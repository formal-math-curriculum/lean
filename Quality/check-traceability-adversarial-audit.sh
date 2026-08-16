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
  local label="$1"
  shift
  printf 'traceability-audit:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -ne 0 ]]; then
    printf 'traceability-audit:unexpected-rejection:%s:exit=%d\n' "$label" "$status" >&2
    return 1
  fi
  printf 'traceability-audit:confirmed-false-accept:%s\n' "$label"
}

expect_reject_contains() {
  local label="$1"
  local signature="$2"
  shift 2
  printf 'traceability-audit:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'traceability-audit:unexpected-accept:%s\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'traceability-audit:wrong-rejection:%s:missing=%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'traceability-audit:control-rejection:%s\n' "$label"
}

# A1 — production-style `validate` does not resolve current declaration names.
case_missing_decl="$WORK/missing-declaration"
make_base "$case_missing_decl"
sed -i 's/QualityTests.TraceabilityFixture.fixtureTheorem/QualityTests.TraceabilityFixture.missingDeclaration/' \
  "$case_missing_decl/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_false_accept missing-current-declaration-validate \
  lake exe traceability validate --root "$case_missing_decl"
expect_reject_contains missing-current-declaration-roundtrip 'traceability:error:resolve:missing-declaration' \
  lake exe traceability roundtrip --root "$case_missing_decl"

# A2 — declaration existence in the combined environment is accepted even when the FLOC claims
# the declaration belongs to a different project module/file. The project module imports Mathlib,
# so Nat.add_comm is transitively visible.
case_wrong_origin="$WORK/wrong-declaration-origin"
make_base "$case_wrong_origin"
sed -i 's/QualityTests.TraceabilityFixture.fixtureTheorem/Nat.add_comm/' \
  "$case_wrong_origin/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_false_accept wrong-declaration-origin-roundtrip \
  lake exe traceability roundtrip --root "$case_wrong_origin"
query_wrong_origin="$(lake exe traceability query declaration Nat.add_comm --root "$case_wrong_origin")"
printf '%s\n' "$query_wrong_origin"
grep -Fq '"source_kind":"project_repository"' <<<"$query_wrong_origin"
grep -Fq '"module_name":"QualityTests.TraceabilityFixture"' <<<"$query_wrong_origin"
printf 'traceability-audit:confirmed-false-attribution:wrong-declaration-origin\n'

# A3 — file existence and module/declaration resolution are independent, allowing a FLOC to claim
# an arbitrary existing file while resolution succeeds against another module in the executing repo.
case_wrong_file="$WORK/wrong-file-module-pair"
make_base "$case_wrong_file"
printf '%s\n' '/- unrelated audit file -/' > "$case_wrong_file/Unrelated.lean"
sed -i 's#QualityTests/TraceabilityFixture.lean#Unrelated.lean#' \
  "$case_wrong_file/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_false_accept wrong-file-module-pair-validate \
  lake exe traceability validate --root "$case_wrong_file"
expect_false_accept wrong-file-module-pair-roundtrip \
  lake exe traceability roundtrip --root "$case_wrong_file"

# A4 — curriculum-lock non-success lineage is not reconciled against the FLINK. The lock says the
# candidate needs scope review after lineage change; the FLINK falsely claims exact/current.
case_lineage="$WORK/lineage-coercion"
make_base "$case_lineage"
cat > "$case_lineage/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"unresolved","resolution_path":["CAND-P1-000001","CAND-P1-000002"],"resolution_state":"needs_scope_review","schema_version":1,"treatment_scopes":["core"]}
EOF
expect_false_accept lock-lineage-coercion-validate \
  lake exe traceability validate --root "$case_lineage"
lineage_generate="$(lake exe traceability generate --root "$case_lineage")"
printf '%s\n' "$lineage_generate"
lineage_out="$(sed -n 's/^traceability:generate:pass:dir=\(.*\):fingerprint=.*/\1/p' <<<"$lineage_generate" | tail -n 1)"
[[ -n "$lineage_out" ]]
[[ ! -s "$lineage_out/unresolved.jsonl" ]]
printf 'traceability-audit:confirmed-silent-drop:lock-lineage-needs-scope-review\n'

# A5 — FLINK current-resolved candidate is not checked against the lock current resolution.
case_current_ref="$WORK/current-resolution-mismatch"
make_base "$case_current_ref"
sed -i 's/"candidate_ref_current_resolved":"CAND-P1-000001"/"candidate_ref_current_resolved":"CAND-P1-999999"/' \
  "$case_current_ref/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_false_accept current-candidate-resolution-mismatch \
  lake exe traceability validate --root "$case_current_ref"

# A6 — FLINK curriculum release is not required to equal the loaded curriculum-lock release.
case_release="$WORK/curriculum-release-mismatch"
make_base "$case_release"
sed -i 's/"curriculum_release_ref":"P1-CURR-v1"/"curriculum_release_ref":"P1-OTHER-v1"/' \
  "$case_release/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_false_accept curriculum-release-mismatch \
  lake exe traceability validate --root "$case_release"

# A7 — treatment/coverage scopes are only checked for non-null, so empty semantic scope is accepted.
case_empty_scope="$WORK/empty-scope"
make_base "$case_empty_scope"
sed -i 's/"coverage_claim_scope":"bounded theorem treatment"/"coverage_claim_scope":""/' \
  "$case_empty_scope/metadata/formal-artifacts/flink/000001-001000.jsonl"
sed -i 's/"treatment_scope":"core"/"treatment_scope":""/' \
  "$case_empty_scope/metadata/formal-artifacts/flink/000001-001000.jsonl"
expect_false_accept empty-treatment-and-coverage-scope \
  lake exe traceability validate --root "$case_empty_scope"

# A8 — a dependency locator can carry a fabricated revision; validation only requires a non-empty
# dependency baseline and resolution imports the selected current environment rather than the claimed revision.
case_dependency_revision="$WORK/dependency-revision-mismatch"
make_base "$case_dependency_revision"
cat > "$case_dependency_revision/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["Nat.add_comm"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","file_path":"Mathlib/Data/Nat/Basic.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"Mathlib.Data.Nat.Basic","observed_at":"fixture-current","record_status":"active","repository":"leanprover-community/mathlib4","revision":"deadbeef-not-the-selected-mathlib-revision","schema_version":1,"source_kind":"dependency_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
expect_false_accept dependency-revision-mismatch-validate \
  lake exe traceability validate --root "$case_dependency_revision"
expect_false_accept dependency-revision-mismatch-roundtrip \
  lake exe traceability roundtrip --root "$case_dependency_revision"

# A9 — FLOC lifecycle references are not checked for issued/existing target identities.
case_lifecycle="$WORK/dangling-locator-lifecycle"
make_base "$case_lifecycle"
sed -i 's/"supersedes_locator_refs":\[\]/"supersedes_locator_refs":["FLOC-P2-999999"]/' \
  "$case_lifecycle/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_false_accept dangling-floc-lifecycle-reference \
  lake exe traceability validate --root "$case_lifecycle"

printf 'traceability-audit:summary:confirmed-candidate-false-accepts\n'
