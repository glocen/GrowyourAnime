# Test requests

The builder's and QA's queue, in order. A piece's record is its entry here: the feel line, what the block contains, what waits, the checks, the verdict. Nothing about a piece is written twice.

## Closed, in the archive

These pieces are closed. Their whole entries are in `docs/archive/test-requests-closed.md`, in their order (research, 2026-11-26, the cleanup with the director's go). A closed piece that reopens moves back here.

- **TR2.** The circuit, in grey (Faber, to research's feel line)
- **TR3.** The HUD in the world, on the kit (Faber, with AR3)
- **TR4.** The reveal's ceremony, in the engine (Faber, with AR3)
- **TR5.** The elite's and the keeper's HUD (Faber, with Modulo's frames)
- **TR8.** Lantern Row dressed, with its night (Faber, with AR5)
- **TR9.** The Breaker screen, on the kit (Faber, with AR3)
- **TR10.** The elite's and the keeper's cooldown, with their marker (Faber, Modulo's icons)
- **TR13.** The signature's ring, reworked (Faber, with Modulo's frames)
- **TR15.** The stat board: skill points (Faber)
- **TR16.** Alone after a fall: the way home (Faber)
- **TR18.** The base as a power plant (Faber, then Modulo's generator)
- **TR19.** Home in one tap: the dock's Base tile (Faber)
- **TR20.** Everything that presses answers the pointer: hover (Faber)
- **TR22.** The base shows its owner (Faber, with Modulo's plinth)
- **TR24.** The first session whole, on a phone (Faber drives, research reviews)
- **TR25.** Attributes in the resolver, with the stat sheet (Faber)
- **TR26.** Items, class rules and the comparison (Faber)
- **TR27.** Chests and bulk opening (Faber)
- **TR28.** The inventory: the bag, in C (Faber)
- **TR30.** The generator's stages (Faber, on AR19)
- **TR31.** Back from away: the card on return (Faber)
- **TR36.** Two attributes, and the types named by their colours (Faber)
- **TR37.** The Forge and the Stone Condenser (Faber, on AR28's look)
- **TR38.** War Emblems (Faber, after TR37)
- **TR40.** Regen in bursts (Faber, after TR28)
- **TR41.** The passed screens that never reached the game (Faber, after TR40)
- **TR50.** One mission per Arc (Faber, after the foe card's upload)
- **TR51.** The base grows: every machine's stages, the landing, the owner's plate and plinth (Faber, after AR49)
- **TR58.** The boards on the Strip (research's request, tier 2, for Faber; Modulo the boards)
- **TR61.** The words, one voice: nine string fixes (research's request, tier 1 per line, for Faber)

## TR1. Day one: the repo, the place, the kit (Faber)

Tooling, with nothing players see, so no feel line and no blockout. Phase 0 of `docs/production-plan.md`.

- **Join the repo.** The folder has local history and `origin` (`github.com/glocen/GrowyourAnime`) has one first commit with a README. They've never met, and research's session can't join them. Join them without losing either (a merge that allows unrelated histories, keeping this folder's files), then push. From then on, pull and push as `AGENTS.md` says.
- **Update the handbook clone** in `handbook/`: it's behind the studio's.
- **Check the ids** the director gave on 2026-11-11: universe 9093907961, place 78052287756826, under group 35516567. Correct `CLAUDE.md`, "Places", if anything differs. Open the place in Studio with Rojo on port 34876.
- **Bring in the kit,** one group at a time, by `handbook/tech/README.md`, "Setup steps": the runtime pieces, the self-test, the logic tests, the debug bridge with live numbers, the type check.
- **Trim the starter** to this game: one place role; the `Hub` and `Match` folders renamed or dropped.
- **Three calls that are yours,** each recorded in `docs/engineering-plan.md`:
  - the save library: the director's data system from NEXT Button's `src/owner/`, kept, adapted or replaced, with the reason. Bringing it into this folder is reading outside the project, so it waits for the director's OK;
  - Roblox's Server Authority mode, on or off;
  - a headless runner for the pure rules, tried on one small rule module.
- **Read `docs/engineering-plan.md`** and correct it: it's yours from today.
- **The hooks' first run here:** say in this entry whether each session was told its role at start.

**Pass:** the repo is pushed and level; Studio boots clean on both sides; the self-test runs with nothing failing; the type check prints `0 new`; each teammate's session is told its role.

**Status:** done, 2026-11-12 (Faber). Implemented and tested; nothing players see, so no visual pass; not yet director-accepted.

- **The repo:** joined by a merge that allows unrelated histories (`57c8145`), this folder's tree unchanged, pushed, `main` tracking `origin/main`. The handbook clone pulled level with the studio's.
- **The ids:** the open place reads place 78052287756826, universe 9093907961, created by group 35516567. `CLAUDE.md` needed no change. Rojo serves on 34876.
- **The kit, in `src/`:** `Net`; `Log` (prefix `[GA]`), `Signal`, `Parts`, `Tune`, `Preset`, `TestInput` in `Shared.Util`; `Config.Presets` with `Baseline`; in `Services/Core` the debug bridge (`BootErrors` added), `TuneService` (live numbers, and a `Preset` command), `LogicTestService`, `SelfTestService`; in `Controllers/Core` `TuneController` and `SelfTestController`, cut to this game (no stamina, lock-on or entity state: the avatar never fights). Not brought in, until a piece uses them: `Raycast`, `Vector`, `UiLint`, the action stage, and the capture, animation, audio and effects tools.
- **The checks:** `tools/checks/luau_check.py` (luau-lsp, new solver) found 18 findings in the kit's own files and all were fixed in code, so `luau-known.txt` is empty. `tools/checks/logic_offline.luau` under Lune, now taking a folder of case lists.
- **The trim:** one role, `Main`; `Hub`, `Match` and the empty `Simulation` dropped. Pure rules live in `Shared.Rules`.
- **The three calls:** in `docs/engineering-plan.md`, "The builder's calls": ProfileStore kept under a save layer of our own (the director's word of 2026-11-12 on NEXT Button's data system is quoted there); Server Authority off, and the place switched to `AuthorityMode` Automatic; Lune for pure rules, tried on `Shared.Rules.OpLedger`.
- **The hooks:** the instruction lint and the tool guard installed on the director's yes (2026-11-12), exactly the handbook's example without the Studio lock. Hooks self-test 126 passed; the lint 0 findings; the guard refused a `git stash` live and let the builder's Studio calls through. **Each session was told its role at start:** Quaestor as Research, Faber as Builder, Modulo as Assets (`.claude/state/roles/`, 2026-11-11 23:17 UTC).
- **The director, 2026-11-12:** "player avatar will be R6 only do not worry". It covers the player's avatar. The self-test's `Avatar: R6` case holds it.
- **Tested, 2026-11-12, in the open place under Automatic:** boot 0 errors on both sides; the self-test 11 passed, 0 failed (1.7 s, 60 fps); `LogicTests` 29 passed; offline, the same 29 pass, and a planted bug (a repeat overwriting the first answer) fails 2; the type check `0 new`.
- **Learned:** a folder rename under a served Rojo crashed it (00:27), as `handbook/engineering/project-setup.md` warns. `AuthorityMode` reads and sets from MCP now. Without Server Authority the place has no input-action controls, and `TestInput.MoveBinding`'s two 5-second waits cost every self-test 10 s: it now looks once. These, and the 18 type fixes to the kit's files, are the handbook's to take (research).
- **Open:** the place's `AuthorityMode` change waits for a save of the place. `rbxassetid://203785492` fails to load at play start ("Asset type does not match requested type"). It's in no instance of the place, so the player's own avatar appearance is the likely source, unverified.

## TR7. Rook, Pip and Lyric installed (Faber, with AR1 and AR4)

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

## TR6. The UI effects kit (Faber)

Research's request, 2026-11-13, from the UI effects study the director asked for that day (`docs/research/vfx-reference.md`, "UI effects", its DESIGN part). Tier 2, research and Faber.

**Feel line:** every press answers the thumb at once with a squeeze and a tick, and every reward flies to its counter and lands with a pulse sized to what it's worth, so the screens feel expensive without ever getting loud.

**The block contains:**
- one kit (Pop, Press, Fly, Count, Shine, Rays, Burst) with its tokens in `UI/Theme.Motion`;
- the press on every button;
- Credits and Electricity flying in after a kill and on a collect;
- the level-up's rays.

It's judged in motion at phone size, beside the before.

**Waits:** the reveal's own layers (TR4, closed, stays), the Breaker screen's effects (with its piece), and sounds beyond the existing cues.

**Order in the queue:** after TR5. **Time, forecast:** about 2 hours.

**Status:** built, 2026-11-14 (Faber).
- **Implemented.**
  - The kit: `src/client/UI/Kit/` Fly, Count, Rays, Shine and Burst, beside AR8 C's Pop and Press, unchanged. Their pure rules are `Rules.Hud`'s ExpoOut, Flock and Arc. Their tokens are `Config.Hud.Motion`'s Haptic, Fly, Count, Rays, Shine and Burst, plus `Pop.Rungs.Fly`.
  - The press: a touch on a button that takes it plays Roblox's UIClick haptic (`Button.Haptic`).
  - A kill's Credits fly from where the Shade fell into the pill's coin. As the first one lands, the number counts up (Expo out), the pill pops at rung 5 and its "+N" rises. A win from nowhere on screen counts and pops at once, at its own rung. A spend shows at once.
  - The level-up: rays behind the word as it lands, one light band across its fill and its edge, and a gold burst off the badge.
- **Calls inside the piece (tier 1, Faber's).**
  - The tokens live in `Config.Hud.Motion`, not `UI/Theme.Motion`, so Tune changes them live.
  - The squeeze stays AR8 C's 0.92, not the study's 0.96: research named it AR8 C's bold thing, and the logic case holds it between 0.88 and 0.95.
  - The game has no Electricity collect, so Electricity flies on the battery's jump (a return from away), from the screen's middle.
  - The shine goes only on the level's word, the one rare reward the HUD shows now.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4039 passing offline, with a new case for the count, the flock and the arc.
  - The self-test's new TR6 case and the level-up's four new checks wait on the Studio MCP, with TR5's.
- **Visually reviewed:** not yet. The captures at phone size, beside the before, go here once Studio is back.
- **Accepted:** no.

## TR11. Spectate, a toggle on the HUD (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`): the player's camera is never moved in a fight, and a small button follows the lead instead. "Change it now."

**Feel line:** mid-fight, the player taps a small eye low on the right and the camera glides onto their Voidkin, so they watch its combo and its signature up close; one more tap and it's back on their avatar, as they left it.

**The block contains:**
- **The toggle,** in grey: a small eye beside the signature's ring, a whole 44 px target, lit while on. Off at every join; never a setting.
- **On:** the camera follows the lead, eased in about 0.3 s; the player's drag and zoom work as ever; the avatar still walks, and the lead still follows it.
- **Off, or when the lead falls, or at a move's black fade:** back on the avatar at the distance and angle the player had.
- Two or three places for the eye, judged at phone size in a pack fight and a keeper's try.

**Waits:** the eye's finished look (with TR13's frames); a sound.

**Checks:** a self-test case for each state (on, off, the lead's fall, a fade); the UI lint on the smallest phone; research's verdict in motion at phone size.

**Order in the queue:** after TR5's frames and the shoulder ease's removal (TR7). **Time, forecast:** about 1 hour.

**Status:** built in grey, 2026-11-14 (Faber).
- **Implemented.**
  - `SpectateController` (client). On, Roblox's camera follows a stand-in point, set before the camera each frame and eased from the avatar's focus to the lead's (about 95% in 0.3 s, `Rules.Hud.Approach`). The heading, the zoom and the drag stay the player's. Off, it eases back and hands the camera to the avatar again. It turns off at once when the lead falls or leaves, and at each spawn. In a move's fade, it's back on the avatar the moment the screen is black (`FadeController.OnFade`, with `FadeController.Play` as the server's fade and the tests' entry).
  - The eye: the kit's button at `Theme.Size.Tap` (44 px rendered at the smallest scale), with a stroked almond and a pupil in grey. It's lit (Selected, the accent) while on, and disabled while the lead is down ("Your lead is down"). It always shows, as `docs/ui.md` has it.
  - Its three places are `Config.Hud.Spectate.Place`: "Above", "Left" or "Below" the signature's ring, tuned live. "Above" is the start.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4035 passing offline, with a new case for the ease.
  - The self-test's new case (on, off, a fall, a fade's black, the zoom and the heading kept) waits on the Studio MCP, with TR5's and TR6's.
  - 2026-11-15, in the phone emulation: the case passes, 28 checks. One finding for research's verdict: on a touch screen Roblox's camera follows, and it turned the heading by about 14° on the way to the lead in one run and by 0° in another. With a mouse the heading holds, and the case holds it there. On a touch screen the case now measures the turn instead. The player's camera is left as it is, by the director's word.
- **Visually reviewed:** not yet. The three places, at phone size in a pack fight and a keeper's try, go here once Studio is back, for research's verdict.
- **Accepted:** no.

## TR12. Health carries: Regen, the fall home, the Training machine (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`; the design: `docs/design.md`, "Combat", "Health carries" to "The next lead", and "The base", "The Training machine"). It replaces `Config.Combat.Heal` and the fall's `DownSeconds`.

**Feel line:** on Lantern Row your Voidkin fights on what it carries: each pack leaves a mark and its health creeps back only a little at a time, so you push one more pack or head home. If it falls, it's gone home in a flash of light, and you send out your next fighter while it heals and trains on your plot, waiting for you to come back.

**The block contains:**
1. **Regen** replaces `Combat.Heal`: a value a second, always, in a fight too. In the block it comes from the level (`Rules/Stats`, as a stat with its source), with the Healer's class carrying more. The gear source waits for Regalia's stats.
2. **Healing at home:** on its plot a lead heals to full in about 30 s.
3. **The fall:** the lead leaves as light (the grey stand-in, no body left), is home on its plot, heals to full in about 90 s, and waits there. It follows the player again once the player is on their plot. In a keeper's ring, a fall ends the try.
4. **The next lead:** once the lead has fallen, the player sends out another healthy Voidkin they own, from the lead's card or the Voidkin screen, anywhere out of combat. The fallen one's card shows "healing at home" with its time, then "training".
5. **The Training machine,** in grey (a box with its plate) on the plot: it trains one Voidkin at a time, the one at home without the player, or the lead while the player is offline. A pure rule in `Rules/`, worked out on the server at the next join from the leave time, as the Breaker's and the battery's are. No cap.
6. **The numbers,** through `tools/balance/sim.py` before they settle (tier 2, research's seeds, tuned by playing):
   - Regen: on Regen alone, a lead at its level ends Lantern Row's Pack 2 with between a third and two thirds of its health; it falls before the elite in at most one run in ten.
   - Training: about a third of a fight's experience a minute at its level. Bring research what a night (8 h) and a week away give at levels 1, 5 and 15.

**Waits:** Regen's gear source (Regalia's stats); the machine's model and the training clip; the fall's finished effect; the "at home" card's finished look.

**Checks:** logic cases: Regen in and out of a fight; healing at home; a fall, the trip home and following again; the next lead; training across a leave, a long one included. The self-test for the lead's card states; research's verdict in motion at phone size: a circuit with a fall, the next lead out, and the trip home.

**Order in the queue:** after TR11. It's the loop, so it comes before TR6. **Time, forecast:** 3 to 4 hours, the sim's run included.

**Status:** built in grey, 2026-11-14 (Faber), c0f0478 and 1be04e6. Time: about 4 active hours, my estimate, not measured.
- **Implemented.**
  - **Regen:** a stat from the level (`Config.Stats.Regen`: Base 4 at level 1 times G, a Healer ×1.5, its own "Level" source, so rarity and stars leave it alone). A lead heals it every second, always, in a fight too (`Rules.Fight.Regen`). On its own plot it also heals from nothing to full in `Combat.Lead.Home.Full` (30 s; `Markers.OnPlot`). `Combat.Heal` and `DownSeconds` are gone.
  - **The fall:**
    - The lead is down for `Combat.Lead.Leave` (1.6 s), then leaves as light: a grey column where it lay (`Config.Effects.LeadLeaves`), its prop back in hand.
    - It's home on its plot, 6 studs before the Training machine, and heals from nothing to full in `Lead.Home.Fallen` (90 s).
    - It follows again once it's whole and the player is on their plot (`Rules.Carry.Fallen`). I read "heals slowly to full, then waits" literally: a fallen lead never leaves the plot half healed.
    - In a keeper's ring a fall ends the try, as before.
  - **The next lead:**
    - The lead never changes in a fight: a keeper's try, a target, or a Shade on it (`FightService.InCombat`).
    - A fallen Voidkin goes out again only once it's whole (`Carry.Refusal`, the SetLead guard).
    - A Voidkin taken in keeps its share and heals at home's rates while it isn't out.
    - The card says "Down", then "Healing at home m:ss" with its bar filling, then "Training" or "At home" (`Hud.LeadStatus`).
    - A "Send another" button under the card opens the Voidkin screen. Its rows say "Healing at home m:ss" or "Training", and a refused row says why.
  - **The Training machine,** a grey box and pad on each plot (`Tags.Training`), with its plate:
    - It trains one Voidkin at a time (`Rules.Training.Who`): the lead while the player is away from the plot or offline, a fallen one once it's healed, nobody while the player is home.
    - It earns a fixed rate at any level, with no cap: `Config.Growth.Training.Share` (0.33) of what fighting earns in Lantern Row, 39.2 a minute today (`Rules.Training.Rate`, from `Config.World.Row`'s packs and elite and `Config.Drops.Share`).
    - The server credits it every 30 s in the game, and whenever who trains changes. At a join it credits the lead's time away (`Training.Advance`, `Profile.Training.Stamp`).
  - Studio adds `LeadHeal` (every Voidkin whole, a fallen lead up beside the avatar) and `TrainingSkip`.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4389 passing offline. New cases cover Regen in and out of a fight, healing at home, the carry, the fall's trip home and following again, the next lead's refusals, the training rate and gain, who trains, and a leave (a night, the same night in steps, 400 days reaching the last level, a worker, a clock gone back).
  - The self-test's new case and the two cases updated for the fall home (the keeper's loss, spectate's fall) wait on the Studio MCP. The new case walks the card's states, the button, the Voidkin screen, the next lead out, and the fallen one refused.
- **The numbers** (`tools/balance/sim.py`, sections 9 and 10), on research's read below, applied 2026-11-14 (Faber). A model, not a measurement: the game's own Config, a bare lead, every Shade of a pack on it at once.
  - **Regen 4 with Ordinary Shades' Attack ×0.5** (`Config.Enemies.Ordinary.Attack` 5.735, from 11.47; a brawler now costs a bare Common Warrior 6% of its health, not 12%).
    - A new account ends Pack 2 with 53% [47 to 60%], and 1 to 2 runs in 100 fall before the elite. From level 3: 72 to 74%, none fall.
    - **Lyric, a Healer, falls in 11 runs of 100** at level 1 (51% [44 to 58%]), above the 2 to 3 target: her low health shows before her Regen ×1.5 does. Faber's proposal, tier 2: the Healer's class Regen ×2, or leave it to her own heal once she has one.
    - Before: Regen 20 on the old Shades gave 62% but refilled in 40 s, which missed the feel line.
  - **Training at a fixed 39.2 a minute:** the director's "Fixed rate, no cap". It's 15.9 a kill on average over Lantern Row's packs and elite, at 450 kills an hour, times 0.33.

    | From level | A level here | A night (8 h) | A day | A week |
    |---|---|---|---|---|
    | 1 | 1 min | 13.4 | 20.3 | 34.7 |
    | 5 | 19 min | 13.9 | 20.5 | 34.7 |
    | 15 | 120 min | 18.7 | 22.2 | 35.3 |
    | 30 | 895 min | 30.5 | 31.6 | 39.3 |

    - Level 60, the last, from level 1: 1394 hours in the machine (58 days).
    - A new account's first night reaches level 13, in Drum Court's range; past level 30, a day gives about a level and a half.
    - Waiting on research's read before it settles.
- **Research's read of the numbers, 2026-11-14, night.**
  - **Regen: Ordinary Shades' Attack ×0.5 with Regen 4** (tier 2, research's, with the fights' owner: Faber proposed it).
    - The director's complaint was waiting out a heal after a pack. At 200 s from empty, waiting loses to the door home (30 s), so the choice the feel line names is real.
    - At ×0.6 with Regen 8 (100 s), a minute and a half's wait still refills, and with no falls the fall home is never met early.
    - 2 to 3 falls in 100 before the elite are within the target.
    - Lyric, a Healer, keeps her class's larger Regen.
  - **Training: the director's word, 2026-11-14, night: "Fixed rate, no cap".** Training earns a fixed amount of experience a minute that never grows, a third of what fighting earns in Lantern Row. Each level costs more, so it slows as levels rise. Faber: run it through section 10 and bring research what a night, a day and a week give from levels 1, 5, 15 and 30, before it settles.
  - **Faber's tier 1, a fallen lead follows only once whole and the player is home: agreed.** That's the director's own words.
  - **The fixed rate's table, research's read: settled.** 39.2 a minute: a level costs 1 minute at level 1, 120 at 15, 895 at 30, and the last level takes 58 days in the machine. It's fast at the start and slow at high level, as the director expected. A first night carries a new account about 13 levels, the start of the ground's climb. Gear, shards and the keeper's win still come only from fighting. Retaken in play at the verdict.
  - **Lyric at level 1, 11 falls in 100: no change.** It's one over the line on 100 runs of a model, and she's no starter, so she rarely leads at level 1. Her Regen stays ×1.5, and her own heal comes with her signature (`docs/design.md`, "Voidkin", the Healer). Retaken at the verdict in motion.
- **Visually reviewed: research's verdict in motion, 2026-11-14, night** (`build/scratch/faber/take/tr12_take.mp4`, phone size, at dusk; read at its beats).
  - **Felt:** the lead drops, its card says Down and then "Healing at home 0:24" where its health was, "Send another" sits under it, and a second lead is out and fighting within eight seconds. Later the first one shows as Training without the player doing a thing. The loop never stalls.
  - **Tier:** works (grey).
  - **The bold thing:** the card's own line turning from health to "Healing at home" with its clock. It answers "where did it go, when is it back" in the one place the player already looks.
  - **Fixes (Faber):**
    1. **The fallen card dims,** as `docs/ui.md` "A fallen lead" says. The portrait stays in full colour today, so at a glance the card still reads as fighting. (Serves the read at phone size.)
    2. **Lead keeps its label while it waits.** At 18.3 the button is an empty outlined box for a moment. Show the pressed state with the word in it. (Serves responsiveness.)
  - **Waits, not a fix:** the column the lead leaves as is a flat white slab, the brightest thing on screen, standing beside the electricity bar. It's grey and goes to the effects pass. When it's drawn, it must not outshine the HUD.
  - The 25 s heal and the held health were the take's, not the game's, and they are noted as such.
- **Accepted:** no.

## TR14. Speed, and the cap at 125 (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`; `docs/design.md`, "Speed"; `docs/balance.md`, "Growth").

**Feel line:** in a pack, you can tell who's leading by how it closes in: the Assassin is on the next Shade before the last one has burst, the Tank plods in heavy, and every lead still keeps up with you on the street.

**The block contains:**
- **Speed** as a stat: each class's walk speed in a fight (seeds: Tank 14, Warrior, Mage and Healer 16, Assassin 19), and a nudge of 1 either way in a Voidkin's own entry (Kirra +1). It replaces the one `Combat.Lead.WalkSpeed`. The catch-up when following stays.
- **The cap at 125:** `Growth.MaxLevel` 125, the same curve on past 60. The launch's pace stays designed to 60, and the training table runs to 125.
- **The numbers:** the sim's kills an hour by class with Speed on, for research, before the seeds settle.

**Waits:** the pace past 60 (with the grounds that reach it).

**Checks:** logic cases (Speed by class and nudge, the cap); research's verdict in motion: Rook and Pip in one pack, and a lead following a running avatar.

**Order in the queue:** with Kirra's install, after "Content as data". **Time, forecast:** about 1 hour.

**Status:** the code built offline, 2026-11-14 (Faber); research's verdict in motion waits on the Studio MCP, with Kirra's install. Time: about 1 active hour, my estimate, not measured.
- **Implemented.**
  - **Speed** (`Config.Stats.Speed`): Tank 14, Warrior, Mage and Healer 16, Assassin 19, and a Voidkin row's own `Speed` nudge, clamped to 1 either way (`Definitions.Voidkin`; Kirra +1, so 20). `Rules.Stats.SpeedOf` puts it in the block. It isn't one of `Stats.Names`, so no item, board or later source adds to it.
  - **The walk:** in a fight a lead walks at its Speed (`FightService`, closing on its slot). Following the avatar, every lead walks `Combat.Lead.FollowWalk` (16, the avatar's own), whatever its Speed, so a Tank never trails and an Assassin never stutters ahead. The catch-up stays for both, never slower than the walk (`Rules.Fight.LeadSpeed`, which replaces `FollowSpeed`). `Combat.Lead.WalkSpeed` is gone. The walk clip already plays at the body's ground speed, so a Tank's stride slows with it.
  - **The cap:** `Growth.MaxLevel` 125, the same curve on (G about 77.4 at 125). A level past 60 takes Mirror Pavilion's kills a level until the grounds that reach those levels are designed. The training machine runs to 125, and ten years in it reach the cap.
- **The sim** (`tools/balance/sim.py`, section 13; a model, not a measurement; the player waits for each pack, an upper bound): Speed changes only the closing and the steps between Shades, about 1.3 to 1.7 s of a 22 s pack. Kills an hour against today's 16: Kirra +1.2%, a Tank −0.8%, Pip and Lyric unchanged, Kirra against a Tank +2.1%. Speed is felt in the pack, not counted.
- **Tested.** The type check: 0 new. The logic: 5272 passing offline. Two new cases: the cap (125, the curve, levels past 60 at the last ground's pace, 60 to 61, the cap resolving), and Speed (every row's class walk and nudge, the same at the cap and every star, Kirra, a Tank, Rook, never from an item or the board, 0 for an enemy). `LeadSpeed` has its cases. Two cases had 60 written in and now read the cap.

## TR17. The Voidkin screen, remade (Faber, then Modulo's look)

Research's entry, 2026-11-14, night, on the director's word of the same night (`docs/decisions.md`: "it need to looks insanely good like ammorpg character but for each voidkin ... to make it easy"; then "Next, now"). It replaces the collection screen built through TR15, and it's `docs/ui.md`'s screens 4 and 5 at the bar. The study: `docs/research/voidkin-screen.md`.

**Feel line:** a player opens one Voidkin and it stands there full size, alive in its own light, turning under their thumb, its power at its feet and everything about it one tap to the side. A character you want to show off, not a list you scroll, and the next one a swipe away.

**The block contains,** in grey, at phone size, in three layouts to judge in motion:
- **Stage:** the figure on the left half, the panel on the right with its tabs along the top, the portrait strip along the bottom.
- **Flank:** the figure in the middle, the kit's three icons in a column on one side and the stars on the other, and the panel sliding in from the right on a tap, the figure easing left to make room.
- **Rail:** the portraits in a column on the left edge, the figure left of centre, the panel on the right.
- **In all three:**
  - the Voidkin's own model, live, playing Idle at about 70% of the screen's height; a drag turns it, and a tap plays the end of its Reveal;
  - a grey stage whose light takes the rarity and whose floor glow takes the element (stand-in colours);
  - Combat Power at its feet;
  - the panel's tabs, Overview, Stats, Kit and Stars, on real data;
  - Lead (or Leading) and Send to work, always in view;
  - favourite, lock and rename beside the name;
  - switching by the strip and by a swipe on the figure.
- The dock's Voidkin opens the lead's screen.

**The director's layout, 2026-11-15, "change it now"** (`docs/decisions.md`): "the ui of the voidkin should be the FULL SCREEN and dont forget it need to showe the gears slot just like taichi panda dragon all the menu button on the left like taichi panda for each voidkins and the voidskins selection scroll bar below". It replaces Stage, Flank and Rail: their takes aren't recorded. The block is rebuilt to it, in grey:
- **Full screen:** the screen covers the world and the HUD. A thin top bar: back and the screen's name on the left, the currencies on the right.
- **The menu, a thin rail on the far left** (the director, 2026-11-15, "change it now": "much smaller and more like a line with a circle of the button welll made like art"): a thin line with the pages as round buttons on it (the list is in the notes below). Only the chosen page's word shows, at the kit's smallest text (AR12). The selected one is larger and lit, and opens its page in the panel on the right. Drawn circles may be smaller than 44 pt; the tap area stays 44.
- **The figure with its gear slots:** the figure stands left of centre, between two columns of six slots, the twelve shared, made bigger (the director, 2026-11-15). Main Hand and Off Hand, its class's pair, sit at the figure's feet, one each side of Combat Power. All are the slots of the preset this Voidkin is linked to (`docs/design.md`, "Presets"). Gear stays the account's, and "for each Voidkin" is the link that's already designed. The slots are empty and grey until gear is built. Combat Power sits at its feet, between the columns (`docs/design.md`, "Combat Power").
- **The Voidkin strip along the bottom,** scrolling. A swipe on the figure still switches.
- **The director's notes on the mock, 2026-11-15,** in now, with every later note on this screen until TR17 closes ("Now, and later notes too"):
  - space between every gear slot;
  - the right panel is the bag: the player's whole inventory, with tabs by kind (`docs/design.md`, "The bag");
  - Overview holds the selected Voidkin's whole stat sheet, with its facts;
  - the rail holds every page: Overview, the bag, Kit, Stars, Forge, Jewels and War Emblems. A system not built yet shows its button greyed with "Soon", never an empty page;
  - Regalia's screen is merged here, so the dock loses Regalia (`docs/ui.md`, screen 5);
  - Legendary gear changes its border only, with no crown (`docs/research/gear-icons.md`, DESIGN).
  - Lead and Send to work move out of the right panel ("the lend and send to work should be moved elsewhere"). Research's placement, to judge in the take: the top bar, right of the name, Lead filled in the room's colour and Send to work beside it. Favourite, lock and rename stay small by the name.
  - The level's text gets a designed mark, not a plain "Lv 12" ("also the levels text design of voidkin need to change", to Modulo). It's drawn in the mock first.
- **Kept from the block:** the live figure, the drag to turn, the tap's flourish, the stage's light by rarity and element, the real data in each page, Lead and Send to work in view (now in the top bar), and favourite, lock and rename by the name.
- **The figure** fills the stage between the top bar and the strip, and the aim of 70% of the height is dropped, since the strip came after it (research, 2026-11-15, on Modulo's mock, AR12).
- **Watch, at phone landscape:** six slots a column over the strip leaves about 38 pt a slot (the reference's are about 12% of the screen's height, about 46 pt; `docs/research/voidkin-screen.md`, 10). The block shows whether they hold. If they don't, a tap anywhere on a column opens the gear page. Taps stay 44 pt.
- **Done when:** one take at phone size (open, turn, tap, three switches by the strip and by a swipe, each menu button, Lead and Send to work), then research's verdict in motion. Modulo's vivid mock of this layout (AR12) is judged beside it.

**Waits:** the look (Modulo, with Faber, after the pick); sorting, filtering and comparing two; another player's view of your lead; the skill tree; evolution.

**Done when:** a take per layout at phone size: open from the dock, turn the figure, tap it, switch three Voidkin by the strip and by a swipe, each tab, and Lead and Send to work once each. Then research's verdict in motion and the director's pick. The UI lint runs first, at both scales.

**Status:** research's three fixes and the band are built, and the retake is with research ("The retake" below). Before: rebuilt to the director's layout, with the notes on the mock in. Faber, 2026-11-15.
- **Implemented.** `src/client/UI/VoidkinScreen/init.luau`, a full screen through the kit's `Screen.Full`: a cover on its own layer hides the world and the HUD and takes their taps, and Back is at the top left. Its numbers are in `Config.Hud.Voidkin`. Stage, Flank, Rail and `Hud.Voidkin.Layout` are gone.
  - **The rail:** seven round buttons on a line. Overview, Bag, Kit and Stars open their page. Forge, Jewels and War Emblems are greyed with "Soon": a tap says so and the page stays. Only the chosen page's word shows. Circles 26 and 42 across, taps 68 by 52 authored.
  - **The stage:** the live figure between two columns of six slots, 6 apart, the twelve shared in the order of `Definitions.Gear` (new, with its logic cases). Main Hand and Off Hand, its class's pair, stand either side of Combat Power. A tap on a column says gear isn't built.
  - **The top bar over the panel:** the currencies, then Lead, filled, and Send to work on a line of their own.
  - **The panel:** the name with favourite, lock and rename, then the chosen page. Overview is its facts and its whole stat sheet, straight under its level. Bag is the inventory with a tab per kind: Shards from the save, and Items, Emblems, Jewels and Stones greyed "soon". A cell is a shard with its count, and a tap names it. Kit and Stars are as before.
  - **The strip** under the stage. A flick, a drag and a tap on the figure are as before. The dock is Voidkin, Base, Map.
  - Rename stores the name raw: the server passes it through Roblox's filter before keeping it (`TextFilterService`). A nickname the filter changes is refused, and the Voidkin keeps its name. Favourite and lock: `Collection.SetMark`.
- **Combat Power.** The director, mid-build, 2026-11-14, night: "combat power need to really look like taichi panda dragon hunter in design but like us visually". It covers Combat Power's display. The block holds its structure in grey: a plate in its rarity's light that fades out at both ends, an emblem, the caption and large digits. When it rises, the digits count up and the gain floats off the plate (`Config.Hud.Voidkin.Power`). For research: that reference's Combat Power, studied for Modulo's look after the pick. The number is `Rules.Stats.Power` on stand-in weights (`Config.Stats.Power`). Tier 2: research's seeds replace them.
- **Measured,** in this window (750 by 401) and then on the smallest phone:
  - the figure's share of the screen's height: 0.56 and 0.55 (the mock's 0.62);
  - a slot: 38.5 and 28.9 rendered px, 36 and 34 authored (the mock's 40, the reference's about 46);
  - a hand: 49.2 and 39.1 rendered px (the mock's 46);
  - Combat Power's plate: 107 and 85 authored px wide;
  - the rail's seven taps need 375 authored px, and its window has 247 and 234.
- **Tested.** The case `Voidkin screen (TR17)` in `SelfTestController/VoidkinCases.luau`: 217 passed, 0 failed, 58 fps, with the UI lint clean in this window and on the smallest phone on each built page. The take's case: 21 passed. Logic offline: 5513 passed. Type check: 0 new.
  - **The whole self-test, 2026-11-15, in the phone emulation with Studio in front:** 1660 passed, 0 failed (259 s, 60 fps). It's the clean whole pass that was owed.
- **The take:** `build/captures/tr17/full_take.mkv` (60 s, phone size, the take starting about 3 s in), with `sheet_a.jpg` and `sheet_b.jpg`. The case `Take: TR17`: the dock, the lead's screen, a turn, a tap, the strip twice, a flick each way, a column's tap, the rail's Bag, Kit and Stars, the rail dragged to Forge, Jewels and War Emblems, Overview, Lead, Send to work, Back. Not played: the drag, the flicks, the rail's taps and its scroll are the test's own calls.
- **Visually reviewed:** by Faber on the sheets. Research's verdict: not yet. **Director-accepted:** no.
- **For research, from the build:**
  1. Seven 44 pt taps don't fit the rail, so it scrolls. The four built pages stand whole before any scroll, and Forge peeks at its foot. Fewer buttons, or the three not built as one, would need no scroll.
  2. Lead and Send to work stand on a line of their own over the name, not right of it. The panel's column is about 300 authored px, and the name, three marks and two actions at 44 pt need about 560.
  3. The mock holds its top row in Roblox's top-bar band, which the screens' room leaves out today (54 of 375 authored px). A full screen with its bar in that band gives the panel about 60 px more and the rail one more button. It changes the Screen kit and the lint's safe area, and isn't built.
  4. The panel's page is about 139 authored px tall under the name's row: Overview shows its type, its level and its first stat before a scroll.
  5. The name has about 75 px beside its three marks, so its second line truncates.
  6. The screen's name stands over the stage and touches a tall figure (Lyric's prop, the stand-in's arm). The mock has the Voidkin's name there, and no screen name.
  7. A lead's two actions both read "Leading": the kit shows on a button's face why it's off.
  8. The screen opens on the lead's Overview. "The right panel is the bag" could mean the bag first: research's to say.
  9. The bag holds shards only and shows no count of its space: no capacity is designed yet.
  10. Combat Power's weights are stand-ins (tier 2).
- **Tier 1 notices.** A fresh open starts on the lead's Overview. Overview's stat sheet comes before "Now" and the gear line. A bag cell's mark takes the light of the Voidkin its shard holds. A nickname holds at most 20 characters (`Config.Voidkin.Nickname`, from `docs/ui.md`).
- **Time:** about 3 active hours for the three layouts, then about 4 for the rebuild and the notes, my estimates, not measured.
- **Research's verdict in motion, 2026-11-15.** From `full_take.mkv`, cropped to the phone: the open at 4 fps, two switches at 8 fps (13.5 to 15.5 s, 18.5 to 20.5 s), and both sheets.
  - **Felt:** a character sheet you flip through. Every Voidkin turns on its stage with its number at its feet, and the panel answers at once. But in grey the stage is boxed in by its columns, and the name is said twice.
  - **Tier:** works (grey). **The one bold thing:** the live figure between its gear columns, with Combat Power at its feet. It's the reason to open the screen, and it reads at phone size.
  - **Fixes (Faber):**
    1. **Never an empty stage.** On a switch, the stage stands empty under its circle for about 0.25 s (13.9 to 14.1 s) before the figure pops in, while the panel has already changed. Keep the old figure until the new one is ready, then change both in one beat. Serves responsiveness.
    2. **The Voidkin's name over the stage, where "Voidkin" stands.** Use one line, with its rarity in its colour (`docs/ui.md`, rule 3), and favourite, lock and rename as small marks beside it at 44 pt taps. The panel loses its name row and the truncated "Epic · Enduran…" line, which repeats the line under it. This answers findings 4, 5 and 6: the page gains the row, and the figure stands under the name. Serves the mock and the read.
    3. **A disabled button says why** (`docs/ui.md`, rule 4). The lead shows Lead lit as "Leading", and Send to work greyed with "not while leading" under it, not "Leading" twice. Serves the read.
  - **Faber's questions, research's calls:**
    - **1 and 3, the rail.** Take the band. The top bar (Back, the currencies) moves into Roblox's top-bar band, right of Roblox's own buttons, and Back leaves the rail's column. The rail then holds the seven 44 pt taps whole, with no scroll, since the director asked for every page on it. If a few points are still short, tighten the gaps between the circles, never the taps. It's a Screen kit change, so the lint's safe area moves with it. The technique is Faber's.
    - **2.** Lead and Send to work on their own line over the panel: accepted, as built.
    - **4 and 8. The screen opens on the bag.** The director's words were "the stats should instead be the players inventory": the panel that showed the stats now shows the bag. Overview is one tap away on the rail. This is research's reading, and the director can turn it around.
    - **9.** No count of the bag's space, since no capacity is designed. It's an open question, not built.
    - **10.** Combat Power's weights: research's seeds are owed (tier 2), and stand-ins stay until then. Pip, a Common at level 12, shows 32,151 over Ironhymn, an Epic at level 8, at 27,433. The seeds must make rarity count for more than four levels.
  - **Not judged:** the look (Modulo's mock and AR12's colour), the slots' art, and the level's mark (the director's later note).
  - **Retake:** the three fixes and the band, with one switch at 8 fps and the rail whole on the smallest phone.
- **The retake, Faber, 2026-11-15.** Research's three fixes, the band and the bag first.
  - **Implemented.**
    - **The band.** A new layer, `Band`, in Roblox's top-bar band, right of Roblox's own buttons (`GuiService.TopbarInset`; `UI/Layers.luau`, `Kit/Screen.luau`: `Screen.Band`, `Screen.BandLeft`). A full screen holds Back, the three marks and the currencies there. The lint's safe area moved with it.
    - **Fix 1, never an empty stage.** A switch asked before a body can be drawn keeps the one shown with its panel, lights the asked cell on the strip at once, and changes both in one beat once it's ready (`VoidkinScreen.Choose`, `Figure.Warm`, `Figure.Ready`).
    - **Fix 2, the name over the stage:** one line, its rarity in its colour, where "Voidkin" stood. The panel's name row is gone. Favourite, lock and rename are 44 pt marks in the band, right of Back.
    - **Fix 3.** The lead's Lead reads "Leading", lit, and Send to work is greyed with "Not while leading" under it (the kit button's `Under`; `Rules.Hud.WorkReason`).
    - The screen opens on the bag.
  - **Measured.**
    - **Fix 1's cause is the renderer, not the fetch.** `PreloadAsync` on a body ends in about 0.01 s with every mesh fetched, and its first draw in a viewport still stood empty for 0.25 to 0.53 s, then grey for a frame. The engine readies a mesh only once something draws it, and gives no signal. So the stage has wings: a viewport 8 px a side where each of the roster's first twelve bodies is drawn ahead at the open. A body counts ready 0.8 s after it stands there (`Config.Hud.Voidkin.Figure.Draw`; the dev PC's measure, no phone measured). At worst a switch waits about 0.8 s after the open, with its cell lit.
    - **The rail isn't whole on the smallest phone.** Seven 44 pt taps need 308 pt. Under the band the phone emulation leaves 343 pt (whole, no scroll), a 360 pt phone 302 pt, and the smallest phone 262 pt. No gap is left to tighten: the taps touch.
    - The figure's share of the height: 0.51 and 0.49 (it was 0.56 and 0.55). The name's line takes 24 authored px over the crown.
    - The name's line: 178 and 153 authored px wide, so a long name is cut on the smallest phone. The smallest phone's band is 475 authored px, and the battery drops its capacity there.
  - **Tested.** The case `Voidkin screen (TR17)`: 255 or 256 passed by the run, 0 failed, the lint clean in this window and on the smallest phone. It holds a body back, asks for it, and checks the figure and the name kept, the asked cell lit, then both changed. The retake's case: 14 passed. The whole self-test, in the phone emulation with Studio in front: 1699 passed, 0 failed (266 s, 60 fps). Type check: 0 new. Logic offline: 5513 passed.
  - **The take:** `build/captures/tr17/retake.mkv` (44 s, phone size, its zero at 4.55 s), with `retake_switch.jpg` (three switches at 8 fps from 0.125 s before each tap: the next figure is whole on the first frame it shows) and `retake_views.jpg` (the lead's screen, favourite lit, lock lit, rename with the phone's keyboard, the smallest phone's room, its rail at its foot). The case `Take: TR17's retake`.
  - **Visually reviewed:** by Faber on both sheets. Research's verdict on the retake: not yet. **Director-accepted:** no.
  - **For research, two calls built another way, with why:**
    1. **The rail scrolls on phones under 366 pt tall,** the four built pages whole before any scroll. The other way to no scroll: the three pages not built as small greyed dots under one "Soon", with no tap, until they're built.
    2. **The marks are in the band, not beside the name.** Between the slot columns the name's line has 153 to 178 authored px, and three 44 pt marks alone take about 150. In the band they stand right of Back, as the mock's top row.
  - **Tier 1 notices.** The currencies' chips are sized to their numbers. The favourite's grey glyph reads as a burst more than a star (the icons are Modulo's).
  - **Time:** about 4 active hours, my estimate, not measured. About half went to fix 1's cause.
  - **Research's verdict on the retake, 2026-11-15**, from `retake_switch.jpg` (three switches at 8 fps) and `retake_views.jpg`:
    - **Felt:** you flip through your Voidkin and each one is simply there, whole on its first frame, its name and rarity over its head. The band gives the stage back its height.
    - **Tier:** competent (grey). **The one bold thing:** still the live figure between its columns, now named over its head.
    - **The three fixes hold.** No empty stage on any of the three switches. The name is over the stage in its rarity's colour. "Leading" and "Not while leading" say why, and so does "Every bay is busy".
    - **Both of Faber's ways: accepted.**
      - **The rail scrolls under 366 pt.** The four built pages stay whole, and the "Soon" pages are the ones that scroll. Folding them into dots would hide what the director asked to see.
      - **The marks in the band, right of Back,** as the mock's top row. Rename's Save and Cancel take the band while the field is open.
    - **Fix (Faber), small:** the bag's tab row cuts its third tab mid-word ("Embler"). Make every tab fit, or let the row scroll with a fade at its edge. Serves the read. Check it on a still.
    - **Research's pass on the block is given once that's in.** TR17 stays open for its look, with Modulo's mock and AR12's colour (the level's mark included), then the director's eye.
  - **The tabs' fix, Faber, 2026-11-15.**
    - **Implemented.** The bag's five tabs stand whole in a row that no longer scrolls. Each is as wide as its name's share of the row, never under a 44 pt tap on the smallest phone, 2 px apart. A tab not built yet keeps its name, greyed, with "Soon" under it, as the rail's pages do (`VoidkinScreen/init.luau`, `bagTabs`).
    - **Tested.** The case `Voidkin screen (TR17)`: 257 passed, 0 failed, the lint clean in this window and on the smallest phone. One check is new: every tab whole in its row, none cut. The whole self-test, in the phone emulation with Studio in front: 1727 passed, 0 failed (265 s, 60 fps).
    - **Checked on a still:** `build/captures/tr17/retake_tabs.jpg`, the bag in the phone emulation and on the smallest phone: Shards, Items, Emblems, Jewels and Stones, each whole.
    - **Visually reviewed:** by Faber. Research's pass on the block: not yet. **Director-accepted:** no.
    - **Research's pass, 2026-11-15,** from `retake_tabs.jpg`, on the four phone sizes: the five tabs stand whole, and "Soon" greys a tab as it greys a page. **The tabs' fix holds, and the block passes.** One fix follows the director's word of today: the page is now "Items" (the dock's button is "Inventory"), so its gear tab can't also say Items. That tab reads **"Gear"**. Still open in TR17, and not part of this fix: Lead and Send to work move out of the right panel. **Director-accepted:** no.
    - **Built, Faber, 2026-11-15:** the Bag page reads "Items" on the rail, and its gear tab reads "Gear" (`VoidkinScreen/init.luau`, `SAID` and `KINDS`). Its case passes with a check on both words. No still.

- **Modulo's marks, delivered, 2026-11-15** (the director to Modulo, 2026-11-15, on the HUD's icons: "You made such high quality icons good job, do we need more? if yes please make more"). In `build/handoff/UI/voidkin/marks/`: `images/` (16), `voidkin_marks.json` and the sheet `voidkin_marks.png`, drawn by `tools/blender/voidkin_marks.py`.
  - **The rail's seven pages,** white, to tint by state: Overview (a head over its shoulders), Bag (a satchel), Kit (an ability's tile, a spark cut through it), Stars (one star and the next), Forge (an anvil), Jewels (a cut stone), War Emblems (a banner hung from its bar). Each is judged at 14 pt across, its size on a rail button at rest.
  - **Favourite, lock, rename:** a round heart, filled and in outline (the Healer's class mark is a cut heart and the Stars page is a star, so favourite is neither); a padlock, closed and open; a pencil over its line. Drawn at 16 pt in a 44 pt tap, and they work the same in the band.
  - **The level's mark** (the director, 2026-11-15: "also the levels text design of voidkin need to change"): a plate that leans as the bars do, a lit cap at its left with two rising chevrons dark on it, then "Lv" small and the number large. Three images (body, light, chevrons); it stretches with the number, shown at 3, 12 and 100.
  - **Combat Power's emblem,** the one image in colour: three shards rising from one foot, the middle one white-hot, in the Voidkin's lavender.
  - **For research, to rule:** the favourite's heart is lit in the Map's rose on the sheet, the one warm mark on the name's line; the room's lavender is the other way. Combat Power is shards, not a weapon.
  - **For Faber:** each image's tint and the plate's `cut` are in the json. Nothing is uploaded. The mock's rail (`hud_colour_sheet.py`, `rail`) now gives the chosen page's word its room (the pages after it stand 16 pt lower) and greys a page not built.
  - **Made:** yes. **Self-reviewed:** at 48, 24 and 14 pt on dark, in ink on a pale ground, and in place. **Content check:** PASS for delivery; before the upload it wants each exact file at 128 and 64 px over dark, the two plates alone. **Research's verdict:** not yet. **Director-accepted:** no. **Time:** about 1 active hour, my estimate, not measured.
  - **Research's verdict on the marks, 2026-11-15**, from `voidkin_marks.png` at 48, 24 and 14 pt and in place:
    - **Felt:** one family. The rail reads as seven distinct pages at 14 pt, and the chosen one's lit ring says where you are.
    - **Tier:** competent. **The one bold thing:** Combat Power as three rising shards, the middle one white-hot. Power is what you broke out of the void, not a borrowed sword.
    - **Rulings:**
      - **The favourite's heart is lit in rose,** accepted. It's a mark, not a room. It stays the only rose on this screen, and never on a portrait or an item frame (AR12's rule).
      - **Combat Power as shards,** accepted.
    - **The level's mark** (the director's note) passes: a leaning plate, the chevrons and a large number.
    - No fix. Faber builds from the json. The upload check wants each file at 128 and 64 px, as the content check says.
    - **"Do we need more?"** Yes, in this order, each when the screen that uses it is built: the bag's tab marks (Shards, Items, Emblems, Jewels, Stones), then each gear slot's empty mark (the twelve and the two hands, AR6's family).
- **Overview shows every stat** (research, 2026-11-15, 19:13, on the director's still of Overview and the words with it: `docs/decisions.md`; the spec is in `docs/ui.md`, 5, "Overview's stat sheet").
  - Overview today shows five stats. It gains the rest in three groups (Core, Attack, Defence), zero shown as 0. A rating shows "up to N%" at the Voidkin's level, and each line keeps its sources.
  - The rules already hold every stat, so this is display only. For Faber, after TR19's and TR20's fixes.
  - **Check, from the same still:** the experience bar under "335 of 4,320 experience to the next" (7.8%) shows only a sliver at its left. Either its fill doesn't draw, or the fill is too dark to see on the track.
  - **Checks:** the case's lint on the smallest phone, with the list scrolled to its foot. A still for research.
  - **Built, 2026-11-15, night (Faber).** The stills: `build/captures/overview/stat_sheet_smallest_phone.png`, at the smallest phone's size, three views: the top (the level, its bar, Core), the middle (Attack) and the foot (Defence, then Now and Gear).
    - **Implemented.** `Rules.Sheet`, pure, writes every line: the 19 stats in Core, Attack and Defence, a zero as 0. A rating gives its points and "up to N%" at the Voidkin's level against a foe with none, as `Rules.Hit` sums it, and Critical counts its floor. The percents are percents, and each line's sources stand under it. Overview draws the groups under quiet captions.
    - **The experience bar's sliver was a bug,** in the kit: `Bar` read its width as an offset alone, so a bar sized by its parent lit about a pixel at any share. It now measures its drawn width and relights when it changes. The Breaker's crack bar under a chamber had the same fault, so it now fills as the shard breaks.
    - **Tested.** Type check 0 new. Logic 5971 offline, with the sheet's four cases. The self-test "Overview's stat sheet" passes 18 of 18: every line's value and sources against the rule, each group in order, a parent-sized bar at 7.8% lit 0.083 of its length, the lead's bar 0.144 for 0.141, and the lint clean on the smallest phone at the list's foot. "Voidkin screen (TR17)" passes 264 of 264. The stills take passes.
    - **Tier 1 calls:** Hit and Critical Resist have no chance of their own, so each says "Lowers a foe's Dodge and Block" or "Lowers a foe's Critical". A rating at zero reads "0", never "up to 0%". Critical Damage lists its base 50% first. Elemental Attack names its element, or says "No element: no second hit". Lifesteal past its cap says what counts. Damage Bonus reads 0% for now, since no signature or passive gives it; Damage Reduction gives Second Wind's 20% "below 30% health".
    - **Visually reviewed:** yes, research's pass below. **Director-accepted:** no.
  - **Research's read of the stills** (2026-11-15, 21:05). **Felt:** every stat is there, each with one plain line of what it does ("Lowers a foe's Dodge and Block") and where it comes from. The experience bar now shows its 14%. **Tier:** competent. **The one bold thing:** the plain line under each stat, which teaches the sheet without a help page. No fix, and Faber's tier 1 calls stand. Closed. The Breaker's crack bar, now filling, is read at the first session's review.
  - **The stat model, built, 2026-11-15, night (Faber),** on the director's yes (the register; `docs/balance.md`, "The stats" and "One hit"; `docs/ui.md`, "Stats, shown honestly"). The stills, at the smallest phone's size: `build/captures/overview/stat_cells_top_smallest_phone.png` (Core's top) and `stat_cells_tap_smallest_phone.png` (Hit's tap open).
    - **Implemented.** `Rules.Hit`: a critical leaves the capped bucket and multiplies on its own, x (1 + Critical Damage - the target's Critical Guard), never under x1, with no ceiling (`Result.CriticalFactor`). The elemental hit is never critical. `Rules.Stats` gives a Voidkin's base (its level 1) and its level's gain as two sources. `Rules.Sheet`: each stat one total, never "up to". A tap lists its sources in order (Base, Level N, Stars, each slot, then forge and the rest as they join the resolver), rounded to add to the total, then its notes, a rating's chance against a foe of its level with the same points last. Overview shows two stats a row, each its name over its total, its sources opening under its row.
    - **Tier 1 calls.** Two a row: a tap must be 44 px at the smallest phone (the kit's 52 authored), and a 52-tall line showed one and a half stats in the window there, so two a row keeps the sheet as dense as the old lines. The notes' and chance lines' words. Combat Power's weights stay the stand-ins they were (research's seeds, TR17 fix 10).
    - **Tested.** Type check 0 new. Logic 7,331 passed, offline and in Studio. The self-test "Overview's stat sheet" passes 38 of 38: every total against the rule, two a row in order, a tap opening Health's sources as `Rules.Sheet` lists them with the base first, Dodge's chance last, a tap moving and closing it, and at the smallest phone the lint clean (every tap 44 px) with Hit's tap open and every note fitting. "Voidkin screen (TR17)" passes 264 of 264. The stills take passes 4 of 4.
    - **Visually reviewed:** research's pass waits. **Director-accepted:** no.
  - **Research's pass on the stat model's stills** (2026-11-15, night, both whole):
    - **Felt:** a character sheet that answers. Every stat has its name over its number, two a row, and a tap opens what it means under its own row. No "up to" is left anywhere.
    - **Tier:** competent. **The one bold thing:** the tap opening full width under its row, so the sources and the chance stand right under the stat they explain.
    - **No fix.** Two a row is Faber's tier 1 and stands: it's denser than the lines, and every cell is a full tap.
    - **Closed** as a block. Combat Power's weights are research's next seeds (fix 10).
  - **Research's seeds for fix 10, Combat Power's weights** (2026-11-15, night; tier 2, Faber's build). They live in `tools/balance/seeds.json`, "combatPower", fitted by the sim's section 16.
    - **The weights,** a point, into `Config.Stats.Power.Weights`, Scale 10 kept: Health 0.53, Attack 4, Defence 3.1, Regen 3.1, Hit 0.53, Dodge 2.1, Critical 1.2, Critical Resist 0.2, Block 1.4, Penetration 0.88, Elemental Attack 5.2, Elemental Resist 0.34, Critical Damage 110, Critical Guard 110, Lifesteal 770. Each is what a point adds to winning, Attack's held at 4, averaged over the four specs on budget, as the fighter and as its foe, at levels 5 to 60.
    - **One change to `Rules.Stats.Power`:** a percent's weight multiplies by G at the block's level. That covers Critical Damage above its base, Critical Guard and Lifesteal. A percent multiplies points, which grow with G, so a fixed weight would count 10% Lifesteal the same at level 1 and at level 60, where it multiplies 22 times the points. A case: the same percent gives G(level) times its level-1 power.
    - **What they give:** the higher number wins 97% of same-level duels with no type edge, and every duel where one side wins 10% faster. The stand-ins managed 90% and 95%.
    - **Its limit:** a sum can't see that spreading points beats stacking them. Of one budget spent two ways, it picks the better about half the time, with the two at most 14% apart. Every refit I tried traded duels away for it. A measure against a panel of every spec picks the better 90% of the time, but it isn't a sum (`docs/polish-later.md`).
    - **My line in fix 10 is withdrawn.** Combat Power can't make rarity count for more than four levels, because it follows the fight. An Epic's x1.26 on its own base is worth about two and a half levels at level 8. Bare, Pip at level 12 beats Ironhymn at level 8 about a third faster, and the seeds show it, 27,640 over 25,222. At the same level the Epic wins clearly. If rarity should be worth more, that's `rarityBase` in `docs/balance.md`, not Combat Power.
  - **Fix 10 and the plain list, built, 2026-11-16 (Faber),** on research's seeds above and the director's word in the builder's session, 2026-11-15: "dont put any description for stats make it like taichi panda dragon hunter overview!", then "Plain list, no taps" to the builder's question.
    - **Implemented.** `Config.Stats.Power.Weights` holds the seeds. In `Rules.Stats.Power`, a percent's weight (Critical Damage above its base, Critical Guard, Lifesteal) multiplies by G at the block's level. `Rules.Sheet` and Overview: every stat as a name and its number, two a row, under the groups' quiet captions, with no tap, no sources and no line of what it does.
    - **Tested.** Type check 0 new. Logic 9,870 passed, offline and in Studio, with the case that a percent gives G(level) times its level-1 power. The self-test "Voidkin screen" passes 300 of its cases. Its 2 fails are TR20's manual pointer take, which the filter picked up and which waits 90 s for an outside driver that wasn't run.
    - **Visually reviewed:** research's pass waits, at the first session's run on a phone. **Director-accepted:** no.

## TR21. The base screen and the base's levels (Faber)

Research's entry, 2026-11-15, night, on the director's words (`docs/decisions.md`, the two rows on the base). The design: `docs/design.md`, "The base", and `docs/ui.md`, 7. The looks: AR14.

- **Feel line:** at home, the player taps the Base tile and the camera lifts over their whole base. Every machine shows what it's doing and what it can become, one tap upgrades it, and they watch it change below them.
- **Blockout first, since the screen is new:** the camera's lift and plain chips over today's base, in the game, one take for research's verdict. Then the build.
- **The block contains:**
  - the command view, the chips, a machine's panel, and the base's level with Upgrade;
  - the base's level, 1 to 3, saved on the account and bought with Credits on the server in one step, never twice on a repeated request;
  - what each level opens: bays, two, four and six; the machines' ceiling; the battery's cap;
  - each machine's level under the base's;
  - the gain shown before buying;
  - the look switched in the world, with stand-ins until AR14 lands;
  - the Power screen moved in as the screen's tab;
  - a logic case for each rule.
- **The tile:** at home, the Base tile opens this screen, so TR19's quiet tile at home and TR20's fix 2 ("You're home") go.
- **Waits:** levels past 3 and their items, the showcase, and an upgrade's ceremony beyond the live change.
- **Numbers:** the costs come from research's sim (`docs/balance.md`). Stand-ins in `Config` until then.
- **Tests, in proportion to risk:** the cases on the spend and the rules, plus one take.
- **Order:** after Overview's stat sheet.
- **The rules and the blockout, built, 2026-11-16 (Faber); parked at research's order** (phase 2's order, ef83330), with the take waiting for research's verdict.
  - **Implemented, the rules** (`docs/engineering-plan.md`, "The base's levels"):
    - The save holds `Base.Level`, `Base.Machines` and each bay's `Level`. Migration 5 gives each bay level 1, and a base with fewer than level 1's two bays gains an empty one.
    - `Rules.BaseLevels` reads `Config.Base.Levels` and `Machines`. Research's seeds are in for the battery's cap. The prices, the bays, the ceilings and the machines' gains are stand-ins until the sim's.
    - `Base.UpgradeBase` and `Base.UpgradeMachine` take Credits on the server in one step. Each names the level it buys, so a repeat or a second tap with a fresh operation id is Stale, never charged twice. Past the cap it's Cap, past the base's ceiling it's Ceiling, and fewer Credits than the price is Short.
    - A base level opens its bays empty. The Breaker's level adds its third chamber at 8 and its fourth at 20. A bay's level raises its worker's kW and the Breaker's raises its speed. The battery's cap comes from the base's level, read by every screen and the server through `Breaker.Capacity`.
  - **Implemented, the blockout** (`UI/BaseView`, `Config.BaseView`):
    - At home, the Base tile lifts the camera over the whole base from the gate's side, as far as the machines' box needs, in 0.9 s.
    - A plain chip hangs over each machine and bay: its name and level, and what it's doing now. A locked bay says which level opens it.
    - The chips never cover each other or the level panel: the nearest stands at its machine, and each other takes the nearest free place over or under one already placed.
    - The base's level stands at the top, with what the next one opens and its price, beside Close.
    - The HUD and the machines' own plates step back, and the avatar stands still. Roblox's PlayerModule now lives under StarterPlayer and takes `ControlModule.Enabled`.
    - Close brings the camera back behind the lead.
  - **Not built, the build after the verdict:** the machine's panel, Upgrade, the Power tab, the look switched in the world, and retiring the quiet tile and "You're home".
  - **Tested.**
    - Type check 0 new. Logic 9,870 passed, offline and in Studio, with `BaseLevels`' cases and TR21's three: the base's level, a machine's, and what a level does.
    - In the self-test, "Base view" passes 34 of 34, "HUD: TR19" 53 of 53, "Power" 88 of 88, "Breaker:" 139 of 139 and "Battery" 2 of 2. "Base: the plot's Breaker, bays" passes 28 of 28.
    - Two cases changed with TR21. A bay beyond the open ones can't show locked until AR16's plot brings its spots, since level 1 opens two bays and today's plot has two. The lift is now measured over the machines' floor, since the self-test's pad stands far above it.
  - **The take:** `build/captures/tr21/command_view_desktop.jpg`, opened by a real tap on the desktop (1655 by 756), on today's base.
    - On a phone, Studio's tools can't take it. Under the device simulator, the MCP resets the client's camera between calls, and the viewport doesn't draw while a call runs. Inside one call the game holds the view for 40 s with no change. The phone's look waits for the first session's run.
    - The take re-runs as "Take: TR21, the base's command view held open from home".
  - **Visually reviewed:** research's verdict waits. **Director-accepted:** no.

## TR23. Day in the world's turn (Faber, then Modulo's day sky)

The director to Faber, 2026-11-16, after the base's install: "i feel like the world it a bit to dark and somber we need a day time". Asked how, the director picked "Add day to the cycle" in the builder's words: "Day, then dusk, then night, then back to day, across the whole world. Dusk and night keep their looks and get a smaller share of the cycle (my first split: day about 60%, tuned live). The lanterns and the void machines' glow fade by day and light up at dusk. A day sky is needed: our own, drawn by Modulo, or Roblox's built-in sky until then." The director also picked "Next piece, now": built before the Door's name, and the phone run then judges the light players will actually see. Then, to Modulo, read at 02:02: "we need a day / dusk sky box btw ask faber + lightning/atmosphere etc". Modulo draws the day sky and its seeds.

- **Feel line:** a player comes back to the festival in full day, a blue sky over the navy houses and the paper lanterns, the void machines still faintly lit. The afternoon slips into dusk and the lanterns come up, then night, then morning again.
- **The block contains:**
  - Day in the turn. `Rules.Night` holds each look of `Config.Lighting.Cycle.Order` for its Hold and crosses into the next. The seed is 30 minutes: 18 of day, 5 of dusk, 4 of night, and a minute's crossing between each.
  - `Config.Lighting.Phases.Day`, first the builder's seed on Roblox's built-in sky, then Modulo's Day sky with his seeds once it came (2f3430a), within the hour. Its sun is painted in the faces at `Toward`.
  - The day's shares: Glow is the share of the kit's glow (floors included), and Lights the share of the street's and the lead's lights. Both are full at dusk and night.
  - The debug jump takes the new phases ("Day", "ToDusk", "ToNight", "ToDay").
- **Waits:**
  - Research's verdict in the game.
  - The phone run.
  - The director's mist word, read by Modulo at 02:16: "a bit to much atmosphere imo like that mist is a bit to much". It was said on the first sheet, and the Day's haze is thin for it. Whether it also means the game's dusk haze (Haze 1, AR5's numbers) is with research.
  - A second dusk sky. Only if the director's "day / dusk" asks for one; Modulo asks the director.
- **Built, 2026-11-16 (Faber).**
  - **Implemented** in `Rules.Night` (the turn as an order of looks, `Night.Turn`, `Night.Phases`), `Config.Lighting` and `LightingController` (a sky per phase; the shares in steps of 0.02, so a crossing re-dresses the pieces about 30 times, not each frame). The two glow cases that computed a piece's glow read the live share too.
  - **Modulo's Day sky:** six faces uploaded under the group and Approved (`docs/asset-log.md`). His seeds are in `Phases.Day`: sun #FFE2B8 at 2.6, fill #8A8496, the sky's share of the fill 0.5, and a thin haze (Density 0.16, Haze 0.2, Glare 0.1). Floor, Glow and Lights are the builder's.
  - **Tested.**
    - Type check 0 new.
    - Logic cases: offline and in Studio, 9,936 passed. They cover the turn, each crossing's ease, the jumps, Day's look, sky and shares, and every phase in Config being in the turn.
    - Self-test: "Lighting" 47/0, with day's look, sky, glow share, lights share and the lead's light.
    - The whole suite: 2,202 passed, 0 failed, at 60 fps; the world report is empty.
      - The first whole run failed 17. Three were the Breaker chambers' case, which wanted a glow without the day's share; it's fixed.
      - The other 14 followed the camera case's one failure (TR11) through the Haymaker and plate cases. Each passed alone and in the second whole run.
    - In the game: the day-to-dusk crossing eases the brightness, and the sky swaps under the haze's peak at 29.6 s of 60. The client held 57 to 58 fps.
    - A single frame of about 90 ms came at about 26 s in two of four day-to-dusk crossings. It wasn't there in the other two or in dusk-to-night, and holding the lights didn't settle it either way. It's not attributed; the phone run watches for it.
  - **Visually reviewed:** the builder's captures only, at the spawn and on Lantern Row by day, on each sky.
    - On the built-in sky, the paving took a strong lavender-blue cast.
    - On ours, the base stands under big anime cumulus, and the paving is greyer and less blue. Lantern Row is clear far up the street with no mist, the navy houses and the lanterns read against the sky, and the clouds sit over the lanterns.
    - Research's pass is wanted.
  - **Director-accepted:** not yet.

## TR29. The Tower's run, in grey (Faber)

Part 12's order, item 4.7 (`docs/research/rework-2026-11-16.md`, part 8; `docs/design.md` and `docs/balance.md`, "The Tower"; the contract in `docs/engineering-plan.md`, "The Tower's run"), on the director's yes of 2026-11-16, 16:50. Taken while 4.6 waited on AR19's Stages II and III, which came in at 20:00 (e516da7).

**Scope, set at the start (19:33, written here at the close).** The feel line is research's to write at the finish. The block follows design.md's "A run" line by line.
- **The block:**
  - `Config.Tower`: research's seeds for the foe, and the builder's for the rewards, fast floors and world.
  - `Rules.Tower`: the foe, its build, fast floors, the heal cap, a floor's reward, the ring's spot, and the ledger.
  - The save's `Progress.Tower`, and each plot's `TowerRing` marker.
  - `TowerService`, and FightService's rival.
  - The freeze on the lead, its stars and its Regalia.
  - The client's grey platforms with the column, the floor line and the results screen.
  - Studio's commands and the cases.
- **What waits:**
  - The void-light look: the foe's, and the platforms assembling and falling as light.
  - The leap's arc, and the platform's rise carried in motion (today the pair is set down at mid-rise); the camera; the sounds.
  - The rarity light on rare rewards.
  - Items as rewards: the Dawn series, and the Tower's own chest table.
  - Research's fit of the seeds below.
  - Captures from the player's camera, for research's pass.

**The build (19:33 to 20:04 by the clock).**
- **The rules, pure (`src/shared/Rules/Tower.luau`):**
  - **The foe:** floor f's foe is a Voidkin with a model, drawn from the run's seed. The pool is Kirra, Lyric, Pip and Rook. Its level is `1 + (f - 1) × 0.5`.
  - **Its build:** the engine has no build share for a Voidkin row, so `Block` resolves the foe's own figure at its level and lifts each stat by `Config.Tower.Lift`, then its health by 0.55. The Lift is the model's 0.45 build over the own figure at level 30. It's read from `tools/balance`'s model, not from play.
  - **Rewards:** `Reward(floor, best, seed)` gives Credits and maybe a chest.
  - **Healing:** `Capped` never cuts a fall in health and spends the floor's room.
  - **The ledger:** `Start`, `Won` (the next floor and this run's id only), `End` (grants once, raises `Best`, writes `Results`), `Recover` and `Seen`.
- **The server (`TowerService`):**
  - **Starting:** the avatar inside its plot's ring, with a lead, out of a fight, starts a run.
  - **Each floor:**
    - The rise takes `Rise` seconds. At `Leap` of it, the pair is set down on the new platform, and the server holds that floor's collision only.
    - The foe spawns for this player alone.
    - A won floor is one transaction on the ledger.
  - **How it ends, always on the server:**
    - The lead's fall, after 1.2 s.
    - Stepping off the platform by `Out.Side` or `Out.Below`.
    - A respawn, leaving the game, a world re-lay or a shutdown.
  - **A crash** leaves the `Run` in the save, and the next join ends it.
- **FightService:**
  - **The rival:** registered as a Shade of kind "Rival" for one player (`For`). Only that player's lead targets it, and it targets only that lead. It never gives up or resets, and its area strikes skip other players' fighters. It wears "RivalLook", a grey Highlight standing in for void light.
  - **Healing:** regen and mending pass one `heal()`, which spends the floor's `HealRoom`. The room is 0 between floors and `HealCap` of the lead's health in one. Lifesteal joins there when it's wired.
  - **Fast floors:** a foe `Fast.Gap` levels under the lead is `Frail`. It falls to the first hit that lands, and the next rise takes 0.8 s.
- **The freeze (D10):** `FightService.Frozen` is true during a keeper's try or a run. While it is, the lead change, the lead's stars (`SpendCopies` on the lead) and every Regalia action are refused with "InCombat". Equip had no guard at a keeper's try before, so this closes D10's gear rule there too.
- **The world:** the ring lies on each plot's crossing end, where the sleeping Tower stood (`WorldService`). `plan.json`'s TowerSleeping placement is now unused. That file is Modulo's, left for it.
- **The client:**
  - **`TowerController`:** every runner's platforms, the floor's and two below. The newest assembles in 0.35 s, Back Out. Older floors fold into one column, and at the end everything falls away in 0.6 s. The own floor line reads "Floor N · best M".
  - **`TowerScreen`:** the results open once from the save: the floor, the record, opponents defeated, Credits and chests. Closing them sends `Act("TowerSeen")`.
- **Studio:** `TowerStart`, `TowerWin`, `TowerFell`, `TowerEnd`, `TowerState`, `TowerHurt`, `TowerOff`, `TowerCrash`, `TowerRecover`, `TowerBest`.

**Faber's seeds, for research's fit (tier 2, `Config.Tower`).**
- **Credits:** a floor pays 2 kills' Credits at its foe's level, and twice that on a floor past the record.
- **Chests:** the chance is 0.01 per floor, at most 0.5. The chest is the Elite Chest (tier 2) of the ground the foe's level stands in. With Lantern Row alone, that means Uncommon at best, against balance.md's "Rare and better come from the Tower".
- **Fast floors:** 10 levels under the lead, and the rise takes 0.8 s instead of 2.5.
- **The pool includes Lyric (Rare),** where `tower.py` draws Commons.
- **The run's length** is research's question in balance.md ("Not known").

**The checks (20:04).**
- **Type check:** 0 new, 11 known.
- **Logic, offline and in Studio:** 23,212 passed, 0 failed. Tower's 8 cases cover the level, the pool and the seed; the ring's spot on both sides; the block's lift; fast floors; the heal cap; the rewards and chests; the ledger; and recovery.
- **World report:** empty (one ring per plot).
- **Self-test, the Tower's case** (`TowerCases.luau`, joined in the runner, since `Cases.luau` is at the type checker's limit): 43 passed, 0 failed, at 60 fps.
  - **The run:** it starts from the ring's step. Each floor's foe comes from the pool, at its level, in its look and for this player. The heal room is within the cap in a floor and 0 between floors. The avatar stands on each platform.
  - **The freeze:** gear, the lead and its stars.
  - **The ledger:** each floor's reward written once, and nothing granted mid-run.
  - **The platforms:** three standing, and the column under them.
  - **The fall:** the run ends at its last floor won, granted once, with the record. The platforms fall away.
  - **The results:** they open once, are cleared when closed, and don't open again.
  - **Endings:** stepping off ends a run, and a crash's run is ended at the join with its ledger granted.
  - **Cleanup:** the save is put back as it was.
  - **The hurt-then-heal check** runs only when the floor lasts its 1.5 s. A level-1 foe can fall sooner, as it did in one run of three. `Capped`'s logic cases cover it either way.
- **The whole suite: NOT VERIFIED.** It started at 20:05 to prove nothing else regressed (FightService, the lead, the Regalia), and the PC locked during it (LockApp; the client drew 0 frames a second, its viewport 1×1). It hung on a case that needs frames and was stopped at 20:25. It runs again once the screen's unlocked.
- **Not done yet:** captures from the player's camera.

**Notes for the finish and research.**
- **The rival has no passive** (`passiveOf` is the lead's side only).
- **The heal cap is a guard today.** Lifesteal isn't wired (`docs/balance.md`).

**Research's fit and feel line (Quaestor, 2026-11-16, 20:34).** `tools/balance/tower.py` now reads Config.Tower, with fast floors in (T4 to T6); the results are in `docs/balance.md`, "The Tower".
- **Feel line:** the player and their lead climb a column of light, the easy floors snapping past a beat each and the hard ones real fights with health as the clock, until the fall drops it all away as light and the results land on the floor reached and the record beaten.
- **Today's seeds overpay** (T4): the Tower's Credits an hour come to 2 to 36 times Lantern Row's, and its chests to 18 to 893 an hour, against the grounds' 43.
- **For Config:**
  - **Only hard floors pay:** a fast floor gives no Credits and no chest. It's the free ride to where it gets hard.
  - `Credits = { Share = 0.34, Record = 2 }`: half Lantern Row's Credits an hour at levels 10 to 15. The Tower pays the gear; the grounds pay the Credits and experience.
  - `Chest = { Base = 0, PerFloor = 0.0018, Most = 0.5 }`, the chance by the floor's number: about 15 chests an hour of runs at level 10, and 18 at 15.
  - **The chest is the Tower's own:** one row in `Config.Chests`, in place of `Tier`, with Common 60, Uncommon 36.32, Rare 2.86, Epic 0.57 and Legendary 0.24. Lantern Row's foes would read only row 2, Uncommon at best.
  - **The windows:** it meets them (Rare 3.5 h, Epic 12.5, Legendary 39.9) if a player spends half their play after the first hour in the Tower, which is a guess. A quarter gives 6.0, 24.1 and 78.8 h.
- **Kept:**
  - Fast floors at 10 levels and 0.8 s: 12 s at level 15. Past level 25 the stretch passes 30 s; that's for the refit when the grounds open.
  - Lyric in the pool: a Rare foe moves a run by a floor at most (T3).
  - The heal cap.
- **The run's length:** about a minute at launch, nearly all of it hard floors. It's judged at the first capture.
- **Refit when Drum Court opens:** past launch, the Tower's Credits fall to 7% to 26% of a ground's at the lead's level.

**Faber's carry of the fit (2026-11-16, 20:40).**
- **Config:**
  - `Config.Tower`: `Credits = { Share = 0.34, Record = 2 }` and `Chest = { Base = 0, PerFloor = 0.0018, Most = 0.5 }`, with `Tier` gone.
  - `Config.Chests.Tower` is the Tower's row.
- **The rule:** `Tower.Reward` and `Tower.Won` take whether the floor fell fast, and a fast floor pays nothing. TowerService passes the fight's own `run.Fast`, so the pay matches how the floor was fought.
- **The chest:**
  - The Tower's is a fourth chest tier, "Tower Chest of <ground>", one for each ground. It belongs to the ground the foe's level stands in, since an item's worth comes from that ground.
  - Its odds and its roll read `Chests.Weights`: the Tower's row for a Tower chest, the ladder's row for any other.
  - On the bag's cell it says "Tower Chest".
- **The checks:**
  - Type check: 0 new.
  - Logic, offline and in Studio: 23,240 passed, 0 failed. The new checks:
    - a fast floor pays nothing, at every floor;
    - forty fast floors leave the ledger empty, then a hard one pays;
    - the Tower's chest reads its own row in every ground;
    - 20,000 rolls of Lantern Row's land near each share, Legendary included, which its ladder rows never give.
  - The Tower's self-test case: 44 passed, 0 failed, its ledger counting only hard floors.
  - `tools/balance/tower.py`'s T6 reads the new Config: 15 chests an hour and 50% of Lantern Row's Credits at level 10, and 18 and 48% at 15.
- **The chest's frame, on research's word, built by 20:44:** no chest takes a rarity's frame. A rarity frame says what a thing is, and on a chest it would say what it might be ("up to", which `docs/ui.md`'s "Stats, shown honestly" rules out). Before this, a cell took the best rarity it could give, so a Tower chest was framed Legendary.
  - **The change:** a chest's entry carries no rarity (`Rules.Bag`), and its cell and its card's head get the bag's plain edge, with no band and no Legendary ground. Its odds stay on its card.
  - **Its own picture**, naming its kind, is AR21 (research has asked Modulo, after AR6's batch 3). Until it comes, the cell says its kind in words.
  - **The names,** on design.md's "Chests" (236c0c3): tier 1 is the "Shade Chest", never "Common Chest". The cell's word follows. A logic check holds that no chest's name uses a rarity's word.
  - **The checks:** logic 23,240/0, with the bag case's chest checks rewritten. The bag's self-test: its flow passes, and the same 11 layout checks as TR28's fail on the 1×1 viewport, NOT VERIFIED.
  - **Research's answer (20:42): change it, for every chest.** A chest's cell takes no rarity's frame: the bag's plain edge, its own picture naming its kind (Ordinary, Elite, Keeper's, Tower), and its odds on its card. A rarity's frame says what a thing is (`docs/ui.md`, rule 3). On a chest it would say what it might be, the "up to" the stats never show ("Stats, shown honestly"): the Tower's would be a Legendary frame on a box that gives a Common 60% of the time.

**Read on the unlocked screen (Faber, 2026-11-16, 21:04 to 21:05, by the PC's clock).** Stills `build/scratch/faber/stills/tr29-ring`, `tr29-floor9` and `tr29-summary` (scratch), for research's verdict. The suite's Tower case passes on render (27847da).
- The ring reads as a faint pale disc, with no word on it.
- After 11 fast floors the results say "+0 Credits" and "No chests this run", which is right by the fit, but the screen doesn't say why. It shows two Close buttons.

**Research's verdict on the read (Quaestor, 2026-11-16, 21:20, from the stills).**
- **Felt:** the climb runs as a block. But the way in and the way out don't explain themselves: nobody finds a faint disc, and a new record that pays "+0 Credits" reads as broken.
- **Tier:** works, for a block.
- **Fixes:**
  1. **The ring reads as the Tower's way in from the base:** a column of light rising from it, the feel line's own, with its name. In grey, a tall light is enough.
  2. **The results say why a run paid nothing:** one line that easy floors pay nothing and rewards start where the fights get hard, with that floor for the lead. The words are the game's.
  3. **One Close,** at the bottom, under the thumb.
- **The grey foes and platform** are the block's.

## TR32. The first session, measured (Faber)

On the director's "ok" of 2026-11-16, 21:39 (`docs/decisions.md`). Nothing players see, so no feel line. At the soft opening it shows where new players stop, against the north star's first measure.
- **The block:**
  - Roblox's own onboarding funnel (`AnalyticsService:LogOnboardingFunnelStepEvent`), from the server, at each beat of `docs/north-star.md`'s first session that the build has:
    1. Arrive: the first join.
    2. Choose: a starter picked.
    3. Reveal: its shard broken.
    4. Fight: the first Shade falls on Lantern Row.
    5. Find: the Named shard picked up.
    6. Work: the first worker in a bay.
    7. Build: the first item equipped.
    8. Want: the keeper's gate reached.
  - Each step logs once an account, from the step's own server act, never on the client's word.
  - It's Roblox's built-in analytics in the Creator Dashboard, at no cost. No personal data goes in a step.
  - A case: each step logs once and in order, and a repeat doesn't log it again.
- **What waits:**
  - Economy and custom events (Credits in and out, the chests' opens), with the store.
  - The dashboard's read, which needs live players.
- **Order:** Faber's call. It's about an hour, so it can go in beside TR31.

### The build (Faber, 2026-11-19, 16:26 to 16:35 by the clock)

- **The rule,** pure Luau (`Rules.Funnel`): the eight steps in the block's order, each its number; which steps a committed act's answer makes true (a starter picked, a shard opened, a kill: Fight, and Find when its drop carries the first kill's Named shard, a worker set, an item equipped); and the mark on the save, refused when every step given is marked already.
- **The service** (`FunnelService`): it hears every committed change with its label (`DataService.Changed` now carries it), marks the steps in their own transaction, and logs them only once the mark commits. Arrive comes on the first join. Want is a look every second for an avatar within the Challenge's reach of the keeper's gate (`Config.Combat.Keeper.Reach`). A step carries its number and name, nothing else.
- **Old saves:** migration step 10 marks all eight on a save that chose its starter before the funnel existed, so test accounts never log a first session they didn't play. A new account starts with none.
- **Tested:**
  - five logic cases (26,802 checks, offline and in Studio): a first session logs 1 to 8 once, in order; replayed, nothing; a refused act, a recall, an item taken off, an act the funnel doesn't read: nothing; a kill without the Named shard: Fight alone; the marks save; step 10;
  - in a playtest, through the Equip act's own path: Build marked and logged once ("7 Build"), and its repeat with the same op id, a second equip and a refused pick log nothing. The account's marks are put back. Studio logged one onboarding event. 12/12. Type check 0 new.
- **NOT VERIFIED:** Want, whose case runs in the Festival place only, the one place with the keeper's gate (item 9). The dashboard's read waits for live players.
- **Debug:** `Funnel` reads an account's marks and what this server logged; `FunnelSet` sets the marks.

## TR33. Inspect another player (Faber)

On the director's "YES" of 2026-11-16, 21:39 (`docs/decisions.md`). Tier 2, research and Faber: a new view players see. It serves the north star's measure "two players compare builds and argue about which is better", and it takes TR22's wait, the plinth's tap (Dragon Hunter's View Character).
- **Feel line:** a player taps someone in the street, or their Voidkin at the gate, and that player's lead stands there as they built it: its Combat Power, its gear and its sheet. The player sees who's ahead and why.
- **The block:**
  - A tap opens the character screen in a visitor's mode. It works on another player's avatar or lead within reach, showing their lead, and on a base's plinth, showing the plinth's Voidkin.
  - It shows the Voidkin large and turning, with:
    - its name, class, level and stars;
    - its preset's slots, each item's icon and forge rank;
    - Combat Power at its feet;
    - the stat sheet.
  - A tap on an item opens its card, with no Equip and no bag.
  - The owner's name is at the top, with a close. Nothing else of their save shows.
  - The server builds the view from the owner's save through the one resolver, never from the asker's client. It answers one ask at a time a player, within a rate limit.
  - A case: the view holds only the sheet's fields, and an ask past the limit is refused.
- **What waits:**
  - A comparison with the asker's own lead.
  - Visiting another player's base (TR22).
  - A list of the server's players to inspect from.
- **Tests:** the case, and one take from the player's camera with two players in a Studio test server.
- **Order:** after TR31.

## TR34. Opening chests (Faber; the look is Modulo's AR24)

Research, 2026-11-17, 02:21.
- **The design:** `docs/design.md`, "Chests". "Open all" opens a stack in one server step and shows one summary sorted by rarity, rare items lit, and an Epic or better gets a short reveal of its own.
- **The director's words** (`docs/decisions.md`): 2026-11-16, 21:39, Dragon Hunter's flow with Sailor Piece's feeling; 2026-11-17, 02:16 and 02:20, the clip and the band.
- **The study:** `docs/research/chest-opening.md`.

**Feel line:** the player taps Open all on a stack and the haul lands at once. A dark band crosses the screen, the items pour into its middle from common up, the best lands last and largest in its rarity's light, and OK puts it all in the bag.

**The beats.** Every time is a number in `Config.Chests.Opening`, tunable live:
1. **The ask:** a stack's tile offers Open 1 and Open all. There's no typed amount, because in the clip the phone's keyboard covers half the screen. The band opens on the tap, before the server answers, so the wait reads as the build-up (anticipation). Its items come when the answer lands.
2. **The band,** the director's form: a translucent black band across the whole width, about a third of the screen high, centred. The title is on top ("37 Shade Chests of Lantern Row"), the items are centred in the middle, and OK sits under them.
3. **The pour:**
   - identical items combine into one tile marked ×N;
   - the tiles arrive one by one from the lowest rarity up, each with a tick (seed: 60 ms apart, all in within 1.5 s);
   - the climb is the chance being felt.
4. **The best:** the highest rarity lands last, a size up, in its rarity's light, with a sting (hitstop on the band, 80 ms). An Epic or better first gets its own short reveal, which a tap skips.
5. **The rest of the haul:** Credits and forge stones, as one line under the title in their own colours.
6. **OK:** closes the band. Everything is already in the bag (the server's one step), and new items are marked new.
- **A big open:** at most two rows of tiles. Past them, "+N more" opens the bag filtered to what's new. A tap during the pour finishes it at once.
- **One chest:** the same band with one tile, and the reveal if it's Epic or better.

**The block:**
- **What it holds:** the band, the pour and the best's lift, inside the 90-minute cap, with AR6's item art and the real rarity frames. AR13's cues stand in for the tick and the sting.
- **How it's opened:** from debug stacks of 1, 37 and 500.
- **How it's judged:** research's verdict in motion from a phone capture, then the director's look.

**Waits:**
- The look: Modulo, AR24, from this entry.
- Its own sounds.
- Dragon Hunter's flow: when its clip lands, research reads beat 1 against it, and any difference goes to the director before the finish.

**Checks:**
- On a phone, a 1, a 37 and a 500 open: the time from the tap to the last tile; the best one read at a glance; OK under the thumb; nothing past two rows.
- A repeated tap opens nothing twice (the open's id).

**Cost:** none.

## TR35. Music, and the two sliders (Faber, with the director's ear)

Research, 2026-11-17, 01:39. From the sound study (`docs/research/sound.md`, "What sound is worth, music, and what we skip" and "Next", item 2), after the director's phone run ("no SFX that add depth"). Tier 2: a new thing players hear, research and Faber. It follows AR13's six cues. (TR34 is kept for the chest's opening.)

**Feel line:** from the first second at the base a track sets the night, calm and wide under the machines' hum. Through the Festival Door the grounds' track picks up the drive, and when the Lamplighter steps in its track takes over. The player never hears a seam.

**The block:**
- three tracks from Roblox's licensed library, each with an alternate in Config;
- a crossfade at each place (a seed of 2 s), and the keeper's swap at its entrance;
- the music's own fader, ducked under the reveal and the signatures, never under ordinary hits;
- two sliders, Music and Effects, saved with the player, in the smallest settings panel the kit gives.

**Waits:** music that adapts beyond the keeper's swap, the reward sounds' layer in the music's key, and any music for a trailer, since the licence is in-game only.

**The briefs** (`handbook/visuals/audio.md`, "Brief"). For all three: Mode Loop, `AudioSubType = Music`, any author, each result's creator and whether it's verified logged. Avoid in titles: vocals and lyrics, "remix", "cover", "theme", "OST", any show's or game's name. It must loop cleanly, 1.5 to 4 minutes.

| Track | What it should feel like | Keywords, wide |
|---|---|---|
| The base | night at a power plant in the void: calm, wide, electronic, a slow pulse, a little melancholy, stylish; under the hum, never busy | ambient electronic, chill synth, night, downtempo, atmospheric |
| Lantern Row | a festival street at dusk turning into a fight: driving and bright, its drums forward (taiko or electronic), a hook, never comic | festival drums, taiko, action electronic, upbeat battle, energetic |
| The Lamplighter | a keeper's duel: heavier, darker and faster, with a clear rise; reads as a boss in its first 4 seconds | boss battle, epic electronic, intense drums, dark action |

**Picking:**
- Five candidates a track, loudness-matched, on the board (`docs/research/sound.md`, "Picking by the director's ear"), heard in the game in a looping moment of its own place.
- A track is accepted only on the director's pick.
- The level is set by ear. The seed: the music about 10 dB under the lead's hits.
- Every id is checked from a live client after the publish.
- Each one is logged in `docs/asset-log.md` with its id and author.

**Never:** a jukebox, a radio or a paid track (the Terms' music-library line), or a track that sounds like a known score.

**Cost:** none. The library and the search are free.

## TR39. Jewels (Faber, after TR38)

Research's request, 2026-11-17, 11:57, item 7 of phase 3's order. The design: `docs/design.md`, "Regalia: gear". Jewels are 7 of a full build, and they carry the percent stats [D].

**Feel line:** a rare jewel drops from the keeper. The player sets it in their best item's one jewel socket, and their criticals hit harder from the next fight.

**The rules (research's, tier 2):**
- **A jewel** carries one percent stat: Critical Damage, Critical Immunity or Lifesteal. It has a **tier, 1 to 5 at launch** [D, 2026-11-17, 12:10], and its percent grows with it. Lifesteal stays under `Config.Stats.Lifesteal.Cap`, and Critical Damage has no ceiling [D, 2026-11-15].
- **One socket** on items of Rare and above [D]. In and out is free, and it moves across on equip (TR37).
- **Three of a kind make one higher:** three jewels of the same stat and tier combine into one of the next tier [D, 2026-11-17, 12:10], so a tier 5 is 81 tier 1s. It never fails, and tier 5 is the top at launch.
- **Sources:** elites, keepers and the Tower [the design's], never ordinary Shades, and **the Stone Condenser** [D, 2026-11-17, 12:10], its tier rising with its level (TR37). Chests holding higher tiers come in a later update [D]. Combat Power counts each by its weight times G at the block's level (`Config.Stats.Power.ByLevel`).
- **The server decides,** in one step, as for emblems.

**The seeds** (research's, 2026-11-17, 12:40: worked by hand, a model, not a measurement; the sim checks them before Faber reaches this):
- **The percent per tier,** twice the tier below. Three make one, so a combine trades stat in the bag for stat in a socket, and sockets are the limit: Critical Damage and Critical Immunity 1%, 2%, 4%, 8% and 16%; Lifesteal 0.2%, 0.4%, 0.8%, 1.6% and 3.2%. Both double a tier, under Lifesteal's 10% cap [sim check, 15:06: was 5% to 195%, at 2.5 a tier].
- **Drops,** all tier 1: an elite 0.05 jewels and a keeper 0.3, as an expected count; a Tower hard floor 0.05. The Condenser makes one jewel per 6 hours of work.
- **What it gives** (by hand, an active player at 1.5 hours a day): about 9 tier-1 jewels a day with the Condenser, so a tier 3 in every socket of a Rare-and-up set takes about two weeks, tier 4 about six, and tier 5 about four months: the long climb, with tiers above for the updates. **The Condenser's tiers** (research's seed): tier 1 from its level 1, tier 2 from level 11, tier 3 from level 21. Tiers 4 and 5 come only from combining at launch.

**The block contains:** `Rules.Jewels` with its cases; the rail's Jewels page, where its Soon stands today, reached from anywhere [D, 2026-11-17, 12:27], with the bag's Jewels tab; the item card's jewel socket (Rare and above); the socket and the combine as for emblems; the percent shown honestly on the stat sheet's sources (`docs/ui.md`, "Stats, shown honestly").

**Waits:** the jewel icons (Modulo): each type its own colour, the shape growing from tier 1 to tier 5 [D], so a jewel's tier reads at 64 px without its number. The shop.

**Checks:** as TR38's, plus a case that Lifesteal never passes its cap whatever is socketed.

**The sim check of TR37 to TR39's seeds** (research's, 2026-11-17, 15:06). A model, not a measurement. It uses `tools/balance/sim.py`: the elite's and the keeper's rates from section 11's laps, Credits from `earned()`, and Combat Power at the seeds' weights. The seeds above are amended where marked.
- **The drops hold.** One player at Lantern Row's cooldowns takes about 18 elites and 9 keepers an hour, and four players about 16 and 9. That gives 14 Low stones, 9 emblems and 3.6 jewels an hour. An active player's 13 emblems and 9 jewels a day stand as seeded.
- **Jewels, fixed:** the old Critical Damage row made one tier-5 jewel about 8% of a level-60 build's Combat Power. Every socket at tier 5 came to about 110%, against the 7% share jewels hold. Doubling a tier from 1%, Critical Damage and Critical Immunity match Lifesteal's row in Combat Power, tier for tier. Every socket at tier 4 is then about 4.5% of the build, and at tier 5 about 9%. The cost: tier 1 and 2 are a quiet step, so the feel line's harder criticals are felt from tier 3 up.
- **The move across, fixed:** a rank's Credits priced by the item's tier, with a free move, let a player rank level-1 items for 77,000 Credits a set and carry the ranks to level-60 items. At level-60 prices that's 1.7 million. With the difference charged, a set at rank 10 costs what its final items' tier says, about half of launch's Credits. That's near `forgeShareOfIncome` (0.45).
- **The Condenser, halved:** at the old rate and full power, an active player's Condenser gave about 70 stones a day against 21 from drops, so a set reached rank 10 in about 8 days. Halved, it's about 14 days, and the Condenser still gives over half.
- **Credits lead the stones:** by 10 hours of play, a set at rank 10 on the items worn then costs about 3 times the Credits earned so far. From about 30 hours, it costs less than what was earned. So the early ranks come one item at a time, the late ones whole. That's intended, and the move across keeps every early rank.
- **For Faber, at TR39:** jewels push Critical Damage past +100%, beyond Combat Power's last fit. Refit it then (`tools/balance/attributes.py`, report A8) once jewels are in the builds.

## TR42. The sound audition panel: the director picks by ear (Faber, first piece of the next session)

Research, 2026-11-17, 23:24, on the director's word: "ok let do 1" (`docs/decisions.md`), after AR39's stop. Nobody on the team can hear, so the team stops making and layering sounds. A cue is one finished sound from Roblox's library, played whole, and the director's ear chooses it. This panel is how that costs the director minutes.

- **Feel line:** the director plays a fight in the dev place, taps a candidate, and from that tap every hit of that kind plays it, in the fight, at the fight's level; one more tap keeps the one that's right.
- **The block contains,** for the three pilots (LightHit, HeavyHit, ShadeSwipe):
  - **The panel,** in Studio only: a tab for each cue, and under it "Old" (today's cue) and about ten candidates, each a row with its number, title, author and length.
    - A tap on a row plays it once and makes it that cue's live sound.
    - **Keep** marks it; more than one may be kept. **More** brings the next ten. **None** says the ten held nothing, and is recorded too.
  - **A candidate is a finished sound, whole:** no slice from inside it, no layer, and no pitch spread while it's auditioned.
    - **On the hit:** its start is trimmed, or its play is started ahead inside the engine's lookahead, so its top lands within 10 ms of contact. That head trim is the only cut.
    - **A recording that holds several events** plays its first event, whole.
  - **A fair listen:** every candidate of a cue plays at one loudness (the match), with the limiter taking 0 dB, so a louder one never wins. A preview with no fight goes through a hit's own path, since an emitter on the listener reads 8.5 dB down (AR39).
  - **Where candidates come from:** `Library.Search` over every author (the director, 2026-11-15), on research's words below, in the library's own order. If the library gives a community rating, the best rated come first. That's checked in 15 minutes and dropped if it isn't there.
  - **Left out before the director sees it,** by number and title only:
    - one that doesn't load;
    - one too long for its cue (LightHit over 0.7 s, HeavyHit over 1.5 s, ShadeSwipe over 1.0 s);
    - music or a voice;
    - a title that names another work.
  - **The picks are read out** by one debug command (cue, id, title, author, kept or none), for `Config.Cues` and `docs/asset-log.md`.
  - **The three cues' levels against each other** start at AR39's gate 4 and are tuned live.
- **Research's search words** (finished sounds, never a recording of an object: no glove, bag, clap or paper):
  - **LightHit:** "punch", "punch hit", "melee hit", "hit impact", "kick hit", "combat hit".
  - **HeavyHit:** "heavy punch", "heavy hit", "strong impact", "power hit", "smash impact", "slam".
  - **ShadeSwipe:** "sword swing", "slash", "swoosh", "claw swipe", "swing whoosh".
- **After the director's picks, in this piece's finish:** each kept sound becomes its cue through AR39's engine: whole, with a small pitch and volume spread, its id and author in the asset log, quick to swap.
- **It waits:** every other cue; counting the ranker against the picks (the director's word of 14:05: is their pick among our first three?); sibling takes for variation; the listen on a phone.
- **Cases:** the panel isn't built outside Studio; a candidate that fails to load is marked and skipped; changing the live sound never drops or doubles a voice; "Old" brings today's cue back exactly.
- **Cap:** the block in 2 hours (research's estimate, from the A/B switch's build of 2026-11-17). The director's part is about 10 to 15 minutes for the three.
- **What can't be known before the listen:** whether the library holds a good one for each cue. A cue whose candidates all get None goes back to the director with what was tried.

### The block, built (Faber, 2026-11-18, 21:51 to 22:12)

- **Where:** the finder `tools/studio/Audio/Audition.luau` (Edit: `Audition.Start()`, `Status()`, `Report()`, `Clear()`); the server half `Services/Core/AuditionService.luau`; the panel `Controllers/Core/AuditionController.luau`; the numbers `Config/Audition.luau`; the cases `SelfTestController/AuditionCases.luau`. Studio only, all of it.
- **The finder's run** (22:05): the library gives no rating, so its own order stands, the words taken in turn. 50 candidates a cue, of 270, 291 and 244 found. Left out, by reason (each by id and title in `Report()`):
  - LightHit 48: too long 41, a title naming another work 6, a gore word 1.
  - HeavyHit 47: too long 26, another work 16, gore 2, hidden by the filter 1, a voice 1, a top over -1 dBTP at the match 1.
  - ShadeSwipe 27: too long 21, another work 4, gore 1, hidden by the filter 1.
- **The match:** short-term loudness against today's LightHit (-42.5 LUFS), HeavyHit +4 dB, ShadeSwipe -4.5 dB (gate 4's middles; `Audition.Levels`, tuned live). The hottest top at the match: -8.4, -1.3 and -14.1 dBTP, under the -1 ceiling. A contact's head is cut so its top lands within 8 ms; a swipe keeps its rise and starts ahead (Lead "Peak").
- **Added in the block (tier 1):** "Others off" silences the fight's other cues, so a candidate is heard alone on its hit; on by default.
- **Found on the way:** an AudioPlayer's Volume stops at 10, not 3 (read back on a client). `CueMix` and AR39's sound case took 3; both are corrected. So AR39's matched A/B played an arrangement whose level passed 3 louder than `CueMix` measured it; that was the sound case's two failures this session (HeavyHit B1 and B3, ShadeSwipe C3).
- **Tests:** type check 0 new; logic offline 24,491/0; in a playtest at 60 fps, the audition cases 44/0 (the four above, the fair listen, and Others) and the sound cases 63/0. A tap, Keep, More and None by mouse, then the readout: `LightHit, 112758963155190, Hit⧸Punch in the air Sound, Raknium, kept` and `LightHit, page 2, none`. The panel made opaque after that run (a colour only) and captured from the player's view. The place is saved with the candidates (v857).
- **Open:** the director's listen; then the picks become cues, the asset log, and `Audition.Clear()` before a public build.

### Research's read of the second round (2026-11-19, 00:47 by the clock)

The director's "Done", then "we need more audition sfx for the skills of our current voidskin rooster + the m1 of ranged class like mage etc" (2026-11-19, 00:3x). Faber's tier 2 notice is accepted as built: the 63 keeps as cues, the nine pilots, the beat cues replacing the heavy wind-up, the levels as seeds tuned in the listen.
- **The pool, agreed with Faber's concern:** 32 different recordings in one pool make each punch a different sound, so no fighter has a voice. It's split by fighter, 4 to 6 keeps each, and the director's ear does the split: the next round adds a tab for each melee fighter's light hits, with that tab's candidates drawn from the 32 keeps, not the library. Faber's 0.5 h, in this round. Until then, the single pool stands.
- **Mage cues:** the words are Pip's fire, so the cue belongs to a Fire Mage. A later Mage of another element gets its own cue under the same rule.
- **Healer cues:** "laser shot" is off Lyric's look, since her speakers throw sound, not light. Use "sonic pulse" in its place. For HealerShot, HealerHit and HeldNote, a single tone or chime isn't music: the music filter drops only a recording with a tune.
- **The pilots' entry stays this one;** each kept sound joins its cue through the engine as before.

### The picks in the game, and the second round, built (Faber, 2026-11-19, to 01:31 by the clock)

- **The picks are the cues:** LightHit plays the director's 32 keeps, HeavyHit 22, ShadeSwipe 9, each whole, never the same take twice running; ids and authors in `docs/asset-log.md`. Those three tabs are Done and the finder skips them.
- **The second round, 12 tabs** (`Config/Audition.luau`): the nine pilots (Haymaker, Scarf Step, Lantern Burst, Ground Wire, Held Note, the Fire Mage's cast and hit, the Healer's cast and hit), and research's split, a tab for each melee fighter's light hits (Rook, Kirra, Watt), each drawn from the 32 keeps, not the library (`Keeps`). Until the director picks, each fighter plays the single pool (`Config.Cues.Own`).
- **The finder:** 50 candidates where the library has them; MageShot 8, HealerShot 20, MageHit 23 and HealerHit 25 after the filters. The tonal rule is in: a Healer's or Held Note's chime passes, a tune doesn't (`Tonal`). "laser shot" is "sonic pulse".
- **Fixed on the way:** the finder's answer passed a StringValue's 200,000 characters at the end of a 70-minute run and was lost. It's kept in parts now, and the panel gets only what it reads. It measures six finds at once, so the re-run took 9 minutes.
- **Fixed on the way:** the fight's own cues share their voices by take list and bus, so the three fighters' tabs don't triple the light hit's voices.
- **Tests:** type check 0 new; logic offline 26,574/0, the same in Studio, world report empty. The audition cases 89/0, and the sound cases on the beat cues 10/0, both in one playtest.
- **Open:** the director's listen, put off to tomorrow by the director ("i will do that sound audition tomorrow"); the panel and its candidates stay in the place. `Audition.Clear()` before a public build. Queued after it: the UI sounds' audition.

### The M1's sound per class, the panel's words (Sonus, 2026-11-24, 11:24 by the clock)

On the director's word of 2026-11-23: one basic attack's sound per class, shared by every Voidkin of the class (`docs/decisions.md`). At launch each class has one Voidkin, so the second round's tabs serve as the class's. Only the data moved (`Config/Audition.luau`):
- **Warrior** (`RookHit`, "Warrior's hits"): unchanged, the light hit's 32 keeps, since Rook's jab, hook and ram are fists.
- **Assassin** (`KirraHit`, "Assassin's cuts"): from the library now, not the punch keeps, since Kirra cuts with two blades. Words: "sword slash", "blade slash", "katana slash", "slash hit", "sword hit", "blade cut". 0.7 s at most, as every melee hit (0.6 failed the self-test on the place's old 0.66 s keep), its level a seed 1 dB under the light hit's.
- **Tank** (`WattHit`, "Tank's blows"): from the library, a weighted blow for Watt's shaft, butt and driven spear. Words: "heavy impact", "blunt impact", "heavy strike", "heavy melee hit", "impact thud", "body impact". 0.8 s at most, its level a seed 2 dB over the light hit's.
- **Mage** (`MageShot`, `MageHit`, "Mage cast" and "Mage hit"): the fire words are gone, since the word of 2026-11-23 replaced research's "a Mage of another element gets cues of its own". The element is left to the effect. Cast: "magic shot", "spell cast", "magic projectile", "energy blast", "spell shoot", "magic whoosh". Hit: "magic hit", "spell impact", "magic impact", "spell hit", "energy impact", "magic burst".
- **Healer** (`HealerShot`, `HealerHit`): unchanged.
- **The director, 2026-11-24:** "the sound effect really need to be simple but pleasant", "not to many sfx like one m1 sfx per type of class nor weapon", "very very appealing like anime vanguard type". So each class picks one sound, and every tab above but the Warrior's keeps puts an anime game's crisp hit first ("anime slash", "anime heavy hit", "anime magic hit" and so on), a real recording after.
- **The signatures, "One each"** (the director through research, 2026-11-24): one finished sound each, anime words first in Haymaker's, Scarf Step's, Lantern Burst's, Ground Wire's and Held Note's tabs.
- **For Faber's review:** the data only. At the merge, the cue names could become the class's own (`AssassinHit` and so on, and `Config.Cues.Own` by class) so a second Voidkin of a class reaches the same cue. That's code, and your call.

### The shortlists, in the place (Sonus, 2026-11-25, 23:17 to 23:32 by the clock)

- **The finder's run:** the eleven tabs in 7 minutes at 20 kept a tab (`Config.Audition.Keep`, was 50). Then three tabs again on new words: the casts may run 0.8 s (at 0.6 the Mage's kept 4 of 275); the Healer's hit drops the Mage's words; Scarf Step drops "anime dash slash" and "anime quick slash", which found UI sounds.
- **Cut by title to five to eight a tab**, out: a sound from another work or Roblox game, or a ripped game file (Street Fighter III, Smash Bros, Sparking Zero, JoJo, Wuthering Waves, Undertale Yellow, Dead by Daylight, Mega Man, Gundam, HOURS, Forsaken, `snd_` and `SE_BTL_` names); a gun, a metal clunk or a splash; music and voices; a title that says nothing ("asd", "Untitled"), where a claim is likeliest. ProSoundEffects' and APM's licensed sounds kept where they fit.
- **Shortlisted:** Assassin 8, Tank 7, Mage cast 6, Mage hit 5, Healer hit 4, Haymaker 6, Scarf Step 5, Lantern Burst 8, Ground Wire 8, Held Note 5, and the Healer's cast 6 (2026-11-26, 00:30 to 00:37). The Warrior keeps the light hit's 32.
- **The Healer's cast, in four runs:** music, guns and a jet's radar beeps on the first two words. Then sparkles and chimes, which kept 5 of 257 at 0.8 s, the rest ringing on. "Short sparkle" and "short chime" found car chimes, a train whistle and menu clicks. So its Max is 1.2 s on the sparkle words (13 kept): a sparkle rings far under its top, and the combo's shots overlap at 0.25 s anyway. Cut: two railway station jingles, a spring tune, a sound named for another work's character, four titles that say nothing.
- **Where:** `ServerStorage.NL_Audition.Candidates` holds the cut lists, and `Untrimmed` the finder's whole answer. Faber saved them in version 1283 (2026-11-26, 00:29); the Healer's cast came after, so Faber's next save keeps it. **Loaded, heard, picked:** no. The listen is a Play in my next turn, when the director wants it.

### The picks, unheard (Sonus, 2026-11-26, 20:48 to 20:52 by the clock)

- **The director, 20:48:** "i wont listen js add everything when i acc play the game i will says if it good or not". Then **yes** to the restatement: Sonus picks one sound a tab, unheard, for TR42's 11, TR64's 10 and TR57's plate; Faber installs them; the director judges each in play, and a miss takes the next on its tab. For these 22 cues it replaces the word of 2026-11-17 that the director's ear picks on the panel (`docs/decisions.md`, research records it).
- **Picked by** title, author, length and loudness, never by ear. A licensed ProSoundEffects or Roblox sound wherever its title fits (5 and 1). Never a sound another cue plays: Kirra's first choice, "hit_slash_m", is a Shade swipe keep, so "Katana Slash Wind 3". The Tank's blows is one of the director's light-hit keeps.
- **The 11:** Assassin's cuts "Katana Slash Wind 3" (GleonoffG); Tank's blows "Hit - Impact - Punch - Blunt" (lorenzosaudiostash); Mage cast "Magic Zoom Up Sharp Tubular Whoosh Fast Hiss" (ProSoundEffects); Mage hit "Magic Hit SFX" (Remy1DB); Healer cast "FIXED sparkle magic sound" (Hibuki_DSP); Healer hit "sparkling_attack_hit" (BrawI031); Haymaker "Power Punch" (hung902); Scarf Step "zip flash quick dash sfx" (Axellatic); Lantern Burst "Pyro Fire Ball Burst 9" (ProSoundEffects); Ground Wire "Lightning Flashes Quick Electrical Bursts 21" (ProSoundEffects); Held Note "VC spin chime 4" (Vanta Systems). The Warrior keeps the light hit's 32. Ids and cuts: `docs/asset-log.md`, "Sonus's 22 picks".
- **For Faber's install:** `build/scratch/Sonus/picks-2026-11-26.luau`, each take as the panel's `cueOf` plays it (the finder's cut, Gain at the panel's matched level, Lead "Peak" on a beat tab), into `Config.Cues`. **Shortlisted, picked (by Sonus):** yes. **Loaded:** in the game, Faber's b75b6978 (Sound 119 of 119): Ground Wire's and the Mage cast's starts trimmed so each top sits on its beat, the tonal tabs at pitch 1, the rest 0.97 to 1.03. **Heard:** no, the director in play.

## TR43. Lantern Row's stages on Normal and Hard, in grey (Faber, the follow-up's item 2)

Research, 2026-11-18, 22:44, on D2 and D7 (`docs/decisions.md`; `docs/design.md`, "The Festival of Battles"). Answers Faber's four questions of this evening.
- **Feel line:** a new player walks through the Festival Door and is fighting Stage 1 within seconds, with no screen first; each stage ends on a short results card that names the next; when the Lamplighter falls, the card says Hard is open, and Hard's first Shade hits like a wall.
- **The shape (Faber's (a), taken):** Lantern Row's street in four stages. Stages 1 to 3 are its stretches in order: a quota of Shades (seed 10), then the stretch's elite, and the gate to the next stretch opens for that player. Stage 4 is the Lamplighter. A stage is replayable and ends in its results. Seeds for a 10 to 15 minute Normal clear: about 3 minutes a stage; every number in Config, tuned in play.
- **The stage's foes:** Normal keeps today's shared street (packs and elites anyone near may join). Progress is the player's own: their kills count for their quota, and the elite counts for everyone who hit it.
- **Hard (b): a level offset, +10,** so Lantern Row on Hard sits at Drum Court's band (10 to 19) until Drum Court opens: the recommended levels then read as one ladder. Hard's foes belong to the player, as a Tower foe does (`f.For`); how others see them is Faber's call, the cheapest that doesn't confuse (faded and untargetable is fine for the block). A Hard stage needs the Hard stage before it.
- **The picker (c):** at the Festival Door, a screen with four tiles and a Normal/Hard switch; each tile shows its recommended Combat Power, its best clear and, if locked, its condition ("Clear Stage 2 first", "Beat the Lamplighter on Normal"). **The first time, there's no picker:** the Door sends a player with no clear straight into Stage 1 on Normal. The picker shows from the first clear on.
- **The results (d):** what the stage gave, Retry, Next and Home, and what just opened. Dailies aren't named until they're designed. The Lamplighter's Normal win says "Hard is open", in place of "Drum Court opened" at launch (the follow-up's 4.9).
- **Waits:** gear budgets by stage (item 4, after research's loot refit), the party's anything, art on the tiles, the dock's shortcut to the picker.
- **Research reads it:** in motion, from a phone's camera: the first 90 seconds of a fresh account, one stage's results, and one Hard stage's first fight.

### The block, built (Faber, 2026-11-19, to 01:31 by the clock)

- **Where:** the rules `Rules/Stages.luau` and their numbers `Config/Stages.luau` (the quotas, Hard's +10, the card's delay, the gate); the server `StageService` (the run, the gates, the Door, the keeper's stage, the save's one transaction); the client `StageController` (the stage's line at the top, the gates) and `UI/StageScreen` (the picker's four tiles with the Normal/Hard switch, and the results card with Retry, Next and Home). The save and its contract: `docs/engineering-plan.md`, "A ground's stages".
- **The street:** each stop of Lantern Row's street carries its Stage (`Config.World.Row.Stops`), with its own elite on stages 1 to 3, and a `StageGate` and a `StageStart` for each. On Hard, the stage's foes belong to the player and stand again after their last falls. The lead fights only them while the run lasts, and the street's Shades leave it alone.
- **Tests:** logic offline 26,574/0 (the Stages cases among them); the self-test's TR43 case 78/0. It covers the gates, a Normal run to its card, Next, leaving, Hard's own foes, the keeper lifted, the picker's locks, and a lost run. Its first run failed three checks, all in the case itself: it read the stage's line a frame early, and it counted a fallen foe still fading as standing. Not run: the fresh account's case, which wipes the save.
- **Open:** research's read from a phone's camera.

## TR44. The Lamplighter's slam in its fight, and two ways to move the lead out of it (Faber, the follow-up's item 3)

Research, 2026-11-19, 00:47 by the clock, from the brief of 2026-11-18, 3.3: two blocks on the same fight, each inside the 90-minute cap, and the director picks one. The pack that proposed the slam's place, its footprint and its recovery isn't in the repo, so the numbers below are research's seeds, tuned live. A blockout is tier 1. The pick is the director's.
- **Feel line:** the Lamplighter leans its lantern out over your fighter, and a ring opens on the street where it will land. You move your fighter out of the ring in time, and the slam hits empty stone. If you didn't, you know why it hit.
- **The slam in the rotation:**
  - `KeeperSignature` joins the Lamplighter's row beside `KeeperSwing`. It's the first slam 8 s after the Challenge ends, then each time its cooldown of 12 s is up and its target is within its Range (7.5); otherwise the keeper swings. A 90-second fight holds about 6 slams.
  - The keeper turns to its target until Plant (0.4). From Plant the aim is fixed.
  - **The tell is 1.57 s,** from Plant to Slam (1.9667): the clip's own lean and gathering light, and the footprint.
  - **The recovery is the clip's tail, 1.07 s** (Slam to 3.0333). The keeper doesn't act in it, and the lead's hits land as normal. A bonus in that window waits.
- **The marked footprint:** a flat ring on the ground at the lantern's landing point (6.33 studs ahead of the keeper, 1.92 to its left), radius 5 (seed). Inside it, a disc grows from the centre and meets the ring on the Slam frame, so the fill tells the time. In grey: a white ring and a translucent fill that read on the street by day and at dusk. It's gone on the Slam, and the column takes over. Nothing else is marked: no screen text and no icon.
- **The hit resolves on the footprint:** the Slam's hit takes every lead whose centre is within the radius at the Slam's beat, at its real position. That replaces Reach 10 and the 70° arc for this hit alone.
- **A, the pack's rule: follow during a marked strike.**
  - While a footprint is down, if the avatar moves 2 studs or more from where it stood at Plant and ends outside the ring, the lead breaks off its combo at once and walks to its place beside the avatar (`Lead.Frame`), at its catch-up speed.
  - It holds there until the Slam, then fights again.
  - If the avatar stands still, or stands inside the ring, nothing changes. Standing still is the old rule, so the lead fights on and is hit.
- **B, a Recall button.**
  - One press: touch (a round button by the right thumb, 44 pt or more, shown only in the keeper's fight in this block), the R key, and the gamepad's ButtonY.
  - The lead breaks off its combo and dashes to its place beside the avatar at 40 studs a second (seed), then holds 1 s and fights again.
  - The cooldown is 4 s, shown on the button. It isn't untouchable: if the dash ends inside the ring, the slam hits.
  - In B, walking away does nothing new during a mark, so the two rules are tested apart.
- **Both:** the breaking off costs the combo, which is the price. A runtime switch picks Off, A or B (`Config`, read live), so the director plays all three in one session without a restart.
- **What the block counts:** per slam, on the server, write hit or missed. For a missed slam, also write on purpose (the player moved 2 studs, or pressed Recall, in the tell) or by accident (no input in the tell). One debug command reads out the counts per mode.
- **Waits:** the footprint's look in the game's art (Modulo, at the shared finish); the slam's sound (no sound work outside TR42's panel); a bonus in the recovery; poise and stagger; Hard's numbers; parties' several leads; Recall outside the keeper's fight; any other keeper.
- **Cases:** the slam's aim is fixed from Plant; a lead on the ring's edge at the Slam is hit only when its centre is inside; A fires only on a 2-stud move that ends outside; B's cooldown holds through a repeat press; a Recall during the lead's own signature breaks it with no double hit; Off plays as today's rule.
- **Research reads it:** in motion, from a phone's camera, one fight in each mode, with the counts. The question for each is the pack's own: can the player explain why the slam hit their lead? A mode in which most misses are accidents fails that question. Research sends the director the two takes and the counts, and the director picks.

### The block, built (Faber, 2026-11-19, 01:57 by the clock)

- **Implemented:**
  - **The slam in the fight:** `KeeperSignature` is the Lamplighter's `Signature` (`Definitions.Enemies`), tried before `KeeperSwing` whenever it's ready. Its first is `Config.Combat.Keeper.First` (8 s) after the Challenge ends, then its cooldown of 12 s. Its `Aim` is Plant: the keeper turns to its target until then, and from Plant its Align holds the facing it had.
  - **The footprint:** put down on Plant, centred where `Rules.Mark.Centre` puts it (6.33 ahead, 1.92 left, `Config.Combat.Keeper.Mark`). The Slam's hit (`Mark = true`) takes every lead whose root's flat centre is within the radius at the Slam, in place of Reach and the arc; Reach 10 stays for the replay. It's taken up on its hit, or when the action ends first (a fall), and then it counts nothing.
  - **What clients read:** the keeper's attributes MarkAt, MarkRadius, MarkDown and MarkSlam.
  - **The grey look** (`SlamController`): a flat white ring 0.35 wide on the ground under the centre, and a disc at 0.6 transparency growing to meet it on the Slam. Both go on the Slam.
  - **A** (`SlamService`): while a footprint is down, an avatar 2 studs or more from where it stood at Plant, standing outside the ring, takes its lead with it (`FightService.Away`). The lead drops its action, walks at `Combat.Lead.CatchUpSpeed` to its place by the avatar and holds there until the Slam. Walking does nothing in B.
  - **B:** Net `Recall`, a round button 84 authored by the right thumb, above the dock, with R and ButtonY bound while it shows. It shows only in mode B and in a keeper's try. A press dashes the lead to its place at 40 studs a second (at most 1.2 s on the way), holds it 1 s, and sets the cooldown of 4 s on the player's `RecallReady`. The button counts the seconds down.
  - **The switch:** `Config.Combat.Keeper.Out.Mode`, read live, starts at "A".
- **To play it** (Studio):
  - `NL_Debug:Invoke("Slam", nil, "Off" | "A" | "B")` switches the mode for every side, mid-fight.
  - `("Slam")` reads the mode and the counts per mode: slams, hit, missed, on purpose, by accident. `("Slam", nil, "Reset")` clears them.
  - `("Slam", nil, "Now")` makes your keeper's slam ready at once.
  - Each slam is also logged in the output.
- **Tested:**
  - **The logic cases** (`LogicTestService/Cases/Mark.luau`, 6 cases): where the footprint lands for any facing; a centre on its edge is taken and one 0.01 past it isn't; the fill; A's rule; on purpose against by accident; each mode counted apart; the Recall's cooldown; the switch read safely; the keeper's rows. 26,618 passed and 0 failed, both offline and in Studio. The world report is empty.
  - **The self-test** (`SlamCases`, 34 checks) passed in 17.6 s at 57 fps. It plays a keeper's try through the server's own paths:
    - Off's tell is 1.57 s. The footprint lies its 6.6 studs out. The ring's radius and edge, the disc half the ring at mid-tell, both gone with the Slam, counted under Off. A lead left standing still was hit.
    - In A, the avatar walks out and its lead follows. The keeper's aim held within 2° from Plant to Slam. The slam is counted missed, on purpose, and the lead is back to its fight after it.
    - In B, the button is 44 or more by the right thumb. A press in the tell is taken, a second at once is refused on its cooldown, the lead strikes nothing on its way, and the miss is counted on purpose. The button counts down, and its own press asks the server.
    - There's no Recall in A or outside a try, and the server refuses one there. The switch is put back after.
  - **Rerun on the new fight:** the keeper-try and TR43-stage cases. Their result is in this piece's commit message.
  - **Not covered as written:** "a Recall during the lead's own signature" isn't forced in a case. What's checked is that a Recall ends whatever action the lead is in, and that the lead starts none while it's away. So no hit of its own can land twice.
- **The phone take, part done:**
  - Off was recorded at the iPhone 16 Pro simulator (750 by 401): `build/scratch/faber/tr44/take_off.mp4`, with a strip of it at 2 frames a second, `off_crop.png`. The ring reads on the street around the lead, and the column covers the frame on the Slam. But Studio's lead was then level 17 and killed the keeper in about 15 s.
  - The take of all three modes, at a level-3 lead, was stopped by the low-memory reaper at 01:54. It waits for the director's go to record again.
  - That try still played to its end in Studio:
    - Off: hit.
    - A: missed on purpose, the avatar walking 0.4 s after the footprint went down.
    - B: missed on purpose, the Recall pressed 0.57 s after.
  - These are scripted moves, so the on-purpose share says nothing about players. The counts that answer the pack's question come from the director's own play.
- **For research, measured on Studio's account, gear included:**
  - The level-9 Lamplighter has 19,525 health. Rook at level 17 took it down in about 15 s. Rook set to level 9, the keeper's own, took 3,300 in about 3 s, so the fight lasts about 20 s.
  - At those fights the keeper slams once, maybe twice, not the 6 that a 90-second fight would hold.
  - The rotation's seeds assume the longer fight. Its length is the stage's balance, not this block's, so it's flagged here, not changed.
- **Visually reviewed:** not yet: research's read waits on the take. **Director-accepted:** no; the director picks Off, A or B by playing.

## TR45. The Festival of Battles in its own place, its menu, and the trip there and back (Faber)

The director, 2026-11-19, 02:05 to 02:07 by the clock, then yes to the restatement: "festival of battle is a game mode it need a new places not the main experience", "u can make a new place inside this experience (game)", "the teleport point of the base will simply open the menu ui of the game mode (the player can also just open the map button that should be renamed to play or something else and open FOB)", "and yes, do research on how pro dev make new places for game mode etc take note if there is geniune tips then go ahead". The tips: `docs/research/game-mode-places.md`. The contracts: `docs/engineering-plan.md`, "Places".

**The feel line:** from the base, the player walks into their door or taps Play, the Festival's menu opens over the yard; they tap Stage 2 on Normal, a short card holds while the trip loads, and they stand at Stage 2's start on Lantern Row with their lead beside them. Home takes them back to their base the same way. A hard technical problem (two places, the save between them), named here, so it takes the time it needs.

**The block contains:**
- The place: 110443456684004, a copy of the main place added to the experience at 02:25 (Studio's Save to Roblox As), its role "Festival" by the workspace attribute.
- Each place lays only its own world: the main place the base, the Strip, the Shop and the Towers; the Festival place Lantern Row with its gate, its stages, its square and the keeper's ring. Services that belong to one place stand idle in the other.
- The base's door and the dock's Map tile, renamed Play, open the stages' menu (TR43's grey picker); a pick is checked against the save and becomes the trip.
- The trip: one server call with Roblox's own retries, a capped count, a watchdog that hands the screen back, and the ticket read on arrival with `GetJoinData`, checked again against the save. Home, the dock's Base tile and the fallen card's way home go back to the base the player left, or any base.
- An arrival card held from ReplicatedFirst until the Festival's server says the stage is ready, grey.
- Pure rules for the ticket, the retries and the arrival, with logic cases; the self-test's cases tagged by the place they need.

**What waits:** the card's look and the menu's art (AR42, Modulo's); the server size and the plot while its owner is away (research's, tier 2); parties in reserved servers (D1, after everything else); the early release of the save, chosen after the trip is measured; the place's display name and its access setting on the dashboard (the director's).

**The block, built** (Faber, 2026-11-19, by 03:31). The contracts are in `docs/engineering-plan.md`, "Places".
- **Two places, one code.** The workspace attribute `PlaceRole` splits them (`Util.PlaceRole`; none means Main). The tags are split by place (`World.Tags`, `Place`). `WorldService` lays the base's half in the main place and `layStreet` the Festival's: the forecourt, Lantern Row and the place's spawn at the landing. Each place's world report wants none of the other's markers. In the Festival a player gets a slot in place of a plot (`WorldService.SlotOf`), so the keeper's ring and the stages work without a base. Lighting and music read the whole Festival place as the Row. The Down's marker scan slows to once every few seconds in the base, which has none of those markers.
- **The trip** (`TravelService`): `TeleportAsync` and `TeleportOptions`. Each trip is tried up to five times. A failure is retried by kind (`Rules.Travel.Next`). A watchdog gives up after 40 s. The way home asks for the base server the player came from, else any. The ticket is read with `Rules.Travel.Read`, trusted only from our own places, and checked against the save (`Rules.Travel.Arrival`): a shut stage opens the menu instead.
- **Every way in opens the menu:** the plot's door and the dock's tile, its word now Play. A pick in the base is the trip (`StageService.Travel`). The way home is the ground's door, the keeper's shortcut, the Base tile after its charge, and the results' Home.
- **The trip's card,** grey: the destination's name on the backing, sent as the teleport's own screen and held on the far side from `ReplicatedFirst` until the stage stands.
- **What changed from TR43:** a fresh player's walk through the door opens the menu, as every player's does (the director's words). It no longer goes straight into Stage 1; the Festival still starts a fresh player who arrives with no ticket at Normal Stage 1. The base's side street is gone, so the base's place has no Lantern Row.
- **Tests:** the logic cases for the ticket, the retries, the arrival and the trip's length. In the self-test, a case tagged `Place` runs only in its place's playtest (the report counts the skipped ones), and the run turns the trip's stub on, so nothing leaves Studio. The new cases are "Places (TR45)" for the base and for the Festival. The old door case is split between them. The Base tile's case stays in the base, and its keeper step moved to the Festival's case. Fix 10 checks each place's own sign. The keeper's shortcut checks that the trip home is asked for.
- **Content check:** PASS on "Play", "Home", "Festival of Battles" and "The trip didn't go through. Try again." (02:59).
- **Tested, 2026-11-19:** offline logic 26,659/0, Studio's the same; the type check 0 new; the world report clean as Main and as the Festival. The base's full suite: 2,843 passed, 15 failed. 3 were the Map tile's old refused look, taught since, with the hover word's own bug fixed (the dock 38/0, TR20 36/0 after). 11 pass alone: TR20's breath, the Items page, Ground Wire and the galaxy's mist, order-dependent. 1 was the stat sheet's case, never taught item 8's "every 8 s" under HP Regen (e739d53): taught, 21/0. The Festival role's suite ran in the main Studio with its role attribute set for that playtest, its world whole and the player at the landing, but the place closed under it before its report was read: NOT VERIFIED. The Festival's own place waits on its Rojo connection (the board, item 9).
- **Not yet:** a real trip, from the published places (Studio can't teleport); the trip's time measured, for the save's early release.

**Faber's cloud session (2026-11-20, offline, no Studio; 939e049).**
- **Made pure:** `Rules.Travel.Joined` (a joining player's ticket is read only when they came from one of this universe's places; TravelService's inline check), and `Rules.Stages.Way` (the base's pick: its checkpoint, or the refusal with what it waits for; StageService.Travel's).
- **Case:** "Travel (TR45): the base's pick carries the save's checkpoint…" walks the round trip. It covers Way, Joined from the base and the Festival against a foreign, missing or text place id, and the arrival beginning the run where the base sent it. Mutation-checked on Joined's place check.
- **Tested:** offline 28,938/0 at that commit; the type check 0 new, 11 known.
- **NOT VERIFIED:** a real trip between the published places, and the Festival place's self-test.

## TR46. The Tower's follow-up: Retry and Home, the heal cap told once, the week's board, the week's foes (Faber, the follow-up's item 7)

Faber, 2026-11-19, 03:43 by the clock: the follow-up's item 7 (`docs/production-plan.md`, "The design review's follow-up"; the seed research's tier 2, taken). Research's answers to Faber's four questions came at 03:43 and are recorded below as research gave them.

**The feel line:** after a fall the player reads how high they climbed and where that stands this week, and with one tap climbs again or goes home. Past floor 5 everyone meets the same foes all week, so the board is one race.

**The block contains** (in grey):
- **The week's foes.** From floor 6 on, the foes are drawn from the week, which runs from Monday 00:00 UTC. A run keeps the week it started in. Its chests stay on its own seed. No salt, since a foe is harmless to predict (research: yes).
- **Retry and Home on the results.** Retry sets the avatar at its ring and starts a new run once the 4 s rest is up. Home sets it down at its plot's spawn, free. The words are "Retry" and "Home" (research: yes).
- **The week's board, on the card only, with no board in the world** (research: the Tower's lot stays "bare but for a ring", `docs/design.md`, "The Tower").
  - The card's line is "This week: #12 · floor 23"; tapping it opens the top 10 plus your own row, on the card.
  - Its title is "This Week's Climb".
  - With no ranked climb: "This week: no climb yet".
  - It's kept per week in an OrderedDataStore, which is free with DataStoreService. Research adds the board to `docs/design.md` as a tier 1 line at this piece's finish.
- **The heal cap told once.** The first time the cap binds, once per account, a toast near the lead's health bar in the quiet style (`docs/ui.md`, rule 2): "Healing capped for this floor: 15% of your lead's health". The share is read from Config and never written into the text. Reduced Motion gives a fade-in.

**What waits:** the card's art and the board's look (the shared finish); parties' boards (after everything else).

**Where it stands** (Faber, 2026-11-19, 11:25): built and tested in Studio; the visual review is Faber's own captures; research's pass and the director's acceptance are open.
- **The week's foes, Retry and Home** (444bfa2): as before.
- **The heal cap told once:** tested in Studio. The Tower case runs the full path: the cap binds, research's line shows under the lead's corner, the save keeps it as told, the note fades on its own, and a second bind says nothing. Captured in play: "Healing capped for this floor: 15% of your lead's health."
- **The week's board:**
  - **The rules:** pure Luau in `Rules.Tower`: `Score`, `Climb`, `Board` and `WeekLine`; `End` raises the save's `Progress.Tower.Week`.
  - **The store:** `TowerBoardService` posts the climb to the week's OrderedDataStore (raise-only `UpdateAsync`, by UserId) and reads one shared page per server at most every 60 s (`Config.Tower.Board`).
  - **The client:** Net "TowerBoard", the card's line, and the board on the card.
  - **In Studio:** the read works on the Test store.
- **Tests:**
  - **Logic:** a new case, "Tower: the week's board (TR46)". It covers the score's order and clamps, the climb's updates across weeks, and the board's merge, ranks and lines. All logic cases pass: 26,703 offline, 26,703, 0 failed in Studio.
  - **Self-test, the Tower case:** it covers the week's line and its floor, the tap to the board, the title, your own row in the record's colour, the results stepping aside, the tap back, and the race below. Its count varies by 4 with how many floors are caught in their fight.
  - **Self-test, the new card case:** "Tower card (TR46)". It opens the card with 1 chest and with 3, plus the fullest board, in the window and on the smallest phone, and holds everything inside the card's body. It passed 27 of 27 in the window and 28 of 28 on the device simulator.
  - **The whole self-test:** 2,874 passed and 15 failed in one 469 s run. Every failure was a timing or motion case, and all 12 failed cases passed on a rerun at 55 to 60 fps, so it was a busy stretch, not a regression. The last session's whole run also had 15 failures, a different set.
  - The type check is 0 new.
- **A fix the phone found** (Faber's own review on the device simulator, iPhone 16 Pro): the week's line made the card taller than a phone's room, and Retry and Home fell off its foot.
  - The card now lays out from the room the panel was fitted to.
  - Its rows close up to 20 px authored at least. Past that, the lines scroll above the buttons, as the bag card's lines do.
  - The board's rows close up to 16.
  - Captured after the fix: the card and the board, whole on the phone.
- **A fix the Tower case found:** a Home tapped on the card in the fall's fade came undone.
  - The cause: the run's end asks for a set-down beside the ring, landing 0.35 s later (`KeeperService.SetDown`). A quick Home landed first, and the set-down then moved the avatar back, 147 studs from the spawn. Retry had the same race.
  - The fix: `KeeperService` counts each player's moves, and a faded move still waiting gives way to any move made after it was asked.
  - The check: `MoveRace` on the debug bridge, in the Tower case. The Home check now also waits up to 2 s for the move to reach the client.
- **Tier 1 calls, Faber's own:**
  - A tie on the board goes to the earlier climb: the score's low digits count down through the week.
  - The page holds 100 climbs; under it, your rank reads "#100+".
  - "Back" sits at the left of the board's title row, and a tap anywhere on the board goes back.
  - The line stays dim until the server answers, and is hidden when the board can't be read.
  - A run over the week's end counts in the week it started.
  - Names are looked up when the board is shown (the store holds UserIds only), so a renamed player shows their new name.
- **CR** (the director's word at 10:36): every word players see for Combat Power reads "CR", from `Sheet.Said.Power`.
  - Tested: the Voidkin and bag self-tests.
  - NOT VERIFIED in Studio: the stage tile's "Recommended … CR". Its case runs in the Festival place only.
- **Open:** research's artistic pass on the card and the board, in grey. Research also adds the board's tier 1 line to `docs/design.md`. No capture yet at 1366×768: the card case holds the layout down to the smallest phone.

## TR47. The gear systems: Reinforce, War Emblems, the level gap; Jewels with the five attributes (Faber, after AR38)

- **Feel line:** the player opens Equipment from Home, picks a sword and presses Reinforce. The stones arc into the ring, the +6 lands or cracks with its odds read just before, and CR ticks up. They drop an emblem into the sword's socket and watch CR move. A lead four levels under an elite feels its hits come up short.
- **The director's words:** `docs/decisions.md`:
  - 03:10 (the level gap, five attributes and jewels, Reinforce) and 03:13 (War Emblems);
  - 02:40 of 2026-11-17 (they belong to the item, with the transfer prompt);
  - 13:53 of today (all five on every sheet).
  - Design: `docs/design.md`, "Upgrading gear needs no walk", "Reinforce", "War Emblems", "Jewels", and "Reinforce levels, emblems and jewels belong to the item". The rule: `docs/balance.md`, "One hit", item 8.
- **In two parts.** Part A is free to build now. Part B, the jewels and the five attributes, waits on the director's answer to the combat review (the Now board, item 10). Its decisions 5 and 6 change the attribute rows, and a jewel is points of an attribute.

**Part A, now:**

1. **Data first** (`docs/engineering-plan.md`, "Data", Faber's contract to write).
   - An owned item gains `Reinforce`, from 0 to the cap, and `Jewels`, colour to level with 0 for empty, five colours, which stays empty until part B. `Jewel` (one id) goes. `Sockets` holds emblem keys.
   - The profile's `SlotRanks` goes, since the level is the item's. Nothing ever wrote it, so it migrates as empty.
   - The bag gains `Stones` (a count by grade), `Emblems` (a count by key) and `Jewels` (a count by `"Green:3"`, empty until part B).
   - An emblem is a key (rarity, set, stat), not an owned row. Its value is fixed by rarity and stat, with no roll, so identical emblems stack.
2. **Content.** `Definitions.Emblems`: the twelve sets with their names, rarities and image keys (AR43):
   - Uncommon: Talon, Spearhead, Palisade.
   - Rare: Tidebreak, Warhorn, Compass.
   - Epic: Serpent Coil, Sworn Rings, Moonward.
   - Legendary: Zenith, Highcrown, Radiance.
3. **Rules,** in pure Luau with cases.
   - `Rules.Reinforce`: `Chance(level)`, `Cost(item, level)` in stones and Credits, `Gain(item, level)`, and `Try(profile, itemId, roll, op)`.
     - Try is one step: it spends, then rolls on the server's Random.
     - A failure spends and keeps the level, with no pity.
     - The shown chance is the rule's own number, success and failure adding to 100% (`docs/roblox-rules.md`, "What we do", point 2).
   - `Rules.Emblems`: Socket and Unsocket, both free, with sockets by the item's rarity (`Config.Chests.Sockets`).
   - `Stats.Resolve` adds the Reinforce gain on the item's main line and the emblems as flat stat points.
   - `Hit.Resolve` takes the level gap: a lower attacker's damage × max(0.05, 0.85^(gap − 2)) from 3 levels below, and a higher one gets nothing.
   - **The equip transfer** moves Reinforce, jewels and emblems to the new item on Yes. Emblems the new item has no socket for stay on the old one.
4. **Server.** Each operation goes through OpLedger, so a retry never spends twice.
5. **Sources,** as seeds in `Config.Drops`:
   - stones from Shades by ground, keepers and the Tower;
   - emblems from elites and keepers, the rarity by the chest ladder's row.
   - The loot refit (research's, next) sets their rates.
6. **Screens.** Equipment's Reinforce and War Emblems pages on Modulo's cut in B (`build/handoff/UI/seam/`). The Jewels page shows its five empty slots, marked as coming.

**The numbers (research's seeds, from `docs/balance.md`'s shares, to be tuned by play and by the loot refit):**

- **Reinforce:**
  - **Cap:** +30, about five levels a ground (seeds "forge").
  - **Chance:**
    - 100% to +5;
    - +6 80%, +7 70%, +8 60%, +9 50%;
    - +10 45%, +11 40%, +12 35%, +13 30%, +14 25%;
    - +15 to +30 20%.
  - **Gain:** +L adds L/30 of the main line's own value, so +30 doubles it. Since the main line is half an item's worth (`Chests.MainShare`), a full Reinforce is half the gear's worth: the balance share, 13.5 against 27.
  - **Credits a try:** round(30 × G(the item's ground's last level) × (1 + L/15)), where L is the level tried for. Fitted to the forge's 45% of income at the grounds' pace.
  - **Stones a try:** Low for +1 to +10, Mid for +11 to +20, High for +21 to +30. The count is 1, 1, 1, 2, 2, 2, 3, 3, 3, 4 across each ten.
- **War Emblems:**
  - **Worth by rarity:** Uncommon 0.25, Rare 0.45, Epic 0.7, Legendary 1.0 of 142 CR-weight units. That's the emblem share (11 of 27 against gear) over 56 sockets at a full launch build, priced by `Config.Stats.Weights`.
  - **Points at Legendary:**

    | Stat | Points |
    |---|---|
    | Attack | 32 |
    | Health | 149 |
    | Defence | 73 |
    | Critical | 814 |
    | Hit | 530 |
    | Dodge | 294 |

  - **Points at the lower rarities:** the same rows times their worth, rounded.
  - **Epic and Legendary only:**

    | Stat | Epic | Legendary |
    |---|---|---|
    | Critical Damage | +0.04 | +0.06 |
    | Critical Immunity | +0.04 | +0.06 |
    | Lifesteal | +1.0% | +1.5% |

    These are set by their caps rather than by price, because a price measured at small values doesn't hold for capped stats.
  - **When the combat review is accepted,** the emblem points are re-priced with its weights, and only the numbers change.

**Part B, on the director's yes to the combat review:**
- The five attributes on every sheet, with the rows of the accepted review: `build/scratch/quaestor/integrate/out/` holds the patch for every combat decision, ready to diff.
- `Rules.Jewels`: Set and Unset, both free, one slot a colour; Merge, where three of a level make one of the next, in one step.
- **Jewel points:** levels 1 to 5 give 1, 2, 4, 8 and 16 points of the colour's attribute. Each merge keeps two thirds, and the slots are what make it worth it. A full launch build's 70 jewels at level 5 match the jewel share (7 of 27).
- Jewels drop from elites, keepers and the Tower.

- **What waits:** the Condenser making jewels and stones; the Void Shop's emblems; chests holding higher jewels; Reinforce at the Forge machine with its ram.
- **Technical calls, the builder's** (from the review's integration):
  - Weights now hold Scale, so nothing multiplies them by it again.
  - The comparison panel shows the true change from the resolver run twice, with a breakdown scaled to sum to it.
- **Done when:**
  - Every rule above has its cases.
  - Try, Socket and the transfer pass a retry test.
  - A phone capture shows the Reinforce and War Emblems pages in every state: can try, can't afford, at the cap, success and failure.
  - The gap's case reads the table in `docs/research/combat-math.md`'s item 1.

### Part A, built (Faber, 2026-11-19, committed 17:09, 6b640a0)

- **Built:** `Rules.Reinforce` (Try, Cost, the server's roll), `Rules.Emblems` (Socket and Unsocket, `set:stat` keys through the bag), the level gap in `Rules.Hit`, and the transfer on equip (`Move = true` carries Reinforce, emblems and jewels). Save step 11 moves gear levels onto the item. Stones and emblems drop as `Config.Drops` seeds. Equipment's 36 images are uploaded under the group, with their places in `Config.Hud`.
- **Tested:** type check 0 new; offline logic 27,104 passed; the full self-test 2,994 passed. Try, Socket and the transfer each pass a retry test. The Gear case's fix (a debug item gets its rarity's sockets) passes alone: 10 of 10 (17:20).
- **Not yet:** the Reinforce and War Emblems pages and their phone capture (Equipment's install in B); part B.

### Faber's cloud session: the transfer under repeats (2026-11-20, offline; ab3f963)

- **A seeded case in `Cases/Regalia`:** 400 equips with Move over six rings and two presets, with a ledger of 8 so ids leave and come back, and a sixth of the equips cut short after they ran. No Reinforce level, emblem or jewel is made or lost, a repeat changes nothing, and a cut equip changes nothing.
- **Mutation-checked** against Transfer's swap, its kept emblems, the ledger's memory and Transaction's rollback. Offline 28,941/0 at that commit; the type check 0 new. It's pure, so Studio's `LogicTests` runs the same code.

## TR48. The loot refit, part 1: Hard's own budget, the keeper's count, the Tower, the materials (Faber, after TR47)

- **What it serves:**
  - D7, "each stage and difficulty rolls on its own budget" (`docs/decisions.md`), which isn't built.
  - The rarities' pace in `docs/design.md`, "The rarities' pace": a Rare in the first hour, and sure on the first Hard keeper's win.
  - Research's study (2026-11-19, 16:53; MODEL, Rook lead, under the combat review's patch, 100 players over 12 h): scripts and outputs in `build/scratch/quaestor/loot/` (`out_e1.txt`, `out_e2.txt`, `out_e2b.txt`).
- **What the block contains:**
  1. **The keeper's count per difficulty (OBSERVED bug).** `Profile.KeeperWins` counts one per ground, so the first Hard keeper gives a tier-2 chest and no Rare. It becomes one count per ground and difficulty, migrating today's count to Normal.
  2. **Hard's own budget.**
     - A chest from a Hard stage reads Drum Court's ladder rows.
     - Its items roll at G of the stage's last stop level plus 10: G(12), G(15), G(18) and G(19) for stages 1 to 4.
     - Normal keeps G(9).
     - MODEL: the median first Rare goes from 7.6 h to 2.0 h, and the Hard stages' median CR rises 0 to 16% over the combat review's solved one. Research re-solves the Hard lifts after, if that's too soft.
  3. **The first Hard keeper's win is a sure Rare:** `Chests.Keeper.FirstFloor = { Hard = "Rare" }`. With it, MODEL puts the median first Rare at 1.7 h, and 90% of players have one by 2.3 h.
  4. **The Tower, refit to the build players have** (MODEL). The Lift's excess over 1 is scaled by 0.3.

     | Stat | Lift |
     |---|---|
     | Health | 1.41 |
     | Attack | 1.23 |
     | Defence | 1.33 |
     | Hit | 1.25 |
     | Dodge | 1.91 |
     | Critical | 1.34 |
     | Critical Resist | 1.14 |
     | Block | 1.59 |
     | Penetration | 1.22 |
     | Elemental Resist | 1.19 |
     | Critical Damage | 1.03 |

     - `Tower.Chest`: Base 0 → 0.02, PerFloor 0.0018 → 0.0004.
     - The Tower's chest row: {59.49, 36.32, 2.86, 0.93, 0.40}. Worked by hand, not simulated.
     - An expected lead climbs 10 floors at level 10, 23 at 16 and 31 at 20, and gets about 15 to 17.5 chests an hour.
     - Carried health caps every lead at about 10 to 12 hard floors. `docs/balance.md`'s "17 at level 10" can't be met, so research restates it there.
  5. **The materials, as `Config.Drops` seeds** (DESIGN, at the "available" ramp). These are TR47's sources.

     | Source | Stones | Emblem | Jewels |
     |---|---|---|---|
     | Normal Shade | 22% chance of 1 Low | none | none |
     | Normal elite | 0.8 Low | 30% | none |
     | Normal keeper | 2 Low | 75%, the first win sure | none |
     | Hard Shade | 28% chance of 1 Low | none | none |
     | Hard elite | 1 Low | 30% | 45% of a level 2, part B |
     | Hard keeper | 2.5 Low | 75% | 1, part B |
     | A Tower hard floor | a Shade's of its band | none | 4% |

     - An emblem rolls its rarity on the chest ladder's row.
     - Drum Court's Mid and High stones: `loot/materials.py`.
  6. **The stage's real length, measured.** The server logs each stage run's start to its finish, travel and waits included. The model's pace swings 2 to 2.5 times on this one unknown: 50 to 110 s of fighting, against 180 to 210 s assumed before.
     - At the model's own times, stages give 610 to 686 kill-units an hour, above the 450 of the pace table.
     - `KillsPerHour` and `Quota` stay until the real number is in.
- **What waits, for research:**
  - The Epic and Legendary pace (the long run was stopped for memory). Worked by hand, the Tower row gives an Epic at about 13 h and a Legendary at about 41 h, against design.md's 4 to 6 and 15 to 20. So Hard's rows likely need an Epic, decided on the long run.
  - The emblem ramp (15% of full at Lantern Row) can't be met with one Uncommon emblem a socket, which gives 6 to 12%. Research's tier 1 call: the ramp is restated, and gear carries the early power.
- **Done when:**
  - The count, the budget and the floor have their cases, with a retry test on the keeper's chest.
  - The Tower's numbers are in Config.
  - The stage log writes a line per run that research can read.

### Built (Faber, 2026-11-19, 17:22)

- **The count:** `Profile.KeeperWins` is `{ Normal, Hard }` per ground; save step 12 moves today's count to Normal. `Progress.KeeperWon(data, ground, now, difficulty, loot)` counts on its difficulty, so a ground's first Hard win gives a first win's chest. `Progress.Wins(record, difficulty?)` reads one or all. The keeper's try takes its run's difficulty as it stands (`KeeperService.DifficultyOf`, set by `StageService`).
- **Hard's budget:** each Hard stage has its own chests in `Definitions.Chests` (`<ground>_<tier>_hard<stage>`; the keeper's tier 3 only on the stage it ends), at the last stop's level plus `Offset.Hard`, reading `Config.Chests.Hard.Rows` (1) past their ground's row. A run's foes carry `Difficulty` and `Stage`, so `DropService` drops that stage's chest. Normal keeps its ground's rows and G(9).
- **The floor:** `Config.Chests.Keeper.FirstFloor = { Hard = "Rare" }`: the weights under Rare go to none on a first win's chest on Hard.
- **The Tower:** the Lift table, `Chest` 0.02 + 0.0004 a floor, and its row, as written above. A hard floor's stones are a Shade's at `Config.Tower.Stones` ("Normal", Lantern Row's band).
- **The materials:** `Config.Drops.StoneChance` by difficulty (0.22, 0.28), the elite's and keeper's stones by difficulty, `EmblemChance` (elite 0.3, keeper 0.75) and `EmblemFirst = { Normal = 1 }`. A keeper's emblem now comes with its win (`Progress.KeeperWon`), never with its fall.
- **The stage log:** each run's length, from its beginning to its clear, its fall or its end, is a line in the server's output (`stage run lanternrow Hard 2: Cleared after 74.3 s`), the last 50 in `NL_Debug:Invoke("StageLog")`, and in a live game Roblox's custom event `StageRunSeconds` (Creator Dashboard, Analytics, Custom), its fields the stage and how it ended.
- **Tested:** type check 0 new; offline logic 27,212 passed, LogicTests in Studio 27,212 passed, with `Cases/Loot.luau`'s six cases (the count, step 12, Hard's chests, the floor with a retry and an interrupted win, the materials' rates, the Tower's numbers). Self-test in the Main place: Gear 10, Tower 63 and HUD 477 passed (the guide reads the new count). NOT VERIFIED, the Festival place (Now board, item 9): the Keeper, Drops and Stages cases, and a real run's log line.
- **For research:** Hard's chests are per stage, so a ground has up to ten more chest kinds in the bag. The keeper's emblem is sure only on its first Normal win, as the table says.

### Part 2: the Epic and Legendary pace (research, 2026-11-19, 20:46, revised 21:00 on the director's word; tier 2, for Faber)

- **The finding (MODEL, the long run, `loot/out_e3.txt`):** with part 1 built, the median first Epic comes at 11.8 h and the first Legendary after 45 h, against design.md's 4 to 6 h and 15 to 20 h. With one ground at launch, no ladder row a chest reads holds an Epic or a Legendary (they start at rows 5 and 7), so only the Tower's 0.93% and 0.40% give them.
- **The director's word** (about 20:55, `docs/decisions.md`): "the epic and legendary should come at any point imo but for the beginning it luck".
- **The change, three weights, each taken from Common:**
  - **Every chest,** Normal and Hard, from the first: Epic at 0.3% and Legendary at 0.05% or more.
  - **A Hard elite's chest:** Epic at 0.6% or more.
  - **A Hard keeper's chest after its first win:** Epic at 1.6% and Legendary at 0.35% or more.
  - **Left out on purpose:** the first Hard win's chest and the Tower's. The first Hard win drops everything under Rare, so these weights would become about half its roll (Epic) and one in ten (Legendary), a jackpot at 5 h (`out_e6.txt`). The Tower's row is above them already.
  - Config: `Chests.Least = { Epic = 0.3, Legendary = 0.05 }`, and `Chests.Hard.Least = { Elite = { Epic = 0.6 }, Keeper = { Epic = 1.6, Legendary = 0.35 } }`, or the shape Faber prefers. The chest's card shows the odds as rolled.
- **MODEL (`out_e7.txt`, the middle variant; design clock, 80 players, 45 h, a quarter in the Tower):**

  | First one | Lucky 10% of players | Median, rolled | Median, worn |
  |---|---|---|---|
  | Rare | 0.7 h | 1.9 h | 2.9 h |
  | Epic | 0.9 h | 3.7 h | 4.6 h |
  | Legendary | 2.4 h | 17.2 h | 22.1 h |

- **Limits:**
  - The clock is the design's 180 and 210 s stages. The real length, from the stage log, can move every time here by 2 to 2.5 times. Research refits once 20 real runs are logged.
  - With more grounds, the ladder reaches rows 5 and 7, and the Hard weights are dropped then. The weights on every chest stay.
- **Done when:** a case rolls each chest's weights (a Normal Shade's, a Hard elite's, the Hard keeper's first and after, the Tower's unchanged), and the bag's chest card shows them.

### Part 2 built (Faber, 2026-11-19, between 21:25 and 21:36 by the clock, alongside AR40's two fixes)

- **The shape, research's as written:**
  - `Config.Chests.Least = { Epic = 0.3, Legendary = 0.05 }`.
  - `Config.Chests.Hard.Least = { Elite = { Epic = 0.6 }, Keeper = { Epic = 1.6, Legendary = 0.35 } }`, on top of it.
- **The rule (`Rules.Chests.Least` and `Weights`):**
  - A ladder chest's Epic and Legendary rise to their least share of its roll, and the difference comes from Common. Its Uncommon and Rare stay its row's.
  - On Hard, a tier-2 chest on the stage a keeper ends (`ChestRows.KeeperStage`) takes the keeper's least, and any other takes the elite's. Lantern Row's stage 4 is the keeper alone, so no elite shares that chest.
  - The Tower's row and a keeper's first-win chest with a floor (Hard's) are untouched.
- **The chest's card says each chance to the hundredth, as rolled** (`Rules.Odds.Percent`), so a Legendary reads 0.05%. Before, it was to the tenth under 10%, which would have read 0.1%.
- **What a Lantern Row chest gives now:**

  | Chest | Common | Uncommon | Rare | Epic | Legendary |
  |---|---|---|---|---|---|
  | A Shade's, Normal | 93.65% | 6% | 0 | 0.3% | 0.05% |
  | An elite's on Normal, or a Shade's on Hard (row 2) | 91.05% | 8.6% | 0 | 0.3% | 0.05% |
  | A Hard elite's (row 3) | 87.35% | 10.9% | 1.1% | 0.6% | 0.05% |
  | The Hard keeper's after its first win (row 3) | 86.05% | 10.9% | 1.1% | 1.6% | 0.35% |
  | The Hard keeper's first win | 0 | 0 | 100% | 0 | 0 |
  | The Tower's | unchanged | | | | |

- **Tests:**
  - The type check: 0 new.
  - The logic cases: 27,248 passed, offline and in Studio. The new case, "Loot: TR48 part 2", checks:
    - research's numbers, and each chest's odds as the table says;
    - every Hard stage's elite;
    - the first Hard win's floor alone, the Tower's untouched, and Normal's first keeper's win;
    - 20,000 rolls each of a Normal Shade's chest and the Hard keeper's repeat, with Epic and Legendary at their shares.
  - Eight older checks compared a chest's weights to its ladder row by identity, and now read the row under the least shares. The Tower case's "no ladder row of Lantern Row's" gives a Legendary is now "more often than Lantern Row's ladder chests".
  - The self-test: the Items page's chest card shows 0.3% and 0.05% (Items page 121/0).
- **Status:** implemented and tested. Research's MODEL stands for the pace. Not director-accepted.

### Faber's cloud session: the keeper in a run (2026-11-20, offline, no Studio; f511b0a)

- **A keeper's win is never granted twice (section 9).** `Progress.KeeperWon` now refuses with `Resting` while the keeper rests from this player's last win. No try begins in the rest (`KeeperService.Try`), so a win then can only be that win again. Before, only KeeperService's in-memory flag stopped a second chest and emblem, since a server's own change carries no op id.
- **Made pure:** StageService's keeper hooks, `Stages.TryAt` (the stretch a try begins at) and `Stages.KeeperFell` (the win as the run's last stop).
- **Cases:** "Progress (section 9): a keeper's win repeated while the keeper rests…", and the keeper in a run on Normal and Hard in `Cases/Stages` (TryAt, KeeperFell, Level +10 on Hard). The older Progress case's second win moves from 60 s to 400 s, past the 300 s rest. Mutation-checked on the rest guard and TryAt's ground check.
- **Tested:** offline 28,923/0 at that commit; the type check 0 new.
- **NOT VERIFIED (the Festival place):** the keeper in a real run.

## TR49. The combat review, built: the six decisions (Faber, after AR40's C)

- **Feel line:** a lead walks into a Lantern Row pack and every Shade in it hits, crits, dodges and blocks back. The skull over a foe says what the fight will cost before the first swing. The sheet shows all five attributes, and CR rises with every piece that makes the lead win.
- **The director's word:** "1) ok", 2026-11-19, 20:57, to the six decisions as restated in `docs/research/combat-math.md`, "For the director: the decisions" (`docs/decisions.md`). The study, its numbers and its limits are there. Nothing here widens them.
- **What the block contains** (the changes are ready to merge in `build/scratch/quaestor/integrate/out/`):
  1. **`integration.patch`,** against `src/shared` as it stood at 16:26. It covers `Rules/{Stats,Hit,Hud}`, `Config/{Stats,Enemies,Hud,Chests,Growth}` and `Definitions/Attributes`, and its `shared/` folder holds whole copies.
     - Since then, TR47 part A (6b640a0) and TR48 (c7ac21e) changed `Config/Stats`, `Rules/Hit` and `Rules/Stats`. Those three hunks don't apply as they are, so merge them by hand.
     - Keep TR47's Reinforce, emblems, jewels and level gap, and TR48's chests, on top of the patch.
  2. **`server.patch`:** FightService (Kindle's old add at 886 to 890 goes; Lifesteal applied) and StageService (the Shades' stage factor). Its line numbers are from before AR42 and AR46, so merge it by hand too.
  3. **`cases_draft.luau`:** 206 checks, passing on the merged copy. They go into the logic cases, and every case that held an old number is re-read, never weakened.
  4. **An element for each of the ten without one** (decision 6; research's picks, by look and kit; set in `Definitions.Voidkin`):

     | Voidkin | Element | Why |
     |---|---|---|
     | Rook | Fire | the red brawler, Second Wind |
     | Kirra | Void | she vanishes and crosses the target |
     | Patch | Frost | the cold pack of a field medic |
     | Tumble | Storm | a spinning kick, wind |
     | Brick | Void | Door Slam draws enemies onto him |
     | Sable | Void | the sable shadow, a turned-aside hit |
     | Gantry | Fire | the steam behind a piston |
     | Mallow | Fire | Hot Meal |
     | Wren | Storm | Updraft, arrows on the wind |
     | Crane | Frost | Calm, the still water of a long draw |

     The 31 then stand at Fire 9, Storm 9, Void 7 and Frost 6. An element's look on a hit is the kit's own, so nothing new is drawn.
  5. **The screens that read the new numbers:** the sheet shows all five attributes on every Voidkin (the director, 13:53). The comparison panel shows the true CR change. The foe card's skull reads the fight's cost, with the cuts at 0.15, 0.5 and 1.0, and a foe at the lead's level or above is never grey.
- **What waits:** Hard's lifts re-solved under TR48's budget (research, on the first logged runs); any change to the class edges (0.046 against a target of 0.03, in the study's limits).
- **Done when:**
  - The type check passes, the 206 checks and every existing case pass, and the self-test passes.
  - **The Stage 1 playtest owed:** a new account plays through Stage 1 on Normal, and the capture records its lowest health and its time. The model says 66%; one play shows whether the packs, swinging together, are lethal.
  - A phone capture shows a Voidkin's sheet with all five attributes, and a foe card's skull in each of its four colours.

### Built in the game (Faber, 2026-11-19, 21:37 to 23:02 by the clock)

- **Merged by hand** from `integration.patch` and `server.patch` onto today's code, keeping TR47's Reinforce, emblems, jewels and level gap and TR48's chests on top:
  - `Rules.Stats` and `Config.Stats`:
    - five Basic Attributes (`Definitions.Attributes` adds Agility, Intelligence and Spirit), each converting once by its row, with the class's Main converting once more;
    - Combat Power as Scale × √(EHP × DPS) against the reference body;
    - the line prices as the weights.
  - `Rules.Hit`: F1 (every K × G reads its rating owner's level), F7 (a block multiplies outside the reduction's ceiling), Kindle's Extra through the elemental path, and `Hit.Expected` in closed form.
  - `Rules.Fight.Steal` with FightService: Lifesteal heals a share of what a hit removed, counted up to its cap a second, through `heal` so the Tower's cap holds. Kindle's old add is gone.
  - `Config.Enemies`: the rows refitted, Hard's Lift by Kind and the stage's factor (`Rules.Stats.Enemy`), read by FightService, StageService and the stage tile's CR. `Config.Growth.Early` is {2, 4, 6, 8, 10, 12, 14}.
  - The ten elements in `Definitions.Voidkin`, as the table above.
  - **The skull:** `Rules.Hud.Cost` (the share of the lead's health one fight takes), `Hud.FoeBlock` and `Hud.FoeTier`, with the cuts at 0.15, 0.5 and 1, never grey for a foe at the lead's level or above.
  - The sheet shows all five attributes, three then two, on the smallest phone (AR43's take 2, with its record).
- **The cases:** the draft's checks are in `LogicTestService/Cases/Combat.luau`. Every case that held an old number was re-read and none was weakened: Bag, Chests, Definitions, Fight, Hit, Regalia, Sheet, Stages, Stats. The skull's self-test case reads the tier from both blocks and holds the never-grey rule.
- **Tested:**
  - Type check 0 new.
  - The logic cases 28,782/0, offline and in Studio.
  - The self-test: the whole suite 3,163/0 at 59 fps (23:01). The touched filters passed before it: the Voidkin screen 243/0, the Overview 25/0, the Items page 48/0, Equipment 71/0, Shop 79/0, HUD's lead card 40/0, TR19's dock 49/0, the Kit's quick tap 13/0, the Clip 3/0.
- **Captures:**
  - The sheet with all five attributes: `build/captures/ar43/take2-lead.png`.
  - The skull's four colours on the smallest phone: `build/captures/ar45/skull-four.png`, from `skull-grey.png`, `skull-white.png`, `skull-yellow.png` and `skull-red.png`. Grey and faint is on a Shade a level under, its level whole; white, yellow and red are on an elite at the lead's level.
  - They're held by the new "Take: AR45's skull" (Manual), which moves the cuts round the fight's cost and gives the take's foes a hundred times their health so they stand. The card's health reads staged.
- **NOT VERIFIED:** the Stage 1 playtest owed (a new account through Stage 1 on Normal, its lowest health and its time). Lantern Row's world stands only in the Festival place (TR45), and opening that place waits on the director (item 9).
- **For research, found in the build:**
  1. The line prices come out a uniform 1.408 times the reference body's true marginal gains, every line alike, so the ranking between lines holds.
  2. The draft's time-to-kill targets leave out decision 6's elements: with Fire, Rook fells Stage 1's packs 12 to 19% faster than the targets assume.
  3. `tools/balance/sim.py`'s dps() predates F1 and F7 (noted in `Rules.Hit`).
  4. **Tier 1:** Lifesteal's heal shows no number; its trickle shows on the bar. Say if it should have one.
  5. The keeper is spawned with no Stage, so the stage's factor never reaches it. The factor's rows hold no keeper today, so nothing changes yet.
  6. The skull case's grey state now uses a Shade a level under, since at the lead's level a foe never reads grey.
  7. Since every Voidkin has an element now, the Voidkin screen's stage floor glows in its element (TR24's rule), where ten stood on grey.
- **Status:** implemented and tested; the Stage 1 playtest owed; for research's look.

### Research's pass and calls (Quaestor, 2026-11-19, 23:04)

- **Felt:** the sheet shows Rook's five attributes whole on the smallest phone, and the foe's card says the fight's cost in one glance: grey sinks, yellow and red jump. **What players see passes at competent.** TR49 closes on the Stage 1 playtest, still owed (item 9).
- **The one bold thing:** the red skull with its red level, which reads before the name.
- **Calls on the findings:**
  1. **The prices must equal the gains (must-fix, class: every number shown as a part of CR).** 1.408 is √2 to 0.4%, so it looks like a √2 in the price path, not a design. Find it and remove it, so an item's CR on its card is what it adds on the reference body. The ranking holding isn't enough: the card and the comparison panel must agree.
  2. **Keep the numbers.** Elements are part of the decided design, and a Stage 1 pack 12 to 19% faster with Fire stays inside the fit's band. The Stage 1 playtest and the refit after 20 logged runs take elements in. A MODEL limit, not a retune.
  3. Research's: `sim.py`'s dps() is brought in line with F1 and F7 at the refit.
  4. **Tier 1 agreed:** no number for Lifesteal. A number on every hit would bury the hits' own, and the bar shows it.
  5. Agreed, nothing changes now. A keeper row in the stage's factor must wire its Stage first.
  6. Agreed: it follows the never-grey rule.
  7. **Agreed:** it's TR24's rule working as written. The floor in the element's colour is better than ten grey ones.

### Research's must-fix: the prices are the gains (Faber, 2026-11-19, 23:05 to 23:10 by the clock)

- **Where the factor was:** not a √2 in the game's path, and the other way round from my finding 1. Measured by `Stats.Sum` at the reference body, every price was 0.710 of its gain, so a point added 1.408 times its price. That 0.710 is the normaliser in research's price run (`runs/s5_prices3.luau`: `out[stat] = parts[stat] * k`, k = the body's CR over its priced total).
- **What a price does:** it's never shown. The item card's CR is `Stats.Sum(after) - Stats.Sum(before)` on the wearer (`Rules.Bag`), and the comparison reads the same, so the card and the panel already agreed. A price sets a rolled line's points: worth / price (`Rules.Chests`). So the 0.710 meant an item rolled at worth W added 1.408 W on the reference body.
- **The fix:**
  - `Config.Stats.Power.Weights` are the gains themselves, measured at the reference body (Rook in Fire, level 30; a percent's per G).
  - `Config.Chests.PowerPerG` goes from 63.5 to 89.4, over the same 0.7102, so every line rolls the points it did, within 0.15% (Attack ×0.9999, Health ×0.9995, Lifesteal ×0.9987). An item's worth is now what it adds on the reference body. No balance moves.
- **Measured after:** price over gain is 0.9997 to 1.0003 for all fifteen lines at levels 1, 10, 30 and 55.
- **The cases:**
  - Bag's price case now holds price = gain within 0.5%, where it held one shared factor within 2%.
  - Chests' attribute price reads 9 to 10 a point, where the normalised prices read 6 to 7.
- **Tested:**
  - Type check 0 new.
  - Logic 28,782/0, offline and in Studio.
  - Self-test: Items page 48/0, Chest 2/0, Equipment 118/0.
- **For research:**
  - `docs/balance.md`, "The stats", says an attribute point is worth about 6 to 7. In the gains it is 9.4 for Strength and 9.5 for Endurance.
  - If gear should be stronger or weaker, that's `PowerPerG`, research's number.

### Research's second look (Quaestor, 2026-11-19, 23:11)

- **The must-fix is met:** every price is its gain within 0.03%, and no line's points moved. The 0.710 was research's own normaliser in the price run, not the game's, and my √2 guess was wrong. `docs/balance.md`, "The stats", is restated as built (4b77430). Gear's strength stays where it is.
- TR49 now closes only on the Stage 1 playtest (item 9).

## TR52. The signature on a tap: a block, judged in motion (Faber, after the Studio run)

Research, 2026-11-23, 14:54, on the director's word of about 14:50: F1 of `docs/research/design-holes.md`, "Block it first". It's a try in a block, tier 1. Whether it joins launch is the director's call after the verdict, since manual signatures are under "Out of launch" (`docs/design.md`).
- **Why:** in a fight the player does almost nothing, and every auto battler studied leaves the ultimate's timing to the player (H1).
- **Feel line:** the ring at the right edge fills as your fighter fights. When it's full it lights and waits. You tap it at the moment that matters: a Guard's shield up, the pack bunched, the keeper's recovery. Your fighter fires its signature at once, and you know the hit was yours.
- **The block contains:**
  - the signature's readout (`docs/ui.md`, the right edge, low) becomes the button. It fills on the signature's cooldown as today, lights when full, and fires on a tap, with no new element on the HUD;
  - an **Auto** toggle beside it, on by default in the block. On, it fires as today, so parked play stays allowed;
  - the tap answers on the frame. The signature starts its own clip at once, and a full ring held for 0.5 s pulses once, so a ready signature is never missed (seed).
  - **Measure first:** the ring's place against Roblox's jump button on a phone. If they meet, the ring moves, and the measure is written here.
- **What waits:** a keyboard key on desktop (seed Q, after the verdict); the ring's finished look; the Tower's fights; the sound.
- **Checks:**
  - the logic case: a tap with the ring not full does nothing and changes nothing; a full ring fires once, and a repeated tap never fires twice;
  - captures on the smallest phone, the ring empty, full and fired;
  - research's verdict and the director's, from one Lantern Row run with Auto on and one with it off, judged in motion.
- **Cap:** 90 minutes.
- **Order:** after the Studio run of AR49, TR51 and TR37, beside the small ones.

### Faber's block (Faber, 2026-11-23, 22:08)

- **The measure, first.** Studio's Device Simulator, iPhone 16 Pro (750×401), in GUI pixels under its 58 px top inset.
  - The readout stands top left, under the lead's card (AR12), at 11,124, 62×62. The Auto toggle stands after the eye, at 141,127, 107×56.
  - Roblox's jump button is at 655,253, 70×70, bottom right. The ring and the jump button don't meet: 582 px apart.
  - The dynamic thumbstick starts wherever a left thumb lands in x −100 to 300, y 114 to 443. The ring and Auto stand inside that zone's top edge.
  - The HUD draws over Roblox's touch controls (DisplayOrder 10 against 0), so a touch on the ring is the ring's. A real touch in the simulator fired the signature once, its clip 62 ms after the touch, and the stick never started.
  - So the ring stays where it stands (research, 721e825 at 21:33, ui.md's row). The cost to weigh in motion: it's the left thumb's, the thumb that walks the avatar; the right thumb only turns the camera.
- **Built:**
  - **The rule,** `Rules.Fight`:
    - `Fight.Tap` arms the signature only while it's ready and not armed already;
    - `Fight.Signature` names it: the kit's action with a cooldown;
    - `Fight.Choose` takes a held action, the signature with Auto off and nothing armed.
    - Armed, the signature is the next action, and its start disarms it.
  - **The server,** `FightService`:
    - the `Signature` remote takes "Tap" and "Auto";
    - armed, the signature fires at once when its target is in range, cutting the combo wherever it is; out of range, it fires the moment it can;
    - Auto lives on the player (`SignatureAuto`), on this server only and not saved: the block's.
  - **The readout** (`HudController`, `UI.Readout`):
    - a touch going down fires it, as a fight's buttons do, not on the let-go;
    - it squeezes in on the frame (`Press` 0.12 over `PressTime` 0.14 s);
    - armed and waiting for range, it stays in a little (`Armed` 0.06);
    - a full ring left untapped pulses once (`Pulse`: `Hold` 0.5, `Length` 0.4, `Scale` 0.16). My reading of the seed: its 0.5 s counts from the end of the ready swell or the fade-in, so the two never merge.
  - **The Auto toggle:** the kit's button after the eye, in the place of a fallen lead's "Send another" (never both). It reads "AUTO ON" / "AUTO OFF": the kit's set light alone read the same either way at the phone's size.
  - Every number is in `Config.Hud.Readout`, tuned live.
- **Checks:**
  - **Type check:** 0 new.
  - **Logic offline:** 29260 passed. The new case:
    - a tap with the ring not full arms nothing and changes nothing;
    - a full ring arms once, and a repeated tap arms nothing;
    - after the fire, a tap on the same frame arms nothing;
    - Auto off holds the signature, and armed it goes first.
  - **"HUD: TR52"** (`SelfTestController/SignatureCases.luau`), 16 passed at 55 fps:
    - Auto off holds a full ring: 0 fires in 2.7 s;
    - it pulses once;
    - the tap squeezes it in on the HUD's next frame, to 0.893;
    - the clip starts 147 ms after the tap: Studio's round trip;
    - three taps on one frame fire once;
    - with the ring not full, the server answers NotReady and nothing changes.
  - **The suites:** "HUD:" 548 passed, 0 failed, TR52's case in it. Its first run failed TR52's case 9 times: a case before left the lead idle with the camera turned away, so the Shade spawned ahead was never taken on (fix 6). The case now heals, calms and clears first, and its Shade comes for the lead. "Kit:" 85, "Camera:" 37 and "Fight: each lead's passive" 23, 0 failed. "Fight:" 640 passed, 8 failed, all eight in Watt's Ground Wire. That's the order effect noted on 2026-11-19 (TR49's run): alone in a fresh playtest it's 20/0, and after TR52's case 20/0. TR12's take stops at its first check, "Rook and Ironhymn owned": the test save owns no Ironhymn (kirra, lyric, marigold, pip, rook, sable, watt). That's a precondition of the save, not TR52's.
- **Captures,** smallest phone, from the simulator: `build/captures/tr52/`.
  - `phone_full`: white-hot, waiting with Auto off.
  - `phone_fired`: emptied as it fires.
  - `phone_filling`: the front partway up.
  - `phone_auto_on`, `phone_auto_off`: the toggle's two words.
- **Not built** (waits, as the entry says): the desktop key, the finished look, the Tower's fights, the sound.
- **For the verdict:** one Lantern Row run with Auto on and one with it off. That's the director's play, and research's verdict from it.

### Research's read of the block, before the director's run (Quaestor, 2026-11-23, 22:11)

From the five stills in `build/captures/tr52/` and Faber's measure. The verdict itself is the run's.
- **Faber's three readings, accepted (tier 1):**
  - the pulse counts from the end of the swell;
  - an armed tap cuts the combo, since "fires its signature at once" is the feel line's own;
  - the toggle needs its words.
- **The words,** research's: "Auto on" and "Auto off", in the kit's sentence case, as the Power screen's "Auto" and "Send another" are written.
- **The run tries the ring under both thumbs.**
  - The feel line put the ring at the right edge, and the stale ui.md row is why the measure was taken against the jump button.
  - Where the ring stands, it's the left thumb's, the one that walks. A Dasher's line asks you to move (AR52), so you can't step off a line and fire at once.
  - In every still the right thumb has only the camera and jump, with a free field above the jump button.
  - So, for the run: the ring's place tunable live (`Config.Hud.Readout`), where it stands and above the jump button. The run with Auto off is played once at each.
  - The eye stays where it is in the block. If the ring moves, ui.md's rows move with the verdict.
- **The stills can't show:**
  - whether a tap lands in the moment, which is the run's;
  - "filling" from "fired" at the phone's size: the two read alike (`phone_filling`, `phone_fired`). That's the ring's finished look, which waits.
- **The run, the director's:** Lantern Row once with Auto on, then with Auto off, at each place. Research's verdict comes from it.

### Faber's add for the run (Faber, 2026-11-23, 22:17)

- **The words:** "Auto on" and "Auto off".
- **The ring's place, tuned live:** `Config.Hud.Readout.At`.
  - `"Card"` stands it where it was. `"Jump"` stands it over Roblox's jump button, centred on it, `Jump.Above` (12) points clear of its top.
  - `NL_Debug:Invoke("Tune", "Hud.Readout.At", "Jump")` moves it mid-run.
  - It reads the touch controls' own jump button. Without one (a desktop playtest), it uses where Roblox would put it in the HUD's box.
  - The eye and Auto stay in the corner.
- **Checks:**
  - **Type check:** 0 new.
  - **"HUD: TR52", desktop:** 24 passed, 0 failed. That's both cases: the toggle says "Auto off" and "Auto on" in its words, and the new place case.
  - **The place case on the phone** (the simulator's iPhone 16 Pro, its own jump button at 655,253, 70×70): 8 passed, 0 failed.
    - The ring stands at 658,177, 62×62, centred over the button within 0.3 px, and 13.5 px clear of its top.
    - It stays on screen, the eye doesn't move, and tuned back it stands under the card again, to the pixel.
- **Still:** `build/captures/tr52/phone_jump_auto_off.jpg`. It shows the ring full over the jump button in a fight with Auto off, the guide's arrow clear to its left, and the toggle reading "Auto off".
  - The older stills still show the first word, "AUTO".

## TR53. The base between runs: what it made while you were away, and its state during a run (Faber, after the install backlog)

Research, 2026-11-23, 14:58, F4 and F6 of `docs/research/design-holes.md`: the director left these to research ("whatever best in your opinion"). Tier 2 (research, and Faber's area): a new moment players see. The look of the card is Modulo's, in the system slab's make.
- **Why:** the base and the fights are two islands (H7), and nothing marks a return home. Pillar 3 promises "a shard cracking while you fight".
- **Feel line:** you come home from Lantern Row, or log in the next day, and one card says what the base did while you were gone: power stored, stones made, a fighter trained, a shard broken. One tap takes it all, and the base looks busier for it. During a run, a quiet line tells you your shard is still breaking at home, and a notice says when it's done.
- **The block contains:**
  - **The return card:** shown once on arriving at the base after a run, or on joining, when anything changed: the battery's gain in kWh, the Condenser's stones, the Training machine's levels, a shard ready to reveal. One "Collect" or "Reveal" press takes it. If nothing changed, no card.
  - **In the Festival place:** the profile is shared across the universe, so the run's HUD shows one line of the base's state (the shard breaking and its time left), and one notice when it breaks: "Your shard broke. Its Voidkin waits at home." The reveal stays at home.
- **What waits:** the card's finished look; a sound; an opt-in experience notification (Roblox: one a day, ages 13+, never required), which comes after the director's word.
- **Checks:** the logic case that a return shows each change once, and a repeat shows nothing; captures on the smallest phone; research's verdict in motion.
- **Cap:** 90 minutes for each half.
- **Order:** after the install backlog and TR52.
- **The look** is AR55, Modulo's, drawn ahead (research, 18:27).
- **From TR31,** folded in (research, 20:07; AR55, research's pass):
  - the server credits everything on arrival, and the press only shows it, sending each amount to its counter;
  - the battery's line is its net gain, shown only when it gained;
  - a battery that ended full and sold its overflow reads "Full", with the Credits as its soft word.
  - The logic case adds: a net loss shows no battery line.
- **Faber, 2026-11-24, 14:06:** the case failed at the smallest phone (the press 37 px, under 44). The press is 52 points now, the slab 8 taller, and the Void Shop's countdown waits while the card is up, as the next step does (`6a817eb2`). The case is 37/0 in the main place, published privately as version 1200.
- **Research's pass on the worker lines, 2026-11-26, 01:15,** from `build/captures/tr53/` at 568×320, 844×390 and a window: passes. Each worker line reads in the Training line's form, the fold line wears its first worker's face, and the battery's #FFE266 is the pill's. Faber's tier 1 calls stand, the sooner fold on short phones included.
  - **On phones the fold stays,** none of Faber's three ways: a tighter pitch takes the rows under what reads at 568; without its title the card no longer says what it is; risen beside the pills, it covers the world's right third. On a phone the card is a glance with one press, and each worker's growth shows at its bay.
  - **Two word changes, tier 1 (Faber's):** the fold line names the most-grown worker whose face it wears, "+11 levels · Watt and 2 more", falling back to "3 workers" where a name doesn't fit at 568; the window's "1 more worker" stays. And one Credit is "+1 Credit", as "+1 level" already is.

## TR54. Goals, basic at launch: a dare per stretch, today's three, and Next (Faber, after TR52 and AR52)

Research, 2026-11-23, 15:24, on the director's yes and "js basic at launch" (`docs/design.md`, "Goals"; `docs/decisions.md`, the row of 15:23). **The Mask Ledger is cut** (the director, 2026-11-23, by 18:38; `docs/decisions.md`): nothing in the goals wears Lantern Row's festival, and no mask goes on the base. The look is AR53's, Modulo's, with its redraw.
- **Feel line:** as a stretch starts, its dare unfolds under the run's line and folds to a small mark that holds while you keep it. On the run's card: "Dare kept" and the stones. Home shows three plain goals that finish themselves while you play, with the account's next step pinned above them.
- **The block contains:**
  - **Dares,** one fixed dare per stretch (research, 17:49: the run has four stretches and no start card), checked on the server. Each is paid when its stretch is cleared with it kept, and a later fall takes nothing back. The run's card shows them all, the fall's card too (AR53):
    1. "Finish with your lead above half."
    2. "Break a raised shield with your signature." (needs TR52's tap and AR52's Guard)
    3. "Let no Dasher's line touch you." (needs AR52's Dasher)
    4. "Stand outside every slam." (needs TR44's lead movement)
    Until a dare's piece is in, that stretch's dare is "Finish without your lead falling." Kept: one forge stone of the ground's grade (seed).
  - **Today's three:** one from each list, drawn on the server at 00:00 UTC, banked up to three days (nine at most), each paying one Lantern Row shard.
    - Fight: "Keep a dare." / "Clear a stretch on Hard." / "Win three Tower floors." / "Bring down the Lamplighter."
    - Base: "Let every bay run a full hour." / "Break three shards." / "Collect the Condenser's tray." / "Train a Voidkin for an hour."
    - Roster: "Lead a run with someone new." (a Voidkin not led today) / "Raise a Voidkin a level." / "Forge once."
  - **Next,** the Today list's head, above the goals, holding its back press (research, 18:54, at AR53's redraw): the account's one next step, with what it opens, the first not done of:
    1. "Bring down the Lamplighter. Hard opens on Lantern Row."
    2. "Raise the base to level 2. A third bay opens, and the Condenser wakes."
    3. "Bring down the Lamplighter on Hard. Its first chest holds a Rare or better."
    4. "Raise the base to level 3. A fourth bay opens. Machines reach level 30."
    5. "Climb the Tower to floor 25. Each new floor pays a first-time bonus."
    6. All done: "Drum Court's gate stays shut, for now."
    Each says only what launch opens (`Config.Base`, `Config.Condenser.Wakes`, `Config.Chests.Keeper`). An update that changes one changes its line. What it opens stays at 45 letters or fewer, so it never takes a third row (three lines shortened at 18:54; content check PASS at 18:55).
  - **The labels:** "Today", the card's word; "Next"; the banked days "Yesterday" and "Two days ago"; a done goal's press, "Claim"; the card's chip, "Dare kept" with "+N".
- **The rules in pure Luau** (`Rules.Goals`): the draw, the banking, the reset, and each goal's check. Logic cases:
  - a goal pays once;
  - a repeat or interrupted claim pays nothing more (the op ledger);
  - the bank holds nine at most;
  - the reset is on UTC, whatever the server.
- **What waits:** the dares' pools, weekly goals.
- **Content check:** PASS on the lines and labels (15:29 and 17:49). "Bring down the Lamplighter", which replaced the masks' wording at 18:38, passed its own check at 18:39.
- **Checks:** the logic cases; captures of the card, the results and Home on the smallest phone; research's verdict in motion.
- **Cap:** about 10 hours of build (research's guess; Faber's estimate replaces it).
- **Order:** after TR52 and AR52's behaviours.

### Faber's build (Faber, 2026-11-24, 01:52 by the clock)

- **Where it lives:** the rules `Rules.Goals` and `Rules.GoalFacts` (the account's facts Next and the draw read, apart so no rule requires itself); the words `Definitions.Goals`; the numbers `Config.Goals` and `Config.Hud` (`Stages.Dare`, `Stages.DareCard`, `Home.Today`); the save's `Goals` (`docs/engineering-plan.md`, "Goals"); `GoalService` on the server; `UI.DareLine`, `UI.TodayList` and the run's card (`UI.StageScreen`) on the client. AR53's 17 images are uploaded under the group, all Approved (`docs/asset-log.md`).
- **Every path counts:** each event is noted in the rule that makes it (`Goals.Note`): a shard broken and the Breaker's time in `Rules.Breaker`, a level in `Rules.Drops` and the Breaker, the tray in `Rules.Base`, a forge in `Rules.Reinforce`, a Tower floor in `Rules.Tower`, the keeper in `Rules.Progress`, a Hard stretch in `Rules.Stages`. Away time counts too: the days roll on join before the base's away time lands.
- **Claims:** one action, `GoalClaim { Day, Slot }`, behind the op ledger. A repeated request gets its first answer, a claimed goal is refused, and an answer that fails commits nothing.
- **A dare:** it opens as each stretch begins, is judged as the stretch clears, and its stone is paid inside the clear's own step, so a clear that isn't saved pays nothing. A later fall takes nothing back. Until its piece is in (`Config.Goals.Ready`), a stretch takes the fallback.
- **Tier-1 calls** (mine, small and reversible):
  - a goal's count goes to every open goal of its kind on every banked day;
  - each draw is fixed by the player's id and the day;
  - a new account starts today, with nothing banked;
  - "above half" follows the lead's health both ways and is judged at the clear;
  - a "Do" dare's mark stays lit once done;
  - a goal whose piece the account hasn't opened is never drawn (Hard, the Tower, the Condenser, the forge). The Tower opens at a best floor of 1, the forge with any gear owned;
  - "someone new" counts a stage, keeper or Tower run, and the day's first run always counts;
  - "every bay" counts only while the base generates with every bay filled; "train" counts while training runs, away too;
  - a Dasher's line is a mark with a length, a slam one without;
  - dares run on Normal and Hard;
  - the day turns at 00:00 UTC, looked for every 5 seconds;
  - the dim's strip under a phone's inset hides when it has no height, so it's never a tap of nought.
- **The captures' review found three faults, each fixed:**
  - stretch 2's dare and later ones stayed folded: at a stretch's advance the dare comes before the run's line is built again, and the line it first came to counted it as shown. It counts once it's laid now, and case 2 checks stretch 2's unfold;
  - Roblox drew its own scroll thumb past the list's glass, a white line, even at thickness nought: hidden, as the Bag's chips already do;
  - the cases' clean-up began a new run instead of ending one: a run is ended by its lead's fall now, the game's own way out.
- **Captures** on the smallest phone (568 by 320 at 0.85, drawn at 852 by 480), in `build/captures/tr54/`:
  - the dare: open (`dare_open`), folded (`dare_folded`), dark below half (`dare_broken`), kept (`dare_kept`), the three marks magnified (`marks`), and stretch 3's unfolding after the fix (`dare_next`);
  - the cards: the fall's with the kept chip and the road's mark (`card_fall`), the keeper's with the chip on its time row (`card_win`);
  - Home: the cog tile and the Today card with one claim waiting (`home`), the list with Next and the rows, a run behind it (`list`).
  - A Manual take holds each state for a still: "Take: TR54" (the self-test's GoalCases).
- **My own review, for research's pass:**
  - The kept mark is told from the held one only by its halo at rest (`marks`); the flare carries the moment in motion. Whether it needs more at rest is research's call.
  - The chip's forge stone is a dark cell at 22 points and reads as a stone only up close.
  - On the keeper's card the chip shares the time row, which is then full.
  - The Today card's pips read as dots: the gold one is clear, the open and the claimed ones are close.
- **Checks:**
  - the type check: 0 new;
  - logic: 29845 passed, 0 failed, offline and in Studio;
  - self-test: Goals (TR54) 55/0, Home's panel (AR49) 41/0, Settings (AR43) 27/0.

### Research's verdict: competent in its look, holding on three must-fixes (Quaestor, 2026-11-24, 01:56)

From the ten captures (the stone chip, the card's rows and the Today card read at 3 and 4 times) and `Rules.Goals`. The motion read is at the second look, since must-fix 1 changes the mark's beats.
- **Felt:** as a stretch starts, its dare reads at once under the line in the line's own glass, then folds to a quiet mark. The cards say "Dare kept" plainly. Home's Today card glows gold when a claim waits, and the list puts the account's next step on top.
- **Tier:** competent. **The one bold thing:** the tab that folds round its mark. The dare costs the fight no room, and a break is a silent split.
- **Must-fixes, each by its class:**
  1. **A dare's mark answers its own question at rest, and the moment its fate changes is seen.** A keep dare's mark asks "still holding?", a "Do" dare's asks "done yet?". Today `Goals.DareLook` gives a "Do" dare "Holds" before and after it's done, so stretch 2's mark is lit before the shield breaks and doesn't change when it does: the dare's own moment gets no beat. The means are Faber's (a "Do" mark unlit until done, then the kept flare, say), with a logic case. Not yet done must read apart from broken.
  2. **Every reward on the run's cards reads as its item at the smallest phone,** as the shards, the shard and the chest do. The forge stone is a dark rock on a dark cell, and "+1" says nothing until it reads. The means are Faber's or Modulo's, whichever is cheaper.
  3. **Every row of the run's cards fits its longest value inside the card at the smallest phone.** Today's win row is full with "0:06". Show the longest in a self-test and a still: a run past ten minutes, a new best (the clock at the title's size, then "a new best"), with a dare kept. If it doesn't fit, the chip takes a row of its own, as on the fall card.
- **Faber's four calls:** kept and held at rest stay as they are: after must-fix 1, a keep dare shows kept only at the clear, with its flare. The stone is must-fix 2, the time row must-fix 3. The Today card's open and claimed pips go to polish-later: the gold one, the one that asks the player to act, is clear, and the card's gold frame says it too.
- **Next:** Faber's fixes, then the second look in motion. Send a short capture of the beats: the unfold and fold, a break, a "Do" dare done, the kept flare at the clear.

### Research's lines for the run's card (Quaestor, 2026-11-24, 11:31)

The director, on TR54's card stills: "i thought we said we stopped with the corny, ai slop lines", about "Hard is open" (the register, by 11:29). The card's lines, read in one pass against `docs/design.md`, "The words". These replace TR50's lines for the card.
- **"Hard is open" and its band go.** The Hard press says it instead: on this card only, the press comes in shut under Hard's lock (the Arc panel's own mark), and about 0.3 s after the card settles the lock lifts off and fades as the press lights. It reads "Hard" with Hard's chevrons, as now. No line replaces the band.
- **The fall's title:** the lead's own name, "Kirra fell", where it read "Your lead fell", in Hurt's red as now.
- **The fall's row:** "Next run starts at Stretch 3", where it read "Your next run starts at Stretch 3 of 4". The marks above it already show the four.
- **The best's tag:** "New best", where it read "a new best".
- **They stay:** "Lantern Row cleared" (plain, and it names the ground); "Dare kept" (the dare's own verb: holds, kept, broken); Hard's chevrons on the press into Hard and on a Hard run's Retry, since that's Hard's mark as on the panel's badge, not ornament.
- **The class, for every screen:** a line is never set as a banner with ornaments on both sides. News is shown by the thing that changed: a press lit, a lock gone, a mark filled.
- Research's second look sees the lock lift in motion, in TR54's capture.

### Faber's fixes: the three must-fixes and research's lines (Faber, 2026-11-24, 12:05 by the clock)

In `565893e6`. The ceiling of 15 is its own commit, `bccd9eee`.
- **Must-fix 1, a "Do" dare's mark asks "done yet?":** `Goals.DareLook` gives a Do dare "Waits" until it's done, then "Kept". A keep dare keeps "Holds" and "Broken". The Waits mark is the held mark unlit (`Config.Hud`, `Stages.Dare.Waits`), so not done yet reads apart from broken, which keeps its split. Done, it flares as a kept dare does at the clear. Logic cases are in `Cases/Goals`. The debug command "DareStep" steps a dare's fate for a take.
- **Must-fix 2, the stone reads as its item:** the stones the dares paid stand in the rewards' row as one reward among the others, on either card, the picture at 28 points on a warm light (`DareCard.Stone`). The chip says "Dare kept" alone.
- **Must-fix 3, every row fits its longest:** the rewards' row is laid from the middle, each cell as wide as its words, and shrinks to keep inside the card's inset, never below 0.85. The chip rides the time's row when the row's longest fits; otherwise it takes a row of its own, measured first. The case "Goals (TR54): the run's cards at their longest…" lays four cards on the smallest phone and checks every shown piece, the title too, inside the inset: a new best past ten minutes, past an hour, from a later stretch, and a fall named by a 20-letter nickname.
- **Research's lines of 11:31:**
  - the "Hard is open" band and its span are gone;
  - on the card whose clear opened Hard, the press into Hard comes in shut under Hard's lock (the Arc panel's mark). 0.3 s after the card's beats the lock lifts 8 points and fades over 0.3 s as the press lights (`Stages.Card.Unlock`). A tap waits until it's lit. Reduced motion shows it lit;
  - the fall's title names its lead as a list shows it, "Kirra fell", in Hurt's red. The name rides the fall's results (`Stages.Lost`, `Lead`), so it's the run's own lead. A long nickname shrinks the title, never below 0.6;
  - "Next run starts at Stretch 3"; "New best".
- **The suite's own faults, fixed:**
  - Play opens the Play panel now, so the trip's and the Arc panel's cases go through it (`Helpers.openArc`). Play's second tap closes the Arc panel too.
  - The Guard's break case raises the shield up to six times, since the signature fires only after its swing.
  - The Dasher's counts are each lunge's own: its First lunge landed in the same read.
- **Found on the way:**
  - the Festival's place had lost its `PlaceRole` attribute and booted as Main, every Festival case skipping. It's set again and saved (version 5).
  - "a machine's plate… this window" fails in a restored Studio window (1228 by 651, the plate hides over the avatar) and passes maximized. That's the window, not the game.
- **Checks:**
  - the type check: 0 new;
  - logic: 31,115 passed, 0 failed, offline and in Studio;
  - self-test, main place: Goals 86/0, Tower (TR29) 63/0, a machine's plate 33/0, Shades (AR52) 40/0, Reveal 176/0, Base view 201/0;
  - self-test, the Festival's place: Stages (TR50) 91/0, with the lock's lift and the lead's name; the dare 34/0; Keeper 42/0; Drops 13/0; Places (TR45) 21/0.
- **Owed for research's second look:** the capture of the beats from the Festival's place (the unfold and fold, a break, a Do dare done, the kept flare at the clear, the lock's lift). It's next, once the director is done with Studio.

## TR55. Forge heat, and a worker's experience by the kWh it makes (Faber, on the director's yeses of 2026-11-24, 10:50)

Research's seeds, `tools/balance/seeds.json`: "forgeHeat" and "power.workXp"; `docs/balance.md`, "A worker's experience". Opened by Faber, 2026-11-24, 12:20 by the clock.

- **Feel lines.** A player whose Reinforce try fails watches the item's heat bar climb, and knows a full bar makes the next press sure. A worker in a bay rises a level now and then while it makes power, so the whole bench grows behind the Training machine.
- **In the block:**
  - **Forge heat:**
    - The rule, pure, in `Rules.Reinforce`: `Heat`, `Fill` and `Odds`. A failure adds round(50 × its chance), up to 100. At 100 the next try succeeds whatever the roll. A success empties it.
    - The item's `Heat` field: none at 0, so no migration (`docs/engineering-plan.md`, the owned item).
    - The transfer moves it with the level.
    - The try's Credits base rises to 32.5.
  - **The Reinforce page:**
    - its odds come from the item's heat;
    - a grey block of the bar sits under the said lines (`Config.Hud`, `Equipment.Reinforce.Heat`): hidden while a try is sure (+1 to +5);
    - full, the bar lights in the good with "Next try is sure".
  - **A worker's experience:**
    - `Training.WorkRate` and `Training.Work`: each kWh pays 100 s of the Training rate, never more a second than the rate (`Config.Base`, `Bays.Xp`). Watt makes 18 kW at level 1 and earns half the rate; Kirra makes 6 kW and earns a sixth.
    - The Breaker pays each bay's worker as it steps. A worker's level is an event, since its kW rise with it, so many small advances still land where one large one does.
    - Its leftover seconds stay on the bay (`Bay.Banked`). A new worker starts with none.
    - Away, it stops with the generation after the away hours. Its levels count toward today's "Raise a Voidkin a level".
    - The advance's summary gives `Worked`, the levels the workers gained, for TR53's return card.
- **Waits:**
  - the bar's look and words: research's verdict on the grey block, then Modulo's art if it calls for it;
  - the bar filling inside a failed try's beat (today the page redraws after the beat);
  - the workers' levels on TR53's return card.
- **Fixed on the way:** the Config line "Watt and Rook at level 1, 30 kW". Every aptitude is 3 or under, so Watt makes 18 kW and Rook 12.
- **Cases:**
  - logic: "Reinforce: forge heat (TR55)…" and "Breaker: TR55, a worker earns by the kWh it makes…";
  - the five Breaker, Condenser and Base cases that assumed a worker's kW never change hold their worker at the last level;
  - the price case at 32.5;
  - self-test: "Equipment: forge heat on Reinforce (TR55)…", through Studio's new "ItemForge" (an item's level and heat by hand).
- **Checks:**
  - the type check: 0 new;
  - logic offline: 31,157 passed, 0 failed;
  - the self-test case: owed, at the next Studio turn.

## TR56. A chest for everything: the Emblem Case, the Jewel Pouch and the Forge Crate, with the orphans closed (research's request, tier 2, for Faber; Modulo the three pictures)

Research, 2026-11-24, 14:00. Launch-design's item 5. The design: `docs/design.md`, "Chests" ("The family at launch") and "Regalia: gear" (War Emblems, the Stone Condenser, Presets). The numbers: `tools/balance/seeds.json`, "chestFamily". It closes TR48's Rare gap too.

- **Feel lines.** After a Hard clear, Open all turns over a Jewel Pouch and a Forge Crate beside the keeper's chest. Three spare Attack emblems fold into one Rare at a press of Combine.
- **In the block:**
  - the three kinds as chests;
  - the Rare least;
  - the emblem drop as a case;
  - the Tower's tenth-floor cases;
  - a Hard keeper's pouch and crate;
  - the combine (pure rule, one server step with an id, a repeat a no-op);
  - Mid into High from the Condenser's level 10;
  - presets 2 and 3 by base level;
  - jewels' points in the resolver and the Condenser's jewel making (seeds "jewels").
- **Waits:**
  - Modulo's three pictures (grey stand-ins meanwhile);
  - the combine's effect and sound;
  - the welcome week's and codes' contents.
- **Cases, one a rule:**
  - each chest's Rare at its least and above its Epic;
  - a case's rarity matching its gear chest's;
  - the Tower's case once a floor;
  - the pouch's and crate's rolls;
  - the combine's refusals and a repeated request paying once;
  - High refused under level 10;
  - presets at their levels.
- **The content check** reads the new names before the build.

**Faber, 2026-11-24, 17:30: built, research's pass next.**
- **Implemented.** The block, as listed. Pouches and crates are chest rows (tiers 6 and 7) that open into the bag's jewels and stones. A case rolls its emblem when opened. The Combine pill sits on War Emblems, the Condenser card has a Switch prompt (F), and the preset row is on the Voidkin sheet. The pictures are the kinds' words on grey until Modulo's land.
- **Tested.**
  - Type check: 0 new. Logic offline: 33,813 passed, 0 failed, with ChestFamily's nine new cases.
  - Self-test: Base: TR37 44/0, War Emblems 35/0 (the new Combine case included), Gear: TR47 10/0, Items 123/0, Tower card 27/0.
  - NOT VERIFIED: the Switch on at level 10 and the card turning to Mid. The check is written, but the PC locked before it ran (read once by hand: both prompts on).
  - Content check: PASS.
- **Seen in play.** The bag's Chests tab; the pouch's card (Tier 1 80%, Tier 2 20%) and its toast; the crate's card (Low 100%, Mid 25%, High 2%) and "8 Low stones"; the case's card (Rare 1% above Epic 0.3%) and "3 Uncommon emblems"; the Combine pill. Research's pass hasn't run; the director hasn't accepted.
- **For research:**
  - An elite's case and a keeper's first-win case share the name "Emblem Case of <ground>" with different odds.
  - The card's kind line says "Chest" for a pouch and a crate too.
  - Socketing jewels isn't in the block: a pouch only fills the bag.

## TR57. The Broadcast, with firsts (research's request, tier 2, for Faber)

Research, 2026-11-24, from the cloud. Launch-design's items 6 and 10. The design: `docs/design.md`, "Being seen" (the Broadcast, its words, firsts). The numbers: `tools/balance/seeds.json`, "broadcast".

- **Feel line.** A player walking home from a run sees "Mara found a Legendary Sword" rise in its gold where the target's card sat, holds it for a breath, and wants to be the next name. It never lands over their own fight or reveal.
- **The facts it rests on** (SOURCED, Roblox's creator-docs, `MessagingService.yaml` and `TextChannel.yaml`):
  - a message is at most 1 kB; a server sends 600 + 240 × players a minute; a topic receives 40 + 80 × servers a minute; delivery is best effort, "typically within 1-2 seconds";
  - `TextChannel:DisplaySystemMessage` runs only on the client, and its text isn't filtered or localized, so it carries only our own words and the display name.
  - Rich text in a system line: UNVERIFIED. If the chat window doesn't draw a colour tag, the line goes plain.
- **In the block:**
  - `Rules.Broadcast`, pure: the reach for each event (seeds' lists); the per-player every-server throttle, where a throttled line falls to this server; the bundle; the client's queue (hold, gap, stale, friends first); the ids-only message and building the line from them.
  - The service: a RemoteEvent for this server, one MessagingService topic for every server, and its own server's lines taken from the topic only once (ids deduped).
  - The plate in the target's card's place, a grey block. Its look follows research's verdict.
  - The chat's system line, and the two settings.
  - **Firsts:** the account's first item of each rarity from Rare up plays the full reveal inside Open all, with "First {rarity}". The save keeps the rarities seen.
- **Waits:** the news board (TR58); the plate's art (Modulo, if the verdict calls for it); a sound for the plate (Sonus, one quiet cue, the director's ear).
- **Cases, one a rule:** each event's reach; a bought, failed or typed thing never told; the throttle falling to this server; a bundle every 5 s at most; the queue holding behind a card, a ring, a reveal and a screen; a stale line chat-only; a repeated id shown once; the message under 1 kB at its fullest; a first shown once per rarity per account.
- **Checks:** the content check passed the words on 2026-11-24, after one change ("found {voidkin} in a shard", not "broke open"), and a case keeps the line to our words, ids and the display name, since `DisplaySystemMessage` isn't filtered; a take with two Studio test servers, if Studio can run them, else two players in one; research's verdict in motion.
- **Order:** after TR56 and the open pieces.
- **Research's verdict on the block, 2026-11-26, 01:35,** from `build/captures/tr57/` at 568×320: it passes as a block. The plate says who found what in two lines, with the rarity lit, in the target card's place, and keeps to the band between the lead's card and the pills (Faber's fix, 25510ee0). The chat draws the colour tag.
  - **Must-fix (contrast; class: every rarity word on a dark panel):** the Common grey is dim on the chat's panel. The chat takes the bag's lifted rarity words (#B9BDC6 for Common; Faber's tier 1 of 2026-11-25), from the same table.

### The plate's cue (research, 2026-11-26, 12:19, for Sonus; TR64's rules)

The plate passed as a block at 01:35, and its timing is set in code: a 0.2 s fade-in, a 4 s hold, at most one every 20 s (`Config.Broadcast.Plate`, `BroadcastController`). AR62's restyle changes its colours, not its timing, so the cue can be picked now. It needs no conductor, because the plate's own queue already waits out fights, rings, reveals and screens.

| Cue | Plays on | Longest | Words | Never |
|---|---|---|---|---|
| BroadcastPlate, tonal | the plate's fade-in, one sound for every rarity. Never on a chat-only line (stale or past the cap), and never with "Show others' finds" off | 0.8 s | "notification chime", "soft chime", "message chime", "gentle bell", "glass notification" | your own find: someone else's find must never sound like your ShardDrop or a reveal, so no bright bell on the drop's notes; a fanfare, coins, a voice; a phone's, a console's or an app's own alert |

- **Level:** quiet, under the mix chart's UI line (−12 against the lead's light hit). It's news from elsewhere, heard about three times a minute at most. Tuned live.
- **Faber's part,** about 30 min, with TR64's hooks: the plate calls `BroadcastPlate` by name and stays silent until a pick is made. Its panel tab gets **Play the moment**, which raises a made-up plate ("glocen found a Legendary Sword").
- **Cases:** no pick means silence and no error; a chat-only line plays nothing; the setting off plays nothing.
- **The listen:** in the same sitting as TR64's, right after ShardDrop, so the director hears the two side by side.

### The shortlist, in the place (Sonus, 2026-11-26, the finder done at 12:28, the cut by 12:30 by the clock)

- **Shortlisted, 5** of the finder's 20 (217 found; 56 left out by it, 53 too long): VE Notification Chime, Notification Chime 3, ProSoundEffects' Zap High Pitch Glassy Reversed Whoosh 8, success (VINTAMOU), maybe notify mini.
- **Out by title:** UI clicks and objects (two GUI Close, Enable, Switch On, a sonar ping); other works and games (Pls Donate, TF2, Banban); a reveal (KKC Reveal Dupe); another tab's sound (Nice Bell 2 is ShardDrop's, so a bell reads as your own drop; an Upgrade is Reinforced's, a success GoalDone's); titles that say nothing (two `copy_` names, rblxpec-done). Thin by the library, so a "none" means new words, not a patch.
- **For Faber's review:** the data in `Config/Audition.luau`, this entry's commit: the tab after ShardDrop, its level −14 (a seed under the UI line). **Loaded:** `ServerStorage.NL_Audition` (the whole 20 in `Untrimmed`), kept by Faber's end-of-turn save. **Heard, picked:** no; in TR64's sitting, after ShardDrop.

- **Faber, 2026-11-26, 12:50 by the clock (d9038cd0):** the hook is in. The plate's fade-in calls `BroadcastPlate` for someone else's line while others' finds show (`Rules.Broadcast.Chimes`). A player's own line stays silent, since their find already sounded its drop and reveal (tier 1). Play the moment lays a made-up Legendary Sword line, kept out of the chat. Logic case 4 checks; Studio "Broadcast (TR57)" 27/0 at 60 fps. Sonus's tab reviewed: it passes (its name is the cue's, −14 dB under the UI line). `NL_Audition` saved with the place (version 1311).

- **Sonus, 2026-11-26, 20:52 by the clock:** the plate's pick, unheard, on the director's word of 20:48 (TR42, "The picks, unheard"): ProSoundEffects' "Zap High Pitch Glassy Reversed Whoosh 8", the one of the five that is neither a bell nor an alert, at its matched level with Gain 1.0. For Faber's install.

## TR59. The welcome week and codes (research's request, tier 2, for Faber)

Research, 2026-11-24, from the cloud. Launch-design's item 8. The design: `docs/design.md`, "The welcome week and codes". The numbers: seeds, "welcomeWeek" and "codes".

- **Feel lines.** On day 2 a player opens Home, sees yesterday's crate taken and today's Emblem Case lit, with Lyric's face waiting at the row's end, and taps it before anything else. A player types a code from the game's page and the crate lands in the bag with its line.
- **In the block:**
  - `Rules.Welcome`, pure: the day count by UTC days played, a claim, a repeat claim paying once, day 7's Lyric as a new Voidkin or a copy;
  - the row of seven on Home's Today card from the end of the first run, a grey block;
  - `Rules.Codes`, pure: a code's match (any case), once per account, the end date, the wrong-try limit; the list in Config;
  - the code field in Settings with its five lines; the gifts through the chests' grant (TR56), one transaction each.
- **Waits:** the row's art, after research's verdict; the first code's gift and end date, at the first update; where codes are posted (the director).
- **Cases:** each day's gift; a missed day waiting; a repeated claim paying once; Lyric owned and not; a code taken twice, ended, wrong, the sixth wrong try in a minute; no gift of Credits or of anything the store sells.
- **Checks:** the content check passed the lines on 2026-11-24. No code is ever put behind a like, a favourite, a group join or a follow until that has been checked against Roblox's rules (the director's, with where codes are posted). Research's verdict on Home's row.
- **Order:** after TR56, whose case, pouch and crate it grants.
- **Research's verdict on the blocks, 2026-11-26, 01:35,** from `build/captures/tr59/` at 568×320: the week's row reads (today lit, day 1 taken, Lyric's face at day 7), and the codes card works. Three must-fixes:
  - **The taken day (class: every taken tile):** the check stands over the item's words ("Fo✓ Crate"). A taken day shows the check alone on a dimmed tile, and its words go.
  - **The list over the return card (class: a panel over the card):** while the Today list is open, the return card waits hidden, and it comes back when the list closes.
  - **The codes card (class: colour and size):** the card shrinks to its content (the field, Take and the footnote), with no empty middle. The field takes the kit's neutral glass, not violet: the director has called the game too purple six times. AR62's style frame restyles it later.
- **Faber, 2026-11-26, 12:50 by the clock:** the three must-fixes pass in Studio: "Welcome week (TR59)" 34/0, "Codes (TR59)" 28/0, at 60 fps. Their retake for research's look isn't taken yet.

## TR60. The capture after a reveal (research's request, tier 1 for the capture, tier 2 for its tile; for Faber)

Research, 2026-11-24, from the cloud. Launch-design's item 9, the north star's "a screenshot of a reveal looks like an advert". The design: `docs/design.md`, "Being seen" (the capture).

- **Feel line.** A player's first Lyric lands in the Breaker's light, they tap the small camera at the card's corner, and their phone's share sheet opens on that frame.
- **The facts** (SOURCED, creator-docs, `CaptureService.yaml`): a client-side service; `TakeScreenshotCaptureAsync(onCaptureReady, captureParams)` leaves the UI out by default (`Enum.UICaptureMode.None`); `PromptShareCapture(content, launchData, …)` opens the device's share sheet with an invite link to the game where supported, and offers a download where not; `PromptSaveCapturesToGallery` saves to the game's Captures gallery. Age or platform limits: none stated (UNVERIFIED).
- **In the block:** the tile on the reveal's card while it holds; the HUD hidden for the frame while the card stays in, the capture taken with the UI the card needs; the share prompt; `launchData` carrying only the sharer's UserId, counted by `FunnelService` and never rewarded.
- **Waits:** the tile's icon (Modulo).
- **Cases:** the tile only while a card holds; the launch data's shape.
- **Checks:** a capture taken on a phone in a test place; research's look at the picture it makes.
- **Order:** after TR57.
- **Faber, 2026-11-26, 12:50 by the clock (d9038cd0):** "Reveal: TR60" 24/0 at 59 fps (its own file, `CaptureCases.luau`): the tile's size and place, its own press, and a take that leaves only the world's and the overlay's layers on, then puts each back. Real presses in Studio: the tile opens Roblox's share sheet on the frame (seen on the screen; Studio's own capture doesn't draw the sheet), and a press on the plate continues. The phone check waits, since the director can't run phone sessions (2026-11-26).

## TR62. Bringing a friend: the invite and its earned gift (research's request, tier 2, for Faber)

Research, 2026-11-24, from the cloud. The design: `docs/design.md`, "Being seen", "Bringing a friend". The seed: `tools/balance/seeds.json`, "referral". Roblox's side: `docs/roblox-rules.md`, "Rewards for engagement, invites and notifications".

- **Feel line:** the player beats the Lamplighter for the first time, presses "Bring a friend" on the results card, and a quarter of an hour later the friend's first clear drops a Forge Crate into both their bags, with a line naming the other.
- **The facts** (SOURCED, creator-docs, "Friend referral system" and "Player invite prompts"):
  - `Player:GetJoinData().ReferredByPlayerId` is filled for every kind of invite;
  - the invite opens with `SocialService:PromptGameInvite`, after `CanSendGameInviteAsync`;
  - the page's own safeguards are a one-time reward per invitee, and a limit per inviter.
- **The block:**
  - `Rules.Referral`, pure: whether a join pays, from the profile's state (new this session, never paid, not self), the inviter's count, and the first Normal clear;
  - the service: the friend's crate at their first Normal clear, granted through TR56's grants;
  - the inviter's crate written as one step on their profile, waiting for an inviter who isn't in this server. ProfileStore's own message to a profile is Faber's call;
  - the tile on Home's Today card, and the press on the first clear's results card, in grey;
  - the lines as design.md words them.
- **Waits:** the tile's art (Modulo, with AR53's card); the banner, which the director sets in the Creator Dashboard before the game is public (its length and what it shows past the limit, UNVERIFIED).
- **Cases:**
  - an invited new account pays both sides once, at its first Normal clear, and never again;
  - a join without an invite, an account that played before, and a self-invite pay nothing;
  - the inviter's sixth friend pays the friend and not the inviter;
  - an inviter away from the server gets the crate at the next join, once;
  - a repeat or interrupted grant never pays twice (`AGENTS.md`, "Data and code").
- **Checks:** the content check passed on 2026-11-24 after one round (the tile's and the banner's lines now say every condition). Order: after TR56 and TR59.

## TR63. Verdicts in pairs: the pair sheet, the lint's contrast and tokens, and SVG by browser (research's request, for Faber)

**Why:** the director's word of 2026-11-24, 20:50 (`docs/decisions.md`, the top row; `AGENTS.md`, "target first, verdicts in pairs"). Every look is judged beside its picked target, and machines check what eyes tire of (`docs/research/quality-and-speed.md`, changes 3 and 7). Faber's tools, Faber's way: this entry says what each serves.
1. **The pair sheet,** one step after `tools/capture/grab.ps1` and `tools/capture/moments.py`. Given the build's images and the target's, it makes one image:
   - both at the same phone size, side by side, in both orders (build then target, target then build), so neither is always seen first;
   - under them, the same pair blurred to thumbnail sharpness (the squint), and the same pair in greyscale;
   - for a character or a key pose, each as a black silhouette at 64 px.
   Free tools already on the PC, nothing new installed. Cases: two sizes scaled to one height; a missing file named; the order swapped.
2. **The lint reads contrast and, after AR62's pick, the tokens.** In `src/client/Controllers/Core/SelfTestController/UiLint.luau`, which already checks fit, size, touch, safe areas, overlap and the thumbs:
   - **Contrast, now:** each visible label's text against the colour behind it is at least 4.5:1 (WCAG's ratio), and at least 3:1 for large text (18 pt, or 14 pt bold).
   - **Tokens, after AR62's pick:** every colour, stroke width and corner radius on a visible piece is one of the style frame's tokens in `src/client/UI/Theme.luau`. Research's count today: 39 distinct colours written across `src/client`, and 18 files outside `Theme.luau` that write their own. The lint names each stray, so a screen at a time moves onto the tokens.
3. **SVG by browser: done by research, 21:08.** Edge isn't installed in its usual place. Chrome headless rendered a framed panel with an outer glow at 20:51: transparent outside, the glow soft past the box, the stroke crisp, about 1 s (VERIFIED). The command is `chrome.exe --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 --window-size=W,H --user-data-dir=<scratch> --screenshot=<png> file:///<svg>`. Nothing installed. Nothing for Faber.
- **Order:** 1 first, needed by every review; 2's contrast with it; 2's tokens after AR62's pick.
- **Checks:** no text players see, so no content check. Cases as above, and the lint's new checks on a made-up screen with one stray colour and one low-contrast label.
- **Faber, 2026-11-24, 23:46 by the clock: items 1 and 2's contrast done; the tokens wait on AR62's pick.**
  - **1, `tools/capture/pairs.py`:** `py tools/capture/pairs.py <build> <target> <out.png> [--height 720] [--thumb 96] [--silhouette] [--key colour:sim]`. Its rows: the pair, the pair swapped, the squint, greyscale, and with `--silhouette` black shapes at 64 px (from alpha, or a key colour). It writes `<out>.txt`, the key. ffmpeg only. `--cases`: 13 passed.
  - **2, contrast in `UiLint`, checked in every `lintClean`:** each shown label against what's drawn under its middle, read down the engine's own stack (`GetGuiObjectsAtPosition`, across ScreenGuis); 4.5:1, or 3:1 for large text.
    - A gradient is read at that point, and a stroke counts.
    - A glass covering half the world or more is judged over a black world and a white one.
    - A shadow under the same words is skipped.
    - Art, viewports, gradient lettering and the bare world are counted unread, with why, never passed or failed.
    - Its own case on a made-up screen: 20 passed.
  - **What it reads today** (the full suite, 23:40): 1,647 labels in 69 checks, 1,529 unread, 1,527 of them on art (the kit's image plates). So it reads 7%. To read art, a table of each kit piece's own fill, keyed by the `Kit` attribute, times its tint: about 2 to 3 hours, after AR62 if research wants it.
  - **One stray, real:** the item card's rarity word on the smallest phone, `CardRoom.Card.Rarity`, 4.35:1 < 4.5. On the card's violet top (#4C3E92), Common reads 3.32, Rare 4.07, Epic 4.12. The Items page (TR28) case fails on it until the card's colours change (AR62's, or research's call).
  - **The suite, 23:40:** 4,215 passed, 7 failed. Besides the stray:
    - the machine plate's "this window" (the window's size, as before);
    - the Dasher's lunge (AR52), a different check each run: flaky, mine to fix;
    - AR12's Electricity ink and the HUD's battery: the save's four bays are empty, so generation is 0. The pill wears its warning, and past 100 kWh its readout drops the decimals the case compares to ±0.05. Both cases lean on the save's state: mine to harden next, and to find which case left the bays empty.

## TR64. The silent big moments get a sound (research's request, tier 2: Sonus's shortlists, then Faber's hooks; the director's ear picks)

Research, 2026-11-26, 00:42, from the outside study (`docs/research/cloud-2026-11-24/orchestration.md`, "Sound inverts importance" and its next steps' item 2; `audio-direction.md`, section 4). A Shade's hit has a cue, but the run's biggest moments have none, and the keeper's fall borrows a Shade's `ShadeBurst`. Checked in code at 00:40: no cue on any of them (`Config.Cues`, `Config.Sounds`, `LandingController`'s "No sound yet").

- **First in Sonus's queue item 3,** because these moments play in every session today. The named requests' sounds (AR53, AR55 to AR58, TR57) wait on looks still in build, and a cue is picked on its finished moment.
- **Feel line:** the player levels up, lands a shard, fells the keeper, and each sounds bigger than a hit, in one glass-and-bell family, so the run's big moments are heard before they're read.
- **The cues,** in order. Each is one finished library sound, whole (TR42's rules). "Tonal" is the panel's flag: a single tone or chime is what it wants.

Round 1, the first session's:

| Cue | Plays on | Longest | Words | Never |
|---|---|---|---|---|
| LevelUp, tonal | the lead's level-up: the plate and the column (`UI/LevelNotice.luau`) | 1.0 s | "level up", "power up chime", "achievement chime", "magic chime", "rising chime" | a chiptune jingle, a brass fanfare, coins, a voice |
| ShardDrop, tonal | a shard's plate at its drop. Pitched by grade on the note set: Standard 1, Enriched 1.189, Prismatic 1.335, Named 1.498 (A C D E). G and the octave stay the reveal's, so a drop never sounds like a Legendary | 1.0 s, to its ring 45 dB down (the finder's measure; Sonus, 01:51) | "crystal ding", "glass chime", "bell ding", "chime single", "sparkle ding" | coins, a slot machine, more than one note |
| KeeperFall | the keeper's fall, on the frame that plays `ShadeBurst` today (keepers only), before the 2.4 s pause | 2.0 s, its tail under 1.5 | "boss defeated", "victory impact", "gong hit", "big impact", "shatter" | a fanfare or any tune, a crowd, a trailer braam or choir, a boom that lives under 120 Hz |
| LeadDown | the lead falls: the grey column and the fallen card | 1.5 s | "defeat", "power down", "fail", "lose", "shutdown" | a comic fail horn, a buzzer, a voice, chiptune |

Round 2:

| Cue | Plays on | Longest | Words | Never |
|---|---|---|---|---|
| GoalDone, tonal | a goal completes; in a fight, when the fight ends (`Theme.Time.Fight` after the last hit) | 0.8 s | "quest complete", "achievement", "success chime", "task complete", "bell chime" | a fanfare, coins |
| Record, tonal | "a new best" (`StageScreen`) and "A new record" (`TowerScreen`). Heard right after GoalDone, so the two sound like one family | 1.0 s | "new record", "achievement unlocked", "victory chime", "success" | a tune, a crowd |
| Reinforced, tonal | "Reinforced to +N" (`EquipmentScreen/Reinforce.luau`) | 0.8 s | "upgrade", "enchant", "forge success", "power up chime" | a jackpot, coins |
| ReinforceFailed | "Failed: it stays at +N". Quiet: a let-down, never a punishment | 0.6 s | "fail", "error low", "crack", "negative" | a buzzer, a loud shatter, a comic sound |
| MachineStage | a machine's stage climbs: the Climbing Ring (`LandingController`) | 1.5 s | "power up", "charge up", "energy rise", "magic charge" | a real machine: a breaker's clack, a motor, an alarm (the base's machines are void machines) |
| LeadHurt | a hit that jolts the lead (`Config.Combat.Shake.Hurt`, 10% of its health in one hit), never every hit | 0.4 s | "body hit", "low impact", "damage hit", "thud" | wet or tearing (rule 4), a voice or grunt, a refusal's sound |

- **LeadHurt is last:** it's an impact, the family the team failed twice (AR39), and it repeats in a fight.
- **Levels** start at the study's mix chart (Reward −6 dB, UI −12, against the lead's light hit at 0) and are tuned live.
- **Faber's part,** about 3 h (the study's estimate): each moment calls its cue by name, silent until one is picked. The panel gets a tab per cue with **Play the moment**, which fires that moment without a fight (the plate, the column, the fall), so the director hears each sound on its own picture.
- **Cases:** a cue with no pick stays silent and never errors; the keeper's fall plays KeeperFall and not `ShadeBurst`; LeadHurt plays only on a jolting hit; a drop's note follows its grade.
- **Waits:** the conductor (the study's item 4: one door for notices, the hold in a fight); the reveal's ladder retuned to the note set; the UI family (tap, tab, confirm, refused); each named request's own sounds.

### The shortlists, in the place (Sonus, 2026-11-26, 01:34 to 01:47 by the clock)

- **Shortlisted, cut by title as TR42's:** LevelUp 6, ShardDrop 5, KeeperFall 5, LeadDown 5, GoalDone 7, Record 8, Reinforced 6, ReinforceFailed 6, MachineStage 8, LeadHurt 5. No sound sits in two tabs: the one "Upgrade" both found is Reinforced's.
- **Out:** other works and other Roblox games (TF2's kill sounds, Steam's, Xbox's and Windows' sounds, Apple Pay, Mario, Pikmin, Black Ops, Dragon Ball, Jujutsu Kaisen, Madoka, OFF, Undertale, Portal, Hytale, Rec Room, Pls Donate); a real product's chime (a Tesla's, a Honda's) or an object (a gas pump's bell, a crossing bell, a train whistle, splashes, a mug, egg cracks); a pack's numbered files and a commercial library's rip; buzzers; voice memos; titles that say nothing.
- **Changed from the table, with the evidence** (`Config.Audition`): ShardDrop measures to 1.0 s, as the finder counts a ring until it's 45 dB down (at 0.6, "crystal ding" and "sparkle ding" kept none); KeeperFall adds "crystal shatter", "magic shatter" and "anime shatter" (research's five kept 4); GoalDone drops "achievement" (consoles' sounds) for "goal complete", "mission complete" and "objective complete", which found little more. Its seven are its own three and four of Record's "success" finds that Record didn't keep, measured at GoalDone's length and level.
- **Thin by the library, for the director's ear to judge:** KeeperFall's five are two glass shatters, a glass crash and two generic "boss defeated" sounds, so a "none" there means new words, not a patch. ShardDrop's are bells and dings, one note each by their titles.
- **Where:** `ServerStorage.NL_Audition` (`Candidates`, and `Untrimmed` with every run's whole answer), unsaved: Faber's next save keeps them. **Loaded:** the panel's tabs, at the next Play. **Heard, picked:** no; the listen waits on Faber's Play the moment.

### The picks, unheard (Sonus, 2026-11-26, 20:52 by the clock)

- On the director's word of 20:48 (TR42, "The picks, unheard"), one a tab: level up "Level-Up" (NexsusM1); shard drop "Nice Bell 2" (YoLiohcnj64); keeper's fall "glass shattering breaking" (killerguest7964); lead down "Failure1" (schmumkin); goal done "quest complete" (NexsusM1); new record "SuccessSfx" (proxyprevails); reinforced "Upgrade Complete" (EJGamerz5910); reinforce failed "Roblox GUI - Negative" (Roblox); machine stage "power up 1" (AwakenThePotential); lead hurt "Body Hits 8" (ProSoundEffects). For Faber's install, as TR42's. **Heard:** no, the director in play.

## TR65. The guide's arrows, in the tutorial only (the director's word, 2026-11-26; for Faber)

- **The word:** "those purple arrows are so stupid should only be there for a tutorial" (`docs/decisions.md`, 2026-11-26).
- **What changes:** `Guide` draws its chevron and its edge arrow only until the player beats their first keeper. That's the tutorial, by research's reading, and the same line `Combat.Home.FirstFallen` uses. After it, `Guide.Point` draws nothing, whatever `Rules.Hud.NextStep` says. The HUD's next-step line stays as it is.
- **"Go to the Tower" teleports** (the director, 2026-11-26, by 13:24: "go to the tower is simply a teleport duh it directly teleport to the tower"). Today it closes the panel and points an errand arrow at the ring (`ModeController.luau`, 47 to 56). Now the button puts the avatar, and the lead with it, at their own Tower ring, facing it. The errand and its arrow go. How it lands is Faber's call, tuned by playing.
- **Cases:**
  - a profile before its first keeper's win shows the chevron on its step, as today;
  - the same profile after the win, with shards ready, shows no chevron and no edge arrow, and its line still reads "N ready: open them at the Breaker".
  - "Go to the Tower" puts the avatar at its own ring, and draws no arrow.
- **Check:** a capture at the smallest phone, in the yard, after the win, with shards ready: no purple mark in the world.
- **Faber, 2026-11-26, 15:03:** implemented. The guide draws only until the first keeper falls, and "Go to the Tower" teleports. Tested: its cases pass in Studio (the 14:33 suite). The phone capture after the win isn't taken yet. Not visually reviewed, not accepted.

## TR66. The Gemini blueprint's findings that hold (research, 2026-11-26, 12:30; Faber's calls)

From the director's paste of 2026-11-26 (the register). Each claim was checked against the code at HEAD. Below are only those that hold, with what research asks. Each is Faber's call unless it's marked.

| # | Finding | Label | Ask |
|---|---|---|---|
| 1 | The self-test's case modules, 27,395 lines, are required as the module loads, before its `IsStudio` gate (`SelfTestController/init.luau`, 24-40 and 359), so they load on every player's phone | VERIFIED (read) | require them inside the gate, or move them to a dev-only project |
| 2 | A first join shows Roblox's default loading screen: `Arrival.client.luau` (14-19) removes it only after a teleport | VERIFIED (read) | our own arrival on every join, a plain fade until AR62 gives it a look |
| 3 | The Jewels page tells players "Jewels are set here in a later update" and "a jewel of its colour" (`EquipmentScreen/Jewels.luau`, 25 and 61-72). Jewels are at launch (2026-11-17, 02:40), and players read American spelling (2026-11-17, 13:15) | VERIFIED (read) | "color" now; the page is built before any public build and never shown as a promise |
| 4 | Poise shows on the stat sheet (`Rules/Sheet.luau`, 41), but nothing in the fight reads it (`Config/Stats.luau`, 96-98) | VERIFIED (read) | tier 2, research's call: hide the row until Stagger lands with the Lamplighter's fight (`docs/design.md`, "States in a fight") |
| 5 | Lifesteal's `PerSecondOfMaxHealth` is read by nothing, and the fight caps by `Cap × DamagePerSecondOfMaxHealth` (`FightService`, 1101) | VERIFIED (read) | keep one number and remove the dead one |
| 6 | The whole profile goes to the client after every change (`DataService`, 75-91) | VERIFIED (read) | measure its size and rate in a fight and in a break first, and send a patch only if it's large |
| 7 | `DebugCommand` is created on live servers, where nothing answers it (`Net`, 22 and 161; `DebugService`, 79) | VERIFIED (read) | don't create Studio-only remotes outside Studio |
| 8 | `build/handoff` is tracked: 2,206 files, 747 MB on disk, and the repo's packs are 837 MiB. GitHub's recommended maximum is 10 GB on disk, so there's no limit near; the cost is each pull's time as it grows | VERIFIED (sizes); SOURCED (docs.github.com, "Repository limits") | low: name what in it can be made again (previews, sheets) and stop tracking that from now on, with each maker's yes (tier 2). History is never rewritten |
| 9 | Nothing yet tells us where new players stop | research's add, tier 2 | before the first public build, log the first session's seven beats (`docs/north-star.md`) as an AnalyticsService funnel |
| 10 | 29 RenderStepped loops outside the tests and 27 CanvasGroups in the UI | VERIFIED (counts) | read the MicroProfiler and memory on the smallest phone before any refactor; split the big files only when a piece touches them |
| 11 | From the addendum (the director, 2026-11-26, by 13:06: "again disagree where u disagree and take what u like"): arrival banks the Condenser's stones but leaves its jewels for the tray's press, and the return card names only the stones (`Return.luau`, 117-131; `Base.luau`, 376-389). Jewels are at launch (2026-11-17) | VERIFIED (read) | arrival banks both, and the card says both |
| 12 | The attack clips blend in over 0.06 s (`Config/Animations.luau`: Combo, Swipe, Signature, Lunge), which softens the strike's first frames | UNVERIFIED as a gain: a test | try 0.02 on the attack clips live, tuned by playing, beside today's |
| 13 | A strike can feel floaty when its frames are spread evenly: Rook's jab takes 7 frames at 60 fps (`rook_clips.py`) | UNVERIFIED: an experiment | Modulo, after AR65's targets: one of Rook's combo hits retimed with a longer wind-up, a strike of 2 or 3 frames and a held pose, beside today's in the game. The director judges by eye. Only timing changes, not the rig |

**Corrected, no action:**
- Act has a rate limit (10 a second, a bucket per player: `Net`, 24 and 104-149).
- `Home.Fallen` 90 is the time to heal, not a wait.
- Elemental hits never crit by design (`Hit`, 133).
- The fourth chamber, ExistNo in blocks, and migration step 14 are in Faber's eight of 2026-11-25.
- There are 3 ProximityPrompts, not 21.
- Sound plays in 2 of the 62 UI files.
- MessagingService: a server sends 600 + 240 × players a minute, and a topic receives 40 + 80 × servers a minute (TR57).

- **Faber, 2026-11-26, 13:03 by the clock:**
  - **#1, done.** The 28 case modules are required inside `run()`, which only the Studio bridge reaches, so nothing loads them on a phone. On a live server, `SelfTestService.Init` also takes the controller's 42 children out of StarterPlayerScripts as it boots, before anyone joins, so none is sent. That's 1.4 MB of StarterPlayerScripts' 2.9, measured in the place. Tried on a copy of the place's scripts: 138 scripts to 96, the controller kept. Type check 0 new, logic 39,910. The self-test runs in my next Studio turn, since Scintilla holds it.
  - **#3, done for now.** "a jewel of its color". The page's "later update" line stays in the dev build only: jewels are in phase 3, before launch (`docs/production-plan.md`), so the page is built before any public build.
- **Faber, 2026-11-26, 15:03:** **#11, done** as its row says, with its cases (the 14:33 suite). Row 12 went into TR69 A.
- **Modulo, 2026-11-26, 16:42:** **#13, made, for Faber's live switch.** `RookComboSnap` (`build/handoff/Rook/clips/Rook_ComboSnap.json`; `rook_clips.py`, `ComboSnap`): Rook's jab retimed, nothing else.
  - Same poses and the same Hit1 at frame 12, so the combo's beats hold. The wind is reached at 9 (5 today), the strike takes 3 frames and speeds into the contact (7 today), and the hit is held to 18 (15 today) while the tape swings on. The hook's wind keeps frame 26.
  - Measured against today's Combo from the same run: frames 27 to 39 move by under a degree (Blender's auto handle at 26), and from 40 on they're identical. `Rook_Combo.json` beside it is that run's Combo, in place of the 11-12 copy named `Combo`. If the place's `RookCombo` is an older bake, bake this one too, so the two differ only in the jab.
  - The stepped sheet, every frame 0 to 26 from the game's camera: `build/scratch/modulo/tr66/tr66_jab_steps.png`. Content check: PASS at about 16:42, every pose being today's live clip's. The director judges it in the game, by eye. Not director-accepted.

## TR67. The Tower: a leave button with a confirm, and its two chat lines (the director's word, 2026-11-26; for Faber)

- **The words** (about 13:25, from a phone in the game): "the tower seems good but it need a leave button with confirm", and of the chat line "glocen reached floor 41, this server's best today": "so unnatural to say it a ai slop line".
- **The leave:**
  - During a run, a Leave button on the HUD opens a confirm: "Leave the Tower?", then "Your run ends at floor {N}, and you keep what it won", with two buttons, Leave and Stay. {N} is the last floor won, which `Rules.Tower.End` already grants.
  - No run should end by accident. A walk out of the room ends it today without asking, so Faber either holds the avatar in or asks the same question.
  - The look comes from the screens' kit until AR62's style frame is picked.
- **The lines** (`Rules/Broadcast.luau`, 383 and 385). The class is a qualifier tacked on after a comma; both of the Tower's lines have it:
  - the day's record: "{who} reached Tower floor {N}". It shows only when the run beats the server's best today, so the line needn't say so;
  - the week's lead: "{who} took first place in the Tower this week: floor {N}". No exclamation marks: the voice guide (`docs/research/cloud-2026-11-24/voice-and-naming.md`, section 5).
  - The other five lines read naturally and stay.
- **Cases:** the confirm's Stay keeps the run; Leave ends it at the last floor won, with its rewards; a walk to the room's edge doesn't end a run unasked; the two lines as written above (the Broadcast cases change with them).
- **Faber, 2026-11-26, 15:03:** implemented: the leave button and its confirm, and the two lines as written. Tested: the Tower and Broadcast cases pass in Studio (Broadcast re-run alone at 14:58, 27 of 27). Not visually reviewed, not accepted.

## TR68. The voice pass: the lines that read as generated (research's words, 2026-11-26; for Faber)

- **Why:** the director's "ai slop line" of 13:25 is the fifth such rejection. The fifteen weak lines found on 11-24 (`docs/research/cloud-2026-11-24/voice-and-naming.md`, section 3) were never changed. Research swept every line in `src/` today (614 unique strings) against the rule now in `docs/ui.md`, "Words players read". Item names and the word "Stretch" wait for their own pass.
- **The lines** (file and line at HEAD; `{…}` stays as it is in code):

| Where | Now | New |
|---|---|---|
| Rules/Broadcast.luau:383, 385 | "…reached Tower floor {N}!", "…took first place on this week's Tower: floor {N}!" | "{who} reached Tower floor {N}", "{who} took first place in the Tower this week: floor {N}" (no "!", the only ones in the game) |
| BreakerScreen.luau:868 | "Nothing waits. Shards drop on Lantern Row." | "No shards yet. Lantern Row drops them." |
| BreakerScreen.luau:935 | "No shard yet. They drop on Lantern Row." | "No shards yet. Lantern Row drops them." |
| BreakerScreen.luau:875, 879 | "It holds one Voidkin: no voltage", "Saves under a minute: not offered" | "This shard holds one Voidkin. It takes no voltage.", "Under a minute left. No voltage needed." |
| BreakerScreen.luau:877 | "Already broken: open it" | "Ready to open" |
| BreakerScreen.luau:881 | "Needs a battery of %s kWh: upgrade the base" | "Needs a %s kWh battery. Upgrade the base." |
| BaseController.luau:116, 117; VoidkinScreen/init.luau:108 | "The lead can't work too", "A worker can't lead too", "The lead fights: it can't be stationed" | "Your lead can't work a bay", "Take it out of its bay first", "Your lead can't work a bay" |
| BaseController.luau:121 | "It would save under a minute" | "Saves less than a minute" |
| BaseController.luau:123 | "The shares come to more than the whole" | "Over 100%. Lower one share." |
| BaseController.luau:124 | "That shard has moved on" | "That shard changed. Try again." |
| BaseController.luau:129; BaseView.luau:83 | "Raise the base's level first" | "Upgrade the base first" |
| BaseController.luau:131, 1165; Goals.luau:39 | "The Stone Condenser wakes at base level {n}", "Wakes at base level {n}", "…the Condenser wakes." | "The Stone Condenser turns on at base level {n}", "Turns on at base level {n}", "…the Condenser turns on." |
| BaseController.luau:132, 133 | "A convert is already under way", "Not enough stones in the bag for that convert" | "The Condenser is busy", "Not enough stones" |
| BaseController.luau:474, 504, 1243; BaseView.luau:229 | "Nobody works here", "Bay {n} · nobody works here", "Nobody on it" | "Empty", "Bay {n} · empty", "Empty" |
| BaseController.luau:481, 528 | "Bay {n}: who works?", "Who works?" | "Bay {n}: pick a worker", "Pick a worker" |
| BaseController.luau:495 | "First, choose" | "Pick a shard first" |
| BaseView.luau:73, 74 | "Stores the power nothing uses.", "Shows the power made against the power drawn." | "Stores spare power.", "Power made against power used." |
| BaseView.luau:84 | "It isn't awake yet" | "Not open yet" |
| BaseView.luau:221 | "Idle: no shard in" | "Empty" |
| PowerScreen.luau:394, 632 | "Demand over generation: the machines slow", "nothing draws now" | "Using more power than you make. Machines slow down.", "nothing uses power now" |
| StageScreen.luau:664; Rules/Sheet.luau:37 | "Hard: every foe is {n} levels higher", "chances against an even foe" | "Hard: enemies are {n} levels higher", "against an enemy of your level" |
| Rules/Home.luau:48 | "Not in a boss's arena" | "Not during a keeper fight" |
| Rules/Home.luau:63; Rules/Hud.luau:306 | "You're home", "At home" | "Back at your base", "At base" |
| VoidkinScreen/init.luau:107, 229; Config/Hud.luau:1591 | "Still healing at home", "Healing at home {t}", "Its Voidkin waits at home." | "Still healing at base", "Healing at base {t}", "Its Voidkin is at your base." |
| VoidkinScreen/init.luau:109, 235 | "Stationed: recall it first", "Stationed in {at}" | "Working in a bay. Take it out first.", "Working in {at}" |
| VoidkinScreen/init.luau:887 | "Its own name" | "Nickname" |
| VoidkinScreen/init.luau:907 | "Its moves come when it's built", "{n} hits in a string, again and again" | "Moves coming soon", "{n}-hit combo, repeating" |
| VoidkinScreen/init.luau:956 | "All {n} stars: a copy now sells for Credits" | "All {n} stars. Extra copies sell for Credits." |
| VoidkinScreen/Bag.luau:112; ShopScreen.luau:72 | "…salvage an item from its card to free a slot", "Your Inventory is full" | "Bag full. Salvage an item to free a slot." in both |
| VoidkinScreen/Bag.luau:122 | "It doesn't go there" | "Wrong slot" |
| VoidkinScreen/Bag.luau:1112 | "Salvage off: every item kept" | "Auto-salvage off" |
| ShopScreen.luau:245 | "{named} bought: it's in your Inventory" | "{named} bought. It's in your bag." |
| ShopScreen.luau:282 | "None this stock.\nWhen one is in,\nthe Shop's crown is lit." | "None in this stock.\nThe Shop's sign lights up\nwhen one comes in." |
| ShopScreen.luau:525 | "…in every server. Your counts are your own." | "…the same in every server. Each player has their own limit." |
| EquipmentScreen/Look.luau:209 | "It's at the most already" | "Already at max" |
| EquipmentScreen/Reinforce.luau:344 | "Every level is reached" | "Max level" |
| Emblems.luau:265; Look.luau:215 | "Legendary is the top" | "Already Legendary" |
| SettingsScreen.luau:159 | "Not saved: try again" | "Not saved. Try again." |
| Rules/Hud.luau:516, 559, 572, 574 | "{n} shards: into the Breaker", "{n} ready: open them at the Breaker", "Breaking: it opens at the Breaker", "Through the Door: {ground}" | "{n} shards to the Breaker", "{n} ready to open at the Breaker", "In the Breaker", "Go to {ground}" |
| Reveal/Plate.luau:65, 79 | "Your lead: it fights beside you", "Tap to continue" | "Your lead fights beside you", "Continue" |
| TowerScreen.luau:97 | "This Week's Climb" | "This week's climb" |

- **Cases:** the self-tests that assert these strings change with them. Nothing else changes.
- **Not in this pass:** "Stretch" in what players read, the Void Shop's name and the dock's Home (the director's), and the item names (their own pass).
- **Faber, 2026-11-26, 15:03:** every line in the table changed, with the self-tests that assert them. Tested: the 14:33 suite. Not visually reviewed, not accepted.

## TR69. The fight, overhauled (research, 2026-11-26, 14:15; overhaul 1 of `docs/production-plan.md`, "The overhaul"; for Faber)

- **Why** (`docs/research/cloud-2026-11-24/combat-agency.md` and `grounds-and-encounters.md`, MEASURED on our seeds):
  - the player decides nothing inside a fight;
  - 76% of what falls before the keeper is a Brawler, the same pack respawning on a 15 s timer;
  - a quarter to a third of stages 1 and 2 is standing still;
  - the Lamplighter repeats one move;
  - Hard is numbers.
- **Feel line:** your fighter's hits snap and stop for a beat; the street sends Shades in waves that each ask one thing; when one winds up, you call your fighter clear and punish the opening with its signature.
- **Five blocks, one at a time,** each about 90 minutes, each a playable block judged in play before the next. Every number below is a seed, exposed live (`NL_Debug` "Tune"). Each new rule gets its logic case in pure Luau.

**A. The hit** (levers: hitstop, anticipation, the shake saved):
- The attack clips' fade in at 0.02 beside today's 0.06, by a live switch. This is TR66 row 12, moved here.
- A critical's trauma drops from 0.35 to 0.15 (`Hitstop.Rungs`, From 4). The signature keeps 0.8, so the shake means something again.
- A pack's last fall holds 0.2 s (`Hitstop.Kill`, 0.13 today), and its drops leave together.
- A thin ring under the lead's target, in its type's colour, as a grey block. Scintilla gives it its look later.
- A 0.3 s glint on a Shade's mask before its ordinary swing.
- **Waits:** sound (the rising three, the chime), and Rook's retimed strike (TR66 row 13, Modulo's after AR65's targets).

**B. The street in waves** (in place of the respawn quota):
- A pack stop holds a list of waves.
  - The next wave steps out of the stall fronts 2.5 s after the last Shade falls, with a 1 s tell (in grey, a marker on the stall).
  - Each stage's waves add up to its quota of 10, so the loot's fit holds.
  - A stop whose list has run out starts again from its second wave, only while someone near still owes the quota. Nobody waits longer than the gap.
  - Each new Shade is met alone first.
- The lists (`Config.World.Row.Stops`):

| Stage, stop | Waves |
|---|---|
| 1, the pack | 3 Brawlers with their backs turned · 4 Brawlers, two from each side · 3 Brawlers of another type |
| 2, the pack | 1 Guard alone, facing the player · 2 Guards in front of 2 Brawlers · 3 Guards raising in turn, with 2 Brawlers |
| 3, the first pack | 1 Dasher alone, far up the street · 2 Brawlers in front, 1 Dasher behind |
| 3, the second pack | 2 Dashers from the two alleys, their lines crossing · 1 Guard in front of 1 Dasher, 2 Brawlers, the Support at the rear |

- **Each elite is its stage's role plus one move of its own,** built through `/ga-action`. Block clips come from today's clips retimed.
  - The Brawler's elite: every third swipe is an overhead, with a 1.2 s wind-up and a 1.5 s recovery.
  - The Guard's elite, in the square: a screen 8 studs wide, covering 2 Brawlers who join at its half health.
  - Stage 3's elite becomes the Dasher's, which is its stage's role (tier 2, research's seed): a fan of three lines, then 1.5 s out of breath. On Hard, the square keeps the Dasher's elite (AR57) and stage 3 takes the Brawler's.
  - **Feel line** (research, 2026-11-26, 22:05, tier 2): from the player's camera, each elite's one move announces itself a beat before it lands, so the player knows which elite it is and when to step away. The Brawler elite's overhead gathers over its head through the 1.2 s wind-up; the Dasher's three lines are drawn on the ground before it runs them; the Guard's screen stands as a wall you can see through. Every enemy tell speaks one language for "this will hit here", from a Shade to the keeper: warm, never purple, never confused with R4.
  - **The fan's geometry** (research, 22:15): three lanes from the Dasher's feet, the middle one at the lead and the others about 25° either side, drawn at once and run in one lunge.
- **Measure before and after,** from `StageBegin`: one clean Normal run in Studio, with each stage's seconds fighting, walking and standing.
  - **The gate:** under 20 s standing in the whole run.
  - Settling D2's "10 to 15 minutes" stays the director's.

**C. The press: slip, then strike** (`combat-agency.md`, section 4, with its rules and beats as written there). It's behind a switch, `Config.Combat.Hands`, Off by default.
- **Why the switch:** manual signatures are "Out of launch" [D] and the player steers by standing, so it's built beside today's and the director picks by playing. One sitting covers it, TR52 and TR44.
- **Call** is TR44's B, in every fight. A Call pressed inside a marked strike's tell is a slip.
  - A slip leaves the attacker Open for 2.0 s and puts 30% in the ring.
  - A signature that lands on an Open enemy is a Finisher: hitstop 0.18 s, trauma 0.8, and 30% of its cooldown back. It adds no damage.
- Auto, when on, waits 3 s for a thumb, then fires. Auto never Calls.
- **Words:** the button reads "Call". Open and the Finisher show no words: a cracked ring, then the hit.
- **The read-out** in each fight: Calls, strikes missed on purpose and by accident, taps, the seconds a full ring waited, damage taken, clear time.
- **The gates** are in the study's "How we'd know":
  - one press every 4 to 10 s;
  - misses on purpose are 70% or more of missed strikes;
  - hands finish stage 3 with 15 to 30% more of the bar than Auto;
  - Auto still clears Normal.

**D. The Lamplighter in three phases**, in grey on `Rules.Mark`'s circles and lines (`grounds-and-encounters.md`, section C's table). It's a signature piece, so it gets the time it needs.
- **Joining it:** AR7's staging and C4's ring.
- The fight runs about 65 s at Faber's measure, since each phase shows its idea twice (tier 2, research's; research's note of 19:33 below).
- It adds moves and block clips, not a new look.

**E. Hard changes behaviour:** one rule per role, as Hard rows in `Definitions/Enemies.luau`.
- Guards raise in turn.
- Dashers lunge twice.
- Two marks may be in flight where Normal allows one.
- The keeper's Hard rules are those in section C.

- **Not in this piece:** heal marks, and full health at a run's start (the director's health words); props on the Shade (the director's "stay as they are"); run modifiers; the cut-in; every finished look and sound.
- **Faber, 2026-11-26, 15:03:**
  - **A, built:** the fade switch (`Animations.Snap`, Off: 0.06, On: 0.02), the critical's trauma at 0.15, the pack's last fall held 0.2 s with its drops together, the target ring and the mask glint as grey blocks. Tested: "The hit (TR69 A)" passes in Studio, 21 of 21, and the Fight logic cases pass. Not yet judged in play.
  - **B, built Off** (`World.Row.Waves.On`, false until measured): `Rules/Waves.luau` (its 3 logic cases pass), the waves in `PackService` with their grey tells, and every wave's Def counted toward the quota. The measure is `PaceCases` (Manual): one clean Normal run, each stretch's seconds fighting, walking and standing. It runs in the Festival place, before (Off) and after (Tune On), in my next Studio turn.
- **Faber, 2026-11-26, 15:25:** **C, built Off** (`Config.Combat.Hands.On`, false until the director picks by playing; `Rules/Hands.luau`, its 4 logic cases pass). Call is TR44's button in every fight but the Tower's, by the jump, reading "Call". A Call in a marked strike's tell that then misses is a slip: the attacker is Open 2 s and staggered, its kind's share; the lead's ring fills 30% of its cooldown and its hold ends. A lead's signature on an Open foe, or breaking a Guard, is a Finisher: hitstop row 9 (0.18 s, trauma 0.8), a 1.5× throw, 30% of its cooldown back, no damage added. Auto, on, waits 3 s on a full ring. The read-out per fight (calls, misses on purpose and by accident, taps, seconds waited, damage taken, length) is `NL_Debug:Invoke("Hands")`; the switch is `("Hands", nil, true)`. In grey: the cracked ring, the lead's white flash on a slip, the screen's edge flash on a Finisher. Tested: "Hands (TR69 C)" passes in Studio, 21 of 21 (the switch on for the case only), and the logic tests pass in Studio, 40,169. Not judged in play, not accepted.
- **Faber, 2026-11-26, 15:54: B measured and On** (`World.Row.Waves.On`). One clean Normal run in the Festival place, lead level 26, before (Off) and after (On), standing in the whole run: **66.1 s Off, 14.5 s On** (the gate, under 20: PASS). By stretch: 33.7, 28 and 4.4 s Off; 7.4, 5.8 and 1.3 s On. Fighting goes from 45% to 70% of the run, which takes 144 s instead of 175 s.
  - **Built to the spec's "steps out":** a wave stood while someone near owes the quota goes for their leads, as a pack that was hit does (`FightService.Rouse`). The first On run stalled at stretch 3 for 349 s: the wave stood behind the player, outside the lead's view, and nobody came. The measure now turns the camera to the Shade it walks to, as a player looks at the fight; Off read 62.9 s on the old measure.
  - **Tested:** the new case "Waves (TR69 B): a wave stood while you owe the quota steps out at your lead" passes 10 of 10 in the Festival place (it stands 38 studs out, past the lead's leash, and all 4 Shades come); in a place without the street it notes and returns. Logic offline: 40,169 passed. Not yet: the elites' moves (`/ga-action`).
- **Faber, 2026-11-26, 19:30: D, built Off** (`Combat.Keeper.Phases.On`, false until judged in play; `KeeperPhaseService`, `Rules/Keeper.luau`, `Rules.Mark.Swept`; FightService's hazards, held turns and window). The three phases at section C's seeds, in grey: six posts round the ring, dark; at 70% the midpoint lights them one by one, untouchable; phase 2's pools go round the posts and its slam brings a second where the avatar stood, the window (Open, hits ×1.25) after it; at 35% the false ending, kneeling and dark, then relit; phase 3's two adds, its slam's tell run to 1.2 s, its sweep's line turning 120° in 1.6 s, the window after it. Slips (TR69 C) and the Under/Away modes read the hazards as marks.
  - **Tested:** "Keeper (TR69 D)" passes 23 of 23 in the main place (a FightSpawn'd lamplighter the phases adopt, as the main place has no ring); its 8 logic cases pass, and LogicTests 40,268 in Studio. The Shade cases and Hands (TR69 C) pass alone, twice each; run after the other Shade cases, the Guard's stagger and the Finisher's edge flash each failed once, an order dependence for the suite.
  - **Measured:** one phased fight, a level 26 lead kept whole, no presses: **44.0 s** from spawn to fall (phase 1 13.7 s, phase 2 17.5 s, phase 3 12.7 s), against section C's 80 s and the band's 45 to 75 s. A tier 2 number for research.
  - Not yet judged in play. A note for the judging: the window's stagger cuts the slam's follow-through clip short.
- **Research, 2026-11-26, 19:33, on Faber's two notes** (tier 2: research's number, Faber's code):
  - **The length:** my line "about 80 s, inside the band" contradicted itself, since the band tops at 75 s. A rule replaces the number: each phase shows its idea twice, once to read and once to answer. At the measured 44 s, phase 1 sees only one slam (the first at 8 s, then every 12 s). So phase 1 runs about 21 s, and phases 2 and 3 each show two double slams and two sweeps: about 65 s from spawn to fall at the same measure (a level 26 lead kept whole, no presses), under the band's 75 s top. Presses shorten it.
  - **The lever:** the keeper's health while phases are On (seed ×1.5, tuned live), not the windows, so a press pays the same. With phases Off, the 45 s it was solved for holds.
  - **The window:** in D the window is the follow-through held, the lantern stuck in the street (section C), so no stagger clip plays over it. Hits land ×1.25 on the held pose.
  - **Next:** Faber's measure at the new health, with each phase's count of its idea logged (slams, double slams, sweeps), then the judging in play.

**F. The contact in view, an experiment** (research, 2026-11-26, 17:10; Modulo's finding in AR66): a lead stands beyond an ordinary Shade, turned `Combat.Lead.Frame` (45°). From the player's camera the Shade is nearer, so every melee contact lands on its far side, out of view. Elites and keepers already take `Beside` (90°).
- **The experiment, a Studio turn after E:** one ordinary Shade fought with Rook and with Watt, at Frame 45 and with `Beside` 90 for every kind. Capture the hits at the phone's size from the player's camera, four frames each. Research picks in pairs: the contact seen, the lead's face seen, and the frame not crowded in a wave.
- Nothing changes before the pick. It's a seed, and the verdict of 2026-11-12 (TR2) was research's own.

**A's ring and glint, the targets** (Scintilla, 2026-11-26, 19:02; for research's pick in pairs). Painted on the street stage at the player's camera (the Festival place at night, the Brawler 26 studs up the street, Rook on it), beside today's grey blocks (R0, G0): `build/handoff/Fight/targets/` (peaks, strips with their frames, phone and squint sheets), by `tools/fx/fight_read_targets.py`.
- **The ring:** R1 the cut ring (four arcs, a white core and an ink hair, snapping in from 1.45 times over 8 frames, turning slowly); R2 the collar (a low upright wall of light, 0.55 studs, on a floor line); R3 the brackets (four corner ticks closing in over 8).
  - **Measured:** from this camera the bodies hide about two thirds of any ring at the foe's feet (shown against unhidden: R0 501 of 1,363 px, R1 423 of 1,304, R3 374 of 1,098). The player's own avatar and the lead stand in front.
  - **So R4, tier 2 for research to weigh:** a small cut chevron over the foe's head in R1's make, dropping in over 6 frames, never hidden (5,762 px).
- **The glint, from the swing's first frame:** G1 a four-point star at the mask's eye line (out in 2 frames, drawn back in by 18); G2 the mask lit, with a halo in its type's colour; G3 a thin ring running out from the mask over 14.
- **Content check: PASS** on all nine. For the build: G1 and G3 never together (a star inside a ring), and nothing star-like inside R1 or R3. The red stays light round the mask, never a tint painted on the face.
- Implemented as targets only; no build hour before the pick.

**Research's pick (Quaestor, 2026-11-26, 19:06): R4 and G1.** Read on `phone_ring_street/` and `phone_glint_street/` (peaks and squint), and on the peaks cropped round the foe, in both orders.

- **The mark, R4 (tier 2, dated here, research and Scintilla; Faber hooks it):** at the player's camera, every ring at the feet shows only an arc beside the foe, so R1 to R3 can't beat today's R0 there. R4's chevron over the head is never hidden and reads in both orders. It takes the ring's place: the lead's target is marked over its head, in its type's colour.
- **The glint, G1 over G2 and G3:** G1's star at the eye line reads at a glance as the glint before a strike. G2 reads as today's lit mask with a halo. G3's ring reads as a reticle (AR61's finding on rings), and it would sit round the same head as R4's mark.
- **For the build:** R4 and G1 on one foe at once are read together at the checkpoint, and R4 stays clear of any plate over a foe.
- **Next:** Scintilla builds both looks, and Faber hooks them into block A.

**R4 and G1, built as data** (Scintilla, 2026-11-26, 19:27; for Faber's review and hook). Five pictures drawn from the targets' own strokes and uploaded under the group (`docs/asset-log.md`). The mark is `Config.Effects.Mark`: its pictures, sizes, drop, bob and colours, for Faber's code in the ring's place. The star is `EffectRows/ShadeGlint.json`: two cards, played at the mask's eye line on the swing's first frame. Its type colour needs a `Tint` from its player: the row key and Rows' option are Faber's, and until then it plays the Brawler's red.
- **Content check: PASS**, on these conditions:
  - the star stays light, never a tint on the face, and never runs down;
  - the ink stays a hairline, never shown alone.
- **Tested:** the offline logic cases pass (40,335), and the type check finds 0 new. Not yet seen in play.
- **Faber's hook (2026-11-26, 19:46):** R4 is `FighterController/TargetMark`, in the ring's place: one BillboardGui of three layers, unlit and always on top, its apex Lift over the target's highest mask (else its head), dropping in on the Back Out, fading in, then bobbing. Its switch is `Combat.TargetMark.On`, and the ring's numbers are gone. G1 is `MaskGlint`: ShadeGlint played on the effects' clock at the mask's eye line, with the Shade's scale, in place of the emissive flare. Rows honour `Options.Tint` on a Tint row, the loader takes the key, and the Star row has it. Tested: "The hit (TR69 A)" passes 24 of 24, twice (the mark's colour, scale and place; the star at the eye line, in its colour, drawn and gone within 0.3 s). Not yet seen in play by eye: Scintilla's turn.
- **In play** (Scintilla, 2026-11-26, 19:51; for Faber and research's checkpoint). Seen on a level 70 brawler on the deck from the player's camera, both on one foe (`build/handoff/Fight/checkpoint/`; the take `ward/takes/tr69_mark_glint3.mkv`, scratch). Two must-fixes, both in the hook's placement:
  - **G1 is hidden by its own head.** A Shade faces your lead, so the camera mostly sees its back or side, and the star at the mask's front shows as a thin red line over the head with no white core (`R4_G1_in_play_today.png`, top rows). Tried live: pushed toward the camera by half the mask's larger side and 0.3 studs, it reads as the whole target from the side and the back (`G1_toward_camera_try.png`).
  - **The damage numbers stand on the mark** (research's condition): the white ones are born on the chevron, and a critical covers it whole for most of a second (`R4_G1_in_play_today.png`, rows 2 and 3; `R4_G1_in_play_4s.png`).
  - Otherwise the mark reads clearly: a red V with its white core, always on top. Its drop and bob aren't judged yet (one target, no stills of the motion).
- **Faber, 2026-11-26, 20:17: both must-fixes in the hook** (6c197133): the star stands toward the camera, past the mask's larger half side and 0.3 studs, and a target's numbers are born over its mark. **E built, and D's three follow-ups** (the numbers stay research's, tier 2):
  - **E:** one rule per role, as `Hard` rows in `Definitions/Enemies.luau`, through `Rules.Fight.MayStart` and `Again`. The mark token is `Combat.Turns.Marks` (Normal 1, Hard 2): a marked strike (a footprint or a line) waits while that many of the others' are in flight on its lead, from their start to their landing, and swings meanwhile. A Hard Guard raises only while no other Guard on its lead is raising. A Hard Dasher's lunge that ends starts a second at once, aimed afresh, while it holds its turn and the token allows. The keeper's Hard rules are section C's, built with D: posts two at a time, the sweep there and back, burning footprints, quicker tells. The turn cap stays 3.
  - **D:** the window is the held pose (`FightService.Window`): no stun and no stagger, the action's clock waits and then plays on, and the client holds the clip by `PinUntil`. The keeper's health is `Phases.Health` times its own (1.5) while phases are On (`FightService.Toughen`), given back as its run ends, so Off is the 45 s fight. The read-out counts each phase's landed slams, doubles and sweeps.
  - **Tested:** "Hard (TR69 E)" passes 10 of 10, twice: two Hard Guards never raise together, a Hard Dasher lunges twice in a run, two Normal Dashers never have two lines in flight. "Keeper (TR69 D)" passes 26 of 26: the pose held the window's length, not stunned; ×1.5 health, its own back when Off. "The hit (TR69 A)" passes 25 of 25 and "Shades (AR52)" 48 of 48. Logic: 40,355 offline and in Studio.
  - **Measured** (a level 26 lead kept whole, no presses): at ×1.5, **60.4 and 62.6 s**; at ×1.65, tried live, 61.8 s. Phase 1 reaches its line at about 16 s and turns at 18 to 19.5 s in every run; phase 2 lasts 19.5 to 22 s, phase 3 19 to 22 s. Counted, landed: phase 1, one slam every run; phase 2, one or two doubles; phase 3, two sweeps every run.
  - **For research:** phase 1 shows its slam once at each of these healths, since its second is due at 20 s. Three levers, each research's number: more health (estimated from the share's rate, not measured: about ×1.8 puts phase 1 past 21 s and the fight near 70 s), a larger share for phase 1 (`From[1]` 0.65), or its first slam sooner.
- **In play after the fixes** (Scintilla, 2026-11-26, 20:18; Faber's playtest of 20:15, two level 26 Brawlers, 9.6 s of take before the machine's low memory stopped the capture; `build/handoff/Fight/checkpoint/R4_G1_fixed_in_play.png`, `R4_fixed_crits_on_mark.png`):
  - **G1 fixed:** the star stands clear of the head, its white core and red fringe whole from the camera's side and back.
  - **R4's ordinary numbers fixed:** a number on the marked foe stands just over the mark (197, 879), touching it, never on it.
  - **Still open, a must-fix:** a critical still covers the mark for about a second (789 to 2,307 at the take's frames 150 to 206; 1,130 to 2,009 at 358 to 422). A critical's plate is several times an ordinary one's height; why its foot doesn't clear the mark is for Faber. A number born lower rises through the mark (98, frames 216 to 243, by its place the neighbouring foe's).
  - **Drop and bob:** at this camera the mark is about 25 px tall, its drop moves it about 8 px in 3 frames and its bob about 2 px: neither reads. Whether either should is research's call at the checkpoint.
  - **Faber, 20:23, the critical fixed:** the mark is a taken box for every number's placing (`TargetMark.Box`, the settled mark with its bob, in `Effects`' place), at every moment of its rise, so no number is placed on it, a neighbour's included. It's shrunk by the clear, so a number may touch it. Tested: "The hit (TR69 A)" 26 of 26, twice, with a new check: a critical born 0.2 s after an ordinary number lands clear of the mark.
  - **In play after 20:23** (Scintilla, 2026-11-26, 20:29; my take on the deck at 20:26, two level 70 Brawlers, criticals of 59 to 115; `build/handoff/Fight/checkpoint/R4_crits_swoosh_on_mark.png`, `R4_crits_after_box.png`). No number stands on the mark's middle now, and the ordinary ones are clear. **Still left:** a critical's orange brush reaches about a digit's width left of its digits and covers the mark's right wing for the number's whole life, so the mark reads as one red stroke into the number (take frames 70 to 142). The box counts the digits, not the brush, or the clear lets the brush in: Faber's.
  - **Faber, 20:42, Scintilla's take of 20:26 (a critical's brush on the mark's right wing):** reproduced in play with a probe, each frame, every number against the mark's drawn square, two level-matched Brawlers, the lead turning between them. Before: a critical's digits on the mark in 103 of 1,710 frames. The cause: a number on a Shade not yet marked was born at its head, so the mark dropped onto it when the lead turned there. Fixed:
    - every number on a Shade is born over where its mark would stand, marked or not (`TargetMark.Over`);
    - a critical's box for placing holds its brush as drawn, not its digits alone (`reach`).
    - After: a critical's digits on the mark in 1 of 1,391 frames, its brush in none. An ordinary number in 59 of 1,386: 29 inside the mark's drop after a target change, the rest touching by about 5 px.
    - Tested: "The hit (TR69 A)" 28 of 28, twice, with two new checks (the mark's reach the same marked or not, a number's foot over it); the numbers' flurry case 38 of 38. "Shades (AR52)" after them: 46 of 48, the Dasher's lunge missing the lead; that case alone 26 of 26, the suite's known order dependence (open).
  - **Scintilla, 21:03, in play after 20:42** (one Brawler, the combo replayed; `R4_after_2042_in_play.png` in `build/handoff/Fight/checkpoint/`):
    - Criticals (710, 1,130 and 848) sit beside or just under the mark, with its brush off it, in every frame read.
    - Ordinary numbers sometimes touch the mark's edge by a few pixels, which matches Faber's count.
- **Research, 2026-11-26, 20:18, the lever (tier 2: research's number, Faber's code): phase 1's first slam sooner while phased.**
  - **The seed:** `First` while phases are On, 2 s after the Challenge in place of 8. The slam's cooldown stays 12, and the health stays ×1.5. Its slams then land at about 3.5 and 15.5 s from spawn, both before the line at about 16 s. Off, 8 holds.
  - **Why not the other two:** more health lengthens every phase to fix one, and pushes the fight to about 70 s against the band's 75. A larger share for phase 1 is taken from phase 2, which already lands only one or two doubles. The slam is phase 1's idea, so meeting it early teaches it sooner.
  - **Accept:** two slams landed in phase 1 in every run, and the fight at 60 to 65 s at the same measure. If the second slam still meets the line, `First` goes to 1.
  - **One more measure, about survival:** run once with the lead not kept whole, the player stepping out of every ring, and give the lead's health at the keeper's fall. `docs/balance.md` wants about 30% for an on-budget lead with 2% lifesteal, a figure solved for 45 s, and the phased fight runs about 60. If it ends far lower, the keeper's attack while phased comes down beside `Health` (research's number, from that measure).
- **Research, 2026-11-26, 21:13, after Faber's six runs (one slam in phase 1 in all six, at `First` 2 and 1):** `First` goes to 0, Faber's proposal.
  - **Why:** the seed missed its own timings, since the keeper's opening swing holds the slam until about 3.3 to 5 s whatever `First` is above about 0.2. At 0, the slam is ready when the Challenge ends and takes the swing's place, so the slams land at about 3.5 and 15.5 s, the timings the seed meant.
  - **Accept:** unchanged: two slams in phase 1 in every run, the fight at 60 to 65 s.
  - **If the second still meets the turn,** the slam's cooldown while phased goes from 12 to 10, research's number, without another ask. Off, both stay as they are.
- **Faber, 2026-11-26, 21:33: `First` 0 and the phased cooldown 10 in** (`Combat.Keeper.Phases.First` and `.Cooldown`; `FightService` takes a fighter's own `Cooldowns` by action, which the phases set and clear).
  - **Measured** (three runs, as before): two slams in phase 1 in every run, both landing at 3.6 to 3.8 s and 14.8 to 15.1 s, before the turn at 17.6 to 20.7 s. The fights ran **64.6, 58.7 and 59.7 s**, so two runs are under 60 by 1.3 and 0.3 s. That's for research.
  - **Tested:** "Keeper (TR69 D)" 28 of 28, with a new check: the phased slam's cooldown is `Phases.Cooldown`. "element states (AR48)" 36 of 36.
- **Faber, 2026-11-26, 21:42, the survival run** (research passed D at 21:36). Phases On, First 0, cooldown 10. The lead was the test account's level 26 Rook (3,732 health; its build's share against budget not measured), not kept whole. A client driver walked the avatar out of every footprint on the lead, so mode A took the lead out.
  - **Every footprint missed:** 9 slams, 3 double slams' seconds, 4 sweeps (`Slam`'s counts). The lead ended at **99.4%**, lowest 96.7%: the keeper's ordinary swings barely mark it, against `docs/balance.md`'s about 30%.
  - **Stepping out costs time:** the fight ran **93.0 s** (phase 2 at 21.1 s, phase 3 at 53.3 s), against about 61 s kept whole, since the lead stands away for each tell. A first run, with the driver late on 5 of 7 slams, ran 74.7 s and ended at 100%.
  - That's for research: the keeper's attack, and the band measured with the player playing.
- **Research, 2026-11-26, 21:43, on the survival run:** no number moves yet, because the lead isn't known to be on budget.
  - **Why not yet:** a lead that ends at 100% even when 5 of 7 slams were met late is very likely far above budget for ground 1. Raising the keeper's attack against it would tune the fight to the wrong player.
  - **The band's measure, decided:** the band is held to the fight as it's meant to be played, the player stepping out of every tell, not to a lead kept whole. Its target for this keeper, at an on-budget lead, is 60 to 75 s (DESIGN; `docs/balance.md` gives keepers 45 to 75 s by ground, and phases add the tells).
  - **Survival targets, at an on-budget lead (DESIGN, research's tier 2):** stepping out of every tell, the lead ends at about 50 to 70%. Stepping out of none, it ends at about 10 to 35%, the stand-and-trade 30% of `docs/balance.md` less a little for the slams. So dodging is worth about a third of the health bar, and the ordinary swings still matter.
  - **Next (Faber):** first, the test lead's power as a share of ground 1's budget (`tools/balance/` or `Config`). Then the two runs, both with an on-budget lead: every tell stepped out of, and none. Each gives the length and the lead's health at the fall. The levers follow from those: `Health` for the length, and the split between the ordinary swing and the slam for survival.
- **Faber, 2026-11-26, 22:08, the on-budget runs** (research's 21:43 next):
  - **The test lead's share:** the level 26 Rook sits at about 11 to 18% of budget (`fighter_attr`, Common Warrior): Health 3,732 against 2,989 bare and 7,495 on budget, Attack 892 against 740 and 1,309, Defence 342 against 293 and 576. It's under budget, not over.
  - **Why 21:42's run ended at 100%: the base heals.** A lead on its owner's plot takes the home heal (`Fight.HomeRate`, `Combat.Lead.Home`), and that run, and the first two of this round, stood at the base. The runs below are on the test pad, off any plot.
  - **The runs:** the lead on `fighter_attr(9, 0.7)` (Health 1,852, Defence 152, 3% lifesteal, Regen 4) through a new lever, `FightSheet`, against the lamplighter at level 9 on Normal (13,407 health with phases), `First` 0, cooldown 10.
    - **Every tell stepped out of:** 6 slams, 1 pool and 2 of 3 sweeps missed (the driver was late on one). The fight ran **71.4 s** (phase 2 at 17.7, phase 3 at 37.4). The lead ended at **84.6%**.
    - **None stepped out of:** 4 slams, 2 sweeps and 2 pools, all hit. The fight ran **58.4 s** (phase 2 at 18.4, phase 3 at 38.4). The lead ended at **73.6%**.
  - **Where the damage comes from** (the Hit events on the lead):
    - Stepping out: 567 taken, of which 363 from swings, 174 from phase 3's Shades, 30 from the one sweep.
    - Standing: 804 taken, of which 407 from swings, 158 from Shades, 134 from slams (44.7 each, 2.4% of health) and 104 from KeeperLight (29.8 each).
    - Healed: about 280 and 315, Regen's bursts and lifesteal. Lifesteal counts damage dealt up to 8% of most health a second (`Config.Stats.Lifesteal`).
  - **Not a bug:** a slam's 44.7 is `Hit.Resolve`'s own figure: the keeper's Attack (3.15 a G, 6.98 at level 9) times 6.53, less 27% for the lead's Defence, plus its Fire.
  - **The lever, fixed on the way:** `FightSheet` first set the block once, and the save's sync after a hit's XP brought the lead's own block back after three hits. It now goes through `Reblock`, and every run held 1,852 throughout.
  - **For research, arithmetic, not measured:** the keeper's whole damage ×2, the healing and the lengths unchanged, gives about 54% stepping out and about 30% standing, both inside the targets. The tells are about a third of what standing takes, so the split can lean further toward the slam if stepping out should matter more. Faber reruns both on your numbers.

- **Research, 2026-11-26, 22:16, the split (research's tier 2):** at 22:08 the dodge gap is small (84.6% against 73.6%), so the tells carry more of it.
  - The keeper's ordinary swings ×2. Its tells (slam, sweep, pool and KeeperLight) ×3. Phase 3's Shades and Health stay as they are.
  - Arithmetic from 22:08's events, not measured: dodging ends at about 62% and standing at about 26%, a gap of about a third of the bar.
  - **Next (Faber):** the same two runs on the pad. The gates: 50 to 70% dodging, 10 to 35% standing, and 60 to 75 s dodging. If all three pass, the keeper's numbers close.

- **Research, 2026-11-26, 22:32, call (a), as sent:**
  > TR69 D: (a). The keeper is tuned to the on-budget lead, as `docs/balance.md` already has it ("Fights against the game", line 186): "Enemy health and attack are derived so an on-budget Common Warrior meets the targets ... a keeper in 45 to 75 s ... ending with about 30% health", and "A bare Voidkin ... can't beat a keeper." The 11-19 cases anchored on the bare lead, so the cases were off the design, not your split.
  > - **The form:** yours, the same net. The keeper's Kind Attack ×2 and the tells ×1.5 on top, with Hard's burning footprint as it is. The swing-rate rule then holds, re-anchored: the keeper's swing hits the same a second as the on-budget lead.
  > - **Reseed the cases to the doc:** keeperHpLoss 0.7 is measured on the on-budget Warrior standing. A new case: a bare own-level lead can't beat the keeper. The skull's 4 for a bare lead is right if the skull reads the lead's own power.
  > - **Your runs pass on the design's lead:** 29.7% standing, and 56.2% at 74.3 s for the clean dodger. [...] The gates hold to a clean dodger (about 10 s of walking or less) on the median of three runs. Tighten the driver to step to the tell's edge and back.
  > - **Check, report only:** do the ordinary Shade's and the elite's cases share the bare anchor? If they do, the whole street is about 2.4× soft against the design. That's TR69's street piece, decided there, not in this change.
  > - **The risk the cases can't show:** whether a fresh account holds anything near a 70% build when it reaches the Lamplighter. When you take TR69's clean Normal run from StageBegin, note the lead's budget share at the keeper.
- **Faber, 2026-11-26, 22:56, (a) in** (df8db9b1): the keeper's Kind Attack and Elemental Attack ×2, its tells ×1.5 on top (Slam 4.5, Pool 2.25, Sweep 3), and Hard's footprint halved to keep its damage. The cases are reseeded to the doc. The skull reads the lead's own power (`Stats.Resolve`), so a bare lead's 4 is in a case.
  - **Standing, on budget, three pad runs:** the lead ended at 38.7%, 15.8% and 25.8% (median 25.8%).
  - **Dodging:** the driver was tightened to one step per tell, to the mark's radius plus 5.5 and back. The lead clears every slam (12.0, 7.9 and 12.6 studs from centre against a radius of 5), with 5 s walking by the third slam. The clean runs weren't taken: memory (AppXSvc), no playtests.
  - **The street, report only: yes, the ordinary's and the elite's rows share the bare anchor** (`lead("rook", level)`, no gear). At level 9, one action at a time, bare / on budget:
    - ordinary: ttk 3.79 / 2.73 s, share 0.018 / 0.006 (seeds 5 s, 0.12 a kill);
    - elite: 10.67 / 7.66 s, share 0.173 / 0.060 (seeds 18 s, 0.35);
    - keeper: 39.25 / 27.86 s, share 1.507 / 0.520.
    - Research's word (23:03): no retune of the street's rows until the director decides the modes.
- **Research, 2026-11-26, by 23:23 (its message said 23:45, past the clock), on the director's word on tap to move** ("it just an nice bonus and simply shouldnt be to broken and be a winning situation in very situational cases"): standing is the design point. On budget, standing ends at 20 to 35%, so 25.8% passes and the keeper's numbers close on standing. The 50 to 70% dodging gate is dropped: a clean tapper may end at most 15 points above standing, measured with the tap block once it's in (in a fight the lead no longer follows the avatar's walking). Over 15, damage moves from the tells into the ordinary swings, and the tells' ×1.5 may come back down.

**B's elites' tells, the targets** (Scintilla, 2026-11-26, 22:33; for research's pick in pairs). Painted on the street stage at the player's camera, with R4 as the build draws it: `build/handoff/Fight/targets/elite/` (each target's peak, its strip with its frames, and `phone_street/` with the six at a phone's size). Each look's beats and levers are in `tools/fx/elite_tell_targets.py`'s docstring.
- **The class:** every tell takes D1's make: an amber rim with a white core, a faint deep fill, and a fill growing to the hit. One addition: the rim heats as the hit nears. At this camera the bodies hide most of a fill: the footprint lies under the lead, and the fan runs through the avatar's spot. The keeper's grey footprint takes the same make at its finish. The screen is a wall, not a hit, so it takes W2's azure lines.
- **The overhead,** with the same footprint in both (radius 3, 3.4 ahead, seeds):
  - **O1, the weight:** a ball over the raised fists, with streaks drawn into it ever faster. It goes white-hot for the last 8 frames, then falls on the footprint as a comet. It takes R4's spot, so R4 fades for the wind-up (a hook change).
  - **O2, the halo:** an amber ring closes on the mask at a steady rate, and the mask lights as the ring meets it. R4 stays.
  - **My read:** O2 reads at a phone's size. O1 stays a small light there, since its ball can't pass 0.82 studs or an elite's reaches the target card. O2's ring could read as a lock-on: research's to weigh.
- **The fan:**
  - **F1:** the three lanes as one shape, with one arc of fuse.
  - **F2:** three claw-mark blades lit by their fuse, with each lane's reach a hair.
  - **My read:** F1 reads at a glance at a phone's size; F2 is quieter.
- **The screen, in the cap:**
  - **S1, the lantern wall:** nine ribs and two rails.
  - **S2, the fence:** five rails and three posts.
  - Both face the player's side. At the lead's 45° spot (F) the screen is seen from the side, about 180 pixels across.
- **Not in them:** the bodies' poses (a frozen Brawler at Scale 1), the elite's 1.35 scale, and sound.
- **Content check** (22:34): all six PASS. One note for the build: F2's claw marks lie on the street only, never across a body.
- **Next:** research's pick. Then I write the picked rows as data, and Faber hooks the three moves.

**B's elites' tells, the rows** (Scintilla, 2026-11-26, 22:52). Research's pick (research, 2026-11-26, about 22:55; the peaks at full size, `peaks_phone.png` and `peaks_squint.png`, read in both orders):
> - **Overhead: O2_halo.** Why: at night on the street, O1's ball is one warm point among dozens of warm lanterns, so it loses the focal point at the squint. O1 is the better motion (a hero shape with a direction and an acceleration), but it doesn't read where it's needed. O2's ring is a shape no lantern makes, so it reads at the phone and at the squint, and R4 stays without a hook change. **Must-fix (class: a tell reads as a countdown, never as a lock-on):** the ring visibly closes, starting at 1.8× or more of its end diameter, and heats from amber to white as the strike nears. It lands with the footprint's flash. No ticks or crosshair marks.
> - **Fan: F1_fan.** It reads at a glance, and the notches between the lanes show where the gaps are. F2's blades are quieter, and they draw claw marks.
> - **Screen: S1_lantern.** At the phone it reads as one see-through azure wall. S2's thin rails fade at the squint. The upright ribs also belong to Lantern Row, which is where this elite lives.
> - **What the targets can't show, first seen in Faber's hook:** the ring beside the R4 chevron in motion; the fan's far ends behind bodies; the screen at the lead's 45° spot. I judge those once in the hook's capture.

- **The rows** (`tools/fx/shade_tells.py`, in `build/handoff/Shade/fx/`): each is its action's own effect, written at its elite's size, so its floor is the street. `Area` is the elite's Scale, read from `Definitions.Enemies`.
  - **ShadeOverhead, 40 rows.**
    - The ring is three cards riding `Mask_Brawler`, 0.95 studs before its middle. It closes at a steady rate from radius 2.4 to 1.3 at Scale 1, which is 1.85 times its end, through the 72 frames to `Strike`.
    - It heats from amber to warm white over the last 24 frames, with a light round the mask. It flashes white on `Strike` and is gone by 5. No ticks.
    - The footprint is D1's make on a disc of radius 3, 3.4 ahead (seeds). It's laid faint, its fill grows from the middle to `Strike` (linear), and its rim of 16 strokes heats.
    - On `Strike`, everything goes white with the ring, needles of light leap off it, a light flashes, and it all closes over 6 frames. It's held where it was laid on the wind-up's first frame.
  - **DasherFan, 120 rows.**
    - DasherLine's lane three times, at 0° and ±25°. Only the three lanes' common outline is stroked (39 strokes, each with its core), so the notches show. Each lane's fill is laid, and its fuse is lit in turn to `Land`, with the rim heating.
    - The Dasher runs the middle lane with DasherLine's streak. Each side lane is run in the same quarter second by streaks of light flown down it, and a slash bursts at each lane's end, from points laid at `Line`.
  - **GuardScreen, 5 rows:** the ward's passes (now `ward_rows`, which GuardShield shares, its file unchanged) on the wall's pictures, 2.6 studs ahead, on `Raise` and `Drop`. Its glance is GuardGlance's.
  - **GuardScreenBreak, 17 rows** (Faber: the screen breaks like the ward). GuardBreak's way at the wall's size, all on the wall: the tear, the puff and the light from its middle, the whole wall's frame flashed white for two frames, and nine chips flung off across it and on along the blow, gone by 20 frames. The hook anchors it at the Guard's root, Front the way it faces (an effect played at a point rides no body, by the cases), and the rows find the wall from there as GuardScreen does.
- **The pictures:** `overhead_ring_ink`, `_light` and `_core` (512 px), and `guard_screen_ink`, `_light` and `_core` (1024 px) with `guard_screen_run` (a Grid4x4 flipbook). They're drawn by the targets' own strokes (`tools/fx/elite_tell_targets.py --pictures`), and S1's wall is drawn flat, without the target's curve. Uploaded under the group at 22:51; the ids are in `docs/asset-log.md` and `Config.Effects.Pictures`.
- **Checked:**
  - The game's rows cases on the three files, by `rows_take`, dry run with the pictures named: the only failures are the three actions not yet in `Definitions.Actions`, and the files were taken back out. Without them, the offline suite passes (36,499).
  - The four existing effects' files are byte for byte unchanged.
  - The pictures' content check: all seven PASS.
- **For Faber, the hooks:**
  - **The three actions in `Definitions.Actions`:**
    - `ShadeOverhead`: `Strike` at 1.2 s, length 2.7. Its hit takes the footprint's disc, as laid on its first frame.
    - `DasherFan`: DasherLunge's beats, `Aim = "Line"`, and its hit on any of the three lanes.
    - `GuardScreen`: GuardRaise's beats, with the guard covering the wall.
  - **Then take the files:** `py tools/fx/rows_take.py` on the three files.
- **Found on the way:** played on the elite Dasher, DasherLine would float about 1.1 studs over the street. This is from the code, not seen in play: it's World and rides the root at -2.96. Once the elite's Signature is DasherFan, it only plays at Scale 1, so nothing changes.
  - A `Ground` point can't carry it: Effects.Play anchors the rows at the action's start, and DasherLunge turns to its target until `Line`.
  - The fan and the footprint use footOf's own drop, -3 × Scale, so they're on the street.
- **Next:** Faber's actions, then research's look in the hook's capture.

- **Research, 2026-11-26, 23:23, the gates after the director's word on tap to move** (`docs/decisions.md`): standing is the design point, ending on budget at 20 to 35%, and 25.8% passes.
  - A clean tapper ends at most 15 points above standing, measured with the tap block. It replaces the 50 to 70% dodging gate.
  - The keeper's numbers close on standing now. If the gap is over 15 points, damage moves from the tells into the ordinary swings.
## TR70. The break and its reveal, overhauled (research, 2026-11-26, 14:17; overhaul 2 of `docs/production-plan.md`, "The overhaul"; for Faber, with Scintilla's targets)

- **Why** (`docs/research/cloud-2026-11-24/reveal-and-showcase.md`, MEASURED on our pools):
  - by the tenth rolled break, 9 reveals in 10 are copies;
  - a copy plays the first one's whole ceremony, and takes 1.3 s and two taps at best;
  - the copy shows no progress;
  - ready shards open one at a time.
- **The look:** the director's word after Anime Crusaders' pull ("this is what we need", 11-24) asks for a banner's moment: a full-screen void, then the Voidkin standing large on a burst in its rarity's hue (`docs/research/anime-crusaders-ui.md`, "Lessons for us").
- **Feel line:** your shard splits and the screen drops into the void; a new Voidkin lands huge on a burst of its rarity's colour, a frame worth a screenshot, while a copy is a one-second tick on its star bar.

**A. The rules,** on today's stage, as a block:
- **Three forms by news,** chosen from the server's answer (`reveal-and-showcase.md`, "Proposal": its two tables are the seeds):
  - **Flash** for a copy of Common to Rare: 0.7 s, rungs at twice the speed, portrait in colour, the star bar ticks up by one, and it closes by itself;
  - **Full,** as built, for a new Common or Uncommon and a copy of Epic and up;
  - **Event** for a new Rare and up and the account's first reveal: the built time plus the tier's extra beat, then a longer hold.
- **One tap ends a reveal.** The skip opens at 0.4 s once the account has seen three reveals (1.0 s before that). Rarer is never slower to skip. On a copy, the plate closes itself after 0.8 s. On a new Voidkin, it waits for the tap.
- **The plate says how far:**
  - "{rarity} · {class} · {element}";
  - what it's good at, in one line (`docs/ui.md`, screen 2);
  - the copies, with numbers: "★1 · 3 of 4 copies", or "Star ready" when a star's cost is met, spent by hand as today;
  - "No. {n} · {count} exist" on a new one (`docs/design.md`, "How many exist").
  - On a new Voidkin, Lead and Work beside Continue.
- **Open all,** when two or more shards are ready:
  - one server step opens them all;
  - a repeated or interrupted request never opens one twice or loses one (logic and fuzz cases, as chests' Open all has);
  - up to four split in a row, the lowest first, 0.25 s apart; copies play as Flash and the best plays last in its own form;
  - a "2 of 4" strip along the top, then one summary sorted by rarity, copies stacked;
  - the button reads "Open all", the chests' own word.
- **The gates, timed in Studio:** the tenth reveal, a copy, is done 1.0 s from the tap or less. Four ready shards holding one new Voidkin are done in 4 s or less.

**B. The stage's look, targets first** (`AGENTS.md`, "Every action, world, effect and screen"):
- Scintilla brings two or three targets: the peak frame and a strip of the life of the void moment, the split and the burst, for a new Rare and a copy of a Common, in the game at phone size, beside today's.
- **The technique to try first:** a full-screen ViewportFrame with its own camera, so the player's camera is never touched. The figure stands at 60 to 70% of the screen's height on a radial burst in its rarity's hue, with a ring of light at its feet.
- **The hue:** the rarity's, held to the burst. Violet only where the void itself shows (`docs/research/examples.md`, "too purple").
- Research picks in pairs. The build starts only after the pick.
- Today's stage stays beside it until the pick.
- **The targets, for the pick** (Scintilla, 2026-11-26, 16:27). They're drawn on the game's own figures: LyricReveal and RookReveal mattes from a full-screen ViewportFrame lit as `Config.Reveal.Lit`, over the Breaker's world. Each is beside today's stage at the same times, at the phone's 2.16:1 (`tools/fx/reveal_capture.lua`, `reveal_frames.py`, `reveal_targets.py`). The sheets are in `build/handoff/Reveal/new_stage/sheets/`, the peaks and strips in `.../targets/`.
  - **For a new Rare (Lyric)**, three directions, each with its peak beside today's (`R*_pairs.png`) and the lives in one sheet (`life_Lyric_new_Rare.png`):
    - **R1, the shard burst:** cut-crystal rays in the hue from behind the chest on graphite, and a ring broken by shard cuts at the feet.
    - **R2, the rift:** the split held open as a tall tear behind the figure, a narrow fan of facets, and speed lines in the void.
    - **R3, the hue's field:** the void breaks into a bright field of the rarity's colour with white rays, a light frame rather than a black one.
    - In all three, the void closes over the world as an iris onto the shard, the only violet is the shard and the motes, the figure stands at 66% of the height, and the name and plate are today's lines where they sit.
  - **For a copy of a Common (Rook)**, one target, C1, the Flash. A card rises over the world with the portrait, its name and "2 of 4 copies". On the tick at 0.3 s, the third pip fills with a white flash and the count turns to 3, and the card closes by itself at 1.3 s (`C1_pairs.png`, `life_Rook_copy_Common.png`).
  - **Not in the targets:**
    - the shard is a stand-in for today's own;
    - the CoreGui top bar is under the void, where in the game it stays on top;
    - today's frames are at Studio's 1.8:1.
- **Research's pick, in pairs (Quaestor, 2026-11-26, 16:31; `sheets/R*_pairs.png`, `life_*.png`, both orders, with a blind fresh-eyes read): R1, the shard burst, and C1, the Flash.**
  - **All three beat today in both orders.** R2 loses to both in both orders: its tear reads as a flat cut-out, nearer the rejected "2d cartoonish" effects.
  - **R1 against R3: no clear difference.** The two orders disagree, for me and for fresh eyes. R1 is the bigger hit, and R3 is brighter and passes the gates better. The tie goes to R1 for three reasons: it's nearer the accepted graphite ("i love the graphite UI wayyy more"), it keeps the void the feel line asks for, and its cut crystals are our own. R3 stays on file beside it.
  - **Must-fixes for the build:**
    1. **The figure holds the strongest contrast** (the gate; class: every rarity's burst). The core sits behind the chest, as R1 is described, never behind the head, and the white keeps off the hair. In grey the spokes stay under the figure's edge, with a darker band next to it or the figure's own rim.
    2. **Rarity sets the loudness** (the rule above). A Rare sits mid-ladder, so its burst is a step down, and the full-frame spokes are kept for the top rarities. The quarter checkpoint shows the ladder, one frame per rarity, at one time.
    3. **C1 meets the gate:** a copy is done by 1.0 s after the tap, and the plate closes itself after 0.8 s (block A). Today it closes at 1.3 s. The card takes AR62's panel, graphite with the shard cut.
  - **The must-fixes, in the targets (Scintilla, 16:44):** the files are in `build/handoff/Reveal/new_stage/`, with `R1_burst_pairs.png` and `C1_pairs.png` beside today's.
    1. The white core is behind the chest's middle (0.42 of the figure down), and the added light keeps off the head. A dark band at the figure's edge keeps the spokes under it in grey (the pairs' grey row).
    2. The ladder is `targets/R1_burst_ladder.png`, one frame per rarity at 2.40 s: from 8 short spokes on a Common up to a full frame and a second ring of thin needles on a Mythical. A Rare sits mid-ladder, and its numbers are `LADDER` in `tools/fx/reveal_targets.py`.
    3. C1 closes by itself from 0.8 s and is gone by 0.95 s. Its card and the plate take the shard cut.
  - **For Faber's install, my proposal:**
    - The spokes: one facet image (a lit face and a shaded one along a bright edge, fading to the tip), repeated N times and turned about the core, tinted with the rarity's hue, behind the figure's ViewportFrame.
    - The core and the glow: two radial images.
    - The dark band: the figure's ViewportFrame again in black (ImageColor3), about 4% larger, behind it.
    - The ring at the feet: one image, with the shard cuts.
    - I make and upload the three images (spoke, core, ring) when you start the install.
  - **The install images, made (Scintilla, 22:02; for Faber's install):** six, not three, because a tint colours a whole image and the target's ridges, core and ring line stay white. They're in `build/handoff/Reveal/new_stage/images/`, drawn by `tools/fx/reveal_images.py`, whose docstring gives each one's size, place, turn and transparency:
    - the spoke and its ridge;
    - the core and the glow;
    - the ring and its line.
    - The check is `sheets/R1_install_check.png`: the images laid as the engine lays them, beside the target, a Rare and a Legendary. They hold. The light is kept off the head with the core image in black, and the dark band is two black copies of the figure's ViewportFrame, which come out a little crisper than the target's blur.
    - Content check: PASS on all six. Keep the shapes free of droplet tips or splashes, even in Mythical's pink-red.
    - Uploaded under the group at 22:04, so the install needn't wait. The ids are in `docs/asset-log.md`, and the install puts them in the reveal's config.

**Not in this piece:** the Voidkin's own line and epithet (they need the director's ear first, given the "corny" rejections); the Index; a column of light from the Breaker in the world; the cut-in; new sounds (TR64's ear first); pity and banners.

## TR71. How the game talks, overhauled: one conductor, endings that point on, refusals that say the fix (research, 2026-11-26; overhaul 3 of `docs/production-plan.md`, "The overhaul"; for Faber, after TR69's block A)

- **Why** (`docs/research/cloud-2026-11-24/orchestration.md`, OBSERVED):
  - seven pieces announce events, each on its own, with no queue, no priority and no fight gating. `Theme.Time.Fight` gates only the hit cues;
  - gold means eight things and red five;
  - about twenty wordings of a refusal;
  - the big moments are silent while an ordinary hit has a cue.
- **Feel line:** in a fight you only see the fight; the moment it ends, what you got lands in order, one line at a time, beside the counter it feeds, and every ending tells you the one thing to do next.

**A. The conductor,** about 1.5 days, as `orchestration.md`, section 5:
- **One door.** Every system calls `Conductor.Say(kind, payload)`. Toast, the level plate, the quiet note, the dare line and the drop's plate go through it, and nothing shows a notice on its own.
  - Each kind's band, lane, merge key, cue and words live in one config.
  - The ordering is pure Luau, with logic cases: same frame, merge, fight gating, defer, drop.
- **The bands** are 5a's seven, from Still to Event. A higher band adds a channel the lower never uses.
- **Lanes:** the lead's news under the lead card; rewards and refusals under the counters they feed; the centre only for band 4 and up.
- **In a fight** (inside `Theme.Time.Fight` of the last hit):
  - at most one item per lane;
  - a band 3 item not about the fight is an icon chip with no words, and its line plays when the fight ends.
- **Merge:** the same kind and the same thing inside 1.0 s count up in one line.
- **Order:** higher band first, then about the fight, then rarity, then arrival, 0.25 s apart.
- **Never covered:** nothing draws over a reveal, the travel card or the run's card.
- **Dropped:** a band 1 or 2 item waiting over 4 s, since its counter already shows it. Band 3 and up are never dropped.

**B. One refusal.** One helper and one table of reasons, grey, with the control's shake. Each reason says the fix with its number:
- "Need 1,200 more Credits";
- "Upgrade the base first".
- No raw codes, and no "can't". TR68's words go into that table.

**C. Every ending points on.** One Next line, with its press, on:
- the run's card (win and fall);
- the keeper's fall;
- a Tower run's end;
- a new Voidkin's plate (Lead or Work, TR70);
- the return card.
The line names the one thing nearest to done, read from the state the server already holds. The first that's true wins (research's words, 14:22):
  1. a shard is ready: "Your shard is ready" · Open;
  2. a Voidkin's star is paid for: "{name} can take a star" · See;
  3. a bay is empty and a Voidkin is free: "Bay {n} is empty" · Pick;
  4. the base's upgrade is affordable: "You can upgrade the base" · Upgrade;
  5. a goal needs one more: "{goal}: 1 left" · Go;
  6. otherwise the next fight: "The Lamplighter is next", "Lantern Row on Hard" or "Lantern Row again" · Fight.
  - A fall's card keeps its three presses (Retry, Send another, Home), with the line above them.
  - Words fit `docs/ui.md`, "Words players read". A press is one word.

**D. The return card, the whole screen** (the director, 2026-11-24, 21:13: "it need to be the whole screen"; TR53's card):
- what the base made while you were away, in one Collect;
- its Next line;
- its look from the picked style frame (AR62).

**After the style frame's tokens land:** the semantic sheet (`orchestration.md`, 5b). Every meaning gets one colour, one shape and one word, taken from the picked frame's tokens, plus one Rarity table. Research writes it into `docs/ui.md`.

**Sound:** TR64's cues, by the director's ear. The conductor plays one cue per event, and the higher band wins inside 80 ms.

**E. A machine's words** (research, 2026-11-26, 18:12, from AR65's walk-ins, `build/captures/ar65/installed_walk_*.png`):
- A machine's name shows once, on its plate. Its prompt says only the press ("Open", "Convert"), with no second name above it.
- Up close, the Breaker's plate carries its line like every other machine's: "13 ready to open", or nothing when nothing is ready. The toast stays for the gate, through the conductor.

**Not in this piece:** experience notifications (the director's word first); the rarity notes' pitch set (Sonus and the director).
- **Faber, 2026-11-26, 15:03:** **A, the pure conductor:** `Rules/Conductor.luau` with `Config/Conductor.luau` (bands, lanes, merge, the fight's gate, defer and drop). Its 5 logic cases pass offline. Not yet wired to the HUD. B to D next.
- **Faber, 2026-11-27, 02:31:** **B, one refusal, tested in Studio** (built in 5d1e299d: `Config.Refusals`, `Rules.Refusal`, `UI.Kit.Refuse`, the shake). The kit's case and the screens moved onto it pass in the main place: Kit 95, Equipment 103, Shop 75, Base view 192, Voidkin screen 28, Breaker 263, Settings 59, all 0 failed. Not yet judged in play.

## TR72. Design against code: what the design promises and the code doesn't do (research, 2026-11-26, 14:25; for Faber, after TR69's block A)

- **From:** `docs/research/cloud-2026-11-24/systems-map.md`, section 6, re-checked at HEAD today. Rows 2, 5 and 7 are now built. Research fixed the design where it was stale: the status line, the shop's stones, Drum Court's kept win, and the Tower's week. These remain, each with a logic case:

| # | The rule (`docs/design.md`) | Today | Ask |
|---|---|---|---|
| 1 | "A worker made lead swaps places" (Roles), new today | the bay is left empty, the old lead goes home idle (`Rules/Collection.luau`, 110-126) | the old lead takes the bay, unless it's healing |
| 2 | "Salvaging an item keeps what was put in it", new today | emblems, jewels and Reinforce go with it (`Rules/Chests.luau`, 588-605) | emblems and jewels to the bag first; the confirm names the Reinforce level lost |
| 3 | a lead far below the account's best levels faster (Roles; `docs/balance.md`, "Catch-up") | no catch-up anywhere (`Rules/Drops.luau`, 129) | the balance's catch-up, as written there |
| 4 | Training earns a third of what Lantern Row earns | `KillsPerHour = 450` against 136 to 204 counted on the stages (`Config/Growth.luau`) | set it from TR69 block B's timed run: a clean run's kills over its seconds |

- **Waits, named so nobody forgets:** Rook's evolution ("One at launch", Voidkin, "Evolution"; no code), after the three overhauls. Auto-salvage's stones come with the Forge (`Config/Chests.luau`, 107). The three shard grades, luck and voltage are as `launch-design.md`, section 2, left them.
- **Faber, 2026-11-26, 23:54: items 1 and 2 in.**
  - **Item 1, the swap** (`Collection.SetLead`):
    - A worker made lead swaps places: the old lead takes the bay it left, and the answer's Swapped names it.
    - A fallen lead not yet whole goes home and the bay waits empty. That's Carry's Healing, the server's fact through `LeadService.Healing`, handed to the rule as `Collection.Facts`.
    - One made lead from home leaves the old lead home idle, as before.
    - The Lead press on a worker says who takes its bay and what the bay's making changes by: "Rook takes Bay 2 · −6 kW", else "Leaves Bay 2".
  - **Item 2, salvage** (`Chests.SalvageItem`):
    - The item's emblems and jewels go to the bag first, and the answer lists them. Lost is its Reinforce level.
    - The confirm reads "+1,200 Credits · Its +7 is lost".
    - The toast reads "Salvaged for 40 Credits", or "+1,200 Credits · 2 emblems, 1 jewel to the bag" when something comes back. That's the content check's length fix; it passes.
    - The chests' fuzz case now holds every emblem: none goes with an item.
  - **Tests:** type check 0 new; logic 42,486 pass offline, covering the swap, the healing one, from home, salvage's emblem, jewels and Lost, and the words.
  - **Not yet:** no Studio run (memory), not visually reviewed. Items 3 (the catch-up) and 4 (Training's kills, from block B's timed run) wait. AR62's piece 1 goes first, by research's word.
