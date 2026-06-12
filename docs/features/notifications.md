# Notifications

Jade collects session events from AI tools, OSC sequences, and a Unix socket API. Notifications drive toasts, sounds, the per-project panel, sidebar badges, and **project-aware attention** (jump-to-unread, metadata lines, terminal rings).

## Built-in provider hooks

Toggle providers under **Settings → Notifications → AI Providers**. Use **Install All** to register hooks for tools detected on this Mac (Claude Code, Codex, Cursor, OpenCode, etc.).

Delivery options: toast on/off, position (top/bottom), sound.

## Attention UX

| Surface | Behavior |
| --- | --- |
| **Jump to Latest Unread** (`⌘⇧U`) | Focuses project/tab/pane with newest unread; marks read |
| **Notification panel** (`⌘⇧I`*) | Lists session notifications for the active project |
| **Sidebar badge** | Unread count on project icon |
| **Expanded project row** | Branch, listening port count, latest unread preview |
| **Terminal attention ring** | Accent border on unfocused panes with unread |
| **Completion dot** | Subtle indicator when a command finished without unread |

\* Shares default shortcut with **Voice Recording** — remap in Settings if needed.

Project-attention patterns are inspired by [cmux](https://github.com/manaflow-ai/cmux) but scoped to **projects and panes**, not agent orchestration.

## CLI

After **Jade → Install CLI**:

```bash
jade notify <type> <pane-id> <title> [body]
jade hooks setup
```

`jade hooks setup` installs notification hook scripts for supported AI CLIs.

## Socket API (custom integrations)

Jade listens on a Unix domain socket:

```
~/Library/Application Support/Muxy/muxy.sock
```

Every Jade terminal exports:

- `MUXY_SOCKET_PATH` — socket path  
- `MUXY_PANE_ID` — pane UUID for routing  

### Wire format

One UTF-8 line per connection, pipe-separated:

```
<type>|<paneID>|<title>|<body>
```

| Field | Required | Description |
| --- | --- | --- |
| `type` | yes | Source id (`claude_hook`, `codex_hook`, `cursor_hook`, `custom`, …) |
| `paneID` | yes | Target pane; use `$MUXY_PANE_ID` inside Jade terminals |
| `title` | yes | Notification title |
| `body` | no | Body text (no `\|` or newlines) |

Max message size: **64 KB**.

### Shell example

```bash
printf '%s|%s|%s|%s' \
  "custom" "$MUXY_PANE_ID" "Build finished" "All tests passed" \
  | nc -U "$MUXY_SOCKET_PATH"
```

Reusable helper:

```bash
muxy_notify() {
  [ -z "${MUXY_SOCKET_PATH:-}" ] && return 0
  local title="${1:-Done}" body="${2:-}" safe_body
  safe_body=$(printf '%s' "$body" | tr '|\n\r' '   ' | head -c 500)
  printf '%s|%s|%s|%s' "custom" "${MUXY_PANE_ID:-}" "$title" "$safe_body" \
    | nc -U "$MUXY_SOCKET_PATH" 2>/dev/null || true
}
```

### Node.js and Python

See prior examples in this file's history — same pattern: connect to `MUXY_SOCKET_PATH`, write one line, close.

## Reference scripts

- Shell hook: `Muxy/Resources/scripts/muxy-claude-hook.sh`
- OpenCode plugin: `Muxy/Resources/scripts/opencode-muxy-plugin.js`

## Tips

- **Fire and forget** if Jade is not running.
- **Sanitize** model-generated bodies; cap length (~500 chars).
- **Pane routing** — omit pane id only when targeting the active pane is acceptable.

## Related

- [Command Palette](../user-guide/command-palette.md) — jump unread, notification panel  
- [Keyboard Shortcuts](../user-guide/keyboard-shortcuts.md)  
- Developer: [Notifications architecture](../developer/architecture/notifications.md)  
