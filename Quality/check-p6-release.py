#!/usr/bin/env python3
"""Fail-closed validation for the bounded Project-6 release manifest."""

from __future__ import annotations

import json
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "RELEASES/P6-FORMALIZATION-RELEASE-v1.md"

EXPECTED_REPRESENTED = {
    "CAND-P1-000004",
    "CAND-P1-000009",
    "CAND-P1-000016",
    "CAND-P1-000017",
    "CAND-P1-000018",
    "CAND-P1-000019",
    "CAND-P1-000024",
    "CAND-P1-000027",
}

EXPECTED_ABSENT = {
    "CAND-P1-000001",
    "CAND-P1-000002",
    "CAND-P1-000003",
    "CAND-P1-000005",
    "CAND-P1-000006",
    "CAND-P1-000007",
    "CAND-P1-000008",
    "CAND-P1-000010",
    "CAND-P1-000011",
    "CAND-P1-000012",
    "CAND-P1-000013",
    "CAND-P1-000014",
    "CAND-P1-000015",
    "CAND-P1-000020",
    "CAND-P1-000021",
    "CAND-P1-000022",
    "CAND-P1-000023",
    "CAND-P1-000025",
    "CAND-P1-000026",
    "CAND-P1-000028",
    "CAND-P1-000029",
    "CAND-P1-000030",
    "CAND-P1-000031",
    "CAND-P1-000032",
    "CAND-P1-000033",
    "CAND-P1-000034",
    "CAND-P1-000035",
    "CAND-P1-000036",
    "CAND-P1-000037",
    "CAND-P1-000038",
    "CAND-P1-000039",
    "CAND-P1-000040",
    "CAND-P1-000041",
    "CAND-P1-000042",
    "CAND-P1-000043",
    "CAND-P1-000044",
    "CAND-P1-000045",
    "CAND-P1-000046",
    "CAND-P1-000521",
    "CAND-P1-000522",
    "CAND-P1-000529",
    "CAND-P1-000530",
    "CAND-P1-000531",
    "CAND-P1-000532",
}

EXPECTED_DECLARATIONS = {
    "FormalMath.Algebra.factoredProduct",
    "FormalMath.Algebra.factoredProduct_eq_zero_iff",
    "FormalMath.Geometry.IsInvariantUnder",
    "FormalMath.Geometry.isInvariantUnder_id",
    "FormalMath.Measurement.rectangleArea",
    "FormalMath.Measurement.rectangleArea_comm",
    "FormalMath.Measurement.rectanglePerimeter",
    "FormalMath.Measurement.rectanglePerimeter_comm",
    "FormalMath.Measurement.rectangularPrismVolume",
    "FormalMath.Measurement.rectangularPrismVolume_swap_length_width",
    "FormalMath.Relations.graphOf",
    "FormalMath.Relations.mem_graphOf_comp_iff",
    "FormalMath.Relations.mem_graphOf_iff",
    "FormalMath.Algebra.Examples.two_five_factored_equation",
    "FormalMath.Arithmetic.Examples.cancel_common_nine_addend",
    "FormalMath.Arithmetic.Examples.neg_seven_mul_neg_four",
    "FormalMath.Arithmetic.Examples.seven_distributes_over_four_plus_three",
    "FormalMath.Arithmetic.Examples.seven_sub_neg_three",
    "FormalMath.Arithmetic.Exercises.distribute_first_addend_only_is_wrong",
    "FormalMath.Arithmetic.Exercises.distribute_then_cancel_solution",
    "FormalMath.Geometry.Examples.bool_univ_invariant_under_id",
    "FormalMath.Measurement.Examples.rectangle_three_four_perimeter_ne_area",
    "FormalMath.Measurement.Examples.rectangle_three_four_values",
    "FormalMath.Measurement.Exercises.rectangularPrism_two_three_four_solution",
    "FormalMath.Relations.Examples.successor_then_double_graph_contains_three_eight",
}

EXPECTED_REUSE = {
    "Nat.instAddCancelCommMonoid",
    "Nat.instCommMonoid",
    "Nat.instDistrib",
    "Int.instAddCommGroup",
    "Int.instCommRing",
}

EXPECTED_PACKET_PATHS = {
    "publication/p6-v1/generate.py",
    "publication/p6-v1/source/scope.json",
    "publication/p6-v1/generated/release-scope.json",
    "publication/p6-v1/generated/formal-authority.json",
    "publication/p6-v1/generated/formal-dependencies.json",
    "publication/p6-v1/generated/representation-bindings.json",
    "publication/p6-v1/generated/external-alignment-coverage.json",
}

FORBIDDEN_FIELD = re.compile(
    r"(?:^|[^A-Za-z0-9])(?:TBD|TODO|PLACEHOLDER|PENDING|PROVISIONAL)"
    r"(?:$|[^A-Za-z0-9])|0{40}|f{40}",
    re.IGNORECASE,
)


def fail(code: str, detail: str = "") -> None:
    suffix = f":{detail}" if detail else ""
    raise AssertionError(f"p6-release:error:{code}{suffix}")


def require(text: str, token: str, code: str) -> None:
    if token not in text:
        fail(code)


def load_json(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def load_jsonl(relative: str) -> list[dict]:
    return [
        json.loads(line)
        for line in (ROOT / relative).read_text(encoding="utf-8").splitlines()
        if line
    ]

def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode()
    return hashlib.sha1(header + data).hexdigest()


def validate_repository() -> None:
    release_scope = load_json("publication/p6-v1/generated/release-scope.json")
    authority = load_json("publication/p6-v1/generated/formal-authority.json")
    dependencies = load_json("publication/p6-v1/generated/formal-dependencies.json")
    bindings = load_json("publication/p6-v1/generated/representation-bindings.json")
    external = load_json("publication/p6-v1/generated/external-alignment-coverage.json")
    publication = load_json("publication/p6-v1/generated/publication-manifest.json")
    floc = load_jsonl("metadata/formal-artifacts/floc/000001-001000.jsonl")

    rows = release_scope["records"]
    if release_scope["record_count"] != 52 or len(rows) != 52:
        fail("scope-count")
    ids = [row["candidate_ref"] for row in rows]
    if len(set(ids)) != 52:
        fail("scope-identity")
    represented = {
        row["candidate_ref"]
        for row in rows
        if row["formal_representation_state"] == "represented"
    }
    absent = {
        row["candidate_ref"]
        for row in rows
        if row["formal_representation_state"] == "not_represented"
    }
    if represented != EXPECTED_REPRESENTED or len(absent) != 44:
        fail("representation-partition")

    counts = publication["counts"]
    expected_counts = {
        "release_scope": 52,
        "fart": 21,
        "floc_total": 22,
        "floc_active_current": 21,
        "floc_historical": 1,
        "flink": 22,
        "linked_identities": 8,
        "representation_bindings": 22,
        "formal_dependency_module_sources": 17,
        "formal_dependency_import_edges": 19,
        "formal_dependency_external_locators": 4,
        "external_alignment_coverage": 156,
    }
    if any(counts.get(key) != value for key, value in expected_counts.items()):
        fail("publication-counts")
    if publication["semantic_fingerprint"] != (
        "cc71d82820de2fe29f30364067996dececb6cae2458e67d83f73cc74548116ab"
    ):
        fail("semantic-fingerprint")
    projections = [row["projection"] for row in publication["projection_compatibility"]]
    if projections != ["Course", "OntoMathPRO", "MSC2020", "arXiv", "Lean/mathlib"]:
        fail("projection-vector")

    if len(authority["formal_artifacts"]) != 21:
        fail("fart-count")
    if len(authority["formal_locators"]) != 22:
        fail("floc-count")
    if len(authority["formal_links"]) != 22:
        fail("flink-count")
    if len(authority["linked_identities"]) != 8:
        fail("lock-count")
    if len(bindings["records"]) != 22:
        fail("binding-count")
    if len(dependencies["module_sources"]) != 17:
        fail("module-count")
    if len(dependencies["import_edges"]) != 19:
        fail("import-count")
    if len(dependencies["external_dependency_locators"]) != 4:
        fail("dependency-locator-count")

    external_rows = external["records"]
    if len(external_rows) != 156:
        fail("external-count")
    if any(row["mapping_state"] != "needs_review" for row in external_rows):
        fail("external-state")
    if any(row["external_id"] is not None for row in external_rows):
        fail("invented-external-id")
    if {row["system"] for row in external_rows} != {"OntoMathPRO", "MSC2020", "arXiv"}:
        fail("external-systems")

    current_project = [
        row
        for row in floc
        if row["locator_status"] == "current"
        and row["source_kind"] == "project_repository"
    ]
    declarations = {
        name for row in current_project for name in row["declaration_names"]
    }
    if declarations != EXPECTED_DECLARATIONS:
        fail("declaration-set")
    reuse = {
        name
        for row in floc
        if row["locator_status"] == "current"
        and row["source_kind"] == "dependency_repository"
        for name in row["declaration_names"]
    }
    if reuse != EXPECTED_REUSE:
        fail("reuse-set")


def validate_manifest(text: str) -> None:
    if FORBIDDEN_FIELD.search(text):
        fail("unresolved-field")

    required = {
        "release-id": "Release identity: `P6-FORMALIZATION-RELEASE-v1`",
        "manifest-path": "Repository manifest: `RELEASES/P6-FORMALIZATION-RELEASE-v1.md`",
        "integration-pr-exact": "Integration PR: [#35](https://github.com/formal-math-curriculum/lean/pull/35)",
        "tag": "Annotated tag: [`formalization/p6-v1`]",
        "base": "Frozen release base: `8228da5c2abfe6bf6eac6aebe4f3cada8ed30b94`",
        "m69-adopted": "9c4339f9-26eb-4868-a659-9945e54b4158@2026-08-25T19:39:25.754Z",
        "m69-current": "35e43976-3d21-4a7a-943c-b7145a2a9b37@2026-08-25T19:37:55.686Z",
        "freeze": "6734f496-d31e-4cac-9d68-aaa0e644dd07@2026-08-25T19:44:50.424Z",
        "scope": "Exact scope rows: 52",
        "partition": "Explicit not represented (44)",
        "counts": "FLOC: 22 total = 21 current + 1 historical",
        "external": "external alignment coverage: 156; all needs_review; all external IDs null",
        "maturity": "maturity: `reviewed_active`, revision-scoped",
        "verification": "verification: four-component verification vector",
        "formal-subject": "formal packet subject: `5b592af5807467d600184d376f1a1d5920ddddbd`",
        "fingerprint": "cc71d82820de2fe29f30364067996dececb6cae2458e67d83f73cc74548116ab",
        "generator": "318b48b3e02bf2a37e320879a58e58ffde5a9269f7f86e6dddb97d6c7131c6f9",
        "peeled": "The released Git subject is the commit peeled from the annotated tag",
        "linear-record": "durable Linear release record",
        "github-release": "A GitHub Release object is not required",
        "handoff": "## Project 5 handoff",
        "nonclaim": "It does not claim that the whole",
        "release-check": "python3 Quality/check-p6-release.py",
        "publication-check": "python3 Quality/check-p6-publication.py",
        "traceability": "lake exe traceability roundtrip",
        "integration": "bash Quality/check-p6-integration-controls.sh",
    }
    for code, token in required.items():
        require(text, token, code)

    if not re.search(r"Integration PR: \[#\d+\]\(https://github\.com/.+/pull/\d+\)", text):
        fail("integration-pr")
    manifest_candidates = re.findall(r"CAND-P1-\d{6}", text)
    if (
        len(manifest_candidates) != 52
        or set(manifest_candidates) != EXPECTED_REPRESENTED | EXPECTED_ABSENT
    ):
        fail("candidate-vector")
    publication = load_json("publication/p6-v1/generated/publication-manifest.json")
    packet_entries = {
        row["path"]: row
        for row in publication["inputs"] + publication["outputs"]
        if row["path"] in EXPECTED_PACKET_PATHS
    }
    if set(packet_entries) != EXPECTED_PACKET_PATHS:
        fail("packet-source-vector")
    for path in sorted(EXPECTED_PACKET_PATHS):
        row = packet_entries[path]
        require(
            text,
            f"| `{path}` | `{row['git_blob']}` | `{row['sha256']}` |",
            "packet-row",
        )
    publication_manifest_bytes = (
        ROOT / "publication/p6-v1/generated/publication-manifest.json"
    ).read_bytes()
    require(
        text,
        "| `publication/p6-v1/generated/publication-manifest.json`"
        f" | `{git_blob_sha(publication_manifest_bytes)}`"
        f" | `{hashlib.sha256(publication_manifest_bytes).hexdigest()}` |",
        "packet-row",
    )
    for candidate in EXPECTED_REPRESENTED:
        require(text, candidate, "represented-identity")
    for declaration in EXPECTED_DECLARATIONS:
        require(text, declaration, "required-declaration")
    for declaration in EXPECTED_REUSE:
        require(text, declaration, "required-reuse")


def expect_failure(label: str, expected: str, text: str) -> None:
    try:
        validate_manifest(text)
    except AssertionError as exc:
        if expected not in str(exc):
            raise AssertionError(
                f"p6-release-control:wrong-failure:{label}:{exc}"
            ) from exc
        print(f"p6-release-control:expected-fail:{label}:{expected}")
        return
    raise AssertionError(f"p6-release-control:unexpected-pass:{label}")


def main() -> int:
    text = MANIFEST.read_text(encoding="utf-8")
    validate_repository()
    validate_manifest(text)
    print("p6-release:pass:repository-and-manifest")

    expect_failure(
        "release-id",
        "p6-release:error:release-id",
        text.replace("Release identity: `P6-FORMALIZATION-RELEASE-v1`", "Release identity: `bad`", 1),
    )
    expect_failure(
        "tag",
        "p6-release:error:tag",
        text.replace("Annotated tag: [`formalization/p6-v1`]", "Annotated tag: [`v1.0.0`]", 1),
    )
    expect_failure(
        "base",
        "p6-release:error:base",
        text.replace("8228da5c2abfe6bf6eac6aebe4f3cada8ed30b94", "1" * 40, 1),
    )
    expect_failure(
        "scope-count",
        "p6-release:error:scope",
        text.replace("Exact scope rows: 52", "Exact scope rows: 51", 1),
    )
    expect_failure(
        "represented-identity",
        "p6-release:error:candidate-vector",
        text.replace("CAND-P1-000004", "CAND-P1-999999"),
    )
    expect_failure(
        "absent-identity",
        "p6-release:error:candidate-vector",
        text.replace("CAND-P1-000001", "CAND-P1-999998"),
    )
    expect_failure(
        "integration-pr",
        "p6-release:error:integration-pr-exact",
        text.replace(
            "Integration PR: [#35](https://github.com/formal-math-curriculum/lean/pull/35)",
            "Integration PR: [#36](https://github.com/formal-math-curriculum/lean/pull/36)",
            1,
        ),
    )
    expect_failure(
        "formal-subject",
        "p6-release:error:formal-subject",
        text.replace(
            "formal packet subject: `5b592af5807467d600184d376f1a1d5920ddddbd`",
            "formal packet subject: `1111111111111111111111111111111111111111`",
            1,
        ),
    )
    expect_failure(
        "packet-blob",
        "p6-release:error:packet-row",
        text.replace(
            "0ec3ecb795599569f9557226ff5ef6bb3c8a10a5",
            "1111111111111111111111111111111111111111",
            1,
        ),
    )
    expect_failure(
        "packet-checksum",
        "p6-release:error:packet-row",
        text.replace(
            "55671c424178740b946fb5815289008487d020cbeeb7808656c2a5faf4349d6a",
            "1" * 64,
            1,
        ),
    )
    expect_failure(
        "semantic-fingerprint",
        "p6-release:error:fingerprint",
        text.replace(
            "cc71d82820de2fe29f30364067996dececb6cae2458e67d83f73cc74548116ab",
            "1" * 64,
        ),
    )
    expect_failure(
        "unresolved-field",
        "p6-release:error:unresolved-field",
        text + "\nTBD\n",
    )
    expect_failure(
        "external-overclaim",
        "p6-release:error:external",
        text.replace(
            "external alignment coverage: 156; all needs_review; all external IDs null",
            "external alignment coverage: 156; adopted mappings",
            1,
        ),
    )
    expect_failure(
        "maturity-overclaim",
        "p6-release:error:maturity",
        text.replace("maturity: `reviewed_active`, revision-scoped", "maturity: `production_complete`", 1),
    )
    expect_failure(
        "verification-overclaim",
        "p6-release:error:verification",
        text.replace("verification: four-component verification vector", "verification: verified forever", 1),
    )
    expect_failure(
        "nonclaim",
        "p6-release:error:nonclaim",
        text.replace("It does not claim that the whole", "It claims that the whole", 1),
    )
    print(
        "p6-release-control:summary:pass:"
        "scope=52:represented=8:absent=44:fart=21:floc=22:flink=22:"
        "bindings=22:external=156"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"p6-release:fail:{exc}")
        raise
