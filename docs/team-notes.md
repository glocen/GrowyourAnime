# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-17, 00:13.
- **Done since 21:48:** TR28's left-side sheet passed, its "about 40" corrected (af2954f); TR24 fix 1 and the go for the director's phone run, then fixes 2 to 4 and the must-fix closed (9f7d500, ce52b0b); AR11, Watt's clips at timing, competent, Ground Wire butt-down (944aada); from the Claude team's articles, three practices kept on the director's go (9701341, the register 2026-11-17).
- **For Faber at his piece boundary:** an exploiter's pass over `Act`'s actions joins "For the Fable pass" in `docs/engineering-plan.md`.
- **Next:** the director's phone-run notes, relayed to Faber; TR34 when the chest clips land in `build/reference/chest-opening/`; AR22's tint and AR23 in the build.

**Faber (builder).** 2026-11-17, 00:31. Watt's install is in (AR11, "The install", 7cd008f). His clips play. Ground Wire stops every enemy round him for his hold, its pose held, and shields him. Insulated takes a share off a hit's elemental part. The seeds are research's tier 2. Four fight and reveal timing cases are NOT VERIFIED at 17 fps (the screen asleep) and run again at 60. The place is saved (version 677). Now: the phone run's six must-fixes (TR24, "The director's run"), then Ground Wire's blockout with Modulo once its rows are in, then TR29's three.
- **Open, tooling:** `tools/ui/kit_config.py` rewrites `Config.UIKit` whole and drops what was added by hand (Eclipse, the reveal's marks, the shard grades). Don't run it until it merges.

**Modulo (assets).** 2026-11-17, 00:35, on Opus 5.5.
- **AR11, Watt's eight clips,** are delivered (cab7a7b) and installed by Faber (7cd008f).
- **Ground Wire's look** (`/ga-action`): its grey rows are in `build/handoff/Watt/fx/` (the action's, the stop's and the shield's). They passed research's technique check and the content check, whose five block conditions are in AR11, "Ground Wire's look". Next: the blockout with Faber in the replay, once his must-fixes are done.
- **Now:** TR24's asks from the director's run: the Festival Door drawn again in two or three grey directions, then the lead card's colours in AR12's palette.
- **Later:** AR24, the chest's opening, after research's study; ids for the galaxy Breaker's six images and the festival tag's four; AR13's eleven layers, whose upload waits on the director's word; TR10's two icons.

**Turns.** Studio: the main place is Faber's since 16:23, for the phone run's fixes and Watt's blockout. Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 13. TR2, the circuit in grey (phase 1); Haymaker, on A; the Shade's burst; Pip's Lantern Burst; Lyric's Held Note; TR3, the HUD in the world; TR4, the reveal; AR7, the Lamplighter installed with his fall; his signature; Lantern Burst's exit in 3D (B1); Haymaker's square in 3D (B5); TR18, power in grey; AR12's HUD part 1. Hours are in each piece's entry.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. **Clips of the chest openings** you know, Sailor Piece's and Taichi Panda 3's, in `build/reference/chest-opening/`, for TR34 ("gimme a moment").
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

For Faber:

4. **Publish the build, for your phone run** (TR24's fix 1 is in, and research gives the go). The place is saved with it, and the Studio tool can't publish: in Studio, File → Publish to Roblox (Alt+P). The experience stays private.

5. **The test rule, in `CLAUDE.md` and `ga-finish`.** Research relays your yes (the register, 2026-11-15, night): at a piece's finish, the cases its change can reach and every offline logic case; the whole suite at a phase's close and after a change to shared code. `CLAUDE.md` changes only on your own word in the builder's session: say "write it" there and it's in.
6. **Your ear on Haymaker's strike sound**, a provisional pick, now heard on its frame. Before TR4's fix it came about 0.3 s late. Measures chose it, and only your ear accepts it. In a playtest, the Server command bar: `game.ServerStorage.NL_Debug:Invoke("Replay", nil, "RookHaymaker")` plays it every 3.5 s, and `Invoke("Replay", nil)` stops it. Two alternates are logged in AR1, section 8.

### Notices

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

