#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

root="${P6_PEDAGOGY_ROOT:-.}"
files=(
  "$root/FormalMath/Relations/Examples/Composition.lean"
  "$root/FormalMath/Geometry/Examples/Symmetry.lean"
  "$root/FormalMath/Measurement/Examples/Mensuration.lean"
  "$root/FormalMath/Measurement/Exercises/Mensuration.lean"
)

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'p6-pedagogy:error:missing-file:%s\n' "$file" >&2
    exit 1
  fi
done

actual="$(
  grep -hE '^public theorem [A-Za-z0-9_]+' "${files[@]}" |
    sed -E 's/^public theorem ([A-Za-z0-9_]+).*/\1/' |
    LC_ALL=C sort
)"
expected="$(printf '%s\n' bool_univ_invariant_under_id rectangle_three_four_perimeter_ne_area rectangle_three_four_values rectangularPrism_two_three_four_solution successor_then_double_graph_contains_three_eight | LC_ALL=C sort)"

if [[ "${P6_PEDAGOGY_EXTRA_DECLARATION_FIXTURE:-0}" == "1" ]]; then
  actual="$(printf '%s\nunplannedPedagogyFixture\n' "$actual" | LC_ALL=C sort)"
fi

if [[ "$actual" != "$expected" ]]; then
  printf 'p6-pedagogy:error:unplanned-public-surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
  exit 1
fi

if grep -nE '^public (def|lemma|abbrev|instance) |(^|[[:space:]])notation[0-9]*' "${files[@]}"; then
  printf 'p6-pedagogy:error:forbidden-surface-kind\n' >&2
  exit 1
fi

exports=(
  'public import FormalMath.Relations.Examples.Composition'
  'public import FormalMath.Geometry.Examples.Symmetry'
  'public import FormalMath.Measurement.Examples.Mensuration'
  'public import FormalMath.Measurement.Exercises.Mensuration'
)
for export_line in "${exports[@]}"; do
  if [[ "${P6_PEDAGOGY_MISSING_EXPORT_FIXTURE:-0}" == "1" && "$export_line" == 'public import FormalMath.Relations.Examples.Composition' ]]; then
    printf 'p6-pedagogy:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
  if ! grep -Fxq "$export_line" "$root/FormalMath.lean"; then
    printf 'p6-pedagogy:error:missing-root-export:%s\n' "$export_line" >&2
    exit 1
  fi
done

if ! grep -Fq 'import QualityTests.P6Pedagogy' "$root/QualityTests.lean"; then
  printf 'p6-pedagogy:error:missing-compatibility-contract\n' >&2
  exit 1
fi

direct_imports="$(grep -hE '^public import ' "${files[@]}" | wc -l)"
if [[ "$direct_imports" -ne 4 ]] || grep -hE '^public import Mathlib\.' "${files[@]}"; then
  printf 'p6-pedagogy:error:dependency-blast-radius\n' >&2
  exit 1
fi

printf 'p6-pedagogy:pass:theorems=5;modules=4;root-exports=4;new-mathlib-imports=0\n'
