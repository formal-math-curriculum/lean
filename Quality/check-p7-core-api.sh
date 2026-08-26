#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P7_CORE_API_ROOT:-.}"
file="$root/FormalMath/Algorithms/Correctness.lean"

if [[ ! -f "$file" ]]; then
  printf 'p7-core-api:error:missing-file:%s\n' "$file" >&2
  exit 1
fi

actual="$(
  grep -hE '^public (def|theorem|lemma|abbrev|structure|class|instance) [A-Za-z0-9_]+' "$file" |
    sed -E 's/^public (def|theorem|lemma|abbrev|structure|class|instance) ([A-Za-z0-9_]+).*/\2/' |
    LC_ALL=C sort
)"
expected="IsCorrectFor"

if [[ "${P7_CORE_API_EXTRA_DECLARATION_FIXTURE:-0}" == "1" ]]; then
  actual="$(printf '%s\nunplannedFixture\n' "$actual" | LC_ALL=C sort)"
fi

if [[ "$actual" != "$expected" ]]; then
  printf 'p7-core-api:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

if grep -nE '^public (theorem|lemma|abbrev|structure|class|instance) |(^|[[:space:]])notation[0-9]*|^instance ' "$file"; then
  printf 'p7-core-api:error:forbidden-surface-kind\n' >&2
  exit 1
fi

if grep -nE '^(public[[:space:]]+)?import([[:space:]]+all)?[[:space:]]+' "$file"; then
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

printf 'p7-core-api:pass:definitions=1;modules=1;root-exports=1;imports=0;instances=0;notations=0;compatibility-contract=present\n'
