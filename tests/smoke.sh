#!/usr/bin/env bash
# Smoke test for the toolchain itself: run run_tests.sh on a tiny fixture chip.
# Checks: a passing block + random step pass, logs land in one run dir,
# a failing block makes the run fail, and two runs get different dirs.
set -eu
TC="$(cd "$(dirname "$0")/.." && pwd)"; W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cp -r "$TC/tests/fixture/." "$W/"; cd "$W"; git init -q .
"$TC/scripts/run_tests.sh" >out1.txt 2>&1 || { cat out1.txt; echo "smoke: clean fixture should pass"; exit 1; }
d1=$(readlink logs/latest); ls logs/$d1/random-fixture.log logs/$d1/ok.log >/dev/null; ls logs/$d1/4state-fixture.log >/dev/null
# Fast runs (no Verilator) are what can collide within one second: use random-only runs.
"$TC/scripts/run_tests.sh" random >/dev/null 2>&1; d2=$(readlink logs/latest)
"$TC/scripts/run_tests.sh" random >/dev/null 2>&1; d3=$(readlink logs/latest)
[ "$d2" != "$d3" ] || { echo "smoke: run dirs collided"; exit 1; }
mustfail() { # description, file to break (sed 's/PASS/FAIL/' or exit 1)
  if "$TC/scripts/run_tests.sh" >/dev/null 2>&1; then echo "smoke: $1 did not fail the run"; exit 1; fi; }
cp tb/ok/tb.sv /tmp/ok.$$; sed -i 's/PASS/FAIL/' tb/ok/tb.sv; mustfail "failing block"; cp /tmp/ok.$$ tb/ok/tb.sv; rm /tmp/ok.$$
for f in tests/random/run.sh tests/run_4state.sh; do
  cp "$f" "$f.bak"; echo "exit 1" >>"$f"; mustfail "failing $f"; mv "$f.bak" "$f"
done
# Pin check: chip.mk must fail when the checkout is not the pinned tag, pass when it is.
T="$(mktemp -d)"; trap 'rm -rf "$W" "$T"' EXIT
git clone -q "$TC" "$T/tc" && git -C "$T/tc" tag -f pin-test >/dev/null
printf 'TC=%s\nTOOLCHAIN_REF=pin-test\ninclude $(TC)/chip.mk\n' "$T/tc" >"$T/Makefile"
cp "$TC/chip.mk" "$T/tc/chip.mk"
make -s -C "$T" -n test >/dev/null 2>&1 || { echo "smoke: matching pin rejected"; exit 1; }
sed -i 's/pin-test/other/' "$T/Makefile"
if make -s -C "$T" -n test >/dev/null 2>&1; then echo "smoke: pin mismatch not detected"; exit 1; fi
echo "smoke: ok"
