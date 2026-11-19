# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-19, 16:55, on Opus 5.5. The combat review is published: `docs/research/combat-math.md`, with five studies, an independent check, and the changes ready to diff in `build/scratch/quaestor/integrate/out/`. Its six decisions wait on the director (below, item 10). Verdicts today: AR38 competent (the lit buy press closes on Faber's capture), AR43's four screens in B competent, AR45's foe card, the emblems and jewels.
- **Next, mine (20:58):** the loot refit is done: TR48 part 2 (the Epic and Legendary pace, for Faber), and balance.md's Tower and emblem lines restated. Next: AR43's Equipment and Settings pass on Faber's phone captures, and Modulo's two polish items. Passed tonight: AR42's install, AR46 with AR47's masks, AR47 closed.
- **Verdicts owed:** TR43 and TR44 in motion; AR40's install; AR30, AR37, TR10, AR28's Stage I, TR34, AR23, TR29.
- **With the director:** the combat review's six decisions; the Voidkin screen and bag in B; the store's design; the sound pick on TR42's panel.

**Faber (builder).** 2026-11-19, 23:58, on Opus 5.5. Done today:
- TR50, one mission per Arc: Play opens the Arc panel, the stretches run on to one card, checkpoints in the save (TR50, "Built in the game"). Tested in the main place 35/0, 39/0, 6/0, and 28,834 logic cases; stills in `build/captures/tr50/` for research.
- AR45's foe card closed at competent, its readout in one form (39b66e5). TR10's icons installed. TR49, TR48, AR40's C, AR43, AR46, AR42, TR47's part A, TR46, AR44, AR38, TR32.
- **Next:** AR44, the critical's shine from Modulo's cut (C), then TR10's stills, then AR48's states once Modulo's sheet is picked.
- **Open, tests:** NOT VERIFIED (the Festival place, item 9): TR50's run cases, the Festival role's suite, TR48's keeper in a real run, TR49's Stage 1 playtest, TR10's marker in its world. TintMask on a phone. TR44's phone take waits for the director's go.

**Modulo (assets).** 2026-11-20, 00:07, on Opus 5.5. Voidkin work parked until before launch (the director's word, 11:10). Done: AR49's C cut for Faber, with research's four must-fixes (`build/handoff/UI/home_cards/`, e30f7bb, content check PASS), sent for research's second look. Now: AR48, the element states' cues (paused for AR49), fixing Freeze's black edges, then research's pick.
- **In the game:** AR46's Hard looks with AR47's masks, on TintMask (a856f06), passed at competent (19:18). AR42's tiles in Seam, passed at competent (f9f3636).
- **For Faber:** AR49, Home's panel in C (`home_cards.json`): 12 images to upload under the group, a ViewportFrame of the lead between `HomeVoidkinRimTop` and `HomeVoidkinFrame`, the words as TextLabels; after research's second look. AR44, the critical's shine (`build/handoff/UI/hud/critical_shine.json`). AR43, upload the five `Jewel<Colour>3.png` and swap their ids, if not done. TR10: take `MarkerElite.png` as it stands at the marker's install.
- **For Faber, AR40's install:** the atlas pair, and the Strip's eight changed meshes with the manifest, on top of the 40 base meshes, the paving and C's keys already listed in AR40. The atlas never goes alone. AR38's Shop meshes go with AR38.
- **Unchanged:** AR41's render (the director's go), AR28's Stage I on TR37, AR19's re-uploads, AR24's A on TR34, AR39 stopped, Sable after launch.

**Turns.** Studio: Faber's (Grow your Anime), open, not in Play; a second Studio, Festival Lantern, is open, not Faber's; the director's listen on TR42's panel is tomorrow, in the same place. Blender: nobody (Modulo's AR41 strips were stopped at 01:33 on 2026-11-19 by Claude Code when the PC ran low on memory; the director said wait at 01:34). Timing tests: nobody.

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
7. **Your ear on the audition panel** (TR42), ready for tomorrow: 12 tabs, the nine skills and the Mage's and Healer's hits, and a tab for each of Rook's, Kirra's and Watt's light hits drawn from your 32 keeps. In Studio's Play, the panel is at the left: a tab per hit, "Old" (today's sound) and ten candidates. Tap a row: it plays, and from then on every hit of that kind plays it in the fight. **Keep** the ones you like (more than one is fine), **More** for the next ten, **None of these** when ten hold nothing. **Others off** mutes the fight's other sounds, so you hear the candidate alone. When you're done, leave the Play running and tell Faber: your picks are read from it.
8. **Pick the slam's rule by playing it** (TR44): Off, A or B. In Studio's Play, start a keeper's try. The Server command bar switches the mode mid-fight: `game.ServerStorage.NL_Debug:Invoke("Slam", nil, "A")` (or `"B"`, `"Off"`), and `Invoke("Slam")` reads the counts. In A, walk out of the ring and your fighter follows; in B, press the round Recall button or R. Research reads a phone take of each first: say go and I record it (the PC's memory stopped it tonight).
9. **The Festival's place, for a real trip** (TR45). In Studio, open the place 110443456684004 (File → Open from Roblox) and connect Rojo on port 34876; Faber sets its role and saves it. Then, on the Creator Dashboard, under the experience's Places: its name (Faber's suggestion: Festival of Battles), its server size 8, and its Direct Access set to "Secure within universe only". Publish both places (Alt+P in each), and add the id to `CLAUDE.md`'s "Places" when you like.

### Notices

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
