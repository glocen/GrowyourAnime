# The reveal and the showcase: how the best stage it, and our ladder

A cloud research agent for Faber, 2026-11-24. Read from written sources only: no footage, no play. Other works are named for principles; nothing of their look, names, sounds or compositions is ours to take (`AGENTS.md`, rule 3). Labels: SOURCED, COMMUNITY, SNIPPET (a search excerpt, page not opened), OBSERVED (our repo), MEASURED, OPINION. Every number proposed is a seed to tune by playing.

## Verdict

1. **Our reveal is well built and aimed at the wrong case.** Its ladder is timed for six rarities, and launch has two: about 87% of Standard breaks are a Common and 13% are Lyric (MEASURED). The Epic-to-Mythical work is unseen.
2. **Length follows rarity when it should follow news.** A fifth copy of Rook plays the same 1.6 s ceremony as the first Rook. By the tenth rolled break, 9 in 10 reveals are copies (MEASURED).
3. **The tenth reveal isn't fast.** The skip is shut for 1.0 s, the card holds 0.3 s, and it takes two taps: 1.3 s at best, one shard at a time (OBSERVED).
4. **The best games do three things we don't:** the multi-open resolves to its best result, the "new" case is marked and the copy case shows progress, and the character speaks.
5. **Keep the stage, change the rules:** three forms (Flash, Full, Event) picked by news and rarity, a break-all, a plate that says who this is and how far the copy took you, then an Index. About two days of Faber's time, no new art for the block.

## Ours, as built (OBSERVED)

- **Where:** `src/client/UI/Reveal/` (`init`, `Shard`, `Figure`, `Plate`), `src/shared/Rules/Reveal.luau`, `src/shared/Config/Reveal.luau`, `src/shared/Config/RevealArt.luau`; wired in `BaseController.Reveal`. A full-screen 2D overlay on an 844 by 390 stage; "the camera never moves" (`Shard.luau`). The Voidkin stands in a ViewportFrame window, 242 by 290 points at Common up to 275 by 364 at Mythical.
- **Beats:** four seams crack (0.03 to 0.34 s) → the light climbs one rung per rarity, each in its colour with a cue two semitones up → Epic and up hold a breath of silence → the split and its flash → the silhouette, rim-lit in the rarity's colour → his colours run down him on his clip's strike → the name stamps → the plate.

| Rarity | Last rung | Split | Name | Card | Flash | Hold |
|---|---|---|---|---|---|---|
| Common | 0.03 s | 0.55 | 1.07 | 1.62 | radius 70 | 0.55 |
| Uncommon | 0.30 | 0.60 | 1.20 | 1.85 | 95 | 0.65 |
| Rare | 0.48 | 0.85 | 1.59 | 2.39 | 135 | 0.80 |
| Epic | 0.66 | 1.05 | 1.97 | 2.92 | 190, breath 0.85 to 1.05 | 0.95 |
| Legendary | 0.84 | 1.30 | 2.22 | 3.32 | whole screen, gold-white | 1.10 |
| Mythical | 1.25 | 1.80 | 2.72 | 3.97 | whole screen, red-white | 1.25 |

- **Skip:** opens at 1.0 s for every rarity and lands on the held frame with the plate. The plate takes a closing tap after 0.3 s.
- **The plate:** "A new Voidkin" or "A copy"; "Common · Red · Warrior"; then "In your collection", "Your lead: it fights beside you", "One more toward its next star" or "Sold for N Credits". No count, no element, no signature, no line from the character, no button.
- **One at a time:** a new reveal replaces the one on screen. I found no break-all for shards; chests have one (`UI/VoidkinScreen/Bag.luau`, "Open all").
- **The director's words:** the 2026-11-13 idea kept for later, "X exist" and a chat line in every server on a Mythical (`docs/decisions.md`, line 143); the effects pass names the reveal (line 145). TR4 closed on research's pass; director-accepted isn't recorded.

**What's right (OPINION):** the tell is honest and climbs (it never shows a rung it won't reach); the silence before the split; a flash that is never pure white; levels set against the loudest; pure rules a test can pin. `characters-and-worlds.md` asks that "the rarer the reveal, the louder it plays": it already does. Loudness isn't the gap.

## Findings: the teardowns

### 1. The tell comes before the character, and it is a colour everyone already knows
- **Honkai: Star Rail.** Three tells in order: the ticket floats in blurred with a rainbow edge on a 5-star; the music changes to a more upbeat tune; the door behind the conductor is blue, purple or gold. In a multi the door shows the **best** result in the batch. COMMUNITY, [GINX](https://www.ginx.tv/en/4-star-5-star-warp-animation-differences).
- **Genshin Impact.** A star crosses a night sky, its colour is the tell, and the rare pull earns the longer descent. COMMUNITY, weak ([HostedGG](https://hostedgg.com/blog/gacha-pull-reveal-color-culture), a blog that cites nothing; the game's wiki answered 402). The same page's cross-game grammar: low is cool and quiet, mid warms, top is gold or a burst; the colour shows before the character renders.
- **Arknights.** "Before opening a bag, light will come out of the bag as an indication of what you'll get inside"; a reader notes the rarities sound different too. COMMUNITY, [GameWith](https://gamewith.net/arknights/article/show/14989) (the colours are in its images, unread).
- **Hearthstone.** Five cards land face down and **the player turns each one**. Hovering shows the tell: no glow, blue, purple, orange. Unowned cards get a blue border and "NEW!". Mass opening (up to 40 packs) came only in 2023, nine years in. COMMUNITY, [wiki](https://hearthstone.wiki.gg/wiki/Card_pack). The Innkeeper calls a Legendary aloud (SNIPPET, [wiki](https://hearthstone.wiki.gg/wiki/Innkeeper)).
- **Hearthstone, the makers.** Each pack gets its own opening, storyboarded by a concept artist first, with one effects artist owning the opening; the pack is a 3D object thrown up and turned three-quarters so its depth reads. SNIPPET, [TouchArcade, Ben Thompson, 2017](https://toucharcade.com/2017/04/04/designing-hearthstone-card-packs-animations-iterations-ungoro-and-more-with-art-director-ben-thompson) (the page answered 403).
- **Dokkan Battle and Dragon Ball Legends.** The tell is a small scene that can **step up mid-way**: a transformation, a second crack in the screen, a rival arriving, each a known guarantee. SNIPPET, [Alucare](https://www.alucare.fr/en/wiki/guide-dbz-dokkan-battle/), [Millenium](https://www.millenium.org/guide/321573.html).
- **Fire Emblem Heroes.** Five orbs, coloured by weapon type; the player picks which to open and each costs less than the last (5, 4, 4, 4, 3). A first-time hero wears a mark. Partial information before the commit, and a choice. COMMUNITY, [Fire Emblem Wiki](https://www.fireemblemwiki.org/wiki/Summoning).

**For us:** our rungs are this grammar already. Two gaps. The rungs are 0.18 s apart, so the question is asked and answered inside a third of a second: widen only the gap before the **last** rung, and only on a new Voidkin. And the batch has no tell at all, because there is no batch (`Rules/Reveal.luau`, `Config/RevealArt.luau` Steps).

### 2. The ladder by rarity: more beats, not just more seconds
- **Sol's RNG.** Stepped thresholds: a star animation from about 1 in 10,000 ([ItemLevel](https://itemlevel.net/sols-rng-all-star-pull-animation/)); a notice to the whole server above 1 in 99,999,998; a unique cutscene with its own music above 1 in 1,000,000,000 ([AllThingsHow](https://allthings.how/sols-rng-aura-tier-list-every-rarity-and-drop-rate-ranked/)). COMMUNITY. Each tier adds a *kind* of thing: a shape, then an audience, then music.
- **Anime Vanguards.** Rates 75.5% Rare, 20% Epic, 4% Legendary, 0.5% Mythic; pity at 50 and 400; a Shiny at 1.5% on Mythic and up, a second roll on top of the unit ([SeeMeta](https://seemeta.com/en/anime-vanguards/summon-rates), [Bloxodes](https://bloxodes.com/wiki/anime-vanguards/banners), [DroidGamers](https://www.droidgamers.com/guides/anime-vanguards-shiny-guide/)). COMMUNITY. Its trait reroll is a second reveal on an owned unit: 0.1% for the top trait, pity 1,500 ([Bloxodes, traits](https://bloxodes.com/wiki/anime-vanguards/traits), SNIPPET). I found no written beat-by-beat of its summon animation, unit showcase or evolution; its own wiki answered 403. That needs footage (`/ga-reference-study`).
- **Pet Simulator 99.** Mass is the reward: passes add 15 and 40 eggs per open; an hourly "biggest hatch" puts the winner's name across every server. SNIPPET, [wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99)). Anime Last Stand and Anime Defenders: only banners, pity and auto-sell found, nothing on staging.
- **Marvel Snap.** The upgrade ladder is presentation, never power: the art breaks the frame, then goes 3D, then animates, then the frame animates ([Upcomer](https://upcomer.com/what-does-upgrading-cards-do-in-marvel-snap-card-upgrades-and-levels-explained/), SNIPPET); the phone's tilt drives parallax (patch notes, 2025-04-01, SNIPPET). The same card gets visibly richer as you invest.

**For us:** each rarity up should add one new *kind* of beat, and Mythical one no other tier has (also `characters-and-worlds.md`, rule 8). Marvel Snap's lesson fits our stars: a copy should buy something you can see.

### 3. The common case is fast, and players vote with the skip
- Anime Vanguards guides tell new players to turn on "Skip Summon Animation" because it "can be tedious with time". COMMUNITY, [ItemLevel](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/); our own `making-greatness.md`, line 77.
- Players skip on routine pulls and watch on the ones they care about. COMMUNITY, weak, HostedGG.
- Sailor Piece opens a thousand chests in one sampled frame with no ceremony at all (`docs/research/chest-opening.md`, OBSERVED there).
- Pokémon TCG Pocket's opening can be skipped ([Game8](https://game8.co/games/Pokemon-TCG-Pocket/archives/483183), SNIPPET).

**For us:** a reveal players learn to skip is a failed reveal. The fix isn't a shorter Mythical. It's a copy that costs under a second and a new Voidkin that keeps its ceremony.

### 4. Right after: "new", progress, a place to put it, a reason to show it
- **Pokémon TCG Pocket.** A swipe tears the pack with sound and vibration; the pack can be opened from the back; tilting shows the card's edges and faces. The stated aim: "We want players to feel as if these digital cards are truly in their hands", and "the act of collecting is the original source of fun". SOURCED, [The Pokémon Company](https://corporate.pokemon.co.jp/en/topics/detail/t-28/). After: a collection board, binders, a pedestal for one card, sharing with friends. COMMUNITY, [Nerdist](https://nerdist.com/article/pokemon-trading-card-game-pocket-hands-on-impressions/), [Digital Trends](https://www.digitaltrends.com/gaming/pokemon-tcg-pocket-preview/).
- **Players invent tells where there are none.** The "bent corner" pack theory spread widely and tested false ([GamesRadar](https://gamesradar.com/games/pokemon/pokemon-tcg-pocket-bent-packs), SNIPPET). People want to read the container.
- **Anime Vanguards.** A Collection NPC pays gems for each new unit and an Enemy Index pays for each new enemy; the Unit Index shows every unit in the pool with its exact chance. COMMUNITY, ItemLevel and Bloxodes above.
- **Genshin Impact.** A copy pays a second currency, more for rarer. COMMUNITY, [RPG Site](https://www.rpgsite.net/feature/10312-genshin-impact-wish-system-gacha-and-banners-explained).

**For us:** our plate ends on "Tap to continue". Nothing points at the bay, the lead slot or a collection. The directive asks for "a persistent collection Index" and no doc holds one (`state-of-the-game.md`, line 72). The plinth inside the gate (`docs/design.md`, "The base shows off its owner") is already our pedestal.

### 5. The psychology, and where the line is
- **Arousal rises before the reveal, and rarer rewards raise it more.** Skin conductance and urge to open another both climb with rarity. SOURCED, [Larche et al., 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC7882574) (avid players of one game, small sample).
- **The wait carries its own signal.** In monkeys, dopamine neurons ramp through the delay when the reward is uncertain, most at a 50% chance. SOURCED, [Fiorillo, Tobler and Schultz, 2003](https://pubmed.ncbi.nlm.nih.gov/12649484/). An animal study: it supports "the tell matters", not a number for us.
- **Near-misses work, and that's the problem.** They recruit the brain's win circuitry and raise the wish to keep playing while feeling unpleasant. SOURCED, [Clark et al., 2009](https://pmc.ncbi.nlm.nih.gov/articles/PMC2658737) (15 people).
- **Paid loot boxes track problem gambling,** direction unknown (n = 7,422). SOURCED, [Zendle and Cairns, 2018](https://www.york.ac.uk/news-and-events/news/2018/research/researchers-find-link-problem-gambling-loot-boxes/).
- **Progress already begun gets finished.** A stamp card with two of ten pre-filled was completed by 34% against 19% (reported by secondary sources). SOURCED, [Nunes and Drèze, 2006](https://ideas.repec.org/a/oup/jconrs/v32y2006i4p504-512.html). Effort rises as the goal nears. SOURCED, [Kivetz, Urminsky and Zheng, 2006](https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal).

**For us, three rules (OPINION):** the result is fixed on the server before the first frame, and the tell only ever climbs to the truth. No rung flickers and falls back, no "almost". Excitement is spent on what the player earned in play. This suits a young audience and costs nothing.

### 6. Roblox's rules that touch it (SOURCED, [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items))
- A random reward **earned in play** needs no odds shown. We show them on every shard anyway (`docs/design.md`, line 121). Keep it.
- Anything random bought with Robux, or with a currency Robux can buy, must list every outcome with its odds before the purchase. Pity and luck count as "probability modifiers" and must be stated in numbers. Restricted players (`ArePaidRandomItemsRestricted`) need another path.
- So if Credits are ever sold, a shop shard is a paid random item (already raised, `README.md`, item 3). The reveal itself is never the problem. The purchase is.
- Sharing is free and built in: `CaptureService` takes a screenshot, prompts a save or a share, and records video. SOURCED, [CaptureService](https://create.roblox.com/docs/reference/engine/classes/CaptureService).
- **One trap in our own plan:** the store proposal lists "a reveal in another light (the crack's colour, never its odds)" (`docs/decisions.md`, line 348). The rungs' colours *are* the tell. A cosmetic may recolour the room and the first void light, never a rung.

## A frank critique of ours

1. **News is ignored.** `RevealArt.Rarities` picks the ceremony by rarity alone; `Outcome` changes only the plate's words. With five Voidkin, a player who owns the two the first session gives sees a new face on 56% of the first rolled break, 24% of the fifth and 8.5% of the tenth; of the first twenty, about three are new (MEASURED, from `Config/Shards.luau` Pools and `Rules/Odds.luau`'s dropped tiers: Common 60/69, Rare 9/69). `design-review.md` reached the same place and proposes a second roll. This page's part is the staging.
2. **The speed floor is too high:** 1.3 s and two taps a copy, and four chambers ready means four ceremonies in a row.
3. **The copy shows no progress.** "One more toward its next star" has no number. Stars cost 1, 2, 4 up to 64 copies (`docs/design.md`, "Stars"): the bar is the whole point of a copy.
4. **The character is mute.** No epithet, no line, no "what it's good at". `docs/ui.md`, screen 2, promises type, class, element, signature and a role line; the plate shows three of the five.
5. **Nobody else sees it.** The Breaker stands at the plot's front so "a passer-by sees the shards cracking" (`docs/design.md`, line 284), yet the reveal is a private overlay.
6. **The advert test hasn't been run.** The held frame is the screenshot. Nobody has judged five of them as stills at phone size.
7. **The work isn't wasted.** The stage, the rungs, the cues and the tests all stay. The change is in which form plays and what the plate says.

## Proposal: our reveal ladder (OPINION, seeds)

**Three forms, picked by the server's answer.** The names are internal labels.

| Form | Plays when | Tap to done | Taps |
|---|---|---|---|
| **Flash** | a copy of Common, Uncommon or Rare | 0.7 s | 0 or 1 |
| **Full** | a new Common or Uncommon; a copy of Epic and up | as built, 1.6 to 2.9 s | 1 |
| **Event** | a new Rare and up, and the account's first reveal | built time plus 0.1 to 0.6 s, then a longer hold | 1 |

**Flash:** cracks → rungs at twice the speed → split at 0.35 s → his portrait already in colour, no silhouette, no name stamp → the star bar fills by one with a tick that pitches up as the bar nears full → closes itself at 0.7 s. If the copy completes a star's cost, the pip turns ivory and the plate says "Star ready". The player still spends by hand (`docs/design.md`).

**The ladder for Full and Event:**

| Rarity | The tell (what's learnt, when) | To the split when new (a copy in Full) | The stage's "camera" | Light and sound | First pose and words | After |
|---|---|---|---|---|---|---|
| Common | one rung, void violet: known by 0.3 s | 0.55 | still | low split, quiet; name at −4 dB | the clip's strike, held 0.55 s; name, epithet | plate |
| Uncommon | a green rung at 0.30 | 0.60 | still | as built | as above | plate |
| Rare | blue at 0.55 (was 0.48): the last gap is the longest | 0.95 | 2% push-in over the last gap | the bed starts; rung cue a step up | strike, held 0.8 s; **his line** types on under the name | plate; Lead and Send to work |
| Epic | purple at 0.80, then the breath | 1.25 (1.05) | 3% push through the breath, 2% kick out on the split | 0.2 s of silence, then the split | held 1.0 s, a slow 1% drift | as Rare |
| Legendary | gold at 1.05, breath | 1.60 (1.30) | as Epic, with shake 5.5 | whole-screen gold-white, the room stays gold through the hold | held 1.5 s | plus a column of gold from the Breaker **in the world**, about 5 s, seen from the Strip |
| Mythical | gold hangs 0.5 s, then red: the only tier with a second question | 2.40 (1.80) | as Legendary; **he breaks the window's frame**, the only tier that does | a second, deeper breath; the high split slowed | held 2.0 s; "No. N in the world" | plus the chat line in every server (the director's kept idea) |

- **Each tier adds one kind of beat:** a second colour, the bed and the line, silence, the world, the frame break and the count.
- **The top of what a shard can hold plays as an Event when new,** so launch has an event to chase: Lyric today.
- **His line** is text, six words or fewer, in his voice, with the epithet from `characters-and-worlds.md`, rule 5. No voice acting. Every word passes the IP list.
- **The pose** is one silhouette a child could draw from memory. It's the frame the screenshot takes.

**The plate that follows:** line 1, the epithet; line 2, "Rare · Healer · Storm"; line 3, what it's good at in a line (`docs/ui.md`); line 4, the outcome with a number: "★1 · 3 of 4 copies". On a new Voidkin, two buttons beside Continue: Lead, Send to work.

**Skip and repeat rules:**
1. The skip gate drops from 1.0 s to 0.4 s once the account has seen three reveals. Rarer is still never slower to skip.
2. One tap ends a reveal: the skip tap lands on the plate, which closes itself after 0.8 s on a copy and waits for a tap on a new Voidkin.
3. **Break all** (the label needs the IP-list check): with two or more shards ready, one server step opens them, as chests do. The stage shows up to four shards in a row, they split lowest first at 0.25 s apart, copies as Flash, and the best one last in its own form. One summary plate. Its tell is the batch's best, as Star Rail's door.
4. A setting, "Fast reveals: off, copies, all but new". A new Voidkin always gets at least its held frame.
5. **The budget:** the tenth reveal of a session, a copy, is done in 1.0 s or less from the tap. Four ready shards with one new Voidkin are done in 4 s or less.

**Copies are made to feel fine by** the bar and its number, the rising tick, "Star ready" as a small win of its own, Credits at the last star (built), and later a richer card frame at stars 2, 4 and 7 (Modulo's time, cosmetic only).

**What the 2-hour blockout contains:** on the built stage through `NL_RevealTest`, in grey where art is missing. (1) Flash, from the same layers with the times scaled. (2) The skip gate and the self-closing plate, from `Config.Reveal`. (3) The star count and its fill on the plate. (4) Break all with four stand-in shards, the server step faked. (5) The epithet and line as plain text for Rook and Lyric. (6) Five phone stills of held frames for the advert test. **What waits:** the world's column, the chat line, the count, the frame break, star frames, the Index, new sounds.

## After the reveal: the showcase and the Index (OPINION, on the findings above)

- **The Voidkin screen** is already studied (`docs/research/voidkin-screen.md`): the figure at 70% of the height, turning, in its rarity's light, a tap playing the end of its Reveal. Add one thing from this page: the reveal's line and epithet live there too, so the screen and the reveal are one identity.
- **The Index:** one screen, by ground. Owned Voidkin stand in colour. The others are silhouettes with the shard that holds them and its chance, from `Odds.Rates`, never copied. Show a count per ground ("Lantern Row 3 of 5") and a row of star pips. Open it with the starter already filled: a begun set gets finished (Nunes and Drèze). Sort the nearest-complete ground first (Kivetz).
- **With five Voidkin the Index is full in an hour,** so it needs a second axis from day one: stars now, the rare second form if the director takes `design-review.md`'s proposal.
- **A shareable frame:** the figure at 60% of the height or more, one rarity colour, the name readable at thumbnail size, no HUD, no button. A "Save the moment" button on a new Rare and up can come later through `CaptureService`.

## A review checklist for a reveal (12 questions)

1. Is the result fixed on the server before the first frame plays?
2. Does the tell only climb, and stop at the truth?
3. Can a player name the rarity with the sound off? With the screen dimmed, by ear?
4. Does each rarity add a new kind of beat, not only length?
5. Is there one beat of silence or stillness before the split on the top tiers?
6. Is a copy done in one second and one tap or none?
7. Does a new Voidkin always get its held frame, even in the fastest mode?
8. Does the copy show a number that moved?
9. In the first second after the split, do we know who this is: name, epithet, one line?
10. Does the held frame pass as an advert, as a still, at phone size?
11. Does the plate offer the next action, and is it one tap?
12. Is the tenth reveal of the session as pleasant as the first, timed on a phone?

## Top 5 to act on

| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **Forms by news:** Flash for copies, the skip gate at 0.4 s after three reveals, one tap. Rewrites `docs/design.md`'s reveal line and `docs/ui.md`, screen 2 | research words it, Faber builds | about 4 h with logic cases | no: tier 2 |
| 2 | **Break all,** best last, one server step with its own fuzz case | Faber | about 6 h | no: tier 2; no economy change |
| 3 | **The plate says who and how far:** epithet, line, role line, "3 of 4 copies", Lead and Send to work | research writes five epithets and lines, Faber lays them | 1 h and 3 h | no: tier 2; names pass the IP list |
| 4 | **The advert test:** five held frames as phone stills, judged as stills; fix pose and figure size as the redesigns land | research and Modulo | 1 h, then per Voidkin | no: tier 1 |
| 5 | **The Index and the world's light:** a 30-line design now, built after the first ten minutes are proven. A completion reward, the Mythical chat line and the count are theirs to call | research designs, Faber builds later | 2 h on paper, about a day built | **yes** for the reward, the chat line and the count, and for adding a screen during a scope freeze |

**Not fetched:** Fandom wikis (Genshin, Sol's RNG, Pet Simulator: 402), Anime Vanguards' own wiki (403), TouchArcade, Kotaku and PC Gamer's two articles (bodies not returned), Marvel's art article (403). No video was read. Timings of other games' sequences are therefore absent: none here is invented.
