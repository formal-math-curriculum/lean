/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
-/
module

public import Traceability.Views

/-!
Truth-preserving curriculum navigation for M2.8 v1.

A curriculum query matches both the identity as originally recorded by the FLINK and the
Project-1-authoritative current-resolved identity. This preserves navigation across governed
candidate renames/splits without rewriting historical recorded identity.
-/

namespace FormalMathTraceability

private def matchesCurriculumId (record : Lean.Json) (candidateId : String) : Bool :=
  let recorded := match stringField "by-curriculum" record "candidate_ref_as_recorded" with
    | .ok id => id == candidateId
    | .error _ => false
  let current := match stringField "by-curriculum" record "candidate_ref_current_resolved" with
    | .ok id => id == candidateId
    | .error _ => false
  recorded || current

public def queryCurriculumV1 (data : RegistryData) (candidateId : String) : IO Unit := do
  for record in (← byCurriculum data).filter fun record => matchesCurriculumId record candidateId do
    IO.println (Lean.Json.compress record)

end FormalMathTraceability
