/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Geometry.Symmetry

/-!
# Bounded invariance results

The identity-transformation result admitted by the M6.4 theorem-wave freeze for CAND-P1-000024.
It does not introduce group actions, classify symmetries, or claim whole-row coverage.
-/

namespace FormalMath.Geometry

/-- Every set is invariant under the identity transformation. -/
@[simp]
public theorem isInvariantUnder_id {α : Type*} (figure : Set α) :
    IsInvariantUnder id figure := by
  simp [IsInvariantUnder]

end FormalMath.Geometry
