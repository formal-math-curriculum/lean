#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

make_root() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock" "$root/QualityTests"
  cp "$ROOT/QualityTests/TraceabilityFixture.lean" "$root/QualityTests/TraceabilityFixture.lean"
  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000001","floc":"FLOC-P2-000002"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":0,"floc":1},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF
  cat > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["FLOC-P2-000001"],"curriculum_link_refs":[],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"provenance-v2 fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"provenance-v2 fixture"},"superseded_by":[],"supersedes":[],"title_or_summary":"Provenance v2 fixture theorem","verification_state":"regression_verified"}
EOF
  cat > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
  : > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl"
  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":0,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-provenance-v2"}
EOF
  : > "$root/metadata/curriculum-lock/linked-identities.jsonl"
}

root="$WORK/root"
make_root "$root"

printf 'traceability-provenance-v2:start:alternate-root-generate\n'
lake exe traceability generate --root "$root" >/dev/null
sha="$(git rev-parse HEAD)"
provenance="$root/.lake/build/traceability/$sha/provenance-v2.json"
[[ -f "$provenance" ]]
grep -Fq '"subject_kind":"alternate_root_content_snapshot"' "$provenance"
grep -Fq '"subject_revision":"not_applicable"' "$provenance"
grep -Fq '"freshness_contract":"content_bound"' "$provenance"
lake exe traceability freshness --root "$root" >/dev/null
printf 'traceability-provenance-v2:pass:alternate-root-no-revision-overclaim\n'

first_digest="$(git hash-object "$provenance")"
lake exe traceability generate --root "$root" >/dev/null
second_digest="$(git hash-object "$provenance")"
[[ "$first_digest" == "$second_digest" ]] || {
  printf 'traceability-provenance-v2:fail:nondeterministic-provenance:%s:%s\n' "$first_digest" "$second_digest" >&2
  exit 1
}
printf 'traceability-provenance-v2:pass:deterministic-regeneration:digest=%s\n' "$first_digest"

sed -i 's/Provenance v2 fixture theorem/Provenance v2 fixture theorem changed/' \
  "$root/metadata/formal-artifacts/fart/000001-001000.jsonl"
set +e
stale_output="$(lake exe traceability freshness --root "$root" 2>&1)"
stale_status=$?
set -e
[[ "$stale_status" -ne 0 ]] || {
  printf 'traceability-provenance-v2:fail:stale-input-unexpected-pass\n' >&2
  exit 1
}
grep -Fq 'traceability:freshness:error:authoritative-inputs-changed' <<<"$stale_output"
printf 'traceability-provenance-v2:pass:stale-authored-input-rejected\n'

lake exe traceability generate --root "$root" >/dev/null
lake exe traceability freshness --root "$root" >/dev/null
third_digest="$(git hash-object "$provenance")"
[[ "$third_digest" != "$first_digest" ]] || {
  printf 'traceability-provenance-v2:fail:changed-input-digest-not-changed\n' >&2
  exit 1
}
printf 'traceability-provenance-v2:pass:changed-input-new-fingerprint\n'

printf 'traceability-provenance-v2:summary:pass\n'
