# source this: puts openroad, klayout, magic on PATH and sets PDK_ROOT / PDK.
EDA_HOME="${EDA_HOME:-$HOME/tools}"
_e="$EDA_HOME/mm/root/envs"
export PATH="$PATH:$_e/openroad/bin:$_e/klayout/bin:$_e/magic/bin"  # appended so system python3 stays first
export PDK_ROOT="$_e/pdk/share/pdk"
export PDK=sky130A
unset _e
