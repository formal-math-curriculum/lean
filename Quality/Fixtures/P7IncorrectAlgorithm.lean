/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

namespace FormalMathQuality.Fixtures.P7IncorrectAlgorithm

example :
    FormalMath.Algorithms.IsCorrectFor (fun _ : Unit => false)
      (fun _ output => output = true) := by
  intro input
  rfl

end FormalMathQuality.Fixtures.P7IncorrectAlgorithm
