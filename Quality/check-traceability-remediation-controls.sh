#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make_base() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock" "$root/QualityTests"
  cp QualityTests/TraceabilityFixture.lean "$root/QualityTests/TraceabilityFixture.lean"
  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000002","floc":"FLOC-P2-000002"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":1,"floc":1},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF
  cat > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000001"],"curriculum_link_refs":["FLINK-P2-000001"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"remediation fixture proof","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"remediation fixture statement"},"superseded_by":[],"supersedes":[],"title_or_summary":"Remediation theorem representation","verification_state":"regression_verified"}
EOF
  cat > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
  cat > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl" <<'EOF'
{"assumptions_or_formulation_notes":"remediation theorem treatment","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"bounded theorem treatment","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000001","id":"FLINK-P2-000001","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"core"}
EOF
  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":1,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-remediation"}
EOF
  cat > "$root/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","record_status":"current","resolution_path":["CAND-P1-000001"],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["core"]}
EOF
}

expect_reject() {
  local label="$1" signature="$2"; shift 2
  printf 'traceability-remediation:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  [[ "$status" -ne 0 ]] || { printf 'traceability-remediation:fail:%s:unexpected-success\n' "$label" >&2; return 1; }
  grep -Fq "$signature" <<<"$output" || { printf 'traceability-remediation:fail:%s:missing=%s\n' "$label" "$signature" >&2; return 1; }
  printf 'traceability-remediation:pass:%s\n' "$label"
}

missing="$WORK/missing"; make_base "$missing"
sed -i 's/fixtureTheorem/missingDeclaration/' "$missing/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject blocker-000007-missing-current-declaration 'traceability:error:resolve:missing-declaration' lake exe traceability validate --root "$missing"

origin="$WORK/origin"; make_base "$origin"
sed -i 's/QualityTests.TraceabilityFixture.fixtureTheorem/Nat.add_comm/' "$origin/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject blocker-000008-wrong-declaration-origin 'traceability:error:resolve:declaration-module-mismatch' lake exe traceability validate --root "$origin"

wrongfile="$WORK/wrongfile"; make_base "$wrongfile"
printf '%s\n' '/- unrelated -/' > "$wrongfile/Unrelated.lean"
sed -i 's#QualityTests/TraceabilityFixture.lean#Unrelated.lean#' "$wrongfile/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject blocker-000008-wrong-module-file 'traceability:error:resolve:module-file-mismatch' lake exe traceability validate --root "$wrongfile"

lineage="$WORK/lineage"; make_base "$lineage"
cat > "$lineage/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"unresolved","resolution_path":["CAND-P1-000001","CAND-P1-000002"],"resolution_state":"needs_scope_review","schema_version":1,"treatment_scopes":["core"]}
EOF
expect_reject blocker-000009-lock-lineage-coercion 'traceability:error:curriculum-lock:current-resolution-mismatch' lake exe traceability validate --root "$lineage"

release="$WORK/release"; make_base "$release"
sed -i 's/"curriculum_release_ref":"P1-CURR-v1"/"curriculum_release_ref":"P1-OTHER-v1"/' "$release/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_reject blocker-000009-release-mismatch 'traceability:error:curriculum-lock:release-mismatch' lake exe traceability validate --root "$release"

dep="$WORK/dependency"; make_base "$dep"
cat > "$dep/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["Nat.add_comm"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","file_path":"Mathlib/Data/Nat/Basic.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"Mathlib.Data.Nat.Basic","observed_at":"fixture-current","record_status":"active","repository":"leanprover-community/mathlib4","revision":"deadbeef-not-selected","schema_version":1,"source_kind":"dependency_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
expect_reject blocker-000010-dependency-revision 'traceability:error:resolve:dependency-revision-mismatch' lake exe traceability validate --root "$dep"

backref="$WORK/backref"; make_base "$backref"
sed -i 's/"curriculum_link_refs":\["FLINK-P2-000001"\]/"curriculum_link_refs":[]/' "$backref/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_reject material-000012-missing-backref 'traceability:error:integrity:flink-missing-from-fart' lake exe traceability validate --root "$backref"

lifecycle="$WORK/lifecycle"; make_base "$lifecycle"
sed -i 's/"supersedes_locator_refs":\[\]/"supersedes_locator_refs":["FLOC-P2-999999"]/' "$lifecycle/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject material-000012-dangling-floc-lifecycle 'traceability:error:integrity:dangling-floc-supersedes' lake exe traceability validate --root "$lifecycle"

status="$WORK/status"; make_base "$status"
sed -i 's/"record_status":"active","repository"/"record_status":"historical","repository"/' "$status/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject material-000012-status-conflict 'traceability:error:integrity:current-floc-not-active' lake exe traceability validate --root "$status"

lockdup="$WORK/lockdup"; make_base "$lockdup"
cat "$lockdup/metadata/curriculum-lock/linked-identities.jsonl" >> "$lockdup/metadata/curriculum-lock/linked-identities.jsonl.tmp"
cat "$lockdup/metadata/curriculum-lock/linked-identities.jsonl" >> "$lockdup/metadata/curriculum-lock/linked-identities.jsonl.tmp"
mv "$lockdup/metadata/curriculum-lock/linked-identities.jsonl.tmp" "$lockdup/metadata/curriculum-lock/linked-identities.jsonl"
sed -i 's/"identity_count":1/"identity_count":2/' "$lockdup/metadata/curriculum-lock/manifest.json"
expect_reject material-000013-duplicate-lock-identity 'traceability:error:curriculum-lock:duplicate-recorded-identity' lake exe traceability validate --root "$lockdup"

scope="$WORK/scope"; make_base "$scope"
sed -i 's/"coverage_claim_scope":"bounded theorem treatment"/"coverage_claim_scope":""/' "$scope/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_reject material-000014-empty-coverage 'traceability:error:flink:empty-coverage_claim_scope' lake exe traceability validate --root "$scope"

baseline="$WORK/baseline"; make_base "$baseline"
sed -i 's/"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART/"dependency_baseline_ref":"P2-DEP-OTHER-v9","id":"FART/' "$baseline/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_reject material-000015-fart-baseline 'traceability:error:integrity:fart-dependency-baseline-mismatch' lake exe traceability validate --root "$baseline"

rename="$WORK/rename"; make_base "$rename"
sed -i 's/"candidate_ref_current_resolved":"CAND-P1-000001"/"candidate_ref_current_resolved":"CAND-P1-000002"/' "$rename/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"resolution_path":\["CAND-P1-000001"\]/"resolution_path":["CAND-P1-000001","CAND-P1-000002"]/' "$rename/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"state":"resolved_exact"/"state":"resolved_lineage"/' "$rename/metadata/formal-artifacts/flink/000001-001000.jsonl"
cat > "$rename/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"current","resolution_path":["CAND-P1-000001","CAND-P1-000002"],"resolution_state":"resolved_lineage","schema_version":1,"treatment_scopes":["core"]}
EOF
lake exe traceability validate --root "$rename" >/dev/null
lake exe traceability query curriculum CAND-P1-000002 --root "$rename" | grep -Fq '"candidate_ref_current_resolved":"CAND-P1-000002"'
printf 'traceability-remediation:pass:material-000011-current-resolved-query\n'

printf 'traceability-remediation:summary:pass\n'
