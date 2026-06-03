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
| `actions/mkdocs-deploy`        | `mkdocs`         |
| `actions/release/github`       | `github-release` |
| `actions/release/latex-manual` | `latex`          |

### Latest releases

The latest released version of each action and the **full commit SHA** it resolves to. Pin against the
commit SHA (not the tag) when consuming these actions — action-pinning security scanners
(e.g. StepSecurity Harden-Runner, OpenSSF Scorecard) flag floating tags and require an immutable
40-character SHA. The floating major tag is force-pushed to the same commit on each backward-compatible
release.

| Action                         | Latest version          | Commit SHA (pin this)                      |
|--------------------------------|-------------------------|--------------------------------------------|
| `actions/python-setup/pip`     | `pip/v1.0.1`            | `d60c8767cd8efb9c42850eabac6845cbe015d772` |
| `actions/python-setup/uv`      | `uv/v1.0.1`             | `d60c8767cd8efb9c42850eabac6845cbe015d772` |
| `actions/python-setup/poetry`  | `poetry/v1.0.1`         | `d60c8767cd8efb9c42850eabac6845cbe015d772` |
| `actions/python-setup/pixi`    | `pixi/v1.0.1`           | `d60c8767cd8efb9c42850eabac6845cbe015d772` |
| `actions/mkdocs-deploy`        | `mkdocs-deploy/v1.0.1`¹ | `b655376b4a9c0b0b37f7f730f840f11c7220d1a6` |
| `actions/release/github`       | `github-release/v1.1.4` | `73618deb1feaffe481d69063ce7bf229fab6598b` |
| `actions/release/latex-manual` | _unreleased_²           | —                                          |

Pin in a consumer workflow by appending the SHA and keeping the version in a trailing comment:

```yaml
- uses: Deltares-research/github-actions/actions/release/github@73618deb1feaffe481d69063ce7bf229fab6598b # github-release/v1.1.4
```

¹ Published tags use the `mkdocs-deploy/*` prefix, not the `mkdocs` namespace listed in the registry above.
  Pin against `mkdocs-deploy/*` until the namespaces are reconciled.
² No release tags cut yet — consume via `@main` until the first `latex/*` tag is published.

> Legacy duplicate tags from early tagging also exist (`python-setup/<pm>/*`, `release/github/*`). Prefer the
> short namespaces in the table above. To regenerate this table, resolve each namespace's newest
> `vX.Y.Z` tag with `git rev-list -n 1 <tag>`.

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
