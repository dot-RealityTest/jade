# Platform freeze

Until Jade ships a first-party client or documents a committed third-party consumer, the following surfaces are **frozen** — bug fixes and security only; no new methods, events, or UI expansion.

## WebSocket remote server

| Item | Policy |
| --- | --- |
| `MuxyServer/` + `MuxyShared/` | Maintain existing RPC; no new protocol methods or events |
| Settings → Mobile / Network | Server stays **disabled by default** |
| [Remote server docs](../features/remote-server/README.md) | Marked maintenance-only |
| Pairing, QR, approved devices | No new UX; no Jade iOS target in this repo |

**Rationale:** Full DTO layer and protocol catalog without a shipped mobile app in `dot-RealityTest/jade`. Upstream [Muxy](https://github.com/muxy-app/muxy) may continue mobile work separately.

## Inspector AI

Inspector chat is **Ollama direct** only; terminal PTYs stay independent from agent exec.

## Remote SSH spaces

Not frozen for removal, but **deprioritized** until one remote story wins (SSH sidebar vs LAN WebSocket). Avoid polishing both in parallel.

## When to lift the freeze

1. A first-party Jade iOS or web client is in this repo and used in QA, **or**
2. A documented external client depends on a specific RPC addition (issue + consumer named in PR).

Until then, prefer palette shortcuts and local features over platform expansion.
