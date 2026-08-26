#!/usr/bin/env python3
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
"""Positive and adversarial controls for the P6 publication contract."""

from __future__ import annotations

import copy
import importlib.util
import json
import sys
from pathlib import Path
from typing import Callable

from p6_frozen_authority import build_frozen_overlay


ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "publication/p6-v1/generate.py"


def load_generator():
    spec = importlib.util.spec_from_file_location("p6_publication_generator", GENERATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load generator")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def expect_failure(label: str, signature: str, action: Callable[[], None]) -> None:
    try:
        action()
    except Exception as exc:
        message = str(exc)
        if signature not in message:
            raise AssertionError(f"{label}: wrong signature: {message}") from exc
        print(f"p6-publication-control:expected-fail:{label}:{signature}")
        return
    raise AssertionError(f"{label}: unexpected success")


def main() -> int:
    generator = load_generator()
    live_scope = generator.load_scope(ROOT)
    frozen_overlay = build_frozen_overlay(ROOT, live_scope)
    live_read_bytes = generator.read_bytes

    def frozen_read_bytes(root: Path, relative: str) -> bytes:
        if relative in frozen_overlay:
            return frozen_overlay[relative]
        return live_read_bytes(root, relative)

    generator.read_bytes = frozen_read_bytes
    baseline = generator.generate_outputs(ROOT)
    generator.check_outputs(ROOT, baseline)
    generator.assert_deterministic(baseline, generator.generate_outputs(ROOT))
    print("p6-publication-control:pass:checked-in-and-deterministic")
    print("p6-publication-control:pass:frozen-authority-prefixes=4;registry-view=1")

    scope = generator.load_scope(ROOT)
    authority = generator.load_authorities(ROOT)
    generator.validate_authorities(scope, authority)
    objects = generator.build_packet_objects(ROOT, scope, authority)
    generator.validate_packet_objects(objects, scope, authority)

    missing_scope = copy.deepcopy(scope)
    missing_scope["scope_rows"].pop()
    expect_failure(
        "missing-release-scope-row",
        "p6-publication:error:scope-row-count:",
        lambda: generator.validate_scope(missing_scope),
    )

    broken_link = copy.deepcopy(authority)
    broken_link["flink"][0]["formal_artifact_ref"] = "FART-P2-999999"
    expect_failure(
        "broken-flink-join",
        "p6-publication:error:broken-flink-join:",
        lambda: generator.validate_authorities(scope, broken_link),
    )

    stale_subject = copy.deepcopy(scope)
    stale_subject["formal_subject_revision"] = "0" * 40
    expect_failure(
        "stale-subject-revision",
        "p6-publication:error:stale-subject:",
        lambda: generator.validate_scope(stale_subject),
    )

    stale_blob = copy.deepcopy(scope)
    stale_blob["frozen_inputs"][0]["git_blob"] = "0" * 40
    expect_failure(
        "stale-input-blob",
        "p6-publication:error:stale-input-blob:",
        lambda: generator.validate_input_blobs(ROOT, stale_blob),
    )

    invented_mapping = copy.deepcopy(objects)
    invented_mapping[generator.OUTPUT_RELS[0]]["records"][0]["external_id"] = "invented:1"
    expect_failure(
        "invented-external-id",
        "p6-publication:error:invented-external-id:",
        lambda: generator.validate_packet_objects(invented_mapping, scope, authority),
    )

    drifted = dict(baseline)
    drifted[generator.OUTPUT_RELS[3]] += b" "
    expect_failure(
        "generated-output-drift",
        "p6-publication:error:output-drift:",
        lambda: generator.check_outputs(ROOT, drifted),
    )

    hierarchy = copy.deepcopy(scope)
    hierarchy["scope_rows"][0]["course_order"] = 1
    expect_failure(
        "hierarchy-leakage",
        "p6-publication:error:hierarchy-leakage:",
        lambda: generator.validate_scope(hierarchy),
    )

    maturity_overclaim = copy.deepcopy(objects)
    maturity_overclaim[generator.OUTPUT_RELS[4]]["records"][0]["maturity"]["state"] = "production_complete"
    expect_failure(
        "maturity-overclaim",
        "p6-publication:error:maturity-overclaim:",
        lambda: generator.validate_packet_objects(maturity_overclaim, scope, authority),
    )

    verification_overclaim = copy.deepcopy(objects)
    verification_overclaim[generator.OUTPUT_RELS[4]]["records"][0]["verification_vector"]["lean_build"] = "verified_forever"
    expect_failure(
        "verification-overclaim",
        "p6-publication:error:verification-overclaim:",
        lambda: generator.validate_packet_objects(verification_overclaim, scope, authority),
    )

    nondeterministic = dict(baseline)
    nondeterministic[generator.OUTPUT_RELS[2]] += b" "
    expect_failure(
        "nondeterministic-second-generation",
        "p6-publication:error:nondeterministic:",
        lambda: generator.assert_deterministic(baseline, nondeterministic),
    )

    fixture_leakage = copy.deepcopy(objects)
    fixture_leakage[generator.OUTPUT_RELS[1]]["negative_fixture_marker"] = True
    expect_failure(
        "fixture-leakage",
        "p6-publication:error:fixture-leakage:",
        lambda: generator.validate_packet_objects(fixture_leakage, scope, authority),
    )

    manifest = json.loads(baseline[generator.MANIFEST_REL])
    if [row["projection"] for row in manifest["projection_compatibility"]] != list(generator.PROJECTIONS):
        raise AssertionError("five-projection vector mismatch")
    print(
        "p6-publication-control:summary:pass:"
        f"scope={manifest['counts']['release_scope']}:"
        f"bindings={manifest['counts']['representation_bindings']}:"
        f"external={manifest['counts']['external_alignment_coverage']}:"
        f"fingerprint={manifest['semantic_fingerprint']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"p6-publication-control:fail:{exc}", file=sys.stderr)
        raise
