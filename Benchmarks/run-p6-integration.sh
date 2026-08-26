#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

PROTOCOL="P6-M6.8-INTEGRATION-PERF-v1"
SCHEMA="P6-M6.8-INTEGRATION-EVIDENCE-v1"
REPETITIONS="${P6_INTEGRATION_REPETITIONS:-3}"
TIMEOUT_SECONDS="${P6_INTEGRATION_TIMEOUT_SECONDS:-1800}"
ACTUAL_SHA="$(git rev-parse HEAD)"
SUBJECT_HEAD_SHA="${P6_INTEGRATION_HEAD_SHA:-$ACTUAL_SHA}"
SUBJECT_INTEGRATION_SHA="${P6_INTEGRATION_INTEGRATION_SHA:-$ACTUAL_SHA}"
FINAL_OUT_ROOT="${P6_INTEGRATION_OUT_ROOT:-$ROOT/.lake/build/p6-integration}"
FORCE_FAILURE="${P6_INTEGRATION_FORCE_FAILURE_FIXTURE:-0}"

fail() {
  printf 'p6-integration:error:%s\n' "$1" >&2
  exit "${2:-2}"
}

is_positive_integer() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

is_sha() {
  [[ "$1" =~ ^[0-9a-f]{40}$ ]]
}

is_positive_integer "$REPETITIONS" || fail "invalid-repetitions:$REPETITIONS"
is_positive_integer "$TIMEOUT_SECONDS" || fail "invalid-timeout-seconds:$TIMEOUT_SECONDS"
is_sha "$SUBJECT_HEAD_SHA" || fail "invalid-head-sha:$SUBJECT_HEAD_SHA"
is_sha "$SUBJECT_INTEGRATION_SHA" || fail "invalid-integration-sha:$SUBJECT_INTEGRATION_SHA"
[[ "$SUBJECT_INTEGRATION_SHA" == "$ACTUAL_SHA" ]] ||
  fail "integration-subject-mismatch:declared=$SUBJECT_INTEGRATION_SHA:actual=$ACTUAL_SHA"
[[ "$FORCE_FAILURE" == 0 || "$FORCE_FAILURE" == 1 ]] ||
  fail "invalid-failure-fixture:$FORCE_FAILURE"
command -v timeout >/dev/null 2>&1 || fail "timeout-unavailable" 69

LEAN_TOOLCHAIN="$(tr -d '\n' < lean-toolchain)"
MATHLIB_REVISION="$(python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("lake-manifest.json").read_text(encoding="utf-8"))
row = next((item for item in manifest["packages"] if item["name"] == "mathlib"), None)
if row is None:
    raise SystemExit("p6-integration:error:mathlib-missing")
print(row["rev"])
PY
)"

STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/p6-integration.XXXXXX")"
trap 'rm -rf "$STAGING_ROOT"' EXIT
RESULT_DIR="$STAGING_ROOT/results"
LOG_DIR="$STAGING_ROOT/logs"
mkdir -p "$RESULT_DIR" "$LOG_DIR" "$FINAL_OUT_ROOT"
CSV="$RESULT_DIR/measurements.csv"
META="$RESULT_DIR/metadata.env"
SUMMARY="$RESULT_DIR/summary.json"

cat > "$CSV" <<'EOF'
protocol,schema,subject_head_sha,subject_integration_sha,lean_toolchain,mathlib_revision,runner_os,runner_arch,workload,iteration,warmup,root_artifact_state,wall_ms,result
EOF

cat > "$META" <<EOF
protocol=$PROTOCOL
schema=$SCHEMA
subject_head_sha=$SUBJECT_HEAD_SHA
subject_integration_sha=$SUBJECT_INTEGRATION_SHA
lean_toolchain=$LEAN_TOOLCHAIN
mathlib_revision=$MATHLIB_REVISION
platform=$(uname -srm)
runner_os=${RUNNER_OS:-unreported}
runner_arch=${RUNNER_ARCH:-unreported}
runner_image_os=${ImageOS:-unreported}
runner_image_version=${ImageVersion:-unreported}
repetitions=$REPETITIONS
warmups_per_workload=1
timeout_seconds=$TIMEOUT_SECONDS
workloads=clean-formal-math-build,warm-noop-formal-math-build,traceability-validate,p6-publication-check
numeric_regression_threshold=not_adopted_first_production_series
anti_hang_budget_is_sla=false
curriculum_content=false
production_traceability_ids_allocated=false
EOF

now_ns() {
  date +%s%N
}

publish_evidence() {
  cp -R "$STAGING_ROOT"/. "$FINAL_OUT_ROOT"/
}

measure() {
  local workload="$1" iteration="$2" warmup="$3" artifact_state="$4"
  shift 4
  local start end elapsed status result log_path
  log_path="$LOG_DIR/${workload}-${iteration}-warmup-${warmup}.log"
  start="$(now_ns)"
  if timeout --foreground --signal=TERM "${TIMEOUT_SECONDS}s" "$@" >"$log_path" 2>&1; then
    status=0
  else
    status=$?
  fi
  end="$(now_ns)"
  elapsed=$(( (end - start) / 1000000 ))
  if [[ "$status" -eq 0 ]]; then result=pass; else result=fail; fi
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%s,%s,%d,%s\n' \
    "$PROTOCOL" "$SCHEMA" "$SUBJECT_HEAD_SHA" "$SUBJECT_INTEGRATION_SHA" \
    "$LEAN_TOOLCHAIN" "$MATHLIB_REVISION" "${RUNNER_OS:-unreported}" \
    "${RUNNER_ARCH:-unreported}" "$workload" "$iteration" "$warmup" \
    "$artifact_state" "$elapsed" "$result" >> "$CSV"
  if [[ "$status" -ne 0 ]]; then
    cat "$log_path" >&2
    return "$status"
  fi
  printf 'p6-integration:pass:%s:iteration=%d:warmup=%s:wall_ms=%d\n' \
    "$workload" "$iteration" "$warmup" "$elapsed"
}

run_series() {
  local workload="$1" artifact_state="$2"
  shift 2
  measure "$workload" 0 true "$artifact_state" "$@"
  local iteration
  for ((iteration=1; iteration<=REPETITIONS; iteration++)); do
    measure "$workload" "$iteration" false "$artifact_state" "$@"
  done
}

if [[ "$FORCE_FAILURE" == 1 ]]; then
  if measure forced-command-failure 1 false fixture false; then
    fixture_status=0
  else
    fixture_status=$?
  fi
  publish_evidence
  printf 'p6-integration:error:forced-command-failure:exit=%d\n' "$fixture_status" >&2
  exit "${fixture_status:-1}"
fi

run_series clean-formal-math-build root_clean \
  bash -c 'lake clean && lake build --wfail FormalMath'
run_series warm-noop-formal-math-build root_warm \
  lake build --wfail FormalMath
run_series traceability-validate root_warm \
  bash -c 'lake build --wfail \
    Mathlib.FieldTheory.Finite.Basic \
    Mathlib.Combinatorics.SimpleGraph.Acyclic \
    Mathlib.Computability.AkraBazzi.AkraBazzi && \
    lake exe traceability validate'
run_series p6-publication-check root_warm \
  python3 Quality/check-p6-publication.py

python3 - "$CSV" "$SUMMARY" "$REPETITIONS" <<'PY'
import csv
import json
import statistics
import sys
from collections import defaultdict
from pathlib import Path

csv_path, summary_path, expected_text = sys.argv[1:]
expected = int(expected_text)
groups = defaultdict(list)
with Path(csv_path).open(newline="", encoding="utf-8") as handle:
    for row in csv.DictReader(handle):
        if row["warmup"] == "false":
            if row["result"] != "pass":
                raise SystemExit(f"p6-integration:error:failed-row:{row['workload']}")
            groups[row["workload"]].append(int(row["wall_ms"]))

required = (
    "clean-formal-math-build",
    "warm-noop-formal-math-build",
    "traceability-validate",
    "p6-publication-check",
)
if tuple(groups) != required:
    raise SystemExit(f"p6-integration:error:workload-order:{tuple(groups)}")

summary = {"protocol": "P6-M6.8-INTEGRATION-PERF-v1", "threshold": None, "workloads": {}}
for workload in required:
    values = groups[workload]
    if len(values) != expected:
        raise SystemExit(
            f"p6-integration:error:measurement-count:{workload}:expected={expected}:actual={len(values)}"
        )
    summary["workloads"][workload] = {
        "count": len(values),
        "min_ms": min(values),
        "median_ms": statistics.median(values),
        "max_ms": max(values),
    }

Path(summary_path).write_text(
    json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

publish_evidence
printf 'p6-integration:summary:pass:out=%s\n' "$FINAL_OUT_ROOT"
