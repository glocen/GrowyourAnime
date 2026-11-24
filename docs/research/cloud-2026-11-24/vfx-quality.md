# High-quality anime-style effects, and what the best Roblox effects artists do

Research (cloud session), 2026-11-24. Written public sources only, read on that date. Techniques and numbers, never a look: no other work's shapes, colours or effects are taken (AGENTS.md, rule 3). It extends `docs/research/vfx-reference.md` (2026-11-13) and doesn't repeat it: where that study already covers a point, this links to it.

**Labels:** **SOURCED** (an official doc, a talk or a named practitioner, linked) · **COMMUNITY** (DevForum or forum posts by practitioners, not verified by Roblox) · **OPINION** (ours, to try in a blockout). Nothing here is a measurement of our game unless it says "in our code".

**Fetching:** the DevForum gives WebFetch an empty page, so its posts were read through its public topic JSON. kotaku.com refused (HTTP 521). The GDC talks themselves (Guilty Gear Xrd 2015, Art Directing VFX for Stylized Games 2017) weren't watched, so only their written summaries count here.

## Why it matters

In an auto-battler, the player watches more than they press. The effects are the fight's feel, and on a phone they're most of what shows that a hit landed.
Anime style is a timing and value discipline, not more particles: what separates good from great is held poses, one-frame strikes, hard-edged shapes and contrast. Layer count doesn't.

## 1. Principles

Already in `vfx-reference.md` and still right: three stages peaking in the first quarter, one hero shape, mid-value bodies with the top value saved for the impact, an importance ladder, hitstop and trauma-squared shake numbers, a dark edge under a bright core, grey timing first. What follows is what the anime-specific sources add.

1. **Prepare long, strike short, relax long.** The strike is often a single frame with "a brutal change of pose", and the held poses around it carry the force. Action is animated "on twos" (12 drawings a second), switching to ones only for slow, smooth passages. SOURCED: [Demon Slayer visual grammar](https://jbsiraudin.github.io/blog/demon-slayer-visual-grammar). A fighting-game animator says the same of startup: spend the frames reaching the wind-up, never in-betweening into the punch, because "the extra frame makes the hit feel slower and weaker". COMMUNITY: [What makes fighting games feel smooth](https://jayts.neocities.org/guide/smooth.html).
2. **Limited animation, keys only.** Arc System Works built Guilty Gear Xrd's 3D look from key poses without interpolation, for clarity. SOURCED (summaries only): [GDC Vault](https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The), [handout PDF](https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf), [Game Watch](https://game.watch.impress.co.jp/docs/news/20150307_691725.html). For effects, a stepped flipbook (frames swapped, not blended) reads as drawn, and a smoothly blended one reads as simulated. OPINION.
3. **Effects accentuate the animation and never replace it.** Light, sparks and shake are layered on the base motion. A strike is announced by a sharp glint, then reinforced by a light shape and sparks. The camera bumps in the strike's direction, and the shake runs at twice the drawing rate. SOURCED: the Demon Slayer article. For us, a hit's effect hangs on the clip's contact marker, and the camera's bump has a direction, not a random jitter. OPINION.
4. **Colour says who is acting.** Each actor owns one light colour (sword, enemy and sparks each have their own). SOURCED: the same article. In a crowd fight this is the readability tool: our lead's family stays brighter and more saturated, and enemies' effects lower in value. OPINION.
5. **Impact frames.** One to a few frames of high contrast at the collision, often monochrome, with sharp lines and silhouettes. A smear shows the path; an impact frame shows the moment. SOURCED: [80.lv, impact frames](https://80.lv/articles/learn-how-to-add-accents-to-your-animations-with-impact-frames), [re:frame on The Lost Crown](https://buttondown.com/reframe/archive/the-impact-of-a-frame/). There's no sourced frame count, though community write-ups say 1 to 3.
6. **Smears only across big gaps.** Add a smear where the pose before and the strike pose are far apart, as in a sword cut, not on every move. COMMUNITY: the fighting-game guide above. Hit sparks scale with the attack's strength. COMMUNITY: the same.
7. **Shape, colour, motion: three influences, one test.** Before each element, ask "If I add this element, will it make the effect noisy?" Contrast and saturation peak at the climax ("Biggest Contrast, High Saturation"), and dissipation is "Low Contrast, Low Opacity" and short. Prefer meshes with scrolling textures to particle clouds. SOURCED: [80.lv, VFX staples, Nordeus](https://80.lv/articles/vfx-staples-shape-color-and-motion/).
8. **Cel values.** Anime shapes are flat fills with hard-edged steps, usually two or three tones, the shadow a darker version of the base. SOURCED for rendering in general, not for effects: [Adobe, cel shading](https://www.adobe.com/uk/creativecloud/animation/discover/cel-shading.html). For effects: a hard-edged opaque shape (LightEmission 0) with a separate additive glow keeps its silhouette on our pale sky, where additive alone washes out. OPINION, consistent with `vfx-reference.md` item 8.
9. **Photosensitivity is a hard limit.** No more than about 3 flashes a second. Saturated red is R/(R+G+B) ≥ 0.8. Area matters from about 20% of the screen. Test every game, flashing or not. SOURCED: [Xbox Accessibility Guideline 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118), [WCAG 2.3.1](https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold). An auto-battle can stack many hits a second, so this caps screen-wide flashes and impact frames, not body flashes.

## 2. Roblox techniques, with their budgets

**Particles** (SOURCED: [ParticleEmitter reference](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter), [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)):
- Rate is capped at **400 a second per emitter, 100 on mobile**. Fill rate (screen pixels covered) and overdraw (overlapping transparent layers) are the named GPU costs.
- `Squash`, `Drag` (seconds to half speed), `TimeScale` (0 freezes), `ZOffset`, `Brightness` (when LightInfluence is 0), `Orientation` (VelocityParallel for streaks), `Shape`/`ShapeStyle`/`ShapeInOut`/`ShapePartial` for rings and discs, and `Emit(n)` for bursts.
- **Flipbooks:**
  - layouts 2x2, 4x4, 8x8 and **Custom** (1 to 64 columns and rows, non-square textures; [client beta, 2025-10-13](https://devforum.roblox.com/t/client-beta-optimize-your-particle-animations-with-custom-flipbook-layouts/4005128));
  - `OneShot` spreads the frames over the particle's life;
  - `FlipbookFramerate` is capped at 30 fps;
  - **`FlipbookBlendFrames`** chooses crossfade or a snappy swap: the stepped anime look is the swap.
- **Quality scaling and caps** (COMMUNITY):
  - an emitter's effective Rate scales with the graphics level, measured as Rate × level / 10 ([thread](https://devforum.roblox.com/t/graphics-quality-lowering-particle-emission-rates/1241979)), and with camera distance too ([thread](https://devforum.roblox.com/t/a-way-to-make-particleemitter-rate-ignore-graphics-quality/474762));
  - `Emit()` bursts aren't scaled the same way;
  - a draw cap of about **16,000 particles on PC and 3,600 on mobile and console**, beyond which particles silently drop ([colbert2677, 2021–22](https://devforum.roblox.com/t/why-do-they-partially-start-disappearing-when-i-use-a-lot-of-particle-emitter/1585054)).
- **Writes cost.** "Property changes to ParticleEmitters can have a dramatic impact on performance". Particles and decals don't batch, so each emitter adds draw calls. SOURCED: [Improve performance](https://create.roblox.com/docs/performance-optimization/improve).

**Beams and Trails** (SOURCED: [Beam](https://create.roblox.com/docs/reference/engine/classes/Beam), [Trail](https://create.roblox.com/docs/reference/engine/classes/Trail)):
- Beam: `CurveSize0/1`, `Segments`, `TextureSpeed`, `TextureMode`, `SetTextureOffset`, `Width0/1`, `FaceCamera`, `ZOffset`. **Beams keep their segment count at every quality level**, unlike particles ([Design for performance](https://create.roblox.com/docs/performance-optimization/design)).
- Trail: `WidthScale` (a NumberSequence, so a tapered swing), `Lifetime`, `MinLength`/`MaxLength`, and `Brightness` from 0 to 10,000.
- COMMUNITY: stacked curved beams fake a 3D mesh with a scrolling texture, easier than a mesh flipbook ([RUNUP breakdown, pewpewagent, 2025](https://devforum.roblox.com/t/runup-vfx-breakdown-part-4/3669430)).

**Mesh effects:**
- COMMUNITY: a slash is a squashed sphere with a polar-warped stroke texture on two `Texture` objects, the mesh itself transparent ([crescent slash](https://devforum.roblox.com/t/crecent-sword-slash-effect/1113871)).
- COMMUNITY: rings are a "Start" and an "End" copy of a mesh, the effect tweening a clone from one to the other (attributed to a top battlegrounds game; the RUNUP post above).
- Mesh flipbooks swap a mesh's texture or mesh id each frame ([thread](https://devforum.roblox.com/t/what-are-mesh-flipbooks/2656999)). Meshes catch world shading, a known problem for effects ([3k3x](https://devforum.roblox.com/t/mesh-flipbooks-particle-flipbooks-animations-and-movesets/2204359)).
- SOURCED: `SurfaceAppearance` has `EmissiveMaskContent`, `EmissiveStrength` and `EmissiveTint` ([reference](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)).
- COMMUNITY: a "distortion sphere" (Glass above Transparency 1 with a disabled Highlight) is an undocumented hack. Don't build on it.

**Other parts:**
- **Highlight:** 255 on a client at once, and a disabled one still holds a slot; destroy it instead. The old limit of 31 is gone. SOURCED: [Highlight](https://create.roblox.com/docs/reference/engine/classes/Highlight).
- **Lights:** shadow-casting lights are expensive, so effect lights take `Shadows = false`. SOURCED: Improve performance.
- **Post effects for screen punches** (ColorCorrection, Blur, FOV): no official mobile cost found.
- **EditableImage:** strict client memory budgets, only one updated per frame on display, and it needs the experience's Mesh/Image API toggle. Not for combat effects. SOURCED: [EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage).
- **UI particles:** `ParticleEmitter2D` (flipbooks, Drag, Squash, additive, `Emit`, `TimeScale`) went to **Studio beta on 2026-11-19 and can't be published yet**. SOURCED: [announcement](https://devforum.roblox.com/t/studio-beta-ui-particles/4996850). It's the right tool for reward bursts once it ships.
- **Texture streaming** (from 2025-12-12): Beam, ParticleEmitter, Decal and Texture images load at a baseline quality first, then ramp up by screen footprint. SOURCED: [announcement](https://devforum.roblox.com/t/introducing-texture-streaming/4144855). A 0.3 s effect can show its baseline mip the first time, so preload the kit.
- **Texture memory** counts pixels: 1024² costs four times 512². Use at most 512 unless an image fills a large share of the screen, and under 256 for minor ones. SOURCED: Improve performance.

**Phone budgets:**
- COMMUNITY, a Roblox-featured guest expert, mid-2024: about **500 scene draw calls, 500k triangles and under 1.3 GB of client memory** for 60 fps on 90% of phones ([MrChickenRocket](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)).
- SOURCED: "avoid changing visual effects based on SavedQualityLevel" ([Design for performance](https://create.roblox.com/docs/performance-optimization/design)). Our player toggle is the right shape.
- **No source gives a per-effect particle budget.**

**How the top Roblox fighting games are built** (COMMUNITY):
- Most anime combat effects are "short lifetime particle emitters with big size and some beams … the right textures" ([thread](https://devforum.roblox.com/t/how-can-i-start-with-vfx-in-roblox/2658727)).
- The client renders: the server validates the skill and tells every client, and each plays the clip and hangs effects on its animation events ([thread](https://devforum.roblox.com/t/best-way-to-replicate-vfx-animations-for-a-battlegrounds-game-tsb-jjs-style-architecture/4814813)).

## 3. Where we stand

What's right, in our docs and our code: the professional principles and the vault's lessons (`vfx-reference.md`); the kit's seven sheets drawn as line, fill and dark passes (`Config.FxKit`); the importance ladder, the hitstop with a body flash and a tremble, and the trauma-squared shake, all live (`Config.Combat`, Hitstop and Shake); light rows with `Shadows = false` and a preloaded kit (`FighterController/Rows.luau`); a player Effects level scaling Rate and Emit (`Rows.luau`, AR43); client-side rows on clip markers. The structure is sound. The gaps are anime timing, the engine's hard limits and accessibility.

| Gap | Evidence | Change | Who, tier |
|---|---|---|---|
| **No stepped timing.** Sheets play `OneShot` over 0.3 to 0.7 s lives, so a 16-frame sheet runs at 23 to 53 fps, smooth rather than drawn. No row chooses `FlipbookBlendFrames` (only the Lantern Row kit's rbxm mentions it) | `Config.FxKit` Sheets; principles 1 and 2 | A row names a drawing rate (12, 15 or 24) and sets BlendFrames off for cel shapes. Life comes from frames over rate, and a hit uses fewer frames (Custom 4x2) | Scintilla, a tier 1 blockout beside the current hit |
| **The default look rests on Rate on phones.** The director's "no phone cap" (2026-11-13) holds for our own choices, but the engine caps anyway: 100/s per emitter on mobile, quality-scaled Rate, and a ~3,600 particle cap. In our code, Watt's Ground Wire sets Rate 420 at frame 0 (above even the PC cap of 400) | `EffectRows/WattGroundWire.json`; section 2 | Hero shapes and flashes are `Emit` bursts, meshes or beams; Rate only for residue. A correction of fact, not a reversal: the full look stays | Scintilla (rows); research notes it in AR8's method, tier 2 |
| **Rate written every frame.** `emitter.Rate = …` runs each step for every live Emitter row (`Rows.luau`, about line 733), where Roblox warns that emitter writes cost | Improve performance | Write only on change, as `init.luau` already does for its view | Faber, own call |
| **Performance mode drops the dark twin.** It's the layer that keeps a shape readable on the pale sky | `Config.FxKit` header; `vfx-reference.md`, slash_blue tip 3 | Drop residue and secondaries first; the dark twin goes last, with the bright pass | Scintilla and research, tier 2 (it's a content-check condition) |
| **No flash rule in numbers.** "A photosensitivity check" is named for rung 8 with no threshold | `vfx-reference.md`, second batch tip 13 | Screen-wide flash, contrast punch or impact frame: at most 3 a second across all sources; none in saturated red; rung 7 and up only | Research writes it into the effects rules, tier 2 |
| **No peak budget readout.** Nothing measures an effect's emitters, live particles or draw calls at its peak | section 2 budgets | A debug readout per effect (emitters, estimated live particles, Render stats), checked in the 6-enemy pack | Faber, own call |
| **No directed camera bump, no speed or focus lines** | principles 3 and 6 | A signature's bump points along the strike; a streak sheet (VelocityParallel, Squash) in the kit | Scintilla with Faber, at the strikes per class |
| **Who's acting, by colour** | principle 4 | Enemies' effects one value step below our lead's family | Research, at the Shades' effects piece |

## 4. The checklist every effect piece passes

Judged in motion, at full speed, at the smallest phone size, on the pale deck and the dark yard. Shown with its numbers.
- [ ] Feel line names the rung, the hero shape, its direction and acceleration, and the lever (hitstop, shake, FOV, light).
- [ ] Timing reads in grey first: prepare long, strike in 1 to 2 frames, relax long; peak inside the first 25% of its life.
- [ ] One hero shape at the top value for the impact's instant only. Everything else is lower, softer and later ("a breath").
- [ ] It hangs on the clip's contact marker, and the strike is never in-betweened.
- [ ] A hard-edged opaque shape with its dark twin under any additive glow, readable on light and dark ground.
- [ ] Flipbooks stepped (BlendFrames off) unless it's smoke or a soft residue. Rate and life written down.
- [ ] Size and brightness match the rung, and the ordinary hit stays small beside the character.
- [ ] In a 6-enemy pack fight: our lead's effect is still the one the eye finds; enemies' sit a value step lower.
- [ ] Hero layers are `Emit`, mesh or beam. No emitter Rate over 100. Peak readout recorded (emitters, particles, draw calls).
- [ ] Performance mode drops residue first and keeps the hero shape and the dark twin.
- [ ] Screen-wide flash: at most 3 a second, no saturated red, rung 7 and up only.
- [ ] No gore: light, sparks, dust, speed lines; nothing sprays from a body (`Config.FxKit`'s conditions); content check before build and upload.
- [ ] Every texture is ours or from a shared open-source pack on rule 2's terms, logged; at most 512 px unless it fills the screen.

## 5. Top 5 to act on

1. **Stepped timing trial** (Scintilla, tier 1): the ordinary hit in two versions side by side, today's smooth one and a stepped one (12 to 15 fps, BlendFrames off, a 1-frame strike flash, held residue). Judged on a phone. If stepped wins, it becomes the kit's default for drawn shapes.
2. **Hero layers off Rate** (Scintilla, Faber's review): flashes and hero shapes as `Emit`, meshes or beams, so phones' 100/s cap, quality scaling and the ~3,600 cap only ever thin the residue. Fix Ground Wire's 420/s when Watt's work reopens.
3. **The flash rule in numbers** (research, tier 2): at most 3 screen-wide flashes a second, no saturated red, rung 7 and up only, checked by a counter in the self-test.
4. **Performance mode order** (Scintilla and research, tier 2): drop residue and secondaries first, and keep the dark twin. Plus Faber's write-on-change for `emitter.Rate`.
5. **Peak budget readout** (Faber): emitters, estimated live particles and draw calls per effect at its peak, run in the 6-enemy pack on the deck. It's the evidence the bar gets judged with, since no source gives a per-effect particle budget.
