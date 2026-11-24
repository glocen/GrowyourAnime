# Animation craft for script-keyed clips: anime energy on an R6 body

A cloud research study, 2026-11-24, for Modulo (clips) and the builder (how the game plays them). Read-only on main. Every number is a seed to tune by playing. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED (computed here), OPINION.

## Verdict

1. **Our method is sound engineering and under-directed timing.** Clips are already pose-to-pose with named eases, arcs, markers and an audit. What they lack is the anime rhythm: a long held prepare, a strike of one or two frames, a held finish.
2. **The body is the hard limit.** R6 has six rigid bars and no scale, so there is no squash, no bent limb, no drawn smear. Energy has to come from bigger whole-body poses, timing, cloth and weapons, and a smear the game adds.
3. **Our own audit punishes snap.** `r6parity.py` fails a one-frame turn that isn't on a marker, and the brief's ten-point clip check has no line on holds, strike length or pose size.
4. **Roblox is not in the way.** A per-frame baked KeyframeSequence carries stepped timing exactly; `AdjustSpeed(0)` is the hitstop; markers and our beat clock already exist.
5. **Do one cheap trial before re-timing anything:** one clip in three timings, in the replay, on a phone, for the director's pick.

## 1. How we animate today (OBSERVED)

- **The pipeline.** A Python script per character (`tools/blender/<name>_clips.py`) keys an exact R6 rig built from Motor6D C0/C1 (`r6anim.py`, `r6rig.py`). Each clip is a function of `t.key(frame, label, ease, **changes)` calls on a 60 fps timeline, starting from a `HUB` stance dict. Feet are planted by a solver. Eases are named (`rook_clips.py:49`: BEZIER auto by default, `in` cubic, `out` quart, `snap`, `hold` constant, `lin`, `sine`, `back`, `cubic`).
- **The export.** `r6anim.export` bakes one pose per frame at 60 fps to JSON; `tools/studio/Animations/Author.SaveBaked` writes a KeyframeSequence with every pose `Linear`. So Blender's curve shape is what plays, and a CONSTANT segment becomes a hold then one 16.7 ms move.
- **The game.** `Config/Animations.luau` holds fades (Combo in 0.06 s, Hit in 0.03 s, Idle 0.2 s), rig reaction sets, layers (Kirra's scarf one priority above the shared reaction), mirrors, and walk strides. `FighterController` plays an action at `Action`, a reaction at `Action2`, a layer at `Action3`; effects hang on `Definitions.Actions` beats by a server clock, not on marker signals (only `ShadeBurst` uses `GetMarkerReachedSignal`). Hitstop is `Config.Combat.Hitstop` by rung (0.045 s ordinary to 0.14 s keeper), applied with `AdjustSpeed`.
- **The method on paper.** `ga-action`: feel line, named beats in the Definition (startup, active, recovery, hitstop), blockout, build, review. The brief (`docs/briefs/asset-maker.md`) says "an animator first", then lists ten checks: nine are mechanical (clipping, floor, planted feet, parity, markers) and one is craft ("arcs and spacing on the sheet").
- **Secondary motion.** Kirra's eight-link scarf is driven by a few keyed numbers (aim, curl, ripple, trail). The Lamplighter's lantern is a real pendulum simulated at bake (`lamplighter_clips.py:223`). Both are good and are one-offs.

**Limits.**
- Pose and timing are fused: poses are typed inline with their frame numbers, so a retime means editing every `t.key`, `t.tail`, `t.blade` and marker by hand.
- A `t.key` sets the whole body on one frame. Offsets exist only where someone added a `t.arm` breakdown.
- R6: torso, head and four straight limbs. A Motor6D Transform is a CFrame, so nothing scales. I found no clip script that passes `knees=True`, though `r6rig.py:53` defines a knee joint.
- "The player's camera" in the sheets is assumed: `rook_clips.py:35` says "GAME is assumed", and `r6anim.py:1004` reads `src/shared/Config/Camera.luau`, which is not on main. The game uses Roblox's own camera, which the player orbits.

## 2. The craft, with sources

| # | Finding | Label and source |
|---|---|---|
| 1 | **Prepare long, strike short, relax long.** Action is drawn on twos (12 drawings a second); the strike is often one drawing with "a brutal change of pose"; the camera shake runs on ones over it. | SOURCED: [Demon Slayer visual grammar](https://jbsiraudin.github.io/blog/demon-slayer-visual-grammar) (also in `vfx-quality.md`, finding 1) |
| 2 | **A measured sword swing:** 43 frames at 60 fps from 14 drawings. Build-up 13, anticipation 16 (one pose held 10), snap 4 (1-1-2), contact held 8 or more. The strike is 9% of the time. Smears show 1 to 2 frames. | COMMUNITY: [Fire Emblem animation breakdown](https://lost-worlds.neocities.org/blog/2024/10/20/fire-emblem-animation/) |
| 3 | **3D that reads as anime treats every frame as a key.** Guilty Gear Xrd tried full animation and rejected it because it "looked more 3D"; poses are set by hand with no interpolation, with scale and mesh deformation per key. | SOURCED: [Game Watch report](https://game.watch.impress.co.jp/docs/news/20150307_691725.html); COMMUNITY (an AI summary of the talk, so unverified in detail): [videohighlight](https://videohighlight.com/v/yhGjCzxJV3E). Handout PDF: not fetched |
| 4 | **Pose-to-pose, effects carry the motion, in-betweens last.** Dead Cells' attacks are "essentially pose-to-pose"; interpolation frames go "before or after the key frames", once the keys read. Timing was changed "dozens of times in minutes". | SOURCED: [Vasseur, Game Developer](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-) |
| 5 | **Overshoot the extreme, then hold the key longer than feels natural.** Offset the arms so they don't move as twins. Break the rig for a sharper frame. An idle states personality through stance. | COMMUNITY: [summary of Overwatch's GDC talk](https://babel.speldesign.uu.se/?p=113918) |
| 6 | **One frame of anticipation already helps. One frame of overshoot adds power.** A smear shows start, path and end in one frame. Hair and cloth fill the gaps in-betweens would. Silhouette is the main tool. | COMMUNITY: [80.lv on Cartwright's Skullgirls talk](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations) |
| 7 | **Holds:** a moving hold keeps a few degrees of drift; a dead hold is a freeze. "The longer you hold an antic, the faster the action can be." A weak pose held is an awkward freeze; a strong one is a statement. | COMMUNITY: [Art of the Hold](https://anim.works/?p=25924) |
| 8 | **Frame data, light against heavy** (60 fps; hit frame / total). Ryu in Smash: jab 2 / 15, forward smash 15 / 45. Ganondorf: jab 7 / 26, forward smash 29 / 69, Warlock Punch 70 / 117. Street Fighter 6 Ryu: light punch 4 startup, 3 active; heavy punch 10 startup, 5 active. | COMMUNITY: [ultimateframedata, Ryu](https://ultimateframedata.com/ryu), [Ganondorf](https://ultimateframedata.com/ganondorf). SF6 from a search snippet of GameSkinny; the page itself wasn't fetched |
| 9 | **What that data says.** Recovery is longer than startup on almost every move (jab: 1 frame before the hit, 13 after). A heavy character has about 2x the startup and 1.5x the total of a light one. The strike itself stays 2 to 5 frames whatever the weight. | MEASURED from row 8 |
| 10 | **An enemy attack has five phases:** opening pose, signal, attack (hitbox 2 to 4 frames), end pose, return. Signal plus attack of 340 ms or more is readable; the end pose holds 170 ms or more; the return is the longest phase. | COMMUNITY: [Anatomy of an enemy attack in Dark Souls 3](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) |
| 11 | **Players get short or hidden anticipation, enemies keep it all.** Weight goes into follow-through. A swing can be its own object that outlasts the body's move. | COMMUNITY: [12 principles for game animation](https://www.gamedeveloper.com/game-platforms/12-principles-for-game-animation) |
| 12 | **Walks and runs** (24 fps, frames a step): 12 a natural walk, 8 a slow run or "cartoon" walk, 6 a run, 4 a very fast run. The contact and passing poses carry the character; the rest is adjustment. | COMMUNITY: [a summary of Williams](https://s184753.blogspot.com/2019/01/more-research-animators-survival-kit.html), and row 5 |
| 13 | **An illustrative kick at 60 fps:** 3 anticipation, 6 acceleration, 2 hit pause, 10 recoil, 4 "personality". | COMMUNITY: [Prolific](https://prolificstudio.co/blog/exaggerated-animation/) (one studio's example, not a standard) |

**For us, line by line.**
- Rows 1, 2, 7: every attack clip gets a held prepare and a held finish. Today most contacts last one baked frame (section 7). Modulo.
- Rows 3, 4: don't step whole clips on a block body without trying it first. Guilty Gear's look leans on hand deformation we can't do. Snap the strike and keep recoveries eased; the trial in "Top 5" settles it. OPINION.
- Row 4: split poses from timing in the scripts (section 4). Modulo.
- Rows 8, 9: weight lives in the anticipation and the recovery, never in a slow strike. Rook's gaps (0.6 s between hits) against Kirra's (0.23 to 0.5 s) already follow this. OBSERVED in `Definitions/Actions.luau`.
- Row 10: the Shade's Attack reaches its tell pose at 0.27 s and hits at 0.5 s, so it clears 340 ms. Its tell is held only 0.1 s (`shade_clips.py`, frames 16 to 22).
- Row 12: `ShadeWalk` is 0.4 s a step, 9.6 frames at 24 fps: between the cartoon walk and the natural one. Fine for a creature that drifts.

**Screen size, which decides pose size** (MEASURED; assumes Roblox's default 70° field of view and a 12.5-stud zoom, the numbers `Config.World.Fit.Camera` uses).
- The screen shows 17.5 studs of height. A 5-stud fighter is 29% of it: about 206 px at 720p. One stud is about 41 px. An enemy 25 studs away is half that.
- Kirra's idle bounce is 0.10 stud (`crouch` 0.04 to 0.14): about 4 px. It can't be seen. Her idle's life is the scarf alone.
- A 10° torso lean moves the head about 0.5 stud: 20 px. A pose change that must read needs an extremity (head, fist, weapon tip) to travel 1 stud or more. OPINION for the threshold.
- From behind the lead, motion straight back or forward is along the view and barely reads. A reaction needs twist, a side lean or a drop in height. OPINION.

## 3. Roblox facts, 2026

- **KeyframeSequence.** Keyframes hold Poses; each Pose has an easing style (Linear by default, Constant, CubicV2, Elastic, Bounce; Cubic is deprecated) and a direction (In, Out, InOut). The Animation Editor defaults to 30 fps. SOURCED: [PoseEasingStyle](https://create.roblox.com/docs/reference/engine/enums/PoseEasingStyle), [Animation Editor](https://create.roblox.com/docs/animation/editor).
- **CurveAnimation.** One curve per channel; modes Linear, Constant, Cubic with tangents. Converting a sequence adds keys, and a conversion to Euler angles can't be undone. SOURCED: [Curve Editor](https://create.roblox.com/docs/animation/curve-editor). **Constant keys in curve animations are reported to interpolate as linear** (opened 2025-10-01, a repro place posted 2026-11-08, not confirmed fixed). COMMUNITY: [DevForum 3970472](https://devforum.roblox.com/t/3970472). For us: stay on baked KeyframeSequences.
- **Stepped timing from Blender.** Blender's FBX exporter has turned Constant keys into Linear (an old report, fix unknown). COMMUNITY: [Blender issue 76928](https://projects.blender.org/blender/blender-addons/issues/76928). It doesn't touch us: our JSON bake has a pose on every frame, so a hold is exact. OBSERVED.
- **Priorities and blending.** Seven levels, Core to Action4. A higher priority wins per joint; equal priorities blend by weight. `Play(fadeTime 0.1, weight 1, speed 1)`. `AdjustSpeed(0)` pauses. `TimePosition` can be set only while playing. `Length` is 0 until loaded. SOURCED: [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack).
- **Markers.** `GetMarkerReachedSignal(name)` fires with one string parameter. The docs don't say what happens when `TimePosition` is set past a marker. SOURCED: [Animation events](https://create.roblox.com/docs/animation/events). For us: keep the beat clock as the source and markers as the self-test's cross-check, as now.
- **Replication.** A client-played track replicates only on that player's own character, or a model the client owns. Any other Animator must be played on the server, or on each client, which is what we do. SOURCED: [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator).
- **Throttling.** `Animator.PreferLodEnabled` is true by default: the engine may evaluate remotely simulated characters less often, by distance and frame budget. SOURCED, same page. For us: a one-frame pose on a Shade can be skipped. Try `PreferLodEnabled = false` on the lead and its target only, and measure the cost. The builder.
- **Limits.** 256 tracks per Animator; load once and cache. COMMUNITY: [DevForum 2577096](https://devforum.roblox.com/t/2577096). No documented length limit; an older editor capped at 30 s. COMMUNITY: [DevForum 3277097](https://devforum.roblox.com/t/3277097). Our longest clip is 4 s.
- **Ownership.** Since 2025-08-21 an animation's Permissions page has Collaborators and Experiences tabs: the owner can grant a universe by id, and a grant can't be revoked. SOURCED: [staff post](https://devforum.roblox.com/t/3892540), [asset privacy](https://create.roblox.com/docs/projects/assets/privacy). Our group-owned clips in the group's game need nothing. AGENTS.md's "Roblox plays only the owner's" is now "the owner's, or a universe the owner granted".
- **Rigs.** A rig is parts joined by Motor6D-style joints or Bones; R15 can use Roblox's own animation library, R6 and custom rigs can't. SOURCED: [Animation overview](https://create.roblox.com/docs/animation). Poses carry CFrames, so no rig scales. OBSERVED in our export.
- **30 or 60.** Roblox interpolates between keyframes at the render rate. A phone at 30 fps samples our 60 fps bake every second frame, so a pose that lasts one baked frame is missed half the time. **Rule: nothing that must be seen lasts less than 2 baked frames (1/30 s).** OPINION from the sampling.

## 4. The recipe

**Pose first.** Name the poses, get the sheet's yes, then time them. A retime touches only the chart.

```python
POSES = {"stance": HUB, "antic": {...}, "smear": {...}, "contact": {...},
         "over": push("contact", 1.12)}        # a pose pushed 12% further from the stance
CHART = [  # frame at 30 fps, pose, ease into it, frames held, parts that arrive late (+) or early (-)
    (1, "antic",   "out",  2, {"H": +1}),
    (3, "smear",   "hold", 0, {}),
    (4, "over",    "hold", 1, {"cloth": +2}),   # marker Hit
    (5, "contact", "out",  3, {}),
    (8, "stance",  "sine", 0, {"RA": +2, "H": +1})]
```

**Six actions at 30 fps** (double every frame for our 60 fps timeline). S / A / R is startup, active, recovery. OPINION seeds built from section 2.

| Action | Total | S / A / R | Frame by frame | Holds |
|---|---|---|---|---|
| Light attack | 14 (0.47 s) | 4 / 1 / 9 | 0 stance; 1-2 antic; 3 smear; **4 contact**, overshot; 5-7 held contact; 8-13 recover. The next hit may cut in from 7 | antic 2, contact 3 |
| Heavy attack | 30 (1.0 s) | 14 / 2 / 14 | 0-2 into antic; 3-10 antic, creeping back; 11-12 "drawn back a hair"; 13 smear; **14 contact**; 15-20 held; 21-29 recover, weight shifts at 24 | antic 10, contact 6 |
| Signature | 66 (2.2 s) | 26 / 2 / 38 | 0-3 the tell pose; 4-21 charge; 22-23 extra wind; 24-25 smear; **26 contact**; 27-38 the finish pose; 39-65 recover, one flourish near 48 | charge 18, finish 12 |
| Dodge or step | 16 (0.53 s) | land on 10, our Skip's beat | 0 crouch; 1-2 stretched launch; 3-9 one air pose, cloth streaming; **10 land**, low; 11-12 held; 13-15 rise | air 7, landing 2 |
| Hit reaction | 11 (0.37 s) | none | **0 the struck extreme**, fade 0.03 s or less; the game's freeze sits here; 1-2 carried 10% further; 3-5 back through the stance to 20% past it; 6-10 settle | extreme 3 |
| Knockdown, then get-up | 25 down, 26 up | none | Down: 0 struck, 1.6x the flinch; 1-3 held; 4-10 fall, speeding up only; **11 land**; 12-14 bounce 0.3 stud; 15 second contact; 16-24 limbs arrive 2 to 4 frames after the torso. Up: 0-6 gather, slow; 7-10 push, fast; 11-15 rise 0.1 stud too tall; 16-25 settle, eyes on the enemy from 8 | launch 3, lying as long as the game says |

- **Weight.** A heavy fighter takes 1.5x the antic and the recovery, the same strike. A light one takes 0.75x, a 1 to 2 frame antic and one more cloth swing.
- **Constant or eased.** Into a hold: quart out. The hold itself: two keys 2° to 3° apart on a sine. Antic to smear to contact: constant, or one frame of linear. Out of the contact: back or quart out. Recoveries and idles: sine or cubic, on ones. Never the same ease on two segments in a row.
- **Smear, cheapest first.**
  1. A pose: the breakdown sits two-thirds along the arc with the chest and the weapon ahead of the hand. Free.
  2. A stretch: the weapon part's `Size` goes 1.5x to 2.5x along its travel for one frame at 30 fps, set by the client on a `Smear` beat. To test: the part scales about its centre, so offset it.
  3. A ghost: one to three clones of the weapon or limb left at the last poses, fading over 0.1 s.
  4. A layer: a Trail or a crescent mesh between the `Smear` and contact beats, alive 0.08 to 0.12 s. Scintilla's.
  - Use one when a tip travels more than about 1.5 studs in a frame at 30 fps. OPINION.
- **Follow-through, by chain depth** (link i of n, root first). OPINION seeds; no source gave numbers.
  - Lag: i frames at 30 fps for stiff things (a blade, short hair), 1.5 i for a scarf or a coat tail, 2 i for a ribbon or a lantern.
  - Size: a light chain swings wider toward the tip, by (1 + 0.5 i / n). A heavy one doesn't.
  - Settle: a damped swing. Hair 3 Hz, gone in 0.25 s. A scarf 2 Hz, 0.5 s, two overshoots. A heavy coat 1.2 Hz, 0.8 s, one.
  - Build it once as a spring follower run at bake (stiffness (2πf)², damping ratio 0.25 to 0.5, 4 substeps a frame). `swing_lantern` already is one.
- **Hitstop and the clip.**
  1. The frame on the contact beat is the overshot pose: a frame worth freezing. Check it as a still.
  2. On the beat, in one render frame: the effect's main shape, the sound, and the victim's Hit clip already at its struck extreme. Then both bodies freeze for the rung's hold.
  3. During the freeze the cloth layer keeps moving at a quarter speed, so it's a moving hold. To try.
  4. The held contact pose stays in the clip. The freeze happens only when a hit lands; a miss still needs the hold.

## 5. Ten pass/fail questions, from the player's camera, at real speed

1. At 64 px and filled black, does each key pose name its action, from three headings (behind-right, side, front-quarter)?
2. From antic to contact, does an extremity travel 1 stud or more across the screen, not along the view?
3. Is there one frame you'd print: a contact or finish pose held 3 frames or more at 30 fps?
4. Is the strike 2 frames or fewer at 30 fps (3 for a heavy)?
5. Is the recovery longer than the startup (light), and the antic hold at least twice the strike (heavy)?
6. In every hold over 4 frames, does something still move, and is nothing frozen by accident?
7. Do the parts arrive on different frames: hips, chest, arm, weapon, cloth?
8. With the effect and sound off, does it still say light or heavy? Frozen at contact, does the effect sit on the weapon's arc?
9. Blended from idle and from walk, and cut by a Hit at its three worst frames: no part through the body, no foot sliding 0.1 stud?
10. Ten plays in a row: is there a tic you notice by the fifth (a head tilt, a twin arm bob, a seam)?

## 6. Six reasons scripted animation looks robotic

| Reason | Fix |
|---|---|
| Everything starts and stops on one frame, because one call keys the whole body | per-part offsets in the chart: hips lead, the weapon lands 1 to 2 frames late, the head 1 |
| The same ease on every segment (auto Bezier floats, linear is a machine) | an ease chosen per segment: fast out of the antic, slow into holds |
| No holds, or dead ones | a moving hold on every antic and contact |
| Twins: both arms mirror each other on the same frame | 10° to 20° and 1 to 2 frames apart, unless symmetry is the idea (the Guard) |
| Poses sized by what looks right up close | push each key 30 to 50% further; judge at 64 px; count studs travelled |
| Parts arrive and stop dead; cloth is keyed, not swung; loops repeat exactly | a 10 to 15% overshoot for 1 to 2 frames, spring followers, one off-beat accent a loop |

## 7. Our clips against the recipe

- **`KirraCombo`** (`kirra_clips.py`, `combo`; frames at 60 fps). MEASURED from the script.
  - Contacts at 12, 26 and 56. Each lasts one baked frame; the next key, 4 to 5 frames on, is already 24° to 83° further. There's no overshoot and no held pose. The only freeze is the game's 45 to 50 ms, and only on a hit.
  - The finisher is the slowest strike: 12 frames (0.2 s) from "both low behind her" to Hit3, against 3 for the draw. It should be the fastest.
  - Twins: Hit3 is `RA=(112, 0, 14)`, `LA=(112, 0, -14)`; the wind is `(-50, 0, ±22)`.
  - Good: the scarf has its own keys a beat behind the body (13 and 31 against 12 and 26).
  - Fix: the rise in 6 frames; hold the top pose 6 to 8 frames with the lift carried, so she hangs; split the arms by 15° and 2 frames; one overshoot frame on Hit1 and Hit2.
- **`RookHit`, the open set's flinch** (`rook_clips.py`, `hit`).
  - Good: struck by frame 3 on a quart-out, and it twists (16°), which reads from behind.
  - It returns straight to the stance from frame 7 with no swing past it. `ShadeHit` does swing past ("the hem swings after it") and is the better clip.
  - One size for every blow: the rung changes the freeze, the flash and the tremble, never the pose. A jab and the Haymaker get the same flinch.
  - To check in Studio: is the body at its struck pose when the freeze starts, or still blending in?
- **`ShadeLunge`, published** (`shade_clips.py`, `lunge`). The house example: a tell pose at 0.27 s, 0.73 s nearly still with a last "drawn back a hair", gone in 4 frames, the mask arriving at 81 and the rest at 88, then 0.8 s open. Use it as the template.
- **The audit and the brief.**
  - `r6parity.py:528`: a joint that turns more than 3x its neighbours' in one frame fails as a "Pop" unless it's within 1.5 frames of a marker. A two-frame snap passes; a one-frame snap or anything stepped fails. Add a way to declare a snap.
  - The brief's checklist has no line for a held contact, strike length, pose travel or twins. Section 5 can supply them.
- **The idles.** Kirra's and Rook's body motion is under 5 px at 720p. After the director's word of 2026-11-17 (no head tilt), an idle's life has to be the stance's asymmetry, one large secondary (scarf, weapon, coat) and a rare weight shift.

## Top 5 to act on

| # | What | Who | Cost | Needs the director's yes? |
|---|---|---|---|---|
| 1 | **One clip, three timings:** `RookHaymaker` (or `KirraCombo`) as it is; with a snapped strike and held contact; and stepped on twos throughout. Judged in the replay on a phone | Modulo, the builder installs | about 3 h | no to try (a blockout, tier 1). The pick becomes the house timing: research and the director |
| 2 | **Poses apart from timing:** `POSES` and `CHART` in the clip scripts, with per-part offsets, `push`, a moving-hold helper, and a spring follower lifted from `swing_lantern` | Modulo | half a day | no, its own lane |
| 3 | **Fix the instruments:** a declared snap in `r6parity`'s Pop rule; section 5's questions in the brief's clip check; sheets from three headings | Modulo for the audit, research for the brief | 2 h | no |
| 4 | **Reactions that sell the blow:** a swing past the stance in the open set's Hit, and a heavy flinch (1.6x, a foot steps) for rung 4 and up | Modulo, then the builder | 3 to 4 h | tier 2 for the heavy flinch: `docs/design.md`, "States in a fight", has one Flinch for "any hit" and one shared reaction set per rig. The swing past the stance is Modulo's own call |
| 5 | **A smear kit:** the weapon stretch, two ghosts and a trail between a `Smear` beat and contact, in grey on one action | Scintilla with the builder | 2 to 3 h | no to try |

Not proposed now: an elbow or knee on the leads. It's the one structural lever left, and it reopens the director's "A" of 2026-11-15 (the R6 body), so it would need their yes.

## Not fetched

The Guilty Gear Xrd handout PDF (503); Dustloop, SuperCombo and Capcom's own frame data (blocked); GameSkinny's SF6 table (search snippet only); the transcripts of two animation breakdown videos (403); a thesis on smears in Overwatch (403). GDC talks were read through write-ups only, never watched.
