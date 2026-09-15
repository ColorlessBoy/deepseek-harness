#!/usr/bin/env bash
# Undo apply.sh: restore the profile's cordis.patch.yml from the snapshot it took.
#
# Restores byte-for-byte what apply.sh captured, then removes the snapshot so a
# later apply can run again. Idempotent: with no snapshot present it reports
# nothing to roll back and exits 0.
#
# Usage:  bash rollback.sh
#         PROFILE=tui bash rollback.sh
set -euo pipefail

PROFILE="${PROFILE:-web}"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
TARGET="$DSH_HOME_DIR/profiles/$PROFILE/cordis.patch.yml"
SNAPSHOT="$TARGET.pre-opencode-go-duplicate.bak"

if [ ! -f "$SNAPSHOT" ]; then
  echo "nothing to roll back: no snapshot at $SNAPSHOT"
  exit 0
fi
if [ ! -f "$TARGET" ]; then
  echo "error: snapshot exists but $TARGET is missing; restore the snapshot manually" >&2
  exit 1
fi

cp "$SNAPSHOT" "$TARGET"
rm -f "$SNAPSHOT"
echo "restored $TARGET from $SNAPSHOT (snapshot removed)"
