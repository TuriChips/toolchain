#!/usr/bin/env bash
# Install the layout tools (OpenROAD, KLayout, Magic, sky130 PDK) with micromamba, no root needed.
# Usage: scripts/install_layout_tools.sh   -> tools in $EDA_HOME (default ~/tools)
# Then:  source scripts/eda-env.sh
# ONLY=openroad installs just that env (CI uses this). Versions are pinned in VERSIONS (openroad, klayout, magic, sky130_pdk).
# Separate envs, because conda cannot solve openroad and klayout together.
set -eu
EDA_HOME="${EDA_HOME:-$HOME/tools}"
TC="$(cd "$(dirname "$0")/.." && pwd)"
v() { sed -n "s/^$1=//p" "$TC/VERSIONS"; }
export MAMBA_ROOT_PREFIX="$EDA_HOME/mm/root"
MM="$EDA_HOME/mm/bin/micromamba"
if [ ! -x "$MM" ]; then
  mkdir -p "$EDA_HOME/mm"
  curl -sL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C "$EDA_HOME/mm" bin/micromamba
fi
LH="-c litex-hub -c conda-forge"
only() { [ -z "${ONLY:-}" ] || [ "$ONLY" = "$1" ]; }
if only openroad; then "$MM" create -y -q -n openroad $LH "openroad=$(v openroad)*"; fi
if only klayout; then "$MM" create -y -q -n klayout -c conda-forge "klayout=$(v klayout)"; fi
if only magic; then "$MM" create -y -q -n magic $LH "magic=$(v magic)*"; fi
if only poppler; then
  "$MM" create -y -q -n poppler -c conda-forge "poppler=$(v poppler)*"
  # pdftoppm etc. on the default PATH (the Read tool renders PDF pages with pdftoppm)
  mkdir -p "$HOME/.local/bin"; for t in pdftoppm pdftotext pdfimages pdfinfo; do ln -sf "$EDA_HOME/mm/root/envs/poppler/bin/$t" "$HOME/.local/bin/$t"; done
fi
if only pdk; then "$MM" create -y -q -n pdk $LH "open_pdks.sky130a=$(v sky130_pdk)*"; fi
echo "done. source $TC/scripts/eda-env.sh"
