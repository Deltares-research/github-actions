#!/usr/bin/env bash
# Assert that `build-wheel: true` on the release/github action produced both a
# wheel and an sdist, and that the action exported DIST_FILES (the glob it hands
# to softprops/action-gh-release as `files:`) such that it covers both of them.
#
# Run from the project directory (where dist/ lives), in a step *after* the
# release action step (DIST_FILES must be in the environment by then).
# Used by .github/workflows/test.release.integration.yml.
set -uo pipefail

echo "::group::Built distributions"
ls -la dist/ 2>/dev/null || { echo "::error::no dist/ directory"; exit 1; }
echo "DIST_FILES (passed to the release as files:): ${DIST_FILES:-<unset>}"
echo "::endgroup::"

ls dist/*.whl    >/dev/null 2>&1 || { echo "::error::no wheel (*.whl) built in dist/"; exit 1; }
ls dist/*.tar.gz >/dev/null 2>&1 || { echo "::error::no sdist (*.tar.gz) built in dist/"; exit 1; }
[ -n "${DIST_FILES:-}" ]          || { echo "::error::DIST_FILES was not exported by the action's build step"; exit 1; }

# DIST_FILES is a glob string (e.g. './dist/*'); softprops/action-gh-release
# expands it. Confirm it expands to both a wheel and an sdist.
matched=$(ls $DIST_FILES 2>/dev/null) || { echo "::error::DIST_FILES ('$DIST_FILES') matched nothing"; exit 1; }
printf '%s\n' "$matched" | grep -q '\.whl$'     || { echo "::error::DIST_FILES ('$DIST_FILES') did not match a wheel; matched: $matched"; exit 1; }
printf '%s\n' "$matched" | grep -q '\.tar\.gz$' || { echo "::error::DIST_FILES ('$DIST_FILES') did not match an sdist; matched: $matched"; exit 1; }

echo "[OK] wheel + sdist built and covered by DIST_FILES"
