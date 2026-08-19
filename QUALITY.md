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

Cache success is reported. Cache failure is reported as `quality-env:cache:nonblocking-fail` and does not convert an otherwise valid selected environment into semantic failure. Cache availability is acceleration only, not proof/build/curriculum evidence.

If the semantic preflight fails during `all`, environment-dependent dimensions are reported as **skipped** rather than executed under a knowingly invalid environment.

## `build` — complete production build / warning gate

```sh
bash Quality/quality.sh build
```

Runs the selected-environment preflight and then `lake build --wfail FormalMath`.

A PASS means the complete supported mathematical library target built under the selected environment at the recorded SHA with Lake warning-failure semantics. It does not imply curriculum or formalization completeness.

## `proof` — production proof/axiom assurance

```sh
bash Quality/quality.sh proof
```

After the selected-environment preflight, this dimension:

1. builds complete `FormalMath` inputs on its own runner;
2. builds reusable `Quality.AxiomAudit` under warning-failure mode;
3. runs the production module-origin axiom audit under direct Lean `-DwarningAsError=true`;
4. runs the standard mathematical axiom positive control.

The auditor distinguishes standard mathematical Lean axioms, `sorryAx`, `Lean.trustCompiler`, and custom/unclassified axioms. Deliberate bad controls live in regression.

## `source` — source/API and authored traceability integrity

```sh
bash Quality/quality.sh source
```

After selected-environment validation, this dimension runs:

```sh
bash Quality/check-source-quality.sh production
lake exe traceability validate
```

Source profiles cover supported `FormalMath`, permanent `QualityTests`, and permanent `Quality`/`Traceability` tooling for governed headers, module documentation where required, warning-suppression policy, and import/API rules.

Selected hard checks include root-umbrella misuse in production, reviewed direct mathlib-transitive roots, explicit public `FormalMath.Internal.*` re-export, and unapproved local `set_option warningAsError false`.

The traceability validator verifies the authored `metadata/formal-artifacts/` registry and minimal `metadata/curriculum-lock/` mirror: canonical JSON/JSONL, schema/enums, stable-ID allocation/sharding/reservation bounds, referential integrity, current locator backreferences, curriculum-lock references, and current project-file existence for current project locators.

Because the executable imports the generated/query/round-trip modules, this dimension also ensures the complete M2.8 traceability CLI compiles before `validate` executes.

The current production traceability registry is intentionally empty of FART/FLOC/FLINK records; this is a valid state, not evidence of absent curriculum mathematics. Production IDs are not allocated until real eligible formal artifacts exist.

Warning suppression is prohibited by default in supported/permanent source. A bounded exception must appear in `Quality/warning-suppression-exceptions.tsv` with a governed `CEXC-M2-*` ID and rationale. No exception is currently adopted.

## `regression` — positive, intended-failure, and traceability behavior

```sh
bash Quality/quality.sh regression
```

After selected-environment validation, the permanent regression harness includes:

- strict production and reusable axiom-auditor builds;
- non-default `QualityTests` positive regression/contract build;
- full non-default `traceability` executable build under `--wfail`;
- production source and authored-registry validation;
- authored traceability controls for duplicate IDs, dangling references, invalid path-like artifact identity, prohibited conflated `formalized` state, noncanonical JSONL, issued/reserved cursor bounds, shard order, plus a valid historical→current FLOC move preserving one FART;
- **generated traceability controls** through `Quality/check-traceability-generated-controls.sh`;
- source positive checks and source-policy negative controls;
- direct `sorry`, transitive `sorryAx`, custom axiom, and `Lean.trustCompiler` controls;
- executable/noncomputable contract control;
- selected-environment mismatch rejection;
- optional-cache failure nonblocking control;
- parallel report-identity collision control;
- the seven test-only FORMREQ-P1-000018 anti-conflation invariants.

Expected-failure fixtures pass only when they return nonzero for the intended signature.

### Generated traceability control

The generated-control harness creates a **temporary non-production** registry; it does not allocate production FART/FLOC/FLINK IDs.

Its representative dataset contains:

- multiple formal artifacts linked to one curriculum candidate without deduplication;
- an `example_of` artifact with `example_only` coverage scope;
- a science-facing `model_for` artifact with explicit review/non-empirical semantics;
- a historical-to-current project locator chain;
- a direct mathlib locator pinned to the selected mathlib revision;
- current project and mathlib declaration coordinates resolved through the Lean environment.

The control verifies:

1. authored fixture validation;
2. `roundtrip` current-module/declaration resolution and set-valued forward/reverse containment;
3. generated view inventory under `.lake/build/traceability/<subject-revision>/`;
4. curriculum, artifact, and declaration queries;
5. preservation of multiple representations and partial coverage semantics;
6. historical-locator navigation and direct-dependency provenance;
7. delete/rebuild semantic-fingerprint equivalence;
8. recovery from manual generated-output mutation;
9. semantic-fingerprint sensitivity to a relevant authored-input mutation;
10. stale curriculum-lock visibility in the generated non-success view.

The successful control emits `traceability-generated-control:summary:pass`. This marker is required evidence that the generated/query/round-trip/rebuild surface actually executed; a green job that omits this subgate is not MAT-196 acceptance evidence.

## Traceability CLI assurance

The non-default tooling CLI supports:

```sh
lake exe traceability validate
lake exe traceability generate
lake exe traceability query curriculum <candidate-id>
lake exe traceability query artifact <FART-id>
lake exe traceability query declaration <module-file-or-declaration>
lake exe traceability roundtrip
```

Current FLOC modules/declarations are resolved against a real Lean environment for generation, reverse declaration query, and round-trip verification. Historical FLOCs remain historical metadata and are not required to import successfully in the current checkout.

Generated output is derived and disposable. For the same governed input tuple, delete/rebuild must preserve the semantic fingerprint; manual generated mutation is overwritten by regeneration, while relevant authored-input changes must alter the semantic projection.

## Gate-definition trust

M2.8 additions are gate-definition changes under `P2-GH-M2.7-v1`. Green CI proves execution, but does not self-certify semantic equivalence or strengthening.

The MAT-195 authored-registry change was separately reviewed under `TRVER-M2-000001`. The MAT-196 generated/query/round-trip change is separately reviewed under `TRVER-M2-000003`.

The MAT-196 regression delta is monotonic: every pre-existing subgate remains present and a single additional `traceability-generated-controls` subgate adds failure conditions; permanent workflow/check names are unchanged.

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

The report directory is local build output, not versioned semantic source of truth.

Show the newest report for the current full SHA with `bash Quality/quality.sh report`, optionally followed by a dimension such as `proof`.

## Failure-report workflow

When a quality command fails:

1. preserve the exact run directory (`result.report` + `output.log`) while diagnosing;
2. confirm selected-environment preflight output and recorded SHA/ref/toolchain/mathlib/manifest;
3. identify the failing dimension/gate rather than using aggregate `all` as root cause;
4. treat an expected negative fixture that unexpectedly succeeds as a gate failure;
5. preserve failed milestone validation lineage in Linear;
6. rerun the affected dimension at the corrected revision;
7. rerun broader regression/all surfaces when appropriate;
8. never inherit an earlier SHA's PASS merely because a new revision descends from it;
9. inspect required subgate markers when acceptance depends on newly added gate semantics.

## Permanent CI

M2.7 wires these commands into four permanent independently visible checks:

- `quality / build`
- `quality / proof`
- `quality / source`
- `quality / regression`

M2.8 does not rename or collapse these checks. Traceability assurance is integrated into the existing `source` and `regression` semantics. PR PASS remains scoped to the exact PR integration context; a later merged `main` SHA requires its own permanent CI before baseline promotion.
