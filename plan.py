#!/usr/bin/env python3
"""Print a study plan grouped and sorted by semester.

ASP answer sets are sets: clingo is free to print plan/2 atoms in any order,
so ordering has to happen after solving.  This script runs clingo through its
Python API, collects the shown atoms, and prints them semester by semester.

Examples:
    python plan.py                         # one plan, default cs-2023
    python plan.py --instance cogsys       # a working example
    python plan.py --all                   # every optimal plan
    python plan.py -c n=10                 # override a #const
    python plan.py --time-limit=60         # any other clingo option
    python plan.py --raw                   # also dump the shown atoms
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import clingo

ROOT = Path(__file__).resolve().parent
# clingo's C++ loader cannot open absolute paths containing non-ASCII
# characters on Windows, so run from the repo root with relative paths.
os.chdir(ROOT)

ENCODING = "encodings/encoding.lp"

INSTANCES = {
    "cs-2023": [
        ENCODING,
        "instances/cs-2023/regulation.lp",
        "instances/cs-2023/regulation-instance.lp",
        "instances/cs-2023/translate.lp",
        "instances/cs-2023/curriculum.lp",
        "instances/cs-2023/input.lp",
        "instances/cs-2023/optimize.lp",
        "instances/cs-2023/show.lp",
    ],
    "cs-2023-example": [
        "instances/cs-2023-example/cs.lp",
        "instances/cs-2023-example/input.lp",
        ENCODING,
        "encodings/show.lp",
    ],
    "cogsys": [
        "instances/cogsys/cogsys.lp",
        ENCODING,
        "encodings/show.lp",
    ],
}

EXTRA_CONSTANTS = {
    "cs-2023-example": ["t=0"],
    "cogsys": ["t=0"],
}


def parse_args() -> tuple[argparse.Namespace, list[str]]:
    parser = argparse.ArgumentParser(
        description="Solve a study-plan instance and print it by semester."
    )
    parser.add_argument(
        "--instance",
        choices=sorted(INSTANCES),
        default="cs-2023",
        help="instance to solve (default: cs-2023)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="enumerate all optimal plans instead of only one",
    )
    parser.add_argument(
        "-c",
        "--const",
        action="append",
        default=[],
        metavar="NAME=VALUE",
        help="override a #const; may be repeated",
    )
    parser.add_argument(
        "--atoms",
        action="store_true",
        help="print only plan(Semester, Course). atoms, sorted by semester",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="also print the raw shown atoms for each model",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show clingo information messages",
    )
    return parser.parse_known_args()


def group_plan(symbols: list[clingo.Symbol]) -> dict[int, list[str]]:
    plan: dict[int, list[str]] = {}
    for symbol in symbols:
        if len(symbol.arguments) != 2:
            continue
        if symbol.name == "plan":
            # cs-2023: plan(Semester, Course)
            semester = symbol.arguments[0].number
            course = str(symbol.arguments[1])
        elif symbol.name == "" and symbol.arguments[1].type == clingo.SymbolType.Number:
            # cogsys / cs-2023-example: (Course, Semester)
            semester = symbol.arguments[1].number
            course = str(symbol.arguments[0])
        else:
            continue
        plan.setdefault(semester, []).append(course)
    for courses in plan.values():
        courses.sort()
    return plan


def shown_value(symbols: list[clingo.Symbol], name: str) -> dict[int, str]:
    """Collect atoms like credits(I, C), term(I, T), fee(I, S)."""
    result: dict[int, str] = {}
    for symbol in symbols:
        if symbol.name != name or len(symbol.arguments) != 2:
            continue
        semester = symbol.arguments[0].number
        result.setdefault(semester, str(symbol.arguments[1]))
    return result


def print_model(
    index: int,
    symbols: list[clingo.Symbol],
    cost: list[int],
    raw: bool,
    atoms: bool,
) -> None:
    plan = group_plan(symbols)
    credits = shown_value(symbols, "credits")
    terms = shown_value(symbols, "term")
    fees = shown_value(symbols, "fee")

    if atoms:
        if index:
            print()
        for semester in sorted(plan):
            for course in plan[semester]:
                print(f"plan({semester}, {course}).")
        return

    if index:
        print()
    title = f"Plan {index + 1}"
    if cost:
        title += f"  (cost: {', '.join(map(str, cost))})"
    print(title)
    print("=" * len(title))

    if not plan:
        print("No planned courses.")
    for semester in sorted(plan):
        details = []
        if semester in terms:
            details.append(terms[semester])
        if semester in credits:
            details.append(f"{credits[semester]} credits")
        if semester in fees:
            details.append(f"fee {fees[semester]}")
        suffix = f"  [{', '.join(details)}]" if details else ""
        print(f"Semester {semester}{suffix}")
        for course in plan[semester]:
            print(f"  {course}")

    if raw:
        print()
        print("Raw shown atoms:")
        for atom in sorted(map(str, symbols)):
            print(f"  {atom}")


def main() -> int:
    args, clingo_args = parse_args()
    files = INSTANCES[args.instance]

    arguments = [f"--models={0 if args.all else 1}"]
    if args.all:
        arguments.append("--opt-mode=optN")
    for constant in EXTRA_CONSTANTS.get(args.instance, []):
        arguments.extend(["-c", constant])
    for constant in args.const:
        arguments.extend(["-c", constant])
    arguments.extend(clingo_args)

    logger = None if args.verbose else (lambda code, message: None)
    control = clingo.Control(arguments, logger=logger)
    for path in files:
        control.load(path)

    control.ground([("base", [])])

    model_count = 0
    with control.solve(yield_=True) as handle:
        for model in handle:
            symbols = model.symbols(shown=True)
            print_model(model_count, symbols, list(model.cost), args.raw, args.atoms)
            model_count += 1
        result = handle.get()

    if model_count == 0:
        print("No model found (UNSATISFIABLE)." if not result.satisfiable else "No model.")
    return 0 if result.satisfiable else 1


if __name__ == "__main__":
    sys.exit(main())
