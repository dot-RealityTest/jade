# Settings

Open settings with `⌘,` (**Jade → Settings…**). The window is resizable with HIG-friendly minimum sizes. Pages are listed in the sidebar.

## General

- **Updates** — automatic Sparkle checks; stable vs beta channel.
- **Sidebar** — show **Home** workspace at `~`; auto-expand worktrees when switching projects.
- **Projects** — keep projects in the sidebar after closing all tabs; default worktree parent path.
- **Tabs** — confirm before closing a tab with a running process; confirm before quit.
- **Toolbar** — choose which chrome actions appear (Snippets, AI, etc.).
- **File tree** — source preference for the tree panel.
- **Session** — restore workspace on launch.
- **Terminal** — **Auto-copy selected text** (default on): releasing the mouse after a selection copies to the clipboard and shows a toast.
- **Project picker** — default location and picker mode.
- **Diagnostics** — optional Sentry crash reporting toggle.

## Appearance

- **Theme** — paired light / dark Ghostty theme.
- **Syntax highlighting** — editor grammar colors.

See [Themes](../features/themes.md).

## Commands

Container for command-related preferences:

- Link to **Keyboard Shortcuts** recorder (all `ShortcutAction` bindings + conflict detection).
- **Custom Commands** — named shell shortcuts with optional icons and keys.
- **Natural Commands** — enable NL → shell generation; Ollama base URL and model (shared with AI assistant and Ollama palette commands); Apple Intelligence where available.

See [Command Palette](command-palette.md) and [Integrations](../features/integrations.md).

## Editor

- **Default editor** — built-in Jade editor or external command.
- **External editor command** — `{file}`, `{line}`, `{column}` placeholders.
- **Rich Input** — floating panel, position, image attachment strategy.
- **Font** — editor typography.

## Sessions

Terminal session restore policies — what Jade remembers across launches per project/tab.

## Recording

- **Voice Recording** — auto-press Return after insert; on-device dictation language.

See [Voice Recording](../features/voice-recording.md).

## Notifications

- **Delivery** — toast on/off.
- **Sound** — notification sound preview.
- **Toast position** — top or bottom of window.
- **AI Providers** — per-provider toggles; **Install All** hooks for Claude Code, Codex, Cursor, OpenCode, etc.

See [Notifications](../features/notifications.md).

## Network

- **Remote access** — Optional WebSocket server on your LAN for third-party clients (no Jade iOS app shipped).
- **Port** — default 4865 (4866 in debug).
- Connection URL copy helper.

See [Remote Server](../features/remote-server/README.md).

## Connections

- **Mobile** — pairing, approvals, QR helper.
- **Remote Spaces** — SSH profiles that appear as sidebar projects; theme and command templates.
- **AI Usage** — enable tracking, display mode (used vs remaining), refresh interval, per-provider toggles.

See [Integrations](../features/integrations.md) and [AI Usage](../features/ai-usage.md).

## AI Assistant

Commit/PR generation and assistant options for the right-rail Ollama chat (`⌘⌃A`). Optional Moltis inspector settings when bundled at build time.

## Ghostty

Open/edit `~/.config/ghostty/config` and reload terminal settings.

## MCP Tools

Obsidian MCP integration:

- Enable, vault path, Python interpreter, `server.py` path.
- Inbox folder (default `Jade/Inbox`), default tags.
- Read-only and backup-on-write toggles.
- Test connection, refresh discovered MCP tool catalog.

See [Obsidian MCP](../features/obsidian-mcp.md).

## Related

- [Keyboard Shortcuts](keyboard-shortcuts.md)  
- [Getting Started](getting-started.md)  
- [Troubleshooting](troubleshooting.md)  
