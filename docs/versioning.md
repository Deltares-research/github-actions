# Namespaced Versioning Guide

This guide explains how to release and version individual actions in this repository **independently** using namespaced Git tags.

## Table of Contents

- [Overview](#overview)
- [When to Use Namespaced Versioning](#when-to-use-namespaced-versioning)
- [Tag Format](#tag-format)
- [Tag Types](#tag-types)
- [Release Process](#release-process)
- [Moving Major Version Tags](#moving-major-version-tags)
- [Automated Release Workflow](#automated-release-workflow)
- [Usage for Consumers](#usage-for-consumers)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Overview

Namespaced versioning gives **each action its own independent version tags**. You can release `pip/v1.0.1` without affecting `mkdocs-deploy` or any other action in the repository.

This is in contrast to *global versioning*, where a single tag (`v1`, `v2`, …) advances all actions together.

## When to Use Namespaced Versioning

Choose namespaced versioning when:

- Actions evolve on independent release cycles
- You want granular, per-action version control
- Different actions have different stability levels (e.g. one is at `v3`, another still at `v1`)
- A breaking change in one action should not force consumers of unrelated actions to migrate
- You want a clear, action-scoped version history

If all actions are released together and depend on each other, prefer global versioning instead.

## Tag Format

Namespaced tags use a short namespace per action — **not** the full directory path. The namespace is chosen for readability in `uses:` lines, not derived mechanically from the file tree:

```
<namespace>/v<MAJOR>.<MINOR>.<PATCH>
<namespace>/v<MAJOR>
```

**Namespace registry — keep this table the source of truth:**

| Action directory               | Namespace        | Examples                                     |
|--------------------------------|------------------|----------------------------------------------|
| `actions/python-setup/pip`     | `pip`            | `pip/v1.0.0`, `pip/v1`                       |
| `actions/python-setup/uv`      | `uv`             | `uv/v1.0.0`, `uv/v1`                         |
| `actions/python-setup/poetry`  | `poetry`         | `poetry/v1.0.0`, `poetry/v1`                 |
| `actions/python-setup/pixi`    | `pixi`           | `pixi/v1.0.0`, `pixi/v1`                     |
| `actions/mkdocs-deploy`        | `mkdocs-deploy`  | `mkdocs-deploy/v1.0.0`, `mkdocs-deploy/v1`   |
| `actions/release/github`       | `github-release` | `github-release/v1.0.0`, `github-release/v1` |
| `actions/release/latex-manual` | `latex`          | `latex/v1.0.0`, `latex/v1`                   |

Pick a namespace per action and stick with it — consumers will reference it forever. If you add a new action, append a row here before cutting its first tag.

## Tag Types

For every action, maintain two kinds of tags.

### 1. Specific Version Tags (Immutable)

**Format:** `<namespace>/v1.0.0`, `<namespace>/v1.1.0`, `<namespace>/v2.0.0`

- Never moved or deleted
- Always point to the same commit
- Used for reproducibility, audits, and security-sensitive workflows

### 2. Major Version Tags (Moving)

**Format:** `<namespace>/v1`, `<namespace>/v2`

- Force-pushed forward as new minor/patch releases land within the same major
- Lets consumers opt into automatic backward-compatible updates
- Never moved backward; never moved across a major boundary

## Release Process

### 1. Prepare the Release

Commit and push your changes to the specific action:

```bash
git add actions/python-setup/pip/
git commit -m "feat(pip): add support for dependency groups"
git push origin main
```

### 2. Create the Specific Version Tag

```bash
git tag -a pip/v1.0.1 -m "Release pip v1.0.1

- Add support for PEP 735 dependency groups
- Fix cache key generation on Windows
- Improve error messages"

git push origin pip/v1.0.1
```

### 3. Move (or Create) the Major Version Tag

```bash
# Force-update the floating major tag for this action
git tag -fa pip/v1 -m "Update pip v1 to v1.0.1"

git push origin pip/v1 --force
```

For a brand-new major (breaking change), create a fresh tag instead of moving the old one:

```bash
git tag -a pip/v2 -m "Major version pip v2"
git push origin pip/v2
```

### 3b. Refresh the README releases table

The **Latest releases** table in `README.md` is generated from the tags, so the tag you just pushed makes it a
release out of date. Regenerate and commit it on `main`:

```bash
.github/workflows/scripts/generate-releases-table.sh --write
git commit -am "docs(readme): refresh releases table for pip/v1.0.1"
git push origin main
```

Consumers pin the commit SHAs from that table, so a stale row sends them to an old ref. **This step is the only
thing keeping the table honest** — do not skip it. The `releases-table - check` workflow is manual
(`gh workflow run ci.releases-table.yml`), so nothing fires automatically if you forget; you can also verify
locally with `generate-releases-table.sh --check`.

Note the table can never be current *within* the tagged commit itself: the tag has to exist before the SHA it
resolves to is known, so the refresh necessarily lands in a later commit.

### 4. Create the GitHub Release

**With GitHub CLI:**

```bash
gh release create pip/v1.0.1 \
  --title "pip v1.0.1" \
  --notes "## New Features

- Dependency Groups: Support for PEP 735 dependency groups
- Improved cache key generation on Windows

## Upgrade Notes

Backward-compatible release for the \`python-setup/pip\` action only.

\`\`\`yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@pip/v1.0.1
  # or @pip/v1 for automatic updates
\`\`\`"
```

**With the GitHub web UI:**

1. Releases → **Draft a new release**
2. **Choose a tag** → select `pip/v1.0.1`
3. Title: `pip v1.0.1`
4. Write notes (prefix with the namespace so the release list stays scannable)
5. Publish

## Moving Major Version Tags

"Moving" a tag means re-pointing it at a different commit. For namespaced majors:

```bash
# -f = force overwrite local tag
# -a = annotated tag with metadata
git tag -fa pip/v1 -m "Update pip v1 to v1.0.1"

# --force is required to overwrite the remote tag
git push origin pip/v1 --force
```

Rules:

- **Always move** the major tag forward when releasing a new patch/minor within the same major.
- **Never move** the major tag across a major boundary — `pip/v1` must never end up pointing at a `v2.x.x` commit.
- **Never delete or rewrite** specific tags like `pip/v1.0.0` — consumers may pin to them.

## Automated Release Workflow

Drop this into `.github/workflows/release-namespaced.yml` to automate steps 3 and 4 whenever a namespaced tag is pushed:

```yaml
name: Create Namespaced Release

on:
  push:
    tags:
      - '*/v*.*.*'  # Matches pip/v1.0.1, mkdocs-deploy/v1.2.0, github-release/v1.0.1, etc.

permissions:
  contents: write

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version info
        id: version
        run: |
          TAG=${GITHUB_REF#refs/tags/}
          NAMESPACE=$(echo $TAG | sed 's|/v[0-9].*||')
          VERSION=$(echo $TAG | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+$')
          MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)

          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "namespace=$NAMESPACE" >> $GITHUB_OUTPUT
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "major=$NAMESPACE/$MAJOR_VERSION" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          name: "${{ steps.version.outputs.namespace }} ${{ steps.version.outputs.version }}"
          generate_release_notes: true
          draft: false
          prerelease: false

      - name: Update major version tag
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag -fa ${{ steps.version.outputs.major }} -m "Update ${{ steps.version.outputs.major }} to ${{ steps.version.outputs.tag }}"
          git push origin ${{ steps.version.outputs.major }} --force
```

Pushing `pip/v1.0.1` then automatically:

1. Creates a GitHub release titled `pip v1.0.1`
2. Generates release notes from commits
3. Force-moves `pip/v1` to the same commit

## Usage for Consumers

Reference a namespaced action by appending `@<namespace>/v<...>` to the action path. The action path still mirrors the directory; only the ref namespace is short.

### Pin to a Specific Version (Production)

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@pip/v1.0.1
```

Stable, reproducible, no surprise updates.

### Track the Major (Most Workflows)

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@pip/v1
```

Picks up patch and minor releases automatically; never crosses into `v2`.

### Track `main` (Not Recommended)

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@main
```

Only for testing unreleased changes — can break at any time.

| Use case | Recommended ref |
|---|---|
| Production / compliance | `@pip/v1.0.1` |
| CI/CD pipelines | `@pip/v1` |
| Dependabot / Renovate | `@pip/v1` |
| Testing unreleased work | `@main` |

## Examples

### First Release of an Action

```bash
git tag -a pip/v1.0.0 -m "Release pip v1.0.0: Initial release"
git push origin pip/v1.0.0

git tag -a pip/v1 -m "Major version pip v1"
git push origin pip/v1

gh release create pip/v1.0.0 \
  --title "pip v1.0.0 - Initial Release" \
  --generate-notes
```

### Bug Fix Release

```bash
git tag -a pip/v1.0.1 -m "Release pip v1.0.1: Fix cache key on Windows"
git push origin pip/v1.0.1

git tag -fa pip/v1 -m "Update pip v1 to v1.0.1"
git push origin pip/v1 --force

gh release create pip/v1.0.1 \
  --title "pip v1.0.1 - Bug Fixes" \
  --notes "Fix cache key generation for Windows"
```

### New Feature Release

```bash
git tag -a mkdocs-deploy/v1.1.0 -m "Release mkdocs-deploy v1.1.0: Add custom domain support"
git push origin mkdocs-deploy/v1.1.0

git tag -fa mkdocs-deploy/v1 -m "Update mkdocs-deploy v1 to v1.1.0"
git push origin mkdocs-deploy/v1 --force

gh release create mkdocs-deploy/v1.1.0 \
  --title "mkdocs-deploy v1.1.0 - Custom Domain Support" \
  --generate-notes
```

### Breaking Change Release

```bash
git tag -a uv/v2.0.0 -m "Release uv v2.0.0: Remove deprecated inputs"
git push origin uv/v2.0.0

# Create a NEW major tag — do not move uv/v1
git tag -a uv/v2 -m "Major version uv v2"
git push origin uv/v2

gh release create uv/v2.0.0 \
  --title "uv v2.0.0 - Breaking Changes" \
  --notes "## Breaking Changes

- Removed \`legacy-mode\` input
- Changed default behavior for lockfile validation

See migration guide in docs."
```

### Releasing Multiple Actions Independently

```bash
# pip → v1.0.1
git tag -a pip/v1.0.1 -m "Release pip v1.0.1"
git push origin pip/v1.0.1
git tag -fa pip/v1 -m "Update to v1.0.1"
git push origin pip/v1 --force

# mkdocs-deploy → v1.2.0 (same commit, different action, different version)
git tag -a mkdocs-deploy/v1.2.0 -m "Release mkdocs-deploy v1.2.0"
git push origin mkdocs-deploy/v1.2.0
git tag -fa mkdocs-deploy/v1 -m "Update to v1.2.0"
git push origin mkdocs-deploy/v1 --force

# uv is untouched and stays at its current version
```

### Security Release Across Multiple Actions

When a single audit fixes issues in several actions, cut a coordinated patch bump for each affected action against the same `main` commit:

```bash
# Cut patch tags for every action whose action.yml changed
for ns in pip uv poetry pixi github-release latex; do
  git tag -a "$ns/v1.0.1" -m "Release $ns v1.0.1: security fixes (SHA-pin third-party actions, etc.)"
  git push origin "$ns/v1.0.1"
done

# Move the floating majors
for ns in pip uv poetry pixi github-release latex; do
  git tag -fa "$ns/v1" -m "Update $ns v1 to v1.0.1"
  git push origin "$ns/v1" --force
done
```

Actions whose `action.yml` is byte-identical do **not** get a new tag (an audit pass alone is not a release event).

## Best Practices

### Maintainers

1. Always use annotated tags (`-a`) with meaningful messages
2. Keep one namespace per action and never rename it — once consumers pin, the namespace is forever
3. Move the major tag on every backward-compatible release
4. Never move or delete specific version tags
5. Never move a major tag across a major boundary
6. Document breaking changes with a migration guide in the release notes
7. Use deprecation warnings for at least one minor release before removing inputs
8. Pin internal action-to-action references to namespaced tags rather than `@main` if you want versioning to be transitive (see the note in `CLAUDE.md` — `uses:` does not evaluate expressions, so this requires a manual SHA bump on each release)

### Consumers

1. Pin to `@<namespace>/v1.0.0` for production / compliance workflows
2. Track `@<namespace>/v1` for everyday CI/CD
3. Read release notes when a major version changes
4. Never use `@main` in production
5. Let Dependabot or Renovate track the major tag for you

## Pre-Release Checklist

- [ ] Changes committed and pushed to `main`
- [ ] Tests passing
- [ ] Action documentation updated
- [ ] Version bump decided (PATCH / MINOR / MAJOR)
- [ ] Breaking changes documented with migration steps (if MAJOR)
- [ ] Specific namespaced tag created and pushed
- [ ] Major namespaced tag moved (or created, for a new major) and force-pushed
- [ ] GitHub release created with notes
- [ ] Verified tags resolve correctly in a sample workflow
