# Decisions

The register: what's confirmed, what's proposed, what's open, what's set aside, and what research challenges. One line each, with its home. The design itself is in `docs/design.md`, where every line carries [D], [P] or [O]. A status changes here and there together, on the director's word or by the tier the change calls for (`AGENTS.md`, "Design changes").

## The director's words

Each covers exactly what it names.

| Date | The words | They cover |
|---|---|---|
| 2026-11-09 | the directive, word for word in `docs/directive.md` | what each section says. Its candidates stay candidates (sections 6, 7 and 21) |
| 2026-11-09 | "our next game named "Grow a Anime"" | the title, in their spelling |
| 2026-11-09 | "This is a inspiration of 2 games: Grow a Garden and grow a chicken fighter (dont even think about worrying of IP)" | taking those two games' genre and general mechanics as inspiration |
| 2026-11-09 | "(it is written custom audio but obv we can do it so exclude it we will take from roblox audio free library and in some case mix if needed)" | the directive's section 14: sounds come from Roblox's audio library, mixed where needed (`AGENTS.md`, rule 2) |
| 2026-11-09 | "the game 20 first seconds isn't a rule for every game just those type of games and ... this is something that ... "Grow a Anime" Need!" | the first 20 seconds as a need of this game and its kind, not a studio rule |
| 2026-11-09 | "make the usual terminal where i can type 1 to call everyone you included" | `tools/team-terminal.cmd` |
| 2026-11-09 | the sketch: eight bases in two rows; the Void Shop, Void Clash and Calamity between them; base visiting; the shop "Every 5 minutes Synch with all server"; Calamity: "Spawn x, big boss, players with minimum % of damages get rewards, top 3 players get the most"; a base holds "Void breakers, fusion, generators output, credits, void essence, training, research data"; players have "level, prestige, Clan rolling systems, traits, aura, race"; a fighter has "Mutation, traits, fusion, level" | a sketch: "you can make your own it is not finished". Its names and layout are taken as the director's. Its lists are candidates |
| 2026-11-09 | "a tower system like grow a chicken fighter on each player base behind ... a player send his anime fighter (maybe need a new name cause duh) that fight players anime fighters whom played the game" | a Tower behind each base, fought against other players' fighters; and a new word for "anime fighter" |
| 2026-11-09 | "we should add a lot of upgrade features and luck ... take some inspiration from sailor piece ... their endless grinding is incredible" | the aim of a long grind with many upgrades and luck; that game as a reference for its structure |
| 2026-11-09 | "the electricity thing features need to be amazing and almost factory simulation like ... if we set on 1 design locked that is geniune with our game vision it could be extremely huge ... it could start by players manually producing electricity (maybe it an bad idea)" | the ambition for electricity, and one design to lock. The manual start is offered as an idea |
| 2026-11-09 | "let make sure we have a geniune bullet proof design foundation ... so that wednesday the team can work with a clear vision" | the foundation closes before Wednesday 2026-11-11, when the team starts |
| 2026-11-09 | "the game just like grow an garden need different type of void shard (like plants) / need to play even when the players left / need a Sync between all server 5 minutes shops that is as exciting if not more with the limits" | types of shard; the game runs while the player is away; the synced five-minute shop with limits |
| 2026-11-09 | "dont bother with what was said about project lynx framework ... we will use our brand new one" | the directive's text on LYNX (section 16; section 22, item G) gives way to the studio's own LYNX in `handbook/` |

## Confirmed

The director's, each in its home. They change only on the director's word.

- **The identity** (the directive, section 3): a compact base, electricity-powered machines, Void Shards, never seeds or planting; a small social neighbourhood; original fighters on R6; the fight is VOID CLASH, never "Void Pit"; a permanent Index; fusion, traits and mutations planned.
- **The rarities,** their order and spelling, and NEXT's rule (section 4).
- **Rarity isn't victory** (section 5).
- **Server authority, saved state and safe transactions** (sections 8 to 10): `docs/engineering-plan.md`.
- **No paid randomness** until its rules are built in and the design approved (sections 7 and 15): `docs/roblox-rules.md`.
- **A small excellent game first** (sections 1 and 17).
- **The map's shape, the synced five-minute shop with limits, types of shard, the Tower behind each base, Calamity, base visiting, the game running while away** (the sketch and words above): `docs/design.md`.
- **Sounds** from Roblox's audio library.
- **The first 20 seconds** as this game's need: `docs/north-star.md`.

## Fighters

The directive, section 3: fighters have original silhouettes, outfits, hair, weapons, animations, effects, names and abilities; a published character "must not be recreated through recognizable combinations of appearance, signature skills, and other protected expression. Renaming a recognizable character is not sufficient."

**The test,** asked of every design sheet before anything is built:

1. Would a fan name a published character at a glance, from the silhouette, the colours or the pose?
2. Does the design take more than one mark from any single character: a hair, an eye cover, an outfit, a weapon, a move, the sound of a name?

A yes to either changes the design, not the name. A fighter starts from a type the whole genre shares (the masked prodigy, the cursed swordsman, the brawler who never quits), and its silhouette, palette, move and name are ours.

The director's words in chat ask for more likeness than this. They're under "Challenged", item 1, and the folder follows the directive until the director answers.

## Proposed

Research's recommendations, 2026-11-09. Each names the simplest option that could work and what the choice costs. None is the design until it passes its tier. Trying one in a blockout is tier 1.

| # | The proposal (`docs/design.md`) | The simplest option | The trade-off | Settled by |
|---|---|---|---|---|
| 1 | **Power is the money:** fighters make power, spare power sells each second | fighters pay credits directly, and power is only a cap | one stream to balance and a payoff for every Grid upgrade, against one curve that everything hangs on | TR2's blockout; a balance run; the director's yes to lock it |
| 2 | **By hand first:** the player's held input grows the first fighter, who then takes over | the Breaker runs by itself from second 0 | a first verb the player performs and an automation they feel, against one more beat in the first seconds | TR2's timing |
| 3 | **A shard's type names its fighter; mystery shards are only earned** | shards as tiers with pools, like eggs | the shop works as in the director's reference and nothing sold is a loot box, against losing "who is it?" on a bought shard after the first time | the director |
| 4 | **The shop's own marks:** stock in the world with a beam, the next shelf hinted, a charged shelf | a list on a panel | more to build, for a shop seen from every base | step 4's blockout |
| 5 | **Away, the base runs as usual,** and batteries bank the hours | finish Breakers only | the full promise of the director's words, against an income to cap | a balance run |
| 6 | **A fight is a list of events** settled by the server and played back | live simulated combat | testable without Studio, replayable and cheat-proof, against less room for live surprises | the builder agrees (`docs/engineering-plan.md`) |
| 18 | **Every break rolls a mutation, and a finished Breaker waits for its owner** ("Shards and Breakers") | no roll; Breakers open by themselves | a roll on the basic action and every reveal watched, against one more tap and mutations' balance at launch | TR2 |
| 19 | **Fights pay essence and experience; only a first clear pays credits** ("Where fights happen") | credits on every floor | the spine stays clean and the lift can't be farmed, against a Tower that pays less cash | a balance run; step 4 |
| 7 | **The Tower:** a climb with health that carries, floors held by real players' saved teams (read only at launch, the gift for holding later and capped), each holder pinned until beaten, and a lift and recharges that run on stored energy ("Where fights happen") | written teams only, as in the director's reference (`docs/research/tower.md`) | the director's own idea in full with nobody online, against a store shared between servers | the builder's cost; step 4's blockout |
| 8 | **Teams of three,** the slice one against one | one against one for good | team-building, against harder reading on a phone | step 4 |
| 9 | **Stars:** copies fuse into a fixed, previewed result, five at most | no fusion at launch | a use for every copy with nothing to lose, against the thrill of a random fuse | after the slice |
| 10 | **About twelve traits, five or six mutations,** mutations from the Void weather | none at launch | the variable roll on every break, against balance work | after the slice |
| 11 | **Three things to spend,** each from its own source; the slice has credits only | one currency | each activity pays its own reward, against more to read | each system's blockout |
| 12 | **The player:** a level, one clan roll, an aura; and **ascension as the sketch's "prestige", a checklist with no wipe** ("The long game") | a level only | one identity roll and a climb that sends the player through every mode, against the four rolls in the sketch and the reset players of the genre know | the director, for the wipe; each track's blockout |
| 17 | **The long game's five rules:** tracks side by side, a token from every action, counters, luck as one number, tracks opened one at a time | add tracks as they come to mind | a grind with a structure, against holding back tracks the director wants early | each update |
| 13 | **Calamity's minimum is measured against a player's own strength** | the sketch's share of the total | newcomers can earn beside a strong player, against a rule that's a little harder to state | the director; under "Challenged", item 4 |
| 14 | **Every roll shows its odds and has a floor.** Nothing random, no reroll and no luck is sold at launch | sell rerolls with odds shown | no rule to trip and a fair game, against the most common income of the genre | the director, before any product |
| 15 | **Launch holds** the base, the Grid's first layers, the shop, 12 to 16 fighters, the first mutations, the Tower, the Index and stars. The arena and Calamity are the first updates | everything in the sketch at launch | a date that can be met at the bar, against a thinner first week | the slice's verdict |
| 16 | **NEXT isn't shown to players** until a licence exists | show it locked | no promise we can't keep, against a mystery at the top of the ladder | the director |

## Open

The directive's twelve areas (section 21), and what settles each.

| Area | Research's recommendation | Settled by |
|---|---|---|
| Void Shard shop | `docs/design.md`, "The Void Shop" | a balance run for chances, quantities and prices |
| Electricity | "The Grid" | TR2; the director's lock on proposal 1 |
| Processing | "Shards and Breakers" | TR2 |
| Initial roster | 12 to 16; the top rarities may fill through updates | the first fighter's timed cost (step 3) |
| Training | stations that work by themselves; a short burst by hand as a bonus | TR2 |
| Void Clash | teams of three; the Tower first, the arena later | step 4 |
| Combat | one basic attack and one signature skill; 15 to 25 seconds shown | the first fighter (step 3) |
| Fusion | stars | after the slice |
| Traits and mutations | proposal 10 | a balance run, after the slice |
| Economy | "What you own and spend"; a fighter's work stays bounded and the steep growth sits in stations and Grid upgrades ("The Grid") | a balance run before any price is built |
| Monetization | nothing sold in the slice. First candidates, all certain: slots, battery hours, an automation step early, the lift at half price, looks. The director's reference sells four passes and none is random (`docs/research/tower.md`) | the director, before any product |
| Release scope | proposal 15 | the slice's verdict |

Also open: the fighters' own word (research's pick is Voidkin: `docs/design.md`, "Words"); the machine's full name (`docs/ip-list.md`); the maturity label (`docs/roblox-rules.md`, "Not verified yet"); race and the player's own traits.

## Set aside

- Seeds, soil, planting (the director: section 3).
- "Void Pit" as the arena's name (the director: section 3).
- Original fighters in NEXT (the director: section 4).
- A text tutorial before the first input (research: `docs/research/first-seconds.md`).
- Wiring, voltage, anything that breaks when power is short (research: "The Grid").
- One shop stock raced for by the whole server (research: it punishes the far base and the phone).
- Taking anything from another player, at launch (research: a challenge gives the contest without the loss).
- A paid restock at launch (research: `docs/roblox-rules.md`).

## Challenged

The directive, section 2, asks for disagreement out loud, in this form: what's wrong, why it matters, the evidence, the alternative, the trade-off.

**1. Fighters that look like someone. The director's to decide.**

- **What's wrong:** two of the director's words pull apart. In chat: "visual very very similar but not 1:1 for example gojo would be named rojo with white hair a diff purple ish clothes but similar blue eyes blindfold". In the directive, the same day: "Renaming a recognizable character is not sufficient", and no character recreated "through recognizable combinations of appearance, signature skills, and other protected expression". The example is such a combination.
- **Why it matters:** Roblox acts on an owner's claim without judging likeness. A valid claim takes the whole game down and puts a warning on the director's account. Owners can now search games by keyword and by image.
- **The evidence** (`docs/roblox-rules.md`): no case found of a game removed for renamed lookalikes as such. Every removal on record followed a claim tied to one property, and the largest took down three anime games at once. So it isn't certain to happen, and what it costs when it does is the game.
- **The alternative:** the test under "Fighters". The real characters come in through NEXT, by licence, a route that exists today.
- **The trade-off:** less recognition at first glance. In return nothing can be claimed, and the fighters are ours to grow, which is also what a licence holder looks for.
- **Status:** the folder follows the directive. It changes only on the director's yes to this, restated: "fighters may be close lookalikes of published characters under new names".

**2. "there is 0 roblox games like this".**

- **What's wrong:** four games with this name's shape exist, and two of them are the chicken game's loop with anime fighters, made in October 2026. All four have zero players (`docs/research/similar-games.md`).
- **Why it matters:** the theme on that loop hasn't drawn players by itself. The gap is real for the whole of what we plan (shop, base, power, fights), and what fills it is how well it's made, from the first minute.
- **The alternative:** nothing to change in the plan. The first 20 seconds and the first fighter carry more weight than the idea.

**3. Everything the first day added.**

- **What's wrong:** on top of the directive's loop, the sketch and the words add a Tower, Calamity, base visiting, deep electricity, five progress tracks on the player and "a lot of upgrade features and luck". The directive, sections 1 and 17: a small excellent game first.
- **The alternative:** all of it has its place in `docs/design.md`, and the order is the plan's: the slice proves grow, power and one fight; launch is proposal 15; the rest are updates, each through its own blockout.
- **The trade-off:** a first release with less in it, on a date that can be met at the bar.

**4. Calamity's rule.** Proposal 13. The evidence: the director's own reference for long grinds pays a boss's rewards only above a share of its health, and its guides send players to private servers to get them (`docs/research/long-grind.md`). On our servers of eight that would empty the Strip.

**5. The reference's grind didn't hold its players.** It fell from 745,280 at once to about 1,000 in seven months, once updates stopped landing weekly, and its income was rerolls sold for Robux, the part Roblox's rules now bind. We take its structure (`docs/design.md`, "The long game") and leave both of those: updates are rows, so one a week is affordable, and no roll is sold.

**6. Studio conventions.**

- **The craft upgrade's animation half** (NEXT Button's repo, TR43 and AR29) is aimed at R15 and a creature. This game's fighters are R6, and the directive, section 11, asks that R6 be verified first. Research re-aims that half at R6, on this game's first fighter.
- **Balance runs.** The directive, sections 5 and 19, asks for relationships simulated before formulas. Research's brief says research never writes code. Proposal: research writes balance runs as scripts in its scratch folder, over rows the builder owns, and the builder reviews any that enter the repo. A change to the brief, for the director.
- **Roblox's Server Authority mode** is on in NEXT Button and cost days. This game's fights are settled by our own rules on the server, which gives the authority without the mode. The builder's call (`docs/engineering-plan.md`).
