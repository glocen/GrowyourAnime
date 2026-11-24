# An audio direction: music, combat, UI and the mix

A research agent in Faber's cloud session, 2026-11-24. It builds on `docs/research/sound.md` (the craft of hits, the engine's traps, the cue list) and doesn't repeat it. Labels: SOURCED (link), COMMUNITY, OBSERVED (our repo), MEASURED (computed), OPINION. "Snippet" means I read a search excerpt, not the page. **Nobody on the team can hear: every number here is a seed for the director's ear, and every proposal is a proposal.**

## Verdict

1. **We have a sound engine and almost no sound.** The fight has about ten cues the director picked. The reveal has eight provisional ones. The screens, the world, the rewards and all five music lists are silent.
2. **The director never rejected sound. They rejected sound made blind:** physical hits synthesised in code ("geniuely horrible"), then library slices stacked by measurement ("comic gibberish"). Their own 63 keeps are all finished, punchy game hits.
3. **The direction proposed: Struck, Glass-lit, Spare.** A hard front on every sound that matters, glass and bell-metal tones in one five-note set for every screen and reward, and few sounds at once with a real silence before the big ones.
4. **It's written so it can be checked without ears** (lengths, pitches, counts, levels), and it spends the director's ear in one sitting of about 20 minutes, not twelve.
5. **Hits are no longer the bottleneck.** The cheapest "expensive" now is music in the lists, a UI family, and ducking and silence around the reveal and the signatures.

## 1. What we have, what's missing, what was rejected

| Area | State | Where |
|---|---|---|
| Fight cues | Light hit 32 keeps, heavy 22, Shade swipe 9, picked by the director on the audition panel, 2026-11-19. Twelve more tabs wait for the director's listen: the five signatures, the Mage's and Healer's casts and hits, and three fighters' own light hits (`docs/team-notes.md`, item 7). | `docs/asset-log.md` (rows of 11-19), `src/shared/Config/Cues.luau`, `Config/Audition.luau` |
| The reveal | Eight cues with a rarity ladder already wired: crack, rung, breath, two splits, name, glint, bed, a −6 dB duck of the world. All "provisional until the director's ear". | `Config/Sounds.luau`, `Config/Reveal.luau` ("Sounds") |
| Music | A working player: five lists (Strip, Base, LanternRow, Keeper, Tower), shuffle, 2 s crossfade, 1.5 s gap, a Music slider. **Every list is empty.** No duck, no filter, no stinger. | `Config/Music.luau`, `Rules/Music.luau`, `Controllers/Main/MusicController.luau` |
| Screens | A press gives a haptic tick and no sound, though `docs/ui.md` asks for "a sound and a haptic". | `src/client/UI/Kit/Button.luau` |
| World, rewards | No ambience bed, no steps of ours, no shard, credits, level or "ready" sound. | `docs/research/sound.md`, "The cues", still open |
| Engine | **Two systems side by side:** the audio graph for fight cues (pooled AudioPlayers, two buses, limiters, the mixer's clock), and legacy `Sound` + `SoundGroup` for the reveal, Haymaker's strike and the music. | `FighterController/Cues.luau` and `Sounds.luau` |
| Tooling | 11 Studio audio tools and 12 Python scripts. | `tools/studio/Audio/`, `tools/audio/` |

All OBSERVED. MEASURED from the asset log: the director's 54 kept hits run 0.25 to 1.39 s, median 0.52 s.

**What the director said** (`docs/decisions.md`):
- 11-14: "Horrendous sound effects". The first nine cues were library slices chosen by waveform.
- 11-15: "the whole SFX that has been used so far is meh"; no steps, no enemy sounds; "there is more author than the 2 you used".
- 11-17, after the phone run: "no SFX that add depth".
- 11-17, 08:00: the 33 synthesised takes (AR13) were "geniuely horrible".
- 11-17, 23:16: AR39's stacked library slices with our support layers were "horrible plain nonsense ... comic gibberish".
- 11-17, 23:24, the decision that stands: every cue is one finished library sound, played whole, picked by the director's ear. "The team makes and layers none."
- 11-19: "i will put those myself" on the music ids. Five days on, none is pasted.
- 11-23: a sound seat (Sonus) that "shortlists library sounds or makes them on this PC under rule 2"; one M1 sound per class.

**Why it failed, my reading (OPINION):** the team attacked the hardest family first (physical impacts), with the weakest tool for it (synthesis), and judged it by numbers. The directive of 11-17 already said so: synthesis suits "tonal interface feedback", risers, whooshes and energy, not a recorded hit. The tonal families were never tried. That's the gap this note fills.

**Two flags.**
- A few kept titles read like another project's or kit's tag (the asset-log rows of 11-19). Rule 3 bars sounds from other Roblox games, and a claim silences a sound. PLAUSIBLE, not confirmed: a content check decides, and each cue should keep one licensed-partner alternate.
- The director is the only ear and the busiest person. Any plan that needs them more than once a week will stall, as the music has.

## 2. The craft, beyond `sound.md`

- **Loudness for phones.** Portable target −18 LUFS ±2, true peak −1 dBTP, loudness range under 20 LU (SOURCED, snippet: [Audiokinetic](https://www.audiokinetic.com/en/mastering-a-game-with-wwise-part1)). The Game Audio Network Guild's mobile figure is −16 LUFS ±2 (COMMUNITY, a secondary table: [voxbooster](https://voxbooster.com/blog/game-loudness-lufs-compliance-statistics-2026/)). **For us:** a 60 s fight measured by `tools/studio/Audio/Loudness` lands at −18 to −16 LUFS; today nothing sets the whole mix's level.
- **UI sound is restraint.** Microsoft's guide: "mid to high frequency (600 Hz to 2 kHz)", "short (less than one second)", "The more often a sound is played, the less obtrusive it should be", "Don't repeat a sound more than two times consecutively", and "Design the sounds ... to feel like they are related variations on a theme". "The ideal sound effect is one that users barely notice, but they would miss if it were absent." SOURCED: [Windows sound guide](https://learn.microsoft.com/en-us/windows/win32/uxguide/vis-sound). 600 Hz to 2 kHz is also what a phone speaker plays best (`sound.md`, item 7). **For us:** the UI family below sits in that band and rate-limits itself.
- **A family is built from timbre, register and rhythm,** and rhythms should differ by their number of notes; up to six notes a second stay readable. SOURCED, snippet: [Glasgow earcon guidelines](https://www.dcs.gla.ac.uk/~stephen/earcon_guidelines.shtml). **For us:** one timbre for every screen; meaning is carried by note count and direction (one tick, two up, two flat).
- **Pitch that climbs is a reward by itself.** Peggle raises the pitch of each peg hit as a shot hits more pegs (SOURCED, snippet: [the patent](https://patents.justia.com/patent/8398476)). Its sequel plays the hits as ascending scales that follow the music's harmony, and "escalating pitch over time on the same sound" gave variety with no new asset (SOURCED, snippet: [G.A.N.G.](https://www.audiogang.org/peggle2-sonic-joy/)). **For us:** one uploaded tone plays a whole ladder through `PlaybackSpeed`: credits counting, a bar filling, a combo, the reveal's rungs.
- **Don't spend the reveal early.** Overwatch's team cut an early light show because the hint "killed your anticipation"; anticipation was built from animation, camera, spinning plates and sound (SOURCED, snippet: [PC Gamer](https://www.pcgamer.com/behind-the-addictive-psychology-and-seductive-art-of-loot-boxes)). **For us:** the tell comes in the last half second, and the silence before the split is longer the rarer the pull.
- **Duck by band, not only by volume.** Baldur's Gate 3 found volume-only ducking gave a pumping, "EDM-like" mix and moved to frequency-based side-chaining (SOURCED, snippet: [Audiokinetic](https://www.audiokinetic.com/baldurs-gate-3-rolling-for-audio-alchemy)). Write down what must always be heard, route by bus, and cap voices per category (COMMUNITY: [bugnet](https://bugnet.io/blog/how-to-mix-game-audio-so-nothing-drowns-out)). **For us:** in fight places the music loses 3 dB of mids, where hit bodies live, rather than its whole level.
- **Adaptive music is two moves:** swap segments (horizontal) or add and remove layers (vertical); a stinger is a short phrase over the music that marks an event; short loops in long contexts tire quickly (SOURCED, snippets: [Berklee](https://online.berklee.edu/takenote/?p=14985), [a thesis on Winifred Phillips's book](https://etheses.whiterose.ac.uk/27365/1/Chapters/Chapter%203/Chapter%203.html)). **For us:** library tracks have no stems, so vertical layering is closed. Ours is swaps, filters, stingers of our own, and gaps.
- **Festival music, in general terms.** A bamboo flute (shinobue) carries the tune; a big drum, a small tight drum and a hand gong (atarigane) keep time (SOURCED: [Kodo](https://www.kodo.or.jp/en/kodo_blog_en/40051), [a culture wiki](https://japanese-wiki-corpus.github.io/culture/Matsuribayashi.html)). **For us:** "festival instruments over a night-electronic bed" is the music's identity, and the hand gong's bell-metal ties it to the UI palette. That's a genre, not any work's score (rule 3).

## 3. Roblox's audio in 2026

- **Uploads are free, with a quota:** 2,000 audio assets per 30 days for an ID-verified uploader, 100 otherwise; .mp3, .ogg, .wav or .flac; under 20 MB, 7 minutes, 48 kHz. No paid tier is offered on the page. SOURCED: [audio assets](https://create.roblox.com/docs/audio/assets). **Rule 1:** if a quota ever runs out, wait; never buy.
- **Permission.** A restricted asset is silent unless the game has a grant: "the asset is not visible or audible during runtime". A grant is permanent. SOURCED: [asset privacy](https://create.roblox.com/docs/projects/assets/privacy). That page says audio has "its own creation defaults" and doesn't state them, so `sound.md`'s rule holds: grant each upload to the universe and check it on a live client.
- **Songs versus sound effects.** An upload is classed as one or the other. An eligible song shows on the game's details page by default, with a 15 s preview and a toggle on its Configure page; sound effects never do. SOURCED, staff: [DevForum, 2026-07-27](https://devforum.roblox.com/t/4760221). **For us:** class our stingers as sound effects, and expect the page to show the top library songs we play.
- **The licensed music keeps growing:** Too Lost (2026-07-27, "thousands of new songs"), then Symphonic (announced 2026-11-12, "now available in the Roblox Creator Store"). SOURCED: the staff post above; [Music Business Worldwide](https://www.musicbusinessworldwide.com/symphonic-inks-deal-to-bring-hundreds-of-thousands-of-songs-to-roblox/). These are released songs, mostly with vocals. APM's production music is the kind written to sit under action. OPINION: search APM first.
- **Search has thin metadata.** `AudioSearchParams` has Album, Artist, AudioSubType, MinDuration, MaxDuration, SearchKeyword, SortType, Tag, Title and MaxPageSize, with no descriptions. There's no key, tempo or genre field. SOURCED: [the class page](https://create.roblox.com/docs/reference/engine/classes/AudioSearchParams). Whether `Tag` carries genre is untested.
- **Two APIs.** "Sound, SoundGroup, and SoundEffect objects are now discouraged in favor of the more robust functionality of audio objects." SOURCED: [audio objects](https://create.roblox.com/docs/audio/objects). Staff: a SoundGroup is "essentially just a chain of audio effects", replaced by wired objects ending in an `AudioFader`. `AudioLimiter` "responds immediately". SOURCED: [DevForum, 2024-12-02](https://devforum.roblox.com/t/3282100).
- **AudioPlayer:** Volume 0 to 10, PlaybackSpeed 0 to 20, `LoopRegion` and `PlaybackRegion` in seconds, `Play(atTime)` on the mixer's clock, `AutoLoad`, and `IsReady`, which can fall back under "extreme memory pressure". SOURCED: [AudioPlayer](https://create.roblox.com/docs/reference/engine/classes/AudioPlayer). **For us:** `LoopRegion` loops the clean middle of a song that wasn't written to loop.
- **Global settings split by API.** `AmbientReverb` "does not affect AudioPlayers or AudioEmitters"; `RolloffScale` and `VolumetricAudio` are described for Sounds; an emitter uses its own `DistanceAttenuation` curve. SOURCED: [SoundService](https://create.roblox.com/docs/reference/engine/classes/SoundService). Acoustic simulation needs the new API and stays off for phones (`sound.md`).
- **No official voice limit was found.** One community benchmark reports cut-outs between 501 and 1,000 playing Sound instances on a PC; another developer guesses 50 (COMMUNITY, no staff reply: [DevForum, 2025-06-14](https://devforum.roblox.com/t/3736250)). **For us:** the cap is masking on a phone speaker, set by ear, far under any engine limit.
- **Haptics.** `HapticEffect` takes a custom waveform (keys of time in ms and strength 0 to 1) and lists most iPhone, Pixel and Galaxy phones as supported. SOURCED: [HapticEffect](https://create.roblox.com/docs/reference/engine/classes/HapticEffect). `devforum-ui.md`, tip 26, says not to trust phone haptics: a garnish on the heavy hit and the reveal's split, never the only feedback.

## 4. The direction, on one page (a proposal)

**Struck.** Every sound that matters starts with a hard front under 10 ms and carries its weight at 250 to 700 Hz. Nothing swells in softly except a riser.
**Glass-lit.** Screens, rewards and shards speak in one material, glass and bell-metal, in one set of five notes. It's the sound of the shard, so the whole UI sounds like the thing the player wants.
**Spare.** Few voices, short tails, and a true silence before the biggest moments. The HUD is quiet until something matters (`docs/north-star.md`, point 4).

**Palette.**
- **In:** glass and crystal (shards, screens, rewards); bell-metal and a hand gong (confirms, rarity); skin drums and struck wood (weight, the festival); paper and cloth (the Shades); electric hum and arcs (the base, the Breaker); air (whooshes, a flute's breath).
- **Banned:** chiptune bleeps and arcade jingles; cartoon boings, slide whistles and comic stabs (the director's "comic gibberish"); wet or tearing impacts (rule 4); voices and grunts (`sound.md`, "What we skip"); casino coin fountains; trailer "braams" and choirs; guns; a boom that lives under 120 Hz; a reverb tail over 1.5 s; anything that recalls a known show's or game's sound (rule 3).
- **The note set:** A minor pentatonic, A C D E G. As `PlaybackSpeed` steps from one tone on A: 1, 1.189, 1.335, 1.498, 1.782, 2 (MEASURED, equal temperament). No two of these notes sit a semitone apart, so a short tone rarely clashes with a track in another key.

**The mix chart** (dB against the lead's light hit at 0; seeds).

| Bus | Level | Voices on a phone | Ducks under | Its band |
|---|---|---|---|---|
| Lead: your Voidkin's hits, signature | 0, heavy +2 at most | light 3, heavy 2, whoosh 2 | nothing | body 250–700 Hz, front 2–5 kHz |
| Reveal | payoff 0 to +2 | 6 | nothing | full band, the only one |
| Reward: shard, credits, level | −6 | 3 | Reveal | 700 Hz–2 kHz |
| Shades and other players | −4, others' fights −10 | swipe 2, hurt 2, burst 3 | Lead: −3.5 dB for 150 ms (exists) | paper 1–4 kHz |
| UI | −12, a tap −16 | 2 | Reveal | 600 Hz–2 kHz |
| Music | −10 exploring, −12 in a fight | 1, 2 in a crossfade | a signature: −6 dB, 150 ms in, 600 ms out. The reveal: −9 dB from the riser, cut to silence for the breath, back over 1.5 s. Never ordinary hits (TR35). | mids −3 dB in fight places |
| Ambience | −20 | 1 bed, 2 spots | a signature and the reveal: −6 dB | under 1 kHz |

- **About 10 voices audible at once in a fight** (OPINION, a seed). Past the cap, the oldest of the lowest bus stops.
- **The whole mix:** −18 to −16 LUFS over a 60 s fight, true peak −1 dBTP, one limiter on the master.
- **Menus:** with a full screen open, the music takes a low-pass near 1.2 kHz and the world drops 6 dB.

**The UI family:** one timbre (recipes 1 and 5), all under 1 s.

| Event | Length | Pitch rule | Limit |
|---|---|---|---|
| Tap, any button down | 25–40 ms | fixed, three takes in turn | none; 16 dB under a hit |
| Tab or page | 50–70 ms | the tab's place in the row sets its note, left low | |
| Open a screen | 120–180 ms | an upward breath ending on E | |
| Close or back | 100–140 ms | the same downward, ending on A, 3 dB quieter | |
| Toggle, slider step | 40 ms | on goes up a fourth, off down; a slider climbs with its value | 12 a second |
| Confirm: equip, claim | 180–250 ms | two notes up a fifth, A to E | |
| Buy or spend | 250–350 ms | the confirm plus one glass tick | |
| Refused | 120–160 ms | one dull note twice, low-passed, never a buzz | once a second |
| Count: credits, experience | 30 ms ticks | one note up per tenth of the total, ending on the confirm | 15 a second |
| Upgrade or level | 400–700 ms | three notes up the set, the last held | |
| Goal done | 400–600 ms | A, C, E on the hand gong's timbre | |

**Combat, by strength.** One finished sound per cue, as decided on 11-17; the layers are separate cues on the clip's own markers, which `Config.Cues.Own` already has (Beat, Contact).

| Strength | What plays | Variation | Length |
|---|---|---|---|
| Light, M1 | the class's hit on contact | 4–6 kept takes, never one twice running; speed 0.97–1.03; volume 0.9–1; each step of a chain 3% higher, reset at its end | 250–450 ms |
| Medium, a chain's last | a whoosh peaking on the contact frame, then a heavier take | speed 0.95–1.0, 3 takes | whoosh 80–120 ms, hit under 700 ms |
| Heavy, a signature | wind-up or riser; **a dip of 60–100 ms** (the world and music duck from 80 ms before contact); one heavy take; a tail | speed 0.94–1.0, never up; 2–3 takes | hit 0.6–1.1 s, tail under 1.2 s |
| Critical | the hit plus one bright sweetener at 3–6 kHz, 150 ms, +2 dB at most | "better, not louder" (`sound.md`) | |
| A Shade bursts | paper and light, its shimmer on a note of the set | 2–3 takes, 3 voices | under 800 ms |

**The reveal's ladder.** The wiring exists in `Config.Reveal.Sounds`: keep the structure, replace the eight picks by ear. The seeds:

| Rarity | Rungs, the tell | Breath, then silence | Payoff | Tail | Music |
|---|---|---|---|---|---|
| Common | 1 (A) | none | low split, −12 dB | 0.4 s | −6 dB |
| Uncommon | 2 (to C) | none | low split, −10 dB | 0.5 s | −6 dB |
| Rare | 3 (to D) | none; the bed starts | low split, −8 dB, one gong note | 0.8 s | −9 dB |
| Epic | 4 (to E) | 0.5 s swell, 120 ms silence | low split, −5 dB, two notes (A and E) | 1.2 s | cut for the silence |
| Legendary | 5 (to G) | 0.8 s swell, 200 ms silence | full shatter, a drum, the three-note motif | 2 s | cut, back over 1.5 s |
| Mythical | 6 (to A, the octave) | 1.2 s swell, 300 ms silence | the shatter slowed to 0.9, a low knock, the motif an octave wider, an aftershock at +400 ms | 3 s | cut, back over 2.5 s |

- The rungs climb the note set (today they step two semitones each). The first four rungs sound alike for every rarity, so the tell is how far the climb goes.
- A Common stays small and honest. Win sounds make wins feel bigger than they are (`sound.md`, the slot-machine study), so nothing dresses a low pull as a high one. No fake-outs.

**The music plan.**

| Place | Feel | Tempo, mode (seeds) | Tracks | Search words |
|---|---|---|---|---|
| Base | night at a power plant: calm, wide, a slow pulse | 70–90 BPM, minor | 2 | ambient electronic, downtempo, night, chill synth, lofi japan |
| Strip | the festival heard from outside: light, warm, a flute | 95–110 BPM, major pentatonic | 2 | japanese festival, matsuri, shinobue, koto, bamboo flute, asian world |
| Lantern Row | the street becomes a fight: drums forward, a hook | 125–140 BPM, minor | 3 | taiko action, japanese drums, hybrid percussion, battle, energetic |
| Keeper | a duel: heavier, darker, reads as a boss in 4 s | 150–170 BPM, or 85 half-time | 2 | boss battle, intense drums, dark action, taiko epic |
| Tower | a climb: spare, hypnotic, rising | 120–130 BPM, minor | 2 | minimal tension, pulse, climbing, suspense electronic |

- **Filters:** `AudioSubType = Music`; `MinDuration` 90, `MaxDuration` 240; APM first, then any author; sorted by use, then by date. Listen for instrumental, a steady level, and a middle that can loop.
- **Leave out:** vocals; a title with "anime", "OST", "theme", "opening", "remix", "cover", "type beat" or a show's or game's name; a chart artist's song.
- **Eleven tracks** sit far under the licence's 250 (`sound.md`, "Music"). Each gets an alternate in Config.
- **Transitions:**
  - a change of place crosses over 2 s, as built;
  - the keeper's entrance is a cut: 0.4 s of nothing, a stinger of ours, then its track from the top;
  - a win stops the music for a sting and 3 s of ambience;
  - the base rests 20 to 40 s between tracks (today one Gap of 1.5 s serves every place);
  - a song loops on a clean middle section through `LoopRegion`.
- **The key:** once a place's track is picked, its long reward tones are tuned to it. Short UI tones stay on the set.

**Ten questions for any sound piece, on a phone speaker.**
1. Is it one finished sound, picked by the director's ear on the moment it plays on?
2. With the panel's phone switch on (a high-pass near 300 Hz), does it still read? Is its weight at 250 to 700 Hz?
3. Does its loudest point land on the contact frame, measured, at most one frame late?
4. Is it inside its family's length, and is its tail over before it can next play?
5. Twenty times in 30 seconds: does it have three takes or a spread, no immediate repeat, and a rate cap?
6. Is it the family's material? If it has a pitch, is it in the note set?
7. Are its bus, its level, its voice cap, what it ducks and what ducks it written in Config?
8. Does the moment still read with the sound off?
9. Does a 60 s fight with it measure −18 to −16 LUFS, peak under −1 dBTP, with the limiter idle?
10. Is it logged with its id and author, with a licensed alternate, no other work's name or tag in its title, heard on a live client, and nothing wet or gory?

## 5. Five sounds we could make ourselves

Python with numpy and scipy, 48 kHz mono, written to OGG (`tools/audio/audiokit.py`; the packages were approved on 11-15). All tonal or air, the families the directive of 11-17 names as fit for synthesis. Each goes to the panel beside library candidates, and "none" is a choice. Seeds throughout.

1. **UI tick, 30 ms.** Sines at 1047 and 1568 Hz (C6, G6) plus one partial at 2.76 times the lower, 12 dB down, for the glass. Attack 0.5 ms; exponential decay with a 6 ms time constant. Add a 3 ms noise burst, band-passed 3 to 6 kHz, 12 dB down. High-pass at 500 Hz; peak −6 dBFS. Three takes with decays of 5, 6 and 7 ms.
2. **Whoosh, 280 ms.** White noise through a band-pass (Q 1.5) whose centre sweeps 400 Hz to 2.4 kHz over the first 200 ms, then falls to 1.2 kHz. Level rises as time squared to a peak at 200 ms and falls over 80 ms. Add the same an octave up at 15%. High-pass at 250 Hz, light tanh drive (1.5). It's played so its peak lands on contact (`Lead = "Peak"`). Three takes: 220, 280 and 340 ms, tops of 2.0, 2.4 and 3.0 kHz.
3. **Shard crack, 180 ms.** A 2 ms noise click, high-passed at 2 kHz. Six sine partials on 1320 Hz (E6) at ratios 1, 1.59, 2.14, 2.65, 3.3 and 4.1, each decaying over 25 ms divided by the root of its index. Five to eight grains of 1 ms noise scattered between 20 and 140 ms, falling from −6 to −24 dB: the splinters. High-pass at 400 Hz; peak −3 dBFS. The ladder is `PlaybackSpeed`.
4. **Charge riser, 1.2 s** (also 0.6 and 2.0). A sine sweeping 220 to 880 Hz exponentially, a copy 7 cents sharp, and a fifth above at −9 dB. A noise band sweeping 800 Hz to 6 kHz at −10 dB. Level from −24 dB to 0 on an exponential curve; a tremolo that quickens from 6 to 24 Hz at 30% depth. Nothing under 200 Hz. It ends on a 2 ms cut, into the silence. For a charge of any length, the Shepard loop in `sound.md`.
5. **Soft confirm, 220 ms.** Two notes: 880 Hz (A5) at 0 ms and 1318.5 Hz (E6) at 70 ms. Each is a sine with its second harmonic at −12 dB and third at −20 dB; attack 2 ms; decay time constant 60 ms. Low-pass at 6 kHz; peak −8 dBFS; dry. **Refused** is the same voice: 587 Hz (D5) twice, 90 ms apart, decay 30 ms, low-passed at 1.5 kHz.

## 6. Frankly

- **Eleven days after "no SFX that add depth", most of the game is still silent.** The effort went into the family the team is worst at, and into tools. A press makes no sound; that's the first second of every session.
- **The music waits on the busiest person.** "i will put those myself" is the director's word, so the lists stay empty. The panel has no music tab (OBSERVED: `Config/Audition.luau`). I disagree with leaving it there: shortlist five a place and let the director tap, as TR35 already describes.
- **"The team makes and layers none" was right for hits and is too wide for tones.** A UI family from twelve uploaders won't sound like one family. Code can guarantee one timbre and one note set. The word of 11-23 reopens making; this note only says where to aim it.
- **Two audio systems means two mixes.** The music can't be side-chained or filtered from the graph while it sits on a `SoundGroup`. A volume tween is enough for now; the move to the graph can wait for a quiet week.
- **Our measures passed sounds four times that the director rejected at first listen.** So no checklist above is a verdict. Questions 2 to 10 are gates; question 1 is the verdict.

## Top 5 to act on

| # | What | Who | Cost | Director's yes? |
|---|---|---|---|---|
| 1 | **One listening sitting, about 20 minutes:** a music tab on the panel with five candidates for each of the five places, and two UI families (ours from recipes 1 and 5; one from the library) on real button presses. | Sonus shortlists; Faber adds the tab; the director listens | about a day; free | Yes: it changes "i will put those myself" into "I pick from a shortlist" |
| 2 | **The UI family as a block:** tap, tab, open, close, confirm, refused from `UI/Kit/Button` and the screens, on a UI bus, with the limits above. | Sonus makes; Faber wires | half a day each; our uploads are free inside the quota | No (tier 2); the picks are the director's |
| 3 | **Ducking and silence:** a `MusicController` duck (level, attack, hold, release), the reveal's music cut for Epic and up, the dip before a signature's contact, the menu low-pass. | Faber | half a day | No (tier 1 to 2); the numbers are seeds |
| 4 | **The reveal's ladder re-picked by ear:** the eight cues on the panel, the rungs on the note set, the silence growing with rarity. | Sonus; the director's ear; research's pass | half a day and five minutes of listening | No, unless the reveal's beats change |
| 5 | **A content check of the 63 keeps, and one licensed alternate per cue,** so a claim is a one-line swap. | Sonus, with the content check | two hours | No; any removal is reported to the director |

Not proposed: more hit work, steps, voices, acoustic simulation, or music that adapts beyond swaps. Each waits until the five above are heard.

## What I couldn't fetch or confirm

- Material Design's sound page came back empty; a card-reveal article (Medium) returned 403; Kotaku's loot-box piece 521; Audiokinetic's Peggle Blast article 403. The Peggle, Overwatch, loudness, earcon and adaptive-music lines rest on search excerpts and are marked "snippet".
- Roblox's Terms of Use and the audio terms weren't read. The 250-track line is `sound.md`'s forum quote.
- No Roblox staff statement on a voice limit, or on audio memory on phones, was found.
- Nothing here was heard or run. Every level, length and pitch is a seed.
