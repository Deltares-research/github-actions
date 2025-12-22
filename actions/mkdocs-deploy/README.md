# MkDocs Deployment Actions

Actions for setting up Python environment and deploying MkDocs documentation to GitHub Pages.

## Available Actions

### setup (`actions/mkdocs-deploy/setup`)
Setup Python environment for documentation building with support for uv, poetry, and pixi.

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy/setup@v1
  with:
    python-version: '3.12'       # Optional, default: '3.12'
    package-manager: 'uv'        # Optional: 'uv', 'poetry', 'pixi'
    dependency-groups: 'docs'    # Optional, default: 'docs'
    poetry-extras: ''            # Optional, for Poetry extras
```

### deploy (`actions/mkdocs-deploy/deploy`)
Deploy MkDocs documentation with mike versioning support.

```yaml
- uses: Deltares-research/github-actions/actions/mkdocs-deploy/deploy@v1
  with:
    package-manager: 'uv'  # uv, poetry, pixi
    deploy-token: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}
    deploy-type: 'main'    # pr, main, release
    release-tag: 'v1.0.0'  # only for release type
```

## Deploy Types

- **pr**: Deploys to `develop` version for pull request previews
- **main**: Deploys to `main` version and sets as default
- **release**: Deploys versioned documentation with release tag

## Complete Workflow Example

Use the reusable workflow for a complete MkDocs deployment solution:

```yaml
name: Deploy Documentation

on:
  push:
    branches: [main]
  pull_request:
  release:
    types: [published]

jobs:
  deploy-docs:
    uses: Deltares-research/github-actions/actions/mkdocs-deploy/workflow.yml@v1
    with:
      package-manager: 'uv'
      dependency-groups: 'docs'
    secrets:
      ACTIONS_DEPLOY_TOKEN: ${{ secrets.ACTIONS_DEPLOY_TOKEN }}
```