#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="屏幕十字标尺"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
PKGROOT="$ROOT_DIR/build/pkgroot"
VERSION="1.1.1"

"$ROOT_DIR/build.sh" >/dev/null
rm -rf "$DIST_DIR" "$PKGROOT"
mkdir -p "$DIST_DIR" "$PKGROOT"
ditto --norsrc --noextattr --noacl "$APP_DIR" "$PKGROOT/$APP_NAME.app"
pkgbuild \
  --root "$PKGROOT" \
  --install-location "/Applications" \
  --identifier "local.codex.screen-cross-ruler.pkg" \
  --version "$VERSION" \
  "$DIST_DIR/ScreenCrossRuler-$VERSION-unsigned.pkg" >/dev/null
ditto -c -k --sequesterRsrc --keepParent \
  "$APP_DIR" \
  "$DIST_DIR/ScreenCrossRuler-$VERSION-macOS-universal.zip"
echo "$DIST_DIR/ScreenCrossRuler-$VERSION-unsigned.pkg"
echo "$DIST_DIR/ScreenCrossRuler-$VERSION-macOS-universal.zip"
