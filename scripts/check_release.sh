#!/usr/bin/env bash
# Usage: scripts/check_release.sh vX.Y  -> exit 1 unless every version pin in the tree is vX.Y
set -eu; v="${1:?version}"; cd "$(git rev-parse --show-toplevel)"; rc=0
chk() { grep -qE "$2" "$1" || { echo "MISMATCH $1: want $v"; rc=1; }; }
chk .github/workflows/ci.yml "toolchain_ref: \{ type: string, default: $v \}"
chk templates/Makefile "^TOOLCHAIN_REF \?= $v\$"
chk templates/ci.yml "ci\.yml@$v\$"
exit $rc
