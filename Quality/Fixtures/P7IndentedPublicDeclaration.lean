/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Project-7 indented public-surface fixture

This file must compile, then fail the P7 API policy because it adds an indented public
declaration.
-/

namespace FormalMathQuality.Fixtures.P7IndentedPublicDeclaration

universe u v

/-- The allowed surface copied into this isolated source-policy fixture. -/
@[expose]
public def IsCorrectFor {Input : Type u} {Output : Type v}
    (algorithm : Input → Output) (specification : Input → Output → Prop) : Prop :=
  ∀ input, specification input (algorithm input)

/-- An unauthorized indented public definition. -/
  public def unplannedIndented : Nat := 0

end FormalMathQuality.Fixtures.P7IndentedPublicDeclaration
