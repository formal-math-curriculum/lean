#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT="${READER_BENCH_OUT_ROOT:-$ROOT/.lake/build/reader-v2}"
WORK="$OUT/work"
SIZES="${READER_BENCH_SIZES:-16 64 256}"
REPETITIONS="${READER_BENCH_REPETITIONS:-2}"
SUBJECT_HEAD_SHA="${READER_BENCH_SUBJECT_HEAD_SHA:-$(git rev-parse HEAD)}"
SUBJECT_INTEGRATION_SHA="$(git rev-parse HEAD)"
MATHLIB_SHA="$(git -C .lake/packages/mathlib rev-parse HEAD)"
mkdir -p "$OUT" "$WORK"
CSV="$OUT/reader-scaling.csv"

cat > "$CSV" <<'EOF'
subject_head_sha,subject_integration_sha,records,workload,iteration,wall_ms,response_bytes,match_count,result_state,result
EOF

now_ns() { date +%s%N; }

make_fixture() {
  local n="$1" root="$2"
  rm -rf "$root"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock"
  python3 - "$n" "$root" "$MATHLIB_SHA" <<'PY'
import json,os,sys
n=int(sys.argv[1]); root=sys.argv[2]; mathlib=sys.argv[3]
def dump(x): return json.dumps(x,sort_keys=True,separators=(',',':'))
def ident(p,i): return f'{p}{i:06d}'
def write_json(p,x): open(p,'w').write(dump(x)+'\n')
def write_jsonl(p,xs): open(p,'w').write(''.join(dump(x)+'\n' for x in xs))
registry={'default_curriculum_baseline_ref':'P1-CURR-v1','dependency_baseline_ref':'P2-DEP-M2.2-v1',
 'format':'formal-artifacts-jsonl-v1','lean_toolchain_ref':'P2-ENV-M2.5-v1',
 'next_ids':{'fart':ident('FART-P2-',n+1),'flink':ident('FLINK-P2-',n+1),'floc':ident('FLOC-P2-',n+1)},
 'protocol_ref':'P2-TRACE-M2.8-PROTOCOL-v1','record_counts':{'fart':n,'flink':n,'floc':n},
 'registry_semantics_ref':'P2-TRACE-M2.8-REGISTRY-v1','registry_status':'active','reservations':[],'schema_version':1,'shard_size':1000}
write_json(os.path.join(root,'metadata/formal-artifacts/registry.json'),registry)
farts=[]; flocs=[]; flinks=[]; locks=[]
for i in range(1,n+1):
  fart=ident('FART-P2-',i); floc=ident('FLOC-P2-',i); flink=ident('FLINK-P2-',i); cand=ident('CAND-P1-',i)
  farts.append({'artifact_kind':'theorem','created_revision':'reader-scale','current_locator_refs':[floc],'curriculum_link_refs':[flink],
    'dependency_baseline_ref':'P2-DEP-M2.2-v1','id':fart,'lean_toolchain_ref':'P2-ENV-M2.5-v1','quality_state':'reviewed',
    'record_status':'active','representation_state':'represented','schema_version':1,'source_provenance':{
      'proof_or_implementation_provenance_notes':'synthetic reader scale fixture','provenance_kind':'direct_dependency_representation',
      'source_refs':['P2-DEP-M2.2-v1'],'statement_provenance_notes':'synthetic reader scale fixture'},'superseded_by':[],
    'supersedes':[],'title_or_summary':f'Reader scale artifact {i}','verification_state':'kernel_checked'})
  flocs.append({'created_revision':'reader-scale','declaration_names':['Complex.eta'],'dependency_baseline_ref':'P2-DEP-M2.2-v1',
    'file_path':'Mathlib/Data/Complex/Basic.lean','formal_artifact_ref':fart,'id':floc,'locator_status':'current',
    'module_name':'Mathlib.Data.Complex.Basic','observed_at':'reader-scale','record_status':'active','repository':'leanprover-community/mathlib4',
    'revision':mathlib,'schema_version':1,'source_kind':'dependency_repository','structural_anchors':[],
    'superseded_by_locator_refs':[],'supersedes_locator_refs':[]})
  flinks.append({'assumptions_or_formulation_notes':'synthetic reader scale link','candidate_lineage_resolution':{
      'resolution_context':'reader scale exact identity','resolution_path':[cand],'review_ref':'not_applicable','state':'resolved_exact'},
    'candidate_ref_as_recorded':cand,'candidate_ref_current_resolved':cand,'coverage_claim_scope':'synthetic_nonproduction',
    'created_revision':'reader-scale','curriculum_release_ref':'P1-CURR-v1','formal_artifact_ref':fart,'id':flink,
    'link_confidence':'established','link_status':'current','record_status':'active','representation_relation':'represents',
    'schema_version':1,'treatment_scope':'core'})
  locks.append({'candidate_ref_as_recorded':cand,'candidate_ref_current_resolved':cand,'record_status':'current',
    'resolution_path':[cand],'resolution_state':'resolved_exact','schema_version':1,'treatment_scopes':['core']})
write_jsonl(os.path.join(root,'metadata/formal-artifacts/fart/000001-001000.jsonl'),farts)
write_jsonl(os.path.join(root,'metadata/formal-artifacts/floc/000001-001000.jsonl'),flocs)
write_jsonl(os.path.join(root,'metadata/formal-artifacts/flink/000001-001000.jsonl'),flinks)
write_json(os.path.join(root,'metadata/curriculum-lock/manifest.json'),{'authority':'project1_external_authority',
 'curriculum_release_ref':'P1-CURR-v1','identity_count':n,'mirror_status':'verified_snapshot','schema_version':1,
 'source_refs':['P1-CURR-v1','P1-P2-HANDOFF-v1'],'verified_by_trace_record':'TRVER-M2-reader-scale'})
write_jsonl(os.path.join(root,'metadata/curriculum-lock/linked-identities.jsonl'),locks)
PY
}

measure() {
  local n="$1" workload="$2" iteration="$3" expected_count="$4" expected_state="$5"; shift 5
  local raw="$WORK/${n}-${workload}-${iteration}.raw" json="$WORK/${n}-${workload}-${iteration}.json"
  local start end elapsed status result bytes
  start="$(now_ns)"; set +e; lake exe traceability "$@" >"$raw" 2>&1; status=$?; set -e; end="$(now_ns)"
  elapsed=$(( (end-start)/1000000 )); result=fail
  if [[ "$status" -eq 0 ]]; then result=pass; fi
  tail -n 1 "$raw" > "$json"; bytes="$(wc -c < "$json" | tr -d ' ')"
  python3 - "$json" "$expected_count" "$expected_state" <<'PY'
import json,sys
p=sys.argv[1]; expected=int(sys.argv[2]); state=sys.argv[3]; d=json.load(open(p))
assert d['reader_contract_ref']=='P2-TRACE-M2.9-READER-v2',d
assert d['match_count']==expected,d
assert d['result_state']==state,d
PY
  [[ "$status" -eq 0 ]]
  printf '%s,%s,%d,%s,%d,%d,%d,%d,%s,%s\n' "$SUBJECT_HEAD_SHA" "$SUBJECT_INTEGRATION_SHA" "$n" "$workload" \
    "$iteration" "$elapsed" "$bytes" "$expected_count" "$expected_state" "$result" >> "$CSV"
}

for n in $SIZES; do
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || { printf 'reader-benchmark:error:invalid-size:%s\n' "$n" >&2; exit 2; }
  root="$WORK/records-$n"; make_fixture "$n" "$root"; cand="$(printf 'CAND-P1-%06d' "$n")"
  # Untimed warmup uses the same strong-validation path.
  lake exe traceability inspect curriculum "$cand" --root "$root" >/dev/null
  lake exe traceability inspect curriculum CAND-P1-999999 --root "$root" >/dev/null
  lake exe traceability inspect source Mathlib.Data.Complex.Basic --root "$root" >/dev/null
  for ((rep=1; rep<=REPETITIONS; rep++)); do
    measure "$n" inspect-one "$rep" 1 matches inspect curriculum "$cand" --root "$root"
    measure "$n" inspect-zero "$rep" 0 zero_matches inspect curriculum CAND-P1-999999 --root "$root"
    measure "$n" inspect-source-multiple "$rep" "$n" multiple_matches inspect source Mathlib.Data.Complex.Basic --root "$root"
  done
done

printf 'reader-benchmark:summary:pass:csv=%s\n' "$CSV"
