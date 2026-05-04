# MkDocs Deploy Action

Stand-alone composite action that sets up a Python environment and deploys versioned MkDocs documentation to GitHub Pages with [`mike`](https://github.com/jimporter/mike). Supports `uv`, `poetry`, and `pixi`.

Python setup is delegated to the package-manager-specific actions under [`actions/python-setup/`](../python-setup/).

## How it works

After Python setup, three deploy paths are conditionally enabled via the `triggers` input. Each is **also** gated on the matching GitHub event, so the same `triggers` value can safely be reused across all three deploy events without firing unintended pushes.

| Trigger value | Required event       | Resulting `mike` calls                                              |
|---------------|----------------------|---------------------------------------------------------------------|
| `pr`          | `pull_request`       | `mike deploy --push develop`                                        |
| `main`        | `push` to `refs/heads/main` | `mike deploy --push main` then `mike set-default --push main` |
| `release`     | `release`            | `mike deploy --push --update-aliases <release-tag> latest` then `mike set-default --push latest` |

## Inputs

| Name              | Required | Default  | Description |
|-------------------|----------|----------|-------------|
| `python-version`  | no       | `3.12`   | Python version (e.g. `3.12`, `3.13`, `3.12.5`). |
| `package-manager` | no       | `uv`     | One of `uv`, `poetry`, `pixi`. |
| `install-groups`  | no       | `docs`   | PEP 735 dependency groups (uv `--group` / poetry `--with`). Space- or comma-separated. |
| `install-extras`  | no       | `''`     | PEP 621 optional-dependency extras (uv `--extra` / poetry `--extras`). Coexists with `install-groups`. |
| `triggers`        | **yes**  | —        | Comma-separated subset of `pr,main,release`. |
| `deploy-token`    | **yes**  | —        | Token used by `mike` to push to `gh-pages` (needs `contents: write`). |
| `release-tag`     | no       | `''`     | Tag deployed by `mike` when the release path fires; usually `${{ github.event.release.tag_name }}`. |

## Required workflow setup

```yaml
permissions:
  contents: write   # mike needs to push to gh-pages
  pages: write      # only required if you also use the GitHub Pages deploy API

steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0   # mike requires full history to maintain gh-pages
```

Your project must include `mike` and `mkdocs` (and any plugins) in the dependency group/extra named by `install-groups` / `install-extras`. For uv that's a PEP 735 `[dependency-groups]` entry; for poetry, a `[tool.poetry.group.X.dependencies]` block; for pixi, `[pypi-dependencies]`.

## Examples

### 1. Minimum — uv project, deploy on PR + main + release

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
          fetch-depth: 0
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@v1
        with:
          triggers: 'pr,main,release'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}
          release-tag: ${{ github.event.release.tag_name }}
```

### 2. Poetry project with extras

The docs deps live in a poetry extra (`[tool.poetry.extras] docs = [...]`):

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@v1
  with:
    package-manager: 'poetry'
    install-groups: ''            # opt out of the default 'docs' group
    install-extras: 'docs'
    triggers: 'pr,main,release'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    release-tag: ${{ github.event.release.tag_name }}
```

### 3. Pixi project, custom Python version

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@v1
  with:
    package-manager: 'pixi'
    python-version: '3.13'
    triggers: 'main,release'      # skip PR previews
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    release-tag: ${{ github.event.release.tag_name }}
```

### 4. Combining groups and extras (uv or poetry)

Useful when docs deps are split across a PEP 735 group and a PEP 621 extra:

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@v1
  with:
    install-groups: 'docs'
    install-extras: 'mkdocs-plugins'
    triggers: 'pr,main,release'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    release-tag: ${{ github.event.release.tag_name }}
```

### 5. Release deploy only

If you only want to publish on tagged releases:

```yaml
on:
  release:
    types: [published]

jobs:
  deploy-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@v1
        with:
          triggers: 'release'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}
          release-tag: ${{ github.event.release.tag_name }}
```

## Notes

- **First-time setup**: the `gh-pages` branch must exist before the first deploy. `mike` creates it automatically on first push if missing.
- **Custom remote token**: pass a PAT via `deploy-token` if `${{ secrets.GITHUB_TOKEN }}` lacks permission for your branch protection rules.
- **`release-tag` is only used by the release path** — leave empty for `pr`/`main`-only flows.
