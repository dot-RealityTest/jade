<p align="center">
  <img src="Muxy/Resources/Assets.xcassets/AppIcon.appiconset/icon_128@2x.png" alt="Jade" width="128" height="128">
</p>

<h1 align="center">Jade</h1>

<p align="center">Native macOS terminal workspace for project-based development — tabs, splits, Git, command palette, local AI, and Obsidian capture — built with SwiftUI and <a href="https://github.com/ghostty-org/ghostty">libghostty</a>.</p>

<p align="center"><a href="https://aka-kika.github.io/jade/">Website</a> · <a href="docs/overview.md">Overview</a> · <a href="llms.txt">llms.txt</a> · <a href="docs/README.md">Docs</a></p>

<div align="center">
  <img src="https://img.shields.io/github/v/release/aka-kika/jade" />
  <img src="https://img.shields.io/github/license/aka-kika/jade" />
  <img src="https://img.shields.io/github/commit-activity/m/aka-kika/jade" />
</div>

---

## Why Jade?

You live in your terminal—but switching between repos, losing context, and hunting for commands breaks flow. **Jade keeps every project's terminals, Git state, notes, and AI context in one persistent workspace.** Jump back in exactly where you left off.

## Quick Start

```bash
# Install (build from source — packaged Releases coming)
git clone https://github.com/aka-kika/jade.git && cd jade
scripts/setup.sh && ./scripts/run-jade.sh

# Open a project
jade /path/to/repo

# Keyboard essentials
⌘K  Command palette    ⌘P  Quick open    ⌘⇧U  Jump to unread    ⌘I  Rich input
```

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

---

## Features

### 🗂️ Project Workspace

- **Persistent workspaces** — Tabs, splits, and focus state saved per project
- **Vertical tabs** — Sidebar tab strip with drag-and-drop, pinning, middle-click close
- **Split panes** — Horizontal/vertical splits with keyboard navigation
- **Home workspace** — Optional pinned shell at `~` in the sidebar
- **Git worktrees** — Create, switch, and manage worktrees from the sidebar
- **Remote spaces** — SSH-backed projects with remote command palette actions

### ⚡ Command Palette & Search

- **Command palette (`⌘K`)** — Fuzzy search for actions, files, snippets, Obsidian capture, project-log steps, and natural shell generation
- **Quick open (`⌘P`)** — Jump to any file
- **Find in files (`⌘⇧F`)** — Project-wide search
- **Local dev shortcuts** — Homebrew upgrades, Ollama commands (list, pull, run, serve)
- **Local Ports** — Active listener overview and dead port detection

### 📝 Editor, Files & Git

- **Built-in VCS** — Git status, diff (unified/split), commit history, branch picker, PR creation via `gh`
- **File tree** — Gitignore-aware browser with file operations
- **Text editor** — Syntax highlighting, search, history
- **Markdown preview** — Render `.md` files inline
- **IDE integration** — Open files/folders in your preferred editor

### 🤖 AI & Knowledge Capture

- **Rich Input (`⌘I`)** — Multi-line compose with images; capture notes/tasks without leaving the terminal
- **AI Assistant (`⌘⌃A`)** — Right-rail Ollama chat; review generated shell commands before running
- **Snippets** — General or project-scoped (`⌘J` / `⌘⌃J`); save terminal selection via right-click; auto-copy on select
- **AI usage tracking (`⌘L`)** — Monitor Claude Code, Codex, Cursor, Copilot, Amp, Factory, Kimi, MiniMax, OpenCode, Z.ai
- **Markdown logs** — Send to Obsidian (`⌘⌃O`) writes markdown into any folder you choose; session logs under `Jade/Logs/{project}/`
- **Project log** — `.jade/` scaffold with todo/goals markdown and Confirm/Complete session workflow
- **Voice recording** — On-device dictation via Apple Speech (Settings → Recording)

### 🔔 Attention & Notifications

- **Notification center** — Toasts, sounds, per-project panel with socket + AI hooks
- **Jump to unread (`⌘⇧U`)** — Project-aware focus (inspired by cmux)
- **Sidebar status** — Branch, ports, unread preview on expanded project rows
- **Terminal attention ring** — Unread highlight on background panes
- **CLI hooks** — `jade notify`, `jade hooks setup`

### 🎨 Polish & Platform

- **Remote WebSocket API** — Optional LAN server for third-party clients (no mobile app shipped)
- **Terminal tools** — Lazygit (`⌘⇧G`), yazi (`⌘⇧Y`), in-terminal find, auto-copy selection
- **200+ themes** — Ghostty theme picker (`⌘⇧K`)
- **Customizable shortcuts** — 40+ actions plus custom shell commands
- **Customizable toolbar** — Minimal workspace chrome
- **Drag and drop** — Reorder tabs/projects; split by dragging
- **Project icons** — Custom logos and colors
- **Auto-updates** — Sparkle (disabled in DEBUG unless `JADE_ENABLE_UPDATES=1`)

Full documentation: [docs/README.md](docs/README.md) — command palette, Obsidian, voice, integrations, project log.

---

## How Jade Compares

| Feature | Jade | iTerm2 | Warp | Ghostty |
|---------|------|--------|------|---------|
| Project workspaces | ✅ Persistent per-repo | ❌ | ✅ | ❌ |
| Built-in Git UI | ✅ Full VCS panel | ❌ | ✅ | ❌ |
| Command palette | ✅ Fuzzy + AI | ❌ | ✅ | ⚠️ Basic |
| Local AI (Ollama) | ✅ Right-rail chat | ❌ | ✅ Cloud | ❌ |
| Obsidian capture | ✅ Direct markdown | ❌ | ❌ | ❌ |
| Split panes | ✅ | ✅ | ✅ | ✅ |
| macOS native | ✅ SwiftUI | ✅ | ✅ | ✅ |
| Open source | ✅ MIT | ❌ | ❌ | ✅ |
| Free | ✅ | ✅ | ⚠️ Limited | ✅ |

**Jade is a project multiplexer**—not just a terminal emulator. It wraps libghostty's rendering with a workflow layer for persistent per-repo contexts, Git operations, snippets, and capture flows. Everything runs locally on your Mac.

---

## FAQ

**What is Jade?**  
A native macOS terminal workspace that organizes shells by project — tabs, splits, Git worktrees, command palette, local Ollama AI, and optional Obsidian capture. Not a cloud IDE; everything runs on your Mac.

**Is Jade free and open source?**  
Yes. MIT license. Build from source (see [Local Development](#local-development)); packaged [Releases](https://github.com/aka-kika/jade/releases) when published.

**What platforms does Jade support?**  
macOS 14+ only. No iOS or Android app under the Jade name.

**Does Jade send my code or terminal data to the cloud?**  
No by default. Ollama and Obsidian run locally with endpoints you configure. SSH remote spaces and LAN WebSocket API are opt-in.

**Where can AI assistants read about Jade?**  
See [llms.txt](llms.txt) and [docs/overview.md](docs/overview.md).

---

## Requirements

- macOS 14+
- Swift 6.0+
- `gh` (optional, for PR management)

## Install

Build locally (no packaged download on [Releases](https://github.com/aka-kika/jade/releases) yet):

```bash
scripts/setup.sh          # downloads GhosttyKit.xcframework
swift build               # debug build
./scripts/run-jade.sh     # assemble Jade.app and launch
```

Use `./scripts/run-jade.sh` rather than `swift run Muxy` — the bare binary skips the app bundle and shows a generic Dock icon.

## CLI

Install via **Jade → Install CLI** from the menu bar:

```bash
jade .
jade /path/to/project
```

## Lineage & Acknowledgments

Jade builds on open-source foundations:

- **[Muxy](https://github.com/muxy-app/muxy)** — Core multiplexer: SwiftUI shell, libghostty rendering, project workspaces, splits, persistence. Jade retains `muxy` identifiers for compatibility (bundle ID, Application Support paths, URL scheme).
- **[cmux](https://github.com/manaflow-ai/cmux)** — UX inspiration for project-aware attention: sidebar status, jump-to-unread, terminal attention cues. Jade applies these at the **project level** (tabs, panes, notifications).

## Feedback & Contributions

Feedback, bug reports, ideas, and PRs welcome.

- **Bug or missing feature?** [Open an issue](https://github.com/aka-kika/jade/issues/new/choose)
- **Want to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md) — fork, branch from `main`, run `scripts/checks.sh --fix --fast`, open a PR

## License

[MIT](LICENSE)
