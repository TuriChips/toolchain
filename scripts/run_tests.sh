#!/usr/bin/env bash
# Usage: scripts/run_tests.sh [block]   (no arg = every block)
# Convention (owned by Quinn, see tb/README.md): each tb/<block>/ has
#   files.f  - RTL + testbench file list, paths relative to repo root
#   tb.sv    - top module `tb`; prints "PASS" and calls $finish on success,
#              $fatal / "FAIL" otherwise
# Logs: logs/<run>/<block>.log, summary in logs/<run>/summary.md, logs/latest -> run.
set -u
cd "$(git rev-parse --show-toplevel)"; TC="$(cd "$(dirname "$0")/.." && pwd)"
run="logs/$(date -u +%Y%m%dT%H%M%S%NZ)"; mkdir -p "$run"
want_random=0; want_4state=0; blocks=()
for a in "$@"; do case "$a" in random) want_random=1;; 4state) want_4state=1;; *) blocks+=("$a");; esac; done
[ $# -eq 0 ] && [ ${#blocks[@]} -eq 0 ] && mapfile -t blocks < <(find tb -mindepth 2 -maxdepth 2 -name files.f -printf '%h\n' 2>/dev/null | sed 's|^tb/||' | sort)
"$TC/scripts/versions.sh" "$run/tool-versions.txt" >/dev/null || { echo "missing tool, see $run/tool-versions.txt"; exit 2; }
pass=0; fail=0; rows=""
for b in "${blocks[@]}"; do
  log="$run/$b.log"; obj="build/$b"; mkdir -p "$obj"
  if verilator --binary --timing -Wall --Mdir "$obj" -f "tb/$b/files.f" --top tb >"$log" 2>&1 \
     && "$obj/Vtb" >>"$log" 2>&1 && grep -q '^PASS' "$log" && ! grep -q 'FAIL' "$log"
  then r=PASS; pass=$((pass+1)); else r=FAIL; fail=$((fail+1)); fi
  rows+="| $b | $r | $log |"$'\n'; echo "$r $b"
done
# Exhaustive/random comparison (Rook): tests/random/run.sh. Runs when no block is
# given or the block is "random"; RUN_DIR makes it write into this run's dir.
if [ -f tests/random/run.sh ] && { [ $# -eq 0 ] || [ "$want_random" = 1 ]; }; then
  RUN_DIR="$run" bash tests/random/run.sh >"$run/random-run.log" 2>&1; rc=$?
  if [ $rc -eq 0 ]; then r=PASS; pass=$((pass+1)); else r=FAIL; fail=$((fail+1)); fi
  rows+="| random (tests/random/run.sh) | $r | $run/random-*.log |"$'\n'; echo "$r random"; cat "$run/random-run.log"
  blocks+=(random)
fi
# 4-state (Icarus) run of X/Z checks (Quinn): tests/run_4state.sh. Same gating as random.
# It logs to logs/4state/; remove stale logs first, then copy into this run's dir.
if [ -f tests/run_4state.sh ] && { [ $# -eq 0 ] || [ "$want_4state" = 1 ]; }; then
  rm -rf logs/4state
  bash tests/run_4state.sh >"$run/4state-run.log" 2>&1; rc=$?
  for f in logs/4state/*.log; do [ -f "$f" ] && cp "$f" "$run/4state-$(basename "$f")"; done
  if [ $rc -eq 0 ]; then r=PASS; pass=$((pass+1)); else r=FAIL; fail=$((fail+1)); fi
  rows+="| 4state (tests/run_4state.sh) | $r | $run/4state-run.log |"$'\n'; echo "$r 4state"; cat "$run/4state-run.log"
  blocks+=(4state)
fi
{ echo "# Test summary $(date -u +%F)"; echo "run: $run  run=${#blocks[@]} pass=$pass fail=$fail"; echo
  echo "| block | result | log |"; echo "|---|---|---|"; printf '%s' "$rows"; } >"$run/summary.md"
ln -sfn "$(basename "$run")" logs/latest
[ ${#blocks[@]} -eq 0 ] && echo "warning: no tests found under tb/*/files.f"
echo "run=${#blocks[@]} pass=$pass fail=$fail  ($run/summary.md)"
[ $fail -eq 0 ]
