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

**A crowd against a lone player, for research (tier 2), 2026-11-12.** Research's ask: one player's kills a minute at a crowded pack against a lone player's. This is a model built on one measurement, not a prediction of play. Measured in a Studio run (four Shades, Rook level 10, no gear, against level-10 brawlers): an ordinary falls 4.9 to 6.5 s after the lead's first hit (mean 5.7, the seed says 5), and the lead loses about 11% of its health to each. From Config: three Shades a pack, 5 s of walk between packs, a pack back 15 s after its last Shade falls, a lead down for 4 s, and healing only after 5 s out of a fight, so the walk heals nothing. A lead keeps its target, else takes the nearest (`Shared.Rules.Fight.LeadTarget`), so leads that arrive together all hit the first Shade; the two behind it may then split them. The figures are kills credited to one player a minute:

| | alone | 2 | 4 | 8 |
|---|---|---|---|---|
| moving together, all on each Shade | 7.6 | 12.6 (x1.65) | 18.7 (x2.4) | 24.6 (x3.2) |
| moving together, split after the first | 7.6 | 8.4 (x1.1) | 12.5 (x1.6) | 16.4 (x2.1) |
| parked at one pack | 5.6 | 7.6 (x1.0) | 9.3 (x1.2) | 10.5 (x1.4) |

The lone figure matches the seeds' pace (450 kills an hour, 7.5 a minute). Against a lone player on the move, the crowd earns more than half again from two players when the leads stay on each Shade, and from four either way. The 15 s wait bounds only a crowd that parks; a crowd on the move is bounded by the walk. The levers are yours: keep it, so playing together pays; make a Shade's health grow with each lead that hits it, which keeps full drops and leaves nothing to steal, so a crowd's fight lasts about as long as a lone one; or share drops past a count. My lean: keep a duo's gain, and only cap a crowd with health per lead if eight sweeping the street at three times the pace is too much.

**Research's verdict, 2026-11-12** (`build/captures/tr2/`: `pack.md`, the five sheets; the take at 30 fps, Studio's view, no sound). **Felt:** the loop holds in grey: choosing, the six-second break and the reveal are quick, the street pulls you forward, and coming home with a shard in the bag wants the next one; but the fight, the heart of it, plays between the camera and the avatar and runs long, so the middle sags. **Tier:** works, as a blockout. **The one bold thing:** the account's first kill dropping the next Voidkin's shard mid-fight, the hook that sends you home, shown today only as a small toast. **The one thing to change:** the fight's framing. Fixes, each tried in a take:

1. **The lead meets the pack ahead of the avatar** (the builder's lean, yes): engaged, it stands on the target's far side from the avatar, so the fight sits beyond the avatar, framed by the player's camera. One number in Config. Serves composition.
2. **A new account's first fights:** no down before the elite, an early pack in about 15 to 20 s (Pack 2 now 42 s and two downs; Pack 1 23.5 s). Levers in order: Rook reaches level 2 during Pack 1, a first level-up as a moment; then Pack 2 at level 1 if still long. Serves the first session.
3. **Watt's shard as a moment:** it leaps from the Shade to the avatar, and a chip ("Watt's shard: break it at home") stays until it's in the Breaker. Serves the hook.
4. **The director's notes** (`docs/decisions.md`, 2026-11-12): plots 200 studs square (from 80; the director, 2026-11-12: "base should be 200"), neighbours 48 apart (from 12), Lantern Row 44 wide (from 32), and the Festival Door on each plot to Lantern Row's gate and back (`docs/design.md`, "The world, in grey"). Judged in the next take, from the player's camera. Serves the base as a place of its own.
5. **The crowd:** keep a duo's gain; from the third lead on a Shade, each further lead adds half its health (a seed). Serves playing together without eight sweeping at three times the pace.

Accepted for the block: the reveal as a text card, the battery rising from 0 as Watt starts (it must visibly count up), the burst's white sphere. Plates overlapping: judge at the player's distance in the next take. **Not yet seen, and needed to close:** the Lamplighter's fall and a rejoin to the saved base, in a take, and one take at phone size. The item tier's main stats wait for phase 3, on the new slots.

**Research's read of the fixes, 2026-11-12** (`pack.md`'s second part, sheets 6 to 12). The five land; the loop holds better than at the verdict. 1, **framing: accepted** on its second try (sheet 11): along the avatar's facing the fight sits mid-frame, just past the avatar; an overlap now and then is the player's own steering, and the camera's job to settle when it's finished. 2, **first fights: the heal tune is taken** (tier 2, research): a lead heals 2 s after it last took a hit at a quarter of its health a second, but never while a Shade is engaged with it; into Config. 3, **the chip names the step that's next:** in the field "break it at home", at home "into the Breaker", the Breaker's plate lit until it's in. 4, **the world: accepted**, the door's landing 4 studs before the gate included. 5, **the crowd:** in logic, enough until a crowd is in a take. The battery's visible count is the builder's, before the close. **To close:** the Lamplighter's fall, a rejoin, and one take at phone size.

**Research's read of the closing takes, 2026-11-12** (`pack.md`'s third part: keeper_1 and keeper_2, rejoin_1 and rejoin_2, join_fixed; four full frames of keeper.mkv). **Felt:** the walk up, the held Challenge and the fade read as stepping into an arena; then the fight plays small and far, Rook half hidden behind the Lamplighter, until the fall's burst and the 2 s alone land the win. **Tier:** works. **The bold thing:** the 2 s alone after the fall, before the fade: the win gets its beat. **The rejoin: accepted.** Everything left came back as it should: the shards ready, Watt at work, the battery paid and refilled. The join fix holds, but for one tile (fix 2).
1, **the keeper's framing** (serves: seeing your own fighter win). The field's rule, the lead beyond its target along the avatar's facing, hides the lead behind any target wider than itself: Rook sits behind the keeper's box for most of the fight. Against a keeper, and an elite, the lead takes the target's side, so both bodies read side by side from the avatar's place. The ring sets the avatar down nearer, so the keeper stands about a third of the frame's height (it's about a fifth). Proof: a sheet of the fight with Rook clear in most tiles.
2, **nothing half-drawn at a join** (serves: the interface never lies, `docs/ui.md`, rule 4). The one tile in join_fixed where the Electricity pill and the lead's card stand as boxes goes: a piece shows whole or not at all.
The fight's length at a posed level isn't judged, as the pack says. The fall's burst is the grey stand-in; its finish comes with the keeper's own look. **To close:** these two, and the phone-size take.

**Research's read of the two, 2026-11-12** (`pack.md`'s fourth part; keeper_framing, join_whole_lift): **both accepted.** Rook now fights in plain view beside the Lamplighter, right of the frame's middle. The keeper stands about a third of the frame's height, and the 26° turn keeps the avatar out of the way. The join lifts from black onto a whole screen, with no box half-drawn. **To close:** only the phone-size take, which waits on the director's Device Emulator click.

**The phone-size take, 2026-11-12** (Faber; `build/captures/tr2/`: `phone_loop.mkv`, 118 s at 29 fps; `phone_loop_sheet.png`, a picture every 5 s; `phone_loop_full_<s>.png`, the phone alone at 5, 15, 40, 85, 95 and 115 s). Studio's Device Simulator on an iPhone 16 Pro in landscape, switched on and off again by the builder on the director's word (2026-11-12: "you are allowed to take control of my pc to put on mobile test remove it etc", then "for this session you can control whenever you need"; it covers switching the device test). The take is "Take: the loop on a new account" again, whole: 23 of 23 at 60 fps, 104 s from the white frame. It starts a new account in the Test store, as before; Pip and Lyric were given back after, at level 3. A first recording stopped at 82 s when the PC ran short of memory, and this one was taken again in full.
- **Fits at phone size:** the screens and their buttons (Choose, Close, Add, Set, Work, the dock), the reveal card, the lead's and the target's cards, the pills, the chip, the touch stick and the jump button. The notch is on the right in landscape, and the pills clear it.
- **The screen's title sits under Roblox's own top-left buttons** (5, 85 and 95 s). The Base screen starts at the top of the phone, so its "Base" sits under the menu and chat buttons. The fix is the screen kept below Roblox's top bar (its inset): mine, on your read.
- **On the plot, the plates fill the top third** (115 s): "Watt · +3.0/min" under the lead's card, "Void Breaker · idle" beside it, "Bay 2 · locked" under the pills, out to the notch's edge. The verdict's question on overlapping plates reads harder here.
- **Four facts:** taken; research's read waits.
- **Research's read of the phone-size take, 2026-11-12** (the sheet; the full views at 5, 85 and 115 s).
  - **Felt:** the whole loop plays on a phone. The cards, the pills, the chip and the screens read, and every button is a thumb's size. The plot is the one place it crowds.
  - **Fixes, the last of TR2:**
    1. **The screens below Roblox's top bar,** as you propose. Serves the title's read.
    2. **The plot's plates speak only when near or when they have news.** A plate shows only within its machine's prompt reach plus a few studs, or while it's lit with something to do (the Breaker with a shard ready, a bay that needs a worker). Elsewhere on the plot it hides. Serves "the HUD is quiet until something matters" (`docs/north-star.md`).
    3. **The battery's plate drops its count:** the Electricity pill already shows it (0.8 / 600 twice at 115 s). Up close, the plate keeps its name and its prompt. Serves one fact in one place.
  - **TR2 closes** once 1 to 3 are in and one still at the phone's size shows the plot at 115 s's spot. Phase 1 closes with it.
- **The last fixes, 2026-11-12** (Faber).
  - **1, the screens:** the screens' layer keeps clear of Roblox's top bar and the notch, as the HUD does (`UI/Layers.luau`). On a short screen, a screen shrinks to the room it has, 8 px from the room's edge, and its lists scroll (`UI/Kit/Screen.luau`). In Studio the room starts 58 px down, under the bar. The world's plates, the reveal's cover and the toasts stay full-bleed.
  - **2, the plates** (`BaseController`). A plate shows within 13 studs, measured flat, of its machine: the prompt's reach and 3. It hides again past 15, so it never flickers at the edge. The spawn stands 14 from the battery, so arriving home shows no plate. Otherwise a plate shows only while it's lit with news. My tier 1 reading of the news:
    - the Breaker: a shard in the bag, or one waiting to be opened (it lit only for the bag before);
    - a bay: open and empty while a Voidkin is free, neither leading nor working. Its plate lights too (new);
    - the battery: never.
  - **3, the battery:** its plate says "Battery", 80 wide. It never had a prompt, so its plate keeps only its name.
  - **Tests:** two new cases, the screen fitting the room and the plates near, far and with news. The avatar is stood on the plot by a new Studio-only command, `TestStandAt`. Self-test 508/508 at 60 fps, logic 1,589 (offline and in Studio), world report sound, type check 0 new.
  - **Four facts:** implemented and tested. Not visually reviewed yet: the phone still at 115 s's spot waits on the director's OK to switch the Device Simulator by computer use. Not accepted.
  - **Research's read of the two tier 1 readings, 2026-11-12:** both accepted. Near is 13 studs and lets go at 15. News lights the Breaker for a shard to break or open, and a bay that's open while a Voidkin is free. The phone still closes TR2.
- **The phone still, 2026-11-12** (Faber).
  - **The go:** the director's word in the builder's session: "u can try the device test if u wanted to else continue working". It covers switching the Device Simulator for this still.
  - **How it was taken:** the simulator was switched on (Test, Device Simulator: iPhone 16 Pro, landscape) and off again after.
  - **The staging:**
    - The save as it stood: Pip leading at level 3, Watt in bay 1, two Lantern Row shards in the bag, and the battery full.
    - The avatar was stood 5 studs from the battery on the spawn's side, facing the Breaker (`TestStandAt`), with the camera turned along its look, 15° down, as the plates case does.
  - **The files** (`build/captures/tr2/`):
    - `phone_plot_still.png`, the phone alone.
    - `phone_plot_before_after.png`, 115 s's picture beside it.
  - **What I see:**
    - The top third is clear. Two plates show: "Void Breaker · idle" lit, since there are shards in the bag, and "Battery" by its name, near. Neither overlaps the other, the cards or the pills.
    - Watt's bay and the locked bay 2 show nothing.
    - The chip says "2 shards: into the Breaker".
  - **Four facts:**
    - Implemented and tested: yes.
    - Visually reviewed: waits on research's read.
    - Director-accepted: not yet.
- **Research's read of the phone still, 2026-11-12:** accepted. The plot now speaks only where it matters: the Breaker lit because there's a shard to break, the battery quiet by its name, and the top third clear around the cards and pills. **TR2 closes,** and phase 1 with it. Director-accepted: not yet.

**Status:** closed 2026-11-12, on research's read of the phone still (above). Director-accepted: not yet. Started 2026-11-12. Done: the save layer; the definitions; the pure rules (odds, the Breaker over time, collection and stars); the base's actions and its clock, through every gate-B and gate-D case offline and in a Run (the circuit to Watt at work, ten hours away, a rejoin); the stats resolver and one hit (`Shared.Rules.Stats`, `Hit`, `Growth`: every source adds, a hit's average matches `sim.py` to 1e-9, experience follows the pace table); Rook's combo and Haymaker with the replay (8bda266); the grey world from `Config.World`, its markers and world report, a plot each (b30467d); Lantern Row's packs and the elite (d165529); the keeper in the plot's own copy of the ring, RingExit and the shortcut (407462b); drops through the fall (1e108e2); the plain HUD and the base's interactions, as a block: the lead's and the target's cards, the Credits and Electricity pills, the dock, the Base and Voidkin screens, the Breaker's, bays' and battery's prompts and plates, the starter choice, the reveal card, damage numbers on the World layer, and a UI lint in the self-test; then the fixes from its first capture: the World layer steps back while a screen is open; identical shards ready to open share one row with their count; a row's name has its own line, with its state, count or time on a quieter second one. From the second capture: rows are 50 tall so a button holds a whole 44 px target (it was 38), a button at rest carries an edge, the scrollbar has its own lane, the Base screen is 660 wide, and each plate is as wide as its longest line at the smallest phone's scale. The names are checked whole at the smallest phone's scale too (`Layers.Force`). Two Manual cases stage the base for a capture ("Capture: …", after "arrives on their own plot"). Haymaker plays its textured bar: uploaded again under the group (116379507394315, `docs/asset-log.md`), since the first upload belongs to the director's account and stayed refused after a share. Uploads now go through `tools/upload/upload_asset.py` with the group's key, on the director's word of 2026-11-12 ("yes it does we set up a key from the group for next button, let use it", covering this game's uploads), fenced as the MCP guard is: the assets endpoint only, files from `build/upload/` only, the group as creator, `expectedPrice` 0. Haymaker 11/11 and Fight 63/63 with the picture. The first item tier waits: TR2 drops no item, and no doc yet says which main stat each of the fourteen slots carries, research's call. The Shade is in (AR2): its nine meshes and three maps uploaded under the group, assembled on R6 by `tools/studio/Models/Shade.luau` into `src/storage/Shade.rbxm`, its nine clips saved in the place. The brawlers and the elite wear it (the elite at 1.35, its second mask waits on AR2); the keeper and the dummy stay boxes. A Shade wears its row's mask, its body lit in its type's colour and its mask in its own; it walks at its stride's rate, swings and flinches on alternate sides, and bursts on its Burst marker, frame 27 of the clip, from the collar, with the grey stand-in. ShadeSwipe follows its clip (tier 1): 1.1 s, the hit at 0.5, damage a second held. From the player's camera the glow barely shows: Roblox multiplies it by the colour map ([the emissive masks' announcement](https://devforum.roblox.com/t/studio-beta-emissive-masks/4034414), and seen in the engine), and the atlas paints the lit edges in the coat's dark purple, so they need a light colour under the glow (Modulo's, on the board). The clips live in the place's `RBX_ANIMSAVES`, so they last once the place is saved. The sim runs clean on the seeds (`tools/balance/sim.py`, eight sections), and a crowd against a lone player is modelled above, for research. The verdict evidence was the loop on a new account at real speed (the Manual self-test "Take: the loop"; `build/captures/tr2/`, gitignored). Research's verdict came (above), and its five fixes are in, each tried in a take (`pack.md`, its second part; sheets 6 to 12): (1) an engaged lead stands beyond its target along the avatar's facing, turned `Combat.Lead.Frame` round, so the fight sits mid-frame (beyond it from the avatar's place, the first try, put the fight at the frame's edge, since a Shade meets the lead at the avatar's side); (2) Rook reaches level 2 on its second kill (`Config.Growth.Early`), with a ring and a rising "Level N", and Pack 2 is level 1: Pack 1 21.9 s, Pack 2 24.7 to 29.3 s with one down, from Pack 1's damage carried in; (3) Watt's shard leaps from the Shade to the avatar, and a chip names the shards in the bag until they're in the Breaker; (4) plots 200 square, 48 apart, Lantern Row 44 wide, and the Festival Door (`DoorService`): a plot's door sets the player and the lead down 4 studs before Lantern Row's gate, out of the lead's leash of Pack 1 (8 studs inside, Rook charged on arrival), and its twin inside the gate sets them down on their plot; (5) from the third lead on a Shade, each further lead adds half its health (`Combat.Crowd`). The battery shows its tenth below 100, so it visibly counts up (it read 0 for the take's last 6 s). Self-test 263/263 at 60 fps, logic 1,370, world report sound. For research: the lead's heal (after 5 s, a tenth a second) is what downs Rook in Pack 2; tried live in a take, after 2 s at a quarter a second gave Pack 1 19.5 s and Pack 2 19.4 s, no down (tier 2, yours; Config unchanged). Research's read of the fixes (above) is in (36f4099): the heal into `Config.Combat` (a lead heals 2 s after its last hit at a quarter of its health a second, never while a Shade is engaged with it), and the chip names the next step, "break it at home" in the field and "into the Breaker" at home, with the Breaker's plate lit until the shard is in. The closing takes (`pack.md`, its third part): the Lamplighter's fall, with two steps posed and said so (Rook at level 14, since a bare Voidkin can't beat a keeper, and the start 25 studs short of the gate), the gate's Challenge held as a player holds it, a 40 s fight that Rook ends at 63%, the set-down beyond the ring, the shortcut home; a rejoin across a real leave of 2 min 11 s: the three shards left breaking come back ready to open, Watt still at work, the battery at 548 of 600 (the shards' 60 paid, Watt's 3 a minute added). Found by the rejoin and fixed: at a join the pills, the plates and the lead's card stood as empty boxes for about 1.2 s before the save's copy came; each now shows once it has something to say (the HUD case checks it). Research's read of the closing takes (above): its two fixes are in (`pack.md`, its fourth part). (1) Against a keeper or an elite the lead stands square to the avatar's facing (`Combat.Lead.Beside`), on the side away from the avatar's line of sight (`Fight.Aside`); the avatar arrives 14 studs from the keeper (`Combat.Keeper.Arrive`; it was 34) and faces 26° past it (`Combat.Keeper.Turn`, tier 1), since straight on at 14 its own body, near the camera, hid the keeper's lower half. Measured in the take from the camera: the Lamplighter 0.32 of the frame's height (median), Rook clear of it in 44 of 44 samples, the Lamplighter clear of the avatar in 44 of 44 (sheet `keeper_framing`). (2) Whole or not at all: the join's black holds from the client's first frame until both pills have their numbers, the lead's card its name and the frames run smooth, at most 8 s (`FadeController`), so the HUD and the plates draw beneath it; a recorded join lifts at 4.6 s, whole in every frame of the lift (sheet `join_whole_lift`); the HUD case checks the lift waited for a whole screen. Self-test 278/278 at 60 fps, logic 1,376, world report sound. The phone-size take is in (above). Next: research's read of it.

## TR3. The HUD in the world, on the kit (Faber, with AR3)

Phase 2. Research's request, 2026-11-12, written ahead so it starts the moment TR2 closes. The HUD of `docs/ui.md`, "The HUD, in the world", built for real on Modulo's kit (AR3, section 2: `build/handoff/UI/kit/`, 89 images past the content check). The reveal is its own piece, next.

**Feel line:** in a fight the screen is the fight: your Voidkin's card sits quiet in the corner, the enemy's card arrives as you engage, and every hit, crit, heal and fall reads at a glance on a phone, over the street at dusk.

**The block contains:**

1. **The kit in the engine:** the images uploaded under the group by the key, and the component library (`src/client/UI/Kit`) drawn from them: panel, button in its seven states, bar as a conduit, the six rarity frames, the gems, class icons and element marks, in Graphite Dark. The `kit.json` rows go to `src/shared/Config/`. The kit's "in use" rules hold (AR3, section 2).
2. **The lead's card:** the portrait in its rarity frame, the level on a badge, the long health bar with current and maximum inside, the thin experience bar, name, type gem, class icon. Fallen: dimmed, with the seconds until it's back.
3. **The target's card:** built like the lead's, only in a fight. The type edge's arrow, up or down, before the first hit lands.
4. **The two pills,** Credits and Electricity (stored over cap, and the rate). The tap waits for its screen.
5. **The signature's readout:** a ring at the right edge, low, that fills over the cooldown and flashes when it fires. New in the game, so it gets its own feel line at the blockout.
6. **The dock:** Voidkin and Base. Regalia and Map join with their systems.
7. **Damage numbers** in the five styles: dealt, element, received, healing, critical, plus the grey word. Roblox's own font with a stroke first (research's call, 2026-11-12: free, quick, and it reads at phone size). A drawn sheet only if play shows it falls short. The flurry's single counting number, from Held Note's fix 1, holds for all of them. The critical's digits and stroke follow the director's word to stay close to the reference, as research's table sets them (AR3, section 3, round 2). A number is placed clear of a neighbour's, and an ally's heal shows when the crest reaches it, as a hit does (research's read of Held Note's fixes, AR4, section 10).
8. **The chip and the world's plates** on the kit, with TR2's last fixes kept: a plate shows near its machine or when it has news.

**Needs from Modulo** (AR3, section 3): each launch Voidkin's cut portrait for the card (Rook, Pip, Lyric now; a silhouette for a Voidkin not yet made), and the critical number's swept stroke.

**What waits:** the reveal's ceremony; the screens (the Breaker, Voidkin, one Voidkin, the bays) on the kit, each its own piece in `docs/ui.md`'s order; event chips, which wait for their systems; a keeper's phases on its card, which wait for the Lamplighter as a real fight; sounds for the HUD.

**Checks:**

- Logic cases: the flurry's merge (a window, one number counting the real total); the type edge's arrow for each pair of types; a disabled state's reason.
- The UI lint (clipping, overlap, touch sizes, safe areas) at the smallest phone's scale.
- A phone-size capture of one fight on Lantern Row that holds a hit dealt, a critical, damage received, a heal (Lyric), the lead's fall and return, and the type edge. Then the plot with a shard ready. Long names and empty and full states, as `docs/ui.md` asks.
- Research's verdict, then the director's eye.

**The director's notes, 2026-11-13, for the blockout's fix round** (`docs/decisions.md`; said mid-build, so they're taken at the checkpoint, not before): "it need a bit more palette of colors it going great so far, but the HP of the voidkin need to be red obviously and i would like to see the hud take more inspiration of tcp 3 hud top left". Research's reading of the reference's card (`build/reference/dragon-hunter/2026-11-12_arena-normal-damage.png`), part by part, for our card in our kit's shapes:
- **Health red** on both cards, the lead's and the target's, with current and maximum in light digits inside it. The reference's is a warm orange-red.
- **The thin bar in a colour of its own,** not the health's: the reference's second bar is blue. Ours is experience; the colour is the builder's to try live, a cool one against the red.
- **The portrait is the card's biggest thing.** The face is larger than the bars' height, and the head stands above the frame's top edge. That needs a new cut of each portrait from Modulo (AR3, section 3), asked once the take shows the card's size. The bars start under the frame's right edge and run out long, ending in a slanted cut.
- **The level on a small badge** at the frame's lower corner, overlapping it.
- **A warm trim** round the bars and the frame, as the reference's gold rims. Ours can take the rarity's colour.
- **More colour across the HUD** comes from colours that mean something: health red, experience its own colour, the rarity's trim, the gems', the pills' icons (Credits warm, Electricity the kit's yellow; research's call at the fix round). The panels may take colour too: not every panel stays Graphite or Pearl, as long as the whole is well composed (the director, 2026-11-13: "not all panels should stay dark or pearly light it just need to be all well composed"). Which panel takes which palette is Modulo's choice, as the director said on 2026-11-12 (`docs/ui.md`, "One look, ours").

**The take, 2026-11-13 (Faber), for research's verdict.** All eight parts are in the game, in Graphite as the kit made them. The director's notes above wait for the fix round.
- **Part 1, the kit:**
  - 109 images are under the group, all Approved, read back by `tools/upload/read_back.py`.
  - `src/shared/Config/UIKit.luau` is written from the handoff by `tools/ui/kit_config.py`.
  - `src/client/UI/Kit` holds Skin (slices, pads, tints), Panel, Button (seven states; a disabled one says why), Bar (the conduit), Portrait and Digits.
- **Parts 2 to 4 and 6, `HudController`:**
  - The lead's card. Fallen, the portrait dims and the conduit says "Back in 3 s".
  - The target's card, shown only in a fight, with its gem and the type edge's chevron (`Rules.Hud.Arrow`).
  - The Credits pill, and the Electricity pill with its thread and "full".
  - The dock, a button selected while its screen is open.
- **Part 5, the ring's feel line** (the builder's, for this verdict): low on the right edge, the lead's signature is a ring round its class's glyph. It empties with a flash the moment the move fires, refills visibly over the cooldown, and swells once when it's ready, so a glance says when the big move comes.
  - The server says when it's ready (`FightService`, the `Ready` attribute).
  - Its numbers are in `Config.Hud.Ring`.
- **Part 7, the numbers** (`FighterController/Effects` with `Kit/Digits`):
  - The five styles and the grey word, in Builder Sans with a stroke.
  - The flurry is one counting number.
  - A number is placed clear of its neighbours (`Rules.Hud.Place`).
  - The critical sits on its swept stroke. Live in `Config.Hud.Numbers`.
- **Part 8:** the chip and the world's plates are on the kit.
- **Live for the fix round** (research's ask), all in `Config.Hud`:
  - `Card.Health`, `Card.TargetHealth`, `Card.Xp` and `Card.Trim` (the lead card's edge), read every frame.
  - `Bar.GlowReach`.
  - For example, `NL_Debug:Invoke("Tune", nil, "Hud.Card.Health", Color3.fromHex("#E2463F"))`.
  - Each was tried in a playtest and showed at once. The seeds are the take's look.
  - For the fix round: `Bar.luau` and AR3's in-use rules say red is never a bar's colour, and the director's note makes health red.
- **Fixed during the take:**
  - The bar's glow ran past both cards. It now reaches at most 8 px past its light.
  - A card read "882 / 881". `Rules.Hud.Health` now gives whole points on both sides, with its case.
  - The Breaker plate's text sat on its edge. It now has 10 px at the sides.
  - Text, Button and Digits kept their labels in weak tables, which dropped live ones, so a label missed its rescale. That was the Base screen's 11.9 px labels at the smallest phone. They now use a tag, or a strong table cleared on `Destroying`.
  - The flurry's swell check was one sample that a long frame could miss. It now reads every frame of the count.
- **The builder's calls (tier 1):**
  - A tap is authored at 52, so it renders 44 at the scale's floor (`Theme.Size.Tap`).
  - The HUD and menus sit in Roblox's safe insets.
  - `Layers.Box` lays them out in a phone's box for the lint.
- **Checks:**
  - Logic: the offline run passes 1702, and the Studio run passes 1702.
  - Self-test: the full suite passed 595 of 595 at 60 fps, on its third run. The first two each failed different timing cases, which passed alone: Lantern Burst's look, the Shade's burst marker, its alternating swings (AR4's known intermittent) and the flurry's swell (fixed above).
  - The world report is empty.
  - The UI lint at the smallest phone (568×320 under Roblox's top bar, at the 0.85 floor), in a fight with a shard in the bag, is clean: fit, size, on screen, touch, safe area, overlap, and clear of the thumbs.
- **Captures,** in the Studio window, in `build/captures/tr3/`:
  - Damage dealt and received.
  - The type edge, Down against the Lamplighter, taken with my test tints.
  - The lead fallen.
  - A dealt number and Lyric's heal.
  - A long name truncated.
  - The plot with shards waiting, its plate lit.
  - A live fight.
  - The critical's look is checked by the self-test, not caught in a capture.
- **For the verdict:**
  - In a close fight, a number's rise reaches the top band and passes under the cards and pills (captures 4 and 7). A fix could keep numbers below the top band.
  - The ring also shows out of a fight.
- **Waiting:**
  - The phone-size capture needs the director to switch on Studio's device simulator. This session has no computer use.
  - Then research's verdict, then the director's eye.
- **Four facts:** implemented; tested (above); visually reviewed by the builder, with research's pass still to come; not director-accepted.

**Research's verdict on the blockout, 2026-11-13,** from the seven captures. The motion (a number's rise, the crit, the ring's flash) is judged live at the fix round's playtest, so the round isn't held for it. **Felt:** a clean, quiet fight HUD that never crowds the street and reads at a glance, but in one grey voice. Health doesn't say health until capture 2's live red, where the card becomes a fighter's card at once. A number that rises into the top band is lost under the cards. **Tier:** works; competent once fixes 2 and 4 land, and the director's notes carry it further. **The one bold thing:** the lead card's slanted conduit, with the level badge biting the frame's corner. The card is known by that shape, and capture 2 shows it lit. Fixes:

1. **The director's notes of 2026-11-13,** as research's reading above sets them. Serves the director's word. Modulo's new portrait cut, with the head above the frame (AR3, section 3), follows the reveal's block-in. The card keeps today's portrait until then.
2. **Red, settled:** health's fill is red on both cards, and no other bar takes red. The content check passed it on 2026-11-13, on these conditions:
   - One flat warm orange-red near `#E2463F`, hard-edged, with the head and core tinted the same. Never a white-pink head.
   - The glow stays within the 8 px cap.
   - On loss the fill only shortens. A lag segment, if any, is flat, in ivory or dimmer, never a darker red.
   - Low and fallen stay length, dimming and words (AR3's condition 5), never a crimson wash or a flashing bar.
   - The red never touches the portrait, and stays apart from Mythical's `#FF2848`.
   - Before it ships, a sheet of the card at full size and 64 px over dark: full, low, empty, on each panel it takes.
   AR3's in-use rule 2 and its palette line are amended to match. `Bar.luau`'s comment follows. Serves: health reads as health.
3. **The trim takes the rarity's colour, never a fixed gold.** In-use rule 4 holds: a gold ring round a Common's frame would read as Legendary. Serves rarity's read.
4. **Numbers stay below the top band.** A number's whole life, rise included, stays under the cards' and pills' lower edge plus a margin. One born near it starts lower or rises less (`Rules.Hud.Place`, with its case). Never drawn over the cards, which hold the health. Serves: every hit read at a glance.
5. **The ring hides out of a fight:** it fades in as a fight starts, and out about a second after it ends. Its feel line, the builder's, is accepted. Serves the feel line: the screen is the fight, and out of one the ring is noise.
6. **A number too wide for its bar** takes a compact form (1.25M). The dummy's 1,254,735 crowds its bar. The builder's tier 1.

**Next:** the fix round, then research's playtest of it (the crit tuned live, the motion), on the device simulator at phone size. The street at dusk is judged once Lantern Row is installed.

**The fix round, 2026-11-13 (Faber), for research's playtest.** All six fixes are in the game. The captures and the card sheet are in `build/captures/tr3/fix_round/`. `0_card_sheet_full_and_64px.png` holds a Common full, low and fallen, the Uncommon and Rare trims, and the target full and compact, each at full size and at 64 px over dark.
1. **The director's notes:**
   - The portrait is the small frame at 1.25 (50 by 60).
   - The bars start under the frame's right edge and run out to the slanted cut.
   - The level's badge bites the frame's lower left corner.
   - The experience thread is a cool blue, `#4E9BFF` (`Config.Hud.Card.Xp`, live).
   - Today's portraits stay until Modulo's new cut.
   - Not done here: the pills' icons. Electricity in cyan needs a new bolt from Modulo, and electricity is the kit's yellow `UIKit.Charge` everywhere, so which one changes is Modulo's and research's call. The panels' palettes are Modulo's choice.
2. **Red:**
   - Both cards' health is `#E2463F`, flat. `Bar`'s new `Flat` tints the core and the head the same red (`UI/Kit/Bar.luau`, its comment updated).
   - The glow keeps its 8 px cap. A loss only shortens the fill, with no lag segment.
   - Low and fallen read by length, the portrait's dimming and "Back in 4 s".
   - The light starts 3 px clear of the portrait's frame (`Bar`'s `Inset`), so the red never touches it, at low health too.
   - Mythical's trim is its metal's `#FF8794`, not its `#FF2848` glow.
3. **The trim:**
   - Round the lead card's bars and its badge, in the lead's rarity's colour (`Config.Hud.Card.Trim`). Seeded from Modulo's frames: the glow, else the metal's light.
   - Seen on Common, Uncommon and Rare. Epic, Legendary and Mythical are seeds that no owned Voidkin shows yet.
   - The card's own edge stays Graphite.
4. **Numbers under the band:**
   - The HUD gives the band's lower edge to `UI/World.luau`: the lowest card, badge or pill showing, plus `Config.Hud.Numbers.Band` (10 px).
   - `Rules.Hud.Place` starts a number born near the band lower, so its peak meets the band and no slot lifts it back over. Its case: "a number's whole life stays under the top band".
   - The World layer holds every number and level-up plate under the band each frame, swell included.
   - The self-test: a critical born at the band, watched every frame, stays 0.5 px under it at its closest.
5. **The ring** shows only in a fight (`Config.Hud.Ring`, live):
   - It fades in over 0.2 s as the lead takes a target, stays 1 s after, and fades out over 0.35 s.
   - Hidden, it follows the cooldown, so it's right the moment it shows. Its self-test checks all three.
6. **Compact numbers:**
   - `Rules.Hud.Short` writes three figures and K, M, B or T, cut, never rounded up.
   - A health number takes it once it would pass 0.75 of its bar (`Config.Hud.Card.Room`), when the compact form is shorter. The dummy reads "1.54M / 1.54M".
- **Checks:**
  - Type check: 0 new.
  - Logic: 1731, in Studio and offline.
  - Self-test: 604/604, at 43 fps. Studio wasn't in front, and the timing cases passed.
  - The world report and the smallest phone's lint: clean.
- **Open:**
  - A Legendary or Mythical frame's crest at 1.25 stands about 4 px above the card, into Roblox's top bar. The head-above-the-frame cut needs that headroom too, so the card moves down when that cut lands.
  - The level-up's word keeps the old violet `Theme.Colour.Xp`, while the thread is now blue. Whether they match is research's call.
  - The phone-size capture still waits on the director's device-simulator click.
- **Four facts:** implemented; tested (above); visually reviewed by the builder, with research's playtest to come; not director-accepted.

**Research's pass on the fix round, 2026-11-13,** from the card sheet and a playtest of my own: Pip on Lantern Row's blockout, two packs, at the crit floor's 0.5 and then 1, put back to 0.05. **Felt:** the card now says what it is at a glance: red health, a blue thread, the portrait leading, the badge on its corner. In play the numbers rise and fade under the band, and the ring arrives with the fight and is gone a second after it. **Tier:** competent, with no obvious issue in what I saw. **The one bold thing:** the red conduit, with the badge biting the frame. All six fixes hold. The three calls:

1. **The headroom:** the top row moves down now, so a Mythical crest at 1.25 and the coming head-above cut clear Roblox's top bar by at least 4 px. The target card and the pills take the lead card's new top line, one line across the top. The band follows.
2. **The level-up's word takes the thread's blue,** `#4E9BFF`. Experience has one colour, and violet now means Epic and the Void.
3. **Electricity stays the kit's yellow,** on its pill too, so Modulo draws no new bolt. The cyan was research's reading, not the director's word. Yellow already means electricity across the kit, and the cool end is full: Rare's blue, Frost's cyan, the thread. Credits keep their warm coin.

Also, as the builder's tier 1: the trim seeds take the director's rarity colours now, live (Uncommon `#7CF0A0`, Rare `#6FB6FF`, Epic `#D29CFF`; AR3, section 4). The sheet's Uncommon trim is the untinted ladder's grey. Not caught in my captures: a critical number. Its look stays the self-test's until the phone-size pack holds one frozen (the effect kit's time scale at 0). **What closes TR3:** the three calls, then the phone-size captures on the director's simulator click, then the director's eye.

**Research on "the three calls and the trims", 2026-11-13** (captures 7 to 10):
- **The top line at 17:** accepted. The back glow's faint edge on the top bar's see-through line is a glow, not a target, and stays. On a Mythical lead, the crest's crimson and the bar's orange-red read as two things, by shape and hue (capture 8).
- **The level-up ring:** the Neon renders it near cyan, so it reads as Frost's light on the ground. It takes the thread's blue as it renders, by a deeper seed under Neon or by a material that doesn't brighten. The builder's means. The check is the ring beside a Frost hit. The word's blue stays. If it sinks at dusk on Lantern Row, fill and stroke swap: ivory digits on a blue stroke.
- **The critical** (capture 9): the gold digits on their swept stroke read at once, under the band. Its size goes from 1.35 to 1.6, so it tops the ladder by a clear step (received and heal are 1.2). Tuned live in the phone pack.
- **The ring at 0.58 under Neon, and the critical at 1.6** (captures 11 to 13): accepted. The ring and the word read as the thread's one blue, and a Frost number beside them as pale cyan. The ring's flat look goes to `docs/polish-later.md`. The dusk recheck is at Lantern Row's install. Research has nothing more on TR3 before the phone pack.

**The three calls and the trims, in, 2026-11-13 (Faber).** Captures 7 to 10 in `build/captures/tr3/fix_round/`.
1. **Headroom.** The top row has one line, `TOP` in `HudController`, at 17: the lead card, the target card and the pills. The band follows: 133.7 authored px, up from 124.7.
   - Measured on the kit's PNG, the Mythical frame's metal starts 10 points over the small frame. At 1.25 its crest clears the top bar by 5.5 authored px: 8.3 on screen in this window (scale 1.5), 4.7 at the smallest phone's 0.85. 16 would leave 3.8 there, hence 17.
   - A head-above cut gets the same room if it rises no more than the crest's 10 points.
   - The frame's back glow reaches 23.75 points over the frame. Its faint edge meets the bar's line where the bar is see-through (capture 8, Aegir's frame set on the client only).
2. **The level-up's blue.** The word and its ring take `Config.Hud.Card.Xp`, read at use, and so does the level's toast. `Theme.Colour.Xp` is gone. The ring is Neon, so it renders lighter than the thread, a pale blue near cyan (capture 10): yours to judge.
3. **Electricity** is unchanged, yellow. Modulo's note is off the board.
4. **The trims:** Uncommon `#7CF0A0`, Rare `#6FB6FF`, Epic `#D29CFF` in `Config.Hud.Card.Trim`, live (capture 7, Sable's green).
5. **The frozen crit**, ready for the phone pack. In a playtest with Pip as the lead, on the Server:
   - Run `Tune("Stats.Caps.CriticalFloor", 1)`, `Tune("Stats.Caps.Critical", 1)`, `Tune("Combat.Replay.FreezeAt", 1.2)`, then `Replay("PipCombo", 3.5)`.
   - The replay's freeze holds Pip just after the third shot, with the effect kit's time scale at 0, so the critical number holds whole under the band (capture 9, desktop).
   - Put the numbers back after: 0.05, 0.6 and 0.
6. **Checks:** type check 0 new; logic 1731 offline and in Studio; the HUD self-test 77/77 at 59 fps; world report sound.

**The ring and the critical, in, 2026-11-13 (Faber).** Research's two follow-ups above.
- **The ring** keeps Neon, seeded at `Config.Effects.LevelUp.Ring.Neon` = 0.58 of the thread's blue.
  - Neon isn't linear. On swatches at noon, the rendered hue was: 1 gives 181 to 193°, Frost 180° with a white glow, 0.65 202°, 0.6 211°, 0.58 214° (the thread's), 0.5 221° and darker, 0.35 near navy. Captures 12 and 13.
  - At 0.58 it's a saturated royal blue with no bloom: a flat flash rather than a glow.
  - An unlit SurfaceGui disc drew 204° through the haze, so it was no better.
  - Beside a Frost hit's number (capture 11, the Manual case "Capture: the level-up's ring beside a Frost hit"), the ring and the word read as one blue and the number as Frost's pale cyan.
  - Check it again at Lantern Row's dusk and night.
  - A case pins the word to the thread and the ring to its share of it.
- **The critical's size** is 1.6 in `Config.Hud.Numbers.Critical`, so the number cases see 38.4 px.
- **Checks:** HUD self-test 81/81 and the number cases 30/30 at 59 fps; logic 1731; type check 0 new.

**The phone-size pack, first part, 2026-11-13 (Faber).** Captures 1 to 4 in `build/captures/tr3/phone/`.
- **The simulator:** Studio's Device Simulator, iPhone 16 Pro in landscape: a 750×401 viewport, UI scale 1.069, touch on. The builder switched it on and off by script, on the director's word (2026-11-13: "Do it yourself for the device test you are allowed to use script"). It's off again.
- **On the test pad** with the dummy, Pip as the lead. This isn't yet the fight on Lantern Row that the checks ask for.
  1. **The top line** (capture 1): the lead card, the target card and both pills sit on one line inside the safe area. The ring, the chip and the dock are clear of the thumbs.
  2. **The frozen critical at 1.6** (capture 2), by the recipe above: "561" in gold on its stroke, whole under the band.
  3. **Found: the World layer's clamp was never written.** A plate marked `World.Below` was marked and nothing more, so the level-up word rose over the Electricity pill (capture 3).
     - **The fix:** `World.luau` now pushes a Below plate down by whatever crosses the band, its height read with the number's swell (its UIScale) counted. The effect kit's timed step runs at `BindToRenderStep` Camera+1, before the plates are placed at Camera+2.
     - **On the phone:** the worst frame of a number is 0.2 px over the band, and of the level-up word 1.0 px, which is pixel rounding. The word sits under the band (capture 4).
     - **A case covers it:** "HUD: a number born at the top band stays under it its whole life" now also fires a level-up and watches its word every frame.
- **For research:** with the camera close in, the clamped level-up word and a number also clamped at the band can overlap (capture 4). It's rare in play. Not changed.
- **Checks:** on the phone, HUD self-test 83/83 at 59 fps and the number cases 32/32. Logic 1731 offline; type check 0 new.
- **Still to take at phone size:** the fight on Lantern Row with damage received, a heal (Lyric), the lead's fall and return and the type edge; then the plot with a shard ready; long names; empty and full states.
- **Still to run:** the desktop's whole self-test on the new clamp.

**The phone-size pack, second part, 2026-11-13 (Faber).** Captures 5 to 15 and two recordings in `build/captures/tr3/phone/`. The simulator was set up as in part one, switched on and off by script, and it's off again.
- **The fight on Lantern Row** (`row_fight_lyric.mkv`, 52 s): the grey street's Pack 3 (Brawlers, level 3), with Lyric leading at level 3. For the take, the critical's floor was tuned live to 0.3 (`Stats.Caps.CriticalFloor`), so criticals come often.
  - Capture 5: a hit dealt and damage received. Capture 6: a heal ("+12", green) beside a gold critical ("69").
  - The fall, forced with `FightHealth 0` once the pack was down (7, 8): the card dims, "Back in 4 s" counts down to 1, and she's back whole at the avatar's side.
- **The type edge** (`row_type_edge_watt_kirra.mkv`): before his first hit on a Brawler (Strength), Watt (Endurance) shows a down arrow (9). Kirra (Agility) shows an up arrow (10). Lyric (Technique) has none, as the ring says.
- **A fall in the middle of a fight** (11): the target's card leaves with the lead, the Brawler walks home whole, and the card comes back with its arrow when Kirra does.
- **The plot with a shard ready.** Found: at the arrival, the Breaker's plate, lit with "Ready to open: 1", stood under the lead's card (12). The World layer lies under the HUD, and a machine's plate wasn't kept under the top band as the numbers are.
  - **The fix:** `BaseController` marks each machine's plate `World.Below`, part one's clamp. At the same arrival, the plate now sits just under the card (15), and the same with the camera turned to put the Breaker high (13).
  - **A case covers it:** "HUD: a machine's plate with news never hides under the top band". It turns the camera so the Breaker's point is halfway up the band, then reads the plate's top: 0.8 px under the band on the desktop, 0.6 on the phone. On the code before the fix, the same measure read 104.6 px over it.
- **Full and long** (14): Ironhymn at level 60 (the roster's widest name, Epic frame) against the Lamplighter at level 60, with Credits at 123,456,789 and the battery full. The top line holds, each piece apart. The lead's health takes its compact form ("18.1K / 19.9K") while the target's wider bar holds "119,623 / 153,478" (fix 6, by design).
- **Empty** (15): Credits at 0, an empty bag (so no chip), no worker, and the battery at 480 / 600 with "+0.0/min". Not taken: a new account's HUD, with no lead and an empty battery. It takes a wipe of the Test account, whose Lyric and Pip feed cases.
- **For research:**
  - A zero rate reads "+0.0/min".
  - On the phone, the Base case "the plot's plates speak only near their machine…" fails two "far off" checks. Its camera aim doesn't hold under the phone's default touch camera, so the Breaker's point falls off screen. With `DevTouchCameraMode` set to Classic it passes 28/28 on the phone, and it passes on the desktop. The game's plates aren't at fault. Not changed.
- **The Test account after:** put back as it was, except that Ironhymn (k8, level 60) stays in the collection, five Voidkin have one copy more, and Credits are 7,772.
- **Checks:**
  - On the phone: the HUD cases 91/91 at 59 fps.
  - On the desktop: the whole self-test 618/618 at 55 fps, part one's clamp included.
  - Logic 1731 in Studio and offline; world report empty; type check 0 new.

**Research's read of the phone pack, both parts, 2026-11-13,** from captures 1 to 15 at the iPhone 16 Pro's size. **Felt:** on a phone the top line reads at a glance: Lyric's red health, the Brawler's, Credits and the battery, each apart and inside the safe area. The heal's green "+12" and the critical's gold "69" sit side by side and say what they are, a fall dims the card and counts "Back in 4 s", and the type edge's arrow is there before the first hit. **Tier:** competent. **The one bold thing:** the red conduits across the top, the lead's and the target's, one line the eye reads like a fighting game's. Both of the builder's catches are good: the level-up word and a machine's news plate now stay under the band. The full and long case holds (Ironhymn at 60 against 119,623 / 153,478), and so does the empty one. One fix:

1. **A level-up word and a number clamped at the band stack, not overlap** (capture 4: "Level 6" across "1,234"). It's the block's own rule ("a number is placed clear of a neighbour's", point 7). The word counts as a neighbour. Rare, so it rides with the next touch of `World.luau` and doesn't hold the director's look.

For later (`docs/polish-later.md`): the type edge's arrow is about 7 points tall on the phone, readable once you know it, small for what it decides. For the builder: the Base case that fails two checks only under the phone's touch camera could set its own camera mode, so every case passes on both. That's your call. **Next:** the director's eye on the HUD.

**The lead card, the director's redesign, in, 2026-11-13 (Faber).** At the director's eye, the lead card was redrawn from mocks the director picked from in the builder's session. The words, all 2026-11-13, covering the lead card only:
- "the color let make it something mature so gradiant black or see if u can make it diff", then "let go with midnight": a lacquered black gradient with a navy undertone.
- Both bars a little thinner (health 17 points, experience 6.5), in the Ember colours, lit at the top and deep at the foot.
- "the black background of xp and hp should be a bit transparent not by much": the empty slots at 80%.
- The text in Builder Sans; the artifacts round Pip's portrait gone.
- "once it done let continue".

What was built:
- **The art.** `tools/blender/lead_card_art.py` draws 26 kit images into `build/handoff/UI/hud/lead_card/`, with `lead_card.json`, a review sheet for the three Voidkin and one for the stand-in's rarities. It uses Modulo's toolkit and portrait renders, worked in Modulo's area at the director's ask; Modulo was told, and re-cutting a face stays Modulo's.
- **The pieces.** The housing and its rim, the tab under the name sliced to fit it, the two lights, a face, frame and head for each Voidkin, the stand-in's face in six rarities, and the badge. The rims are white, tinted the rarity's colour (`Config.Hud.Card.Trim`).
- **The code.** `tools/ui/kit_config.py` writes the images and the card's geometry (`UIKit.LeadCard`). `src/client/UI/LeadCard.luau` lays the card. `HudController` uses it: its old lead card is gone, and so is `Config.Hud.Card.Health`, since the lights carry their own colours.
- **The health text.** It is set tight on the lead card ("1,466/1,466": `Rules.Hud.Health`'s `tight`), with four logic cases.

Two engine lessons, for research's handbook:
- A sliced image whose middle runs its full height draws only its top third, stretched. The lights and the tab came out pale until each cut kept a middle of half a point (`across` in the script).
- A soft shadow that is still above zero at an image's edge shows in game as a faint box. Each shadow now fades to nothing by 0.9 of its image's pad.

The three images that changed for the second lesson passed the content check again and were uploaded again. The light and tab images didn't change, only their slice numbers.

**Captures** in `build/captures/tr3/lead_card/`:
- desktop, full health;
- 42% health;
- fallen ("Back in 2 s", the portrait dimmed);
- the iPhone 16 Pro on the device simulator, switched by script and off again.

**Checks:**
- Content check PASS on the 26 images, and on the three re-cut.
- 29 uploads, all Approved and the group's (read back).
- Type check 0 new.
- Logic 1735/1735, offline and in Studio; world report empty.
- The HUD cases 91/91 at 56 fps.
- The whole self-test 618/618 at 55 fps.

**Open:**
- A UDim2 offset rounds to a whole pixel, so a layer may sit up to 0.6 authored px from its drawn place. None shows in the captures.
- The uncut renders stay in `lead_card/renders/` out of git until research's pass, then go.

**Research's pass on the lead card, 2026-11-13,** from the two sheets and the four captures. **Felt:** the card has grown up. A lacquered midnight housing, the ember health lit along its top, and Pip's hat rising out of the frame, so the Voidkin stands in its card rather than sitting behind glass. Fallen, the face dims and "Back in 2 s" sits in the empty slot, plain to read. **Tier:** competent, near the top of it. **The one bold thing:** the head breaking the frame's top edge, which makes the portrait the card's biggest thing, as the reference does it. The type gem biting the frame's corner where the bars begin ties the face to the bars. On the phone the tight "1,466/1,466" fits, and the hat clears Roblox's bar. One fix, before the director's look:

1. **The target's card is built like the lead's** (this TR, point 3: "built like the lead's"), in the same housing, light and type. Today the top line holds two looks side by side: the lead's midnight and ember beside the target's Graphite card from before. It serves a HUD "all well composed" (the director, 2026-11-13), and the director's words for the lead card aren't widened, because point 3 already asks for it. Then one full-frame capture at phone size, in a fight, with both cards and the pills, for research's read of the whole.

The renders can go. Both engine lessons go to the handbook (research's).

**The target's card, built like the lead's, in, 2026-11-13 (Faber),** research's fix 1.
- **The art.** `lead_card_art.py` draws the target's blade (`CardTargetHousing`: Midnight's body and lacquer, the health slot only, at 80%) and its rim. The tab's rim was re-cut: its line ran along the tab's foot, under the name. Review sheet: `target_card_sheet.png`.
- **The code.** `src/client/UI/TargetCard.luau` lays it from the lead's parts, in `UIKit.TargetCard`'s points (`kit_config.py`): the blade sliced to its length, the lead's tab cut to fit the name and level, the Ember light, the type's stud on the blade's left end, Builder Sans. `HudController`'s old target card is gone, with `Config.Hud.Card.TargetHealth`. The rims and the stud take `Config.Hud.Card.TargetTrim`, a neutral grey, since a Shade has no rarity (the builder's seed).
- **The level.** "maybe we should make the level text a tiny bit brighter and in yellow style" (the director, 2026-11-13). Read as the target's "Lv 30", the one level drawn in grey: `Config.Hud.Card.Level`, a soft gold, #F2CB62. The lead's badge number takes the same gold, since the director left it to the builder ("whatever best", 2026-11-13): one colour for a level on both cards, while experience keeps its blue. Capture `round3_levels_gold`; the HUD cases 91/91.
- **Captures** in `build/captures/tr3/lead_card/`: `round3_target_desktop`; `round3_target_level` (the phone, enlarged); `round3_phone_fight`, the full iPhone 16 Pro frame in a fight with both cards and the pills, for research's read of the whole.
- **Checks:** content check PASS on the three images; 3 uploads Approved and the group's (read back); type check 0 new; logic 1735/1735, offline and in Studio; world report empty; the HUD cases 91/91 at 56 fps; the whole self-test 618/618 at 54 fps. The renders are deleted.

**Research's read of the whole, 2026-11-13,** from `round3_phone_fight` at the iPhone 16 Pro's size. **Felt:** the top line now speaks one language. Pip's card and the Brawler's carry the same midnight blade and ember light, level with each other, and the pills sit beside them in the same dark. The eye goes face, red, red, then the numbers in the street. **Tier:** competent. **The one bold thing:** the two ember conduits across the top, yours and its, read like a fighting game's. The soft gold "Lv 30" is the director's word, and it reads. No fix. A damage number crossing the Breaker's plate is the staging: a fight at the plot. On Lantern Row no machine plate meets a fight. Research's pass on TR3 is given. **Next:** the director's look in game.

**Status:** started 2026-11-12 (Faber). The three calls, the trims, the ring and the critical are in, 2026-11-13. The phone pack's first part and the clamp fix are in, 2026-11-13. The phone pack's second part and the machine plates' clamp are in, 2026-11-13. Research's read of both parts given, 2026-11-13. The lead card's redesign, at the director's eye, is in, 2026-11-13. Research's pass on it given, competent; its fix, the target's card, is in, 2026-11-13. Research's read of the whole phone frame given, no fix: research's pass on TR3 given, 2026-11-13. **Closed, 2026-11-13.** The director, the same day: "for the premium hud my approval is not required simply do your best i will check everything later on keep going". It covers the HUD: the director's look in game comes later, as a check, and any rework it names is a new piece.

## TR4. The reveal's ceremony, in the engine (Faber, with AR3)

Phase 2. Written by the builder, 2026-11-13, when TR3 closed, from AR3 sections 4 and 5; research amends it. The game's signature moment (`docs/design.md`, "Shards and the Void Breaker"; `docs/ui.md`, "The reveal"), built to Modulo's `build/handoff/Reveal/parts/reveal.json`. The art it's judged against is `build/handoff/Reveal/art/`, research's pass at competent.

**Feel line:** AR3, section 4, as Modulo answered it and research accepted it. The beats and each rarity's times: AR3, section 5.

**The block contains:**

1. **The parts in the engine:** the 28 images uploaded under the group, the shard's 8 meshes published from Studio (`ModelAssembly.PublishMesh`), and Rook's, Pip's and Lyric's Reveal clips saved in the place the way the fight's clips are.
2. **`Config.Reveal`,** written from `reveal.json` by `tools/ui/reveal_config.py`, with the ids. Research tunes its numbers live.
3. **`Rules.Reveal`,** pure Luau: the times, the curves, the leak's pick, the split's flash, the name's size, the skip.
4. **The stage** (`src/client/UI/Reveal`): `reveal.json`'s 16 layers, laid each frame from the time since the tap. It holds the shard in a ViewportFrame on its pose, with the leak over it. The figure is its Voidkin's body on its Reveal clip, or the grey stand-in on Rook's clip for a Voidkin not yet made. Then the colours' run, the strike, the name's slam, the split's flash and the kick. Full screen on the Overlay layer, the frame's right wing inside a phone's safe area.
5. **The break wired in:** `BaseController.Reveal` plays it after the server's yes, then the card that's there today. The skip opens at 1.0 s and lands on the held frame. The bodies reach the client through a copy the server puts in `ReplicatedStorage`.
6. **Sounds,** to research's cues, from Roblox's library, each logged.

**Research's sound cues, 2026-11-13.** The reveal is heard hundreds of times, so a Common is short and quiet, and the two peaks belong to the rare ones. Each cue's weight sits above 250 Hz, or a phone loses it (`handbook/visuals/audio.md`, "UI sound"). All cues go through one `Reveal` sound group, and the world and its music duck 6 dB while it plays. Levels are relative to the loudest, the Legendary split at 0 dB. Each cue lands on its beat's frame.

| Cue | When | Level | The character |
|---|---|---|---|
| Crack | each seam, 4 times, 0.03 to 0.34 s | -14 | a dry, short crystal crack, one source, each seam a semitone higher. Every rarity |
| Rung | each new colour of the leak's climb | -12 rising to -6 at the top rung | one clean glass chime, short tail (about 0.4 s), pitched up a step per rung. Not at Common, which doesn't climb |
| Breath | the breath, Epic up | -10 at its peak | an air swell drawn inward (a reversed shimmer), cut dead about 0.12 s before the split, so the split lands out of silence |
| Split, low | the split, Common to Epic | Common -12, Uncommon -10, Rare -8, Epic -5 | a glassy pop with a short sparkle, one source, deeper and longer as it climbs |
| Split, high | the split, Legendary and Mythical | 0 | a full burst: a bright shatter over a body in the low mids, tail about 1.5 s. Mythical plays it a touch lower (speed 0.9) |
| Strike | the ram's Knock | -6 | the Voidkin's own: for Rook, his Haymaker strike, shortened. Each Voidkin's comes with its Reveal |
| Name | the name's slam, one frame after | Common -4 to Mythical -2 | a heavy metal stamp, short ring, no tail over 0.3 s. At Common it's the loudest thing, so the beat still lands |
| Glint | the light along the rule | -14 | a short high shing |
| Bed | from the colours to the card, Rare up | -18 | a soft held shimmer pad, no melody, faded in over 0.3 s and out over 0.4 s into the card |

Cut from the builder's list: the window opening. It falls 0.13 s after the split, inside the split's tail, and a cue there would blur the two. **The skip** stops every cue and plays the name's slam on the held frame, so a skipped reveal still lands. The levels are seeds, tuned by ear in the engine. Research's verdict in motion includes the sound.

**What waits:** the card after the reveal, on the kit, with the Voidkin screens; the shard at the world's, the bag's and a chamber's sizes; each Voidkin's own Reveal as it's made; the clips' upload for a public build (no clip is published yet: `Config.Animations.Ids`).

**Checks:**

- Logic cases: each rarity's times are `reveal.json`'s; the skip is shut before 1.0 s and open after it, at every rarity; the leak's two sets always share 1; no name is set wider than 379.2 points.
- Self-test cases:
  - A break at each rarity plays through to the card.
  - A tap before 1.0 s does nothing; a tap after it lands on the held frame.
  - A refused break shows no ceremony.
  - The frame stays inside the smallest phone's safe area.
- The engine beside the art at `reveal.json`'s four moments per rarity, as `reveal_parts_compare.png` lays them.
- The frame rate through a Mythical, on desktop and on the phone's simulator.
- Research's verdict in motion, then its artistic pass.

**Time named:** about 10 hours. It's the signature piece, and the leak is the hard part.

**Built, 2026-11-13 (Faber).** The block's six items are in. The builder's calls on the way, each tier 1:

- **The stage fits and centres in the screen's safe area,** and the room behind still fills the screen. On the phone simulator (an iPhone 16 Pro, 750 by 401), the stage filled the height, so from Rare up the frame's top stood up to 26 px in Roblox's top-bar strip. Fitted to the safe area, it's 1% smaller there, and the desktop doesn't change.
- **A sound starts on its frame.** A new Sound waited 0.28 to 0.35 s to load, even with its file cached, so the cracks bunched and the split came about 0.3 s late. The client now keeps one loaded Sound per cue and plays clones of it (`FighterController/Sounds`, the bank). Every cue now starts within one or two frames, measured. The fight's cues go through the same function, so Haymaker's strike was late by about as much before this: the director's ear on it (the board's "Waiting on the director") is best given now.
- **A cue on the screen is levelled by its whole gain** (`Rules.Sound`): no file plays past twice its own level. A cue in the world keeps its bounds. The reveal's cues sit well under the reference, so quiet library files serve without lifting their noise. A case checks every scheduled cue at every rarity.
- **The low split, deeper and longer as it climbs:** played at speed 1.12, 1.06, 1 and 0.94 from Common to Epic (`Config.Reveal.Sounds.SplitLow.Speed`), a seed for the ear.
- **The stamp:** research's "no tail over 0.3 s" chose the metal slam (40 dB down by 0.22 s) over the louder anvil, which rings to 0.37 s. The sounds and their alternates are in `docs/asset-log.md`.
- **Known, for research's verdict:** the colours run top to bottom, where the art spreads them out from the ram's head, about 8 frames apart at most. Pip and Lyric have no strike sound until theirs come with their Reveals.

What the checks found:

- **Logic:** 2249 cases pass, offline and in Studio. Among them is the sounds' schedule at every rarity: each cue on its beat, its level, the climb.
- **Self-test:** 688 of 688 on the desktop, at 60 fps. TR4's five cases:
  - Each rarity's card comes within two frames of `reveal.json`'s Card, and every scheduled cue sounds.
  - A tap before 1.0 s does nothing. One after it lands on the held frame, with only the stamp sounding. A tap inside the card's hold keeps the card, and one past it closes it.
  - A refused break shows nothing and spends nothing.
  - The frame, the window, the name and its rule sit inside the safe area at every rarity, on the desktop and on the phone simulator.
  - Each Reveal clip's strike marker is where `Config.Reveal.Strikes` says.
- **The frame rate through a Mythical:**
  - Desktop: 60 fps, the worst frame 19 ms.
  - Phone simulator: 45.9 fps, against 48 idle, the worst frame 25 ms either way. The simulator caps its own client, so the 50 fps line is NOT VERIFIED on a phone. The reveal costs about 2 fps under that cap.
- **Beside the art:** all six rarities at the four moments (`build/scratch/faber/reveal/compare_<rarity>.png`).
- **The world report** is empty. The place is saved, version 256.
- **For research's verdict in motion,** at phone size in 0.2 s steps: `build/scratch/faber/reveal/sheet_myth.png` (0.2 s to the card) and `sheet_common.png` (0 s to the card).
  - The sounds' schedule is `Rules.Reveal.Cues`, and their levels are `Config.Reveal.Sounds`.
  - The sounds stay provisional until the director's ear.

**Research's verdict, 2026-11-13,** on the 0.2 s phone sheets and `compare_<rarity>.png`, with `ga-fresh-eyes` blind beside it. Steps of 0.2 s can't show a stamp or a crack, so this is the read of the beats. The motion and the sound come with fix 2.
- **Felt:** on a Mythical, the shard sits in the dark while its light climbs through green, blue and purple. It holds on gold long enough to let you think "Legendary", then turns red. A white flash, a black shape in a burning spiked frame, and the fighter lit with its name across the left. A Common is quick and quiet, as the ladder wants. The engine matches the art at all six rarities, the name a touch bolder, which is right on a phone.
- **Tier:** competent.
- **The one bold thing:** the climb, with the gold hold before the red. Fresh eyes named the cut from the flash to the dark shape in the burning frame.
- **Fresh eyes, blind:** competent. The light tells you your luck, but at Mythical the shard's break is hidden under the white, and the name reads as a title card more than a stamp.
- **Accepted:**
  - The colours running top to bottom: 8 frames is under the eye at full speed.
  - The stage fitted to the safe area.
  - The sound bank.
- **Fixes:**
  1. **The top flash is never pure white.** Legendary's and Mythical's flash goes to their own light (gold-white, red-white) at about 0.85, not 1, so the split's pieces show through it and a dark room isn't blinded. This serves the break, which fresh eyes lost, and `docs/research/vfx-reference.md`, rule 3 ("never pure white"). Faber, with Modulo's eye on the colour.
  2. **A take in motion with its sound,** a Common and a Mythical at phone size, recorded with the game's audio. It's for the name's landing, the shard's answer at each rung, and the nine cues. If the name still lands as a title card, it gets a stamp's motion there: a scale down onto its place over about 4 frames, with the slam on the frame it lands.
- **For the card, when it's built with the Voidkin screens** (under "What waits"): it never covers the name. Today's card sits over its first letters.

**The fixes, 2026-11-13 (Faber).** The material is in `build/captures/tr4/`. Both takes are at phone size (the simulator's iPhone 16 Pro), with the game's own sound.
1. **The top flash in its own light.** Legendary goes to gold-white `#FFF0C8` and Mythical to red-white `#FFDCE0`, at 0.85 (`Config.Reveal.WholeFlash`; Common to Epic keep their round white flash). In the frames, the split's pieces show through it at both rarities (`mythical_flash_frames.png`, `legendary_flash_1.31_1.36.png`). Modulo's eye on the two colours is asked.
2. **The takes with sound:** `take_mythical_sound.mp4` and `take_common_sound.mp4`.
   - **The name:** in the first Mythical take it landed as a title card, one picture at 1.7 times, then down. It now has a stamp's motion (`Config.Reveal.Stamp`): it falls onto its place over 4 frames, faster each frame, lands on its time a touch under its size with the slam, and settles. The new take shows it over three pictures (`mythical_name_stamp_frames.png`). This departs from `reveal.json`'s slam curve, which eased into the landing over 3 frames; Modulo is told.
   - **The sound, by numbers:**
     - The onsets follow the schedule one for one: four cracks, five rungs, the breath, the split, the strike, then the glint and the slam.
     - Each comes 0.04 to 0.09 s after its frame, about 0.06 on average. That's this PC's audio path, an estimate good to about 0.03 s. A take puts its own 0.116 s of lag on the sound, measured on a clip whose flash and beep are in step, and that is taken off. About 0.06 s late is inside what people accept as in step.
     - The mix touches full scale on 7 samples in the Mythical: the rungs' attacks, the strike and the slam. Around the split, the strike and the slam it sits near −12 dBFS RMS. The levels are research's call; nothing changed.
3. **Checks:** logic 2,258 offline and in Studio; the reveal's self-test 72/72 at 54 fps on the desktop; the type check clean. New cases: the whole-screen flash is never white and never above 0.9; the name falls over three to five frames, faster each frame.

**Research's pass, 2026-11-13,** on both takes, the three frame sheets and the takes' sound measured (ebur128, the waveform).
- **Felt:** the Mythical's flash goes red-white with the shard flying apart inside it. The burning frame fills with light, the dark shape comes, and the name drops onto its line with the slam. The Legendary's gold does the same.
- **The sound:** it has the shape the cues asked for:
  - the cracks and the rungs as separate spikes;
  - the breath held, then cut just before the split;
  - the split's wide attack with its long tail;
  - a gap, then the strike and the stamp;
  - the bed fading under the card.
- **Tier:** competent.
- **The one bold thing:** the break seen through the red-white flash. Fresh eyes' lost moment is now the best one.
- **Both fixes are met.** The stamp's fall is right. It departs from `reveal.json`'s eased landing, and a stamp should hit, not settle in.
- **The level, corrected the same day:** research read −9.7 LUFS and a +1.4 dBFS peak off the take and asked for the `Reveal` group 3 dB down. Faber showed the take can't carry that measure. The PC's own sound processing boosts and compresses the loopback: a −30 dBFS tone comes back at −19, and 3 dB down moved the take by only 1.4 LU, still touching full scale. So the number is withdrawn and the fader stays at 1. The real measure is an offline mixdown of the cues' own samples at their scheduled times, volumes, speeds and fader, for loudness and true peak. It's built in AR8 A, where the fight's cues need the same measure, and it sets the reveal about 3 to 6 LU above the fight.
- **About 0.06 s of audio lag:** accepted, inside what reads as in step.
- **Research's pass on TR4 is given.** The sounds' character and the final levels stay provisional for the director's ear. Pip's and Lyric's strikes come with their Reveals.

**Status:** built 2026-11-13 (Faber), from TR3's close at 12:54 to about 14:30. Research's verdict on the beats is given (competent, two fixes). Both fixes are in, with the takes with sound, to 14:45. **Research's pass is given, 2026-11-13: TR4 is closed.** The level check moves to AR8 A, and the director hears the sounds later.

## Next, not yet written

Written: TR8, Lantern Row dressed with its night, and TR9, the Breaker screen (below). Still to write, each when the one before it closes: the Lamplighter as a real fight; Regalia.

## TR7. Rook, Pip and Lyric installed (Faber, with AR1 and AR4)

Research's entry, 2026-11-13, at Faber's request. Phase 2's "Rook, Pip and Lyric finished and timed" (`docs/production-plan.md`). It comes first in the queue, before TR5 and TR6.

**Feel line:** on a phone, in a pack fight on Lantern Row, each of the three fights in a way you can see. Rook plants and hammers. Pip skips back out of reach and lobs fire. Lyric keeps her distance and sings the pack back. The fight always sits clear of your own avatar, right of centre, so every landing reads.

**The block contains,** in this order, each judged in motion at phone size before the next:
1. **The framing,** in grey, from Faber's three variants. Each is judged in a pack fight and a keeper's try.
   - **A. A shoulder camera in a fight:** an ease of about 2.5 studs right and 1 up while the lead is engaged.
   - **B. Geometry only:** `Lead.Frame` 70 and `Keeper.Turn` 40.
   - **C. The keeper holds the ring's middle,** plus A or B for packs.
   - **The checks:**
     - the avatar never covers the lead or its target;
     - Haymaker's landing reads as the slam (AR8, B5's final);
     - the hang clears the Target card;
     - the pole's rock reads (AR7);
     - the keeper's lantern and look down share a shot (AR8, the keeper's signature).
   - **For A:** the ease is gentle, about 0.4 s. It eases back only after the fight has been over about 1.5 s, so a lead stepping in and out never makes the camera swim. It never takes the player's own drag of the camera.
2. **The skip back,** for Pip and Lyric, through `/ga-action`, as designed in `docs/design.md`, "Combat". In the block, the body plays Modulo's block clip, or a held pose if it isn't in yet. It closes on its balance check: ten runs with the skip and ten without, within 10%.
3. **The three passives,** from `docs/roster.md`, short and simple (the director, 2026-11-13), each with a grey cue readable at phone size where it has one. The numbers are seeds: tier 2, research's, tuned by playing, with Faber's view in his row.
   - **Rook's Second Wind:** below 30% health he takes 20% less damage. Its cue is a faint shell round him while it holds.
   - **Pip's Kindle:** his combo's third shot adds Fire damage worth 40% of that shot, as its own coloured number. Its cue is the lantern flaring on the shot.
   - **Lyric's Tempo:** Held Note's cooldown is 20% shorter. It needs no cue: the song comes round more often.
   - The three must leave the balance check within 10% of each other's time to clear Lantern Row's first pack at their level. A passive can't close a gap in the combos, so the band is settled at the timing (part 4), with the combos open (research's verdict, 2026-11-14).
4. **Timed:** each lead plays its whole kit in real fights, not the replay: combo, signature on its cooldown, passive. Haymaker's hitstop and camera numbers get set by playing (B5's "Not done").

**Waits:**
- the skip clip's finish (its block clip is Modulo's, made now: `docs/design.md`, "Combat");
- the passives' art;
- the states, Burn and Shock included (with the Lamplighter as a real fight);
- Rook's evolution;
- the finish pass on the signatures (`docs/polish-later.md`).

**Verdicts:**
- the framing's blockout;
- the skip back's blockout (`/ga-action`);
- the passives together;
- the final, from QA's pack once QA has joined, else Faber's takes, with fresh eyes on the framing.

**Order in the queue:** first. **Time, forecast:**
- the framing, about 1 hour;
- the skip back with its check, about 2;
- the passives, about 1.5;
- the timing, about 0.5.

**Research's verdict on the framing's blockout (2026-11-13; `build/captures/tr7/`, the sheets and the mp4s, Rook leading, phone size): A for every fight, with `Keeper.Turn` 40.**
- **Felt:**
  - Before, the fight happens behind your own back: the keeper stands at the avatar's right shoulder, and a pack climbs over the avatar's right side.
  - With A and Turn 40, the avatar steps to the left third, and the keeper's fight stands on its own in open floor right of centre. The fall's pole and lantern stand alone against the sky.
- **Tier:** competent in the keeper's try. Works in a pack: at 2.5 studs the avatar still overlaps the pack's left edge in about half the frames.
- **The one bold thing:** the keeper's fall in row 5, a lone pole against the sky with nothing in front of it.
- **Picked:** A plus `Keeper.Turn` 40. `Lead.Frame` stays 45.
  - B loses: Frame 70 spreads a pack round the avatar and puts one between it and the camera.
  - C loses: it's no clearer than A, and it changes the keeper's character, which is no framing fix's to change.
- **Fixes, for the build:**
  1. **The offset is a Config number, tuned by playing in a pack.** Try 3.5 studs right beside 2.5, and keep the smaller one that leaves the lead and its target uncovered in nine frames of ten. The 1 up stays.
  2. The 0.4 s ease, the 1.5 s hold and the player's free drag stay as tried. The final judges them in motion.
- **Carried to the build's take:** Haymaker's landing as the slam, the hang against the Target card, the keeper's look down. The keeper's hat under the Target card is TR5's to fix, and so is a level-up banner over a keeper's fall.

**The build and its take (Faber, 2026-11-13, 21:58 to 22:20).**
- **In the game:**
  - `Config.Combat.Shoulder` (Right 2.5, Up 1, Ease 0.4, Hold 1.5) and `Keeper.Turn` 40.
  - The rule `Rules/Fight.ShoulderShare` has a logic case.
  - `FighterController/Shoulder.luau` sets `Humanoid.CameraOffset` before the camera each frame, so the drag stays free. A self-test case checks that it eases in, holds, and eases back.
  - Checks: type check 0 new; logic 3897/3897; self-test "Camera:" 10/10 at 60 fps.
- **Fix 1, the offset, measured in pack fights.** The offsets took turns every 1.1 s within one fight, so each was judged on the same fight. "Uncovered" means the avatar's body hides at most a tenth of the lead's and the target's points, by rays from the camera.

  | Where the avatar stands | Right 0 | Right 2.5 | Right 3.5 | Right 4.5 |
  |---|---|---|---|---|
  | 14 studs from the pack's middle | 32/35 | 29/30 | 25/26 | 27/27 |
  | In the pack, 8 studs | 15/45 | 19/45 | 14/41 | 14/40 |

  - In the pack, raising the camera instead (Up 1, 2, 3 at Right 2.5) does no better: 14/32, 15/36, 13/26.
  - A target straight ahead at 8 studs needs about 7 studs of offset to clear the body (geometry), so there it's the avatar's place that covers the fight, not the camera's.
  - **2.5 stays:** 3.5 buys nothing measurable. This in-the-pack case is likely what the "about half" in the verdict saw (`build_pack_close8.jpg`).
- **The take,** in `build/captures/tr7/build_*`, phone size, Rook leading:
  - **Haymaker's landing:** in a real pack fight, the square drops through two frames and lands on the target's feet on Strike, with the target flashed white. It squashes, with its bars on the floor, on the next frame (`build_pack_landing.png`). To me it reads as the slam.
  - **The hang doesn't clear the card.**
    - On a Shade, the Target card covers the square's lower half from its forming to its drop, about 0.27 s (`build_pack_hang.png`).
    - Against the keeper, the square's foot sits Clear over the keeper's top, so it hangs above the frame and only its foot shows (`build_try_hang.png`).
    - A Shade's head leaves no room between it and the card, so the square's height isn't the lever.
  - **The keeper's look down:** the lantern raised in open sky over Rook and the hat tipped down toward him, just under the card, share one shot (`build_try_lookdown.png`). The signature was forced in a try: it has no place in the keeper's own fight yet. The card sits between them through the lantern's descent, which is TR5's.
  - **The pole's rock:** the pole stands alone in open sky right of the avatar and leans a few degrees each way. Then its light goes out and the scraps rise (`build_try_rock.png`). It reads at phone size, small.
- **Research, your call, the hang:**
  - On a Shade: (a) TR5's card fades while the player's own lead's signature hangs, about 0.35 s; or (b) it stays.
  - Against the keeper: (c) the square's foot is capped so its top stays inside the frame. It would then cross the keeper's hat, so the content check reads it again. Or (d) it stays, since the drop still lands in the frame.
  - My pick is (a) and (d): the keeper's card changes in TR5 anyway.

**The skip's block clip (Modulo, 2026-11-13, 21:07 to 21:25 UTC, about 0.3 h of its 1-hour cap).**
- **Delivered:**
  - `build/handoff/Pip/clips/Pip_Skip.json` and `build/handoff/Lyric/clips/Lyric_Skip.json`;
  - each with its `pack_Skip`;
  - each with its entry in `Pip.clips.json` or `Lyric.clips.json`.
- **The clip:**
  - It runs at 60 fps and doesn't loop: Pip's is 33 frames, Lyric's 34.
  - It moves in place; the body's travel is Faber's.
  - The beats: a gather to 5, off at 9, the top at 15 (0.36 studs up for Pip, 0.34 for Lyric), and **`Land` at frame 21, 0.35 s**, in a ready crouch.
  - The settle to the stance runs from 21 to the end. The next action may cut it at Land.
- **The props, keyed:**
  - Pip: the lantern is left behind, low, and bobs up after him. The hat floats at the top and sits a beat after his boots land.
  - Lyric: the stand comes up in her fist and goes down on Land. The speakers lag, swing in, and thump once on Land.
- **Checks:**
  - Legs swing 8° (Pip) and 9° (Lyric), of 25.
  - No arm is held.
  - Pip: the lantern stays 0.87 studs from his body, and his hands 1.46 from the brim.
  - Lyric: the speakers stay 0.06 studs from her arm, and her fist holds the pole 2.11 to 2.58 studs up it.
  - Both exports pass their audit (AUDIT PASS), and the content check passes both clips.
- **Code:**
  - The lift pass is shared now, as `rook_clips.lift`, and Lyric's keys can lift her.
  - The other clips are untouched, since their lift is 0.

**Research's read of the build and the call on the hang (2026-11-13; `build_pack_hang`, `_landing`, `build_try_hang`, `_lookdown`, the table):**
- **Accepted:**
  - the offset at 2.5. Inside a pack it's the avatar's own place that covers the fight, which is the player's steering, not the camera's.
  - Haymaker's landing as the slam: the square on the target's feet with the flash, then flat (B5's carried check passes).
  - the keeper's lantern and look down in one shot, and the pole's rock, small but read.
- **On a Shade: (a), through what exists, in TR7 now, not TR5.** `Config.Hud.SeeThrough` already turns the card see-through while a listed part sits behind it. Add the player's own lead's hanging square (the stamp's posts, rails and plate) to its watch, so the card goes to its Target see-through only while the square is actually behind it. That's not a timed fade, and the bar stays readable. TR5's scope stays as written.
- **Against the keeper: (c), not (d).** Haymaker's bold thing is the hang (B5's final). Off the top of the frame, it's lost in the one fight that matters most.
  - Cap the square's top a margin below the top band, measured from the camera each frame. Its foot may then come down over the hat.
  - One still to the content check. If it blocks, (d) stands.
- **Next:** the hang's two fixes with one still each, then the skip back. The framing closes with them.

**The hang's fixes (Faber, 2026-11-13, 22:25 to 23:10; stills in `build/captures/tr7/fix_*`).**
- **On a Shade, (a):** the posts, rails and plate of the player's own lead's square carry `Config.Hud.SeeThrough.Tag`, and the top band watches them. The Target card goes see-through only while the square is behind it (`fix_shade_seethrough.png`: the Brawler's card at its floor, the square behind it).
- **The cap, (c):** the frame's top stays `Stamp.Under` (10 px) below the top bar's foot (`UI.World.Ceiling`), measured from the camera each frame. The edge is the top bar's foot, as research chose, so the square hangs behind the see-through card. Each outer top corner meets that screen row at its own height, and the lowest holds: an off-centre top edge tilts on screen, and the middle alone left a corner 4 px over.
- **Against the keeper, (d) stands.** Capped, the square hung at the keeper's hat (`fix_keeper_hang.png`), and the content check blocked it on condition 1 of Haymaker's PASS (AR8: "B5's hang stays well above the head"). `Stamp.Uncapped` holds the keeper, so its hang stands as before (`fix_keeper_uncapped.png`).
- **From the same block, for every target:** the cap never holds the square lower than `Over`, `Clear` above the target's head. There the head's margin wins over the top bar, and the square's top may pass the line.
- **The content check, again: PASS** on `fix_keeper_uncapped.png` and `fix_shade_seethrough.png`, and on the floor in the code. The keeper's square is well above the hat; the Brawler's is about a head and a half clear. Still open from B5's own PASS (AR8): the slam passing the head in one frame, and a 64 px sheet at every heading before the art is uploaded.
- **Checks:**
  - type check 0 new; logic offline 3900/3900;
  - self-test "Haymaker" 55/55, "Keeper:" 65/65, "Camera:" 10/10, "Hud" 2/2, all at 60 fps. The cap's case: held at the line, never over it except at its floor, never under `Clear` over the head, uncapped over a Keeper (foot 34.40 of 34.40), capped over an Ordinary as tall (10.00, its floor).

**The skip back's blockout (Faber, 2026-11-13, about 1 hour by the commits and the takes' files; `build/captures/tr7/skip_*`).**
- **In the game,** on Modulo's block clip (baked in the place as `Skip`, fades 0.04 in and 0.1 out):
  - `Definitions/Actions`: `PipSkip` and `LyricSkip`, with `Beats.Land` 0.35, cancel from 0.35, no hits. `Actions.SkipOf(def)` gives a Voidkin's skip.
  - `Config.Combat.Skip`: On, Close 5, Every 4, Step 30 (degrees between the spots it tries), Body 1.5, Ground 2. All are live through `Tune`, and `On` turns it off for a check.
  - Pure rules in `Rules/Fight`: `ShouldSkip` (an enemy within Close, between actions, Every since the last, no swing at it winding up), `SkipBearings` (its place in the frame first, then spots round it by Step) and `SkipKeepsClear` (the path keeps Body from the enemy). They have a logic case.
  - `FightService`: the lead's think tries the skip before its next action. It glides to the spot by Land, still facing its target, re-aimed every frame with the Align held rigid, then lands into its next action.
  - `LeadLevel` takes an optional xp, so a test puts a save back exactly.
- **The self-test,** "Fight: a ranged lead skips back when a Shade closes", for each skipping Voidkin owned (Pip and Lyric here): 20/20 at 60 fps.
  - It skips inside Close and lands outside it: 11 to 14 studs from where the Shade stood, with no slide after Land.
  - Its facing, once turned (0.1 s in), is 2° off the Shade at worst for Pip and 5° for Lyric.
  - The next action starts 0.43 to 0.48 s after the skip does, inside Land + 0.3.
  - A Shade running in leaves the lead 25 to 32° off as the skip starts. The skip turns it at once (a line in `docs/polish-later.md`).
- **The balance check:** 10 runs with the skip and 10 without for each, alternating, `build/captures/tr7/skip_balance_runs.txt`.
  - Each run: the lead at level 1 against Lantern Row's Pack 1, at level 1. Respawn tuned to 1 s, with 11 s between runs so cooldowns reset. Each lead levels up on its second kill in both modes; the runs record when.

  | Lead | Damage taken, with / without | Time to clear, with / without | Falls | Skips a run |
  |---|---|---|---|---|
  | Pip | 446 / 479 (−6.8%) | 20.3 / 20.3 s (−0.3%) | 0 / 0 | 2.3 |
  | Lyric | 604 / 617 (−2.1%) | 27.4 / 26.3 s (+4.0%) | 0 / 0 | 3.0 |

  - Within 10% for both, and neither falls more often. Every stays 4.
  - Pip's damage taken spreads widely (sd 57 with, 95 without), wider than the gap. One run without the skip took 236; leave it out and the gap reads −11.8%. Ten runs can't tell these apart. Twenty more each would, if you want it.
- **The takes,** phone size: `skip_pip.mp4` and `skip_lyric.mp4`, with sheets, strips (`*_detail.png`) and stills (`*_still.png`).
  - Lyric's skip reads right of centre.
  - Pip's spot lies beyond his target from the camera, so his skip travels straight away from it and reads as a short shift on screen. That's the frame's geometry, not the skip.
- **The content check: PASS** on the stills and strips. Any frame used in public needs a 64 px sheet over dark and a fresh check.
- **Checks:**
  - type check 0 new; logic offline 3959/3959, and the same in Studio; world report 0 findings;
  - self-test "Fight:" 385/386. The one failure was Rook's piston slide, 0.85 against a stale 0.65: Modulo's B5 polish authored 0.85 (`Rook_Haymaker.json`). The expectation is updated, and the case passes 10/10.
- **Research, your call:** the blockout's verdict through `/ga-review`, and whether Pip's away-from-camera skip needs anything.

**Research's verdict on the skip back's blockout (2026-11-13; both takes at phone size, 10 fps strips 1.0 to 2.6 s and 4 fps 2.6 to 10.6 s, in `build/scratch/quaestor/tr7/`).**
- **Felt:** the skip itself is clean, quick and lands into the shot, with no moonwalk and no jitter. But across the fight the Shade is back on the lead within about half a second, and both leads spend most of each take shooting point-blank. Pip is pressed for nearly all of 2.6 to 9 s; Lyric opens a gap three or four times, and each is gone in a beat.
- **Tier:** works, as a block. The move passes; the behaviour the director asked for ("back away from close ranged enemy") shows for a moment every 4 s and is swallowed.
- **The one bold thing:** the landing into the next shot. It's what makes it a skip and not a retreat; keep it.
- **Fixes:**
  1. **Every from 4 to 2.5,** live through `Tune`, so the gap is what you see more often than the press. The balance check had room: both leads were well inside 10% (the design's "if the skip helps more, Every goes up" bounds it the other way). Rerun with the passives in place, so one batch covers both: 10 and 10 for Lyric, 20 and 20 for Pip given his spread. Past 10%, settle between 2.5 and 4 by the same check.
  2. **Pip's away-from-camera skip:** no lever. The read is the gap opening, not the path's length on screen, and fix 1 shows it more often. Judged again on the rerun's take.
  3. **For the shared finish** (`docs/polish-later.md`): a puff at take-off and a scuff at the landing, from the kit's rows, at rung 2. That's what sells a short skip seen end-on.

**The passives' blockout (Faber, 2026-11-13 to 14; `build/captures/tr7/passives*`).**
- **In the game,** as data:
  - `Definitions/Passives`: one row per lead, in three kinds. Second Wind is a Reduction: 20% less damage below 30% health. Kindle is an Extra: Fire worth 40% of `PipCombo`'s `Shot3`. Tempo is a Cooldown: Held Note's 20% shorter. The rows are live through `Tune` (`Passives.rook.Share`), and `Config.Combat.Passives.On` turns them off for a check.
  - `Rules/Passive`, pure: `Holds`, `Reduction`, `Extra` and `Cooldown`. A logic case covers their edges and one whole hit through `Hit.Resolve` (100 in, 80 taken).
  - `FightService`: the target's Reduction goes into `Hit.Resolve`, and the Extra joins the hit's elemental part, named on the Hit event. The Cooldown counts on the action's start and in the Ready and Cooldown attributes. A Reduction sets `PassiveOn` while it holds.
  - The cues, in grey. Second Wind: a faint ball round Rook while `PassiveOn` holds (`Config.Effects.Passives.Shell`). Kindle: the Fire as its own number in Pip's element colour, 0.1 s behind the shot's, and a flare at his lantern on the shot (`Passives.Flare`). Tempo has none.
- **The self-test,** "Fight: each lead's passive in play, with its cue": 19/19.
  - Rook's shell is on at 20% health, within a stud of him, and gone at full health.
  - Kindle comes on `Shot3` only, its Fire at least 40% of the shot's physical damage (119.1 on 297.9), with the flare seen.
  - Tempo's cooldown is 8.00 s.
- **The take,** phone size: `passives.mp4`, 30 s. Rook fights at 25% health against a level 13 Brawler, then Pip against a level 16. With it: `passives_sheet.png`, `passives_rook_still.png`, `passives_rook_strip.png`, `passives_pip_strip.png`, and `passives_pip_flare.png` (the flare at the lantern, and the Fire 112 beside the counting 637: 0.4 × `Shot3`'s 279).
- **The content check: PASS** on the cues and the names.
- **Two reads for research's pass:**
  - The shell is very faint at phone size, as the spec asks: in the still it's a thin ring. Its `Transparency` 0.6 is live.
  - Kindle's Fire, #FF8A3D, sits close in hue to a received hit's #E27A6A: in the take, a received 84 and the Fire 112 look alike. The received red is `docs/ui.md`'s muted red, so the element's tone is the freer one to move.

**The balance batch, the skip's rerun and the passives in one (Faber, 2026-11-14; `build/captures/tr7/passives_balance_runs.txt`, and Lyric's rerun in `passives_balance_lyric.txt`).**
- **The runs,** as before: the lead at level 1 against Pack 1 at level 1, Respawn 1 s, 11 s between runs, the modes interleaved, Every 2.5.

  | Lead | Mode | Runs | Damage taken (sd) | Time to clear (sd) | Falls | Skips a run | Under 30% health, a run |
  |---|---|---|---|---|---|---|---|
  | Rook | everything on | 10 | 614 (34) | 22.3 s (0.6) | 0 | | 3.6 s |
  | Rook | no passive | 10 | 665 (54) | 23.3 s (1.0) | 0 | | 6.2 s |
  | Pip | everything on | 20 | 407 (49) | 19.7 s (1.5) | 0 | 2.5 | 0.1 s |
  | Pip | no skip | 20 | 448 (29) | 21.2 s (2.5) | 0 | 0 | 0 |
  | Pip | no passive | 10 | 423 (43) | 21.1 s (1.4) | 0 | 2.4 | 0 |
  | Lyric | everything on | 10 | 565 (33) | 26.9 s (1.5) | 0 | 3.1 | 0 |
  | Lyric | no skip | 10 | 666 (111) | 29.3 s (4.5) | 0 | 0 | 1.3 s |
  | Lyric | no passive | 10 | 560 (40) | 26.9 s (1.6) | 0 | 3.0 | 0 |

- **Lyric's runs were taken again** after a bug the first batch showed: Rook's and Lyric's pushes could carry a Shade through Lantern Row's wall, and one stuck outside walked home forever. A push now ends at the world, and a Shade stuck walking home is set down at its place (c118647, with a logic case). In the rerun no Shade stood past 21.0 studs from the lane's middle, inside the walls at 22.
- **The skip, with and without:** Pip takes 9.3% less and clears 7.0% faster. Lyric takes 15.2% less and clears 8.3% faster. Most of hers is the bad runs it saves: three of her ten without it ran 32 to 37 s, two of them with her under 30% health, and the medians are 1.3% apart. Both are inside 10%, so Every stays 2.5.
- **The passives, with and without:** Rook takes 7.6% less, clears 4.0% faster, and spends about half as long under 30% health. Pip clears 6.5% faster and takes 3.9% less. Lyric's Tempo changes nothing measurable: +0.1% to clear, +0.9% taken, Held Note 3.0 times a run against 2.9.
  - Why, from the Definitions (DESIGN, not measured): a cast waits for the combo in hand (1.75 s) to end. So at 8 s her casts come every 9.5 s, against 11.25 at 10 s, and a fourth would land at 28.5 s, just past a 27 s clear. Tempo pays only in longer fights, a keeper's.
- **The skip's rerun take, at phone size** (fix 2; level 1 against Pack 1, Every 2.5, the passives on), in `build/captures/tr7/`:
  - `skip_rerun_pip.mp4`: 25 s, with skips at about 8.0, 14.7, 17.3 and 22.4 s. Strips: `skip_rerun_pip_8s_strip.png` and `_15s_strip.png`.
  - `skip_rerun_lyric.mp4`: 29 s, with skips at about 6.7, 11.8, 17.9 and 27.4 s. Strip: `skip_rerun_lyric_7s_strip.png`.
  - The times come from the server, within about half a second of the video's.
- **The three side by side,** everything on: Pip 19.7 s, Rook 22.3 s (+13%), Lyric 26.9 s (+36%). The rule holds for none of the pairs with Pip.
  - No passive's number closes it. Second Wind acts only under 30% health, where a level-1 Rook spends 3.6 s a run. Tempo adds no cast inside a clear (above). Kindle is Pip's, the fastest.
  - The gap was there before the passives: without them, Pip 21.1 s and Lyric 26.9 s. It's in the combos, which the rule keeps fixed.
  - **For research, the options:** (a) a passive of another kind for Lyric, one that pays across a whole pack (a tier 2 change to the seeds); (b) the check judged on another measure for a ranged lead, since hers is the only one that keeps its distance; (c) the combos' numbers opened for this one check, Lyric's and Rook's; (d) accepted for the block, settled at TR7's timing (part 4), which touches the combos' beats anyway. Mine is (d) with (c) inside it: the timing piece already moves the combos' beats, so the gap closes there with one batch, not two.

**Research's verdict on the passives and the gap, 2026-11-14** (the batch above; `passives.mp4` and its stills; the skip's rerun strips).
- **Felt:** Rook's shell and Pip's flare are cues you can catch at phone size, and Kindle's Fire as its own number is a small treat on the third shot. Tempo is felt nowhere in a pack: 3.0 casts against 2.9.
- **Tier:** works, as blocks, for Second Wind and Kindle. Tempo fails its own line ("the song comes round more often").
- **The one bold thing:** Kindle's Fire, its own number on the shot, a passive you see every few seconds.
- **The gap: (d) with (c), Faber's pick.** My rule, "its passive's number moves, not its combo's", assumed a passive could close the gap; the batch shows none can, so the rule is corrected: the 10% band is settled at TR7's timing (part 4), with Rook's and Lyric's combos open. They come up toward Pip, not Pip down, checked against `tools/balance/sim.py`'s pace. A Rare that clears a third slower than a Common is the wrong first lesson of the ladder.
- **Fixes:**
  1. Tempo must show in a pack: Held Note no longer waits for the combo in hand (the same kind, no new cue), the shorter cooldown kept. If the timing batch still shows nothing, research brings another kind.
  2. Kindle's Fire moves its tone away from a received hit's red, kept clear of the critical's gold; Faber's call on the value, checked side by side in the timing take.
  3. The shell stays faint, as asked.
- **Pip's end-on skip:** seen in the rerun (the 8 s strip), no lever, as fix 2 said. The take at the timing shows it again in a real fight.

**Status:** requested, 2026-11-13. The framing's blockout is judged: A with Turn 40. The framing is built, with its take, and accepted. Research's call on the hang: SeeThrough on a Shade, the cap against the keeper. The hang's fixes are in, with (d) against the keeper after the content check's block, 2026-11-13: the framing closes. The skip back's blockout is in, with its balance check within 10%; research's verdict: works, Every to 2.5, rerun with the passives in place, 2026-11-13. The passives are built, and the batch with the skip's rerun is in (Lyric's rows taken again after the wall fix), 2026-11-14. The skip's rerun take is in. Research's verdict on the passives, 2026-11-14: works for two, Tempo to show in a pack; the gap settled at the timing with the combos open. The director, 2026-11-14, night: framing A's shoulder ease is scrapped ("simply do not touch player camera"); the placement (Lead.Frame, Lead.Beside, Keeper.Turn) stays, its two checks retaken without the ease (`docs/decisions.md`). The ease is out, 2026-11-14 (Faber): `Shoulder.luau`, `Config.Combat.Shoulder` and `Rules.Fight.ShoulderShare` are gone with their cases, and a self-test case checks that a fight leaves the camera's offset at zero (type check 0 new, logic 4027 offline; its Studio run waits on the MCP). Next: the two checks retaken without the ease, in a pack fight and a keeper's try, with Turn 40 judged, then the timing.

## TR5. The elite's and the keeper's HUD (Faber, with Modulo's frames)

Research's request, 2026-11-13, on the director's word of the same day: "btw mini boss and boss should have a different HUD" (`docs/decisions.md`). A new piece: TR3 stays closed.

**Feel line:**
- An elite's card wears a heavier frame than a Shade's, so you know it's no ordinary Shade before the first blow.
- When a keeper steps up, its name, its title and one long bar take the screen like a title card, so you know this fight is the street's own.

**The block contains** three variants in grey, judged in motion at phone size in a keeper's try and an elite's pack. It's the HUD's own pattern, a boss bar, in our own frames.
- **A. The keeper at the foot.**
  - The keeper's bar runs wide across the bottom centre: its name and title above, its phases as segments.
  - During a try, the dock steps out, since its buttons don't serve a fight.
  - The top band then has no target card over the keeper's hat, the problem AR7 section 5 met (`Config.Hud.SeeThrough`).
- **B. The keeper at the top.** A wide, thin bar across the top centre, in the target card's place and below the band, with its name and title over it.
- **C. The elite only.** The target card as it is, with a heavier frame: a crest notch, the word Elite, a thicker bar. It's used with A or B. A keeper gets A or B.
- Both open with the name stamped on as the Challenge lands, and leave as the fall's Gone.

**Waits:**
- the frames' art (Modulo's, on the kit, after the verdict);
- the sounds;
- the other grounds' keepers.

**Order in the queue:** after "Rook, Pip and Lyric installed". **Time, forecast:** the grey variants about 1.5 hours, the art about 2.

**The grey blockout (Faber, 2026-11-13 to 14; takes and stills in `build/captures/tr5/`).**
- **The director's pick, 2026-11-14, while the takes ran:** "it should be at the top middle". It covers where the keeper's HUD stands, nothing else.
  - B was then laid inside the band: the title, the name and the bar in the target card's place, as wide as the room between the lead's card and the pills. That is 216 authored px on the smallest phone and about 360 at the authored size, with its foot at 87, above the lead card's foot at 113.
  - B as first built put its bar under the band at y 118. On a phone that crossed the middle of the screen, through the keeper's body (`tr5_b_8s.png`), so it's gone.
  - `Config.Hud.Boss.Keeper` is "B". A, at the foot, is still one Tune away.
- **The director's words on its look, 2026-11-14,** on the grey top middle:
  - "let make the Hud of the boss bar much better this is so empty and let make the hp color a purpleish all of course well compose";
  - then "it does need to looks very light too else we see nothing".

  They cover the keeper's boss bar: its look, its health's colour, and staying light over the fight. The elite's card keeps its red.
  - **Rebuilt as a title card with no plate behind it:**
    - the title, small and lilac grey, between two thin rules, each ending in a diamond;
    - the name large, with its type's gem before it and its level in the cards' gold after it, cut to fit;
    - one framed bar on a faint purple glow. The fill is the keeper's purple, lit from above (#CDA6FF to #9150FF to #5A27C9), with diamond caps at the ends and one at the phase. Its empty part is see-through.
  - **New motion:** a pale trail behind the fill holds 0.45 s after a hit, then drains half the bar a second. A shine crosses the bar once as it comes in.
  - Every word has a dark edge. The numbers are in `Config.Hud.Boss`.
- **In the game:**
  - `UI.BossBar`: the title card in both layouts.
  - `UI.TargetCard.Elite`: C.
  - `HudController`: the target card stands aside for a keeper, the dock steps out in A, and it measures the band's room.
  - `Text.Resize`, and the `Keeper` field in `Definitions.Grounds` for the title ("Keeper of Lantern Row").
  - The numbers: `Config.Hud.Boss`.
- **The stamp and the leave:**
  - The name stamps on at the Challenge's Stamp beat (0.03 s off in the self-test), from 1.6 times its size over 0.14 s. The title and the bar follow over 0.25 s.
  - It leaves from the fall's Gone: 1.77 s after the fall, against 1.68.
- **A fix after the first take:** the title was dim grey with no edge and vanished on Lantern Row's pale floor (`tr5_a_5s.png`). The title, the name, the number and the word Elite now have a dark edge.
- **Checks:**
  - Self-test "HUD:" 153/153 at 59 fps on the grey block.
  - With the purple bar and research's fixes, 158/158 at 59 fps. TR5's case adds four checks: the purple fill; the trail held behind the fill after a hit, never under it; the number on the bar; the word Elite in the tab after the level.
  - TR5's case passes both layouts through the UI lint on the smallest phone. Type check: 0 new.
- **Takes, at phone size** (Studio's device test, iPhone 16 Pro):
  - `tr5_fixed.mp4`, the purple bar with the fixes, 20 s of a try: the fade, the stamp, the shine and the fight. Stills: `tr5_fixed_10s.png`; `tr5_fixed_zoom.png`, 12 frames of the bar over 3 s; and `tr5_fixed_number.png`, the number moved clear of the cap. The keeper's hat and lantern read under the card and through its empty part;
  - `tr5_c_fixed.png`, an elite's card with the word in its tab;
  - `tr5_purple.mp4`, the purple bar before the fixes, kept for the record;
  - `tr5_top.mp4`, the grey top middle, a whole try: the fade, the stamp, the fight, the fall and its leave;
  - `tr5_a.mp4`, the foot;
  - `tr5_b.mp4`, B as first built, kept for the record;
  - `tr5_c.png`, an elite's card.
- **The content check:** PASS on the three grey stills and the names. Its one note was the grey word Elite against the sky, which is now edged. PASS on the purple bar's stills and code, 2026-11-14: the trail is near-white, nothing reads as a liquid, and the gem is ours (`tools/blender/ui_kit.py`).
- **Seen, not TR5's:** in one try of the four, the Lamplighter fell to Rook (level 11) in about 11 s. In another it stood at 88% after 8 s. Not explained yet; it's a note for the keeper's balance.

**Research's verdict on the grey blockout, 2026-11-14** (`tr5_top.mp4` at one-second steps, its 7 s still, and `tr5_c.png`, at phone size).
- **Felt:** when the Lamplighter steps up, his name stamps into the band where the target card stood and the bar runs between Rook's card and the pills: the fight gets its headline without covering the ring, but the bar is thin and the number hangs below the band, over the keeper's hat.
- **Tier:** works, as a block. The director's pick, the top middle, holds.
- **The one bold thing:** the keeper's name and title stamped into the band at the Challenge: the street's own fight announced where the eye already reads.
- **Fixes:**
  1. Nothing of the keeper's HUD below the band's foot: the number sits on the bar's right end or inside it, so it never crosses the keeper (the 7 s still: "14,038/15,457" on his hat).
  2. The bar about twice as thick, still inside the band, so it reads at a glance as the one long bar (it's thinner than Rook's now).
  3. C, the elite: the word Elite inside the frame, in the card's own ink, not grey on the sky. The frame's weight is Modulo's art.
- **Modulo's frames, next:** the keeper's bar frame and title plate, and the elite's heavier card frame with its crest notch, on the kit in Graphite, to the fixed layout.
- **Carried:** the Lamplighter falling to Rook at level 11 in about 11 s, one try of four, goes with TR7's timing, where research reads the keeper's numbers.

**The fixes (Faber, 2026-11-14),** built on the purple bar:
1. **Nothing below the band's foot:** the number sits inside the bar's right end, 12 px clear of its cap. In B the card runs from 17 to 86 authored px, against the lead card's foot at 113.
2. **The bar 18 px,** against the grey block's 8. That's the least that holds the number's line on the smallest phone (Caption at the scale's floor, 17). Its empty part went from 0.3 to 0.45 see-through, for the director's "very light".
3. **C:** the word Elite in the card's tab after the level, in the card's ivory. The tab stretches to fit it. Its grey and its edge are gone.

**Modulo's frames, the scope (2026-11-14).** The keeper's HUD stays as Faber rebuilt it on the director's words: no plate, nothing solid over the fight; the purple fill, the glow, the text and the motion are his. Research's word of the same day: no fill, the title's frame is the two rules with diamond tips and a small crest at the middle top, as one ornament.
- **In the block:** line art in the kit's metal, white to tint, lit from above, with a dark hairline baked in so it reads on the pale floor.
  - The keeper: the bar's rim for a bar 20 high (`BossBarRim`, sliced); the two end caps and the phase mark as faceted lozenges (`BossBarCap`, `BossBarMark`); the two rules, each with a diamond tip and tapering toward the title (`BossTitleRuleLeft`, `BossTitleRuleRight`, sliced across); and the crest over the title's middle (`BossTitleCrest`).
  - The elite: the blade 6 taller, with its light in one piece 23 high (`CardTargetEliteHousing`, `CardTargetEliteHousingRim`, `CardLightHealthElite`). Its heavier frame runs round the blade and a small tab at its right end, with the crest notch on the tab (`CardTargetEliteFrame`). The tab holds the word Elite in the card's ink (`CardTargetEliteTab`, `CardTargetEliteTabRim`).
- **Waits:** the keeper's phase mark stands in until the keeper has phases.

**Modulo's frames, delivered, 2026-11-14** (`build/handoff/UI/hud/boss/`: `images/`, `boss.json` in `lead_card.json`'s schema, `boss_sheet.png` at 2 and 1 pixels a point on the sky, the pale floor and the night, `boss_sheet_zoom.png`; drawn by `tools/blender/boss_hud_art.py`).
- **The keeper,** each image white for Faber to tint Rim. Placing them:
  - `BossBarRim` replaces the channel's UIStroke: sliced, its box the channel's, pad 3. It lies 2.2 outside the channel, with a dark line just inside over the fill's edge.
  - `BossBarCap` (12 by 29) replaces the two cap diamonds, centred on the channel's ends. `BossBarMark` (7 by 26) replaces the phase diamond.
  - They were drawn for a bar 20 high; Faber's 11853ba sets it at 18. The rim slices to any height. The cap and the mark scale with the bar: the cap 1.45 times its height, the mark 1.3.
  - `BossTitleRuleLeft` and `BossTitleRuleRight` replace the two rules and their tips. Each is sliced across, its box from the tip's outer point to the taper's end, 6.4 high, centred on the title's middle.
  - `BossTitleCrest` (24 by 11) has its foot's middle 2 into the title row's top middle, so the title row moves down 9 or the crest stands above `Top.Y`.
- **The elite,** in the lead's points like `CardTargetHousing`. Its geometry is in `boss.json`, `elite`, in the target card's own points:
  - the card 45.8 high, and the stud at (6.65, 30.9);
  - the light row 23 high;
  - the word Elite centred at (189.9, 9.5), in the name's ink;
  - the crest notch reaching 7.3 above the card's top.
  - The name's tab must end by x 165.85, so an elite's name holds about 90 pixels. The Shades' names are short.
  - The frame's tint is Faber's call. The sheet shows it in Graphite's glint, #C9D2E4. The housing's rim and the tab's rim take `TargetTrim`. Faber's grey goes: the stroke, the notch, the Under strip and the grey word.
- **Checks:** the self-review at phone size on the three grounds. Every piece reads, the crest and the notch small as asked. The content check: PASS, 2026-11-14.
- **Time:** about 0.3 h, 01:32 to 01:52.

**Research's read of the fixes and pass on Modulo's frames, 2026-11-14** (`tr5_fixed_10s.png`, `tr5_c_fixed.png`, `boss_sheet.png` at 2 and 1 px a point on three grounds).
- **The fixes landed:** the purple bar at 18 px with its number inside, nothing below the band's foot, clear of the keeper; the title between its rules; Elite in the tab, in the card's ivory.
- **Felt:** the keeper's bar now announces the fight like a title card drawn in line, light over the ring as the director asked, and the elite's card is plainly heavier at a glance.
- **Tier:** competent, accepted. The director's words hold: nothing solid behind the name.
- **The one bold thing:** the tapering rules with diamond tips and the winged crest: a title card made of line, so the fight stays visible through it.
- **No fix.** One watch at install: the number over the pale trail (at about 80% health it sits on it); its dark edge carries it in the sheet, so check it in the take.

**The director's words on the purple bar, 2026-11-14 (evening),** said to Faber:
- "we should remove the middle crystal in the hp middle bar of the boss then it perfecg";
- "and make the hp text value be in the center of the hp frame";
- "also the boss name be in a black or redish or purplish or something better text not white".

They cover the keeper's bar: the phase mark, the health number's place, and the name's colour. Built the same evening (Faber):
- **The middle crystal:** gone. It was the phase mark, a stand-in, since the keeper has no phases; `Config.Hud.Boss.Phases` goes with it, and Modulo's `BossBarMark` stays unused.
- **The number:** centred on the bar. It sits on the pale trail only after a hit crosses the middle, and its dark edge carries it there. That answers research's watch, checked in `tr5_centre_zoom.png`.
- **The name:** the keeper's purple, lit from above like the fill (#D7B5FF to #A066FF, `Config.Hud.Boss.Name`), keeping its dark edge; the level stays the cards' gold.
- **Checks:** type check 0 new. Self-test "HUD:" 161/161 at 60 fps, with three new checks: the number in the bar's middle, no mark across the bar, the name in the keeper's purple. The first run had one flake: a toast's message caught sliding in just after the start; the rerun passed.
- **Stills:** `tr5_centre_trail.jpg` (a try, the number on the trail at about a quarter health) and `tr5_centre_zoom.png`. The frames' install still to come: the 12 images are uploaded under the group, Approved and in `UIKit.luau`.

**Status:** built in grey, 2026-11-14, with B at the top middle by the director's pick. Research's verdict given, 2026-11-14: works, three fixes (Faber), and Modulo's frames start. The keeper's bar was rebuilt on the director's words of the same day (richer, purple, light), with the three fixes in. Research's read of the fixes and pass on Modulo's frames, 2026-11-14: competent, accepted. The director's three words of the evening are built (no middle mark, the number centred, the name purple). The frames are uploaded and in the kit. Next: the frames installed in the bar and the elite's card (Faber).

## TR6. The UI effects kit (Faber)

Research's request, 2026-11-13, from the UI effects study the director asked for that day (`docs/research/vfx-reference.md`, "UI effects", its DESIGN part). Tier 2, research and Faber.

**Feel line:** every press answers the thumb at once with a squeeze and a tick, and every reward flies to its counter and lands with a pulse sized to what it's worth, so the screens feel expensive without ever getting loud.

**The block contains:**
- one kit (Pop, Press, Fly, Count, Shine, Rays, Burst) with its tokens in `UI/Theme.Motion`;
- the press on every button;
- Credits and Electricity flying in after a kill and on a collect;
- the level-up's rays.

It's judged in motion at phone size, beside the before.

**Waits:** the reveal's own layers (TR4, closed, stays), the Breaker screen's effects (with its piece), and sounds beyond the existing cues.

**Order in the queue:** after TR5. **Time, forecast:** about 2 hours.

**Status:** built, 2026-11-14 (Faber).
- **Implemented.**
  - The kit: `src/client/UI/Kit/` Fly, Count, Rays, Shine and Burst, beside AR8 C's Pop and Press, unchanged. Their pure rules are `Rules.Hud`'s ExpoOut, Flock and Arc. Their tokens are `Config.Hud.Motion`'s Haptic, Fly, Count, Rays, Shine and Burst, plus `Pop.Rungs.Fly`.
  - The press: a touch on a button that takes it plays Roblox's UIClick haptic (`Button.Haptic`).
  - A kill's Credits fly from where the Shade fell into the pill's coin. As the first one lands, the number counts up (Expo out), the pill pops at rung 5 and its "+N" rises. A win from nowhere on screen counts and pops at once, at its own rung. A spend shows at once.
  - The level-up: rays behind the word as it lands, one light band across its fill and its edge, and a gold burst off the badge.
- **Calls inside the piece (tier 1, Faber's).**
  - The tokens live in `Config.Hud.Motion`, not `UI/Theme.Motion`, so Tune changes them live.
  - The squeeze stays AR8 C's 0.92, not the study's 0.96: research named it AR8 C's bold thing, and the logic case holds it between 0.88 and 0.95.
  - The game has no Electricity collect, so Electricity flies on the battery's jump (a return from away), from the screen's middle.
  - The shine goes only on the level's word, the one rare reward the HUD shows now.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4039 passing offline, with a new case for the count, the flock and the arc.
  - The self-test's new TR6 case and the level-up's four new checks wait on the Studio MCP, with TR5's.
- **Visually reviewed:** not yet. The captures at phone size, beside the before, go here once Studio is back.
- **Accepted:** no.

## TR8. Lantern Row dressed, with its night (Faber, with AR5)

Research's entry, 2026-11-14. Phase 2's "Lantern Row dressed" (`docs/production-plan.md`). The kit is delivered and accepted (AR5, section 2), so the direction is chosen: this is the build, not a new blockout.

**Feel line:** through the festival gate, the player steps off the plot into a warm street of stalls and lantern strings at dusk that slowly turns to night, and every fight on it, a pack, the elite's square, the keeper's gate, reads clear against the light at phone size.

**The block contains:**
- **The kit installed** from `build/handoff/LanternRow/` as AR5's "For the builder" says: each piece at its place from `manifest.json`, one SurfaceAppearance each, the lights in `plan.json` and no others, `CastShadow` off where it says, a Part under each look floor for the walking. The upload covers what the content check passed, and nothing else.
- **Through the world contract** (`docs/engineering-plan.md`, "The world contract"): the markers the fight already reads stay where TR2 put them, and the world report stays sound.
- **The night cycle:** one server clock, dusk and night with a crossfade (`docs/decisions.md`, 2026-11-12). The seed, tier 2 and tuned by playing: 20 minutes, 13 of dusk, 5 of night, a minute's crossing each way. Its length and a jump to either phase are live through Tune, for the takes.
- **The three notes for the install, tuned live:** the houses' glow at about two thirds (half their windows dark if the skyline still reads as a city); a Shade's edge against the floors (the floors' glow strength is the lever); the square's fight frame.

**Waits:** goods on the counters; the keeper's ring past the gate as dressing; the Breaker and the bay as machines; the other grounds' recolours.

**Checks:** self-test and world report; the device take with the phone's device test on, inside AR5's budget (14 lights the ceiling); research's verdict from the player's camera from both ends, in a pack fight, the square and the keeper's gate, at dusk and at night; `ga-fresh-eyes` at the final (a major landmark aims at exceptional).

**Order in the queue:** after TR6 and "Content as data". **Time, forecast:** 3 to 5 hours.

**Status:** installed, the take with research for its verdict, 2026-11-14 (Faber). Type check 0 new, logic 5526 offline.
- **The kit:** its two files taken as they are (`tools/world/kit_take.py`, into `Config.Kits.LanternRow`), the placement in `Shared.World.Kit`, and the street dressed by `WorldService` from the template. Each piece stands at the plan's place, with the plan's nine static lights. The grey walls, square and gates stay as unseen colliders, and the street's own floor carries the walking in the kit's paving tile.
- **The night:** `Rules.Night` on the server's clock, `Config.Lighting` from the kit's frames, and `LightingController`. The ground's look holds from 24 studs short of the gate, so a door's landing opens in it. A sky is swapped under the haze's peak; the lead carries the plan's tenth light. `Night <phase>` jumps the turn, and every number is live through Tune.
- **The paper:** its emitter from the plan's numbers (AR5, "The paper's emitter"), in eight boxes from the gate up the street over the paving (`Kit.Paper`, a logic case).
- **Studio's half:** the 16 meshes published under the group, and the maps and sky faces uploaded, all in `docs/asset-log.md`. `tools/studio/KitAssembly.luau` builds the template, `src/storage/LanternRowKit.rbxm`, from `tools/studio/Kits/LanternRow.json`. `DressReport` is clean: 288 pieces and eight boxes of paper, as the plan has them.
- **Self-test:** World TR8 3 passed, Lighting TR8 32 passed, at 60 fps. The take case, `Take: TR8`, 9 passed, at phone size from the player's camera: up the street at dusk and back down at night. Two steps aren't played: the standing packs are cleared first, and the turn to night is jumped.
- **Waiting:** research's verdict on the take, with the three notes to tune live after it; the device budget on the phone; `ga-fresh-eyes` at the final.
- **Research's verdict in motion, 2026-11-14, night** (`build/scratch/faber/take/tr8_take.mp4`, phone size; read at its beats, dusk at 7 to 25, night at 31 to 48).
  - **Felt:** through the door, the street opens as a tunnel of lanterns running to a bright far point, with stalls and lit windows on both sides. At night the sky goes navy and the lanterns take over. It reads as a festival at phone size, and dusk and night are told apart at a glance.
  - **Tier:** competent.
  - **The bold thing:** the lantern canopy converging up the street. It pulls the eye toward the elite's square and the keeper, which is the ground's whole direction.
  - **Fix (Faber): the paper never passes the camera.** At 7.5, 14, 31.6 and 47.9 a piece drifts close and fills a corner as a large flat white quad, the brightest shape on screen. It reads as a glitch, not paper. Fade each piece out near the camera, or keep the boxes clear of it, and take it off pure white to a warm paper tint. (Serves composition and the read.)
  - **The three install notes:**
    1. **The houses' glow at two thirds: yes.** The lanterns are the street's hero, and the windows are its fill.
    2. **A Shade's edge against the floors: no change.** The Brawlers' black and red part from the paving at dusk and at night.
    3. **The fight frame at the square: not judged here.** On a walk that doesn't stop, the avatar standing between the camera and the Brawler is expected with a camera that never moves. It's judged in a take with a real stop.
  - **Not TR8's, noted for their own verdicts:**
    - TR10's Stack card sits mid-screen over the avatar's path the whole way up. That goes in TR10's verdict.
    - The door's Way slab blooms at night as the brightest thing at the gate. That's the door's look, and it waits.
- **Research's read of round 1, 2026-11-14, night** (the retake; round 0 is kept as `tr8_take_round0.mp4`): **the paper fix lands, and TR8's verdict stands at competent.**
  - The scraps drift among the lantern strings, small and cream. Nothing passes the camera on the walk.
  - At night they read as paper, not embers or ash: flat, pale and unlit beside the lanterns. The content check's condition is met.
  - At 7.5 and 12, the white shape low on the right is Ironhymn's grey stand-in walking beside the camera, not paper.
  - **The Way slab, on Faber's question: dim it now, dress it later.** Dimming is one number, and it stops a grey block from outshining the ground's lanterns at the gate. So take it off Neon, to no brighter than the lanterns. Its dressing waits for the world's door pass.
- **Fix round 1, the paper, 2026-11-14 (Faber):** the boxes held in a band over the camera, 12 to 18.5 studs over the paving among the lantern strings (the plan's 4 to 14.5), the rate following the band's height so the density holds, and a warm paper tint, #F2E3C6, no glow: `Config.Lighting.Paper`, live through Tune, placed by `Kit.PaperBand` on the server and the client. Content check PASS for the tint and band; its standing condition sharper among the lanterns: paper, never embers by a lantern or ash at night. Checks: a logic case keeps the floor over Roblox's starting zoom pitched 30 degrees down (10.75); World TR8 sees each box in the band in its tint; the retake (`tr8_take.mp4`, round 0 kept as `tr8_take_round0.mp4`) passed 10, the camera's highest 8.43 over the paving. A player zoomed out past about 20 studs rides into the band. Waiting: research's verdict on the retake.
- **The Way slab dimmed, 2026-11-14 (Faber), on research's read of round 1:** the door home's way off Neon to SmoothPlastic, lit by the street (`Config.World.Grey.Door.HomeWay`); the plots' Festival Doors keep theirs. World TR8 checks it, 5 passed; the take again, 10 passed. At night at the gate the lanterns are the brightest thing. Its dressing waits for the door pass.

## TR9. The Breaker screen, on the kit (Faber, with AR3)

Research's entry, 2026-11-14. Phase 2's "the Breaker screen on the real kit" (`docs/production-plan.md`); the screen's design is `docs/ui.md`, "The screens of the first loop", 3. TR2's grey prompts and plates are its "before".

**Feel line:** at home, the player opens the Void Breaker and sees its chambers as they stand in the world, each shard cracking with its time left, the waiting line below, and with one tap the shard's odds, so feeding a shard in feels like loading a machine, not filling a form.

**The block contains:**
- **Two or three layouts in grey,** judged at phone size in a take at home with shards breaking: the chambers, the waiting line, the odds one tap away, infusion as a clear choice with its Electricity price and what it does to the odds (`docs/design.md`, "Infusion"; not on Named shards).
- **Then the picked one on AR3's kit,** in the Dynamo palette (`docs/ui.md`, "One look, ours"), with its frames and motion from TR6.
- **The odds as `Rules/Odds` gives them,** never copied into the screen.

**Waits:** the bays' screen (`docs/ui.md`, 7); the Condenser; any Robux price (`docs/roblox-rules.md`).

**Checks:** a self-test case for each control's state, the UI lint, a logic case if a rule moves; the content check on any new text; research's verdict on the grey layouts, then its pass on the build at phone size.

**Order in the queue:** after TR8. **Time, forecast:** 2 to 3 hours.

**Status:** "Drop rates" is built, 2026-11-15, for research's pass (Faber, "Drop rates" below). Machine and its payoff have research's pass, with the fade fix and the two names. Not built yet: voltage as time, which goes with TR18, whose kWh price it. Machine picked, and research's fixes built, 2026-11-15 ("The fixes built" below). Before: the grey layouts and infusion built, and their take with research for its verdict, 2026-11-14. Time: about 2.5 active hours, my estimate, not measured.
- **Implemented.**
  - **Infusion, on the server** (`Rules.Base.Infuse { Chamber | Line, Def, Level }`): the price from the battery, and the shard's Luck raised by `Config.Shards.Infusion[Level]` (seeds: a little, +0.10 for 300; a lot, +0.25 for 900), capped at `LuckCap`.
    - Once per shard. Only a shard still breaking or waiting, never one ready or in the bag, and never a Named or a starter shard (`Odds.Lifted`, which counts the tiers the luck lifts).
    - `Def` is the shard the client saw there. A shard that broke or moved since is refused as "Moved", and nothing is spent.
    - The new refusals are Named, Infused, Short and Moved, each with its toast.
  - **`AddShard` answers where the shard stands,** its Chamber or its place in the Line, so the screen keeps it chosen as it goes in.
  - **The screen** (`UI/BreakerScreen`): the Breaker's prompt opens it when nothing is ready, and opens the oldest ready shard otherwise, as before.
    - **Three layouts,** tuned live through `Config.Hud.Breaker.Layout`:
      - **Machine:** the chambers side by side, each with its shard, its crack as a conduit filling and its time left, and the rest locked up to `Breaker.MostChambers` (4). A strip below holds what's ready, waiting and in the bag. The chosen shard's pane is on the right.
      - **List:** one row per shard, beside the pane.
      - **Sheet:** the machine across the screen, and the pane comes over it on a tap, with Back.
    - **The pane:** the shard's name and place over one column that scrolls: its one action (Open, Take out, Put it in), infusion, and every chance from `Rules.Odds`, rarest first.
      - When the whole shard takes no infusion, one line over the levels says why: it holds one Voidkin, one tier only, put it in first, already broken, or "Infused, a little: once a shard".
      - Each level is a button with its price, "A little · 300" and "A lot · 900", kept on it when it's locked. The line beside it says what the level does to the rarest tier (the tier, its chance now, its chance after), or why that level can't be paid: "Needs 300 Electricity", or research's "Needs a battery of 900: upgrade the base".
      - The first build put the reasons on the buttons themselves, but the kit writes a disabled button's reason as its label, and the longer reasons overflowed a 112-pixel button. The odds list kept barely 56 pixels at the foot. The column fixes both.
  - **The screens' kit:** a screen opened again as its owner rebuilds it now refills its body in place: no second entrance, and Closed doesn't fire. The Base screen rebuilt the same way on each change of the save, and flashed.
  - **Studio adds `BaseBattery`** (the battery set within its capacity), for the price tests.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4841 passing offline. Infusion has two new cases (the price, a repeat, a second infusion, short, the lift; Named, moved, a different Def, bad arguments), and `AddShard`'s answer has one.
  - The self-test's new cases wait on the Studio MCP:
    - the prompt's choice;
    - each layout at this screen's scale and the smallest phone's, with the UI lint: the chambers as they stand, the strip, a row per shard, the odds rarest first, a tap to a shard, and the sheet's Back;
    - infusion's every refusal and its text, its price, its effect, one press spent once, the odds lifted, and the broken shard opened;
    - the kit's refill in place.
  - **The content check** on the screen's text: PASS. Two of its three notes are done: an infused shard is named by its level ("Infused, a little"), not by its luck as a number, which reads as a chance; and a chance under 0.01% shows as "<0.01%", never "0.00%". The third is done for a level short of Electricity ("Needs 300 Electricity"). The reworked pane's text had a second check: PASS.
- **Research's calls, 2026-11-14, night.**
  - **The price stays, and the battery grows into it** (tier 2, research's). Infusion is meant for the rare shards a player meets once the base has grown (`docs/balance.md`, the Prismatic's nudge), and the battery's cap rises with the base's level (`docs/design.md`, "The base"). Seed: the base's level 2 holds 1,000. The rest of the table is set when the base's upgrades are built.
    - Until then "a lot" stays shown and locked. Its reason names the way there, not only the shortfall: "Needs a battery of 900: upgrade the base".
  - **Once per shard: Faber's reading is right.** "Adds into one number" is about sources (the Breaker's tuning and an infusion), not one shard infused twice. A little or a lot is one choice.
- **Visually reviewed:** the take sent to research, 2026-11-14 (`build/scratch/faber/take/tr9_take.mp4`, phone size, the case `Take: TR9`, 16 passed at 59 fps): the walk to the Breaker and its prompt; Machine with a chamber tapped and a shard in the line infused a little; List with a row's odds; Sheet with a chamber's odds over the machine, Back and Close, the chambers breaking through it. Not played: the shards and the full battery given first, and each switch of layout (a Tune on the open screen). Research's verdict waits.
- **Director-accepted:** no.
- **Out of the block:** AR3's kit in the Dynamo palette, after the verdict; the bays' screen; any Robux price.
- **Research's verdict in motion, and the director's pick, 2026-11-14, night** (the take, read at its beats at phone size).
  - **The director's pick: Machine** (on research's recommendation). List and Sheet are dropped, with Faber's two notes on them (Sheet's fold, List's scroll).
  - **Felt:** in Machine, the whole Breaker reads at a glance: what's cracking and how long, what's next, what's in the bag. Infusion is a clear choice, its price and its effect side by side ("Epic 1.0% → 1.1%"), and the one it can't afford says why.
  - **Tier:** works (grey).
  - **The bold thing:** the chambers as boxes, filling in a row like the machine in the world. The screen is the machine, not a list about it.
  - **Fixes (Faber):**
    1. **A ready chamber is the loudest thing on the screen.** The take shows Ready in List and Sheet, but never in Machine. In Machine, a ready chamber should glow gold, read "Ready", and open on a tap of the box itself. This is the payoff moment. (Serves impact.)
    2. **A locked chamber says what opens it** ("Locked · base level N"), by the same rule as the locked infusion. "Locked" alone is a dead end. (Serves the read.)
  - Retake: Machine only, with a chamber turning Ready and opened from the box.
  - **Corrected on Faber's facts, the same night: both fixes change.**
    1. **A chamber never holds a ready shard.** It hands the shard to Ready and takes the next one, so the Breaker keeps working while the player is away. That rule stays. The fix becomes Faber's (a) and (b):
       - (a) a Ready chip glows gold, reads "Ready", and opens on one tap of the chip itself;
       - (b) as a shard finishes, its chamber flashes gold "Ready" for about 1.5 s as it hands the shard to the strip, so the payoff shows in the machine.
    2. **A chamber's unlock is the Breaker's own level** (`docs/design.md`, "The base"). The text is "Locked · upgrade the Breaker", with the level once the Breaker's upgrades are seeded.
  - Retake: Machine, with a shard finishing in a chamber (b) and opened from its chip (a).
- **The fixes built, 2026-11-15 (Faber).** Time: about 1.5 active hours, my estimate, not measured.
  - **Implemented.** `UI/BreakerScreen` is Machine only: List, Sheet and `Hud.Breaker.Layout` are gone.
    - (a) A ready shard's chip has a bold gold edge over a gold fill that breathes (`Config.Hud.Breaker.Glow`). "Ready" is its first word, in gold, with the shard's name under it. One tap opens it, into the reveal.
    - (b) A chamber whose shard finishes flashes gold with "Ready" across the box for 1.5 s: held 0.35 s, then fading, with a small pop as it lands (`Config.Hud.Breaker.Flash`, tuned live). The chip it hands over lands lit and settles into its breath. The screen tells a finish from the base as it stands each quarter second, so the flash comes with the shard, whether the server's copy or the screen's own clock sees it first. A shard that finished while the screen was shut doesn't flash: its chip waits, gold.
    - A locked chamber reads "Locked" with "Upgrade the Breaker" under it. Tier 1: the dot is a line break, since a chamber is about 90 px wide.
    - Lever: anticipation is the crack's bar filling, and the payoff is the flash and the hand-off to the strip.
  - **Tested.** The Breaker's cases: 106 passed, 0 failed, 59 fps, in the phone emulation. One is new: a shard finishing flashes its chamber, reaches the strip as a gold chip, and opens on one tap of it (the flash measured at 1.45 to 1.55 s). The screen's case is Machine only and checks each locked chamber's line. The type check: 0 new. Logic offline: 5440 passed.
  - **The retake is recorded, 2026-11-15:** `build/captures/tr9/machine_retake.mkv` (phone size; the action is in its first 30 s), with `retake_sheet.jpg`. The case `Take: TR9, the Breaker in Machine, a shard finishing in its chamber and opened from its chip`: the walk, the prompt, the line's shard and its odds, two chambers finishing in gold, their two gold Ready chips, one tap, the shard, the reveal, and the Breaker again with one chip left.
  - **Visually reviewed:** by Faber on the sheet. The gold chips and the chambers' gold read at phone size. In the sheet's frame of the flash, the chamber already holds the next shard's line, and whether "Ready" reads across it is for the verdict in motion. Research's verdict: not yet. **Director-accepted:** no.
  - **Research's verdict on the retake, 2026-11-15.** Read at 10 fps across the finish (14.4 to 16.4 s), and from the sheet.
    - **Felt:** both chambers turn solid gold and say Ready, and their chips drop into the strip lit. The payoff lands where the work was, then the machine takes the next shard.
    - **Tier:** competent (grey). **The one bold thing:** the gold flash handing over to the chip.
    - **Fix (Faber):** while the gold fades, from about 15.4 to 15.9 s, the next shard's "Chamber 1 · Standard · 29 s left" shows through "Ready", two texts on top of each other. Hold the next shard's words until the gold is gone, then let them in. Serves the read. Check it on a still; no retake.
    - **Research's pass on TR9 is given once that fix is in.** The infusion's numbers, "A little · 300" and "Needs a battery of 900", become kWh with TR18 (20 and 60), and the screen's look is AR12's galaxy room: both are other pieces.
    - **The two names change** (the director, 2026-11-15: "what the f is a little a lot this is childish words let use real electrician words"). "A little" becomes **Low voltage** and "a lot" **High voltage**, each with its price in kWh on its button. An infused shard reads "Infused · Low voltage" or "Infused · High voltage". This goes in with the fix above, and the content check passes the new text.
    - **Then the effect changes** (the director, 2026-11-15, asked: "Faster break"). Voltage buys time, not luck: Low halves the time left, and High breaks the shard at once, priced by the time saved (TR18's numbers). `Config.Shards.Infusion`'s lifts go. A shard it would save under a minute shows no voltage, so a Standard shows none. The button reads its price and what it saves ("High voltage · 60 kWh · breaks now").
    - **"Who it can hold" becomes "Drop rates"** ("drop rate is that simple"). It lists every Voidkin the shard can give, grouped under each rarity's total, to 100% ("it obviously dont contain everything the odd are off").
  - **The fade fix and the names, Faber, 2026-11-15.**
    - **Implemented.** While gold fades over a chamber, what it holds next waits hidden under it: its name, its bar, its time left and its infusion show once the gold is gone (`BreakerScreen.luau`, `cell`). The chamber's own number stays. The levels are Low voltage and High voltage (`LEVELS`), and an infused shard reads "Infused · Low voltage". A button holds its name over its price on two lines: "High voltage · 900" on one line didn't fit the smallest phone's button.
    - **Tested.** The Breaker's cases: 163 passed, 0 failed, 59 fps, the lint clean on the smallest phone. Two checks are new: the next shard's words aren't shown under the gold, and show once it's gone. Type check: 0 new.
    - **Checked on a still:** `build/captures/tr9/gold_fade_still.jpg`, six pictures from 0.3 to 1.9 s after the flash. "Ready" stands alone on the gold, the box is bare for about 0.2 s, then "Standard · 29 s left" comes in. The two-line buttons were read on a frame of their case.
    - **Visually reviewed:** by Faber. Research's pass: not yet. **Director-accepted:** no.
    - **Not built:** voltage as time, its price, and "Drop rates". Until they are, Low and High voltage still lift the odds as the old levels did. Tier 1 notice: the place line reads "· infused, low voltage".
  - **Research's pass on TR9, 2026-11-15:** the fade fix holds on the still. "Ready" stands alone on the gold, the box is bare for a beat, then the next shard comes in. **TR9's Machine and its payoff pass.** The still predates the names ("A little · 300"), and the two-line buttons were read on their case's frame. Voltage as time, its kWh price and "Drop rates" are their own work: Drop rates next, and voltage with TR18. Neither reopens this pass. **Director-accepted:** no.
  - **Drop rates, Faber, 2026-11-15.** In grey, to Modulo's sheet (`build/handoff/UI/hud/colour/vivid3_breaker_ready.png`).
    - **Implemented.**
      - **The rule,** pure: `Rules.Odds.Rates` gives a shard's table grouped by rarity, the commonest first, each chance also in whole hundredths of a percent. They're rounded by largest remainder, so the rows shown add to exactly 100% and a rarity's total is the sum of its rows. `Odds.Percent` writes them ("60%", "6.75%").
      - **The pane:** "Drop rates" is a button beside the shard's one action, one tap away. Lit, it shows every Voidkin under its rarity's total in place of the voltage, a Voidkin a line. A second tap brings the voltage back. It starts closed each time the screen opens.
    - **Tested.** Logic offline: 5552 passed, with a new case on every shard at three lucks (every Voidkin once under its own rarity, the rows adding to 100%, ground 1's Standard by hand). The Breaker's cases: 189 passed, 0 failed, 60 fps, in the phone emulation, the lint clean with the rates open. The take's case: 15 passed. Type check: 0 new.
    - **Checked on a still:** `build/captures/tr9/drop_rates.jpg`: closed with the voltage under it, then open on "Common 60%" and its four at 15%, the list going on under a scroll bar.
    - **Visually reviewed:** by Faber. Research's pass: not yet. **Director-accepted:** no.
    - **For research, built another way than the sheet, with why:**
      1. **"Drop rates" stands beside the action, not under the voltage.** At 44 pt taps the pane's column holds about 150 authored px: the action and two voltage rows fill it, and a button under them would sit below the fold. The sheet's rows are drawn smaller than a tap.
      2. **A Voidkin a line, not two a line.** Half the pane is about 87 authored px, and "Marigold" beside "0.33%" at the kit's caption needs about 93. Five rows show before a scroll.
      3. **It starts closed on every shard,** since today every shard shows voltage rows. With TR18 a shard that takes no voltage can start with its rates open, as the sheet's Standard does.
    - **Tier 1 notice.** A Common's line wears its rarity's grey, dimmer than its Voidkin's numbers under it: the colours are AR12's.
    - **Time:** about 1.5 active hours, my estimate, not measured.
  - **Research's pass on Drop rates, 2026-11-15,** from `drop_rates.jpg`:
    - **Felt:** one tap, and the shard's odds turn into who you can get. Ground 1's Standard reads Common 60% with four at 15% each, as `Rules.Odds` says.
    - **Tier:** works, as a grey block. The logic case holding the rows to 100% is the one bold thing: the list can't lie.
    - **The three ways built differently are accepted:** beside the action, a Voidkin a line, and starting closed until TR18.
    - **Fix 1:** "Drop rates" is information, not the shard's action, yet on a waiting shard it fills the width with the action's lit edge and reads as the thing to press. Make it a secondary button with a small list mark, half the width or less, never with the action's light.
    - **Fix 2:** a rarity's total is its group's heading, but Common's grey makes it dimmer than its own rows. Give each heading the rarity's colour at full strength and a heavier weight, and keep the rows' names ivory.
    - The voltage rows are still the old lift, which goes with TR18.
    - **Director-accepted:** no.
  - **The two fixes built, Faber, 2026-11-15.**
    - **Implemented.** "Drop rates" is a secondary button: half its row whether or not an action stands beside it, three bars of a list left of its word, and no accent's base line (the kit button's new `Quiet` and `Inset`). A rarity heads its rows in its own colour and the kit's heaviest face, Common in a lifted grey (`Config.Hud.Breaker.Tier`). The rows' names are ivory.
    - **Tested.** The Breaker's cases: 191 passed, 0 failed, with a new check on the button (half its row at most, its mark, no base line). The whole self-test: 1729 passed, 0 failed (268 s, 60 fps).
    - **Checked on a still:** `build/captures/tr9/drop_rates.jpg`, taken again. **Visually reviewed:** by Faber. **Director-accepted:** no.

## TR10. The elite's and the keeper's cooldown, with their marker (Faber, Modulo's icons)

Research's entry, 2026-11-14, on the director's words of the same day (`docs/decisions.md`): a cooldown kept by the server before the elite and the keeper come back, and while they're down, their icon, the time left and a small card of their loot with its drop rates. A new piece: TR5 stays as it is.

**Feel line:** when the elite falls, its square keeps its place: its icon hangs over the empty square with the time counting down and what it drops beside it, so you know when to come back and why; the keeper's gate does the same for your own Lamplighter.

**The block contains:**
- **The cooldown, on the server.**
  - The elite: one timer for the whole server, since its fight is shared. It replaces the elite's share of `Config.World` `Respawn`; the packs keep theirs.
  - The keeper: each player's own timer (the director's pick, 2026-11-14), since each player has their own fight. It starts when that player beats him; a lost try can be tried again at once.
  - A rejoin or a server hop never resets a player's keeper timer: it's kept with the player's state.
  - Seeds, tier 2, research's, tuned by playing: the elite 2 minutes, the keeper 5 minutes. Faber checks their effect on the Jewels' pace in `tools/balance/sim.py` before they settle, and brings research the numbers.
- **The marker, while it's down,** in grey first: over the elite's square, and at the keeper's gate for the player whose timer runs.
  - Its icon, the time left as it counts down, and a small card of its loot with each drop's rate.
  - The rates come from `Rules/Drops`, never copied into the UI.
  - Two or three layouts, judged at phone size from the street, near and far.
- **The icons:** the elite's and the Lamplighter's, Modulo's, on the kit, after the verdict on the grey marker.

**Waits:** the other grounds' elites and keepers; the marker's sounds; a marker for packs.

**Checks:** a logic case for each timer (the server's, a player's, a rejoin across it); the self-test for the marker's states; the UI lint on the smallest phone; the content check on the icons and the text; research's verdict on the grey marker, then its pass.

**Order in the queue:** after TR6. **Time, forecast:** the timers and the grey marker about 2 hours, the icons about 1.

**Status:** the timers and the marker built in grey, 2026-11-14 (Faber). Time: about 1.5 active hours, my estimate, not measured.
- **Implemented.**
  - **The elite's timer, the server's:** `Config.World.Row.Back.Elite` (120 s) from its fall, through `Rules.Cooldown`. The packs keep `Row.Respawn` (15 s). PackService writes the server time it's back on the Elite marker (`BackAt`), so every client shows the same time.
  - **The keeper's, each player's:**
    - `Row.Back.Keeper` (300 s) from each win, kept in the save (`Progress.Grounds[ground].Back`, os.time) and written in the win's own step (`Progress.KeeperWon`).
    - A try meanwhile is refused "Resting" (`KeeperService.Try`, `Progress.Resting`). A loss rests nothing.
    - A clock behind the one that set it (another server's) never lengthens it.
  - **The marker, in grey** (`DownController`, client): over the elite's square while its timer runs, and at the keeper's gate while this player's runs, the gate's Challenge hidden for them meanwhile.
    - It shows a stand-in icon (the name's letter on a grey tile), the name and the time counting down.
    - Its card lists Credits, experience and the Standard shard, each with its chance from `Rules.Drops.Card`. `Hud.Chance` writes them: "100%", "14%", "36%", never rounded up.
  - **Three layouts** in `Config.Hud.Down.Layout`, tuned live: "Stack", "Row", and "Badge", whose card shows only within `Near` (60 studs). `Compare` shows the three side by side over the elite's square for one capture.
  - Studio adds `PackBack` (a group that's down stands at once) and `KeeperRest` (this player's keeper resting that many seconds, 0 for back now).
- **Tested.**
  - The type check: 0 new.
  - The logic: 4440 passing offline. New cases cover each timer (the server's, a player's, a rejoin across it), the loot card against Roll's own numbers, and the chance's text.
  - The self-test's new case waits on the Studio MCP, with the UI lint on the smallest phone. It covers the elite down (its marker, time, card and the three layouts), the keeper resting (its marker, the Challenge hidden, a try refused), and both coming back. The four keeper tries in other cases now clear an earlier win's rest first.
- **The numbers** (`tools/balance/sim.py`, section 11). A model, not a measurement: the seeds' kill times, section 9's walks, every pack up when reached, and 10 s for a win's way home and back, my guess.

    | Players on the server | Elite kills an hour | Keeper kills | Both: the Jewels' sources | Income | Standard shards |
    |---|---|---|---|---|---|
    | 1, before | 16.9 | 17.0 | 33.9 | 100% | 20.8 |
    | 1, the seeds | 17.9 | 8.9 | 26.8 | 90% | 18.7 |
    | 4, the seeds | 15.7 | 9.2 | 24.9, from 34.0 | 90% | 18.9 |
    | 8, the seeds | 12.9 | 9.4 | 22.3, from 34.2 | 89% | 18.8 |

  - A lap takes about 3.3 minutes. So the elite's 2 minutes costs a player alone nothing, and costs a full server about a quarter of its elite kills.
  - The keeper's 5 minutes means every other lap: it halves keeper kills. The Jewels' sources fall 21% alone and 35% on a full server; income falls 10%.
  - Waiting out the keeper pays worse than walking back down the street (57 to 61% of the income), so the model walks back.
  - If research wants the keeper every lap, 3 minutes is under a lap. Or the Jewels' drop rate from elites and keepers can make up the cut once Jewels exist. Research's call.
- **Research's read of the Jewels' pace, 2026-11-14, night: the seeds stay, the elite 2 min and the keeper 5.**
  - A cooldown under a lap is one the looping player never sees, and the director asked for the marker so a boss's return is something to come back for.
  - Jewels don't exist yet. Their drop rate from elites and keepers is set against this cadence when they're built, so the cut is made up there (Faber's second option).
  - TR12's trips home lengthen a lap too, so a lap is no fixed figure to tune a timer to.
- **Visually reviewed:** not yet. The three layouts at phone size from the street, near and far, go here once Studio is back, for research's verdict. Modulo's two icons come after it.
- **Accepted:** no.

## TR11. Spectate, a toggle on the HUD (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`): the player's camera is never moved in a fight, and a small button follows the lead instead. "Change it now."

**Feel line:** mid-fight, the player taps a small eye low on the right and the camera glides onto their Voidkin, so they watch its combo and its signature up close; one more tap and it's back on their avatar, as they left it.

**The block contains:**
- **The toggle,** in grey: a small eye beside the signature's ring, a whole 44 px target, lit while on. Off at every join; never a setting.
- **On:** the camera follows the lead, eased in about 0.3 s; the player's drag and zoom work as ever; the avatar still walks, and the lead still follows it.
- **Off, or when the lead falls, or at a move's black fade:** back on the avatar at the distance and angle the player had.
- Two or three places for the eye, judged at phone size in a pack fight and a keeper's try.

**Waits:** the eye's finished look (with TR13's frames); a sound.

**Checks:** a self-test case for each state (on, off, the lead's fall, a fade); the UI lint on the smallest phone; research's verdict in motion at phone size.

**Order in the queue:** after TR5's frames and the shoulder ease's removal (TR7). **Time, forecast:** about 1 hour.

**Status:** built in grey, 2026-11-14 (Faber).
- **Implemented.**
  - `SpectateController` (client). On, Roblox's camera follows a stand-in point, set before the camera each frame and eased from the avatar's focus to the lead's (about 95% in 0.3 s, `Rules.Hud.Approach`). The heading, the zoom and the drag stay the player's. Off, it eases back and hands the camera to the avatar again. It turns off at once when the lead falls or leaves, and at each spawn. In a move's fade, it's back on the avatar the moment the screen is black (`FadeController.OnFade`, with `FadeController.Play` as the server's fade and the tests' entry).
  - The eye: the kit's button at `Theme.Size.Tap` (44 px rendered at the smallest scale), with a stroked almond and a pupil in grey. It's lit (Selected, the accent) while on, and disabled while the lead is down ("Your lead is down"). It always shows, as `docs/ui.md` has it.
  - Its three places are `Config.Hud.Spectate.Place`: "Above", "Left" or "Below" the signature's ring, tuned live. "Above" is the start.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4035 passing offline, with a new case for the ease.
  - The self-test's new case (on, off, a fall, a fade's black, the zoom and the heading kept) waits on the Studio MCP, with TR5's and TR6's.
  - 2026-11-15, in the phone emulation: the case passes, 28 checks. One finding for research's verdict: on a touch screen Roblox's camera follows, and it turned the heading by about 14° on the way to the lead in one run and by 0° in another. With a mouse the heading holds, and the case holds it there. On a touch screen the case now measures the turn instead. The player's camera is left as it is, by the director's word.
- **Visually reviewed:** not yet. The three places, at phone size in a pack fight and a keeper's try, go here once Studio is back, for research's verdict.
- **Accepted:** no.

## TR12. Health carries: Regen, the fall home, the Training machine (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`; the design: `docs/design.md`, "Combat", "Health carries" to "The next lead", and "The base", "The Training machine"). It replaces `Config.Combat.Heal` and the fall's `DownSeconds`.

**Feel line:** on Lantern Row your Voidkin fights on what it carries: each pack leaves a mark and its health creeps back only a little at a time, so you push one more pack or head home. If it falls, it's gone home in a flash of light, and you send out your next fighter while it heals and trains on your plot, waiting for you to come back.

**The block contains:**
1. **Regen** replaces `Combat.Heal`: a value a second, always, in a fight too. In the block it comes from the level (`Rules/Stats`, as a stat with its source), with the Healer's class carrying more. The gear source waits for Regalia's stats.
2. **Healing at home:** on its plot a lead heals to full in about 30 s.
3. **The fall:** the lead leaves as light (the grey stand-in, no body left), is home on its plot, heals to full in about 90 s, and waits there. It follows the player again once the player is on their plot. In a keeper's ring, a fall ends the try.
4. **The next lead:** once the lead has fallen, the player sends out another healthy Voidkin they own, from the lead's card or the Voidkin screen, anywhere out of combat. The fallen one's card shows "healing at home" with its time, then "training".
5. **The Training machine,** in grey (a box with its plate) on the plot: it trains one Voidkin at a time, the one at home without the player, or the lead while the player is offline. A pure rule in `Rules/`, worked out on the server at the next join from the leave time, as the Breaker's and the battery's are. No cap.
6. **The numbers,** through `tools/balance/sim.py` before they settle (tier 2, research's seeds, tuned by playing):
   - Regen: on Regen alone, a lead at its level ends Lantern Row's Pack 2 with between a third and two thirds of its health; it falls before the elite in at most one run in ten.
   - Training: about a third of a fight's experience a minute at its level. Bring research what a night (8 h) and a week away give at levels 1, 5 and 15.

**Waits:** Regen's gear source (Regalia's stats); the machine's model and the training clip; the fall's finished effect; the "at home" card's finished look.

**Checks:** logic cases: Regen in and out of a fight; healing at home; a fall, the trip home and following again; the next lead; training across a leave, a long one included. The self-test for the lead's card states; research's verdict in motion at phone size: a circuit with a fall, the next lead out, and the trip home.

**Order in the queue:** after TR11. It's the loop, so it comes before TR6. **Time, forecast:** 3 to 4 hours, the sim's run included.

**Status:** built in grey, 2026-11-14 (Faber), c0f0478 and 1be04e6. Time: about 4 active hours, my estimate, not measured.
- **Implemented.**
  - **Regen:** a stat from the level (`Config.Stats.Regen`: Base 4 at level 1 times G, a Healer ×1.5, its own "Level" source, so rarity and stars leave it alone). A lead heals it every second, always, in a fight too (`Rules.Fight.Regen`). On its own plot it also heals from nothing to full in `Combat.Lead.Home.Full` (30 s; `Markers.OnPlot`). `Combat.Heal` and `DownSeconds` are gone.
  - **The fall:**
    - The lead is down for `Combat.Lead.Leave` (1.6 s), then leaves as light: a grey column where it lay (`Config.Effects.LeadLeaves`), its prop back in hand.
    - It's home on its plot, 6 studs before the Training machine, and heals from nothing to full in `Lead.Home.Fallen` (90 s).
    - It follows again once it's whole and the player is on their plot (`Rules.Carry.Fallen`). I read "heals slowly to full, then waits" literally: a fallen lead never leaves the plot half healed.
    - In a keeper's ring a fall ends the try, as before.
  - **The next lead:**
    - The lead never changes in a fight: a keeper's try, a target, or a Shade on it (`FightService.InCombat`).
    - A fallen Voidkin goes out again only once it's whole (`Carry.Refusal`, the SetLead guard).
    - A Voidkin taken in keeps its share and heals at home's rates while it isn't out.
    - The card says "Down", then "Healing at home m:ss" with its bar filling, then "Training" or "At home" (`Hud.LeadStatus`).
    - A "Send another" button under the card opens the Voidkin screen. Its rows say "Healing at home m:ss" or "Training", and a refused row says why.
  - **The Training machine,** a grey box and pad on each plot (`Tags.Training`), with its plate:
    - It trains one Voidkin at a time (`Rules.Training.Who`): the lead while the player is away from the plot or offline, a fallen one once it's healed, nobody while the player is home.
    - It earns a fixed rate at any level, with no cap: `Config.Growth.Training.Share` (0.33) of what fighting earns in Lantern Row, 39.2 a minute today (`Rules.Training.Rate`, from `Config.World.Row`'s packs and elite and `Config.Drops.Share`).
    - The server credits it every 30 s in the game, and whenever who trains changes. At a join it credits the lead's time away (`Training.Advance`, `Profile.Training.Stamp`).
  - Studio adds `LeadHeal` (every Voidkin whole, a fallen lead up beside the avatar) and `TrainingSkip`.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4389 passing offline. New cases cover Regen in and out of a fight, healing at home, the carry, the fall's trip home and following again, the next lead's refusals, the training rate and gain, who trains, and a leave (a night, the same night in steps, 400 days reaching the last level, a worker, a clock gone back).
  - The self-test's new case and the two cases updated for the fall home (the keeper's loss, spectate's fall) wait on the Studio MCP. The new case walks the card's states, the button, the Voidkin screen, the next lead out, and the fallen one refused.
- **The numbers** (`tools/balance/sim.py`, sections 9 and 10), on research's read below, applied 2026-11-14 (Faber). A model, not a measurement: the game's own Config, a bare lead, every Shade of a pack on it at once.
  - **Regen 4 with Ordinary Shades' Attack ×0.5** (`Config.Enemies.Ordinary.Attack` 5.735, from 11.47; a brawler now costs a bare Common Warrior 6% of its health, not 12%).
    - A new account ends Pack 2 with 53% [47 to 60%], and 1 to 2 runs in 100 fall before the elite. From level 3: 72 to 74%, none fall.
    - **Lyric, a Healer, falls in 11 runs of 100** at level 1 (51% [44 to 58%]), above the 2 to 3 target: her low health shows before her Regen ×1.5 does. Faber's proposal, tier 2: the Healer's class Regen ×2, or leave it to her own heal once she has one.
    - Before: Regen 20 on the old Shades gave 62% but refilled in 40 s, which missed the feel line.
  - **Training at a fixed 39.2 a minute:** the director's "Fixed rate, no cap". It's 15.9 a kill on average over Lantern Row's packs and elite, at 450 kills an hour, times 0.33.

    | From level | A level here | A night (8 h) | A day | A week |
    |---|---|---|---|---|
    | 1 | 1 min | 13.4 | 20.3 | 34.7 |
    | 5 | 19 min | 13.9 | 20.5 | 34.7 |
    | 15 | 120 min | 18.7 | 22.2 | 35.3 |
    | 30 | 895 min | 30.5 | 31.6 | 39.3 |

    - Level 60, the last, from level 1: 1394 hours in the machine (58 days).
    - A new account's first night reaches level 13, in Drum Court's range; past level 30, a day gives about a level and a half.
    - Waiting on research's read before it settles.
- **Research's read of the numbers, 2026-11-14, night.**
  - **Regen: Ordinary Shades' Attack ×0.5 with Regen 4** (tier 2, research's, with the fights' owner: Faber proposed it).
    - The director's complaint was waiting out a heal after a pack. At 200 s from empty, waiting loses to the door home (30 s), so the choice the feel line names is real.
    - At ×0.6 with Regen 8 (100 s), a minute and a half's wait still refills, and with no falls the fall home is never met early.
    - 2 to 3 falls in 100 before the elite are within the target.
    - Lyric, a Healer, keeps her class's larger Regen.
  - **Training: the director's word, 2026-11-14, night: "Fixed rate, no cap".** Training earns a fixed amount of experience a minute that never grows, a third of what fighting earns in Lantern Row. Each level costs more, so it slows as levels rise. Faber: run it through section 10 and bring research what a night, a day and a week give from levels 1, 5, 15 and 30, before it settles.
  - **Faber's tier 1, a fallen lead follows only once whole and the player is home: agreed.** That's the director's own words.
  - **The fixed rate's table, research's read: settled.** 39.2 a minute: a level costs 1 minute at level 1, 120 at 15, 895 at 30, and the last level takes 58 days in the machine. It's fast at the start and slow at high level, as the director expected. A first night carries a new account about 13 levels, the start of the ground's climb. Gear, shards and the keeper's win still come only from fighting. Retaken in play at the verdict.
  - **Lyric at level 1, 11 falls in 100: no change.** It's one over the line on 100 runs of a model, and she's no starter, so she rarely leads at level 1. Her Regen stays ×1.5, and her own heal comes with her signature (`docs/design.md`, "Voidkin", the Healer). Retaken at the verdict in motion.
- **Visually reviewed: research's verdict in motion, 2026-11-14, night** (`build/scratch/faber/take/tr12_take.mp4`, phone size, at dusk; read at its beats).
  - **Felt:** the lead drops, its card says Down and then "Healing at home 0:24" where its health was, "Send another" sits under it, and a second lead is out and fighting within eight seconds. Later the first one shows as Training without the player doing a thing. The loop never stalls.
  - **Tier:** works (grey).
  - **The bold thing:** the card's own line turning from health to "Healing at home" with its clock. It answers "where did it go, when is it back" in the one place the player already looks.
  - **Fixes (Faber):**
    1. **The fallen card dims,** as `docs/ui.md` "A fallen lead" says. The portrait stays in full colour today, so at a glance the card still reads as fighting. (Serves the read at phone size.)
    2. **Lead keeps its label while it waits.** At 18.3 the button is an empty outlined box for a moment. Show the pressed state with the word in it. (Serves responsiveness.)
  - **Waits, not a fix:** the column the lead leaves as is a flat white slab, the brightest thing on screen, standing beside the electricity bar. It's grey and goes to the effects pass. When it's drawn, it must not outshine the HUD.
  - The 25 s heal and the held health were the take's, not the game's, and they are noted as such.
- **Accepted:** no.

## TR13. The signature's ring, reworked (Faber, with Modulo's frames)

Research's entry, 2026-11-14, night, on the director's word (`docs/decisions.md`): the ring looks cheap and flat. What it does and where it sits stay (TR3, part 5; `docs/ui.md`); its look is new.

**Feel line:** low on the right edge, the lead's signature sits in a jewel of the HUD: its light fills round the class's glyph over the cooldown, empties in a flash as the move fires, and swells once when it's ready, so the big move reads as a charge you can see coming.

**The block contains:**
- Two or three looks in grey at phone size, beside the current ring: depth (a rim, a well under the fill, a light on the fill's leading edge), the ready swell, the empty flash.
- The picked one on Modulo's frames, as TR5's were, with its motion from TR6's kit.
- The spectate eye (TR11) drawn on the same frames.

**Waits:** a sound for the ready swell.

**Checks:** the HUD's self-test and the UI lint; the content check on the frames; research's verdict on the grey looks, then its pass in motion at phone size.

**Order in the queue:** after TR6. **Time, forecast:** about 1 hour in grey, then the frames (Modulo's).

**Status:** the looks in grey built, 2026-11-14 (Faber). Time: under an hour, my estimate, not measured.
- **Implemented:** `UI.RingLooks`, three directions in the HUD's Graphite palette. Each draws the same cooldown state as today's ring.
  - **Rim**, depth on today's ring: a raised rim lit from the top, a sunken well, and a bright head with a glow riding the fill's leading edge. Ready, a pulse rings out from the rim as the light goes white-hot; fired, the well flashes white.
  - **Pool**, the well itself fills from the bottom with a bright line at its level, and the glyph goes dark on the full pool. Ready, a glint crosses it once; fired, it drains in a white flash.
  - **Pips**, the ring in 8 segments that light one by one, the next one filling and larger. Ready, a chase runs round; fired, they all flash and go dark.
  - `Config.Hud.Ring.Look` puts one in the ring's place, with today's ring hidden under it. `Ring.Beside` shows all three in a row left of the ring, named, on the same cooldown, for one capture. Both are tuned live; the defaults leave today's ring alone.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4391 offline (no pure rule here).
  - The self-test's new case (each look through empty, a quarter, half, nearly full, full, the fire, hidden; Rim's head at the foot when half full; Pips' count lit; Pool's level; one look in the ring's place and back) waits on the Studio MCP.
- **Visually reviewed:** not yet. The capture goes here once Studio is back: `Beside` on, at phone size, in a pack fight through a fire and a ready, for research's verdict on the grey looks.
- **Accepted:** no.

## TR14. Speed, and the cap at 125 (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night (`docs/decisions.md`; `docs/design.md`, "Speed"; `docs/balance.md`, "Growth").

**Feel line:** in a pack, you can tell who's leading by how it closes in: the Assassin is on the next Shade before the last one has burst, the Tank plods in heavy, and every lead still keeps up with you on the street.

**The block contains:**
- **Speed** as a stat: each class's walk speed in a fight (seeds: Tank 14, Warrior, Mage and Healer 16, Assassin 19), and a nudge of 1 either way in a Voidkin's own entry (Kirra +1). It replaces the one `Combat.Lead.WalkSpeed`. The catch-up when following stays.
- **The cap at 125:** `Growth.MaxLevel` 125, the same curve on past 60. The launch's pace stays designed to 60, and the training table runs to 125.
- **The numbers:** the sim's kills an hour by class with Speed on, for research, before the seeds settle.

**Waits:** the pace past 60 (with the grounds that reach it).

**Checks:** logic cases (Speed by class and nudge, the cap); research's verdict in motion: Rook and Pip in one pack, and a lead following a running avatar.

**Order in the queue:** with Kirra's install, after "Content as data". **Time, forecast:** about 1 hour.

**Status:** the code built offline, 2026-11-14 (Faber); research's verdict in motion waits on the Studio MCP, with Kirra's install. Time: about 1 active hour, my estimate, not measured.
- **Implemented.**
  - **Speed** (`Config.Stats.Speed`): Tank 14, Warrior, Mage and Healer 16, Assassin 19, and a Voidkin row's own `Speed` nudge, clamped to 1 either way (`Definitions.Voidkin`; Kirra +1, so 20). `Rules.Stats.SpeedOf` puts it in the block. It isn't one of `Stats.Names`, so no item, board or later source adds to it.
  - **The walk:** in a fight a lead walks at its Speed (`FightService`, closing on its slot). Following the avatar, every lead walks `Combat.Lead.FollowWalk` (16, the avatar's own), whatever its Speed, so a Tank never trails and an Assassin never stutters ahead. The catch-up stays for both, never slower than the walk (`Rules.Fight.LeadSpeed`, which replaces `FollowSpeed`). `Combat.Lead.WalkSpeed` is gone. The walk clip already plays at the body's ground speed, so a Tank's stride slows with it.
  - **The cap:** `Growth.MaxLevel` 125, the same curve on (G about 77.4 at 125). A level past 60 takes Mirror Pavilion's kills a level until the grounds that reach those levels are designed. The training machine runs to 125, and ten years in it reach the cap.
- **The sim** (`tools/balance/sim.py`, section 13; a model, not a measurement; the player waits for each pack, an upper bound): Speed changes only the closing and the steps between Shades, about 1.3 to 1.7 s of a 22 s pack. Kills an hour against today's 16: Kirra +1.2%, a Tank −0.8%, Pip and Lyric unchanged, Kirra against a Tank +2.1%. Speed is felt in the pack, not counted.
- **Tested.** The type check: 0 new. The logic: 5272 passing offline. Two new cases: the cap (125, the curve, levels past 60 at the last ground's pace, 60 to 61, the cap resolving), and Speed (every row's class walk and nudge, the same at the cap and every star, Kirra, a Tank, Rook, never from an item or the board, 0 for an enemy). `LeadSpeed` has its cases. Two cases had 60 written in and now read the cap.

## TR15. The stat board: skill points (Faber)

Research's entry, 2026-11-14, night, on the director's words of the same night ("Board now, tree later"; `docs/decisions.md`). The design is `docs/design.md`, "Skill points".

**Feel line:** each level your Voidkin hands you a point, and on its card you choose where it grows: more health to hold, more attack to finish, more regen to last. The gain shows before you tap it, so every level is a small decision of your own.

**The block contains:**
- **The rule,** pure Luau in `Rules/`: one point a level from level 2, each Voidkin's own; four stats (Health, Attack, Defence, Regen), a point sized by `G` at its level; the reset for a little Credits. The server decides every spend and every reset, once each.
- **The share:** the points come out of the own base's 35 (`docs/balance.md`). The split from the sim: an even spread matches today's Voidkin within 2%, and the strongest one-stat spread is no more than about 10% ahead on Lantern Row's circuit.
- **The board, in grey,** on the Voidkin screen: the four stats, the points left, the gain before a tap, the reset with its price. Two layouts, judged at phone size.

**Waits:** the tree; the board's finished look (with the kit); sounds.

**Checks:** logic cases (earning, spending, a repeated or interrupted spend never spends twice, the reset, a level-up mid-screen); the self-test for the board's states; the UI lint; research's verdict on the grey layouts, then its pass.

**Order in the queue:** after TR9. **Time, forecast:** 2 to 3 hours.

**Status:** taken out of the game, 2026-11-14, night, on the director's word: "Remove now, tree later", picked from Faber's restatement ("Take the board off the game. Stats grow from level, stars and gear, as before TR15. Skill points come back later, inside the skill tree you planned. The code stays in git, so nothing is lost."). Out: `Rules/Board` and its logic cases, `Config.Stats.Board`, `Config.Hud.Board`, `Stats.PointGain` and the board's share in `Stats.Resolve`, `SpendPoint` and `ResetPoints` in `Rules/Collection`, the `LeadPoints` command, the board's self-test and take, and the Voidkin screen's board (the plain collection stands until TR17). A save's points go in migration step 3 (`Shared.Data.Migrations`, with its logic case). Kept: the Screen kit's lists keep their scroll across a rebuild (the take's finding; a self-test case holds it). The board's code is at `a2e0036`. `tools/balance/sim.py` section 12 is research's to drop or keep. Time: about 1 active hour for the removal, my estimate, not measured. What follows is the record of what was built.

**Status before, 2026-11-14:** the rule, the save and the board in grey built offline, 2026-11-14 (Faber), and reworked the same night on research's call (c), the board on top. Research's verdict on the layouts waits on the Studio MCP. Time: about 3 active hours, then about 1.5 for the rework, my estimates, not measured.
- **Implemented.**
  - **The rule** (`Rules/Board`, pure): one point a level from level 2 (`Config.Stats.Board`), each Voidkin's own, on Health, Attack, Defence or Regen.
    - **On top of the own base.** Spent evenly at full, each stat gains its `Share` of its own figure, rarity and class in it (`Rules.Stats.Own`), at every level. A stat's points, as a part of those earned, place four times that part of its Share, so every point on one stat adds four times its Share there.
    - **A point waiting adds nothing,** so a Voidkin whose points wait is today's Voidkin and a spent point is a gain. A point's part of the share falls as points pile up, and the figure it's a part of grows with G.
    - More spent than earned (a test's or a tune's) spreads the share over the points spent, so the board never adds more than its share.
    - `SpendPoint { Voidkin, Stat }` and `ResetPoints { Voidkin }` go through `Collection.Actions` on the server, once each by op id. The refusals are NoPoints, Stat, Nothing, Short and Unknown.
    - The reset gives every point back, unspent, for `ResetPerG × G` Credits (57 at level 2, 111 at 9).
  - **The block** (`Rules/Stats`): Base, Stars and Level as they were before the board, and a "Board" line for each stat on top. Stars stay a share of the own base, and points never move them. `Stats.PointGain` is what one more point adds now: the gain the board shows, and what a tap adds.
  - **The save:** each owned Voidkin has `Points`, and migration step 2 gives old saves an empty table.
  - **The screen** (`UI/VoidkinScreen`, out of `HudController`), in two layouts tuned live through `Config.Hud.Board.Layout`:
    - **Split:** the collection beside the chosen Voidkin's board, the lead's first. A tap on a name chooses it. Lead moves onto the board, because the narrow list can't hold a row's detail and a button.
    - **Sheet:** the collection as it was, with Lead on each row. A tap on a name opens its board over it, with Back.
    - **The board:** the name and level, and the points to spend ("No points to spend: each level gives one" at none). Each stat shows as it stands, with its live gain on its button before a tap (a Common Warrior's Health: +43.16 for its first point at level 2, +10.64 at 9). It's greyed, with the gain kept, when no points are left; at level 1 it shows a first point's worth. The reset shows its price, and its first tap asks "Sure?" for 3 s. A row in the collection says "· N to spend".
  - **Studio adds `LeadPoints`** (the lead's spent points, set), for the tests.
- **The sim** (`tools/balance/sim.py`, section 12; a model, not a measurement; a bare lead on one of Lantern Row's packs at its own level):
  - **Worth** of 1% more of each stat there: Health 1.00%, Attack 1.84%, Defence 0.35%, Regen 0.48%. The shares are priced to equal worth: Health ×1, Attack ×0.54, Defence ×2.88, Regen ×2.05.
  - **The shares, seeded:** Health 1.2%, Attack 0.6%, Defence 3.3%, Regen 2.4% (`Config.Stats.Board.Share`). The strongest one-stat lean on Lantern Row is +7.1% over today's Voidkin: Lyric, every point on Regen.
  - **Over today's Voidkin, the same at 5, 9, 30, 60 and 125** (the share is fixed and the pack grows with G; 30 to 125 count no gear, and their grounds aren't built):

    | lead | all Health | all Attack | all Defence | all Regen | even, full |
    |---|---|---|---|---|---|
    | Rook | +4.8% | +4.4% | +4.7% | +4.1% | **+4.6%** |
    | Kirra | +4.8% | +4.4% | +4.2% | +4.2% | **+4.4%** |
    | Pip | +4.8% | +4.4% | +4.2% | +4.1% | **+4.4%** |
    | Lyric | +4.8% | +4.7% | +5.5% | +7.1% | **+5.5%** |

  - **TR12's targets, the board spent evenly at full** (section 9's circuit), for a new account: Pack 2 ends at a median of 53% to 55% (today's Voidkin 51% to 54%), and falls before the elite are 0 to 5 in 100 (today 2 to 9). Both hold. Starting the street at level 3, Pack 2 ends at 73% to 76%, against 72% to 74% without the board, already past two thirds before it.
  - **A level-up never lowers a stat.** With its point waiting, a level-up thins the points spent, and the least a stat rises is +1.4%. A share above 6.7% would let one fall, at level 2 to 3.
- **Tested.**
  - The type check: 0 new. The logic: 5369 passing offline. The board has 8 cases:
    - earning;
    - a point's gain on top, class and rarity in it, the shown gain what a tap adds;
    - nothing spent is today's Voidkin, an even full spend adds each Share and every point on one four times it, for every Voidkin at every level, with stars unmoved;
    - the four stats only;
    - a repeated or interrupted spend;
    - the reset;
    - no spread lowers a stat, and no level-up does with its point waiting (with Defence's share at 10% it fails, checked);
    - the migration.
  - The Stats and Fight cases read today's Voidkin again.
  - The self-test's case waits on the Studio MCP. It covers both layouts at both scales with the UI lint; a tap spent once and the lead in the world growing by the gain its button showed; a level gained mid-screen; every point spent; the reset when short, at its price, with "Sure?" lapsing, and on two taps. TR12's case finds Lead in either layout.
  - **The content check** on the screen's text: PASS, and the rework changes no text. Its note is done: a refusal with no line of its own says "Not now", and the output names its code.
- **For research, tier 2:** the shares, and showing a first point's worth on the greyed board at level 1.
- **One finding, from the first build** (a point `Point × G`, out of the own base): on Lantern Row the board was felt as "which number grows" more than as power. A Voidkin has 8 points by level 9, each about 0.75% of a stat.
- **Research's call on the seeds, 2026-11-14, night (tier 2).**
  - **The finding decides it: the board must be felt where the launch is played.** Launch is Lantern Row, levels 1 to 9, with training past it. A point worth 0.75%, with the strongest lean at +1.2%, makes the director's choice invisible there, and 1.3× doesn't change that.
  - **The cause is the shape, not the scale.** The slice the board takes grows with the count of points, so at 125 it eats the leanest stat's base, and that ceiling holds every level down.
  - **The change: the board holds a fixed share of each stat's own base at every level.** The points spread that share. A point's gain is worth more early and less as points pile up, and the screen keeps showing it live before a tap. Nothing then runs out at 125.
  - **Seed the share with the sim** so the strongest one-stat lean on Lantern Row's circuit is about +7% (the bound stays 10%) and an even spread stays within 2% of today's Voidkin. Bring research the share and section 12's table at levels 5, 9, 30, 60 and 125.
  - **The weights' pricing to equal worth, ResetPerG 50, Lead on the board in Split, and the reset's two taps: accepted.**
- **Research's call on an unspent point, 2026-11-14, night (tier 2).** Faber's shares (Health 5.8%, Attack 3.1%, Defence 16.7%, Regen 11.9%; the strongest lean +7.1%, Lyric on Regen) asked (a) an unspent point adds nothing, a lead 20.4% weaker at none spent, or (b) it counts as an even spread until spent.
  - **Neither: (c) the board adds on top.** Under (a) a level-up makes the lead weaker inside the first pack. Under (b) a tap is a trade, and the screen's "+9.26" is half a lie. The director asked for points that "upgrade their stats", so a spent point is a gain and a waiting point is today's Voidkin. This retires my own "no free power" line (`docs/design.md`, "Skill points"; `docs/balance.md`, "Where power comes from").
  - **The own base is the Voidkin's own, class and rarity in it,** as Faber read it. The design line now says so.
  - **The seeds:** scale the shares so the strongest one-stat lean on Lantern Row is about +7% over today's Voidkin (the bound stays 10%). Then check TR12's targets with the board spent evenly at full: Pack 2 ends between a third and two thirds of health, and falls before the elite stay at most 1 in 10. If they miss, the shares come down, not the enemies. Bring section 12's table at 5, 9, 30, 60 and 125, with an even spender's gain.
  - **The reset** returns every point unspent, at its price.
- **Research's read of the reworked seeds, 2026-11-14, night (tier 2): accepted.**
  - **The shares stand:** Health 1.2%, Attack 0.6%, Defence 3.3% and Regen 2.4%, with the strongest lean at +7.1% and an even spender at +4.4 to +5.5%. They meet the call. TR12's targets hold with the board spent evenly at full: Pack 2 ends at 53 to 55%, and 0 to 5 in 100 fall before the elite. The same table at every level is what a fixed share should give.
  - **The thinning stands, with its guard.** A level-up with its point waiting never lowers a stat (it rises at least +1.4%), and the logic case stops any share above 6.7%. The screen must show a stat as it stands after the level, never a number that drops.
  - **Faber's call, the greyed board at level 1 showing a first point's worth:** accepted. It teaches the board before it's earned.
  - **Still to judge in motion,** once the MCP is back: whether +7% is felt on Lantern Row's circuit, in Split and Sheet at phone size.

## TR16. Alone after a fall: the way home (Faber)

Research's entry, 2026-11-14, night, from Faber's "what I'd change" on the Now board (tier 2, research and UI; `docs/design.md`, "A fall sends it home", "The next lead"). A first-session player often owns one Voidkin. When it falls, "the next lead" has no one to send, and the player stands alone on Lantern Row with nothing to do and no reason given.

**Feel line:** a player whose only Voidkin falls sees its card say it's healing at home, with one chip under it, "Go home", and a thin trail on the street to the gate's Festival Door, so they walk back knowing why, and find it training or ready when they arrive.

**The block contains:**
- **When:** the lead falls and no other Voidkin the player owns is ready to lead. With a second one ready, "the next lead" stands as built and nothing here shows.
- **The chip,** in grey, under the fallen card (`docs/ui.md`, "A fallen lead"): "Go home", a whole 44 px target. A tap draws the trail; it never moves the player.
- **The trail,** in grey: a thin line on the ground from the avatar to the nearest Festival Door twin, at the gate. Gone at the door, at the lead's return, or on a second tap.
- **Shades** treat the lone avatar as they do today. Nothing new is designed for them here.

**Waits:** the trail's look, past grey (the HUD's shared finish); a chip for anything else.

**Done when:** a logic case covers when the chip shows (one Voidkin fallen, none ready; none when a second is ready; gone at the lead's return). The self-test covers the chip at both scales with the UI lint, and the trail from the elite's square to the door. Research's verdict in motion at phone size.

**Status:** built offline, 2026-11-14 (Faber); the self-test and research's verdict in motion wait on the Studio MCP. Time: about 1.5 active hours, my estimate, not measured.

**Scrapped by the director, 2026-11-15, night** (`docs/decisions.md`): "Go home" and its trail go. The way home becomes a HUD control that teleports to the base, on a short cooldown, out of combat, a boss's area and an event only. That is a new piece with its own feel line, from research. Faber: don't spend more on TR16's chip or trail. **The new piece is TR19**, the dock's Base tile. Its chip, trail, rule and cases were taken away in TR19's build (Faber, 2026-11-15).
- **Implemented.**
  - **When** (`Rules.Hud.AfterFall`, pure): a fallen lead's card offers "Send" while another Voidkin could lead now (`Hud.LeadReason` refuses it nothing), else "Home" while the player is out in a ground, else nothing. "Out in a ground" is the night's own line (`Rules.Night.Inside`, 24 studs short of the gate), never during a keeper's try.
  - **The chips share one place under the card,** and only one shows. "Send another" now shows only when someone could go out (tier 1): a Voidkin at work can't lead, so before this it showed a button that sent no one.
  - **"Go home"** (`HudController`): the kit's grey button, 180 by a whole tap, lit while the trail is drawn. A tap draws the trail and a second clears it. It never moves the player.
  - **The trail** (`Rules.WayHome`, pure; `Controllers.Main.WayHomeController`): a thin light-grey line on the floor from the avatar to the home door, redrawn as the avatar walks. The street is a straight walled lane, so the line runs straight to the door; from the elite's square, wider than the street, it first steps square into the lane, 4 studs in from the stall fronts. It's gone within 6 studs of the door, out of the ground, at a respawn, on a second tap, and when the card stops offering it. Its numbers are `Config.Hud.WayHome`, tuned live.
  - **The world** (`WorldService`) writes the door's point and the street (`HomeDoor`, `Street`) on its folder, which never streams out. One ground today, so one door; a second ground's door joins the folder with it.
  - **Studio adds `VoidkinFallen`** (`LeadService`): every Voidkin but the lead fallen just now, so a lead falls alone on an account that owns several. `LeadHeal` makes them whole again.
- **Tested.** The type check: 0 new. The logic: 5414 passing offline. Two new cases (`Cases/WayHome`):
  - When the chip shows: one fallen out in a ground, none at the base, the next lead with a second ready, healing, healed, at work, among several, and gone at the lead's return.
  - The route on Lantern Row's own geometry: from the square's middle, its two edges and the landing, on the floor, inside the street, ending at the door; the reach at the door.
  - Each bites: with the base check or the lane's clamp removed, five checks fail.
- **The content check:** PASS on "Go home" and on the grey trail (rules 2 to 4), judged from the code; its look on screen is research's verdict.
- **Waiting on the MCP.** The self-test case is written ("HUD: TR16"): the chip under the card and never the next's, at both scales with the UI lint, the trail from the elite's square to the door, following a walk, cleared on a second tap, gone at the door and at the lead's return. Then research's verdict in motion at phone size.
- **Research's verdict in motion, 2026-11-14, night** (`build/scratch/faber/take/tr16_take.mp4`, phone size, at dusk; read at its beats).
  - **Felt:** the chip arrives in the right place and says the right thing. But after the tap, nothing in view answers for about five seconds. The trail starts under the avatar and runs behind the camera, under the Voidkin and Base buttons, so the tap reads as a dead button until the walk turns round.
  - **Tier:** the chip works; the trail doesn't yet.
  - **The bold thing:** "Go home" in "Send another"'s place. After a fall, the one place to look always says what to do next.
  - **Fix, round 1 (Faber): the tap is answered in view, at once.** The camera is never moved (the director's word), so the answer is in the world:
    - chevrons flow along the trail toward the door, so even the sliver at the screen's bottom reads as "this way, back";
    - for about 2 s after the tap, an arrow stands over the avatar's head, pointing along the trail's first leg.
    - Judge it from the same take's start. The test: the player knows which way to turn within half a second of the tap.
  - **The Brawlers idling beside the lone avatar:** as designed ("Shades treat the lone avatar as they do today"). No change.

## TR17. The Voidkin screen, remade (Faber, then Modulo's look)

Research's entry, 2026-11-14, night, on the director's word of the same night (`docs/decisions.md`: "it need to looks insanely good like ammorpg character but for each voidkin ... to make it easy"; then "Next, now"). It replaces the collection screen built through TR15, and it's `docs/ui.md`'s screens 4 and 5 at the bar. The study: `docs/research/voidkin-screen.md`.

**Feel line:** a player opens one Voidkin and it stands there full size, alive in its own light, turning under their thumb, its power at its feet and everything about it one tap to the side. A character you want to show off, not a list you scroll, and the next one a swipe away.

**The block contains,** in grey, at phone size, in three layouts to judge in motion:
- **Stage:** the figure on the left half, the panel on the right with its tabs along the top, the portrait strip along the bottom.
- **Flank:** the figure in the middle, the kit's three icons in a column on one side and the stars on the other, and the panel sliding in from the right on a tap, the figure easing left to make room.
- **Rail:** the portraits in a column on the left edge, the figure left of centre, the panel on the right.
- **In all three:**
  - the Voidkin's own model, live, playing Idle at about 70% of the screen's height; a drag turns it, and a tap plays the end of its Reveal;
  - a grey stage whose light takes the rarity and whose floor glow takes the element (stand-in colours);
  - Combat Power at its feet;
  - the panel's tabs, Overview, Stats, Kit and Stars, on real data;
  - Lead (or Leading) and Send to work, always in view;
  - favourite, lock and rename beside the name;
  - switching by the strip and by a swipe on the figure.
- The dock's Voidkin opens the lead's screen.

**The director's layout, 2026-11-15, "change it now"** (`docs/decisions.md`): "the ui of the voidkin should be the FULL SCREEN and dont forget it need to showe the gears slot just like taichi panda dragon all the menu button on the left like taichi panda for each voidkins and the voidskins selection scroll bar below". It replaces Stage, Flank and Rail: their takes aren't recorded. The block is rebuilt to it, in grey:
- **Full screen:** the screen covers the world and the HUD. A thin top bar: back and the screen's name on the left, the currencies on the right.
- **The menu, a thin rail on the far left** (the director, 2026-11-15, "change it now": "much smaller and more like a line with a circle of the button welll made like art"): a thin line with the pages as round buttons on it (the list is in the notes below). Only the chosen page's word shows, at the kit's smallest text (AR12). The selected one is larger and lit, and opens its page in the panel on the right. Drawn circles may be smaller than 44 pt; the tap area stays 44.
- **The figure with its gear slots:** the figure stands left of centre, between two columns of six slots, the twelve shared, made bigger (the director, 2026-11-15). Main Hand and Off Hand, its class's pair, sit at the figure's feet, one each side of Combat Power. All are the slots of the preset this Voidkin is linked to (`docs/design.md`, "Presets"). Gear stays the account's, and "for each Voidkin" is the link that's already designed. The slots are empty and grey until gear is built. Combat Power sits at its feet, between the columns (`docs/design.md`, "Combat Power").
- **The Voidkin strip along the bottom,** scrolling. A swipe on the figure still switches.
- **The director's notes on the mock, 2026-11-15,** in now, with every later note on this screen until TR17 closes ("Now, and later notes too"):
  - space between every gear slot;
  - the right panel is the bag: the player's whole inventory, with tabs by kind (`docs/design.md`, "The bag");
  - Overview holds the selected Voidkin's whole stat sheet, with its facts;
  - the rail holds every page: Overview, the bag, Kit, Stars, Forge, Jewels and War Emblems. A system not built yet shows its button greyed with "Soon", never an empty page;
  - Regalia's screen is merged here, so the dock loses Regalia (`docs/ui.md`, screen 5);
  - Legendary gear changes its border only, with no crown (`docs/research/gear-icons.md`, DESIGN).
  - Lead and Send to work move out of the right panel ("the lend and send to work should be moved elsewhere"). Research's placement, to judge in the take: the top bar, right of the name, Lead filled in the room's colour and Send to work beside it. Favourite, lock and rename stay small by the name.
  - The level's text gets a designed mark, not a plain "Lv 12" ("also the levels text design of voidkin need to change", to Modulo). It's drawn in the mock first.
- **Kept from the block:** the live figure, the drag to turn, the tap's flourish, the stage's light by rarity and element, the real data in each page, Lead and Send to work in view (now in the top bar), and favourite, lock and rename by the name.
- **The figure** fills the stage between the top bar and the strip, and the aim of 70% of the height is dropped, since the strip came after it (research, 2026-11-15, on Modulo's mock, AR12).
- **Watch, at phone landscape:** six slots a column over the strip leaves about 38 pt a slot (the reference's are about 12% of the screen's height, about 46 pt; `docs/research/voidkin-screen.md`, 10). The block shows whether they hold. If they don't, a tap anywhere on a column opens the gear page. Taps stay 44 pt.
- **Done when:** one take at phone size (open, turn, tap, three switches by the strip and by a swipe, each menu button, Lead and Send to work), then research's verdict in motion. Modulo's vivid mock of this layout (AR12) is judged beside it.

**Waits:** the look (Modulo, with Faber, after the pick); sorting, filtering and comparing two; another player's view of your lead; the skill tree; evolution.

**Done when:** a take per layout at phone size: open from the dock, turn the figure, tap it, switch three Voidkin by the strip and by a swipe, each tab, and Lead and Send to work once each. Then research's verdict in motion and the director's pick. The UI lint runs first, at both scales.

**Status:** research's three fixes and the band are built, and the retake is with research ("The retake" below). Before: rebuilt to the director's layout, with the notes on the mock in. Faber, 2026-11-15.
- **Implemented.** `src/client/UI/VoidkinScreen/init.luau`, a full screen through the kit's `Screen.Full`: a cover on its own layer hides the world and the HUD and takes their taps, and Back is at the top left. Its numbers are in `Config.Hud.Voidkin`. Stage, Flank, Rail and `Hud.Voidkin.Layout` are gone.
  - **The rail:** seven round buttons on a line. Overview, Bag, Kit and Stars open their page. Forge, Jewels and War Emblems are greyed with "Soon": a tap says so and the page stays. Only the chosen page's word shows. Circles 26 and 42 across, taps 68 by 52 authored.
  - **The stage:** the live figure between two columns of six slots, 6 apart, the twelve shared in the order of `Definitions.Gear` (new, with its logic cases). Main Hand and Off Hand, its class's pair, stand either side of Combat Power. A tap on a column says gear isn't built.
  - **The top bar over the panel:** the currencies, then Lead, filled, and Send to work on a line of their own.
  - **The panel:** the name with favourite, lock and rename, then the chosen page. Overview is its facts and its whole stat sheet, straight under its level. Bag is the inventory with a tab per kind: Shards from the save, and Items, Emblems, Jewels and Stones greyed "soon". A cell is a shard with its count, and a tap names it. Kit and Stars are as before.
  - **The strip** under the stage. A flick, a drag and a tap on the figure are as before. The dock is Voidkin, Base, Map.
  - Rename stores the name raw: the server passes it through Roblox's filter before keeping it (`TextFilterService`). A nickname the filter changes is refused, and the Voidkin keeps its name. Favourite and lock: `Collection.SetMark`.
- **Combat Power.** The director, mid-build, 2026-11-14, night: "combat power need to really look like taichi panda dragon hunter in design but like us visually". It covers Combat Power's display. The block holds its structure in grey: a plate in its rarity's light that fades out at both ends, an emblem, the caption and large digits. When it rises, the digits count up and the gain floats off the plate (`Config.Hud.Voidkin.Power`). For research: that reference's Combat Power, studied for Modulo's look after the pick. The number is `Rules.Stats.Power` on stand-in weights (`Config.Stats.Power`). Tier 2: research's seeds replace them.
- **Measured,** in this window (750 by 401) and then on the smallest phone:
  - the figure's share of the screen's height: 0.56 and 0.55 (the mock's 0.62);
  - a slot: 38.5 and 28.9 rendered px, 36 and 34 authored (the mock's 40, the reference's about 46);
  - a hand: 49.2 and 39.1 rendered px (the mock's 46);
  - Combat Power's plate: 107 and 85 authored px wide;
  - the rail's seven taps need 375 authored px, and its window has 247 and 234.
- **Tested.** The case `Voidkin screen (TR17)` in `SelfTestController/VoidkinCases.luau`: 217 passed, 0 failed, 58 fps, with the UI lint clean in this window and on the smallest phone on each built page. The take's case: 21 passed. Logic offline: 5513 passed. Type check: 0 new.
  - **The whole self-test, 2026-11-15, in the phone emulation with Studio in front:** 1660 passed, 0 failed (259 s, 60 fps). It's the clean whole pass that was owed.
- **The take:** `build/captures/tr17/full_take.mkv` (60 s, phone size, the take starting about 3 s in), with `sheet_a.jpg` and `sheet_b.jpg`. The case `Take: TR17`: the dock, the lead's screen, a turn, a tap, the strip twice, a flick each way, a column's tap, the rail's Bag, Kit and Stars, the rail dragged to Forge, Jewels and War Emblems, Overview, Lead, Send to work, Back. Not played: the drag, the flicks, the rail's taps and its scroll are the test's own calls.
- **Visually reviewed:** by Faber on the sheets. Research's verdict: not yet. **Director-accepted:** no.
- **For research, from the build:**
  1. Seven 44 pt taps don't fit the rail, so it scrolls. The four built pages stand whole before any scroll, and Forge peeks at its foot. Fewer buttons, or the three not built as one, would need no scroll.
  2. Lead and Send to work stand on a line of their own over the name, not right of it. The panel's column is about 300 authored px, and the name, three marks and two actions at 44 pt need about 560.
  3. The mock holds its top row in Roblox's top-bar band, which the screens' room leaves out today (54 of 375 authored px). A full screen with its bar in that band gives the panel about 60 px more and the rail one more button. It changes the Screen kit and the lint's safe area, and isn't built.
  4. The panel's page is about 139 authored px tall under the name's row: Overview shows its type, its level and its first stat before a scroll.
  5. The name has about 75 px beside its three marks, so its second line truncates.
  6. The screen's name stands over the stage and touches a tall figure (Lyric's prop, the stand-in's arm). The mock has the Voidkin's name there, and no screen name.
  7. A lead's two actions both read "Leading": the kit shows on a button's face why it's off.
  8. The screen opens on the lead's Overview. "The right panel is the bag" could mean the bag first: research's to say.
  9. The bag holds shards only and shows no count of its space: no capacity is designed yet.
  10. Combat Power's weights are stand-ins (tier 2).
- **Tier 1 notices.** A fresh open starts on the lead's Overview. Overview's stat sheet comes before "Now" and the gear line. A bag cell's mark takes the light of the Voidkin its shard holds. A nickname holds at most 20 characters (`Config.Voidkin.Nickname`, from `docs/ui.md`).
- **Time:** about 3 active hours for the three layouts, then about 4 for the rebuild and the notes, my estimates, not measured.
- **Research's verdict in motion, 2026-11-15.** From `full_take.mkv`, cropped to the phone: the open at 4 fps, two switches at 8 fps (13.5 to 15.5 s, 18.5 to 20.5 s), and both sheets.
  - **Felt:** a character sheet you flip through. Every Voidkin turns on its stage with its number at its feet, and the panel answers at once. But in grey the stage is boxed in by its columns, and the name is said twice.
  - **Tier:** works (grey). **The one bold thing:** the live figure between its gear columns, with Combat Power at its feet. It's the reason to open the screen, and it reads at phone size.
  - **Fixes (Faber):**
    1. **Never an empty stage.** On a switch, the stage stands empty under its circle for about 0.25 s (13.9 to 14.1 s) before the figure pops in, while the panel has already changed. Keep the old figure until the new one is ready, then change both in one beat. Serves responsiveness.
    2. **The Voidkin's name over the stage, where "Voidkin" stands.** Use one line, with its rarity in its colour (`docs/ui.md`, rule 3), and favourite, lock and rename as small marks beside it at 44 pt taps. The panel loses its name row and the truncated "Epic · Enduran…" line, which repeats the line under it. This answers findings 4, 5 and 6: the page gains the row, and the figure stands under the name. Serves the mock and the read.
    3. **A disabled button says why** (`docs/ui.md`, rule 4). The lead shows Lead lit as "Leading", and Send to work greyed with "not while leading" under it, not "Leading" twice. Serves the read.
  - **Faber's questions, research's calls:**
    - **1 and 3, the rail.** Take the band. The top bar (Back, the currencies) moves into Roblox's top-bar band, right of Roblox's own buttons, and Back leaves the rail's column. The rail then holds the seven 44 pt taps whole, with no scroll, since the director asked for every page on it. If a few points are still short, tighten the gaps between the circles, never the taps. It's a Screen kit change, so the lint's safe area moves with it. The technique is Faber's.
    - **2.** Lead and Send to work on their own line over the panel: accepted, as built.
    - **4 and 8. The screen opens on the bag.** The director's words were "the stats should instead be the players inventory": the panel that showed the stats now shows the bag. Overview is one tap away on the rail. This is research's reading, and the director can turn it around.
    - **9.** No count of the bag's space, since no capacity is designed. It's an open question, not built.
    - **10.** Combat Power's weights: research's seeds are owed (tier 2), and stand-ins stay until then. Pip, a Common at level 12, shows 32,151 over Ironhymn, an Epic at level 8, at 27,433. The seeds must make rarity count for more than four levels.
  - **Not judged:** the look (Modulo's mock and AR12's colour), the slots' art, and the level's mark (the director's later note).
  - **Retake:** the three fixes and the band, with one switch at 8 fps and the rail whole on the smallest phone.
- **The retake, Faber, 2026-11-15.** Research's three fixes, the band and the bag first.
  - **Implemented.**
    - **The band.** A new layer, `Band`, in Roblox's top-bar band, right of Roblox's own buttons (`GuiService.TopbarInset`; `UI/Layers.luau`, `Kit/Screen.luau`: `Screen.Band`, `Screen.BandLeft`). A full screen holds Back, the three marks and the currencies there. The lint's safe area moved with it.
    - **Fix 1, never an empty stage.** A switch asked before a body can be drawn keeps the one shown with its panel, lights the asked cell on the strip at once, and changes both in one beat once it's ready (`VoidkinScreen.Choose`, `Figure.Warm`, `Figure.Ready`).
    - **Fix 2, the name over the stage:** one line, its rarity in its colour, where "Voidkin" stood. The panel's name row is gone. Favourite, lock and rename are 44 pt marks in the band, right of Back.
    - **Fix 3.** The lead's Lead reads "Leading", lit, and Send to work is greyed with "Not while leading" under it (the kit button's `Under`; `Rules.Hud.WorkReason`).
    - The screen opens on the bag.
  - **Measured.**
    - **Fix 1's cause is the renderer, not the fetch.** `PreloadAsync` on a body ends in about 0.01 s with every mesh fetched, and its first draw in a viewport still stood empty for 0.25 to 0.53 s, then grey for a frame. The engine readies a mesh only once something draws it, and gives no signal. So the stage has wings: a viewport 8 px a side where each of the roster's first twelve bodies is drawn ahead at the open. A body counts ready 0.8 s after it stands there (`Config.Hud.Voidkin.Figure.Draw`; the dev PC's measure, no phone measured). At worst a switch waits about 0.8 s after the open, with its cell lit.
    - **The rail isn't whole on the smallest phone.** Seven 44 pt taps need 308 pt. Under the band the phone emulation leaves 343 pt (whole, no scroll), a 360 pt phone 302 pt, and the smallest phone 262 pt. No gap is left to tighten: the taps touch.
    - The figure's share of the height: 0.51 and 0.49 (it was 0.56 and 0.55). The name's line takes 24 authored px over the crown.
    - The name's line: 178 and 153 authored px wide, so a long name is cut on the smallest phone. The smallest phone's band is 475 authored px, and the battery drops its capacity there.
  - **Tested.** The case `Voidkin screen (TR17)`: 255 or 256 passed by the run, 0 failed, the lint clean in this window and on the smallest phone. It holds a body back, asks for it, and checks the figure and the name kept, the asked cell lit, then both changed. The retake's case: 14 passed. The whole self-test, in the phone emulation with Studio in front: 1699 passed, 0 failed (266 s, 60 fps). Type check: 0 new. Logic offline: 5513 passed.
  - **The take:** `build/captures/tr17/retake.mkv` (44 s, phone size, its zero at 4.55 s), with `retake_switch.jpg` (three switches at 8 fps from 0.125 s before each tap: the next figure is whole on the first frame it shows) and `retake_views.jpg` (the lead's screen, favourite lit, lock lit, rename with the phone's keyboard, the smallest phone's room, its rail at its foot). The case `Take: TR17's retake`.
  - **Visually reviewed:** by Faber on both sheets. Research's verdict on the retake: not yet. **Director-accepted:** no.
  - **For research, two calls built another way, with why:**
    1. **The rail scrolls on phones under 366 pt tall,** the four built pages whole before any scroll. The other way to no scroll: the three pages not built as small greyed dots under one "Soon", with no tap, until they're built.
    2. **The marks are in the band, not beside the name.** Between the slot columns the name's line has 153 to 178 authored px, and three 44 pt marks alone take about 150. In the band they stand right of Back, as the mock's top row.
  - **Tier 1 notices.** The currencies' chips are sized to their numbers. The favourite's grey glyph reads as a burst more than a star (the icons are Modulo's).
  - **Time:** about 4 active hours, my estimate, not measured. About half went to fix 1's cause.
  - **Research's verdict on the retake, 2026-11-15**, from `retake_switch.jpg` (three switches at 8 fps) and `retake_views.jpg`:
    - **Felt:** you flip through your Voidkin and each one is simply there, whole on its first frame, its name and rarity over its head. The band gives the stage back its height.
    - **Tier:** competent (grey). **The one bold thing:** still the live figure between its columns, now named over its head.
    - **The three fixes hold.** No empty stage on any of the three switches. The name is over the stage in its rarity's colour. "Leading" and "Not while leading" say why, and so does "Every bay is busy".
    - **Both of Faber's ways: accepted.**
      - **The rail scrolls under 366 pt.** The four built pages stay whole, and the "Soon" pages are the ones that scroll. Folding them into dots would hide what the director asked to see.
      - **The marks in the band, right of Back,** as the mock's top row. Rename's Save and Cancel take the band while the field is open.
    - **Fix (Faber), small:** the bag's tab row cuts its third tab mid-word ("Embler"). Make every tab fit, or let the row scroll with a fade at its edge. Serves the read. Check it on a still.
    - **Research's pass on the block is given once that's in.** TR17 stays open for its look, with Modulo's mock and AR12's colour (the level's mark included), then the director's eye.
  - **The tabs' fix, Faber, 2026-11-15.**
    - **Implemented.** The bag's five tabs stand whole in a row that no longer scrolls. Each is as wide as its name's share of the row, never under a 44 pt tap on the smallest phone, 2 px apart. A tab not built yet keeps its name, greyed, with "Soon" under it, as the rail's pages do (`VoidkinScreen/init.luau`, `bagTabs`).
    - **Tested.** The case `Voidkin screen (TR17)`: 257 passed, 0 failed, the lint clean in this window and on the smallest phone. One check is new: every tab whole in its row, none cut. The whole self-test, in the phone emulation with Studio in front: 1727 passed, 0 failed (265 s, 60 fps).
    - **Checked on a still:** `build/captures/tr17/retake_tabs.jpg`, the bag in the phone emulation and on the smallest phone: Shards, Items, Emblems, Jewels and Stones, each whole.
    - **Visually reviewed:** by Faber. Research's pass on the block: not yet. **Director-accepted:** no.
    - **Research's pass, 2026-11-15,** from `retake_tabs.jpg`, on the four phone sizes: the five tabs stand whole, and "Soon" greys a tab as it greys a page. **The tabs' fix holds, and the block passes.** One fix follows the director's word of today: the page is now "Items" (the dock's button is "Inventory"), so its gear tab can't also say Items. That tab reads **"Gear"**. Still open in TR17, and not part of this fix: Lead and Send to work move out of the right panel. **Director-accepted:** no.
    - **Built, Faber, 2026-11-15:** the Bag page reads "Items" on the rail, and its gear tab reads "Gear" (`VoidkinScreen/init.luau`, `SAID` and `KINDS`). Its case passes with a check on both words. No still.

- **Modulo's marks, delivered, 2026-11-15** (the director to Modulo, 2026-11-15, on the HUD's icons: "You made such high quality icons good job, do we need more? if yes please make more"). In `build/handoff/UI/voidkin/marks/`: `images/` (16), `voidkin_marks.json` and the sheet `voidkin_marks.png`, drawn by `tools/blender/voidkin_marks.py`.
  - **The rail's seven pages,** white, to tint by state: Overview (a head over its shoulders), Bag (a satchel), Kit (an ability's tile, a spark cut through it), Stars (one star and the next), Forge (an anvil), Jewels (a cut stone), War Emblems (a banner hung from its bar). Each is judged at 14 pt across, its size on a rail button at rest.
  - **Favourite, lock, rename:** a round heart, filled and in outline (the Healer's class mark is a cut heart and the Stars page is a star, so favourite is neither); a padlock, closed and open; a pencil over its line. Drawn at 16 pt in a 44 pt tap, and they work the same in the band.
  - **The level's mark** (the director, 2026-11-15: "also the levels text design of voidkin need to change"): a plate that leans as the bars do, a lit cap at its left with two rising chevrons dark on it, then "Lv" small and the number large. Three images (body, light, chevrons); it stretches with the number, shown at 3, 12 and 100.
  - **Combat Power's emblem,** the one image in colour: three shards rising from one foot, the middle one white-hot, in the Voidkin's lavender.
  - **For research, to rule:** the favourite's heart is lit in the Map's rose on the sheet, the one warm mark on the name's line; the room's lavender is the other way. Combat Power is shards, not a weapon.
  - **For Faber:** each image's tint and the plate's `cut` are in the json. Nothing is uploaded. The mock's rail (`hud_colour_sheet.py`, `rail`) now gives the chosen page's word its room (the pages after it stand 16 pt lower) and greys a page not built.
  - **Made:** yes. **Self-reviewed:** at 48, 24 and 14 pt on dark, in ink on a pale ground, and in place. **Content check:** PASS for delivery; before the upload it wants each exact file at 128 and 64 px over dark, the two plates alone. **Research's verdict:** not yet. **Director-accepted:** no. **Time:** about 1 active hour, my estimate, not measured.
  - **Research's verdict on the marks, 2026-11-15**, from `voidkin_marks.png` at 48, 24 and 14 pt and in place:
    - **Felt:** one family. The rail reads as seven distinct pages at 14 pt, and the chosen one's lit ring says where you are.
    - **Tier:** competent. **The one bold thing:** Combat Power as three rising shards, the middle one white-hot. Power is what you broke out of the void, not a borrowed sword.
    - **Rulings:**
      - **The favourite's heart is lit in rose,** accepted. It's a mark, not a room. It stays the only rose on this screen, and never on a portrait or an item frame (AR12's rule).
      - **Combat Power as shards,** accepted.
    - **The level's mark** (the director's note) passes: a leaning plate, the chevrons and a large number.
    - No fix. Faber builds from the json. The upload check wants each file at 128 and 64 px, as the content check says.
    - **"Do we need more?"** Yes, in this order, each when the screen that uses it is built: the bag's tab marks (Shards, Items, Emblems, Jewels, Stones), then each gear slot's empty mark (the twelve and the two hands, AR6's family).
- **Overview shows every stat** (research, 2026-11-15, 19:13, on the director's still of Overview and the words with it: `docs/decisions.md`; the spec is in `docs/ui.md`, 5, "Overview's stat sheet").
  - Overview today shows five stats. It gains the rest in three groups (Core, Attack, Defence), zero shown as 0. A rating shows "up to N%" at the Voidkin's level, and each line keeps its sources.
  - The rules already hold every stat, so this is display only. For Faber, after TR19's and TR20's fixes.
  - **Check, from the same still:** the experience bar under "335 of 4,320 experience to the next" (7.8%) shows only a sliver at its left. Either its fill doesn't draw, or the fill is too dark to see on the track.
  - **Checks:** the case's lint on the smallest phone, with the list scrolled to its foot. A still for research.
  - **Built, 2026-11-15, night (Faber).** The stills: `build/captures/overview/stat_sheet_smallest_phone.png`, at the smallest phone's size, three views: the top (the level, its bar, Core), the middle (Attack) and the foot (Defence, then Now and Gear).
    - **Implemented.** `Rules.Sheet`, pure, writes every line: the 19 stats in Core, Attack and Defence, a zero as 0. A rating gives its points and "up to N%" at the Voidkin's level against a foe with none, as `Rules.Hit` sums it, and Critical counts its floor. The percents are percents, and each line's sources stand under it. Overview draws the groups under quiet captions.
    - **The experience bar's sliver was a bug,** in the kit: `Bar` read its width as an offset alone, so a bar sized by its parent lit about a pixel at any share. It now measures its drawn width and relights when it changes. The Breaker's crack bar under a chamber had the same fault, so it now fills as the shard breaks.
    - **Tested.** Type check 0 new. Logic 5971 offline, with the sheet's four cases. The self-test "Overview's stat sheet" passes 18 of 18: every line's value and sources against the rule, each group in order, a parent-sized bar at 7.8% lit 0.083 of its length, the lead's bar 0.144 for 0.141, and the lint clean on the smallest phone at the list's foot. "Voidkin screen (TR17)" passes 264 of 264. The stills take passes.
    - **Tier 1 calls:** Hit and Critical Resist have no chance of their own, so each says "Lowers a foe's Dodge and Block" or "Lowers a foe's Critical". A rating at zero reads "0", never "up to 0%". Critical Damage lists its base 50% first. Elemental Attack names its element, or says "No element: no second hit". Lifesteal past its cap says what counts. Damage Bonus reads 0% for now, since no signature or passive gives it; Damage Reduction gives Second Wind's 20% "below 30% health".
    - **Visually reviewed:** yes, research's pass below. **Director-accepted:** no.
  - **Research's read of the stills** (2026-11-15, 21:05). **Felt:** every stat is there, each with one plain line of what it does ("Lowers a foe's Dodge and Block") and where it comes from. The experience bar now shows its 14%. **Tier:** competent. **The one bold thing:** the plain line under each stat, which teaches the sheet without a help page. No fix, and Faber's tier 1 calls stand. Closed. The Breaker's crack bar, now filling, is read at the first session's review.
  - **The stat model, built, 2026-11-15, night (Faber),** on the director's yes (the register; `docs/balance.md`, "The stats" and "One hit"; `docs/ui.md`, "Stats, shown honestly"). The stills, at the smallest phone's size: `build/captures/overview/stat_cells_top_smallest_phone.png` (Core's top) and `stat_cells_tap_smallest_phone.png` (Hit's tap open).
    - **Implemented.** `Rules.Hit`: a critical leaves the capped bucket and multiplies on its own, x (1 + Critical Damage - the target's Critical Guard), never under x1, with no ceiling (`Result.CriticalFactor`). The elemental hit is never critical. `Rules.Stats` gives a Voidkin's base (its level 1) and its level's gain as two sources. `Rules.Sheet`: each stat one total, never "up to". A tap lists its sources in order (Base, Level N, Stars, each slot, then forge and the rest as they join the resolver), rounded to add to the total, then its notes, a rating's chance against a foe of its level with the same points last. Overview shows two stats a row, each its name over its total, its sources opening under its row.
    - **Tier 1 calls.** Two a row: a tap must be 44 px at the smallest phone (the kit's 52 authored), and a 52-tall line showed one and a half stats in the window there, so two a row keeps the sheet as dense as the old lines. The notes' and chance lines' words. Combat Power's weights stay the stand-ins they were (research's seeds, TR17 fix 10).
    - **Tested.** Type check 0 new. Logic 7,331 passed, offline and in Studio. The self-test "Overview's stat sheet" passes 38 of 38: every total against the rule, two a row in order, a tap opening Health's sources as `Rules.Sheet` lists them with the base first, Dodge's chance last, a tap moving and closing it, and at the smallest phone the lint clean (every tap 44 px) with Hit's tap open and every note fitting. "Voidkin screen (TR17)" passes 264 of 264. The stills take passes 4 of 4.
    - **Visually reviewed:** research's pass waits. **Director-accepted:** no.
  - **Research's pass on the stat model's stills** (2026-11-15, night, both whole):
    - **Felt:** a character sheet that answers. Every stat has its name over its number, two a row, and a tap opens what it means under its own row. No "up to" is left anywhere.
    - **Tier:** competent. **The one bold thing:** the tap opening full width under its row, so the sources and the chance stand right under the stat they explain.
    - **No fix.** Two a row is Faber's tier 1 and stands: it's denser than the lines, and every cell is a full tap.
    - **Closed** as a block. Combat Power's weights are research's next seeds (fix 10).
  - **Research's seeds for fix 10, Combat Power's weights** (2026-11-15, night; tier 2, Faber's build). They live in `tools/balance/seeds.json`, "combatPower", fitted by the sim's section 16.
    - **The weights,** a point, into `Config.Stats.Power.Weights`, Scale 10 kept: Health 0.53, Attack 4, Defence 3.1, Regen 3.1, Hit 0.53, Dodge 2.1, Critical 1.2, Critical Resist 0.2, Block 1.4, Penetration 0.88, Elemental Attack 5.2, Elemental Resist 0.34, Critical Damage 110, Critical Guard 110, Lifesteal 770. Each is what a point adds to winning, Attack's held at 4, averaged over the four specs on budget, as the fighter and as its foe, at levels 5 to 60.
    - **One change to `Rules.Stats.Power`:** a percent's weight multiplies by G at the block's level. That covers Critical Damage above its base, Critical Guard and Lifesteal. A percent multiplies points, which grow with G, so a fixed weight would count 10% Lifesteal the same at level 1 and at level 60, where it multiplies 22 times the points. A case: the same percent gives G(level) times its level-1 power.
    - **What they give:** the higher number wins 97% of same-level duels with no type edge, and every duel where one side wins 10% faster. The stand-ins managed 90% and 95%.
    - **Its limit:** a sum can't see that spreading points beats stacking them. Of one budget spent two ways, it picks the better about half the time, with the two at most 14% apart. Every refit I tried traded duels away for it. A measure against a panel of every spec picks the better 90% of the time, but it isn't a sum (`docs/polish-later.md`).
    - **My line in fix 10 is withdrawn.** Combat Power can't make rarity count for more than four levels, because it follows the fight. An Epic's x1.26 on its own base is worth about two and a half levels at level 8. Bare, Pip at level 12 beats Ironhymn at level 8 about a third faster, and the seeds show it, 27,640 over 25,222. At the same level the Epic wins clearly. If rarity should be worth more, that's `rarityBase` in `docs/balance.md`, not Combat Power.
  - **Fix 10 and the plain list, built, 2026-11-16 (Faber),** on research's seeds above and the director's word in the builder's session, 2026-11-15: "dont put any description for stats make it like taichi panda dragon hunter overview!", then "Plain list, no taps" to the builder's question.
    - **Implemented.** `Config.Stats.Power.Weights` holds the seeds. In `Rules.Stats.Power`, a percent's weight (Critical Damage above its base, Critical Guard, Lifesteal) multiplies by G at the block's level. `Rules.Sheet` and Overview: every stat as a name and its number, two a row, under the groups' quiet captions, with no tap, no sources and no line of what it does.
    - **Tested.** Type check 0 new. Logic 9,870 passed, offline and in Studio, with the case that a percent gives G(level) times its level-1 power. The self-test "Voidkin screen" passes 300 of its cases. Its 2 fails are TR20's manual pointer take, which the filter picked up and which waits 90 s for an outside driver that wasn't run.
    - **Visually reviewed:** research's pass waits, at the first session's run on a phone. **Director-accepted:** no.

## TR18. The base as a power plant (Faber, then Modulo's generator)

Research's entry, 2026-11-14, night, on the director's word (`docs/decisions.md`, 2026-11-14, night, (1); "Yes, as restated"). The design: `docs/design.md`, "Power: the base is a power plant". The HUD's pill and screen 7: `docs/ui.md`.

**Feel line:** a player stands at their generator, drags one bar, and hears the Breaker spin up as the training slows. The base is a plant they run, and every kW they make goes where they chose.

**Order in the queue:** after TR17. **Time, forecast:** 4 to 6 active hours.

**The block contains,** in grey:
- **The rule** (`Rules/Power`, pure, with logic cases):
  - generation from the bays' workers;
  - each machine's draw: its share of generation over its rating, up to full speed, never stopping dead;
  - Auto's split by demand;
  - the battery: charging from what isn't routed, covering routed demand above generation, offline too, to its cap.
- **The save** (server-owned):
  - the shares and Auto, validated on the server: each share 0 or more, the total never over the whole;
  - the battery in kWh;
  - a migration step from the stored counter to kWh.
- **The machines run at their factor:** the Breaker's speed, the Condenser's rate, the Training machine's pace. Infusion is paid in kWh.
- **The generator:** a grey block at the base, with generation and demand on its face. Its prompt opens the Power screen.
- **The Power screen** in grey:
  - one horizontal bar, split by handles;
  - +/- on each share, and Auto;
  - each machine's row: its kW against its rating, and its speed in %;
  - the battery's kWh, its cap, and the hours of work it holds.
- **The HUD pill:** generation against demand in kW, in grey until AR12's pick, with a state for demand over generation.
- **When it shows:** the screen opens once a second machine draws. Until then, Auto runs it unseen.

**The numbers,** research's seeds, 2026-11-15: `tools/balance/seeds.json`, "power"; `tools/balance/sim.py`, section 14. Faber puts them in `Config`.
- **Generation:** a worker makes 6 kW an aptitude point, with +2% a level as now. Watt and Rook at level 1 make 30 kW, the director's own example.
- **Demand:** each machine draws its rating while it works. A Breaker chamber breaking draws 15 kW, times its shard's ground factor, so two chambers ask 30 kW. The Training machine draws 10 kW.
- **A shard's cost is derived,** never set: its chamber's rating times its break time. A Standard costs 0.125 kWh, an Enriched 3.75, a Prismatic 45. `Config.Shards.Grades[...].Energy` goes.
- **The floor:** 0.25 of full speed, as `MinSpeed` today.
- **The battery:** 60 kWh, starting at 2. Overflow sells at 0.5 Credits a kWh. Away hours are as now.
- **Infusion is voltage** (the director, 2026-11-15, "Faster break"; `docs/design.md`): Low halves a shard's time left, and High breaks it at once. The price is the energy its chamber would still draw over the time saved, times 1.33, times the ground's factor (`seeds.json`, "voltage"). A price rounds up to a whole kWh. It's not offered when it saves under a minute, so never on a Standard, and Lantern Row has only Standards: voltage first appears with Drum Court's Enriched (factor 1.5: Low 4 kWh, High 8). A Mask Parade Prismatic (factor 2) asks 60 and 120, more than today's 60 kWh battery holds, so the battery's cap must grow with the base before ground 3.
- **Migration:** an old save's electricity divides by 10 into kWh, so a full old battery (600) is a full new one (60).
- **Auto and the split,** read from the design's "the battery covers routed demand above generation":
  - Under Auto, each machine's routed demand is its full rating, so the battery tops them all up to full speed while it holds charge.
  - Under a manual split, each machine's routed demand is its share, which is never more than generation, so the battery isn't drawn. That's how a player saves power for an infusion.
- **What the sim says, ground 1:**
  - Breaking costs almost nothing against generation (cover about 19 to 38 times).
  - The power goes where the player chooses: the Training machine, the battery and infusion.
  - With the battery empty and both chambers and the Training machine running, Auto gives each 68%.
  - The battery fills in 3 hours of the spare 20 kW.
  - The old energy cover is replaced. A heavy player's Breaker isn't limited by power on ground 1, and it wasn't before either (x1.9).

**Waits:**
- the generator's model (Modulo, requested once the block is judged);
- the screen's and the pill's look (AR12, then the machine room's Dynamo);
- the plant's sounds.

**Done when:**
- the logic cases pass: split, Auto, the floor, the battery's charge, drain, cap and offline, the migration and a refused share;
- a take at phone size: walk to the generator and open it, drag a handle, then Auto, the Breaker's progress slowing and speeding with it, and the HUD pill changing;
- research's verdict in motion. The UI lint runs first, at both scales.

**Faber's build, 2026-11-15.** About 1 active hour (16:32 to 17:27), against 4 to 6 forecast; the screen-time checks remain.
- **Where it lives:**
  - the rule: `Rules/Power` (pure), on the base's one clock in `Rules/Breaker`, which now trains the Training machine's Voidkin too;
  - voltage and the split as server actions: `Rules/Base` (`Infuse`, `SetPower`);
  - the save: `Base.Charge` in kWh, `Base.Power { Auto, Shares, Open }`, the Training machine's stamp gone; migration step 4;
  - the numbers: `Config.Base`, `Config.Shards.Voltage`;
  - the generator: a grey block left of the Breaker, between it and the Training machine (`Config.World.Grey.Generator`, tag `Generator`);
  - the screen and the pill: `UI/PowerScreen` and the HUD's Power pill.
- **Tier 1, my calls:**
  - **The machines:**
    - a starter shard's cost is derived like any shard's (0.025 kWh), and the 2 kWh start covers it;
    - routed power a machine can't use charges the battery;
    - a machine with no share runs at the floor;
    - shares over the whole, from an older save, are scaled back to it.
  - **The Power screen:**
    - it opens the first time the Training machine draws, the Breaker being the first machine;
    - a split is refused until then;
    - Auto keeps the last split for later.
  - **Voltage:**
    - it's refused on a shard that holds a stated Voidkin (`Named`) and on one it would save under a minute (`Brief`);
    - an old save's luck-infused shard keeps its luck, and `Volt` marks voltage.
  - **Time:**
    - away, the lead trains at full power while the battery lasts, then at the floor;
    - the last minute or less online before a leave counts as away.
  - **The pill:**
    - "30 / 34 kW" with the battery's kWh after it, and the thread its fill;
    - over generation, the value turns an amber warning colour (`Theme.Colour.Over`);
    - a battery's jump on a return still flies in, with "+N kWh".
  - **The screen:**
    - under Auto, the bar shows what each machine draws, scaled to the whole while they ask more than is made;
    - +/- moves 5% (`Config.Hud.Power`), and + is off once the whole is given;
    - a handle asks once, when it's let go;
    - the battery's hours are at today's demand.
  - **Numbers shown:** kWh to the hundredth under 100, so a charging battery visibly counts (one bay turns it every 2 s).
- **For research:**
  - **The Training machine:** it draws a flat 10 kW, as this entry says, where `sim.py` multiplies it by the ground's factor. Say which is right.
  - **Voltage in Lantern Row:** voltage is never offered there, so its pane only ever says "Saves under a minute: not offered". Should it hide until Drum Court?
- **Tested:**
  - type check 0 new;
  - logic 5905 offline: split, Auto, the floor, charge, drain, cap, offline, the migration, a refused share, voltage's price and refusals, training on the clock.
- **Self-test, run 2026-11-15:** Power 55 (the UI lint included, in this window and on the smallest phone, with a split), voltage 60 (it tunes the Standard to 900 s for itself and puts it back), the pills 34, the plates 28, the worker 8, all passing at 60 fps. The full suite: 1979 passed and 2 failed, both since fixed and passing alone (cb73de0).
- **The take at phone size, 2026-11-15** (`build/captures/tr18/power_take.mkv`, 45 s at 59 fps, its zero at 4.48 s; `power_take_sheet.jpg`, a row a moment). The case `Take: TR18, the Power screen from the generator…`: the walk to the generator, its prompt, the screen under Auto, the Breaker's handle slid to a quarter over 1.2 s, then Auto. Not played: the screen opened by `PowerOpen`, a shard in each chamber, the battery a third full. Its readings:
  - under Auto: the Breaker "30 / 30 kW · 100%", the pill "21 / 30 kW" in amber, the battery draining;
  - with the split: the Breaker "5.1 / 30 kW · 25%", the pill the same;
  - Auto again: the Breaker "30 / 30 kW · 100%".
- **Visually reviewed by Faber, on the sheet.** The Breaker slowing and speeding reads in its row. Three things don't, for research's verdict:
  1. **The pill doesn't change with the split,** against the done-when. It says what the machines ask, and they ask the same. Proposal: amber only while the battery covers a shortfall, so a split that generation covers turns it plain.
  2. **The Breaker's share goes to the next machine, not to the battery.** Its handle at a quarter gives the idle Training machine 75% and the battery 0%, while the battery takes the 16 kW left (the rule's `Net`). Proposal: a handle hands what it gives up to the battery, and an idle machine's share is drawn as the battery's.
  3. **The head warns about a choice.** "Demand over generation: the machines slow" stands in orange under a split the player made. Proposal: under a split it says the fact plainly, "The Breaker at 25%", without the warning colour.
  - Each changes my own tier 1 calls in this build. I make none before the verdict.

- **Research's verdict, 2026-11-15, night** (`power_take_sheet.jpg`, a row a moment at phone size):
  - **Works in grey.** The split bar reads at a glance, and the Breaker slowing and speeding reads in its row. The screen is the kit's grey, as a grey build should be; its look comes with Modulo's generator.
  - **Faber's three proposals are accepted** (tier 2, research for design):
    1. The pill turns amber only while the battery covers a shortfall.
    2. A handle hands what it gives up to the battery, and an idle machine's share is drawn as the battery's.
    3. Under a split the player made, the head states the fact plainly ("The Breaker at 25%"), with no warning colour.
  - **The Training machine:** a flat 10 kW at launch, as built. `sim.py` scales it by the ground's factor so it stays a real share of later plants. That rule joins with Drum Court, and at Lantern Row's factor both give 10.
  - **Voltage in Lantern Row:** hidden. A pane that can only say "not offered" is noise, and at launch no ground offers it. It shows from the first ground that offers it.
  - **Next:** the three changes and the hidden pane; then a retake at phone size, the same case, for research's pass.
- **Built, 2026-11-15, night** (Faber, f5c2927):
  - **The pill** turns amber only while the battery covers a shortfall (`Flow.Net` under 0).
  - **The Void Breaker's handle** keeps the Training machine's share, squeezing it only at the bar's end, so what it gives up goes to the battery. With both handles on one spot, the first move picks the side: left moves the Breaker's, right the Training machine's.
  - **An idle machine's segment** is drawn in the battery's colour.
  - **The head:**
    - under Auto it still warns, in the warning colour ("The battery covers the rest", or "Demand over generation: the machines slow");
    - under a split it says each slowed machine plainly, in the dim text colour: "The Void Breaker at 25%".
  - **Voltage:** none shows on a kind it's never offered on (`Rules.Power.Offered`), so Lantern Row's shards show no pane.
  - **Tested:**
    - logic 5912 offline (`Offered`: the 30-second Standard never, at 900 s always, an unknown shard never);
    - Power 58: the handle keeps the 60%, the idle segment, the plain head under a split;
    - voltage 60: the 30-second shards show none, then the case tunes both 30-second grades to 900 s;
    - the HUD's pills 34.
- **The retake at phone size, 2026-11-15, night** (`build/captures/tr18/power_retake.mkv`, 55 s at 59 fps, its zero at 5.25 s; `power_retake_sheet.jpg`, a row a moment). The same case, 17 passing at 60 fps. The stills:
  - `retake_pill_auto.png`: before the screen opens, the pill "21 / 30 kW" in amber, the battery covering;
  - `retake_auto.png`: under Auto, the head's "The battery covers the rest" in the warning colour;
  - `retake_split.png`: the handle at a quarter. The Breaker 25%, the battery's 75% beside it, the Training machine idle at 0%. The head says "The Void Breaker at 25%" in grey;
  - `retake_auto_again.png`: Auto again.
  - Not seen: the pill under the split, as the screen covers it. The HUD case checks its rule.
- **Visually reviewed by Faber, on the stills:** the three changes read as accepted. Research's pass on the retake waits.

- **Research's pass on the retake, 2026-11-15, night** (`retake_auto.png`, `retake_split.png`): **it passes.**
  - Under Auto, "The battery covers the rest" warns in orange because it's a shortfall.
  - Under the split, "The Void Breaker at 25%" states the fact in grey, and the bar shows the 75% going to the battery in its own yellow, the pill's colour. The idle Training machine shows 0%.
  - The voltage pane is gone.
  - The pill under a split is covered by the HUD case, so no extra beat is needed.
  - **TR18 closes in grey:** works, competent for a grey screen. Its look comes with Modulo's generator, a piece of its own.

**Status:** research's verdict built and retaken at phone size, 2026-11-15, night (Faber, above). Self-test passing. Research's pass given, 2026-11-15, night: closed in grey. Not director-accepted.

## TR19. Home in one tap: the dock's Base tile (Faber)

Research, 2026-11-15, night, on the director's word of the same night (`docs/decisions.md`: "there should be a Ui to tp back to base with a small CD and only when out of combat/boss area event etc"). It replaces TR16's chip and trail. **The control is the dock's Base tile:** the dock already has a house that means home, so a second button would say the same thing twice.

- **Feel line:** a player out on Lantern Row taps the house on the dock. After a short charge that tells them it's coming, they fold into void light and step out at their own Breaker with their lead beside them: quick, sure, never a menu.
- **The beats** (seeds, UNVERIFIED; tuned in play, in `Config`):
  - **Anticipation:** the tile fills from its foot in 0.6 s, and the avatar's outline lifts in void light. A hit taken or dealt in the charge cancels it, and nothing is spent.
  - **The jump:** a short white-violet flash at the screen's edges, about 0.15 s. The player arrives at their plot's spawn, facing the Breaker. The lead and anyone following arrive with them.
  - **Arrival:** a small FOV settle (+4 easing back over 0.3 s) and a puff of light at the feet. Its sound is in AR13's later pass.
  - **Cooldown:** 20 s, shown as a sweep across the tile, and the tile stays tappable to explain itself.
- **When it refuses:** the tile dims, and a tap gives a short shake and a toast in plain words:
  - "In a fight": a hit dealt or taken in the last 4 s;
  - "Not in a boss's ground": the Lamplighter's or a keeper's try;
  - "Not during an event";
  - the cooldown: "Ready in 12 s".
  - The server decides every refusal. The client only shows the state. The rule goes in pure Luau, next to `Rules.Night.Inside`, with logic cases.
- **At the base:** the tile reads as "here", quieter, and a tap does nothing. Away from your own plot (another base or the Strip), it takes you home in the same way.
- **After a fall** (D02): while the lead is down and the player is out alone, the Base tile gets the pip, because home is where the lead waits.
- **Takes away:** TR16's "Go home" chip and `Rules.WayHome`'s trail, with their cases. The Festival Door and its twins stay as they are.
- **The block contains:** the tap, the charge, the jump, the refusals, the cooldown and the pip, with stand-in light. **Waits:** the final look of the light (Modulo), and the sound (AR13's later pass).
- **Checks:**
  - logic cases for every refusal and the cooldown;
  - the self-test from Lantern Row, a keeper's try and the base;
  - research's verdict in motion from the player's camera, at phone size.

**Status:** built, self-tested, and taken at phone size, 2026-11-15 (Faber). Research's verdict in motion given, 2026-11-15, night: competent as a block, with two fixes and the fight's rule, then a short retake (below). Fixed and retaken the same night (below). Research's pass given on the retake, 2026-11-15, night: closed as a block, with the fill at 0.85. Time: about half an active hour to build, by the commits' clock from the dock's commit at 15:35, and about half an hour for the self-test and the take.

- **Implemented.**
  - **The rule** (`Rules.Home`, pure): `Refusal` in the spec's order (here, a boss's ground, an event, a fight, the cooldown), `Says` in its plain words ("Ready in 12 s" counts the whole seconds left, never 0), `Broken` (a hit at or after the charge's start), `Share` (a charge's or a cooldown's run, 0 to 1). Seeds in `Config.Home`, tuned live (`Tune "Home.Charge"`).
  - **The server decides** (`HomeService`, Net `Home`): a refusal answers why; else the charge starts (the player's `HomeCharge`, server time) and the server re-checks at its end. A hit the player's lead dealt or took (`FightService` stamps the owner's `HitAt`) cancels it, and nothing is spent. A try or an event begun in the charge refuses too. Then the player and their lead are set down at the plot's spawn facing its Breaker (`KeeperService.Place`, no fade), `HomeReady` starts the 20 s, and the client is told (`HomeJump`). In Studio: `HomeState`, `HomeHit`, `HomeReady`.
  - **The tile** (`UI.Dock`: `Mood`, `Fill`, `Sweep`, `Shake`): quiet at home; dim in a fight or a boss's ground, still tappable; fills from its foot in white over the charge; wears the cooldown's veil; shakes 4 points over 0.25 s on a refusal, with the server's words in a toast. The pip after a lone fall is the Base tile's (`Rules.Hud.AfterFall`'s "Home").
  - **The jump** (stand-ins until Modulo's look): the avatar's outline (a `Highlight`, #B48CFF) lifts over the charge; a white-violet light at the four edges, up and gone in 0.15 s; the field of view 4 wider, eased back over 0.3 s; a flat ring of light opening to 6 studs at the feet (`Effects.Arrive`).
  - **Taken away:** TR16's chip, `WayHomeController`, `Rules.WayHome`, `Config.Hud.WayHome`, their logic cases, their self-test case and their take.
- **Tested.** Type check 0 new. Logic 5824 offline (three new cases: every refusal in its order and its words, the charge broken and the shares, the pip). Studio has the code (searched). Written, not yet run: the self-test case (at home, Lantern Row, the cooldown, a fight, a hit in the charge, a keeper's try, the pip after a lone fall) and research's take ("Take: TR19").
- **Visually reviewed:** no. **Director-accepted:** no.
- **Tier 1 calls:**
  - The cooldown's dim is its veil: the share still to come is veiled in ink and swept away left to right, so the tile brightens as it comes back, rather than a whole dim tile under a sweep.
  - A quiet tile doesn't sink on a press, since nothing happens.
  - The Map's tile keeps the kit's dim and toast, without the shake.
- **For research:** the Base screen (the bag and the bays) loses its dock entry. It still opens from each bay's prompt. Say whether it needs another way in.

**The self-test and the take at phone size** (Faber, 2026-11-15, evening; the device simulator's iPhone 16 Pro):

- **The self-test:** TR19's case passes 48 of 48: at home, Lantern Row, the cooldown, a fight, a hit in the charge, a keeper's try, and the pip after a lone fall.
- **The take** (`build/captures/tr19/`):
  - The recording is `home_take.mkv` at 59.5 fps, with zero at 7.85 s. The sheet is `home_take_sheet.jpg` (and its `.tsv`), seven moments 1.2 s apart.
  - Stills: `cooldown_tap.png`, `closing.png`, `first_hit.png`, `fight_tap.png`.
  - The take passes 11 of 11.
  - It now ends in a real fight by Pack 2: the cooldown is cleared and the player set down 12 studs from the pack, neither played.
- **What the fight shows:**
  - From the set-down to the lead's first hit, about 3 s, the tile is at rest, ready to tap.
  - Yet the HUD already says "fight" in that time: the Brawler's card is up and the readout is in (`closing.png`).
  - From the first hit the tile is dim, and a tap shakes it and says "In a fight" (`fight_tap.png`).
  - So hud_fight.png caught that first gap. Built to the spec: "In a fight" is a hit in the last 4 s (`Config.Home.Fight`).
- **The question for research** (tier 2: the rule is the spec's):
  - Should "In a fight" also begin when the lead takes a target or a Shade takes the lead, the moment the target's card shows?
  - Then the tile and the HUD say the same thing.
  - The cost is small: `Rules.Home` gains the fact in its situation (the server has it in `FightService.InCombat` and the lead's `Target`), plus a logic case and a self-test check.
  - Until research's word, it stays as built.

**Research's verdict in motion, 2026-11-15, night.** Read from `home_take_sheet.jpg`, the four stills, and two cuts from `home_take.mkv` at native size: the jump at 20 fps, 10.8 to 11.75 s, and the fight's tap at 30 fps.

- **Felt:** quick and sure.
  - From tap to arrival takes 0.65 s. The lead arrives beside the avatar, and the base's own chip greets them ("89 shards: into the Breaker").
  - The tile's four states read apart at phone size:
    - ready: full yellow;
    - quiet at home: muted gold;
    - the cooldown: the veil swept left to right, so the tile brightens as it comes back, with "Ready in 11 s" for whoever taps;
    - a fight: the whole tile dark olive and the icon faint, with a small shake that reads beside "In a fight".
- **Tier:** competent, as a block. The weakest beat is the one that says "it's coming": the charge.
- **The one bold thing:** the cooldown's veil. It answers "how long" with no number, and the toast gives the number only to whoever asks.
- **Fixes for the block:**
  1. **The press flashes black.** At the tap (10.9 s), the tile goes to ink for a frame, then back to yellow before the charge. At the moment that should feel sure, it reads as a glitch. The press goes straight into the charge's fill.
  2. **The charge doesn't read at phone size.**
     - The white rising over the ready yellow barely shows: only the last frames look paler, and no edge is seen rising.
     - The outline's #B48CFF sinks into Lantern Row's violet stone.
     - For the stand-in: the tile goes to its ink at the tap and fills in white from its foot, with a bright edge. It reads apart from the cooldown's veil, which sweeps sideways. Make the outline near-white (#EEE6FF), so it reads on every ground.
     - Amended the same night, before the build: white on ink, not the void's violet (#B48CFF), on the director's word to Modulo at 19:09 ("to much purple"). The colour comes from the palette once it's picked.
     - Modulo's final light keeps the same need: it must read on the violet grounds.
- **The question, answered (tier 2, research and Faber's area): "In a fight" is `FightService.InCombat` or a hit in the last 4 s.**
  - **InCombat is the game's one meaning of a fight** (TR12): the lead has a target, or a Shade has the lead. The lead swap already refuses on it ("Not during a fight").
  - **The card and the tile then agree:** while a target's card is up, the tile is dim. The card is the cue the player already reads.
  - **A Shade's target alone wouldn't close the gap.** The lead takes a target within 30 studs of the avatar (`Combat.Lead.Leash`), but a Shade notices only at 20, so the card would still show over a ready tile.
  - **The cost, accepted:** home refuses within about 30 studs of a live Shade. Stepping back ends it, as it does for the lead swap: the lead lets go past its leash, and a Shade gives up 40 studs from its spawn.
  - **A fall ends the fight at once:** the 4 s tail counts only while the lead stands. Then the pip after a lone fall never points at a dim tile. Going home is what the pip asks for, and the Shades have no one left to fight.
  - **The cases:**
    - the closing gap: a target and no hit gives "Fight";
    - a Shade's target alone gives "Fight";
    - after a fall, no tail.
- **The Base screen's way in (Faber's question): no other way in.** What it holds already has homes in the spec: the bays open at each bay (`docs/ui.md`, 7), and the bag is the character screen's Items page (TR17).
- **Then:** a short retake at phone size of the tap and the charge (20 fps, the tile and the avatar cut out), and of the closing gap with the tile dim. TR19 closes as a block on that read. Its light waits on Modulo, its sound on AR13.

**The fixes and the retake** (Faber, 2026-11-15, night; about 35 minutes from the verdict's commit; the device simulator's iPhone 16 Pro):

- **Implemented.**
  - **The black frame's cause:** each tile's pressed twin wasn't loaded before its first press. For about 250 ms the tile drew nothing, so the dock's body showed through. Then the yellow pressed twin came. The dock now loads every pressed twin when it's built, which fixes the first press of Inventory and the Map too.
  - **Fix 1, the press goes straight into the charge** (`Dock.Charges`):
    - The client starts the fill on the tap's own frame, before the server answers. A refusal drops it and shakes the tile.
    - The tile is in ink from the tap to the jump (`Config.Hud.Dock.Charge.Ink`, #0B0B12). A charge under way never dims, since only a hit breaks it, as on the server.
    - Once landed, the full tile holds until this client sees home (at most `Config.Home.Hold`, 0.4 s), then goes quiet. No veil and no dim come in between.
  - **Fix 2, white over ink, as amended:**
    - The fill's body is white at 0.6.
    - Its rising edge is a band of 0.1 of the tile's height, white at full.
    - The outline is #EEE6FF.
    - All three are stand-ins until the palette is picked. The body can go to 0.85 for a whiter fill (`Tune "Hud.Dock.Charge.Alpha"`), at the cost of a weaker edge.
  - **The fight's rule:**
    - `Rules.Home`'s situation gains `Engaged` (`FightService.InCombat`, which the server publishes as the player's `Engaged` attribute) and `Standing` (the lead out and standing).
    - A fight is `Engaged`, or a hit in the last 4 s while the lead stands.
    - `HomeService` and the tile read the same rule.
- **Tested.**
  - Type check: 0 new.
  - Logic: 5922 offline. One new case covers:
    - the closing gap;
    - a Shade's target;
    - engaged still under a boss's ground, before the cooldown, and at home still home;
    - after a fall, no tail, though the cooldown still counts.
  - TR19's self-test passes 61 of 61 at 60 fps, the take run first.
    - The case's 50 checks include three new ones: every pressed twin loaded; the fill from the tap's own frame (0.019 s); ink from tap to home, then quiet (rest, then the charge at 0.02 s, then quiet at 0.67 s).
    - The take passes 11 of 11, the closing gap included ("Rest then Dim").
  - TR20's dock cases pass 28 of 28.
  - A Studio command for a case that starts after a fight: `LeadCalm` (`FightService.Calm`). A lead with a target is now "In a fight", so the case calls it first, and so does the take.
- **The retake** (`build/captures/tr19/`):
  - `home_retake.mkv`: zero at 6.60 s. The capture averages 46.9 fps, while the client ran at 60.
  - `retake_charge_20fps.jpg`, the tile and the avatar from 0.1 s before the tap to the arrival:
    - the tile is ink at 0 ms;
    - the white rises from its foot under its bright edge, with the house's mark showing through as it climbs;
    - the avatar's near-white outline is lit from about 0.3 s;
    - the jump lands at about 0.65 s;
    - the tile is quiet at home in the next frame, with no yellow flash anywhere.
  - `retake_closing_gap.jpg`, at phone size from 22.45 s:
    - the tile is at rest;
    - at 22.8 s the Brawler's card shows and the tile dims, with no hit yet;
    - it stays dim while the lead closes, through the first hit at 25.3 s;
    - a tap says "In a fight".
- **Seen in Studio:** partway through a run, the client dropped to 20 fps with the window in front: 47 ms of render CPU, 3 ms of GPU, and nothing else loading the PC. A playtest restart gave 60 again. A report taken at 20 fps isn't timing evidence, and each one says its rate.
- **Tier 1 calls:** the hold after the jump; a charge never dims; `LeadCalm`.
- **Visually reviewed:** research's read of the retake is next. **Director-accepted:** no.

**Research's read of the retake** (2026-11-15, 19:45; both strips at their size):

- **Felt:** the tap answers on its own frame now. The tile drops to ink, a white tide climbs from its foot under a bright line, the avatar lights, and home lands at about 0.65 s with the tile already quiet. In the street, the tile dims the moment the Brawler's card shows, before any hit, and a tap says why.
- **Tier:** competent. Both fixes and the fight's rule are met.
- **The one bold thing:** the ink on the tap's own frame. The press and the charge are one motion, with nothing in between.
- **One number, the one Faber asked about: take 0.85.** At 0.6 the fill reads mid-grey over ink, and grey on a tile says disabled, not charging. At 0.85 the band's step inside the fill is lost, but the edge that moves is where white meets ink, and that stays the strongest line on the tile. Tier 1, in `Tune`, then in `Config`.
- **No other fix. TR19 closes as a block at research's pass.** Its ink, white and outline are stand-ins until AR12's palette is picked.

## TR20. Everything that presses answers the pointer: hover (Faber)

Research, 2026-11-15, night, on the director's word of the same night ("we should play with the hover UI maybe we never added it"). Checked: nothing in the game reacts to a pointer today. No `MouseEnter` exists anywhere in `src/client`, and no spec asks for one.

- **Feel line:** on a computer, every button the pointer crosses answers at once by lifting and brightening, so the player knows what a click will do before making it. On a pad, the selection does the same. On a phone nothing changes, because a touch has no hover.
- **One shared util** in the client, put on every pressable thing: the dock's tiles, the chips, the Breaker's chambers, the screens' tabs, cards and close buttons. Pressed beats hover, and open beats both.
- **The motion** (seeds, UNVERIFIED; in `Config`, tuned in play):
  - **in:** 0.08 s, eased out; **out:** 0.12 s;
  - **a tile or button:** lifts 2 points, its gradient's stops move 12% toward white, and its halo shows at 40%;
  - **a card:** scales to 1.03 and its rarity rim brightens;
  - **nothing moves its neighbours.**
- **The word:** after 0.35 s on a dock tile, its word (the long-press word) shows above it. A refused Base tile shows its reason.
- **A pad:** the selected thing takes the same lift, with a thin rim of our own in place of Roblox's default selection image.
- **Touch:** no hover. Go by the last input type, not by `TouchEnabled`, so a laptop with a touchscreen still gets hover from its mouse.
- **The sound:** a quiet tick on hover, in AR13's UI pass. None until then.
- **The block contains:** the util, the dock, the Breaker's chambers and the Voidkin screen's cards. Every pressable thing built after it uses the util from the start. **Waits:** hover on things in the world (a bay, a Voidkin at work, the generator), a piece of its own if play asks for it.
- **Checks:**
  - it answers within a frame of the pointer's entry;
  - no layout shift;
  - nothing on touch;
  - research's verdict in motion with a mouse, then with a pad.

**Status:** built, 2026-11-15 (Faber). The self-test and research's verdict in motion, with a mouse and with a pad, wait for the screen. Time: under half an active hour by the commits' clock, from TR19's commit at 15:57. Research's pass on the one take, 2026-11-15, night: closed as a block, the ready chip's hover glow at High.

- **Implemented.**
  - **The util** (`UI.Kit.Hover`): `Hover.On(target, paint)` gives each pressable thing a share from 0 to 1, eased in over `In` and out over `Out`. Each thing paints its own answer from that share, so nothing moves its neighbours. The kind goes by the last input (`LastInputTypeChanged`), never `TouchEnabled`: a mouse hovers what it's over, a pad hovers `GuiService.SelectedObject`, a touch hovers nothing. Roblox's selection image gives way to each thing's own rim. `Lift`, `White` and `Whites` are the shared answers; `Force` and `Pretend` stand in for the mouse and the input kind in tests. Seeds in `Config.Hud.Motion.Hover`, tuned live (`Tune "Hud.Motion.Hover.Lift"`).
  - **The dock** (`UI.Dock`): a tile at rest lifts 2 points, its gradient's stops go 12% toward white, and its halo shows at 40%. A pad's selection also wears the tile's edge as its rim. After 0.35 s its word shows above it, and a refused tile's word is its reason: the Base tile's from `Rules.Home.Says` (`Dock.Reason`), the Map's from its disabled reason. Pressed and open beat hover, and a quiet or dim tile keeps its mood.
  - **The Breaker's chambers and chips** (`UI.BreakerScreen`'s `tapOver`, through `Panel.Hover`): the words inside a chamber lift 2 points while its tap stays put, its body goes 12% toward white, and its edge leans toward the accent (40%, or whole for a pad). A lit chamber keeps its light.
  - **The Voidkin screen's cards** (the strip): a card scales to 1.03 in its own place (its portrait, its face and its label, through `Button.Grow`) and its rarity's rim lifts. A press's squeeze beats it, and the chosen card keeps its ring.
- **Tested.** Type check 0 new. Logic 5824 offline (nothing pure to add: the rule is the util's ease). Studio has the code (searched). Written, not yet run: the self-test case ("UI: TR20"), covering, with a pretended mouse, the dock's answer within a frame, the lift, the halo, the neighbours and the tap still, the word, the Map's reason, nothing on touch, and a pad's selection with its rim; then a Breaker chamber's words lifted with it and its neighbour in place; then a strip card at 1.03 with its rim, in place. TR19's and TR20's cases now live in `SelfTestController/HudCases.luau`, joined to Cases' list as the Voidkin cases are: Cases' one table had passed what the type solver checks in one piece.
- **Visually reviewed:** no. **Director-accepted:** no.
- **Tier 1 calls:**
  - A panel's halo is its edge leaning toward the accent, since a chamber has no halo layer.
  - The Breaker's chips hover too: they share the chambers' tap.
  - A card's rim is its rarity's trim, on every card but the chosen one, which keeps its ring: a frame draws one stroke of its own.
- **Waits, beyond the block's four parts:** the kit's other buttons (the screens' tabs, the close buttons, the Voidkin screen's rail) take the util at the shared finish; things in the world, a piece of their own if play asks for it.

**Research's verdict in motion with a mouse, 2026-11-15, night.** From Faber's take at computer size (`build/captures/tr20/hover_mouse.mkv`, the engine's own pointer, the simulator off) and its three sheets. Cuts at native size: the cards at 10 fps, 29.6 to 30.5 s; the Breaker at 2 fps, 35 to 48 s.

- **Felt:** on the dock, yes. A tile whitens the moment the pointer crosses it, and its word follows, so you know what a click will do before you make it. The cards' answer is too faint to see, and the Breaker isn't in the take.
- **Tier:** works, on the dock. The block isn't whole until the cards and the Breaker read.
- **The one bold thing:** the Map tile says "The map isn't open yet" before any click. A refused control explains itself before you try it.
- **The lift:** the 2 points barely show at computer size. The whitening carries the answer, and that's enough: no change.
- **Fixes (Faber):**
  1. **The word collides with the chip above it** (Faber's own find), and it's bare text with a stroke, which is fragile over a chip or the sky.
     - Fix: the word stands on a plate of its own, the toasts' plate made small, drawn above everything and centred over its tile.
     - While it shows, it may cover the chip: the pointer says where the player's eye is.
  2. **At home, the Base tile's word is "You're home",** not "Base". It's the reason its click does nothing (`docs/ui.md`, rule 4; TR19, "a refused Base tile shows its reason"). The tap stays silent, as TR19 says.
  3. **The cards' answer is too faint to find.**
     - In the sheet, the green card hovered and at rest look the same. In the native cut, it barely shows.
     - At 1.03 a card grows about 3 px, and the rim of a card already lit in its rarity hardly changes.
     - Seed: **1.06, and the rim at its full light** (UNVERIFIED, tuned live with the screen in front).
     - Neighbours still never move: at 1.06 a card grows about 3.5 px a side into a gap of about 18, never over the next card.
  4. **The Breaker isn't in the take.**
     - From 38 to 46 s, the pointer rests on Chamber 2's foot, an empty chamber, and never over a chip.
     - The chambers that hold a shard aren't shown either.
     - Retake with the pointer on a ready chip and on a chamber with a shard breaking.
     - An empty chamber answers only if a click on it does something.
- **Then:** the pad take as planned, its rows saying the input kind is pretended. A still of fixes 1 and 2, and a short retake of fixes 3 and 4.
- **Amended the same night, on the director's words on playtests** (the register): no still and no retake of fixes 1 to 3, since the cases cover them and research sees them at the first session's review. One take only: the pointer on a ready chip and on a chamber with a shard breaking, and the pad, never seen yet.

**Fixes built, 2026-11-15, night (Faber).** The take: `build/captures/tr20/fixes_take_sheet.jpg`, four stills at computer size, held step by step: a ready chip and a breaking chamber under the pointer, then the pad's selection on that chamber and on a dock tile. The stills of fixes 1 to 3 stay beside it, not required.

- **Implemented.**
  1. **The word's plate** (`UI.Dock`): the word is a label on a small `Panel` plate, fitted to its text, centred over its tile, above the HUD's other pieces, and drawn with the toasts' skin. No stroke.
  2. **"You're home"** (`Rules.Home.Word`): the tile's word for a hover or a long press; the tap stays silent. TR21 retires it with TR19's quiet tile at home, when the tile opens the base screen.
  3. **The cards:** 1.06, and the rim goes to its full light (`Hover.RimLight`, 0.5 toward white).
  4. **A ready chip and a breaking chamber** answer the pointer and the pad, in the take.
  - **The charge fill's body** at 0.85 alpha (TR19's verdict, `Charge.Alpha`).
- **Tested.** Type check 0 new. Logic 5925 offline, with "You're home" as a case. "UI: TR20" 34 of 34 at 59 fps: the plate centred on its tile within a pixel, its words whole, drawn over the chip; a ready chip's gold edge lighter under the pointer; a hovered card's rim at full light and clear of its neighbours' faces. "HUD: TR19" 53 of 53 at 60 fps. The take's six checks pass. The whole suite ran 2018 passed and 4 failed, in 306 s at 59 fps: the four were the Breaker's drop rates, whose case still wanted voltage on Lantern Row's 30-second shards, which TR18's verdict took off (f5c2927). The case now asks for voltage only where `Rules.Power.Offered` offers it, and passes 57 of 57.
- **Found on the way:**
  - **A hovered ready chip read duller than its neighbour:** `Panel.Hover` leaned a trimmed edge (its gold) toward the palette's accent. A trimmed edge now goes toward white.
  - **TR19's fill came up 0.07 to 0.08 s late after TR20's case:** the synced clock can stall a few frames after server load. A tap's fill now runs from the client's own clock too, and the later of the two wins: 0.019 s.
  - **Studio passed 7 GB of memory** after many playtests and stalled the MCP's client calls. The director restarted it.
- **Open, for research:** a hovered ready chip's answer is faint: its breathing gold covers the body's whitening. A seed if it should read more: on hover, the glow goes to its High.
- **Visually reviewed:** no. **Director-accepted:** no.
- **Tier 1 calls:** a trimmed edge whitens toward white, never the accent; a tap's fill runs from the client's clock as well as the server's; the plate draws above the HUD's other pieces in its layer.

**Research's read of the one take** (2026-11-15, 20:55; `build/captures/tr20/fixes_take_sheet.jpg`):

- **Felt:** a breaking chamber answers the pointer with a pale rim, and the pad's selection is the same rim, so the two inputs read as one language. The dock tile's word stands on its own plate, above the shards' hint.
- **Tier:** competent.
- **The one fix, tier 1:** a ready chip under the pointer barely changes, because its breathing gold drowns the whitening. Take Faber's seed: on hover its glow goes to High.
- **TR20 closes as a block at research's pass,** with that seed. The word's plate covers part of the hint while it shows. It's brief, and it stands.
- **The fix, built (Faber, 2026-11-15, night):** under the pointer or a pad's selection, a ready chip's breath pauses and goes to its High (`HudConfig.Breaker.Glow.High`), and breathes on from where it paused when the pointer leaves (`UI.BreakerScreen`, `glow`). "UI: TR20" 36 of 36, with the held glow at 0.600 for 0.600 and the breath going on after; the Breaker's cases pass. Type check 0 new. **Visually reviewed:** research's pass, the seed taken. **Director-accepted:** no.

## TR21. The base screen and the base's levels (Faber)

Research's entry, 2026-11-15, night, on the director's words (`docs/decisions.md`, the two rows on the base). The design: `docs/design.md`, "The base", and `docs/ui.md`, 7. The looks: AR14.

- **Feel line:** at home, the player taps the Base tile and the camera lifts over their whole base. Every machine shows what it's doing and what it can become, one tap upgrades it, and they watch it change below them.
- **Blockout first, since the screen is new:** the camera's lift and plain chips over today's base, in the game, one take for research's verdict. Then the build.
- **The block contains:**
  - the command view, the chips, a machine's panel, and the base's level with Upgrade;
  - the base's level, 1 to 3, saved on the account and bought with Credits on the server in one step, never twice on a repeated request;
  - what each level opens: bays, two, four and six; the machines' ceiling; the battery's cap;
  - each machine's level under the base's;
  - the gain shown before buying;
  - the look switched in the world, with stand-ins until AR14 lands;
  - the Power screen moved in as the screen's tab;
  - a logic case for each rule.
- **The tile:** at home, the Base tile opens this screen, so TR19's quiet tile at home and TR20's fix 2 ("You're home") go.
- **Waits:** levels past 3 and their items, the showcase, and an upgrade's ceremony beyond the live change.
- **Numbers:** the costs come from research's sim (`docs/balance.md`). Stand-ins in `Config` until then.
- **Tests, in proportion to risk:** the cases on the spend and the rules, plus one take.
- **Order:** after Overview's stat sheet.
- **The rules and the blockout, built, 2026-11-16 (Faber); parked at research's order** (phase 2's order, ef83330), with the take waiting for research's verdict.
  - **Implemented, the rules** (`docs/engineering-plan.md`, "The base's levels"):
    - The save holds `Base.Level`, `Base.Machines` and each bay's `Level`. Migration 5 gives each bay level 1, and a base with fewer than level 1's two bays gains an empty one.
    - `Rules.BaseLevels` reads `Config.Base.Levels` and `Machines`. Research's seeds are in for the battery's cap. The prices, the bays, the ceilings and the machines' gains are stand-ins until the sim's.
    - `Base.UpgradeBase` and `Base.UpgradeMachine` take Credits on the server in one step. Each names the level it buys, so a repeat or a second tap with a fresh operation id is Stale, never charged twice. Past the cap it's Cap, past the base's ceiling it's Ceiling, and fewer Credits than the price is Short.
    - A base level opens its bays empty. The Breaker's level adds its third chamber at 8 and its fourth at 20. A bay's level raises its worker's kW and the Breaker's raises its speed. The battery's cap comes from the base's level, read by every screen and the server through `Breaker.Capacity`.
  - **Implemented, the blockout** (`UI/BaseView`, `Config.BaseView`):
    - At home, the Base tile lifts the camera over the whole base from the gate's side, as far as the machines' box needs, in 0.9 s.
    - A plain chip hangs over each machine and bay: its name and level, and what it's doing now. A locked bay says which level opens it.
    - The chips never cover each other or the level panel: the nearest stands at its machine, and each other takes the nearest free place over or under one already placed.
    - The base's level stands at the top, with what the next one opens and its price, beside Close.
    - The HUD and the machines' own plates step back, and the avatar stands still. Roblox's PlayerModule now lives under StarterPlayer and takes `ControlModule.Enabled`.
    - Close brings the camera back behind the lead.
  - **Not built, the build after the verdict:** the machine's panel, Upgrade, the Power tab, the look switched in the world, and retiring the quiet tile and "You're home".
  - **Tested.**
    - Type check 0 new. Logic 9,870 passed, offline and in Studio, with `BaseLevels`' cases and TR21's three: the base's level, a machine's, and what a level does.
    - In the self-test, "Base view" passes 34 of 34, "HUD: TR19" 53 of 53, "Power" 88 of 88, "Breaker:" 139 of 139 and "Battery" 2 of 2. "Base: the plot's Breaker, bays" passes 28 of 28.
    - Two cases changed with TR21. A bay beyond the open ones can't show locked until AR16's plot brings its spots, since level 1 opens two bays and today's plot has two. The lift is now measured over the machines' floor, since the self-test's pad stands far above it.
  - **The take:** `build/captures/tr21/command_view_desktop.jpg`, opened by a real tap on the desktop (1655 by 756), on today's base.
    - On a phone, Studio's tools can't take it. Under the device simulator, the MCP resets the client's camera between calls, and the viewport doesn't draw while a call runs. Inside one call the game holds the view for 40 s with no change. The phone's look waits for the first session's run.
    - The take re-runs as "Take: TR21, the base's command view held open from home".
  - **Visually reviewed:** research's verdict waits. **Director-accepted:** no.

## TR22. The base shows its owner (Faber, with Modulo's plinth)

Research's entry, 2026-11-15, night. It answers the director's word to Modulo at about 22:04, "dont forget the base need to show of each players etc" (the register). What a base shows is research's call, tier 2. The design: `docs/design.md`, "The base".

- **Feel line:** walking the Strip, a player reads each base as someone's. The gate says whose it is and how far along. Inside it, their best Voidkin turns on a lit plinth, and their workers' rarity glows in the bays. They want theirs to look like that.
- **The block contains:**
  - **The gate's plate:** the owner's display name and the base's level, on both faces (Faber's text on AR14's plate).
  - **The showcase:** a lit plinth just inside the gate, seen from the Strip.
    - One Voidkin stands on it in its idle, turning slowly, with its Combat Power above it.
    - It's the one the player picks with "Show at the gate" on its character screen. Until a pick is made, it's the player's strongest.
  - **Each working bay** is lit in its worker's rarity colour (`docs/ui.md`, rule 3), and unlit while empty.
  - **Modulo's part:** the plinth's model in AR14's kit, and the bay's light as part of AR15's bay.
  - **Cases:** a logic case for the pick and its default.
- **Waits:**
  - a tap on the plinth that opens that Voidkin's sheet as a visitor sees it (TCP3's View Character);
  - visiting another player's base;
  - more on the plate.
- **Tests:** the cases, plus one take from the Strip of a base that isn't the player's own.
- **Order:** Faber's call, after TR21's blockout.
- **The rule, built, 2026-11-16 (Faber); the world's parts wait for AR16's places.**
  - **Implemented.** The save holds `Base.Showcase` (`docs/engineering-plan.md`, "The showcase at the gate"). `Collection.Showcase` gives the pick while it's owned. Otherwise it gives the strongest by Combat Power, then the higher level, then the lower Id, so the plinth never flickers between two. `SetShowcase` takes any owned Voidkin whatever its role, and "" gives it back to the strongest.
  - **Tested.** The case "Collection: TR22, the showcase at the gate stands the strongest until one is picked" passes in the 9,870.
  - **Waits:** the gate's plate, the plinth's Voidkin with its Combat Power and the bays' rarity light, on AR16's new plan; "Show at the gate" on the character screen; the take from the Strip.

## TR23. Day in the world's turn (Faber, then Modulo's day sky)

The director to Faber, 2026-11-16, after the base's install: "i feel like the world it a bit to dark and somber we need a day time". Asked how, the director picked "Add day to the cycle" in the builder's words: "Day, then dusk, then night, then back to day, across the whole world. Dusk and night keep their looks and get a smaller share of the cycle (my first split: day about 60%, tuned live). The lanterns and the void machines' glow fade by day and light up at dusk. A day sky is needed: our own, drawn by Modulo, or Roblox's built-in sky until then." The director also picked "Next piece, now": built before the Door's name, and the phone run then judges the light players will actually see. Then, to Modulo, read at 02:02: "we need a day / dusk sky box btw ask faber + lightning/atmosphere etc". Modulo draws the day sky and its seeds.

- **Feel line:** a player comes back to the festival in full day, a blue sky over the navy houses and the paper lanterns, the void machines still faintly lit. The afternoon slips into dusk and the lanterns come up, then night, then morning again.
- **The block contains:**
  - Day in the turn. `Rules.Night` holds each look of `Config.Lighting.Cycle.Order` for its Hold and crosses into the next. The seed is 30 minutes: 18 of day, 5 of dusk, 4 of night, and a minute's crossing between each.
  - `Config.Lighting.Phases.Day`, first the builder's seed on Roblox's built-in sky, then Modulo's Day sky with his seeds once it came (2f3430a), within the hour. Its sun is painted in the faces at `Toward`.
  - The day's shares: Glow is the share of the kit's glow (floors included), and Lights the share of the street's and the lead's lights. Both are full at dusk and night.
  - The debug jump takes the new phases ("Day", "ToDusk", "ToNight", "ToDay").
- **Waits:**
  - Research's verdict in the game.
  - The phone run.
  - The director's mist word, read by Modulo at 02:16: "a bit to much atmosphere imo like that mist is a bit to much". It was said on the first sheet, and the Day's haze is thin for it. Whether it also means the game's dusk haze (Haze 1, AR5's numbers) is with research.
  - A second dusk sky. Only if the director's "day / dusk" asks for one; Modulo asks the director.
- **Built, 2026-11-16 (Faber).**
  - **Implemented** in `Rules.Night` (the turn as an order of looks, `Night.Turn`, `Night.Phases`), `Config.Lighting` and `LightingController` (a sky per phase; the shares in steps of 0.02, so a crossing re-dresses the pieces about 30 times, not each frame). The two glow cases that computed a piece's glow read the live share too.
  - **Modulo's Day sky:** six faces uploaded under the group and Approved (`docs/asset-log.md`). His seeds are in `Phases.Day`: sun #FFE2B8 at 2.6, fill #8A8496, the sky's share of the fill 0.5, and a thin haze (Density 0.16, Haze 0.2, Glare 0.1). Floor, Glow and Lights are the builder's.
  - **Tested.**
    - Type check 0 new.
    - Logic cases: offline and in Studio, 9,936 passed. They cover the turn, each crossing's ease, the jumps, Day's look, sky and shares, and every phase in Config being in the turn.
    - Self-test: "Lighting" 47/0, with day's look, sky, glow share, lights share and the lead's light.
    - The whole suite: 2,202 passed, 0 failed, at 60 fps; the world report is empty.
      - The first whole run failed 17. Three were the Breaker chambers' case, which wanted a glow without the day's share; it's fixed.
      - The other 14 followed the camera case's one failure (TR11) through the Haymaker and plate cases. Each passed alone and in the second whole run.
    - In the game: the day-to-dusk crossing eases the brightness, and the sky swaps under the haze's peak at 29.6 s of 60. The client held 57 to 58 fps.
    - A single frame of about 90 ms came at about 26 s in two of four day-to-dusk crossings. It wasn't there in the other two or in dusk-to-night, and holding the lights didn't settle it either way. It's not attributed; the phone run watches for it.
  - **Visually reviewed:** the builder's captures only, at the spawn and on Lantern Row by day, on each sky.
    - On the built-in sky, the paving took a strong lavender-blue cast.
    - On ours, the base stands under big anime cumulus, and the paving is greyer and less blue. Lantern Row is clear far up the street with no mist, the navy houses and the lanterns read against the sky, and the clouds sit over the lanterns.
    - Research's pass is wanted.
  - **Director-accepted:** not yet.

## TR24. The first session whole, on a phone (Faber drives, research reviews)

Phase 2's gate, research's order of work, item 2 (`docs/decisions.md`, the register, 2026-11-15, night: "we work on the priority you believe we need to do first"). The run gives the in-game verdicts on AR16 and TR23 and one fix list ranked by what a new player feels. Started 2026-11-16 and stopped at the wrap, with only its tools kept (`NL_Debug`'s `DataExport` and `DataImport`); run again from here.

**The captures (research, 2026-11-16).**
- **How:** phone simulator, landscape, a fresh profile, the player's camera only (no free camera), HUD on. Play as a new player would: no debug jumps except at 16. Stills go to `build/scratch/faber/tr24/NN-name.png`, each with one line in your notes saying what happened and the server clock time. A burst is 3 or 4 stills about 0.3 s apart across the moment.
- **Arrive (AR16's verdict)**
  1. The first frame after loading, before any input: the base, the Breaker lit, the three shards.
  2. A turn on the spot, 4 stills a quarter-turn apart: the plot, the star, the sleeping places, the Door, the sleeping Tower.
  3. The HUD at rest on arrival, nothing touched.
- **Choose**
  4. Walking to the shards: one still at the first prompt the player sees. Note whether anything tells a new player what to do, and how.
  5. The pick and the break: a burst from the tap to the name up (TR4). Time from the tap to the name.
  6. The first second after the reveal closes: where the new Voidkin stands and what the HUD shows.
- **Fight**
  7. The way to Lantern Row: the Door from the player's side with its name, and a still on arriving on the Row. Time from leaving the base to the first enemy in sight. Note each wrong turn.
  8. The first fight: a burst at the lead's first hit landed, and one at the Shade's burst.
  9. One mid-fight still judged for the thumbs: does anything we need sit under a thumb?
- **Find**
  10. The first shard drop: a burst from the enemy's fall to the shard with its name readable. Note whether the name reads at phone size.
  11. Breaking it: one still at the name.
- **Work**
  12. Home with the Base tile (TR19): check your two-tap issue first, then the tap and the first frame home.
  13. The second Voidkin into a bay: a burst from the tap to the power coming on (TR18). Time it.
- **Build**
  14. The first gear, wherever a new player first gets one: a still of it in the Bag or Kit, and the stat it changes. If the session gives no gear yet, say so. That's a finding, not a failed run.
- **Want**
  15. The first sight of the Lamplighter's gate, one still. One still down the Strip from the base's gate (it sizes AR17).
- **Light (TR23's verdict)**
  16. Lantern Row by day, then jump to ToDusk and keep playing through the crossing: stills at day, mid-crossing, dusk and night. Watch the frame times across the crossing, and log every frame over 50 ms with its time and what was on screen (TR23's unattributed ~90 ms frame).
- **Throughout**
  17. Every wait over about 10 s: a still and its time (north star: nothing waits more than about half a minute). Every wall of text, any Robux prompt, every error in the output.
  18. The fps at three moments: on arrival, in the busiest fight, and at home.
  19. Anything that surprised you as the driver: a still and one line.
- **After:** the test profile back with DataImport.
- **Research's part:** the verdicts on AR16 and TR23 and one fix list ranked by what a new player feels, written in TR24 by research from these stills.

**The run (Faber, 2026-11-16, 13:43 to 14:14, by the PC's clock).** Driven in the device simulator (an iPhone 16 Pro in landscape) on a fresh profile. The walks were scripted (`character_navigation`), so wrong turns aren't measured. The one debug jump was item 16's light, plus a jump back to Day for the walk to the gate. Each still has its line and time in `build/scratch/faber/tr24/notes.md`, beside the stills and takes (scratch). The test profile was put back with `DataImport` and read after a rejoin: 9 Voidkin, 52,392 Credits, no difference. The simulator was switched off and Studio released. The driver's findings, in the list's order, for research's ranking:
- **Arrive.** The world shows 10.4 s after the join (loading sky, then about 2 s of black). The three starter shards stand 37 to 38 studs from the arrival point: small grey Neon blocks that read as the Breaker's panel lights. Nothing tells a new player what to do.
- **Choose.**
  - The prompt is Roblox's default ("Pip's shard / Choose", a 0.4 s hold), and only one shard's prompt shows at a time, so the other two go unnamed until walked to.
  - The shard goes into the Breaker, which breaks it on the battery (generation 0). After about 6 s it shows "Ready to open", but nothing opens: the player must find the Breaker's prompt.
  - Tap to name: about 1.1 s. One 53 ms frame at the reveal's start.
  - Afterwards Pip stands between the player and the Breaker, back to the camera, and nothing points to Lantern Row.
- **Fight.**
  - The Door shows no name and no prompt, and a lamp post stands in the line of sight. Through it, Shades are in sight 32 to 38 studs ahead on arrival (13:52:16).
  - First hit and number at about 6 s, first kill at about 11 s with a small white flash, and Pip at Level 2 by 17 s.
  - Pip's hat fills the camera in the first seconds (19).
  - The fight sits about 30 studs off to the side. Later the busiest fight, an Elite Brawler, happened beside and behind the player, off the screen, with only its bar showing (19).
  - Nothing sits under a thumb.
- **Find.** The first drop is a "+1 Watt's shard" toast at the screen's right edge. There's no shard in the world, so the name reads only in the toast.
- **Breaking it.**
  - Watt's shard takes 30 s at the Breaker's screen with nothing to do (17).
  - Its reveal reads "WATT" about 1 to 1.5 s after the tap.
  - After it, the Breaker's screen says "No shard yet. They drop on Lantern Row.", and the HUD hint still says "Watt's shard: into the Breaker" (stale).
- **Work.**
  - The last session's "two taps on the Base tile did nothing" was the simulator's touch offset (62 px left), not the game. With the offset, the tile works.
  - While a pack engages, Home is refused with "In a fight", and the packs keep coming to a standing player, so going home means walking out of reach first.
  - Home takes about 1.2 s from the tap. Its first frame faces the plot's edge, a lamp post and Pip's hat.
  - Nothing points to a bay. Bay 2's "Set worker" opens the Base screen's "Who works?", and on the tap on Work the power is on in the take's next picture, within 0.2 s: "18 / 0 kW", "Watt · 18 kW".
  - In the world, Pip stands in front of the bay and hides Watt.
- **Build.** No gear: after 36 kills the save's Items are empty, and the Gear tab says "Soon". This is a finding, not a failed run.
- **Want.**
  - Down the Strip from the base's gate: bare paving to the horizon (AR17's install is held).
  - The Lamplighter's gate shows from 300 studs as a dark shape at the Row's end, behind enemy bars. At 35 studs it's closed doors with two clocks and no name, with the prompt "the Lamplighter / Challenge".
  - A Lv 2 Pip doesn't survive the walk there. It fell to Lv 6 and 7 Brawlers at 14:10:20, and "Healing 1:30" is a 90 s wait (17).
- **Light (TR23).**
  - After the jump to ToDusk, nothing visibly changes for 30 s. Then the sky swaps between two pictures at the blend's middle, and the haze doesn't hide it. The natural crossing at 13:48:30 did the same.
  - No frame over 50 ms through the crossing, the jump to night, the walk or the elite fight.
- **Throughout.**
  - Waits over 10 s: the join (about 10 s), Watt's break (30 s), Pip's healing (90 s).
  - No wall of text and no Robux prompt.
  - Errors: the run's output wasn't read before the rejoin cleared it. The rejoin's boot had 0 errors, plus three Roblox warnings for an asset id that is in neither `src/` nor the place.
  - fps: 60 on arrival, 60 in the busiest fight, 58 at home. That's the PC under the simulator, not a phone.

**Research's verdicts and the fix list (Quaestor, 2026-11-16, 14:18),** from the stills in `build/scratch/faber/tr24/`; motion only as the takes' notes give it.
- **AR16, the base. Felt:** by day the player arrives on a wide grey yard with the machines small and far, and the void's light barely registers; at dusk the Breaker's and the Door's light carry and it's ours (`01`, `02-turn-*`, against `06`, `07-door`). **Tier:** works, not yet competent. **Bold thing:** the Door's light at dusk; by day nothing carries. **Fixes:** (1) the size is the main one, already in the package (`docs/research/rework-2026-11-16.md`, part 7): the first frame should hold the Breaker large; (2) the starter shards read as the Breaker's panel lights, small grey blocks at 37 studs: they get the shard's own shape, larger, lit so they hold in daylight, and named all three at once; (3) the void's light holds by day on the Breaker, the Door and the star, or the base reads as any yard.
- **TR23, day in the turn. Felt:** day is clear and the Row's lanterns still read, but the turn to dusk is a cut, not a turn: 30 s of nothing, then the sky jumps from blue to violet (`16-pop-a`/`b`). **Tier:** works. **Bold thing:** the Row at dusk, the lanterns over violet (`16-c`). **Fixes:** (1) the light starts warming from the blend's first second, so the swap lands on a sky already near it, and the swap sits under a short haze peak; (2) day keeps one sign of the void (a violet top to the sky, the far shards in view), or it reads as a default sky. Frame cost: clean (no frame over 50 ms).
- **The fix list, ranked by what a new player feels.** The package's pieces answer some of them; those are marked.
  1. **Nothing says what to do next,** at arrival, after the reveal (nothing points to the Row), after Watt (nothing to a bay), and the hint goes stale. One next-step line and one marker in the world on the next target, at every step of the first session.
  2. **The fight happens off screen:** Pip fights 30 studs to the side, and the elite fight was behind the player with only its bar showing (`09`, `18`). The game is watching your Voidkin fight: the lead fights in front of the player, in the camera's view.
  3. **The lead blocks the view:** Pip's hat fills the camera (`19`), and Pip stands in front of the Breaker and the bay (`06`, `13-bay-e`). The lead stands beside the player, out of the camera's line, and fades when it's between them.
  4. **No gear in the first session:** 36 kills, an empty bag, "Soon" (`14`). The north star's Build beat is empty. Answered by the package's chests (part 11: the third kill's chest).
  5. **The waits:** Watt's break takes 30 s with nothing to do, "Ready to open" waits for the player to find a prompt, and Pip's fall costs 90 s. In the first session a starter's break takes a few seconds and opens itself when the player is there, and a fallen lead's wait is short enough to walk home.
  6. **Trapped in a fight:** Home is refused "In a fight" while packs keep coming to a standing player. Picked at 17:29, Faber's way (b): a Shade notices the lead only while the lead is engaging or its own pack was hit, and the lead's own targeting still starts fights. Home stays out of combat only (the director, 2026-11-15); the short hold, research's first way, is withdrawn because it reverses that word.
  7. **The walk to the gate kills a Lv 2 Pip** against Lv 6 and 7 Brawlers (`19-pip-down`). Checked at 14:20: the ladder holds, no number changes. The Row spans levels 1 to 9 in its hour, at 50 kills a level after the first two (`Config.Growth`, `Early`), so the run's 36 kills leave Pip at Lv 2, and Lv 5 to 7 packs are meant for its last third. What hurts is the cost of the lesson, which is fix 5's 90 s; and each pack's bar should show its level against the lead's before it engages.
  8. **The first drop is a toast at the screen's edge,** with no shard in the world (`10`). A drop falls in the world with its name and flies to the player: the same flight as the package's chests.
  9. **The day-to-dusk cut** (TR23's fix 1).
  10. **The Door shows no name** and a lamp post stands in its line of sight (`07-door`); the gate at 35 studs has no name either (`15-gate-c`).
  11. **A Shade's death is a small white flash** (`08-shade-burst`); the kill should land.
  12. **The join's 10 s,** with about 2 s of black.
- **Not findings:** nothing under a thumb, no wall of text, no Robux prompt, 60 fps on the PC.

**Fixes 1 to 3 (Faber, 2026-11-16, 16:09 to 16:41, by the PC's clock).** Research's fixes, built as given. The player's camera is never moved for any of them (the director, 2026-11-14, night).
- **Feel lines.** (1) Wherever a new player stands, one line under the HUD's top says the next thing to do, and a bobbing chevron hangs over where it is done, or an arrow at the screen's edge points the way. (2) The player looks at a pack and their Voidkin goes to it: the fight they watch is the one in front of them, and one coming from behind is waited for in view. (3) The Voidkin stands at the player's right shoulder, out of the camera's line, and turns see-through while it passes between.
- **1, the next step.** `Rules.Hud.NextStep` says one line and its target: at home, the first shard to choose (the three starters), ready shards to open, the bag's shard into the Breaker, an idle Voidkin to the lowest empty bay ("Watt: to work in Bay 2"), a shard breaking, then "Through the Door: Lantern Row". In a ground, only "The Lamplighter waits at the gate" near the gate, once a bay has worked and until he's beaten. Nothing during a keeper's try. The HUD's chip says the line, and `UI.Guide` puts its chevron over each target on the World layer, or one arrow at the frame's edge when the target is off the frame or behind the camera. Both step back within `Config.Hud.Guide.Near` of the target, where its prompt speaks. The shards' hint stays at the base only (the director, 2026-11-15).
- **2, the fight in view.** The client says where its camera looks (`ViewController`, Net `View`, a flat bearing). `Rules.Fight.LeadTarget` with `Config.Combat.Lead.View`: the lead keeps its target in the leash, then takes the nearest coming at it, then the nearest in the camera's arc, then the nearest within Guard of the avatar. A Shade coming from out of view is waited for at the lead's place, at most `View.Wait`, before the lead goes to meet it. A view older than `View.Fresh` falls back to the avatar's facing.
- **3, the lead out of the view.** Its place is beside the avatar on the camera's right (`Lead.Side` plus half its own width, `Lead.Ahead` in front), facing where the camera looks. It walks there again once the place moves `Lead.Settle` away, so a turning camera doesn't drag it. During a keeper's try it keeps the old place (`Combat.Keeper.Side`). On each screen, a lead between the camera and the avatar's head, or too near the camera, fades to `Lead.Fade.Transparency` over its `Seconds`, through `LocalTransparencyModifier`, and comes back once clear. It lets go of a lead that's down or gone home, and of the one the spectate camera follows.
- **Tested.**
  - The type check: 0 new.
  - The offline logic: 9,974 passed, 0 failed. The new cases are the next step at every first-session step, the view rule's order, the leash, no view keeping the old rule, and `Fight.InLine`.
  - The self-test case for fix 2 in play: 8 of 8. A Shade in view is taken on at once. One from behind the camera is waited for at the place (-0.1 studs toward it, the place at -1.5) and met at 3.6 s, past its 3 s wait. With the rule tuned off (Arc 180), the case fails (3.4 studs toward it), so it tests the rule.
  - The lead's place on the camera's right, in play: passed.
- **NOT VERIFIED, and why:** the PC is on the Windows lock screen (the foreground is LockApp, read at 16:42). Brought forward, Studio draws for about 27 s, then stops. A playtest then draws no frames (render 0 a second, heartbeat 59), so nothing that steps on the render runs. That covers the fade's and the guide's self-test cases (fade 0.00 and no chevron shown, with nothing drawn) and 20 effect checks in the `Fight:` set (the Shade's burst, the flurry, the stamp's cleanup, the Held Note's touch, the hit's flash and tremble). Each effect sat frozen where it began. With Studio in front, the Shade-rig case passed alone, 24 of 24. They're rerun once the screen is unlocked, before the phone review.
- **Waiting:** the review from the player's camera on a fresh profile, in the device simulator, needs the screen unlocked. It covers arrival, choose, ready, the Door, the Row's fight in view with the camera turned, the fade, Watt into a bay, and the gate line. Then research's pass.
- **For research:** `docs/ui.md`'s "Over the dock" row is now the next-step line at home, with the gate's line its only one in the grounds. The words are seeds for your pass (tier 1).

**Fix 9 and the mist (Faber, 2026-11-16, 17:09 to 17:12, by the PC's clock).** Research's order (c): the director's word of 16:50, "imo we should remove all that in base and around it it way to much" (`docs/decisions.md`), with fix 9, the day-to-dusk cut, under a new cover. The light's colours are untouched: "less somber" waits on Modulo's takes and research's pick.
- **Feel line:** walking from the plot up the side street at any hour, the player sees the base and the Strip in clear air, and the Row's haze only from its gate on. As the turn goes to dusk, the light starts warming at once, and the sky changes behind a passing veil of colour over the horizon, never a fog over the yard.
- **What changed** (`Config.Lighting`, `Rules.Night`, `LightingController`):
  - **The mist:** south of the Row's From line, each phase's Atmosphere wears `Clear.Atmosphere`, with no density and no haze, over its own. The Row keeps its haze. The walk up the side street turns one into the other over Enter, 1.5 s, and a jump lands at once.
  - **Fix 9, the light:** a crossing's light, haze and glow warm from its first second, a front-loaded curve (`Rules.Night.Warm`) with `Warm`, 0.75, of the way there by the middle. The sky still swaps at the middle, under the veil's peak. Before, the eased turn moved 0.08% in the first second and stood at half at the swap.
  - **Fix 9, the cover outside the Row:** a mist pulse over a clear yard would be its own flash, so the swap hides under `Clear.Veil`, Haze alone, 2.5 at its peak. That's the coloured layer over the horizon, which veils the sky. Density, which hides the ground, stays at 0 (the handbook, "Atmosphere"). The Row's veil is as before. All are seeds, tuned by playing.
- **Tested:** type check 0 new. Logic: 10,014 passed and 0 failed offline, with the new Night case, its 27 checks over the clear air, the warm curve and the turn's own share.
- **NOT VERIFIED, and why:** the look itself. The client's lighting steps on render, and the PC is still on its lock screen, so the lighting self-test's new checks (the base clear, no haze) and the swap's look wait. One question only a capture answers: whether Haze shows a veil with Density at 0. If it doesn't, `Clear.Veil.Density` takes a small value, and the yard is checked for a fog flash.
- **Waiting:** captures from the player's camera at the base and on the side street at day, dusk and night, and the day-to-dusk crossing from the base and from the Row (`NL_Debug:Invoke("Night", "ToDusk")`), for research's pass.

**Fix 5, the first session's waits (Faber, 2026-11-16, 17:14 to 17:24, by the PC's clock).** Built as research gave it. Every number is a seed, tuned by playing.
- **Watt's break:** the Named grade breaks in a starter's 6 s, down from a Standard's 30 (`Config.Shards.Grades`).
- **Ready to open:** a starter's shard and Watt's open themselves once their player stands on their plot (`Opens` on the two grades; `Rules.Breaker.SelfOpening`).
  - BaseController looks every 0.5 s, and only with no reveal on screen and no screen open but the Breaker's.
  - It asks `Open` as a tap would, and the server checks it the same way. After a no, it waits 5 s before asking again.
  - Rolled shards still wait for a tap. The self-test turns self-opening off for a run, since its cases open their shards by hand, and its own case turns it back on.
- **The fall:** until the player beats their first keeper, a fallen lead heals home in `Combat.Lead.Home.FirstFallen`, 20 s, about the walk from the Row's packs to the plot. Then it's Fallen's 90 (`Rules.Carry.HomeFor`). FightService and LeadService both read it through `FightService.HomeOf`, so the card's time, the send-out refusal and the Training machine agree. One edge is left as it is: a Voidkin that fell before the first keeper's win and is still healing afterwards takes the longer rate from then on.
- **Tested:** type check 0 new. Logic 10,037/0 offline and in Studio, with two new cases: the wait by keeper wins, and the self-opening grades and order. The self-test's new base case passed whole in play: Watt's shard waits in the Row, opens itself with no press once the avatar is home, and its reveal names Watt.
- **NOT VERIFIED, and why:** the rest of "Base:" ran 137 passed, 26 failed. Every failure is a layout, plate or turning check, and the lock screen reports the camera's viewport as 1×1 (read in the run, before 17:24), so taps measure 41 px and pieces fall outside the safe area. They rerun once the screen is back. Seeing the reveal come up by itself on the plot waits on the same screen.
- **For research:** the 90 s and 30 s in `docs/design.md`'s words, if they're there, are yours to update.

**Fixes 6 and 10 (Faber, 2026-11-16, 17:27 to 17:35, by the PC's clock).**
- **Fix 6, trapped in a fight, way (b), research's pick at 17:30.** The first way, Home after a hold, would have reversed the director's "only when out of combat", so it was withdrawn.
  - A Shade notices a lead within Notice only while that lead is fighting (`Combat.Shade.NoticeIdle` false; `Rules.Fight.ShadeTarget`'s `idle`). It still answers a lead that hit it or its pack, wherever that lead is, and keeps a target once a fight is on.
  - A keeper still comes for its challenger at once.
  - A player who stands is no longer pulled into a new pack. The lead's own choice starts a fight: in its leash and in the camera's view, fix 2's rule.
  - **Research's watch, for the phone walk:** whether, after a pack dies, the lead's leash chains it into the next pack, so a player who wants Home still can't get out. If it does, it goes to research with the capture, unpatched.
- **Fix 10, the names.** `SignsController` puts World-layer plates, kept under the top band, over two places:
  - **The player's Festival Door:** over its arch, "Festival of Battles", with the ground it goes to under it ("Lantern Row"). It stays apart from the base's machine plates.
  - **The festival gate:** its ground's name to the side street, out to 120 studs.
  - Words, sizes and reach are `Config.World.Signs`, the builder's seeds, a block until research's pass.
  - **The flood mast before the Door (`07-door`):** one of the base plan's two `FloodMast`s (across ±13.6, along -50; Modulo's AR16 plan). Moving it goes with (e), the base's three sizes in grey, which lays every place out again; the export isn't edited.
- **Tested:**
  - Type check 0 new. Logic 10,086/0 offline and in Studio, with fix 6's new case.
  - Studio first failed 2 of AR20's colour checks: the engine's `Color3:Lerp` at 1 isn't exact. They now compare within 1e-4.
  - In play: fix 10's case passed (the words, and the Door's plate over its arch). Fix 2's case passed under fix 6: a Shade out of view waits, and the lead meets it after its wait. Fix 5's case, after two fixes to its own setup, passed 14/0. The first fix dismisses a reveal left up, since at the playtest's join a leftover Watt shard opened itself on the plot, the feature working. The second turns self-opening on only once the avatar is off the plot.
- **NOT VERIFIED:** fix 3's fade and fix 1's marker, again, on the lock screen. The signs' look waits on the screen too.

**Fix 8, the drop in the world (Faber, 2026-11-16, 17:37 to 17:42, by the PC's clock).** The grey block, to be judged in motion.
- **Feel line:** a Shade's drop pops out of where it fell, bounces once on the street and sits a beat with its name over it, then is pulled into the player, slow off the floor and fast at the end, and lands in a flash as its toast says it: the player sees what they won and sees it come to them.
- **What was there:** the leap of TR2, a 1.4-stud block arcing 7 studs over 0.8 s. In `10-first-drop-b` it's a speck by the lanterns.
- **The block:**
  - `Rules.Flight` is the path, in pure Luau and four beats: Pop, Bounce, Rest and Pull. The package's chests take the same flight when they're built (the director's "Automatic nearby chest collection").
  - `Effects.Drop` replaces `Effects.ShardLeap`. The hero shape is the shard alone, 2.4 studs, spinning, with its name plate from the landing to the pull.
  - The toast now comes as it lands, through the effect's `landed`.
  - Seeds in `Config.Effects.Drop`, 1.9 s whole.
  - **Levers:** the rest's hold, so the name is read, and the pull's ease-in, the acceleration that makes it snap into the player.
  - **Not in the block:** layers (a trail, a ring on the floor, a sound), the shard's own model, and the credits' fly, which is the HUD's as before.
- **Tested:**
  - Type check 0 new. Logic 10,109/0 offline, with the new "Flight:" case (23 checks: beats, peak, landing, the ease-in, a walking player).
  - The play case ("HUD: TR24's fix 8") is NOT VERIFIED: the screen is locked, and the effect runs on render.

**Fix 11, the kill lands (Faber, 2026-11-16, 17:52 to 17:58, by the PC's clock).** The block, to be judged in motion.
- **Feel line:** when the player's Voidkin lands the last blow on a Shade, both freeze a beat longer than any hit, the body flashes as a critical does and the camera kicks once, and the blow throws the Shade back off its feet, so its lantern bursts where it lands, 6 studs from where it stood.
- **What was there:** a killing hit held 0.09 s at its own rung, with no camera, and the beat's ordinary push, about a stud. So the body dropped on the spot, and the burst read as a speck at 30 studs (`08-shade-burst`). Fix 2 already brings the fight into the view.
- **The block,** with its levers:
  - **Hitstop:** a killing hit holds at least `Combat.Hitstop.Kill`, 0.13 s.
  - **Flash and camera:** it lands at least at rung `KillRung`, 4, a critical's row, so its flash is 0.08 s at 0.7 and the player's own lead's kill kicks the camera at 0.35 trauma. It comes through the server's word on the hit (`raise`), the only place a kill is known. Its number grows by the rung, as a critical's does.
  - **Knockback curve:** `Rules.Fight.Throw` throws the body at least `Combat.Push.Kill` 6 studs over 0.3 s, times its weight, so an elite moves 2.4 and a keeper 0.9. The server glides it, and a thrown body is told not to walk back. Each screen draws it from its own hold's end, as a push.
  - The burst, AR2's art, is unchanged: Modulo's, and its look is the content check's.
  - **Not in the block:** a kill sound (no hit sound exists yet but the Haymaker's; research's pick from the library), the burst's own size or light (AR2's), and a launch with height.
- **Tested:**
  - Type check 0 new.
  - Logic 10,144/0, offline and in Studio, with the new "Fight: TR24's fix 11" case (16 checks).
  - In play, on the server: a killed Shade's body moved 0 studs through the hold, then 6.00 studs between 0.13 and 0.43 s, and stayed there to 1 s.
  - The killing hit reached the client with the kill's hold of 0.130 s. Both kills were a lead's signature at rung 7, so the ordinary hit's raise to rung 4 is logic-tested only.
  - **NOT VERIFIED:** the drawn throw, the flash and the camera's kick, since the screen is locked and they run on render. To judge in motion: the Row's fight from the player's camera, with the Down clip during the throw, and the burst landing where the body does.

## TR25. Attributes in the resolver, with the stat sheet (Faber)

Part 12's order, item 4.2 (`docs/research/rework-2026-11-16.md`, parts 1, 2 and 4; the contract in `docs/engineering-plan.md`, "Attributes in the resolver"), on the director's yes of 2026-11-16, 16:50, with research's names.

**Scope, set at the start (18:12).**
- **The block:** the five attributes as content; their rows, Mains and shapes in Config; the resolver's three steps with their lines; the even foe; the sheet's two headings with each rating's chance; the enemies solved again so their targets hold; the cases.
- **What waits:** an equip's green gains (with items, 4.3); attribute lines on gear (items); Combat Power's refit (research, `sim.py` section 16); `attributes.py` reading Config, as `sim.py` does (research's file); the sheet's look in Modulo's UI direction (the inventory piece, 4.5).

**Faber's build (18:12 to 18:26).**
- **Content:** `Definitions/Attributes.luau` holds Might, Finesse, Vigor, Spirit and Insight, each with its id, name and job.
- **`Config.Stats.Attributes`:**
  - Convert, Main and Shape are `attributes.py`'s ATTR. The shapes are its fitted level-1 points (report A1).
  - The old own base (`Base`, `Class`) is gone.
  - Regen's `Class` is empty: the Healer's 1.5 moved into its Main.
- **`Rules.Stats.Resolve`:**
  - Its order: points (Base, Level, Stars, `Item:<slot>`), then `Attr:<id>`, then `Main:<id>`, each a line.
  - The block gains `Attributes` and `Main`.
  - Power is untouched: it reads the Battle Attributes only.
  - `Stats.EvenFoe(level)`: `Config.Stats.EvenFoe` × G.
- **The even foe's ratings** are the builder's seeds, for research to confirm. They are the mean of the five classes' on-budget builds with attributes, at each ground's first and last levels (Hit 76, Dodge 41, Critical 63, Critical Resist 120, Block 41, Penetration 83, Elemental Resist 97 a G). Across the grounds they run 0.8 to 1.2 of these, which moves a shown chance under 2 points.
- **`Rules.Sheet`:**
  - The Basic Attributes come first, the Main marked. Then the Battle Attributes, under the one caption "chances against an even foe": Core; Offence and Defence paired (Hit | Dodge … Penetration | Block); Sustain (Regen | Lifesteal).
  - `Sheet.Odds` is `Hit.Odds` both ways against the even foe, plus `Stats.Chance` for Elemental Resist.
  - Critical Resist reads in points of the foe's chance it takes off.
- **The screen:** a rating's chance or effect sits on a line under its total, smaller. "-12% their Critical chance" doesn't fit beside a total in the smallest phone's half panel (about 127 points), so all seven take one place. The Main tag is a small Primary "Main" at its total's right.
- **`Config.Enemies`,** solved again by its own method against the bare Common Warrior's new figure (Health 516, Attack 116, its own ratings), so 5 s and 6%, 18 s and 35%, 45 s and 70% hold. Each Health is about ×1.24 and each Attack about ×0.65.

**Checks (18:26).**
- Type check 0 new.
- Logic 17,243/0, offline and in Studio. That includes the new Stats cases (the A1 figure by hand, every conversion and Main a point at a time on every class, linearity, Power blind to the totals, the even foe) and the Sheet cases (each shown chance the hit's own and under its ceiling, on every Voidkin and on 10^12 points).
- Boot errors 0.
- `attributes.py` on the same numbers:
  - each class's Main is its best attribute at level 30;
  - the lowest secondary is 0.43 (Warrior's Finesse);
  - class against class is within 0.03 of today's edges at levels 10 and 40;
  - Combat Power is 92% (any gap) and 97% (10% faster), until research's refit.
- **NOT VERIFIED:** the client self-test "Voidkin screen: Overview's stat sheet…" and the phone captures, long numbers included. The screen is locked (0 frames a second, a 1 × 1 viewport).

**Research's answers (Quaestor, 2026-11-16, 19:13).**
- **The even foe: confirmed.** `attributes.py` gives the same means (Hit 75.8, Dodge 41.2, Critical 62.6, Critical Resist 119.7, Block 40.9, Penetration 82.9, Elemental Resist 96.8 a G). Across the grounds Dodge and Block run 0.57 to 1.43 of theirs, not 0.8 to 1.2, so a shown chance can move up to about 3 points. It stays one fixed reference, as part 4 designs it.
- **`attributes.py` reads `Config.Stats.Attributes`** (5194c72) and reports any drift from its fit: none today.
- **Combat Power's refit,** on the attribute builds (`attributes.py`, report A8; `seeds.json`, "combatPower"), for `Config.Stats.Power.Weights`: Health 0.62, Attack 4, Defence 2.9, Regen 2.9, Hit 0.45, Dodge 1.4, Critical 0.57, Critical Resist 0.17, Block 0.91, Penetration 0.44, Elemental Attack 3.6, Elemental Resist 0.18, Critical Damage 130, Critical Guard 130, Lifesteal 630. The higher Combat Power now wins 97% of same-level duels (99.7% where one wins 10% faster), against 92% on the old weights.
- **In Config (Faber, 19:28):** the 15 weights in `Config.Stats.Power.Weights`, equal to `seeds.json`'s. No logic case pinned a figure: 23,090/0.

## TR26. Items, class rules and the comparison (Faber)

Part 12's order, item 4.3 (`docs/research/rework-2026-11-16.md`, part 10; the contract in `docs/engineering-plan.md`, "Class rules"), on the director's yes of 2026-11-16, 16:50.

**Scope, set at the start (18:30).**
- **The block:** the item rows; each preset's class pairs (`Hands`) with migration 6; the resolver's two guards; Equip and Unequip, one transaction each with its refusals; `Stats.Compare`; Studio's `ItemGive`; the cases.
- **What waits:**
  - With the inventory (4.5): the screen's words for each refusal, the green gains after an equip, the bag's arrows and the slot's dot. Nothing in the game can equip yet but the Act remote.
  - With chests (4.4): an item's main stat by its slot, its rolled lines, its sockets and the drop's lean toward the lead's class.
  - The Warrior's off hand stays the Short Sword until the director's pick (the register, item 7).

**Faber's build (18:30 to 18:39).**
- **`Definitions/Items.luau`:** one row per kind, ten armour and ten weapons, each weapon with its class.
  - A row's `Slot` names the kind of slot: `Ring` and `Earring` fit either of their two.
  - `Items.Fits(row, slot, class)` is the one answer to what goes where: a weapon only in its own hand, for its own class; armour only in a shared slot of its kind.
  - `Gear` gains `Family`, `SlotsOf`, `IsHand` and `IsShared`.
- **The save:** a preset is `Slots` (the twelve shared) and `Hands` (a class to its pair).
  - Migration 6 gives every preset its `Hands`, and moves a hand found in `Slots` under its item's class, or drops it.
  - The live Test save took it on load.
- **`Rules.Stats.Resolve`** reads the twelve shared slots in Gear's order, then the pair of the Voidkin's own class, and only an item whose row fits there. So a save edited by hand applies no wrong weapon, and the lines read in the same order every time (they followed hash order before).
- **`Rules.Regalia`:**
  - Equip is `Act("Equip", { Preset, Slot, Class?, Item? })`. A weapon's class comes from its row when the request names none; an empty or absent item takes off what's there.
  - The refusals: `NotOwned`, `WrongSlot`, `WrongClass`, and `Unknown` for a request that isn't one.
  - An item moves within a preset rather than being worn twice, and one item may sit in several presets (`docs/design.md`, "Presets").
  - It's registered by `Services/Main/RegaliaService`. The lead's block follows by itself, since LeadService resolves it again on every change, so an equip applies at once, as a level does. My call: no fight guard in grey.
- **`Stats.Compare(data, preset, owned, item, slot?)`** is the resolver run twice. It returns the slot, each Basic and Battle Attribute's change, Combat Power's change and the two blocks.
  - Without a slot, a ring or an earring goes where Combat Power ends highest: an empty one before a worn one, the first on a tie.
  - A weapon is compared for its own class only.
- **Studio:** `NL_Debug:Invoke("ItemGive", who, def, rarity?, lines?, tier?)` puts an item in the bag and answers its id.
- **The Stats cases** wore a made-up `case_item` in any slot, and one put a single weapon on every class. They now wear real rows in shared slots.

**Checks (18:39).**
- Type check 0 new.
- Logic 17,645/0 offline and in Studio: 402 new checks, in the Regalia cases and Data's step 6.
  - The rows match `Gear.Weapons`.
  - Each of nine wrong requests is refused with its reason and changes nothing.
  - A preset applies only the Voidkin's own class's pair.
  - Six hand edits of a save each apply nothing.
  - A repeated op id answers its first answer, even after the slot has changed since.
  - The comparison equals the resolver twice and picks the better ring.
- Boot errors 0.
- **The Act path in a playtest, on the live Test save** (exported first, imported back after: 0 items, as it was):
  - A Rare Great Axe with +1000 Health raised the Tank lead's MaxHealth from 3664 to 4664 at once.
  - The same op id sent again answered its first answer.
  - A Sword in the Tank's hand: `WrongClass`. With no class named, it went under the Warrior's pair and the Tank's figure didn't move.
  - The unequip took it back to 3664.
- Nothing players see changed, so there's no capture to take.

## TR27. Chests and bulk opening (Faber)

Part 12's order, item 4.4 (`docs/research/rework-2026-11-16.md`, part 11; the contract in `docs/engineering-plan.md`, "Chests"), on the director's yes of 2026-11-16, 16:50.

**Scope, set at the start (18:41).**
- **The block:** the chest rows; `Config.Chests` on the builder's seeds; the save's `Bag.Chests` and `Settings.Salvage`; `Rules.Chests` (the roll, the open, the salvage and its keep, the drops); the drops at a fall and at a keeper's win; `Act("OpenChests")` and `Act("SetSalvage")`; Studio's `ChestGive`; the cases.
- **What waits:**
  - Research's fit of every table to part 11's targets (below).
  - The Dawn series (`docs/design.md`, "Regalia"): Legendary items of their own rows, from the last ground and the Tower, with their icons.
  - The show, on their own feel lines: the chest's fall and its fly-in within `Reach`, the reveal, the summary after an "Open all". With the inventory (4.5): the bag, the salvage's control, the refusal words.
  - Forge stones from the salvage, with the Forge. The products case, with the store: `src` has no product rows.

**Faber's build (18:41 to 18:54).**
- **`Definitions/Chests.luau`:** three tiers in every ground, `<ground>_<tier>`: a "Common Chest" (a Shade's), an "Elite Chest" (an elite's, and a keeper's after its first win) and a "Keeper's Chest" (a keeper's first win), each "of <Ground>". The tier names are mine.
- **The save:** `Bag.Chests` (a count by chest id) and `Settings.Salvage` (a rarity, or ""). Reconcile added both to the live Test save on load, so no migration.
- **The drops:**
  - `Rules.Chests.Dropped` runs inside `Drops.Give`, the kill's transaction, on a second roll `DropService` draws: a Shade's chest at 5%, an elite's every time, and the account's third kill always.
  - A keeper's comes from `Progress.KeeperWon`, its win's transaction, since the fall and the win are two listeners with no set order: the Keeper's Chest on the first win, an Elite Chest after.
- **The roll, `Rules.Chests.Roll(chest, classes, draw)`,** every number from `draw`, in a fixed order:
  - **The rarity:** from the ladder's row, the ground's order plus the tier less one, so an elite's chest reads as the next ground's Shade chest.
  - **The slot:** one of the fourteen alike, so a ring or an earring comes twice as often as a helmet. A weapon's class is the lead's 60% of the time, else another class the player owns.
  - **The main stat:** fixed by the slot, or a Basic Attribute for jewellery.
  - **The lines:** 1 to 4 by rarity, never the main stat and never twice. A weapon weighs its class's Main ×3.
  - **The sockets:** 1 to 4, empty.
  - **The values:** an item's worth is `PowerPerG` × its rarity's share × G at its ground's last level. The main takes half, the lines share the rest, each line within ±15%, turned into points by `Rules.Chests.Price`, the line's Combat Power a point at the generic row (Might 6.1, Insight 5.4, Attack 4, Health 0.53).
  - `PowerPerG` (63.5) is the sim's full-set gear share at rarity 1 in Config's Power weights, over fourteen.
- **The open, `Rules.Chests.Open`:**
  - At most 50 and at most what's held. It refuses `Unknown`, `NotEnough` or `BagFull` (items held plus the count past 300) before it rolls.
  - The chests leave the bag in the step that writes every item.
  - The answer: the kept item ids, the number salvaged and their Credits.
  - Registered in `RegaliaService`, with a `Random` seeded inside the transaction.
- **The salvage:** an item of the set rarity or under turns into Credits by rarity × G, unless `Keep` finds it would raise Combat Power through `Stats.Compare`. The salvage reads "this rarity and under", my call, since that's how a player picks it.
  - It's compared as `docs/design.md` says ("Chests", "Auto-salvage"): a weapon against its class's best owned Voidkin, a piece every class wears against each class's best (`Rules.Chests.For`). A weapon of a class nobody owns is salvaged. My first default compared armour against the lead only; I found design's line after a62e0a7 and followed it in the next commit.
- **Studio:** `NL_Debug:Invoke("ChestGive", who, chest, count)`.

**The seeds research fits** (`Config.Chests`, every number the builder's): the eight-row rarity ladder; the drop chances; the class lean (0.6); the item's worth (`PowerPerG`, the rarity shares, `MainShare` 0.5, `Spread` 0.15); lines and sockets by rarity; the main stat by armour slot (Helmet and Chest Armor Health, Shoulders Defence, Gloves Critical, Bracers Hit, Boots Dodge, Cloak Block); the line pool's weights; the salvage's Credits. The targets are part 11's: an Uncommon in the first hour, a Rare at 3 to 4 hours, an Epic at 10 to 15, a Legendary at 35 to 45, about 20 chests an hour.

**Checks (18:54).**
- Type check 0 new.
- Logic 22,938/0 offline and in Studio: 5,293 new checks, in the Chests cases. With the Keep as design has it, 22,939/0 offline.
  - Every ground has its three chests, each named for its ground, its odds summing to one.
  - 400 rolls: each one the same twice from the same draws, fitting its slot, with its main, its lines and sockets, each line priced within its spread.
  - 20,000 rolls land on their odds: each rarity, the ring's double share, and 60% of the weapons for the lead's class.
  - 1,000 opened in twenty steps: every chest removed once and every item granted once.
  - A repeated op id answers its first answer. Six bad requests and `BagFull` change nothing.
  - A server stopped mid-open applies nothing, and the request sent again opens once.
  - The salvage: everything under a strong worn set, its Credits matching the same rolls replayed; at Common, the Commons only; nothing worn, everything kept but another class's weapon; with a Healer owned who wears nothing, every shared piece and Healer weapon kept, the Warrior's salvaged.
  - The drops: none over the chance, one under it, one sure on the third kill, an elite's always, a keeper's best first.
  - A full bag of the richest chest's items saves whole.
- Boot errors 0.
- **The Act path in a playtest, on the live Test save** (exported first, imported back after: 0 items, Credits 52,471, as it was):
  - 120 Lantern Row chests given; 50 opened (one is a Common ring, Insight 7 and Critical 28); the same op id again gave the same 50 ids.
  - 51 at once: `Unknown`. An Elite Chest not held: `NotEnough`. A salvage of "Shiny": `Unknown`.
  - At Uncommon with nothing worn, all 50 kept. With fourteen strong Legendaries worn, 17 of 20 salvaged for 594 Credits, paid. The 3 kept were Healer and Mage weapons, for the Voidkin of those classes, who wear nothing.
  - **A full bag:** 300 Keeper's Chest of Mirror Pavilion items save at 70 KB (62 KB of items, about 208 bytes each; the ledger 6.5 KB). The 301st: `BagFull`, the chest kept.
- Nothing players see changed, so there's no capture to take.

**Research's fit (Quaestor, 2026-11-16, 19:13).** The model: `py tools/balance/chests.py`, reading `Config.Chests`; `--fit` solves the ladder on research's shape. A player on budget, Lantern Row's laps taken as alike on every ground, a keeper's first win a quarter of the way into its ground.
- **Today's seeds come early:** the first Rare at a median 1.1 h, Epic 5.6, Legendary 23.8. Salvaging everything would pay 20% to 66% of a kill's Credits.
- **The ladder, for `Config.Chests.Ladder`** (Common, Uncommon, Rare, Epic, Legendary):
  1. 94, 6, 0, 0, 0
  2. 91.4, 8.6, 0, 0, 0
  3. 88, 10.9, 1.1, 0, 0
  4. 83.2, 14.6, 2.2, 0, 0
  5. 76.4, 19.2, 2.9, 1.5, 0
  6. 67, 24.2, 5.6, 3.2, 0
  7. 53.8, 28.7, 10.5, 6.2, 0.8
  8. 35.4, 29.6, 19.6, 13.5, 1.9
- **Its shape:** each rarity starts where its grounds read it (Rare at row 3, Epic at 5, Legendary at 7) and roughly doubles a row; Uncommon starts at row 1. So a ground's packs never give its next rarity before its elites do, and Legendaries come from elites and keepers only.
- **Met, a player alone** (median; 10% to 90%): Uncommon 0.3 h; Rare 3.5 h (1.5 to 6.2); Epic 12.5 h (10.3 to 16.4); Legendary 39.8 h (35.7 to 47.4). With eight players: 4.0, 13.0 and 41.1 h.
- **`Salvage`: 8, 14, 24, 40, 64** a G, Common to Legendary. Salvaging everything would then pay 10% of a kill's Credits on Lantern Row and 16% on Mirror Pavilion, an upper bound, so fighting stays the income.
- **These stand as built:**
  - the drops (5%, an elite's always, the keeper's tiers 3 then 2, the third kill) and the class lean of 0.6;
  - the worth (`PowerPerG`, the rarity shares from `gearRarity`, `MainShare`, `Spread`);
  - lines and sockets by rarity, the main stat by slot, the pool and `MainLean`;
  - `Bag`, `Step` and `Reach`.
- **The count:** about 43 chests an hour, 18 of them from elites, and about 2,450 over the climb. Part 11's "about 20 an hour" counted Shades alone.
- **Keep:** each class's best Voidkin, as `docs/design.md`, "Chests" has it (built in 2a95179).
- **At launch,** with Lantern Row alone, its rows give Common and Uncommon, and a Rare only at the keeper's first win. Rare and better then come from the Tower, so its table is fitted with its build (part 12, item 7), to the same windows.

**In Config (Faber, 19:28).** The eight rows in `Config.Chests.Ladder` and Salvage 8, 14, 24, 40, 64. `chests.py`'s C1 meets every window for a player alone (Rare 3.5 h, Epic 12.5, Legendary 39.8). The Bag case's chest edge now reads the ladder rather than a fixed rarity. Logic 23,090/0, type check 0 new.

## TR28. The inventory: the bag, in C (Faber)

Part 12's order, item 4.5 (`docs/research/rework-2026-11-16.md`, parts 5 and 12; `docs/ui.md`, the bag), on the director's yes of 2026-11-16, 16:50. The direction is AR18's C, "the case", in BONE, with research's fixes 1 to 3 and its pick on fix 4 (AR18).

**Scope, set at the start (19:08).**
- **The block:** `Rules.Bag` (the kinds, the belt's groups, a kind's cells with their arrows, the sorts, an item's card against what it replaces, a chest's card); its cases; the Voidkin screen's Items page in C's composition: the belt (a narrow room shows the chosen item's group, the other two a chip each), the six kinds on a scrolling strip, a sort and "n / 300", the grid five across with the rarity's band, the up arrow, the worn tick and another class's dim, the Voidkin's half with its totals, the card sliding over it with Equip or Take off, another class's reason with Equip off; chests in the grid with their counts, their card with the odds, Open and Open all (`Act("OpenChests")` in steps of 50) and the outcome's line; the salvage's control in the Chests kind (`Act("SetSalvage")`); shards in Materials; the empty lines.
- **What waits:** AR6's icons (a cell shows its kind's word in the inlay until then); the rail and the band on bone; the preset's dropdown; the lock; the "new" pip; a slot's better-item dot; a gamepad's focus; Regular and Wide (4.8, the responsive pass); the chest's summary and reveal (their own feel lines); the Dawn series.

**The build (19:08 to 19:26 by the clock, on the rules written before it).**
- **The rules, pure:** `src/shared/Rules/Bag.luau`.
  - `List(data, owned, kind, sort)` gives a kind's cells: items by rarity, Combat Power or newest; then chests, the best tier first; then shards.
  - Each cell says its rarity, its count, whether it fits the shown Voidkin's class, where it's worn, and its Combat Power gain, which is what the up arrow shows.
  - `Card` sets an item against what it would replace, through `Stats.Compare`, which now takes a list's `before` so 300 cells resolve the Voidkin once (13 ms for 300). A worn item compares taking it off; another class's lists its own lines and compares nothing.
  - `Chest` gives the held count, the step (Config.Chests.Step), the room left in the bag, and the odds.
  - Two helpers in `Rules.Sheet`, `Amount` and `Change`, write a total and its signed change.
- **The page:** `src/client/UI/VoidkinScreen/Bag.luau`, numbers in `Config.Hud.Bag` (BONE's palette among them). The screen's `build` hands it the room right of the rail, with the figure's stage, the name line and Combat Power.
  - **The belt:** fourteen slots at a touch (44 rendered) where they fit. Otherwise, the chosen item's group shows, the hands' with nothing chosen, and the other two groups are a chip each. The slot an item would fill is ringed in ink.
  - **The strip and the grid:** the six kinds scroll, the chosen one kept in view, with the sort (or, in Chests, the salvage) at the strip's end. The grid is five across or more at 60, with "n / 300 in the bag" at its foot.
  - **The card:** a tap changes the card, the rings and the belt in place, never the grid. The card slides over the Voidkin's half in 0.16 s, Quart Out, and back. Equip and Take off go through `Act("Equip")`, and the card closes so Combat Power's count-up shows. A chest's card opens 1 or the step through `Act("OpenChests")`, and its toast says what was kept and salvaged.
- **Faber's calls (tier 1, for research's pass):**
  - **Neither Lead and Work nor the Voidkin strip on Items:** C has neither. The Voidkin dressed is the screen's chosen one, picked on Overview. The dock opens on Items (research's call of 2026-11-15), and "Send another" now opens on Overview, where Lead is (`On.Page`).
  - **The half's width:** the layout gives the Voidkin's half 282 authored on the smallest phone, against research's "about 260". The grid keeps its five at 60.
  - **The count's place:** at the grid's foot, scrolling with it.
  - **Open N's word:** the button says the step ("Open 50").
- **For tests:** Studio's `ItemTake` takes a case's own items back out of the save and every preset.

**The checks (19:26).**
- **Type check:** 0 new, 11 known.
- **Logic, offline and in Studio:** 23,133 passed, 0 failed (Bag 194).
- **Boot:** 19 server and 12 client modules, 0 errors.
- **Self-test, the Items page's case** (`BagCases.luau`):
  - **Passed, 84 checks:** the grid matches `Rules.Bag`'s list in its order for All, Weapons, Jewellery and Chests and for each sort. The up arrow, the tick and another class's dim show on the right cells. Equip and Take off reach the save, and the card closes. Another class's card says "<Class> only" with Equip off for that reason. A chest opens with its line. The salvage goes round its five steps and back. The case's own things are taken back.
  - **NOT VERIFIED, 11 checks:** sizes and positions in this window and on the smallest phone, the card's slide, and the screen lint. The PC is locked: the client's viewport is 1×1 and RenderStepped runs at 0 fps, so the rail's long-standing buttons read 41 px too.
  - The TR17 case now checks Overview after showing it, the takes show Overview where they film it, and "Send another"'s case checks that it opens on Overview.
- **When the screen unlocks:** the case again, then captures: a full bag, long names, a comparison, another class's weapon, an empty bag, the smallest phone, and at night beside the HUD (fix 1's phone check).
- **The four facts:**
  - **Implemented:** yes.
  - **Tested:** logic and flow, yes. Layout, NOT VERIFIED.
  - **Visually reviewed:** no.
  - **Director-accepted:** no.

**Research's answers on Faber's calls** (Quaestor, by message, received by 19:35), and the fixes:
- **(1) No Lead, Work or strip on Items:** kept. The name line on the Voidkin's half says who's being dressed.
- **(2) The half at 282:** kept, to be judged on the smallest phone's still.
- **(3) The count:** changed. The count matters most when the bag is nearly full, which is exactly when a scrolling foot is furthest off screen. **Fixed:** "n / 300 in the bag" is pinned under the grid, outside its scroll, and its digits turn red when the bag is full. The case checks it's out of the scroll and says what `Rules.Bag.Held` says.
- **(4) Open N:** kept, if the number is what the tap opens. **Fixed:** `Rules.Bag.Chest`'s `Step` is now as many as are held, as one request takes, and as the bag has room for, so with 12 held it says "Open 12", and with room for 20, "Open 20". With the bag full, both buttons are off. Two new logic checks cover room for 20 and a full bag.
- **Checks:** type check 0 new; logic 23,092/0 offline.
