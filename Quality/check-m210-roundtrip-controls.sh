#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$ROOT"

expect_failure() {
  local label="$1"
  local signature="$2"
  shift 2
  local output status
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    printf 'm210-roundtrip:fail:%s:unexpected-success\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$signature" <<<"$output"; then
    printf 'm210-roundtrip:fail:%s:missing-signature:%s\n' "$label" "$signature" >&2
    return 1
  fi
  printf 'm210-roundtrip:pass:%s-rejected\n' "$label"
}

copy_production_root() {
  local target="$1"
  mkdir -p "$target"
  cp -a metadata "$target/metadata"
  cp -a FormalMath "$target/FormalMath"
}

printf 'm210-roundtrip:start:production-validation\n'
lake exe traceability validate | tee "$WORK/validate.log"
grep -Fq 'traceability:validate:pass:fart=3;floc=3;flink=3;curriculum-identities=2' "$WORK/validate.log"
grep -Fq 'traceability:resolve:pass:current-modules=3;declarations=3' "$WORK/validate.log"

printf 'm210-roundtrip:start:production-roundtrip\n'
lake exe traceability roundtrip | tee "$WORK/roundtrip.log"
grep -Fq 'traceability:roundtrip:pass:links=3;locator-link-checks=3' "$WORK/roundtrip.log"

printf 'm210-roundtrip:start:production-generated-views\n'
first_output="$(lake exe traceability generate)"
printf '%s\n' "$first_output"
first_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$first_output" | tail -n 1)"
[[ -n "$first_fingerprint" ]]
lake exe traceability freshness

revision="$(git rev-parse HEAD)"
generated="$ROOT/.lake/build/traceability/$revision"
for file in manifest.json by-curriculum.jsonl by-artifact.jsonl by-source.jsonl history.jsonl unresolved.jsonl index.md; do
  [[ -f "$generated/$file" ]]
done

python3 - "$generated" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])

def records(name):
    text = (root / name).read_text()
    return [json.loads(line) for line in text.splitlines() if line]

curriculum = records("by-curriculum.jsonl")
artifacts = records("by-artifact.jsonl")
sources = records("by-source.jsonl")
payload = "\n".join(json.dumps(record, sort_keys=True) for record in curriculum + artifacts + sources)

required = {
    "CAND-P1-000016",
    "CAND-P1-000017",
    "FART-P2-000001",
    "FART-P2-000002",
    "FART-P2-000003",
    "FLOC-P2-000001",
    "FLOC-P2-000002",
    "FLOC-P2-000003",
    "FLINK-P2-000001",
    "FLINK-P2-000002",
    "FLINK-P2-000003",
    "FormalMath/Algebra/FactoredEquation.lean",
    "FormalMath/Algebra/ZeroProduct.lean",
    "FormalMath/Algebra/Examples/FactoredEquation.lean",
    "FormalMath.Algebra.factoredProduct",
    "FormalMath.Algebra.factoredProduct_eq_zero_iff",
    "FormalMath.Algebra.Examples.two_five_factored_equation",
}
missing = sorted(item for item in required if item not in payload)
assert not missing, missing
assert len(artifacts) == 3, len(artifacts)
assert len(sources) == 3, len(sources)
PY

printf 'm210-roundtrip:start:forward-reverse-queries\n'
lake exe traceability query curriculum CAND-P1-000016 | tee "$WORK/cand16.jsonl"
grep -Fq 'FLINK-P2-000001' "$WORK/cand16.jsonl"
grep -Fq 'FART-P2-000001' "$WORK/cand16.jsonl"
grep -Fq 'FLOC-P2-000001' "$WORK/cand16.jsonl"

lake exe traceability query curriculum CAND-P1-000017 | tee "$WORK/cand17.jsonl"
for id in FLINK-P2-000002 FLINK-P2-000003 FART-P2-000002 FART-P2-000003 FLOC-P2-000002 FLOC-P2-000003; do
  grep -Fq "$id" "$WORK/cand17.jsonl"
done

while IFS='|' read -r declaration fart floc; do
  lake exe traceability query declaration "$declaration" | tee "$WORK/source-query.jsonl"
  grep -Fq "$fart" "$WORK/source-query.jsonl"
  grep -Fq "$floc" "$WORK/source-query.jsonl"
done <<'EOF'
FormalMath.Algebra.factoredProduct|FART-P2-000001|FLOC-P2-000001
FormalMath.Algebra.factoredProduct_eq_zero_iff|FART-P2-000002|FLOC-P2-000002
FormalMath.Algebra.Examples.two_five_factored_equation|FART-P2-000003|FLOC-P2-000003
EOF

printf 'm210-roundtrip:start:derived-rebuild\n'
rm -rf "$generated"
second_output="$(lake exe traceability generate)"
printf '%s\n' "$second_output"
second_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$second_output" | tail -n 1)"
[[ "$first_fingerprint" == "$second_fingerprint" ]]
lake exe traceability freshness
git diff --exit-code -- metadata
printf 'm210-roundtrip:pass:derived-rebuild:fingerprint=%s\n' "$second_fingerprint"

printf 'm210-roundtrip:start:wrong-declaration-control\n'
wrong_declaration="$WORK/wrong-declaration"
copy_production_root "$wrong_declaration"
python3 - "$wrong_declaration/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
records = [json.loads(line) for line in path.read_text().splitlines() if line]
for record in records:
    if record["id"] == "FLOC-P2-000002":
        record["declaration_names"] = ["FormalMath.Algebra.nonexistentM210Theorem"]
path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in records))
PY
expect_failure wrong-declaration 'missing-declaration:FLOC-P2-000002' \
  lake exe traceability validate --root "$wrong_declaration"

printf 'm210-roundtrip:start:wrong-module-control\n'
wrong_module="$WORK/wrong-module"
copy_production_root "$wrong_module"
python3 - "$wrong_module/metadata/formal-artifacts/floc/000001-001000.jsonl" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
records = [json.loads(line) for line in path.read_text().splitlines() if line]
for record in records:
    if record["id"] == "FLOC-P2-000002":
        record["module_name"] = "FormalMath.Algebra.Examples.FactoredEquation"
        record["file_path"] = "FormalMath/Algebra/Examples/FactoredEquation.lean"
path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in records))
PY
expect_failure wrong-module 'declaration-module-mismatch:FLOC-P2-000002' \
  lake exe traceability validate --root "$wrong_module"

printf 'm210-roundtrip:start:stale-generated-control\n'
stale_root="$WORK/stale-generated"
copy_production_root "$stale_root"
lake exe traceability generate --root "$stale_root" >/dev/null
python3 - "$stale_root/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
records = [json.loads(line) for line in path.read_text().splitlines() if line]
records[0]["title_or_summary"] += " stale-control"
path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in records))
PY
expect_failure stale-generated 'traceability:freshness:error:registry-inputs-changed' \
  lake exe traceability freshness --root "$stale_root"

printf 'm210-roundtrip:start:external-mathlib-locator\n'
mathlib_revision="$(python3 - <<'PY'
import json
manifest = json.load(open("lake-manifest.json"))
matches = [package["rev"] for package in manifest["packages"] if package["name"] == "mathlib"]
assert len(matches) == 1, matches
print(matches[0])
PY
)"
[[ "$mathlib_revision" == 'db584cd6d46c92f209a44c0f1c829460d327499d' ]]
[[ "$(git -C .lake/packages/mathlib rev-parse HEAD)" == "$mathlib_revision" ]]
external_source='.lake/packages/mathlib/Mathlib/Data/Int/Order/Basic.lean'
grep -Fq 'protected alias ⟨eq_zero_or_eq_zero_of_mul_eq_zero, _⟩ := Int.mul_eq_zero' "$external_source"
lake env lean -DwarningAsError=true QualityTests/M210ExternalLocator.lean
printf 'm210-roundtrip:pass:external-locator:repository=leanprover-community/mathlib4;revision=%s;module=Mathlib.Data.Int.Order.Basic;declaration=Int.eq_zero_or_eq_zero_of_mul_eq_zero\n' "$mathlib_revision"

python3 - <<'PY'
import json
import pathlib

root = pathlib.Path("metadata/formal-artifacts")
records = []
for path in root.glob("*/*.jsonl"):
    records.extend(json.loads(line) for line in path.read_text().splitlines() if line)
payload = json.dumps(records, sort_keys=True)
assert "leanprover-community/mathlib4" not in payload
assert "READY" not in payload and "REQEXPR" not in payload
PY
printf 'm210-roundtrip:pass:external-dependency-not-project-or-curriculum-authority\n'
printf 'm210-roundtrip:summary:pass\n'
