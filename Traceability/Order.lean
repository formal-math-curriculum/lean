/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Per-shard ordering preflight for authored M2.8 JSONL records.

Every non-empty FART/FLOC/FLINK shard must contain records in strictly increasing stable-ID order.
This check is intentionally file-local so multiple shards do not depend on filesystem traversal order.
-/

open Lean System

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def recordId (path : FilePath) (lineNo : Nat) (line : String) : IO String := do
  let parsed := (Json.parse line).mapError fun e =>
    s!"traceability:error:{path}:{lineNo}:json-parse:{e}"
  let json ← IO.ofExcept parsed
  let value ← IO.ofExcept <| (json.getObjVal? "id").mapError fun e =>
    s!"traceability:error:{path}:{lineNo}:id:{e}"
  IO.ofExcept <| value.getStr? |>.mapError fun e =>
    s!"traceability:error:{path}:{lineNo}:id:{e}"

private def validateShardOrder (path : FilePath) : IO Unit := do
  let text ← IO.FS.readFile path
  if text.isEmpty then
    return
  let parts := text.splitOn "\n"
  let lines := if text.endsWith "\n" then (parts.reverse.drop 1).reverse else parts
  let mut previous : Option String := none
  let mut lineNo := 0
  for line in lines do
    lineNo := lineNo + 1
    if line.isEmpty then
      continue
    let id ← recordId path lineNo line
    match previous with
    | none => pure ()
    | some prior =>
        if prior == id then
          failIO s!"traceability:error:registry:duplicate-id:{id}"
        else if !(decide (prior < id)) then
          failIO s!"traceability:error:allocation:noncanonical-record-order:{path}:{prior}:{id}"
    previous := some id

private def validateFamilyOrder (root : FilePath) (family : String) : IO Unit := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then
    return
  if !(← dir.isDir) then
    failIO s!"traceability:error:{dir}:not-directory"
  let paths ← dir.walkDir
  for path in paths do
    if path.extension == some "jsonl" then
      validateShardOrder path

public def validateShardOrderRoot (root : FilePath := ".") : IO Unit := do
  validateFamilyOrder root "fart"
  validateFamilyOrder root "floc"
  validateFamilyOrder root "flink"
  IO.println "traceability:shard-order:pass"

end FormalMathTraceability
