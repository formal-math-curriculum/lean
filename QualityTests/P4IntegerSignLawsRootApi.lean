/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-4 integer-sign-law root API contract

Compile-time downstream contract for the two bounded integer sign-law examples exposed by the
supported `FormalMath` umbrella. Reachability does not establish whole-topic curriculum coverage or
convert library/proof dependencies into learner prerequisites.
-/

namespace QualityTests.P4IntegerSignLawsRootApi

-- The root exposes both declarations at their exact governed theorem types without re-exporting
-- their upstream structure instances.
example :
    Int.sub (Int.ofNat 7) (Int.neg (Int.ofNat 3)) = Int.ofNat 10 :=
  FormalMath.Arithmetic.Examples.seven_sub_neg_three

example :
    Int.mul (Int.neg (Int.ofNat 7)) (Int.neg (Int.ofNat 4)) = Int.ofNat 28 :=
  FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four

end QualityTests.P4IntegerSignLawsRootApi
