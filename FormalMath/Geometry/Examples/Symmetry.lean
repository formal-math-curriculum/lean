/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Geometry.SymmetryResults

/-!
# Concrete invariance example

One M6.6 specialization for CAND-P1-000024. It demonstrates identity invariance on a concrete type
and set; it does not classify transformations or symmetries.
-/

namespace FormalMath.Geometry.Examples

/-- The universal set of booleans is invariant under the identity transformation. -/
public theorem bool_univ_invariant_under_id :
    FormalMath.Geometry.IsInvariantUnder id (Set.univ : Set Bool) :=
  FormalMath.Geometry.isInvariantUnder_id Set.univ

end FormalMath.Geometry.Examples
