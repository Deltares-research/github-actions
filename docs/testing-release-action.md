# Testing the Release Action

This document describes the test workflows created for the `release` composite action.

## Test Workflows

### 1. `test.release.unit.yml` - Comprehensive Unit Tests

This workflow runs automatically on push and pull requests. It tests various components of the release action in isolation.

**Test Jobs:**

- **test-release-uv**: Tests the release process with the `uv` package manager
  - Creates a minimal Python project with uv
  - Verifies project setup and configuration
  - Tests version determination logic

- **test-release-poetry**: Tests the release process with the `poetry` package manager
  - Creates a Poetry-based Python project
  - Verifies Poetry installation and configuration
  - Tests lock file generation

- **test-release-pixi**: Tests the release process with the `pixi` package manager
  - Creates a Pixi-based Python project
  - Verifies Pixi installation and configuration
  - Tests environment setup

- **test-version-inputs**: Tests version input scenarios
  - Full version input (e.g., `1.2.3`)
  - Constructed version from major, minor, patch
  - Prerelease version detection (beta, alpha, rc)
  - Version with 'b' character detection

- **test-permission-check**: Tests the admin permission check logic
  - Verifies GitHub API permission check
  - Tests user permission retrieval

- **test-user-info**: Tests user information retrieval
  - Verifies GitHub API user info retrieval
  - Tests user name and email extraction

- **test-action-structure**: Validates the action.yml file
  - Checks YAML syntax
  - Verifies required fields (name, description, runs.using)
  - Lists all defined inputs

- **summary**: Generates a test summary with results from all test jobs

**Triggers:**
- Push to `main` or `test-release` branches
- Pull requests
- Manual dispatch with test scenario selection

**Manual Execution:**
```bash
# Run all tests
gh workflow run test.release.unit.yml

# Run specific package manager test
gh workflow run test.release.unit.yml -f test-scenario=uv
gh workflow run test.release.unit.yml -f test-scenario=poetry
gh workflow run test.release.unit.yml -f test-scenario=pixi
```

### 2. `test.release.integration.yml` - Integration Tests

This workflow performs end-to-end integration testing by actually calling the release action. It's designed for manual execution only.

**Features:**
- Creates a test branch to avoid polluting main
- Sets up a complete test project with the chosen package manager
- Calls the actual release action
- Verifies the release was successful:
  - Tag creation
  - Version update in `pyproject.toml`
  - CHANGELOG update
  - Wheel build (if enabled)
- Cleans up test branch and tag after completion

**Inputs:**
- `package-manager`: Choose between `uv`, `poetry`, or `pixi`
- `test-version`: Version to test with (e.g., `0.1.0-test.1`)
- `skip-admin-check`: Skip admin permission check for testing (default: true)
- `build-wheel`: Test wheel building (default: true)

**Manual Execution:**
```bash
# Test with uv
gh workflow run test.release.integration.yml \
  -f package-manager=uv \
  -f test-version=0.1.0-test.1 \
  -f skip-admin-check=true \
  -f build-wheel=true

# Test with poetry
gh workflow run test.release.integration.yml \
  -f package-manager=poetry \
  -f test-version=0.1.0-test.2 \
  -f skip-admin-check=true \
  -f build-wheel=true

# Test with pixi
gh workflow run test.release.integration.yml \
  -f package-manager=pixi \
  -f test-version=0.1.0-test.3 \
  -f skip-admin-check=true \
  -f build-wheel=false
```

## Test Coverage

The test workflows cover the following aspects of the release action:

### Inputs
- ✅ `release-branch`: Tested in integration workflow
- ✅ `major`, `minor`, `patch`: Tested in version-inputs job
- ✅ `increment`: Logic tested (not directly used in current implementation)
- ✅ `version`: Tested with various formats
- ✅ `python-version`: Tested with matrix strategy (3.12, 3.13)
- ✅ `package-manager`: All three options tested (uv, poetry, pixi)
- ✅ `dependency-groups`: Tested in all package manager scenarios
- ✅ `poetry-extras`: Tested in poetry scenario
- ✅ `github-token`: Used in all integration tests
- ✅ `check-admin-permissions`: Tested with skip option
- ✅ `build-wheel`: Tested with enable/disable

### Functionality
- ✅ Permission check logic
- ✅ Version determination
- ✅ Python environment setup (all package managers)
- ✅ Changelog generation (integration test)
- ✅ User info retrieval
- ✅ Git configuration
- ✅ Version bumping (integration test)
- ✅ Lock file updates (integration test)
- ✅ Wheel building (integration test)
- ✅ GitHub release creation (integration test)
- ✅ Prerelease detection

### Edge Cases
- ✅ Prerelease versions (beta, alpha, rc)
- ✅ Version with 'b' character
- ✅ Missing user info
- ✅ Lock file commit failures
- ✅ Git push failures

## Running Tests Locally

### Prerequisites
- GitHub CLI (`gh`) installed and authenticated
- Access to the repository

### Run All Unit Tests
```bash
# Push to trigger automatic tests
git push origin main

# Or manually trigger
gh workflow run test.release.unit.yml
```

### Run Integration Test
```bash
# Choose your package manager and version
gh workflow run test.release.integration.yml \
  -f package-manager=uv \
  -f test-version=0.1.0-test.$(date +%s) \
  -f skip-admin-check=true \
  -f build-wheel=true
```

### View Test Results
```bash
# List recent workflow runs
gh run list --workflow=test.release.unit.yml

# View specific run details
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

## CI/CD Integration

The unit tests run automatically on:
- Every push to `main` branch
- Every pull request
- Manual dispatch

This ensures that any changes to the release action are validated before being merged.

## Troubleshooting

### Test Failures

**Permission Check Fails:**
- Ensure `GITHUB_TOKEN` has proper permissions
- Check if the repository collaborator API is accessible

**Package Manager Setup Fails:**
- Verify the package manager version is compatible
- Check if lock files are generated correctly

**Version Bump Fails:**
- Ensure commitizen is installed in dev dependencies
- Verify `tool.commitizen` configuration in `pyproject.toml`

**Integration Test Cleanup Fails:**
- Manually delete test branches: `git push origin --delete test-release-<timestamp>`
- Manually delete test tags: `git push origin --delete refs/tags/<test-version>`

### Debugging Tips

1. **Enable debug logging:**
   ```bash
   # Set repository secret or variable
   ACTIONS_RUNNER_DEBUG=true
   ACTIONS_STEP_DEBUG=true
   ```

2. **Check action.yml syntax:**
   ```bash
   # Install yq
   pip install yq
   
   # Validate YAML
   yq eval '.' actions/release/github/action.yml
   ```

3. **Test version logic locally:**
   ```bash
   VERSION="1.0.0"
   if [ -n "$VERSION" ]; then
     echo "Using version: $VERSION"
   fi
   ```

## Contributing

When modifying the release action:

1. Update the relevant test scenarios in `test.release.unit.yml`
2. Run the integration test with all package managers
3. Update this documentation if needed
4. Ensure all tests pass before merging

## Future Improvements

- [ ] Add tests for PyPI publishing (if added to action)
- [ ] Test different Python versions in integration tests
- [ ] Add tests for custom changelog templates
- [ ] Test with actual admin permissions
- [ ] Add performance benchmarks
- [ ] Test with monorepo scenarios

