/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Algebra.Ring.Int.Defs

/-!
# Integer sign-law examples

Concrete uses of subtracting a negative integer and multiplying two negative integers for the
bounded `P4-TREAT-CAND9-INT-SIGN-LAWS-v1` treatment. The canonical laws remain the upstream `Int`
declarations; these examples do not introduce replacement operations, wrapper theorems, a generic
ring curriculum claim, or full CAND-P1-000009 coverage.

The curriculum-facing sign rules are supported by OpenStax, *Prealgebra 2e*, §§3.3–3.4. This module
paraphrases that support and reuses the exact pinned Lean/mathlib declarations; it reproduces no
source prose or exercises.
-/

namespace FormalMath.Arithmetic.Examples

/-- Subtracting negative three from seven is addition of three. -/
public theorem seven_sub_neg_three : (7 : ℤ) - (-3) = 10 := by
  calc
    (7 : ℤ) - (-3) = 7 + 3 := Int.sub_neg 7 3
    _ = 10 := rfl

/-- The product of negative seven and negative four is positive twenty-eight. -/
public theorem neg_seven_mul_neg_four : (-7 : ℤ) * (-4) = 28 := by
  calc
    (-7 : ℤ) * (-4) = 7 * 4 := Int.neg_mul_neg 7 4
    _ = 28 := rfl

end FormalMath.Arithmetic.Examples
