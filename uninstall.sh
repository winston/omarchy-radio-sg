#!/bin/bash
# Stop playback and remove the PATH link install.sh made, and only that. Remove the
# plugin itself with `omarchy plugin remove winston.radio-sg`.

set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINK=$HOME/.local/bin/omarchy-radio

# stop first, using the copy in this folder
"$here/bin/omarchy-radio" stop 2>/dev/null

if [[ -e $LINK || -L $LINK ]] && grep -q 'omarchy-radio-sg managed' "$LINK" 2>/dev/null; then
  rm -f "$LINK"
  echo "Removed $LINK"
else
  echo "Nothing to do."
fi
