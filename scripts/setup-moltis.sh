#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MOLTIS_VERSION="20260518.01"
MOLTIS_BINARY="$PROJECT_ROOT/Muxy/Resources/moltis"
MOLTIS_SHARE="$PROJECT_ROOT/Muxy/Resources/moltis-share"

fetch_moltis() {
    if [[ -x "$MOLTIS_BINARY" && -d "$MOLTIS_SHARE" ]]; then
        echo "==> Moltis already present at $MOLTIS_BINARY"
        return 0
    fi

    local arch
    case "$(uname -m)" in
        arm64) arch="aarch64-apple-darwin" ;;
        x86_64) arch="x86_64-apple-darwin" ;;
        *) echo "Error: unsupported architecture $(uname -m)"; return 1 ;;
    esac

    local archive="moltis-${MOLTIS_VERSION}-${arch}.tar.gz"
    local url="https://github.com/moltis-org/moltis/releases/download/${MOLTIS_VERSION}/${archive}"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN

    echo "==> Downloading Moltis ${MOLTIS_VERSION} (${arch})"
    curl -fsSL "$url" -o "$tmp/$archive"
    tar xzf "$tmp/$archive" -C "$tmp"

    local extracted="$tmp/moltis-${MOLTIS_VERSION}-${arch}"
    mkdir -p "$(dirname "$MOLTIS_BINARY")"
    cp "$extracted/moltis" "$MOLTIS_BINARY"
    chmod +x "$MOLTIS_BINARY"
    rm -rf "$MOLTIS_SHARE"
    cp -R "$extracted/share/moltis" "$MOLTIS_SHARE"
    codesign --force --sign - "$MOLTIS_BINARY" >/dev/null 2>&1 || true
    echo "    Installed: $MOLTIS_BINARY"
    echo "    Share dir: $MOLTIS_SHARE"
    echo ""
    echo "To bundle Moltis into local debug builds, run:"
    echo "  MUXY_BUNDLE_MOLTIS=1 swift build"
    echo "Release packaging never ships Moltis; debug routing still resolves the source tree copy."
}

fetch_moltis
