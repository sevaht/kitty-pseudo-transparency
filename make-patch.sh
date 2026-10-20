#!/usr/bin/env bash
# SPDX-License-Identifier: Unlicense
# Regenerate the package patch from a kitty checkout that has the change applied
# (KITTY_SRC, default ~/scm/kitty).
#
# The patch is everything that differs from the upstream commit the checked-out
# branch is based on, including uncommitted changes to tracked files, minus the
# changelog (released versions have no "future" section for it to apply to).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
src=${KITTY_SRC:-$HOME/scm/kitty}
patch_file=$here/0001-pseudo-transparent-background.patch

if ! git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$src is not a git checkout of kitty; set KITTY_SRC to one." >&2
    exit 1
fi

git -C "$src" fetch --quiet --tags origin
base=$(git -C "$src" merge-base HEAD origin/master)
git -C "$src" diff "$base" --no-color --binary -- . ':(exclude)docs/changelog.rst' >"$patch_file"
echo "wrote $patch_file ($(grep -c '^diff --git' "$patch_file") files, based on ${base:0:12})"
