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
if [ ! -s "$dest/$lib/primitives.v" ] || [ ! -s "$dest/$lib/sky130_fd_sc_hd.v" ]; then
  url="$(v sky130_pdk_url)"; want="$(v sky130_pdk_sha256)"
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$dest"
  curl -sSfL --retry 3 "$url" | tee >(sha256sum | cut -d' ' -f1 >"$tmp/sha") \
    | tar -xj -C "$dest" --strip-components=0 --wildcards \
        "*/$lib/primitives.v" "*/$lib/sky130_fd_sc_hd.v" 2>"$tmp/tarerr" || true
  wait
  got="$(cat "$tmp/sha")"
  [ "$got" = "$want" ] || { echo "sky130 package sha256 mismatch: got $got want $want" >&2; exit 1; }
  # members live under share/pdk/ in the package; flatten to $dest/sky130A/...
  src="$(find "$dest" -path "*/$lib/primitives.v" | head -1)"
  [ -n "$src" ] || { echo "models not found in package" >&2; cat "$tmp/tarerr" >&2; exit 1; }
  root="${src%/$lib/primitives.v}"
  [ "$root" = "$dest" ] || { mkdir -p "$dest/$lib"; cp "$root/$lib/"*.v "$dest/$lib/"; rm -rf "$dest/share"; }
fi
echo "$dest"
