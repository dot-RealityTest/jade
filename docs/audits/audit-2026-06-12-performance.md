# Performance Audit — 2026-06-12

Scope: full-app performance pass (startup, SwiftUI rendering, IO/persistence/subprocess, terminal bridge).
Method: four parallel read-only audit agents over `Muxy/` (~420 files, ~73k LOC). Findings verified by file:line.

## Priority shortlist (best effort-to-impact)

| # | Finding | Area | Severity | Effort |
|---|---------|------|----------|--------|
| 1 | Synchronous JSON loads (projects, worktrees, workspaces) on main thread before first frame | Startup | Critical | Low |
| 2 | `stagedFiles`/`unstagedFiles` filters + tree rebuilds recomputed 5+ times per render | SwiftUI | High | Low |
| 3 | Git status spawned per file-tree reload, no caching/coalescing; FSEvents triggers parallel refreshes | IO | High | Med |
| 4 | `vcsPruneSignature` O(N) array rebuild on every AppState change | SwiftUI | High | Low |
| 5 | ProjectStore saves full JSON synchronously on every mutation (no debounce) | IO | High | Low |
| 6 | `untrackedFilesDiff()` spawns one `git diff --no-index` per untracked file (51 processes for 50 files) | IO | High | Med |
| 7 | Eager `saveWorkspaces()` calls bypass the 300ms debounce | IO | High | Low |
| 8 | Batch mutations during VCS refresh fire @Observable cascades per-mutation | SwiftUI | High | Med |

---

## 1. Startup (before first frame)

1. **MuxyApp.swift:23 — CRITICAL** — `ProjectStore.init()` synchronously reads + JSON-decodes `projects.json` on main thread (`CodableFileStore.load()` at CodableFileStore.swift:24-25 uses `Data(contentsOf:)` + inline decode). Fix: load async, render empty state first.
2. **MuxyApp.swift:24-26 — CRITICAL** — `WorktreeStore.init()` loads worktree JSON for *every* project synchronously; cost scales with project count.
3. **MuxyApp.swift:33-35 — CRITICAL** — `appState.restoreSelection()` synchronously loads + decodes the full `workspaces.json` snapshot tree.
4. **MuxyApp.swift:299 — HIGH** — `GhosttyService.shared` init (`ghostty_init()` + config file read) on main thread before first frame.
5. **MuxyConfig.swift:111-122 — MEDIUM** — ghostty config read twice (seed pass + `loadMuxyGhosttyConfig()`); redundant IO.
6. **MuxyApp.swift:291 — MEDIUM** — Sentry SDK start before first frame.
7. **MuxyApp.swift:301-304 — MEDIUM** — ThemeService default/migration passes each re-read the entire ghostty config line-by-line; `applyTerminalRenderDefaultsIfNeeded` may also write it back synchronously.
8. **MuxyApp.swift:312-319 — LOW** — `AIProviderRegistry.installAll()` probes filesystem paths per provider; async but unprioritized.
9. **MuxyApp.swift:22-45 — DESIGN** — `AppEnvironment.live` eagerly constructs all persistence stores; defer non-critical ones (e.g. `RemoteSpacesStore`) past first frame.

## 2. SwiftUI rendering / observation

1. **VCSTabState.swift:142-148 + VCSTabView.swift:1287,1437,1455,1524-1546 — HIGH** — `stagedFiles`/`unstagedFiles` are computed filters accessed 5+ times per render; each change also rebuilds `stagedTreeRows`/`unstagedTreeRows` (VCSTabState.swift:510-516 → `VCSFileTree.rows()` → O(N log N) sort). Fix: stored properties with invalidation; compute tree rows once on mutation.
2. **MainWindow.swift:260-261, 2171-2186 — HIGH** — `vcsPruneSignature`/`vcsEnsureSignature` rebuild full UUID arrays (nested loop over all projects × worktrees) on every observation as a change detector. Fix: lightweight hash or direct mutation observation.
3. **VCSTabState.swift:365-402 — HIGH** — `performRefresh()` mutates 3 expansion Sets + `files` array + per-file diff loads as separate @Observable mutations; each triggers downstream tree recomputation. Fix: single-transaction batch.
4. **VCSTabState.swift:1220-1229 + VCSTabView.swift:1527 — MEDIUM** — `filteredPullRequests` full filter + allocation just to render a header count. Fix: cache, pre-compute count, debounce search.
5. **MainWindow.swift:150-156 — MEDIUM** — GeometryReader updates `mainWindowWidth` per resize event; 8+ derived layout properties (lines 796-908) recompute per event. Fix: debounce, cache derived metrics.
6. **MainWindow.swift (2640 lines) — MEDIUM** — monolithic body with 19 `.onChange` observers over a large @Observable AppState (lines 153, 260-300, 2324-2630). Fix: decompose into smaller views; push observers to lowest level.

## 3. IO / persistence / subprocess

1. **ProjectStore.swift:19,26,30-42 — HIGH** — every project mutation does full synchronous JSON encode + atomic write on main thread, no debounce. Fix: mirror AppState's 300ms debounce.
2. **GitRepositoryService.swift:714-721 — HIGH** — `countLines()` does synchronous `FileManager.contents()` per untracked file in the diff loop. Fix: batch/async reads.
3. **MainWindow.swift:686,690 + TabAreaView.swift:74,78 — HIGH** — direct `appState.saveWorkspaces()` calls bypass the internal 300ms debounce. Fix: route through `scheduleWorkspaceSave()`.
4. **FileTreeService.swift:18-60 — HIGH** — `loadChildrenSync()` does full `contentsOfDirectory()` + `git check-ignore` per expand/refresh; watcher triggers reload of *all* expanded paths. Fix: reload only changed subtrees from FSEvents paths.
5. **FileTreeState.swift:407-425 — HIGH** — full `git status --porcelain` spawned on every reload, no caching; 0.3s-debounced FSEvents can stack parallel calls. Fix: cache + skip when no relevant changes.
6. **AIAssistantService.swift:164-195 — HIGH** — `untrackedFilesDiff()` = `git ls-files` + one `git diff --no-index` per file, serialized. Fix: batch into few invocations.
7. **GitProcessRunner.swift:295-302 + AIAssistantRunner.swift:218-230 — HIGH** — blocking `readDataToEndOfFile()` on dispatch queues; hung process blocks the thread indefinitely. Fix: DispatchIO / timeouts.
8. **VCSTabState.swift:289-426 — HIGH** — no coalescing of `performRefresh()`; FSEvents can trigger overlapping 4-task refreshes. Fix: single pending-refresh queue.
9. **CodableFileStore.swift:24-25 — MEDIUM** — synchronous `Data(contentsOf:)` + decode (also the startup bottleneck above). Fix: async read/decode.
10. **VCSTabState.swift:1283-1297 — MEDIUM** — PR auto-sync infinite-loop task polls `gh pr list` with no lifecycle management. Fix: proper cancellable timer.
11. **FileSystemWatcher.swift:40,65 — MEDIUM** — 0.3s FSEvents latency + 0.3s debounce = ~600ms perceived lag in file tree/VCS updates. Fix: 100-150ms.
12. **VCSTabState.swift:368-407 — MEDIUM** — per-file diff-cache evicts (100+ files = 100+ evicts). Fix: batch evictions.
13. **RemoteServerDelegate.swift:330-371 — MEDIUM** — `getTerminalContent()` builds full `[TerminalCellDTO]` (~300KB per 200×50 snapshot) before serializing. Fix: stream to Data.
14. **Sidebar.swift — LOW** — 60s usage-refresh timer runs even when sidebar hidden.
15. **GitRepositoryService.swift — LOW** — no dedup of identical concurrent git invocations (e.g. double `currentBranch()`).
16. **FileTreeService.swift:124 — LOW** — `waitUntilExit()` with no timeout.

## 4. Terminal / libghostty bridge

1. **GhosttyTerminalNSView.swift:310-317 — MEDIUM** — deferred Metal-layer resize queues both an immediate async and a 0.1s `asyncAfter`, double-firing per backing change. Fix: single path.
2. **GhosttyTerminalNSView.swift:623-655 — MEDIUM** — every `mouseMoved` calls `ghostty_surface_quicklook_word()` for hover underline. Fix: throttle to ~10Hz.
3. **GhosttyTerminalNSView.swift:739-746 — MEDIUM** — row height derived via full `ghostty_surface_read_cells()` per hover update. Fix: cache, invalidate on resize/zoom.
4. **RemoteTerminalStreamer.swift:52-65 — MEDIUM** — per-PTY-chunk `Data` copy + `main.async` hop, no coalescing. Fix: batch per `ghostty_app_tick()`.
5. **RemoteServerDelegate.swift:330-371 — MEDIUM** — full cell readback even for hidden/occluded panes. Fix: occlusion check first.
6. **TerminalPane.swift:202-247 — LOW/MED** — `updateNSView` reassigns all 7+ callback closures on every SwiftUI render pass. Fix: guard on state identity.
7. **GhosttyRuntimeEventAdapter.swift:88-111 — LOW** — title/PWD events dispatch to main unconditionally (dynamic PS1 spams queue). Fix: dispatch only on actual change.
8. **GhosttyTerminalNSView.swift:1176-1191 — LOW** — alternate-screen check forces cell readback per keystroke when 0.15s cache expires. Fix: cheaper API or longer cache.
9. **GhosttyTerminalNSView.swift:284-292 — LOW** — per-pane `ghostty_surface_set_occlusion()` calls during tab switch, unbatched.

---

## Suggested attack order

**Phase A — quick wins (a day):** startup async loads (§1.1-1.3), ProjectStore debounce (§3.1), saveWorkspaces routing (§3.3), staged/unstaged caching (§2.1), signature hash (§2.2).
**Phase B — VCS/file-tree pipeline (1-2 days):** refresh coalescing (§3.8), git status caching (§3.5), incremental file tree (§3.4), batch mutations (§2.3), FSEvents debounce tuning (§3.11).
**Phase C — polish:** terminal bridge throttles (§4), MainWindow decomposition (§2.6), process safety timeouts (§3.7, §3.16).
