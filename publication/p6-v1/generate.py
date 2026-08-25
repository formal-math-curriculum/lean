#!/usr/bin/env python3
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
"""Generate the deterministic Project-6 / Project-5-v2 publication handoff."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

SUBJECT_REVISION = "5b592af5807467d600184d376f1a1d5920ddddbd"
MATHLIB_REVISION = "db584cd6d46c92f209a44c0f1c829460d327499d"
LEAN_TOOLCHAIN = "leanprover/lean4:v4.33.0"
SCOPE_REL = "publication/p6-v1/source/scope.json"
GENERATOR_REL = "publication/p6-v1/generate.py"
FART_REL = "metadata/formal-artifacts/fart/000001-001000.jsonl"
FLOC_REL = "metadata/formal-artifacts/floc/000001-001000.jsonl"
FLINK_REL = "metadata/formal-artifacts/flink/000001-001000.jsonl"
LINKED_REL = "metadata/curriculum-lock/linked-identities.jsonl"
OUTPUT_DIR = "publication/p6-v1/generated"
OUTPUT_RELS = (
    f"{OUTPUT_DIR}/external-alignment-coverage.json",
    f"{OUTPUT_DIR}/formal-authority.json",
    f"{OUTPUT_DIR}/formal-dependencies.json",
    f"{OUTPUT_DIR}/release-scope.json",
    f"{OUTPUT_DIR}/representation-bindings.json",
)
MANIFEST_REL = f"{OUTPUT_DIR}/publication-manifest.json"
EXTERNAL_SYSTEMS = ("arXiv", "MSC2020", "OntoMathPRO")
PROJECTIONS = ("Course", "OntoMathPRO", "MSC2020", "arXiv", "Lean/mathlib")
FORBIDDEN_HIERARCHY_KEYS = {
    "course_cluster",
    "course_order",
    "depth_successors",
    "learner_prerequisite",
    "learner_prerequisites",
    "parent",
    "parent_id",
    "parents",
    "prerequisite",
    "prerequisites",
}


class PublicationError(RuntimeError):
    """A stable, machine-readable publication-contract failure."""


def fail(code: str, detail: str) -> None:
    raise PublicationError(f"p6-publication:error:{code}:{detail}")


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def compact_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def read_bytes(root: Path, rel: str) -> bytes:
    path = root / rel
    if not path.is_file():
        fail("missing-input", rel)
    return path.read_bytes()


def read_json(root: Path, rel: str) -> Any:
    try:
        return json.loads(read_bytes(root, rel).decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        fail("invalid-json", f"{rel}:{exc}")


def read_jsonl(root: Path, rel: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(read_bytes(root, rel).decode("utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            value = json.loads(raw)
        except json.JSONDecodeError as exc:
            fail("invalid-jsonl", f"{rel}:{line_number}:{exc}")
        if not isinstance(value, dict):
            fail("invalid-jsonl-row", f"{rel}:{line_number}")
        rows.append(value)
    return rows


def require_unique(rows: list[dict[str, Any]], key: str, label: str) -> None:
    values = [row.get(key) for row in rows]
    if any(value is None for value in values):
        fail("missing-key", f"{label}:{key}")
    if len(values) != len(set(values)):
        fail("duplicate-key", f"{label}:{key}")


def find_forbidden_key(value: Any, prefix: str = "$") -> str | None:
    if isinstance(value, dict):
        for key, nested in value.items():
            lower = key.lower()
            if lower in FORBIDDEN_HIERARCHY_KEYS or lower.startswith("course_"):
                return f"{prefix}.{key}"
            hit = find_forbidden_key(nested, f"{prefix}.{key}")
            if hit:
                return hit
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            hit = find_forbidden_key(nested, f"{prefix}[{index}]")
            if hit:
                return hit
    return None


def contains_fixture_marker(value: Any) -> bool:
    if isinstance(value, dict):
        return any("fixture" in str(key).lower() or contains_fixture_marker(nested)
                   for key, nested in value.items())
    if isinstance(value, list):
        return any(contains_fixture_marker(item) for item in value)
    return isinstance(value, str) and "fixture" in value.lower()


def load_scope(root: Path) -> dict[str, Any]:
    scope = read_json(root, SCOPE_REL)
    if not isinstance(scope, dict):
        fail("invalid-scope", "root-not-object")
    validate_scope(scope)
    return scope


def validate_scope(scope: dict[str, Any]) -> None:
    if scope.get("schema_version") != "p6-m67-source/v1":
        fail("scope-schema", str(scope.get("schema_version")))
    if scope.get("formal_subject_revision") != SUBJECT_REVISION:
        fail("stale-subject", str(scope.get("formal_subject_revision")))
    if scope.get("lean_toolchain") != LEAN_TOOLCHAIN:
        fail("stale-toolchain", str(scope.get("lean_toolchain")))
    if scope.get("mathlib_revision") != MATHLIB_REVISION:
        fail("stale-mathlib", str(scope.get("mathlib_revision")))
    if tuple(scope.get("external_systems", ())) != EXTERNAL_SYSTEMS:
        fail("external-systems", repr(scope.get("external_systems")))
    hit = find_forbidden_key(scope)
    if hit:
        fail("hierarchy-leakage", hit)
    rows = scope.get("scope_rows")
    if not isinstance(rows, list):
        fail("scope-rows", "not-array")
    if len(rows) != 52:
        fail("scope-row-count", str(len(rows)))
    require_unique(rows, "candidate_ref", "scope")
    expected_numbers = list(range(1, 47)) + [521, 522, 529, 530, 531, 532]
    expected = [f"CAND-P1-{number:06d}" for number in expected_numbers]
    actual = [row.get("candidate_ref") for row in rows]
    if actual != expected:
        fail("scope-row-universe", f"expected-ordered-52:actual={actual}")
    for row in rows:
        if set(row) != {"candidate_ref", "primary_disposition"}:
            fail("scope-row-shape", row["candidate_ref"])
        if not isinstance(row["primary_disposition"], str) or not row["primary_disposition"]:
            fail("scope-disposition", row["candidate_ref"])
    frozen = scope.get("frozen_inputs")
    if not isinstance(frozen, list) or not frozen:
        fail("frozen-inputs", "empty")
    require_unique(frozen, "path", "frozen-inputs")
    if [row["path"] for row in frozen] != sorted(row["path"] for row in frozen):
        fail("frozen-input-order", "not-sorted")
    for entry in frozen:
        if set(entry) != {"git_blob", "path"}:
            fail("frozen-input-shape", str(entry.get("path")))
        if not re.fullmatch(r"[0-9a-f]{40}", str(entry["git_blob"])):
            fail("frozen-input-blob", str(entry["path"]))


def validate_input_blobs(root: Path, scope: dict[str, Any]) -> None:
    for entry in scope["frozen_inputs"]:
        actual = git_blob_sha(read_bytes(root, entry["path"]))
        if actual != entry["git_blob"]:
            fail("stale-input-blob", f"{entry['path']}:expected={entry['git_blob']}:actual={actual}")
    toolchain = read_bytes(root, "lean-toolchain").decode("utf-8").strip()
    if toolchain != LEAN_TOOLCHAIN:
        fail("stale-toolchain-file", toolchain)
    manifest = read_json(root, "lake-manifest.json")
    packages = manifest.get("packages", []) if isinstance(manifest, dict) else []
    mathlib = next((row for row in packages if row.get("name") == "mathlib"), None)
    if not mathlib or mathlib.get("rev") != MATHLIB_REVISION:
        fail("stale-mathlib-manifest", repr(mathlib))


def load_authorities(root: Path) -> dict[str, list[dict[str, Any]]]:
    return {
        "fart": read_jsonl(root, FART_REL),
        "floc": read_jsonl(root, FLOC_REL),
        "flink": read_jsonl(root, FLINK_REL),
        "linked": read_jsonl(root, LINKED_REL),
    }


def validate_authorities(scope: dict[str, Any], authority: dict[str, list[dict[str, Any]]]) -> None:
    fart = authority["fart"]
    floc = authority["floc"]
    flink = authority["flink"]
    linked = authority["linked"]
    for label, rows in authority.items():
        require_unique(rows, "id" if label != "linked" else "candidate_ref_current_resolved", label)
    if len(fart) != 21:
        fail("fart-count", str(len(fart)))
    if len(floc) != 22:
        fail("floc-count", str(len(floc)))
    if len(flink) != 22:
        fail("flink-count", str(len(flink)))
    if len(linked) != 8:
        fail("linked-identity-count", str(len(linked)))
    if sum(row.get("record_status") == "active" for row in fart) != 21:
        fail("fart-status-count", "expected-21-active")
    if sum(row.get("record_status") == "active" for row in floc) != 21:
        fail("floc-active-count", "expected-21")
    if sum(row.get("record_status") == "historical" for row in floc) != 1:
        fail("floc-historical-count", "expected-1")
    historical = [row for row in floc if row.get("record_status") == "historical"]
    if [row.get("id") for row in historical] != ["FLOC-P2-000003"]:
        fail("floc-history", repr([row.get("id") for row in historical]))
    if sum(row.get("record_status") == "active" and row.get("link_status") == "current"
           for row in flink) != 22:
        fail("flink-status-count", "expected-22-active-current")

    scope_ids = {row["candidate_ref"] for row in scope["scope_rows"]}
    fart_by_id = {row["id"]: row for row in fart}
    floc_by_id = {row["id"]: row for row in floc}
    linked_by_candidate = {row["candidate_ref_current_resolved"]: row for row in linked}

    current_locator_ids: set[str] = set()
    for artifact in fart:
        refs = artifact.get("current_locator_refs")
        if not isinstance(refs, list) or len(refs) != 1:
            fail("current-locator-cardinality", artifact["id"])
        locator_ref = refs[0]
        locator = floc_by_id.get(locator_ref)
        if locator is None:
            fail("missing-current-locator", f"{artifact['id']}:{locator_ref}")
        if locator.get("formal_artifact_ref") != artifact["id"]:
            fail("locator-artifact-mismatch", locator_ref)
        if locator.get("record_status") != "active" or locator.get("locator_status") != "current":
            fail("noncurrent-selected-locator", locator_ref)
        current_locator_ids.add(locator_ref)
    active_locator_ids = {row["id"] for row in floc if row.get("record_status") == "active"}
    if current_locator_ids != active_locator_ids:
        fail("current-locator-coverage", repr(sorted(active_locator_ids - current_locator_ids)))

    for locator in floc:
        if locator.get("formal_artifact_ref") not in fart_by_id:
            fail("orphan-floc", locator["id"])

    for link in flink:
        artifact = fart_by_id.get(link.get("formal_artifact_ref"))
        if artifact is None:
            fail("broken-flink-join", f"{link['id']}:{link.get('formal_artifact_ref')}")
        candidate = link.get("candidate_ref_current_resolved")
        if candidate not in scope_ids:
            fail("foreign-flink-candidate", f"{link['id']}:{candidate}")
        identity = linked_by_candidate.get(candidate)
        if identity is None:
            fail("missing-linked-identity", f"{link['id']}:{candidate}")
        if link.get("candidate_lineage_resolution", {}).get("state") != "resolved_exact":
            fail("nonexact-lineage", link["id"])
        if link.get("treatment_scope") not in identity.get("treatment_scopes", []):
            fail("treatment-scope-mismatch", link["id"])
        if link["id"] not in artifact.get("curriculum_link_refs", []):
            fail("artifact-backlink-mismatch", link["id"])


def parse_project_imports(source: str, module_name: str) -> list[dict[str, str]]:
    imports: list[dict[str, str]] = []
    for line in source.splitlines():
        match = re.match(
            r"^\s*(?:(public|private)\s+)?import(?:\s+(all))?\s+(.+?)\s*$",
            line,
        )
        if not match:
            continue
        import_mode = match.group(1) or ("all" if match.group(2) else "normal")
        for dependency in match.group(3).split():
            if not re.fullmatch(r"[A-Za-z0-9_.]+", dependency):
                fail("invalid-import", f"{module_name}:{dependency}")
            imports.append({
                "dependency_kind": "project_module" if dependency.startswith("FormalMath.") else "external_module",
                "from_module": module_name,
                "import_mode": import_mode,
                "to_module": dependency,
            })
    return imports


def build_packet_objects(
    root: Path,
    scope: dict[str, Any],
    authority: dict[str, list[dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    fart = sorted(copy.deepcopy(authority["fart"]), key=lambda row: row["id"])
    floc = sorted(copy.deepcopy(authority["floc"]), key=lambda row: row["id"])
    flink = sorted(copy.deepcopy(authority["flink"]), key=lambda row: row["id"])
    linked = sorted(copy.deepcopy(authority["linked"]),
                    key=lambda row: row["candidate_ref_current_resolved"])
    fart_by_id = {row["id"]: row for row in fart}
    floc_by_id = {row["id"]: row for row in floc}

    formal_authority = {
        "schema_version": "p6-formal-authority/v1",
        "authority": "formal-math-curriculum/lean",
        "formal_subject_revision": SUBJECT_REVISION,
        "source_registry_blobs": {
            FART_REL: next(row["git_blob"] for row in scope["frozen_inputs"] if row["path"] == FART_REL),
            FLOC_REL: next(row["git_blob"] for row in scope["frozen_inputs"] if row["path"] == FLOC_REL),
            FLINK_REL: next(row["git_blob"] for row in scope["frozen_inputs"] if row["path"] == FLINK_REL),
            LINKED_REL: next(row["git_blob"] for row in scope["frozen_inputs"] if row["path"] == LINKED_REL),
        },
        "counts": {
            "fart": 21,
            "floc_active_current": 21,
            "floc_historical": 1,
            "floc_total": 22,
            "flink": 22,
            "linked_identities": 8,
        },
        "formal_artifacts": fart,
        "formal_locators": floc,
        "formal_links": flink,
        "linked_identities": linked,
    }

    links_by_candidate: dict[str, list[dict[str, Any]]] = {}
    for link in flink:
        links_by_candidate.setdefault(link["candidate_ref_current_resolved"], []).append(link)
    scope_records: list[dict[str, Any]] = []
    for row in scope["scope_rows"]:
        candidate = row["candidate_ref"]
        links = sorted(links_by_candidate.get(candidate, []), key=lambda item: item["id"])
        represented = bool(links)
        scope_records.append({
            "candidate_ref": candidate,
            "formal_artifact_refs": sorted({link["formal_artifact_ref"] for link in links}),
            "formal_representation_state": "represented" if represented else "not_represented",
            "limitation": (
                "Only the listed treatment-scoped formal links are represented; this is not a whole-row claim."
                if represented else
                "No active formal link is published at the frozen subject; absence does not alter curriculum scope."
            ),
            "primary_disposition": row["primary_disposition"],
            "scope_authority_ref": scope["scope_authority_ref"],
            "treatment_scope_refs": sorted({link["treatment_scope"] for link in links}),
        })
    release_scope = {
        "schema_version": "p6-release-scope/v1",
        "authority": "P6-M6.1 adopted scope plus Lean-derived representation state",
        "formal_subject_revision": SUBJECT_REVISION,
        "record_count": len(scope_records),
        "records": scope_records,
        "nonclaim": "No Course hierarchy, ordering, parentage or learner prerequisites are emitted.",
    }

    bindings: list[dict[str, Any]] = []
    for link in flink:
        artifact = fart_by_id[link["formal_artifact_ref"]]
        locator = floc_by_id[artifact["current_locator_refs"][0]]
        bindings.append({
            "binding_key": f"{link['id']}::{artifact['id']}::{locator['id']}",
            "candidate_ref": link["candidate_ref_current_resolved"],
            "correspondence": {
                "coverage_claim_scope": link["coverage_claim_scope"],
                "identity_resolution": link["candidate_lineage_resolution"]["state"],
                "relation": link["representation_relation"],
                "treatment_scope": link["treatment_scope"],
            },
            "formal_artifact": {
                "artifact_kind": artifact["artifact_kind"],
                "formal_artifact_ref": artifact["id"],
                "quality_state": artifact["quality_state"],
                "record_status": artifact["record_status"],
                "representation_state": artifact["representation_state"],
                "title_or_summary": artifact["title_or_summary"],
            },
            "formal_link_ref": link["id"],
            "limitation": link["assumptions_or_formulation_notes"],
            "maturity": {
                "state": "reviewed_active",
                "scope": "revision_scoped",
            },
            "source_locator": {
                "declaration_names": locator["declaration_names"],
                "file_path": locator["file_path"],
                "formal_locator_ref": locator["id"],
                "locator_status": locator["locator_status"],
                "module_name": locator["module_name"],
                "record_status": locator["record_status"],
                "repository": locator["repository"],
                "revision": locator["revision"],
            },
            "verification_vector": {
                "extraction_reproducibility": "verified_by_generator",
                "lean_build": "qualified_at_frozen_subject",
                "registry_join": "verified",
                "source_location": "verified_by_current_floc",
            },
        })
    bindings.sort(key=lambda row: row["binding_key"])
    representation_bindings = {
        "schema_version": "p6-representation-bindings/v1",
        "authority": "formal-math-curriculum/lean",
        "formal_subject_revision": SUBJECT_REVISION,
        "record_count": len(bindings),
        "records": bindings,
        "nonclaim": "Curriculum identity and correspondence remain treatment-scoped and independent of maturity.",
    }

    module_sources: list[dict[str, Any]] = []
    import_edges: list[dict[str, str]] = []
    seen_modules: set[str] = set()
    for locator in floc:
        if locator["record_status"] != "active" or locator["repository"] != "formal-math-curriculum/lean":
            continue
        module_name = locator["module_name"]
        if module_name in seen_modules:
            continue
        seen_modules.add(module_name)
        rel = locator["file_path"]
        data = read_bytes(root, rel)
        module_sources.append({
            "file_path": rel,
            "git_blob": git_blob_sha(data),
            "module_name": module_name,
            "sha256": sha256(data),
        })
        import_edges.extend(parse_project_imports(data.decode("utf-8"), module_name))
    module_sources.sort(key=lambda row: row["module_name"])
    import_edges.sort(key=lambda row: (row["from_module"], row["to_module"], row["import_mode"]))
    external_locators = [{
        "declaration_names": row["declaration_names"],
        "file_path": row["file_path"],
        "formal_artifact_ref": row["formal_artifact_ref"],
        "formal_locator_ref": row["id"],
        "module_name": row["module_name"],
        "repository": row["repository"],
        "revision": row["revision"],
    } for row in floc if row["record_status"] == "active"
        and row["repository"] != "formal-math-curriculum/lean"]
    external_locators.sort(key=lambda row: row["formal_locator_ref"])
    formal_dependencies = {
        "schema_version": "p6-formal-dependencies/v1",
        "authority": "generated from exact frozen Lean module bytes and current FLOC dependency locators",
        "formal_subject_revision": SUBJECT_REVISION,
        "mathlib_revision": MATHLIB_REVISION,
        "lean_toolchain": LEAN_TOOLCHAIN,
        "module_source_count": len(module_sources),
        "module_sources": module_sources,
        "import_edge_count": len(import_edges),
        "import_edges": import_edges,
        "external_dependency_locator_count": len(external_locators),
        "external_dependency_locators": external_locators,
        "nonclaim": "Formal import edges are not Course hierarchy, editorial sequence or learner prerequisites.",
    }

    external_records = [{
        "adoption_authority": "formal-math-curriculum/content governance",
        "candidate_ref": row["candidate_ref"],
        "external_id": None,
        "mapping_state": "needs_review",
        "nonclaim": "Coverage state only; no mapping is proposed or adopted by the Lean repository.",
        "system": system,
    } for row in scope["scope_rows"] for system in EXTERNAL_SYSTEMS]
    external_records.sort(key=lambda row: (row["candidate_ref"], row["system"]))
    external_alignment = {
        "schema_version": "p6-external-alignment-coverage/v1",
        "authority": "coverage-only ledger; curated mapping authority remains with content governance",
        "formal_subject_revision": SUBJECT_REVISION,
        "record_count": len(external_records),
        "records": external_records,
    }

    return {
        OUTPUT_RELS[0]: external_alignment,
        OUTPUT_RELS[1]: formal_authority,
        OUTPUT_RELS[2]: formal_dependencies,
        OUTPUT_RELS[3]: release_scope,
        OUTPUT_RELS[4]: representation_bindings,
    }


def validate_packet_objects(
    objects: dict[str, dict[str, Any]],
    scope: dict[str, Any],
    authority: dict[str, list[dict[str, Any]]],
) -> None:
    if contains_fixture_marker(objects):
        fail("fixture-leakage", "generated-packet")
    hit = find_forbidden_key(objects[OUTPUT_RELS[3]])
    if hit:
        fail("hierarchy-leakage", f"release-scope:{hit}")
    if objects[OUTPUT_RELS[1]].get("counts") != {
        "fart": 21,
        "floc_active_current": 21,
        "floc_historical": 1,
        "floc_total": 22,
        "flink": 22,
        "linked_identities": 8,
    }:
        fail("formal-authority-counts", repr(objects[OUTPUT_RELS[1]].get("counts")))
    release_records = objects[OUTPUT_RELS[3]].get("records", [])
    if len(release_records) != 52:
        fail("scope-row-count", str(len(release_records)))
    if len(objects[OUTPUT_RELS[4]].get("records", [])) != 22:
        fail("binding-count", str(len(objects[OUTPUT_RELS[4]].get("records", []))))
    ext_records = objects[OUTPUT_RELS[0]].get("records", [])
    if len(ext_records) != 156:
        fail("external-coverage-count", str(len(ext_records)))
    keys = {(row.get("candidate_ref"), row.get("system")) for row in ext_records}
    if len(keys) != 156:
        fail("external-coverage-duplicate", str(len(keys)))
    for row in ext_records:
        if row.get("mapping_state") != "needs_review":
            fail("external-state", f"{row.get('candidate_ref')}:{row.get('system')}")
        if row.get("external_id") is not None:
            fail("invented-external-id", f"{row.get('candidate_ref')}:{row.get('system')}")
    for binding in objects[OUTPUT_RELS[4]]["records"]:
        locator = binding["source_locator"]
        if locator["record_status"] != "active" or locator["locator_status"] != "current":
            fail("binding-noncurrent-locator", binding["binding_key"])
        vector = binding.get("verification_vector", {})
        if tuple(sorted(vector)) != (
            "extraction_reproducibility",
            "lean_build",
            "registry_join",
            "source_location",
        ):
            fail("verification-vector", binding["binding_key"])
    source_candidates = [row["candidate_ref"] for row in scope["scope_rows"]]
    output_candidates = [row["candidate_ref"] for row in release_records]
    if source_candidates != output_candidates:
        fail("scope-output-order", "mismatch")


def build_manifest(
    root: Path,
    scope: dict[str, Any],
    objects: dict[str, dict[str, Any]],
    rendered: dict[str, bytes],
) -> dict[str, Any]:
    generator_data = read_bytes(root, GENERATOR_REL)
    input_rows = [{
        "git_blob": None,
        "path": SCOPE_REL,
        "sha256": sha256(read_bytes(root, SCOPE_REL)),
    }, {
        "git_blob": git_blob_sha(generator_data),
        "path": GENERATOR_REL,
        "sha256": sha256(generator_data),
    }]
    for entry in scope["frozen_inputs"]:
        data = read_bytes(root, entry["path"])
        input_rows.append({
            "git_blob": entry["git_blob"],
            "path": entry["path"],
            "sha256": sha256(data),
        })
    input_rows.sort(key=lambda row: row["path"])
    output_rows = []
    for rel in OUTPUT_RELS:
        if rel == OUTPUT_RELS[1]:
            record_count = 21 + 22 + 22 + 8
        elif rel == OUTPUT_RELS[2]:
            record_count = (
                objects[rel]["module_source_count"]
                + objects[rel]["import_edge_count"]
                + objects[rel]["external_dependency_locator_count"]
            )
        else:
            record_count = objects[rel]["record_count"]
        output_rows.append({
            "path": rel,
            "record_count": record_count,
            "sha256": sha256(rendered[rel]),
        })
    output_rows.sort(key=lambda row: row["path"])
    counts = {
        "external_alignment_coverage": 156,
        "fart": 21,
        "flink": 22,
        "floc_active_current": 21,
        "floc_historical": 1,
        "floc_total": 22,
        "formal_dependency_external_locators": objects[OUTPUT_RELS[2]]["external_dependency_locator_count"],
        "formal_dependency_import_edges": objects[OUTPUT_RELS[2]]["import_edge_count"],
        "formal_dependency_module_sources": objects[OUTPUT_RELS[2]]["module_source_count"],
        "linked_identities": 8,
        "release_scope": 52,
        "representation_bindings": 22,
    }
    generator_fingerprint = sha256(generator_data)
    semantic_payload = {
        "counts": counts,
        "formal_subject_revision": SUBJECT_REVISION,
        "generator_fingerprint": generator_fingerprint,
        "inputs": input_rows,
        "mathlib_revision": MATHLIB_REVISION,
        "outputs": output_rows,
        "schemas": sorted(objects[rel]["schema_version"] for rel in OUTPUT_RELS),
    }
    return {
        "schema_version": "p6-publication-manifest/v1",
        "formal_subject_revision": SUBJECT_REVISION,
        "repository_heads_at_freeze": scope["repository_heads_at_freeze"],
        "lean_toolchain": LEAN_TOOLCHAIN,
        "mathlib_revision": MATHLIB_REVISION,
        "generator": {
            "fingerprint_algorithm": "sha256(exact-generator-source-bytes)",
            "generator_fingerprint": generator_fingerprint,
            "normalization": "UTF-8; sorted JSON keys; two-space indent; LF; one terminal newline",
            "path": GENERATOR_REL,
            "runtime": "Python standard library only",
        },
        "counts": counts,
        "inputs": input_rows,
        "outputs": output_rows,
        "semantic_fingerprint": sha256(compact_bytes(semantic_payload)),
        "semantic_fingerprint_algorithm": "sha256(canonical-compact-json of schemas, revisions, ordered inputs, ordered outputs, counts and generator fingerprint)",
        "projection_compatibility": [{
            "projection": projection,
            "state": "compatible",
            "boundary": (
                "formal facts only; content/editorial/alignment adoption remains downstream"
                if projection != "Lean/mathlib" else
                "exact FART/FLOC/FLINK, toolchain, mathlib and formal-dependency facts"
            ),
        } for projection in PROJECTIONS],
        "authority_boundaries": [
            "Lean owns formal artifacts, locators, links, formal dependencies and reproducibility evidence.",
            "Content governance owns canonical content IDs, editorial truth and curated external mappings.",
            "The site owns generated presentation outputs and does not become a source of authority.",
        ],
        "nonclaims": [
            "No filesystem-derived Course hierarchy or learner prerequisites.",
            "No invented canonical content IDs or OntoMathPRO/MSC2020/arXiv mappings.",
            "No whole-curriculum verification claim, release tag, M6.8 work or Project 16.",
        ],
    }


def generate_outputs(root: Path) -> dict[str, bytes]:
    root = root.resolve()
    scope = load_scope(root)
    validate_input_blobs(root, scope)
    authority = load_authorities(root)
    validate_authorities(scope, authority)
    objects = build_packet_objects(root, scope, authority)
    validate_packet_objects(objects, scope, authority)
    rendered = {rel: canonical_bytes(objects[rel]) for rel in OUTPUT_RELS}
    manifest = build_manifest(root, scope, objects, rendered)
    if tuple(row["projection"] for row in manifest["projection_compatibility"]) != PROJECTIONS:
        fail("projection-vector", repr(manifest["projection_compatibility"]))
    rendered[MANIFEST_REL] = canonical_bytes(manifest)
    return rendered


def assert_deterministic(first: dict[str, bytes], second: dict[str, bytes]) -> None:
    if first.keys() != second.keys():
        fail("nondeterministic", "output-path-set")
    for rel in first:
        if first[rel] != second[rel]:
            fail("nondeterministic", rel)


def check_outputs(root: Path, expected: dict[str, bytes]) -> None:
    for rel, data in expected.items():
        path = root / rel
        if not path.is_file():
            fail("missing-output", rel)
        actual = path.read_bytes()
        if actual != data:
            fail("output-drift", f"{rel}:expected={sha256(data)}:actual={sha256(actual)}")


def write_outputs(root: Path, rendered: dict[str, bytes]) -> None:
    for rel, data in rendered.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--print-semantic-fingerprint", action="store_true")
    args = parser.parse_args(argv)
    try:
        first = generate_outputs(args.root)
        second = generate_outputs(args.root)
        assert_deterministic(first, second)
        if args.check:
            check_outputs(args.root, first)
        else:
            write_outputs(args.root, first)
        manifest = json.loads(first[MANIFEST_REL])
        if args.print_semantic_fingerprint:
            print(manifest["semantic_fingerprint"])
        print(
            "p6-publication:pass:"
            f"scope={manifest['counts']['release_scope']}:"
            f"fart={manifest['counts']['fart']}:"
            f"floc={manifest['counts']['floc_total']}:"
            f"flink={manifest['counts']['flink']}:"
            f"bindings={manifest['counts']['representation_bindings']}:"
            f"external={manifest['counts']['external_alignment_coverage']}:"
            f"fingerprint={manifest['semantic_fingerprint']}"
        )
        return 0
    except PublicationError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
