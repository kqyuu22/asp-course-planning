# Study regulations
> An ASP-based system for reasoning about study regulations

## Fork and adaptation

This repository is an independent, customized adaptation of
[`potassco/study-regulations`](https://github.com/potassco/study-regulations),
cloned from the upstream project and maintained here as
[`kqyuu22/asp-course-planning`](https://github.com/kqyuu22/asp-course-planning).

The upstream repository provides the generic ASP encodings and the Cognitive
Systems (CogSys) Master example. The original encodings and CogSys instance
remain the work of the upstream authors; this fork's contribution is the
HCMUT CS 2023 adaptation.

The fork keeps the upstream encoding framework and uses it to model the
**Computer Science 2023 curriculum at Ho Chi Minh City University of
Technology (HCMUT)**. The current implementation is the modular instance in
[`instances/cs-2023`](./instances/cs-2023); the older monolithic version is
kept in [`instances/cs-2023-example`](./instances/cs-2023-example) for
reference.

This is an independent adaptation, not an official HCMUT project. For the
original system, examples and paper, use the upstream repository and the
references below.

## Current status

The project currently works through two lightweight command-line front ends:

* [`run.sh`](./run.sh) — solves an instance with clingo and prints the raw
  answer set.
* [`plan.py`](./plan.py) — solves an instance through clingo's Python API and
  prints the plan grouped by semester, with courses sorted inside each
  semester.

The checked-in [`output.txt`](./output.txt) is a quick snapshot of a recent
run. It is a static file, not regenerated automatically. The current snapshot
shows an interrupted multi-model enumeration: the first model was found in
about 0.63 seconds, and the run was stopped after 10 models.

What is working:

* The modular **HCMUT CS 2023** instance solves and produces study plans.
* The upstream **CogSys** instance still runs as a compatibility example.
* `run.sh` works with either a `clingo` executable or a pip-installed
  `clingo` Python module.
* `plan.py` provides readable, semester-ordered output and a raw
  `plan(Semester, Course)` mode.

Known limitations:

* The clinguin UI is still primarily useful for the upstream CogSys instance.
  Running the CS 2023 instance through the UI currently returns raw JSON rather
  than a rendered page.
* `output.txt` is a snapshot only; rerun the commands below to refresh it.
* Full optimal-plan enumeration for CS 2023 can take minutes. Use a time limit
  or request a single model unless all optima are needed.

## Quick start

### Requirements

For the command-line solver, install either form of clingo:

```console
conda install potassco::clingo
```

or:

```console
pip install clingo
```

A pip installation provides `python -m clingo`; `run.sh` and `plan.py` detect
this automatically. The optional UI requires **clinguin v2.0** or newer,
following the
[clinguin installation instructions](https://clinguin.readthedocs.io/en/latest/clinguin/installation.html).

### One-command interface

On Linux, macOS, Git Bash, or WSL:

```sh
./run.sh 1                    # one plan for the default cs-2023 instance
./run.sh 0                    # enumerate optimal plans
./run.sh --time-limit=60 1    # pass any clingo option
INSTANCE=cogsys ./run.sh 1    # upstream CogSys example
INSTANCE=cs-2023-example ./run.sh 1
```

On Windows, `run.sh` needs a POSIX shell. From PowerShell, use Git Bash:

```powershell
& "C:\Program Files\Git\bin\bash.exe" run.sh 1
```

or run the Python interface directly:

```powershell
python plan.py
python plan.py --atoms
```

### Readable semester-ordered output

```powershell
python plan.py                 # one plan, grouped by semester
python plan.py --atoms         # plan(Semester, Course). atoms, sorted
python plan.py --raw           # readable plan plus raw shown atoms
python plan.py --all           # all optimal plans
python plan.py --instance cogsys
python plan.py -c n=10         # override a #const
python plan.py --time-limit=60
```

Example:

```text
Plan 1  (cost: 11, 1116225, 1)
==============================
Semester 2  [regular, 21 credits, fee 18570000]
  co3047
  co3057
  ...
```

ASP answer sets are unordered, so `plan.py` sorts the shown `plan/2` atoms
after solving. Raw clingo output does not guarantee semester order.

## Organization

### Encodings

* [`encoding.lp`](./encodings/encoding.lp): generic encoding to generate study
  plans (described in the paper).
* [`encoding-examinations.lp`](./encodings/encoding-examinations.lp): extended
  encoding including examination tasks.
* [`show.lp`](./encodings/show.lp): `#show` statements for the CogSys display.
* [`ui.lp`](./encodings/ui.lp): clinguin UI encoding.

### Instances

The fork's current HCMUT instance is modular. The layers are combined in this
order:

* [`regulation.lp`](./instances/cs-2023/regulation.lp): school-independent
  model of terms, attempts, credits, GPA, semester loads, and fees.
* [`regulation-instance.lp`](./instances/cs-2023/regulation-instance.lp):
  HCMUT-specific parameters, grade scale, fee rules, retake policy, and
  graduation requirements.
* [`translate.lp`](./instances/cs-2023/translate.lp): translates the student
  transcript into attempts, history, and sets.
* [`curriculum.lp`](./instances/cs-2023/curriculum.lp): CS 2023 courses,
  course groups, credit bounds, majors, prerequisites, and co-requisites.
* [`input.lp`](./instances/cs-2023/input.lp): example planning horizon,
  transcript, closed courses, and budget.
* [`optimize.lp`](./instances/cs-2023/optimize.lp): lexicographic objectives
  (shortest plan, cost, summer terms, retake timing).
* [`show.lp`](./instances/cs-2023/show.lp): output projection for the CS 2023
  instance.

The older monolithic CS 2023 version remains in
[`instances/cs-2023-example/cs.lp`](./instances/cs-2023-example/cs.lp), with
its own [README](./instances/cs-2023-example/README.md).

The upstream CogSys instances are:

* [`cogsys.lp`](./instances/cogsys/cogsys.lp): basic CogSys Master
  regulations.
* [`cogsys-examinations.lp`](./instances/cogsys/cogsys-examinations.lp):
  CogSys Master with examination tasks.
* [`cogsys-examinations-constraints.lp`](./instances/cogsys/cogsys-examinations-constraints.lp):
  examination-task constraints from the paper.

### Tools and snapshots

* [`run.sh`](./run.sh): shell front end; chooses `clingo` or
  `python -m clingo`, resolves the repo root, and selects an instance with
  `INSTANCE`.
* [`plan.py`](./plan.py): Python front end; produces semester-sorted readable
  output, `--atoms` output, or raw atoms.
* [`output.txt`](./output.txt): quick view of a recent raw solver run.
* [`tests/README.md`](./tests/README.md): upstream regression cases. Some
  upstream commands predate the `t` constant; with the current encoding, add
  `-c t=0` when running CogSys or the legacy example directly.

## Manual clingo commands

Use these when you want to see exactly which files are loaded.

- HCMUT CS 2023, modular instance:

```sh
clingo \
  encodings/encoding.lp \
  instances/cs-2023/regulation.lp \
  instances/cs-2023/regulation-instance.lp \
  instances/cs-2023/translate.lp \
  instances/cs-2023/curriculum.lp \
  instances/cs-2023/input.lp \
  instances/cs-2023/optimize.lp \
  instances/cs-2023/show.lp \
  1
```

- Original CogSys example:

```sh
clingo instances/cogsys/cogsys.lp encodings/encoding.lp encodings/show.lp \
  -c n=4 -c t=0 1
```

- Legacy monolithic CS 2023 example:

```sh
clingo instances/cs-2023-example/cs.lp instances/cs-2023-example/input.lp \
  encodings/encoding.lp encodings/show.lp -c t=0 1
```

If only the Python module is installed, replace `clingo` with
`python -m clingo`.

## Refreshing output.txt

For a raw single-model snapshot:

```sh
./run.sh 1 > output.txt
```

For a readable, semester-sorted snapshot:

```sh
python plan.py > output.txt
```

## UI with clinguin

The upstream CogSys UI is still available:

```sh
clinguin client-server \
  --domain-files instances/cogsys/cogsys.lp encodings/encoding.lp \
  --ui-files encodings/ui.lp \
  -c n=4 -c t=0
```

The UI encoding in `encodings/ui.lp` is instance-agnostic and displays terms
and `map(c, Module, Credits)` values. The current system does not fully render
the modular CS 2023 instance; running it through the UI returns raw JSON.

![](img/out.png)

## References

* [Reasoning about Study Regulations in Answer Set Programming](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/iclp/HahnMNO0SS23.pdf)
* [Upstream repository](https://github.com/potassco/study-regulations)
* [Clingo](https://potassco.org/clingo/)
* [Clinguin](https://clinguin.readthedocs.io/en/latest/)
