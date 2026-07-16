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
# --check is what CI runs; it prints a diff of actual (README) vs expected.
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

VERSIONING_DOC="$REPO_ROOT/docs/versioning.md"

# REGISTRY entries are "<action directory>|<tag namespace>", parsed from the
# namespace-registry table in docs/versioning.md.
#
# It is DERIVED, not hand-copied. docs/versioning.md declares itself the source of
# truth, and a second hand-maintained copy is what produced the bug this script
# exists to prevent: README's registry said `mkdocs` while the published tags (and
# versioning.md) said `mkdocs-deploy`. Two lists that must agree eventually do not.
#
# Cells must stay ASCII: printf pads by byte, so a multi-byte character (e.g. a
# footnote superscript) would silently misalign the column. Footnotes live in the
# prose under the table instead.
REGISTRY=()

load_registry() {
  local line dir ns
  # Rows look like: | `actions/release/github` | `github-release` | `...` |
  while IFS= read -r line; do
    dir=$(printf '%s' "$line" | sed -E 's/^\| *`([^`]+)` *\|.*/\1/')
    ns=$(printf '%s' "$line" | sed -E 's/^\| *`[^`]+` *\| *`([^`]+)` *\|.*/\1/')
    [ -n "$dir" ] && [ -n "$ns" ] && REGISTRY+=("$dir|$ns")
  done < <(grep -E '^\| *`actions/[^`]+` *\| *`[^`]+` *\|' "$VERSIONING_DOC" || true)

  if [ ${#REGISTRY[@]} -eq 0 ]; then
    echo "error: parsed no namespace rows from $VERSIONING_DOC" >&2
    echo "The registry table there is the source of truth; has its format changed?" >&2
    exit 2
  fi
}

# Every directory holding an action.yml must appear in the registry. Without this
# the table drifts in a new way: add an action, tag it, and --check still passes
# while the action never appears in the README -- a missing row is more invisible
# than a wrong SHA, which is the failure this script exists to prevent.
assert_registry() {
  # Explicit `=()` init, not a bare `local -a`: the latter leaves the array unset
  # until first assignment, so `${#missing[@]}` trips `set -u` on the happy path
  # (when nothing is missing) and kills the run.
  local -a on_disk=() registered=() missing=()
  local dir entry

  # `find | xargs` status is invisible to set -e through a process substitution,
  # so an empty result is checked explicitly below rather than trusted to fail.
  # Prefix stripping uses ${var#...} (not sed) so a path with regex metacharacters
  # cannot corrupt the expression.
  while IFS= read -r dir; do
    on_disk+=("${dir#"$REPO_ROOT/"}")
  done < <(find "$REPO_ROOT/actions" -name action.yml -exec dirname {} \; 2>/dev/null | sort)

  if [ ${#on_disk[@]} -eq 0 ]; then
    echo "error: found no actions/*/action.yml under $REPO_ROOT/actions" >&2
    echo "Either the checkout is broken or the layout changed; refusing to render" >&2
    echo "a table that would silently claim this repo publishes nothing." >&2
    exit 2
  fi

  for entry in "${REGISTRY[@]}"; do registered+=("${entry%%|*}"); done

  for dir in "${on_disk[@]}"; do
    case " ${registered[*]} " in
      *" $dir "*) ;;
      *) missing+=("$dir") ;;
    esac
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "error: these actions have no row in the namespace registry" >&2
    echo "($VERSIONING_DOC):" >&2
    printf '  %s\n' "${missing[@]}" >&2
    echo "Add a row there so the action appears in the README table." >&2
    exit 2
  fi
}

# Newest vX.Y.Z tag for a namespace, or empty when the action has no release yet.
#
# Only bare X.Y.Z is matched, which deliberately excludes both the floating major
# tag (<ns>/v1, force-pushed and so not a stable thing to advertise) and
# prereleases (<ns>/v1.0.0b1) -- the table advertises the newest stable release.
#
# `|| true` on the pipeline is load-bearing: with `pipefail`, a non-matching grep
# fails the whole pipeline, and under `set -e` that would abort the script on the
# assignment instead of returning empty -- making the no-tags branch below
# unreachable and killing the run with no output at all.
latest_tag() {
  git tag -l "$1/v*" \
    | grep -E "^$1/v[0-9]+\.[0-9]+\.[0-9]+$" \
    | sort -V \
    | tail -1 \
    || true
}

build_table() {
  local -a actions=() versions=() shas=()
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

# Assert exactly one of each marker, on its own line, in the right order.
#
# The -x (whole-line) match is load-bearing and must stay in lockstep with
# render_readme's awk, which splices on `$0 == begin`. Validating with a substring
# match instead let an indented or trailing-space marker satisfy this function
# while never matching in awk: the splice then no-opped, render_readme returned the
# README verbatim, --check compared the file to itself and reported "up to date"
# -- staying green no matter how wrong the table was. A guard that fails open is
# worse than no guard, because CI vouches for the drift.
#
# Order and uniqueness matter too: duplicate markers make awk insert the table
# twice, and an inverted pair emits a mangled README -- both silently, and --write
# would commit the damage.
require_markers() {
  local begin_count end_count begin_line end_line
  begin_count=$(grep -cxF "$BEGIN_MARKER" "$README" || true)
  end_count=$(grep -cxF "$END_MARKER" "$README" || true)

  if [ "$begin_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    echo "error: README.md must contain exactly one of each generated-block marker," >&2
    echo "each alone on its own line with no leading or trailing whitespace." >&2
    echo "  found $begin_count x '$BEGIN_MARKER'" >&2
    echo "  found $end_count x '$END_MARKER'" >&2
    exit 2
  fi

  begin_line=$(grep -nxF "$BEGIN_MARKER" "$README" | cut -d: -f1)
  end_line=$(grep -nxF "$END_MARKER" "$README" | cut -d: -f1)
  if [ "$begin_line" -ge "$end_line" ]; then
    echo "error: the BEGIN marker must precede the END marker in README.md" >&2
    echo "  BEGIN at line $begin_line, END at line $end_line" >&2
    exit 2
  fi
}

# Splice the freshly built table between the markers, leaving everything else
# (prose, footnotes, pin example) untouched.
#
# Read/write are deliberately asymmetric: CR is stripped from every line so a CRLF
# working tree does not read as "every line changed", which means output is always
# LF. With core.autocrlf git normalizes to LF on commit anyway, so this only
# affects the working copy.
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
  load_registry
  assert_registry
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
        echo "::error::README.md releases table is out of date. Run .github/workflows/scripts/generate-releases-table.sh --write" >&2
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
