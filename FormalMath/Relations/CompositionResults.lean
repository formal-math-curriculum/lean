/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Relations.GraphResults

/-!
# Bounded function-composition graph result

The single dependency-adjacent result admitted by the M6.5 freeze for CAND-P1-000018. It connects
the adopted `graphOf` API to ordinary function composition without introducing a new function,
relation, graph representation, notation, or whole-row coverage claim.
-/

namespace FormalMath.Relations

/-- Membership in the graph of a composite function reduces to nested evaluation. -/
@[simp]
public theorem mem_graphOf_comp_iff
    {α β γ : Type*} {g : β → γ} {f : α → β} {point : α × γ} :
    point ∈ graphOf (g ∘ f) ↔ point.2 = g (f point.1) :=
  Iff.rfl

end FormalMath.Relations
