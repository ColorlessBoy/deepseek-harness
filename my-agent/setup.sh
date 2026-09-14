#!/usr/bin/env bash
# Restore a dsh profile from this committed seed on a new machine.
#
# Usage: ./my-agent/setup.sh [profile-name]   # default: web
#
# Copies the pinned manifest (package.json / pnpm-lock.yaml / pnpm-workspace.yaml /
# cordis.yml) into $DSH_HOME/profiles/<profile> and installs the exact plugin set.
# An existing local cordis.patch.yml is preserved unless --force is passed.
set -euo pipefail

PROFILE="${1:-web}"
FORCE="${2:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED="$HERE/profile"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
DEST="$DSH_HOME_DIR/profiles/$PROFILE"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "error: pnpm not found. Install it first, e.g. 'corepack enable'." >&2
  exit 1
fi

mkdir -p "$DEST"

cp "$SEED/package.json" "$SEED/pnpm-lock.yaml" "$SEED/pnpm-workspace.yaml" "$SEED/cordis.yml" "$DEST/"

if [ -f "$DEST/cordis.patch.yml" ] && [ "$FORCE" != "--force" ]; then
  echo "kept existing $DEST/cordis.patch.yml (pass --force to overwrite)"
else
  cp "$SEED/cordis.patch.yml" "$DEST/"
fi

echo "installing plugins into profile '$PROFILE' at $DEST ..."
(cd "$DEST" && pnpm install)

echo
echo "done. verify with:"
echo "  dsh --profile $PROFILE --dump-config"
echo "start with:"
echo "  dsh --profile $PROFILE"
