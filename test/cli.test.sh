# Playback CLI: lifecycle, volume, status, check. Uses a sine source, no network.
source "$(dirname "$0")/lib.sh"

R="$TEST_ROOT/bin/omarchy-radio"
export OMARCHY_RADIO_STATIONS="$TEST_ROOT/test/fixtures/stations.json"
export OMARCHY_RADIO_MPV_OPTS=--ao=null
players() { pgrep -fc "input-ipc-server=$XDG_RUNTIME_DIR" || true; }
field() { "$R" status | jq -r "$1"; }

# list / dependencies
ok '"$R" list | grep -q "tone-a"' "list shows stations"
mkdir "$HOME/bin"; for t in jq socat column; do ln -s "$(command -v $t)" "$HOME/bin/$t"; done
err=$(PATH="$HOME/bin" "$R" play tone-a 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $err == *"missing required tool: mpv"* ]]' "missing mpv is named"

# machine-readable listing: one object per station, file order, only the public fields
eq "$("$R" list --json | jq -c "map(.id)")" '["tone-a","tone-b"]' "list --json order"
ok '"$R" list --json | jq -e "length == 2 and (.[0] | keys == [\"freq\",\"id\",\"name\",\"operator\"])" >/dev/null' "list --json fields"

# stopped, idle no-ops
eq "$(field .class)" stopped "status when idle"
ok '"$R" toggle' "toggle when stopped succeeds"
ok '"$R" stop' "stop when idle succeeds"
eq "$(players)" 0 "toggle/stop start nothing"
eq "$("$R" volume 40)" 40 "volume with no player is saved"

# play, survive caller, saved volume applied
bash -c "\"$R\" play tone-a"
eq "$(field .class)" playing "playing after caller exits"
eq "$(field .station)" tone-a "station id reported"
eq "$(field .volume)" 40 "saved volume applied on spawn"
eq "$(players)" 1 "one player"

# switch: still one player, new station
"$R" play tone-b
eq "$(field .station)" tone-b "switched"
eq "$(players)" 1 "one player after switch"

# unknown id leaves playback alone
ok '! "$R" play nope 2>/dev/null' "unknown id fails"
eq "$(field .station)" tone-b "playback unchanged by unknown id"
err=$("$R" play nope 2>&1 || true)
ok '[[ $err == *nope* ]]' "error names the id"

# pause / resume
"$R" toggle; eq "$(field .class)" paused "paused"
"$R" toggle; eq "$(field .class)" playing "resumed"
"$R" toggle; "$R" play tone-a
eq "$(field .class)" playing "play while paused resumes"

# volume
eq "$("$R" volume 50)" 50 "absolute"
eq "$("$R" volume +5)" 55 "relative up"
eq "$(field .volume)" 55 "applied to player"
eq "$("$R" volume -10)" 45 "relative down"
"$R" volume 98 >/dev/null; eq "$("$R" volume +5)" 100 "clamped high"
"$R" volume 3 >/dev/null;  eq "$("$R" volume -5)" 0 "clamped low"
ok '! "$R" volume abc 2>/dev/null' "bad volume rejected"

# status shape and speed
"$R" volume 60 >/dev/null
ok '"$R" status | jq -e ".class and .text and .tooltip and .station and .name and (.volume == 60)" >/dev/null' "playing shape"
t0=$(date +%s%N); "$R" status >/dev/null; ms=$(( ($(date +%s%N) - t0) / 1000000 ))
ok '(( ms < 100 ))' "status under 100ms (was ${ms}ms)"
ok '"$R" status | jq -e ".tooltip | contains(\"Tone A\")" >/dev/null' "tooltip names station"
ok '"$R" status | jq -e ".freq == \"88.8\" and (has(\"title\") | not)" >/dev/null' "freq present, no title when the stream reports none"

# stop leaves nothing behind
"$R" stop
eq "$(players)" 0 "no player after stop"
ok '[[ ! -e $XDG_RUNTIME_DIR/omarchy-radio.sock ]]' "no socket after stop"
eq "$(field .class)" stopped "stopped"
ok '"$R" stop' "stop is idempotent"

# stale socket: killed player leaves its socket behind
"$R" play tone-a
pkill -9 -f "input-ipc-server=$XDG_RUNTIME_DIR"; sleep 0.2
ok '[[ -S $XDG_RUNTIME_DIR/omarchy-radio.sock ]]' "stale socket present"
eq "$(field .class)" stopped "stale socket reads as stopped"
"$R" play tone-b
eq "$(field .station)" tone-b "play cleans up a stale socket"
"$R" stop

# check
export OMARCHY_RADIO_CHECK_SECS=1
ok '"$R" check --play >/dev/null' "check passes on good fixture"
out=$(OMARCHY_RADIO_STATIONS="$TEST_ROOT/test/fixtures/bad-stations.json" "$R" check 2>&1) && rc=0 || rc=$?
ok '(( rc != 0 )) && [[ $out == *"FAIL  dead"* ]]' "check names the failing station"

done_tests
