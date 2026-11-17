# Sound: how we make it good

Research, 2026-11-15, on the director's two asks (`docs/decisions.md`, 2026-11-15: "the game lack environnement sfx ... we should study how to make good sfx like jujusu infinite"; then "research about pro sfx, anime sfx like fire force, pro roblox dev sfx and if we need an app such as audacity"). The studio's method stays `handbook/visuals/audio.md`; this file is what the game needs and the changes to how we pick. Labels: SOURCED (read at the link), UNVERIFIED (nobody acts on it yet). Nothing here is tested in Studio.

**Updated 2026-11-17, 00:39,** after the director's phone run (`docs/decisions.md`, by 00:17: "no SFX that add depth" and "do deep research on how to make SFX in a game what need or dont FOR A roblox anime games"). Two read-only studies added what's worth what, music, phone speakers, what to skip, and the engine's facts since. Studies of excerpts only say so.

## Where we are

- **Nine cues in the whole game:** Haymaker's strike and the reveal's eight (`src/shared/Config/Sounds.luau`, `docs/asset-log.md`). Every other moment is silent: steps, the Shades, every other attack, the grounds, the base, the screens.
- **Every pick was made by measure.** No teammate can hear, so a waveform's shape chose each one and no ear accepted it. The director's verdict: "meh", and on 2026-11-14 "Horrendous".
- **Made and never heard:** Modulo's 33 takes for the six-cue test (`docs/asset-requests.md`, AR13). Their upload waits on the director's word.
- **No music at all,** and no volume setting. Pass 1 had neither (corrected below).
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
7. **Phones are the target.** A phone speaker gives very little low end, so weight has to live above it. Modern phones struggle under 200 Hz and roll off fully by 100 Hz. A bass's growl and knock lives at 250 to 700 Hz, and saturation adds harmonics EQ can't (SOURCED, a vendor guide: [LANDR](https://blog.landr.com/make-bass-audible-phone-speakers/)). Older Androids measured rolled off from about 1 kHz, an iPhone 7 Plus from about 400 Hz (SOURCED, excerpt: [Audiokinetic](https://www.audiokinetic.com/en/community/blog/loudness-and-frequency-response-on-popular-smart-phones/)). A phone's amplifier cuts deep bass near its limit, so a hit heavy in sub-bass comes out quieter overall (SOURCED, excerpt: [Electronic Design](https://www.electronicdesign.com/technologies/analog/article/21805959/make-your-audio-system-sound-better-with-smart-amp-technology)). The ear hears a missing low note from its harmonics (SOURCED, abstract: Larsen and Aarts, *JAES* 2002). **Ours:** every cue's weight sits at 250 to 700 Hz with a sharp attack. Sub-bass is only ever a saturated extra layer. Nothing important rides on panning, and tails stay short, their reverb cut below 200 to 400 Hz. The director's acceptance pass is on a phone, with the iPhone's silent switch off: users report it mutes Roblox.
8. **Loudness has a target.** Sony's guidance was −18 LUFS for portable devices, ±2 LU. SOURCED: [Designing Sound, 2012](https://designingsound.org/2012/07/30/video-games-and-loudness-standards-interview-with-sonys-garry-taylor/). ITU-R BS.2434 (2018) says the same for portable game devices (SOURCED, excerpt). **Ours:** the handbook's levelling to −14 dBFS per cue stays. The whole mix's level is measured offline, as the reveal's was.

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

## What sound is worth, music, and what we skip (2026-11-17)

- **Sound raises how good the picture looks.** In a study of 108 people, better audio raised the perceived quality of the same visuals. SOURCED (abstract): [Storms and Zyda, *Presence*, 2000](https://calhoun.nps.edu/entities/publication/1be1a67d-88bc-433f-908d-0914c080de2e). So the director's "far to look like a game" is partly a sound finding.
- **Effects carry the feel; music adds to them.** Turning effects off changed every dimension of the Game Experience Questionnaire. Music only worked with them, on tension and flow. SOURCED: [Nacke, Grimshaw and Lindley, 2010](https://ub-ir.bolton.ac.uk/esploro/outputs/journalArticle/More-than-a-feeling-Measurement-of/999710108841), one shooter study.
- **Sound alone doesn't keep players.** In two casual games, removing music and effects had little or no effect on play time; animation did. SOURCED (abstract): [Andersen et al., CHI 2011](https://grail.cs.washington.edu/projects/game-abtesting/chi2011).
- **Most mobile players say they play muted:** 91% of 2,400, self-reported, casual-heavy. Young players with long sessions keep it on most. SOURCED: [TapResearch, 2022](https://blog.tapresearch.com/how-sound-preferences-impact-player-engagement). **Ours:** sound never carries anything a player needs. A Shade's tell also shows.
- **Win sounds inflate how big a win feels** (players overestimated their wins 24% against 15%). SOURCED: [Dixon et al., 2014](https://pmc.ncbi.nlm.nih.gov/articles/PMC4225056), a slot-machine study. **Ours:** a Common reward stays small. Sound never dresses a paid roll (rule 4).
- **The genre ships sound as a feature.** Anime Vanguards' Update 5 listed a new soundtrack, and Blox Fruits 17.3 "Footstep sounds have been added". SOURCED (excerpts): [Sportskeeda](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-5-patch-notes), [the wiki](https://blox-fruits.fandom.com/wiki/Updates/17.3). Roblox's own Park template runs one bed loop with 27 bird calls, 6 rustles and 6 gusts fired at random over it. SOURCED: [DevForum, 2025-02-25](https://devforum.roblox.com/t/3507022). Licensed anime games lift the show's own sounds, which is closed to us: our anime feel comes from craft.

**Music** (new: pass 1 had none).
- **Why now:** a silent world reads as unfinished, and licensed tracks cost an afternoon. Per hour, it's the most "real game" we can add. INFERRED.
- **Where from:** Roblox's licensed music. APM since 2018 ("royalty free for use on the Roblox platform"), DistroKid since 2024-09-19, and Too Lost since 2026-07-27. SOURCED: [2018](https://devforum.roblox.com/t/130570), [2024](https://devforum.roblox.com/t/3164792), [2026](https://devforum.roblox.com/t/4760221). Search with `AudioSubType = Music`. Rule 2's "Roblox's audio library" covers it.
- **The terms,** quoted on the forum from the Terms of Use, 5.a.iii: up to 250 licensed tracks in one game at a time, no "streaming service or music library" inside it, and never charging to hear a track. SOURCED (forum quote, 2024-12-15): [DevForum](https://devforum.roblox.com/t/3305661). The Terms and the help page refused fetching. No line excludes monetized games, and none says they're included: INFERRED allowed. Never a jukebox, a radio or a paid track.
- **Trailers** need music of their own: community answers say the licence is in-game only (no staff reply, 2018).
- **Ours:** a base track, a grounds track and a keeper track, crossfaded per place, on their own fader. It ducks under the reveal (TR4) and under signatures, never under ordinary hits. Each has an alternate in Config, since licensed tracks have been blocked by mistake (forum, 2023). The track picked sets the key the reward sounds wait on (AR13's A and E). Never a track that sounds like a known anime score (rule 3).
- **Its own effects in the music's key:** Hi-Fi Rush's "Inst FX" gives attacks musical sounds (SOURCED, excerpt). **Ours:** a signature's hit carries one pitched layer in the key, after the reward sounds.
- **Later, not now:** music that adapts to play. Zenless Zone Zero adds a rap section to the pull's music when an S-rank is coming (SOURCED: [interview, 2026-02-13](https://playday.one/2026/02/13/1v1-an-interview-with-san-z-studio-on-the-sounds-of-zenless-zone-zero)). Swapping to the keeper's track gives most of it.

**What else the anime feel takes:**
- **Near-silence before a hit** makes it feel louder at the same level. On a phone, contrast is the only way to make a hit bigger without clipping. SOURCED, a trailer guide (excerpt); Rob Bridgett's chapter on dynamic range and silence.
- **Misses get whooshes too,** since most of a fight is things not connecting.
- **The anime bass drop** is a saturated knock with a hard attack on a phone, never sub-bass.
- **No sample twice in a row:** random with no immediate repeat. SOURCED: [MusicRadar](https://musicradar.com/tuition/tech/how-to-avoid-the-machine-gun-effect-using-round-robin-sampling-632302).

**What we skip:**
- **Voices.** Speech can't be published as a sound effect, actors cost money, and voices risk imitation.
- **Steps for every surface.** That's Celeste's, a platformer where movement is the game. Ours fights on its own: one set per place.
- **Others' fights at full volume.** From another player's lead, only its hits and bursts play, about 10 dB down, under the voice cap. Every relay is rate-limited by the server.
- **A jukebox,** acoustic simulation (frame time on phones), and music that adapts beyond the keeper's swap.
- **No mute:** Music and Effects get their own sliders, which players ask for (SOURCED: [DevForum](https://devforum.roblox.com/t/320826)).

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
- **ElevenLabs (read 2026-11-17, 14:00, on the director's ask: "look up if eleven labs could be a geniune source of high quality sfx or if i need to curate roblox sfx library"):** a cloud generator, used through an account on its website.
  - **Licence:** its own pages say the free plan requires credit to elevenlabs.io and paid plans don't. Third-party guides of 2026 say the free plan carries no commercial licence at all, and that the cheapest plan with one costs about $6 a month, covering only what's made while subscribed. SOURCED, the vendor: [sound effects, commercial](https://elevenlabs.io/sound-effects/commercial). UNVERIFIED, the guides: [bigvu](https://bigvu.tv/blog/elevenlabs-pricing-2026-plan-worth/), [dupple](https://dupple.com/learn/is-elevenlabs-free).
  - **Quality:** the praise found is the vendor's own, plus one reviewer's impression of a version not named. No measured or blind comparison with a licensed library was found. UNVERIFIED.
  - **Against our rules:** it breaks rule 2's terms for our own sounds (no website, sign-up or account). Clean commercial rights also cost money (rule 1). Using it means changing the core, which only the director's yes to a restatement can do.
  - **Research's recommendation: curate Roblox's library.** It holds more than 100,000 professionally produced sounds from licensed partners, free, under today's rules ([audio assets](https://create.roblox.com/docs/audio/assets)). What failed before was the process, not the source: one blind pick per cue. The method above fixes that: five candidates per cue, levelled, picked by the director's ear in a fight, layered at runtime, with our own synthesis for the sub, whooshes and UI.

## Long ultimates: phases that hold as one piece

Research, 2026-11-17, 14:20, on the director's worry: "a long ultimate skills that require a well mixed up phases of sfx that fit perfectly and well timed should we do more study on this?". It's a web study by a research agent, its own pages read. **The gap:** no developer has written how a Street Fighter 6, Guilty Gear, Tekken, Genshin, Star Rail or Zenless ultimate's sound is built, in English, Japanese or Chinese. Anything about those games is UNVERIFIED.

**Timing is the solved half.** Each phase's sound plays on the clip's own marker, as the effects already do. Roblox's `AudioPlayer:Play(atTime)` can be scheduled against `SoundService:GetMixerTime()`, "for sample-accurate, framerate-independent timing", and `Cancel()` withdraws a scheduled play. A client's animations replicate, so each client plays the phases from the markers it sees, with no message per phase. SOURCED: [AudioPlayer](https://create.roblox.com/docs/reference/engine/classes/AudioPlayer.md), [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator.md).

**The arrangement is the hard half.** What the sources say:
- **One family per fighter, in one key.** Riot keeps a champion's whole kit, its ultimate included, in one palette: Ahri's fox, Teemo's pentatonic scale, Kindred's aquaphone. A kit's identity lives in each ability's first second. SOURCED: [Riot](https://www.leagueoflegends.com/en-gb/news/dev/the-frequencies-of-folklore/). **Ours:** each Voidkin gets a key and a motif, so a multi-hit steps up the scale and still reads as one phrase.
- **A bed under the whole ability, and a mix state for its length.** Apex's Bloodhound ultimate plays a drone of breaths and synths throughout, raises enemies' sounds and lowers his own. SOURCED: [A Sound Effect](https://www.asoundeffect.com/apex-legends-sound/). Mortal Kombat 1 ducks so "each hit punches through", and puts both fighters' screams on the climax. SOURCED: [A Sound Effect](https://www.asoundeffect.com/mortal-kombat-1-game-audio/).
- **Tension:** a Shepard tone keeps rising for any length (The Dark Knight's Batpod, Dunkirk), so a charge of varying length can loop and still climb. SOURCED: [Wikipedia](https://en.wikipedia.org/wiki/Shepard_tone).
- **Silence before the hit:** "a beat of silence just before the impact" ([Sound On Sound, 2013](https://www.soundonsound.com/techniques/sound-design-visual-media-radio)). The mix itself can make it: the big sound's envelope ducks everything just before it lands ([Designing Sound, 2013](https://designingsound.org/2013/06/21/finding-your-way-with-high-dynamic-range-audio-in-wwise/)). SOURCED.
- **Fewer, bigger layers.** Gundam: The Origin's sound effects lead: "if you put in too many tiny sounds, it actually feels like something's off." SOURCED: [interview](https://www.gundam-the-origin.net/en/special/interview39.html).
- **The phases build by width, not volume:** the wind-up narrow, the hits wider, the sub held back for the finale, which is the only full-band moment, under a master limiter. UNVERIFIED, common practice.
- **Several ultimates at once:** Overwatch ranks other players in the mix by their threat to the listener. SOURCED: [PCGamesN](https://pcgamesn.com/overwatch/overwatch-devs-on-creating-a-game-you-can-play-by-sound-and-announcing-dolby-atmos-support). **Ours:** your own ultimate and anything hitting you on top; other players' thinned to their claim and finale.
- **Cancels:** a sound fired from an animation plays on after a cancel unless it has its own stop ([Unreal forum](https://forums.unrealengine.com/t/how-to-stop-sounds-played-with-notify-playsound-in-animinstance/362986)). In slow motion the start and end keep normal speed, and impacts swap to slow takes rather than being pitched down alone ([CRIWARE, 2024](https://blog.criware.com/index.php/2024/06/03/bullet-time/)). SOURCED.
- **An outcome waits for the server.** Street Fighter 6 delayed its commentary 0.3 s so rollback couldn't make it "lie". SOURCED: [Den Faminico Gamer, CEDEC 2023](https://news.denfaminicogamer.jp/kikakuthetower/230824s/2). **Ours:** a kill or break sting waits for the server's word; the phases play off the local clip.
- **Roblox's tools for it:**
  - `AudioCompressor` has a sidechain and an attack down to 0.1 ms, fast enough to duck under a hit. The old `CompressorSoundEffect` can't go under 0.1 s.
  - `AudioLimiter` is there for the master.
  - `LoopRegion` loops a bed of any length from one file.
  - SOURCED: [AudioCompressor](https://create.roblox.com/docs/reference/engine/classes/AudioCompressor.md), [AudioLimiter](https://create.roblox.com/docs/reference/engine/classes/AudioLimiter.md).
- **Roblox's known traps,** from forum reports with no staff answer:
  - a marker on a clip's last frame occasionally doesn't fire, so cleanup goes on `Stopped`;
  - `PreloadAsync` does nothing for an `AudioPlayer`, so keep it parented and check `IsReady`;
  - a start delay of about 0.1 s was reported and never resolved.
  - **Faber measures our own start delay before any frame-tight cue is trusted.** SOURCED as reports: [2088994](https://devforum.roblox.com/t/2088994), [4819196](https://devforum.roblox.com/t/4819196), [2961664](https://devforum.roblox.com/t/2961664).
- **Music, cheapest first** (DESIGN; our music isn't on a beat):
  1. duck it under the ultimate and let it come back after;
  2. the same, with one sting in the fighter's key on the finale;
  3. a hard cut at the drop-out, for a signature only.

**The cue sheet,** one per ultimate, filled before its sounds are picked (DESIGN, from the above; numbers are seeds for the ear). Its head sets the length, key, motif, bed, music option, which cues wait for the server, and what a cancel does.

| # | Phase | Marker | Enters | Leaves | Pitch, rhythm | Notes |
|---|---|---|---|---|---|---|
| 0 | Claim | `ult_claim` | voice or motif sting | | the root | reads in its first second; others hear only this and the finale |
| 1 | Charge | `ult_charge` | the bed (looped), a riser | | rising, pulses quickening | no sub yet |
| 2 | Release | `ult_release` | the release's snap, a whoosh | the riser | a jump to the fifth or octave | narrow band |
| 3 | Hits or travel | `ult_hit_N` | one layer per hit, takes in turn | | a step up the scale per hit | each hit its own event, so the count can vary |
| 4 | Drop-out | `ult_drop` | an inhale, optional | the bed, the tails, the lows | | 4 to 15 frames of near-silence; skipped under 4 |
| 5 | Finale | `ult_finale` | the full band: impact, sub, voice | | back to the root | the only full-band moment; its outcome sting waits for the server |
| 6 | Aftermath | `ult_tail`, never the last frame | tail, debris, the bed resolving | everything else | the root | ducks release over 1 to 2 s; cleanup on `Stopped` |

**A cancel:** in phases 0 to 1, the bed and riser fade out over 80 to 150 ms and a short fizzle in key plays. In 2 to 3, the scheduled hits are cancelled and the last hit's tail stays. From 4 on, the ultimate is committed and plays out.

**What this means for the worry:** the risk is real, but it's a method, not luck. A sheet per ultimate fixes the phases before any sound is chosen. The director's samples calibrate each family, and the director's ear picks each layer inside its phase. Then the ultimate is heard whole, in a fight, from a phone. **The first test** is one ultimate taken end to end through the sheet when the Voidkin work resumes. It's judged by the director before the sheet is used for the rest.

## Picking by the director's ear

- **Search every author** (the director, 2026-11-15). Rule 2's order stays a preference: Roblox and its licensed partners first in the ranking. Any author's sound is taken when it's the best by ear. It's logged with its uploader, and gets a licensed alternate where one exists, so a claim is a one-line swap.
- **Lower risk:** Roblox, its partners, and sound effects published since 2024-05-23, which passed Roblox's copyright detection and moderation, with an ID-verified distributor. SOURCED: [Roblox, 2024](https://devforum.roblox.com/t/public-sound-effects-upload-are-now-available-for-creators/2980704). **Higher risk:** old anonymous uploads, and titles that name a commercial library or another work. The second is already filtered out by the shortlist.
- **Check that each one plays.** A search returns sounds our game can't play (Roblox staff, 2025-01-10, "intended"). SOURCED: [DevForum](https://devforum.roblox.com/t/assetservicesearchaudio-provides-results-that-cant-be-played-in-experience/3364668). Every candidate is loaded in our place before it reaches the director. Since late January 2025 public uploads and Creator Store free audio play without being added to the game (SOURCED, staff: [DevForum, 2025-01-30](https://devforum.roblox.com/t/3375062)), so fewer fail, and the check stays.
- **Our group's own uploads need a grant.** A game needs permission to use an audio asset, or it's silent at runtime. A grant is permanent. Staff said in 2023 that group games get no automatic grant. SOURCED: [asset privacy](https://create.roblox.com/docs/projects/assets/privacy), [DevForum](https://devforum.roblox.com/t/2502005). **Ours:** each uploaded cue is granted `Use` to universe 9093907961, and the grant is read back. The bulk API (`asset-permissions-api`, beta) needs a key scope only the director can add.
- **Studio passing isn't proof.** A moderated sound loaded on the server and played nothing on a live client in a group game. SOURCED: [DevForum, 2025-02](https://devforum.roblox.com/t/3464632). **Ours:** a live client checks every cue id (a preload's `Failure`, or an analyzer's peak above 0) after each publish, which also catches a claimed or deleted library sound.
- **Loudness matched before every comparison,** because the louder candidate tends to win (practitioners; INFERRED weight high). A one-shot under 0.4 s is levelled by its RMS or its loudest 0.4 s, never integrated loudness, which needs 0.4 s (EBU Tech 3341, pyloudnorm).
- **The board, for the ear:** candidates under random letters, never titles. The current cue is hidden among them, one deliberately poor candidate too, and "none" is a choice. One earlier pair comes back to check the picks agree, and a phone switch puts a high-pass near 300 Hz on the mix. Each pick is logged, all in a looping fight beat. Borrowed from ITU-R BS.1534's hidden reference and anchor; research's proposal, untried.
- **Search:** `AudioSearchParams` takes up to 100 a page, sorts by use, trend or date, and still has no uploader filter. Each result carries its creator and whether it's verified, and its `CreateTime` marks the lower-risk uploads by itself. The call has a low rate limit, so it goes in pcall. The Studio MCP's `search_asset` has a price filter: always `"free"` (rule 1). SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/AudioSearchParams).
- **Several candidates per cue, for the ear.** For each cue, research's brief goes to `tools/studio/Audio`, which searches wide and shortlists five by shape. The director clicks through them in the Audition panel during a fight and picks one, or none. A cue is accepted only on that pick.
- **Calibrated by the director's samples** (the director, 2026-11-17, 14:05: "i will help calibrate your tools by showing sample of what good sfx from x family should be ... we will likely keep upgrading it"; research agrees). This replaces the anchors' proposal.
  - **The samples:** for each family (a hit, a whoosh, a UI tap, a step...), three to five good ones that span the styles wanted, plus one or two that are wrong. A Roblox asset id is best, since the tool measures it in place. Each good sample is its own anchor, so a family with two styles keeps both: a candidate is ranked by its nearness to the closest anchor, never to the family's average.
  - **The tool's first upgrade:** today it measures only attack, tail, length and three bands (`tools/studio/Audio/Briefs.luau`), which can't tell one style of hit from another. It gets a richer fingerprint: more bands, brightness over time, noise against tone, and the envelope's shape. A family's brief is then measured from its samples, not written by hand.
  - **The measure of the tool:** how often the director's pick is in the shortlist of five, counted per family. A family whose pick is missing twice gets more samples or a tool upgrade, as the director said.
  - **A family with no sample:** it borrows the nearest family's anchors and the craft rules above, and its shortlist is flagged as uncalibrated. A miss there asks for samples first.
  - **What it can't do:** no teammate hears. The tool shortlists by measure, and only the director's ear accepts a sound.
- **A reference by numbers, if the director wants it:** 30 s of combat from the director's example, recorded by the director and kept internal. We measure sound events per action, where the whoosh falls against the contact, and tail lengths. That gives timing, never taste (`handbook/visuals/audio.md`, "Do"). Optional; the ear on our own candidates matters more.

## The engine, for Faber

The builder's calls; these are the facts behind them.

- **The new audio API is released** (out of beta 2024-09-10). The classic `Sound` stays supported. SOURCED: [Roblox, 2024](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454).
  - `AudioCompressor` has a Sidechain pin for ducking. SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/AudioCompressor).
  - `AudioLimiter` responds instantly, where the classic compressor lets a transient through (the handbook's trap). SOURCED: [Roblox, 2024-12](https://devforum.roblox.com/t/3282100).
- **Layers start together** when each gets the same start time: `AudioPlayer:Play(atTime)` with `SoundService:GetMixerTime()` plus about 0.1 s, "sample-accurate, framerate-independent". SOURCED: [the docs](https://create.roblox.com/docs/reference/engine/classes/AudioPlayer), and a Roblox audio engineer, 2026-07-25. That would also answer the handbook's 0.3 s late-start trap differently. Untested by us.
  - Mixer time differs between machines, so each client schedules a cue from a replicated event, never from the server's clock.
  - `Play()` doesn't rewind: it resumes, so a quick replay plays nothing. Staff's fix: `Stop()`, set `TimePosition`, then `Play()` (SOURCED: [2026-07-18](https://devforum.roblox.com/t/4743400)). One player is one voice, so a cue keeps a small pool of loaded players, and the pool's size is its voice cap.
  - Random spread on a one-shot goes through `PlaybackSpeed`, never `AudioPitchShifter`, whose window adds latency off the contact frame.
  - **Level trap:** Roblox doubled AudioPlayer's volume in 2025 (forced 2025-09-29). Level advice for AudioPlayer from before is 6 dB off. SOURCED: [staff](https://devforum.roblox.com/t/3907391).
  - A player with `AutoLoad` loads as soon as its asset is set and may unload under extreme memory pressure: check `IsReady` before scheduling, on phones above all.
  - **Listener trap:** the default listener exists only in games with voice chat. Set `DefaultListenerLocation` to Camera or Character, or emitters are silent (SOURCED: [docs](https://create.roblox.com/docs/audio/objects), staff 2026-04-15).
  - `AudioEmitter:GetAudibilityFor(listener)` reads 0 to 1. Skipping another player's cue under about 0.05 keeps a full server's voices down (INFERRED).
  - The docs now call Sound, SoundGroup and SoundEffect "discouraged" in favour of the audio objects. They still work.
  - **Not yet usable:** `AudioWindSynthesizer`, wind made in the engine (Turbulence, Whistle, Foliage), listed since build 734 with no docs; a candidate for the grounds' wind once released. `AudioStreamWriter`, Luau buffers into the graph, Studio only: if it works, the director could hear our synthesized takes in Studio before any upload. Both unverified.
- **Acoustic simulation** (occlusion, reverb) is fully released (2026-09-22) and needs the new API. SOURCED: [Roblox](https://devforum.roblox.com/t/full-release-acoustic-simulation-emit-audio-with-presence/4307121). Not for now: it costs frame time on phones.
- **Steps.** The director hears no steps. Roblox's default character sounds play one plastic step whatever the floor (UNVERIFIED). Games customise them by their own copy of `RbxCharacterSounds`, mapping `Humanoid.FloorMaterial` (SOURCED: [docs](https://create.roblox.com/docs/reference/engine/classes/Humanoid)) to sets. A report of 2026-08-19 says the defaults can't be removed in some games (UNVERIFIED). `SoundService.CharacterSoundsUseNewApi` moves the default character sounds to the new API, and in 2026-04 it broke in older places whose script lacked a child; our copy must match the setting (SOURCED: [DevForum](https://devforum.roblox.com/t/4556965)). **Test first in our place:** are the defaults there and audible, and does our own copy replace them? The Voidkin and the Shades are rigs with no steps at all: theirs come from their walk clips.
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

Music has its own fader beside this list: it ducks under the reveal and the signatures, never under ordinary hits.

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
| Music: base, grounds, keeper | 1 each, an alternate in Config | Roblox's licensed library, picked by ear in a fight, crossfaded per place (2026-11-17) |
| Music and Effects sliders | 2 | in settings; the muted majority and the players who stream (2026-11-17) |

### Pass 2: the rest

- States: stagger's crack, heavy stagger's burst, stun's circling, knockdown's thud, burn, chill and freeze, shock, sap.
- The keeper's entrance, its ring and its fall.
- The lead's fall into light; the next lead sent out.
- The base's bed (a power plant at rest); each bay working; the generator; the battery charging; infusion's surge, Low and High voltage.
- The Festival Door: its hum and the trip.
- The Power screen's handles; an upgrade bought; gear equipped.
- The Voidkin's efforts and voices: a real gap the big games fill (MK1 records 300 to 400 files a fighter). A later piece, once the director wants voices at all.

## Next

The order of work, research's ranking (2026-11-17, 00:39). Rule 2's change was approved on 2026-11-15, and the four packages are in, so pass 1's first steps wait on nothing but the upload.

1. **The six-cue test, heard in a fight** (AR13). It's made. Its upload waits on the director: the 33 files heard first, or up unheard (research's advice). Faber installs it on one clock with the pool and the duck above. The director's ear decides: if it sounds like slop, the approach changes before the other cues.
2. **Music, and the two sliders.** Three tracks from the licensed library, searched as music, loudness-matched, picked by ear. It's the most "real game" per hour.
3. **The screens' family:** tap, open, close, tab, confirm, refused.
4. **The rest of the fight:** whooshes on misses too, impacts by weight, the lead hit, each kit's beats, the Shade set.
5. **Each place's bed with 3 to 6 spot sounds,** and the rewards (shard, level, credits, a shard ready).
6. **Should, after pass 1:** steps (test the defaults first), the Breaker's and the bays' hum, the keeper's entrance and fall, others' fights quieter.

For Faber: the engine's traps above, the grant to the universe and the live check, `tools/studio/Audio` on `SearchAudioAsync` with creators and music. For research: each cue's brief in its entry when it opens.
