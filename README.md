# toolchain
Shared build, test, synth and CI for every Turichips chip repo. Owner: Otto.

Chip repo setup: copy `templates/Makefile` to the root and `templates/ci.yml` to `.github/workflows/ci.yml`. Then `make all`, or `make test BLOCK=name`.

Test layout (Quinn): `tb/<block>/files.f` (file list from repo root) and `tb.sv` (top module `tb`, prints `PASS`).
Synthesis: runs `synth/run.sh` in the chip repo if present (Petra).
Tool versions are pinned in `VERSIONS`; a mismatch fails the run. Chips pin a toolchain tag (`TOOLCHAIN_REF`) and bump it on purpose.
If `.toolchain` is not at the pinned tag, `make` stops with "toolchain mismatch": bump `TOOLCHAIN_REF` and the `@tag` in `.github/workflows/ci.yml` together and `rm -rf .toolchain`. For toolchain development, `make TOOLCHAIN_REF=` turns the check off.
Logs: `logs/<run>/` with `summary.md`, per-block logs and `tool-versions.txt`.
