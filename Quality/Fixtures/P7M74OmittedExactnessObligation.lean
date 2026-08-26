/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-! Compiles, then must fail the M7.4 production policy for an omitted exactness obligation. -/

namespace FormalMath.Algebra

public theorem identity_exact_zero : True := by
  trivial

end FormalMath.Algebra
