# Balance

How every number in the game is put together, so that nothing compounds. The rules here are the design. The numbers are seeds in `tools/balance/seeds.json` (until the game's own Definitions hold them) and are tuned by play.

The director, 2026-11-11: "avoid compounding (which was an issue i noticed on next button simulator all the multipliers led to me in 1 session having over 2296x in clicker which was not what i intented ... i was thinking of a x + x + x)".

**Status:** the structure is designed and tested by simulation (`py tools/balance/sim.py`, run of 2026-11-11, below). Nothing is played. A simulation checks the numbers against each other; it doesn't know what players will do.

## The one rule

**Things add. Almost nothing multiplies.**

1. Every source of power (level, gear, forge, emblems, jewels, research, stars) gives **flat points** to a stat. None gives "a percent of your attack".
2. Two exceptions, both a percent of the thing's **own base** and both linear: an item's Reinforce level on that item, and a Voidkin's stars on its own base stats. Neither touches the total.
3. Growth comes from **authored tables**: a level's row, an item tier's row. Getting stronger means a better row, not another multiplier.
4. A hit multiplies in **four places only,** each with a ceiling: the defender's mitigation, the attacker's bonus bucket, the defender's reduction bucket, and the level gap [D, 2026-11-19, 03:10]. Everything that would be "a damage boost" is a number added into one of the two buckets.
5. Every earning rate (Credits, experience, electricity, luck) has **one bucket** of bonuses that add, and a ceiling.

A new system joins by adding points to a stat or a number to a bucket. If it can't be written that way, it's a core change and goes to the director.

## Growth

One curve, `G(level)`, gives the size of everything at a level: a Voidkin's base stats, an item tier's stats, an enemy's health, a reward. The level cap is 125, and the launch is designed to 60, where G is 22 [D, 2026-11-14, night: "the level cap is 125 but the launch is designed for level 60 simple is as that"]. Past 60 the same curve runs on (G about 77 at 125); the pace there is designed with the grounds that reach it. Because rewards, costs and enemies follow the same curve, a higher level changes what a player fights, not how fast the numbers run.

## Where power comes from

Shares of a full launch build's stat points, at level 60:

| Source | Share | How it's earned |
|---|---|---|
| The Voidkin's own base (level and rarity) | 35 | fighting |
| Its stars | 3.5 | duplicates |
| Gear | 27 | drops, the shop |
| Reinforce levels | 13.5 | stones and Credits, by chance past +5 |
| War Emblems | 11 | drops, the shop |
| Jewels | 7 | elites, keepers, the Tower |
| Research | 3 | Research Points |

- **What each ground makes available** is `tools/balance/seeds.json`, "available". Emblems at Lantern Row are 0.10 of full, down from 0.15 (research, 2026-11-19, 20:55): one Uncommon emblem a socket gives 6 to 12%, so gear carries the early power. The tables below come from before that change, which moves a Lantern Row build by about 1% (0.55 of its about 57 share points, worked by hand).
- **Rarity** multiplies a Voidkin's own base only, from 1.00 for a Common to 1.50 for a Mythical. Since the base is about a third of a build, a Mythical at a full build has about 19% more of each stat than a Common at a full build.
- **Skill points** come later, inside a skill tree (`docs/design.md`, "Skill points"). None are in the game now.
- **Class** sets a Voidkin's own points by its shape and its Main ("Basic Attributes", below). It doesn't touch gear, but for the weapon pair each class holds.
- **Gear is the account's,** so most of a build carries over to whichever Voidkin leads.

## The stats

The Battle Attributes, which every fight reads:

| Stat | Kind | What it does |
|---|---|---|
| Health, Attack, Defence | points | the three every source adds to |
| Regen | points | health in one burst every 8 s, always, in a fight too (`docs/design.md`, "Health carries"; TR40) |
| Speed | studs a second | a lead's walk speed in a fight, by class and Voidkin (`docs/design.md`, "Speed") |
| Hit | rating | against the target's Dodge and Block |
| Dodge | rating | chance to avoid a hit entirely |
| Critical | rating | chance of a critical hit, against the target's Critical Resist |
| Critical Resist | rating | lowers the attacker's critical chance |
| Block | rating | chance to block: a blocked hit adds to the reduction bucket |
| Penetration | rating | ignores a share of the target's Defence |
| Elemental Attack | points | a second hit of the Voidkin's element, past Defence |
| Elemental Resist | rating | lowers elemental damage taken |
| Critical Damage | percent | the extra a critical adds, from a base of +50%, every source adding to it. No ceiling: over the updates it can reach 20,000% [D, 2026-11-15, night] |
| Critical Immunity | percent | taken off an attacker's Critical Damage |
| Lifesteal | percent | heals for a share of damage dealt |
| Damage Bonus, Damage Reduction | percent | from signatures, passives and effects only, never from gear |

**Ratings** all convert the same way: `chance = ceiling x mine / (mine + theirs + K x G(level))`. A rating never reaches its ceiling, an opposing rating always pulls it down, and it needs more points at higher levels to hold the same chance. That shape is what keeps a stat from being solved.

**Combat Power** is one number shown to the player: a weighted sum of the stats, its weights fitted by the simulation so the higher number wins more often with no type edge. It's for reading, matchmaking and the Clash's rewards. It's never used to compute damage. How it's shown: `docs/design.md`, "Combat Power". Its weights (`tools/balance/seeds.json`, "combatPower"; refit on the attribute builds by `attributes.py`, report A8, with the sim's section 16 method) are what a point adds to winning, Attack's held at 4. A percent's weight is given at level 1 and multiplies by G at the Voidkin's level, since a percent multiplies points that grow with G. With them the higher number wins 97% of same-level duels with no type edge, and 99.7% where one side wins 10% faster (2026-11-16). Its limit is a sum's: it can't see that spreading points beats stacking them, so of one budget spent two ways it picks the better about half the time (`docs/polish-later.md`).

**Basic Attributes** [D, 2026-11-19, 03:10: five, Strength, Agility, Intelligence, Endurance and Spirit, one per class's Main; research's refit replaces the two-attribute rows below, which stand until it lands] feed the Battle Attributes and no fight reads them itself (`docs/design.md`, "Voidkin"). Each attribute converts by one row, every class alike, and the class's Main once more by its own. A class's points at level 1 are its shape, fitted so the class stands against every class and spec as it did before. The rows and the shapes: `src/shared/Config/Stats.luau`, "Attributes", once Faber lands TR36. The model reads them there: `py tools/balance/attributes.py`, or a proposed copy through `ATTR_STATS`.

| Attribute | Its job | It feeds, every class | As a Main, on top |
|---|---|---|---|
| Strength | power | Attack 1, Health 3, Hit 0.4, Penetration 0.4 | Warrior: Attack 1. Assassin: Attack 0.6, Critical 1.6, Dodge 0.6. Mage: Attack 0.6, Elemental Attack 0.25, Penetration 1.5 |
| Endurance | toughness | Health 5, Defence 1, Block 0.3, Regen 0.02, Critical Resist 1.5, Elemental Resist 1 | Tank: Attack 0.5, Health 3, Block 0.3. Healer: Attack 0.7, Regen 0.06, Critical Resist 2 |

- **The shapes, fitted** (level 1, Common, no stars; Strength, Endurance): Warrior 67, 48; Tank 40, 77; Assassin 67, 41; Mage 67, 45; Healer 38, 68.
- **SIMULATED** (`attributes.py` on the rows above, 2026-11-17, research's seeds, UNVERIFIED in play):
  - Class-against-class edges stay within 0.03 of the old ones at levels 10 and 40.
  - Each Main is its class's best attribute. The other is worth 67% to 74% of it at levels 5 to 60, so neither is dead.
  - All in the Main beats spreading evenly, which beats all in the other. Gear reads "my Main first".
- **Health** runs 29% to 45% lower at level 1 than before the attributes (the Warrior lowest, since its Main gives Attack). Its ratings and Attack make up the value.
- **Against the game,** an ordinary Shade dies in 4.1 to 5.7 s across the six grounds, against 4.5 to 5.7 before. Each kill costs one or two points more health. The Warrior gains most, about 0.8 s.
- **Combat Power,** its weights refit on these builds, picks the winner of 96.3% of same-level duels with no type edge, and 99.7% where one side wins 10% faster. The refit weights: Health 0.67, Attack 4, Defence 2.9, Regen 3.2, Hit 0.57, Dodge 1.7, Critical 0.65, Critical Resist 0.11, Block 0.96, Penetration 0.59, Elemental Attack 4.0, Elemental Resist 0.21, Critical Damage 110, Critical Immunity 110, Lifesteal 650, for `Config.Stats.Power.Weights` (TR36).
- **A gear line's price** is its Combat Power at the generic row: a point of either is worth about 6 to 7, and about 10 as the class's Main.

## One hit

Done by the server, once per attack, by one function (`docs/engineering-plan.md`, "The resolver").

1. **Hit or dodged.**
2. **Physical:** `Attack x the move's coefficient x (1 - mitigation)`. Mitigation comes from Defence, after Penetration, with a ceiling.
3. **The attacker's bonus bucket,** a sum: Damage Bonus from effects and the type advantage. One ceiling.
   - **A critical** multiplies on its own, outside the bucket: `x (1 + Critical Damage - the target's Critical Immunity)`, never under x1, with no ceiling [D, 2026-11-15, night]. Each update that raises Critical Damage raises the foes' health and Critical Immunity on the same curve ("The one rule").
4. **The defender's reduction bucket,** a sum: Damage Reduction from effects, the type disadvantage, and on a block, the block's share. One ceiling.
5. `final = physical x (1 + bonus) x critical x (1 - reduction)`, the critical x1 on a hit that isn't one.
6. **Elemental,** if the attacker has it: `Elemental Attack x coefficient x (1 - resist)`, through the same two buckets but never critical. Shown as the second, coloured number.
7. **Lifesteal** heals from the health actually removed, with a ceiling per second.
8. **The level gap** [D, 2026-11-19, 03:10]: when the attacker's level is below the defender's by more than 2, the hit (physical and elemental) is multiplied by `max(0.05, 0.85 ^ (gap - 2))`: 61% at 5 levels, 27% at 10, 10% at 16. A higher attacker gets nothing. Seeds, through the simulation before the build; Hard's recommended power is refit with it.

## Type

The edge is added, once: +25% in the attacker's bonus bucket with the advantage, +15% in the defender's reduction bucket against it. So about x1.25 and x0.85 [the package's candidate; the old 2x and 0.5x are retired]. Neutral pairs get nothing.

## Catch-up

A lead more than a few levels under the account's highest Voidkin earns experience faster, a fixed bonus in the experience bucket. Raising a second lead for a type counter costs hours, not weeks.

## Earning

| Rate | Its bucket holds | Ceiling |
|---|---|---|
| Credits | research, an event, a pass if one is ever sold, the daily track | x2.5 |
| Experience | catch-up, an event, research | x2.5 |
| Electricity | research, an event | x2 |
| Luck | Breaker tuning from research | +0.40 lift on a shard's top two tiers |

Upgrades to the base and its machines are the largest Credit sink (`docs/design.md`, "The base"). Their costs follow G, so a level costs about the same share of a ground's earnings wherever it's bought; the seeds set them before phase 3. **The base's level** [D, 2026-11-15, night: max 20 for now, "hundreds of hours of farm"; then launch's cap at 3, with items past it]: at launch, levels 2 and 3 cost Credits, priced so level 2 lands in the first session and 3 at about 5 hours (seeds, set with the sim). The sim's section 15 prices each level on the Credits earned since the one before. Level 2 takes half of the first 20 minutes' Credits, and level 3 a quarter of what's earned from there to 5 hours. **A machine's level** has a ceiling set by the base's level: 2, 6 and 30 at launch. That keeps the machines the sink through the whole launch, while the base's own levels are its gates. Each machine level costs the machines' 30% of the income over that level's slice of time, shared among the machines standing then. Up to 5 hours, the forge's 45%, the machines' 30% and the base's 25% use all of the income. After that, a quarter is left for the shop and the rest. What a level gives, and the battery's cap at each of the base's levels, are research's seeds (`tools/balance/seeds.json`, "baseLevels"): a bay +4% output a level; the Breaker +2% speed a level, its third chamber at level 8 and its fourth at 20; the battery's cap holds the dearest shard's full break in the grounds each base level spans. The ladder to 20 keeps a time target in the hundreds of hours, research's first reading 300, and is priced when its items are designed.

The Stone Condenser is how time away becomes strength (`docs/design.md`, "The base"). Its stones count inside forge ranks' share, not on top of it, and its tray's cap bounds how far a player who checks in often pulls ahead of one who doesn't. Its rate and cap are seeds, set by the simulation before phase 3.

The Void Rift is Breaker speed for a minute, on a schedule. Online all day it averages x1.63. It's the one large multiplier in the game, it's on a clock, and it touches time only.

## Pace

Seeds for how long each ground takes a player who keeps a 70% build ("on budget"): 1, 3, 6, 10, 15 and 22 hours, 57 in all. Everything else is derived from that table: kills per level, what a forge rank costs, when a player meets each shard. One table to turn if the game is too long or too short.

## The Tower

[D, 2026-11-16: the package's point 4.] One Voidkin climbs, its health carried from floor to floor (`docs/design.md`, "The Tower"). The numbers: `src/shared/Config/Tower.luau` (TR29). The foe's build share stays in `tools/balance/seeds.json`, "tower". The model: `py tools/balance/tower.py`.

**SIMULATED** (median of 60 runs, 2026-11-16, fast floors in): floors won by one run, a Warrior. The five classes end within 2 floors of each other.

| Level | A weak build (0.4) | On budget (0.7) | A full build (1.0) | Minutes on budget | Fast floors |
|---|---|---|---|---|---|
| 5 | 3 | 5 | 7 | 0.3 | 0 |
| 10 | 12 | 17 | 20 | 0.9 | 0 |
| 15 | 18 | 21 | 24 | 0.9 | 9 |
| 30 | 45 | 53 | 59 | 1.7 | 39 |
| 45 | 73 | 78 | 82 | 2.0 | 69 |
| 60 | 101 | 104 | 109 | 2.5 | 99 |

- **Restated for launch** (research, 2026-11-19, 20:55; MODEL, `build/scratch/quaestor/loot/`, under the combat review's patch and TR48's Lift): the table above is TR29's, before the refit. With the Lift's excess scaled by 0.3, an expected lead climbs 10 floors at level 10, 23 at 16 and 31 at 20, and the health it carries caps it at about 10 to 12 hard floors. The 17 at level 10 no longer holds.
- **Power shows as floors:** at level 30 a full build climbs 14 floors past a weak one.
- **A run at launch** (levels 10 to 15) lasts about a minute, nearly all of it hard floors. Whether that length feels good is judged in play.
- **Fast floors** take 12 s at level 15. Past level 25 the stretch passes 30 s (51 s at 30, 129 s at 60), against the design's "takes seconds", and at 60 only 5 hard floors follow it. It isn't a launch problem; it's refit when the grounds above Lantern Row open.
- **The heal cap** changes nothing today (the floors are the same from 10% up). It's the guard for when Lifesteal is wired.
- **The pool:** a Rare foe (Lyric) in one floor of four moves a run by a floor at most.
- **The rewards** (research's fit, TR29), with only hard floors paying, but for floor 5's chest, sure on the account's first win of it (a7cbd28, 2026-11-18):
  - **Credits:** half Lantern Row's an hour at levels 10 to 15, and a third at level 5. The Tower pays the gear; the grounds pay the Credits and experience, so neither is the only place worth playing.
  - **Chests:** about 15 an hour of runs at level 10 and 18 at 15. The chest has its own rarity row (`Config.Chests`), since Lantern Row's foes would read only row 2.
  - **The windows at launch,** if the Tower takes half of play after the first hour (a guess): Rare 3.5 h, Epic 12.5 h, Legendary 39.9 h. A quarter gives 6.0, 24.1 and 78.8 h; all of play in the Tower gives 2.3, 6.8 and 20.5 h.
  - **Past launch,** the Tower's Credits fall to 7% to 26% of a ground's at the lead's level, and its chests stay at 20 to 40 an hour. Its rewards are refit when Drum Court opens.

## Chests

[D, 2026-11-16: the package's point 9.] The targets, the first of each rarity at its hour: `docs/design.md`, "Chests". The numbers: `src/shared/Config/Chests.luau`. The model: `py tools/balance/chests.py`, whose `--fit` solves the ladder; research's fit is in `docs/test-requests.md`, TR27.

- **The shape** (research's): each rarity starts on the ladder where its grounds read it and roughly doubles a row, so a ground's packs never give its next rarity before its elites do, and Legendaries come from elites and keepers only.
- **SIMULATED** on the fit, a player alone on budget (the median first; 10% to 90% of players): Uncommon 0.3 h; Rare 3.5 h (1.5 to 6.2); Epic 12.5 h (10.3 to 16.4); Legendary 39.8 h (35.7 to 47.4). Eight players on a server are slower by up to 1.3 h, since they share the elite.
- **About 43 chests an hour,** 18 of them from elites, about 2,450 over the climb to level 60: bulk opening and auto-salvage are what make that many pleasant.
- **Salvage** pays at most 10% of a kill's Credits on Lantern Row and 16% on Mirror Pavilion, so fighting stays the income and the base's prices hold.
- **At launch,** with Lantern Row alone, Hard's chests read Drum Court's rows (TR48), and its elites and keepers carry their own Epic and Legendary weights (TR48, part 2). MODEL: Rare about 2 h, Epic about 4.3 h, Legendary about 18 h. The Tower's row is TR48's.

## What the simulation showed (2026-11-11)

Run it with `py tools/balance/sim.py`. It reads the seeds and `docs/roster.md`.

**Nothing compounds.**
- A full build against a bare Voidkin of the same level: x2.86 in each stat. The same sources multiplied together would give x4.62.
- Damage a second, bare Common as 1: on budget x2.6, full and balanced x3.4, full and built for damage x5.6, a Mythical Assassin built for damage x6.9. With the type advantage and the largest effect bonus on top: x11.9, rerun on 2026-11-15, night, with the critical outside the bucket (x10.5 before). That's the ceiling of the whole game at one level.
- One hit can't exceed x3 of its plain value before a critical, which has no ceiling, or fall under x0.30, by the buckets' ceilings.

**Builds matter more than rarity.**
- A Common at a full build beats a Mythical at half a build (16 s against 28 s in the arena).
- At equal builds the Mythical wins clearly (18 s against 28 s).
- The type advantage alone, equal builds: 18 s against 28 s. Decisive, not automatic.

**No build wins everything.** Legendary Warriors at full builds, arena health x3:

| Row against column | balanced | damage | defence | elemental |
|---|---|---|---|---|
| balanced | even | wins | wins narrowly | even |
| damage | loses | even | loses | even |
| defence | loses narrowly | wins | even, and long (47 s) | loses |
| elemental | even | even | wins | even |

Balanced is the safe build and the others are matchup builds. Two defence builds make the longest fight, as the director expects.

**Fights against the game.** Enemy health and attack are derived so an on-budget Common Warrior meets the targets: an ordinary Shade in 5 s, an elite in 18 s, a keeper in 45 to 75 s by ground, ending with about 30% health when a typical 2% of lifesteal is counted. Without any lifesteal the same Warrior ends near 10% at ground 1 and falls just short at ground 6.
- A bare Voidkin takes 9 to 14 s on an ordinary Shade and can't beat a keeper.
- Half a build loses to the keeper, narrowly at ground 1 and clearly at ground 6.
- On budget with the type advantage: wins with about 60% left. Against the type: loses. Bringing the right lead is worth as much as a third of a build.
- Walking into a new ground in the last ground's build: 6 to 7 s a kill and about a quarter of health lost each. Harder until the new gear comes, never a wall.

**The Breaker and electricity.**
- Bays cover what the Breaker asks x1.5 to x1.7 for a player on half an hour a day, x1.35 to x1.45 on an hour and a half, and x0.85 to x0.98 on four hours. The heaviest players are the ones who feel electricity, and research and better workers are their answer.
- Chambers are never the limit (under 12% busy). Break time is anticipation, electricity is the cost.
- Infusion is voltage since 2026-11-15 and buys time, not luck (sim.py, section 14). On ground 1, a Prismatic's High voltage costs 60 kWh, a full battery, to save 3 hours; an Enriched's costs 5. A Prismatic of the last ground would cost 420, so the battery's cap must grow with the base before then.

**What players own** (1,500 simulated players each, every shard broken):

| Hours a day | Day 7 | Day 30 | Day 90 |
|---|---|---|---|
| 0.5 | ground 2, 12 Voidkin | ground 4, 23 Voidkin, 81% have a Legendary | ground 6, 28 Voidkin, 33% have a Mythical |
| 1.5 | ground 3, 19 Voidkin | ground 6, 28 Voidkin, 24% have a Mythical | 30 Voidkin, 92% have a Mythical |
| 4 | ground 5, 26 Voidkin, 99% have a Legendary | 29 Voidkin, 82% have a Mythical | 31 Voidkin, all have a Mythical |

Every player has all five types and all five classes within the first week: no counter and no role waits on luck.

## What the simulation doesn't know

- **Kits.** Signatures, passives, taunts, heals for allies and range aren't modelled. Class against class is only as good as the kits make it.
- **Play.** Dodging by walking, picking fights, quitting. The pace table is a guess until someone plays.
- **Lifesteal** is strong against bosses and weak against players, by its nature. Its per-second ceiling is the guard, and it's the first stat to watch in play.
- **The heaviest players** finish the six grounds in about two weeks at these seeds. What holds them after is the Tower, the Clash, stars and the Mythical hunt, then updates.
- **The store.** Nothing sold is modelled, because nothing is designed to be sold yet.

## Tuning

- A number changes in its seed, never in a formula. The run is repeated and the tables above are replaced.
- Numbers are exposed at runtime in the dev build, so they're tuned by playing.
- A change to a rule on this page is a balance change of tier 2 at least (`AGENTS.md`, "Design changes"). A new multiplier anywhere is tier 3.
