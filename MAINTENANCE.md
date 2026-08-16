# Dependency, Proof-Maintenance & Migration Strategy

This document records the M2.9 maintenance workflow for Lean/mathlib upgrades, declaration moves, proof breakage, deprecation, rollback, and traceability refresh. It does not adopt a dependency upgrade by itself.

## Authority and identity rules

- `P2-ENV-M2.5-v1` and `P2-DEP-M2.2-v1` remain the selected environment/dependency baselines until a governed successor decision is adopted.
- Testing an upgrade or migration is not adoption.
- A file/module/declaration move changes `FLOC`, not `FART`, when the governed formal artifact identity and contract are preserved.
- A materially changed statement/representation is not auto-migrated merely because a name is similar. It requires semantic review and may require a successor/new `FART`.
- Dependency/API evolution never changes curriculum identity, prerequisite structure, Level, readiness, or coverage by implication.
- Historical FLOCs remain history; only current FLOCs must resolve in the selected current environment.

## Upgrade/migration lifecycle

1. **Propose** — identify candidate dependency revision/API move, reason, expected benefit, and affected surfaces.
2. **Isolate** — create a non-production branch/worktree or fixture. Do not mutate the adopted baseline merely to test.
3. **Resolve** — update only the isolated dependency/toolchain/locator inputs required for the scenario.
4. **Build and verify** — run selected-environment checks appropriate to the candidate, full project build, proof/source/regression checks, and traceability validation/generation.
5. **Classify breakage** — distinguish environment resolution, module/file move, declaration rename, type/signature change, proof breakage, deprecation warning, generated-view staleness, or unrelated runner/cache failure.
6. **Migrate explicitly** — for preserved formal identity, add a new current FLOC and demote the old FLOC to historical with reciprocal supersession. Never rewrite stable IDs from paths.
7. **Reject incompatible substitution** — name/path similarity is insufficient. The expected formal contract must still typecheck or receive explicit mathematical review.
8. **Benchmark blast radius** — record affected builds/quality/traceability surfaces using `P2-SCALE-M2.9-PROTOCOL-v1` where meaningful.
9. **Review adoption** — only a governed baseline-successor decision may update selected Lean/mathlib/dependency/environment identifiers.
10. **Regenerate and reverify** — after adoption, regenerate derived traceability views and obtain fresh exact-subject CI. Generated output is never carried forward as authority.

## Rollback

Rollback restores the last adopted authoritative tuple rather than attempting to preserve a partially migrated state:

- `lean-toolchain`;
- `lakefile.toml` dependency ref;
- `lake-manifest.json` resolved dependency graph;
- `Quality/environment-baseline.env` or its governed successor;
- authored FART/FLOC/FLINK records from the last adopted revision;
- generated traceability output is deleted and rebuilt.

A rollback is complete only after semantic environment validation and applicable build/proof/source/regression checks pass on the restored exact revision.

## FART/FLOC decision examples

### Locator-only move

Before:

```text
FART-P2-000001
└── current FLOC-P2-000001 → Old.Module / Old/File.lean / oldDeclaration
```

After a verified move with preserved formal contract:

```text
FART-P2-000001
├── historical FLOC-P2-000001
└── current    FLOC-P2-000002 → New.Module / New/File.lean / newDeclaration
```

The FART remains stable because the formal representation identity is intentionally preserved; the source coordinate changes.

### Incompatible candidate

If a similarly named declaration no longer satisfies the expected theorem/type contract, it is **not** accepted as the new current locator. The migration remains unresolved until reviewed; depending on mathematical meaning, a new/superseding FART may be required.

## Current release boundary for MAT-202

At execution time, mathlib `v4.33.0` is still the latest stable release and is already the selected baseline. Therefore MAT-202 does not manufacture a nonexistent stable successor. Its executable scenario exercises locator/declaration migration and incompatible-substitution rejection while keeping the production environment unchanged.

## Executable control

```sh
bash Quality/check-maintenance-migration-controls.sh
```

The control is synthetic/non-curricular. It verifies:

- a before/after declaration pair with the same expected contract;
- one stable synthetic FART with historical and current FLOCs;
- reciprocal FLOC supersession and derived history visibility;
- rejection of a similarly located/named but contract-incompatible candidate;
- no production environment or production traceability ID allocation.
