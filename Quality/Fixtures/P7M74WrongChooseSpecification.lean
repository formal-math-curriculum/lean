/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Algorithms.Correctness
public import Mathlib.Data.Nat.Choose.Basic

/-! Compiles, then must fail the M7.4 production policy for specification drift. -/

namespace FormalMath.Algorithms

public theorem natChoose_isCorrectFor :
    IsCorrectFor
      (fun input : Nat × Nat => Nat.choose input.1 input.2)
      (fun _ _ => True) := by
  intro _
  trivial

end FormalMath.Algorithms
