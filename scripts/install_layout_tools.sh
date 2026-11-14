#!/usr/bin/env bash
# Install the layout tools (OpenROAD, KLayout, Magic, sky130 PDK) with micromamba, no root needed.
# Usage: scripts/install_layout_tools.sh   -> tools in $EDA_HOME (default ~/tools)
# Then:  source scripts/eda-env.sh
# Versions are pinned in VERSIONS (openroad, klayout, magic, sky130_pdk).
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
"$MM" create -y -q -n openroad $LH "openroad=$(v openroad)*"
"$MM" create -y -q -n klayout  -c conda-forge "klayout=$(v klayout)"
"$MM" create -y -q -n magic    $LH "magic=$(v magic)*"
"$MM" create -y -q -n pdk      $LH "open_pdks.sky130a=$(v sky130_pdk)*"
echo "done. source $TC/scripts/eda-env.sh"
