# Jade — Public Stable Release Design

**Date:** 2026-06-10
**Status:** Approved for planning
**Owner:** KIKA

## Goal

Bring Jade to a stable, polished state and establish **`github.com/aka-kika/jade`** as its new
canonical public home. "Stable" means: a clean build, green tests, `scripts/checks.sh` passing,
the in-flight Obsidian capture work finished, and a prioritized round of bug/UX fixes applied —
published to the new public repo as a clean snapshot with fresh history.

## Decisions (locked)

- **Release target:** `aka-kika/jade` becomes the new public home. Add it as a git remote and
  publish there.
- **Publish strategy:** **Clean snapshot, fresh history** (orphan/squashed initial commit).
  This overwrites the current divergent content at `aka-kika/jade` and drops the 70 internal
  commits currently on local `main`.
- **Polish approach:** **Discover then prioritize** — after the build is green, run the app +
  tests, produce a prioritized issue list, fix the top tier with user sign-off.
- **In scope:** stabilize build/tests, finish the Obsidian vault-writer capture path,
  bug-fix/UI-polish pass, publish clean snapshot.
- **Out of scope (for now):** cutting a tagged/packaged versioned release artifact (version
  bump, notes, signed appcast); NavigationSplitView refactor; full Liquid Glass pass; Moltis
  bundle; Sentry v9 / Sparkle 2.9.2 / Swift 6.2 upgrades; renaming internal `Muxy` identifiers.

## Standing constraints (from CLAUDE.md / learned preferences)

- Keep `com.muxy.app`, `muxy://`, `~/Library/Application Support/Muxy/`, the SwiftPM `Muxy`
  target, and internal Muxy identifiers **stable**. User-facing copy says **Jade**; CLI is
  **`jade`** only.
- No code comments; self-explanatory code; early returns; fix root causes not symptoms.
- Run `scripts/checks.sh --fix` after every task.
- Do not push to `origin` (`muxy-app/muxy`). Pushing to `aka-kika/jade` happens only at the
  final gate with explicit approval.
- Write tests for any testable behavior changed or added.

## Phased plan (sequential gates)

Each phase ends at a checkpoint the user signs off before the next begins.

### Phase 0 — Green baseline (blocker for everything)

The app cannot build right now: `xcode-select` points at CommandLineTools, but the project
needs the full Xcode toolchain (`Xcode-beta.app`, Swift 6.4 / macOS 27 host).

- Point the toolchain at Xcode-beta for builds (`DEVELOPER_DIR` or `xcode-select -s`; the latter
  needs the user to run it via `sudo`).
- Restore `GhosttyKit.xcframework` via `scripts/setup.sh` if missing (gitignored, large).
- Run `swift build`, `swift test`, then `scripts/checks.sh --fix`.
- **Exit criteria:** clean build, all existing tests green, checks pass. No behavior changes
  beyond the minimum needed to compile. Record the known-green commit/state.

### Phase 1 — Finish in-flight Obsidian vault-writer

Uncommitted work: `Muxy/Services/ObsidianVaultWriter.swift`,
`Muxy/Models/ObsidianCaptureWriteMode.swift`, modified MCP files
(`ObsidianMCPSettings`, `ObsidianMCPToolAction`, `ObsidianMCPSettingsStore`,
`ObsidianSendService`, `MCPToolsSettingsView`), `JadeJourneyBootstrapService`, and tests
(`ObsidianVaultWriterTests`, plus changes to `CapturePathIntegrationTests`, `JadeJourneyTests`,
`ObsidianMCPTests`). The vault writer already includes path-escape protection.

- Review the writer, write-mode model, settings store, and `ObsidianSendService` wiring for
  completeness and correct integration (append vs new-file mode, read-only guard, path safety).
- Confirm no hard-coded personal vault paths leak into source or fixtures (public-repo safe).
- Make all related tests green; add tests for any gap found.
- **Exit criteria:** feature compiles, tests green, `checks.sh` passes, committed as one clean
  unit. Optional live verification via `./scripts/dogfood-capture-path.sh`
  (`JADE_DOGFOOD_OBSIDIAN=1` for a real vault send).

### Phase 2 — Discover & prioritize bugs / UI polish

- Launch via `./scripts/run-jade.sh`; exercise core flows (projects/tabs/splits, terminal,
  command palette, Rich Input, Settings/MCP, project log).
- Run the full test suite and `swiftlint --strict` / `swiftformat --lint`.
- Produce a **prioritized issue list** (correctness/crash bugs first, then UX rough edges),
  each with a short repro/why and a proposed fix.
- User picks which to fix; implement the top tier (root-cause fixes, tests where testable),
  re-verify after each with `checks.sh --fix`.
- **Exit criteria:** agreed top-tier issues fixed and verified; build/tests/checks green.

### Phase 3 — Public-home prep & publish

- **Privacy/scrub audit:** scan the tree (source, tests, fixtures, docs, scripts) for personal
  paths (`/Users/kika_hub`, `_KIKA_MAIN`, `Kika's_Obsidian`), emails
  (`miss.iliuchina@gmail.com`), and any private vault/host names. Remove or anonymize. Keep
  intended internal `Muxy` identifiers.
- **Public docs check:** README, `docs/`, landing assets read correctly for a fresh public
  visitor; user-facing copy says Jade; install instructions accurate.
- **Snapshot & publish:** build a clean fresh-history snapshot (orphan branch or squashed root
  commit) of the polished tree; add `aka-kika/jade` as a remote; push. **Final gate — explicit
  user approval before anything goes public.**
- **Exit criteria:** `aka-kika/jade` holds the clean, building, scrubbed snapshot; user confirms.

## Risks & mitigations

- **Toolchain/xcframework friction (Phase 0):** if `swift build` fails for environment reasons,
  fix the environment first; do not paper over with code changes. `sudo xcode-select` and large
  xcframework download may need the user to run a command interactively.
- **Unbounded polish scope (Phase 2):** mitigated by the discover→prioritize→sign-off gate; we
  fix a top tier, not "everything."
- **Privacy leak to public repo (Phase 3):** mitigated by a dedicated scrub audit as a hard
  gate before push; fresh history avoids exposing internal commit history.
- **Irreversible publish:** fresh-history push to a public repo is hard to fully retract; gated
  on explicit approval and a completed scrub audit.

## Success criteria

1. `swift build` + `swift test` + `scripts/checks.sh` all green locally on Xcode-beta toolchain.
2. Obsidian vault-writer capture path finished, tested, committed.
3. Agreed top-tier bugs/UX issues fixed and verified.
4. No personal paths/emails/private vault names in the published tree.
5. `aka-kika/jade` populated with the clean snapshot, with user sign-off.
