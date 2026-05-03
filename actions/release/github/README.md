# Python Release Action

Complete automated release workflow for Python packages with version bumping, changelog generation, and GitHub release creation.

## Features

- ✅ **Multi-package manager support**: uv, poetry, pixi
- ✅ **Permission checking**: Optional admin permission validation
- ✅ **Flexible versioning**: Manual version input or major.minor.patch construction
- ✅ **Automated changelog**: Uses Commitizen for changelog generation
- ✅ **Git integration**: Automatic commits, tags, and pushes
- ✅ **Wheel building**: Optional Python wheel creation
- ✅ **GitHub releases**: Automated release creation with optional artifacts

## Usage

### Basic Usage

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Version to release (e.g. 1.2.3)"
        required: true
        type: string

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: Create Release
        uses: Deltares-research/github-actions/actions/python-release@v1
        with:
          version: ${{ github.event.inputs.version }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Advanced Usage with All Options

```yaml
name: Automated Release

on:
  workflow_dispatch:
    inputs:
      release_branch:
        description: "Branch to create release from"
        required: false
        default: "main"
      version:
        description: "Full version to release (e.g. 1.0.0 or 1.0.0-beta.1)"
        required: false
        type: string
      major:
        description: "The new major version"
        required: false
        type: string
      minor:
        description: "The new minor version" 
        required: false
        type: string
      patch:
        description: "The new patch version"
        required: false
        type: string

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: ${{ github.event.inputs.release_branch || 'main' }}
          
      - name: Create Release
        uses: Deltares-research/github-actions/actions/python-release@v1
        with:
          release-branch: ${{ github.event.inputs.release_branch || 'main' }}
          version: ${{ github.event.inputs.version }}
          major: ${{ github.event.inputs.major }}
          minor: ${{ github.event.inputs.minor }}
          patch: ${{ github.event.inputs.patch }}
          python-version: '3.12'
          package-manager: 'uv'
          dependency-groups: 'dev docs'
          github-token: ${{ secrets.GITHUB_TOKEN }}
          check-admin-permissions: 'true'
          build-wheel: 'true'
```

### Poetry Example

```yaml
- name: Create Release with Poetry
  uses: Deltares-research/github-actions/actions/python-release@v1
  with:
    version: "1.2.3"
    package-manager: 'poetry'
    poetry-extras: 'dev,docs'
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Pixi Example

```yaml
- name: Create Release with Pixi
  uses: Deltares-research/github-actions/actions/python-release@v1
  with:
    version: "1.2.3"
    package-manager: 'pixi'
    dependency-groups: 'dev docs'
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `release-branch` | Branch to create release from | No | `main` |
| `major` | The new major version | No | `''` |
| `minor` | The new minor version | No | `''` |
| `patch` | The new patch version | No | `''` |
| `increment` | The type of increment (MAJOR, MINOR, PATCH) | No | `''` |
| `version` | Full version to release (e.g. 1.0.0 or 1.0.0-beta.1) | No | `''` |
| `python-version` | Python version to install | No | `3.12` |
| `package-manager` | Package manager (uv, poetry, pixi) | No | `uv` |
| `dependency-groups` | Dependency groups to install | No | `dev docs` |
| `poetry-extras` | Poetry extras to install (e.g., "dev,docs") | No | `''` |
| `github-token` | GitHub token for API calls and releases | Yes | - |
| `check-admin-permissions` | Whether to check if user has admin permissions | No | `true` |
| `build-wheel` | Whether to build and include wheel in release | No | `true` |

## Version Specification

You can specify the version in two ways:

1. **Manual version**: Use the `version` input to specify the complete version (e.g., "1.2.3", "2.0.0-beta.1")
2. **Component version**: Use `major`, `minor`, and `patch` inputs to construct the version

If both are provided, `version` takes precedence.

## Requirements

### Dependencies
- Requires [Commitizen](https://commitizen-tools.github.io/commitizen/) for changelog generation and version bumping
- Requires `jq` for JSON parsing (available on GitHub runners)

### Permissions
- The workflow needs `contents: write` permission for creating releases and pushing changes
- If `check-admin-permissions` is enabled, the user triggering the workflow must have admin permissions

### Package Manager Setup
- **uv**: Requires `uv.lock` file
- **poetry**: Requires `poetry.lock` and `pyproject.toml` with Poetry configuration
- **pixi**: Requires `pixi.lock` and `pixi.toml` files

## What This Action Does

1. **Permission Check**: Verifies user has admin permissions (optional)
2. **Version Determination**: Resolves the target version from inputs
3. **Environment Setup**: Installs Python and dependencies using specified package manager
4. **Changelog Generation**: Updates CHANGELOG.md using Commitizen
5. **Git Configuration**: Sets up Git with user information from GitHub API
6. **Version Bump**: Updates version in project files and commits changes
7. **Tag & Push**: Creates git tag and pushes changes to repository
8. **Build Package**: Creates Python wheel (optional)
9. **GitHub Release**: Creates GitHub release with generated notes and artifacts

## Examples

See the [examples directory](../../examples/) for complete workflow examples.