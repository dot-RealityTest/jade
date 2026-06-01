# Project Log

Jade's project log ties repo markdown, a `.jade/` scaffold, and Obsidian session notes into one workflow: propose a focus step, work in the terminal, then log what happened.

User-facing copy uses **log** and **session** (not “journey” or mood/energy prompts).

## On-disk layout (repo)

When you run **Set Up Project Log** from the command palette (`⌘K`), Jade creates:

| Path | Purpose |
| --- | --- |
| `.jade/journey.md` | Local session history and **Next step** fallback |
| `.jade/rules.md` | Soft guardrails (**Not yet** / **Always** sections) |
| `.jade/decisions/` | Optional decision notes |
| `.jade/achievements/` | Completed-step artifacts |
| `.jade/blockers/` | Blocker notes |
| `.jade/log/` | Local log fragments |
| `todo.md` | Open tasks (`- [ ]` items) — created only if missing |
| `goals.md` | Outcomes and milestones — created only if missing |
| `project-map.md` | Orientation table — created only if missing |

Existing files are never overwritten.

## Where the next step comes from

Priority order (`JadeJourneyReader`):

1. First open `- [ ]` item in **`todo.md`**
2. First goal bullet in **`goals.md`**
3. **Next step** section in **`.jade/journey.md`**

If **`.jade/rules.md`** disagrees with a step (for example “deploy to production” under **Not yet**), Jade shows a soft blocker. You can override once and continue.

## Command palette flow

| Step | Palette command | Result |
| --- | --- | --- |
| 1 | **Set Up Project Log** | Bootstrap `.jade/` and project markdown |
| 2 | **Confirm Next Step** | Review overlay: confirm, skip, or override blocker |
| 3 | Work | Terminal, Rich Input, AI, etc. |
| 4 | **Complete Step** | Mark step done in repo markdown + Obsidian session log |

On confirm, Jade can prefill **Rich Input** and open send mode. Completing a step updates local markdown and writes a structured note to Obsidian when MCP is configured.

## Obsidian session logs

Session notes are created via MCP **`create_note`** at:

```
Jade/Logs/{project-slug}/sessions/{timestamp}-{step-slug}.md
```

Frontmatter includes `type: project-session-log`, date, project path, step, outcome, risk, and source file.

Each note includes:

- **Focus step** — title, summary, rationale  
- **Work log** — checklist to fill in  
- **Session notes** — freeform area  
- **Goals (reference)** — from `goals.md` when present  
- **Follow-up** — remaining open todos  
- **Project files** — table of repo surfaces  
- **Blockers** — when rules disagreed  
- **Related** — link to the vault project hub  

On first session or project capture, Jade ensures a vault hub at **`Jade/Logs/{project-slug}/project.md`** (see [Obsidian MCP](obsidian-mcp.md)).

Example note shapes: [Obsidian templates](../templates/obsidian/README.md).

## Settings checklist

1. **Settings → MCP Tools** — enable Obsidian MCP, vault path, Python, `server.py`  
2. Test connection and **Refresh Tools**  
3. Open a project and run **Set Up Project Log** if `.jade/` is missing  
4. Use **Confirm Next Step** → **Complete Step** to close the loop  

## Related

- [Command Palette](../user-guide/command-palette.md) — palette entries  
- [Obsidian MCP](obsidian-mcp.md) — vault paths, capture, MCP palette group  
- [Integrations](integrations.md) — Rich Input and AI assistant  
