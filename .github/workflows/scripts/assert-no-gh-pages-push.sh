#!/usr/bin/env bash
# Asserts mike did NOT push anything new to the fake remote's gh-pages branch.
#
# Pairs with .github/workflows/test-helpers/setup-fake-remote which seeds
# gh-pages with exactly ONE commit (the README seed). If mike pushed, there
# will be additional commits on the branch.
#
# Used by tests whose deploy-types should not match the triggering event —
# proves the action correctly skipped all deploy steps.
set -euo pipefail

FAKE_REMOTE=/tmp/fake-remote.git

COMMIT_COUNT=$(git --git-dir="$FAKE_REMOTE" rev-list --count refs/heads/gh-pages)
if [ "$COMMIT_COUNT" -ne 1 ]; then
  echo "::error::expected gh-pages to have exactly 1 commit (seed), found $COMMIT_COUNT — a deploy step ran when it shouldn't have"
  git --git-dir="$FAKE_REMOTE" log --oneline refs/heads/gh-pages
  exit 1
fi

echo "OK: gh-pages still at seed commit — no deploy step fired"
