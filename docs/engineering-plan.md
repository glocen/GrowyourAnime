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

- `Stats.resolve(voidkin, preset, account)` returns the full stat block. It's the only place stats are added up: the Voidkin's row and stars, each slot's item and forge rank, emblems, jewels, research. It returns the breakdown too, so the stat screen shows where each point came from: the Voidkin's own figure as two lines, its base (the level-1 figure) and what its level adds, then its stars and each slot (`Rules.Stats`; the tap is `Rules.Sheet`).
- `Combat.resolveHit(attacker, defender, move, seed)` returns one hit's result: dodged or not, physical and elemental amounts, critical, blocked, lifesteal. It's the only place the two buckets and their ceilings exist. A critical multiplies outside them, with no ceiling (`Rules.Hit`, `CriticalFactor`).
- Both are pure, both run on the server for truth, and the client may call the first for previews. Neither is copied: a second place that adds stats or computes damage is a bug.
- A test fails the build if any stat source multiplies another (`docs/balance.md`, "The one rule").

## Data contracts (a sketch)

The shape's home is `src/shared/Data/Profile.luau`, since TR2. This sketch is what it was built from.

**An owned Voidkin:** `Id` (made by the server when it's uncovered, never reused), `Def`, `Level`, `Xp`, `Stars`, `Copies` (duplicates not yet spent on a star), `Nickname`, `Preset` (which Regalia preset it's linked to), `Favourite`, `Locked`, `Born`. Its role is read from the slot that holds it (the builder, TR2).

**An owned item:** `Id`, `Def`, `Tier`, `Rarity`, `Design`, `Lines` (the rolled lines, the main stat first), `Sockets` (one a socket by its rarity: an emblem key or ""), `Reinforce` (its level, 0 to the cap), `Jewels` (a colour's level in its slot, none without a key). The level, the emblems and the jewels belong to the item, never the slot; equipping over an item that holds any offers to move them across (TR47, `Rules.Regalia.Transfer`).

**An emblem** is a key, `"set:stat"` (`Rules.Emblems`), never an owned row: its value is fixed by its set's rarity and its stat, so identical emblems stack in the bag.

**A profile:** `Version`; `Voidkin` by `Id`; `Index` by definition (first found, count); `Items` by `Id`; `Presets` (fourteen item ids each); `Bag` (shards and chests by id, stones by grade, emblems by key, jewels by `"Colour:level"`, each with its count); `Currency`; `Base` (bays with their worker, chambers with their shard, progress and stamp, the waiting line, the battery's charge in kWh, the plant's split (Auto, each machine's share, whether the Power screen is open: TR18), machine levels); `Research`; `Progress` (grounds opened, keepers beaten, Tower floor); `Shop` (what was bought against the rotation's number); `Claims` (the Calamity's windows, the daily track); `Champion`; `Funnel` (the first session's steps already logged, by name: TR32).

- **The base's levels** (TR21, the builder's contract, 2026-11-15): `Base.Level`, 1 to `Config.Base.Levels.Cap`; `Base.Machines`, each single machine's level by its name (the Breaker's now; the Condenser's, the Forge's and the Lab's when they come; the Training machine has none); and each bay's `Level` on its bay. What a level gives is computed from these by `Rules.BaseLevels`, never stored: the bays open, the battery's cap, a machine's ceiling, the Breaker's speed, rating and chambers, a bay's output. A base level bought opens its bays in the same change, and a Breaker level that brings a chamber adds it. Migration 5 gives each bay its level and opens the bays level 1 holds.
- **The showcase at the gate** (TR22, the builder's contract, 2026-11-15): `Base.Showcase`, the Id of the Voidkin picked with "Show at the gate", whatever its role, or "". Which one stands is `Rules.Collection.Showcase`'s: the pick while it's owned, else the strongest by Combat Power, then level, then Id. Reconcile fills the key into older saves.
- **The Stone Condenser** (TR37, the builder's contract, 2026-11-23): `Base.Condenser` = `{ Made, Tray, Convert? }`. `Made` is the part of the next stone worked so far, 0 to 1; `Tray` is the stones it holds by grade; `Convert` is the seconds of work a convert has had, or nil when none runs. Its level is `Base.Machines.Condenser`. Both are filled by Reconcile, so no migration. What it makes, its cap, its rating and the cups it lights come from `Rules.Condenser`, never stored. It is worked in `Rules.Breaker`'s event steps, online and away, at its share of the plant (`Rules.Power`). CollectTray and Convert each change the save in one step (`Rules.Base`).
- **Goals** (TR54, the builder's contract, 2026-11-24): `Goals` = `{ Days, Led }`.
  - `Days` holds up to `Config.Goals.Bank` days, oldest first, each `{ Day, Picks, Have, Claimed }`: its UTC day number (`Rules.Goals.DayOf`), the goal ids drawn for it (`Definitions.Goals`, one a list), how far each has come, and whether each is claimed.
  - A day's draw is fixed by the player's id and the day (`Rules.Goals.Draw`), so a rejoin or a second server never draws it again.
  - `Led` is the day's leads so far, `{ Day, Ids }`, for "someone new".
  - A goal's words, its reward and Next are computed from the rows and the save, never stored.
  - A dare lives with its run on the server and is never saved. Its stone goes into `Bag` as its stretch clears, so a later fall takes nothing back.
  - Filled by Reconcile, so no migration. A claim changes the save in one step behind the op ledger.
- The profile holds ids and numbers only: no model, part or display name.
- `Version` and one migration per step, from the first save.
- A nickname is stored raw and filtered for each viewer when shown (`docs/roblox-rules.md`).
- It sits on ProfileStore, under a layer of our own: see [the builder's calls](#the-builders-calls).

## The rework's contracts

The builder's, 2026-11-16, written before the systems (research's order, `docs/research/rework-2026-11-16.md`, part 12). The design they serve waits on the director's yes to its nine points. Each contract holds whichever way the open questions go: a name the director picks is a row's display name, never a key a save holds. Every number is a seed in `Config`, never here.

**Attributes in the resolver** (the proposal, parts 1 to 4).
- **The rows:** `Definitions/Attributes.luau` holds the two, Strength and Endurance (TR36, 2026-11-17, replacing the five), each with a stable id and its display name. The ids are the working names, so a rename changes only `Name`. `Config.Stats.Attributes` holds each one's conversion row, and each class's Main, its Main's own row and its shape.
- **Nothing is saved but gear's lines:** a Voidkin's points are computed (shape × rarity × G(level) × its stars), as its stats are today. Gear adds points as item lines whose `Stat` is an attribute id. When the five became two, migration step 8 turned each retired id on a saved line into the one that took its job (`Migrations.OldAttributes`), merging two that land on one.
- **Types** are named by the colours they wear, and the id is the name (`Red`, `Orange`, `Blue`, `Purple`, `Green`, TR36). No save holds one: a Voidkin's comes from its row, a Shade's from its row or its spawn. The gems' images are keyed `Gem<type>`.
- **`Stats.Resolve`** keeps its signature and its breakdown. The block gains `Attributes` (each total) and `Main`. The order:
  1. Points: the Voidkin's own, then each worn line's, flat.
  2. Each total converts once by its row.
  3. The Main converts once more by its class's row.
  4. Each conversion is a line (`Attr:<id>`, `Main:<id>`), so the sheet shows where every point of every Battle Attribute came from.
- **`Stats.Power` reads the Battle Attributes only,** never `Attributes`, so no point counts twice.
- **The even foe:** `Stats.EvenFoe(level)` builds its block from Config's on-budget ratings. The sheet's chances come from `Stats.Chance` against it, the function the hit uses.
- **Checks:**
  - logic cases for each conversion and each Main;
  - linearity: twice a source's points, twice exactly its lines; no source multiplies another;
  - Combat Power unchanged when only `Attributes` changes;
  - each shown chance equal to `Stats.Chance`, and never over its ceiling;
  - `tools/balance/attributes.py` reads the same Config, as `sim.py` does.

**Class rules** (part 10).
- **Item rows:** `Definitions/Items.luau` is the row an `OwnedItem.Def` names: `Id`, `Slot` (the kind of slot: `Ring` and `Earring` fit either of their two), `Kind`, `Name`, and `Class` on a weapon only. `Items.Fits(row, slot, class)` is the one answer to what goes where, asked by the resolver and the equip. A case checks each weapon's class against `Gear.Weapons`.
- **A preset:** `Slots` keeps the twelve shared slots. A new key, `Hands`, holds each class's pair: `{ [class]: { ["Main Hand"]: id?, ["Off Hand"]: id? } }`. The next migration moves any hand found in `Slots` under its item's class. None exists today, since items aren't built yet.
- **The resolver reads `Slots` and `Hands[its class]` only.** It also skips a hand item whose row's class isn't the Voidkin's. A hand-edited save can't apply a wrong weapon: two guards.
- **Equip:** one transaction, `Act("Equip", { Preset, Slot, Class?, Item })` with its op id. The server checks the owner, the slot against the row, and a hand's class. It refuses with `NotOwned`, `WrongSlot` or `WrongClass`, which the screen says, or `Unknown` for a request that isn't one. Unequip is the same with no item. An item moves within a preset rather than being worn twice (`Rules.Regalia`, TR26).
- **The comparison:** `Stats.Compare(data, preset, owned, item, slot?)` is the resolver run twice (without a slot, a ring or an earring goes where Combat Power ends highest), and returns the attribute changes, the Battle changes and Combat Power's. The screen calls it on its copy of the profile. It's the same pure function the server would call on the same data, so it can't drift, and no tap waits on a remote (the builder's call).
- **Checks:** a wrong-class equip refused; a preset applying only its class's pair; a hand-edited save not applying a wrong weapon; a repeated equip a no-op.

**Chests** (part 11).
- **The rows:** `Definitions/Chests.luau` holds `Id`, `Ground`, `Tier` and `Name`. `Config.Chests` holds the tables (rarity, slot and line rolls by ground and tier), the drop chances, the bag's cap, the open step (50) and the pickup reach.
- **The save:**
  - `Bag.Chests`: count by chest id. A stack is a count, so identical chests stack by shape.
  - `Settings.Salvage`: an opened item of this rarity or under turns into Credits (forge stones once the Forge is in), or `""` for none.
  - `Items` as they are.
  - Size, measured at the build (TR27): a full bag of 300 of the richest chest's items saves at 70 KB, about 208 bytes an item, against a profile's 4 MB.
- **A drop is granted on the server at the kill,** in the kill's own transaction (`Rules.Drops` through `Rules.Chests.Dropped`, with a roll drawn by `DropService`), as Watt's shard is today. A keeper's comes from its win's transaction (`Rules.Progress.KeeperWon` through `Rules.Chests.KeeperChest`), since the fall and the win are two listeners with no set order. The chest falling in the world and flying to the player is its show: "a reward is granted before its animation, never by it".
- **Open:** `Act("OpenChests", { Chest, Count })` with its op id. Count is at most the open step and at most what's owned. "Open all" is several requests, one op id each, and the summary shows once all have answered.
  - Each request is one transaction: it removes the chests, rolls each item with `Rules.Chests.Roll(chest, classes, draw)`, `draw` a generator seeded on the server in the transaction, never from the client, and applies the salvage. A weapon's class comes from `Rules.Chests.Classes`: the lead's at `Config.Chests.ClassLean`, else another class the player owns.
  - It writes everything in the same step and answers with the item ids and the salvage's totals.
  - It refuses `BagFull` before rolling when the items held and the count would pass the cap, and the chests stay. `Unknown` and `NotEnough` the same way.
  - The salvage's rarity is set by `Act("SetSalvage", { Below })`.
- **The salvage never takes an item that would raise Combat Power** (`Rules.Chests.Keep`, through `Stats.Compare`), against whom `docs/design.md` says ("Chests", "Auto-salvage"): a weapon against its class's best owned Voidkin, a piece every class wears against each class's best (`Rules.Chests.For`, by Combat Power in its own preset). A class the player owns none of protects nothing.
- **Rule 4:** no product grants a chest, a key or a rate. A case reads every product row, once the store has rows (none in `src` at TR27).
- **Checks:**
  - 1,000 opened in steps, every chest removed once and every item granted once;
  - a repeated op id answers its first answer;
  - a refused step changes nothing;
  - a server stopped mid-open applies nothing, and the request sent again opens once;
  - the save's size at a full bag.

**The Tower's run** (part 8).
- **The save:** `Progress.Tower` holds `Best`, `Run?` and `Results?`. `Run` is the ledger: `Id` (`Profile.NewId`), `Started`, `Floor` (the last won), and what's won (Credits, chests by id). `Results` is the last run's summary, kept until the screen has shown it.
- **Each floor won is one transaction** that writes the ledger. **The end is one transaction:**
  1. It grants the ledger.
  2. It raises `Best`.
  3. It writes `Results` and clears `Run`.
  An end that finds no `Run`, or another `Id`, is a no-op, so a run is granted once.
- **Interruptions:**
  - Leaving the ring, home, a disconnect or a shutdown each end the run on the server, before the profile is released.
  - A crash leaves `Run` in the save at its last saved floor. The next join ends it then, so nothing doubles and nothing won and saved is lost.
  - `Results` opens the screen once and is cleared by an `Act` with its op id.
  - A run never resumes.
- **The rules, pure, `Rules.Tower`:** `Foe(floor, seed)` gives the Voidkin row and the level, and `Block(foe)` its stat block: its own figure lifted to the seeds' build (`Config.Tower.Lift`, read from the model), since the engine has no build share (TR29). `Reward(floor, best, seed, fast)` gives a floor's Credits and chest roll, nothing for a fast floor, and its chest is the Tower's own tier, which rolls by `Config.Chests.Tower` (research's fit, TR29). `HealCap(maxHealth)` gives the most healed in one floor.
- **FightService:**
  - The foe is a Voidkin row fought as a rival for one player (`SpawnRival`): only that player's lead fights it, and its strikes touch no one else.
  - Healing passes one function that counts each floor's healing against the cap, so Lifesteal, when wired, is capped there too.
  - The lead, its stars and the preset freeze at the first fight, as at a keeper's try (`FightService.Frozen`, D10).
- **The world:** each plot's `TowerRing` marker, in `Shared.World.Tags`, with the world report counting one per owned plot. Platforms are the client's, from the run's floor attribute, never more than three. The server holds one floor's collision.
- **Checks:** health carried between floors; the heal cap; the ledger each floor; a disconnect granting what was won; a rejoin showing the results once; at most three platforms; captures of the climb and the results.

**A ground's stages** (TR43; `Rules.Stages`, `Config.Stages`, `StageService`).
- **The save:** `Progress.Stages[ground]` holds `Normal` and `Hard`, each `{ Cleared, Best }`: the highest stage cleared on it, and each stage's best seconds, 0 before one is timed. It's written from the first clear. A run is never saved.
- **A clear is one transaction** (`DataService.Change` with `Rules.Stages.Clear`): `Cleared` raised and the best kept, once a run (its `Claimed`), and its answer says what opened.
- **The run is the server's** (`StageService`): its kills come from `FightService.Fell`, for each hitter running that stage (on Hard, only the player's own foes, `For`); the keeper's stage from the try's win (`KeeperService.Won`). What counts, when a Hard pack stands again, whether a gate is shut, the keeper's try and fall in a run, the run's two cards and its attributes are pure (`Rules.Stages`: `Counts`, `Regrows`, `Shut`, `TryAt`, `KeeperFell`, `Won`, `Lost`, `Published`, `Parse`; 2026-11-20), so the service only wires them. A leave, the street left or the lead's fall ends it with nothing written.
- **Hard's foes** are the player's (`FightService.SpawnEnemy`'s `For`), and the lead fights alone while it runs (`SetSolo`). **The gates** are the server's per player: a walk across one shut is set back (`Rules.Stages.Passes`), the client only shows it.
- **The world:** `StageGate` and `StageStart` markers, and each `Pack` and `Elite` marker's `Stage`, in `Shared.World.Tags`.
- **Checks:** the offline cases (`Cases/Stages.luau`); the self-test's TR43 case (the gates, a Normal run to its card, Hard's own foes, the keeper lifted, the picker's locks, a lost run); a fresh account through the Door, Manual, since it wipes the save.

**The responsive layout** (part 6).
- **One module, `UI.Layout`:**
  - `Class()` gives Compact, Regular or Wide, from the viewport less the safe insets (`ScreenGui.ScreenInsets`, `GuiService:GetGuiInset`), on thresholds in `Config.UIKit.Layout`.
  - `Input()` gives Mouse, Touch or Gamepad, from `UserInputService.PreferredInput`, confirmed in Studio on 2026-11-16: KeyboardAndMouse, Gamepad, Touch and MicroGamepad, the last read as Gamepad.
  - `Changed` fires on a viewport, inset or input change, so a switch of device is live.
  - Hover reads `Input()` from then on, in place of its own last-input guess.
- **One kit:** each screen builds its frame from `Theme.Size[class]` (gutters, columns, the 44-point touch target) and rebuilds on `Changed`. No second set of screens. Wide is three columns, Compact and Regular two panes.
- **Gamepad:** focus through `GuiService.SelectedObject`. The shoulder buttons step the tabs and B closes, bound through `ContextActionService` above the game's priority while a screen is open.
- **Checks:** the UI lint for every screen at each class's smallest viewport (Compact at `Theme.Smallest`, the smallest phone held sideways; Regular at a tablet's 1024 × 768; Wide at 1920 × 1080) and in each input; under Touch, every target at 44 points or more; captures by eye at each class.

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

## The world contract

The handbook's rule ([the world contract](../handbook/engineering/architecture.md)), as this game keeps it. Built in TR2, 2026-11-12.

- **One list.** Every tag a world stamps and code reads, with its attributes and how many a world holds, is in `Shared.World.Tags`. Code reads markers only through `Shared.World.Markers`, never a tag's name as a literal, and only those inside `workspace`: copies in storage carry the same tags.
- **Whoever builds a world stamps it.** With no `workspace.World` in the place, `WorldService` lays research's layout in grey from `Config.World` and stamps it as it goes. An authored world (level design, later) replaces it by being there. A grey world saved into the place by mistake (attribute `Grey`) is laid fresh at boot.
- **The world report:** `NL_Debug:Invoke("WorldReport")` returns what's wrong, empty when the world is whole: a marker's kind and attribute types, enemy ids, plot numbers, ground under each standing marker, and the counts (per plot or in the whole world). The server logs it at boot, and the self-test checks it.
- **The grey world, laid out:** the crossing's centre is the origin and north is `-Z`. Plots are numbered west to east, the north row first. A World number tuned in a playtest lays it again, and `WorldService.Laid` tells whatever stands on a marker to find it again.
- **Plots:** the server gives each player the lowest free plot at join (the player attribute `Plot`, freed at leave) and sets them down on its spawn, facing the Breaker. Eight plots, so the place's Max Players is eight.
- **A plot no one owns is a bare lot** (the director, 2026-11-15: "if there 3 players out of 8 only 3 base are in"): its floor with its `Plot` marker, nothing else. A player's base, its plot's own markers and its dressing, stands when they arrive, before the attribute is set, and goes when they leave. `WorldService.Built` tells whatever stands on its markers. The report wants a plot's own markers on the owned plots and none on the rest.
- **One base plan for every plot**, laid in each plot's own frame (`Kit.Place`). A placement marked `"toward": "crossing"` is written for one side and mirrored, across and turn, onto each plot's crossing side (`Kit.Toward`, AR16's sleeping Tower); the dressing report checks it stands there.
- Screens read replicated state, never markers.

## Places

The Festival of Battles is a game mode, so it has its own place in this experience (the director, 2026-11-19: "festival of battle is a game mode it need a new places not the main experience", "u can make a new place inside this experience"). Built in TR45; the research behind it: `docs/research/game-mode-places.md`.

- **Two places, one code.** The base's place (`Config.Game.Places.Main`) holds the plots, the Strip, the Shop and the Towers; the Festival's (`Places.Festival`) holds Lantern Row's stages, its elites and its keeper. Both run the whole of `src/`. The workspace attribute `PlaceRole` ("Main" or "Festival", saved in each place, never synced by Rojo) is read once through `Shared.Util.PlaceRole`; with none the place is Main. Every place boots `Core` and `Main`, then the role's own folder if there is one.
- **A place per ground** (the director, 2026-11-19, by 11:16; `docs/decisions.md`): each ground gets its own place in this experience, and Normal and Hard are picked inside it, on its one map, never as separate places.
  - Today's Festival place is Lantern Row's. The base stays its own place.
  - The code changes at ground 2: a `PlaceRole` per ground, or a ground attribute beside "Festival", whichever the second ground's build shows is simpler. Until then nothing changes.
- **Each tag belongs to one place** (`Shared.World.Tags`, `Place`): `WorldService` lays only its place's half, and the world report wants none of the other's.
- **The trip is `TravelService`'s alone.** It sends one player at a time with `TeleportAsync` and `TeleportOptions` (a server asked for on the way home: the base server they came from, else any), retries a failed start by kind (`Rules.Travel.Next`: a flooded server after 15 s, a failure after 1 s, a server gone to any server once, the rest final), and gives up after a watchdog; the trip's card goes up on both sides of the loading screen (`SetTeleportGui`, then `ReplicatedFirst`'s `Arrival`).
- **The ticket is a request, never a grant.** The teleport data is the stage asked for, written by the sender and readable by the client, so the arriving server reads it with `Rules.Travel.Read` (unknown fields dropped, every value checked), trusts it only from one of `Config.Game.Places` (`Rules.Travel.Joined`), and checks it against the save before a run begins (`Rules.Travel.Arrival`): a stage the save keeps shut opens the menu instead. Nothing a player owns ever travels in it.
- **The save travels by the store, not the ticket.** It's released at leave and loaded at arrival as any join; the plot is freed while the player is away, and the way home lays it again.
- **Every way in opens the menu, and the menu sends.** In the base, the plot's door and the dock's Play tile open the stages' menu; a pick is the trip. In the Festival a pick begins the run in place, and the ground's door, the keeper's shortcut, the dock's Base tile and the results' Home are the trip home.
- **Studio can't teleport.** The self-test turns `TravelService`'s stub on for the run, so every trip asked for is recorded (`TravelSent`) and nothing leaves; `TravelFail` plays Roblox's refusals, `StageArriveBy` an arrival by ticket. A case with `Place` runs only in that place's playtest. A real trip is tested from the published places.
- **What's the director's in the dashboard:** each place's name, its server size (the Festival's at most `Plots.Count`, eight, set on the Creator Dashboard below 11), and the Festival's Direct Access set to "Secure within universe only", so it's reached only by a trip from our servers.

## Transactions

- Each change to a valuable is one server function: check, then apply everything to the profile, with no yield between.
- The client sends an operation id with each request. The profile holds the recent ones with their first answers (`Shared.Rules.OpLedger`), written in the same change as the operation, so a retry can't buy, break or forge twice, even after a crash or a server hop.
- A break's inputs (the shard, its ground, the luck applied) are fixed when it enters a chamber and can't change after.
- An upgrade names the level it buys, so a second tap sent with a fresh operation id is refused, never charged twice (TR21). A second tap is always a new request with its own id: the UI kit's Button refuses a press while its last is pending, and the rule refuses what the save can no longer pay for.
- A change the server makes on its own has no operation id, so its caller runs it once; where a repeat could still get past the caller, the rule refuses it too. A keeper's win while that keeper rests from this player's last is refused (`Rules.Progress.KeeperWon`, `Resting`; 2026-11-20): no try begins in the rest, so it can only be that win again.
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

## Content at scale

The director's word, 2026-11-13: "foundation / well made module script on everything to produce content at massive scales very fast". The runtime already keeps no `if id ==` branch: what follows is what one more item still costs, read from the code on 2026-11-13, and again after "Content as data" on 2026-11-14.

| Kind | Data today | Art today | Code still written per item |
|---|---|---|---|
| **A Voidkin** | its row (`Definitions/Voidkin`, its kit on it: `Kit`), 2 or 3 `Actions` rows, a `Props` entry if it lets go of a prop, two portraits in `Config/UIKit` | Modulo's model, sheet and clips scripts, to `build/handoff/<Name>/`, with its recipe | its install (`tools/studio/Models/<Name>.json`: the published ids, below, "The recipe contract"), and its signature's rows (below). Its self-test cases are the loops of item 5 |
| **An effect** | its rows, named by its action (`Action.Effect`): in `Config/Effects`, or a rows file in `Config/EffectRows` (Pip's and Lyric's shots) | the effect's art and rows scripts, to `<effect>.rows.json` (below, "The rows contract") | none. The three older signatures stay functions in `FighterController/Effects.luau` (`Config.Effects.Older`: Haymaker, Lantern Burst, Held Note) until the finish pass |
| **A Shade** | its row in `Definitions/Enemies` (rig, mask, action, type, scale); a new move needs an `Actions` row | its mask on the shared Shade rig; an elite's second mask needs its own entry and a fresh `Shade.rbxm` | none |
| **A keeper** | its `Enemies` row, 3 `Actions` rows, its `Animations` and `Falls` entries, its look and `Rows` | about six Blender scripts, and its install as a Voidkin's | its fall assumes a lantern and a pole (`LanternOut`), and an enemy has one action, so a signature never joins its fight (it plays only through `KeeperForce`) |
| **A ground** | its `Grounds` row and shard factor exist for all six; one Standard shard row | the street kit | `WorldService.lay` lays one street from one `World.Row`; nine world tags are one per world; one ring, one door target, and Lantern Row named in code. Lantern Row is the only ground at launch (the director, 2026-11-13), so this waits until after it |

**To become data,** in the order they pay at launch. Items 1 to 5 are in code since 2026-11-14 and pass their checks with Studio closed; their self-test cases wait on Studio.
1. **Effects as rows.** `Rows` gains what the older functions do by hand: a streak from a body point to the target on a beat (`Streak`), a sound on its frame (`Sound`), and a part's glow back over the cooldown (`Relight`). An action names its effect (`Action.Effect`), played through one player (`Effects.Play`), which replaced the `EFFECTS` table. The camera move is out, on the director's word of 2026-11-14: the camera never moves in a fight but for the hit's shake (`docs/decisions.md`). The three older signatures move over at the finish pass, where they're remade anyway.
2. **One model assembler.** `tools/studio/ModelRecipe.luau` builds every model from Modulo's recipe and the builder's install, in place of one script per model (below, "The recipe contract"). Author's `HELD` is read from the templates that ship. The Shade keeps its own script: one rig for every Shade, its masks by role.
3. **Rows from their file,** never copied by hand into `Config/Effects` (below, "The rows contract").
4. **A Voidkin's entries on its row:** its kit (`Kit`: Signature, Combo, Skip, Idle) on its `Definitions/Voidkin` row, which `Actions.Kits`, `Skips`, `RoleOf` and `IdleOf` read. `Config/Animations` keeps the shared clips' roles.
5. **One self-test per kind, looped over every item.** Every effect plays on a stand-in body: each of its rows shows, it lives to its end and ends on its frame, its streaks and relights run out, and it leaves nothing and puts its looks back, destroyed halfway too. Every Voidkin with a model is made the lead in turn: its R6 hidden, each piece held to the body, and each point and glow its effects use on it. The markers for every clip were already so.
6. **An enemy's kit,** as a lead's, so a keeper's signature joins its fight, and a fall built from any kept parts.
7. **After launch, streets by ground:** `World.Row` per ground, the one-per-world tags per ground, a ring and a door each.

The piece that does 1 to 5 is "Content as data" in `docs/production-plan.md`.

### The rows contract

An effect's rows are data: the asset maker's rows script writes them, and the game takes them as they are.
- **The file:** `build/handoff/<Name>/fx/<effect>.rows.json`, schema `rows/1`. It holds `Config.Effects`' Rows type as JSON, with "Schema" and "Effect" (its name) on top.
  - A Vector3 is `{"Vector3": [x, y, z]}`, and a Color3 is `{"Color3": [r, g, b]}`, from 0 to 255.
  - A missing value is null or left out.
  - A "Why" on the effect or a row is a note for the reader, dropped at load. A field the game doesn't know is refused.
- **Taking it:** `py tools/fx/rows_take.py <file>` copies it byte for byte to `src/shared/Config/EffectRows/<Effect>.json`, then runs the decoder and the rows' logic cases. A file they refuse is taken back out. A taken file is never edited: change the script that wrote it, and take it again.
- **In the game:** `Config.EffectRows` decodes each file once, at load, and `Config.Effects.Rows` takes them beside its own Luau rows. The player, a Tune and the checks see one kind of effect.
- **The reverse:** `py tools/fx/rows_export.py <Effect> <out.json>` writes an effect from `Config.Effects` as its file, tuned values and all. The keeper's signature and the lantern's exit can start a rows script this way. The logic case "the rows contract" takes every effect through its file and back.

### The recipe contract

A model is the asset maker's recipe and the builder's install, built by one assembler.
- **The recipe** (`build/handoff/<Name>/<Name>.recipe.json`, written by Modulo's model script) is in Roblox studs, Y up, the model facing -Z with its HumanoidRootPart at (0, 3, 0).
  - Each piece has its mesh file, its centre, and `on`: a rig part, or a piece before it.
  - A piece on a joint of its own has `motor`, the name the clips key, and `pivot`. Any other piece is welded. `edge` marks a shell that casts no shadow.
  - Its points: `name`, `on`, `at`.
  - Its glow (`emissive`): one, with its pieces, tint and `cold`; or groups, each with its pieces, tint, and `strength` or `cold`.
- **The install** (`tools/studio/Models/<Name>.json`, the builder's) holds the published ids (`Meshes` by piece, `Maps`), and what the recipe leaves to the builder: `NoShadow`, `GlowNames` (the attribute each glow group carries for the code), `Points`, `Lights` and `Humanoid`. The fields are listed in `ModelRecipe.Build`'s header.
- **The steps:**
  1. `py tools/upload/stage_model.py <Name>` copies the recipe and the meshes to `build/import`.
  2. Each new mesh is published once (`Assembly.PublishMesh`), and its id goes into the install.
  3. `Assembly.Build("<Name>")` builds the model in Studio, serialized into `src/storage/<Name>.rbxm`.
- **The check, Studio closed:** `lune run tools/checks/models_offline.luau` builds every installed model. It compares each with the template that ships, instance by instance, and the held parts with the templates'. `--recipe <Name>` checks that a new delivery builds, before its install. On 2026-11-14, Rook, Pip, Lyric and the Lamplighter build the same as their templates.

## How each system is tested

| System | First check | Then |
|---|---|---|
| Any code | the type check with Studio closed: `py tools/checks/luau_check.py` prints `0 new` | |
| Pure rules | their logic cases with Studio closed, under Lune | the same cases in Studio's `LogicTests` |
| Definitions | a logic case: ids unique, every row complete, rarity order exact, nothing above Mythical obtainable | |
| Stats and the hit | pure-rule cases: each source alone, all together, each ceiling, the breakdown summing to the total, no source multiplying another | the game's rows run through `tools/balance/sim.py`, so the simulation and the game read one set of numbers |
| The Breaker, bays, battery | pure-rule cases over time: shortage, overflow, away and back, a chamber emptied mid-work | a real leave and rejoin |
| Odds | a large sample of breaks against the odds shown | |
| Transactions | repeat and interrupt each one, offline where the rule is pure (seeded runs of the shard's way, gear's way, the Regalia transfer, the shop's buys and the Tower's runs; a star, the Tower's end, a repeated advance, a keeper's win) | two clients |
| Combat in the world | the self-test in a Run: leash, reset, defeat, a keeper's freeze | captures from the player's camera, research's verdict |
| Several players | two clients on a local server: plots, a leave, a join, an elite shared | a real second player |
| Screens | the UI lint at phone size with empty, full and long-name states, both themes | the rendered screen by eye |

A check names what it proves. No visual pass comes from a static check, and no simulation predicts what players will do.

## The package's gates

The package's six gates (A to F) and Astra's nine findings are acceptance checks, each attached to the piece that satisfies it in `docs/test-requests.md`. The negative cases the package lists (its file 02) become logic cases as their systems are built.

## For the Fable pass

The builder works on Opus 5.5. When the director's reset allows a Fable session (`docs/production-plan.md`, "Models"), these get a second read first, because a quiet mistake in them is the most expensive: the save layer and its migrations, the transaction functions, the resolver, and the Breaker's away-from-the-game math.
