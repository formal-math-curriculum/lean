#!/usr/bin/env python3
"""Fail-closed policy for the exact frozen Project-7 M7.4 result wave."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path


ROOT = Path(os.environ.get("P7_M74_ROOT", "."))
EXACT_FILE = Path(os.environ.get("P7_M74_EXACT_FILE", ROOT / "FormalMath/Algebra/ExactResults.lean"))
CHOOSE_FILE = Path(os.environ.get("P7_M74_CHOOSE_FILE", ROOT / "FormalMath/Algorithms/NatChoose.lean"))
ROOT_FILE = ROOT / "FormalMath.lean"


def fail(code: str, detail: str = "") -> None:
    suffix = f":{detail}" if detail else ""
    print(f"p7-m74:error:{code}{suffix}", file=sys.stderr)
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.is_file():
        fail("missing-file", str(path))
    return path.read_text(encoding="utf-8")


exact = read(EXACT_FILE)
choose = read(CHOOSE_FILE)
root = read(ROOT_FILE)

public_pattern = re.compile(r"(?m)^\s*(?:@\[[^\]]*\]\s*)*public\s+theorem\s+([A-Za-z0-9_]+)\b")
if public_pattern.findall(exact) != ["identity_exact_zero"]:
    fail("unplanned-public-surface", "exact-results")
if public_pattern.findall(choose) != ["natChoose_isCorrectFor"]:
    fail("unplanned-public-surface", "nat-choose")

for label, source in (("exact-results", exact), ("nat-choose", choose)):
    if re.search(r"(?m)^\s*(?:@\[[^\]]*\]\s*)*public\s+(?:def|opaque|instance|abbrev|structure|class)\b", source):
        fail("forbidden-public-kind", label)
    if re.search(r"(?m)^\s*(?:local\s+)?(?:instance|notation\d*)\b", source):
        fail("forbidden-instance-or-notation", label)

exact_required = [
    "public import Mathlib.Algebra.Exact.Basic",
    "public theorem identity_exact_zero {M P : Type*} [Zero P] :",
    "Function.Exact (fun x : M => x) (fun _ : M => (0 : P))",
]
choose_required = [
    "public import FormalMath.Algorithms.Correctness",
    "public import Mathlib.Data.Nat.Choose.Basic",
    "public theorem natChoose_isCorrectFor :",
    "(fun input : Nat × Nat => Nat.choose input.1 input.2)",
    "| (_n, 0) => output = 1",
    "| (0, _k + 1) => output = 0",
    "| (n + 1, k + 1) => output = Nat.choose n k + Nat.choose n (k + 1)",
]
if any(fragment not in exact for fragment in exact_required):
    fail("signature-drift", "identity-exact-zero")
if any(fragment not in choose for fragment in choose_required):
    fail("signature-drift", "nat-choose")

if os.environ.get("P7_M74_MISSING_EXPORT_FIXTURE") != "1":
    for module in ("FormalMath.Algebra.ExactResults", "FormalMath.Algorithms.NatChoose"):
        if f"public import {module}" not in root:
            fail("missing-root-export", module)
else:
    fail("missing-root-export", "fixture")

manifest = json.loads(read(ROOT / "lake-manifest.json"))
mathlib = [package["rev"] for package in manifest["packages"] if package["name"] == "mathlib"]
expected_mathlib = os.environ.get("P7_M74_EXPECTED_MATHLIB_REV", "db584cd6d46c92f209a44c0f1c829460d327499d")
if mathlib != [expected_mathlib]:
    fail("mathlib-revision-mismatch")

fart_path = ROOT / "metadata/formal-artifacts/fart/000001-001000.jsonl"
floc_path = ROOT / "metadata/formal-artifacts/floc/000001-001000.jsonl"
flink_path = ROOT / "metadata/formal-artifacts/flink/000001-001000.jsonl"
registry_path = ROOT / "metadata/formal-artifacts/registry.json"
lock_path = ROOT / "metadata/curriculum-lock/linked-identities.jsonl"
lock_manifest_path = ROOT / "metadata/curriculum-lock/manifest.json"


def jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in read(path).splitlines() if line]


fart = jsonl(fart_path)
floc = jsonl(floc_path)
flink = jsonl(flink_path)
registry = json.loads(read(registry_path))
locks = jsonl(lock_path)
lock_manifest = json.loads(read(lock_manifest_path))

expected_fart = [f"FART-P2-{n:06d}" for n in range(23, 29)]
expected_floc = [f"FLOC-P2-{n:06d}" for n in range(24, 30)]
expected_flink = [f"FLINK-P2-{n:06d}" for n in range(24, 37)]
if [row["id"] for row in fart[-6:]] != expected_fart or len(fart) != 28:
    fail("fart-selector")
if [row["id"] for row in floc[-6:]] != expected_floc or len(floc) != 29:
    fail("floc-selector")
if [row["id"] for row in flink[-13:]] != expected_flink or len(flink) != 36:
    fail("flink-selector")

expected_declarations = [
    ["Semigroup.mul_assoc"],
    ["FormalMath.Algebra.identity_exact_zero"],
    ["FiniteField.card"],
    ["SimpleGraph.IsTree.connected"],
    ["FormalMath.Algorithms.natChoose_isCorrectFor"],
    ["AkraBazziRecurrence.isTheta_asympBound"],
]
if [row["declaration_names"] for row in floc[-6:]] != expected_declarations:
    fail("floc-declaration-drift")
if [row["candidate_ref_current_resolved"] for row in flink[-13:]] != [
    "CAND-P1-000049", "CAND-P1-000050", "CAND-P1-000060", "CAND-P1-000590", "CAND-P1-000591",
    "CAND-P1-000592", "CAND-P1-000078", "CAND-P1-000594", "CAND-P1-000084", "CAND-P1-000602",
    "CAND-P1-000079", "CAND-P1-000090", "CAND-P1-000520",
]:
    fail("flink-row-drift")
if registry["record_counts"] != {"fart": 28, "flink": 36, "floc": 29}:
    fail("registry-counts")
if registry["next_ids"] != {"fart": "FART-P2-000029", "flink": "FLINK-P2-000037", "floc": "FLOC-P2-000030"}:
    fail("registry-cursors")
if len(locks) != 21 or len({row["candidate_ref_current_resolved"] for row in locks}) != 21:
    fail("curriculum-lock-identities")
if lock_manifest.get("identity_count") != 21:
    fail("curriculum-lock-manifest")

print("p7-m74:pass:local-theorems=2;direct-dependency-theorems=4;selected-identities=13;admitted-identities=42;deferments=56;fart=28;floc=29;flink=36;curriculum-lock-identities=21")
