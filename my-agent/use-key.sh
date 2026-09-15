#!/usr/bin/env bash
# Switch which OpenCode Go key dsh sends on requests.
#
# Usage: bash my-agent/use-key.sh <pool-name>   # e.g. qq, gmail
#
# Copies OPENCODE_GO_KEY_<name>'s value into OPENCODE_API_KEY (the reference the
# llm-pi-ai routes resolve) and points OPENCODE_GO_KEY_ACTIVE at the name so the
# usage widget marks it. The credential store reloads the file, so the next
# request uses the new key with no restart.
set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: bash my-agent/use-key.sh <pool-name>" >&2
  exit 2
fi

node --input-type=module -e '
import { readFileSync, writeFileSync, chmodSync } from "node:fs"
import { join } from "node:path"
const [name, dshHome] = process.argv.slice(1)
const path = join(dshHome, ".credentials.yaml")
let text = readFileSync(path, "utf8")
const found = text.match(new RegExp("^  OPENCODE_GO_KEY_" + name + ":\\s*(.+)$", "m"))
if (found === null) {
  console.error("no OPENCODE_GO_KEY_" + name + " in " + path)
  process.exit(1)
}
const value = found[1].trim()
text = text.replace(/^  OPENCODE_API_KEY:.*$/m, "  OPENCODE_API_KEY: " + value)
text = /^  OPENCODE_GO_KEY_ACTIVE:.*$/m.test(text)
  ? text.replace(/^  OPENCODE_GO_KEY_ACTIVE:.*$/m, "  OPENCODE_GO_KEY_ACTIVE: \"" + name + "\"")
  : text.replace(/(^  OPENCODE_GO_KEY_[^\n]*\n)/m, "$1  OPENCODE_GO_KEY_ACTIVE: \"" + name + "\"\n")
writeFileSync(path, text)
chmodSync(path, 0o600)
console.log("active OpenCode Go key -> " + name)
' "$NAME" "${DSH_HOME:-$HOME/.dsh}"
