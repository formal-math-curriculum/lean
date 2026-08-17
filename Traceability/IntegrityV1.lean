/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Traceability.Views

/-!
Cross-record authority, lifecycle, scope, and baseline integrity for the M2.8 v1 traceability
registry.

`RegistryV1` owns physical/schema/cursor validation. This module deliberately performs the stronger
semantic reconciliation that requires looking across FART/FLOC/FLINK records and the curriculum
lock. Project-1 lock state is authoritative for candidate lineage; a FLINK may not contradict it.
-/

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def requiredString (context : String) (j : Lean.Json) (key : String) : IO String := do
  let value ← IO.ofExcept <| stringField context j key
  if value.isEmpty then failIO s!"traceability:error:{context}:empty-{key}"
  return value

private def requiredStrings (context : String) (j : Lean.Json) (key : String) : IO (List String) := do
  let values ← IO.ofExcept <| stringArrayField context j key
  for value in values do
    if value.isEmpty then failIO s!"traceability:error:{context}:empty-{key}-item"
  return values

private def firstDuplicateString : List String → Option String
  | [] => none
  | x :: xs => if xs.contains x then some x else firstDuplicateString xs

private def isResolutionState (state : String) : Bool :=
  ["resolved_exact", "resolved_lineage", "needs_scope_review", "ambiguous", "stale", "unresolved"].contains state

private def isNonSuccessResolution (state : String) : Bool :=
  ["needs_scope_review", "ambiguous", "stale", "unresolved"].contains state

private structure LockIdentity where
  raw : Lean.Json
  recorded : String
  current : String
  recordStatus : String
  state : String
  path : List String
  treatments : List String

private def parseLockIdentity (j : Lean.Json) : IO LockIdentity := do
  let c := "curriculum-lock-identity"
  let schema ← IO.ofExcept <| jsonField c j "schema_version"
  let schemaNat ← IO.ofExcept <| schema.getNat? |>.mapError fun e => s!"traceability:error:{c}:schema_version:{e}"
  if schemaNat != 1 then failIO s!"traceability:error:{c}:unsupported-schema-version:{schemaNat}"
  let recorded ← requiredString c j "candidate_ref_as_recorded"
  let current ← requiredString c j "candidate_ref_current_resolved"
  let recordStatus ← requiredString c j "record_status"
  if !["current", "historical", "stale", "unresolved"].contains recordStatus then
    failIO s!"traceability:error:{c}:invalid-record-status:{recordStatus}"
  let state ← requiredString c j "resolution_state"
  if !isResolutionState state then failIO s!"traceability:error:{c}:invalid-resolution-state:{state}"
  let path ← requiredStrings c j "resolution_path"
  if path.isEmpty then failIO s!"traceability:error:{c}:empty-resolution-path:{recorded}"
  match path with
  | first :: _ =>
      if first != recorded then failIO s!"traceability:error:{c}:path-does-not-start-recorded:{recorded}:{first}"
  | [] => unreachable!
  match path.reverse with
  | last :: _ =>
      if last != current then failIO s!"traceability:error:{c}:path-does-not-end-current:{recorded}:{current}:{last}"
  | [] => unreachable!
  if state == "resolved_exact" then
    if recorded != current || path.length != 1 then
      failIO s!"traceability:error:{c}:invalid-exact-resolution:{recorded}:{current}"
  if state == "resolved_lineage" && path.length < 2 then
    failIO s!"traceability:error:{c}:lineage-path-too-short:{recorded}"
  if (state == "resolved_exact" || state == "resolved_lineage") && recordStatus != "current" then
    failIO s!"traceability:error:{c}:resolved-identity-not-current:{recorded}:{recordStatus}"
  if isNonSuccessResolution state && recordStatus == "current" then
    failIO s!"traceability:error:{c}:non-success-identity-marked-current:{recorded}:{state}"
  let treatments ← requiredStrings c j "treatment_scopes"
  if treatments.isEmpty then failIO s!"traceability:error:{c}:empty-treatment-scopes:{recorded}"
  if let some duplicate := firstDuplicateString treatments then
    failIO s!"traceability:error:{c}:duplicate-treatment-scope:{recorded}:{duplicate}"
  return { raw := j, recorded, current, recordStatus, state, path, treatments }

private def findLockIdentity? (identities : List LockIdentity) (recorded : String) : Option LockIdentity :=
  identities.find? (fun identity => identity.recorded == recorded)

private def findJsonById? (records : List Lean.Json) (id : String) : IO (Option Lean.Json) := do
  for record in records do
    if (← requiredString "record" record "id") == id then return some record
  return none

private def validateFartBaselines (data : RegistryData) : IO Unit := do
  let dependencyBaseline ← requiredString "registry-manifest" data.registryManifest "dependency_baseline_ref"
  let leanBaseline ← requiredString "registry-manifest" data.registryManifest "lean_toolchain_ref"
  for fart in data.farts do
    let id ← requiredString "fart" fart "id"
    let dep ← requiredString "fart" fart "dependency_baseline_ref"
    let lean ← requiredString "fart" fart "lean_toolchain_ref"
    if dep != dependencyBaseline then
      failIO s!"traceability:error:integrity:fart-dependency-baseline-mismatch:{id}:{dep}:{dependencyBaseline}"
    if lean != leanBaseline then
      failIO s!"traceability:error:integrity:fart-lean-baseline-mismatch:{id}:{lean}:{leanBaseline}"

private def validateFartLinkBackrefs (data : RegistryData) : IO Unit := do
  for link in data.flinks do
    let linkId ← requiredString "flink" link "id"
    let fartId ← requiredString "flink" link "formal_artifact_ref"
    let some fart ← findJsonById? data.farts fartId
      | failIO s!"traceability:error:integrity:dangling-flink-fart:{linkId}:{fartId}"
    let refs ← requiredStrings "fart" fart "curriculum_link_refs"
    if !refs.contains linkId then
      failIO s!"traceability:error:integrity:flink-missing-from-fart:{linkId}:{fartId}"

private def validateFartLocatorBackrefs (data : RegistryData) : IO Unit := do
  for fart in data.farts do
    let fartId ← requiredString "fart" fart "id"
    let locatorRefs ← requiredStrings "fart" fart "current_locator_refs"
    for locatorId in locatorRefs do
      let some floc ← findJsonById? data.flocs locatorId
        | failIO s!"traceability:error:integrity:dangling-fart-current-locator:{fartId}:{locatorId}"
      let owner ← requiredString "floc" floc "formal_artifact_ref"
      if owner != fartId then
        failIO s!"traceability:error:integrity:fart-current-locator-crosses-artifact:{fartId}:{locatorId}:{owner}"
      let status ← requiredString "floc" floc "locator_status"
      if status != "current" then
        failIO s!"traceability:error:integrity:current-locator-ref-not-current:{fartId}:{locatorId}:{status}"
  for floc in data.flocs do
    let locatorId ← requiredString "floc" floc "id"
    let fartId ← requiredString "floc" floc "formal_artifact_ref"
    let status ← requiredString "floc" floc "locator_status"
    let some fart ← findJsonById? data.farts fartId
      | failIO s!"traceability:error:integrity:dangling-floc-fart:{locatorId}:{fartId}"
    let locatorRefs ← requiredStrings "fart" fart "current_locator_refs"
    if status == "current" && !locatorRefs.contains locatorId then
      failIO s!"traceability:error:integrity:current-floc-missing-from-fart:{locatorId}:{fartId}"
    if status != "current" && locatorRefs.contains locatorId then
      failIO s!"traceability:error:integrity:noncurrent-floc-listed-current:{locatorId}:{fartId}:{status}"

private def validateFartLifecycle (data : RegistryData) : IO Unit := do
  for fart in data.farts do
    let id ← requiredString "fart" fart "id"
    let supersedes ← requiredStrings "fart" fart "supersedes"
    let supersededBy ← requiredStrings "fart" fart "superseded_by"
    for targetId in supersedes do
      if targetId == id then failIO s!"traceability:error:integrity:self-fart-supersession:{id}"
      let some target ← findJsonById? data.farts targetId
        | failIO s!"traceability:error:integrity:dangling-fart-supersedes:{id}:{targetId}"
      let reverse ← requiredStrings "fart" target "superseded_by"
      if !reverse.contains id then failIO s!"traceability:error:integrity:asymmetric-fart-supersession:{id}:{targetId}"
    for targetId in supersededBy do
      if targetId == id then failIO s!"traceability:error:integrity:self-fart-supersession:{id}"
      let some target ← findJsonById? data.farts targetId
        | failIO s!"traceability:error:integrity:dangling-fart-superseded-by:{id}:{targetId}"
      let reverse ← requiredStrings "fart" target "supersedes"
      if !reverse.contains id then failIO s!"traceability:error:integrity:asymmetric-fart-superseded-by:{id}:{targetId}"

private def validateFlocLifecycle (data : RegistryData) : IO Unit := do
  for floc in data.flocs do
    let id ← requiredString "floc" floc "id"
    let fartId ← requiredString "floc" floc "formal_artifact_ref"
    let locatorStatus ← requiredString "floc" floc "locator_status"
    let recordStatus ← requiredString "floc" floc "record_status"
    if locatorStatus == "current" && recordStatus != "active" then
      failIO s!"traceability:error:integrity:current-floc-not-active:{id}:{recordStatus}"
    if locatorStatus == "historical" && recordStatus != "historical" then
      failIO s!"traceability:error:integrity:historical-floc-status-mismatch:{id}:{recordStatus}"
    if locatorStatus == "unresolved" && recordStatus != "unresolved" then
      failIO s!"traceability:error:integrity:unresolved-floc-status-mismatch:{id}:{recordStatus}"
    let supersedes ← requiredStrings "floc" floc "supersedes_locator_refs"
    let supersededBy ← requiredStrings "floc" floc "superseded_by_locator_refs"
    for targetId in supersedes do
      if targetId == id then failIO s!"traceability:error:integrity:self-floc-supersession:{id}"
      let some target ← findJsonById? data.flocs targetId
        | failIO s!"traceability:error:integrity:dangling-floc-supersedes:{id}:{targetId}"
      if (← requiredString "floc" target "formal_artifact_ref") != fartId then
        failIO s!"traceability:error:integrity:floc-supersession-crosses-fart:{id}:{targetId}"
      let reverse ← requiredStrings "floc" target "superseded_by_locator_refs"
      if !reverse.contains id then failIO s!"traceability:error:integrity:asymmetric-floc-supersession:{id}:{targetId}"
    for targetId in supersededBy do
      if targetId == id then failIO s!"traceability:error:integrity:self-floc-supersession:{id}"
      let some target ← findJsonById? data.flocs targetId
        | failIO s!"traceability:error:integrity:dangling-floc-superseded-by:{id}:{targetId}"
      if (← requiredString "floc" target "formal_artifact_ref") != fartId then
        failIO s!"traceability:error:integrity:floc-supersession-crosses-fart:{id}:{targetId}"
      let reverse ← requiredStrings "floc" target "supersedes_locator_refs"
      if !reverse.contains id then failIO s!"traceability:error:integrity:asymmetric-floc-superseded-by:{id}:{targetId}"

private def validateCurriculumAuthority (data : RegistryData) : IO Unit := do
  let lockRelease ← requiredString "curriculum-lock-manifest" data.lockManifest "curriculum_release_ref"
  let mut identities : List LockIdentity := []
  for raw in data.lockIdentities do
    identities := (← parseLockIdentity raw) :: identities
  identities := identities.reverse
  if let some duplicate := firstDuplicateString (identities.map (·.recorded)) then
    failIO s!"traceability:error:curriculum-lock:duplicate-recorded-identity:{duplicate}"
  for link in data.flinks do
    let id ← requiredString "flink" link "id"
    let recorded ← requiredString "flink" link "candidate_ref_as_recorded"
    let current ← requiredString "flink" link "candidate_ref_current_resolved"
    let release ← requiredString "flink" link "curriculum_release_ref"
    if release != lockRelease then
      failIO s!"traceability:error:curriculum-lock:release-mismatch:{id}:{release}:{lockRelease}"
    let some authority := findLockIdentity? identities recorded
      | failIO s!"traceability:error:curriculum-lock:missing-linked-identity:{id}:{recorded}"
    if current != authority.current then
      failIO s!"traceability:error:curriculum-lock:current-resolution-mismatch:{id}:{current}:{authority.current}"
    let lineage ← IO.ofExcept <| jsonField "flink" link "candidate_lineage_resolution"
    let linkState ← requiredString "flink.candidate_lineage_resolution" lineage "state"
    let linkPath ← requiredStrings "flink.candidate_lineage_resolution" lineage "resolution_path"
    if linkPath.isEmpty then failIO s!"traceability:error:flink:empty-resolution-path:{id}"
    match linkPath with
    | first :: _ => if first != recorded then failIO s!"traceability:error:flink:path-does-not-start-recorded:{id}:{first}:{recorded}"
    | [] => unreachable!
    match linkPath.reverse with
    | last :: _ => if last != current then failIO s!"traceability:error:flink:path-does-not-end-current:{id}:{last}:{current}"
    | [] => unreachable!
    if linkState != authority.state then
      failIO s!"traceability:error:curriculum-lock:lineage-state-mismatch:{id}:{linkState}:{authority.state}"
    let treatment ← requiredString "flink" link "treatment_scope"
    let _coverage ← requiredString "flink" link "coverage_claim_scope"
    if !authority.treatments.contains treatment then
      failIO s!"traceability:error:curriculum-lock:treatment-scope-not-authorized:{id}:{treatment}:{recorded}"
    if isNonSuccessResolution authority.state then
      let linkStatus ← requiredString "flink" link "link_status"
      let recordStatus ← requiredString "flink" link "record_status"
      if linkStatus == "current" || recordStatus == "active" then
        failIO s!"traceability:error:curriculum-lock:non-success-link-marked-current:{id}:{authority.state}:{linkStatus}:{recordStatus}"

public def validateIntegrityV1 (data : RegistryData) : IO Unit := do
  validateFartBaselines data
  validateFartLinkBackrefs data
  validateFartLocatorBackrefs data
  validateFartLifecycle data
  validateFlocLifecycle data
  validateCurriculumAuthority data
  IO.println s!"traceability:integrity:pass:fart={data.farts.length};floc={data.flocs.length};flink={data.flinks.length};lock-identities={data.lockIdentities.length}"

end FormalMathTraceability
