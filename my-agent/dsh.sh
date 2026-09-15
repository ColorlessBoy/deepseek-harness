#!/usr/bin/env bash
# Run dsh against this repository's profile in one command: link, install, launch.
#
# Usage: ./my-agent/dsh.sh [profile] [dsh args...]   # default profile: web
#
# The profile is a symlink into my-agent/profile, so whatever branch you have
# checked out is what dsh boots. pnpm install runs on every launch so a branch
# switch or pull that changed pnpm-lock.yaml takes effect before boot.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-web}"
shift || true

bash "$HERE/setup.sh" "$PROFILE"

cd "$HERE/.."
exec pnpm dsh --profile "$PROFILE" "$@"
