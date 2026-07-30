#!/usr/bin/env bash
# build_deb.sh — Build VeloxMD as a Debian (.deb) package.
#
# Usage:
#   ./build_deb.sh            # builds release .deb
#   ./build_deb.sh --debug    # builds debug .deb
#
# Requirements: flutter, dpkg-deb (apt install dpkg).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_MODE="release"
APP_NAME="veloxmd"
OUTPUT_NAME="VeloxMD"
APP_VERSION="$(grep '^version:' "$SCRIPT_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"

# Map uname arch to Debian arch
case "$(uname -m)" in
  x86_64)  DEB_ARCH="amd64" ;;
  aarch64) DEB_ARCH="arm64" ;;
  armv7l)  DEB_ARCH="armhf" ;;
  *)       DEB_ARCH="$(uname -m)" ;;
esac

# Parse args
for arg in "$@"; do
  case "$arg" in
    --debug)   BUILD_MODE="debug" ;;
    --release) BUILD_MODE="release" ;;
    --help|-h)
      echo "Usage: $0 [--debug|--release]"
      exit 0
      ;;
  esac
done

BUNDLE_DIR="$SCRIPT_DIR/build/linux/x64/$BUILD_MODE/bundle"
OUTPUT_DIR="$SCRIPT_DIR/dist"
PKGROOT="$OUTPUT_DIR/${APP_NAME}-deb"
DEB_OUT="$OUTPUT_DIR/${OUTPUT_NAME}-${APP_VERSION}-${DEB_ARCH}.deb"

# ── 1. Flutter build ────────────────────────────────────────────────────────
echo "▶ Building Flutter Linux ($BUILD_MODE)…"
cd "$SCRIPT_DIR"
flutter build linux "--$BUILD_MODE"
echo "  Bundle: $BUNDLE_DIR"

# ── 2. Assemble package tree ─────────────────────────────────────────────────
echo "▶ Assembling package tree…"
rm -rf "$PKGROOT"

INSTALL_DIR="$PKGROOT/usr/lib/$APP_NAME"
BIN_DIR="$PKGROOT/usr/bin"
DESKTOP_DIR="$PKGROOT/usr/share/applications"
ICON_DIR="$PKGROOT/usr/share/icons/hicolor/256x256/apps"
DOC_DIR="$PKGROOT/usr/share/doc/$APP_NAME"

mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR" "$DOC_DIR"

# Copy Flutter bundle into /usr/lib/veloxmd/
cp -r "$BUNDLE_DIR/." "$INSTALL_DIR/"

# Wrapper script in /usr/bin so the binary is on PATH
cat > "$BIN_DIR/$APP_NAME" <<EOF
#!/bin/sh
exec /usr/lib/$APP_NAME/$APP_NAME "\$@"
EOF
chmod 755 "$BIN_DIR/$APP_NAME"

# Desktop entry
cp "$SCRIPT_DIR/linux/runner/resources/$APP_NAME.desktop" "$DESKTOP_DIR/"

# Icon — search common locations, use a 1×1 placeholder if none found
ICON_SRC=""
for candidate in \
    "$SCRIPT_DIR/assets/icon.png" \
    "$SCRIPT_DIR/assets/icons/icon.png" \
    "$SCRIPT_DIR/linux/runner/resources/$APP_NAME.png"; do
  if [[ -f "$candidate" ]]; then
    ICON_SRC="$candidate"
    break
  fi
done
if [[ -n "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$ICON_DIR/$APP_NAME.png"
else
  echo "  ⚠ No icon found; package will use a placeholder."
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "$ICON_DIR/$APP_NAME.png"
fi

# Minimal changelog (required by lintian)
cat > "$DOC_DIR/changelog.Debian.gz" /dev/null || true
gzip -9 -c /dev/null > "$DOC_DIR/changelog.Debian.gz"

# copyright file
cat > "$DOC_DIR/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: VeloxMD
Upstream-Contact: https://github.com/lbonomo/VeloxMD

Files: *
License: MIT
EOF

# ── 3. DEBIAN control files ──────────────────────────────────────────────────
echo "▶ Writing DEBIAN control files…"
mkdir -p "$PKGROOT/DEBIAN"

# Installed size in KB
INSTALLED_KB=$(du -sk "$PKGROOT/usr" | awk '{print $1}')

cat > "$PKGROOT/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $APP_VERSION
Architecture: $DEB_ARCH
Maintainer: VeloxMD contributors <https://github.com/lbonomo/VeloxMD>
Installed-Size: $INSTALLED_KB
Depends: libgtk-3-0, libglib2.0-0, libblkid1, libgcc-s1
Recommends: xdg-utils
Section: utils
Priority: optional
Homepage: https://github.com/lbonomo/VeloxMD
Description: Fast Markdown viewer for Linux desktop
 VeloxMD is a lightweight, keyboard-friendly Markdown viewer
 built with Flutter. It supports live file reload, a table of
 contents panel, drag-and-drop, dark/light theme, and opens
 .md files directly from the file manager.
EOF

# postinst: update desktop DB and icon cache after install
cat > "$PKGROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
EOF
chmod 755 "$PKGROOT/DEBIAN/postinst"

# postrm: clean up after removal
cat > "$PKGROOT/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database -q /usr/share/applications || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
    fi
fi
EOF
chmod 755 "$PKGROOT/DEBIAN/postrm"

# ── 4. Set correct permissions ───────────────────────────────────────────────
echo "▶ Setting permissions…"
find "$PKGROOT" -type d -exec chmod 755 {} \;
find "$PKGROOT/usr" -type f -exec chmod 644 {} \;
chmod 755 "$PKGROOT/usr/lib/$APP_NAME/$APP_NAME"
chmod 755 "$PKGROOT/usr/bin/$APP_NAME"

# ── 5. Build .deb ────────────────────────────────────────────────────────────
echo "▶ Building .deb package…"
mkdir -p "$OUTPUT_DIR"
dpkg-deb --root-owner-group --build "$PKGROOT" "$DEB_OUT"
rm -rf "$PKGROOT"

echo ""
echo "✅ Done!"
echo "   Output: $DEB_OUT"
echo ""
echo "Install with:  sudo dpkg -i $DEB_OUT"
echo "               sudo apt-get install -f   # fix any missing deps"
