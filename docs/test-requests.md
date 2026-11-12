# Test requests

The builder's and QA's queue, in order. A piece's record is its entry here: the feel line, what the block contains, what waits, the checks, the verdict. Nothing about a piece is written twice.

## TR1. Day one: the repo, the place, the kit (Faber)

Tooling, with nothing players see, so no feel line and no blockout. Phase 0 of `docs/production-plan.md`.

- **Join the repo.** The folder has local history and `origin` (`github.com/glocen/GrowyourAnime`) has one first commit with a README. They've never met, and research's session can't join them. Join them without losing either (a merge that allows unrelated histories, keeping this folder's files), then push. From then on, pull and push as `AGENTS.md` says.
- **Update the handbook clone** in `handbook/`: it's behind the studio's.
- **Check the ids** the director gave on 2026-11-11: universe 9093907961, place 78052287756826, under group 35516567. Correct `CLAUDE.md`, "Places", if anything differs. Open the place in Studio with Rojo on port 34876.
- **Bring in the kit,** one group at a time, by `handbook/tech/README.md`, "Setup steps": the runtime pieces, the self-test, the logic tests, the debug bridge with live numbers, the type check.
- **Trim the starter** to this game: one place role; the `Hub` and `Match` folders renamed or dropped.
- **Three calls that are yours,** each recorded in `docs/engineering-plan.md`:
  - the save library: the director's data system from NEXT Button's `src/owner/`, kept, adapted or replaced, with the reason. Bringing it into this folder is reading outside the project, so it waits for the director's OK;
  - Roblox's Server Authority mode, on or off;
  - a headless runner for the pure rules, tried on one small rule module.
- **Read `docs/engineering-plan.md`** and correct it: it's yours from today.
- **The hooks' first run here:** say in this entry whether each session was told its role at start.

**Pass:** the repo is pushed and level; Studio boots clean on both sides; the self-test runs with nothing failing; the type check prints `0 new`; each teammate's session is told its role.

**Status:** done, 2026-11-12 (Faber). Implemented and tested; nothing players see, so no visual pass; not yet director-accepted.

- **The repo:** joined by a merge that allows unrelated histories (`57c8145`), this folder's tree unchanged, pushed, `main` tracking `origin/main`. The handbook clone pulled level with the studio's.
- **The ids:** the open place reads place 78052287756826, universe 9093907961, created by group 35516567. `CLAUDE.md` needed no change. Rojo serves on 34876.
- **The kit, in `src/`:** `Net`; `Log` (prefix `[GA]`), `Signal`, `Parts`, `Tune`, `Preset`, `TestInput` in `Shared.Util`; `Config.Presets` with `Baseline`; in `Services/Core` the debug bridge (`BootErrors` added), `TuneService` (live numbers, and a `Preset` command), `LogicTestService`, `SelfTestService`; in `Controllers/Core` `TuneController` and `SelfTestController`, cut to this game (no stamina, lock-on or entity state: the avatar never fights). Not brought in, until a piece uses them: `Raycast`, `Vector`, `UiLint`, the action stage, and the capture, animation, audio and effects tools.
- **The checks:** `tools/checks/luau_check.py` (luau-lsp, new solver) found 18 findings in the kit's own files and all were fixed in code, so `luau-known.txt` is empty. `tools/checks/logic_offline.luau` under Lune, now taking a folder of case lists.
- **The trim:** one role, `Main`; `Hub`, `Match` and the empty `Simulation` dropped. Pure rules live in `Shared.Rules`.
- **The three calls:** in `docs/engineering-plan.md`, "The builder's calls": ProfileStore kept under a save layer of our own (the director's word of 2026-11-12 on NEXT Button's data system is quoted there); Server Authority off, and the place switched to `AuthorityMode` Automatic; Lune for pure rules, tried on `Shared.Rules.OpLedger`.
- **The hooks:** the instruction lint and the tool guard installed on the director's yes (2026-11-12), exactly the handbook's example without the Studio lock. Hooks self-test 126 passed; the lint 0 findings; the guard refused a `git stash` live and let the builder's Studio calls through. **Each session was told its role at start:** Quaestor as Research, Faber as Builder, Modulo as Assets (`.claude/state/roles/`, 2026-11-11 23:17 UTC).
- **The director, 2026-11-12:** "player avatar will be R6 only do not worry". It covers the player's avatar. The self-test's `Avatar: R6` case holds it.
- **Tested, 2026-11-12, in the open place under Automatic:** boot 0 errors on both sides; the self-test 11 passed, 0 failed (1.7 s, 60 fps); `LogicTests` 29 passed; offline, the same 29 pass, and a planted bug (a repeat overwriting the first answer) fails 2; the type check `0 new`.
- **Learned:** a folder rename under a served Rojo crashed it (00:27), as `handbook/engineering/project-setup.md` warns. `AuthorityMode` reads and sets from MCP now. Without Server Authority the place has no input-action controls, and `TestInput.MoveBinding`'s two 5-second waits cost every self-test 10 s: it now looks once. These, and the 18 type fixes to the kit's files, are the handbook's to take (research).
- **Open:** the place's `AuthorityMode` change waits for a save of the place. `rbxassetid://203785492` fails to load at play start ("Asset type does not match requested type"). It's in no instance of the place, so the player's own avatar appearance is the likely source, unverified.

## TR2. The circuit, in grey (Faber, to research's feel line)

Phase 1. A blockout of the whole loop: grey boxes and stand-ins, no art, placeholder sound at most. It answers one question: is the loop worth playing before any art?

**Feel line:** you break a shard and somebody steps out; they fight beside you down a street of enemies while a second one powers your base; you come home to a shard that's ready, and you want the next one.

**The block contains:**

1. **A base** on a plot: the Breaker with two chambers and a waiting line, one bay open and a second locked, the battery.
2. **Three starter shards,** one chosen, broken fast. A reveal as a card with a name: no ceremony yet.
3. **The lead:** an R6 stand-in that follows, fights what's near the avatar by the real rules (leash, reset, down and back), with one melee combo and one signature on a cooldown. Rook's row from `docs/roster.md`.
4. **The resolver and the stat block** (`docs/engineering-plan.md`), with the level table and a first item tier from `tools/balance/seeds.json`. The numbers are read from data, exposed at runtime.
5. **Lantern Row** as a grey street: Brawler Shades as boxes with a mask shape, one elite, the Lamplighter's ring with a keeper that only has health and a basic attack.
6. **Drops:** Credits, Standard shards, one Named shard for Watt from the first enemy.
7. **Work:** Watt in a bay makes electricity; the Breaker draws it; shortage slows it.
8. **Saving,** on the library chosen in TR1, with the profile's shape and its version.
9. **A plain HUD** in `docs/ui.md`'s layout with stock frames: the lead's card, the target's card, two pills, the dock, damage numbers.

**What waits:** every finished look and sound; the reveal's ceremony; Regalia beyond one equipped item per slot; the Forge; presets; the other grounds; the shop, the Rift, the Tower, the Clash, the Calamity; a second attack family.

**Checks:**

- Logic cases: stats add and nothing multiplies; each ceiling; a hit's breakdown; the Breaker over time (shortage, overflow, away and back, a shard taken out mid-work); odds against a large sample; each transaction repeated and interrupted; a leave and a rejoin.
- The package's gates this piece answers (`docs/archive/package-v13/02_FIRST_PLAYABLE_AND_OWNERS.md`): A, the contract (one schema owner, one test namespace); B, the first circuit (every step on a fresh account, through a reconnect and hostile requests); and the saving half of D (work left partly done, a return after 8 to 12 hours away, full and empty caps, no transaction doubled). Its negative cases for those become logic cases.
- The seeds as the game holds them, run through `tools/balance/sim.py`, or the builder's reason they can't be yet.
- Research's verdict in motion, from the player's camera, at phone size. The director's play when they want it.

**Pass:** a new account can play from the first shard to the Lamplighter's fall and come back to a saved base. Research's verdict says whether the loop holds, and names the one thing to change if it doesn't.

**The builder's read, 2026-11-12.** On research's layout (`docs/design.md`, "The world, in grey") and the package's changes (`docs/decisions.md`, "What changed from the package"):

- **The keeper, fought alone (the builder's call):** eight copies of the ring, one per plot, out of sight. The keeper's gate starts a try: a short fade, then the avatar and the lead stand in their own copy with a fresh keeper. A win sets them down beyond the ring, by the shortcut and Drum Court's shut gate. A loss or a leave sets them back before the keeper's gate. The ring in the street stays, so the player sees the same place. I ruled out phasing (one ring, other players' fights hidden on each client): every effect, sound and collision would have to know whose fight it is, and each slip would show. A copy costs one fade.
- **Whose a pack is (tier 2, research's call):** the street is shared and the layout doesn't say. My proposal: a pack belongs to everyone, every player whose lead hit a Shade gets its drop in full (the elite's rule), and a pack comes back a set time after its last Shade falls (a seed of 15 s, in Config). With eight players, six packs and parking allowed (`docs/design.md`, "Combat"), giving a pack to its first hitter leaves the others walking past fights they can't join.
- **The street's length follows the spacing (tier 2, a pace number):** three packs, the elite's square, three packs and the keeper's gate, one spacing apart each, so tuning one number keeps the rhythm. At 80 studs that's about 590 studs, 37 s, not 640.
- **Plot depth isn't in the layout.** I'd make it 80, with the back 24 kept, then a 16-stud path and a Tower footprint of 32: that gives the side street its 8 s (128 studs).
- **Walk times, by my count:** about 15 s from the near plots to the first pack, 21 from the far ones, and 22 from the far ones on the Shop's side, which cross the Strip. I'm not asking for a change: walking will tune it.
- **The grey world is laid by code (the builder's call):** a server module builds it from `Config.World` (times, the walk, widths) when the place has no authored world. It builds it again when a number is tuned in a playtest. It stamps the markers an authored world will carry (`Shared.World.Tags`, contract in `docs/engineering-plan.md`), so dressing Lantern Row (AR5) changes no code that reads them.
- **Shade numbers (mine, in Config):** a pack notices a lead within 20 studs and gives up past 40 from its spawn, so a fight never pulls the next pack 80 studs on.
- **Eight plots means eight players per server.** Max Players must be 8: a director's click in Game Settings.
- **The package's changes: nothing I'd change.** For the data: a preset holds item ids, so one item may sit in several presets and nothing moves between them. Whether a Tower line-up of three may wear one item twice is a phase 3 question. Chambers, bays and the battery all progress over time, so TR2 builds that as one module.

**Research's answer, 2026-11-12:** yes to both: a pack belongs to everyone, full drops to every hitter, back after a wait; the street's length follows the spacing. Both are written in `docs/design.md`, "The world, in grey". The plot depth and the Shade numbers are fine as read. When the seeds are in Config, run the sim on one player's kills a minute at a crowded pack against a lone player's, and bring it to research if the crowd earns more than half again. Max Players at 8 goes to the director.

**The builder's seeds, for research (tier 2), 2026-11-12.** In Config, dated, standing in the dev build until research answers. A Credit is measured against a ground-1 kill (10, seeds `pace.creditsPerKillPerG`).

- **The floor's price** (`Config.Base.Breaker.MinSpeed` 0.25): with no power the Breaker runs at a quarter speed, and that floor is free: a Standard shard takes 120 s instead of 30 and draws only what the workers make. Electricity buys speed (4x), never access. If power should gate breaking harder, the floor goes lower (0.05 is 10 minutes a shard), never to zero ("never stops dead").
- **The battery** (`Config.Base.Battery`): it starts holding 20, one Named shard's work, so Watt's shard breaks at full speed before any worker exists. The cap is 600, about 100 minutes of two ground-1 workers. Overflow sells at 0.05 Credits each, so an hour of Watt's overflow (180) pays 9 Credits, under one kill.
- **Away** (`AwayHours` 2): I read the seeds' `bays.batteryHoursByGround` as the workers making electricity for 2 hours away, then the Breaker running on what the battery holds. Ten hours away with six Standard shards and Watt at work: all six break, and the battery ends at 342.
- **Shards** (`Config.Shards.Grades`): a Named shard is a Standard's 30 s and 20; a starter is 6 s and free (D01's "fast").
- **A copy past seven stars** (`Config.Voidkin.SellCredits`): ten times the seeds' `shards.value`, so a Common copy pays one ground-1 kill and a Mythical's a thousand.
- **Drops** (`Config.Drops`): each hitter gets a fall's drop in full, 10 Credits and the pace table's experience a kill, times G, times a share by kind: an ordinary Shade 1, the elite 3.6, the keeper 9 (each one's time to fall against an ordinary's, at the seeds' numbers). A Standard shard drops at 4% a kill (the seeds' 18 an hour over 450 kills), raised by the same share (the elite 14%, the keeper 36%). Watt's Named shard comes once, with the account's first kill.

**Status:** started 2026-11-12. Done: the save layer; the definitions; the pure rules (odds, the Breaker over time, collection and stars); the base's actions and its clock, through every gate-B and gate-D case offline and in a Run (the circuit to Watt at work, ten hours away, a rejoin); the stats resolver and one hit (`Shared.Rules.Stats`, `Hit`, `Growth`: every source adds, a hit's average matches `sim.py` to 1e-9, experience follows the pace table); Rook's combo and Haymaker with the replay (8bda266); the grey world from `Config.World`, its markers and world report, a plot each (b30467d); Lantern Row's packs and the elite (d165529); the keeper in the plot's own copy of the ring, RingExit and the shortcut (407462b); drops through the fall (1e108e2); the plain HUD and the base's interactions, as a block: the lead's and the target's cards, the Credits and Electricity pills, the dock, the Base and Voidkin screens, the Breaker's, bays' and battery's prompts and plates, the starter choice, the reveal card, damage numbers on the World layer, and a UI lint in the self-test. Self-test 130/130 at 60 fps before the HUD; its HUD and Base cases 65/65 since, a full run owed; logic 1,350. The first item tier waits: TR2 drops no item, and no doc yet says which main stat each of the fourteen slots carries, research's call. Haymaker's textured bar waits on the director's share (the Now board). Next: three fixes from the HUD's first capture (world plates hide while a screen is open; identical Ready shards share one row; rows get a second line so a shard's name isn't cut), the full run, the Shade's model (AR2), then the sim and research's verdict evidence.

## Next, not yet written

In order, each written when the one before it closes: the HUD and the reveal on the real kit (with AR3); Rook, Pip and Lyric installed (with AR1 and AR4); Lantern Row dressed (with AR5); the Lamplighter as a real fight; Regalia.
