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
Complete workflow for generating LaTeX/PDF documentation from Markdown using Deltares styles.

- **`actions/release/latex-manual`** — Setup environment, fetch Deltares styles, convert Markdown to LaTeX, compile PDFs

[📖 Full Documentation](actions/release/latex-manual/README.md)

### 🚀 GitHub Release (`actions/release/github/`)
Automated release workflow for Python packages with version bumping, changelog generation, and GitHub release creation.

- **`actions/release/github`** — Permission checks, version bumping, changelog generation, wheel building, GitHub releases

[📖 Full Documentation](actions/release/github/README.md)

## Usage

Each action is versioned independently using **namespaced tags** (`<action-name>/v<MAJOR>.<MINOR>.<PATCH>`). Reference the action path plus the namespaced tag:

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup Python with uv
    uses: Deltares-research/github-actions/actions/python-setup/uv@python-setup/uv/v1
    with:
      python-version: '3.12'
      install-groups: dev
```

### Reference patterns

| Pattern | Example | When to use |
|---|---|---|
| Floating major | `@python-setup/uv/v1` | CI/CD, everyday workflows — auto-picks up patches and minor releases |
| Pinned specific | `@python-setup/uv/v1.0.0` | Production, compliance, security-critical workflows |
| Branch | `@main` | Testing unreleased changes only — **not** for production |

## Versioning

This repository uses **namespaced versioning**: every action has its own independent version tags, so a release of one action never affects the others.

For each action, two tags are maintained:

- **Specific version** (immutable) — e.g. `python-setup/uv/v1.0.0`. Never moves.
- **Floating major** — e.g. `python-setup/uv/v1`. Force-pushed forward as new backward-compatible releases land within the same major.

A breaking change creates a new major (`python-setup/uv/v2`) and leaves the old major tag where it was, so existing consumers keep working.

See [docs/namespaced-versioning.md](docs/namespaced-versioning.md) for the full guide, including the release process, the automated release workflow, and worked examples.

## Contributing

1. Make changes to the relevant action under `actions/`.
2. Validate by running the test workflows in `.github/workflows/` (e.g. `gh workflow run test.python-setup-uv.unit.yml`).
3. Tag the new version with the action's namespace and push:

   ```bash
   # Specific (immutable) version
   git tag -a python-setup/uv/v1.1.0 -m "Release python-setup/uv v1.1.0"
   git push origin python-setup/uv/v1.1.0

   # Move the floating major tag forward
   git tag -fa python-setup/uv/v1 -m "Update python-setup/uv v1 to v1.1.0"
   git push origin python-setup/uv/v1 --force
   ```

4. For a breaking change, create a **new** major tag instead of moving the old one (`python-setup/uv/v2`).

See [docs/namespaced-versioning.md](docs/namespaced-versioning.md) for the complete release procedure.
