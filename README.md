# Deltares GitHub Actions

Shared GitHub Actions for Deltares repositories.

## Actions by Topic

### 🐍 Python Setup (`actions/python-setup/`)
Actions for setting up Python environments for general development.

- **`actions/python-setup/uv`** - Setup with uv package manager

[📖 Full Documentation](actions/python-setup/README.md)

### 📚 MkDocs Deployment (`actions/mkdocs-deploy/`)
Complete workflow actions for MkDocs documentation - from setup to deployment.

- **`actions/mkdocs-deploy/setup`** - Universal Python setup supporting uv, poetry, pixi
- **`actions/mkdocs-deploy/deploy`** - Deploy with mike versioning support

[📖 Full Documentation](actions/mkdocs-deploy/README.md)

### 📄 LaTeX Documentation (`actions/latex-docs/`)
Complete workflow for generating LaTeX/PDF documentation from Markdown using Deltares styles.

- **`actions/latex-docs`** - Setup environment, fetch Deltares styles, convert Markdown to LaTeX, compile PDFs

[📖 Full Documentation](actions/latex-docs/README.md)

### 🚀 Python Release (`actions/python-release/`)
Complete automated release workflow for Python packages with version bumping, changelog generation, and GitHub release creation.

- **`actions/python-release`** - Permission checks, version bumping, changelog generation, wheel building, GitHub releases

[📖 Full Documentation](actions/python-release/README.md)

## Reusable Workflows

### MkDocs Deployment Workflow

Complete workflow for deploying MkDocs documentation with support for multiple package managers.

**Note**: Reusable workflows must be in `.github/workflows/` due to GitHub requirements.

```yaml
# .github/workflows/docs.yml
name: Deploy Documentation

on:
  push:
    branches: [main]
  pull_request:
    branches: ['**']
  release:
    types: [published]

jobs:
  deploy-docs:
    uses: Deltares-research/github-actions/.github/workflows/deploy-mkdocs.yml@v1
    with:
      python-version: '3.12'
      package-manager: 'uv'       # or 'poetry', 'pixi'
      dependency-groups: 'docs'
      # poetry-extras: 'docs,dev'  # Only for Poetry
    secrets:
      ACTIONS_DEPLOY_TOKEN: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}
```

## Usage

To use these actions in your workflows:

```yaml
steps:
  - uses: actions/checkout@v4
  - name: Setup Python Environment
    uses: deltares/github-actions/setup-python-uv@v1
    with:
      python-version: '3.12'
      install-groups: dev
```

## Versioning

Actions are versioned using semantic versioning. Use:
- `@v1` for latest v1.x.x (recommended)
- `@v1.2.3` for specific version
- `@main` for latest development (not recommended for production)

## Contributing

1. Make changes to actions
2. Test thoroughly
3. Tag new versions: `git tag v1.x.x && git push origin v1.x.x`
4. Update major version tag: `git tag -f v1 && git push -f origin v1`