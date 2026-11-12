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
- **The glow:** the mask covers the knuckles, the heat band and the piston's rod. The game lights it on `Rook_RightArm` and `Rook_Piston` with `EmissiveStrength` 0 to 2.5 and `EmissiveTint` #FFA630, through Haymaker's wind-up.
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

## AR2. The Shade, one rig for every enemy

For Modulo, after AR1's sheet is approved (it can run beside AR1's model).

**Feel line:** a festival-goer the Void has filled, wrong in the way a costume is wrong when nobody's inside it, and readable at a glance by its mask.

**Delivers:** a sheet with the body, the glowing outline in the five type colours, and the four masks (`docs/roster.md`, "Enemies"); then the model on one rig; then its clips: idle, walk, a basic attack, the Guard's raise, the Dasher's line and lunge, hit taken, and the burst into light and paper when it falls. No wounds, no blood, nothing left behind (`AGENTS.md`, rule 4).

**Checks:** as AR1. **Status:** in progress (Modulo, 2026-11-12). Delivery 1, the sheet, is delivered to `build/handoff/Shade/`. Delivery 2, the model, and delivery 3, the nine clips, are delivered to `build/handoff/Shade/` past the content check and research's reads. Open: the burst's light and paper, an effect built with the builder; the elite's second mask.

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
- **Not done:** the burst's light and paper (an effect, with the builder, with its own content check); the elite's second mask. Nothing is uploaded or seen in the engine.
- **Hours:** the clips, 1.2, the two rounds and the checks' fixes included.

## AR3. The UI kit

For Modulo, from `docs/ui.md`. After AR1's sheet, so the kit is designed against a real Voidkin's portrait.

**Feel line:** a panel that looks cut from a shard and a bar that fills like light through a conduit: the interface of a game that costs money, quiet until something happens.

**Delivers:** a direction sheet first (the lead's card, a rarity frame for each of the six launch rarities, a pill, a button in all its states, a panel, the damage numbers, in Graphite Dark and Pearl Light, at phone size); research's verdict and the director's eye on that sheet; then the kit as sliced images with their insets, and the five type gems, five class icons and four element marks.

**Checks:** the content check; legible at phone size over a bright and a dark world; research's verdict.

**Status:** open.

## AR4. Pip and Lyric

For Modulo, after AR1 closes. The ranged family and the first element (Pip); a heal and a complex signature (Lyric). Same four deliveries, timed. With AR1 they give the cost of a simple, a middling and a complex Voidkin, and with Rook's evolution they're the package's gate C: three finished exemplars and one evolved.

**Status:** open.

## AR5. The festival kit and the base's machines

For Modulo, after AR4. One kit of stalls, lanterns, banners and gates that six grounds recolour; the Void Breaker with its chambers; a bay. Written in full when AR4 closes.

**Status:** not started.

## Later, by ground

The rest of ground 1 (Kirra, Watt, Patch, Sable), then each ground's Voidkin in `docs/roster.md`'s order. **The machines** (Gantry, Bulwark, Ironhymn, Shiomaru, Aegir) share one custom rig, taller than a player, with its own clip family: the first of them is timed like AR1, because a custom rig is a different cost.
