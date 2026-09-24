#!/bin/bash
# Optional helper: put `omarchy-radio` on your PATH by linking to the copy in this
# folder. The plugin itself is installed with `omarchy plugin add`; this only adds
# the terminal command. Safe to re-run; it never replaces a file it did not create.

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC=$here/bin/omarchy-radio
LINK=$HOME/.local/bin/omarchy-radio

die() { echo "install: $*" >&2; exit 1; }

# -- prerequisites: name everything that is missing, change nothing
missing=()
for tool in mpv socat jq curl column omarchy omarchy-shell; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
(( ${#missing[@]} == 0 )) || die "missing required tools: ${missing[*]}"
command -v omarchy-plugin-enable >/dev/null ||
  die "this Omarchy has no shell plugin support (omarchy plugin ...); Omarchy 4 or newer is required"
[[ -x $SRC ]] || die "$SRC not found; run this from the plugin folder"

# -- never replace something we did not create
if [[ -e $LINK || -L $LINK ]]; then
  [[ $(readlink "$LINK" 2>/dev/null) == "$SRC" ]] && { echo "Already linked: $LINK"; exit 0; }
  grep -q 'omarchy-radio-sg managed' "$LINK" 2>/dev/null ||
    die "$LINK exists and was not created by this project; not touching it"
fi

mkdir -p "$(dirname "$LINK")"
ln -sfn "$SRC" "$LINK"
echo "Linked $LINK -> $SRC"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Note: ~/.local/bin is not on your PATH; run it as $LINK." ;;
esac
