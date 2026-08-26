/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-7 core API contract

Compile-time downstream contracts for the one definition admitted by the frozen M7.3 minimal API.
These checks prove root reachability, exact definitional shape, and one positive semantic use only.
They do not claim an algorithm-result family, complexity model, or whole-row coverage.
-/

namespace QualityTests.P7CoreApi

example {Input Output : Type*} (algorithm : Input → Output)
    (specification : Input → Output → Prop) :
    FormalMath.Algorithms.IsCorrectFor algorithm specification ↔
      ∀ input, specification input (algorithm input) :=
  Iff.rfl

example :
    FormalMath.Algorithms.IsCorrectFor (fun value : Bool => value)
      (fun input output => output = input) := by
  intro input
  rfl

end QualityTests.P7CoreApi
