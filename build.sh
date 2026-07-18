#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="屏幕十字标尺"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/ScreenCrossRuler"
RESOURCES="$APP_DIR/Contents/Resources"
ICONSET="$BUILD_DIR/AppIcon.iconset"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$RESOURCES" "$ICONSET"

SWIFT_FLAGS=(
  -O
  -parse-as-library
  -swift-version 5
  -framework AppKit
  -framework SwiftUI
  -framework Combine
  -framework CoreGraphics
)
SWIFT_SOURCES=(
  "$ROOT_DIR/Sources/RulerGeometry.swift"
  "$ROOT_DIR/Sources/Localization.swift"
  "$ROOT_DIR/Sources/RulerState.swift"
  "$ROOT_DIR/Sources/RulerOverlayView.swift"
  "$ROOT_DIR/Sources/SettingsView.swift"
  "$ROOT_DIR/Sources/main.swift"
)

xcrun swiftc "${SWIFT_FLAGS[@]}" -target arm64-apple-macos12.0 \
  "${SWIFT_SOURCES[@]}" -o "$BUILD_DIR/ScreenCrossRuler-arm64"
xcrun swiftc "${SWIFT_FLAGS[@]}" -target x86_64-apple-macos12.0 \
  "${SWIFT_SOURCES[@]}" -o "$BUILD_DIR/ScreenCrossRuler-x86_64"
lipo -create \
  "$BUILD_DIR/ScreenCrossRuler-arm64" \
  "$BUILD_DIR/ScreenCrossRuler-x86_64" \
  -output "$EXECUTABLE"

xcrun swiftc -framework AppKit "$ROOT_DIR/Sources/generate_icon.swift" -o "$BUILD_DIR/generate-icon"
"$BUILD_DIR/generate-icon" "$BUILD_DIR/AppIcon-1024.png"
while read -r filename pixels; do
  sips -z "$pixels" "$pixels" "$BUILD_DIR/AppIcon-1024.png" --out "$ICONSET/$filename" >/dev/null
done <<'SIZES'
icon_16x16.png 16
icon_16x16@2x.png 32
icon_32x32.png 32
icon_32x32@2x.png 64
icon_128x128.png 128
icon_128x128@2x.png 256
icon_256x256.png 256
icon_256x256@2x.png 512
icon_512x512.png 512
icon_512x512@2x.png 1024
SIZES
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

cp "$ROOT_DIR/LICENSE" "$RESOURCES/LICENSE.txt"
cp "$ROOT_DIR/ATTRIBUTION.md" "$RESOURCES/ATTRIBUTION.md"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR" >/dev/null
touch "$APP_DIR"
echo "$APP_DIR"
