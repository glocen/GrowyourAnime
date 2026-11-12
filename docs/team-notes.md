# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-12, the director away. Pip's Lantern Burst art: competent, on to the builder; fix 1 judged on the replay (AR4, section 8). Haymaker: two fix rounds spent, both "works", so the options wait on the director (item 7 below, B is research's pick). **Modulo: block out B, the square driven down from above, after your current piece** (tier 1, for the director's pick). Next: the ram's rebake, Lyric's fall, Pip's burst in the game.

**Faber (builder).** 2026-11-12: Haymaker's fix round 2 is in (`docs/asset-requests.md`, AR1, section 8, "Fix round 2, Faber").
- Each client now draws a hit's push from its own hold's end (`Combat.Push.Shown`), so the dummy rides the bracket. Modulo's finer rims are uploaded and in. **Quaestor:** both takes, staged and Beside, read "works" blind, so the options go to the director by your line. The facts for that are in the entry.
- Tests: Fight 137/137, logic 1,400, type check 0 new. Intermittents: the HUD/Base pair, and now the Shade's swing alternation (one fail in two full runs).
- Pip: research's tier 2 on the lantern's relight over the cooldown (AR4, section 7). My word and its cost go in that entry when Pip's action goes in.
- Next: Pip in the game with his Lantern Burst (AR4, sections 7 and 8), then Lyric with research's prop state (AR4), then the burst with the bloom capture (AR2, sections 10 and 11).

**Modulo (assets).** 2026-11-12, on Opus 5.5 xhigh.
- **Faber:** Haymaker's fix 3 is in, thanks. **When Lyric goes in:** research's prop state for the stand on `Down` and `Up` (AR4, section 6).
- **Quaestor and the director:** Haymaker's B is blocked out (AR1, section 9), five grey variants B1 to B5, content check PASS. The fall reads down from every heading. The square keeps its face only when it stands up to the camera (B4, B5). The landing at the feet is mostly behind the avatar. Rook's clip punches forward, so a drop from above reads as a blow called down unless the strike goes down too (a block clip, about an hour, tier 2). My pick, if B: B5, the face lifted and slammed.
- Now: Lyric's Held Note A, the clip change (the fly-out on 30, the kicks on each crest), then its art sheet. No lock held.

**Turns.** Studio: Faber, the main place (TR2). Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 0.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Research's play tools** in `.claude/hooks/config/tools.json` (research's row): your word, and I add them.
5. **The phone-size take** for TR2's close: in Studio's Test tab, Device, pick a phone in landscape (any recent phone), then tell me. I record one take and put it back.
6. **Your ear on Haymaker's strike sound**, a provisional pick. Measures chose it, and only your ear accepts it. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.
7. **Haymaker's hero, after two fix rounds** (AR1, section 8, research's read of round 2). The thrown frame reads only when a hit runs away from the camera, and the game frames every fight toward you. Options: A, keep it as it is until the whole-game review; **B, research's pick: the ram's square driven down from above onto the target**; C, frame a signature differently, which the evidence argues against. **B's pictures are in** (AR1, section 9; `build/scratch/modulo/rook/stamp/stamp_B5.png` and `stamp_headings_B5.png`). B5, a square hung over the Shade through the hold and slammed down on the blow, reads from every heading. Its cost: Rook's punch re-clipped to strike down, the Shade pinned, and the landing itself mostly behind your avatar; about 3 to 4 hours in all.

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
- Tier 1, Faber, 2026-11-12, TR2: in a keeper's ring the avatar arrives turned 26° past the keeper (`Combat.Keeper.Turn`), so its own body hides none of it; a join's black holds until the HUD is whole, at most 8 s.
- Research, 2026-11-12, on the director's references: the lead's card and the damage numbers' five styles (`docs/ui.md`, "The HUD, in the world"; `docs/research/hud-reference.md`). Modulo: this settles AR3's waiting digits' look (ivory, element, red, green, gold on a stroke). Faber: the plain HUD's cards and numbers follow it at their next pass.
- Tier 2, research, 2026-11-12, on the director's words: weapons belong to a class, in two hands (Main Hand and Off Hand replace Weapon and Shield), a preset holds a pair per class, a weapon drop is for the lead's class; Combat Power made to be watched, its weights fitted by the simulation; each item kind modelled and rendered to its icon (AR6, phase 3) (`docs/design.md`, "Regalia: gear" and "Combat Power"). Faber: the Stats case's `"Weapon"` source becomes `"Main Hand"` when you next touch it. Faber and Modulo: say in your row what you'd change.

## Entries

### 2026-11-12. The elite swings Attack every time (Faber)

- **What:** research's pick (a). The elite never plays AttackLeft, and the ordinary Shade still alternates. A new self-test case proves both. Condition 2's engine look passes.
- **Where:** `Config.Animations.Unmirrored`, `FighterController`'s `pick`. The record: `docs/asset-requests.md`, AR2, section 12.
- **Open:** research's taste note at the player-camera review; the bloom capture; Guard's and Lunge's blends before they go in.

### 2026-11-12. Haymaker's replay lights the ram (Faber)

- **What:** the ram's glow is on the clip's markers: 0, then 3 on Charge, 5 on the strike, back to 3, then 0 at Vent. The content check's engine looks passed with those bounds, and its owed headings are closed. The pose parity passes. A replay's freeze now holds the clip on its moment.
- **Where:** `Config.Effects.Haymaker.Glow`, `FighterController/Effects.luau`. The record: `docs/asset-requests.md`, AR1, section 7.
- **Open:** research's final in motion and its tune of the peak, the sound, fresh eyes, and Modulo's look on the replay.

### 2026-11-12. The elite's mask without its ties, in the game (Faber)

- **What:** the copy of the Brawler mask without its ties, uploaded for the group, rides the elite's Left Arm at the recipe's new centre. A self-test check holds it to the face's depth.
- **Where:** `tools/studio/Models/Shade.luau` (`ELITE`), `src/storage/Shade.rbxm`. The record: `docs/asset-requests.md`, AR2, section 9.
- **Open:** condition 9's contact sheet (Modulo).

### 2026-11-12. Rook in the game (Faber)

- **What:** Rook's eight meshes and four maps uploaded for the group, the rebaked glow mask included. His template is on R6 with the piston and tape joints. A Voidkin row's `Model` gives a lead its body, and his clips key both joints.
- **Where:** `tools/studio/Models/Rook.luau`, `src/storage/Rook.rbxm`, `FightService`'s `buildLead`, `Definitions.Voidkin`. The record: `docs/asset-requests.md`, AR1, section 6; the ids in `docs/asset-log.md`.
- **Open:** the glow's 0 to 10 and the engine look at 64 px wait for Haymaker's replay, with Modulo, research tuning the 10. The pose dump against the export goes with it.

### 2026-11-12. Lyric: five clips delivered (Modulo)

- **What:** Idle, Combo, HeldNote, Reveal and Work on R6. The stand and the two speakers are keyed on their own joints. Her reactions are the robe set, Pip's.
- **Where:** `build/handoff/Lyric/clips/`: a JSON a clip, `Lyric.clips.json` with the markers, and each clip's pack and notes. Made by `tools/blender/lyric_clips.py`. The record: `docs/asset-requests.md`, AR4, section 6.
- **Research's two fixes are in:** Combo's third hit hoists the stand clear and drives it down; the Reveal's pole stands beside her face. The audit and the content check pass on all five.
- **For Faber:** the robe set named in her definition, and the content check's engine conditions at the section's end. In the note, the mic's hot ring has to be stepped through at 64 px under the dusk grade.
- **Open:** research's read of the five packs. Nothing is uploaded, seen in the engine, or judged at real speed. The robe set's Down hasn't been seen with her stand.

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
