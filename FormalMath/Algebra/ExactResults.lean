/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Mathlib.Algebra.Exact.Basic

/-!
# One bounded exactness result

The identity map followed by a zero map is exact. This is the single exactness-oriented result
authorized for CAND-P1-000592 by the M7.4 freeze. It does not introduce chain complexes,
homomorphism APIs, module structure, or a general exact-sequence development.
-/

namespace FormalMath.Algebra

/-- The identity map is surjective, so it is exact before a zero map. -/
@[simp]
public theorem identity_exact_zero {M P : Type*} [Zero P] :
    Function.Exact (fun x : M => x) (fun _ : M => (0 : P)) := by
  intro y
  constructor
  · intro _
    exact ⟨y, rfl⟩
  · intro _
    rfl

end FormalMath.Algebra
