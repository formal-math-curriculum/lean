#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make_base() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock" "$root/QualityTests"
  cp "$ROOT/QualityTests/MigrationAfter.lean" "$root/QualityTests/MigrationAfter.lean"

  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000002","floc":"FLOC-P2-000003"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":1,"floc":2},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF

  cat > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-before","current_locator_refs":["FLOC-P2-000002"],"curriculum_link_refs":["FLINK-P2-000001"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"synthetic maintenance migration fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"identity intentionally stable across locator move"},"superseded_by":[],"supersedes":[],"title_or_summary":"Stable maintenance identity contract","verification_state":"regression_verified"}
EOF

  cat > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-before","declaration_names":["QualityTests.MigrationBefore.stableIdentityContract"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/MigrationBefore.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"superseded","module_name":"QualityTests.MigrationBefore","observed_at":"fixture-before","record_status":"superseded","repository":"formal-math-curriculum/lean","revision":"fixture-before","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":["FLOC-P2-000002"],"supersedes_locator_refs":[]}
{"created_revision":"fixture-after","declaration_names":["QualityTests.MigrationAfter.stableIdentityContract"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/MigrationAfter.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000002","locator_status":"current","module_name":"QualityTests.MigrationAfter","observed_at":"fixture-after","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-after","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":["FLOC-P2-000001"]}
EOF

  cat > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl" <<'EOF'
{"assumptions_or_formulation_notes":"synthetic maintenance treatment","candidate_lineage_resolution":{"resolution_context":"P1-CURR-v1 exact identity","resolution_path":["CAND-P1-000001"],"review_ref":"not_applicable","state":"resolved_exact"},"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","coverage_claim_scope":"maintenance fixture only","created_revision":"fixture-before","curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":"FART-P2-000001","id":"FLINK-P2-000001","link_confidence":"established","link_status":"current","record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"maintenance_fixture"}
EOF

  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":1,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-maintenance"}
EOF
  cat > "$root/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000001","record_status":"current","resolution_path":["CAND-P1-000001"],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["maintenance_fixture"]}
EOF
}

expect_reject() {
  local label="$1" signature="$2"; shift 2
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  [[ "$status" -ne 0 ]] || { printf 'maintenance-migration:fail:%s:unexpected-success\n' "$label" >&2; return 1; }
  grep -Fq "$signature" <<<"$output" || { printf 'maintenance-migration:fail:%s:missing=%s\n' "$label" "$signature" >&2; return 1; }
  printf 'maintenance-migration:pass:%s\n' "$label"
}

positive="$WORK/positive"
make_base "$positive"
lake exe traceability validate --root "$positive"
printf 'maintenance-migration:pass:stable-fart-locator-replacement\n'

# A naive migration that keeps the new module/file coordinate but points to the old module's
# declaration must not be accepted merely because the declaration name is similar.
incompatible="$WORK/incompatible"
make_base "$incompatible"
sed -i 's/QualityTests.MigrationAfter.stableIdentityContract/QualityTests.MigrationBefore.stableIdentityContract/' \
  "$incompatible/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_reject incompatible-origin 'traceability:error:resolve:declaration-module-mismatch' \
  lake exe traceability validate --root "$incompatible"

printf 'maintenance-migration:summary:pass\n'
