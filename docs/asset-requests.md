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

## AR2. The Shade, one rig for every enemy

For Modulo, after AR1's sheet is approved (it can run beside AR1's model).

**Feel line:** a festival-goer the Void has filled, wrong in the way a costume is wrong when nobody's inside it, and readable at a glance by its mask.

**Delivers:** a sheet with the body, the glowing outline in the five type colours, and the four masks (`docs/roster.md`, "Enemies"); then the model on one rig; then its clips: idle, walk, a basic attack, the Guard's raise, the Dasher's line and lunge, hit taken, and the burst into light and paper when it falls. No wounds, no blood, nothing left behind (`AGENTS.md`, rule 4).

**Checks:** as AR1. **Status:** open.

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
