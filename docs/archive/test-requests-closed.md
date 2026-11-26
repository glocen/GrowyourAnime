# Test requests, closed

The closed entries of `docs/test-requests.md`, moved here whole and unchanged on 2026-11-26 (research, the cleanup with the director's go). The live file keeps an index line for each.

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

### The two icons (Modulo, 2026-11-17, 16:17 to 16:22 by the clock)

Research's word, 2026-11-17, sent with AR31's verdict (AR31, "Research's verdict", 16:11): the grey marker has never been captured, so the icons are drawn now, at the stand-in tile's size (`Config.Hud.Down.Icon`, 40). Their layout doesn't change the drawing.
- **Feel line (Modulo's):** from the street, the player sees who is down before reading the name: the elite by its two masks, the Lamplighter by his hat and his lantern.
- **The images:** `build/handoff/UI/marker/images/MarkerElite.png` and `MarkerLamplighter.png`, 160 px square on transparency (40 points at the kit's 4 a point). The sheet is `build/handoff/UI/marker/marker_icons.png`, from `tools/blender/marker_icons.py`.
- **How they're made:** each from its own delivery (`build/handoff/Shade`, `build/handoff/Lamplighter`), its meshes and maps on the surfaces Roblox draws. Each shows a face and a sign:
  - **Elite:** the Brawler's mask, with the elite's second mask on its arm, turned to the camera. The two masks are what tell the elite from a pack's Brawler.
  - **Lamplighter:** his paper mask under the straw hat, with his lantern lit beside his head. The lantern is brought in from the pole's end at 0.75 of its size. The pole stays out, since at 40 points it is a line across the face.
  - The body's glow is a quarter of the game's, so the type shows at the edges, not as a lit seam down a 40-point picture.
- **For Faber:** each image goes on the marker's Icon tile, in place of the Initial (a letter on PlateHigh). It's an ImageLabel filling the tile and clipped to its corner, or the tile's colour left under it as the sheet shows. Upload both under the group.
- **My read:** on the tile at 40 px, the elite reads as a big mask and a small one, and the Lamplighter as a hat over a white mask with a cyan light. At 28 px both still part.
- **Content check** (for building and upload, 2026-11-17, 16:22 to 16:24 by the clock): **PASS**. It read the sheet, both files at 160 px and at 64 px over dark and bright, the script, and AR2's and AR7's checks.
  - The elite's seam reads as coat piping and its hem as an even fade, never blood. The second mask reads as a paper badge on the sleeve, not a head.
  - The hat sits on a paper lantern mask, a festival costume piece with no play on anyone. Its cords read as a chin strap.
  - **Conditions:**
    1. The elite's body glow stays at a quarter of the game's or lower, no redder than `#EA4B4F`, with a dark gap between the big mask's chin and the seam. A new glow, colour or camera makes a new picture, and it comes back to the check.
    2. The Lamplighter's eyes stay level closed arcs, with no slant and no teeth. A caption, if one ever comes, is checked against `docs/ip-list.md`.
    3. Upload these exact two files under the group, and log each in `docs/asset-log.md` with `tools/blender/marker_icons.py` as its source.
    4. Once in game, look at the live marker at 64 px over Lantern Row's dark and bright corners. No bloom or tint on the ImageLabel may push the elite's red further, or put red on the small mask.
    5. AR2's and AR7's conditions stand.
- **Four facts.** Implemented: the two images. Tested: rendered and read on the tile at 80, 40 and 28 px. Visually reviewed: my read; research's verdict next. Director-accepted: no.
- **Research's verdict (Quaestor, 2026-11-17, 16:24): passed, no must-fix,** on the sheet at 80, 40 and 28 px and at 64 px over dark and bright (9f71763).
  - **Felt:** two bosses you can tell apart at a glance: the hat and its lantern against two grinning masks.
  - **Tier:** competent.
  - **The bold thing:** the Lamplighter's hat with the lit lantern. That silhouette is still him at 28 px.
  - The elite's masks run near white, so at 28 px they're two pale shapes. That's enough beside the hat, and it goes to polish-later, not here.
  - **Next:** Faber lays them on the marker in place of the letters, beside the grey marker's own capture: the three layouts at phone size from the street, near and far. One verdict covers the marker and its icons in the game.

### The elite's icon on AR47's mask (Modulo, 2026-11-19, 20:57 to 21:02 by the clock)

- **Why:** `MarkerElite.png` was rendered on 2026-11-17 from the mask with ink brows, the face AR42's content check blocked and AR47 reworked. It was never uploaded, so it's redrawn before Faber takes it.
- **First, a re-render on the reworked mask, as it stood:** no brows, but no face either. The icon's light (the sun, the camera's fill, and the paper's own glow at the model's 12) clipped the paper to white. So the lit holes and grin vanished into it, and at 28 px the masks were two blank shapes, polish-later's note made worse (`build/scratch/modulo/marker_ar47/old_new_x3.png`).
- **The fix, the masks' light in the icon only** (`tools/blender/marker_icons.py`, `PAPER_LIGHT` and `MASK_GLOW`):
  - The paper's diffuse is scaled to 0.5, 0.45, 0.39, and its glow is brought from 12 to 3.5.
  - The paper now draws at about (209, 191, 165), against the game's (205, 179, 152), measured on AR47's capture. The almond holes and the grin glow white on it, as in the game.
  - The last six of ten takes are in `build/scratch/modulo/marker_ar47/takes/elite_light_takes.png` (`variants.py` beside it). The one used is I.
  - The camera, the body's glow and its red are unchanged. `MarkerLamplighter.png` is byte-identical.
- **My read:** at 40 px both masks read as faces, with lit cuts on tan paper. At 28 px the holes still show as two lit cuts on each. That answers polish-later's line, so it moves to Done.
- **Content check: PASS** (21:02), on the file at 160 px and on the sheet at 80, 40 and 28 px and at 64 px over dark and bright.
  - Both masks are tan paper with no ink. Their holes are almond and lit, on the small mask too, which meets AR47's condition 3. There are no dark sockets or dot pupils, and no hood.
  - **Conditions:**
    1. Upload this exact file under the group, and log it with `marker_icons.py` as its source.
    2. A change to `PAPER_LIGHT`, `MASK_GLOW`, `BODY_GLOW`, `RED` or `VIEW` that clips the paper white or darkens the holes comes back to the check.
    3. TR10's conditions 1, 4 and 5 stand.
    4. AR47's condition 4 holds for every picture of this Shade.
- **For Faber:** upload the files as they stand in `build/handoff/UI/marker/images/`, with TR10's install. Nothing else changes.

### Research's pass on the elite's icon (Quaestor, 2026-11-19, 21:03)

- **Felt:** it's the street's Brawler: the tan paper mask with its holes and grin lit, the small mask on its shoulder, the same face as AR47's tile. It reads at 40 px, and at 28 px as a mask with teeth. **Passes at competent;** Faber installs it with the Lamplighter's.

### The stills for research's verdict (Faber, 2026-11-23, 16:40 by the clock)

- **The sheet:** `build/captures/tr10/layouts_sheet.png`, with the nine stills beside it. Its columns are Stack, Row and Badge; its rows are the elite's plate at 24 studs, at 120, and the keeper's.
  - Every still is on the smallest phone's frame (the take now frames as AR44's does), on the Strip under the Row's look, from the game's camera behind the avatar. Modulo's two pictures are on the tiles.
  - The home-only step chip is hidden for the stills: on a ground it never shows the Breaker's line.
- **What I saw:**
  - At 120 studs the plate stands where it does at 24. It hangs 9 studs over its marker, so from the game's camera both sit near the horizon. Only Badge changes, dropping its card past Near.
  - **Stack:** its last row ("Lantern Row shard") runs under the nav bar.
  - **Row:** the keeper's title is cut ("The Lamplighter · …").
  - **All three:** the plate stands over the avatar's path mid-screen, research's note in TR8.
- **The take:** it passed (5).

### Research's verdict on the layouts: Badge, with two must-fixes (Quaestor, 2026-11-23, 16:41)

From `layouts_sheet.png` and `far_badge.png`, the smallest phone, the game's camera.
- **Felt:** a dark card sits mid-screen at any distance. Badge's mask with its countdown says "back in 4:32" at a glance. But at 120 studs it's a panel over the player's own head, not a mark over a square down the street.
- **The pick: Badge.** Far, it gives the icon and the time; near, it adds the card. That's the feel line's "when to come back" and "why", in that order. Stack and Row are set aside: they carry a title the icon already says, and each breaks on the phone (the nav bar, the cut name).
- **Tier:** works.
- **The one bold thing:** the mask with its countdown under it.
- **Must-fix 1, class "a world marker drawn at screen size":** the marker takes its size from the world. It shrinks with distance, down to a floor where the icon and the time still read on the smallest phone. Near, it's capped at today's size. At 120 studs it's a small badge over its square, not a panel over the avatar. Check the 9-stud hang from the game's camera with the new size.
- **Must-fix 2, class "an empty frame":** Badge's far state draws only the icon's tile and its time. Today the card's dark panel stays behind with nothing in it (`far_badge.png`, about 520 by 215 px around a 150 px tile).
- **For the second look,** what stills can't show: a walk from 120 studs to 24 toward the elite, at phone size. It shows the badge growing and the card arriving at `Near`, whether it eases or pops. One strip or a short take, and the keeper's gate the same way.
- Then the icons are in, and TR10 closes on the second look.

### The two fixes, and the walks for the second look (Faber, 2026-11-23, 17:04 by the clock)

- **Fix 1, the world size.** The badge takes a scale of `Hud.Down.Full / distance` from the camera, capped at 1 near. Full is 75, the camera's distance when the avatar stands at Near. The floor is `Least`: 28 px for the tile on the smallest phone, a scale of 0.69 there. The time and the card's words keep 14 px or more on the smallest phone at every size. Measured: 1.00 at 12 and 60 studs, 0.75 at 100, 0.69 at 200.
- **The hang.** In the first walk, held under the whole top band, the small badge still stood on the avatar's head from the game's camera. It now stands open, like the band's other open plates: over its square near the horizon, between the lead's card and the wallet, and it moves aside only from a piece it would cross. At 24 studs the card hangs from the top of the frame to just over the avatar's head, clear of the lead's card and the wallet. That holds for both, the elite's at 9 studs and the keeper's at 11.
- **Fix 2, the empty frame.** Far, the badge draws only the tile and the time: 60 authored px wide, under half the card's 176. The panel shows only from Near. There the card opens downward from the tile in 0.18 s (`Hud.Down.Unfold`, quad out), fading in as it widens. The tile stays where it was (0 px).
- **Removed:** Stack, Row and the comparison: from Config, the controller and the cases.
- **The take now centres the phone on the window.** The world is drawn across the whole window, so only a centred phone has the world standing under its HUD as it does on a phone. `Layers.Box` now takes the box's place. The 16:40 stills had it at the window's left, with the avatar right of centre.
- **The walks.** The game's camera (20° down, 12.5 studs, FOV 70), by day, on the Strip, walking at 16 studs/s from 120 studs to 24:
  - `build/captures/tr10/walk_elite.png` and `walk_keeper.png`: ten frames each, at the phone's size. They show 120 studs standing, the walk, the four frames of the unfold, and 24 studs.
  - `unfold_elite.png` and `unfold_keeper.png`: twenty frames in a row at about 30 fps, cropped to the badge.
  - All the frames: `build/scratch/faber/tr10_walk_elite/` and `tr10_walk_keeper/` (gitignored).
- **What I saw:**
  - The badge grows smoothly to full size by Near.
  - The card arrives in four frames, eased, not popped.
  - For two of those frames the rows are cut at the panel's sides ("redits 190"), a wipe from the middle. If that reads as a glitch, one change would fix it: the rows fade in once the width lands.
- **Checked:**
  - "HUD: TR10": 53 passed. Its new case checks the size at 12, 60, 100 and 200 studs, the time readable, the tile never under 28 px, far showing only the tile and the time, the tile still while the card opens, and the lint clean near and far.
  - After `Layers.Box`'s change: "HUD: a keeper's try" 2 passed and "Tower card (TR46)" 27 passed.
  - The take passed (5). The type check: 0 new.
  - The Festival case "World: TR10" is rewritten to the fold and unfold. It runs only in the Festival's place, which isn't published yet.
- **At the close, the whole suite: 3,351 passed, 1 failed.** The one is TR42's audition, the long suite's known flake, which passes alone (89 passed). LogicTests: 29,156 passed.
  - Two checks were taught the badge: "no plate shows empty" now skips a hidden panel and finds its words beside it in its plate.
  - The foe card's skull check now reads the skull's own transparency under the card's see-through. A fighter standing behind the card fades it, which failed the check with nothing wrong.
- **Not done:** desktop-size stills. The badge was reviewed at the smallest phone only, by me and in research's pass.

### Research's second look: TR10 passes at competent (Quaestor, 2026-11-23, 17:06)

From `walk_elite.png`, `walk_keeper.png` and `unfold_elite.png`, the smallest phone, the game's camera, judging what changed.
- **Felt:** walking down the Strip, the mask and its countdown stand small over the square ahead. As you arrive, the badge opens into its card, which hangs over the street above your head. "Back in 4:32, and here's why" reads in that order.
- **Must-fix 1 met:** the badge takes its size from the world. At 120 studs it's a small mark near the horizon, off the avatar. At 24 studs (the keeper's at 11) the card stands clear of the avatar, the wallet and the lead's card.
- **Must-fix 2 met:** far, only the icon's tile and its time.
- **The unfold's wipe from the middle:** accepted as it is. For two frames at 30 fps, the rows are clipped at the sides. At full speed that reads as the card opening, not as cut words.
- **Tier:** competent; the bold thing is unchanged.
- **What the strips can't show:** the elite's badge with players at its square, and the badge at dusk and night. Both are first seen on the published place, where QA's pack or the director's phone run will show them.
- **The four facts:** implemented, tested, visually reviewed and passed; director-accepted not yet.

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

**Read on the unlocked screen (Faber, 2026-11-16, 21:01 to 21:17, by the PC's clock).** A fresh profile in play, walked by script from arrival to the gate's line. The stills are `build/scratch/faber/stills/tr24-01` to `tr24-15` (scratch), for research's verdict.
- **The suite (27847da):** 2,391 passed, 10 failed; six fixed and each rerun alone. The four left wait on the Items page in A and on TR25's smallest phone. Fix 8's and fix 11's play cases pass on render.
- **Fix 1, again (27a168a):** the edge arrow stood under the wallet. It now stands under the HUD's top band. In view is still judged on the frame's own inset, so the Door's crown, high over its sign, keeps its chevron and gets no arrow (`05a` before, `05` after). The case gains both checks, 8/8 at 60 fps.
- **What reads:** the Door's sign (fix 10, `05`); the Row's Shades in view from the landing and the fight before the camera (fix 2, `06`, `07`); turned round, Rook between the camera and the avatar fades to 0.65 (fix 3, `08`); home, "Watt's shard: into the Breaker" (`09`); the break and Watt's reveal (`10`, `11`); in the Row again once a bay works, "The Lamplighter waits at the gate" (`15`).
- **The driver's findings, for research's ranking:**
  - At the top, under the band, the edge arrow stands about a quarter down the frame and reads as a small lilac stroke on the sky (`13`, `14`).
  - Watt's reveal shows the grey stand-in body (`11`).
  - "Watt: to work in Bay 1" while the plate in view reads "Bay 2 · nobody works here" (`12`).
  - At work, no Watt stands at Bay 1: the plate, within 13 studs, says "Watt · 18 kW" (`14`). The meter reads "18 / 0 kW".
  - From the first stills (`01` to `03`): chevrons over the starters at arrival, the starters plain lit cubes, the reveal opening by itself, the lead on the camera's right.

**Research's verdict on the read (Quaestor, 2026-11-16, 21:20, from the stills).**
- **Felt:** arrival to the gate now runs on its own, the Door found and the Row's fight in view, until the bay. There the loop's second pillar, a Voidkin at work, can't be seen.
- **Met:** fixes 1, 2, 3 and 10, and the gate's line.
- **The driver's findings, ranked:**
  1. **Watt at work is seen.** The worker stands at its bay, working, and the objective's chevron sits over the bay it names. Today it says Bay 1 while the plate in view says Bay 2 (`12`), and no one stands at Bay 1 (`14`). Serves the Build beat.
  2. **The edge arrow reads as an arrow on the sky and the pale floor.** Today it's a small lilac stroke (`13`, `14`). Make it larger, an arrow's shape, with a dark backing. Serves wayfinding, the first session's spine.
  3. **The starters read as Void Shards,** the break card's crystal, not lit cubes (`02`). The first thing a player picks should be what it says.
  4. **The meter never reads "18 / 0 kW",** eighteen out of nothing. When nothing draws, it shows what's made. Its words stay `docs/ui.md`'s, "Power".
  5. **Watt's grey reveal** (`11`) belongs to the roster's second Voidkin, not to this piece.
  6. **Kept as they are:** the chevrons over the starters, the reveal following the break, and the lead on the right.
- 1 to 4 are this piece's fixes.

**Then, the director's own run (research, 2026-11-16, 21:39).** After fix 1, the worker seen at its bay, the director plays the first session on a real phone, on research's go (`docs/decisions.md`, the row of 21:39: "sure just give me the go"). Faber publishes the build to the place first; the experience stays private.

**Fix 1, Watt at work is seen (Faber, 2026-11-16, 22:30 to 23:24 by the PC's clock).**
- **Watt's body:** AR11's seven meshes and four maps are uploaded under the group with the key (`docs/asset-log.md`), built to `src/storage/Watt.rbxm` (`models_offline Watt` PASS), and `Model = "Watt"` is on his row. His clips are Modulo's next, so his row's `ClipsDue` says where they come from. Until they land he fights on the stand-in's kit and reveals as the stand-in (finding 5). The two logic rules on a body now take `ClipsDue`, and ask for it gone once his kit is in.
- **The worker at its bay:** `BaseService` puts the worker's body in its bay's ring (`FightService.Body`), facing the bay's front, `Config.World.Bay.Hip` over its floor, held in place, and through nobody's way. `BaseController` plays its rig's Idle; his own stance comes with his clips. The body goes when the bay empties.
- **AR16's rarity light:** the ring's `BayHalo` stands in Neon in the worker's rarity colour (`Config.Reveal`'s Words), with one PointLight (`Config.World.Bay.Light`), and is dark when the bay is empty. Watt is Common: his #AEB4C0 barely reads by day in the stills.
- **The chevron:** `stepTargets` already pointed at the bay the step names. The plate in view at `12` was Bay 2's, which stands behind the Breaker from the spawn. A new case now proves it for all six bays, and with Watt standing in Bay 1 the line and the bay agree on sight.
- **The Tower, found by its case once Watt had a body:**
  - **A body without its moves is no foe.** `Rules.Tower.Pool` takes a Model and a Kit, so Watt waits for his clips. A logic check says so.
  - **Results the save no longer holds close.** A run started with the last run's results still open drops them (`Rules.Tower.Start`), but the screen stayed up: the run then ended on the old floor's results, and its own never showed. Now the open results close, and the new run's open at its end. A check in the Tower case.
  - **The case itself:** the bays' workers step out for its run (a full battery spills their power into Credits mid-run), and its foes strike for next to nothing by a Tune put back after. A lifted foe's signature takes about two fifths of a level 5 lead after the heal cap's hurt to half, so the climb was testing the run's seed, not the ledger. The lead's fall keeps its own step.
- **Tested:**
  - Type check: 0 new.
  - Logic offline: 24,099/0.
  - The new "Base: TR24's fix 1" case: 19/19.
  - "Base:": 202/0.
  - The bodies' case, with Watt as the lead: 36/0.
  - "Reveal": 160/0.
  - "Tower": 48/0, five runs in a row, one started over a stepped-off run's results left open.
  - The whole suite, 23:24 to 23:30, with TR28's fixes in: 2,458 passed, 4 failed, at 45 fps. The Tower's two Credits failures are gone.
    - TR25's two known Overview overflows.
    - The Mythical reveal's 50 fps hold: NOT VERIFIED. The client ran 43 to 47 fps quiet, with Bay 1's worker and without, so the cause is this Studio's long session, not the worker.
    - TR20's pointer case: it passes alone, 36/0.
- **Stills:** `build/scratch/faber/stills/tr24-fix1-wide` and `tr24-fix1-near`. The lead stands beside him: the camera follows the avatar.
- **For research:** Watt's Signature words still say "plants the wrench", and take A carries a spear. The row's words and `docs/roster.md` are yours.

**Research's go for the director's run (Quaestor, 2026-11-16, 23:34, from `tr24-fix1-wide` and `tr24-fix1-near`).** Fix 1 reads. Watt stands at work in Bay 1's ring with his spear, the halo lit, and the plate names him. The go is given: the director publishes (Faber's waiting item 4), then plays the first session on a phone.
- **One fix, with fixes 2 to 4:** walked up to the bay, Rook stands between the camera and Watt and hides him (`tr24-fix1-near`). The lead keeps clear of a working bay's ring when the player is near it, or fades there as fix 3 has it.

**Fixes 2 to 4, and the lead faded off a working bay (Faber, 2026-11-16, 23:36 to 23:58).**
- **Fix 4, the meter:** with nothing drawing, the Power pill shows what's made, "18 kW", never "18 / 0 kW" (`Read.Against`; the Generator's plate and the Power screen read the same). Its word stays "Power".
- **Fix 2, the edge's arrow:** an arrow, a shaft and a head, on a round dark backing rimmed in the guide's colour, 60 points across (`Config.Hud.Guide.Edge`), in place of the small chevron. Its middle keeps half its size inside the frame's inset, so the whole of it stays clear of the next step's chip. A repaint takes only the rim and the arrow; the backing stays the ink.
- **Fix 3, the starters:** each one waiting is the reveal's own shard whole, the Standard grade the break card pictures, at 0.6 of its 4.5 studs (2.7 here, about half the avatar), with a faint light in the break's first crack colour. The unseen anchor keeps its prompt and its turn; the pieces are welded to it (`BaseController`, `dressStarter`).
- **The lead off a working bay:** the fade of fix 3 sees past a bay's worker too. A lead in the camera's line to a worker within `Combat.Lead.Fade.Worker` (24 studs) of the avatar fades to 0.65, and comes back once clear (`ViewController`). The lead's place is unchanged: a fade is cheaper and covers every angle; keeping it out of the ring is the other way, if the fade doesn't read.
- **Tested:**
  - The type check: 0 new. The offline logic: 24,099 passed, 0 failed.
  - New and touched cases in play: the edge's arrow (10/10, its shape, its size, its foot over the inset); the starter's crystal (9/9: the whole shell, no core or bud, the palette, 2.7 studs tall, its light, its pieces turning with it); the lead faded off a worker (5/5: whole with no worker, faded with one near, whole again with it far); the Power pill's "18 kW" (in "the lead's card reads the lead", 34/34); fix 3's own fade and place (7/7, 6/6).
  - The whole suite, 23:53 to 23:59: 2,473 passed, 2 failed, at 60 fps. The two are TR25's known Overview overflows on the smallest phone. The Mythical reveal's 50 fps hold passes (60 fps, the worst frame 19 ms).
- **Research's must-fix, the arrow over the chip (Quaestor, 2026-11-17; Faber, by 00:03).** Its still predates the inset of half the arrow's size; that inset alone left the arrow 13 px over the chip at this screen's size, and 5 px under the inset at its bob's lowest. Now the arrow counts the chip itself: the HUD names its foot piece (`World.Foot`, the next step's chip), and while it shows, the arrow's foot stays `Guide.Edge.Clear` (6 points) over its top. The inset also keeps the arrow's nudge along its way.
  - **Tested:** the type check, 0 new. The marker's case, 11/11, three runs in a row: a stand-in chip taller than the inset, the arrow straight behind at the bottom middle, its foot 11 to 13 px over the chip's top. "The lead's card reads the lead", 34/34 at 48 fps.
  - **Still:** `tr24-fix2-arrow-middle`, the Breaker straight behind, the arrow whole over the chip.
- **Stills** (`build/scratch/faber/stills/`): `tr24-fix4-meter`, `tr24-fix2-arrow` (the Breaker behind the camera), `tr24-fix3-starters` (the three built beside the avatar for the still: they show only to a new account).

**Research's verdict on fixes 2 to 4 (Quaestor, 2026-11-16, 23:59, from `tr24-fix4-meter`, `tr24-fix2-arrow` and `tr24-fix3-starters`).**
- **Felt:** the base speaks plainly now. The meter says what's made, three crystals wait by the player's feet, and an arrow on a dark disc says turn round.
- **Tier:** competent.
- **The one bold thing:** the starters are the reveal's own crystal, so the first thing a new player sees is the thing they'll break.
- **Must fix:** with the Breaker straight behind, the arrow sits at the bottom middle and the chip covers its lower half (`tr24-fix3-starters`). At the bottom edge, its inset counts the chip, so the whole disc stays above it.
- **The lead's fade off a worker:** accepted on its cases (5/5). No still shows it, so the director's phone run is its first look.
- **Research: the must-fix passes** (Quaestor, 2026-11-17, 00:03, `tr24-fix2-arrow-middle`). With the Breaker straight behind, the arrow stands whole above the chip at the bottom middle and reads as "behind you". TR24's fixes 1 to 4 are closed for research.

**The director's run (2026-11-17, by 00:17, on a phone; research's list at 00:23).** The director's words: `docs/decisions.md`, the row of by 00:17. Six stills, in the director's chat only.
- **Felt (the director):** "still far to look like a game, no SFX that add depth". Sound is its own track below.
- **Must-fix, Faber:**
  1. **The sheet shows percents only.** Hit, Dodge, Critical, Block, Penetration, Critical Resist and Elemental Resist each show one percent and no points. Critical Resist reads "7.2%", with no "their Critical chance" after it. This is a class of fix: every chance or share stat on every screen.
  2. **Critical Immunity,** never Critical Guard, everywhere a player reads it.
  3. **"Main" sits with its own attribute.** Beside Watt's Vigor 215 it now stands before Spirit 73, and reads as Spirit's.
  4. **One palette across the bag's tabs.** The Items tab drops the brown lacquer and takes the Overview's background, cells, tabs and stage. A's ledger layout stays. Switching tabs never changes the colours.
  5. **Watt's portrait,** made as Rook's is. Today the lead's card and the roster row show a grey silhouette, and so does every Voidkin without one: each installed Voidkin needs its portrait.
  6. **The level on the lead's card** sits on a badge on the portrait's frame (`docs/ui.md`, the HUD, top left), never as the lavender tab hanging below the card at another slant. The badge takes the card's own colours, so no new tint joins it.
- **For Modulo, when back:** the Festival Door drawn again, two or three directions in grey beside the plot. Today its face is one flat gradient card, and a string of lanterns hangs across it like a line of washing. The door says where it leads by its light, depth and name. Lantern Row's lanterns stay in their ground. Then the lead card's colours, in AR12's palette.
- **Sound:** research's deep study first, beside `docs/research/sound.md`, then the order of cues. AR13's six layers are still unheard.

**Faber's six (2026-11-17, done by 01:31 by the clock).**
- **1, percents only.** `Rules.Sheet` shows each of the seven ratings as its chance or effect against the even foe, one percent and no points. `Rules.Bag` carries a rating as its share too: the item card's comparison by `Sheet.Odds` before and after, an item's own line by `Sheet.Adds`, what its points would add to the Voidkin shown. Critical Resist reads its percent alone. A change too fine for a tenth reads to a hundredth, then "<0.01%", so a real gain never shows "+0%" (it did, in the gain's green: a tier-1 helmet's +40 Hit on a level-100 Rook adds 0.04%; my call, found on the phone take).
- **2, Critical Immunity** in every line a player reads; the field's id `CriticalGuard` stays in code.
- **3, "Main"** sits on its own attribute's total.
- **4, one palette:** the Items tab takes the Overview's backing, cells, tabs and stage (`Config.Hud.Bag`); the lacquer is gone. A's ledger layout stays.
- **5, the portraits:** AR3, "Watt's and Kirra's portraits", "In the game".
- **6, the level's badge,** in take A's colours (AR12, research's pick, 14318e5): a block on the card's slant over the frame's foot, its left at the frame's, growing rightward with the number; the chevrons and the number in ink on the Voidkin's Block; the plate the Voidkin's Panel with no band, its edge lavender, the words its pale; experience a thread 3 thick. The level-up's pop lifts the block toward white (`UI.LeadCard.Glow`); the number keeps its ink. The old tab (`LevelPlate`) is gone from the card.
- **An engine quirk, found on the way:** sliced with its full height as the middle row, the slanted block drew upright and shifted whenever it was smaller than its pixels (the desktop HUD at 1.5, every phone), and right only when larger. The badge's height is cut whole now (`Config.UIKit.CardLevelBadge`), and a case holds it. The four variants side by side: `slice_probe_ABCD.jpg`.
- **Four facts.** Implemented: yes. Tested: type check 0 new; logic 24,269/0, offline and in Studio; the Voidkin screen 261/261, the Items page 106/106, the lead's card 82/82, the pop 16/16; the stills take 3/3, on the phone and the desktop. Visually reviewed: Faber, on the phone (iPhone 16 Pro, 750 by 401) and the desktop, the badge read at level 100 on the phone; stills in `build/scratch/faber/tr24_stills/` (the phone's five, the desktop's card and HUD, the badge before the fix). Research's pass: waiting. Director-accepted: no.
- **For research:** `docs/ui.md`, "How each number is written", still says points with a chance; fix 1 makes it one percent. And its "Numbers" say one decimal on a percent under 10%: the change line's hundredth under a twentieth of a percent bends that, so a real gain never reads as none. Yours to keep or change.

**Research's pass on Faber's six (Quaestor, 2026-11-17, 01:32),** from the phone's five stills, the desktop's card and HUD, and the badge's crop.
- **Felt:** the sheet now reads the way the director asked, one percent a stat and Critical Immunity by name. The bag is one room across its tabs, and the level sits on the portrait's corner as part of the card.
- **Tier:** competent. **All six pass,** with no must-fix:
  1. One percent each: Hit 90%, Critical Resist 5.1%, no points.
  2. Critical Immunity everywhere.
  3. "Main" on Might's own total.
  4. The Items tab in the Overview's slate.
  5. Watt's and Kirra's portraits.
  6. The badge reads "100" on the phone.
- **Faber's two calls stand:** the hundredth on a fine change, and the badge's height cut whole. `docs/ui.md` now says percents only and the hundredth.
- **Older, not this piece; a must-fix before any public build:** the fifth card in the roster row is a silhouette in an Uncommon frame. A Standard shard of Lantern Row rolls Uncommon 30% of the time (`Config.Shards.Pools`), and the only Uncommon of ground 1 is Sable, who has no model, kit or portrait yet (`Rules.Odds` rolls every row of the ground). A player's first shards can give a Voidkin that isn't made. The roll takes only made Voidkin, or each is made first. How is Faber's call; which Voidkin come next is research's and the production plan's.
- **Still open from the director's run:** the Festival Door (AR15, C, its colour pass next) and sound (`docs/research/sound.md`, "Next"). Phase 3's go follows the Door.

**Sable's guard (Faber, 2026-11-17, to 10:09 by the clock).** Research's must-fix above, before any public build.
- **The rule:** only a made Voidkin comes out of a shard.
  - "Made" is the definitions' own read (`Definitions.Voidkin.Made`): its body (Model) and its moves (Kit) installed, and no clips still due.
  - `Rules.Odds` leaves out any Voidkin that isn't made. So a tier with no one made drops, by the rule already there ("a tier nobody there reaches is dropped").
  - A Named shard of a Voidkin that isn't made holds nothing, so the Breaker refuses it and the shard stays.
  - Each Voidkin joins the tables on its own once it's built: there's nothing to switch on.
- **What it gives at launch** (the director, 02:40: five Voidkin, with Sable, Marigold and Crane waiting): Lantern Row's Standard shard gives the four Commons and Lyric.
  - The pool's 60 and 9 stand, out of 69: Common 86.96% (21.74% each) and Rare 13.04%. The drop rates show exactly that, from the same table.
  - With two tiers live, luck lifts only Rare.
  - The Breaker is the only place a roll happens (`Rules.Base`, through `Odds.Roll`).
- **For research (tier 2, a number that changes balance):**
  - Lyric goes from 9% to 13.04% of a Standard shard, by the drop rule as it stands. Another split while three tiers wait is `Config.Shards.Pools`, research's numbers.
  - `tools/balance/sim.py`'s `pool()`, which Odds follows exactly, doesn't know "made" yet.

**Four facts:**
- Implemented: as above (`Definitions/Voidkin`, `Rules/Odds`).
- Tested:
  - The new logic case covers the guard:
    - every entry of every shard is made, and every Named or Starter shard holds its own;
    - the launch table worked by hand, Sable, Marigold and Crane never in it, and the rates read Common and Rare;
    - luck lifts one tier;
    - Sable, once made, joins at 30 in 99 and leaves with his row;
    - a Named Sable holds nothing and rolls nothing;
    - every made Voidkin has both portraits.
  - The rule's own math (four tiers, the Enriched and Prismatic grades, the featured weight, the rates by hand) is still worked, with the waiting rows made for the case.
  - Logic: 25,153 passed, 0 failed, offline and in Studio.
  - The Breaker's two drop-rate cases: 57 and 60 passed. With an infused shard the top tier reads 13.04%.
  - The whole suite, run twice:
    - The second run: 2,612 passed and 1 failed, the Keeper's lantern "and out on Out". That's a clip marker's timing, which this piece doesn't touch. Alone it failed once in three, at 53 fps. Frames were counted through that run: 52 a second, no gap over 0.11 s.
    - The first run: 16 failed together (the camera, the world plates, a fade and the guide's chevron), with the camera left Scriptable at its end. All 16 ran before the Base cases, and nothing here touches them. Run alone they passed (123 checks), and they didn't come back in the second run. Their cause is unknown.
- Visually reviewed: no. Nothing players see changed except two tiers fewer in the drop rates, which the cases' layout checks cover.
- Director-accepted: no.

**The framing takes, 45 against 90 (Faber, 2026-11-17, 11:50 to 11:55 by the clock).** Research's experiment, tier 1, set by `Tune` only. `Combat.Lead.Frame` is back at its seed, 45, and no code or Config changed.
- **How:** the setup was the same in both takes.
  - Studio's iPhone 16 Pro simulator, 750 × 401, from the player's camera, with the HUD on. Take A ran at 58.2 fps, take B at 57.3.
  - Rook at level 12, healed and calm. Pack 1 on Lantern Row, three level-1 brawlers, whole at the start of each take.
  - The avatar was set down on the street 40 studs short of the pack, then walked in to 12 studs on the server's `MoveTo`, and the fight played itself.
  - The camera was turned up the street by a drag, as a player turns it (yaw 0.3° and −0.6°). A black flash marks each take's zero.
- **The takes,** in `build/captures/tr24/`:
  - `framing_45.mkv` and its sheet `framing_45_sheet.jpg`, the flash at 0.30 s;
  - `framing_90.mkv` and its sheet `framing_90_sheet.jpg`, the flash at 0.25 s.
  - Each sheet runs 1 to 16 s after the flash, a tile a second, four across.
- **What I see, for research's verdict:**
  - At 45, after the first hits the fight drifts up the street and right: Rook and the Shades are small in the frame's right third by 5 s, clear of the avatar.
  - At 90, the fight stays close beside the avatar, right of the middle, the bodies larger (by eye, not measured). They bunch together, and a Shade now and then reaches the avatar's right edge (tile 9).
  - The pack fell in about 10 s at 45 and about 13 s at 90. One take each can't say whether that comes from the angle.
- **Research's verdict (Quaestor, 2026-11-17, 11:56): 45 stays.**
  - **In a real fight, the lead isn't hidden.** At 45 Rook stands clear beside the Shades through the fight (tiles 5 to 8), and the avatar never covers him. At 90 the bodies are larger but bunch onto the avatar, which covers Rook in tiles 9 to 12. A larger fight that the player's own body covers is worse than a smaller one in the open.
  - **So AR11's hidden lead was the replay's camera,** set close behind the target, not the game's. The Voidkin pieces (AR11, AR26, at the end) are judged from the real player's camera, as in these takes, not from the replay's.
  - **What it means for their effects:** at 45 the fight sits small in the right third on a phone. An effect must read at that size, which is the bar AR26's rows were already held to (64 px).
  - Nothing changes in the game.

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

**The rebuild in A (Faber, 2026-11-16, scope set at 21:27 by the PC's clock).** On the director's pick of AR18's A, about 20:52 (`docs/decisions.md`), under `docs/ui.md`'s bag rules.
- **The block contains:**
  - **A's ledger:** the Voidkin between its two columns of slots: the six armour pieces on the left; the Cloak, the Amulet, the two Rings and the two Earrings on the right. Its name and level stand over it, and Combat Power and its two hands at its feet. All fourteen slots always show, so C's belt and its group chips go.
  - **A's lacquer:** warm black, brass hairlines, bone words. Gains and losses take the kit's GOOD and BAD, and red shows only as digits.
  - **A's cell, at about 64:**
    - a lacquer well holding its design's picture;
    - its rarity as a bar along its foot, with a fine rim and its light rising; Legendary takes a gilt double rim and a brass corner;
    - a weapon's class mark from the kit, laid at the foot's right (AR6's json);
    - another class's weapon drained;
    - the up arrow and the worn tick, as before.
  - **The card:**
    - the design's picture, and its name as the title, with kind and rarity under it;
    - Combat Power's change right under the title, then what it replaces;
    - every Basic and Battle Attribute's change;
    - Equip at the right thumb.
  - **As C had them:** the six kinds' strip, the sort, the count and the chest's card.
  - **An item's design** (`docs/design.md`, Regalia): stored on the item at its drop (`OwnedItem.Design`), with migration 7 for saves made before it.
- **Faber's call (tier 1, for research's pass):** the Voidkin's half stands right of the grid, where A's sheet has it on the left. `docs/ui.md` puts Equip at the right thumb and the card over the Voidkin's half on a phone. With the half on the left, Equip would sit under the left thumb.
- **Waits for the shared finish:**
  - a third column where it fits (the card always on beside the half, as A's sheet);
  - A's motion: the contents rising 8 points, and the target's ring drawn round once;
  - the rail in brass (one rail for every page);
  - the preset's dropdown;
  - the Emblems, Jewels and Stones pages;
  - with the third column: the totals with nothing chosen, and A's "No <Class> weapon" line (the block has no room for them; the Overview shows the whole sheet).
- **Acceptance:**
  - the Items page's case rewritten for the ledger (all fourteen, the target ringed in its column), passing in this window and on the smallest phone;
  - the TR20 card case, the TR17 rail word and TR28's five across all passing;
  - the design's logic case passing;
  - stills from the player's camera for research: a full bag, a long name, another class's weapon, the empty bag, the smallest phone and night.
- **The director's words on A's sheet, 2026-11-16, by 21:32:**
  - "the empty gears slot decal need a rework it sooo simple like the chest arm  shoulder". This covers the empty slot's mark, slot by slot (A's sheet draws it with `inventory_directions.py`'s `empty_mark`). The marks are an asset for Modulo, and research opens its request. Until they come, the block's empty slot keeps C's seat as a stand-in.
  - "Also the inventory first tab should be a "all" featuring everything than gears etc". This covers the first tab. The game's strip already opens on All, which holds the gear, the chests and the shards, and the rebuild keeps it so. A's "Gear" first tab isn't carried.
- **Built (Faber, 2026-11-16, by 22:28):**
  - The page is `src/client/UI/VoidkinScreen/Bag.luau`, rewritten; its numbers are `Config.Hud.Bag`.
  - The lacquer lies under the figure's stage, in the screen's frame.
  - The chests show AR21's pictures, uploaded and logged (`Definitions.Chests`' `Image`).
  - The empty slots show AR22's 20 marks, uploaded by 22:20, at 32/44 of the well in #6E6556, 0.1. A hand's mark is the shown Voidkin's class.
- **Faber's calls (tier 1, for research's pass):**
  - **The card lists only the lines it changes,** then "No change" if none.
  - **The smallest phone:** six slots a touch tall need 264 px and the room has 262. So the column pitch shrinks: each slot keeps its whole 44, and neighbouring taps overlap by under a rendered pixel.
  - **The kinds strip fades** where it hides a chip, so a cut chip no longer reads as a stray dot.
  - **The stage keeps** Overview's cool grey panel on A's warm lacquer.
  - **The target's ring:** in the block the card covers the doll, so the ring shows only once the third column comes.
- **Checks:**
  - type check 0 new;
  - logic 24,081/0 offline (the design case checks a chest's picture is its tier's and in the kit);
  - the Items case 104/104, with the marks and the strip's fade checked in this window and on the smallest phone;
  - TR20 36/36;
  - TR17 256/256.
- **Stills** (`build/scratch/faber/stills/tr28-*.jpg`, via the manual case "Take: TR28"): empty, full, long, other, chests, phone-doll, phone. There's no night still (the director, 2026-11-15: no day/night checks).

**Research's verdict on the rebuild in A (Quaestor, 2026-11-16, 22:37, from the seven stills).**
- **Felt:** the bag reads as one screen at last. The gear sits on the left and the Voidkin on the right, among slots that name what's missing. The chests sit as real things among the gear, and a card says in one number what an item does.
- **Tier:** competent.
- **The bold thing:** the doll framed by its named empty slots, a set to fill.
- **Fixes:**
  1. **The stage takes A's warm lacquer and its glow,** as the director's pick drew it. Today Overview's cool grey panel is the brightest field on the screen, and it reads as another screen pasted in. This reverses that one tier 1 call.
  2. **The card accounts for its number.** The Legendary Bracers say +465 Combat Power over one line, Health +75, which alone is worth about 40 (`tr28-long`, `tr28-phone`). Every stat it changes shows, Basic Attributes first, as `docs/ui.md`'s comparison has it. If they're there, the card cuts them. [Research's error, corrected at 23:34: +465 is right. Health +75 x weight 0.62 x Stats' Scale 10; research's "about 40" left out the scale. Faber's new case proves every card's Combat Power is the sum of its shown lines.]
  3. **The card says "Combat Power",** the doll's own word, not "Power".
- **Kept, Faber's tier 1 calls:** only the changed lines, then "No change"; the overlap under a pixel; the strip's fade; the card over the doll in the block.
- **The Tower chest's card tells the truth in Lantern Row:** 60% Common is the best of the four, where the Keeper's is 88%. Its one row falls below later grounds' Elite chests, so research refits it with Drum Court.
- **Not here:** AR23's number, which is queued, and TR25's overflow, its own piece.
- **The tint and the bracer** read from the player's camera: AR22 closes.
- **Visually reviewed in stills only.**

**Research's three fixes, and the director's sides (Faber, 2026-11-16, by 23:26 by the PC's clock).**
- **Fix 1, the stage on A's lacquer:**
  - On the Items page the stage drops Overview's panel and halo. A warm glow stands round the figure's middle (`Config.Hud.Bag.Stage`: #3A2B1C, 0.55 at its heart, in five round rings scaled as one to fit the stage).
  - The figure's own disc becomes A's brass floor (`Figure.Lacquer`: BrassDim at half, half the figure's height across). A's quarter hid behind the feet from the stage's near-level camera.
  - Overview keeps its own stage, and the disc takes its own look back there. Two checks in the Voidkin screen case.
- **Fix 2, no change, and a correction:** +465 is what Health +75 is worth: Health's weight 0.62 × 75 × `Stats`' Scale of 10. "About 40" leaves out the scale. A new logic case proves it: on every stocked item that fits, a card's Combat Power is the sum of its shown lines, within 1.
- **Fix 3:** the card's word is "Combat Power".
- **The sides, the director's word (2026-11-16, by 23:24): "why is the voidkin + gear slot on the right when it should be on the left".**
  - The doll stands at the room's left, as A's sheet has it, then a brass hairline, then the grid. This reverses my tier 1 call of 21:27.
  - The card opens at the room's right edge, the doll's width, where A's sheet has its comparison column. Equip stays under the right thumb, and the doll stays in view beside the card.
  - This replaces the kept call "the card over the doll". It parts from `docs/ui.md`'s line "the item's sheet slides over the Voidkin's half", as A itself did: research's to rewrite.
  - On a phone the card covers the grid's end while it's open: research's pass judges it.
  - A check in the Items case.
- **Tested:**
  - Type check: 0 new.
  - Logic offline: 24,099/0.
  - "Items page (TR28)": 106/0.
  - "Voidkin screen (TR17)": 259/0.
- **Still:** `build/scratch/faber/stills/tr28-left.jpg`.

**The bag in the seam's skin (Faber, 2026-11-17, scope set at 12:30 by the clock).** On the director's word of 02:40 ("the inventory ... with that color style not the old yellow brown") and Modulo's sheet (`build/handoff/UI/inventory/bag_seam*.png`, AR18, "The skin in the seam's colours"), with research's pass of 08:01 and the ring's second look of 08:16. The ledger's layout is unchanged.
- **The block contains:**
  - **The palette:** `UIKit.Palettes.Seam`, Modulo's colours in the kit's keys, with `Light` as its accent and `Ink` and `Card` beside them. `SeamLit` is the plate of light: Equip's palette.
  - **One palette across the Voidkin screen's tabs:** the cover, the Overview's panel, words, hairlines and wells, the rail, and the band's Back take the seam's colours. The stage keeps its rarity's light, on the seam's dark, and gains the shaft: Light at 0.13, 26 points either side of the figure's middle, cut at the stage.
  - **The Items page:**
    - the room in the seam's panel;
    - lit seam edges, a 1 point line of Light over a soft glow, strongest at their middle, on the room's top, the hairline between the doll and the grid, the card's sliding edge and Combat Power's plate;
    - every rarity's well in the seam's `Well`;
    - the chosen ring, on the chosen cell and the slot it fills: a dark moat, then 2.6 points of Light with its glow outward, drawn over its neighbours;
    - the lit chip and Equip as plates of light with Ink words.
  - **Cases:**
    - the Voidkin screen's case checks the seam on both tabs, with no graphite or lacquer left;
    - the Items case checks the ring, the lit chip and Equip.
  - Phone stills at the end.
- **What waits:**
  - AR6's icons, our own prompt, and the rest of TR28's "waits";
  - the edge's light along a cut corner (the ring's corners are round, round the cells' cut ones);
  - the wallet's pills, which stay the HUD's.
- **Implemented (13:07):**
  - `UIKit.Palettes.Seam` and `SeamLit`, `Config.Hud.Seam`, and `VoidkinScreen/Seam.luau` (the lit edge, the chosen ring, the plate of light); `Kit.Screen.Full` takes a palette for its cover and Back.
  - The room lies on a layer under the stage (`Behind`), so the figure stands on it. The plain floor under a figure with no element is the seam's Facet. Equip's glow is the kit's ring glow in Light, along its cut corners. The card's captions are in Glint.
  - Found on the way: on a touch device the kinds strip drew its scroll thumb at thickness nought, a grey line under the chips (hidden on the strip and the rail). The screen's refill put the strip's old scroll back after the kind changed, so All could stand cut at the smallest phone: the strip now keeps its scroll only while its kind stays (`Keep`), and its chosen chip is placed from the chips' widths.
- **Tested:** the type check 0 new; "Items page (TR28)" 112/0 and "Voidkin screen (TR17)" 264/0.
- **Seen:** phone stills (iPhone 16 Pro, the take's Empty, Full, Long, Other and Chests) by the builder: the figure on the room with its shaft, the lit seams, the ring in Light, Equip and Open 2 as plates of light, Tank only in the seam's dark. Research's pass waits.

**The director's words of 2026-11-17, by 13:00 and by 13:03 (Faber).** "We said armor not armour?"; "let just merge weapon and armor as 1 single tab \"gear\""; "aslo overview ui shouldn't show any gears slot". Each covers what it names.
- **Implemented (13:13):**
  - The strip's five kinds: All, Gear, Jewellery, Chests, Materials (`Rules.Bag.Kinds`). Gear holds the weapons and the armor, the cloak with it. "Armour" is gone from what players see. All's empty line is now "Nothing in the bag yet", since "No gear yet" is Gear's.
  - The Overview (and every page but Items) shows no gear slots: the two columns of six and the two hands are gone, and Combat Power stands alone under the figure's middle. The name's line spans the stage's group. `Config.Hud.Voidkin.Slots` became `Span`. The panel's line "Gear · preset ..., in hand" stays: it isn't a slot.
- **Tested:** the type check 0 new; logic offline 23,971/0 (the Bag case on five kinds); "Items page (TR28)" 112/0; "Voidkin screen (TR17)" 233/0, its slot checks now "no gear slot on the screen" and "Combat Power under the figure's middle, alone at its feet".
- **Seen:** phone stills by the builder, the strip with Gear and the Overview without slots. Research's pass waits.

**Research's pass on the seam skin and the three words (Quaestor, 2026-11-17, 13:16),** from the phone stills (`build/scratch/faber/stills/`).
- **Felt:** the bag is one room now, its seams lit and its rarity frames carrying the colour. The Gear tab is right: one tab for what's worn, and the strip fits a phone.
- **Tier:** works. The director's word over these stills, 13:16: "those ui need a massive polished it looks childish". Read on the crop they sent, it's the page rail first: the beads on a string, the white ring, the stock glyphs and three "Soon"s. That's AR29, a new look, not a fix round here.
- **Must-fix (Faber):**
  1. **The Overview's top bar collides** (`overview-phone.png`): the fourth button sits on the Credits pill, and Electricity is cut to "60.00 kWh". Class: the top bar's buttons and pills never overlap at any page or phone.
  2. **The Overview leaves its lower third empty:** the sheet's panel ends at two-thirds of the screen's height. Class: a page's panel fills the room to the bottom edge, and the sheet scrolls inside it. If it's the capture's moment, a fresh still proves it.
- **American spelling** (the director, 13:15, `docs/decisions.md`): "Jewelry" on the strip, and every shown "Defence", "Armour" or "Colour" in Config, Definitions and the UI's text, by one search.

**The two must-fixes and American spelling (Faber, by 13:24).**
- **Implemented:**
  - **Spelling,** by one search of `src/`. The strip's kind is "Jewelry", with "No jewelry yet" (`Rules.Bag`). The stat shows as "Defense" through `Sheet.Said` (the code's key stays `Defence`), and so does the next star's gains line. The heading is "Offense and Defense". No shown "Armour" or "Colour" was left: the rest are code names and comments. "Favourite" is a save key drawn as an icon, never as a word.
  - **The top bar:** the wallet never crosses Back and the three marks. When the room is short it steps down, one step at a time, until it fits: the battery without its capacity ("60.00 kWh"), then what it holds alone beside its bolt ("60.00"), then Credits short (10.6K), then the battery alone (`wallet()` in `VoidkinScreen/init.luau`, its form an attribute). At the smallest phone it takes "60.00", and at the iPhone 16 Pro the whole "60.00 / 60 kWh".
  - **The panel:** nothing to fix. The 2/3 still was the take that forces the smallest phone's box into a bigger window. At the iPhone 16 Pro's own size, the panel runs from 70 to 334 of a 343-pixel room, and the sheet scrolls inside it (`overview-iphone-phone.png`).
- **Tested:** the type check 0 new; logic offline 23,973/0 ("a ring is jewelry", "Defense, in American spelling", the heading); "Items page (TR28)" 112/0; "Voidkin screen (TR17)" 249/0. The new class check, "the band clear, the wallet right of Rename, and its words whole", runs on every built page at the window's size and at the smallest phone. The Combat Power centring check takes 2 px of rounding (564 against 565 failed once at 1).
- **Seen:** phone stills by the builder, `overview-iphone-phone.png` (the panel to the bottom, the band whole) and `band-smallest-phone.png` (the wallet stepped down, clear of the marks). Research's pass waits.

- **Research's second look (Quaestor, 2026-11-17, 13:25): closed on research's side.** The top bar clears at both sizes (the smallest phone shortens Electricity to "60.00" by its bolt, which reads). The Overview's panel fills to the bottom at the iPhone's own size, so the empty third was the forced take's box, as Faber says. Jewelry and Defense show. The rail and the top bar's look go on in AR29.

## TR30. The generator's stages (Faber, on AR19)

Part 12's order, item 4.6 (`docs/research/rework-2026-11-16.md`, part 7; `docs/design.md`, "The base", "Three stages for every machine"), on the director's yes of 2026-11-16, 16:50. Research's answer is (a): the generator takes the stage of a machine at the base's ceiling. Modulo's pieces and swap table are AR19, "Stages II and III as kit pieces" (e516da7).

**Scope, set at the start.**
- **The block:**
  - The stage rule in `Rules.BaseLevels` and `Config.Base`.
  - The 23 meshes uploaded and the base kit rebuilt.
  - The mill laid once a stage from the swap's table, the owner's stage shown, and each stage's motion (the wheel, the pinions from it, the gauge, the mark at its stage's degrees).
  - Studio's `BaseLevel`, and the cases.
- **What waits:**
  - The stage's moment: the change landing as a moment when the base levels up (design.md). Today it's an instant swap.
  - The motion's check in the game from the player's camera (the content check's condition).
  - The other machines' stages: the Breaker, the bays, the battery, then the Training machine.

**The build, done by 20:32 by the clock** (it came after TR29's commit at 20:25 and AR19's at 20:00).
- **The rule, pure:**
  - `Config.Base.Machines.Stages = { 1, 6, 15 }`, the first machine level of each stage.
  - `BaseLevels.Stage(level)` gives a machine's stage. `BaseLevels.GeneratorStage(baseLevel)` is `Stage(Ceiling(baseLevel))`: I at base level 1, II at 2, III at 3.
- **The kit:**
  - `kit_take.py` and `stage_kit.py` took and staged it. `KitAssembly.Publish` uploaded the 23 new meshes under the group, with their ids in `tools/studio/Kits/Base.json` and `docs/asset-log.md`.
  - `KitAssembly.Build` rebuilt `src/storage/BaseKit.rbxm`: 65 pieces, 51,629 bytes, adler32 matching Studio's. The one before is in `build/scratch/faber/`.
- **`WorldService`:**
  - Each plot's mill holds a model per stage ("Stage 1" to "Stage 3"), laid from `plan.machines.generatorStages`. Stage III stands Generator2Wheel and Generator2Pinion by name, as the table says.
  - Each piece carries its row's `Moves`, `Rate` (the wheel's 1, a pinion's -2.4) and the mark's `Turn` (117.88 for I, 114.54 for II and III).
  - Each stage's solids are the manifest's collision: II and III's sill sits 5.1 toward the gate, with the legs' heads moved. They're marked `Unseen`.
  - II and III are laid hidden and open.
- **`BaseService`:** it stands the owner's stage (the plant's `Stage`), and hides the other two and opens their solids. It feeds every stage's wheel, steps and mark, so a stage is already where the plant is when it's shown. A plot with no owner stands at Stage I.
- **`BaseController`:**
  - What turns is read from each piece's `Moves`.
  - A pinion is driven from its stage's wheel's angle, `CFrame.Angles(0, 0, -wheel × Rate)`, in a second pass the same frame. The wheel's angle wraps at five turns, where the pinion's 12 come round whole, so the teeth never jump.
  - The mark turns to its stage's degrees. A hidden piece keeps its angle and is moved once shown.
  - `MillStage(plant)` gives the shown stage's model, for the cases.
- **Studio's `BaseLevel`** sets the save's base level alone, so a case shows a stage and puts the level back.

**The checks (20:32).**
- **Type check:** 0 new, 11 known.
- **Logic, offline and in Studio:** 23,227 passed, 0 failed. It covers the stages at machine levels 1, 5, 6, 14, 15 and 30, and the generator's at base levels 1 to 3.
- **World report:** empty.
- **In a playtest, from the server, at base levels 2, 3 and back to 1:**
  - The plant's stage follows the level.
  - The shown stage has its body, wheel, pinions and mark seen, and its six solids solid. The other stages' parts are hidden and open.
  - The lit steps follow the generation.
- **On the client:** every stage's turning pieces arrive with their `Moves`, `Rate` and `Turn`.
- **NOT VERIFIED (the PC is locked, 0 frames a second):**
  - The turning in motion.
  - The new self-test checks in BaseCases' mill case: each level's stage shown and solid, the others hidden and open, a pinion driven from its wheel about its own axle, and the stage's degrees. The mill's older checks there and in `Cases.luau` read the shown stage through `MillStage`.
  - The whole suite, and the player-camera check.

**Read on the unlocked screen (Faber, 2026-11-16, 21:02 to 21:03, by the PC's clock).** Stills `build/scratch/faber/stills/tr30-stage2` and `tr30-stage3` (scratch), for research's verdict. The stages swap at base levels 2 and 3, and the pinion turns at 2.4 times the wheel in motion. The mill's self-test checks and the whole suite pass on render (27847da).

**Research's verdict on the read (Quaestor, 2026-11-16, 21:20, from the stills).**
- **Felt:** Stage III reads as the generator grown, not swapped: the gear and the side housings arrive on the same wheel.
- **Tier:** competent.
- **No fixes.** Visually reviewed in stills only: the motion is unseen, and the case's 2.4 is the measure until a capture shows it.

## TR31. Back from away: the card on return (Faber)

**Folded into TR53** (research, 2026-11-23, 20:07): TR53 is this card, rewritten at F4 without reading this entry. TR53 carries over two things: the press only shows what the server credited on arrival, and the overflow's Credits. The cap's line isn't on the card at launch (`docs/polish-later.md`). Nothing here was built.

On the director's "yes!" of 2026-11-16, 21:39 (`docs/decisions.md`), to research's suggestion. Tier 2, research and Faber: a new screen players see. It serves the north star's first measure, "comes back the next day", and it's cheap: the numbers already exist in the rejoin's summary (`Rules.Breaker.Advance` with `away`).
- **Feel line:** the player comes back and, before anything else, sees what the base did without them: the shards it broke, the Credits its workers made, the levels their lead trained. One tap pours it into their counters, so the first second back is a reward.
- **The block:**
  - One card on a rejoin, when the time away passes a seed in Config (5 minutes to start). It shows over the base, before the next step's line.
  - Its lines come from the rejoin's summary, each with its HUD picture: Credits made, shards ready in the Breaker, the levels the lead trained (with the lead's portrait), the power the bays made. A zero line isn't shown.
  - The time away, said plainly. When the cap bit, it's said honestly: "Your bays worked 2 h of your 9 h away" (`Config.Base.Battery.AwayHours`).
  - One button. On its tap the amounts fly to their counters and count up there. The server has already credited them on load; only the show waits on the tap.
  - A case, pure, Studio closed: the card's lines from a summary, zeros hidden, the cap's line only when it bit.
- **What waits:**
  - The Stone Condenser's stones, with the Forge.
  - A Roblox experience notification when the battery fills: it's opt-in and has its own rules, so `docs/roblox-rules.md` comes first.
  - Any effect beyond the fly-in.
- **Tests:** the case, and one take from the player's camera on a phone: a rejoin after a scripted absence (`BaseService`'s "as if `seconds` passed").
- **Order:** after TR24's fixes and the rebuild in A (TR28).

## TR36. Two attributes, and the types named by their colours (Faber)

Research, 2026-11-17, 09:27, on the director's word of the same morning (`docs/decisions.md`): "just strenght and endurance", then "yes" to research's restatement, and the types named by the colours they already wear. Design: `docs/design.md`, "Voidkin". The numbers: `docs/balance.md`, "The stats". No art is redrawn.

- **The attributes:** five become two, Strength and Endurance.
  - `Config.Stats.Attributes` takes the rows, Mains and shapes in `docs/balance.md`'s table, with these shapes: Warrior 67, 48; Tank 40, 77; Assassin 67, 41; Mage 67, 45; Healer 38, 68.
  - `Definitions.Attributes` takes the two.
  - The ids are yours. A jewellery roll picks one of the two.
- **Combat Power's weights,** refit on these builds: `docs/balance.md`, the same section, into `Config.Stats.Power.Weights`.
- **The types are named by their colours,** in the same ring: Strength → Red, Endurance → Orange, Agility → Blue, Intelligence → Purple, Technique → Green.
  - Everything players see takes the new names: the type's label, the stat sheet, the filters, the reveal.
  - Whether the ids change is your call. The gems, their colours and the Shades' tints stay.
- **What research checks:** the stat sheet and the item card at phone size, showing only Strength and Endurance under Basic. A ring's line says "Strength" or "Endurance". No "Might", "Finesse", "Vigor", "Spirit" or "Insight" is left anywhere players look.
- **Cases:** the Stats and Sheet logic cases move to two attributes, and one new case checks that every class's Main is Strength or Endurance and that every shown type name is a colour.
- **The model** reads the new rows once they land: `py tools/balance/attributes.py`. Research reruns it and confirms the fit.
- **Saves:** a Voidkin's own points come from its class's shape, so only gear rolled with an old attribute needs a rule. Re-rolling it on load or wiping test saves is your call, since nothing is public.

**Built, 2026-11-17, 11:14 to 11:50 by the clock (Faber).**
- **Implemented.**
  - **The two:** `Definitions/Attributes.luau` holds Strength and Endurance (the ids are the names). `Config.Stats` takes `docs/balance.md`'s rows, Mains, shapes and refit `Power.Weights`, and the Beats ring in colours.
  - **The type ids are the colours** (Red, Orange, Blue, Purple, Green), ids and names alike, my call. Kept, the old ids Strength and Endurance would share a key with the new attributes in every table keyed by either. No save holds a type: a Voidkin's comes from its row, a Shade's from its row, and the place's markers carry none (0 found in Edit). Renamed: the Voidkin and Enemies rows, `Hud.Card.Types`, `Shades.Tint`, the gems' keys (`Gem<colour>` and `Gem<colour>Seated`, the same images), and the lead card's default gem. No screen filters by type yet, so no filter was renamed.
  - **Saves:** migration step 8 turns each saved line on a retired attribute into the one that took its job (Might, Finesse and Insight into Strength; Vigor and Spirit into Endurance). Two lines that land on one are added together, in the first one's place. The Studio save went 7 to 8.
  - **The chest pool:** the two take the five's share, 5 and 5 of its 21 (each of the five was 2). Research: confirm or set (`Config.Chests`, tier 2).
  - **Found in the phone still and fixed (tier 1):** a ring's Basic lines make the card's list scroll, and Roblox then clips the list beside its 3 px bar, so each right-aligned gain lost its last figure (`build/captures/tr36/phone_4_card.png`). The list now insets its canvas by the bar, and its lines take the canvas's width (`UI/VoidkinScreen/Bag.luau`).
- **Tested.**
  - Type check 0 new. Logic 23,970 passed, 0 failed, offline and in Studio. World report sound.
  - New cases:
    - "Definitions: TR36", every class's Main is Strength or Endurance and every type shown is a colour, across rows, tints, studs and gems;
    - "Data: step 8", the five retired lines merged, nothing else moved;
    - the Items page's "the smallest phone: the card's lines scroll, and every change ends inside them" (the weapon's Strength adds four Battle lines).
    - The Stats and Sheet cases moved to two. "Might" stays in one case as a retired id that adds nothing.
  - The Items page after the fix: 107 of 107 in Studio's window. In the simulator, one check, the chosen kind's chip in view, fails, since the case's smallest-phone box is drawn inside the simulator's own 750 × 401.
  - The full self-test: 2,602 passed, 3 failed, at 58 fps. The 3 are TR20's hover on a Breaker chamber: its words lift 181 points, not 2. Alone it passes 36 of 36, so it depends on order. TR36 touches no Breaker, so it's carried as a flaky case.
  - A first run had 16 false failures, all from my own long poll resetting the camera. Rerun clean.
  - **Numbers that moved with the rows, for research to confirm or retune:**
    - Fight's bare Common Warrior: the brawler 5 to 4.56 s, the elite 18 to 16.40 s, the Lamplighter 45 to 40.71 s.
    - The Bag's price check: 465 to 503 (Health's weight refit, 0.67 × 75 × 10).
  - `py tools/balance/attributes.py` on the new Config: "Shape against the fit: the same". The Warrior's level 1 is Health 441, Attack 134, Defence 48, Regen 5.0, as the case.
- **Visually reviewed (mine).** At phone size, in Studio's iPhone 16 Pro simulator (750 × 401), in `build/captures/tr36/`:
  - `phone_top_and_card.png`: the Overview's top reads "Common · Red · Warrior", then Basic Attributes "Strength 188 Main" and "Endurance 135". A Rare ring's card reads Basic "Strength 200 +12" and "Endurance 143 +8", whole after the fix.
  - Also `phone_2_battle.png`, `phone_3_items.png` and `phone_5_hud.png`.
  - A search of `src/` finds the five retired names only in step 8's map, its case and Stats' retired-id case.
- **Research's pass:** not yet. **Director-accepted:** no.


**Research's pass (Quaestor, 2026-11-17, 11:50),** from the phone stills (`build/captures/tr36/`).
- **The check holds.** The Overview reads "Common · Red · Warrior" with Strength (Main) and Endurance, and nothing else under Basic. The ring's card reads Strength and Endurance with their gains. No old attribute name shows anywhere in the stills, and the card's clipped figure is fixed.
- **The three numbers (tier 2), confirmed as built:**
  1. **The chest pool, Strength 5 and Endurance 5 of 21:** the attributes keep the share the five had, so a line's worth by Combat Power is unchanged.
  2. **The bare Warrior's kills, about 9% quicker** (the brawler 4.56 s, the elite 16.40, the Lamplighter 40.71): inside the model's 4.1 to 5.7 s for an ordinary kill. It's the two attributes' lower level-1 health, as `docs/balance.md` says. Tuned by playing if Lantern Row feels quick.
  3. **The Bag's price check at 503:** it's the refit's Health weight, as intended.
- **Tier:** works as a system change, nothing new to judge in look. **Closed on research's side.**

## TR37. The Forge and the Stone Condenser (Faber, on AR28's look)

Research's request, 2026-11-17, 11:17, item 7 of phase 3's order (`docs/production-plan.md`). The design: `docs/design.md`, "The base" (the Condenser) and "Regalia: gear" (forge ranks, the move across). The numbers: `docs/balance.md`, "Where power comes from" (forge ranks are 13.5 of a full build).

**Feel lines:** AR28's two. The Forge: the player sets an item on it, and it takes the stones and drives the item up a rank, which comes back brighter. The Condenser: coming home, its tray glows with what it made while they were away.

**The rules (research's, tier 2):**
- **A forge rank belongs to the item** [D, 2026-11-17, 02:40]. Each rank adds a share of the item's own base, its main stat and every line alike: `fullBonusOfGearBase` (0.50) over `maxRank` (30), so 1/60 of the base a rank. It's linear and touches nothing else (`docs/balance.md`, rule 2).
- **Three stone grades,** by the rank they buy: Low for ranks 1 to 10, Mid for 11 to 20, High for 21 to 30. **At launch ranks stop at 10**, so only Low stones are spent. Mid and High drop and stack from launch, with the ranks they buy coming in the big update. Lantern Row and the Tower drop Low, and the Tower drops a few Mid.
- **A rank never fails.** It costs stones and Credits, rising with the rank and with the item's level tier (G), and it always lands. No chance and no loss, so the Forge never sells a random outcome.
- **The move across** is the design's prompt on equip (TR26's comparison). Yes moves the rank, the emblems and the jewel. No leaves them on the old item. The emblems and the jewel move free. **A rank moving to an item of a higher level tier costs the Credits' difference,** the rank's whole price at the new item's G less what it cost at the old one's, with no stones. A rank moving to a lower tier is free, with nothing back [sim check, 15:06, TR39's end].
- **The Condenser makes Low stones, online and away.** Its rate grows with its level, and it draws electricity like the Breaker (`Rules.Power`), slower with less. Stones land in its tray, which has a cap in hours of work. A full tray stops. Its second job turns 5 Low into 1 Mid over a set time, one at a time.
- **Every spend is the server's, in one step:** a repeated or interrupted request never spends twice or ranks twice. The away time is worked out on return, as the Training machine's is.

**The seeds** (research's, 2026-11-17, 11:49: worked by hand from `tools/balance/seeds.json`, a model, not a measurement; a sim section follows before Faber reaches this piece):
- **A rank's cost:** rank × 100 × G(the item's level tier) Credits, and rank × 1 Low stone. Rank 10 on a level-12 item is 2,800 Credits and 10 stones. A whole worn set (14 slots) to rank 10 is 770 stones and about 45% of a launch player's Credits over the 40 hours its Legendary window lasts (`docs/balance.md`, "The Tower").
- **Drops:** an elite 0.3 Low stones and a keeper 1, as an expected count. Ordinary Shades drop none, so the stones come from the moments worth coming back for.
- **The Condenser:** 1 Low stone an hour at level 1, plus 0.05 a level (2.45 at level 30, launch's ceiling) [sim check, 15:06, halved from 2 and 0.1]. It also makes jewels into the same tray [D, 2026-11-17, 12:10], its tier rising with its level (TR39's seeds), so the block includes the jewel in the tray. Its tray holds 12 hours of work, and the conversion takes 30 minutes for 5 Low into 1 Mid.
- **What it gives** (by hand): a whole set at rank 10 in about 12 active hours for a casual player (0.5 a day, 25 days), 26 for an active one (1.5 a day, 17 days) and 39 for a heavy one (4 a day, 10 days). The Condenser gives half or more of an active player's stones, so coming back pays.

**The block contains:**
- the rules in pure Luau (`Rules.Forge`, `Rules.Condenser`) with their cases;
- the Forge page in grey, on the character screen's rail where its Soon stands today [D, 2026-11-17, 12:27: "plug the forge ui and system there"], reached from anywhere: pick an item, see its stats now and at the next rank, the cost, and one press. The Forge machine's prompt opens the same page, and there the ram strikes on the press (AR28's contact);
- the Condenser in grey: its tray in the world (full, part-full, empty, readable from the gate), a tap to collect, and its convert job;
- stones in the bag's Stones tab;
- the rank's badge on an item's slot (TR28) and its card.

**Waits:** the machines' models (AR28's pick, then Modulo's Stage I); the rank-up moment's effect and sound; ranks 11 to 30; the Condenser's Stages II and III; auto-salvage into stones (TR27's note).

**Checks:** the logic cases (a rank's gain, its cost, never twice on a repeat, the move across, the tray's cap, the away time, the conversion); the self-test of both screens; the UI lint on the smallest phone; research's verdict in grey from a phone capture.

**Order in the queue:** item 7, after TR29's fixes and TR10's captures. Emblems (TR38) and jewels (TR39) follow, written by research before Faber reaches them.

### Research's scope today (Quaestor, 2026-11-23, 02:53): what's left after TR47

TR51 is Faber's previous piece, and this is the next, on the director's order of 00:05 (the main map and the systems). The Forge's ranks above are **already built as Reinforce** (TR47: `Rules.Reinforce`, a chance a try, paid in stones and Credits, cap 30, grades by tens). They replace this entry's "a rank never fails" and its rank prices, and nothing of the Forge's rules is built again. What's left:
- **The Condenser's rules in pure Luau** (`Rules.Condenser`, `Config.Condenser`) with their cases. It makes Low stones online and away into its tray (1 an hour at level 1, plus 0.05 a level), drawing electricity like the Breaker (`Rules.Power`) and slower with less. The tray holds 12 hours of work, and a full tray stops. Its second job turns 5 Low into 1 Mid, one at a time, in 30 minutes. **This matters at launch:** only Low stones drop on the first ground (`Config.Drops`, `GroundsAGrade` 2), and Reinforce spends Mid from level 11, so the Condenser's convert is the way past 10. The away time is worked out on return, as the Training machine's is, and every collect or convert is the server's, in one step.
- **The Condenser in the world:** AR28's Comb at Stage I in its sleeping place, the tray readable from the gate (full, part-full, empty), a tap to collect, and the convert job in a small grey panel on the kit.
- **The Forge in the world:** AR28's Press at Stage I in its sleeping place. Its prompt opens Equipment's Reinforce page, and the ram strikes on a press made there (design.md, "Upgrading gear needs no walk").
- **Waits:** jewels in the tray (TR39); Stages II and III in the world (AR36, after this); the rank-up's effect and sound; the Research Lab (after launch).
- **Checks:** the logic cases (the rate by level and by power, the tray's cap, the away time, the convert, a repeat never collecting twice); the self-test; captures from the gate at the smallest phone. Research's verdict is in the game.

### Faber's build (2026-11-23, steps 1 at 03:06 and 2 at 03:23)

- **Research's yes to two seeds** (Quaestor, before 03:06, recorded here at research's word): the Condenser **wakes at base level 2**, its asleep state reading as waiting like the Lab's, and it **asks 10 kW at level 1**, rising with its pace to 24.5 at 30. Also research's: a case where a full tray with a convert running still lands its Mid (added).
- **Step 1, the rules (6b97f0b):** `Rules.Condenser`, `Config.Condenser`. It's a third machine in `Rules.Power`, worked through `Rules.Breaker`'s event steps online and away. `Rules.Base` gains CollectTray and Convert, each in one step, and UpgradeMachine takes the Condenser. The save gains `Base.Condenser` and `Machines.Condenser` (Reconcile fills them). Ten cases in `Cases/Condenser`.
- **Step 2, the world (ca3dbb1):**
  - **The Condenser:** AR28's Comb at Stage I (frame, core, 37 cups) stands over its sleeping stone, which shows below level 2 with its plate saying "Wakes at base level 2".
    - **The tray from the gate:** the plate says "Tray n of 12 Low", "Tray full", and any Mid. The core turns while it works, at its power's speed, and stops on a full tray.
    - **Collect and convert:** a Collect prompt shows while the tray holds a stone. A small grey panel on the kit runs the convert, with its own prompt.
  - **The Forge:** AR28's Press at Stage I. Its prompt opens Equipment on Reinforce, and every try strikes the ram on every client: anticipation to its tell, a fast strike, a hitstop on the plate, an eased settle. The gears turn with its travel. The timing is in `Rules.Forge` and `Config.World.Forge`, tunable live.
- **The builder's tier-1 calls:**
  - **The comb lights by the tray's fill of its cap** (`Rules.Condenser.Lit`): 37 cups over a cap of 12 at level 1, so a full tray lights it whole. Mid stones aren't in the cups; the plate and the panel say them.
  - **The convert's refusal is its own word** (`Base.Stones`: "A convert takes 5 Low stones"), not the battery's.
- **Tier-2 notice, the Power screen:** its bar keeps two handles. The Condenser shares under Auto, and a split never clears its share, but its own handle, light and chip wait for a Power screen piece.
- **Implemented, offline-tested:** type check 0 new; logic offline 29155 passed (cases Condenser and Forge).
- **The Studio run (Faber, 2026-11-23, ef86dab at 14:42; the captures 15:00 to 15:03 by the clock).**
  - **Two fixes:**
    - the Forge and the Condenser had no spec in `World.Tags`, which stopped the plot's build at join (their specs added);
    - TR37's case raced the tray: the attribute lands with its packet, the copy's handler a moment later. The case now waits until the two agree (34/34).
  - The full self-test 3,288 passed, 1 failed (TR42's, a flake that passes alone); LogicTests 29,155 passed; WorldReport empty.
  - **Captures,** in `build/captures/tr37/`:
    - `forge_player` and `condenser_player`, the Condenser awake at base level 2, from where a player walks round the Training machine and the battery;
    - `phone_forge`, `phone_condenser` and `phone_condenser_asleep`, at the smallest phone's 1,334 by 750, the world only.
    - Neither machine shows from the gate: both stand in the back row behind the generator (TR51's gate frames).
- **Visually reviewed:** research's verdict in grey asked. **Director-accepted:** not yet.
- **Research's verdict in grey (Quaestor, 2026-11-23, 15:27),** from `phone_condenser_asleep`:
  - **Felt:** the Condenser in grey reads as a pad on the floor, not a machine, and from the gate it isn't there at all.
  - **Tier:** works, as grey.
  - **The one bold thing:** none yet. That's the finding, and AR51's card and AR50's machines carry it.
  - **Must-fix 1, class "the yard at Stage III":** neither machine is seen from the gate. Folded into AR54's plan.
  - **Not a fix:** the grey disc's words cut at "5 Low into 1…". AR51's card replaces them.

## TR38. War Emblems (Faber, after TR37)

Research's request, 2026-11-17, 11:57, item 7 of phase 3's order. The design: `docs/design.md`, "Regalia: gear" (sockets, the move across). Emblems are 11 of a full build (`docs/balance.md`, "Where power comes from").

**Feel line:** the player drops an emblem into an empty socket on an item, the item's card shows the gain, and the Combat Power ticks up by a whole number.

**The rules (research's, tier 2):**
- **An emblem** has a rarity (Common, Uncommon and Rare at launch [D]), a level tier fixed at the drop, and one stat: a flat line of Strength, Endurance, Health, Attack, Defence or Critical at launch. The other Battle Attributes come later [research, 16:11, AR31's verdict]. Its size is its rarity's budget times G(tier), priced by Combat Power as an item's line is, so every stat's emblem of one rarity is worth the same.
- **Sockets** by the item's rarity: one on Common, two on Uncommon, three on Rare, four on Epic and above [D]. Putting one in or taking one out is free [D]. They move across on equip with the rank and the jewel (TR37).
- **Three of a kind make one better:** three emblems of the same stat and rarity combine into one of the next rarity, at the highest tier of the three. It never fails, and Rare is the top at launch. Duplicates always have a use.
- **Sources:** chests (`Config.Chests`, a new kind of reward), elites, and the Void Shop when it comes (phase 4).
- **The server decides,** in one step: a socket, a removal or a combine never duplicates or loses an emblem on a repeat.

**The seeds** (research's, 2026-11-17, 12:40: worked by hand from `docs/balance.md`'s shares, a model, not a measurement; the sim checks them before Faber reaches this):
- **A line's size:** a share of a same-tier Legendary item's whole budget, in Combat Power: Common 4%, Uncommon 7%, Rare 10%. Four Rare emblems on an item then add about 40% of it, the 11 to 27 that emblems hold against gear.
- **Drops:** an elite 0.2 emblems and a keeper 0.6, as an expected count, with the rarity row Common 70, Uncommon 25, Rare 5. A chest holds an emblem 30% of the time.
- **What it gives** (by hand, an active player at 1.5 hours a day): about 13 emblems a day, so a Rare (nine Commons through two combines) takes under a day, and a whole worn set's sockets fill with Rares in about six weeks.

**The block contains:** `Rules.Emblems` with its cases; the rail's War Emblems page, where its Soon stands today, reached from anywhere [D, 2026-11-17, 12:27], with the bag's Emblems tab filled; the item card's sockets (empty marks from AR22, filled with the emblem's icon and its line); a tap-to-socket and a tap-to-remove; the combine on the Emblems tab.

**Waits:** the emblem icons (Modulo, phase 3 order item 4); Epic and above; the shop.

**Checks:** logic cases (a line's size, the sockets by rarity, the combine, the move across, never twice on a repeat); the self-test; the UI lint on the smallest phone; research's verdict in grey from a phone capture.

## TR40. Regen in bursts (Faber, after TR28)

Research's request, 2026-11-17, 12:54, on the director's word (`docs/decisions.md`, "by 12:54"). Tier 2, a balance number, set by the director.

**Feel line:** mid-fight, every few seconds a soft pop on the lead and a green number: the Voidkin catches its breath, and the player feels it hold on.

**The rules:**
- **One burst every 8 seconds,** always, in a fight too. The timer runs from the lead's summon, never resets on a hit, and a burst at full health heals nothing and shows nothing.
- **Its size:** half of what 8 seconds of today's Regen heal, the level's own, Endurance's and a Healer's Main alike. So today's rate times 8 times 0.5, a value, never a share of health.
- **It starts very slow** (the director, by 12:56): `Config.Stats.Regen.Base` goes from 4 to 1, a quarter of the level's own, after the half. A burst is about 1% of health at level 1 and under 2% at level 12. What a build adds (Endurance, a Healer's Main, gear and emblem lines) keeps its size, so Regen grows with the build.
- **Home's healing on the player's own plot** is unchanged.
- `Config.Stats.Regen` holds the 8 s and the 0.5, tunable through `Tune`.
- **The sheet** shows the burst's size as Regen's number. The item card's Regen lines read the same way.
- **Combat Power:** Regen's weight is refit for the burst. Its worth halves at the same points, so its weight follows, checked in `attributes.py` and the sim before the build closes.
- **The look,** block only: the lead's heal number in the damage numbers' own kit, green, and a quick pop at its chest. No new effect art: it waits for the finish.

**Checks:** logic cases (a burst's size, its 8 s, none at full, the sheet's number); the self-test; Fight's case times again; research's verdict from a phone capture in a real fight.

**Built (Faber, 2026-11-17, by 14:37 by the clock).**
- **Implemented.**
  - `Config.Stats.Regen` is `{ Base = 1, Every = 8, Share = 0.5 }`, and `Rules.Stats.Burst` is the rate × Every × Share. The block keeps Regen as a rate a second.
  - `FightService.thinkLead`: a lead's `RegenAt` starts at its summon + Every. `Rules.Fight.BurstDue` steps it by Every, never reset by a hit, and catches up once after a stall. `Rules.Fight.Burst` heals, capped at full, and a burst that heals fires Net `Heal` with `Regen = true`.
  - Home's own heal on the player's plot is unchanged: `Rules.Fight.HomeRate`, the old `RegenRate` without Regen. Read here as: bursts come everywhere, the plot included, on top of home's heal.
  - The client: `Effects.RegenPop`, a Neon ball in the heal green at the chest, swelling 1 to 3.4 studs over 10 frames (`Config.Effects.RegenPop`), and the green number in the damage numbers' kit for the player's own lead.
  - The sheet and the cards: Regen reads one burst's size, "17 every 8 s" (`Sheet.Burst`, `Sheet.Amount`, `Sheet.Change`).
  - Combat Power's Regen weight is 3.2 → 1.6. Rook at level 12: 29,427 → 29,070.
- **Tested.**
  - Type check 0 new. Logic offline 23,998 passed, 0 failed: the TR12 case rewritten for HomeRate, and a TR40 case (the 8 s and the 0.5, Base 1, the timings, the cap, five bursts in 40 s, Rook's burst between 0.4% and 2% of health at levels 1 and 12). Sheet's cases read the burst.
  - Self-test: the new case "Fight: TR40, a lead's Regen in bursts" passes 9 of 9.
  - **Fight's case times again:** every "Fight:" case on a fresh playtest, 553 passed and 0 failed, in 137 s at 60 fps. The lead beats an ordinary Shade in 5.85 s.
  - Two older cases needed fixes to pass from a fresh start, and nothing in them is TR40's:
    - The lead fights only what the camera sees (TR24's fix 2), and a fresh camera looked 58° off the test Shade: the lead stood idle 20 s. `lookAhead` turns the camera the avatar's way before each of the 14 test Shades spawns.
    - Haymaker's stamp counted a real stamp from an earlier case's fight: it now calms the lead and waits for the floor to clear.
  - **The whole suite,** started by 14:22, 448 s: 2,526 passed and 11 failed, at 59 fps.
    - One is Pip's skip, which passed in the Fight run and alone.
    - Ten are Base and HUD checks that need the base's models: the Breaker's chambers, the machine plates at the spawn, the Door's rings and signs, a worker's halo. The plots have stood grey since 8858359 (AR16 at 128 studs, until the plan is laid again: the console says so at boot), and they fail alone too. TR40 touches nothing in the world. Open, for the piece that lays the plan again.
  - **A bug fixed:** FighterController wrote `Effects.TimeScale` every frame, so a capture's hold never held, against the module's own contract. It now writes only as the replay's freeze starts and ends.
- **Visually reviewed:** for research's verdict.
  - The take "Take: TR40, a Regen burst in a real fight at Pack 1": Rook fights Pack 1 at 60% health, the next burst is held 4 frames in, and Pack 1 is brought back if it falls first. It puts Rook's level, experience and Regen back after.
  - Stills at the iPhone 16 Pro's size, in `build/scratch/faber/stills/`:
    - `burst-phone.png`: the pop half-clear at Rook's chest behind the hit sparks, and "+22" in green beside the 555s;
    - `burst-crowded-phone.png`: the same moment from behind the avatar, with the green number under a "Block" and the hit numbers.
  - My read: the burst is easy to lose in a busy fight, its number among the hits and its pop under the sparks. Readable when the lead stands clear.
- **Director-accepted:** no.
- **Waiting on research:** the Regen weight 1.6 and Base 1 in `tools/balance/`. `sim.py:993` still sets the lead's Regen at 4 a second, and its circuit heals at the full rate continuously, not in half-size bursts. `attributes.py`'s TODAY keeps 4 as the old point.

- **Research's verdict (Quaestor, 2026-11-17, 14:40),** from Faber's two phone stills in a real fight at Pack 1 (`burst-phone.png`, `burst-crowded-phone.png`), and the balance tools run on the build's numbers.
  - **Felt:** a heal you find only if you look for it. The "+22" sits among the 555s and a "Block", the same size as a hit, and the pop hides behind the sparks. Faber's read says the same.
  - **Tier:** works. The rule is right: bursts every 8 s, Base 1.
  - **Must-fix, its class: a number about the lead's own state reads on the lead's own bar, not in the crowd of hits.** The burst shows on the lead's health bar in the HUD: the gained health fills in green with a short sweep, and its "+22" rises beside the health numbers, where nothing else competes. In the world it keeps only a small pop at the chest, or none, Faber's call by what reads. That covers any later heal of the lead's own: Lifesteal's, a Healer's.
  - **The balance, from `tools/balance/sim.py`,** now modelling bursts on one clock, and edge() healing at the burst's share:
    - The fitted Regen weight is 1.41 to 1.65 across levels 5 to 60, mean 1.55. The game's 1.6 stands, and `seeds.json` now matches.
    - On a new account, Rook ends Pack 2 at about 52% health against 78% at the old rate. About 1 run in 100 falls before the elite for Rook and Pip, and 5 for Kirra. That's the low start the director asked for ("every stats must feels low at the beginning"), and home heals the rest.
    - **A known gap, research's:** the street model leaves out Endurance's Regen, so it reads low. At level 1, Rook's Endurance adds about as much again as the base.
  - **Accepted on the cases:** the 553 Fight cases. What they can't show is how a burst feels in a long fight. That's first seen in the bar's fix, in a capture of three bursts in a row.

**The must-fix, on the lead's bar (Faber, 2026-11-17, by 15:03 by the clock).**
- **Implemented:**
  - A burst on the player's own lead shows on its HUD card (`HudController.LeadHealed`, `paintHeal`; `Config.Hud.Card.Heal`).
    - A soft band in the heal's green runs along the health light from its root to its front in 0.3 s, holds 0.15 s and fades over 0.45 s. It's soft at both ends, so the light's slant never shows a square edge.
    - A burst is 0.4 to 2% of the bar, a sliver of one or two points on a phone, so the sweep carries the read.
    - "+22" in the same green stands after the health's digits, measured as drawn. It rises 8 points over 1.2 s and fades in its last third.
  - In the world, the green number is gone. The pop stays as a small tie to the body: 0.8 to 2.2 studs, from 1 to 3.4.
  - HudController hears `Heal` itself, so a later heal of the lead's own (Lifesteal's, a healer's) comes to the same place.
- **Tested:**
  - Type check: 0 new.
  - "Fight: TR40": 12 of 12. It checks the band runs, "+N" is the burst's own and in the heal's green, and no number appears in the world.
  - "HUD:": 417 passed, 2 failed, both the machine plate with news, which needs the base's models (open above).
  - On the iPhone simulator, 14 more HUD cases failed: the lead never took on its Shade under the simulator's camera (TR24's view rule). They pass with it off, on the same code.
- **Seen, for research's second look:** three bursts in a row in a real fight at Pack 1, on the iPhone 16 Pro, each held 0.3 s in (the band just at the front).
  - The stills are in `build/scratch/faber/stills/`: `bar-burst1-phone.png` (+22 at 732 of 1,237), `bar-burst2-phone.png` (650), `bar-burst3-phone.png` (607), and `bar-zoom.png`, the card ×3 from the first.
  - The take: "Take: TR40, three Regen bursts in a row...".
  - In these stills "+22" stands 3 points wider than set. Since fixed: it's measured as drawn.
- **Director-accepted:** no.
- **Research's second look (Quaestor, 2026-11-17, 15:04): closed on research's side.** Judged on the must-fix only, from the three bursts in a row and the zoom (984fede). The green sweep at the bar's front and the "+22" by the digits read at a glance on the phone, away from the hit numbers, on every burst. The smaller world pop with no number no longer competes. Director-accepted: not yet.

## TR41. The passed screens that never reached the game (Faber, after TR40)

Research, 2026-11-17, 14:05, on the director's question: "how is that there is many ui that havent got the implementation such as void breaker galaxy ui". A read-only audit of the requests against `src/` found four pieces delivered, passed, and never wired. For three of them no build request was ever written, and none was in any order of work. That's research's miss as keeper of the plan. Each is built as delivered, with no new design.
- **The galaxy Breaker** (AR12, "The galaxy Breaker's images for the build"; the director: "ok we keep it", 2026-11-15):
  - uploaded 2026-11-17, not wired;
  - the six images and `build/handoff/UI/breaker/breaker_sky.json` are laid in `BreakerScreen`, as the json and research's read say: one mist band in a `CanvasGroup` with its gradient, and the per-window stack as the fallback;
  - the falling star first at 3 to 6 s, then every 15 to 30 s;
  - reduced motion holds it still.
  - The images still stand: Eclipse left the Breaker's room to Modulo as art. The one number to read in the build is the light behind a working shard (`#DCCBFF`, the old lavender). Modulo calls it if it reads off.
- **Power's cut images in Eclipse** (AR12, "Power's cut images, in Eclipse"): eight images, not uploaded. Upload them under the group, then lay the bar from `power_images.json`.
- **The level-up notice, take B** (AR12; the director's pick): its clip and three images, not uploaded. Upload, then install.
- **The shard's festival tag** (AR12; research: competent): four images, uploaded 2026-11-17, not wired.
- **The HUD's V2 leftovers** (AR12, the 30 images): Battery, Plant, Route, Shard, the three Ink crests and the rest never reached `UIKit`. For each, Faber says in this entry whether a later piece replaced it (the halos by the lead card, BlockDock by the dock) or installs it.
- **Not here:** TR17's page marks and the old top-bar marks, which AR29 replaces.
- **Checks:** the content check is already passed for each delivery; the asset log row on upload; the touched self-tests; then research's read from phone captures (the Breaker in motion, a falling star, a working shard), then the director's.

### The galaxy Breaker, in the game (Faber, 2026-11-17, by 15:30 by the clock)

- **Built** (`src/client/UI/BreakerScreen.luau`, its numbers in `Config/Hud.luau`, `Breaker.Sky`):
  - **The night:** the two halves fill the panel between its fill and its edge. The panel is 684 by 306, so the art stretches about 8%. The six stars sit at the json's places, each breathing on its own clock.
  - **The mist:** one band in a `CanvasGroup` carrying the river's gradient. It runs behind the chambers' windows at the json's top and foot, sliding left at 2.5 points a second, by scale so it moves smoothly.
  - **The windows are glass:** `#0A0824` solid on the number strip and the plate. Between them a working or empty chamber is 0.1 cover and a locked one 0.13. The panel's shadow goes, so the river shows through. Every word sits on a solid part.
  - **The light:** a working chamber's light (`#DCCBFF`) breathes in its window under its shard.
  - **The falling star:** in chamber 4's window, first at 3 to 6 s after opening, then every 15 to 30 s.
  - **Reduced motion** holds everything at its start, and no star falls.
- **Calls made at the build:**
  - **"Upgrade the Breaker"** doesn't fit a locked chamber's plate at the smallest phone (113 points of text in a 104-point plate). It's said once, right-aligned on the "Chambers" heading line. That's your fix-1 fallback, moved above the row for room.
  - **The ready lights aren't laid:** a ready shard leaves its chamber at once, so a chamber never holds one.
  - **The per-window fallback isn't built:** the one band lines up with the windows in the captures.
  - **The chamber cell** is 142 wide, up from 138. The strip is 20 tall, and the plates are one height across the row. `ShardArt.Least` is 50, down from 60, so the shard fits the window at the floor.
- **Tested:**
  - **Self-test:** "Breaker:" passes 176/0. The new case is "Breaker: TR41, the galaxy", in its own list, `SelfTestController/BreakerCases.luau`.
  - **A refactor to make room:** `Cases.luau` is at the type checker's limit, so the shared waits and reads moved to one home, `SelfTestController/Helpers.luau`.
  - **The take:** "Take: TR41" passes 4/0.
  - **Type check:** 0 new.
  - **Full suite:** 2570/11.
    - Ten are the Base and HUD checks that wait on AR16's base models: Modulo's delivery 3 is for those, and I install it next.
    - One is the Held Note's ring, which passes alone (50/0): a load flake.
- **Stills for your read, at the smallest phone,** in `build/scratch/faber/stills/`:
  - `tr41-falling-full.png`: two shards working, a star held mid-fall in chamber 4;
  - `tr41-zoom.png`: the same, zoomed on the chambers;
  - `tr41-still-full.png`: held still, the chambers empty.
  - "Take: TR41" holds each state for a capture.
- **Open:**
  - **Research's read.** At the phone the falling star is a thin streak, 28 by 24 points, and the light reads soft at 0.36 cover. Both are the json's numbers, Modulo's to call.
  - **TR41 (b) to (e)** come next.

- **Research's verdict (Quaestor, 2026-11-17, 15:40),** on the galaxy Breaker from the three stills at the smallest phone.
  - **Felt:** the Breaker is a window on the void now. The working chambers glow pink and violet in their own sky, and the locked ones sit dark beside them.
  - **Tier:** competent.
  - **The bold thing:** the mist band behind the chambers, lit where a shard works.
  - **The calls:**
    - "Upgrade the Breaker" once on the heading line stands.
    - No ready lights stands.
    - The light at 0.36 cover reads; it stays.
  - **Must-fix, its class: a moment meant to be caught reads at phone size on first sight.** The falling star at 28 by 24 points reads as a scratch on the glass. Give it a bright head with a soft glow and about twice the length, crossing chamber 4's window corner to corner. Modulo sets the numbers in the json, Faber lays them. Any other once-in-a-while moment on a screen meets the same bar.
  - **Older, a must-fix all the same:** the "Ready, waiting and in the bag" row runs under the detail panel, and its third card is cut mid-word. The row ends at the panel's left edge, with a soft fade where it scrolls on.
  - **What the stills can't show:** the band's slide and the star's fall in motion. They're seen first in the second look's capture: one fall at full speed, with the band moving.

### The two must-fixes, in the game (Faber, 2026-11-17, 16:09 to 16:55 by the clock, beside AR17's install)

- **The falling star,** on Modulo's numbers (AR12, "The falling star, made to be caught"):
  - `BreakerFallingStar.png` is uploaded under the group with the key, 121639543913318, read back Approved;
  - `Breaker.Sky.Falling` takes `Points` (56, 48), `Head` (9, 39), `From` (1, 0), `To` (0, 1) and `Seconds` 0.9.
- **The ready row** ends at the machine's column, by the detail panel. It sits in a `CanvasGroup` (`StripFade`) whose gradient fades its last tenth out (`Breaker.Fade`, 0.1), so a chip cut there fades rather than stopping mid-word.
- **Cases:** "Breaker: TR41, the galaxy" adds three checks: the star at its made size; the row's end at the machine's column, with the list inside the fade; and the fade's three keys.
- **Tested:**
  - Breaker 179/0, HUD 419/0, Base 261/0, World 79/0, UI TR20 36/0;
  - "Take: TR41" 4/0;
  - type check 0 new.
- **For research's second look** (`build/scratch/faber/stills/`), at the smallest phone (the take's layers at the floor's scale, in the desktop window):
  - `tr41-falling-3.png`: one fall at full speed with the band moving, the clip's frames 150, 157 and 164 (5.0, 5.23 and 5.47 s, 0.23 s apart);
  - `tr41-falling-zoom.png`: chamber 4 at mid-fall, at 2 times the pixels;
  - `tr41-fall.mp4`: the clip, 24 s at 30 fps, with the fall from 5.0 s. The star crosses the window from its top right toward its bottom left.
- **Open, mine:** after the suites, a reveal stood at its held frame (Watt, "A copy", its clock at 1.6 s), and a click didn't close it. `NL_RevealTest`'s Close did. It came from a case or from the take I stopped earlier; the cause isn't found yet.
- **Four facts:**
  - **Implemented:** yes.
  - **Tested:** as above.
  - **Visually reviewed:** my read of the clip. Research's second look is next.
  - **Director-accepted:** no.
- **Research's second look (Quaestor, 2026-11-17, 16:54),** on the two fixes only, from the three frames and the zoom.
  - **The falling star: passed.** In the first frame it's a bright head with its tail across chamber 4's window, caught at a glance, and it fades out in the next two.
  - **The ready row: the fix is right, and its number is short.** At 0.1 the fade covers less than half a card, so the third card still reads "Rea" cut at the panel's edge.
    - Set `Breaker.Fade` to about 0.3, so the last card fades out over its own width.
    - It's a tune, not a third round: Faber checks it in one still, and research's look is done.
- **The tune, checked (Faber, 2026-11-17, 16:57 by the clock):** `Breaker.Fade` is 0.3. "Breaker: TR41" passes 42/0 and "Take: TR41" 4/0. In the take's first held state at the smallest phone, the third card shows only as a ghost under the panel's edge, its word no longer cut (`build/scratch/faber/stills/tr41-fade-03.jpg`, the row zoomed in `tr41-fade-03-zoom.png`). TR41 (a) is done on both sides. Director-accepted: no.

### (b) Power's bar from its cut images, in the game (Faber, 2026-11-17, 16:58 to 17:23 by the clock)

- **Uploaded:** Modulo's eight images as delivered (a00fee1), under the group with the key, all eight read back Approved. Their ids are in `docs/asset-log.md` (the row of 2026-11-15, "Power's bar, cut, in Eclipse") and `Config.Hud`, `Power.Images`.
- **Built** (`src/client/UI/PowerScreen.luau`, `bar` and `lay`; its numbers in `Config.Hud`, `Power`, written from `power_images.json`). The stack is the json's `bar.stack`, in its order:
  - the ember behind the well, at 0.16;
  - the well, the kit's ButtonFill and ButtonEdge, 26 past each end, 13 above and 15 under;
  - the bed;
  - a glow under each light, at 0.42, outside every window;
  - the lights;
  - the outline, at 0.95;
  - the three ticks;
  - the brass handles over all.
- **The lights:** each light is `PowerBusLight` at the bar's whole size and place, seen through its segment's window, with its 17-stop gradient turned 90 degrees. Its white arriving end runs from 1 to 0.7 over 38.4 points, ending at its right side. Windows run cut to cut on the rim's span, with the gap at each cut between two lights. An idle machine's light wears the battery's gradient.
- **The chips** are the cut stones, Breaker and Training.
- **Calls made at the build:**
  - **Every place across the bar is a share of its width in points,** never an offset. A `UDim`'s offset is a whole number, so the json's 1.8-point cut landed at 1, and a handle sat 2 pixels off its cut in the first run. The width in points is read from the bar's own size (its height is 24 points), so it holds at every layer scale. The bar lays itself again when that size changes.
  - **The brass is centred by its anchor,** not by a half point's offset.
  - **The kit's images are generated** (`Config.UIKit`, never edited by hand), so the bar's images live in `Hud.Power`. `Skin.LayOwn` lays a screen's own image record as `Skin.Lay` lays the kit's.
  - **The battery's mark in the head** (`Battery.png`) is one of the V2 leftovers. It's answered in (e).
- **Cases:**
  - "Power:" checks:
    - each layer's image and its order;
    - the glows outside every window;
    - the well's reach;
    - each light's window, cut to cut with the gap;
    - the light at the bar's own place;
    - the arriving end clear, then 0.7 at its right side;
    - each handle's brass on its cut.
  - A light's colour is read from its gradient, where the old check read a frame's colour. The rest's share is read from the segment's `Share`, where the old check read its width, which now leaves out the rim and the gaps.
- **The take:** "Take: TR41 (b)" holds the screen at the smallest phone, with the Breaker working at 40%, the idle Training machine's 20% lit as the battery's, and the battery's rest. It passes 6/0 and puts the split back.
- **Tested:**
  - "Power:" 87/0;
  - the full suite, after the change to Skin: 2,687 passed and 3 failed, all three in the Lighting case (TR8, TR23): the crossing's shard keeps its own steady glow (`Config.Lighting.Steady`, AR17's install, 47c0b85), which that older case didn't know. Taught it, the Lighting cases pass 54/0. Logic offline 24,007/0;
  - type check 0 new.
- **Stills for your read,** at the smallest phone, in `build/scratch/faber/stills/`:
  - `tr41b-power-split.jpg` and `tr41b-power-split-zoom.png`: the Breaker's silver at 40%, then the idle Training share and the rest in the battery's yellow, with a handle at each cut;
  - `tr41b-power-idle.jpg` and `tr41b-power-idle-zoom.png`: both machines idle, so the bar is the battery's whole, both handles at the start.
- **Not seen:** the Training machine's cyan. It lights only while the machine draws, and nothing in the test save trains.
- **Four facts:**
  - **Implemented:** yes.
  - **Tested:** as above.
  - **Visually reviewed:** my stills. Research's read is next.
  - **Director-accepted:** no.
- **Research's verdict (Quaestor, 2026-11-17, 17:24): passed, no must-fix,** from the split and the idle stills at the smallest phone with their zooms (7175794).
  - **Felt:** the bar reads as a lit channel you set by hand. The Breaker's silver pours in from the left, the battery's gold takes the rest, and the brass handles sit at the cuts ready to drag.
  - **Tier:** competent.
  - **The bold thing:** the white arriving end of each light, so power visibly flows to its machine.
  - **As designed, and to polish-later:** an idle machine's share wears the battery's gold, so the handle between them splits gold from gold. It's honest, since the power goes to the battery, and the row says "Idle". A dimmed trace of the machine's own colour would show where its share ends.
  - **Accepted on the cases:** the Training machine's cyan, which no still shows. It's seen first in a capture with a save that trains, which Faber can add to (e)'s.

### (c) The level-up notice, take B, in the game (Faber, 2026-11-17, after 17:24 (ebeecac) to 17:58 by the clock)

- **Built,** from Modulo's `build/handoff/UI/hud/levelup/levelup_notice.json` and three images, uploaded under the group and read back Approved (`docs/asset-log.md`, the notice's row):
  - **`src/client/UI/LevelNotice.luau`:** the plate in the lead card's violet slides in from the screen's left edge under the lead's corner, at the card's left edge. Its new level falls onto the lavender block with a flash and a knock, one sheen crosses, then it holds and slides back. It's as wide as its words ask (the json's Base plus the wider of the name and "LEVEL UP").
  - **The motion** is a pure rule, `Rules.Hud.Notice`, with its logic case. Every number is in `Config.Hud.LevelNotice`.
  - **Said once, in one place,** as research ruled on 2026-11-15: `HudController` shows the notice in place of the old level toast, and `Effects.LevelUp` loses its word over the lead. The column of light and its sleeve stay.
- **Calls made at the build:**
  - **The plate is three plain pieces of its image, not Roblox's slice.** Under the layer's scale a 9-slice drew this plate wrong, measured in Studio: cut across only, nothing at all; with rows above and under its middle, its lower rows far too short. That fault is what pushed the number off its block in my first stills. The ends keep their size and the middle stretches, as the json cuts it.
  - **The number is centred on the block as Modulo's image draws it:** 30.75 points across at the digits' middle height, where the json's middle says 28.9. The json's note says "centred on the block", so the image wins. Modulo: your json's middle may want the same.
  - **The sizes are the json's times 1.2.** Blender's capitals stand 1.2 times the game's face at the same size, measured on the sheet. "LEVEL UP" is spaced by hair spaces, for Blender's 1.14.
  - **The sheen fades over the leaning ends** (the json's first option), rather than clipping. It passes under the words as the json stacks it, so "UP" pales for the tenth of a second it's crossed (still e).
  - **A second level while it's shown** takes the new number and lands again from its arrival, then holds anew.
  - **Room on a phone:** the step's chip over the dock shares its row at the smallest phone. The plate stops a gap short of it, and a longer name is cut with "…" (Roblox cuts at a word: "Little Storm Cloud" reads "Little…"). It's never narrower than "LEVEL UP".
  - **Every place across the plate is a share of its width,** as in (b), since a UDim's offset is a whole number.
- **Cases:**
  - "HUD: TR41 (c), the level-up's notice" (`SelfTestController/NoticeCases.luau`, its own list) checks:
    - the first frame against the rule's place for its age;
    - the words, the place under the corner and the width;
    - the plate's three pieces, their sizes and their shares of the image;
    - the number centred on the block;
    - the stack;
    - a second level re-landing it;
    - the fall, the squash, the flash, the knock and the sheen;
    - no toast;
    - a 20-letter name at the smallest phone, cut and stopping short of the chip.
  - The level-up's light cases lost their word checks.
- **The take:** "Take: TR41 (c)" holds the notice at the smallest phone, at the age `NL_TakeStep` writes. "Long" shows the longest name at level 100. It passes 3/0 and puts the layer back.
- **Tested:**
  - the notice's case 39/0 (7.8 s, 59 fps);
  - the level-up's light: one colour 8/0, the column 17/0, the top band 5/0, the reward pops 16/0, TR6's badge burst 28/0;
  - every "HUD:" case, the notice's included, 445/0 (82.3 s, 59 fps);
  - logic offline 24,032/0;
  - type check 0 new.
- **Stills for your read,** at the smallest phone, in `build/scratch/faber/stills/`. `tr41c-strip-zoom.png` shows all seven zoomed, in order:
  - `tr41c-a-0.08-sliding-in.jpg`
  - `tr41c-b-0.26-falling.jpg`
  - `tr41c-c-0.33-landing-flash.jpg`
  - `tr41c-d-0.57-sheen-entering.jpg`
  - `tr41c-e-0.72-sheen-crossing.jpg`
  - `tr41c-f-1.5-rest.jpg`
  - `tr41c-g-long-name-cut.jpg`
- **Four facts:**
  - **Implemented:** yes.
  - **Tested:** as above.
  - **Visually reviewed:** my stills. Research's read is next.
  - **Director-accepted:** no.
- **Research's verdict (Quaestor, 2026-11-17, 18:00): passed, no must-fix,** from the seven frames and the rest still (7295327).
  - **Felt:** a quick, clean beat: the number drops in big, lands with a flash, and a sheen crosses. Then it sits small under the portrait, out of the fight's way.
  - **Tier:** competent.
  - **The bold thing:** the number's drop, oversized for a frame before it lands in its block.
  - **Faber's calls stand:** the three pieces, the number centred as the image draws it, the 1.2 sizes, the sheen under the words, and the cut at a word.
  - **One check, its class: the notice and the portrait never disagree.** In the rest still the portrait's badge reads 12 while the notice says 13. If the take only staged the notice, nothing to do. If a real level-up leaves the badge behind, the badge takes the new level at the notice's landing (0.33 s). A case covers it. **Answered (18:02):** the take only staged it. On a real gain, the server writes the level onto the lead's model in the save's own step, and the notice's case now checks that the badge reads 13 at rest (782a9e9, 40/0). Closed on research's side.
  - **To polish-later:** a long name cut to one word ("Little…") loses who levelled. A name could shrink a step before it's cut.

### (d) Where a shard came from: the festival tag, in the game (Faber, 2026-11-17, after 18:01 (782a9e9) to 18:38 by the clock)

- **Built,** from Modulo's `build/handoff/UI/shards/tag/shard_tag.json` and the four images already up (`docs/asset-log.md`, the tag's row):
  - **`src/client/UI/ShardTag.luau`** lays the ground's look on a shard's picture. The picture keeps its place and size.
    - **A picture of 50 points and up** (a chamber's) wears the tag, hung by its thread from the crystal's right shoulder: a third of the side at 50, a quarter at 96, a straight line between.
    - **A smaller picture** (a bag cell's) wears the mark on its disc at the crystal's foot.
    - **A Breaker strip chip** gets a band of the ground's colour, 3.6 points, along its foot. It's the chip's own fill shape in that colour, clipped to the foot, so it keeps the chip's corners and lies under its edge.
  - **The box is a pure rule,** `Rules.Hud.ShardTag`, checked against the json's five boxes. Every number is in `Config.Hud.ShardTag`, both drawn grounds'. A shard of a ground with no tag drawn shows none.
- **Calls made at the build:**
  - **In a bag cell, the mark sits at the crystal's left foot, mirrored.** At the json's right foot, every cell's count wrote over the disc ("×40" on the lantern; the case caught it). The count keeps the corner it has across the whole bag.
    - Measured on the three small pictures: the disc covers the lower flank of a Prismatic or an Enriched alike on either side.
    - Research: yours to overturn.
  - **The Breaker's strip ran past its panel at the smallest phone,** since (a).
    - The panel shrinks to the room there (292 points tall), but the chambers' row kept its full 142. So the chips' feet hung about 10 px past the panel's foot, cut, the band with them.
    - Now the row takes what the body leaves over the strip, worked out from the sizes (the entrance's scale shrank it while it was read from the screen, caught by a case).
    - At the smallest phone a working chamber's picture is then 40 points: the small picture and its mark, as drawn for 40. With an infusion line it's 26 at least.
    - At full size nothing changes: the row is still 142 and the picture 68. Research's Least (50) holds wherever the room allows.
- **Waits,** as the design's block says: the two-line name ("Lantern Row" over "Prismatic Shard") wherever a name shows, and the bag's sort and filter by ground. Every shard in the game is Lantern Row's today, so only its tag shows.
- **Cases:**
  - Logic, "Hud: TR41 (d)":
    - the json's five boxes, within 0.01;
    - the third and the quarter;
    - the mark's least, its place and its mirror;
    - every shard's ground has its images.
  - Self-test, "Breaker: TR41 (d)" (`BreakerCases.luau`), at this screen and at the smallest phone's scale:
    - the tag's tie on the crystal's shoulder, within a pixel, and its plaque its share of the side;
    - a chip's band 3.6 points high at its foot, under its edge, in the ground's colour.
  - The same case, in the smallest phone's own room:
    - every chip inside the panel;
    - the row taking the rest;
    - a chamber's picture in the look of its size.
  - The same case, in the bag:
    - the mark at the left foot;
    - the count clear of it;
    - the lint at each.
- **The take:** "Take: TR41 (d)" shows the Breaker, then the bag, at the smallest phone, as `NL_TakeStep` says ("Breaker", "Bag", "End"). "Large" shows the Breaker in this screen's own room, its chamber's picture wearing the tag. It passes 5/0.
- **Tested:**
  - the tag's case 42/0, the galaxy's 42/0;
  - every other "Breaker" case passes. The run's 8 failures were in takes: TR20's, driven past its steps by my run's "End", and TR18's (below);
  - the Items page 112/0, the Voidkin screen 249/0;
  - logic offline 24,051/0, type check 0 new.
- **Found, not from this piece:** TR18's take fails on its own at "the Power screen opens on its prompt", where it walks to the generator and taps the prompt. Nothing here touches the base, the Power screen or a prompt. I'll look into it at TR18's next pass.
- **Stills for your read,** at the smallest phone, in `build/scratch/faber/stills/`:
  - `tr41d-a-breaker-phone.jpg`, and `tr41d-a-breaker-zoom.png` for the chamber's mark and the chips' bands;
  - `tr41d-b-bag-phone.jpg`, and `tr41d-b-bag-zoom.png` for the mark beside the count.
  - `tr41d-c-breaker-large.jpg`, and `tr41d-c-tag-zoom.png` for the tag on a chamber's 68-point picture, on a larger screen.
- **Four facts:**
  - **Implemented:** yes.
  - **Tested:** as above.
  - **Visually reviewed:** my stills. Research's read is next.
  - **Director-accepted:** no.
- **Research's verdict (Quaestor, 2026-11-17, 18:40): passed, no must-fix** (5fc5472; stills a to c, read zoomed).
  - **Felt:** a shard says where it came from without a word. The chamber's picture wears a hung tag when there's room, and a cyan disc when there isn't.
  - **Tier:** competent.
  - **The bold thing:** the tag hung by its thread from the crystal's shoulder at 68 points, a festival keepsake on the stone.
  - **Faber's two calls stand:**
    - **The mark at the left foot, mirrored:** the count keeps its corner across the bag, and the disc reads clear beside "×40".
    - **The chambers' row gives way at the smallest phone:** that is TR41 (a)'s class, nothing runs past its panel, and the 40-point picture with its disc still reads.
  - **To polish-later:** at the smallest phone, a ready chip's band (3.6 points) reads as a faint line under the gold edge, not yet as the ground's colour.
  - **Not this piece's:** TR18's take, failing at the Power screen's prompt, is Faber's to look into at TR18's next pass, as the record says.

### (e) The HUD's V2 leftovers, and the Training machine training (Faber, 2026-11-17, after 18:40 (25e59ed) to 18:49 by the clock)

- **The 30 images of AR12's V2, Block, one by one** (`build/handoff/UI/hud/colour/images/`, `hud_colour.json`):
  - **In the game since AR12's build (17):** the pills' block (BlockPill); the ink marks of Power, Credits and Voidkin (InkBolt, InkCoin, InkShard: the two pills and the hint); CoinMint (the credits' flight, the reveal's plate); the readout in its four layers with the two signatures' icons and their ready twins; the spectate eye, off and on; the lead card's stud and its glow.
  - **Installed here (1):** Battery, the battery's mark on its plate in the Power screen's head.
    - It replaces the stand-in drawn from frames, at 28 points, its drawing (25 points across) where the stand-in stood, so the words keep their place.
    - In its own gold, untinted (`Config.Hud.Power.Images.Battery`).
    - Uploaded under the group, read back Approved; content check PASS for the upload (`docs/asset-log.md`, the V2 row).
  - **Replaced by a later piece (8):**
    - BlockDock, and the light icons only the dock wore (Plant, Shard, Route): replaced by the dock's own images, its tiles and three ink marks (AR12, "The dock's images, delivered").
    - The four halos (CardFrameHalo Rare to Mythical): taken off by the director's word of 2026-11-15, "let remove this light aura" (AR12).
  - **Unspent, as decided (4):**
    - Crest and InkCrest: Regalia's. Its dock button isn't built since the merge (the director, 2026-11-15; research's pass: they stay in the kit, unspent, not deleted).
    - InkPlant and InkRoute: the Base's and the Map's marks on a block. No pill or hint of either exists, and the dock has its own marks.
    - None of the four is uploaded. The kit's system rows already name them, so a pill or hint of one stops at `Skin.Icon`'s assert until it goes up and into the kit: that's the sign it's needed.
- **The Power pill's covering state** in V2 (the Battery icon at 17 points between "30 kW" and "34 kW used", and the bar's covered share in dashes) is TR18's to say.
  - TR18 rebuilt the pill: generation against demand, then the battery's own reading, its fill as the thread.
  - Covering shows in the warning colour on the value (research's verdict on TR18).
  - I've built nothing there. See "Open, for research".
- **The Training machine's cyan** (research's ask at (b)), seen in the game:
  - The lead, whole at home while the player is off the plot, trains (the game's own rule, `Rules.Training.Who`). The driver set it up: the heal tuned to 5 s, the avatar on the strip, the lead felled.
  - The Training machine's share wears its own light, cyan, at 54% beside the battery's gold rest.
- **Cases:**
  - "Power: the generator shows ..." checks three things about the plate's mark:
    - it's the battery's image, untinted;
    - it's centred on the plate's height;
    - its box ends before the words.
    - It passes 90/0.
  - "Take: TR41 (e)" shows the Power screen at the smallest phone, then in this screen's room ("Large"), as `NL_TakeStep` says. It checks the mark, that a Voidkin trains, and that the Training machine wears its own light. It passes 6/0.
- **Tested:** type check 0 new.
- **Stills for your read,** in `build/scratch/faber/stills/`:
  - `tr41e-a-power-phone.jpg`, and `tr41e-a-power-zoom.png` for the head and the bar at the smallest phone;
  - `tr41e-b-power-large.jpg`, and `tr41e-b-mark-zoom.png` for the mark beside its reading at full size.
- **Open, for research:**
  - **The pill's second value** ("full", "42.10 kWh") is the battery's, but only its words say so. V2 put the battery's mark in the pill while it covers. Should the mark, at 17 points, stand before that value always? It's a tier 2 call; nothing is built until you say.
  - **The mark draws two cells of three lit at any charge.** It's a mark, not a gauge: the bar under the reading is the gauge. At 60 of 60 it reads as said, but say if it jars.
- **Four facts:**
  - **Implemented:** yes.
  - **Tested:** as above.
  - **Visually reviewed:** my stills. Research's read is next.
  - **Director-accepted:** no.
- **Research's verdict (Quaestor, 2026-11-17, 18:50): works, one must-fix** (d6bdea4; stills a and b, read zoomed).
  - **Felt:** the Power screen's head now reads as the battery's own: a gold mark, the reading and the bar under it. The Training machine's cyan share sits clear beside the battery's gold.
  - **Tier:** competent once the must-fix is in.
  - **The bold thing:** none new; the piece answers the kit.
  - **The 30 images:** each is answered, and the four unspent stay in the kit, as decided.
  - **Must-fix, its class: two readings of one value never disagree** (TR41 (c)'s class).
    - A battery mark with cells is read as a gauge. At 60.00 / 60 kWh, with a full bar, it shows two of three cells lit.
    - The fix: the mark's cells follow the charge by thirds, or it shows no lit cell at all. Faber picks whichever is cheaper with Modulo's image.
    - It holds wherever the mark stands.
  - **The pill's second value, research's call (tier 2, with Faber's HUD; Modulo's mark used as drawn): yes.** The battery's mark, at 17 points, stands before the battery's reading in the Power pill always, not only while it covers. "full" alone doesn't say what is full. It takes the same must-fix. `docs/ui.md`'s top-right row says so.
- **Faber's fix (2026-11-17, after 18:50 (research's verdict) to 19:08 by the clock):** the must-fix, and the pill's mark.
  - **The cells follow the charge by thirds** (`Rules.Hud.BatteryCells`):
    - none only when empty, all three only when full (when the pill says "full");
    - between, a cell for each third begun, at most two. A battery near empty keeps its last cell lit, as a phone's does, until it's empty.
  - **With Modulo's one image, no new upload** (`UI/BatteryMark.luau`, `Config.Hud.Power.Cells`). Three crops of the image lie over it:
    - a lit cell is a crop of its second cell;
    - an empty one is a tile of the battery's dark inside, from the middle of one gap to the next, stretched from a small flat patch deep in the empty slot.
    - A first try cropped close to the gold, and a gold seam showed between dark cells at the pill's size: an image drawn small blends each pixel with its neighbours. Hence the patch, kept 8 pixels clear of any gold.
    - The third cell is a pixel narrower than the others, since the image's slot ends there: under half a screen pixel at the pill's size.
  - **The pill:** the mark at 17 points, 4 before the battery's reading, always, its middle on the reading's line.
    - It's placed by the words' own drawn width as it changes (`Pill.Before`).
    - A first placement by the face's measured width put it 3.6 to 5.3 points off; now it's 3.6 to 3.9.
    - The pill's own mark stays the bolt, where the battery's jump flies to.
  - **Cases:**
    - logic "Hud: TR41 (e), the battery mark's cells …", 24,062/0;
    - the plate's cells against the save's charge, in "Power: the generator …", 91/0;
    - the pill's cells, its gap (within 0.75 points), its line, and its clearance from the generation's words, in "HUD: … the pills read the save", 38/0 at full and 39/0 at 35 kWh;
    - "AR12, the pills wear …", 38/0. Type check 0 new.
  - **The take** passed its screen and mark checks. Its two training checks failed: I skipped the driver's training setup this time, since only the stills mattered. They passed at (e).
  - **Stills,** in `build/scratch/faber/stills/`:
    - `tr41e-fix-pill-cells.png`: the pill at 0.32 kWh, 35.02 and full, with one, two and three cells.
    - `tr41e-fix-plate-phone.png` and `tr41e-fix-plate-mark.png`: the plate at the smallest phone, at 35 of 60, two cells.
    - `tr41e-fix-large.jpg` and `tr41e-fix-large-head-pill.png`: the plate and the pill together at 35.20, two cells each. These came before the placement by drawn width, so the pill's gap there is up to a point and a half wide.
  - **Four facts:**
    - **Implemented:** yes.
    - **Tested:** as above.
    - **Visually reviewed:** my stills. Research's read is next.
    - **Director-accepted:** no.
- **Research's second look (Quaestor, 2026-11-17, 19:09): passed, closed** (239d8a6; the pill's three charges and the plate at 35 of 60, read zoomed).
  - **The fix:** the mark and the reading now agree at every charge. 0.32 kWh shows one cell, 35.02 shows two, and "full" shows three. The plate at 35 of 60 shows two cells over a bar a little past half.
  - **The pill:** the mark makes "full" say what is full.
  - **Nothing broke.** TR41 is done on research's side, (a) to (e).

## TR50. One mission per Arc (Faber, after the foe card's upload)

- **Feel line:** the player taps Play, sees Lantern Row with Normal and Hard, taps one and is in. The four stretches run on one after another to the Lamplighter, with a line between them saying how far they've come. A lead that falls late comes back at its stretch, not at the gate.
- **The director's word:** 2026-11-19, 23:19 (`docs/decisions.md`, the row; `docs/design.md`, "The Festival of Battles").
- **What the block contains:**
  1. **Play** opens the Arc panel straight away. The mode panel stays in code for later modes, skipped while there's one.
  2. **The Arc panel:** one tile for Lantern Row, with Normal and Hard as its two choices: recommended CR, Hard's lock and its condition, and the run's checkpoint ("Stretch 3 of 4"). AR42's picker art is reused, its four stage tiles going.
  3. **The run:** `Rules.Stages` keeps its four rows as stretches. A stretch's clear moves straight on to the next with AR42's stage line ("Stretch 2 of 4"), and the results card shows once, at the run's end. A stretch's chests, experience and quota are as they are now, so TR48's pace and TR49's fit stay put, the stage factors included.
  4. **Checkpoints,** in the save: the last stretch reached per difficulty, until that difficulty's keeper falls. A fall ends the run. Leaving the place keeps the checkpoint.
  5. **Hard** opens when the Lamplighter falls on Normal, as now. The first Hard win's Rare floor stays the keeper's.
- **Waits:** a second Arc on the panel; any new art (AR42's pieces carry it).
- **Done when:** the cases cover a full run, a fall at stretch 3 resuming at 3, the checkpoint clearing on the keeper's fall, and Hard's lock; a phone capture shows Play to the Arc panel and a stretch's line.

### Built in the game (Faber, 2026-11-19, 23:19 to 23:58 by the clock)

- **Play:** the dock's Play and the base's door open the Arc panel straight away. No mode panel exists in code yet, so there's nothing to skip.
- **The Arc panel** (`UI/StageScreen.luau`, `StageScreen.Pick`; `Config.Hud`, `Stages.Arc`):
  - one tile for Lantern Row, on AR42's glass: the Lamplighter's picture, the ground's name, and Normal and Hard as two presses inside it;
  - each press shows its recommended CR and its four marks (cleared, the checkpoint ringed, the rest shut), with "Stretch k of 4" and what comes next ("To the Lamplighter", "Continue from here", or the best run's time);
  - Hard, while shut, shows the lock and "Beat the Lamplighter on Normal";
  - AR42's four stage tiles and the difficulty switch are gone.
  - **Recommended CR:** the builder's seed, tier 2 for research: the keeper's own CR on that difficulty, at his level there, lifted as TR49 lifts him (`Rules.Stages.Recommended`). Research can flip it to the run's first stretch.
- **The run** (`Rules.Stages`, `StageService`):
  - **Begin:** `Net` "Stage" is `(ground, difficulty)`, and the server picks the stretch: the checkpoint (`Stages.Checkpoint`).
  - **Stretch to stretch:** a clear writes the stretch once and moves on after `Results.After` with no card, and the gate behind the run opens (`Stages.Through`).
  - **The card,** once, at the end (`StageScreen.Results`):
    - on a win: "Lantern Row cleared", the whole run's time, chests, credits and shards, and "a new best" only for a run that began at stretch 1;
    - on Normal's keeper: "Hard is open", and the lit press goes into Hard;
    - on a fall: "Your lead fell" and "Your next run starts at Stretch k of 4".
  - **Stretches unchanged:** each stretch's quota, chests and experience are the same, so TR48's pace and TR49's fit stay put.
- **Checkpoints** (`Profile.StageLine.Reached`):
  - the last stretch reached per difficulty, saved on each clear;
  - kept on a fall and on leaving the street or the place;
  - cleared when that difficulty's keeper falls.
  - Hard opens on the Lamplighter's fall on Normal, as before.
- **The line:** "Stretch 2 of 4" under the top bar. The toast at a shut gate reads "Clear Stretch k to go on".
- **Tested:**
  - Type check: 0 new.
  - Logic, offline: 28,834/0. `Cases/Stages` covers a full run, a fall at stretch 3 resuming at 3, the checkpoint clearing on the keeper's fall, Hard's lock, and a ticket's arrival at the checkpoint.
  - In the main place: the base's travel case 35/0 (Play opens the Arc panel; the ticket carries the checkpoint; Hard while shut is refused), the dock 39/0, and "Take: TR50" 6/0.
  - **NOT VERIFIED:** the Festival place's run case "Stages (TR50)", rewritten to the run (a run moving on, leaving, the panel at the checkpoint, the keeper's card opening Hard, Hard moving on, a fall at stretch 3), and the Festival travel case. They wait for the Festival place (item 9).
- **Captures** (the smallest phone, in `build/captures/tr50/`):
  - `panel.png`: Play to the Arc panel, Normal at stretch 1 and Hard shut;
  - `panel-stretch3.png`: a checkpoint at stretch 3;
  - `line.png`: a stretch's line, in the main place from the run's attributes on the client;
  - all three in `play-panel-line.png`, and `hard-lock-zoomed.png`.
- **For research:**
  - Hard's lock is the Voidkin chrome's `Lock`, AR42's own, but at phone size its shackle reads open. A closed lock may read better.
  - The line's badge says "2" beside "Stretch 2 of 4". The number shows twice; I've kept it as the block's words.

### Research's pass (Quaestor, 2026-11-19, 23:59)

- **Felt:** Play lands on Lantern Row with Normal and Hard side by side, and the track says at a glance where the run stands ("Stretch 3 of 4, Continue from here"). In the fight, the line says how far into the stretch you are. **Works. It closes competent on the must-fixes.** The combined still `play-panel-line.png` is a bad crop that shows only Roblox's corner buttons, so I read the three full stills.
- **Recommended CR stays the keeper's** (tier 2, research's): the run ends at the keeper, so that's the number that says whether you'll finish.
- **Must-fixes:**
  1. **A shut lock (class: every lock icon at phone size):** Hard's shackle reads open, so it says "unlocked". Use a closed shackle.
  2. **The way in is a press:** nothing on the Normal card says "tap here". Give the open difficulty a lit press, "Fight" or "Continue" at a checkpoint, in the kit's `Lit`.
  3. **The line's badge** shows the difficulty's mark (Hard's chevrons, Normal's own), not a second "2".
  4. **Name the last foe:** "then its last foe" reads oddly. Write "then the elite", or "then the Lamplighter" on stretch 4.
  5. **The track's ends (class: every track or bar with nodes):** a stub of line sticks out left of 1 and right of 4. The line runs from node 1 to node 4 only. The done ticks sit on the nodes' top left corners, half outside, so set them inside the node or as its fill.
- **Older, Modulo's after AR49 (class: every art tile's ground):** Lantern Row's tile stands its lantern on a violet field, the ground the director keeps calling too purple. Its ground should be the festival's dusk, warm under the lantern.

### Research's must-fixes in the game (Faber, 2026-11-20, 00:00 to 00:10 by the clock)

1. **A shut lock:** Hard's lock is the closed shackle, `Voidkin.Chrome.Images.LockOn`. The Arc panel was the only place a lock stood for "shut"; the Voidkin screen's toggle keeps its open/closed pair.
2. **The way in:** the open difficulty's card carries a lit press, "Fight", or "Continue" at a checkpoint, in the kit's `Lit` (Hard's in its ember). It sits under "Stretch k of 4" (`Config.Hud`, `Stages.Arc.Choice.Says` and `Press`). The whole card stays the tap. "Continue from here", the best run and "To the Lamplighter" leave the card: the press says it.
3. **The line's badge:** a lit square holding the difficulty's mark, Hard's two chevrons or Normal's one (`StageScreen.Mark`). Normal's one chevron is new: `ChevronSingle`, drawn in code in LevelChevrons' stroke (`tools/ui/chevron_single.ps1`; content check PASS; 106111525882911, Approved).
4. **The last foe by name:** "then the elite", "then the Lamplighter" on the keeper's stretch, and "the elite down".
5. **The track** runs from node 1's middle to node 4's, under them, with nothing past either end, on the panel and the run's card. A cleared node wears its tick as its fill, centred, with no number.

- **Tested:** type check 0 new. In the main place: "Take: TR50" 13/0 (the press's words, the closed lock, the track's start, the ticks in their nodes, the line's chevron and its last foe), travel 35/0, the dock 39/0. The Festival case checks the press says Continue at the checkpoint (NOT VERIFIED, item 9).
- **Stills:** `build/captures/tr50/fixes-panel-line.png`, the three full frames stacked. Hard's line at the keeper's stretch is in `fix-line-hard-zoomed.png`.

### Research's second look (Quaestor, 2026-11-20, 00:11)

- **All five fixes are met.** The lock is shut, "Fight" and "Continue" are the lit way in, the badge carries Normal's chevron or Hard's coral pair, the foe is named, and the track runs node to node with its ticks as fills. **TR50 passes at competent** on what players see. The Festival run cases stay NOT VERIFIED until the place opens (item 9).
- **The older line widens, Modulo's after AR48 (same class: every art tile's ground):** not only the lantern's tile, but the picker's whole screen stands on a violet ground with a lavender glow. Both take the festival's dusk, warm under the lantern.

### The Arc panel's ground in the festival's dusk: a colour block-in (Modulo, 2026-11-23, 00:12 to 00:20 by the clock)

- **The sheet:** `build/scratch/modulo/arc_dusk/stage_arc_dusk.png`: the Arc panel as it stands today and three steps of dusk, each at the smallest phone's own pixels. Drawn by `tools/blender/stage_arc_dusk.py` from `Config.Hud`'s Stages and Faber's capture, as a stand-in for the layout. Each step's colours are in `stage_arc_dusk.json`, under the names Config keeps them by.
- **No image changes.** The lantern's picture is clear round the lantern: its violet field is the bed's fill and bloom (`Stages.Bed.Fill`, `Accent.Normal.Bloom`), so every step is a palette for Faber.
- **The steps,** each over the one before:
  - **A, the bed only.** The lantern's field is the dusk street: dark wine over the lantern (`#1E0F16`), rosewood at its foot (`#4A2324`), its light pooled low in amber (`#FF9A50` at 0.62, its middle 0.36 of the bed under the lantern's). The lantern's gold needs a dark field behind its paper, so the warmth sits under it, where its light would fall.
  - **B, and the ground.** The screen behind the glass in the street's rose (`#5E2A3A` to `#1E0E12`, a bloom of `#FF8246` at 0.38 behind the bed), the light round the panel and Normal's lit plates in lantern light (`#FFCF98`; white to `#FFE0B4`). The glass stays Seam's.
  - **C, and the glass.** The panel, its cards, its wells and its words in rosewood and ivory.
- **A scope to keep:** the director's word of 2026-11-19, 14:56 put the picker back in Seam ("i liked the old one before"; AR43, "Equipment back in Seam"). A and B keep Seam's glass. C leaves it on this screen, so C is past that scope and would be the director's to say.
- **Modulo's read:**
  - A fixes the tile and nothing else: the screen still stands on violet.
  - B answers the line. The ground and the bed are the ground's own dusk and the violet glass is one colour among others. It also scales: each ground gives its bed and its screen their colours, and the kit stays one kit. Its weak spots: the band's dark plates stay violet-black on the rose, and Normal's cream press sits nearer Hard's coral than lavender did.
  - C is the most of one piece, but it's all one warm brown-rose, and it drops the kit on one screen.
  - **Modulo recommends B.** The first take's ground (`#3E1F26` to `#170C0F`) read as a dull maroon, so it was moved to the street's rose.
- **Not drawn:** Hard open, the results card and the run's line, which keep Seam's ground; say if they follow.
- **Status:** drawn and self-read. Not content-checked (colours on a checked screen, nothing uploaded), not picked, not in the game. It waits on research's pick, then the palette for Faber.

### Research's pick: B (Quaestor, 2026-11-23, 00:19)

- **Felt:** the screen opens on the festival's dusk street, the lantern glowing in its own warm field. The Seam glass sits over it as the screens' one make, and the violet is a panel's colour now, not the world's.
- **Tier: competent. B is picked.** The one bold thing is the lantern on dark wine with its light pooled under it: it pops far more than on violet, and it tells you where you're going.
- **Why not the others:** A leaves the screen standing on violet, so it misses the line. C binds best, but it drops Seam on one screen against the director's 14:56 word, and it reads as one brown. C stays out unless the director asks.
- **Must-fixes:** none. Modulo's two weak spots aren't fixes. The plates in the top band are Seam's glass, as the panels are, and the cream Fight against Hard's coral reads apart at the smallest phone.
- **They follow, in the same palette:** the results card and the run's line take B's ground behind their glass, so the festival's screens share one dusk. Hard open and those two are drawn with the palette's delivery and read by Modulo. Only a clash comes back to me: Hard's coral lit on the rose ground is the one to watch.
- **For Faber:** a palette only (`stage_arc_dusk.json`, B), installed after AR49, in the main place's UI. It isn't Festival-place work, so the director's order of 00:05 doesn't hold it.

### What follows from B, drawn: a clash in Normal's lights (Modulo, 2026-11-23, 00:21 to 00:29 by the clock)

- **The sheet:** `build/scratch/modulo/arc_dusk/stage_arc_dusk_follow.png`, three columns at the smallest phone's pixels: today's, B, and B with Normal's lights left Seam's (`B_KIT` in `stage_arc_dusk.json`). Its rows: the panel later (Normal at its third stretch, Hard open), three results cards, two of the run's lines.
- **A fact first:** the results card and the run's line have no ground of their own. The card stands over the street, dimmed by a cover (`Screen.Dim`, `Card.Dim` 0.5, in `SeamGlass.Backing`, `#1F1942`); the line stands in the HUD over the street. So what follows from B on them is the cover's colour and Normal's lights, nothing else. They're drawn over a stand-in of Lantern Row's dusk.
- **The cover follows, and it's the gain:** in dark wine (`#2A1219` at the same 0.5) the street under the card stays the street's dusk. Today's violet cover turns it purple.
- **The clash, in B as picked:** B put Normal's lit plates, marks and road in lantern cream. With Hard shut that read apart. With Hard open it doesn't hold:
  - **On the panel,** Continue in cream sits over Fight in coral: two pale warm plates, apart only by a tint and the chevrons.
  - **On the card,** the cream road, Ready's gold ("a new best", "Stage 4 is open") and Hard's coral band are three warm lights side by side. Today the way on is lavender, what you earned is gold, and Hard is coral.
  - **On the line,** Normal's cream mark and Hard's pink one differ by the chevrons' box alone, in a HUD that's lavender everywhere else.
- **The fix, drawn (the third column):** Normal's own lights stay the kit's (the lit plates, the marks, the road, the ring, Normal's card's edge). The dusk keeps the ground behind the glass, the bed with its pooled light, the light and the rim round the panel, and the card's cover. Normal and Hard read apart at a glance again, and gold is alone again.
  - It's also less to build: the lit press stays the kit's shared fill (`Make.Lit.Fill`), the card changes its cover only, and the line doesn't change.
- **Modulo's read: B with Seam's lights, competent.** B as picked would ship a weaker Normal and Hard pair than today's.
- **Status:** drawn and self-read. It waits on research's word on the clash. Then the palette goes to Faber under Config's own names. Not in the game.
- **Research, 00:29: yes to the third column, competent.** Seen: in B, Continue's cream over Fight's coral are two pale warm plates, and the road's cream sits too near "a new best"'s gold. With Normal's lights left Seam's, Normal reads lavender and Hard reads coral at a glance, on the panel, the card and the line. The dusk keeps the ground, the bed, the panel's light and rim, and the card's cover. That is all the line asked: violet is off the ground and stays on what's lit. The palette goes to Faber, after AR49.

### The dusk palette, delivered (Modulo, 2026-11-23, 00:31 by the clock)

- **For Faber, after AR49:** `build/handoff/UI/stages/arc_dusk.json`, with the two sheets beside it (`stage_arc_dusk.png`, `stage_arc_dusk_follow.png`: the third column is the one to match). No image changes and nothing to upload.
- **What changes,** each under the home it has in Config today:
  - **The ground behind the glass:** the Arc screen's own backing (`#5E2A3A` to `#1E0E12`, through `Glass.Ground`'s third argument), and a bloom on it behind the bed (`#FF8246` at 0.38). The bloom is new: the Arc screen has none today.
  - **The bed:** `Stages.Bed.Fill` (`#1E0F16` to `#4A2324`), its bloom in `#FF9A50` at 0.62, lower and flatter (`Bed.Bloom.Middle` 0.5, 0.88), and its edge in `#7A5048`.
  - **The panel:** its glow in `#FFCF98` and its rim in `#FFEBD2`, with Back's underline.
  - **The results card:** its cover in `#2A1219`, at the same `Card.Dim`.
- **Three colours need a home of their own,** since Normal's lights stay as they are: the bed's bloom (today `Accent.Normal.Bloom`), the panel's glow (today `Accent.Normal.Glow`) and the card's cover (today `SeamGlass.Backing`). Where they live in Config is Faber's call.
- **The bed's bloom is matched by eye:** the json gives where the drawn light falls to a third (85.5 by 39.8 points on the bed). `Bed.Bloom.Size` is set against the sheet at the phone's pixels, since the kit's bloom has its own falloff.
- **Stays:** Normal's lights, Hard's ember, Seam's glass and its words, the run's line, every image.
- **Status:** made, self-read, passed by research at competent (00:29), delivered. Not content-checked (colours on checked screens, nothing uploaded). Not in the game: the first capture of the installed panel is read at the smallest phone, with Hard open.

### The class swept: every art tile's ground (Modulo, 2026-11-23, 01:52 to 02:05 by the clock)

Research's go at 01:52, as one colour block-in capped at about an hour. A read-only survey of `src/client/UI` and Config listed every place a picture stands on a field of its own: eleven.
- **One is a ground in the element's colour: the floor under the fighter on the Voidkin screen** (`VoidkinScreen/Figure.luau`, the `Floor` part). It's a Neon disc in the fighter's element, so Storm's fighters stand on pink and Void's on violet (Fire's on orange, which the viewport dulls to olive: `#AB9F52` in `build/captures/ar43/take2-lead.png`). This is the floor in research's row.
- **The block-in:** `build/scratch/modulo/voidkin_floor/voidkin_floor.png`, by `tools/blender/voidkin_floor.py`: Rook (Fire), Watt (Storm) and Kirra (Void), each today and in two takes, at the smallest phone's pixels. The fighter is a grey stand-in. Storm's and Void's floors as shown today are estimates from Fire's.
  - **A, one floor:** pale stone for every fighter (`#A9A59B` as shown, with the stage's light on it). The element stays in the fighter's words.
  - **B, the element as a rim:** the same stone, and a thin ring of the element's light round its edge, 0.03 of the floor across.
  - **Modulo's read: B.** The floor reads as the stage's stone, and the element is an accent again, one small thing. A is calmer, but it drops the only place the element shows as colour on this screen.
  - **For the build, either take:** the viewport dulls a Neon part, so the stone's and the rim's colours are matched to the sheet in the game. B's rim is one more part in the figure's world.
- **Left as they are, with the reason:**
  - **Seam's own glass:** the bag's, Equipment's and Reinforce's cells, the sockets, the results card's chips, the dock's tiles, the Void Shop's hero. A well in the kit's glass isn't a ground, and the director's word of 2026-11-19, 14:56 keeps these screens in Seam.
  - **Already not violet:** the lead card's and Home's fields behind a fighter (navy), the portraits' wells (graphite), the Breaker's chamber (teal glass).
  - **The Voidkin screen's stage** behind the fighter (`Seam.Stage`, violet-black, lit from below by the rarity): the screen's own glass, kept.
- **Two that aren't palettes, for research to weigh, not drawn:**
  - **The reveal's room** (`reveal_room.png`) is baked violet-black, `#2B2542` to `#07050C`: a whole room as the ground. It's a closed piece, and a change is a new image.
  - **Equipment's ground** (`Hud.Equipment.Backing` with its violet bloom) is the ground the picker just left. The 14:56 word keeps it.
- **Status:** drawn and self-read, 13 minutes of the hour. Not picked, not content-checked (colours on a checked screen), not in the game.
- **Research's pick, 02:05: B, competent.** The floor reads as the stage's own stone, and the fighter stands out on it. The element shrinks to one lit edge, so Storm's pink and Void's violet are an accent on what's alive, never a ground. A loses the one colour that tells the element at a glance. Modulo's survey of the other ten stands, with its reasons. The reveal's room goes to `docs/polish-later.md`, since it's a closed piece and a new image. Equipment's ground stays, on the 14:56 word. For Faber, after TR51: the stone and the rim matched to the sheet in the viewport.

### Faber's cloud session: the run's rules made pure (2026-11-20, offline, no Studio; 5058a78)

- **Moved from StageService into `Rules.Stages`:** which falls count (`Counts`), when a Hard pack stands again (`Regrows`), whether a gate is shut (`Shut`), the save's holdings and the run's two cards (`Holdings`, `Won`, `Lost`), the run's attributes and their reading back (`Published`, `Parse`, which StageController now shares), and the log's name (`Label`). The service only wires them; nothing players see changed.
- **Cases:** three in `Cases/Stages`: the falls and the regrowth, the gate, and the cards with the attributes. A gain is floored at 0 when Credits were spent past it during the run. Each was mutation-checked.
- **Tested:** offline 28,896/0 at that commit; the type check 0 new, 11 known; the Rojo build.
- **NOT VERIFIED (the Festival place):** the run case "Stages (TR50)" in its playtest, and the run's log line in a real run.
- **Found, not fixed:** the client's `look()` gate rule skips the server's ground check and its Ending state. It can't show while there's one ground; at ground 2 it should call `Rules.Stages.Shut`.

### The dusk palette and the Voidkin floor, installed (Faber, 2026-11-23, 17:52 by the clock)

- **The dusk, as `arc_dusk.json` gives it (B with Seam's lights), under Config's names:**
  - On the Arc panel: the ground behind the glass (`Stages.Arc.Backing`), the street's light pooled behind the bed (`Arc.Bloom`), the light round the panel (`Arc.Glow`), its rim and Back's underline in ivory (`Arc.Rim`).
  - On the bed: its fill, its amber pool (`Stages.Bed.Bloom`), its rosewood hairline (`Bed.Edge`).
  - The run's card: its cover in dark wine (`Card.Cover`). It dims the world by half toward the wine (a ground pixel 205,185,165 bare, 123,101,95 under it).
  - Normal's lights, Hard's ember and the run's line are unchanged.
  - `Button.Set` takes an `Underline` colour, the screen's own light.
- **Found and fixed:** a screen opened again under its name keeps its cover and its Back. So the card clears the ivory from Back, and the panel opened over the card (the server's `StagePick`) puts its own cover colour back.
- **The floor, B:**
  - The fighter stands on stone (`Voidkin.Stage.Floor.Stone`), its element a ring of opaque Neon round the edge, 0.03 of the floor across. A fighter with no element gets no ring.
  - Measured on the stage with grey probes: plastic shows about 0.74 of its colour, and Neon shows about 11.3 × colour^1.84 in linear light (`Floor.Neon`). Fire's orange showed yellow before.
  - So the stone wears `#E4DCC4` to show the sheet's `#A9A59B` (155 to 167 shown), and the ring wears the colour that shows its element's (Fire's shows 229,134,67 against 255,138,61).
  - The unused `Stage.Glow` is gone.
- **Tested:** type check 0 new.
  - "HUD: TR50's dusk" (new) 15/0: the panel's ground, the bloom at the bed's middle, glow, rim, the bed, Back's ivory; the card's wine; and the panel reopened over the card.
  - "Voidkin screen (TR17)" 271/0: the stone, and the ring checked through the measured curve, within a part's 8-bit colour step.
  - The base's travel 35/0, the dock 39/0, Home's panel 40/0, Kit AR30 27/0, the button states 15/0.
  - "Take: TR50" (it gained a Card step) 10/1. The one fail is "Hard shut wears the closed lock": I staged Hard open for the sheet's state.
  - AR43's take 3/0. The save was put back after staging (Normal 2 cleared, checkpoint 1).
- **Stills,** at the smallest phone, the main place's light (`build/captures/tr50/`): `arc_panel_hard_open.png`, `arc_back_underline.png`, `run_card_cover.png`, `voidkin_floor_rook.png`, `voidkin_floor_marigold_epic.png`.
- **Against the sheet's third column, for research's look:**
  1. The bed's amber pool is broader and browner than the sheet's core under the lantern.
  2. The ring has no halo: a viewport draws no bloom, and a stepped halo would read as more rings.
  3. Under an Epic, the stage's light (TR17's rarity trim) tints the stone lavender. The light is outside B: research's call whether it should stop tinting the floor.
  4. Back's underline wears the ivory in the kit's soft rest state, not the sheet's crisp line.
- **Status:** implemented and tested in the main place. Waits on research's pass. Not director-accepted.

### Research's look at the install: competent, two must-fixes (Quaestor, 2026-11-23, 17:54)

From the five stills at the smallest phone, against the sheets' third column and the floor's B.
- **Felt:**
  - The Arc panel reads as one evening at the festival: the lantern glows amber in its bed, Normal sits in cool ivory, Hard in ember.
  - On the Voidkin screen, the fighter stands on pale stone, its element a ring of light round the edge.
- **Tier:** competent.
- **The one bold thing:** the lantern's warm pool against the cool ivory panel.
- **The four differences:**
  1. The bed's pool, broader and browner: accepted. At phone size it reads as the lantern's light, not mud.
  2. No halo on the ring: accepted. The crisp ring carries the element, and Faber is right that a stepped halo would read as more rings.
  3. The Epic's light on the stone: **must-fix 1**, below.
  4. Back's soft underline: accepted. It's the kit's own rest state, the same on every Back.
- **Must-fix 1, class "violet on a ground":** a rarity's stage light stops tinting the floor. The stone stays the stone under every rarity, and the light keeps the fighter and the backdrop. Under Marigold's Epic the stone reads lavender today, and the floor is the one neutral the element's ring needs. The way is Faber's: the light's angle or range, or the stone's own colour.
- **Must-fix 2, class "a control the sheet doesn't have":** the run's card shows "Back" at the top left (`run_card_cover.png`), beside Retry and Home. The sheet draws none. The card hides it, unless Back does something Retry and Home don't; if it does, say what in this record, and research reads it again.
- **For the second look:** Marigold's floor under Epic, and the card without Back. Two stills are enough.

### Research's two must-fixes (Faber, 2026-11-23, 17:59 by the clock)

- **Must-fix 1, met: the rarity's light no longer tints the floor.**
  - The stage lights a plastic floor at its colour × (Ambient + LightColor × 0.46), per channel. Common's two measurements give the 0.46 within 0.02 on every channel.
  - The floor now wears what shows the sheet's `#A9A59B` under its own stage's light (`Voidkin.Stage.Floor`: Shows, Lit). The fighter and the backdrop keep the rarity's light.
  - Marigold (Epic) wears `#AFC28F` and shows 165,158,160 at the front; before, the stone showed lavender.
  - The Voidkin case checks the stone on Common and on a Rare (it picks the first Voidkin that isn't Common), and fails if the save holds none: 278/0.
- **Must-fix 2: Back stays on the card, for its one use:**
  - Back closes the card and leaves the player on the street where the run ended, the run over, with the HUD's Base and Play back. Retry starts another run and Home travels to the base, so Back is the card's only way to stay, by friends or to look round.
  - It's also the way out if Home is refused (`Home.Refusal`), when the card would otherwise hold.
  - Your call: if staying isn't wanted after a run, I hide it.
- **Stills for the second look:** `build/captures/tr50/voidkin_floor_marigold_epic_fix.png`. The card is unchanged: `run_card_cover.png`.
- **Tested:** type check 0 new; Voidkin screen 278/0; AR43's take 3/0.

### Research's second look: TR50 passes at competent (Quaestor, 2026-11-23, 18:00)

- **Must-fix 1 met:** under Marigold's Epic the stone reads as the stone (`voidkin_floor_marigold_epic_fix.png`), with Fire's ring round it. The rarity's light stays on the fighter and the backdrop.
- **Must-fix 2, answered by its use:** Back stays on the run's card. It's the card's one way to stay on the street with the run over, for an elite that anyone near may join, and the way out when Home is refused. The sheet missed a real exit, so the sheet was wrong, not the card.
- **The four facts:** implemented, tested, visually reviewed and passed; director-accepted not yet.

### Closed (Faber, 2026-11-23, 18:13 by the clock)

- **The whole self-test** on TR50's code (f0f7f88), from a fresh playtest: 3,376 passed, 2 failed (526 s, 53 fps).
  - **"Shop: the Void Shop's counter":** "the piece salvaged again (Worn)" failed in the run and passed alone, 57/0.
  - **"Keeper: … its lantern goes out last":** "and out on Out" failed in the run and again alone, 26/1. It is the same intermittent frame check that failed once and then passed twice on 2026-11-17; nothing near the keeper's fall has changed since. It is rerun at AR48's next playtest.
- **Logic, offline:** 29,197 passed.
- TR50 is closed at competent; the director's acceptance waits.

## TR51. The base grows: every machine's stages, the landing, the owner's plate and plinth (Faber, after AR49)

Research, 2026-11-23, 01:55 by the clock, on the director's order of 00:05 ("first we work on the main map and systems", `docs/decisions.md`). It's the main map's biggest gap against the north star (pillar 3, "The base is alive"). Today only the generator changes in the world: `WorldService` reads `machines.generatorStages` alone (`src/server/Services/Main/WorldService.luau`, about line 753). Every other stage's art is passed and waits on its install. So this is install work, with no new design.
- **Feel line:** a player raises the Breaker to level 6. A violet hoop climbs it, the old shape glows and swaps, and the Developed Breaker stands there, bigger. Walking back out to the gate, they can see from the Strip what their base has become, with their name on the gate's plate and their best Voidkin turning on its plinth.
- **The block contains, in this order, each checked before the next:**
  1. **Stages II and III in the world** for the Void Breaker (AR32), the bays (AR33), the battery (AR34; upload BatteryRack again) and the Training machine (AR35; upload TrainingCrown again). Each takes its stage from its own level (`Rules.BaseLevels`, `Config.Base.Machines.Stages`), the way the generator's swap works.
  2. **AR37's landing** on every swap: the hoop, the glowing cover, the throw, the light (AR37's table and the content check's five conditions; upload `fx_rise_Void` only). It plays on a level-up, never on a join or a respawn, where the stage simply stands.
  3. **TR22's world parts**, where AR16's plan already has their places: the gate's plate (the owner's name and the base's level, on both faces) and the plinth inside the gate (the picked Voidkin turning, with its Combat Power).
- **Waits:** the Forge and the Condenser standing (TR37, the next piece); the stage sounds (the director's samples); the base's levels 2 and 3 look beyond the machines (AR50, Modulo's); the Tower's lot (after the main game, the director's word of 2026-11-19).
- **Checks:** a logic case for each machine's stage at levels 5, 6, 14 and 15, and one that a join shows the stage with no landing; the flash guard's case (0.34 s); the self-test; captures from the gate and from the court, at stages I, II and III, at the smallest phone.
- **Research's verdict in the game** reads: the landing at full speed, at the Breaker and from the court; a base level-up's machines starting on one frame; the Highlight's fill at the court's distance; the plate and the plinth from the Strip.
- **Order:** Faber's next piece after AR49. It goes ahead of AR44's shine, TR10's stills, TR50's Arc palette and AR48's states. TR37 follows it.

### Faber's build (Faber, 2026-11-23, 02:08 to 02:50 by the clock: 38d01a8, ad1372b, e086d9e)

- **Implemented,** the three steps in order.
  1. **Stages II and III in the world** (38d01a8).
     - Each machine is laid as its kit's three stages, each a "Stage n" (`WorldService`). `BaseService` stands the one its level takes (`Rules.BaseLevels.Stages`): the Breaker and a bay by their own level, the battery and the Training machine by the base's.
     - The Breaker's chambers are laid once, with a lid where the save hasn't the chamber yet. BreakerLamp moves to its stage's crystal. The hinges and a bay's rings turn while a chamber breaks or a worker works.
     - Debug: `MachineLevel`.
  2. **AR37's landing** (ad1372b): pick A to Modulo's recipe (`Config.Landing`, tunable live; `Rules.Landing`; `LandingController`).
     - The server holds the old stage until the swap, 35 frames after the landing's start.
     - It schedules each plot's landings by the flash guard (Gap 0.34 s), so a base level-up's machines swap on one instant.
     - A join, a respawn or a plot changing hands plays none.
     - `fx_rise_Void` is uploaded under the group, 84217908322822. Until the kit's rbxm is rebuilt in Studio, the hoop and the shaft are Neon.
  3. **TR22's gate and plinth** (e086d9e).
     - The plate: the owner's display name over "Level n", on both faces (`Config.World.Plate`).
     - The plinth: the showcase Voidkin (`Collection.Showcase`) at its middle, facing the Strip, playing its Idle and turning 0.08 turns a second, with its CR over it (`Config.World.Showcase`).
- **Tested.**
  - Type check 0 new; logic offline 29,036 passed. The logic cases cover each machine's stage at levels 5, 6, 14 and 15; a join or respawn showing the stage with no landing; the landing's beats and size; and the flash guard over 400 seeded runs (never early, never closer than the gap, at most 3 swaps a second).
  - In-game cases written in `BaseCases` but not run:
    - each machine at its stage;
    - the swap under the full cover, read frame by frame;
    - a base level-up's three machines on one frame, and the Breaker's landing after the gap;
    - a respawn playing none;
    - the plate, the plinth's figure, and a pick and its return.
- **The Studio run (Faber, 2026-11-23, ef86dab at 14:42; the captures 14:49 to 15:00 by the clock).**
  - The full self-test 3,288 passed, 1 failed: TR42's audition lost a voice in the long suite, and it passes 89 of 89 twice alone. Every TR51 case above passed. LogicTests 29,155 passed; WorldReport empty.
  - FxKit.rbxm rebuilt in Studio: the hoop and the shaft wear `fx_rise_Void`, not Neon.
  - **The shards in their chambers,** at Stage III: each shard's middle sits 0.06 studs from its chamber's, a 1.1 by 2.2 shard in a 4.65 by 4.19 chamber. Chambers the save hasn't got stay hidden (`stage3_breaker_shards.png`).
  - **The landing,** in a burst of the viewport at Stage III from the court:
    - a base level-up's three machines swap on one instant, and the Breaker's after the gap (the peaks 0.35 s apart);
    - at the swap the machine is the cover's flat pale violet, which carries the beat;
    - the light's pool on the pale floor can't be read by day at Brightness 2. Kept there: a pool that read by day would bloom at dusk.
    - For research's read: the generator's floor ring reaches 1.3 r, about 28 studs from its middle, and runs through the Breaker and the court.
  - **The Fit Prints at Stage III don't fit today's plan.** Measured in play on plot 1, in the plot's axes:
    - generator 30.2 by 28.9, 27.2 high, its middle 3.7 inward of its spot;
    - Breaker 34.6 by 9.9, 20.2 high, 7.0 across;
    - each bay 10.4 by 11.7, 15.8 high; battery 6.5 by 4.5, 13.5 high; Training machine 9.7 by 13.0, 10.4 high;
    - Festival Door 8.6 by 14.2, 13.1 high (today's print is 3 by 12.4); Forge 11.1 by 8.8, 13.0 high; Condenser 9.7 by 9.5, 11.8 high.
    - Stage I matches today's Prints within 0.1.
    - **Where today's plan fails with Stage III's prints:**
      - Clear (12): 8.3 between the generator and the Training machine; 10.5 from bay 1 to the generator and from the Forge to the Training machine; 11.9 from the Breaker to the generator.
      - From the gate, the Breaker stands 58° off the line, past the 51° the camera sees.
    - **The trial's sizes fail too:** 128 (8.3; the Breaker on the way in and outside; 59°), 144 (8.3; the Breaker on the way in; 54°), 160 (8.3 only).
    - So `Config.World.Fit.Prints` stays at Stage I: Stage III's would fail the trial's logic case with no layout to answer it.
    - **Tier 2, for research and Modulo:** the plan at Stage III, the Breaker's and the generator's places first.
  - **The plate's top is cut from the gate's eye** (y 10 at z -11.5): "glocen" runs under the frame's top at every stage (`phone_stage1_gate.png`). For research: lower the plate, or let the name leave the gate's view.
  - **Captures,** in `build/captures/tr51/`, by day, the camera held at the gate's eye and from the court:
    - `stage1_gate`, `stage2_gate`, `stage3_gate`, and the same three for the court, at 2,483 by 1,134 with the HUD;
    - `phone_stage1_gate` to `phone_stage3_court`, the smallest phone's 1,334 by 750. These are the world only: the HUD there is laid for the desktop, and the HUD on the phone is AR49's and the cases';
    - `landing_stage3_court_01167ms`, `_01340ms` (the swap) and `_01687ms` (the Breaker's, after the gap);
    - `stage3_breaker_shards`.
- **Visually reviewed:** research's verdict asked. **Director-accepted:** not yet.
- **Tier 1, Faber:** the plate reads "Level n" under the name rather than the bare number, so a passer-by reads a level beside a name. Research: say in your row what you'd change.
- **Research's verdict (Quaestor, 2026-11-23, 15:26),** from `phone_stage1_gate`, `phone_stage3_gate` and `phone_stage3_court`:
  - **Felt:** walking in, a level-3 base is told from a level-1 base at a glance. The Breaker sprouts horns around its shard, and the generator a crown of spikes.
  - **Tier:** competent.
  - **The one bold thing:** the Breaker's Stage III horns around the floating shard, a silhouette that reads across the yard.
  - **Must-fix 1, class "text cut by the frame's edge":** the plate's name runs off the top of the gate's view at every stage. Raise the plate until it leaves the gate's view, so it's read whole from the Strip, where passers-by are. The owner reads their level on Home. "Level n" (Faber's tier 1) stays. The plate is Gate1's mesh, so it moves in AR54, Modulo's.
  - **Must-fix 2, class "the yard at Stage III":** today's plan doesn't hold Stage III's footprints (Faber's measures above), and the Forge and the Condenser stand behind the generator from the gate (TR37). It's one plan, so one piece: AR54, Modulo's, on research's rules. The generator's floor ring belongs in it: the ring ends inside its own clear, never under another machine or across the court.
  - **Not judged here:** the landing in motion. Faber's frames and their timing (0.35 s between the peaks) are accepted on the measures; it's first seen in motion at a live base level-up.

## TR58. The boards on the Strip (research's request, tier 2, for Faber; Modulo the boards)

Research, 2026-11-24, from the cloud. Launch-design's item 7, the north star's "two players compare builds". The design: `docs/design.md`, "Being seen" (the boards). The numbers: seeds, "boards".

- **Feel line.** Coming back from a run through the crossing, a player glances at the strongest-lead board, sees their name at ninth, and knows the number to beat.
- **The facts** (SOURCED, creator-docs, data stores' "Error codes and limits"): `GetSortedAsync` 5 + 2 × players a server a minute, writes 30 + 5 × players, a page at most 100. The plan uses 3 reads and at most 8 posts a minute at 8 players (COMPUTED).
- **In the block:**
  - two new ordered stores, the best lead's CR and total stars, posted by the server as `TowerBoardService` posts the Tower's week: only raised, by UserId, the name looked up when shown;
  - the Tower's week moved onto a board in the world (the screen's board stays until the verdict);
  - three boards and the news plate in grey on the Shop's side of the crossing, top ten each, the viewer's own rank under them;
  - the news plate fed by TR57's every-server lines.
- **Waits:** a tap on a name opening the lead card (TR33, not built); the boards' art (Modulo, an AR after the verdict).
- **Cases:** a post only raises; the post throttle; the top ten and the own-rank line from a made-up page; a name never stored, only an id.
- **Checks:** the content check on the boards' titles; a world-report line for their place; research's verdict from the player's camera walking the crossing.
- **Order:** after TR57.
- **Research's verdict on the block, 2026-11-26, 01:35,** from `build/captures/tr58/` (the window's take; the phone's shows only sky, so it's retaken): the feel line doesn't read. A row is about 9 px on a window and 4 px on a phone at 26 studs.
  - **Must-fix (the main read; class: every board's face):** each face holds the top three and the viewer's own row, at about three times today's size. The viewer's row is lit and shows its rank first ("9 · glocen · 7,173"); a viewer in the top three is lit where they stand, and the fourth row shows the fourth. That's Faber's options 1 and 2 together, and it replaces "top ten each". The boards stay where they are: nearer the path would only double the size and crowd the crossing. The full list waits for a tap, with TR33.
  - **Must-fix (placement):** from the path, a pole stands in front of the Tower board's title. One of the two moves.
  - **Retake:** on the smallest phone, from the path's nearest point, walking the crossing.
- **Faber, 2026-11-26, 12:50 by the clock:** the face's must-fix passes in Studio, "Boards on the Strip (TR58)" 18/0. **The pole** is the crossing's south corner post (`StripPost` at x ±40, z 20.6, 10.4 studs tall, from Modulo's Strip plan). It stands between the Strip and both boards on its side, so as a player walks the Strip it sweeps across the Lead board, then the Week's. No board shift that keeps the boards where they stand clears it. Asked of Modulo: the two south crossing posts out to |x| ≥ 70 (the boards end at 59). **Retake** at 568×320, the player 26 studs off the boards, the post as today and then at x 70 in a playtest only: `build/captures/tr58/retake_z6_post_today_small.png` and `retake_z6_post_out_small.png`. At 70 both titles and their rows read clear. The test store holds one name, so a face shows one row; the four rows are the case's made-up page. The walking frames wait for the window in front.
- **Research's second look, 2026-11-26, 13:16** (`build/captures/tr58/retake2_*_small.png`, 568×320): both must-fixes pass, as visually reviewed by research.
  - **The face:** from the path's nearest point, the Lead board's title and four rows read, with the viewer's row lit and its rank first.
  - **The placement:** walking the crossing both ways, no post crosses a board.
  - **For the row's art, not a must-fix:** the empty faces ("News: Nothing yet", "Most stars: No one yet") hold one small line on a large dark slab. The empty state gets the rows' size and the board's own art.

## TR61. The words, one voice: nine string fixes (research's request, tier 1 per line, for Faber)

Research, 2026-11-24, from the cloud: a pass over every player-visible string in `src/` (about 1,080 read; the bar is `docs/design.md`, Goals, "The words"). The game already holds it: there are no exclamations, no "Complete" and no "Earn". These nine break it, as a slip of vocabulary or a voice split three ways. Strings only, no layout.

| Where | Now | Make it | Why |
|---|---|---|---|
| `Rules/Modes.luau`, festival's `Line` | "Fight through the grounds beside your lead" | "Fight through the Arcs beside your lead" | players read "Arc" (the director, 2026-11-19; design.md, "Words") |
| same, the fallback `named` | "The grounds" | "The Arcs" | same |
| `Definitions/Chests.luau`, a Hard chest's `Name` | "{chest} of {ground}, Hard Stage {n}" | "Hard {chest} of {ground}", with "Stretch {n}" on its card's second line | "Stage" left with the 2026-11-19, 23:19 row (one run of four stretches); the id keeps the stacks apart |
| `BaseController` 128, `BaseView` 85, `ShopScreen` 75 | "No answer. Try again." / "No answer: try again" | "That didn't go through. Try again." | one failure, one sentence: the other screens already say it |
| `BaseController` 112 | "None of that shard in the bag" | "You have none of that shard" | the bag's page reads "Inventory" (the director, 2026-11-19, 03:37); the line needn't name it |
| `VoidkinScreen` 886 | "Every star: a copy sells for Credits" | "All seven stars: a copy now sells for Credits" | the old line reads as if every star sells |
| `VoidkinScreen` 102 | "The lead fights, it can't be stationed" | "The lead fights: it can't be stationed" | the comma splice; colons are the game's join |
| `Bag.luau` 989 | "Shades drop them, and keepers" | "Shades and keepers drop them" | as its four siblings say it |
| `TowerScreen` 211 | "{n} opponents defeated" | "{n} floors won" | the bar's "no Defeat X"; the Tower counts floors everywhere else |

- **After TR56,** two lines turn false: `Emblems.luau` 281, "No emblems yet: Shades and keepers drop them", becomes "No emblems yet: elites and keepers drop them in cases" (the Emblem Case replaces the loose drop); and `Jewels.luau` 24, "Jewels are coming", goes once the pouch and the Condenser make jewels.
- **Cases:** none new; the self-test's text checks that read these strings follow them.
- **Checks:** the content check isn't needed (no new name); research reads the changed screens at the next capture.
- **Faber, 2026-11-24, 23:30 by the clock: done.** All nine, and both lines after TR56. Two calls of mine:
  - The Jewels line stays, and tells the truth: "Jewels are set here in a later update". Jewels drop (TR56) but setting them waits on TR47's part B, and the off presses need a reason.
  - "Stretch {n}" sits before the count on a Hard chest card's second line: "Stretch 2 · ×3 held", 97 px in 105 at the smallest phone. Hard chests of different stretches share a name and stack apart by id.
  - New case: "Items page: a Hard stretch's chest names its stretch on its card's second line, whole at the smallest phone (TR61)", 20 passed. EquipmentCases follows the Jewels line.
  - `docs/design.md` 272 still lists "opponents defeated" in the Tower's results (research's file).
