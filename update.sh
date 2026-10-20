#!/usr/bin/env bash
# SPDX-License-Identifier: Unlicense
# Keep the kitty-pseudo-transparency package in step with Arch's kitty.
#
#   update.sh              check that the patch applies to the version Arch's
#                          kitty is at, update the PKGBUILD, build the package
#   update.sh VERSION      the same for a specific kitty release, e.g. 0.50.0
#   update.sh --check      only report whether a rebuild is needed (exit 10 if
#                          so); needs no network
#   update.sh --no-build   prepare the PKGBUILD but do not run makepkg
#
# Nothing here uses sudo; installing the result is left to you.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
patch_file=0001-pseudo-transparent-background.patch
# a browser User-Agent, rather than makepkg's default curl one
user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'

check_only=0 build=1 version=
for arg in "$@"; do
    case $arg in
        --check) check_only=1 ;;
        --no-build) build=0 ;;
        -h | --help) sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) echo "unknown option: $arg" >&2; exit 1 ;;
        *) version=$arg ;;
    esac
done

# upstream version of Arch's kitty package: strip any epoch and the pkgrel
official=$(pacman -Si kitty | awk '/^Version/ {print $3}' | sed 's/^[0-9]*://; s/-[^-]*$//')
version=${version:-$official}
current=$(sed -n 's/^pkgver=//p' "$here/PKGBUILD")
patch_hash=$(sha256sum "$here/$patch_file" | cut -d' ' -f1)
recorded_hash=$(grep -o "'[0-9a-fA-F_A-Z]*'" "$here/PKGBUILD" | tr -d "'" | sed -n 2p)

if ((check_only)); then
    if [[ $version != "$current" ]]; then
        echo "update available: package is at $current, kitty is at $version"
        exit 10
    fi
    if [[ $patch_hash != "$recorded_hash" ]]; then
        echo "the patch changed since the PKGBUILD was last updated"
        exit 10
    fi
    echo "up to date ($current)"
    exit 0
fi

# fetch the release source with a browser User-Agent
tarball=kitty-$version.tar.gz
if [[ ! -f $here/$tarball ]]; then
    curl -fsL -A "$user_agent" -o "$here/$tarball" "https://github.com/kovidgoyal/kitty/archive/refs/tags/v$version.tar.gz" || {
        rm -f "$here/$tarball"
        echo "could not download kitty v$version" >&2
        exit 1
    }
fi
tar_hash=$(sha256sum "$here/$tarball" | cut -d' ' -f1)

# the patch has to apply to the release we are about to build
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tar -xzf "$here/$tarball" -C "$tmp" --strip-components=1
if ! (cd "$tmp" && patch -Np1 --dry-run --no-backup-if-mismatch <"$here/$patch_file" >"$tmp/patch.log" 2>&1); then
    cat "$tmp/patch.log" >&2
    cat >&2 <<EOF

The patch does not apply to kitty $version. Rebase the patch's source branch
onto v$version, resolve the conflicts, and regenerate the patch with
make-patch.sh (see "When the patch stops applying" in README.md).
EOF
    exit 2
fi

if [[ $version != "$current" ]]; then
    sed -i "s/^pkgver=.*/pkgver=$version/; s/^pkgrel=.*/pkgrel=1/" "$here/PKGBUILD"
fi
python3 - "$here/PKGBUILD" "$tar_hash" "$patch_hash" <<'EOF'
import re, sys
path, tar_hash, patch_hash = sys.argv[1:]
text = open(path).read()
new = f"sha256sums=('{tar_hash}'\n            '{patch_hash}')"
text, n = re.subn(r"sha256sums=\(.*?\)", new, text, count=1, flags=re.S)
assert n == 1
open(path, "w").write(text)
EOF
echo "PKGBUILD is at kitty $version"

if ((build)); then
    cd "$here"
    makepkg -fC --noprogressbar
    echo
    echo "Built. Install with:  sudo pacman -U $here/kitty-pseudo-transparency-$version-*.pkg.tar.zst"
fi
