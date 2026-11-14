#!/usr/bin/env bash
# Fake-package test: wrong sha must fail twice and leave nothing in dest; right sha must pass.
set -eu
TC="$(cd "$(dirname "$0")/.." && pwd)"; t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
d=pkg/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog
mkdir -p "$t/$d"; echo "// p" >"$t/$d/primitives.v"; echo "// c" >"$t/$d/sky130_fd_sc_hd.v"
tar -cjf "$t/p.tar.bz2" -C "$t" pkg; good=$(sha256sum "$t/p.tar.bz2" | cut -d' ' -f1)
export SKY130_PDK_URL="file://$t/p.tar.bz2"
f="$TC/scripts/fetch_sky130_models.sh"; dest="$t/dest"
for i in 1 2; do
  SKY130_PDK_SHA256=bad "$f" "$dest" 2>/dev/null && { echo "FAIL: wrong sha accepted (run $i)"; exit 1; } || true
done
[ -z "$(find "$dest" -name '*.v' 2>/dev/null)" ] || { echo "FAIL: unverified files left in dest"; exit 1; }
SKY130_PDK_SHA256=$good "$f" "$dest" >/dev/null
[ -s "$dest/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v" ] || { echo "FAIL: good sha missing files"; exit 1; }
SKY130_PDK_SHA256=bad "$f" "$dest" 2>/dev/null && { echo "FAIL: stale dest trusted for other sha"; exit 1; } || true
echo "PASS fetch_sky130_models"
