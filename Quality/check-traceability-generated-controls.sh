#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/metadata/formal-artifacts/fart" "$ROOT/metadata/formal-artifacts/floc" \
  "$ROOT/metadata/formal-artifacts/flink" "$ROOT/metadata/curriculum-lock" "$ROOT/QualityTests"
cp QualityTests/TraceabilityFixture.lean "$ROOT/QualityTests/TraceabilityFixture.lean"

cat > "$ROOT/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000005","flink":"FLINK-P2-000005","floc":"FLOC-P2-000006"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":4,"flink":4,"floc":5},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF

cat > "$ROOT/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000001"],"curriculum_link_refs":["FLINK-P2-000001"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"project fixture proof","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"project fixture statement"},"superseded_by":[],"supersedes":[],"title_or_summary":"Primary theorem representation","verification_state":"regression_verified"}
{"artifact_kind":"example","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000003"],"curriculum_link_refs":["FLINK-P2-000002"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000002","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"draft","record_status":"active","representation_state":"partial","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"project fixture example","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"example only"},"superseded_by":[],"supersedes":[],"title_or_summary":"Example representation","verification_state":"kernel_checked"}
{"artifact_kind":"model","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000004"],"curriculum_link_refs":["FLINK-P2-000003"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000003","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"draft","record_status":"active","representation_state":"partial","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"mathematical fixture model","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"not an empirical adequacy claim"},"superseded_by":[],"supersedes":[],"title_or_summary":"Science-facing model fixture","verification_state":"kernel_checked"}
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000005"],"curriculum_link_refs":["FLINK-P2-000004"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000004","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"direct mathlib representation","provenance_kind":"direct_dependency_representation","source_refs":["P2-DEP-M2.2-v1"],"statement_provenance_notes":"reuses upstream theorem directly"},"superseded_by":[],"supersedes":[],"title_or_summary":"Direct mathlib representation","verification_state":"kernel_checked"}
EOF

cat > "$ROOT/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":["FLOC-P2-000002"]}
{"created_revision":"fixture-old","declaration_names":["Fixture.Old.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"Fixture/Old.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000002","locator_status":"historical","module_name":"Fixture.Old","observed_at":"fixture-old","record_status":"historical","repository":"formal-math-curriculum/lean","revision":"fixture-old","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":["FLOC-P2-000001"],"supersedes_locator_refs":[]}
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureExample"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000002","id":"FLOC-P2-000003","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureModel"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000003","id":"FLOC-P2-000004","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
{"created_revision":"fixture-current","declaration_names":["Nat.add_comm"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","file_path":"Mathlib/Data/Nat/Basic.lean","formal_artifact_ref":"FART-P2-000004","id":"FLOC-P2-000005","locator_status":"current","module_name":"Mathlib.Data.Nat.Basic","observed_at":"fixture-current","record_status":"active","repository":"leanprover-community/mathlib4","revision":"db584cd6d46c92f209a44c0f1c829460d327499d","schema_version":1,"source_kind":"dependency_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF

cat > "$ROOT/metadata/formal-artifacts/flink/000001-001000.jsonl" <<'EOF'
{"assumptions_or_formulation_notes":"primary theorem treatment","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"bounded theorem treatment","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000001","id":"FLINK-P2-000001","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"core"}
{"assumptions_or_formulation_notes":"example only","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"example_only","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000002","id":"FLINK-P2-000002","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"example_of","schema_version":1,"treatment_scope":"example"}
{"assumptions_or_formulation_notes":"mathematical model only; no empirical adequacy claim","candidate_lineage_resolution":{"resolution_context":"candidate split requires treatment-scope review","resolution_path":["CAND-P1-000002"],"review_ref":"TRGAP-M2-fixture","state":"needs_scope_review"},"candidate_ref_as_recorded":"CAND-P1-000002","candidate_ref_current_resolved":"CAND-P1-000002","coverage_claim_scope":"model_assumptions_only","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000003","id":"FLINK-P2-000003","link_confidence":"provisional","link_status":"needs_review","record_status":"unresolved","representation_relation":"model_for","schema_version":1,"treatment_scope":"model"}
{"assumptions_or_formulation_notes":"direct upstream theorem representation","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"alternate theorem representation","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000004","id":"FLINK-P2-000004","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"core"}
EOF

cat > "$ROOT/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":2,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-fixture"}
EOF
cat > "$ROOT/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","record_status":"current","resolution_path":["CAND-P1-000001"],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["core","example"]}
{"candidate_ref_as_recorded":"CAND-P1-000002","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"unresolved","resolution_path":["CAND-P1-000002"],"resolution_state":"needs_scope_review","schema_version":1,"treatment_scopes":["model"]}
EOF

printf 'traceability-generated-control:start:validate\n'
lake exe traceability validate --root "$ROOT"

printf 'traceability-generated-control:start:roundtrip\n'
lake exe traceability roundtrip --root "$ROOT" | tee "$ROOT/roundtrip.log"
grep -Fq 'traceability:resolve:pass:current-modules=2;declarations=4' "$ROOT/roundtrip.log"
grep -Fq 'traceability:roundtrip:pass:links=4' "$ROOT/roundtrip.log"

printf 'traceability-generated-control:start:generate-1\n'
first_output="$(lake exe traceability generate --root "$ROOT")"
printf '%s\n' "$first_output"
first_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$first_output" | tail -n 1)"
[[ -n "$first_fingerprint" ]]
sha="$(git rev-parse HEAD)"
out="$ROOT/.lake/build/traceability/$sha"
for file in manifest.json by-curriculum.jsonl by-artifact.jsonl by-source.jsonl history.jsonl unresolved.jsonl index.md; do
  [[ -f "$out/$file" ]]
done
[[ "$(grep -c 'CAND-P1-000001' "$out/by-curriculum.jsonl")" -ge 3 ]]
grep -Fq '"representation_relation":"example_of"' "$out/by-curriculum.jsonl"
grep -Fq '"coverage_claim_scope":"example_only"' "$out/by-curriculum.jsonl"
grep -Fq '"kind":"flink"' "$out/unresolved.jsonl"
grep -Fq '"needs_scope_review"' "$out/unresolved.jsonl"
grep -Fq '"id":"FLOC-P2-000002"' "$out/history.jsonl"
grep -Fq '"repository":"leanprover-community/mathlib4"' "$out/by-source.jsonl"
grep -Fq '"revision":"db584cd6d46c92f209a44c0f1c829460d327499d"' "$out/by-source.jsonl"
grep -Fq 'no empirical adequacy claim' "$out/by-curriculum.jsonl"

printf 'traceability-generated-control:start:queries\n'
[[ "$(lake exe traceability query curriculum CAND-P1-000001 --root "$ROOT" | grep -c 'CAND-P1-000001')" -ge 3 ]]
lake exe traceability query artifact FART-P2-000001 --root "$ROOT" | grep -Fq 'FART-P2-000001'
lake exe traceability query declaration QualityTests.TraceabilityFixture.fixtureTheorem --root "$ROOT" | grep -Fq 'FLOC-P2-000001'
lake exe traceability query declaration Nat.add_comm --root "$ROOT" | grep -Fq 'FLOC-P2-000005'

printf 'traceability-generated-control:start:delete-rebuild\n'
rm -rf "$out"
second_output="$(lake exe traceability generate --root "$ROOT")"
printf '%s\n' "$second_output"
second_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$second_output" | tail -n 1)"
[[ "$first_fingerprint" == "$second_fingerprint" ]]

printf 'traceability-generated-control:start:manual-generated-mutation\n'
printf 'manual mutation\n' >> "$out/index.md"
third_output="$(lake exe traceability generate --root "$ROOT")"
third_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$third_output" | tail -n 1)"
[[ "$first_fingerprint" == "$third_fingerprint" ]]
! grep -Fq 'manual mutation' "$out/index.md"

printf 'traceability-generated-control:start:authoritative-input-mutation\n'
sed -i 's/Primary theorem representation/Primary theorem representation changed/' "$ROOT/metadata/formal-artifacts/fart/000001-001000.jsonl"
fourth_output="$(lake exe traceability generate --root "$ROOT")"
fourth_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$fourth_output" | tail -n 1)"
[[ "$fourth_fingerprint" != "$first_fingerprint" ]]

printf 'traceability-generated-control:start:stale-lock-visible\n'
sed -i 's/"mirror_status":"verified_snapshot"/"mirror_status":"stale_snapshot"/' "$ROOT/metadata/curriculum-lock/manifest.json"
lake exe traceability generate --root "$ROOT" >/dev/null
grep -Fq '"kind":"curriculum_lock"' "$out/unresolved.jsonl"

echo 'traceability-generated-control:summary:pass'
