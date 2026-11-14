#!/usr/bin/env bash
# Record exact tool versions so results can be repeated. Fails if a tool is missing.
set -u
out="${1:-logs/tool-versions.txt}"; mkdir -p "$(dirname "$out")"
rc=0
TC="$(cd "$(dirname "$0")/.." && pwd)"
{
  echo "date: $(date -u +%FT%TZ)"
  echo "commit: $(git rev-parse --short HEAD 2>/dev/null || echo none)"
  for t in verilator yosys make python3; do
    if command -v "$t" >/dev/null; then echo "$t: $($t --version 2>&1 | head -1)"
    else echo "$t: MISSING"; rc=1; fi
  done
  for t in verilator yosys; do want=$(sed -n "s/^$t=//p" "$TC/VERSIONS")
    command -v $t >/dev/null && ! $t --version 2>&1 | grep -q "$want" && { echo "$t: version mismatch, pinned $want"; rc=1; }
  done
  # layout tools: optional (not every runner has them) but pinned when present
  for t in openroad klayout magic; do
    command -v $t >/dev/null || { echo "$t: not installed (optional)"; continue; }
    case $t in openroad) got=$(openroad -version 2>&1 | head -1);; klayout) got=$(klayout -v 2>&1 | head -1);; magic) got=$(magic --version 2>&1 | head -1);; esac
    echo "$t: $got"
    want=$(sed -n "s/^$t=//p" "$TC/VERSIONS")
    case $t in openroad) want=${want##*_g};; esac
    echo "$got" | grep -q "$want" || { echo "$t: version mismatch, pinned $want"; rc=1; }
  done
  [ -d "${PDK_ROOT:-/nonexistent}/sky130A" ] && echo "sky130A: $PDK_ROOT/sky130A"
  command -v iverilog >/dev/null && echo "iverilog: $(iverilog -V 2>&1 | head -1)"
  echo "toolchain: $(git -C "$TC" describe --tags --always 2>/dev/null)"
} | tee "$out"
exit $rc
