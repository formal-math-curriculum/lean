/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import all FormalMath.Algebra.ZeroProduct
public import FormalMath.Algebra.ZeroProduct

/-!
# Factored-integer-equation examples

Concrete specialization of the M2.10 integer factored-equation theorem. This example is another
formal representation of the existing bounded curriculum treatment, not a new curriculum identity.
-/

namespace FormalMath.Algebra.Examples

/-- The factored integer equation `(x - 2) * (x - 5) = 0` has exactly the roots `2` and `5`. -/
public theorem two_five_factored_equation (x : ℤ) :
    FormalMath.Algebra.factoredProduct 2 5 x = 0 ↔ x = 2 ∨ x = 5 := by
  simpa using FormalMath.Algebra.factoredProduct_eq_zero_iff 2 5 x

end FormalMath.Algebra.Examples
