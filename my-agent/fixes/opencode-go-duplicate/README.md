# Fix: duplicate `opencode-go` plugin entry

## Symptom

The profile reports the entry id `opencode-go` twice (`dsh-opencode-go` / user-patch), and `dsh web` no longer starts.

## Cause

`dsh-opencode-go` ships its own `cordis.patch.yml`, which inserts the `opencode-go` row. The profile's own `cordis.patch.yml` still carried a leftover `- insert:` block from when the plugin was installed as a local `file:` dependency, so the same id was inserted twice.

## Fix

Remove only the leftover `insert` block from the profile's user patch. The `- id: opencode-go` config row (`keyNames`) stays, and the bundle still inserts the row.

Files touched: `$DSH_HOME/profiles/<profile>/cordis.patch.yml` only.

## Use

From the repository root (or anywhere):

```sh
bash my-agent/fixes/opencode-go-duplicate/apply.sh     # snapshot + remove the duplicate insert
pnpm dsh --profile web --dump-config | grep -c 'id: opencode-go'   # expect 1
bash my-agent/dsh.sh web                                # start dsh
```

Undo:

```sh
bash my-agent/fixes/opencode-go-duplicate/rollback.sh
```

- `apply.sh` writes a snapshot next to the file (`cordis.patch.yml.pre-opencode-go-duplicate.bak`) before changing anything, refuses to overwrite an existing snapshot, and is a no-op when the fix is already in place.
- `rollback.sh` restores that snapshot byte-for-byte and removes it; with no snapshot it reports nothing to roll back and exits 0.
- Neither script touches bundles, dependencies, services, or restarts anything. A different profile: `PROFILE=<name> bash apply.sh`.
