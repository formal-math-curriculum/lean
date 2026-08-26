/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

/-!
# Algorithm correctness

A minimal contract saying that a total algorithm satisfies an explicit input/output specification.
It supports one bounded treatment for CAND-P1-000090 without choosing a model of execution,
complexity, partiality, randomness, state, termination, or whole-topic coverage.
-/

namespace FormalMath.Algorithms

/-- A total algorithm is correct when its output satisfies the specification for every input. -/
@[expose]
public def IsCorrectFor {Input Output : Type*}
    (algorithm : Input → Output) (specification : Input → Output → Prop) : Prop :=
  ∀ input, specification input (algorithm input)

end FormalMath.Algorithms
