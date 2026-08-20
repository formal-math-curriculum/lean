# P4-FORMALIZATION-RELEASE-v1

This manifest defines the first bounded verified-curriculum formalization release of Project 4. It
does not claim that the whole curriculum, or any whole candidate listed below, is formalized.

## Immutable release subject

- Release identity: `P4-FORMALIZATION-RELEASE-v1`
- Curriculum authority: `P1-CURR-v1`
- Repository: `formal-math-curriculum/lean`
- Authorizing issue: [MAT-411](https://linear.app/verified-mathematics/issue/MAT-411/remediate-m47-findings-and-publish-the-first-verified-curriculum)
- Integration PR: [#28](https://github.com/formal-math-curriculum/lean/pull/28)
- Frozen PR base: `0227b33af78b555b42778c336e6d01da74fb6b9c`
- Remediation implementation commit: `eff23329a550e34b76275f16f8fbda50fc2ab992`
- Annotated tag: `formalization/p4-v1`

The released Git subject is the commit peeled from the annotated tag, not an unmerged PR head. The
tag may be created only after PR #28 is merged with the governed merge method and all four permanent
checks pass again on the resulting `main` commit. The tag is immutable and must never be moved. The
durable M4.8 release record in Linear resolves the tag object, peeled merge commit, parents, tree,
final PR head, workflow run, jobs, and artifacts. This relationship avoids embedding an impossible
self-reference to this file's own containing commit.

## Bounded curriculum coverage

| Curriculum identity | Released treatment scope | Representation boundary |
| --- | --- | --- |
| `CAND-P1-000004` | natural-number additive/multiplicative monoid laws; distributivity; two operation-law examples; one guided distributive-cancellation exercise and one diagnostic counterexample | Partial treatment plus bounded examples/exercise; not full CAND4 coverage |
| `CAND-P1-000009` | integer additive inverses and subtraction of a negative; product of two negative integers; two signed-operation examples | Partial treatment plus bounded examples; not full CAND9 coverage |
| `CAND-P1-000016` | factored integer expression construction used by the selected equation-solving slice | Bounded construction only |
| `CAND-P1-000017` | integer zero-product solution characterization and the roots-2-and-5 worked example | Bounded theorem and one example; not whole-topic coverage |

The release bundle reaches the Project-4 `FM7` release-baseline state only when the tag qualification
contract above is satisfied. Authored FART records remain the declaration-level source of their
`reviewed` and `regression_verified` states; this manifest does not rewrite those records or infer
learner readiness, grade order, or prerequisite edges from Lean imports.

## Governed project declarations

- `FormalMath.Algebra.factoredProduct`
- `FormalMath.Algebra.factoredProduct_eq_zero_iff`
- `FormalMath.Algebra.Examples.two_five_factored_equation`
- `FormalMath.Arithmetic.Examples.cancel_common_nine_addend`
- `FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three`
- `FormalMath.Arithmetic.Examples.seven_sub_neg_three`
- `FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four`
- `FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution`
- `FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong`

The pinned direct-dependency representations include `Nat.instAddCancelCommMonoid`,
`Nat.instCommMonoid`, `Nat.instDistrib`, `Int.instAddCommGroup`, and `Int.instCommRing`. They are
library/proof dependencies and do not thereby become learner prerequisites.

## Environment and reproducible verification

- Lean toolchain: `leanprover/lean4:v4.33.0`
- Lean commit: `d8b18978322de05a8f3dba51ef03cf5461676c17`
- Lake: `5.0.0-src+d8b1897`
- mathlib input: `v4.33.0`
- resolved mathlib revision: `db584cd6d46c92f209a44c0f1c829460d327499d`
- dependency baseline: `P2-DEP-M2.2-v1`
- environment baseline: `P2-ENV-M2.5-v1`
- traceability protocol: `P2-TRACE-M2.8-PROTOCOL-v1`

After cloning the public repository, check out `formalization/p4-v1`, confirm the tag is annotated and
peels to the expected commit recorded in MAT-411's completion package, and run each dimension
separately:

```sh
bash Quality/quality.sh env
bash Quality/quality.sh build
bash Quality/quality.sh proof
bash Quality/quality.sh source
bash Quality/quality.sh regression
lake exe traceability validate
```

The regression dimension includes intended-failure proof/trust controls, source/API controls,
traceability controls, exact root theorem-type contracts, and a TERM-resistant cache-descendant
control that requires both zero surviving descendants and an explicit PASS report. Optional build
caches are acceleration only and are not proof, source, curriculum, or release evidence.

## Sources and traceability

The authored registry under `metadata/formal-artifacts/` is the canonical repository record for
FART/FLOC/FLINK identities, declaration coordinates, source provenance, coverage scope, and current
or historical locators. `metadata/curriculum-lock/` is a minimal non-authoritative mirror of the
linked `P1-CURR-v1` identities. Mathematical source selections and reuse classifications are governed
by the M2.10 specification package, the M4.2 research package, the M4.4 adjacent-slice decision, and
the M4.5 pedagogical-alignment decision referenced by those authored records.

## Known limitations and exclusions

- No whole-curriculum, whole-topic, grade-order, or learner-readiness completion is claimed.
- The natural-number and integer candidates are represented only at the treatment scopes named
  above; examples are not proofs of generic laws.
- No generic semiring, ring, or replacement operation API is introduced by this release.
- Project 5 web publishing, browser-side kernel execution, and manually duplicated Lean snippets are
  outside this release.
- Generated traceability views and local quality reports are derived evidence, not versioned semantic
  source.
- A checkout other than the peeled tagged commit, or evidence from another SHA, is not this release.

Any change to source, dependencies, toolchain, authored traceability, public API, curriculum scope,
or this manifest requires a successor release identity and requalification of every affected gate.
