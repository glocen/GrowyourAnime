# The design

How the game works, system by system: the current design only. The vision is `docs/north-star.md`. The register of who decided what, and what's challenged: `docs/decisions.md`.

Every line carries its status:

- **[D]** the director's: the directive (`docs/directive.md`, by section), the sketch or their words of 2026-11-09.
- **[P]** research's proposal. Trying it in a blockout is tier 1. It becomes the design by the tier its size calls for.
- **[O]** open: no recommendation yet, or one that waits on a look or a measure.

Numbers here are targets to tune by playing. Once a system is built, its numbers live in `src/shared/Config/` and leave this file.

## The spine

**[P] Power is the money.** One sentence holds the game together:

> Fighters make the power that grows the next fighters, and the power you don't use sells itself.

1. **Grow.** A Void Shard goes into a Void Breaker. Power breaks it, and a fighter grows inside, in view.
2. **Power.** The fighter goes to work on a station. Its training makes power, and it grows stronger as it trains.
3. **Clash.** The team goes out to fight. Fights pay what power can't: rare shards, void essence, rank, and the right to buy and build more.

Power runs the machines. Spare power turns into credits every second. Credits buy shards and machines. More fighters, more power.

Why this spine: it gives the game's own answer to what "grow" means, it makes electricity the thing every upgrade feeds, and it turns each new fighter into something you see working at once.

## Words

| Word | What it is | Status |
|---|---|---|
| Void Shard | what a fighter grows from. Never planted, never a seed (the directive, section 3) | [D] |
| Void Breaker | the machine that breaks a shard and grows its fighter. Players see "Breaker" until the director rules on the full name (`docs/ip-list.md`) | [D] the sketch |
| Void Clash | the fight. Every fight in the game is a Void Clash, wherever it happens. Never "Void Pit" (section 3) | [D] the name; [P] that it names every fight |
| the Grid | a base's power: what it makes, uses and stores | [P] |
| credits | the spending money | [D] the sketch |
| void essence | what improves a fighter you own | [D] the sketch; [P] its use |
| research data | what buys permanent upgrades for the base | [D] the sketch; [P] its use |
| the Tower | each base's own climb, at its back | [D] their words |
| Calamity | a boss the whole server fights | [D] the sketch |
| the Index | the permanent record of every fighter found (section 3) | [D] |
| the fighter's own word | "anime fighter" needs a name of its own (the director). Research's pick is **Voidkin**: it belongs with Void Shard and Void Clash, it's the same word for one or many, and a first screen found no owner. Also clear: Nova, Awakened. Out: three candidates another game owns (`docs/ip-list.md`) | [O] the director's pick |

## The map

The director's sketch, with research's additions marked.

```
  T     T     T     T          T: each base's Tower, at its back
[ B1 ][ B2 ][ B3 ][ B4 ]       fronts open onto the Strip
  Void Shop   VOID CLASH   Calamity          the Strip
[ B8 ][ B7 ][ B6 ][ B5 ]
  T     T     T     T
```

- [D] Eight bases, two rows of four, with the Void Shop, the Void Clash arena and the Calamity ground between them. Servers of eight.
- [D] Bases can be visited.
- [P] Every base's front is open to the Strip, and its Breakers face it, so a reveal happens in everyone's view.
- [P] The eight Towers stand behind the bases and light floor by floor. The skyline is the server's ranking, readable from anywhere.
- [P] From any base's front to the shop: eight seconds at most on foot. Timed at the blockout.
- [O] What a visitor can do in a base. Research's start: look (the showcase, the Index wall) and challenge the owner's team. Never take anything.

**A base, front to back** [P]: the gate and a showcase of three fighters; the Breakers; the stations; the Board, where cables meet; the fusion and research machines; the Tower. Machines stand on slots, and a base grows by opening slots.

## The Grid

The director, 2026-11-09: "the electricity thing features need to be amazing and almost factory simulation like". The directive, section 6: no complicated electrical simulator unless it demonstrably improves the game; "understandable choices and satisfying progression, not excessive management". Both hold in this design: **the depth is in what you build and where your power goes, never in electrical rules.**

**The rules** [P]:

1. **Three numbers, no more:** MAKE (kW), USE (kW), STORED (kWh). They are the only electricity the screen shows.
2. **Spare power sells itself.** MAKE minus USE becomes credits every second. Nothing is wasted, so every upgrade to the Grid pays.
3. **Everything else is seen in the world.** Cables pulse with what flows through them and thicken under load. A machine that's short dims and slows. A full battery glows.
4. **Short power never destroys anything.** Machines slow in proportion, in the order the Board sets.
5. **The choice is where the power goes:** into Breakers (more fighters), into training (stronger ones), into research (permanent upgrades), or out as credits.

**Where power comes from** [P]. Each source has its own rhythm:

| Source | Rhythm | Arrives |
|---|---|---|
| The player's own hand: hold the Breaker's handle | a burst, only while held | second 0 |
| A fighter on a dynamo station | steady, and it grows with the fighter | the first fighter |
| Batteries | stored spare, spent on a boost or while away | early |
| Void weather collectors | a surge during a weather | later |
| A reactor that burns void essence | steady and costly | later |
| A Calamity's core, as a trophy | a small permanent source | later |

**By hand first** (the director: "it could start by players manually producing electricity (maybe it an bad idea)"). [P] It's a good idea in one place and a bad one everywhere else. Good: the first shard is grown by the player's own held input, the game's first verb. Then the first fighter steps onto the dynamo, the cables light without the player, and the handle is never needed again: the first automation, inside the first 15 seconds. Kept after that only as a short bonus burst the player may choose. Bad: as the routine way to make power. The directive, section 6, rules out "constant tedious manual interaction".

**Automation comes in steps** [P], each one a thing the player did by hand until then: growing by hand, then fighter-powered; loading each shard, then a queue that feeds the Breakers; placing each new fighter, then fighters that walk to the best free station; and so on up. Each step is an unlock the player feels.

**Depth for later, each layer only if its blockout earns it** [P]:

- **Modules:** a machine has two or three slots, and what's fitted shows on it (a coil, a cooler, a capacitor).
- **Overclock:** run a machine past its rating, faster and at a steeply higher draw.
- **Neighbours on the floor:** some machines lift the ones beside them, so where a machine stands matters. This is the cheapest true factory depth, and it needs no wiring.
- **Priorities on the Board:** which machines keep full power when the Grid is short.

**Away from the game.** [D] The director, 2026-11-09: the game "need to play even when the players left". [P] The base is a factory that runs itself, so it runs as usual while its owner is away: Breakers finish, fighters train, spare power sells. The batteries set how many hours of that are banked for the return. One rule covers every machine, bigger batteries mean a longer night's work, and nothing is ever lost by being away.

**What the Grid never has:** voltage, phases, wiring puzzles, anything that breaks, or a number a ten-year-old can't read off the screen.

## Shards and Breakers

[D] The director, 2026-11-09: "the game just like grow an garden need different type of void shard (like plants)".

- [P] **A shard's type names its fighter, as a seed names its plant.** Each type has its own look, rarity, price, break time and power draw. What the player buys is known. What stays a surprise: which shards the shop holds, who is inside a type the first time it's grown, and the mutation and trait each break rolls.
- [P] **Bought shards are certain, earned shards are mystery.** A second kind of shard, never sold, comes from the Tower, Calamities and Index milestones, and grows one fighter from a pool, with its odds shown. So the roll on who you get exists, and money never touches it (`docs/roblox-rules.md`, "Paid random items").
- [P] A shard's rarity sets how long it takes to break and how much power it draws: seconds for the first, minutes in the middle, hours at the top. Luck finds a top shard, and the Grid earns it: on a weak Grid it still breaks, slowly. The fighter grows in view the whole time.
- [P] **Overcharge:** spend stored energy on a break to finish it faster. Whether it may also lift a break's odds is [O]: it would be a luck item, and the rule on those is in "Luck".
- [O] Prices, how many types at launch (one per fighter), how many Breakers a base starts with (the blockout tries two).

## The Void Shop

[D] The director, 2026-11-09: "need a Sync between all server 5 minutes shops that is as exciting if not more with the limits". The sketch: "Every 5 minutes Synch with all server".

- [D] One stock for the whole game, new every five minutes, the same on every server, with a limit on what each player may buy.
- [P] The stock is worked out from the clock, so every server shows the same shelf with no messages between them, and players anywhere can tell each other what's in.
- [P] The first shards are always on the shelf. Each higher one has its own chance to appear and its own small quantity. A player's limit is that quantity, theirs alone: nobody races a neighbour for the last one.

**What makes it ours** [P]:

1. **The stock stands in the world.** The shards are on the shelves, lit in their rarity's colour, and when a high one is in, a beam of that colour rises over the shop. It's seen from every base and every Tower, and everyone runs.
2. **The next shelf is hinted.** In the last minute before the change, the best shard of the next stock shows as a shape and a colour. There's always a reason to stay for one more.
3. **A charged shelf.** Now and then one shelf comes charged by the Void weather, and what those shards grow is sure to carry its mutation. It's the same on every server, so it's the moment players tell each other about.
4. **Luck finds it, the Grid earns it.** A top shard is only as good as the base that breaks it.

- [P] No paid restock at launch. A paid reroll of a random shelf is a question Roblox hasn't answered (`docs/roblox-rules.md`).
- [O] Each shard's chance, quantity and price. A balance run first, then live numbers.
- [O] Whether the Void weather and Calamities run from the same clock, so every server lives the same moment. Research's start: yes.

## Fighters

- [D] Original, on Roblox's R6 body, each with its own silhouette, outfit, hair, weapon, animations, effects, name and abilities (sections 3 and 11). The line they stay inside: `docs/decisions.md`, "Fighters".
- [D] Rarities, in order, spelled exactly: Common, Uncommon, Rare, Epic, Legendary, Mythical, Radiant, Secret, Divine, Transcendant, NEXT (section 4). NEXT is kept for officially licensed characters. No original fighter is born into it, evolves into it or fuses into it.
- [D] Rarity sets a fighter's base and potential. It never guarantees a win: a well-built Legendary can beat a plain Mythical (section 5).
- [P] The targets to test in a balance run before any formula is built: one rarity step is worth about a third more strength; a full build (level, stars, a fitting trait) is worth about 60 percent, bounded. Neither is a measurement.
- [P] Three types to start: close, blade, ranged. One basic attack and one signature skill each.
- [P] A fighter grows in view: in the Breaker, then in stages as it levels, shown by size, aura and gear that every fighter shares, so no fighter needs extra art per stage.
- [O] How many fighters at launch. Research's range is 12 to 16, with at least one in every rarity below NEXT. Decided once the first fighter's cost is timed (`docs/production-plan.md`, step 3).

**Mutations and traits** (section 7: few, distinctive, each one changes how a fight or a base plays):

- [P] About twelve traits, rolled when a fighter is grown. Some are for fights, some for the Grid.
- [P] Five or six mutations. Each is a look and one effect, and each comes from the Void weather at the moment of the break.
- [P] The Index records each fighter in each mutation, which is the long collection.

**Fusion** (section 7):

- [P] Copies of one fighter fuse into stars, five at most. The result is fixed and shown before the player agrees. The fighter with the most progress is the one kept. One server operation, safe to repeat and to interrupt (`docs/engineering-plan.md`, "Transactions").
- [P] A spare fighter can be released for void essence.
- [D] Nothing fuses into NEXT, refused in the server's rules.

## Training

- [D] Readable, satisfying, relevant to fights, and never a chore (section 6).
- [P] Training is work on a station, and it never needs the player's hand:
  - a **dynamo** station makes power and gives a little experience;
  - a **dojo** station uses power and gives a lot.
- [P] The choice is which fighters power the base and which are pushed ahead.
- [O] Whether a fighter away at a fight leaves its station dark for that time. Research's start: yes, for the seconds the fight lasts, because it keeps the world honest and costs little.

## Void Clash: the fight

- [D] Automatic, and it must show who fights, what they do, the damage, why it was won or lost, and what was earned. Correct and dull fails (section 6).
- [P] The server settles the whole fight at once, from the two teams and a seed, into a list of events. The client plays that list back as the show. Rules are pure Luau, tested without Studio (`docs/engineering-plan.md`).
- [P] A team is up to three. The slice fights one against one. The rules take any number from the start.
- [P] A fight plays for 15 to 25 seconds and ends on one card: who won it, and the moment that decided it.
- [O] Whether the three types beat each other in a circle. It would give team-building a reason with one small rule. A balance run first.

## Where fights happen

Three places, three kinds of play. Only the first is in the slice.

**The Tower** (the director: a tower on each base, as in the chicken game, where your fighters meet the fighters of "players ... whom played the game"):

The reference was read on 2026-11-09 (`docs/research/tower.md`, SOURCED). Its tower is a solo climb against the game's own opponents, with health that carries between floors, a record, a lift to floors already reached, and no tickets. Nothing found puts another player's team on a floor, and no mode called "rush" was found. So floors held by other players' fighters is the director's own idea, and the part that makes this Tower ours.

- [P] **A run is a climb.** The team goes up floor by floor, and each floor is one Void Clash. Health carries from one floor to the next. A run ends when the team falls, and nothing is lost by falling: every floor cleared has already paid, and the best floor is the record.
- [P] **Each floor shows who holds it** before the fight. The first floors hold teams we wrote. Above them, each floor holds the saved team of a real player of about that strength, with their name over it. Every tenth floor is a Void boss of ours.
- [P] **Your team holds floors too,** on other players' Towers, while you're away. What it won comes back as a gift on your return. Nothing is ever taken from a loser.
- [P] **The Tower runs on the Grid.** Between floors, stored energy can recharge the team. A lift, also on stored energy, starts a run from any floor already held. A stronger base climbs higher, and there are no tickets and no daily limit.
- [P] **What it pays:** credits and void essence on every floor, more with height, so playing pays more than waiting. A first clear pays what opens the game: new shard types on the shop's shelf, machines, slots, and a line in ascension's lists.
- [P] **The skyline:** a Tower is lit up to its best floor, with the number on top.
- [O] The player's hand during a fight. The reference lets the player cheer and retreat. Ours settles each fight at once, so the choices come between floors. Whether one input during a fight earns its place (a surge from the batteries) is for a blockout after the slice.

**The Void Clash arena,** on the Strip:

- [P] Live, in front of everyone: a neighbour's team against yours, or a round that anyone present may enter. Later than launch.
- [O] Stakes, schedule, ranking.

**Calamity** (the sketch: a big boss spawns, players above a minimum share of the damage are rewarded, the top three most):

- [P] Everyone on the server sends a team at the same boss. Later than launch.
- [P] One change to the sketch's rule: the minimum is measured against a player's own strength, not against the server's total. On a server of eight with one very strong player, a share of the total shuts every newcomer out. The director's reference for long grinds uses a share of the boss's health, and its guides tell players to go to private servers (`docs/research/long-grind.md`, "Bosses"). The top three still get their bonus.
- [P] A beaten Calamity leaves its Void weather over the server for a few minutes, which is where mutations come from.

## Luck

The director: "we should add a lot of upgrade features and luck".

- [P] Luck lives in five places: what the shop's shelf holds, the mutation a break may add, the trait a fighter is born with, who comes out of a mystery shard, and one roll on the player (below).
- [P] **Luck is one number the player owns,** shown on screen. The Index, research, ascension and the Void weather feed it, and the odds a player sees move with it.
- [P] Every roll shows its odds. Every roll has a counter that guarantees the better result after a fixed number of tries, so bad luck is a goal with an end.
- [D] No roll, reroll or luck item is sold for Robux, or for anything Robux buys, until Roblox's rules for it are built in and the director has approved the design (sections 7 and 15; `docs/roblox-rules.md`).

## The long game

The director's reference for a grind that doesn't end was read on 2026-11-09 (`docs/research/long-grind.md`, SOURCED). Its structure is five things, and its warning is one: it peaked at 745,280 players and stands near 1,000, because the grind held only while an update landed every week.

**What we take** [P]:

1. **Tracks side by side.** Each is its own ladder with its own token, and each changes something the player sees. A cheaper one is always left to improve.
2. **Every action can drop a token:** a break, a fight, a Calamity. No minute is wasted.
3. **Counters** on every roll.
4. **Luck as one number** that every track feeds.
5. **Tracks open one at a time,** at spaced gates. The first hour shows three.

**Our tracks** [P]:

| Track | Its ladder | It changes |
|---|---|---|
| The Index | every fighter, then every fighter in every mutation | luck and credits per page; the Index wall in the base |
| A fighter | level by training, stars by copies, a trait by reroll | its strength, its power, its look by stage |
| The Grid | research, machine levels, modules | what the base makes, and how it looks and sounds |
| The Tower | floors without an end | what the shop and the machines open to; the skyline |
| The clan | one roll on the player | one bent for the whole base |
| Ascension | a checklist across the whole game, tier by tier | the base's power, credits and luck, and its look |

- [P] **Ascension is the sketch's "prestige", without a wipe.** Each tier is a list that sends the player through every part of the game (break this many, reach this floor, fill this page, make this much power). Fighters are valuables, so nothing the player owns is ever reset to climb.
- [P] Launch holds the Index, the fighter's level and stars, the Grid's first layers and the Tower. The others follow, one per update.
- [P] **The warning, built in:** content is rows, so a weekly update is a new shard, a new weather, a new floor set or a new Calamity, made without new code.

## The player

The sketch: "level, prestige, Clan rolling systems, traits, aura, race..".

- [P] A level, from everything the player does. It opens the tracks.
- [P] One roll on the player, not four: a clan, which gives the whole base one bent (a clan of the storm powers better, a clan of the blade fights better with blades). Rerolled with tokens that every action can drop.
- [P] Ascension, above.
- [P] An aura on the avatar, which shows the ascension tier and can't be bought.
- [O] Race and the player's own traits: two more rolls of the same kind as the clan. Research's start: not at launch, and only if the clan proves players want a second.

## What you own and spend

| Thing | Comes from | Goes to |
|---|---|---|
| Power | fighters on dynamos, and the sources above | machines; the spare becomes credits |
| Credits | spare power; first finds in the Index; first clears | shards, machines, slots |
| Void essence | fights; released fighters | stars, rerolling a trait, a reactor's fuel |
| Research data | the research machine, which runs on power; Calamities; Index milestones | permanent upgrades to the base |

- [P] The slice has power and credits only. Each of the other two arrives with the system that spends it.
- [P] The first time a fighter is found, the Index pays credits. So the very first reveal pays, nine seconds in.

## What's built when

`docs/production-plan.md`, "The slice", is the order. In short: the slice proves grow, power and one fight. Launch adds the Tower, the Index, stars and the Grid's first layers. The arena, Calamity and each deeper layer follow as updates, chosen by what was measured.
