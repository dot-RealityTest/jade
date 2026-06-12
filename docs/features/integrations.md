# Integrations

AI, capture, snippets, natural shell generation, Home workspace, and remote SSH spaces — how they fit together in Jade.

See [Product scope](../developer/product-scope.md) for the canonical capture and AI model.

## Rich Input (primary capture)

Multi-line compose surface for notes, tasks, and terminal payloads. All freeform capture goes here — not through separate inspector panels.

![Rich Input slash menu for tasks, lists, headings, and code blocks](../../assets/screenshots/jade-rich-input-slash.png)

Type **`/`** in Rich Input for structured blocks: to-do, bullet/numbered lists, headings, quote, code block, divider.

| Action | Default shortcut |
| --- | --- |
| Toggle Rich Input | `⌘I` |
| Preview overlay | `⌘⌃N` |
| Send (with newline) | `⌘↩` when panel focused |
| Send (no newline) | `⌘⇧↩` when panel focused |

Open Rich Input from the command palette or shortcuts — not from extra title-bar toggles. Supports image attachments and draft persistence. Markdown persists via **ProjectInspectorStore** per project. Configure floating vs docked layout in **Settings → Editor**.

Legacy notes/todo shortcuts (`⌘⇧J`, `⌘⌥J`) open Rich Input in notes mode.

## Project log (structured sessions)

Palette workflow: **Set Up Project Log** → **Confirm Next Step** → work → **Complete Step**. Reads `todo.md` / `goals.md` / `.jade/journey.md`; writes Obsidian session logs. Confirming a step may prefill Rich Input. See [Project log](project-log.md).

## AI Assistant

Right-rail chat backed by **Ollama** using URL and model from **Settings → Commands → Natural Commands**.

| Action | Shortcut |
| --- | --- |
| Toggle AI Assistant | `⌘⌃A` |

**Settings → AI Assistant** — commit message / PR generation options and assistant behavior.

Only one primary right-rail panel is visible at a time: Snippets or AI.

## Snippets

Reusable shell snippets with **general** vs **project** scope (remote spaces can have their own store).

![Snippets panel with general-scope workflow commands](../../assets/screenshots/jade-snippets-workspace.png)

| Action | Shortcut / palette |
| --- | --- |
| Toggle snippets panel | `⌘J` |
| Toggle scope | `⌘⌃J` or **General Snippets** / **Project Snippets** |
| Save from terminal | Right-click → **Save as Snippet** (selection or line under cursor) |
| Save from natural command review | **Save as Snippet** after generating a shell command in the palette |

**Auto-copy** — selecting text in a terminal copies it on mouse release (default on; **Settings → General**). Pair with **Save as Snippet** to turn frequent commands into reusable snippets without retyping.

Scope preference persists in UserDefaults (`muxy.general.snippetsScopeMode`). Storage: `snippets.json` (general), `project-snippets/{projectID}.json` (project), `remote-spaces/{slug}/snippets.json` (remote).

## Natural Commands

**Settings → Commands → Natural Commands**

- Enable review-first natural language → shell command generation  
- **Ollama base URL** and **model** (shared with AI assistant and Ollama palette commands)  
- Optional Apple Intelligence backend where available  

In the command palette, type a descriptive shell request; Jade may offer **Generate shell command** with a review step before execution.

## Home workspace

**Settings → General → Sidebar → Show Home workspace**

Pins a **Home** project at `~` in the sidebar for general-purpose shells (default on). Toggle off if you only want explicit project folders.

## Remote spaces

**Settings → Connections → Remote Spaces**

Configure SSH-backed **remote spaces**. Each space can sync to a sidebar project on launch (`RemoteSpaceLauncher`).

When a remote tab is active, the command palette prioritizes **Remote Commands** (SSH session, copy SSH command, system overview, apt upgrade, reboot/power off, GPU tools on supported profiles) and **Remote Spaces** switching.

Natural command generation receives **remote** context when you're on a remote tab.

## Local Ports

**Command palette → Local Ports**

Shows listening and dead TCP ports observed during the session — useful when dev servers spawn from terminal tabs.

## AI usage tracking

**Settings → Connections** (usage toggles) · **`⌘L`** or palette **AI Usage**

Live token/cost panels for Claude Code, Codex, Cursor, Copilot, Amp, Factory, Kimi, MiniMax, OpenCode, Z.ai, and related providers. See [AI Usage](ai-usage.md).

## Related

- [Command Palette](../user-guide/command-palette.md)  
- [Markdown Logs](markdown-logs.md)  
- [Project Log](project-log.md)  
- [Notifications](notifications.md) — hooks and attention UX  
