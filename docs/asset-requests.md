# Asset requests

The asset maker's queue, in order. A piece's record is its entry here: the feel line, what it delivers, the checks, the verdict, the status. The bar: `docs/north-star.md`. Who the Voidkin are: `docs/roster.md`.

**The line every design is held to** (`AGENTS.md`, rule 3): a Voidkin starts from a type of character a whole genre shares, and its silhouette, outfit, move and name are ours. Reference is for mood, never a blueprint. Each sheet passes the content check before anything is modelled.

## AR1. Rook, the first Voidkin, to the bar

For Modulo. Research's request, 2026-11-11. The exemplar: what every later Voidkin is measured against, and the first one timed.

**Feel line:** a street brawler you'd pick out of a crowd by his outline alone, who winds up so far you flinch before the punch lands.

**Delivers,** in this order, each shown before the next:

1. **A design sheet:** silhouette in black; front and three-quarter views on the R6 body; three colour chips; the key pose of Haymaker; the sheet again at 64 px over dark and bright grounds. From `docs/roster.md`'s row. Content check and research's verdict here before any model.
2. **The model** on the R6 rig, at the player's height: how hair, jacket and gauntlet sit on R6 (meshes, textures or both) is yours to settle, with its cost in triangles and in hours noted here.
3. **The clip reel,** the one R6 has never had from us: idle with a breath; the three-hit combo with wind-up, contact and recovery readable in each; Haymaker; hit taken; down and back up; the reveal pose; one working loop for a bay.
4. **The look of Haymaker:** one hero shape with a direction and an acceleration, designed with the builder in the same session (`/ga-action`).

**Time it.** Hours for each of the four, written here. This entry's total is what the launch date is estimated from.

**Checks:** the content check on the sheet and before upload; your own review strips; research's verdict (`/ga-review`) on the sheet and on the final in motion; fresh eyes on the final.

**Status:** in progress (Modulo, 2026-11-12). Deliveries 1 to 3, the sheet, the model and the clips, are delivered to `build/handoff/Rook/`. Delivery 4, Haymaker's look: the builder's replay is in, the ram's heat with it, past the content check's engine looks (section 7), staged as the game frames it and with its sound (section 8). Fresh eyes has read it. Research's final and Modulo's look on the staged take are next, and the director's ear on the sound. Rook's body is in the game, maps and clips included (section 6).

**1. The sheet** (Modulo, 2026-11-12).

- **Where:** `build/handoff/Rook/rook_sheet.png`, redrawn with research's fixes 1 and 2. `tools/blender/rook_sheet.py` rebuilds it (`-- <out> sheet`); `-- <out> pack` writes the eight outlines the direction was picked from.
- **The look:** R6's own blocks and round head in a cropped oxblood jacket over a bone wrap. A collar that stands as a wall behind the head. A flat-top with one cut. The left sleeve torn off, the arm taped, two loose ends of tape to move. On the right arm one ram of a gauntlet, 1.9 × 1.8 × 2.2 studs, carried a quarter stud wide of the arm. A battlement in bone across the jacket's back, the side the player's camera sees most.
- **The director, 2026-11-12,** on the sheet's second pass: "i think it should look more R6 and the eye are bit off". It covers Rook's sheet. Done: limbs and torso are the R6 blocks with clothes as thin shells, the head is R6's round one, and the eyes are redrawn level and apart. Only the gauntlet, the collar, the hair and the tape ends stand off the blocks.
- **Tried on the sheet, tier 1:** a piston on the gauntlet's back that draws out through the wind-up while the knuckles light, so the tell is on the weapon itself. For the builder and delivery 4: it wants its own joint.
- **Open for the clip:** R6's arm has no elbow, so the punch travels an arc and lands straight. The key pose winds the body until the back half-shows.
- **Assumed:** the player's camera (behind, 18° up, orthographic views). Config holds no camera numbers yet.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4, at full size and in the 64 px rows. To hold on the model and the clips: the collar gets real cloth thickness (its rim shows as a thin line from the player's camera); the plaster, the torn sleeve and the tape ends stay clean and bone, never tapering into drops; the back mark stays a plain battlement; through Haymaker's hold the lead arm stays at or below the shoulder; "Oxblood" stays an internal colour name; the evolution with two gauntlets gets its own check. For research: the check found no "Fighters" test in `docs/decisions.md`, which `AGENTS.md` rule 3 points to, and it left a note on the name Haymaker for the name re-look.
- **Research's verdict** (Quaestor, 2026-11-12, on the sheet and the pack; stills, so motion waits for the reel):
  - **Felt:** a square brawler with an iron ram on one arm and a wind-up you read from the outline alone. At rest, from behind and at 64 px over dark, the ram sinks into his legs and the ground.
  - **Tier:** competent. Not yet exceptional, which the exemplar aims at. The piston and the wind-up in motion are where exceptional has to come from.
  - **The one bold thing:** the side-on Haymaker outline. A pointing arm and a ram drawn all the way back read as a punch about to land, with no colour at all.
  - **Fixes:**
    1. The ram's big faces go one value up, to Iron, over Ink trousers. Read 1 is now the weakest thing on the dark 64 px row, and in the three-quarter view it sits on the thigh, dark on dark (serves: picked out of a crowd).
    2. The model's rest pose and the idle hold the ram off the hip, with daylight between it and the body. The front outline fuses ram and torso into one block (serves: the outline alone).
    3. From the player's camera, the taped lead arm hides behind the head and collar through Haymaker's hold. In the clip it opens 20 to 30° to the side, still at or below the shoulder, so "marks the target" reads from behind (serves: the flinch). For delivery 3.
  - **Next:** the model starts with fixes 1 and 2. Fix 3 goes into the clip. The camera stays assumed until Config holds it, and the reel is judged at the real one.
  - **For the next fighter's pack:** Rook's eight outlines differ in details. Pip's should differ in kind.
- **Hours:** the sheet, 0.5 (the kit's copy and three passes included).

**2. The model** (Modulo, 2026-11-12).

- **Where:** `build/handoff/Rook/`, delivered 2026-11-12: eight `Rook_<Piece>.json` meshes, four maps, `Rook.recipe.json`, and the review sheet `rook_model_sheet.png`. `tools/blender/rook_model.py` rebuilds all of it in about 20 seconds (`-- <out>`).
- **How he sits on R6:** meshes and one texture set. A rigid mesh rides each of the six parts and carries the body's own surface too, so the rig's blocks are hidden. Hair, collar, jacket and gauntlet are geometry. The face is geometry too, so it holds at any distance. One 1024 px atlas holds everything, with the contact shading baked into the colour, at 73 px a stud. No normal map: the low mesh is the form.
- **Cost:** 7,236 triangles in 8 pieces, the gauntlet arm 2,912 of them. Four maps: colour, roughness, metalness and a glow mask.
- **Two joints past R6's six:** `Rook_Piston` on the right arm slides 0.65 studs toward the shoulder, and `Rook_Tape` on the left arm swings. Their pivots are in the recipe, and the clips key them under those names.
- **The glow:** the mask covers the knuckles, the heat band and the piston's rod. The game lights it on `Rook_RightArm` and `Rook_Piston` with `EmissiveStrength` 0 to 10 and `EmissiveTint` #FFA630, through Haymaker's wind-up. The 10 is from the rebake, section 5's last entry; it was 2.5.
- **Research's fixes:** 1, the ram's big faces are Iron over Charcoal trousers. 2, the rest pose holds the ram 20° out, with daylight to the hip. Added on the model: a seam and four bolts on the fist, trouser cuffs, a steel buckle.
- **For the builder to check in the game:**
  - Hide the six rig parts (Transparency 1).
  - Keep a clip playing at all times. With the arm hanging at R6's rest, the ram meets the hip, and every clip holds it out.
  - Metalness is low (0.35 on the iron) so the ram keeps its value under any sky. Say if it reads flat.
  - The clothes are shells 0.01 to 0.02 studs proud of the body: look for flicker at a distance.
- **Content check, 2026-11-12:** BLOCK on the colour map, then PASS. The first map's ground between the islands was dark plum, and its small islands padded into drop shapes. Now the ground is one neutral, and islands under 20 px sit on flat swatches. To hold: an entry in `docs/asset-log.md` before upload; the lead arm stepped on a bare rig when Haymaker's clip is checked.
- **Research's read** (Quaestor, 2026-11-12, stills from the baked maps; the clips judge it in motion): the model rides on to the clips as it is.
  - **Felt:** the sheet's brawler made solid. The Iron ram now leads every view, and at 64 px over dark it reads before the jacket does.
  - **Tier:** competent. Fixes 1 and 2 landed. Exceptional still has to come from the wind-up in motion.
  - **The one bold thing:** the lit ram from the player's camera. The ember face is the brightest thing in the frame, so the tell sits on the weapon, where the player looks.
  - **Fixes:**
    1. At the reveal's size, the mouth reads as a smudge under the plaster. Give it one firm line, a set jaw (serves: the reveal's "a real character, a name"). It's on the colour map, so the clips aren't touched.
    2. The sheet's fix 3 is still open, for the pose sheet: from the player's camera, the lead arm hides behind the head through the hold.
  - **Done** (Modulo, 2026-11-12): 1, the mouth is one firm Ink line, rebaked, and the content check passed it. 2 is in the clips.
- **Hours:** the model, 0.5.

**3. The clips** (Modulo, 2026-11-12).

- **Where:** `build/handoff/Rook/clips/`, delivered 2026-11-12: eight `Rook_<Clip>.json` exports at 60 fps, and each clip's key poses from the player's camera, the front and the side (`poses_<Clip>.png`). `tools/blender/rook_clips.py` rebuilds them (`-- <out> export`, about a minute), with each clip's pack on the bare rig and its arcs, one dot a frame, which stay out of git for their size.
- **The reel:**

  | Clip | Seconds | Markers | The performance |
  |---|---|---|---|
  | Idle, loops | 2.40 | | weight sunk, the ram heavy off the hip, one slow breath, eyes on you |
  | Combo | 2.00 | Hit1 0.20, Hit2 0.80, Hit3 1.43 | a jab to find you, a hook with the ram, then the ram straight down |
  | Haymaker | 2.00 | Charge 0.13, Strike 0.95, Shock 0.97, Step 1.05, Vent 1.17 | the ram drawn back at the camera, the taped arm thrown out to mark you, a beat too long, then he steps through you behind it |
  | Hit | 0.30 | | the flinch: the lead shoulder turned, and the ram's weight swings him back |
  | Down | 1.10 | Land 0.57 | the legs go, he sits down hard and hangs on the ram like a post |
  | Up | 0.90 | | he pushes off the ram, and the head comes up before the body is ready |
  | Reveal | 1.60 | Knock 0.85 | folded small, opens wide, the ram straight up, the piston fires once, held for the name |
  | Work, loops | 2.00 | Pump 0.13 | he drops the ram on the post like a pile driver, and takes his time |

- **Timing:** from the seeds (`docs/balance.md`): the combo's three hits sit inside 1.8 s, and its last 0.35 s is recovery the next action may cut. Config holds no action yet, so the beats join Config with delivery 4.
- **Changed from the request's words, tier 1,** each accepted in research's read:
  - "Down" is a hard sit propped on the ram. R6 has no knee to go down on.
  - The reveal's last gesture is the piston firing with the ram raised. R6's box arms can't meet on the centre line without going through the chest.
  - Hit is the flinch of `docs/design.md`, "States in a fight": 0.3 s, and the feet never move, so it can sit over an action.
  - Haymaker's torso winds 36 to 46°, not the sheet's 80. Past that the body hides the marking arm from the camera behind him.
- **For the builder:**
  - Each clip keys the six R6 joints and the model's two: `Rook_Piston` (its draw, 0 to 0.65) and `Rook_Tape`.
  - Every one-shot starts from the idle's first pose. The reveal doesn't return to it: it ends held, and the idle takes over after the name card.
  - The root never moves. Haymaker's step is inside the clip (the body goes 0.95 studs forward and comes back), so the hit's reach is the game's to match or the root's to carry.
  - The glow follows the markers: up from Charge to Strike, out by Vent.
  - Not done here, and yours when the clips are registered: the blend over the idle with the game's fades, and the game's own dump of a pose against the export (`tools/blender/r6parity.py compare`).
- **My checks:**
  - The kit's audit passes on all eight exports: no limb through the body, nothing under the floor, no pop, loops closed (seam 0°).
  - Feet are solved onto their places on every frame, and a travelling foot lifts.
  - The ram's nearest to the body through each clip: 0.03 studs inside at worst (Haymaker, two frames after the strike).
  - Eyes: level on the target through Idle, Combo and Haymaker (within 5°); down on the post in Work; they leave the target in Hit, Down, Up and Reveal, as those beats ask.
  - Judged from stills, 12-frame strips, arcs and speed curves. Not judged moving at real speed, and the camera is the assumed one: both wait for the game.
- **Content check, 2026-11-12:** BLOCK on the reveal's held end, then PASS on all eight clips and the rebaked model. The first hold kept a straight arm raised 61° for 0.63 s; now the ram stands within 15° of straight up (`handbook/platform/rules-and-moderation.md`, "Salute-like poses"). To hold for the upload check: a bare-rig side view with the hold frames stepped; delivery 4's effect at "it fires" read from every heading at 64 px; another look at any clip the script changes.
- **Research's read** (Quaestor, 2026-11-12, from the pose sheets and packs; the final is judged in motion, in the game, with Haymaker's effect):
  - **Felt:** Haymaker throws the ram back at the camera, and the flinch the feel line asked for is there. The hold, though, is a freeze, and the combo's first hit can't be seen from behind.
  - **Tier:** competent.
  - **The one bold thing:** Haymaker frame 34 from the player's camera. The ram's knuckles come at the player and fill the lower frame.
  - **Fixes:**
    1. Haymaker's hold, frames 34 to 52, is still: the two frames match. Make it creep. The piston draws out across the hold, and the torso winds a few more degrees, so the beat that's too long reads as building, not stuck (serves: the flinch).
    2. Combo hit 1, the jab, can't be seen from the player's camera: the taped fist goes out behind the torso. Open it to the side as Haymaker's lead arm now opens (serves: three hits you can read).
    3. The reveal ends on the plain stance. End it on the hero pose instead, frame 51, the ram raised after the piston fires, held to the clip's last frame, so the name lands on it. The idle takes over after the card (serves: the reveal's "a real character, a name").
  - **Accepted:** the wind-up at 38 to 44° for the lead arm's read from behind; the hard sit propped on the ram; the reveal's piston firing in place of the knock on the palm; Hit as the flinch at 0.3 s. The ram's 0.02-stud dip into the torso in Combo and Up can't be seen at play distance.
  - **Fixes checked** (Quaestor, 2026-11-12, new pose sheets): 1 and 3 landed. The hold now builds, from 34 to 52, and the reveal holds the raised ram with his eyes on the player, which reads as the hero. 2 is better but still faint on the still: from behind, the jab sits mostly behind the shoulder. The final judges it in motion, in the game, with its spark, rather than in a second round of stills. The wider arcs on Haymaker and the hook are accepted.
- **The fixes, as made** (Modulo, 2026-11-12):
  1. The hold creeps at a steady speed: the piston draws from 0.3 to 0.65, the torso winds from 36 to 46°, and the ram arm draws back 14° more.
  2. The jab lands 40° left of the target, the torso turned 22°, so the taped arm shows left of the body from behind.
  3. The reveal ends on the raised ram, held from 0.97 s to its last frame, eyes on you. By the content check the held ram stands near straight up, steeper than frame 51.
  - Added with them: Haymaker and the hook swing round wide and rising. The first export took the ram under the shoulder like a pendulum.
- **Hours:** the clips, 0.7.

**4. Haymaker's look: the block-in** (Modulo, 2026-11-12). Grey boxes on the real clip, timing and size only, no art.

- **Where:** `build/scratch/modulo/rook/haymaker_fx/`: `blockin_A.png`, `blockin_B.png` and `blockin_C.png` (twelve frames each from the player's assumed camera), `blockin_side.png`, `blockin_bright.png` (a bright floor) and `blockin_64.png`. `tools/blender/rook_haymaker_fx.py` rebuilds them in about 15 s.
- **Feel line, proposed for research to sign:** Rook's punch lands and the ram's own square face is thrown down the ground through you, like the stamp of a pile driver, seen from behind him.
- **Job and rank:** a signature. It shows where the shock runs and that the hit is heavy.
- **The hero shape:** the ram's face as a square bracket, two posts and a lintel, standing on the ground across the hit's line. Direction: down the line, from the knuckles through the target. Acceleration: it snaps out and settles, 78% of its 8 studs in the first 4 frames and the rest by frame 10. It grows as it goes, so the body it reaches stands inside it.
- **One shape, three times:**
  - The charge: a square drawn tight onto the ram's face through the hold, from 2.9 studs to 1.7, cut at the strike.
  - The punctuation: the same square thrown open round the ram, 3.0 then 3.6 studs, on the Strike frame and the Shock frame.
  - The release: the bracket.
- **Variants:**
  - A, the corridor: five brackets punched up one after another down the line, each larger. They stay where they were laid and leave from the near end.
  - B, the thrown frame: one bracket flies down the line, stretched along its travel while it's fast.
  - C, the thrown frame and its wake: B, and where it passed it leaves A's brackets standing, thinner and greyer.
- **My pick: C.** B gives one hero with a direction, and from behind it closes round the target like a frame. Alone it leaves the ground between them empty, and from the side it's one post. The wake gives the depth and shows the line that was hit, and it stays under the hero in value.
- **On the clip's markers:** the charge from 0.47 s to Strike; the punctuation on Strike and Shock; the bracket from the frame after Shock; all of it gone 0.42 s after Strike.
- **Stand-ins, not decided here:** the reach (8 studs), the target's place (7 studs ahead), the body's knock back, the two greys. Colour and texture wait for the art sheet.
- **What I see wrong:**
  - From the player's camera, Rook's own body hides the bracket for its first two frames. The punctuation square carries those frames.
  - On the bright floor the light bars are weak and the dark rim must carry them. That's the art sheet's first job.
  - The body's knock runs along the view, so it barely shows from behind. How it's shown is the builder's, with the camera.
  - At Strike the ram is 2.5 studs right of his centre line: the swing is wide, and the ram reaches the centre line by Step. The shock's line starts at the ram's face and runs to the target, 30° across on this stand-in.
  - The 64 px sheet's labels cover a third of each tile.
- **Not done:** this is my preview, not the builder's replay, which doesn't exist yet. The beats aren't in a Definition.
- **Research's verdict** (Quaestor, 2026-11-12, on blockin_A/B/C, side and 64):
  - **Feel line, signed with one change:** Rook's punch lands and the ram's own square face is thrown along the ground through the target, like the stamp of a pile driver, seen from behind him. ("Through you" becomes "through the target": the player stands behind Rook, not in the line.)
  - **Felt:** the ram's square face thrown at the target and framing it, an idea only this weapon could have. From the player's camera, though, C's wake piles up round the target and hides it, and at 64 px the bars almost vanish.
  - **Tier:** competent, for a block-in. The direction is right.
  - **The one bold thing:** the square. The shock is the ram's own face, so the effect says who threw it.
  - **Pick: C.** Behind him, B is cleaner. But champions in the Clash Grounds and other players on Lantern Row see Haymaker from the side, and from there only the wake shows the line that was hit.
  - **Fixes:**
    1. The bars read at 64 px: about three times as thick as now, a lintel you can see on a phone (serves: "it looks expensive", hits that land).
    2. The wake stands at most half the hero's height and stops short of the target, so from behind the target's body and its hit reaction stay clear. It keeps the side read (serves: a hit you can read).
  - **Waits for the art sheet, as you wrote:** colour, the bright floor's rim, a ground mark under the posts.
- **The fixes, as made** (Modulo, 2026-11-12, `blockin_C.png` and the three shared sheets redrawn):
  1. The hero's bar is 0.85 studs at the ram and 1.35 at the end of the line, from 0.4 and 0.6. The punctuation square, the charge's square and the floor's lines are thicker with it.
  2. The wake is three brackets at half the hero's height, the last one a stud short of the target. From behind, the target stands clear inside the hero's frame. From the side the wake still shows the line.
- **Next:** the art sheet (the bar's texture and how it erodes, the colour, the rim for a bright floor, the ground mark), then the builder's replay.
- **Hours:** the block-in, 0.3.

### 5. Haymaker's look: the art sheet (Modulo, 2026-11-12)

- **Where:** `build/handoff/Rook/fx/haymaker_art.png` (the sheet) and `haymaker_bar.png` (the one picture, 512 x 1024). Made by `tools/blender/rook_haymaker_art.py`, about 40 seconds, Workbench: `blender -b --factory-startup --python tools/blender/rook_haymaker_art.py -- <out dir>`. It plays the block-in's thrown frame with the floor's lines (its B: research dropped C's wake at this sheet), at the block-in's numbers.
- **One bar, drawn once.** Every element is the same picture: the charge's square, the strike's square, the thrown bracket's posts and lintel, the floor's two lines. One upload, and "one shape three times" holds by construction.
- **The bar:** a chisel's stroke, both ends cut on the slant, in three tones: a cream core (`#FFF1CC`), Rook's ember (`#FFA630`), an ink rim (`#1E1B22`) that holds the shape on a bright floor. Three thin slits run in from its ends, and it's cracked into slanted chips in two rows, no two the same length.
- **How it's eaten:** eight frames, baked. One field says how deep each texel sits in the stroke, and a frame keeps what's deeper than its threshold: 0, 7, 16, 28, 42, 57, 72 and 86% of the bar gone. The cracks open first, then the chips part and shrink, and the tones follow the edge inward, so it cools as it goes: cream, then ember, then ink. Hard edges throughout, nothing soft, nothing round.
- **The numbers it's played at** (frames of the clip, 60 a second; Strike is 57):
  - The charge, 28 to 56: the square forms out of its chips over 8 frames (frames 7 to 0), then boils between frames 0 and 1.
  - The strike's square: frame 0 on Strike, frame 3 on Shock.
  - The hero, 59 to 74: frames 0 and 1 in turn while it flies (10 frames), then 1 to 7 over 6 frames while it still drifts, opens 6% and its feet lift.
  - The floor's lines: hot for 3 frames, then x (0.34, 0.26, 0.30), a scorch, eaten from age 4 to 11.
  - All gone by frame 76, 0.32 s after Strike. The block-in's markers said 82: the end is shorter by research's fix.
- **For the builder (your call, Faber):** each bar is a flat picture, unlit, cut by its alpha, stretched along its length only. The preview draws a bar's stroke as 60% of its plane's height and 92% of its length. One way that needs one upload: a `SurfaceGui` on a thin transparent part with an `ImageLabel`, stepping `ImageRectOffset` by 128 px a frame, and `ImageColor3` for the scorch's tint. No glow is added on the sheet.
- **My calls (tier 1):** the block-in's dark backing box became the rim, drawn in the picture. The corners are flush, so it stays a bracket and never a gate. I tried two afterimages behind the hero while it's fast, and took them out: they weren't in the block-in, and they cluttered it.
- **What I see wrong:**
  - Frame 59: the ram and his own body still hide half the hero, as in the block-in.
  - The chips are drawn by a rule, and at full size the bar's cracks show it: regular, like brickwork. At the size it's played, they read as a cracked stamp.
  - With the wake gone, the side view shows the bracket and two thin lines on the floor: honest, and plainer than the block-in's C.
  - On the dark floor the scorch is nearly invisible. That's meant: the hot frames carry it there, and the scorch is for the bright floor.
  - It's a preview in my renderer, not the builder's replay: no bloom, no camera move, no hitstop, the stand-in body.
- **Not done:** the beats in a Definition, the builder's replay, the sound, the camera. `ga-fresh-eyes` on the final.
- **Content check, 2026-11-12:** PASS, on `haymaker_bar.png` as it would upload and on the look as the sheet draws it, in all three tints on both floors.
  - To keep it a pass: the scorch no redder than it is; the scorch on the floor, never on a body; the bars hard-edged, with no soft, round or glossy variant. A change of tint or shape needs a fresh check.
  - Still owed before a public build: the effect at "it fires" from the front and three-quarter headings at 64 px, on the builder's replay. The sheet shows it from behind and from the side only.
  - The image is logged in `docs/asset-log.md` at upload.
- **Research's verdict** (Quaestor, 2026-11-12, on haymaker_art and haymaker_bar): on to the builder with the wake dropped.
  - **Felt:** the ram's face thrown as a hot iron square that frames the target and cools as it breaks up: cream, then ember, then ink. In colour the wake reads as rusty scaffolding under it.
  - **Tier:** competent on the sheet. Exceptional, which a signature aims at, has to come from the builder's hitstop, camera and sound on the replay, judged in motion with fresh eyes.
  - **The one bold thing:** one bar for everything, eaten as it cools. The effect is made of one stroke, and the stroke carries Rook's ember.
  - **The wake: dropped.** It was there for the side read, and in colour the floor's two lines already give that read, cleaner. That's the block-in's B with the scorch lines. It's also the second round on the wake idea, so it's dropped rather than patched again.
  - **Fix:** the last frames, 74 to 80, hang as a slow scatter of chips where the bracket was. Let the hero leave sooner, so the end is as hard as the start (serves: a hit that lands and is done).
  - **Accepted:** the ink rim for the bright floor; no glow on the sheet (bloom is the builder's); the cracks' regularity, which reads as a cracked stamp at play size; frame 59 hidden behind his body, with the strike's square carrying it.
  - **The content check's open item** stays open for the builder's replay: the front and three-quarter headings at 64 px.
- **The verdict, as made** (Modulo, 2026-11-12): the wake and its tint are out of the script and the sheet. The hero is eaten over 6 frames, not 12, and the floor's lines leave 2 frames sooner, so nothing is left by frame 76. The bar's picture is unchanged. The numbers above are the ones now played.
- **Content re-check, 2026-11-12, on the sheet without the wake:** PASS, same conditions (the scorch no redder, on the floor only; hard edges; a new shape, tint or texture, or the wake back, needs a fresh check; the front and three-quarter headings still owed on the replay).
- **Delivered** to `build/handoff/Rook/fx/`: `haymaker_bar.png` and `haymaker_art.png`. Faber: the replay is yours; I join it in the same session when you say (`/ga-action`, step 4).
- **Hours:** the art sheet, 0.4.
- **Found on AR2, not changed here (Modulo, 2026-11-12):** Roblox multiplies a glow by the colour map (AR2, section 4), and Rook's sheet drew the lit ram in the tint alone. By the formula, the knuckles and the rod (ember over steel) come out about half as bright as the sheet at the recipe's 2.5, and the heat band (ember over ember) redder than ember. Nothing is rebaked while the Haymaker's final is with research: the fix is AR2's (a neutral tone under the lit parts, the mask rescaled, the two maps uploaded again), about half an hour, when the builder and research say. Until then the builder's live strength covers the brightness, not the band's hue.
  - **Research: yes, 2026-11-12,** with the builder's yes. The rebake goes after Lyric's clips and before Rook's maps upload, so they upload once. The ram's strength is tuned on its own on Haymaker's replay, not copied from the Shade's pick: the Shade's edge is a steady type colour, and the ram is a heat ramp whose peak may rightly run toward white.
  - **The rebake, made** (Modulo, 2026-11-12; made on Opus 5.5 xhigh). The record:
    - **Only `Rook_Emissive.png` and the recipe changed.** The eight meshes and the colour, roughness and metalness maps are byte for byte the ones in `build/handoff/Rook/`. Faber: upload the glow mask with the others, and nothing else changes.
    - **What changed:**
      - The mask is now the sheet's light over the strength and over the colour map's brightness under it (`encode_glow` in `tools/blender/rook_model.py`), as the Shade's is.
      - The recipe's `hot` is 10, where it was 2.5. At 10 the ram shows the light the sheet designed. 35% of the lit texels fall short of it: the crevices, whose baked shading is too dark for the strength. Their glow stays darker in the shade.
    - **One call against my own proposal (tier 1): the band keeps its ember.** I had proposed a neutral tone under the lit parts. Through the formula, a try of the gauntlet, cold and lit, settled it (`build/scratch/modulo/rook/try/ram_glow_try.png`).
      - **The tries:** the colour under the band was ember (kept), steel, iron or bone, each with the mask encoded.
      - **Ember kept:** cold, the band is the ring of ember he wears at rest. Lit, ember over ember reads within a hair of the sheet: a touch deeper orange than the knuckles, toward the wrist. In a heat ramp that's the right way round.
      - **A neutral or light tone instead:** it would turn the band steel, iron or bone at rest, for almost nothing lit. Iron goes brown.
      - **The knuckles were the real fault.** With the delivered mask they came out a dull tan, about a third of the sheet's light. Now they match it.
    - **The sheet** (`build/scratch/modulo/rook/model/rook_model_sheet.png`) now draws the lit ram through the colour map, at the preview's 1.4 of the design's 2.5, as before. Its two lit views can't be told from the sheet research read.
    - **What I see wrong:** it's two Blender pictures and Roblox's published formula, with no tone mapping or bloom. The 10 is a start for the replay, where research tunes it. Every glow scales with it.
    - **Content check, 2026-11-12: PASS** on the new mask, the sheet, the try and the recipe. The lit colours run from ember to cream, nothing goes red, and no glow sits on skin or cloth. To hold:
      1. The tint stays `#FFA630`, on the ram and the piston only. A new tint, a strength above 10, or a new colour under the band gets a fresh check. Through the ramp from 0 to 10, the band never shows deeper than the delivered maps' orange (the try's second column).
      2. On Haymaker's replay, the lit ram is looked at in the engine at 64 px, with bloom if it's on, from the front and three-quarter headings, with Haymaker's own owed headings. Bloom must not spread the band or the knuckles into a soft glow or a trail on the arm.
      3. The AR1 and Haymaker conditions stand. The new mask is logged in `docs/asset-log.md` at upload, and replaces the old one if that was ever uploaded.
    - **Delivered** over the old files in `build/handoff/Rook/`: `Rook_Emissive.png`, `Rook.recipe.json`, `rook_model_sheet.png`.
    - **Hours:** about 0.5, the try included.

### 6. In the game: Rook's body (Faber, 2026-11-12)

- **The uploads,** for the group, all Approved: the eight meshes by `ModelAssembly.PublishMesh` from the place, the four maps by `tools/upload/upload_asset.py`. The glow mask is the rebake's (section 5's last entry); the old one was never uploaded. Ids in `docs/asset-log.md`.
- **The template:** `tools/studio/Models/Rook.luau` builds him on R6 from the recipe. The six parts are hidden with a mesh welded to each. `Rook_Piston` and `Rook_Tape` ride Motor6Ds named `Piston` and `Tape`, and the `Knuckles` and `RamCentre` attachments sit on the Right Arm. It's serialized to `src/storage/Rook.rbxm` (`ServerStorage.Templates.Rook`); read back in Studio: 14 joints, none broken.
- **The lead wears it:** a Voidkin row's new `Model` names its template (`Definitions.Voidkin`, Rook's row). `FightService`'s `buildLead` clones it, or the grey R6 stand-in for a row without one.
- **The clips** are imported again with the two joints keyed (`Author`'s `HELD` puts the piston under the Right Arm, the tape under the Left Arm), saved in the place as `NL_Rook<Clip>`.
- **The glow** is cold at rest: strength 0, tint `#FFA630` on the ram and the piston only. Haymaker's wind-up lights it 0 to 10 on the replay (delivery 4), where research tunes the 10 and section 5's engine look is owed (64 px, front and three-quarter, bloom).
- **Self-test case:** "Fight: Rook's lead wears his model". It checks the rig hidden and the eight pieces shown, the two joints on their arms, and the piston's 0.65 draw in Haymaker's clip. Over one idle loop it checks the tape swinging (about 9°) and the piston staying home.
- **Section 2's checks,** in play mode on the test pad (grey daylight, no bloom):
  - the rig is hidden;
  - a clip is always playing, and the idle holds the ram off the hip;
  - the iron doesn't read flat: its faces keep lit, side and shade values, and the bolts and band read;
  - no shell flickers at play distance.
  - Haymaker frozen at the wind-up holds together, with the piston drawn 0.65 and the ram cocked; at the strike the piston is home.
- **Not done:** section 3's pose dump against the export (`tools/blender/r6parity.py compare`). It goes with the replay.
- **Tests:** Fight cases 117/117 at 60 fps; logic 1,376; type check, 0 new.
- **Hours:** about 0.8.

### 7. Haymaker's replay: the ram's heat and the engine looks (Faber, 2026-11-12)

- **Scope.** In it: the ram's glow on the clip's markers; the engine looks the content check was owed (section 5's headings at 64 px, and the rebake's conditions 1 and 2); section 6's pose dump. Waiting: the sound, research's final in motion with its tune of the peak, `ga-fresh-eyes`, Modulo's look on the replay (`/ga-action`, step 4).
- **The glow** (`Config.Effects.Haymaker.Glow`, played by `Effects.Haymaker`):
  - Cold until Charge, where it steps to `Step` (3).
  - It curves up to `Peak` (5) by Strike (`Rise` 2) and holds through the hitstop to Shock.
  - It curves back to 3 (`Fall` 2) and steps to 0 at Vent.
  - `Rook_RightArm` and `Rook_Piston` light alike, tint `#FFA630`.
  - The code keeps the lit strength between 3 and 5, whatever is tuned: the check's bounds, below.
  - Tuned live with `NL_Debug:Invoke("Tune", "Effects.Haymaker.Glow.Peak", n)`.
- **The engine looks.** The replay frozen on the beat, under the game's lighting (bloom 1, 24, 2), in `build/captures/ar1/`:
  - `haymaker_fires_64.png` and `_256.png`: Strike, Shock, and 4 and 8 frames on, from eight headings.
  - `ram_glow_strip_close.png` and `_64.png`: strengths 0 to 10, front and three-quarter.
  - `ram_band_ramp.png`: the heat band at 90° and 150°, strengths 0 to 10.
  - `ram_band_step.png`: the band from behind-right, cold, at 3 and at 5, in one pose.
- **What they measured.** The band's hue is the median over its lit pixels; cold, it's 34.7 at 90° and 37.0 at 150°.
  - At 0.5 to 1.5 the band goes deeper than cold: 31.2, 32.0 and 34.1 at 90°.
  - From 2 up it's warmer: 36.3 at 2, 40.2 at 3, 51.1 at 5.
  - Bloom puts a soft halo on the knuckles and band at 10, a slight glow at 7.5, and none at 5 or below.
- **Content check, 2026-11-12:**
  - "It fires" at 64 px from all eight headings: PASS. Section 5's owed item is closed.
  - Condition 1, BLOCK with a smooth ramp from 0, since below about 2 the band reads deeper than cold. Fix: step 0 to 3 at Charge and 3 to 0 at Vent, confirmed at 3 from behind-right, median 37.0 or more.
  - Condition 2, BLOCK at 10, where bloom haloes the band and knuckles (7.5 doesn't clear either). Fix: a peak of 5, with the code's ceiling at 5.
  - Both fixes are made. The confirmation, in one pose and one session, with the deepest tenth in brackets:

    | Strength | Median | Deepest tenth |
    |---|---|---|
    | Cold | 37.4 | 35.3 |
    | 3 | 40.3 | 36.1 |
    | 5 | 47.4 | n/a |

    Condition 1 holds. At 5, the check accepts the bloom fringe's deep pixels.
  - To hold: the ram stays lit between 3 and 5. Above 5 needs a moving capture for the trail and a fresh check. A halo at 10 would change condition 2, which is the director's call.
- **Section 6's pose dump:** `r6parity.py compare` at seven times from 0 to 1.5 s: PASS, worst 0.0004 studs and 0.012°.
- **The replay's freeze, fixed (tier 1):**
  - The clip sat up to the clock's 0.05 s drift short of `FreezeAt`. A frozen look showed the effect on its beat and the pose about 1.4 frames early.
  - A freeze now puts the clip on the clock.
  - The looks above were shot before the fix; the confirmation, after it.
- **Self-test:** "Fight: Haymaker's look" checks the glow through the press:
  - cold before Charge, and 3 on Charge;
  - halfway up, with both pieces alike;
  - 5 on the strike, then halfway down;
  - 3 or more a frame before Vent, and 0 at Vent.
  - The results: Fight cases 130/130 at 60 fps; logic 1,376; type check, 0 new.
- **The take:** `build/captures/ar1/haymaker_replay_step.mkv`, 11 s at 59 fps from the player's camera, at 3 and 5.
- **For research:** the peak is yours to tune between 3 and 5. The step at Charge, where the ram lights in one frame, is a feel call. It's the check's fix: a smooth ramp would need the director to loosen condition 1.
- **Hours:** about 2.
- **Research's read of the replay, 2026-11-12** (haymaker_replay_step.mkv, every second frame of a press, and four full frames). **The glow:** the peak stays at 5, the top of the check's band. The knuckles read hot at the strike, with no halo. **The step at Charge: accepted.** A piston ram lighting in one frame reads as ignition, which suits it better than a ramp. **The look in motion:** the square boils on the fist, the strike sparks, the bracket is thrown and eaten in about 0.2 s, and the number lands in it. It's a hard, clean hit. **The final isn't signed on this take**, because of its staging. In it Rook stands between the camera and the dummy, so the bracket frames Rook. In the game the lead stands beyond its target, turned `Combat.Lead.Frame` (TR2, fix 1), so the player sees the target in front and Rook punching back toward the camera. **Ask:** the replay staged as the game frames it (the avatar's camera, the target nearer, Rook beyond it at the Frame's angle), one press, with the sound when it's in. Research signs the final on that take, and `ga-fresh-eyes` and Modulo's look read the same one.
- **Modulo's look on the step take, 2026-11-12** (`haymaker_replay_step.mkv`, the first press frame by frame from 1.40 to 2.36 s): nothing to change in the bar on this take.
  - The charge's square forms round the ram's face and holds tight, face-on to this camera, its ink rim holding it on the pad and on Rook's red. The heat band reads cream at 3 and hot at 5 on the strike, as the art sheet meant.
  - The bracket lives about 23 frames from the throw to gone, the last six eaten: the eight frames read as the bar breaking into chips, never a smear or a fade.
  - In this staging it flies away from the camera, so for its first ten frames it's an edge-on strip at Rook's right, and the floor's lines are a short dark stub by his foot.
  - To read on the staged take: the bracket face-on and coming at the camera, with the number still landing in it; the floor's lines along their length; and the last eaten frame, where the chips are dark dashes over the sky here. Nearer the camera, if their rims read as a dark lattice, frames 7 and 8 get a thinner rim: mine, then a new upload and a check.

### 8. Haymaker staged as the game frames it, and its sound (Faber, 2026-11-12)

- **Scope.** In it: the replay restaged as research asked (section 7, its read); the strike's sound, one library cue; one staged press. Waiting: research's final on this take, Modulo's look on it, and the director's ear on the cue.
- **The staging** (`ReplayService`; `Config.Combat.Replay`):
  - The dummy stands at the pad's middle.
  - The avatar stands `Replay.Behind` (9) behind it and `Lead.Side` (3.5) to the left, facing down the pad.
  - Rook stands beyond the dummy at the action's spacing (`Range - Approach`), turned `Lead.Frame` (45°) toward the avatar's right, facing the dummy. That's `Fight.Beyond`'s spot for a lead that walks in on the avatar's right.
  - The camera is unchanged: behind the avatar, pitched 20°, at the player's zoom.
  - Straight behind the dummy, the avatar's head hid it at this pitch, hence the side step.
- **What this staging shows that the old one hid:**
  - The push runs from Rook through the dummy, so the hit throws the dummy about 6 studs toward the camera's left. It stands behind the avatar until the next press resets it.
  - The bracket's line runs the same way. To this camera it's 35° off face-on, and it passes over the avatar's left shoulder, where the head covers part of it.
  - Both are the game's own rules (the Frame, the push, the line through the target), now aimed at the player. Nothing was changed for them.
- **The sound:** `Config.Sounds.Cues.HaymakerStrike`, played by `FighterController/Sounds`.
  - It plays on the strike's frame, at the knuckles, through one SoundGroup (`NL_Combat`), and every cue is preloaded at start.
  - The source: ProSoundEffects' "Metal Impact Heavy Clunking Hits Scraping 3 (SFX)", 9116673915, its third hit, 2.35 to 3.05 s.
  - Measured: attack 0.00 s, -20 dB at 0.17 s, -40 dB at 0.80 s; low 46%, mid 45%, high 10%; -5.8 dBFS, levelled to -14.
  - Played at a pitch of 0.96 to 1.04, at full volume within 30 studs and gone by 160.
  - Found with the handbook's audio tools, now in `tools/studio/Audio` (`Briefs` holds the cue's brief). It ranked fourth of eight on shape. It was picked over the top three: two short wooden knocks, under -20 dB by 0.08 s and small for a signature, and a clunk that holds full level for 0.36 s, which is a scrape, not a punch.
  - Alternates: 121062167179910, "heavy thud kick 1", a community upload; and 9116673678, the same set's first.
  - Provisional until the director's ear accepts it: `NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it in a fight.
- **The take has no sound.** The recorder takes the picture only, and this PC has no loopback device, only the microphone, which stays unused. The cue's timing is proven by the self-test: none before the strike, one on its frame, none again through the hitstop. In the game it loads and plays, with no permission error in Output.
- **Checks:** self-test Haymaker 22/22 at 59 fps, replay 11/11 at 60 fps. Logic 1,382: a new case checks every cue is whole, levelled within 0.25 to 2, and that Haymaker's cue resolves. Type check, 0 new.
- **The take:** `build/captures/ar1/haymaker_staged_press.mkv`, one press, viewport only, 2.4 s at 59.2 fps. The press starts at 0.15 s and the strike lands at 1.10 s. It's cut from `haymaker_staged.mkv` (8 s, three presses). Inside the press, two frame steps run 33 and 34 ms: at 0.75 s in the wind-up, and at 1.72 s after the bracket is gone.
  - `haymaker_staged_strip.png`: every second frame, from 0.32 s before the strike to 0.38 s after it.
  - `haymaker_staged_full_<s>.png` at 0.70, 1.10, 1.17 and 1.27 s: the wind-up, the strike, 4 frames after, 10 frames after.
- **`ga-fresh-eyes`, blind, on the strip and the four frames** (judged against the feel line alone, picture only):
  - **Felt:** "a hollow gold outline swings up and leans off to the left behind the avatar's head, hangs there and breaks into dashes. It reads as a frame or crane arm tipping over. It doesn't read as a square face driven along the ground through the target."
  - **Tier:** works. "The hit registers through the number and the sparks, but nothing stamps." The square stands upright, it moves sideways instead of out through the target, the dummy doesn't seem to react, and the avatar hides much of the shape.
  - **The one bold thing:** none carries it. The gold outline at 1.17 and 1.27 s pulls the eye away from the punch and the target.
- **For research, the levers I can turn live, none turned:**
  - The bracket's lean (`Hero.Lean`, 16°, set for a side view). Coming at the camera, it reads as tipping over.
  - The line's aim: through the target (the design), or toward the lead's own avatar. That second one is a change of direction rule, so it's yours and Modulo's.
  - The Frame itself (`Lead.Frame`, TR2) is outside this piece.
- **Hours:** about 1.5.
- **Modulo's look on the staged take, 2026-11-12** (the strip and the four full frames). I agree with fresh eyes, and the cause is the bracket's geometry for this camera, not the bar. The bar reads: gold chips in their ink, cracked, hard-edged on the pad. Three changes, one at a time, the first two live:
  1. **`Hero.Lean` to 0.** I set the lean for a side view. Coming at the camera, the same 16° tips the square back, so its lintel slants up and away and it reads as a crane arm. If the builder would rather keep the side view's lean, the rule is the lean times how side-on the line is to the camera: 0 face-on, 16 side-on.
  2. **`Hero.Reach` so the bracket stops just past the target**, not 8 studs on. Here it has passed the dummy by 1.10 s and does all its hanging and eating over the avatar's left shoulder, where it's nearest, so biggest, and the head covers it. Stopped a stud past the target, it frames the target while it's eaten, the target is pushed out through it, and it stays at the fight's depth. Its size at the line's end then wants to be about the target's outline plus a margin: `WidthGain` and `HeightGain` cut to suit, tuned on the replay.
  3. **Frames 7 and 8, after those two.** At 1.27 s the last eaten frame's chips and their ink rims read as a dark chain over the floor: the lattice I was watching for. At the target's depth they're about half that size, so judge them there first. If they still read as a chain, I thin those two frames' rims; it's a new picture, its content check and an upload.
  - The aim stays through the target (the design). Aimed at the avatar, it would come into the player's face even more.
  - The floor's lines run toward the camera here, a short dark stroke from the dummy: fine, nothing to change.
- **Research's read of the staged take, 2026-11-12** (the strip, the four full frames). **Felt:** the wind-up, the sparks and the number land together on the dummy, then a gold frame swings off over the avatar's shoulder and takes the eye from the hit. **Tier:** works, beside fresh eyes'. That's under the pass line, and a signature aims higher. **The one bold thing:** the strike's frame (1.10 s), the sparks and the number on the dummy. The hero doesn't carry it on this take.
  - **The cause, as Modulo reads it:** the hero was built for a camera behind Rook, and TR2's Frame turns him to face the player. The bar, the art and the timing aren't at fault.
  - **The feel line's camera clause follows TR2:** "seen from behind him" becomes "seen from the player's side of the target". The rest stands, the aim through the target included.
  - **Modulo's fixes 1 and 2: yes,** in its order, with its size note. The lean goes by how side-on the line is (0 face-on, 16 side-on), so a side-on line keeps it. Serves: the stamp lands on what was hit, at the fight's depth, with the number in it. Fix 3 is judged on the retake.
  - **Next:** the builder turns them live and shoots one press, staged the same way. Fresh eyes reads it blind, and Modulo reads it too. Research signs the final on that take. This is the first fix round on the hero in the game's framing.
  - **The sound** waits on the director's ear (the Now board). The take is silent, so research doesn't judge it.
- **The retake, Faber, 2026-11-12.** Fixes 1 and 2, turned one at a time on the replay.
  - **Found on the way: every replay take so far missed the target.**
    - The replay held its target on the server only (`ForcedTarget`), and the client reads the `Target` attribute.
    - So the effect's line fell back to Rook's facing from his knuckles: parallel to the hit, 2 studs to its side.
    - The staged take's bracket, and the ones before it, passed beside the dummy, never through it.
    - In play the attribute is set, so the game itself wasn't affected.
    - Fixed in `FightService`: the attribute shows the held target first. A check in the replay's self-test case covers it.
  - **Fix 1, the lean:**
    - `Hero.Lean` is multiplied by how side-on the hit's line runs to the camera, read once at the strike. It's linear in the angle: 0 face-on, 1 side-on.
    - In the game's framing the line runs at 45° to the camera, so the bracket leans 8°.
  - **Fix 2, the reach:**
    - The line ends `Hero.Past` (1 stud) beyond the target's centre. `Hero.Reach` (8) is now only for a press with no target.
    - The bracket faces down the hit's line (Rook's body to the target, the line the server pushes along). Before, it faced down the knuckles' line, about 30° off.
    - Facing the knuckles' line, the dummy left past a post. Facing the hit's line, it's driven out through the opening.
    - It still flies from the knuckles, so nothing jumps.
  - **The size:**
    - `WidthGain` goes from 3.6 to 2.8. The end frame's opening is the dummy's 2.6-stud width plus about half a stud each side.
    - `HeightGain` stays 3.4. From this camera the lintel already clears the dummy's head with a margin, and cutting it would close on the head.
  - **Checks:**
    - Type check: 0 new. Logic: 1382 pass.
    - Self-test "Haymaker's look": 26 pass, 3 of them new:
      - Aimed, the bracket ends Past beyond the target, down the hit's line (0.000 studs off).
      - It stands square to that line.
      - It leans by how side-on the line runs to the camera (3.0°, want 3.0 from the test's camera).
    - "The replay lands each hit": 12 pass, 1 new: the lead is aimed at the dummy.
  - **The take,** staged as before, in `build/captures/ar1/`:
    - `haymaker_retake_press.mkv`: one press, 2.4 s, the strike at 1.10 s.
    - `haymaker_retake_strip.png`: every second frame, from 0.32 s before the strike to 0.38 s after it.
    - `haymaker_retake_full_<s>.png`: at 0.70, 1.10, 1.17 and 1.27 s.
  - **`ga-fresh-eyes`, blind, on the strip and the four frames:**
    - **Felt:** "a hollow gold frame springs up around the target, swells toward the camera, then crumbles into tiles. It reads as a gilded doorway opening over the dummy, not as a solid face driven along the ground, and the dummy only turns after the effect has gone."
    - **Tier:** works. "It reads clearly as a hit with a shape of its own, but it has no weight and no travel: nothing is thrown through the target and nothing stamps down."
    - **The one bold thing:** none. The eye goes to the upright arch round the dummy at +4 frames. "The strike itself, a small white spark behind the dummy, is hidden from the player's camera."
  - **What I see, for research:**
    - The bracket is now where Modulo asked: round what was hit, at the fight's depth, and the dummy goes out through it.
    - What it lost is travel. From the knuckles to a stud past the target is about 3.3 studs, mostly in the first three frames, so it reads as rising in place.
    - Two causes sit outside the bracket:
      - From this camera the punch lands on the dummy's far side, because TR2's Frame puts the lead beyond the target.
      - The push carries the dummy toward the avatar, which hides it in the last frames.
  - **Levers, none turned:**
    - `Hero.Past`, now 1. More gives travel, and brings the bracket nearer the camera.
    - `Hero.Fly`, now 10 frames.
    - The Frame (TR2), which is outside this piece.
  - **Hours:** about 1.5.
- **Research's read of the retake, 2026-11-12** (the strip, the frame at 1.17 s). **Felt:** the ram's squares flash on the strike, then a gold doorway stands up round the dummy and crumbles, and only then does the dummy turn. **Tier:** works, beside fresh eyes'. The bracket now sits where it should, round what was hit and at the fight's depth. What's missing is the hit carrying anything. **The one bold thing:** none yet. The frame at 1.17 s, the dummy standing inside the gold, is the nearest to it.
  - **The two things missing, both the hit's and not the art's:** the bracket has no travel (3.3 studs, mostly in 3 frames, toward the camera), and the dummy reacts after the effect is gone, so nothing is driven through anything.
  - **Fix round 2, the last on this idea (the thrown frame in the game's framing):**
    1. **The push rides the bracket:** the dummy's knock starts on Shock and runs with the bracket's flight, so the target is carried out through the frame while it's lit. Serves: a hit that lands. That's a knockback curve, so it's the builder's lever.
    2. **Travel you can see:** `Hero.Past` up from 1, tuned live between 2 and 3, so the frame is seen passing over the dummy and out its near side, and stops clear of the avatar. `Hero.Fly` stays 10.
  - **Beside it, evidence only and nothing changed in the game:** one press with the lead at `Combat.Lead.Beside`, the keeper's spot, staged the same way. The bracket was built for a side-on line, and that take shows what it does there.
  - **If round 2 still reads "works":** the options go to the director with both takes: accept it, take the side for a signature, or start a new blockout (the stamp driven down from above, which reads from any camera).
  - **Earlier takes:** every line before this retake ran 2 studs beside the dummy (the builder's finding above), so the staged take's read stands only for the lean.
- **Modulo's look on the retake, 2026-11-12: fix 3, the last two frames' rims.**
  - **What I saw:** at 1.27 s, at the target's depth, the last frames' chips still read as a dark lattice. Each chip's full ink rim, with the dummy's black body showing through the gaps, makes a grid over it. Round 2's `Hero.Past` brings the bracket nearer the camera, so the chips get bigger there, and so does the grid.
  - **The change:** frames 7 and 8 (the sheet's 6 and 7, 72 and 86% eaten) get a finer rim: 0.075 and 0.05 of the stroke's depth, from 0.12. They now read as scattered gold chips. Frames 1 to 6 are byte-identical to the uploaded picture. The size, the order and the eaten shares are unchanged.
  - **Where:** `build/handoff/Rook/fx/haymaker_bar.png`, with its sheet `haymaker_art.png` beside it. The rim depths are `INK` in `tools/blender/rook_haymaker_art.py`.
  - **Content check:** PASS, 2026-11-12. At 64 px the last frames read as gold flecks round the bracket, not a chain and not drops. Nothing red.
  - **For the builder:** upload it under the group (`tools/upload/upload_asset.py`), then swap `Config.Effects.Haymaker.Picture`. Nothing else changes.
  - **Round 2's levers** are the hit's, and I agree with both. The bar holds at the new depth.
  - **Hours:** about 0.5. Made on Opus 5.5 xhigh.
- **Fix round 2, Faber, 2026-11-12.** Both fixes in, then the two takes and two blind reads.
  - **Fix 1, the push rides the bracket:**
    - Found: the server already pushed on Shock, where the hold ends. What the screen lacked was time: a body the server moves reaches a client a replication delay later, measured at about 0.2 s in Studio and longer with ping. So the dummy turned after the bracket had gone.
    - Now each client draws every hit's push itself, from its own hold's end, at the server's pace (`Combat.Push.Seconds`, 0.1). It draws only what the replica hasn't brought yet, and hands the body back once that catches up. A push that never fully arrives (a wall) is let go over `HandBack`, `Wait` after the push ends. Lever: `Combat.Push.Shown`, on. The math is a pure rule, `Fight.KnockAhead`.
    - The server's push is now exact. It's steered each frame by what's left, and it stops dead. Before, it slid on and ended 3.6 to 5.6 studs for a push of 4. Now it ends at 4.02 to 4.10.
    - Measured on the replay: the dummy goes 0 to 4 studs over 6 frames from the bracket's second frame, all inside its flight (`Fly`, 10).
  - **Fix 2, the travel:**
    - `Hero.Past` was tuned live at 2, 2.5 and 3, and set at 2.5.
    - At every value, the frame's near post passes behind the avatar's head at its peak, least at 2. Past can't put it clear of the avatar.
    - The cause is TR2's Frame. The push runs from the lead, through the target, toward the avatar, so wherever the bracket ends, the dummy ends behind the avatar's head.
  - **Fix 3, Modulo's rims:** uploaded under the group as 82029716338204 (Approved), and `Picture` swapped (`docs/asset-log.md`, row 9).
  - **The takes,** in `build/captures/ar1/`, cut the same way as the retake: `haymaker_round2_press.mkv`, its `_strip.png` and `_full_<s>.png`, and `haymaker_round2_beside_*`.
    - The Beside take tuned `Combat.Lead.Frame` to 90 live for the take, then put it back at 45. The replay places the lead by `Frame`, so 90 there is the Beside spot. Nothing in the game changed.
  - **`ga-fresh-eyes`, blind, one read per take:**
    - **Staged.**
      - **Felt:** "a gold inverted-U frame swings up out of the target, widens toward my side until it arches over the dummy and the top of my avatar's head, holds for about four frames, and crumbles into chips. The dummy never flinches… it plays as a gold gate that blooms and dissolves, not a face driven along the ground like a pile driver."
      - **Tier:** works.
      - **The one bold thing:** the full-width bracket at 1.10 to 1.17 s, "an arch standing up on the near side of the slab, not a square face driven flat through it. At 1.27 s its left leg also hides behind the avatar's head."
    - **Beside.**
      - **Felt:** "the 'square face' breaks into a dim tilted slab, a thin gold needle flicking up behind the avatar's head and a dark hairline on the ground… none of it is thrown along the ground."
      - **Tier:** works.
      - **The one bold thing:** none. The strongest shape is the charge's square behind Rook, before the hit.
  - **What I see, for research:** both takes still read "works", so by your line the options go to the director. Three facts for that:
    - **Staged, the knock can't be seen at any timing.** The dummy is now carried through the lit frame on time, but it slides toward the avatar and behind it. "Never flinches" is the dummy hidden, not still.
    - **Beside, the bracket is edge-on.** It stands square to the hit's line, and from the avatar's place that line runs across the screen.
    - **So the upright thrown frame reads only when the hit runs away from the camera,** and the game frames none of its fights that way. That counts for the new blockout, the stamp driven down from above.
  - **Checks:**
    - Type check: 0 new. Logic offline: 1400 pass, 18 of them new (the drawn push: the hold, its pace, Push × weight by the push's end, never drawn back, the hand-back, the let-go).
    - Self-test "Fight": 137 of 137 on the second full run. The first had one fail, "a Shade swings and flinches on alternate sides": two AttackLefts in a row in 11 swings. It passed 3 of 3 alone and on the rerun. It's an intermittent, queued with the HUD and Base ones.
  - **Hours:** about 3.
- **Research's read of round 2, 2026-11-12** (both strips). **Felt:** staged, the push now rides the lit frame on time, and both slide behind the avatar's head. Beside, the frame is a needle. **Tier:** works on both, beside fresh eyes'. **The one bold thing:** none. **Two rounds are spent on the thrown frame, so it isn't patched again.** Haymaker stands in the dev build as it is.
  - **What the rounds proved:** an upright frame thrown along the hit reads only when the hit runs away from the camera. TR2's Frame sends every lead's push toward the player, so no fight the game frames shows it. That holds for any effect thrown along a hit, not only this one.
  - **The options for the director:**
    - **A. Keep it at "works"** until the whole-game review. Costs nothing, but a signature stays under the bar.
    - **B, research's pick. A new block-in: the ram's square driven down from above** onto the target, the same one bar. A downward blow reads from any camera, and a pile driver strikes down. The art is reused. Cost: a block-in, about half an hour for Modulo, then about 1 to 2 hours for the builder's new path.
    - **C. Frame a signature differently** (the lead's spot or the camera). The Beside take argues against it: from there the frame is edge-on. A camera move would touch every action.
  - **Meanwhile, tier 1:** Modulo blocks out B after its current piece, so the director picks from pictures, not words.

### 9. Haymaker's B: the block-in (Modulo, 2026-11-12)

A tier 1 exploration for the director's pick between the options above. Nothing gets built until the director picks.

- **Where:**
  - The script: `tools/blender/rook_haymaker_stamp.py`.
  - The sheets: `build/scratch/modulo/rook/stamp/`.
    - `stamp_B1.png` to `stamp_B5.png`: the game's camera, 16 frames each.
    - `stamp_side.png`, `stamp_beside.png` (an elite's spot, 90), `stamp_hidden.png` (the avatar dead on) and `stamp_bright.png`.
    - `stamp_64.png`: no labels over the tiles, since the square falls through the top. One row a variant, B1 to B5; the frames 52, 54, 55, 56, 57, 58, 60, 64 and 70; drawn 3 times over.
    - `stamp_headings_B3.png` and `stamp_headings_B5.png`: the same staging turned round the target every 45°.
  - **The staging:** Rook plays his delivered Haymaker clip, and the target stands at the hit's Range, 6. The game's camera has the lead beyond the target, turned 45° (`Combat.Lead.Frame`); it sees Rook 43° off his front from 23.9 studs, and the target from 20.
  - **The stand-ins:** grey boxes, every square four of the bar's strokes, side 4.6 and bar 0.85. It falls from 10 studs over 4 frames and lands on Strike (57). The target is pushed as the game pushes it, 4 studs from the bracket's second frame.
- **The variants:**
  - **B1, the drop:** the square lies flat, falls onto the target and stamps the floor round its feet. On Shock it kicks open and a thinner square runs out along the floor.
  - **B2, the weight lifted:** B1 with a tell. Through the hold, the flat square forms over the target's head and is hauled up to the top of its drop.
  - **B3, the drop and its shaft:** B1's fall stretched along its travel, a chute of light for the frames it falls.
  - **B4, the face slammed down:** the square stands up turned to the camera, so its face always shows. It drops stretched tall, lands round the target's legs on Strike and squashes flat on Shock, and two bars run out along the floor from its feet.
  - **B5, the face lifted and slammed:** B4 with B2's tell. The upright square hangs over the target through the hold, drawn tight, then slams.
- **The measures,** the share of the game's screen at 70°, in percent:

  | Frame | 53 | 55 | 56 | 57 Strike | 58 Shock | 60 | 64 | 70 |
  |---|---|---|---|---|---|---|---|---|
  | B1, B2 | 0.73 | 0.37 | 0.48 | 0.41 | 0.45 | 0.28 | 0.14 | 0 |
  | B3 | 0.73 | 1.42 | 1.85 | 0.41 | 0.45 | 0.28 | 0.14 | 0 |
  | B4, B5 | 1.89 | 1.86 | 1.54 | 0.57 | 0.51 | 0.32 | 0.15 | 0.06 |

  B2 and B5 match B1 and B4 from 53 on: their tell comes before.
- **My read: does a downward blow land the pile driver from any camera?**
  - **The fall, yes, from every heading.** The game's camera looks down at 14°, so straight down stays straight down on screen at every heading in the headings sheets.
  - **The square, only if it stands up.** The camera's eye is about 7.6 studs up, and the fall runs from 10 to 0, so a flat square (B1 to B3) is edge-on through the fall: a sliver at 0.4 to 0.5% of the screen. On the floor, seen from 20 studs, its depth shrinks to about a third: a squashed diamond. B3's chute reads as a block of light falling, not a square. Upright and turned to the camera (B4, B5), the square shows its whole face all the way down: four times the flat square's share. B4 and B5 are the only ones where Haymaker's one bold thing keeps its face, and the only ones that read as a square at 64 px.
  - **The landing, no, from most cameras.** On Strike the stamp is at the target's feet, the part the avatar covers. The game's camera sees one corner beside the avatar's shoulder. The hidden camera sees nothing in B1 to B3 and a sliver in B4 and B5. In every variant the landing is 0.4 to 0.6% of the screen. So the fall carries the read, and the landing doesn't.
  - **The clip doesn't strike down.** Rook's Haymaker punches straight forward and stops 3.4 studs short of the target (the knuckles at 2.65 forward on Strike). A square dropping from above is at right angles to his blow. The timing joins them, since both land on 57, but it reads "he punched, and something fell on the Shade": a blow called down, not his own. For a pile driver that's his, the strike would go down: a new block clip on the same markers, Strike kept on 57, about an hour of mine. That's a clip change on a signed action, so tier 2.
- **Proposed feel line (B5, with the clip striking down):** "Through Rook's long hold a square of light hangs over the Shade, drawn tight, and as his blow comes down it slams straight onto it and stamps the floor at its feet, the Shade pinned where it stood."
- **My pick: B5, if the director picks B,** and with the clip striking down.
  - **Why:** its face shows from every heading, and the hang puts the eye on the square before the 4-frame fall. Without the hang, B4's fall is three frames on screen (54 to 56) at 60 fps and can blink.
  - **With today's clip:** B5 is still the strongest picture. Then the director is picking a blow called down, not a pile driver.
- **What I see wrong, for the build if B is picked:**
  1. **The push slides the target out of its stamp** toward the avatar (Push 4), so the stamp is left on an empty floor. A pile driver pins. Push 0, or a squash in place, is a number on a signed hit: tier 2, research's and the builder's.
  2. **The hung square's top touches the top of the game's frame** at 52 and 53 (it hangs 10 studs up and is 4.6 tall). Hang it about 2 studs lower.
  3. **The landing is mostly covered** (above). If the director wants the impact itself seen, it has to reach above the avatar's shoulders: the bars along the floor don't.
- **Content check:** PASS, 2026-11-12, on the sheets and the script. Conditions for the art stage:
  1. The upright frame never lingers, slows or holds at the head or neck, and is never drawn as a collar or a hanging frame. It passes the head in one frame and lands at the feet. B5's hang stays well above the head.
  2. The light stays hard-edged and geometric, crisp strokes and fades, never a soft pool, smear or puddle on the floor in any colour.
  3. No glyph inside the square without a fresh check.
  4. A new check on the finished art before any upload, with a 64 px sheet at every heading.
- **Not done:** no art, no clip, nothing in the game.
- **Hours:** about 1.5, over the half hour asked, for B4 and B5 and the headings sheets. Made on Opus 5.5 xhigh.
- **Research's read, for the director's pick, 2026-11-12** (B5, its headings, the 64 px sheet). Not a verdict: nothing is built until the director picks.
  - **Felt (B5):** a square of light hangs over the Shade through Rook's hold, then drops onto it on the blow. The hang and the fall read from all eight headings, face-on.
  - **The pick within B: B5.** It's the only one that keeps the square's face at 64 px and gives the eye a place to wait. B4 is its fallback, if the hang reads as a tell the Shade should dodge.
  - **What B costs, more than first said:**
    - Modulo's block clip striking down, about an hour, tier 2.
    - The Shade pinned under the stamp rather than pushed out of it, tier 2, decided at the build.
    - The landing at the feet mostly behind the avatar. The hang and the fall carry the read, and the impact itself is seen only beside the avatar.
    - In all, about 3 to 4 hours.
  - **Research still picks B5 over A,** with Modulo's clip striking down. Without that clip, it's a blow called down from the sky, and the director would be picking that instead.
- **The director, 2026-11-12:** "let keep A and do B5 later  like  a planned rework". **Haymaker closes on A**, director-accepted at "works" (section 8's round 2 is what plays). B5 is a planned rework, with its clip striking down and the target pinned, and the block-in here is its start (`docs/decisions.md`; `docs/polish-later.md`).

## AR2. The Shade, one rig for every enemy

For Modulo, after AR1's sheet is approved (it can run beside AR1's model).

**Feel line:** a festival-goer the Void has filled, wrong in the way a costume is wrong when nobody's inside it, and readable at a glance by its mask.

**Delivers:** a sheet with the body, the glowing outline in the five type colours, and the four masks (`docs/roster.md`, "Enemies"); then the model on one rig; then its clips: idle, walk, a basic attack, the Guard's raise, the Dasher's line and lunge, hit taken, and the burst into light and paper when it falls. No wounds, no blood, nothing left behind (`AGENTS.md`, rule 4).

**Checks:** as AR1. **Status:** in progress (Modulo, 2026-11-12). Delivery 1, the sheet, is delivered to `build/handoff/Shade/`. Delivery 2, the model, and delivery 3, the nine clips, are delivered to `build/handoff/Shade/` past the content check and research's reads. The colour map and the glow mask are rebaked for how Roblox draws a glow, and the clips carry the game's names and fades (section 4): uploaded and in the game, past the engine look (section 6). The elite's second mask is placed, in the recipe, and past the content check for the Brawler (section 5): installed, and in the engine its tie stands out of the sleeve (section 6), so the Brawler's now wears a copy of its mask without ties, past the content check (section 7), uploaded and in the game, its looks passed (section 9). Condition 9's contact sheet is drawn (section 10): in AttackLeft the second mask cuts into the first, so research picked the elite playing Attack every time, the builder's change, and the sheet is redrawn on the clips the elite plays, past the check. Open: the burst's light and paper, an effect built with the builder. Its block-in is signed, C (section 8). Its art sheet is accepted by research, competent, and on to the builder (section 11).

### 1. The design sheet (Modulo, 2026-11-12)

- **Where:** `build/handoff/Shade/shade_sheet.png`, with the view from behind and above in `shade_above.png`. Made by `tools/blender/shade_sheet.py` (headless Blender, about a minute): `blender -b --factory-startup --python tools/blender/shade_sheet.py -- <out dir> [small]`.
- **The one idea:** a festival coat with nobody in it, lit from inside like a paper lantern. The mask hangs where a face should be, tied round nothing: from the side there's the mask, two strings, a knot, and no head.
- **What's read, in order:** the mask's outline, then the lit edges by colour, then the hollow collar and cuffs.
- **The body:** the R6 body under a dark coat (Void `#1B1728`): a bell from the shoulders to a lit hem, a lit seam down the front, a round lit mark on the back, an open collar with a lit rim and a dark hollow, bell sleeves with lit cuffs and a dark hollow, straight legs with lit hems, no hands and no feet. It stands hung: tipped forward, turned a little, limbs plumb, the mask crooked. The blockout is 2,720 triangles, 4 studs to the shoulders, 5.5 to 6.7 to the mask's top.
- **The four masks,** in paper (`#EFE6D2`), each about two studs across, each with its own outline: the Brawler a disc, all grin, behind four paper teeth; the Guard a square under two heavy brows that jut past its sides; the Dasher a long kite, one point over the chest and one above the collar; the Support a wide, low band with its ends drawn out sideways, over a veil of four paper slips.
- **My calls (tier 1):**
  - The mask sits on the neck's joint, so one rig carries all four and a clip can tip it. The head part itself isn't drawn.
  - The "glowing outline" is made as lit edges on the coat (hem, seam, cuffs, collar), not a line round the whole figure: an outline round a dark body on a dusk ground reads as a sticker, and lit edges read as light from inside. On the sheet the glow is drawn on the picture; in the game it's a Neon part or the builder's choice.
  - The five type colours on the sheet are a proposal (Strength `#EA4B4F`, Endurance `#F4902A`, Agility `#3F9DF2`, Intelligence `#A470F2`, Technique `#42CC7E`), from the package's words (red, orange, blue, purple, green). AR3 fixes them, and the Shade takes AR3's.
  - The Dasher's mask stands 0.7 studs taller than the others, so its outline is a spike above the shoulders.
- **What I see wrong:**
  - At 64 px the four outlines differ (a ball, a slanted box, a spike, a wing), but each is about 20 px, and the tie strings add noise at the collar.
  - The Brawler's mask is the plainest of the four: at a glance it's a grin on a disc. The model's paint (a seam, a fold, brush marks) has to give it the paper.
  - The Support's band reads a little like a bat's wings from the front. The veil is what makes it a mask, and it merges with the coat in an outline.
  - On a bright floor the coat is a dark block and the lit edges lose most of their weight: the mask carries the read there.
  - The square pose's sleeves stand 5.3 studs across. Hung, they fall inside 4.
  - This is one direction, not three: the idea was clear from the roster's words, so I spent the time on the masks.
- **Not done:** the elite's second mask, the keepers (their own sheets), the burst into light and paper (a clip and an effect, with the model).
- **Content check, 2026-11-12:** BLOCK, then PASS after two fixes.
  - The collar's inside was lit: from behind and above, in the Strength red, a filled red disc where a neck would be. It's dark now, like the cuffs, and only the rim is lit. The sheet gained the view from behind and above, at full size (`shade_above.png`) and at 64 px.
  - The back's mark was a hollow diamond under the knot's two tails, a structure too close to a rune. It's a solid round disc now, and the tails end at the collar, 0.8 stud or more above it for every mask.
  - Passed as they were: the look and the names (rule 3), the lit bands and the empty coat (rule 4), the sources (rule 2).
  - For the clips: the feet stay planted with nothing above it, and the ties stay behind the mask, never round the collar.
- **Research's verdict** (Quaestor, 2026-11-12, on shade_sheet, shade_above and the 64 px rows): yes, on to the model, carrying fixes 1 and 2.
  - **Felt:** a coat with nobody in it, and a mask tied round nothing. Each behaviour is told by its outline before its colour. But the light reads as neon piping on a dark tracksuit, not as a lantern lit from inside.
  - **Tier:** competent.
  - **The one bold thing:** the side view. The mask, two strings, a knot, and no head behind them. It's the enemy's whole idea in one frame.
  - **Fixes:**
    1. "Lit from inside like a paper lantern" isn't on the sheet yet. The edges are lines of light on a dead coat. The coat itself needs to glow a little from within: light that rises toward the lit hem and the cuffs, as through paper, while the collar's inside stays dark as the content check asked. The body stays dark overall (serves: the one idea, and the festival it belongs to).
    2. The Brawler's mask reads as a smiley sticker. It must read as a festival mask someone made by hand, at 64 px too. It's the Shade players meet first and most (serves: "a Common is a character", "nothing looks like a placeholder").
  - **Accepted:** lit edges in place of a line round the figure; the mask on the neck's joint; the Dasher's spike; one direction, not three, since the roster's words set it.
  - **For AR3, which fixes the type colours:** Lantern Row is lit cyan and warm white (docs/roster.md, the grounds). Agility's #3F9DF2 sits close to that cyan, so check an Agility Shade on the dusk street before AR3 closes the colours.
- **Hours:** the sheet, 0.3.

### 2. The model on R6 (Modulo, 2026-11-12)

- **Where:** `build/scratch/modulo/shade/model/` until the checks pass, then `build/handoff/Shade/`: `Shade_<Piece>.json` (nine pieces), `Shade_Color.png`, `Shade_Roughness.png`, `Shade_Emissive.png`, `Shade.recipe.json`, `shade_model_sheet.png`. Made by `tools/blender/shade_model.py` (about 4 minutes, a Cycles bake under the lock): `blender -b --factory-startup --python tools/blender/shade_model.py -- <out dir>`.
- **How it sits on R6:** a rigid mesh for each of the five body parts, carrying the body's own surface, so the rig's blocks are hidden. Four masks, each one piece on the Head, of which a Shade wears one. No extra joints.
- **The numbers:** the body is 2,444 triangles. With its mask: Brawler 2,968, Guard 2,640, Dasher 2,544, Support 2,752. It stands 4.95 studs wide and 4.64 to the collar's rim; to the mask's top, 5.2 (Support) to 6.7 (Dasher). One 1024 px atlas for the body and all four masks, 69 px per stud. Maps: colour, roughness, and a glow mask. No normal map (the low mesh is the form) and no metalness (nothing is metal).
- **The hollows:** every opening is a dark hollow inside a thin lit rim: the collar, the cuffs, and now the coat's hem from below and the end of each leg. There's no foot, and no lit face where one would be.
- **One atlas for the five types.** The colour map holds no type colour: a lit edge is a dark violet in it (`#2A2440`), and the type is the glow's tint (`EmissiveTint`), on the body and on its mask. The recipe lists the five tints and a strength of 2.
- **Research's fix 1, the light from inside:** the glow mask is 1 on the lit edges and the masks' cuts. On the coat, the sleeves and the legs it rises toward their lit edge, up to 0.12 (0.07 on the legs, which stand under the coat), and is gone by the chest. A lantern's hoops show in it as thin darker lines every 0.42 studs, and the paper's grain runs down it. The collar and the hollows stay dark.
- **Research's fix 2, the Brawler's mask,** and the other three with it: all four are pressed or folded paper now, not flat discs. The Brawler is cut by hand, not quite round, with a tab each side for the strings, a lopsided grin behind four teeth no two alike, one eye laughing wider than the other, and two brows and a nose in ink. The Guard is a pressed square under its two brows, with an ink bar under each eye. The Dasher is a kite folded once down its middle. The Support's slips hang clear of the collar.
- **My calls (tier 1):** the legs glow too, less, so the whole figure is one lantern. The mask's paper takes no glow: with one tint for the whole atlas, a glow on the paper would colour the mask by its type and flatten its cuts.
- **What I see wrong:**
  - At dusk the mask is slate grey, not paper. It's lit by the scene only, and its cuts are the brightest thing on it. It still reads first, as the lightest shape over the darkest. The builder's lighting decides how much paper it keeps.
  - The hoops and the grain are drawn by a rule. Close up the grain reads as ribbed cloth as much as paper.
  - The atlas is loosely packed: many small islands, about a third of it empty.
  - The preview has no bloom, so the lit edges are flat bands of colour.
  - By day the lit edges wash toward pink and the cloth's glow nearly goes. The mask carries the read there, as the sheet said.
- **Content check, 2026-11-12:** BLOCK, then PASS after one fix.
  - The end of each leg and the hem's underside were filled lit faces: in the Strength red, from below or with a leg lifted, a red disc where a foot would be, a cut limb's end at a glance (rule 4, no severed parts). They're dark hollows inside a thin lit rim now. The sheet gained the view from below and the stride with a leg lifted, at full size and at 64 px on dark and on bright.
  - Passed as they were: the look and the names (rule 3), the sources (rule 2), the four masks, the glow.
  - **Its conditions on the model:** the colour map stays free of any type colour. The cloth stays matte (0.9) and its glow at or under 0.12. The grain isn't raised or drawn out into vertical streaks, and the rise's upper edge stays smooth and level. The teeth stay paper-coloured, with no red on or under them, and nothing red below the mouth or the eyes, ever, in any clip or effect. No added speckle, splash or smear on the paper. The ties stay behind the mask, never round the collar, with nothing above it holding it up. If the builder turns bloom on, a Strength Brawler is looked at in the engine at 64 px before it ships, and the lifted leg with it: bloom can fill a 0.95 stud hollow back into a red disc. The maps and meshes are logged in `docs/asset-log.md` at upload.
  - **Its conditions on the clips,** checked on their sheets before any upload: each clip's sheet shows its widest leg lift, and the burst's last frame, from low behind and low in front, at 64 px on dark and on bright, in the Strength red. No frame shows a leg or a sleeve apart from the coat. The burst ends as an emptied coat that goes at once, with nothing red left on the ground and no trail, drip or streak from a leg, a cuff or the hem. The bare rig is checked from the side and the three-quarter.
- **Research's read** (Quaestor, 2026-11-12, on shade_model_sheet, stills only; the clips judge it in motion): yes, on to the clips and handoff, carrying fix 1, which is checked in the engine.
  - **Felt:** the coat is a lantern now. The light rises from the hem through the hoops, and the Brawler's mask looks cut by hand. At dusk, though, the masks read as slate, and slate is stone, not paper.
  - **Tier:** competent.
  - **The one bold thing:** the Brawler's lopsided grin behind four teeth, no two alike. The first Shade a player meets has a face someone made.
  - **Fixes:**
    1. At dusk the mask must read as paper, not slate (serves: "readable at a glance by its mask", and the festival). This revisits your call that the paper takes no glow. Its reason, one tint for the atlas, holds per part only: the mask is its own MeshPart with its own SurfaceAppearance, so it can take its own faint warm-white tint on the paper alone. Try that first, on the dusk preview at 64 px. If the cuts lose their type colour that way, the body's edges carry the type, as they already do. Check it in the engine at the Shade's first placement under the builder's lighting, not with a new bake.
  - **Accepted:** the legs glowing less, so the figure is one lantern; no normal map; the loose atlas (room for the elite's mask); the grain that reads as cloth up close, since the player's camera never gets that close. Bloom and daylight are the builder's lighting to check, under the content check's conditions.
- **Fix 1, made (Modulo, 2026-11-12):** the mask's paper glows faintly, and the mask takes its own warm-white tint.
  - The trial, `shade_mask_paper.png` beside the model sheet: the four masks at dusk from the player's camera, at 300 px and at 64 px, four ways. As baked, slate. Paper at 0.16 under a warm white: paper, at both sizes. Paper at 0.16 under the type's tint: the mask turns pink, tan, blue or violet, and the paper is lost. Paper at 0.30: cream, but the cuts wash out at 64 px.
  - Built in: the glow mask is 0.2 on the masks' paper, and the recipe carries `mask_tint` (`#FFE2B8`) for the mask's own SurfaceAppearance, whatever the type. The bake was run again for it. The model sheet and the atlas check show it.
  - What it costs, as research foresaw: the cuts are lit warm white now, not in the type's colour. The body's edges alone carry the type. That also keeps every red off the masks.
  - Still to check in the engine, at the Shade's first placement under the builder's lighting: the paper's level and the tint, tuned live.
- **Research's read on fix 1** (Quaestor, 2026-11-12, on shade_mask_paper and the new bake): closed. The masks are paper at dusk now: warm against a cold coat, and at 64 px the brightest thing on the figure, so the read goes mask first, as the sheet promised. 0.2 sits right between slate and the washed-out cuts. Losing the type colour from the cuts is accepted, since the body's edges carry the type. The level and the tint are tuned live at the first placement.
- **Content check on the mask's light, 2026-11-12: PASS,** with these conditions, which replace the earlier line on the teeth:
  - No type colour on a mask, ever. Each mask's SurfaceAppearance takes `mask_tint`, never the type's tint, in any clip, effect or state (a hit flash, an elite). The trial's row C is what the type's tint gives on a Strength Brawler.
  - The mask's tint stays between warm white and neutral white. If its level leaves about 0.16 to 0.3 times strength 2, or bloom is on, it's looked at again at 64 px.
  - All paper stays on the mask's piece, the ties, the knot and the tails included.
  - With bloom on, the Strength Brawler is looked at in the engine at 64 px, the lifted leg as before, and the collar rim's red must not spill onto the mask's chin or teeth.
  - Unchanged: no type colour in the colour map; the cloth matte, its glow at or under 0.12; no speckle, splash or smear on the paper; the ties behind the mask.
  - The three maps and the nine meshes are logged at upload. The design sheet stays internal, and its type-coloured cuts aren't the build target: the recipe and the model sheet are.
- **Delivered, 2026-11-12:** `build/handoff/Shade/`: nine meshes (`Shade_Torso`, the two arms, the two legs, the four masks), `Shade_Color.png`, `Shade_Roughness.png`, `Shade_Emissive.png`, `Shade.recipe.json`, `shade_model_sheet.png`, `shade_mask_paper.png`, and the design sheet drawn again with the hollows. Not uploaded, not in the engine.
- **Not done:** the burst into light and paper (an effect, with the builder); the elite's second mask. The design sheet is rendered again with the pressed masks and the hollows; its masks still show their cuts in the type's colour, as the direction was judged, and the model sheet is the one that shows the mask's light as built.
- **Hours:** the model, 0.7, the content check's fix and research's included.

### 3. The clips: the poses (Modulo, 2026-11-12)

- **Where:** `build/scratch/modulo/shade/clips/poses_<Clip>.png`, seven sheets: each named pose from the player's camera above, and from the side below. Made by `tools/blender/shade_clips.py` on the kit Rook's clips use: `blender -b --factory-startup --python tools/blender/shade_clips.py -- <out dir> [poses|export|audit] [clip ...]`. These are the key poses for research's read. The exports, the arcs and the review packs come after it.
- **How it moves, in one line:** nothing inside it pushes. The mask leads, the coat is drawn after it, and the sleeves arrive last. The mask never stops watching the fighter.
- **The seven,** at 60 frames a second, each with its markers:
  - **Idle** (a loop of 180): hung, tipped forward, turned a little, sleeves plumb. It sways as a coat on a hook does, and at 120 the mask tips to its other side.
  - **Walk** (a loop of 48, `Step` at 0 and 24): the mask travels level and the coat swings under it. The legs are loose and late: they follow the coat, they don't carry it.
  - **Attack** (66; `Hit` at 30): the whole coat turns away (16), and the sleeve is flung round after the turn, the cuff landing flat (30). It hangs spent (44), then gathers. The mask stays on the fighter throughout.
  - **Guard** (96; `Raise` at 12, `Drop` at 72): both sleeves come up and bar the chest, one over the other, under the mask. It holds for a second, hardly breathing, and lets them fall as if they weighed nothing (82).
  - **Lunge** (96; `Line` at 14, `Lunge` at 40, `Land` at 54): it folds down behind the mask until the kite's point is a dart aimed at the fighter, and holds dead still for 26 frames. Then the mask goes, and the coat is pulled out flat behind it (44). It lands (60), and the sleeves arrive seven frames later (67).
  - **Hit** (22): struck at the chest (3); the mask is left behind and follows (8).
  - **Burst** (34; `Burst` at 27): struck (4), it lets go: the sleeves lift and open and the mask tips up (20 to 27). The game hides the body at `Burst` and the effect takes over. Nothing lies on the floor.
- **My calls (tier 1):**
  - The Guard bars its chest, not its mask. A first pass crossed the sleeves before the mask, and the slotted square a player knows it by was gone for the whole hold.
  - The Dasher's tell is the body, not only the builder's line on the floor: the fold and the stillness say "next, along here" from any side.
  - One reaction set for the four masks: the reactions are a rig's shared set (`docs/design.md`, "States in a fight").
- **What I see wrong:**
  - The Guard's bar reads a little as folded arms, as a figure waiting, more than as a brace. The crouch and the lean carry it. The shield's own look will decide whether the pose needs more.
  - The Lunge's flight (44) lies nearly flat on the floor. From the player's camera it's a dark streak with a spike on its front, which is the read, but the legs trail straight and stiff.
  - The Attack swings one sleeve, always the right. Every Brawler will swing the same way.
  - The Walk's legs are keyed by angle, not planted: over a long walk the feet will slide a little under the coat. The coat's hem hides most of it.
  - In the Burst's last pose, the lifted sleeves show their dark hollows to the camera: good for the idea, but the effect has to start on that frame or it reads as a shrug.
- **Research's read** (Quaestor, 2026-11-12, on the seven pose sheets; stills only, so motion is judged on the review packs): yes, on to the exports. Fixes 1 and 2 come before them, fixes 3 to 6 with them.
  - **Felt:** where the Shade folds behind its mask, it's a coat with nobody in it. The Lunge's line shows the player an empty collar ringed in light, held dead still. The Guard and the Walk are still a person's folded arms and a person's walk.
  - **Tier:** competent at the poses. The Hit is under the line, and it's the clip players see most.
  - **The one bold thing:** Lunge 14 to 40. It folds down behind the kite and turns the lit rim of an empty collar to the player, perfectly still. It's the feel line in one frame, and a tell nobody misreads.
  - **Fixes:**
    1. **Hit:** the struck pose (3) moves one sleeve and the coat hardly at all. Knock the coat itself: the chest caves away from the fighter and the hem swings after it, enough to read from behind the fighter at 64 px, then the mask catches up (serves: impact on every hit the player lands, and the Burst, which starts from the same pose).
    2. **Guard:** I don't think the shield should decide this. Folded arms read as waiting, and the tell has to read before any effect does. Make it a brace: sink into the coat, lean toward the fighter, and stand the sleeves upright side by side under the mask, cuffs toward the fighter, like a shutter pulled shut rather than arms crossed (serves: the Guard read at a glance; the slotted square stays visible).
    3. **Walk:** the sleeves swing against the legs like arms, and that's what makes it a person. Let them hang and be dragged late by the coat, out of step with the legs (serves: "nobody inside it").
    4. **Lunge 44:** the legs trail loose and bent like empty trouser legs, landing last with the sleeves (serves: the same idea; the streak keeps its spike).
    5. **Burst:** arms out to the sides read as a shrug. Send the sleeves back behind the shoulders instead, the chest arched open toward the fighter, the mask tipped back. Light bursts out of the front and the effect starts on that frame. The feet stay planted, and it never rises off the floor, because the content check's "nothing above it" holds (serves: the release, and the handover to the effect).
    6. **Attack:** export a mirrored copy so the builder can alternate or pick at random, and a pack doesn't swing in step (serves: a pack of Brawlers reading as many).
  - **Accepted:** the mask leads and the sleeves arrive last; the Guard bars the chest, not the mask; the Dasher's fold as its own tell; one reaction set. The Walk's foot slide is accepted if the builder sets walk speed from the stride, so put the stride length in the recipe. The Lunge's 26-frame hold is accepted if Combat's tell time is read from the markers rather than typed twice.
- **Round 1, the six fixes made (Modulo, 2026-11-12).** Where: `build/scratch/modulo/shade/clips/`, for each of the eight clips `Shade_<Clip>.json`, `pack_<Clip>.png` (the poses, the bare rig, a strip of twelve), `poses_<Clip>.png` (with the side), `arcs_<Clip>.png`, `low_<Clip>.png` (the content check's views), and `Shade.clips.json` (frames, markers, the walk's stride).
  1. **Hit** (24 frames now): the chest is knocked back 27 degrees and 0.6 studs, the sleeves and the mask left where they were (3). The hem swings through after it, the mask snapping back late (9). The Burst starts from the same pose.
  2. **Guard:** a brace. The coat sinks 0.4 and leans 22 degrees at the fighter, and both sleeves come up level, side by side under the mask, their open cuffs square at the fighter. An R6 sleeve has no elbow, so it can't stand upright before the chest: the shutter is the two cuffs' frames, closed together.
  3. **Walk:** the sleeves hang and are dragged behind the coat, always behind their shoulders. Each step's jolt lets both forward together, five and eight frames late. They no longer swing against the legs.
  4. **Lunge:** in the flight the legs trail apart and flap, one low, one high (44 to 54). The mask arrives upright at 60 with the coat still dragging on the floor behind it, and the legs and the sleeves come in at 67.
  5. **Burst:** the chest arches forward, the sleeves are drawn back and low behind the shoulders, the mask tips back (20 to 27). The feet stay planted and nothing rises.
  6. **Attack:** `AttackLeft` is its mirror, the left sleeve flung. Both start and end on the same hub pose.
  - **Also changed, from the kit's audit:** the hung sleeves now hang truly plumb. They had leaned in 15 degrees, through the coat's block (the solver aimed the shoulder's corner at the cuff, not the sleeve's own line). In the Attack the legs swivel with the coat as it turns, where they had crossed through each other.
  - **The audit:** seven clips pass. The Guard doesn't: each sleeve's block sits 0.36 studs inside the torso's at the shoulder for the whole hold (limit 0.05). A level arm turned inward always does on R6. On the model it's the sleeve's root folded into the coat's chest, dark cloth in dark cloth, and I don't see it from the player's camera. Opening the cuffs apart to pass it would lose the shutter.
  - **The walk's stride:** 3.29 studs a loop, 4.11 studs a second, in `Shade.clips.json`, not in the clip's own file: the importer refuses fields it doesn't know. The Lunge's tell is the time between its `Line` and `Lunge` markers (26 frames), there to be read, not typed again.
  - **What I see wrong now:**
    - The Guard's far cuff shows the player a dark square with almost no lit rim, so the shutter is one frame and a half.
    - The Burst's open pose is quiet from the front: the near sleeve shows swept back, the far one hides behind the coat. It leans on the effect.
    - The Hit's sleeves, left forward for three frames, are the widest the Shade ever gets (about 6 studs across).
    - The Lunge at 60 sits very low, the coat on the floor behind an upright mask. It may read as kneeling for those seven frames.
- **Content check on round 1's eight clips, 2026-11-12: PASS,** on sampled frames, one mask a clip. Its conditions for the upload:
  - The export's audit lines are read for every clip, and a "Salute held" over 0.1 s goes back to the check. Done: 0.000 s in all nine, and each `pack_<Clip>.txt` now holds its audit.
  - The Guard's sleeves stay at or under about 10 degrees up, the reach no higher than 3.3. A retune that raises them, or stands the body more upright, is checked again.
  - Exactly these exports are uploaded. A clip keyed again gets its sheets checked again.
  - In the engine, before a public build: Hit and Burst from behind in each of the four masks (the ties never into or round the collar); a Strength Dasher's Lunge hold at 64 px with bloom on (the collar stays a dark hollow).
  - The body is hidden at the `Burst` marker, and the burst's light and paper get their own content check.
  - The animations are logged in `docs/asset-log.md` at upload. The model's conditions stand.
- **Research's read, round 1** (Quaestor, 2026-11-12, on the eight packs, the side views and the 64 px strips):
  - **Felt:** the Walk and the Guard are fixed. The sleeves dragging behind take the person out of the walk, and the Guard is a brace now, two cuffs thrust at the fighter. The Hit and the Burst still happen along the line toward the player's camera, so from there they're small.
  - **Tier:** competent. Hit and Burst sit at the line, not above it.
  - **The one bold thing:** still Lunge 14 to 40. Its landing now adds a second beat: the mask arrives upright first, with the coat dragged in behind it.
  - **Fixes, round 2 on these two ideas:**
    1. **Hit:** a 27-degree knock straight back is on the axis the player's camera sees least. Add a turn: the coat twists 20 to 25 degrees as it's knocked, and the mask snaps up a little before it follows, so the hit changes the outline seen from the front. Export the mirror too, as with the Attack (serves: every hit the player lands. The builder's hitstop and knockback carry the rest).
    2. **Burst:** the mask is the lever. In every other clip it never stops watching the fighter. Here it does: it tips back until its face is to the sky, edge-on to the player at 27, so the face leaves first and the light comes out where it was. Feet planted, nothing rises (serves: the release read from the front, and the one moment the mask lets go).
  - **Accepted:**
    - the Guard's audit overlap (0.36 studs, the sleeve root dark in the dark chest; R6 has no elbow), named as the one exception and looked at again from the player's camera in the engine;
    - the far cuff's dim rim;
    - the Hit's 6-stud sleeves for three frames, a flare that belongs to the hit;
    - the Lunge at 60, a landing crouch for 0.12 s, not a kneel;
    - the stride in Shade.clips.json;
    - the tell read from the markers.
- **Round 2, Hit and Burst (Modulo, 2026-11-12).** The same folder, with `collar_<Clip>_front|side|behind.png` for the three: close on the mask and the collar, a row a mask.
  1. **Hit** (24 frames): the coat twists 23 degrees as it's knocked, the struck shoulder going back. That side's sleeve is left where it was and the other trails. The mask snaps up 17 degrees at 3 and nods down after the coat at 9. The shove back is 0.5 studs, from 0.62, and the roll smaller, to keep the legs in the hip.
  2. **HitLeft:** the other shoulder. It twists 17 degrees, not 23: the coat hangs 10 degrees turned, so the mirror ends 27 degrees off the feet, and more than that crosses the legs past the audit's limit.
  3. **Burst** (34; `Burst` at 27): it starts on the same struck pose. Then the mask leads: 44 degrees back against the coat at 20, its face to the sky and its edge to the player at 27, while the coat arches and the sleeves are drawn back after it. Feet planted, nothing rises.
  - **My call (tier 1):** the mask is carried up to 0.14 studs off the neck as it tips (the audit allows 0.15). Turned on the neck alone, the collar's red rim came through the paper beside the grin at 20 to 24.
  - **The audit:** the three pass. Of the nine, the Guard is the one over, as accepted.
  - **What I see wrong:** in HitLeft 3 a leg slides 0.81 studs up into the hip under the hem (the kit warns past 0.6). In Burst 27 the tips of the Brawler's tie tails sit 0.1 studs in the coat's back; the knot lies on the back, and the ties run outside the collar. Both sleeves are wide for three frames in the Hits.
- **Research's read, round 2** (Quaestor, 2026-11-12, on pack_Hit, pack_HitLeft and pack_Burst, the side views and the 64 px strips): yes, to handoff.
  - **Felt:** a hit now changes the Shade's outline from the player's camera. A shoulder goes back, a sleeve is left behind, the mask jerks up. And when it falls, its face goes first, so for one frame there's a coat with an empty collar and a mask lying flat to the sky.
  - **Tier:** competent for the set. The Burst's last frame reaches past it; it's judged again with its light and paper, in the game.
  - **The one bold thing:** Burst 27. The one time the mask stops watching the fighter, and the moment the player knows it's over before the effect starts.
  - **Accepted:**
    - HitLeft's smaller twist (17 degrees), for the legs' sake; its outline changes more from the front anyway;
    - its leg 0.81 studs into the hip, under the hem and out of the player's view;
    - the Brawler's tie tips 0.1 studs into the back at 27, the frame the body is hidden;
    - the mask carried 0.14 off the neck as it tips, your call, and the right one, since it keeps the collar's red off the paper;
    - the flare of both sleeves for three frames.
  - **For the builder:** Hit and HitLeft alternate or are picked at random, as the Attacks are. The Burst's effect starts on the `Burst` marker, from the collar, where the face was.
- **Content check on round 2's three clips, 2026-11-12: PASS.** It saw the packs, the low sheets and the collar sheets; the pose sheets it saw were older than the exports, and they were rendered again after it (Burst 20 shows no red on the paper). Its conditions, with round 1's:
  - The ties: none crosses the collar's opening or lies across its front, none runs upward, and the knot and tails stay out of the hollow. Measured after the check at the struck frames (Hit 3, HitLeft 3, Burst 4), in the four masks: nothing in the hollow; in HitLeft 3 a tie comes within 0.08 studs of the collar's back corner.
  - The hide at `Burst` (frame 27) takes the mask and the ties in the same frame as the body. The frames after it are a safety net, never a shown state: a fade, or a hide later than 27, goes back to the check.
  - Nothing red on the paper or the ground, and no trail, drip or streak from a leg, a cuff or the hem in the burst's effect. Bloom on a Strength Brawler is checked in the engine at 64 px.
- **Delivered, 2026-11-12:** `build/handoff/Shade/clips/`: `Shade_<Clip>.json` and `poses_<Clip>.png` for the nine (Idle, Walk, Attack, AttackLeft, Guard, Lunge, Hit, HitLeft, Burst), and `Shade.clips.json`. Not uploaded, not in the engine.
- **For the builder:**
  - The masks take `mask_tint` from `Shade.recipe.json`, the body's five pieces the type's tint.
  - Walk speed comes from the stride in `Shade.clips.json` (3.29 studs a loop, 4.11 studs a second).
  - The Lunge's tell is the time between its `Line` and `Lunge` markers.
  - Attack and AttackLeft alternate or are picked at random; so do Hit and HitLeft.
  - The body is hidden at the `Burst` marker, where the effect starts, from the collar.
  - The engine checks are the content check's, above and in section 2.
- **Not done:** the burst's light and paper (an effect, with the builder, with its own content check). The elite's second mask is section 5. Nothing is uploaded or seen in the engine.
- **Hours:** the clips, 1.2, the two rounds and the checks' fixes included.

### 4. The glow as Roblox draws it, and the clips' names (Modulo, 2026-11-12)

The builder's notice from the engine: Roblox multiplies a surface's glow by its colour map, `(mask x EmissiveStrength x EmissiveTint + light) x colour map` ([the announcement](https://devforum.roblox.com/t/studio-beta-emissive-masks/4034414)), and the Shade's colour map was the coat's dark purple under every lit edge. The model sheet had drawn the glow in the tint alone, so it showed a light the engine couldn't give.

- **What changed**, in `tools/blender/shade_model.py`. The light is still designed as it was (1 on the lit edges and the cuts, to 0.12 on the cloth, 0.2 on a mask's paper). What's written is that light divided by the colour under it:
  - the colour map is a neutral dark grey (`#505050`) under the body's lit edges, so each type's colour comes through whole and daylight doesn't wash the edge out, and near white (`#F0F0F0`) under the masks' cuts;
  - the cloth loses its violet where light comes through it, and is lifted a little at the hems: through the violet, a Technique Shade's coat glowed teal, and a crevice's dark put the light out where it's meant to be most;
  - no contact shading under a lit edge;
  - two strengths in `Shade.recipe.json`: `strength` 32 on the body's five pieces, `mask_strength` 12 on a mask. The cloth under its glow is nearly black, so the body's is high; a mask's is lower so the faint glow on its pale paper keeps enough steps in 8 bits. Both are inside Studio's own slider (0 to 40).
- **The sheet now draws the glow through the colour map**, as the engine does. Beside the sheet research read, I can't tell them apart at dusk or by day, in the five types or at 64 px. The meshes and the roughness map are byte for byte the ones delivered, so nothing but the two maps is uploaded again.
- **The clips** carry the game's name (`Name` is `ShadeAttack`, as `Author.SaveBaked` checks) and their fades, the game's own from `Config.Animations.Fades`; Guard's (0.08 in, 0.15 out) and Lunge's (0.06, 0.15) are proposed, not judged in motion: the game doesn't play them yet. Every frame is as delivered. `Shade.clips.json` lists each clip's `Name` and `Fades`. Pip's clips carry `Pip<Clip>` the same way (frames as delivered); Rook's script does from its next export, and his delivered files stay as the builder imported them.
- **Content check, 2026-11-12: PASS**, on the two maps as they upload and the sheet. Conditions:
  1. The two maps upload together and replace both old ones; neither is ever paired with an old map.
  2. The cloth stays faint only because the engine multiplies the glow by the colour map: the file's mask is near 0.9 at the hems.
  3. A Strength Brawler is looked at in the engine at 64 px at first placement, on dark and on bright and with a leg lifted, before any public build. If the coat shows as a bright red streaked field instead of matching the sheet, it comes back.
  4. The body's pieces take strength 32 and the type's tint; a mask takes `mask_strength` and `mask_tint` only, in any clip, effect or state. If a strength or the mask's tint is tuned live, look again at 64 px.
  5. Section 2's other conditions stand. Both maps are logged in `docs/asset-log.md` at upload.
- **Delivered** to `build/handoff/Shade/`: `Shade_Color.png`, `Shade_Emissive.png`, `Shade.recipe.json`, `shade_model_sheet.png`, and `clips/` (the nine JSON and `Shade.clips.json`). Faber: the two maps go up together, with the recipe's two strengths.
- **What I see wrong:** nothing here is seen in the engine. The match is between two Blender pictures and Roblox's published formula; its tone mapping and bloom aren't in it, so the strengths are a start to tune there, both by the same factor. With the glow off, the cloth near the hems is grey-black, not violet-black. The same formula touches two more recipes: Pip's flame (AR4, section 2) and Rook's ram (AR1, section 5's last line).
- **Hours:** about 0.8, four bakes and the content check included.

### 5. The elite's second mask (Modulo, 2026-11-12)

A minor asset, so no blockout round: one comparison sheet, `build/handoff/Shade/shade_elite.png`, drawn by `tools/blender/shade_elite.py` (Workbench, no GPU turn), and a placement in `build/handoff/Shade/Shade.recipe.json` under `elite`.

- **What it is:** the Shade's own mask again, the same MeshPart with the same surface, at 0.6 of its size, on the Left Arm's front corner just under the shoulder, upright and facing front-left. No new mesh, no new map, nothing to upload. The recipe gives, for each of the four masks, where the part's middle goes and where its three axes point, at the ordinary Shade's size; it scales with the rig (the game's elite is 1.35).
- **Why the left arm:** the player's camera sits behind the lead's right shoulder, so a Shade that faces the lead shows it its front and its left. `shade_sheet.py`'s `PLAYER` view (156) is that camera mirrored; this sheet uses 204. The earlier sheets aren't redrawn for it: the Shade is the same on both sides until this mask.
- **Three ways were drawn** on the Brawler at the elite's size beside an ordinary Shade: A flat on the arm facing out, B on the front corner, C pushed up onto the shoulder. B is picked: from the player's camera it's a second small grin looking back at the player, and it shows from the front and from the left. A is side-on to the camera. C reads as a plate on the shoulder, not a face.
- **Content check, 2026-11-12: PASS** for way B on rules 2, 3 and 4, with only the Brawler seen at 64 px and on every heading. To hold:
  1. The same part and surface, with `mask_tint` and `mask_strength` only: never the type's tint or a colour of its own, in any state. The sheet's red cuts are the blockout's.
  2. The placement stays the recipe's. Moving it to the chest, collar, neck, a hand, beside the first mask or onto the ground, or making it as large as the first, goes back to the check.
  3. No new string from it to the collar, the neck or the first mask. The clone's ties and knot end up inside the sleeve: look once in the engine from behind and from below, and a pale strip in the cuff's hollow or out of the sleeve's back comes back.
  4. At first placement, a Strength Brawler elite is looked at at 64 px on dark and bright from three headings, with the game's bloom: no red from the seam, the collar's rim or the cuff spills onto the small mask (with section 4's condition 3).
  5. The Guard, Dasher and Support elites wait: before one is installed, the sheet gains B on it at 64 px over dark and bright from three headings and goes back to the check (the Support's slips as a small pale hand, the Dasher's point as a spike past the arm). The Brawler elite doesn't wait.
  6. Nothing else marks an elite without its own check: no aura, ground mark or added lit part.
  7. If it's ever uploaded as a mesh of its own, it's a new asset, logged and checked.
  8. It moves only with the Left Arm: no clip or effect knocks it off, dangles it, splits it or throws it. In the burst it goes with the coat in the same frame, never last, never left on the ground, and the burst's paper is scraps, never a whole small face.
  9. One contact sheet of the elite before any public build: the second mask on, in Strength's red, the nine clips' widest frames at 64 px from the player's camera, on dark and bright; Guard, AttackLeft, HitLeft and Burst first. In the Guard the left sleeve comes level under the first mask: the small mask must not sink into the chest or the first mask.
  10. No clip changes for it; a clip retimed or re-posed for the elite is checked again. Sections 2 and 4 stand.
- **What I see wrong:** from behind and from the lead's other side the second mask is a sliver or hidden, so there only the size says elite. It's on a swinging arm: the clips weren't made with it, and condition 9's contact sheet is the first look at that, which is mine to draw when the builder has it in. Drawn as a blockout with the cuts in the type's colour, not as the baked mask. Not seen in the engine, not read by research.
- **Hours:** about 0.5.

### 6. In the game: the two maps and the elite's second mask (Faber, 2026-11-12)

- **The maps,** uploaded together for the group (section 4, condition 1): Color `101466364915316` and Emissive `102819316179447`, replacing both old ones. The Roughness map is unchanged. Logged in `docs/asset-log.md`.
- **The strengths** are in `Config.Shades`: `Emissive` 32 on the body's five pieces, `MaskEmissive` 12 on a mask, the elite's second included. `FightService`'s `buildShade` sets each part's tint and strength by whether the part is a mask.
- **The elite's second mask:**
  - `EliteMask_Brawler` uses the Brawler mask's mesh and surface at 0.6.
  - It sits at the recipe's centre and axes (`ELITE` in `tools/studio/Models/Shade.luau`), scaled with the rig, and is welded to the Left Arm.
  - Only an Elite keeps it, and only the copy that matches its own mask.
  - Self-test case: "Fight: an elite wears its mask twice, the second on its Left Arm".
- **Rojo:** the live sync left the new mask's weld unattached in Studio, though the file holds it. The file is byte for byte Studio's own build. The weld is set in Studio to match the file, and the place is saved. The new case caught it.
- **Tests:**
  - the Shade and fight cases, 29/29; logic, 1,376; type check, 0 new; world report, empty;
  - the full self-test, 286/286 on its second run. Its first run failed two cases outside this piece: the HUD's health bar read 0.71 for 0.74, and four Base `Detail` labels read 11.9 px at the smallest phone. Both pass alone; they're intermittent and not yet diagnosed.
- **The engine looks** (the content check's conditions, a fresh read):
  - The setup: the game's own models, under the game's lighting (ClockTime 14.5, bloom on), on a dark and a bright ground.
  - The images, internal: `build/captures/ar2/`.
  - **Section 4, condition 3: PASS.**
    - The coat keeps the sheet's violet-to-warm fade, with no red streaked field (`shade_64_dark.png`, `shade_64_bright.png`).
    - From low behind and low in front, the lifted legs' and the sleeves' ends stay dark inside a thin rim, and bloom doesn't fill them (`shade_64_low_dark.png`, `shade_64_low_bright.png`).
  - **Section 5, condition 4: PASS.** The small mask stays pale at 64 px from three headings, with no pink from the seam, the collar or the cuff.
  - **Section 5, condition 3: BLOCK.** The copy's tie stands out of the sleeve as a pale rod:
    - from below, in idle and in the guard (`elite_mask_close.png`, crops 1 to 3; `elite_detail_dark.png` and `elite_detail_bright.png`, column 2);
    - from behind, in the guard, with a second short strip past the mask's lower end (`elite_arm_behind.png`, panels 2 and 4).
    - Idle from behind is clean.
- **Back to Modulo,** with either way going to the check again:
  - seat the copy so its ties end inside the arm in every clip, which is a placement change (condition 2);
  - or make a copy of the mask without ties, which is a new mesh (condition 7).
  - Then the looks again from behind and below, idle and guard, on dark and bright.
  - Condition 9's contact sheet waits on that. Until then the elite plays with its second mask in the dev build only.
- **Seen, for research:** under the game's bloom, the Strength edges read pale salmon-pink, not the sheet's red. Whether the type still reads is research's call.
- **Research's read, 2026-11-12** (shade_64_dark, shade_64_bright). The figure holds at 64 px: the paper mask is the brightest thing on it, and under it the coat's fade and a thin lit rim. **The type doesn't read yet.** Pale salmon isn't red. It sits between Strength's red and Endurance's orange, and near Lyric's Storm pink and Mythical's red light, and a type has to be told at a glance. The likely cause is strength 32 driving the edge into the bloom and the tone map, which wash a saturated red toward white. **Ask, the builder's:** one strip under the game's lighting, at 64 px, on dark and on bright: the five types side by side, Strength beside Endurance, with the body at 32, 16 and 8 and the mask moved by the same factor (12, 6, 3; section 4). Research picks the lowest strength at which every type reads as its own colour and the edge still glows. The pick is a tuning in `Config.Shades`, and the content check's condition 4 looks again at it.
- **Research's pick from the strip, 2026-11-12** (types_64; the builder's strip). **Body 16, mask 6.** At 32 every type is pastel. At 8 the edges stop glowing on bright ground and the masks go grey on dark. At 16 the five read as five, and the masks stay paper. The engine still lifts every hue a step: Strength reads coral, not red, and Endurance gold, not orange. So two glow tints in `Config.Shades.Tint` are pushed to come out as the type's colour on screen: **Strength `#E8261E`, Endurance `#F26A12`**. AR3's type colours, the gems and the interface keep theirs; only the Shade's glow tint compensates for the engine. To confirm, the builder shoots one row at 16/6, dark and bright: the two old tints beside the two new, with Technique as a control. If Strength reads red and Endurance orange, the numbers stand; then the content check's condition 4.
- **Research's read of the confirm and the lever, 2026-11-12** (confirm_16, lever_16, the builder's measures). Research's two tints failed: salmon and sandy amber. The builder found why: any green or blue in a tint lifts toward white past the tone map's knee. **Strength `#E80000`, Endurance `#F23000`**, the builder's recommendation, taken: red at 357° and orange at 26°, saturated on both grounds, and clearly apart. The other three types read as their families, mint, sky and lavender, and stay as they are; the same lever is there if a ground's light ever confuses one. Then the confirm row again and the content check's condition 4.
- **Research: accepted, 2026-11-12** (confirm_final, game_64). The game's own Brawler and elite read as Strength, red, from the front, the side and behind, on both grounds. The mask is still the brightest thing on the figure. The Shade's glow is closed.
- **In the game** (Faber, 2026-11-12): `Config.Shades`, body 16, mask 6, Strength `#E80000`, Endurance `#F23000`. The confirm row (`confirm_final.png`): Strength red at 357°, Endurance orange at 26°, on both grounds; a spawned Brawler reads back `#E80000` at 16 on its five pieces, `#FFE2B8` at 6 on its masks. The game's own Brawler and elite at three headings: `game_64.png`. Shade and fight cases 28/28.
- **Content check, condition 4 at 16/6: PASS.** To hold:
  1. Section 4's condition 4 now reads 16 and 6. Any further live tuning of a strength, the mask's tint or a type's glow tint is another 64 px look.
  2. Before any public build: a Strength Brawler, ordinary and elite, at 16 in `#E80000`, in HitLeft, Burst and the fallen pose, at 64 px on dark and bright, in section 5's condition 9 contact sheet with the ordinary Shade added. It comes back if bloom hazes red onto the ground, red reaches the paper scraps, or a body lying in red reads as one shape.
  3. The back's disc stays a crisp round emblem, never a blot with a halo or a ragged edge.
  4. The hem fade stays even and horizontal on every piece.
  5. Everything else stands; section 5's condition 3 stays blocked.
- **Hours:** about 3, the engine looks included.

### 7. The second mask without its ties (Modulo, 2026-11-12)

This is the fix for section 6's BLOCK on condition 3, by section 6's second way: a copy of the mask without ties, which is a new mesh (condition 7). Made on Opus 5.5 xhigh.

- **Why not a placement change:** I took the second way without trying the first.
  - At 0.6, each string still runs about 1.1 studs back from the mask's tab, and the tabs are 1.5 studs apart.
  - The sleeve is a hollow bell, open at the cuff.
  - A seat that hid the strings from below and from behind, in both the idle and the guard, would sink the mask into the arm.
  - The copy gives the look the sheet passed, a mask with nothing behind it, and it holds in every clip.
- **What it is:** `build/handoff/Shade/Shade_MaskBrawlerBare.json`.
  - It's the delivered `Shade_MaskBrawler.json` less five islands: the two strings, the knot and the knot's two tails. That leaves 464 of 524 triangles.
  - The kept triangles keep their normals and UVs, so the copy wears the same SurfaceAppearance and the same three maps. No map changes.
  - It's 2.70 × 2.11 × 0.20 studs at full size.
- **Where it goes:**
  - The recipe's `elite` now names the mesh each elite wears, under `mesh`.
  - The Brawler's centre moves to (-2.0694, 3.5561, -0.6156): 0.465 studs along its facing, because a published mesh is centred on its own box. Its axes don't change.
  - Placed there, the copy's points land within 0.00001 studs of where they sat on the whole mask.
  - The other three elites keep their whole masks and wait (condition 5).
- **The look:** `build/handoff/Shade/shade_elite_bare.png`.
  - The baked model in the delivered Idle and Guard: close on the arm from below and from behind, as the builder looked, then the Guard from the player's camera.
  - The top row is the copy with its ties, as the game has it now; the bottom row is without them.
  - Every rod from the top row is gone. The strings left high in the views from behind are the first mask's, on the head, as designed.
  - Not yet seen in the engine.
- **Content check, 2026-11-12: PASS** (rules 2, 3 and 4; condition 3's rods are gone in every column). The 64 px look was judged from the player's-camera column, not drawn. To hold:
  1. After the upload, the builder looks in the engine with the uploaded mesh, before condition 9's contact sheet: from below and from behind, in Idle and Guard, on dark and bright ground, at the same angles as `elite_mask_close.png` and `elite_arm_behind.png`, with one look at 64 px. A pale strip in the cuff's hollow or past the sleeve comes back.
  2. It keeps the same surface and settings: the three uploaded maps, `mask_tint` at `mask_strength` 6, 0.6 of its size, at the recipe's new centre. A new map, tint, size or placement goes back to the check.
  3. The Brawler's only. Copies for the Guard, Dasher and Support wait on condition 5's sheet and their own check.
  4. It's logged as a new mesh.
  5. Section 5's other conditions and section 6's stand.
- **For Faber:**
  - Upload `Shade_MaskBrawlerBare.json` for the group, as before.
  - Point `ELITE.Brawler` at that mesh, with the recipe's new centre.
  - Then condition 1's looks.
  - After that, condition 9's contact sheet is mine.
- **Tools:**
  - `tools/blender/shade_elite_bare.py` is new: it cuts the copy, places it as the game does, and draws the look.
  - `tools/blender/shade_elite.py`'s `write` now names each elite's mesh and centres the copy.
- **Hours:** about 0.7.

### 8. The burst into light and paper: the block-in (Modulo, 2026-11-12)

Grey boxes on the delivered Burst clip: timing and size only, no art. Made on Opus 5.5 xhigh.

- **Where:** `build/scratch/modulo/shade/burst/`.
  - `burst_A.png`, `burst_B.png` and `burst_C.png`: twelve frames each from the player's assumed camera, behind a grey stand-in for the lead 7 studs in front of the Shade.
  - `burst_side.png`, `burst_bright.png` and `burst_64.png`: the three variants side by side.
  - `tools/blender/shade_burst_fx.py` rebuilds them in about a minute.
- **Feel line, proposed for research to sign:** the last hit lands and the Shade lets go: the light inside it leaps out of the empty collar into the sky, and the coat it lit comes apart into paper carried up after it, seen from behind the fighter.
- **Job and rank:** the payoff of every fight, seen many times a minute. So it's short, gone 0.4 s after the `Burst` marker, and it leaves the ground clear for the next pack. Not a signature.
- **The hero shape:** the light, one tall shape leaving the collar where the face was.
  - Direction: up, leaning 8° away from the fighter.
  - Acceleration: it leaps and settles, 7 studs in 8 frames, most of it in the first 3. Then it still climbs, thinning, and it's out 14 frames after the Burst. It's stretched along its travel while it's fast.
- **One idea, three times:**
  - The charge: light spills up out of the collar as the mask tips off it, 18 to 26, from 0.2 to 1.8 studs tall.
  - The punctuation: on the Burst frame (27), the coat is lit whole, one box in its outline. The body, the mask and the ties are hidden on that frame, as the content check holds (section 3).
  - The release: from 28, by variant.
- **Variants:**
  - A, the flame let go: the flame, and the coat in ten scraps, thrown out and tumbling down, gone before the floor.
  - B, the lantern bursts: a ball of light swells round the body to 5.5 studs and shrinks back by 14 frames, and the scraps fly out of it every way. The nearest to the white ball the game plays now.
  - C, the sky lantern: the flame, and the scraps drawn after it in a loose turning column, smaller as they climb, each gone 18 frames after it lifts. Nothing falls.
- **My pick: C.**
  - Everything goes one way: the light leads and the paper follows.
  - The ground stays clear, and by construction nothing can lie on the floor.
  - From behind the fighter, the release rises out from behind the lead.
  - B's ball sits on the line of sight and swallows the lead for ten frames. A's falling scraps read as debris at the fighter's feet.
- **On the clip's markers:** the charge from 18 to the Burst; the punctuation on the Burst (27); the flame from 28 to 41; the scraps from 28, all gone by 51.
- **Stand-ins, not decided here:** the lead's place (7 studs out), the camera (24° to the Shade's left of its front, 20 studs away), the rise (7 studs), the ten scraps, the two greys. Colour, texture and the light's own glow wait for the art sheet.
- **What I see wrong:**
  - At 64 px only the flare (27) and the flame's first frame (28) read. After 29 the flame and the scraps are a few pixels. That's the art sheet's first job: a larger, brighter flame, and scraps that catch the light. Bloom will help the flame in the engine, but the content check's "no red haze on the ground" limits how much it can carry.
  - On the bright floor the flare is pale grey on pale grey. It needs a rim or a darker edge, as Haymaker's bar did.
  - The charge is faint from the player's camera: the tipping mask covers most of the collar until 25.
  - From 31 to 34 the flame's box reads as a floating block. The art's shape, a tapering flame, has to carry the sense of something going up and out.
  - The scraps tumble edge-on half the time and read thin. In C they drift right of the flame's line, from the camera.
  - The 64 px sheet's labels cover a third of each tile, as on Haymaker's.
- **Not done:**
  - The art sheet: the flame's shape and colour, the scraps' paper and how they burn out, the rim.
  - Then the builder's build.
  - The beats aren't in a Definition.
  - The light and the paper get their own content check (section 3).
- **Hours:** about 0.6.
- **Research's verdict, 2026-11-12** (burst_side, burst_C). **Feel line: signed** as proposed. **C, the sky lantern**, for your reasons: one direction, the light leading and the paper following, and nothing on the ground for the next pack. **Felt:** the flare and the first frame of the flame say "let go", and then it's specks by 31. **Tier:** works, as a block-in should. **The one bold thing:** everything goes up. Fixes, for the art sheet:
1. **The flame carries the read to 34**, not 29 (serves: the payoff of every fight, read at 64 px from behind the lead). It's larger and brighter in its first six frames, a tapering shape, so it never reads as a floating block.
2. **The scraps rise under the flame,** in its column, not drifting right of it. One line up, from the camera.
3. **A dark rim on the flare and the flame,** for the bright floor, as Haymaker's bar has.

### 9. In the game: the second mask without its ties (Faber, 2026-11-12)

- **The upload:** `Shade_MaskBrawlerBare` for the group, `134287799840335`, by `ModelAssembly.PublishMesh`, Approved. Logged in `docs/asset-log.md`.
- **The template:** `ELITE.Brawler` in `tools/studio/Models/Shade.luau` names that mesh (`Mesh`) at the recipe's new centre, with the same axes. `src/storage/Shade.rbxm` is built again; in Studio its 16 joints are all attached.
- **Condition 2 holds,** read off a spawned elite: the three uploaded maps, `#FFE2B8` at 6, 0.6 of the first mask's width.
- **Self-test:** the elite case now checks the copy is as deep as the face alone (0.069 of the first mask's depth; the whole mask would be 0.6). Its 10 checks pass.
- **Condition 1's looks:** the game's elite under the game's lighting (ClockTime 14.5, bloom on), in Idle and Guard, on dark and bright ground. The images, internal, are in `build/captures/ar2/`.
  - **From behind, from below-left and from below-behind** (section 6's angles; `elite_bare_close.png`, dark above, bright below): no pale rod or strip in the cuff's hollow or past the sleeve, in any column.
  - **One pale shape stays from below-left:** a notched strip beside the sleeve. It's the head's own mask, seen edge-on past the arm. Hiding the head's mask removes it; hiding the second mask doesn't (`elite_bare_which.png`).
  - From behind, the strings high on the head are the first mask's, as designed.
  - **At 64 px,** from the front, the three-quarter and the side (`elite_bare_64.png`): the small mask stays pale on the arm, and from the front it shows as a thin pale edge, the copy's own face at its angle.
- **Next:** condition 9's contact sheet is Modulo's.
- **Hours:** about 0.7.

### 10. The elite's contact sheet (Modulo, 2026-11-12)

Section 5's condition 9, with the ordinary Shade beside it for section 6's 16/6 check, condition 2. `build/handoff/Shade/shade_elite_contact.png`, drawn by `tools/blender/shade_elite_contact.py`. Made on Opus 5.5 xhigh.

- **What it is:**
  - The baked model on the rig, with the copy without ties at the recipe's placement, seated at rest as the game welds it.
  - The nine delivered clips, from the player's camera.
  - Lit in Eevee with the uploaded maps at the game's numbers: body `#E80000` at 16, masks `#FFE2B8` at 6. Eevee has no engine tone map and no bloom.
- **What it shows:**
  - Each clip at its widest frame across the camera, plus the frame condition 9 names in the four first: Guard 44 braced, AttackLeft 30 Hit, HitLeft 3 struck, Burst 27. All at 64 px, on dark and on bright.
  - The four first larger, where the second mask comes nearest.
  - The ordinary Shade beside the elite in HitLeft 7, Burst 20 and Burst 27.
  - Every frame of every clip, measured: the second mask's triangles against the coat's, the right sleeve's and the first mask's (an exact overlap test), and its nearest approach. The numbers are in `build/scratch/modulo/shade/contact/shade_elite_contact.json`.
- **Found, AttackLeft crosses:**
  - From 26 to 31, round its Hit, the second mask cuts into the first mask, and into the coat at 26.
  - At 64 px the two masks are one pale shape.
  - The game plays Attack and AttackLeft in turn (`Config.Animations.Mirrors`), so it shows in the dev build.
- **Every other clip crosses nothing:**
  - The Guard comes nearest the first mask: 0.04 studs at 79, in the let-fall.
  - Lunge: 0.07 at 68.
  - HitLeft: 0.23 at 3.
  - Attack: 0.27.
  - The game doesn't play Guard or Lunge yet.
- **What doesn't fix it,** measured, throwaway, in `build/scratch/modulo/shade/contact/explore/` and `explore_b/`:
  - Sliding the mask down the arm, or turning it round the arm toward its outer face: AttackLeft is cleared only by crossing the Guard or the sleeve's bell, or by facing side-on (way A, rejected in section 5).
  - Narrowing the swing: with the sleeve's swing out cut from 86° to 50° and its rise at the Hit from 80° to 64°, the masks still cross at 29 and 30.
  - **The cause:** the coat turns 32° under a mask that keeps watching the lead, which carries the left shoulder under the first mask's edge. That is the attack itself ("the mask still watching"), so a clip fix is a real re-pose.
- **Proposed fix, for research (tier 2):** the elite plays Attack in AttackLeft's place. It's a code change in the builder's `FighterController`, and no passed clip, mask or placement is touched. The other way is a re-posed AttackLeft (frames about 24 to 32), which goes back to the check and changes every Shade's swing.
- **What I see wrong:**
  - At HitLeft 3 the small mask is clear of the first by 0.23 studs, but at 64 px the two stack into one pale cluster by the head. That's a read for research, not a crossing.
  - The measure covers each clip's own frames, not the blends between clips.
- **Content check, 2026-11-12:**
  - **Rules 2, 3 and 4: PASS.** Nothing on the sheet is for upload.
  - **Condition 9: BLOCK, for the public build only.** The dev build keeps the elite as it is. To hold:
    1. AttackLeft is fixed, by (a) the elite playing Attack in its place (the check's recommendation too) or (b) a re-posed AttackLeft, which comes back to the check. If (b) changes every Shade's clip, the ordinary Shade's passes are looked at again.
    2. After the fix, this sheet's AttackLeft columns and measures are drawn again: no crossing in any clip the game plays.
    3. Before Guard or Lunge go into the game, one look in the engine at 64 px through the blends from Idle into each, since their margins are thin.
    4. Sections 5, 6, 7 and 9's other conditions stand. Any clip, placement or glow change comes back to the check.
  - **Closed by the sheet:**
    - Condition 9's second mask, colour and nine clips at 64 px on both grounds, with the four first.
    - The Guard holds.
    - The 16/6 check's side-by-side, Strength red reading as thin rims with nothing like blood.
    - "A body lying in red": nothing lies. Burst 27 is the clip's last frame, standing, and the game hides every part on the `Burst` marker, the second mask with them, so condition 8's "same frame, never last" holds.
  - **Open in the 16/6 check's condition 2:**
    - Bloom hazing red onto the ground. It needs the builder's engine capture: ordinary and elite, HitLeft and Burst up to the marker, at 64 px on dark and bright, under the game's lighting.
    - Red reaching the paper scraps. It closes at the burst's art sheet and its own check (section 8).
- **Hours:** about 1.5.
- **Research's pick, 2026-11-12: (a).** The elite swings Attack every time; the ordinary Shade keeps alternating. An elite is the heavy of the pack, and the same arm again and again reads as weight, not as a missing clip. Nothing that passed is touched, and the ordinary Shade's clips aren't reopened for one figure. Faber builds it in `FighterController`; Modulo redraws the AttackLeft columns as the elite's Attack. **HitLeft 3's pale cluster: accepted.** It's one hit-reaction frame, and the masks part on the next.
- **Redrawn for (a)** (Modulo, 2026-11-12): the sheet in `build/handoff/Shade/` replaced. It shows the eight clips the elite plays, Attack in AttackLeft's place, with Attack's Hit at 30 as the named frame. Nothing crosses in any of them; Attack comes nearest the first mask at 26, 0.27 studs. Made on Opus 5.5 xhigh.
  - **Content check, 2026-11-12:** rules 2, 3 and 4 PASS, and condition 9 holds on this sheet. To hold before the public build:
    1. The builder's change only picks the clip, so no new check. It's shown, not stated: a self-test case proving an elite never plays AttackLeft by any route, while the ordinary Shade still alternates.
    2. Attack into Attack is a new blend, and the sheet measures each clip's own frames only. One engine look at 64 px of an elite swinging Attack several times in a row, from the player's camera, in the builder's player-camera review. If the masks merge in the blend, it comes back to the check.
    3. Still open, as above: Guard's and Lunge's look through the blends, the bloom capture, and red on the paper (section 8).

### 11. The burst's look: the art sheet (Modulo, 2026-11-12)

The block-in's C, the sky lantern, with research's three fixes (section 8). Made on Opus 5.5 xhigh.

- **Where:** `build/handoff/Shade/fx/`:
  - `shade_burst.png`, the one picture, 1024 x 768;
  - `shade_burst_art.png`, the sheet;
  - `shade_burst_art.json`, every picture on every frame.
  - Made by `tools/blender/shade_burst_art.py` in about 15 seconds, in Workbench: `blender -b --factory-startup --python tools/blender/shade_burst_art.py -- <out dir>`.
- **One picture, one upload:**
  - **The flame:** eight frames of 128 x 256 along the top. It burns upward, with a round base hottest low in its middle and three tongues pointing up. It boils between frames 0 and 1, then frames 2 to 7 eat it from its tongues and edges back to an ember at its base: 8, 18, 32, 48, 64 and 80% gone.
  - **The paper:** four torn scraps below, eight frames of 128 x 128 each. Some edges are cut and some torn, with a fold across. Frame 0 is whole; the others burn it from one side, a char line before a gold front, 10 to 90% gone.
  - **Three tones each, hard edges:** the flame is a warm-white core (`#FFF8EA`), a lantern gold (`#FFC861`) and the Shade's ink (`#100D17`) as its rim. The paper is the masks' paper (`#EFE6D2`, `#C9BA9C` on the fold), an ember front (`#FFB040`) and the same ink. Nothing in it is red.
- **One shape, three times:** the charge is the flame small in the collar; the flare is the flame the coat's size, on the Burst frame; the release is the flame let go.
- **Research's fixes:**
  1. **The read carries to 34.** The flame is 3.0 studs wide and 5.2 long at 28, stretched while it's fast. Over its six hot frames it tapers to 2.5 by 3.3 at 34.
     - Measured at 64 px from the player's camera, the light alone, without the paper: 132 px at 28, 108 at 31, 79 at 34. The block-in's were 99, 51 and 37.
     - The art at 34 is as large as the block-in was at 30 (73).
  2. **The paper rises in its column.** Each scrap is drawn in to the flame's line within 6 frames and turns round it, close in. The line leans 8° with the flame, so from both cameras it's one line up.
  3. **The ink rim:** about a pixel at 64 px on the flame and the flare. It holds them on the bright floor; on the dark floor the gold carries the edge.
- **The numbers it's played at** (the clip's frames, 60 a second; `Burst` is 27):
  - **The charge, 18 to 26:** the hot frames, a step every two frames. Its foot is on the collar, from 0.6 x 0.4 studs to 1.1 x 1.8.
  - **The flare, 27:** frame 0, 3.8 x 5.4, its top 0.9 over the collar.
  - **The flame, 28 to 41:** frames 0 and 1 in turn to 33, then 2 to 7. Its tip climbs 7 studs in 8 frames, then 0.2 a frame, leaning 8° away from the lead. It's out after 41, 0.23 s after the marker.
  - **The paper, 28 to 49:** ten scraps of 1.3 studs where the coat stood. Each lifts 1 to 6 frames after the Burst and rises 8 studs over 18 frames, a third smaller as it climbs and burnt through its eight frames over 17. All gone after 49, 0.37 s after the marker.
- **For the builder (your call, Faber):**
  - **One way:** each picture is a `BillboardGui` with an `ImageLabel` on the one upload, stepping `ImageRectOffset` and `ImageRectSize` by the table, with `LightInfluence` 0.
  - **The table:** each picture's centre from the collar, in the Shade's right, forward and up as it stood at the Burst. On the charge's frames it's from the Torso's collar point. Also the size in studs, the rectangle, the scraps' `Rotation` and their width's squeeze, which is the flutter.
  - **No glow is drawn.** The hot frames' brightness is yours: `Brightness` and the bloom.
- **A correction to the block-in's stand-in camera:**
  - The lead fights beyond its target, 45° off the line (`Combat.Lead.Frame`, `FightService`). So the player sees the Shade being fought from behind on its right, about 135° off its front.
  - The sheet's main rows are from there. The block-in's front-left camera stays for another Shade of the pack.
- **My calls (tier 1):**
  - **The flame burns upward.** The block-in's shape was a head trailing a tail. Drawn that way, its tongues hung down like drips (the check's "no drip"), and the head read as a bulb.
  - **The paper is the masks' paper,** not the coat's dark. It catches the light on both floors.
- **What I see wrong:**
  - The flare at 27 is only a little larger than 28's flame: the punctuation is the body going out more than the light's size.
  - The charge barely shows from the player's camera: the coat and the tipping mask hide the collar until 25.
  - The boil swaps frames every frame at 60 a second, as Haymaker's does. It may flicker; the replay judges it.
  - After 38 the paper is specks: the read is over by then.
  - It's a preview in my renderer: no bloom, no camera move.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4 and the conditions from sections 3 and 8. "Red reaching the paper scraps" is closed on the art. To keep it a pass:
  1. **Never tinted:** `ImageColor3` white, never the type's colour; `LightInfluence` 0. A tint, a colour or added glow comes back to the check.
  2. **One engine capture closes the red item:**
     - The shot: a Strength Brawler, ordinary and elite, through Burst 18 to 45 at 64 px, on dark and bright, under the game's bloom, from the player's camera.
     - It must show no red on the flame or the paper, no red haze on the ground during the charge, and nothing red after 27.
     - It can be section 10's bloom capture.
  3. The hide at 27 stays on the flare's frame.
  4. The scraps only rise, shrink and end. A falling or landing variant comes back to the check.
  5. The image is logged in `docs/asset-log.md` and uploaded for the group by the key.
- **Not done:** research's verdict; the upload; the builder's build and replay; `ga-fresh-eyes`, if research wants it.
- **Hours:** about 1.0.
- **Research's verdict, 2026-11-12** (shade_burst_art, shade_burst). **On to the builder.** **Felt:** the last hit lands and a small warm flame leaves the coat and climbs, its paper following it up, gone before the next pack arrives. A kill feels like letting something go, not like a mess. **Tier:** competent. **The one bold thing:** the light leads and the paper follows, in one column. The three fixes land: 79 px of light at 34 against the block-in's 37, the paper in the column, and the ink rim holding on the bright floor. Both your calls are accepted. The flame burns upward, since tongues hanging down read as drips. The corrected camera is the view players have. One flame for every type, warm white and gold: the type is told while the Shade lives, and the release is the same for all, which keeps the check's "no red". No `ga-fresh-eyes`, since it isn't a signature. **For the builder's replay:** under the game's bloom, the cream core must keep its gold edge and not wash to a white blob; that look is the final, beside the bloom capture that closes the red item.

### 12. In the game: the elite swings Attack every time (Faber, 2026-11-12)

Research's pick (a), section 10.

- **The change:**
  - `Config.Animations.Unmirrored` names, by a fighter's `Kind`, the clips it never trades for their mirror. `Elite = { ShadeAttack = true }`.
  - `FighterController`'s `pick`, the only route to a mirror clip, reads it.
  - The ordinary Shade still alternates Attack and AttackLeft, and Hit and HitLeft. The elite keeps its HitLeft.
- **Condition 1, shown:**
  - "Fight: the elite swings Attack every time" (new) sees 7 swings, every one Attack.
  - "Fight: a Shade swings and flinches on alternate sides" still sees 8 alternating swings and alternating flinches. Both cases share one watcher (`swingsOf`).
  - A live fight's log: 10 swing starts in 12 s, every one Attack.
- **Condition 2, the engine look:**
  - An elite fighting Rook, from the player's camera, under the game's bloom, at 59 fps, on the bright floor.
  - Four Attack joins, every other frame, at 64 px, in `build/captures/ar2/`:
    - `elite_attack_joins_64.png`, as played.
    - `elite_attack_joins_flag_64.png` and `_x2.png`, with the first mask flagged magenta and the second green. The flags were runtime Highlights for the take only, never saved.
  - Unflagged, the check couldn't tell one pale shape from two, so the flags were added.
  - Through every join only the first mask shows. The second appears after the hit, as a sliver at the shoulder's edge, two shapes.
- **Content check, 2026-11-12: PASS on condition 2.** To hold:
  - No Highlight or flag colour goes into `src/`, the place or an upload.
  - **For research's pass (taste, not a rule):** in a few follow-through frames the second mask's sliver sits against the first mask's lower edge (x2 sheet: row 2, tiles 7 and 8; row 4, tile 6). Unflagged, both are cream, so at 64 px it may read as the mask with a pale strip under it. If it reads as one shape at the player-camera review, it comes back to the check.
  - Still open: Guard's and Lunge's look through their blends, before either goes in. The bloom capture: ordinary and elite, HitLeft and Burst, on dark and bright. That capture also closes section 11's red item and its gold edge.
- **Tests:** Fight cases 130/130 at 60 fps; logic 1,376; type check, 0 new.
- **Hours:** about 0.7.
- **Research, 2026-11-12: accepted**, the taste note included. A sliver touching the first mask's edge for a few follow-through frames is a moment, not a merged shape.

### 13. In the game: the Shade's burst (Faber, 2026-11-12)

Section 11's sheet, played by its table, with the content check's conditions shown.

- **The build:**
  - `Config.ShadeBurstArt` is the sheet's table, generated by `tools/art/art_table.py` from `shade_burst_art.json`: frames 18 to 49, 211 pictures, ten scraps. A logic case reads it (below).
  - `Effects.ShadeBurst` plays it. Each picture is a `BillboardGui` on the one upload (91970461037109, `Config.Effects.ShadeBurst`), stepping `ImageRectOffset` and `ImageRectSize`, the scraps' `Rotation` and their squeeze. `ImageColor3` is white, `LightInfluence` 0, `Brightness` 1.
  - Each picture's centre comes from the Torso's `Collar` point, in the Shade's right, forward and up as it stood at the Burst, scaled with the model (the elite's 1.35).
  - The charge (18 to 26) follows the clip's own time. From the `Burst` marker on, frames follow the clock, rounded to the nearest frame.
  - The body hides on the flare's picture.
- **What the engine does, seen in the takes** (OBSERVED, at 60 fps from the window's raw pictures):
  - A `BillboardGui` made, shown or changed in `RenderStepped` is drawn one picture late.
  - One set fully see-through goes the same picture.
  - A part's `LocalTransparencyModifier` shows the same picture.
- **So:**
  - Every picture's billboard is made at the start, enabled and see-through, and shown by its image's transparency.
  - A picture is cleared a step late, so it never blinks between frames.
  - The body hides a step after the flare is set, so the hide's picture is the flare's. Before this, 27 and 28 drew nothing.
  - The rounding: holding frame 27 for whole steps drew the flare twice when a step was short; nearest-frame draws it once.
- **A leak, found by the full suite:**
  - One burst stayed on the self-test's pad for good, 13 billboards.
  - On the old code: hold a fallen Shade's Down clip still and let the server take the body. The body never hid (the clip sat at 0.05 s, the marker at 0.45), and the burst stayed after the hold was let go.
  - The charge ran on the clip's clock with no end: a body that left with its clip short of the marker left its burst behind. A Shade cleared during the killing hit's hold, its clip at rate 0, fits.
  - Now a body gone before its marker takes the charge with it.
  - A clip that never reaches its marker bursts anyway `Config.Effects.ShadeBurst.Wait` (0.4 s) past it, at 0.85 s from the fall. That's after the longest hold (0.13 s) and before the server takes the body (1.2 s). A logic case holds the order.
  - The case "a Shade's burst never waits for good on a clip held still": a held clip bursts at 0.88 s and its burst ends; a body cleared while its clip is held takes its burst with it, 0.17 s after its fall.
- **An axis fix:** the table's offsets are right, forward and up. `VectorToWorldSpace` reads right, up and back, so the flame first slid along the ground instead of climbing. The case's "on its line" check holds it.
- **The conditions:**
  1. **Never tinted:** shown by the self-test's "untinted and unlit, the group's picture" check.
  2. **The engine capture,** in four takes, from the player's camera (the replay's 20° and 12.5 studs; the elite's takes turned toward the fight, which it fights beside the avatar):
     - The setup: a Strength Brawler, ordinary at level 3 and elite at level 1, against Pip at level 1, under the game's bloom, lossless at 60 fps, on dark `#1B1922` and bright `#E8E4DA`.
     - Each burst frame is placed in the take by a one-picture mark on the hide. Frames 18 to 45 are cut at 64 px.
     - **Red after 27:** the count is r ≥ 120 and over 1.8 times g and b, at the window's own pixels. It's 0 to 1 (dark ordinary), 0 to 5 (bright ordinary), 0 to 8 (dark elite) and 0 to 6 (bright elite). Every such pixel is the same orange-brown, r 128 to 181, g 65 to 98, b 30 to 49, at Pip's lantern. None is on the flame, the paper or the ground.
     - **18 to 26:** the count is the Shade's own coat and trims, 2,600 to 6,200 pixels. No charge frame shows haze on the ground, on either floor.
  3. **The hide at 27:** in each take's raw pictures, the hide's picture holds the flare. Every picture after it is a new frame, with no blank and no flare twice.
  4. **The scraps:** the logic case reads every scrap through the table: none ever falls, none ever grows, and each ends.
  5. **The image:** asset-log row 17, uploaded for the group by the key, Approved.
- **Research's note:** under the bloom, the cream core keeps its gold edge and its ink rim on both floors, at 64 px and at the window's size (`_native`). It doesn't wash to a white blob.
- **Section 10's bloom capture:**
  - The ordinary's HitLeft, 3, 7 and 12 frames in, on both floors: the red trims stay crisp, with no halo on the floor.
  - The elite never plays Hit or HitLeft in a fight: `Combat.Flinch.Kinds` leaves it out, and the takes saw no hit clip in two fights of about 22 s each. Its part of the capture is the Burst.
- **For research's read:** at this camera, the rising flame passes behind the damage number about 31 to 34. On the ordinary takes the ember at about 34 climbs into the HUD's top-right panels (Credits, the bar).
- **Where:** `build/captures/ar2/` (gitignored):
  - `burst_<floor>_<kind>_64.png` (18 to 45), `_64x3.png` (eight frames at 3x), `_native.png` (27, 28, 31, 34), `_64.tsv`;
  - `burst_<floor>_ordinary_hitleft_64x3.png`;
  - the takes, `burst_take_<floor>_<kind>.mkv` and `.json`.
  - In the elite takes the grab repeats a whole-window picture byte for byte about every fifth picture: the grab's, not the game's.
- **Tests:**
  - The Shade's case: the flare set on 27, the charge in the collar before it, the flare in the hide's own picture, its centre 1.8 under the collar and on its line, untinted, and nothing left after its last frame.
  - Its marker check now counts the steps that ran: never before the marker, within two steps after it. In nominal frames, one long frame in the full suite tipped it (0.48 against 0.45 ± 2 frames). It now reads 0.467 s, a step of 17.2 ms.
  - The full suite at 60 fps: 399 of 400. The one fail is the Base screen's label size at the smallest phone's scale (11.9 px under 14), the HUD/Base intermittent queued next, outside this piece's files.
  - Logic 1,584; type check, 0 new. The place saved, v185.
- **For later:** Pip's Lantern Burst and Haymaker's bar turn their billboards on and off on their frames, so each is a picture late at the start and a picture short at the end; a line in `docs/polish-later.md`.
- **Hours:** about 4.5, most of it the picture lag and the leak.
- **Research's pass, 2026-11-12** (`_native` and `_64x3` on both floors, the ordinary's 64 px row, the HitLeft captures). **Accepted. The Shade's burst closes**, with no ga-fresh-eyes since it isn't a signature.
  - **Felt:** the coat's glow lets go, a cream flame with its gold edge and ink rim leaps out of the collar, climbs and pinches to an ember, and the paper follows it up. A Shade that's done, said once and quickly.
  - **Tier:** competent. **The one bold thing:** everything goes up, as the block-in promised, and on the bright floor too.
  - **Section 11's note holds:** the core never washes to a blob, on either floor. **Section 10's capture holds:** the trims stay crisp, with no halo on the floor.
  - **The damage number at 31 to 34:** the rising flame crosses the killing hit's number as it fades. It's brief, and the number stays legible. To `docs/polish-later.md`, not a fix.
  - **The ember under the HUD's top-right panels:** the HUD draws over it, which is the right order. Accepted.
  - **`ShadeBurst.Wait` 0.4: accepted.** A held clip still bursts, between the longest hold and the body's removal. A burst that never comes would be worse.
  - **The elite never flinches:** accepted, as `Combat.Flinch.Kinds` has it.
  - **Still open:** Pip's flame and a Shade's flame rising together. That needs one take of Pip's Lantern Burst killing two Shades, from the player's camera, after Pip's round 2 is imported.

## AR3. The UI kit

For Modulo, from `docs/ui.md`. After AR1's sheet, so the kit is designed against a real Voidkin's portrait.

**Feel line:** a panel that looks cut from a shard and a bar that fills like light through a conduit: the interface of a game that costs money, quiet until something happens.

**Delivers:** a direction sheet first (the lead's card, a rarity frame for each of the six launch rarities, a pill, a button in all its states, a panel, the damage numbers, in Graphite Dark and Pearl Light, at phone size); research's verdict and the director's eye on that sheet; then the kit as sliced images with their insets, and the five type gems, five class icons and four element marks.

**Checks:** the content check; legible at phone size over a bright and a dark world; research's verdict.

**Status:** the direction sheet is past the content check and research's verdict, its three fixes drawn and passed (section 1), and delivered to `build/handoff/UI/ui_sheet.png`. The director's eye, 2026-11-12: Graphite Dark is the main theme; Pearl Light stays for some screens, drawn with a black border (`docs/decisions.md`, the director's words). The kit's images start from the sheet, Graphite first. The director, on the same sheet: some screens get a palette of their own on the same kit, and Mythical's light is reddish, not the split rainbow; its broken crown stays. The glance strip is drawn again with the red Mythical, beside the failed button and the Strength gem, at 1 pt over both themes. That round is drawn, past the content check and research's read (section 1, "The director's words, drawn on the sheet"), and delivered to `build/handoff/UI/ui_sheet.png`, with its foot at true size in `ui_glance.png`. The kit's images are made, past the content check, and delivered to `build/handoff/UI/kit/` (section 2). Research's verdict on them: competent, the frames exceptional, the four palettes accepted; its five fixes are drawn and past the content check (section 2, "The fix round"), so the kit is ready for the builder. Nothing is uploaded or in the engine. The director, 2026-11-12, to Modulo: which screens are Pearl and which get their own palette is Modulo's to choose (section 2). The HUD's portraits, the silhouette and the critical's sweep are made, past the content check, and delivered to `build/handoff/UI/hud/` for research's verdict (section 3).

### 1. The direction sheet (Modulo, 2026-11-12)

`build/scratch/modulo/ui/sheet/ui_sheet.png`, 2400 by 2144, drawn by `tools/blender/ui_sheet.py` at 2 pixels a point. Both themes side by side: the lead's card, the two pills and the damage numbers over a dusk street and a noon street; the six frames round Rook's portrait; a button's seven states; a panel with two buttons, a long name in a Legendary frame, and three bars (full, low, empty); the four HUD strips again at 1 pixel a point.

**Calls, all mine to be judged:**

- **One cut.** Every piece is a rectangle with its top-left and bottom-right corners cut, never rounded. A panel has one facet line at its top-left cut and nothing else.
- **Light is ivory** (`#FFF4D6`), the plain hit number's own colour, and it always runs in a dark channel: a bar's fill, a button's lower edge at rest, the edge of a selected one, the run of light on a waiting one. Green and red light only say succeeded and failed, and both come with words.
- **A rarity is a shape and a light, never a hue.** Common: two cuts, iron. Uncommon: four cuts, steel, a second line inside. Rare: one crest, silver, a soft glow. Epic: a crest and a base point, side notches, white-hot. Legendary: a three-point crown, gold. Mythical: a broken four-point crown in red light (the director, 2026-11-12; it split light before). The five hues stay the types', on the gem in the frame's top cut. The class's mark sits in the bottom cut.
- **Numbers** slant 0.22 and carry a dark stroke that follows their size (1.5 points on a 20 point number, 1 point under it). Proposed element colours, for research: Fire `#FF8A3D`, Frost `#8FE3FF`, Storm `#FFE45C`, Void `#B58CFF`.
- **Pearl Light** is the same kit on a pale panel, with two extra rules found by drawing it: a bar's light keeps a 2 point dark rim all round, and a frame sits in a dark seat, or silver and white-hot frames vanish.

**Research's question on Agility's blue** (AR2, section 1): the five gems are drawn under a cyan lamp (`#5FE3F0`) and a warm one, at two sizes, at the sheet's bottom right. Agility's `#3F9DF2` stays its own beside the cyan: it's deeper and bluer, and the gem's dark rim holds it. I'd keep it.

**Stand-ins, not the kit:** the type face (Blender's own), the gems, the class mark, the coin and the bolt, the two streets.

**What I see wrong:**

1. On Pearl, a bar's lit part is nearly the panel's own colour. The rim holds it, but the dark empty part is what the eye takes first. The Graphite bar doesn't have this.
2. Common and Uncommon are close at 1 pixel a point: the second line and the two extra cuts are small.
3. In the lead's card the frame is 40 points wide, and a crown's small points clot there. The card may want its own cut of each frame: the crest only.
4. Over the dusk street the numbers' stroke does nothing (they read without it); over noon it's what carries them, and `Dodge` in grey is the weakest.
5. Pearl's waiting button: the run of light on its top edge is faint. The three dots carry the state.

**Content check, 2026-11-12: PASS** on rules 2, 3 and 4, for the direction sheet only, the HUD strips seen at 1 pixel a point. To hold on the kit's build:

1. No shipped image carries text in Blender's face: the game's text is Roblox's fonts or our own drawn digit sheet, which gets its own check.
2. The Strength gem stays a hard-faceted stone with its dark rim, in its slot: never round, a teardrop, glossy like a liquid, or scattered. Re-checked alone at 64 px over dark.
3. The stand-in class mark reads as a plus or a bare cross at 1 pixel a point: the Warrior's icon needs a clear taper and a guard.
4. The five class icons, four element marks, the final gems, the coin and the bolt each get a check against hate symbols and real logos.
5. Failed, low health and fallen stay edge light, dimming and words: never a red wash, streak or splash across a portrait.
6. "Sledgehammer Sunday" stays a long-name test string, or goes through the roster's name check.
7. Before upload, each sliced image gets a review sheet at full size and at 64 px over dark, and its row in `docs/asset-log.md`.

- **Research's read** (Quaestor, 2026-11-12, on ui_sheet.png at full size, both themes, the 1 pt strips): yes to the direction, carrying fixes 1 to 3 into the kit.
  - **Felt:** Graphite looks like a game that costs money and keeps quiet. The cut corners and the ivory light running in dark channels are one idea, used everywhere, and the crit's gold number is rightly the loudest thing on screen. Pearl is the weaker theme: its bars and its waiting state lose their light.
  - **Tier:** competent.
  - **The one bold thing:** light only ever runs in a dark channel: the bar as a conduit, the button's lit lower edge, the selected one's rim. It's ours, and a player will learn "lit means live" without being told.
  - **Fixes:**
    1. **The rarity ladder must read at a glance.** At 1 pt, Common and Uncommon are the same frame, and Rare and Epic differ by a notch. Each step has to add one thing you can see at 64 px: a cut, a point, a step of light. The test is the six frames shuffled at 1 pt, over dark and over Pearl, sorted correctly at a glance (serves: the reveal and the Voidkin grid, where rarity is the whole read).
    2. **Pearl's full bar reads as an empty outline.** The fill has to be the warmest, brightest thing in the bar and never the panel's colour: for example a warm core under the ivory, or a deeper channel. The test is full, low and empty told apart at 1 pt on Pearl (serves: health read at a glance, in the theme some players will live in).
    3. **Storm leaves yellow.** #FFE45C beside the crit's gold reads as a small crit, in the same channel. Try a hot magenta (around #FF6FD8), tested beside the crit, the heal and Void's violet at 1 pt over both streets (serves: the crit owning gold).
  - **Your three questions:**
    - (1) Rarity as shape and light, with the five hues kept for the types: yes. It's what docs/ui.md asks, and hue rarity would collide with the type gems. Gold and the split light stay where the excitement is, at the top two.
    - (2) Agility's #3F9DF2: kept. Beside the cyan lamp the gem holds as its own.
    - (3) Fire #FF8A3D, Frost #8FE3FF and Void #B58CFF: yes. Fire sits near Endurance's orange, but in another channel, so the element marks read by shape first. Storm per fix 3.
  - **Accepted:**
    - the lead card's own crest-only cut of each frame;
    - the one cut and the single facet line;
    - Pearl's dark seat for frames and the 2 pt rim;
    - Pearl's faint waiting edge, carried by the dots;
    - grey Dodge at noon, carried by its stroke;
    - green and red only with words.
  - Storm's colour is research's call as lead designer, recorded here; it touches the builder's damage numbers when they come. Research is putting the sheet in front of the director.

**Fixes 1 to 3, drawn on the sheet** (Modulo, 2026-11-12; the sheet is now 2400 by 2316, with a glance-test strip a theme at its foot: the six frames out of order at 64 px, and a bar full, low and empty, at 1 pixel a point):

1. Each rarity adds one thing: Common a hairline in dark iron; Uncommon a thick band of bright steel; Rare a point on top and the first glow; Epic points all four ways, white-hot; Legendary a crown of three in gold; Mythical a broken crown that splits light. The side notches became points that stand out. In the strip I sort all six at a glance on Graphite; on Pearl, Common and Uncommon are the closest pair, told by the pale band inside the seat.
2. On Pearl a warm light burns gold at its edges and white at its core, inside the 2 point rim, so a fill is never the panel's colour. Full, low and empty are three different things in the strip. Graphite's bar is unchanged.
3. Storm is `#FF6FD8`. All four elements now stand beside the critical and the heal over both streets, at both sizes: Storm no longer reads as a small critical, and it holds apart from Void's violet.

- **Research's read on fixes 1 to 3** (Quaestor, 2026-11-12, on the glance strips at 1 pt and the street panels): all three pass.
  - **The six frames, shuffled:**
    - On Graphite they sort at a glance: none, a double line, a crest, a crest with side points and white glow, gold, the prism.
    - On Pearl they sort too. Common and Uncommon are the closest pair, held apart by the double line, and Epic's white glow drops out, so on Pearl Epic is told from Rare by its side points alone.
    - Accepted. The kit keeps the side points as wide as drawn.
  - **Pearl's bar:** full, low and empty are told apart at 1 pt. Gold at the edges and white at the core reads as full now.
  - **Storm #FF6FD8:** clear of the crit's gold and the heal's green over both streets. It stays apart from Void's #B58CFF at 1 pt, the closest pair, and holds over the dusk street.
  - The kit's sliced images start from this sheet once the director has looked at it (the entry's "the director's eye"). I've put it in front of the director.

**The director's words, drawn on the sheet** (Modulo, 2026-11-12; `build/scratch/modulo/ui/sheet/ui_sheet.png`, and its foot alone at true size in `ui_glance.png`):

1. **Mythical's light is red.** The broken crown is as it was. Its metal runs from a pale red at the crown to a deep one at the base (`#FF8794` to `#B3122E`), the glow is `#FF2848`, and a white-hot line runs inside it as on Epic and Legendary. The split light is gone from the script.
2. **Pearl's pieces carry a black border,** 1.6 points, on panels, pills and buttons. A bar's rim and a frame's seat were dark already.
3. **The glance strip has a second half,** at 1 pixel a point on both themes: the Mythical frame with a Strength gem in its cut, a failed button with its words, the gem alone at two sizes, and the lead's card in a Mythical frame on low health.
4. **A gem in a frame's cut sits in a dark seat** (mine, tier 1). Without it the Strength gem was red on red in a Mythical frame.
5. **The colours stay swappable.** Every colour a piece uses comes from its theme's one row in the script, and the kit's images will be cut so a screen's own palette is a new row, not new images. Which screens are Pearl, and which get their own palette, isn't chosen here: that's the director's.

**What I see, at 1 pixel a point:**

- Shuffled among the six, Mythical sorts at once on both themes: it's the only red, and the crown is the tallest shape. Gold, white and red are three steps nobody mixes up.
- Beside the failed button it doesn't read as "failed". The button's is a thin dull line round a plain box, with words under it. Mythical's is a wide crown that glows. But they're one family of hue, and on Pearl, where every glow is weaker, they're closer than on Graphite.
- The Strength gem holds in its seat. In the lead's card the frame has no gem; the card's own gem sits beside it on the panel, clear of the glow.
- On low health in a Mythical frame, the amber of the bar's low light sits near the frame's red. They're apart on the card, and the bar's is a line, not a crown.
- Pearl's black border makes its buttons the strongest thing on a Pearl panel, more than Graphite's are on theirs. A disabled button's border is faded with it.

**Content check, 2026-11-12: PASS** on rules 2, 3 and 4 for this round, for the direction sheet only. The red is edge light: it's painted under the slot and the portrait, so none of it lies across a face, and it reads as a lit sign at full size and at 1 pixel a point. The broken crown matches no symbol or logo the check could name. Its one spot near the line was the splinters, red like the metal and trailing off the lower corner at 64 px; they're white-hot on the sheet now, drawn after the check. Added to the first check's seven, for the kit's images:

8. The red stays the frame's own line and outer halo. It never fills, tints or crosses the portrait, never pools or shifts below the frame, and never pulses, thickens or spreads inward on low health, failed or fallen: those states stay as condition 5 says, on a Mythical card too.
9. Mythical's splinters are white-hot or dropped under about 96 px wide, and stay straight-edged triangles, never a shrinking row of red specks under the frame's foot. The Mythical slice's review sheet settles it at full size and at 64 px over dark.
10. The crest's and the base's points stay straight-edged, sharp and no taller than about their width, never rounded, lengthened or tapered. Any motion on the frame (a flicker, a break-off, particles) gets its own check.
11. The card's 40-point cut is checked alone at true size over dark: the ring stays open with its white core showing. If the points fuse into a solid red mass over the head, the card takes the crest-only cut.
12. The Mythical frame alone, with no portrait and on transparency, gets its 64 px look over dark before upload, with the other slices.

**Hours:** the sheet with its fixes, about 2.1; the round on the director's words, about 0.5.

- **Research's read of the round** (Quaestor, 2026-11-12, on `ui_sheet.png` and `ui_glance.png`): yes. The kit's images start, Graphite first.
  - **Mythical:** red, with the broken crown the tallest shape. It sorts at once among the six on both themes, and gold, white and red are three clear steps. The failed button shares its hue but never its shape, and it always carries words (rule 3's "green and red only with words"), so that holds. On Pearl the halo washes toward pink at 1 pt. The director asked for reddish, so the Pearl Mythical slice is read at 64 px for "red, not pink", and its halo deepens if it doesn't pass.
  - **Pearl's black border:** it's what Pearl lacked. The pieces stand off the cream at both sizes. Buttons on Pearl now outweigh their panels more than Graphite's do; that's acceptable for the few screens Pearl will dress.
  - **The dark seat under a gem:** accepted (tier 1). The Strength gem holds inside the Mythical frame.
  - **Swappable rows per theme:** accepted. That's what keeps the director's "other palettes for some screens" from costing new images.

### 2. The kit's images (Modulo, 2026-11-12)

`build/handoff/UI/kit/`: 89 images in `images/`, `kit.json` (each image's size, insets, reach and what colours it; the four palettes' rows; the bar's measures), and the review sheets. Made by `tools/blender/ui_kit.py`, at 4 pixels a point (SliceScale 0.25). Nothing is uploaded or in the engine.

**How it's cut.** A slice is white wherever a palette colours it, so a palette is one row of colours and never new images: the engine tints a slice, with a gradient for a panel's two colours. Graphite and Pearl are therefore the same images. A rarity's frame, a gem and a mark keep their own colours on every palette. No image carries text. A clear pixel keeps its neighbour's colour, so a scaled edge doesn't darken.

**What's in it:**

- **A panel** (body, edge at two weights, the glint on its two deep cuts, the facet, the shadow). A pill is the same slices at 30 points high.
- **A button** (body, edge at two weights, shadow, the light on its lower edge and its glow, the ring of light and its glow, the shade of a pressed one, the waiting dots and their well, the tick). Its seven states are these layers, shown in each palette.
- **A bar** and a **thread** (channel, edge), with one light for both (the light, its white core, its head, its glow), placed by `kit.json`'s measures.
- **The six frames, each in two cuts:** the full one, 80 by 96 points, for 64 points wide and up, and the small one, 40 by 48, with the crest alone, for the lead's card. Each is three images: its light and well under the portrait, the frame over it, and the dark seat a pale panel gives it. `masks/` holds each frame's shape, to cut a portrait to it before upload; the masks aren't shipped.
- **The five type gems,** each its own cut as well as its colour, so they're told apart without colour: Strength a six-sided stone, Endurance a square one, Agility a tall kite, Intelligence a triangle, Technique a brilliant seen from the side. Each comes bare and in its dark seat.
- **The five class marks:** Warrior a blade on the slant with its taper and guard, Tank a shield with its boss, Assassin a cowl with a leaning peak and one narrowed slit for the eyes, Mage a broken ring round a core, Healer a cut heart. Each comes in its dark seat and as a bare white glyph.
- **The four element marks:** Fire a flame of three straight tongues, Frost three crossed bars, Storm a cloud with one bolt, Void a dark shard with a white crack through it.
- **The coin, the bolt, the critical's spark.**

**The director's word on the palettes** (2026-11-12, to Modulo, answering "I chose nothing about which screens are Pearl or get their own palette"): "You will and should i give you creativity for it, some ui have their own palette if u think it would look better it just need to be all compose". It covers which screens are Pearl and which get a palette of their own: that's Modulo's to choose, and the whole has to hold together.

**The choice, under that word** (`kit_palettes.png`, the same corner of a screen built from the slices in each):

| Palette | Its screens | Why |
|---|---|---|
| Graphite Dark | the HUD and its cards, the dock, Voidkin, one Voidkin, Regalia, confirm, error, toast, reward | the field and the collection: rarity's light reads best on it |
| Dynamo | the Breaker, the base's bays; later the Forge, the Condenser, the Lab | the machine room: warm iron, and a button's light is the charge the bays make |
| Void Violet | the reveal's card; later the Void Shop | where a shard opens: the darkest room, so the rarity's own light is the brightest thing in it |
| Pearl Light | the map, a shard's odds, where a stat's points come from | what's read like a printed page |

What a palette may change: a panel's body, its edge and glint, the ink, and the accent a button and a selection burn with. What it never changes: the cut, the frames, the gems and marks, health's ivory light, green and red, the numbers. That's what holds the four together. A later screen takes one of these four unless its own piece argues for a fifth.

**Calls, mine (tier 1):**

- A class mark always sits in its dark seat, on every palette, like a gem in a frame: a frame is the same object everywhere.
- The small cut halves its corners with everything else. At their full size on a 40 point frame they ate the crest.
- Mythical's first crest point moved from 0.2 to 0.24 of the width: it overlapped the corner's cut and left a barb.
- On a pale panel, Legendary's and Mythical's seat carries a deeper light close to the frame (research's condition on Pearl's Mythical).

**Against the earlier checks' conditions:** 1, no image carries text. 2, the Strength gem is a six-sided cut stone with a table, facet lines and a dark rim (`kit_icons.png`, alone at 64 px over dark). 3, the Warrior's mark is a leaf blade with a guard, on the slant: no cross at 16 px. 7 and 12, every image has its review at full size and at 64 px over dark. 8, Mythical's red is a line and a halo. 9, its splinters are white-hot, straight-edged, and absent from the small cut. 10, the crest's and the base's points are the sheet's own, straight-edged and sharp, none lengthened; only the first one's place changed. 11, the small cut is shown alone. Research's Pearl condition: at 64 px on the pale chip Mythical reads red; only the last of its fade goes through pink.

**What I see wrong:**

1. The Assassin's fang is the weakest of the five marks: at 16 px it's a curved wedge, and it could be taken for a horn.
2. On Pearl, a selected button is a double dark line with a pale thread in it. It reads as "marked", less as "lit".
3. At 16 px the gems are told by colour first; their cuts start to read at 32.
4. Void Violet under a Mythical frame is the loudest corner of the four. That's the reveal, so it may be right; on a shop screen full of frames it would want a calmer body.
5. The full frame is drawn for 80 points. A reveal that shows one far larger wants its own cut, with that piece.

**For the builder:**

- The layer order of a panel, a button, a bar and a frame is `ui_kit.py`'s `panel`, `button`, `bar` and `frame`: the palettes sheet is built by them, from the shipped images alone.
- An image with `pad` reaches that many points past its piece's box on every side: place it at minus `pad`, sized plus twice `pad`.
- A waiting button is the ring with a window run round it (a gradient's transparency, turning), and the three dots.
- A portrait can't be clipped to a cut corner in the engine: each Voidkin's portrait is cut to its frame's mask here, before upload. A live viewport in a frame needs another answer, to settle with that screen.
- The palettes' rows in `kit.json` are for `src/shared/Config/`, which is theirs.

**Waits, outside this piece:** the damage numbers' digits (Roblox's faces with a stroke, or a drawn sheet with its own check), a larger frame for the reveal, each Voidkin's cut portrait.

**Content check, 2026-11-12: PASS** on rules 2, 3 and 4, for handing the kit's images to the builder. It read the ten review sheets, twenty of the shipped images and the script. Nothing reads as blood, a wound or a drop at any size, on dark or on pale, and no mark matches a hate symbol, a real logo or another work's mark. Conditions 1 to 5 and 8 to 12 are met. On 10 it measured one exception: the crest's second point is 14 wide by 20 tall, the same crown as on the passed sheet; it stays, and must not get taller, and no base point may get taller than its width. Its limits: the stretching slices were seen at full size only, and the bare white glyphs on the icons sheet only. After the check, the chip beside the Assassin's fang was dropped (the check's own suggestion, against an arc-and-dot look at 16 px); nothing else changed.

Before upload: the kit's row in `docs/asset-log.md` and the script in git, both done with this delivery. Only `images/` is uploaded, never the sheets or the masks.

For the builder, in use:

1. Never two `Bolt` icons side by side as a pair.
2. Red on a button's ring and its glow only with words, never on a bar or across a portrait.
3. Any motion on a frame, and each cut portrait, gets its own check.
4. A palette's accent lights buttons and selections, never a ring round a portrait's frame: Dynamo's yellow there would be taken for Legendary's gold (research's fix 5). How a selected portrait is marked is settled with its screen.

**Hours:** the kit's images, about 1.6.

**Research's verdict, 2026-11-12.** **Felt:** four rooms of one game: the cut, the frames and the gems carry across every palette, each palette gives its screen a mood without dimming rarity's light, and at phone size Graphite's card is the cleanest, Void Violet's the most exciting. **Tier:** competent; the frames reach exceptional. **The one bold thing:** the frames: Mythical's red crown and Legendary's gold read at 64 px on all four, and on the pale chip Mythical reads red (research's Pearl condition: met). The palettes and their screens are accepted (`docs/ui.md`, rule 3, now in line). Fixes:

1. Pearl's panels carry the black border the director named: their edge is a thin grey line now; the buttons have it, the panels don't. Serves the director's word.
2. Pearl's selected button fills its body with ink, the label pale, instead of the double line, so it reads lit, not marked. Serves the state.
3. The Assassin's fang is replaced (your point 1, agreed). The test: at 16 px it's not a crescent, not a blade (the Warrior's), not a horn. One way: a pointed hood with an eye slit. Serves telling five classes apart.
4. Intelligence's gem and Void's mark are both violet, side by side on Sliptail's card: take Void's mark darker, its crack white, so they part at 16 px. Serves the card's row.
5. Dynamo's charge-yellow stays on buttons and selections, never as a ring round a portrait frame, so it's never taken for Legendary's gold on the Breaker. Serves rarity's read.

Accepted as they are: the gems read by colour first at 16 px (the cut follows at 32); Void Violet's calmer body for the shop and the reveal's larger frame wait for their pieces. For later: every weapon icon will carry its class mark on its frame (`docs/design.md`, "Regalia: gear"), so the marks also work at an icon's corner. Fixes 1 to 5 are one round; the kit goes to the builder once they're in.

**The fix round (Modulo, 2026-11-12).** The five are in and `build/handoff/UI/kit/` is regenerated: `PanelEdgeBold`, `ClassAssassin`, `ClassAssassinGlyph`, `ElementVoid`, `kit.json` and four of the sheets changed. Still 89 images, none uploaded or in the engine.

1. **Pearl's panels.** The black border was there, 1.6 points at the very edge, and a dark world swallowed it: only the pale body's end was left to see. `PanelEdgeBold` is now a rule 2 points wide set 1.5 in from the edge, so a lip of the pale body stands outside it and it reads on any ground. A pill wears it too. A button keeps its border at the edge, since it sits on the pale panel.
2. **Pearl's selected button** fills with ink, its label pale, the ring's ivory thread inside it. No new image: Pearl's row in `kit.json` carries `selected` (the fill's two colours) and `selectedText`, and `button` in the script shows the order.
3. **The Assassin's mark** is a cowl with a leaning peak and one narrowed slit for the eyes. Eight cuts were tried at 16 px beside the other four marks. A slit that sits low or dips in the middle reads as a smile at that size, so it sits high and narrows to the bridge of the nose; the peak leans so it's cloth, not a helm.
4. **Void's mark** is a dark shard with a violet rim and a white crack: a fracture on the slant, five uneven runs and one short spur. Beside Intelligence's gem at 16 px it parts by its dark body, its shape and the white.
5. **Dynamo's yellow.** No image changes. The rule is in `kit.json`'s note, on `ButtonRing`'s use, and in "in use" above, 4.

**Content check, 2026-11-12: PASS** on the round, rules 2, 3 and 4, on the regenerated files. Void's mark passed at its second look: the first draft's crack was three upright strokes, which in white on a dark shard read as a rune at 32 px and under, and it was redrawn. To hold, each needing a new check if it changes: the cowl's peak stays short and leaning and its eyes stay one band, never two holes; Void's crack keeps one spur, one-sided and ending inside the shard, its runs uneven and on the slant, never upright and never crossed.

**What I see wrong:** at 14 px the cowl is a capped head with a dark band: it's told from the Tank's shield by pointing up, and from the heart by the band, no more. Void's crack carries a violet halo, so on a dark panel the mark still reads violet first.

**Hours:** the round, about 0.6.


### 3. The HUD's own art: portraits and the critical's stroke (research's ask, 2026-11-12)

For TR3, after Lantern Row's round 2 (AR5, section 1).

- **Each launch Voidkin's cut portrait** for the lead's card: Rook, Pip and Lyric now, cut to the frame's mask before upload (section 2's note). The head and shoulders, three-quarter, eyes to the player, and readable at the card's size on a phone. Plus one silhouette for a Voidkin that isn't made yet. Each portrait gets its own check.
- **The critical number's swept stroke:** one picture of our own behind a gold, heavy, forward-slanted number (`docs/ui.md`, "Damage numbers"). It must read as speed, not a slash or a wound: rule 4's check.
- **Checks:** the content check; legible at phone size over Lantern Row's dark and bright corners; research's verdict.

**Delivered (Modulo, 2026-11-12):** `build/handoff/UI/hud/`: `images/` (19), `hud_art.json` in the kit's form, and the sheet, `hud_art_sheet.png`. Made by `tools/blender/hud_art.py` (`make`, `sheet`). Nothing is uploaded or in the engine.

- **The portraits.** Each is the Voidkin's own model, the body about a third of a turn off and the head turned back to the player, lit by the model's sun with a soft fill from the camera. Two cuts each, on the frame's own canvas: `Portrait<Name>` for the full frame (80 by 96 points) and `Portrait<Name>Small` for the lead's card (40 by 48), cut to their rarity's mask from `Definitions.Voidkin` (Rook and Pip Common, Lyric Rare).
  - **Rook** sizes you up: the gauntlet's shoulder forward, chin down, a level look from under the brow.
  - **Pip** looks up from under a hat too big for him, head cocked.
  - **Lyric** is between songs: chin a touch up, the headset and its mic to the camera. Her stand is hidden: at this crop it was a bar across her face.
- **The silhouette.** A head, a neck and a pair of shoulders in flat violet, lit along the upper edges, faceless. One picture cut to all six rarities in both cuts (`PortraitUnknown<Rarity>[Small]`), since a mask is the frame's. It's drawn, not shot: a bare R6 body at a portrait's crop was a slab with a stub, and at the card's size it read as an empty frame (my first two tries, and the content check's note on the second).
- **The critical's sweep,** `CritSweep`: five level streaks leaning with the number's slant, one wide with dry gaps and four hairlines, thin tails behind and square heads forward. A grey slice, 112 by 56 points, tinted by the game. On the sheet it's amber `#E8862A` under the gold number, so the number stays the brightest thing.
- **Read at phone size:** the sheet shows the four in the lead's card's frame at 2 pixels a point and at 1, over the merge's dark side and its bright end (round 2's own frames), and the sweep under a critical over both. All four portraits read at 1; the sweep reads as lines of speed at 2 and as an amber bar with a streak either side at 1.

**For the builder:**

1. A portrait is laid Back, portrait, frame, at the frame's own place and size: same canvas, same pad, nothing to align.
2. A Voidkin without a portrait takes `PortraitUnknown<its rarity>`.
3. `CritSweep` sits behind a critical number and under its stroke, centred on it: its height twice the number's size, its width the number's width and a half. It stretches along, never up. The tint and the slant are in `hud_art.json`.
4. Only `images/` is uploaded.

**Content check, 2026-11-12: PASS** on rules 2, 3 and 4, each of the five on its own line. It read the sheet, all 19 images, the uncut renders and the script, and compared the sweep with the reference's stroke: ours is five ruled streaks from numbers, the reference's one brush blob with a curled tail. Its limits: 64 px over dark only; likeness from memory. To hold, each change coming back to the check:

1. The sweep's tint is amber `#E8862A` or yellower: never red, crimson, magenta, plum or black, and never under the received number.
2. The sweep stays level behind a number: never turned to a diagonal, crossed, doubled, stretched upward, or left on a body, a portrait or the ground.
3. The sweep stays straight parallel streaks with square heads: no curve, no taper at both ends, no flecks beside it, no gloss.
4. Rook's collar rim under the chin stays the jacket's flat colour, even and joined on both sides; the plaster stays clean and pale.
5. Lyric's rose stays flat, bright and matte, ending level at the collar, never a free strand on the skin; the mic's tip stays clear of the mouth.
6. Pip's face stays lit skin under the brim at the card's size on the real street, at night too.
7. A fallen or low portrait is dimmed and edge-lit only: no red wash, streak or crack across a face.
8. The silhouette stays faceless and plain: a mark, a glow or a question mark gets its own check.
9. Each new Voidkin's portrait, each evolution's, and any new angle or crop gets its own check.

The silhouette was redrawn after that check, and went back alone: **PASS**, 2026-11-12, all twelve cuts. Its nearest wrong reads, a stoppered bottle or a rubber stamp in the small Mythical cut seen bare, are harmless and gone in the frame. It adds to 8: no knob, hair, costume line or new proportion without a check, and the fill stays the kit's violet with its pale rim, never red or flesh-toned, never tinted by a fallen state. The handoff's files are this make's, byte for byte.

**Research's verdict, 2026-11-12** (the sheet).
- **Felt:** three people looking back at you from the corner, each in one glance: Rook sizing you up, Pip unsure under his hat, Lyric between songs. Even at the card's small size over the street's dark side and its bright end, you know who leads.
- **Tier:** competent. **The one bold thing:** the eyes to the player. A HUD card that looks at you is a companion, not a stat block.
- **The sweep:** accepted. At 2 pixels a point it's speed, at 1 an amber bar that still lifts the gold, and the number stays the brightest thing.
- **The silhouette:** accepted. A faceless violet bust says "not yet yours", not "missing".
- **No fixes.** One note: the faces carry the shared face style the director plans to rework (`docs/polish-later.md`). The portraits are rendered from the models by `hud_art.py`, so that rework re-cuts them for a run's cost.
- **Accepted, on to the builder for TR3.** Faber uploads `images/` under the group with the key.

**What I see wrong:**

- The portraits wear the models' one face each (`docs/polish-later.md` has a face of its own for each Voidkin): the pose and the head's turn carry the character here, not the expression.
- Rook's gauntlet is a grey block at the frame's corner: it says "shoulder", not "gauntlet", at this crop.
- Lyric is the busiest at 1 pixel a point: the hair, the rose, the headset and the mic share about 20 pixels.
- The silhouette is the familiar head-and-shoulders mark, nothing of the Void in it. It does its job and no more.
- The sweep's wide streak is a slab at 1 pixel a point. Whether it should thin there is seen with the real font, its stroke and motion, in TR3.
- Nothing was seen in the engine, on a phone, or moving. The street behind the cards is my render of the merge, not Roblox's.

**Not done:** research's verdict; the upload (the builder's, with TR3); seen in the game. No test request of its own: TR3 is where these are tested. **Hours:** about 1.5, an estimate.

## AR4. Pip and Lyric

For Modulo, after AR1 closes. The ranged family and the first element (Pip); a heal and a complex signature (Lyric). Same four deliveries, timed. With AR1 they give the cost of a simple, a middling and a complex Voidkin, and with Rook's evolution they're the package's gate C: three finished exemplars and one evolved.

**Status:** started (Modulo, 2026-11-12), while AR1's delivery 4 waits on the builder and AR3 on its verdicts. Pip's sheet is past the content check and research's two reads (section 1) and delivered to `build/handoff/Pip/pip_sheet.png`. His model is past research's read and the content check (section 2) and delivered beside it, not yet in the engine. His eight clips are accepted by research after its one fix round, past the content check on both rounds (section 3), and **delivered** to `build/handoff/Pip/clips/`, not yet in the engine. Lyric's sheet is delivered to `build/handoff/Lyric/lyric_sheet.png`, past the content check and research's read, the feel line signed, the signature Held Note (section 4). Her model is read by research (competent, its three fixes landed), its two fixes for the next bake are made and past the content check, and it's **delivered** beside the sheet (section 5), made on Opus 5.5 xhigh: the fixes not yet read, the model not in the engine. Her five clips are **delivered** to `build/handoff/Lyric/clips/`, accepted by research, and the look at her props in the robe set's fall is made (section 6). Delivery 4 for Pip, Lantern Burst's look: the block-in is drawn on his clip in three variants, and research signed the feel line and picked B (section 7). Its art sheet is delivered to `build/handoff/Pip/fx/`, past the content check, and research read it competent, on to the builder (section 8). Lyric's Held Note: the block-in is drawn on her clip in three variants, past the content check, for research's verdict; my pick is A, the crests (section 9).

### 1. Pip's sheet (Modulo, 2026-11-12)

`build/scratch/modulo/pip/sheet/pip_sheet.png`, 1920 by 1200, drawn by `tools/blender/pip_sheet.py`. Rook's layout: the outline, front and back on the R6 body, how he stands, the player's camera; Lantern Burst's key pose from the target's side, as an outline and from the player's camera; all of it at 64 px over dark, bright and in black; the values.

**Feel line, signed as written** (Quaestor, 2026-11-12): an apprentice half the size of his own hat, whose one spell is bigger than he is: when the lantern goes, it's him that gets thrown back.

**The look:**

- **One idea:** a hat with a boy under it, and the one spell he has, kept in a lantern. The hat's tip has fallen to his left and the lantern floats at his right, so the two balance in the outline.
- **The hat:** a brim 3.4 studs wide that sags, a chalk band, a crown that slumps and a tip weighted by a brass bead and a tassel. 6.9 studs to its top. It hangs from the head on its own joint, so a clip can lift and lag it.
- **The robe** was cut for someone taller: a bell to below the knees with an uneven hem, sleeves that hang half a stud past his hands and open like bells, a collar that stands to his chin. Chalk at the hem, the cuffs and the collar.
- **The back,** what the player's camera sees: a book as big as his back, in leather with brass corners and one plain brass disc.
- **The lantern:** a brass cage round a flame, a peaked lid, two paper slips under it that trail. Its own piece, held by nothing. Hot, the flame fills the cage.
- **The face:** R6's round head, a straight fringe, large eyes with one catchlight each, short brows raised in the middle, a small open mouth. It shows under the brim from the front; from behind he's all hat.
- **Colours:** Inkwell `#46348A` (Intelligence's family, deep), Chalk `#EFE8D8`, Flame `#FF8A3D` (the Fire colour of AR3's sheet). Brass, leather, chestnut, skin.

**The key pose, the send:** he points with his whole sleeve and the lantern goes, hot, its slips streaming. The spell kicks: he's thrown back on his heels, the hat lifts, and the other hand holds it on.

**For the model and the builder:** two pieces beyond R6's six, the hat and the lantern, each wanting its own joint, as Rook's piston did. Blockout 5,396 triangles.

**What I see wrong:**

1. From the player's camera the send has both arms up and out, a V: the pointing arm doesn't read as pointing from behind. The lantern leaving and its light have to carry it there, which is the effect's work.
2. Over the dark ground at 64 px the robe and hat hold only by the chalk bands, the book and the lantern. I lightened Inkwell once for it.
3. The robe's bell is rigid on R6: the legs swing inside it, and a long stride will show a boot through the hem. To settle on the model, as the Shade's coat was.
4. He's the plain reading of an apprentice mage. What's his own is the pairing (the fallen tip and the floating lantern), the book on his back, and the recoil.

**Content check, 2026-11-12: PASS** on rules 2, 3 and 4, at full size and in the 64 px block; the sheet only. For research: the check found no "Fighters" section in `docs/decisions.md`, which `AGENTS.md` rule 3 points to, and it left two notes for the name's look-again in `docs/ip-list.md`. To hold on the model, the clips and the effect:

1. The face stays lit human skin under the brim from the front, in the game's light and at 64 px over dark: never a dark void, the eyes never lit or yellow.
2. The hat stays in the robe's colour in any variant or evolution: never straw, tan or yellow over a blue coat, and no stars, moons or belt on it.
3. No staff, wand, big gloves or gauntlet. The lantern stays a brass lantern that floats and is sent: never a flask, potion or bomb from a launcher, never a creature with a face, wings, limbs or a name.
4. The book's cover stays plain; a mark added later gets a check against symbols and logos.
5. The slips stay flat, straight-edged paper, never tapering to drops. The burst and its hit are light, sparks and dust: no burn marks, charring, stains or pools, nothing in the flame's colour that drips or sprays.
6. The clips are stepped through on a bare rig from the side and three-quarter: the pointing arm is never held nearly still at 20 to 70 degrees up with the body upright; it stays level or moving, with the lean back. The send is read from the player's camera at 64 px on every heading.
7. The model and each upload batch get their own check.

- **Research's read** (Quaestor, 2026-11-12, on pip_sheet.png at full size and the 64 px rows): a re-render of the sheet with fixes 1 to 3, then the model.
  - **Felt:** a purple wizard with a floating lantern, clear at a glance. But the feel line's first half isn't on the sheet: the hat is a wizard's hat of the usual size, not one he's half the size of. And from behind, the send reads as a cheer.
  - **Tier:** works. He's one of three starters, the first choice a player makes, so he aims at exceptional.
  - **The one bold thing:** from the player's camera, a book as big as his back with a lit lantern bobbing beside it. Nobody else in the roster reads like that from behind.
  - **Fixes:**
    1. **The hat really is too big.** The brim comes down to sit on the collar and nearly over his eyes, the crown is taller, and the tip falls further, so the hat is half his outline. The eyes stay visible and lit under the brim (the content check's condition 1). Keep the triangle count at what the joint can lag (serves: the feel line, and "a hat with a boy under it" as the whole read).
    2. **The send, from behind:** the pointing sleeve goes level and straight down the lantern's line, never up. The recoil reads through the lean back, the hat lifting and the other hand clamping it, not through two raised arms (serves: the send read from the player's camera; also the content check's condition 6).
    3. **Chalk on the brim's edge.** Inkwell is violet, and Lantern Row's dusk is violet too. Run the chalk band round the brim so the hat's outline, his one idea, holds on the real street. Show it at 64 px over a dusk-violet ground beside the dark and bright rows (serves: the read on the ground where players meet him).
  - **Accepted:**
    - Inkwell, Chalk and Flame (#FF8A3D, the Fire colour);
    - the lantern held by nothing, on its own joint;
    - the slips;
    - the robe cut for someone taller;
    - the face under the brim;
    - the robe's rigid bell, settled on the model as the Shade's coat was;
    - the plain apprentice reading, since what's his own is the pairing, the book and the recoil, and fixes 1 and 2 push those.
  - **The name's look-again:** closes on the content check's two facts, in this entry.
  - The missing "Fighters" section in docs/decisions.md is already open with the director, along with north-star's "The look". Meanwhile the directive's section 3 and north-star's "The bar" stand in for it.

**Round 2, fixes 1 to 3 drawn** (Modulo, 2026-11-12; the sheet is now 1920 by 1290, with a row at 64 px over Lantern Row's dusk violet):

1. The hat is half his outline: 7.4 studs to its top over a 5 stud body, the brim 3.8 wide. The brim hangs to his collar behind and at the sides and is pushed up at the front, so the eyes show under it; the crown is 2.3 studs tall and slumps left; the tip falls to the level of his brow. One joint, as before. Blockout 5,696 triangles for the whole figure.
2. The send: one sleeve goes level down the lantern's line, and the lantern is low and ahead of it. The other hand has the brim by its front and clamps it; from the player's camera that arm is behind the hat, so one arm reads. The recoil is the lean back (15 degrees) and the hat lifted 21 degrees off his head.
3. Chalk runs round the brim's edge. Over the dusk violet at 64 px the hat's outline is that chalk ring and the band.

Also: a hand shows inside each sleeve's end. The lantern floats a little lower and further out, clear of the wider brim.

**What I see wrong now:** the brim's sides hang at shoulder height, so an arm raised sideways goes through it: the clips keep his arms forward or low, or the hat tips with them. In the send's three-quarter view the clamping sleeve covers half his face.

- **Research's read, round 2** (Quaestor, 2026-11-12, on pip_sheet.png at 1920x1290): yes, on to the model.
  - **Felt:** a hat with a boy under it, now literally. The brim sits on his collar like a lampshade, his eyes peek out under it, and the lantern balances the fallen tip. From behind, the send is one level sleeve down the lantern's line, the other hand clamping the brim. It reads as a throw that kicks.
  - **Tier:** competent, and the starter's read is there. Whether he reaches exceptional is decided in motion, by the recoil and the hat's lag.
  - **The one bold thing:** the hat as half of him. Every other read (the face, the book, the lantern) sits under it or beside it.
  - **For the model and the clips:** the hat's lag on the send is where he becomes his own. Give the hat's joint the most care.
  - **The name's look-again:** passes. Pip is an ordinary word and name, not one a work invented. Of the content check's two facts (from memory, unchecked; neither changes the reading): the Paladins character shares the name but not the look, the role's dress or the move, and the content check's condition 3 keeps the lantern from ever becoming a flask. Lulu's companion is named Pix, which isn't ours, and condition 2 keeps the hat in the robe's colour.

**Hours:** the sheet with its second round, about 1.8.

### 2. Pip's model on R6 (Modulo, 2026-11-12)

- **Where:** `build/scratch/modulo/pip/model/` until the checks pass, then `build/handoff/Pip/`: `Pip_<Piece>.json` (eight pieces), `Pip_Color.png`, `Pip_Roughness.png`, `Pip_Metalness.png`, `Pip_Emissive.png`, `Pip.recipe.json`, `pip_model_sheet.png`. Made by `tools/blender/pip_model.py` (a Cycles bake under the lock): `blender -b --factory-startup --python tools/blender/pip_model.py -- <out dir>`.
- **How he sits on R6:** a rigid mesh for each of the six parts, carrying the body's own surface, so the rig's blocks are hidden and the Head's face decal goes. Two pieces on joints of their own:
  - **The hat,** on the Head, turning about the top of his head (`0, 4.95, 0`). Its rest tilt is in the mesh, so he's himself with no clip playing.
  - **The lantern,** on the Torso, at `2.75, 4.3, -0.3` beside his right shoulder. Nothing holds it: the clips move and turn it, and Lantern Burst sends it.
- **The numbers:** 8,208 triangles in the eight pieces (the torso 3,112 with its folds, the hat 1,392, the lantern 604). 7.37 studs to the hat's top, 4.75 wide without the lantern. One 1024 px atlas, 58 px per stud. Maps: colour with the contact shading baked in, roughness, metalness (the brass, at 0.5), and a glow mask. No normal map.
- **The glow** is the lantern's flame and nothing else: the recipe gives the Fire colour, a strength of 1.2 as it floats and 3 through the send. The face and the eyes take none.
- **Changed from the sheet (tier 1):**
  - The hat's fallen tip is one round taper, not four blocks.
  - The robe's hem is 0.2 studs fuller front and back, so a walk's stride stays inside it up to 25 degrees each way. The recipe carries that number for the clips.
- **For the builder, in the recipe:** CastShadow off on the hat, or the brim puts his face in the dark (the content check's condition 1), and off on the lantern, which is a light. A light around the lantern is the builder's call, tuned in the engine. Three points: `Lantern` (the flame's middle), `Sleeve` (the right cuff's opening, where the send's line starts), `Chest`.
- **What I see wrong:**
  - From the player's camera the sent lantern flies base first, so its hot flame is hidden. The clip has to tumble it, or the effect's light carries the send.
  - The robe is one large violet field, shaded by contact only. No folds are drawn.
  - About half the faces, the bevels and the small parts, sit on the atlas's swatches and take one flat colour each. The player's camera never gets close enough to tell.
  - The hair's side tufts can read as ears from the front.
  - At 64 px over Lantern Row's dusk, lit as dusk, the robe is close to the ground's own violet. The chalk ring, the hem, the book and the lantern hold him.
- **Research's read** (Quaestor, 2026-11-12, on pip_model_sheet.png, stills; the clips judge it in motion): yes, on to the clips, carrying fixes 1 and 2.
  - **Felt:** the sheet's Pip, built. A lampshade of a hat on a small boy, a lit lantern at his shoulder. The face under the brim holds by day and at dusk, and that was the risk. From his right side he's a thin column under an enormous brim, which is the feel line's "half the size of his own hat" in one view.
  - **Tier:** competent.
  - **The one bold thing:** the brim's chalk ring from the player's camera. A white ellipse bigger than his shoulders, and you'd know him by it alone across the festival.
  - **Fixes:**
    1. **The robe tells its story.** Draw a few long folds from the shoulders that bunch and pool at the hem over the boots, where a robe cut for someone taller would. Keep it in value, not new colour, lighter on the tops of the folds (serves: "cut for someone taller", which is half his character, and breaking the one flat field that sits close to the dusk ground's violet).
    2. **The side tufts read as floppy ears** in the face crops. Tuck them under the brim, or join them to the fringe in one shape, so they read as hair (serves: the face, the one part of him players meet at the reveal).
  - **Your two questions:**
    - The lantern: tumble it, yes. A lantern that turns end over end shows its flame every half turn, and an apprentice who can't throw it straight is his character, not a fault. Its glow at 3 through the send carries the rest.
    - The flat robe: fix 1.
  - **Accepted:**
    - the tip as one taper;
    - the fuller hem, with 25 degrees in the recipe;
    - CastShadow off on the hat and the lantern;
    - the three points;
    - the swatch faces, which no camera reaches;
    - the dusk read held by the chalk, the hem, the book and the lantern;
    - the glow on the flame alone.
- **Fixes 1 and 2, made (Modulo, 2026-11-12),** on the model and its sheet; research reads them in the clips' packs:
  1. Nine long folds run down the robe from the shoulders and the chest, in its shape (up to 0.12 studs at the hem) and drawn into the colour map in value alone: lighter along each fold's top, darker beside it. Above the hem the cloth is stacked: a crease that wanders round him and a roll over it. Each sleeve has three drawn folds. The hem's height is unchanged, since a lower hem would let the boots through at a stride.
  2. The side tufts are gone. The hair's edge drops in a lock down each cheek, one shape with the fringe.
- **Content check, 2026-11-12: BLOCK on the maps, narrowly; the model, the recipe and rules 2 and 3 passed.**
  - The flame's five islands on the colour map were pointed drops in the Fire colour, the only warm drop shapes on it (rule 4 at its mildest reading; the handbook's trap on drop shapes).
  - Fixed: the flame's faces sit on their swatch, one straight-edged block on the colour map and on the glow mask. `rook_model.py`'s bake takes `lit_swatches` for it.
  - **Second look, the same day: PASS** on the rebaked `Pip_Color.png`, `Pip_Emissive.png` and the sheet, on rules 2, 3 and 4. The only Flame orange on the colour map is its swatch, and the glow mask is one white block over it. The folds are violet on violet in value alone, and the cheek locks read as hair. One new condition: the folds stay in the robe's own violet, and a pass that takes them darker or toward plum or red gets the map another look. The check didn't re-read the recipe or the meshes that round.
  - **Delivered** to `build/handoff/Pip/` after it: the eight meshes, the four maps, the recipe and the sheet, all from the one run.
  - The sheet's seven conditions hold on the model; the sixth is the clips'.
  - **Its conditions from here:**
    - Before upload, Pip's rows in `docs/asset-log.md`, and the batch gets its own check.
    - In the engine: CastShadow off on the hat; the face read again under the brim from the player's camera in Lantern Row's dusk at 64 px; the eyes never lit, whatever light is put round the lantern.
    - The clips: condition 6 on a bare rig from the side and the three-quarter; the lantern's tumble never brings it onto or into his head or torso.
    - The effect: condition 5; the hot flame under the game's bloom read from every heading at 64 px, so the glow beside his head reads as a lantern and not as something coming off him; the tint stays `#FF8A3D`, never redder.

**The flame's tint in the recipe is white (Modulo, 2026-11-12).** Roblox multiplies the glow by the colour map (AR2, section 4), and the colour map under the flame is already `#FF8A3D`: tinted orange as well, the flame would have come out red, against the condition above. `Pip.recipe.json` now gives `tint` `#FFFFFF`, so the flame is drawn in `#FF8A3D`; the maps and the strengths are unchanged, and the sheet already showed that colour. Not seen in the engine.

**Hours:** the model, about 1.1, the two fixes and the content check's included.

### 3. Pip's clips: the poses (Modulo, 2026-11-12)

**Delivered** to `build/handoff/Pip/clips/` (2026-11-12): the eight `Pip_<Clip>.json`, `Pip.clips.json`, and each clip's pack with its notes. The audit passes on all eight; research's read, its fix round and both content checks are at the section's end. Not uploaded, and not seen in the engine.

- **Where the working set is:** `build/scratch/modulo/pip/clips/`. For each of the eight clips: `Pip_<Clip>.json`; `pack_<Clip>.png` (the named poses from the clip's camera, the bare rig from the side, a strip of twelve) with `pack_<Clip>.txt` (its numbers and the audit's lines); `poses_<Clip>.png` (each named pose from three sides); `arcs_<Clip>.png`; `bare_<Clip>.png` (the bare rig stepped through the clip, from the side and the three-quarter). Then `headings_LanternBurst.png` (the wind-up, the send and the recoil at 64 px on eight headings, over a bright ground and over dusk) and `Pip.clips.json` (frames, markers, the flight). Made by `tools/blender/pip_clips.py` on the kit Rook's clips use: `blender -b --factory-startup --python tools/blender/pip_clips.py -- <out dir> [poses|export|audit] [clip ...]`.
- **Export one clip a run.** All eight in one export ran the machine out of memory. `audit` with no clip named runs all eight without rendering, and writes `Pip.clips.json`.
- **How he moves, in one line:** a kid in a coat that's too big, a beat behind his own sleeves, and the hat says what he feels. His hands never go to it. The lantern is the one that's good at this.
- **The eight,** at 60 frames a second, each with its markers:
  - **Idle** (a loop of 192): rocking a hair on his heels. At 120 he turns to check the lantern's still there, and it perks up and turns to him.
  - **Combo** (100; `Shot1` at 10, `Shot2` at 26, `Shot3` at 62): two flicks off the end of his sleeve, the lantern spitting and kicked back over a stud each time, askew. For the third he sets his feet and ducks under his brim (44 to 57), then jabs the whole sleeve: the lantern kicks clean over (a full turn, 62 to 93) and the hat jumps.
  - **LanternBurst** (132; `Heat` at 8, `Send` at 51, `Burst` at 66, `Return` at 98): he reels the lantern round to his sleeve's end, winds up with the sleeve behind him (30 to 45), and lets go with it level down the lantern's line. The lantern goes end over end, two turns, 12 studs out. The kick throws him: he rocks back over his heels all of a piece, toes up, the free sleeve wheeling out behind him and the hat off his head (57), and it has him off the floor (62). He comes down half a stud behind where he stood, and the hat comes down on him, too far (68). He has to tip his chin up to see whether it worked (86), then nod it back (106). The lantern comes home the long way.
  - **Hit** (20): struck (3), he folds round it, both sleeves thrown forward; the hat follows by its own lag, and the lantern shies.
  - **Down** (66; `Land` at 29): the blow takes him in the chest (6) and he goes over backwards like a plank in a robe, the sleeves reaching forward for something to hold. He falls out from under his hat: it hangs over him (29) and comes down over his face (39). His boots bounce once (34). The lantern comes down to look.
  - **Up** (58): the hat gets up first (10). He stands himself up the way you'd walk a ladder upright (22 to 36), goes a little too far (44), and the lantern's back at his shoulder before he looks for it.
  - **Reveal** (96; `Kindle` at 24, `Flourish` at 58): a hat on a bundle of robe. The lantern comes round from behind him and lights, the brim tips up, and there's a boy under it (41). He tries a flourish: the lantern loops the loop, and its wind has the hat right off his head (67). He ducks (70), it lands back on him, and he looks up from under it for his name.
  - **Work** (a loop of 120; `Pump` at 27): right shoulder to the post, a sleeve held over it like warming a hand at a stove. The lantern rears, ducks in and gives it a go. While it gets its breath he drops his chin and nods his hat back up (70 to 76), and looks up to read the dial over his head (83 to 92).
- **The hat and the lantern** are keyed on their own joints, every frame. The hat lags the head by a spring (at its widest here 18 degrees back, 14 round, 5 to a side), and the clip takes it over where it acts: the send, the fall, the reveal. The lantern is placed in the stage's space, so it stays put while he moves.
- **What changed since the pose sheets, and why:**
  1. **The left arm was keyed backwards.** On this rig a left arm's roll is positive toward the body, and every standing pose had it positive: the first export failed all eight clips with the left arm 0.26 to 0.36 studs inside the torso. Every left-arm roll is now zero or outward, and the rule is written over the clips in the script.
  2. **No hand goes to the hat.** With the arm out of the chest, a hand at the brim is a straight arm raised beside an upright body: the audit's salute check read it held for 0.22 s in LanternBurst and 0.15 s in the Reveal, over its 0.1 s line, and it's the content check's condition 6. The lifted hat is also out of an R6 arm's reach. So the hat is moved by the kick, the lantern's wind and his own nod, and never by a hand. This drops the sheet's "other hand clamping the brim" from the send: for research, below.
  3. **Work stands side-on.** His right shoulder is to the post, so the sleeve reaches it without crossing his chest.
  4. **Down falls backwards, and Up starts there.** Falling forward he lay feet toward the player's camera: it looked up the robe and into the cuffs. Now his head comes down toward the camera with the hat over his face and the sleeves out at his sides. The hat lies on its brim, 0.03 studs over the floor, turned about the middle of his head.
  5. **The Reveal starts lower** (crouched low inside the robe, the hat tipped 27 degrees over him), and at the flourish the hat leaves his head by 0.3 studs and he ducks under it.
  6. **Two measures added** to each clip's numbers: a hand's nearest to the hat, and the brim's rim at its lowest over the floor.
  7. **Each pack is taken from the camera its clip is seen from:** the player's for the fight; the front for the Reveal and for Work; for Down and Up the player's heading from 14 studs, because laid out he's five studs long before the hat.
- **The checks, as numbers, from the last run of all eight:**
  - The audit: PASS on every clip. At their worst: an arm 0.039 studs into the body (Work; the line is 0.05), the legs crossed by 0.080 (Combo; 0.10), a pop of 1.65x (LanternBurst's head; 3.0), a nod of 28 degrees (the Reveal's start; 30), nothing under the floor, and both loops' seams at 0.
  - A raised straight arm beside an upright body: held 0.00 s in seven clips. In Down the left arm passes through 21 degrees up for 0.05 s as he's struck (the line is 0.1 s), on its way forward. Two more lines are excused by the body's tilt, past 30 degrees: Down's right arm, 30 up for 0.067 s (16 to 19), and Up's left arm, 26 up for 0.15 s (17 to 25), while he's levered up off the floor.
  - A leg's widest swing in the robe, of the recipe's 25 degrees: Idle 6, Combo 14, LanternBurst 12, Hit 11, Down 18, Up 12, Reveal 22, Work 14.
  - The lantern's nearest to his torso: 0.38 studs (Work, 27). To his head: 1.16 (Work). To the hat: 0.20 (Work, 51). Over the floor: 0.23 (the Reveal's start, behind him).
  - A hand's nearest to the hat: 0.22 studs (Work, 20, the sleeve over the post under the brim). Next nearest 0.44 (Down, 22).
  - His eyes, the face's pitch: Idle +4 to +7; Combo -3 to +5; LanternBurst +3 to +37, thrown back; Hit -3 to +13; Down to +78, on his back; Reveal -46 under the hat to +19; Work -29 at the post to +24 at the dial.
- **The clip pass, ticked one by one:**
  - [x] Key poses from the clip's camera: read on all eight packs. The exception is in "What I see wrong", first line.
  - [x] The eyes are measured (above).
  - [x] The audit passes on every export.
  - [x] Feet are planted by the kit except where a clip lifts them (the fall, the boots' bounce), and both loops close with a seam of 0.
  - [x] The lantern is keyed with the body at each beat, clear of him and the floor (above).
  - [ ] Blended over the loops the way the game blends it: not done here. Combo, LanternBurst, Hit and Up end on Idle's first pose; the blend itself is the builder's to show.
  - [x] Arcs and spacing are on `arcs_<Clip>.png`, a dot a frame. The lantern's flight is one clean arc out to 12 studs and home the long way, its spacing widest at the send.
  - [ ] Judged moving at real speed: no. Blender runs headless here, so motion is read from the strips, the bare-rig steps and the arcs. The hat's lag and the lantern's tumble want eyes on them in the engine.
  - [x] Markers sit on every beat (`Pip.clips.json`).
  - [ ] The game's own dump matches the export: the builder's, when Pip goes in.
- **The send at 64 px** (`headings_LanternBurst.png`): on all eight headings, over both grounds, he holds as the hat and its chalk ring. At the send the level sleeve shows with the lantern at its end on six headings; from straight behind and the next heading round, the hat and the robe cover both (the content check's eyes, and it's right). By the recoil the flown lantern is a dot of a few pixels. At that size the effect's light has to carry the send, not the lantern's body.
- **The robe set** (research's ruling, below): `bare_Hit.png`, `bare_Down.png` and `bare_Up.png` are the body without the hat and the lantern. Struck, tipped back over the heels in one piece, flat with the arms out; then up like a ladder. They read as a hit and a fall without the props.
- **My calls (tier 1):**
  - **The robe makes his rules.** A leg stays within 25 degrees of the torso, so he tips back like a plank over his heels, crouches where another would bow, and never twists far over planted feet.
  - **His hands never go to the hat** (change 2).
  - **The beats and the flight are the clip's proposal** for the builder's Action rows: the markers above, and 12 studs to the burst (`Flight` in `Pip.clips.json`).
  - **Kindle is a marker.** The lantern is cold until `Kindle` in the Reveal; the glow is the builder's, from the recipe.
- **What I see wrong:**
  - On the send's recoil (57 to 62) the hat's crown faces the player's camera and covers him: for five frames he's a hat, a level sleeve and a wheeling one. Research keeps it: it's the clip's bold thing.
  - In Work his face shows from the front only from the nod to the dial (76 to about 95). From behind he's a hat and a book for the whole loop: nobody has drawn the bay yet, so which side a player sees isn't known.
  - Laid out, he's a hat lying on a robe. That's the idea, but the next robed Voidkin has no hat, and its Down is a flat body with its arms out and nothing more.
  - The fall carries his head three to four studs toward the player's camera. The wide camera I read it from isn't the game's: at the game's distance he may leave the frame's bottom edge.
  - The Reveal's first pose is a hat on a bundle of robe, not a hat alone.
  - Without a hand, the hat coming back down "by itself" is a cheat the eye may or may not forgive at speed.
- **For research:**
  1. **The clamping hand is gone from the send** (change 2). The sheet's approved key pose had it. The recoil is carried by the plank, the wheeling sleeve and the hat instead. If the hand has to come back, it needs a pose the salute check and condition 6 both pass, and I haven't found one on a straight arm.
  2. **The read of the eight packs,** with the model's fixes 1 and 2 (section 2) in the same look.
- **For the builder, when Pip goes in:** the content check's engine checks (sections 1 and 2); the blend over Idle; the fall from the game's own camera; the dump against the export; `Hit`, `Down` and `Up` as the `robe` reaction set, with the hat's and the lantern's tracks dropped on a body that has neither joint.

**Hours:** the clips, about 6 by my own estimate, not timed: 2 to 3 to the pose sheets, the rest on the left arm, the hat and the fall.

- **Research's ruling on Hit, Down and Up** (Quaestor, 2026-11-12, tier 2, on the section's numbers; the poses themselves are read after the export):
  - **Yes, as a second shared set, not as Pip's own.** One set per Voidkin would put three clips on each of 31; one set per body costs three clips once. Five of the 31 wear a long robe or gown (Pip, Cinder, Halcyon, Crane, Umbriel), and Rook's Down at 108 degrees comes out of every one of them. So R6 gets two sets, open legs and robe, and these three are the robe set. Recorded in `docs/design.md`, "States in a fight", "When".
  - **What that asks of the clips:** the body has to read as a fall without the hat and the lantern, because the next robed Voidkin has neither. The props keep their keys on their own joints. A body without those joints has no track for them, so nothing changes for it.
  - **For Faber, when Pip goes in:** a Voidkin's definition names its reaction set, `open` or `robe`. Rook and the Shade's rig stay as they are.
  - **Modulo:** say in your row if two sets don't hold for a body you can see coming (a long tail, a mech's custom rig is already its own).

- **Research's read of the eight** (Quaestor, 2026-11-12, on the eight packs, `headings_LanternBurst.png` and `bare_Down.png`; a blind fresh-eyes read of LanternBurst beside it): one fix round on LanternBurst, Combo and Work. The other five are accepted as they are.
  - **Felt:** he's a small boy losing an argument with his own hat. The flicks spit, the send flips the hat into a full disc and the lantern streaks off. But in the side view his body hardly leaves its feet, so the hat is thrown back and he isn't. The fresh eyes read the same thing on its own: "the hat shows the throw-back while his body doesn't."
  - **Tier:** competent. LanternBurst is a starter's signature, so it aims at exceptional and isn't there yet. The Reveal is the best of the eight: a hat on a bundle, a boy under it, and the hat blown off at the flourish.
  - **The one bold thing:** the brim swinging up into a tilted disc at 57 to 62, bigger than he is. Both reads picked it. Five frames covered by the hat is the right trade, so keep it.
  - **Fixes:**
    1. **LanternBurst: the kick throws him, not only his hat.** From 51 to 62 he rocks back well past the sheet's 15 degrees onto his heels, toes up, and skids or hops back about half a stud, still inside the robe's 25 degrees. The sheet's clamping hand showed the kick, so now the body has to (serves: the feel line's "it's him that gets thrown back").
    2. **Combo: each flick kicks the lantern back at least a stud, with a tilt,** so Shot1 and Shot2 each show a beat at 64 px (serves: the hits' impact, which half a stud doesn't carry).
    3. **Work: at the dial read, give the eyes one beat under the brim from the loop's camera.** At the post and through the nod he's all hat from the front (serves: the face, and the content check's condition 1).
  - **Your two questions:**
    1. **The hand gone from the hat:** accepted. Sleeves too long to reach his own hat is truer to him than a clamp, and a held salute isn't worth a pose. Fix 1 does the clamp's old job.
    2. **Down falls backwards, and Up starts there:** accepted. Laid out, it's a hat over a sleeve, and that's the joke. Bare, it reads as a plank fall. Whether the fall stays in frame from the game's own camera is the builder's check.
  - **The model's fixes 1 and 2:** both read in the Reveal at 41 and 96: the folds are lighter on their tops, and the cheek locks are hair. Accepted.
- **Round 1, research's three fixes made** (Modulo, 2026-11-12; the three clips exported again, their packs, pose sheets, arcs and bare sheets with them, and `headings_LanternBurst.png`):
  1. **LanternBurst: the kick throws him.** At 57 he's rocked 21 degrees back over his heels all of a piece, toes up, his chest 1.1 studs behind his feet. At 62 he's at 27 degrees and off the floor by 0.14. At 68 he lands half a stud behind where he stood, sinking a little, and the hat comes down on him as he does. He walks it back by 132. A leg's widest swing is 12 of the robe's 25 degrees, and his face tips to +37. The sleeve stays level down the lantern's line. On the bare rig from the side it's a plank going over, where before only the hat went.
  2. **Combo: each flick kicks the lantern back over a stud,** 1.15 on the first and 1.25 on the second, tilted 36 and 42 degrees and rolled to opposite sides, and home again in ten frames. It stays outside his brim: nearest to the hat 0.28 studs, at the third shot as before.
  3. **Work: the dial is over his head.** From 83 to 92 he looks up at it, his face at +24, the hat staying tipped back 12 degrees from the nod. From the front three-quarter his eyes show under the brim from 76 to about 95. Work's pack is taken from that side now. From behind there's no pose that shows a face, and the bay that would say which side a player sees isn't drawn yet.
  - The audit passes on the three again, with no raised-arm line on any of them. Not read again by research: its read above is of the round before.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4, twice: on the eight clips before the fix round, and on LanternBurst, Combo and Work after it.
  - **Condition 6 holds.** No sleeve is held raised beside an upright body. The check corrected my numbers on two lines the audit excuses by the body's tilt (Down's right arm, Up's left), and they're in "The checks, as numbers" now. LanternBurst's pass rests on the sleeve staying level in the world while he tips back: against his own torso it's 21 to 27 degrees up for a fifth of a second.
  - **The lantern** is never onto or into his head or torso. It isn't a creature: no face, limbs, wings, voice or name, and giving it one breaks the sheet's condition 3.
  - **Down** is a comic knockdown that Up follows: a hat lying on a robe, a lantern looking on.
  - **Not seen by the check:** Combo's frames 12 and 28 with the lantern in the picture. They were judged from the arcs and the clip's nearest distances.
  - **For the builder, in the engine and at upload:**
    1. Upload exactly these exports. A clip keyed again is checked again, and so is a "Salute held" over 0.1 s or a "Salute tilted" line that grows or loses its tilt (Up 17 to 25, Down 16 to 19).
    2. The audit never saw a cross-fade. Step the bare rig through Up into Idle, and through any interrupt of Up or Down: Up's raised left arm must not land on an upright torso for over 0.1 s. Don't freeze or slow Down inside 13 to 19: hitstop belongs at the blow (6), where the arms are low.
    3. A Hit, a Down or a stagger that breaks LanternBurst's wind-up (8 to 45), the Reveal's loop or Work's duck-in cross-fades the lantern's joint: check that its path doesn't cut through his head, hat or torso.
    4. Down 41 to 66 and Up 0 to 10, with bloom and the light on, at 64 px from every heading: the flame is 0.6 studs over the floor beside the hat, and has to read as a hovering lantern, not a warm pool on the ground by a downed head. If it doesn't, the lantern is lifted in the hold. The tint stays `#FF8A3D`.
    5. Down held as a defeat, with the body left lying, goes back to the check before it's built.
    6. The robe set on a Voidkin with no hat leaves its face uncovered when it's down: that fighter's own check looks at its Down.
    7. Work's sleeve and the send's sleeve stay at or under level in any retune.
    8. The face and the eyes, read in the engine at Work 83 to 92 from the front, with the lit lantern a stud from his head, and at LanternBurst 57 to 63 from the front, where the thrown hat shades his face in Blender (CastShadow off on the hat should clear it).
    9. The glow at 64 px from every heading, with Combo 12 and 28 from the side and Work 76 to 92 from the front among the frames.
    10. Sections 1 and 2 still apply.
- **Research's read of round 1** (Quaestor, 2026-11-12, on the three packs in `build/handoff/Pip/clips/`): all three fixes pass, and Pip's eight clips are accepted.
  - **LanternBurst:** from the side, at 57 to 62, the bare rig goes over like a plank, where before only the hat went. Now he's the one thrown back, and the hat's disc lands on him as he lands. This is the feel line in stills. Whether it reaches exceptional is decided in motion, in the engine.
  - **Combo:** 1.15 and 1.25 studs with opposite rolls is the beat the flicks lacked. Frames 12 and 28 aren't in the pack. They're read in the engine's 64 px pass (the content check's item 9).
  - **Work:** at 76 and 83 the eyes show under the tipped brim, with the lantern lighting his face. Taking the pack from the front three-quarter is right until the bay is drawn.

### 4. Lyric's sheet (Modulo, 2026-11-12)

`build/handoff/Lyric/lyric_sheet.png`, 1920 by 1290, drawn by `tools/blender/lyric_sheet.py` (Workbench, about 9 seconds, no GPU turn). Pip's layout: the outline, front and back on the R6 body, how she stands, the player's camera; the signature's key pose from the target's side, as an outline side on and from the player's camera; all of it at 64 px over dark, Lantern Row's dusk and bright, and in black; the values. The sheet doesn't carry the signature's name (the content check, below).

**Feel line, proposed, for research to sign or change:** a stage singer who's never played a room this small: she drags the mic stand down to her, leans her whole weight into one note, and the two speakers she brought throw it down the street.

**The look:**

- **One idea:** she brought the stage with her, and everything she wears is cut on one slant, high at her right and low at her left.
- **The stand:** 6.2 studs on a round weighted base, a head taller than she is. A dark taped grip, a pale clutch, a chrome upper tube, and a chrome ball mic that leans back toward whoever holds the stand, with a lit ring under its head. She carries it as a staff in her gloved right hand. Its own piece.
- **The speakers:** two cabinets, 0.9 by 1.2 studs, that hover at her shoulders at two heights. One cone in a lit ring on the front, a lit bar on the back, a handle on top. Each its own piece, held by nothing.
- **The bob,** in two layers: a pale top layer cut straight from her right ear down to her left jaw, its fringe swept the same way, over a rose layer cut level at the jaw. The rose shows as a wedge that widens to her right, from the front and from behind.
- **The headset:** a band over the bob, a cup at each ear, a boom from her right ear to her mouth with a lit tip.
- **The jacket:** its hem runs from her right hip to her left knee, with a chalk band along it; chalk piping from her right shoulder to her left hip; a low collar. The back, what the player's camera sees: five lit bars, a level meter, and a radio pack on her belt.
- **The legs:** dark leggings into pale boots on thick dark soles, and one chalk stripe on the right leg, the one the short side bares.
- **The face:** R6's round head, eyes with one catchlight each, level brows, the fringe over her left brow. On the note her mouth is open.
- **Colours:** Limelight `#34A866` (Technique's family, deeper), Ash `#EAE4D6`, Storm `#FF6FD8` (AR3's Storm, and only on what's lit). Rose `#D94FB4` is matte and never lit. Backstage dark, chrome, skin.

**The key pose, the note:** she lunges with her right side leading. The stand's base is planted ahead and to her right, 58 degrees off her line, and the stand is leant 47 degrees, so the mic comes down to her mouth and her gloved fist closes on the pole under it, 10 degrees below level. Her body leans 17 degrees into it, her free arm is flung low and back, and the two speakers are thrown up and ahead to the wave's two edges, tipped down the street, their rings wide. From the player's camera the pole runs out to the right at its full length.

**For the model and the builder:** three pieces beyond R6's six, the stand and the two speakers. The stand wants a joint on the right arm; each speaker wants its own joint, and whether a speaker rides on her or is the builder's part that follows her is the builder's call. Blockout 5,028 triangles. Standing she is 6.26 studs across with the speakers and 6.19 to the mic's top; the note is 8.7 across and 6.6 deep.

**What I see wrong:**

1. From behind the bob is still a smooth pale dome with a rose wedge under it: a cap at a glance. The slant and the two layers read; hair doesn't yet. The model has to cut it into locks with tips that stand off the head.
2. R6 has no elbow, so the stand can only be held where its pole passes within an arm of her shoulder. With the base straight ahead of her the fist can't reach the pole at all and the arm ends 37 degrees up, straight and held; that was the first key pose, and it's why the base now goes to her right. The clips have the same limit: the stand swings about her right hand, never the hand along the stand. From the side the note's outline lost its long diagonal for it.
3. The speakers are boxes in the outline. What says speaker is the lit ring, which is there at 64 px from the front and missing from behind, where each shows one lit bar.
4. One hand holds the stand in every pose, so her right arm is spoken for in every clip: the free left arm does all the acting.
5. The note is wide. The speakers end 4 studs ahead and 3.6 out to each side and the stand's base 3.5 to her right, which is the effect's cone more than her body. In a fight they'd pass through allies. On the sheet's 64 px rows the two note poses' stands cross from one cell into the next.
6. Green with pink lights over Lantern Row's dusk holds at 64 px; over the bright ground the pale bob and boots drop away and she's a green block.

**Content check, 2026-11-12: BLOCK, on one thing that isn't drawn:** the signature's name in the roster, "Encore", on this fighter (rule 3, with `docs/ip-list.md`'s lines on signature-move names and shared names). The check's reason went to research by message; the rename is research's, and only the new name needs a check. Until then no sheet, definition or text of mine carries the name. The look, the poses, "Lyric" and "Tempo" pass rules 2, 3 and 4, at full size and in the 64 px block, judged from memory without web access. The check saw the pass before the last: since it, the heading lost the name and the mic arm went from 37 degrees up to 10 below level (its condition 9, measured by the script, which prints it). To hold on the model, the clips and the effect:

1. The signature is renamed before any player-facing text, definition or UI carries it.
2. The pale layer covers the whole crown and fringe, and the rose shows only under the slant. Never a left and right split, never red, never an all-pink, teal, turquoise or green head, never twin tails, long hair, loops or rings.
3. The jacket stays this true green in every variant, evolution and light grade: never teal, turquoise or cyan, never olive or khaki. No necktie, pleated skirt, detached sleeves, arm numerals or lit panel on a sleeve; the meter stays on her back as plain solid bars.
4. The stand stays a mic stand with a ball mic and a blunt round base: no blade, spike or point, never a guitar, wand or green rod. She never rides a floating stage or platform.
5. The speakers stay two plain cabinets with one cone each: no face, eyes, ears, limbs, wings or names, no megaphone horns, never more than two.
6. No brand mark, logo or text on the headset, speakers, pack or jacket. A mark added later gets its own check.
7. When the bob is cut into locks, the rose ends stay blunt and level. No rose lock tapers to a hanging point at the neck, and rose stays matte, unlit and off the skin, collar and jacket.
8. The leggings stay full-length, opaque and dark, and the hem's short side never rises above the belt.
9. The note's hold is stepped through on a bare rig from the side and three-quarter. In the hold the fist is at or below shoulder height, or the arm keeps moving, with the lunge, the lean and the low-back free arm kept (`handbook/platform/rules-and-moderation.md`, the held straight arm).
10. The free arm never holds a straight raise toward the crowd in any idle, victory or emote clip. No wink, blown kiss, heart hands, beckoning or hip-sway idle.
11. The wave is light, arcs, rings and speed lines that start at the speakers' rings, clear of her head. Nothing pink streams from her mouth or face on any heading at 64 px.
12. The effect has no droplets, spray, falling particles, splats, stains, pools or glossy shapes, and never shifts toward red. The hit is light, sparks and dust, and the heal is not hearts.
13. The wave stays a cone and never lengthens for each fighter it passes. Its shapes are drawn by our scripts.
14. Her sounds come from Roblox's library and are logged: no vocal-synth voice bank, no AI voice, no published melody.
15. The model and each upload batch get their own check, with the player's camera at 64 px over the dusk ground.

For research, from the check: `docs/decisions.md` still has no "Fighters" section, and no line on how mature the tone is; the check judged to the mildest reading. "Tempo" is never paired with "Lethal".

**Hours:** the sheet with its five blockout passes and the pose's rework after the check, about 2.

**Research's verdict, 2026-11-12.** **Feel line: signed** as proposed. **The signature is Held Note** (`docs/roster.md`): her feel line in two words, and it names the move by what she does. A plain phrase, nothing on `docs/ip-list.md`; the content check reads it with the model. **Felt:** a stage singer at a glance from the front: the stand taller than her and the two lit speakers say it at 64 px, and the note commits, the pole's long diagonal and the lunge selling one held blast; from the player's camera she's a green block under a pale dome with a lit meter, and that's the view players see most. **Tier:** competent; the note from the target's side reaches for exceptional. **The one bold thing:** the stand dragged down to her mouth in the note. Fixes, for the model:

1. **The back carries the slant:** the bob cut into locks that stand off the head (your point 1, agreed), and the chalk piping or the hem's band crossing the back so "cut on one slant" reads from the player's camera. Serves the view players see.
2. **Each speaker shows its lit ring from behind too,** so it reads as a speaker, not a box, from the player's camera. Serves the read of her kit.
3. **On bright ground** the pale bob and boots drop out: give the Ash parts a Backstage edge, thin, so her outline holds there. Serves later grounds.

Accepted: the stand's base to her right-front and the arm 10 below level (R6's limit, the hold within condition 9); the note's width, since the speakers mark the cone's edges and don't collide; the free left arm doing the acting. The check's ask: `docs/decisions.md` now has its "Fighters" section, with the tone. Her model can start.

### 5. Lyric's model on R6 (Modulo, 2026-11-12)

- **Where:** `build/handoff/Lyric/`: `Lyric_<Piece>.json` (twelve pieces), `Lyric_Color.png`, `Lyric_Roughness.png`, `Lyric_Metalness.png`, `Lyric_Emissive.png`, `Lyric.recipe.json`, `lyric_model_sheet.png`. Made by `tools/blender/lyric_model.py` (a Cycles bake under the lock, about 20 seconds): `blender -b --factory-startup --python tools/blender/lyric_model.py -- <out dir> [look]`; `look` stops before the bake and draws the model in Workbench. The shapes are `lyric_sheet.build(model=True)`. Made on Opus 5.5 xhigh.
- **How she sits on R6:** a rigid mesh for each of the six parts, carrying the body's own surface, so the rig's blocks are hidden and the Head's face decal goes. Three pieces on joints of their own:
  - **The stand,** on the Right Arm, its pivot where her fist meets the pole (`1.5, 2.15, -0.68`). At rest it stands upright on its base, the pole just in front of her hanging fist. The clips swing it about her hand and never slide the hand along it (R6 has no elbow; section 4, point 2).
  - **The speakers,** each on a joint on the Torso at its own middle (`±2.62, 5, 0.55`), held by nothing, the rest turn and the 0.9 scale in the mesh. Whether one rides on her rig or is the builder's part that follows her stays the builder's call.
  - And three **edges** (research's fix 3, below), welded to the Head and the legs.
- **The numbers:** 8,612 triangles in the twelve pieces, after research's two fixes (the head 1,884, each speaker 1,048, the torso 1,076, the stand 896, the edges 1,024 together). 5.38 studs to the headset's top, 4.15 wide without the speakers; the stand 6.2. One 1024 px atlas, 79 px per stud. Maps: colour with the contact shading baked in, roughness, metalness (the chrome, at 0.6), and a glow mask. No normal map.
- **The glow** is Storm's pink on the speakers' rings front and back, the mic's ring, the headset's tip and the meter, and nothing else. All of it sits on the Glow swatch, one flat block on both maps. The recipe's tint is white, since the colour map under it is already the pink (AR2, section 4): a strength of 1 as she stands and 2.5 for the speakers and the stand through the note. The face, the eyes and the rose layer take none.
- **Research's three fixes, made:**
  1. **The back carries the slant.** The bob's back is cut into seven pale locks, from behind her right ear to behind her left, each sunk under the crown and standing 0.1 studs off the bob past its slanted edge, each its own length; the rose layer under them is unchanged, cut level and blunt (condition 7). A chalk rail crosses her back at 24 degrees, high at her right, lying on the jacket as it flares, and the meter's five bars stand on it.
  2. **Each speaker shows a lit ring from behind:** a ring round a flat dark port, in place of the sheet's back bar. A port, not a second cone (condition 5).
  3. **A thin Backstage edge on the Ash parts.** The bob and the boots have a dark shell 0.035 studs outside them (but the front's locks, below), turned inside out, so only its far side shows, just past their outline: an inverted hull. Each shell is a piece of its own (`Lyric_HeadEdge`, `Lyric_RightLegEdge`, `Lyric_LeftLegEdge`) on the Backstage swatch, because it must cast no shadow.
- **Changed from the sheet (tier 1):** the headset's boom hugs her cheek, so in sunlight its tip's shadow stays under the tip (on the first bake it lay on her cheek as a dark smudge); everything rose (the hair's under-layer, the speakers' feet) sits on the Rose swatch and takes one flat colour (the content check, below); the meter's bars are re-heighted to stand on the rail.
- **For the builder, in the recipe:**
  - The edges: CastShadow off, or they shade the pale parts they wrap; DoubleSided off (the default), or they cover them. Each is welded to its part and takes the same SurfaceAppearance.
  - The three joints' pivots, and four points: `Mic` (the mic's head, where the note starts), `RingR` and `RingL` (each speaker's cone, where the wave leaves it), `Chest`.
- **What I see wrong:**
  1. From the front, in sun, the bob is near white and reads as a helmet with a dark rim; the front's slant rests on the fringe and the rose wedge, as on the sheet.
  2. The headset's lit tip sits at the corner of her mouth. Close up it can read as a pink mark on her cheek.
  3. At 64 px the edges are under a pixel. What holds her over bright ground there is the darker rim they give the outline. Close up they're a cel line on the pale parts alone, and the rest of her has none.
  4. The note's open mouth isn't on the model: her face is one mesh with the mouth closed. An open mouth for the note would be a small piece the builder shows during it, or nothing.
  5. With no clip playing, the stand stands in front of her fist, not in it.
  6. Nothing is seen in the engine. That the edges draw as they do here (one-sided, no shadow) is the preview's assumption, set as the recipe asks.
- **Content check, 2026-11-12: BLOCK on the colour map, narrowly; the model, the recipe, the other maps, "Held Note" and rules 2 and 3 passed.** A rose sliver from the hair's under-layer was a drop's silhouette, pointed above and heavy below, shaded to deep magenta: rule 4 at its mildest reading, the handbook's trap on drop shapes, as on Pip's flame. Fixed: every rose face sits on the Rose swatch. **Second look, the same day: PASS** on the rebake, all four maps, the sheet and the recipe. Conditions 1 to 8 and 15 hold on the model (7 stronger, the rose all one flat swatch); 9 and 10 are the clips', 11 to 14 the effect's and the sounds'. **Delivered** after it, all from the one run. New conditions:
  - The headset's lit tip stays at cold strength, never hot, and never sits over her lips, the note with her mouth open included. Close up it reads as a pink mark on her cheek.
  - Rose faces stay on their swatch in every later rebake and variant.
  - In the engine: at 64 px under Lantern Row's dusk grade, the jacket stays green, not teal (condition 3).
  - Before any upload: her rows in `docs/asset-log.md`, and the batch gets its own check.

**Hours:** the model, about 1.2, the look passes, the fixes and the check's round included.

**Research's verdict, 2026-11-12** (the model sheet, at full size and its 64 px rows). **Felt:** from the player's camera she now reads as a performer: pale locks over a rose edge, the meter standing on a slanted rail, a lit ring at each shoulder; the three fixes land, and the speakers read as speakers from every side. **Tier:** competent. **The one bold thing:** the two lit rings bracketing her at every heading, so the kit says "stage" even at 64 px. Fixes, for the next bake; her clips can start now, since both are on the head's mesh and no joint moves:
1. **The front reads hair, not helmet** (your point 1, agreed; serves her portrait on the lead's card and the reveal, which are the front of her head). Cut the front's slant into lock tips as the back is, and shade the crown a step cooler than Ash, so sun doesn't flatten it to white.
2. **The headset's tip leaves her mouth** (your point 2 and the check's condition; serves a clean face in the portrait). The boom ends at the middle of her cheek, a mouth's width clear of the corner.
Accepted: the edges as a darker rim at 64 px and a cel line close up (points 3 and 6, until the engine shows otherwise); no open mouth, since the pose carries the note (point 4); the stand at rest in front of the fist, which the clips hold (point 5).
- **Research's two fixes, made** (Modulo, 2026-11-12; baked again and delivered over the first, all from one run; made on Opus 5.5 xhigh):
  1. **The front reads as hair.** Across her face the top layer's edge is lifted 0.14 studs, and five short blunt locks hang from under it, overlapping to their ends, long and short by turns along the same slanted cut: a choppy fringe. Only the long one over her right brow passes the old line; the two over her left eye end at it or short of it. The crown runs up into `AshCool` (`#D4D5E0`), a step cooler than Ash, by height from 4.85 to 5.22 studs: a blend, never a seam, which would read as a helmet's rim. By day its top stays a light cool grey with its form.
  2. **The headset's tip is at mid-cheek,** level with her mouth and a mouth's width clear of its corner, turned to the cheek and still hugging it, so its shadow stays under it.
  - **Two tries failed on the way.** Tips with gaps and a dark edge each read in sun as a row of teeth over her eyes; without the edge, as fangs, since through each gap the forehead shows dark in the fringe's shadow, and will in the engine's sun too. So the front's locks have no gaps and no edge. The edges keep to the outline: the rest of the bob, the back's locks, the boots.
  - **Content check on the rebake, 2026-11-12: PASS** on rules 2, 3 and 4: the sheet, the 64 px rows, all four maps and the recipe. Conditions 2 to 8 still hold, and the crown stays pale. New conditions:
    - The shading between the front's locks stays soft, matte and grey-violet in every later bake and variant, never pushed toward magenta, red or a glossy black, and the locks stay blunt tabs, never tapering to hanging points. The colour map is moderated as a flat image.
    - In the engine: if the game adds bloom, her face is checked close up and at 64 px under the dusk grade, so the cheek tip's glow doesn't spread pink over her skin. If it does, the tip's strength comes down or it stays off bloom.
    - For the clips: in the note the mic's ring comes to her mouth at hot strength, near the cheek tip and the rose wedge. Stepped through at 64 px from the target's side and the player's camera, the two pink lights and the rose by her face must not read as pink coming off her face (condition 11).
  - Not yet read by research or seen in the engine. **Hours:** the fix round, about 0.5.
- **Research's read of the two fixes, 2026-11-12: accepted.** The front now ends in hair: the stepped locks break the crown's edge in the face by day and at dusk, and the crown no longer flattens to white. The cheek tip sits clear of her mouth. The gapless front, chosen after the teeth reading, is the right call. The model closes at competent; her clips are next.

### 6. Lyric's clips: research's read of the poses (2026-11-12, before timing)

On Modulo's five pose sheets (`build/scratch/modulo/lyric/clips/`). **Yes to timing**, with two fixes.
- **Held Note's toss: accepted** (tier 1). The stand leaves her hand, lands planted and leant, and she catches it into the lunge. It gives the note an anticipation beat the sheet didn't have, and it keeps the pole out of her head. Whether the toss delays the blast too long is judged in motion.
- **Fix 1, the Combo from the player's camera** (serves: three hits that read from behind, where players watch). The stand barely leaves upright on the stamp, the cue and the drive. The hits read only through her left arm. On hit 3 the stand is hoisted clear of the ground, its base about a stud up, and driven down, so its top travels visibly from behind.
- **Fix 2, the Reveal's held frame** (serves: her face on the reveal, which the front camera frames). At 90 and 150 the pole crosses her face. In the hold it stands beside her face, as the Idle's front shows.
- Accepted: the Idle, its monitor glance included; the Work; the Reveal's speakers rising one, two, three.
- **Her reactions: the robe set** (`docs/design.md`, "States in a fight"). The open set's leg swings of 98 to 112 degrees would come out through her jacket's tail. Faber names it in her definition.

- **Delivered: the five clips, with research's two fixes** (Modulo, 2026-11-12; made on Opus 5.5 xhigh). They are in `build/handoff/Lyric/clips/`: the five `Lyric_<Clip>.json`, `Lyric.clips.json` (frames, loops, markers), and each clip's pack with its notes. They are made by `tools/blender/lyric_clips.py` (`blender -b --factory-startup --python tools/blender/lyric_clips.py -- <out dir> [poses|export|audit] [clip ...]`). The working set is in `build/scratch/modulo/lyric/clips/`: the pose sheets, `arcs_<Clip>.png`, `bare_<Clip>.png` and `headings_HeldNote.png` (the toss and the note at 64 px, on eight headings, over both grounds). The audit and the content check pass on all five. Nothing is uploaded, seen in the engine, or judged at real speed.
  - **The five,** at 60 frames a second. Each clip has a body track and three prop joints: `Lyric_Staff` (the stand, at her fist), `Lyric_SpeakerL` and `Lyric_SpeakerR`. The clips' names carry the `Lyric` prefix.
    - **Idle** (a loop of 241): her weight is on her back foot, the stand leant in to her fist, and her chin keeps time. Once a loop (166 to 196) she glances back over her right shoulder at her monitor.
    - **Combo** (106; `Shot1` at 15, `Shot2` at 30, `Shot3` at 60): she stamps the base and the right speaker fires; she cuts her free hand at you and the left one fires. Then she hoists the whole stand and drives it down, and both fire.
    - **HeldNote** (151; `Breath` at 4, `Note` at 30, `Release` at 90): one breath, then she tosses the stand out (14 to 23). It flies near upright, clear of her, lands planted far out to her right and tips in to her. She catches it into the lunge: the mic at her mouth, her weight on it, the free arm flung low behind. The speakers fly out to the cone's edges and shake through the hold. After two beats of pushing she lets it go (96) and walks the stand back in (106 to 150).
    - **Reveal** (151; `Power` at 18, `Strike` at 90): her head is down and the speakers dark and low. They power up and rise, and two taps of the base count it in. On three her chin comes up, the stand upright beside her face, the free hand thrown out low. Held for her name.
    - **Work** (a loop of 121; `Pump` at 30): a soundcheck at the bay. The speakers are turned on the post and pump on every beat. She stamps the stand on two, and on four (84 to 108) she looks up to read the dial.
  - **Research's two fixes:**
    1. **Combo, hit 3.** At 54 the stand is hoisted clear, its base about a stud up and its top above the right speaker. The mic's head is then 4.1 studs from her mouth, against 2.0 to 2.5 for the other hits. At 60 it's driven down. From the player's camera its top travels one long arc, from high over her right shoulder down past the speaker (`arcs_Combo.png`, a dot a frame).
    2. **Reveal, the hold.** At 90 and 150 the pole stands upright to the right of her face, under her fist. From the front her face is clear (`pack_Reveal.png`, `poses_Reveal.png`).
  - **My calls (tier 1):**
    - The free arm's swing at `Shot2` is a little wider, because the audit had it 0.055 studs into her body at 29.
    - `headings_HeldNote.png` shows frames 10, 20, 30 and 60, so the toss is among them.
  - **The checks, as numbers, from the last run of all five:**
    - **The audit: PASS on every clip.** The worst results, each against its line:

      | Check | Worst | Line |
      |---|---|---|
      | An arm into the body | 0.042 studs (Combo) | 0.05 |
      | A leg out of the hip | 0.064 studs (HeldNote's lunge) | 0.10 |
      | Pop | 2.22x (Combo's free arm) | 3.0 |
      | A limb's turn about its length | 16 degrees in a frame | 45 |
      | Nod | 28 degrees (the Reveal's start and Work's post) | 30 |

      Nothing goes under the floor, and both loops' seams are at 0. Work's look up at the dial is quick, up to 12 degrees a frame at 90, and smooth (pop 1.0x).
    - **Held arms: none.** A raised arm held still: 0.00 s in all five. An arm nearly still at 20 to 70 degrees up: 0 frames in all five. The highest the stand arm goes is 19 degrees up, at Combo's hoist (54), moving, and 6 up at the throw (HeldNote 20). In the note it's about 10 below level. The free arm at its highest: -7 (HeldNote), -29 (Combo), -38 (Reveal), -74 (Work), -80 (Idle).
    - **The stand's nearest to her:**
      - Torso 0.15 studs (Reveal 83), Head 0.10 (Combo 60, the pole beside her face as it comes down), the right leg 0.17 (Combo 54).
      - It's 0.00 to her right arm at HeldNote 25: that's the catch, her hand meeting the pole.
      - Her fist stays on the pole, 1.38 to 5.11 studs up it, of the 1.3 to 5.2 it can hold. 5.11 is the haul, her hand high up the pole.
      - In the note the mic's head is 0.79 studs from her mouth at 30 and 0.69 at 88, just off her face toward the game's camera.
    - **The speakers' nearest to her:** 0.10 studs from her right arm at the Reveal's start, low at her sides. Otherwise 0.29 or more.
    - **A leg's widest swing:**
      - The left leg is under the jacket's tail, which allows 30: Idle 6, Combo 12, HeldNote 18, Reveal 17, Work 7.
      - The right leg is on the hem's short side: 32 in HeldNote's lunge (88), 17 in Combo, 16 in the Reveal.
    - **Her eyes, the face's pitch:** Idle -5 to +6; Combo -5 to +9; HeldNote +4 to +12; Reveal -38 with her head down to +6; Work -29 at the post to +22 at the dial.
  - **The clip pass:**
    - [x] Key poses from the clip's camera, read on all five packs: the player's camera for the fight, the front for the Reveal and Work, wide for the note.
    - [x] The eyes are measured (above).
    - [x] The audit passes on every export.
    - [x] Feet planted, and both loops close with a seam of 0.
    - [x] The stand and speakers keyed with the body at each beat, clear of her (above).
    - [ ] Blended the way the game blends: the builder's.
    - [x] Arcs and spacing are on `arcs_<Clip>.png`. The mic's widest spacing is on the toss, the hoist's drive and the haul. It's densest in the hold.
    - [ ] Judged moving at real speed: no, Blender runs headless here.
    - [x] Markers sit on every beat (`Lyric.clips.json`).
    - [ ] The game's own dump against the export: the builder's.
  - **What I see wrong:**
    - **The toss lands fast.** From 20 to 23 the stand tips from near upright to its long lean. At speed that may read as a snap, not a fall. Research's line already holds the toss's length for motion.
    - **The Reveal's free arm, from the front.** From 90 to 150 the arm, thrown out low (38 degrees under level), points toward the front camera and foreshortens beside her head. The content check read it as a hand at her headset. From the player's camera it reads as thrown out low.
    - **The robe set has no tracks for her props.** It carries no keys for her stand or speakers, so they stay at rest against their joints: the stand in her fist, the speakers by her shoulders. Where that lands in Down, as she goes over like a plank, I haven't seen. It may put the stand's base through the floor or the pole across her. I can step Pip's three on her rig with the props if research wants it before she goes in.
    - **The note at 64 px, by heading** (`headings_HeldNote.png`):
      - From her left (225 to 270 degrees) the stand is behind her and barely shows.
      - From her right front (45 to 90) its lean points at the lens, and it reads near upright.
      - From the player's side, behind her right shoulder, and from her front it's the long diagonal to her mouth.
  - **For research:** the read of the five packs, with fixes 1 and 2. The toss's length and the hoist's drive at speed are for the engine.
  - **For the builder, when Lyric goes in:**
    - Her definition names the `robe` set (research's ruling), and the robe set's look on her stand and speakers is the line above.
    - Show the blend over Idle, and the game's dump against the export.
    - The content check's engine conditions are below.
  - **Content check, 2026-11-12: PASS** on rules 2, 3 and 4, and on conditions 4, 5, 9 and 10, for all five clips.
    - **What it opened:** every pack and its notes, the bare, pose and arc sheets, and `headings_HeldNote.png`. The 64 px read is real for the note; for the other four it rests on the packs' strips.
    - **Condition 9:** stepped bare, the note is a lunge with a forward lean and the arm about level.
    - **Condition 10:** no free arm holds a raise.
    - **Condition 11, at the model's baked glow:** at 30 and 60, from her front and from behind, the mic, the cheek tip and the rose read as separate small marks.
    - **Also seen, and not blocking:** the stand passing 0.10 to 0.17 studs from her head, a blunt prop in its own place. HeldNote's right leg at 32 is research's to judge.
    - **To hold for the upload and the engine:**
      1. Upload only the five `Lyric_<Clip>.json`, never the review images.
      2. Her clips' rows go in `docs/asset-log.md` before upload, and the batch gets its own check.
      3. At the mic ring's hot strength in the note, step through at 64 px from the target's side and from the player's camera, under Lantern Row's dusk grade. The ring, the cheek tip and the rose must not read as pink coming off her face (condition 11). If they do, the ring's strength comes down or it stays off bloom. The cheek tip stays cold.
      4. Nothing traces the mic's head: no trail, ribbon or particles on its path, which rises off her face.
      5. Her reactions are the robe set, never the open set.
      6. A change to a clip's arm angles, or a new emote or victory clip, gets a new check. Conditions 4, 5 and 11 to 14 still hold for the effect and the sounds.

**Hours:** the clips, about 5 by my own estimate, not timed: about 3 to the pose sheets, the rest on the toss, the clearances against her mesh and the two fixes.

**Research's read of the five clips, 2026-11-12** (the packs, `arcs_Combo`, `headings_HeldNote`). **On to the builder.** Both fixes land. The Combo's drive now travels from high over her right shoulder down past the speaker, and in the Reveal's hold the pole stands right of her face. Accepted:
- **The toss's three-frame tip:** a stand landing should plant hard. Whether it snaps too much is judged in motion, with the toss's length.
- **The Reveal's free arm at her headset, from the front:** a singer's hand to her monitor. It's a gesture that fits her, it holds no raise (condition 10), and from the player's camera it reads as thrown low.
- **The right leg at 32°:** the jacket's short side is her right, so the tail doesn't cover it.
- **The note by heading:** from her left the stand hides behind her. The player's camera and the target's side are the reads that matter.
**The props in her fall: step Pip's Down on her once, after Rook's ram.** That's a look, not a new clip. If the stand goes through the floor or across her, the builder plays it as a prop state: the stand leaves her hand on Down, lies beside her, and comes back on Up. The speakers stay as they are.

- **The look, made** (Modulo, 2026-11-12; made on Opus 5.5 xhigh): Pip's `Down` played on her rig with no track for her props, as the engine would play it, so each stays at its joint's rest.
  - **What I made:** `build/scratch/modulo/lyric/robe/robe_down_lyric.png` shows every 6 frames from the player's camera, the side and the front. Made by a throwaway script beside it, `robe_down.py`.
  - **The stand: yes, the prop state.** It's rigid in her fist, so it follows the sleeve that reaches forward as she goes over.
    - 12 to 24: it swings up over her, base in the air, like a flag.
    - 29: the mic goes 0.23 studs through the floor.
    - 30 to the end: laid out, the pole lies across her head, through her hair's surface, the base standing a stud off the floor.
  - **The speakers: they stay.** They ride her shoulders down. Laid out, they sit 0.09 (right) and 0.15 studs (left) over the floor beside her head, never through it.
  - **For Faber, when Lyric goes in:** research's prop state for the stand on `Down`. It leaves her fist at the blow, before 12, so it never flags up over her, and lies beside her. On `Up` it comes back to her hand. `Hit` and `Up` weren't stepped. `Hit` is short and keeps her upright. `Up` starts from the lying pose, so the stand comes back to her as she rises.

### 7. Pip's Lantern Burst: the block-in (Modulo, 2026-11-12)

Grey shapes on his delivered LanternBurst clip, on its markers (Heat 8, Send 51, Burst 66, Return 98): timing and size only, no art. Made on Opus 5.5 xhigh.

- **Where:** `build/scratch/modulo/pip/burst/`.
  - `pipburst_A.png`, `_B.png` and `_C.png`: sixteen frames each from the player's camera, 8 to 128.
  - The three variants side by side: `pipburst_side.png`; `_beside.png`, the camera beside an elite; `_hidden.png`, the worst case; `_bright.png`; `_64.png`.
  - `pipburst.json` holds the lantern's places, each variant's share of the screen and its size.
  - `tools/blender/pip_burst_fx.py` rebuilds them in about two minutes.
- **The camera, as the game frames a fight** (`Config.Combat.Lead`). The lead stands beyond its target, turned `Frame` (45°). The camera is 12.5 studs behind the avatar, at the game's 70° field of view.
  - The player sees past the avatar and the target to Pip's front-left, 33° off his front and 30 studs away. The burst is nearer, at 21.
  - The avatar faces 26° past its target, the game's own turn for a keeper's ring, so its body hides none of the fight.
  - Beside an elite (`Beside`, 90) the throw crosses the screen and he's seen 63° off his front.
  - Dead on (`_hidden.png`), the avatar's body and the target hide the burst's middle.
  - The lantern stops a stud and a half short of the target's middle, so from the player's side the target stands in front of it. **Whatever the burst is, it has to read over and round the target.**
- **Feel line, proposed for research to sign:** past his target you see the little mage heave the lantern and get rocked back by his own throw; then his spell stands up over the Shades, a flame twice his height, and it's gone by the time he gets his hat up to look.
- **Job and rank:** his signature, and a starter's, so it aims at exceptional. It pays off a wind-up of 0.7 s, and it shows which Shades are hit.
- **One idea, three times:** the flame in his lantern, small, then bigger than he is.
  - **The heat** (8 to 51): the flame grows in the cage. It fills the cage by 30 and spills out past it by 45, to 1.25 studs.
  - **The send** (51 to 65): a ring kicks back off the lantern at his cuff, opening from 0.7 to 3.3 studs and pushed 0.9 toward him. It's the push that throws him (51 to 57). The lantern streaks out, its trail long while it's fast and gone as it stops.
  - **The punctuation** (66): a ball of light at the lantern, 1.7 studs.
  - **The burst** (67 on), by variant, over the area. The area's radius is a stand-in 5 studs, the builder's.
  - **After:** the lantern goes home spent, its flame out from 66 until it's home at 128, where it relights.
- **Variants:**
  - **A, the bloom:** seven tongues fly out of the lantern level, swing up to stand round the area's edge as they get there, then lift off and go out by 92.
  - **B, the flame let out:** one flame leaps up out of the lantern. Its foot drops to the floor by 69 and its belly is the area's width by 70. Its tip is at 12.7 studs by 70 and 13.2 at 72. From 73 it tears off the floor and narrows as it rises, its tip to 13.8 at 80, and it's gone at 92.
  - **C, the lantern of light:** the lantern's six bars spring out to the area's edge and up to 9.5 studs, with a lid on them and the flame filling them from 68 to 78. Then the bars break outward and go out by 90.
- **The measures,** at the game's field of view from the player's camera:

  | Variant | Peak share of the screen | Tallest |
  |---|---|---|
  | A | 1.0% at 72 | 6.6 studs |
  | B | 4.05% at 72 | 13.8 studs |
  | C | 3.7% at 72 | 12.1 studs |

  For scale: Pip stands 6.9 studs to the top of his hat, and Haymaker's thrown bracket is 5.4 studs tall at most.
- **My pick: B.**
  - One shape and one direction: it leaps up, most of its height in four frames, and its foot is the area.
  - It's the only one where the feel line's "bigger than he is" reads in a frame: twice his height, beside him.
  - It reads over the target from all three cameras, and its top still shows over the avatar's head when the avatar is dead on.
  - A is the size of a Shade and reads as spikes standing up from the ground; dead on, the avatar hides it.
  - C reads as a gazebo, a cage set down over the target, and a cage says "held", a state this signature doesn't have (`docs/roster.md`).
- **Stand-ins, not decided here:** the area's radius (5); the flight, the clip's 12 studs, scaled so the lantern stops about a stud short of the target's front; the camera's geometry (Faber's staged replay is the truth); the greys.
- **What I see wrong:**
  - **B's mass is one smooth teardrop.** On the sheets it can read as a drop or an onion dome. The art sheet gives it tongues and a ragged tip, so it's never a drop (section 1, condition 5).
  - **B rises, like the Shade's burst** (AR2, section 11). When the Lantern Burst kills, two flames go up within a breath of each other. They differ in size (13 studs against about 4), in colour (`#FF8A3D` against warm white and gold) and in when they come. Whether that reads as one gesture or a muddle is a call for motion.
  - **The punctuation is hidden from the player's camera.** The ball at 66 sits behind the target. From there the first readable frame is 67, B's tip just over the Shade's mask at 6.8 studs. The hit's frame belongs on 66 all the same, and the art's first frame has to clear the target's head.
  - **The heat is about 8 pixels at that distance.** From there, the wind-up reads through his pose and the lantern's own glow, not through the effect's size.
  - **The kick's ring** is a thin circle at his sleeve, and it's gone at 64 px. The recoil is the clip's read. If the ring adds nothing in motion, the art drops it.
  - The 64 px sheet's labels cover a third of each tile, as on the Shade's.
- **For research and the builder, tier 2, a proposal:** the signature "fires by itself, with a readout the player can watch" (`docs/design.md`). The lantern comes home spent. Its flame could relight over the cooldown, from dark at the burst to full when it's ready, so the lantern is the readout. It needs `EmissiveStrength` on `Pip_Lamp` driven by the cooldown, and research's word.
- **Not done:**
  - Research's verdict, with `ga-fresh-eyes` on the signature.
  - Then the art sheet: the flame's shape, tongues and `#FF8A3D`, never redder; the trail; the heat in the cage; the rim for the bright floor. Then its content check.
  - Then the builder's build. The beats aren't in a Definition: Pip has no action in `Definitions.Actions` yet.
- **Hours:** about 1.0.
- **Research's verdict, 2026-11-12** (pipburst_A, B, C, side, beside, 64; `ga-fresh-eyes` read blind beside it). **Feel line: signed.** **B, the flame let out.** **Felt:** a speck of a mage past the Shade flicks something, then a spire of flame snaps up over the Shade in two frames, twice his height, thins upward and is gone. The flame's half of the line lands; his half, the heave and the kick back, barely reads from this camera. **Tier:** competent; a starter's signature aims at exceptional. **The one bold thing:** 67 to 69, a curl becoming a tall flame over the Shade. Fresh eyes: competent, the same bold thing, and the same two gaps. Fixes, for the art sheet and the build:
1. **Pip's half reads at 30 studs** (serves: the line's first half, the wind-up the burst pays off). The heat reads by the lantern's own glow climbing through 8 to 51, which a pose can't do at that distance. The send's trail is bright and long enough to carry the eye from him to the target.
2. **The flame lives through its hold** (serves: a flame, not a tent). From 72 to 76 it boils, its tongues licking up, never a still dome. Its ragged tip makes it never a drop (your point 1).
Accepted: the hit's frame on 66, with the art's first frame clearing the target's head; the kick's ring dropped if it adds nothing in motion. The two rising flames, his and a Shade's on a kill, are called in motion on the builder's replay. **Tier 2, the lantern as the readout: yes** (research, for the design; the builder's word on the cost). The lantern comes home dark and relights over the cooldown, full when the signature is ready. The HUD's ring stays, since the lantern isn't always on screen (`docs/ui.md`).

### 8. Lantern Burst's look: the art sheet (Modulo, 2026-11-12)

The block-in's B, the flame let out, with research's two fixes (section 7). Made on Opus 5.5 xhigh.

- **Where:** `build/handoff/Pip/fx/`:
  - `pip_burst.png`, 1024 x 896: the flame's sixteen frames and the heat's four, one upload;
  - `pip_burst_trail.png`, 512 x 128: the trail, a second upload;
  - `pip_burst_art.png`, the sheet;
  - `pip_burst_art.json`: what plays on every frame, and the checks' numbers.
  - Made by `tools/blender/pip_burst_art.py` in about a minute, in Workbench: `blender -b --factory-startup --python tools/blender/pip_burst_art.py -- <out dir>`. Add `pictures` for the two pictures alone.
- **The pictures:**
  - **Four tones, hard edges:**
    - a cream core (`#FFF4DC`);
    - a gold (`#FFC65A`);
    - Pip's flame orange (`#FF8A3D`), the reddest thing in it;
    - his ink (`#1E1B22`) as the rim, about a pixel at 64 px.
  - Nothing hangs, drips, falls or breaks off: a loose fleck read as a drop.
  - **Three nested flames,** orange, gold and cream, each with its own tongues and out of step, so the inside licks too. Drawn by depth alone, the cream made a tent.
  - **The leap (cells 0 to 3):** a curl off the lantern that unrolls into the tall flame, 13.2 studs.
  - **The boil (4 to 7):** every tongue licks up, thins and snaps back, each on its own phase. Some tongue is always reaching, and the tip is ragged on every frame.
  - **The end (8 to 15):** the whole boiling flame, smaller and raised as one, down to a wisp. Its foot leaves the ground while its tip stays near where it was, and it cools from the cream to the gold to the orange. The last four are in 128 cells.
  - **The heat (16 to 19):** its own four, a round belly with tongues licking out of the cage's lid.
  - **The trail:** the flame blown back, a round head at the right and three tongues streaming to points at the left.
- **The numbers it's played at** (the clip's frames, 60 a second; Send 51, Burst 66):
  - **The burst, 66 to 93:** one billboard, 15 x 15 studs, three times the area's radius, so it scales with the area.
    - Its foot is on the ground under where the lantern stops. It never moves; only its cell changes.
    - The leap plays one cell a frame (66 to 69), the boil two frames each (70 to 77), and the end two frames each (78 to 93).
    - It's gone after 93, 0.45 s after the marker.
  - **The heat, 8 to 65:** a cell every two frames, in a square whose belly sits on the lantern's middle, eased between 1.0 stud at Heat, 1.9 at 30, 2.8 at 45, 3.2 at Send and 2.6 at 65. It flies with the lantern.
  - **The trail, 52 to 70:** a Beam with `FaceCamera`, Width0 0.6 and Width1 2.4.
    - Attachment0 sits at his cuff, where the lantern was at Send (for a later frame, 15 frames back, never before Send). Attachment1 sits on the lantern.
    - After the Burst, its tail closes onto the burst over 5 frames.
  - **The glow:** `Pip_Lamp`'s `EmissiveStrength`, 1.2 cold to 3.0 hot from Heat to Send on the curve u^1.6, slow then fast. It's held through the flight and is 0 from the Burst. The relight over the cooldown is yours.
- **Research's fixes:**
  1. **Pip's half from 30 studs.** Counted from the player's camera at 456 x 256, the block-in's pixels to the art's:
     - 30: 49 to 59. 45: 83 to 84. 51: 122 to 152. 60: 117 to 189.
     - At 55 the block-in's 623 was its kick ring, now dropped; the art has 193.
     - The rest of fix 1 is the glow, which isn't drawn here: its climb is the builder's, on the mask.
  2. **The flame lives through its hold:** the boil above, 72 to 76 included. It's never a still dome: four different raggings.
- **The measures,** the block-in's to the art's:
  - The burst's share of the player's screen: 67: 0.7% to 1.9%. 69: 3.4% to 4.0%. 72: 4.1% to 4.2%. 76: 3.5% to 4.3%.
  - At 64 px: 720 to 764 px at its height, against the block-in's 601 to 714. 90 px at 90, against 26.
- **For the builder (your call, Faber):**
  - **One way:** as the Shade's burst. A `BillboardGui` with an `ImageLabel` on the one upload, stepping `ImageRectOffset` and `ImageRectSize` by the table, `LightInfluence` 0, `ImageColor3` white. The heat is a second one on the lantern.
  - **The trail's texture:** U runs from the tail (Attachment0) to the lantern (Attachment1), stretched once (`TextureMode` Stretch, `TextureLength` 1). Please check its way round on the first replay: if it plays backward, swap the attachments, not the picture.
  - **Back:** a knob that pushes the burst's plane away from the camera, so the Shades it hits stand in front of it. The sheet's last row shows 2 studs. I'd play it at 0, since it reads over and round the target as drawn. It's yours to tune on the replay.
  - **The table:** `pip_burst_art.json`, `frames`. For each frame:
    - the burst's cell;
    - the heat's cell, its size, and `up`, its centre above the lantern;
    - the trail's tail and head as clip frames, and how far it has closed;
    - the glow.
    - Positions are by rule from the lantern, so they follow the game's own lantern.
  - **No glow is drawn on the pictures.** Their brightness under bloom is yours.
  - **The readout** (research's tier 2 yes): the relight over the cooldown, and its cost, are yours.
- **My calls (tier 1):**
  - **The kick ring is dropped,** with research's leave. The recoil is the clip's.
  - **The trail holds at his cuff through the whole flight.**
    - From the player's camera the flight comes at the lens, about 36° off its line, so it shows at about 60% of its length. A lagging trail was a few pixels behind the heat.
    - Held, it draws the line from him to the target and is pulled into the burst.
  - **The end goes to a wisp,** not the block-in's thinning. Thinned, the flame left a stem under its tongues, a matchstick, and a single tip read as a teardrop.
- **What I see wrong:**
  - **The trail is still small from the player's camera:** about 40 px at its longest (66) on a 456 px frame, and before 60 it's mostly behind the heat's flame. That camera sees the throw coming at it, so the glow and bloom will carry more of fix 1 than the trail does. The replay judges it.
  - The avatar's head and body cover the burst's middle from the player's camera. Its tongues and tip read round them.
  - End cell 2 keeps the outermost pair of tongues low at its sides for two frames.
  - The heat's cells swap every two frames, so it may flicker at the lantern.
  - It's a preview in my renderer: no bloom, no camera move.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4 and section 1's conditions 3 and 5, with nothing redder than `#FF8A3D`. To keep it a pass (a change comes back to the check):
  1. **The tint stays white:** `ImageColor3` and the Beam's `Color` white, so the orange shows as drawn. An orange tint multiplies it to red.
  2. **Never on the floor:** the burst stays an upright picture facing the camera. Laid flat as a decal or ground mark, it reads as a scorch or a pool.
  3. **No new shapes:** no shards, no splash, nothing liquid on the ground, and nothing in the flame's colours that moves down (falling embers, a lantern that breaks).
  4. **One engine look under the game's bloom:** the heat at the lantern beside his head, at 64 px from every heading, reads as the lantern, not as something coming off him (section 2's condition). The bloom doesn't turn the orange red or haze it onto the ground.
  5. Both pictures are logged in `docs/asset-log.md`, and uploaded for the group by the key, together.
- **Not done:**
  - Research's verdict, with `ga-fresh-eyes` on the signature.
  - The uploads: two images, the group's, by the key.
  - The builder's build and replay.
  - The two rising flames, called in motion.
- **Hours:** about 2.5.
- **Research's verdict, 2026-11-12** (pip_burst_art, the two pictures). On to the builder.
  - **Felt:** a curl of fire comes off the lantern, unrolls into a tall inked flame over the target, licks, and lifts off as a wisp. The flame is Pip's: cream, gold and his orange, held by his ink.
  - **Tier:** competent on the sheet, beside fresh eyes' competent. Exceptional, which a signature aims at, has to come on the replay, from the glow and the bloom.
  - **The one bold thing:** the leap, 66 to 69: one curl unrolling into the whole flame. Fresh eyes named the same frames, and the wisp at 88 to 93 second.
  - **Fix 2: accepted on the sheet.** The tip is ragged on every cell. Whether it lives in motion is the replay's call, since fresh eyes read the boil on the sheet as "one card held in place". The builder's lever if it does: one frame per cell, through the four boil cells twice.
  - **Fix 1: carried to the replay.** The drawn half is up from 30 on, and the trail is honestly small from the camera the throw comes at. Pip's half has to read at 30 studs through the lantern's glow climb and the bloom. If it's still a few orange pixels, the next levers are the glow's hot end, then the heat's size at Send.
  - **For Modulo's look on the replay, a note and not a fix:** the boil's outer tongues lick out low at the foot (69 to 80), wider than the block-in's column. If in the game it reads as a campfire rather than a flame standing up, those tongues come off the ground.
  - **Accepted:** the trail held at his cuff; the kick ring dropped; the end as a wisp; Back at 0 to start. The two rising flames are called on the replay.
- **Builder, 2026-11-12: Pip in the game, with his Lantern Burst** (Faber).
  - **Built, and where:**
    - **Pip:** assembled from the uploads by `tools/studio/Models/Pip.luau` into `src/storage/Pip.rbxm`. The hat and the lamp are held pieces on the robe rig (`Config.Animations`), his idle is his own, and his clips are imported and kept in the saved place. `Definitions.Voidkin`'s pip names his model and rig.
    - **His kit:** `PipCombo` and `PipLanternBurst` in `Definitions.Actions`, `Kits.pip`. A hit with `Area` lands on every enemy within that many studs of its target (`Rules.Fight.Within`, `FightService`).
    - **The look:** `Config.Effects.LanternBurst`, played by `FighterController/Effects.LanternBurst` from `pip_burst_art.json`'s table: the glow's climb on `Pip_Lamp`, the heat on the lantern, the trail's Beam, and the burst, 15 studs (3 × Area), its foot on the ground under where the lantern stops.
    - **The shots:** a grey block, a streak from the lantern to the target on each shot (`Config.Effects.Shot`). It reads (`build/captures/ar4/pip_combo_take1_scan.png`).
  - **My calls (tier 1):**
    - **The effects' own clock runs through the hitstop.** The action's clock stops in a hold, which froze the leap on cell 0 for about 7 frames in take 1. The burst's cells and the trail's closing count from the Burst on that free clock. The heat, the glow and the throw stay on the action's clock.
    - **The throw follows the target.** The client scales the lantern's flight from Send so it stops `Throw.Short` (1.5 studs) short of the target, between 0 and 1.25 of the clip's, and hands it back between Return and the clip's end. The flight is offset on the lamp joint's `C0`, because the Animator overwrites `Transform` in every phase. The table's positions are by rule from the lantern, so the heat, the trail and the burst follow it.
    - **The trail plays the right way round:** the round head at the lantern, so the attachments stay as they are. Back stays at 0.
  - **The readout (section 7, tier 2): my word is yes, and it's built.** The lamp is dark from the Burst to the clip's end. It then relights to Cold over the rest of the cooldown, on `Glow.Relight`'s curve (1, linear), and is full when the signature is ready. A new burst takes it from wherever it is.
    - **Its cost to build:** one property write a frame on one `SurfaceAppearance` while it relights, on the client only.
    - **Its cost to the design, for research:** in a fight the signature fires as soon as it's ready, so the lantern sits below full for about 89% of each 10 s cycle: dark for 1.1 s, then 7.8 s of relighting. It reads dim for most of a fight, and full only for a moment before each burst.
    - **The lever:** `Relight` above 1 holds it dim, then fills it late; below 1 fills it early.
  - **The content check's conditions, in the game:**
    1. The tint is white on both billboards and the Beam, with `LightInfluence` 0. The self-test asserts it.
    2. The burst is an upright billboard facing the camera, and nothing lies on the floor.
    3. No new shapes.
    4. **The engine look**, at ClockTime 17.6 (the game has no dusk grade yet), frozen at 0.75 s, with Pip scaled to 64 px (`build/scratch/faber/h64_*.png`):
       - At headings 20 and −70, the heat reads as the lantern alight beside his hat.
       - At 90, the lantern is on his far side and peeks out, cage and all, between the brim and his shoulder.
       - At 160, he's cut off by the screen's edge, a spot the framing avoids.
       - The game's bloom (Threshold 2) doesn't take the billboards at Brightness 1. Nothing reads red, and nothing hazes onto the ground.
    5. Both pictures are uploaded for the group by the key, together, Approved, and logged (`docs/asset-log.md`).
    - **Pip's own conditions:** the face shows under the brim at 64 px, at 17.6 and at 18.3, near dark. The eyes are never lit. `CastShadow` is off on the hat and the lamp in the template. The flame plays as drawn, `#FF8A3D` at its reddest.
  - **The checks:**
    - The type check: 0 new. The logic cases: 1,459 pass.
    - The self-test's Lantern Burst case: 30/30 with Pip as the lead. It covers the glow, the cells, the heat's size and belly, the trail, the burst's size and foot, the white tint, nothing left behind, and the relight.
    - The whole Fight suite with Rook as the lead: 166/166. With Pip as the lead it was 177/178: the one fail was the case's own, since it looked for Rook's idle. Fixed, it passes on Pip's.
  - **For research's two judgements** (`build/captures/ar4/`):
    - **Pip's half at 30 studs:** `pip_burst_take2.mkv`, and `pip_burst_take2_half.png`, four frames through the heat. My read: a cold flame in the cage at rest, then the heat swells beside the hat to 3.2 studs at Send, and it reads from the player's camera. The levers are `Effects.LanternBurst.Glow.Hot`, then `Heat.Keys`.
    - **The boil, 70 to 77:** `pip_burst_take2_burst.png` (60 fps, the table's two frames a cell) beside `pip_burst_boil1x2_burst.png` (your lever: one frame a cell, played twice).
      - My read: at two frames a cell the tongues visibly change every second frame, which isn't one card held still. At one a frame it flickers.
      - Yours to call. The levers are `Burst.Boil` and `Burst.BoilPlays`.
    - **To replay it yourself:** in a playtest, on the Server, `game.ServerStorage.NL_Debug:Invoke("Act", nil, "SetLead", { Voidkin = "k6" })`, then `Invoke("Replay", nil, "PipLanternBurst", 4)`. `Invoke("Replay", nil)` stops it, and `k1` puts Rook back.
  - **Seeds, a tier 2 notice for research:**
    - The shots: 0.75, 0.75 and 1.17 of his power, a second's worth as Rook's combo's, with Reach 15.5.
    - The burst: 2.5 on each Shade within 5 studs, heavy, Push 1.5, Cooldown 10.
    - Range: 14.5 for both, so he fights 13.5 studs off (Range − Approach) and the clip's throw lands as drawn.
  - **Not done:**
    - Research's verdict on the replay (fixes 1 and 2), with `ga-fresh-eyes`.
    - The two rising flames on a kill. The replay's dummy doesn't fall, so they wait for the Shade's burst (AR2, section 11).
    - Modulo's look on the replay: the low outer tongues.
  - **Hours:** about 4, an estimate.
- **Research's verdict on the replay, 2026-11-12** (take 2: the burst, the half, the scan; the boil at 1x2; fresh eyes blind beside). In the dev build.
  - **Felt:** the lantern heats beside his hat, a gold streak leaves him, one tall lick shoots up past the Shade and the flame fans out round it, holds, then pinches up into a wisp. **Tier:** competent, the same as fresh eyes. A signature aims higher. **The one bold thing:** the entrance, the single lick for one frame before the rest fans out. Fresh eyes named it too.
  - **Fix 1, Pip's half: accepted for the heat.** It swells to his head's size beside the hat at Send, and the streak carries it to the target. `Glow.Hot` stays. **His recoil doesn't read at the player's distance** (fresh eyes: "standing, then ducking"). That's half the feel line, so it's a fix: the throw rocks him back a step, and the hat tips with it. Modulo's clip.
  - **Fix 2, the boil: the table's two frames a cell stays.** At one a frame it flickers. **But the peak holds one outline for about 14 frames, and both readers called it a bonfire.** Modulo's note becomes a fix: lift the outer tongues off the ground, narrow the foot, and let the outline climb a little through 70 to 77, so a flame stands up rather than a fire sits.
  - These two are the second round on the burst. After them it stays competent if it doesn't climb, with no third round.
  - **The readout: `Glow.Relight` 0.5,** research's call on the design cost. The lamp is dark straight after the burst, which is the read that matters, and lit again by the cooldown's middle, so Pip's lantern isn't dim for most of a fight. The HUD ring still says "ready".
  - **The seeds, tier 2: yes, provisional.** The burst at 2.5 a Shade is under Haymaker's 4.0 on one target and over it on two. That's the crowd-clearer's trade. They're measured when the slice's packs exist.
- **Round 2, the last on the burst: he's rocked back a step, and the flame stands up (Modulo, 2026-11-12).** Made on Opus 5.5 xhigh.
  - **Fix 1, the recoil.** Files: `tools/blender/pip_clips.py`, `burst()`; `build/handoff/Pip/clips/Pip_LanternBurst.json` and `pack_LanternBurst.png`/`.txt`.
    - **Why it read as ducking:** in round 1 the kick knocked the hat off his head, and it came down too far, over his eyes. So he sank under it.
    - **The throw now throws him (56):** he leans back 24° with both feet free. At 61 he steps back onto his right foot, his hips 1.1 studs behind where he stood, and he's caught on it at 65, about 1.4 studs back.
    - **The rest of the clip:** he stays rocked back and tall through the burst. At 86 he leans in to see whether it worked, and he steps home over the return.
    - **The hat** tips back off his brow with the throw: 16°, then 19° against his body at the step, riding 0.2 studs up, held through the burst. At 106 he nods it back down (16°), and it settles forward into place at 108.
    - **The beats are unchanged:** 133 frames and the same markers (Heat 8, Send 51, Burst 66, Return 98).
    - **The audit: PASS.**
      - A leg's widest swing is 24° of the robe's 25°, at the step.
      - The brim's rim is never lower than 2.91 studs, so he's tall through the whole clip.
      - His left hand comes no nearer the hat than 1.43.
    - **The brim against the robe's mesh:**
      - Nothing is inside it through the hold.
      - At the kick (56), 3 to 14 vertices are 0.03 inside. Round 1 had about 20 at 0.1 through its hold.
      - The deepest point is the wind-up's sleeve at 46, 0.29 in, unchanged.
    - **At 64 px** (`build/scratch/modulo/pip/round2/headings_LanternBurst.png`, eight headings, dusk and bright): the tipped hat changes his outline from every heading. The key poses are in `poses_LanternBurst.png` beside it.
  - **Fix 2, the flame stands up.** Files: `tools/blender/pip_burst_art.py` (`STAND`, `CLIMB`, `STOOD`, and `stand` and `pinch` in `shape`); `build/handoff/Pip/fx/pip_burst.png`.
    - **The foot draws in** through the boil (70 to 77). On the ground it's 9.4 studs at 69, then 6.5, 5.1, 4.7 and 4.7. Before, it held at 11.
    - **The root pinches up,** so the flame rises from a point rather than standing on a block.
    - **The four outer tongues leave the ground** for its flanks. Their lowest points are 0.75, 2.1, 2.2 and 2.9 studs up, where before they were all at 0.01.
    - **Below 4 studs** the widest is now 9.1 down to 7.3, from 12.3 to 12.6.
    - **The top climbs,** 13.2 to 14.25 as drawn. The licks still move it: measured, it's 13.5, 11.9, 12.8 and 13.8, then 14.5 at 78.
    - So each two-frame cell has its own outline, where round 1 held one through the boil.
    - **The end** starts from where the boil stood, with its tongues still up its flanks. The pinch at its foot lets go as it lifts, so its bottom stays round and never comes to a point.
    - **Unchanged:** the leap's one tall lick (accepted), the heat, the trail, the timing and every cell's place.
    - **Its cost:** at the peak the flame covers 0.30 to 0.34 of its cell, where it covered 0.35 to 0.36. That's about 11% less flame on screen.
  - **The table is unchanged.** On the new clip, `table()` gives the same play data as the handoff's `pip_burst_art.json`: built from the keyed rig and compared key by key, nothing differs.
    - **The full art run,** on the director's go (2026-11-12, "foreground go"): the json's `checks` and the sheet `pip_burst_art.png` are round 2's. At the peak the burst covers 3.6% to 3.9% of the player's screen. Round 1 covered 4.2% to 4.3%, and the block-in 3.5% to 4.1%.
  - **My calls (tier 1):**
    - **The leap keeps its wide foot:** at 69 the flame stands 9.4 wide on the ground. That shows the area the hit covers, at the moment it lands. Then it draws in.
    - **The hat's tilt against his body stays under about 29°,** or the brim's back cuts his collar. His lean back carries the rest of the tip.
    - **The hat over his eyes is gone:** it tips back off his brow, and the nod brings it down.
  - **What I see wrong:** at 64 px the climb barely shows: a stud is about 4 px. The stand and the narrower foot read; the climb reads at full size.
  - **The content check: PASS** (rules 2, 3 and 4) on the picture, the glance, the pack, the headings, the poses and the bare rig. On its ask, it also checked every cell at 64 px over the dusk and the bright ground (`build/scratch/modulo/pip/flame/pip_burst_at64.png`). Nothing drips, every tongue points up, there's no red past `#FF8A3D`, and nothing sits on the floor.
  - **For the builder:**
    - Import `Pip_LanternBurst` into the saved place.
    - Upload `pip_burst.png` for the group by the key, in place of the current one.
    - The table and the trail are as they were.
  - **Not done:** research's read of the recoil, on a take that shows him clear. The flame is accepted (below).
  - **Hours:** about 3, an estimate.
- **Round 2 in the game (Faber, 2026-11-12).**
  - **In:**
    - The clip is imported into the saved place (version 188): 133 keyframes, 101 moved from round 1, the markers unchanged.
    - The picture is uploaded for the group by the key: 139257020366755, Approved, in `Config.Effects.LanternBurst.Picture`. Round 1's 98613697418337 is unused (`docs/asset-log.md`, row 18).
  - **Tests:**
    - The fight's self-test cases: 223 of 223 at 60 fps, the clip's markers against its beats included.
    - Logic 1,584; type check 0 new.
  - **Research's take, Pip's burst killing two Shades from the player's camera** (`build/captures/ar4/`):
    - `pip_r2_two_take.mkv` is the take.
    - `pip_r2_two_strip.png` runs from 0.82 to 2.27 s, a cell every 3 frames, six to a row.
    - `pip_r2_two_full_<s>.png` are full views: 1.12 (the numbers), 1.37 and 1.47 (the boil), 1.57 (the lanterns flare), and 1.67 to 1.87 (they climb and burn down).
    - The seconds count from the step Pip's clip was first drawn. The magenta square in the bottom-left corner is the take's sync mark: my kit left it on after its first picture.
    - Staged for the take only: two level 1 brawlers side by side, 9 studs ahead of the avatar. Their health was tuned live to 200, so the burst's 298 kills both (at 881 it can't). It went back when the playtest stopped, and nothing in the game changed.
    - What it shows: both bodies fall together, and two lanterns flare out of Pip's flame as two separate flames and climb apart.
  - **Found: the kill shows 0.3 s before its flame.** Three takes, the same each time.
    - **On the client:** the Shades hit Pip twice during his throw. Each hit holds his clip about 0.1 s, at frames 43 and 55, so his heave stutters twice.
    - **On the server:** the clock doesn't hold, so the Burst's hit lands on time at 1.10 s, while his clip on the client is only at frame 57.
    - **Then:** the client holds Pip at frame 57, mid-flight, for the heavy hold, and his flame comes out at 1.38 s. By then the Shades started falling at 1.08 s and their numbers showed at 1.12 s. Their lanterns flare at 1.65 s.
    - **The cause:** hitstop is presentation only, and its time isn't caught up (`handbook/feel/combat.md`, "Hit confirmation"; `handbook/feel/game-feel.md`, "Hitstop"). That works for a hold after the fighter's own contact. A hold taken in the middle of the fighter's own action delays its later beats on the client only.
    - **Proposal for research,** its own piece outside round 2. Both changes are client only, with no change to pace or balance:
      1. A fighter in the middle of an action takes no hold when struck. It still shows the spark and the number. This removes this drift and the stutter in his heave.
      2. A server hit that arrives before the client reaches its beat moves the clip on to that beat before the hold, so the hold always lands on its contact frame.
    - **The other way:** the server could hold too. That slows every action by its holds, which is a balance change.
- **Research's read of round 2 in the game, 2026-11-12** (the two-Shade strip, 1.47 and 1.67 s).
  - **The flame stands up: accepted.** At 1.47 it's a tall flame with its tongues climbing off a narrower foot, and no longer a bonfire.
  - **The two rising flames: accepted.** Pip's orange flame lifts as a column, and the Shades' two cream flames flare from its foot and climb apart. Their colours keep them separate, and they read as one gesture: his fire, then their lights leaving.
  - **The recoil:** not judged on this take. The Shades stand between him and the camera, and the hold-drift freezes him mid-flight. It's read on the next take that shows him clear.
  - **The drift: yes to both of the builder's client-only changes,** as their own piece, before the Frame experiment. A kill that shows before its flame breaks cause and effect on every action. Design's word on change 1: a fighter mid-action shows the spark and the number when struck, but its clip never holds. Its own action's beats keep the stage.
- **The hold-drift fix in the game (Faber, 2026-11-12),** on research's yes above. Client only, with no change to pace or balance.
  - **In:**
    1. A body struck in the middle of its own action shows the spark and the number, and its clip doesn't hold (`FighterController`, `show`).
    2. When a server hit finds the screen's clock short of its beat, the clip and its effects' clocks move to the beat before the hold (`Fight.CatchTo`; `FighterController`, `catchUp`). The effects' free time doesn't move, since it already ran through the hold.
  - **Tests:**
    - Logic 1,589, with CatchTo's case. Type check 0 new.
    - The fight's self-test cases: 236 of 236 at 60 fps.
    - A new case holds the lead's combo 0.4 s on screen at its first hit. Each later hit then finds the clock, the clip and the effects on its beat: Shot2 at 0.433, Shot3 at 1.033.
    - A body in the middle of its action takes no hold. Idle, it holds 0.09 s.
  - **Beyond the burst:** in a chain, the fighter's own hold on one hit leaves its screen that far behind the server. The next hit now moves the clip on by up to that hold (0.09 s light, 0.13 heavy), then holds on its contact frame. Before the fix, that hold landed short of the contact frame. Shot3 came on its beat this way in the case.
  - **Research's take: the kill on the flame** (`build/captures/ar4/pip_hold_fix_*`).
    - **Staged** as round 2's take: two level 1 brawlers. Their health was tuned live to 200 for the take only, and went back when the playtest stopped. 58.2 fps. The sync mark now shows for three pictures, then goes.
    - **The client's log:**
      - Pip's clip reaches the Burst's frame 66 at 1.07 s, and both Shades go down at 1.10 s with his clip at 67.
      - Through the throw his clip never holds longer than a picture.
      - They vanish at 1.58 s.
      - Before the fix, he held at 43 and at 55, the kill came at his frame 57, and the flame at 1.38 s.
    - **The files:**
      - `pip_hold_fix_strip.png` runs from 0.82 to 2.10 s, a cell every 3 frames.
      - `pip_hold_fix_full_<s>.png` are full views: 1.07 (the flame), 1.10 (the kill), 1.20 and 1.35 (the boil and the numbers), and 1.55 (the lanterns).
    - **The recoil:** the Shades stand between him and the camera until they vanish at 1.58 s, as in round 2's take.
- **Research's read of the hold-drift fix, 2026-11-12** (the strip, 0.82 to 2.10 s).
  - **Accepted.** The flame leaps and the two 298s rise in it. The kill is the flame now, cause and effect in one picture.
  - **The chain:** accepted as built. A hit that moves the clip on by up to its own hold keeps each contact on its beat, and that's the rhythm the player reads.
  - **The recoil:** hidden again by this staging, and it isn't asked of another take. The Frame 150 take puts Pip on the player's side of his target, so it shows the recoil clear. It's read there.
  - **Pip's Lantern Burst** stands at competent with round 2, its last round (the director's planned rework of its look: `docs/polish-later.md`). It closes once the recoil is seen in that take.
- **The Frame 150 take (Faber, 2026-11-12),** research's ask, on the director's go: "it fine he can do the test" (2026-11-12). The go covers this one evidence take, not a change to the Frame. `Combat.Lead.Frame` was tuned live to 150 for the take and put back at 45. Nothing in the game changed. The replay, from the player's camera, at 57 to 58 fps.
  - **The files** (`build/captures/ar4/`):
    - `pip_frame150_burst.mkv`, with `pip_frame150_burst_strip.png` (1.7 to 3.1 s, at 10 fps).
    - `pip_frame150_combo.mkv`, with `pip_frame150_combo_sheet.png` (at 3 fps).
    - `lyric_frame150_note.mkv`, with `lyric_frame150_note_strip.png` (0 to 1.5 s, at 10 fps) and `lyric_frame150_note_sheet.png` (two presses).
  - **What I see:**
    - **Pip at 150 stands at the frame's right edge, about half of him cut off.** His reach (gap 13.5) puts him about 49° right of the camera's axis, at the edge of its field of view. The lantern's arc to the dummy and the burst read whole. The recoil shows only as his tilt at that edge, so it isn't clear here either.
    - **The combo:** Pip at the same edge. His shots show only as the numbers over the dummy.
    - **Lyric at 150 stands whole,** right of the dummy (gap 11). Her crests cross toward it from the side.
- **Research's read of the Frame 150 take, 2026-11-12.**
  - **The answer: Frame stays at 45.** On the player's side, a ranged lead's reach pushes it to the frame's edge (Pip half cut off at 13.5), and its shots show only as numbers. At 45 it's small but whole, and on screen. The director's word fits it too: the camera stays on the player, and the lead needn't fill it. The experiment is closed, with no change.
  - **What it showed:** Pip's burst reads whole from either side. The lantern's arc back to the target is the best view of the throw so far.
  - **Pip's recoil:** judged on Modulo's round 2 replay strip (he rocks back a step with the hat tipped back), and accepted. At the play camera it's a small beat behind the flame, and the flame is the read.
  - **Pip's Lantern Burst closes: competent,** two rounds and the hold-drift fix. Director-accepted: not yet. The director's planned rework of its look stands (`docs/polish-later.md`). Still open in the game: the trail's quarter turn (the builder's, queued).

### 9. Lyric's Held Note: the block-in (Modulo, 2026-11-12)

Grey shapes on her delivered HeldNote clip, on its markers (Breath 4, Note 30, Release 90): timing and size only, no art. Made on Opus 5.5 xhigh.

- **Where:** `build/scratch/modulo/lyric/note/`.
  - `heldnote_A.png`, `_B.png` and `_C.png`: sixteen frames each from the player's camera, 4 to 108.
  - The three variants side by side: `heldnote_side.png`; `_beside.png`, the camera beside an elite; `_hidden.png`, the worst case; `_bright.png`; `_64.png`.
  - `heldnote.json` holds the cone, the figures' places in it, the frames each wave reaches them, and each variant's share of the screen.
  - `tools/blender/lyric_note_fx.py` rebuilds them in about a minute.
- **The cone comes from her speakers,** read off the keyed clip in the hold: their two lines meet 3.9 studs behind her, 24° each side of her line. The rings stand 4.5 studs up, tipped 14° down the street, so the wave's middle falls a quarter of a stud for every stud it goes. It's 12 studs across at the target and 16 at its end. **Its length is a stand-in:** 16 studs out from her, the wave from the rings at 4.7 studs out. None is in the design.
- **The camera, as Pip's block-in** (section 7; `Config.Combat.Lead`): the target 11 studs out in the cone's middle, the lead beyond it turned 45°, the camera 12.5 behind the avatar at 70°. The player sees her 36° off her front from 27.6 studs, and **the wave comes at the camera.** A second Shade stands deeper (12° off the middle), and an ally, another lead, stands in it to her left (17°).
- **Feel line, proposed for research to sign:** past her target you see her lunge into the mic, and the note comes down the street at you in arcs of light, one on every half-beat, each one landing on the Shades and washing over her side, until she lets go and the last runs out alone.
- **Hero shape:** the crest, an arc across the whole cone, thrown fast from the rings and slowing as it goes.
- **Shared by every variant:**
  - **The charge** (22 to 30): a light swells in each ring as the speakers draw back with her breath.
  - **The punctuation** (30): both rings flash, ring-sized (0.9 studs).
  - **The touches:** stand-ins for the builder's shared hit and heal, to time them. A flash at a Shade's chest, and a ring rising round the ally, on the frame a wave reaches it.
  - **The wave's shape:** a veil the wave's full height that you see through, with a white ribbon on its leading face. At the target the veil spans 1.8 to 4.6 studs up, and at the end from the floor to 4.3.
- **Variants:**
  - **A, the crests:** an arc thrown from the rings on every half-beat (30, 45, 60, 75, 90). Each takes 14 frames to the end, fast then slowing, and thins as it gets there. It reaches the target at 33, 48, 63, 78 and 93.
  - **B, the front:** one arc thrown to just past the target by 36, then pushed slowly on through the hold, shaking with the speakers' buzz. On the Release it runs to the end and goes by 100. It reaches the target and the ally once, and the deeper Shade only at 73.
  - **C, the stream:** the arc thrown at the Note, as A's first, then speed lines poured down the cone from the rings, two a frame, through the hold. On the Release they stop at the rings and the last run out by 100.
- **The measures,** at the game's field of view from the player's camera:

  | Variant | Share of the screen | Touches on the target |
  |---|---|---|
  | A | 2.8% at 40, 1.4% through the hold, 2.2% at 98 | five, the last after the Release |
  | B | 1.2% to 1.9%, held the whole hold | one |
  | C | 3.0% at 40, then 0.3% to 0.8% | one |

  For scale, Pip's Lantern Burst peaks at 4.05% (section 7, B).
- **My pick: A.**
  - It's her beat. Everything she does lands on 120 a minute. The crests make the music visible, and they keep landing as long as she holds, so "held" reads as pressure that keeps coming.
  - It reads from the player's camera and at 64 px: a pale arc crossing the screen every half-beat. Each one shows the cone, so you see who's in it.
  - B reads as a wall held up in front of the Shades, a shield, which her ability isn't. It also stands between the camera and the target for a whole second.
  - C's speed lines run almost at the lens, so from the player's camera they're scratches, 0.3% of the screen. They read only from the side.
- **What A asks of others, for research and the builder:**
  - **Five touches,** the last after the Release. Either the hit and the heal tick five times across the hold, or they land once on the first crest and the rest is show. That's the design's call, tier 2.
  - **Her clip,** mine: the speakers buzz ten times a second through the hold and kick only at 31. With A they'd kick on each crest (45, 60, 75, 90), four lines in `lyric_clips.py`. I'd make that change once A is picked.
- **Stand-ins, not decided here:** the cone's length (16 from her); its opening up and down (11°); a crest's 14 frames; where the figures stand; the greys.
- **What I see wrong:**
  - **The avatar is in the cone.** In the game's framing it stands 22.5° off the middle, inside 24°, and the crests run over it near the camera. That's A's peaks at 40 and 98. A heal washing over the avatar may read as healing it, and the avatar is never a target (`docs/design.md`). Either the cone is shorter than about 15 studs from her, or the crest fades past the last figure it reaches. For research and the builder.
  - **The speakers land at 32,** two frames after the Note, so the first crest is born ahead of them. Either the fly-out lands on 30 (my clip), or the first crest rides with the rings for two frames.
  - **From the player's camera, the left speaker sits just left of her head on screen.** The ring's flash stays ring-sized, or it covers her face (condition 11).
  - **The avatar's body covers the cone's right half** from the player's camera, as it covered Pip's burst's middle. The left half carries the read.
  - **Each crest is on screen about 9 of its 15 frames.** At real speed that could strobe. That's for motion to judge.
  - The 64 px sheet's labels cover a third of each tile, as on Pip's and the Shade's.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4 and conditions 11 to 13, the grey block-in only. The drawn look keeps:
  1. **The ring's flash stays clear of her face,** with a gap you can see, and never pink, red or warm there. Every heading is read at 64 px.
  2. **C's speed lines stay long streaks** running out along the cone, never short bits or dots that seem to fall (condition 12). They end at the cone's end, not on the floor.
  3. **Nothing liquid:** no gloss, beads or drips at a band's edge, and no splash where the wave meets a Shade.
  4. **The heal is a plain ring,** never hearts.
  5. **The arc stays sound or light.** A sharp crescent coming at the camera can read as a blade's slash: a note, not a block.
  6. **The drawn effect gets its own check** in every tint it uses, at full size and 64 px, over both grounds, from every camera here.
- **Not done:**
  - Research's verdict, with `ga-fresh-eyes` on the signature.
  - Then the art sheet: the crest's look, the veil, the touches' shapes; then its content check.
  - Then the builder's build. The beats aren't in a Definition: Lyric has no action in `Definitions.Actions` yet.
- **Hours:** about 1.5.
- **Research's verdict, 2026-11-12** (A, B and C, side, 64; fresh eyes blind beside). **A, the crests**, for your reasons. Fresh eyes picked A too.
  - **Feel line, signed with one change:** past her target you see her lunge into the mic, and the note sweeps out across the Shades in arcs of light, one on every half-beat, each one landing on the Shades and washing over her side, until she lets go and the last runs out alone. ("Comes down the street at you" becomes "sweeps out across the Shades": from the player's camera the arcs cross the screen, and they must never reach the avatar.)
  - **Felt:** a lunge, a wide pale arc curling over both Shades, then a pulse through the hold, and one last arc alone after she lets go. **Tier:** competent for a block-in, the same as fresh eyes. **The one bold thing:** the first wide arc at 40, over both Shades. The lone last arc at 98 comes second.
  - **Fix 1, the crest never reaches the avatar:** the cone is 14 studs from her (research's design number, tier 2, until balance gives range a cost), and each crest thins to nothing over its last 4. Serves: the avatar is never a target. Builder: confirm the avatar stands past 14 in the game's framing.
  - **Fix 2, no dead air in the hold:** fresh eyes read 60 to 75 as gaps. Each crest lives until the next is halfway out, so one is always on its way. That also answers your strobe worry. Serves: "held" reads as pressure that keeps coming.
  - **Five touches: yes, tier 2.** The signature's total is split over the five crests, each a fifth, so the total doesn't change. A crest that shows a hit lands one. Builder: your word on cost.
  - **Your clip, yes:** the fly-out lands on 30, and the speakers kick on each crest.
  - **Accepted:** the ring's flash stays ring-sized; the left half carries the read past the avatar's body. B reads as a shield, and C's streaks vanish at 64 px, as you saw.
- **Builder, 2026-11-12: Lyric in the game, with her Held Note** (Faber).
  - **Built, and where:**
    - **Lyric:** assembled from the uploads by `tools/studio/Models/Lyric.luau` into `src/storage/Lyric.rbxm` (twelve meshes, four maps, the group's, all Approved). The stand is a held piece on the robe rig, and her idle is her own. Her Idle, Combo and HeldNote are imported and kept in the saved place, with the crests' markers. Her Hit, Down and Up are the robe set. `Definitions.Voidkin`'s lyric names her model and rig.
    - **Her kit:** `LyricCombo` and `LyricHeldNote` in `Definitions.Actions`, `Kits.lyric`.
    - **The shots:** the grey streak, from the speaker that fires, as section 6 has it: right, left, then both (`Config.Effects.Shot.Speakers`).
    - **The Held Note's beats are the clip's markers:** Breath, Note, Crest2, Crest3, Crest4, Release. Each of the five is a touch, 0.5 of her power on every Shade in the cone, so 2.5 in all, the size of Pip's burst. Cooldown 10.
    - **The cone:** 14 studs from her, 24° each side of her line, the angle measured from the point 3.9 behind her where the speakers' lines meet, as the block-in read it (`Rules.Fight.InCone`). Nothing behind her is in it.
    - **The grey look,** every number live by `Tune` (`Config.Effects.HeldNote`, `FighterController/Effects.HeldNote`):
      - A glow swells in each ring over the 8 frames before the Note, flashes ring-sized (0.9 studs) and fades over 6.
      - On each touch a crest of twelve grey panels is thrown from 4.7 studs out, fast then slowing, its middle falling as the rings tip. Its axis is the line to the target when it's thrown.
      - **Fix 1:** each panel thins to nothing over its last 4 studs, so a crest is gone at 14.
      - **Fix 2:** each crest lives until the next is halfway out (its life is the gap × 2^(1/Ease)), so one is always on its way.
    - **The heal:** each touch heals her, and every ally lead standing in the cone, by 0.04 of their most. A `+N` in the heal colour rises over a healed body of mine (`Net`'s `Heal`).
  - **Five touches, my word on cost: yes.** The server runs the hit five times a press: a cone scan over the pad's fighters, one Hit message for each Shade touched and one Heal for each body healed. That's a handful of messages a second while she holds.
    - **One change it needed, `Steady` (tier 1, mine):** a touch holds the Shades, never her. Five light holds on her would stop her 0.09 s each, so the crests after the first would land 0.09, 0.18, 0.27 and 0.36 s late, off her 120 a minute. Her clip now runs straight through.
  - **Fix 1 confirmed: the avatar stands past 14.** In the replay it's 20.2 studs from her. In the game's framing (the target 11 out in the cone's middle, Lyric beyond it turned 45°), the avatar is past 14 whenever it stands more than about 3.9 studs from the target. The logic case checks 4, 5.2 and 8. Closer than that, a crest's fading tail can reach its spot on screen, but never as a touch: a touch lands only on the other side, and the avatar isn't a fighter.
  - **Research's prop state** (`Config.Animations.Props`, `FighterController`):
    - **On Down:** the stand leaves her fist 0.1 s in (frame 3, before the blow at 12), falls over 0.25 s, and lies flat on the floor 2.9 studs to her right and 1.5 behind her. She falls back, so it lies by her body, 0.16 studs clear of her arm.
    - **On Up:** it rises back into her hand over 0.3 s.
    - **How:** each client lets go of its own copy, the motor off and the piece anchored. The server's never moves. A first try, steering the motor against the clip, lagged a frame and tipped the lying stand into the floor.
  - **Two fixes beside it, for every fighter:**
    - **Up plays on every rig.** It played only on the open-legs rig, so Pip never played PipUp. He does now.
    - **Each target gets its own hold and spark.** An area hit sparked once before, so Pip's burst on several Shades now sparks on each.
  - **The checks:**
    - The type check: 0 new. The logic cases: 1,571 pass, with the Held Note's (its numbers, the cone at its end, its edges and behind her, the avatar's distance, the heal).
    - The self-test's Held Note case with Lyric as the lead: each crest lands once on each Shade in the cone, both Shades are struck, every touch is steady, five heals come to 185.6 of the 185.6 wanted, her clip never holds, and the avatar stands 20.2 off. The whole Fight suite with her: 199/199.
    - The whole suite with Rook as the lead: 374/374, at 60 fps.
    - **The capture:** at the first crest the arc crosses both Shades, with a spark on each, and the rings' flash stays ring-sized.
  - **Seeds, a tier 2 notice for research:**
    - **The heal:** 0.04 of the most a touch, 0.2 a press, on her and every ally lead in the cone. A seed, not simulated: the balance sheet has no heal yet.
    - **The shots:** 0.75, 0.75 and 1.17 of her power, Pip's, with Reach 13. Range 12 for both, so she fights 11 off, where the cone's middle meets her target.
  - **For research's verdict on the block in the game:** in a playtest, on the Server, `game.ServerStorage.NL_Debug:Invoke("Act", nil, "SetLead", { Voidkin = "k7" })`, then `Invoke("Replay", nil, "LyricHeldNote", 4)`. `Invoke("Replay", nil)` stops it, and `k1` puts Rook back. No shard holds her yet (she's Zone 2's), so the Test store's save got her from `Invoke("VoidkinGive", nil, "lyric")`, Studio only.
  - **Not done:**
    - Research's verdict on the replay, with `ga-fresh-eyes`.
    - **The art (section 10, Modulo's):** the crest's look, the veil, the touches' shapes. Then the rings' hot strength and the dusk check against it (condition 3). Her glow stays cold through the note in this block.
    - **Her clips are unpublished** until a public build, under the content check's conditions: only the five `Lyric_<Clip>.json`, their rows before the upload, and a new check if a clip's arm angles change.
  - **Hours:** about 4, an estimate.
- **Research on the seeds, 2026-11-12 (tier 2).** The verdict on the block waits on a take.
  - **The heal: 0.01 a touch, not 0.04,** so 0.05 a press, a DESIGN seed. At 0.04 she heals 20% of her health every 10 s, 2% a second. A keeper takes 1.2 to 2% a second off an on-budget Common Warrior, which ends near 10% with no lifesteal (`docs/balance.md`, "Fights against the game"). So a solo Lyric could never fall to a keeper. At 0.01 she heals 0.5% a second, about a third of that: a little more than the typical 2% lifesteal gives. It's measured when the balance sheet models heals.
  - **The shots and the range: yes,** provisional, as Pip's.
  - **`Steady` on her touches: accepted** (tier 1, the builder's). Her 120 a minute is the action.
- **Builder, 2026-11-12: the heal at 0.01, and the take for the verdict** (Faber).
  - **The heal is 0.01 a touch** on all five (`Definitions.Actions`). The logic case now checks a press's total, 0.05. Logic 1,571, type check 0 new. The self-test's Held Note case with Lyric: 19/19, five heals coming to 46.4 of the 46.4 wanted.
  - **The take,** in `build/captures/ar4/`, from the player's camera at 58 to 59 fps, with a second Shade deeper in her cone and her health at half:
    - `lyric_note_take1_press.mkv`: one press. Frame 0 is the one picture with a magenta square in the bottom-left corner, a timing mark for this take only, never in the game.
    - `lyric_note_take1_strip.jpg`: every second frame, 22 to 108, eight a row. Each picture is within 1 ms of its frame's time (the `.tsv` beside it).
    - `lyric_note_take1_f33.png`, `_f63.png` and `_f95.png`: full frames at the first crest, mid-hold and the last crest after the Release.
  - **My read, for your fix 2:** each crest exists until the next is halfway out, but from about 38 to 43 of each half-beat little shows. With `Ease` 4 a crest spends most of its life in its last 4 studs, where it thins to nothing.
    - **The lever, beside it:** `lyric_note_ease2_press.mkv` and `lyric_note_ease2_strip.jpg`, the same press at `Ease` 2 (its life follows: the gap × 2^(1/2)). A crest shows in every tile through the hold. Her health was full by that press, so it shows no `+9`.
    - Yours to call: `Effects.HeldNote.Ease` stays 4 in `Config` until you do.
- **Research's verdict on the block in the game, 2026-11-12** (take 1 at Ease 4, the same press at Ease 2, three full frames; fresh eyes blind beside). **Ease 2, and the block is accepted.**
  - **Felt:** at Ease 2 each crest is still whole when it crosses the Shades, so the 37 comes from the wave. After she lowers the mic, the last one runs past alone. **Tier:** competent, the same as fresh eyes. At Ease 4 it reads "works": each crest is biggest beside her and a sliver by the time it lands, the reverse of the feel line. **The one bold thing:** the crest arriving whole over the Shades.
  - **For the art sheet (section 10, Modulo's), three things the grey shows:**
    1. **The beat inside the wall:** at Ease 2 the crests overlap into one white wall that blurs the half-beat. Each crest's leading ribbon carries its arrival, bright, and the veil behind it falls away, so you count five even when two are on screen.
    2. **An arc, not a panel:** the grey is flat banked rectangles. The crest the block-in chose is an arc across the cone.
    3. **The lunge:** "her body stays planted and only the mic stand tilts". With the speaker kicks you're already adding, she drives into the mic on the Note, enough to read at 27 studs.

### 10. Held Note's look: the art sheet (Modulo, 2026-11-12)

Research's three asks on the block in the game (section 9, its verdict). Made on Opus 5.5 xhigh.

- **Scope.** In it: the crest's ribbon and veil, the touches' shapes (the hit, the heal, the rings' flash), the table, and the lunge. Waiting, the builder's: the rings' hot strength and the dusk check against it (condition 3).
- **Where:** `build/handoff/Lyric/fx/`.
  - `lyric_note_crest.png`, 1024 x 256: the ribbon.
  - `lyric_note_veil.png`, 1024 x 256: the veil.
  - `lyric_note_touch.png`, 1024 x 512, in 256 cells: `hit0` to `hit3`, `heal` and `flash`.
  - `lyric_note_art.json`: what plays on every frame.
  - `lyric_note_art.png`: the sheet, her clip from the player's camera and four other views, at 64 px on dark and on bright.
  - The code: `tools/blender/lyric_note_art.py` (79e8295), and the lunge in `tools/blender/lyric_clips.py` (f4aad8c).
- **Ask 1, the beat inside the wall.** Each crest is two Beams on the same two ends.
  - **The ribbon:** two white strands edged in her Storm, crossing and crossing again over a thin pale core, one for each speaker. Its ends are round.
  - **The veil, under it:** the band's body, pale and see-through, rimmed in Storm, with a lower `ZOffset`. It holds 3 frames after the throw and falls away over 8 (`veil_hold`, `veil_fade`).
  - So an older crest is the braid only, and two crests on screen never stack into a wall. Up close (`build/scratch/modulo/lyric/art/lyric_note_strip.png`, 31 to 55), at 45 to 50 the new crest is bright and veiled and the older one a braid.
- **Ask 2, an arc.** The Beam's `CurveSize` bends each crest into a circle's arc across the cone: 0.2834 × its radius at each end, along the tangent. The table's notes say "an arc, never flat panels".
- **Ask 3, the lunge** (f4aad8c).
  - She gathers back on the throw (20), then drives into the mic on the Note: her torso 26° in and 1.4 studs on, her feet stepped out under her hips.
  - The hold keeps the lean. She straightens off it on the let-go.
  - The markers are unchanged. AUDIT PASS.
- **The touches:**
  - **The hit:** a white ping with Storm crackling out from it, in short strokes that never fall. Four cells, two frames each, 3 studs across, on a Shade's chest the frame a crest reaches it.
  - **The heal:** a plain mint ring rising round an ally, 14 frames.
  - **The flash:** white, at each ring. It's 0.9 then 0.6 on the Note, and 0.6 then 0.4 on each crest after.
- **The table's timing** (`lyric_note_art.json`):
  - The crests are thrown at 30, 45, 60, 75 and 90.
  - Each punches 70% of the way out in 7 frames, then drifts on to the end over 34. It's unseen for its first 2.5 studs, out of the rings' flash, and thins to nothing over its last 4.
  - On the sheet's stage, the target is touched at 33, 48, 63, 78 and 93, the deeper Shade 8 frames after each, and an ally a frame before.
- **For the builder, one question:** the table's motion is the block-in A's punch and drift, and the game's block plays `Ease` 2, which research accepted.
  - Either play the table's radius and its two transparencies a frame, or keep `Ease` 2 and take from the table only the look by the crest's age: the ribbon thinning over its last 4 studs, and the veil's 3 and 8 frames.
  - Yours and research's call. The pictures work with either.
  - **Research's answer, 2026-11-12: the game keeps `Ease` 2,** the direction from its verdict in the game (section 9). The table's punch and drift isn't used, so take from the table only the look by the crest's age. Research judges the crest's size in the replay, with the Beam's width as the live lever, and there's no redraw before that verdict.
- **The sheet's checks:**
  - **The share of the player's screen,** block-in to art: through the hold, 1.4% to 0.6%. At 40, 2.8% to 0.4%. At 92, 0.5% to 0.7%.
  - **At 64 px,** the effect covers 70 to 158 pixels, on dark and on bright.
  - **The run:** Blender's peak was 960 MB. It was stopped twice by Claude Code for low system memory, then ran in the foreground on the director's go.
- **What I see wrong:** on screen the art covers about 40% of the grey's share through the hold. The crest reads as a bright braid where the grey was a band, so its arrival is sharper but it's smaller.
  - If the replay finds it slight, the lever is the Beam's width (the table's `width`, about 2 to 2.4 studs), as one scale in `Config` that's live by `Tune`. That needs no redraw, since the pictures stretch across it.
- **My calls (tier 1):**
  - The ribbon's two strands, one for each speaker.
  - The veil's 3 and 8 frames.
  - The crest born unseen for its first 2.5 studs, out of the rings' flash.
- **The content check: PASS** (rules 2, 3 and 4) on the three pictures, the sheet and the strip.
  - On its ask, it also looked at the three uploads alone at 64 px over the dusk, a bright ground and grey (`build/scratch/modulo/lyric/art/lyric_note_upload64.png`), and at the clip's bare rig and pack after the lunge. Both closed.
  - **Its conditions:**
    1. The crackles stay uneven strokes of different shapes, never twelve identical bolts evenly round a ring.
    2. An arm stays at or below shoulder height through the throw (16 to 24) and the haul (104 to 112). Measured on every frame by the clip's audit, each arm's highest is 9° above level (the right, at 20), and no arm holds at 20 to 70° up.
    3. The builder measures the flash's share again at the camera's closest zoom. At the player's default distance the whole effect is under 3% of the screen.
  - Storm (`#FF6FD8`) reads pink, never red.
- **For the builder:**
  - Upload the three pictures for the group by the key.
  - Play them from the table: two Beams a crest, the veil's `ZOffset` under the ribbon's, `CurveSize` as the table has it, the touch cells and the flash.
  - Then the rings' hot strength and the dusk check (condition 3), and the flash's share at the closest zoom.
- **Not done:** the builder's import; research's verdict in the game.
- **Hours:** about 4, an estimate.
- **Builder, 2026-11-12: the art in the game, and the take for the verdict** (Faber). Made on Opus 5.5.
  - **Implemented** (`FighterController/Effects.luau`, `Config.Effects.HeldNote`):
    - **The pictures** are the group's uploads, all Approved (read back): the ribbon 98526314701538, the veil 97868344376539, the touches 108376131261819 (`docs/asset-log.md`). The ribbon and the veil went up turned a quarter clockwise, their left end the top row, with the pixels unchanged, because a Beam runs a picture's height along it (`handbook/visuals/vfx-engine-facts.md`, "Beam"; tested here).
    - **Each crest is two Beams on the arc's two ends:** the ribbon (`ZOffset` 0.02) over the veil (0). Both are upright (`FaceCamera` off), stretched, still, white, unlit, 24 segments. The ends sit at plus and minus the half angle on the radius off the apex, the first on her left. `CurveSize` is 4/3 × tan(half / 2) × radius at both ends (0.2834 × r at 24°), so each crest is a circle's arc.
    - **Motion and look:** the motion stays `Ease` 2 (research's answer, above). The look by age is the table's: born unseen over its first 2.5 studs, narrowing to 0.4 of its height over the last 4, the veil held 3 frames and gone over 8.
    - **The width:** `Config.Effects.HeldNote.Width`, a scale on the table's height, live by `NL_Debug:Invoke("Tune", "Effects.HeldNote.Width", 1.5)`. At 1 it's the table's: 0.9 studs at the rings, growing as the crest goes out.
    - **The flash:** the flash cell on each ring, 0.15 out along her facing. It swells from 0.25 to 0.55 over the 8 frames before the Note, is 0.9 and 0.6 on the Note and the frame after, and 0.6 and 0.4 on each later crest.
    - **The touches:** a struck body takes the hit's four cells (2 frames each, 3 studs, 1.2 toward the camera) on the frame its crest comes within 0.7 of it. They come in place of the spark (`Effects.Running.Struck`; `FighterController`, `drawnBy`). If its crest has already run out, they come at once. Its number and hold stay on the server's beat.
    - **The heal's ring:** each heal puts the ring flat round the healed body (`Effects.HealRing`, by the healer's action, `FighterController`'s `HEALS`). It rises from 0.4 to 5 studs (out fast), its radius goes from 1.6 to 1.12, and it's gone over the last 5 of its 14 frames.
  - **Tested:**
    - Type check: 0 new. Logic: 1589.
    - A new self-test case on a stand-in of hers, so it runs with any lead: "the Held Note's look keeps the art sheet's table". It checks the flash's sizes and cell, the two Beams' setup, the arc (both ends on the radius, 48° apart, its middle on the radius too), the height and width by age, Width live, the veil gone after 11 frames, the touch on the frame the crest comes within Short (frame 5 at 9 studs) and only once though struck twice, the heal's ring, and nothing left. It passed in both whole Fight runs.
    - The whole Fight suite at 60 fps: 273/278, then 274/278. The fails were in two other cases, each passing in the other run, the first alone too (30/30): the Lantern Burst's look (its lantern checks read the lead's own burst from the fight before) and the replay's combo (no hit landed). Both read state this client-only change doesn't touch. They join the intermittents.
  - **Condition 3, the flash at the camera's closest zoom.** In the replay with the camera fully in (0.5), on the Note's frame (the flash's largest, 0.9 studs), the two flashes cover 0.32% of the screen. That counts their cells' whole squares, so it's an upper bound: RingR at 15.7 studs, RingL at 10.6, at 1361 × 827. She's nearer only when the avatar walks up to her: one 0.9-stud cell covers 2.8% of the screen at 3 studs and 1.0% at 5, for one frame, then 0.6 for one more.
  - **The take for research's verdict:** `build/captures/ar4/lyric_note_art_take.mkv` (12 s at 58.5 fps, lossless; four presses, every 3 s). It's the replay from the player's camera, three level-1 brawlers standing in the cone between her and the dummy.
    - The Shades were spawned on their spots with `Combat.Shade.Notice` 0 and `WalkSpeed` 0, tuned for the take only and put back.
    - Also: `lyric_note_art_strip.png` (one press at 12 fps from 2.2 s) and `lyric_note_art_full_2.45s.png`.
    - What I see: each crest a braided band crossing the three Shades and the dummy, the crackles and the ring landing on each body as the crest reaches it, the numbers on the beat. The Shades bunch in front of her at this framing.
  - **For research:**
    - The number comes on the server's beat, and a body's touch comes when the crest reaches it: about 5 frames later at 9 studs, about 15 at 14.
    - The rings' hot strength and the dusk check (condition 3) come after the verdict, as scoped.
  - **Four facts:** implemented; tested; visually reviewed by me only, research's pass waits; director-accepted: no.
  - **Hours:** about 3.
- **Research's verdict on the art in the game, 2026-11-12** (the strip, the full view at 2.45 s; round 1 of the art in the game).
  - **Felt:** she plants and the Shades shudder under a rain of 37s. The crests are there, pale braids and thin rings on each body, but they read as wisps, and the numbers are the loudest thing on the screen.
  - **Tier:** works, not yet competent. The art landed (the braid, the ring on the touch), but it doesn't carry the read.
  - **The one bold thing:** nothing carries it yet. It should be the crest's leading ribbon, and today it's the wall of numbers.
  - **Fixes, round 1:**
    1. **One counting number per body** for a flurry, as `docs/ui.md` sets it ("a flurry merges into one counting number"): five touches on three Shades make fifteen numbers a press, and they bury the crest. This is the HUD's rule, built here first, for every flurry. Serves the crest's read.
    2. **The number on the touch:** on the client, a body's number and its touch show when the crest reaches it, not on the server's beat. 5 to 15 frames early is the same break as the Lantern Burst's before its fix. Client only. Serves cause and effect.
    3. **The crest's width** up, live, until the leading ribbon is the brightest edge in the cone: research tunes it in the replay (`Effects.HeldNote.Width`) once 1 and 2 are in. No redraw. Serves the beat inside the wall.
  - **Accepted:** the flash (condition 3 met at 0.32%); the ring on the touch; Ease 2.
  - **Not judged here:** the noon pad's pale ground eats a pale crest. The dusk check comes with Lantern Row's look (AR5), and the Frame 150 take shows her from the player's side.
- **Builder, 2026-11-12: fixes 1 and 2 in the game, and the take** (Faber). Made on Opus 5.5.
  - **Implemented:**
    - **Fix 1, one counting number per body** (`Effects.Number`, `FighterController`'s `onHit` and `onHeal`): a flurry is one press of one fighter's action on one body, for every action. Its window is the number's own life: it joins while the number still shows, so up to `Seconds` (0.8) after the press's last hit. Its first hit's number rises as before. Each later hit adds to it: the number counts up to the new total over `Combat.Numbers.Count` (0.12 s), swells `Pop` times (1.3) and settles, and its fade starts over from that hit. Heals merge the same way (`+`), and a Miss is one word that pops again. Both numbers are live by `Tune`.
    - **My call (tier 1):** a critical inside a flurry turns its number gold and 1.35 times larger from that hit on, so the body keeps one number. The other way is the critical as its own number beside the count. Say if you want that.
    - **Fix 2, the number on the touch** (`Effects.Running.Struck`, `FighterController`'s `show` and `onHit`): when the crest draws the hit, the body's number, hold and push all wait for the frame the crest reaches it. The hold and push weren't named in the fix. I moved them because they broke the same way, 5 to 15 frames early. A Miss waits for the crest too, without the touch. A hit asked about after its touch lands at once. If she's knocked down mid-hold, what still waits lands then, so no number is lost. Client only, and the server's beat and numbers are unchanged.
  - **Tested:**
    - Type check: 0 new. Logic: 1589.
    - New case: "a flurry is one counting number on each body" (14 checks: it counts to the whole, swells and settles, fades from the last hit, another press is its own number, a critical turns it gold, a Miss is one word).
    - The Held Note's look case now also checks that both askings land on the touch's frame and not the beat's, that one asked after the touch lands at once, and that a cut-short note lands what waits.
    - In the replay with Lyric, the whole-fight case also checks one number a body for the press (2 bodies, never more than 1 at once), each counted to its hits' whole, each arriving with its touch, and her heals as one number to their whole. All passed (70/70 across the two cases).
    - The whole Fight suite, with Pip leading: 295/295 at 60 fps.
    - TR3 asks for the merge as a logic case. The rule is client-side here, tested by the self-test, and it moves into pure Luau with TR3.
  - **The take for your read:** `build/captures/ar4/lyric_note_count_take.mkv` (12 s at 57.9 fps, lossless; four presses every 3 s, at about 0.3, 3.3, 6.3 and 9.3 s).
    - It's the replay from the player's camera, with three level-8 Brawlers standing in her cone 8 to 13 studs out, and the dummy. Level 8, so they survive the four presses: Lyric is level 3 now, and level-1 Brawlers burst on the first press.
    - Only for the take, they were spawned on their spots with `Combat.Shade.Notice` 0, `WalkSpeed` 0 and `GiveUp` 1000, then put back.
    - Also: `lyric_note_count_strip.jpg` (the second press at 12 fps from 3.5 s), and `lyric_note_count_4.25s.png` and `4.75s.png` (crops of the bodies: 122 and 138 counting to 203 and 230).
    - What I see: four numbers a press where there were twenty, each counting up as its crest lands. As in round 1, the Shades bunch in front of her at this framing.
  - **For research:**
    - Two bodies standing close still overlap their numbers (the 4.75 s crop: two 203s). Each number keeps the random sideways spread it had before. Not in fix 1. If you want it, the lever is a number placed clear of a neighbour's.
    - A heal's ring and number on an ally in her cone still come on the server's beat, not when the crest reaches the ally (the Heal event carries no beat). Only her own heal shows in the replay. Say if fix 2 should cover allies.
    - Fix 3, the crest's width, is yours in the replay: `NL_Debug:Invoke("Tune", "Effects.HeldNote.Width", 1.5)`. Lyric leads by `Invoke("Act", nil, "SetLead", { Voidkin = "k4" })`, and Pip's `k3` is back as the lead now.
  - **Four facts:** implemented; tested; visually reviewed by me only, research's pass waits; director-accepted: no.
  - **Hours:** about 2.5.
- **Research's read of fixes 1 and 2, 2026-11-12** (the strip, the crops at 4.25 and 4.75 s).
  - **Accepted, both.** Four numbers a press where there were twenty, each counting up as its crest lands. Moving the hold and the push with the number is right: one moment, one frame.
  - **A critical turns the count gold:** accepted. One body, one number.
  - **Close bodies' numbers overlapping:** yes, a number is placed clear of its neighbour's. It goes in TR3's damage numbers, where the rule lives for every flurry.
  - **An ally's heal on the touch:** yes, the same rule, in TR3 with the numbers. A heal carries its beat as a hit does.
  - **Fix 3, the width:** the crests still barely show at 1 in this strip. Research's session predates its play tools, so it asks the builder for one take, after TR2's phone fixes: three presses at widths 1.5, 2 and 2.5, the same staging, and a strip of each. Research picks from it.
  - **Held Note** stays at works until the width is picked. That's the last of its round 1.
- **Builder, 2026-11-12: the width ladder, for research's pick** (Faber). One take, three presses: `Effects.HeldNote.Width` 1.5, 2 and 2.5, tuned live between presses.
  - **Files:** `build/captures/ar4/lyric_width_ladder_take.mkv` (12 s, lossless; the presses at about 1.6, 4.6 and 7.6 s).
    - One strip a press: `lyric_width_1.5_strip.jpg`, `lyric_width_2_strip.jpg`, `lyric_width_2.5_strip.jpg` (12 fps, from 0.2 s after the press, as the count take's strip).
    - `lyric_width_ladder_side.png`: the three side by side, each 1 s after its press, cropped to the bodies.
  - **Staging:** as the count take. Lyric leads in the replay, every 3 s, with the dummy and three level-8 Brawlers spawned on her line at 5.1, 7.6 and 10.0 studs. `Notice` 0, `WalkSpeed` 0 and `GiveUp` 1000 only for the take, all put back after, and Pip leads again.
  - **Two things to weigh:**
    - The hits' pushes carry the Brawlers about 1.8 studs outward over the take (6.9, 9.3 and 11.8 at its end), so the third press's bodies stand a little apart from the first's. Compare the crests' spread, not the bodies' places.
    - The take runs at 57.3 fps, or 58.7 without one 267 ms step at 0.05 s, before the first press.
  - **What I see:** at 1.5 the rings hug the bodies. At 2 they span the pair. At 2.5 the crest reaches past the bodies on both sides.
  - **Four facts:** taken. Research's pick waits, and Config stays at 1 until it.

## AR5. The festival kit and the base's machines

For Modulo, after AR4. One kit of stalls, lanterns, banners and gates that six grounds recolour; the Void Breaker with its chambers; a bay. The kit's full list is written when the direction below is picked. Research's request, 2026-11-12, started early: Modulo's AR4 deliveries are in, and the direction is taste work for Fable's last hours.

**Status:** section 1's round 2 sheet delivered, for research's verdict and the director's pick (Modulo, 2026-11-12).

### 1. Lantern Row's look: the direction sheet

**Feel line, proposed for Modulo to answer:** you step through the festival gate at dusk and the street opens ahead, lanterns strung overhead glowing cyan and warm white under a painted sky, and your Voidkin and the Shades stand out against the stalls like a frame from an anime's festival night.

**The director's word, 2026-11-12:** "i hope it looks a bit anime like". The levers research named to the director, for you to weigh, not a spec: a painted dusk gradient sky with the lanterns blooming against it; bold clean shapes in flat painted colour with the shading baked in, as on Rook; dark outlines on the big shapes, modelled in, since the engine draws none; life in the air (paper, banners, light); signs in an invented script of our own.

**Delivers:** one sheet, before any kit is modelled. Explore fast: rough blocks, no finish.

- Three directions, A, B and C, each as one frame of Lantern Row (`docs/design.md`, "The world, in grey": 44 studs between the stall fronts) from the player's camera, as the game sets it (`Config.Combat.Replay`): Rook fighting two Shades in the middle distance.
- The same frame of each at phone size, and over its darkest and brightest corner. The fighters must stay the brightest, clearest things in it, by value and edge.
- Each direction is made only from what the engine can draw: a sky of our own picture, Lighting and Atmosphere and bloom, flat-colour maps, outlines as geometry. Note each one's cost for a phone, roughly in parts and triangles.
- Your pick among the three, and what you see wrong in each.

**Checks:** the content check on the sheet; research's verdict (the blockout checkpoint), then the director's eye. **Time it:** hours, here.

**Modulo's sheet, 2026-11-12:** `build/handoff/LanternRow/lantern_row_look.png`, made by `tools/blender/lantern_row_look.py` (one run a direction, then `sheet`). The staging and the camera come from Config: the struck Shade 9 studs ahead of the avatar and Lead.Side to its right, Rook beyond it at Lead.Frame, the second Shade one Slots.Spacing round him, the camera at 12.5 studs, 20° down, FOV 70. The fighters wear their delivered maps and play their own clips (Rook at Haymaker's Shock, Hit, Attack's wind-up). The avatar is a grey stand-in. Eevee renders in linear light, then one bloom and one tone curve of mine are applied the same to all three. Those two are an approximation of Roblox's, not a measurement. The sky is a shader here; in the game it's six painted faces.

- **A, Painted dusk.** A low gold sun behind the player, a pink band under a violet sky ahead, warm wood, a low skyline. Wrong: the middle values are murky, the street is lighter than the fight (Rook 0.26 against 0.39 round him), and the sun only lights the fight from this end of the street. From the other end it's backlit.
- **B, Ink night.** A dark street, cyan lanterns blooming, a soft PointLight carried over each fighter. The only one where the lead is the brightest thing round him (Rook 0.41 against 0.28; 7% of the frame outshines the fighters). Wrong: it reads as a neon city more than a festival (cyan everywhere, too many lit windows); the Shades' coats sit on the paving's value (edge step 0.05, the lowest); the heavy ink is invisible on dark shapes, 659 shells for little.
- **C, Last light.** Golden hour, the sun raking across, long shadows, pastel cel colour. It has the clearest silhouettes (edge step 0.30) and is the most slice-of-life. Wrong: the fighters are the darkest things in it (99% of the frame outshines them), and the game's hits are light, sparks and glow, which a bright street washes out.
- **In all three:** the invented script reads as Latin letters at a distance ("b", "o", "%"), so the real script needs a design of its own. The stalls repeat. The sky is a minor lever from this camera: pitched 20° down, it's a strip at the top. The lantern canopy and the paving are the major ones.
- **My pick: B, with A's warmth.** Night, so the fight and its effects are the brightest things on the street. Warm white lanterns for most, cyan between them, as the feel line has it. Half the lit windows. Warm light pools on the paving under the strings, so the Shades' dark coats stand against lit floor. Ink only on shapes seen against the sky or lit surfaces.
- **Where I disagree with the ask:** "the fighters the brightest" can't hold for the Shades. Their coats are void-dark by design (AR2), so only a near-black street would put them on top. I propose: the lead the brightest thing round it by value, and each Shade clear by edge (dark against lit floor, its mask and its type's glow). Research sets the numbers at its verdict.
- **The feel line, answered:** you step through the festival gate at nightfall and the street runs ahead under a canopy of lanterns, warm white with cyan between, the stalls gone dark in ink, and the fight is the brightest place on it: your Voidkin lit, the Shades' pale masks and dark coats against the lit paving.
- **Phone cost** (the block, within 220 studs of the camera; not measured on a device): 809 to 891 pieces, 48,000 to 53,000 triangles, 48 to 75 PointLights, plus the fighters (Rook 7,236, a Shade 5,412). The lights are the risk, and a device take is the builder's. The levers: a string's eleven lanterns as one MeshPart (about 340 fewer pieces), and one light per string.
- **Content check:** PASS (the sheet, the glyphs, the script). It covers these eight glyphs only: the kit's script gets its own check.
- **The director, 2026-11-12, on the sheet:** "oh wow this is beautifull! good job". It covers the sheet as a whole and picks no direction.
- **Not done:** research's verdict; the director's pick among the three. **Hours:** about 2.5, an estimate.
- **Research's verdict, 2026-11-12** (the sheet; fresh eyes beside it).
  - **Felt:** A is the festival, B is the fight, C is a summer afternoon. Each wins one half of the feel line and loses the other.
  - **Tier:** competent, as a direction sheet. **The one bold thing:** the lantern canopy narrowing down the street to a glow at its end. It points every frame at the fight, and it's in all three.
  - **Fresh eyes** (blind, from the stills): all three competent. It picks A, the only one where the lanterns and the fighters both hold at dusk. B wins the lanterns but its Shades sink into the blue street, and C loses the lanterns.
  - **Research's pick: B's structure in A's hour,** Modulo's merge, held at dusk:
    - B's dark street with the fight the brightest place on it, and A's warm white lanterns with cyan between them.
    - Warm pools on the paving under the strings, so a Shade's dark coat stands on lit floor.
    - The street's end glows with A's pink afterglow under a violet sky. It's blue hour, not night, so the roster's "at dusk" holds and the canopy runs into the glow.
  - **Modulo's disagreement: agreed.** The lead is the brightest thing round it by value, and each Shade clears by edge. The numbers, research's, for round 2: the lead's value at least 1.3 times what's round it; no more than a tenth of the frame brighter than the fighters' top quarter; a Shade's edge step at least 0.15 against the floor behind it (B's 0.05 is the fault fresh eyes saw).
  - **Fixes, round 2:**
    1. One frame of the merge as a blockout.
    2. The same frame from the street's far end, since a low sun or a lit end backlights the fight from there.
    3. One frame with a hit's light in it: Pip's burst or Haymaker's square. Serves "the hits are light".
    4. The script redrawn so that no glyph reads as a Latin letter or a sign at a distance (`b`, `o` and `%` today), with its own check. Serves rule 3 and the street's own voice.
  - **Accepted:** the ink only on shapes against the sky or lit surfaces; the phone levers (a string as one MeshPart, one light per string), with the device take the builder's at install; the sky as a minor lever.
  - **Next:** the director's eye on the three and on the merge's direction, then round 2.
- **Modulo's round 2, 2026-11-12:** `build/handoff/LanternRow/lantern_row_look_round2.png`, by the same script (`M`, `M far`, `M hit`, `glyphs`, then `sheet2`). The merge's three frames, round 1's three beside them for the pick, and the script.
  - **The merge, M.** The sky and the haze turn with the view: pink afterglow under violet toward the street's end, violet-blue back toward the gate. Two warm lanterns to one cyan. One SpotLight a string, straight down, for the pools. Paving a step lighter than B's. Ink on the big shapes only (324 shells against B's 659). One PointLight carried by the lead, 1.8 studs ahead of him toward his target and 5.2 up. The Shades carry none.
  - **Against research's targets** (my measures, on my bloom and tone curve, not Roblox's):

    | Frame | Lead over what's round him (1.3) | A Shade's edge (0.15) | Frame over the lead's top quarter | Frame over the three fighters' (10%) |
    |---|---|---|---|---|
    | From the gate | 1.45 (0.52 against 0.36) | 0.17 | 3% | 33% |
    | From the far end | 1.79 (0.47 against 0.26) | 0.11, short | 2% | 27% |
    | Haymaker's Strike, the square | 1.54 | 0.20 | 3% | 28% |

  - **Where I disagree with the second target as written.** Counted on the three fighters' top quarter, it can't hold with the third. Two of the three are Shades, dark by design. With a light on each Shade it held (6%), and their edge fell to 0.07, since a lit coat sits on the floor's value. With none, the edge holds and the count is 33%. I propose counting it on the lead's top quarter: 3%. Research's call.
  - **What the calibration found, for the builder's light:** a light over the lead and above his hat puts him in the hat's shadow (0.25). A light in front of him on the camera's side lights the Shades' backs to the floor's value (edge 0.02). Between him and his target, under the hat's height, it lights his front and the floor behind the Shades.
  - **Wrong in it:**
    - From this camera the Shades stand between the player and the lead and hide half of him, and half of Haymaker's square. That's the staging (Lead.Frame), not the look.
    - From the far end there's no afterglow. The stalls sink near black, it reads closer to night than to blue hour, and the Shades' edge is short. The lever is a lighter haze back toward the gate, or stronger pools.
    - The pools are a lit lane more than pools. The stalls have no light of their own, and the awnings' red goes brown.
  - **Phone cost** (the block, within 220 studs; not measured on a device): 827 pieces, 48,484 triangles, 14 lights (13 SpotLights and the lead's), against round 1's 48 to 75.
  - **The script: not there yet, after two draws.** Draw 1 was a pressed bowl with two or three wedges; draw 2, on the sheet, is a fan of four or five curled wedges over a small cup, each letter on a diagonal (`lantern_row_script.png`, written by `glyphs`).
    - Content check on the rules (2, 3 and 4): PASS, for this ink on these two grounds. The upload's own files need their own check.
    - On research's ask: BLOCK, both draws. Nothing reads at true 16 or 10 px, or at 128 and 32. In the 16 px tiles blown up five times, draw 2's glyphs 4 to 7 lean toward a letter (an n or pi, an e, an a, an S), none strongly.
    - That's two rounds on one idea, so I stop patching. The options, for research: judge at the size a sign really shows from the player's camera; a running band with no letter-sized cells; or refuse draws on the 16 px raster itself (a closed counter, two parallel runs). A cell of about ten ink pixels finds a letter for some reader.
  - **Content check, the sheet:** PASS. Its one note, not this piece's: a Strength Shade from behind on a dark street is a dark coat with a red mark, worth a glance before a public image stages several.
  - **Not done:** research's verdict; the director's pick among A, B, C and the merge. **Hours:** about 2.5, an estimate.
- **Research's verdict on round 2, 2026-11-12.**
  - **Felt:** the merge is the festival at nightfall. A violet sky goes pink at the street's end, the lanterns run into it warm and cyan, paper rides the air, and the fight stands on lit stone. It's the first frame that looks like the game's advert.
  - **Tier:** competent, close to exceptional in mood. **The one bold thing:** the canopy running into the afterglow, now with the fight lit beneath it.
  - **The second target: Modulo's way, agreed.** It's counted on the lead's top quarter (3%). A Shade reads by its edge and its mask, and the lead by value.
  - **Not fixed on the sheet, for the kit's build:**
    - The far end's edge (0.11): a lighter haze back toward the gate, so it's blue hour from both ends.
    - Pools as pools, not one lit lane.
    - A light of each stall's own, and the awnings' red kept red.
    - The lead's carried light placed as the calibration found: between him and his target, under the hat's height.
  - **The script: research reconsiders its own test.** After two draws the ask was the fault, not the draws. Blown up five times, any ten-pixel ink shape finds a letter for some reader. The test is now the player's: at the sizes a sign shows from the camera, at 32, 16 and 10 px, no glyph reads as a letter or a word. Draw 2 meets it, and draw 2 is the script. The content check on rules 2 to 4 stands (PASS), and the upload's files get their own.
  - **Research's recommendation to the director: the merge.**
- **The director's pick, 2026-11-12: the merge** (asked among A, B, C and the merge). Lantern Row's look is the merge, and the direction is final.

### 2. Lantern Row's kit (research's request, 2026-11-12)

For Modulo, after AR3 section 3. Built in the merge's look, with its four notes from the verdict above. The festival kit that six grounds recolour starts here. Lantern Row is its first use.

**Delivers,** each shown before the next, with the content check:

1. **The kit's pieces,** as meshes and flat-colour maps with the shading baked in, and ink shells only where a shape meets the sky or a lit surface:
   - two stalls and a corner stall, each with its awning and its own light;
   - the lantern string as one mesh, warm and cyan;
   - a banner on a pole, and a sign board carrying the script (draw 2);
   - the festival gate and the keeper's gate;
   - the elite's square, its floor and its edge;
   - the paving;
   - drifting paper, as a particle's picture.
2. **The sky:** the merge's afterglow as a sky picture of our own, with the haze and Lighting it needs written as numbers for the builder's Config.
3. **The layout's dressing:** where each piece stands along `docs/design.md`'s 44-stud street, as a plan the builder places from (Lantern Row dressed is its own TR, after TR3).
4. **A phone budget:** pieces, triangles and lights, as round 2 counted them. Round 2's 14 lights is the ceiling to keep.
5. **Night, the director's word** (2026-11-12: "we should add a night cycle for this festival area as well cause the night looks absolutely gorgeous as well"). Lantern Row turns from the merge's dusk to night and back. Every piece is made to read in both:
   - a night sky picture of our own beside the dusk one;
   - the night's Lighting, haze and bloom as numbers beside the dusk's;
   - one frame of the fight at night from the player's camera, held to the same targets (the lead at least 1.3 times what's round it, a Shade's edge at least 0.15).
   - **The night is B's canopy with the merge's warmth:** warm lanterns stay the most, so it's a festival at night and not a neon city. The pools carry the Shades' edge, which B lacked.

**Checks:** the content check; research's verdict from the player's camera at the builder's install, from both ends; the director's eye. **Time it:** hours, here.

**Waits, outside this section:** the kit's pieces, the Breaker and the bay, the other five grounds' recolours, the world's install (the builder).

## AR6. Regalia's item art

For Modulo, when phase 3 opens. Every item kind modelled in Blender and rendered to its icon: ten weapons (two per class) and the twelve shared slots, on the kit's rarity frames, Dawn with designs of its own (`docs/design.md`, "Regalia: gear"). Starts from the reference study, `docs/research/gear-icons.md`. Written in full when phase 3 opens.

**Status:** not started.

## Later, by ground

The rest of ground 1 (Kirra, Watt, Patch, Sable), then each ground's Voidkin in `docs/roster.md`'s order. **The machines** (Gantry, Bulwark, Ironhymn, Shiomaru, Aegir) share one custom rig, taller than a player, with its own clip family: the first of them is timed like AR1, because a custom rig is a different cost.
