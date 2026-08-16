# M2.9 Traceability Reader V2

`P2-TRACE-M2.9-READER-v2` is an additive, read-only diagnostic/navigation surface. It preserves the M2.8 `query` commands unchanged and does not create another traceability or curriculum authority.

## Commands

```text
inspect curriculum <candidate-id> [--treatment <scope>] [--root <repository-root>]
inspect artifact <FART-id> [--root <repository-root>]
inspect source <module|file|declaration> [--root <repository-root>]
inspect unresolved [--root <repository-root>]
```

Every successful `inspect` command runs the same strong validation used by the existing CLI before emitting its reader envelope.

## Envelope

Reader v2 emits one JSON object after validation:

```text
reader_contract_ref = P2-TRACE-M2.9-READER-v2
authority = derived_read_only
query_kind
query_value
match_count
result_state
results
```

`result_state` is descriptive reader output only. It is not workflow, curriculum, readiness, Level, formalization-completeness, or proof-quality authority.

Normal query states are `zero_matches`, `matches`, and `multiple_matches`. `inspect unresolved` uses `unresolved_present` when the existing derived unresolved view is nonempty.

## Curriculum navigation

Curriculum inspection keeps the M2.8 set-valued rule: a candidate may match `candidate_ref_as_recorded`, `candidate_ref_current_resolved`, or both. Each result reports explicit match reasons rather than collapsing lineage.

Optional `--treatment` is exact equality against the already-authored FLINK `treatment_scope`. The reader does not rank, infer, normalize, or invent treatment categories.

Multiple FART representations remain multiple results. Match count never implies curriculum coverage or completeness.

## Artifact navigation

Artifact inspection retains the original by-artifact record and adds explicit locator lifecycle groups/counts:

- current;
- historical;
- unresolved;
- total;
- curriculum-link count.

Historical visibility never means current resolvability.

## Source navigation

Source inspection remains exact match only. It reports whether each result matched by:

- `module_name`;
- `file_path`;
- `declaration_name`.

No fuzzy lookup, theorem-name similarity, or migration inference is added.

## Unresolved diagnostics

`inspect unresolved` wraps the existing derived `unresolvedView`. It is orientation only and never mutates FART/FLOC/FLINK or curriculum-lock records.

## Failure semantics

Strong validation precedes reader output. Invalid authored state, broken current declaration resolution, dependency mismatch, or curriculum-authority inconsistency remains a command failure. The reader must never translate such failures into a valid `zero_matches` envelope.

Duplicate reader options are rejected rather than silently overridden.

## V1 compatibility

Existing commands remain JSONL streams:

```text
query curriculum ...
query artifact ...
query declaration ...
```

Reader v2 does not change their output envelope or semantics.

## Scale evidence

`Benchmarks/run-reader-scaling.sh` uses non-production 16/64/256-record fixtures under `P2-SCALE-M2.9-PROTOCOL-v1`. It measures three exact reader workloads after warmup:

- one curriculum match;
- zero curriculum matches;
- multiple source matches, where the expected cardinality equals the record count.

The benchmark intentionally retains strong validation on every measured command. It is therefore reader+validation cost, not a claim that validation has been optimized away.

Synthetic IDs never enter the production registry and carry no curriculum-coverage meaning. No performance SLA is adopted from these regimes.

## Provenance relationship

Reader v2 is implemented directly on top of the qualified MAT-203 head and therefore inherits `P2-TRACE-M2.9-PROVENANCE-v2`. `inspect` operates from validated authored records/in-memory derived views; it does not treat on-disk generated views as authority and does not bypass the M2.9 content-and-projection freshness contract when those files are used elsewhere.
