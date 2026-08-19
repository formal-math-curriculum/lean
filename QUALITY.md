# Local quality commands

This document defines the supported M2.6 local quality-command surface for the Formal Mathematics Curriculum repository.

These commands report software/formalization quality dimensions only. They do **not** infer curriculum identity, taxonomy rank, learner readiness, Level, mathematical importance, empirical truth, or curriculum/formalization completeness.

## Selected environment precondition

The selected M2.6 environment is versioned in `Quality/environment-baseline.env` and currently fixes:

- Lean toolchain `leanprover/lean4:v4.33.0`;
- Lean 4.33.0 commit `d8b18978322de05a8f3dba51ef03cf5461676c17`;
- Lake `5.0.0-src+d8b1897`;
- mathlib input `v4.33.0` and resolved revision `db584cd6d46c92f209a44c0f1c829460d327499d`;
- the governed `lake-manifest.json` blob for this baseline.

Every independently runnable semantic quality dimension invokes `Quality/check-environment.sh semantic` before it can emit PASS. The preflight verifies effective Lean/Lake, performs `lake update`, rejects drift in `lean-toolchain`/`lakefile.toml`/`lake-manifest.json`, checks the selected manifest identity, and checks the resolved mathlib checkout revision.

A feature branch does not silently select a new environment merely by committing a different toolchain or dependency revision. Changing the selected environment requires governed dependency/environment work and an update to the versioned baseline.

## Command surface

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

## `env` — selected environment + optional cache warmup

```sh
bash Quality/quality.sh env
```

The semantic preflight is mandatory. After it passes, `env` attempts `lake exe cache get` as a best-effort acceleration step.

Cache semantics:

- cache success is reported;
- cache failure is reported as `quality-env:cache:nonblocking-fail`;
- cache failure does **not** change an otherwise valid selected environment into semantic failure;
- builds may consequently take longer or build more dependencies from source;
- cache availability is not proof/build/curriculum evidence.

If the semantic preflight fails during `all`, environment-dependent dimensions are reported as **skipped** rather than executed under a knowingly invalid environment.

## `build` — complete production build / warning gate

```sh
bash Quality/quality.sh build
```

Runs the selected-environment preflight and then `lake build --wfail FormalMath`.

A PASS means the complete supported target built under the selected environment at the recorded SHA with Lake warning-failure semantics. It does not imply curriculum or formalization completeness.

## `proof` — production proof/axiom assurance

```sh
bash Quality/quality.sh proof
```

After the selected-environment preflight, this dimension:

1. builds reusable `Quality.AxiomAudit` under warning-failure mode;
2. runs the production module-origin axiom audit under direct Lean `-DwarningAsError=true`;
3. runs the standard mathematical axiom positive control.

The auditor distinguishes standard mathematical Lean axioms, `sorryAx`, `Lean.trustCompiler`, and custom/unclassified axioms. Deliberate bad controls, including a `Lean.trustCompiler` fixture, live in the regression dimension.

## `source` — source/import/API-boundary structural checks

```sh
bash Quality/quality.sh source
```

After selected-environment validation, runs `Quality/check-source-quality.sh production`.

Profiles:

- supported `FormalMath` source: governed header, module documentation, warning-suppression policy, production import rules;
- permanent `QualityTests` source: governed header, module documentation, warning-suppression policy, test-appropriate import rules;
- permanent `Quality` Lean tooling: governed header and warning-suppression policy.

Selected hard checks include root-umbrella misuse in production, reviewed direct mathlib-transitive roots, explicit public `FormalMath.Internal.*` re-export, and unapproved local `set_option warningAsError false`.

Warning suppression is prohibited by default in supported/permanent source. A bounded exception must appear in `Quality/warning-suppression-exceptions.tsv` with a governed `CEXC-M2-*` ID and rationale. No exception is currently adopted.

Known semantic linter blind spots remain documented in `P2-QA-M2.6-SOURCE-v1`; this command does not claim complete semantic API verification.

## `regression` — positive and intended-failure behavior

```sh
bash Quality/quality.sh regression
```

After selected-environment validation, runs the permanent MAT-178/MAT-182 regression harness. It includes:

- strict production and reusable axiom-auditor builds;
- non-default `QualityTests` positive regression/contract build;
- source positive checks;
- direct `sorry`, transitive `sorryAx`, custom axiom, and `Lean.trustCompiler` controls;
- source-policy controls including permanent-test provenance and warning-suppression rejection;
- executable/noncomputable contract control;
- selected-environment mismatch rejection through a standalone semantic dimension;
- optional-cache failure nonblocking control;
- parallel report-identity collision control;
- the seven test-only FORMREQ-P1-000018 anti-conflation invariants.

Expected-failure fixtures pass only when they return nonzero for the intended signature.

## `all` — orchestration, not collapsed truth

```sh
bash Quality/quality.sh all
```

Runs `env`, then `build`, `proof`, `source`, and `regression`. Each semantic dimension independently revalidates the selected environment before its own gate. After an initially valid environment, `all` continues across failing dimensions so one failure does not hide the others. The final aggregate status is nonzero if any dimension failed, but per-dimension reports remain authoritative execution evidence.

## Collision-resistant revision-bound reports

Every executed dimension receives a unique run directory created with `mktemp`:

```text
.lake/build/quality/<dimension>-<full-git-sha>-<unique-token>/
  result.report
  output.log
```

The full SHA participates in the directory name, and the unique token prevents same-dimension/same-SHA concurrent or rapid retries from overwriting one another.

`result.report` version 2 includes:

- dimension and pass/fail/skipped status;
- exit code;
- exact full Git SHA and ref;
- selected environment baseline path and its Git blob identity;
- committed `lean-toolchain`;
- effective Lean and Lake versions;
- resolved mathlib revision;
- `lake-manifest.json` Git blob;
- platform;
- start/end UTC timestamps;
- exact executed command;
- diagnostic log path.

The report directory is under `.lake/` and remains local build output, not versioned semantic source of truth.

Show the newest report for the **current full SHA**:

```sh
bash Quality/quality.sh report
```

or for one dimension:

```sh
bash Quality/quality.sh report proof
```

## Failure-report workflow

When a quality command fails:

1. preserve the exact run directory (`result.report` + `output.log`) while diagnosing;
2. confirm selected-environment preflight output and recorded SHA/ref/toolchain/mathlib/manifest;
3. identify the failing dimension/gate rather than using aggregate `all` as root cause;
4. treat an expected negative fixture that unexpectedly succeeds as a gate failure;
5. preserve failed milestone validation lineage in Linear;
6. rerun the affected dimension at the corrected revision;
7. rerun broader regression/all surfaces when appropriate;
8. never inherit an earlier SHA's PASS merely because a new revision descends from it.

## CI handoff

M2.7 may call these same commands from permanent CI. M2.6 does not select workflow topology, triggers, required check names, runner matrix, branch/merge policy, concurrency/cancellation, or artifact retention.

M2.7 constraints inherited from M2.6:

- each semantic CI dimension must retain the selected-environment preflight or an explicitly equivalent precondition in the same execution environment;
- cache failure must remain operational/non-semantic and must not masquerade as theorem/build failure;
- build, proof, source, and regression results must remain independently diagnosable;
- report directories are per-execution and collision-resistant;
- platform is recorded; M2.7 decides which platform matrix is required;
- dependency/toolchain updates change the selected environment and therefore require governed baseline update plus full quality revalidation;
- upstream/dependency changes must follow M2.2 dependency/reuse governance rather than being accepted because CI happens to pass.
