/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Traceability.Order
import Traceability.RegistryV1
import Traceability.Reservations
import Traceability.Resolve
import Traceability.RoundTrip
import Traceability.Views

/-!
Command-line entry point for governed M2.8 traceability tooling.

Authored FART/FLOC/FLINK metadata remains authoritative. Generated views, queries and round-trip
checks are derived assurance/navigation surfaces only.
-/

open System

namespace FormalMathTraceability

private def parseRoot : List String → Except String FilePath
  | [] => pure "."
  | ["--root", root] => pure root
  | _ => throw "expected optional --root <repository-root>"

private def validateRoot (root : FilePath) : IO Unit := do
  validateShardOrderRoot root
  validateReservationBoundsRoot root
  validateRegistryV1Root root

private def usage : String :=
  "usage: lake exe traceability <validate|generate|roundtrip|query curriculum <candidate-id>|query artifact <FART-id>|query declaration <module-file-or-declaration>> [--root <repository-root>]"

public unsafe def main (args : List String) : IO Unit := do
  match args with
  | "validate" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
  | "generate" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
      let data ← loadRegistryData root
      resolveCurrentDeclarations data
      let _ ← generateViews root
      return
  | "roundtrip" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
      let data ← loadRegistryData root
      verifyRoundTrip data
  | "query" :: "curriculum" :: candidateId :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
      queryCurriculum (← loadRegistryData root) candidateId
  | "query" :: "artifact" :: artifactId :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
      queryArtifact (← loadRegistryData root) artifactId
  | "query" :: "declaration" :: needle :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      validateRoot root
      let data ← loadRegistryData root
      resolveCurrentDeclarations data
      querySource data needle
  | _ =>
      throw <| IO.userError usage

end FormalMathTraceability
