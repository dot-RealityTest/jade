# Claude Feature Map — Muxy / Jade

Use this file as context when running Claude Code for Muxy development.
It contains the current project state, open problems, and prioritized feature backlog.

---

## Project Identity

- **User-facing name:** Jade
- **Internal name / bundle ID:** Muxy / `com.muxy.app`
- **What it is:** Lightweight macOS terminal multiplexer built with SwiftUI + libghostty (Metal rendering)
- **Platforms:** macOS 14+, iOS 17+ (companion app)
- **Repo:** `/Users/kika_hub/Projects/muxy/`
- **Build:** `scripts/setup.sh` → `swift build` → `swift run Muxy`
- **Checks:** Run `scripts/checks.sh --fix` after every task

---

## Architecture at a Glance

| Component | Role | File Hint |
|-----------|------|-------------|
| `GhosttyService` | Singleton managing single `ghostty_app_t` instance, 120fps tick, clipboard | `Muxy/Services/GhosttyService.swift` |
| `GhosttyTerminalNSView` | AppKit NSView hosting `ghostty_surface_t`, Metal rendering | `Muxy/Views/Terminal/GhosttyTerminalNSView.swift` |
| `GhosttyTerminalRepresentable` | `NSViewRepresentable` bridge into SwiftUI | `Muxy/Views/Terminal/GhosttyTerminalRepresentable.swift` |
| `AppState` | `@Observable` — projects → tabs → split pane trees, active project/tab | `Muxy/Models/AppState.swift` |
| `ProjectStore` | `@Observable` — persists projects to `~/Library/Application Support/Muxy/projects.json` | `Muxy/Services/ProjectStore.swift` |
| `GhosttyKit` | C module wrapping `ghostty.h`, prebuilt xcframework | `GhosttyKit/` + `GhosttyKit.xcframework/` |

### Critical Constraint: NSViewRepresentable
- **Never** return a cached/reused NSView from `makeNSView`. SwiftUI breaks silently.
- To keep a terminal alive across tab switches, mount all tabs in a `ZStack` with `opacity(0)` + `allowsHitTesting(false)` for inactive ones. Do not conditionally remove from tree.
- Blank view = most likely re-mounted from detached state.

---

## Current State (as of 2026-05-19)

### What Works
- Project-based workspace with persistent project list
- Vertical tabs with drag-drop reorder, pin, rename, middle-click close
- Horizontal + vertical split panes with keyboard navigation
- 200+ Ghostty themes with picker
- 40+ configurable shortcuts with conflict detection
- Built-in text editor with syntax highlighting
- In-terminal search with match navigation
- Auto-updates via Sparkle
- iOS companion app (TestFlight) with local server sync

### Known Gaps
1. **Built-in VCS is minimal.** Only basic git diff. No blame, log graph, or PR management.
2. **iOS companion niche.** High maintenance, unclear ROI.
3. **No note-taking integration** beside the built-in text editor.

---

## Implemented Features

### Session Persistence
- Workspace layout (tabs, splits, focus) is saved to `workspaces.json` and restored on launch
- Working directories are persisted per terminal pane via `GHOSTTY_ACTION_PWD` events
- Command tabs and external editor tabs survive restarts (startup command + file path are serialized)
- Toggle available in Settings → General → "Restore previous session on launch"
- Note: actual shell process state (running commands, scrollback buffer) cannot be persisted without tmux integration or libghostty state export

---

## Prioritized Backlog

### P0 — Tmux / Deep Session Integration
- Persist actual shell state (running processes, scrollback) via tmux integration or libghostty state export
- Would allow true session survival comparable to iTerm2/Warp

### P1 — Ghostty Config UI
- Built-in editor for `~/.config/ghostty/config`
- Validation against known Ghostty options
- Live reload preview
- Deliverable: `GhosttyConfigSettingsView.swift` + settings navigation integration

### P1 — Improved VCS
- ~~Git log graph~~ — Done
- Branch switcher with conflict warning
- Lazygit launch is already bound to `Cmd+Shift+G` — surface its UI inline or improve discoverability
- Deliverable: `VCSView` with log graph + branch list

### P2 — Plugin / Scripting
- Users want custom toolbar buttons and automations
- Could be AppleScript, Shortcuts integration, or lightweight Lua/JS scripts
- Deliverable: `PluginManager` + API for registering toolbar items

### P2 — AI Integration
- Inline AI assistant in terminal (similar to Warp/Windsurf)
- Could route to local Ollama or cloud API
- Deliverable: `AIAssistantPanel` + configurable model endpoint

### P3 — Window Management
- Multiple windows per project
- Float/pin panels (e.g., always-on-top snippet window)
- Deliverable: `WindowManager` + float state

---

## Technical Constraints

| Constraint | Implication |
|------------|-------------|
| Swift 6.0+ strict concurrency | `@Observable` + actors for shared state |
| No external dependency managers | Everything via SwiftPM. Sparkle is the only external dep |
| libghostty is C/Metal | Bridge layer must handle raw pointers safely. Never retain `ghostty_surface_t` in Swift directly |
| `com.muxy.app` stable | Do not change bundle ID or URL scheme |
| Terminal state in-memory only | Any persistence must serialize/deserialize around libghostty lifecycle |
| No comments in code | All code must be self-explanatory. Use logs for debugging |

---

## Code Quality Rules

- Security first, native only, clean architecture, no hacks
- Early returns instead of nested conditionals
- Fix root causes, not symptoms
- If testable, write tests
- Keep PR descriptions under 3 lines
- Upload screenshots/recordings for UI PRs
- Never push repo unless explicitly asked

---

## Context for Claude Runs

When starting a Claude session for Muxy:

1. Load this file + `docs/architecture.md` + `CLAUDE.md`
2. Specify the target component (e.g., `AppState`, `ProjectStore`, `GhosttyTerminalNSView`)
3. If touching the Ghostty bridge, also load `GhosttyKit/ghostty.h` and the relevant Swift wrapper
4. Trace the full lifecycle: SwiftUI view → `makeNSView` → surface creation → Metal render loop → destruction
5. For UI features, reference `AppIdentity` for naming (`Jade` vs `Muxy`)
6. Use `scripts/checks.sh --fix` after every edit

---

*Generated 2026-05-19. Update when major features ship or architecture changes.*
