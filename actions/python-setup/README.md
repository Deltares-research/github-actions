# Python Setup Actions

Actions for setting up Python environments with different package managers.

## Available Actions

### uv (`actions/python-setup/uv`)
Setup Python with uv package manager.

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/uv@v1
  with:
    python-version: '3.12'
    install-groups: 'dev docs'
    verify-lock: 'true'
```

## Usage Patterns

### For General Development
Use `actions/python-setup/uv` for most development workflows.

### For Documentation
Use `actions/mkdocs-deploy/setup` which supports multiple package managers.

### For Cross-Project Compatibility
Use `actions/python-setup/uv` for general Python setup needs.