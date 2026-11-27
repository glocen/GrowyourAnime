# TR7. Rook, Pip and Lyric installed (Faber, with AR1 and AR4)

Research's entry, 2026-11-13, at Faber's request. Phase 2's "Rook, Pip and Lyric finished and timed" (`docs/production-plan.md`). It comes first in the queue, before TR5 and TR6.

**Feel line:** on a phone, in a pack fight on Lantern Row, each of the three fights in a way you can see. Rook plants and hammers. Pip skips back out of reach and lobs fire. Lyric keeps her distance and sings the pack back. The fight always sits clear of your own avatar, right of centre, so every landing reads.

**The block contains,** in this order, each judged in motion at phone size before the next:
1. **The framing,** in grey, from Faber's three variants. Each is judged in a pack fight and a keeper's try.
   - **A. A shoulder camera in a fight:** an ease of about 2.5 studs right and 1 up while the lead is engaged.
   - **B. Geometry only:** `Lead.Frame` 70 and `Keeper.Turn` 40.
   - **C. The keeper holds the ring's middle,** plus A or B for packs.
   - **The checks:**
     - the avatar never covers the lead or its target;
     - Haymaker's landing reads as the slam (AR8, B5's final);
     - the hang clears the Target card;
     - the pole's rock reads (AR7);
     - the keeper's lantern and look down share a shot (AR8, the keeper's signature).
   - **For A:** the ease is gentle, about 0.4 s. It eases back only after the fight has been over about 1.5 s, so a lead stepping in and out never makes the camera swim. It never takes the player's own drag of the camera.
2. **The skip back,** for Pip and Lyric, through `/ga-action`, as designed in `docs/design.md`, "Combat". In the block, the body plays Modulo's block clip, or a held pose if it isn't in yet. It closes on its balance check: ten runs with the skip and ten without, within 10%.
3. **The three passives,** from `docs/roster.md`, short and simple (the director, 2026-11-13), each with a grey cue readable at phone size where it has one. The numbers are seeds: tier 2, research's, tuned by playing, with Faber's view in his row.
   - **Rook's Second Wind:** below 30% health he takes 20% less damage. Its cue is a faint shell round him while it holds.
   - **Pip's Kindle:** his combo's third shot adds Fire damage worth 40% of that shot, as its own coloured number. Its cue is the lantern flaring on the shot.
   - **Lyric's Tempo:** Held Note's cooldown is 20% shorter. It needs no cue: the song comes round more often.
   - The three must leave the balance check within 10% of each other's time to clear Lantern Row's first pack at their level. A passive can't close a gap in the combos, so the band is settled at the timing (part 4), with the combos open (research's verdict, 2026-11-14).
4. **Timed:** each lead plays its whole kit in real fights, not the replay: combo, signature on its cooldown, passive. Haymaker's hitstop and camera numbers get set by playing (B5's "Not done").

**Waits:**
- the skip clip's finish (its block clip is Modulo's, made now: `docs/design.md`, "Combat");
- the passives' art;
- the states, Burn and Shock included (with the Lamplighter as a real fight);
- Rook's evolution;
- the finish pass on the signatures (`docs/polish-later.md`).

**Verdicts:**
- the framing's blockout;
- the skip back's blockout (`/ga-action`);
- the passives together;
- the final, from QA's pack once QA has joined, else Faber's takes, with fresh eyes on the framing.

**Order in the queue:** first. **Time, forecast:**
- the framing, about 1 hour;
- the skip back with its check, about 2;
- the passives, about 1.5;
- the timing, about 0.5.

**Research's verdict on the framing's blockout (2026-11-13; `build/captures/tr7/`, the sheets and the mp4s, Rook leading, phone size): A for every fight, with `Keeper.Turn` 40.**
- **Felt:**
  - Before, the fight happens behind your own back: the keeper stands at the avatar's right shoulder, and a pack climbs over the avatar's right side.
  - With A and Turn 40, the avatar steps to the left third, and the keeper's fight stands on its own in open floor right of centre. The fall's pole and lantern stand alone against the sky.
- **Tier:** competent in the keeper's try. Works in a pack: at 2.5 studs the avatar still overlaps the pack's left edge in about half the frames.
- **The one bold thing:** the keeper's fall in row 5, a lone pole against the sky with nothing in front of it.
- **Picked:** A plus `Keeper.Turn` 40. `Lead.Frame` stays 45.
  - B loses: Frame 70 spreads a pack round the avatar and puts one between it and the camera.
  - C loses: it's no clearer than A, and it changes the keeper's character, which is no framing fix's to change.
- **Fixes, for the build:**
  1. **The offset is a Config number, tuned by playing in a pack.** Try 3.5 studs right beside 2.5, and keep the smaller one that leaves the lead and its target uncovered in nine frames of ten. The 1 up stays.
  2. The 0.4 s ease, the 1.5 s hold and the player's free drag stay as tried. The final judges them in motion.
- **Carried to the build's take:** Haymaker's landing as the slam, the hang against the Target card, the keeper's look down. The keeper's hat under the Target card is TR5's to fix, and so is a level-up banner over a keeper's fall.

**The build and its take (Faber, 2026-11-13, 21:58 to 22:20).**
- **In the game:**
  - `Config.Combat.Shoulder` (Right 2.5, Up 1, Ease 0.4, Hold 1.5) and `Keeper.Turn` 40.
  - The rule `Rules/Fight.ShoulderShare` has a logic case.
  - `FighterController/Shoulder.luau` sets `Humanoid.CameraOffset` before the camera each frame, so the drag stays free. A self-test case checks that it eases in, holds, and eases back.
  - Checks: type check 0 new; logic 3897/3897; self-test "Camera:" 10/10 at 60 fps.
- **Fix 1, the offset, measured in pack fights.** The offsets took turns every 1.1 s within one fight, so each was judged on the same fight. "Uncovered" means the avatar's body hides at most a tenth of the lead's and the target's points, by rays from the camera.

  | Where the avatar stands | Right 0 | Right 2.5 | Right 3.5 | Right 4.5 |
  |---|---|---|---|---|
  | 14 studs from the pack's middle | 32/35 | 29/30 | 25/26 | 27/27 |
  | In the pack, 8 studs | 15/45 | 19/45 | 14/41 | 14/40 |

  - In the pack, raising the camera instead (Up 1, 2, 3 at Right 2.5) does no better: 14/32, 15/36, 13/26.
  - A target straight ahead at 8 studs needs about 7 studs of offset to clear the body (geometry), so there it's the avatar's place that covers the fight, not the camera's.
  - **2.5 stays:** 3.5 buys nothing measurable. This in-the-pack case is likely what the "about half" in the verdict saw (`build_pack_close8.jpg`).
- **The take,** in `build/captures/tr7/build_*`, phone size, Rook leading:
  - **Haymaker's landing:** in a real pack fight, the square drops through two frames and lands on the target's feet on Strike, with the target flashed white. It squashes, with its bars on the floor, on the next frame (`build_pack_landing.png`). To me it reads as the slam.
  - **The hang doesn't clear the card.**
    - On a Shade, the Target card covers the square's lower half from its forming to its drop, about 0.27 s (`build_pack_hang.png`).
    - Against the keeper, the square's foot sits Clear over the keeper's top, so it hangs above the frame and only its foot shows (`build_try_hang.png`).
    - A Shade's head leaves no room between it and the card, so the square's height isn't the lever.
  - **The keeper's look down:** the lantern raised in open sky over Rook and the hat tipped down toward him, just under the card, share one shot (`build_try_lookdown.png`). The signature was forced in a try: it has no place in the keeper's own fight yet. The card sits between them through the lantern's descent, which is TR5's.
  - **The pole's rock:** the pole stands alone in open sky right of the avatar and leans a few degrees each way. Then its light goes out and the scraps rise (`build_try_rock.png`). It reads at phone size, small.
- **Research, your call, the hang:**
  - On a Shade: (a) TR5's card fades while the player's own lead's signature hangs, about 0.35 s; or (b) it stays.
  - Against the keeper: (c) the square's foot is capped so its top stays inside the frame. It would then cross the keeper's hat, so the content check reads it again. Or (d) it stays, since the drop still lands in the frame.
  - My pick is (a) and (d): the keeper's card changes in TR5 anyway.

**The skip's block clip (Modulo, 2026-11-13, 21:07 to 21:25 UTC, about 0.3 h of its 1-hour cap).**
- **Delivered:**
  - `build/handoff/Pip/clips/Pip_Skip.json` and `build/handoff/Lyric/clips/Lyric_Skip.json`;
  - each with its `pack_Skip`;
  - each with its entry in `Pip.clips.json` or `Lyric.clips.json`.
- **The clip:**
  - It runs at 60 fps and doesn't loop: Pip's is 33 frames, Lyric's 34.
  - It moves in place; the body's travel is Faber's.
  - The beats: a gather to 5, off at 9, the top at 15 (0.36 studs up for Pip, 0.34 for Lyric), and **`Land` at frame 21, 0.35 s**, in a ready crouch.
  - The settle to the stance runs from 21 to the end. The next action may cut it at Land.
- **The props, keyed:**
  - Pip: the lantern is left behind, low, and bobs up after him. The hat floats at the top and sits a beat after his boots land.
  - Lyric: the stand comes up in her fist and goes down on Land. The speakers lag, swing in, and thump once on Land.
- **Checks:**
  - Legs swing 8° (Pip) and 9° (Lyric), of 25.
  - No arm is held.
  - Pip: the lantern stays 0.87 studs from his body, and his hands 1.46 from the brim.
  - Lyric: the speakers stay 0.06 studs from her arm, and her fist holds the pole 2.11 to 2.58 studs up it.
  - Both exports pass their audit (AUDIT PASS), and the content check passes both clips.
- **Code:**
  - The lift pass is shared now, as `rook_clips.lift`, and Lyric's keys can lift her.
  - The other clips are untouched, since their lift is 0.

**Research's read of the build and the call on the hang (2026-11-13; `build_pack_hang`, `_landing`, `build_try_hang`, `_lookdown`, the table):**
- **Accepted:**
  - the offset at 2.5. Inside a pack it's the avatar's own place that covers the fight, which is the player's steering, not the camera's.
  - Haymaker's landing as the slam: the square on the target's feet with the flash, then flat (B5's carried check passes).
  - the keeper's lantern and look down in one shot, and the pole's rock, small but read.
- **On a Shade: (a), through what exists, in TR7 now, not TR5.** `Config.Hud.SeeThrough` already turns the card see-through while a listed part sits behind it. Add the player's own lead's hanging square (the stamp's posts, rails and plate) to its watch, so the card goes to its Target see-through only while the square is actually behind it. That's not a timed fade, and the bar stays readable. TR5's scope stays as written.
- **Against the keeper: (c), not (d).** Haymaker's bold thing is the hang (B5's final). Off the top of the frame, it's lost in the one fight that matters most.
  - Cap the square's top a margin below the top band, measured from the camera each frame. Its foot may then come down over the hat.
  - One still to the content check. If it blocks, (d) stands.
- **Next:** the hang's two fixes with one still each, then the skip back. The framing closes with them.

**The hang's fixes (Faber, 2026-11-13, 22:25 to 23:10; stills in `build/captures/tr7/fix_*`).**
- **On a Shade, (a):** the posts, rails and plate of the player's own lead's square carry `Config.Hud.SeeThrough.Tag`, and the top band watches them. The Target card goes see-through only while the square is behind it (`fix_shade_seethrough.png`: the Brawler's card at its floor, the square behind it).
- **The cap, (c):** the frame's top stays `Stamp.Under` (10 px) below the top bar's foot (`UI.World.Ceiling`), measured from the camera each frame. The edge is the top bar's foot, as research chose, so the square hangs behind the see-through card. Each outer top corner meets that screen row at its own height, and the lowest holds: an off-centre top edge tilts on screen, and the middle alone left a corner 4 px over.
- **Against the keeper, (d) stands.** Capped, the square hung at the keeper's hat (`fix_keeper_hang.png`), and the content check blocked it on condition 1 of Haymaker's PASS (AR8: "B5's hang stays well above the head"). `Stamp.Uncapped` holds the keeper, so its hang stands as before (`fix_keeper_uncapped.png`).
- **From the same block, for every target:** the cap never holds the square lower than `Over`, `Clear` above the target's head. There the head's margin wins over the top bar, and the square's top may pass the line.
- **The content check, again: PASS** on `fix_keeper_uncapped.png` and `fix_shade_seethrough.png`, and on the floor in the code. The keeper's square is well above the hat; the Brawler's is about a head and a half clear. Still open from B5's own PASS (AR8): the slam passing the head in one frame, and a 64 px sheet at every heading before the art is uploaded.
- **Checks:**
  - type check 0 new; logic offline 3900/3900;
  - self-test "Haymaker" 55/55, "Keeper:" 65/65, "Camera:" 10/10, "Hud" 2/2, all at 60 fps. The cap's case: held at the line, never over it except at its floor, never under `Clear` over the head, uncapped over a Keeper (foot 34.40 of 34.40), capped over an Ordinary as tall (10.00, its floor).

**The skip back's blockout (Faber, 2026-11-13, about 1 hour by the commits and the takes' files; `build/captures/tr7/skip_*`).**
- **In the game,** on Modulo's block clip (baked in the place as `Skip`, fades 0.04 in and 0.1 out):
  - `Definitions/Actions`: `PipSkip` and `LyricSkip`, with `Beats.Land` 0.35, cancel from 0.35, no hits. `Actions.SkipOf(def)` gives a Voidkin's skip.
  - `Config.Combat.Skip`: On, Close 5, Every 4, Step 30 (degrees between the spots it tries), Body 1.5, Ground 2. All are live through `Tune`, and `On` turns it off for a check.
  - Pure rules in `Rules/Fight`: `ShouldSkip` (an enemy within Close, between actions, Every since the last, no swing at it winding up), `SkipBearings` (its place in the frame first, then spots round it by Step) and `SkipKeepsClear` (the path keeps Body from the enemy). They have a logic case.
  - `FightService`: the lead's think tries the skip before its next action. It glides to the spot by Land, still facing its target, re-aimed every frame with the Align held rigid, then lands into its next action.
  - `LeadLevel` takes an optional xp, so a test puts a save back exactly.
- **The self-test,** "Fight: a ranged lead skips back when a Shade closes", for each skipping Voidkin owned (Pip and Lyric here): 20/20 at 60 fps.
  - It skips inside Close and lands outside it: 11 to 14 studs from where the Shade stood, with no slide after Land.
  - Its facing, once turned (0.1 s in), is 2° off the Shade at worst for Pip and 5° for Lyric.
  - The next action starts 0.43 to 0.48 s after the skip does, inside Land + 0.3.
  - A Shade running in leaves the lead 25 to 32° off as the skip starts. The skip turns it at once (a line in `docs/polish-later.md`).
- **The balance check:** 10 runs with the skip and 10 without for each, alternating, `build/captures/tr7/skip_balance_runs.txt`.
  - Each run: the lead at level 1 against Lantern Row's Pack 1, at level 1. Respawn tuned to 1 s, with 11 s between runs so cooldowns reset. Each lead levels up on its second kill in both modes; the runs record when.

  | Lead | Damage taken, with / without | Time to clear, with / without | Falls | Skips a run |
  |---|---|---|---|---|
  | Pip | 446 / 479 (−6.8%) | 20.3 / 20.3 s (−0.3%) | 0 / 0 | 2.3 |
  | Lyric | 604 / 617 (−2.1%) | 27.4 / 26.3 s (+4.0%) | 0 / 0 | 3.0 |

  - Within 10% for both, and neither falls more often. Every stays 4.
  - Pip's damage taken spreads widely (sd 57 with, 95 without), wider than the gap. One run without the skip took 236; leave it out and the gap reads −11.8%. Ten runs can't tell these apart. Twenty more each would, if you want it.
- **The takes,** phone size: `skip_pip.mp4` and `skip_lyric.mp4`, with sheets, strips (`*_detail.png`) and stills (`*_still.png`).
  - Lyric's skip reads right of centre.
  - Pip's spot lies beyond his target from the camera, so his skip travels straight away from it and reads as a short shift on screen. That's the frame's geometry, not the skip.
- **The content check: PASS** on the stills and strips. Any frame used in public needs a 64 px sheet over dark and a fresh check.
- **Checks:**
  - type check 0 new; logic offline 3959/3959, and the same in Studio; world report 0 findings;
  - self-test "Fight:" 385/386. The one failure was Rook's piston slide, 0.85 against a stale 0.65: Modulo's B5 polish authored 0.85 (`Rook_Haymaker.json`). The expectation is updated, and the case passes 10/10.
- **Research, your call:** the blockout's verdict through `/ga-review`, and whether Pip's away-from-camera skip needs anything.

**Research's verdict on the skip back's blockout (2026-11-13; both takes at phone size, 10 fps strips 1.0 to 2.6 s and 4 fps 2.6 to 10.6 s, in `build/scratch/quaestor/tr7/`).**
- **Felt:** the skip itself is clean, quick and lands into the shot, with no moonwalk and no jitter. But across the fight the Shade is back on the lead within about half a second, and both leads spend most of each take shooting point-blank. Pip is pressed for nearly all of 2.6 to 9 s; Lyric opens a gap three or four times, and each is gone in a beat.
- **Tier:** works, as a block. The move passes; the behaviour the director asked for ("back away from close ranged enemy") shows for a moment every 4 s and is swallowed.
- **The one bold thing:** the landing into the next shot. It's what makes it a skip and not a retreat; keep it.
- **Fixes:**
  1. **Every from 4 to 2.5,** live through `Tune`, so the gap is what you see more often than the press. The balance check had room: both leads were well inside 10% (the design's "if the skip helps more, Every goes up" bounds it the other way). Rerun with the passives in place, so one batch covers both: 10 and 10 for Lyric, 20 and 20 for Pip given his spread. Past 10%, settle between 2.5 and 4 by the same check.
  2. **Pip's away-from-camera skip:** no lever. The read is the gap opening, not the path's length on screen, and fix 1 shows it more often. Judged again on the rerun's take.
  3. **For the shared finish** (`docs/polish-later.md`): a puff at take-off and a scuff at the landing, from the kit's rows, at rung 2. That's what sells a short skip seen end-on.

**The passives' blockout (Faber, 2026-11-13 to 14; `build/captures/tr7/passives*`).**
- **In the game,** as data:
  - `Definitions/Passives`: one row per lead, in three kinds. Second Wind is a Reduction: 20% less damage below 30% health. Kindle is an Extra: Fire worth 40% of `PipCombo`'s `Shot3`. Tempo is a Cooldown: Held Note's 20% shorter. The rows are live through `Tune` (`Passives.rook.Share`), and `Config.Combat.Passives.On` turns them off for a check.
  - `Rules/Passive`, pure: `Holds`, `Reduction`, `Extra` and `Cooldown`. A logic case covers their edges and one whole hit through `Hit.Resolve` (100 in, 80 taken).
  - `FightService`: the target's Reduction goes into `Hit.Resolve`, and the Extra joins the hit's elemental part, named on the Hit event. The Cooldown counts on the action's start and in the Ready and Cooldown attributes. A Reduction sets `PassiveOn` while it holds.
  - The cues, in grey. Second Wind: a faint ball round Rook while `PassiveOn` holds (`Config.Effects.Passives.Shell`). Kindle: the Fire as its own number in Pip's element colour, 0.1 s behind the shot's, and a flare at his lantern on the shot (`Passives.Flare`). Tempo has none.
- **The self-test,** "Fight: each lead's passive in play, with its cue": 19/19.
  - Rook's shell is on at 20% health, within a stud of him, and gone at full health.
  - Kindle comes on `Shot3` only, its Fire at least 40% of the shot's physical damage (119.1 on 297.9), with the flare seen.
  - Tempo's cooldown is 8.00 s.
- **The take,** phone size: `passives.mp4`, 30 s. Rook fights at 25% health against a level 13 Brawler, then Pip against a level 16. With it: `passives_sheet.png`, `passives_rook_still.png`, `passives_rook_strip.png`, `passives_pip_strip.png`, and `passives_pip_flare.png` (the flare at the lantern, and the Fire 112 beside the counting 637: 0.4 × `Shot3`'s 279).
- **The content check: PASS** on the cues and the names.
- **Two reads for research's pass:**
  - The shell is very faint at phone size, as the spec asks: in the still it's a thin ring. Its `Transparency` 0.6 is live.
  - Kindle's Fire, #FF8A3D, sits close in hue to a received hit's #E27A6A: in the take, a received 84 and the Fire 112 look alike. The received red is `docs/ui.md`'s muted red, so the element's tone is the freer one to move.

**The balance batch, the skip's rerun and the passives in one (Faber, 2026-11-14; `build/captures/tr7/passives_balance_runs.txt`, and Lyric's rerun in `passives_balance_lyric.txt`).**
- **The runs,** as before: the lead at level 1 against Pack 1 at level 1, Respawn 1 s, 11 s between runs, the modes interleaved, Every 2.5.

  | Lead | Mode | Runs | Damage taken (sd) | Time to clear (sd) | Falls | Skips a run | Under 30% health, a run |
  |---|---|---|---|---|---|---|---|
  | Rook | everything on | 10 | 614 (34) | 22.3 s (0.6) | 0 | | 3.6 s |
  | Rook | no passive | 10 | 665 (54) | 23.3 s (1.0) | 0 | | 6.2 s |
  | Pip | everything on | 20 | 407 (49) | 19.7 s (1.5) | 0 | 2.5 | 0.1 s |
  | Pip | no skip | 20 | 448 (29) | 21.2 s (2.5) | 0 | 0 | 0 |
  | Pip | no passive | 10 | 423 (43) | 21.1 s (1.4) | 0 | 2.4 | 0 |
  | Lyric | everything on | 10 | 565 (33) | 26.9 s (1.5) | 0 | 3.1 | 0 |
  | Lyric | no skip | 10 | 666 (111) | 29.3 s (4.5) | 0 | 0 | 1.3 s |
  | Lyric | no passive | 10 | 560 (40) | 26.9 s (1.6) | 0 | 3.0 | 0 |

- **Lyric's runs were taken again** after a bug the first batch showed: Rook's and Lyric's pushes could carry a Shade through Lantern Row's wall, and one stuck outside walked home forever. A push now ends at the world, and a Shade stuck walking home is set down at its place (c118647, with a logic case). In the rerun no Shade stood past 21.0 studs from the lane's middle, inside the walls at 22.
- **The skip, with and without:** Pip takes 9.3% less and clears 7.0% faster. Lyric takes 15.2% less and clears 8.3% faster. Most of hers is the bad runs it saves: three of her ten without it ran 32 to 37 s, two of them with her under 30% health, and the medians are 1.3% apart. Both are inside 10%, so Every stays 2.5.
- **The passives, with and without:** Rook takes 7.6% less, clears 4.0% faster, and spends about half as long under 30% health. Pip clears 6.5% faster and takes 3.9% less. Lyric's Tempo changes nothing measurable: +0.1% to clear, +0.9% taken, Held Note 3.0 times a run against 2.9.
  - Why, from the Definitions (DESIGN, not measured): a cast waits for the combo in hand (1.75 s) to end. So at 8 s her casts come every 9.5 s, against 11.25 at 10 s, and a fourth would land at 28.5 s, just past a 27 s clear. Tempo pays only in longer fights, a keeper's.
- **The skip's rerun take, at phone size** (fix 2; level 1 against Pack 1, Every 2.5, the passives on), in `build/captures/tr7/`:
  - `skip_rerun_pip.mp4`: 25 s, with skips at about 8.0, 14.7, 17.3 and 22.4 s. Strips: `skip_rerun_pip_8s_strip.png` and `_15s_strip.png`.
  - `skip_rerun_lyric.mp4`: 29 s, with skips at about 6.7, 11.8, 17.9 and 27.4 s. Strip: `skip_rerun_lyric_7s_strip.png`.
  - The times come from the server, within about half a second of the video's.
- **The three side by side,** everything on: Pip 19.7 s, Rook 22.3 s (+13%), Lyric 26.9 s (+36%). The rule holds for none of the pairs with Pip.
  - No passive's number closes it. Second Wind acts only under 30% health, where a level-1 Rook spends 3.6 s a run. Tempo adds no cast inside a clear (above). Kindle is Pip's, the fastest.
  - The gap was there before the passives: without them, Pip 21.1 s and Lyric 26.9 s. It's in the combos, which the rule keeps fixed.
  - **For research, the options:** (a) a passive of another kind for Lyric, one that pays across a whole pack (a tier 2 change to the seeds); (b) the check judged on another measure for a ranged lead, since hers is the only one that keeps its distance; (c) the combos' numbers opened for this one check, Lyric's and Rook's; (d) accepted for the block, settled at TR7's timing (part 4), which touches the combos' beats anyway. Mine is (d) with (c) inside it: the timing piece already moves the combos' beats, so the gap closes there with one batch, not two.

**Research's verdict on the passives and the gap, 2026-11-14** (the batch above; `passives.mp4` and its stills; the skip's rerun strips).
- **Felt:** Rook's shell and Pip's flare are cues you can catch at phone size, and Kindle's Fire as its own number is a small treat on the third shot. Tempo is felt nowhere in a pack: 3.0 casts against 2.9.
- **Tier:** works, as blocks, for Second Wind and Kindle. Tempo fails its own line ("the song comes round more often").
- **The one bold thing:** Kindle's Fire, its own number on the shot, a passive you see every few seconds.
- **The gap: (d) with (c), Faber's pick.** My rule, "its passive's number moves, not its combo's", assumed a passive could close the gap; the batch shows none can, so the rule is corrected: the 10% band is settled at TR7's timing (part 4), with Rook's and Lyric's combos open. They come up toward Pip, not Pip down, checked against `tools/balance/sim.py`'s pace. A Rare that clears a third slower than a Common is the wrong first lesson of the ladder.
- **Fixes:**
  1. Tempo must show in a pack: Held Note no longer waits for the combo in hand (the same kind, no new cue), the shorter cooldown kept. If the timing batch still shows nothing, research brings another kind.
  2. Kindle's Fire moves its tone away from a received hit's red, kept clear of the critical's gold; Faber's call on the value, checked side by side in the timing take.
  3. The shell stays faint, as asked.
- **Pip's end-on skip:** seen in the rerun (the 8 s strip), no lever, as fix 2 said. The take at the timing shows it again in a real fight.

**Status:** requested, 2026-11-13. The framing's blockout is judged: A with Turn 40. The framing is built, with its take, and accepted. Research's call on the hang: SeeThrough on a Shade, the cap against the keeper. The hang's fixes are in, with (d) against the keeper after the content check's block, 2026-11-13: the framing closes. The skip back's blockout is in, with its balance check within 10%; research's verdict: works, Every to 2.5, rerun with the passives in place, 2026-11-13. The passives are built, and the batch with the skip's rerun is in (Lyric's rows taken again after the wall fix), 2026-11-14. The skip's rerun take is in. Research's verdict on the passives, 2026-11-14: works for two, Tempo to show in a pack; the gap settled at the timing with the combos open. The director, 2026-11-14, night: framing A's shoulder ease is scrapped ("simply do not touch player camera"); the placement (Lead.Frame, Lead.Beside, Keeper.Turn) stays, its two checks retaken without the ease (`docs/decisions.md`). The ease is out, 2026-11-14 (Faber): `Shoulder.luau`, `Config.Combat.Shoulder` and `Rules.Fight.ShoulderShare` are gone with their cases, and a self-test case checks that a fight leaves the camera's offset at zero (type check 0 new, logic 4027 offline; its Studio run waits on the MCP). Next: the two checks retaken without the ease, in a pack fight and a keeper's try, with Turn 40 judged, then the timing.

