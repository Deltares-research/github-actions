# Python Package Release Action

Automated release workflow for Python packages: bumps the version with [Commitizen](https://commitizen-tools.github.io/commitizen/), regenerates the changelog, commits and tags, optionally builds a wheel, and creates a GitHub Release.

## Features

- ✅ **Multi-package-manager support**: `uv`, `poetry`, `pixi`
- ✅ **Conventional-commit driven**: pick an increment (`patch`/`minor`/`major`); Commitizen computes the next version
- ✅ **Prereleases**: optional `alpha` / `beta` / `rc` tags, and draft releases
- ✅ **Resilient to legacy/messy tag history**: if Commitizen can't anchor an incremental changelog on an existing tag, the action regenerates the changelog from git history and retries (see [Tag history & changelog](#tag-history--changelog))
- ✅ **Admin gate**: only repository admins can trigger a release
- ✅ **Monorepo aware**: point `config-file` at a package's `pyproject.toml`
- ✅ **Optional wheel build** attached to the release

## Usage

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      increment:
        description: "Version increment"
        required: true
        type: choice
        options: [patch, minor, major]
      prerelease-type:
        description: "Prerelease type (none for a standard release)"
        required: false
        default: "none"
        type: choice
        options: [none, alpha, beta, rc]
      draft:
        description: "Create the GitHub release as a draft"
        required: false
        default: "false"
        type: choice
        options: ["false", "true"]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # full history + tags are required

      - name: Release
        uses: Deltares-research/github-actions/actions/release/github@github-release/v1
        with:
          increment: ${{ inputs.increment }}
          prerelease-type: ${{ inputs.prerelease-type }}
          draft: ${{ inputs.draft }}
          package-manager: poetry          # or uv / pixi
          python-version: '3.11'
          install-groups: 'dev docs'
          build-wheel: 'true'
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Pixi

```yaml
- uses: Deltares-research/github-actions/actions/release/github@github-release/v1
  with:
    increment: minor
    package-manager: pixi
    pixi-environments: 'default dev'
    pixi-activate-environment: 'dev'
    build-wheel: 'false'
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Monorepo (package with its own `pyproject.toml`)

```yaml
- uses: Deltares-research/github-actions/actions/release/github@github-release/v1
  with:
    increment: patch
    config-file: packages/my-package/pyproject.toml
    package-manager: uv
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

Commitizen and the lock-file update run from the directory containing `config-file`.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `increment` | Version increment: `patch`, `minor`, or `major`. | **Yes** | — |
| `github-token` | Token for the permission check, pushes, and the GitHub Release. | **Yes** | — |
| `release-branch` | Branch to release from (used in messages/summary; check out this ref yourself). | No | `main` |
| `prerelease-type` | `none`, `alpha`, `beta`, or `rc` (forwarded to `cz bump --prerelease`). | No | `none` |
| `draft` | Create the GitHub release as a draft (`true`/`false`). | No | `false` |
| `config-file` | Path to a Commitizen config (`pyproject.toml`) for monorepos. Empty = repo root. | No | `''` |
| `python-version` | Python version to install. | No | `3.12` |
| `package-manager` | `uv`, `poetry`, or `pixi`. | No | `uv` |
| `install-groups` | Dependency groups to install (uv/poetry only; space- or comma-separated). | No | `dev docs` |
| `pixi-environments` | Pixi environments to install (pixi only; passed to `setup-pixi`). | No | `''` |
| `pixi-activate-environment` | Pixi environment to put on `PATH` (pixi only; must also be in `pixi-environments`). | No | `''` |
| `verify-lock` | Verify the lock file is up to date before installing. | No | `true` |
| `build-wheel` | Build a wheel and attach it to the release. | No | `true` |
| `skip-github-release` | **Testing only.** Bump + tag + push but skip the GitHub Releases API call. | No | `false` |

## What this action does

1. **Permission check** — calls `GET /repos/{repo}/collaborators/{actor}/permission`; the actor must have `admin`.
2. **Environment setup** — installs Python and dependencies via the chosen package manager (delegates to `actions/python-setup/<pm>`).
3. **Configure git** — sets `user.name` / `user.email` to the triggering actor.
4. **Validate changelog** — confirms the `changelog_file` from `[tool.commitizen]` (or `CHANGELOG.md`) exists.
5. **Compute the next version** — from the current version + `increment` (+ `prerelease-type`), via `cz bump`. Robust to a messy tag history (see below).
6. **Bump & changelog** — `cz bump` updates the version files, regenerates the changelog, commits, and tags. If the incremental changelog can't be anchored on an existing tag, the action regenerates the whole changelog from git history and retries (see below).
7. **Update the lock file** — `uv lock` / `poetry lock` / `pixi install`, committed if it changed.
8. **Push** — commits and tags pushed to the repository.
9. **Build wheel** — optional (`build-wheel`).
10. **GitHub Release** — created via `softprops/action-gh-release` with the changelog section as the body, the wheel attached (if built), and `draft` / prerelease flags applied. Skipped when `skip-github-release: true`.

## Requirements

### Commitizen configuration

The consumer repo must configure Commitizen in `pyproject.toml`, and Commitizen must be installed via one of the `install-groups` (uv/poetry) or the pixi manifest. A typical block:

```toml
[tool.commitizen]
name = "cz_conventional_commits"
version_provider = "pep621"          # or "poetry" / "uv" — match your build backend
tag_format = "$version"              # MUST match how your existing tags are named
changelog_file = "CHANGELOG.md"
update_changelog_on_bump = true
version_scheme = "pep440"
```

The two settings that have to be right:

- **`tag_format`** must match your real git tags. If your tags look like `v1.2.3`, use `tag_format = "v$version"`; if they're `1.2.3`, use `"$version"`. Tags that don't match are skipped (with a warning) — they don't break the release, but they won't show up in the changelog either.
- **`changelog_file`** must exist and (for the smooth path) its newest `## X.Y.Z` heading should correspond to a real tag. See below.

### Other

- `contents: write` permission on the job, and `fetch-depth: 0` on the checkout (full history and tags are needed).
- `jq` (available on GitHub-hosted runners).
- `uv` needs `uv.lock`; `poetry` needs `poetry.lock` + `pyproject.toml`; `pixi` needs `pixi.lock` + `pixi.toml`.

## Tag history & changelog

`cz bump`'s changelog step is **always incremental**: it reads the changelog file, takes its newest `## X.Y.Z` heading, and tries to find a git tag (matching `tag_format`) whose version matches it, so it knows which commits are "new". On a repo with a clean history that always works.

On a repo with a **messy or legacy tag history** — tags created by hand, tags that don't match `tag_format` (e.g. `v2.0.0` when `tag_format = "$version"`, or a PEP 440 post-release like `2.3.1.post1`), or a changelog whose newest version was never tagged — that anchor can't be found and `cz bump` exits with *"No tag found to do an incremental changelog"*.

This action recovers automatically: it regenerates the **whole changelog from git history** (which needs no anchor — unparsable tags are simply skipped) and retries the bump, which then anchors on the latest real tag, commits, and tags. **Note:** on a repo's first release through this action, this means a hand-written changelog may be replaced by generated entries; the action emits a `::warning::` when it does this. Subsequent releases stay on the fast (incremental) path.

To avoid the regen entirely on a legacy repo, do one of the following once:

- Run `cz changelog` (e.g. `uv run cz changelog`) locally, commit the regenerated changelog, and push — so its newest heading matches your latest real tag.
- Or make the newest `## X.Y.Z` heading in the changelog match an existing tag (e.g. add a heading for your latest released version).
- Or rename/remove tags that don't match `tag_format` (don't delete tags consumers may pin to).

And going forward: cut releases **only** through this action (or `cz bump`) — don't create release tags by hand — and the history stays clean.

## Testing

This action is exercised by the workflows in [`.github/workflows/`](../../../.github/workflows/):

- `test.release.unit.yml` — pure-bash unit tests for the helper scripts under `scripts/` (`is-prerelease.sh`, `next-version.sh`).
- `test.release.integration.yml` — end-to-end runs against a fake git remote for `uv`/`poetry`/`pixi`, prereleases, and the messy-tag-history recovery path.
