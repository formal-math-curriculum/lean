/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Data.Nat.Basic

/-!
Lean declarations used only by M2.8 traceability query/round-trip controls.

These declarations are test fixtures, not Curriculum-v1 formalizations and not production FARTs.
-/

namespace QualityTests.TraceabilityFixture

public theorem fixtureTheorem (n : Nat) : n + 0 = n := by
  simp

public theorem fixtureExample : 2 + 3 = 5 := by
  decide

public def fixtureModel (n : Nat) : Nat := n + 1

end QualityTests.TraceabilityFixture
