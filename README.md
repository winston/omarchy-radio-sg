# omarchy-radio-sg

An [Omarchy](https://omarchy.org) plugin for listening to Singapore FM radio
(Mediacorp's stations and UFM): a bar widget that shows what is playing, a station
picker in the Omarchy menu, and mpv doing the playback.

It targets **Omarchy 4's `omarchy-shell`** (its Quickshell bar and plugin system),
not Waybar or Walker.

Built spec-first with [OpenSpec](https://github.com/Fission-AI/OpenSpec).
See `openspec/` for the specs and the change that built this.

## Stations

Ten stations, each played with `mpv --no-video --ao=null --length=3` on
2026-09-24 before being added. Stream URLs came from the
[fmstream.org](https://fmstream.org/index.php?c=SNG) directory, used at
development time only; the plugin never contacts it. The streams are the public
StreamTheWorld `livestream-redirect` URLs. The meLISTEN app's private API is not used.

| MHz | Station | Operator | Language | id |
|---|---|---|---|---|
| 88.3 | 88.3 Jia | Mediacorp | Mandarin | `jia883` |
| 90.5 | Gold 905 | Mediacorp | English | `gold905` |
| 92.4 | Symphony 92.4 | Mediacorp | Classical | `symphony924` |
| 93.3 | YES 933 | Mediacorp | Mandarin | `yes933` |
| 95.0 | Class 95 | Mediacorp | English | `class95` |
| 95.8 | Capital 958 | Mediacorp | Mandarin | `capital958` |
| 96.3 | Hao 96.3 | Mediacorp | Mandarin | `hao963` |
| 97.2 | Love 972 | Mediacorp | Mandarin | `love972` |
| 98.7 | 987FM | Mediacorp | English | `fm987` |
| 100.3 | UFM 100.3 | SPH Media | Mandarin | `ufm1003` |

The list is `stations.json`. Stations that stop working show up in
`omarchy-radio check`. Other directory entries (Kiss92, One FM, Money FM, 938NOW,
Warna, Ria, Oli, ...) use the same URL form and can be added the same way.

## CLI

`omarchy-radio` does all the work; the bar widget and picker just call it.
mpv is the only state, so the CLI, the picker and the widget always agree.

```
Usage: omarchy-radio <command> [args]

  list                 Show the stations
  play <id>            Play a station (switches if one is already playing)
  toggle               Pause or resume
  stop                 Stop playback
  volume <N|+N|-N>     Set or nudge the volume, 0-100
  status               Print the state as one line of JSON
  pick                 Choose a station from the Omarchy menu
  check [--play]       Probe every stream URL; --play also plays 3 s of each

Environment:
  OMARCHY_RADIO_STATIONS   stations.json to use instead of the installed one
  OMARCHY_RADIO_MPV_OPTS   extra mpv options (e.g. --ao=null)
```

`status` prints one line of JSON: `class` (`playing`, `paused` or `stopped`),
`text`, `tooltip`, and while a station is loaded also `station`, `name`, `freq`
and `volume`. The first three are Waybar's shape too. The tooltip shows the
stream's current song title when the station sends one.

The last volume is remembered across stops (default 50).

## Bar widget

The widget sits on the right of the bar after install. Move it with
`omarchy bar move local.radio-sg --section center`.

| Action | Result |
|---|---|
| Left click | Open the station picker |
| Scroll | Volume up or down by 5 |
| Middle click | Pause or resume |
| Right click | Stop |
| Hover | Station, frequency, state, volume and the current song title |

While playing it shows `󰐊  Class 95`, while paused `󰏤  Class 95`, and when
stopped only the radio icon `󰐹`, so it stays clickable. On a vertical bar the
station name is hidden. It refreshes every 2 seconds, so changes made from a
terminal show up too.

## Install

Requires Omarchy 4 or newer, plus `mpv`, `socat`, `jq` and `curl`.

```bash
./install.sh      # copies the CLI, stations and plugin, then enables the widget
./uninstall.sh    # stops playback and removes exactly what install.sh added
```

Both are safe to re-run. The installer only overwrites files it created (they
carry a marker) and stops with an error if something else is in the way. It
changes your bar only through `omarchy plugin enable`, so the rest of
`shell.json` is left alone, and uninstalling restores it exactly.

Files: `~/.local/bin/omarchy-radio`, `~/.local/share/omarchy-radio/stations.json`
and `~/.config/omarchy/plugins/local.radio-sg/`.

> Shell plugins run unsandboxed inside `omarchy-shell`. This one is a single QML
> file that only runs `omarchy-radio`; read it before enabling if you like:
> `plugin/RadioWidget.qml`. It uses `omarchy-shell`'s internal widget classes,
> which Omarchy does not document as a stable API, so it was written against 4.0.4.

## Development

Tests are plain bash and need no network or sound; they play an mpv
`lavfi` sine source with the null audio output.

```bash
test/run.sh
```

Each `test/*.test.sh` runs in a throwaway `$HOME` and `$XDG_RUNTIME_DIR`.
