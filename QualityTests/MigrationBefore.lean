/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Mathlib.Data.Nat.Basic

/-!
# Maintenance migration fixture — before move

Synthetic non-curricular declaration used only to exercise M2.9 locator migration semantics.
-/

namespace QualityTests.MigrationBefore

public theorem stableIdentityContract (n : Nat) : n = n := rfl

end QualityTests.MigrationBefore
