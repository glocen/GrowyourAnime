# AR2. The Shade, one rig for every enemy

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
  - **The Guard, Dasher and Support** join `Definitions/Enemies` only once every lead's basic attack passes their masks (the content check, 2026-11-17; AR26). Today Watt's crack and Rook's spikes don't: each combo script lists what waits, read from the masks the game uses.
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

