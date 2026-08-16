# M2.9 synthetic scalability benchmarks

These fixtures implement empirical engineering workloads governed by `P2-SCALE-M2.9-PROTOCOL-v1` and `P2-SCALE-M2.9-EVIDENCE-v1`.

They are **not mathematical curriculum content**, do not belong to the supported `FormalMath` API, and must never allocate production `FART-P2-*`, `FLOC-P2-*`, or `FLINK-P2-*` identities.

## Build-scaling harness

`bash Benchmarks/run-build-scaling.sh`

Environment controls:

- `BENCH_SIZES` — whitespace-separated positive module-fanout sizes. Default: `8 32 128`.
- `BENCH_REPETITIONS` — measured repetitions per workload. Default: `3`.
- `BENCH_OUT_ROOT` — output root. Default: `.lake/build/benchmarks`.

The harness creates a temporary Lake package under `.lake/build/benchmarks/work/` using the repository's selected Lean toolchain. Each star topology contains a central `Bench.Common`, N leaf modules importing it, and an umbrella module importing the leaves.

Measured workloads are:

1. `clean-project-build` — root build artifacts absent for the synthetic package;
2. `warm-noop-build` — exact source unchanged with compatible project artifacts present;
3. `leaf-module-edit` — one terminal leaf is changed after a warm build;
4. `central-module-edit` — the shared central module is changed after a warm build.

The benchmark records exact Git subject, topology/cardinality vector, iteration, build-artifact/change state, wall time, and pass/fail result to `build-scaling.csv`.

## Interpretation boundary

The benchmark isolates Lean/Lake project-build and import-graph effects. It does **not** model mathematical importance, curriculum percentage, proof difficulty, or future production repository size.

The synthetic package has no mathlib dependency. This is deliberate: upstream mathlib acquisition/cache behavior is measured separately from root project invalidation. The permanent `quality` jobs continue to provide the observed upstream-cache/CI dimensions.

Results are exploratory until a series satisfies the repetition/comparability requirements in the M2.9 measurement protocol. No runtime threshold is encoded in this harness.