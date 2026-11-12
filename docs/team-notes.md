# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-12: the director's eye on AR3's sheet is in: Graphite Dark is the main theme, and Pearl Light, with a black border, serves some screens (`docs/decisions.md`); the kit's images are unblocked, and Modulo has been told. AR2, the Shade: passed (c53970f). AR4, Pip: sheet and model passed, the clips' poses next. For Faber when the Shade goes in: the mask's own tint, walk speed from the stride, the Lunge's tell from its markers, Attack/AttackLeft and Hit/HitLeft alternating, the Burst's effect from the collar on its marker. Next: TR2's verdict as QA; Pip's poses and his Hit, Down and Up; Haymaker's final in motion.

**Faber (builder).** 2026-11-12: stopped at the director's word, mid-TR2. In and tested: Rook's combo and Haymaker (8bda266), the grey world (b30467d), Lantern Row's packs (d165529), the keeper (407462b), drops (1e108e2), and the plain HUD with the base's interactions as a block (its HUD and Base cases 65/65, logic 1,350; a full self-test run is owed). Pick up from: three fixes from the HUD's first capture (TR2's status line), the full run, the Shade's model (AR2), then the sim and research's verdict evidence. Haymaker's textured bar waits on item 4 below.

**Modulo (assets).** 2026-11-12: stopped on the director's word, relayed by Quaestor; nothing running, no lock held. AR4, Pip: the sheet and the model are in `build/handoff/Pip/`, past the content check and research's reads (`docs/asset-requests.md`, AR4, sections 1 and 2); not uploaded, not in the engine. His eight clips are keyed and their pose sheets rendered, with no review yet (section 3): the export was stopped by the machine running low on memory, so the next step is to run it again, then research's read and the content check. Quaestor: section 3 asks you to rule on Pip's own Hit, Down and Up, against the shared reaction set. AR3: the kit's images wait on the director's look at `build/handoff/UI/ui_sheet.png`. Open on AR2: the burst's light and paper, with Faber, and the elite's second mask. AR1, delivery 4: I join Haymaker's replay when Faber says. The director, 2026-11-12: units, clips, effects and textures are made without waiting for the director's answer, and reworks are named after testing.

**Turns.** Studio: nobody. Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 0.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For TR2 (Faber), when you're next in Studio:

4. **Share Haymaker's picture with the game.** The picture went up under your own account, not the group's, so the game is refused it ("Requester does not have permission for Asset", image 139742668928839). Either Play Solo in the main place and click "Click to share access" in the Output window, or open the image on the Creator Dashboard, then Permissions, and add universe 9093907961.
5. **Max Players 8** in Game Settings: one player for each of the eight plots.
6. **Save the main place** (Ctrl+S), so `AuthorityMode` Automatic and Rook's clips stay in it. Or say the word and I add `save_place` to the tool guard.
7. **Research's play tools** in `.claude/hooks/config/tools.json` (research's row): your word, and I add them.

### Notices

- Tier 2, research, 2026-11-11: the changes from the package (`docs/decisions.md`, "What changed from the package"). Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-12: the world's layout for TR2 (`docs/design.md`, "The world, in grey"). Faber: say in your row what you'd change before you build the world.
- Tier 2, research, 2026-11-12: states in a fight (`docs/design.md`, "States in a fight"): poise, stagger, heavy stagger, stun, knockdown, one effect per element. Built with the Lamplighter as a real fight, after TR2. Faber and Modulo: say in your row what you'd change.
- Research, 2026-11-11: every number in `tools/balance/seeds.json` is a seed. Simulated, not played.
- Tier 1, Faber, 2026-11-12: Server Authority is off, and the place runs `AuthorityMode` Automatic (`docs/engineering-plan.md`, "The builder's calls"). Modulo: by the handbook, a clip registered from a `KeyframeSequence` plays in a playtest under Automatic, unpublished (`handbook/art/animation.md`).
- Tier 2, Faber, 2026-11-12, for research: whose a pack is, and the street's length following the pack spacing (`docs/test-requests.md`, TR2, "The builder's read").
- Faber, for research, 2026-11-12: the director's words on the data system and purchases mid-TR2, for the register (`docs/engineering-plan.md`, "The builder's calls", the save layer).
- Tier 1, Faber, 2026-11-12: the keeper is fought in a copy of the ring for each plot, and code lays the grey world from Config (same place).
- Tier 2, Faber, 2026-11-12, for research: the builder's seeds (the Breaker's free floor, the battery, away, Named and starter shards, copies past seven), in `docs/test-requests.md`, TR2.
- Faber, for research, 2026-11-12: the director's word that the player's avatar is R6 only, for the register; and the handbook's lessons from the kit's first run here. Both are in TR1's entry.

## Entries

### 2026-11-12. The Shade: the model and nine clips delivered (Modulo)

- **What:** one body on R6 (five pieces, 2,444 triangles) and four masks, on one atlas for the five types; nine clips: Idle, Walk, Attack, AttackLeft, Guard, Lunge, Hit, HitLeft, Burst.
- **Where:** `build/handoff/Shade/` and its `clips/`, made by `tools/blender/shade_model.py` and `tools/blender/shade_clips.py`. The record: `docs/asset-requests.md`, AR2.
- **For Faber:** "For the builder" in AR2's section 3, and the content check's engine checks in sections 2 and 3.
- **Open:** the burst's light and paper, an effect built with the builder; the elite's second mask. Nothing is uploaded or seen in the engine.

### 2026-11-12. Day one: the repo, the kit, the calls (Faber)

- **What:** the repo joined to GitHub and pushed. The kit is in `src/`: remotes, live numbers, presets, the debug bridge, the self-test, the logic tests. Both guards are installed. The starter is trimmed to one role, and three calls are made: ProfileStore kept under our own save layer, Server Authority off, pure rules run with Studio closed under Lune.
- **Where:** `docs/test-requests.md`, TR1; `docs/engineering-plan.md`, "The builder's calls"; `tools/checks/`.
- **Tested:** the self-test 11 of 11, the logic tests 29 of 29 in Studio and offline, the type check `0 new`, the hooks' self-test 126 of 126.
- **Open:** the place waits for a save to keep `AuthorityMode` Automatic. The next piece is TR2.
- **For:** everyone who runs a check: the commands are in `.claude/skills/ga-studio-test/SKILL.md`.

### 2026-11-11. The design, the balance model and the start of production (research)

- **What:** the director's package of 2026-11-11 read whole and turned into the game's own pages. Eighteen open decisions answered. Balance rebuilt so nothing compounds, and tested by a simulation (`py tools/balance/sim.py`). Thirty-one Voidkin, the Shades and six grounds authored. The HUD's direction. The first requests: TR1, TR2, AR1 to AR5.
- **Where:** `docs/`; `tools/balance/`. The package itself is in `docs/archive/package-v13/` (kept out of git: it's large, and partly superseded). The directive of 2026-11-09 is in `docs/archive/`.
- **The folder** is now `C:\Users\gloce\GrowyourAnime`, with `origin` set. The kit was refreshed from the studio's corrected templates.
- **Tested:** the simulation only. Nothing is built, nothing is played, nothing is drawn.
- **Open:** the local history and the remote's first commit aren't joined, so nothing is pushed yet (TR1's first step). The ids aren't checked. The handbook clone here is behind.
- **For:** everyone. Start at `docs/north-star.md`, then your row.
