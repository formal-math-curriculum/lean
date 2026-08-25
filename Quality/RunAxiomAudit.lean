/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath
import Quality.AxiomAudit

run_cmd
  FormalMathQuality.AxiomAudit.auditModulePrefix `FormalMath
    (requiredDeclarations := #[
      `FormalMath.Algebra.factoredProduct,
      `FormalMath.Algebra.factoredProduct_eq_zero_iff,
      `FormalMath.Algebra.Examples.two_five_factored_equation,
      `FormalMath.Arithmetic.Examples.cancel_common_nine_addend,
      `FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four,
      `FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three,
      `FormalMath.Arithmetic.Examples.seven_sub_neg_three,
      `FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong,
      `FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution,
      `FormalMath.Geometry.IsInvariantUnder,
      `FormalMath.Geometry.isInvariantUnder_id,
      `FormalMath.Measurement.rectangleArea,
      `FormalMath.Measurement.rectangleArea_comm,
      `FormalMath.Measurement.rectanglePerimeter,
      `FormalMath.Measurement.rectanglePerimeter_comm,
      `FormalMath.Measurement.rectangularPrismVolume,
      `FormalMath.Measurement.rectangularPrismVolume_swap_length_width,
      `FormalMath.Relations.graphOf,
      `FormalMath.Relations.mem_graphOf_comp_iff,
      `FormalMath.Relations.mem_graphOf_iff
    ])
