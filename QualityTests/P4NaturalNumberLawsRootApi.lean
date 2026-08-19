/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-4 natural-number-law root API contract

Compile-time downstream contract for the two bounded natural-number operation-law examples exposed
by the supported `FormalMath` umbrella. Reachability does not establish whole-topic curriculum
coverage or convert library/proof dependencies into learner prerequisites.
-/

namespace QualityTests.P4NaturalNumberLawsRootApi

/-- The root exposes the concrete distributivity example. -/
example : 7 * (4 + 3) = 7 * 4 + 7 * 3 :=
  FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three

/-- The root exposes the concrete additive-cancellation example. -/
example {x y : Nat} (h : 9 + x = 9 + y) : x = y :=
  FormalMath.Arithmetic.Examples.cancel_common_nine_addend h

end QualityTests.P4NaturalNumberLawsRootApi
