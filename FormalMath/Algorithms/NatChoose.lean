/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Algorithms.Correctness
public import Mathlib.Data.Nat.Choose.Basic

/-!
# Correctness of the Pascal-recursive binomial algorithm

This module gives the single bounded M7.4 consumer of `IsCorrectFor`: `Nat.choose` satisfies its
three defining Pascal-recursion equations. It does not model traces, complexity, partiality,
randomness, optimality, or termination and does not claim whole combinatorics coverage.
-/

namespace FormalMath.Algorithms

/-- `Nat.choose` satisfies the three equations of its total recursive specification. -/
public theorem natChoose_isCorrectFor :
    IsCorrectFor
      (fun input : Nat × Nat => Nat.choose input.1 input.2)
      (fun input output =>
        match input with
        | (_n, 0) => output = 1
        | (0, _k + 1) => output = 0
        | (n + 1, k + 1) => output = Nat.choose n k + Nat.choose n (k + 1)) := by
  rintro ⟨n, k⟩
  cases n <;> cases k <;> rfl

end FormalMath.Algorithms
