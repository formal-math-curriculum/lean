/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Imported safe axiom-audit fixture

Provides a declaration in a separate module so the audit regression cannot pass by inspecting only
declarations local to its driver.
-/

namespace FormalMathQuality.Fixtures.ImportedSafe

public theorem importedTruth : True :=
  trivial

end FormalMathQuality.Fixtures.ImportedSafe
