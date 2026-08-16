/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Traceability.Views

/-!
M2.9 content-bound provenance for generated traceability views.

This is an additive successor to the M2.8 generated manifest. It does not make generated files
authoritative and it does not rewrite authored FART/FLOC/FLINK metadata.
-/

open Lean System

namespace FormalMathTraceability

private def provenanceFailIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def processOutputV2 (cmd : String) (args : Array String) : IO String := do
  let result ← IO.Process.output { cmd := cmd, args := args }
  if result.exitCode != 0 then
    provenanceFailIO s!"traceability:provenance:error:process:{cmd}:exit={result.exitCode}:{result.stderr}"
  return result.stdout.trimAscii.toString

private def blobHashV2 (path : FilePath) : IO String :=
  processOutputV2 "git" #["hash-object", path.toString]

private def familyFilesV2 (root : FilePath) (family : String) : IO (List FilePath) := do
  let dir := root / "metadata" / "formal-artifacts" / family
  if !(← dir.pathExists) then return []
  if !(← dir.isDir) then provenanceFailIO s!"traceability:provenance:error:{dir}:not-directory"
  let paths := (← dir.walkDir).filter fun p => p.extension == some "jsonl"
  return (paths.qsort fun a b => decide (a.toString < b.toString)).toList

private def familyFingerprintV2 (root : FilePath) (family : String) : IO String := do
  let paths ← familyFilesV2 root family
  let mut parts := []
  let mut index := 0
  for path in paths do
    index := index + 1
    parts := s!"{family}:{index}:{← blobHashV2 path}" :: parts
  return String.intercalate ";" parts.reverse

public def registryInputFingerprintV2 (root : FilePath := ".") : IO String := do
  let registryPath := root / "metadata" / "formal-artifacts" / "registry.json"
  let registryHash ← blobHashV2 registryPath
  let fart ← familyFingerprintV2 root "fart"
  let floc ← familyFingerprintV2 root "floc"
  let flink ← familyFingerprintV2 root "flink"
  let parts := [s!"registry:{registryHash}", fart, floc, flink].filter (fun x => !x.isEmpty)
  return String.intercalate ";" parts

public def curriculumLockFingerprintV2 (root : FilePath := ".") : IO String := do
  let manifestPath := root / "metadata" / "curriculum-lock" / "manifest.json"
  let identitiesPath := root / "metadata" / "curriculum-lock" / "linked-identities.jsonl"
  return s!"manifest:{← blobHashV2 manifestPath};identities:{← blobHashV2 identitiesPath}"

public def authoritativeInputFingerprintV2 (root : FilePath := ".") : IO String := do
  return s!"registry=[{← registryInputFingerprintV2 root}]|curriculum-lock=[{← curriculumLockFingerprintV2 root}]"

private def governedRootV2 (root : FilePath) : Bool :=
  root.toString == "."

private def provenancePathV2 (root : FilePath) (generatorRevision : String) : FilePath :=
  root / ".lake" / "build" / "traceability" / generatorRevision / "provenance-v2.json"

public def writeProvenanceV2 (root outDir : FilePath) : IO FilePath := do
  let data ← loadRegistryData root
  let generatorRevision ← currentGitSha
  let governed := governedRootV2 root
  let registryFingerprint ← registryInputFingerprintV2 root
  let lockFingerprint ← curriculumLockFingerprintV2 root
  let authoredFingerprint ← authoritativeInputFingerprintV2 root
  let release ← IO.ofExcept <| stringField "curriculum-lock" data.lockManifest "curriculum_release_ref"
  let lockStatus ← IO.ofExcept <| stringField "curriculum-lock" data.lockManifest "mirror_status"
  let dependencyBaseline ← IO.ofExcept <| stringField "registry-manifest" data.registryManifest "dependency_baseline_ref"
  let toolchain ← IO.ofExcept <| stringField "registry-manifest" data.registryManifest "lean_toolchain_ref"
  let subjectKind := if governed then "governed_repository_revision" else "alternate_root_content_snapshot"
  let subjectRevision := if governed then generatorRevision else "not_applicable"
  let repositoryRevisionClaim := if governed then "exact_generator_checkout" else "none"
  let manifest := Json.mkObj [
    ("authority", Json.str "generated_derived_provenance"),
    ("provenance_schema_version", Json.num 2),
    ("provenance_ref", Json.str "P2-TRACE-M2.9-PROVENANCE-v2"),
    ("generator_revision", Json.str generatorRevision),
    ("output_namespace_revision", Json.str generatorRevision),
    ("subject_kind", Json.str subjectKind),
    ("subject_revision", Json.str subjectRevision),
    ("repository_revision_claim", Json.str repositoryRevisionClaim),
    ("registry_input_fingerprint", Json.str registryFingerprint),
    ("curriculum_lock_input_fingerprint", Json.str lockFingerprint),
    ("authoritative_input_fingerprint", Json.str authoredFingerprint),
    ("freshness_contract", Json.str "content_bound"),
    ("curriculum_release_ref", Json.str release),
    ("curriculum_lock_status", Json.str lockStatus),
    ("dependency_baseline_ref", Json.str dependencyBaseline),
    ("lean_toolchain_ref", Json.str toolchain),
    ("legacy_generated_manifest", Json.str "manifest.json"),
    ("result_state", Json.str "pass")
  ]
  let path := outDir / "provenance-v2.json"
  IO.FS.writeFile path (Json.compress manifest ++ "\n")
  IO.println s!"traceability:provenance-v2:pass:subject-kind={subjectKind}:path={path}"
  return path

public def verifyProvenanceV2 (root : FilePath := ".") : IO Unit := do
  let generatorRevision ← currentGitSha
  let path := provenancePathV2 root generatorRevision
  if !(← path.pathExists) then
    provenanceFailIO s!"traceability:freshness:error:missing-provenance:{path}"
  let jsonText ← IO.FS.readFile path
  let provenance ← IO.ofExcept <| (Json.parse jsonText).mapError fun e => s!"traceability:freshness:error:json:{e}"
  let recorded ← IO.ofExcept <| stringField "provenance-v2" provenance "authoritative_input_fingerprint"
  let current ← authoritativeInputFingerprintV2 root
  if recorded != current then
    provenanceFailIO "traceability:freshness:error:authoritative-inputs-changed"
  let subjectKind ← IO.ofExcept <| stringField "provenance-v2" provenance "subject_kind"
  let subjectRevision ← IO.ofExcept <| stringField "provenance-v2" provenance "subject_revision"
  if governedRootV2 root then
    if subjectKind != "governed_repository_revision" || subjectRevision != generatorRevision then
      provenanceFailIO "traceability:freshness:error:governed-subject-mismatch"
  else if subjectKind != "alternate_root_content_snapshot" || subjectRevision != "not_applicable" then
    provenanceFailIO "traceability:freshness:error:alternate-root-overclaim"
  IO.println s!"traceability:freshness:pass:subject-kind={subjectKind}"

end FormalMathTraceability
