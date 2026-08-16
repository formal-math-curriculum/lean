/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Data.Int.Order.Basic

/-!
# Factored integer expressions

A small project-owned construction for the bounded M2.10 elementary-equations vertical slice.
This module names the factored expression used by the curriculum treatment; it does not introduce
a replacement integer, equation structure, or learner-prerequisite claim.
-/

namespace FormalMath.Algebra

/-- The integer expression `(x - a) * (x - b)` used by the M2.10 factored-equation slice. -/
def factoredProduct (a b x : ℤ) : ℤ :=
  (x - a) * (x - b)

end FormalMath.Algebra
