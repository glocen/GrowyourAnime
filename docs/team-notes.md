# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-23, 14:04, on Opus 5.5 at xhigh (the director's word). **The director's order (decisions.md, 00:05): the main map and the systems first; the Festival places come after.** Done this session: the director's "the dock is a bit too shiny" (13:00), agreed and reopened as a fix for Faber (AR30, "The dock's shine, reopened on the director's word"); AR50's finish passed at competent, no must-fix; AR51 written for Modulo (the Condenser's convert panel and its share on the Power screen).
- **Next, mine:** AR49, TR51 and TR37 in the game, from Faber's captures once Studio is open; the dock's shine read on the phone; AR51's pick.
- **Faber's order:** the Studio run of AR49, TR51 and TR37, then the small ones (the dock's shine, AR44's shine, TR10's stills, TR50's Arc palette and Voidkin floor, AR48's states), then AR50's install (all seven pieces), then AR51.
- **Verdicts owed, main map first:** AR37, AR28's Stage I, AR30, AR23, TR10 (each read in the game at its install); then TR43, TR44, TR34, TR29 (Festival and Tower, after).
- **With the director:** open Studio on the main place with Rojo on 34876, so tonight's code is seen; the PC's keep-awake (restart it, or the screen never off on mains); `src/shared/Config/Sounds.luau`'s uncommitted change, nobody's; the Voidkin model examples; the store's design; the sound pick on TR42's panel.

**Faber (builder).** 2026-11-23, 03:25, on Opus 5.5. Stopped at the director's wrap-up (through research). Built today, each implemented and offline-tested, none run in Studio: the Studio MCP attaches to a blank Studio window, never the one with Grow your Anime open.
- TR37 in two steps: the Condenser's rules (6b97f0b), then the Forge and the Condenser in their sleeping places (ca3dbb1). Record: TR37, "Faber's build". Earlier: AR49 (04b45b5) and TR51's three steps (38d01a8, ad1372b, e086d9e).
- **Next:** the Studio run of AR49, TR51 and TR37: the self-test, LogicTests and WorldReport; FxKit.rbxm rebuilt with the landing's look; the Fit Prints; captures from the gate at each stage and on the smallest phone, for research. Then the small ones (AR44's shine, TR10's stills, TR50's Arc palette and Voidkin floor, AR48's states), then AR50's install.
- **Open, tests:** NOT VERIFIED: AR49, TR51 and TR37; and, in the Festival place (item 9), TR50's run cases, the Festival role's suite, TR48's keeper, TR49's Stage 1 playtest and TR10's marker. TintMask on a phone. TR44's phone take waits for the director's go.

**Modulo (assets).** 2026-11-23, 14:41, on Fable 5.2. Voidkin work parked until before launch (the director's word, 11:10).
- **Now:** AR51's finish delivered, after research's pick (B, and Rose with the six-sided chip): the convert card's spec at the game's sizes (`build/handoff/Base/condenser_card.json`, `condenser_card.png`; 172 by 70 points, since the blockout's word stood under the 14-point floor; asleep, the cost line alone), and the Power screen's share (`build/handoff/UI/hud/colour/condenser_share.json`, `images/PowerChipCondenser.png`, `images/ArrowRight.png`). Content check PASS for both images. **Waits: research's pass on the finish** (AR51, "The finish").
- **For Faber, AR51's build, after AR50's install:** upload the two images under the group; the card from `condenser_card.json`; `Config.Hud`'s Power takes the Condenser's colour, gradient and chip; must-fix 2 (no row half-cut at the fold) is yours.
- **Next:** nothing queued; research's design study names the next pieces. No new effects work until the director answers on an effects teammate.
- **AR50:** passed at competent (research, 14:04); all seven pieces are Faber's, after TR51, as one install.
- **Delivered earlier today:** AR48's five cues as a block-in (`build/handoff/FxKit/states/`, Faber's after TR49's states), TR50's dusk palette (`build/handoff/UI/stages/arc_dusk.json`, Faber's after AR49), and the Voidkin screen's floor in B (`build/handoff/UI/voidkin/voidkin_floor.json`, Faber's after TR51).
- **In the game:** AR46's Hard looks with AR47's masks, on TintMask (a856f06), passed at competent (19:18). AR42's tiles in Seam, passed at competent (f9f3636).
- **For Faber:** AR49, Home's panel in C (`home_cards.json`): 12 images to upload under the group, a ViewportFrame of the lead between `HomeVoidkinRimTop` and `HomeVoidkinFrame`, the words as TextLabels; after research's second look. AR44, the critical's shine (`build/handoff/UI/hud/critical_shine.json`). AR43, upload the five `Jewel<Colour>3.png` and swap their ids, if not done. TR10: take `MarkerElite.png` as it stands at the marker's install.
- **For Faber, AR40's install:** the atlas pair, and the Strip's eight changed meshes with the manifest, on top of the 40 base meshes, the paving and C's keys already listed in AR40. The atlas never goes alone. AR38's Shop meshes go with AR38.
- **Unchanged:** AR28's Stage I on TR37, AR19's re-uploads, AR24's A on TR34, AR39 stopped, Sable after launch.

**Turns.** Studio: Faber's turn released (2026-11-23, 03:25); the Studio MCP is attached to the blank Studio window, not the one with Grow your Anime open (item 10); the director's listen on TR42's panel is tomorrow, in the same place. Blender: nobody (Modulo's AR41 strips were stopped at 01:33 on 2026-11-19 by Claude Code when the PC ran low on memory; the director said wait at 01:34). Timing tests: nobody.

**The count.** Week of 2026-11-23: 0 pieces closed and playable so far. Today's closes are art and picks (AR48, TR50's palettes, AR50's pick), all waiting on their install, which is how they become playable.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. **Clips of the chest openings** you know, Sailor Piece's and Taichi Panda 3's, in `build/reference/chest-opening/`, for TR34 ("gimme a moment").
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Publish the build, for your phone run** (TR24's fix 1 is in, and research gives the go). The place is saved with it, and the Studio tool can't publish: in Studio, File → Publish to Roblox (Alt+P). The experience stays private.

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. **Your ear on Haymaker's strike sound**, a library pick (not one of AR13's made takes), heard on its frame. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.
7. **Your ear on the audition panel** (TR42), ready for tomorrow: 12 tabs, the nine skills and the Mage's and Healer's hits, and a tab for each of Rook's, Kirra's and Watt's light hits drawn from your 32 keeps. In Studio's Play, the panel is at the left: a tab per hit, "Old" (today's sound) and ten candidates. Tap a row: it plays, and from then on every hit of that kind plays it in the fight. **Keep** the ones you like (more than one is fine), **More** for the next ten, **None of these** when ten hold nothing. **Others off** mutes the fight's other sounds, so you hear the candidate alone. When you're done, leave the Play running and tell Faber: your picks are read from it.
8. **Pick the slam's rule by playing it** (TR44): Off, A or B. In Studio's Play, start a keeper's try. The Server command bar switches the mode mid-fight: `game.ServerStorage.NL_Debug:Invoke("Slam", nil, "A")` (or `"B"`, `"Off"`), and `Invoke("Slam")` reads the counts. In A, walk out of the ring and your fighter follows; in B, press the round Recall button or R. Research reads a phone take of each first: say go and I record it (the PC's memory stopped it tonight).
9. **The Festival's place, after the main map and the systems** (TR45; your word of 2026-11-23, 00:05: the team has full access to it). When its work opens, the Creator Dashboard's settings stay yours to confirm: its name (Faber's suggestion: Festival of Battles), its server size 8, and its Direct Access set to "Secure within universe only". Then the id goes into `CLAUDE.md`'s "Places".

10. **The Studio MCP on the Grow your Anime window.** Two Studios are open, and the MCP is attached to the blank one ("Place is not open"), so nothing of tonight's three pieces has run. Close the blank Studio window, or turn the MCP server on in the Grow your Anime window (the Assistant's settings), with Rojo connected on 34876. Faber runs the tests as soon as it shows.

### Notices

- Tier 2, research, 2026-11-23, 14:04, AR51: the Condenser gets a convert panel in the Comb's make and its own share on the Power screen (colour, chip, light, a third handle), answering Faber's TR37 notice below. Faber: say in your row what you'd change.
- Tier 2, Faber, 2026-11-23, TR37: the Power screen's bar keeps two handles. The Condenser shares under Auto, and a split never clears its share, but its own handle, light and chip wait for a Power screen piece. Tier 1: the Comb lights by the tray's fill of its cap, from the bottom row up (a full tray lights all 37), and the convert's refusal is its own word ("A convert takes 5 Low stones"). Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-19, TR49 and AR43's take 2: the experience line reads "{xp} of {need} to Level {n}", one line on the smallest phone, so all five attributes show; Lifesteal's heal shows on the bar with no number of its own. Research: say in your row what you'd change.
- Tier 2, research, 2026-11-19, 20:46, TR48 part 2: on Hard, an elite's chest holds Epic 0.9% and a keeper's chest after its first win Epic 2.0% and Legendary 0.45%, so a one-ground launch meets design.md's Epic at 4 to 6 h and Legendary at 15 to 20 (MODEL). Faber: say in your row what you'd change.
- Tier 1, Faber, 2026-11-19, AR43 in B: Settings' Effects covers the fight's particles and the camera's shake; the words the cut left open are mine ("Shades and keepers drop them", "Not enough Credits", "It's at +N already", the emblem bag's Sort pill, "Jewels are coming", "Not saved: try again"). The list is in AR43, "Faber's install of Equipment's three and Settings in B". Research: say in your row what you'd change.
- Tier 2, research, 2026-11-19, 17:02: Hard's ember in the world (AR46). Hard's Shades, elites and Lamplighter wear the picker's ember, in three directions to capture before the pick. Faber's part is one switch at spawn. Also: TR47's and TR48's seeds (Reinforce, emblems, the materials, Hard's own budget, the Tower's Lift).
- Tier 2, research, 2026-11-17, 21:10: the Void Shop's rules (`docs/design.md`, "The Strip"): six lines a stock, a rare offer about once an hour (a Named shard, never a roll), each player's own limit, the shelf fitted to the farthest ground, bought at the counter. Faber: say in your row what you'd change.
- Tier 1, Modulo, 2026-11-18, AR38: the Shop's shelf follows D6. Its two lights are the Standard shards, and between them stands the featured piece's cradle, dark until a featured stock lights a stone in it with the crown (AR38, "The clock's fix, and the Shop in AR40's C"). Research: say in your row what you'd change.
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
- Tier 1, Faber, 2026-11-15, night, TR19 and TR20's fixes: the hold after the jump, a charge never dims, and `LeadCalm` (TR19); a trimmed edge (a ready chip's gold, a card's trim) whitens toward white under the pointer, never toward the accent; a tap's fill runs from the client's clock as well as the server's, and the later wins; the word's plate draws above the HUD's other pieces. Research: say in your row what you'd change.
- Tier 2, Faber, for research, 2026-11-15, Kirra's install: her kit's coefficients are seeds (the combo at Rook's combo's rate per second, the signature on Haymaker's numbers), and her reveal's strike falls on Land (AR10, "The install"). Research: say in your row what you'd change.
- Tier 1, Faber, 2026-11-15, Kirra's install:
  - Her combo is one clip, played from 0 each round. The server's dash covers whatever gap is left, so a round begun up close steps in place.
  - Scarf Step stays on take A until the blockout.
  - The replay starts each press of a move from the same spot.
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

### 2026-11-23, 13:38. AR50: the rings afloat refitted on one axle (Modulo)

- **What:** level 2's ring no longer passes through the generator. Both rings stand on one axle through the plot's heart, leant 9° into the plot: `LevelRing` is the floor's second ring lifted (23 in radius, 14 up), `LevelRingOuter` 27 in radius 10.6 further up it, turning the other way. Level 2's ring now reads from 150 studs and through the gate.
- **Where:** `build/handoff/Base` (the two meshes, their manifest entries and plan rows, four sheets); `tools/blender/base_levels.py`; the audit, `tools/blender/base_levels_clear.py`; the record in AR50, "The rings' refit".
- **Open:** research's pass on the whole finish. Research's call placed the floor's ring forward of the generator; it's round it, so the rings went wide of the generator instead (the record's first line). Nothing uploaded, nothing in the game.
- **For:** research now; Faber after TR51, all seven pieces as one install.

### 2026-11-23, 03:25. TR37 built, not yet run in Studio (Faber)

- **The Stone Condenser:** its rules in pure Luau (`Rules.Condenser`, `Config.Condenser`), a third machine in `Rules.Power`, worked online and away through `Rules.Breaker`'s steps. CollectTray and Convert are each the server's, in one step. Its save is `Base.Condenser`, filled by Reconcile.
- **In the world:**
  - **The Condenser:** AR28's Comb over its sleeping stone, which stands until base level 2. Its cups light by the tray's fill, and the plate reads the tray from the gate. There's a tap to collect and a small grey panel for the convert (5 Low into 1 Mid).
  - **The Forge:** AR28's Press. Its prompt opens Equipment on Reinforce, and each try strikes its ram: lift, strike, hitstop, settle (`Rules.Forge`, `Config.World.Forge`).
- **Checks:** type check 0 new; logic offline 29155 passed. The self-test's TR37 case, the world report and the captures wait for the MCP on the right Studio window (item 10).
- **Where:** TR37, "Faber's build"; the save contract in `docs/engineering-plan.md`. For research: the verdict in the game, once captured.

### 2026-11-23, 02:51. AR49 and TR51 built, not yet run in Studio (Faber)
- **AR49** (04b45b5): Home's panel in C, three cards on dark glass, the lead live under the Voidkin card's frame; the Voidkin screen takes the Equipment screen's rail. Record: AR49, "Faber's build".
- **TR51** (38d01a8, ad1372b, e086d9e):
  - every machine's stages II and III stand by their level;
  - a rise seen on its owner's plot plays AR37's landing, the swap under its cover, a plot's landings on one instant or 0.34 s apart;
  - the gate's plate says the owner's name over "Level n", and the plinth turns their showcase Voidkin with its CR.
  - Record: TR51, "Faber's build".
- **Checks:** type check 0 new; logic offline 29,036 passed. The in-game cases are written, NOT VERIFIED: the Studio MCP saw no open place.
- **For research:** the in-game verdicts on AR49 and TR51, after Faber's Studio run and captures. **For the director:** Grow your Anime open in Studio, Rojo connected on 34876, for that run.

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
