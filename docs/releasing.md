# Releasing GitHub Actions

This guide explains how to create and manage releases for the Deltares GitHub Actions repository.

## Release Process Overview

GitHub Actions are versioned using semantic versioning (semver) with Git tags. Users can reference actions by:
- Specific version: `@v1.2.3`
- Major version: `@v1` (automatically points to latest v1.x.x)
- Branch: `@main` (latest development, not recommended for production)

## Step-by-Step Release Process

### 1. Prepare for Release

Before creating a release, ensure:
- All changes are tested and working
- Documentation is updated
- CHANGELOG.md is updated with new features/fixes

### 2. Determine Version Number

Follow semantic versioning:
- **Major** (v2.0.0): Breaking changes that require workflow updates
- **Minor** (v1.1.0): New features, backward compatible
- **Patch** (v1.0.1): Bug fixes, backward compatible

### 3. Create Version Tags

From the repository root directory:

```bash
# Ensure you're on main branch and up to date
git checkout main
git pull origin main

# Create specific version tag
git tag v1.0.0

# Create/update major version tag (points to latest v1.x.x)
git tag -f v1

# Push tags to GitHub
git push origin v1.0.0
git push -f origin v1
```

### 4. Create GitHub Release (Optional)

1. Go to GitHub repository → Releases → "Create a new release"
2. Choose the version tag you just created
3. Add release notes describing changes
4. Publish the release

## Version Management Strategy

### Major Version Tags
- Always maintain major version tags (`v1`, `v2`, etc.)
- These should point to the latest patch release of that major version
- Users reference these for automatic updates: `@v1`

### Example Release Sequence
```bash
# Initial release
git tag v1.0.0
git tag v1
git push origin v1.0.0 v1

# Bug fix release
git tag v1.0.1
git tag -f v1  # Move v1 to point to v1.0.1
git push origin v1.0.1
git push -f origin v1

# New feature release
git tag v1.1.0
git tag -f v1  # Move v1 to point to v1.1.0
git push origin v1.1.0
git push -f origin v1

# Breaking change release
git tag v2.0.0
git tag v2  # Create new major version tag
git push origin v2.0.0 v2
# Note: v1 still points to v1.1.0 for existing users
```

## Testing Releases

### Test with @main First
Before tagging, test your changes using `@main`:
```yaml
- uses: Deltares-research/github-actions/setup-python-uv@main
```

### Test Specific Version
After tagging, test the specific version:
```yaml
- uses: Deltares-research/github-actions/setup-python-uv@v1.0.0
```

### Test Major Version Tag
Verify the major version tag works:
```yaml
- uses: Deltares-research/github-actions/setup-python-uv@v1
```

## Common Commands

### View existing tags
```bash
git tag -l
```

### Delete a tag (local and remote)
```bash
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

### Move a major version tag
```bash
git tag -f v1
git push -f origin v1
```

## Best Practices

1. **Always test before tagging** - Use `@main` for testing
2. **Update CHANGELOG.md** before each release
3. **Use descriptive commit messages** for release commits
4. **Maintain major version tags** for user convenience
5. **Don't delete old version tags** - users may depend on them
6. **Document breaking changes** clearly in release notes

## Automation

Consider adding a workflow to automate the tagging process:

```yaml
# .github/workflows/release.yml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release (e.g., v1.0.0)'
        required: true
        type: string

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create and push tags
        run: |
          VERSION=${{ inputs.version }}
          MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)
          
          git tag $VERSION
          git tag -f $MAJOR_VERSION
          
          git push origin $VERSION
          git push -f origin $MAJOR_VERSION
```

## Troubleshooting

### "Unable to resolve action" error
- Verify the tag exists: `git ls-remote --tags origin`
- Check tag format: should be `v1.0.0`, not `1.0.0`
- Ensure repository is public or properly authenticated

### Users not getting latest version
- Check if major version tag (`v1`) points to latest release
- Use `git tag -f v1` to move the tag if needed

### Breaking changes
- Create new major version (`v2`)
- Don't move existing major version tags
- Document migration path in release notes