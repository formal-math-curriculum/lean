/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Measurement.MensurationResults

/-!
# Mensuration exercise solution

One deliberately bounded M6.6 solution theorem for CAND-P1-000027. It proves only the displayed
2-by-3-by-4 rectangular-prism computation and does not introduce units or positivity assumptions.
-/

namespace FormalMath.Measurement.Exercises

/-- Solution theorem for the concrete rectangular-prism volume exercise 2 · 3 · 4. -/
public theorem rectangularPrism_two_three_four_solution :
    FormalMath.Measurement.rectangularPrismVolume 2 3 4 = 24 := by
  change ((2 : ℝ) * (3 : ℝ)) * (4 : ℝ) = (24 : ℝ)
  rw [← Nat.cast_mul, ← Nat.cast_mul]

end FormalMath.Measurement.Exercises
