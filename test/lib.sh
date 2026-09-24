# Tiny assert helpers for test/*.test.sh. Sourced, not executed.
failures=0
ok()  { if eval "$1"; then :; else echo "  not ok: $2" >&2; failures=$((failures + 1)); fi; }
eq()  { if [[ $1 == "$2" ]]; then :; else echo "  not ok: $3 (got '$1', want '$2')" >&2; failures=$((failures + 1)); fi; }
done_tests() { (( failures == 0 )); }
