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

**Status:** in progress (Modulo, 2026-11-12). Deliveries 1 to 3, the sheet, the model and the clips, are delivered to `build/handoff/Rook/`. Delivery 4, Haymaker's look, is next, with the builder.

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

## AR2. The Shade, one rig for every enemy

For Modulo, after AR1's sheet is approved (it can run beside AR1's model).

**Feel line:** a festival-goer the Void has filled, wrong in the way a costume is wrong when nobody's inside it, and readable at a glance by its mask.

**Delivers:** a sheet with the body, the glowing outline in the five type colours, and the four masks (`docs/roster.md`, "Enemies"); then the model on one rig; then its clips: idle, walk, a basic attack, the Guard's raise, the Dasher's line and lunge, hit taken, and the burst into light and paper when it falls. No wounds, no blood, nothing left behind (`AGENTS.md`, rule 4).

**Checks:** as AR1. **Status:** in progress (Modulo, 2026-11-12). Delivery 1, the sheet, is delivered to `build/handoff/Shade/`. Delivery 2, the model, and delivery 3, the nine clips, are delivered to `build/handoff/Shade/` past the content check and research's reads. The colour map and the glow mask are rebaked for how Roblox draws a glow, and the clips carry the game's names and fades (section 4): uploaded and in the game, past the engine look (section 6). The elite's second mask is placed, in the recipe, and past the content check for the Brawler (section 5): installed, and in the engine its tie stands out of the sleeve, so it's back with Modulo (section 6). Open: the burst's light and paper, an effect built with the builder.

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

## AR3. The UI kit

For Modulo, from `docs/ui.md`. After AR1's sheet, so the kit is designed against a real Voidkin's portrait.

**Feel line:** a panel that looks cut from a shard and a bar that fills like light through a conduit: the interface of a game that costs money, quiet until something happens.

**Delivers:** a direction sheet first (the lead's card, a rarity frame for each of the six launch rarities, a pill, a button in all its states, a panel, the damage numbers, in Graphite Dark and Pearl Light, at phone size); research's verdict and the director's eye on that sheet; then the kit as sliced images with their insets, and the five type gems, five class icons and four element marks.

**Checks:** the content check; legible at phone size over a bright and a dark world; research's verdict.

**Status:** the direction sheet is past the content check and research's verdict, its three fixes drawn and passed (section 1), and delivered to `build/handoff/UI/ui_sheet.png`. The director's eye, 2026-11-12: Graphite Dark is the main theme; Pearl Light stays for some screens, drawn with a black border (`docs/decisions.md`, the director's words). The kit's images start from the sheet, Graphite first. The director, on the same sheet: some screens get a palette of their own on the same kit, and Mythical's light is reddish, not the split rainbow; its broken crown stays. The glance strip is drawn again with the red Mythical, beside the failed button and the Strength gem, at 1 pt over both themes. That round is drawn, past the content check and research's read (section 1, "The director's words, drawn on the sheet"), and delivered to `build/handoff/UI/ui_sheet.png`, with its foot at true size in `ui_glance.png`. The kit's images are made, past the content check, and delivered to `build/handoff/UI/kit/` (section 2). Research's verdict on them: competent, the frames exceptional, the four palettes accepted; its five fixes are drawn and past the content check (section 2, "The fix round"), so the kit is ready for the builder. Nothing is uploaded or in the engine. The director, 2026-11-12, to Modulo: which screens are Pearl and which get their own palette is Modulo's to choose (section 2).

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


## AR4. Pip and Lyric

For Modulo, after AR1 closes. The ranged family and the first element (Pip); a heal and a complex signature (Lyric). Same four deliveries, timed. With AR1 they give the cost of a simple, a middling and a complex Voidkin, and with Rook's evolution they're the package's gate C: three finished exemplars and one evolved.

**Status:** started (Modulo, 2026-11-12), while AR1's delivery 4 waits on the builder and AR3 on its verdicts. Pip's sheet is past the content check and research's two reads (section 1) and delivered to `build/handoff/Pip/pip_sheet.png`. His model is past research's read and the content check (section 2) and delivered beside it, not yet in the engine. His eight clips are accepted by research after its one fix round, past the content check on both rounds (section 3), and **delivered** to `build/handoff/Pip/clips/`, not yet in the engine. Lyric's sheet is delivered to `build/handoff/Lyric/lyric_sheet.png`, past the content check and research's read, the feel line signed, the signature Held Note (section 4). Her model is read by research (competent, its three fixes landed), its two fixes for the next bake are made and past the content check, and it's **delivered** beside the sheet (section 5), made on Opus 5.5 xhigh: the fixes not yet read, the model not in the engine. Her clips are next.

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

## AR5. The festival kit and the base's machines

For Modulo, after AR4. One kit of stalls, lanterns, banners and gates that six grounds recolour; the Void Breaker with its chambers; a bay. Written in full when AR4 closes.

**Status:** not started.

## AR6. Regalia's item art

For Modulo, when phase 3 opens. Every item kind modelled in Blender and rendered to its icon: ten weapons (two per class) and the twelve shared slots, on the kit's rarity frames, Dawn with designs of its own (`docs/design.md`, "Regalia: gear"). Starts from the reference study, `docs/research/gear-icons.md`. Written in full when phase 3 opens.

**Status:** not started.

## Later, by ground

The rest of ground 1 (Kirra, Watt, Patch, Sable), then each ground's Voidkin in `docs/roster.md`'s order. **The machines** (Gantry, Bulwark, Ironhymn, Shiomaru, Aegir) share one custom rig, taller than a player, with its own clip family: the first of them is timed like AR1, because a custom rig is a different cost.
