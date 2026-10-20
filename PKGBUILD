# SPDX-License-Identifier: Unlicense (this file; the package itself is GPL-3.0-only)
# kitty with a pseudo-transparent background: background_image_origin
# (monitor, desktop, wallpaper) and background_image_margin_color.
# Built without the man pages and HTML docs (see prepare()).
# See README.md for how the patch and this package are kept up to date.

pkgname=kitty-pseudo-transparency
_pkgbase=kitty
pkgver=0.49.2
pkgrel=1
pkgdesc="Modern, hackable, featureful, OpenGL based terminal emulator, with a pseudo-transparent background"
arch=(x86_64)
url="https://sw.kovidgoyal.net/kitty/"
license=(GPL-3.0-only)
depends=(
  cairo
  dbus
  fontconfig
  freetype2
  harfbuzz
  hicolor-icon-theme
  kitty-shell-integration
  kitty-terminfo
  lcms2
  libgl
  libpng
  librsync
  libx11
  libxcursor
  libxi
  libxkbcommon
  libxkbcommon-x11
  openssl
  python
  wayland
  xxhash
  zlib
)
makedepends=(
  go
  libcanberra
  libxinerama
  libxrandr
  mesa
  python-setuptools
  shader-slang
  simde
  ttf-nerd-fonts-symbols-mono
  wayland-protocols
)
optdepends=(
  'imagemagick: viewing images with icat'
  'libcanberra: playing "bell" sound on terminal bell'
  'python-pygments: syntax highlighting in kitty +kitten diff'
)
provides=("kitty=$pkgver")
conflicts=(kitty)
source=(
  "$_pkgbase-$pkgver.tar.gz::https://github.com/kovidgoyal/kitty/archive/refs/tags/v$pkgver.tar.gz"
  0001-pseudo-transparent-background.patch
)
sha256sums=('e9ca20b49d0c262af956058ceb97cfef505552dc447d8328ea96d069a04570f3'
            '24e04469c0d8518fc8338166a29b0f3635b6c6eb17ec50d9a5d8aa4e1927f895')

prepare() {
  cd "$_pkgbase-$pkgver"
  patch -Np1 -i ../0001-pseudo-transparent-background.patch

  # Build without the man pages and HTML docs, whose build needs sphinx_design,
  # which is not in the Arch repositories. setup.py only runs `make docs` when
  # docs/_build/html is missing, and only installs the docs unless skip_docs is set.
  mkdir -p docs/_build/html
  sed -i 's/^    skip_docs = False$/    skip_docs = True/' setup.py
  grep -q '^    skip_docs = True$' setup.py
}

build() {
  cd "$_pkgbase-$pkgver"
  export CGO_CPPFLAGS="${CPPFLAGS}"
  export CGO_CFLAGS="${CFLAGS}"
  export CGO_CXXFLAGS="${CXXFLAGS}"
  export CGO_LDFLAGS="${LDFLAGS}"
  export GOFLAGS="-buildmode=pie -trimpath -ldflags=-linkmode=external -mod=readonly -modcacherw"
  python setup.py linux-package --update-check-interval=0
}

package() {
  cd "$_pkgbase-$pkgver"

  cp -r linux-package "$pkgdir/usr"

  # shell completions
  python __main__.py + complete setup bash | install -Dm644 /dev/stdin "$pkgdir/usr/share/bash-completion/completions/kitty"
  python __main__.py + complete setup fish | install -Dm644 /dev/stdin "$pkgdir/usr/share/fish/vendor_completions.d/kitty.fish"
  {
    echo "#compdef kitty"
    python __main__.py + complete setup zsh
  } | install -Dm644 /dev/stdin "$pkgdir/usr/share/zsh/site-functions/_kitty"

  install -Dm644 "$pkgdir/usr/share/icons/hicolor/256x256/apps/kitty.png" "$pkgdir/usr/share/pixmaps/kitty.png"

  # provided by the kitty-terminfo and kitty-shell-integration packages
  rm -r "$pkgdir/usr/share/terminfo"
  rm -r "$pkgdir/usr/lib/kitty/shell-integration"

}
