/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Traceability.Main

/-!
Executable root for the non-default M2.8 traceability CLI.
-/

public def main (args : List String) : IO Unit :=
  FormalMathTraceability.main args
