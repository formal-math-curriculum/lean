#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

printf 'm29-audit:start:reader-lock-identity-unresolved\n'
FIXTURE="$WORK/unresolved-lock"
mkdir -p "$FIXTURE/metadata/formal-artifacts/fart" \
  "$FIXTURE/metadata/formal-artifacts/floc" \
  "$FIXTURE/metadata/formal-artifacts/flink" \
  "$FIXTURE/metadata/curriculum-lock"

cat > "$FIXTURE/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000001","flink":"FLINK-P2-000001","floc":"FLOC-P2-000001"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":0,"flink":0,"floc":0},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF
cat > "$FIXTURE/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":1,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-audit-unresolved-lock"}
EOF
cat > "$FIXTURE/metadata/curriculum-lock/linked-identities.jsonl" <<'EOF'
{"candidate_ref_as_recorded":"CAND-P1-999001","candidate_ref_current_resolved":"CAND-P1-999001","record_status":"unresolved","resolution_path":["CAND-P1-999001"],"resolution_state":"needs_scope_review","schema_version":1,"treatment_scopes":["core"]}
EOF

# A curriculum-lock identity may legitimately remain unresolved without any Project-2 formalization records.
# If strong validation accepts this state, the reader's unresolved surface must not silently report zero.
lake exe traceability validate --root "$FIXTURE" > "$WORK/validate.log"
lake exe traceability inspect unresolved --root "$FIXTURE" > "$WORK/unresolved.raw"
tail -n 1 "$WORK/unresolved.raw" > "$WORK/unresolved.json"
python3 - "$WORK/unresolved.json" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p))
needle='CAND-P1-999001'
serialized=json.dumps(d,sort_keys=True,separators=(',',':'))
if d.get('result_state') == 'zero_matches' and needle not in serialized:
    print('m29-audit:confirmed:false-negative:authoritative-lock-identity-omitted')
    raise SystemExit(0)
print('m29-audit:not-confirmed:authoritative-lock-identity-visible-or-validation-changed')
raise SystemExit(2)
PY

printf 'm29-audit:start:path-filter-dependency-coverage\n'
# ReaderV2 directly imports NavigationV1 and ProvenanceV2; ProvenanceV2 and reader behavior also depend
# on shared traceability modules. Dedicated M2.9 workflows should either include semantic dependencies
# in their path filters or the permanent regression gate should execute the controls unconditionally.
python3 - "$ROOT/.github/workflows/m29-reader.yml" "$ROOT/.github/workflows/m29-traceability-scale.yml" "$ROOT/Quality/run-regression-tests.sh" <<'PY'
import sys
reader=open(sys.argv[1]).read()
scale=open(sys.argv[2]).read()
reg=open(sys.argv[3]).read()
missing_reader=[p for p in ['Traceability/NavigationV1.lean','Traceability/ProvenanceV2.lean','Traceability/Views.lean','Traceability/IntegrityV1.lean'] if p not in reader]
missing_scale=[p for p in ['Traceability/Views.lean','Traceability/IntegrityV1.lean','Traceability/RegistryV1.lean'] if p not in scale]
permanent_reader='check-traceability-reader-v2.sh' in reg
permanent_prov='check-traceability-provenance-v2.sh' in reg
if missing_reader and missing_scale and not permanent_reader and not permanent_prov:
    print('m29-audit:confirmed:gate-coverage-gap:reader=' + ','.join(missing_reader))
    print('m29-audit:confirmed:gate-coverage-gap:scale=' + ','.join(missing_scale))
    raise SystemExit(0)
print('m29-audit:not-confirmed:gate-coverage-closed')
raise SystemExit(2)
PY

printf 'm29-audit:summary:confirmed-candidate-findings\n'
