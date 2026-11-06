#!/bin/sh
# Catch up to a recovery point without template branches.
# Creates branch catch-up/<point> from the first commit of main (the state generated
# from the template) and applies catch-up/<point>.patch, which holds the cumulative diff.
# Usage: sh scripts/catch-up.sh <point> [--dry-run]
#   points: 1-2, 2-1, 2-2, 3-1, eval-no-doc, drift-fixture
set -eu
point="${1:-}"
mode="${2:-}"
case "$point" in
  ''|-*|*[!A-Za-z0-9-]*) echo "usage: sh scripts/catch-up.sh <point> [--dry-run]" >&2; exit 3 ;;
esac
case "$mode" in
  ''|--dry-run) ;;
  *) echo "usage: sh scripts/catch-up.sh <point> [--dry-run]" >&2; exit 3 ;;
esac
cd "$(git rev-parse --show-toplevel)"
patch="catch-up/$point.patch"
[ -f "$patch" ] || { echo "no patch for point $point: $patch" >&2; ls catch-up/*.patch 2>/dev/null >&2; exit 3; }
git fetch --quiet origin main
base=$(git rev-list --max-parents=0 origin/main | tail -n 1)
if [ "$mode" = "--dry-run" ]; then
  tmp=$(mktemp -d)
  trap 'git worktree remove --force "$tmp" >/dev/null 2>&1; rm -rf "$tmp"' EXIT
  git worktree add --quiet --detach "$tmp" "$base"
  (cd "$tmp" && git apply --check "$OLDPWD/$patch") && echo "dry-run ok: $patch applies to $base" && exit 0
  echo "dry-run failed: $patch does not apply to $base" >&2; exit 1
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "uncommitted changes found. commit or stash them first (git stash -u)." >&2
  exit 1
fi
# The patch lives on main; keep a copy before switching to the base commit.
saved=$(mktemp)
trap 'rm -f "$saved"' EXIT
cp "$patch" "$saved"
git switch -c "catch-up/$point" "$base"
git apply --index "$saved"
git commit --quiet -m "catch up to recovery point $point"
echo "now on branch catch-up/$point. push with: git push -u origin catch-up/$point"
