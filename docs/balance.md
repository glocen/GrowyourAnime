# Balance

How every number in the game is put together, so that nothing compounds. The rules here are the design. The numbers are seeds in `tools/balance/seeds.json` (until the game's own Definitions hold them) and are tuned by play.

The director, 2026-11-11: "avoid compounding (which was an issue i noticed on next button simulator all the multipliers led to me in 1 session having over 2296x in clicker which was not what i intented ... i was thinking of a x + x + x)".

**Status:** the structure is designed and tested by simulation (`py tools/balance/sim.py`, run of 2026-11-11, below). Nothing is played. A simulation checks the numbers against each other; it doesn't know what players will do.

## The one rule

**Things add. Almost nothing multiplies.**

1. Every source of power (level, gear, forge, emblems, jewels, research, stars) gives **flat points** to a stat. None gives "a percent of your attack".
2. Two exceptions, both a percent of the thing's **own base** and both linear: a slot's forge rank on the item in that slot, and a Voidkin's stars on its own base stats. Neither touches the total.
3. Growth comes from **authored tables**: a level's row, an item tier's row. Getting stronger means a better row, not another multiplier.
4. A hit multiplies in **three places only,** each with a ceiling: the defender's mitigation, the attacker's bonus bucket, the defender's reduction bucket. Everything that would be "a damage boost" is a number added into one of the two buckets.
5. Every earning rate (Credits, experience, electricity, luck) has **one bucket** of bonuses that add, and a ceiling.

A new system joins by adding points to a stat or a number to a bucket. If it can't be written that way, it's a core change and goes to the director.

## Growth

One curve, `G(level)`, gives the size of everything at a level: a Voidkin's base stats, an item tier's stats, an enemy's health, a reward. Launch levels are 1 to 60, and G runs from 1 to 22. Because rewards, costs and enemies follow the same curve, a higher level changes what a player fights, not how fast the numbers run.

## Where power comes from

Shares of a full launch build's stat points, at level 60:

| Source | Share | How it's earned |
|---|---|---|
| The Voidkin's own base (level and rarity) | 35 | fighting |
| Its stars | 3.5 | duplicates |
| Gear | 27 | drops, the shop |
| Forge ranks | 13.5 | stones and Credits |
| War Emblems | 11 | drops, the shop |
| Jewels | 7 | elites, keepers, the Tower |
| Research | 3 | Research Points |

- **Rarity** multiplies a Voidkin's own base only, from 1.00 for a Common to 1.50 for a Mythical. Since the base is about a third of a build, a Mythical at a full build has about 19% more of each stat than a Common at a full build.
- **Class** shifts a Voidkin's own base between health, attack and defence. It doesn't touch gear.
- **Gear is the account's,** so most of a build carries over to whichever Voidkin leads.

## The stats

| Stat | Kind | What it does |
|---|---|---|
| Health, Attack, Defence | points | the three every source adds to |
| Hit | rating | against the target's Dodge and Block |
| Dodge | rating | chance to avoid a hit entirely |
| Critical | rating | chance of a critical hit, against the target's Critical Resist |
| Critical Resist | rating | lowers the attacker's critical chance |
| Block | rating | chance to block: a blocked hit adds to the reduction bucket |
| Penetration | rating | ignores a share of the target's Defence |
| Elemental Attack | points | a second hit of the Voidkin's element, past Defence |
| Elemental Resist | rating | lowers elemental damage taken |
| Critical Damage | percent | the extra a critical adds, from a base of +50% |
| Critical Guard | percent | taken off an attacker's Critical Damage |
| Lifesteal | percent | heals for a share of damage dealt |
| Damage Bonus, Damage Reduction | percent | from signatures, passives and effects only, never from gear |

**Ratings** all convert the same way: `chance = ceiling x mine / (mine + theirs + K x G(level))`. A rating never reaches its ceiling, an opposing rating always pulls it down, and it needs more points at higher levels to hold the same chance. That shape is what keeps a stat from being solved.

**Power** is one number shown to the player: a weighted sum of the stats. It's for reading, matchmaking and the Clash's rewards. It's never used to compute damage.

## One hit

Done by the server, once per attack, by one function (`docs/engineering-plan.md`, "The resolver").

1. **Hit or dodged.**
2. **Physical:** `Attack x the move's coefficient x (1 - mitigation)`. Mitigation comes from Defence, after Penetration, with a ceiling.
3. **The attacker's bonus bucket,** a sum: Damage Bonus from effects, the type advantage, and on a critical, Critical Damage less the target's Critical Guard. One ceiling.
4. **The defender's reduction bucket,** a sum: Damage Reduction from effects, the type disadvantage, and on a block, the block's share. One ceiling.
5. `final = physical x (1 + bonus) x (1 - reduction)`.
6. **Elemental,** if the attacker has it: `Elemental Attack x coefficient x (1 - resist)`, through the same two buckets but never critical. Shown as the second, coloured number.
7. **Lifesteal** heals from the health actually removed, with a ceiling per second.

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
| Luck | Breaker tuning from research, infusion | +0.40 lift on a shard's top two tiers |

The Void Rift is Breaker speed for a minute, on a schedule. Online all day it averages x1.63. It's the one large multiplier in the game, it's on a clock, and it touches time only.

## Pace

Seeds for how long each ground takes a player who keeps a 70% build ("on budget"): 1, 3, 6, 10, 15 and 22 hours, 57 in all. Everything else is derived from that table: kills per level, what a forge rank costs, when a player meets each shard. One table to turn if the game is too long or too short.

## What the simulation showed (2026-11-11)

Run it with `py tools/balance/sim.py`. It reads the seeds and `docs/roster.md`.

**Nothing compounds.**
- A full build against a bare Voidkin of the same level: x2.86 in each stat. The same sources multiplied together would give x4.62.
- Damage a second, bare Common as 1: on budget x2.6, full and balanced x3.4, full and built for damage x5.6, a Mythical Assassin built for damage x6.9. With the type advantage and the largest effect bonus on top: x10.5. That's the ceiling of the whole game at one level.
- One hit can't exceed x3 of its plain value or fall under x0.30, by the buckets' ceilings.

**Builds matter more than rarity.**
- A Common at a full build beats a Mythical at half a build (16 s against 28 s in the arena).
- At equal builds the Mythical wins clearly (18 s against 28 s).
- The type advantage alone, equal builds: 19 s against 28 s. Decisive, not automatic.

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
- Infusion on a Standard shard costs fifteen times the shard for almost nothing. On a Prismatic of the last ground it takes the Mythical chance from 4.0% to at most 5.1%. A nudge, where it's meant to be.

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
