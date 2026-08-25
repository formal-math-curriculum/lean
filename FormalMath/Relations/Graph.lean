/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Mathlib.Data.Set.Defs

/-!
# Function graphs

A minimal project-owned name for the graph of a function as a set of ordered pairs. It supports the
bounded coordinate-representation treatment for CAND-P1-000019 without replacing mathlib functions,
sets, products, or coordinate geometry, and without asserting whole-topic coverage.
-/

namespace FormalMath.Relations

/-- The set of ordered pairs whose second coordinate is the value of `f` at the first. -/
public def graphOf {α β : Type*} (f : α → β) : Set (α × β) :=
  { point | point.2 = f point.1 }

end FormalMath.Relations
