# Contributing

Thanks for helping. This is a small project: a bash CLI (`bin/omarchy-radio`), one
QML widget (`RadioWidget.qml`) and a JSON station list (`stations.json`). Keep changes
small and in the style of the surrounding code.

## Run the tests

Tests are plain bash and need no network or sound; they play an mpv `lavfi` sine
source with the null audio output.

```bash
test/run.sh
```

Each `test/*.test.sh` runs in a throwaway `$HOME` and `$XDG_RUNTIME_DIR`.

## Try your change in Omarchy

Omarchy clones committed files, so commit first, then add your checkout by path:

```bash
omarchy plugin add /path/to/omarchy-radio-sg --enable --yes
# after more commits:
omarchy plugin update winston.radio-sg --yes && omarchy restart shell
```

The shell keeps a loaded widget until it restarts, so restart after each update.

## Add or fix a station

1. Find its stream URL (for example on [fmstream.org](https://fmstream.org)).
2. Check it plays: `mpv --no-video --ao=null --length=3 <url>` should exit 0.
3. Add an entry to `stations.json` with `id`, `name`, `freq`, `operator`, `language`
   and `url`, then run `omarchy-radio check --play`.

Only add streams that are the station's own public feed; do not use a station app's
private API.

## Specs

Behavior is specified with [OpenSpec](https://github.com/Fission-AI/OpenSpec), and the
specs are the source of truth for what the plugin should do.

- `openspec/specs/`: the current requirements, one folder per capability
  (`station-catalog`, `radio-playback`, `station-picker`, `bar-widget`,
  `installation`), each with testable scenarios.
- `openspec/changes/archive/`: the changes that built the plugin, with the proposal
  (why), design (how, and alternatives rejected) and tasks (what was verified):
  - `2026-09-24-add-sg-radio-plugin`: the plugin itself, including why it targets
    `omarchy-shell` rather than Waybar.
  - `2026-09-24-publish-as-omarchy-plugin`: restructuring it to match Omarchy's
    plugin model (`omarchy plugin add`).

For a behavior change, propose it first (`/opsx:propose` in Claude Code, or
`openspec new change <name>`), implement it, then archive it so `openspec/specs/`
stays current. Small fixes and station updates do not need a change.
