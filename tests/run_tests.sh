#!/usr/bin/env bash
# Decodes every fixture with the plugin's reader procedure in batch Praat and
# checks the values, the time axis and the refusals.
# Usage: PRAAT=/path/to/praat bash tests/run_tests.sh
set -uo pipefail
: "${PRAAT:?set PRAAT to a Praat executable}"
HERE="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
python3 "$HERE/make_fixtures.py"
sed -n '/^# PROCEDURES$/,$p' "$HERE/../plugin_EMLLabChartReader/scripts/emlLabChartReader.praat" > "$work/procs.praat"
cat "$HERE/harness_head.praat" "$work/procs.praat" > "$work/harness.praat"
trust=""; "$PRAAT" --version | grep -q " 6\." || trust="--FULL-TRUST"
fail=0
for f in format1_time format1_notime format2_notime format2_badtime format3_notime format3_time; do
  "$PRAAT" $trust --run "$work/harness.praat" "$HERE/fixtures/$f.adibin" "$work/$f.Sound" | grep -E "RESULT|WARNING"
done
python3 "$HERE/check_values.py" "$work" || fail=1
for f in truncated badmagic; do
  out=$("$PRAAT" $trust --run "$work/harness.praat" "$HERE/fixtures/$f.adibin" "$work/$f.Sound" 2>&1)
  if echo "$out" | grep -q "^Error:"; then
    echo "$f: refused, as expected"
  else
    echo "$f: NOT refused"; fail=1
  fi
done
rm -rf "$work"
[ $fail = 0 ] && echo "ALL TESTS PASS" || { echo "TESTS FAILED"; exit 1; }
