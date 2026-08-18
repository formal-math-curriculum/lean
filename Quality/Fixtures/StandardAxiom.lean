/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Quality.AxiomAudit

namespace FormalMathQuality.Fixtures.StandardAxiom

theorem proposition_extensionality (p q : Prop) (h : p ↔ q) : p = q :=
  propext h

end FormalMathQuality.Fixtures.StandardAxiom

#formal_math_axiom_audit Quality.Fixtures.StandardAxiom
