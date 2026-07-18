#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_BUILD="$ROOT_DIR/.test-build"
TEST_EXECUTABLE="$TEST_BUILD/ruler-geometry-tests"
PREFERENCES_TEST_EXECUTABLE="$TEST_BUILD/ruler-preferences-tests"

rm -rf "$TEST_BUILD"
mkdir -p "$TEST_BUILD"

xcrun swiftc \
  -parse-as-library \
  -swift-version 5 \
  -framework CoreGraphics \
  "$ROOT_DIR/Sources/RulerGeometry.swift" \
  "$ROOT_DIR/Tests/RulerGeometryTests.swift" \
  -o "$TEST_EXECUTABLE"

"$TEST_EXECUTABLE"

xcrun swiftc \
  -parse-as-library \
  -swift-version 5 \
  -framework AppKit \
  -framework Combine \
  -framework CoreGraphics \
  "$ROOT_DIR/Sources/RulerGeometry.swift" \
  "$ROOT_DIR/Sources/Localization.swift" \
  "$ROOT_DIR/Sources/RulerState.swift" \
  "$ROOT_DIR/Tests/RulerPreferencesTests.swift" \
  -o "$PREFERENCES_TEST_EXECUTABLE"

"$PREFERENCES_TEST_EXECUTABLE"
"$ROOT_DIR/build.sh" >/dev/null
open -W -n "$ROOT_DIR/build/屏幕十字标尺.app" --args --smoke-test
codesign --verify --deep --strict "$ROOT_DIR/build/屏幕十字标尺.app"
lipo -archs "$ROOT_DIR/build/屏幕十字标尺.app/Contents/MacOS/ScreenCrossRuler" \
  | grep -q 'x86_64 arm64\|arm64 x86_64'
rm -rf "$TEST_BUILD"
echo "APP_SMOKE_TEST_PASSED"
