/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Reservation preflight for M2.8 stable FART/FLOC/FLINK allocation.

A reservation occupies issued namespace space and therefore must be unique and strictly below the
manifest's next cursor. Reserved or retired IDs are never reusable identities.
-/

open Lean System

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def strField (context : String) (j : Json) (key : String) : Except String String := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def idNumber (context idPrefix value : String) : Except String Nat := do
  if !value.startsWith idPrefix then
    .error s!"traceability:error:{context}:invalid-id:{value}"
  else
    let suffix := String.ofList ((value.toList).drop idPrefix.length)
    if suffix.length != 6 then
      .error s!"traceability:error:{context}:invalid-id:{value}"
    else
      match suffix.toNat? with
      | some n => if n == 0 then .error s!"traceability:error:{context}:invalid-id:{value}" else .ok n
      | none => .error s!"traceability:error:{context}:invalid-id:{value}"

private def nextCursor (nextIds : Json) (family idPrefix : String) : Except String Nat := do
  idNumber "registry-manifest.next_ids" idPrefix (← strField "registry-manifest.next_ids" nextIds family)

private def duplicate? : List String → Option String
  | [] => none
  | x :: xs => if xs.contains x then some x else duplicate? xs

public def validateReservationBoundsRoot (root : FilePath := ".") : IO Unit := do
  let path := root / "metadata" / "formal-artifacts" / "registry.json"
  let text ← IO.FS.readFile path
  let manifest ← IO.ofExcept <| (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
  let nextIds ← IO.ofExcept <| (manifest.getObjVal? "next_ids").mapError fun e => s!"traceability:error:registry-manifest:next_ids:{e}"
  let nextFart ← IO.ofExcept <| nextCursor nextIds "fart" "FART-P2-"
  let nextFloc ← IO.ofExcept <| nextCursor nextIds "floc" "FLOC-P2-"
  let nextFlink ← IO.ofExcept <| nextCursor nextIds "flink" "FLINK-P2-"
  let reservationJson ← IO.ofExcept <| (manifest.getObjVal? "reservations").mapError fun e => s!"traceability:error:registry-manifest:reservations:{e}"
  let reservations ← IO.ofExcept <| reservationJson.getArr? |>.mapError fun e => s!"traceability:error:registry-manifest:reservations:{e}"
  let mut ids := []
  for reservation in reservations do
    let id ← IO.ofExcept <| strField "registry-manifest.reservation" reservation "id"
    ids := id :: ids
    if id.startsWith "FART-P2-" then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FART-P2-" id
      if n >= nextFart then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFart}"
    else if id.startsWith "FLOC-P2-" then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FLOC-P2-" id
      if n >= nextFloc then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFloc}"
    else if id.startsWith "FLINK-P2-" then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" "FLINK-P2-" id
      if n >= nextFlink then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFlink}"
    else
      failIO s!"traceability:error:registry-manifest.reservation:invalid-id:{id}"
  match duplicate? ids with
  | some id => failIO s!"traceability:error:registry:duplicate-reservation:{id}"
  | none => pure ()
  IO.println s!"traceability:reservations:pass:count={ids.length}"

end FormalMathTraceability
