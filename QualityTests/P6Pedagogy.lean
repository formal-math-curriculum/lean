/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-6 pedagogical artifact contracts

Exact downstream contracts for the frozen five-declaration M6.6 wave. These checks distinguish
specific examples, a diagnostic, and an exercise solution from generic theorem or whole-row claims.
-/

namespace QualityTests.P6Pedagogy

example :
    ((3, 8) : Nat × Nat) ∈
      FormalMath.Relations.graphOf ((fun n : Nat => 2 * n) ∘ fun n : Nat => n + 1) :=
  FormalMath.Relations.Examples.successor_then_double_graph_contains_three_eight

example :
    FormalMath.Geometry.IsInvariantUnder id (Set.univ : Set Bool) :=
  FormalMath.Geometry.Examples.bool_univ_invariant_under_id

example :
    FormalMath.Measurement.rectanglePerimeter 3 4 = 14 ∧
      FormalMath.Measurement.rectangleArea 3 4 = 12 :=
  FormalMath.Measurement.Examples.rectangle_three_four_values

example :
    FormalMath.Measurement.rectanglePerimeter 3 4 ≠
      FormalMath.Measurement.rectangleArea 3 4 :=
  FormalMath.Measurement.Examples.rectangle_three_four_perimeter_ne_area

example :
    FormalMath.Measurement.rectangularPrismVolume 2 3 4 = 24 :=
  FormalMath.Measurement.Exercises.rectangularPrism_two_three_four_solution

end QualityTests.P6Pedagogy
