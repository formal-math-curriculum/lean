/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Measurement.Mensuration

/-!
# Bounded mensuration results

Three argument-symmetry results admitted by the M6.4 theorem-wave freeze for CAND-P1-000027.
They preserve the definition layer's unrestricted real inputs and do not assert positivity, units,
formula derivations, geometric existence, or whole-row coverage.
-/

namespace FormalMath.Measurement

/-- Rectangle perimeter is unchanged when displayed length and width are exchanged. -/
public theorem rectanglePerimeter_comm (length width : ℝ) :
    rectanglePerimeter length width = rectanglePerimeter width length := by
  simp [rectanglePerimeter, add_comm]

/-- Rectangle area is unchanged when displayed length and width are exchanged. -/
public theorem rectangleArea_comm (length width : ℝ) :
    rectangleArea length width = rectangleArea width length := by
  simp [rectangleArea, mul_comm]

/-- Rectangular-prism volume is unchanged when displayed length and width are exchanged. -/
public theorem rectangularPrismVolume_swap_length_width (length width height : ℝ) :
    rectangularPrismVolume length width height =
      rectangularPrismVolume width length height := by
  simp [rectangularPrismVolume, mul_comm]

end FormalMath.Measurement
