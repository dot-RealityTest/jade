# Jade

Jade is the distributed macOS app. The SwiftPM executable target, source directory, shared modules, persistence paths, bundle identifier, and URL scheme still use the Muxy name for compatibility.

Requires macOS 14+ and Swift 6.0+. No external dependency managers needed; everything is SPM-based.

## Linting & Formatting

Requires `swiftlint` and `swiftformat` (`brew install swiftlint swiftformat`).

```bash
scripts/checks.sh        # Run all checks (formatting, linting, build)
scripts/checks.sh --fix  # Auto-fix formatting and linting issues
swiftformat --lint .      # Check formatting only
swiftlint lint --strict   # Check linting only
```

Run `scripts/checks.sh --fix` after every task.

## Architecture

- Jade is a macOS terminal multiplexer built with SwiftUI that uses [libghostty](https://github.com/ghostty-org/ghostty) for terminal emulation and rendering via Metal.
- The architecture of the app is documented at `./docs/architecture.md` and must always be up to date.
- Keep app identity centralized through `AppIdentity`. The user-facing app name is `Jade`; the primary CLI is `jade`; `muxy` remains a compatibility alias. Keep `com.muxy.app` and `muxy://` stable unless the user explicitly asks for a deeper migration.
- Release packaging copies the SwiftPM `Muxy` executable into the app bundle as `Contents/MacOS/Jade`.

### Core Components

- **GhosttyService** (singleton) — Manages the single `ghostty_app_t` instance per process. Loads config from `~/.config/ghostty/config`, runs a 120fps tick timer, and handles clipboard callbacks.

- **GhosttyTerminalNSView** — AppKit `NSView` that hosts a ghostty surface (`ghostty_surface_t`). Handles all keyboard/mouse input routing to libghostty and manages the Metal rendering layer. This is bridged into SwiftUI via `GhosttyTerminalRepresentable`.

- **AppState** (@Observable) — Manages the mapping of projects → tabs → split pane trees. Tracks active project, active tab per project, and provides tab lifecycle operations (create, close, select).

- **ProjectStore** (@Observable) — Persists projects as JSON to `~/Library/Application Support/Muxy/projects.json`. Projects are directories the user adds via NSOpenPanel.

## GhosttyKit Integration

`GhosttyKit/` is a C module wrapping `ghostty.h` — the libghostty API. The precompiled static library lives in `GhosttyKit.xcframework/` (gitignored, downloaded via `scripts/setup.sh`).

Key libghostty types: `ghostty_app_t` (app), `ghostty_surface_t` (terminal surface), `ghostty_config_t` (configuration). Surfaces are created when terminal views move to a window and destroyed on removal.

The xcframework is built via GitHub Actions on the [muxy-app/ghostty](https://github.com/muxy-app/ghostty) fork. See [docs/building-ghostty.md](docs/building-ghostty.md) for details.

## Data Persistence

- **Projects:** `~/Library/Application Support/Muxy/projects.json`
- **Ghostty config:** `~/.config/ghostty/config`
- **Terminal state (tabs, splits):** persisted to `~/Library/Application Support/Muxy/workspaces.json` and restored on launch. Working directories are captured and replayed. Actual shell process state (running commands, scrollback) remains in-memory only.

## CLI

- Install from the app menu item **Jade → Install CLI**.
- The installer must install `jade` as the primary command and `muxy` as a legacy compatibility command.
- The bundled wrapper lives at `Muxy/Resources/scripts/muxy-cli`; keep it command-name aware so usage text matches the executable name.
- Do not manually overwrite `/usr/local/bin` during normal agent work unless the user explicitly asks for a system install.

## NSViewRepresentable Pitfalls

- Never return a cached/reused NSView from `makeNSView`. SwiftUI assumes it gets a fresh view and breaks silently when it doesn't (blank views, lost input).
- To keep an NSView alive across tab switches, keep the `NSViewRepresentable` mounted in the view tree (e.g. all tabs in a ZStack with `opacity(0)` + `allowsHitTesting(false)` for inactive ones) rather than conditionally removing it and relying on a registry cache.
- When debugging blank/empty NSView issues, first check whether the NSView is being re-mounted from a detached state — that's the most common cause.

## Top Level Rules

- Security first
- Native Only
- Maintainability
- Scalability
- Clean Code
- Clean Architecture
- Best Practices
- No Hacky Solutions

## Main Rules

- No commenting allowed in the codebase
- All code must be self-explanatory and cleanly structured
- Use early returns instead of nested conditionals
- Don't patch symptoms, fix root causes
- For every task, Consider how it will impact the architecture and code quality, not just the immediate problem
- Follow the existing code's pattern but offer refactors if they improve code quality and maintainability.
- Use logs for debugging.
- If the feature is testable, then you must write tests.
- Avoid long PR descriptions. It is for humans and keep it in 3 lines maximum.
- Upload screenshots or recordings for the PRs.
- Never answer any question without a proper investigation and exploring the codebase.
- Prioritize problem comprehension over premature implementation. Validate the approach before execution to avoid rework
- Plan properly before executing to not double work

## Git

- Commits are local by default — create commits when the user asks or when work should be saved on disk.
- Do not push this repo, publish branches, or open PRs unless the user explicitly asks.

## Code Review

- Review the PRs/Code against the purpose of the PR/Issue/Asked. If you find unrelated issues to the PR during the review, Report them in a separate section.
- Apply review recommendations only after user's confirmation.

## Learned User Preferences

- Prefer minimal top window chrome for Jade: one compact workspace chrome row (~32pt) under the native title bar; keep the trailing icon row sparse (Snippets, AI, etc.) — no Notes/Todo chrome toggles or in-panel Send/Notes segmented control; open Rich Input (including popup/preview capture) via shortcuts/commands, not inspector chrome; command palette omits Todos and notes/todo panel entries, groups MCP actions (e.g. Obsidian) under MCP, and prioritizes Rich Input, Find in Files, and Toggle Sidebar.
- User-visible copy must say **Jade** (quit dialog, menus, settings); keep `muxy`/`Muxy` only for compatibility (bundle id, URL scheme, CLI alias, Application Support paths, internal types).
- When polishing Jade UI, aim for a finer, smaller, premium feel rather than chunky controls or extra vertical bands.
- For UI screenshot feedback, confirm the target is Jade/muxy before changing code; the user also has a separate PiecesTask app and has corrected mistaken cross-repo polish.
- Inspector AI defaults to Ollama direct; bundled Moltis (Ollama-backed gateway) is dev-only when built with `MUXY_BUNDLE_MOLTIS=1` — keep Ghostty terminal PTYs independent from Moltis agent/exec.
- When Jade scope grows (AI, chrome, panels), prefer trimming over-engineering and delaying platform features until the shell UX converges.
- When implementing an attached plan, do not edit the plan file; use existing todos and mark them in progress.
- Jade project log UX: next step from project markdown (`todo.md`, then `goals.md`, then `.jade/journey.md` fallback) with no mood/energy prompts; user-facing copy uses “log” / “session” (Set Up Project Log, Confirm Next Step, Complete Step); soft blockers when `.jade/rules.md` disagrees; Obsidian vault layout `Jade/Logs/{slug}/` — auto-created `project.md` hub (`type: project-log`), session logs in `sessions/` (`type: project-session-log`), project captures in `notes/` (`type: project-capture`); inbox when no active project.
- Keep Jade **project-aware** (projects/tabs/panes), not agent-orchestration like cmux; adopt cmux-style **project-level** attention cues (jump-to-unread, status), not multi-agent session routing.
- Snippets use **general** (shared) vs **project** scopes; switch via command palette (“General Snippets”, “Project Snippets”, “Toggle Snippet Scope”) or **⌘⌃J** — do not add chrome icons for scope mode.
- Expose MCP tools in Jade Settings; prioritize Obsidian vault capture (local `obsidian-mcp`) with a quick send-to-vault command.
- Command palette includes local dev shortcuts: **Upgrade Homebrew** and Ollama **list / pull / run / serve**; pull and run use the model from Natural Command Settings.

## Learned Workspace Facts

- Launch Jade locally with `./scripts/run-jade.sh` (embeds `AppIcon.icns`, syncs `AppIcon.png` into the resource bundle) or `open .build/.../Jade.app`. Replace artwork with `scripts/update-app-icon.sh path/to/icon.png` (1024×1024 PNG). The bare SwiftPM `Muxy` binary shows a generic icon and can spawn a duplicate Dock entry separate from `Jade.app`; **DEBUG builds disable Sparkle update checks** unless `JADE_ENABLE_UPDATES=1`.
- PiecesTask is a separate project at `/Users/kika_hub/Projects/PiecesTask`, not part of the muxy/Jade repo.
- Jade main-window HIG work favors incremental changes (native title bar, consolidated chrome, `WindowLayoutMetrics`) over a full `NavigationSplitView` / single-inspector refactor unless the user widens scope; the **Settings** window is resizable with HIG min sizes via `SettingsView` window policy.
- **Home** sidebar (`HomeWorkspace`) pins a general shell at `~` (toggle `muxy.general.showHomeWorkspaceInSidebar`, default on); **remote spaces** sync to sidebar projects on launch via `RemoteSpaceLauncher.syncSidebarProjects`.
- Bundled Moltis is opt-in at build time via `MUXY_BUNDLE_MOLTIS=1` (default release builds omit the bundle); gateway state lives under `~/Library/Application Support/Muxy/moltis/` with Ollama URL/model from `NaturalCommandSettings`.
- Right-rail panels use `SidePanelPolicy` mutual exclusion (Snippets, AI, Notes/Todo inspector — one primary panel at a time); notes/tasks UX prefers Rich Input over chrome or palette toggles.
- MCP integrations: catalog at `/Users/kika_hub/Documents/CODEX tools/MCPS.md`; Obsidian vault `/Users/kika_hub/_KIKA_MAIN/Kika's_Obsidian/` with local server at `/Users/kika_hub/Projects/obsidian-mcp/` (`.venv/bin/python`, `server.py`).
- Open-source reference repos live under `/Users/kika_hub/Documents/OPEN-Source-REPOS/` (e.g. Warp at `repos/warpdotdev/`); study patterns only — Warp is AGPL, do not copy its code into Jade.
- Per-project log scaffold lives in `.jade/` (`journey.md`, `rules.md`, log folders) plus optional project-root `goals.md`, `todo.md`, `project-map.md` created only when missing; `JadeProjectContextReader` parses structured context from those files.
- Git remotes: `origin` → `muxy-app/muxy` (upstream — do not push unless asked); `personal` → private https://github.com/dot-RealityTest/jade — push with `git push personal main` when the user asks to update/push their repo (not `origin`).
- Snippet storage: general `snippets.json`, per-project `project-snippets/{projectID}.json`, remote under `remote-spaces/{slug}/snippets.json`; active scope mode in UserDefaults (`muxy.general.snippetsScopeMode`).
- Continual learning updates `AGENTS.md` / `CLAUDE.md` / `.cursor/hooks/state/continual-learning-index.json` only (never plugin-cache global index); macOS verify via `scripts/checks.sh --fix --fast` when full checks fail on missing upstream `MuxyMobile` files; user docs hub `docs/README.md`.
- **Jade is macOS-only** — no iOS/Android app under Jade branding; this repo has no `MuxyMobile` target; optional WebSocket remote server remains for third-party clients.
