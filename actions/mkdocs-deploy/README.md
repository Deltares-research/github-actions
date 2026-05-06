# MkDocs Deploy Action

Stand-alone composite action that sets up a Python environment and deploys versioned MkDocs documentation to GitHub Pages with [`mike`](https://github.com/jimporter/mike). Supports `uv`, `poetry`, and `pixi`.

Python setup is delegated to the package-manager-specific actions under [`actions/python-setup/`](../python-setup/).

## How it works

Each invocation runs **exactly one** deploy path, selected by `trigger`. The action does **not** check `github.event_name` itself — the caller is responsible for matching event ↔ trigger via a job-level `if:`.

| `trigger` value | Resulting `mike` calls |
|---|---|
| `pr`      | `mike deploy --push develop` |
| `main`    | `mike deploy --push main` (+ `mike set-default --push main`, unless `main-set-default=false`) |
| `release` (stable, `release-prerelease=false`) | `mike deploy --push --update-aliases <release-tag> <release-alias>` then `mike set-default --push <release-alias>` |
| `release` (prerelease, `release-prerelease=true`) | `mike deploy --push <release-tag>` (no alias, no set-default — does not displace the served default) |

## Inputs

| Name              | Required | Default  | Description |
|-------------------|----------|----------|-------------|
| `python-version`  | no       | `3.12`   | Python version (e.g. `3.12`, `3.13`, `3.12.5`). |
| `package-manager` | no       | `uv`     | One of `uv`, `poetry`, `pixi`. |
| `install-groups`  | no       | `docs`   | PEP 735 dependency groups to install (uv `--group` / poetry `--with`). Space- or comma-separated. |
| `trigger`         | **yes**  | —        | Which deploy path to run. One of `pr`, `main`, `release`. |
| `deploy-token`    | **yes**  | —        | Token used by `mike` to push to `gh-pages` (needs `contents: write`). |
| `release-tag`     | no       | `''`     | Tag deployed by `mike` when `trigger=release`; usually `${{ github.event.release.tag_name }}`. |
| `release-alias`   | no       | `latest` | Mike alias the release version is published under and set as default. Common alternatives: `stable`. |
| `main-set-default`    | no   | `true`   | Whether the main deploy path also runs `mike set-default --push main`. Set to `false` for libraries that publish stable releases and want the released alias (not main) to remain the served default. |
| `release-prerelease`  | no   | `false`  | Whether the release being deployed is a prerelease (alpha/beta/rc). When `true`, mike publishes the tag alone — no `--update-aliases` and no `set-default`. Typically `${{ github.event.release.prerelease }}`. |

### Why no `install-extras`?

Doc-builder deps (`mike`, `mkdocs`, plugins) are CI-only — end users of your wheel never need them. Putting them in PEP 621 `[project.optional-dependencies]` (extras) leaks `Provides-Extra: docs` into the published wheel metadata, which is wrong for internal-only deps. Use a PEP 735 dependency group (or `[tool.poetry.group.docs.dependencies]` for poetry) instead — those never reach the wheel.

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

Your project must declare `mike` and `mkdocs` (and any plugins) in:
- **uv**: `[dependency-groups] docs = ["mike", "mkdocs"]`
- **poetry**: `[tool.poetry.group.docs.dependencies] mike = "*"; mkdocs = "*"`
- **pixi**: `[pypi-dependencies] mike = "*"; mkdocs = "*"` (pixi installs PEP 621 + pypi deps from a single `pixi.toml`)

## Examples

### 1. All three paths in one workflow

Three jobs — one per deploy path — each gated on the right event:

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
  deploy-pr:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
        with:
          trigger: 'pr'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}

  deploy-main:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
        with:
          trigger: 'main'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}

  deploy-release:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
        with:
          trigger: 'release'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}
          release-tag: ${{ github.event.release.tag_name }}
          release-prerelease: ${{ github.event.release.prerelease }}
```

### 2. Poetry project, custom python and group name

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
  with:
    package-manager: 'poetry'
    python-version: '3.13'
    install-groups: 'documentation'   # group name in your pyproject.toml
    trigger: 'main'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Pixi project

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
  with:
    package-manager: 'pixi'
    trigger: 'main'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
```

### 4. Release-only deploy

```yaml
on:
  release:
    types: [published]

jobs:
  deploy-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
        with:
          trigger: 'release'
          deploy-token: ${{ secrets.GITHUB_TOKEN }}
          release-tag: ${{ github.event.release.tag_name }}
```

### 5. Custom release alias (`stable` instead of `latest`)

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
  with:
    trigger: 'release'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    release-tag: ${{ github.event.release.tag_name }}
    release-alias: 'stable'
```

### 6. Prerelease handling (alpha/beta/rc don't displace `latest`)

Wire `release-prerelease` straight from the GitHub release event payload — when the release is marked prerelease in the GitHub UI, mike publishes the tag standalone without aliasing it to `latest` or making it default:

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
  with:
    trigger: 'release'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    release-tag: ${{ github.event.release.tag_name }}
    release-prerelease: ${{ github.event.release.prerelease }}
```

### 7. Keep release alias as the served default (don't promote main)

For libraries: pushes to main get a `main/` version on gh-pages, but the served default stays at the stable release alias.

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy@mkdocs/v1
  with:
    trigger: 'main'
    deploy-token: ${{ secrets.GITHUB_TOKEN }}
    main-set-default: 'false'
```

## Notes

- **First-time setup**: the `gh-pages` branch must exist before the first deploy. `mike` creates it automatically on first push if missing.
- **Custom remote token**: pass a PAT via `deploy-token` if `${{ secrets.GITHUB_TOKEN }}` lacks permission for your branch protection rules.
- **`release-tag`, `release-alias`, `release-prerelease`** are only consulted on `trigger=release`.
- **`main-set-default`** is only consulted on `trigger=main`.
