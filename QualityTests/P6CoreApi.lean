/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-6 core API contract

Compile-time downstream contracts for the five definitions admitted by the frozen M6.3 minimal API.
These checks prove reachability and exact definitional shape only. They do not claim theorem,
example, exercise, editorial, or whole-row coverage.
-/

namespace QualityTests.P6CoreApi

example {α β : Type*} (f : α → β) :
    FormalMath.Relations.graphOf f = { point | point.2 = f point.1 } :=
  rfl

example {α : Type*} (transform : α → α) (figure : Set α) :
    FormalMath.Geometry.IsInvariantUnder transform figure ↔ Set.image transform figure = figure :=
  Iff.rfl

example (length width : ℝ) :
    FormalMath.Measurement.rectanglePerimeter length width = 2 * (length + width) :=
  rfl

example (length width : ℝ) :
    FormalMath.Measurement.rectangleArea length width = length * width :=
  rfl

example (length width height : ℝ) :
    FormalMath.Measurement.rectangularPrismVolume length width height = length * width * height :=
  rfl

end QualityTests.P6CoreApi
