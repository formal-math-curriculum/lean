/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Init.Data.Nat.Basic

/-!
# Natural-number operation-law examples

Concrete uses of distributivity and additive cancellation for the first bounded Project-4
arithmetic-to-algebra treatment. The canonical laws remain the upstream `Nat` declarations; these
examples do not introduce replacement operations, a wrapper hierarchy, or a generic semiring
curriculum claim.

The curriculum-facing law schemas and arithmetic-to-algebra role are sourced in OpenStax,
*Prealgebra 2e*, §§7.2–7.4, with equality-transformation context in §2.3. Those sections use a wider
instructional number domain; this module's natural-number specialization is justified separately by
the exact `Nat` declarations it reuses. Source prose and exercises are not reproduced here.
-/

namespace FormalMath.Arithmetic.Examples

/-- A concrete use of left distributivity over natural-number addition. -/
public theorem seven_distributes_over_four_plus_three : 7 * (4 + 3) = 7 * 4 + 7 * 3 :=
  Nat.left_distrib 7 4 3

/-- Equal natural-number sums remain equal after cancelling a common left addend. -/
public theorem cancel_common_nine_addend {x y : Nat} (h : 9 + x = 9 + y) : x = y :=
  Nat.add_left_cancel h

end FormalMath.Arithmetic.Examples
