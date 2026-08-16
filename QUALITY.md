# Local quality commands

This document defines the supported local M2.6 quality-command surface for the Formal Mathematics Curriculum repository.

These commands report software/formalization quality dimensions only. They do **not** infer curriculum identity, taxonomy rank, learner readiness, Level, mathematical importance, or empirical truth.

## Preconditions

Use authenticated access to the private repository and check out the exact branch/ref/SHA you intend to verify. The environment remains governed by `lean-toolchain`, `lakefile.toml`, and `lake-manifest.json`.

The command surface is:

```sh
bash Quality/quality.sh env
bash Quality/quality.sh build
bash Quality/quality.sh proof
bash Quality/quality.sh source
bash Quality/quality.sh regression
bash Quality/quality.sh all
bash Quality/quality.sh report [dimension]
```

`all` is convenience orchestration only. It is **not** the sole canonical quality result: every executed dimension writes an independent revision-bound report and diagnostic log.

## `env` — governed environment

```sh
bash Quality/quality.sh env
```

Runs:

1. `lake update`;
2. `git diff --exit-code -- lean-toolchain lakefile.toml lake-manifest.json`;
3. `lake exe cache get`.

A pass means the dependency environment resolves and the three governed environment files remain unchanged after resolution. Cache availability accelerates builds but is not semantic evidence.

If `env` fails during `all`, environment-dependent dimensions are reported as **skipped**, not silently attempted in an ungoverned environment.

## `build` — complete production build / warning gate

```sh
bash Quality/quality.sh build
```

Runs `lake build --wfail FormalMath`.

A pass means the complete supported `FormalMath` target builds at the recorded revision with Lake warning-failure semantics. It does not mean the curriculum or formalization program is complete.

## `proof` — production proof/axiom assurance

```sh
bash Quality/quality.sh proof
```

Runs, in order:

1. `lake build --wfail +Quality.AxiomAudit`;
2. the production module-origin axiom audit with Lean `-DwarningAsError=true`;
3. the standard mathematical axiom positive control with the same direct-Lean warning semantics.

The production auditor distinguishes standard Lean mathematical axioms from `sorryAx`, custom/unclassified axioms, and trust-compiler dependence rather than treating all axioms as one category. Deliberate bad fixtures live in the regression dimension.

## `source` — source/import/API-boundary structural checks

```sh
bash Quality/quality.sh source
```

Runs `Quality/check-source-quality.sh production`.

Hard checks currently cover governed Lean source headers, supported-module documentation presence, root-umbrella import misuse, reviewed direct mathlib-transitive import roots, and explicit public `FormalMath.Internal.*` re-export. Broad exact `import Mathlib` is advisory.

Known blind spots remain documented in `P2-QA-M2.6-SOURCE-v1`; this command does not claim complete semantic API verification.

## `regression` — positive and intended-failure behavior

```sh
bash Quality/quality.sh regression
```

Runs the permanent MAT-178 regression harness. It includes:

- strict production build and reusable axiom-auditor build;
- non-default `QualityTests` positive regression/contract build;
- source-quality positive checks;
- direct `sorry`, transitive `sorryAx`, custom-axiom, source-policy, and computability negative controls;
- the seven test-only FORMREQ-P1-000018 anti-conflation invariants.

Expected-failure fixtures pass the regression dimension only when they return nonzero for the intended signature.

## `all` — orchestration, not collapsed truth

```sh
bash Quality/quality.sh all
```

Runs `env`, then `build`, `proof`, `source`, and `regression`. After a valid environment, it continues across failing dimensions so a single failure does not hide the others. The final aggregate status is nonzero if any dimension failed, but the per-dimension reports remain authoritative execution evidence.

## Revision-bound reports

Every executed dimension creates two local files under:

```text
.lake/build/quality/
```

- `<dimension>-<short-sha>-<timestamp>.report` — compact provenance/status record;
- `<dimension>-<short-sha>-<timestamp>.log` — diagnostic command output.

Reports include:

- dimension and pass/fail/skipped status;
- exit code;
- exact Git SHA and current ref;
- committed `lean-toolchain` value;
- effective Lean and Lake versions;
- resolved local mathlib revision when available;
- Git blob identity of `lake-manifest.json`;
- platform;
- start/end UTC timestamps;
- exact shell command;
- diagnostic log path.

The report directory is under `.lake/` and therefore remains local build output, not versioned source of truth.

Show the most recent current-SHA report:

```sh
bash Quality/quality.sh report
```

Or for one dimension:

```sh
bash Quality/quality.sh report proof
```

## Failure-report workflow

When a quality command fails:

1. preserve the exact `.report` and referenced `.log` while diagnosing;
2. confirm the recorded SHA/ref/toolchain/mathlib context before interpreting the failure;
3. identify the failing dimension and underlying gate rather than treating aggregate `all` status as the root cause;
4. if the failure is an expected negative fixture that unexpectedly passed, treat that as a gate failure;
5. preserve failed validation lineage in the relevant Linear issue when the failure is part of an architecture milestone;
6. rerun the affected dimension at the corrected revision, then rerun the broader regression/all surface when appropriate;
7. never inherit a prior revision's PASS merely because the new revision is its descendant.

## CI handoff

M2.7 may call these same commands from permanent CI. M2.6 does not select workflow topology, trigger policy, runner matrix, required-check names, merge policy, or artifact-retention policy.

A future CI aggregate may orchestrate `all`, but it must keep `build`, `proof`, `source`, and `regression` results independently diagnosable.
