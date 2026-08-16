/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Traceability.NavigationV1
public import Traceability.ProvenanceV2

/-!
M2.9 read-only reader/navigation envelopes.

The existing `query` JSONL streams remain unchanged. Reader v2 adds explicit cardinality,
match-reason, lifecycle, and unresolved diagnostics without creating or mutating authority.
-/

open Lean

namespace FormalMathTraceability

private def readerFailIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def jsonArrayV2 (xs : List Json) : Json :=
  Json.arr xs.toArray

private def jsonStringArrayV2 (xs : List String) : Json :=
  Json.arr (xs.map Json.str).toArray

private def jsonArrayFieldV2 (context : String) (j : Json) (key : String) : Except String (List Json) := do
  let values ← (← jsonField context j key).getArr? |>.mapError fun e =>
    s!"traceability:reader-v2:error:{context}:{key}:{e}"
  return values.toList

private def countState (count : Nat) : String :=
  if count == 0 then "zero_matches" else if count == 1 then "matches" else "multiple_matches"

private def envelope (kind value : String) (results : List Json) (state? : Option String := none) : Json :=
  Json.mkObj [
    ("reader_contract_ref", Json.str "P2-TRACE-M2.9-READER-v2"),
    ("authority", Json.str "derived_read_only"),
    ("query_kind", Json.str kind),
    ("query_value", Json.str value),
    ("match_count", Json.num results.length),
    ("result_state", Json.str (state?.getD (countState results.length))),
    ("results", jsonArrayV2 results)
  ]

private def curriculumMatchReasons (record : Json) (candidateId : String) : List String :=
  let recorded := match stringField "by-curriculum" record "candidate_ref_as_recorded" with
    | .ok id => id == candidateId
    | .error _ => false
  let current := match stringField "by-curriculum" record "candidate_ref_current_resolved" with
    | .ok id => id == candidateId
    | .error _ => false
  let mut reasons := []
  if recorded then reasons := "recorded_identity" :: reasons
  if current then reasons := "current_resolved_identity" :: reasons
  reasons.reverse

private def curriculumTreatment? (record : Json) : Except String String := do
  let link ← jsonField "by-curriculum" record "link"
  stringField "flink" link "treatment_scope"

private def decorateCurriculum (record : Json) (candidateId : String) : Json :=
  Json.mkObj [
    ("match_reasons", jsonStringArrayV2 (curriculumMatchReasons record candidateId)),
    ("record", record)
  ]

public def inspectCurriculumV2 (data : RegistryData) (candidateId : String)
    (treatment : Option String := none) : IO Unit := do
  let records ← byCurriculum data
  let mut matches := []
  for record in records do
    let reasons := curriculumMatchReasons record candidateId
    if !reasons.isEmpty then
      let treatmentMatches ← match treatment with
        | none => pure true
        | some expected =>
            match curriculumTreatment? record with
            | .ok actual => pure (actual == expected)
            | .error e => readerFailIO e
      if treatmentMatches then
        matches := decorateCurriculum record candidateId :: matches
  IO.println <| Json.compress <| envelope "curriculum" candidateId matches.reverse

private def locatorStatus (locator : Json) : String :=
  match stringField "floc" locator "locator_status" with
  | .ok status => status
  | .error _ => "invalid"

private def filterLocators (locators : List Json) (status : String) : List Json :=
  locators.filter fun locator => locatorStatus locator == status

private def decorateArtifact (record : Json) : IO Json := do
  let locators ← IO.ofExcept <| jsonArrayFieldV2 "by-artifact" record "locators"
  let links ← IO.ofExcept <| jsonArrayFieldV2 "by-artifact" record "curriculum_links"
  let current := filterLocators locators "current"
  let historical := filterLocators locators "historical"
  let unresolved := filterLocators locators "unresolved"
  return Json.mkObj [
    ("locator_counts", Json.mkObj [
      ("total", Json.num locators.length),
      ("current", Json.num current.length),
      ("historical", Json.num historical.length),
      ("unresolved", Json.num unresolved.length)
    ]),
    ("curriculum_link_count", Json.num links.length),
    ("current_locators", jsonArrayV2 current),
    ("historical_locators", jsonArrayV2 historical),
    ("unresolved_locators", jsonArrayV2 unresolved),
    ("record", record)
  ]

public def inspectArtifactV2 (data : RegistryData) (artifactId : String) : IO Unit := do
  let records ← byArtifact data
  let mut matches := []
  for record in records do
    let id ← IO.ofExcept <| stringField "by-artifact" record "artifact_id"
    if id == artifactId then matches := (← decorateArtifact record) :: matches
  IO.println <| Json.compress <| envelope "artifact" artifactId matches.reverse

private def sourceMatchReasons (record : Json) (needle : String) : Except String (List String) := do
  let locator ← jsonField "by-source" record "locator"
  let moduleName ← stringField "floc" locator "module_name"
  let filePath ← stringField "floc" locator "file_path"
  let declarations ← stringArrayField "floc" locator "declaration_names"
  let mut reasons := []
  if moduleName == needle then reasons := "module_name" :: reasons
  if filePath == needle then reasons := "file_path" :: reasons
  if declarations.contains needle then reasons := "declaration_name" :: reasons
  return reasons.reverse

public def inspectSourceV2 (data : RegistryData) (needle : String) : IO Unit := do
  let records ← bySource data
  let mut matches := []
  for record in records do
    let reasons ← IO.ofExcept <| sourceMatchReasons record needle
    if !reasons.isEmpty then
      matches := Json.mkObj [
        ("match_reasons", jsonStringArrayV2 reasons),
        ("record", record)
      ] :: matches
  IO.println <| Json.compress <| envelope "source" needle matches.reverse

public def inspectUnresolvedV2 (data : RegistryData) : IO Unit := do
  let records ← unresolvedView data
  let state := if records.isEmpty then "zero_matches" else "unresolved_present"
  IO.println <| Json.compress <| envelope "unresolved" "all" records (some state)

end FormalMathTraceability
