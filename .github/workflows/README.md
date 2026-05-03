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
  - `poetry-extras` override (groups skipped when extras set; verified by passing a bogus group)
  - `python-version` pin honored (3.13)
  - `git config` set to `github.actor` after action runs
  - **End-to-end PR deploy** for each PM: mike actually runs and pushes `develop/` to a fake `gh-pages` (PR-event jobs only)
  - Deploy-step gating: workflow_dispatch fires no deploy step
  - `action.yml` structural sanity (yq)

  Every job uses **[test-helpers/setup-fake-remote](test-helpers/setup-fake-remote/action.yml)** to repoint `origin` at `/tmp/fake-remote.git` before the action runs, so `mike deploy --push` never reaches github.com.

  Helper assertion scripts under [scripts/](scripts/):
  - `assert-gh-pages-has-version.sh <version>` — confirms mike wrote the named version to fake gh-pages
  - `assert-no-gh-pages-push.sh` — confirms gh-pages still at the seed commit

  Fixtures under [`tests/data/mkdocs-deploy/`](../../tests/data/mkdocs-deploy/):
  - `uv/`, `poetry/`, `poetry-extras/`, `pixi/` — pyproject + lockfile per PM with `mike` + `mkdocs`
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

