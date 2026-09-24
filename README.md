# omarchy-radio-sg

An [Omarchy](https://omarchy.org) plugin for listening to Singapore FM radio
(Mediacorp's stations and UFM): a bar widget that shows what is playing, a station
picker in the Omarchy menu, and mpv doing the playback.

It targets **Omarchy 4's `omarchy-shell`** (its Quickshell bar and plugin system),
not Waybar or Walker.

Built spec-first with [OpenSpec](https://github.com/Fission-AI/OpenSpec); see
[Specs](#specs) for where the requirements and design live.

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

  list [--json]        Show the stations (--json for a JSON array)
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
`text`, `tooltip`, and while a station is loaded also `station`, `name`, `freq`,
`volume` and, when the stream sends one, the song `title`. The first three are Waybar's shape too. The tooltip shows the
stream's current song title when the station sends one.

The last volume is remembered across stops (default 50).

## Bar widget

The widget sits on the right of the bar after install. Move it with
`omarchy bar move winston.radio-sg --section center`.

| Action | Result |
|---|---|
| Left click | Open or close the popup card |
| Scroll | Volume up or down by 5 |
| Middle click | Pause or resume |
| Right click | Stop |
| Hover | Station, frequency, state, volume and the current song title |

While playing it shows `󰐊  Class 95`, while paused `󰏤  Class 95`, and when
stopped only the radio icon `󰐹`, so it stays clickable. On a vertical bar the
station name is hidden. It refreshes every 2 seconds (every second while the card
is open), so changes made from a terminal show up too.

### Popup card

Styled like the network and audio popups, and it follows your theme:

- **Header**: station, frequency, playing or paused, and the current song when the
  stream sends one.
- **Play/pause** button (disabled while stopped; start a station from the list).
- **Volume** slider.
- **Stations**: click one to switch to it; the current one is highlighted.

### Keybinding for the menu picker

`omarchy-radio pick` opens the station list as an Omarchy menu, handy for a
keybinding. For example, in `~/.config/hypr/bindings.conf`:

```
bindd = SUPER ALT, R, Radio, exec, ~/.local/bin/omarchy-radio pick   # needs the PATH helper, see Install
```

## Install

Requires Omarchy 4 or newer, plus `mpv`, `socat`, `jq` and `curl`.

This repo is an Omarchy shell plugin, so Omarchy installs it for you:

```bash
omarchy plugin add <git-url> --enable     # clone, validate and enable the widget
omarchy plugin update winston.radio-sg    # later: fetch new versions
omarchy restart shell                     # the shell keeps a loaded widget until it restarts
omarchy plugin remove winston.radio-sg --yes
```

That is all the widget needs: it runs the CLI from inside its own folder
(`~/.config/omarchy/plugins/winston.radio-sg/`), so nothing else is installed and
your `PATH` does not matter. Stop any playing station first with the widget's
right click, since removing the plugin does not stop it.

### The `omarchy-radio` command in a terminal (optional)

To run `omarchy-radio` yourself, or use the keybinding above, link it onto your PATH:

```bash
cd ~/.config/omarchy/plugins/winston.radio-sg
./install.sh      # checks the requirements, links ~/.local/bin/omarchy-radio here
./uninstall.sh    # stops playback and removes that link, nothing else
```

The link points into the plugin folder, so `omarchy plugin update` updates it too.
The script is safe to re-run and refuses to replace a file it did not create.
It only checks that the requirements above are installed, which makes it a handy
diagnostic if the widget seems to do nothing.

> Shell plugins run unsandboxed inside `omarchy-shell`. This one is a single QML
> file that only runs `omarchy-radio`; read it before enabling if you like:
> `RadioWidget.qml`. It uses `omarchy-shell`'s internal UI classes (`PopupCard`,
> `Button`, `PanelSlider`, ...), which Omarchy does not document as a stable API,
> so it was written against 4.0.4. The plugin folder is the whole repository
> (about 1 MB with the tests and specs).

## Development

Tests are plain bash and need no network or sound; they play an mpv
`lavfi` sine source with the null audio output.

```bash
test/run.sh
```

Each `test/*.test.sh` runs in a throwaway `$HOME` and `$XDG_RUNTIME_DIR`.

To try the plugin from a checkout, commit your change and add the checkout by path;
Omarchy clones the committed files, so uncommitted edits do not show up:

```bash
omarchy plugin add /path/to/omarchy-radio-sg --enable --yes
# after more commits:
omarchy plugin update winston.radio-sg --yes && omarchy restart shell
```

## Specs

The behavior is specified with [OpenSpec](https://github.com/Fission-AI/OpenSpec),
and the specs are the source of truth for what this plugin should do.

- `openspec/specs/`: the current requirements, one folder per capability:
  `station-catalog`, `radio-playback`, `station-picker`, `bar-widget` and
  `installation`. Each requirement has scenarios that the tests and hands-on checks
  were written against.
- `openspec/changes/archive/`: the changes that built the plugin, each with its
  `proposal.md` (why), `design.md` (how, and the alternatives rejected) and `tasks.md`
  (what was done and how each part was verified):
  - `2026-09-24-add-sg-radio-plugin`: the plugin itself, including why it targets
    `omarchy-shell` rather than Waybar.
  - `2026-09-24-publish-as-omarchy-plugin`: restructuring it to match Omarchy's
    documented plugin model (`omarchy plugin add`).

To change behavior, propose a new change first (`/opsx:propose` in Claude Code, or
`openspec new change <name>`), then implement it and archive it so `openspec/specs/`
stays current.
