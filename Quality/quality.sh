#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -uo pipefail

REPORT_DIR="${QUALITY_REPORT_DIR:-.lake/build/quality}"
BASELINE_FILE="${QUALITY_BASELINE_FILE:-Quality/environment-baseline.env}"
mkdir -p "$REPORT_DIR"

usage() {
  cat <<'EOF'
Usage: bash Quality/quality.sh <command> [dimension]

Commands:
  env         Validate the selected Lean/Lake/dependency environment; cache warmup is best-effort.
  build       Validate selected environment, then build complete FormalMath with warnings as failures.
  proof       Validate selected environment, build FormalMath proof-audit inputs, then run production proof/axiom assurance.
  source      Validate selected environment, then run source/import/API-boundary and authored traceability integrity checks.
  regression  Validate selected environment, then run positive regressions and negative controls.
  all         Run env, then every quality dimension with independent results.
  report      Print the latest compact report for the current full SHA (optionally one dimension).

Every semantic dimension enforces the selected M2.5 environment before it can emit PASS. Each run
writes a unique revision-bound directory with `result.report` and `output.log` under
`.lake/build/quality` by default. `all` is orchestration only; dimension records remain canonical.
EOF
}

current_sha() { git rev-parse HEAD; }
current_ref() { git symbolic-ref --short -q HEAD || printf 'detached'; }
manifest_blob() { git hash-object lake-manifest.json 2>/dev/null || printf 'missing'; }
baseline_blob() { git hash-object "$BASELINE_FILE" 2>/dev/null || printf 'missing'; }
resolved_mathlib() {
  if [[ -d .lake/packages/mathlib/.git ]]; then
    git -C .lake/packages/mathlib rev-parse HEAD 2>/dev/null || printf 'unresolved'
  else
    printf 'unresolved'
  fi
}
lean_version() { lean --version 2>&1 | head -n 1 || true; }
lake_version() { lake --version 2>&1 | head -n 1 || true; }
platform_string() { uname -srm; }
timestamp_utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

write_report() {
  local dimension="$1"
  local command_text="$2"
  local status_name="$3"
  local exit_code="$4"
  local log_path="$5"
  local started_at="$6"
  local finished_at="$7"
  local report_path="$8"

  cat > "$report_path" <<EOF
quality_report_version=2
dimension=$dimension
status=$status_name
exit_code=$exit_code
git_sha=$(current_sha)
git_ref=$(current_ref)
selected_environment_baseline=$BASELINE_FILE
selected_environment_baseline_git_blob=$(baseline_blob)
lean_toolchain=$(tr -d '\n' < lean-toolchain 2>/dev/null || printf 'missing')
lean_version=$(lean_version)
lake_version=$(lake_version)
mathlib_revision=$(resolved_mathlib)
lake_manifest_git_blob=$(manifest_blob)
platform=$(platform_string)
started_at_utc=$started_at
finished_at_utc=$finished_at
command=$command_text
log_path=$log_path
EOF
}

new_run_dir() {
  bash Quality/create-quality-run-dir.sh "$1" "$(current_sha)"
}

run_recorded() {
  local dimension="$1"
  shift
  local command_text
  printf -v command_text '%q ' "$@"
  command_text="${command_text% }"

  local run_dir log_path report_path started_at finished_at status status_name
  run_dir="$(new_run_dir "$dimension")" || return $?
  log_path="$run_dir/output.log"
  report_path="$run_dir/result.report"
  started_at="$(timestamp_utc)"

  printf 'quality-command:start:%s:%s\n' "$dimension" "$command_text"
  "$@" 2>&1 | tee "$log_path"
  status=${PIPESTATUS[0]}
  finished_at="$(timestamp_utc)"

  if [[ "$status" -eq 0 ]]; then
    status_name=pass
  else
    status_name=fail
  fi
  write_report "$dimension" "$command_text" "$status_name" "$status" "$log_path" \
    "$started_at" "$finished_at" "$report_path"
  printf 'quality-command:result:%s:%s:exit=%d:report=%s\n' \
    "$dimension" "$status_name" "$status" "$report_path"
  return "$status"
}

run_env() {
  run_recorded env bash -c '
    bash Quality/check-environment.sh semantic || exit $?
    if bash Quality/check-environment.sh cache; then
      printf "quality-env:cache:pass\n"
    else
      status=$?
      printf "quality-env:cache:nonblocking-fail:exit=%d\n" "$status"
    fi
    exit 0
  '
}

run_build() {
  run_recorded build bash -c \
    'bash Quality/check-environment.sh semantic && lake build --wfail FormalMath'
}

run_proof() {
  run_recorded proof bash -c \
    'bash Quality/check-environment.sh semantic && lake build --wfail FormalMath && lake build --wfail +Quality.AxiomAudit && lake env lean -DwarningAsError=true Quality/RunAxiomAudit.lean && lake env lean -DwarningAsError=true Quality/Fixtures/StandardAxiom.lean'
}

run_source() {
  run_recorded source bash -c \
    'bash Quality/check-environment.sh semantic && bash Quality/check-source-quality.sh production && lake exe traceability validate'
}

run_regression() {
  run_recorded regression bash -c \
    'bash Quality/check-environment.sh semantic && bash Quality/run-regression-tests.sh'
}

write_skip_report() {
  local dimension="$1"
  local reason="$2"
  local run_dir report_path now
  run_dir="$(new_run_dir "$dimension")" || return $?
  report_path="$run_dir/result.report"
  now="$(timestamp_utc)"
  write_report "$dimension" "not-run" skipped 125 "none" "$now" "$now" "$report_path"
  printf 'skip_reason=%s\n' "$reason" >> "$report_path"
  printf 'quality-command:result:%s:skipped:reason=%s:report=%s\n' "$dimension" "$reason" "$report_path"
}

run_all() {
  local env_status aggregate=0 status dimension
  run_env
  env_status=$?
  if [[ "$env_status" -ne 0 ]]; then
    for dimension in build proof source regression; do
      write_skip_report "$dimension" environment-failed
    done
    printf 'quality-all:fail:environment-failed\n' >&2
    return "$env_status"
  fi

  for dimension in build proof source regression; do
    case "$dimension" in
      build) run_build ;;
      proof) run_proof ;;
      source) run_source ;;
      regression) run_regression ;;
    esac
    status=$?
    if [[ "$status" -ne 0 ]]; then
      aggregate=1
    fi
  done

  if [[ "$aggregate" -eq 0 ]]; then
    printf 'quality-all:pass\n'
  else
    printf 'quality-all:fail:one-or-more-dimensions-failed\n' >&2
  fi
  return "$aggregate"
}

show_report() {
  local dimension="${1:-}"
  local sha latest
  local -a matches=()
  sha="$(current_sha)"
  shopt -s nullglob
  if [[ -n "$dimension" ]]; then
    matches=("$REPORT_DIR/${dimension}-${sha}-"*/result.report)
  else
    matches=("$REPORT_DIR/"*"-${sha}-"*/result.report)
  fi
  shopt -u nullglob
  if (( ${#matches[@]} == 0 )); then
    printf 'quality-report:error:no-report-for-current-sha:%s\n' "$sha" >&2
    return 2
  fi
  latest="$(ls -1t "${matches[@]}" | head -n 1)"
  cat "$latest"
}

case "${1:-}" in
  env) run_env ;;
  build) run_build ;;
  proof) run_proof ;;
  source) run_source ;;
  regression) run_regression ;;
  all) run_all ;;
  report) show_report "${2:-}" ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 2 ;;
esac
