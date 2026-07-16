# GitHub Actions Workflows

This directory contains workflows for testing the composite actions in this repository.

## Workflow Naming Convention

Workflows are organized using a clear naming pattern:
```
test.<action-name>.<test-type>.yml
```

Examples:
- `test.release.unit.yml` - Unit tests for release action
- `test.release.integration.yml` - Integration tests for release action
- `test.python-setup-uv.unit.yml` - Unit tests for python-setup/uv action

## Test Workflows

### Release Action Tests

- **[test.release.unit.yml](test.release.unit.yml)**: Comprehensive unit tests for the release action
  - Runs automatically on push/PR
  - Tests all package managers (uv, poetry, pixi)
  - Validates inputs, permissions, and action structure
  
- **[test.release.integration.yml](test.release.integration.yml)**: End-to-end integration tests
  - Manual execution only
  - Tests actual release workflow
  - Verifies tag creation, version bumping, and wheel building

### Python Setup Tests

- **[test.python-setup-uv.unit.yml](test.python-setup-uv.unit.yml)**: Tests for the python-setup/uv action
  - Tests Python version installation
  - Verifies uv installation and dependency management

### MkDocs Deploy Tests

- **[test.mkdocs-deploy.unit.yml](test.mkdocs-deploy.unit.yml)**: Tests for the mkdocs-deploy action
  - Setup wiring across uv, poetry, and pixi (with `mike` + `mkdocs` installed)
  - `install-groups` propagates through to `python-setup/{uv,poetry}` (extras are intentionally not supported — doc deps belong in groups)
  - `pixi-environments` / `pixi-activate-environment` forwarded to `python-setup/pixi` (mirrors `actions/release/github`)
  - `python-version` pin honored (3.13)
  - `git config` set to `github.actor` after action runs
  - **End-to-end PR deploy** for each PM: mike actually runs and pushes `develop/` to a fake `gh-pages` (PR-event jobs only)
  - Unknown `trigger` value fires no deploy step
  - `action.yml` structural sanity (yq)

  Every job uses **[test-helpers/setup-fake-remote](test-helpers/setup-fake-remote/action.yml)** to repoint `origin` at `/tmp/fake-remote.git` before the action runs, so `mike deploy --push` never reaches github.com.

### Releases Table

- **[ci.releases-table.yml](ci.releases-table.yml)**: asserts the README "Latest releases" table still matches the
  git tags, via `scripts/generate-releases-table.sh --check`. Runs on PRs touching the table, on every push to
  `main`, and weekly. Deliberately **not** on tag pushes: the table records the commit a tag resolves to, so the
  tagged commit can never contain its own row and such a run could never be green. Refreshing the table is part of
  the release procedure (see [docs/versioning.md](../../docs/versioning.md)); this check is the backstop.

- **[test.releases-table.unit.yml](test.releases-table.unit.yml)**: unit tests for
  **[scripts/generate-releases-table.sh](scripts/generate-releases-table.sh)**
  - `--check` is green when fresh; `--print` matches the committed block
  - a wrong pinned **SHA** is caught with an actionable diff (tag-independent, so a release cannot make the suite
    red or, worse, silently vacuous)
  - an action with no tags renders `_unreleased_` rather than aborting
  - the registry is **derived** from `docs/versioning.md`, proven by editing it and watching the table follow
  - an action on disk with no registry row fails the run instead of being silently omitted
  - `--write` is idempotent and repairs drift
  - duplicate, inverted, missing, and **indented** markers all exit 2 (the last is a regression test: a marker
    validated as a substring but spliced on an exact line made `--check` a silent no-op)

  Helper assertion scripts under [scripts/](scripts/):
  - `assert-gh-pages-has-version.sh <version>` — confirms mike wrote the named version to fake gh-pages
  - `assert-no-gh-pages-push.sh` — confirms gh-pages still at the seed commit

  Fixtures under [`tests/data/mkdocs-deploy/`](../../tests/data/mkdocs-deploy/):
  - `uv/`, `poetry/`, `pixi/` — pyproject + lockfile per PM with `mike` + `mkdocs` in a docs *group*
  - `_site/mkdocs.yml` + `_site/site_docs/index.md` — minimal mkdocs site (uses `site_docs/` to avoid clobbering the repo's tracked `docs/`)

## Running Tests

### Automatic Tests
Tests run automatically on:
- Push to main branch
- Pull requests

### Manual Tests
```bash
# Run release action unit tests
gh workflow run test-release-action.yml

# Run release action integration test
gh workflow run test-release-integration.yml \
  -f package-manager=uv \
  -f test-version=0.1.0-test.1 \
  -f skip-admin-check=true
```

## Documentation

See [testing-release-action.md](../docs/testing-release-action.md) for detailed information about testing the release action.

