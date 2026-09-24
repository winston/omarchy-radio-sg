# install.sh / uninstall.sh (the optional PATH helper) in a throwaway HOME, plus checks
# that the repo root is a valid Omarchy plugin folder.
source "$(dirname "$0")/lib.sh"

REPO=$TEST_ROOT
LINK=$HOME/.local/bin/omarchy-radio
export OMARCHY_RADIO_STATIONS="$REPO/test/fixtures/stations.json" OMARCHY_RADIO_MPV_OPTS=--ao=null

# the helper only checks that these exist; stubs keep the real shell out of it
stubs=$HOME/stubs; mkdir -p "$stubs"
for c in omarchy omarchy-shell omarchy-plugin-enable; do printf '#!/bin/bash\nexit 0\n' >"$stubs/$c"; done
chmod +x "$stubs"/*
export PATH="$stubs:$PATH"

# -- the repo root is a plugin folder
ok '[[ $(jq -r .id "$REPO/manifest.json") == winston.radio-sg ]]' "manifest id is winston.radio-sg"
ok 'grep -q "moduleName: \"winston.radio-sg\"" "$REPO/RadioWidget.qml"' "widget moduleName matches the id"
ok '[[ -z $(find "$REPO" -name .git -prune -o -type l -print -quit) ]]' "no symlinks in the repo"
if command -v omarchy-plugin-validate >/dev/null; then
  ok 'omarchy-plugin-validate "$REPO" >/dev/null 2>&1' "repo root passes omarchy plugin validate"
else
  echo "  skip: omarchy-plugin-validate not installed" >&2
fi

# -- link created
out=$(bash "$REPO/install.sh" 2>&1); rc=$?
eq "$rc" 0 "install succeeds ($out)"
ok '[[ -L $LINK && $(readlink "$LINK") == "$REPO/bin/omarchy-radio" ]]' "link points into this folder"
ok '"$LINK" list | grep -q tone-a' "linked command finds its stations"

# -- repeat run changes nothing
out=$(bash "$REPO/install.sh" 2>&1); rc=$?
eq "$rc" 0 "repeat run succeeds"
ok '[[ $out == *"Already linked"* ]]' "repeat run says it is already linked"

# -- follows the target: a second checkout takes over the link, and edits show through
copy=$HOME/checkout; mkdir "$copy"; cp -r "$REPO"/{bin,stations.json,install.sh,uninstall.sh} "$copy/"
bash "$copy/install.sh" >/dev/null 2>&1
eq "$(readlink "$LINK")" "$copy/bin/omarchy-radio" "another checkout of ours can take over the link"
echo "# v2" >>"$copy/bin/omarchy-radio"
ok 'grep -q "^# v2" "$LINK"' "edits to the target show through the link"

# -- uninstall stops playback and removes the link
export XDG_STATE_HOME=$HOME/state
"$LINK" play tone-a
eq "$(pgrep -fc "input-ipc-server=$XDG_RUNTIME_DIR" || true)" 1 "a player is running"
out=$(bash "$copy/uninstall.sh" 2>&1)
eq "$out" "Removed $LINK" "uninstall message"
ok '[[ ! -e $LINK && ! -L $LINK ]]' "link removed"
eq "$(pgrep -fc "input-ipc-server=$XDG_RUNTIME_DIR" || true)" 0 "playback stopped"

# -- nothing to remove
eq "$(bash "$REPO/uninstall.sh" 2>&1)" "Nothing to do." "uninstall with no link"
ok 'bash "$REPO/uninstall.sh" >/dev/null 2>&1' "uninstall with no link succeeds"

# -- name collision: someone else's file or link is refused and left alone
mkdir -p "$HOME/.local/bin"; echo "mine" >"$LINK"
err=$(bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"not created by this project"* ]]' "foreign file refused"
eq "$(cat "$LINK")" mine "foreign file untouched"
ok 'bash "$REPO/uninstall.sh" >/dev/null 2>&1; [[ $(cat "$LINK") == mine ]]' "uninstall leaves a foreign file alone"
rm -f "$LINK"; echo "other" >"$HOME/other"; ln -s "$HOME/other" "$LINK"
ok '! bash "$REPO/install.sh" >/dev/null 2>&1 && [[ $(readlink "$LINK") == "$HOME/other" ]]' "foreign link refused and untouched"
rm -f "$LINK"

# -- a missing tool is named and nothing changes
tools=$HOME/tools; mkdir "$tools"
for t in jq socat curl column ln mkdir grep dirname readlink cat; do ln -s "$(command -v $t)" "$tools/$t"; done
cp "$stubs"/* "$tools/"
err=$(PATH="$tools" /bin/bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"missing required tools: mpv"* ]]' "missing mpv is named"
ok '[[ ! -e $LINK && ! -L $LINK ]]' "no link when a tool is missing"

# -- Omarchy without plugin support
rm "$tools/omarchy-plugin-enable"; ln -s "$(command -v mpv)" "$tools/mpv"
err=$(PATH="$tools" /bin/bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"shell plugin support"* ]]' "unsupported Omarchy explained"
ok '[[ ! -e $LINK && ! -L $LINK ]]' "no link on unsupported Omarchy"

done_tests
