/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Relations.CompositionResults

/-!
# Composite-function graph example

One concrete M6.6 example for CAND-P1-000018 and CAND-P1-000019. It demonstrates one evaluation and
membership fact only; it does not claim generic function-family, plotting, or whole-row coverage.
-/

namespace FormalMath.Relations.Examples

/-- Successor followed by doubling sends three to eight, so the pair belongs to its graph. -/
public theorem successor_then_double_graph_contains_three_eight :
    ((3, 8) : Nat × Nat) ∈
      FormalMath.Relations.graphOf ((fun n : Nat => 2 * n) ∘ fun n : Nat => n + 1) := by
  rfl

end FormalMath.Relations.Examples
