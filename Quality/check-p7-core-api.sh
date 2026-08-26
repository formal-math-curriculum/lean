#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P7_CORE_API_ROOT:-.}"
file="${P7_CORE_API_FILE:-$root/FormalMath/Algorithms/Correctness.lean}"

if [[ ! -f "$file" ]]; then
  printf 'p7-core-api:error:missing-file:%s\n' "$file" >&2
  exit 1
fi

surface_pattern='^[[:space:]]*(@\[[^]]*\][[:space:]]*)*public[[:space:]]+'
authorized_pattern='^[[:space:]]*(@\[[^]]*\][[:space:]]*)*public[[:space:]]+def[[:space:]]+IsCorrectFor([^A-Za-z0-9_]|$)'
instance_pattern='^[[:space:]]*(@\[[^]]*\][[:space:]]*)*((public|private|protected|local)[[:space:]]+)*instance[[:space:]]'
notation_pattern='(^|[[:space:]])notation[0-9]*[[:space:]]'
import_pattern='^[[:space:]]*(public[[:space:]]+)?import([[:space:]]+all)?[[:space:]]+'

surface_lines="$({ grep -hE "$surface_pattern" "$file" || true; })"
surface_count="$(awk 'NF { count++ } END { print count + 0 }' <<<"$surface_lines")"
authorized_count="$({ grep -hEc "$authorized_pattern" "$file" || true; })"
actual="$(
  sed -E 's/^[[:space:]]*(@\[[^]]*\][[:space:]]*)*public[[:space:]]+//' <<<"$surface_lines" |
    LC_ALL=C sort
)"
expected="def IsCorrectFor"

if (( surface_count != 1 || authorized_count != 1 )); then
  printf 'p7-core-api:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

instance_count="$(grep -cE "$instance_pattern" "$file" || true)"
notation_count="$(grep -cE "$notation_pattern" "$file" || true)"
if (( instance_count > 0 || notation_count > 0 )); then
  grep -nE "$instance_pattern|$notation_pattern" "$file" || true
  printf 'p7-core-api:error:forbidden-surface-kind\n' >&2
  exit 1
fi

import_count="$(grep -cE "$import_pattern" "$file" || true)"
if (( import_count > 0 )); then
  grep -nE "$import_pattern" "$file" || true
  printf 'p7-core-api:error:unplanned-import\n' >&2
  exit 1
fi

export_line='public import FormalMath.Algorithms.Correctness'
if [[ "${P7_CORE_API_MISSING_EXPORT_FIXTURE:-0}" == "1" ]] ||
   ! grep -Fxq "$export_line" "$root/FormalMath.lean"; then
  printf 'p7-core-api:error:missing-root-export:%s\n' "$export_line" >&2
  exit 1
fi

if ! grep -Fq 'import QualityTests.P7CoreApi' "$root/QualityTests.lean"; then
  printf 'p7-core-api:error:missing-compatibility-contract\n' >&2
  exit 1
fi

definition_count="$authorized_count"
printf 'p7-core-api:pass:definitions=%d;modules=1;root-exports=1;imports=%d;instances=%d;notations=%d;compatibility-contract=present\n' \
  "$definition_count" "$import_count" "$instance_count" "$notation_count"
