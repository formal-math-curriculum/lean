# Project 6 publication handoff v1

This directory is the deterministic Lean-owned handoff for the adopted Project-5 v2 publication contract. It publishes formal authority and coverage facts at the frozen M6.6 subject `5b592af5807467d600184d376f1a1d5920ddddbd`.

Run:

```text
python3 publication/p6-v1/generate.py --check
python3 Quality/check-p6-publication.py
```

Run the generator without `--check` only when an authority input intentionally changes. Generated files use canonical JSON (UTF-8, sorted keys, two-space indentation, LF, one terminal newline). The manifest pins input Git blobs, Lean/toolchain/mathlib revisions, output SHA-256 values, generator fingerprint and semantic fingerprint.

Ownership boundary:

- Lean owns FART/FLOC/FLINK, source locators, formal import/dependency facts and reproducibility evidence.
- Content governance owns canonical content IDs, editorial truth and curated OntoMathPRO/MSC2020/arXiv mappings.
- Site code owns generated presentation, never underlying authority.
- Filesystem paths are source locators only. They do not define Course hierarchy, order or learner prerequisites.

The 52-row scope output makes missing formal representation explicit. The 156 external-system rows are coverage states only and remain `needs_review`; null external IDs are intentional. Verification is a vector, maturity is revision-scoped and correspondence remains treatment-scoped.

This packet does not create a Project-6 release, mutate content/site, start M6.8 or authorize Project 16.
