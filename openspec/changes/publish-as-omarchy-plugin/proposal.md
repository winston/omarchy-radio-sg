# Proposal

## Why

The plugin is built for one machine: it lives in a `plugin/` subfolder, uses the
`local.` id, and installs with a copy-based `install.sh`. Omarchy's documented plugin
model is different: a git repo with `manifest.json` at its root, an
`<author>.<name>` id, installed with `omarchy plugin add <git-url> --enable`,
updated with `omarchy plugin update`, removed with `omarchy plugin remove`. Matching
it lets anyone install the plugin from the repo URL in one command, and makes the
repo publishable as-is.

## What Changes

- **Repo root becomes the plugin.** `manifest.json` and `RadioWidget.qml` move from
  `plugin/` to the repo root (`plugin/` is deleted). `bin/omarchy-radio` and
  `stations.json` stay where they are. The whole clone is the plugin folder, which
  `omarchy plugin validate` accepts (checked on a simulated clone).
- **Rename the id** from `local.radio-sg` to `winston.radio-sg`, following the
  `<author>.<name>` convention (Omarchy names clones `<username>.<name>` too). The
  widget's module name changes with it.
- **The widget finds the CLI inside its own folder** (relative to the QML file)
  instead of `~/.local/bin`, so `omarchy plugin add` alone gives a working widget.
  The CLI already finds `stations.json` next to itself.
- **Install, update and remove go through Omarchy**: `omarchy plugin add <url>
  --enable`, `omarchy plugin update` (then `omarchy restart shell`), and
  `omarchy plugin remove`. Adding from a local checkout works the same way
  (`omarchy plugin add /path/to/checkout`, which a bare path is allowed for), which
  is the development workflow.
- **`install.sh` and `uninstall.sh` shrink to an optional helper** that links
  `omarchy-radio` into `~/.local/bin` (for terminals and keybindings) and removes the
  link and stops playback. They no longer copy files or touch the plugin folder.
- **BREAKING (one machine):** the installed `local.radio-sg` widget and its bar
  entry are replaced by `winston.radio-sg`. The author's machine is migrated once
  (remove the old install first, then add the new one); no other installs are known.
- README install, update, remove and development sections are rewritten to match.

Non-goals: publishing or pushing the repo (still local-only), a Waybar adapter,
splitting the plugin into its own repo or branch, and any change to playback,
stations or the popup card.

## Capabilities

### New Capabilities
<!-- None: all the behavior lives in the existing installation capability. -->

### Modified Capabilities
- `installation`: install, update and removal become Omarchy's plugin commands; the
  plugin folder is self-contained; the scripts become an optional PATH helper.
  Removes "Idempotent install" (replaced by "Installable as an Omarchy plugin") and
  rewrites "Non-destructive to user configuration", "Prerequisite check" and "Clean
  uninstall" for the helper. Adds "Self-contained plugin folder" and "Optional
  command-line access".

## Impact

- **Files moved or deleted:** `plugin/manifest.json`, `plugin/RadioWidget.qml`
  (to the root); `plugin/` removed.
- **Files rewritten:** `install.sh`, `uninstall.sh`, `test/install.test.sh`, the
  README, the manifest id and the widget's module name and CLI path.
- **Touches the user's system:** at migration, the old `local.radio-sg` folder,
  `~/.local/bin/omarchy-radio` and `~/.local/share/omarchy-radio/` (removed with the
  current `uninstall.sh`); afterwards the new plugin folder (created by `omarchy
  plugin add`) and, optionally, a symlink in `~/.local/bin`. `shell.json` is changed
  only by Omarchy's own commands.
- **Dependencies:** unchanged (`mpv`, `socat`, `jq`, `curl`, Omarchy 4).
- **Risks:** installs no longer check prerequisites, so a missing tool shows up only
  when the CLI first runs (the helper and README cover this); the plugin folder now
  contains the whole repo (about 1 MB of tests, specs and docs); and the widget's
  path lookup must be proven to work in the live shell (design D3).
