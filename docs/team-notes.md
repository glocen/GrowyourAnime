# Team notes

## Now

Each teammate rewrites its own row: one to three lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-28, 03:02 by the clock, wrapped up for the day. Picked or ruled tonight: Pip C done apart from the collar's back (AR63); the Shades' round 3 is meshes on R6 at R6 limb lengths (AR75); the Haymaker's round 2 is simulated fire and smoke (AR76); the fall overhauled as a Void implosion (AR77); Kirra's blades sheathed (AR78); the burn in, with two must-fixes (AR69); no day and night pairs. Next: judge AR77's targets and the Shades' round 3; the Turing II calibration experiment, on the director's go.
- **Next:** AR68 A's must-fixes pass once Faber's captures land; TR73's health ×10 read; AR69 and F1's fixes as Scintilla brings them; the Festival of Battles against the bar.
- **With the director:** the icon's direction (a, b or c); whether research's acting lead of 11-24 still runs; whether the top-left overhaul word (relayed by Modulo) is theirs.

**Faber (builder).** 2026-11-28, 03:02 by the clock, on Opus 5.5. Stopped for the night: nothing running, Studio released (Festival saved, v94, Edit), no lock held.
- Done: Pip's round collar in the dev build (836831a2), zoomed 4x front and 3/4; AR69's burn reviewed (effects case 304/0 with StateBurn). Pip's portraits and card wait on Modulo's back fix of the collar.
- Next: TR72's back-to-back session (the keeper's rest included) for KillsPerHour; then Pip's collar and the four images once Modulo sends them.

**Modulo (assets).** 2026-11-28, 02:28. **AR63, the folds:** Rook's take A by the kit's seam pull, BETTER at the phone's size, to research for the verdict; Kirra's pulls WORSE on her pale trousers, not put in (`docs/requests/AR63.md`, "Rook's and Kirra's folds by the seam pull"). Pip's soft folds are installed (Faber, 3cedfb1e). **AR75's round 2:** not picked; round 3 changes the technique.
- **Now:** AR75's Shades, round 3: the body itself built from meshes on the R6 joints, two or three targets differing in body shape, the mask redrawn with no grin.
- **Next:** Rook's map and install, on research's verdict.

**Scintilla (effects).** 2026-11-28, 02:48. AR76's targets are in for research's pick in a pair: A, the ball, and B, the ram's square, on Lantern Row plates at the game's camera (`build/handoff/Rook/fx/ar76/`; the record in AR76.md). Next: AR69's burn into src on Faber's two ids (the fall waits on AR77), then AR77's targets. No Studio turn held, nothing running.
- **Next:** while AR69 waits, Haymaker's look overhaul (AR59.md, research's note). B5's composition is the director's (2026-11-12), so only its look changes, to the fire kit. Its request and scope are asked of research. AR7's S5 waits on Faber's staging, and AR58's final on QA's pack.

**Sonus (sound).** 2026-11-28, 00:25 by the clock. **The seven gaps are in the game, unheard** (TR64; Faber's dc8a4f97): seven hooked, GearDrop unhooked (no gear drops in a fight). My 22 earlier picks too (TR42). Launch work done; no Studio turn held, nothing running.
- **Next:** the director's word in play on the 22 and the 7 (a miss takes its next); then research's next cue list.

**Turns.** Studio: nobody (Festival saved and released by Faber, 03:02). Blender: headless only, with 2 GB free. Timing tests: nobody.

**The count.** Week of 2026-11-23: 6 pieces closed and playable: AR49, TR10, AR44's shine, TR50, AR50's and AR54's install, AR51 (each entry below has its hours). In the game and waiting: TR52 (the director's run), AR52 (research's pass), TR54 (three must-fixes).

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. **Clips of the chest openings** you know, Sailor Piece's and Taichi Panda 3's, in `build/reference/chest-opening/`, for TR34 ("gimme a moment").
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. ~~Your phone sitting~~: answered, no phone sessions (2026-11-26). F7's times are taken on the PC.

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. ~~Your ear on Haymaker's strike~~: answered, sounds are picked blind and judged in play (2026-11-26, 20:48).
8. **The slam's rule (TR44) and tap to move** are played together: tap to move is on the pad (Faber, 728b88e0), and A's walk-out no longer pulls the lead off while it's on. Judge both in one sitting.
9. **The Festival's place, after the main map and the systems** (TR45; your word of 2026-11-23, 00:05: the team has full access to it). When its work opens, the Creator Dashboard's settings stay yours to confirm: its name (Faber's suggestion: Festival of Battles), its server size 8, and its Direct Access set to "Secure within universe only". Then the id goes into `CLAUDE.md`'s "Places".
10. **Sailor Piece's UI, for the UI's complete overhaul:** 10 to 20 screenshots in `build/reference/inbox/` (its fight HUD, menus, an inventory, a reward screen, a few buttons up close), or 15 minutes live with Faber on your account. Anime Crusaders X's study is in (`docs/research/anime-crusaders-ui-surface.md`).
11. ~~Turing v0's restatement~~: answered, research's call (03:47); written in at 12:24 on the director's word, without u3 (`docs/decisions.md`, `docs/turing.md`).
12. ~~The power timeouts~~: answered, they stay "never" (03:47).
13. ~~Pip's finish~~: answered, research's call (03:47): released, and it starts once Kirra's hair passes the director's look (AR63).

### Notices

- **Research, 2026-11-26, 22:29, Gemini's memory (the director's ask, 22:08 to 22:20):** Gemini reads a role file (`ROLE.md`) and its own notes (`NOTES.md`) at the start of every session, and ends each answer with the notes it keeps. A shelf of copies of our design docs (`study/`) is refreshed before each session. All in `build/scratch/quaestor/gemini/`, text only; it's read-only with no terminal, and research's script files its notes.
- **Research, 2026-11-26, 21:51, the cleanup (the director's go):** closed pieces' entries moved whole to `docs/archive/asset-requests-closed.md` and `docs/archive/test-requests-closed.md`; the live files keep an index line for each (2.4 MB to 0.8 MB, and 0.75 MB to 0.33 MB). An edit to a closed piece goes in its archive entry, or the piece moves back. Unclear, kept live for their owners' word (close or keep): AR41; TR1, TR6, TR7, TR11, TR12, TR14, TR17, TR21, TR23, TR29, TR32, TR35, TR39, TR43, TR48.
- **AGENTS.md, 21:39, "Beyond the vision" and "Gemini"** (the director's yes to research's restatement): a teammate may build beyond the original vision when it's genuinely worth it, with a notice here until the director reviews it. Gemini is a consulted voice, on the subscription's quota only, never an asset maker.
- **Research, 2026-11-26, 00:42, tier 2 (TR64):** the silent big moments get a sound. Ten cues in two rounds, the first session's first (level-up, a shard's drop, the keeper's fall, the lead down); Sonus shortlists, Faber hooks each moment with Play the moment in the panel (about 3 h), and the director's ear picks.
- **The director, 2026-11-25, by 21:32, to research, for Modulo:** Modulo runs on Opus 5.5 now, at xhigh (research's pick, at the director's word: `docs/production-plan.md`, "Models"). Set in `tools/team-terminal.cmd`, Faber's launcher, edited by research at the director's ask.
- **The director, 2026-11-25, 21:28, in Scintilla's session, item 10:** "Yes, Scintilla installs it now", to the restatement: Studio's play tools for Effects and Sound as research has them, and Effects among the uploaders inside the guard's limits. Installed in Faber's hooks at the director's ask: f239fb03, hooks self-test 126 passed. Item 10 can leave "Waiting on the director".
- **The director, 2026-11-24, 21:26, for everyone:** "only modulo will keep working and redesign the voidkin + ui it unreadable for players and ugly we need to study". Tonight only Modulo works: the study, then the redesign's targets (AR62). Everyone else commits and stops.
- **The director, 2026-11-24, 20:50 and 20:52, for everyone: target first, verdicts in pairs** (`AGENTS.md`, "Every action, world, effect and screen" and "One style frame"; `docs/decisions.md`, the top rows):
  - Every piece players see starts with two or three targets at final quality, in the game, in at most 3 h. **Research picks every target** in pairs against the director's examples (the director, 21:13: "it js need to be good"); the director judges results in the game. Until the pick, start your next piece.
  - Checkpoints come at a quarter and at half of a cap, beside the target. A miss changes the technique and is never polished. Moves are posed first, stepped.
  - Research's verdict: the gates, then the build beside its target and the director's examples (`docs/research/examples.md`).
  - **The style frame first** (AR62): Home and Rook in the game's light, with one page of tokens. Modulo makes AR64's hair targets first, then the frames. No other UI or Voidkin piece starts before the frame's pick.
  - UI art is SVG, rendered by headless Chrome (TR63, 3). Faber: TR63's pair sheet and lint.

- Tier 2, research, 2026-11-24, evening, from the cloud: TR62, bringing a friend (`docs/design.md`, "Being seen"; seed "referral"): a friend new to the game who beats the Lamplighter pays both sides a Forge Crate, five friends at most an inviter. Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-24, evening, from the cloud: TR57 to TR60 (`docs/design.md`, "Being seen" and "The welcome week and codes"; seeds "broadcast", "boards", "welcomeWeek", "codes"). Day 7 of the welcome week is Lyric for everyone, since about 13% of Lantern Row's Standard shards hold Lyric and nearly every player owns all five Voidkin by then. Faber and Modulo: say in your row what you'd change.
- The director, 2026-11-24, 11:11, for everyone: overhaul what's clearly better, above all visually and in design, and fix bugs at once (`AGENTS.md`, "Overhaul what's clearly better"; the register's top row). The old kept for rollback; a redo players see is a blockout beside the old, judged by research in the game; the director's own decisions are redone as an alternative shown to the director.
- Tier 2, research, 2026-11-24, 10:55: a fall in the Festival (`docs/design.md`, "A fall in the Festival"): the Arrival pad counts as home for following, and the fall card holds Retry (lit when a lead is ready, dim with the time left), Send another and Home. Faber: say in your row what you'd change.
- Tier 1, Faber, 2026-11-23, AR52: the Dasher runs on through the lead to its line's end, keeps its aim to its action's end (its back to whoever it passed), and is first ready 1.5 s after it spawns, the Guard at once. The shield's grey pane stands at 0.25 transparency. Research: say in your row what you'd change.
- Tier 2, research, 2026-11-23, 20:07, TR53: TR31 folded in. The battery's line shows only a net gain, and reads "Full" with the overflow's Credits when it sold. Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-23, 17:49, AR53: Home gains a **Today** card (today's three goals, Next at the list's head) in Settings' column, Settings a cog tile over it. A run's dares sit under the run's line (no start card); a dare kept before a fall is paid.
- Tier 2, research, 2026-11-23, 14:54, AR52: the Guard and the Dasher join Lantern Row's stretches, with mixed outline types (Green, Orange) so no one lead wins the run; Modulo's masks and clips now, Faber's behaviours after the backlog. Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-23, 14:58, TR53: a return card at the base (what it made while you were away, one tap) and the base's shard shown during a run. Faber: say in your row what you'd change.
- Tier 1, research, 2026-11-23, 14:54, TR52: the signature on a tap, tried as a block with an Auto toggle; launch is the director's call after the verdict.
- Tier 2, research, 2026-11-23, 14:04, AR51: the Condenser gets a convert panel in the Comb's make and its own share on the Power screen (colour, chip, light, a third handle), answering Faber's TR37 notice below. Faber: say in your row what you'd change.
- Tier 2, Faber, 2026-11-23, TR37: the Power screen's bar keeps two handles. The Condenser shares under Auto, and a split never clears its share, but its own handle, light and chip wait for a Power screen piece. Tier 1: the Comb lights by the tray's fill of its cap, from the bottom row up (a full tray lights all 37), and the convert's refusal is its own word ("A convert takes 5 Low stones"). Research: say in your row what you'd change.
