#!/usr/bin/env bash
# Fetch only the sky130_fd_sc_hd Verilog cell models (primitives.v, sky130_fd_sc_hd.v) for
# gate-level simulation in CI. Streams the pinned open_pdks.sky130a conda package (same one
# install_layout_tools.sh uses), checks its sha256, keeps just the two files. Nothing is committed.
# Usage: scripts/fetch_sky130_models.sh [dest]   (default $HOME/.cache/turichips/pdk)
# Prints the PDK_ROOT to use; CI appends it to $GITHUB_ENV.
set -euo pipefail
TC="$(cd "$(dirname "$0")/.." && pwd)"
v() { sed -n "s/^$1=//p" "$TC/VERSIONS"; }
dest="${1:-$HOME/.cache/turichips/pdk}"
lib=sky130A/libs.ref/sky130_fd_sc_hd/verilog
# SKY130_PDK_URL / SKY130_PDK_SHA256 override the pins (used by tests/fetch_sky130_models_test.sh)
url="${SKY130_PDK_URL:-$(v sky130_pdk_url)}"; want="${SKY130_PDK_SHA256:-$(v sky130_pdk_sha256)}"
# Only a verified fetch writes $dest/.sha256, so unverified files are never trusted.
if [ "$(cat "$dest/.sha256" 2>/dev/null)" != "$want" ] || [ ! -s "$dest/$lib/primitives.v" ] || [ ! -s "$dest/$lib/sky130_fd_sc_hd.v" ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$dest" "$tmp/x"
  curl -sSfL --retry 3 "$url" | tee >(sha256sum | cut -d' ' -f1 >"$tmp/sha") \
    | tar -xj -C "$tmp/x" --wildcards \
        "*/$lib/primitives.v" "*/$lib/sky130_fd_sc_hd.v" 2>"$tmp/tarerr" || true
  wait
  got="$(cat "$tmp/sha")"
  [ "$got" = "$want" ] || { echo "sky130 package sha256 mismatch: got $got want $want" >&2; exit 1; }
  src="$(find "$tmp/x" -path "*/$lib/primitives.v" | head -1)"
  [ -n "$src" ] || { echo "models not found in package" >&2; cat "$tmp/tarerr" >&2; exit 1; }
  root="${src%/$lib/primitives.v}"
  rm -rf "$dest/$lib" "$dest/.sha256"; mkdir -p "$dest/$lib"
  cp "$root/$lib/primitives.v" "$root/$lib/sky130_fd_sc_hd.v" "$dest/$lib/"
  echo "$want" >"$dest/.sha256"
fi
echo "$dest"
