#!/usr/bin/env bash
# License: see the repository LICENSE file.
# Authors: Formal Mathematics Curriculum contributors
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT_ROOT="${BENCH_OUT_ROOT:-$ROOT/.lake/build/benchmarks}"
RESULT_DIR="$OUT_ROOT/results"
WORK_ROOT="$OUT_ROOT/work"
SIZES="${BENCH_SIZES:-8 32 128}"
REPETITIONS="${BENCH_REPETITIONS:-3}"
SUBJECT_HEAD_SHA="${BENCH_HEAD_SHA:-$(git -C "$ROOT" rev-parse HEAD)}"
SUBJECT_INTEGRATION_SHA="${BENCH_INTEGRATION_SHA:-$(git -C "$ROOT" rev-parse HEAD)}"
LEAN_TOOLCHAIN="$(tr -d '\n' < "$ROOT/lean-toolchain")"

mkdir -p "$RESULT_DIR" "$WORK_ROOT"
CSV="$RESULT_DIR/build-scaling.csv"
META="$RESULT_DIR/metadata.env"

cat > "$CSV" <<'EOF'
subject_head_sha,subject_integration_sha,workload,topology,modules,import_edges,graph_depth,max_fanout,iteration,warmup,project_artifact_state,change_state,wall_ms,result
EOF

cat > "$META" <<EOF
benchmark_protocol=P2-SCALE-M2.9-PROTOCOL-v1
benchmark_schema=P2-SCALE-M2.9-EVIDENCE-v1
synthetic=true
production_traceability_ids_allocated=false
subject_head_sha=$SUBJECT_HEAD_SHA
subject_integration_sha=$SUBJECT_INTEGRATION_SHA
lean_toolchain=$LEAN_TOOLCHAIN
sizes=$SIZES
repetitions=$REPETITIONS
platform=$(uname -srm)
EOF

now_ns() {
  date +%s%N
}

measure() {
  local workload="$1" topology="$2" modules="$3" edges="$4" depth="$5" fanout="$6"
  local iteration="$7" warmup="$8" artifact_state="$9" change_state="${10}"
  shift 10
  local start end elapsed status result
  start="$(now_ns)"
  set +e
  "$@"
  status=$?
  set -e
  end="$(now_ns)"
  elapsed=$(( (end - start) / 1000000 ))
  if [[ "$status" -eq 0 ]]; then result=pass; else result=fail; fi
  printf '%s,%s,%s,%s,%d,%d,%d,%d,%d,%s,%s,%s,%d,%s\n' \
    "$SUBJECT_HEAD_SHA" "$SUBJECT_INTEGRATION_SHA" "$workload" "$topology" \
    "$modules" "$edges" "$depth" "$fanout" "$iteration" "$warmup" \
    "$artifact_state" "$change_state" "$elapsed" "$result" >> "$CSV"
  return "$status"
}

write_header() {
  cat <<'EOF'
/-
License: see the repository LICENSE file.
Authors: Formal Mathematics Curriculum contributors
Synthetic M2.9 benchmark fixture. This file is generated under .lake/build and is not curriculum content.
-/
module
EOF
}

make_star_workspace() {
  local n="$1" ws="$2" i leaf
  rm -rf "$ws"
  mkdir -p "$ws/Bench"
  cp "$ROOT/lean-toolchain" "$ws/lean-toolchain"
  cat > "$ws/lakefile.toml" <<'EOF'
name = "formal-math-synthetic-benchmark"
defaultTargets = ["Bench"]
requiresModuleSystem = true
allowNonModules = false

[[lean_lib]]
name = "Bench"
globs = ["Bench.*"]
requiresModuleSystem = true
allowNonModules = false
EOF

  {
    write_header
    printf '\nnamespace Bench\n\npublic def commonSeed : Nat := 1\n\nend Bench\n'
  } > "$ws/Bench/Common.lean"

  {
    write_header
    printf '\n'
    for ((i=1; i<=n; i++)); do
      printf 'public import Bench.Leaf%04d\n' "$i"
    done
  } > "$ws/Bench.lean"

  for ((i=1; i<=n; i++)); do
    leaf="$ws/Bench/Leaf$(printf '%04d' "$i").lean"
    {
      write_header
      printf '\nimport Bench.Common\n\nnamespace Bench\n\ndef leaf%04d : Nat := commonSeed + %d\n\nend Bench\n' "$i" "$i"
    } > "$leaf"
  done
}

build_workspace() {
  local ws="$1" log_path
  log_path="$ws/.benchmark-last-build.log"
  if (cd "$ws" && lake build Bench >"$log_path" 2>&1); then
    return 0
  fi
  cat "$log_path" >&2
  return 1
}

mutate_leaf() {
  local ws="$1" n="$2" rep="$3" leaf
  leaf="$ws/Bench/Leaf$(printf '%04d' "$n").lean"
  printf '\nnamespace Bench\ndef leafMutation%d : Nat := %d\nend Bench\n' "$rep" "$rep" >> "$leaf"
}

mutate_central_public() {
  local ws="$1" rep="$2"
  printf '\nnamespace Bench\npublic def centralMutation%d : Nat := %d\nend Bench\n' "$rep" "$rep" >> "$ws/Bench/Common.lean"
}

for n in $SIZES; do
  if ! [[ "$n" =~ ^[1-9][0-9]*$ ]]; then
    printf 'benchmark:error:invalid-size:%s\n' "$n" >&2
    exit 2
  fi
  ws="$WORK_ROOT/star-$n"
  modules=$((n + 2))
  # Common -> N leaves, and N leaves -> umbrella.
  edges=$((2 * n))
  depth=3
  fanout=$n

  # One declared warmup clean build per cardinality. It is retained in evidence but excluded from comparable-series summaries.
  make_star_workspace "$n" "$ws"
  rm -rf "$ws/.lake"
  measure clean-project-build star "$modules" "$edges" "$depth" "$fanout" \
    0 true project_clean no_source_change build_workspace "$ws"

  # Clean-series: recreate root build state before every measured repetition.
  for ((rep=1; rep<=REPETITIONS; rep++)); do
    make_star_workspace "$n" "$ws"
    rm -rf "$ws/.lake"
    measure clean-project-build star "$modules" "$edges" "$depth" "$fanout" \
      "$rep" false project_clean no_source_change build_workspace "$ws"
  done

  # Warm/no-op series: same exact subject and compatible root artifacts.
  make_star_workspace "$n" "$ws"
  build_workspace "$ws"
  for ((rep=1; rep<=REPETITIONS; rep++)); do
    measure warm-noop-build star "$modules" "$edges" "$depth" "$fanout" \
      "$rep" false project_warm no_source_change build_workspace "$ws"
  done

  # Leaf edit: a private leaf-only change after a warm build.
  for ((rep=1; rep<=REPETITIONS; rep++)); do
    make_star_workspace "$n" "$ws"
    build_workspace "$ws"
    mutate_leaf "$ws" "$n" "$rep"
    measure leaf-module-edit star "$modules" "$edges" "$depth" "$fanout" \
      "$rep" false project_warm leaf_local_change build_workspace "$ws"
  done

  # Central edit: a PUBLIC change to Common, imported by every leaf, after a warm build.
  for ((rep=1; rep<=REPETITIONS; rep++)); do
    make_star_workspace "$n" "$ws"
    build_workspace "$ws"
    mutate_central_public "$ws" "$rep"
    measure central-module-edit star "$modules" "$edges" "$depth" "$fanout" \
      "$rep" false project_warm central_project_change build_workspace "$ws"
  done
done

printf 'benchmark:build-scaling:pass:csv=%s\n' "$CSV"
