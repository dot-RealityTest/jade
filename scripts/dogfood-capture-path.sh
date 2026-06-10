#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/arm64-apple-macosx/debug"
APP="$BUILD_DIR/Jade.app"
MARKER="jade-dogfood-$(date +%Y%m%d-%H%M%S)"

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
DIM='\033[2m'
RESET='\033[0m'

pass() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; exit 1; }
skip() { echo -e "  ${YELLOW}○${RESET} $1"; }
section() { echo -e "\n${DIM}==>${RESET} $1"; }

cd "$PROJECT_ROOT"

section "Unit tests (capture path)"
swift test --filter 'CapturePathIntegration|ProjectInspectorStore|Jade Journey|Obsidian Note Path|RichInputSubmitter' 2>&1 | tail -5
pass "Capture-path unit tests"

OBSIDIAN_PY="${OBSIDIAN_PYTHON_PATH:-}"
OBSIDIAN_SERVER="${OBSIDIAN_SERVER_SCRIPT:-}"
OBSIDIAN_VAULT="${OBSIDIAN_VAULT_PATH:-}"

if [[ -x "$OBSIDIAN_PY" && -f "$OBSIDIAN_SERVER" && -d "$OBSIDIAN_VAULT" ]]; then
  section "Live Obsidian MCP (vault write + verify)"
  export JADE_DOGFOOD_OBSIDIAN=1
  export OBSIDIAN_PYTHON_PATH="$OBSIDIAN_PY"
  export OBSIDIAN_SERVER_SCRIPT="$OBSIDIAN_SERVER"
  export OBSIDIAN_VAULT_PATH="$OBSIDIAN_VAULT"
  swift test --filter 'Capture Path Live Obsidian' 2>&1 | tail -8
  pass "Obsidian vault round-trip"
else
  skip "Obsidian MCP paths missing — set OBSIDIAN_* env vars to enable live vault test"
fi

section "Build Jade.app"
if [[ ! -x "$BUILD_DIR/Muxy" ]]; then
  swift build
fi
"$SCRIPT_DIR/run-jade.sh" >/dev/null 2>&1 || true
sleep 0.5
if pgrep -x Jade >/dev/null 2>&1; then
  pass "Jade.app running"
else
  open -n "$APP"
  sleep 3
  pgrep -x Jade >/dev/null 2>&1 || fail "Jade did not launch"
  pass "Jade.app launched"
fi

section "UI smoke (Peekaboo)"
if ! command -v peekaboo >/dev/null 2>&1; then
  skip "peekaboo not installed — brew install steipete/tap/peekaboo"
  exit 0
fi

peekaboo permissions --json >/dev/null 2>&1 || true

jade "$PROJECT_ROOT" >/dev/null 2>&1 || true
sleep 3

for _ in 1 2 3; do
  peekaboo app activate "Jade" --foreground 2>/dev/null \
    || osascript -e 'tell application "Jade" to activate' >/dev/null 2>&1 \
    || true
  sleep 1
  FRONT=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
  if [[ "$FRONT" == "Jade" ]]; then
    break
  fi
done

if [[ "$FRONT" != "Jade" ]]; then
  fail "Jade is not frontmost (got: ${FRONT:-unknown}). Close overlapping apps and retry."
fi
pass "Jade is frontmost"

peekaboo hotkey "cmd,i" --app Jade --foreground 2>/dev/null || peekaboo hotkey "cmd,i" --app Jade
sleep 1.5

peekaboo hotkey "cmd,k" --app Jade --foreground 2>/dev/null || peekaboo hotkey "cmd,k" --app Jade
sleep 0.8
peekaboo type "Toggle Rich Input" --app Jade --delay 5 2>/dev/null || peekaboo type "Toggle Rich Input" --delay 5
sleep 0.5
peekaboo press return --app Jade 2>/dev/null || peekaboo hotkey return --app Jade
sleep 1.2

peekaboo type "$MARKER" --app Jade --delay 5 2>/dev/null || peekaboo type "$MARKER" --delay 5
sleep 0.8

SHOT="/tmp/jade-dogfood-rich-input.png"
peekaboo image --app Jade --path "$SHOT" --retina 2>/dev/null || peekaboo image --mode frontmost --path "$SHOT" --retina

if [[ ! -f "$SHOT" ]]; then
  fail "Peekaboo capture failed — check Screen Recording permission for Terminal/Cursor"
fi

ANALYSIS=$(peekaboo see --path "$SHOT" --analyze "Is a Rich Input or side panel visible? Is there a text field or editor?" 2>/dev/null || true)
if [[ -n "$ANALYSIS" ]]; then
  echo -e "${DIM}  peekaboo:${RESET} ${ANALYSIS:0:200}..."
fi

pass "Rich Input opened and typed marker: $MARKER"
pass "Screenshot: $SHOT"

section "Done"
echo -e "Capture-path dogfood finished. Review ${SHOT} if UI looked wrong."
