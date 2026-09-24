# Design

## Context

See `proposal.md` for motivation. The findings below come from inspecting this
machine (Omarchy 4.0.4) and probing streams.

- **No Waybar or Walker.** The bar, launcher and menu are one Quickshell process,
  `omarchy-shell`. Plugins are directories with a `manifest.json` and QML. User
  plugins live in `~/.config/omarchy/plugins/<id>/`, are hot-reloaded on save,
  and are managed with `omarchy plugin {add,enable,disable,remove}`. Bar layout
  lives in `~/.config/omarchy/shell.json`, which `omarchy plugin enable` and
  `omarchy bar` edit for us.
- **Menu.** `omarchy-menu-select <prompt> [icon<TAB>label<TAB>subtext…]` is a
  dmenu-style picker rendered by the shell. It returns `label<TAB>subtext`, or
  exits 1 on cancel. The JSONC menu extension's `provider` hook only supports
  providers that are compiled into `Menu.qml` (fonts, power-profiles, apps), so
  a custom dynamic submenu is not possible without forking the menu.
- **Bar widgets** extend `Ui/BarWidget.qml` and typically wrap `BarIconButton`,
  which exposes `onPressed(button)` and `onWheelMoved(delta)`. `bar.run(cmd)`
  runs a shell command. `omarchy.microphone` is a compact reference.
- **Streams.** The station source is fmstream.org. Its country page embeds station
  ids, and a POST to `https://fmstream.org/stations2.php` (`ids`, `app=fmstream`)
  returns each station's stream URLs as JSON. The Mediacorp streams use
  `https://playerservices.streamtheworld.com/api/livestream-redirect/<MOUNT>.aac`,
  which 302-redirects to a live server, so we do not hardcode a server number.
  All ten stations below were play-tested with
  `mpv --no-video --ao=null --length=3` (rc=0) on 2026-09-24:

  | Freq | Station | Mount |
  |---|---|---|
  | 88.3 | 88.3 Jia | `883JIAAAC` |
  | 90.5 | Gold 905 | `GOLD905AAC` |
  | 92.4 | Symphony 92.4 | `SYMPHONY924AAC` |
  | 93.3 | YES 933 | `YES933AAC` |
  | 95.0 | Class 95 | `CLASS95AAC` |
  | 95.8 | Capital 958 | `CAPITAL958FMAAC` |
  | 96.3 | Hao 96.3 | `HAO_963AAC` |
  | 97.2 | Love 972 | `LOVE972FMAAC` |
  | 98.7 | 987FM | `987FMAAC` |
  | 100.3 | UFM 100.3 | `UFM_1003AAC` |

  The directory lists 45 Singapore entries, and further plain-stream candidates
  (Kiss92, One FM 91.3, Money FM 89.3, 938NOW, Warna, Ria, Oli) use the same URL form.
  They are outside the user's chosen list. The v1 list is exactly the ten rows above.
  fmstream is an undocumented internal endpoint, so it is used only for discovery
  at development time, never by the plugin at runtime. Every committed URL must
  still pass the mpv check in task 2.

## Goals / Non-Goals

**Goals:**
- Small, readable bash; one QML file of a few dozen lines.
- One source of truth for playback state (mpv itself), so the CLI, picker and
  widget can never disagree.
- Works with the stock Omarchy 4 install, using Omarchy's own commands.

**Non-Goals:**
- A Waybar or Walker adapter (a possible later change; the CLI already prints
  Waybar-shaped JSON).
- Custom menu submenu, a QML station panel, or replacing `omarchy.media`.
- Song-title tracking or scrobbling.

## Decisions

### D1. Native `omarchy-shell` plugin, not Waybar/Walker
The brief assumed Waybar and Walker, which this Omarchy does not have. Targeting
the native shell means we can test it here, and it gives us a real install path
(`omarchy plugin enable`) instead of editing dotfiles. *Alternative:* build the
Waybar and Walker version blind. Rejected: it is untestable on this machine and
targets a stack Omarchy has dropped. The user confirmed this choice.

### D2. Logic in a bash CLI (`omarchy-radio`); QML only presents and calls it
Everything testable (state, volume math, station lookup) lives in bash, so the
QML is a thin shell and any other frontend can reuse the CLI. Subcommands:
`play <id>`, `stop`, `toggle`, `volume <N|+N|-N>`, `status`, `pick`, `list`,
`check`. *Alternative:* implement state and IPC in QML with a Quickshell `Socket`.
That would be reactive (no polling) but makes the logic untestable outside the
shell, and there is no CLI or picker reuse.

### D3. mpv over a Unix socket; mpv is the state store
`mpv --no-video --no-terminal --idle=no --input-ipc-server=$XDG_RUNTIME_DIR/omarchy-radio.sock <url>`,
started with `setsid` so it outlives the caller. Commands go through
`socat - UNIX-CONNECT:$SOCK` as one-line JSON. The command `status` asks mpv for `path`,
`pause` and `volume`, and maps `path` back to a station by URL in `stations.json`.
There is no separate state file to drift. *Alternative:* a pid or state file. Rejected:
it goes stale and needs its own cleanup logic. Consequences:
- A dead socket file is treated as `stopped` (connect fails), and `play` removes it.
- `play` on a running player sends `loadfile <url> replace` instead of respawning,
  which is gapless for volume and avoids the socket race.
- Volume survives stop and play: the last value is kept in
  `$XDG_STATE_HOME/omarchy-radio/volume` and passed as `--volume` on spawn.
  Default 50, so a first play is never at full blast.

### D4. Picker via `omarchy-menu-select`
`pick` feeds rows as `<glyph>\t<name>\t<freq> FM · <operator>` and maps the
returned label back to an id. The current station gets a different glyph. This is
what a Walker dmenu would have been. It is one function, and no menu-config edits
are needed (see Context on why the JSONC provider is not usable). An optional
follow-up is a `radio` entry in the user's `omarchy-menu.jsonc`; the installer does
not touch that file.

### D5. Widget polls `omarchy-radio status` every 2 s
A QML `Timer` runs the CLI through a Quickshell `Process`, parses the JSON, and
drives the icon and label. Click handlers call the CLI and then trigger an
immediate refresh. Two seconds is cheap (one socat round trip) and covers the
"external change shows up within seconds" requirement. *Alternative:* a
long-lived `mpv` property-observer socket in QML: reactive, but more QML and
harder to test. It can be swapped in later without changing the CLI.
Interactions: left = `pick`, scroll = `volume ±5`, right = `stop`, middle = `toggle`.
On a vertical bar the label is hidden (spec).

### D6. Data and install layout
| Item | Installed at |
|---|---|
| CLI | `~/.local/bin/omarchy-radio` |
| Stations | `~/.local/share/omarchy-radio/stations.json` |
| Plugin | `~/.config/omarchy/plugins/local.radio-sg/` |

The CLI resolves stations from `$OMARCHY_RADIO_STATIONS`, then the data dir, then
`../stations.json` next to the script, so it also runs straight from the checkout.
Files are **copied**, not symlinked, so the repo can move or be deleted. The
installer marks what it owns (a header comment in the script, a `.omarchy-radio-sg`
marker file in the plugin dir) and refuses to overwrite anything without the marker.
The plugin is enabled with `omarchy plugin enable local.radio-sg`, so the shell
edits its own `shell.json`. We never hand-edit it, and uninstall (`omarchy plugin
disable` then delete) is the mirror image.

### D7. Stream verification is a repeatable script
`omarchy-radio check` does the fast probe (`curl -r 0-4096`: 2xx and an `audio/*`
content type). `check --play` also runs `mpv --no-video --ao=null --length=3`
per station. The second is the bar for committing a station; the first is for
periodic health checks. This keeps the "only verified URLs" rule enforceable
rather than a promise.

### D8. Testing
Plain bash (`test/run.sh`); no bats dependency. Offline tests use a fixture station
file whose URL is an mpv `av://lavfi:sine` source and `--ao=null`, which exercises
the whole lifecycle (play, switch, toggle, volume clamp, stop, stale socket,
status JSON) without network or sound. Network verification is `check --play`,
run by hand. Installer tests run against a temp `$HOME`. The QML is checked by
running it in the live shell on this machine.

## Risks / Trade-offs

- **[Third-party stream URLs change or geo-block]** → `check` reports failures by
  name; the list is a plain JSON file that is easy to fix.
- **[Plugins are unsandboxed code in `omarchy-shell`]** → the QML only spawns the
  CLI and holds no secrets; the README says so; the plugin lands after an explicit
  enable by the installer.
- **[`omarchy-shell` internals are not a documented stable API]** (`Ui/BarWidget`,
  `BarIconButton`, `bar.run`) → keep the widget tiny and modelled on first-party
  widgets; pin to what 4.0.4 provides and note it in the README.
- **[`~/.local/bin` may not be on the shell's PATH]** → the widget invokes the CLI
  by absolute `$HOME` path; verify in the live shell (task 5).
- **[Enable and disable may not restore `shell.json` exactly]** → the round-trip
  scenario is tested by diffing `shell.json` before install and after uninstall,
  with any difference resolved via `omarchy bar`.
- **[Polling adds a small constant load]** → about one process per 2 s, only
  while the widget exists.
- **[Unverified station names]** → CNA938, Lush 99.5, Hitz 89.9 and the SPH
  stations may not be shipped in v1. That is intended (verified only), and the
  README will list what was tried.

## Open Questions

- Does the user want SPH stations if they turn out to need HLS or tokenized URLs?
  (Default: omit anything that isn't a plain stream.)
- Should the icon be a Nerd Font radio glyph or an animated one while playing?
  (Default: static glyphs; cosmetic.)
