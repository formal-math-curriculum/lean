#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

lake build --wfail +QualityTests.TraceabilityFixture

make_root() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock" "$root/QualityTests"
  cp "$ROOT/QualityTests/TraceabilityFixture.lean" "$root/QualityTests/TraceabilityFixture.lean"
  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"SYNTHETIC-M2","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"SFART-M2-000002","flink":"SFLINK-M2-000001","floc":"SFLOC-M2-000002"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":0,"floc":1},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"synthetic_fixture","reservations":[],"schema_version":1,"shard_size":1000}
EOF
  cat > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"fixture-current","current_locator_refs":["SFLOC-M2-000001"],"curriculum_link_refs":[],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"SFART-M2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"provenance-v2 synthetic fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"provenance-v2 synthetic fixture"},"superseded_by":[],"supersedes":[],"title_or_summary":"Provenance v2 synthetic fixture theorem","verification_state":"regression_verified"}
EOF
  cat > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"fixture-current","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"SFART-M2-000001","id":"SFLOC-M2-000001","locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"fixture-current","record_status":"active","repository":"formal-math-curriculum/lean","revision":"fixture-current","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
EOF
  : > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl"
  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"synthetic_fixture_authority","curriculum_release_ref":"SYNTHETIC-M2","identity_count":0,"mirror_status":"synthetic_fixture","schema_version":1,"source_refs":["SYNTHETIC-M2"],"verified_by_trace_record":"SYNTHETIC-M2-provenance-v2"}
EOF
  : > "$root/metadata/curriculum-lock/linked-identities.jsonl"
}

expect_freshness_reject() {
  local root="$1" signature="$2" label="$3"
  set +e
  local output
  output="$(lake exe traceability freshness --root "$root" 2>&1)"
  local status=$?
  set -e
  [[ "$status" -ne 0 ]] || { printf 'traceability-provenance-v2:fail:%s:unexpected-pass\n' "$label" >&2; exit 1; }
  grep -Fq "$signature" <<<"$output" || { printf '%s\n' "$output" >&2; exit 1; }
  printf 'traceability-provenance-v2:pass:%s\n' "$label"
}

root="$WORK/root"
make_root "$root"

printf 'traceability-provenance-v2:start:alternate-root-generate\n'
lake exe traceability validate --root "$root" >/dev/null
lake exe traceability generate --root "$root" >/dev/null
sha="$(git rev-parse HEAD)"
out="$root/.lake/build/traceability/$sha"
legacy="$out/manifest.json"
provenance="$out/provenance-v2.json"
[[ -f "$legacy" && -f "$provenance" ]]
grep -Fq '"repository":"not_applicable"' "$legacy"
grep -Fq '"subject_revision":"not_applicable"' "$legacy"
grep -Fq '"subject_context":"alternate_root_content_snapshot"' "$legacy"
grep -Fq '"deterministic_source_time":"not_applicable"' "$legacy"
grep -Fq '"subject_kind":"alternate_root_content_snapshot"' "$provenance"
grep -Fq '"subject_revision":"not_applicable"' "$provenance"
grep -Fq '"freshness_contract":"content_and_projection_bound"' "$provenance"
grep -Fq '"generated_output_fingerprint"' "$provenance"
grep -Fq '"legacy_manifest_fingerprint"' "$provenance"
if grep -Fq "$WORK" "$provenance"; then
  printf 'traceability-provenance-v2:fail:path-dependent-absolute-root\n' >&2; exit 1
fi
lake exe traceability freshness --root "$root" >/dev/null
printf 'traceability-provenance-v2:pass:alternate-root-no-revision-overclaim\n'

# Sidecar contract itself is validated.
python3 - "$provenance" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['freshness_contract']='timestamp_only'
open(p,'w').write(json.dumps(d,sort_keys=True,separators=(',',':'))+'\n')
PY
expect_freshness_reject "$root" 'freshness_contract-mismatch:timestamp_only:content_and_projection_bound' tampered-sidecar-rejected
lake exe traceability generate --root "$root" >/dev/null

# Derived output mutation and legacy-manifest mutation are both freshness relevant.
printf '\nmanual generated mutation\n' >> "$out/index.md"
expect_freshness_reject "$root" 'traceability:freshness:error:generated-outputs-changed' generated-output-mutation-rejected
lake exe traceability generate --root "$root" >/dev/null
python3 - "$legacy" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['result_state']='tampered'
open(p,'w').write(json.dumps(d,sort_keys=True,separators=(',',':'))+'\n')
PY
expect_freshness_reject "$root" 'traceability:freshness:error:legacy-manifest-changed' legacy-manifest-mutation-rejected
lake exe traceability generate --root "$root" >/dev/null

# Same authoritative inputs regenerate deterministically.
first_digest="$(git hash-object "$provenance")"
lake exe traceability generate --root "$root" >/dev/null
second_digest="$(git hash-object "$provenance")"
[[ "$first_digest" == "$second_digest" ]] || { printf 'traceability-provenance-v2:fail:nondeterministic-provenance\n' >&2; exit 1; }
printf 'traceability-provenance-v2:pass:deterministic-regeneration:digest=%s\n' "$first_digest"

fart_dir="$root/metadata/formal-artifacts/fart"
# Filename change must stale provenance.
mv "$fart_dir/000001-001000.jsonl" "$fart_dir/000101-001100.jsonl"
expect_freshness_reject "$root" 'traceability:freshness:error:registry-inputs-changed' shard-rename-rejected
mv "$fart_dir/000101-001100.jsonl" "$fart_dir/000001-001000.jsonl"
lake exe traceability freshness --root "$root" >/dev/null

# SCALEFAIL-M2-000002 regression: preserve filename+bytes but move it under a nested relative path.
# Path-bound provenance must reject the relocation before regeneration.
mkdir -p "$fart_dir/archive"
mv "$fart_dir/000001-001000.jsonl" "$fart_dir/archive/000001-001000.jsonl"
expect_freshness_reject "$root" 'traceability:freshness:error:registry-inputs-changed' same-filename-shard-relocation-rejected
mv "$fart_dir/archive/000001-001000.jsonl" "$fart_dir/000001-001000.jsonl"
rmdir "$fart_dir/archive"
lake exe traceability freshness --root "$root" >/dev/null

# Authored content change must stale provenance and yield a new fingerprint after regeneration.
sed -i 's/Provenance v2 synthetic fixture theorem/Provenance v2 synthetic fixture theorem changed/' \
  "$root/metadata/formal-artifacts/fart/000001-001000.jsonl"
expect_freshness_reject "$root" 'traceability:freshness:error:registry-inputs-changed' stale-authored-input-rejected
lake exe traceability generate --root "$root" >/dev/null
lake exe traceability freshness --root "$root" >/dev/null
third_digest="$(git hash-object "$provenance")"
[[ "$third_digest" != "$first_digest" ]] || { printf 'traceability-provenance-v2:fail:changed-input-digest-not-changed\n' >&2; exit 1; }
printf 'traceability-provenance-v2:pass:changed-input-new-fingerprint\n'

printf 'traceability-provenance-v2:summary:pass\n'
