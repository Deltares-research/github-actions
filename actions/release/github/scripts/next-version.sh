#!/usr/bin/env bash
# Resolve the next release version (in tag form) for the github release action.
#
# Why this isn't just `cz bump --dry-run | grep "tag to create"`:
#   When `update_changelog_on_bump = true`, `cz bump` (even with --dry-run)
#   generates the changelog, and `cz changelog --incremental` needs to anchor
#   on a previous tag. If the repo's tag history is messy (the latest version
#   recorded in the changelog has no git tag matching `tag_format`, or a tag
#   uses a form commitizen can't parse such as `2.3.1.post1`) that anchor
#   lookup fails with exit 16 ("No tag found to do an incremental changelog").
#   commitizen still prints the `tag to create:` line to stdout before that
#   failure, so we read it from the (partial) output and ignore the exit code.
#   As a second fallback we use `cz bump --get-next`, which prints just the
#   next version and returns before any changelog work.
#
# Usage: next-version.sh <increment> <prerelease-type> <cz-command...>
#   increment        : major | minor | patch
#   prerelease-type  : none | alpha | beta | rc
#   cz-command       : how to invoke commitizen, e.g. `poetry run cz`,
#                      `uv run cz`, `pixi run -e dev cz`
#
# Prints the next version (normalised to the configured tag_format) on stdout.
# Exits non-zero with a ::error:: message if it cannot determine a version.
#
# Run from the directory containing the project's pyproject.toml. Tested by
# .github/workflows/test.release.unit.yml -- keep that matrix in sync.
set -uo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <increment> <prerelease-type> <cz-command...>" >&2
  exit 2
fi

INCREMENT="$1"; shift
PRERELEASE_TYPE="$1"; shift
CZ=("$@")

PRERELEASE_ARGS=()
if [ "$PRERELEASE_TYPE" != "none" ] && [ -n "$PRERELEASE_TYPE" ]; then
  PRERELEASE_ARGS=(--prerelease "$PRERELEASE_TYPE")
fi

# commitizen's tag_format (defaults to "$version"). Used to turn a bare version
# returned by `cz bump --get-next` into the tag string the rest of the release
# pipeline expects (release tag name, changelog heading lookup, ...).
TAG_FORMAT='$version'
if [ -f pyproject.toml ]; then
  TF=$(grep -A 20 "^\[tool\.commitizen\]" pyproject.toml | grep "^tag_format" | head -1 | sed 's/.*=\s*"\(.*\)"/\1/' || true)
  [ -n "$TF" ] && TAG_FORMAT="$TF"
fi

to_tag() {
  # $1 = bare version; substitute it into $TAG_FORMAT ($version / ${version}).
  local v="$1" t="$TAG_FORMAT"
  t="${t//\$\{version\}/$v}"
  t="${t//\$version/$v}"
  printf '%s' "$t"
}

NEXT=""

# 1) `cz bump --dry-run` prints "tag to create: <tag>" before any changelog
#    work, so parse that even if cz then exits non-zero on a messy tag history.
#    Its stderr (including the underlying commitizen error, if any) flows to the
#    step log so failures stay visible.
DRYRUN_OUT=$("${CZ[@]}" bump --dry-run --yes --increment "$INCREMENT" "${PRERELEASE_ARGS[@]}") || true
NEXT=$(printf '%s\n' "$DRYRUN_OUT" \
        | grep -m1 'tag to create' \
        | sed -E 's/.*tag to create:[[:space:]]*//' \
        | tr -d '[:space:]') || true

# 2) Fallback: `cz bump --get-next` prints only the next version and returns
#    before generating the changelog, so it survives a tag history commitizen
#    can't fully parse. It emits a bare version, so normalise to tag form.
if [ -z "$NEXT" ]; then
  GETNEXT_OUT=$("${CZ[@]}" bump --get-next --yes --increment "$INCREMENT" "${PRERELEASE_ARGS[@]}") || true
  GETNEXT_VERSION=$(printf '%s\n' "$GETNEXT_OUT" | grep -m1 -E '^[0-9]' | tr -d '[:space:]') || true
  [ -n "$GETNEXT_VERSION" ] && NEXT=$(to_tag "$GETNEXT_VERSION")
fi

if [ -z "$NEXT" ]; then
  echo "::error::Could not determine the next version. Tried 'cz bump --dry-run' and 'cz bump --get-next'." >&2
  echo "::error::Check that commitizen is configured (e.g. a [tool.commitizen] block in pyproject.toml) and" >&2
  echo "::error::that existing git tags match tag_format ('$TAG_FORMAT'). A tag such as '2.3.1.post1' or" >&2
  echo "::error::'v1.0.0' that does not match tag_format breaks commitizen's incremental changelog." >&2
  exit 1
fi

printf '%s\n' "$NEXT"
