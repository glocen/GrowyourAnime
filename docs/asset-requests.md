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

**Status:** in progress (Modulo, 2026-11-12). Delivery 1 is drawn and waits on its two checks.

**1. The sheet** (Modulo, 2026-11-12).

- **Where:** `build/scratch/modulo/rook/rook_sheet.png`, and in `build/handoff/Rook/` once it passes. `tools/blender/rook_sheet.py` rebuilds it (`-- <out> sheet`); `-- <out> pack` writes the eight outlines the direction was picked from.
- **The look:** R6's own blocks and round head in a cropped oxblood jacket over a bone wrap. A collar that stands as a wall behind the head. A flat-top with one cut. The left sleeve torn off, the arm taped, two loose ends of tape to move. On the right arm one ram of a gauntlet, 1.9 × 1.8 × 2.2 studs, carried a quarter stud wide of the arm. A battlement in bone across the jacket's back, the side the player's camera sees most.
- **The director, 2026-11-12,** on the sheet's second pass: "i think it should look more R6 and the eye are bit off". It covers Rook's sheet. Done: limbs and torso are the R6 blocks with clothes as thin shells, the head is R6's round one, and the eyes are redrawn level and apart. Only the gauntlet, the collar, the hair and the tape ends stand off the blocks.
- **Tried on the sheet, tier 1:** a piston on the gauntlet's back that draws out through the wind-up while the knuckles light, so the tell is on the weapon itself. For the builder and delivery 4: it wants its own joint.
- **Open for the clip:** R6's arm has no elbow, so the punch travels an arc and lands straight. The key pose winds the body until the back half-shows.
- **Assumed:** the player's camera (behind, 18° up, orthographic views). Config holds no camera numbers yet.
- **Content check, 2026-11-12: PASS** on rules 2, 3 and 4, at full size and in the 64 px rows. To hold on the model and the clips: the collar gets real cloth thickness (its rim shows as a thin line from the player's camera); the plaster, the torn sleeve and the tape ends stay clean and bone, never tapering into drops; the back mark stays a plain battlement; through Haymaker's hold the lead arm stays at or below the shoulder; "Oxblood" stays an internal colour name; the evolution with two gauntlets gets its own check. For research: the check found no "Fighters" test in `docs/decisions.md`, which `AGENTS.md` rule 3 points to, and it left a note on the name Haymaker for the name re-look.
- **Research's verdict:** asked 2026-11-12.
- **Hours:** the sheet, 0.5 so far (the kit's copy and three passes included).

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
