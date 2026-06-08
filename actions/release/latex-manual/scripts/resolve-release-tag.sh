#!/usr/bin/env bash
# Resolve which release tag the built PDFs should be attached to.
#
#   $1 = release-tag input  (explicit tag; wins when non-empty)
#   $2 = release-event tag  (github.event.release.tag_name; the fallback)
#
# Prints the resolved tag (possibly empty) to stdout. The explicit input wins so
# the action can attach to a known release when run from a workflow_run (where
# there is no `release` event payload); otherwise it falls back to the event tag.
#
# Tested by .github/workflows/test.release-latex-manual.unit.yml.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: resolve-release-tag.sh <release-tag-input> <release-event-tag>" >&2
  exit 2
fi

input_tag="$1"
event_tag="$2"

if [ -n "$input_tag" ]; then
  echo "$input_tag"
else
  echo "$event_tag"
fi
