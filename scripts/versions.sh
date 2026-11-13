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
  echo "toolchain: $(git -C "$TC" describe --tags --always 2>/dev/null)"
} | tee "$out"
exit $rc
