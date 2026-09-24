# Tasks

## 1. Repo scaffolding and test harness

- [x] 1.1 Create `bin/`, `plugin/`, `test/`, and `test/fixtures/stations.json` (one `av://lavfi:sine=frequency=440` entry plus one more, for offline tests); verify `ls` shows the layout
- [x] 1.2 Add `test/run.sh`, a tiny bash assert harness that runs every `test/*.test.sh` in a temp `$HOME` and `$XDG_RUNTIME_DIR`; verify `test/run.sh` runs and reports 0 tests
- [x] 1.3 Add `.gitignore` and a README "Development" section on how to run the tests; verify the documented command runs as written

## 2. Station catalog (`station-catalog`)

- [x] 2.1 Re-verify the chosen ten stations (88.3, 90.5, 92.4, 93.3, 95.0, 95.8, 96.3, 97.2, 98.7, 100.3) with `curl -I` and a fresh `mpv --no-video --ao=null --length=3 <url>` using the `livestream-redirect` URLs in design.md; do not touch the meLISTEN API; verify every kept URL has a passing mpv run
- [x] 2.2 Write `stations.json` with only verified stations (`id`, `name`, `freq`, `operator`, `language`, `url`), in a sensible display order; verify `jq` parses it and every entry has all fields with unique ids
- [x] 2.3 Add a "Stations" section to the README listing what is included and the source of the URLs (fmstream.org, at development time only) and the date they were verified; verify it matches `stations.json`

## 3. Playback CLI (`radio-playback`)

- [x] 3.1 Implement the `omarchy-radio` skeleton: strict mode, dependency check (`mpv`, `socat`, `jq`, `curl`) with a clear error, station file resolution (`$OMARCHY_RADIO_STATIONS`, data dir, next to the script), `list`, and a header marker comment; verify `omarchy-radio list` prints the stations and a missing tool gives a named error in a test
- [x] 3.2 Implement the mpv IPC helper (`socat` JSON command and `get_property`) and stale-socket detection; verify a test with a dead socket file reports `stopped` and that a later `play` cleans it up
- [x] 3.3 Implement `play <id>`: spawn with `setsid`, `--no-video --no-terminal --input-ipc-server`, `--volume` from the saved volume (default 50), or `loadfile … replace` when running; unknown id is an error that leaves playback alone; verify tests for start, switch (one player process only), unknown id, and survival after the caller exits
- [x] 3.4 Implement `toggle`, `stop` and `volume <N|+N|-N>` (clamped 0–100, saved to `$XDG_STATE_HOME/omarchy-radio/volume`, no-op success when idle); verify tests for pause/resume, toggle when stopped, clamp at 100 and 0, relative steps, idempotent stop, and no leftover process or socket after stop
- [x] 3.5 Implement `status` JSON (`class`, `text`, `tooltip`, `station`, `name`, `volume`; station found by URL, ICY title added to the tooltip when mpv reports one); verify tests for playing, paused and stopped output shapes and that `status` is read-only and returns in well under 100 ms with `time`
- [x] 3.6 Implement `check [--play]` per design D7 (non-zero exit, failing stations named); verify against the fixture file (pass) and a fixture with a bad URL (fail)
- [x] 3.7 Document the CLI (usage block in `--help` and a README "CLI" section); verify `omarchy-radio --help` matches the README

## 4. Station picker (`station-picker`)

- [x] 4.1 Implement `pick` using `omarchy-menu-select` with `glyph<TAB>name<TAB>freq · operator` rows, a distinct glyph for the current station, and a label-to-id map; cancel (exit 1) changes nothing. To keep it testable, `pick` reads the selector command from `$OMARCHY_RADIO_SELECT` (default `omarchy-menu-select`); verify tests with a fake selector for choose, cancel, and the current-station marker
- [x] 4.2 Run `omarchy-radio pick` in the live shell on this machine and verify the menu opens, filters by typing, and plays the chosen station audibly

## 5. Bar widget (`bar-widget`)

- [x] 5.1 Write `plugin/manifest.json` (`id: local.radio-sg`, kind `bar-widget`, category Media, `allowMultiple: false`) and check it with `omarchy plugin validate`; verify it validates
- [x] 5.2 (left click superseded by group 7) Write `plugin/RadioWidget.qml`, modelled on `omarchy.microphone`: `Timer` and `Process` polling `omarchy-radio status` every 2 s, glyphs for playing, paused and stopped, station label (hidden on vertical bars), tooltip, and the four mouse mappings (left = pick, scroll = `volume ±5`, right = `stop`, middle = `toggle`), each followed by an immediate refresh; verify by loading the plugin in the live shell and checking each scenario in the `bar-widget` spec by hand
- [x] 5.3 Confirm the CLI is reachable from the shell's environment (PATH or an absolute `$HOME` path) and that an external `omarchy-radio stop` from a terminal shows in the widget within a few seconds; verify both, and fix the QML if the first fails
- [x] 5.4 Add a README "Bar widget" section describing the interactions, plus a screenshot or ASCII description; verify the described interactions match what was observed in 5.2

## 6. Installer (`installation`)

- [x] 6.1 Write `install.sh`: prerequisite check (tools, `omarchy` plugin commands; exit non-zero and change nothing if missing), copy the CLI and stations, copy the plugin dir with the `.omarchy-radio-sg` marker, refuse to overwrite unmarked files, then `omarchy-shell shell rescanPlugins` and `omarchy plugin enable local.radio-sg`; verify it in a temp `$HOME` test for first install, repeat install (no duplicates), update in place, and name collision
- [x] 6.2 Write `uninstall.sh`: stop playback, `omarchy plugin disable`, remove only marked files, succeed with "nothing to do" when absent; verify tests for full uninstall, partial install, and not-installed
- [x] 6.3 Verify the round trip on this machine: snapshot `~/.config/omarchy/shell.json`, run install then uninstall, and diff it (no differences beyond what `omarchy bar` restores; resolve any that remain); verify the diff is empty
- [x] 6.4 Update the README with "Install / Uninstall / Requirements" (Omarchy 4+, the unsandboxed-plugin warning, and that this targets `omarchy-shell`, not Waybar); verify each documented command runs as written

## 7. Popup card (`bar-widget`, `radio-playback`, `station-catalog`)

- [ ] 7.1 Add `omarchy-radio list --json` (compact array of `id`, `name`, `freq`, `operator`, in file order; the plain `list` stays as is) and add `freq`/`title` handling to `status` so `title` is present only when the stream reports one; verify with cli tests for the JSON shape and order, `title` present and absent (fixture streams have no ICY title, so check the absent case, and the present case against a real station by hand), and update `--help` and the README CLI section so `diff` of the usage block still passes
- [ ] 7.2 Add the popup card to `plugin/RadioWidget.qml`: `PopupCard` anchored to the button and bound to `popupOpen`, built like `omarchy.media`'s card (header with station, `freq FM · state` and song title; play/pause `Button`, disabled when stopped; volume `PanelSlider` sending `volume N` on release; `PanelSeparator`, "STATIONS" `PanelSectionHeader`, and a selectable row per station with the current one highlighted); left click toggles it instead of running `pick`; stations loaded once from `list --json`; polling 1 s while open; verify with region screenshots of the popup while stopped, playing (with a song title) and paused, and that a third-party plugin can import the `qs.Ui` classes used
- [ ] 7.3 Check the popup behaviours by hand and report each: clicking a station plays it and the card stays open, play/pause and slider work, external `omarchy-radio` changes show within a couple of seconds, the card closes on outside click and Escape, and it looks consistent with the network popup (same card border, fonts, colors, row style, in the current theme); verify by screenshot comparison with the network popup and the user's confirmation
- [ ] 7.4 Update the README "Bar widget" section (left click opens the popup card and what it contains; `omarchy-radio pick` is for keybindings and terminals, with a sample Hyprland bind) and note the internal `qs.Ui` dependency; verify every interaction in the table matches 7.3

## 8. Integration check

- [x] 8.1 Run `test/run.sh` end to end and `omarchy-radio check --play` on the shipped stations; verify all green and record any station that fails
- [ ] 8.2 On this machine, after group 7: install, open the popup card, play a station from its list, change volume with the slider and by scroll, pause, stop, and uninstall; verify each spec scenario in `openspec/changes/add-sg-radio-plugin/specs/` holds and run `openspec validate add-sg-radio-plugin`
- [x] 8.3 Confirm the repo is still local-only (`git remote -v` prints nothing) and commit the work on a branch, with no push; verify `git log` shows the commits and `git status` is clean
