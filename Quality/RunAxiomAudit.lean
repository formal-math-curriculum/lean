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
      `FormalMath.Algebra.Examples.two_five_factored_equation
    ])
