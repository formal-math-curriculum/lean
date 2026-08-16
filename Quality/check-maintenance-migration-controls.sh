#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT_REPO="$(git rev-parse --show-toplevel)"
OUT_DIR="$ROOT_REPO/.lake/build/maintenance"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT_DIR"
RESULT="$OUT_DIR/migration-result.env"

subject_sha="$(git rev-parse HEAD)"
resolved_mathlib="$(git -C .lake/packages/mathlib rev-parse HEAD 2>/dev/null || printf 'unresolved')"

# The contract checks import project modules through LEAN_PATH, so materialize the exact
# fixture modules first. This is setup, not a relaxation of the compatibility check.
printf 'maintenance-migration:start:fixture-build\n'
lake build --wfail +QualityTests.MigrationBefore +QualityTests.MigrationAfter
printf 'maintenance-migration:fixture-build:pass\n'

printf 'maintenance-migration:start:contract-positive\n'
cat > "$TMP/Compatible.lean" <<'EOF'
import QualityTests.MigrationBefore
import QualityTests.MigrationAfter

def ExpectedStableContract := ∀ n : Nat, n = n

example : ExpectedStableContract := QualityTests.MigrationBefore.stableIdentityContract
example : ExpectedStableContract := QualityTests.MigrationAfter.stableIdentityContract
EOF
lake env lean -DwarningAsError=true "$TMP/Compatible.lean"
printf 'maintenance-migration:contract-positive:pass\n'

printf 'maintenance-migration:start:incompatible-negative\n'
cat > "$TMP/Incompatible.lean" <<'EOF'
import QualityTests.MigrationAfter

def ExpectedStableContract := ∀ n : Nat, n = n

example : ExpectedStableContract := QualityTests.MigrationAfter.incompatibleCandidate
EOF
if lake env lean -DwarningAsError=true "$TMP/Incompatible.lean" >"$TMP/incompatible.log" 2>&1; then
  cat "$TMP/incompatible.log"
  printf 'maintenance-migration:incompatible-negative:unexpected-pass\n' >&2
  exit 1
fi
cat "$TMP/incompatible.log"
printf 'maintenance-migration:incompatible-negative:expected-reject\n'

FIXTURE_ROOT="$TMP/root"
mkdir -p "$FIXTURE_ROOT/metadata/formal-artifacts/fart" \
  "$FIXTURE_ROOT/metadata/formal-artifacts/floc" \
  "$FIXTURE_ROOT/metadata/formal-artifacts/flink" \
  "$FIXTURE_ROOT/metadata/curriculum-lock" \
  "$FIXTURE_ROOT/QualityTests"
cp QualityTests/MigrationBefore.lean "$FIXTURE_ROOT/QualityTests/MigrationBefore.lean"
cp QualityTests/MigrationAfter.lean "$FIXTURE_ROOT/QualityTests/MigrationAfter.lean"

cat > "$FIXTURE_ROOT/metadata/formal-artifacts/registry.json" <<'EOF'
{"default_curriculum_baseline_ref":"P1-CURR-v1","dependency_baseline_ref":"P2-DEP-M2.2-v1","format":"formal-artifacts-jsonl-v1","lean_toolchain_ref":"P2-ENV-M2.5-v1","next_ids":{"fart":"FART-P2-000002","flink":"FLINK-P2-000001","floc":"FLOC-P2-000003"},"protocol_ref":"P2-TRACE-M2.8-PROTOCOL-v1","record_counts":{"fart":1,"flink":0,"floc":2},"registry_semantics_ref":"P2-TRACE-M2.8-REGISTRY-v1","registry_status":"active","reservations":[],"schema_version":1,"shard_size":1000}
EOF

cat > "$FIXTURE_ROOT/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'EOF'
{"artifact_kind":"theorem","created_revision":"migration-before","current_locator_refs":["FLOC-P2-000002"],"curriculum_link_refs":[],"dependency_baseline_ref":"P2-DEP-M2.2-v1","id":"FART-P2-000001","lean_toolchain_ref":"P2-ENV-M2.5-v1","quality_state":"reviewed","record_status":"active","representation_state":"represented","schema_version":1,"source_provenance":{"proof_or_implementation_provenance_notes":"synthetic migration fixture","provenance_kind":"original_project","source_refs":[],"statement_provenance_notes":"same governed contract before and after locator move"},"superseded_by":[],"supersedes":[],"title_or_summary":"Synthetic stable theorem identity across locator move","verification_state":"regression_verified"}
EOF

cat > "$FIXTURE_ROOT/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'EOF'
{"created_revision":"migration-before","declaration_names":["QualityTests.MigrationBefore.stableIdentityContract"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/MigrationBefore.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000001","locator_status":"historical","module_name":"QualityTests.MigrationBefore","observed_at":"migration-before","record_status":"historical","repository":"formal-math-curriculum/lean","revision":"migration-before","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":["FLOC-P2-000002"],"supersedes_locator_refs":[]}
{"created_revision":"migration-after","declaration_names":["QualityTests.MigrationAfter.stableIdentityContract"],"dependency_baseline_ref":"not_applicable","file_path":"QualityTests/MigrationAfter.lean","formal_artifact_ref":"FART-P2-000001","id":"FLOC-P2-000002","locator_status":"current","module_name":"QualityTests.MigrationAfter","observed_at":"migration-after","record_status":"active","repository":"formal-math-curriculum/lean","revision":"migration-after","schema_version":1,"source_kind":"project_repository","structural_anchors":[],"superseded_by_locator_refs":[],"supersedes_locator_refs":["FLOC-P2-000001"]}
EOF

cat > "$FIXTURE_ROOT/metadata/curriculum-lock/manifest.json" <<'EOF'
{"authority":"project1_external_authority","curriculum_release_ref":"P1-CURR-v1","identity_count":0,"mirror_status":"verified_snapshot","schema_version":1,"source_refs":["P1-CURR-v1","P1-P2-HANDOFF-v1"],"verified_by_trace_record":"TRVER-M2-migration-fixture"}
EOF
: > "$FIXTURE_ROOT/metadata/curriculum-lock/linked-identities.jsonl"

printf 'maintenance-migration:start:traceability-validate\n'
lake exe traceability validate --root "$FIXTURE_ROOT"
printf 'maintenance-migration:traceability-validate:pass\n'

printf 'maintenance-migration:start:traceability-generate\n'
generate_output="$(lake exe traceability generate --root "$FIXTURE_ROOT")"
printf '%s\n' "$generate_output"
subject_dir="$FIXTURE_ROOT/.lake/build/traceability/$subject_sha"
[[ -f "$subject_dir/by-artifact.jsonl" ]]
[[ -f "$subject_dir/history.jsonl" ]]
grep -Fq '"id":"FART-P2-000001"' "$subject_dir/by-artifact.jsonl"
grep -Fq '"id":"FLOC-P2-000002"' "$subject_dir/by-artifact.jsonl"
grep -Fq '"id":"FLOC-P2-000001"' "$subject_dir/history.jsonl"
printf 'maintenance-migration:locator-chain:pass:fart=FART-P2-000001;historical=FLOC-P2-000001;current=FLOC-P2-000002\n'

cat > "$RESULT" <<EOF
maintenance_evidence_version=1
protocol=P2-SCALE-M2.9-PROTOCOL-v1
synthetic=true
production_ids_allocated=false
subject_sha=$subject_sha
lean_toolchain=$(tr -d '\n' < lean-toolchain)
resolved_mathlib=$resolved_mathlib
baseline_environment=P2-ENV-M2.5-v1
baseline_dependency=P2-DEP-M2.2-v1
stable_fart=FART-P2-000001
historical_floc=FLOC-P2-000001
current_floc=FLOC-P2-000002
compatible_contract=pass
locator_supersession=pass
incompatible_name_only_migration=rejected
production_environment_changed=false
EOF

printf 'maintenance-migration:summary:pass:result=%s\n' "$RESULT"
