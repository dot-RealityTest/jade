# Jade Documentation

**Jade** is a native macOS terminal workspace organized around projects, worktrees, tabs, and split panes. It ships a built-in editor, source-control UI, file tree, command palette, Obsidian MCP capture, project session logs, on-device voice dictation, and a WebSocket API for companion apps.

Internal SwiftPM targets and paths still use **Muxy** for compatibility.

```mermaid
flowchart TB
  Project --> Worktree
  Worktree --> Splits[Split Tree]
  Splits --> TabArea[Tab Area]
  TabArea --> Tab
  Tab --> Terminal
  Tab --> Editor
  Tab --> VCS[Source Control]
  Tab --> Diff[Diff Viewer]
```

## User Guide

| Page | What's in it |
| --- | --- |
| [Getting Started](user-guide/getting-started.md) | Install, first project, palette tour |
| [Command Palette](user-guide/command-palette.md) | `⌘K` actions, dev commands, MCP, project log |
| [Keyboard Shortcuts](user-guide/keyboard-shortcuts.md) | Default bindings, all remappable |
| [Settings](user-guide/settings.md) | Every settings tab explained |
| [Troubleshooting](user-guide/troubleshooting.md) | Logs, common fixes, reset state |

## Features

| Page | What's in it |
| --- | --- |
| [Projects](features/projects.md) | Add/switch projects, IDE launch, CLI, URL scheme |
| [Worktrees](features/worktrees.md) | Per-worktree workspaces, setup commands |
| [Tabs & Splits](features/tabs-and-splits.md) | Tab kinds, splits, drag & drop, pinning |
| [Terminal](features/terminal.md) | Ghostty config, find, copy/paste, custom commands |
| [Editor](features/editor.md) | Built-in editor, quick open, markdown preview |
| [Source Control](features/source-control.md) | Git status, diff, branches, pull requests |
| [File Tree](features/file-tree.md) | Gitignore-aware tree, file ops, drag & drop |
| [Command Palette & dev tools](user-guide/command-palette.md) | Homebrew, Ollama, natural commands, local ports |
| [Integrations](features/integrations.md) | Rich Input, AI assistant, snippets, home, remote spaces |
| [Project Log](features/project-log.md) | `.jade/`, todo/goals, session workflow |
| [Obsidian MCP](features/obsidian-mcp.md) | Vault capture, session logs, project hub |
| [Voice Recording](features/voice-recording.md) | On-device dictation |
| [Notifications](features/notifications.md) | Hooks, socket API, attention UX, `jade notify` |
| [Layouts](features/layouts/README.md) | Declarative `.muxy/layouts/*.yaml` workspaces |
| [AI Usage](features/ai-usage.md) | Claude Code, Copilot, Codex, Cursor, and more |
| [Themes](features/themes.md) | Theme picker and Ghostty config |
| [Remote Server](features/remote-server/README.md) | WebSocket API for mobile clients |

## Developer

| Page | What's in it |
| --- | --- |
| [Architecture](developer/architecture/README.md) | System overview, components, data flow |
| [Architecture (monolith)](architecture.md) | Full service/view inventory |
| [Building Ghostty](developer/building-ghostty.md) | Building the GhosttyKit xcframework |

## Lineage

Jade builds on [Muxy](https://github.com/muxy-app/muxy) and takes project-attention UX inspiration from [cmux](https://github.com/manaflow-ai/cmux). See the root [README](../README.md#lineage--acknowledgments).
