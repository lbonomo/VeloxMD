#!/usr/bin/env bash
# build_appimage.sh — Build VeloxMD as a single portable AppImage for Linux.
#
# Usage:
#   ./build_appimage.sh            # builds release AppImage
#   ./build_appimage.sh --debug    # builds debug AppImage
#
# Requirements: flutter, wget/curl, fuse (or fuse3) for AppImage execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_MODE="release"
ARCH="$(uname -m)"
APP_NAME="veloxmd"
APP_VERSION="$(grep '^version:' "$SCRIPT_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"

# Parse args
for arg in "$@"; do
  case "$arg" in
    --debug) BUILD_MODE="debug" ;;
    --release) BUILD_MODE="release" ;;
    --help|-h)
      echo "Usage: $0 [--debug|--release]"
      exit 0
      ;;
  esac
done

BUNDLE_DIR="$SCRIPT_DIR/build/linux/x64/$BUILD_MODE/bundle"
OUTPUT_DIR="$SCRIPT_DIR/dist"
APPDIR="$OUTPUT_DIR/${APP_NAME}.AppDir"
APPIMAGE_OUT="$OUTPUT_DIR/${APP_NAME}-${APP_VERSION}-${ARCH}.AppImage"

# ── 1. Flutter build ────────────────────────────────────────────────────────
echo "▶ Building Flutter Linux ($BUILD_MODE)…"
cd "$SCRIPT_DIR"
flutter build linux "--$BUILD_MODE"
echo "  Bundle: $BUNDLE_DIR"

# ── 2. Locate or download appimagetool ──────────────────────────────────────
APPIMAGETOOL="$(command -v appimagetool 2>/dev/null || true)"
if [[ -z "$APPIMAGETOOL" ]]; then
  APPIMAGETOOL="$OUTPUT_DIR/appimagetool-${ARCH}.AppImage"
  if [[ ! -x "$APPIMAGETOOL" ]]; then
    echo "▶ Downloading appimagetool…"
    mkdir -p "$OUTPUT_DIR"
    DOWNLOAD_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
    if command -v wget &>/dev/null; then
      wget -q --show-progress -O "$APPIMAGETOOL" "$DOWNLOAD_URL"
    else
      curl -L --progress-bar -o "$APPIMAGETOOL" "$DOWNLOAD_URL"
    fi
    chmod +x "$APPIMAGETOOL"
  fi
fi
echo "  appimagetool: $APPIMAGETOOL"

# ── 3. Assemble AppDir ───────────────────────────────────────────────────────
echo "▶ Assembling AppDir…"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy Flutter bundle
cp -r "$BUNDLE_DIR/." "$APPDIR/usr/"

# Symlink the binary to the standard location
ln -sf "../${APP_NAME}" "$APPDIR/usr/bin/${APP_NAME}"

# Desktop file (required by AppImage)
cp "$SCRIPT_DIR/linux/runner/resources/${APP_NAME}.desktop" "$APPDIR/"
# Also put in standard location
mkdir -p "$APPDIR/usr/share/applications"
cp "$SCRIPT_DIR/linux/runner/resources/${APP_NAME}.desktop" "$APPDIR/usr/share/applications/"

# Icon — look for PNG assets; fall back to a plain SVG placeholder if absent
ICON_SRC=""
for candidate in \
    "$SCRIPT_DIR/assets/icon.png" \
    "$SCRIPT_DIR/assets/icons/icon.png" \
    "$SCRIPT_DIR/linux/runner/resources/${APP_NAME}.png"; do
  if [[ -f "$candidate" ]]; then
    ICON_SRC="$candidate"
    break
  fi
done
if [[ -n "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$APPDIR/${APP_NAME}.png"
  cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
else
  echo "  ⚠ No icon found; AppImage will use a default icon."
  # Create a minimal valid PNG (1x1 transparent) so appimagetool doesn't fail
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "$APPDIR/${APP_NAME}.png"
  cp "$APPDIR/${APP_NAME}.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
fi

# AppRun entry-point
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
SELF_DIR="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$SELF_DIR/usr/lib:${LD_LIBRARY_PATH:-}"
exec "$SELF_DIR/usr/veloxmd" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# ── 4. Package into AppImage ─────────────────────────────────────────────────
echo "▶ Packaging AppImage…"
mkdir -p "$OUTPUT_DIR"
ARCH="$ARCH" "$APPIMAGETOOL" --no-appstream "$APPDIR" "$APPIMAGE_OUT"

echo ""
echo "✅ Done!"
echo "   Output: $APPIMAGE_OUT"
echo ""
echo "Run with:  $APPIMAGE_OUT"
echo "           $APPIMAGE_OUT /path/to/file.md"
