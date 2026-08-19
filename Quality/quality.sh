#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -uo pipefail

REPORT_DIR="${QUALITY_REPORT_DIR:-.lake/build/quality}"
mkdir -p "$REPORT_DIR"

usage() {
  cat <<'EOF'
Usage: bash Quality/quality.sh <command> [dimension]

Commands:
  env         Resolve/verify the governed Lean/Lake/dependency environment.
  build       Build the complete FormalMath target with warnings as failures.
  proof       Build/run production proof and axiom assurance checks.
  source      Run production source/import/API-boundary checks.
  regression  Run positive regressions and deliberate negative controls.
  all         Run env, then every quality dimension with independent results.
  report      Print the latest compact report for the current SHA (optionally one dimension).

Every executed dimension writes a revision-bound compact .report file and a diagnostic .log file
under .lake/build/quality by default. `all` is convenience orchestration only; dimension reports
remain the canonical execution records.
EOF
}

current_sha() { git rev-parse HEAD; }
current_short_sha() { git rev-parse --short=12 HEAD; }
current_ref() { git symbolic-ref --short -q HEAD || printf 'detached'; }
manifest_blob() { git hash-object lake-manifest.json 2>/dev/null || printf 'missing'; }
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
file_timestamp() { date -u '+%Y%m%dT%H%M%SZ'; }

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
quality_report_version=1
dimension=$dimension
status=$status_name
exit_code=$exit_code
git_sha=$(current_sha)
git_ref=$(current_ref)
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

run_recorded() {
  local dimension="$1"
  shift
  local command_text
  printf -v command_text '%q ' "$@"
  command_text="${command_text% }"

  local short_sha stamp base log_path report_path started_at finished_at status status_name
  short_sha="$(current_short_sha)"
  stamp="$(file_timestamp)"
  base="$REPORT_DIR/${dimension}-${short_sha}-${stamp}"
  log_path="${base}.log"
  report_path="${base}.report"
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
  run_recorded env bash -c \
    'lake update && git diff --exit-code -- lean-toolchain lakefile.toml lake-manifest.json && lake exe cache get'
}

run_build() {
  run_recorded build lake build --wfail FormalMath
}

run_proof() {
  run_recorded proof bash -c \
    'lake build --wfail +Quality.AxiomAudit && lake env lean -DwarningAsError=true Quality/RunAxiomAudit.lean && lake env lean -DwarningAsError=true Quality/Fixtures/StandardAxiom.lean'
}

run_source() {
  run_recorded source bash Quality/check-source-quality.sh production
}

run_regression() {
  run_recorded regression bash Quality/run-regression-tests.sh
}

write_skip_report() {
  local dimension="$1"
  local reason="$2"
  local short_sha stamp report_path now
  short_sha="$(current_short_sha)"
  stamp="$(file_timestamp)"
  report_path="$REPORT_DIR/${dimension}-${short_sha}-${stamp}.report"
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
  local short_sha pattern latest
  short_sha="$(current_short_sha)"
  if [[ -n "$dimension" ]]; then
    pattern="$REPORT_DIR/${dimension}-${short_sha}-"'*.report'
  else
    pattern="$REPORT_DIR/"'*'"-${short_sha}-"'*.report'
  fi
  latest=$(ls -1t $pattern 2>/dev/null | head -n 1 || true)
  if [[ -z "$latest" ]]; then
    printf 'quality-report:error:no-report-for-current-sha:%s\n' "$short_sha" >&2
    return 2
  fi
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
