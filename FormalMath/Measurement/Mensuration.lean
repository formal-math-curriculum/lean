/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Mathlib.Data.Real.Basic

/-!
# Elementary mensuration definitions

Three formula definitions for the bounded CAND-P1-000027 rectangle and rectangular-prism surface.
They intentionally impose no positivity or unit convention at the definition layer. Hypotheses,
dimensional interpretation, formula results, examples, and exercises belong to later governed
milestones and must not be inferred from these names alone.
-/

namespace FormalMath.Measurement

/-- Perimeter expression for a rectangle with displayed length and width. -/
@[expose]
public def rectanglePerimeter (length width : ℝ) : ℝ :=
  2 * (length + width)

/-- Area expression for a rectangle with displayed length and width. -/
@[expose]
public def rectangleArea (length width : ℝ) : ℝ :=
  length * width

/-- Volume expression for a rectangular prism with displayed length, width, and height. -/
@[expose]
public def rectangularPrismVolume (length width height : ℝ) : ℝ :=
  length * width * height

end FormalMath.Measurement
