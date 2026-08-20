#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -uo pipefail

BASELINE_FILE="${QUALITY_BASELINE_FILE:-Quality/environment-baseline.env}"

fail() {
  local code="$1"
  local detail="$2"
  printf 'quality-env:error:%s:%s\n' "$code" "$detail" >&2
  return 1
}

load_baseline() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    fail baseline-file-missing "$BASELINE_FILE"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$BASELINE_FILE"
  local required=(
    QUALITY_ENV_BASELINE_VERSION QUALITY_LEAN_TOOLCHAIN QUALITY_LEAN_VERSION QUALITY_LEAN_COMMIT
    QUALITY_LAKE_VERSION QUALITY_MATHLIB_INPUT_REV QUALITY_MATHLIB_REV QUALITY_MANIFEST_GIT_BLOB
  )
  local name
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      fail baseline-field-missing "$name"
      return 1
    fi
  done
}

semantic_check() {
  load_baseline || return $?

  local committed_toolchain lean_output lake_output manifest_blob actual_mathlib
  committed_toolchain="$(tr -d '\n\r' < lean-toolchain 2>/dev/null || true)"
  if [[ "$committed_toolchain" != "$QUALITY_LEAN_TOOLCHAIN" ]]; then
    fail toolchain-file-mismatch "expected=$QUALITY_LEAN_TOOLCHAIN;observed=$committed_toolchain"
    return 1
  fi

  lean_output="$(lean --version 2>&1)" || {
    fail lean-unavailable "$lean_output"
    return 1
  }
  if [[ "$lean_output" != *"Lean (version $QUALITY_LEAN_VERSION"* ]] ||
     [[ "$lean_output" != *"commit $QUALITY_LEAN_COMMIT"* ]]; then
    fail effective-lean-mismatch "expected-version=$QUALITY_LEAN_VERSION;expected-commit=$QUALITY_LEAN_COMMIT;observed=$lean_output"
    return 1
  fi

  lake_output="$(lake --version 2>&1)" || {
    fail lake-unavailable "$lake_output"
    return 1
  }
  if [[ "$lake_output" != "Lake version $QUALITY_LAKE_VERSION"* ]] ||
     [[ "$lake_output" != *"Lean version $QUALITY_LEAN_VERSION"* ]]; then
    fail effective-lake-mismatch "expected=$QUALITY_LAKE_VERSION;observed=$lake_output"
    return 1
  fi

  if ! lake update; then
    fail lake-update-failed "selected dependency environment did not resolve"
    return 1
  fi

  if ! git diff --quiet HEAD -- lean-toolchain lakefile.toml lake-manifest.json; then
    fail governed-environment-drift "lean-toolchain/lakefile.toml/lake-manifest.json changed after resolution"
    return 1
  fi

  manifest_blob="$(git hash-object lake-manifest.json 2>/dev/null || true)"
  if [[ "$manifest_blob" != "$QUALITY_MANIFEST_GIT_BLOB" ]]; then
    fail manifest-baseline-mismatch "expected=$QUALITY_MANIFEST_GIT_BLOB;observed=$manifest_blob"
    return 1
  fi

  if [[ ! -d .lake/packages/mathlib/.git ]]; then
    fail mathlib-checkout-missing ".lake/packages/mathlib/.git"
    return 1
  fi
  actual_mathlib="$(git -C .lake/packages/mathlib rev-parse HEAD 2>/dev/null || true)"
  if [[ "$actual_mathlib" != "$QUALITY_MATHLIB_REV" ]]; then
    fail mathlib-revision-mismatch "expected=$QUALITY_MATHLIB_REV;observed=$actual_mathlib"
    return 1
  fi

  if ! grep -Fq "rev = \"$QUALITY_MATHLIB_INPUT_REV\"" lakefile.toml; then
    fail mathlib-input-revision-mismatch "expected lakefile rev=$QUALITY_MATHLIB_INPUT_REV"
    return 1
  fi

  printf 'quality-env:semantic:pass:baseline=%s;lean=%s;mathlib=%s;manifest=%s\n' \
    "$QUALITY_ENV_BASELINE_VERSION" "$QUALITY_LEAN_VERSION" "$actual_mathlib" "$manifest_blob"
}

cache_fetch() {
  if [[ "${QUALITY_CACHE_FAIL_FIXTURE:-0}" == "1" ]]; then
    printf 'quality-env:cache:simulated-failure\n' >&2
    return 73
  fi
  if [[ "${QUALITY_CACHE_FORCE_KILL_FIXTURE:-0}" == "1" ]]; then
    printf 'quality-env:cache:simulated-term-resistant-fetch\n' >&2
    trap '' TERM
    exec sleep 10
  fi
  if [[ "${QUALITY_CACHE_TIMEOUT_FIXTURE:-0}" == "1" ]]; then
    printf 'quality-env:cache:simulated-slow-fetch\n' >&2
    exec sleep 10
  fi
  exec lake exe cache get
}

cache_check() {
  local timeout_seconds="${QUALITY_CACHE_TIMEOUT_SECONDS:-300}"
  if [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    printf 'quality-env:cache:invalid-timeout:value=%s\n' "$timeout_seconds" >&2
    return 64
  fi

  if [[ "${QUALITY_CACHE_TIMEOUT_UNAVAILABLE_FIXTURE:-0}" == "1" ]] ||
     ! command -v timeout >/dev/null 2>&1 ||
     ! timeout --version 2>/dev/null | grep -Fq 'GNU coreutils'; then
    printf 'quality-env:cache:timeout-unavailable\n' >&2
    return 69
  fi

  local status
  timeout --foreground --signal=TERM --kill-after=5s "${timeout_seconds}s" \
    bash "$0" cache-fetch
  status=$?
  if [[ "$status" -eq 137 ]]; then
    return 124
  fi
  return "$status"
}

case "${1:-semantic}" in
  semantic) semantic_check ;;
  cache) cache_check ;;
  cache-fetch) cache_fetch ;;
  *)
    printf 'usage: %s [semantic|cache]\n' "$0" >&2
    exit 2
    ;;
esac
