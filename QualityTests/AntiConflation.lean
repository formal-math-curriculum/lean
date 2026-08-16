/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

import FormalMath.Basic

/-!
# Anti-conflation regression contract

A test-only model for FORMREQ-P1-000018. It deliberately keeps curriculum state and formal/software
state in separate structures and proves that representative formal operations preserve curriculum
truth. This is **not** the serialization/schema chosen for Curriculum or FART/FLOC/FLINK data; M2.8
retains authority over production traceability metadata.
-/

namespace FormalMathQualityTests.AntiConflation

private structure CurriculumState where
  candidateId : String
  rank : String
  level : String
  readiness : List String
  reqExpr : String
  importance : String
  confidence : String
  candidateLineage : List String
  deriving Repr, BEq

private structure FormalState where
  imports : List String
  theoremDependencies : List String
  encodings : List String
  formalStatus : String
  candidateRef : String
  modelAssumptions : List String
  empiricalTruthClaim : Bool
  deriving Repr, BEq

private structure CombinedState where
  curriculum : CurriculumState
  formal : FormalState
  deriving Repr, BEq

private def addImport (s : CombinedState) (dep : String) : CombinedState :=
  { s with formal := { s.formal with imports := dep :: s.formal.imports } }

private def addTheoremDependency (s : CombinedState) (dep : String) : CombinedState :=
  { s with formal := { s.formal with theoremDependencies := dep :: s.formal.theoremDependencies } }

private def addEncoding (s : CombinedState) (encoding : String) : CombinedState :=
  { s with formal := { s.formal with encodings := encoding :: s.formal.encodings } }

private def repointFormalCandidateRef (s : CombinedState) (candidateRef : String) : CombinedState :=
  { s with formal := { s.formal with candidateRef := candidateRef } }

private def setFormalStatus (s : CombinedState) (status : String) : CombinedState :=
  { s with formal := { s.formal with formalStatus := status } }

/-- FORMREQ-018.1: software import changes do not synthesize learner readiness. -/
private theorem importEdge_preserves_curriculum (s : CombinedState) (dep : String) :
    (addImport s dep).curriculum = s.curriculum := rfl

/-- FORMREQ-018.2: theorem-dependency changes do not synthesize rank or Level changes. -/
private theorem theoremDependency_preserves_curriculum (s : CombinedState) (dep : String) :
    (addTheoremDependency s dep).curriculum = s.curriculum := rfl

/-- FORMREQ-018.3: another formal encoding does not create another curriculum identity. -/
private theorem secondEncoding_preserves_candidate (s : CombinedState) (encoding : String) :
    (addEncoding s encoding).curriculum.candidateId = s.curriculum.candidateId := rfl

/-- FORMREQ-018.4: formal-link repointing across a governed rename does not erase curriculum lineage. -/
private theorem formalRepoint_preserves_lineage (s : CombinedState) (candidateRef : String) :
    (repointFormalCandidateRef s candidateRef).curriculum.candidateLineage =
      s.curriculum.candidateLineage := rfl

private def scienceModelFixture : CombinedState :=
  { curriculum :=
      { candidateId := "CAND-fixture-science"
        rank := "Field"
        level := "L4-L6"
        readiness := ["READY-fixture"]
        reqExpr := "all_of(READY-fixture)"
        importance := "core-in-scope"
        confidence := "fixture"
        candidateLineage := ["CAND-fixture-science"] }
    formal :=
      { imports := []
        theoremDependencies := []
        encodings := ["FART-fixture-model"]
        formalStatus := "represented"
        candidateRef := "CAND-fixture-science"
        modelAssumptions := ["continuum approximation", "idealized boundary conditions"]
        empiricalTruthClaim := false } }

/-- FORMREQ-018.5: a formalized model carries assumptions without asserting empirical truth. -/
private theorem scienceModel_retains_boundary :
    !scienceModelFixture.formal.modelAssumptions.isEmpty ∧
      scienceModelFixture.formal.empiricalTruthClaim = false := by
  decide

/-- FORMREQ-018.6: missing/unknown formalization status does not downgrade curriculum assessment. -/
private theorem missingFormalization_preserves_curriculum (s : CombinedState) :
    (setFormalStatus s "missing").curriculum = s.curriculum := rfl

/-- FORMREQ-018.7: proof dependencies do not collapse readiness `any_of` route semantics. -/
private theorem proofDependency_preserves_reqExpr (s : CombinedState) (dep : String) :
    (addTheoremDependency s dep).curriculum.reqExpr = s.curriculum.reqExpr := rfl

end FormalMathQualityTests.AntiConflation
