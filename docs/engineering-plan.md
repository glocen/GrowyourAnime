# Engineering plan

The contracts the design asks of the code, and how the code is tested. Research's sketch of 2026-11-11, from the package's shared contracts (`docs/archive/package-v13/03_SHARED_DATA_AND_BEHAVIOR_CONTRACTS.md`) and the design in `docs/design.md`. Nothing here is built. **The builder owns this file from its first session** and corrects it freely: research wrote what the design needs, not how to code it.

## Locked

Nothing yet. A line moves here when the builder and research agree it's settled, and from then it changes only with the director's OK.

## The shape, in six lines

1. **Content is rows.** A Voidkin, a shard, an item, an emblem, a ground, an enemy and a research node are each a row in `src/shared/Definitions/`, with a stable id that never changes and never shows to players.
2. **A player owns instances.** An owned Voidkin or item is a small record pointing at its definition and carrying only what's its own.
3. **Rules are pure Luau.** What needs no engine (stats, a hit, the Breaker's progress, a shard's odds, the shop's stock) lives in `src/shared/Rules/`, touches no Roblox API, and runs with Studio closed.
4. **The server keeps time as stamps, not loops.** A machine stores its progress and when that was read. One pure function advances a base from one time to another, online or away.
5. **One owner per change.** Every change to something a player owns goes through one server function for that kind of change.
6. **One resolver.** Every stat anyone reads, and every hit, comes from one function each.

## The resolver

The package's D04, and the heart of `docs/balance.md`.

- `Stats.resolve(voidkin, preset, account)` returns the full stat block. It's the only place stats are added up: the Voidkin's row and stars, each slot's item and forge rank, emblems, jewels, research. It returns the breakdown too, so the stat screen shows where each point came from.
- `Combat.resolveHit(attacker, defender, move, seed)` returns one hit's result: dodged or not, physical and elemental amounts, critical, blocked, lifesteal. It's the only place the two buckets and their ceilings exist.
- Both are pure, both run on the server for truth, and the client may call the first for previews. Neither is copied: a second place that adds stats or computes damage is a bug.
- A test fails the build if any stat source multiplies another (`docs/balance.md`, "The one rule").

## Data contracts (a sketch)

**An owned Voidkin:** `Id` (made by the server when it's uncovered, never reused), `Def`, `Level`, `Xp`, `Stars`, `StarProgress`, `Nickname`, `Preset` (which Regalia preset it's linked to), `Role`, `Favourite`, `Locked`, `Born`.

**An owned item:** `Id`, `Def`, `Tier`, `Rarity`, `Lines` (the rolled lines), `Sockets` (emblem ids), `Jewel`.

**A profile:** `Version`; `Voidkin` by `Id`; `Index` by definition (first found, count); `Items` by `Id`; `Presets` (fourteen item ids each); `SlotRanks` (forge rank per slot); `Bag` (shards, emblems, jewels, stones by id and count); `Currency`; `Base` (bays with their worker, chambers with their shard, progress and stamp, the waiting line, the battery and its stamp, machine levels); `Research`; `Progress` (grounds opened, keepers beaten, Tower floor); `Shop` (what was bought against the rotation's number); `Claims` (the Calamity's windows, the daily track); `Champion`.

- The profile holds ids and numbers only: no model, part or display name.
- `Version` and one migration per step, from the first save.
- A nickname is stored raw and filtered for each viewer when shown (`docs/roblox-rules.md`).
- Whether this sits on the director's data system (ProfileStore, `PlayerHandlerData`, `ProductManager`) as in NEXT Button is the builder's first call (`AGENTS.md`, "Data and code").

## Who owns what

| State | Owner | The client's part |
|---|---|---|
| The profile, every currency and count | server | reads a copy |
| Combat: health, positions that matter, every hit | server, through the resolver | shows it, plays effects, predicts nothing that pays |
| What a break gives | server, rolled when the break finishes, before the reveal | plays the reveal |
| The Breaker, bays and battery | server, as progress and stamps | shows progress from the same values |
| The Void Shop's stock | server, from world time and a seed that never reaches a client, the same in every server | shows it, asks to buy |
| The Rift and the Calamity's schedule | server, from world time | shows the countdown |
| The Calamity's health | each server its own | shows it |
| The Clash Grounds | server: champions are server-run from their owner's saved stats | watches |
| Bases: who has which plot | server, at join | walks around |

## Transactions

- Each change to a valuable is one server function: check, then apply everything to the profile, with no yield between.
- The client sends an operation id with each request. The server remembers recent ones and answers a repeat with the first result, so a retry can't buy, break or forge twice.
- A break's inputs (the shard, its ground, the luck applied) are fixed when it enters a chamber and can't change after.
- A reward is granted before its animation, never by it.
- Nothing above Mythical, and nothing Limited, can come from any roll at launch: refused in the rules themselves.

## Reusable modules

The director's proposal of 2026-11-11, in their words: "faber should maybe code while thinking long term to save time and be more efficient like make whole systems in module so he can re use them etc.. now this is just a proposal and i want to be perfectly clear, he should solely code in a way that benefits him not me nor my idea if it negative."

It's the builder's call, system by system. Where research sees the design itself repeating, and a shared module would likely pay:

| The design repeats | So one module could serve |
|---|---|
| a thing that progresses over time, online or away | chambers, bays, the battery, research, any later machine |
| a server-run fighter with a stat block and a kit | the lead, Shades, keepers, champions, Echoes, Tower opponents, the Calamity |
| a stock that rotates on world time with limits | the Void Shop, later event shops |
| a schedule on world time | the Rift, the Calamity, the daily track |
| a grid of owned things with sort, filter and compare | Voidkin, items, emblems, the bag |
| a reveal with tiers of ceremony | shards, rare drops, evolution |

A module is worth it when its second user exists in the design. Building for one nobody has designed yet isn't asked for.

## How each system is tested

| System | First check | Then |
|---|---|---|
| Any code | the type check with Studio closed | |
| Definitions | a logic case: ids unique, every row complete, rarity order exact, nothing above Mythical obtainable | |
| Stats and the hit | pure-rule cases: each source alone, all together, each ceiling, the breakdown summing to the total, no source multiplying another | the game's rows run through `tools/balance/sim.py`, so the simulation and the game read one set of numbers |
| The Breaker, bays, battery | pure-rule cases over time: shortage, overflow, away and back, a chamber emptied mid-work | a real leave and rejoin |
| Odds | a large sample of breaks against the odds shown | |
| Transactions | repeat and interrupt each one | two clients |
| Combat in the world | the self-test in a Run: leash, reset, defeat, a keeper's freeze | captures from the player's camera, research's verdict |
| Several players | two clients on a local server: plots, a leave, a join, an elite shared | a real second player |
| Screens | the UI lint at phone size with empty, full and long-name states, both themes | the rendered screen by eye |

A check names what it proves. No visual pass comes from a static check, and no simulation predicts what players will do.

## The package's gates

The package's six gates (A to F) and Astra's nine findings are acceptance checks, each attached to the piece that satisfies it in `docs/test-requests.md`. The negative cases the package lists (its file 02) become logic cases as their systems are built.

## For the Fable pass

The builder works on Opus 5.5. When the director's reset allows a Fable session (`docs/production-plan.md`, "Models"), these get a second read first, because a quiet mistake in them is the most expensive: the save layer and its migrations, the transaction functions, the resolver, and the Breaker's away-from-the-game math.
