# Sound: how we make it good

Research, 2026-11-15, on the director's two asks (`docs/decisions.md`, 2026-11-15: "the game lack environnement sfx ... we should study how to make good sfx like jujusu infinite"; then "research about pro sfx, anime sfx like fire force, pro roblox dev sfx and if we need an app such as audacity"). The studio's method stays `handbook/visuals/audio.md`; this file is what the game needs and the changes to how we pick. Labels: SOURCED (read at the link), UNVERIFIED (nobody acts on it yet). Nothing here is tested in Studio.

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

## Pro and anime craft, in recipes

The director's second ask, 2026-11-15: "research about pro sfx, anime sfx like fire force, pro roblox dev sfx". What the professionals say, as checks we can run.

- **A hit is two sounds:** the attacker's and the target's, chosen by material. At contact the swing ducks a few dB, so the impact punches through. SOURCED: Ghost of Yōtei, [A Sound Effect](https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- **Weight is low end plus the transient.** God of War Ragnarök gave a bowshot "more bass and transient at the beginning". A filter that moves on every attack breaks repetition. The tail grows with the hit's strength. SOURCED: [A Sound Effect](https://asoundeffect.com/god-of-war-ragnarok-game-audio).
- **One big hit is several tiny ones:** 3 to 8 impacts within a second, each a few frames long (Randy Thom, Skywalker Sound). SOURCED: [Sound Ideas, 2025](https://sound-ideas.com/blogs/sound-ideas/the-sound-design-power-of-single-events-composed-of-multiple-closely).
- **A heavy impact is built from the bottom up:** a distorted kick or taiko, then percussion, a processed cymbal, the sub and an atmosphere. Each layer gets its own EQ and compression, and the sum a limiter. A riser leads into the hit, or into a brief silence before it (Richard Veenstra). SOURCED: [Ableton, 2021](https://www.ableton.com/fr/blog/learn-how-to-make-high-impact-sounds-for-movies-and-trailers).
- **Elements, from named pros:**
  - Fire: whooshes from a burning staff swung past the microphones, cut into a cast, a travel loop and an impact (Diablo IV). SOURCED: [Blizzard](https://news.blizzard.com/en-us/article/23731236/diablo-iv-quarterly-updateoctober-2021).
  - Ice: metal scraped on ice, crunches, ice pings and wind chimes through reverb, always with one realistic layer (Frozen 2). SOURCED: [A Sound Effect](https://www.asoundeffect.com/frozen-2-sound/).
  - Frost: "resonated metal with dry ice" (Hearthstone). SOURCED: [Blizzard](https://hearthstone.blizzard.com/en-us/blog/23964694/).
  - Electricity: arcs, discharges and a low thump. SOURCED: [Designing Sound](https://designingsound.org/2011/01/13/tonsturm-releases-electricity-sfx-library-qa-included/).
- **A palette per character.** Riot gives each champion a sonic palette that all its spells share, and makes a sound's clarity match its importance. SOURCED: [Riot](https://www.leagueoflegends.com/en-gb/news/dev/ask-riot-let-s-talk-clarity/). **Ours:** each Voidkin's kit shares a palette, and its class and element set the palette's base.
- **Anime.**
  - Fire Force's sound effects are by Yasumasa Koyama, also of JoJo's Bizarre Adventure and Dr. Stone. SOURCED: [ANN](https://www.animenewsnetwork.com/encyclopedia/people.php?id=57426). Nothing is written about its fire sounds.
  - Koyama works with very low bass for weight, dubstep, trap and 80s-synth tones, and near-silence on slow motion. He notes that weak speakers lose his bass. SOURCED: [Febri interview, 2022, translated](https://jojowiki.com/Interview:Febri_(September_2022)).
  - The classic anime kit: a phaser, a harmonizer and a synthesizer for an aura, sounds reversed, short sounds tuned to the music's key, and "the lie's sound" over reality (Fizz Sound Creation). SOURCED: [CEDEC 2011](https://gigazine.net/gsc_news/en/20110911_anime_soundeffect_cedec2011).
  - Anime keeps a "hard FX" family for unreal sounds, the shing and the zing. Sounds enter one at a time, and the mix stays lean, with quiet after a battle. SOURCED: [AV Watch, 2025](https://av.watch.impress.co.jp/docs/topic/2062061.html), [Yasunori Honda](https://www.philipbrophy.com/projects/cinesonic/yasunorihonda.html).
- **Pro, not stock:** eight checks on every pick.
  1. Layers, each with a role in its band.
  2. A shared palette.
  3. Variation, with a cap on repeats.
  4. Ducking by priority.
  5. No silence at the file's head.
  6. Weight carried by harmonics a phone can play.
  7. Headroom: true peak under −1 dBTP.
  8. Reward and UI sounds in the music's key.
  - The sources are above, and Sony's loudness slides for headroom. Pitch spread and tight heads are UNVERIFIED (practitioner guides).

**Six recipes,** layer roles SOURCED as cited, lengths UNVERIFIED (the ear accepts them):

| Cue | Layers | Processing |
|---|---|---|
| Light hit | a snap (10–30 ms), a mid body (80–150 ms), a spark tick (~100 ms) | sharp transient, no sub; pitch and volume spread; 3–5 takes |
| Heavy hit | a riser or a brief silence (100–250 ms), then 3–8 micro-impacts in under 1 s, a kick body with highs cut, a dry sub (300–500 ms), a metal top, a tail by strength | each layer EQ'd to its band; the sub saturated so a phone hears it; swings and ambience ducked on contact |
| Fire ability | a cast whoosh (300–600 ms), a travel loop, an impact, a darker tail; an aura bed (phaser, harmonizer) | spread on every re-trigger; voice cap; pitched down for weight |
| Frost or storm | frost: a metal-on-ice scrape, a crunch, pings or chimes in reverb, one real layer; storm: an arc crackle, a discharge snap, a low thump | a short reverse swell into the cast; band-limited hiss |
| A Shade bursts | a paper rip (150–300 ms), a distorted cardboard thump as the pop, a bright shimmer tail (400–800 ms), scattered paper ticks | the shimmer in the music's key; short tail so a pack doesn't pile up; voice cap |
| A reward | 2–3 rising tones in the key, on the beat, a crystal sparkle, a soft swell; the reveal: a riser, a short silence, the chime | gentle compression; reverb tail about 1–1.5 s |

## Roblox's rules for sounds we make

- **Library sounds are used inside Roblox only.** Edits are allowed "solely within your game", through Studio's sound properties. No Roblox source permits downloading, editing and re-uploading one, and an upload requires that we hold its rights. SOURCED: [Roblox, 2018](https://devforum.roblox.com/t/upcoming-music-changes-and-copyright-related-action/130570), [audio assets](https://create.roblox.com/docs/audio/assets). **So "mix if needed" means layering at runtime:** several library slices, pitch, EQ and timing through the audio graph. Only material we hold the rights to is mixed offline and uploaded.
- **Uploading our own sounds is free:** .ogg, .mp3, .wav or .flac, under 7 minutes, up to 48 kHz. The quota is 2,000 a month for an ID-verified uploader per the audio page, and 100 per the Open Cloud guide, so read the real number from the quota endpoint. An upload can't be updated in place: a fix is a new id. SOURCED: [audio assets](https://create.roblox.com/docs/audio/assets), [Open Cloud usage](https://create.roblox.com/docs/cloud/guides/usage-assets).
- **Copyright takedowns are final,** with no appeal. SOURCED: [Roblox staff](https://devforum.roblox.com/t/editing-copyrighted-audio/2176521). Every sound sits behind one Config id.
- **Roblox's own showcases layer at runtime,** from field recordings and synthesis, mixed through sidechained groups. SOURCED: [Beyond the Dark](https://create.roblox.com/docs/resources/beyond-the-dark/sound-design). SoundGroups are now discouraged in favour of audio objects. SOURCED: [docs](https://create.roblox.com/docs/sound/groups).
- **Roblox has no sound-effect generator,** only text-to-speech. SOURCED: [docs](https://create.roblox.com/docs/ai/accelerated-workflows).

## Tools and making our own

- **Audacity isn't needed.** 4.0 removed scripting, so it's a tool for a human's hands only. SOURCED: [4.0.0 notes](https://www.audacityteam.org/changelog/4.0.0/).
- **The toolset that needs no human at the controls:** Python, already installed, plus these from PyPI with no account:
  - numpy and scipy (BSD): synthesis, filters, spectra.
  - Spotify's pedalboard (GPLv3): compression, limiting, saturation, filters, reverb, pitch and time, reading and writing OGG and MP3. No VST plugins.
  - pyloudnorm (MIT): loudness.
  - Optional: FFmpeg, whose Windows builds come from third-party builders linked by ffmpeg.org.
  - SOURCED: each package's PyPI page, as read on 2026-11-15.
- **Synthesis is good for some layers, poor for others.** A sound engineer at Sony: a "very convincing wind" from filtered noise, but for realistic physical sounds "very few models would support a blind test with recordings". Pros mix synthesis and recordings. SOURCED: [Designing Sound, 2012](https://designingsound.org/2012/06/04/procedural-audio-an-interview-with-nicolas-fournel/). **Ours:** library recordings carry the realism (the impact's body, paper, cloth, steps). Our own code makes the sub, the whooshes, risers, shimmers, the aura, arcs, the UI and the Breaker's hum. They're layered at runtime.
- **Local AI sound models don't meet the director's conditions.** The ones whose licence allows a monetized game (Stability's Stable Audio Open and Stable Audio 3 Small SFX) are downloaded behind an account, and their free licence ends past $1M a year in revenue. The rest are non-commercial (Meta's AudioGen, Sony's Woosh, MMAudio, TangoFlux, AudioLDM2). SOURCED: each model's card or licence, as read on 2026-11-15.

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

1. **The director:**
   - the change to rule 2: sounds made by us on the PC, restated in research's chat on 2026-11-15 and waiting on the yes;
   - each install (numpy, scipy, pedalboard, pyloudnorm);
   - whether a test of six cues goes first, after Faber's HUD.
2. **The test, six cues:** a Shade's swipe, its hurt and its burst, and a light hit, a heavy hit and a critical. Each is a stack of library slices layered at runtime, plus Modulo's synthesized layers once the rule's yes is in. Five candidates each, for the director's ear in a fight. If it still sounds like slop, the approach changes before the other 39.
3. **Faber:**
   - the steps test in our place;
   - `tools/studio/Audio` moved to `SearchAudioAsync`, with each result's creator and a playability check;
   - layers on one clock through the audio graph, with a priority duck.
4. **Research:** each test cue's brief, from the recipes above, in the piece's entry when it opens.
