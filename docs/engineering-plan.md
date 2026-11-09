# Engineering plan

The architecture sketch and the validation plan the directive asks for (`docs/directive.md`, sections 8 to 10, 18 and 22, D and G). Research's sketch, 2026-11-09: nothing here is built, and nothing is locked. The builder owns this file from day one and corrects it. A line moves under "Locked" only with the director's OK.

## Locked

Nothing yet.

## The shape, in five lines

1. **Content is rows.** A fighter, a shard, a machine, a trait, a mutation, a rarity and a skill are each a row in `src/shared/Definitions/`, with a stable id that never changes and never shows to players.
2. **A player owns instances, not definitions.** An owned fighter is a small record that points at its definition and carries what's its own.
3. **Rules are pure Luau.** What needs no engine lives in `src/shared/Rules/` and touches no Roblox API, so it runs with Studio closed.
4. **The server keeps time as stamps, not loops.** Processing and training store when they started, and the result is computed when someone looks. Offline progress comes free, and nothing ticks per fighter.
5. **A battle is a log.** The server resolves a whole fight at once from the two teams and a seed, pays the rewards, and sends the log. The client plays it back as a show and decides nothing.

## Data contracts (a sketch)

**An owned fighter:**

| Field | What it is |
|---|---|
| `Id` | unique, made by the server when the fighter is uncovered, never reused |
| `Def` | the definition's stable id |
| `Level`, `Xp` | its own progress |
| `Stars` | fusion's result, if fusion is star-based (`docs/decisions.md`, "Proposed") |
| `Traits`, `Mutation` | what it rolled |
| `Born` | when it was uncovered |
| `Locked` | the player's guard against fusing it away |

**A profile:** `Version`; `Fighters` by `Id`; `Index` by definition id (first found, count found); `Shards` by shard id; `Currency`; `Base` (machines with their queue and start stamps, training spots with their fighter and start stamp, power, upgrades); `Clash` (progress); `Ops` (the last operation ids).

- No model, part or display name is saved: the profile holds ids and numbers only.
- `Version` and one migration function per step, from the first save.
- Whether this sits on the director's data system (ProfileStore, `PlayerHandlerData`, `ProductManager`) is the builder's first call (the directive, section 9).

## Who owns what

| State | Owner | The client's part |
|---|---|---|
| The profile, every currency and count | server | reads a copy |
| The shop's stock | server, from the clock and a seed, the same in every server | shows it, asks to buy |
| Processing and training | server, as start stamps | shows progress from the same stamps |
| Which fighter a shard gives | server, at the moment processing ends | plays the reveal |
| A battle's outcome and rewards | server, in one step | plays the log |
| Fusion | server, in one step | previews from the same pure rule |
| Bases: who owns which | server | walks around |

## Transactions

- Each change to a valuable is one server function: check, then apply everything to the profile, with no yield between the two.
- The client sends an operation id with each request. The server remembers the last ones and answers a repeat with the first result, so a retry can't buy, fuse or uncover twice.
- NEXT is refused in the rules themselves: no roll, fusion or reward can return a NEXT fighter (the directive, section 4).

## The extension test

Run once, as a checklist, when the slice's data exists (the directive, section 8). Each of these should be a new row, or one new rule module, with no change to saved data and no edit to an unrelated system: another rarity, a new fighter, a machine upgrade, a shard type, a base theme, a training activity, a combat mode. A miss is fixed in the structure. Nothing hypothetical is built to prove it.

## Roblox's Server Authority mode

A question for the builder, before the place is set up. "Server-authoritative" in the directive means the server decides what a player owns and who won. That needs remotes that validate, not the engine's `AuthorityMode`. The mode cost the last game days (attribute limits that throw, controls that moved: `handbook/engineering/server-authority-and-netcode.md`), and it exists for games where the player's own body fights. Here the fighters are the server's, and the player only walks. Research's reading: leave the mode off unless a test shows a need. The builder decides.

## How each system is tested

| System | First check | Then |
|---|---|---|
| Any code | the type check with Studio closed, `luau_check.py` (tested on NEXT Button) | |
| Definitions: ids unique, rarity order exact, no NEXT at launch | a logic case | |
| Power, experience, the shop's roll, processing, fusion's rules, capacity | pure rules under a headless runner, if the first experiment holds; else the logic tests in Studio | balance runs over the same rows |
| A battle | the same seed gives the same log; boundary values; each trait and mutation alone and together | the show, judged by eye in Studio |
| Transactions | repeat and interrupt each one in a logic case | a real leave and rejoin |
| The base, the reveal, training, the arena | the self-test in a Run | captures from the player's camera, research's verdict |
| Several players | two clients on a local server: bases assigned, a leave, a join | a real second player on real ping |
| Screens | the UI lint (clipping, overflow, overlap, touch sizes, safe areas) with empty, full and long-name states | the rendered screen, at phone size, by eye |
| Sound | each cue heard in the game | |

A check names what it proves. No visual pass comes from a static check, and no balance run predicts what players will do.

## New experiments this game asks of LYNX

One at a time, each with its question, in `handbook/studio/lynx.md`'s form. Only these three are asked for now:

1. **A headless runner for the pure rules.** Can the rules run and be tested with Studio closed, in seconds? It decides where combat's and the economy's tests live.
2. **Balance runs from the game's own rows.** Can a script read the Definitions and play out the four kinds of player the directive names (section 19)? It decides whether numbers are tuned before they're felt.
3. **The UI lint on a phone layout,** from the first screen, so the first screen sets the kit.

Selene, StyLua, Open Cloud checks and a staging place stay out until one of them answers a problem this game has.
