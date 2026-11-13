#!/usr/bin/env bash
# Smoke test for the toolchain itself: run run_tests.sh on a tiny fixture chip.
# Checks: a passing block + random step pass, logs land in one run dir,
# a failing block makes the run fail, and two runs get different dirs.
set -eu
TC="$(cd "$(dirname "$0")/.." && pwd)"; W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -r "$TC/tests/fixture/." "$W/"; cd "$W"; git init -q .
"$TC/scripts/run_tests.sh" >out1.txt 2>&1 || { cat out1.txt; echo "smoke: clean fixture should pass"; exit 1; }
d1=$(readlink logs/latest); ls logs/$d1/random-fixture.log logs/$d1/ok.log >/dev/null
"$TC/scripts/run_tests.sh" >/dev/null 2>&1; d2=$(readlink logs/latest)
[ "$d1" != "$d2" ] || { echo "smoke: run dirs collided"; exit 1; }
sed -i 's/PASS/FAIL/' tb/ok/tb.sv
if "$TC/scripts/run_tests.sh" >/dev/null 2>&1; then echo "smoke: failing block did not fail the run"; exit 1; fi
echo "smoke: ok"
