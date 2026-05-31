#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/arm64-apple-macosx/debug"
APP="$BUILD_DIR/Jade.app"
BIN="$BUILD_DIR/Muxy"
RESOURCE_BUNDLE="$BUILD_DIR/Muxy_Muxy.bundle"
SOURCE_ICON="$PROJECT_ROOT/Muxy/Resources/AppIcon.png"
SPARKLE="$PROJECT_ROOT/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

needs_build=false
if [[ ! -x "$BIN" ]]; then
    needs_build=true
elif [[ ! -d "$RESOURCE_BUNDLE" ]]; then
    needs_build=true
elif [[ -f "$SOURCE_ICON" && "$SOURCE_ICON" -nt "$RESOURCE_BUNDLE/AppIcon.png" ]]; then
    needs_build=true
fi

if [[ "$needs_build" == true ]]; then
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
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.0.0-dev" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 0" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :SUEnableAutomaticChecks false" "$APP/Contents/Info.plist"
cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"
cp "$SOURCE_ICON" "$APP/Contents/Resources/Muxy_Muxy.bundle/AppIcon.png"
"$SCRIPT_DIR/create-icns.sh" "$APP/Contents/Resources/AppIcon.icns"
cp -R "$SPARKLE" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/Jade" 2>/dev/null || true
codesign --force --deep --sign - "$APP" >/dev/null

echo "==> Launching Jade"
open -n "$APP"
