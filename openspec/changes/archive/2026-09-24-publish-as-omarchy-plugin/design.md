# Design

## Context

See `proposal.md` for motivation. Findings from this machine (Omarchy 4.0.4), read
from `omarchy-plugin-add`, `omarchy-plugin-validate`, `omarchy-plugin-remove` and
Omarchy's plugin README:

- `omarchy plugin add <git-url> [--enable] [--yes]` clones the repo to a staging
  dir, runs `omarchy plugin validate` on it, then moves it to
  `~/.config/omarchy/plugins/<manifest id>/`. Adding an existing id is refused.
- `omarchy plugin update [id]` fast-forwards that git checkout; the shell keeps an
  already-loaded widget until it restarts (observed while building the popup).
- The URL guard (`omarchy-git-url-check`) refuses `--options` and `helper::`
  transports but allows bare paths, so `omarchy plugin add /path/to/checkout` works.
  A clone contains only committed files.
- Validation: manifest at the root, valid `id` (not `omarchy.*`), existing relative
  entry points, and **no symlinks anywhere in the folder**. A simulated clone of this
  repo with `manifest.json` and `RadioWidget.qml` copied to the root passes
  (whole repo about 1.2 MB).
- `omarchy plugin remove --yes` on a git-cloned folder deletes it; on a non-git
  folder it moves it to a hidden `.bak` copy (why the old installer did its own removal).
- The CLI already resolves `stations.json` next to itself (`bin/../stations.json`,
  via `readlink -f`), so it works from inside a plugin folder and through a symlink.

## Goals / Non-Goals

**Goals:**
- `omarchy plugin add <repo> --enable` is the whole install.
- No copying logic of our own; the scripts only do what Omarchy does not (PATH link).
- Existing behavior (playback, picker, popup card) is untouched.

**Non-Goals:**
- Publishing, pushing, or choosing a host for the repo.
- Splitting the plugin into a separate repo or branch to keep the folder small.
- Migrating other users' installs (only this machine has the old id).

## Decisions

### D1. The repo root is the plugin folder
`manifest.json` and `RadioWidget.qml` move to the root, with `entryPoints.barWidget`
`"RadioWidget.qml"`. This is the documented model ("a plugin is a git repo with a
`manifest.json` at its root"). *Alternative:* keep `plugin/` and publish it as its own
repo or a subtree. Rejected: two repos to keep in sync for a 1 MB saving. Consequence:
tests, specs and `.claude/` ship inside the plugin folder; harmless, and validated.

### D2. Id `winston.radio-sg`
Follows `<author>.<name>` (their examples: `acme.weather`; Omarchy's clone naming:
`<username>.<name>`). `local.` is legal but not the published convention. The widget's
`moduleName` must equal the id. The bar entry in `shell.json` is keyed by id, so the
old entry goes when the old plugin is disabled and the new one is added by
`plugin add --enable`; no hand edits of `shell.json`.

### D3. The widget finds the CLI relative to its own file
`readonly property string cli: Qt.resolvedUrl("bin/omarchy-radio")` with the `file://`
prefix stripped. This replaces `$HOME/.local/bin/omarchy-radio`, so nothing outside the
plugin folder is needed and PATH is irrelevant. It is unproven for third-party plugins
in this shell, so the first apply task tests it live. *Contingency if it does not
resolve to a real path:* build the path from `Quickshell.env("HOME")` and the fixed,
documented plugin dir `~/.config/omarchy/plugins/winston.radio-sg/bin/omarchy-radio`.

### D4. Scripts become an optional PATH helper
`install.sh` (kept name, so existing habits and docs stay valid) now only: checks
prerequisites (D6), then symlinks `~/.local/bin/omarchy-radio` to `<its own folder>/bin/omarchy-radio`.
The symlink lives outside the plugin folder, so the "no symlinks" validation is not
affected, and `omarchy plugin update` updates what it points to. It refuses to replace
a file it did not create (a link is "ours" if it points at a `bin/omarchy-radio` that
carries the existing `omarchy-radio-sg managed` marker). `uninstall.sh` stops playback
and removes only that link. Neither touches `shell.json` or the plugin folder.
*Alternative:* drop the scripts entirely. Rejected: a terminal or keybinding needs
`omarchy-radio` on PATH, and the CLI is otherwise buried in the plugin folder.

### D5. Update and development workflows
Update: `omarchy plugin update winston.radio-sg`, then `omarchy restart shell` (the
README says so). Development: commit, then `omarchy plugin add /path/to/checkout
--enable --yes`; to iterate, edit the checkout, commit, and `omarchy plugin update`
(the plugin's git origin is the checkout) followed by a shell restart. Editing files
in the installed folder directly also works but is not reloaded without a restart.

### D6. Prerequisites are checked by the helper and the CLI, not by an installer
There is no installer in the `plugin add` path, so a missing tool is reported by the
CLI at first use (existing "Missing dependencies" behavior). The helper still checks up
front, so running it doubles as a diagnostic, and the README lists the requirements.
*Known gap:* the widget fires commands detached, so a missing `mpv` shows as
"nothing happens" from the bar; surfacing it in the widget is out of scope here.

### D7. One-time migration of this machine
Order matters because both ids cannot be installed together (same widget, same
`~/.local/bin` path): (1) with the current tree, run `./uninstall.sh`, which stops
playback, disables and deletes `local.radio-sg`, and removes the CLI and data;
(2) restructure and commit the repo; (3) `omarchy plugin add <checkout> --enable --yes`;
(4) optionally `./install.sh` for the PATH link. `shell.json` is compared with the
pre-install snapshot after step 1 and after a final remove to prove the round trip.

### D8. Testing
`test/install.test.sh` is rewritten for the helper in a throwaway `$HOME` (link
created, repeat run, follows the target, collision, missing tool, unsupported Omarchy,
uninstall variants), keeping the stubbed `omarchy` commands. A new check validates the
repo root with the real `omarchy-plugin-validate` when it is available. The QML path,
`plugin add`/`update`/`remove` and the round trip are verified live on this machine.

## Risks / Trade-offs

- **[`Qt.resolvedUrl` may not give a usable path in the shell]** → tested first (task
  3.1); documented fallback in D3.
- **[The plugin folder now holds the whole repo]** → about 1 MB, validated; noted in
  the README; no secrets in the repo (audited).
- **[No prerequisite check on `plugin add`]** → CLI errors by name, helper check,
  README requirements (D6).
- **[`plugin update` needs a shell restart]** → stated in the README and unchanged
  Omarchy behavior.
- **[Migration removes the working widget for a few minutes]** → done in one sitting
  with the radio stopped; the old install is fully restorable from git history.
- **[A bare-path `plugin add` uses committed content only]** → the workflow says
  commit first; uncommitted edits will not appear.

## Migration Plan

D7. Rollback: `omarchy plugin remove winston.radio-sg --yes`, then check out the commit
before this change and run its `./install.sh`.

## Open Questions

- None blocking. Whether to publish the repo, and where, is a later decision.
