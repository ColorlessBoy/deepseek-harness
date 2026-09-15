#!/usr/bin/env bash
# Point a dsh profile at this repository's profile directory, then install its plugins.
#
# Usage: ./my-agent/setup.sh [profile-name]   # default: web
#
# Creates $DSH_HOME/profiles/<profile> as a symlink to my-agent/profile, so the
# branch's package.json / pnpm-lock.yaml / cordis.patch.yml ARE the live profile,
# and runs pnpm install there. Re-run it after a branch switch or pull that
# changed the manifest or lockfile (my-agent/dsh.sh does this for you).
set -euo pipefail

PROFILE="${1:-web}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED="$HERE/profile"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
DEST="$DSH_HOME_DIR/profiles/$PROFILE"
SEED_REAL="$(cd "$SEED" && pwd -P)"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "error: pnpm not found. Install it first, e.g. 'corepack enable'." >&2
  exit 1
fi

mkdir -p "$DSH_HOME_DIR/profiles"

if [ -L "$DEST" ]; then
  if [ "$(cd "$DEST" && pwd -P)" != "$SEED_REAL" ]; then
    echo "error: $DEST is a symlink to $(cd "$DEST" && pwd -P), not $SEED_REAL." >&2
    echo "Remove it and re-run." >&2
    exit 1
  fi
elif [ -e "$DEST" ]; then
  echo "error: $DEST exists and is not a symlink to $SEED_REAL." >&2
  echo "Move it aside and re-run so dsh can manage it." >&2
  exit 1
else
  ln -s "$SEED" "$DEST"
  echo "linked $DEST -> $SEED"
fi

echo "installing plugins for profile '$PROFILE' from the committed lockfile ..."
(cd "$SEED" && pnpm install)

# dsh supplies @deepseek-ai/* to out-of-tree plugins through
# $DSH_HOME/profiles/node_modules, which Node's lookup only reaches while the
# profile sits under that directory. This profile lives in the repo, so link the
# fallback beside it at the one path its lookup does walk through.
FALLBACK="$DSH_HOME_DIR/profiles/node_modules"
mkdir -p "$FALLBACK"
if [ -e "$HERE/node_modules" ] && [ ! -L "$HERE/node_modules" ]; then
  echo "error: $HERE/node_modules exists and is not a symlink; remove it and re-run." >&2
  exit 1
fi
ln -sfn "$FALLBACK" "$HERE/node_modules"

echo
echo "done. start with:"
echo "  bash my-agent/dsh.sh $PROFILE"
