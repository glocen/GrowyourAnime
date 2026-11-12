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

**Checks:** as AR1. **Status:** in progress (Modulo, 2026-11-12). Delivery 1, the sheet, is delivered to `build/handoff/Shade/`. Delivery 2, the model, is next, carrying research's two fixes.

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
