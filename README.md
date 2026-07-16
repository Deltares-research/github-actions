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
  - uses: actions/checkout@v4

  - name: Setup Python with uv
    uses: Deltares-research/github-actions/actions/python-setup/uv@uv/v1
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
commit SHA (not the tag) when consuming these actions — action-pinning security scanners
(e.g. StepSecurity Harden-Runner, OpenSSF Scorecard) flag floating tags and require an immutable
40-character SHA. The floating major tag is force-pushed to the same commit on each backward-compatible
release.

<!-- BEGIN GENERATED: latest-releases -->
| Action                         | Latest version          | Commit SHA (pin this)                      |
|--------------------------------|-------------------------|--------------------------------------------|
| `actions/python-setup/pip`     | `pip/v1.1.0`            | `0d76ad54ebc4c8bde82105ac863de1ec841544f1` |
| `actions/python-setup/uv`      | `uv/v1.1.0`             | `0d76ad54ebc4c8bde82105ac863de1ec841544f1` |
| `actions/python-setup/poetry`  | `poetry/v1.1.0`         | `0d76ad54ebc4c8bde82105ac863de1ec841544f1` |
| `actions/python-setup/pixi`    | `pixi/v1.1.0`           | `0d76ad54ebc4c8bde82105ac863de1ec841544f1` |
| `actions/mkdocs-deploy`        | `mkdocs-deploy/v1.1.0`  | `e40b79ba9ee2e6d8d16dde4610f02c3a5af9de5a` |
| `actions/release/github`       | `github-release/v1.2.0` | `e40b79ba9ee2e6d8d16dde4610f02c3a5af9de5a` |
| `actions/release/latex-manual` | `latex/v1.0.1`          | `e40b79ba9ee2e6d8d16dde4610f02c3a5af9de5a` |
<!-- END GENERATED: latest-releases -->

<!-- Regenerate this table with: .github/workflows/scripts/generate-releases-table.sh --write -->
<!-- CI checks it with: .github/workflows/scripts/generate-releases-table.sh --check -->

Pin in a consumer workflow by appending the SHA and keeping the version in a trailing comment:

```yaml
- uses: Deltares-research/github-actions/actions/release/github@e40b79ba9ee2e6d8d16dde4610f02c3a5af9de5a # github-release/v1.2.0
```

> Legacy duplicate tags from early tagging also exist (`python-setup/<pm>/*`, `release/github/*`). Prefer the
> namespaces in the table above.

### Reference patterns

| Pattern         | Example      | When to use                                                          |
|-----------------|--------------|----------------------------------------------------------------------|
| Floating major  | `@uv/v1`     | CI/CD, everyday workflows — auto-picks up patches and minor releases |
| Pinned specific | `@uv/v1.0.0` | Production, compliance, security-critical workflows                  |
| Branch          | `@main`      | Testing unreleased changes only — **not** for production             |

## Versioning

This repository uses **namespaced versioning**: every action has its own independent version tags, so a release of one action never affects the others.

For each action, two tags are maintained:

- **Specific version** (immutable) — e.g. `uv/v1.0.0`. Never moves.
- **Floating major** — e.g. `uv/v1`. Force-pushed forward as new backward-compatible releases land within the same major.

A breaking change creates a new major (`uv/v2`) and leaves the old major tag where it was, so existing consumers keep working.

See [docs/versioning.md](docs/versioning.md) for the full guide, including the release process, the automated release workflow, and worked examples.

## Contributing

1. Make changes to the relevant action under `actions/`.
2. Validate by running the test workflows in `.github/workflows/` (e.g. `gh workflow run test.python-setup-uv.unit.yml`).
3. Tag the new version with the action's namespace and push:

   ```bash
   # Specific (immutable) version
   git tag -a uv/v1.1.0 -m "Release uv v1.1.0"
   git push origin uv/v1.1.0

   # Move the floating major tag forward
   git tag -fa uv/v1 -m "Update uv v1 to v1.1.0"
   git push origin uv/v1 --force
   ```

4. For a breaking change, create a **new** major tag instead of moving the old one (`uv/v2`).

See [docs/versioning.md](docs/versioning.md) for the complete release procedure.
