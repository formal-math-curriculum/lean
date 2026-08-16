/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Traceability.Resolve
public import Traceability.Views

/-!
Bidirectional set-valued round-trip checks over generated M2.8 traceability projections.
-/

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def nestedId (context outerKey : String) (record : Json) : IO String := do
  let nested ← IO.ofExcept <| jsonField context record outerKey
  IO.ofExcept <| stringField context nested "id"

private def artifactViewHasLink (record : Json) (linkId : String) : IO Bool := do
  let links ← IO.ofExcept <| jsonField "by-artifact" record "curriculum_links"
  let values ← IO.ofExcept <| links.getArr? |>.mapError fun e => s!"traceability:error:roundtrip:curriculum_links:{e}"
  for link in values do
    if (← IO.ofExcept <| stringField "flink" link "id") == linkId then return true
  return false

private def sourceViewHasLink (record : Json) (linkId : String) : IO Bool := do
  let links ← IO.ofExcept <| jsonField "by-source" record "curriculum_links"
  let values ← IO.ofExcept <| links.getArr? |>.mapError fun e => s!"traceability:error:roundtrip:source-links:{e}"
  for link in values do
    if (← IO.ofExcept <| stringField "flink" link "id") == linkId then return true
  return false

public unsafe def verifyRoundTrip (data : RegistryData) : IO Unit := do
  resolveCurrentDeclarations data
  let curriculum ← byCurriculum data
  let artifacts ← byArtifact data
  let sources ← bySource data
  let mut linkCount := 0
  let mut locatorCount := 0

  for link in data.flinks do
    linkCount := linkCount + 1
    let linkId ← IO.ofExcept <| stringField "flink" link "id"
    let fartId ← IO.ofExcept <| stringField "flink" link "formal_artifact_ref"
    let forwardFound ← curriculum.anyM fun record => do
      let nested ← IO.ofExcept <| jsonField "by-curriculum" record "link"
      return (← IO.ofExcept <| stringField "flink" nested "id") == linkId
    if !forwardFound then failIO s!"traceability:error:roundtrip:missing-forward-link:{linkId}"
    let some artifactRecord ← artifacts.findM? (fun record => do
      return (← IO.ofExcept <| stringField "by-artifact" record "artifact_id") == fartId)
      | failIO s!"traceability:error:roundtrip:missing-artifact-view:{fartId}"
    if !(← artifactViewHasLink artifactRecord linkId) then
      failIO s!"traceability:error:roundtrip:artifact-missing-link:{fartId}:{linkId}"
    for floc in (← flocsForFart data fartId) do
      let flocId ← IO.ofExcept <| stringField "floc" floc "id"
      locatorCount := locatorCount + 1
      let some sourceRecord ← sources.findM? (fun record => do
        return (← nestedId "by-source" "locator" record) == flocId)
        | failIO s!"traceability:error:roundtrip:missing-source-view:{flocId}"
      if !(← sourceViewHasLink sourceRecord linkId) then
        failIO s!"traceability:error:roundtrip:source-missing-link:{flocId}:{linkId}"

  IO.println s!"traceability:roundtrip:pass:links={linkCount};locator-link-checks={locatorCount}"

end FormalMathTraceability
