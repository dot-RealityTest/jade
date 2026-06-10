# Jade — Public Stable Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring Jade to a stable, polished state (green build/tests, finished Obsidian capture path, prioritized bug/UX fixes) and publish it as a clean fresh-history snapshot to `github.com/aka-kika/jade`.

**Architecture:** Sequential gated phases. Establish a green build baseline on the Xcode-beta toolchain before any code change, verify+commit the already-wired Obsidian vault-writer, run a discover→prioritize→fix polish loop, then scrub for privacy and publish a clean snapshot. No internal `Muxy` identifier changes; user-facing copy stays "Jade".

**Tech Stack:** Swift 6 / SwiftUI + AppKit, libghostty (`GhosttyKit.xcframework`), SwiftPM, Swift Testing, `scripts/checks.sh`, `./scripts/run-jade.sh`, `swiftlint`, `swiftformat`, git.

**Spec:** `docs/superpowers/specs/2026-06-10-jade-public-stable-release-design.md`

---

## File / area map

| Area | Paths |
|------|-------|
| Build/toolchain | `scripts/setup.sh`, `scripts/checks.sh`, `scripts/run-jade.sh`, `Package.swift` |
| Obsidian capture (in-flight) | `Muxy/Services/ObsidianVaultWriter.swift`, `Muxy/Models/ObsidianCaptureWriteMode.swift`, `Muxy/Models/ObsidianMCPSettings.swift`, `Muxy/Models/ObsidianMCPToolAction.swift`, `Muxy/Services/ObsidianMCPSettingsStore.swift`, `Muxy/Services/ObsidianSendService.swift`, `Muxy/Views/Settings/MCPToolsSettingsView.swift`, `Muxy/Services/JadeJourneyBootstrapService.swift` |
| Obsidian tests | `Tests/MuxyTests/Services/ObsidianVaultWriterTests.swift`, `Tests/MuxyTests/Services/ObsidianMCPTests.swift`, `Tests/MuxyTests/Services/CapturePathIntegrationTests.swift`, `Tests/MuxyTests/Services/JadeJourneyTests.swift` |
| Polish (discovered) | TBD per Phase 2 findings — one task appended per agreed fix |
| Publish | git remotes, `README.md`, `docs/`, untracked `.handoff/`, `PROJECT_CATCH_UP.md`, `plan.md` |

---

## Phase 0 — Green baseline

**Goal:** A clean build + green tests + passing `checks.sh` on the Xcode-beta toolchain, with zero behavior changes. This is a hard blocker; do not proceed to Phase 1 until it passes.

### Task 0.1: Point the build at the full Xcode toolchain

**Files:** none (environment).

- [ ] **Step 1: Check current toolchain**

Run: `xcode-select -p`
Expected: `/Library/Developer/CommandLineTools` (the broken state — SwiftPM can't load `BuildServerProtocol.framework`).

- [ ] **Step 2: Switch to Xcode-beta (user runs this — needs sudo)**

Ask the user to run in the session:
```
! sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
```
Expected: no output, exit 0. (Alternative without sudo for a single command: prefix builds with `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`.)

- [ ] **Step 3: Verify the switch**

Run: `xcode-select -p && xcrun --find swift`
Expected: path now under `/Applications/Xcode-beta.app/...`.

### Task 0.2: Restore GhosttyKit.xcframework if missing

**Files:** `scripts/setup.sh` (read-only use).

- [ ] **Step 1: Check for the xcframework**

Run: `ls -d GhosttyKit.xcframework 2>/dev/null && echo PRESENT || echo MISSING`
Expected: `PRESENT` or `MISSING`.

- [ ] **Step 2: If MISSING, run setup (may download multi-GB artifact)**

Run: `scripts/setup.sh`
Expected: completes, `GhosttyKit.xcframework/` now exists. If it fails to download, stop and surface the error to the user — do not work around it in code.

### Task 0.3: Establish the green baseline

**Files:** none (verification only).

- [ ] **Step 1: Build**

Run: `swift build 2>&1 | tail -20`
Expected: `Build complete!` (no errors). If errors appear, they are real and must be triaged before continuing.

- [ ] **Step 2: Test**

Run: `swift test 2>&1 | tail -30`
Expected: all tests pass (note the count). Record any pre-existing failures explicitly — they become Phase 2 candidates, not silent passes.

- [ ] **Step 3: Run the full check gate**

Run: `scripts/checks.sh --fix`
Expected: formatting/lint/build all pass. If `--fix` modifies files, review the diff.

- [ ] **Step 4: Record the baseline**

Run: `git stash list; git status -s | head` (no commit here — baseline is the current working tree once green). Note the green state in your working notes.

---

## Phase 1 — Finish & commit the Obsidian vault-writer

**Goal:** The already-wired vault-writer capture path compiles, its tests pass, contains no personal vault paths, and is committed as one clean unit. (Code is integrated already: `ObsidianSendService.swift:160` switches on `captureWriteMode`; `:204`/`:211` call `appendCaptureBlock`/`writeNote`. This phase verifies and lands it.)

### Task 1.1: Review the capture wiring for correctness

**Files:** Read `Muxy/Services/ObsidianSendService.swift`, `Muxy/Services/ObsidianVaultWriter.swift`, `Muxy/Models/ObsidianCaptureWriteMode.swift`, `Muxy/Services/ObsidianMCPSettingsStore.swift`, `Muxy/Views/Settings/MCPToolsSettingsView.swift`.

- [ ] **Step 1: Verify append vs new-file behavior**

Read `ObsidianSendService.swift` around line 160. Confirm `.append` mode routes to a writeNote call with `append: true` and `.newFile` produces a unique filename per send (no overwrite). Confirm the read-only guard (`ObsidianVaultWriterError.readOnly`) is honored before any write.

- [ ] **Step 2: Verify path safety is reachable**

Confirm `resolvedFileURL` (`ObsidianVaultWriter.swift:50`) is on the write path so `.pathEscapesVault` / `.invalidRelativePath` can actually fire. No code change unless a gap is found; if a gap is found, write a failing test first (Task 1.2 pattern) before fixing.

### Task 1.2: Confirm the Obsidian tests are green

**Files:** `Tests/MuxyTests/Services/ObsidianVaultWriterTests.swift`, `ObsidianMCPTests.swift`, `CapturePathIntegrationTests.swift`, `JadeJourneyTests.swift`.

- [ ] **Step 1: Run the Obsidian + capture + journey suites**

Run: `swift test --filter Obsidian 2>&1 | tail -20`
Expected: pass. Then:
Run: `swift test --filter CapturePath 2>&1 | tail -20` and `swift test --filter JadeJourney 2>&1 | tail -20`
Expected: pass.

- [ ] **Step 2: If any fail, fix root cause TDD-style**

Keep the failing test, make the minimal source change to pass it, re-run the single test, then re-run the suite. Do not weaken assertions to force a pass.

### Task 1.3: Scrub personal paths from the in-flight files

**Files:** all Phase-1 source + test files listed above.

- [ ] **Step 1: Scan for personal data in the changed set**

Run: `git diff --name-only HEAD; echo '---'; git diff HEAD -- Muxy Tests | grep -nEi "/Users/kika_hub|_KIKA_MAIN|Kika.?s_Obsidian|miss\.iliuchina@gmail\.com" || echo "CLEAN"`
Expected: `CLEAN`. If hits appear, replace with neutral test fixtures (e.g. a temp-dir path) — never a real personal vault path.

- [ ] **Step 2: Re-run affected tests after any scrub edit**

Run: `swift test --filter Obsidian 2>&1 | tail -10`
Expected: pass.

### Task 1.4: Commit the finished capture path

**Files:** the Phase-1 source + test set.

- [ ] **Step 1: Run the gate**

Run: `scripts/checks.sh --fix`
Expected: pass.

- [ ] **Step 2: Stage and commit only the Obsidian capture files**

```bash
git add Muxy/Services/ObsidianVaultWriter.swift Muxy/Models/ObsidianCaptureWriteMode.swift \
  Muxy/Models/ObsidianMCPSettings.swift Muxy/Models/ObsidianMCPToolAction.swift \
  Muxy/Services/ObsidianMCPSettingsStore.swift Muxy/Services/ObsidianSendService.swift \
  Muxy/Views/Settings/MCPToolsSettingsView.swift Muxy/Services/JadeJourneyBootstrapService.swift \
  Tests/MuxyTests/Services/ObsidianVaultWriterTests.swift Tests/MuxyTests/Services/ObsidianMCPTests.swift \
  Tests/MuxyTests/Services/CapturePathIntegrationTests.swift Tests/MuxyTests/Services/JadeJourneyTests.swift
git commit -m "Finish Obsidian vault-writer capture path (append / new-file modes)."
```
Expected: one commit; `git status -s` no longer lists these files.

- [ ] **Step 3 (optional): Live dogfood against a real vault**

Run: `JADE_DOGFOOD_OBSIDIAN=1 ./scripts/dogfood-capture-path.sh` (only if the user wants a live vault send; otherwise run `./scripts/dogfood-capture-path.sh` for the integration test path).
Expected: capture lands under the configured vault; no errors.

---

## Phase 2 — Discover & prioritize bugs / UI polish

**Goal:** Produce a prioritized issue list from a running app + test/lint sweep, get user sign-off on which to fix, then fix the agreed top tier TDD-style. Tasks for individual fixes are appended to this plan as they're agreed — they are not pre-written because the bugs aren't known yet.

### Task 2.1: Launch the app and exercise core flows

**Files:** none (manual QA via `scripts/run-jade.sh`).

- [ ] **Step 1: Build & launch the real app bundle**

Run: `./scripts/run-jade.sh`
Expected: `Jade.app` launches with the correct icon (not the bare `Muxy` binary).

- [ ] **Step 2: Walk core flows and note defects**

Exercise: add/open a project; create/close/select tabs; split panes; terminal input/scrollback; command palette (Rich Input, Find in Files, Toggle Sidebar, MCP/Obsidian actions); Rich Input (`⌘I`) incl. slash menu ↑/↓/Return/Escape; Settings (MCP Tools, AI); project log (Set Up Project Log → Confirm Next Step → Complete Step). Record each defect with: what happened, expected, repro steps.

### Task 2.2: Static sweep

**Files:** whole tree.

- [ ] **Step 1: Strict lint + format check**

Run: `swiftlint lint --strict 2>&1 | tail -30` and `swiftformat --lint . 2>&1 | tail -30`
Expected: note any violations not auto-fixed.

- [ ] **Step 2: Full test run for flaky/failing tests**

Run: `swift test 2>&1 | tail -40`
Expected: record any failures/flakes.

### Task 2.3: Produce the prioritized issue list and get sign-off

**Files:** append findings to this plan under "Phase 2 fixes".

- [ ] **Step 1: Write the ranked list**

Rank: crashes/data-loss > functional bugs > visible UX rough edges > minor polish. For each: title, severity, repro/why, proposed fix, rough effort. Present to the user.

- [ ] **Step 2: User selects the top tier**

Wait for the user to pick which items to fix this round. Append one task per selected item using the TDD task template below.

### Task 2.N (template, one per agreed fix): [Defect title]

**Files:** Create/Modify/Test — exact paths once the defect is localized.

- [ ] **Step 1: Write a failing test reproducing the defect** (code shown when the defect is known)
- [ ] **Step 2: Run it; confirm it fails for the right reason**
- [ ] **Step 3: Make the minimal root-cause fix** (no symptom patching)
- [ ] **Step 4: Run the test; confirm pass**
- [ ] **Step 5: `scripts/checks.sh --fix`, then commit** with a one-line message

> For UI-only polish with no testable assertion, replace Steps 1–4 with: make the change, relaunch via `./scripts/run-jade.sh`, capture a before/after screenshot, confirm with the user, then run the gate and commit.

---

## Phase 3 — Public-home prep & publish

**Goal:** A clean, scrubbed, building snapshot pushed to `aka-kika/jade` with fresh history, behind an explicit final approval gate.

### Task 3.1: Full-tree privacy/scrub audit

**Files:** whole tree (source, tests, docs, scripts, untracked notes).

- [ ] **Step 1: Scan tracked + untracked content for personal data**

Run:
```bash
grep -rnEi "/Users/kika_hub|_KIKA_MAIN|Kika.?s_Obsidian|miss\.iliuchina@gmail\.com" \
  --include='*.swift' --include='*.md' --include='*.sh' --include='*.json' --include='*.txt' . \
  | grep -v 'docs/superpowers/' || echo "CLEAN"
```
Expected: `CLEAN`. (Spec/plan docs under `docs/superpowers/` are local and excluded from the snapshot in Step 3.)

- [ ] **Step 2: Remediate any hits**

Replace personal paths/emails/vault names with neutral placeholders or remove. Keep intended internal identifiers: `com.muxy.app`, `muxy://`, `~/Library/Application Support/Muxy/`, the SwiftPM `Muxy` target. Re-run the Step 1 scan until `CLEAN`.

- [ ] **Step 3: Decide disposition of local-only notes**

Confirm with the user whether `.handoff/`, `PROJECT_CATCH_UP.md`, `plan.md`, and `docs/superpowers/` should be excluded from the public snapshot (recommended: exclude — they're working notes). Record the exclude list for Task 3.3.

### Task 3.2: Public docs sanity pass

**Files:** `README.md`, `docs/README.md`, `docs/` user guides, landing assets.

- [ ] **Step 1: Read README + docs as a first-time public visitor**

Confirm: user-facing name is Jade; macOS-only scope is clear; install/build instructions are accurate (no Homebrew cask, no `muxy` CLI alias, `jade` CLI only); no broken links to internal-only docs; screenshots render.

- [ ] **Step 2: Fix any inaccuracies, run the gate, commit**

```bash
scripts/checks.sh --fix
git add -A && git commit -m "Polish public docs for release."
```

### Task 3.3: Build the clean snapshot and publish (final gate)

**Files:** git history/remotes.

- [ ] **Step 1: Confirm working tree is green and committed**

Run: `git status -s` (expect clean except intentionally-excluded local notes) and `swift build 2>&1 | tail -3` (expect `Build complete!`).

- [ ] **Step 2: Create an orphan snapshot branch (no history)**

```bash
git checkout --orphan public-release
# remove excluded local notes from the snapshot per Task 3.1 Step 3
git rm -r --cached --quiet .handoff PROJECT_CATCH_UP.md plan.md docs/superpowers 2>/dev/null || true
git add -A
git commit -m "Jade: stable public release snapshot."
```
Expected: a single root commit containing the polished tree.

- [ ] **Step 3: Add the remote and push — ONLY after explicit user approval**

Present the snapshot contents (`git show --stat HEAD | head -40`) to the user. After explicit "yes, publish":
```bash
git remote add aka-kika https://github.com/aka-kika/jade.git 2>/dev/null || git remote set-url aka-kika https://github.com/aka-kika/jade.git
git push --force aka-kika public-release:main
```
Expected: `aka-kika/jade` `main` now holds the clean snapshot. Then return to the working branch: `git checkout main`.

- [ ] **Step 4: Verify the published repo**

Run: `git ls-remote https://github.com/aka-kika/jade.git main`
Expected: the new snapshot commit hash. Confirm with the user.

---

## Notes for the executor

- **Do not push to `origin` (`muxy-app/muxy`).** The only publish target is `aka-kika/jade`, and only at Task 3.3 Step 3 with explicit approval.
- **No code comments** (repo rule). Self-explanatory code, early returns, root-cause fixes.
- **Run `scripts/checks.sh --fix` after every code task.**
- **Out of scope:** versioned/tagged release artifact, Sentry v9, Sparkle 2.9.2, Swift 6.2 language mode, NavigationSplitView refactor, Liquid Glass pass, Moltis bundle, renaming internal `Muxy` identifiers.
