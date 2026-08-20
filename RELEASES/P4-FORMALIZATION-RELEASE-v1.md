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
- Independent-review remediation commit: [`8a782339c25f8c0cd6058493c204f7098299ed35`](https://github.com/formal-math-curriculum/lean/commit/8a782339c25f8c0cd6058493c204f7098299ed35)
- Annotated tag: [`formalization/p4-v1`](https://github.com/formal-math-curriculum/lean/tree/formalization/p4-v1)
- Durable release record: [P4-M4.8-FIRST-VERIFIED-CURRICULUM-RELEASE-BASELINE-v1](https://linear.app/verified-mathematics/document/p4-m48-first-verified-curriculum-release-baseline-v1-8efde162a712)
- Frozen M4.7 audit ledger: [P4-M4.7-ADVERSARIAL-AUDIT-AND-FINDING-LEDGER-v1](https://linear.app/verified-mathematics/document/p4-m47-adversarial-audit-and-finding-ledger-v1-99e2d6fbb824)

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

The linked curriculum identities retain the Project-1 `CM7` state for the declared bounded scopes.
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
- selected `lake-manifest.json` Git blob: `b45d9c37e5168cf22bdd886bee5073f025cee29a`
- `Quality/environment-baseline.env` Git blob: `c879198ea3f357311b8fafa9ed68361ea44ad61e`

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
lake exe traceability roundtrip
```

The regression dimension includes intended-failure proof/trust controls, source/API controls,
traceability controls, exact root theorem-type contracts, and a TERM-resistant cache-descendant
control that requires both zero surviving descendants and an explicit PASS report. Optional build
caches are acceleration only and are not proof, source, curriculum, or release evidence.

## Qualified remediation evidence

The following evidence belongs to the non-self-referential remediation input commit
[`8a782339c25f8c0cd6058493c204f7098299ed35`](https://github.com/formal-math-curriculum/lean/commit/8a782339c25f8c0cd6058493c204f7098299ed35),
tree `15b73426724eee0141853ede4452854e60c9d3cd`. Adding this manifest evidence creates a
successor head, so the durable release record—not this file—records the exact final PR head, merge,
post-merge workflow, tag object, and rerun report paths. Those final gates may not inherit PASS from
this table.

| Dimension | UTC interval | Result and report | Evidence class |
| --- | --- | --- | --- |
| environment | `2026-08-20T10:10:44Z`–`10:10:57Z` | PASS/0; `.lake/build/quality/env-8a782339c25f8c0cd6058493c204f7098299ed35-UI0RIJlH/result.report` | Reproduced locally |
| build | `2026-08-20T10:10:57Z`–`10:11:09Z` | PASS/0; `.lake/build/quality/build-8a782339c25f8c0cd6058493c204f7098299ed35-yugEMY58/result.report`; 321 jobs | Reproduced locally |
| proof | `2026-08-20T10:11:10Z`–`10:11:26Z` | PASS/0; `.lake/build/quality/proof-8a782339c25f8c0cd6058493c204f7098299ed35-BEKgWlmx/result.report` | Reproduced locally |
| source | `2026-08-20T10:11:26Z`–`10:11:44Z` | PASS/0; `.lake/build/quality/source-8a782339c25f8c0cd6058493c204f7098299ed35-auqFJnY2/result.report`; 35 files, zero failures/advisories | Reproduced locally |
| regression | `2026-08-20T10:11:44Z`–`10:16:54Z` | PASS/0; `.lake/build/quality/regression-8a782339c25f8c0cd6058493c204f7098299ed35-XAYCnm2w/result.report` | Reproduced locally |
| traceability validate + roundtrip | completed by `2026-08-20T10:17:04Z` | PASS; FART 10 / FLOC 11 / FLINK 10 / lock 4 / modules 10 / declarations 14 / links 10 / locator-link checks 11 | Reproduced locally |

The proof audit enumerated 10 project constants, including all nine required public declarations:
four have no axiom dependencies and six use only the permitted standard mathematical axiom
`propext`. Coverage failures, `sorryAx`, `Lean.trustCompiler`, and custom/unclassified axiom failures
were all zero. Regression separately demonstrated that deliberate `sorry`, transitive `sorryAx`,
custom axiom, trust-compiler, vacuous-coverage, and exact CAND9 type-drift fixtures fail with their
intended signatures. The direct TERM-resistant descendant control returned governed status 124 in
six seconds, found no surviving recorded PID, and the full `env` control also wrote PASS/0.

PR integration run [32357588356](https://github.com/formal-math-curriculum/lean/actions/runs/32357588356)
executed synthetic merge
[`7b65d7e3a1f41c6cfe42ff960be3d5b79fecf98f`](https://github.com/formal-math-curriculum/lean/commit/7b65d7e3a1f41c6cfe42ff960be3d5b79fecf98f),
tree `15b73426724eee0141853ede4452854e60c9d3cd`, with ordered parents the frozen base and
`8a782339c25f8c0cd6058493c204f7098299ed35`. Its tree equals the input head tree. This is Observed
remote integration evidence, not local reproduction and not exact-head commit execution evidence.

| Job | Job ID | Artifact ID | Artifact digest |
| --- | --- | --- | --- |
| `quality / build` | `96390023950` | `9402293521` | `sha256:d743564db9f630627bee4b0f6d1b3bb7454c8754cef48bdee5aa21abb2b70af5` |
| `quality / proof` | `96390023443` | `9402310431` | `sha256:c79509d504e9bf10b46a7cb2905f30c4901b29ecd6cea5e8e2c19dec7dae2392` |
| `quality / source` | `96390023690` | `9402382843` | `sha256:3665ba204042d5c043f4f0ca4055538a57b77928bb240e59c9cbdf856f7ca960` |
| `quality / regression` | `96390023718` | `9402438436` | `sha256:c9ce147c93c5c2085b494e0c57272865f41159e62e8cad04c2ea686d73dbc34e` |

All four jobs and artifacts completed successfully. Final release promotion additionally requires a
zero-Blocker/Material successor review, Ready qualification, governed merge, four successful jobs on
the resulting `main` commit, and verified annotated-tag creation. Exact final subjects live in the
durable release record linked above.

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
