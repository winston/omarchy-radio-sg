# install.sh / uninstall.sh in a throwaway HOME with stubbed omarchy commands.
source "$(dirname "$0")/lib.sh"

REPO=$TEST_ROOT
ID=local.radio-sg
BIN=$HOME/.local/bin/omarchy-radio
DATA=$HOME/.local/share/omarchy-radio
PLUGIN=$HOME/.config/omarchy/plugins/$ID
CALLS=$HOME/calls.log

# stubs: the real omarchy CLI would talk to the live shell
stubs=$HOME/stubs; mkdir -p "$stubs"
cat >"$stubs/omarchy" <<'S'
#!/bin/bash
echo "omarchy $*" >>"$HOME/calls.log"
case "$*" in
  "plugin enable"*) touch "$HOME/enabled" ;;
  "plugin disable"*) rm -f "$HOME/enabled" ;;
esac
S
cat >"$stubs/omarchy-shell" <<'S'
#!/bin/bash
echo "omarchy-shell $*" >>"$HOME/calls.log"
if [[ $* == "shell listPlugins" ]]; then
  if [[ -e $HOME/enabled ]]; then echo '[{"id":"local.radio-sg","enabled":true}]'; else echo '[]'; fi
fi
S
printf '#!/bin/bash\nexit 0\n' >"$stubs/omarchy-plugin-enable"
chmod +x "$stubs"/*
export PATH="$stubs:$PATH"

files() { find "$HOME" -type f ! -path "$stubs/*" ! -path "$HOME/checkout/*" ! -path "$HOME/tools/*" ! -name calls.log ! -name enabled | sort; }
enables() { grep -c '^omarchy plugin enable' "$CALLS" || true; }

# first install
out=$(bash "$REPO/install.sh" 2>&1); rc=$?
eq "$rc" 0 "install succeeds ($out)"
ok '[[ -x $BIN ]]' "cli installed"
ok '[[ -f $DATA/stations.json ]]' "stations installed"
ok '[[ -f $PLUGIN/manifest.json && -f $PLUGIN/RadioWidget.qml ]]' "plugin installed"
eq "$(enables)" 1 "plugin enabled once"
ok '"$BIN" list | grep -q class95' "installed cli finds installed stations"

# repeat install: same files, no second enable
before=$(files | xargs sha256sum)
out=$(bash "$REPO/install.sh" 2>&1)
eq "$(files | xargs sha256sum)" "$before" "repeat install changes no files"
ok '[[ $out != *"restart shell"* ]]' "unchanged repeat install stays quiet about restarting"
eq "$(enables)" 1 "repeat install does not enable again"

# update in place, from a changed checkout
copy=$HOME/checkout; mkdir "$copy"; cp -r "$REPO"/{bin,plugin,stations.json,install.sh} "$copy/"
echo "// v2" >>"$copy/plugin/RadioWidget.qml"
out=$(bash "$copy/install.sh" 2>&1)
ok '[[ $out == *"omarchy restart shell"* ]]' "update tells you to restart the shell"
ok 'grep -q "// v2" "$PLUGIN/RadioWidget.qml"' "update reaches the plugin"
ok '[[ -f $PLUGIN/.omarchy-radio-sg ]]' "marker survives update"

# uninstall
out=$(bash "$REPO/uninstall.sh" 2>&1)
eq "$out" Uninstalled. "uninstall message"
eq "$(files)" "" "uninstall leaves no files behind (round trip)"
ok 'grep -q "^omarchy plugin disable $ID" "$CALLS"' "plugin disabled"

# nothing to remove
eq "$(bash "$REPO/uninstall.sh" 2>&1)" "Nothing to do." "uninstall when absent"
ok 'bash "$REPO/uninstall.sh" >/dev/null 2>&1' "uninstall when absent succeeds"

# partial install: only the cli
bash "$REPO/install.sh" >/dev/null 2>&1; rm -rf "$PLUGIN" "$DATA"
ok 'bash "$REPO/uninstall.sh" >/dev/null 2>&1' "partial uninstall succeeds"
ok '[[ ! -e $BIN ]]' "partial uninstall removes the cli"
rm -f "$HOME/enabled"

# name collision: someone else's file at the cli path
mkdir -p "$HOME/.local/bin"; echo "mine" >"$BIN"
err=$(bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"not installed by this project"* ]]' "collision refused"
eq "$(cat "$BIN")" mine "foreign file untouched"
ok '[[ ! -e $PLUGIN && ! -e $DATA ]]' "nothing else installed on collision"
ok 'bash "$REPO/uninstall.sh" >/dev/null 2>&1; [[ $(cat "$BIN") == mine ]]' "uninstall leaves foreign file alone"
rm -f "$BIN"

# collision on the plugin dir
mkdir -p "$PLUGIN"; echo x >"$PLUGIN/theirs"
ok '! bash "$REPO/install.sh" >/dev/null 2>&1' "plugin dir collision refused"
ok '[[ ! -e $BIN && -f $PLUGIN/theirs ]]' "plugin dir collision changes nothing"
rm -rf "$HOME/.config"

# a missing tool is named and nothing changes
tools=$HOME/tools; mkdir "$tools"
for t in jq socat curl column install cp rm mkdir touch diff grep dirname cat sha256sum; do ln -s "$(command -v $t)" "$tools/$t"; done
cp "$stubs"/* "$tools/"
err=$(PATH="$tools" /bin/bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"missing required tools: mpv"* ]]' "missing mpv is named"
ok '[[ ! -e $BIN ]]' "no changes when a tool is missing"

# Omarchy without plugin support
rm "$tools/omarchy-plugin-enable"; ln -s "$(command -v mpv)" "$tools/mpv"
err=$(PATH="$tools" /bin/bash "$REPO/install.sh" 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"shell plugin support"* ]]' "unsupported Omarchy explained"
ok '[[ ! -e $BIN ]]' "no changes on unsupported Omarchy"

done_tests
