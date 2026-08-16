/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Data.Nat.Basic

/-!
# Maintenance migration fixture — after move

Synthetic non-curricular declarations used only to exercise M2.9 locator migration semantics.
-/

namespace QualityTests.MigrationAfter

public theorem stableIdentityContract (n : Nat) : n = n := rfl

public theorem incompatibleCandidate (_n : Nat) : True := trivial

end QualityTests.MigrationAfter
