# The first ten minutes: how strong games open, our timed script, and the gap

A cloud research session, 2026-11-24, read-only on main. It builds on `docs/research/first-seconds.md`, `cold-read.md` and `design-holes.md` (F7), and on today's `retention-and-discovery.md`, `state-of-the-game.md` and `design-review.md`. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED, OPINION. No game was played and no video watched: every "seconds" figure for another game is my inference from written guides unless a source is linked. Every number proposed is a seed to tune by playing. Every proposal waits for its tier's yes.

## Verdict

1. **Today the seven beats, played in the north star's order, cost three teleports.** Fight and Find are in the Festival place, Work and Build are at home, Want is back in the Festival. No strong game studied puts a place change before its first reward. OBSERVED and OPINION.
2. **The first hit lands at about 1:10 to 1:40 after joining, by my estimate**, behind a walk, a 6 s break, a panel and a trip nobody has timed. That sits inside Roblox's 61 to 180 s bounce window, and one slow trip pushes it out.
3. **The rules for a great opening are already in our code, pointed at the wrong place.** The first kill drops Watt's shard, the second gives level 2, the third a sure chest (`Config/Drops.luau`, `Growth.luau`, `Chests.luau`). Three Shades at home deliver all of it before any loading card.
4. **The script below reaches seven of the eight funnel steps before 3:00** with one new service call, one new next-step line and some hiding. The first trip becomes the player's choice, with something to come home to.
5. **We can't see any of it yet.** `FunnelService` logs step names without seconds, and the trip has never been run for real. Measure first: one hour of code and one phone run.

## 1. Today's first session, as built

Times are estimates from code and from TR24 (a PC simulator run of 2026-11-16, before the two places and the chests). Not a phone measurement.

| Since join | What happens | Evidence |
|---|---|---|
| 0:00 to ~0:10 | Roblox's loading screen, then the plot. | MEASURED by Faber, TR24: 10.4 s on PC (`docs/test-requests.md`, TR24) |
| ~0:10 | Spawn facing the Breaker and three starter shards. Chip: "Choose your first shard". The full dock (Base, bag, Play) is already up. | OBSERVED `Rules/Hud.luau` `NextStep`, `UI/Dock.luau` |
| ~0:12 to 0:25 | Walk to a shard (TR24 measured 37 to 38 studs then), hold 0.4 s. | OBSERVED `BaseController.luau` (`CHOOSE_HOLD`) |
| +6 s | The break. It opens itself. | OBSERVED `Config/Shards.luau` (Starter 6 s, `Opens`) |
| +1.6 s | A Common's reveal: name at 1.07 s, card at 1.62 s, skip from 1.0 s. The shortest ceremony in the game. | OBSERVED `Config/RevealArt.luau`, `Reveal.luau` |
| ~0:30 to 0:45 | Chip: "Through the Door: Lantern Row". Walk into the Door. | OBSERVED `NextStep` |
| then | The Arc panel: Normal and Hard, recommended Combat Power, four stretch marks. Press Normal. | OBSERVED `StageService.luau`, `UI/StageScreen.luau` |
| then | The trip: a grey card. Never timed for real. A new server is about 5 to 6 s, with reports of 60 s stalls; the card holds up to 20 s. | COMMUNITY `docs/research/game-mode-places.md`; OBSERVED `Config/Travel.luau` |
| ~1:10 to 1:40 | First hit, about 6 s after landing (TR24). Kill 1 drops Watt's shard, kill 3 a chest. | OBSERVED `Config/Drops.luau` (`First`), `Chests.luau` (`Sure = 3`) |
| +2 to 3 min | Stretch 1: ten kills from one pack of four that stands again every 15 s. Two forced waits. The next-step chip is silent in the Festival. | OBSERVED `Config/World.luau`, `Stages.luau`; see `grounds-and-encounters.md` |
| later | Work needs a trip home. Build has no next-step line at all. Want needs a third trip and three cleared stretches. | OBSERVED `NextStep` (no Build step; nil off the plot until the gate) |

**Frank critique.** OPINION, from the code:
- The player's first prize sits in the bag in the wrong place. The game then says nothing, because the shard hint only shows at the base.
- The first reveal, the one moment every player sees, gets the least ceremony we have.
- A fresh player meets Hard, Combat Power and stretch marks before their first fight, and a dare line during it. That's four ideas ahead of the one that matters.
- No session-end hook is designed. Nothing is left visibly unfinished when the player leaves.
- A new lead at level 2 likely falls in stretch 2 or 3 (TR24 saw it on older numbers; not checked on today's). The first loss comes with no line saying what to do about it.

## 2. How strong games open

Roblox first, then mobile RPG benchmarks. "inf." marks my inference.

| Game | First input and first reward | Taught how | Withheld at first | First sink, then long goal | First social hook | Source |
|---|---|---|---|---|---|---|
| Grow a Garden | On your own plot with a starter seed. Plant in one input; first crop in under 10 s; first sale triples the money. | No text tutorial. The plot and the shop are the lesson. | Rare seeds, gear, pets. | Next seed up the ladder; a rare seed in a 5-minute stock. | Neighbours' plots in view; tiny servers. | our `first-seconds.md`; Naavik credits its "gentle" opening ([link](https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/)) SOURCED |
| Steal a Brainrot | Empty base, a little cash. Walk to the conveyor, buy the cheapest unit ($25, pays $1/s): paid back in 25 s (MEASURED from the guide's numbers). | No tutorial mentioned. One loud object in the middle of the map. | Nothing hidden, only unaffordable. | The next unit; first rebirth near $50M. | At once: others can steal from you; a base lock on a timer. | COMMUNITY [1](https://rblxguide.com/games/steal-a-brainrot/beginner-guide), [2](https://vgtimes.com/guides/166496-steal-a-brainrot-beginners-guide-tips-and-basics.html) |
| Dress to Impress | New players join Casual servers. A theme, about 300 s to dress, then the runway: first reward at 6 to 8 min (inf.). | The round is the tutorial. | Pro servers (3,000 stars). | Standard items are free; rank ladder. | Immediate: everyone rates everyone, 1 to 5 stars. | COMMUNITY [link](https://rblxguide.com/games/dress-to-impress/updates/beginners-guide) |
| Fisch | Spawn with a free rod. A tutorial NPC asks for 3 fish; cast inside a minute (inf.). | One NPC, one ask, then sell. | Other islands, boats (level 5). | A 2,000 C$ rod; the rod ladder. | Shared water (inf.). | COMMUNITY [link](https://rblxguide.com/games/fisch/updates/beginner-guide) |
| Blox Fruits | Pick a side, land on a starter island, quest giver in front of spawn: defeat 5 (or 8, guides differ) bandits. | A quest board, then fighting. | Fruits: the dealer is visible at 10,000+ and out of reach. | A 1,000 sword; the fruit. | Sides, then crews later. | COMMUNITY [1](https://bloxmeta.gg/games/blox-fruits/guides/beginners-guide), [2](https://blox-fruits.fandom.com/wiki/Pirate_Starter) |
| Anime Vanguards | Pick one of three free starters on first join, then a short tutorial stage with free rewards. | By placing units in a real stage. | Evolve, challenges, later modes stand in the lobby as places. | A summon at 50 gems; level milestones to 100. | The lobby, co-op stages. | COMMUNITY, mixed guides [link](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/). Exact flow not confirmed |
| Pet Simulator 99 | Tutorial quests hand out free pets; pets break things by themselves. | Quests. | Later areas behind coin gates. | The gate to area 2. | Trading, later. | COMMUNITY, weak: guides disagree; a 240 Robux pack is offered early |
| Marvel Snap | An intro battle, then matches against bots. One location, starter cards with no abilities. | Two pre-set games teach the signature bet, with the player placed to win. | The bet for hours; the store and pass for the whole first season. | A $2.99 bundle only; the collection track. | None early, by design. | SOURCED [DoF](https://www.deconstructoroffun.com/blog/2023/5/23/marvel-snap-the-definitive-deconstruction), [GDC write-up](https://mobilegamer.biz/second-dinner-reveals-the-secrets-of-marvel-snaps-onboarding-and-card-design/) |
| Clash Royale | Five short tutorials, each adding one thing. The first ends on a chest with a ~15 s wait and a skip: the sink shown once, free. | By playing matches. | Most cards; about 24 of 42 by Arena 2. | Chest timers of 3 to 12 h in four slots: full slots are the natural stop. | Clans, later (not sourced). | SOURCED [Apple](https://developer.apple.com/app-store/onboarding-for-games/), [Game Developer](https://www.gamedeveloper.com/design/clash-royale---deconstructing-supercell-s-next-billion-dollar-game); COMMUNITY [PG.biz](https://www.pocketgamer.biz/ftue-clash-royale/) |
| Genshin Impact | A cutscene, a choice of two, a guided walk and fight. The first pull only after the intro quest, at the first city: tens of minutes (inf.). | A guide character, step by step. | The gacha, co-op. | A discounted first banner with a sure 4-star. | Co-op, hours later (from memory, not fetched). | COMMUNITY [Epic](https://store.epicgames.com/news/get-started-with-genshin-impact-with-our-beginners-guide), [GameRant](https://gamerant.com/genshin-impact-character-re-roll-beginner-wish-story-adventure-rank/) |
| AFK Journey | Story and guided stages; "early game rewards are extremely generous"; idle income starts early. | Guided stages. A reviewer disliked the unskippable ones. | Most modes, behind padlocks. | Idle income as the speed bump; D60 of 7% against 4%. | Guilds, later. | SOURCED (analyst) [Naavik](https://naavik.co/digest/lessons-learned-from-afk-journey/) |

What the table says (OPINION, read across the rows):
- **The Roblox hits put the first reward in the place you spawn**, inside about a minute, with one object to walk to. None of the six I could read loads a second place first.
- **The mobile RPGs take longer, and pay for it with a staged win**: bots, pre-set hands, placeholder heroes. They never let the first fight be lost.
- **The first sink is shown once, cheap or free, right after the thing it speeds up was used** (Clash Royale's chest, Two Dots' power-up in Apple's page).
- **The session's stop is designed**: timers full, a prize named for tomorrow. Ours isn't.
- **Not found:** stopwatch timings for any of these. Our own phone run is the only real number we'll have.

## 3. The rules, with sources

| # | Rule | Source | For us |
|---|---|---|---|
| R1 | **Time to fun.** "FTUEs that get users into the fun quickly tend to do better." Fun inside 5 minutes; casual users leave in under 2. | SOURCED [Roblox, Design for Roblox](https://create.roblox.com/docs/production/game-design/design-for-roblox); [GameAnalytics 2025 Roblox report](https://www.gameanalytics.com/reports/2025-roblox-report) (via a search summary) | First hit by 0:40, not 1:10 to 1:40. Faber, the first breach below. |
| R2 | **The 60 s and 180 s windows.** Home ranking reads first-play bounces under 60 s and from 61 to 180 s. A staff reply says the whole experience counts, so a teleport isn't punished as such. | SOURCED [Roblox, Discovery](https://create.roblox.com/docs/discovery); COMMUNITY (snippet) in `retention-and-discovery.md` | The trip isn't the problem; the wait and what comes before it are. Put a reveal before 60 s and three rewards before 180 s. |
| R3 | **Teach by doing, in eight words.** Blend the lesson into play, do the action once, at most eight words on screen. Players "generally don't like to read instructions". | SOURCED [George Fan, GDC 2012](https://gamedeveloper.com/design/gdc-2012-10-tutorial-tips-from-i-plants-vs-zombies-i-creator-george-fan); [Roblox, Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) | `Hud.NextStep` already works this way: one line, one chevron. Its lines are 4 to 6 words. Keep it, and close its holes. |
| R4 | **One new idea at a time.** Spread lessons out (money came after ten levels); one step at a time; non-essentials after onboarding. | SOURCED Fan; [Apple, Onboarding for Games](https://developer.apple.com/app-store/onboarding-for-games/) | Hide Hard, Combat Power, dares, Today's three, the shop and the Tower until their beat. `view.Funnel` is already on the client (`Data/Profile.luau`). |
| R5 | **Timed hints, shown once, only to who needs them.** Most testers pressed within 10 s, so the hint shows at 11 s. | SOURCED Roblox, Onboarding techniques | The chevron could wait about 8 s before it appears over the starters, and the signature ring's hint 3 s (`combat-agency.md`, block 1). |
| R6 | **A first win is arranged.** Bots, a pre-set opening hand, the player "put in a winning position". | SOURCED DoF and the GDC write-up above | The lead can't fall in the first fight, and stretch 1 of a first run can't be lost. Tier 2, balance. |
| R7 | **Early generosity, depth later.** Extremely generous early rewards; the shop after the player has used what it sells. | SOURCED Naavik; Apple | Three rewards in three kills is already our rule. Show Reinforce only once a chest piece is equipped. |
| R8 | **Fix the funnel's worst step before adding content.** One step lost 70% of players; an icon fixed it. | SOURCED [Roblox DevRel, 2024-07-12](https://devforum.roblox.com/t/3064458) | We log eight steps with no seconds. Add them. Faber, 1 h. |
| R9 | **End on a designed moment, and leave something open.** "An intentionally designed moment of joy"; a timer that ends after the session; "come back tomorrow for another prize". | SOURCED [Roblox, Onboarding](https://create.roblox.com/docs/production/game-design/onboarding); Game Developer and Apple above | Section 5. |

## 4. Our first ten minutes, as a script

**The teleport, honestly.** Should the first fight be in the base place? Yes (OPINION), as a one-time **first breach**: on a fresh account only, the starter's break cracks the yard and three level 1 Brawlers step out (`design-holes.md`, F7; `design-review.md` asks for it as the default). "First breach" is an internal name; anything players read still needs the IP-list check.
- **Why:** the first hit moves from about 1:10 to 1:40 to about 0:35; Fight, Find, Work and Build all land before any trip; the first trip is chosen, and a slow one costs a player who already owns three things.
- **Cost:** one grey block for Faber, 90 minutes to 3 hours (OPINION). `FightService.SpawnEnemy` already takes `For = player` and already runs in the base place for the Tower's rivals. The drops need no change. New: a hook on a fresh account's first open, three spawn points from the plot's markers, a guard so the lead can't fall, a logic case for "never repeats" (run it only while the save's `Funnel.Fight` is unmarked).
- **What it touches:** the vision's Fight beat and the director's word of 2026-11-19 that the Festival is its own place. **It needs the director's yes.** It isn't a second mode: three Shades, once per account.
- **If the answer is no:** keep the fight in the Festival, give a fresh player a one-button Arc panel, budget the trip at 10 s, and light Home on the first results card while the bag holds Watt's shard. First hit stays near 1:00, and Work stays behind a second trip.

Times are since join, on a phone, as seeds. Status: BUILT as read in code; CHANGED says how; NEW.

| Time | On screen | The player presses | The game answers | Feeling | Hidden until later | Status |
|---|---|---|---|---|---|---|
| 0:00 to 0:10 | Roblox's loading, then the plot | nothing | the camera faces the Breaker and three shards | "that's mine" | everything | BUILT |
| 0:10 | Three starter shards within 12 studs, in frame. Chip: "Choose your first shard". No dock. | moves the stick | the chevron appears only after 8 s idle | curiosity | dock, pills, goals | CHANGED: the dock hidden until the reveal; the distance checked on a phone (37 studs on 11-16); the timed chevron |
| 0:13 to 0:17 | Standing by a shard, "Choose" | holds 0.4 s | the shard flies into the Breaker | "I picked" | the other two starters | BUILT (funnel: Choose) |
| 0:17 to 0:23 | The Breaker shakes, a 6 s count | nothing | the break, with sound rising | anticipation | break times of other grades | BUILT; the sound is missing (`audio-direction.md`) |
| 0:23 to 0:27 | The reveal: silhouette, name, a card with one button, "Lead" | taps once | the Voidkin steps down beside the avatar | the first wow | rarity odds, copies, stats | CHANGED: a one-time long form, about 3.5 s, no skip, in place of the Common's 1.6 s (`reveal-and-showcase.md`, the Event form). Rarity unchanged (funnel: Reveal) |
| 0:28 to 0:32 | The yard cracks 12 to 15 studs off; three Shades step out. Chip, a seed: "Three Shades. {lead} has them." | moves closer, or doesn't | the lead runs in on its own | "it fights for me" | the Door, the bag | NEW: the first breach |
| 0:33 to 0:40 | First hit by 0:35. Shade 1 falls. | steers | Watt's shard flies to the avatar, toast "+1" | first prize | what a named shard is | BUILT rule (`Drops.First`), NEW place (funnel: Fight, Find) |
| 0:40 to 0:50 | The signature ring fills and glows; a hint after 3 s idle | taps the ring | the signature ends Shade 2; "Level 2" notice | "I did that" | Auto, the second button | CHANGED: needs `combat-agency.md` block 1. Level 2 at kill 2 is BUILT (`Growth.Early`) |
| 0:50 to 1:00 | Shade 3 falls. The crack shuts. | steers | a chest drops, toast only | a full pocket | Reinforce, salvage | BUILT rule (`Chests.Sure`); NEW: the lead can't fall here |
| 1:00 to 1:10 | Chip: "{shard}: into the Breaker" | walks 5 studs, presses | 6 s break, it opens itself | "I know this one" | break-all, chambers | BUILT |
| 1:10 to 1:15 | Watt's reveal, the ordinary form | taps | Watt stands idle by the bays | a second fighter | Aptitude numbers | BUILT |
| 1:15 to 1:30 | Chip: "Station Watt in Bay 1" | walks, presses | the bay lights; the kWh figure starts to climb | "it earns while I play" | Training, the Condenser | BUILT (funnel: Work) |
| 1:30 to 1:55 | The bag cell appears. Chip, a seed: "Open the chest" then "Equip it" | two taps | the piece goes on; Combat Power ticks up | stronger, by my hand | Reinforce, emblems, jewels | NEW: a Build step in `Hud.NextStep`; CHANGED: the bag cell gated by the funnel (funnel: Build) |
| 1:55 to 2:10 | Play appears. Chip: "Through the Door: Lantern Row"; the Door's sign lit | walks into the Door | a panel: one tile, one button | "now, out" | Hard, Combat Power, stretch marks, the Tower | CHANGED: a fresh player's panel is stripped. The Door still opens the menu, as the director said |
| 2:10 to 2:25 | The trip card, with the lead on it | nothing | lands at the gate; budget 12 s | a short breath | everything | BUILT, untimed; CHANGED: the lead on the card |
| 2:25 to 3:00 | Lantern Row, stretch 1. Run line only. | steers, taps the ring | first hit within 6 s; the lead with gear on | the real street | the dare line | BUILT; CHANGED: no dare on a first run |

Beat by beat after 3:00:

| Time | Beat | The game answers | Hidden until later | Status |
|---|---|---|---|---|
| 3:00 to 4:30 | Stretch 1: ten kills and the elite, with no standing still | stones and Credits fall; the lead reaches level 3 or 4 | the shop's stock | CHANGED: the pack stands again in 3 s on stage 1, or waves (`grounds-and-encounters.md`, item 2). Can't be lost on a first run (R6) |
| 4:30 | The first results card: one line, one lit button, "Next" | the dare for stretch 2 is named here, the first time a dare is seen | Hard, Retry | CHANGED: a fresh card shows less |
| 4:30 to 6:30 | Stretch 2: the Guards, one new Shade | the first fight that can go wrong | | BUILT |
| about 6:30 | The lead falls, or stretch 2 clears | if it falls: Home is lit, with a seed line, "Watt has been working." | Retry stays, unlit | CHANGED: today Retry is lit and nothing points home |
| 6:30 to 7:00 | Home, by the trip or the Home button | the battery shows 5 minutes of Watt's work | | BUILT, untimed |
| 7:00 to 8:30 | The first sink: Reinforce the equipped piece to +1, a sure success to +5 | Combat Power ticks up again; base level 2's price shows as a bar, "x of 840" | emblems, jewels, the shop | BUILT (`Config/Reinforce.luau`, `Base.luau`); NEW: a next-step line for it, shown once |
| 8:30 to 10:00 | Back through the Door. The panel now shows the stretch marks and where the run stands | stretch 2 or 3 with a stronger lead | Hard until the keeper falls (BUILT rule) | BUILT |
| at the first Row clear, day 1 or 2 | Want: the Tower card and Hard open | | | README, item on the Tower card |

By 3:00 the player has chosen, revealed twice, fought, found, stationed, equipped and travelled: funnel steps 1 to 7. Today, by my estimate, they'd have steps 1 to 5 and a full bag in the wrong place. The script uses eight nouns in ten minutes (shard, Breaker, the lead's name, Shade, Watt, Bay, Door, Lantern Row), against the fifty `state-of-the-game.md` counted.

## 5. The session's end hook

Three things left visibly unfinished, on the first results card and on the plot (OPINION, from R9):
1. **Something breaking with a count.** A Standard shard is 30 s: too short to leave open. An Enriched shard is 900 s (`Config/Shards.luau`). Proposal: the first clear of stretch 1 pays one Enriched shard, once per account. At launch that's in effect a Lyric, the only Voidkin above Common with a model. **Economy: the director's yes.** Without it, the hook is items 2 and 3 only, and weaker.
2. **The battery filling.** "Full in 1 h 50" beside the bays (60 kWh cap, 2 hours away; `Config/Base.luau`). BUILT numbers; the line on the results card is NEW.
3. **The next goal named.** The pinned Next line, and the keeper: "The Lamplighter waits at the gate" exists only near the gate today. Show it on the card once stretch 1 is cleared, and mark the funnel's Want there. CHANGED.

No push notification is proposed: `retention-and-discovery.md` covers the opt-in rules, and the game isn't public.

## 6. The gap: the ten cheapest changes, by value per hour

| # | Change | Who | Cost | Tier |
|---|---|---|---|---|
| 1 | Seconds since join on every funnel step, and the trip's seconds, in the log and as custom events (`FunnelService`, `Travel.Took`) | Faber | 1 h | 1 |
| 2 | A Build step in `Hud.NextStep` ("Open the chest", "Equip it"), with logic cases | research words it, Faber | 1 to 2 h | 2 |
| 3 | Stage 1's pack stands again in 3 s on a first run (one number, then waves later) | Faber, research's seed | 15 min | 2 |
| 4 | Starters within 12 studs and in frame at spawn; the chevron after 8 s | Faber | 30 min | 1 |
| 5 | The first reveal's one-time long form, from timings already in `Config/RevealArt.luau` | research picks, Faber | 1 h | 2 |
| 6 | Hide by funnel mark: dock cells, Hard, Combat Power, stretch marks, the dare line, Today's three | Faber | 2 to 3 h | 2 |
| 7 | The first breach, in grey, with the no-fall guard and its "never repeats" case | Faber; research's feel line and verdict | 90 min to 3 h | block: 1; to ship: **the director's yes** |
| 8 | The first results card: one line, one lit button; Home lit when the lead falls | research words it, Faber | 1 to 2 h | 2 |
| 9 | The end hook's two free lines (battery, the keeper) on the card and the plot | Faber | 1 h | 2 |
| 10 | The one-time Enriched shard at the first stretch clear | research's restatement, Faber | 30 min | **3: the director's yes** |

Items 1 to 6 and 8 to 9 are about a day and a half of Faber's time and change no decision. Item 7 is the one that moves the first hit.

**The director's private phone run: a stopwatch table.** One fresh account, phone in landscape, on mobile data if possible. Say aloud what you think you should do next; the silences are the findings. Targets are seeds.

| Measure | Target (script) | Today (est.) | Read |
|---|---|---|---|
| Join to the plot on screen | 10 s | 10 s on PC | |
| Join to the first deliberate press (the starter) | 17 s | 15 to 25 s | |
| Join to the first Voidkin's name | 25 s | 25 to 40 s | |
| Join to the first hit | 35 s | 70 to 100 s | |
| Join to the first drop in the bag | 40 s | 80 to 110 s | |
| Each trip, press to control (three readings) | 12 s or less | unknown | |
| Join to Watt in a bay | 1:30 | after a second trip | |
| Join to the first piece equipped | 1:55 | no line leads there | |
| Join to stretch 1 cleared | 4:30 | 4 to 5 min | |
| Longest stretch with nothing to do, and where | under 10 s | two 15 s waits in stretch 1 | |
| Times you didn't know what to do next | 0 | | |
| Was the lead's first fall explained | yes | no | |
| What was unfinished when you stopped | three things | | |

## Top 5 to act on

| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **Measure first:** seconds on the funnel and the trip, then the phone run above | Faber, then the director | 1 h, then 20 min | no |
| 2 | **The first breach in grey,** judged in motion from a phone: three Shades at home, three rewards, no fall | Faber builds, research reads | 90 min to 3 h | no for the block; **yes to ship** (the Fight beat, the 11-19 word) |
| 3 | **Close the guide's holes:** the Build step, the first results card, Home lit on a fall | research words, Faber | 3 to 4 h | no (tier 2) |
| 4 | **One idea at a time:** hide by funnel mark, the stripped first panel, no dare on a first run, the first reveal's long form | Faber, research | 4 to 5 h | no (tier 2); the Door still opens the menu |
| 5 | **A designed stop:** the battery and keeper lines now; the one-time Enriched shard as a restated proposal | Faber; research restates | 1 h, then 30 min | **yes** for the shard (economy) |

**Not fetched:** Destructoid's Fisch guide and two Sportskeeda Anime Vanguards pages (403), a uxdesign.cc onboarding essay (403), a Pet Simulator 99 guide (404), PocketGamer.biz's idle-RPG analysis (redirect), PC Gamer on Steal a Brainrot (cut short), Unity's FTUE page (empty). PocketGamer.biz's Clash Royale piece keeps its detail in a video. GameAnalytics' report was read through a search summary only.
