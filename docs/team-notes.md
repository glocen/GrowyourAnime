# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-12: AR3's kit images: competent, the frames exceptional; four palettes accepted, five fixes for Modulo (AR3, research's verdict). Regalia on the director's words: class weapons in two hands, the five pairs final, Combat Power's moment, the gear icons' study (`docs/research/gear-icons.md`; notice below). TR2's verdict: the loop holds in grey; five fixes, the framing first (TR2, research's verdict), with the director's notes: bigger plots apart, a wider Lantern Row, the Festival Door; the Condenser makes stones away. Next: Haymaker's final in motion; Lyric's sheet when Modulo delivers; TR2's next take.

**Faber (builder).** 2026-11-12: TR2, research's five fixes are in, each tried in a take; self-test 263/263 at 60 fps, logic 1,370. Quaestor: the take of the fixes is in `build/captures/tr2/pack.md` (its second part) with sheets 6 to 12, and TR2's status line says what each did. Yours there: the framing now runs along the avatar's facing (from its place, the fight sat at the frame's edge); Pack 2 still downs Rook once, from Pack 1's damage carried in, and a faster heal out of a fight cleared it in a live try (tier 2, yours). The plot's door lands 4 studs before the gate, out of Pack 1's reach. Next: TR2's closing takes (the Lamplighter's fall, a rejoin, phone size), then `/ga-finish`.

**Modulo (assets).** 2026-11-12: Lyric's sheet is drawn and in `build/handoff/Lyric/lyric_sheet.png` (`docs/asset-requests.md`, AR4, section 4): made, self-reviewed, delivered; not read by research, not accepted. Quaestor: the feel line there is proposed, yours to sign or change, then the read; and the content check passed her look but blocks her signature's name in the roster, so the rename is yours (the reason is in my message, the conditions in section 4). Her model waits on both. Still with Faber from AR2's section 4: the Shade's two maps uploaded together with the recipe's two strengths; Rook's ram has the same fault, sized in AR1's section 5: say when. Now, while the read is out: the elite's second mask (AR2). Open after it: the burst's light and paper, with Faber. AR1, delivery 4: I join Haymaker's replay when Faber says. Nothing running, no lock held.

**Turns.** Studio: Faber, the main place (TR2). Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 0.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Research's play tools** in `.claude/hooks/config/tools.json` (research's row): your word, and I add them.

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
- Faber, for research, 2026-11-12: the director's word that the group's Open Cloud key covers this game's uploads, for the register (`docs/test-requests.md`, TR2's status line). The builder uploads through `tools/upload/upload_asset.py`, from `build/upload/`, after the content check, as before.
- Tier 1, Faber, 2026-11-12: ShadeSwipe follows the Shade's Attack clip: 1.1 s with its hit at 0.5 (it was 1.3 s, the strike at 0.55), damage a second held (`Shared.Definitions.Actions`).
- Tier 2, Faber, for research, 2026-11-12: a crowd on the move earns more than half again a lone player's kills, from two players when the leads stay on each Shade (x1.65 at two, x3.2 at eight), and the 15 s wait bounds only a parked crowd. It's a model on one measurement; the table and the levers are in `docs/test-requests.md`, TR2, "A crowd against a lone player".
- Faber, for Modulo, 2026-11-12, AR2: Roblox multiplies a SurfaceAppearance's glow by its colour map ([the emissive masks' announcement](https://devforum.roblox.com/t/studio-beta-emissive-masks/4034414), and seen in the engine). The Shade's atlas paints the lit edges and the masks' cuts in the coat's dark purple, so at strength 2 the type's colour barely shows, and at 25 it reads magenta. Yours: a light colour under the glow (white, or the paper on the masks), then I upload the map again. Also: the clips' `Name` lacks the `Shade` prefix that `Author.SaveBaked` checks (I renamed my import copies), and they carry no fades (mine are in `Config.Animations`).
- Tier 2, research, 2026-11-12: reactions on R6 come in two shared sets, open legs and robe; Pip's Hit, Down and Up are the robe set (`docs/design.md`, "States in a fight"). Faber and Modulo: say in your row what you'd change.
- The director, 2026-11-12, on TR2's grey world: plots much farther apart and much bigger, Lantern Row a bit wider, "overall im quite happy with the progression made and going on, kudos to everyone". The world's notes come through research's TR2 verdict; nobody changes the layout before it (`docs/decisions.md`).
- Faber, for research, 2026-11-12: the director's word that the builder saves the main place itself until launch ("you can save the game yourself whenever you want for now until it launch"), for the register. `save_place` has its Builder line in `.claude/hooks/config/tools.json`; the place is saved (version 113), the clips in it kept.
- Tier 1, Faber, 2026-11-12, TR2: the Festival Door stands 34 studs right of the Breaker, level with it; its twin inside Lantern Row's gate on the east stall front; a plot's door lands 4 studs before the gate, out of the lead's leash of Pack 1. The battery shows its tenth below 100, so it visibly counts up. An engaged lead's spot follows the avatar's facing (fix 1).
- Research, 2026-11-12, on the director's references: the lead's card and the damage numbers' five styles (`docs/ui.md`, "The HUD, in the world"; `docs/research/hud-reference.md`). Modulo: this settles AR3's waiting digits' look (ivory, element, red, green, gold on a stroke). Faber: the plain HUD's cards and numbers follow it at their next pass.
- Tier 2, research, 2026-11-12, on the director's words: weapons belong to a class, in two hands (Main Hand and Off Hand replace Weapon and Shield), a preset holds a pair per class, a weapon drop is for the lead's class; Combat Power made to be watched, its weights fitted by the simulation; each item kind modelled and rendered to its icon (AR6, phase 3) (`docs/design.md`, "Regalia: gear" and "Combat Power"). Faber: the Stats case's `"Weapon"` source becomes `"Main Hand"` when you next touch it. Faber and Modulo: say in your row what you'd change.

## Entries

### 2026-11-12. The UI kit's images delivered (Modulo)

- **What:** the kit as slices (panel, button, bar, thread), the six frames in two cuts, the five type gems, five class marks, four element marks, the coin, the bolt and the spark. A slice is white where a palette colours it, so a palette is a row of colours, never new images.
- **Where:** `build/handoff/UI/kit/` (`images/`, `kit.json`, the review sheets), made by `tools/blender/ui_kit.py`. The record: `docs/asset-requests.md`, AR3, section 2.
- **The director, 2026-11-12:** which screens are Pearl and which get a palette of their own is Modulo's to choose, so long as the whole holds together. The choice: Graphite for the field and the collection, Dynamo for the Breaker and the bays, Void Violet for the reveal's card, Pearl for what's read like a page.
- **For Faber:** "For the builder" in that section: the layer order is the script's `panel`, `button`, `bar` and `frame`; the palettes' rows are in `kit.json`.
- **Open:** nothing on the images: research's verdict came (competent, the frames exceptional) and its five fixes are in, past the content check (AR3, section 2, "The fix round"). Nothing is uploaded or in the engine.

### 2026-11-12. Pip: eight clips delivered (Modulo)

- **What:** Idle, Combo, LanternBurst, Hit, Down, Up, Reveal and Work on R6, with the hat and the lantern keyed on their own joints. Hit, Down and Up are the robe reaction set.
- **Where:** `build/handoff/Pip/clips/` (a JSON a clip, `Pip.clips.json` with the markers and the 12-stud flight, each clip's pack and notes), made by `tools/blender/pip_clips.py`. The record: `docs/asset-requests.md`, AR4, section 3.
- **Changed on the way:** no hand ever goes to the hat, the send's kick throws his whole body, and Down falls backwards with the hat over his face.
- **For Faber:** the ten engine checks at the section's end, and "For the builder" above them: the blend over Idle, the fall from the game's own camera, the dump against the export.
- **Open:** nothing is uploaded, seen in the engine, or judged at real speed.

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
