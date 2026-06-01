# Troubleshooting

If something goes wrong, this page collects the common fixes. If your issue isn't here, please [open an issue](https://github.com/muxy-app/muxy/issues).

See also the [documentation index](../README.md) for command palette, Obsidian MCP, project log, and voice setup.

## Logs

Muxy writes logs through the unified macOS logging system. Stream them live:

```bash
log stream --predicate 'subsystem == "app.muxy"' --info --debug
```

Or grab a recent slice:

```bash
log show --predicate 'subsystem == "app.muxy"' --last 10m --info --debug
```

## Terminal is blank or unresponsive

- Try **Jade → Reload Configuration** (`⌘⇧R`).
- Check `~/.config/ghostty/config` parses by opening it in **Open Configuration…**.
- If the issue is reproducible, check `log stream` while reproducing.

## CLI not found

Run **Jade → Install CLI**. This installs **`jade`** (primary) and **`muxy`** (alias) under `/usr/local/bin`. Ensure `/usr/local/bin` is on your `$PATH`.

## Project won't open via `muxy <path>`

The path must exist and must be a directory (not a file). Relative paths are resolved against the shell's current directory. Quote paths with spaces.

## Source Control: gh actions disabled

Pull request features require the `gh` CLI to be installed and authenticated:

```bash
brew install gh
gh auth login
```

After authenticating, restart Muxy or click **Refresh** in the PR list.

## Mobile server won't start

- Make sure the port (default 4865) isn't in use: `lsof -i :4865`.
- Check **Settings → Mobile** for an error message — port conflicts and bind failures are surfaced there.

## Notifications aren't showing

- Check **Settings → Notifications** that the global toggle and the relevant per‑source toggle are on.
- macOS may have suppressed Muxy's system notifications — check **System Settings → Notifications → Muxy**.
- For socket‑based integrations, verify the socket exists: `ls -l ~/Library/Application\ Support/Muxy/muxy.sock`.

## Obsidian MCP / project log

- Enable **Settings → MCP Tools** and run **Test MCP** plus **Refresh Tools**.
- Vault path must be the Obsidian vault root; Python must run your local `server.py`.
- Read-only mode blocks `create_note` — session logs and Send to Obsidian need writes enabled.
- Session notes land under `Jade/Logs/{project}/` in the vault; see [Obsidian MCP](../features/obsidian-mcp.md).

## Voice recording or notifications on `⌘⇧I`

Default shortcuts bind **Voice Recording** and **Project Notifications** to the same key. Remap one in **Settings → Commands → Keyboard Shortcuts**. Voice requires an on-device dictation language in **System Settings → Keyboard → Dictation**.

## AI usage shows nothing

- Check the provider is enabled in **Settings → AI Usage**.
- Make sure the relevant credential (env var, JSON file, or Keychain entry) exists.
- Click **Refresh** in the popover and watch `log stream` for parser errors.

## Reset state

If you want to start fresh, quit Muxy and remove:

```
~/Library/Application Support/Muxy/
```

This wipes projects, worktrees, notifications, and approved mobile devices. Ghostty config at `~/.config/ghostty/config` is left alone.

## Reporting a bug

When filing an issue, include:

- macOS version
- Muxy version (Muxy menu → About Muxy)
- Reproduction steps
- A `log show --predicate 'subsystem == "app.muxy"' --last 10m` snippet if relevant
