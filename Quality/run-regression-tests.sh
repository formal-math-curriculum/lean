#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

CONTROL_REPORT_DIR="$(mktemp -d)"
trap 'rm -rf "$CONTROL_REPORT_DIR"' EXIT
IMPORTED_AXIOM_BUILD_DIR=".lake/build/lib/lean"
mkdir -p "$IMPORTED_AXIOM_BUILD_DIR/Quality/Fixtures"

run_pass() {
  local label="$1"
  shift
  printf 'quality-regression:start:%s\n' "$label"
  if "$@"; then
    printf 'quality-regression:pass:%s\n' "$label"
  else
    local status=$?
    printf 'quality-regression:fail:%s:exit=%d\n' "$label" "$status" >&2
    return "$status"
  fi
}

run_pass_contains() {
  local label="$1"
  local signature="$2"
  shift 2
  printf 'quality-regression:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -ne 0 ]]; then
    printf 'quality-regression:fail:%s:exit=%d\n' "$label" "$status" >&2
    return "$status"
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'quality-regression:fail:%s:missing-signature:%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'quality-regression:pass:%s\n' "$label"
}

expect_fail_contains() {
  local label="$1"
  local signature="$2"
  shift 2
  printf 'quality-regression:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'quality-regression:fail:%s:unexpected-success\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'quality-regression:fail:%s:missing-signature:%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'quality-regression:expected-fail:%s:exit=%d\n' "$label" "$status"
}

expect_fail_regex() {
  local label="$1"
  local pattern="$2"
  shift 2
  printf 'quality-regression:start:%s\n' "$label"
  set +e
  local output
  output=$("$@" 2>&1)
  local status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'quality-regression:fail:%s:unexpected-success\n' "$label" >&2
    return 1
  fi
  if ! grep -Eq "$pattern" <<<"$output"; then
    printf 'quality-regression:fail:%s:missing-computability-signature\n' "$label" >&2
    return 1
  fi
  printf 'quality-regression:expected-fail:%s:exit=%d\n' "$label" "$status"
}

run_pass strict-production-build lake build --wfail FormalMath
run_pass reusable-axiom-auditor-build lake build --wfail +Quality.AxiomAudit
run_pass imported-safe-module-build lake env lean -DwarningAsError=true \
  -o "$IMPORTED_AXIOM_BUILD_DIR/Quality/Fixtures/ImportedSafe.olean" \
  Quality/Fixtures/ImportedSafe.lean
run_pass imported-custom-axiom-module-build lake env lean -DwarningAsError=true \
  -o "$IMPORTED_AXIOM_BUILD_DIR/Quality/Fixtures/ImportedCustomAxiom.olean" \
  Quality/Fixtures/ImportedCustomAxiom.lean
run_pass_contains production-imported-axiom-coverage \
  "missing-required=[]" \
  lake env lean -DwarningAsError=true Quality/RunAxiomAudit.lean
run_pass_contains imported-module-axiom-coverage \
  "declaration=FormalMathQuality.Fixtures.ImportedSafe.importedTruth; origin=Quality.Fixtures.ImportedSafe; axioms=[]" \
  lake env lean -DwarningAsError=true Quality/Fixtures/ImportedSafeAudit.lean
run_pass positive-regression-and-contract-build lake build --wfail QualityTests
run_pass traceability-validator-build lake build --wfail traceability
run_pass production-source-quality bash Quality/check-source-quality.sh production
run_pass p6-core-api-policy bash Quality/check-p6-core-api.sh
run_pass p6-fundamental-results-policy bash Quality/check-p6-fundamental-results.sh
run_pass p6-adjacent-functions-policy bash Quality/check-p6-adjacent-functions.sh
run_pass p6-pedagogy-policy bash Quality/check-p6-pedagogy.sh
run_pass production-traceability-registry lake exe traceability validate
run_pass project-floc-revision-controls bash Quality/check-project-floc-revision-controls.sh
run_pass m210-production-roundtrip-controls bash Quality/check-m210-roundtrip-controls.sh
run_pass traceability-negative-controls bash Quality/check-traceability-controls.sh
run_pass traceability-generated-controls bash Quality/check-traceability-generated-controls.sh
run_pass traceability-remediation-controls bash Quality/check-traceability-remediation-controls.sh
run_pass traceability-provenance-v2-controls bash Quality/check-traceability-provenance-v2.sh
run_pass traceability-reader-v2-controls bash Quality/check-traceability-reader-v2.sh
run_pass m29-audit-remediation-controls bash Quality/check-m29-remediation-controls.sh
run_pass source-positive-lean lake env lean -DwarningAsError=true Quality/Fixtures/SourceQuality/Good.lean
run_pass source-positive-policy bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/Good.lean
run_pass report-identity-collision-control bash Quality/check-report-identity.sh

expect_fail_contains direct-sorry "declaration uses \`sorry\`" \
  lake env lean -DwarningAsError=true Quality/Fixtures/SorryWarning.lean
expect_fail_contains transitive-sorryAx "unfinished=[sorryAx]" \
  lake env lean Quality/Fixtures/SorryAxiom.lean
expect_fail_contains custom-axiom "custom-or-unclassified" \
  lake env lean Quality/Fixtures/CustomAxiom.lean
expect_fail_contains trust-compiler "trust-review=[Lean.trustCompiler]" \
  lake env lean Quality/Fixtures/TrustCompiler.lean
expect_fail_contains imported-custom-axiom "custom-or-unclassified=[FormalMathQuality.Fixtures.ImportedCustomAxiom.importedFixtureCustomAxiom]" \
  lake env lean -DwarningAsError=true Quality/Fixtures/ImportedCustomAxiomAudit.lean
expect_fail_contains vacuous-imported-coverage "coverage-empty" \
  lake env lean -DwarningAsError=true Quality/Fixtures/VacuousImportedAudit.lean

expect_fail_contains p6-core-unplanned-public-surface "p6-core-api:error:unplanned-public-surface" \
  env P6_CORE_API_EXTRA_DECLARATION_FIXTURE=1 bash Quality/check-p6-core-api.sh
expect_fail_contains p6-core-missing-root-export "p6-core-api:error:missing-root-export" \
  env P6_CORE_API_MISSING_EXPORT_FIXTURE=1 bash Quality/check-p6-core-api.sh

expect_fail_contains p6-results-unplanned-public-surface "p6-results:error:unplanned-public-surface" \
  env P6_RESULTS_EXTRA_DECLARATION_FIXTURE=1 bash Quality/check-p6-fundamental-results.sh
expect_fail_contains p6-results-missing-root-export "p6-results:error:missing-root-export" \
  env P6_RESULTS_MISSING_EXPORT_FIXTURE=1 bash Quality/check-p6-fundamental-results.sh

expect_fail_contains p6-adjacent-unplanned-public-surface "p6-adjacent:error:unplanned-public-surface" \
  env P6_ADJACENT_EXTRA_DECLARATION_FIXTURE=1 bash Quality/check-p6-adjacent-functions.sh
expect_fail_contains p6-adjacent-missing-root-export "p6-adjacent:error:missing-root-export" \
  env P6_ADJACENT_MISSING_EXPORT_FIXTURE=1 bash Quality/check-p6-adjacent-functions.sh

expect_fail_contains p6-pedagogy-unplanned-public-surface "p6-pedagogy:error:unplanned-public-surface" \
  env P6_PEDAGOGY_EXTRA_DECLARATION_FIXTURE=1 bash Quality/check-p6-pedagogy.sh
expect_fail_contains p6-pedagogy-missing-root-export "p6-pedagogy:error:missing-root-export" \
  env P6_PEDAGOGY_MISSING_EXPORT_FIXTURE=1 bash Quality/check-p6-pedagogy.sh

expect_fail_contains root-umbrella-import "root-umbrella-import" \
  bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/UmbrellaImport.lean
expect_fail_contains ungoverned-transitive-import "ungoverned-transitive-import" \
  bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/TransitiveImport.lean
expect_fail_contains internal-reexport "internal-reexport" \
  bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/InternalReexport.lean
expect_fail_contains missing-source-header "source-header" \
  bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/MissingHeader.lean
expect_fail_contains missing-module-doc "module-doc" \
  bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/MissingModuleDoc.lean
expect_fail_contains test-source-missing-header "source-header" \
  bash Quality/check-source-quality.sh test-fixture Quality/Fixtures/SourceQuality/TestMissingHeader.lean
expect_fail_contains warning-suppression "warning-suppression-disabled" \
  bash Quality/check-source-quality.sh test-fixture Quality/Fixtures/SourceQuality/WarningSuppression.lean

expect_fail_regex intended-executable-noncomputable \
  "(no code|noncomputable|cannot evaluate|compiler|depends on declaration)" \
  lake env lean Quality/Fixtures/Regression/NoncomputableExecutable.lean

expect_fail_contains standalone-environment-mismatch "quality-env:error:toolchain-file-mismatch" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" \
  QUALITY_BASELINE_FILE=Quality/Fixtures/Environment/Mismatch.env \
  bash Quality/quality.sh source

run_pass_contains optional-cache-failure-nonblocking "quality-env:cache:nonblocking-fail:exit=73" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" QUALITY_CACHE_FAIL_FIXTURE=1 \
  bash Quality/quality.sh env

run_pass_contains optional-cache-timeout-nonblocking \
  "quality-env:cache:nonblocking-timeout:seconds=1;exit=124" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" QUALITY_CACHE_TIMEOUT_SECONDS=1 \
  QUALITY_CACHE_TIMEOUT_FIXTURE=1 bash Quality/quality.sh env

run_pass_contains optional-cache-forced-kill-timeout-nonblocking \
  "quality-env:cache:nonblocking-timeout:seconds=1;exit=124" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" QUALITY_CACHE_TIMEOUT_SECONDS=1 \
  QUALITY_CACHE_FORCE_KILL_FIXTURE=1 bash Quality/quality.sh env

printf 'quality-regression:start:optional-cache-descendant-timeout-no-survivor\n'
descendant_report_dir="$CONTROL_REPORT_DIR/cache-descendant"
descendant_direct_pid_file="$descendant_report_dir/direct-child.pid"
descendant_direct_output_file="$descendant_report_dir/direct-output.log"
descendant_env_pid_file="$descendant_report_dir/env-child.pid"
descendant_env_output_file="$descendant_report_dir/env-output.log"
mkdir -p "$descendant_report_dir"
SECONDS=0
set +e
env QUALITY_CACHE_TIMEOUT_SECONDS=1 QUALITY_CACHE_DESCENDANT_FIXTURE=1 \
  QUALITY_CACHE_DESCENDANT_PID_FILE="$descendant_direct_pid_file" \
  bash Quality/check-environment.sh cache >"$descendant_direct_output_file" 2>&1
descendant_direct_status=$?
set -e
descendant_direct_elapsed=$SECONDS
descendant_direct_output="$(<"$descendant_direct_output_file")"
printf '%s\n' "$descendant_direct_output"
if [[ "$descendant_direct_status" -ne 124 ]] || (( descendant_direct_elapsed > 8 )); then
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:direct:exit=%d;elapsed=%d\n' \
    "$descendant_direct_status" "$descendant_direct_elapsed" >&2
  exit 1
fi
if [[ ! -s "$descendant_direct_pid_file" ]]; then
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:direct:missing-pid\n' >&2
  exit 1
fi
descendant_direct_pid="$(<"$descendant_direct_pid_file")"
if kill -0 "$descendant_direct_pid" 2>/dev/null; then
  kill -KILL "$descendant_direct_pid" 2>/dev/null || true
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:direct:pid=%s\n' \
    "$descendant_direct_pid" >&2
  exit 1
fi

set +e
env QUALITY_REPORT_DIR="$descendant_report_dir" \
  QUALITY_CACHE_TIMEOUT_SECONDS=1 QUALITY_CACHE_DESCENDANT_FIXTURE=1 \
  QUALITY_CACHE_DESCENDANT_PID_FILE="$descendant_env_pid_file" \
  bash Quality/quality.sh env >"$descendant_env_output_file" 2>&1
descendant_status=$?
set -e
descendant_output="$(<"$descendant_env_output_file")"
printf '%s\n' "$descendant_output"
if [[ "$descendant_status" -ne 0 ]] ||
   ! grep -Fq "quality-env:cache:nonblocking-timeout:seconds=1;exit=124" \
     <<<"$descendant_output"; then
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:cache-outcome\n' >&2
  exit 1
fi
if [[ ! -s "$descendant_env_pid_file" ]]; then
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:missing-pid\n' >&2
  exit 1
fi
descendant_pid="$(<"$descendant_env_pid_file")"
if kill -0 "$descendant_pid" 2>/dev/null; then
  kill -KILL "$descendant_pid" 2>/dev/null || true
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:pid=%s\n' \
    "$descendant_pid" >&2
  exit 1
fi
shopt -s nullglob
descendant_reports=("$descendant_report_dir"/env-*/result.report)
shopt -u nullglob
if (( ${#descendant_reports[@]} != 1 )) ||
   ! grep -Fxq 'status=pass' "${descendant_reports[0]}" ||
   ! grep -Fxq 'exit_code=0' "${descendant_reports[0]}"; then
  printf 'quality-regression:fail:optional-cache-descendant-timeout-no-survivor:report\n' >&2
  exit 1
fi
printf 'quality-regression:pass:optional-cache-descendant-timeout-no-survivor\n'

type_drift_dir="$CONTROL_REPORT_DIR/p4-integer-sign-laws-type-drift"
mkdir -p "$type_drift_dir"
cat > "$type_drift_dir/P4IntegerSignLawsRootApiTypeDrift.lean" <<'EOF'
module

import FormalMath

namespace QualityTests.P4IntegerSignLawsRootApiTypeDrift

example :
    Int.sub (Int.ofNat 7) (Int.neg (Int.ofNat 3)) = Int.ofNat 11 :=
  FormalMath.Arithmetic.Examples.seven_sub_neg_three

end QualityTests.P4IntegerSignLawsRootApiTypeDrift
EOF
expect_fail_contains p4-integer-sign-laws-root-api-type-drift "Type mismatch" \
  lake env lean -DwarningAsError=true \
  "$type_drift_dir/P4IntegerSignLawsRootApiTypeDrift.lean"

run_pass_contains optional-cache-invalid-timeout-nonblocking \
  "quality-env:cache:nonblocking-invalid-timeout:value=invalid;exit=64" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" QUALITY_CACHE_TIMEOUT_SECONDS=invalid \
  bash Quality/quality.sh env

run_pass_contains optional-cache-timeout-unavailable-nonblocking \
  "quality-env:cache:nonblocking-timeout-unavailable:exit=69" \
  env QUALITY_REPORT_DIR="$CONTROL_REPORT_DIR" QUALITY_CACHE_TIMEOUT_UNAVAILABLE_FIXTURE=1 \
  bash Quality/quality.sh env

printf 'quality-regression:summary:pass\n'
