/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import QualityTests.Computability

/-!
# Intended-executable computability negative control

This fixture deliberately attempts to evaluate a declaration whose specification uses classical
choice. It must fail at the execution boundary; the corresponding noncomputable specification is
allowed to exist and compile in `QualityTests.Computability`.
-/

open FormalMathQualityTests.Computability

#eval specificationChoice (show Nonempty Nat from ⟨7⟩)
