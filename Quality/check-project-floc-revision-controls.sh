#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

FLOC_FILE="metadata/formal-artifacts/floc/000001-001000.jsonl"
source_file="FormalMath/Algebra/FactoredEquation.lean"
recorded_revision="$(sed -n '1s/.*"revision":"\([^"]*\)".*/\1/p' "$FLOC_FILE")"
recorded_anchor="$(sed -n '1s/.*"structural_anchors":\["git-blob:\([0-9a-f]*\)"\].*/\1/p' "$FLOC_FILE")"
current_revision="$(git rev-parse HEAD)"
current_anchor="$(git hash-object "$source_file")"

[[ -n "$recorded_revision" && -n "$recorded_anchor" ]]
[[ "$recorded_revision" != "$current_revision" ]]
[[ "$recorded_anchor" == "$current_anchor" ]]
lake exe traceability validate | grep -Fq 'traceability:resolve:pass:current-modules=17;declarations=25'
printf 'project-floc-revision-control:pass:metadata-descendant\n'

backup="$(mktemp)"
cp "$source_file" "$backup"
restore() {
  cp "$backup" "$source_file"
  rm -f "$backup"
}
trap restore EXIT
printf '\n-- synthetic source drift\n' >> "$source_file"
set +e
output="$(lake exe traceability validate 2>&1)"
status=$?
set -e
if [[ "$status" -eq 0 ]]; then
  printf 'project-floc-revision-control:fail:source-drift-accepted\n' >&2
  exit 1
fi
grep -Fq 'traceability:error:resolve:project-source-drift:FLOC-P2-000001' <<<"$output"
printf 'project-floc-revision-control:pass:source-drift-rejected\n'
restore
trap - EXIT
lake exe traceability validate | grep -Fq 'traceability:resolve:pass:current-modules=17;declarations=25'
printf 'project-floc-revision-control:summary:pass\n'
