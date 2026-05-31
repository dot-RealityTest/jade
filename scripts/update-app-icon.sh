#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="${1:-$PROJECT_ROOT/Muxy/Resources/AppIcon.png}"
ICONSET="$PROJECT_ROOT/Muxy/Resources/Assets.xcassets/AppIcon.appiconset"
RESOURCES="$PROJECT_ROOT/Muxy/Resources"

if [[ ! -f "$SOURCE" ]]; then
    echo "Usage: scripts/update-app-icon.sh [path/to/icon.png]" >&2
    echo "Source must be a square PNG (1024×1024 recommended)." >&2
    exit 1
fi

width=$(sips -g pixelWidth "$SOURCE" 2>/dev/null | awk '/pixelWidth/ { print $2 }')
height=$(sips -g pixelHeight "$SOURCE" 2>/dev/null | awk '/pixelHeight/ { print $2 }')
if [[ "$width" != "$height" ]]; then
    echo "Error: icon must be square (got ${width}×${height})." >&2
    exit 1
fi

echo "==> Updating AppIcon from $SOURCE"
if [[ "$(cd "$(dirname "$SOURCE")" && pwd)/$(basename "$SOURCE")" != "$(cd "$RESOURCES" && pwd)/AppIcon.png" ]]; then
    cp "$SOURCE" "$RESOURCES/AppIcon.png"
fi
python3 "$SCRIPT_DIR/strip-icon-black-matte.py" "$RESOURCES/AppIcon.png"

resize() {
    sips -s format png -z "$2" "$2" "$RESOURCES/AppIcon.png" --out "$ICONSET/$1" >/dev/null
}

resize icon_16.png 16
resize icon_16@2x.png 32
resize icon_32.png 32
resize icon_32@2x.png 64
resize icon_128.png 128
resize icon_128@2x.png 256
resize icon_256.png 256
resize icon_256@2x.png 512
resize icon_512.png 512
resize icon_512@2x.png 1024

echo "==> Rebuilding resource bundle"
(cd "$PROJECT_ROOT" && swift build)

echo "==> Done. Run ./scripts/run-jade.sh to launch Jade with the new icon."
