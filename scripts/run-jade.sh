#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/arm64-apple-macosx/debug"
APP="$BUILD_DIR/Jade.app"
BIN="$BUILD_DIR/Muxy"
SPARKLE="$PROJECT_ROOT/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

if [[ ! -x "$BIN" ]]; then
    echo "==> Building debug Muxy"
    (cd "$PROJECT_ROOT" && swift build)
fi

if [[ ! -d "$SPARKLE" ]]; then
    echo "==> Fetching Sparkle (swift package resolve)"
    (cd "$PROJECT_ROOT" && swift package resolve)
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Jade"
chmod +x "$APP/Contents/MacOS/Jade"
cp "$PROJECT_ROOT/Muxy/Info.plist" "$APP/Contents/Info.plist"
cp -R "$BUILD_DIR/Muxy_Muxy.bundle" "$APP/Contents/Resources/"
cp -R "$SPARKLE" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/Jade" 2>/dev/null || true
codesign --force --deep --sign - "$APP" >/dev/null

echo "==> Launching Jade"
open -n "$APP"
