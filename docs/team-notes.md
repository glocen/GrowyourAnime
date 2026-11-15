# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-14, night.
- **The director's words, in the register:** the Voidkin screen remade (TR17, three grey layouts, `docs/research/voidkin-screen.md`); the stat board removed, the skill tree later; the base as a power plant (TR18, after TR17; `docs/design.md`, "Power"); the HUD's colour (AR12, Modulo now, for the director's pick).
- **Verdicts given:** TR8 (competent, paper fix landed), TR9 (Machine picked, works), TR12 (works), TR16 (the chip works, a trail fix); AR11 Watt's sheet (competent, take A, one fix for the model).
- **Next:** TR18's numbers in the sim; TR17's takes and verdict, then the director's pick; AR12's sheet; the retakes of TR16 and TR9's Machine.

**Faber (builder).** 2026-11-15.
- **TR17, the Voidkin screen:** rebuilt full screen to the director's layout, with the notes on the mock: the seven-page rail, the bag, Overview with the stat sheet, Lead and Send to work in the top bar, spaced slots. Its case passes (217 checks) and its take (21). **For research:** the take is in `build/captures/tr17/`, and ten findings from the build are in its status.
- **The whole self-test is clean:** 1660 passed, 0 failed, in the phone emulation. **TR9's retake is recorded** (`build/captures/tr9/`), for research's verdict.
- **Next:** AR12's colour into the HUD (V2, Block, from `hud_colour.json`), with the lead card's halos and the portrait's seam fix. The director, 2026-11-15, to Faber: "We need to add the colors by the way, modulo cooked with the colors let make this game more vivid once we can". Then TR12's and TR16's fixes; the TR10, TR13 and TR11 takes; Kirra's install; TR18.

**Modulo (assets).** 2026-11-15, on Fable 5.2.
- **AR12, the HUD's and the screens' colour:** the HUD's images in V2, Block are delivered: `build/handoff/UI/hud/colour/images/` (30 images), `hud_colour.json` (how each piece stacks, each system's colours, the rooms) and `hud_colour_images.png` (AR12, "The HUD's images in V2, Block"). Content check PASS; not uploaded. **For Faber:** the readout's light is one image under a gradient, its stops in the json, untried in Studio. `vivid_voidkin.png` is the look to hold beside TR17's rebuild. **Now:** delivery 3's sheet, the Breaker and the bays in Dynamo vivid, before and after.
- **AR10, Kirra:** delivered and accepted through the clips. **Scarf Step's look:** the grey rows are in `build/handoff/Kirra/fx/KirraScarfStep.rows.json`; its blockout in the replay goes first, when Faber gives the turn (AR10, section 5).
- **AR11, Watt:** the sheet is past the content check and research's verdict (competent, take A, one fix for the model).
- **Next:** delivery 3's verdict, then its images; Scarf Step's blockout; Watt's model, with the shirt fix; then TR10's two icons. Nothing running, no lock held.

**Turns.** Studio: the main place is Faber's, in Edit, the phone emulation on (AR12's HUD is reviewed at phone size next). Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 11. TR2, the circuit in grey (phase 1); Haymaker, on A; the Shade's burst; Pip's Lantern Burst; Lyric's Held Note; TR3, the HUD in the world; TR4, the reveal; AR7, the Lamplighter installed with his fall; his signature; Lantern Burst's exit in 3D (B1); Haymaker's square in 3D (B5). Hours are in each piece's entry.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

6. **Your ear on Haymaker's strike sound**, a provisional pick, now heard on its frame. Before TR4's fix it came about 0.3 s late. Measures chose it, and only your ear accepts it. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.

### Notices

- Tier 1, Faber, 2026-11-14, TR16: a fallen card's two chips share one place under it, and only one shows. "Send another" now shows only when another Voidkin could go out at once: a Voidkin at work can't lead, so it used to show a button that sent no one. The trail keeps 4 studs in from the stall fronts and is gone within 6 studs of the door.
- Tier 1, Faber, 2026-11-14, Kirra's install: First Strike crits her first hit to land on a target, past the critical's cap. A dodged swing hasn't landed, and a Shade that walked home is fought anew. No cue of its own: the critical's number.
- Tier 1, Faber, 2026-11-14, TR9: a screen opened again, as its owner rebuilds it, keeps its panel and refills its body in place, so the Base and Breaker screens no longer replay their entrance on each change. The Breaker's prompt opens the oldest ready shard as before, else the Breaker's own screen.
- Tier 1, Faber, 2026-11-14, TR8: the ground's look holds from 24 studs short of the festival gate, so a door's landing opens in it, and the place keeps its own Lighting elsewhere. The stalls, signs and houses collide by their box and the posts by their mesh. The gates collide by the grey street's own parts. The street's floor wears the paving tile under the bays, and the lead carries the plan's tenth light at its head, in the ground only.
- Tier 2, Modulo, 2026-11-14: Scarf Step lands to the side of the Shade, about 35° off the line from the player's camera, so its line shows 9.8 of its 10 studs on the screen instead of folding to a streak (AR10, section 1). Research and Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-13: the effects kit grows, from the vault (`docs/research/vfx-reference.md`, "What the vault teaches, beside ours"): a stack of layers per beat, a dark twin under each bright layer, our own 4x4 and 8x8 sheets with outline and fill passes, the emitter row with Drag, Squash, Acceleration, EmitCount and EmitDelay, a screen row and a caster light from rung 4 and 7; the full look, with a "performance mode" setting to lower it (the director, 2026-11-13). The kit now; effects that passed, at the finish pass. Faber and Modulo: after your current piece, say in your row what you'd change.
- Tier 1, Modulo, 2026-11-13: the Lamplighter's wrench is one-handed. The arm goes straight up beside its hat, and the lantern rises high over it. The blocking's two-handed wrench left the ring's frame and grazed the brim (AR7, section 4).
- Tier 2, research, 2026-11-13: a ranged lead keeps its distance (`docs/design.md`, "Combat"), from the director's question. Built in "Rook, Pip and Lyric installed". Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-13: the passives' seeds (Second Wind, Kindle, Tempo), in TR7, part 3. Faber: say in your row what you'd change.
- Faber, for research, 2026-11-12: the director's word in the builder's session, "add your play tools for quaestor". Research now has the play tools in the tool guard, as QA does: `start_stop_play`, `execute_luau` and the inputs (`.claude/hooks/config/tools.json`). Research's brief keeps it to playtests and captures, never an edit, in a turn on this board.
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
