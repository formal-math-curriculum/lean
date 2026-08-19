/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean.Data.Json
public import Lean.Util.Path

/-!
Derived M2.8 traceability views.

This module reads the authored FART/FLOC/FLINK registry and curriculum lock and constructs
non-authoritative forward/reverse projections. It never writes back to authored metadata.
-/

open Lean System

namespace FormalMathTraceability

public structure RegistryData where
  registryManifest : Json
  lockManifest : Json
  farts : List Json
  flocs : List Json
  flinks : List Json
  lockIdentities : List Json

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

public def jsonField (context : String) (j : Json) (key : String) : Except String Json :=
  (j.getObjVal? key).mapError fun e => s!"traceability:error:{context}:{key}:{e}"

public def stringField (context : String) (j : Json) (key : String) : Except String String := do
  (← jsonField context j key).getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"

public def stringArrayField (context : String) (j : Json) (key : String) : Except String (List String) := do
  let values ← (← jsonField context j key).getArr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}"
  let mut out := []
  for value in values do
    out := (← value.getStr? |>.mapError fun e => s!"traceability:error:{context}:{key}:{e}") :: out
  return out.reverse

private def parseJsonFile (path : FilePath) : IO Json := do
  let text ← IO.FS.readFile path
  IO.ofExcept <| (Json.parse text).mapError fun e => s!"traceability:error:{path}:json-parse:{e}"

private def parseJsonl (path : FilePath) : IO (List Json) := do
  if !(← path.pathExists) then
    return []
  let text ← IO.FS.readFile path
  if text.isEmpty then
    return []
  let lines := if text.endsWith "\n" then ((text.splitOn "\n").reverse.drop 1).reverse else text.splitOn "\n"
  let mut out := []
  let mut lineNo := 0
  for line in lines do
    lineNo := lineNo + 1
    if !line.isEmpty then
      out := (← IO.ofExcept <| (Json.parse line).mapError fun e => s!"traceability:error:{path}:{lineNo}:json-parse:{e}") :: out
  return out.reverse

private def readFamily (root : FilePath) (family : String) : IO (List Json) := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then return []
  if !(← dir.isDir) then failIO s!"traceability:error:{dir}:not-directory"
  let paths := (← dir.walkDir).filter fun p => p.extension == some "jsonl"
  let paths := paths.qsort fun a b => decide (a.toString < b.toString)
  let mut out := []
  for path in paths do
    out := out ++ (← parseJsonl path)
  return out

public def loadRegistryData (root : FilePath := ".") : IO RegistryData := do
  return {
    registryManifest := ← parseJsonFile (root / "metadata" / "formal-artifacts" / "registry.json")
    lockManifest := ← parseJsonFile (root / "metadata" / "curriculum-lock" / "manifest.json")
    farts := ← readFamily root "fart"
    flocs := ← readFamily root "floc"
    flinks := ← readFamily root "flink"
    lockIdentities := ← parseJsonl (root / "metadata" / "curriculum-lock" / "linked-identities.jsonl")
  }

private def idOf (context : String) (j : Json) : IO String :=
  IO.ofExcept <| stringField context j "id"

public def findFart? (data : RegistryData) (id : String) : IO (Option Json) := do
  for fart in data.farts do
    if (← idOf "fart" fart) == id then return some fart
  return none

public def flocsForFart (data : RegistryData) (id : String) : IO (List Json) := do
  let mut out := []
  for floc in data.flocs do
    if (← IO.ofExcept <| stringField "floc" floc "formal_artifact_ref") == id then out := floc :: out
  return out.reverse

public def linksForFart (data : RegistryData) (id : String) : IO (List Json) := do
  let mut out := []
  for link in data.flinks do
    if (← IO.ofExcept <| stringField "flink" link "formal_artifact_ref") == id then out := link :: out
  return out.reverse

private def jsonArray (xs : List Json) : Json :=
  Json.arr xs.toArray

private def artifactView (data : RegistryData) (fart : Json) : IO Json := do
  let id ← idOf "fart" fart
  return Json.mkObj [
    ("artifact_id", Json.str id),
    ("artifact", fart),
    ("locators", jsonArray (← flocsForFart data id)),
    ("curriculum_links", jsonArray (← linksForFart data id))
  ]

public def byArtifact (data : RegistryData) : IO (List Json) := do
  let mut out := []
  for fart in data.farts do out := (← artifactView data fart) :: out
  return out.reverse

public def byCurriculum (data : RegistryData) : IO (List Json) := do
  let mut out := []
  for link in data.flinks do
    let fartId ← IO.ofExcept <| stringField "flink" link "formal_artifact_ref"
    let some fart ← findFart? data fartId
      | failIO s!"traceability:error:generated:dangling-flink-fart:{fartId}"
    out := Json.mkObj [
      ("curriculum_release_ref", ← jsonField "flink" link "curriculum_release_ref" |> IO.ofExcept),
      ("candidate_ref_as_recorded", ← jsonField "flink" link "candidate_ref_as_recorded" |> IO.ofExcept),
      ("candidate_ref_current_resolved", ← jsonField "flink" link "candidate_ref_current_resolved" |> IO.ofExcept),
      ("link", link),
      ("artifact", fart),
      ("locators", jsonArray (← flocsForFart data fartId))
    ] :: out
  return out.reverse

public def bySource (data : RegistryData) : IO (List Json) := do
  let mut out := []
  for floc in data.flocs do
    let fartId ← IO.ofExcept <| stringField "floc" floc "formal_artifact_ref"
    let some fart ← findFart? data fartId
      | failIO s!"traceability:error:generated:dangling-floc-fart:{fartId}"
    out := Json.mkObj [
      ("locator", floc),
      ("artifact", fart),
      ("curriculum_links", jsonArray (← linksForFart data fartId))
    ] :: out
  return out.reverse

public def historyView (data : RegistryData) : IO (List Json) := do
  let mut out := []
  for floc in data.flocs do
    let status ← IO.ofExcept <| stringField "floc" floc "locator_status"
    if status != "current" then out := floc :: out
  return out.reverse

private def lineageState (link : Json) : IO String := do
  let lineage ← IO.ofExcept <| jsonField "flink" link "candidate_lineage_resolution"
  IO.ofExcept <| stringField "flink.lineage" lineage "state"

private def lockIdentityUnresolved (identity : Json) : IO Bool := do
  let recordStatus ← IO.ofExcept <| stringField "curriculum-lock-identity" identity "record_status"
  let resolutionState ← IO.ofExcept <| stringField "curriculum-lock-identity" identity "resolution_state"
  return recordStatus == "stale" || recordStatus == "unresolved" ||
    resolutionState == "needs_scope_review" || resolutionState == "ambiguous" ||
    resolutionState == "stale" || resolutionState == "unresolved"

public def unresolvedView (data : RegistryData) : IO (List Json) := do
  let mut out := []
  let lockStatus ← IO.ofExcept <| stringField "curriculum-lock" data.lockManifest "mirror_status"
  if lockStatus != "verified_snapshot" then
    out := Json.mkObj [("kind", Json.str "curriculum_lock"), ("record", data.lockManifest)] :: out
  for identity in data.lockIdentities do
    if ← lockIdentityUnresolved identity then
      out := Json.mkObj [("kind", Json.str "curriculum_lock_identity"), ("record", identity)] :: out
  for floc in data.flocs do
    if (← IO.ofExcept <| stringField "floc" floc "locator_status") == "unresolved" then
      out := Json.mkObj [("kind", Json.str "floc"), ("record", floc)] :: out
  for link in data.flinks do
    let status ← IO.ofExcept <| stringField "flink" link "link_status"
    let lineage ← lineageState link
    if status == "needs_review" || status == "unresolved" ||
        lineage == "needs_scope_review" || lineage == "ambiguous" || lineage == "stale" || lineage == "unresolved" then
      out := Json.mkObj [("kind", Json.str "flink"), ("record", link)] :: out
  return out.reverse

private def writeJsonl (path : FilePath) (records : List Json) : IO Unit := do
  let text := String.join (records.map fun record => Json.compress record ++ "\n")
  IO.FS.writeFile path text

private def processOutput (cmd : String) (args : Array String) : IO String := do
  let result ← IO.Process.output { cmd := cmd, args := args }
  if result.exitCode != 0 then
    failIO s!"traceability:error:process:{cmd}:exit={result.exitCode}:{result.stderr}"
  return result.stdout.trimAscii.toString

public def currentGitSha : IO String :=
  processOutput "git" #["rev-parse", "HEAD"]

private def currentGitTimestamp : IO String :=
  processOutput "git" #["show", "-s", "--format=%ct", "HEAD"]

private def gitBlobHash (path : FilePath) : IO String :=
  processOutput "git" #["hash-object", path.toString]

private def outputFingerprint (files : List (String × FilePath)) : IO String := do
  let mut parts := []
  for (name, path) in files do parts := s!"{name}:{← gitBlobHash path}" :: parts
  return String.intercalate ";" parts.reverse

private def humanIndex (data : RegistryData) (subjectContext subjectRevision lockStatus release : String) : String :=
  s!"# Generated curriculum-to-code traceability index\n\n**Authority:** generated derived view — do not edit as source of truth.\n\n- Subject context: `{subjectContext}`\n- Subject revision: `{subjectRevision}`\n- Curriculum release: `{release}`\n- Curriculum-lock state: `{lockStatus}`\n- FART records: {data.farts.length}\n- FLOC records: {data.flocs.length}\n- FLINK records: {data.flinks.length}\n\nUse the authored registry under `metadata/formal-artifacts/` for Project-2 traceability truth and the governed Project-1 release for curriculum truth.\n"

public def generateViews (root : FilePath := ".") : IO FilePath := do
  let data ← loadRegistryData root
  let sha ← currentGitSha
  let governedSubject := root.toString == "."
  let subjectRevision := if governedSubject then sha else "not_applicable"
  let subjectContext ← if governedSubject then
      pure (if (← IO.getEnv "GITHUB_EVENT_NAME").isSome then "github_actions" else "local")
    else
      pure "alternate_root_content_snapshot"
  let repository := if governedSubject then "formal-math-curriculum/lean" else "not_applicable"
  let sourceTime ← if governedSubject then currentGitTimestamp else pure "not_applicable"
  let outDir := root / ".lake" / "build" / "traceability" / sha
  IO.FS.createDirAll outDir
  let curriculum ← byCurriculum data
  let artifacts ← byArtifact data
  let source ← bySource data
  let history ← historyView data
  let unresolved ← unresolvedView data
  let curriculumPath := outDir / "by-curriculum.jsonl"
  let artifactPath := outDir / "by-artifact.jsonl"
  let sourcePath := outDir / "by-source.jsonl"
  let historyPath := outDir / "history.jsonl"
  let unresolvedPath := outDir / "unresolved.jsonl"
  let indexPath := outDir / "index.md"
  writeJsonl curriculumPath curriculum
  writeJsonl artifactPath artifacts
  writeJsonl sourcePath source
  writeJsonl historyPath history
  writeJsonl unresolvedPath unresolved
  let lockStatus ← IO.ofExcept <| stringField "curriculum-lock" data.lockManifest "mirror_status"
  let release ← IO.ofExcept <| stringField "curriculum-lock" data.lockManifest "curriculum_release_ref"
  IO.FS.writeFile indexPath (humanIndex data subjectContext subjectRevision lockStatus release)
  let fingerprint ← outputFingerprint [
    ("by-artifact", artifactPath), ("by-curriculum", curriculumPath), ("by-source", sourcePath),
    ("history", historyPath), ("index", indexPath), ("unresolved", unresolvedPath)
  ]
  let dependencyBaseline ← IO.ofExcept <| stringField "registry-manifest" data.registryManifest "dependency_baseline_ref"
  let toolchain ← IO.ofExcept <| stringField "registry-manifest" data.registryManifest "lean_toolchain_ref"
  let manifest := Json.mkObj [
    ("authority", Json.str "generated_derived"),
    ("generated_schema_version", Json.num 1),
    ("generator_revision", Json.str sha),
    ("repository", Json.str repository),
    ("subject_revision", Json.str subjectRevision),
    ("subject_context", Json.str subjectContext),
    ("trace_registry_schema_ref", Json.str "P2-TRACE-M2.8-REGISTRY-v1"),
    ("curriculum_release_ref", Json.str release),
    ("curriculum_lock_status", Json.str lockStatus),
    ("dependency_baseline_ref", Json.str dependencyBaseline),
    ("lean_toolchain_ref", Json.str toolchain),
    ("deterministic_source_time", Json.str sourceTime),
    ("record_counts", Json.mkObj [
      ("by_artifact", Json.num artifacts.length), ("by_curriculum", Json.num curriculum.length),
      ("by_source", Json.num source.length), ("history", Json.num history.length),
      ("unresolved", Json.num unresolved.length)
    ]),
    ("semantic_fingerprint", Json.str fingerprint),
    ("result_state", Json.str "pass")
  ]
  IO.FS.writeFile (outDir / "manifest.json") (Json.compress manifest ++ "\n")
  IO.println s!"traceability:generate:pass:dir={outDir}:fingerprint={fingerprint}"
  return outDir

private def printJsonLines (records : List Json) : IO Unit :=
  for record in records do IO.println (Json.compress record)

public def queryArtifact (data : RegistryData) (artifactId : String) : IO Unit := do
  let records ← byArtifact data
  printJsonLines (records.filter fun record =>
    match stringField "by-artifact" record "artifact_id" with | .ok id => id == artifactId | .error _ => false)

public def queryCurriculum (data : RegistryData) (candidateId : String) : IO Unit := do
  let records ← byCurriculum data
  printJsonLines (records.filter fun record =>
    match stringField "by-curriculum" record "candidate_ref_as_recorded" with | .ok id => id == candidateId | .error _ => false)

private def sourceMatches (record : Json) (needle : String) : Bool :=
  match jsonField "by-source" record "locator" with
  | .error _ => false
  | .ok locator =>
      let moduleMatch := match stringField "floc" locator "module_name" with | .ok x => x == needle | _ => false
      let fileMatch := match stringField "floc" locator "file_path" with | .ok x => x == needle | _ => false
      let declarationMatch := match stringArrayField "floc" locator "declaration_names" with | .ok xs => xs.contains needle | _ => false
      moduleMatch || fileMatch || declarationMatch

public def querySource (data : RegistryData) (needle : String) : IO Unit := do
  printJsonLines ((← bySource data).filter fun record => sourceMatches record needle)

end FormalMathTraceability
