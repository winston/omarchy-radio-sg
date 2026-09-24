# Proposal

## Why

Singapore's FM stations (Mediacorp's meLISTEN family and SPH's) are easiest to
reach through phone apps or browser tabs, which is awkward on a keyboard-driven
Omarchy desktop. A small native plugin lets you tune, pause and adjust volume
from the bar and menu, with no browser, no app and no window.

## What Changes

- Add a curated, hand-verified station list (`stations.json`) checked into the
  repo, with ten user-chosen stations: 88.3 Jia, Gold 905, Symphony 92.4, YES 933,
  Class 95, Capital 958, Hao 96.3, Love 972, 987FM and UFM 100.3. Every entry has
  been confirmed to serve audio; nothing is looked up at runtime.
- Add a small bash CLI, `omarchy-radio`, that plays a station in a headless
  `mpv` (`--no-video --input-ipc-server`) and controls it over the IPC socket:
  `play`, `stop`, `toggle` (pause), `volume`, `status`, `pick`.
- Add a station picker built on the Omarchy menu (`omarchy-menu-select`), which
  is the Omarchy 4 equivalent of a Walker dmenu. It is a standalone command
  (`omarchy-radio pick`) for terminals and keybindings.
- Add an `omarchy-shell` bar-widget plugin (manifest and one QML file). It shows
  the now-playing state and maps the interactions: left click opens a popup card,
  scroll changes volume, right click stops, middle click pauses. The popup card
  is styled like the network and audio popups and holds a now-playing header
  (station, frequency, state, song title), a play/pause button, a volume slider
  and the station list. It gets its state from `omarchy-radio status` and its
  stations from `omarchy-radio list --json`.
- Add idempotent `install.sh` and `uninstall.sh`. They put the scripts in
  `~/.local/bin`, link the plugin into `~/.config/omarchy/plugins/`, and enable
  it with `omarchy plugin`. They never overwrite user config.

**Platform note (differs from the original brief):** the installed Omarchy 4.0.4
has no Waybar or Walker. Its bar, launcher and menu run inside the Quickshell-based
`omarchy-shell`, which has a real plugin API (`manifest.json`, `omarchy plugin
add/enable`, `omarchy bar put`). The native shell is the only target for this
change; Waybar/Walker support is out of scope. This was confirmed with the user.
The CLI is bar-agnostic, so a Waybar adapter could be added later as its own
change.

Non-goals: runtime station discovery (radio-browser.info), the private meLISTEN
API, podcasts and on-demand content, track metadata beyond what the stream
exposes, recording, and any GitHub remote or push.

## Capabilities

### New Capabilities
- `station-catalog`: the verified station list, its schema, and the rule that
  only stations confirmed to play are included.
- `radio-playback`: the `omarchy-radio` CLI and its mpv IPC lifecycle (start,
  switch, pause, volume, stop, status).
- `station-picker`: choosing a station from the Omarchy menu.
- `bar-widget`: the `omarchy-shell` bar widget, its status display and its mouse
  interactions.
- `installation`: idempotent install and uninstall without clobbering user config.

### Modified Capabilities
<!-- None: openspec/specs/ is empty. -->

## Impact

- **New files** in this repo: `stations.json`, `bin/omarchy-radio`, `plugin/`
  (`manifest.json`, `RadioWidget.qml`), `install.sh`, `uninstall.sh`, README updates.
- **Touches the user's system only at install time:** `~/.local/bin/omarchy-radio`,
  a symlink at `~/.config/omarchy/plugins/sg.radio/`, and plugin enable state in
  `~/.config/omarchy/shell.json` (written by `omarchy plugin` and
  `omarchy bar put`, not by hand).
- **Runtime dependencies:** `mpv`, `socat`, `jq` and `curl` (all present now),
  plus `omarchy-shell` and its `omarchy` CLI.
- **Risk:** the plugin runs unsandboxed inside `omarchy-shell`. The QML is kept to
  one small file that only invokes `omarchy-radio`. Stream URLs are third-party
  and may change, so `omarchy-radio check` re-verifies them.
