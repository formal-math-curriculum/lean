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
grep -Fq 'traceability:validate:pass:fart=28;floc=29;flink=36;curriculum-identities=21' "$WORK/validate.log"
grep -Fq 'traceability:resolve:pass:current-modules=28;declarations=37' "$WORK/validate.log"

printf 'm210-roundtrip:start:production-roundtrip\n'
lake exe traceability roundtrip | tee "$WORK/roundtrip.log"
grep -Fq 'traceability:roundtrip:pass:links=36;locator-link-checks=37' "$WORK/roundtrip.log"

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
    "CAND-P1-000018",
    "CAND-P1-000004",
    "CAND-P1-000009",
    "CAND-P1-000019",
    "CAND-P1-000024",
    "CAND-P1-000027",
    "CAND-P1-000090",
    "FART-P2-000001",
    "FART-P2-000002",
    "FART-P2-000003",
    "FART-P2-000004",
    "FART-P2-000005",
    "FART-P2-000006",
    "FART-P2-000007",
    "FART-P2-000008",
    "FART-P2-000009",
    "FART-P2-000010",
    "FART-P2-000011",
    "FART-P2-000012",
    "FART-P2-000013",
    "FART-P2-000014",
    "FART-P2-000015",
    "FART-P2-000016",
    "FART-P2-000017",
    "FART-P2-000018",
    "FART-P2-000019",
    "FART-P2-000020",
    "FART-P2-000021",
    "FART-P2-000022",
    "FLOC-P2-000001",
    "FLOC-P2-000002",
    "FLOC-P2-000003",
    "FLOC-P2-000004",
    "FLOC-P2-000005",
    "FLOC-P2-000006",
    "FLOC-P2-000007",
    "FLOC-P2-000008",
    "FLOC-P2-000009",
    "FLOC-P2-000010",
    "FLOC-P2-000011",
    "FLOC-P2-000012",
    "FLOC-P2-000013",
    "FLOC-P2-000014",
    "FLOC-P2-000015",
    "FLOC-P2-000016",
    "FLOC-P2-000017",
    "FLOC-P2-000018",
    "FLOC-P2-000019",
    "FLOC-P2-000020",
    "FLOC-P2-000021",
    "FLOC-P2-000022",
    "FLOC-P2-000023",
    "FLINK-P2-000001",
    "FLINK-P2-000002",
    "FLINK-P2-000003",
    "FLINK-P2-000004",
    "FLINK-P2-000005",
    "FLINK-P2-000006",
    "FLINK-P2-000007",
    "FLINK-P2-000008",
    "FLINK-P2-000009",
    "FLINK-P2-000010",
    "FLINK-P2-000011",
    "FLINK-P2-000012",
    "FLINK-P2-000013",
    "FLINK-P2-000014",
    "FLINK-P2-000015",
    "FLINK-P2-000016",
    "FLINK-P2-000017",
    "FLINK-P2-000018",
    "FLINK-P2-000019",
    "FLINK-P2-000020",
    "FLINK-P2-000021",
    "FLINK-P2-000022",
    "FLINK-P2-000023",
    "FormalMath/Algebra/FactoredEquation.lean",
    "FormalMath/Algebra/ZeroProduct.lean",
    "FormalMath/Algebra/Examples/FactoredEquation.lean",
    "FormalMath/Algebra/Examples/FactoredIntegerEquation.lean",
    "Mathlib/Algebra/Group/Nat/Defs.lean",
    "Mathlib/Algebra/Ring/Nat.lean",
    "FormalMath/Arithmetic/Examples/NaturalNumberLaws.lean",
    "Mathlib/Algebra/Group/Int/Defs.lean",
    "Mathlib/Algebra/Ring/Int/Defs.lean",
    "FormalMath/Arithmetic/Examples/IntegerSignLaws.lean",
    "FormalMath/Arithmetic/Exercises/NaturalNumberLaws.lean",
    "FormalMath/Relations/Graph.lean",
    "FormalMath/Geometry/Symmetry.lean",
    "FormalMath/Measurement/Mensuration.lean",
    "FormalMath/Relations/GraphResults.lean",
    "FormalMath/Relations/CompositionResults.lean",
    "FormalMath/Relations/Examples/Composition.lean",
    "FormalMath/Geometry/Examples/Symmetry.lean",
    "FormalMath/Measurement/Examples/Mensuration.lean",
    "FormalMath/Measurement/Exercises/Mensuration.lean",
    "FormalMath/Algorithms/Correctness.lean",
    "FormalMath/Geometry/SymmetryResults.lean",
    "FormalMath/Measurement/MensurationResults.lean",
    "FormalMath.Arithmetic.Exercises.NaturalNumberLaws",
    "FormalMath.Relations.Graph",
    "FormalMath.Geometry.Symmetry",
    "FormalMath.Measurement.Mensuration",
    "FormalMath.Relations.GraphResults",
    "FormalMath.Relations.CompositionResults",
    "FormalMath.Relations.Examples.Composition",
    "FormalMath.Geometry.Examples.Symmetry",
    "FormalMath.Measurement.Examples.Mensuration",
    "FormalMath.Measurement.Exercises.Mensuration",
    "FormalMath.Geometry.SymmetryResults",
    "FormalMath.Measurement.MensurationResults",
    "FormalMath.Algorithms.Correctness",
    "FormalMath.Algebra.factoredProduct",
    "FormalMath.Algebra.factoredProduct_eq_zero_iff",
    "FormalMath.Algebra.Examples.two_five_factored_equation",
    "Nat.instAddCancelCommMonoid",
    "Nat.instCommMonoid",
    "Nat.instDistrib",
    "FormalMath.Arithmetic.Examples.cancel_common_nine_addend",
    "FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three",
    "Int.instAddCommGroup",
    "Int.instCommRing",
    "FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four",
    "FormalMath.Arithmetic.Examples.seven_sub_neg_three",
    "FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong",
    "FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution",
    "FormalMath.Relations.graphOf",
    "FormalMath.Geometry.IsInvariantUnder",
    "FormalMath.Measurement.rectangleArea",
    "FormalMath.Measurement.rectanglePerimeter",
    "FormalMath.Measurement.rectangularPrismVolume",
    "FormalMath.Relations.mem_graphOf_iff",
    "FormalMath.Relations.mem_graphOf_comp_iff",
    "FormalMath.Relations.Examples.successor_then_double_graph_contains_three_eight",
    "FormalMath.Geometry.Examples.bool_univ_invariant_under_id",
    "FormalMath.Measurement.Examples.rectangle_three_four_perimeter_ne_area",
    "FormalMath.Measurement.Examples.rectangle_three_four_values",
    "FormalMath.Measurement.Exercises.rectangularPrism_two_three_four_solution",
    "FormalMath.Geometry.isInvariantUnder_id",
    "FormalMath.Measurement.rectangleArea_comm",
    "FormalMath.Measurement.rectanglePerimeter_comm",
    "FormalMath.Measurement.rectangularPrismVolume_swap_length_width",
    "FormalMath.Algorithms.IsCorrectFor",
}
missing = sorted(item for item in required if item not in payload)
assert not missing, missing
assert len(artifacts) == 28, len(artifacts)
assert len(sources) == 29, len(sources)

artifact3 = next(record for record in artifacts if record["artifact_id"] == "FART-P2-000003")
assert artifact3["artifact"]["current_locator_refs"] == ["FLOC-P2-000004"]
locator3 = next(record["locator"] for record in sources if record["locator"]["id"] == "FLOC-P2-000003")
locator4 = next(record["locator"] for record in sources if record["locator"]["id"] == "FLOC-P2-000004")
assert locator3["locator_status"] == "historical"
assert locator3["superseded_by_locator_refs"] == ["FLOC-P2-000004"]
assert locator4["locator_status"] == "current"
assert locator4["supersedes_locator_refs"] == ["FLOC-P2-000003"]
PY

printf 'm210-roundtrip:start:forward-reverse-queries\n'
lake exe traceability query curriculum CAND-P1-000016 | tee "$WORK/cand16.jsonl"
grep -Fq 'FLINK-P2-000001' "$WORK/cand16.jsonl"
grep -Fq 'FART-P2-000001' "$WORK/cand16.jsonl"
grep -Fq 'FLOC-P2-000001' "$WORK/cand16.jsonl"

lake exe traceability query curriculum CAND-P1-000017 | tee "$WORK/cand17.jsonl"
for id in FLINK-P2-000002 FLINK-P2-000003 FART-P2-000002 FART-P2-000003 FLOC-P2-000002 FLOC-P2-000003 FLOC-P2-000004; do
  grep -Fq "$id" "$WORK/cand17.jsonl"
done

lake exe traceability query curriculum CAND-P1-000004 | tee "$WORK/cand4.jsonl"
for id in FLINK-P2-000004 FLINK-P2-000005 FLINK-P2-000006 FLINK-P2-000010 FART-P2-000004 FART-P2-000005 FART-P2-000006 FART-P2-000010 FLOC-P2-000005 FLOC-P2-000006 FLOC-P2-000007 FLOC-P2-000011; do
  grep -Fq "$id" "$WORK/cand4.jsonl"
done

lake exe traceability query curriculum CAND-P1-000009 | tee "$WORK/cand9.jsonl"
for id in FLINK-P2-000007 FLINK-P2-000008 FLINK-P2-000009 FART-P2-000007 FART-P2-000008 FART-P2-000009 FLOC-P2-000008 FLOC-P2-000009 FLOC-P2-000010; do
  grep -Fq "$id" "$WORK/cand9.jsonl"
done

lake exe traceability query curriculum CAND-P1-000018 | tee "$WORK/cand18.jsonl"
for id in FLINK-P2-000017 FLINK-P2-000018 FART-P2-000017 FART-P2-000018 FLOC-P2-000018 FLOC-P2-000019; do
  grep -Fq "$id" "$WORK/cand18.jsonl"
done

lake exe traceability query curriculum CAND-P1-000019 | tee "$WORK/cand19.jsonl"
for id in FLINK-P2-000011 FLINK-P2-000014 FLINK-P2-000019 FART-P2-000011 FART-P2-000014 FART-P2-000018 FLOC-P2-000012 FLOC-P2-000015 FLOC-P2-000019; do
  grep -Fq "$id" "$WORK/cand19.jsonl"
done

lake exe traceability query curriculum CAND-P1-000024 | tee "$WORK/cand24.jsonl"
for id in FLINK-P2-000012 FLINK-P2-000015 FLINK-P2-000020 FART-P2-000012 FART-P2-000015 FART-P2-000019 FLOC-P2-000013 FLOC-P2-000016 FLOC-P2-000020; do
  grep -Fq "$id" "$WORK/cand24.jsonl"
done

lake exe traceability query curriculum CAND-P1-000027 | tee "$WORK/cand27.jsonl"
for id in FLINK-P2-000013 FLINK-P2-000016 FLINK-P2-000021 FLINK-P2-000022 FART-P2-000013 FART-P2-000016 FART-P2-000020 FART-P2-000021 FLOC-P2-000014 FLOC-P2-000017 FLOC-P2-000021 FLOC-P2-000022; do
  grep -Fq "$id" "$WORK/cand27.jsonl"
done

while IFS='|' read -r declaration fart floc; do
  lake exe traceability query declaration "$declaration" | tee "$WORK/source-query.jsonl"
  grep -Fq "$fart" "$WORK/source-query.jsonl"
  grep -Fq "$floc" "$WORK/source-query.jsonl"
done <<'EOF'
FormalMath.Algebra.factoredProduct|FART-P2-000001|FLOC-P2-000001
FormalMath.Algebra.factoredProduct_eq_zero_iff|FART-P2-000002|FLOC-P2-000002
FormalMath.Algebra.Examples.two_five_factored_equation|FART-P2-000003|FLOC-P2-000004
EOF

grep -Fq 'FLOC-P2-000003' "$WORK/source-query.jsonl"

while IFS='|' read -r declaration fart floc; do
  lake exe traceability query declaration "$declaration" | tee "$WORK/p4-source-query.jsonl"
  grep -Fq "$fart" "$WORK/p4-source-query.jsonl"
  grep -Fq "$floc" "$WORK/p4-source-query.jsonl"
done <<'EOF'
Nat.instAddCancelCommMonoid|FART-P2-000004|FLOC-P2-000005
Nat.instCommMonoid|FART-P2-000004|FLOC-P2-000005
Nat.instDistrib|FART-P2-000005|FLOC-P2-000006
FormalMath.Arithmetic.Examples.cancel_common_nine_addend|FART-P2-000006|FLOC-P2-000007
FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three|FART-P2-000006|FLOC-P2-000007
Int.instAddCommGroup|FART-P2-000007|FLOC-P2-000008
Int.instCommRing|FART-P2-000008|FLOC-P2-000009
FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four|FART-P2-000009|FLOC-P2-000010
FormalMath.Arithmetic.Examples.seven_sub_neg_three|FART-P2-000009|FLOC-P2-000010
FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong|FART-P2-000010|FLOC-P2-000011
FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution|FART-P2-000010|FLOC-P2-000011
EOF

while IFS='|' read -r declaration fart floc; do
  lake exe traceability query declaration "$declaration" | tee "$WORK/p6-source-query.jsonl"
  grep -Fq "$fart" "$WORK/p6-source-query.jsonl"
  grep -Fq "$floc" "$WORK/p6-source-query.jsonl"
done <<'EOF'
FormalMath.Relations.graphOf|FART-P2-000011|FLOC-P2-000012
FormalMath.Geometry.IsInvariantUnder|FART-P2-000012|FLOC-P2-000013
FormalMath.Measurement.rectangleArea|FART-P2-000013|FLOC-P2-000014
FormalMath.Measurement.rectanglePerimeter|FART-P2-000013|FLOC-P2-000014
FormalMath.Measurement.rectangularPrismVolume|FART-P2-000013|FLOC-P2-000014
FormalMath.Relations.mem_graphOf_iff|FART-P2-000014|FLOC-P2-000015
FormalMath.Relations.mem_graphOf_comp_iff|FART-P2-000017|FLOC-P2-000018
FormalMath.Relations.Examples.successor_then_double_graph_contains_three_eight|FART-P2-000018|FLOC-P2-000019
FormalMath.Geometry.Examples.bool_univ_invariant_under_id|FART-P2-000019|FLOC-P2-000020
FormalMath.Measurement.Examples.rectangle_three_four_perimeter_ne_area|FART-P2-000020|FLOC-P2-000021
FormalMath.Measurement.Examples.rectangle_three_four_values|FART-P2-000020|FLOC-P2-000021
FormalMath.Measurement.Exercises.rectangularPrism_two_three_four_solution|FART-P2-000021|FLOC-P2-000022
FormalMath.Geometry.isInvariantUnder_id|FART-P2-000015|FLOC-P2-000016
FormalMath.Measurement.rectangleArea_comm|FART-P2-000016|FLOC-P2-000017
FormalMath.Measurement.rectanglePerimeter_comm|FART-P2-000016|FLOC-P2-000017
FormalMath.Measurement.rectangularPrismVolume_swap_length_width|FART-P2-000016|FLOC-P2-000017
EOF


lake exe traceability query curriculum CAND-P1-000090 | tee "$WORK/cand90.jsonl"
for id in FLINK-P2-000023 FART-P2-000022 FLOC-P2-000023; do
  grep -Fq "$id" "$WORK/cand90.jsonl"
done

lake exe traceability query declaration FormalMath.Algorithms.IsCorrectFor | tee "$WORK/p7-source-query.jsonl"
grep -Fq 'FART-P2-000022' "$WORK/p7-source-query.jsonl"
grep -Fq 'FLOC-P2-000023' "$WORK/p7-source-query.jsonl"

printf 'm210-roundtrip:start:derived-rebuild\n'
rm -rf "$generated"
second_output="$(lake exe traceability generate)"
printf '%s\n' "$second_output"
second_fingerprint="$(sed -n 's/.*:fingerprint=//p' <<<"$second_output" | tail -n 1)"
[[ "$first_fingerprint" == "$second_fingerprint" ]]
lake exe traceability freshness
git diff --exit-code -- metadata
printf 'm210-roundtrip:pass:derived-rebuild:fingerprint=%s\n' "$second_fingerprint"

printf 'm210-roundtrip:start:stale-old-current-locator-control\n'
old_current="$WORK/old-current"
copy_production_root "$old_current"
python3 - "$old_current" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
fart_path = root / "metadata/formal-artifacts/fart/000001-001000.jsonl"
farts = [json.loads(line) for line in fart_path.read_text().splitlines() if line]
for record in farts:
    if record["id"] == "FART-P2-000003":
        record["current_locator_refs"] = ["FLOC-P2-000003"]
fart_path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in farts))

floc_path = root / "metadata/formal-artifacts/floc/000001-001000.jsonl"
flocs = [json.loads(line) for line in floc_path.read_text().splitlines() if line]
flocs = [record for record in flocs if record["id"] != "FLOC-P2-000004"]
for record in flocs:
    if record["id"] == "FLOC-P2-000003":
        record["locator_status"] = "current"
        record["record_status"] = "active"
        record["superseded_by_locator_refs"] = []
floc_path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in flocs))

registry_path = root / "metadata/formal-artifacts/registry.json"
registry = json.loads(registry_path.read_text())
registry["record_counts"]["floc"] = 10
registry_path.write_text(json.dumps(registry, sort_keys=True, separators=(",", ":")) + "\n")
PY
expect_failure stale-old-current-locator 'traceability:error:floc:missing-current-project-file:FLOC-P2-000003:FormalMath/Algebra/Examples/FactoredEquation.lean' \
  lake exe traceability validate --root "$old_current"

printf 'm210-roundtrip:start:current-backreference-control\n'
bad_backref="$WORK/bad-backref"
copy_production_root "$bad_backref"
python3 - "$bad_backref/metadata/formal-artifacts/fart/000001-001000.jsonl" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
records = [json.loads(line) for line in path.read_text().splitlines() if line]
for record in records:
    if record["id"] == "FART-P2-000003":
        record["current_locator_refs"] = ["FLOC-P2-000003"]
path.write_text("".join(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n" for record in records))
PY
expect_failure current-backreference 'traceability:error:registry:noncurrent-locator-in-current-set:FART-P2-000003:FLOC-P2-000003' \
  lake exe traceability validate --root "$bad_backref"

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
        record["module_name"] = "FormalMath.Algebra.Examples.FactoredIntegerEquation"
        record["file_path"] = "FormalMath/Algebra/Examples/FactoredIntegerEquation.lean"
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
assert "leanprover-community/mathlib4" in payload
assert "FLOC-P2-000005" in payload and "FLOC-P2-000006" in payload
assert "FLOC-P2-000008" in payload and "FLOC-P2-000009" in payload
assert "READY" not in payload and "REQEXPR" not in payload
PY
printf 'm210-roundtrip:pass:external-dependency-not-project-or-curriculum-authority\n'
lake env lean -DwarningAsError=true QualityTests/M210RootApi.lean
printf 'm210-roundtrip:pass:formal-math-root-api\n'
lake env lean -DwarningAsError=true QualityTests/P4NaturalNumberLawsRootApi.lean
printf 'm210-roundtrip:pass:p4-natural-number-laws-root-api\n'
lake env lean -DwarningAsError=true QualityTests/P4NaturalNumberExerciseRootApi.lean
printf 'm210-roundtrip:pass:p4-natural-number-exercise-root-api\n'
lake env lean -DwarningAsError=true QualityTests/P4IntegerSignLawsRootApi.lean
printf 'm210-roundtrip:pass:p4-integer-sign-laws-root-api\n'
printf 'm210-roundtrip:summary:pass\n'
