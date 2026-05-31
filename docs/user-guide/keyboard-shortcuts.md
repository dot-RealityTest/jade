# Keyboard Shortcuts

Every shortcut listed here can be remapped in **Settings → Keyboard Shortcuts**. Defaults are shown.

## Tabs

| Action | Shortcut |
| --- | --- |
| New Tab | `Cmd+T` |
| Close Tab | `Cmd+W` |
| Rename Tab | `Cmd+Shift+T` |
| Pin / Unpin Tab | `Cmd+Shift+P` |

## Panes

| Action | Shortcut |
| --- | --- |
| Split Right | `Cmd+D` |
| Split Down | `Cmd+Shift+D` |
| Close Pane | `Cmd+Shift+W` |
| Focus Pane Left | `Cmd+Opt+←` |
| Focus Pane Right | `Cmd+Opt+→` |
| Focus Pane Up | `Cmd+Opt+↑` |
| Focus Pane Down | `Cmd+Opt+↓` |
| Toggle Maximize Pane | `Cmd+Opt+Return` |

## Tab navigation

| Action | Shortcut |
| --- | --- |
| Next Tab | `Cmd+]` |
| Previous Tab | `Cmd+[` |
| Cycle Next Tab (All Panes) | `Ctrl+Tab` |
| Cycle Previous Tab (All Panes) | `Ctrl+Shift+Tab` |
| Tab 1–9 | `Cmd+1` … `Cmd+9` |

## Project navigation

| Action | Shortcut |
| --- | --- |
| Next Project | `Ctrl+]` |
| Previous Project | `Ctrl+[` |
| Project 1–9 | `Ctrl+1` … `Ctrl+9` |
| Switch Worktree | `Cmd+Shift+O` |

## Navigation history

| Action | Shortcut |
| --- | --- |
| Navigate Back | `Cmd+Ctrl+←` |
| Navigate Forward | `Cmd+Ctrl+→` |

Mouse side buttons (3 / 4) and three‑finger horizontal trackpad swipes also navigate Back / Forward.

## App

| Action | Shortcut |
| --- | --- |
| Open Project… | `Cmd+O` |
| Source Control | `Cmd+K` |
| Quick Open | `Cmd+P` |
| Toggle Sidebar | `Cmd+B` |
| Toggle File Tree | `Cmd+E` |
| Toggle AI Usage | `Cmd+L` |
| Theme Picker | `Cmd+Shift+K` |
| Reload Configuration | `Cmd+Shift+R` |

## Editor

| Action | Shortcut |
| --- | --- |
| Save File | `Cmd+S` |
| Find | `Cmd+F` |

## Markdown preview

| Action | Shortcut |
| --- | --- |
| Zoom In | `Cmd+=` |
| Zoom Out | `Cmd+-` |
| Reset Zoom | `Cmd+0` |

## Terminal

| Action | Shortcut |
| --- | --- |
| Find in Terminal | `Cmd+F` |

## Custom command shortcuts

Define your own command shortcuts in **Settings → Keyboard Shortcuts → Custom Commands**. Each entry has a display name, a shell command, an optional icon, and an optional keybinding. Triggering one creates a tab and runs the command.

## Local dev commands (command palette)

Open the command palette with `⌘K` and search for:

| Command | What it does |
| --- | --- |
| Upgrade Homebrew | Runs `brew update && brew upgrade` in a new tab |
| Ollama List Models | Runs `ollama list` |
| Ollama Pull Model | Pulls the model from **Settings → Natural Commands** |
| Ollama Run Model | Starts an interactive session with that model |
| Ollama Serve | Runs `ollama serve` |

These commands ensure Homebrew and Ollama are on `PATH` in GUI-launched shells and keep one-shot commands in an interactive tab when they finish.
