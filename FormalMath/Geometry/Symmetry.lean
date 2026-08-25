/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Mathlib.Data.Set.Defs

/-!
# Elementary set invariance

A bounded predicate for saying that a transformation preserves a figure as a set. It supports the
elementary symmetry treatment for CAND-P1-000024 without introducing a replacement equivalence,
group-action hierarchy, or crystallographic claim.
-/

namespace FormalMath.Geometry

/-- A figure is invariant under a transformation when its image is exactly the original set. -/
@[expose]
public def IsInvariantUnder {α : Type*} (transform : α → α) (figure : Set α) : Prop :=
  Set.image transform figure = figure

end FormalMath.Geometry
