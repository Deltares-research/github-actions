#!/usr/bin/env bash
# Generate the "Latest releases" table in README.md from the actual git tags.
#
# The table maps each composite action to its newest released version tag and the
# full 40-character commit SHA that tag resolves to. Consumers pin the SHA, so a
# hand-maintained table drifts silently and hands people a stale or non-existent
# ref. This regenerates it from the tags instead.
#
# Usage:
#   generate-releases-table.sh            # print the table to stdout
#   generate-releases-table.sh --write    # rewrite the table block in README.md
#   generate-releases-table.sh --check    # exit 1 if README.md is out of date
#
# --check is what CI runs; it prints a diff of expected vs actual.
#
# Requires: git, with tags fetched (git fetch --tags).
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
README="$REPO_ROOT/README.md"
BEGIN_MARKER='<!-- BEGIN GENERATED: latest-releases -->'
END_MARKER='<!-- END GENERATED: latest-releases -->'

# Temp files are global, not local: the EXIT trap runs after main()'s locals are
# gone, and `set -u` would abort on them.
TABLE_FILE=
EXPECTED=
cleanup() { rm -f "$TABLE_FILE" "$EXPECTED"; }
trap cleanup EXIT

# Registry: <action directory>|<tag namespace>
#
# The namespace is the tag prefix that is ACTUALLY published, which is not always
# the short name in docs/versioning.md (mkdocs-deploy vs mkdocs). Add a row here
# when a new action gets its first tag.
#
# Cells must stay ASCII: printf pads by byte, so a multi-byte character (e.g. a
# footnote superscript) would silently misalign the column. Footnotes live in the
# prose under the table instead.
REGISTRY=(
  "actions/python-setup/pip|pip"
  "actions/python-setup/uv|uv"
  "actions/python-setup/poetry|poetry"
  "actions/python-setup/pixi|pixi"
  "actions/mkdocs-deploy|mkdocs-deploy"
  "actions/release/github|github-release"
  "actions/release/latex-manual|latex"
)

# Newest vX.Y.Z tag for a namespace. Excludes the floating major tag (<ns>/v1),
# which is force-pushed and therefore not a stable thing to advertise.
latest_tag() {
  git tag -l "$1/v*" \
    | grep -E "^$1/v[0-9]+\.[0-9]+\.[0-9]+$" \
    | sort -V \
    | tail -1
}

build_table() {
  local -a actions versions shas
  local h_action="Action" h_version="Latest version" h_sha="Commit SHA (pin this)"
  local w_action=${#h_action} w_version=${#h_version} w_sha=${#h_sha}
  local entry dir ns tag sha action version

  for entry in "${REGISTRY[@]}"; do
    IFS='|' read -r dir ns <<< "$entry"
    tag=$(latest_tag "$ns")
    if [ -n "$tag" ]; then
      version="\`$tag\`"
      sha="\`$(git rev-list -n 1 "$tag")\`"
    else
      version="_unreleased_"
      sha="-"
    fi
    action="\`$dir\`"

    actions+=("$action"); versions+=("$version"); shas+=("$sha")
    (( ${#action}  > w_action  )) && w_action=${#action}
    (( ${#version} > w_version )) && w_version=${#version}
    (( ${#sha}     > w_sha     )) && w_sha=${#sha}
  done

  printf '| %-*s | %-*s | %-*s |\n' \
    "$w_action" "$h_action" "$w_version" "$h_version" "$w_sha" "$h_sha"
  printf '|%s|%s|%s|\n' \
    "$(printf -- '-%.0s' $(seq $((w_action + 2))))" \
    "$(printf -- '-%.0s' $(seq $((w_version + 2))))" \
    "$(printf -- '-%.0s' $(seq $((w_sha + 2))))"

  local i
  for i in "${!actions[@]}"; do
    printf '| %-*s | %-*s | %-*s |\n' \
      "$w_action" "${actions[$i]}" \
      "$w_version" "${versions[$i]}" \
      "$w_sha" "${shas[$i]}"
  done
}

require_markers() {
  grep -qF "$BEGIN_MARKER" "$README" && grep -qF "$END_MARKER" "$README" && return 0
  echo "error: README.md is missing the generated-block markers:" >&2
  echo "  $BEGIN_MARKER" >&2
  echo "  $END_MARKER" >&2
  exit 2
}

# Splice the freshly built table between the markers, leaving everything else
# (prose, footnotes, pin example) untouched.
render_readme() {
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v tf="$TABLE_FILE" '
    { sub(/\r$/, "") }                 # tolerate a CRLF working tree (Windows)
    $0 == begin { print; while ((getline line < tf) > 0) print line; close(tf); skip=1; next }
    $0 == end   { print; skip=0; next }
    !skip       { print }
  ' "$README"
}

# Compare ignoring line endings, so a CRLF checkout does not read as "every line
# changed" against LF-generated output.
same_ignoring_eol() {
  diff -q <(tr -d '\r' < "$1") <(tr -d '\r' < "$2") >/dev/null 2>&1
}

main() {
  local mode=${1:---print}
  require_markers

  TABLE_FILE=$(mktemp)
  EXPECTED=$(mktemp)

  build_table > "$TABLE_FILE"

  case "$mode" in
    --print)
      cat "$TABLE_FILE"
      ;;
    --write)
      render_readme > "$EXPECTED"
      if same_ignoring_eol "$EXPECTED" "$README"; then
        echo "README.md already up to date."
      else
        cp "$EXPECTED" "$README"
        echo "README.md releases table updated."
      fi
      ;;
    --check)
      render_readme > "$EXPECTED"
      if same_ignoring_eol "$EXPECTED" "$README"; then
        echo "[OK] README.md releases table is up to date."
      else
        echo "::error::README.md releases table is out of date. Run .github/scripts/generate-releases-table.sh --write" >&2
        diff -u <(tr -d '\r' < "$README") <(tr -d '\r' < "$EXPECTED") >&2 || true
        exit 1
      fi
      ;;
    *)
      echo "usage: $0 [--print|--write|--check]" >&2
      exit 2
      ;;
  esac
}

main "$@"
