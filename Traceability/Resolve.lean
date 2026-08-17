/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean
public import Traceability.Views

/-!
Exact current-target resolution for M2.8 FLOCs.

A declaration is accepted only when it exists **and** Lean reports that its declaring module is the
module named by the FLOC. Current project locators preserve their qualified source revision as
provenance and couple the executing checkout to that source content with an immutable `git-blob:`
structural anchor. This remains valid in shallow PR checkouts and metadata-only descendant revisions
while still failing closed on source drift. Dependency locators remain tied to the selected
`lake-manifest.json` revision. Historical locators remain metadata and are not required to import in
the current checkout.
-/

open Lean System

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def nameFromDotted (value : String) : Name :=
  (value.splitOn ".").foldl (fun acc part => Name.str acc part) Name.anonymous

private def canonicalFileForModule (moduleName : String) : IO String := do
  let parts := moduleName.splitOn "."
  if parts.isEmpty || parts.any (·.isEmpty) then
    failIO s!"traceability:error:resolve:invalid-module-name:{moduleName}"
  return String.intercalate "/" parts ++ ".lean"

private def currentFlocs (data : RegistryData) : IO (List Lean.Json) := do
  let mut out := []
  for floc in data.flocs do
    if (← IO.ofExcept <| stringField "floc" floc "locator_status") == "current" then out := floc :: out
  return out.reverse

private def uniqueModules (flocs : List Lean.Json) : IO (List String) := do
  let mut modules := []
  for floc in flocs do
    let moduleName ← IO.ofExcept <| stringField "floc" floc "module_name"
    if !modules.contains moduleName then modules := moduleName :: modules
  return modules.reverse

private def processOutput (cmd : String) (args : Array String) : IO String := do
  let result ← IO.Process.output { cmd := cmd, args := args }
  if result.exitCode != 0 then
    failIO s!"traceability:error:resolve:process:{cmd}:exit={result.exitCode}:{result.stderr}"
  return result.stdout.trimAscii.toString

private def executionRepositoryRoot : IO FilePath :=
  return FilePath.mk (← processOutput "git" #["rev-parse", "--show-toplevel"])

private def parseJsonFile (path : FilePath) : IO Lean.Json := do
  let text ← IO.FS.readFile path
  IO.ofExcept <| (Lean.Json.parse text).mapError fun e => s!"traceability:error:resolve:{path}:json-parse:{e}"

private def selectedDependencyRevision? (repository : String) : IO (Option String) := do
  let repoRoot ← executionRepositoryRoot
  let manifest ← parseJsonFile (repoRoot / "lake-manifest.json")
  let packagesJson ← IO.ofExcept <| jsonField "lake-manifest" manifest "packages"
  let packages ← IO.ofExcept <| packagesJson.getArr? |>.mapError fun e => s!"traceability:error:resolve:lake-manifest:packages:{e}"
  for package in packages do
    let url ← IO.ofExcept <| stringField "lake-package" package "url"
    if url.endsWith repository || url.endsWith (repository ++ ".git") then
      return some (← IO.ofExcept <| stringField "lake-package" package "rev")
  return none

private def requireProjectSourceCoupling (root : FilePath) (filePath : String) : IO Unit := do
  let repoRoot ← executionRepositoryRoot
  let target := root / filePath
  let executing := repoRoot / filePath
  if !(← executing.pathExists) then
    failIO s!"traceability:error:resolve:project-source-not-in-executing-checkout:{filePath}"
  if !(← target.pathExists) then
    failIO s!"traceability:error:resolve:missing-project-source:{filePath}"
  let targetText ← IO.FS.readFile target
  let executingText ← IO.FS.readFile executing
  if targetText != executingText then
    failIO s!"traceability:error:resolve:alternate-root-source-mismatch:{filePath}"

private def projectBlobDigest (id : String) (anchors : List String) : IO String := do
  let blobAnchors := anchors.filter fun anchor => anchor.startsWith "git-blob:"
  match blobAnchors with
  | [anchor] =>
      let digest := String.ofList ((anchor.toList).drop "git-blob:".length)
      if digest.length != 40 then
        failIO s!"traceability:error:resolve:invalid-project-git-blob-anchor:{id}:{anchor}"
      return digest
  | [] => failIO s!"traceability:error:resolve:missing-project-git-blob-anchor:{id}"
  | _ => failIO s!"traceability:error:resolve:multiple-project-git-blob-anchors:{id}"

private def requireProjectBlobCoupling (id filePath : String) (anchors : List String) : IO Unit := do
  let expected ← projectBlobDigest id anchors
  let repoRoot ← executionRepositoryRoot
  let actual ← processOutput "git" #["hash-object", (repoRoot / filePath).toString]
  if actual != expected then
    failIO s!"traceability:error:resolve:project-source-drift:{id}:{expected}:{actual}:{filePath}"

private def validateLocatorSubject (root : FilePath) (data : RegistryData) (floc : Lean.Json) : IO Unit := do
  let id ← IO.ofExcept <| stringField "floc" floc "id"
  let sourceKind ← IO.ofExcept <| stringField "floc" floc "source_kind"
  let repository ← IO.ofExcept <| stringField "floc" floc "repository"
  let revision ← IO.ofExcept <| stringField "floc" floc "revision"
  let moduleName ← IO.ofExcept <| stringField "floc" floc "module_name"
  let filePath ← IO.ofExcept <| stringField "floc" floc "file_path"
  let anchors ← IO.ofExcept <| stringArrayField "floc" floc "structural_anchors"
  let canonicalFile ← canonicalFileForModule moduleName
  if filePath != canonicalFile then
    failIO s!"traceability:error:resolve:module-file-mismatch:{id}:{moduleName}:{filePath}:{canonicalFile}"
  if sourceKind == "project_repository" then
    if repository != "formal-math-curriculum/lean" then
      failIO s!"traceability:error:resolve:project-repository-mismatch:{id}:{repository}"
    requireProjectSourceCoupling root filePath
    let rootReal ← IO.FS.realPath root
    let repoRootReal ← IO.FS.realPath (← executionRepositoryRoot)
    if rootReal.normalize == repoRootReal.normalize then
      requireProjectBlobCoupling id filePath anchors
  else if sourceKind == "dependency_repository" then
    let expectedBaseline ← IO.ofExcept <| stringField "registry-manifest" data.registryManifest "dependency_baseline_ref"
    let locatorBaseline ← IO.ofExcept <| stringField "floc" floc "dependency_baseline_ref"
    if locatorBaseline != expectedBaseline then
      failIO s!"traceability:error:resolve:dependency-baseline-mismatch:{id}:{locatorBaseline}:{expectedBaseline}"
    let some selectedRevision ← selectedDependencyRevision? repository
      | failIO s!"traceability:error:resolve:dependency-repository-not-selected:{id}:{repository}"
    if revision != selectedRevision then
      failIO s!"traceability:error:resolve:dependency-revision-mismatch:{id}:{revision}:{selectedRevision}"
  else
    failIO s!"traceability:error:resolve:unsupported-source-kind:{id}:{sourceKind}"

private def declaringModule? (env : Environment) (declName : Name) : Option Name := do
  let modIdx ← env.getModuleIdxFor? declName
  env.allImportedModuleNames[modIdx.toNat]?

public unsafe def resolveCurrentDeclarations (root : FilePath) (data : RegistryData) : IO Unit := do
  let flocs ← currentFlocs data
  let modules ← uniqueModules flocs
  if modules.isEmpty then
    IO.println "traceability:resolve:pass:current-modules=0;declarations=0"
    return
  for floc in flocs do
    validateLocatorSubject root data floc
  initSearchPath (← findSysroot)
  let imports : Array Import := (modules.map fun moduleName => { module := nameFromDotted moduleName }).toArray
  let env ← importModules imports {} 0
  let mut declarationCount := 0
  for floc in flocs do
    let flocId ← IO.ofExcept <| stringField "floc" floc "id"
    let moduleName ← IO.ofExcept <| stringField "floc" floc "module_name"
    let claimedModule := nameFromDotted moduleName
    let declarations ← IO.ofExcept <| stringArrayField "floc" floc "declaration_names"
    for declaration in declarations do
      declarationCount := declarationCount + 1
      let declarationName := nameFromDotted declaration
      if !env.contains declarationName then
        failIO s!"traceability:error:resolve:missing-declaration:{flocId}:{moduleName}:{declaration}"
      let some actualModule := declaringModule? env declarationName
        | failIO s!"traceability:error:resolve:missing-declaration-origin:{flocId}:{declaration}"
      if actualModule != claimedModule then
        failIO s!"traceability:error:resolve:declaration-module-mismatch:{flocId}:{declaration}:{actualModule}:{claimedModule}"
  IO.println s!"traceability:resolve:pass:current-modules={modules.length};declarations={declarationCount}"

end FormalMathTraceability
