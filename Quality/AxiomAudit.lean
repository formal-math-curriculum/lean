/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import Lean.Elab.Command
import Lean.Util.CollectAxioms

open Lean Elab Command

namespace FormalMathQuality.AxiomAudit

private def moduleNameForDecl (env : Environment) (declName : Name) : Name :=
  match env.getModuleIdxFor? declName with
  | some modIdx =>
      match env.allImportedModuleNames[modIdx.toNat]? with
      | some moduleName => moduleName
      | none => env.header.mainModule
  | none => env.header.mainModule

private def moduleHasPrefix (prefix moduleName : Name) : Bool :=
  let p := prefix.toString
  let m := moduleName.toString
  m == p || m.startsWith (p ++ ".")

private def isStandardMathematicalAxiom (name : Name) : Bool :=
  let s := name.toString
  s == "propext" || s == "Classical.choice" || s == "Quot.sound"

private def isSorryAxiom (name : Name) : Bool :=
  name.toString == "sorryAx"

private def isTrustCompilerAxiom (name : Name) : Bool :=
  name.toString == "Lean.trustCompiler"

private def namesString (names : Array Name) : String :=
  String.intercalate ", " <| names.toList.map (·.toString)

/--
Audit every kernel declaration whose origin module is `modulePrefix` or one of its descendants.

Standard Lean mathematical axioms (`propext`, `Classical.choice`, `Quot.sound`) are reported but do
not fail the default audit. `sorryAx`, `Lean.trustCompiler`, and all other unclassified axioms fail.
The module-origin filter is intentional: project declaration namespaces need not mirror module paths.
-/
public meta def auditModulePrefix (modulePrefix : Name) : CommandElabM Unit := do
  let env ← getEnv
  let names ← env.checked.get.constants.map₂.foldlM (init := #[]) fun acc declName _ => do
    let origin := moduleNameForDecl env declName
    pure <| if moduleHasPrefix modulePrefix origin then acc.push declName else acc
  let names := names.qsort Name.lt
  let mut failures := 0
  let mut withAxioms := 0
  for declName in names do
    let axioms ← Lean.collectAxioms declName
    if !axioms.isEmpty then
      withAxioms := withAxioms + 1
      let standard := axioms.filter isStandardMathematicalAxiom
      let sorries := axioms.filter isSorryAxiom
      let trust := axioms.filter isTrustCompilerAxiom
      let custom := axioms.filter fun axiomName =>
        !(isStandardMathematicalAxiom axiomName || isSorryAxiom axiomName || isTrustCompilerAxiom axiomName)
      if !standard.isEmpty then
        logInfo m!"axiom audit: {declName}: standard=[{namesString standard}]"
      if !sorries.isEmpty then
        failures := failures + 1
        logError m!"axiom audit: {declName}: unfinished=[{namesString sorries}]"
      if !trust.isEmpty then
        failures := failures + 1
        logError m!"axiom audit: {declName}: trust-review=[{namesString trust}]"
      if !custom.isEmpty then
        failures := failures + 1
        logError m!"axiom audit: {declName}: custom-or-unclassified=[{namesString custom}]"
  logInfo m!"axiom audit: module-prefix={modulePrefix}; declarations={names.size}; declarations-with-axioms={withAxioms}; failures={failures}"
  if failures > 0 then
    throwError "formal mathematics axiom audit failed"

syntax (name := formalMathAxiomAudit) "#formal_math_axiom_audit " ident : command

elab_rules : command
  | `(#formal_math_axiom_audit $prefix:ident) =>
      auditModulePrefix prefix.getId

end FormalMathQuality.AxiomAudit
