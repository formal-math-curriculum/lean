#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P6_RESULTS_ROOT:-.}"
files=(
  "$root/FormalMath/Relations/GraphResults.lean"
  "$root/FormalMath/Geometry/SymmetryResults.lean"
  "$root/FormalMath/Measurement/MensurationResults.lean"
)

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'p6-results:error:missing-file:%s\n' "$file" >&2
    exit 1
  fi
done

actual="$(
  grep -hE '^public theorem [A-Za-z0-9_]+' "${files[@]}" |
    sed -E 's/^public theorem ([A-Za-z0-9_]+).*/\1/' |
    LC_ALL=C sort
)"
expected="$(printf '%s\n' isInvariantUnder_id mem_graphOf_iff rectangleArea_comm rectanglePerimeter_comm rectangularPrismVolume_swap_length_width | LC_ALL=C sort)"

if [[ "${P6_RESULTS_EXTRA_DECLARATION_FIXTURE:-0}" == "1" ]]; then
  actual="$(printf '%s\nunplannedResultFixture\n' "$actual" | LC_ALL=C sort)"
fi

if [[ "$actual" != "$expected" ]]; then
  printf 'p6-results:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

if grep -nE '^public (def|lemma|abbrev|instance) |(^|[[:space:]])notation[0-9]*' "${files[@]}"; then
  printf 'p6-results:error:forbidden-surface-kind\n' >&2
  exit 1
fi

exports=(
  'public import FormalMath.Geometry.SymmetryResults'
  'public import FormalMath.Measurement.MensurationResults'
  'public import FormalMath.Relations.GraphResults'
)
for export_line in "${exports[@]}"; do
  if [[ "${P6_RESULTS_MISSING_EXPORT_FIXTURE:-0}" == "1" && "$export_line" == 'public import FormalMath.Relations.GraphResults' ]]; then
    printf 'p6-results:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
  if ! grep -Fxq "$export_line" "$root/FormalMath.lean"; then
    printf 'p6-results:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
done

if ! grep -Fq 'import QualityTests.P6FundamentalResults' "$root/QualityTests.lean"; then
  printf 'p6-results:error:missing-compatibility-contract\n' >&2
  exit 1
fi

printf 'p6-results:pass:theorems=5;modules=3;root-exports=3;compatibility-contract=present\n'
