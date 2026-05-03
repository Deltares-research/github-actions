# MkDocs Deployment Action

Stand-alone composite action that sets up Python and deploys MkDocs documentation to GitHub Pages with [`mike`](https://github.com/jimporter/mike) versioning. Supports `uv`, `poetry`, and `pixi`.

Python setup is delegated to the package-manager-specific actions under `actions/python-setup/`.

## Usage

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy/complete@v1
  with:
    python-version: '3.12'        # Optional, default: '3.12'
    package-manager: 'uv'         # Optional: 'uv', 'poetry', 'pixi' (default 'uv')
    dependency-groups: 'docs'     # Optional, default: 'docs' (uv --group / poetry --with)
    poetry-extras: ''             # Optional, Poetry --extras (when set, dependency-groups is ignored for poetry)
    deploy-types: 'main'          # Required: 'pr', 'main', 'release', or comma-separated
    deploy-token: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}  # Required
    release-tag: 'v1.0.0'         # Optional, required for release type
```

The action's deploy steps are gated on both `deploy-types` AND the triggering event:
- `pr` runs only on `pull_request`
- `main` runs only on `push` to `refs/heads/main`
- `release` runs only on `release`

## Deploy Types

- **pr** — Deploys to the `develop` version (PR previews).
- **main** — Deploys the `main` version and sets it as default.
- **release** — Deploys `<release-tag>` aliased to `latest`, and sets `latest` as default.

## Complete Workflow Example

```yaml
name: Deploy Documentation

on:
  push:
    branches: [main]
  pull_request:
  release:
    types: [published]

permissions:
  contents: write
  pages: write

jobs:
  deploy-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # mike needs full history to push to gh-pages

      - uses: Deltares-research/github-actions/actions/mkdocs-deploy/complete@v1
        with:
          package-manager: 'uv'
          dependency-groups: 'docs'
          deploy-types: 'pr,main,release'
          deploy-token: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}
          release-tag: ${{ github.event.release.tag_name }}
```
