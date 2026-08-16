#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Strong validation of current project locators requires the governed source module in LEAN_PATH.
lake build --wfail +QualityTests.TraceabilityFixture

FIXTURE="$WORK/root"
mkdir -p "$FIXTURE/metadata/formal-artifacts/fart" \
  "$FIXTURE/metadata/formal-artifacts/floc" \
  "$FIXTURE/metadata/formal-artifacts/flink" \
  "$FIXTURE/metadata/curriculum-lock" \
  "$FIXTURE/QualityTests"
cp "$ROOT/QualityTests/TraceabilityFixture.lean" "$FIXTURE/QualityTests/TraceabilityFixture.lean"

python3 - "$FIXTURE" <<'PY'
import json, os, sys
root=sys.argv[1]
def dump(x): return json.dumps(x, sort_keys=True, separators=(',', ':'))
def write_json(path, obj):
    with open(path,'w') as f: f.write(dump(obj)+'\n')
def write_jsonl(path, rows):
    with open(path,'w') as f:
        for row in rows: f.write(dump(row)+'\n')

registry={
  "default_curriculum_baseline_ref":"P1-CURR-v1",
  "dependency_baseline_ref":"P2-DEP-M2.2-v1",
  "format":"formal-artifacts-jsonl-v1",
  "lean_toolchain_ref":"P2-ENV-M2.5-v1",
  "next_ids":{"fart":"FART-P2-000004","flink":"FLINK-P2-000003","floc":"FLOC-P2-000005"},
  "protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1",
  "record_counts":{"fart":3,"flink":2,"floc":4},
  "registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1",
  "registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
write_json(os.path.join(root,'metadata/formal-artifacts/registry.json'), registry)

farts=[
 {"artifact_kind":"theorem","created_revision":"reader-v2","current_locator_refs":["FLOC-P2-000001"],
  "curriculum_link_refs":["FLINK-P2-000001"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001",
  "lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active",
  "representation_state":"represented","schema_version":1,
  "source_provenance":{"proof_or_implementation_provenance_notes":"synthetic reader fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"synthetic reader fixture"},
  "superseded_by":[],"supersedes":[],"title_or_summary":"Lineage reader fixture","verification_state":"regression_verified"},
 {"artifact_kind":"example","created_revision":"reader-v2","current_locator_refs":["FLOC-P2-000003"],
  "curriculum_link_refs":["FLINK-P2-000002"],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000002",
  "lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active",
  "representation_state":"represented","schema_version":1,
  "source_provenance":{"proof_or_implementation_provenance_notes":"synthetic reader fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"synthetic reader fixture"},
  "superseded_by":[],"supersedes":[],"title_or_summary":"Second representation reader fixture","verification_state":"regression_verified"},
 {"artifact_kind":"theorem","created_revision":"reader-v2","current_locator_refs":[],
  "curriculum_link_refs":[],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000003",
  "lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"not_reviewed","record_status":"active",
  "representation_state":"represented","schema_version":1,
  "source_provenance":{"proof_or_implementation_provenance_notes":"synthetic unresolved reader fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"synthetic unresolved reader fixture"},
  "superseded_by":[],"supersedes":[],"title_or_summary":"Unresolved locator reader fixture","verification_state":"not_verified"}
]
write_jsonl(os.path.join(root,'metadata/formal-artifacts/fart/000001-001000.jsonl'), farts)

flocs=[
 {"created_revision":"reader-v2","declaration_names":["QualityTests.TraceabilityFixture.fixtureTheorem"],"dependency_baseline_ref":"not_applicable",
  "file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001",
  "locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"reader-v2","record_status":"active",
  "repository":"formal-math-curriculum/lean","revision":"reader-v2","schema_version":1,"source_kind":"project_repository","structural_anchors":[],
  "superseded_by_locator_refs":[],"supersedes_locator_refs":["FLOC-P2-000002"]},
 {"created_revision":"reader-v1-history","declaration_names":["QualityTests.TraceabilityOld.fixtureTheorem"],"dependency_baseline_ref":"not_applicable",
  "file_path":"QualityTests/TraceabilityOld.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000002",
  "locator_status":"historical","module_name":"QualityTests.TraceabilityOld","observed_at":"reader-v1-history","record_status":"historical",
  "repository":"formal-math-curriculum/lean","revision":"reader-v1-history","schema_version":1,"source_kind":"project_repository","structural_anchors":[],
  "superseded_by_locator_refs":["FLOC-P2-000001"],"supersedes_locator_refs":[]},
 {"created_revision":"reader-v2","declaration_names":["QualityTests.TraceabilityFixture.fixtureExample"],"dependency_baseline_ref":"not_applicable",
  "file_path":"QualityTests/TraceabilityFixture.lean","formal_artifact_ref":"FART-P2-000002","id":"FLOC-P2-000003",
  "locator_status":"current","module_name":"QualityTests.TraceabilityFixture","observed_at":"reader-v2","record_status":"active",
  "repository":"formal-math-curriculum/lean","revision":"reader-v2","schema_version":1,"source_kind":"project_repository","structural_anchors":[],
  "superseded_by_locator_refs":[],"supersedes_locator_refs":[]},
 {"created_revision":"reader-v2","declaration_names":["QualityTests.TraceabilityMissing.missingTheorem"],"dependency_baseline_ref":"not_applicable",
  "file_path":"QualityTests/TraceabilityMissing.lean","formal_artifact_ref":"FART-P2-000003","id":"FLOC-P2-000004",
  "locator_status":"unresolved","module_name":"QualityTests.TraceabilityMissing","observed_at":"reader-v2","record_status":"unresolved",
  "repository":"formal-math-curriculum/lean","revision":"reader-v2","schema_version":1,"source_kind":"project_repository","structural_anchors":[],
  "superseded_by_locator_refs":[],"supersedes_locator_refs":[]}
]
write_jsonl(os.path.join(root,'metadata/formal-artifacts/floc/000001-001000.jsonl'), flocs)

flinks=[
 {"assumptions_or_formulation_notes":"synthetic reader lineage link",
  "candidate_lineage_resolution":{"resolution_context":"reader lineage fixture","resolution_path":["CAND-P1-000001","CAND-P1-000002"],"review_ref":"not_applicable","state":"resolved_lineage"},
  "candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002",
  "coverage_claim_scope":"synthetic_nonproduction","created_revision":"reader-v2","curriculum_release_ref":"P1-CURR-v1",
  "formal_artifact_ref":"FART-P2-000001","id":"FLINK-P2-000001","link_confidence":"established","link_status":"current",
  "record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"core"},
 {"assumptions_or_formulation_notes":"synthetic second reader link",
  "candidate_lineage_resolution":{"resolution_context":"reader exact fixture","resolution_path":["CAND-P1-000002"],"review_ref":"not_applicable","state":"resolved_exact"},
  "candidate_ref_as_recorded":"CAND-P1-000002","candidate_ref_current_resolved":"CAND-P1-000002",
  "coverage_claim_scope":"synthetic_nonproduction","created_revision":"reader-v2","curriculum_release_ref":"P1-CURR-v1",
  "formal_artifact_ref":"FART-P2-000002","id":"FLINK-P2-000002","link_confidence":"established","link_status":"current",
  "record_status":"active","representation_relation":"represents","schema_version":1,"treatment_scope":"example"}
]
write_jsonl(os.path.join(root,'metadata/formal-artifacts/flink/000001-001000.jsonl'), flinks)

lock_manifest={"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":2,
 "mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-reader-v2"}
write_json(os.path.join(root,'metadata/curriculum-lock/manifest.json'), lock_manifest)
locks=[
 {"candidate_ref_as_recorded":"CAND-P1-000001","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"current",
  "resolution_path":["CAND-P1-000001","CAND-P1-000002"],"resolution_state":"resolved_lineage","schema_version":1,"treatment_scopes":["core"]},
 {"candidate_ref_as_recorded":"CAND-P1-000002","candidate_ref_current_resolved":"CAND-P1-000002","record_status":"current",
  "resolution_path":["CAND-P1-000002"],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["example"]}
]
write_jsonl(os.path.join(root,'metadata/curriculum-lock/linked-identities.jsonl'), locks)
PY

run_inspect() {
  local name="$1"; shift
  lake exe traceability "$@" > "$WORK/$name.raw"
  tail -n 1 "$WORK/$name.raw" > "$WORK/$name.json"
}

printf 'traceability-reader-v2:start:strong-validation\n'
lake exe traceability validate --root "$FIXTURE"
printf 'traceability-reader-v2:strong-validation:pass\n'

run_inspect zero inspect curriculum CAND-P1-999999 --root "$FIXTURE"
run_inspect recorded inspect curriculum CAND-P1-000001 --root "$FIXTURE"
run_inspect multi inspect curriculum CAND-P1-000002 --root "$FIXTURE"
run_inspect treatment_core inspect curriculum CAND-P1-000002 --root "$FIXTURE" --treatment core
run_inspect treatment_example inspect curriculum CAND-P1-000002 --treatment example --root "$FIXTURE"
run_inspect treatment_miss inspect curriculum CAND-P1-000002 --treatment missing --root "$FIXTURE"
run_inspect artifact inspect artifact FART-P2-000001 --root "$FIXTURE"
run_inspect source_module inspect source QualityTests.TraceabilityFixture --root "$FIXTURE"
run_inspect source_file inspect source QualityTests/TraceabilityFixture.lean --root "$FIXTURE"
run_inspect source_decl inspect source QualityTests.TraceabilityFixture.fixtureTheorem --root "$FIXTURE"
run_inspect unresolved inspect unresolved --root "$FIXTURE"

python3 - "$WORK" <<'PY'
import json, os, sys
w=sys.argv[1]
def load(name): return json.load(open(os.path.join(w,name+'.json')))
def require_envelope(d, kind, count, state):
    assert d['reader_contract_ref']=='P2-TRACE-M2.9-READER-v2', d
    assert d['authority']=='derived_read_only', d
    assert d['query_kind']==kind, d
    assert d['match_count']==count, d
    assert d['result_state']==state, d

z=load('zero'); require_envelope(z,'curriculum',0,'zero_matches')
r=load('recorded'); require_envelope(r,'curriculum',1,'matches')
assert r['results'][0]['match_reasons']==['recorded_identity']

m=load('multi'); require_envelope(m,'curriculum',2,'multiple_matches')
reasons=[x['match_reasons'] for x in m['results']]
assert ['current_resolved_identity'] in reasons, reasons
assert ['recorded_identity','current_resolved_identity'] in reasons, reasons

c=load('treatment_core'); require_envelope(c,'curriculum',1,'matches')
assert c['results'][0]['record']['link']['treatment_scope']=='core'
e=load('treatment_example'); require_envelope(e,'curriculum',1,'matches')
assert e['results'][0]['record']['link']['treatment_scope']=='example'
t=load('treatment_miss'); require_envelope(t,'curriculum',0,'zero_matches')

a=load('artifact'); require_envelope(a,'artifact',1,'matches')
counts=a['results'][0]['locator_counts']
assert counts=={'total':2,'current':1,'historical':1,'unresolved':0}, counts
assert a['results'][0]['curriculum_link_count']==1

sm=load('source_module'); require_envelope(sm,'source',2,'multiple_matches')
assert all('module_name' in x['match_reasons'] for x in sm['results'])
sf=load('source_file'); require_envelope(sf,'source',2,'multiple_matches')
assert all('file_path' in x['match_reasons'] for x in sf['results'])
sd=load('source_decl'); require_envelope(sd,'source',1,'matches')
assert sd['results'][0]['match_reasons']==['declaration_name']

u=load('unresolved'); require_envelope(u,'unresolved',1,'unresolved_present')
assert u['results'][0]['kind']=='floc'
print('traceability-reader-v2:envelope-matrix:pass')
PY

# Existing v1 query remains a JSONL record stream, not the v2 envelope.
lake exe traceability query curriculum CAND-P1-000002 --root "$FIXTURE" > "$WORK/query-v1.raw"
grep '^{' "$WORK/query-v1.raw" > "$WORK/query-v1.jsonl"
[[ "$(wc -l < "$WORK/query-v1.jsonl" | tr -d ' ')" == "2" ]]
if grep -Fq 'reader_contract_ref' "$WORK/query-v1.jsonl"; then
  printf 'traceability-reader-v2:fail:v1-query-shape-changed\n' >&2
  exit 1
fi
printf 'traceability-reader-v2:v1-query-compatibility:pass\n'

# Duplicate options must not be silently accepted.
set +e
dup_output="$(lake exe traceability inspect curriculum CAND-P1-000002 --treatment core --treatment example --root "$FIXTURE" 2>&1)"
dup_status=$?
set -e
[[ "$dup_status" -ne 0 ]]
grep -Fq 'duplicate --treatment' <<<"$dup_output"
printf 'traceability-reader-v2:duplicate-option-rejected:pass\n'

# Strong-validation errors remain failures and are never rewritten as reader zero-results.
BROKEN="$WORK/broken"
cp -a "$FIXTURE" "$BROKEN"
python3 - "$BROKEN/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'PY'
import json, sys
p=sys.argv[1]
rows=[json.loads(x) for x in open(p) if x.strip()]
rows[0]['declaration_names']=['QualityTests.TraceabilityFixture.missingDeclaration']
with open(p,'w') as f:
    for r in rows: f.write(json.dumps(r, sort_keys=True, separators=(',', ':'))+'\n')
PY
set +e
broken_output="$(lake exe traceability inspect curriculum CAND-P1-999999 --root "$BROKEN" 2>&1)"
broken_status=$?
set -e
[[ "$broken_status" -ne 0 ]]
grep -Fq 'traceability:error:resolve:missing-declaration' <<<"$broken_output"
if grep -Fq '"result_state":"zero_matches"' <<<"$broken_output"; then
  printf 'traceability-reader-v2:fail:validation-error-collapsed-to-zero\n' >&2
  exit 1
fi
printf 'traceability-reader-v2:strong-validation-failure-preserved:pass\n'

printf 'traceability-reader-v2:summary:pass\n'
