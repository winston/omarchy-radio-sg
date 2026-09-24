#!/bin/bash
# Run every test/*.test.sh, each in its own sandboxed HOME and XDG_RUNTIME_DIR.
# A test sources test/lib.sh and calls ok/eq/has; a non-zero exit fails it.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pass=0 fail=0

for t in "$here"/*.test.sh; do
  [[ -e $t ]] || continue
  sandbox=$(mktemp -d)
  mkdir -p "$sandbox"/{home,run}
  chmod 700 "$sandbox/run"
  if HOME="$sandbox/home" XDG_RUNTIME_DIR="$sandbox/run" \
     XDG_STATE_HOME="$sandbox/home/.local/state" XDG_DATA_HOME="$sandbox/home/.local/share" \
     TEST_ROOT=$(dirname "$here") bash "$t"; then
    pass=$((pass + 1)); echo "PASS $(basename "$t")"
  else
    fail=$((fail + 1)); echo "FAIL $(basename "$t")"
  fi
  pkill -f "input-ipc-server=$sandbox/run" 2>/dev/null
  rm -rf "$sandbox"
done

echo "$pass passed, $fail failed"
(( fail == 0 ))
