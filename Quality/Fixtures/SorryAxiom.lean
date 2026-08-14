/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Quality.AxiomAudit

namespace FormalMathQuality.Fixtures.SorryAxiom

theorem unfinishedBase : True := by
  sorry

theorem transitivelyUnfinished : True :=
  unfinishedBase

end FormalMathQuality.Fixtures.SorryAxiom

#formal_math_axiom_audit Quality.Fixtures.SorryAxiom
