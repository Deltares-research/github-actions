# Deltares GitHub Actions

Shared GitHub Actions for Deltares repositories.

Published as `Deltares-research/github-actions`.

## Actions by Topic

### 🐍 Python Setup (`actions/python-setup/`)
Composite actions for setting up Python with the package manager of your choice.

- **`actions/python-setup/pip`** — Setup with pip
- **`actions/python-setup/uv`** — Setup with uv
- **`actions/python-setup/poetry`** — Setup with Poetry
- **`actions/python-setup/pixi`** — Setup with Pixi

[📖 Full Documentation](actions/python-setup/README.md)

### 📚 MkDocs Deployment (`actions/mkdocs-deploy/`)
Stand-alone composite action for deploying MkDocs documentation with `mike` versioning. Supports uv, poetry, pixi.

- **`actions/mkdocs-deploy`** — Setup Python (via `actions/python-setup/<pm>`) and deploy docs in one step

[📖 Full Documentation](actions/mkdocs-deploy/README.md)

### 🏗️ Executable Build (`actions/executable/pyinstaller/`)
Stand-alone composite action that builds a Windows executable with PyInstaller (onedir/onefile or a `.spec` file),
optionally zips it and uploads it as an artifact. Supports uv, poetry, pixi. Windows runners only.

- **`actions/executable/pyinstaller`** — Setup Python (via `actions/python-setup/<pm>`) and build the executable

[📖 Full Documentation](actions/executable/pyinstaller/README.md)

### 📄 LaTeX Documentation (`actions/release/latex-manual/`)
Self-contained pipeline for building Deltares LaTeX/PDF manuals via the [`ddocs`](https://github.com/Deltares-research/doc_utils)
CLI. Installs its own Python + ddocs (pandoc bundled), fetches the Deltares LaTeX styles from the internal
`Deltares/LatexInstallation` repo, optionally converts Markdown to LaTeX, and compiles the PDFs — with the
TeX Live install cached across runs.

- **`actions/release/latex-manual`** — fetch Deltares styles (`ddocs get-tex-template`), optionally convert
  Markdown → LaTeX, install + cache TeX Live, compile PDFs, upload artifacts, and (optionally) attach the PDFs
  to a GitHub release
- Requires a `latex-template-token` (read access to `Deltares/LatexInstallation`); fails fast if it is empty
- Set `markdown-input-dir: ''` to skip conversion for repos that author LaTeX directly; set `tex-files` to the
  documents to compile; set `release-tag` to attach to an existing release (e.g. from a `workflow_run`)

[📖 Full Documentation](actions/release/latex-manual/README.md)

### 🚀 GitHub Release (`actions/release/github/`)
Automated release workflow for Python packages with version bumping, changelog generation, and GitHub release creation.

- **`actions/release/github`** — Permission checks, version bumping, changelog generation, wheel building, GitHub releases

[📖 Full Documentation](actions/release/github/README.md)

## Usage

Each action is versioned independently using **namespaced tags** (`<namespace>/v<MAJOR>.<MINOR>.<PATCH>`). The namespace is short — see [docs/versioning.md](docs/versioning.md) for the full registry. Reference the action path plus the namespaced tag:

```yaml
steps:
  - uses: actions/checkout@v7

  - name: Setup Python with uv
    uses: Deltares-research/github-actions/actions/python-setup/uv@uv/v1.1.1
    with:
      python-version: '3.12'
      install-groups: dev
```

### Namespace registry

| Action                         | Namespace        |
|--------------------------------|------------------|
| `actions/python-setup/pip`     | `pip`            |
| `actions/python-setup/uv`      | `uv`             |
| `actions/python-setup/poetry`  | `poetry`         |
| `actions/python-setup/pixi`    | `pixi`           |
| `actions/mkdocs-deploy`        | `mkdocs-deploy`  |
| `actions/release/github`       | `github-release` |
| `actions/release/latex-manual` | `latex`          |

### Latest releases

The latest released version of each action and the **full commit SHA** it resolves to. Pin against the
commit SHA, or the exact `<namespace>/vX.Y.Z` tag, when consuming these actions — action-pinning security
scanners (e.g. StepSecurity Harden-Runner, OpenSSF Scorecard) flag floating tags and require an immutable
40-character SHA. This repo publishes **immutable tags only** — there are no floating major tags to track.

| Action                         | Latest version          | Commit SHA (pin this)                      |
|--------------------------------|-------------------------|--------------------------------------------|
| `actions/python-setup/pip`     | `pip/v1.1.1`            | `35542e0d629396ac64162d8a5df6110484009147` |
| `actions/python-setup/uv`      | `uv/v1.1.1`             | `35542e0d629396ac64162d8a5df6110484009147` |
| `actions/python-setup/poetry`  | `poetry/v1.1.2`         | `35542e0d629396ac64162d8a5df6110484009147` |
| `actions/python-setup/pixi`    | `pixi/v1.1.1`           | `35542e0d629396ac64162d8a5df6110484009147` |
| `actions/mkdocs-deploy`        | `mkdocs-deploy/v1.1.1`  | `2362f622737db2d19ef48f8bc972a1cb268166b5` |
| `actions/release/github`       | `github-release/v1.2.1` | `2362f622737db2d19ef48f8bc972a1cb268166b5` |
| `actions/release/latex-manual` | `latex/v1.0.2`          | `2362f622737db2d19ef48f8bc972a1cb268166b5` |

Pin in a consumer workflow by appending the SHA and keeping the version in a trailing comment:

```yaml
- uses: Deltares-research/github-actions/actions/release/github@2362f622737db2d19ef48f8bc972a1cb268166b5 # github-release/v1.2.1
```

> Legacy duplicate tags from early tagging also exist (`python-setup/<pm>/*`, `release/github/*`). Prefer the
> short namespaces in the table above. To regenerate this table, resolve each namespace's newest
> `vX.Y.Z` tag with `git rev-list -n 1 <tag>`.

### Reference patterns

| Pattern        | Example          | When to use                                                        |
|----------------|------------------|--------------------------------------------------------------------|
| Pinned version | `@uv/v1.1.0`     | All workflows — the only supported release pin (bump deliberately) |
| Commit SHA     | `@<40-char-sha>` | Strictest supply-chain pinning; what action scanners require       |
| Branch         | `@main`          | Testing unreleased changes only — **not** for production           |

## Versioning

This repository uses **namespaced versioning**: every action has its own independent version tags, so a release of one action never affects the others.

Every tag is an **immutable specific version** — e.g. `uv/v1.1.0` — that points at one commit and is never moved or deleted. This repo publishes **no floating major tags** (`uv/v1`): a floating tag silently changes under consumers, so a pin would not be reproducible — the same reason the `mkdocs-deploy` and `release/github` wrappers pin their internal `python-setup` composition to exact versions. A breaking change cuts a new `uv/v2.0.0` and leaves the older `uv/v1.x.x` tags untouched, so existing consumers keep working until they migrate.

See [docs/versioning.md](docs/versioning.md) for the full guide, including the release process, the automated release workflow, and worked examples.

## Contributing

1. Make changes to the relevant action under `actions/`.
2. Validate by running the test workflows in `.github/workflows/` (e.g. `gh workflow run test.python-setup-uv.unit.yml`).
3. Tag the new version with the action's namespace and push:

   ```bash
   # Immutable version tag on the merged commit
   git tag -a uv/v1.1.0 --no-gpg-sign -m "Release uv v1.1.0"
   git push origin uv/v1.1.0
   ```

4. For a breaking change, cut a new major tag (`uv/v2.0.0`); never move or delete an existing tag.

See [docs/versioning.md](docs/versioning.md) for the complete release procedure.
