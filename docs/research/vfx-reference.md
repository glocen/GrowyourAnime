# Professional game effects, and ours beside them: a reference study

Research, 2026-11-13. For the effects pass (`docs/asset-requests.md`, AR8), on the director's word of the same day: "make it great look at some pro vfx examples and compare" (`docs/decisions.md`).

**The question:** what makes professional skill effects and UI effects read as premium, in structure, readability, impact and motion, with numbers where they exist? And where do ours fall short?

**The evidence:** public written sources only, read on 2026-11-13. No footage was studied or kept, so there's nothing in `build/reference/`. These are principles and numbers, never a look: no shape, colour scheme or effect of another game is taken (`AGENTS.md`, rule 3).

**Labels:**
- **MANUAL:** an official or talk source.
- **OBSERVED:** a practitioner's stated measurement.
- **DESIGN:** ours.

Where no source gave a number, it says so.

## What the professionals say

### Structure

1. **Three stages, peaking early.** A short wind-up, an impact that peaks within the first quarter of the effect's life, then an eased fade or erosion. Never linear. MANUAL: Riot's VFX style guide, as summarised by [VFX Apprentice](https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips).
2. **One main shape.** The primary element carries the high value, a clear silhouette, high opacity and one sharp focal point. Secondaries are lower in value and opacity, simpler, softer, and move less. On a projectile, the leading tip is the brightest part. Don't stack many alpha layers or mix shapes that contradict each other. MANUAL (the same).
3. **Block the timing in grey before texturing.** Even an instant effect dissipates gracefully. Heals run slower than attacks. OBSERVED, no frame counts given: [VFX Apprentice, timing](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
4. **Separate the beats.** A secondary layer comes after "a breath", so it reads as a second effect. Late spark spawns that break the momentum are cut. OBSERVED: [realtimevfx, timing](https://realtimevfx.com/t/are-there-any-experienced-vfx-artists-here-who-excel-at-timing/28575).

### Readability

5. **"If everything is important, nothing is."** Rate each effect's importance from 1 to 10, and match its size, brightness, sharpness and punch to that rating. Control effects read stronger than plain damage. MANUAL: [realtimevfx, Riot's missile anatomy](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062).
6. **Noise is the enemy.** Only high-impact effects may be loud, and only within limits. Cut fine, busy texture. The order of priority: gameplay accuracy, then readability, then theme. MANUAL: [Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/) and [behind the VFX updates](https://www.leagueoflegends.com/en-au/news/dev/dev-behind-the-scenes-of-vfx-updates/).
7. **Value.**
   - The body sits in mid values; the top value is kept for the impact's instant. Never pure black or pure white.
   - Effects get the widest saturation, the world the narrowest.
   - One dominant hue with a small, desaturated complement.
   - MANUAL (Riot's guide, as above).
8. **On light and dark ground alike:** a bright interior with a darker, more saturated edge. Premultiplied alpha holds colour where additive washes out on bright ground. OBSERVED: [realtimevfx, colour](https://realtimevfx.com/t/diving-into-color-tips-tricks-i-use-for-using-color/16220).
9. **On a phone:** no primary source gives a size or particle cap. Fewer, larger particles beat many small ones (a weak source).

### Impact

10. **Hitstop.**
    - Both bodies freeze for the same time, longer for more damage, shorter for projectiles, with a cap.
    - The struck body shakes during the freeze, and the shake shrinks across it.
    - Sakurai keeps it short when many fighters are on screen.
    - MANUAL: [Sakurai, Famitsu column 490](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/).
11. **Hitstop numbers.**
    - **Smash:** a heavy one-on-one hit about 133 to 250 ms, capped at 500 ms. Scaled down to ×0.75 with eight players. OBSERVED: [SmashWiki, hitlag](https://www.ssbwiki.com/Hitlag).
    - **Street Fighter:** light about 150 ms, medium 183, heavy 217. OBSERVED: [sonichurricane](https://sonichurricane.com/?p=1043).
    - **An action-game primer:** weak hits 0 to 30 ms, strong 50 to 80, critical 100 to 150, and a hit flash on the struck body of about 80 ms. OBSERVED: [uhiyama-lab](https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/).
12. **Shake.**
    - Heavier hits shake with more amplitude and frequency.
    - The shake fades in and out over the camera's own motion.
    - "Trauma" decays, and the shake is trauma squared, because "linear doesn't feel punchy."
    - MANUAL topic: [Eiserloh, GDC 2016](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing). OBSERVED: [Game Developer, hit effects](https://gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).

### Motion and the interface

13. **Durations.**
    - Small feedback takes about 100 ms, which reads as instant.
    - Panels take 200 to 300 ms. Over about 400 ms feels slow, and 500 ms drags.
    - Exits are shorter than entrances: on mobile, 225 ms in and 195 ms out.
    - MANUAL: [Material motion](https://m1.material.io/motion/duration-easing.html) and [NN/g](https://www.nngroup.com/articles/animation-duration/).
14. **Easing.** Ease out to enter, ease in to exit. Linear motion looks mechanical. MANUAL (the same).
15. **A reveal's escalation by rarity.**
    - Low rarities run cool and quick, high ones warm and slower.
    - The reveal slows and shifts colour and sound before the result.
    - A skip that's blocked, and a fake-out that's long or frequent, both backfire.
    - Weak (search snippets; the primary post refused us).

### Mistakes the professionals name

16. Each of these is MANUAL, from the sources above:
    - effects that linger, even a few frames;
    - linear curves;
    - too many alpha layers;
    - everything at the top value;
    - every effect equally loud;
    - late secondaries that kill the momentum.

## Building in 3D: how the professionals make the parts

Research, 2026-11-13, on the director's word of that day: "we should looks at pro tips regarding 3d and take note". Written public sources only. Techniques, never a look.

Roblox has no custom shaders. So a trick that needs one (a texture panning on a mesh, erosion by a threshold, two textures multiplied, a soft rim) takes a stand-in from the last list in this section. The Roblox engine facts found here are in `handbook/visuals/vfx-engine-facts.md`, "Meshes".

### Meshes

1. **The UVs run along the shape's length, in one piece, with no seams.**
   - The texture is clamped, not wrapped, so a sweep along it ends cleanly.
   - A ribbon is better a curved strip, about a third of a cylinder and double-sided, than a flat plane. It reads from more sides.
   - OBSERVED: [realtimevfx, mesh ribbons](https://realtimevfx.com/t/vfx-basics-mesh-soulercoasters/1987). MANUAL: [Epic, animating UVs](https://dev.epicgames.com/documentation/unreal-engine/animating-uv-coordinates-in-unreal-engine).
2. **A whirlwind is nested shells.**
   - The inner shell moves fastest and each outer one slower.
   - Bumps in the mesh keep the outline from being a smooth tube.
   - The mesh's ends fade through painted vertex alpha, so no hard border shows.
   - Small sprites ride over the shells for detail.
   - OBSERVED: [realtimevfx, a tornado](https://realtimevfx.com/t/soulnado-vfx-wip/7500) and [80.lv, a tornado](https://80.lv/articles/creating-a-tornado-in-unity/).
3. **Breaking repetition:** each spawn turns the mesh by a random angle. OBSERVED: [realtimevfx, a League effects artist's notes](https://realtimevfx.com/t/shannon-mcsheehan-lol-fx-knowledge-share/1133?page=15).
4. **Volume on a thrown thing:** a few curved strips, turned at random about the line of flight within a narrow range. Two crossed strips add body. OBSERVED: [80.lv, stylized combat effects](https://80.lv/articles/creating-stylized-combat-vfx-in-the-zelda-style/).
5. **Mesh or card:**
   - Meshes take swipes, slashes, shockwaves and anything with a near and a far side.
   - Flat sparks, flashes and glows stay on cards facing the camera.
   - OBSERVED: [VFX Apprentice, the basics](https://www.vfxapprentice.com/blog/textures-meshes-shaders-vfx-basics).

### Textures

6. **Grey, tinted in the engine.**
   - Textures are painted in greyscale and coloured by the engine, so one texture serves many effects.
   - A gradient ramp gives one part several colours.
   - OBSERVED: [realtimevfx, gradient mapping](https://realtimevfx.com/t/particle-gradient-mapping/1952).
7. **Layered noise:**
   - its scales an octave apart (0.5, 1, 2), never close ones, which beat against each other;
   - its speeds compatible, or the layers read as two sheets sliding;
   - the more layers, the narrower each one's range.

   OBSERVED: [JangaFX on Diablo III's effects](https://jangafx.com/insights/diablo-3-vfx-experiments), and [realtimevfx, scrolling](https://realtimevfx.com/t/vfx-basics-creating-the-scrolling-texture-with-mask-setup/1966).
8. **A ribbon's look:** the brightest values at its edges. Two ribbons on the same path, one adding light and one covering, build depth. OBSERVED: the League thread above.
9. **Size:** no source gives a budget. On Roblox, memory goes by pixel count, so a 512 costs four times a 256 (MANUAL). A practitioner rarely needs noise over 512 (weak).

### Layers and their motion

10. **Each layer has its own build-up, peak and aftermath,** and together they make the effect's.
    - A trail starts as the swing gathers speed and ends as its force fades.
    - An impact is built in order: the contact point, then debris, dust, shockwaves, smoke, then a few small lingering bits.
    - The build-up before the impact stays clean.
    - OBSERVED: [80.lv, trails and impacts](https://80.lv/articles/trail-impact-vfx-production).
11. **A beat of breath before and after:** a short charge-in and an aftermath, added once the core works. OBSERVED: the stylized combat article above.
12. **Timing first, then detail.** Every extra layer is "more risk of dissonance". Grey block-ins make tuning faster, and re-timing alone can change what an effect means. OBSERVED: [VFX Apprentice, timing](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx) and [realtimevfx, block-ins](https://realtimevfx.com/t/block-ins-and-timing/29830).
13. **Motion lives in curves.**
    - A constant pan reads as still, so the speed and the strength change over the life.
    - Sparks start stretched and shrink to dots.
    - Halving a lingering cloud's life and softening its edge cured it.
    - OBSERVED: the two 80.lv articles above.
    - No source gives a scale curve in numbers.
14. **One base, many effects:** a fix to the base reaches every effect built on it. MANUAL: [Epic, Niagara's emitter inheritance](https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/Niagara/UNiagaraEmitter). The kit and the player are our version.

### On Roblox, the stand-ins (DESIGN, from the sources and `handbook/visuals/vfx-engine-facts.md`)

| A shader trick elsewhere | Ours |
|---|---|
| a texture panning round a shell | the shell spins (the player's `Spin`). Nested shells spin at different speeds, the inner fastest |
| a texture panning along a ribbon | a Beam with `TextureSpeed`, or two Beams at different speeds for parallax (MANUAL: [Roblox's waterfall tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/create-waterfalls)) |
| a soft fade at a mesh's ends | vertex alpha painted in Blender, with `Transparency` above 0 |
| erosion by a threshold | the burn as a Start-to-End track: a band's transparency stepping up the coil, as B1's exit does |
| a glow on the mesh | an emissive mask (`EmissiveStrength` by script, the red channel), or Neon with vertex colour and no texture |
| a texture that flickers through by itself | the ForceField material on a grey texture: free motion, but its speed can't be set |

## UI effects: how the professionals make them feel, and how they're built

Research, 2026-11-13, on the director's word of that day: "we also need to do research on pro tip for ui effects and ui vfx". Written public sources only. Roblox's engine facts for UI effects are in `handbook/visuals/ui.md`, "UI effects: engine facts".

### What the sources say

1. **A reward flies, lands, then the counter answers.**
   - Icons fly to their counter on a curve, not a straight line, each with a random arc and a stagger, at most about 10 icons per gain.
   - The counter starts ticking when the first one lands, and pulses about 30% larger over about 0.25 s.
   - A "+N" takes its meter's colour.
   - OBSERVED: [a Zynga postmortem](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies), [Bézier coin flights](https://sstyles93.github.io/blogs/mmgs_bezier).
2. **A reward's layers are 60 to 150 ms apart.**
   - Spark, then value, then count, about 400 ms in all.
   - All at once reads as one flash, and wider gaps read as lag.
   - The answer comes on the press, not the release.
   - OBSERVED, weak: [dev.to, the reward moment](https://dev.to/patilrb/the-reward-moment-is-the-product-43h6).
3. **A press:**
   - The press squeezes to about 0.97.
   - Nothing scales in from 0: from 0.9 or more.
   - OBSERVED: [Emil Kowalski, animation tips](https://emilkowal.ski/ui/7-practical-animation-tips).
4. **Springs:**
   - Apple's spring is a duration and a bounce. A bounce of 0.15 is barely felt, 0.3 is clear, and above about 0.4 is too much for UI. MANUAL: [WWDC23, animate with springs](https://developer.apple.com/videos/play/wwdc2023/10158/).
   - On Roblox, the open spr module: a damping ratio of 1 is neutral, and below 1 is for what must pop. OBSERVED: [spr](https://github.com/Fraktality/spr).
   - Springs beat tweens when a target changes mid-motion.
5. **Stagger:** 30 to 80 ms per item, capped, since 10 items at 50 ms make the last one wait half a second. OBSERVED: [Flutter's staggered menu](https://docs.flutter.dev/cookbook/effects/staggered-menu-animation).
6. **Count-ups:** Expo Out, with most of a large jump counted fast and only the end eased. OBSERVED: [countUp.js](https://github.com/inorganik/countUp.js).
7. **A reveal:**
   - Anticipation, then the climax at the highest contrast and saturation, then a short, faint dissipation.
   - A bigger reward builds a longer anticipation.
   - OBSERVED: [80.lv, shape, colour and motion](https://80.lv/articles/vfx-staples-shape-color-and-motion/).
   - "Joyful but subtle", with light and shadow drawing the eye exactly when and where. MANUAL: [a Supercell studio blog](https://supercell.com/en/news/job-uiux-artists-story/).
8. **How much juice:**
   - 3,018 players across four levels of juiciness. None and extreme both did worse than medium and high, on play time, experience, motivation and performance. MANUAL, peer-reviewed: [Kao 2020](https://www.x-mol.com/paper/1307980428882448384).
   - Too much amplified feedback lowers how competent players feel. MANUAL: [CHI 2024](https://publikationen.bibliothek.kit.edu/1000171104/152952099).
9. **Apple's motion rules:**
   - Feedback is brief and precise.
   - No motion on the most frequent interactions.
   - Motion is never the only carrier of information.
   - No sustained wobble near 0.2 Hz.
   - The player's reduced-motion setting is respected.
   - MANUAL: [Apple HIG, motion](https://developer.apple.com/design/human-interface-guidelines/motion).
10. **One motion language:**
    - a few named patterns and tokens, never literal values;
    - effects kept as data, with every timing offset in one place;
    - one 0-to-1 handle per effect.
    - OBSERVED: [Atlassian, motion](https://atlassian.design/foundations/motion).

**No source gives:** alpha values for glows and rays, a layer order for UI glows, or a phone budget for UI objects.

### DESIGN: our UI effects (starting numbers, tuned by playing)

1. **One UI effects kit, data-driven like the 3D player.**
   - Pop, Press, Fly, Count, Shine, Rays, Burst.
   - Each is one module with named tokens in `UI/Theme.Motion`, so no screen makes a tween of its own.
   - It's the UI's version of the 3D kit, built once.
2. **The press:**
   - a squeeze to about 0.96 on press, with a spring back at bounce 0.15;
   - `ClickHaptic` on a phone.

   This answers our open line, "a pixel isn't felt under a thumb".
3. **A reward, by its rung on the ladder:**
   - **A small gain (rung 2 to 3):** the count and a 1.1 pulse.
   - **A kill's Credits and a shard caught (rung 4 to 5):**
     - 4 to 8 icons fly on curved arcs, staggered about 40 ms;
     - the count starts on the first landing and runs about 0.6 s, Expo Out;
     - the pill pulses about 1.25 over 0.25 s.
   - **A level-up or a reveal (5 and up):** sunburst rays from a Conical gradient and a shine sweep, with the layers 60 to 150 ms apart.
4. **Springs only where something pops:**
   - panels keep their tweens (Quart Out, exits shorter and eased in, as rule 4 of the effects pass);
   - pops take a spring with bounce 0.15 to 0.3, never above 0.4.
5. **Restraint, the measure of premium:**
   - medium to high juice, never extreme;
   - nothing moves on its own for long, and a shine sweeps only on what's rare;
   - no motion carries information alone;
   - reduced motion turns moves into fades.
6. **On a phone:** a pop on a plain frame by UIScale, never on a CanvasGroup; gradients move by Offset and Rotation only.

## From the vault: open-source effects, read apart

The director shares open-source effects to study (2026-11-13). Each one is kept in `build/reference/vfx-vault/<name>/`, which is gitignored and stays local. It's read headless with Lune, so its scripts never run. Its full digest sits beside it in `build/scratch/quaestor/vault/`. Using one in the game follows rule 2's exception (AGENTS.md; the director's yes, 2026-11-13).

### slash_blue (read 2026-11-13; the VFX Forge Emit Module, zilibobi, VFX-DL 1.0)

OBSERVED in the file:
- **Shape:** 100 particle emitters, 27 beams and 3 trails, on five invisible root parts, with no meshes. Each effect is authored as attributes, and a runtime module plays them.
- **Three beats:**
  - **0 s:** the swing, the flying slice and the hit go off together. The slice is a part tweened 50 studs in 1 s, Cubic Out, carrying stacked beams and a 0.5 s particle wake.
  - **0.5 s:** an inhale 60 studs out: two stars shrink from 20 to 0 over 0.4 s, ease-in.
  - **0.8 s:** the blast, with rings, smokes, sparks, ten bezier-flown trails per path set, a camera shake and a sound.
- **Two screen punches,** on Lighting: FOV 70 to 60, Blur 7 and Contrast 0.1 in 0.1 s, released over 0.5 s. Then the blast: Blur 10 to 12, Contrast 0.5, Brightness 0.2 and a pink tint, released over 1.2 s, Circular Out.
- **The ids:** about 70 texture ids and 3 sounds, none uploaded by the file's author as far as the file shows. Who owns each needs a lookup before any use.

The tips, OBSERVED with their numbers, each with what it means for us (DESIGN):
1. **An inhale before the payoff:** 0.3 s of contraction, a star shrinking 20 to 0, ease-in, before the blast lands. For us: a signature's Charge beat gets one shrinking shape. The keeper's Gather and Haymaker's hang already do this; Lantern Burst's Heat could.
2. **A 3-frame flash:** the brightest layers live 0.05 s, the shapes under them 0.2 to 0.4 s, and the residue 0.5 to 2 s. For us: a flash is never longer than 3 frames at 60 fps. Check A's hit and the strike flashes against it.
3. **Dark under bright:** each bright crescent (LightEmission 1, Brightness 5 to 30, ZOffset 5 to 10) has a twin with no emission (LightEmission 0, black to deep violet) and dark smoke at ZOffset -2. For us: our rim-darker-than-core rule, done as a separate layer, which keeps the shape on a pale sky. It's the cheapest fix for the noon wash-out B1 met.
4. **Ease-out growth:** a ring does half its growth in the first 10% of its life (0, then 14 at 0.1, then 30 at 1). A flash does the reverse, 20 to 5 in 0.15 s. For us: rings in the rows use Quart or Expo Out, never linear.
5. **Sparks that brake:** a launch speed of 15 to 225 with Drag 5 to 7, size 0 to a peak at 15 to 20% of life then 0, and VelocityParallel Squash 2 to 0. They stretch on the launch and shorten as they slow. For us: the hit sparks' spec in the kit.
6. **Squash as a second size curve:** a ray goes -1 to 0.5, from thin and tall to wide. One texture gives two silhouettes. For us: fewer textures in the kit.
7. **Hue-shift, keep the value:** a ramp from cyan to violet. Only the 0.05 s glow carries the accent. For us: each Voidkin's ramp stays in its own family. The chromatic rainbow is theirs, and too loud for our restraint.
8. **A blade of beams on a moving part:** three stacked beams (Brightness 30, Stretch, TextureSpeed 2) between attachments on a tweened part, faded as a unit by a late transparency scale. For us: a projectile's body, such as Pip's lantern streak.
9. **Screen punch fast, release slow:** 0.1 s in, 0.5 to 1.2 s out. For us: only rung 7 and up, and gentle. The level-up and a keeper's fall are the other candidates.
10. **Shake by distance:** amplitude 0.2 for a swing and 1 for a blast, falling off linearly to zero at 150 to 300 studs. For us: only a player's own lead's signature shakes that player's camera.

**Too much for our bar:** its size, with blasts 60 studs across and 30 to 50 particles each, and its rainbow ramps. On a phone in a pack fight, that's noise. Our ladder (`DESIGN`, below) sets how big each moment gets.

### The second batch (read 2026-11-13: eleven files, six flipbook sheets, one code repo)

OBSERVED in the files. Each digest is `build/scratch/quaestor/vault/<name>_digest.md`. Every script was read as text, and none calls by id, loadstring, HTTP or a paid service: all are clean.

| File | What it is | Terms found | Verdict |
|---|---|---|---|
| day1 (Lightning Axes) | a blink-dash, 20 studs in 0.175 s, then a spin; 55 emitters, one hue | "use in games ... credit would be nice" | **yes**, for technique: small, clear beats, reads on a phone |
| JaxelosCosmoOS | an orb: 1.25 s charge, a 0.5 s flight, a 0.1 s shrink, a cross flare, a star burst | none | **yes**, as a study: disciplined palette and beats; a signature budget |
| day4 (gravthrust) | a rise, then a 45-stud lunge in a spiral of trails | a like and a follow asked; "reupload the keyframesequence" (their animation, never ours to use) | partly: the best choreography; too many layers |
| MEshFlipOpenSource | a mesh flipbook: a Decal's images swapped on a sphere or pillar | none | partly: the best hero-shape technique; its own look too loud |
| LotusSlashVFXOSByMarcid | a spin slash with a lotus bloom; 521 emitters | **CC BY-NC 4.0, study only** | partly: excellent beats; far too heavy |
| DoubleFireSlashVFXOSByMarcid | an X of two fire cuts, 10 frames apart | "CREDIT ME" labels, no license | partly: the ideas, not the density |
| HanamiLotusSwarmOSByMarcid | rows of lotus meshes blooming outward | none | partly: the wave idea; 1260 emitters is noise |
| 2yroldmiseorb | a looping void orb, 17 layers | none | partly: the loop and the black core fit the Void |
| WaterPracticeVFX | a 2 s water vortex | none | partly: good lessons, no hit frame |
| QP2V40OS, ForceandReactorsPresets | presets for outside plugins; nothing renders without them | none | partly: the numbers only; the plugins are never adopted |

**Nothing here is taken whole.** One is non-commercial, most state no terms (so their rights are unknown), and their sounds, animations and demo rigs are never ours. The lessons are the value.

The tips, OBSERVED, each with what it means for us (DESIGN):
1. **A blink hides the cut** (day1): the body fades out in 0.075 s and back in 0.065 s under a burst, and the clip freezes while it's hidden. The arrival burst reuses the departure's layers at 0.55 to 0.6 of their life, so it lands sharper. For us: the skip back, and any dash.
2. **Two cuts, 10 frames apart** (DoubleFire): an X lands as two beats, not one. For us: a two-hit signature is two flashes at least 0.15 s apart, or the second is lost.
3. **Fade to black, not to clear** (DoubleFire, Lotus): embers ramp red to dark red to black, and ground rings burn out by darkening. For us: dissipation keeps the shape on our pale sky (the noon wash-out of B1), the same rule as slash_blue's dark twin.
4. **Negative LightEmission** keeps a colour saturated and smoke solid (DoubleFire, Lotus, day4). It's undocumented: the builder tests it in our lighting before any row uses it.
5. **A negative size curve is a free delay** (Cosmo): the particle is born below zero and appears when the curve crosses it. For us: the second layer of a row needs no delay field.
6. **A four-point glint from one sprite** (Cosmo): two copies, one squashed wide, one tall. For us: the strike glint without a new texture.
7. **The mesh flipbook** (MEshFlip): a Decal on an invisible part's mesh, its image swapped 16 to 24 times over about 1 s while the part grows, ease-out cubic. For us: the hero shape of a rung 7 and up (a shell, a pillar) gets drawn motion. Our 3D method stays the base; this is its top tier, made with our own frames.
8. **Freeze inside the effect** (ForceandReactors): the effect's own time scale dips to 0.01 at 21 to 30% of its life, then returns to 1. For us: a hitstop that touches only the effect, not the fight's clock; worth a try on Haymaker's landing.
9. **One master curve** (ForceandReactors): size, time scale, colour and brightness all read from one intensity. For us: the ladder's rung could be that one number on a row.
10. **A wave from staggered copies** (Hanami): one unit in three rows, 0.06 s apart, each further out and 1.4x larger. For us: a ground signature's spread at three to five copies, never eighteen.
11. **A seamless loop** (2yroldmiseorb): rate × lifetime of 2 to 3, transparency 1 > 0 > 1, the flipbook played once per life. For us: idle auras and the shard's hum never pop.
12. **Accelerating lunge** (day4): spring stiffness ramps 20 to 1000 over 0.5 s, ease-in. For us: a lead's dash speeds up into the hit rather than snapping.
13. **The silhouette frame** (day4, QP2V40): one or two frames of black fill with a rim, or a Contrast +5 then -5 flash. For us: rung 8 at most, the keeper's fall, and only after a photosensitivity check.
14. **A shake profile** (QP2V40): amplitude up to 4 at 11% of 1 s, down to 0.5 by 53%, 12 Hz, zero at 500 studs. For us: a ceiling. Ours stay at slash_blue's 0.2 to 1.

**The flipbook sheets** (`build/reference/vfx-vault/flipbooks/`; open source, shared by the director): a ring burst drawn three ways (a shaded fill, an outline alone, two-tone toon), then a wisp splash, a hook splash and a flame, each 4x4 at 1920 px (256 px a frame once fitted to Roblox's 1024). For us: **an outline pass and a fill pass as separate sheets** lets a quiet hit play the outline alone and a signature both, one drawing on two rungs. Open source, so usable under rule 2's exception, or redrawn in `tools/`.

**ViewportStencil** (github.com/sebasvcx/ViewportStencil, MIT): code that draws a model inside a surface, such as a crack, a hole or a portal, through a masked ViewportFrame, without cutting the ground. A library, not art, so it's the builder's call, with its license notice kept. For later: craters and portals. Not Haymaker's landing, which takes no plate on the floor (AR8).

### The third batch (read 2026-11-13: ten files; the director: "not all vfx are high quality or made by pro")

OBSERVED; digests beside the others. All clean. Craft rated honestly.

| File | What it is | Craft | Terms | Verdict |
|---|---|---|---|---|
| InkSwingOSByMarcid | a black ink brush-slash: three stacked smear meshes, ink that curls back like liquid | solid, near pro | none in the file; the author's others are CC BY-NC | **yes**, for lessons: value contrast without glow |
| ArtemisArrowRainVFXOSByMarcid | a charge, four arrows, then a 1.4 s arrow storm | solid; staging pro | a credit label only | partly: the best lesson on many projectiles |
| Purple_arcane_showcase | a 10 s scripted orb showcase | solid | library headers only | partly: its screen-punch ladder, in code |
| JaxelosStarOSS | a looping comet, three colour variants | solid | none | **yes**, for its tail |
| DemonAuraVFX | a looping red aura on a rig | solid | none | partly: tendrils and the eye for an awakened state |
| bem | a channelled fire beam | amateur effect, solid camera | none | partly: camera and light moves; ~4,800 particles is what not to do |
| stuff | a two-fighter fight cinematic, no effects | solid | none | partly: the held impact |
| Death_FX | a 1 s blue burst | amateur | none | partly: a KO pop's recipe |
| bow_thngiemajig | an idle aura on a bow | amateur | none | partly: emitter volumes along a silhouette |
| First_OS | a map-scale sky beam with rainbow strobes | amateur | none | no |

**Sounds in the whole vault** (read by `AudioContent`): only day1 (4), day4 (4), slash_blue (3) and First_OS (4) have any.

The new tips, OBSERVED, with what they mean for us (DESIGN):
1. **Value, not glow** (InkSwing): black, grey and tan smears with no bloom read at phone size. For us: a mature look's strongest hits can be dark shapes with a thin bright edge, not more light.
2. **Many projectiles as two emitters** (Artemis): the rain is speed lines (Rate 35, life 0.15 s, Speed 300, squashed long) and, apart, ground hits in a box at Rate 18; the eye pairs them. About ten streaks on screen at once, framed by a sky circle and a ground circle as one shape. For us: any volley, never one part per arrow.
3. **A screen ladder in two steps** (Purple arcane): a main hit takes vignette 0.5, FOV to 45 eased back over 0.4 s, shake 1.3 over 0.6 s; a minor hit takes FOV 54 and blur 1 for 0.05 s, shake over 0.25 s. For us: rungs 7 to 8 and rung 4, scaled down to our camera.
4. **The held impact** (stuff): both bodies freeze 1.25 s while the camera keeps easing to rest; the strike is 3 frames after a 0.35 s coil. For us: a keeper's fall (rung 9) only, a few tenths of that.
5. **A tail that fades over a zone** (JaxelosStar): its beams end at 24, 32.5, 43 and 49 studs. For us: dash wakes and Pip's streak taper by staggered ends, not by one fade.
6. **Charge widens, release snaps** (bem): FOV 70 to 80 over a 0.6 s charge, then 60 in 0.15 s; a hand light tweened with the effect lights the caster and the floor. For us: a channelled signature's breath, with the light on the caster, never on the landing (AR8).
7. **Tendrils as curved beams** (DemonAura): four tapered, camera-facing beams make the whole silhouette. A three-hump size curve twinkles without a flipbook. For us: awakened states and the keeper's aura.
8. **Emitter volumes** (bow): invisible boxes along a shape make the sparkle trace its silhouette. For us: a weapon's glint along its edge.

## What the vault teaches, beside ours (2026-11-13)

OBSERVED in our `Config.Effects`: **25 layers across every effect in the game**, 3 of them emitters, all 2x2 flipbooks, and no layer that is dark. A good file in the vault spends 15 to 100 layers on a single moment. The gap isn't polish; it's structure. DESIGN, what changes:

| | Ours now | The vault, every good file | The change |
|---|---|---|---|
| Layers | one to six per effect | a stack per beat: flash, main shape, secondary, residue | each beat a small stack: 4 to 8 layers at rung 2 to 4, 10 to 20 at rung 7 to 9 |
| Dark | none | a dark twin under every bright layer; smoke and embers fade to black | every bright layer gets its dark twin; dissipation darkens, never just clears |
| Drawn motion | 2x2 flipbooks | 4x4 and 8x8 sheets; outline and fill drawn apart; mesh flipbooks for hero shapes | a texture kit of our own sheets (ring burst, crescent, splash, puff, spark, glint, flame), each with an outline pass and a fill pass |
| Physics | little | Drag 5 to 7, Squash on velocity, Acceleration that curls, negative size as a delay | the kit's emitter row exposes Drag, Squash, Acceleration, EmitCount and EmitDelay, all Tune-live |
| Beats | one or two | anticipation (an inhale or a charge), a 3-frame flash, the shape, a breath, the secondary, residue | rung 7 and up has all six; rung 2 to 4 keeps flash, shape, residue |
| Screen | a short linear shake | FOV punch, blur, contrast, vignette, a fast-in slow-out ladder | rung 4 and up gets a screen row, from the ladder above |
| Light | none on the caster | a PointLight that flashes with the hit or rides the charge | a light row on the caster for rung 7 and up |
| Budget | far under | often far over (500 to 4,800 particles) | a cap per rung, found on a phone: the vault shows both what works and what's too much |

**When:** the kit gets these capabilities now (the effects kit stays at the bar now, the director's word of 2026-11-13 on the finish pass). The effects being built now use them. Effects that already passed are redone at the finish pass, with this table as its brief.

## Ours beside them (OBSERVED in our config and captures, 2026-11-13)

| What | Ours now | The professionals | Read |
|---|---|---|---|
| Hitstop | Light 0.09 s, Heavy 0.13 s (`Config.Combat.Hitstop`); Light on every hit that isn't heavy (`FightService`, the push waits it out) | ordinary hits 0 to 50 ms, strong 50 to 80, signature or critical 100 to 150; shorter with many on screen | Our light is a strong hit's length, used on ordinary blows in a crowd |
| The struck body | the clip pauses; no flash on the body, no shake inside the freeze | a hit flash of about 80 ms; the body shakes, shrinking across the freeze | missing: the cheapest premium lever we don't use |
| Camera shake | Heavy 1.6 × 0.25 = 0.4 studs, 0.15 s, linear fade, position only (`Effects.Shake`) | trauma squared, heavier means more amplitude and frequency, faded in and out | linear and very short: it ticks rather than lands |
| Haymaker's hit (`build/captures/ar1/haymaker_staged_strip.png`) | the ram's gold square, then a few thin white spark lines at contact | one main shape at the top value at the impact's instant, peaking in the first quarter | the impact is the weakest beat: thin lines, no light on the ground, nothing to say "heavy" |
| Held Note (`build/captures/ar4/lyric_note_art_full_2.45s.png`) | pale lilac waves, thin, at mid value on a pale sky; small pink zigzags on the hit | a bright interior with a darker saturated edge, readable on light and dark | low value contrast on bright ground: it melts into the sky |
| The level-up (`Config.Effects.LevelUp`) | a flat ring from 2 to 10 studs over 0.6 s, and the word rising 1.6 s | the peak early, then an eased fade; reward pops scaled to their importance | a mark on the ground, not a moment (already in `docs/polish-later.md`) |
| UI motion (`UI/Theme.Motion`) | 0.12, 0.2 and 0.35 s, Quart Out for everything | 100 ms feedback, 200 to 300 ms panels, exits shorter and eased in | durations right; exits use the entrance's curve and length |
| Button press (`UI/Kit/Button`) | sinks a pixel, shaded | about 100 ms of feedback | thin at phone size: a pixel isn't felt under a thumb |
| The reveal (`Config.RevealArt`) | flash 0.10 to 0.26 s and shake 2.5 to 6.5 rising by rarity; skip from 1.0 s | escalation by rarity, never a blocked skip | already built to the pattern; TR4's verdict checks it in motion |
| Billboards (`docs/polish-later.md`) | drawn a picture late, out a picture early | lingering or late "even a few frames" hurts | a known bug, in the pass |

## DESIGN: the rules for our effects pass

1. **An importance ladder,** set once and kept by every effect after:

   | Effect | Rung |
   |---|---|
   | an ordinary hit | 2 |
   | a combo's last hit, the Shade's swing | 3 |
   | a critical | 4 |
   | the level-up, a shard caught | 5 |
   | a Voidkin's signature | 7 |
   | the keeper's signature | 8 |
   | a keeper falls | 9 |
   | a Legendary or Mythical reveal | 10 |

   Size, brightness, the hitstop and the shake grow with the rung. Nothing below 7 takes the top value for more than a frame or two.
2. **The hit's four levers, by rung,** as starting numbers to tune by playing (Faber, runtime-tuned as always):

   | Rung | Hitstop | The struck body |
   |---|---|---|
   | 2 to 3 | 0.04 to 0.05 s | a flash of 0.06 s |
   | 4 | 0.07 s | a flash of 0.08 s |
   | 7 to 8 | 0.12 to 0.14 s | a flash of 0.1 s, and the body shaken inside the freeze, shrinking |

   - The shake becomes trauma squared: a heavy hit adds about 0.5 trauma, a signature about 0.8. It decays over 0.3 to 0.4 s, with some rotation as well as position.
   - The killing hit keeps its own hold.
3. **Every effect has one main shape and three stages.** It peaks in the first quarter of its life and fades eased, never linear. The secondary comes after a breath, lower and softer. A bright interior with a darker saturated edge, so it reads on Lantern Row's night and the base's bright sky alike.
4. **The UI's motion:**
   - Exits are about 0.8 of the entrance's length and ease in.
   - A press answers within 0.1 s, with a squeeze a thumb can feel. The squeeze is ours to design, judged on a phone.
   - Every reward that counts (Credits, Electricity, experience, a level) pops at the size of its rung.
5. **Judged in motion at phone size,** never from stills, each beside its "before". Rung 7 and up gets `ga-fresh-eyes`.

**Images looked at:** `build/captures/ar1/haymaker_staged_strip.png`, `build/captures/ar4/lyric_note_art_full_2.45s.png`. **Not found anywhere:** the phase ratios of a skill effect in frames, a damage number's pop, a cap on particles for phones. Those stay ours to find by playing.
