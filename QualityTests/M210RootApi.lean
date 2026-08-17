/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# M2.10 root API contract

Compile-time downstream contract for the three bounded M2.10 production declarations exposed by
the supported `FormalMath` umbrella. This verifies API reachability only and does not claim broader
curriculum coverage.
-/

namespace QualityTests.M210RootApi

/-- The root exposes the construction. -/
example (a b x : Int) : Int :=
  FormalMath.Algebra.factoredProduct a b x

/-- The root exposes the general bounded theorem. -/
example (a b x : Int) :
    FormalMath.Algebra.factoredProduct a b x = 0 ↔ x = a ∨ x = b :=
  FormalMath.Algebra.factoredProduct_eq_zero_iff a b x

/-- The root exposes the concrete example. -/
example (x : Int) : FormalMath.Algebra.factoredProduct 2 5 x = 0 ↔ x = 2 ∨ x = 5 :=
  FormalMath.Algebra.Examples.two_five_factored_equation x

end QualityTests.M210RootApi
