#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make_base() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" \
    "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" \
    "$root/metadata/curriculum-lock" \
    "$root/QualityTests"
  cp QualityTests/TraceabilityFixture.lean "$root/QualityTests/TraceabilityFixture.lean"
  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000002","floc":"FLOC-P2-000002"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":1,"floc":1},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF
  cat > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000001"],"curriculum_link_refs":["FLINK-P2-000001"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"audit fixture proof","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"audit fixture statement"},"superseded_by":[],"supersedes":[],"title_or_summary":"Audit theorem representation","verification_state":"regression_verified"}
EOF
  cat > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
  cat > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl" <<'EOF'
{"assumptions_or_formulation_notes":"audit theorem treatment","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"bounded theorem treatment","created_revision":"fixture-current","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000001","id":"FLINK-P2-000001","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"core"}
EOF
  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":1,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-audit"}
EOF
  cat > "$root/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","record_status":"current","resolution_path":["CAND-P1-000001"],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["core"]}
EOF
}

expect_false_accept() {
  local label="$1"; shift
  printf 'traceability-audit2:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -ne 0 ]]; then
    printf 'traceability-audit2:unexpected-rejection:%s:exit=%d\n' "$label" "$status" >&2
    return 1
  fi
  printf 'traceability-audit2:confirmed-false-accept:%s\n' "$label"
}

expect_reject_contains() {
  local label="$1" signature="$2"; shift 2
  printf 'traceability-audit2:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'traceability-audit2:unexpected-accept:%s\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'traceability-audit2:wrong-rejection:%s:missing=%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'traceability-audit2:confirmed-rejection:%s\n' "$label"
}

# N1 — known-hard enum mutation is correctly rejected. This is a positive/null audit result.
case_enum="$WORK/invalid-enum"
make_base "$case_enum"
sed -i 's/"representation_state":"represented"/"representation_state":"made_up_state"/' \
  "$case_enum/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_reject_contains invalid-enum 'invalid-enum:made_up_state' \
  lake exe traceability validate --root "$case_enum"

# N2 — direct dangling FLINK→FART is correctly rejected.
case_dangling_flink="$WORK/dangling-flink"
make_base "$case_dangling_flink"
sed -i 's/"formal_artifact_ref":"FART-P2-000001"/"formal_artifact_ref":"FART-P2-999999"/' \
  "$case_dangling_flink/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_reject_contains dangling-flink-fart 'dangling-flink-fart:FLINK-P2-000001:FART-P2-999999' \
  lake exe traceability validate --root "$case_dangling_flink"

# A10 — FART's redundant current curriculum link list can omit a live/current FLINK.
case_reverse_link="$WORK/missing-fart-link-backref"
make_base "$case_reverse_link"
sed -i 's/"curriculum_link_refs":\["FLINK-P2-000001"\]/"curriculum_link_refs":[]/' \
  "$case_reverse_link/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_false_accept missing-fart-current-link-backref \
  lake exe traceability validate --root "$case_reverse_link"

# A11 — FART supersession targets may be syntactically valid but dangling.
case_fart_lifecycle="$WORK/dangling-fart-lifecycle"
make_base "$case_fart_lifecycle"
sed -i 's/"supersedes":\[\]/"supersedes":["FART-P2-999999"]/' \
  "$case_fart_lifecycle/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_false_accept dangling-fart-lifecycle-reference \
  lake exe traceability validate --root "$case_fart_lifecycle"

# A12 — contradictory current/historical status axes are accepted.
case_status="$WORK/status-conflict"
make_base "$case_status"
sed -i 's/"observed_at":"fixture-current","record_status":"active"/"observed_at":"fixture-current","record_status":"historical"/' \
  "$case_status/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_false_accept current-locator-historical-record-status \
  lake exe traceability validate --root "$case_status"

# A13 — lineage resolution_path is not decoded as an array of governed candidate IDs.
case_path="$WORK/malformed-resolution-path"
make_base "$case_path"
sed -i 's/"resolution_path":\["CAND-P1-000001"\]/"resolution_path":"not-an-array"/' \
  "$case_path/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_false_accept malformed-flink-resolution-path \
  lake exe traceability validate --root "$case_path"

# A14 — duplicate curriculum-lock identity rows are accepted when identity_count matches the duplicate count.
case_lock_dup="$WORK/duplicate-lock-identity"
make_base "$case_lock_dup"
cat "$case_lock_dup/metadata/curriculum-lock/linked-identities.jsonl" >> \
  "$case_lock_dup/metadata/curriculum-lock/linked-identities.tmp"
cat "$case_lock_dup/metadata/curriculum-lock/linked-identities.jsonl" >> \
  "$case_lock_dup/metadata/curriculum-lock/linked-identities.tmp"
mv "$case_lock_dup/metadata/curriculum-lock/linked-identities.tmp" \
  "$case_lock_dup/metadata/curriculum-lock/linked-identities.jsonl"
sed -i 's/"identity_count":1/"identity_count":2/' \
  "$case_lock_dup/metadata/curriculum-lock/manifest.json"
expect_false_accept duplicate-curriculum-lock-identity \
  lake exe traceability validate --root "$case_lock_dup"

# A15 — a fully consistent recorded→current lineage still cannot be found by the current candidate ID.
case_query="$WORK/current-query-miss"
make_base "$case_query"
sed -i 's/"candidate_ref_current_resolved":"CAND-P1-000001"/"candidate_ref_current_resolved":"CAND-P1-000002"/' \
  "$case_query/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"resolution_context":"P1-CURR-v1 exact identity"/"resolution_context":"governed rename"/' \
  "$case_query/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"resolution_path":\["CAND-P1-000001"\]/"resolution_path":["CAND-P1-000001","CAND-P1-000002"]/' \
  "$case_query/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"state":"resolved_exact"/"state":"resolved_lineage"/' \
  "$case_query/metadata/formal-artifacts/flink/000001-001000.jsonl"
cat > "$case_query/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"current","resolution_path":["CAND-P1-000001","CAND-P1-000002"],"resolution_state":"resolved_lineage","schema_version":1,"treatment_scopes":["core"]}
EOF
lake exe traceability validate --root "$case_query"
recorded_query="$(lake exe traceability query curriculum CAND-P1-000001 --root "$case_query")"
current_query="$(lake exe traceability query curriculum CAND-P1-000002 --root "$case_query")"
recorded_rows="$(grep '^{' <<<"$recorded_query" || true)"
current_rows="$(grep '^{' <<<"$current_query" || true)"
[[ -n "$recorded_rows" ]]
[[ -z "$current_rows" ]]
printf 'traceability-audit2:confirmed-current-query-miss:CAND-P1-000002\n'

# A16 — FART environment refs are not reconciled with the registry manifest baselines.
case_baseline="$WORK/fart-baseline-mismatch"
make_base "$case_baseline"
sed -i 's/"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART/"dependency_baseline_ref":"P2-DEP-OTHER-v9","id":"FART/' \
  "$case_baseline/metadata/formal-artifacts/fart/000001-001000.jsonl"
sed -i 's/"lean_toolchain_ref":"P2-ENV-M2.5-v1"/"lean_toolchain_ref":"P2-ENV-OTHER-v9"/' \
  "$case_baseline/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_false_accept fart-environment-baseline-mismatch \
  lake exe traceability validate --root "$case_baseline"

printf 'traceability-audit2:summary:pass\n'
