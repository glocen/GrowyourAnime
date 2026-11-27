# AR7. The Lamplighter, Lantern Row's keeper

For Modulo, now (research's request, 2026-11-13). Phase 2's keeper is the first boss a player meets and the last beat of the first session (`docs/production-plan.md`, phase 2). It's a signature piece, so it gets the time it needs, named here: a sheet first, explored fast, judged beside a Voidkin.

**Feel line:** at the street's end a tall festival-goer the Void has filled turns from its great lantern and lifts its pole, and you know it's the ground's master before it moves.

**The rig: the Shade's** (AR2), as the roster has it: "a Shade in full festival dress with one signature of its own" (`docs/roster.md`, "Enemies"). It uses the same R6 rig and clip family, so the Shade's reactions, and later the states' cues, fit it as they are. It stands taller by scale: TR2's grey keeper is 7.4 studs (`Definitions/Enemies.luau`). A body of its own isn't asked. If the Shade's rig, scaled, can't carry the dress, say so with the lever you tried and the options.

**Delivers,** each shown before the next:
1. **The sheet:** the keeper's dress over the Shade's empty coat. A lamplighter's long coat, a hat or hood, its own keeper's mask (not one of the four), and a long pole with a hook and a lantern. It has Intelligence's outline, and the lantern burns in Lantern Row's cyan and warm white. Up to three directions, cheap, with your pick and what's wrong in each. It must read at 64 px, and at a third of the ring's frame beside a Voidkin (TR2's keeper framing).
2. **The model** on the Shade's rig, scaled, with the lantern as a part the clips and the signature can light.
3. **The clips:** the Shade's family checked at its scale, the Challenge (the held pose as a try starts, TR2), and the signature's wind-up and strike as a block clip.
4. **Its fall:** the Shade's burst into light and paper at keeper size, with the lantern's light going out last. No wounds, nothing left behind (`AGENTS.md`, rule 4).

**Its signature, a seed** (tier 2: research and the builder; built through `/ga-action` in the Lamplighter's fight, after Lantern Row is dressed). It plants the pole, and the lantern swings up and lights a cyan circle on the ground under the lead. Then the lantern slams down on it as a heavy hit. The wind-up is long enough to read on a phone. A heavy stagger landed during it breaks the signature ("States in a fight": "a signature being wound up is broken"), so Haymaker has an answer to it. The sheet only needs the pose and the prop. The numbers and the name come with the action.

**Checks:** the content check (rules 3 and 4); research's verdict with fresh eyes at the sheet and at the block clip. **Time it:** hours, here. **Waits:** the states' cues, the sounds and the keeper's phases on its card, all in the fight's TR.

**Status:** in progress (Modulo, 2026-11-13, on Opus 5.5 xhigh). **Time named at the start:** about 13 hours over the four deliveries: the sheet 3, the model 4, the clips 4, the fall 2. It's a signature piece, so the time is a forecast, not a cap; each delivery records what it took. Delivery 1, the sheet, is past the content check and research's verdict (competent, A at 1.5) and **delivered** to `build/handoff/Lamplighter/` (section 1). Delivery 2, the model, is past the content check and research's verdict (competent) and **delivered** to `build/handoff/Lamplighter/` (section 2). Delivery 3, the clips: blocked (section 3), timed with research's two fixes, the wrench raised on research's read, past the content check and research's look, and **delivered** to `build/handoff/Lamplighter/clips/` (section 4). Delivery 4, the fall: its block clip played in the replay at competent (section 5); the final clip, its rock let go, is past the content check and **delivered** to `build/handoff/Lamplighter/clips/` (section 8).

### 1. The sheet (Modulo, 2026-11-13)

- **Where:** `build/scratch/modulo/lamplighter/sheet/lamplighter_sheet.png`, 1920 by 1640, with a half-size copy beside it. It's delivered to `build/handoff/Lamplighter/` on research's yes. `tools/blender/lamplighter_sheet.py` draws it in headless Blender in about a minute: `-- <out dir> [small]`. It's a Workbench blockout over the Shade's own builder, with the glow drawn on the picture. Rook is his baked model in Eevee.
- **The rig carries the dress.** The Shade's R6 at 1.5 times its size (the elite is 1.35), with no body of its own. The lever is to dress over the Shade's coat, not to swap it:
  - A long bell coat from the hem at 0.62 to the shoulders, with the Shade's lit hem and seam on the outside.
  - Wide oversleeves from 2.3 down, the Shade's lit cuff showing below them.
  - The pole runs through the right cuff, so an arm's clip carries it.
- **The three directions,** each on the sheet from the front, as the ring's camera sees it, and in outline:
  - **A, the Bearer (my pick):** a straw cone hat over a lantern-faced paper mask with closed eyes. The indigo coat has cream bands and a red sash, and a lantern crest is on the back. The pole is planted upright, and the lantern hangs from its crook beside the face.
    - What's wrong: from above, the brim hides the mask's brow (the ring's camera sees it level, so both eyes show). A staff and a cone hat could read as a generic mage, so the lantern and the festival coat have to carry it.
  - **B, the Warden:** a peaked hood round a crescent mask, with the pole over the shoulder and the lantern behind the head.
    - What's wrong: a hood and a long pole over the shoulder is a scythe-bearer's outline, so it reads as death, not as the festival's master. The lantern hides behind the head from the player's camera.
  - **C, the Crier:** a tall lacquer cap over a lattice mask, with the pole held out and the lantern hung in front.
    - What's wrong: the lantern hangs between the keeper and the player and covers the mask and the coat. Held out level, the pole reads as a fishing rod, not as a weapon it can bring down.
- **Why A:**
  - The planted pole is the signature's own start, so the stance already says what it will do.
  - The cone hat is an outline no Shade has.
  - The lantern hangs at the mask's height, so lamp and face read as one. The face is a lantern too: the street's master wears the street.
- **The signature's pose** is on the sheet as a seed: the pole planted ahead, the lantern swung up over the head, and a cyan circle under the lead. Its cuffs show end-on as lit squares, which the clip fixes by the arm's roll.
- **At 64 px** the three outlines are different on night, day and paper, beside an ordinary Shade at the same scale. A's hat and lantern carry it.
- **In the ring, beside Rook,** at TR2's framing, measured from TR2's capture: zoom 10, pitch 10, FOV 70.

  | Direction | Size (studs) | Body share of the ring's frame | With the pole |
  |---|---|---|---|
  | A | 10.4 × 5.2 × 12.4 tall to the pole's top | 43% | 60% |
  | B | – | 45% | 51% |
  | C | – | 49% | 60% |

- **For research and the builder, the scale:**
  - The request's "a third of the ring's frame" and a keeper taller than the elite don't fit together.
  - A third would be about 1.16 times a Shade, under the elite's 1.35: about 8.2 studs to the hat's top, against an elite's 7.4 to 9 to its mask's top. At 1.5 the hat's top is at 10.5.
  - I'd keep 1.5 and let the keeper's framing pull the camera out, because a keeper shorter than an elite fails the feel line. The number is the builder's (`Definitions/Enemies.luau`).
- **Content check, 2026-11-13: PASS.** Rules 2, 3 and 4 and Roblox's, the names against `docs/ip-list.md`. Two notes carried to the model and the fall:
  - A's thin red hat cords run down beside the pale mask. The model ties them under the chin, in rope or cream.
  - The fall bursts into light and paper with no red pieces, the sash's included.
- **Time:** about 25 minutes by the clock (Quaestor's message at 10:57 UTC, the sheet past the check at 11:20), against the 3 hours named. On Opus 5.5 xhigh.
- **Four facts:** made; self-reviewed; content check PASS; research's verdict below; **delivered** 2026-11-13 to `build/handoff/Lamplighter/lamplighter_sheet.png`, byte for byte the sheet checked.

**Research's verdict, 2026-11-13,** on the sheet, with `ga-fresh-eyes` blind beside it (its pick A, its Tier competent, its bold thing the same as research's). **Felt:** A is the one you'd know across the ring. The wide straw brim and the lit lantern hung at the mask's height read as one crown of light, the brightest point in the ring's frame, and it still reads at 64 px. B's hood is a reaper's from the player's camera, and C's lantern covers its own body. But A stands square, with its arms out, a patient keeper more than a master about to strike. **Tier:** competent. **The one bold thing:** the lantern beside the face, the face itself a lantern: the street's master wears the street. **A is picked,** and so is 1.5. The request's "a third of the frame" was TR2's grey box, not a target, and a keeper shorter than its elite fails the feel line. The ring's framing is the builder's call. A lower camera that looks up at it would serve "tall" better than a wider one. Fixes, for the model and the clips:

1. **It stands like the master:** in its idle and its Challenge, its weight leans on the planted pole, its shoulders are up, and its head drops under the brim, then lifts as a try starts. Serves "you know it's the ground's master before it moves".
2. **Checked beside each starter:** the model in the ring beside Pip, Lyric and Rook. Pip's robe and A's indigo coat must read apart in value. Serves the keeper's read beside your own fighter.

The content check's two notes stand (the cords tied under the chin, and no red pieces in the fall). **Next:** delivery to `build/handoff/Lamplighter/`, then the model.

### 2. The model on the Shade's rig (Modulo, 2026-11-13)

- **Where:** `build/scratch/modulo/lamplighter/model/`. It's delivered to `build/handoff/Lamplighter/` on research's yes. It holds:
  - `lamplighter_model_sheet.png` (1920 by 1700, with a half-size copy) and `lamplighter_atlas_check.png`.
  - The four maps, the eight meshes as JSON, `Lamplighter.recipe.json`, and `lamplighter_model.blend` for the clips.
  - `tools/blender/lamplighter_model.py` makes it all in headless Blender in about 2 minutes: `-- <out dir>`. With `--stance` it draws the pose in clay, without the bake.
- **What it is:** the Shade's R6 body as AR2 built it, with its own coat taken off, under A the Bearer's dress: the long coat, the oversleeves, the lantern-faced mask and the sedge hat.
  - Eight pieces, 6,104 triangles. The six R6 parts: the Head carries the mask, the hat and its cords. Two more pieces turn on Motor6Ds of their own: the pole on the Right Arm, and the lantern on the pole.
  - One 1024 px atlas at 60 px a stud: colour with the contact shading baked in, roughness, metalness (the brass), and one glow mask read three ways.
    - The body glows in Intelligence's violet at the Shade's 32.
    - The mask's paper and cuts glow in its warm white at 12.
    - The lantern's paper glows whole under a white tint: 1.2 as it stands, 3.0 through the signature.
  - The coat's folds, the hat's plaited straw, the lantern's ribs and the pole's grain are drawn into the colour map.
- **Fix 1, it stands like the master:**
  - **The idle:** leaned 9° forward over the planted pole, turned 8° to it and tipped 6° onto it. The right sleeve goes down and out to the pole, as onto a staff, and the left is held back. The head is bowed 22° under the brim.
  - **The Challenge:** the head lifts to 4° up as a try starts.
  - Both are on the sheet from the ring's camera, and close on the face.
  - **Built in the stance:** the pole and the lantern are built where the stance holds them, so the idle never keys their joints. The Shade's shared clips don't carry the pole: delivery 3 adds a hold on the right arm, or keeper clips.
  - **The arm:** a first try held the arm out level. The ring's camera then saw the sleeve's open end as a dark square beside the face. Angled down, the end sits at the waist with the pole through it.
- **Fix 2, beside each starter:** in the ring at dusk, at TR2's framing, beside Pip, Lyric and Rook, with the keeper's head lifted.
  - The coat went from the kit's indigo (#2C2A64, 0.18 coded, in Pip's band) down to #161436 (0.09).
  - Measured in the frames, the keeper's torso (median) against each starter:

  | Beside | The keeper's torso | The starter | Share in the dark band (under 0.15) |
  |---|---|---|---|
  | Pip | 0.12 | 0.19 | 54% against 23% |
  | Lyric | 0.12 | 0.31 | 54% against 7% |
  | Rook | 0.12 | 0.20 | 54% against 36% |

  - A first step (#1E1C4A) read 0.14 against Pip's 0.19, both mostly dark, so I went one step further.
  - In the grey crops on the sheet, Pip's robe is a mid grey against the coat's near-black. The torso's median includes the cream bands and the lit hem, so the coat alone is darker still.
- **The content check's note is carried:** the hat's cords are rope (#8A7150). They run down beside the mask and tie in a knot under its chin, with two short tails.
- **Measured:**
  - **Clearances:** the pole stands 0.50 off the brim, and the lantern 0.88 off it and 0.18 off its pole. From the ring's camera the lantern is 88 px clear of the mask.
  - **Height:** in the stance, the hat's top is at 6.89 studs (10.3 at 1.5), and the pole's top at 7.7 (11.6).
  - **Stride:** a leg swings 27° each way inside the long coat's hem. The Shade's walk swings 30° forward, so the keeper's takes 25° (in the recipe).
  - **Glow:** 24 texels of the body's glow stop short at 1, none of them visible.
- **For the builder,** once it's delivered:
  - **The recipe:** each piece's R6 part, the two motors' pivots, the four SurfaceAppearances' tints and strengths, and six points (the lantern's middle, the hook's tip, the pole's foot, the grip, the chest and the crest).
  - **The rest pose with no clip:** the pole runs from behind the right heel up through the grip, forward and out. So a clip must play before the keeper is seen.
  - **The lantern:** CastShadow is off. A cyan PointLight in it is your call.
- **For research, the camera:**
  - The ring's camera sees the keeper's face from a touch below. So the bowed head shows the brim over the brow, not over the eyes.
  - The "lower" view on the sheet looks up 10°, as your thought for "tall" would. From there the bow reads less still.
  - The head's drop reads best from level or above. A lower camera trades some of fix 1's beat for height.
- **Content check, 2026-11-13: PASS.** It covered the sheet, the atlas check, all four maps and the recipe, against rules 2, 3 and 4 and Roblox's rules, with the names checked against `docs/ip-list.md`. The hat-cord note is met.
  - Two conditions stay open: the fall and the signature have no red pieces, and each map and mesh gets its line in `docs/asset-log.md` before upload (at delivery).
- **Time:** about 35 minutes by the clock (11:37 to 12:11 UTC), against the 4 hours named. On Opus 5.5 xhigh.
- **Four facts:** made; self-reviewed; content check PASS; research's verdict below; **delivered** 2026-11-13 to `build/handoff/Lamplighter/`, byte for byte what was checked: `Lamplighter.recipe.json`, the four `Lamplighter_<Map>.png`, the eight `Lamplighter_<Piece>.json` and `lamplighter_model_sheet.png`. Its row is in `docs/asset-log.md`. Not uploaded, not in the engine.
- **Faber, to build it:** the recipe holds every piece's part, pivot and glow, and the "For the builder" lines above. The pole needs a clip before the keeper is seen, and the clips come next (delivery 3). The ring's camera stays as it is (research's verdict below).

**Research's verdict, 2026-11-13,** on the model sheet and the atlas check. **Felt:** from the ring's camera it towers over each starter. The lantern burns cyan above the straw brim, the head is bowed under it, and the dark coat with its lit lilac seams says Shade before anything else does. When the head lifts as a try starts, it has the authority the sheet's A lacked. **Tier:** competent. **The one bold thing:** the lantern and the brim, a crown of light, now with a bowed head under it. Both fixes are met. It leans on the pole, its shoulders are up, and the head drops and lifts. Beside Pip, Lyric and Rook, the coat reads darker than each (0.12 against 0.19 to 0.31), so they never merge. **The camera: keep the ring's as it is.** At 1.5 it already looks tall beside the starters, and the bow and lift is the beat that says "master". Research's thought of a lower camera is withdrawn, and the builder is told. Yes, deliver. **Next:** the clips (the Shade's family at its scale, the Challenge, the signature's block clip), with the fall and the signature carrying no red pieces.

### 3. The clips: the blocking (Modulo, 2026-11-13)

- **Where:** `build/scratch/modulo/lamplighter/clips/`:
  - `lamplighter_blocking.png`: every clip's key poses from the fight's camera, a row a clip.
  - `poses_<Clip>.png`: each clip's key poses from the fight's camera and from its left side.
  - `family/lamplighter_family.png`: the Shade's own clips on the keeper.
  - `tools/blender/lamplighter_clips.py` draws them in Workbench in about a minute: `-- <out dir> [poses|family] [clip ...]`. The performance lines are in it, one a clip, written before the poses.
- **The fight's camera:** behind your fighter, at 20° round from the keeper's front and 2° up, from a touch below the mask (TR2's zoom 10 and pitch 10 at 1.5). Stage units are the Shade's; the game's are 1.5 times them. Your fighter stands at KeeperSwing's Range, 6 studs (4.0 here), read from `Definitions/Actions.luau`.
- **How the props move,** three tracks a clip:
  - **The body:** keyed as the Shade's are (`rook_clips.py`), the legs re-solved on every frame.
  - **The pole:** its joint is at the grip, so its line always passes through the right cuff. Planted, its foot stays on its floor place and the pole slides through the grip. Held, it's leant toward a heading. The two blend by direction, never by the foot's place.
  - **The lantern:** hung from the hook's tip on its cord, swung off plumb by keys. Where it would go through the floor, it lies on it instead.
- **The Shade's family, checked at keeper scale.** None of the Shade's five clips can play on the keeper. Each lays the pole through the coat, and the lantern stands stiff on its cord:

  | The Shade's clip | The pole's lowest point | Its nearest to the body | The lantern off plumb | A leg's widest (the coat holds 27°) |
  |---|---|---|---|---|
  | Idle | −0.10 | −0.10 | 49° | 16° |
  | Walk | 0.17 | −0.10 | 67° | 30° |
  | Attack | −0.68 | −0.10 | 75° | 14° |
  | Hit | −0.44 | −0.10 | 80° | 42° |
  | Burst | −0.47 | −0.07 | 100° | 39° |

  So the keeper takes its own set: Idle, Walk, Hit and, at delivery 4, its Down. **Faber:** `Config/Animations` gets a Lamplighter rig set; the Shade's isn't used for it.
- **The clips,** blocked as key poses (frames at 60 fps):
  - **Idle,** a 240-frame loop. Hung on the planted pole, the head bowed 31° in all (the model's bow), a breath, and once a loop the head sinks under the brim and catches itself.
  - **Challenge,** 92 frames. 0 it waits; 18 it hears you; **44 Lift**, it looks at you; **58 Stamp**, the pole lifted a hand and stamped; 92 it looks at your fighter, in Ready.
    - **Why at you:** at 1.5, looking at your fighter is 22° down, so a lift to it moved the head only a few degrees, and the first blocking didn't read. Lifted to the player's camera, the head comes up 29° and the hat goes flat.
  - **Ready,** a 180-frame loop: squared to your fighter, still on the pole, the head up.
  - **Walk,** a 64-frame loop. The legs swing 25°. The pole goes ahead and is planted with the left foot. It covers 3.51 a loop (4.94 studs a second at 1.5); the game's walk speed times it in phase B.
  - **Swing,** KeeperSwing's 96 frames: Strike 48 and Recover 60, from its Beats in `Definitions/Actions.luau`.
    - **The lever:** anticipation, the lean back, as the action names. It draws the pole's foot back past its hip like a lance, then sweeps it round and across at your fighter's chest. The pole turns over in its hand, the lantern flung up behind its shoulder, and it plants the pole again.
    - **Why the pole's foot, not the crook:** a crook-first flat sweep, blocked first, put the lantern into the camera, onto the floor (0.18) and through the head. Now the crook and the lantern stay high: the lantern's foot is 0.92 up at its lowest. The lantern's weight stays the signature's.
  - **Hit,** 30 frames. Rocked back a little, the head lifted under the brim; then onto the pole as the lantern swings. The feet never move.
  - **Signature, the block clip,** 178 frames: the lamppost.
    - **The beats:** 24 **Plant**, the pole planted ahead and out to its right. 44 **Light**, the pole leant 20° out over your fighter, one-handed, like a street lamp: the lantern hangs at (0.52, 4.32), over your fighter at (0, 4.0), its foot 3.85 up. It holds to 96. 106, it wrenches the pole up with both hands, the lantern over its own head. 114 **Slam**: it brings the pole down like a hammer, and the lantern lands at (0.32, 4.64), on the circle, lying there to 152. 178 Ready.
    - **Plant to Slam** is 1.5 s; the action sets the real numbers.
    - **Why the lamppost:** the seed says "the lantern swings up and lights a cyan circle on the ground under the lead". Read as the lantern standing over its hook, it fails: a lantern on a cord can't stand up there through a wind-up. As a street lamp leant over your fighter, the circle is the lantern's own light, and the keeper of a street of lanterns becomes one.
- **For research, the read from the fight's camera:** the lamppost's lantern hangs over your fighter, so from behind your fighter it sits in front of the keeper's chest. From the side it reads as a street lamp. I'd keep it: the light comes over you, and the circle is at your fighter's feet. Your call.
- **Known, for phase B:** the breakdowns, arcs and the lantern's swing as a pendulum. Four grazes in transitions:
  - the Swing's recovery against the coat (−0.07 at 67) and the right leg (−0.03 at 32);
  - the Signature's wrench against the coat (−0.10 at 98) and the hat (−0.09 at 110).
- **Time:** about 30 minutes by the clock, from the model's delivery (12:16 UTC) to the blocking (12:46), against the 4 hours named for the clips. On Opus 5.5.
- **Four facts:** blocked; self-reviewed from the fight's camera and its left side, with the numbers above. The content check comes with the export. Research's read of the poses comes before any timing work. Not delivered.

**Research's read of the blocking, 2026-11-13,** from `lamplighter_blocking.png`, `poses_Signature.png` and the family sheet. **Felt:** a tired night watchman who nods under its brim, hears you, lifts its face straight to you and stamps. Then, in the fight, it walks on its pole, sweeps low with the pole's foot, and on its signature leans its lantern out over your fighter, wrenches it overhead and hammers it down. **Tier:** competent as blocking. The signature isn't exceptional yet, and fix 1 is the gap. **The one bold thing:** the wrench at 106, the lantern lifted above its own hat. It's the tallest shape the keeper makes, and it's the beat players will learn to fear. **The three calls:**
- The lamppost is kept. From behind your fighter, the lantern in front of the chest is the tell: the light comes over you, and the eye has one thing to watch.
- The Swing goes foot first. The lantern's weight stays the signature's.
- The Challenge looks at the player's camera. Being looked at is what makes it a master before it moves.

The keeper's own Idle, Walk and Hit, rather than the Shade's family, are its call and right. The doze-and-catch is the Idle's personality: keep it. **Fixes:**
1. **The hold is a still.** 44 and 96 are nearly the same pose, so the 0.87 s hold reads dead. Give it a second key that grows: the weight sinks into the pole, the head comes up under the brim toward your fighter, and the lantern settles and steadies. The wind-up should look like it's building, not waiting. That serves the signature's tell and its bar.
2. **A short hang at the wrench's top,** about 4 frames, in timing, so the overhead lantern registers at phone size before the 8-frame slam. That serves the bold thing.

Then time it. The signature goes to `ga-fresh-eyes` beside research's read at its motion blockout with Faber (`/ga-action`).

### 4. The clips: timed (Modulo, 2026-11-13)

- **Where:** `build/scratch/modulo/lamplighter/clips/export/`. It holds:
  - the seven `Lamplighter_<Clip>.json` and `Lamplighter.clips.json` (lengths, loops, markers, the walk's stride);
  - a review pack a clip (`pack_<Clip>.png`, with its notes and audit in `.txt`);
  - the arcs, one dot a frame for the grip, the pole's foot and the lantern (`arcs_<Clip>.png`);
  - the bare rig stepped through (`bare_<Clip>.png`).
  - `tools/blender/lamplighter_clips.py -- <out dir> export` makes them in about 2 minutes. Its `audit` mode runs alone in 30 seconds.
- **The lantern is a weight on its cord now,** not keyed: the game's gravity, a 1.61 cord (a 0.70 s swing), a little drag, and the floor. Keys only pull it toward a swing. It's caught at 100° off plumb, so it never goes over the top. A clip that isn't a loop ends with it hanging plumb, and a loop closes its seam.
- **Fix 1, the hold grows** (`poses_Signature.png`, 44 to 96, from the fight's camera):
  - 44: it leans the pole out, head bowed 28° under the brim.
  - 70: its weight sinks onto the pole.
  - 96: the head comes up, and the face comes out under a level brim. The lantern settles from 60 to 96.
  - **Why the blocking's hold was a still:** your fighter's face is 2.4 below the keeper's eyes at 4.0 off. So "looks at you" bowed the head 31°, deeper than the plant's own bow. The 96 now looks over your fighter's head, toward the camera behind it.
  - **The lamppost moved** so the face shows: the pole's foot is at (1.95, 0.95), leant 22° at −38°. The lantern hangs over your fighter's shoulder, beside the keeper's face, where the blocking's covered it.
- **Fix 2, the hang:** 106 **Wrench**, 110 the top held 4 frames, 118 **Slam** 8 frames later.
  - **The wrench is one-handed** (tier 1). The pole comes up upright beside the hat on its right, the lantern up beside it, and the left arm is flung out against it.
  - Why: the blocking's overhead wrench took the lantern out of the ring's frame and the pole through the brim (−0.09). An R6 left arm can't reach the pole out there.
- **The slam:** the pole comes down level, the hand slid up it to 4.6, and the lantern lands on the floor at (−0.65, 4.48), by your fighter at (0, 4.0). It stays down to about 153.
  - Why level, not head down: the drum hangs 2.92 below the hook, so with the pole's head on the floor the lantern went 0.56 through it.
- **The signature's numbers:** 183 frames, 3.03 s. Markers: Plant 24, Light 44, Wrench 106, Slam 118. Plant to Slam is 1.57 s, the window a heavy stagger can break. The action sets the real numbers.
- **The Swing's turn-over:** the pole now turns over upright at its right side (a key at 33). The foot passes down beside the leg, and the lantern up and out to the right. Before, the lantern went through the head (−1.00 at 34). At the Strike the lantern is flung wide (7.3 to its right, at its 100° catch) and comes back by Recover: its weight shown, for your read at speed.
- **The Walk is the blocking's 64 frames,** as research called it right. It covers 5.27 studs a loop, 4.94 a second at rate 1 (`Stride` in `clips.json`).
  - **For Faber and research (tier 2):** the keeper chases at the Shade's `WalkSpeed` 12 (`Config/Combat.luau`). That plays the walk at 2.43, 4.6 steps a second: a scurry, not a master.
  - A first try timed the loop to 12 studs a second (28 frames). The lantern flailed to 134°.
  - My proposal: a keeper's own walk speed near 5, the clip at rate 1.
- **The rest:**
  - Idle: 240 frames, Catch 188, the lantern still (1° at its widest).
  - Challenge: 92 frames, Lift 44, Stamp 58. The stamp kicks the lantern.
  - Ready: 180 frames.
  - Hit: 30 frames. The blow swings the lantern 52°.
  - The Challenge goes from Wait into Ready. The Swing, the Hit and the Signature start and end on Ready. The loops close their seams (0°).
- **Checks, my own:**
  - r6parity's audit: **PASS on all seven**, at the export.
  - The signature at its closest: an arm in the body 0.043 (limit 0.05); salute held 0 s; a nod of 28.3° (30); a leg's widest 27° (the coat holds 27).
  - Nothing passes the head. The pole is 0.01 clear at its closest (20), and the lantern 0.02 (176). The content check's note on a 0.01 graze at 171 was cleared in this pass: it tips its head away as the pole rises.
  - The blocking's four grazes are gone.
  - The plant flings the lantern to its 100° catch at 23: a snap in motion, for your read.
- **For Faber, at delivery:**
  - `Config/Animations` needs the Lamplighter's set: Idle, Challenge, Ready, Walk, Swing (KeeperSwing), Hit and Signature. `Strides.LamplighterWalk` is `clips.json`'s 4.94.
  - The Challenge is 1.53 s. The keeper should hold it to its end: the screen clears about 0.45 s in, so the Lift at 0.73 s is seen.
- **Time:** about 45 minutes by the clock, from research's read (12:49 UTC) to the export (13:35). With the blocking, about 1 hour 15 of the 4 named for the clips. On Opus 5.5.
- **Content check, 2026-11-13: PASS.** It covered all seven packs, the arcs, the bare sheets, `clips.json` and the performance lines, against rules 2, 3 and 4 and Roblox's, with the names checked against `docs/ip-list.md`. Its note on the head graze was cleared and the signature re-checked: PASS. It carries:
  - The model's condition, no red pieces in the signature, is met: the clips have no effect pieces.
  - The slam's effects (the cyan circle, the impact) get their own check in `/ga-action`: no red; no drop, spray or stain shapes in any colour; the hit shown as light, dust or sparks.
  - A re-export that moves the lantern needs the same short re-check. Each clip gets its line in `docs/asset-log.md` at delivery.

**Research's read of the timed clips, 2026-11-13,** from the packs, the arcs and `poses_Signature.png`.
- **Felt:** the hold builds now. It leans out bowed, sinks onto the pole, and at 96 the face comes up under a level brim with the lantern beside it, not over it. That's the moment you know it's coming. The slam folds the whole body: the hat tips, the pole lies level, the lantern is down by your fighter. The Swing's lantern flung wide and swinging back shows its weight.
- **Tier:** competent. The signature isn't exceptional yet, for one reason: the wrench.
- **The one bold thing:** the face lifting at 96. It's the best moment the keeper has.
- **Fix 1 is met,** and **fix 2 is met in time** (the 4-frame hang, the slam 8 frames on).
- **The calls:**
  - The Swing's wide fling: yes.
  - The plant's snap to the catch: yes. Both give the lantern a weight.
  - The one-handed wrench is kept, but not at this height.
- **Fix, the wrench's height:** at 106 to 110 the lantern stands barely above where it hangs at Ready. So the anticipation's peak is no bigger than the rest pose, and the warning before the heaviest blow in the first session doesn't read. Raise it: the arm straight up, the pole slid up through the grip, until the lantern's top stands clearly over the hat, at least a fifth of the keeper's height above its Ready place, as it reads at 64 px. Judge the frame by the game's ring camera, where the keeper is 0.32 of the frame's height (TR2, `keeper_framing`), not by a tighter render. If even that leaves the frame, the lever is yours: say what you tried. This serves the tell (`docs/research/vfx-reference.md`, rule 1: rung 8).
- **Tier 2, the keeper's walk: research's yes** to a walk speed of its own near 5, with the clip at rate 1. Faber checks the time to first contact against a ranged lead (Pip, Lyric) and against Rook in a take. If the slower approach gives a ranged lead more than about 1.5 s of extra free hits, he raises it as far as 7, with the clip's rate following (up to 1.4 still reads as a walk).
- **Deliver** all seven once the wrench is raised, after research's look at the new 106 to 118. No other round.
- **The wrench raised (Modulo, 2026-11-13),** in `build/scratch/modulo/lamplighter/clips/`:
  - The arm goes straight up, to 80°, the most R6 reaches: the grip is 5.25 up. The pole slides up through the grip, from 3.9 to 2.6 up it, tipped 6° out to the right so it clears the brim.
  - At 110 it tips back 4° along the slam's own line, so the fall stays in one plane at the keeper's right. The first try swept the pole's foot through the torso (−0.09 at 114) and the right leg.
  - At 106 the lantern's foot is 8.73 up, against Ready's 4.68 and the hat's top at 6.89. That's 59% of the keeper's height above its Ready place, about 38 px at 64 px. The whole drum stands over the hat from 102 to 112, swinging on its cord.
  - **The heave** (tier 1): 96 to 106 was a quart ease-out, and over the longer rise it threw a third of the move into frame 97, a one-frame jump at 64 px. It's now a cubic in-out over the same 10 frames: the look holds to about 99, and the heave fills 100 to 102. The slam's timing is unchanged: it lands at 118 and rests to 153.
  - **A ring camera** joins the script: the fight's way round, at the game's 70° with the keeper 0.32 of the frame's height (`ring_Signature.png`, `ring64_Signature.png`). `-- ring Signature span=a,b,step` renders a strip of frames alone at 64 px, in about 0.4 GB.
  - **Checks:** the audit passes on the Signature (Pop 1.04; salute 0.05 s, in passing; an arm in the body 0.043). The pole clears the torso by 0.24 and the right leg by 0.57. The content check's short re-check of 96 to 118: **PASS**, with nothing new to carry.
  - **Time:** about 15 minutes by the clock, from research's read (13:37 UTC) to the strips (13:52). The clips took about 1 hour 30 of the 4 named.
- **Research's look at the raised wrench, 2026-11-13** (`ring_Signature_wrench.png`, `ring64x2_Signature_94_122.png`): **met.** From 102 to 112 the lantern stands high over the hat, the tallest shape the keeper makes, unmistakable at 64 px. Then it comes down in one plane onto your fighter. The heave from 100 to 102 fixes the one-frame jump. Yes, deliver all seven.
- **Four facts:**
  - Made: timed and exported.
  - Self-reviewed: from the fight's camera, the side and the ring's, with the audit. Content check PASS, and PASS again on the raised wrench.
  - Delivered 2026-11-13 to `build/handoff/Lamplighter/clips/`, byte for byte what was checked: the seven `Lamplighter_<Clip>.json`, `Lamplighter.clips.json`, and a pack each (`pack_<Clip>.png` and `.txt`). Its row is in `docs/asset-log.md`. Not uploaded, and not in the engine.
  - Accepted: research's read was competent, and its look at the raised wrench met.
  - The roles and the walk went to Faber with the delivery.

### 5. The fall: the block clip (Modulo, 2026-11-13)

**The feel line, proposed, for research to sign:** "Struck one blow too many, the keeper sags onto its pole, its mask tips back to the sky and it bursts into light and paper; its pole stays planted where it stood, the lantern still lit on its hook, the last light on the street, until it gutters and goes out."
- **The hero shape:** the lit lantern on the lone pole.
- **The levers:**
  - anticipation in the sag onto the pole and the mask letting go;
  - the Shade's own Burst;
  - then a held beat: the lantern alone for half a second before its light goes.
- **Why the pole stands** (tier 1, for the verdict): the keeper of a street of lanterns leaves one behind, as its signature leans its pole out as a street lamp. A falling pole was the other road: a long sweep and a lantern rolling on the floor, where a light low by the ground can read as a pool (Pip's condition 4).

**Scope, fixed here.**
- **The block:**
  - the clip, `tools/blender/lamplighter_fall.py`, exported as `Lamplighter_Down.json` (LamplighterDown): 97 frames, 1.60 s, with the markers Burst 34, Gutter 64, Out 80 and Gone 88;
  - in the replay (Faber, with AR7's install):
    - the Shade's burst at keeper size (1.5) on Burst, the body hidden there, the Pole and the Lantern kept;
    - the lantern's glow steady at 1.2, flickering from Gutter, and 0 on Out;
    - on Gone, the pole and the lantern go to a handful of the burst's own paper scraps, with no flame;
    - the server keeps the body until Gone.
- **Waits:**
  - any art of the fall's own (the guttering, the last scraps), if the replay asks for it;
  - the final clip's polish;
  - the sound.

**The clip.**
- 4: struck, it's rocked back, the size of Hit's blow at the shoulder. The planted pole carries the grip's jolt about three times up to its hook, so the lantern is held back from flinging over it.
- 16: it sags onto its pole, the head bowed under the brim.
- 26: the mask lets go.
- 34, **Burst**: its face is to the sky and the hat tips back, as the Shade's Burst.
- After that the hidden body brings the grip back over the pole's planted foot, so the pole rocks back past upright once and stands still by 54. The lantern swings and steadies.
- 64, **Gutter**; 80, **Out**; 88, **Gone**.

**Checks, on the export:**
- The audit passes: an arm into the body 0.015, a leg out of the hip 0.035, Pop 1.04.
- The pole stays 0.96 off the torso and 0.51 off the head (at 44, hidden).
- The lantern's widest off plumb is 50° at 15, as it sags (74° before the hold at the blow). It stays 0.84 off the head.
- A leg swings at most 24° (the coat holds 27).

**The read on the sheet** (`build/scratch/modulo/lamplighter/fall/poses_Down.png`, from the fight's camera and its left side, the body hidden after Burst as the game hides it):
- It reads struck, sagging, then the face to the sky.
- Then one shape is left, the lamppost with its lantern, and it holds through the light's going out.
- The bare rig and the arcs: `bare_Down.png`, `arcs_Down.png`.

**Content:** the model's check carried a condition, no red pieces in the fall. The body and its red sash hide at Burst, and the burst's art has no red. The pole that stays is the model's dark lacquer, for the final's check to read. The block plays unpublished in the replay, so the content check comes with the final clip, before any upload.

**Time:** about 15 minutes by the clock, from B5's commit to the export (16:14), against the 2 hours named for the fall.

**Asks:**
- **Research:** sign the feel line and the scope, or correct them; then the verdict in the replay.
- **Faber:** the replay above, with AR7's install.

**Research signs the scope and the feel line, with one correction, 2026-11-13** (`poses_Down.png`).
- **The idea is accepted, tier 1:** the pole stays planted with its lantern lit, then the light goes. It's the strongest fall on the sheet. One shape is left where a keeper stood, and it says who this was. It fits the ladder's rung 9: a held beat that only a keeper's fall earns.
- **The correction to the feel line:** Lantern Row is a street of paper lanterns (`docs/roster.md`), so the keeper's lantern isn't "the last light on the street", and nothing in this scope darkens the others. The signed line: "Struck one blow too many, the keeper sags onto its pole, its mask tips back to the sky and it bursts into light and paper; its pole stays planted where it stood, the lantern still lit on its hook, alone, until it gutters and goes out."
- **The scope is signed as written.** The street dimming with its keeper is a new idea, so it isn't in this piece. It goes to `docs/polish-later.md`, for the street's own dressing.
- **For the replay's verdict:**
  - Does the lone lantern read as the keeper's among the street's own lanterns at phone size? It's judged in Lantern Row as it stands. If the replay runs on the plot, the verdict is only a blockout's.
  - Does the half second from the pole's stillness to Gutter hold, or does it drag before the fight's rewards?
  - The pole rocks back once with no hand on it. It must read as let go, not as pushed.
- **Next:** Faber's replay with AR7's install, then research's verdict in motion.

**AR7 installed, and the fall's replay built (Faber, 2026-11-13).**
- **The install:**
  - The model is a template: `tools/studio/Models/Lamplighter.luau` builds `src/storage/Lamplighter.rbxm` (`ServerStorage.Templates.Lamplighter`). It has:
    - the eight meshes and four maps;
    - the pole on the right arm and the lantern on the pole, as Motor6Ds the clips key;
    - a cyan PointLight in the lantern (1.2, range 9, scaled with the body);
    - a Collar point where the burst starts.
  - Its eight clips are saved in the place, unpublished: Idle, Challenge, Ready, Walk, Swing, Hit, Signature and this Down.
  - The keeper's row is `Rig = "Lamplighter"`, Scale 1.5, `Enter = "KeeperChallenge"`.
    - It holds its Challenge as it spawns, before anything else (1.53 s: Lift 0.73, Stamp 0.97).
    - It fights in its Ready and swings `LamplighterSwing`.
    - It walks at `Combat.Keeper.WalkSpeed` 5, the clip at rate 1.01.
  - Its Hit doesn't play yet: `Combat.Flinch.Kinds` leaves keepers out, unchanged.
- **The fall** (`Config.Effects.Falls.Lamplighter`, the scope as signed):
  - The Shade's burst plays at its size on the clip's Burst, and the body hides; the pole and the lantern stay.
  - The lantern holds at 1.2 until Gutter, falls with a flicker until Out, and is 0 from Out. Its light follows it.
  - On Gone the two go to 7 of the burst's own scraps (4 from the lantern, 3 from the pole), rising 2 studs, with no flame.
  - The server keeps the body 1.9 s (`Combat.Keeper.FadeSeconds`). In the self-test it's still there at the clip's 1.57 s, past Gone's 1.47.
- **Research's tier 2, the time to first contact.** In a keeper try each, I measured the free time: the keeper's first swing less the lead's first action. Walk 5 against the Shade's 12:

  | Lead | At 5 | At 12 | Extra |
  |---|---|---|---|
  | Pip | 1.65 s | 1.00 s | +0.65 s |
  | Lyric | 1.57 s | 1.00 s | +0.57 s |
  | Rook | 0.51 s | 0.67 s | −0.16 s (the Challenge's hold covers his walk-in) |

  All are under 1.5 s, so the walk stays at 5.
- **Checks:**
  - Type check: 0 new.
  - Logic: 2432/2432, offline and in Studio. New cases:
    - the fall keeps its order;
    - the body lasts to Gone after the longest hold;
    - the walk plays between rate 0.9 and 1.4;
    - an entrance hurts no one;
    - the row check goes by rig.
  - The keeper's self-test case: 24/24 at 60 fps, under the phone emulator. It covers:
    - the rig, the scale and the feet;
    - the glows;
    - the Challenge held still;
    - the Ready;
    - the walk at 5.03;
    - the fall, frame by frame on the clip's clock.
  - The whole self-test on the desktop: 849/851 at 55 fps. The two misses are HUD cases outside this piece, found here and stable alone:
    - the level-up word rises 66 px over the top band on the desktop (it passes on the phone, and AR8 C's whole runs were all on the phone emulator);
    - an open plate under the Electricity pill sits 9.0 px under it, short of the band's 9.5, on both.

    They're my next fix, before Rook, Pip and Lyric.
  - Under the phone emulator, the touch camera also misses its known checks: the Base case's two (TR3) and the arrival camera's facing. All three pass on the desktop.
- **Takes,** at phone size (the iPhone 16 Pro emulator), in `build/captures/ar7/`:
  - `ar7_try.mp4` (sheet `ar7_try_sheet.png`, the opening `ar7_try_challenge_strip.png`): a keeper try with Pip, from the gate's prompt through the fade, the Challenge, the walk-in and the trades.
  - `ar7_fall.mp4` (strip `ar7_fall_strip.png`, a tenth of a second a cell): the fall's replay at the street's end by the gate. The keeper is spawned 14 studs ahead of the avatar, turned 25° right so it stands where a try puts it, then defeated 4 s in.
  - Lantern Row is still its grey block (its install, AR5 section 2, is queued), so by research's line this verdict is a blockout's.
- **What I see, for the verdict:**
  1. **Pip hides the Challenge.** A try sets the lead down at `Combat.Lead.Side` to the avatar's right (`KeeperService` `setDown`). That's on the camera's line to the keeper, and Pip walks in along it. Through the Lift and the Stamp, his hat covers most of the keeper. It belongs with the queued avatar-occlusion fix. My proposal: a try sets the lead down on the avatar's left. Not changed here (scope).
  2. **The keeper reaches the frame's top on the phone.** At `Arrive` 14, its hat and lantern touch the top, and the swing's lantern rises into the top-right pills. The lever is a step back on `Arrive` (research's number, TR2's read).
  3. **"Out" reads faintly.** The lantern's colour map is pale cyan paper, so at glow 0 it still reads half lit in daylight. Out to Gone is 8 frames, 0.13 s. The levers: a darker tint on the paper as it goes out, a longer Out, or the fall's own art, which the scope holds until the replay asks for it.
  4. Research's three questions stand: the lone lantern among the street's own, the half second before Gutter, and the pole's rock read as let go.

**Research's verdict on the install and the fall's replay (2026-11-13, a blockout's, Lantern Row grey; `ar7_fall.mp4` at 10 cells a second, `ar7_try_challenge_strip.png`).**
- **Felt:** the keeper drops and leaves its lantern standing on the pole, which is the right picture, but Pip walks back across it, so the lantern goes out and scatters behind his hat. On a phone the fall has no ending.
- **Tier:** works. **The one bold thing:** the lantern left standing alone on its pole after the body's gone (8.3 to 8.9 s). Keep it.
- **Fixes, in order, before Rook, Pip and Lyric; all numbers, tuned live:**
  1. **The lead on the avatar's left in a try (Faber's proposal, accepted).** It clears the Challenge and the fall's line both.
  2. **The lead holds after a keeper falls,** facing it until Gone, then turns. The fall is the try's ending, and the lead watches it with the player.
  3. **Out reads:** from Gutter the paper's Color goes down toward a deep blue-grey (about a third of its value), and Out to Gone lengthens to about 0.35 s, eased in. The goal: dark paper is plainly unlit against the day sky.
  4. **Arrive 14 to about 17,** in 1-stud steps until the hat and the swing's lantern clear the frame's top and the pills on the phone, with a margin.
- **The three questions:**
  - The half second before Gutter doesn't drag. It's the bold thing's moment.
  - The pole's rock reads as a lean, not yet as let go. Look again once Pip no longer covers it.
  - The lone lantern among the street's own can't be judged on a grey street, so it goes to Lantern Row's install (AR5, section 2).
- **Next look:** one take of the try and the fall after fixes 1 to 4, from the same camera.

**Fixes 1 to 3 in; Arrive can't meet fix 4 (Faber, 2026-11-13; 5fc87a3).**
- **Fixes 1–3, as asked, the numbers in Config:**
  1. A try sets the lead down at `Combat.Keeper.Side` −3.5, the avatar's left. Measured: −3.50.
  2. After a keeper with a fall goes down, a lead that was on it holds and faces it until Gone plus the longest hold, then turns. Measured: 0.01 studs of drift, 0° off.
  3. `Falls.Lamplighter`: from Gutter the paper's Color eases (`Ease` 2) to `Dark` (66, 74, 90), reaching it at Out. Gone moves to 101, so Out to Gone is 0.35 s.
  - Two numbers follow from the later Gone: `WinPause` 2.4 (the last scrap is seen), `FadeSeconds` 2.1.
- **Checks:**
  - Self-test: 861/861 at 60 fps under the phone emulator, the touch camera's checks included.
  - Logic: 2436/2436, in Studio and offline. The world report is empty. Type check: 0 new.
  - New checks: the lead's side; the hold, its facing, then the turn; the paper's own colour until Gutter, going down, dark from Out to Gone; Out to Gone at 0.3–0.45 s; Dark is a deep blue-grey; the last scrap comes before WinPause.
- **Take,** at Arrive 14 with Pip, under the phone emulator, in `build/captures/ar7/`:
  - `ar7_fixes.mp4` (sheet `ar7_fixes_sheet.png`);
  - `ar7_fixes_challenge.png`: from the fade's lift, 10 cells a second;
  - `ar7_fixes_fall_strip.png`: the fall, 10 cells a second.
- **Fix 4, measured** on the phone's 750×401 viewport, frame by frame (the hat's top):
  - Arrive 14: y 82. Arrive 16: 77. Arrive 18: 84 to 90, at 31 to 34 studs.
  - So the hat stands 57 to 69 px over the Electricity pill's foot (147) and over the Credits pill's (108) in nearly every frame. Arrive 18 is no better than 14.
  - **Why no Arrive can work:** the camera's eye is 7.8 studs over the keeper's floor and the hat's top is 10.5.
    - The hat is above eye level, so at any distance it projects above the horizon (y 116 to 123).
    - The top band's feet are all below the horizon: Target 137, Electricity 147, Lead 171.
    - On the phone the band covers the width but for two gaps, of 25 and 38 px.
    - A step back only eases the hat toward the horizon, about 2 px a stud, while the keeper shrinks.
  - Arrive stays 14.
- **The take shows two more things:**
  1. **Pip still crosses the Challenge.** Set down on the left, it walks to its slot on the keeper's far side, to the right. That's `Lead.Beside.Keeper` 90 with `Fight.Aside`, which takes the side the keeper leans to. The walk crosses the camera's line, so its hat covers the keeper's body through the Lift and the Stamp.
  2. **The same slot pulls the fight to the frame's right edge.** The fall's lantern, now plainly dark, stands under the Credits pill, the Electricity pill and the shard toast, with Pip out of frame. So the bold thing is mostly hidden on a phone.
- **Options, each with its cost** (the call is research's):
  - **A.** In a try, the lead takes the keeper's near side: `Fight.Aside`'s side flipped for keepers. The walk-in never crosses the camera's line, the fight and the fall sit nearer the middle, and the lead watching is in frame. About 45 minutes, with a logic case and a take.
  - **B.** The top band goes see-through over the keeper: a piece fades to about a quarter while the hat or the lantern is under it, then eases back. It works on every device and with any placement. About 1.5 hours, with a self-test case.
  - **C.** The try's economy pills step out: Credits and Electricity slide up for the try and come back for the win's count. This clears only the right column; a fight under the Target card stays covered. About 1 hour.
  - **D.** The try's camera goes higher, the eye about 14 studs instead of 7.8, so the hat projects under the band. The avatar then sinks into the bottom HUD and the view turns top-down. About 1 hour, plus a framing study.
  - **My pick:** A, then B.

**Research's call on fix 4 (2026-11-13, from `ar7_fixes_fall_strip.png` and `ar7_fixes_challenge.png`).**
- **Fixes 1 to 3 pass:**
  - The dark paper reads plainly unlit against the sky. The fall's last beat now exists.
  - The lead sits on the left, and it holds.
- **Fix 4 is withdrawn, on Faber's measurement.** Arrive stays 14. The hat is above the eye, and on a phone the band's feet sit below the horizon, so no step back clears it.
- **A now.** It's the cheap lever that fixes the cause: the walk-in stops crossing the camera's line, and the fight and the fall come off the right edge.
- **Then one take, and B only if it's still needed.** If after A the hat or the lantern still sits under the band through the Challenge or the fall, B is built on two terms:
  - the economy pills and the shard toast fade to a quarter;
  - the Target card fades no lower than half, with its bar kept readable, because it's the fight's own read.

  B is judged in motion like any blockout.
- **C and D are rejected.** C clears only the right column, and B covers it. D sinks the avatar into the bottom of the screen and turns the view top-down.
- **Next look:** the try and the fall after A, from the same camera.

**A and B in, with a take (Faber, 2026-11-13; e91b143).**
- **A:** against a keeper, a lead past `Lead.Straight` takes the side toward the avatar's line of sight (`Combat.Lead.Near`, `Fight.Aside`'s `near`). Measured over the walk-in, from a camera 12.5 studs behind the avatar: the lead keeps 5.5 to 5.8 studs on its own side of the line to the keeper and never crosses it (about 220 frames).
- **The take after A** (`build/captures/ar7/ar7_near*`):
  - Pip is clear of the Challenge.
  - The fall's dark lantern stands alone in the sky, with Pip watching from the left.
  - The Target card still covered the keeper's hat through the Challenge, so B's condition was met.
- **B, built as a blockout.** While the keeper's hat or lantern is under a piece of the top band on screen, that piece fades, eased:
  - the economy pills and the shard toast fade to 0.25;
  - the Target card fades to 0.5 and no lower, and its bar and health number to 0.85;
  - a piece comes back 0.25 s after the last overlap, and the lead's card is never faded.

  The numbers are in `Config.Hud.SeeThrough`, live-tunable. The fade scales each part's own transparency (`src/client/UI/Kit/Fade.luau`), so no CanvasGroup clips a pop's swell, and anything that animates a part mid-fade keeps control of it.
- **Checks:**
  - Keeper filter 65/65 at 60 fps. The new checks hold the camera so the hat sits under each piece in turn:
    - under the Target card, the card reaches 0.50 and its bar 0.85, and the drawing shows it (the housing at 0.50, the light at 0.15);
    - under the Credits pill, the pill reaches 0.25;
    - with the keeper out of view, every piece is whole again and each part is exactly as it was;
    - no piece ever went past its floor.
  - The full self-test: 870/870. Logic: 2459/2459 in Studio and offline. The world report is empty. Type check: 0 new.
- **The take with B** (`ar7_see.mp4`, `_sheet`, `_challenge`, `_card`, `_fall_strip`):
  - Through the Challenge the card is at half. The hat and the pole read through its housing and tab, and the bar's strip across the brim stays almost whole (`ar7_see_card.png`).
  - In the fall the band has nothing to fade: the lantern goes dark in clear sky.
  - This time Pip stood in front of the keeper's body at the fall.
- **A new finding, for the framing.** With A, the keeper walks out to meet the lead, so in both takes the fight runs straight ahead, behind the avatar's own body, which covers the lead and the keeper for much of the try. This is the framing fix already queued for "Rook, Pip and Lyric installed" ("the avatar's body never covers the lead and its target at phone size"), now seen in a try. Levers, for research's call:
  - the keeper holds the ring's middle and lets the lead come to it (the Turn already sets the middle off the avatar's line);
  - a larger Turn;
  - the avatar set down further aside for a try.
- **Research:** B's verdict in motion, and whether the framing finding joins this piece or stays with the install piece.

**Research's verdict on A and B (2026-11-13; `ar7_see_challenge.png`, `ar7_see_card.png`, `ar7_see_fall_strip.png`).**
- **Felt:** the keeper stands up through a half-clear card, Pip comes in from his own side, and at the end the dark lantern stands alone in clear sky over Pip's hat. The fall finally ends on screen.
- **Tier:** competent, as a blockout on a grey street. **The one bold thing:** the unlit lantern alone against the sky. It now reads.
- **B passes as built.** The hat reads through the housing, and the bar across the brim is the fight's own read, so it stays. The numbers stay live in `Config.Hud.SeeThrough`.
- **The framing stays with "Rook, Pip and Lyric installed",** its first fix there. It's every fight's framing, not the keeper's, and scope is fixed at the feel line. Research leans to the keeper holding the ring's middle and letting the lead come: it clears the avatar's line and gives the keeper a holder's presence. That piece's blockout decides.
- **Carried:**
  - the pole's rock, looked at again in that piece's take;
  - the lone lantern among the street's own, at Lantern Row's install (AR5, section 2).
- **AR7's install closes here** at research's pass. The signature's motion blockout (section 6) stays open.

### 6. The signature's effect: the block-in (Modulo, 2026-11-13)

Research's ask: a grey block-in on the delivered Signature clip's markers (Plant 24, Light 44, Wrench 106, Slam 118). It's staged like B1's H, from the fight's camera past the avatar, at 64 px and on Lantern Row's dusk, at rung 8. Two or three variants, my pick, the feel line and the scope.

**The feel line, proposed, for research to sign:** "The keeper wrenches its lantern high over its hat, the light gathering white in it as it looks down at your fighter; then it slams it down beside them, and the light leaps back up out of the street, a column twice the keeper's height that lets go of the ground and climbs away."
- **The hero shape:** the column of light leaping up where the lantern lands.
- **The levers:**
  - anticipation through the hold: the lantern's light is mid grey from the Light, white from the look down (96), and motes are drawn in faster toward the wrench;
  - the flare on the Wrench, the top value for two frames;
  - one streak trailing the fall, 111 to 118;
  - the slam's flash on 118 and 119, the top value;
  - the column's peak on 121, three frames into its 26, inside the first quarter;
  - chips flung off its edge a breath later, from 122, lower and softer.
  - The hitstop (rung 8: 0.12 to 0.14 s), the shake and the camera are Faber's, on Slam.

**Scope, fixed here.**
- **The block:** in Faber's `/ga-action` motion blockout on the same markers, the grey shapes as the script draws them. Their numbers are in `halo()`, `gathering()`, `flash()`, `column()` and `chips()`, in the keeper's units (×1.5 for studs), to be tuned by playing.
- **Waits:**
  - the drawn look, after the verdict: the column's picture in Lantern Row's cyan and warm white, under the content check's conditions;
  - the sound;
  - the hitstop and shake numbers;
  - any circle on the ground (C, below).

**The variants** (`tools/blender/lamplighter_signature_fx.py`; the sheets are in `build/scratch/modulo/lamplighter/signature_fx/`: one per variant from the game's camera, the ring and flank strips, the bright floor, and `signature_64.png`):
- **A, the column: my pick.** At 64 px it's one white flame by the lead, with one point, rising and leaving through the frame's top. The keeper stays seen beside it.
- **B, the shock:** a wall of light running out over the lead's feet, with chips. It's the biggest, but from the game's camera and at 64 px it's a flat hoop on the floor round the lead, the decal read B1 ruled out.
- **C, A under the seed's circle:** the seed's circle, stood up as a waist-high wall from the Light, drawing in to the Wrench. From the game's camera it reads as a white dish at the lead's feet, the pool research warned of, even as a wall.
  - My answer: the circle adds nothing the gathering's light doesn't already say, and it costs the pool.
  - I propose dropping the seed's "circle on the ground" (tier 2: research and Faber).

**The measures,** from the game's camera. The share is the screen the effect changes at 480 by 270.

| Frame | 106 | 118 | 119 | 120 | 121 | 122 | 124 | 127 | 130 | 136 |
|---|---|---|---|---|---|---|---|---|---|---|
| A | 2.0% | 3.1% | 3.8% | 4.6% | **4.7%** | 4.4% | 4.1% | 3.6% | 2.8% | 1.4% |
| B | 2.0% | 3.2% | 3.4% | 4.8% | 5.5% | **5.8%** | 5.0% | 3.0% | 1.2% | 0.0% |

- Pip's coil, a Voidkin's signature at rung 7, peaks at 4.4%, and A is over it. At 2.3 by 10 keeper units, A held 2.5%; at 3.8 by 11.2, 4.7%.
- A's top is 16.8 studs at its peak, and it climbs off through the frame's top by 136. It's gone on 144, while the keeper still holds the pole down.

**A finding for the camera** (DESIGN: staged from `Config.Combat`'s numbers, not captured in the engine). From the keeper fight's camera, the wrench's lantern and its light stand over the frame's top edge from 103 to 110, by up to 4°, so on a phone the bold thing is cut. The camera is seen from the keeper's right, a touch from behind: Keeper.Arrive 14, Turn 26, Lead.Beside.Keeper 90, and 12.5 studs behind the avatar, 14° down at 70°.
- The lever is the camera's (Faber): tilt up about 6°, eased, through the hold from the Light, and back on the Slam; or ease back.
- The clip stays as delivered. Its wrench passed from the ring camera.

**The content check: PASS** (rules 2, 3 and 4), on the grey block-in only, all three slams, at full size, at 64 px and on the bright floor. The drawn look carries these conditions:
1. No drop shape. The column gets flame tongues or a ragged edge, and the streak is drawn as straight streaks. No gloss, and no bead at a tip or a foot. What lets go rises and fades: nothing falls or drips.
2. Light colours only: white, cyan, the lantern's warm tint. Never red or black.
3. The chips are angular bits flung up and out. Never beads or a fan of droplets.
4. Nothing is left on the floor: the floor is clear by about 140.
5. Any low light keeps an open centre and visible height, never a filled disc. A drawn circle that reads as a plate or a pool at 64 px is cut.
6. A visible gap between the gathered light and the hat at every heading at 64 px. The motes stream into the lantern, never out of the head.
7. The drawn look's own check: at full size, at 64 px from every heading, on dark and bright, and once with the light in a dark colour, to test the shape alone.

**Hours:** about 0.6: 15:31 to 15:48 UTC, then 16:01 to 16:20, with B1's last redraw between.

**Asks:**
- **Research:** sign the feel line and the scope, or correct them. Give the verdict on A against B and C, with `ga-fresh-eyes` (rung 8) and the dropped circle (tier 2).
- **Faber:** the motion blockout on the markers, and the camera's tilt.

**Research's verdict, 2026-11-13,** on the three variants, the 64 px, ring, flank and bright sheets, with `ga-fresh-eyes` blind beside it (rung 8).
- **Felt:** a long lean with the lantern out over your fighter. The wrench swings it up, and on the slam a white spike shoots up beside the fighter, stands, then breaks off and flies up out of the frame.
- **Tier:** competent as a blockout.
- **The one bold thing:** the spike breaking off and leaving upward (130 to 140). Fresh eyes named the same, and picked A too: B's ring reads as a tub rim and nearly vanishes on the bright floor, and C's disc reads as a saucer.
- **A is picked. The feel line and the scope are signed** as written.
- **The circle is dropped** (tier 2, research's part given). The tell is the lantern leant over your fighter and the light gathering in it. Faber confirms his part in the motion blockout.
- **The camera's tilt** through the hold is Faber's lever. Without it the bold wrench is cut on a phone.
- **Fixes, for the art and the motion blockout:**
  1. **It holds from 120 to 127.** It's at its peak and barely changes for seven frames. Let go sooner, as H did: the foot leaves two or three frames after the peak (rule 3).
  2. **At impact it covers your fighter and most of the keeper.** The slam's pose and the struck lead's flash are the beat. Make the column narrower and taller, so the keeper's body and the lead stay seen through 119 to 121. Keep its share over the coil's by its height.
  3. **Give it the keeper's own shape.** In grey it's a teardrop, a round foot and a point. That's the drop the content check rules out (condition 1), and it's the same verb as Pip's coil: a spire that lets go upward. The rung-8 keeper's signature should be told apart from a rung-7 Voidkin's at a glance. One direction, Modulo's to draw: straight sides like lamplight, and the street's own mark, the paper lantern's ribs, as bands of light climbing it. The colour (Lantern Row's cyan and warm white) does the rest.
  4. **The gathering in the hold** is a small change at 64 px. The art and the motion blockout judge whether the lantern's light reads as building.
- **Next:** the art sheet with fixes 1 to 3, under the content check's seven conditions. Then Faber's motion blockout through `/ga-action`, and `ga-fresh-eyes` again at the final.

### 7. The signature's art (Modulo, 2026-11-13)

Research's fixes 1 to 3, drawn under the content check's seven conditions. The script is `tools/blender/lamplighter_signature_art.py`. The sheets and pictures are in `build/scratch/modulo/lamplighter/signature_art/`, not delivered: the content check blocks on the clip (below).

**The column:** three Beams where the lantern lands.
- **The shaft:** Wrap, one rib a period (TextureLength 2.63 studs), TextureSpeed 7 so the ribs climb, Width0 = Width1, LightEmission 0.7.
- **The tip:** Stretch, the shaft's width, a needle drawn in the picture.
- **The halo:** behind both, 1.9 times as wide, wider on the slam's two frames (the flash).
- **The pictures:** `lamplighter_column.png`, `lamplighter_column_tip.png`, `lamplighter_column_halo.png` and `lamplighter_glow.png` (a BillboardGui on the drum through the hold). The numbers per frame, in studs, are in `lamplighter_signature_art.json`.

**The fixes, measured from the game's camera:**
1. **The hold:** the foot lets go on 123, two frames after the peak, and is 3.2 studs up by 127. The top climbs slower, so the column shortens and thins as it goes. It goes out from 128 and is gone by 140.
2. **Narrower and taller:** 6 studs wide at the peak (the grey's belly was 7.6).
   - Covered at 118 to 121: the lead about 10% (the grey, all of it), the keeper 4 to 6% (the grey, 13 to 17%).
   - Share: 6.5% at 118 and 5.0% at 121, over the coil's 4.4%.
   - The point stays inside the frame to 126, then climbs out of the top.
3. **The keeper's shape:** straight sides, the paper lantern's ribs as warm bands of light climbing it, cyan and warm white, a needle top. In the dark colour it's a banded spire, not a teardrop.
- **The hold's light** is kept to the drum, with its ribs seen through it. It's wider only for the wrench's flare, 106 to 110.

**The content check: BLOCK, on the clip, not the art.**
- **The art passes:** conditions 1 to 5 and 7, and rules 2 to 4.
- **Condition 6 passes from the game's camera and the flank:** at 64 px the glow stays at least 8 px and 6 px clear of the head and hat (`hat_gap_px_at_64` in the json).
- **Condition 6 fails from the ring's heading,** your fighter's side.
  - The Signature clip holds the lantern between your fighter and the keeper's face from 44 to 100, and the fall passes it again on 116.
  - The drum itself covers the head, by 102 to 314 px at 64 px, so no glow size fixes it.
  - It reads as light gathering at the face, then a spike leaving it: the trap in `handbook/platform/rules-and-moderation.md`, "Traps".
- **The check's fix:** the clip's hold and fall held off that line from 44 to 116, keeping the wrench's height at 106 to 110. It passes when the ring's gaps are positive on every frame.

**Tier 2, for research:** this reopens the signed clip's hold. The clip isn't uploaded (`docs/asset-log.md`), so it costs a re-export and a short re-check, not a re-upload.
1. **Higher and out to the side (my pick).**
   - Through the hold the lantern is held up over your fighter and out to the keeper's side, its drum clear over the hat from your fighter's side.
   - The fall comes down that side to the same landing.
   - It clears every heading, not only the three cameras we test.
   - The wrench's lift gets shorter. The bold thing in your verdict, the column leaving at 130 to 140, is untouched.
2. **Out to the side only.** It clears the three cameras, but some heading between them lines the lantern up with the face again.
- **Cost:** about 2 hours of mine (the hold and fall keys, the clip's own checks, the export, this sheet again), then your look at the hold from the game's camera.
- **Until then:** the art waits in scratch. Faber's motion blockout runs on the grey as scoped, and this doesn't hold it.
- **The clip's block stands however the effect is built:** the drum itself is what covers the face.

**Stopped as it stands,** on the director's word of 2026-11-13, through research: effects are built in 3D in the engine (our meshes with scrolling or gradient textures, Beams, Trails, particles where they help, lights), not drawn pictures on camera-facing cards. The column is already three Beams and Neon chips. The hold's glow is the one card. Waiting for AR8's plan.

**Hours:** about 0.75, 16:10 to 16:55 UTC.

**Research's call on the tier 2 (2026-11-13): option 1,** higher and out to the keeper's side, with the fall down that side.
- **Why:** it is the only option that clears every heading, and the shorter lift costs nothing that carries the read (the column leaving at 130 to 140).
- **The order in Modulo's queue:** AR8's kit first, then this clip, then the effects' rows as the player lands.
- **Research's look:** at the hold, from the game's camera, before the re-export goes to Faber.
- **Research's look at option 1 (2026-11-13, `build/scratch/modulo/sig_opt1/`, both heights, from the game's camera and the ring):** full height is picked.
  - **Why full height:**
    - From the ring it stands as one clean upright: the lantern on its pole beside the hat. It's a good silhouette for the hold.
    - Its margins carry the glow's spread at every heading.
    - d stacks the drum straight over the hat from the ring, the same reading as the face trap, only higher.
  - **The two-frame crossing at 114 to 116** from behind or left of your fighter is accepted. It's the lantern landing on them, in motion, and the content check rules on it.
  - **One condition, for Faber's motion blockout (section 6):** at either height, the hold sits at the game frame's top edge, and on a phone the top band covers it. The camera lifts through the hold so the lantern stays in frame below the band from the Light to the wrench, then comes back down for the slam. That tilt is the signature's camera lever, judged in the motion blockout.

**Option 1 delivered (Modulo, 2026-11-13), at full height.**
- **The hold:** the pole comes up off its plant and is held one-handed near its foot, leant out over your fighter on the keeper's right (`RAISE`, `RAISED` and `RAISE_OPEN` in `tools/blender/lamplighter_clips.py`). At the Light the lantern hangs over (2.95, 4.70) keeper units, its foot 7.35 up. The timing, the wrench and the four markers stay.
- **The fall:** the pole tips over the top with the arm still high (`TIP` 114), then drives down along heading −52. The lantern lands at (−1.28, 4.22), about 0.9 studs further to the keeper's left than before.
- **Measured on the exported json,** as clear pixels between the drum and the head and hat at 64 px:
  - The ring is positive on every frame from 44 to 118, the least 3.1 at 114. The hold has 14 or more.
  - The game camera's least is 1.2 at 116, and the flank's is 7.2.
  - A sweep of 11 headings at the game camera's distance: the hold is clear at every heading, the least 5.0 at 35°. From straight behind your fighter and from its left (−30, 0), the landing crosses the face on 114 and on 116 to 117.
  - On the game's screen the drum's top sits at 1.0 through the hold (0.74 before) and 1.11 at the wrench (1.03 before). That's the camera's lift, in research's condition above.
  - The body: the pole is 0.01 off the head at 20, as before. The lantern is 0.08 off it at 175 (0.02 before). The widest leg swing is 27, and the coat holds 27. The audit passes.
- **The content check: PASS** on the clip. The block on condition 6 is lifted. The crossing at 114 to 117 is accepted as motion: a solid drum swinging past for about four frames, with nothing gathering at the face. Its conditions bind AR8's effect build:
  - **a.** From 104 to 118, no glow, halo or motes sit on the drum beyond its paper. The hold's light and shell are out by 104.
  - **b.** The fall's streak (111 to 118) never lies across the head or face at any heading on 117 or 118. It's straight, in light colours only.
  - **c.** The column and chips stand at the new landing, with section 7's numbers re-measured there.
  - **d.** The effect's own check covers 112 to 119 from −30 and 0, at 64 px, on the dark floor and the bright one.
- **Delivered:** `Lamplighter_Signature.json`, `pack_Signature.png` and `pack_Signature.txt` in `build/handoff/Lamplighter/clips/`. `Lamplighter.clips.json` is unchanged: 183 frames, the same markers. The sheets are in `build/scratch/modulo/sig_opt1/`: `pick_full/` and `pick_d/`, and `json_full/` (the hold from the game's camera and the ring, and the crossing).
- **Hours:** about 0.7, 17:20 to 18:00 UTC.
- **Faber:** re-save the Signature as `NL_LamplighterSignature` from this json. The camera's lift through the hold is your motion blockout's lever (research's condition above).

### 8. The fall: the final clip (Modulo, 2026-11-13)

This is delivery 4, the block clip of section 5 polished, on research's open note: "The pole's rock reads as a lean, not yet as let go."
- **Where:** `Lamplighter_Down.json`, `pack_Down.png`, `pack_Down.txt` and `bare_Down.png` (the bare rig, for the upload's check) in `build/handoff/Lamplighter/clips/`. `Lamplighter.clips.json` gains Down; its other seven clips are unchanged. Made by `tools/blender/lamplighter_fall.py`, now named as the export's `Source`.
- **The same clip otherwise:** 97 frames, the markers Burst 34, Gutter 64, Out 80 and Gone 88. `Config.Effects.Falls.Lamplighter` keeps its own Gone at 101, past the held last frame. Frames 0 to 26 are as the block's.
- **The rock, let go:**
  - From 26 to 34, tipping back to the sky, the keeper drags the pole over with it, 9° toward itself on Burst.
  - With nothing on it, the pole springs back past upright and wobbles out, each swing about half the last: −4.3° on 40, +1.8° on 46 and −0.9° on 52, and it stands still by 58. A sine between the turns is the spring's own motion: at rest on each turn and fastest through upright, so nothing in it reads as pushed.
  - The lantern swings after the hook and steadies through Gutter. At its widest it's under 50° off plumb, the sag's own widest.
  - It's measured on the export, the pole's lean frame by frame (the script's `poses` log). Each turn's aim is solved against the grip it gives, because an arm can't reach every place. The hidden body stands a quarter stud toward the pole for the first swing away. `rock_Down.png` (frames 30 to 60, every second frame) is in `build/scratch/modulo/lamplighter/fall_final/`, with the pose sheet.
- **Checks:** the audit passes: an arm into the body 0.015, a leg out of the hip 0.035, Pop 1.04, a salute held 0 s. While the body shows, the pole stays 0.78 off the torso, at 34.
- **The content check: PASS,** on the pose and rock sheets, the bare rig, the arcs, the pack and the export. Nothing red is left after Burst, nothing is left behind, no arm is ever raised straight, and the lone pole reads as a street lantern. Carried to the build:
  1. The game hides the body on Burst, so only the pole and the lantern remain. The export keeps the body's pose after 34.
  2. The scraps at Gone stay the burst's own, with no red and no flame.
- **Open:**
  - Faber: re-save the Down as `NL_LamplighterDown` from this json, and take it from the game's camera.
  - Research's look at the rock, in the take of "Rook, Pip and Lyric installed", where it was carried.
- **Hours:** about 0.2, 19:27 to 19:40 UTC, the content check included.

**The re-save and the take (Faber, 2026-11-13).** `NL_LamplighterDown` is re-saved in the place from this json (97 frames, 1.60 s, Burst 0.57, Gutter 1.07, Out 1.33, Gone 1.47; its `Source` is `lamplighter_fall.py`), and the place is saved (version 334). The block clip it replaces is in git. Taken in a real try from the game's camera at phone size, the keeper beaten by `KeeperEnd`: `build/captures/ar7/ar7_down_final.mp4` and `ar7_down_final_strip.png`.
- **The carried conditions hold:** the body is gone on Burst, leaving the pole and the lantern. The pole rocks and stands, the lantern goes dark, and the scraps at Gone are pale, with no red and no flame. The flame on Burst is the burst's own, as accepted in section 5.
- **Checks:** self-test "Keeper:" 65/65 at 60 fps.
- **Open:** research's look at the rock, in the framing take. From this camera the player's avatar covers the keeper's lower half until Burst.
- **Hours:** about 0.15.

**The swing's and the challenge's looks, in grey (Scintilla, 2026-11-24).** `tools/fx/keeper_moves.py` writes `build/handoff/Lamplighter/fx/KeeperSwing.rows.json` and `KeeperChallenge.rows.json`, from the kit only.
- **Swing:** a pale trail behind the pole's foot (`PoleFoot`), widest on `Strike`, a softer, later one behind the lantern (its weight), a crescent cut where the foot passes. **Challenge:** the lantern's own glow flares on `Lift`; on `Stamp` a hoop opens on the street from the pole's foot, the dust a breath after. Levers: anticipation (the trail grows into the blow), weight (the lantern's lag), punctuation (the cut, the stamp).
- **For Faber:** `Effect = "KeeperSwing"` and `Effect = "KeeperChallenge"` on their actions, and `py tools/fx/rows_take.py` on both files in the same commit (on a scratch copy with all four effects linked, AR52's two included: 2799 passed, 0 failed). Then the review.
- **Content check, before the build: PASS.** Conditions: nothing red to maroon at the finish, the crescent's dark pass included; the dark passes play only with their bright ones; the puff never lies flat; the light's share is measured if two keepers swing at once or the swing quickens; the finished look gets its own check.
- **Status:** implemented as data, not shown in the game; tested offline only; not visually reviewed (item 10); not director-accepted.

**The targets, redrawn on the shaft and the lantern (Scintilla, 2026-11-26, 12:37).**
- **Why:** from the game's camera the pole's foot stays behind your fighter: 11.7 studs deep at Strike, your fighter 10.7, and the stamp lands behind its legs. The first five targets, drawn at the foot, showed only the lantern.
- **The shaft:** the stage sampled only the foot and the lantern, so `tools/fx/keeper_targets.py` solves the hook from the clip's joints, fitted to the sampled foot (0.001 studs). The lantern's path, which the fit never sees, checks it: 0.002 studs mean on the swing, 0.005 on the challenge.
- **The targets,** in `build/handoff/Lamplighter/targets/` (peaks, strips, phone sheets):
  - S4, the smear: the shaft swept into a sheet of light from the hold to the blow, trailing into the follow-through.
  - S5, the lantern's arc: a comet along the lantern's swing, a flare on Strike, the shaft's glint.
  - S6, the echoes: the lantern's afterimages.
  - C3, the pulse: a bead up the shaft into the lantern, which bursts.
  - C4, the wide ring: a ring on the street out to 6.5 studs.
- **My read at phone size:**
  - S4 reads as a sweep beside your fighter's head, S5 as a bright pop with a short comet, and S6 barely reads.
  - C3's burst is the brightest thing on the screen, its ring lost in it. C4's ring shows only on your fighter's left.
  - The whole swing is small on the screen: the pole turns mostly in depth, and the lantern sits beside the "Auto on" plate.
- **Also fixed in the drawer:** your fighter was laid back from the linear picture into the sRGB render, drawn darker. The challenge's tiles showed the HUD's fading ghost; the HUD now comes from the backdrop.
- **For the pick:** the lantern's paper is cyan by its recipe, cold at rest, so its glow reads cyan-white; the light's own hue is the kit's warm.
- **Status:** targets, for research's pick in pairs. Nothing built. Content check: PASS.

**Research's pick, in pairs (Quaestor, 2026-11-26, 12:41; the phone sheets in `build/handoff/Lamplighter/targets/phone_keeper_*/peaks_phone.png`, each pair read in both orders).**
- **The challenge: C4, the wide ring.** It beats C3 both ways. C3's white burst at the lantern is the brightest thing on the screen and says nothing about where to stand. C4's ring on the street does. **Must-fix before the build** (class: the warning's area): the ring reads all the way round. Today only its left arc shows past your fighter, so it needs more width or a faint fill inside it.
- **The swing: S5, the lantern's arc, redrawn once.** It beats S4 and S6 both ways: S4's smear reads as a thin line to your fighter's head, and S6 barely reads. S5 isn't yet clearly good, because the flare is a small pop beside the "Auto on" plate. **The redraw:** the comet runs the lantern's whole path from the hold, so the arc itself is the read, and the flare lands as its end, not on its own.
- **For Faber, not an effect's fix:** in a fight the keeper stands behind your fighter, so its swing plays behind him (the entry's 11.7 against 10.7 studs). The keeper's stand-off, or the fight's camera, decides how much of any swing shows. This is one finding for TR-side staging.

**The redraws, for research's second look (Scintilla, 2026-11-26, 12:51).** Same files, same names:
- **C4:** the ring now runs out to 10 studs, 7.6 at its peak, on a band 0.55 studs wide. A deep warm (#7A4A12) is laid under it, the technique of AR52's day fix, so it holds on the pale street, and a faint fill sits inside it. It now reads all the way round your fighter: its left, near and right arcs, and its far arc behind your fighter's legs. Where that far arc crosses the keeper's robe it draws over it (the stage's known limit).
- **S5:** the comet runs the lantern's whole path from the hold (frame -8, where the lantern starts to move) to Strike and on, a third as wide at its tail, the deep warm laid under it. The flare lands as its end and holds three frames. From the game's camera that whole path is still short, about an eighth of the screen's width from the hook toward its left edge, and it ends under the "Auto on" plate: the staging finding above decides more.
- **Status:** targets. Nothing built. Content check: PASS.

**Research's second look (Quaestor, 2026-11-26, 12:52), on what changed:**
- **C4: picked, for the build.** The ring now reads all the way round your fighter, near arc included. Under the squint it's the frame's one warm shape, on a street it holds. The Challenge is the keeper's entrance (`Enemies.luau`, `Enter`), not a hit area, so its 10 studs warn of nothing false.
- **S5: not picked yet.** The comet is right, but the swing still plays behind your fighter and ends under the "Auto on" plate, so its main read sits half in the HUD's column. That's staging, not the effect's technique, so a third redraw on the same staging would only polish it. **Waits on:** Faber's staging (the keeper's stand-off, or where its swing plays from the game's camera), so the swing crosses the frame beside your fighter and clear of the HUD's left column. Then S5 is redrawn once on it and picked or not.

**C4's build (Scintilla, 2026-11-26, 14:36).**
- **Technique:** the ring as the target's own drawing, two 4x4 flipbooks of its 18 frames (`tools/fx/keeper_targets.py --pictures`): the field and the line. Played once, flat on the street at the keeper's feet from Stamp (Ground, Hold), 10.6 studs to its edge. Under to over: the field laid deep warm #7A4A12, the field added warm, the line added warm white. The Gaze's glow keeps its beats. The hoop and the dust are dropped: the ring is the one hero shape.
- **Status:** implemented and taken (logic offline, 0 failed). Not yet seen in the game: the PC ran short of memory and my Studio turn ended first. The take waits for my next turn. **For Faber's review:** `tools/fx/keeper_targets.py`, `tools/fx/keeper_moves.py`, `KeeperChallenge.json`. `Actions.luau`'s KeeperChallenge comment ("the hoop and dust on Stamp") is now stale.
- **C4 in the game (Scintilla, 2026-11-26, 15:26): the main read missed.** I took it at the stage's camera, by day, slowed 0.2 (`build/handoff/Lamplighter/checkpoint/c4_game_1_strip_vs_target.png` and `c4_game_1_feet.png`).
  - The ring reads as a faint pale swirl on the pale stone, not the target's warm gold band. The added warm and white wash out on bright ground, and the deep field at 0.6 transparency barely shows.
  - The keeper's Challenge clip didn't play in this take (its pose held), so the take's beats are read from the rows alone.
  - **The change, in technique:** AR52's day fix. Paint the ring's band in the target's warm hue (LightEmission 0, close to opaque) and keep the added light to the line's core alone.
  - Next take: my next Studio turn, with the clip checked first.
  - **The change, built (16:29):** RingBand is painted warm amber (#E07A16, LE 0, 0.95 seen), with RingInk (#5C3006, 0.6) a hair outside it, and RingLine's warm white as the only light. The additive band is gone and the shape is the picked one. Logic offline: 8,668 passed. The next take uses the game's own path, where the keeper's spawn plays its Challenge (`Enemies.Enter`), since my own track didn't play.
- **C4 on Lantern Row (Scintilla, 2026-11-26, 18:04): the main read missed again at the player's camera.**
  - **The take:** the Festival place in Play, with the keeper spawned on the street (`FightSpawn`, its Enter playing the Challenge). It was taken at the player's camera, in the street's own light, with no slow. Two stagings:
    - 15 studs ahead of the standing avatar: the keeper stands over the camera, and its feet are behind the avatar.
    - 24 studs ahead, the street's standing Brawlers fighting the lead beside it: `c4_street_life.png`, nine frames 1/15 s apart; `c4_street_pairs.png`, the peak beside C4's target with the squint and grey rows; both in `build/handoff/Lamplighter/checkpoint/`.
  - **What shows:**
    - The ring is a soft amber haze that spreads round the keeper's feet for about 0.3 s, behind the avatar's head.
    - The dark rim and the white line don't show: at this low angle a 0.55-stud band 24 studs off is a few pixels tall.
    - At the squint it's a faint warm smudge. In grey it's gone.
  - **Why the target read and this doesn't:** the target was framed at the stage's camera, close behind the lead, with the ring passing under the lead and filling the frame's lower half. At the player's camera the keeper stands up the street, so the ring is a thin ellipse.
  - **Not yet taken:** the keeper's real entrance at the ground's end. FightSpawn placed it where I chose. Where the keeper stands from the player's camera then decides most of this, as research's staging note on S5 said.
  - **Two techniques have now missed** (the additive field, then the painted band). By the rule, the options go to the director with the images. They're research's to bring:
    1. Keep C4, staged where its feet show. This needs Faber's staging of the keeper's entrance: its stand-off, or the camera at the entrance.
    2. An upright read in place of a ground ring: a warm column or flare at the lantern on Stamp. It reads at a low camera, but it says less about where to stand.
    3. Drop the ring, so the Challenge reads by the clip and the lantern's glow alone.

    My lean is option 1, then one take at the real entrance before the director sees them.
  - **Status:** implemented (dc7106c1, reviewed clean by Faber) and taken in the game at the player's camera. Visually reviewed: my read, a miss; research's verdict waits. Not director-accepted.

### Research's verdict on C4's street take (Quaestor, 2026-11-26, 18:07; `c4_street_pairs.png` and `c4_street_life.png`, read in both orders)

- **Missed, agreed.** At the player's camera, C4's band is a warm smudge at the squint and gone in grey. The target was framed close behind the lead, with the ring filling the lower half. Two techniques have missed, so the options go to the director on their return, with these images and the target.
- **Option 1, narrowed:** the camera stays the player's (the director, 2026-11-14: "simply do not touch player camera"; `docs/design.md`, "The camera is the player's"). So "the camera at the entrance" is out, and only the keeper's stand-off is left, which is Faber's.
- **First, one take at the keeper's real entrance,** at the ground's end and at the player's camera, with no change to the build. That's evidence, not a third technique, so the director sees the real case.
- **Research's lean:** if the real entrance shows the ring all round, option 1. If it shows the same thin ellipse, option 2, an upright warm flare at the lantern on Stamp, from a new target. What sank C3, "says nothing about where to stand", no longer weighs, since the Challenge is an entrance and not a hit area (C4's pick). The flare is warm, not C3's white. Option 3 is the cheapest, but it leaves the keeper's entrance without its light beat.

### C4 at the keeper's real entrance (Scintilla, 2026-11-26, 18:34)

- **The take:** the Festival place in Play, through the gate's own try (`KeeperTry`: the fade, the set-down at the copy's entrance, the keeper's Enter playing the Challenge). Taken at the player's camera with the build unchanged, 60 fps, no slow. The sheets are in `build/handoff/Lamplighter/checkpoint/`:
  - `c4_entrance_life.png`: 12 frames, 1/15 s apart, the keeper's arrival to the ring's end;
  - `c4_entrance_pairs.png`: the widest moment beside C4's target, with the squint and grey rows;
  - `c4_entrance_light.png`: only what the ring lit, against the frame before it.
- **What shows:** the keeper lands about 15 studs ahead and to the right. Its ring is a faint ellipse that spreads left under the lead and the avatar for about 0.3 s. The ellipse is cut on the right by a straight line, so it isn't all round. The rim and the white line don't read. It's a warm haze at the squint and gone in grey. It's the same thin ellipse as on the street.
- **The straight cut** isn't the particle's square: that would cut both sides. It's most likely a floor part a hair above the keeper's spot. I check it on my next Studio turn. If it is the floor, fixing it adds the ellipse's right half and doesn't change the read.
- **Status:** evidence for the options, with no change to the build. Visually reviewed: my read, the thin ellipse. Research's verdict waits.

### Research's read of the real entrance, and the options for the director (Quaestor, 2026-11-26, 18:35; `c4_entrance_life.png`, `c4_entrance_pairs.png`)

- **Agreed: the same thin ellipse.** It's a warm haze under the lead and the avatar for about 0.3 s, gone in grey. Option 1 fails at the real entrance, and the straight cut doesn't change that.
- **For the director, on their return:**
  - option 2, an upright warm flare at the lantern on Stamp (research's lean);
  - option 3, no ring, where the Challenge reads by the clip and the lantern's glow;
  - with option 1's three takes shown as tried.
- **So the director picks between images, not words:** Scintilla makes option 2's target at the real entrance, at the player's camera (its peak frame and a strip of its life, within an hour). Option 3's frame is the same take with the ring off. No build hour before the director's pick.

### Option 2's target and option 3's frame (Scintilla, 2026-11-26, 18:55)

- **Feel line:** the keeper stamps its pole and its lantern answers. Warm light drops down the pole and strikes the street at its foot, so from the player's camera the challenge lands where the keeper stands.
- **Where it's drawn:** on the real entrance's take at the player's camera, frame by frame from Stamp, riding the lantern where the take has it. The boss bar sits just above the lantern there, so the light is drawn under the HUD as the game would draw it, and a tall upward shape would hide behind the bar. Both shapes are warm gold and amber, not C3's white.
  - **F1, the drop:** the lantern flares. A lance falls down the pole, speeding up over 3 frames (the lever: acceleration into the Stamp), and strikes the foot as a flat pool of light with a fan of short sparks. It holds to frame 6, then burns out from the lantern down by 20.
  - **F2, the upright star:** a tall warm four-point star at the lantern, out in 2.5 frames, with a thin ring running out to 1.75 studs by frame 9. It's gone by 16.
- **The images,** in `build/handoff/Lamplighter/targets/`: `C4x_{F1,F2}_entrance_{peak,strip}.png` (peak at frame 3; the strip's frames are in `C4x_entrance_strip.txt`), option 3's `C4x_O3_entrance_*` (the take with the ring's tint put back to the frame before it), and today's `C4x_C4_entrance_*` beside them. The phone and squint sheets of the four are in `C4x_phone/`. The script is `tools/fx/keeper_flare_targets.py`.
- **My read:** F1 stays an upright warm line landing at the keeper's foot at the squint. F2 shrinks to a warm spot at the lantern. Option 3 and today's C4 look almost the same at phone size.
- **The content check:** both pass (rules 2, 3 and 4: only warm light, nothing red, drawn by our script on our own take). One limit for F2 if it's built: a cross in a circle can match a banned symbol, so its arms stay unequal and pointed (2.2 up, 3.0 down) and its level arms stay inside the ring from the first frame.
- **Status:** targets only, for research's pick and then the director's. No build hour.

**Research's pick, F1 against F2 (Quaestor, 2026-11-26, 18:45; `C4x_phone/peaks_phone.png` and `peaks_squint.png`, each pair read in both orders): F1, the drop.**

- **Both ways, F1.** Its lance is one hero shape, with a direction and an acceleration. It comes down out from under the boss bar and lands at the keeper's foot, where C4's ring was meant to say "here". At the squint it holds as an upright warm line. F2 sits behind the boss bar and shrinks to a spot.
- **Gates:** squint as above. O3 against today's C4: no clear difference, both orders, so option 3 costs the challenge nothing that C4 shows today. Effects have no accepted example. The rejected ones are "2d flame" and "2d cartoonish fire" (`docs/research/examples.md`), so the must-fix for a build: every layer of the lance and its pool is light and sparks, never a flame shape.
- **For the director, on their return:** F1 (option 2, research's lean) or O3 (option 3, no ring), as `C4x_F1_entrance_peak.png` beside `C4x_O3_entrance_peak.png`, with C4's three takes shown as tried. No build hour before the director's word.


**Research, 2026-11-26, 23:20: F1 goes ahead in the dev build** (Scintilla). Parking it left the maker idle under the delegation of 2026-11-24, 21:13. F1 and O3 stay with the director as options under the two-techniques rule, and O3 is only the ring off, so its word can still swap them.

- **F1 at the keeper's real entrance (Scintilla, 2026-11-27, 12:20; 1fb167b1):** the Festival place, through the gate's own try, at the player's camera, 60 fps, no slow.
  - **The setup:** the stage picker was closed first, as the Fight press would close it. The debug try skips that press.
  - **The takes:**
    - by day, 54.7 fps;
    - at dusk, 56.8 fps, like the target's light. No dropped frame falls in the strip's frames.
  - **The sheets,** in `checkpoint/`: `f1_entrance_{day,dusk}_{strip,peak}_vs_target.png`, the target above, the same crop and the same frames from Stamp.
  - **Main read: FAILED.**
    - The target's wide gold column becomes a hairline down the pole, with a gold point at its foot. The pool shows as a pale smear by frame 11.
    - The lantern stays cyan through Lift and Stamp, so the Halo and the Flare don't show.
  - **The cause isn't found.** It isn't width alone:
    - At about 30 px a stud here, the Glow beam (1.5 studs at the keeper's scale) and the Halo (3.3 studs) should both show plainly.
    - The suspects: the `Lantern` point on the live keeper (if it's missing, every row riding it is left unplaced), or the beams' facing.
    - The next step is to read both in Studio at my next turn. Per the two-rounds rule, a round changes that cause, never the finish.
  - **Also seen:**
    - The copy's grey arena frames the keeper smaller than the old street take.
    - The boss bar now rises over the keeper's head at about frame 11.
  - **Status:**
    - Implemented.
    - Tested in play: FAILED on the main read.
    - Visually reviewed by me only.
    - Not director-accepted.
- **F1, fix round 1 (Scintilla, 2026-11-27, 12:41), for Faber's review:**
  - **The cause, found from the dusk take at full size:** the rows were built at the target's studs, and the target's stud is too big.
    - The target was drawn at 66 px a stud (`keeper_flare_targets.py`, `PX`, from "the keeper stands about 500 px tall").
    - At the entrance the game draws about 26 px a stud:
      - the lantern (3.5 to 4 studs across) is about 90 px wide, both in the target's own view and in the take;
      - the lance's beam measures the same.
    - So every layer stood at two fifths of its target: the lance 5 px where the target has 20.
    - The halo and the flare were also smaller than the lantern. They sat at its middle, and cards are depth-tested, so the lantern hid them. That's why it never warmed.
  - **The change:** in `tools/fx/keeper_moves.py`, every F1 size is the target's times 2.5 (`SEEN`): the beams' widths, the lance's top over the lantern, the pool, the point, the sparks and the light.
    - The two cards now take the target's glow radius through fx_glow's own falloff (`FALL`). The halo is 11 to 13 studs, so its light shows round the lantern. The flare is 4 to 5.6.
    - Timings and colours are unchanged. Taken: logic offline 10,736 passed, 0 failed.
  - **Left, if the take shows it:** the flare's hot middle stays inside the lantern. Drawing it in front needs a card offset toward the camera, `BillboardGui.StudsOffset`, which a Card row can't carry yet (Faber's code, asked only if the take needs it).
  - **Status:**
    - Implemented. Faber's review of its data: PASS (rows parse, pictures present).
    - Tested in play: FAILED (the next block).
    - Visually reviewed by me only.
    - Not director-accepted.
- **F1, round 1 in play (Scintilla, 2026-11-27, 13:38):** at the Festival entrance at dusk, 60 fps. After the Rojo sync, Studio held round 1's rows (the Halo at 11.11 studs, read in Studio before the take). The sheets: `checkpoint/f1_dusk_r1_{strip,peak}_vs_target.png`.
  - **Main read: FAILED, as before.**
    - The lantern flares white at the Stamp, but no warm halo shows round it.
    - The column is a thin gold line, about a third of the target's width, and the Glow's haze never shows.
    - The foot's sparks and the warm light on the ground (frames 7 to 16) show.
  - **Round 1's cause is disproved for the cards.** A halo 11 to 13 studs wide can't hide behind a 4-stud lantern.
    - Measured: no warm gain round the lantern from frame 2 to 7. It rises only at frame 11, from the ground's light.
    - So the cards and the wide beams aren't drawn at all, and size isn't the cause.
  - **Next, round 2: find the cause before any change.** Read the live rows in Studio, frozen at Stamp + 4:
    - each card's position against the `Lantern` attachment, its size and its ImageTransparency;
    - each beam's widths, transparency and ends.
    - A cause inside Rows is Faber's. If a second round fails on the same cause, the technique changes.
