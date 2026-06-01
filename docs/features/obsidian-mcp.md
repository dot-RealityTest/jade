# Obsidian MCP

Jade talks to your Obsidian vault through a local MCP server ([obsidian-codex-mcp](https://github.com/dot-RealityTest/obsidian-codex-mcp) or compatible). Capture snippets, search notes, and write **project session logs** without leaving the terminal workspace.

## Setup

1. Open **Settings → MCP Tools** (or **Jade → Obsidian MCP Settings…**).
2. Enable Obsidian MCP.
3. Set **Vault path** to your Obsidian vault folder.
4. Set **Python** and **`server.py`** (for example a `.venv/bin/python` and local `server.py`).
5. Choose **Inbox folder** (default `Jade/Inbox`) for captures without an active project.
6. Optional: default tags, read-only mode, backup-on-write.
7. **Test MCP** and **Refresh Tools** so the command palette shows MCP actions.

Environment variables passed to the server include `OBSIDIAN_VAULT_PATH`, `OBSIDIAN_READ_ONLY`, and `OBSIDIAN_BACKUP_ON_WRITE`.

## Ways to capture

| Method | Access | Destination |
| --- | --- | --- |
| **Send to Obsidian** | `⌘⌃O`, Obsidian menu, palette **MCP Tools** | See below |
| **Session log** | Palette **Complete Step** / journey confirm flow | `Jade/Logs/{slug}/sessions/…` |
| **Palette MCP group** | `⌘K` → MCP Tools | Inbox, search, tags, tree |

### Send to Obsidian content priority

1. Selected text in the focused text field  
2. Terminal selection in the active pane  
3. Rich Input text (when the panel is open)  
4. Clipboard  

### Paths

| Context | Vault path |
| --- | --- |
| No active project | `{inboxFolder}/{timestamp}-{slug}.md` |
| Active project | `Jade/Logs/{slug}/notes/{timestamp}-{slug}.md` with `type: project-capture` |

Project captures include frontmatter, the note body, open todos from `todo.md`, and goals from `goals.md` when available.

### Project log hub

Before the first session log or project capture, Jade creates **`Jade/Logs/{slug}/project.md`** if it does not exist — a central index with todo, goals, and links to sessions/notes folders.

Session logs use **`type: project-session-log`** under **`Jade/Logs/{slug}/sessions/`**. See [Project Log](project-log.md).

**Reference templates** (frontmatter + section layout Jade generates): [docs/templates/obsidian/](../templates/obsidian/README.md).

## MCP Tools palette / menu

| Action | MCP tool | Notes |
| --- | --- | --- |
| Send to Obsidian | `create_note` | Quick capture |
| List Obsidian Inbox Notes | `list_notes` | Configured inbox folder |
| Search Obsidian Notes | `search_notes` | Uses palette query as search term |
| List Obsidian Tags | `get_all_tags` | Vault-wide tags |
| Show Obsidian Vault Tree | `get_folder_structure` | Folder tree |
| Open MCP Tools Settings | — | Opens Settings |

## Built-in MCP catalog

Jade also documents standard tools for agents and power users: `get_note`, `update_note`, `delete_note`, `create_folder`, `get_backlinks`, `get_note_links`, and `configure_vault`. Availability depends on your server script version.

## Related

- [Project Log](project-log.md) — Confirm / Complete step and session note shape  
- [Command Palette](../user-guide/command-palette.md) — MCP section and `⌘⌃O`  
- [Settings](../user-guide/settings.md) — MCP Tools tab  
