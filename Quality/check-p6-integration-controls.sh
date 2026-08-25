#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/p6-integration-controls.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
HARNESS="Benchmarks/run-p6-integration.sh"

expect_fail_contains() {
  local label="$1" signature="$2"
  shift 2
  local output status
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'p6-integration-controls:fail:%s:unexpected-success\n' "$label" >&2
    exit 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'p6-integration-controls:fail:%s:missing-signature:%s\n' \
      "$label" "$signature" >&2
    exit 1
  fi
  printf 'p6-integration-controls:expected-fail:%s:exit=%d\n' "$label" "$status"
}

expect_fail_contains zero-repetitions 'p6-integration:error:invalid-repetitions:0' \
  env P6_INTEGRATION_REPETITIONS=0 P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/zero-repetitions" \
  bash "$HARNESS"
expect_fail_contains noninteger-repetitions 'p6-integration:error:invalid-repetitions:invalid' \
  env P6_INTEGRATION_REPETITIONS=invalid \
  P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/noninteger-repetitions" bash "$HARNESS"
expect_fail_contains zero-timeout 'p6-integration:error:invalid-timeout-seconds:0' \
  env P6_INTEGRATION_TIMEOUT_SECONDS=0 P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/zero-timeout" \
  bash "$HARNESS"
expect_fail_contains noninteger-timeout 'p6-integration:error:invalid-timeout-seconds:invalid' \
  env P6_INTEGRATION_TIMEOUT_SECONDS=invalid \
  P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/noninteger-timeout" bash "$HARNESS"
expect_fail_contains integration-subject-mismatch 'p6-integration:error:integration-subject-mismatch:' \
  env P6_INTEGRATION_INTEGRATION_SHA=0000000000000000000000000000000000000000 \
  P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/subject-mismatch" bash "$HARNESS"

forced_output="$TMP_ROOT/forced-output.log"
set +e
env P6_INTEGRATION_REPETITIONS=1 P6_INTEGRATION_TIMEOUT_SECONDS=5 \
  P6_INTEGRATION_FORCE_FAILURE_FIXTURE=1 \
  P6_INTEGRATION_OUT_ROOT="$TMP_ROOT/forced-failure" \
  bash "$HARNESS" >"$forced_output" 2>&1
forced_status=$?
set -e
cat "$forced_output"
if [[ "$forced_status" -eq 0 ]] ||
   ! grep -Fq 'p6-integration:error:forced-command-failure:' "$forced_output" ||
   grep -Fq 'p6-integration:summary:pass' "$forced_output"; then
  printf 'p6-integration-controls:fail:forced-command-failure:exit=%d\n' \
    "$forced_status" >&2
  exit 1
fi
if ! grep -Fq ',forced-command-failure,1,false,fixture,' \
  "$TMP_ROOT/forced-failure/results/measurements.csv" ||
   ! grep -Fq ',fail' "$TMP_ROOT/forced-failure/results/measurements.csv"; then
  printf 'p6-integration-controls:fail:forced-command-failure:evidence\n' >&2
  exit 1
fi
if [[ -e "$TMP_ROOT/forced-failure/results/summary.json" ]]; then
  printf 'p6-integration-controls:fail:forced-command-failure:summary-present\n' >&2
  exit 1
fi
printf 'p6-integration-controls:expected-fail:forced-command-failure:exit=%d\n' \
  "$forced_status"
printf 'p6-integration-controls:summary:pass\n'
