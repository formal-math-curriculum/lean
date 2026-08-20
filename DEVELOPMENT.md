# Development environment

The supported FormalMath development environment is defined by **versioned repository state**. Editors and caches are conveniences over this command-line baseline.

## Prerequisites

- Git
- authenticated GitHub access to the private `formal-math-curriculum/lean` repository
- [`elan`](https://github.com/leanprover/elan)
- network access when the selected Lean toolchain or Git dependencies are not already available locally

A specific editor, GitHub CLI, container runtime, or Nix environment is not required.

## Select the revision you intend to reproduce

Do **not** assume that the repository's default branch already contains the environment you want to reproduce. Environment evidence is always tied to an explicit Git ref/SHA.

```sh
git clone https://github.com/formal-math-curriculum/lean.git
cd lean
git fetch origin
# Replace TARGET_REF with the branch, tag, or commit SHA you intend to reproduce.
git checkout TARGET_REF
git rev-parse HEAD
git status --short --branch
```

When reproducing a reported failure, `TARGET_REF` should be the exact reported commit SHA whenever possible.

### Current versioned baseline

The selected Lean/Lake environment is versioned on `main`. Evidence remains revision-bound: do not transfer verification from a reported commit or pull-request head to a later `main` SHA without establishing implementation-file equivalence or rerunning the applicable environment checks.

## Fresh setup from the selected revision

After checking out the intended ref/SHA:

```sh
cat lean-toolchain
elan show
lean --version
lake --version
lake update
git diff --exit-code -- lean-toolchain lakefile.toml lake-manifest.json
lake build FormalMath
```

The current baseline is Lean `4.33.0` with mathlib `v4.33.0`. The effective versions reported by `elan`, Lean, and Lake matter; the contents of `lean-toolchain` alone are not sufficient evidence if an elan override selects something else.

The diff assertion is part of the reproducibility check. If `lean-toolchain`, `lakefile.toml`, or `lake-manifest.json` is intentionally modified, that modified state must be treated as the explicit subject under test rather than silently reported as the versioned baseline.

`lake update` may use mathlib's precompiled cache when the toolchain matches. This is an acceleration path, not a source of semantic truth.

Supported optional cache retrieval:

```sh
bash Quality/quality.sh env
```

The semantic preflight runs first. Cache retrieval then has a 300-second default budget; override it with a positive integer such as `QUALITY_CACHE_TIMEOUT_SECONDS=60`. GNU/coreutils `timeout` sends `TERM` at expiry and forces `KILL` after a five-second grace. Cache success, failure, expiry, invalid override, or an unavailable compatible timeout mechanism is recorded explicitly, but remains nonblocking after semantic PASS because cache contents are not proof, build, or curriculum evidence. Invalid values and unavailable-timeout cases skip the optional fetch.

## Cold reproduction without project cache

Use this when investigating cache masking or environment drift:

```sh
rm -rf .lake
MATHLIB_NO_CACHE_ON_UPDATE=1 lake update
git diff --exit-code -- lean-toolchain lakefile.toml lake-manifest.json
lake build FormalMath
```

`.lake/` is disposable derived state. A warm build that succeeds while this clean path fails is a reproducibility defect and should be reported as such.

## Toolchain override drift

Detect the declared/effective state:

```sh
cat lean-toolchain
elan show
lean --version
```

If an unintended directory override selects another Lean version, remove the override and verify recovery:

```sh
elan override unset
elan show
lean --version
```

Do not edit `lean-toolchain` merely to accommodate an accidental local override. Version changes are governed dependency/environment changes.

## Manifest or dependency drift

Inspect changes before accepting them:

```sh
git diff -- lakefile.toml lake-manifest.json lean-toolchain
git status --short
```

For an accidental local change when no dependency update is intended:

```sh
git restore lakefile.toml lake-manifest.json lean-toolchain
rm -rf .lake
lake update
git diff --exit-code -- lakefile.toml lake-manifest.json lean-toolchain
```

Do not use this recovery sequence to erase evidence from an intentional dependency migration.

## Environment failure report

Include at least:

```text
Repository: formal-math-curriculum/lean
Git commit:
Git branch/ref:
Working tree status:
Platform / architecture:
lean-toolchain content:
elan show:
lean --version:
lake --version:
mathlib input tag:
resolved mathlib revision:
Execution mode: warm_cache | cold_project_cache | fresh_clone | override_test | other
Command that failed:
Failure phase:
Minimal relevant error excerpt:
Known elan override? yes/no/details
Existing .lake before run? yes/no
Recovery attempts:
Clean reproduction result: yes/no/unknown
```

Useful diagnostic commands:

```sh
git rev-parse HEAD
git status --short --branch
uname -a
cat lean-toolchain
elan show
lean --version
lake --version
git diff -- lakefile.toml lake-manifest.json lean-toolchain
```

## Editor policy

No editor is canonical. An editor integration is compatible with the supported workflow when it uses the repository-selected Lean toolchain/LSP and the same repository revision/dependency state. Editor-only success does not override a failing `lake build FormalMath`.

## Scope

A successful environment build is evidence about reproducibility and compilation only. It is not evidence of curriculum completeness, learner readiness, mathematical importance, absence of all axioms/placeholders, or empirical adequacy of applied models.
