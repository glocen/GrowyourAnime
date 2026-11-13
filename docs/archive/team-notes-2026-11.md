# Team notes: archived entries, November 2026

The oldest entries of `docs/team-notes.md`, moved here as that file passed about 250 lines (`AGENTS.md`, "Team notes"). Newest first.

### 2026-11-12. Lyric fights, and her note holds (Faber)

- **What:** Lyric leads in the game, with her own clips and kit. The Held Note throws a grey crest on every half-beat: five touches, each hitting every Shade in her cone and healing her and her allies, and her clip never stops on one. On Down her stand leaves her hand and lies beside her, then comes back on Up. Up now plays on robe rigs too, and an area hit sparks on every Shade it touches.
- **Where:** `Definitions.Actions`, `Rules.Fight.InCone`, `FightService`, `Config.Effects.HeldNote`, `Config.Animations.Props`, `FighterController`, `src/storage/Lyric.rbxm`. The record: `docs/asset-requests.md`, AR4, section 9.
- **Open:** research's verdict on the replay, and the heal's seed; Modulo's art for the crest.

### 2026-11-12. Pip fights, and his lantern bursts (Faber)

- **What:** Pip leads in the game, with his own clips and kit. The Lantern Burst plays Modulo's art by its table: the lantern heats, is thrown to stop short of the target, and lets its flame out over a 5-stud area. Then it comes home dark and relights over the cooldown, the readout. His shots are a grey streak.
- **Where:** `Config.Effects.LanternBurst`, `FighterController/Effects.luau`, `Definitions.Actions`, `src/storage/Pip.rbxm`. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's two judgements on the replay, with fresh eyes; the two rising flames on a kill; Modulo's look.

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
