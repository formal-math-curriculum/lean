#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
OUT="$ROOT/.lake/build/reader-v2"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"

lake build --wfail +QualityTests.TraceabilityFixture

FIXTURE="$WORK/root"
mkdir -p "$FIXTURE/metadata/formal-artifacts/fart" "$FIXTURE/metadata/formal-artifacts/floc" \
  "$FIXTURE/metadata/formal-artifacts/flink" "$FIXTURE/metadata/curriculum-lock" "$FIXTURE/QualityTests"
cp "$ROOT/QualityTests/TraceabilityFixture.lean" "$FIXTURE/QualityTests/TraceabilityFixture.lean"

python3 - "$FIXTURE" <<'PY'
import json, os, sys
root=sys.argv[1]
def dump(x): return json.dumps(x,sort_keys=True,separators=(',',':'))
def write_json(p,x): open(p,'w').write(dump(x)+'\n')
def write_jsonl(p,xs): open(p,'w').write(''.join(dump(x)+'\n' for x in xs))
def fart(i,kind,locs,links,title,q='reviewed',v='regression_verified'):
  return {'artifact_kind':kind,'created_revision':'reader-v2','current_locator_refs':locs,'curriculum_link_refs':links,
    'dependency_baseline_ref':'P2-DEP-M2.2-v1','id':f'FART-P2-{i:06d}','lean_toolchain_ref':'P2-ENV-M2.5-v1',
    'quality_state':q,'record_status':'active','representation_state':'represented','schema_version':1,
    'source_provenance':{'proof_or_implementation_provenance_notes':'synthetic reader fixture','provenance_kind':'original_project',
      'source_refs':[],'statement_provenance_notes':'synthetic reader fixture'},'superseded_by':[],'supersedes':[],
    'title_or_summary':title,'verification_state':v}
def floc(i,fart_id,status,module,file,decls,supersedes=None,superseded_by=None):
  return {'created_revision':'reader-v2','declaration_names':decls,'dependency_baseline_ref':'not_applicable','file_path':file,
    'formal_artifact_ref':fart_id,'id':f'FLOC-P2-{i:06d}','locator_status':status,'module_name':module,'observed_at':'reader-v2',
    'record_status':status if status in ('historical','unresolved') else 'active','repository':'formal-math-curriculum/lean',
    'revision':'reader-v2','schema_version':1,'source_kind':'project_repository','structural_anchors':[],
    'superseded_by_locator_refs':superseded_by or [],'supersedes_locator_refs':supersedes or []}
def flink(i,fart_id,recorded,current,state,path,treatment):
  return {'assumptions_or_formulation_notes':'synthetic reader link','candidate_lineage_resolution':{
      'resolution_context':'reader-v2 fixture','resolution_path':path,'review_ref':'not_applicable','state':state},
    'candidate_ref_as_recorded':recorded,'candidate_ref_current_resolved':current,'coverage_claim_scope':'synthetic_nonproduction',
    'created_revision':'reader-v2','curriculum_release_ref':'P1-CURR-v1','formal_artifact_ref':fart_id,'id':f'FLINK-P2-{i:06d}',
    'link_confidence':'established','link_status':'current','record_status':'active','representation_relation':'represents',
    'schema_version':1,'treatment_scope':treatment}
registry={'default_curriculum_baseline_ref':'P1-CURR-v1','dependency_baseline_ref':'P2-DEP-M2.2-v1','format':'formal-artifacts-jsonl-v1',
 'lean_toolchain_ref':'P2-ENV-M2.5-v1','next_ids':{'fart':'FART-P2-000004','flink':'FLINK-P2-000003','floc':'FLOC-P2-000005'},
 'protocol_ref':'P2-TRACE-M2.8-PROTOCOL-v1','record_counts':{'fart':3,'flink':2,'floc':4},
 'registry_semantics_ref':'P2-TRACE-M2.8-REGISTRY-v1','registry_status':'active','reservations':[],'schema_version':1,'shard_size':1000}
write_json(os.path.join(root,'metadata/formal-artifacts/registry.json'),registry)
write_jsonl(os.path.join(root,'metadata/formal-artifacts/fart/000001-001000.jsonl'),[
 fart(1,'theorem',['FLOC-P2-000001'],['FLINK-P2-000001'],'Lineage reader fixture'),
 fart(2,'example',['FLOC-P2-000003'],['FLINK-P2-000002'],'Second representation reader fixture'),
 fart(3,'theorem',[],[],'Unresolved locator reader fixture','not_assessed','not_checked')])
write_jsonl(os.path.join(root,'metadata/formal-artifacts/floc/000001-001000.jsonl'),[
 floc(1,'FART-P2-000001','current','QualityTests.TraceabilityFixture','QualityTests/TraceabilityFixture.lean',
      ['QualityTests.TraceabilityFixture.fixtureTheorem'],['FLOC-P2-000002']),
 floc(2,'FART-P2-000001','historical','QualityTests.TraceabilityOld','QualityTests/TraceabilityOld.lean',
      ['QualityTests.TraceabilityOld.fixtureTheorem'],[],['FLOC-P2-000001']),
 floc(3,'FART-P2-000002','current','QualityTests.TraceabilityFixture','QualityTests/TraceabilityFixture.lean',
      ['QualityTests.TraceabilityFixture.fixtureExample']),
 floc(4,'FART-P2-000003','unresolved','QualityTests.TraceabilityMissing','QualityTests/TraceabilityMissing.lean',
      ['QualityTests.TraceabilityMissing.missingTheorem'])])
write_jsonl(os.path.join(root,'metadata/formal-artifacts/flink/000001-001000.jsonl'),[
 flink(1,'FART-P2-000001','CAND-P1-000001','CAND-P1-000002','resolved_lineage',['CAND-P1-000001','CAND-P1-000002'],'core'),
 flink(2,'FART-P2-000002','CAND-P1-000002','CAND-P1-000002','resolved_exact',['CAND-P1-000002'],'example')])
write_json(os.path.join(root,'metadata/curriculum-lock/manifest.json'),{
 'authority':'project1_external_authority','curriculum_release_ref':'P1-CURR-v1','identity_count':2,'mirror_status':'verified_snapshot',
 'schema_version':1,'source_refs':['P1-CURR-v1','P1-P2-HANDOFF-v1'],'verified_by_trace_record':'TRVER-M2-reader-v2'})
write_jsonl(os.path.join(root,'metadata/curriculum-lock/linked-identities.jsonl'),[
 {'candidate_ref_as_recorded':'CAND-P1-000001','candidate_ref_current_resolved':'CAND-P1-000002','record_status':'current',
  'resolution_path':['CAND-P1-000001','CAND-P1-000002'],'resolution_state':'resolved_lineage','schema_version':1,'treatment_scopes':['core']},
 {'candidate_ref_as_recorded':'CAND-P1-000002','candidate_ref_current_resolved':'CAND-P1-000002','record_status':'current',
  'resolution_path':['CAND-P1-000002'],'resolution_state':'resolved_exact','schema_version':1,'treatment_scopes':['example']}])
PY

run_inspect() { local name="$1"; shift; lake exe traceability "$@" > "$WORK/$name.raw"; tail -n 1 "$WORK/$name.raw" > "$WORK/$name.json"; }

lake exe traceability validate --root "$FIXTURE"
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
import json,os,sys
w=sys.argv[1]
def load(n): return json.load(open(os.path.join(w,n+'.json')))
def env(d,k,c,s):
 assert d['reader_contract_ref']=='P2-TRACE-M2.9-READER-v2' and d['authority']=='derived_read_only'
 assert d['query_kind']==k and d['match_count']==c and d['result_state']==s,d
env(load('zero'),'curriculum',0,'zero_matches')
r=load('recorded'); env(r,'curriculum',1,'matches'); assert r['results'][0]['match_reasons']==['recorded_identity']
m=load('multi'); env(m,'curriculum',2,'multiple_matches'); reasons=[x['match_reasons'] for x in m['results']]
assert ['current_resolved_identity'] in reasons and ['recorded_identity','current_resolved_identity'] in reasons,reasons
c=load('treatment_core'); env(c,'curriculum',1,'matches'); assert c['results'][0]['record']['link']['treatment_scope']=='core'
e=load('treatment_example'); env(e,'curriculum',1,'matches'); assert e['results'][0]['record']['link']['treatment_scope']=='example'
env(load('treatment_miss'),'curriculum',0,'zero_matches')
a=load('artifact'); env(a,'artifact',1,'matches'); assert a['results'][0]['locator_counts']=={'total':2,'current':1,'historical':1,'unresolved':0}
sm=load('source_module'); env(sm,'source',2,'multiple_matches'); assert all('module_name' in x['match_reasons'] for x in sm['results'])
sf=load('source_file'); env(sf,'source',2,'multiple_matches'); assert all('file_path' in x['match_reasons'] for x in sf['results'])
sd=load('source_decl'); env(sd,'source',1,'matches'); assert sd['results'][0]['match_reasons']==['declaration_name']
u=load('unresolved'); env(u,'unresolved',1,'unresolved_present'); assert u['results'][0]['kind']=='floc'
print('traceability-reader-v2:envelope-matrix:pass')
PY

lake exe traceability query curriculum CAND-P1-000002 --root "$FIXTURE" > "$WORK/query-v1.raw"
grep '^{' "$WORK/query-v1.raw" > "$WORK/query-v1.jsonl"
[[ "$(wc -l < "$WORK/query-v1.jsonl" | tr -d ' ')" == "2" ]]
! grep -Fq 'reader_contract_ref' "$WORK/query-v1.jsonl"
printf 'traceability-reader-v2:v1-query-compatibility:pass\n'

set +e
dup_output="$(lake exe traceability inspect curriculum CAND-P1-000002 --treatment core --treatment example --root "$FIXTURE" 2>&1)"; dup_status=$?
set -e
[[ "$dup_status" -ne 0 ]]; grep -Fq 'duplicate --treatment' <<<"$dup_output"
printf 'traceability-reader-v2:duplicate-option-rejected:pass\n'

BROKEN="$WORK/broken"; cp -a "$FIXTURE" "$BROKEN"
python3 - "$BROKEN/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'PY'
import json,sys
p=sys.argv[1]; rows=[json.loads(x) for x in open(p) if x.strip()]; rows[0]['declaration_names']=['QualityTests.TraceabilityFixture.missingDeclaration']
open(p,'w').write(''.join(json.dumps(r,sort_keys=True,separators=(',',':'))+'\n' for r in rows))
PY
set +e
broken_output="$(lake exe traceability inspect curriculum CAND-P1-999999 --root "$BROKEN" 2>&1)"; broken_status=$?
set -e
[[ "$broken_status" -ne 0 ]]; grep -Fq 'traceability:error:resolve:missing-declaration' <<<"$broken_output"
! grep -Fq '"result_state":"zero_matches"' <<<"$broken_output"
printf 'traceability-reader-v2:strong-validation-failure-preserved:pass\n'

cat > "$OUT/reader-result.env" <<EOF
reader_evidence_version=1
reader_contract=P2-TRACE-M2.9-READER-v2
subject_sha=$(git rev-parse HEAD)
synthetic=true
production_traceability_ids_allocated=false
zero_one_multiple=pass
recorded_and_current_resolved_identity=pass
treatment_filter=pass
locator_lifecycle=pass
source_match_reasons=pass
unresolved_diagnostics=pass
v1_query_compatibility=pass
validation_failure_preserved=pass
EOF
printf 'traceability-reader-v2:summary:pass:result=%s\n' "$OUT/reader-result.env"
