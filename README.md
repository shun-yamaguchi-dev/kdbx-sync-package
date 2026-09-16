# KDBX Sync

KDBX Sync watches a local and a remotely synced copy of a KeePass database, then uses KeePassXC to merge changes in either direction. It uses launchd on macOS and keeps the database, key file, and synchronization storage under your control.

## Requirements

- macOS 13 or later
- KeePassXC command-line executable
- `fswatch`

## Install

From the repository root:

```bash
./scripts/install.sh
```

This installs the app in `~/Applications/KDBX Sync.app` and the `kdbx-sync` command in `~/.local/bin`. Ensure that directory is on your `PATH`.

## First-time setup

Create the global configuration once. Supply absolute paths to the KeePassXC executable and `fswatch`:

```bash
kdbx-sync init \
  --keepassxc /Applications/KeePassXC.app/Contents/MacOS/keepassxc \
  --fswatch /opt/homebrew/bin/fswatch
```

Optional timings are in seconds and default to `2`, `2`, and `5`:

```bash
kdbx-sync init \
  --keepassxc /absolute/path/to/keepassxc \
  --fswatch /absolute/path/to/fswatch \
  --push-debounce 2 \
  --pull-debounce 2 \
  --ignore-window 5
```

The command creates `~/.config/kdbx-sync/config.toml`. It will not overwrite an existing configuration.

## Vault commands

Add a vault, then enable it when its paths are correct:

```bash
kdbx-sync vault add personal \
  --local-path /absolute/path/to/local.kdbx \
  --local-watch-path /absolute/path/to/local-directory \
  --remote-path /absolute/path/to/remote.kdbx \
  --remote-watch-path /absolute/path/to/remote-directory \
  --keyfile-path /absolute/path/to/keyfile

kdbx-sync vault enable personal
```

Other supported commands are:

```text
kdbx-sync vault list
kdbx-sync vault show NAME
kdbx-sync vault rename OLD_NAME NEW_NAME
kdbx-sync vault disable NAME
kdbx-sync vault remove NAME
```
