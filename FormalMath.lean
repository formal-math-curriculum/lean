/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Algebra.Examples.FactoredIntegerEquation
public import FormalMath.Arithmetic.Examples.IntegerSignLaws
public import FormalMath.Arithmetic.Examples.NaturalNumberLaws
public import FormalMath.Basic

/-!
# FormalMath

Root import surface for the Formal Mathematics Curriculum Lean library.

This file is an umbrella for downstream convenience. Production `FormalMath.*` modules must import
their semantic dependencies directly rather than importing this root umbrella. The current public
surface includes the bounded M2.10 factored-integer-equation slice, bounded Project-4 natural-number
operation-law and integer sign-law examples, and supporting infrastructure. It does not claim
curriculum coverage or formalization completeness.
-/
