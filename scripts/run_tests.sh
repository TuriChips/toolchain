#!/usr/bin/env bash
# Usage: scripts/run_tests.sh [block]   (no arg = every block)
# Convention (owned by Quinn, see tb/README.md): each tb/<block>/ has
#   files.f  - RTL + testbench file list, paths relative to repo root
#   tb.sv    - top module `tb`; prints "PASS" and calls $finish on success,
#              $fatal / "FAIL" otherwise
# Logs: logs/<run>/<block>.log, summary in logs/<run>/summary.md, logs/latest -> run.
set -u
cd "$(git rev-parse --show-toplevel)"; TC="$(cd "$(dirname "$0")/.." && pwd)"
run="logs/$(date -u +%Y%m%dT%H%M%SZ)"; mkdir -p "$run"
blocks=("$@"); [ ${#blocks[@]} -eq 0 ] && mapfile -t blocks < <(find tb -mindepth 2 -maxdepth 2 -name files.f -printf '%h\n' 2>/dev/null | sed 's|^tb/||' | sort)
"$TC/scripts/versions.sh" "$run/tool-versions.txt" >/dev/null || { echo "missing tool, see $run/tool-versions.txt"; exit 2; }
pass=0; fail=0; rows=""
for b in "${blocks[@]}"; do
  log="$run/$b.log"; obj="build/$b"; mkdir -p "$obj"
  if verilator --binary --timing -Wall --Mdir "$obj" -f "tb/$b/files.f" --top tb >"$log" 2>&1 \
     && "$obj/Vtb" >>"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"
  then r=PASS; pass=$((pass+1)); else r=FAIL; fail=$((fail+1)); fi
  rows+="| $b | $r | $log |"$'\n'; echo "$r $b"
done
{ echo "# Test summary $(date -u +%F)"; echo "run: $run  run=${#blocks[@]} pass=$pass fail=$fail"; echo
  echo "| block | result | log |"; echo "|---|---|---|"; printf '%s' "$rows"; } >"$run/summary.md"
ln -sfn "$(basename "$run")" logs/latest
[ ${#blocks[@]} -eq 0 ] && echo "warning: no tests found under tb/*/files.f"
echo "run=${#blocks[@]} pass=$pass fail=$fail  ($run/summary.md)"
[ $fail -eq 0 ]
