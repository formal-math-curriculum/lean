/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Quality.AxiomAudit

namespace FormalMathQuality.Fixtures.CustomAxiom

axiom fixtureCustomAxiom : True

theorem usesFixtureCustomAxiom : True :=
  fixtureCustomAxiom

end FormalMathQuality.Fixtures.CustomAxiom

#formal_math_axiom_audit Quality.Fixtures.CustomAxiom
