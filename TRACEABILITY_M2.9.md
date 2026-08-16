# M2.9 Traceability Provenance & Scale Contract

This document is the additive M2.9 successor contract for generated traceability provenance and scale behavior. It preserves `P2-TRACE-M2.8-v1` authority boundaries.

## Provenance v2

`P2-TRACE-M2.9-PROVENANCE-v2` adds `provenance-v2.json` beside the existing generated M2.8 views. The sidecar is still generated/derived and never becomes authored truth.

It records:

- generator Git revision;
- subject kind;
- subject revision only when the default governed repository root is the subject;
- content fingerprints for the authored formal-artifact registry and curriculum lock;
- combined authoritative-input fingerprint;
- dependency/toolchain baseline references;
- curriculum release and lock state;
- an explicit `content_bound` freshness contract.

## Governed root versus alternate root

For the default root (`.`):

```text
subject_kind = governed_repository_revision
subject_revision = exact generator checkout SHA
repository_revision_claim = exact_generator_checkout
```

For an explicit alternate `--root`:

```text
subject_kind = alternate_root_content_snapshot
subject_revision = not_applicable
repository_revision_claim = none
```

The output directory remains namespaced by the generator revision for compatibility with M2.8 tooling. That directory name is **not** a claim that an alternate root is the same Git revision. Freshness for alternate roots is content-bound through `provenance-v2.json`.

This deliberately narrow contract closes the M2.8 arbitrary-root overclaim without pretending to know the VCS identity of an arbitrary filesystem tree.

## Freshness verification

After generation:

```sh
lake exe traceability freshness
lake exe traceability freshness --root <alternate-root>
```

`freshness` recomputes authored registry + curriculum-lock fingerprints from local files only. It does not query Linear or another external authority. A relevant local input mutation after generation makes freshness fail until the derived output is regenerated.

A freshness PASS means only that the generated provenance sidecar matches the current local authored inputs under the recorded contract. It does not prove that Project 1 has not changed externally and does not turn the curriculum lock into curriculum authority.

## Scale benchmark

`Benchmarks/run-traceability-scaling.sh` constructs non-production synthetic FART/FLOC/FLINK/lock datasets and measures:

- strong validation;
- generation including strong validation;
- content-freshness verification;
- curriculum query including strong validation;
- generated output size;
- deterministic rebuild;
- stale registry detection;
- stale curriculum-lock detection.

Synthetic records reuse a known selected mathlib declaration solely to exercise engineering cardinality. They are never committed into the production registry, never consume production cursors, and carry no curriculum coverage meaning.

Initial regimes are 16, 64, and 256 records, log-spaced by 4×. They are measurement regimes, not performance targets or fractions of the curriculum.

## Optimization rule

No indexing, caching, sharding, or query optimization may weaken:

- canonical authored JSON/JSONL validation;
- cross-record integrity;
- exact current source/dependency resolution;
- curriculum-lock reconciliation;
- set-valued forward/reverse navigation;
- deterministic generated output;
- stale-input detectability;
- the prohibition on inferring curriculum semantics from code/import/dependency structure.

Optimizations are adopted only after measured evidence identifies a material bottleneck. The v2 provenance change itself adds freshness evidence; it does not declare a scale SLA.

## Carry-forward

M2.10 must exercise the adopted provenance/freshness contract in the architecture vertical slice. A later main promotion must regenerate provenance and rerun permanent CI on the exact resulting main revision.
