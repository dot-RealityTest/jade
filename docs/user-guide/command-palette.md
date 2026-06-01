# Command Palette

The command palette is Jade's primary capture surface: search actions, files, snippets, MCP tools, and project-log steps without leaving the keyboard.

**Open:** `⌘K` · **File → Command Palette**

![Command palette with local dev commands](../../assets/screenshots/jade-command-palette-dev.png)

Type to filter. Press **Return** to run the highlighted row. Some remote actions ask for confirmation on a second **Return**.

## Sections

Results are grouped. When a **remote space** tab is active, remote commands appear first.

| Section | When it appears | Examples |
| --- | --- | --- |
| **App** | Always | New tab, Rich Input, project log, local dev commands |
| **MCP Tools** | Obsidian MCP enabled and configured | Send to Obsidian, search vault, list tags |
| **Remote Commands** | Active SSH remote-space tab | SSH session, apt upgrade, GPU tools |
| **Remote Spaces** | You have configured spaces | Switch to another machine |
| **Snippets** | Current snippet scope | Run saved shell snippets |
| **Files** | Query is 2+ characters or contains `/` | Quick-open project files |
| **Worktrees** | Project has git worktrees | Switch worktree |

## App commands (high priority)

| Command | Shortcut | What it does |
| --- | --- | --- |
| Jump to Latest Unread | `⌘⇧U` | Focus the tab/pane with the newest unread notification |
| Project Notifications | `⌘⇧I`* | Open the per-project notification panel |
| Set Up Project Log | — | Create `.jade/` plus optional `todo.md`, `goals.md`, `project-map.md` |
| Confirm Next Step | — | Review the next focus step from project markdown |
| Complete Step | — | Mark the step done and write a session log to Obsidian |
| Toggle Rich Input | `⌘I` | Notes, tasks, and multi-line capture before sending to the terminal |
| Rich Input Preview | `⌘⌃N` | Markdown preview overlay |
| Toggle Snippets | `⌘J` | Right-rail snippets panel |
| General / Project Snippets | — | Switch snippet scope |
| Toggle Snippet Scope | `⌘⌃J` | Flip general ↔ project snippets |
| Toggle AI Assistant | `⌘⌃A` | Right-rail local AI chat (Ollama) |
| Send to Obsidian | `⌘⌃O` | Capture selection, Rich Input, or clipboard to your vault |
| Quick Open | `⌘P` | Fuzzy-find files in the active project |
| Find in Files | `⌘⇧F` | Search file contents in the project |
| Toggle Sidebar | `⌘B` | Project sidebar |
| Toggle File Tree | `⌘E` | Built-in file tree |
| Local Ports | — | List listening and dead ports for this session |
| Theme Picker | `⌘⇧K` | Ghostty theme browser |
| AI Usage | `⌘L` | Token and cost usage popover |

\* **Shortcut note:** `⌘⇧I` is also bound to **Voice Recording** in default shortcuts. Remap one of them in **Settings → Commands → Keyboard Shortcuts** if both matter to you.

## Local dev commands

These open a **new terminal tab** and run a one-shot or interactive shell script. Jade prepends common Homebrew and Ollama paths so GUI-launched shells behave like Terminal.app.

| Command | Shell behavior |
| --- | --- |
| Upgrade Homebrew | `brew update && brew upgrade` |
| Ollama List Models | `ollama list` |
| Ollama Pull Model | `ollama pull <model>` |
| Ollama Run Model | `ollama run <model>` |
| Ollama Serve | `ollama serve` |

The Ollama model name comes from **Settings → Commands → Natural Commands** (same URL/model as the AI assistant and natural shell generation).

## Natural shell commands

When **Natural Commands** is enabled and your query looks like a multi-step or destructive shell request, the palette offers **Generate shell command**. Jade drafts a command for review before it runs in a tab. See [Integrations](../features/integrations.md).

## MCP Tools section

When Obsidian MCP is configured (**Settings → MCP Tools**), the palette lists vault actions: inbox capture, search, tags, folder tree, and settings. See [Obsidian MCP](../features/obsidian-mcp.md).

## Snippets section

Shows snippets for the active scope (**general** or **project**). Remote spaces can have their own snippet store. Use **General Snippets**, **Project Snippets**, or `⌘⌃J` to change scope without opening the panel.

Create snippets from the terminal: select text (auto-copied by default), right-click → **Save as Snippet**. Or save from natural-command review after **Generate shell command**.

## Files and worktrees

- **Files:** starts searching after two characters (or immediately if the query contains `/`).
- **Worktrees:** lists git worktrees for the active project; same family as **Switch Worktree** (`⌘⇧O`).

## Related

- [Keyboard Shortcuts](keyboard-shortcuts.md) — full default binding table
- [Project Log](../features/project-log.md) — Set Up / Confirm / Complete flow
- [Obsidian MCP](../features/obsidian-mcp.md) — vault capture and session logs
- [Voice Recording](../features/voice-recording.md) — on-device dictation
