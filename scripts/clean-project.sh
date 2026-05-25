#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find "$ROOT" -name .DS_Store -type f -delete
rm -rf "$ROOT/.omx" "$ROOT/.muxy" "$ROOT/.plans" "$ROOT/muxy-markdown-remote-image-urlcache"
rm -f "$ROOT/Muxy/Resources/moltis" 2>/dev/null || true
rm -rf "$ROOT/Muxy/Resources/moltis-share" 2>/dev/null || true

if [[ "${1:-}" == "--build" ]]; then
  rm -rf "$ROOT/.build" "$ROOT/build" "$ROOT/DerivedData"
fi
