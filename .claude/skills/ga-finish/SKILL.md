---
name: "ga-finish"
description: Close the builder's finished Grow your Anime piece. Run the checks, review what players see, update the one status home and the team notes, log assets, commit only our paths, push. Builder only; the other teammates close pieces as their briefs say. Use when a piece of work is done or the director says to wrap up.
---

# Finish a piece (builder only)

The other teammates close their pieces as their briefs say. Step 7 pushes, and only the builder pushes for the team.

1. **Checks, all passing.**
   - the type check, the logic tests and the self-test, once they exist (for example the type check, the self-test and the logic tests, in each place that has them).
   - The world report if markers or world code changed.
   - a purchase in the published game, if the store changed (for example a match smoke test if the match lifecycle changed, or the first session played from a new save if anything a new player meets changed: the aim is a premium first session).
   - Add a self-test or logic case for every new mechanic or rule.
2. **What players see goes through "The checks, in order"** (AGENTS.md):
   - **Your own review:** player-camera captures at 1920×1080 and 1366×768, in the place's real lighting, then a harsh self-critique against the bar. World pieces are also seen at the player's distance, in the place's real lighting, with a backup of what they replaced.
   - **QA's evidence pack:** file a test request in `docs/test-requests.md`. Until QA runs it, your captures stand in.
   - **Research's artistic pass:** close only after it passes. If research is off, close, and note it on the Now board's research line. Research reviews the piece on its return, and reopens it if it's below the bar.
3. **Status, once.**
   - Update the status line and the milestone table in `docs/production-plan.md`, the only status home.
   - Update a spec only if behaviour changed.
4. **Team notes.**
   - Update the "Now" board.
   - Add one entry at the top, at most about 10 lines: what changed, where it lives, what's open, who it's for.
   - If the file passes about 250 lines, move the oldest entries to `docs/archive/`.
5. **Assets.**
   - Add a row to `docs/asset-log.md` for each new or replaced asset.
   - Before any upload or publish, the content check (`ga-content-check`) must PASS. An ASK DIRECTOR waits for the director.
6. **Tidy.** Delete the temp files, unused parts and dead code you created, and empty `build/import`.
7. **Commit by path, then push.**
   - `git add` only the paths you changed (never `-A`), then commit exactly those: `git -c user.name=glocen -c user.email=92930182+glocen@users.noreply.github.com commit -m "<message>" -- <paths>`. For a file that also holds another session's edits, see AGENTS.md, "Shared folder and git".
   - Then push, never by force. The director, 2026-11-11: "You can start pushing on the github of grow your anime". Pushing carries the teammates' local commits too.
8. **Report** to the director, each stated separately: implemented, tested, visually reviewed, director-accepted. Then suggest `/clear` before an unrelated piece.
