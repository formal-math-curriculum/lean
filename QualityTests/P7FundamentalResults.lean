/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-7 fundamental-results contracts

Exact consumers for the two local M7.4 theorems and four pinned direct-dependency results.
-/

namespace QualityTests.P7FundamentalResults

example {M P : Type*} [Zero P] :
    Function.Exact (fun x : M => x) (fun _ : M => (0 : P)) :=
  FormalMath.Algebra.identity_exact_zero

example :
    FormalMath.Algorithms.IsCorrectFor
      (fun input : Nat × Nat => Nat.choose input.1 input.2)
      (fun input output =>
        match input with
        | (_n, 0) => output = 1
        | (0, _k + 1) => output = 0
        | (n + 1, k + 1) => output = Nat.choose n k + Nat.choose n (k + 1)) :=
  FormalMath.Algorithms.natChoose_isCorrectFor

example {G : Type*} [Semigroup G] (a b c : G) : a * b * c = a * (b * c) :=
  mul_assoc a b c

example (K : Type*) [Field K] [Fintype K] (p : Nat) [CharP K p] :
    ∃ n : ℕ+, Nat.Prime p ∧ Fintype.card K = p ^ (n : Nat) :=
  FiniteField.card K p

example {V : Type*} {G : SimpleGraph V} (h : G.IsTree) : G.Connected :=
  h.connected

#check AkraBazziRecurrence.isTheta_asympBound

end QualityTests.P7FundamentalResults
