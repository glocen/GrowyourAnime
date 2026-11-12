# Third-party libraries

Each is copied from its source unedited and called only through one wrapper of ours (`handbook/engineering/code-standards.md`, "Third-party and kept code"). Rojo maps `shared/` and `server/` only, so licenses sit here at the root.

| Library | Where | Source, pinned | License | Our wrapper |
|---|---|---|---|---|
| ProfileStore 1.0.3 | `server/ProfileStore.luau` | github.com/MadStudioRoblox/ProfileStore, commit `45c9847cbcf1fc260369c50eb335aba7c35aecdd` (2025-07-31), fetched 2026-11-12 | Apache-2.0, `ProfileStore.LICENSE` | `src/server/Services/Core/DataService.luau` |
