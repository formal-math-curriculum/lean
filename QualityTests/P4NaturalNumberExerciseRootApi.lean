/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath

/-!
# Project-4 natural-number exercise root API contract

Compile-time downstream contract for the bounded CAND4 exercise solution and diagnostic exposed by
the supported `FormalMath` umbrella. Reachability does not establish full CAND4 coverage, a new
learner-readiness relation, or a generic algebra exercise API.
-/

namespace QualityTests.P4NaturalNumberExerciseRootApi

/-- The root exposes the cancellation checkpoint of the guided solution. -/
example {n : Nat} (h : 9 + 7 * (4 + 3) = 9 + n) : 7 * (4 + 3) = n :=
  (FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution h).1

/-- The root exposes the distributed-form checkpoint of the guided solution. -/
example {n : Nat} (h : 9 + 7 * (4 + 3) = 9 + n) : 7 * 4 + 7 * 3 = n :=
  (FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution h).2.1

/-- The root exposes the final-answer checkpoint of the guided solution. -/
example {n : Nat} (h : 9 + 7 * (4 + 3) = 9 + n) : n = 49 :=
  (FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution h).2.2

/-- The root exposes the diagnostic counterexample. -/
example : 7 * (4 + 3) ≠ 7 * 4 + 3 :=
  FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong

end QualityTests.P4NaturalNumberExerciseRootApi
