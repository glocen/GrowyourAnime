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

## What the full-size pictures show (2026-11-25, 00:49, on "still very very bad js learn do study"; unfinished, paused at the director's word)

The Shag build and a spiked build after it were both rejected (AR64). The study this time is on eight of the catalog's best-loved boys' hairs at 700 px (`build/reference/hair/catalog720/`, internal). Six are read; `6413085241` and `4875445470` are not yet. Their 3D pictures need a sign-in, so the meshes weren't read: everything below is from pictures.

OBSERVED:
- **A lock is a long thin ribbon,** five to eight times as long as it is wide, near one width for most of its length, then a long needle point. Ours were leaves and cones, two to one.
- **Every ribbon curves,** in a C or an S, and its point flicks up or out. None is straight.
- **Seventy to a hundred of them, in about three layers,** and they cross. They come in clumps that fan from one root, never in rows side by side.
- **The top is one surface.** Round the whorl the hair is broad smooth sheets with fine lines drawn along them; the ribbons only come apart toward the ends. Two tufts arc left and right out of the whorl, with a few thin strays.
- **The light is soft and runs across each ribbon** (lighter down its middle, dark at its edges), on a picture that goes from a dark root to a lighter end. A black cap fills the inside.
- The mass is about 1.5 to 1.7 heads wide and falls over the forehead to the eyes.

DESIGN, tried once (`tools/blender/hair_ways.py`, `Sheets`, take T): pleated sheets from the whorl whose pleats part into points near their ends, broad shells over the crown, a few loose locks. It reads as hair, but its pleats are still wide petals (about three to one), nothing crosses, and the points don't flick. Not shown as a candidate.

Still to do: read the last two pictures, measure a ribbon's width against the head on each, then build ribbons that thin, curved and crossed, and judge the build beside these pictures at one size before anyone sees it.
