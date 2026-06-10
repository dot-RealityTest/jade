# Jade — Overview

**Jade** is a native **macOS terminal workspace** for developers who organize work by **project**, not by loose terminal windows.

Product scope and freeze policy: [docs/developer/product-scope.md](developer/product-scope.md), [docs/developer/platform-freeze.md](developer/platform-freeze.md).

## One sentence

Jade combines a **Ghostty-powered terminal**, **project tabs and split panes**, **Git worktrees**, a **command palette**, **Rich Input + Obsidian capture**, and **local Ollama AI** in one SwiftUI app.

## Who it is for

| You are… | Jade helps with… |
| --- | --- |
| A macOS developer | Project-scoped shells, worktrees, and persistent workspace state |
| An Obsidian user | Rich Input capture and session logs to your vault via MCP |
| An AI-assisted coder | Ollama chat in the inspector; optional usage readout for Claude/Codex/Cursor |

## What makes it different

- **Project-first** — Each repo gets its own workspace (tabs, splits, cwd memory).
- **Native and local-first** — SwiftUI + libghostty/Metal; Ollama runs on your machine.
- **Capture without leaving the shell** — Rich Input, command palette, snippets, vault export.
- **Not a cloud IDE** — No account, no required backend.

## Core capabilities

1. **Terminal** — libghostty rendering, themes, find, auto-copy selection, snippets from selection.
2. **Layout** — Vertical tabs, horizontal/vertical splits, drag-and-drop reorder, worktrees.
3. **Command palette** — Fuzzy actions, file search, MCP tools, project log steps, dev shortcuts.
4. **Capture** — Rich Input, Obsidian send, structured project session logs.
5. **CLI** — `jade /path/to/project`, `jade notify`, `jade hooks setup`.

## Optional surfaces (fallback / frozen)

- Built-in editor, file tree, and VCS tab — quick peek; prefer external IDE for deep work.
- AI usage panel — Claude Code, Codex CLI, Cursor CLI quotas only.
- Remote WebSocket server — maintenance-only; see [platform freeze](developer/platform-freeze.md).

## Platform

- **macOS 14+ only** — No iOS or Android app under the Jade name in this repository.
- **Open source** — MIT license; contributions welcome.

## Install

Download from [GitHub Releases](https://github.com/dot-RealityTest/jade/releases) when published, or build with `./scripts/run-jade.sh` after `scripts/setup.sh`.

## Documentation

Full docs: [docs/README.md](README.md)

Obsidian vault note templates: [templates/obsidian/README.md](templates/obsidian/README.md)

Machine-readable index for AI systems: [llms.txt](../llms.txt) at the repository root.

## Privacy

Jade stores workspace state under `~/Library/Application Support/Muxy/`. Terminal scrollback and shell processes are local. Obsidian and Ollama endpoints are user-configured. Remote spaces use SSH you define.

## Related projects

- [Muxy](https://github.com/muxy-app/muxy) — upstream terminal multiplexer lineage
- [Ghostty](https://github.com/ghostty-org/ghostty) — terminal emulation engine
- [cmux](https://github.com/manaflow-ai/cmux) — inspiration for project-level attention UX
