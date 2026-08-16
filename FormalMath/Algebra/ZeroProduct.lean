/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Algebra.FactoredEquation

/-!
# Zero-product solution characterization

Formalizes the bounded integer factored-equation treatment selected for M2.10. The proof dependency
on integer zero-product reasoning is an implementation dependency only; it does not alter Project-1
learner-readiness or curriculum-prerequisite authority.
-/

namespace FormalMath.Algebra

/-- An integer factored product is zero exactly at either of its two displayed roots. -/
public theorem factoredProduct_eq_zero_iff (a b x : ℤ) :
    factoredProduct a b x = 0 ↔ x = a ∨ x = b := by
  constructor
  · intro h
    have hmul : (x - a) * (x - b) = 0 := by
      simpa [factoredProduct] using h
    rcases Int.eq_zero_or_eq_zero_of_mul_eq_zero hmul with ha | hb
    · exact Or.inl (sub_eq_zero.mp ha)
    · exact Or.inr (sub_eq_zero.mp hb)
  · intro h
    rcases h with rfl | rfl <;> simp [factoredProduct]

end FormalMath.Algebra
