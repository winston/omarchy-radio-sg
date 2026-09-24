#!/bin/bash
# Install omarchy-radio: the CLI, the station list and the Omarchy shell bar widget.
# Safe to re-run. It only overwrites files it created (each carries a marker) and
# changes the bar only through `omarchy plugin enable`.

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ID=local.radio-sg
MARK=.omarchy-radio-sg
BIN=$HOME/.local/bin/omarchy-radio
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-radio
PLUGIN=$HOME/.config/omarchy/plugins/$ID

die() { echo "install: $*" >&2; exit 1; }

# -- prerequisites: name everything that is missing, change nothing
missing=()
for tool in mpv socat jq curl column omarchy omarchy-shell; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
(( ${#missing[@]} == 0 )) || die "missing required tools: ${missing[*]}"
command -v omarchy-plugin-enable >/dev/null ||
  die "this Omarchy has no shell plugin support (omarchy plugin ...); Omarchy 4 or newer is required"

# -- never replace something we did not create
[[ ! -e $BIN && ! -L $BIN ]] || grep -q 'omarchy-radio-sg managed' "$BIN" 2>/dev/null ||
  die "$BIN exists and was not installed by this project; not touching it"
[[ ! -e $DATA ]] || [[ -e $DATA/$MARK ]] ||
  die "$DATA exists and was not created by this project; not touching it"
[[ ! -e $PLUGIN && ! -L $PLUGIN ]] || [[ -f $PLUGIN/$MARK && ! -L $PLUGIN ]] ||
  die "$PLUGIN exists and was not created by this project; not touching it"

# -- files
install -Dm755 "$here/bin/omarchy-radio" "$BIN"
install -Dm644 "$here/stations.json" "$DATA/stations.json"
touch "$DATA/$MARK"

if ! diff -rq -x "$MARK" "$here/plugin" "$PLUGIN" >/dev/null 2>&1; then
  rm -rf "$PLUGIN"
  mkdir -p "$PLUGIN"
  cp -r "$here/plugin/." "$PLUGIN/"
fi
touch "$PLUGIN/$MARK"

# -- register with the shell; an already-enabled widget keeps its place in the bar
omarchy-shell shell rescanPlugins >/dev/null
if omarchy-shell shell listPlugins | jq -e --arg id "$ID" '.[] | select(.id == $id and .enabled)' >/dev/null; then
  echo "Widget already enabled."
else
  omarchy plugin enable "$ID"
fi

echo "Installed. Try: omarchy-radio pick"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Note: ~/.local/bin is not on your PATH, so run it as $BIN in a terminal." ;;
esac
echo "Move the widget with: omarchy bar move $ID --section center"
