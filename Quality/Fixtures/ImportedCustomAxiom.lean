/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Imported custom-axiom fixture

Provides a deliberately unacceptable axiom in a module separate from the audit driver.
-/

namespace FormalMathQuality.Fixtures.ImportedCustomAxiom

public axiom importedFixtureCustomAxiom : True

public theorem usesImportedFixtureCustomAxiom : True :=
  importedFixtureCustomAxiom

end FormalMathQuality.Fixtures.ImportedCustomAxiom
