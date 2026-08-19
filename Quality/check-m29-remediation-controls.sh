#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fixture_sources=(
  Benchmarks/run-traceability-scaling.sh
  Benchmarks/run-reader-scaling.sh
  Quality/check-traceability-provenance-v2.sh
  Quality/check-traceability-reader-v2.sh
  Quality/check-maintenance-migration-controls.sh
)

printf 'm29-remediation:start:synthetic-source-namespace-separation\n'
for path in "${fixture_sources[@]}"; do
  if grep -Eq '(FART-P2-|FLOC-P2-|FLINK-P2-|CAND-P1-)' "$ROOT/$path"; then
    printf 'm29-remediation:fail:production-identity-in-synthetic-fixture:%s\n' "$path" >&2
    exit 1
  fi
  grep -Fq 'synthetic_fixture' "$ROOT/$path" || {
    printf 'm29-remediation:fail:missing-synthetic-fixture-marker:%s\n' "$path" >&2
    exit 1
  }
done
printf 'm29-remediation:pass:synthetic-source-namespace-separation\n'

make_zero_root() {
  local root="$1"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock"
  cat > "$root/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"SYNTHETIC-M2","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"SFART-M2-000001","flink":"SFLINK-M2-000001","floc":"SFLOC-M2-000001"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":0,"flink":0,"floc":0},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"synthetic_fixture","reservations":[],"schema_version":1,"shard_size":1000}
EOF
  : > "$root/metadata/formal-artifacts/fart/000001-001000.jsonl"
  : > "$root/metadata/formal-artifacts/floc/000001-001000.jsonl"
  : > "$root/metadata/formal-artifacts/flink/000001-001000.jsonl"
  cat > "$root/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"synthetic_fixture_authority","curriculum_release_ref":"SYNTHETIC-M2","identity_count":0,"mirror_status":"synthetic_fixture","schema_version":1,"source_refs":["SYNTHETIC-M2"],"verified_by_trace_record":"SYNTHETIC-M2-remediation"}
EOF
  : > "$root/metadata/curriculum-lock/linked-identities.jsonl"
}

GOOD="$WORK/good"
make_zero_root "$GOOD"
lake exe traceability validate --root "$GOOD" >/dev/null
printf 'm29-remediation:pass:synthetic-root-valid\n'

BAD_IDS="$WORK/bad-ids"
cp -a "$GOOD" "$BAD_IDS"
python3 - "$BAD_IDS/metadata/formal-artifacts/registry.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p))
d['next_ids']={'fart':'FART-P2-000001','flink':'FLINK-P2-000001','floc':'FLOC-P2-000001'}
open(p,'w').write(json.dumps(d,sort_keys=True,separators=(',',':'))+'\n')
PY
set +e
bad_ids_output="$(lake exe traceability validate --root "$BAD_IDS" 2>&1)"; bad_ids_status=$?
set -e
[[ "$bad_ids_status" -ne 0 ]] || { printf 'm29-remediation:fail:production-id-accepted-in-synthetic-mode\n' >&2; exit 1; }
grep -Fq 'invalid-id:FART-P2-000001' <<<"$bad_ids_output"
printf 'm29-remediation:pass:production-id-rejected-in-synthetic-mode\n'

BAD_AUTH="$WORK/bad-authority"
cp -a "$GOOD" "$BAD_AUTH"
python3 - "$BAD_AUTH/metadata/curriculum-lock/manifest.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['authority']='project1_external_authority'
open(p,'w').write(json.dumps(d,sort_keys=True,separators=(',',':'))+'\n')
PY
set +e
bad_auth_output="$(lake exe traceability validate --root "$BAD_AUTH" 2>&1)"; bad_auth_status=$?
set -e
[[ "$bad_auth_status" -ne 0 ]] || { printf 'm29-remediation:fail:project1-authority-accepted-in-synthetic-mode\n' >&2; exit 1; }
grep -Fq 'invalid-authority:project1_external_authority:synthetic_fixture_authority' <<<"$bad_auth_output"
printf 'm29-remediation:pass:project1-authority-rejected-in-synthetic-mode\n'

# SCALEFAIL-M2-000006: specialized gates must cover semantic dependencies, while permanent
# regression must execute the critical v2 controls without path filtering.
python3 - "$ROOT/.github/workflows/m29-reader.yml" "$ROOT/.github/workflows/m29-traceability-scale.yml" "$ROOT/Quality/run-regression-tests.sh" <<'PY'
import sys
reader=open(sys.argv[1]).read(); scale=open(sys.argv[2]).read(); reg=open(sys.argv[3]).read()
reader_required=['Traceability/NavigationV1.lean','Traceability/ProvenanceV2.lean','Traceability/Views.lean','Traceability/IntegrityV1.lean','Traceability/RegistryV1.lean']
scale_required=['Traceability/Views.lean','Traceability/IntegrityV1.lean','Traceability/RegistryV1.lean','Traceability/NavigationV1.lean']
assert all(x in reader for x in reader_required), reader_required
assert all(x in scale for x in scale_required), scale_required
assert 'check-traceability-reader-v2.sh' in reg
assert 'check-traceability-provenance-v2.sh' in reg
assert 'check-m29-remediation-controls.sh' in reg
PY
printf 'm29-remediation:pass:gate-coverage\n'
printf 'm29-remediation:summary:pass\n'
