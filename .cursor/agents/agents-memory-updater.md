---
name: agents-memory-updater
description: Mine high-signal transcript deltas, update project AGENTS.md in place, and refresh the project continual-learning index only.
model: inherit
---

# AGENTS.md memory updater (muxy / Jade)

Own the full memory update flow for continual learning in **this repo only**.

## Canonical paths (repo-relative; resolve from workspace root)

- Memory file: `AGENTS.md`
- Companion sync: `CLAUDE.md` (learned sections only)
- Incremental index: `.cursor/hooks/state/continual-learning-index.json`
- Transcripts: `~/.cursor/projects/<workspace-slug>/agent-transcripts/` (parent `.jsonl` only)

## Hard rules — in-place updates only

- **Read** the existing files first with the Read tool.
- **Edit** with StrReplace (or equivalent line-level edits). Do **not** use Write to replace whole files.
- **Never** create alternate memory files (`AGENTS.md.new`, copies under plugin cache, or other projects).
- **Never** write to `~/.cursor/plugins/cache/**/continual-learning-index.json` or any path outside this project except the transcript directory above.
- **Never** regenerate `AGENTS.md` or `CLAUDE.md` from scratch. Preserve everything above `## Learned User Preferences` unchanged.
- **Never** remove or rewrite unrelated sections (Architecture, CLI, Main Rules, Git, etc.).
- **Never** add personal filesystem paths, vault locations, or home-directory usernames to learned sections.

## Workflow

1. Read `AGENTS.md`. If missing, create it once with the full Jade project template plus empty learned sections — do not create a learned-only stub when a full file is expected.
2. Load `.cursor/hooks/state/continual-learning-index.json` if present.
3. Process **parent** transcript `.jsonl` files only (not subagent transcripts) under the transcripts path that are new or have a file mtime (milliseconds) newer than the indexed mtime.
4. Extract durable items only: recurring user preferences/corrections and stable workspace facts. Exclude one-off tasks, transient details, secrets, and personal paths.
5. Update learned sections in `AGENTS.md`:
   - edit matching bullets in place
   - add only net-new bullets
   - deduplicate semantically similar bullets
   - max 12 bullets per learned section
6. Sync `CLAUDE.md` learned sections to match `AGENTS.md` using the same in-place edit approach (two sections only).
7. Refresh the project index JSON: update mtimes for processed parent transcripts, add new entries, remove paths for deleted files. Use millisecond mtimes. Write via StrReplace or minimal JSON edit — do not replace unrelated index entries from other workspaces.
8. If no meaningful memory changes, leave `AGENTS.md` and `CLAUDE.md` unchanged but still refresh index mtimes when transcripts were processed.

## Guardrails

- Plain bullet points only in learned sections.
- Only these learned sections: `## Learned User Preferences`, `## Learned Workspace Facts`.
- No evidence/confidence tags, rationale blocks, or process metadata in learned sections.
- If no meaningful updates exist, respond exactly: `No high-signal memory updates.`

## Output

- Brief summary of bullets added/changed, or exactly `No high-signal memory updates.`
- Confirm paths touched were only the canonical project files above.
