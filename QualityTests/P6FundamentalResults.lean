/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-6 bounded fundamental-result contracts

Downstream type contracts for exactly the five M6.4 results. These checks prove public reachability
and exact statement shape without claiming pedagogical, adjacent-row, publication, or whole-row
coverage.
-/

namespace QualityTests.P6FundamentalResults

example {α β : Type*} {f : α → β} {point : α × β} :
    point ∈ FormalMath.Relations.graphOf f ↔ point.2 = f point.1 :=
  FormalMath.Relations.mem_graphOf_iff

example {α : Type*} (figure : Set α) :
    FormalMath.Geometry.IsInvariantUnder id figure :=
  FormalMath.Geometry.isInvariantUnder_id figure

example (length width : ℝ) :
    FormalMath.Measurement.rectanglePerimeter length width =
      FormalMath.Measurement.rectanglePerimeter width length :=
  FormalMath.Measurement.rectanglePerimeter_comm length width

example (length width : ℝ) :
    FormalMath.Measurement.rectangleArea length width =
      FormalMath.Measurement.rectangleArea width length :=
  FormalMath.Measurement.rectangleArea_comm length width

example (length width height : ℝ) :
    FormalMath.Measurement.rectangularPrismVolume length width height =
      FormalMath.Measurement.rectangularPrismVolume width length height :=
  FormalMath.Measurement.rectangularPrismVolume_swap_length_width length width height

end QualityTests.P6FundamentalResults
