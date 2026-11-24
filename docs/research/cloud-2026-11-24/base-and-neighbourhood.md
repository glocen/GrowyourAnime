# The base and its neighbourhood: real choices, signs of life, a reason to live on a street

Cloud study, 2026-11-24. Read-only on the game (MAIN). Every item is a proposal. Numbers are seeds, tuned by playing. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED (computed here), OPINION. Builds on `design-review.md` (challenge 4), `state-of-the-game.md`, `retention-and-discovery.md`, and MAIN's `docs/research/design-holes.md` (H3, H4, H7, F4, F6, F7); it doesn't repeat them.

## The verdict, in five lines

1. **The base asks for almost nothing.** Of the twelve decisions a player has there, one is a real trade (who leads, since a worker can't lead), and the base doesn't show it. The rest are upkeep, a gate, or a choice with one answer.
2. **The root cause is one surplus number.** Bays make only kW, kW is 1.8 to 7.7 times demand, and aptitude is one number that mostly repeats the class. No choice made upstream of a surplus can matter.
3. **The cheapest real choice pays in what players already want** (levels, stones, hours away, a faster heal), not in kW: one work knack per Voidkin, then links between neighbouring bays. About 12 hours of build for both.
4. **"Alive" is reactivity, not volume.** Workers stand in their rings playing the fight idle. Ten cheap signs, about 25 hours in all, change that. The first four cost about 9.
5. **The neighbourhood should be safe, seen and shared at launch: no trading, no stealing.** One Festival server per street makes the neighbours the people you fight beside, and it's the cheapest answer to "the fight feels like leaving home".

## 1. What the base is today

### The decisions (OBSERVED: `src/shared/Rules/Base.luau`, its eleven actions, plus the lead and the showcase; `src/shared/Config/Base.luau`)

| Decision | How often | Is it a choice? |
|---|---|---|
| Which starter shard | once | Yes, one of three |
| Add a shard, reorder the line, take one out | every shard | No. Launch shards break in 30 s and chambers are under 12% busy (`docs/balance.md`) |
| Open a broken shard | every shard | A moment, not a choice |
| Who works in which bay (`SetWorker`) | when a Voidkin or a bay arrives: about 4 to 6 times in launch's whole life | Weak. Bays are identical, output is one number, and at base level 3 every Voidkin that isn't leading works (H3) |
| Who leads ("A worker can't lead too", `BaseController.luau:115`) | each run | **The one real trade**, but nothing at the base shows what the lead gave up |
| The power split (`SetPower`) | never | No. Auto is the answer (`docs/balance.md`, "Electricity at launch") |
| Voltage (`Infuse`) | never at launch | Not offered: no launch shard saves 60 s |
| The base's level | twice (840, then 18,000 Credits) | No. A gate |
| A machine's level | up to 174 purchases: the Breaker, the Condenser and four bays, 29 levels each, 131,990 Credits a machine (MEASURED from `Config.Base.Machines.Price`) | Weak. One price list for all, and a bay's +4% a level feeds the surplus |
| Collect the Condenser's tray | every 12 h at most | Upkeep, and the reason to return |
| Convert 5 Low stones to 1 Mid (30 min) | when stones allow | A small real one |
| The showcase Voidkin | rarely | Expression |

### What it shows and does

- **While you watch (OBSERVED):** each worker's body stands in its bay's ring, "tagged Worker for the client to play its rig's Idle", with the ring lit in its rarity colour (`BaseService.luau:102-106`). `Config/Animations.luau` holds Idle, Hit, Down and Up per rig, and no work clip. The rings and hinges turn, the Mill's buckets show generation against demand, the battery lights its cells, chips hang over machines, and a stage swap has its landing (TR51, built).
- **Nobody speaks, looks at you, or reacts to anything.** I found no bark, no look-at and no reaction to a run's result. OBSERVED by search, so absence isn't proven: check.
- **While you're away (OBSERVED: `Rules/Breaker.luau:264-281`):** the workers generate for `AwayHours = 2`, then the machines run on the battery (60, 150 or 400 kWh by base level), then at the 25% floor (`Power.MinSpeed`). The lead trains. The tray stops at 12 hours of stones.
- **MEASURED, rough:** a first-day player (base level 2, two workers at 30 kW, Training and Condenser drawing 20 kW, about 20 kWh stored at leaving) gets about 4 hours at full speed, then a night at a quarter. Assumptions are mine; the simulation should confirm.
- **On return:** nothing marks it yet. TR53 (the return card, and the base's line during a run) is designed and queued, with its look drawn (AR55).
- **Possible gap, check:** `docs/design.md` line 55 says a Voidkin levels "from fighting, working or training". `Rules/Breaker.luau:11` says "A worker never trains", and I found no rule that pays a worker experience.

## 2. What the best base loops do

**F1. A work choice needs three things at once: different jobs, workers that differ by job, and scarcity.**
- Palworld has 12 work types and suitability levels 1 to 10 per Pal, and some partner skills give +1 in one work type to every other Pal at the base. COMMUNITY: [Palworld wiki](https://palworld.wiki.gg/wiki/Work_Suitability).
- Arknights ties each operator's base skill to one facility type. Skills with similar effects don't stack (the strongest applies), so a varied roster beats five copies. Morale (24) drains at work, and at 0 the skill switches off. COMMUNITY: [RIIC](https://arknights.wiki.gg/wiki/Rhodes_Island_Infrastructure_Complex), [Base skill](https://arknights.wiki.gg/wiki/Base_skill).
- Fallout Shelter matches a dweller's stat to a room: "Each character's SPECIAL profile affects their ability to generate different resources". Reviewers still "criticized its lack of depth", and IGN said it was "desperately in need of a set of endgame goals or resource sinks". SOURCED through [Wikipedia](https://en.wikipedia.org/wiki/Fallout_Shelter).
- **For us:** we have none of the three. One job (kW). One number: across 31 definitions, 5 of 6 Assassins have aptitude 1 and 4 of 6 Tanks have 3 (MEASURED, `Definitions/Voidkin.luau`), so aptitude is the class said twice. No scarcity at level 3. Fallout Shelter's fate (matching without sinks reads as shallow) is ours today.

**F2. A timing choice needs a price or a risk.**
- Fallout Shelter's Rush fails at 40% minus 1.5 times (average room stat plus average luck), never under 10%, plus 10% for each recent rush. COMMUNITY: [the community FAQ](https://github.com/therabidsquirel/The-Fallout-Shelter-FAQ/wiki/Section-3:-Rooms,-Resources,-and-Storage).
- Satisfactory lets a machine run to 250%, and 200% speed costs 250% power. COMMUNITY: [wiki](https://satisfactory.wiki.gg/wiki/Clock_speed).
- **For us:** take the price, never the risk. A fire or a lost shard breaks "never loses a shard" (`docs/design.md`) and the premium tone. Skip morale too: it's a chore timer, the "excessive management" the directive's section 6 warns about.

**F3. The return is a celebration, and its cap is a goal you can see.**
- Pecorella (Kongregate), reported from GDC: a check-in "creates a celebratory moment every time that you return", and the longer you stay away, "the greater your incentive to return". SOURCED: [Game Developer](https://www.gamedeveloper.com/design/the-rise-of-games-you-mostly-don-t-play).
- AFK Arena's chest stops growing at 12 hours, and one free "fast reward" a day gives 2 more hours. COMMUNITY, search results of guides only; the pages refused the fetch.
- From memory, not fetched today (verify before quoting): Egg, Inc. sells away time by the silo, about an hour each, so the cap is a trophy you buy. Cookie Clicker gives offline cookies only after a prestige upgrade, at a small share for one hour.
- **For us:** TR53 has the right contents. Two gaps: the world should tell the news before the card does (section 6), and the cap should be said honestly as hours ("ran dry at 6 h"), which `docs/design.md` already asks of the battery screen.

**F4. On Roblox, public theft draws crowds and clips, at a cost we shouldn't pay.**
- Steal a Brainrot: income units sit in an open base, anyone can carry one off, and a button raises "a temporary shield". Guinness compares it to capture the flag. It peaked at 25.4 million concurrent players in October 2025. The same page reports clips of upset children with "tens of millions of views", Polygon's "the best items are only available for cash", and widespread automation cheats. SOURCED through [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot). Its "rituals" need three players acting together. COMMUNITY: [Beebom](https://beebom.com/robloxs-steal-a-brainrot-delivered-a-2025-masterclass-in-player-engagement-and-gave-uefn-a-second-wind/).
- Grow a Garden charged 37 Robux to take one crop, told the whole server, and the stated defence was a free private server. COMMUNITY: [DroidGamers](https://www.droidgamers.com/guides/grow-a-garden-stealing/). A former Square Enix executive called the game "somewhat evil" for it (GamesRadar's headline; the article body didn't fetch).
- Its trading came months after launch, behind a Trading Ticket (100,000 Sheckles or 19 Robux), and pet gifting was switched off for about two weeks over a duplication exploit. COMMUNITY, search results only (Sportskeeda, DroidGamers).
- **For us:** what works there is a small server where everyone sees everyone's best thing, and news that reaches the whole server. We can have both without theft. Stealing breaks "Visiting is free and safe: look, never touch" [D]. Trading breaks "Fighters are valuables" until it has its own fuzz-tested, one-step design. Both wait.

**F5. Roblox's own levers.**
- The default matchmaking has a Friends signal: the share of a server's players "who are friends with the joining player or who share an IP address". SOURCED: [Roblox docs](https://create.roblox.com/docs/matchmaking/attributes-and-signals). The page gives no weights.
- Private servers can be free; the experience must be public, and they can't be combined with paid access. SOURCED: [Roblox docs](https://create.roblox.com/docs/production/monetization/private-servers).
- An invite can carry 200 characters of launch data, read with `GetJoinData()`. SOURCED: [Roblox docs](https://create.roblox.com/docs/production/promotion/invite-prompts).
- Intentional co-play days is a ranking signal, co-play sessions run 1.9 times longer, and sessions in reserved servers count as co-play (`retention-and-discovery.md`, findings 1 and 15).
- **For us:** a friend who joins lands on our street by default while a plot is free. Then the Door splits them: nothing sends two neighbours to one Festival server (section 8).

**F6. Workers become characters when the game notices things.**
- Supergiant's stated aim for Hades is moments where "the game is paying attention". SOURCED: [Game Developer](https://www.gamedeveloper.com/design/how-supergiant-weaves-narrative-rewards-into-i-hades-i-cycle-of-perpetual-death). Kasavin's method, from a search result of GameSpot (page refused): "What would these characters talk about and what would they notice? Add those interactions."
- Spiritfarer designed its characters first, then cut the farming back so gathering wasn't the point. SOURCED through [Wikipedia](https://en.wikipedia.org/wiki/Spiritfarer). Its mood system (a daily hug, a favourite dish, a happy spirit helping at a station) is from memory; the wiki refused the fetch.
- Blue Archive's cafe: students walk in, the player taps them for bond, and furniture raises "comfort", which raises income. COMMUNITY, search results of guides.
- Not fetched, so not used as evidence: Dave the Diver's staff, Two Point's traits, Stardew's machines, Animal Crossing's visits, Clash of Clans' base viewing.
- **For us:** thirty short lines keyed to six events are worth more than three hundred idle lines. Pillar 1 ("every Voidkin is somebody") can be proven at the base for a few hours of work.

## 3. The critique, frankly

1. **A pillar rests on a currency nobody is short of.** "Electricity is what ties collecting to fighting", and at launch it ties nothing (`design-review.md` says the same). I'd go further: tightening to 1.2 to 1.4 times fixes the arithmetic, not the feeling. A player doesn't want kW. They want levels, stones, a reveal and a win. OPINION.
2. **The kW layer hides the characters.** Watt in a bay reads "Watt · 18 kW". A new Voidkin adds a number to a surplus, so collecting has no echo at home.
3. **The base was built as machines first.** Five or more passes (`state-of-the-game.md`) went to stages, landings, rings and plates (TR51), and none to the workers. The pillar's first words are "Workers at their bays".
4. **The first night away is short, and the game doesn't say so.** Two hours of generation, then the battery, then a quarter speed. TR53's card will show small numbers on day 2 unless the seed moves or the card explains the cap.
5. **The neighbourhood has a map and no verbs.** Plate, plinth and lit bays are in. Visiting and the plinth's tap wait (TR22). Most servers will hold one to three players for a long time, so no hook may depend on a neighbour being there.
6. **The Door ends the street.** The Festival's server takes eight at most (`docs/engineering-plan.md`, "Places"), but nothing fills it with your own eight.

## 4. Three ways to give the bays a real choice (ranked)

All three add into existing rate buckets, each with its ceiling (`docs/balance.md`, rule 5). None multiplies another. They sit on existing systems, but the README's proposed scope freeze still applies if the director takes it.

### A. A work knack for each Voidkin (first; about 7 h)

- **The rule:** every Voidkin has one knack, a single line saying what it adds to the base while it works in a bay. A knack pays in something players already want. Two of the same kind don't stack: the strongest counts, so a varied crew beats a doubled one. The lead works no bay, so choosing a lead means giving up its knack. Aptitude and kW stay as they are.
- **Seeds, one per class at launch** (a rarer Voidkin can carry its own later):

| Class (launch Voidkin) | Knack, working name | What it adds |
|---|---|---|
| Tank (Watt) | Big Wheel | its aptitude of 3, as today: the most kW |
| Mage (Pip) | Fine Work | the Condenser makes stones 20% faster |
| Healer (Lyric) | House Medic | a lead at home heals twice as fast (a fall's 90 s becomes 45 s) |
| Assassin (Kirra) | Night Shift | away, the bays generate 2 h longer (2 h becomes 4 h) |
| Warrior (Rook) | Sparring Partner | the trainee earns 20% more. **Needs the director's yes:** Training is "fixed rate" [D, 2026-11-14]. Without it: the Breaker's line breaks 20% faster, which is weak at launch |

- **On the screen:** the bay's chip gains one line ("Pip · 12 kW · Fine Work: stones +20%"). The pick list shows each knack beside its kW. In the world, a lit cable runs from the bay to the machine it helps, so the gate view shows who helps what.
- **The tie to fighting:** leading Lyric costs the faster heal at home. A fall hurts less with a Healer in a bay. Every reveal is a fighter and a new job. With two bays and four spare Voidkin at base level 1, the choice exists inside the first session.
- **Limit, said plainly:** at level 3, four spare Voidkin fill four bays, so the choice shrinks to who leads until the roster passes five. B covers that.
- **Cost:** research 2 h (the table and a simulation rerun), the builder about 5 h (a column in `Definitions/Voidkin.luau`, reads in `Rules.Power`, `Rules.Condenser`, `Rules.Training` and the heal, logic cases, the chip's line), the cable's look 1 h. Tier 2. The names need the IP-list check.

### B. Linked bays: who stands next to whom (second; about 5 h, after A)

- **The rule:** bays pair off (1 with 2, 3 with 4, 5 with 6; check against AR16's layout). Two workers in a pair who share an element are linked, and each one's knack counts half again (seed: +50% of the knack; for Big Wheel, +3 kW each).
- **At launch:** Fire links Rook and Pip. Storm links Watt and Lyric. Kirra (Void) links with nobody yet. Leading Watt breaks Storm, and leading Kirra keeps both links. So position and the lead both matter with only five Voidkin, and a shard that might hold a second Void is suddenly wanted.
- **On the screen:** a beam in the element's colour between the two rings, "Linked: Storm" on both chips, and a two-line exchange in bubbles when the link forms.
- **Cost:** the builder 3 h, the beam 1 h, research 1.5 h (two lines a pair, content-checked). Tier 2. Without A it only moves kW, which is hollow.

### C. Overdrive and one focus (third; about 5 h; it touches the director's designs)

- **The rule:** a machine may take up to twice its rated kW and then runs up to 1.5 times as fast, so the second half of the power buys less. One tap picks the Focus that gets the surplus (`design-review.md`'s Break, Train, Forge). What's left charges the battery as today.
- **Why:** it gives the surplus a use without shrinking anyone's numbers, and it makes "what do I want waiting when I come back, levels or stones?" a question asked once a session.
- **Needs the director's yes:** the Power screen is their design (tier 3), and Overdrive on the Training machine touches "fixed rate". On the Condenser alone it's tier 2. A simulation rerun comes first (research, 2 h).

**Rejected:** a Rush with a failure roll (loss and frustration), morale and rest (a chore timer), a second production chain (the Condenser's convert is one, and one is enough for a small game).

## 5. The alive list: ten signs, ordered by value per hour

| # | Sign | Who | Hours |
|---|---|---|---|
| 1 | Workers turn their heads to you and nod when you pass within 12 studs | the builder | 1.5 |
| 2 | Bark bubbles on six events: you return after 8 h or more, a shard finishes, the lead comes home fallen, the lead comes home after the keeper, the base levels, a link forms. Thirty lines for five Voidkin, 45 letters at most, one bubble per plot every 20 s | research writes and checks, the builder shows | 1.5 + 2 |
| 3 | A ready shard throws a pillar of light over the Breaker with a chime, seen from the spawn and the Strip | Scintilla, the builder | 1 + 0.5 |
| 4 | The lead walks in beside you after a run and the workers answer the result: a cheer or a wince, using 2's lines | the builder | 2 |
| 5 | A work loop per rig in place of the fight idle: three rigs (R6, Robe, Watt's), each inside the one-hour block-clip cap | Modulo | 3 |
| 6 | Tap a worker: it turns, plays a one-second emote, says a line and shows its chip. No reward at launch | the builder | 1.5 |
| 7 | "Lv +1" pops over the trainee and "+1" over the tray when it happens while you watch | the builder | 1.5 |
| 8 | Machine sound beds that follow load: the Mill's pitch with generation, the Breaker's hum with busy chambers, a tick as a stone lands. `Config/Music.luau`'s lists are still empty | Sonus, the builder | 2 + 1 |
| 9 | Voidkin with no bay lounge at set spots (the gate's rail, the Mill's rim). At base level 1, two of the five have no bay. Where they are today: check | the builder, Modulo (a lean clip per rig) | 2 + 3 |
| 10 | One personal prop at each worker's bay, arriving with the worker. Original, content-checked | Modulo, the builder | 2.5 + 1 |

Items 1 to 4 are about 9 hours and need no new art beyond one light. Every line of text passes the content check and the IP list.

## 6. The return moment, beat by beat

It builds on TR53; nothing here replaces it. Two cases.

**After hours away (a join):**

| Time | Beat |
|---|---|
| before the fade lifts | The world is already set: stones heaped in the tray, the battery's cells lit, a ready shard glowing in its chamber under its pillar (item 3) |
| 0.0 s | The spawn faces the Breaker, as today. The workers look up (item 1) |
| 0.5 s | One bark from the showcase Voidkin, picked by absence: under 1 h none, 1 to 8 h, over 8 h, over 3 days |
| 1.0 s | TR53's card slides in, headed with the time: "While you were away · 9 h". Four lines at most, each counting up |
| on the card | The honest cap, only when it bit: "Ran at full power for 6 h. Base level 2 holds 10 h." The limit becomes a goal |
| one tap | "Collect": each amount flies to its counter (TR53), and the stones leave the tray in the world on the same frame |
| last line | If a shard is ready, the press is "Reveal". It never plays by itself. The game's signature moment becomes the return's peak |
| after | One suggestion, not a list: "Bay 3 is empty. Pip could work there." Then the Festival Door brightens |

**After a run (minutes away):** no card unless a shard broke. The lead walks in with you, the workers answer the result (item 4), and a fallen lead is seen healing on its pad, faster with a House Medic at work.

**Rules:** one tap clears it; under 6 seconds; walking away dismisses it; the server credits on arrival (TR53 already says so); nothing random, nothing sold.

**One seed to review (tier 2, research's simulation):** `AwayHours` from 2 to 8, so the first night away runs whole. Night Shift then adds on top. Egg, Inc. and AFK Arena size their caps to a night's sleep; ours covers about 4 hours on day 1.

## 7. The neighbourhood at launch

**Do (small, honest, safe):**

1. **A reveal is seen from the street.** A Rare or better throws its light above the base, and the Strip shows one line with the owner's display name and the Voidkin's name. Neighbours can walk over and see it on the plinth. The rarer, the louder (the README's item 7). The builder, 2 h. Tier 1 or 2.
2. **The plinth's tap** opens that Voidkin's sheet as a visitor sees it. TR22 already lists it as waiting. It serves the north star's "two players compare builds and argue". The builder, about 3 h.
3. **One Spark a day for each neighbour.** A visitor presses one prompt at a neighbour's Mill. The owner's Condenser gets 15 minutes of work done at once, and so does the visitor's. At most 7 received a day. It's fixed, free, never random and never an item, so there is nothing to duplicate or scam. The gate's plate counts Sparks received. The builder, 3 h. Tier 2: a small new source in the economy, so the director is told.
4. **Friends on one street.** Roblox's Friends signal already prefers a friend's server. Add the invite prompt after the first keeper falls (`retention-and-discovery.md`, item 4), its launch data naming the inviter so the newcomer is walked to that plot.

**Wait:** trading and gifting Voidkin (F4: exploits and a grey market; "Fighters are valuables"), stealing of any kind ("look, never touch" [D]; upset children aren't premium), shared or co-owned bases, guilds, the Clash Grounds and the Calamity (already after the cut line), and free private servers. Private servers are a dashboard switch at release, the director's hand, and nothing is released now.

**It must work alone.** Empty lots stay bare [D]. No goal, reward or tutorial step may need a neighbour.

## 8. The base and the Festival: so the fight isn't leaving home

1. **One Festival server per street** (first, about 3 h). Each main server keeps one reserved Festival id, and everyone who takes its Door lands in the same Lantern Row. Your neighbours become the people you fight beside (H7's second bullet), shared packs and joinable elites finally have known faces, and reserved-server sessions count as co-play. Limits, from MAIN's `docs/research/game-mode-places.md`: a new server takes about 5 to 6 s to start; a friend can't follow straight into a reserved server (they join the street first, which is what we want); nothing solid on how long a reserved server lives. Tier 2: routing is the builder's area, with research; the director is told.
2. **Go together.** If a neighbour stands in the Door's ring when you press, both travel in one call. It isn't a party system: no screen, no leader. The director's "parties last" stands. If they read it as a party, it waits.
3. **The base speaks during the run, in a character's voice.** TR53's notice becomes a worker's portrait and line: "Pip: your shard cracked. Come see." The same facts, said by somebody.
4. **The Door is a send-off, not a loading screen.** The workers turn as you step in. The teleport screen shows your own base and one line ("Watt keeps the lights on"). `SetTeleportGui` and the arrival screen are already in the trip (TR45).
5. **Carry a charge (the bold one).** At the Door, spend battery to take power into the run. It would be the battery's first sink at launch (`docs/balance.md`: "The battery has no sink") and the plainest reading of "electricity ties collecting to fighting". Two versions:
   - *Charged start*, 20 kWh: the lead's signature is ready as the run begins. Tier 2, after TR52's tap is accepted.
   - *Spare cell*, 40 kWh: once a run, a lead that would fall stands back up at 30%. **Tier 3:** it touches "A fall sends it home" [D, 2026-11-14].
   - MEASURED, rough: a run of 10 to 15 minutes banks about 4 to 8 kWh of surplus, so a charge is a real saving, not a button pressed every run.
6. **The first breach** (F7 in `design-holes.md`: the first fight at home, tier 3) remains the strongest single fix for the first session. It's endorsed here, not restated.

## What touches a confirmed decision

| Proposal | Decision it touches | Needs |
|---|---|---|
| Sparring Partner; Overdrive on Training | Training's "Fixed rate, no cap" [D, 2026-11-14] | the director's yes |
| Three focus taps in place of the drag bar | the Power screen [D, 2026-11-14] | the director's yes |
| Spare cell | "A fall sends it home" [D, 2026-11-14] | the director's yes |
| Go together | "parties last" | the director's reading |
| Free private servers, the invite prompt | release settings | the director, at release |
| Knacks, links, Spark, `AwayHours`, one Festival server per street | none found | tier 2: research and the builder, the director told |

## Top 5 to act on

1. **Work knacks (4A), then linked bays (4B).** Research 3.5 h (the tables, the lines, a simulation rerun); the builder 8 h; the cable and beam 2 h. Tier 2. Only Sparring Partner needs the director's yes.
2. **Alive pack one: items 1 to 4 of the list** (look-at, barks, the ready-shard pillar, the lead comes home). The builder 6 h, research 1.5 h, Scintilla 1 h. Tier 1 and 2, no yes needed. It's the cheapest proof of pillars 1 and 3 together.
3. **Build TR53 as written, with section 6's additions:** the world set before the card, the honest cap line, the absence bark, and `AwayHours` reviewed from 2 toward 8. The builder: TR53's own 3 h plus about 1.5 h; research 1 h on the seed. Tier 2.
4. **One Festival server per street.** The builder 3 h, and a round-trip test. Tier 2, the director told. "Go together" follows if the director reads it as inside "parties last".
5. **Neighbour hooks: the reveal seen from the street, the plinth's tap, one Spark a day.** The builder about 8 h in all. The first two are tier 1 and 2. The Spark is a tier 2 economy notice. Trading and stealing stay out, and the director's "look, never touch" stands.

**Not fetched or thin:** Pecorella's own slides, PC Gamer's and GamesRadar's article bodies, AFK Arena's guides, every Fandom wiki (payment or login walls), Roblox's default signal weights. Cookie Clicker, Egg, Inc. and Spiritfarer's moods are from memory and marked so. The web search budget ran out partway, so Dave the Diver, Two Point, Stardew, Animal Crossing and Clash of Clans weren't studied.
