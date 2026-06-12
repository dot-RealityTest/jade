# Markdown Logs & Capture

Jade writes session logs and quick captures as markdown files into a folder you choose. Point it at an Obsidian vault to get linked notes with frontmatter, or at any folder for plain markdown.

## Setup

1. Open **Settings → Logs & Capture** (or **Jade → Log Settings…**).
2. Choose a **Logs Folder** — your Obsidian vault or any directory.
3. Choose **Inbox folder** (default `Jade/Inbox`) for captures without an active project.
4. Optional: default capture note path and write mode (append vs new file).
5. **Test Folder** to confirm Jade can see it.

No server, plugin, or extra software is required — Jade writes the files directly.

## Ways to capture

| Method | Access | Destination |
| --- | --- | --- |
| **Send to Obsidian** | `⌘⌃O`, Obsidian menu, `⌘K` palette | See below |
| **Session log** | Palette **Complete Step** / journey confirm flow | `Jade/Logs/{slug}/sessions/…` |

### Send to Obsidian content priority

1. Selected text in the focused text field
2. Terminal selection in the active pane
3. Rich Input text (when the panel is open)
4. Clipboard

### Paths

| Context | Path inside the logs folder |
| --- | --- |
| No active project | `{inboxFolder}/{timestamp}-{slug}.md` or appended to the default capture note |
| Active project | `Jade/Logs/{slug}/notes/{timestamp}-{slug}.md` with `type: project-capture` |

Project captures include frontmatter, the note body, open todos from `todo.md`, and goals from `goals.md` when available.

### Project log hub

Before the first session log or project capture, Jade creates **`Jade/Logs/{slug}/project.md`** if it does not exist — a central index with todo, goals, and links to sessions/notes folders.

Session logs use **`type: project-session-log`** under **`Jade/Logs/{slug}/sessions/`**. See [Project Log](project-log.md).

**Reference templates** (frontmatter + section layout Jade generates): [docs/templates/obsidian/](../templates/obsidian/README.md).

## Related

- [Project Log](project-log.md) — Confirm / Complete step and session note shape
- [Command Palette](../user-guide/command-palette.md) — Send to Obsidian and `⌘⌃O`
- [Settings](../user-guide/settings.md) — Logs & Capture tab
