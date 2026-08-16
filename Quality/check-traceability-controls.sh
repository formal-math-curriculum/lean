#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

BASE_REGISTRY='{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000001","floc":"FLOC-P2-000003"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":0,"floc":2},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}'
FART='{"artifact_kind":"theorem","created_revision":"fixture-r2","current_locator_refs":["FLOC-P2-000002"],"curriculum_link_refs":[],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"draft","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"fixture"},"superseded_by":[],"supersedes":[],"title_or_summary":"Fixture theorem","verification_state":"kernel_checked"}'
FLOC1='{"created_revision":"fixture-registry","declaration_names":["Fixture.old"],"dependency_baseline_ref":"not_applicable","file_path":"Fixture/Old.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"historical","module_name":"Fixture.Old","observed_at":"fixture-r1","record_status":"historical","repository":"formal-math-curriculum/lean","revision":"fixture-r1","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":["FLOC-P2-000002"],"supersedes_locator_refs":[]}'
FLOC2='{"created_revision":"fixture-registry","declaration_names":["Fixture.current"],"dependency_baseline_ref":"not_applicable","file_path":"Fixture/Current.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000002","locator_status":"current","module_name":"Fixture.Current","observed_at":"fixture-r2","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-r2","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":["FLOC-P2-000001"]}'
LOCK='{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":0,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-000001"}'

make_valid_root() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/curriculum-lock" "$root/Fixture"
  printf '%s\n' "$BASE_REGISTRY" > "$root/metadata/formal-artifacts/registry.json"
  printf '%s\n' "$FART" > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl"
  printf '%s\n%s\n' "$FLOC1" "$FLOC2" > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl"
  printf '%s\n' "$LOCK" > "$root/metadata/curriculum-lock/manifest.json"
  : > "$root/metadata/curriculum-lock/linked-identities.jsonl"
  printf '/- fixture source target -/\n' > "$root/Fixture/Current.lean"
}

expect_pass() {
  local label="$1" root="$2"
  printf 'traceability-control:start:%s\n' "$label"
  if lake exe traceability validate --root "$root"; then
    printf 'traceability-control:pass:%s\n' "$label"
  else
    local status=$?
    printf 'traceability-control:fail:%s:exit=%d\n' "$label" "$status" >&2
    return "$status"
  fi
}

expect_fail_contains() {
  local label="$1" signature="$2" root="$3"
  printf 'traceability-control:start:%s\n' "$label"
  set +e
  local output
  output="$(lake exe traceability validate --root "$root" 2>&1)"
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'traceability-control:fail:%s:unexpected-success\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'traceability-control:fail:%s:missing-signature:%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'traceability-control:expected-fail:%s:exit=%d\n' "$label" "$status"
}

valid="$TMP_ROOT/valid"
make_valid_root "$valid"
expect_pass locator-move-preserves-fart "$valid"

duplicate="$TMP_ROOT/duplicate"
cp -R "$valid" "$duplicate"
printf '%s\n' "$FART" >> "$duplicate/metadata/formal-artifacts/fart/000001-001000.jsonl"
sed -i 's/"fart":1/"fart":2/' "$duplicate/metadata/formal-artifacts/registry.json"
expect_fail_contains duplicate-fart 'duplicate-id:FART-P2-000001' "$duplicate"

dangling="$TMP_ROOT/dangling"
cp -R "$valid" "$dangling"
sed -i 's/"formal_artifact_ref":"FART-P2-000001"/"formal_artifact_ref":"FART-P2-000002"/g' \
  "$dangling/metadata/formal-artifacts/floc/000001-001000.jsonl"
expect_fail_contains dangling-floc 'dangling-floc-fart:FLOC-P2-000001:FART-P2-000002' "$dangling"

path_identity="$TMP_ROOT/path-identity"
cp -R "$valid" "$path_identity"
sed -i 's/"id":"FART-P2-000001"/"id":"FormalMath.Basic"/' \
  "$path_identity/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_fail_contains path-derived-identity 'invalid-id:FormalMath.Basic' "$path_identity"

conflated="$TMP_ROOT/conflated"
cp -R "$valid" "$conflated"
sed -i 's/"dependency_baseline_ref":"P2-DEP-M2.2-v1","id"/"dependency_baseline_ref":"P2-DEP-M2.2-v1","formalized":true,"id"/' \
  "$conflated/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_fail_contains conflated-formalized 'forbidden-conflated-field:formalized' "$conflated"

noncanonical="$TMP_ROOT/noncanonical"
cp -R "$valid" "$noncanonical"
sed -i 's/{"artifact_kind"/{ "artifact_kind"/' \
  "$noncanonical/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_fail_contains noncanonical-jsonl 'noncanonical-jsonl' "$noncanonical"

printf 'traceability-control:summary:pass\n'
