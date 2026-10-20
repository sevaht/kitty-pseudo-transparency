# kitty-pseudo-transparency

An Arch Linux package of [kitty](https://sw.kovidgoyal.net/kitty/) with a patch that gives it a
**pseudo-transparent background without a compositor**, like `urxvt -tr`: the window stays
opaque and kitty draws the part of the desktop wallpaper that is behind it.

This is a personal build, not part of upstream kitty. It is official kitty plus one patch.

## What it adds

Two options, X11 only:

| option | values | meaning |
|---|---|---|
| `background_image_origin` | `window` (default), `monitor`, `desktop`, `wallpaper` | what the background image is laid out against. `monitor` and `desktop` lay the configured `background_image` out against the monitor(s) or the whole desktop, so it stays fixed on the screen while the window moves. `wallpaper` ignores `background_image` and uses the desktop's actual wallpaper. |
| `background_image_margin_color` | a color (default `#000000`) | what is shown where the image does not cover the monitor or desktop (`monitor` / `desktop` only) |

The simplest configuration, using the real wallpaper:

```
background_opacity 1
background_image_origin wallpaper
background_tint 0.7
```

`background_tint` blends the background color over the wallpaper (the existing kitty option),
so `0.7` looks like a `background_opacity` of `0.7` would over a compositor.

Notes:

- `wallpaper` reads the pixmap that wallpaper setters leave on the X root window
  (`_XROOTPMAP_ID`; `feh --bg-*`, `hsetroot`, `nitrogen` and similar set it) and follows
  changes to it. If there is no such wallpaper, kitty logs one line and behaves as `window`.
- Windows spanning several monitors show each monitor's own part of the image.
- The image follows the window when it is moved; while it is being dragged the update happens
  when your window manager reports the new position (often only when the drag ends).
- On Wayland the position of a window is not available to applications, so all values behave
  like `window` there (and real `background_opacity` is cheap on Wayland anyway).

Tested with kitty 0.49.2 on Arch Linux under X11 with two monitors.

## Installing

```
git clone git@github.com:sevaht/kitty-pseudo-transparency.git
cd kitty-pseudo-transparency
./update.sh                # builds the package for the kitty version Arch currently has
sudo pacman -U kitty-pseudo-transparency-*.pkg.tar.zst
```

The package `provides` and `conflicts` with `kitty`; pacman will ask whether to replace it.
`kitty-terminfo` and `kitty-shell-integration` stay the official Arch packages. Build
dependencies are listed in the `PKGBUILD`; neither script uses sudo. To go back to stock kitty:
`sudo pacman -S kitty`.

The build leaves out kitty's man pages and HTML documentation, because building them needs
`sphinx_design`, which is not in the Arch repositories.

## Updating

Arch updates never touch this package (it is in no repository), so after a `pacman -Syu` that
brings a new kitty:

```
./update.sh --check        # offline; exit status 10 means a rebuild is needed
./update.sh                # downloads that release, checks the patch applies, builds
sudo pacman -U kitty-pseudo-transparency-*.pkg.tar.zst
```

`update.sh VERSION` targets a specific release, and `--no-build` only updates the `PKGBUILD`.
`--check` and a bare `update.sh` are all a scheduler or wrapper script needs to automate this.

### When the patch stops applying

`update.sh` stops and shows the failing hunks. The change lives in
`0001-pseudo-transparent-background.patch`; to rework it, apply it to a kitty checkout:

```
git clone https://github.com/kovidgoyal/kitty && cd kitty
git checkout -b pseudo-transparency v<release>
git apply --3way /path/to/0001-pseudo-transparent-background.patch   # fix conflicts
```

Four of the files are generated and are best regenerated instead of merged by hand:
`kitty/options/parse.py`, `kitty/options/types.py`, `kitty/options/to-c-generated.h` and
`kitty/glfw-wrapper.{c,h}` (from `kitty/options/definition.py` and `glfw/glfw.py`). Then
regenerate the patch from that checkout, which also compares it against `origin/master`:

```
KITTY_SRC=/path/to/kitty ./make-patch.sh
./update.sh
```

## Files

| file | purpose |
|---|---|
| `PKGBUILD` | builds the official kitty release tarball with the patch applied |
| `0001-pseudo-transparent-background.patch` | the change to kitty (no changelog entry, since releases have no section for it) |
| `update.sh` | tracks Arch's kitty version, checks the patch applies, updates the checksums, builds |
| `make-patch.sh` | regenerates the patch from a kitty checkout (`KITTY_SRC`) |
| `LICENSE`, `LICENSE-GPL-3.0` | Unlicense (scripts, packaging) and GPL-3.0 (the patch), see [License](#license) |

## License

- The scripts, the `PKGBUILD`, and this README are released into the public domain under the
  [Unlicense](LICENSE).
- The patch (`0001-pseudo-transparent-background.patch`) is a modification of kitty and so stays
  under kitty's own license, [GPL-3.0-only](LICENSE-GPL-3.0); the package built from it is
  GPL-3.0-only too, which is what the `PKGBUILD`'s `license` field says. kitty itself is
  copyright Kovid Goyal and contributors and its license is unchanged.
