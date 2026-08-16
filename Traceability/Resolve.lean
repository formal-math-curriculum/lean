/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Lean
public import Traceability.Views

/-!
Lean-environment resolution for current FLOC module/declaration coordinates.

Historical locators remain queryable metadata but are not required to import in the current checkout.
-/

open Lean

namespace FormalMathTraceability

private def failIO (msg : String) : IO α :=
  throw <| IO.userError msg

private def nameFromDotted (value : String) : Name :=
  (value.splitOn ".").foldl (fun acc part => Name.str acc part) Name.anonymous

private def currentFlocs (data : RegistryData) : IO (List Json) := do
  let mut out := []
  for floc in data.flocs do
    if (← IO.ofExcept <| stringField "floc" floc "locator_status") == "current" then out := floc :: out
  return out.reverse

private def uniqueModules (flocs : List Json) : IO (List String) := do
  let mut modules := []
  for floc in flocs do
    let moduleName ← IO.ofExcept <| stringField "floc" floc "module_name"
    if !modules.contains moduleName then modules := moduleName :: modules
  return modules.reverse

public unsafe def resolveCurrentDeclarations (data : RegistryData) : IO Unit := do
  let flocs ← currentFlocs data
  let modules ← uniqueModules flocs
  if modules.isEmpty then
    IO.println "traceability:resolve:pass:current-modules=0;declarations=0"
    return
  initSearchPath (← findSysroot)
  let imports : Array Import := (modules.map fun moduleName => { module := nameFromDotted moduleName }).toArray
  let env ← importModules imports {} 0
  let mut declarationCount := 0
  for floc in flocs do
    let moduleName ← IO.ofExcept <| stringField "floc" floc "module_name"
    let declarations ← IO.ofExcept <| stringArrayField "floc" floc "declaration_names"
    for declaration in declarations do
      declarationCount := declarationCount + 1
      let declarationName := nameFromDotted declaration
      if !env.contains declarationName then
        failIO s!"traceability:error:resolve:missing-declaration:{moduleName}:{declaration}"
  IO.println s!"traceability:resolve:pass:current-modules={modules.length};declarations={declarationCount}"

end FormalMathTraceability
