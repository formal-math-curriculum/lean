/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Project-7 attribute-prefixed public-surface fixture

This file must compile, then fail the P7 API policy because it adds a public theorem on an
attribute-prefixed command line.
-/

namespace FormalMathQuality.Fixtures.P7AttributePrefixedPublicTheorem

universe u v

/-- The allowed surface copied into this isolated source-policy fixture. -/
@[expose]
public def IsCorrectFor {Input : Type u} {Output : Type v}
    (algorithm : Input → Output) (specification : Input → Output → Prop) : Prop :=
  ∀ input, specification input (algorithm input)

/-- An unauthorized attribute-prefixed public theorem. -/
@[simp] public theorem unplannedAttributePrefixed : True := by
  trivial

end FormalMathQuality.Fixtures.P7AttributePrefixedPublicTheorem
