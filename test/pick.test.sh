# Picker: rows, choosing, cancelling, current-station marker. Fake selector, no shell needed.
source "$(dirname "$0")/lib.sh"

R="$TEST_ROOT/bin/omarchy-radio"
export OMARCHY_RADIO_STATIONS="$TEST_ROOT/test/fixtures/stations.json"
export OMARCHY_RADIO_MPV_OPTS=--ao=null

# Fake omarchy-menu-select: logs its argv, then prints $FAKE_PICK (or cancels if unset).
sel="$HOME/fake-select"
cat >"$sel" <<'FAKE'
#!/bin/bash
printf '%s\n' "$@" >"$FAKE_LOG"
[[ -n ${FAKE_PICK-} ]] || exit 1
printf '%b\n' "$FAKE_PICK"
FAKE
chmod +x "$sel"
export OMARCHY_RADIO_SELECT="$sel" FAKE_LOG="$HOME/args.log"
field() { "$R" status | jq -r "$1"; }

# rows: prompt, then every station in file order as glyph<TAB>name<TAB>freq FM · operator
TAB=$'\t'
unset FAKE_PICK; "$R" pick
row() { sed -n "$1p" "$FAKE_LOG"; }
eq "$(row 1)" Radio "prompt is Radio"
eq "$(row 2 | cut -f2-)" "Tone A${TAB}88.8 FM · Test" "first row is Tone A with freq and operator"
eq "$(row 3 | cut -f2-)" "Tone B${TAB}99.9 FM · Test" "second row is Tone B"

# cancel changes nothing
ok '"$R" pick' "cancel exits cleanly"
eq "$(field .class)" stopped "cancel plays nothing"

# choose plays, and the picker returns label<TAB>subtext like the real one
FAKE_PICK='Tone B\t99.9 FM · Test' "$R" pick
eq "$(field .station)" tone-b "choose plays the station"

# a selector that echoes the whole row, icon included, resolves too
"$R" stop
FAKE_PICK='\U000f0439\tTone A\t88.8 FM · Test' "$R" pick
eq "$(field .station)" tone-a "choose resolves when the icon is echoed back"
FAKE_PICK='Tone B\t99.9 FM · Test' "$R" pick

# cancel keeps the current station
unset FAKE_PICK; "$R" pick
eq "$(field .station)" tone-b "cancel keeps playback"

# current station is marked with a check
eq "$(row 3 | cut -f1)" "✓" "current row marked"
ok '[[ $(row 2 | cut -f1) != "✓" ]]' "other row not marked"

"$R" stop
done_tests
