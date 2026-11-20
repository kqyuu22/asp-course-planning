#!/bin/sh
# Solve a study-plan instance with the current ASP engine.
#
# Usage:
#   ./run.sh [clingo options] [models]
#
# Examples:
#   ./run.sh 1                         # one best plan (default: cs-2023)
#   ./run.sh 0                         # enumerate all optimal plans
#   ./run.sh --time-limit=60 1         # extra clingo options come first
#   INSTANCE=cs-2023-example ./run.sh 1
#   INSTANCE=cogsys ./run.sh 1
#
# Environment:
#   INSTANCE   cs-2023 (default), cs-2023-example, or cogsys
#   CLINGO     command used to launch clingo (default: clingo, then
#              `python -m clingo` for a pip/conda Python install)
#
# Notes:
#   - Pass a model count yourself: without it clingo prints every model.
#   - Constants such as n and t live in the instance files. Override them
#     like any other clingo option, e.g. `./run.sh -c n=10 1`.
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTANCE=${INSTANCE:-cs-2023}
cd -- "$DIR"          # relative paths avoid clingo's Windows Unicode-path bug
INST_DIR="instances/$INSTANCE"

run_clingo() {
    if [ -n "${CLINGO:-}" ]; then
        # CLINGO may contain arguments, e.g. CLINGO="python -m clingo".
        # shellcheck disable=SC2086
        $CLINGO "$@"
    elif command -v clingo >/dev/null 2>&1; then
        clingo "$@"
    elif command -v python >/dev/null 2>&1; then
        python -m clingo "$@"
    elif command -v python.exe >/dev/null 2>&1; then
        # WSL with a Windows Python installation.
        python.exe -m clingo "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m clingo "$@"
    else
        echo "run.sh: clingo not found." >&2
        echo "        Install it (conda install potassco::clingo)" >&2
        echo "        or pip install clingo, or set CLINGO=/path/to/clingo." >&2
        exit 127
    fi
}

case "$INSTANCE" in
    cs-2023)
        # Modular HCMUT CS 2023 instance.
        # Order follows the layers documented in the files themselves:
        # generic encoding -> school-independent extension -> school policy
        # -> student history -> curriculum -> objectives -> output.
        run_clingo \
            "encodings/encoding.lp" \
            "$INST_DIR/regulation.lp" \
            "$INST_DIR/regulation-instance.lp" \
            "$INST_DIR/translate.lp" \
            "$INST_DIR/curriculum.lp" \
            "$INST_DIR/input.lp" \
            "$INST_DIR/optimize.lp" \
            "$INST_DIR/show.lp" \
            "$@"
        ;;
    cs-2023-example)
        # Older monolithic CS 2023 example (still useful as a check).
        run_clingo \
            "$INST_DIR/cs.lp" \
            "$INST_DIR/input.lp" \
            "encodings/encoding.lp" \
            "encodings/show.lp" \
            -c t=0 \
            "$@"
        ;;
    cogsys)
        # Upstream Cognitive Systems master example.
        run_clingo \
            "$INST_DIR/cogsys.lp" \
            "encodings/encoding.lp" \
            "encodings/show.lp" \
            -c t=0 \
            "$@"
        ;;
    *)
        echo "run.sh: unknown INSTANCE '$INSTANCE'" >&2
        echo "        choose cs-2023, cs-2023-example, or cogsys" >&2
        exit 2
        ;;
esac
