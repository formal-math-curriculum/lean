/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Data.Int.Order.Basic

/-!
# M2.10 external dependency locator contract

Compile-time evidence that the exact public mathlib declaration selected by the M2.10 reuse record
is available from its directly governed module. This is dependency evidence only: it does not create
a project FART, curriculum identity, readiness relation, or prerequisite claim.
-/

namespace QualityTests.M210ExternalLocator

/-- The selected external zero-product surface eliminates an integer product equal to zero. -/
example (a b : ℤ) (h : a * b = 0) : a = 0 ∨ b = 0 :=
  Int.eq_zero_or_eq_zero_of_mul_eq_zero h

end QualityTests.M210ExternalLocator
