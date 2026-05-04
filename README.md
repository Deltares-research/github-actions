# Deltares GitHub Actions

Shared GitHub Actions for Deltares repositories.

## Actions by Topic

### 🐍 Python Setup (`actions/python-setup/`)
Actions for setting up Python environments for general development.

- **`actions/python-setup/uv`** - Setup with uv package manager

[📖 Full Documentation](actions/python-setup/README.md)

### 📚 MkDocs Deployment (`actions/mkdocs-deploy/`)
Stand-alone composite action for deploying MkDocs documentation with `mike` versioning. Supports uv, poetry, pixi.

- **`actions/mkdocs-deploy`** - Setup Python (via `actions/python-setup/<pm>`) and deploy docs in one step

[📖 Full Documentation](actions/mkdocs-deploy/README.md)

### 📄 LaTeX Documentation (`actions/release/latex-manual/`)
Complete workflow for generating LaTeX/PDF documentation from Markdown using Deltares styles.

- **`actions/release/latex-manual`** - Setup environment, fetch Deltares styles, convert Markdown to LaTeX, compile PDFs

[📖 Full Documentation](actions/release/latex-manual/README.md)

### 🚀 GitHub Release (`actions/release/github/`)
Complete automated release workflow for Python packages with version bumping, changelog generation, and GitHub release creation.

- **`actions/release/github`** - Permission checks, version bumping, changelog generation, wheel building, GitHub releases

[📖 Full Documentation](actions/release/github/README.md)

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