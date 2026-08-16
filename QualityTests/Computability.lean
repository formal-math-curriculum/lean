/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath.Basic

/-!
# Computability contract controls

Test-only examples separating mathematical specification from executable API requirements.
A mathematically legitimate `noncomputable` specification is allowed to compile; an API that is
explicitly exercised as executable is tested separately by a deliberate failing fixture.
-/

namespace FormalMathQualityTests.Computability

/-- Representative executable API used by the positive runtime contract. -/
def executableDouble (n : Nat) : Nat := n + n

#guard executableDouble 21 == 42

/--
Representative mathematical specification that may use classical choice. Its presence is valid as a
specification and is not an assertion that the declaration has executable code. It is public only
inside the non-default `QualityTests` test library so the negative execution fixture can import it.
-/
public noncomputable def specificationChoice {α : Type} (h : Nonempty α) : α :=
  Classical.choice h

example (h : Nonempty Nat) : specificationChoice h = specificationChoice h := rfl

end FormalMathQualityTests.Computability
