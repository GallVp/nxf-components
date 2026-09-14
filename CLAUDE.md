# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A staging repository of nf-core-style Nextflow DSL2 modules and subworkflows (`repository_type: modules` in `.nf-core.yml`). Components live here under the `gallvp` namespace while under development, and are submitted upstream to [nf-core/modules](https://github.com/nf-core/modules) once they meet nf-core guidelines. Once a PR is merged upstream, the local copy may be removed at any time — check `README.md` / `SUBMITTED.md` for submission status before assuming a module is still needed here.

## Setup

Install the dev version of nf-core/tools (required — this repo relies on dev-only features):

```bash
pip install --upgrade --force-reinstall git+https://github.com/nf-core/tools.git@dev
```

## Workflow for adding a new component

Follow this exact sequence (from `README.md`):

1. **Search**: check [nf-core/modules](https://nf-co.re/modules), its [issues](https://github.com/nf-core/modules/issues) and [PRs](https://github.com/nf-core/modules/pulls) — don't duplicate work in progress.
2. **Issue**: open an issue on nf-core/modules for the module/subworkflow.
3. **Create**: `nf-core -v modules create tool/subtool` on a tool-specific branch.
4. **Lint**: `nf-core -v modules lint tool/subtool`.
5. **Test**: `nf-core -v modules -g https://github.com/GallVp/nxf-components.git test tool/subtool`.
6. **Commit** to this repo.
7. **Install**: `nf-core -v modules -g https://github.com/GallVp/nxf-components.git install tool/subtool`.
8. **PR**: open a PR against nf-core/modules from a personal fork.
9. **Status**: update the submission table in `README.md`.
10. **Remove**: once the nf-core/modules PR is merged, delete the module here and update the status table.

## Common commands

```bash
# Run nf-test for a single module or subworkflow (from repo root)
nf-test test modules/gallvp/<tool>/<subtool>
nf-test test subworkflows/gallvp/<name>

# Run with a specific execution profile (matches CI matrix: conda, docker, singularity)
nf-test test --profile=docker modules/gallvp/<tool>/<subtool>

# Update/regenerate a test snapshot
nf-test test --update-snapshot modules/gallvp/<tool>/<subtool>

# Lint a single module / subworkflow
nf-core -v modules lint <tool>/<subtool>
nf-core subworkflows lint <name>

# Run all pre-commit hooks (docs sync check, test data path check, prettier, ruff, hadolint, nf-lint, etc.)
# CI runs these via `prek` (a drop-in Rust reimplementation of pre-commit); either works locally off the same config
pre-commit run --all-files

# Clean local Nextflow run artifacts (.nextflow, work/, output/, .nf-test, etc.)
./cleanNXF.sh
```

nf-test configuration (`nf-test.config`) sets `testsDir "."`, points `configFile` at `tests/config/nf-test.config`, and loads nf-test plugins (`nft-bam`, `nft-vcf`, `nft-csv`, `nft-fastq`, `nft-anndata`, `nft-compress`, `nft-utils`). Test data URLs are centralized in `tests/config/test_data.config` (backed by `nf-core/test-datasets`) — don't hardcode test data URLs directly in `.nf.test` files; reference `params.test_data...` instead so `.github/scripts/check_test_data_paths.sh` (a pre-commit hook) can rewrite them.

## Docs sync

`docs/index.html` and `docs/AVAILABLE.txt` are generated from the set of `main.nf` files under `*/gallvp/*` by `docs/populate_index.sh`. This runs as a pre-commit hook (`docs_check`) and **fails the commit** if the generated docs are out of sync with the current module/subworkflow list — run `./docs/populate_index.sh` after adding/removing a component to resync before committing.

## Hybrid subworkflow testing workaround

nf-core/tools does not support subworkflows composed of both `gallvp` and `nf-core` modules (see [nf-core/tools#1927](https://github.com/nf-core/tools/issues/1927)). The workaround: `nf-core-modules/` is a dummy nf-core pipeline used only to install real nf-core modules for testing. `nf-core-hybridisation.sh` then copies those installed modules from `nf-core-modules/modules/nf-core/<tool>` into `modules/gallvp/<tool>` (rewriting the `modules_nfcore` test tag to `modules_gallvp`), so that hybrid subworkflows here only ever reference modules under `modules/gallvp/`. Re-run `./nf-core-hybridisation.sh` after updating `nf-core-modules` if a hybrid subworkflow's dependencies change. One module (`gunzip`) is additionally kept under `modules/nf-core/` for subworkflow-testing purposes.

## Structure of a module/subworkflow

Each component follows the standard nf-core layout:

- `main.nf` — the process (module) or workflow (subworkflow) definition.
- `meta.yml` — metadata, validated against `modules/yaml-schema.json` / `subworkflows/yaml-schema.json` via pre-commit.
- `environment.yml` — conda dependencies, validated against `modules/environment-schema.json`.
- `tests/main.nf.test` — nf-test cases; tests are tagged (e.g. `modules_gallvp`, `modules`) which drives CI's change-detection and matrix.
- `tests/main.nf.test.snap` — nf-test snapshots.
- `tests/nextflow.config` — test-specific config overrides (e.g. for prefix/ext.args cases).

Subworkflows are named by chaining their component tool names in dataflow order, e.g. `fasta_seqkit_refsort`, `gff_fasta_gffread_eggnogmapper_agat_gt` — match this convention for new subworkflows. Subworkflow `main.nf` files reference module includes with relative paths like `../../../modules/gallvp/<tool>/main`.

## CI (`.github/workflows/test.yml`)

- `pre-commit`: runs all pre-commit hooks via `prek`.
- `nf-test-changes`: detects nf-test files related to changes since the PR base, via the local composite action `.github/actions/detect-nf-test-changes` (runs `nf-test --dry-run --changed-since --related-tests`, excludes anything under `nf-core-modules/` and any test tagged `modules_nfcore`), splits the result into module vs. subworkflow paths, then calls `.github/actions/get-shards` to compute how many parallel nf-test shards are needed (capped at `max_shards`).
- `nf-core-lint-modules` / `nf-core-lint-subworkflows`: lints each changed module/subworkflow with nf-core/tools dev.
- `nf-test`: matrix over `shard` × `profile` (`conda`/`docker`/`singularity`). Each job filters the full changed-paths list against `.github/skip_nf_test.json` (a map of profile → path prefixes to skip — add an entry there instead of a matrix `exclude` when a tool has no conda recipe), then runs `.github/actions/nf-test-action` with `--shard N/total` over the filtered paths.
- `confirm-pass`: aggregate required-status gate.

The three composite actions under `.github/actions/` (`detect-nf-test-changes`, `get-shards`, `nf-test-action`) mirror the pattern used in the sibling `nf-modules` repo, scaled down for this repo's size (standard `ubuntu-latest` runners, no self-hosted `runs-on` labels, no arm64 leg, no Sentieon secrets).

## Style

- Groovy/Nextflow: linted via `nf-lint-pre-commit` (nextflow-lint) — no auto-formatting enabled yet.
- Python: `ruff` (see `ruff.toml`, line length 120, target py310), rules `I,E1,E4,E7,E9,F,UP,N`.
- Everything else (`md`, `yml`, `html`, `css`, `js`, `sh`): Prettier, tab width 2 (4 for other file types) — see `.prettierrc.yml` / `.prettierignore`.
