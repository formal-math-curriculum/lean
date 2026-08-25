/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Relations.Graph

/-!
# Bounded function-graph results

The exact membership characterization admitted by the M6.4 theorem-wave freeze for
CAND-P1-000019. It does not claim plotting, intercept, slope, analytic-geometry, or whole-row
coverage.
-/

namespace FormalMath.Relations

/-- Membership in `graphOf f` is exactly the coordinate equation defining the graph. -/
@[simp]
public theorem mem_graphOf_iff {α β : Type*} {f : α → β} {point : α × β} :
    point ∈ graphOf f ↔ point.2 = f point.1 :=
  Iff.rfl

end FormalMath.Relations
