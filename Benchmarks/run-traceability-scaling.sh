#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
OUT_ROOT="${TRACE_BENCH_OUT_ROOT:-$REPO_ROOT/.lake/build/traceability-benchmarks}"
RESULT_DIR="$OUT_ROOT/results"
WORK_ROOT="$OUT_ROOT/work"
SIZES="${TRACE_BENCH_SIZES:-16 64 256}"
REPETITIONS="${TRACE_BENCH_REPETITIONS:-2}"
SUBJECT_HEAD_SHA="${TRACE_BENCH_SUBJECT_HEAD_SHA:-$(git rev-parse HEAD)}"
SUBJECT_INTEGRATION_SHA="$(git rev-parse HEAD)"
MATHLIB_SHA="$(git -C .lake/packages/mathlib rev-parse HEAD)"
mkdir -p "$RESULT_DIR" "$WORK_ROOT"
CSV="$RESULT_DIR/traceability-scaling.csv"
META="$RESULT_DIR/metadata.env"

cat > "$CSV" <<'EOF'
subject_head_sha,subject_integration_sha,records,workload,iteration,wall_ms,output_bytes,result
EOF

cat > "$META" <<EOF
benchmark_protocol=P2-SCALE-M2.9-PROTOCOL-v1
benchmark_schema=P2-SCALE-M2.9-EVIDENCE-v1
traceability_provenance=P2-TRACE-M2.9-PROVENANCE-v2
synthetic=true
production_traceability_ids_allocated=false
subject_head_sha=$SUBJECT_HEAD_SHA
subject_integration_sha=$SUBJECT_INTEGRATION_SHA
lean_toolchain=$(tr -d '\n' < lean-toolchain)
mathlib_revision=$MATHLIB_SHA
sizes=$SIZES
repetitions=$REPETITIONS
platform=$(uname -srm)
EOF

now_ns() { date +%s%N; }

measure() {
  local records="$1" workload="$2" iteration="$3" output_dir="$4"
  shift 4
  local start end elapsed status result bytes=0
  start="$(now_ns)"
  set +e
  "$@"
  status=$?
  set -e
  end="$(now_ns)"
  elapsed=$(( (end - start) / 1000000 ))
  if [[ "$status" -eq 0 ]]; then result=pass; else result=fail; fi
  if [[ -d "$output_dir" ]]; then
    bytes="$(du -sb "$output_dir" | awk '{print $1}')"
  fi
  printf '%s,%s,%d,%s,%d,%d,%d,%s\n' \
    "$SUBJECT_HEAD_SHA" "$SUBJECT_INTEGRATION_SHA" "$records" "$workload" "$iteration" \
    "$elapsed" "$bytes" "$result" >> "$CSV"
  return "$status"
}

make_fixture() {
  local n="$1" root="$2"
  rm -rf "$root"
  mkdir -p "$root/metadata/formal-artifacts/fart" "$root/metadata/formal-artifacts/floc" \
    "$root/metadata/formal-artifacts/flink" "$root/metadata/curriculum-lock"
  python3 - "$n" "$root" "$MATHLIB_SHA" <<'PY'
import json, os, sys
n=int(sys.argv[1]); root=sys.argv[2]; mathlib=sys.argv[3]

def dump(obj):
    return json.dumps(obj, sort_keys=True, separators=(',', ':'))

def ident(prefix, i):
    return f"{prefix}{i:06d}"

registry={
  "default_curriculum_baseline_ref":"P1-CURR-v1",
  "dependency_baseline_ref":"P2-DEP-M2.2-v1",
  "format":"formal-artifacts-jsonl-v1",
  "lean_toolchain_ref":"P2-ENV-M2.5-v1",
  "next_ids":{"fart":ident("FART-P2-",n+1),"flink":ident("FLINK-P2-",n+1),"floc":ident("FLOC-P2-",n+1)},
  "protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1",
  "record_counts":{"fart":n,"flink":n,"floc":n},
  "registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1",
  "registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
open(os.path.join(root,"metadata/formal-artifacts/registry.json"),'w').write(dump(registry)+'\n')

farts=[]; flocs=[]; flinks=[]; locks=[]
for i in range(1,n+1):
    fart=ident("FART-P2-",i); floc=ident("FLOC-P2-",i); flink=ident("FLINK-P2-",i); cand=ident("CAND-P1-",i)
    farts.append({
      "artifact_kind":"theorem","created_revision":"synthetic-scale","current_locator_refs":[floc],
      "curriculum_link_refs":[flink],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":fart,
      "lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active",
      "representation_state":"represented","schema_version":1,
      "source_provenance":{"proof_or_implementation_provenance_notes":"synthetic non-production scale fixture",
        "provenance_kind":"direct_dependency_representation","source_refs":["P2-DEP-M2.2-v1"],
        "statement_provenance_notes":"repeated upstream target solely for engineering scale measurement"},
      "superseded_by":[],"supersedes":[],"title_or_summary":f"Synthetic scale artifact {i}",
      "verification_state":"kernel_checked"})
    flocs.append({
      "created_revision":"synthetic-scale","declaration_names":["Complex.eta"],
      "dependency_baseline_ref":"P2-DEP-M2.2-v1","file_path":"Mathlib/Data/Complex/Basic.lean",
      "formal_artifact_ref":fart,"id":floc,"locator_status":"current","module_name":"Mathlib.Data.Complex.Basic",
      "observed_at":"synthetic-scale","record_status":"active","repository":"leanprover-community/mathlib4",
      "revision":mathlib,"schema_version":1,"source_kind":"dependency_repository","structural_anchors":[],
      "superseded_by_locator_refs":[],"supersedes_locator_refs":[]})
    flinks.append({
      "assumptions_or_formulation_notes":"synthetic scale link",
      "candidate_lineage_resolution":{"resolution_context":"synthetic scale exact identity","resolution_path":[cand],
        "review_ref":"not_applicable","state":"resolved_exact"},
      "candidate_ref_as_recorded":cand,"candidate_ref_current_resolved":cand,
      "coverage_claim_scope":"synthetic_nonproduction","created_revision":"synthetic-scale",
      "curriculum_release_ref":"P1-CURR-v1","formal_artifact_ref":fart,"id":flink,
      "link_confidence":"established","link_status":"current","record_status":"active",
      "representation_relation":"represents","schema_version":1,"treatment_scope":"core"})
    locks.append({
      "candidate_ref_as_recorded":cand,"candidate_ref_current_resolved":cand,"record_status":"current",
      "resolution_path":[cand],"resolution_state":"resolved_exact","schema_version":1,"treatment_scopes":["core"]})

for family, records in (("fart",farts),("floc",flocs),("flink",flinks)):
    p=os.path.join(root,f"metadata/formal-artifacts/{family}/000001-001000.jsonl")
    with open(p,'w') as f:
        for r in records: f.write(dump(r)+'\n')
lock_manifest={"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":n,
  "mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],
  "verified_by_trace_record":"TRVER-M2-synthetic-scale"}
open(os.path.join(root,"metadata/curriculum-lock/manifest.json"),'w').write(dump(lock_manifest)+'\n')
with open(os.path.join(root,"metadata/curriculum-lock/linked-identities.jsonl"),'w') as f:
    for r in locks: f.write(dump(r)+'\n')
PY
}

manifest_value() {
  local path="$1" key="$2"
  python3 - "$path" "$key" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))[sys.argv[2]])
PY
}

for n in $SIZES; do
  if ! [[ "$n" =~ ^[1-9][0-9]*$ ]]; then
    printf 'trace-benchmark:error:invalid-size:%s\n' "$n" >&2
    exit 2
  fi
  root="$WORK_ROOT/records-$n"
  make_fixture "$n" "$root"
  out="$root/.lake/build/traceability/$SUBJECT_INTEGRATION_SHA"

  for ((rep=1; rep<=REPETITIONS; rep++)); do
    measure "$n" validate "$rep" "$out" lake exe traceability validate --root "$root"
  done

  for ((rep=1; rep<=REPETITIONS; rep++)); do
    rm -rf "$out"
    measure "$n" generate-with-validation "$rep" "$out" lake exe traceability generate --root "$root"
    measure "$n" freshness "$rep" "$out" lake exe traceability freshness --root "$root"
    measure "$n" query-with-validation "$rep" "$out" lake exe traceability query curriculum "$(printf 'CAND-P1-%06d' "$n")" --root "$root" >/dev/null
  done

  # Determinism: same authoritative inputs must reproduce both generated semantic and input fingerprints.
  rm -rf "$out"
  lake exe traceability generate --root "$root" >/dev/null
  semantic1="$(manifest_value "$out/manifest.json" semantic_fingerprint)"
  authored1="$(manifest_value "$out/provenance-v2.json" authoritative_input_fingerprint)"
  rm -rf "$out"
  lake exe traceability generate --root "$root" >/dev/null
  semantic2="$(manifest_value "$out/manifest.json" semantic_fingerprint)"
  authored2="$(manifest_value "$out/provenance-v2.json" authoritative_input_fingerprint)"
  [[ "$semantic1" == "$semantic2" ]]
  [[ "$authored1" == "$authored2" ]]
  [[ "$(manifest_value "$out/provenance-v2.json" subject_kind)" == "alternate_root_content_snapshot" ]]
  [[ "$(manifest_value "$out/provenance-v2.json" subject_revision)" == "not_applicable" ]]
  printf 'trace-benchmark:determinism:pass:records=%d\n' "$n"

  # Registry mutation after generation must make freshness fail before regeneration.
  python3 - "$root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'PY'
import json, sys
p=sys.argv[1]; rows=[json.loads(x) for x in open(p) if x.strip()]
rows[-1]["title_or_summary"] += " changed-after-generation"
with open(p,'w') as f:
    for r in rows: f.write(json.dumps(r, sort_keys=True, separators=(',', ':'))+'\n')
PY
  if lake exe traceability freshness --root "$root" >"$RESULT_DIR/stale-registry-$n.log" 2>&1; then
    printf 'trace-benchmark:error:stale-registry-accepted:records=%d\n' "$n" >&2
    exit 1
  fi
  grep -Fq 'traceability:freshness:error:authoritative-inputs-changed' "$RESULT_DIR/stale-registry-$n.log"
  printf 'trace-benchmark:stale-registry:expected-reject:records=%d\n' "$n"

  # Recreate, generate, then mutate curriculum lock; freshness must also fail.
  make_fixture "$n" "$root"
  lake exe traceability generate --root "$root" >/dev/null
  python3 - "$root/metadata/curriculum-lock/manifest.json" <<'PY'
import json, sys
p=sys.argv[1]; d=json.load(open(p)); d["mirror_status"]="stale_snapshot"
open(p,'w').write(json.dumps(d, sort_keys=True, separators=(',', ':'))+'\n')
PY
  if lake exe traceability freshness --root "$root" >"$RESULT_DIR/stale-lock-$n.log" 2>&1; then
    printf 'trace-benchmark:error:stale-lock-accepted:records=%d\n' "$n" >&2
    exit 1
  fi
  grep -Fq 'traceability:freshness:error:authoritative-inputs-changed' "$RESULT_DIR/stale-lock-$n.log"
  printf 'trace-benchmark:stale-lock:expected-reject:records=%d\n' "$n"
done

printf 'trace-benchmark:summary:pass:csv=%s\n' "$CSV"
