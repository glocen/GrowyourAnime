# Why our hair reads messy and theirs clean

Modulo, 2026-11-24, 21:38, on the director's word on AR64's first spike takes: "those hair are still messy do research". It feeds AR64. The labels:
- **OBSERVED:** seen in an image.
- **DESIGN:** ours, for the takes.

The images stay internal (`build/reference/anime-vanguards/`, `build/scratch/modulo/study/`).

## What was looked at

- **Anime Vanguards:** eight unit renders, their heads cropped at full resolution: `ichiga`, `kinnua`, `genitsu`, `noruto`, `jon`, `shinzi`, `rukio`, `todays-strongest` (`study/hs1.png`, `hs2.png`); `compare_heads.png`.
- **Ours:** today's Rook (AR59's pick) and Kirra (AR60), and the first spike takes (`hair/rook/busts.png`, 21:35).
- **The web:** two searches and one article (80.lv, Kensyouen_Y's anime hair). Nothing measurable. One idea came from the search, from a CG Cookie guide's search summary: big shapes make the silhouette, the clumps sit inside them. The guide's page itself refused the fetch. The answer came from the images.

## What theirs does, and ours didn't (OBSERVED)

1. **The hair comes down over the face.** On seven of the eight units the fringe reaches the brows, or the eyes. The sides cover the head's top corners and come down past the ears. The block of the head never shows above the brow. Ours sat on top of the head like a cap, over a bare forehead, with a hard line across it.
2. **One mass from one crown.** Every lock runs out from one point near the top, back, and turns down the head to its edge. Ours had rows of locks combed different ways, which crossed at the crown.
3. **Locks touch at the root and part only at their ends.** Each lock is wide where it starts and overlaps its neighbours, so the silhouette is one shape with a toothed edge. Ours stood apart, with the dark scalp showing between them: the "artifacts".
4. **Round locks, lit ridge, dark edges.** Each lock is round over its top and smooth-shaded. Its ridge is the light colour, and it falls to a dark edge where it meets the next. That gives clean dark lines between locks, the way an anime drawing does. Ours were thin leaves with grey undersides, or faceted diamonds: noise.
5. **Three sizes, all in the same direction.** A few big locks make the shape, with smaller ones between them. None go against the flow.

## The way, for AR64 (DESIGN)

- Built in `tools/blender/hair_ways.py`, `Solid`.
- The three takes are this way at three degrees:
  - **A, the mass:** the points part only at their ends.
  - **B, spiked:** the ends lifted clear, and the crown standing.
  - **C, sleek:** fewer, broader locks lying close.
- The first spike takes (21:35) are dropped. They kept points 2 to 4 of what was wrong.

## How hair is made for Roblox (2026-11-24, 22:26, on "ur hair is still horrible" and "js study how to make hair on roblox")

From the DevForum's hair tutorials and feedback threads, and the UGC guides (sources below). These are community sources, not Roblox's own; no official hair guide was found.
- **The locks are curves with a profile.** Each lock is a Bezier path with a bevel profile: a circle at resolution 2 or 3, its points moved to a custom shape. Each end is scaled to 0 (Alt+S) for a point. The locks are converted to mesh, joined (Ctrl+J) and decimated. ([DevForum, part 1](https://devforum.roblox.com/t/how-to-make-hair-in-blender/480098), [part 2](https://devforum.roblox.com/t/how-to-make-ugc-hair-in-blender-28-pt-2/612848))
- **The budget:** about 4,000 triangles for UGC hair, and a texture of at most 1024 px. 512 is enough for a stylized look. ([UGC guide](https://generalistprogrammer.com/tutorials/how-to-make-and-sell-ugc-on-roblox), [Roblox docs](https://create.roblox.com/docs/art/characters/creating/texturing-setup))
- **The texture:** a gradient or streaks, with each lock's UV laid the same way, dark at the root and light at the tip, plus a lighter highlight bar. That's what our kit's strips already do.
- **What made hair read badly** ([feedback thread](https://devforum.roblox.com/t/i-made-anime-hair/881090)): "very flat, the colors are drained and it's not nearly fluffy enough". The fixes offered were curved convex forms and lighter, livelier shading.
- **The genre's best:** Anime Vanguards' hair, up close, is neither strips nor curves left apart. It's one sculpted surface: a few big forms flowing into one another, creased where they meet, smooth everywhere else. The pro pipeline is sculpt, then retopology, then bake ([80.lv](https://80.lv/articles/how-to-create-a-refined-and-vivid-fantasy-character-with-natural-curly-hair)).

**Dropped:** the remeshed single surface built from this (take S, 22:26). The director, by 23:00: "it still horrible ur hair is horrendous". It read as fat clay fingers.

## A wider look, and what was measured (2026-11-24, 23:17, on "browse more example")

The director: "u dont have to take inspiration only from those hair browse more example". Looked at, all internal (`build/reference/hair/`, `build/reference/anime-vanguards/`):
- **Roblox's catalog:** the 32 most-favourited hair accessories under six anime searches, their catalog pictures (`catalog/index.tsv`). The boys' "messy" and "fluffy" hairs, 200,000 to 940,000 favourites each, are the ones players pick.
- **Anime Vanguards:** four heads at the renders' own size, doubled (`study/n1.png`, `n2.png`).
- **Sketchfab:** the 48 most-liked models under four hair searches; twelve were worth a look, the rest whole characters or printed figures (`sketchfab/index.tsv`).
- **Four modelling guides,** read for numbers: none gave any. One refused the fetch.

What every good one does (OBSERVED), and ours never did:
1. **One whorl.** Every lock is born at one point on the crown and runs away from it: forward over the forehead, down the sides, down the back. Each turns the same way round it.
2. **Layers, like roof tiles.** A ring at the hem, a ring over it, the crown's over that. Each ring hides the roots of the one below, so only points and overlaps show.
3. **Long locks.** A lock runs most of the head: half a head to a whole head long. Ours were a quarter.
4. **A dome bigger than the head.** 1.4 to 2 heads wide, a third to half a head over it (MEASURED on the pictures). The locks lie on it, and only their last third leaves it, turned out.
5. **The fringe is hair.** It falls from the whorl to the brows or the eyes, broad at the top, parting into points.
6. **A lock is flat.** In Anime Vanguards a blade with a ridge: a broad face, a narrow one, hard edges, twenty to forty-five of them. In the catalog a thin ribbon, sixty to a hundred.
7. **Dark inside.** Under the locks a cap in the hair's shade, so a gap shows shade, never skin.
8. **No two neighbours alike.** Lengths and points vary along a ring, so the edge has a rhythm.

**Our way** (DESIGN, `hair_ways.py`, `Blades`):
- A cap in the hair's shaded colour.
- Three rings of flat wedge blades from one whorl (`ring`, `lay`), each lock lying on the head and turned out over its last half. A fringe of leaves from the whorl's front.
- The broad face light and the narrow one in shade, one hard edge between them, drawn in the picture.
- 2,100 to 3,800 triangles.
- Three grains of one layout: A, B fewer and bigger (Anime Vanguards' end), C finer (the catalog's end).

## How the pros make it (2026-11-24, 23:59, on "do study on how hair is made by pro")

After the fifth modelled round was rejected ("your hair still look bad.") and the design was drawn flat first (AR64, "Designs drawn first"), the director: "do study on how hair is made by pro". Read on the web for the pipeline; most pro write-ups are video, and several pages refused the fetch, so sizes and curve rules have almost no sourced numbers. STATED is what a source says.

1. **Big to small** (STATED). The silhouette's masses first, then the clumps inside them, then a few strands that break away. Start from chunks, never from strands. ([80.lv, sculpting stylized hair](https://80.lv/articles/guide-sculpting-stylized-hair-in-zbrush/), [Wacom, drawing anime hair](https://community.wacom.com/en-us/?p=25953654))
2. **Three stacked layers** (STATED): a base on the scalp that covers the hairline, a middle layer, a top layer that makes the silhouette. The fringe is made apart. ([a character-hair write-up](https://tinakuang.myblog.arts.ac.uk/2024/03/26/3d-character-hair/))
3. **The fringe is three chunks, the middle one the largest; the sides are longer and sharper; the back is the largest** (STATED, Wacom). Every chunk connects back to the whorl.
4. **No two alike** (STATED). Beginners make every strand the same width and length. Vary both, and the gaps between them. Split a chunk's end into points. Too many strands is a mess, too few is clay; repetition, wobble and symmetry are the usual faults. (Wacom; 80.lv; [a DevForum first-hair thread](https://devforum.roblox.com/t/my-first-time-making-hair-on-blender-need-opinions/2022740): fewer and wider, puffed off the head, with highlights)
5. **The section is a triangle or a diamond** (STATED): two numbers a ring. In 37,000 VRoid hairstyles a style has 25 to 130 clumps. ([the VRoid hair paper](https://arxiv.org/html/2509.21114v1))
6. **Lit as one mass** (STATED). Guilty Gear Xrd takes the hair's normals from simple round shapes, so the light doesn't break on every clump. ([4Gamer](https://www.4gamer.net/games/216/G021678/20140703095/), [the Blender way](https://dskjal.com/blender/toon-shading.html))
7. **One ring of light** (STATED): a band at one height round the head, with a small zig-zag, drawn, not computed from the light. ([Unity Toon Shader](https://docs.unity3d.com/Packages/com.unity.toonshader@0.9/manual/AngelRing.html), [a procedural one](https://godotshaders.com/shader/procedural-illustration-esque-hair-highlight-shader/))
8. **Roblox** (STATED): 4,000 triangles at most, one mesh, a cap under the hair made from the head. ([the accessory specifications](https://create.roblox.com/docs/art/accessories/specifications), [DevForum](https://devforum.roblox.com/t/ugc-hair-help/2725562))

**Not found:** root widths, where a clump is widest, how a clump curves, how much clumps overlap.

**Our way now** (DESIGN, `hair_ways.py`, `Locks`, `rook`), replacing the rings of `Blades` for Rook:
- The design is drawn flat and picked first (`tools/art/hair_designs.py`), then modelled lock for lock.
- A lock is a closed leaf, round over its top, smooth all the way round, placed by hand from the whorl.
- Three layers: short points under the hem, the big masses over them (the back's the broadest), the fringe in three chunks on top, the middle one the largest. Two tufts at the whorl.
- Lengths, widths and turns differ from neighbour to neighbour, and the two sides differ.
- The normals are turned part of the way to a ball's, and the picture is lit the same way; one ring of light runs round the dome, dipping to a point on each lock.
- 3,600 triangles.

## What the full-size pictures show (2026-11-25, 00:49, on "still very very bad js learn do study"; paused at the director's word, resumed on "go", 21:2x)

The Shag build and a spiked build after it were both rejected (AR64). The study this time is on eight of the catalog's best-loved boys' hairs at 700 px (`build/reference/hair/catalog720/`, internal), all eight read. Their 3D pictures need a sign-in, so the meshes weren't read: everything below is from pictures.

OBSERVED:
- **A lock is a long thin ribbon,** five to eight times as long as it is wide, near one width for most of its length, then a long needle point. Ours were leaves and cones, two to one.
- **Every ribbon curves,** in a C or an S, and its point flicks up or out. None is straight.
- **Seventy to a hundred of them, in about three layers,** and they cross. They come in clumps that fan from one root, never in rows side by side.
- **The top is one surface.** Round the whorl the hair is broad smooth sheets with fine lines drawn along them; the ribbons only come apart toward the ends. Two tufts arc left and right out of the whorl, with a few thin strays.
- **The light is soft and runs across each ribbon** (lighter down its middle, dark at its edges), on a picture that goes from a dark root to a lighter end. A black cap fills the inside.
- The mass is about 1.5 to 1.7 heads wide and falls over the forehead to the eyes.

OBSERVED on the resumed study, building beside the pictures at one size (each line found by a round that lacked it):
- **A ribbon is folded, not round:** a shallow V across it with a hard crease down the ridge, so one half takes the light and the other falls into shade. A tube or a flat card reads as clay or paper.
- **Broad and overlapping at the root,** so no scalp or cap shows between locks near the head; they only come apart toward the points. A ribbon that starts thin reads as a wet string.
- **Clumps, not combs:** a broad lock with a thinner twin from the same root that parts from it toward the point, and big chunks beside small ones. Locks of one width in a row read as a mop.
- **Every lock from the whorl turns the same way round it,** a swirl. Alternating bows read as tangle.
- **The whorl sits at the back of the crown, and the fringe has its own point at the top of the front:** from the front its locks part outward. Fringe locks laid from the back whorl run parallel down the face, a curtain.
- **The points kick out past shorter under layers;** when every layer ends at one height, the bottom is a hanging fringe of needles all round.
- **A dark cap and dark roots, a soft sheen down each lock's lit half:** the depth is in that range, dark between the locks, light along their ridges.
- **6413085241** is a short side-swept crop of broad flat locks over a black cap; **4875445470**, side on, long ribbons hanging to needle points.

DESIGN, take R (`tools/blender/hair_ways.py`, `Ribbons`, `rook_ribbons`; 43 rounds, 2026-11-25, 21:29, to 2026-11-26, 13:07; the take today is RP, `rook_ribbons(solid=True)`): folded ribbons laid over the head from the back whorl in a swirl, each widest at the crown and drawn steadily to a hard tip; broad top locks, the side ones with thinner twins, longest outside and kicking out; a fringe of four parting from its own point at the top front, one lead lock the biggest; two crescents at the crown; a tapered nape; a darker inner mass held close to the head, dark roots, lit as one mass (each normal 0.85 of the way to a ball round the head) with a dim sheen along each lock. 1.62 heads wide, 0.53 of a head over the head with the crown's tips, 4,284 triangles (over the 4,000 a catalog hair is held to: thinned at the finish). Sheets: `build/handoff/Rook/hair/hair_rook_ribbons.png` (ours only); beside three catalog hairs, `build/reference/hair/compare_rook_r43.png` (internal).

A blind reader (`ga-fresh-eyes`, the catalog as the bar) read rounds 28 and 30: **no, both times.** Its gaps, worst first, and where round 31 stands:
- **The silhouette flares** at the sides and hem like an umbrella; the catalog's is a compact dome held close, a few tips breaking it. Round 31 holds the sides close; not read blind.
- **Too many locks of one width** (round 28: about thirty, "a frayed broom"); the catalog's eight to ten broad ones each read. Round 29's five big ones read as shards; rounds 30 and 31 carry about ten.
- **One layer, nothing crossing:** the catalog lays front locks over a dark inner mass. Round 31 darkens the inner mass; nothing crosses yet.
- **No accent at the crown:** 6823338112's parting with two upturned tips, 14892162637's cowlick and curl, are what make them known in silhouette, at 64 px too. Not done: earlier tries (a V, a tuft) read as horns, so it's drawn first next.
- **Many shines, grey-blue:** a streak per lock reads metallic; the bar is near-black, one soft band. Round 31 lights the mass as one; the lit side still reads grey-blue in our stage's light, where the catalog's band sits on the upper locks.

Rounds 32 to 41 (2026-11-26, 12:00 to 12:36), take R, accent `split` (RS). OBSERVED, each line found by a round that lacked it:
- **The grey was the stage, not the paint.** Darker paint moved the hair's mean from 0.21 to 0.20; the sheen off took it to 0.07. Our sky is one colour all round, the ground too, so a black hair's sheen greys every lock and fills the gaps between them. Measured against the catalog's pictures (mean 0.09 to 0.13 for its black hairs), the stage's sheen on the hair is set to 0.1. That's a calibration, not a measurement: the in-game check is Faber's.
- **The outer locks run longest.** When the side locks ended above the layers under them, the side read as a cap with a brim over a fringe of shards; ended past them, it read as hair.
- **The back runs down to a tapered nape,** longest at the middle. Ended at the head's widest, it read as a bowl cut from the game's camera.
- **The crown's tips are crescents that run out along the dome almost level, then lift.** Rising from the whorl at 35°, two tips read as one fin or as horns. Thin whiskers read as antennae: the catalog's are the full-width ends of the crown's locks.
- **A lock is widest where it leaves the crown and narrows steadily to a hard tip.** Wide to the middle with a late taper, it reads as a spade; wide in the middle, as a petal or a leaf.
- **The fringe parts at its point,** with one lead lock bigger and longer than the rest and dark gaps between the locks. A lock down the middle and a lit layer under the gaps made a curtain that hid the eyes at 64 px.
- **The light runs dim along each lock, one direction for the mass.** A band painted at one height becomes a blob on every lock it crosses.
- **Measured on round 33,** without the accent: the outline at a fifth of its height is 0.71 of its width, inside the catalog's 0.62 to 0.86.
- **Still open,** from the blind read of round 40: the outline flares like a bell at the hem, the edges fray into thin spikes, and a flat shelf juts out at the back's upper left.

Rounds 42 and 43 (2026-11-26, about 13:00 to 13:07), take RP, on the director's "the hair look a bit like pasta". OBSERVED:
- **The noodle was the light.** The ring of light sat at one height, and its shine was laid along a line down each ribbon, so every top lock lying in the ring's height carried a bright stripe down its length: a tube, a noodle. Laid across each lock's whole face, the ring crosses the mass as one band.
- **Loose, thin, curling locks at the sides and back read as strands, not hair.** 22 locks of 0.22 studs and their thin twins, lifted off the head and curling, showed the sky between them. Fewer, wider (0.34 to 0.58), shorter and laid close, they read as one mass at 64 px and from the game's camera (a blind reader, round 42).
- **A soft crease reads rubbery.** With the crease eased, the locks read as plastic leaves; the catalog's have a crisp dark crease where one lies over the next. Round 43 put it back (0.78).
- **Still open,** from the blind read of round 42: close up, the locks are broad petals where the catalog's are many and narrow; a few strays at the back's left edge.

Take T before it (`Sheets`): pleated sheets whose pleats part into points near their ends. Wide petals, nothing crossing, points that don't flick. Dropped.

## Against Anime Vanguards: why ours reads bad, measured (2026-11-26, 13:10 to 14:16)

The director, on round 43: "round 43 is still bad.. study how to make it good instead of iterating", then "now compare with anime vanguard or anime crusader and if u believe yours is bad compared to it keep studying and improve". No round was built for this study; four throwaway tests isolated causes (`build/scratch/modulo/hair/study/`, with `measure.py`). Pictures looked at, all internal: the catalog's eight (`catalog720/`); Anime Vanguards' units `roku`, `gaari`, `ichiga`, `jon`, `sosuke` and `savior-moonless`, heads enlarged (`study/av_heads.png`, `spikes.png`); ours, rounds 41 and 43.

**The measure** (MEASURED). Each hair is scaled to one width and the inside kept. It counts the share of inside pixels on a hard tone step and on a soft slope; their ratio is the hair's crispness. At 160 px wide, AV's renders' own size:

| Hair | hard step % | soft slope % | crispness | tone spread (sd) | brightest 5% |
|---|---|---|---|---|---|
| catalog, six black boys' hairs | 3.5 to 12.7 | 33 to 50 | 0.11 to 0.28 | 0.056 to 0.076 | 0.22 to 0.26 |
| AV, `roku` (black) | 8.9 | 35 | 0.25 | 0.058 | 0.27 |
| AV, `gaari`, `savior-moonless`, `ichiga` (coloured) | 18 to 30 | 30 to 49 | 0.37 to 0.83 | 0.09 to 0.20 | 0.36 to 0.75 |
| ours, round 41 (RS) | 5.8 | 67 | 0.09 | 0.052 | 0.23 |
| ours, round 43 (RP) | 4.6 | 47 | 0.10 | 0.048 | 0.24 |

Ours is the least crisp of all: its tone runs in soft slopes where theirs sits in planes split by hard edges. That is the "pasta", the "rubbery plastic leaves" the blind reader named, and the "still bad".

**What makes ours soft** (TESTED, one change at a time on round 41, measured at 480 px):
- **The paint.** Our picture shades across each lock: a lit ridge, an eased dark edge, a ring of shine. Painted flat across and graded only along, the soft slopes fall from 36% to 10%, and the tubes go.
- **Not the normals.** Each lock lit by its own faces instead of a ball's: no measurable change, with the paint as it is or flat (0.4% hard, 35% soft either way). On a near-black colour the light moves the tone too little to show.
- **Flat paint alone is dull.** The spread falls to 0.024, a third of theirs, and a tone of its own on each lock doesn't lift it: the colour is too dark for the light to draw planes on.

**What Anime Vanguards does** (OBSERVED, the enlarged heads):
1. **A lock is a solid spike, not a ribbon:** a blade or a pyramid with volume, its section a triangle or a diamond, with a ridge on top.
2. **Flat-shaded, low in polygons:** two or three faces across a spike, two to four segments along it. Each face takes the light as one plane: lit, mid, shade, split by hard edges. That is where its crispness comes from.
3. **One colour, little paint:** the picture is near-flat. A black hair is a dark grey, so its lit planes reach about 0.27 and its shade about 0.08: the planes show.
4. **Few and big:** about 12 great masses on `roku`, about 25 to 30 spikes on `savior-moonless` and `gaari`. Big ones make the outline, small ones fill between, every one swept the same way from the crown, and their points lift clear.
5. **Bold outline:** the mass is a clear shape at a glance, toothed all round, falling over the brow in a few big locks.

The web study (sources below) says the catalog's look is in its texture: strands painted along a strip every lock shares, occlusion multiplied in, shine marks painted per lock ([DevForum, part 2](https://devforum.roblox.com/t/how-to-make-hair-in-blender-2-8-pt-2/612848), [80.lv, hand-painted](https://80.lv/articles/studying-hand-painted-texturing-workflow-for-stylized-art), [a well-known anime game's shader, excerpt](https://bjayers.artstation.com/blog/category/5)). Roblox's own docs advise a colour map with "little to no lighting" ([SurfaceAppearance](https://create.roblox.com/docs/art/modeling/surface-appearance)). AV's units follow Roblox's way: hard-edged geometry lit by the engine.

**Why 43 rounds missed:** they chased the catalog's bar, sixty to a hundred thin ribbons and a painted texture, with soft paint across each ribbon, so they read as tubes or petals. A Voidkin's bar is a unit's in Anime Vanguards (the director, 2026-11-23, 23:45). The spike rounds of 2026-11-24 and 25 were rejected as "stiff flat shards, too many, too alike, faceted": thin flat cards all of one size. AV's are solid, swept in groups, big beside small.

**What sixteen blind reads found** (TESTED, 2026-11-26, 13:30 to 14:12). Each read was a new fresh reader, given one sheet with the takes beside the four black AV heads at one size. Mostly two takes differed in one thing, and the reader checked them in both orders. Sheets: `study/blind2.png` to `blind16.png`.
- **Flat planes read as paper on ours.** These all read as "folded paper", "crumpled foil" or "faceted black paper, folded card", four times:
  - a diamond section, flat or smooth;
  - a ridge with two flat planes and a hard step;
  - the same geometry beside its rounded twin (14:08).
  - So AV's crispness doesn't come back through flat faces here. The crispness gate above is dropped, because it rewards what reads as paper.
- **A rounded section reads as hair** in every read since: a lens, five points over the top and two under, hard only at its two sides.
- **Tone:**
  - Near-black with a soft sheen read as "glossy plastic shells".
  - Charcoal, matte and rounded won (14:10).
  - Matte charcoal on flat planes is the paper above. The fault was the planes, not the charcoal.
  - The game's warm light browns a neutral black, so the black leans cool.
- **Fewer, bigger, ranked:**
  - Readers asked for it in every read. At 26 locks down to 17, the back read "one mass" (14:05).
  - Wide alone makes a lobe ("a beret"). A big lock is long and tapered.
- **The crown:**
  - Many locks meeting at the whorl read "crumpled" from the top and the back. A smooth dome under the locks and fewer roots there quiet it.
  - Thin up-locks or short tufts on the crown read as "antennae" or "horns", three times.
- **The silhouette is the gap left:** "a rounded cap". Flaring the sides read "mushroom"; holding them close reads "cap". Status was "close" in every read, never "very close" yet.

**The way, for Rook** (DESIGN, from the reads): `rook_wedges()` in `hair_ways.py`, class `Spikes`.
- **The locks:** about 19 rounded wedges over a smooth crown dome, from a whorl at the back of the crown, swept one way.
- **The layout:**
  - four small hem locks;
  - five long leaders of uneven length, leaving the outline;
  - one lock over each ear;
  - three lying forward over the crown, close to it;
  - five in the fringe, the lead to his right.
- **The colour:** cool matte charcoal, darker at the roots and under each lock, with the occlusion baked in.
- **The gates:** the outline 1.4 to 1.8 heads wide; a fresh blind reader at "very close" or better before the director sees it.
