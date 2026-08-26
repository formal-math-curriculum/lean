/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import FormalMath.Algebra.Examples.FactoredIntegerEquation
public import FormalMath.Algorithms.Correctness
public import FormalMath.Arithmetic.Examples.IntegerSignLaws
public import FormalMath.Arithmetic.Examples.NaturalNumberLaws
public import FormalMath.Arithmetic.Exercises.NaturalNumberLaws
public import FormalMath.Basic
public import FormalMath.Geometry.Symmetry
public import FormalMath.Geometry.SymmetryResults
public import FormalMath.Geometry.Examples.Symmetry
public import FormalMath.Measurement.Mensuration
public import FormalMath.Measurement.MensurationResults
public import FormalMath.Measurement.Examples.Mensuration
public import FormalMath.Measurement.Exercises.Mensuration
public import FormalMath.Relations.Graph
public import FormalMath.Relations.GraphResults
public import FormalMath.Relations.CompositionResults
public import FormalMath.Relations.Examples.Composition

/-!
# FormalMath

Root import surface for the Formal Mathematics Curriculum Lean library.

This file is an umbrella for downstream convenience. Production `FormalMath.*` modules must import
their semantic dependencies directly rather than importing this root umbrella. The current public
surface includes the bounded M2.10 factored-integer-equation slice, bounded Project-4 natural-number
operation-law and integer sign-law examples, one bounded natural-number exercise solution and
diagnostic, three bounded Project-6 core-definition surfaces, their five bounded M6.4 interface
results, one bounded M6.5 function-composition graph result, five bounded M6.6 pedagogical
artifacts, one bounded Project-7 algorithm-correctness contract, and supporting infrastructure. It
does not claim curriculum coverage or formalization completeness.
-/
