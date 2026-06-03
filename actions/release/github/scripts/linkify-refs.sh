#!/usr/bin/env bash
# Rewrite bare "#<num>" issue/PR references into clickable markdown links.
#
# Commitizen writes PR/issue references as bare "(#31)". GitHub only
# auto-links bare "#31" inside issues/PRs/commits -- NOT in a release body
# supplied as custom text -- so without this rewrite they render as plain text.
#
# Usage:
#   linkify-refs.sh <repo-url> < body   # reads stdin, writes rewritten body to stdout
#
# "<repo-url>" is the repository base URL, e.g. https://github.com/owner/repo.
# References are linked to "<repo-url>/issues/<num>" because GitHub redirects
# that to the pull request when the number is a PR, so it is correct for both
# issues and PRs.
#
# The guard "([^[]|^)" preserves the character before "#" (e.g. the "(" in
# "(#31)") while skipping references that are already inside a "[#31](...)"
# markdown link (those are preceded by "[").
#
# Tested by .github/workflows/test.release.unit.yml. Keep the regex here in
# sync with the test matrix.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <repo-url>  (body on stdin)" >&2
  exit 2
fi

repo_url="$1"

sed -E "s@([^[]|^)#([0-9]+)@\1[#\2](${repo_url}/issues/\2)@g"
