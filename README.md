# Deltares GitHub Actions

Shared GitHub Actions for Deltares repositories.

## Available Actions

### setup-python-uv

Sets up Python with uv package manager and installs dependencies.

```yaml
- name: Setup Python with uv
  uses: deltares/github-actions/setup-python-uv@v1
  with:
    python-version: '3.12'        # Optional, default: '3.12'
    install-groups: 'dev docs'    # Optional, default: 'dev'
    verify-lock: 'true'          # Optional, default: 'true'
```

### setup-python-docs

Sets up Python environment for documentation building with support for multiple package managers.

```yaml
- name: Setup Python for Documentation
  uses: deltares/github-actions/setup-python-docs@v1
  with:
    python-version: '3.12'       # Optional, default: '3.12'
    package-manager: 'uv'        # Optional: 'uv', 'poetry', 'pixi'
    dependency-groups: 'docs'    # Optional, default: 'docs'
    poetry-extras: ''            # Optional, for Poetry extras
```

### deploy-mkdocs

Deploys MkDocs documentation to GitHub Pages using mike for versioning.

```yaml
- name: Deploy Documentation
  uses: deltares/github-actions/deploy-mkdocs@v1
  with:
    package-manager: 'uv'        # Required: 'uv', 'poetry', 'pixi'
    deploy-token: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}
    deploy-type: 'main'          # Required: 'pr', 'main', 'release'
    release-tag: 'v1.0.0'       # Optional, required for release type
```

## Reusable Workflows

### MkDocs Deployment Workflow

Complete workflow for deploying MkDocs documentation with support for multiple package managers.

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
    uses: Deltares-research/github-actions/.github/workflows/reusable-mkdocs-deploy.yml@v1
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