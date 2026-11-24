# The character art pipeline: premium anime fighters from scripts, inside Roblox

Research subagent, 2026-11-24 (cloud session). For Modulo and the director. Read in MAIN: `docs/roster.md` ("The look"), `docs/briefs/asset-maker.md`, `tools/blender/anime_make.py`, `rook_make_takes.py`, `blcommon.py`, AR11 ("The comparison"), AR59, AR60, and the director's words in `docs/decisions.md` (11-15, 11-17, 11-20, 11-23, 11-24). It builds on `characters-and-worlds.md` (who the cast is) and `vfx-quality.md`; this page is only how a fighter is made.

**Labels:** SOURCED (a page I read), SNIPPET (a search summary only), COMMUNITY, OBSERVED (our repo), MEASURED (computed here), OPINION. **Every number is a seed, tuned by looking on a phone.** Everything is a proposal. Nothing here copies a unit: the make is studied, never a design (rule 3). The genre just showed why: Anime Vanguards reportedly retired unit models in its Update 13 (mid 2026) after copyright complaints, leaving blank squares (SNIPPET, [Gamezebo](https://www.gamezebo.com/walkthroughs/anime-vanguards-update-13-log/)).

## Verdict

1. **What the director rejected on 11-23 was the build, not Rook:** thick built garments, a cube head, slab eyes, faceted hair, an oversized prop. The make since 11-24, 01:19 (painted R6 blocks, a round head, clump hair) is the right family; the director said "you seems to get it now". It stands at research's "competent", and nothing is accepted in the game yet.
2. **The gap to premium is paint and hair craft, not triangles.** Ours is soft airbrush shade plus noise grain, even clumps and thin face lines. Anime is hard two-tone shadow shapes, few big clumps shaded as one mass, and heavy eye lines.
3. **At our camera the lead is 110 to 260 px tall and seen from behind; his head is 27 to 64 px.** The back view, the hair's outline and three values carry a fight. The face is for the card, the reveal and the Voidkin screen.
4. **Roblox has no toon shader, so the look lives in the colour picture.** Highlights aren't ink. An outline is a flipped shell inside the same mesh. Vertex colours don't survive a SurfaceAppearance. 1024 px and under 6k triangles is right for a Common.
5. **A script can measure what it can't judge.** Put number gates before any sheet, and ask the director six left-or-right questions on a phone. One limit is the director's alone: R6 is a 4.1-head body, and the anime the director named are 6.5 to 7.5 heads.

## 1. Where we stand

**The pipeline today (OBSERVED, `tools/blender/anime_make.py`):**
- `Block`: R6's six boxes, 12 triangles each, with a picture drawn on every face by a numpy painter (`Paint`: polygons, strokes, `soft`, `blur`). `Head`: a lathed round head, 476 triangles, with `draw_face` drawing eyes, brows, a nose tick and a mouth from about 12 numbers. `Hair`: three-faced "leaf" clumps on an egg, laid in rows. `Built`: thin ribbons, loops and blades.
- `handoff` packs one 1024 px colour picture, a flat roughness picture and an emissive mask, at 96 texels a stud on the body and 156 on the head. Meshes travel as JSON into Studio's EditableMesh with per-corner normals (`blcommon.export_mesh_json`, `tools/studio/ModelAssembly.luau`), and wear a SurfaceAppearance (`ModelRecipe.luau:148`). Rook: 3,896 triangles, 3,360 of them hair in 68 leaves (AR59).

**What it can do:** repeat exactly; change a face or a palette by a number; hold the rig and clips; draw three takes in an hour; measure sizes and values.

**What it can't do (OPINION, from the code and the sheets' own notes):**
- **It can't see.** The maker reads its own renders, and AI verdicts have passed work the director then rejected (`README.md`, diagnosis 5). AR59's first pick was made "with fresh eyes given no benchmark".
- **Formula tells.** Analytic shapes come out even: clumps in rings, evenly spaced, one line weight. Evenness is what reads as "AI slop", more than a low triangle count.
- **Airbrush shade.** The cloth's shade is blurred gradients (`shade`, `shadow`, `lit`) plus `grain`, "soft clouds of lighter and darker". Research's second look already says "the reference's cloth is still painted harder than ours".
- **Nothing is baked.** No ambient occlusion and no cast shade from hair onto brow: every shadow is placed by hand. The Cycles bake exists in `blcommon.bake_pbr` and the new make doesn't use it.
- **One face family.** Twelve numbers on one template drift to the same face. The roster says "no two Voidkin share a face".
- **A guessed camera.** `rook_sheet.py:566`: `GAME = (28, 18)`, "an assumption until Config holds its numbers". Config holds them now (`Config/World.luau:48`: Back 12.5, Fov 70; `Config/Combat.luau`: Pitch 20, Side 4, Ahead 1.5).

**What the director rejected, in order (OBSERVED, `docs/decisions.md`):**
| Date | Words | What it rejects |
|---|---|---|
| 11-15 | "corny electrician ... bloxburg electrian npc", "need to look like real anime" | a job's costume; a non-anime make |
| 11-20 | "the model we have for the voidkin are horrible ... much better with watt but we need an even much bigger improvement" | every model before the make |
| 11-23 | "DONT MAKE THOSE MODEL WITH THOSE STYLE", "LOOK AT ANIME VANGUARD" | AR59's first make: built garments, cube head, slab faces, faceted hair, a 1.4x gauntlet |
| 11-24 | "the hair need a rework tbh", "do research on how to make good hair" | a cap of flat clumps; then 60 to 74 even spikes |
| 11-24, 01:47 | "it fine if the model has some attachment or ovexageration you seems to get it now" | nothing: the make is on course |
| 11-17; 11-20 | "the portrait has this weird black line behind the model hair"; "i will give batch exemple tomorrow" | a dark edge behind the hair at card size; the examples are "not in the repo" (AR59) |

## 2. What reads at our scale

**Our numbers (MEASURED from Config and the kit).** The lead stands about 15 studs from the camera. At Fov 70 the screen's height covers 21 studs.

| Screen height | px a stud | Figure (5.1 studs) | Head (1.25) | Rook's eye (0.30 x 0.13) | Lash line (0.046) | Mouth line (0.016) |
|---|---|---|---|---|---|---|
| 450 px (our small-phone sheet) | 21 | 110 px | 27 px | 6 x 3 px | 1.0 px | 0.3 px |
| 720 px | 34 | 176 px | 43 px | 10 x 4 px | 1.6 px | 0.5 px |
| 1080 px | 51 | 263 px | 64 px | 15 x 7 px | 2.4 px | 0.8 px |

- **For us:** in a fight the mouth and nose don't exist, and an eye is a 6 px smudge. The player's camera is behind the lead (AR59: "from behind, where the player's camera is"). So **design the back first**, and judge a face only at the card, the reveal and the Voidkin screen.

**Proportions.**
- Chibi is 2 to 3 heads tall, with the eyes low and big, the neck gone and fingers optional (SOURCED, [Clip Studio](https://tips.clip-studio.com/en-us/articles/4863)). A cute figure is 4 to 6 heads, an average anime figure 6 to 7 (SNIPPET, [easydrawingguides](https://easydrawingguides.com/how-to-draw-anime-body-proportions/)).
- **R6 is 4.1 heads tall and 3.2 heads wide (MEASURED: 5.125 studs over a 1.25 head; 4 studs across the arms).** It's the "cute" class with a very wide box. Anime Vanguards' units are the same plain R6 body (OBSERVED in our own study, AR11 and AR59; I found no written source).
- **For us:** on a 4-head body, follow the 4-head rules: big low eyes, big hair, few large details, simplified hands and feet. Fine anatomy, small buckles and thin trims are wasted.

**Silhouette, value, colour.**
- Valve designed each class to be named "even when viewed only in silhouette"; "interior details such as clothing folds are chosen to echo silhouette shapes"; "high frequency detail is omitted where possible"; "muted colors dominating and small areas of saturation"; and "saturation increases at the terminator" (SOURCED, [Mitchell et al., SIGGRAPH 2007](https://www.advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2(Siggraph07%20Course%20Notes).pdf)).
- **For us:** `grain` is high-frequency detail with no design: cut it. Folds should repeat the outline's angles. Shadow tones get more saturated and cooler, never greyer.

**The face.**
- One eye's width between the eyes; lid shape is the personality: upturned sharp angles read aggressive, drooping lids sleepy, round eyes innocent (SOURCED, [Clip Studio](https://tips.clip-studio.com/en-us/articles/2605)).
- Arc System Works used no normal maps, set the shadow shapes by hand, and lit faces to stay bright (SNIPPET, Game Watch on the GDC 2015 talk; the handout returned 503).
- Anime heads get sphere-like normals, edited apart from the body, for "cleaner shadows" (SOURCED, [BNPR](https://bnpr.gitbook.io/bnpr/shaders/toon-shading-nbpr-abnormal-normal-sphering)). Our head is already a lathe, so its normals are clean. The hair's aren't.
- Low-poly artists put the pupil and highlight on their own layer and paint at twice the final size (SOURCED, [80.lv](https://80.lv/articles/the-soul-of-low-poly-characters/)).

**Hair.** Modulo's study in AR59 stands (few broad clumps, three sizes, tiles, one origin; 1.3 to 1.6 heads wide; 0.45 to 0.6 of a head over the crown). Added here:
- Roblox hair is modelled from curves with a simple bevel profile, "the less complex the shape is, the less tris you have", at resolution about 4 (COMMUNITY, [DevForum](https://devforum.roblox.com/t/480098)).
- Arc System Works thins or removes outline on hair and eyelids, and notes that "mesh intersections do not produce contour lines" (SOURCED, [ASW Academy](https://docswell.com/s/ASW_Academy/5LVY67-GG-Toonline-Eng)).
- Cards with alpha are wrong for us: overlapping partial transparency is drawn several times over (SOURCED, [Roblox](https://create.roblox.com/docs/performance-optimization/improve.md)). Solid chunks only.

## 3. Roblox in 2026: limits and tricks

| Topic | What's true | Label |
|---|---|---|
| Triangles | "Individual meshes can not exceed 20,000 triangles." EditableMesh: 60,000 vertices, 20,000 triangles | SOURCED, [specs](https://create.roblox.com/docs/art/modeling/specifications), [EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh.md) |
| Texture size | Up to 4096 px; 4K rendering went live 2026-01-30, streamed down to what a device can hold. Roblox's own budget: 1024 px "maximum" for a humanoid, 256 px for hair. One line on the same page still says 1024: stale. A 1024 px map costs four times a 512 px one; "usually needs at most 512x512" unless large on screen | SOURCED, [texture specs](https://create.roblox.com/docs/art/modeling/texture-specifications.md), [staff post](https://devforum.roblox.com/t/4316229), [performance](https://create.roblox.com/docs/performance-optimization/improve.md) |
| SurfaceAppearance | Worth it for us, for three things: the emissive mask (live on all clients since 2026-02-12, it blooms "exactly like the Neon material"); `Color`, a tint that multiplies the colour map, set by script, and "does not affect performance"; one material for all pieces. Not for PBR: no normal map, no metal | SOURCED, [docs](https://create.roblox.com/docs/art/modeling/surface-appearance.md), [staff post](https://devforum.roblox.com/t/4357705) |
| Low quality levels | The look "depends on the user's device and graphics quality level". No official list of what drops. A matte, colour-only look has nothing to lose | SOURCED (docs); the rest not found |
| Vertex colours | Import from FBX and multiply the part's colour on plain materials. Reported to have "no effect on surface appearance rendering" (2025-10, still open 2026-04, no staff reply) | COMMUNITY, [tutorial](https://devforum.roblox.com/t/3050119), [request](https://devforum.roblox.com/t/3981469) |
| Highlight | One colour, the whole outline only, no inner lines. Outlines reached phones as a client beta on 2024-07-08, on "a separate, heavily optimized system that does not support thickness". The first one costs about 1 ms of GPU. The docs now cap at 255; the 2024 post said 31 | SOURCED, [docs](https://create.roblox.com/docs/reference/engine/classes/Highlight.md); COMMUNITY, [post](https://devforum.roblox.com/t/3059061) |
| Outline by shell | The usual Roblox answer: a copy with flipped normals, a little bigger, dark. It doubles triangles. No custom shaders exist | COMMUNITY, [DevForum](https://devforum.roblox.com/t/3533978) |
| Lighting | `Technology` is replaced by `LightingStyle` (Soft or Realistic) and `PrioritizeLightingQuality`, neither scriptable; fully live 2025-07-23. Soft is "the best option for the classic Roblox look" | SOURCED, [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting.md), [staff post](https://devforum.roblox.com/t/3401512) |
| Draw calls | Pieces batch only when their SurfaceAppearances are identical | SOURCED, the performance page |
| Skinning | At most 4 bones a vertex. Our import already writes bones (`ModelAssembly.luau`, `skin`) | SOURCED, specs; OBSERVED |
| Layered clothing | Needs R15 cages. Irrelevant on R6 | COMMUNITY |

**For us:**
- **Bake all light into the colour picture** and keep roughness at 1. Modulo's choice to paint the hair's colours into the picture is right, for a second reason: the SurfaceAppearance would likely ignore vertex colours anyway. (The kit's comment says the mesh format carries no colour; EditableMesh does have `SetFaceColors`. It isn't worth using.)
- **The outline that costs nothing extra to draw:** put the flipped shell *inside the same mesh*, its UVs on one dark texel of the same picture. Roblox culls back faces, so it shows only past the outline. No second part, no second draw call; triangles double on that piece only. OPINION: untested in our game; the base's kit already uses a shell at 0.11 studs (`docs/decisions.md`, 11-15).
- **Hair shadow on a painted face is a double shadow.** Try `NoShadow` for the hair in `tools/studio/Models/<Name>.json`; the body still casts.
- **`Rook_Roughness.png` is 1024 px of one flat value** (OBSERVED, AR59). A 4 px map does the same. The emissive mask can be 256 px.
- **`SurfaceAppearance.Color` gives a hit flash, a shiny variant or an evolution's colourway with no new texture.** A light grey base tints widest (SNIPPET, the tinting release).
- **Which `LightingStyle` the place uses isn't in the repo** (Lighting isn't in Rojo). The builder reads it once; every take is then judged under it.

## 4. What lifts a script-only maker most

Ranked by jump per hour (OPINION). The Blender names are from its Python API; the manual's pages didn't load today. Bakes, bevels and booleans already run headless in our repo (OBSERVED, `blcommon.py`). Skip: Geometry Nodes (curves and modifiers do the same in fewer lines), hair cards, normal maps, and any downloaded base mesh or generator (rule 2).

1. **Hard cel shapes instead of blur.** In `Paint`: a shadow is a polygon with an edge 1 to 2 texels soft. Three tones a material: base, shadow, one small light. Delete `grain`. No new tool; half a day in the kit.
2. **Bake occlusion once, with every piece in place.** `scene.render.engine = 'CYCLES'`, `bpy.ops.object.bake(type='AO', margin=8)` into the atlas; multiply it at 40 to 60%, tinted toward the shadow hue, then posterise it to two steps so it stays cel. It gives the hair's shade on the brow, the jacket's on the legs, the arm's on the torso, all for free and all correct. Needs `build/locks/blender.lock`.
3. **Hair as one lit mass.** Give every clump the normals of a smooth egg: a `DATA_TRANSFER` modifier (`data_types_loops={'CUSTOM_NORMAL'}`, `loop_mapping='POLYINTERP_NEAREST'`, `mix_factor` 0.6 to 0.8) from the scalp's egg, or `NORMAL_EDIT` (`mode='RADIAL'`). Our JSON already carries per-corner normals into Studio. This is the standard anime fix for "faceted", and it costs no triangles.
4. **Rounder clumps from curves.** `bpy.data.curves.new(type='CURVE')`, a 5 or 6 point lens as `bevel_object`, each point's `radius` for the taper and `tilt` for the twist, `resolution_u` 3 to 4, `use_fill_caps`; then `bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))` and a `WELD`. Or keep the leaf and add `SUBSURF` level 1. Three faces a clump is why it reads as blades.
5. **The outline shell by modifier.** `SOLIDIFY`: `thickness` 0.05, `offset` 1, `use_flip_normals=True`, `use_rim=False`, `material_offset` 1, and `vertex_group` to thin it to nothing at hair tips and eyelids (the ASW rule). Join it into the piece.
6. **Built cloth that drapes.** A low cage, then `SUBSURF` 1, `SHRINKWRAP` (`offset` 0.03 to 0.06) onto the body, `SOLIDIFY` thin, `BEVEL` with `harden_normals`. For collars, cuffs, tails, hoods and scarves only: the director rejected garments built thick.
7. **A parts library, not one template.** Hair in four slots (fringe, sides, back, top), six options each: 1,296 heads. Eyes as six lid shapes. A script rejects any new head whose black outline overlaps an existing fighter's by more than 75%.
8. **Toon-rendered 2D art for where the face is seen.** Portraits and reveal cards are pictures, so Blender can draw them as real anime: Eevee with `ShaderNodeShaderToRGB` into a constant `ColorRamp`, and Freestyle lines (`scene.render.use_freestyle`, a lineset with silhouette, border and crease). The 3D model then only has to match in outline and colour.

## 5. The recipe

### Proportion chart (H = one head = 1.25 studs)

| Part | Heads | Studs | Note |
|---|---|---|---|
| Body, floor to crown; across the arms | 4.1; 3.2 | 5.125; 4.0 | R6, fixed (the director's "A", 11-15) |
| Hair, width | 1.3 to 1.6 | 1.6 to 2.0 | AR59's measure of the reference |
| Hair, over the crown | 0.45 to 0.6 | 0.56 to 0.75 | Rook is under this today (research's note) |
| Hair, back length | one of: nape 0.2, shoulder 0.7, waist 1.7 | | no two launch fighters share a length |
| Eye centre above chin | 0.42 to 0.45 | 0.53 to 0.56 | the kit's 0.53 is right |
| Eye width; gap between the eyes | 0.24 to 0.28; 0.8 to 1 eye width | 0.30 to 0.35; 0.25 to 0.33 | |
| Eye height: wide, almond, narrow | 0.18, 0.14, 0.11 | 0.22, 0.18, 0.14 | Rook's 0.13 with a 0.3 lid is the floor |
| Upper lash line; brow | | 0.06 to 0.08; 0.05 to 0.06 | the lash is 2 px at 720; today 0.046 and 0.042 |
| Weapon length; least thickness | 0.6 to 1.1 of the body | 3 to 5.5; 0.12 | thinner than 0.12 is under 3 px on a small phone |
| A built piece off the body | | 0.04 to 0.10 | one thing may be 1.3 to 1.6 times life (11-24, 01:47) |
| Smallest shape meant to read in a fight | | 0.25 | 5 px at 450, 8 px at 720 |

### Face
1. Pick a lid shape for the personality first: one of six (round, almond, upturned, drooping, half-shut, slit). No two launch fighters share one.
2. Build each eye from six flat layers, no blur: off-white, a lid shadow across the top third, the iris in two tones (dark top, light bottom), a pupil, one large highlight (at least 0.05 studs, the same side in both eyes) and one small. The upper lash is the heaviest line on the whole fighter. The iris is his second colour signature: saturated, repeating the accent.
3. Skin gets two shadows only: under the fringe, and under the chin onto the neck. Hard-edged. No cheek gradient, no nose shadow.
4. Mouth and nose are for the card; draw them thin. For a fight, the brows may touch the fringe's shadow, so eyes and brows make one dark band. Draw the head's picture at 512 texels a stud and shrink it, as low-poly artists do.

### Hair
1. **Black outline first.** Ten outlines at 64 px, back and front. Pick the one a stranger could draw from memory: 3 to 5 points that break the head's circle, one of them clearly the longest, the two sides different. Block them in minutes with `SKIN` (a radius per vertex) plus `SUBSURF`, or metaballs and a voxel `REMESH`; a rough mesh "is read as the style" (AR59), so these never leave the maker.
2. **20 to 30 clumps, not 60 to 90,** in three sizes: 5 to 7 big ones (0.35 to 0.5 H wide) that make the outline, 8 to 14 middling (0.2 to 0.3 H), at most 8 strays. The big ones carry 70% of the outline. Each has a lens cross-section of 5 or 6 points and the egg's normals (section 4, items 3 and 4).
3. **Paint three tones, hard-edged:** the base; a shadow under each overlap and at the roots (value x 0.7, cooler); one band of light as a broken zigzag at 60 to 70% of the head's height, 0.1 H wide. Tips may take the accent.
4. **The back is the main view:** a tail, a nape cut, a streak, something that's his alone from behind. Budget: 2,500 to 4,000 triangles, as much again if it wears a shell.

### Costume
1. **Three values on the back view,** each at least 15% of its area, neighbours at least 20 points of lightness apart (AR59's must-fix 1, now a gate). Hair, top and legs are three different values. **One accent,** 5 to 10% of the area, the element's colour, seen from behind too.
2. **At most four colour areas** on the back. A break at the waist (a hem, a sash, a belt line) so the torso and leg boxes don't fuse. An open front showing an inner layer.
3. **One asymmetry and one thing that hangs or trails** (a scarf, sash ends, tails, a slung weapon). The trailing piece is what moves, so it earns bones first.
4. **Folds:** 3 to 6 a face, as hard shadow shapes pulled from the shoulder, armpit, elbow and waist, their angles echoing the outline. Never muscles (AR59's must-fix 4).
5. **Hands and feet are paint.** The last 0.4 studs of an arm is the hand: a value break at the wrist, finger lines on the end face. The last 0.4 of a leg is the shoe: a sole line 0.06 thick in a lighter value, a toe cap on the front.
6. **Fight the box with paint:** the outer 0.15 studs of the torso's front and back in the shadow tone, so the waist reads narrower than the block.

### Colour
- **Five colours a fighter:** skin, hair, cloth main, cloth second, accent. Every shadow tone is derived: hue 10 to 20 degrees toward blue-violet, value x 0.70 to 0.75, saturation x 1.1 to 1.2. Never a grey or black multiply.
- **Saturation:** big areas at 0.55 or less (HSV), skin 0.25 to 0.40, the accent 0.75 to 0.95. Nothing pure black or pure white: ink stays near `#1B161A`, so a line still shows on dark cloth.
- **Against the ground:** Shades are dark bodies on a night street, so every fighter carries one mass of at least 30% of its back at mid or light value.
- **Across the cast:** hair and main cloth together sit at least 30 degrees of hue from every other launch fighter. Type colours stay in the UI (`characters-and-worlds.md`, rule 4).

### Shading and outline for Roblox
1. Everything in the colour map. Roughness 1, no metal, no normal map.
2. Layers, bottom to top: flat colours; hard cel shadows; baked occlusion at 40 to 60%, two steps; one ramp down the body (12 to 18% darker at the feet); a thin light on each block's top edge (0.05 studs, 10 to 15% lighter), Valve's rim in place of a dark line; ink lines last.
3. Ink in two weights: 0.03 studs for inner lines, 0.05 to 0.06 where cloth overlaps cloth. Tinted by what it sits on (dark blue on blue cloth), not black everywhere.
4. Outline, to test in three states: none; a soft dark border painted on the blocks' edges; a shell of 0.05 studs on hair, head and built pieces only, coloured like the hair's shadow, fading to nothing at the tips. Mind the director's "weird black line behind the model hair": judge it at the card's size.
5. No Highlight as ink: keep it for marking a target. Emissive only on the element's accent.

### Budget (seeds)

| | Common, Uncommon | Rare | Epic | Legendary, Mythical |
|---|---|---|---|---|
| Triangles, shell included | 6,000 | 9,000 | 12,000 | 16,000; no one mesh over 20,000 |
| Colour map | 1024 | 1024 | 1024, or 2048 if the Voidkin screen is soft | 2048 |
| Roughness; emissive | 4 px flat; 256 | same | same | 4 px; 512 |
| Bones for pieces that trail | 0 to 2 | 2 to 4 | 4 to 6 | 6 to 10 |

- At 1080 px a fight shows 51 px a stud against our 96 texels: sharp. If the Voidkin screen shows a fighter over about 500 px tall, the body passes 96 px a stud and softens. The builder measures that once; it decides 1024 or 2048 (MEASURED for the fight; the screen's framing I didn't read).

### The review checklist: pass or fail, from the player's camera, on a phone

1. Filled black at 64 px, from behind: can a stranger name which fighter it is among the launch five?
2. Does the black outline overlap every other fighter's by less than 75%?
3. From behind at 450 px: three values, each over 15% of the area?
4. Is there one accent, 5 to 10%, and is it visible from behind?
5. Beside a Shade at night: does he separate at a glance, without his name?
6. Does the hair break the head's circle in 3 to 5 places, and stand 0.45 H or more over the crown?
7. Are there 30 clumps or fewer, in three clear sizes, with no two neighbours the same?
8. Is every shadow edge hard, with no blur wider than 2 texels and no grain?
9. At the card's size: do the eyes read as eyes, with a highlight, and is the lash the heaviest line?
10. Is his lid shape used by no other launch fighter?
11. Does the weapon or fist read in a fight (0.12 studs thick or more, a value apart from what's behind it)?
12. Does something trail or swing when he moves?
13. Between two reference units at the same height, unlabelled: does fresh eyes fail to pick ours out as the odd one?
14. Could one line say who he is without naming a job or a published character (the Fighters test)?
15. On the director's phone, in the game, in motion: does the director say yes? Nothing before this counts as accepted. (Items 1 to 12 are numbers a script prints before any sheet leaves; 13 to 15 need eyes.)

### The five commonest reasons a low-poly anime model looks cheap

| # | Reason | Fix |
|---|---|---|
| 1 | **Evenness:** same-size clumps, even spacing, mirror symmetry, one line weight | big, middling, small at about 60, 30, 10; one asymmetry; two line weights |
| 2 | **Airbrush and noise:** soft gradients and grain in place of designed shadow shapes | hard two-tone cel shapes, baked occlusion in two steps, no grain |
| 3 | **A timid face:** eyes at lifelike size, thin lines, shading across the face | big low eyes, a heavy lash, flat skin with two shadows |
| 4 | **Value mush:** all mid or all dark, saturation everywhere | three value groups, saturation kept for the accent |
| 5 | **Hair as spikes or facets,** each lit on its own | few big tiled clumps, the egg's normals, one drawn band of light |

## 6. What a person's eye must still decide, and how to ask cheaply

- **The examples promised on 11-20.** Ask for six screenshots from any Roblox anime game, taken in play: three units they'd be proud to own, three they find corny, one word each. Internal only, never uploaded (rule 3). Two minutes.
- **Six left-or-right pairs on their phone,** one picture each, the same fighter: outline none or shell; cel or soft shade; eyes at 0.14 or 0.20; hair at 0.45 or 0.7 over the crown; muted or vivid; plain or lightly bevelled blocks. Each answer becomes a default in the kit.
- **A "never" list built from the director's rejections,** kept at the top of `anime_make.py`: job costumes, thick built garments, cube heads, slab eyes, faceted hair, oversized props.
- **Acceptance happens in the game, moving, on the phone.** A sheet can only fail a fighter, never pass one.
- **The one call that's the director's alone (their yes needed; it reopens "A" of 11-15):** R6 caps us at Anime Vanguards' look, a 4-head toy figure. If "real anime" (11-15) is meant literally for the top rarities, and the Voidkin screen is to show each one "like ammorpg character" (11-14, said of that screen only), the answer is a taller custom body for Legendary and Mythical, as the machines already have. OPINION: keep R6 for the launch five, and decide this before the first Legendary.

## Top 5 to act on

| # | What | Who | Cost | Director's yes? |
|---|---|---|---|---|
| 1 | **Cel paint in the kit:** hard shadow shapes, derived shadow colours, baked occlusion, no `grain`; lash and brow weights from the chart. Redraw Rook's picture with it as the proof | Modulo | half a day; one Cycles bake | no; their look at the result |
| 2 | **Hair by the recipe:** 20 to 30 clumps in three sizes, a lens section, the egg's normals, a drawn band of light, 0.45 H or more over the crown | Modulo | 3 to 4 hours | no; it's the note the director already gave |
| 3 | **Number gates and the real camera:** a script prints checklist items 1 to 12; the sheet's camera comes from Config (Back 12.5, Fov 70, Pitch 20) | Modulo | 2 to 3 hours | no |
| 4 | **One hour of Studio tests:** the shell inside the hair's mesh at 0.035, 0.05 and 0.07; hair with `NoShadow`; which `LightingStyle` the place uses; a 4 px roughness map; `SurfaceAppearance.Color` as the hit flash; the Voidkin screen's size in px | the builder | 1 hour, private, nothing published | no |
| 5 | **The director's two minutes:** six screenshots and six left-or-right pairs, then the taller-body question before the first Legendary | the director; research asks | 2 to 5 minutes | the body question, yes |

**Held for after these:** toon-rendered portraits and reveal art (section 4, item 8), a tier 2 look for research and the director. **Couldn't fetch:** the Guilty Gear Xrd GDC handout (503; its facts here are a search summary), Valve's Dota 2 character art guide (the page needs scripts), Blender's manual pages (truncated), any official list of what a SurfaceAppearance drops at low quality, and any written account of how Anime Vanguards builds a unit. **Not tested:** anything in Studio or Blender; every px figure assumes the lead 15 studs from the camera.
