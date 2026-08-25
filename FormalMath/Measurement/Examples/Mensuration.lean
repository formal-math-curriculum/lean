/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Measurement.MensurationResults

/-!
# Mensuration worked example and diagnostic

One M6.6 worked rectangle computation and one concrete diagnostic for CAND-P1-000027. The diagnostic
separates perimeter from area in this case only; it does not characterize every equality case or
supply unit semantics.
-/

namespace FormalMath.Measurement.Examples

/-- A rectangle with displayed side lengths three and four has perimeter fourteen and area twelve. -/
public theorem rectangle_three_four_values :
    FormalMath.Measurement.rectanglePerimeter 3 4 = 14 ∧
      FormalMath.Measurement.rectangleArea 3 4 = 12 := by
  constructor
  · change (2 : ℝ) * ((3 : ℝ) + (4 : ℝ)) = (14 : ℝ)
    rw [← Nat.cast_add, ← Nat.cast_mul]
  · change (3 : ℝ) * (4 : ℝ) = (12 : ℝ)
    rw [← Nat.cast_mul]

/-- The concrete 3-by-4 rectangle witnesses that perimeter and area are not interchangeable. -/
public theorem rectangle_three_four_perimeter_ne_area :
    FormalMath.Measurement.rectanglePerimeter 3 4 ≠
      FormalMath.Measurement.rectangleArea 3 4 := by
  rw [rectangle_three_four_values.1, rectangle_three_four_values.2]
  intro h
  exact (by decide : (14 : ℕ) ≠ 12) (Nat.cast_inj.mp h)

end FormalMath.Measurement.Examples
