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
