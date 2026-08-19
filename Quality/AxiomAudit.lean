/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public meta import Lean.Elab.Command
import Lean.Util.CollectAxioms

open Lean Elab Command

namespace FormalMathQuality.AxiomAudit

private meta def moduleNameForDecl (env : Environment) (declName : Name) : Name :=
  match env.getModuleIdxFor? declName with
  | some modIdx =>
      match env.allImportedModuleNames[modIdx.toNat]? with
      | some moduleName => moduleName
      | none => env.header.mainModule
  | none => env.header.mainModule

private meta def moduleHasPrefix (modulePrefix moduleName : Name) : Bool :=
  let p := modulePrefix.toString
  let m := moduleName.toString
  m == p || m.startsWith (p ++ ".")

private meta def isStandardMathematicalAxiom (name : Name) : Bool :=
  let s := name.toString
  s == "propext" || s == "Classical.choice" || s == "Quot.sound"

private meta def isSorryAxiom (name : Name) : Bool :=
  name.toString == "sorryAx"

private meta def isTrustCompilerAxiom (name : Name) : Bool :=
  name.toString == "Lean.trustCompiler"

private meta def namesString (names : Array Name) : String :=
  String.intercalate ", " <| names.toList.map (·.toString)

/--
Audit every kernel declaration whose origin module is `modulePrefix` or one of its descendants.

Standard Lean mathematical axioms (`propext`, `Classical.choice`, `Quot.sound`) are reported but do
not fail the default audit. `sorryAx`, `Lean.trustCompiler`, and all other unclassified axioms fail.
The module-origin filter is intentional: project declaration namespaces need not mirror module paths.
Imported and locally declared constants are both inspected. An empty result is a coverage failure by
default, and callers may provide declarations required for a governed production surface. Additional
implementation-internal declarations remain visible and audited without becoming governed locators.
-/
public meta def auditModulePrefix (modulePrefix : Name)
    (requiredDeclarations : Array Name := #[]) (requireNonempty := true) :
    CommandElabM Unit := do
  let env ← getEnv
  let names := env.constants.fold (init := #[]) fun acc declName _ =>
    let origin := moduleNameForDecl env declName
    if moduleHasPrefix modulePrefix origin then acc.push declName else acc
  let names := names.qsort Name.lt

  let mut coverageFailures : Nat := 0
  if requireNonempty && names.isEmpty then
    coverageFailures := coverageFailures + 1
    logError m!"axiom audit: module-prefix={modulePrefix}; coverage-empty"
  let requiredDeclarations := requiredDeclarations.qsort Name.lt
  let missingRequired := requiredDeclarations.filter fun declName => !names.contains declName
  if !missingRequired.isEmpty then
    coverageFailures := coverageFailures + 1
    logError m!"axiom audit: module-prefix={modulePrefix}; coverage-missing=[{namesString missingRequired}]"

  let mut axiomFailures : Nat := 0
  let mut withAxioms : Nat := 0
  for declName in names do
    let origin := moduleNameForDecl env declName
    let axioms := (← Lean.collectAxioms declName).qsort Name.lt
    logInfo m!"axiom audit: declaration={declName}; origin={origin}; axioms=[{namesString axioms}]"
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
        axiomFailures := axiomFailures + 1
        logError m!"axiom audit: {declName}: unfinished=[{namesString sorries}]"
      if !trust.isEmpty then
        axiomFailures := axiomFailures + 1
        logError m!"axiom audit: {declName}: trust-review=[{namesString trust}]"
      if !custom.isEmpty then
        axiomFailures := axiomFailures + 1
        logError m!"axiom audit: {declName}: custom-or-unclassified=[{namesString custom}]"
  let failures := coverageFailures + axiomFailures
  logInfo m!"axiom audit: module-prefix={modulePrefix}; declarations={names.size}; names=[{namesString names}]; required=[{namesString requiredDeclarations}]; missing-required=[{namesString missingRequired}]; declarations-with-axioms={withAxioms}; coverage-failures={coverageFailures}; axiom-failures={axiomFailures}; failures={failures}"
  if failures > 0 then
    throwError "formal mathematics axiom audit failed"

elab "#formal_math_axiom_audit " modulePrefix:ident : command =>
  auditModulePrefix modulePrefix.getId

end FormalMathQuality.AxiomAudit
