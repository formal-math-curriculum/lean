#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

mode="${1:-production}"
target="${2:-}"

failures=0
advisories=0
files_checked=0
WARNING_EXCEPTIONS="Quality/warning-suppression-exceptions.tsv"

error() {
  local file="$1"
  local rule="$2"
  local detail="$3"
  printf 'source-quality:error:%s:%s:%s\n' "$file" "$rule" "$detail" >&2
  failures=$((failures + 1))
}

advisory() {
  local file="$1"
  local rule="$2"
  local detail="$3"
  printf 'source-quality:advisory:%s:%s:%s\n' "$file" "$rule" "$detail"
  advisories=$((advisories + 1))
}

is_forbidden_transitive_root() {
  case "$1" in
    Batteries|Batteries.*|Aesop|Aesop.*|Qq|Qq.*|ProofWidgets|ProofWidgets.*|\
    LeanSearchClient|LeanSearchClient.*|Plausible|Plausible.*|Cli|Cli.*|\
    ImportGraph|ImportGraph.*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

warning_suppression_allowed() {
  local file="$1"
  [[ -f "$WARNING_EXCEPTIONS" ]] || return 1
  awk -F '\t' -v file="$file" '
    $0 !~ /^#/ && $1 == file && $2 ~ /^CEXC-M2-/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$WARNING_EXCEPTIONS"
}

check_header() {
  local file="$1"
  local prefix
  prefix="$(head -n 12 "$file")"
  if ! grep -Fq 'License: see the repository LICENSE file.' <<<"$prefix"; then
    error "$file" "source-header" "missing governed repository-license header"
  fi
  if ! grep -Fq 'Authors: Formal Mathematics Curriculum contributors' <<<"$prefix"; then
    error "$file" "source-header" "missing governed authors header"
  fi
}

check_module_doc() {
  local file="$1"
  if ! head -n 100 "$file" | grep -Fq '/-!'; then
    error "$file" "module-doc" "supported module lacks a module docstring"
  fi
}

check_warning_policy() {
  local file="$1"
  local line line_no code
  line_no=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    code="${line%%--*}"
    if [[ "$code" =~ ^[[:space:]]*set_option[[:space:]]+warningAsError[[:space:]]+false([[:space:]]+in)?([[:space:]]|$) ]]; then
      if warning_suppression_allowed "$file"; then
        advisory "$file:$line_no" "warning-suppression-exception" "local warningAsError suppression allowed by governed CEXC entry"
      else
        error "$file:$line_no" "warning-suppression-disabled" "local warningAsError=false is prohibited without a governed CEXC exception"
      fi
    fi
  done < "$file"
}

check_imports() {
  local file="$1"
  local profile="${2:-production}"
  local line line_no code qualifiers modules module public_import
  line_no=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    code="${line%%--*}"
    if [[ "$code" =~ ^[[:space:]]*((public|meta)[[:space:]]+)*import[[:space:]]+(.+)$ ]]; then
      qualifiers="${BASH_REMATCH[1]}"
      modules="${BASH_REMATCH[3]}"
      public_import=0
      if [[ "$qualifiers" == *public* ]]; then
        public_import=1
      fi
      for module in $modules; do
        module="${module%%,*}"
        [[ -z "$module" ]] && continue
        if [[ "$profile" == "production" && "$module" == "FormalMath" ]]; then
          error "$file:$line_no" "root-umbrella-import" "production modules must import semantic dependencies, not the FormalMath umbrella"
        fi
        if is_forbidden_transitive_root "$module"; then
          error "$file:$line_no" "ungoverned-transitive-import" "direct import of transitive package module '$module' is not governed as a project dependency"
        fi
        if (( public_import )) && { [[ "$module" == "FormalMath.Internal" ]] || [[ "$module" == FormalMath.Internal.* ]]; }; then
          error "$file:$line_no" "internal-reexport" "supported source must not publicly re-export FormalMath.Internal"
        fi
        if [[ "$module" == "Mathlib" ]]; then
          advisory "$file:$line_no" "broad-mathlib-import" "broad Mathlib import requires human import-cost review"
        fi
      done
    fi
  done < "$file"
}

check_math_file() {
  local file="$1"
  files_checked=$((files_checked + 1))
  check_header "$file"
  check_module_doc "$file"
  check_warning_policy "$file"
  check_imports "$file" production
}

check_test_file() {
  local file="$1"
  files_checked=$((files_checked + 1))
  check_header "$file"
  check_module_doc "$file"
  check_warning_policy "$file"
  check_imports "$file" test
}

check_tooling_file() {
  local file="$1"
  files_checked=$((files_checked + 1))
  check_header "$file"
  check_warning_policy "$file"
}

check_path_as_math() {
  local path="$1"
  if [[ -f "$path" ]]; then
    check_math_file "$path"
  elif [[ -d "$path" ]]; then
    while IFS= read -r file; do
      check_math_file "$file"
    done < <(find "$path" -type f -name '*.lean' -print | LC_ALL=C sort)
  else
    printf 'source-quality:error:%s:input:fixture/target path does not exist\n' "$path" >&2
    exit 2
  fi
}

check_path_as_test() {
  local path="$1"
  if [[ -f "$path" ]]; then
    check_test_file "$path"
  elif [[ -d "$path" ]]; then
    while IFS= read -r file; do
      check_test_file "$file"
    done < <(find "$path" -type f -name '*.lean' -print | LC_ALL=C sort)
  else
    printf 'source-quality:error:%s:input:test fixture/target path does not exist\n' "$path" >&2
    exit 2
  fi
}

case "$mode" in
  production)
    [[ -f FormalMath.lean ]] || { printf 'source-quality:error:FormalMath.lean:input:missing root umbrella\n' >&2; exit 2; }
    check_math_file FormalMath.lean

    while IFS= read -r file; do
      check_math_file "$file"
    done < <(find FormalMath -type f -name '*.lean' -print | LC_ALL=C sort)

    if [[ -d Quality ]]; then
      while IFS= read -r file; do
        check_tooling_file "$file"
      done < <(find Quality -type f -name '*.lean' ! -path 'Quality/Fixtures/*' -print | LC_ALL=C sort)
    fi

    if [[ -f QualityTests.lean ]]; then
      check_test_file QualityTests.lean
    fi
    if [[ -d QualityTests ]]; then
      while IFS= read -r file; do
        check_test_file "$file"
      done < <(find QualityTests -type f -name '*.lean' -print | LC_ALL=C sort)
    fi
    ;;
  fixture)
    [[ -n "$target" ]] || { printf 'usage: %s fixture <file-or-directory>\n' "$0" >&2; exit 2; }
    check_path_as_math "$target"
    ;;
  test-fixture)
    [[ -n "$target" ]] || { printf 'usage: %s test-fixture <file-or-directory>\n' "$0" >&2; exit 2; }
    check_path_as_test "$target"
    ;;
  *)
    printf 'usage: %s [production | fixture <file-or-directory> | test-fixture <file-or-directory>]\n' "$0" >&2
    exit 2
    ;;
esac

printf 'source-quality:summary:mode=%s;files=%d;failures=%d;advisories=%d\n' \
  "$mode" "$files_checked" "$failures" "$advisories"

if (( failures > 0 )); then
  exit 1
fi
