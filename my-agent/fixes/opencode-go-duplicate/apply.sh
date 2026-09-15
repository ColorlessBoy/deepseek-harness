#!/usr/bin/env bash
# Fix: duplicate entry id `opencode-go` in a dsh profile's user patch.
#
# Cause: the profile's cordis.patch.yml still inserts the plugin row from when
# dsh-opencode-go was a local (file:) plugin. It is now a bundle that inserts the
# same row from its own cordis.patch.yml, so the id appears twice.
#
# This script removes ONLY that leftover insert block. It touches nothing else:
# no bundles, no dependencies, no service. Idempotent: a second run after a
# successful apply is a no-op, and the snapshot it creates is never overwritten
# (roll back first to re-apply).
#
# Usage:  bash apply.sh            # profile name from $PROFILE (default: web)
#         PROFILE=tui bash apply.sh
set -euo pipefail

PROFILE="${PROFILE:-web}"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
TARGET="$DSH_HOME_DIR/profiles/$PROFILE/cordis.patch.yml"
SNAPSHOT="$TARGET.pre-opencode-go-duplicate.bak"

if [ ! -f "$TARGET" ]; then
  echo "error: $TARGET not found" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required" >&2
  exit 1
fi

python3 - "$TARGET" "$SNAPSHOT" <<'PY'
import re
import sys
import pathlib

target = pathlib.Path(sys.argv[1])
snapshot = pathlib.Path(sys.argv[2])
text = target.read_text()
lines = text.splitlines(keepends=True)

def is_child(line: str) -> bool:
    return line[:1] in (' ', '\t') and line.strip() != ''

blocks = []
i = 0
while i < len(lines):
    if lines[i].rstrip('\n') == '- insert:':
        j = i + 1
        while j < len(lines) and is_child(lines[j]):
            j += 1
        block = ''.join(lines[i:j])
        has_id = re.search(r'^\s*-\s*id:\s*opencode-go\s*$', block, re.M)
        has_name = re.search(r'^\s*name:\s*dsh-opencode-go\s*$', block, re.M)
        if has_id and has_name:
            blocks.append((i, j))
            i = j
            continue
    i += 1

if not blocks:
    if re.search(r'^\s*-\s*id:\s*opencode-go\s*$', text, re.M):
        print('already applied: no leftover insert block; nothing to change')
        sys.exit(0)
    print('error: found neither a matching insert block nor an `opencode-go` row; inspect the file manually', file=sys.stderr)
    sys.exit(2)
if len(blocks) > 1:
    print('error: more than one matching insert block; refusing to guess', file=sys.stderr)
    sys.exit(2)
if snapshot.exists():
    print(f'error: snapshot already exists at {snapshot}; run rollback.sh first (or remove it deliberately)', file=sys.stderr)
    sys.exit(3)

out = ''.join(line for idx, line in enumerate(lines) if not (blocks[0][0] <= idx < blocks[0][1]))
remaining = len(re.findall(r'^\s*-\s*id:\s*opencode-go\s*$', out, re.M))
if remaining != 1:
    print(f'error: expected exactly one `opencode-go` row after the edit, found {remaining}; aborting before writing', file=sys.stderr)
    sys.exit(4)

snapshot.write_text(text)
target.write_text(out)
print(f'snapshot: {snapshot}')
print(f'removed 1 leftover insert block from {target}')
print(f'remaining `opencode-go` rows: {remaining}')
PY

echo
echo 'verify (read-only):'
echo "  pnpm dsh --profile $PROFILE --dump-config | grep -c 'id: opencode-go'   # expect 1"
echo 'then start with:'
echo "  bash my-agent/dsh.sh $PROFILE"
