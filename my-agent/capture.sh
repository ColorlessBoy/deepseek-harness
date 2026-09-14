#!/usr/bin/env bash
# Record the current machine's dsh profile into this committed seed.
#
# Usage: ./my-agent/capture.sh [profile-name]   # default: web
#
# Run this after 'dsh plugin --profile <name> add ...' so the new plugin set,
# its exact versions, and the lockfile are captured into git.
set -euo pipefail

PROFILE="${1:-web}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED="$HERE/profile"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
SRC="$DSH_HOME_DIR/profiles/$PROFILE"

if [ ! -d "$SRC" ]; then
  echo "error: profile '$PROFILE' not found at $SRC" >&2
  exit 1
fi

cp "$SRC/package.json" "$SRC/pnpm-lock.yaml" "$SRC/pnpm-workspace.yaml" "$SRC/cordis.yml" "$SEED/"
cp "$SRC/cordis.patch.yml" "$SEED/"

echo "captured profile '$PROFILE' into $SEED:"
echo "  $(ls "$SEED")"
echo
echo "review then commit:"
echo "  git -C \"$HERE/..\" diff -- my-agent/profile"
