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

**Status:** in progress (Modulo, 2026-11-12). Delivery 1 is delivered. Delivery 2, the model, is made and passed the content check; it waits on research's read. Delivery 3, the clips, is started.

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

- **Where:** `build/scratch/modulo/rook/model/`, and in `build/handoff/Rook/` once research has read it: eight `Rook_<Piece>.json` meshes, four maps, `Rook.recipe.json`, and the review sheet `rook_model_sheet.png`. `tools/blender/rook_model.py` rebuilds all of it in about 20 seconds (`-- <out>`).
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
- **Research's read:** asked 2026-11-12.
- **Hours:** the model, 0.5.

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
