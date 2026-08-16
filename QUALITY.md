# Local quality commands

This document defines the supported local quality-command surface for the Formal Mathematics Curriculum repository.

These commands report software/formalization quality dimensions only. They do **not** infer curriculum identity, taxonomy rank, learner readiness, Level, mathematical importance, empirical truth, or curriculum/formalization completeness.

## Selected environment precondition

The selected environment is versioned in `Quality/environment-baseline.env` and currently fixes:

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

1. builds complete `FormalMath` inputs on its own runner;
2. builds reusable `Quality.AxiomAudit` under warning-failure mode;
3. runs the production module-origin axiom audit under direct Lean `-DwarningAsError=true`;
4. runs the standard mathematical axiom positive control.

The auditor distinguishes standard mathematical Lean axioms, `sorryAx`, `Lean.trustCompiler`, and custom/unclassified axioms. Deliberate bad controls, including a `Lean.trustCompiler` fixture, live in the regression dimension.

## `source` — source/API and authored traceability integrity

```sh
bash Quality/quality.sh source
```

After selected-environment validation, this dimension runs both:

```sh
bash Quality/check-source-quality.sh production
lake exe traceability validate
```

Source profiles cover:

- supported `FormalMath` source: governed header, module documentation, warning-suppression policy, production import rules;
- permanent `QualityTests` source: governed header, module documentation, warning-suppression policy, test-appropriate import rules;
- permanent `Quality` and `Traceability` Lean tooling: governed header, warning-suppression policy, and import checks.

Selected hard checks include root-umbrella misuse in production, reviewed direct mathlib-transitive roots, explicit public `FormalMath.Internal.*` re-export, and unapproved local `set_option warningAsError false`.

The traceability validator independently verifies the authored `metadata/formal-artifacts/` registry and minimal `metadata/curriculum-lock/` offline mirror: canonical JSON/JSONL, schema/enums, ID allocation/sharding, referential integrity, current locator backreferences, curriculum-lock references, and current project-file existence for current project locators.

The current production traceability registry is intentionally empty of FART/FLOC/FLINK records; this is a valid state, not evidence of absent curriculum mathematics. Production IDs are not allocated until real eligible formal artifacts exist.

Warning suppression is prohibited by default in supported/permanent source. A bounded exception must appear in `Quality/warning-suppression-exceptions.tsv` with a governed `CEXC-M2-*` ID and rationale. No exception is currently adopted.

Known semantic linter blind spots remain documented in the adopted quality baseline; this command does not claim complete semantic API verification.

## `regression` — positive and intended-failure behavior

```sh
bash Quality/quality.sh regression
```

After selected-environment validation, runs the permanent regression harness. It includes:

- strict production and reusable axiom-auditor builds;
- non-default `QualityTests` positive regression/contract build;
- non-default `traceability` executable build;
- production source and authored-registry validation;
- traceability negative controls for duplicate IDs, dangling references, invalid path-like artifact identity, prohibited conflated `formalized` state, noncanonical JSONL, plus a positive historical→current FLOC move preserving one FART;
- source positive checks;
- direct `sorry`, transitive `sorryAx`, custom axiom, and `Lean.trustCompiler` controls;
- source-policy controls including permanent-test provenance and warning-suppression rejection;
- executable/noncomputable contract control;
- selected-environment mismatch rejection through a standalone semantic dimension;
- optional-cache failure nonblocking control;
- parallel report-identity collision control;
- the seven test-only FORMREQ-P1-000018 anti-conflation invariants.

Expected-failure fixtures pass only when they return nonzero for the intended signature.

The M2.8 traceability additions are a **gate-definition change** under `P2-GH-M2.7-v1`: green CI proves execution, but semantic equivalence/strengthening must also be reviewed explicitly. The intended change is monotonic with respect to prior source/regression behavior: every pre-existing subgate remains present, and new traceability checks add failure conditions rather than removing existing ones.

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

`result.report` version 2 includes dimension/status, exit code, exact SHA/ref, selected-environment baseline identity, toolchain/Lake/mathlib/manifest provenance, platform, timestamps, exact command, and diagnostic log path.

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

## Permanent CI

M2.7 wires these commands into four permanent independently visible checks:

- `quality / build`
- `quality / proof`
- `quality / source`
- `quality / regression`

M2.8 does not rename or collapse these checks. Traceability integrity is added to the existing `source` and `regression` semantics. PR PASS remains scoped to the exact PR integration context; a later merged `main` SHA requires its own permanent CI before baseline promotion.
