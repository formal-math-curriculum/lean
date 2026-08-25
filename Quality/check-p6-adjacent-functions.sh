#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P6_ADJACENT_ROOT:-.}"
file="$root/FormalMath/Relations/CompositionResults.lean"

if [[ ! -f "$file" ]]; then
  printf 'p6-adjacent:error:missing-file:%s\n' "$file" >&2
  exit 1
fi

actual="$(
  grep -E '^public theorem [A-Za-z0-9_]+' "$file" |
    sed -E 's/^public theorem ([A-Za-z0-9_]+).*/\1/' |
    LC_ALL=C sort
)"
expected="mem_graphOf_comp_iff"

if [[ "${P6_ADJACENT_EXTRA_DECLARATION_FIXTURE:-0}" == "1" ]]; then
  actual="$(printf '%s\nunplannedAdjacentFixture\n' "$actual" | LC_ALL=C sort)"
fi

if [[ "$actual" != "$expected" ]]; then
  printf 'p6-adjacent:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

if grep -nE '^public (def|lemma|abbrev|instance) |(^|[[:space:]])notation[0-9]*' "$file"; then
  printf 'p6-adjacent:error:forbidden-surface-kind\n' >&2
  exit 1
fi

export_line='public import FormalMath.Relations.CompositionResults'
if [[ "${P6_ADJACENT_MISSING_EXPORT_FIXTURE:-0}" == "1" ]]; then
  printf 'p6-adjacent:error:missing-root-export:%s\n' "$export_line" >&2
  exit 1
fi
if ! grep -Fxq "$export_line" "$root/FormalMath.lean"; then
  printf 'p6-adjacent:error:missing-root-export:%s\n' "$export_line" >&2
  exit 1
fi

if ! grep -Fq 'import QualityTests.P6AdjacentFunctions' "$root/QualityTests.lean"; then
  printf 'p6-adjacent:error:missing-compatibility-contract\n' >&2
  exit 1
fi

direct_imports="$(grep -cE '^public import ' "$file")"
if [[ "$direct_imports" -ne 1 ]] || ! grep -Fxq 'public import FormalMath.Relations.GraphResults' "$file"; then
  printf 'p6-adjacent:error:dependency-blast-radius\n' >&2
  exit 1
fi

printf 'p6-adjacent:pass:theorems=1;modules=1;root-exports=1;new-mathlib-imports=0\n'
