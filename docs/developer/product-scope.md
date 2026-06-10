# Product scope

Jade is a **macOS terminal workspace**: projects, tabs, splits, Ghostty shells, and a command palette. Capture and AI extend the shell — they do not replace it.

## Capture model (single write path)

Three layers; only the first two are user-facing write surfaces.

| Layer | Role | User entry |
| --- | --- | --- |
| **Rich Input** | Primary capture for notes, tasks, terminal payloads, and images | `⌘I`, command palette **Toggle Rich Input** |
| **ProjectInspectorStore** | Persistence for Rich Input markdown (per project); not a separate panel | Used by Rich Input and preview overlay |
| **Project log** | Structured session workflow: propose step → work → complete → Obsidian session note | Palette: Set Up Project Log, Confirm Next Step, Complete Step |
| **Obsidian MCP** | Vault export for captures and session logs | `⌘⌃O`, palette MCP actions |

### Rules

1. **All freeform notes and tasks go through Rich Input** — no dedicated notes/todo inspector chrome.
2. **Project log reads repo markdown** (`todo.md`, `goals.md`, `.jade/journey.md`) and writes session logs to Obsidian; confirming a step may prefill Rich Input.
3. **Send to Obsidian** uses Rich Input text, terminal selection, or palette capture — not a parallel notes app.
4. **Do not add a fourth capture surface** (inbox panel, inspector split, etc.) until Rich Input + Obsidian session logs are boringly reliable.

Legacy inspector notes/todo panels and `SidePanelPolicy` slots were removed; shortcuts that referenced them open Rich Input instead.

## AI model (single production path)

| Path | Status |
| --- | --- |
| **Ollama direct** (inspector chat, natural commands) | Single production path |
| **AI usage panel** | Read-only quota for **Claude Code, Codex CLI, Cursor CLI** only |

## IDE surfaces (fallback, not wedge)

Built-in editor, file tree, and VCS tab remain for quick peeks and small Git actions. **Open in IDE** is the preferred path for serious editing. Do not expand toward a full IDE (commit graph, richer PR workspace, editor extensions).

## Related docs

- [Integrations](../features/integrations.md) — Rich Input, AI, snippets
- [Project log](../features/project-log.md) — session workflow
- [Obsidian MCP](../features/obsidian-mcp.md) — vault layout
- [Platform freeze](platform-freeze.md) — remote server policy
