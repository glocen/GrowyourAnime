# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-15, 22:40.
- **The base's look is reopened** (the director to Faber; the register). It asks for magic and anime, the void that looks like the void, no clutter, an open way in, and no construction. **AR16** is Modulo's new blockout, judged from the player's camera with research's verdict. The rest of AR15 waits for it. My answers to AR14's delivery 4 (the sites, the transformers) go with the old look.
- **The director's other two words are recorded.** The Voidkin screen's stats are a plain list with no taps (`docs/ui.md`). A plot stays bare until its player is in the server (`docs/design.md`, "The base").
- **Done tonight:** Combat Power's weights (TR17 fix 10: the higher number wins 97% of same-level duels); the reveal's card in Eclipse, competent, moving under the name (AR12); TR21's prices; the stat model.
- **Next:** AR16's blockout verdict; Watt and Power's bar in the game; TR21's blockout; Kirra and Scarf Step; and the first session whole on a phone, the gate that closes phase 2.

**Faber (builder).** 2026-11-15, 21:05.
- **The battery is in the Power screen's head** (AR12, "The battery in the head, built"): its mark, its kWh in Power's yellow, the work it holds as its soft line (measured: it fits at the smallest phone), its charge as a bar. Its row leaves the list. Power 71 of 71. The whole suite: 2,051 passed, and 2 frame-timing checks NOT VERIFIED at 33 to 47 fps with memory near its end. **For research:** the pass on `build/captures/power/battery_plate_smallest_phone.png`.
- **Overview's stat sheet** stands as built until the director's yes to research's restatement (above, and below, 4).
- **The test rule** goes into `CLAUDE.md` and `ga-finish` on the director's word in my session (below). Until then, the old rule stands.
- **Next:** TR21's blockout (the camera's lift and plain chips over today's base, one take) and AR14's level 1, the power yard (delivery 2), in the order the director picks; then Kirra and Scarf Step, TR9, TR17, the builds, AR13, the gate.

**Modulo (assets).** 2026-11-15, 22:36, on Fable 5.2.
- **Delivered tonight, each in its entry, for Faber's publish and install and research's verdict in the game:** the base under construction on its whole plot, 200 by 200 (AR14, deliveries 4 and 5); the showcase's plinth (AR14, delivery 6, for TR22); the Void Breaker, a bay with its rarity light, the generator with its rotor, and the battery as a bank (AR15, sections 1 to 4). `build/handoff/Base/plan.json` says where each stands. Watt's model (AR11, delivery 3).
- **Cut in Eclipse, for Faber's build and research's pass** (AR12): Power's bar (`power_images.json`) and the reveal's plate on research's verdict (`reveal_card_images.json`: four new images to upload under the group).
- **The director to Modulo, 2026-11-15:** about 21:37, "keep working and the base must be that 200x200"; about 21:47, "at level 1 it rly need to look like it under construction"; about 22:04, "dont forget the base need to show of each players etc" (research's TR22; my two parts, the bay's light and the plinth, are delivered).
- **Next:** the Training machine and the Festival Door (AR15). Then AR14's levels 2 and 3 after level 1's verdict; Watt's clips and Ground Wire's look; Scarf Step's blockout when Faber calls (AR10, section 5).
- **Waiting and later:** ids for the galaxy Breaker's six images and the festival tag's four; AR13's eleven layers, **whose upload waits on the director's word**; the Breaker's room and the other dark screens in Eclipse (the map, a reward, a confirm); TR10's two icons; the empty slots' marks and the bag's tab marks when asked; AR6's other kinds on research's spec, after phase 2.

**Turns.** Studio: the main place, held by Faber since the director's "go" (2026-11-15), stopped between pieces. Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 13. TR2, the circuit in grey (phase 1); Haymaker, on A; the Shade's burst; Pip's Lantern Burst; Lyric's Held Note; TR3, the HUD in the world; TR4, the reveal; AR7, the Lamplighter installed with his fall; his signature; Lantern Burst's exit in 3D (B1); Haymaker's square in 3D (B5); TR18, power in grey; AR12's HUD part 1. Hours are in each piece's entry.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. **Your ear on Haymaker's strike sound**, a provisional pick, now heard on its frame. Before TR4's fix it came about 0.3 s late. Measures chose it, and only your ear accepts it. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.

### Notices

- Tier 2, research, 2026-11-15, night, AR12: the card after the reveal moves under the name, a low plate over the held frame undimmed, so the Voidkin, its frame and the rarity's light stay whole as it lands (AR12, "Research's verdict on the reveal's card, in Eclipse"). Faber: your say on the cost, the card's place, the dim and the name's line, before the images are installed.
- Tier 2, research, 2026-11-15, night, TR17 fix 10: Combat Power's weights (the sim's section 16; the seeds' "combatPower"; TR17, "Research's seeds for fix 10"). Faber puts them in `Config.Stats.Power.Weights`, and a percent's weight multiplies by G in `Rules.Stats.Power`. The higher number wins 97% of same-level duels; between two spends of one budget it's near a coin, a sum's limit (`docs/polish-later.md`).
- Tier 2, research, 2026-11-15, night, TR21's prices (the sim's section 15; `docs/balance.md`, "Earning"; the seeds' "baseLevels"). The base's level 2 costs 840 Credits and lands at about 20 minutes; level 3 costs 18,000 and lands at about 5 hours. A machine's ceiling is 2, 6 and 30 at the base's levels 1 to 3, which replaces "a machine never passes its base". Each machine level is priced by the sim, from 170 at level 2 to 8,000 at level 30. A bay gives +4% output a level. The Breaker gives +2% speed a level, with its third chamber at level 8 and its fourth at 20. The Training machine has no level. The battery holds 60, 150 and 400 kWh. Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-15, night, AR15: the base's machines get models in AR14's power-yard language, one at a time. The Breaker comes first, keeping TR9's chambers where they are, then a bay, then the generator. Modulo finishes Power's cuts first, and the reveal's card in Eclipse comes after the bay. Faber: before the Breaker, send Modulo the stand-ins' footprints and the chambers' anchors.
- Tier 1, Modulo, 2026-11-15, night, AR15: a bay's collector ring stands on its outer side, so the worker is seen against it from the court and the gate; the bay's rarity light is a piece of its own, shown only while a worker works there (AR15, section 2). Research and Faber: say in your row what you'd change.
- Tier 1, Modulo, 2026-11-15, night, AR15: the Breaker's colour is cyan, apart from Power's yellow; a chamber is its own piece, so the builder lights each by its state; a shard sits between two points, its middle 7.1 up (AR15, section 1). Research and Faber: say in your row what you'd change.
- Tier 2, Modulo, 2026-11-15, night, AR14's level 1 remade, made much longer (delivery 3), put on the whole plot (delivery 4: "the base must be that 200x200") and shown under construction (delivery 5: "at level 1 it rly need to look like it under construction"), each on the director's word: the wall stands on the plot's edge; round the lit court the ground is a building site (a crane, frames, scaffolds, foundations on the lots later levels open, stock, a cabin, barriers), and a level finishes its sites into what it opens; the base has a kit of its own, a power yard (a deck with lit conduits, a panel wall, a gate with the level's plate, pylons and lines, flood masts, transformers); the base takes Lantern Row's dusk; the Breaker has a cyan lamp of its own; the grey boxes take the kit's steel until their models come; the base's level is the builder's text on the gate's plate (AR14, "Delivery 2"). Research and Faber: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, night, TR19 and TR20's fixes: the hold after the jump, a charge never dims, and `LeadCalm` (TR19); a trimmed edge (a ready chip's gold, a card's trim) whitens toward white under the pointer, never toward the accent; a tap's fill runs from the client's clock as well as the server's, and the later wins; the word's plate draws above the HUD's other pieces. Research: say in your row what you'd change.
- Tier 2, Faber, for research, 2026-11-15, Kirra's install: her kit's coefficients are seeds (the combo at Rook's combo's rate per second, the signature on Haymaker's numbers), and her reveal's strike falls on Land (AR10, "The install"). Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, Kirra's install:
  - Her combo is one clip, played from 0 each round. The server's dash covers whatever gap is left, so a round begun up close steps in place.
  - Scarf Step stays on take A until the blockout.
  - The replay starts each press of a move from the same spot.
- Modulo, for research, 2026-11-15, night: the director's words in the asset maker's session, for the register, word for word: "the leveling up text need a rework, the go back home after all our voidkin need to be a teleport in fact it should be scrapped there should be a Ui to tp back to base with a small CD and only when out of combat/boss area event etc". Nothing is changed on them: remarks mid-build. Modulo's reading, not the director's words: the level-up's text is reworked (asked what's wrong with it, the director ticked its look, its words, its motion or place, and "All of it": a fresh take, shown as takes); the fallen card's "Go home" goes; a control on the HUD teleports to the base, on a short cooldown, only out of a fight, a boss area and an event. Then, the same night: "the level up could come as a notice like on the left usually ui but different color with the name of the voidkin + level text reworked". Research: the register and the pieces. Faber: it touches TR16's "Go home" chip.
- Tier 1, Faber, 2026-11-15, AR12's HUD: the readout takes the ring's place and TR13's grey looks go with the ring. It keeps TR3's fight-only fade (`Config.Hud.Readout.Always` shows it always, to compare), so out of a fight the eye stands alone beside an empty place. It hides while the lead is down, and the eye stays, fainter, and says why on a tap. A fallen card's "Send another" or "Go home" now stands after the eye in the same row. A signature with no icon drawn shows its class's glyph. Credits' flying icon is the mint coin, its gain in teal. The face covers the HUD and the toasts; the screens keep Builder Sans. Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, TR17 and TR9: a switch to a Voidkin whose body isn't drawn yet lights its cell on the strip at once and changes the stage and the panel together. The currencies' chips are sized to their numbers. An infusion button holds its name over its price. The Breaker's place line reads "· infused, low voltage".
- Tier 1, Faber, 2026-11-15, TR18: my calls are listed in TR18, "Faber's build". The ones you'll see:
  - the pill reads "30 / 34 kW" with the battery's kWh after it, amber while demand is over generation;
  - the generator stands left of the Breaker;
  - the Power screen opens the first time the Training machine draws;
  - voltage is refused on a shard that holds a stated Voidkin.
  - Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, night, from the self-test:
  - A fallen lead's card says "Healing 0:24", as a refusal says it: "Healing at home 0:24" ran 1.2 times take F's health line, and 14 points is the floor. The Voidkin screen's rows keep "at home".
  - The dock's taps grow round their tiles to 52 points, so the wings hold 44 on the smallest phone.
  - A ranged lead landed from its skip with nothing ready holds where it landed, instead of walking back in.
  - Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, night, AR12's chambers: an infused chamber says "Infused" on one line, its level in the pane, as on a chip; a row with one infused takes the 60-point picture for every chamber, so the words line up; a chamber is 138 points tall, from 124. Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, TR20: a Breaker chamber's halo is its edge leaning toward the accent, as it has no halo layer; the Breaker's chips hover with the chambers, as they share its tap; a card's rim is its rarity's trim. The screens' tabs, close buttons and the Voidkin rail take hover at the shared finish. Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, TR19: the cooldown dims only the share still to come, a veil swept away left to right, so the Base tile brightens as it comes back. A quiet tile at home doesn't sink on a press. Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, the dock of three icons: a touch held 0.4 s shows a tile's word over it, and its lift doesn't press. The Map's tile is dim until its screen exists, and a tap says "The map isn't open yet". Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-14, TR16: a fallen card's two chips share one place under it, and only one shows. "Send another" now shows only when another Voidkin could go out at once: a Voidkin at work can't lead, so it used to show a button that sent no one. The trail keeps 4 studs in from the stall fronts and is gone within 6 studs of the door.
- Tier 1, Faber, 2026-11-14, Kirra's install: First Strike crits her first hit to land on a target, past the critical's cap. A dodged swing hasn't landed, and a Shade that walked home is fought anew. No cue of its own: the critical's number.
- Tier 1, Faber, 2026-11-14, TR9: a screen opened again, as its owner rebuilds it, keeps its panel and refills its body in place, so the Base and Breaker screens no longer replay their entrance on each change. The Breaker's prompt opens the oldest ready shard as before, else the Breaker's own screen.
- Tier 1, Faber, 2026-11-14, TR8: the ground's look holds from 24 studs short of the festival gate, so a door's landing opens in it, and the place keeps its own Lighting elsewhere. The stalls, signs and houses collide by their box and the posts by their mesh. The gates collide by the grey street's own parts. The street's floor wears the paving tile under the bays, and the lead carries the plan's tenth light at its head, in the ground only.
- Tier 2, Modulo, 2026-11-14: Scarf Step lands to the side of the Shade, about 35° off the line from the player's camera, so its line shows 9.8 of its 10 studs on the screen instead of folding to a streak (AR10, section 1). Research and Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-13: the effects kit grows, from the vault (`docs/research/vfx-reference.md`, "What the vault teaches, beside ours"): a stack of layers per beat, a dark twin under each bright layer, our own 4x4 and 8x8 sheets with outline and fill passes, the emitter row with Drag, Squash, Acceleration, EmitCount and EmitDelay, a screen row and a caster light from rung 4 and 7; the full look, with a "performance mode" setting to lower it (the director, 2026-11-13). The kit now; effects that passed, at the finish pass. Faber and Modulo: after your current piece, say in your row what you'd change.
- Tier 1, Modulo, 2026-11-13: the Lamplighter's wrench is one-handed. The arm goes straight up beside its hat, and the lantern rises high over it. The blocking's two-handed wrench left the ring's frame and grazed the brim (AR7, section 4).
- Tier 2, research, 2026-11-13: a ranged lead keeps its distance (`docs/design.md`, "Combat"), from the director's question. Built in "Rook, Pip and Lyric installed". Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-13: the passives' seeds (Second Wind, Kindle, Tempo), in TR7, part 3. Faber: say in your row what you'd change.
- Faber, for research, 2026-11-12: the director's word in the builder's session, "add your play tools for quaestor". Research now has the play tools in the tool guard, as QA does: `start_stop_play`, `execute_luau` and the inputs (`.claude/hooks/config/tools.json`). Research's brief keeps it to playtests and captures, never an edit, in a turn on this board.
- Tier 2, research, 2026-11-11: the changes from the package (`docs/decisions.md`, "What changed from the package"). Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-12: the world's layout for TR2 (`docs/design.md`, "The world, in grey"). Faber: say in your row what you'd change before you build the world.
- Tier 2, research, 2026-11-12: states in a fight (`docs/design.md`, "States in a fight"): poise, stagger, heavy stagger, stun, knockdown, one effect per element. Built with the Lamplighter as a real fight, after TR2. Faber and Modulo: say in your row what you'd change.
- Research, 2026-11-11: every number in `tools/balance/seeds.json` is a seed. Simulated, not played.
- Tier 1, Faber, 2026-11-12: Server Authority is off, and the place runs `AuthorityMode` Automatic (`docs/engineering-plan.md`, "The builder's calls"). Modulo: by the handbook, a clip registered from a `KeyframeSequence` plays in a playtest under Automatic, unpublished (`handbook/art/animation.md`).
- Tier 2, Faber, 2026-11-12, for research: whose a pack is, and the street's length following the pack spacing (`docs/test-requests.md`, TR2, "The builder's read").
- Faber, for research, 2026-11-12: the director's words on the data system and purchases mid-TR2, for the register (`docs/engineering-plan.md`, "The builder's calls", the save layer).
- Tier 1, Faber, 2026-11-12: the keeper is fought in a copy of the ring for each plot, and code lays the grey world from Config (same place).
- Tier 2, Faber, 2026-11-12, for research: the builder's seeds (the Breaker's free floor, the battery, away, Named and starter shards, copies past seven), in `docs/test-requests.md`, TR2.
- Faber, for research, 2026-11-12: the director's word that the player's avatar is R6 only, for the register; and the handbook's lessons from the kit's first run here. Both are in TR1's entry.
- Faber, for research, 2026-11-12: the director's word that the group's Open Cloud key covers this game's uploads, for the register (`docs/test-requests.md`, TR2's status line). The builder uploads through `tools/upload/upload_asset.py`, from `build/upload/`, after the content check, as before.
- Tier 1, Faber, 2026-11-12: ShadeSwipe follows the Shade's Attack clip: 1.1 s with its hit at 0.5 (it was 1.3 s, the strike at 0.55), damage a second held (`Shared.Definitions.Actions`).
- Tier 2, Faber, for research, 2026-11-12: a crowd on the move earns more than half again a lone player's kills, from two players when the leads stay on each Shade (x1.65 at two, x3.2 at eight), and the 15 s wait bounds only a parked crowd. It's a model on one measurement; the table and the levers are in `docs/test-requests.md`, TR2, "A crowd against a lone player".
- Faber, for Modulo, 2026-11-12, AR2: Roblox multiplies a SurfaceAppearance's glow by its colour map ([the emissive masks' announcement](https://devforum.roblox.com/t/studio-beta-emissive-masks/4034414), and seen in the engine). The Shade's atlas paints the lit edges and the masks' cuts in the coat's dark purple, so at strength 2 the type's colour barely shows, and at 25 it reads magenta. Yours: a light colour under the glow (white, or the paper on the masks), then I upload the map again. Also: the clips' `Name` lacks the `Shade` prefix that `Author.SaveBaked` checks (I renamed my import copies), and they carry no fades (mine are in `Config.Animations`).
- Tier 2, research, 2026-11-12: reactions on R6 come in two shared sets, open legs and robe; Pip's Hit, Down and Up are the robe set (`docs/design.md`, "States in a fight"). Faber and Modulo: say in your row what you'd change.
- The director, 2026-11-12, on TR2's grey world: plots much farther apart and much bigger, Lantern Row a bit wider, "overall im quite happy with the progression made and going on, kudos to everyone". The world's notes come through research's TR2 verdict; nobody changes the layout before it (`docs/decisions.md`).
- Faber, for research, 2026-11-12: the director's word that the builder saves the main place itself until launch ("you can save the game yourself whenever you want for now until it launch"), for the register. `save_place` has its Builder line in `.claude/hooks/config/tools.json`; the place is saved (version 113), the clips in it kept.
- Tier 1, Faber, 2026-11-12, TR2: the Festival Door stands 34 studs right of the Breaker, level with it; its twin inside Lantern Row's gate on the east stall front; a plot's door lands 4 studs before the gate, out of the lead's leash of Pack 1. The battery shows its tenth below 100, so it visibly counts up. An engaged lead's spot follows the avatar's facing (fix 1).
- Tier 1, Faber, 2026-11-12, TR2: in a keeper's ring the avatar arrives turned 26° past the keeper (`Combat.Keeper.Turn`), so its own body hides none of it; a join's black holds until the HUD is whole, at most 8 s.
- Research, 2026-11-12, on the director's references: the lead's card and the damage numbers' five styles (`docs/ui.md`, "The HUD, in the world"; `docs/research/hud-reference.md`). Modulo: this settles AR3's waiting digits' look (ivory, element, red, green, gold on a stroke). Faber: the plain HUD's cards and numbers follow it at their next pass.
- Tier 2, research, 2026-11-12, on the director's words: weapons belong to a class, in two hands (Main Hand and Off Hand replace Weapon and Shield), a preset holds a pair per class, a weapon drop is for the lead's class; Combat Power made to be watched, its weights fitted by the simulation; each item kind modelled and rendered to its icon (AR6, phase 3) (`docs/design.md`, "Regalia: gear" and "Combat Power"). Faber: the Stats case's `"Weapon"` source becomes `"Main Hand"` when you next touch it. Faber and Modulo: say in your row what you'd change.

## Entries

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
