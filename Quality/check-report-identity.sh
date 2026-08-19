#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
list="$tmp/ids.txt"
sha="$(git rev-parse HEAD)"

for _ in {1..64}; do
  QUALITY_REPORT_DIR="$tmp/reports" bash Quality/create-quality-run-dir.sh source "$sha" >> "$list" &
done
wait

lines="$(wc -l < "$list" | tr -d ' ')"
unique="$(sort -u "$list" | wc -l | tr -d ' ')"
dirs="$(find "$tmp/reports" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

if [[ "$lines" != "64" || "$unique" != "64" || "$dirs" != "64" ]]; then
  printf 'quality-report-identity:error:lines=%s;unique=%s;dirs=%s\n' "$lines" "$unique" "$dirs" >&2
  exit 1
fi

printf 'quality-report-identity:pass:parallel=64;unique=64;sha=%s\n' "$sha"
