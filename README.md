# KDBX Sync

KDBX Sync watches a local and a remotely synced copy of a KeePass database, then uses KeePassXC to merge changes in either direction. It uses launchd on macOS and keeps the database, key file, and synchronization storage under your control.

## Philosophy

KDBX Sync is designed for a simple workflow: **keep working with KeePass normally, without having to think about synchronization.**

A typical setup has two copies of the same KeePass database:

```
Your Mac
└── Local KeePass database
          ↕
      KDBX Sync
          ↕
Synced storage
└── Remote KeePass database
```

The local database can be used directly by KeePassXC, while the remote copy can live in a synchronization service or another location that you control. KDBX Sync watches both sides and uses KeePassXC to merge changes when either side changes.

This is useful when you want to:

- keep a working KeePass database in a location optimized for your local workflow;
- keep another copy in a synchronized storage location;
- make changes from either side without manually running merge commands;
- avoid depending on a proprietary password-manager synchronization service;
- keep control over where the database, key file, and synchronization data are stored.

KDBX Sync is deliberately a **synchronization coordinator**, not a password manager or a storage service. It does not replace KeePassXC, manage your passwords, or provide cloud storage. It connects the tools you already use and automates the synchronization workflow around them.

The macOS application exists to turn this previously script-based workflow into a manageable application. It provides configuration management, Login Item integration, and LaunchAgent lifecycle management while keeping the underlying synchronization runtime simple and transparent.

## Requirements

- macOS 13 or later
- KeePassXC command-line executable
- `fswatch`

KDBX Sync bundles its synchronization runtime inside the application. KeePassXC and `fswatch` remain external dependencies and their absolute paths are stored in the KDBX Sync configuration.

## Install

From the repository root:

```shell
./scripts/install.sh
```

This installs:

```
~/Applications/KDBX Sync.app
~/.local/bin/kdbx-sync
```

Ensure `~/.local/bin` is on your `PATH`.

The application bundle contains the synchronization runtime, so the installed LaunchAgents do not depend on the runtime scripts remaining in the source repository.

## First-time setup

### Initialize configuration

Create the global configuration once. Supply absolute paths to the KeePassXC executable and `fswatch`:

```shell
kdbx-sync init \
  --keepassxc /Applications/KeePassXC.app/Contents/MacOS/keepassxc \
  --fswatch /opt/homebrew/bin/fswatch
```

Optional timings are specified in seconds:

```shell
kdbx-sync init \
  --keepassxc /absolute/path/to/keepassxc \
  --fswatch /absolute/path/to/fswatch \
  --push-debounce 2 \
  --pull-debounce 2 \
  --ignore-window 5
```

The defaults are:

```
push_debounce = 2
pull_debounce = 2
ignore_window = 5
```

The command creates:

```
~/.config/kdbx-sync/config.toml
```

It will not overwrite an existing configuration.

### Add a vault

Add a vault by providing its local database, remote database, watch directories, and key file:

```shell
kdbx-sync vault add personal \
  --local-path /absolute/path/to/local.kdbx \
  --local-watch-path /absolute/path/to/local-directory \
  --remote-path /absolute/path/to/remote.kdbx \
  --remote-watch-path /absolute/path/to/remote-directory \
  --keyfile-path /absolute/path/to/keyfile
```

New vaults are disabled initially.

### Enable a vault

Once the paths are correct:

```shell
kdbx-sync vault enable personal
```

Enabling a vault performs the initial synchronization check and then installs its push and pull LaunchAgents.

If both database files already exist and contain different contents, KDBX Sync reports a conflict rather than automatically choosing one side.

## Vault management

List configured vaults:

```shell
kdbx-sync vault list
```

Show a vault's configuration:

```shell
kdbx-sync vault show NAME
```

Rename a vault:

```shell
kdbx-sync vault rename OLD_NAME NEW_NAME
```

Disable a vault:

```shell
kdbx-sync vault disable NAME
```

Remove a vault:

```shell
kdbx-sync vault remove NAME
```

Vault names are human-readable identifiers and can be changed. Each vault also has a stable UUID that KDBX Sync uses to identify its LaunchAgents.

For each enabled vault, push and pull are managed as separate LaunchAgents.

## Login Item

KDBX Sync can register the application itself as a macOS Login Item:

```shell
kdbx-sync login-item enable
```

Check its status:

```shell
kdbx-sync login-item status
```

Disable it:

```shell
kdbx-sync login-item disable
```

The Login Item is the application coordinator. It is not the synchronization worker itself.

At login, macOS launches `KDBX Sync.app`, which reconciles the configured vaults with launchd and restores any required push and pull LaunchAgents.

Starting KDBX Sync at login does **not** perform an initial database synchronization. Initial synchronization is performed when a vault is enabled.

## How it works

KDBX Sync consists of a macOS application and two independent synchronization workflows for each enabled vault:

```
macOS Login
    │
    ▼
KDBX Sync.app
    │
    ▼
Configuration
    │
    ▼
LaunchAgent management
    │
    ├───────────────┐
    ▼               ▼
   Push            Pull
LaunchAgent     LaunchAgent
    │               │
    ▼               ▼
Push runner      Pull runner
    │               │
    ▼               ▼
Push operation   Pull operation
    │               │
    └───────┬───────┘
            ▼
         KeePassXC
```

Push and pull remain separate workflows so that a change on one side does not require a single monolithic synchronization process.

The applicatio manage the lifecycle of the LaunchAgents, while the bundled runtime performs the actual filesystem watching, debouncing, and KeePassXC merge operations.

## Files and directories

KDBX Sync uses the following locations:

```
~/Applications/KDBX Sync.app
    Installed application and bundled runtime

~/.local/bin/kdbx-sync
    Command-line entry point

~/.config/kdbx-sync/config.toml
    KDBX Sync configuration

~/Library/LaunchAgents/
    Generated push and pull LaunchAgent plists

~/.local/state/kdbx-sync/
    Per-vault runtime state and synchronization logs
```

The database files and key files are **not** stored inside KDBX Sync. Their locations are specified by each vault's configuration.

## Updating

To update an existing installation, run:

```shell
./scripts/install.sh
```

The installer rebuilds the application and replaces the installed `.app` bundle.

Existing configuration, Login Item registration, and LaunchAgent state are kept separately from the application bundle. Reinstalling the application therefore does not require recreating the vault configuration or manually reinstalling its LaunchAgents.

## Troubleshooting

Check whether the Login Item is enabled:

```shell
kdbx-sync login-item status
```

Check configured vaults:

```shell
kdbx-sync vault list
```

Inspect a vault:

```shell
kdbx-sync vault show NAME
```

Inspect the generated LaunchAgents:

```shell
ls ~/Library/LaunchAgents/com.kdbx.*.plist
```

Inspect synchronization state and logs:

```shell
ls ~/.local/state/kdbx-sync/
```

If a vault is not supposed to synchronize, disable it:

```shell
kdbx-sync vault disable NAME
```
