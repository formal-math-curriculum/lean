/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Traceability.IntegrityV1
import Traceability.NavigationV1
import Traceability.Order
import Traceability.RegistryV1
import Traceability.Reservations
import Traceability.Resolve
import Traceability.RoundTrip
import Traceability.Views

/-!
Command-line entry point for governed M2.8 traceability tooling.

Authored FART/FLOC/FLINK metadata remains authoritative. `validate` is intentionally the strongest
production acceptance path: after physical/schema checks it reconciles curriculum authority and
resolves every current source target against the exact selected environment.
-/

open System

namespace FormalMathTraceability

private def parseRoot : List String → Except String FilePath
  | [] => pure "."
  | ["--root", root] => pure root
  | _ => throw "expected optional --root <repository-root>"

private unsafe def validateRoot (root : FilePath) : IO RegistryData := do
  validateShardOrderRoot root
  validateReservationBoundsRoot root
  validateRegistryV1Root root
  let data ← loadRegistryData root
  validateIntegrityV1 data
  resolveCurrentDeclarations root data
  IO.println "traceability:strong-validation:pass"
  return data

private def usage : String :=
  "usage: lake exe traceability <validate|generate|roundtrip|query curriculum <candidate-id>|query artifact <FART-id>|query declaration <module-file-or-declaration>> [--root <repository-root>]"

public unsafe def main (args : List String) : IO Unit := do
  match args with
  | "validate" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let _ ← validateRoot root
      return
  | "generate" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let _ ← validateRoot root
      let _ ← generateViews root
      return
  | "roundtrip" :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let data ← validateRoot root
      verifyRoundTrip root data
  | "query" :: "curriculum" :: candidateId :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let data ← validateRoot root
      queryCurriculumV1 data candidateId
  | "query" :: "artifact" :: artifactId :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let data ← validateRoot root
      queryArtifact data artifactId
  | "query" :: "declaration" :: needle :: rest =>
      let root ← IO.ofExcept <| parseRoot rest
      let data ← validateRoot root
      querySource data needle
  | _ =>
      throw <| IO.userError usage

end FormalMathTraceability
