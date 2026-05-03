#!/usr/bin/env bash
# Verifies that mike pushed the named version to the fake remote's gh-pages.
#
# Usage: assert-gh-pages-has-version.sh <version>
#   <version>   The mike version to look for (e.g. 'develop', 'main', 'v1.0.0')
#
# Pairs with .github/workflows/test-helpers/setup-fake-remote (which creates
# the bare repo at /tmp/fake-remote.git and seeds gh-pages with a README).
#
# Mike publishes each version as a top-level directory on gh-pages plus a
# versions.json manifest. We assert both.
set -euo pipefail

VERSION="${1:?usage: assert-gh-pages-has-version.sh <version>}"
FAKE_REMOTE=/tmp/fake-remote.git

VERIFY_DIR="${RUNNER_TEMP:-/tmp}/verify-gh-pages"
rm -rf "$VERIFY_DIR"
git clone --quiet --branch gh-pages "file://$FAKE_REMOTE" "$VERIFY_DIR"

echo "gh-pages contents:"
ls -la "$VERIFY_DIR"

if [ ! -d "$VERIFY_DIR/$VERSION" ]; then
  echo "::error::expected directory '$VERSION/' on gh-pages, not found"
  exit 1
fi

if [ ! -f "$VERIFY_DIR/versions.json" ]; then
  echo "::error::versions.json missing on gh-pages — mike did not run as expected"
  exit 1
fi

if ! grep -q "\"version\": \"$VERSION\"" "$VERIFY_DIR/versions.json"; then
  echo "::error::versions.json does not list '$VERSION':"
  cat "$VERIFY_DIR/versions.json"
  exit 1
fi

echo "OK: gh-pages contains '$VERSION/' and versions.json lists it"
