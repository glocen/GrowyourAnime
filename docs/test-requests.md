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

**Status:** in build, 2026-11-14 (Faber). In code, with the offline checks passing (type check 0 new, logic 4806):
- **The kit:** its two files taken as they are (`tools/world/kit_take.py`, into `Config.Kits.LanternRow`), the placement in `Shared.World.Kit`, and the street dressed by `WorldService` once the template exists. Each piece stands at the plan's place, with the plan's nine static lights. The grey walls, square and gates stay as unseen colliders, and the street's own floor carries the walking in the kit's paving tile. `DressReport` checks it against the plan.
- **The night:** `Rules.Night` on the server's clock, `Config.Lighting` from the kit's frames, and `LightingController`. The ground's look holds from 24 studs short of the gate, so a door's landing opens in it, and the place keeps its own elsewhere. A sky is swapped under the haze's peak; the sun is solved to the frames'; the glows and lights come from Config; the lead carries the plan's tenth light. `Night <phase>` jumps the turn, and every number is live through Tune.
- **Studio's half:** `tools/studio/KitAssembly.luau`, its install `tools/studio/Kits/LanternRow.json`, and `tools/upload/stage_kit.py`.
- **Uploaded** under the group, Approved: the 8 maps and the 12 sky faces (`docs/asset-log.md`).
- **Waiting on the Studio MCP:** the 16 meshes published, the template built and serialized, three self-test cases, the three notes tuned live, the device take, the verdicts.
- **Out of the block:** the paper's drift, which has no emitter numbers in the handoff.

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

**Status:** the grey layouts and infusion built offline, 2026-11-14 (Faber); research's verdict waits on the Studio MCP. Time: about 2.5 active hours, my estimate, not measured.
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
- **Visually reviewed:** no. The three layouts wait for a take at home at phone size, with shards breaking, and research's verdict.
- **Director-accepted:** no.
- **Out of the block:** AR3's kit in the Dynamo palette, after the verdict; the bays' screen; any Robux price.

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
- **Visually reviewed:** not yet. Research's verdict in motion at phone size (a circuit with a fall, the next lead out, the trip home) goes here once Studio is back.
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

**Status:** the rule, the save and the board in grey built offline, 2026-11-14 (Faber), and reworked the same night on research's call (c), the board on top. Research's verdict on the layouts waits on the Studio MCP. Time: about 3 active hours, then about 1.5 for the rework, my estimates, not measured.
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
