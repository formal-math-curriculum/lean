/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
import Quality.SourceAudit

open System
open FormalMathQuality.SourceAudit

private def report (label : String) (findings : Array Finding) : IO UInt32 := do
  for finding in findings do
    printFinding finding
  let errors := errorCount findings
  let advisories := advisoryCount findings
  IO.println s!"source audit: scope={label}; errors={errors}; advisories={advisories}"
  return if errors == 0 then 0 else 1

private def productionAudit : IO UInt32 := do
  let rootFindings ← auditFile "FormalMath.lean" (isProduction := true)
  let sourceFindings ← auditTree "FormalMath" (isProduction := true)
  let qualityFindings ← auditTree "Quality" (isProduction := false) (excludeFixtures := true)
  report "production" (rootFindings ++ sourceFindings ++ qualityFindings)

private def oneFileAudit (path : String) : IO UInt32 := do
  report path (← auditFile path (isProduction := true))

public def main (args : List String) : IO UInt32 :=
  match args with
  | ["production"] => productionAudit
  | ["file", path] => oneFileAudit path
  | _ => do
      IO.eprintln "usage: lean --run Quality/RunSourceAudit.lean production | file <path>"
      return 2
