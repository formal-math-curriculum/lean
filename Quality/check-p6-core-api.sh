#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P6_CORE_API_ROOT:-.}"
files=(
  "$root/FormalMath/Relations/Graph.lean"
  "$root/FormalMath/Geometry/Symmetry.lean"
  "$root/FormalMath/Measurement/Mensuration.lean"
)

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'p6-core-api:error:missing-file:%s\n' "$file" >&2
    exit 1
  fi
done

actual="$(
  grep -hE '^public (def|theorem|lemma|abbrev) [A-Za-z0-9_]+' "${files[@]}" |
    sed -E 's/^public (def|theorem|lemma|abbrev) ([A-Za-z0-9_]+).*/\2/' |
    LC_ALL=C sort
)"
expected="$(printf '%s\n' IsInvariantUnder graphOf rectangleArea rectanglePerimeter rectangularPrismVolume | LC_ALL=C sort)"

if [[ "${P6_CORE_API_EXTRA_DECLARATION_FIXTURE:-0}" == "1" ]]; then
  actual="$(printf '%s\nunplannedFixture\n' "$actual" | LC_ALL=C sort)"
fi

if [[ "$actual" != "$expected" ]]; then
  printf 'p6-core-api:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

if grep -nE '^public (theorem|lemma|abbrev) |(^|[[:space:]])notation[0-9]*' "${files[@]}"; then
  printf 'p6-core-api:error:forbidden-surface-kind\n' >&2
  exit 1
fi

if grep -nE '^(public[[:space:]]+)?import([[:space:]]+all)?[[:space:]]+Mathlib$' "${files[@]}"; then
  printf 'p6-core-api:error:broad-mathlib-root-import\n' >&2
  exit 1
fi

exports=(
  'public import FormalMath.Geometry.Symmetry'
  'public import FormalMath.Measurement.Mensuration'
  'public import FormalMath.Relations.Graph'
)
for export_line in "${exports[@]}"; do
  if [[ "${P6_CORE_API_MISSING_EXPORT_FIXTURE:-0}" == "1" && "$export_line" == 'public import FormalMath.Relations.Graph' ]]; then
    printf 'p6-core-api:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
  if ! grep -Fxq "$export_line" "$root/FormalMath.lean"; then
    printf 'p6-core-api:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
done

if ! grep -Fq 'import QualityTests.P6CoreApi' "$root/QualityTests.lean"; then
  printf 'p6-core-api:error:missing-compatibility-contract\n' >&2
  exit 1
fi

printf 'p6-core-api:pass:definitions=5;modules=3;root-exports=3;compatibility-contract=present\n'
