# Engineering plan

The contracts the design asks of the code, and how the code is tested. Research's sketch of 2026-11-11, from the package's shared contracts (`docs/archive/package-v13/03_SHARED_DATA_AND_BEHAVIOR_CONTRACTS.md`) and the design in `docs/design.md`. **The builder's from 2026-11-12** (TR1), corrected where the code taught something.

## Locked

Nothing yet. A line moves here when the builder and research agree it's settled, and from then it changes only with the director's OK.

## The shape, in six lines

1. **Content is rows.** A Voidkin, a shard, an item, an emblem, a ground, an enemy and a research node are each a row in `src/shared/Definitions/`, with a stable id that never changes and never shows to players.
2. **A player owns instances.** An owned Voidkin or item is a small record pointing at its definition and carrying only what's its own.
3. **Rules are pure Luau.** What needs no engine (stats, a hit, the Breaker's progress, a shard's odds, the shop's stock) lives in `src/shared/Rules/`, touches no Roblox API, and runs with Studio closed.
4. **The server keeps time as stamps, not loops.** A machine stores its progress and when that was read. One pure function advances a base from one time to another, online or away.
5. **One owner per change.** Every change to something a player owns goes through one server function for that kind of change.
6. **One resolver.** Every stat anyone reads, and every hit, comes from one function each.

## The builder's calls

Made in TR1, 2026-11-12. Each is the builder's technical call (`AGENTS.md`, "Design changes"), and each says what would reopen it.

**The save layer: ProfileStore kept, everything above it ours.**

- **ProfileStore stays,** unedited, in `src/libraries/server/`, fetched from its source (Mad Studio's ProfileStore, a pinned release) when TR2 builds saving, and called through one wrapper of ours. Its session lock is what keeps two servers from writing one profile, the classic way a game duplicates items, and the directive says it plainly: "do not rewrite a proven persistence library just to create a new system" (section 9).
- **`PlayerHandlerData` and `ProductManager` are replaced,** with a layer written fresh for this game. NEXT Button's (`src/owner/`, read 2026-11-12 on the director's OK) holds pets as counts by kind, where section 9 wants a unique id per owned Voidkin with its own level, stars and history. It changes a profile through about thirty-five one-field setters with game rules inside them, and syncs the client with one remote event per field. Only its store receipts are safe from a repeat. The director, 2026-11-12, on reading it: "sure but i think we should redo everything so we make it perfect, next button was kinda.. rushed". That word covers NEXT Button's data system.
- **Purchases start from the director's `ProductManager`.** The director, 2026-11-12, mid-TR2: "we can use my data systems by the way as always as well as the product handler etc". Shown the trade, they chose: the new save layer stays, and when the store is designed, their `ProductManager` is the starting point for purchases, adapted to this layer. Then: "just whatever best and has the highest quality and is robust this is a sensitive issue". So when the store is built, the builder reads their `ProductManager` first and keeps whatever of it is the most robust. That covers purchases only. `PlayerHandlerData` stays replaced.
- **Built in TR2, 2026-11-12:** ProfileStore 1.0.3, pinned (`src/libraries/README.md`); the shape in `Shared.Data.Profile`, migrations in `Shared.Data.Migrations`, and every write as one `Shared.Data.Transaction` (on a copy, committed whole, op id in the same step), opened and closed by `DataService`. A Voidkin's role is read from the slot that points at it, not stored on it, so a role has one home.
- **Kept as lessons, rewritten in our code:** a receipt is granted only once its purchase id is saved (ProfileStore's documented way); `AddUserId` on every profile, for data deletion requests; a profile whose session ends kicks its player; Studio and live servers use different stores.
- **Reopen it** if ProfileStore's lock fails a test we write for it, or Roblox ships a save service that locks sessions itself.

**Server Authority: off** (`Workspace.AuthorityMode` Automatic).

- The player's avatar is never a target and never deals damage (`docs/design.md`, "Combat"): the server runs every Voidkin, Shade and keeper. Server Authority's prediction protects movement and hits that the player times, and this game has none.
- What it would cost: more server load, the step's rules on every system ([server authority](../handbook/engineering/server-authority-and-netcode.md#the-rules-of-the-step)), and animation ids that play only once published, which slows Modulo's iteration.
- Where the avatar's position earns something (the lead's leash, a pickup), the server checks the avatar's speed.
- **Reopen it** if a player-timed action or movement against another player is designed.

**Pure rules run with Studio closed,** under Lune (`rokit.toml`), through `tools/checks/logic_offline.luau`.

- A rule's cases live in `src/server/Services/Core/LogicTestService/Cases/`, one file per rule module, and require their rules through `game:GetService("ReplicatedStorage")`. The same file runs in Studio's `LogicTests` and offline:
  `lune run tools/checks/logic_offline.luau src/server/Services/Core/LogicTestService/Cases`
- Tried on `Shared.Rules.OpLedger`: every case passes offline, and a planted bug (a repeat overwriting the first answer) fails it.
- The runner never proves the engine does what a rule assumes: cases about players, attributes, remotes and saves stay in Studio.

## The resolver

The package's D04, and the heart of `docs/balance.md`.

- `Stats.resolve(voidkin, preset, account)` returns the full stat block. It's the only place stats are added up: the Voidkin's row and stars, each slot's item and forge rank, emblems, jewels, research. It returns the breakdown too, so the stat screen shows where each point came from.
- `Combat.resolveHit(attacker, defender, move, seed)` returns one hit's result: dodged or not, physical and elemental amounts, critical, blocked, lifesteal. It's the only place the two buckets and their ceilings exist.
- Both are pure, both run on the server for truth, and the client may call the first for previews. Neither is copied: a second place that adds stats or computes damage is a bug.
- A test fails the build if any stat source multiplies another (`docs/balance.md`, "The one rule").

## Data contracts (a sketch)

The shape's home is `src/shared/Data/Profile.luau`, since TR2. This sketch is what it was built from.

**An owned Voidkin:** `Id` (made by the server when it's uncovered, never reused), `Def`, `Level`, `Xp`, `Stars`, `Copies` (duplicates not yet spent on a star), `Nickname`, `Preset` (which Regalia preset it's linked to), `Favourite`, `Locked`, `Born`. Its role is read from the slot that holds it (the builder, TR2).

**An owned item:** `Id`, `Def`, `Tier`, `Rarity`, `Lines` (the rolled lines), `Sockets` (emblem ids), `Jewel`.

**A profile:** `Version`; `Voidkin` by `Id`; `Index` by definition (first found, count); `Items` by `Id`; `Presets` (fourteen item ids each); `SlotRanks` (forge rank per slot); `Bag` (shards, emblems, jewels, stones by id and count); `Currency`; `Base` (bays with their worker, chambers with their shard, progress and stamp, the waiting line, the battery and its stamp, machine levels); `Research`; `Progress` (grounds opened, keepers beaten, Tower floor); `Shop` (what was bought against the rotation's number); `Claims` (the Calamity's windows, the daily track); `Champion`.

- The profile holds ids and numbers only: no model, part or display name.
- `Version` and one migration per step, from the first save.
- A nickname is stored raw and filtered for each viewer when shown (`docs/roblox-rules.md`).
- It sits on ProfileStore, under a layer of our own: see [the builder's calls](#the-builders-calls).

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
- The client sends an operation id with each request. The profile holds the recent ones with their first answers (`Shared.Rules.OpLedger`), written in the same change as the operation, so a retry can't buy, break or forge twice, even after a crash or a server hop.
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
| Any code | the type check with Studio closed: `py tools/checks/luau_check.py` prints `0 new` | |
| Pure rules | their logic cases with Studio closed, under Lune | the same cases in Studio's `LogicTests` |
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
