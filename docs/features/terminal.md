# Terminal

Jade's terminals are powered by [libghostty](https://github.com/ghostty-org/ghostty), running on a Metal layer for fast, GPU-accelerated rendering.

## Configuration

Ghostty is configured at `~/.config/ghostty/config`. Open it with **Jade → Open Configuration…**, reload after editing with `⌘⇧R`.

Most Ghostty options work — fonts, colors, padding, keybinds, shell integration. Jade applies the active light/dark variant automatically when the system appearance changes.

## Find in terminal

`⌘F` opens an inline search overlay scoped to the focused pane. Enter / Shift-Enter cycle through matches; Escape dismisses.

## Copy and paste

| Action | Shortcut / behavior |
| --- | --- |
| Copy (with selection) | `⌘C` |
| Send `^C` to program | `⌘C` with no selection |
| Paste | `⌘V` or right-click → **Paste** |
| X11 selection paste | Middle-click |
| **Auto-copy selection** | On by default — releasing the mouse after selecting text copies it to the clipboard and shows a **Copied to clipboard** toast |

Toggle auto-copy in **Settings → General → Auto-copy selected text** (`muxy.general.autoCopyTerminalSelection`, default **on**).

## Save selection as snippet

Right-click in a terminal pane to open the context menu:

- **Copy** — copy the current selection (`⌘C` when text is selected).
- **Save as Snippet** — save the selected text, or the line under the pointer if nothing is selected, into the active snippet scope (**general**, **project**, or remote space). Jade strips common shell prompts (`$`, `>`, `%`, …) when generating the snippet title. A toast confirms the scope (e.g. **Saved to Project**).
- **Paste**, split actions, etc. — see below.

Saved snippets appear in the snippets panel (`⌘J`) and command palette snippet section. Switch scope with **⌘⌃J** or palette **General Snippets** / **Project Snippets** before saving if you want a different target.

See [Integrations — Snippets](integrations.md#snippets).

## Working directory

Jade tracks the cwd via Ghostty's shell integration (OSC 7). The directory is persisted in workspace snapshots so newly recreated tabs land in the same folder when applicable.

## Custom command shortcuts

Define reusable shell command shortcuts in **Settings → Keyboard Shortcuts → Custom Commands**:

- Display name, command, optional icon, optional keybinding.
- Triggering one creates a new tab and runs the command.
- Useful for `npm run dev`, `make watch`, `just test`, …

## Right-click menu

Inside a terminal pane:

| Item | Notes |
| --- | --- |
| **Copy** | Enabled when text is selected |
| **Save as Snippet** | Selection or line under cursor → current snippet scope |
| **Paste** | From system clipboard |
| **Split Right / Left / Down / Up** | Split the pane in that direction |

## Notifications from the terminal

OSC 9 and OSC 777 notification escape sequences are routed into Jade's notification panel and (optionally) macOS notifications. See [Notifications](notifications.md).

## Quick-select labels

Ghostty's quick-select feature lets you focus a pane or surface by typing a label key. Labels and bindings are configured in the Ghostty config.
