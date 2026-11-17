# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-17, 10:58, working through the director's absence (no break; no new sound effects until the director's samples).
- **Today's calls:** two attributes (Strength, Endurance) and the types named by their colours (TR36, Faber's); AR27, the idles lose their head glance; AR26, Rook keeps its rows with the spacing ask, and both tier 2 asks are approved on research's side; AR15's Door closed on research's side.
- **AR11, Ground Wire's retake:** works. Must-fix (round 2 on the hold): the lock as a pulsing fill on the stopped Shade, the shield as a pulsing glint on the spear's head. Asked of Faber: does a real fight hide the lead behind its target?
- **Next:** verdicts in motion on AR26's blocks as Faber installs them; sim.py's pool() learns "made" (TR24); attributes.py on the real Config once TR36 lands.

**Faber (builder).** 2026-11-17, 18:38. TR41 (d) is in: the festival tag on a chamber's picture, its mark on a disc in a bag cell (at the crystal's left foot, clear of the count), a band of the ground's colour along a Breaker chip's foot, for research's read (TR41, "(d) Where a shard came from"; stills in `build/scratch/faber/stills/tr41d-*`). Found and fixed on the way: at the smallest phone the Breaker's strip ran past its panel, cut. Voidkin work stays parked on branch `parked/ar26-watt-block`.
- **Now:** TR41 (e), the V2 leftovers, with the Training machine's still.
- **Next, in order:** AR29's B, 13 icons; AR30's 25 images; AR31's 38 and TR10's two icons up, then TR10's marker captures; TR34; AR23; TR29 and TR10; TR37 to TR39; TR31 to TR33, TR35, the responsive pass; AR19's six re-uploads; AR32's and AR33's Stages II and III as kit pieces.
- **Open, tests:** four timing cases are NOT VERIFIED (AR11). The Keeper's "and out on Out" and Pip's skip fail at times. TR20's Breaker hover depends on order. A reveal once stayed held after the suites (TR41, "The two must-fixes", Open).
- **Open, for research:** the target card's light (`CardLightHealth`) keeps its glow ahead of its front. Does it go the same way as the lead's?

**Modulo (assets).** 2026-11-17, 18:37, on Opus 5.5. Voidkin work parked until before launch (the director's word, 11:10): AR26 and AR27 stay as delivered, and Faber holds AR27's upload.
- **For Faber, after TR41 (b) to (e), in order:** AR29's B (13 icons), AR30's buttons (25 images), AR31's 38 upgrade images and TR10's two marker icons, all passed by research.
- **For Faber, after those:**
  - AR32, the Void Breaker's Stages II and III, the Great Jaws: four meshes and the swap's table `machines.breakerStages` (AR32, "Stages II and III as kit pieces"). Research reads it in the game from the spawn and the gate, with the hinges turning.
  - AR33, the bays' Stages II and III, the Horned Crown: four meshes and `machines.bayStages` (AR33, "Stages II and III as kit pieces"), passed by research. Research reads it in the game from the court, with the toothed rings turning.
  - AR34, the battery's stages, the Rising Stack: BatteryRack re-exported (AR19's note), BatteryRack2 and BatteryRack3, and `machines.batteryStages` with the cells' seats (AR34, "Stages II and III as kit pieces"). Content check: PASS.
- **Now:** AR34's kit pieces wait for research's pass. The renders ran in the foreground under the memory guard, on the director's go of 17:55.
- **Unchanged:** AR28's Stage I is with Faber, waiting on TR37; its 7 meshes went up with AR16 (3feb5a5). AR19's class fix (db2f086) passed research at 11:48; Faber's six re-uploads wait. AR24's A waits on Faber's TR34 block. Sable is after launch.

**Turns.** Studio: Faber (the game's place, for TR41 (b) to (e)). Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 13. TR2, the circuit in grey (phase 1); Haymaker, on A; the Shade's burst; Pip's Lantern Burst; Lyric's Held Note; TR3, the HUD in the world; TR4, the reveal; AR7, the Lamplighter installed with his fall; his signature; Lantern Burst's exit in 3D (B1); Haymaker's square in 3D (B5); TR18, power in grey; AR12's HUD part 1. Hours are in each piece's entry.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. **Clips of the chest openings** you know, Sailor Piece's and Taichi Panda 3's, in `build/reference/chest-opening/`, for TR34 ("gimme a moment").
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Publish the build, for your phone run** (TR24's fix 1 is in, and research gives the go). The place is saved with it, and the Studio tool can't publish: in Studio, File → Publish to Roblox (Alt+P). The experience stays private.

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. **Your ear on Haymaker's strike sound**, a library pick (not one of AR13's made takes), heard on its frame. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.
7. **The sample sounds** of the family you want, for the one retry on the sound effects (your word, by 08:00). Nobody makes a new one until they come.

### Notices

- Tier 1, Modulo, 2026-11-17, AR28's Stage I: the Comb's panel is six-sided, 37 cups in rows of 4 to 7 to 4, with its horns hugging its sides and closing round the core, against the block's "a block with a ring on top". The fill still reads by the lit height, from the bottom row up (AR28, "Stage I"). Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-16, AR16's install: the great ring turns against the rotor at 0.35 of its rate; the Training crown turns 0.12 turns a second while a Voidkin trains, and its pad stands 6 before the stone; the base's machine plates never cover each other: the nearest stands at its point and the others take the nearest free place over or under it (`World.Apart`). Research: say in your row what you'd change.
- Tier 2, research, 2026-11-16, AR16: the Tower's silhouette moves behind the back corner toward the crossing, off the generator's line, so it moves the Tower's lot in the world contract. Faber's say on the cost; if it's too much, it stays on the middle line until the game's verdict.
- Tier 1, Faber, 2026-11-16, AR12's plate: my say on the cost is in AR12, "Faber's install": small, laid as research gave it. The plate starts at the name's rule's left end, 8 under it. It widens for a long line rather than cutting one, and keeps its size on screen. "Tap to continue" drops under the plate when the outcome's line leaves it under 12 points. Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-16, TR21's blockout: a chip that would cover another rises to the nearest free place over or under it, never over the base's level at the top (TR21, "The rules and the blockout"). Research: say in your row what you'd change.
- Tier 2, research with Modulo, 2026-11-16, AR16: the star pulls in to neighbours about 36 apart, and the empty ground gets sleeping places for bays 3 to 6 and for the Forge, the Condenser and the Lab, lit as each wakes. Faber's install takes the new places.
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
