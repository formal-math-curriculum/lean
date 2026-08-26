/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Project-7 unsupported public-surface fixture

This file must compile, then fail the P7 API policy because it adds a public declaration kind
outside the authorized surface.
-/

namespace FormalMathQuality.Fixtures.P7UnsupportedPublicOpaque

universe u v

/-- The allowed surface copied into this isolated source-policy fixture. -/
@[expose]
public def IsCorrectFor {Input : Type u} {Output : Type v}
    (algorithm : Input → Output) (specification : Input → Output → Prop) : Prop :=
  ∀ input, specification input (algorithm input)

/-- An unauthorized public opaque declaration. -/
public opaque unplannedOpaque : Prop := True

end FormalMathQuality.Fixtures.P7UnsupportedPublicOpaque
