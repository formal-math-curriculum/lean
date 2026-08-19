/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Quality.AxiomAudit

namespace FormalMathQuality.Fixtures.TrustCompiler

theorem usesTrustCompiler : True :=
  Lean.trustCompiler

end FormalMathQuality.Fixtures.TrustCompiler

#formal_math_axiom_audit Quality.Fixtures.TrustCompiler
