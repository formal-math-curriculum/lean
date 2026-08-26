/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Mathlib.Algebra.Exact.Basic

/-! Compiles, then must fail the M7.4 production source policy for an extra theorem. -/

namespace FormalMath.Algebra

@[simp]
public theorem identity_exact_zero {M P : Type*} [Zero P] :
    Function.Exact (fun x : M => x) (fun _ : M => (0 : P)) := by
  intro y
  constructor
  · intro _
    exact ⟨y, rfl⟩
  · intro _
    rfl

public theorem unplannedM74Theorem : True := by
  trivial

end FormalMath.Algebra
