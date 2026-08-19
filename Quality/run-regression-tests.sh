#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

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
run_pass positive-regression-and-contract-build lake build --wfail QualityTests
run_pass production-source-quality bash Quality/check-source-quality.sh production
run_pass source-positive-lean lake env lean -DwarningAsError=true Quality/Fixtures/SourceQuality/Good.lean
run_pass source-positive-policy bash Quality/check-source-quality.sh fixture Quality/Fixtures/SourceQuality/Good.lean

expect_fail_contains direct-sorry "declaration uses \`sorry\`" \
  lake env lean -DwarningAsError=true Quality/Fixtures/SorryWarning.lean
expect_fail_contains transitive-sorryAx "unfinished=[sorryAx]" \
  lake env lean Quality/Fixtures/SorryAxiom.lean
expect_fail_contains custom-axiom "custom-or-unclassified" \
  lake env lean Quality/Fixtures/CustomAxiom.lean

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

expect_fail_regex intended-executable-noncomputable \
  "(no code|noncomputable|cannot evaluate|compiler|depends on declaration)" \
  lake env lean Quality/Fixtures/Regression/NoncomputableExecutable.lean

printf 'quality-regression:summary:pass\n'
