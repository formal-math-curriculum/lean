#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

REPORT_ROOT="${QUALITY_REPORT_DIR:-.lake/build/quality}"
dimension="${1:?dimension required}"
sha="${2:-$(git rev-parse HEAD)}"
mkdir -p "$REPORT_ROOT"
mktemp -d "$REPORT_ROOT/${dimension}-${sha}-XXXXXXXX"
