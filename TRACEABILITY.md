# Curriculum-to-Code Traceability

The repository separates mathematical curriculum authority, stable formal-artifact identity, versioned source location, generated navigation, and revision-scoped verification evidence.

## Authority model

- Project 1 / the governed curriculum release owns curriculum identities, treatments, prerequisite/readiness semantics, Levels, and coverage.
- `metadata/formal-artifacts/` owns Project-2 `FART` (formal-artifact), `FLOC` (versioned locator), and `FLINK` (scoped curriculum link) records at a repository revision.
- Lean source owns what files/modules/declarations actually exist at the selected repository/dependency revision.
- `metadata/curriculum-lock/` is a minimal version-controlled, non-authoritative Project-1 release/lineage mirror for deterministic offline traceability.
- `.lake/build/traceability/<subject-revision>/` contains generated derived navigation only. It is disposable and never authoring truth.
- quality/CI results are revision-scoped assurance evidence; they do not create curriculum identity, readiness, Level, mathematical importance, empirical truth, or curriculum/formalization completeness.

The core relationship is:

```text
curriculum candidate/treatment
          ↕ FLINK
stable formal artifact (FART)
          ↕ FLOC
repository/dependency revision + module/file/declaration
          ↕ generated projections
reader/tool navigation
```

File/module/declaration moves change `FLOC`, not `FART` or curriculum identity. Candidate splits never automatically clone formal artifacts or links.

## Authored registry

M2.8 v1 uses canonical sharded JSON Lines:

```text
metadata/formal-artifacts/
  registry.json
  fart/<id-range>.jsonl
  floc/<id-range>.jsonl
  flink/<id-range>.jsonl
```

The current production registry contains ten FARTs, eleven FLOCs (ten current and one historical), and
ten FLINKs. The next cursors are FART `000011`, FLOC `000012`, and FLINK `000011`. These records cover
only their explicit bounded treatment scopes, including one CAND4 guided exercise and diagnostic;
their presence is not a whole-candidate completeness or learner-readiness claim.

A registry line is canonical only when parsing it with Lean's JSON parser and re-rendering it with `Lean.Json.compress` yields the exact same line. IDs are explicit, stable, monotonic, and never derived from source paths.

## Curriculum lock

`metadata/curriculum-lock/` contains only release/lineage information needed by authored `FLINK` records. Project 1 remains the authority. If a required curriculum identity cannot be resolved from the governed lock, tooling surfaces an unresolved/stale state; it does not silently query Linear or another source and does not invent a resolution.

The current production lock contains exactly CAND-P1-000004, CAND-P1-000009, CAND-P1-000016, and
CAND-P1-000017. It mirrors only the identities needed by current FLINKs and does not copy learner
readiness or prerequisite authority into the repository.

## CLI

The non-default `traceability` executable is tooling infrastructure, not part of the supported `FormalMath` mathematical API.

Validate authored inputs:

```sh
lake exe traceability validate
```

Generate derived views:

```sh
lake exe traceability generate
```

Forward curriculum lookup:

```sh
lake exe traceability query curriculum CAND-P1-000001
```

Formal-artifact lookup:

```sh
lake exe traceability query artifact FART-P2-000001
```

Reverse module/file/declaration lookup:

```sh
lake exe traceability query declaration My.Module.theoremName
```

Verify set-valued forward/reverse consistency:

```sh
lake exe traceability roundtrip
```

Each command also accepts an optional final `--root <repository-root>` argument where supported by the CLI, primarily for governed fixtures and explicit alternate roots.

## Validation

`validate` checks canonical JSON/JSONL, schema/enums, stable ID format/allocation/reservation bounds, shard placement/order, FART/FLOC/FLINK referential integrity, current-locator backreferences, curriculum-lock references, and current project-file existence for current project FLOCs.

Current FLOC module/declaration coordinates are additionally exercised by generated/query/round-trip tooling against a real Lean environment. Historical FLOCs remain navigable historical metadata; they are not required to import in the current checkout.

Direct mathlib reuse is represented as a dependency-repository FLOC with exact dependency revision/module/file/declaration provenance. No upstream source annotation is required.

## Generated views

`generate` first validates authored inputs and resolves current declarations, then writes derived output to:

```text
.lake/build/traceability/<subject-revision>/
  manifest.json
  by-curriculum.jsonl
  by-artifact.jsonl
  by-source.jsonl
  history.jsonl
  unresolved.jsonl
  index.md
```

The generated files are not committed authority and are never read back as FART/FLOC/FLINK truth.

`manifest.json` records the generated-derived authority class, generated schema version, generator/subject revision, curriculum release and lock state, dependency/toolchain baseline references, deterministic source time, record counts, and the semantic fingerprint of the normative generated files.

The main views have distinct purposes:

- `by-curriculum.jsonl` preserves candidate/treatment → FLINK → FART → locator navigation without collapsing multiple representations;
- `by-artifact.jsonl` preserves each FART with its current/historical locators and curriculum links;
- `by-source.jsonl` provides reverse locator/module/file/declaration → FART → curriculum navigation;
- `history.jsonl` keeps non-current FLOCs visible after moves/renames;
- `unresolved.jsonl` surfaces stale/unresolved/needs-review states rather than silently dropping them;
- `index.md` is human-readable generated orientation, not a curriculum taxonomy or Lean course.

## Forward, reverse, and round-trip semantics

Mappings are set-valued. A candidate may have zero, one, or many FART representations. The tooling never chooses a fake canonical representation merely for convenience.

The round-trip check verifies governed edges in both directions:

```text
curriculum/FLINK → FART → FLOC/source
source/FLOC → FART → FLINK/curriculum
```

Expected multiplicity is preserved. Silently dropped or invented governed edges are failures.

## Formalization state is multidimensional

Do not replace independent state axes with one boolean such as `formalized`:

- representation state;
- verification state;
- quality state;
- FLINK treatment/coverage scope.

An example, exercise solution, direct mathlib representation, project wrapper, mathematical model, or alternate encoding can each be a distinct FART linked to the same curriculum identity without cloning that curriculum identity.

A FLINK with `example_of` and `coverage_claim_scope = example_only` does not establish whole-topic coverage. A `model_for` artifact, when verified, proves mathematical consequences of its assumptions; it does not establish empirical adequacy.

## Source annotations

M2.8 v1 deliberately has no machine-consumed custom Lean attribute, command, or structured source comment for FART/FLINK IDs. Reverse navigation is reconstructed from FLOC declaration/module/file coordinates and generated indexes. This keeps the authored registry authoritative and works equally for external mathlib declarations that the project cannot annotate upstream.

Human docstrings may mention traceability IDs as convenience pointers, but tooling does not treat those mentions as registry input.

## Rebuild semantics

Generated output is disposable. For the same governed input tuple, deleting `.lake/build/traceability/<subject-revision>/` and regenerating must reproduce the same semantic fingerprint.

The permanent regression fixture also checks that:

- manual mutation of a generated file is eliminated by regeneration;
- a relevant authored-input mutation changes the generated fingerprint;
- a stale curriculum-lock state remains visible in the generated non-success view.

Generated output is therefore a projection of authority, never an authority feedback channel.

## Quality integration

The permanent quality surface retains the four M2.7 check identities:

```sh
bash Quality/quality.sh build
bash Quality/quality.sh proof
bash Quality/quality.sh source
bash Quality/quality.sh regression
```

`source` validates the production authored registry and compiles/executes the traceability CLI. `regression` preserves all prior controls and adds authored-registry controls plus the non-production generated/query/round-trip/rebuild fixture.

These M2.8 additions are gate-definition changes under `P2-GH-M2.7-v1`. Green CI proves execution; semantic strengthening is reviewed independently. No prior failure condition is removed.

## PR versus main

All generated and quality evidence is revision-scoped. A stacked-PR PASS applies to that exact PR integration context. It is not evidence that `main` contains or has verified the implementation. After an eventual bottom-up merge, the resulting main SHA requires fresh permanent CI and traceability evidence before main-baseline promotion.
