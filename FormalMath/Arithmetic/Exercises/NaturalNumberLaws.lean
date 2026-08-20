/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath.Arithmetic.Examples.NaturalNumberLaws

/-!
# Natural-number distributive-cancellation exercise

An original guided exercise for the bounded
`P4-TREAT-CAND4-DISTRIBUTE-CANCEL-EXERCISE-v1` treatment of CAND-P1-000004.

## Pedagogical contract

* **Learning objective:** verify cancellation of a common addend, distribution to both addends,
  and the final natural-number value as three explicit correction checkpoints.
* **Learner readiness:** CAND-P1-000003 under the existing scope qualification of
  READY-P1-000001; this module creates no new readiness relation.
* **Statement and domain:** for `n : Nat`, an equality with common left addend nine is the only
  hypothesis. No nonzero, order, finiteness, classical, or other implicit hypothesis is added.
* **Connection:** the solution directly reuses `cancel_common_nine_addend` and
  `seven_distributes_over_four_plus_three` from the preceding CAND4 example surface.
* **Function and difficulty:** one guided composition of two established properties, followed by
  closed arithmetic evaluation. The final equality alone is not presented as forcing one method;
  the conjunction below is the formal correction criterion for the three requested checkpoints.
* **Diagnostic:** `distribute_first_addend_only_is_wrong` rejects the specific error of multiplying
  only the first addend. One counterexample does not prove the general distributive law.
* **Verification:** Lean's kernel checks both declarations; the production axiom audit governs the
  permitted trust surface.

The distributive-law and equality-transformation roles are supported by OpenStax, *Prealgebra 2e*,
§§7.3 and 2.3. This module paraphrases that support and contains an original project exercise; it
reproduces no source prose, image, table, or exercise.
-/

namespace FormalMath.Arithmetic.Exercises

/--
Given the common-addend equality, certify cancellation, full distribution, and the final answer.
-/
public theorem distribute_then_cancel_solution {n : Nat}
    (h : 9 + 7 * (4 + 3) = 9 + n) :
    7 * (4 + 3) = n ∧ 7 * 4 + 7 * 3 = n ∧ n = 49 := by
  have hcancel : 7 * (4 + 3) = n :=
    FormalMath.Arithmetic.Examples.cancel_common_nine_addend h
  have hdistributed : 7 * 4 + 7 * 3 = n := by
    calc
      7 * 4 + 7 * 3 = 7 * (4 + 3) :=
        FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three.symm
      _ = n := hcancel
  have hanswer : n = 49 := by
    calc
      n = 7 * (4 + 3) := hcancel.symm
      _ = 7 * 4 + 7 * 3 :=
        FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three
      _ = 49 := rfl
  exact ⟨hcancel, hdistributed, hanswer⟩

/-- Multiplying only the first addend does not give the value of `7 * (4 + 3)`. -/
public theorem distribute_first_addend_only_is_wrong :
    7 * (4 + 3) ≠ 7 * 4 + 3 := by
  decide

end FormalMath.Arithmetic.Exercises
