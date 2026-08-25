# P6-FORMALIZATION-RELEASE-v1

This manifest defines one bounded Project-6 formalization release. It does not claim that the whole
curriculum, any whole candidate row, arithmetic, number theory, discrete mathematics, geometry,
measurement or elementary algebra is completely formalized.

## Immutable release subject

- Release identity: `P6-FORMALIZATION-RELEASE-v1`
- Curriculum authority: `P1-CURR-v1`
- Repository: `formal-math-curriculum/lean`
- Repository manifest: `RELEASES/P6-FORMALIZATION-RELEASE-v1.md`
- Authorizing issue: [MAT-469](https://linear.app/verified-mathematics/issue/MAT-469/integrate-and-publish-p6-formalization-release-v1-and-close-project-6)
- Integration PR: [#35](https://github.com/formal-math-curriculum/lean/pull/35)
- Frozen release base: `8228da5c2abfe6bf6eac6aebe4f3cada8ed30b94`
- M6.9 adopted baseline: `9c4339f9-26eb-4868-a659-9945e54b4158@2026-08-25T19:39:25.754Z`
- M6.9 current selector: `35e43976-3d21-4a7a-943c-b7145a2a9b37@2026-08-25T19:37:55.686Z`
- M6.10 release freeze: `6734f496-d31e-4cac-9d68-aaa0e644dd07@2026-08-25T19:44:50.424Z`
- Annotated tag: [`formalization/p6-v1`](https://github.com/formal-math-curriculum/lean/tree/formalization/p6-v1)

The released Git subject is the commit peeled from the annotated tag. The tag may be created only
after this PR is merged by the governed merge method, its merge tree equals the independently
audited final-head tree, and all permanent quality and P6 integration checks pass again on the exact
resulting `main` commit. The tag is immutable and must never be moved, deleted or recreated.

The durable Linear release record attached to MAT-474 resolves the exact final PR head, merge commit,
tree, ordered parents, post-main runs, jobs, artifacts, annotated tag object and peeled commit. This
relationship avoids an impossible self-reference to this file's own containing commit and tag
object. A GitHub Release object is not required and must not be inferred from the tag.

## Bounded curriculum coverage

Exact scope rows: 52. Exactly 8 rows are represented only at the treatment scopes below. Explicit
not represented (44) rows remain in the release scope and are not silently excluded or delayed.

| Curriculum identity | Released treatment scope | Representation boundary |
| --- | --- | --- |
| `CAND-P1-000004` | natural-number additive/multiplicative monoid laws; distributivity; two examples; one distributive-cancellation exercise and diagnostic | Partial treatment; not whole-row coverage |
| `CAND-P1-000009` | integer additive inverses, subtraction of a negative, product of two negative integers and two examples | Partial treatment; not whole-row coverage |
| `CAND-P1-000016` | factored integer expression construction | Bounded construction only |
| `CAND-P1-000017` | integer zero-product solution characterization and roots-2-and-5 example | Bounded theorem and example only |
| `CAND-P1-000018` | composite-function graph membership and one concrete example | Partial function/composition treatment only |
| `CAND-P1-000019` | function graph definition, membership result and shared composite example | No plotting, slope or analytic-geometry completion |
| `CAND-P1-000024` | set invariance definition, identity result and Bool-universe example | Identity transformation only; no symmetry classification |
| `CAND-P1-000027` | three mensuration formulas, argument-symmetry results, worked values/diagnostic and one solution | Real-valued formulas only; no units, positivity or whole-mensuration claim |

### Explicit not represented (44)

`CAND-P1-000001`, `CAND-P1-000002`, `CAND-P1-000003`, `CAND-P1-000005`,
`CAND-P1-000006`, `CAND-P1-000007`, `CAND-P1-000008`, `CAND-P1-000010`,
`CAND-P1-000011`, `CAND-P1-000012`, `CAND-P1-000013`, `CAND-P1-000014`,
`CAND-P1-000015`, `CAND-P1-000020`, `CAND-P1-000021`, `CAND-P1-000022`,
`CAND-P1-000023`, `CAND-P1-000025`, `CAND-P1-000026`, `CAND-P1-000028`,
`CAND-P1-000029`, `CAND-P1-000030`, `CAND-P1-000031`, `CAND-P1-000032`,
`CAND-P1-000033`, `CAND-P1-000034`, `CAND-P1-000035`, `CAND-P1-000036`,
`CAND-P1-000037`, `CAND-P1-000038`, `CAND-P1-000039`, `CAND-P1-000040`,
`CAND-P1-000041`, `CAND-P1-000042`, `CAND-P1-000043`, `CAND-P1-000044`,
`CAND-P1-000045`, `CAND-P1-000046`, `CAND-P1-000521`, `CAND-P1-000522`,
`CAND-P1-000529`, `CAND-P1-000530`, `CAND-P1-000531`, `CAND-P1-000532`.

## Formal authority and publication facts

- FART: 21
- FLOC: 22 total = 21 current + 1 historical
- FLINK: 22
- curriculum-lock linked identities: 8
- representation bindings: 22
- project module sources: 17
- typed Lean import edges: 19
- external dependency locators: 4
- external alignment coverage: 156; all needs_review; all external IDs null
- projections: Course, OntoMathPRO, MSC2020, arXiv, Lean/mathlib
- maturity: `reviewed_active`, revision-scoped
- verification: four-component verification vector
- formal packet subject: `5b592af5807467d600184d376f1a1d5920ddddbd`
- semantic fingerprint: `cc71d82820de2fe29f30364067996dececb6cae2458e67d83f73cc74548116ab`
- generator SHA-256: `318b48b3e02bf2a37e320879a58e58ffde5a9269f7f86e6dddb97d6c7131c6f9`

Every representation join resolves FLINK to FART to a current FLOC. Historical
`FLOC-P2-000003` is preserved for provenance but is not a current join target. Learner prerequisites,
proof dependencies, Lean imports, repository build dependencies and Course order remain distinct.

### Publication packet identities

| Path | Git blob | SHA-256 |
| --- | --- | --- |
| `publication/p6-v1/generate.py` | `d3c7db2b9bcb5a492b0863dbe836e1a7889908f0` | `318b48b3e02bf2a37e320879a58e58ffde5a9269f7f86e6dddb97d6c7131c6f9` |
| `publication/p6-v1/source/scope.json` | `0ec3ecb795599569f9557226ff5ef6bb3c8a10a5` | `0201abb95c7c7dcb7890fe55e669c7ec406c7c36c7b2b525d55b667a6eebe6f5` |
| `publication/p6-v1/generated/release-scope.json` | `6a56e86bd91e74368548541a328338f151ac3001` | `55671c424178740b946fb5815289008487d020cbeeb7808656c2a5faf4349d6a` |
| `publication/p6-v1/generated/formal-authority.json` | `460906e7ab4098fdffdba380ad0f62ae0c3b17ef` | `c0b17e560855dd0aeb633ccc67ce6c3813150c54f8270dd9ddeb4da77831e747` |
| `publication/p6-v1/generated/formal-dependencies.json` | `6b13fef287afa0530158a8d27888b0b711d99eb2` | `7d3defcb6646f1a036950124600abcf361eaaa0adbb5eb73867b431f08f42ffd` |
| `publication/p6-v1/generated/representation-bindings.json` | `7b65fca119f9ff786829917a9978df575aedec31` | `8d4b4390d892c6418228742650ec989415ec80d3904fc6e24ee3462833e9b9a4` |
| `publication/p6-v1/generated/external-alignment-coverage.json` | `8a11310156c9f3bf6b286371531edbcadc23125e` | `e23701dfa9a1a32c0f2e1bea69b71da8cb7e5e458261b94c961ba6ebf8fb2293` |
| `publication/p6-v1/generated/publication-manifest.json` | `e3bec0486691359b137dfb1547edad2ef574727e` | `5485434cea4dabfb8f1d06da2eb045a7ace520031275e972eb0b791f537e9b45` |

## Governed project declarations

- `FormalMath.Algebra.factoredProduct`
- `FormalMath.Algebra.factoredProduct_eq_zero_iff`
- `FormalMath.Geometry.IsInvariantUnder`
- `FormalMath.Geometry.isInvariantUnder_id`
- `FormalMath.Measurement.rectangleArea`
- `FormalMath.Measurement.rectangleArea_comm`
- `FormalMath.Measurement.rectanglePerimeter`
- `FormalMath.Measurement.rectanglePerimeter_comm`
- `FormalMath.Measurement.rectangularPrismVolume`
- `FormalMath.Measurement.rectangularPrismVolume_swap_length_width`
- `FormalMath.Relations.graphOf`
- `FormalMath.Relations.mem_graphOf_comp_iff`
- `FormalMath.Relations.mem_graphOf_iff`
- `FormalMath.Algebra.Examples.two_five_factored_equation`
- `FormalMath.Arithmetic.Examples.cancel_common_nine_addend`
- `FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four`
- `FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three`
- `FormalMath.Arithmetic.Examples.seven_sub_neg_three`
- `FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong`
- `FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution`
- `FormalMath.Geometry.Examples.bool_univ_invariant_under_id`
- `FormalMath.Measurement.Examples.rectangle_three_four_perimeter_ne_area`
- `FormalMath.Measurement.Examples.rectangle_three_four_values`
- `FormalMath.Measurement.Exercises.rectangularPrism_two_three_four_solution`
- `FormalMath.Relations.Examples.successor_then_double_graph_contains_three_eight`

Pinned direct-dependency reuse:

- `Nat.instAddCancelCommMonoid`
- `Nat.instCommMonoid`
- `Nat.instDistrib`
- `Int.instAddCommGroup`
- `Int.instCommRing`

These are exact library/proof dependencies at the selected mathlib revision. They do not become
learner prerequisites, Course order or whole-row coverage.

## Environment and reproducible verification

- Lean toolchain: `leanprover/lean4:v4.33.0`
- mathlib revision: `db584cd6d46c92f209a44c0f1c829460d327499d`
- `lean-toolchain` Git blob: `025e59548e48cf71f2744154e2890beefe30a258`
- `lake-manifest.json` Git blob: `b45d9c37e5168cf22bdd886bee5073f025cee29a`
- formal-artifact registry Git blob: `1e9001529dba66d4223544c9510a60f12fef28db`
- FART shard Git blob: `7634a6e3408e633bedfd40e471137dced4225cab`
- FLOC shard Git blob: `ef5c23897948a68c691fc741066586ee4832ea92`
- FLINK shard Git blob: `7ff47aa509f76d6c866d43084a91ba44d29e4563`
- curriculum-lock identities Git blob: `d05fba62472bf73ff21dda858327fdb16e47c84b`

Run separately on the exact checkout:

```sh
bash Quality/quality.sh env
bash Quality/quality.sh build
bash Quality/quality.sh proof
bash Quality/quality.sh source
bash Quality/quality.sh regression
lake exe traceability validate
lake exe traceability roundtrip
python3 publication/p6-v1/generate.py --check
python3 Quality/check-p6-publication.py
python3 Quality/check-p6-release.py
bash Quality/check-p6-integration-controls.sh
```

Entry evidence belongs to pre-release main and is not final release evidence:

- quality run `32885242097`, jobs `97924042502`, `97924043061`, `97924043175`, `97924043204`, all success;
- integration run `32885242083`, job `97924042590`, success;
- artifact `9578472323`, digest `sha256:cf080ae815cddb76bf93f5f7709ce7fff85d9ba87eff12d230ca289a9f06b0b3`;
- 4 warmups + 12 passing measurements; threshold null; no SLA.

Final release promotion requires fresh final-head PR evidence, independent release audit, guarded
merge, all required post-main evidence on the merge commit, and only then annotated-tag creation and
peeled-target verification. Evidence from another SHA cannot satisfy those gates.

## Project 5 handoff

Project 5 consumes generated formal facts only from:

- `publication/p6-v1/generated/release-scope.json`
- `publication/p6-v1/generated/formal-authority.json`
- `publication/p6-v1/generated/formal-dependencies.json`
- `publication/p6-v1/generated/representation-bindings.json`
- `publication/p6-v1/generated/external-alignment-coverage.json`
- `publication/p6-v1/generated/publication-manifest.json`

Consumers key joins by canonical candidate/treatment/FART/FLOC/FLINK identities and verify the
semantic fingerprint, Git blobs, SHA-256 values, tagged peeled commit and durable Linear release
record. Lean owns formal facts and reproducibility evidence; content governance owns canonical
content/editorial/classification truth; the site owns presentation output only. A consumer must
reject drift, invented mapping, path-derived hierarchy, maturity/verification overclaim or a tag
that is not annotated and peeled to the recorded release commit.

## Known limitations, invalidation and rollback

- Forty-four rows are explicitly not represented.
- The eight represented rows are partial treatment scopes, not whole rows.
- External alignments remain unadopted: all `needs_review`, all external IDs null.
- The historical locator is provenance only.
- Performance evidence is runner/revision/workload specific; there is no SLA.
- No Project-7 implementation, specialization phase or whole-curriculum completion is included.
- A checkout other than the annotated tag's peeled commit is not this release.

Before merge, rollback is PR/branch closure without `main` or tag mutation. A merged but unqualified
main must not be tagged or called released. After tag publication, the tag must never move, be
deleted or be recreated; corrections require a successor release identity and preserved lineage.
Any source, dependency, toolchain, registry, public API, scope, publication packet, checker or
manifest change requires affected-gate requalification and normally a successor release.
