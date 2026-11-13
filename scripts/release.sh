#!/usr/bin/env bash
# Two steps, because main only changes through merged PRs:
#   scripts/release.sh vX.Y         on a branch: bump every version pin, run checks, commit.
#                                   Open a PR for it; after it merges:
#   scripts/release.sh --tag vX.Y   on up-to-date main: verify the pins, then tag and print the push command.
# The tag therefore always carries its own defaults (toolchain#13).
set -eu
mode=bump; [ "${1:-}" = "--tag" ] && { mode=tag; shift; }
v="${1:?usage: release.sh [--tag] vX.Y}"; [[ "$v" =~ ^v[0-9]+\.[0-9]+$ ]] || { echo "bad version $v"; exit 1; }
cd "$(git rev-parse --show-toplevel)"
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean"; exit 1; }
! git rev-parse -q --verify "refs/tags/$v" >/dev/null || { echo "tag $v exists"; exit 1; }
if [ $mode = bump ]; then
  sed -i -E "s/(toolchain_ref: \{ type: string, default: )v[0-9]+\.[0-9]+/\1$v/" .github/workflows/ci.yml
  sed -i -E "s/^(TOOLCHAIN_REF \?= )v[0-9]+\.[0-9]+/\1$v/" templates/Makefile
  sed -i -E "s/(ci\.yml@)v[0-9]+\.[0-9]+/\1$v/" templates/ci.yml
  scripts/check_release.sh "$v"; tests/smoke.sh
  if git diff --quiet; then echo "pins already at $v, nothing to bump. After main has them: scripts/release.sh --tag $v"; exit 0; fi
  git commit -qam "Release $v: bump version pins" && echo "committed. Open a PR; after it merges: scripts/release.sh --tag $v"
else
  git fetch -q origin main
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "--tag must run on HEAD == origin/main (git checkout main && git pull)"; exit 1; }
  scripts/check_release.sh "$v"
  git tag "$v" && echo "tagged $v at $(git rev-parse --short HEAD). Push: git push origin $v"
fi
