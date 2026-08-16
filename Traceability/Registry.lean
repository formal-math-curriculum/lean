/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Deterministic M2.8 authored-registry validation.

This module validates canonical JSON/JSONL, stable-ID allocation and shard ordering,
FART/FLOC/FLINK schema and referential integrity, the minimal non-authoritative curriculum lock,
and current project-file locators. It deliberately does not assign curriculum semantics from code.
-/

open Lean System

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def failE (context msg : String) : Except String α :=
  .error s!"traceability:error:{context}:{msg}"

private def objKeys (j : Json) : Except String (List String) := do
  let obj ← j.getObj?
  return obj.foldl (fun acc key _ => key :: acc) []

private def requireExactKeys (context : String) (j : Json) (allowed : List String) : Except String Unit := do
  let keys ← objKeys j
  for key in keys do
    if !allowed.contains key then
      failE context s!"unknown-field:{key}"
  for key in allowed do
    if !keys.contains key then
      failE context s!"missing-field:{key}"

private def strField (context : String) (j : Json) (key : String) : Except String String := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def natField (context : String) (j : Json) (key : String) : Except String Nat := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  value.getNat? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def objField (context : String) (j : Json) (key : String) : Except String Json := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  let _ ← value.getObj? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  return value

private def arrField (context : String) (j : Json) (key : String) : Except String (Array Json) := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  value.getArr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def strArrayField (context : String) (j : Json) (key : String) : Except String (List String) := do
  let values ← arrField context j key
  let mut result := []
  for value in values do
    let s ← value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"
    result := s :: result
  return result.reverse

private def requireNonempty (context key value : String) : Except String Unit :=
  if value.isEmpty then failE context s!"empty-field:{key}" else .ok ()

private def requireEnum (context key value : String) (allowed : List String) : Except String Unit :=
  if allowed.contains value then .ok () else failE context s!"invalid-enum:{key}:{value}"

private def firstDuplicate : List String → Option String
  | [] => none
  | value :: rest => if rest.contains value then some value else firstDuplicate rest

private def strictlySorted : List String → Bool
  | a :: b :: rest => decide (a < b) && strictlySorted (b :: rest)
  | _ => true

private def requireUnique (context key : String) (values : List String) : Except String Unit :=
  match firstDuplicate values with
  | some value => failE context s!"duplicate-set-value:{key}:{value}"
  | none => .ok ()

private def requireSortedUnique (context key : String) (values : List String) : Except String Unit := do
  requireUnique context key values
  if !strictlySorted values then
    failE context s!"noncanonical-set-order:{key}"

private def idNumber (context idPrefix value : String) : Except String Nat := do
  if !value.startsWith idPrefix then
    failE context s!"invalid-id:{value}"
  let suffix := value.drop idPrefix.length
  if suffix.length != 6 then
    failE context s!"invalid-id:{value}"
  match suffix.toNat? with
  | none => failE context s!"invalid-id:{value}"
  | some 0 => failE context s!"invalid-id:{value}"
  | some n => return n

private def pad6 (n : Nat) : String :=
  let s := toString n
  String.ofList (List.replicate (6 - s.length) '0') ++ s

private def expectedShard (n : Nat) : String :=
  let first := ((n - 1) / 1000) * 1000 + 1
  let last := first + 999
  s!"{pad6 first}-{pad6 last}.jsonl"

private def readCanonicalJson (path : FilePath) : IO Json := do
  if !(← path.pathExists) then
    failIO s!"traceability:error:{path}:missing-file"
  let text ← IO.FS.readFile path
  let parsed := (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
  let json ← IO.ofExcept parsed
  if text != Json.compress json ++ "\n" then
    failIO s!"traceability:error:{path}:noncanonical-json"
  return json

private def readCanonicalJsonl (path : FilePath) : IO (Array Json) := do
  let text ← IO.FS.readFile path
  if text.isEmpty then
    return #[]
  if !text.endsWith "\n" then
    failIO s!"traceability:error:{path}:missing-final-newline"
  let parts := text.splitOn "\n"
  let lines := (parts.reverse.drop 1).reverse
  let mut out := #[]
  let mut lineNo := 0
  for line in lines do
    lineNo := lineNo + 1
    if line.isEmpty then
      failIO s!"traceability:error:{path}:{lineNo}:blank-jsonl-line"
    let parsed := (Json.parse line).mapError fun e => s!"traceability:error:{path}:{lineNo}:json-parse:{e}"
    let json ← IO.ofExcept parsed
    if Json.compress json != line then
      failIO s!"traceability:error:{path}:{lineNo}:noncanonical-jsonl"
    out := out.push json
  return out

private structure LocatedJson where
  path : FilePath
  value : Json

private def readFamily (root : FilePath) (family : String) : IO (Array LocatedJson) := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then
    return #[]
  if !(← dir.isDir) then
    failIO s!"traceability:error:{dir}:not-directory"
  let paths ← dir.walkDir
  let mut records := #[]
  for path in paths do
    if path.extension == some "jsonl" then
      let values ← readCanonicalJsonl path
      for value in values do
        records := records.push { path := path, value := value }
  return records

private structure RegistryManifest where
  nextFart : Nat
  nextFloc : Nat
  nextFlink : Nat
  countFart : Nat
  countFloc : Nat
  countFlink : Nat
  reservations : List String

private def validateManifest (j : Json) : Except String RegistryManifest := do
  let context := "registry-manifest"
  requireExactKeys context j [
    "default_curriculum_baseline_ref", "dependency_baseline_ref", "format", "lean_toolchain_ref",
    "next_ids", "protocol_ref", "record_counts", "registry_semantics_ref", "registry_status",
    "reservations", "schema_version", "shard_size"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  if (← strField context j "format") != "formal-artifacts-jsonl-v1" then failE context "invalid-format"
  if (← natField context j "shard_size") != 1000 then failE context "invalid-shard-size"
  if (← strField context j "registry_semantics_ref") != "P2-TRACE-M2.8-REGISTRY-v1" then failE context "registry-semantics-ref-mismatch"
  if (← strField context j "protocol_ref") != "P2-TRACE-M2.8-PROTOCOL-v1" then failE context "protocol-ref-mismatch"
  requireNonempty context "default_curriculum_baseline_ref" (← strField context j "default_curriculum_baseline_ref")
  requireNonempty context "dependency_baseline_ref" (← strField context j "dependency_baseline_ref")
  requireNonempty context "lean_toolchain_ref" (← strField context j "lean_toolchain_ref")
  requireNonempty context "registry_status" (← strField context j "registry_status")

  let nextIds ← objField context j "next_ids"
  requireExactKeys "registry-manifest.next_ids" nextIds ["fart", "flink", "floc"]
  let nextFart ← idNumber "registry-manifest.next_ids.fart" "FART-P2-" (← strField "registry-manifest.next_ids" nextIds "fart")
  let nextFlink ← idNumber "registry-manifest.next_ids.flink" "FLINK-P2-" (← strField "registry-manifest.next_ids" nextIds "flink")
  let nextFloc ← idNumber "registry-manifest.next_ids.floc" "FLOC-P2-" (← strField "registry-manifest.next_ids" nextIds "floc")

  let counts ← objField context j "record_counts"
  requireExactKeys "registry-manifest.record_counts" counts ["fart", "flink", "floc"]
  let countFart ← natField "registry-manifest.record_counts" counts "fart"
  let countFlink ← natField "registry-manifest.record_counts" counts "flink"
  let countFloc ← natField "registry-manifest.record_counts" counts "floc"

  let reservationValues ← arrField context j "reservations"
  let mut reservations := []
  for value in reservationValues do
    requireExactKeys "registry-manifest.reservation" value ["id", "reason", "state"]
    let rid ← strField "registry-manifest.reservation" value "id"
    if !(rid.startsWith "FART-P2-" || rid.startsWith "FLOC-P2-" || rid.startsWith "FLINK-P2-") then
      failE "registry-manifest.reservation" s!"invalid-id:{rid}"
    let state ← strField "registry-manifest.reservation" value "state"
    requireEnum "registry-manifest.reservation" "state" state ["reserved_unissued", "retired_identity"]
    requireNonempty "registry-manifest.reservation" "reason" (← strField "registry-manifest.reservation" value "reason")
    reservations := rid :: reservations

  return {
    nextFart := nextFart
    nextFloc := nextFloc
    nextFlink := nextFlink
    countFart := countFart
    countFloc := countFloc
    countFlink := countFlink
    reservations := reservations.reverse
  }

private structure FartSummary where
  id : String
  number : Nat
  currentLocators : List String
  curriculumLinks : List String

private structure FlocSummary where
  id : String
  number : Nat
  fart : String
  locatorStatus : String
  sourceKind : String
  filePath : String

private structure FlinkSummary where
  id : String
  number : Nat
  fart : String
  candidateRecorded : String
  linkStatus : String
  lineageState : String

private def validateSourceProvenance (j : Json) : Except String Unit := do
  let context := "fart.source_provenance"
  requireExactKeys context j ["proof_or_implementation_provenance_notes", "provenance_kind", "source_refs", "statement_provenance_notes"]
  requireEnum context "provenance_kind" (← strField context j "provenance_kind")
    ["original_project", "adapted_from_dependency", "direct_dependency_representation", "mixed", "other"]
  let refs ← strArrayField context j "source_refs"
  requireSortedUnique context "source_refs" refs
  let _ ← strField context j "statement_provenance_notes"
  let _ ← strField context j "proof_or_implementation_provenance_notes"

private def validateFart (located : LocatedJson) : Except String FartSummary := do
  let j := located.value
  let context := "fart"
  let keys ← objKeys j
  if keys.contains "formalized" then failE context "forbidden-conflated-field:formalized"
  requireExactKeys context j [
    "artifact_kind", "created_revision", "current_locator_refs", "curriculum_link_refs",
    "dependency_baseline_ref", "id", "lean_toolchain_ref", "quality_state", "record_status",
    "representation_state", "schema_version", "source_provenance", "superseded_by", "supersedes",
    "title_or_summary", "verification_state"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  let id ← strField context j "id"
  let number ← idNumber context "FART-P2-" id
  if located.path.fileName.getD "" != expectedShard number then
    failE context s!"wrong-shard:{id}:{located.path.fileName.getD ""}"
  requireEnum context "artifact_kind" (← strField context j "artifact_kind")
    ["definition", "theorem", "theorem_family", "structure_api", "model", "encoding", "example", "exercise_solution", "infrastructure", "other"]
  requireNonempty context "title_or_summary" (← strField context j "title_or_summary")
  requireEnum context "representation_state" (← strField context j "representation_state")
    ["unknown", "not_assessed", "planned", "partial", "represented"]
  requireEnum context "verification_state" (← strField context j "verification_state")
    ["not_checked", "elaborates", "kernel_checked", "regression_verified"]
  requireEnum context "quality_state" (← strField context j "quality_state")
    ["not_assessed", "draft", "reviewed", "approved"]
  requireEnum context "record_status" (← strField context j "record_status")
    ["active", "historical", "superseded", "retired", "unresolved"]
  let currentLocators ← strArrayField context j "current_locator_refs"
  let curriculumLinks ← strArrayField context j "curriculum_link_refs"
  let supersedes ← strArrayField context j "supersedes"
  let supersededBy ← strArrayField context j "superseded_by"
  requireSortedUnique context "current_locator_refs" currentLocators
  requireSortedUnique context "curriculum_link_refs" curriculumLinks
  requireSortedUnique context "supersedes" supersedes
  requireSortedUnique context "superseded_by" supersededBy
  for ref in currentLocators do
    let _ ← idNumber context "FLOC-P2-" ref
  for ref in curriculumLinks do
    let _ ← idNumber context "FLINK-P2-" ref
  for ref in supersedes do
    let _ ← idNumber context "FART-P2-" ref
  for ref in supersededBy do
    let _ ← idNumber context "FART-P2-" ref
  validateSourceProvenance (← objField context j "source_provenance")
  requireNonempty context "lean_toolchain_ref" (← strField context j "lean_toolchain_ref")
  requireNonempty context "dependency_baseline_ref" (← strField context j "dependency_baseline_ref")
  requireNonempty context "created_revision" (← strField context j "created_revision")
  return { id := id, number := number, currentLocators := currentLocators, curriculumLinks := curriculumLinks }

private def validateFloc (located : LocatedJson) : Except String FlocSummary := do
  let j := located.value
  let context := "floc"
  requireExactKeys context j [
    "created_revision", "declaration_names", "dependency_baseline_ref", "file_path", "formal_artifact_ref",
    "id", "locator_status", "module_name", "observed_at", "record_status", "repository", "revision",
    "schema_version", "source_kind", "structural_anchors", "superseded_by_locator_refs", "supersedes_locator_refs"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  let id ← strField context j "id"
  let number ← idNumber context "FLOC-P2-" id
  if located.path.fileName.getD "" != expectedShard number then
    failE context s!"wrong-shard:{id}:{located.path.fileName.getD ""}"
  let fart ← strField context j "formal_artifact_ref"
  let _ ← idNumber context "FART-P2-" fart
  let sourceKind ← strField context j "source_kind"
  requireEnum context "source_kind" sourceKind ["project_repository", "dependency_repository"]
  let dependencyBaseline ← strField context j "dependency_baseline_ref"
  let filePath ← strField context j "file_path"
  requireNonempty context "repository" (← strField context j "repository")
  requireNonempty context "revision" (← strField context j "revision")
  requireNonempty context "module_name" (← strField context j "module_name")
  requireNonempty context "file_path" filePath
  if sourceKind == "project_repository" then
    if dependencyBaseline != "not_applicable" then failE context "project-locator-dependency-baseline-must-be-not_applicable"
  else if dependencyBaseline == "not_applicable" || dependencyBaseline.isEmpty then
    failE context "dependency-locator-missing-baseline"
  let decls ← strArrayField context j "declaration_names"
  let anchors ← strArrayField context j "structural_anchors"
  let supersedes ← strArrayField context j "supersedes_locator_refs"
  let supersededBy ← strArrayField context j "superseded_by_locator_refs"
  requireSortedUnique context "declaration_names" decls
  requireSortedUnique context "structural_anchors" anchors
  requireSortedUnique context "supersedes_locator_refs" supersedes
  requireSortedUnique context "superseded_by_locator_refs" supersededBy
  for ref in supersedes do
    let _ ← idNumber context "FLOC-P2-" ref
  for ref in supersededBy do
    let _ ← idNumber context "FLOC-P2-" ref
  let locatorStatus ← strField context j "locator_status"
  requireEnum context "locator_status" locatorStatus ["current", "historical", "superseded", "unresolved"]
  requireEnum context "record_status" (← strField context j "record_status") ["active", "historical", "superseded", "retired", "unresolved"]
  requireNonempty context "observed_at" (← strField context j "observed_at")
  requireNonempty context "created_revision" (← strField context j "created_revision")
  return {
    id := id, number := number, fart := fart, locatorStatus := locatorStatus,
    sourceKind := sourceKind, filePath := filePath
  }

private def validateLineage (j : Json) : Except String String := do
  let context := "flink.candidate_lineage_resolution"
  requireExactKeys context j ["resolution_context", "resolution_path", "review_ref", "state"]
  let state ← strField context j "state"
  requireEnum context "state" state ["resolved_exact", "resolved_lineage", "needs_scope_review", "ambiguous", "stale", "unresolved"]
  requireNonempty context "resolution_context" (← strField context j "resolution_context")
  requireNonempty context "review_ref" (← strField context j "review_ref")
  requireUnique context "resolution_path" (← strArrayField context j "resolution_path")
  return state

private def requireNotNull (context key : String) (j : Json) : Except String Unit := do
  let value ← (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  match value with
  | .null => failE context s!"null-{key}"
  | _ => .ok ()

private def validateFlink (located : LocatedJson) : Except String FlinkSummary := do
  let j := located.value
  let context := "flink"
  requireExactKeys context j [
    "assumptions_or_formulation_notes", "candidate_lineage_resolution", "candidate_ref_as_recorded",
    "candidate_ref_current_resolved", "coverage_claim_scope", "created_revision", "curriculum_release_ref",
    "formal_artifact_ref", "id", "link_confidence", "link_status", "record_status", "representation_relation",
    "schema_version", "treatment_scope"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  let id ← strField context j "id"
  let number ← idNumber context "FLINK-P2-" id
  if located.path.fileName.getD "" != expectedShard number then
    failE context s!"wrong-shard:{id}:{located.path.fileName.getD ""}"
  let fart ← strField context j "formal_artifact_ref"
  let _ ← idNumber context "FART-P2-" fart
  let candidateRecorded ← strField context j "candidate_ref_as_recorded"
  requireNonempty context "candidate_ref_as_recorded" candidateRecorded
  requireNonempty context "candidate_ref_current_resolved" (← strField context j "candidate_ref_current_resolved")
  requireNonempty context "curriculum_release_ref" (← strField context j "curriculum_release_ref")
  let lineageState ← validateLineage (← objField context j "candidate_lineage_resolution")
  requireNotNull context "treatment_scope" j
  requireNotNull context "coverage_claim_scope" j
  let _ ← strField context j "assumptions_or_formulation_notes"
  requireEnum context "representation_relation" (← strField context j "representation_relation")
    ["represents", "partially_represents", "example_of", "exercise_for", "implementation_support_for", "model_for", "other"]
  requireEnum context "link_confidence" (← strField context j "link_confidence")
    ["established", "reviewed_provisional", "provisional", "unresolved"]
  let linkStatus ← strField context j "link_status"
  requireEnum context "link_status" linkStatus ["current", "historical", "superseded", "needs_review", "unresolved"]
  requireEnum context "record_status" (← strField context j "record_status")
    ["active", "historical", "superseded", "retired", "unresolved"]
  requireNonempty context "created_revision" (← strField context j "created_revision")
  return {
    id := id, number := number, fart := fart, candidateRecorded := candidateRecorded,
    linkStatus := linkStatus, lineageState := lineageState
  }

private structure LockManifest where
  release : String
  status : String
  identityCount : Nat

private structure LockIdentity where
  recorded : String

private def validateLockManifest (j : Json) : Except String LockManifest := do
  let context := "curriculum-lock-manifest"
  requireExactKeys context j [
    "authority", "curriculum_release_ref", "identity_count", "mirror_status", "schema_version",
    "source_refs", "verified_by_trace_record"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  if (← strField context j "authority") != "project1_external_authority" then failE context "invalid-authority"
  let release ← strField context j "curriculum_release_ref"
  requireNonempty context "curriculum_release_ref" release
  let status ← strField context j "mirror_status"
  requireEnum context "mirror_status" status ["verified_snapshot", "provisional_snapshot", "stale_snapshot", "unresolved"]
  let refs ← strArrayField context j "source_refs"
  requireSortedUnique context "source_refs" refs
  requireNonempty context "verified_by_trace_record" (← strField context j "verified_by_trace_record")
  return { release := release, status := status, identityCount := (← natField context j "identity_count") }

private def validateLockIdentity (j : Json) : Except String LockIdentity := do
  let context := "curriculum-lock-identity"
  requireExactKeys context j [
    "candidate_ref_as_recorded", "candidate_ref_current_resolved", "record_status", "resolution_path",
    "resolution_state", "schema_version", "treatment_scopes"
  ]
  if (← natField context j "schema_version") != 1 then failE context "unsupported-schema-version"
  let recorded ← strField context j "candidate_ref_as_recorded"
  requireNonempty context "candidate_ref_as_recorded" recorded
  requireNonempty context "candidate_ref_current_resolved" (← strField context j "candidate_ref_current_resolved")
  requireEnum context "resolution_state" (← strField context j "resolution_state")
    ["resolved_exact", "resolved_lineage", "needs_scope_review", "ambiguous", "stale", "unresolved"]
  requireUnique context "resolution_path" (← strArrayField context j "resolution_path")
  requireSortedUnique context "treatment_scopes" (← strArrayField context j "treatment_scopes")
  requireEnum context "record_status" (← strField context j "record_status") ["current", "historical", "unresolved"]
  return { recorded := recorded }

private def findFart? (farts : List FartSummary) (id : String) : Option FartSummary :=
  farts.find? fun f => f.id == id

private def findFloc? (flocs : List FlocSummary) (id : String) : Option FlocSummary :=
  flocs.find? fun f => f.id == id

private def findFlink? (links : List FlinkSummary) (id : String) : Option FlinkSummary :=
  links.find? fun f => f.id == id

private def reservationNumbers (idPrefix context : String) (reservations : List String) : Except String (List Nat) := do
  let mut result := []
  for rid in reservations do
    if rid.startsWith idPrefix then
      result := (← idNumber context idPrefix rid) :: result
  return result

private def requireDenseIssued (context : String) (nextId : Nat) (issued : List Nat) : Except String Unit := do
  let expected := (List.range (nextId - 1)).map (· + 1)
  for n in expected do
    if !issued.contains n then
      failE context s!"silent-unissued-hole:{n}"

private def validateAllocationOrder
    (family idPrefix : String) (nextId : Nat) (records : Array LocatedJson) : Except String Unit := do
  let mut lastId : Option String := none
  for located in records do
    let id ← strField s!"allocation.{family}" located.value "id"
    let n ← idNumber s!"allocation.{family}" idPrefix id
    if n >= nextId then
      failE "allocation" s!"issued-id-not-below-next:{id}:next={nextId}"
    match lastId with
    | some previous =>
        if previous == id then
          failE "registry" s!"duplicate-id:{id}"
        else if located.path == records[0]!.path && !(decide (previous < id)) then
          failE "allocation" s!"noncanonical-record-order:{located.path}:{previous}:{id}"
    | none => .ok ()
    lastId := some id

private def validateReservationBounds (manifest : RegistryManifest) : Except String Unit := do
  for rid in manifest.reservations do
    if rid.startsWith "FART-P2-" then
      if (← idNumber "registry.reservation" "FART-P2-" rid) >= manifest.nextFart then
        failE "allocation" s!"reserved-id-not-below-next:{rid}:next={manifest.nextFart}"
    else if rid.startsWith "FLOC-P2-" then
      if (← idNumber "registry.reservation" "FLOC-P2-" rid) >= manifest.nextFloc then
        failE "allocation" s!"reserved-id-not-below-next:{rid}:next={manifest.nextFloc}"
    else if rid.startsWith "FLINK-P2-" then
      if (← idNumber "registry.reservation" "FLINK-P2-" rid) >= manifest.nextFlink then
        failE "allocation" s!"reserved-id-not-below-next:{rid}:next={manifest.nextFlink}"

private def validateCrossReferences
    (manifest : RegistryManifest)
    (farts : List FartSummary) (flocs : List FlocSummary) (links : List FlinkSummary)
    (lock : LockManifest) (lockIds : List LockIdentity) : Except String Unit := do
  if manifest.countFart != farts.length then failE "registry" "record-count-mismatch:fart"
  if manifest.countFloc != flocs.length then failE "registry" "record-count-mismatch:floc"
  if manifest.countFlink != links.length then failE "registry" "record-count-mismatch:flink"
  if lock.identityCount != lockIds.length then failE "curriculum-lock" "identity-count-mismatch"

  if let some id := firstDuplicate (farts.map (·.id)) then failE "registry" s!"duplicate-id:{id}"
  if let some id := firstDuplicate (flocs.map (·.id)) then failE "registry" s!"duplicate-id:{id}"
  if let some id := firstDuplicate (links.map (·.id)) then failE "registry" s!"duplicate-id:{id}"
  if let some id := firstDuplicate manifest.reservations then failE "registry" s!"duplicate-reservation:{id}"

  let reservedFart ← reservationNumbers "FART-P2-" "registry.reservations" manifest.reservations
  let reservedFloc ← reservationNumbers "FLOC-P2-" "registry.reservations" manifest.reservations
  let reservedFlink ← reservationNumbers "FLINK-P2-" "registry.reservations" manifest.reservations
  requireDenseIssued "registry.fart" manifest.nextFart (farts.map (·.number) ++ reservedFart)
  requireDenseIssued "registry.floc" manifest.nextFloc (flocs.map (·.number) ++ reservedFloc)
  requireDenseIssued "registry.flink" manifest.nextFlink (links.map (·.number) ++ reservedFlink)

  for loc in flocs do
    if (findFart? farts loc.fart).isNone then failE "registry" s!"dangling-floc-fart:{loc.id}:{loc.fart}"
  for link in links do
    if (findFart? farts link.fart).isNone then failE "registry" s!"dangling-flink-fart:{link.id}:{link.fart}"
    if !(lockIds.any fun x => x.recorded == link.candidateRecorded) then
      let explicitNonSuccess := link.linkStatus == "needs_review" || link.linkStatus == "unresolved" ||
        link.lineageState == "needs_scope_review" || link.lineageState == "ambiguous" ||
        link.lineageState == "stale" || link.lineageState == "unresolved"
      if !explicitNonSuccess then
        failE "curriculum-lock" s!"missing-linked-identity:{link.id}:{link.candidateRecorded}"

  for fart in farts do
    for locId in fart.currentLocators do
      match findFloc? flocs locId with
      | none => failE "registry" s!"dangling-fart-current-locator:{fart.id}:{locId}"
      | some loc =>
          if loc.fart != fart.id then failE "registry" s!"locator-backref-mismatch:{fart.id}:{locId}"
          if loc.locatorStatus != "current" then failE "registry" s!"noncurrent-locator-in-current-set:{fart.id}:{locId}"
    for linkId in fart.curriculumLinks do
      match findFlink? links linkId with
      | none => failE "registry" s!"dangling-fart-curriculum-link:{fart.id}:{linkId}"
      | some link => if link.fart != fart.id then failE "registry" s!"link-backref-mismatch:{fart.id}:{linkId}"

  for loc in flocs do
    if loc.locatorStatus == "current" then
      match findFart? farts loc.fart with
      | none => .ok ()
      | some fart => if !fart.currentLocators.contains loc.id then failE "registry" s!"current-locator-missing-from-fart:{loc.id}:{fart.id}"

public def validateRegistryRoot (root : FilePath := ".") : IO Unit := do
  let manifestJson ← readCanonicalJson (root / "metadata" / "formal-artifacts" / "registry.json")
  let manifest ← IO.ofExcept <| validateManifest manifestJson
  let fartRaw ← readFamily root "fart"
  let flocRaw ← readFamily root "floc"
  let flinkRaw ← readFamily root "flink"

  IO.ofExcept <| validateAllocationOrder "fart" "FART-P2-" manifest.nextFart fartRaw
  IO.ofExcept <| validateAllocationOrder "floc" "FLOC-P2-" manifest.nextFloc flocRaw
  IO.ofExcept <| validateAllocationOrder "flink" "FLINK-P2-" manifest.nextFlink flinkRaw
  IO.ofExcept <| validateReservationBounds manifest

  let mut farts := []
  for record in fartRaw do
    farts := (← IO.ofExcept <| validateFart record) :: farts
  farts := farts.reverse

  let mut flocs := []
  for record in flocRaw do
    let summary ← IO.ofExcept <| validateFloc record
    if summary.locatorStatus == "current" && summary.sourceKind == "project_repository" then
      if !(← (root / summary.filePath).pathExists) then
        failIO s!"traceability:error:floc:missing-current-project-file:{summary.id}:{summary.filePath}"
    flocs := summary :: flocs
  flocs := flocs.reverse

  let mut links := []
  for record in flinkRaw do
    links := (← IO.ofExcept <| validateFlink record) :: links
  links := links.reverse

  let lockJson ← readCanonicalJson (root / "metadata" / "curriculum-lock" / "manifest.json")
  let lock ← IO.ofExcept <| validateLockManifest lockJson
  let lockRaw ← readCanonicalJsonl (root / "metadata" / "curriculum-lock" / "linked-identities.jsonl")
  let mut lockIds := []
  for record in lockRaw do
    lockIds := (← IO.ofExcept <| validateLockIdentity record) :: lockIds
  lockIds := lockIds.reverse

  IO.ofExcept <| validateCrossReferences manifest farts flocs links lock lockIds
  IO.println s!"traceability:allocation:pass:next-fart={manifest.nextFart};next-floc={manifest.nextFloc};next-flink={manifest.nextFlink}"
  IO.println s!"traceability:validate:pass:fart={farts.length};floc={flocs.length};flink={links.length};curriculum-identities={lockIds.length};curriculum-lock-status={lock.status};curriculum-release={lock.release}"

end FormalMathTraceability
