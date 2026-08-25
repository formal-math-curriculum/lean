/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Measurement.Examples.Mensuration

/-!
# Mensuration exercise solution

One original closed-arithmetic M6.6 solution checkpoint for CAND-P1-000027. It is not a full exercise
bank and does not claim that learners must use one calculation method.
-/

namespace FormalMath.Measurement.Exercises

/-- The adopted volume formula evaluates a 2-by-3-by-4 rectangular prism to twenty-four. -/
public theorem rectangularPrism_two_three_four_solution :
    FormalMath.Measurement.rectangularPrismVolume 2 3 4 = 24 := by
  norm_num [FormalMath.Measurement.rectangularPrismVolume]

end FormalMath.Measurement.Exercises
