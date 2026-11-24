#!/usr/bin/env bash
# Fetch only the sky130_fd_sc_hd Verilog cell models (primitives.v, sky130_fd_sc_hd.v) for
# gate-level simulation in CI, plus the tt_025C_1v80 liberty file (synthesis/STA, ~13 MB) and the tech LEF + cell LEF (OpenROAD read_lef, a few MB). Streams the pinned open_pdks.sky130a conda package (same one
# install_layout_tools.sh uses), checks its sha256, keeps just those files. Nothing is committed.
# Usage: scripts/fetch_sky130_models.sh [dest]   (default $HOME/.cache/turichips/pdk)
# Prints the PDK_ROOT to use; CI appends it to $GITHUB_ENV.
set -euo pipefail
TC="$(cd "$(dirname "$0")/.." && pwd)"
v() { sed -n "s/^$1=//p" "$TC/VERSIONS"; }
dest="${1:-$HOME/.cache/turichips/pdk}"
lib=sky130A/libs.ref/sky130_fd_sc_hd/verilog
libd=sky130A/libs.ref/sky130_fd_sc_hd/lib
liberty=sky130_fd_sc_hd__tt_025C_1v80.lib
tlef=sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
lef=sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
# SKY130_PDK_URL / SKY130_PDK_SHA256 override the pins (used by tests/fetch_sky130_models_test.sh)
url="${SKY130_PDK_URL:-$(v sky130_pdk_url)}"; want="${SKY130_PDK_SHA256:-$(v sky130_pdk_sha256)}"
# Only a verified fetch writes $dest/.sha256, so unverified files are never trusted.
if [ "$(cat "$dest/.sha256" 2>/dev/null)" != "$want" ] || [ ! -s "$dest/$lib/primitives.v" ] || [ ! -s "$dest/$lib/sky130_fd_sc_hd.v" ] || [ ! -s "$dest/$libd/$liberty" ] || [ ! -s "$dest/$tlef" ] || [ ! -s "$dest/$lef" ]; then
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$dest" "$tmp/x"
  curl -sSfL --retry 3 "$url" | tee >(sha256sum | cut -d' ' -f1 >"$tmp/sha") \
    | tar -xj -C "$tmp/x" --wildcards \
        "*/$lib/primitives.v" "*/$lib/sky130_fd_sc_hd.v" "*/$libd/$liberty" "*/$tlef" "*/$lef" 2>"$tmp/tarerr" || true
  wait
  got="$(cat "$tmp/sha")"
  [ "$got" = "$want" ] || { echo "sky130 package sha256 mismatch: got $got want $want" >&2; exit 1; }
  src="$(find "$tmp/x" -path "*/$lib/primitives.v" | head -1)"
  [ -n "$src" ] || { echo "models not found in package" >&2; cat "$tmp/tarerr" >&2; exit 1; }
  root="${src%/$lib/primitives.v}"
  [ -s "$root/$libd/$liberty" ] || { echo "liberty $liberty not found in package" >&2; exit 1; }
  [ -s "$root/$tlef" ] && [ -s "$root/$lef" ] || { echo "LEF files not found in package" >&2; exit 1; }
  rm -rf "$dest/$lib" "$dest/$libd" "$dest/.sha256"; mkdir -p "$dest/$lib" "$dest/$libd" "$dest/$(dirname $tlef)" "$dest/$(dirname $lef)"
  cp "$root/$lib/primitives.v" "$root/$lib/sky130_fd_sc_hd.v" "$dest/$lib/"
  cp "$root/$libd/$liberty" "$dest/$libd/"
  cp "$root/$tlef" "$dest/$tlef"; cp "$root/$lef" "$dest/$lef"
  echo "$want" >"$dest/.sha256"
fi
echo "$dest"
