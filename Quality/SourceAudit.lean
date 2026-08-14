/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Init.System.IO

namespace FormalMathQuality.SourceAudit

open System

public inductive Severity where
  | error
  | advisory
  deriving BEq, Repr

public structure Finding where
  severity : Severity
  rule : String
  path : String
  detail : String
  deriving Repr

private def normalizedPathString (path : FilePath) : String :=
  path.toString.replace "\\" "/"

private def isFixturePath (path : FilePath) : Bool :=
  (normalizedPathString path).startsWith "Quality/Fixtures/"

private def isLeanFile (path : FilePath) : Bool :=
  (normalizedPathString path).endsWith ".lean"

private def sourceLines (content : String) : List String :=
  content.splitOn "\n"

private def hasNativeHeader (content : String) : Bool :=
  let lines := sourceLines content
  let hasLicense := lines.any fun line =>
    line.trim == "License: see the repository LICENSE file."
  let hasAuthors := lines.any fun line =>
    (line.trim).startsWith "Authors: "
  hasLicense && hasAuthors

private def importPayload? (line : String) : Option (Bool × String) :=
  let line := line.trim
  if line.startsWith "public import " then
    some (true, (line.drop 14).trim)
  else if line.startsWith "import " then
    some (false, (line.drop 7).trim)
  else
    none

private def importModules (payload : String) : List String :=
  (payload.split (fun c => c.isWhitespace)).filter (fun token => !token.isEmpty)

private def hasModulePrefix (prefix moduleName : String) : Bool :=
  moduleName == prefix || moduleName.startsWith (prefix ++ ".")

private def ungovernedTransitivePrefixes : List String :=
  ["Aesop", "Batteries", "Cli", "ImportGraph", "LeanSearchClient", "Plausible", "ProofWidgets", "Qq"]

private def auditImport
    (path : FilePath)
    (isProduction : Bool)
    (isPublicImport : Bool)
    (moduleName : String) : Array Finding := Id.run do
  let pathString := normalizedPathString path
  let mut findings := #[]
  if isProduction && pathString.startsWith "FormalMath/" && moduleName == "FormalMath" then
    findings := findings.push {
      severity := .error
      rule := "S002"
      path := pathString
      detail := "production FormalMath.* modules must not import the root FormalMath umbrella"
    }
  if isProduction && ungovernedTransitivePrefixes.any (fun prefix => hasModulePrefix prefix moduleName) then
    findings := findings.push {
      severity := .error
      rule := "S003"
      path := pathString
      detail := s!"direct import of ungoverned mathlib-transitive module '{moduleName}'"
    }
  if isProduction && isPublicImport && hasModulePrefix "FormalMath.Internal" moduleName &&
      !pathString.startsWith "FormalMath/Internal/" then
    findings := findings.push {
      severity := .error
      rule := "S004"
      path := pathString
      detail := s!"supported module publicly re-exports Internal module '{moduleName}'"
    }
  if isProduction && moduleName == "Mathlib" then
    findings := findings.push {
      severity := .advisory
      rule := "A001"
      path := pathString
      detail := "broad Mathlib umbrella import requires review; prefer a specific semantic module when practical"
    }
  return findings

public def auditFile (path : FilePath) (isProduction : Bool := false) : IO (Array Finding) := do
  let content ← IO.FS.readFile path
  let mut findings := #[]
  if !hasNativeHeader content then
    findings := findings.push {
      severity := .error
      rule := "S001"
      path := normalizedPathString path
      detail := "project-native Lean source must reference repository LICENSE and an Authors line"
    }
  for line in sourceLines content do
    if let some (isPublicImport, payload) := importPayload? line then
      for moduleName in importModules payload do
        findings := findings ++ auditImport path isProduction isPublicImport moduleName
  return findings

private def leanFilesUnder (root : FilePath) : IO (Array FilePath) := do
  if !(← root.pathExists) then
    return #[]
  if ← root.isDir then
    let paths ← root.walkDir
    let mut files := #[]
    for path in paths do
      if !(← path.isDir) && isLeanFile path then
        files := files.push path
    return files
  else if isLeanFile root then
    return #[root]
  else
    return #[]

public def auditTree
    (root : FilePath)
    (isProduction : Bool := false)
    (excludeFixtures : Bool := false) : IO (Array Finding) := do
  let files ← leanFilesUnder root
  let mut findings := #[]
  for path in files do
    if !(excludeFixtures && isFixturePath path) then
      findings := findings ++ (← auditFile path isProduction)
  return findings

public def printFinding (finding : Finding) : IO Unit := do
  let severity := match finding.severity with
    | .error => "ERROR"
    | .advisory => "ADVISORY"
  IO.println s!"source audit: {severity} {finding.rule} {finding.path}: {finding.detail}"

public def errorCount (findings : Array Finding) : Nat :=
  findings.foldl (init := 0) fun count finding =>
    if finding.severity == .error then count + 1 else count

public def advisoryCount (findings : Array Finding) : Nat :=
  findings.foldl (init := 0) fun count finding =>
    if finding.severity == .advisory then count + 1 else count

end FormalMathQuality.SourceAudit
