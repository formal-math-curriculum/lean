/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Traceability.Order
import Traceability.RegistryV1

/-!
Command-line entry point for governed M2.8 traceability tooling.

MAT-195 implements `validate`. Generated views and round-trip/query commands are introduced by the
next implementation issue rather than being stubbed as false capabilities here.
-/

open System

namespace FormalMathTraceability

private def parseRoot : List String → Except String FilePath
  | [] => pure "."
  | ["--root", root] => pure root
  | _ => throw "usage: lake exe traceability validate [--root <repository-root>]"

public def main (args : List String) : IO Unit := do
  match args with
  | "validate" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateShardOrderRoot root
      validateRegistryV1Root root
  | _ =>
      throw <| IO.userError "usage: lake exe traceability validate [--root <repository-root>]"

end FormalMathTraceability
