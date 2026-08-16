/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Allocation/canonical-order preflight for the M2.8 authored traceability registry.

This module intentionally stays separate from the semantic cross-reference validator: it checks that
issued and reserved IDs are strictly below the manifest's next cursor and that records inside each
JSONL shard are ordered by their explicit stable IDs.
-/

open Lean System

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def strField (context : String) (j : Json) (key : String) : Except String String := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def idNumber (context prefix value : String) : Except String Nat := do
  if !value.startsWith prefix then
    throw s!"traceability:error:{context}:invalid-id:{value}"
  let suffix := value.drop prefix.length
  if suffix.length != 6 then
    throw s!"traceability:error:{context}:invalid-id:{value}"
  match suffix.toNat? with
  | some n =>
      if n == 0 then
        throw s!"traceability:error:{context}:invalid-id:{value}"
      else
        return n
  | none => throw s!"traceability:error:{context}:invalid-id:{value}"

private def parseJsonFile (path : FilePath) : IO Json := do
  let text ← IO.FS.readFile path
  let parsed := (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
  IO.ofExcept parsed

private def readJsonl (path : FilePath) : IO (Array Json) := do
  let text ← IO.FS.readFile path
  if text.isEmpty then
    return #[]
  let parts := text.splitOn "\n"
  let lines := if text.endsWith "\n" then (parts.reverse.drop 1).reverse else parts
  let mut result := #[]
  for line in lines do
    if !line.isEmpty then
      let parsed := (Json.parse line).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
      result := result.push (← IO.ofExcept parsed)
  return result

private def nextCursor (manifest : Json) (family prefix : String) : Except String Nat := do
  let nextIds ← (manifest.getObjVal? "next_ids").mapError fun e => s!"traceability:error:registry-manifest:next_ids:{e}"
  let id ← strField "registry-manifest.next_ids" nextIds family
  idNumber "registry-manifest.next_ids" prefix id

private def validateShard (path : FilePath) (prefix : String) (next : Nat) : IO Unit := do
  let records ← readJsonl path
  let mut previous : Option String := none
  for record in records do
    let id ← IO.ofExcept <| strField s!"shard:{path}" record "id"
    let number ← IO.ofExcept <| idNumber s!"shard:{path}" prefix id
    if number >= next then
      failIO s!"traceability:error:allocation:issued-id-not-below-next:{id}:next={next}"
    match previous with
    | some prior =>
        if prior == id then
          failIO s!"traceability:error:registry:duplicate-id:{id}"
        else if !(decide (prior < id)) then
          failIO s!"traceability:error:allocation:noncanonical-record-order:{path}:{prior}:{id}"
    | none => pure ()
    previous := some id

private def validateFamily (root : FilePath) (family prefix : String) (next : Nat) : IO Unit := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then
    return
  if !(← dir.isDir) then
    failIO s!"traceability:error:{dir}:not-directory"
  let paths ← dir.walkDir
  for path in paths do
    if path.extension == some "jsonl" then
      validateShard path prefix next

private def validateReservations (manifest : Json) (nextFart nextFloc nextFlink : Nat) : IO Unit := do
  let reservationsJson ← IO.ofExcept <| (manifest.getObjVal? "reservations").mapError fun e =>
    s!"traceability:error:registry-manifest:reservations:{e}"
  let reservations ← IO.ofExcept <| reservationsJson.getArr? |>.mapError fun e =>
    s!"traceability:error:registry-manifest:reservations:{e}"
  for reservation in reservations do
    let id ← IO.ofExcept <| strField "registry-manifest.reservation" reservation "id"
    if id.startsWith "FART-P2-" then
      let number ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FART-P2-" id
      if number >= nextFart then
        failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFart}"
    else if id.startsWith "FLOC-P2-" then
      let number ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FLOC-P2-" id
      if number >= nextFloc then
        failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFloc}"
    else if id.startsWith "FLINK-P2-" then
      let number ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FLINK-P2-" id
      if number >= nextFlink then
        failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFlink}"
    else
      failIO s!"traceability:error:registry-manifest.reservation:invalid-id:{id}"

public def validateAllocationRoot (root : FilePath := ".") : IO Unit := do
  let manifestPath := root / "metadata" / "formal-artifacts" / "registry.json"
  let manifest ← parseJsonFile manifestPath
  let nextFart ← IO.ofExcept <| nextCursor manifest "fart" "FART-P2-"
  let nextFloc ← IO.ofExcept <| nextCursor manifest "floc" "FLOC-P2-"
  let nextFlink ← IO.ofExcept <| nextCursor manifest "flink" "FLINK-P2-"
  validateFamily root "fart" "FART-P2-" nextFart
  validateFamily root "floc" "FLOC-P2-" nextFloc
  validateFamily root "flink" "FLINK-P2-" nextFlink
  validateReservations manifest nextFart nextFloc nextFlink
  IO.println s!"traceability:allocation:pass:next-fart={nextFart};next-floc={nextFloc};next-flink={nextFlink}"

end FormalMathTraceability
