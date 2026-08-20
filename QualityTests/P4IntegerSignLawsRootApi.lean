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

-- The root exposes both exact declarations without re-exporting their upstream structure instances.
#check FormalMath.Arithmetic.Examples.seven_sub_neg_three
#check FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four

end QualityTests.P4IntegerSignLawsRootApi
