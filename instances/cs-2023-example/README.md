# CS 2023 Study Regulations

**README version: 2.0 (second version)**

The folder name `cs-2023` stands for the Computer Science (CS) curriculum for students entering in 2023 at Ho Chi Minh City University of Technology (HCMUT) in Vietnam.

The current version is a simplified example of the full CS curriculum.

This folder is an **instance** of the generic study-plan encoding, not a fork of
it. 

The important question for this instance is therefore:

> How much of `encodings/encoding.lp` is actually reused, and what does
> `instances/cs-2023/cs.lp` add on top?

Short answer:

- `encoding.lp` supplies the **scheduling engine**: the choice rule, the
  one-term-per-module constraint, the generic `before` ordering mechanism, and
  the generic `sum` constraints.
- `cs.lp` supplies the **curriculum data**, the **credit accounting**, and the
  **study-regulations policy**.
- The only student-specific *state* is the transcript (`grade/2`), plus the
  optional `retake_requested/1` preference. The transcript/retake policy is the
  one substantial policy area that requires new state and has no counterpart
  in `encoding.lp`.
- `cs.lp` does **not** use `card/3`, `subseteq/2`, `equal/2`, or the
  `map(s, ...)` / `m(w)` / `m(s)` term-splitting feature of `encoding.lp`.
- `cs.lp` does **not** modify `encoding.lp`. It only emits the atoms that
  `encoding.lp` expects.

| File | Role |
|---|---|
| `cs.lp` | CS-2023 curriculum, transcript/retake rules, credit accounting, policy |
| `input.lp` | Example student transcript; facts only |
| `../../encodings/encoding.lp` | Generic scheduler and generic constraints |
| `../../encodings/show.lp` | Optional display of scheduled modules |

---

## 1. The two layers

```
input.lp
  grade/2, retake_requested/1
        |
        v
cs.lp
  curriculum data + transcript state + retake policy
  credit accounting + elective overflow
  semester bounds + prerequisites + availability
        |
        |  emits: in/2, map/3, empty/1, sum/4, set(before(...)), ...
        v
encodings/encoding.lp
  { in(E,s(I)) } choice rule
  in(E,s) union
  generic set materialisation
  empty / subseteq / equal / card / sum constraints
        |
        v
encodings/show.lp
  display of (module, term) pairs
```

`cs.lp` is not an alternative to `encoding.lp`; it is a configuration of it.
The only thing that is fundamentally new is the transcript/retake layer and the
credit-accounting glue that makes passed and retaken courses visible to the
generic `sum` constraints.

### Running

With the `clingo` executable:

```console
clingo instances/cs-2023/cs.lp instances/cs-2023/input.lp encodings/encoding.lp encodings/show.lp -c n=9 1
```

If only `pyclingo` is installed:

```console
python -m clingo instances/cs-2023/cs.lp instances/cs-2023/input.lp encodings/encoding.lp encodings/show.lp -c n=9 1
```

`n = 9` is also the default in `cs.lp`; passing `-c n=9` makes it explicit.
Terms are classified by `I \ 3`:

| `I \ 3` | Season |
|---|---|
| `1` | fall |
| `2` | spring |
| `0` | summer |

With `n = 9`, terms 3, 6 and 9 are summer terms.

---

## 2. How much of `encoding.lp` is used?

### 2.1 Coverage table

| `encoding.lp` mechanism | Used by `cs.lp`? | What it does for CS-2023 |
|---|---|---|
| `{ in(E,s(I)) } :- in(E,m), I=1..n.` | **Yes** | Chooses a term for every schedulable module. `cs.lp` defines `m` from the curriculum groups plus `retake_group`. |
| `in(E,s) :- in(E,s(I)).` | **Yes** | The union of all scheduled modules. Used by credit accounting, the "already attempted" guard, and the forced `eng_test` milestone. |
| `in(E,m(X)) :- X = (s;w), in(E,m), map(s,E,X).` | **No** | CS-2023 does not use the generic winter/summer module sets. It uses its own `season/2` and `available/2` policy instead. |
| `empty(A)` | **Yes** | `empty(int(s(I),s(J)))` forbids a module from appearing in two terms. |
| `int(A,B)` | **Yes** | Used only as the argument of `empty(...)` for the term-conflict constraint. It is not used for credit sums. |
| `set(before(A))` / `in(E,before(A))` | **Yes** | Implements prerequisites and retake ordering. |
| `sum(A,F,bw,(L,U))` | **Yes** | Group credit bounds over `credit(H)` and per-semester upper bounds over `s(I)`. |
| `sum(A,F,geq,L)` | **Yes** | Per-semester minimum load, unless the degree is already complete. |
| Generic set materialisation for `sum`, `empty`, `int`, `before` | **Yes** | `set(A)` is derived automatically from the atoms emitted by `cs.lp`. |
| `subseteq(A,B)` | **No** | CS-2023 does not use subset relations. |
| `equal(A,B)` | **No** | CS-2023 does not use set equality. |
| `card(A,leq,U)` | **No** | There is no course-count limit. The summer limit is a *credit* limit (`sum`), not a count of modules. |
| `show.lp` | **Yes, optional** | Displays scheduled `(module, term)` pairs. |
| `encoding-examinations.lp` | **No** | CS-2023 does not model examinations. |

### 2.2 What this means

The complete scheduling backbone is reused:

- the **choice rule** that assigns modules to terms,
- the **union** `in(E,s)`,
- the **one-term** constraint via `empty` + `int`,
- the **ordering** mechanism via `before`,
- the **credit-bound** constraints via `sum` with both `bw` and `geq`.

`cs.lp` writes no custom *scheduling* choice rule, no custom set
materialisation, no custom sum constraint, and no custom `before`
implementation. Its only choice rules are the accounting choices that decide
which elective bucket a course is counted in. Otherwise it only writes the
instance data and policy rules that activate the generic mechanisms.

The generic features that are left unused are exactly the ones the CS-2023
regulation does not need:

- `card/3` is not used because semester limits are measured in credits, not in
  number of courses. The old course-count summer cap is gone.
- `subseteq/2` and `equal/2` are not used because the regulation is expressed
  through explicit credit buckets and their `sum` bounds.
- `map(s, ...)` / `m(w)` / `m(s)` is not used because availability is handled
  by a dedicated `available/2` policy with `not_offered/2` exceptions.

---

## 3. What `cs.lp` adds on top

The additions fall into three groups: **data**, **new accounting/rules**, and
**policy expressed through the generic constraints**.

### 3.1 Curriculum data

`cs.lp` defines which courses exist, which group each course belongs to, and
how many credits each course is worth:

```lp
in((mt1003; mt1005; ...), a1_group).
map(c, mt1003, 4).
```

It also defines the group bounds:

| Group | Credits | Role |
|---|---:|---|
| `a1_group` | `30..30` | Mathematics and basic sciences |
| `a2_group` | `11..11` | Social and economics |
| `a3_group` | `6..6` | Introduction to engineering |
| `a4_group` | `8..8` | Foreign languages |
| `core_group` | `11..11` | Core courses |
| `a6_group` | `0..0` | Physical education (required separately) |
| `elective_pool_c` | `15..15` | Elective pool C |
| `elective_pool_d` | `3..3` | Elective pool D |
| `elective_pool_general` | `9..100` | Overflow bucket for extra electives |
| `total_degree` | `100..1000` | Total degree; `1000` is a sentinel meaning "no meaningful upper bound" |

The total is `100..1000`, but the current course data has a maximum of
**102** credits: the compulsory groups contribute 66 credits and every elective
is worth 3 credits. Thus every reachable total is `66 + 3k`. The lower bound
`100` is not reachable; the smallest reachable total above it is `102`.

This data is not "implemented" by `encoding.lp`; it configures the generic
`in/2`, `map/3` and `sum/4` machinery.

### 3.2 Credit accounting: the main new abstraction

A course can belong to a group without automatically contributing to that
group's credit total. In particular:

- a passed course contributes credits even though it is never scheduled;
- a failed course can contribute through a separate retake module;
- an elective can be counted either in its own pool or in the overflow bucket,
  but not both.

`cs.lp` therefore introduces `credit/1` sets:

```lp
in(C, credit(H))          :- ..., in(C, s).
in(retake(C), credit(H))  :- ..., in(retake(C), s).
in(earned(C), credit(H))  :- ..., passed(C).
```

`earned(C)` and `retake(C)` are **pseudo-modules** used only for credit
accounting. They let the instance reuse the generic `sum` constraint:

```lp
sum(credit(H), c, bw, (L,U)) :- group(H), map(l,H,L), map(u,H,U).
```

This is a new accounting layer, but it is built entirely from the generic
`sum` mechanism. The total-degree bucket is the disjoint union of the leaf
buckets, so every course is counted exactly once.

### 3.3 Elective overflow

`elective_pool_general` is a real overflow bucket, not a second copy of the
same elective credits:

```lp
{ counted(E,B) : candidate(E,B) } = 1 :- candidate(E,_), in(E,s).
in(E, credit(B)) :- counted(E,B), in(E,s).
```

For each scheduled elective, the solver chooses exactly one bucket:

- the quota of its own pool (`elective_pool_c` or `elective_pool_d`), or
- `elective_pool_general`.

Passed electives use the same mechanism through `earned_counted/2`. This
prevents double counting and makes the general bucket genuinely "overflow".

### 3.4 Per-semester credit bounds

The policy is configured at the top of `cs.lp`:

```lp
#const regular_min = 12.
#const regular_max = 22.
#const summer_min  = 0.
#const summer_max  = 9.
```

and then emitted as generic `sum` constraints:

```lp
sum(s(I), c, bw, (0,U)) :- semester_load(I, _, U).
sum(s(I), c, geq, L)    :- semester_load(I, L, _), not degree_complete.
```

Consequences:

- fall and spring terms: `12..22` credits;
- summer terms: `0..9` credits;
- 0-credit PE modules are part of the term but contribute 0 credits;
- retakes are part of the term and contribute their full credit value.

This is a new **policy** but not a new engine mechanism: it is the generic
`sum` constraint applied to `s(I)`.

### 3.5 Degree-completion exemption

The minimum load is waived once the student has already passed enough credits
to satisfy every group lower bound:

```lp
earned_credits(H,S) :- group(H), S = #sum{...}.
group_unmet(H) :- group(H), map(l,H,L), earned_credits(H,S), S < L.
degree_complete :- #count{ H : group_unmet(H) } = 0.
```

When `degree_complete` holds, the `sum(s(I),c,geq,L)` rule is not generated.
The upper bounds still apply. This is a new derived condition, implemented
with ordinary ASP aggregates; `encoding.lp` has no notion of "degree complete".

### 3.6 Transcript and retakes: the part `encoding.lp` does not model

This is the main new **state machine** in `cs.lp`. It is not a configuration of
an existing `encoding.lp` feature; it is new logic.

```lp
attempted(C) :- grade(C, _).
passed(C)    :- grade(C, G), G >= 2.
failed(C)    :- grade(C, G), G < 2, not passed(C).
```

If several attempts exist, any passing grade wins.

Rules:

- A course that was already attempted is never scheduled as its original node:
  ```lp
  :- attempted(C), in(C, s).
  ```
- Only failed courses are eligible for a retake:
  ```lp
  eligible(C) :- failed(C), map(c, C, _).
  ```
- A failed **compulsory** course must be retaken.
- A failed **elective** is available for an optional retake. It becomes
  mandatory only when `retake_requested(C)` is present; the credit bounds can
  also make the optional retake necessary in practice.
- A retake is a separate module `retake(C)` with the original credit value,
  original availability restrictions, and original prerequisites.
- Passed courses contribute through `earned(C)` and are never scheduled again.
- Zero-credit PE courses are required explicitly unless already passed; a
  failed PE is handled by the normal compulsory-retake rule.

This layer emits `retake(C)` into the generic `m` set, so `encoding.lp` then
schedules it like any other module. That is the clean boundary: **new state
comes from `cs.lp`; scheduling stays generic**.

### 3.7 Prerequisites

Prerequisites are declared as a single relation:

```lp
prereq(mt1005, mt1003).
prereq(co2011, co1007).
...
```

The instance then uses the generic `before/1` machinery:

```lp
set(before(target(C))) :- prereq(C, _).
in(C, target(C))       :- prereq(C, _).

in(retake(C), target_retake(C)) :- eligible(C).
set(before(target_retake(C)))   :- eligible(C).
```

`encoding.lp` derives `in(P, before(target(C)))` whenever `P` is scheduled in
an earlier term than `C`. `cs.lp` only has to check:

- the prerequisite was passed before the horizon, or
- it is scheduled strictly earlier, or
- for a failed prerequisite, its retake is scheduled strictly earlier.

This is a new **policy table and constraints**, but the ordering mechanism is
the generic `before` feature.

### 3.8 Seasonal availability

`cs.lp` has its own availability policy:

```lp
available(C,I) :- in(C,m), term(I), season(I,S), not not_offered(C,S).

not_offered(pe1003, summer).
not_offered(pe1005, summer).
not_offered(co1005, summer).
```

Retakes inherit the restriction of the original course. Scheduling is then
constrained by:

```lp
:- in(E,s(I)), not available(E,I).
```

This is why `cs.lp` does not need the `map(s, ...)` / `m(w)` / `m(s)` feature of
`encoding.lp`: its policy is "this course is not offered in this season",
including retake inheritance, rather than "this module belongs to the summer
set".

### 3.9 External requirements and PE

- `eng_test` is an external milestone. It is forced into `in(E,s)` but is
  forbidden from being placed in a term:
  ```lp
  in(eng_test, s).
  :- external(E), in(E,s(I)).
  ```
- PE courses are zero-credit but compulsory. They must be scheduled (or
  retaken) unless already passed.

Both are new instance constraints; neither needs a new generic encoding.

### 3.10 GPA optimisation

The instance contains a commented-out soft constraint:

```lp
% #maximize{ Grade * Credits, M : in(M,s(I)), expected_grade(M,Grade), map(c,M,Credits) }.
```

It is inactive because no `expected_grade/2` relation is provided. Without it,
the solver returns any feasible plan; it does not optimise GPA.

---

## 4. Reuse vs. new features at a glance

| Concern | `encoding.lp` | `cs.lp` |
|---|---|---|
| Schedule selection | choice rule over `in(E,m)` | defines `in(E,m)` from groups + retake nodes |
| One term per module | `empty` + `int` | emits `empty(int(s(I),s(J)))` |
| Prerequisite order | `before` | emits `target(C)` / `target_retake(C)` sets and constraints |
| Credit bounds | `sum` (`bw`, `geq`) | emits `sum(s(I),...)` and `sum(credit(H),...)` |
| Curriculum | none | course/group/credit data |
| Credit accounting | none | `credit/1`, `earned/1`, `retake/1`, total union |
| Elective overflow | none | `candidate/2` + exactly-one `counted/2` |
| Transcript | none | `grade/2` -> `attempted` / `passed` / `failed` |
| Retakes | none | `retake/1` modules, `eligible/1`, `required/1` |
| Semester loads | none | `semester_load/3` + `sum` |
| Degree completion | none | `earned_credits/2`, `group_unmet/1`, `degree_complete/0` |
| Availability | none | `available/2`, `not_offered/2` |
| PE / external milestones | none | explicit constraints |
| GPA optimisation | none | optional commented `#maximize` |

In other words: **the engine is reused; the domain is new**. Most of the
domain layer is data and policy that is expressed through `encoding.lp`'s
existing `in`, `map`, `sum`, `empty`, and `before` mechanisms. The transcript
and retake logic is the part with genuinely new state.

---

## 5. How `input.lp` works with `cs.lp`

`input.lp` contains **facts only**. All rules live in `cs.lp`.

### Allowed facts

| Fact | Meaning |
|---|---|
| `grade(C,G).` | The student attempted course `C` before the planning horizon with grade `G` (`0..4`). |
| `retake_requested(C).` | The student explicitly wants to retake failed course `C`; this makes an elective retake mandatory. |

The shipped example is:

```lp
grade(mt1003, 1).      % failed compulsory -> required retake
grade(im1013, 1).      % failed elective -> optional retake (requested below)
grade(co1007, 4).      % passed -> credits count, never scheduled again
grade(la1007, 4).      % passed -> credits count, never scheduled again

retake_requested(im1013).
```

### Semantics

- `G >= 2` is a pass. A passed course contributes its credits as `earned(C)`.
- `G < 2` is a failure. Failed compulsory courses are automatically retaken.
- A failed elective is available for an optional retake. It is mandatory only
  if `retake_requested(C)` is present; the credit bounds can still force the
  optional retake in practice.
- `retake_requested(C)` is ignored if `C` was passed or has no `grade` fact.
- Multiple `grade` facts for the same course are allowed; any pass wins.
- `done/1` is not used by this version.
- A grade for a course that is not defined in `cs.lp` does not make that course
  schedulable; the course must first be added to the curriculum data.

### Running with or without a transcript

With the example transcript:

```console
python -m clingo instances/cs-2023/cs.lp instances/cs-2023/input.lp encodings/encoding.lp encodings/show.lp -c n=9 1
```

Without a transcript (or with an empty `input.lp`), every course is treated as
not yet attempted:

```console
python -m clingo instances/cs-2023/cs.lp encodings/encoding.lp encodings/show.lp -c n=9 1
```

To use a real transcript, replace the facts in `input.lp` or pass another input
file after `cs.lp`. Do not add rules to the input file; rules belong in
`cs.lp`.

---

## 6. Known behaviours and limitations

- **Total 100 is unreachable.** With the current credits, totals are
  `66 + 3k`; the lower bound `100` is not attainable, and the only feasible
  complete total under the current course pool is `102`. The total upper bound
  `1000` is a sentinel for "no meaningful upper bound".
- **Strict minimum load.** Every fall/spring term requires at least 12 credits
  while `degree_complete` is false. A student who is very close to finishing
  (for example, 99 earned credits and one 3-credit course left) can therefore
  be unsatisfiable. There is no partial-final-term exemption.
- **Only failed courses are retaken.** Passed courses cannot be retaken.
- **No optimisation is active.** The GPA `#maximize` rule is commented out, so
  the solver returns any feasible plan rather than a best plan.
- **No course-count limit.** The old summer course-count cap is not used;
  summer is limited by credits only.
- **The generic features `card/3`, `subseteq/2`, `equal/2` and `map(s,...)` are
  intentionally unused.** They are not needed by this regulation.

---

## 7. Versioning

**README version 2.0** is a rewrite of the first version. It documents the
current `cs.lp`/`input.lp` interface and, in particular, the boundary between
the generic mechanisms reused from `encodings/encoding.lp` and the
CS-2023-specific data, accounting and policy added by `cs.lp`.

Update this version number and the affected sections whenever `cs.lp` changes
its interface or policy.
