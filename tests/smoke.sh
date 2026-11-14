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
git clone -q "$TC" "$T/tc" && git -C "$T/tc" tag -f pin-test >/dev/null; git -C "$T/tc" tag -f pin-test2 >/dev/null
printf 'TC=%s\nTOOLCHAIN_REF=pin-test\ninclude $(TC)/chip.mk\n' "$T/tc" >"$T/Makefile"
cp "$TC/chip.mk" "$T/tc/chip.mk"
make -s -C "$T" -n test >/dev/null 2>&1 || { echo "smoke: matching pin rejected"; exit 1; }
sed -i 's/pin-test$/pin-test2/' "$T/Makefile"   # second tag on the same commit must also match
make -s -C "$T" -n test >/dev/null 2>&1 || { echo "smoke: second tag on same commit rejected"; exit 1; }
sed -i 's/pin-test2/other/' "$T/Makefile"
if make -s -C "$T" -n test >/dev/null 2>&1; then echo "smoke: pin mismatch not detected"; exit 1; fi
# Template Makefile must reject a checkout that lacks the chip.mk check (an old .toolchain).
old="$(mktemp -d)"; git clone -q "$TC" "$old/chip" && cd "$old/chip" && git tag v0.0-old && cd - >/dev/null
sed 's|^TOOLCHAIN_REF ?= .*|TOOLCHAIN_REF ?= v9.9|; s|^TC := .*|TC := '"$old"'/chip|' "$TC/templates/Makefile" >"$old/Makefile"
printf '# stub: old chip.mk without a pin check\ntest:\n\t@true\n' >"$old/chip/chip.mk"
if make -s -C "$old" test >/dev/null 2>&1; then echo "smoke: template Makefile accepted a wrong-tag .toolchain"; exit 1; fi
sed -i 's|^TOOLCHAIN_REF ?= .*|TOOLCHAIN_REF ?= v0.0-old|' "$old/Makefile"   # matching pin must pass
make -s -C "$old" test >/dev/null 2>&1 || { echo "smoke: template Makefile rejected the matching pin"; exit 1; }
rm -rf "$old"
echo "smoke: ok"
