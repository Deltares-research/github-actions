# Namespaced Versioning Guide

This guide explains how to release and version individual actions in this repository **independently** using
namespaced Git tags. This repo uses **immutable tags only** — there are no floating major tags.

## Table of Contents

- [Overview](#overview)
- [When to Use Namespaced Versioning](#when-to-use-namespaced-versioning)
- [Tag Format](#tag-format)
- [Tag Policy — Immutable Only](#tag-policy--immutable-only)
- [Release Process](#release-process)
- [Automated Release Workflow](#automated-release-workflow)
- [Usage for Consumers](#usage-for-consumers)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Pre-Release Checklist](#pre-release-checklist)

## Overview

Namespaced versioning gives **each action its own independent version tags**. You can release `pip/v1.0.1` without
affecting `mkdocs-deploy` or any other action in the repository.

This is in contrast to *global versioning*, where a single tag (`v1`, `v2`, …) advances all actions together.

Every tag is an **immutable, specific version** (`<namespace>/vX.Y.Z`). This repo deliberately does **not** publish
floating major tags (`<namespace>/v1`) — see [Tag Policy](#tag-policy--immutable-only).

## When to Use Namespaced Versioning

Choose namespaced versioning when:

- Actions evolve on independent release cycles
- You want granular, per-action version control
- Different actions have different stability levels (e.g. one is at `v3`, another still at `v1`)
- A breaking change in one action should not force consumers of unrelated actions to migrate
- You want a clear, action-scoped version history

If all actions are released together and depend on each other, prefer global versioning instead.

## Tag Format

Namespaced tags use a short namespace per action — **not** the full directory path. The namespace is chosen for
readability in `uses:` lines, not derived mechanically from the file tree:

```
<namespace>/v<MAJOR>.<MINOR>.<PATCH>
```

Only the fully-qualified `vX.Y.Z` form exists. There is no `<namespace>/v<MAJOR>` (or `v<MAJOR>.<MINOR>`) floating
tag.

**Namespace registry — keep this table the source of truth:**

| Action directory                 | Namespace        | Examples                                         |
|----------------------------------|------------------|--------------------------------------------------|
| `actions/python-setup/pip`       | `pip`            | `pip/v1.0.0`, `pip/v1.0.1`                       |
| `actions/python-setup/uv`        | `uv`             | `uv/v1.0.0`, `uv/v1.1.0`                         |
| `actions/python-setup/poetry`    | `poetry`         | `poetry/v1.1.0`, `poetry/v1.1.1`                 |
| `actions/python-setup/pixi`      | `pixi`           | `pixi/v1.0.0`, `pixi/v1.1.0`                     |
| `actions/mkdocs-deploy`          | `mkdocs-deploy`  | `mkdocs-deploy/v1.0.0`, `mkdocs-deploy/v1.1.0`   |
| `actions/executable/pyinstaller` | `pyinstaller`    | `pyinstaller/v1.0.0`, `pyinstaller/v1.1.0`       |
| `actions/release/github`         | `github-release` | `github-release/v1.1.4`, `github-release/v1.2.0` |
| `actions/release/latex-manual`   | `latex`          | `latex/v1.0.0`, `latex/v1.1.0`                   |

Pick a namespace per action and stick with it — consumers will reference it forever. If you add a new action,
append a row here before cutting its first tag.

## Tag Policy — Immutable Only

Every tag this repo publishes is a **specific version** and is treated as permanent:

- **Format:** `<namespace>/v1.0.0`, `<namespace>/v1.1.0`, `<namespace>/v2.0.0`
- **Never moved or deleted.** A tag always points at the same commit, forever.
- Used for reproducibility, audits, and security-sensitive workflows — which is to say, all workflows.

### Why no floating major tags

A floating major tag (`<namespace>/v1` that is force-pushed forward on every release) makes a consumer's pin
**non-reproducible**: `uses: …@pip/v1` can resolve to different code on two runs with no change on the consumer's
side and nothing in their diff to show it. The same hazard applies to internal action-to-action composition, where
`uses:` does not evaluate expressions and pinning is not transitive. To keep every reference reproducible, this repo:

- publishes **only** immutable `vX.Y.Z` tags, and
- pins **internal** composition to exact versions too — e.g. `actions/mkdocs-deploy` and `actions/release/github`
  reference `actions/python-setup/<pm>@<pm>/vX.Y.Z`, not `@main` and not `@<pm>/v1`.

The trade-off is deliberate: consumers (and the wrappers) do not get patch/minor updates automatically; a bump is
an explicit change to the pinned version. Let Dependabot or Renovate propose those bumps.

### Migrating off a floating tag

Earlier releases published floating majors (`<namespace>/v1`). They have been retired. If you were pinning
`@<namespace>/v1`, switch to the exact version you want, e.g. `@pip/v1.0.1`. The newest version of each action is in
the "Latest releases" table in the repo [README](../README.md).

## Release Process

### 1. Prepare the Release

Land your change to the action on `main` (via a pull request):

```bash
# on a feature branch, via a PR that merges to main
git add actions/python-setup/pip/
git commit -m "feat(pip): add support for dependency groups"
```

### 2. Create the Specific Version Tag

Tag the merged commit on `main`:

```bash
git tag -a pip/v1.0.1 --no-gpg-sign -m "Release pip v1.0.1

- Add support for PEP 735 dependency groups
- Fix cache key generation on Windows
- Improve error messages"

git push origin pip/v1.0.1
```

That's the whole bump — there is no floating major tag to move.

For a **breaking change**, cut a fresh major version (`v2.0.0`); you never retro-point anything, so old `v1.x.x`
tags keep working for existing consumers:

```bash
git tag -a pip/v2.0.0 --no-gpg-sign -m "Release pip v2.0.0: remove deprecated inputs"
git push origin pip/v2.0.0
```

### 3. Create the GitHub Release

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
\`\`\`"
```

**With the GitHub web UI:**

1. Releases → **Draft a new release**
2. **Choose a tag** → select `pip/v1.0.1`
3. Title: `pip v1.0.1`
4. Write notes (prefix with the namespace so the release list stays scannable)
5. Publish

## Automated Release Workflow

Drop this into `.github/workflows/release-namespaced.yml` to create the GitHub release whenever a namespaced tag is
pushed:

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
        uses: actions/checkout@v7
        with:
          fetch-depth: 0

      - name: Get version info
        id: version
        run: |
          TAG=${GITHUB_REF#refs/tags/}
          NAMESPACE=$(echo $TAG | sed 's|/v[0-9].*||')
          VERSION=$(echo $TAG | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+$')

          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "namespace=$NAMESPACE" >> $GITHUB_OUTPUT
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          name: "${{ steps.version.outputs.namespace }} ${{ steps.version.outputs.version }}"
          generate_release_notes: true
          draft: false
          prerelease: false
```

Pushing `pip/v1.0.1` then automatically creates a GitHub release titled `pip v1.0.1` with notes generated from the
commits. There is no major-tag move step, because this repo keeps no floating major tags.

## Usage for Consumers

Reference a namespaced action by appending `@<namespace>/v<MAJOR>.<MINOR>.<PATCH>` to the action path. The action
path still mirrors the directory; only the ref namespace is short.

### Pin to a Specific Version (all workflows)

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@pip/v1.0.1
```

Stable, reproducible, no surprise updates. This is the only supported way to pin a release — bump the pinned version
deliberately (or let Dependabot/Renovate open a PR to bump it for you).

### Track `main` (Not Recommended)

```yaml
- uses: Deltares-research/github-actions/actions/python-setup/pip@main
```

Only for testing unreleased changes — can break at any time.

| Use case | Recommended ref |
|---|---|
| Production / compliance | `@pip/v1.0.1` |
| CI/CD pipelines | `@pip/v1.0.1` |
| Dependabot / Renovate | `@pip/v1.0.1` (tool bumps the exact version) |
| Testing unreleased work | `@main` |

## Examples

### First Release of an Action

```bash
git tag -a pip/v1.0.0 --no-gpg-sign -m "Release pip v1.0.0: Initial release"
git push origin pip/v1.0.0

gh release create pip/v1.0.0 \
  --title "pip v1.0.0 - Initial Release" \
  --generate-notes
```

### Bug Fix Release

```bash
git tag -a pip/v1.0.1 --no-gpg-sign -m "Release pip v1.0.1: Fix cache key on Windows"
git push origin pip/v1.0.1

gh release create pip/v1.0.1 \
  --title "pip v1.0.1 - Bug Fixes" \
  --notes "Fix cache key generation for Windows"
```

### New Feature Release

```bash
git tag -a mkdocs-deploy/v1.1.0 --no-gpg-sign -m "Release mkdocs-deploy v1.1.0: Add custom domain support"
git push origin mkdocs-deploy/v1.1.0

gh release create mkdocs-deploy/v1.1.0 \
  --title "mkdocs-deploy v1.1.0 - Custom Domain Support" \
  --generate-notes
```

### Breaking Change Release

```bash
git tag -a uv/v2.0.0 --no-gpg-sign -m "Release uv v2.0.0: Remove deprecated inputs"
git push origin uv/v2.0.0

gh release create uv/v2.0.0 \
  --title "uv v2.0.0 - Breaking Changes" \
  --notes "## Breaking Changes

- Removed \`legacy-mode\` input
- Changed default behavior for lockfile validation

Existing consumers stay on \`uv/v1.x.x\`; migrate deliberately. See migration guide in docs."
```

Old `v1.x.x` tags are never touched, so consumers pinned to them keep working until they choose to migrate.

### Releasing Multiple Actions Independently

```bash
# pip → v1.0.1
git tag -a pip/v1.0.1 --no-gpg-sign -m "Release pip v1.0.1"
git push origin pip/v1.0.1

# mkdocs-deploy → v1.2.0 (same commit, different action, different version)
git tag -a mkdocs-deploy/v1.2.0 --no-gpg-sign -m "Release mkdocs-deploy v1.2.0"
git push origin mkdocs-deploy/v1.2.0

# uv is untouched and stays at its current version
```

### Security Release Across Multiple Actions

When a single audit fixes issues in several actions, cut a coordinated patch bump for each affected action against
the same `main` commit:

```bash
# Cut patch tags for every action whose action.yml changed
for ns in pip uv poetry pixi github-release latex; do
  git tag -a "$ns/v1.0.1" --no-gpg-sign -m "Release $ns v1.0.1: security fixes (SHA-pin third-party actions, etc.)"
  git push origin "$ns/v1.0.1"
done
```

Actions whose `action.yml` is byte-identical do **not** get a new tag (an audit pass alone is not a release event).

## Best Practices

### Maintainers

1. Always use annotated tags (`-a`) with meaningful messages
2. Keep one namespace per action and never rename it — once consumers pin, the namespace is forever
3. Publish immutable `vX.Y.Z` tags only — never a floating `<namespace>/v<MAJOR>` tag
4. Never move or delete a published version tag
5. For a breaking change, cut a new `vX.0.0`; leave the old `v(X-1).y.z` tags in place
6. Document breaking changes with a migration guide in the release notes
7. Use deprecation warnings for at least one minor release before removing inputs
8. Pin internal action-to-action references to exact namespaced versions (`@<ns>/vX.Y.Z`), not `@main` — `uses:`
   does not evaluate expressions, so bump these pins (and re-release the wrapper) on each internal release

### Consumers

1. Pin to an exact `@<namespace>/vX.Y.Z` in every workflow
2. Read release notes before bumping to a new version
3. Never use `@main` in production
4. Let Dependabot or Renovate open PRs that bump the pinned version for you

## Pre-Release Checklist

- [ ] Changes committed and pushed to `main` (via a merged PR)
- [ ] Tests passing
- [ ] Action documentation updated
- [ ] Version bump decided (PATCH / MINOR / MAJOR)
- [ ] Breaking changes documented with migration steps (if MAJOR)
- [ ] Specific namespaced tag created and pushed
- [ ] GitHub release created with notes
- [ ] Verified the tag resolves correctly in a sample workflow
- [ ] Any internal wrapper that composes the released action bumped to the new exact version and re-released
```

