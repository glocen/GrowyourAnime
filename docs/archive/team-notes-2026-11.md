# Team notes: archived entries, November 2026

The oldest entries of `docs/team-notes.md`, moved here as that file passed about 250 lines (`AGENTS.md`, "Team notes"). Newest first.

### 2026-11-15, night. The dock's images delivered (Modulo)

- **What:** AR12's dock as three icons, in images for the build: the body, a tile's white layers in two sizes (the tile, its pressed twin, the sheen, the open rim, the open halo), one light and its glow, the three marks in ink, the pip. Research's two mark fixes are in.
- **Where:** `build/handoff/UI/hud/dock/` (`images/`, `hud_dock.json`, `hud_dock_images.png`, and `hud_dock.png` rendered again), from `tools/blender/hud_dock_sheet.py`. The record: AR12, "The dock's images, delivered".
- **Checked:** the stack of images matches the block's drawing (the numbers are in the record); content check PASS for delivery and upload; self-reviewed at phone size over both streets.
- **Open:** research's read of the two marks at 32 px; Faber's build; the upload.
- **For:** Faber, research.

### 2026-11-15, evening. TR17's retake and TR9's fade fix (Faber)

- **What changed.** The Voidkin screen has research's three fixes: the stage never stands empty on a switch, the Voidkin's name is over the stage, and the lead reads "Leading" with "Not while leading" under Send to work. Its top bar is in Roblox's band, a new `Band` layer any full screen can use (`Kit/Screen.luau`). The Breaker's chamber holds its next shard's words until the gold is gone, and the infusion's levels are Low voltage and High voltage.
- **A finding worth keeping:** a model fetched with `PreloadAsync` still draws empty for up to half a second the first time a viewport shows it. Drawing it ahead in a small viewport is what makes it ready (`VoidkinScreen/Figure.luau`, the wings).
- **Where it lives.** `docs/test-requests.md`, TR17, "The retake", and TR9, "The fade fix and the names". Evidence: `build/captures/tr17/retake*.jpg`, `build/captures/tr9/gold_fade_still.jpg`.
- **Then, the same evening:** the bag's five tabs stand whole (research's one fix on the retake), and the Breaker's pane has "Drop rates" one tap away, from a pure rule whose rows add to exactly 100% (`Rules.Odds.Rates`).
- **Open.** Research's pass on TR17's block and on Drop rates. The rail scrolls on phones under 366 pt tall. Voltage as time isn't built: it goes with TR18.
- **For:** research.

### 2026-11-14. Kirra's clips delivered (Modulo)

- **What:** AR10, delivery 3:
  - the clips: Idle, Combo (opening on its dash), Scarf Step, Reveal and Work;
  - three tail layers over the open set's Hit, Down and Up.

  Each draw is a reach straight up and back to the grip. The tail's links bend at most 22° each, and Work runs nine short steps a lap round its post.
- **Where:** `build/handoff/Kirra/clips/`, made by `tools/blender/kirra_clips.py`. The recipe in `build/handoff/Kirra/` now has each blade on a Torso joint. The record: AR10, section 4.
- **Checked:** the audit and the content check pass on all eight. Research's verdict: competent, no fix. The in-engine look at phone size comes at the install.
- **For Faber:** section 4's "For Faber, at the install": the kit's names, Work's post and its 6 studs, and the blend and dump at install. `models_offline --recipe Kirra` builds the recipe.
- **Time:** about 1 hour 40 for the clips, against Pip's 6 hours.

### 2026-11-13. The keeper's Signature re-delivered, option 1 (Modulo)

- **What:** the lantern is held high and out to the keeper's right through the hold, clear of the hat from every heading, then tipped over the top and slammed down beside your fighter. The timing and the markers stay.
- **Where:** `build/handoff/Lamplighter/clips/Lamplighter_Signature.json` with its pack, made by `tools/blender/lamplighter_clips.py`. The record: AR7 section 7, "Option 1 delivered".
- **Checked:** the ring is positive on every frame, and the content check passes. Its four conditions bind AR8's effect build.
- **For Faber:** re-save `NL_LamplighterSignature`. The camera's lift through the hold is the motion blockout's lever.

### 2026-11-13. AR8's kit delivered: the effects' meshes and textures (Modulo)

- **What:**
  - 21 meshes: two coils and each in six burn bands, a shell, a hoop with an upright band, a crescent, a column, three chips.
  - 19 images: strand, rise and rib ramps in four palettes for `MeshPart.TextureID`, opaque in their own colours; and, white for Beams and particles, a beam, tongues, a streak, a spark, embers, a glow and a flame.
- **Where:** `build/handoff/FxKit/`, with the recipe `fx_kit.json`, made by `tools/blender/fx_kit.py`. The record: AR8, "The kit".
- **Checked:** the content check passes all of it, the flame on its redraw. Its conditions on embers and flame are in the recipe. The self-review is at 64 px on both floors.
- **For Faber:** one upload batch under the group, then the player. Open there: whether a MeshPart showing its texture draws unlit.

### 2026-11-13. AR7 installed: the Lamplighter fights in its own rig, and its lantern goes out (Faber)

- **What:** the keeper wears Modulo's model and eight clips, at 1.5 scale.
  - It holds its Challenge as it spawns and fights in its Ready.
  - It walks at 5, research's tier 2. The time to first contact was measured, and 5 stays.
  - It falls into the Shade's burst with its pole and lit lantern left standing. The lantern gutters, goes out and goes to paper.
- **Where:**
  - the model: `tools/studio/Models/Lamplighter.luau`, which builds `src/storage/Lamplighter.rbxm`;
  - the rows: `Definitions/Enemies` (Rig, Enter) and `Definitions/Actions` (KeeperChallenge);
  - the numbers: `Config.Effects.Falls` and `Config.Combat.Keeper` (WalkSpeed, FadeSeconds);
  - the code: `Effects.LanternOut`, `FightService`'s `buildRig`, and `FightDefeat` on the bridge.
  The record: AR7, section 5.
- **Checked:** type check 0 new; logic 2432, offline and in Studio; the keeper's case 24/24 at 60 fps, under the phone emulator. The desktop suite is 849/851: the two misses are HUD cases outside this piece, fixed next.
- **For research:** the verdict in motion on `build/captures/ar7/`, with three things I see: Pip in front of the Challenge, the keeper at the frame's top, and a faint "Out".

### 2026-11-13. AR8 B5's replay: Haymaker slams a square and pins (Faber)

- **What:** Modulo's block clip plays in RookHaymaker's place. B5's grey square forms over the target through the hold, falls stretched, lands on Strike at its feet and squashes on Shock as two floor bars run out. It lies where it landed. Haymaker's strike pushes nothing (the pin, tier 2, signed). A's bracket returns with `Stamp.On` false.
- **Tier 1:** the hang's top is 6.4, not the scope's 8, because at 8 the square leaves a phone's frame.
- **Where:** `Effects.Haymaker`, `Config.Effects.Haymaker.Stamp`, `Definitions/Actions` (RookHaymaker), `stage_clips.py --source`. The record: AR8, "B5", "The replay built".
- **Checked:** type check 0 new; logic 2408; the new stamp case 18/18; the suite's timing cases pass at 60 fps.
- **For research:** the verdict in motion on `build/captures/ar8/b5/`, A beside B5.

### 2026-11-13. AR8 C's fixes, and B1 and B2 installed (Faber)

- **What:** the level-up's "Level N" now stands clear over the lead's head, white edged in the thread's blue. It slides aside, eased, from a pill or a toast it would cross. The toasts sit under the Electricity pill, inside the safe area. The column wears Modulo's picture, white at its peak and blue as it fades. Lantern Burst plays the coil, and Held Note the bold crest, veil and touch.
- **Found:** on a notched phone, world plates stood off their points toward the sides, because the viewport is the safe width and the layer is full-bleed. `UI/World` now maps through the top bar's inset from the layer's corner.
- **Where:** `UI/World`, `UI/Kit/Toast`, `UI/Layers`, `HudController`, `FighterController/Effects`, `Config.Effects`, `Config.Hud`. Ids are in `docs/asset-log.md`, rows 39 to 43. The record: AR8, "C's fixes, and B1 and B2 installed".
- **Checked:** the whole self-test, 793/793 at 60 fps; logic 2407.
- **For research:** one pass on `build/captures/ar8/c_b1_b2/` closes C, B1 and B2. Condition 4 and part 5 read there.

### 2026-11-13. AR8 C built: the interface (Faber)

- **What changed:** a press squeezes and springs back; a screen fades and grows in, and leaves in 0.8 of that, eased in; a toast slides in from the right edge. Credits and Electricity pop with a rising "+N" that counts, experience glints along the thread, and a level swells its badge. The level-up is a column of the thread's blue standing past the lead's head, sized by the lead, with a fainter sleeve over the body. A number grows with its hit's rung, and a hit of rung 7 or more sends the lower numbers aside.
- **Where:** `UI/Kit/` (Button, Screen, Toast, the new Pop), `HudController`, `FighterController/Effects`, `Rules.Hud`, `Config.Hud`, `Config.Effects.LevelUp`. The record: AR8, "C. The interface".
- **A lesson for the handbook:** a `Beam` takes its transparency only at its segments' joints, so with one segment a soft foot or a fade along it never shows.
- **Open:** research's pass in motion at phone size. The toasts past the phone's right edge and over the Electricity pill, at the next pass on the toasts.

### 2026-11-13. AR8 B1 and B2 delivered: Lantern Burst's coil and Held Note made bolder (Modulo)

- **What:** Lantern Burst's flame, let out. Three fat ribbons wind in round the Shades to one column and flare white on 70. Then they let go and climb off as a thread, gone by 93. Two small forked flames stay where the outer feet let go. Held Note's crest, veil and crackles are rimmed in a deep magenta, and the crest's strands are about two and a half times as thick, so the wave holds on a bright sky.
- **Where:** `build/handoff/Pip/fx/pip_burst.png`, with `pip_burst_art.json` and `pip_burst_art.png`; `build/handoff/Lyric/fx/`, the three pictures and `lyric_note_upload.png`. The scripts: `tools/blender/pip_burst_coil_art.py` and `lyric_note_art.py`. The record: AR8, "B1, the art sheet" and "B2".
- **Checked:** the content check passes on both, and research's pass on the sheets is competent.
- **For Faber:** one re-upload for the burst, with the same layout; `Config.Effects.LanternBurst.Burst` plays it as drawn, and the trail is unchanged. Three re-uploads for Held Note, with the crest and the veil turned a quarter as before. The asset log names the old id each retires. In your take, check the coil's foot leaving the Shade's head at 74 to 78 (condition 4), and whether the wind reads.
- **Open:** Faber's uploads and take, then research's pass in motion.

### 2026-11-13. AR8 A built: the hit by its rung (Faber)

- **What:** every hit holds, flashes and shakes by its rung. An ordinary blow is a 0.045 s flick of white. A signature is a 0.13 s held instant: the body flashed white and trembling, the camera rolled through it. The camera shake is trauma squared, from the player's own lead only. Haymaker's bars and the billboards of Lantern Burst and Held Note no longer draw a frame late.
- **Where:** the numbers are in `Config.Combat.Hitstop` and `Shake`, the rules in `Rules.Fight`, the screen's side in `FighterController`. The level check is `tools/studio/Audio/Loudness` and `Mixdown`. The record: AR8, "A. The hit".
- **Done:** logic 2368, the whole self-test 697/697 at 60 fps. Takes are in `build/captures/ar8/`, each beside its "before".
- **For research:** the pass in motion. The level check reads Legendary and Mythical 6 LU over the fight's loudest, Common to Epic level with it, and every true peak under −1.
- **Open:** research's pass. Then C, the interface.

### 2026-11-13. The Lamplighter's clips delivered (Modulo)

- **What:** the keeper's seven clips: Idle, Challenge, Ready, Walk, Swing, Hit and Signature. The lantern swings as a weight on its cord. The signature plants the pole and leans it out like a street lamp, its face comes up, then it wrenches the lantern high over its hat and slams it down by your fighter.
- **Where:** `build/handoff/Lamplighter/clips/`, made by `tools/blender/lamplighter_clips.py`. The record: AR7, section 4.
- **Checked:** the audit passes on all seven, and the content check passes. Research read them as competent, and says the raised wrench meets its fix.
- **For Faber:** the roles in `Config/Animations`, `Strides.LamplighterWalk` 4.94, and the keeper's walk near 5 (research's tier 2 yes; your take checks it). **Open:** not uploaded, and not in the engine. The fall is next for the keeper, after AR8's B.

### 2026-11-13. TR4 built: the reveal's ceremony in the engine (Faber)

- **What:** Modulo's reveal at every rarity, with research's sound cues, from the break's yes to the card. The skip lands on the held frame with the stamp.
- **Where:** the stage is `src/client/UI/Reveal`, the rules `Rules.Reveal` and `Rules.Sound`, the numbers `Config.Reveal`, `Config.RevealArt` and `Config.Sounds`. The record: `docs/test-requests.md`, TR4, "Built".
- **Done:** self-test 688/688, logic 2249, the world report sound, the place saved (256). The sounds are logged in `docs/asset-log.md`.
- **For everyone:** a new Sound waited about 0.3 s to load, so every sound came late, the fight's too. A bank of loaded Sounds fixes it (`FighterController/Sounds`).
- **Open:** research's verdict in motion, then its pass. The sounds stay provisional until the director's ear.

### 2026-11-13. TR3 closed: the HUD on the kit, both cards in Midnight (Faber)

- **What:** the HUD in the world on the kit, with the lead card at the director's picks (Midnight, the Ember bars, Builder Sans, the head over the frame) and the target's card built like it. Both levels are in gold.
- **Where:** the art is `tools/blender/lead_card_art.py`, which writes `build/handoff/UI/hud/lead_card/`. The config is `UIKit.LeadCard` and `UIKit.TargetCard`, written by `tools/ui/kit_config.py`. The code is `src/client/UI/LeadCard.luau` and `TargetCard.luau`, used by `HudController`. The record: TR3.
- **Done:** 32 uploads, Approved and the group's. Self-test 618/618, logic 1735/1735. Research's pass given, no fix left.
- **Open:** the director checks the HUD later, not as a gate (the director, 2026-11-13: "my approval is not required").

### 2026-11-13. The kit's three frames tinted (Modulo)

- **What:** Uncommon green, Rare blue, Epic purple on the kit's frames, the director's colours on the same shapes, so the uploaded ladder matches the reveal's. 14 of the kit's 89 images; the rest and `kit.json` are unchanged.
- **Where:** `build/handoff/UI/kit/images/`, made by `tools/blender/ui_kit.py`; the colours live in `ui_sheet.RARITIES`. The record: AR3, section 6.
- **For Faber:** upload the 14, then run `kit_config.py` with their ids. **Open:** not uploaded.

### 2026-11-13. The reveal's art sheet and engine parts delivered (Modulo)

- **What:** the reveal's art, past research's pass at competent: the six fixes, then three more. Its engine parts too: 28 images, the shard's 8 meshes, and `reveal.json`, the whole reveal written as rules. Rook's Reveal re-keyed, his head up out of the fold, with a `Name` marker.
- **Where:** `build/handoff/Reveal/parts/` and `art/`, and `build/handoff/Rook/clips/`, made by `tools/blender/reveal_art.py` and `rook_clips.py`. The record: `docs/asset-requests.md`, AR3, section 5.
- **Checked:** content check PASS. Laid from the files alone, the engine's frame sits within 0.6 to 2.3 (sRGB) of the art, except at the leak's peak: 6.0 at Legendary and 9.3 at Mythical, where UI can't add light.
- **For Faber:** the reveal TR, to `reveal.json`'s order. Rook's Reveal is new, so take your saved copy again. **Open:** not in the engine, nothing uploaded.

### 2026-11-13. The reveal's block-in delivered (Modulo)

- **What:** the Void Shard's one form for three grades, its four seams and four sizes; the reveal's beats for a Common and a Legendary, as strips and movies at phone size on Void Violet; the six rarities' read before the name; the larger frame's cut; layouts A and B, B picked.
- **Where:** `build/handoff/Reveal/`, made by `tools/blender/reveal_blockin.py`. The record: `docs/asset-requests.md`, AR3, section 4, "Delivered".
- **Times:** a Common splits at 0.55 s, its name at 1.57, its card at 2.15; a Legendary at 1.30, 2.32 and 3.40. The skip is open from 1.0 s on every rarity.
- **The director's word:** Uncommon green, Rare blue, Epic purple, used in the block-in; its costs to the kit are in the record.
- **For Quaestor:** the verdict and the register. **Open:** grey and stand-ins; nothing is in the engine. Made on Opus 5.5, from the shard's reshape on (Fable 5.2 before).

### 2026-11-13. Lantern Row's kit delivered, with its night (Modulo)

- **What:** the festival kit's 16 pieces as meshes on one colour and one glow atlas, ink in each mesh; the paving as lit modules and the square's floor, their pools painted; the paper's flipbook; a dusk sky and a night sky, six faces each; the Lighting numbers for both; the street's dressing plan (271 placements, 9 lights); the phone budget.
- **Where:** `build/handoff/LanternRow/` (`meshes/`, `maps/`, `sky/`, `manifest.json`, `plan.json`, three sheets), made by `tools/blender/lantern_row_kit.py`. The record: `docs/asset-requests.md`, AR5, section 2, "Delivered".
- **Measured in renders:** the lead 1.44 to 1.65 times what's round him, a Shade's edge 0.154 to 0.170, at dusk and at night, from both ends. The most within 220 studs: 196 pieces, 91,308 triangles, 8 lights.
- **For Quaestor:** the verdict, and three calls (the houses, the square's canopy, StallB's roof). **For Faber:** "For the builder" in the entry, after that verdict.
- **Open:** nothing is uploaded, installed or seen in the engine. A Shade's edge passes by a hair, and the engine's light decides it.

### 2026-11-12. The HUD's portraits and the critical's sweep delivered (Modulo)

- **What:** Rook's, Pip's and Lyric's portraits, cut to their rarity frame's mask in the full cut and the lead's card's; one silhouette for a Voidkin not yet made, in all six rarities; the critical number's sweep, a grey slice of speed lines the game tints amber.
- **Where:** `build/handoff/UI/hud/` (`images/`, `hud_art.json`, the sheet), made by `tools/blender/hud_art.py`. The record: `docs/asset-requests.md`, AR3, section 3.
- **For Faber:** "For the builder" in that section: Back, portrait, frame on one canvas; the sweep's place, size and tint.
- **Open:** research's verdict. Nothing is uploaded, in the engine, or seen moving.

### 2026-11-12. One number a body, on the crest (Faber)

- **What:** a flurry, one press's hits on one body, shows one number that counts up, for every action, and heals the same. The Held Note's number, hold and push on a body wait for its crest to reach it.
- **Where:** `Effects.Number`, `Effects.Running.Struck`, `FighterController` (`show`, `onHit`, `onHeal`), `Config.Combat.Numbers` (`Count`, `Pop`), with a new self-test case and checks added to the Held Note's two. The record: `docs/asset-requests.md`, AR4, section 10.
- **Open:** research's read of the take, then fix 3 (the width), research's own.

### 2026-11-12. Lyric's note in its art (Faber)

- **What:** the Held Note plays Modulo's art sheet. Each crest is a braid over a veil on an arc across the cone, and the rings flash on the Note. A struck body takes the crackle when the crest reaches it, in place of the spark, and a heal rises as a ring round the healed body.
- **Where:** `FighterController/Effects.luau` (`HeldNote`, `HealRing`), `Config.Effects.HeldNote`, with a self-test case. The three pictures are the group's uploads (`docs/asset-log.md`). The record: `docs/asset-requests.md`, AR4, section 10.
- **Open:** research's verdict on the take; then the rings' hot strength and the dusk check.

### 2026-11-12. A hit lands on its frame (Faber)

- **What:** a fighter struck mid-action no longer holds its clip on screen. A server hit that arrives before the screen reaches its beat moves the clip on to the beat first. Pip's burst now kills on its flame, where before the kill came 0.3 s ahead of it.
- **Where:** `Fight.CatchTo` and `FighterController` (`show`, `catchUp`), each with a case. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's verdict on the take.

### 2026-11-12. Pip's round 2 in the game (Faber)

- **What:** Modulo's round 2 of the Lantern Burst plays in the game: Pip is rocked back a step, and the flame stands up. Research's take of the burst killing two Shades shows two lanterns rising out of his flame.
- **Where:** the clip in the saved place (v188), and the picture's new upload in `Config.Effects.LanternBurst.Picture`. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's verdict on round 2. The kill shows 0.3 s before the flame (a hold mid-action, held on the client only), with two fixes proposed in the same section.

### 2026-11-12. The Shade bursts into light and paper (Faber)

- **What:** a fallen Shade's collar charges, then flares the coat's size on its Burst marker as the body goes out. A flame climbs, its paper rising after it, from Modulo's art by its table, untinted. The content check's capture closes its red item: nothing red after the hide, on dark and bright, ordinary and elite. A burst no longer stays in the world when its body leaves first or its clip stalls.
- **Where:** `Config.ShadeBurstArt` (from `tools/art/art_table.py`), `Config.Effects.ShadeBurst`, `FighterController/Effects.luau`. The record: `docs/asset-requests.md`, AR2, section 13.
- **Open:** research's pass. Pip's and Rook's billboards are drawn a picture late (`docs/polish-later.md`).

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
