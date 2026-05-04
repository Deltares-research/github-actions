#!/usr/bin/env bash
# Print "true" if $1 looks like a prerelease version, "false" otherwise.
#
# Recognises:
#   - PEP 440 prereleases:  1.0.0a1, 1.0.0b1, 1.0.0rc1, 1.0.0dev1, 1.0.0.dev1
#   - SemVer prereleases:   1.0.0-alpha.1, 1.0.0-beta.1, 1.0.0-rc.1,
#                           1.0.0-pre.1, 1.0.0-dev.1
#   - Either form behind a tag_format prefix (e.g. v1.0.0b1, pkg-1.0.0-beta.1)
#
# Treated as releases (false):
#   - 1.0.0, v1.0.0, pkg-1.0.0
#   - PEP 440 post-releases: 1.0.0.post1
#   - Tags whose prefix happens to contain stray letters (build, release, etc.)
#     as long as those letters don't form one of the prerelease patterns above.
#
# Tested by .github/workflows/test.release.unit.yml. Keep the regex here in
# sync with the test matrix.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <version>" >&2
  exit 2
fi

v="$1"

if [[ "$v" =~ [0-9]+(a|b|rc|dev)[0-9]+ ]] \
   || [[ "$v" =~ \.dev[0-9]+ ]] \
   || [[ "$v" =~ -(alpha|beta|rc|pre|dev) ]]; then
  echo "true"
else
  echo "false"
fi
