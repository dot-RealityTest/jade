<p align="center">
  <img src="Muxy/Resources/Assets.xcassets/AppIcon.appiconset/icon_128@2x.png" alt="Jade" width="128" height="128">
</p>

<h1 align="center">Jade</h1>

<p align="center">Native macOS terminal workspace for project-based development — tabs, splits, Git, command palette, local AI, and Obsidian capture — built with SwiftUI and <a href="https://github.com/ghostty-org/ghostty">libghostty</a>.</p>

<div align="center">
  <img src="https://img.shields.io/github/v/release/dot-RealityTest/jade" />
  <img src="https://img.shields.io/github/license/dot-RealityTest/jade" />
  <img src="https://img.shields.io/github/commit-activity/m/dot-RealityTest/jade" />
</div>

## Screenshots

<p align="center">
  <img src="assets/screenshots/jade-snippets-workspace.png" alt="Jade workspace with terminal, snippets panel, and voice recording" width="900" />
</p>

<p align="center">
  <img src="assets/screenshots/jade-command-palette-dev.png" alt="Command palette with Homebrew upgrade and Ollama commands" width="440" />
  &nbsp;
  <img src="assets/screenshots/jade-rich-input-slash.png" alt="Rich Input slash commands for lists, headings, and tasks" width="440" />
</p>

<p align="center">
  <img src="assets/screenshots/jade-voice-recording.png" alt="On-device voice dictation with listening timer and waveform" width="440" />
</p>

## Features

### Core terminal workspace

- **Project-based workflow** — Organize terminals by project with persistent workspace state
- **Home workspace** — Optional pinned shell at `~` in the sidebar
- **Vertical tabs** — Sidebar tab strip with drag-and-drop reordering, pinning, renaming, and middle-click close
- **Split panes** — Horizontal and vertical splits with keyboard navigation and resizable dividers
- **Git worktrees** — Create, switch, and manage worktrees from the sidebar with per-pane branch tracking
- **Remote spaces** — SSH-backed sidebar projects with remote command palette actions
- **Workspace persistence** — Tabs, splits, and focus state saved and restored per project

### Command palette & search

- **Command palette (`⌘K`)** — Fuzzy actions, files, snippets, MCP tools, project-log steps, and natural shell generation
- **Quick open & find in files** — `⌘P` / `⌘⇧F` plus palette file search
- **Local dev shortcuts** — Upgrade Homebrew; Ollama list, pull, run, serve from the palette
- **Local Ports** — Session listening and dead port overview from the palette

### Editor, files & Git

- **Built-in VCS** — Git status, diff (unified and split), commit history, branch picker, and PR creation/listing via `gh`
- **File tree** — Gitignore-aware browser with file operations and clipboard
- **Text editor** — Syntax highlighting, search, and history
- **Markdown preview** — Render Markdown files inline
- **IDE integration** — Open files and folders in your preferred IDE

### AI, capture & knowledge

- **Rich Input (`⌘I`)** — Multi-line compose with images; notes/tasks capture without extra chrome
- **AI Assistant (`⌘⌃A`)** — Right-rail Ollama chat; natural shell command review
- **Snippets** — General vs project scope (`⌘J`, `⌘⌃J`); right-click terminal selection → **Save as Snippet**; auto-copy on select (Settings → General)
- **AI usage tracking (`⌘L`)** — Claude Code, Codex, Cursor, Copilot, Amp, Factory, Kimi, MiniMax, OpenCode, Z.ai
- **Obsidian MCP** — Send to vault (`⌘⌃O`); session logs under `Jade/Logs/{project}/`
- **Project log** — `.jade/` scaffold, todo/goals markdown, Confirm/Complete session workflow
- **Voice recording** — On-device dictation via Apple Speech (Settings → Recording)

### Notifications & attention

- **Notification center** — Toasts, sounds, per-project panel, socket + AI hooks
- **Jump to latest unread (`⌘⇧U`)** — Project-aware focus (cmux-inspired, project-scoped)
- **Sidebar status** — Branch, ports, unread preview on expanded project rows
- **Terminal attention ring** — Unread highlight on background panes
- **CLI** — `jade notify`, `jade hooks setup`

### Platform & polish

- **Remote WebSocket API** — Optional LAN server for third-party clients (no Jade iOS app shipped today)
- **Terminal tools** — Lazygit `⌘⇧G`, yazi `⌘⇧Y`, in-terminal find; auto-copy selection; right-click **Save as Snippet**
- **200+ themes** — Ghostty theme picker `⌘⇧K`
- **Customizable shortcuts** — 40+ actions plus custom shell commands
- **Customizable toolbar** — Sparse workspace chrome (Snippets, AI, …)
- **Drag and drop** — Reorder tabs/projects; split by dragging tabs
- **Project icons** — Custom logos and colors
- **Auto-updates** — Sparkle (disabled in DEBUG unless `JADE_ENABLE_UPDATES=1`)

Full documentation: [docs/README.md](docs/README.md) — command palette, Obsidian, voice, integrations, project log.

## Requirements

- macOS 14+
- Swift 6.0+
- `gh` installed (optional for PR management)

## Install

Download a build from [Releases](https://github.com/dot-RealityTest/jade/releases), or build locally (see [Local Development](#local-development)).

Jade is **macOS-only** today. There is no iOS or Android app under the Jade name. Upstream [Muxy](https://github.com/muxy-app/muxy) ships separate mobile companions; this repo does not include `MuxyMobile`. The desktop app still exposes an optional WebSocket API — see [Remote Server](docs/features/remote-server/README.md).

## Local Development

```bash
scripts/setup.sh          # downloads GhosttyKit.xcframework
swift build               # debug build
./scripts/run-jade.sh     # assemble Jade.app and launch
```

Use `./scripts/run-jade.sh` rather than `swift run Muxy` — the bare binary skips the app bundle and shows a generic Dock icon.

## Lineage & acknowledgments

Jade is a personal macOS terminal workspace built on open-source foundations:

- **[Muxy](https://github.com/muxy-app/muxy)** — Core terminal multiplexer: SwiftUI shell, libghostty rendering, project workspaces, splits, and persistence. Jade keeps `muxy` / `Muxy` identifiers for compatibility (bundle id, Application Support paths, URL scheme).
- **[cmux](https://github.com/manaflow-ai/cmux)** — UX inspiration for project-aware attention: sidebar status, jump-to-unread, and terminal attention cues. Jade applies those patterns at the **project** level (tabs, panes, notifications), not as an agent orchestration layer.

## CLI

Use **Jade → Install CLI** from the macOS menu to install the **`jade`** command.

```bash
jade .
jade /path/to/project
```

## Feedback & contributions

Feedback, bug reports, ideas, and pull requests are welcome.

- **Something broken or missing?** [Open an issue](https://github.com/dot-RealityTest/jade/issues/new/choose)
- **Want to contribute code?** See [CONTRIBUTING.md](CONTRIBUTING.md) — fork, branch from `main`, run `scripts/checks.sh --fix --fast`, and open a PR

## License

[MIT](LICENSE)
