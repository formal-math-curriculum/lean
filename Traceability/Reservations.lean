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
manifest's next cursor. Reserved or retired IDs are never reusable identities. Synthetic M2.9
fixtures use a disjoint `S*` namespace while exercising the same cursor invariants.
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

private structure ReservationNamespace where
  fartPrefix : String
  flocPrefix : String
  flinkPrefix : String

private def reservationNamespace (manifest : Json) : Except String ReservationNamespace := do
  let status ← strField "registry-manifest" manifest "registry_status"
  if status == "active" then
    return { fartPrefix := "FART-P2-", flocPrefix := "FLOC-P2-", flinkPrefix := "FLINK-P2-" }
  if status == "synthetic_fixture" then
    return { fartPrefix := "SFART-M2-", flocPrefix := "SFLOC-M2-", flinkPrefix := "SFLINK-M2-" }
  .error s!"traceability:error:registry-manifest:invalid-enum:registry_status:{status}"

public def validateReservationBoundsRoot (root : FilePath := ".") : IO Unit := do
  let path := root / "metadata" / "formal-artifacts" / "registry.json"
  let text ← IO.FS.readFile path
  let manifest ← IO.ofExcept <| (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
  let ns ← IO.ofExcept <| reservationNamespace manifest
  let nextIds ← IO.ofExcept <| (manifest.getObjVal? "next_ids").mapError fun e => s!"traceability:error:registry-manifest:next_ids:{e}"
  let nextFart ← IO.ofExcept <| nextCursor nextIds "fart" ns.fartPrefix
  let nextFloc ← IO.ofExcept <| nextCursor nextIds "floc" ns.flocPrefix
  let nextFlink ← IO.ofExcept <| nextCursor nextIds "flink" ns.flinkPrefix
  let reservationJson ← IO.ofExcept <| (manifest.getObjVal? "reservations").mapError fun e => s!"traceability:error:registry-manifest:reservations:{e}"
  let reservations ← IO.ofExcept <| reservationJson.getArr? |>.mapError fun e => s!"traceability:error:registry-manifest:reservations:{e}"
  let mut ids := []
  for reservation in reservations do
    let id ← IO.ofExcept <| strField "registry-manifest.reservation" reservation "id"
    ids := id :: ids
    if id.startsWith ns.fartPrefix then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" ns.fartPrefix id
      if n >= nextFart then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFart}"
    else if id.startsWith ns.flocPrefix then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" ns.flocPrefix id
      if n >= nextFloc then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFloc}"
    else if id.startsWith ns.flinkPrefix then
      let n ← IO.ofExcept <| idNumber "registry-manifest.reservation" ns.flinkPrefix id
      if n >= nextFlink then failIO s!"traceability:error:allocation:reserved-id-not-below-next:{id}:next={nextFlink}"
    else
      failIO s!"traceability:error:registry-manifest.reservation:invalid-id:{id}"
  match duplicate? ids with
  | some id => failIO s!"traceability:error:registry:duplicate-reservation:{id}"
  | none => pure ()
  IO.println s!"traceability:reservations:pass:count={ids.length}"

end FormalMathTraceability
