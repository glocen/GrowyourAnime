# Team notes: archived entries, November 2026

The oldest entries of `docs/team-notes.md`, moved here as that file passed about 250 lines (`AGENTS.md`, "Team notes"). Newest first.

### 2026-11-23, 13:38. AR50: the rings afloat refitted on one axle (Modulo)

- **What:** level 2's ring no longer passes through the generator. Both rings stand on one axle through the plot's heart, leant 9° into the plot: `LevelRing` is the floor's second ring lifted (23 in radius, 14 up), `LevelRingOuter` 27 in radius 10.6 further up it, turning the other way. Level 2's ring now reads from 150 studs and through the gate.
- **Where:** `build/handoff/Base` (the two meshes, their manifest entries and plan rows, four sheets); `tools/blender/base_levels.py`; the audit, `tools/blender/base_levels_clear.py`; the record in AR50, "The rings' refit".
- **Open:** research's pass on the whole finish. Research's call placed the floor's ring forward of the generator; it's round it, so the rings went wide of the generator instead (the record's first line). Nothing uploaded, nothing in the game.
- **For:** research now; Faber after TR51, all seven pieces as one install.

### 2026-11-23, 00:31. TR50's older line: the Arc panel's ground in the festival's dusk, a palette (Modulo)

- **What:** the screen behind the picker's glass and the lantern's bed take Lantern Row's dusk, the lantern's light pooled under it; the panel's glow and rim are lantern light; the results card's cover is dark wine, so the street under it stays its dusk. Research picked B, then B with Normal's lights left Seam's: in cream they ran into Hard's coral and Ready's gold once Hard was open.
- **Where:** `build/handoff/UI/stages/arc_dusk.json` and its two sheets; `tools/blender/stage_arc_dusk.py`; the record in TR50 (`docs/test-requests.md`).
- **Open:** not in the game. Three colours need their own home in Config (the bed's bloom, the panel's glow, the card's cover). The run's line doesn't change.
- **For:** Faber, after AR49.

### 2026-11-23, 00:18. AR48: the element states' cues, delivered as a block-in (Modulo)

- **What:** Burn, Chill and Freeze, Shock and Sap, grey then colour beside a plain hit, on the Shade and Rook from the player's camera. Frost and Sap passed at the block-in, Burn at research's second look, Shock on Modulo's read after must-fix 3, as research set it.
- **Where:** `build/handoff/FxKit/states/` (three sheets and the counts); the seeds in `tools/blender/element_states_fx.py`; the record in AR48.
- **Open:** nothing is in the game. The content check's conditions go with the build, and the first installed capture is read with the bodies turned, at 64 px.
- **For:** Faber, after TR49's states.

### 2026-11-19, 23:58. TR50, one mission per Arc (Faber)

- **What changed:**
  - The dock's Play opens the Arc panel: Lantern Row's tile with Normal and Hard, each with its recommended CR, its four marks and its checkpoint; Hard shows its lock and why.
  - A run goes through the four stretches with the line "Stretch 2 of 4" and one card at the end. A fall keeps the checkpoint; the keeper's fall clears it.
- **Where:** TR50, "Built in the game"; `Rules.Stages`, `StageService`, `UI/StageScreen.luau`, `StageController`.
- **Tested:** type check 0 new; 28,834 logic cases offline; in the main place, travel 35/0, the dock 39/0, the take 6/0.
- **Open:** the Festival place's run cases, NOT VERIFIED (item 9). Two looks for research: Hard's lock reads open at phone size, and the line shows its number twice.
- **For:** research's pass on `build/captures/tr50/play-panel-line.png`.

### 2026-11-19, 23:02. TR49, the combat review built, with AR43's take 2 of the Voidkin screen and bag (Faber)

- **What changed:**
  - Five Basic Attributes, Combat Power from EHP × DPS, F1 and F7 in the hit, Lifesteal and Kindle as the review set them, the enemy rows refitted, the ten elements, and the first levels faster.
  - The foe card's skull now reads the fight's cost, never grey at the lead's level or above.
  - The Voidkin screen and bag wear take 2, all five attributes on the smallest phone.
  - Also: AR44's Gap 0.12, and AR43's five level 3 jewels (Approved).
- **Where:** TR49, "Built in the game"; AR43, "Faber's install of take 2"; AR44, "Gap 0.12 in the game".
- **Tested:** type check 0 new; 28,782 logic cases offline and in Studio; the self-test 3,163/0 at 59 fps.
- **Open:** the Stage 1 playtest, NOT VERIFIED until the Festival place opens (item 9). Seven findings for research in TR49.
- **For:** research's pass on the captures in `build/captures/ar43/`, `ar45/` and `ar44/`.

### 2026-11-19, 21:24. AR40's C installed: the world by day, the Shop's building, the system panel's first two windows (Faber)

- **What changed:** both kits are in C, with the beds, the cream paving and the teal glass, and the base's atlas and the paving are uploaded under the group. The day is C's warm afternoon. The Shop stands as AR38's building: its counter collides, its crown shows on a featured stock, and its five minutes count each stock down. The Breaker's and the Power windows are on the system panel's slab, with C's ink, C's buttons and the chamber's teal band. The Breaker keeps its night (the director, 2026-11-15).
- **Where:** AR40, "The install of C"; `tools/studio/Kits/`, `src/storage/*Kit.rbxm`, `Config.Lighting`, `Config.UIKit` (System), `Theme.Ink`, `Kit.Button`'s face, `WorldService`'s `dressShop`, `Rules.Shop.Minute`.
- **Tested:** the type check, 27,232 logic cases, the world report, and the self-test's Shop, Power, Breaker, World, Base, Kit, HUD, UI, Equipment and Settings filters, all passing (three stale cases fixed).
- **Open:** research's pass on the four captures in `build/scratch/faber/ar40/`. The rest of the system panel follows: the base screen's chips and side panels, the Forge's, the Void Shop's screen, and the shared confirm, toast and reward.
- **For:** research.

### 2026-11-19, 20:33. AR43 in B: Equipment's three and Settings, from Home's tray (Faber)

- **What changed:** Home's tray opens Reinforce, Jewels and War Emblems on Equipment's screen in SeamGlass, and Settings on its own: one card of Music, Sound and Effects sliders, saved once on release and heard at once. Every tile in the tray is built.
- **Where:** AR43, "Faber's install of Equipment's three and Settings in B"; `src/client/UI/EquipmentScreen/`, `src/client/UI/SettingsScreen.luau`, `Rules.Settings`, `SettingsService`, `SettingsController`, `Config.Hud.Equipment` and `Settings`.
- **Tested:** type check 0 new; logic 27,226 passed offline; Equipment's three cases and Settings' case passed. The frame-bound checks are NOT VERIFIED: the PC is locked.
- **Open:** the phone captures of every state, then research's pass.
- **For:** research.

### 2026-11-19, 17:28. TR47 part A and TR48: gear's own levels, the loot refit part 1 (Faber)

- **What changed:** TR47 part A (6b640a0): Reinforce, War Emblems, the level gap and the transfer on equip; save v11. TR48: a keeper's wins count by difficulty (save v12), so the first Hard keeper gives a first win's chest, a sure Rare. Hard's stages roll their own chests at the stage's level on Drum Court's rows. The Tower is refit, stones and emblems drop at research's rates, and each stage run's length is logged (`StageRunSeconds` live, `StageLog` in Studio).
- **Where:** TR47, "Part A, built", and TR48, "Built" (`docs/test-requests.md`); `Rules.Progress`, `Rules.Chests`, `Rules.Drops`, `Definitions.Chests`, `Config.Chests`, `Config.Drops`, `Config.Tower`.
- **Tested:** type check 0 new; logic 27,212 passed offline and in Studio; the Gear, Tower and HUD self-tests passed. NOT VERIFIED in the Festival place (item 9).
- **Open:** the Equipment pages and TR47's phone capture come with the install in B. Research's long run reads TR48's notes.
- **For:** research.

### 2026-11-19, 16:36. TR32: the first session measured (Faber)

- **What changed:** Roblox's onboarding funnel logs the first session's eight steps, from Arrive to Want, once an account, from the server's own acts. Each step is marked on the save before it's logged, so a repeat, a retry or a rejoin never logs it twice. Saves that played before today have all eight marked (migration step 10).
- **Where:** TR32, "The build". `Rules.Funnel`, `FunnelService`, `Profile.Funnel`, and `DataService.Changed`, which now carries the act's label.
- **Open:** Want's case runs in the Festival place only (item 9). The dashboard's read waits for live players.
- **For:** research (the count), and the director at the soft opening.

### 2026-11-19, 16:29. AR38: the Void Shop, installed and closed at competent (Faber)

- **What changed:** the Void Shop works in the game. The server's shelf runs on world time and a stored salt, with one buy per transaction, the counter's prompt, and the restock chip under the pills. On research's pass: each line's picture is its card's hero on its light; the screen stands on the bag's room (`Seam.Case`); the shard says no rarity; and each Buy is the lit press, the kit's new `Lit` button on the numbers of Modulo's cut in B.
- **Where:** AR38's entry, from "The install" to "The lit press". `Rules.Shop`, `ShopService`, `ShopController`, `UI.ShopScreen`, `Config.Shop`, `Config.Hud.Shop` and `Make.Lit`, `ShopCases.luau`, the Shop's logic cases.
- **Open:** the lit press's sheen comes with B's idle phase, at Equipment's install.
- **For:** research, and the director's next look at the Strip.

### 2026-11-19, 13:19. AR44: the numbers' must-fixes, the measured critical, the clip (Faber)

- **What changed:** B is the plain numbers' style. The critical wears research's measured gold, its near-black outline and the #CC661F splash. Each glyph advances by its own share of the gap: a comma, a "1", a digit. Every number and word stays clear of every other along its whole rise, on any body. The self-test now starts with no screen open.
- **Where:** AR44, "Faber's must-fixes, the measured colours, and the clip". `Config.Hud.Numbers`, `Rules.Hud.PlaceAlong`, `UI.Kit.Digits`, the fighter's `Effects`, `NumberCases.luau`, and two logic cases.
- **Open:** research's second look, from `build/captures/ar44/`. The critical lands without a pop, research's call. Seven cases fail in the phone simulator and pass in the full window.
- **For:** research.

### 2026-11-19, 11:25. TR46: the heal cap told once, the week's board; "CR" in every word (Faber)

- **What changed:**
  - After a Tower run, the card says where you stand this week ("This week: #12 · floor 23"). A tap shows "This Week's Climb": the top 10 and your own row.
  - The heal cap's first bind says why, once per account.
  - Every word players see for Combat Power reads "CR" (the director, 10:36).
- **Where:** `Rules.Tower` (Score, Climb, Board, WeekLine), `TowerBoardService` (the week's OrderedDataStore, by UserId), `UI/TowerScreen`, `Sheet.Said.Power`. Record: TR46, "Where it stands".
- **Also:**
  - On a phone, Retry and Home had fallen off the card. It now lays out from its fitted room: the rows close up, and past that they scroll. A new case holds this down to the smallest phone.
  - A quick Home on the card in the fall's fade came undone when the fade's set-down beside the ring landed after it. Now a faded move gives way to any newer one (`KeeperService`, checked by `MoveRace`).
- **Open:**
  - research's pass on the card and the board, in grey;
  - research's `docs/design.md` line for the board;
  - the stage tile's "CR", NOT VERIFIED (the Festival place).
- **For:** research and the director.

### 2026-11-19, 01:58. TR44's slam in the keeper's fight, with its footprint and the switch Off, A, B (Faber)

- **What changed:** the Lamplighter slams in its fight, first 8 s after its Challenge, then every 12 s. From Plant its aim is fixed and a ring opens on the street, filling to its edge on the Slam. The hit takes the leads inside it.
- **A:** walk 2 studs out of the ring and your fighter follows. **B:** a Recall button by the right thumb (R, ButtonY) dashes it to you, with a 4 s cooldown. One switch, live, and the server counts each slam per mode.
- **Where:** `Rules/Mark.luau`, `SlamService`, `SlamController`, `FightService` (the footprint, the fixed aim, `Away`), `Config.Combat.Keeper` (First, Mark, Out). Record: TR44, "The block, built".
- **Open:** research's read waits on the phone take (stopped by the low-memory reaper); the director picks by playing (board, item 8). A fight at the keeper's level lasts about 20 s on Studio's account: one slam, not six (for research).
- **For:** research and the director.

### 2026-11-19, 01:31. TR43's stages, items 6 and 8, the music and the character sounds; TR42's second round ready (Faber)

- **TR43:** Lantern Row in four stages on Normal and Hard, in grey: the gates, the Door's first-time entry, the picker, the results card, Hard's own foes (TR43, "The block, built"). For research's read from a phone's camera.
- **Item 6:** Salvage on the item's card, left of Equip: a first tap asks with its Credits, a second salvages, and a worn item says "Take it off first". The full bag's line says how to free a slot (`UI/VoidkinScreen/Bag.luau`).
- **Item 8, D5:** the bays are 2, 3 and 4 at the base's levels 1 to 3; bays 5 and 6 stand locked, "Opens with more Voidkin" (`Config.Base`). Save step 9 trims a base holding more, freeing those workers. HP Regen's sheet line reads its burst with "every 8 s" under it.
- **The music:** `Config/Music.luau`, where the director pastes the ids; `MusicController` shuffles them, never one twice running. **The character sounds:** Roblox's walk, jump and fall sounds are gone (`src/overrides`).
- **TR42:** the picks are the cues, and the second round's 12 tabs wait on the director's listen, tomorrow.
- **Tests:** offline logic 26,574/0, Studio's the same, world report empty; the touched self-test cases pass (stages 78, bag 121, base 38, audition 89, sound 10).

### 2026-11-17, 23:24. AR39 stopped; the sounds go to the director's ear, TR42 (Quaestor)

- **What changed:** the sound rescue is stopped. Two more attempts passed every measure and failed at the director's first listen: 13 layers made by code ("horrendous sfx.."), then round 2's library recordings, sliced and stacked ("it sounds like everything but not a sfx"). Nobody on the team can hear, and the measures don't predict the ear.
- **The director's pick:** an audition panel in the dev place. Every cue is one finished library sound, any author, played whole, and the director keeps the one that's right.
- **Where:** `docs/asset-requests.md`, AR39 (the stop, and research's errors); `docs/test-requests.md`, TR42 (the panel); `docs/decisions.md`, the top rows.
- **Stands:** Faber's engine and its measures (starts on the mixer's clock, counted misses, the A/B switch, the match). Today's cues play.
- **Open:** TR42's build and the director's listen. AR40's renders and captures, for research's colour pick.
- **For:** Faber (TR42 first), Modulo (nothing on sound), the director (about 10 to 15 minutes on the panel).

### 2026-11-17, 18:49. TR41 (e): the HUD's V2 leftovers answered, the Training machine training (Faber)

- **What changed:** of AR12's 30 V2 images, 17 were already in the game. The battery's mark is now installed on the Power screen's plate, in place of its stand-in drawn from frames. 8 were replaced by later pieces (the dock's own images; the halos the director took off). 4 stay unspent until a pill or hint wears them.
- **Where:** `PowerScreen.luau`, `Config.Hud.Power.Images.Battery`; cases "Power: the generator ..." and "Take: TR41 (e)".
- **Tested:** the Power case 90/0, the take 6/0, type check 0 new. The Training machine's cyan was seen in the game, with the lead training.
- **Research's verdict:** works, one must-fix (the mark's cells disagreed with the reading), and yes to the mark in the Power pill. Both are in at 19:08: its cells follow the charge by thirds, on the plate and in the pill (`UI/BatteryMark.luau`, `Rules.Hud.BatteryCells`; TR41, "(e)", "Faber's fix").

### 2026-11-17, 18:38. TR41 (d): where a shard came from, the festival tag, installed (Faber)

- **What changed:** a shard's picture wears its ground's look. In a chamber, the tag hangs from the crystal's shoulder. In a bag cell, the mark sits on a disc at the crystal's left foot, since the count holds the right. On a Breaker chip, a band of the ground's colour runs along its foot. At the smallest phone the Breaker's chambers give way so the strip stays inside the panel; its chips had hung past it, cut.
- **Where:** `UI/ShardTag.luau`, `Rules.Hud.ShardTag`, `Config/Hud.luau` (`ShardTag`), `BreakerScreen.luau`, `VoidkinScreen/Bag.luau`. Cases: logic "Hud: TR41 (d)", self-test "Breaker: TR41 (d)", "Take: TR41 (d)".
- **Tested:** the tag 42/0, the galaxy 42/0, the Items page 112/0, the Voidkin screen 249/0, logic 24,051/0; type check 0 new.
- **Open:** the two-line name and the bag's ground filter wait, as the design's block says. TR18's take fails at the generator's prompt, not from this piece.
- **For:** research's read (`build/scratch/faber/stills/tr41d-*`).

### 2026-11-17, 17:58. TR41 (c): the level-up notice, take B, installed (Faber)

- **What changed:** a level gained shows Modulo's notice under the lead's corner: it slides in, its number lands with a flash and a knock, one sheen crosses, and it slides back. The old toast and the word over the lead are gone; the column of light stays.
- **Where:** `UI/LevelNotice.luau`, `Rules.Hud.Notice`, `Config/Hud.luau` (`LevelNotice`), `HudController`, `Effects.LevelUp`. Cases: logic "Hud", self-test "HUD: TR41 (c)" (`NoticeCases.luau`), "Take: TR41 (c)".
- **Tested:** HUD 445/0, the notice 39/0, logic 24,032/0; type check 0 new.
- **Open:** the plate is three plain image pieces, since a Roblox 9-slice drew it wrong under the layer's scale. The number sits on the block as drawn (30.75), not on the json's 28.9.
- **For:** research's read from the strip (`build/scratch/faber/stills/tr41c-strip-zoom.png`).

### 2026-11-17, 16:52. AR17: the Strip installed at 128; TR41 (a)'s two must-fixes (Faber)

- **What changed:** the Strip and the side street wear Modulo's kit, laid from the festival gate (12 meshes, 126 placements, 7 lights, the paving). The great shard glows steady, without Clear's lift. The Breaker's falling star is Modulo's redraw, and the ready row fades out at the detail panel.
- **Where:** `WorldService` (`dressStrip`), `src/storage/StripKit.rbxm`, `Config/Kits/Strip/`, `Config/Lighting.luau` (`Steady`), `BreakerScreen.luau`, `Config/Hud.luau`. Cases: logic "Strip:", self-test "World: AR17", "Breaker: TR41".
- **Tested:** logic 24,007/0; World 79/0, Base 261/0, HUD 419/0, Breaker 179/0; type check 0 new.
- **For research:** the phone captures at the spawn and the crossing, and TR41's second look (`build/scratch/faber/stills/ar17-*`, `tr41-falling-3.png`).

### 2026-11-17, 15:59. AR17: the Strip's plan laid again at 128 (Modulo)

- The Strip's pieces stand where the world at 128 puts them. The Strip runs ±432, the festival gate is at -200, and the plots are at ±128 and ±288. The crack, the posts, the outcrops and the far ring all moved with them; nothing in the kit changed. 126 placements, 12,868 triangles, 7 lights.
- **Fix 3:** the farthest gate is 288 from the crossing. From there the great shard reads 3.7 to 1, against 3.2 from the 372 view research passed (the same measure on both).
- **Where:** `build/handoff/Strip/` (`plan.json` and the eleven views); the record is AR17, "The plan laid again at 128".
- **Open:** research's pass, then Faber's install.

### 2026-11-17, 15:45. AR30: the phone sheet on the smallest phone (Modulo)

- Every button in the seam's make, on Faber's seven smallest-phone stills: the item card, the class-locked card, a chest's card, the Breaker, the base screen's rows, and the dock and prompt at a bay and at the Breaker. Today's buttons are on the left, the make on the right.
- **Where:** `build/handoff/UI/buttons/buttons_phone.png`; the record is AR30, "The phone sheet on the smallest phone". Content check PASS.
- **Open:** research's read. One note goes beyond the buttons: the item card covers the bag's chips at this size.

### 2026-11-17, 15:31. AR16: the plan laid again at 128 (Modulo)

- **What changed:** AR16's star is recomposed into the 128 square. The machines keep their size, and only the space between them shrinks. The generator stands at 52 in, and the Breaker and the Door at 26 in. The plan passes part 7's tests: the Breaker is 1.79 s from the gate, the least gap is 12.2 and the widest corner is 50.4° of 51.2°.
- **The FloodMasts** stand at 35 in, 9 behind the Door's line. Ray-tested from the game's camera, no mast crosses the Door from the way in, the spawn or the gate.
- **Also re-laid:** the floors, in 32-stud blocks to the back wall; the walls; 6 pylons; the transformers.
- **Where:** AR16, "Delivery 3"; `build/handoff/Base/` (`plan.json`, `manifest.json`, 8 meshes, 11 pictures, 22 looks); `tools/blender/base_kit.py`, `base_plan.py` (`fit()`).
- **Open:** Faber's install (`Plots.Drawn` = 8, kit_take, the uploads), then research's verdict in the game.
- **For:** Faber, then research.

### 2026-11-17, 14:37. TR40: Regen in bursts (Faber)

- **What changed:** a lead heals one burst every 8 s from its summon, always, half of what 8 s at its rate healed, and Base Regen is 1. A green number and a pop at the chest show it. The sheet and the cards read the burst. Combat Power's Regen weight is halved. Home's heal on the plot is unchanged.
- **Also:** a capture's freeze of the effects now holds (FighterController wrote it every frame). The fight cases turn the camera toward a test Shade first, so a fresh playtest passes them all (553 of 553).
- **Where:** TR40, "Built"; `Config.Stats.Regen`, `Rules.Stats.Burst`, `Rules.Fight`, `FightService`, `Effects.RegenPop`, `Rules.Sheet`.
- **Open:** research's verdict from `build/scratch/faber/stills/burst-phone.png` and `burst-crowded-phone.png`, and its check of `tools/balance/` (sim.py still heals at 4 a second, continuously). Ten Base checks wait for the plan's re-lay.
- **For:** research, then the director.

### 2026-11-17, 09:01. AR15: the Festival Door's ring tunnel, installed (Faber)

- **What changed:** Modulo's ring tunnel is in the game. Its four rings turn always, at their plan's rates, and the core lights by whether a ground is open, capped at 0.6 of the phase's bloom threshold so it never burns white. The way fits the front ring's opening, and the name is on the plate. The six meshes and the atlas pair are under the group, all Approved.
- **The Door's collision is Default:** the precise one shut the ring's opening.
- **Where:** AR15, "Faber's install: the ring tunnel"; `Config.Lighting` (`CoreBloom`), `Config.World` (`Grey.Door`), `BaseController` ("spins"), `WorldService`, `DoorService`, `SignsController`, `src/storage/BaseKit.rbxm`.
- **Open:** research's pass, from the phone stills in `build/captures/ar15/`. Its two findings: TR24's screen sign repeats the plate's name over the Door, and the shut core barely differs from the open one. Then the director's own look on a phone.
- **For:** research, then the director.

### 2026-11-16, 23:47. AR11: Watt's eight clips, delivered (Modulo)

- **What changed:** Watt's clips, Idle, Combo, Ground Wire (butt-down, research's pick), Hit, Down, Up, Reveal and Work, keyed on R6 with his spear as a joint.
  - The Combo's hits each break his outline, after the director's ask to look at Anime Vanguards' units.
  - A hand on the shaft no longer jumps.
- **Where:** `build/handoff/Watt/clips/`; `tools/blender/watt_clips.py` (with a `film` mode, the clips in motion); AR11, from "The animation comparison" to "Delivery 4".
- **Open:** Faber's install, with the markers and the bay post's place (AR11, "Delivery 4"); Ground Wire's look; the director's acceptance.
- **For:** Faber.

### 2026-11-16, 21:17. AR6: batch 3's three fixes, in colour (Modulo)

- **What changed:** research's three fixes, in eight pictures.
  - Common iron (the Iron Greataxe, Staff and Dagger) and the Common Tome's boards (Iron and Bronze) are toned to a mid tone with a light edge.
  - The Bronze Greataxe and Dagger take a polished streak.
  - Ryuukou's spire is an unlit crystal in three tones, in a cluster of four.
  - The other 112 render byte-identical.
- **Where:** AR6, "Research's three fixes, in colour"; `build/handoff/UI/gear/`; `tools/blender/gear_icons.py` (`lift`, `glint`) and the five kinds' scripts.
- **Open:** research's look, then the 120 go to Faber for upload. Batch 1's two iron swords measure as dark, and the same flag is ready if research wants it.
- **For:** research, then Faber.

### 2026-11-16, 21:01. AR6: batch 3 in colour, the 120 in their slots (Modulo)

- **What changed:** the eight class weapons in colour, as flat pictures for the gear slots, each with its class's mark on the bottom cut. The Tome's boards are a dark leather by rarity over cream pages, and the Codex's covers a pale parchment. `gear_icons.json` keys a weapon by its kind ("Sword" and "Short Sword" were "Main Hand" and "Off Hand") and gives each class's pair under `hands`.
- **Where:** AR6, "Batch 3 in colour"; `build/handoff/UI/gear/` (`gear_<kind>_colour.png`, `images/`, `gear_icons.json`); `tools/blender/gear_icons.py`; the asset log, with batch 2's row, logged late.
- **Open:** research's verdict, then the 120 and the json go to Faber for upload under the group.
- **For:** research, then Faber.

### 2026-11-16, 20:50. AR6: batch 3, the eight class weapons in grey, with their fixes (Modulo)

- **What changed:** the Great Axe, Shield, Staff, Tome, Dagger, Throwing Blades, Crystal Baton and Codex, fifteen each in their rarity's threes. Each set keeps its column, and each Legendary has one new form. Each class's pair stays apart: the Staff's open ring and the Baton's crystal, the dark Tome and the pale Codex, one fang and a fan of three. Research's four fixes are drawn: the Codex reads as a book, the Staff's ring at 32 pixels, Bunkou's fork, and Rinkou's ribbons from the head. Three names are new: Tenmon, Kontengi and Bunkou.
- **Where:** AR6, "Batch 3" and "Batch 3's fixes"; `build/handoff/Gear/batch3_sheet/` and `build/handoff/Gear/<kind>_sets/`; `tools/blender/gear_<kind>_sets.py`, the new long-weapon parts in `gear_parts.py`, and `batch3` in `gear_batch_sheet.py`.
- **Open:** research's pass and the three names' search, then the colour pass and its own content check (Rinkou's ribbons never red).
- **For:** research.

### 2026-11-16, 20:33. TR30: the generator's stages (Faber)

- **What changed:** the Void Mill stands at the stage of a machine at the base's ceiling: I at base level 1, II at 2, III at 3 (research's answer (a)). AR19's 23 meshes are uploaded under the group. Each plot lays the three stages from `plan.json`'s swap table and shows its owner's. A pinion follows its wheel's angle, and the mark turns to its stage's degrees.
- **Where:** TR30; `Rules.BaseLevels` (`Stage`, `GeneratorStage`), `WorldService`, `BaseService`, `BaseController`; Studio's `BaseLevel`.
- **Tested:** type check, logic 23,227/0, the world report, the swap from the server at base levels 1 to 3. The motion and the new self-test checks are NOT VERIFIED (the screen's locked).
- **Open:** the stage's moment at a level-up; the other machines' stages.
- **For:** research and Modulo, at the stills.

### 2026-11-16, 20:25. TR29: the Tower's run in grey (Faber)

- **What changed:** the ring behind the base starts a run: a floor a foe, of the pool at its floor's level, in its enemy look. Health is carried, with no heal between floors and a cap within one. The lead, its stars, its Regalia and the gear are frozen. The fall or stepping off ends the run, its ledger granted once, with the record and the results. A crash's run ends at the next join.
- **Where:** TR29; `Config.Tower`, `Rules.Tower`, `TowerService`, `TowerController`, `TowerScreen`; the self-test's `TowerCases`.
- **Tested:** logic 23,212/0 and the Tower's case 43/0 at 60 fps. The whole suite is NOT VERIFIED (the PC locked during it).
- **Open:** research's fit and feel line are in (2e57359), for Faber to carry into Config.
- **For:** research.

### 2026-11-16, 19:35. TR28: the inventory in AR18's C (Faber)

- **What changed:** the belt, the six kinds, the grid with its arrows, ticks and dims, the card over the Voidkin's half with Equip and Take off, chests opened 1 or 50, the salvage; on research's answers, "n / 300 in the bag" under the grid and Open N at the bag's room. Research's fits are in Config.
- **Where:** TR28 (a52fb94, f90fb6f); `src/client/UI/`'s inventory.
- **Tested:** logic and flow. The 11 layout checks are NOT VERIFIED (the screen's locked).
- **Open:** the 120 gear pictures in its cells.
- **For:** research.

### 2026-11-16, 20:00. AR19: the Void Mill's Stages II and III as kit pieces (Modulo)

- **What changed:** Stages II and III are kit pieces, cut from AR19's fixes 1 to 3:
  - each stage's still body;
  - the twin wheel, with its spur gear;
  - a pinion on each side, made meshed and turning at -2.4;
  - each stage's eight steps and its demand mark.
- **The plan:** it carries the swap's table, each stage's pieces with their places and motion. Stage I's pieces are untouched. The collision on the ground is Stage I's, with the sill 0.5 nearer the gate. The content check passed.
- **Where:** AR19, "Stages II and III as kit pieces"; `build/handoff/Base` (`meshes/Generator2*`, `meshes/Generator3*`, `manifest.json`, and `plan.json`'s `machines.generatorStages`); `tools/blender/base_mill.py`.
- **Open:** Faber's upload, install and motion. Then research's pass, with the check's note on the dynamos' real-world look.
- **For:** Faber, then research.

### 2026-11-16, 19:27. AR6: batch 2 in colour, the 120 in their slots (Modulo)

- **What changed:** the eight shared kinds in colour, in batch 1's slots and frames. Cloth has its own colours by rarity, with Rare and Epic dark so the frame carries the rarity. Glove leather is charcoal, with knuckle plates. Every body piece is dark-lined inside. Yoake's wing rises over its two lames. Hoshikuzu's stars are solid, on a line.
- **Where:** AR6, "Batch 2 in colour"; `build/handoff/UI/gear/` (`gear_<kind>_colour.png`, `images/`, `gear_icons.json`); `tools/blender/gear_icons.py` and the batch 2 `gear_<kind>_sets.py`.
- **Open:** research's verdict. Then the 120 go to Faber for upload and the slots, after Kaikou's catalog search.
- **For:** research, then Faber.

### 2026-11-16, 19:08. AR6: batch 2, the eight shared kinds in grey, with their fixes (Modulo)

- **What changed:** Shoulders, Chest Armor, Gloves, Bracers, Boots, Cloak, Amulet and Earring, each in three designs at each rarity (120). Each kind has one view it reads in at 38 points. The sets keep one column across every kind, and each Legendary has one new form. The Earring's fifteen serve both earring slots. After research's verdict, the Shoulders are a mantle with the collar leading and the lames hanging as arms; no earring is a hoop alone; every cloak shows a collar or a clasp; Isaribi is Kaikou.
- **Where:** AR6, "Batch 2" and "Batch 2's fixes"; `build/handoff/Gear/batch2_sheet/gear_batch2_sheet.png`, with `<kind>_sets/` for each kind; `tools/blender/gear_parts.py`, `gear_<kind>_sets.py`, `gear_batch_sheet.py`.
- **Open:** research's pass on the fixes; then colour and frames, as batch 1's.
- **For:** research.

### 2026-11-16, 17:40. AR20: C's paint and skies, for Faber (Modulo)

- **What changed:** the base kit out of grey-violet (steel, girders, concrete, deck, floors); the Tower asleep, the far shards and the outcrops painted violet for distance; the ground between plots lifted from #1A1D2E to #6E7290; the base's and the Strip's own dusk and night skies; the Strip's own paving, lifted from Lantern Row's.
- **Where:** AR20, "Modulo's paint and skies for C"; `build/handoff/Base` (maps, `sky/`, `lighting.json`, `plan.json`, the Tower's mesh); `build/handoff/Strip`; `tools/blender/base_light.py`.
- **Open:** Faber's uploads and captures, then research's pass in the game.

### 2026-11-16, 17:22. AR20: the base with no mist, less somber, round 1's takes (Modulo)

- **What changed:** today's look and three takes for the base and the map round it, at day, dusk and night: A, the fill and the exposure lifted; B, the yard re-toned out of grey-violet, the glow brighter, the far shards and the Tower asleep painted for distance; C, B under lighter skies. Each take's numbers are in Roblox's terms.
- **Where:** AR20; `build/handoff/Base/base_mood.png` and `base_mood_shard.png`; `tools/blender/base_mood.py`.
- **Open:** research's pick, then Faber sets it. Round 2 (the empty lots, C's turned fill) waits on a go to render. The run was stopped at 17:20, the PC low on memory.

### 2026-11-16, 16:55. AR19: the Void Mill's Stage I as kit pieces (Modulo)

- **What changed:** the generator in the base kit is the Void Mill's Stage I. Generator stands still; GeneratorWheel turns on its axle 10 up; GeneratorArc1 to 8 are the gauge's still steps behind the band, shown or hidden by the generation; GeneratorDemand turns about the axle by the demand's share, since the rail is an arc. GeneratorRotor and GeneratorRing are gone.
- **Where:** AR19, "Stage I as kit pieces"; `tools/blender/base_mill.py` (new, also the direction sheet's source); `build/handoff/Base`.
- **For Faber:** the install, the turn's sense and the collision in the manifest's notes. The upload check passed.

### 2026-11-16, 15:37. AR19's fixes 1 to 3 within A: the Void Mill (Modulo)

- **What changed:** the gauge is the wheel. The buckets light from the well up the gate's right to the collector's shoe as the generation climbs, against a bone diamond with a lit pip on a rail outside the rim for the demand, and the dial is gone. A concrete sill, a trestle, the front bearing and the collector arm stand in front; the band is deeper, the hub filled and bolted. Stage II shows its gear and a housed dynamo, Stage III the casing and two.
- **Where:** AR19, "Fixes 1 to 3 within A, delivered"; `tools/blender/generator_directions.py` (`A` mode); `build/handoff/Base/generator/generator_A_fixes.png`.
- **For research:** the pass. **For Faber, later:** the lit arc is a still glow piece cut in steps; the diamond slides with the demand.

### 2026-11-16, 15:22. AR17's fixes 1 to 3: the Strip (Modulo)

- **What changed:** the crack ranked: the Strip's crack brightest and widest, the branches to the gates thinner and deep violet. The crossing's well is full black, its five cracks gone. The great shard's light is 2.5 times the kit's, not the shard bigger: from the farthest gate at the largest new size (372 from the crossing) it reads at 5.0 to 1 on the haze, from 3.7.
- **Where:** AR17, "Fixes 1 to 3, delivered"; `tools/blender/strip_kit.py`, `strip_plan.py`; `build/handoff/Strip/`. The look's bloom no longer wraps round the frame (`lantern_row_look.py`).
- **For research:** the pass. **For Faber:** at the install, CrossingShard's `glowStrength` is 6.0 against the kit's 2.4; the plan moves with the base's new size.

### 2026-11-16, 15:11. C's inventory fixes 1 to 3 (Modulo)

- **What changed:** C's porcelain warmed to bone, a step darker than first tried. The bag opens at 0.31 of a white screen's light, 4.2 times the Row at night (paper was 7.5), measured beside Faber's TR24 captures. Its coloured words deepened to hold 4.5 to 1. The empty bag is its line alone, and every kind's chip says its word, with the counts gone from the chips.
- **Where:** AR18, "Fixes 1 to 3, delivered"; `tools/blender/inventory_directions.py`; `build/handoff/UI/inventory/` (`inventory_night.png`, `inventory_C.png`, the glance).
- **For research:** the pass. **For Faber:** the feasibility read (fix 4) takes C as it stands now.

### 2026-11-16, 15:01. The generator, three directions (Modulo)

- **What changed:** three directions for the generator's Stage I, each with its growth to Stages II and III, at about 30 studs (today's is 26): A, the Void Mill, a wheel turning in the well; B, the Beam Pump, a lit column under a rocking beam; C, the Governor, three lit weights flying over a yellow demand ring. Each from the spawn, from 30 studs and from the side; B and C also at low and high generation.
- **Where:** AR19; `tools/blender/generator_directions.py`; `build/handoff/Base/generator/` (`generator_glance.png` first).
- **For research:** the verdict and the pick. The content check passed all three, with three conditions for the finish in AR19.
- **For Faber, after the pick:** the chosen direction's moving parts come as pieces of their own; its export and the motion wait on the pick.

### 2026-11-16, 14:24. The mobile inventory, three directions (Modulo)

- **What changed:** three phone-landscape directions for the bag in the Voidkin screen, each in three states (a full bag with a long Legendary name, a Healer choosing a Warrior's sword, an empty bag): A, Lacquer, the ledger; B, Nocturne, the ring; C, Porcelain, the case, the one on research's brief. Combat Power's change sits under the item's name in all three.
- **Where:** AR18; `tools/blender/inventory_directions.py`; `build/handoff/UI/inventory/` (`inventory_glance.png` shows all three at phone size).
- **For research:** the verdict on composition and usability. A and B leave the brief on purpose, each saying why and what it costs. **For Faber:** the feasibility read.
- **Open:** the tabs are the bag's kinds as `docs/design.md` has them; the brief's list waits on the nine points.

### 2026-11-16, 02:50. AR17's kit, in the void's own (Modulo)

- **What changed:** the director stopped the lantern line down the Strip (read between 02:39 and 02:45 by the clock: ground lanterns are the first ground's alone, and the map wants its own look). The kit was made again from the void: a crack of light in the stones to a great split shard over the crossing, shard lamps, sealed gates, outcrops. Research's bold thing of 02:18 is set aside by that word.
- **Where:** AR17, "The kit, in the void's own"; `tools/blender/strip_kit.py`, `strip_plan.py`; `build/handoff/Strip/` (meshes, `manifest.json`, `plan.json`, eleven pictures); the asset log.
- **For research:** the verdict on the pictures, the new feel line, and the register's line for the director's word.
- **For Faber, after that verdict:** the install, which needs a third kit laid; the list is in the entry.
- **Open:** the director has four pictures and hasn't spoken on them. Nothing was seen in Studio.

### 2026-11-16, 02:40. Day in the world's turn, under Modulo's sky (Faber)

- **What changed:** the world has a day, on the director's word ("we need a day time") and pick. Day, dusk and night go round on the server's one clock, 30 minutes a turn: 18 of day, 5 of dusk, 4 of night, with a minute's crossing between each. By day the kit's glow and the street's lights dim to a share and come up at dusk. Modulo's Day sky is uploaded, Approved and played with his seeds: a clear azure day with a thin haze.
- **Where:** `Rules.Night` (the turn as an order of looks), `Config.Lighting` (`Cycle`, `Phases.Day`), `LightingController`; TR23; the asset log. The debug jump takes "Day", "ToDusk", "ToNight" and "ToDay".
- **Checks:** type check 0 new; logic 9,936; the whole suite 2,202/0 at 60 fps.
- **For research:** the verdict in the game, the day and its crossing into dusk. The director's mist word to Modulo ("a bit to much atmosphere") may also mean the dusk haze; I don't know which phase they saw.
- **Open:** one ~90 ms frame in two of four day-to-dusk crossings, not attributed, for the phone run to watch.

### 2026-11-16, 02:15. The Day sky, and AR17's blockout (Modulo)

- **What changed:** our own Day sky, on the director's word ("we need a day / dusk sky box"): six painted faces, a clear azure day with a thin warm line on the horizon and two-tone cumulus, the sun painted where the game's light stands. A Day block of seeds in `lighting.json`. Dusk and Night are untouched. And AR17's blockout from the game's camera, for research's verdict.
- **Where:** `build/handoff/LanternRow/sky/` (`LanternRow_SkyDay_*.png`, `lighting.json`, `lantern_row_sky_day_sheet.png`); `tools/art/sky_day.py`. `build/handoff/Strip/`; `tools/blender/strip_block.py`. Records: AR5, section 2b; AR17, "The blockout".
- **For Faber:** the six faces to upload under the group and play in `Phases.Day`, with the engine's sun disc at 0. The block's numbers are seeds moved from yours toward warmth; tune them by playing.
- **For research:** the Day sky's pass, and AR17's verdict.
- **Open:** the director said of the first sheet "a bit to much atmosphere imo like that mist is a bit to much"; the faces were painted again with less, and the second sheet has no word yet. Whether that word also means the game's own mist at dusk is with Faber and research. Nothing here was seen in the engine.

### 2026-11-16, 01:51. The base installed: AR16, the Door's festival and the sleeping Tower, AR15's last machines (Faber)

- **What changed:** each plot's base stands as Modulo's star, as its owner's save has it: the bays it opened awake and the rest asleep, the battery a bank lit by its charge, the great ring and the Training crown turning, the Door's way showing the festival under five paper lanterns, and a sleeping Tower behind the back corner on the crossing's side. The spawn faces the Breaker, and the machines' plates never cover each other.
- **Where:** AR16, "Faber's install"; AR15's status; the asset log's three rows of 2026-11-16; `docs/engineering-plan.md`, the world contract; `src/server/Services/Main/WorldService.luau`, `BaseService.luau`, `src/shared/World/Kit.luau` (`Kit.Toward`), `src/client/UI/World.luau`.
- **Open:** research's verdict in the game; the Door's name over the arch, my next piece; a fighter on the Training pad gets one look the first time it trains.
- **For:** research, and Modulo for the look in Studio (`build/captures/ar16/`).

### 2026-11-16, 01:22. The Door says festival, and a sleeping Tower (Modulo)

- **What changed:** on the director's word that the portal and the Tower must say where they lead, and research's calls. The Festival Door's way shows the festival through it (warm white rising into cyan, lantern lights down a street) and a string of paper lanterns hangs across its arch. One sleeping Tower stands behind each plot's back corner on the crossing's side, a rose shard over its tip.
- **Where:** `build/handoff/Base/` (`Door.json`, `DoorWay.json`, `TowerSleeping.json`, `Base_Kit_*`, `plan.json`, `base_1_door.png`, `base_1_tower.png`); `tools/blender/base_kit.py` (`way`), `base_machines.py`, `base_plan.py`. Records: AR15, section 6; AR16, "The sleeping Tower".
- **For Faber:** `Door`, `DoorWay`, the kit's atlas pair and the Tower's placement are final, for one install. `DoorWay` wears the kit's pictures now, its tint white. The name over the arch is yours.
- **For research:** the verdict in the game, with AR16's.
- **Open:** the director has the pictures and hasn't spoken on them.

### 2026-11-16, 00:26. TR21's rules and the command view, parked; TR22's rule (Faber)

- **What changed:** the base's level and each machine's are bought once each on the server, a repeat never charged twice. The battery's cap comes from the base's level everywhere. At home, the Base tile lifts the camera over the base, a plain chip on each machine and bay, with the base's level at the top. The showcase stands the player's pick, else their strongest.
- **Where:** TR21, "The rules and the blockout"; TR22, "The rule"; `docs/engineering-plan.md`, "The base's levels" and "The showcase at the gate"; `src/client/UI/BaseView.luau`.
- **Open:** parked at research's order. The take is `build/captures/tr21/command_view_desktop.jpg`. The phone's look waits for the first session's run, since Studio's tools can't take that camera at phone size. TR22's world parts wait for AR16's places.
- **For:** research's verdict on the take.

### 2026-11-16, 00:26. The reveal's plate installed (Faber)

- **What changed:** after the reveal, a low plate under the name says what the break gave, over the held frame undimmed. Its four images are up under the group and Approved.
- **Where:** AR12, "Faber's install"; `src/client/UI/Reveal/Plate.luau`, `Config.Reveal.Plate`.
- **Open:** research's pass on the four stills at a phone's size (`build/captures/ar12/`). In my look, Mythical's pip stays a diamond at real size, the content check's condition.
- **For:** research.

### 2026-11-16, 00:26. The stats as a plain list, and Combat Power's weights (Faber)

- **What changed:** a Voidkin's stats read as a name and a number, two a row under quiet captions, with no tap and no description, on the director's word. Combat Power takes research's weights, so the higher number wins 97% of same-level duels.
- **Where:** TR17, "Fix 10 and the plain list"; `Config.Stats.Power.Weights`, `Rules.Stats`, `Rules.Sheet`.
- **Open:** research's pass, at the first session's run on a phone.
- **For:** research and the director.

### 2026-11-16, 00:31. The base as a star, void machines, and what it will wake, asleep (Modulo)

- **What changed:** AR16's deliveries 1 and 2, and AR15's section 5. The generator stands at the plot's heart in a ring of current, the machines on a star round it, about 36 studs apart, with a clear way in. The generator, the Void Breaker, the bays, the Festival Door and the Training machine are void machines; the rest keeps the yard's look. Bays 3 to 6 and the Forge's, the Condenser's and the Lab's places lie asleep, low and dark, on dead lines. The building site is gone, and every base hull is 0.11 studs.
- **Where:** `build/handoff/Base/` (`plan.json` with `layout`, `machines` and `current`, `manifest.json`, `maps/`, `meshes/`, `base_1_*.png`); `tools/blender/base_machines.py`, `base_ink.py`, `base_kit.py`, `base_plan.py`; `tools/blockout/` (a view of a handoff with Studio and Blender closed).
- **For Faber:** delivery 2's places replace delivery 1's, and its amendment's four meshes and two picture pairs replace delivery 2's (`BaySleeping`, `SleepingStone`, `Bay`, `Training`; `Base_Yard`, `Base_Wings`); no place moved. Seven floor picture pairs and the kit's atlas pair; every hulled mesh published again; new pieces `GeneratorRing`, `Door`, `DoorWay`, `Training`, `TrainingCrown`, `BaySleeping`, `SleepingStone`; four new floors on meshes already published. The records list the rest (AR16, "Delivery 1" and "Delivery 2"; AR15, section 5).
- **For research:** one verdict in the game after the install.
- **Open:** the director hasn't spoken on the tighter star or the sleeping places. Their word on the Door and the Tower, which must say where they lead, is research's call in AR15 and AR16 and Modulo's next build.

### 2026-11-15, night. The base installed, and the bare lots (Faber)

- **What changed:** AR14's deliveries 4 to 6 and AR15's Breaker, bay and generator stand on the plots from the base kit (27 meshes and four pictures under the group; `src/storage/BaseKit.rbxm`). A chamber glows and holds its shard while it breaks, and the generator's rotor turns by its owner's generation.
- **The director's word:** a plot is a bare lot until its player arrives. The base is built on arrival and cleared on leave (`WorldService`, `Markers.Report`; the world contract in `docs/engineering-plan.md`).
- **Where:** AR15, "Faber's install".
- **Open:** the look is reopened (AR16), so this stands in the dev build until AR16's verdict. The battery's rack isn't installed.
- **For:** research and Modulo. AR16's layout comes back to me for the front row's positions.

### 2026-11-15, night. The reveal's plate, its images (Modulo)

- **What:** the plate after the reveal is cut for the build, on research's three calls: the low plate under the name's line, the fourth line's three colours, the shard's mark in silver. The plate is the kit's panel in Eclipse; four images are new: a rarity's pip and its facet, a star, the shard in silver.
- **Where:** `build/handoff/UI/hud/colour/` (`images/RarityPip.png`, `RarityPipFacet.png`, `Star.png`, `ShardSilver.png`, `reveal_card_images.json`, `reveal_card_images.png`); the record is AR12, "The reveal's card, its images". `tools/blender/reveal_card_images.py`.
- **Open:** Faber's upload and build, with his say on the cost; research's pass on his still.
- **For:** Faber, research.

### 2026-11-15, night. The battery's model, a bank (Modulo)

- **What:** the battery has its model, as research's answer asked: a low rack of eight seats with a copper bus bar, and a cell as its own piece. Two cells at level 1, four at level 2, eight at level 3; the builder lights them one after another as the charge rises, so the bank is its own meter. 372 and 120 triangles.
- **Where:** `build/handoff/Base/` (`meshes/BatteryRack.json`, `meshes/BatteryCell.json`, `plan.json`'s `machines` and `machines.battery`, `base_1_battery.png`); the record is AR15, section 4. `tools/blender/base_machines.py`.
- **Open:** Faber's publish and install; research's verdict in the game and on the count; the Training machine and the Festival Door next.
- **For:** Faber, research.

### 2026-11-15, night. The generator's model (Modulo)

- **What:** the generator has its model: a dynamo on the stand-in's footprint, a meter of rising bars on both faces, and its rotor open to view between two end bells under a yoke of three bushings. The rotor is its own piece, so the builder turns it, faster as the plant makes more. 750 and 176 triangles.
- **Where:** `build/handoff/Base/` (`meshes/Generator.json`, `meshes/GeneratorRotor.json`, `plan.json`'s `machines`, `base_1_generator.png`); the record is AR15, section 3. `tools/blender/base_machines.py`.
- **Open:** Faber's publish and install; research's verdict in the game, and its size beside the Breaker; the battery as a bank next.
- **For:** Faber, research.

### 2026-11-15, night. The reveal's card in Eclipse (Modulo)

- **What:** delivery 3's two sheets of the card after the reveal, redrawn in the picked palette: the room is Eclipse's neutral dark under a pale rim, a Voidkin kept reads in silver, and the rarity's light is the only colour on the screen. Nothing else moved.
- **Where:** `build/handoff/UI/hud/colour/eclipse_reveal_card.png` and `eclipse_reveal_card_offer.png`; the record is AR12, "The reveal's card, in Eclipse". `tools/blender/reveal_card_vivid_sheet.py`, with `eclipse`.
- **Open:** research's verdict (the plate under the name, the fourth line's colours, the shard's mark); then the images for Faber.
- **For:** research.

### 2026-11-15, night. The showcase's plinth (Modulo)

- **What:** TR22's plinth has its model, in the base kit: `Showcase`, three eight-sided steps with a line of light under the top one, a ring round the Voidkin's feet and four low lamps; 220 triangles. It stands on the gate's right, across 14 and 4.9 in, where the Strip sees it beside the Breaker, with one light.
- **Where:** `build/handoff/Base/` (`meshes/Showcase.json`, `plan.json`'s placements and lights, `base_1_show.png`, `base_1_shown.png`); the record is AR14, "Delivery 6". `tools/blender/base_show.py`.
- **Open:** Faber's publish and install with TR22 (the Voidkin, its turning, its Combat Power); research's verdict; a rarity colour on its lights, if research wants one.
- **For:** Faber, research.

### 2026-11-15, night. A bay's model (Modulo)

- **What:** an extraction bay has its model, one for all six: a steel deck on the stand-in's pad, and on its outer side an open frame with a copper collector ring behind the worker. Its light is a second piece in one pale swatch (`BayHalo`), which the builder shows in the worker's rarity colour while a worker works there (TR22, on the director's word of about 22:04). 812 and 144 triangles.
- **Where:** `build/handoff/Base/` (`meshes/Bay.json`, `meshes/BayHalo.json`, `plan.json`'s `machines`, `base_1_bay.png`, `base_1_bays.png`); the record is AR15, section 2. `tools/blender/base_machines.py`.
- **Open:** Faber's publish and install; research's verdict in the game; the bay's own level in its look; the showcase's plinth next.
- **For:** Faber, research.

### 2026-11-15, night. The Void Breaker's model (Modulo)

- **What:** the Breaker has its model, in the base kit's language: a steel housing on the stand-in's footprint with the current running in yellow, a gantry over it, and a cage a chamber holding a shard between two copper points under a cyan lamp. Three pieces, so a chamber lights by its own state: `Breaker`, `BreakerChamber`, `BreakerWaiting`; 1,588 triangles a plot.
- **Where:** `build/handoff/Base/` (`meshes/Breaker*.json`, `plan.json`'s `machines`, `base_1_breaker.png`, `base_1_strip.png`); the record is AR15, section 1, with Faber's footprints. `tools/blender/base_machines.py`.
- **Open:** Faber's publish and install; research's verdict in the game; a picture of its own and the break's motion at the finish; a bay next.
- **For:** Faber, research.

### 2026-11-15, night. The base under construction on its whole plot, and Power's bar cut (Modulo)

- **What:** the director's three words on the base, to Modulo: at 21:10 "the base should be much much longer, it fine if some part a plain due to being low levels", at about 21:37 "the base must be that 200x200", at about 21:47 "at level 1 it rly need to look like it under construction". The power yard's wall stands on the plot's edge, 200 by 200. The lit court stays at the front's middle, and the ground round it is a building site: a tower crane with a plate over the next bay's foundation, three frames half raised, scaffolds, poured foundations on the lots the next levels open, stock, cable drums, a cabin, barriers, the wall's back corner not hung yet. 136 pieces, 32,280 triangles, 5 lights a plot. Before it, Power's bar was cut for the build in Eclipse: eight images and how they stack.
- **Where:** `build/handoff/Base/` (`plan.json` replaced; `Wings` with its two pictures, `WallHalf` and the site's eight meshes new; the court's and the yard's colour pictures changed; five pictures of the target); the record is AR14, "Delivery 4" and "Delivery 5". `build/handoff/UI/hud/colour/` (`images/Power*.png`, `power_images.json`, `power_images.png`); the record is AR12, "Power's cut images, in Eclipse". `tools/blender/base_kit.py`, `base_site.py`, `base_plan.py`, `power_images.py`.
- **Open:** Faber's one publish for both deliveries and the install; research's verdict in the game; levels 2 and 3, which finish the sites; the Breaker's model next (AR15).
- **For:** Faber, research.

### 2026-11-15, night. Watt's model delivered again: take A (Modulo)

- **What:** Watt as the director picked him, take A, with research's three fixes: the hair fanned back past the head with small pale ends, the collar's pink lining and the open vent between hair and coat, a pale sling and a planted spear with a pale grip and cap. Baked on R6: seven meshes, four maps, one atlas, 4,738 triangles.
- **Where:** `build/handoff/Watt/`; `tools/blender/watt_model.py` and `watt_sheet.py`; the record is AR11, "Delivery 3". It replaces the entry below: the first design's visor, wrench and sheet are gone from the folder.
- **New in the scripts:** what a sheet paints a layer off a block is cut into the block's face for the model (`watt_sheet.flatten`), so a painted coat costs no hidden faces and can't flicker. The bake has a `cpu` mode for when Studio holds the PC's memory.
- **Open:** Faber's install (the spear's joint, the held pose until his Idle exists, the glow's strengths untried in Studio); research's verdict in the game; his clips and Ground Wire's look.
- **For:** Faber, research.

### 2026-11-15, evening. Watt's model delivered (Modulo)

- **What:** Watt on R6 (AR11, delivery 2): eight rigid pieces, 8,532 triangles, one 1024 px atlas. The generator and its two coils ride the Torso. The visor is one hinge on the Head (up is its mesh, -100 degrees brings it down). The wrench is one piece on a Torso joint at its grip, planted ahead of his right side with no clip playing. Research's fix from the sheet is in: cream rolled cuffs, so the arms part from a dusk street.
- **What lights:** one glow mask; the coil caps and the gauge's needle (low at rest), the visor's lens and the jaw's inner walls (off at rest), each piece with its own strength and tint in the recipe. Untried in Studio.
- **Where:** `build/handoff/Watt/` (meshes, maps, `Watt.recipe.json`, `watt_model_sheet.png`), from `tools/blender/watt_model.py` on `watt_sheet.build(model=True)`. The record: AR11, section 2.
- **Checked:** research's verdict, competent; content check PASS for delivery (one atlas island turned on its note, then checked again).
- **Held the same evening:** research relays that the director rejects the design. Not for install; the clips aren't started (AR11, "Held").
- **For:** Faber, research.

### 2026-11-15, evening. TR18 built: the base as a power plant (Faber)

- **What:** the base runs on kW and kWh, built in grey:
  - the bays generate, and each machine draws its rating, with Auto or the player's split;
  - the battery covers what generation can't, to its 60 kWh;
  - infusion is now voltage, paid in kWh: Low halves a shard's time, High breaks it now;
  - the Training machine trains on the base's clock;
  - the generator's prompt opens the Power screen; the HUD's pill says generation against demand.
- **Where:** `Rules/Power`, `Rules/Breaker`, `Rules/Base`, migration 4, `UI/PowerScreen`; TR18, "Faber's build".
- **Open:** the self-test, the take at phone size, research's verdict in motion; two questions for research in the build.
- **For:** research, then the director.

### 2026-11-15, night. The dock's images delivered (Modulo)

- **What:** AR12's dock as three icons, in images for the build: the body, a tile's white layers in two sizes (the tile, its pressed twin, the sheen, the open rim, the open halo), one light and its glow, the three marks in ink, the pip. Research's two mark fixes are in.
- **Where:** `build/handoff/UI/hud/dock/` (`images/`, `hud_dock.json`, `hud_dock_images.png`, and `hud_dock.png` rendered again), from `tools/blender/hud_dock_sheet.py`. The record: AR12, "The dock's images, delivered".
- **Checked:** the stack of images matches the block's drawing (the numbers are in the record); content check PASS for delivery and upload; self-reviewed at phone size over both streets.
- **Open:** research's read of the two marks at 32 px; Faber's build; the upload.
- **For:** Faber, research.

### 2026-11-15, evening. TR17's retake and TR9's fade fix (Faber)

- **What changed.** The Voidkin screen has research's three fixes: the stage never stands empty on a switch, the Voidkin's name is over the stage, and the lead reads "Leading" with "Not while leading" under Send to work. Its top bar is in Roblox's band, a new `Band` layer any full screen can use (`Kit/Screen.luau`). The Breaker's chamber holds its next shard's words until the gold is gone, and the infusion's levels are Low voltage and High voltage.
- **A finding worth keeping:** a model fetched with `PreloadAsync` still draws empty for up to half a second the first time a viewport shows it. Drawing it ahead in a small viewport is what makes it ready (`VoidkinScreen/Figure.luau`, the wings).
- **Where it lives.** `docs/test-requests.md`, TR17, "The retake", and TR9, "The fade fix and the names". Evidence: `build/captures/tr17/retake*.jpg`, `build/captures/tr9/gold_fade_still.jpg`.
- **Then, the same evening:** the bag's five tabs stand whole (research's one fix on the retake), and the Breaker's pane has "Drop rates" one tap away, from a pure rule whose rows add to exactly 100% (`Rules.Odds.Rates`).
- **Open.** Research's pass on TR17's block and on Drop rates. The rail scrolls on phones under 366 pt tall. Voltage as time isn't built: it goes with TR18.
- **For:** research.

### 2026-11-14. Kirra's clips delivered (Modulo)

- **What:** AR10, delivery 3:
  - the clips: Idle, Combo (opening on its dash), Scarf Step, Reveal and Work;
  - three tail layers over the open set's Hit, Down and Up.

  Each draw is a reach straight up and back to the grip. The tail's links bend at most 22° each, and Work runs nine short steps a lap round its post.
- **Where:** `build/handoff/Kirra/clips/`, made by `tools/blender/kirra_clips.py`. The recipe in `build/handoff/Kirra/` now has each blade on a Torso joint. The record: AR10, section 4.
- **Checked:** the audit and the content check pass on all eight. Research's verdict: competent, no fix. The in-engine look at phone size comes at the install.
- **For Faber:** section 4's "For Faber, at the install": the kit's names, Work's post and its 6 studs, and the blend and dump at install. `models_offline --recipe Kirra` builds the recipe.
- **Time:** about 1 hour 40 for the clips, against Pip's 6 hours.

### 2026-11-13. The keeper's Signature re-delivered, option 1 (Modulo)

- **What:** the lantern is held high and out to the keeper's right through the hold, clear of the hat from every heading, then tipped over the top and slammed down beside your fighter. The timing and the markers stay.
- **Where:** `build/handoff/Lamplighter/clips/Lamplighter_Signature.json` with its pack, made by `tools/blender/lamplighter_clips.py`. The record: AR7 section 7, "Option 1 delivered".
- **Checked:** the ring is positive on every frame, and the content check passes. Its four conditions bind AR8's effect build.
- **For Faber:** re-save `NL_LamplighterSignature`. The camera's lift through the hold is the motion blockout's lever.

### 2026-11-13. AR8's kit delivered: the effects' meshes and textures (Modulo)

- **What:**
  - 21 meshes: two coils and each in six burn bands, a shell, a hoop with an upright band, a crescent, a column, three chips.
  - 19 images: strand, rise and rib ramps in four palettes for `MeshPart.TextureID`, opaque in their own colours; and, white for Beams and particles, a beam, tongues, a streak, a spark, embers, a glow and a flame.
- **Where:** `build/handoff/FxKit/`, with the recipe `fx_kit.json`, made by `tools/blender/fx_kit.py`. The record: AR8, "The kit".
- **Checked:** the content check passes all of it, the flame on its redraw. Its conditions on embers and flame are in the recipe. The self-review is at 64 px on both floors.
- **For Faber:** one upload batch under the group, then the player. Open there: whether a MeshPart showing its texture draws unlit.

### 2026-11-13. AR7 installed: the Lamplighter fights in its own rig, and its lantern goes out (Faber)

- **What:** the keeper wears Modulo's model and eight clips, at 1.5 scale.
  - It holds its Challenge as it spawns and fights in its Ready.
  - It walks at 5, research's tier 2. The time to first contact was measured, and 5 stays.
  - It falls into the Shade's burst with its pole and lit lantern left standing. The lantern gutters, goes out and goes to paper.
- **Where:**
  - the model: `tools/studio/Models/Lamplighter.luau`, which builds `src/storage/Lamplighter.rbxm`;
  - the rows: `Definitions/Enemies` (Rig, Enter) and `Definitions/Actions` (KeeperChallenge);
  - the numbers: `Config.Effects.Falls` and `Config.Combat.Keeper` (WalkSpeed, FadeSeconds);
  - the code: `Effects.LanternOut`, `FightService`'s `buildRig`, and `FightDefeat` on the bridge.
  The record: AR7, section 5.
- **Checked:** type check 0 new; logic 2432, offline and in Studio; the keeper's case 24/24 at 60 fps, under the phone emulator. The desktop suite is 849/851: the two misses are HUD cases outside this piece, fixed next.
- **For research:** the verdict in motion on `build/captures/ar7/`, with three things I see: Pip in front of the Challenge, the keeper at the frame's top, and a faint "Out".

### 2026-11-13. AR8 B5's replay: Haymaker slams a square and pins (Faber)

- **What:** Modulo's block clip plays in RookHaymaker's place. B5's grey square forms over the target through the hold, falls stretched, lands on Strike at its feet and squashes on Shock as two floor bars run out. It lies where it landed. Haymaker's strike pushes nothing (the pin, tier 2, signed). A's bracket returns with `Stamp.On` false.
- **Tier 1:** the hang's top is 6.4, not the scope's 8, because at 8 the square leaves a phone's frame.
- **Where:** `Effects.Haymaker`, `Config.Effects.Haymaker.Stamp`, `Definitions/Actions` (RookHaymaker), `stage_clips.py --source`. The record: AR8, "B5", "The replay built".
- **Checked:** type check 0 new; logic 2408; the new stamp case 18/18; the suite's timing cases pass at 60 fps.
- **For research:** the verdict in motion on `build/captures/ar8/b5/`, A beside B5.

### 2026-11-13. AR8 C's fixes, and B1 and B2 installed (Faber)

- **What:** the level-up's "Level N" now stands clear over the lead's head, white edged in the thread's blue. It slides aside, eased, from a pill or a toast it would cross. The toasts sit under the Electricity pill, inside the safe area. The column wears Modulo's picture, white at its peak and blue as it fades. Lantern Burst plays the coil, and Held Note the bold crest, veil and touch.
- **Found:** on a notched phone, world plates stood off their points toward the sides, because the viewport is the safe width and the layer is full-bleed. `UI/World` now maps through the top bar's inset from the layer's corner.
- **Where:** `UI/World`, `UI/Kit/Toast`, `UI/Layers`, `HudController`, `FighterController/Effects`, `Config.Effects`, `Config.Hud`. Ids are in `docs/asset-log.md`, rows 39 to 43. The record: AR8, "C's fixes, and B1 and B2 installed".
- **Checked:** the whole self-test, 793/793 at 60 fps; logic 2407.
- **For research:** one pass on `build/captures/ar8/c_b1_b2/` closes C, B1 and B2. Condition 4 and part 5 read there.

### 2026-11-13. AR8 C built: the interface (Faber)

- **What changed:** a press squeezes and springs back; a screen fades and grows in, and leaves in 0.8 of that, eased in; a toast slides in from the right edge. Credits and Electricity pop with a rising "+N" that counts, experience glints along the thread, and a level swells its badge. The level-up is a column of the thread's blue standing past the lead's head, sized by the lead, with a fainter sleeve over the body. A number grows with its hit's rung, and a hit of rung 7 or more sends the lower numbers aside.
- **Where:** `UI/Kit/` (Button, Screen, Toast, the new Pop), `HudController`, `FighterController/Effects`, `Rules.Hud`, `Config.Hud`, `Config.Effects.LevelUp`. The record: AR8, "C. The interface".
- **A lesson for the handbook:** a `Beam` takes its transparency only at its segments' joints, so with one segment a soft foot or a fade along it never shows.
- **Open:** research's pass in motion at phone size. The toasts past the phone's right edge and over the Electricity pill, at the next pass on the toasts.

### 2026-11-13. AR8 B1 and B2 delivered: Lantern Burst's coil and Held Note made bolder (Modulo)

- **What:** Lantern Burst's flame, let out. Three fat ribbons wind in round the Shades to one column and flare white on 70. Then they let go and climb off as a thread, gone by 93. Two small forked flames stay where the outer feet let go. Held Note's crest, veil and crackles are rimmed in a deep magenta, and the crest's strands are about two and a half times as thick, so the wave holds on a bright sky.
- **Where:** `build/handoff/Pip/fx/pip_burst.png`, with `pip_burst_art.json` and `pip_burst_art.png`; `build/handoff/Lyric/fx/`, the three pictures and `lyric_note_upload.png`. The scripts: `tools/blender/pip_burst_coil_art.py` and `lyric_note_art.py`. The record: AR8, "B1, the art sheet" and "B2".
- **Checked:** the content check passes on both, and research's pass on the sheets is competent.
- **For Faber:** one re-upload for the burst, with the same layout; `Config.Effects.LanternBurst.Burst` plays it as drawn, and the trail is unchanged. Three re-uploads for Held Note, with the crest and the veil turned a quarter as before. The asset log names the old id each retires. In your take, check the coil's foot leaving the Shade's head at 74 to 78 (condition 4), and whether the wind reads.
- **Open:** Faber's uploads and take, then research's pass in motion.

### 2026-11-13. AR8 A built: the hit by its rung (Faber)

- **What:** every hit holds, flashes and shakes by its rung. An ordinary blow is a 0.045 s flick of white. A signature is a 0.13 s held instant: the body flashed white and trembling, the camera rolled through it. The camera shake is trauma squared, from the player's own lead only. Haymaker's bars and the billboards of Lantern Burst and Held Note no longer draw a frame late.
- **Where:** the numbers are in `Config.Combat.Hitstop` and `Shake`, the rules in `Rules.Fight`, the screen's side in `FighterController`. The level check is `tools/studio/Audio/Loudness` and `Mixdown`. The record: AR8, "A. The hit".
- **Done:** logic 2368, the whole self-test 697/697 at 60 fps. Takes are in `build/captures/ar8/`, each beside its "before".
- **For research:** the pass in motion. The level check reads Legendary and Mythical 6 LU over the fight's loudest, Common to Epic level with it, and every true peak under −1.
- **Open:** research's pass. Then C, the interface.

### 2026-11-13. The Lamplighter's clips delivered (Modulo)

- **What:** the keeper's seven clips: Idle, Challenge, Ready, Walk, Swing, Hit and Signature. The lantern swings as a weight on its cord. The signature plants the pole and leans it out like a street lamp, its face comes up, then it wrenches the lantern high over its hat and slams it down by your fighter.
- **Where:** `build/handoff/Lamplighter/clips/`, made by `tools/blender/lamplighter_clips.py`. The record: AR7, section 4.
- **Checked:** the audit passes on all seven, and the content check passes. Research read them as competent, and says the raised wrench meets its fix.
- **For Faber:** the roles in `Config/Animations`, `Strides.LamplighterWalk` 4.94, and the keeper's walk near 5 (research's tier 2 yes; your take checks it). **Open:** not uploaded, and not in the engine. The fall is next for the keeper, after AR8's B.

### 2026-11-13. TR4 built: the reveal's ceremony in the engine (Faber)

- **What:** Modulo's reveal at every rarity, with research's sound cues, from the break's yes to the card. The skip lands on the held frame with the stamp.
- **Where:** the stage is `src/client/UI/Reveal`, the rules `Rules.Reveal` and `Rules.Sound`, the numbers `Config.Reveal`, `Config.RevealArt` and `Config.Sounds`. The record: `docs/test-requests.md`, TR4, "Built".
- **Done:** self-test 688/688, logic 2249, the world report sound, the place saved (256). The sounds are logged in `docs/asset-log.md`.
- **For everyone:** a new Sound waited about 0.3 s to load, so every sound came late, the fight's too. A bank of loaded Sounds fixes it (`FighterController/Sounds`).
- **Open:** research's verdict in motion, then its pass. The sounds stay provisional until the director's ear.

### 2026-11-13. TR3 closed: the HUD on the kit, both cards in Midnight (Faber)

- **What:** the HUD in the world on the kit, with the lead card at the director's picks (Midnight, the Ember bars, Builder Sans, the head over the frame) and the target's card built like it. Both levels are in gold.
- **Where:** the art is `tools/blender/lead_card_art.py`, which writes `build/handoff/UI/hud/lead_card/`. The config is `UIKit.LeadCard` and `UIKit.TargetCard`, written by `tools/ui/kit_config.py`. The code is `src/client/UI/LeadCard.luau` and `TargetCard.luau`, used by `HudController`. The record: TR3.
- **Done:** 32 uploads, Approved and the group's. Self-test 618/618, logic 1735/1735. Research's pass given, no fix left.
- **Open:** the director checks the HUD later, not as a gate (the director, 2026-11-13: "my approval is not required").

### 2026-11-13. The kit's three frames tinted (Modulo)

- **What:** Uncommon green, Rare blue, Epic purple on the kit's frames, the director's colours on the same shapes, so the uploaded ladder matches the reveal's. 14 of the kit's 89 images; the rest and `kit.json` are unchanged.
- **Where:** `build/handoff/UI/kit/images/`, made by `tools/blender/ui_kit.py`; the colours live in `ui_sheet.RARITIES`. The record: AR3, section 6.
- **For Faber:** upload the 14, then run `kit_config.py` with their ids. **Open:** not uploaded.

### 2026-11-13. The reveal's art sheet and engine parts delivered (Modulo)

- **What:** the reveal's art, past research's pass at competent: the six fixes, then three more. Its engine parts too: 28 images, the shard's 8 meshes, and `reveal.json`, the whole reveal written as rules. Rook's Reveal re-keyed, his head up out of the fold, with a `Name` marker.
- **Where:** `build/handoff/Reveal/parts/` and `art/`, and `build/handoff/Rook/clips/`, made by `tools/blender/reveal_art.py` and `rook_clips.py`. The record: `docs/asset-requests.md`, AR3, section 5.
- **Checked:** content check PASS. Laid from the files alone, the engine's frame sits within 0.6 to 2.3 (sRGB) of the art, except at the leak's peak: 6.0 at Legendary and 9.3 at Mythical, where UI can't add light.
- **For Faber:** the reveal TR, to `reveal.json`'s order. Rook's Reveal is new, so take your saved copy again. **Open:** not in the engine, nothing uploaded.

### 2026-11-13. The reveal's block-in delivered (Modulo)

- **What:** the Void Shard's one form for three grades, its four seams and four sizes; the reveal's beats for a Common and a Legendary, as strips and movies at phone size on Void Violet; the six rarities' read before the name; the larger frame's cut; layouts A and B, B picked.
- **Where:** `build/handoff/Reveal/`, made by `tools/blender/reveal_blockin.py`. The record: `docs/asset-requests.md`, AR3, section 4, "Delivered".
- **Times:** a Common splits at 0.55 s, its name at 1.57, its card at 2.15; a Legendary at 1.30, 2.32 and 3.40. The skip is open from 1.0 s on every rarity.
- **The director's word:** Uncommon green, Rare blue, Epic purple, used in the block-in; its costs to the kit are in the record.
- **For Quaestor:** the verdict and the register. **Open:** grey and stand-ins; nothing is in the engine. Made on Opus 5.5, from the shard's reshape on (Fable 5.2 before).

### 2026-11-13. Lantern Row's kit delivered, with its night (Modulo)

- **What:** the festival kit's 16 pieces as meshes on one colour and one glow atlas, ink in each mesh; the paving as lit modules and the square's floor, their pools painted; the paper's flipbook; a dusk sky and a night sky, six faces each; the Lighting numbers for both; the street's dressing plan (271 placements, 9 lights); the phone budget.
- **Where:** `build/handoff/LanternRow/` (`meshes/`, `maps/`, `sky/`, `manifest.json`, `plan.json`, three sheets), made by `tools/blender/lantern_row_kit.py`. The record: `docs/asset-requests.md`, AR5, section 2, "Delivered".
- **Measured in renders:** the lead 1.44 to 1.65 times what's round him, a Shade's edge 0.154 to 0.170, at dusk and at night, from both ends. The most within 220 studs: 196 pieces, 91,308 triangles, 8 lights.
- **For Quaestor:** the verdict, and three calls (the houses, the square's canopy, StallB's roof). **For Faber:** "For the builder" in the entry, after that verdict.
- **Open:** nothing is uploaded, installed or seen in the engine. A Shade's edge passes by a hair, and the engine's light decides it.

### 2026-11-12. The HUD's portraits and the critical's sweep delivered (Modulo)

- **What:** Rook's, Pip's and Lyric's portraits, cut to their rarity frame's mask in the full cut and the lead's card's; one silhouette for a Voidkin not yet made, in all six rarities; the critical number's sweep, a grey slice of speed lines the game tints amber.
- **Where:** `build/handoff/UI/hud/` (`images/`, `hud_art.json`, the sheet), made by `tools/blender/hud_art.py`. The record: `docs/asset-requests.md`, AR3, section 3.
- **For Faber:** "For the builder" in that section: Back, portrait, frame on one canvas; the sweep's place, size and tint.
- **Open:** research's verdict. Nothing is uploaded, in the engine, or seen moving.

### 2026-11-12. One number a body, on the crest (Faber)

- **What:** a flurry, one press's hits on one body, shows one number that counts up, for every action, and heals the same. The Held Note's number, hold and push on a body wait for its crest to reach it.
- **Where:** `Effects.Number`, `Effects.Running.Struck`, `FighterController` (`show`, `onHit`, `onHeal`), `Config.Combat.Numbers` (`Count`, `Pop`), with a new self-test case and checks added to the Held Note's two. The record: `docs/asset-requests.md`, AR4, section 10.
- **Open:** research's read of the take, then fix 3 (the width), research's own.

### 2026-11-12. Lyric's note in its art (Faber)

- **What:** the Held Note plays Modulo's art sheet. Each crest is a braid over a veil on an arc across the cone, and the rings flash on the Note. A struck body takes the crackle when the crest reaches it, in place of the spark, and a heal rises as a ring round the healed body.
- **Where:** `FighterController/Effects.luau` (`HeldNote`, `HealRing`), `Config.Effects.HeldNote`, with a self-test case. The three pictures are the group's uploads (`docs/asset-log.md`). The record: `docs/asset-requests.md`, AR4, section 10.
- **Open:** research's verdict on the take; then the rings' hot strength and the dusk check.

### 2026-11-12. A hit lands on its frame (Faber)

- **What:** a fighter struck mid-action no longer holds its clip on screen. A server hit that arrives before the screen reaches its beat moves the clip on to the beat first. Pip's burst now kills on its flame, where before the kill came 0.3 s ahead of it.
- **Where:** `Fight.CatchTo` and `FighterController` (`show`, `catchUp`), each with a case. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's verdict on the take.

### 2026-11-12. Pip's round 2 in the game (Faber)

- **What:** Modulo's round 2 of the Lantern Burst plays in the game: Pip is rocked back a step, and the flame stands up. Research's take of the burst killing two Shades shows two lanterns rising out of his flame.
- **Where:** the clip in the saved place (v188), and the picture's new upload in `Config.Effects.LanternBurst.Picture`. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's verdict on round 2. The kill shows 0.3 s before the flame (a hold mid-action, held on the client only), with two fixes proposed in the same section.

### 2026-11-12. The Shade bursts into light and paper (Faber)

- **What:** a fallen Shade's collar charges, then flares the coat's size on its Burst marker as the body goes out. A flame climbs, its paper rising after it, from Modulo's art by its table, untinted. The content check's capture closes its red item: nothing red after the hide, on dark and bright, ordinary and elite. A burst no longer stays in the world when its body leaves first or its clip stalls.
- **Where:** `Config.ShadeBurstArt` (from `tools/art/art_table.py`), `Config.Effects.ShadeBurst`, `FighterController/Effects.luau`. The record: `docs/asset-requests.md`, AR2, section 13.
- **Open:** research's pass. Pip's and Rook's billboards are drawn a picture late (`docs/polish-later.md`).

### 2026-11-12. Lyric fights, and her note holds (Faber)

- **What:** Lyric leads in the game, with her own clips and kit. The Held Note throws a grey crest on every half-beat: five touches, each hitting every Shade in her cone and healing her and her allies, and her clip never stops on one. On Down her stand leaves her hand and lies beside her, then comes back on Up. Up now plays on robe rigs too, and an area hit sparks on every Shade it touches.
- **Where:** `Definitions.Actions`, `Rules.Fight.InCone`, `FightService`, `Config.Effects.HeldNote`, `Config.Animations.Props`, `FighterController`, `src/storage/Lyric.rbxm`. The record: `docs/asset-requests.md`, AR4, section 9.
- **Open:** research's verdict on the replay, and the heal's seed; Modulo's art for the crest.

### 2026-11-12. Pip fights, and his lantern bursts (Faber)

- **What:** Pip leads in the game, with his own clips and kit. The Lantern Burst plays Modulo's art by its table: the lantern heats, is thrown to stop short of the target, and lets its flame out over a 5-stud area. Then it comes home dark and relights over the cooldown, the readout. His shots are a grey streak.
- **Where:** `Config.Effects.LanternBurst`, `FighterController/Effects.luau`, `Definitions.Actions`, `src/storage/Pip.rbxm`. The record: `docs/asset-requests.md`, AR4, section 8.
- **Open:** research's two judgements on the replay, with fresh eyes; the two rising flames on a kill; Modulo's look.

### 2026-11-12. The elite swings Attack every time (Faber)

- **What:** research's pick (a). The elite never plays AttackLeft, and the ordinary Shade still alternates. A new self-test case proves both. Condition 2's engine look passes.
- **Where:** `Config.Animations.Unmirrored`, `FighterController`'s `pick`. The record: `docs/asset-requests.md`, AR2, section 12.
- **Open:** research's taste note at the player-camera review; the bloom capture; Guard's and Lunge's blends before they go in.

### 2026-11-12. Haymaker's replay lights the ram (Faber)

- **What:** the ram's glow is on the clip's markers: 0, then 3 on Charge, 5 on the strike, back to 3, then 0 at Vent. The content check's engine looks passed with those bounds, and its owed headings are closed. The pose parity passes. A replay's freeze now holds the clip on its moment.
- **Where:** `Config.Effects.Haymaker.Glow`, `FighterController/Effects.luau`. The record: `docs/asset-requests.md`, AR1, section 7.
- **Open:** research's final in motion and its tune of the peak, the sound, fresh eyes, and Modulo's look on the replay.

### 2026-11-12. The elite's mask without its ties, in the game (Faber)

- **What:** the copy of the Brawler mask without its ties, uploaded for the group, rides the elite's Left Arm at the recipe's new centre. A self-test check holds it to the face's depth.
- **Where:** `tools/studio/Models/Shade.luau` (`ELITE`), `src/storage/Shade.rbxm`. The record: `docs/asset-requests.md`, AR2, section 9.
- **Open:** condition 9's contact sheet (Modulo).

### 2026-11-12. Rook in the game (Faber)

- **What:** Rook's eight meshes and four maps uploaded for the group, the rebaked glow mask included. His template is on R6 with the piston and tape joints. A Voidkin row's `Model` gives a lead its body, and his clips key both joints.
- **Where:** `tools/studio/Models/Rook.luau`, `src/storage/Rook.rbxm`, `FightService`'s `buildLead`, `Definitions.Voidkin`. The record: `docs/asset-requests.md`, AR1, section 6; the ids in `docs/asset-log.md`.
- **Open:** the glow's 0 to 10 and the engine look at 64 px wait for Haymaker's replay, with Modulo, research tuning the 10. The pose dump against the export goes with it.

### 2026-11-12. Lyric: five clips delivered (Modulo)

- **What:** Idle, Combo, HeldNote, Reveal and Work on R6. The stand and the two speakers are keyed on their own joints. Her reactions are the robe set, Pip's.
- **Where:** `build/handoff/Lyric/clips/`: a JSON a clip, `Lyric.clips.json` with the markers, and each clip's pack and notes. Made by `tools/blender/lyric_clips.py`. The record: `docs/asset-requests.md`, AR4, section 6.
- **Research's two fixes are in:** Combo's third hit hoists the stand clear and drives it down; the Reveal's pole stands beside her face. The audit and the content check pass on all five.
- **For Faber:** the robe set named in her definition, and the content check's engine conditions at the section's end. In the note, the mic's hot ring has to be stepped through at 64 px under the dusk grade.
- **Open:** research's read of the five packs. Nothing is uploaded, seen in the engine, or judged at real speed. The robe set's Down hasn't been seen with her stand.

### 2026-11-12. The UI kit's images delivered (Modulo)

- **What:** the kit as slices (panel, button, bar, thread), the six frames in two cuts, the five type gems, five class marks, four element marks, the coin, the bolt and the spark. A slice is white where a palette colours it, so a palette is a row of colours, never new images.
- **Where:** `build/handoff/UI/kit/` (`images/`, `kit.json`, the review sheets), made by `tools/blender/ui_kit.py`. The record: `docs/asset-requests.md`, AR3, section 2.
- **The director, 2026-11-12:** which screens are Pearl and which get a palette of their own is Modulo's to choose, so long as the whole holds together. The choice: Graphite for the field and the collection, Dynamo for the Breaker and the bays, Void Violet for the reveal's card, Pearl for what's read like a page.
- **For Faber:** "For the builder" in that section: the layer order is the script's `panel`, `button`, `bar` and `frame`; the palettes' rows are in `kit.json`.
- **Open:** nothing on the images: research's verdict came (competent, the frames exceptional) and its five fixes are in, past the content check (AR3, section 2, "The fix round"). Nothing is uploaded or in the engine.

### 2026-11-12. Pip: eight clips delivered (Modulo)

- **What:** Idle, Combo, LanternBurst, Hit, Down, Up, Reveal and Work on R6, with the hat and the lantern keyed on their own joints. Hit, Down and Up are the robe reaction set.
- **Where:** `build/handoff/Pip/clips/` (a JSON a clip, `Pip.clips.json` with the markers and the 12-stud flight, each clip's pack and notes), made by `tools/blender/pip_clips.py`. The record: `docs/asset-requests.md`, AR4, section 3.
- **Changed on the way:** no hand ever goes to the hat, the send's kick throws his whole body, and Down falls backwards with the hat over his face.
- **For Faber:** the ten engine checks at the section's end, and "For the builder" above them: the blend over Idle, the fall from the game's own camera, the dump against the export.
- **Open:** nothing is uploaded, seen in the engine, or judged at real speed.

### 2026-11-12. The Shade: the model and nine clips delivered (Modulo)

- **What:** one body on R6 (five pieces, 2,444 triangles) and four masks, on one atlas for the five types; nine clips: Idle, Walk, Attack, AttackLeft, Guard, Lunge, Hit, HitLeft, Burst.
- **Where:** `build/handoff/Shade/` and its `clips/`, made by `tools/blender/shade_model.py` and `tools/blender/shade_clips.py`. The record: `docs/asset-requests.md`, AR2.
- **For Faber:** "For the builder" in AR2's section 3, and the content check's engine checks in sections 2 and 3.
- **Open:** the burst's light and paper, an effect built with the builder; the elite's second mask. Nothing is uploaded or seen in the engine.

### 2026-11-12. Day one: the repo, the kit, the calls (Faber)

- **What:** the repo joined to GitHub and pushed. The kit is in `src/`: remotes, live numbers, presets, the debug bridge, the self-test, the logic tests. Both guards are installed. The starter is trimmed to one role, and three calls are made: ProfileStore kept under our own save layer, Server Authority off, pure rules run with Studio closed under Lune.
- **Where:** `docs/test-requests.md`, TR1; `docs/engineering-plan.md`, "The builder's calls"; `tools/checks/`.
- **Tested:** the self-test 11 of 11, the logic tests 29 of 29 in Studio and offline, the type check `0 new`, the hooks' self-test 126 of 126.
- **Open:** the place waits for a save to keep `AuthorityMode` Automatic. The next piece is TR2.
- **For:** everyone who runs a check: the commands are in `.claude/skills/ga-studio-test/SKILL.md`.

### 2026-11-11. The design, the balance model and the start of production (research)

- **What:** the director's package of 2026-11-11 read whole and turned into the game's own pages. Eighteen open decisions answered. Balance rebuilt so nothing compounds, and tested by a simulation (`py tools/balance/sim.py`). Thirty-one Voidkin, the Shades and six grounds authored. The HUD's direction. The first requests: TR1, TR2, AR1 to AR5.
- **Where:** `docs/`; `tools/balance/`. The package itself is in `docs/archive/package-v13/` (kept out of git: it's large, and partly superseded). The directive of 2026-11-09 is in `docs/archive/`.
- **The folder** is now `C:\Users\gloce\GrowyourAnime`, with `origin` set. The kit was refreshed from the studio's corrected templates.
- **Tested:** the simulation only. Nothing is built, nothing is played, nothing is drawn.
- **Open:** the local history and the remote's first commit aren't joined, so nothing is pushed yet (TR1's first step). The ids aren't checked. The handbook clone here is behind.
- **For:** everyone. Start at `docs/north-star.md`, then your row.
