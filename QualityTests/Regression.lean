/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath.Basic

/-!
# Bootstrap behavioral regression

Positive test-only assertions that the supported `FormalMath.Basic` import surface remains usable in
the governed environment. These examples are testing infrastructure, not curriculum content and not
claims of formalization coverage.
-/

namespace FormalMathQualityTests.Regression

example : (2 : Nat) + 2 = 4 := by decide

example (n : Nat) : n + 0 = n := by simp

end FormalMathQualityTests.Regression
