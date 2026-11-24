# Systems that marry: how the best games feel like one game, and the method we can copy

A cloud research agent, 2026-11-24, read-only on main. It answers the director's words of that day: "designing a game with the small details that comes with big systems ... look at how gta 6 systems marry each other this is the synchronization and holes details filed ... just to make it 1 whole premium game". This is the outside study and the method. Four sibling audits cover our own seams in detail; here ours is judged only at the pillars and the loop. It builds on `docs/research/design-holes.md` (2.2, 2.4, H7, F4, F6) and doesn't repeat it.

**Labels:** SOURCED (page fetched today, link in "Sources"), COMMUNITY (a talk, video or wiki I know but could not fetch today: treat as unverified until someone opens it), OBSERVED (read in our repo, path given), OPINION (my call). Every proposal is a proposal; every number is a seed to tune by playing.

## Verdict

1. **Cohesion isn't volume.** Rockstar's worlds react because a few account-wide readings (honour, bounty, now a "Criminal Profile") are read by many systems, and because they cut what doesn't sit: about five hours left Red Dead Redemption 2, and a grocery system left GTA VI because it "complicated the mechanics". SOURCED.
2. **The same four moves recur in every studio studied:** one object with many faces, a few rules applied everywhere, every ending pointing at the next activity, and the world answering what the player did.
3. **Our skeleton is better married than it feels.** A Voidkin has six faces, Combat Power reads every progression, and electricity really does tie collecting to the Breaker. OBSERVED. What's missing is the answering: nothing in the base knows about the fight, nothing in the fight knows about the base, and no one in the world notices who you brought.
4. **The method is cheap:** one N×N matrix, one source and sink ledger, one clock table, one "what if" list and a twelve-question gate. About half a day once, then 15 minutes a piece. It must replace paper, not add to it (`README.md`, item 10).
5. **Marry before adding.** The eight marriages below are joins between systems we already have. None is a new system, and none comes before the director's phone run (`README.md`, item 1).

## 1. What the best do

### Rockstar: a few readings, read everywhere

- **GTA VI is out:** 19 November 2026, PlayStation 5 and Xbox Series X/S. SOURCED (Wikipedia). Five days on, almost no designer has written about its systems, so the rest leans on Red Dead Redemption 2.
- **What's documented for GTA VI.** SOURCED:
  - a "Criminal Profile" that works "similar to the honour system in Red Dead Redemption 2": it "evaluates the level of violence and escalation used during crime, dynamically altering in-game consequences and NPC reactions";
  - NPCs with personality traits set by their district, whose behaviour depends on how the player has treated them;
  - the two leads' relationship "depends on the player's actions", and with the Profile and a "Family Savings" balance it picks the ending;
  - weather that is "much more localised and persistent"; storms cut visibility.
- **Red Dead Redemption 2's honour is one number with many readers.** SOURCED. Fed by: helping strangers, obeying the law, sparing a duel's loser, theft, harming innocents. Read by: shop prices, loot, outfits, dialogue, mission scenes, the ending.
- **The bounty is a chain, not a meter.** A witness reports, the law comes, the bounty grows, bounty hunters track, the region locks down, and it ends at a counter where you pay. Each step is a different system handing on to the next. SOURCED.
- **Hunting crosses four systems with one object.** The weapon and where the shot lands set a pelt's quality, which sets money, crafting and food; a carcass left out rots and draws predators. SOURCED.
- **The camp keeps the character between modes.** Gang members keep "the same personality and mood" from cutscene to play; they have routines; answer them often and they talk to you more. Nelson: the team was "obsessed with [the world] feeling natural or organic in every respect". Garbut: "building a place, not a linear or static representation". SOURCED.
- **What it cost:** about 500,000 voiced lines, 80-page scripts for single pedestrians, ten times GTA V's animations, about 1,600 developers. SOURCED. We copy the principle, never the volume.
- **Where their systems don't marry.** SOURCED:
  - missions are "linear scenarios with set objectives"; Eurogamer's reviewer "voiced frustration at the lack of freedom in some story missions";
  - realism "restricted opportunities and unnecessarily prolonged some animations", and the controls and interface were "inconsistent and confusing";
  - of GTA VI, one review: "large sections where it is an absolutely epic game, and large sections that are boring and too limited".
- **The lesson:** the player learns the rules in the open game, and feels it at once when a set piece suspends them. A mode may narrow the rules, but it should say so, and never contradict them.
- **For us:** the keeper's ring and the Tower freeze the lead and Regalia, and say so (`docs/design.md`, "Combat"). That's a narrowing, stated. Keep it that way: every keeper and Tower foe uses the one states ladder ("One ladder for everyone who fights"), and each exception (a Shade's Void carries no Sap; the Tower's "lighter build") goes on one short list.

### Nintendo, Breath of the Wild: few rules, multiplied

- A physics engine plus a "chemistry engine" that "defines the physical properties of most objects and governs how they interact with the player and one another". Metal draws lightning, wood burns, cold water takes ice. Aonuma: the engine "underpins everything in the world". They tested the rules first in a cheap 2D prototype. SOURCED.
- **The three rules** from the GDC 2017 talk "Change and Constant". COMMUNITY (the talk as widely reported; the GDC Vault page held no detail and Polygon refused the fetch):
  1. an element (fire, water, electricity, wind) changes a material's state;
  2. an element changes another element's state;
  3. a material never changes another material.
- **"Multiplicative gameplay"** (the same talk, COMMUNITY): designers stop writing one answer per problem. Each new object multiplies with every rule already there, so content grows faster than the work.
- Harvey Smith reached the same place in 2001: the moments that failed "tended to rely on special-case triggering or scripting", the ones that worked on "the interaction of flexible sub-systems". His fix: a bullet carries properties (ballistic, heat, electricity) and objects answer properties, never each weapon by name. SOURCED.
- **For us:** our chemistry is small and already written: the type ring, four elements with one state each, and poise (`docs/design.md`, "States in a fight"). The test for `grounds-and-encounters.md`'s new Shades: each is a new *combination* of existing rows, never a new rule. One new rule a ground at most.

### Supergiant, Hades: failure is the delivery van

- Kasavin: "It was an explicit goal of our early development, to take the pain out of dying and having to restart", and the player must "feel the time you spent wasn't a waste of your time". SOURCED.
- Death is where the other systems live. Dialogue "advance[s] with each run", standing with characters "unlocks narrative elements and quests", and what you carried back is spent in the House on permanent upgrades. About ten hours of dialogue for many possible chains; "Reactivity has always been a goal of our narrative design". SOURCED.
- **Each currency has one job and one door.** COMMUNITY (from memory; the wiki returned an error): Darkness to the Mirror's talents, Gemstones to the House's contractor, Keys to weapons, Nectar to gifts, Titan Blood to weapon aspects. A gift returns a keepsake: a friendship that is also a piece of combat gear. One object, two systems.
- **For us:** "A fall sends it home", where the fallen lead heals and then trains (`docs/design.md`, "Combat"). That's the Hades shape on paper. What's missing is the saying of it: the fall is silent. See marriage 2.

### Monster Hunter: every system faces the next hunt

- The hunter "does not grow and has no intrinsic statistics or attributes whatsoever". All power is gear, all gear is monster parts, and better gear opens harder monsters. Even the companion cooks and gardens for the hunt. SOURCED.
- **The lesson:** one anchor. Ask of any system "how does this help the next hunt?", and it has an answer or it isn't in the game.
- **For us:** our anchor is the next keeper's recommended Combat Power. Three progressions feed it (the Voidkin's level and stars, Regalia, the Training machine); the base's level feeds it only through electricity and the Breaker. That's fine, if every screen shows the way back to the anchor.

### Stardew Valley, Animal Crossing: the calendar is the glue

- Four 28-day seasons; crops die at a season's end; energy refills each morning. Cooking was made unprofitable on purpose: its job is buffs for the other skills, not money. Bundles ask for goods from every activity and open new areas. A spouse helps on the farm. SOURCED.
- Animal Crossing runs on the real clock: most things come back the next day, some creatures only in season. The team removed waits from crafting and cut bank interest so that cheating the clock pays little. SOURCED.
- **The lesson:** systems marry in time as much as in resources. One system, one job (cooking). And a clock is a promise: don't set a timer the player can't answer.
- **For us:** see rule 11 and the clock table in section 4.

### Genshin Impact, Honkai: Star Rail: one property makes collecting matter in a fight

- Every character holds one element, reactions need two, the party is four, and the same elements solve the world's puzzles. So each new character changes combat and exploration, not just a number. SOURCED.
- The pacer (Resin) "slowly regenerates over time", and it's the most criticised part: the endgame becomes "a slog" and resin "feels so unnecessary" (PC Gamer). SOURCED.
- **For us:** our pacer is better than resin, because the collection makes it: workers make the electricity the Breaker runs on. Keep it taut (`design-holes.md`, H4). Our weak side is theirs strong: with one automatic lead, a second Voidkin changes little in a fight (`combat-agency.md`, `collection-and-economy.md`).

### Supercell and Pokémon: one object, every system

- **Clash Royale:** a card is collected, requested from clanmates, upgraded with copies and gold, and played. Upgrades raise the King Level, trophies open arenas, arenas open cards. Costs rise so players "must choose where to spend". Supercell removed chest timers in April 2025: even a founding system goes when it stops serving. SOURCED.
- **Pokémon:** Tajiri's link cable idea came before anything else: "I imagined a chunk of information being transferred by connecting two Game Boys". Version exclusives and trade evolutions mean the collection can't be finished alone. The same creature is the collectible, the fighter and the trade good. SOURCED.
- **For us:** a Voidkin already has six faces (section 4). Don't add a trade face: Roblox's rules and our "fighters are valuables" make it costly, and the showcase plinth is our social face.

### The systemic-design writers

- **Smith:** systemic play costs feedback. "Better user feedback is required to avoid confusing the player". A link the player can't see doesn't exist. SOURCED.
- **Spector:** "Always show the goal." "Without real, predictable consequences, choice is irrelevant." "Descriptions of game systems are no substitute for prototypes and actual implementation." And: "cut it and do everything that's left so well that no one notices the stuff that isn't there". SOURCED.
- **McEntee (Ubisoft's rational design):** "there is no such thing as a vague atomic parameter"; a skills-against-inputs matrix; a "variety matrix" that lists every ability, tool and space and marks combinations nobody thought of. SOURCED.
- **Cook:** a loop is exercised again and again, an arc is "a broken loop you exit immediately". Ask "What repeats and what does not?" SOURCED. His value chains: `design-holes.md`, 2.2.
- **Mark Brown, "The Rise of the Systemic Game":** systems are "aware" of each other because they share inputs and outputs, not because someone scripted each pair. COMMUNITY (video, not fetched).

## 2. The rules, each with its test

| # | Rule | The test (pass or fail) | From |
|---|---|---|---|
| 1 | One object, many faces | each core object is read by 3 systems or more; name them | Pokémon, Clash Royale, Hades' keepsake |
| 2 | Two out, one in | in the matrix, every system's row has 2 filled cells and its column 1 | Cook, Monster Hunter |
| 3 | Few rules, everywhere | a new enemy, machine or mode uses only existing properties; exceptions fit on 5 lines | Breath of the Wild, Smith |
| 4 | Same rules in the set piece | a keeper or Tower fight narrows rules and says so; it never contradicts one | Red Dead Redemption 2's critics |
| 5 | One reading, many readers | one account-wide number drives 3 visible reactions or more | honour, the Criminal Profile |
| 6 | Failure pays forward | a lost run shows one thing kept and one thing changed | Kasavin |
| 7 | The loop closes | every end screen names the next act, in a different system | Monster Hunter, Spector |
| 8 | The world answers | each major act draws one reaction elsewhere, the same session | Rockstar's camp, Hades |
| 9 | No orphan, no dead end | every resource reaches the anchor in 3 steps or fewer, and has one main job | Cook, Stardew's cooking, Hades |
| 10 | Collection matters in the fight | owning a second fighter changes how a fight goes, in the first hour | Genshin |
| 11 | Compatible clocks | each cycle fits whole into the next; no timer asks for an act the player can't take where they stand | Animal Crossing, resin's critics |
| 12 | One word, one colour, one sound per idea | the consistency sheet has no idea with two entries | Red Dead Redemption 2's interface criticism |
| 13 | Detail where the eye rests; cut the rest | the 5 most-seen seconds are listed, and detail hours go there first | Houser's cuts, GTA VI's groceries |
| 14 | Every link has a cue | each cross-system effect shows within 2 s of its cause | Smith |

## 3. The method

| Tool | What it looks like | Time | What it catches |
|---|---|---|---|
| **Interaction matrix** | N×N table; row A, column B: "what A gives B" and "what B shows of A" | 1 to 2 h once, 10 min a new system | islands, one-way links, a system fed by nothing |
| **Source and sink ledger** | one row per resource: sources, sinks, cap, overflow, the anchor it reaches (Machinations in table form) | 1 h, plus a simulation we already own | orphans, pooling, a cap with no overflow |
| **Loop line** | one sentence per loop (session, day, week), each clause one system | 30 min | a chain that stops, a clause no system owns |
| **Journey state chart** | the player's states (at base, in a run, lead fallen, bag full, away) and every exit | 1 to 2 h | a state with no exit or no feedback |
| **One-page design** | one page, mostly a picture; Librande: "why create a document with more than one page if most people only read the first page anyway?" SOURCED | 1 h a system | a system nobody can explain |
| **Pillar filter** | each proposal against the four pillars, yes or no (`directing-the-game.md`) | 5 min | work that serves no pillar |
| **"What if" list** | for each pair of systems, the awkward cases, each with its answer | 30 min a pair | edge states: full, empty, mid-change, away |
| **Clock table** | every timer with its length and where the player must stand to answer it | 20 min | a timer that can't be answered, cycles that don't nest |
| **Cross-system playtest** | a 20-minute script that crosses every seam twice ("the round trip") | 20 min a build | a cue missing at a handover |
| **Details backlog** | one line each, tagged with seconds seen per session; worked from the top | running, capped at 30 lines | polish spent where nobody looks |
| **Consistency sheet** | one row per idea: its word, colour, icon, sound | 2 h once | two words or two golds for one idea (`ui-colour-review.md` found about 9 golds) |

**Keeping it cheap.** OPINION: one file of about 120 lines holds the matrix, the ledger, the clock table and the sheet. It replaces prose; it's updated only when a system is added or cut; and the checklist in section 6 is the only gate. If it grows past its page, it's wrong.

### A filled-in miniature: "Tidewatch" (made up, three systems: Fishing, the Lamp, the Market)

| gives → | Fishing | Lamp | Market |
|---|---|---|---|
| **Fishing** | — | the catch renders into lamp oil | fish to sell; today's best catch hangs on the stall |
| **Lamp** | a lit lamp adds 2 h of night fishing and draws deep fish | — | a lit lamp brings 2 more ships of buyers |
| **Market** | sells nets and bait | sells lenses (a wider beam) | — |

- **Ledger.** Fish: from Fishing; to the Market (coins) and the Lamp (oil). Oil: from fish; burns 1 jar an hour; cap 6; past the cap it sells. Coins: from the Market; to nets, bait, lenses. **Hole found:** deep fish drop pearls, and nothing takes pearls. Cut them or give them a job.
- **Loop line.** Fish, render oil, light the lamp, fish the night for deep fish, sell them, buy a lens, light further. It closes.
- **What if.** The lamp dies mid-trip: the boat comes home safe, the catch is kept, the deep fish leave. The hold is full: the line won't cast, and says why. Three days away: the lamp is out, the moorings are empty, one line says so on return.
- **Clocks and sheet.** A trip is 3 min, a market day 20, a jar 60: six trips fit a day and three days fit a jar, so they nest. Oil is amber everywhere, the lamp is "lit", never "on", and one bell means a ship.
- **What the matrix showed:** the Market shows nothing of a dark Lamp. Fix: empty moorings, a look, no new rule.

## 4. Applied to ours, at the pillars

### Who sees each core object

| Object | Systems that see it today (OBSERVED) | Should, and doesn't (OPINION) |
|---|---|---|
| **A Voidkin** | the Breaker's reveal; the lead in a fight; a bay worker by aptitude; the Training machine; stars from copies; the Tower's first five foes; the showcase plinth; two Today goals (`docs/design.md`; `src/shared/Definitions/Goals.luau`) | the bay doesn't know who it is: "Apt ... has nothing to do with combat" (`docs/roster.md`, line 15), so a worker is a number from 1 to 3. No enemy or keeper reacts to who leads. The reveal doesn't say what the newcomer is for |
| **A shard** | dropped in fights and named for its ground; sold in the shop; paid by Today's goals; queued and broken in the Breaker; the bag | a run: the shards' hint shows only at the base (`src/shared/Rules/Hud.luau`, `Hud.ShardHint`, on the director's word of 11-15), and the Festival is another place, so "a shard cracking while you fight" (pillar 3) isn't felt (`design-holes.md`, H7) |
| **Electricity** | bays make it; the Breaker, the Condenser and the Training machine draw it; the battery, voltage, overflow into Credits; the Void Mill as its own gauge | the fight: nothing in a run makes, spends or shows power. And it may be slack (H4), so the Power screen's split may have one answer |
| **Gear** | chests from Shades, elites, keepers and the Tower; the shop's featured piece; Reinforce, emblems, jewels; presets by class; Combat Power | the world: never on the body [D], so Combat Power's number is its only face outside a menu. No goal names gear (`Goals.luau`) |
| **Credits** | from fights, overflow, copies past seven stars; to the shop, Reinforce, the Condenser, the base and the machines | fine as the hub. The risk is selling them (`README.md`, item 3) |
| **Research Points** | a field in the profile (`src/shared/Data/Profile.luau`), with no source and no sink at launch | nothing: keep it unseen until the Lab exists |
| **Combat Power** | reads level, stars and gear; shown against each ground, keeper and Tower floor | our "honour": one reading, many readers. The base's level isn't in it, and needn't be |

### The eight marriages (joins, not systems; together about 20 builder hours, 4 of Modulo's, 4 of research's, all seeds)

1. **The reveal says what the newcomer is for.** After the name, one line from data: "Blue. Beats Red: most of Lantern Row." or "Your best worker yet." The peak moment then points at the fight and the base (rules 1, 7). It fits the plate in `reveal-and-showcase.md`. Cost: the builder 2 h, research the line patterns 1 h. Tier 2.
2. **A fall that pays, said out loud.** The fall's card names what the run kept (shards, chests, experience), where the lead is ("Healing at home, then training") and the Next line (rule 6). The rules already exist; the saying doesn't. Cost: the builder 2 h. Tier 2.
3. **The keeper notices who you brought.** One dry line on the keeper's card as the ring closes, picked by the lead's type edge and by the try count (first try, third try, back after a win). Five Voidkin and one keeper make about 8 lines (rule 8). Research writes them to the goals' word rules; the content check reads them. Cost: research 1 h, the builder 2 h. Tier 2.
4. **The base comes with you.** F6 of `design-holes.md`: in a run, one quiet chip when a chamber finishes. Then pillar 3 is true from the player's camera. Cost: the builder 2 h. Tier 2; research judges whether the director's 11-15 word on the shards' hint covers it, and asks if in doubt.
5. **You come home to something.** F4 of `design-holes.md`, the return card. Add one reaction in the world: after a keeper's win, the workers look up as the lead walks in. Cost: F4's 3 h, plus one shared clip from Modulo (1 h block). Tier 2.
6. **Workers are somebody.** A bay takes its worker's element as its light, and the worker has an idle of its own at the bay. Aptitude's 1 to 3 gets a reason in the character's row. Look only, no number changed (pillars 1 and 3). Cost: Modulo 2 h a rig family, the builder 2 h. Tier 2. A real link between work and combat (a rested worker starts its first fight with its signature ready, say) changes balance and the roster's "nothing to do with combat": tier 3, and it waits.
7. **A keeper's win is felt at the base.** One state link from fight to base: for an hour after a keeper falls, the bays run a little hot (seed: +10%), and the Void Mill shows it. The first thing in a fight that touches electricity (rules 2, 5). Cost: the builder 3 h, research the simulation 1 h. Tier 3: economy.
8. **The Tower remembers your roster.** Floors 1 to 5 are already Rook, Pip, Kirra, Lyric and Watt in an enemy look (`docs/design.md`, "The Tower"). When a player's own Voidkin beats its shadow, its collection card keeps the mark and the floor. Six faces become seven, with no new art. Cost: the builder 2 h. Tier 2.

### Five anti-patterns for us

1. **The bolted-on machine.** A machine whose whole design is "X in, a timer, Y out". The Condenser and the Training machine are near this line; the Lab would cross it. Each machine must pass rule 2 before it's built.
2. **The orphan currency.** Research Points today; three grades of forge stone are one currency wearing three names unless each grade has its own door. Void Essence was rightly cut.
3. **Parallel ladders that never meet.** A Voidkin's level and stars, Regalia's Reinforce, emblems and jewels, the base and its machines. They meet in one number. If a ladder stops moving Combat Power, or moving the keeper, it's a side game (Katkoff's Builder Base, `design-holes.md`, 2.2).
4. **The mode that suspends the rules.** Each exception is reasonable alone (no Sap from Shades, a lighter Tower build, frozen gear at a keeper). Rockstar's missions are what twenty of them feel like. Keep the list, cap it at five.
5. **Reactivity by volume.** 500,000 lines isn't our lesson. Three reactions a system, each from data we already hold, placed in the five most-seen seconds. A reaction nobody sees is paper.

## 5. Frank critique of where we stand

- **We designed the nouns well and the verbs between them badly.** OPINION. `docs/design.md` gives each system a careful section, and the handovers get a clause. The loop is one paragraph; the base alone runs to about forty lines (OBSERVED).
- **The base and the fight share a save and nothing else the player can see.** OBSERVED (H7; `Hud.ShardHint`). That's the single biggest reason the game reads as two games.
- **Our clocks don't nest.** OBSERVED in `docs/design.md`, MEASURED by hand: the shop turns every 5 min and a run takes 10 to 15, so a run misses 2 or 3 stocks it can't reach from the Festival place. A Standard shard breaks in about 30 s, so chambers sit idle for a whole run unless the line is full. Today's goals reset at 00:00 UTC, fine. Rule 11 fails on the shop: either the featured stock outlasts a run, or its chip stays quiet in one. The 5 minutes are the director's, so that's their call.
- **The words mostly hold; the colours don't.** One string for Combat Power and one ladder of states are right. Nine golds aren't (`ui-colour-review.md`).
- **The exceptions list doesn't exist.** They live in dated bullets across `docs/design.md`.

## 6. The cohesion review: twelve questions before anything is built

1. Which pillar does it serve? Name one.
2. Which core object does it read? If it brings a new one, why can't an existing one do the job?
3. What does it give two other systems? What gives to it?
4. Does it use only existing rules and states? If it adds one, where else will that rule apply?
5. Does every resource in it reach the next keeper in three steps or fewer?
6. When it ends, what does it point at next, in a different system?
7. What does the player keep when they fail in it?
8. Who or what in the world notices it happened?
9. What's its clock, and can the player answer it from wherever they'll be?
10. What happens when it's full, empty, interrupted, or the player is away?
11. Does every idea in it use the sheet's word, colour and sound?
12. Where will the player's eye be, and is the detail there?

A "no" on 1, 3 or 6 sends it back. Any other "no" is written on its request entry in one line.

## Top 5 to act on

| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **One cohesion page:** the matrix, the ledger, the clock table and the exceptions list, about 120 lines, replacing prose. The twelve questions become a block on each new request entry | research | 3 h once, 15 min a piece | no, if it replaces paper; yes if it becomes a rule in `AGENTS.md` |
| 2 | **Close the loop at every ending:** the run card, the fall card, the Tower's results and the reveal each end on the same Next line plus one fact from another system (marriages 1 and 2) | the builder; research the lines | 4 to 5 h | no (tier 2) |
| 3 | **The world answers three times:** the keeper's line, the chip when a chamber finishes, the workers looking up (marriages 3, 4, 5, with F4 and F6) | research, the builder, Modulo one clip | about 8 h | only if research reads the 11-15 hint word as covering the chip |
| 4 | **Workers are somebody, look only** (marriage 6), tried on one bay and one Voidkin as a blockout first | Modulo, the builder | 4 h for the blockout | no for the look; yes for any link to combat |
| 5 | **The clock and orphan pass:** decide the shop's clock against a run's length, keep Research Points unseen, cap the exceptions at five | research audits; the builder 1 h | 2 h | yes for the shop's clock; the surge of marriage 7 too |

All of it comes after the phone run, and inside a scope freeze if the director calls one: these are joins, not systems.

## Sources

Fetched today (SOURCED):
- Wikipedia: [Grand Theft Auto VI](https://en.wikipedia.org/wiki/Grand_Theft_Auto_VI), [Red Dead Redemption 2](https://en.wikipedia.org/wiki/Red_Dead_Redemption_2), [its development](https://en.wikipedia.org/wiki/Development_of_Red_Dead_Redemption_2), [Breath of the Wild](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Breath_of_the_Wild), [Hades](https://en.wikipedia.org/wiki/Hades_(video_game)), [Monster Hunter](https://en.wikipedia.org/wiki/Monster_Hunter), [Genshin Impact](https://en.wikipedia.org/wiki/Genshin_Impact), [Stardew Valley](https://en.wikipedia.org/wiki/Stardew_Valley), [Animal Crossing: New Horizons](https://en.wikipedia.org/wiki/Animal_Crossing:_New_Horizons), [Clash Royale](https://en.wikipedia.org/wiki/Clash_Royale), [Pokémon Red, Blue and Yellow](https://en.wikipedia.org/wiki/Pok%C3%A9mon_Red,_Blue,_and_Yellow), [Immersive sim](https://en.wikipedia.org/wiki/Immersive_sim). Wikipedia is a secondary source: the developers' quotes are as it reports them.
- Game Developer: [Kasavin on Hades](https://www.gamedeveloper.com/design/how-supergiant-weaves-narrative-rewards-into-i-hades-i-cycle-of-perpetual-death), [Spector's Deus Ex postmortem](https://www.gamedeveloper.com/design/postmortem-ion-storm-s-i-deus-ex-i-), [McEntee on rational design](https://www.gamedeveloper.com/design/rational-design-the-core-of-i-rayman-origins-i-).
- [Smith, "The Future of Game Design"](https://www.witchboy.net/articles/the-future-of-game-design-moving-beyond-deus-ex-and-other-dated-paradigms/); [Cook, "Loops and Arcs"](https://lostgarden.com/2012/04/30/loops-and-arcs/); [Librande, "One-Page Designs"](https://www.gdcvault.com/play/1012356/One-Page) (the session's description only).

Not fetched (COMMUNITY, from memory; check before quoting):
- The session's web searches were used up, so nothing was found by search: every page above was opened by its known address.
- Breath of the Wild's three chemistry rules and "multiplicative gameplay": the talk's [Vault page](https://www.gdcvault.com/play/1024562/Change-and-Constant-Breaking-Conventions) describes nothing, and Polygon refused. Hades' currency map: the wiki returned an error. Mark Brown's video and Vulture's Red Dead Redemption 2 feature: not reachable.
- Honkai: Star Rail, Brawl Stars, and Rockstar's or Naughty Dog's detail passes: nothing was read on them today, so this file makes no claim about them. Dormans, Adams and Cook's value chains were read by `design-holes.md`, not again here.
