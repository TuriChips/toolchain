# toolchain
Shared build, test, synth and CI for every Turichips chip repo. Owner: Otto.

Chip repo setup: copy `templates/Makefile` to the root and `templates/ci.yml` to `.github/workflows/ci.yml`. Then `make all`, or `make test BLOCK=name`.

Test layout (Quinn): `tb/<block>/files.f` (file list from repo root) and `tb.sv` (top module `tb`, prints `PASS`).
Synthesis: runs `synth/run.sh` in the chip repo if present (Petra).
Tool versions are pinned in `VERSIONS`; a mismatch fails the run. Chips pin a toolchain tag (`TOOLCHAIN_REF`) and bump it on purpose.
Releases: `scripts/release.sh vX.Y` on a branch (bumps all pins, commits), PR, then `scripts/release.sh --tag vX.Y` on main. A tag push runs `check_release.sh`, so a tag with stale pins goes red.
If `.toolchain` is not at the pinned tag, `make` stops with "toolchain mismatch": bump `TOOLCHAIN_REF` and the `@tag` in `.github/workflows/ci.yml` together and `rm -rf .toolchain`. For toolchain development, `make TOOLCHAIN_REF=` turns the check off.
Logs: `logs/<run>/` with `summary.md`, per-block logs and `tool-versions.txt`.

Layout tools (Tesla): `scripts/install_layout_tools.sh` installs OpenROAD, KLayout, Magic and the sky130 PDK without root (micromamba, into `~/tools`). `source scripts/eda-env.sh` puts them on PATH and sets `PDK_ROOT` and `PDK=sky130A`. PDK path on the lab VM: `~/tools/mm/root/envs/pdk/share/pdk/sky130A`. Pins are in `VERSIONS`; `versions.sh` fails on a mismatch if the tool is on PATH.

CI gate-level models (Tesla): the chip CI job caches and exports `PDK_ROOT` with only `sky130_fd_sc_hd/verilog/{primitives.v,sky130_fd_sc_hd.v}`, fetched by `scripts/fetch_sky130_models.sh` from the pinned package (`sky130_pdk_url`, `sky130_pdk_sha256` in `VERSIONS`). Cold fetch ~4 min, then cached. Chips get it by bumping `TOOLCHAIN_REF` to the release that includes this.
