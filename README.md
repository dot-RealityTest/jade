<p align="center">
  <img src="Muxy/Resources/Assets.xcassets/AppIcon.appiconset/icon_128@2x.png" alt="Jade" width="128" height="128">
</p>

<h1 align="center">Jade</h1>

<p align="center">Lightweight, memory-efficient terminal for Mac built with SwiftUI and <a href="https://github.com/ghostty-org/ghostty">libghostty</a>.</p>
<p align="center"><a href="#install">Mac</a> | <a href="#ios">iOS</a> | <a href="https://apps.apple.com/de/app/muxy/id6762464046?l=en-GB">App Store</a> | <a href="https://play.google.com/store/apps/details?id=com.muxy.app">Android</a> | <a href="https://discord.gg/4eMXAmJQ2n">Discord</a></p>

<div align="center">
  <img src="https://img.shields.io/github/downloads/muxy-app/muxy/total" />
  <img src="https://img.shields.io/github/v/release/muxy-app/muxy" />
  <img src="https://img.shields.io/github/license/muxy-app/muxy" />
  <img src="https://img.shields.io/github/commit-activity/m/muxy-app/muxy" />
</div>

## Screenshots

<img width="3004" alt="Jade terminal workspace with project tools" src="assets/screenshots/jade-project-tools.png" />

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
- **Snippets** — General vs project scope (`⌘J`, `⌘⌃J`)
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

- **Mobile companion apps** — Pair iOS and Android devices to control Mac terminals remotely
- **Terminal tools** — Lazygit `⌘⇧G`, yazi `⌘⇧Y`, in-terminal find
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

### Homebrew

```bash
brew tap muxy-app/tap
brew install --cask muxy
```

### Manual

Download the latest release from the [releases page](https://github.com/muxy-app/muxy/releases)

### iOS

[Instructions](https://github.com/muxy-app/mobile)

- Install the iOS app via TestFlight (https://testflight.apple.com/join/7t1AaYHW)
- Open Jade on your Mac
- Go to Settings (Cmd + `,`)
- Go to Mobile tab
- Toggle the `Allow mobile device connection`
- Open the iOS app
- Enter the IP and Port
- Approve the connection on your Mac
- Test and open issues for the bugs

### Android

[Instructions](https://github.com/muxy-app/mobile)

## Local Development

```bash
scripts/setup.sh          # downloads GhosttyKit.xcframework
swift build               # debug build
./scripts/run-jade.sh     # assemble Jade.app with icon and launch
```

Replace the app icon with a square PNG (1024×1024 recommended):

```bash
scripts/update-app-icon.sh path/to/icon.png
./scripts/run-jade.sh
```

Running `swift run Muxy` directly skips the app bundle and shows a generic Dock icon.

## Lineage & acknowledgments

Jade is a personal macOS terminal workspace built on open-source foundations:

- **[Muxy](https://github.com/muxy-app/muxy)** — Core terminal multiplexer: SwiftUI shell, libghostty rendering, project workspaces, splits, and persistence. Jade keeps `muxy` / `Muxy` identifiers for compatibility (bundle id, Application Support paths, CLI alias).
- **[cmux](https://github.com/manaflow-ai/cmux)** — UX inspiration for project-aware attention: sidebar status, jump-to-unread, and terminal attention cues. Jade applies those patterns at the **project** level (tabs, panes, notifications), not as an agent orchestration layer.

## CLI

Use **Jade → Install CLI** from the macOS menu to install the terminal command.
It installs `jade` and keeps `muxy` as a compatibility alias.

```bash
jade .
jade /path/to/project
```

## License

[MIT](LICENSE)
