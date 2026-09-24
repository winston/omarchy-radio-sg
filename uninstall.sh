#!/bin/bash
# Remove what install.sh added, and only that. Safe to run when nothing is installed.

set -uo pipefail

ID=local.radio-sg
MARK=.omarchy-radio-sg
BIN=$HOME/.local/bin/omarchy-radio
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-radio
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-radio
PLUGIN=$HOME/.config/omarchy/plugins/$ID
removed=0

ours_bin=0; grep -q 'omarchy-radio-sg managed' "$BIN" 2>/dev/null && ours_bin=1

# stop playback first, using the CLI we are about to remove
(( ours_bin )) && "$BIN" stop 2>/dev/null

if [[ -f $PLUGIN/$MARK && ! -L $PLUGIN ]]; then
  command -v omarchy >/dev/null && omarchy plugin disable "$ID" >/dev/null 2>&1
  rm -rf "$PLUGIN"; removed=1
  command -v omarchy-shell >/dev/null && omarchy-shell shell rescanPlugins >/dev/null 2>&1
fi

if (( ours_bin )); then rm -f "$BIN"; removed=1; fi
if [[ -e $DATA/$MARK ]]; then rm -rf "$DATA"; removed=1; fi
if [[ -d $STATE && $removed == 1 ]]; then rm -rf "$STATE"; fi

if (( removed )); then echo "Uninstalled."; else echo "Nothing to do."; fi
