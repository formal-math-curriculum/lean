/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-6 dependency-adjacent function contract

Downstream type contract for exactly the one M6.5 result. This proves public reachability and the
frozen statement shape without claiming examples, exercises, generic composition theory, graph
taxonomy, or whole-row coverage.
-/

namespace QualityTests.P6AdjacentFunctions

example {α β γ : Type*} {g : β → γ} {f : α → β} {point : α × γ} :
    point ∈ FormalMath.Relations.graphOf (g ∘ f) ↔ point.2 = g (f point.1) :=
  FormalMath.Relations.mem_graphOf_comp_iff

end QualityTests.P6AdjacentFunctions
