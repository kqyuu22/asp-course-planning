
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
HCMUT CS 2023 adaptation. The fork keeps that encoding framework and uses it to
model the **Computer Science 2023 curriculum at Ho Chi Minh City University of
Technology (HCMUT)**. The curriculum-specific instance is in
[`instances/cs-2023`](./instances/cs-2023), with its own
[`README.md`](./instances/cs-2023/README.md) explaining how it reuses
`encodings/encoding.lp` and what new policies it adds.

This is an independent adaptation, not an official HCMUT project. For the
original system, examples and paper, use the upstream repository and the
references below.

## Description

This repository contains ASP encodings to:
* generate study plans using [*clingo*](https://potassco.org/clingo/), and
* generate a User Interface (UI) to explore study plans using [*clinguin*](https://clinguin.readthedocs.io/en/latest/).

As an example, the upstream project focuses on the study regulations for the [Cognitive Systems (CogSys) Master](https://www.uni-potsdam.de/fileadmin/projects/studium/docs/03_studium_konkret/07_rechtsgrundlagen/studienordnungen/StO_CogSys_EN.pdf). This fork adds the HCMUT CS 2023 instance described above.

For a formal description of the system, please read the [original paper](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/iclp/HahnMNO0SS23.pdf).

## Installation

* ***clingo***

  To run the encodings, *clingo* must be installed, for example, using conda:

  ```console
  conda install potassco::clingo
  ```

* ***clinguin* v2.0**

  To run the UI, *clinguin* version 2.0 must be installed, following these [installation instructions](https://clinguin.readthedocs.io/en/latest/clinguin/installation.html).

## Organization

### Encodings


* [`encoding.lp`](./encodings/encoding.lp): encoding - encoding to generate study plans (described in the paper).
* [`encoding-examinations.lp`](./encodings/encoding-examinations.lp): extended encoding - encoding including examination tasks.
* [`show.lp`](./encodings/show.lp): `#show` statements to simplify the visualization.



### Instances

Specific study regulations can be found in the [instances directory](./instances):

* [`cogsys.lp`](./instances/cogsys/cogsys.lp): basic study regulations for CogSys Master.
* [`cogsys-examinations.lp`](./instances/cogsys/cogsys-examinations.lp): extension of CogSys Master with examination tasks.
* [`cogsys-examinations-constraints.lp`](./instances/cogsys/cogsys-examinations-constraints.lp): CogSys Master examination tasks constraints (described in the paper).

The fork's curriculum instance:

* [`cs-2023/cs.lp`](./instances/cs-2023/cs.lp): HCMUT Computer Science 2023 curriculum, written on top of the generic encoding.
* [`cs-2023/input.lp`](./instances/cs-2023/input.lp): example transcript and retake request for the CS 2023 instance.
* [`cs-2023/README.md`](./instances/cs-2023/README.md): documentation of the instance, including how much of `encoding.lp` it reuses and what new policies it adds.

## Usage

### Solving with *clingo*

- Obtain a single study plan for the original CogSys example

```command
clingo instances/cogsys/cogsys.lp encodings/{encoding.lp,show.lp} -c n=4 1
```

- Obtain a single study plan for the HCMUT CS 2023 instance

```command
clingo instances/cs-2023/cs.lp instances/cs-2023/input.lp encodings/encoding.lp encodings/show.lp -c n=9 1
```


### UI with *clinguin*

- Open an interactive UI to configure the original CogSys study plan

```command
clinguin client-server --domain-files instances/cogsys/cogsys.lp encodings/encoding.lp --ui-files encodings/ui.lp -c n=4
```

- Open the same UI for the HCMUT CS 2023 instance

```command
clinguin client-server --domain-files instances/cs-2023/cs.lp instances/cs-2023/input.lp encodings/encoding.lp --ui-files encodings/ui.lp -c n=9
```

The UI encoding in `encodings/ui.lp` is instance-agnostic: it displays terms and
`map(c, Module, Credits)` values, so the same UI is used for both the CogSys and
CS 2023 instances. However, the current system does not support rendering CS 2023 so if the UI of CS 2023 is run, the web just returns a raw json.

![](img/out.png)

