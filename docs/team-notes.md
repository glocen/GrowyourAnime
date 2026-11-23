# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-23, 22:11, on Opus 5.5 at xhigh. **The director's order (decisions.md, 00:05): the main map and the systems first; AR52 is the one exception.** Since 14:58, on the director's yes: F7 and F8 written; **F5, goals basic at launch** (design.md, "Goals"; TR54, AR53). F3's first measure: **electricity at launch is slack** (x1.8 to x7.7; balance.md, "Electricity at launch"). Passed since 16:00: AR44's shine and weights, AR49, AR52's Orange, TR10 (Badge), **AR54's yard at Stage III** (competent; the bold thing is the lines out of the heart). **AR53 picked (B, the Today card), TR54's words written** (17:49). Since: TR50 passed (18:00); AR48's states answered (18:05); **AR53's finish passed at competent** (18:27). **The director cut the Mask Ledger** (by 18:38: "we make an anime game"; decisions.md, the top row): goals are the dares and today's three, with Next at the list's head. **AR53's redraw passed at competent** (19:03). **AR55 picked** (19:09); **its finish passed at competent** (20:20, both must-fixes met, AR53's dare included). TR31 folded into TR53. AR48's check passes, Burn stays 3 s (20:07). **The director: the Tower's room drawn ahead now** (by 20:01; AR56). **AR54 with AR50's levels passed in the game** (20:26; the pulse to polish-later). **AR56 picked: A, the Crown,** with fresh eyes (20:38); **the room passes at competent** (21:38). The room is kept as it is, on the director's pick by 21:53, with its height to polish-later. **AR57 written** (21:54): the Guard's and the Dasher's elites, Modulo's next. **TR52's block read** (22:11): its run is the director's, at both thumbs. **AR51 passed at competent** (21:33).
- **Next, mine:** F3's rest (the launch's length, every resource at day 1, 7 and 30, then the power fix for the director); F7's timing when the places are published (item 4).
- **Faber's order:** (1) TR50, then AR48's states, as you have them; (2) AR50's and AR54's install, done and passed; (3) AR51, passed; (4) TR52; then AR52's behaviours, TR54 and TR53. F7's timing whenever item 4's publish lands. Effects and sound data from Scintilla and Sonus come to you for review before your push.
- **Modulo's order:** **AR57, the Guard's and the Dasher's elites** (the director, by 21:53). AR56 is closed and kept as it is; Faber's install comes after the main game.
- **With the director:** **TR52's run**, the signature on a tap: Lantern Row once with Auto on, then with Auto off with the ring at each thumb (TR52, research's read); answer **item 10 in Faber's session** (the hooks for Scintilla and Sonus); **item 4**, publish both places and Faber's OK to run the player once; open two sessions titled **Scintilla** and **Sonus**; `src/shared/Config/Sounds.luau`'s uncommitted change; the store's design.

**Faber (builder).** 2026-11-23, 22:08, on Opus 5.5.
- **AR51 is closed** at competent (research's second look, 721e825). Must-fix 3 and the guide's arrow riding the chip are in (23980a0).
- **TR52's block is in the game** (TR52, "Faber's block"):
  - the readout is the button; a full ring left untapped pulses once; Auto sits after the eye.
  - The measure: the ring and the jump button don't meet (582 px apart). The ring stands at the dynamic stick's top edge, and a touch on it never starts the stick.
  - Captures are in `build/captures/tr52/`.
  - **Waits:** the director's Lantern Row run with Auto on and one off, then research's verdict.
- **Next:** AR52's behaviours, TR54, and TR53 (with TR31 folded in). F7's timing waits on item 4's publish.
- **The hooks for Scintilla and Sonus** wait on the director's own word (item 10). **Open, tests:** as before.

**Modulo (assets).** 2026-11-23, 21:55, on Fable 5.2. Voidkin work parked until before launch (the director's word, 11:10).
- **Now: AR57, the Guard's and the Dasher's elites,** in progress (the look first, then the two clips at the elite's scale in AR52's timings). AR56 is closed on my side: the director keeps the Tower room as it is (decisions.md, by 21:53); the room, its entrance and record marker are in `build/handoff/TowerRoom/` (AR56, "Modulo's finish"), for Faber's install after the main game. The two grey tests of the height stay in the generator (`stand`, `landing`). Nothing in the game, nothing uploaded.
- **For Faber:** TR53's look is `build/handoff/UI/return/` (the kit builds the slab, the lines and the presses; three images to upload; the Training line takes the kit's small portrait). The dare's open tab is in `goals.json`, "unfolded". My sheets are the strict case: the game has a sixth more room at the smallest phone. TR54's look is the goals' handoff: `DareMark*` where `DareTag*` stood (the origin is now the mark's middle), one `GoalNext` plate that holds the back press, no Ledger; `HomeSettings` gives way to the cog tile and the Today card. The Guard's clip is fixed (AR52, "The Guard's sleeve, fixed at the clip's finish") and goes up once as `ShadeGuard`.
- **Next:** whatever research orders after AR57.
- **Still Faber's, each in its entry:** AR49's Home panel, AR44's shine, AR40's install (the atlas never alone), AR48's cues, TR50's dusk palette, the Voidkin screen's floor, AR50's seven pieces.

**Turns.** Studio: Faber's, on the main place, the playtest stopped between pieces (2026-11-23, 15:15); the director's listen on TR42's panel is tomorrow, in the same place. Blender: nobody (Modulo's AR41 strips were stopped at 01:33 on 2026-11-19 by Claude Code when the PC ran low on memory; the director said wait at 01:34). Timing tests: nobody.

**The count.** Week of 2026-11-23: 0 pieces closed and playable so far. Today's closes are art and picks (AR48, TR50's palettes, AR50's pick), all waiting on their install, which is how they become playable.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. **Clips of the chest openings** you know, Sailor Piece's and Taichi Panda 3's, in `build/reference/chest-opening/`, for TR34 ("gimme a moment").
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Publish the build, for your phone run** (TR24's fix 1 is in, and research gives the go). The place is saved with it, and the Studio tool can't publish: in Studio, File → Publish to Roblox (Alt+P). The experience stays private.
   - **The same publish unblocks F7's timing** (`docs/research/design-holes.md`, F7, "The check"). Faber times the published places: the door, the trip, and Lantern Row's first hit. The starter shard is timed in Studio, on a new Test save. Your Live save is never wiped.
   - **What Faber needs from you:**
     - the Festival's place published too, with today's build;
     - your OK for Faber to start the PC's Roblox player into the private game under your account, for one timed run.

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. **Your ear on Haymaker's strike sound**, a library pick (not one of AR13's made takes), heard on its frame. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.
7. **Your ear on the audition panel** (TR42), ready for tomorrow: 12 tabs, the nine skills and the Mage's and Healer's hits, and a tab for each of Rook's, Kirra's and Watt's light hits drawn from your 32 keeps. In Studio's Play, the panel is at the left: a tab per hit, "Old" (today's sound) and ten candidates. Tap a row: it plays, and from then on every hit of that kind plays it in the fight. **Keep** the ones you like (more than one is fine), **More** for the next ten, **None of these** when ten hold nothing. **Others off** mutes the fight's other sounds, so you hear the candidate alone. When you're done, leave the Play running and tell Faber: your picks are read from it.
8. **Pick the slam's rule by playing it** (TR44): Off, A or B. In Studio's Play, start a keeper's try. The Server command bar switches the mode mid-fight: `game.ServerStorage.NL_Debug:Invoke("Slam", nil, "A")` (or `"B"`, `"Off"`), and `Invoke("Slam")` reads the counts. In A, walk out of the ring and your fighter follows; in B, press the round Recall button or R. Research reads a phone take of each first: say go and I record it (the PC's memory stopped it tonight).
9. **The Festival's place, after the main map and the systems** (TR45; your word of 2026-11-23, 00:05: the team has full access to it). When its work opens, the Creator Dashboard's settings stay yours to confirm: its name (Faber's suggestion: Festival of Battles), its server size 8, and its Direct Access set to "Secure within universe only". Then the id goes into `CLAUDE.md`'s "Places".

10. **The hooks for the new seats.** Research relays your yes of 14:50 to two teammates. Their hooks are permission settings, and a relayed word can't change those, so Faber waits for yours. The change, in `.claude/hooks/`:
    - `Effects` (`^Scintilla`) and `Sound` (`^Sonus`) in `config/roles.json`;
    - their briefs in `hooks.json`'s drift guard;
    - Studio's playtest tools for both in `tools.json`: start and stop, run code, the input tools, as research has;
    - Effects among the uploaders in `open_cloud_guard.py`, so Scintilla uploads under the group with its key, inside the guard's own limits (a new asset only, from `build/upload/`, at price 0).
    - Until then their Studio calls are blocked.

### Notices

- Tier 2, research, 2026-11-23, 20:07, TR53: TR31 folded in. The battery's line shows only a net gain, and reads "Full" with the overflow's Credits when it sold. Faber: say in your row what you'd change.
- Tier 2, research, 2026-11-23, 17:49, AR53: Home gains a **Today** card (today's three goals, Next at the list's head) in Settings' column, Settings a cog tile over it. A run's dares sit under the run's line (no start card); a dare kept before a fall is paid.
- Tier 2, research, 2026-11-23, 14:54, AR52: the Guard and the Dasher join Lantern Row's stretches, with mixed outline types (Green, Orange) so no one lead wins the run; Modulo's masks and clips now, Faber's behaviours after the backlog. Faber and Modulo: say in your row what you'd change.
- Tier 2, research, 2026-11-23, 14:58, TR53: a return card at the base (what it made while you were away, one tap) and the base's shard shown during a run. Faber: say in your row what you'd change.
- Tier 1, research, 2026-11-23, 14:54, TR52: the signature on a tap, tried as a block with an Auto toggle; launch is the director's call after the verdict.
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

### 2026-11-23, 22:08. TR52, the signature on a tap, a block in the game (Faber)

- **What changed:** the signature's readout is the button, firing as the touch goes down, and it squeezes in on that frame. An **AUTO ON / AUTO OFF** toggle stands after the eye. With Auto off, a full ring waits for the tap and pulses once. A tap fires the signature once, cutting the combo when its target is in range. A ring not full does nothing.
- **The measure:** the ring and Roblox's jump button don't meet (582 px apart on the smallest phone). The ring stands at the dynamic stick's top edge, and a touch there is the ring's: the stick never starts.
- **Where:** TR52, "Faber's block"; `Rules.Fight.Tap`, `FightService.Tap`, the `Signature` remote, `Config.Hud.Readout`, `SelfTestController/SignatureCases.luau`.
- **Tested:** type check 0 new; 29260 logic; "HUD: TR52" 16/0; "HUD:" 548/0, "Kit:" 85/0, "Camera:" 37/0; "Fight:" 640/8, all eight Ground Wire's known order effect (20/0 alone and after TR52).
- **Open:** the director's Lantern Row run with Auto on and one off, then research's verdict.
- **For:** research and the director, with captures in `build/captures/tr52/`.

### 2026-11-23, 21:46. AR56: the Tower's room, the Crown, delivered as a kit (Modulo)

- **What changed:** the Tower's room exists as art: an open floor at a tower's top, eight blades leaning out of the rim, the floor's number on a slab afloat, the foe up four steps over the far rim, cloud under the horizon in the sky's faces. Its entrance and record marker for the lot are drawn in the same make.
- **Where:** `build/handoff/TowerRoom/`; AR56, "Modulo's finish"; `tools/blender/tower_room_kit.py`.
- **Checked:** content check PASS twice; research's passes at competent, the room at its second look and the entrance at its first. Stills and a take only.
- **Open:** the drop doesn't read from the fight's camera (the rim hides all but 7 degrees), and a raised stand hid the fighters. A grey test of a landing at the door is next, then the director's pick; if picked, the sky's faces and one piece change.
- **For:** research (the test); Faber at the install, after the main game: ten pictures to upload, and the checks in the entry.

### 2026-11-23, 21:18. AR51, the Stone Condenser's two faces, built (Faber)

- **What changed:** B's convert card beside the cradle, asleep, ready, short and running. The Power screen has the Condenser's Rose share, its six-sided chip, and a third row and handle. On the smallest phone the list is cut to whole rows (must-fix 2).
- **A finding fixed:** Roblox's prompt card is drawn under our layers, and the card hid its words. The card now stands right of it (`UI.World.Beside`). The phone take is faithful now: the camera's field, the World layer and the guide's arrow are all framed as the phone's.
- **Where:** AR51, "Faber's build"; the asset log's row 145 (two uploads, Approved).
- **Tested:** type check 0 new; 29247 logic; TR37 41, the guide 11, "Power:" 108, "Base:" 371, 0 failed.
- **Open:** the guide's arrow over the avatar and the prompt on the smallest phone (for research's call); B's 3D stones on the cradle, not built.
- **For:** research's pass, with stills in `build/captures/ar51/`.

### 2026-11-23, 20:24. AR50's and AR54's install, built (Faber)

- **What changed:**
  - The base's deck is AR54's: sixteen floors, the plan's `layout`, and each later bay at its turn.
  - Part 7's measure reads that same layout at Stage III's prints. The trial's three layouts are gone.
  - The landing's ring scales to end at 25 studs.
  - AR50's levels stand at each level's generator swap: the deck's light, the fins, and the two rings turning opposite ways on one axle. Bays 3 and 4 wear their wake while awake.
- **Where:** AR54, "Faber's install, with AR50's levels". Code in `WorldService` (`layLevels`), `BaseService` (showPlot), `Rules.BaseFit` (`Turned`), `Rules.Landing` (`Reach`) and `Kit.Floors`. 25 meshes and 30 pictures are uploaded and Approved, with their ids in the asset log.
- **Run:** type check 0 new; logic 29247 passing; "Base:" self-test 364 passed, 0 failed; world report empty; `base_levels_clear.py` PASS. **Not verified:** a wake on a bay awake from a save. The test save has two bays open.
- **For:** research's read in the game (stills in `build/captures/ar54/`, the smallest phone's from the gate included). The director's acceptance waits.

### 2026-11-23, 18:13. TR50, one mission per Arc, closed at competent (Faber)

- **What changed today:** the Arc panel and the run's card in the festival's dusk (Modulo's palette B), and the Voidkin stage's floor B: stone and a Neon ring of the element. Research had two must-fixes:
  - the stone now shows `#A9A59B` under every rarity's light, by the stage's measured light model (`Voidkin.Stage.Floor`: Shows, Lit);
  - Back stays on the run's card, as its one way to stay on the street.
- **Where:** TR50, from "The dusk palette and the Voidkin floor, installed" to "Closed"; `Config.Hud` (Stages.Arc, Voidkin.Stage), `StageScreen`, `VoidkinScreen/Figure`, `Kit/Button` (Underline), `Kit/Screen`.
- **Run:** self-test 3,376 passed, 2 failed: the shop's passes alone, and the keeper lantern's is an intermittent frame check (since 2026-11-17), rerun next. Logic offline: 29,197 passed. Stills in `build/captures/tr50/`.
- **For:** research, who passed it at 18:00. The director's acceptance waits.

### 2026-11-23, 17:33. TR10, the down badge, closed at competent (Faber)

- **What changed:** the elite's and the keeper's marker is Badge alone: far, its icon's tile and its time, sized by the world (Full / distance, floored at a 28 px tile on the smallest phone). Past Near its loot card opens downward from the tile in 0.18 s. It stands open over its square, no longer on the avatar's head. Stack and Row are gone.
- **Where:** TR10, "The two fixes, and the walks for the second look"; `DownController`, `Config.Hud.Down`. Takes now centre the phone on the window (`Layers.Box`'s place).
- **Run:** the self-test 3,351 passed, 1 failed (TR42's flake, which passes alone); LogicTests 29,156. Walk strips in `build/captures/tr10/`.
- **Open:** the Festival case "World: TR10" runs only in the Festival's place, once published.
- **For:** research, who passed it at 17:06 (TR10, "Research's second look").

### 2026-11-23, 16:00. AR44's critical shine, built (Faber)

- **What:** take C on the critical. The chrome ramp; a cyan and red split that lands at 7 points and settles to a 4.6 hairline; a white flash; one glint across the number. Live in `Config.Hud.Numbers.Critical.Shine`; the copies in `FighterController/Shine.luau`.
- **Found:** the numbers' and cards' outlines were scaled twice (1.5 times in Studio, 0.85 on the smallest phone). Now authored: a tier 1 notice to research for a re-read of the weights.
- **Run:** the self-test 3,309 passed, 0 failed; LogicTests 29,155; WorldReport empty. Stills in `build/captures/ar44/`.
- **For research:** AR44's read, and the weights. **For Modulo:** TR51's plate lives in Gate1's mesh.

### 2026-11-23, 15:15. The Studio run of AR49, TR51 and TR37; AR30's dock seeds (Faber)

- **Run in Studio** (ef86dab): the self-test 3,288 passed, 1 failed (TR42's flake, which passes alone); LogicTests 29,155; WorldReport empty. Five fixes, FxKit rebuilt with the landing's look. The records: TR51 and TR37, "The Studio run"; AR49, "Faber's build".
- **TR51:** the stages from the gate and the court, on the smallest phone, the landing mid-swap, and the shards in their chambers, in `build/captures/tr51/`. Stage III's footprints break today's plan (tier 2, research and Modulo), so the Fit Prints stay at Stage I. The plate's top is cut from the gate's eye.
- **TR37:** the Forge and the Condenser, awake and asleep, in `build/captures/tr37/`. **AR49:** stills with Rook and Kirra in `build/captures/ar49/`; its take now sets the lead through the save.
- **AR30:** Rest 0.4, Open 0.6, Quiet 0.2, with a take and six stills on the pale deck and the dark lane (`build/captures/ar30/`). Nothing blooms past the glass, so the reach stays.
- **For research:** four reads. **For the director:** the new seats' hooks (item 10).

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
