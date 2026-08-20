# Lean Formal Mathematics Curriculum

Mathematics lessons, definitions, proofs, examples, and exercises written in Lean 4.

## Development baseline

The initial formalization environment is pinned to:

- Lean `v4.33.0`
- mathlib `v4.33.0`

The repository uses a single root Lake package with the primary Lean library `FormalMath`.

## Build

Clone the public repository (authentication is required only for authorized writes), and **check out
the branch/ref/SHA you intend to reproduce before running environment commands**. Do not assume the
default branch already contains an unmerged environment change.

Verify the effective toolchain:

```sh
elan show
lean --version
lake --version
```

Build the complete primary library:

```sh
lake build FormalMath
```

The committed `lake-manifest.json` records the resolved dependency revisions. `lake exe cache get` may be used as an optional acceleration step when available; caches are not part of the semantic source of truth.

For exact revision selection, fresh setup, cold reproduction, toolchain-drift recovery, and environment diagnostics, see [`DEVELOPMENT.md`](DEVELOPMENT.md).

## Quality checks

The supported local quality surface is documented in [`QUALITY.md`](QUALITY.md). Each dimension is independently runnable and revision-bound:

```sh
bash Quality/quality.sh env
bash Quality/quality.sh build
bash Quality/quality.sh proof
bash Quality/quality.sh source
bash Quality/quality.sh regression
```

`bash Quality/quality.sh all` is convenience orchestration only; it does not collapse the underlying gate dimensions into one canonical truth.

## Curriculum-to-code traceability

Authored formal-artifact identity/location/link records and the deterministic validator are documented in [`TRACEABILITY.md`](TRACEABILITY.md).

Validate the selected revision's authored traceability state with:

```sh
lake exe traceability validate
```

The traceability registry does not define curriculum taxonomy, learner prerequisites, Levels, readiness, or mathematical coverage. It links governed Project-1 curriculum identities/treatments to stable Project-2 formal-artifact identities and versioned code/dependency locations.

The supported mathematical root currently exposes the bounded M2.10 factored-integer-equation slice,
two concrete natural-number operation-law examples, and two concrete integer sign-law examples. The
root also exposes one bounded guided natural-number exercise that makes cancellation, distributivity,
and the final answer explicit, together with one diagnostic counterexample. Canonical laws are reused
directly from Lean/mathlib; the local examples and exercise do not claim full arithmetic-operations,
integer-topic, grade-order, learner-readiness, or full-candidate coverage.

## Source layout

- `FormalMath.lean` — convenience root for the supported library API.
- `FormalMath/` — Lean modules in the `FormalMath.*` module hierarchy.
- `Traceability/` — non-default M2.8 traceability validator/tooling; not part of the mathematical API.
- `metadata/formal-artifacts/` — authored FART/FLOC/FLINK registry surface.
- `metadata/curriculum-lock/` — minimal non-authoritative offline mirror for linked curriculum identities.
- `.lake/` — local Lake dependencies/build/generated artifacts; ignored by Git.

Repository structure and Lean module/import structure are software architecture and do not define curriculum taxonomy or learner prerequisites.

## License

See [`LICENSE`](LICENSE).
