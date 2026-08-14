# Lean Formal Mathematics Curriculum

Mathematics lessons, definitions, proofs, examples, and exercises written in Lean 4.

## Development baseline

The initial formalization environment is pinned to:

- Lean `v4.33.0`
- mathlib `v4.33.0`

The repository uses a single root Lake package with the primary Lean library `FormalMath`.

## Build

Use authenticated access to this private repository, clone it, and **check out the branch/ref/SHA you intend to reproduce before running environment commands**. Do not assume the default branch already contains an unmerged environment change.

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

## Source layout

- `FormalMath.lean` — convenience root for the supported library API.
- `FormalMath/` — Lean modules in the `FormalMath.*` module hierarchy.
- `.lake/` — local Lake dependencies/build artifacts; ignored by Git.

Repository structure and Lean module/import structure are software architecture and do not define curriculum taxonomy or learner prerequisites.

## License

See [`LICENSE`](LICENSE).
