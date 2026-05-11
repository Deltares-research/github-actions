#!/usr/bin/env bash
# Fail fast -- before the version bump, tag and push -- if a tool the release
# needs is not installed in the consumer's environment, with a message that
# says what to add. Without this check a missing 'build' surfaces only at the
# wheel step, after the bump commit and tag have already been pushed.
#
# Usage: validate-toolchain.sh <package-manager> <pixi-activate-env> <build-wheel>
#   package-manager    : uv | poetry | pixi
#   pixi-activate-env  : pixi environment to use (pixi only; '' = the default env)
#   build-wheel        : true | false
#
# Run from the directory containing the project's pyproject.toml / pixi.toml
# (the caller cds there for monorepos). Tested by
# .github/workflows/test.release.unit.yml -- keep that matrix in sync.
set -uo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <package-manager> <pixi-activate-env> <build-wheel>" >&2
  exit 2
fi

PM="$1"
PIXI_ENV="$2"
BUILD_WHEEL="$3"

# How to run a command inside the project's environment. This mirrors the
# command construction in the "Generate changelog and bump version" step so the
# preflight validates the exact environment the bump will use.
if [ "$PM" = "pixi" ]; then
  if [ -n "$PIXI_ENV" ]; then
    RUN=(pixi run -e "$PIXI_ENV")
  else
    RUN=(pixi run)
  fi
else
  RUN=("$PM" run)
fi

check_import() {
  # $1 = python module name, $2 = hint printed on failure
  local module="$1" hint="$2"
  if ! "${RUN[@]}" python -c "import $module" >/dev/null 2>&1; then
    echo "::error::Python package '$module' is not installed in your '$PM' environment."
    echo "::error::$hint"
    exit 1
  fi
  echo "$module: OK"
}

# commitizen drives the version bump and changelog; it is always required.
check_import commitizen "Add 'commitizen' to your dev dependencies (dev group / pixi manifest)."

# PyPA 'build' is only needed for the pixi wheel path; uv/poetry use their
# built-in 'uv build' / 'poetry build', so they need nothing extra.
if [ "$BUILD_WHEEL" = "true" ] && [ "$PM" = "pixi" ]; then
  check_import build "Add 'build' (conda-forge package name: 'python-build') to your pixi manifest, or set build-wheel: 'false'."
fi
