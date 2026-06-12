# Rich Input Visual Mode + Direct Vault Capture

**Date:** 2026-06-02  
**Status:** Approved direction (Option C)  
**Scope:** Jade macOS — capture path + Rich Input editing UX

## Decision

**Option C:** Ship **filesystem-only vault capture** and **Rich Input visual editing** first. Defer **Obsidian MCP 2.0** until this UX converges. Existing stdio MCP remains for palette tools (`list_notes`, `search_notes`, etc.) but **Send to Obsidian** gains a direct-write path that does not require Python/`server.py`.

## Goals

1. Vibe coders can write notes/tasks in Rich Input and **see checkboxes and headings** while editing.
2. Devs can keep **Source** mode (current monospace markdown + syntax tint).
3. Users can send Rich Input content to a **configured vault `.md` path** without MCP for the happy path.
4. No breaking change to project-session logs or MCP palette until MCP 2.0.

## Non-goals (this phase)

- Obsidian MCP 2.0 tool redesign
- REST API / Cortex / Local REST plugin integration
- Full Typora-style block editor or split-pane WYSIWYG
- Replacing journey session log MCP writes

---

## 1. Direct vault capture (filesystem)

### Settings (new section: **Capture → Obsidian Vault**)

| Field | Default | Notes |
|-------|---------|-------|
| Vault path | (empty) | Reuse validation from `ObsidianVaultPathValidator` |
| Default note path | `Jade/Inbox/capture.md` | Relative to vault root |
| Append mode | `append` | `append` \| `new-file` (timestamp slug per send) |
| Prefer direct write | `true` | When vault + note path valid, skip MCP for send |

Place in **Settings → General** or a slim **Capture** tab — not buried in MCP Tools. MCP Tools keeps server config for advanced tools.

### Write behavior

- Resolve `vaultPath + defaultNotePath` → absolute URL.
- Create parent folders if missing (same safety as project log scaffold).
- **Append mode:** append `\n\n---\n\n` + frontmatter-light block (timestamp, project tag if active) + body.
- **New-file mode:** `{dirname}/{timestamp}-{slug}.md` sibling to configured path’s folder.
- On success: toast with vault-relative path; optional `reveal in Finder`.
- On failure: clear error (permissions, missing vault, path outside vault).

### Send routing (`ObsidianSendService` / `SendToObsidianContentCapture`)

```
if directCaptureEnabled && vaultConfigured:
    try ObsidianVaultWriter.write(...)
else if mcpConfigured:
    existing MCP create_note path
else:
    error — configure vault in Settings
```

Project-aware captures still use `Jade/Logs/{slug}/notes/…` when a project is active (filesystem writer, same formatters as today).

### Tests

- Unit: path resolution, append formatting, slug safety, traversal rejection.
- Integration: temp vault dir, write + read back markdown.
- Dogfood script: use direct write when `JADE_DOGFOOD_OBSIDIAN=1` without MCP server.

---

## 2. Rich Input editing style

### Setting

`muxy.richInput.editingStyle`: **`source`** | **`visual`**  
Default: **`source`** (preserves current dev UX).

UI: **Settings → Editor → Rich Input → Editing style**  
Copy: *Source* — markdown syntax visible. *Visual* — tasks and headings render inline.

### Source mode (unchanged)

- `MarkdownTextEditor` + `MarkdownInlineHighlighter` tinting.
- Slash commands insert raw markdown (`- [ ] `, `## `, etc.).

### Visual mode (new)

Extend `MarkdownTextEditor` when `editingStyle == .visual`:

| Element | Behavior |
|---------|----------|
| Task lines `- [ ]` / `- [x]` | Line-leading marker replaced visually with ☐/☑ (attachment or custom draw); marker chars hidden or dimmed |
| Toggle | Space on task line, or click checkbox hit region → flip `[ ]` ↔ `[x]` in stored string |
| Slash `/todo` | Inserts task line; cursor after task text |
| Headings `#`–`###` | Larger font on heading line (reuse `.heading(level)` decoration) |
| Bullets / bold / etc. | Keep existing highlighter; no full HTML preview |

Storage remains **plain markdown** in `RichInputState` / workspace notes — Visual is presentation only.

### Implementation notes

- Add `visualEditingEnabled` to `MarkdownTextEditor.Configuration`.
- New `MarkdownVisualTaskLayout` or extend `Coordinator.applyHighlighting()`:
  - Detect task lines; apply `NSTextAttachment` checkbox glyph OR custom `NSLayoutManager` delegate for checkbox rects.
  - `keyDown`: Space toggles task when caret on task line.
- Reuse toggle logic from `ProjectWorkspaceMarkdown` / preview overlay where possible.

### Tests

- Toggle task in visual mode updates underlying string to `- [x]`.
- Slash todo in visual mode produces togglable line.
- Source mode unaffected (regression).

---

## 3. MCP 2.0 (deferred)

After visual Rich Input + direct capture ship:

- Revise `obsidian-codex-mcp` tool surface (v2).
- Jade: MCP optional for send; palette tools use v2 protocol.
- Document migration in `docs/features/obsidian-mcp.md`.

---

## 4. Implementation order

1. **ObsidianVaultWriter** + capture settings + send routing + tests  
2. **RichInputEditingStyle** setting + Editor settings UI  
3. **Visual mode** task checkbox + heading emphasis in `MarkdownTextEditor`  
4. Docs: `docs/features/integrations.md`, `docs/user-guide/settings.md`  
5. Update `scripts/dogfood-capture-path.sh` for direct vault write  

---

## 5. Acceptance

- [ ] User sets vault + `Jade/Inbox/capture.md`, sends Rich Input → file updated without MCP.
- [ ] Visual mode: `/todo` shows checkbox; Space toggles checked state.
- [ ] Source mode unchanged; setting persists across launches.
- [ ] `scripts/checks.sh --fix --fast` passes.
