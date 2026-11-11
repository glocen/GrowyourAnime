---
name: "ga-start"
description: Start the builder's Grow your Anime session. Sync git safely, get Rojo and the Studios ready, read only the current state, confirm the piece. Builder only; the other teammates start from their briefs. Use once at the start of the builder's session or when the director says to start.
---

# Start a session (builder only)

The other teammates don't run this: their briefs say how they start, and only the builder pulls.

1. **Git.**
   - Run `git status`, then `git fetch`.
   - If `origin/main` is ahead, pull with `git pull --rebase`, after comparing any blocking local file with `origin/main` and removing only identical copies.
   - Never stash, reset, restore or delete another session's files. If their uncommitted work blocks the pull, skip the pull and tell the director.
   - Pull the handbook's clone too: `handbook`.
2. **Rojo.** Make sure it's serving through `tools/rojo-serve.ps1` in a visible terminal. A pull crashes Rojo: if you pulled, ask the director to reconnect each Studio (Plugins → Rojo → Connect), then check Studio has the pulled code.
3. **Studios and turns.**
   - Run `list_roblox_studios` (ids change on restart).
   - Read the Now board's "Turns": at most two Studios open, and one timing test at a time.
   - Never playtest a place another teammate holds: a playtest locks its Edit DataModel.
4. **State, not history.**
   - Read the "Now" board and the newest 3 entries of `docs/team-notes.md`, then the status line and the piece's own block in `docs/production-plan.md`.
   - Read the spec section the piece touches, nothing more.
5. **Baseline.** If the piece changes code, run the self-test once before editing (`/ga-studio-test`), so you know what was already failing. Skip it when the last full pass already covers HEAD's `src/`.
6. **Tell the director in 3 to 5 lines:** the piece for this session, its acceptance checks, and anything you need from them (approvals, Studio clicks, publishing).
