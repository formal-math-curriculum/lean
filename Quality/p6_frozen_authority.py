#!/usr/bin/env python3
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
"""Construct the immutable P6 authority view from append-only live registries."""

from __future__ import annotations

import copy
import hashlib
import json
import re
from pathlib import Path
from typing import Any

JSONL_PREFIX_COUNTS = {
    "metadata/curriculum-lock/linked-identities.jsonl": 8,
    "metadata/formal-artifacts/fart/000001-001000.jsonl": 21,
    "metadata/formal-artifacts/flink/000001-001000.jsonl": 22,
    "metadata/formal-artifacts/floc/000001-001000.jsonl": 22,
}
REGISTRY_REL = "metadata/formal-artifacts/registry.json"
FROZEN_COUNTS = {"fart": 21, "flink": 22, "floc": 22}
FROZEN_NEXT_IDS = {
    "fart": "FART-P2-000022",
    "flink": "FLINK-P2-000023",
    "floc": "FLOC-P2-000023",
}


class FrozenAuthorityError(RuntimeError):
    """A stable failure for an invalid post-P6 authority extension."""


def fail(code: str, detail: str) -> None:
    raise FrozenAuthorityError(f"p6-frozen-authority:error:{code}:{detail}")


def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def expected_blobs(scope: dict[str, Any]) -> dict[str, str]:
    rows = scope.get("frozen_inputs")
    if not isinstance(rows, list):
        fail("scope", "missing-frozen-inputs")
    result = {str(row.get("path")): str(row.get("git_blob")) for row in rows}
    for relative in (*JSONL_PREFIX_COUNTS, REGISTRY_REL):
        if relative not in result:
            fail("scope", f"missing:{relative}")
    return result


def frozen_jsonl_prefix(root: Path, relative: str, count: int, expected: str) -> bytes:
    data = (root / relative).read_bytes()
    lines = data.splitlines(keepends=True)
    if len(lines) < count:
        fail("truncated-jsonl", f"{relative}:expected-at-least={count}:actual={len(lines)}")
    for number, raw in enumerate(lines, 1):
        try:
            value = json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            fail("invalid-jsonl", f"{relative}:{number}:{exc}")
        if not isinstance(value, dict):
            fail("invalid-jsonl-row", f"{relative}:{number}")
    prefix = b"".join(lines[:count])
    actual = git_blob_sha(prefix)
    if actual != expected:
        fail("frozen-prefix-drift", f"{relative}:expected={expected}:actual={actual}")
    return prefix


def numeric_suffix(value: str) -> int:
    match = re.fullmatch(r"[A-Z]+-P2-(\d{6})", value)
    if match is None:
        fail("cursor-shape", value)
    return int(match.group(1))


def frozen_registry(root: Path, expected: str) -> bytes:
    data = (root / REGISTRY_REL).read_bytes()
    try:
        current = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        fail("invalid-registry", str(exc))
    if not isinstance(current, dict):
        fail("invalid-registry", "root-not-object")
    counts = current.get("record_counts")
    cursors = current.get("next_ids")
    if not isinstance(counts, dict) or not isinstance(cursors, dict):
        fail("invalid-registry", "missing-counts-or-cursors")
    for key, frozen_count in FROZEN_COUNTS.items():
        if counts.get(key, -1) < frozen_count:
            fail("registry-count-regression", key)
        if numeric_suffix(str(cursors.get(key))) < numeric_suffix(FROZEN_NEXT_IDS[key]):
            fail("registry-cursor-regression", key)
    frozen = copy.deepcopy(current)
    frozen["next_ids"] = dict(FROZEN_NEXT_IDS)
    frozen["record_counts"] = dict(FROZEN_COUNTS)
    rendered = (
        json.dumps(frozen, ensure_ascii=False, separators=(",", ":")) + "\n"
    ).encode("utf-8")
    actual = git_blob_sha(rendered)
    if actual != expected:
        fail("frozen-registry-drift", f"expected={expected}:actual={actual}")
    return rendered


def build_frozen_overlay(root: Path, scope: dict[str, Any]) -> dict[str, bytes]:
    """Return exact P6 bytes while proving the live registries are append-only extensions."""
    blobs = expected_blobs(scope)
    overlay = {
        relative: frozen_jsonl_prefix(root, relative, count, blobs[relative])
        for relative, count in JSONL_PREFIX_COUNTS.items()
    }
    overlay[REGISTRY_REL] = frozen_registry(root, blobs[REGISTRY_REL])
    return overlay
