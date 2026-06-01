# Jade — Overview

**Jade** is a native **macOS terminal workspace** for developers who organize work by **project**, not by loose terminal windows.

## One sentence

Jade combines a **Ghostty-powered terminal**, **project tabs and split panes**, **Git and worktrees**, a **command palette**, **local Ollama AI**, and **Obsidian capture** in one SwiftUI app.

## Who it is for

| You are… | Jade helps with… |
| --- | --- |
| A macOS developer | Project-scoped shells, worktrees, and persistent workspace state |
| A polyglot builder | Built-in editor, file tree, markdown preview, and IDE handoff |
| An AI-assisted coder | Ollama chat, natural shell commands, agent notification hooks |
| An Obsidian user | Send captures and session logs to your vault via MCP |

## What makes it different

- **Project-first** — Each repo gets its own workspace (tabs, splits, cwd memory).
- **Native and local-first** — SwiftUI + libghostty/Metal; Ollama runs on your machine.
- **Capture without leaving the shell** — Command palette, Rich Input, snippets, vault export.
- **Not a cloud IDE** — No account, no required backend; optional SSH remote spaces only.

## Core capabilities

1. **Terminal** — libghostty rendering, 200+ themes, find, auto-copy selection, save selection as snippet.
2. **Layout** — Vertical tabs, horizontal/vertical splits, drag-and-drop reorder.
3. **Git** — Status, diff, history, branches, PR create/list via GitHub CLI.
4. **Command palette** — Fuzzy actions, file search, MCP tools, Ollama and Homebrew shortcuts.
5. **Knowledge** — Project log (`.jade/`, todo/goals), Obsidian session logs, voice dictation.
6. **CLI** — `jade /path/to/project`, `jade notify`, `jade hooks setup`.

## Platform

- **macOS 14+ only** — No iOS or Android app under the Jade name in this repository.
- **Open source** — MIT license; contributions welcome.

## Install

Download from [GitHub Releases](https://github.com/dot-RealityTest/jade/releases) or build with `./scripts/run-jade.sh` after `scripts/setup.sh`.

## Documentation

Full docs: [docs/README.md](README.md)

Machine-readable index for AI systems: [llms.txt](../llms.txt) at the repository root.

## Privacy

Jade stores workspace state under `~/Library/Application Support/Muxy/`. Terminal scrollback and shell processes are local. Obsidian and Ollama endpoints are user-configured. Remote spaces use SSH you define.

## Related projects

- [Muxy](https://github.com/muxy-app/muxy) — upstream terminal multiplexer lineage
- [Ghostty](https://github.com/ghostty-org/ghostty) — terminal emulation engine
- [cmux](https://github.com/manaflow-ai/cmux) — inspiration for project-level attention UX
