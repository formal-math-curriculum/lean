# Curriculum-to-Code Traceability

The repository separates mathematical curriculum authority, formal-artifact identity, source location, and verification evidence.

## Authority model

- Project 1 / the governed curriculum release owns curriculum identities, treatments, prerequisite/readiness semantics, Levels, and coverage.
- `metadata/formal-artifacts/` owns Project-2 `FART` (formal-artifact), `FLOC` (versioned locator), and `FLINK` (scoped curriculum link) records at a repository revision.
- Lean source owns what files/modules/declarations actually exist at the selected revision.
- quality/CI results are revision-scoped assurance evidence; they do not create curriculum identity, readiness, Level, mathematical importance, or empirical adequacy.
- generated indexes are derived and rebuildable; they are never authoring truth.

The core relationship is:

```text
curriculum candidate/treatment
          ↕ FLINK
stable formal artifact (FART)
          ↕ FLOC
repository/dependency revision + module/file/declaration
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

The current bootstrap intentionally allocates **no production FART/FLOC/FLINK IDs**. The repository does not yet contain curriculum mathematics that would justify manufacturing coverage records merely to populate the registry. All three next-ID cursors therefore remain at `000001`.

A registry line is canonical only when parsing it with Lean's JSON parser and re-rendering it with `Lean.Json.compress` yields the exact same line. IDs are explicit, stable, monotonic, and never derived from source paths.

## Curriculum lock

`metadata/curriculum-lock/` is a minimal, version-controlled, **non-authoritative** mirror used so local validation and CI do not require live Linear access.

It contains only release/lineage information needed by authored `FLINK` records. Project 1 remains the authority. If a required curriculum identity cannot be resolved from the governed lock, tooling surfaces an unresolved/stale state; it does not silently query another source or invent a resolution.

The current lock contains no linked identities because the production FLINK registry is empty.

## Validate

From the exact repository revision you want to inspect:

```sh
lake exe traceability validate
```

To validate a fixture or another checkout root:

```sh
lake exe traceability validate --root /path/to/root
```

Validation includes canonical JSON/JSONL, schema/enums, ID format and allocation density, shard placement, FART/FLOC/FLINK referential integrity, current-locator backreferences, curriculum-lock references, and current project-file existence for current project locators.

The permanent local quality surface also runs traceability integrity through the existing independent check dimensions:

```sh
bash Quality/quality.sh source
bash Quality/quality.sh regression
```

The `source` dimension validates the production registry. The `regression` dimension builds the validator and exercises deliberate controls including duplicate IDs, dangling references, path-like invalid artifact IDs, the prohibited conflated `formalized` field, noncanonical JSONL, and a valid historical-to-current FLOC move that preserves one FART identity.

## Formalization state is multidimensional

Do not replace the registry's independent state axes with one boolean such as `formalized`:

- representation state
- verification state
- quality state
- FLINK treatment/coverage scope

An example, exercise solution, direct mathlib representation, project wrapper, or alternate encoding can each be a distinct FART linked to the same curriculum identity without cloning that curriculum identity.

## Source annotations

M2.8 v1 deliberately has no machine-consumed custom Lean attribute, command, or structured source comment for FART/FLINK IDs. Reverse navigation is reconstructed from FLOC declaration/module/file coordinates. This keeps the authored registry authoritative and works equally for external mathlib declarations that the project cannot annotate upstream.

Human docstrings may mention traceability IDs as convenience pointers, but tooling does not treat those mentions as registry input.

## Generated documentation

Generated reverse indexes and reader navigation are the next M2.8 implementation layer. Their governed location is under `.lake/build/traceability/<subject-revision>/`; they are not committed as authoritative source. See the M2.8 documentation/rebuild architecture in Linear for the normative generated-view contract.
