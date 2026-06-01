# Obsidian vault templates for Jade

Jade writes structured markdown to your Obsidian vault through MCP **`create_note`**. You do not need to copy these files manually — Jade creates them on **Complete Step**, **Send to Obsidian**, and the first project capture.

Use this folder as the **canonical reference** for note shape, frontmatter, and folder layout (Dataview, Bases, search, and GEO).

## Vault layout

```
{vault}/
  Jade/
    Inbox/                          # captures with no active project
      {timestamp}-{slug}.md
    Logs/
      {project-slug}/
        project.md                  # hub — type: project-log
        sessions/
          {timestamp}-{step}.md     # type: project-session-log
        notes/
          {timestamp}-{slug}.md     # type: project-capture
```

**Project slug** comes from the sidebar project name (lowercase, hyphenated).

## Note types

| File | `type` frontmatter | Created by |
| --- | --- | --- |
| [project-log.example.md](project-log.example.md) | `project-log` | First session log or project capture |
| [project-session-log.example.md](project-session-log.example.md) | `project-session-log` | Command palette **Complete Step** |
| [project-capture.example.md](project-capture.example.md) | `project-capture` | **Send to Obsidian** (`⌘⌃O`) with active project |
| [inbox-capture.example.md](inbox-capture.example.md) | *(none — inbox note)* | **Send to Obsidian** with no active project |

## Typical tags

Jade merges **Settings → MCP Tools → default tags** with:

- `project-log`, `session-log`, or `project-capture`
- `{project-slug}`
- Session outcome (`started`, `completed`, `skipped`, …) on session logs

## Dataview starter

```dataview
TABLE date, project, session.step AS step, session.outcome AS outcome
FROM "Jade/Logs"
WHERE type = "project-session-log"
SORT date DESC
```

## Related

- [Obsidian MCP](../../features/obsidian-mcp.md)
- [Project Log](../../features/project-log.md)
