# Sound: how we make it good

Research, 2026-11-15, on the director's ask (`docs/decisions.md`, 2026-11-15: "the game lack environnement sfx ... we should study how to make good sfx like jujusu infinite"). The studio's method stays `handbook/visuals/audio.md`; this file is what the game needs and the changes to how we pick. Labels: SOURCED (read at the link), UNVERIFIED (nobody acts on it yet). Nothing here is tested in Studio.

## Where we are

- **Nine cues in the whole game:** Haymaker's strike and the reveal's eight (`src/shared/Config/Sounds.luau`, `docs/asset-log.md`). Every other moment is silent: steps, the Shades, every other attack, the grounds, the base, the screens.
- **Every pick was made by measure.** No teammate can hear, so a waveform's shape chose each one and no ear accepted it. The director's verdict: "meh", and on 2026-11-14 "Horrendous".
- **Only two libraries were searched:** ProSoundEffects and APMOfficial. The search tool takes any author (`handbook/visuals/audio.md`, "Search"); we ranked those two first and stopped there.

The fault is less the nine picks than the process: one candidate per cue, chosen blind, and most of the game never briefed. The fix is coverage, sets, and the director's ear early on several candidates.

## What makes action sound good

The director's example, Jujutsu Infinite, has nothing written about its sound: no developer post, DevForum thread or serious review was found. The big games' sound teams have written a lot, and it agrees. Each item names what we take.

1. **Sets, not single sounds.** Mortal Kombat 1 builds impacts in categories (body, blade, blunt, magic). Each fighter gets a palette of impact layers, whooshes and drones. Basic hits share core impacts, and signature moves get their own launch, impact and block sounds. SOURCED: [A Sound Effect, 2023](https://www.asoundeffect.com/mortal-kombat-1-game-audio/). **Ours:** one shared impact set by weight (light, medium, heavy, critical) and one whoosh set by weapon kind. Each signature gets its own sounds per beat (start, release, hit), as the handbook's "three beats, three sounds" already says.
2. **A hit is layers in time:** the tell or whoosh before contact, a sharp transient on the contact frame, the body (the weight), and a short tail. Keep tails short, so they don't mask the next hit. SOURCED for the layering (the MK1 page). The masking remark is UNVERIFIED, though it agrees with the handbook's "a blade is crisp and short". **Ours:** each impact cue is a stack of two or three slices played on one clock, and a tail stops before the next swing can land.
3. **Enemies start with steps and breath.** Diablo IV gives every monster footsteps and foley first ("the creature's cadence and rhythm"), then attack efforts and pain sounds. It randomises every sound and caps how many copies play at once, by "importance to you, the player". SOURCED: [Blizzard, 2021-10](https://news.blizzard.com/en-us/article/23731236/diablo-iv-quarterly-updateoctober-2021). God of War's Draugr were hard to hear coming until their spawn sounds were varied. SOURCED: [A Sound Effect, 2018](https://asoundeffect.com/god-of-war-sound/). **Ours:** a Shade set of a paper rustle as it moves, a rise as it appears, a tell before its swipe, its swipe, a hurt crackle and its burst into light and paper.
4. **The important sound pops; the rest gives way.** MK1 and God of War duck lesser sounds under the big moments with side-chain compression. Overwatch and Diablo IV rank sounds by importance and cap voices. SOURCED: the MK1 and God of War pages; [Overwatch, GDC 2016](https://gdcvault.com/play/1023010/Overwatch-The-Elusive-Goal-Play), from the abstract. **Ours:** a priority table (below). The lead's hits and a Shade's tell come first, ambience last, and each cue has a voice cap.
5. **The world breathes under it.** Ghost of Tsushima runs its ambience from data (what plays where and how often), places spot sounds by hand only where they matter, and drops ambience under tense moments. SOURCED: [A Sound Effect, 2020](https://www.asoundeffect.com/ghost-of-tsushima-sound/). **Ours:** each place gets one bed and a few spot sounds: the grounds' festival, the base's power plant, the Breaker.
6. **Nothing sounds the same twice.** Pitch spread about ±10% and volume 0.85 to 1, with at least three takes for steps. UNVERIFIED: tutorials only, though they agree with each other and with Diablo IV. **Ours:** the handbook's pitch spread on every cue, and three takes for each step surface and each common impact.
7. **Phones are the target.** A phone speaker gives very little low end, so weight has to live above it. UNVERIFIED on numbers. It agrees with the handbook's "keep a cue's weight above 250 Hz". **Ours:** the director's acceptance pass is on a phone.
8. **Loudness has a target.** Sony's guidance was −18 LUFS for portable devices, ±2 LU. SOURCED: [Designing Sound, 2012](https://designingsound.org/2012/07/30/video-games-and-loudness-standards-interview-with-sonys-garry-taylor/). **Ours:** the handbook's levelling to −14 dBFS per cue stays. The whole mix's level is measured offline, as the reveal's was.

## Picking by the director's ear

- **Search every author** (the director, 2026-11-15). Rule 2's order stays a preference: Roblox and its licensed partners first in the ranking. Any author's sound is taken when it's the best by ear. It's logged with its uploader, and gets a licensed alternate where one exists, so a claim is a one-line swap.
- **Lower risk:** Roblox, its partners, and sound effects published since 2024-05-23, which passed Roblox's copyright detection and moderation, with an ID-verified distributor. SOURCED: [Roblox, 2024](https://devforum.roblox.com/t/public-sound-effects-upload-are-now-available-for-creators/2980704). **Higher risk:** old anonymous uploads, and titles that name a commercial library or another work. The second is already filtered out by the shortlist.
- **Check that each one plays.** A search returns sounds our game can't play (Roblox staff, 2025-01-10, "intended"). SOURCED: [DevForum](https://devforum.roblox.com/t/assetservicesearchaudio-provides-results-that-cant-be-played-in-experience/3364668). Every candidate is loaded in our place before it reaches the director.
- **Several candidates per cue, for the ear.** For each cue, research's brief goes to `tools/studio/Audio`, which searches wide and shortlists five by shape. The director clicks through them in the Audition panel during a fight and picks one, or none. A cue is accepted only on that pick.
- **Anchors set the taste.** The director's first few picks become anchors. Later searches rank candidates by their likeness to the anchor of the same family (attack, decay, the three bands the tool already measures), so the ear teaches the measure. Research's proposal, untried.
- **A reference by numbers, if the director wants it:** 30 s of combat from the director's example, recorded by the director and kept internal. We measure sound events per action, where the whoosh falls against the contact, and tail lengths. That gives timing, never taste (`handbook/visuals/audio.md`, "Do"). Optional; the ear on our own candidates matters more.

## The engine, for Faber

The builder's calls; these are the facts behind them.

- **The new audio API is released** (out of beta 2024-09-10). The classic `Sound` stays supported. SOURCED: [Roblox, 2024](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454).
  - `AudioCompressor` has a Sidechain pin for ducking. SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/AudioCompressor).
  - `AudioLimiter` responds instantly, where the classic compressor lets a transient through (the handbook's trap). SOURCED: [Roblox, 2024-12](https://devforum.roblox.com/t/3282100).
- **Layers start together** when each gets the same start time: `AudioPlayer:Play(atTime)` with `SoundService:GetMixerTime()` plus about 0.1 s, per a Roblox audio engineer, 2026-07-25. SOURCED: [DevForum](https://devforum.roblox.com/t/some-looped-audios-make-a-repeating-popping-noise/4751982). That would also answer the handbook's 0.3 s late-start trap differently. Untested by us.
- **Acoustic simulation** (occlusion, reverb) is fully released (2026-09-22) and needs the new API. SOURCED: [Roblox](https://devforum.roblox.com/t/full-release-acoustic-simulation-emit-audio-with-presence/4307121). Not for now: it costs frame time on phones.
- **Steps.** The director hears no steps. Roblox's default character sounds play one plastic step whatever the floor (UNVERIFIED). Games customise them by their own copy of `RbxCharacterSounds`, mapping `Humanoid.FloorMaterial` (SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/Humanoid)) to sets. A report of 2026-08-19 says the defaults can't be removed in some games (UNVERIFIED). **Test first in our place:** are the defaults there and audible, and does our own copy replace them? The Voidkin and the Shades are rigs with no steps at all: theirs come from their walk clips.
- `AssetService:SearchAudioAsync` replaces the deprecated `SearchAudio`. It can't filter by uploader, so the tool reads each result's creator. SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/AssetService).

## The cues

Pass 1 is what a first session hears in its first ten minutes, in the order it hears it. Pass 2 is the rest. The total is about 45 cues; with sets of three, about 90 slices.

**Priority**, highest first, which decides the voice caps and what ducks:

1. the lead's hits and signature;
2. a Shade's tell;
3. rewards (shard, level, credits);
4. the screens;
5. other hits;
6. steps;
7. spot sounds;
8. ambience.

### Pass 1: the first ten minutes

| Cue | Set | What it should feel like |
|---|---|---|
| The avatar's steps | 3 per surface: paving, wood boards | soft, quick, never louder than a hit; a tap, not a clomp |
| The lead's steps | 3 | lighter than the avatar's, so the pair reads as two |
| The grounds' bed | 1 loop | a festival at night far off: murmur, wind through paper flags, a low drum now and then; under everything |
| A lantern's spot | 1 loop | a soft flame flutter near the lanterns |
| A Shade appears | 2 | paper drawn up from nothing with a cold rise; it warns without alarming |
| A Shade moves | 1 loop | dry paper scraping; tells where it is |
| A Shade's tell | 2 | a short inhale of rustling before its swipe; the player learns to hear it coming |
| A Shade's swipe | 3 | a paper-edged whoosh |
| A Shade's hurt | 3 | a crackle of paper and a spark |
| A Shade bursts | 2 | light popping and paper scattering: the payoff, bright, never a death cry |
| Whoosh, by weapon | 3 each: blade, blunt, staff, fist | the swing, peaking on the contact frame |
| Impact, by weight | 3 each: light, medium, heavy | transient plus body; heavy carries the lowest weight the phone can play |
| Critical | 2 | the impact plus a bright sweetener; reads as better, not louder |
| The lead is hit | 3 | a dull thud with a spark; apart from the Shade's crackle |
| Each kit's beats | per beat | Haymaker's retake, Lantern Burst, Held Note, First Strike, Scarf Step, the keeper's slam: start, release, hit |
| A shard drops | 1 | a glassy chime with a rising tail; the game's main reward |
| Level up | 1 | a short rising fanfare in tone, not music |
| Credits gained | 3 | a light coin-and-glass tick; it plays often, so it's tiny |
| UI: tap, open, close, tab, buy, refused | 1 each, one family | one material for all (glass and metal, like the kit); a tap is nearly silent |
| The Breaker works | 1 loop | an electric hum that rises with its share of power |
| A shard is ready | 1 | a clear chime from the Breaker |
| The reveal's eight | as TR4 | brought to the director's ear again, beside new candidates |

### Pass 2: the rest

- States: stagger's crack, heavy stagger's burst, stun's circling, knockdown's thud, burn, chill and freeze, shock, sap.
- The keeper's entrance, its ring and its fall.
- The lead's fall into light; the next lead sent out.
- The base's bed (a power plant at rest); each bay working; the generator; the battery charging; infusion's surge, Low and High voltage.
- The Festival Door: its hum and the trip.
- The Power screen's handles; an upgrade bought; gear equipped.
- The Voidkin's efforts and voices: a real gap the big games fill (MK1 records 300 to 400 files a fighter). A later piece, once the director wants voices at all.

## Next

1. **The director:** this plan, and whether pass 1 goes before Faber's next fixes (research recommends it: sound is the cheapest large gain in feel left).
2. **Faber:** the steps test in our place, then `tools/studio/Audio` moved to `SearchAudioAsync`, with each result's creator and a playability check. Then pass 1's shortlists, five per cue, into the Audition panel.
3. **Research:** one brief per pass 1 cue (search words, length, attack, the bands), in TR's entry when the piece opens.
4. **The director's ear:** a listening session per family (steps and world; the Shades; hits; rewards and UI), about 15 minutes each, picks recorded in the panel.
