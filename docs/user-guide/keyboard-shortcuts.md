# Keyboard Shortcuts

Every shortcut can be remapped in **Settings → Commands → Keyboard Shortcuts**. Defaults below use **Jade** user-facing names; internal action IDs still use `muxy` in preferences paths.

## Command palette & navigation

| Action | Shortcut |
| --- | --- |
| Command Palette | `⌘K` |
| Quick Open (files) | `⌘P` |
| Find in Files | `⌘⇧F` |
| Open Project… | `⌘O` |
| Toggle Sidebar | `⌘B` |
| Toggle File Tree | `⌘E` |
| Reload Ghostty Config | `⌘⇧R` |
| Theme Picker | `⌘⇧K` |
| AI Usage | `⌘L` |

Source Control has **no default key** — open it from the palette (`⌘K` → “Source Control”) or assign a binding.

## Tabs

| Action | Shortcut |
| --- | --- |
| New Tab | `⌘T` |
| Reopen Closed Tab | `⌘⇧T` |
| Close Tab | `⌘W` |
| Rename Tab | `⌘⌥T` |
| Pin / Unpin Tab | `⌘⇧P` |

## Panes

| Action | Shortcut |
| --- | --- |
| Split Right | `⌘D` |
| Split Down | `⌘⇧D` |
| Close Pane | `⌘⇧W` |
| Focus Pane Left / Right / Up / Down | `⌘⌥←` / `→` / `↑` / `↓` |
| Toggle Maximize Pane | `⌘⌥↩` |

## Tab navigation

| Action | Shortcut |
| --- | --- |
| Next Tab | `⌘]` |
| Previous Tab | `⌘[` |
| Cycle Next Tab (All Panes) | `⌃Tab` |
| Cycle Previous Tab (All Panes) | `⌃⇧Tab` |
| Tab 1–9 | `⌘1` … `⌘9` |

## Project navigation

| Action | Shortcut |
| --- | --- |
| Next Project | `⌃]` |
| Previous Project | `⌃[` |
| Project 1–9 | `⌃1` … `⌃9` |
| Switch Worktree | `⌘⇧O` |

## Navigation history

| Action | Shortcut |
| --- | --- |
| Navigate Back | `⌘⌃←` |
| Navigate Forward | `⌘⌃→` |

Mouse side buttons (3 / 4) and three-finger horizontal trackpad swipes also navigate Back / Forward.

## Terminal tools

| Action | Shortcut |
| --- | --- |
| Find in Terminal | `⌘F` |
| Lazygit | `⌘⇧G` |
| Yazi | `⌘⇧Y` |
| Copy selection | `⌘C` (with selection); also **auto-copy on mouse-up** when enabled in Settings → General |
| Save as Snippet | Right-click terminal → **Save as Snippet** (no default key) |

## Rich Input

| Action | Shortcut |
| --- | --- |
| Toggle Rich Input | `⌘I` |
| Rich Input Preview | `⌘⌃N` |
| Send Rich Input | `⌘↩` (when panel focused) |
| Send without newline | `⌘⇧↩` (when panel focused) |

## Capture & integrations

| Action | Shortcut |
| --- | --- |
| Send to Obsidian | `⌘⌃O` |
| Toggle Snippets | `⌘J` |
| Toggle Snippet Scope | `⌘⌃J` |
| Toggle AI Assistant | `⌘⌃A` |

## Notifications & voice

| Action | Shortcut | Notes |
| --- | --- | --- |
| Jump to Latest Unread | `⌘⇧U` | Active project first, then global |
| Project Notifications | `⌘⇧I` | Notification panel |
| Voice Recording | `⌘⇧I` | **Conflicts with notifications** — remap one |

## Legacy inspector (optional)

| Action | Shortcut |
| --- | --- |
| Toggle Project Notes Panel | `⌘⇧J` |
| Toggle Project Todo Panel | `⌘⌥J` |

Prefer Rich Input (`⌘I`) and the command palette for notes/tasks capture.

## Editor

| Action | Shortcut |
| --- | --- |
| Save File | `⌘S` |
| Find | `⌘F` |

## Markdown preview

| Action | Shortcut |
| --- | --- |
| Zoom In | `⌘=` |
| Zoom Out | `⌘-` |
| Reset Zoom | `⌘0` |

## Custom command shortcuts

Define reusable shell shortcuts in **Settings → Commands → Keyboard Shortcuts → Custom Commands**. Each entry has a name, command, optional icon, and optional keybinding.

## Command palette-only actions

Open `⌘K` and search for:

| Command | What it does |
| --- | --- |
| Set Up Project Log | Bootstrap `.jade/` and project markdown |
| Confirm Next Step | Review next focus from todo/goals/journey |
| Complete Step | Finish step + Obsidian session log |
| Local Ports | Session listening / dead ports |
| Upgrade Homebrew | `brew update && brew upgrade` in a new tab |
| Ollama List / Pull / Run / Serve | Local LLM maintenance (model from Natural Commands settings) |
| Obsidian MCP actions | When MCP Tools configured — see [Obsidian MCP](../features/obsidian-mcp.md) |

Full palette reference: [Command Palette](command-palette.md).

## Related

- [Getting Started](getting-started.md)  
- [Settings](settings.md)  
- [Voice Recording](../features/voice-recording.md)  
