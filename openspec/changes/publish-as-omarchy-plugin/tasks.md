# Tasks

## 1. Migrate this machine off `local.radio-sg` (do first, with the current tree)

- [x] 1.1 Stop the radio, run the current `./uninstall.sh`, and confirm the old install is gone: no `~/.config/omarchy/plugins/local.radio-sg`, no `~/.local/bin/omarchy-radio`, no `~/.local/share/omarchy-radio`, `omarchy-radio` not running, and `~/.config/omarchy/shell.json` identical to the snapshot taken before the original install; verify with `ls`, `pgrep -x mpv` and `diff`

## 2. Restructure the repo as an Omarchy plugin (`installation`)

- [x] 2.1 `git mv plugin/manifest.json plugin/RadioWidget.qml .`, remove `plugin/`, set the manifest `id` to `winston.radio-sg` and the widget `moduleName` to match; verify `omarchy plugin validate .` passes from the repo root and `git grep local.radio-sg -- . ':!openspec/changes/archive'` finds only intentional mentions
- [x] 2.2 Commit the restructure so a bare-path `plugin add` can clone it; verify `git status` is clean and `git log -1` shows it

## 3. Self-contained widget (`installation`)

- [x] 3.1 Point the widget at the CLI inside its own folder with `Qt.resolvedUrl("bin/omarchy-radio")` (strip `file://`), then install with `omarchy plugin add <checkout> --enable --yes` and confirm the widget shows the playback state and the popup card works with `~/.local/bin/omarchy-radio` absent (`omarchy-radio` not on PATH); if the path does not resolve, apply the D3 contingency and note it in design.md; verify by region screenshots of the bar and the open card while a station plays at low volume
- [x] 3.2 Verify the update path: commit a small visible change to the checkout, run `omarchy plugin update winston.radio-sg` and `omarchy restart shell`, and confirm the bar runs the new version and its bar entry is unchanged; then revert that change and update again

## 4. PATH helper scripts (`installation`)

- [x] 4.1 Rewrite `install.sh`: prerequisite check (tools and `omarchy plugin` support; exit non-zero naming what is missing, changing nothing), then symlink `~/.local/bin/omarchy-radio` to `<script folder>/bin/omarchy-radio`, idempotently, refusing to replace a file it did not create; verify in `test/install.test.sh` (temp `$HOME`, stubbed `omarchy`) for link created, repeat run, target followed after an update, collision refused with the foreign file untouched, missing tool named, and unsupported Omarchy explained
- [x] 4.2 Rewrite `uninstall.sh`: stop playback and remove only the link it created; succeed with "Nothing to do" when absent; verify tests for full uninstall, link absent, and a foreign file left alone
- [x] 4.3 Add a test that the repo root passes the real `omarchy-plugin-validate` (skipped with a note when the command is not installed); verify `test/run.sh` is green

## 5. Docs (`installation`)

- [x] 5.1 Rewrite the README "Install" section: requirements, `omarchy plugin add <git-url> --enable`, update (`omarchy plugin update` and `omarchy restart shell`), remove (`omarchy-radio stop`, `omarchy plugin remove winston.radio-sg --yes`), the optional PATH helper, and the development workflow (commit, add from a local path); update every other mention of the old id, the `plugin/` path and the copy-based installer, and the `omarchy bar move` example; verify each documented command runs as written on this machine (dev workflow with the local path)

## 6. Integration on this machine

- [x] 6.1 Final pass from a clean state: `omarchy plugin remove winston.radio-sg --yes`, confirm `shell.json` is identical to the snapshot, then `omarchy plugin add <checkout> --enable --yes` and `./install.sh`; verify the widget, popup card, scroll volume and a station play work, `omarchy-radio` runs from a terminal, and `test/run.sh` and `openspec validate --strict` pass
- [x] 6.2 Leave the machine in a good state (widget installed and enabled, radio stopped, volume low) and commit the work on `master` with no remote and no push; verify `git remote -v` prints nothing and `git status` is clean
