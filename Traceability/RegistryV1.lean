/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Warning-free v1 validator for the authored M2.8 FART/FLOC/FLINK registry and the minimal
non-authoritative curriculum lock.
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
    if !allowed.contains key then failE context s!"unknown-field:{key}"
  for key in allowed do
    if !keys.contains key then failE context s!"missing-field:{key}"

private def field (context : String) (j : Json) (key : String) : Except String Json :=
  (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def strField (context : String) (j : Json) (key : String) : Except String String := do
  (← field context j key).getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def natField (context : String) (j : Json) (key : String) : Except String Nat := do
  (← field context j key).getNat? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

private def objField (context : String) (j : Json) (key : String) : Except String Json := do
  let value ← field context j key
  let _ ← value.getObj? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  return value

private def strArrayField (context : String) (j : Json) (key : String) : Except String (List String) := do
  let values ← (← field context j key).getArr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  let mut out := []
  for value in values do
    out := (← value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}") :: out
  return out.reverse

private def requireNonempty (context key value : String) : Except String Unit :=
  if value.isEmpty then failE context s!"empty-field:{key}" else .ok ()

private def requireEnum (context key value : String) (allowed : List String) : Except String Unit :=
  if allowed.contains value then .ok () else failE context s!"invalid-enum:{key}:{value}"

private def firstDuplicate : List String → Option String
  | [] => none
  | x :: xs => if xs.contains x then some x else firstDuplicate xs

private def strictlySorted : List String → Bool
  | a :: b :: rest => decide (a < b) && strictlySorted (b :: rest)
  | _ => true

private def requireSortedUnique (context key : String) (values : List String) : Except String Unit := do
  match firstDuplicate values with
  | some value => failE context s!"duplicate-set-value:{key}:{value}"
  | none => pure ()
  if !strictlySorted values then failE context s!"noncanonical-set-order:{key}"

private def idNumber (context idPrefix value : String) : Except String Nat := do
  if !value.startsWith idPrefix then failE context s!"invalid-id:{value}"
  let suffix := String.ofList ((value.toList).drop idPrefix.length)
  if suffix.length != 6 then failE context s!"invalid-id:{value}"
  match suffix.toNat? with
  | none => failE context s!"invalid-id:{value}"
  | some 0 => failE context s!"invalid-id:{value}"
  | some n => return n

private def pad6 (n : Nat) : String :=
  let s := toString n
  String.ofList (List.replicate (6 - s.length) '0') ++ s

private def expectedShard (n : Nat) : String :=
  let first := ((n - 1) / 1000) * 1000 + 1
  s!"{pad6 first}-{pad6 (first + 999)}.jsonl"

private def readCanonicalJson (path : FilePath) : IO Json := do
  if !(← path.pathExists) then failIO s!"traceability:error:{path}:missing-file"
  let text ← IO.FS.readFile path
  let json ← IO.ofExcept <| (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"
  if text != Json.compress json ++ "\n" then failIO s!"traceability:error:{path}:noncanonical-json"
  return json

private def readCanonicalJsonl (path : FilePath) : IO (List Json) := do
  let text ← IO.FS.readFile path
  if text.isEmpty then return []
  if !text.endsWith "\n" then failIO s!"traceability:error:{path}:missing-final-newline"
  let lines := ((text.splitOn "\n").reverse.drop 1).reverse
  let mut out := []
  let mut lineNo := 0
  for line in lines do
    lineNo := lineNo + 1
    if line.isEmpty then failIO s!"traceability:error:{path}:{lineNo}:blank-jsonl-line"
    let json ← IO.ofExcept <| (Json.parse line).mapError fun e => s!"traceability:error:{path}:{lineNo}:json-parse:{e}"
    if Json.compress json != line then failIO s!"traceability:error:{path}:{lineNo}:noncanonical-jsonl"
    out := json :: out
  return out.reverse

private structure LocatedJson where
  path : FilePath
  value : Json

private def readFamily (root : FilePath) (family : String) : IO (List LocatedJson) := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then return []
  if !(← dir.isDir) then failIO s!"traceability:error:{dir}:not-directory"
  let mut out := []
  for path in (← dir.walkDir) do
    if path.extension == some "jsonl" then
      for value in (← readCanonicalJsonl path) do
        out := { path := path, value := value } :: out
  return out.reverse

private structure Manifest where
  nextFart : Nat
  nextFloc : Nat
  nextFlink : Nat
  countFart : Nat
  countFloc : Nat
  countFlink : Nat
  reservations : List String

private def validateManifest (j : Json) : Except String Manifest := do
  let c := "registry-manifest"
  requireExactKeys c j ["default_curriculum_baseline_ref", "dependency_baseline_ref", "format", "lean_toolchain_ref", "next_ids", "protocol_ref", "record_counts", "registry_semantics_ref", "registry_status", "reservations", "schema_version", "shard_size"]
  if (← natField c j "schema_version") != 1 then failE c "unsupported-schema-version"
  if (← strField c j "format") != "formal-artifacts-jsonl-v1" then failE c "invalid-format"
  if (← natField c j "shard_size") != 1000 then failE c "invalid-shard-size"
  if (← strField c j "registry_semantics_ref") != "P2-TRACE-M2.8-REGISTRY-v1" then failE c "registry-semantics-ref-mismatch"
  if (← strField c j "protocol_ref") != "P2-TRACE-M2.8-PROTOCOL-v1" then failE c "protocol-ref-mismatch"
  requireNonempty c "default_curriculum_baseline_ref" (← strField c j "default_curriculum_baseline_ref")
  requireNonempty c "dependency_baseline_ref" (← strField c j "dependency_baseline_ref")
  requireNonempty c "lean_toolchain_ref" (← strField c j "lean_toolchain_ref")
  requireNonempty c "registry_status" (← strField c j "registry_status")
  let nextIds ← objField c j "next_ids"
  requireExactKeys "registry-manifest.next_ids" nextIds ["fart", "flink", "floc"]
  let nextFart ← idNumber c "FART-P2-" (← strField c nextIds "fart")
  let nextFloc ← idNumber c "FLOC-P2-" (← strField c nextIds "floc")
  let nextFlink ← idNumber c "FLINK-P2-" (← strField c nextIds "flink")
  let counts ← objField c j "record_counts"
  requireExactKeys "registry-manifest.record_counts" counts ["fart", "flink", "floc"]
  let countFart ← natField c counts "fart"
  let countFloc ← natField c counts "floc"
  let countFlink ← natField c counts "flink"
  let reservationValues ← (← field c j "reservations").getArr? |>.mapError fun e => s!"traceability:error:{c}:reservations:{e}"
  let mut reservations := []
  for value in reservationValues do
    requireExactKeys "registry-manifest.reservation" value ["id", "reason", "state"]
    let rid ← strField c value "id"
    let state ← strField c value "state"
    requireEnum c "state" state ["reserved_unissued", "retired_identity"]
    requireNonempty c "reason" (← strField c value "reason")
    if !(rid.startsWith "FART-P2-" || rid.startsWith "FLOC-P2-" || rid.startsWith "FLINK-P2-") then failE c s!"invalid-id:{rid}"
    reservations := rid :: reservations
  return { nextFart, nextFloc, nextFlink, countFart, countFloc, countFlink, reservations := reservations.reverse }

private structure Fart where
  id : String
  number : Nat
  locs : List String
  links : List String

private structure Floc where
  id : String
  number : Nat
  fart : String
  status : String
  sourceKind : String
  filePath : String

private structure Flink where
  id : String
  number : Nat
  fart : String
  candidate : String
  linkStatus : String
  lineageState : String

private def validateProvenance (j : Json) : Except String Unit := do
  let c := "fart.source_provenance"
  requireExactKeys c j ["proof_or_implementation_provenance_notes", "provenance_kind", "source_refs", "statement_provenance_notes"]
  requireEnum c "provenance_kind" (← strField c j "provenance_kind") ["original_project", "adapted_from_dependency", "direct_dependency_representation", "mixed", "other"]
  requireSortedUnique c "source_refs" (← strArrayField c j "source_refs")
  let _ ← strField c j "statement_provenance_notes"
  let _ ← strField c j "proof_or_implementation_provenance_notes"

private def validateFart (located : LocatedJson) : Except String Fart := do
  let j := located.value
  let c := "fart"
  let keys ← objKeys j
  if keys.contains "formalized" then failE c "forbidden-conflated-field:formalized"
  requireExactKeys c j ["artifact_kind", "created_revision", "current_locator_refs", "curriculum_link_refs", "dependency_baseline_ref", "id", "lean_toolchain_ref", "quality_state", "record_status", "representation_state", "schema_version", "source_provenance", "superseded_by", "supersedes", "title_or_summary", "verification_state"]
  if (← natField c j "schema_version") != 1 then failE c "unsupported-schema-version"
  let id ← strField c j "id"
  let number ← idNumber c "FART-P2-" id
  if located.path.fileName.getD "" != expectedShard number then failE c s!"wrong-shard:{id}"
  requireEnum c "artifact_kind" (← strField c j "artifact_kind") ["definition", "theorem", "theorem_family", "structure_api", "model", "encoding", "example", "exercise_solution", "infrastructure", "other"]
  requireEnum c "representation_state" (← strField c j "representation_state") ["unknown", "not_assessed", "planned", "partial", "represented"]
  requireEnum c "verification_state" (← strField c j "verification_state") ["not_checked", "elaborates", "kernel_checked", "regression_verified"]
  requireEnum c "quality_state" (← strField c j "quality_state") ["not_assessed", "draft", "reviewed", "approved"]
  requireEnum c "record_status" (← strField c j "record_status") ["active", "historical", "superseded", "retired", "unresolved"]
  requireNonempty c "title_or_summary" (← strField c j "title_or_summary")
  requireNonempty c "lean_toolchain_ref" (← strField c j "lean_toolchain_ref")
  requireNonempty c "dependency_baseline_ref" (← strField c j "dependency_baseline_ref")
  requireNonempty c "created_revision" (← strField c j "created_revision")
  let locs ← strArrayField c j "current_locator_refs"
  let links ← strArrayField c j "curriculum_link_refs"
  let supersedes ← strArrayField c j "supersedes"
  let supersededBy ← strArrayField c j "superseded_by"
  requireSortedUnique c "current_locator_refs" locs
  requireSortedUnique c "curriculum_link_refs" links
  requireSortedUnique c "supersedes" supersedes
  requireSortedUnique c "superseded_by" supersededBy
  for x in locs do let _ ← idNumber c "FLOC-P2-" x
  for x in links do let _ ← idNumber c "FLINK-P2-" x
  for x in supersedes do let _ ← idNumber c "FART-P2-" x
  for x in supersededBy do let _ ← idNumber c "FART-P2-" x
  validateProvenance (← objField c j "source_provenance")
  return { id, number, locs, links }

private def validateFloc (located : LocatedJson) : Except String Floc := do
  let j := located.value
  let c := "floc"
  requireExactKeys c j ["created_revision", "declaration_names", "dependency_baseline_ref", "file_path", "formal_artifact_ref", "id", "locator_status", "module_name", "observed_at", "record_status", "repository", "revision", "schema_version", "source_kind", "structural_anchors", "superseded_by_locator_refs", "supersedes_locator_refs"]
  if (← natField c j "schema_version") != 1 then failE c "unsupported-schema-version"
  let id ← strField c j "id"
  let number ← idNumber c "FLOC-P2-" id
  if located.path.fileName.getD "" != expectedShard number then failE c s!"wrong-shard:{id}"
  let fart ← strField c j "formal_artifact_ref"
  let _ ← idNumber c "FART-P2-" fart
  let sourceKind ← strField c j "source_kind"
  requireEnum c "source_kind" sourceKind ["project_repository", "dependency_repository"]
  let baseline ← strField c j "dependency_baseline_ref"
  if sourceKind == "project_repository" then
    if baseline != "not_applicable" then failE c "project-locator-dependency-baseline-must-be-not_applicable"
  else if baseline == "not_applicable" || baseline.isEmpty then failE c "dependency-locator-missing-baseline"
  requireNonempty c "repository" (← strField c j "repository")
  requireNonempty c "revision" (← strField c j "revision")
  requireNonempty c "module_name" (← strField c j "module_name")
  let filePath ← strField c j "file_path"
  requireNonempty c "file_path" filePath
  requireSortedUnique c "declaration_names" (← strArrayField c j "declaration_names")
  requireSortedUnique c "structural_anchors" (← strArrayField c j "structural_anchors")
  requireSortedUnique c "supersedes_locator_refs" (← strArrayField c j "supersedes_locator_refs")
  requireSortedUnique c "superseded_by_locator_refs" (← strArrayField c j "superseded_by_locator_refs")
  let status ← strField c j "locator_status"
  requireEnum c "locator_status" status ["current", "historical", "superseded", "unresolved"]
  requireEnum c "record_status" (← strField c j "record_status") ["active", "historical", "superseded", "retired", "unresolved"]
  requireNonempty c "observed_at" (← strField c j "observed_at")
  requireNonempty c "created_revision" (← strField c j "created_revision")
  return { id, number, fart, status, sourceKind, filePath }

private def requireNotNull (context key : String) (j : Json) : Except String Unit := do
  match ← field context j key with
  | .null => failE context s!"null-{key}"
  | _ => pure ()

private def validateFlink (located : LocatedJson) : Except String Flink := do
  let j := located.value
  let c := "flink"
  requireExactKeys c j ["assumptions_or_formulation_notes", "candidate_lineage_resolution", "candidate_ref_as_recorded", "candidate_ref_current_resolved", "coverage_claim_scope", "created_revision", "curriculum_release_ref", "formal_artifact_ref", "id", "link_confidence", "link_status", "record_status", "representation_relation", "schema_version", "treatment_scope"]
  if (← natField c j "schema_version") != 1 then failE c "unsupported-schema-version"
  let id ← strField c j "id"
  let number ← idNumber c "FLINK-P2-" id
  if located.path.fileName.getD "" != expectedShard number then failE c s!"wrong-shard:{id}"
  let fart ← strField c j "formal_artifact_ref"
  let _ ← idNumber c "FART-P2-" fart
  let candidate ← strField c j "candidate_ref_as_recorded"
  requireNonempty c "candidate_ref_as_recorded" candidate
  requireNonempty c "candidate_ref_current_resolved" (← strField c j "candidate_ref_current_resolved")
  requireNonempty c "curriculum_release_ref" (← strField c j "curriculum_release_ref")
  let lineage ← objField c j "candidate_lineage_resolution"
  requireExactKeys "flink.candidate_lineage_resolution" lineage ["resolution_context", "resolution_path", "review_ref", "state"]
  let lineageState ← strField c lineage "state"
  requireEnum c "lineage_state" lineageState ["resolved_exact", "resolved_lineage", "needs_scope_review", "ambiguous", "stale", "unresolved"]
  requireNonempty c "resolution_context" (← strField c lineage "resolution_context")
  requireNonempty c "review_ref" (← strField c lineage "review_ref")
  requireNotNull c "treatment_scope" j
  requireNotNull c "coverage_claim_scope" j
  let _ ← strField c j "assumptions_or_formulation_notes"
  requireEnum c "representation_relation" (← strField c j "representation_relation") ["represents", "partially_represents", "example_of", "exercise_for", "implementation_support_for", "model_for", "other"]
  requireEnum c "link_confidence" (← strField c j "link_confidence") ["established", "reviewed_provisional", "provisional", "unresolved"]
  let linkStatus ← strField c j "link_status"
  requireEnum c "link_status" linkStatus ["current", "historical", "superseded", "needs_review", "unresolved"]
  requireEnum c "record_status" (← strField c j "record_status") ["active", "historical", "superseded", "retired", "unresolved"]
  requireNonempty c "created_revision" (← strField c j "created_revision")
  return { id, number, fart, candidate, linkStatus, lineageState }

private structure Lock where
  release : String
  status : String
  count : Nat
  candidates : List String

private def validateLock (root : FilePath) : IO Lock := do
  let j ← readCanonicalJson (root / "metadata" / "curriculum-lock" / "manifest.json")
  let c := "curriculum-lock-manifest"
  let parsed ← IO.ofExcept <| do
    requireExactKeys c j ["authority", "curriculum_release_ref", "identity_count", "mirror_status", "schema_version", "source_refs", "verified_by_trace_record"]
    if (← natField c j "schema_version") != 1 then failE c "unsupported-schema-version"
    if (← strField c j "authority") != "project1_external_authority" then failE c "invalid-authority"
    let release ← strField c j "curriculum_release_ref"
    let status ← strField c j "mirror_status"
    requireEnum c "mirror_status" status ["verified_snapshot", "provisional_snapshot", "stale_snapshot", "unresolved"]
    requireSortedUnique c "source_refs" (← strArrayField c j "source_refs")
    return (release, status, (← natField c j "identity_count"))
  let identities ← readCanonicalJsonl (root / "metadata" / "curriculum-lock" / "linked-identities.jsonl")
  let mut candidates := []
  for item in identities do
    let candidate ← IO.ofExcept <| do
      let c := "curriculum-lock-identity"
      requireExactKeys c item ["candidate_ref_as_recorded", "candidate_ref_current_resolved", "record_status", "resolution_path", "resolution_state", "schema_version", "treatment_scopes"]
      if (← natField c item "schema_version") != 1 then failE c "unsupported-schema-version"
      requireEnum c "resolution_state" (← strField c item "resolution_state") ["resolved_exact", "resolved_lineage", "needs_scope_review", "ambiguous", "stale", "unresolved"]
      requireSortedUnique c "treatment_scopes" (← strArrayField c item "treatment_scopes")
      return (← strField c item "candidate_ref_as_recorded")
    candidates := candidate :: candidates
  if parsed.2.2 != candidates.length then failIO "traceability:error:curriculum-lock:identity-count-mismatch"
  return { release := parsed.1, status := parsed.2.1, count := parsed.2.2, candidates := candidates.reverse }

private def numbersFor (idPrefix : String) (ids : List String) : Except String (List Nat) := do
  let mut out := []
  for id in ids do
    if id.startsWith idPrefix then out := (← idNumber "registry.reservations" idPrefix id) :: out
  return out

private def requireDense (context : String) (nextId : Nat) (issued : List Nat) : Except String Unit := do
  for n in (List.range (nextId - 1)).map (· + 1) do
    if !issued.contains n then failE context s!"silent-unissued-hole:{n}"

public def validateRegistryV1Root (root : FilePath := ".") : IO Unit := do
  let manifest ← IO.ofExcept <| validateManifest (← readCanonicalJson (root / "metadata" / "formal-artifacts" / "registry.json"))
  let fartRaw ← readFamily root "fart"
  let flocRaw ← readFamily root "floc"
  let flinkRaw ← readFamily root "flink"
  let mut farts := []
  for item in fartRaw do
    let x ← IO.ofExcept <| validateFart item
    if x.number >= manifest.nextFart then failIO s!"traceability:error:allocation:issued-id-not-below-next:{x.id}:next={manifest.nextFart}"
    farts := x :: farts
  farts := farts.reverse
  let mut flocs := []
  for item in flocRaw do
    let x ← IO.ofExcept <| validateFloc item
    if x.number >= manifest.nextFloc then failIO s!"traceability:error:allocation:issued-id-not-below-next:{x.id}:next={manifest.nextFloc}"
    if x.status == "current" && x.sourceKind == "project_repository" && !(← (root / x.filePath).pathExists) then
      failIO s!"traceability:error:floc:missing-current-project-file:{x.id}:{x.filePath}"
    flocs := x :: flocs
  flocs := flocs.reverse
  let mut links := []
  for item in flinkRaw do
    let x ← IO.ofExcept <| validateFlink item
    if x.number >= manifest.nextFlink then failIO s!"traceability:error:allocation:issued-id-not-below-next:{x.id}:next={manifest.nextFlink}"
    links := x :: links
  links := links.reverse
  if manifest.countFart != farts.length then failIO "traceability:error:registry:record-count-mismatch:fart"
  if manifest.countFloc != flocs.length then failIO "traceability:error:registry:record-count-mismatch:floc"
  if manifest.countFlink != links.length then failIO "traceability:error:registry:record-count-mismatch:flink"
  if let some id := firstDuplicate (farts.map (·.id)) then failIO s!"traceability:error:registry:duplicate-id:{id}"
  if let some id := firstDuplicate (flocs.map (·.id)) then failIO s!"traceability:error:registry:duplicate-id:{id}"
  if let some id := firstDuplicate (links.map (·.id)) then failIO s!"traceability:error:registry:duplicate-id:{id}"
  let rf ← IO.ofExcept <| numbersFor "FART-P2-" manifest.reservations
  let rl ← IO.ofExcept <| numbersFor "FLOC-P2-" manifest.reservations
  let rk ← IO.ofExcept <| numbersFor "FLINK-P2-" manifest.reservations
  IO.ofExcept <| requireDense "registry.fart" manifest.nextFart (farts.map (·.number) ++ rf)
  IO.ofExcept <| requireDense "registry.floc" manifest.nextFloc (flocs.map (·.number) ++ rl)
  IO.ofExcept <| requireDense "registry.flink" manifest.nextFlink (links.map (·.number) ++ rk)
  let lock ← validateLock root
  for loc in flocs do
    if !(farts.any (fun f => f.id == loc.fart)) then failIO s!"traceability:error:registry:dangling-floc-fart:{loc.id}:{loc.fart}"
  for link in links do
    if !(farts.any (fun f => f.id == link.fart)) then failIO s!"traceability:error:registry:dangling-flink-fart:{link.id}:{link.fart}"
    if !lock.candidates.contains link.candidate then
      let nonSuccess := link.linkStatus == "needs_review" || link.linkStatus == "unresolved" || link.lineageState == "needs_scope_review" || link.lineageState == "ambiguous" || link.lineageState == "stale" || link.lineageState == "unresolved"
      if !nonSuccess then failIO s!"traceability:error:curriculum-lock:missing-linked-identity:{link.id}:{link.candidate}"
  for fart in farts do
    for locId in fart.locs do
      match flocs.find? (fun x => x.id == locId) with
      | none => failIO s!"traceability:error:registry:dangling-fart-current-locator:{fart.id}:{locId}"
      | some loc =>
          if loc.fart != fart.id then failIO s!"traceability:error:registry:locator-backref-mismatch:{fart.id}:{locId}"
          if loc.status != "current" then failIO s!"traceability:error:registry:noncurrent-locator-in-current-set:{fart.id}:{locId}"
    for linkId in fart.links do
      match links.find? (fun x => x.id == linkId) with
      | none => failIO s!"traceability:error:registry:dangling-fart-curriculum-link:{fart.id}:{linkId}"
      | some link => if link.fart != fart.id then failIO s!"traceability:error:registry:link-backref-mismatch:{fart.id}:{linkId}"
  for loc in flocs do
    if loc.status == "current" then
      match farts.find? (fun f => f.id == loc.fart) with
      | some fart => if !fart.locs.contains loc.id then failIO s!"traceability:error:registry:current-locator-missing-from-fart:{loc.id}:{fart.id}"
      | none => pure ()
  IO.println s!"traceability:allocation:pass:next-fart={manifest.nextFart};next-floc={manifest.nextFloc};next-flink={manifest.nextFlink}"
  IO.println s!"traceability:validate:pass:fart={farts.length};floc={flocs.length};flink={links.length};curriculum-identities={lock.count};curriculum-lock-status={lock.status};curriculum-release={lock.release}"

end FormalMathTraceability
