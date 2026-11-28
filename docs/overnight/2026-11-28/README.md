# Overnight cloud production, 2026-11-28

Quaestor (research), 2026-11-28, about 03:15 UTC, from a cloud session, on the director's word before sleep. Each prompt in `prompts/` is self-contained: paste it whole into a new cloud session. Each session writes its own record here as `<Name>.md`, and those records are what the morning integrates.

## What research measured in a cloud container tonight

| Thing | Result |
|---|---|
| The offline logic suite (Lune 0.11.1) | PASSED: 78,495 cases, 0 failed, 4 s |
| The models check | PASSED: 6 models, 0 with differences |
| The type check (luau-lsp 1.70.1, Rojo 7.7.1) | PASSED: 0 new, 11 known, 7 s |
| Pinned tools from GitHub releases, Blender from blender.org, apt, PyPI | all reachable; Blender 5.3.0's checksum matches |
| Headless Blender 5.3 | Cycles on the CPU and Workbench under 1 s for a small scene; EEVEE through software Mesa, about 40 s for its first frame; no GPU |
| The team's hooks | **don't run**: every hook calls `py`, which Linux lacks. The shell guard and memory guard are off, and every MCP tool is refused (the MCP guard fails closed) |
| A `py` shim (tested, then not used) | the guards run, but a cloud session has no signed teammate title, so the role reads "unknown" and **every `git push` is refused** |
| The pre-commit reference guard | doesn't run (no `py`, and `core.hooksPath` is unset). The prompts run it by hand before every commit |
| Absent in the cloud | Studio, Rojo serve, the Open Cloud key, Gemini, Codex, `build/scratch`, `build/captures`, `build/reference` (no shipped frames), `handbook/` |
| Present | `build/handoff/` (1.3 GB), all of `src/`, `tools/`, `docs/` |

**Sourced, not tested** (code.claude.com docs): cloud sessions share the subscription's one usage budget, and parallel sessions spend it in proportion. A session keeps running with the browser closed. An idle VM pauses and can be reclaimed. Whether a cloud session resumes on its own after a usage reset is UNCONFIRMED. `CLAUDE_CODE_REMOTE=true` marks a cloud session.

## The team tonight, and why

| Order | Session | Model, effort | Primary work | Expected by morning | Limits |
|---|---|---|---|---|---|
| 1 | **Faber** | Opus 5.5, high (the director, 11-27) | the op ledger's nil-id hole; the Studio-only remotes on live servers; hostile-input and heavy-save tests; TR71's Next as a pure rule; the rest-per-difficulty migration once research rules | 5 to 8 fixes and rules, each with cases, offline-tested | nothing Studio-verified; HUD wiring waits for the PC |
| 2 | **Quaestor** | Opus 5.5, high (the director, 11-27) | rulings within the hour; picks as targets land; Turing II's blind calibration on the director's 38 judged examples; one Early Access readiness page | rulings, picks that unblock the makers' builds tonight, a measured calibration with a held-out half | no shipped frames, so that verdict dimension is NOT VERIFIED; GPT's Turing II proposal is on the PC, unread |
| 3 | **Scintilla** | Opus 5.5, xhigh (the director, 11-23) | a reusable cloud stage calibrated to a real Studio take; the burn's two must-fixes; AR77's fall targets; AR76's Mantaflow sim kit into 8x8 flipbooks | the stage, the burn's fix in data, the fall targets picked or ruled, a first sim kit | no Studio take, no uploads; the stage is an approximation with its gap written down |
| 4 | **Modulo** | Opus 5.5, xhigh (the director, 11-25) | the pipeline made portable; Pip's collar back (already picked); the Shades' round 3 targets; Kirra's blades targets; the build after a pick | Pip finished on the model, two pieces at a pick, maybe one built | the PC may hold uncommitted round 3 work (row of 02:28); CPU renders only |
| 5, optional | **Probator** | Opus 5.5, high | independent hostile-input, sequence and remote-surface tests outside `src`; persistence windows; regression runs on Faber's branch | failing cases for real defects, or evidence that named attacks fail | launch only if the budget allows a fifth session (below) |

**Not launched: Sonus.**
- Every cue waits on the director's ear in play: the 22 and the 7 are installed and unheard.
- Shortlisting runs through Studio's audition panel.
- Our own synthesized sounds were rejected ("horrendous", "comic gibberish").
- A night of sound work would make nothing the director can judge by morning.

**Four sessions is the recommendation.**
- They draw on one budget, and a fifth adds about a quarter more spend for the least unique output: Faber's queue already holds the hostile-input tests.
- **Launch Probator** if you're on the largest plan and want the tester independent of the fixer (Faber detects Probator's branch and hands it those tests).
- **If budget is tight:** run Scintilla and Modulo at high, not xhigh, tonight. Their work is the hardest taste work, so that's a real loss, but a session that stops at a limit makes nothing.

**Why not fewer?** The four have independent queues of 6 to 8 hours each, disjoint paths, and one real dependency (picks), which runs in the direction that pays: makers make targets, research picks them overnight, and the makers build before morning.

## How to launch (about 5 minutes)

1. Start each session on this repo from **`main`** (not this branch), in the order above, a minute apart.
2. Pick the model, and the effort if the picker offers it.
3. Paste the whole prompt from `prompts/<Name>.md`.
4. Rename each session to its name ("Faber overnight", and so on), so you can tell them apart. Naming a teammate's session is the director's to do.
5. Close the tab. The sessions keep running.

## In the morning

- **Find the branches.** Each session reports its own (`claude/...`), and each holds `docs/overnight/2026-11-28/<Name>.md`. Read Quaestor's top section first: one screen, each worker in one line.
- **Integration order:**
  1. Quaestor (docs only);
  2. Faber (`src`, his record);
  3. Probator's cases (moved into `src/.../Cases` by Faber);
  4. Scintilla (her rows reviewed by Faber, her tools and deliveries);
  5. Modulo (tools, deliveries).
- **The shared files** (`docs/team-notes.md`, `docs/asset-log.md`, the request indexes) were left untouched tonight. Each record's "For integration" holds their lines word for word.
- **Then the PC's checks:** Rojo connected, the Studio smoke tests each record lists, the self-test, and the takes. Only then does anything count as Studio-verified.
- **After integration,** this folder moves to `docs/archive/`.
