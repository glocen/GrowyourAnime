# Orchestration: one language of feedback

Study of 2026-11-24, for the director's words: "make every systems well implemented and orchestrated ... the synchronization and holes details filed ... just to make it 1 whole premium game". Read from MAIN's code and docs; line numbers are MAIN's as read today. Every number proposed here is a seed to tune by playing. Short paths: `Main/` is `src/client/Controllers/Main/`, `UI/` is `src/client/UI/`, `Config.X` is `src/shared/Config/X.luau`.

## Verdict

1. **There is no conductor.** Seven pieces announce events (damage numbers, the toast, the level plate, the quiet note, the dare line, the drop's plate, the pills) and each decides alone. No queue, no priority, no fight gating: `Theme.Time.Fight = 6` is defined in `UI/Theme.luau:111` and nothing reads it.
2. **The importance ladder is real in combat and absent everywhere else.** Rungs drive hitstop, pill pops and number size (three configs). Notices and sound have no rung at all.
3. **Sound inverts importance.** An ordinary hit has a cue. The keeper's fall borrows a Shade's. Level-up, lead down, a drop, a goal, a purchase, an upgrade and a machine stage are silent.
4. **Meanings share signals.** Gold says ready, claim, Power, critical, Legendary, level, record and every shard drop. Red says harm, refusal, failure, Hard and Mythical. Refusals come in three tones and about twenty wordings.
5. **The fix is structural and small:** one door for notices (a "Conductor"), one sheet (meaning to signal), one Rarity table, eight cues. About 3 builder days plus Sonus's UI family. No new art for the block.

**Limits of this study.** The web search budget for this session was used up, so no searches ran. I fetched known primary pages directly; what I could not reach is listed in section 4. The four sibling studies written in parallel (`systems-that-marry.md`, `systems-map.md`, `seams-and-states.md`, `detail-pass.md`) were not read.

## 1. What each event gets today (OBSERVED)

"none" means I read the code and it is silent there. "not found" means I searched and found nothing. Haptic is one line for the whole table: only button presses (`UI/Kit/Button.luau`, `HapticEffectType.UIClick`); no game event has one.

| Event | Words: place, time | Colour | Sound | World, camera, hold | Home |
|---|---|---|---|---|---|
| Hit | number over the target, 0.8 s | ivory #F8F1DF, element colour behind | `LightHit`, `HeavyHit` (Voices 4, 2) | hold 0.045 to 0.05 s, flash; rungs 2 to 3 | `Config.Hud.Numbers`, `Config.Combat.Hitstop.Rungs`, `Config.Cues` |
| Critical | number at 1.6, slanted | gold #FFCF4D | `Critical` over the hit's cue | hold 0.07 s, trauma 0.35; rung 4 | same |
| Kill | "+N" at the Credits pill; the run line's notch pops | teal pill | `ShadeBurst` | burst, hold 0.13 s, 4 to 8 icons fly 0.5 s | `Main/FighterController/init.luau:457`, `Config.Hud.Motion.Fly` |
| Elite enters, falls | none on entry; brass edge on the target card; a down marker with a timer | brass | none of its own | none of its own | `UI/TargetCard.luau`, `Config.Hud.Boss.Elite`, `Main/DownController.luau` |
| Keeper enters | boss bar stamps in, top middle, 0.14 s | purple #9150FF | none (`Config.Music` list `Keeper` is empty) | fade around the try | `UI/BossBar.luau`, `Config.Hud.Boss` |
| Keeper falls | none for 2.4 s (`WinPause`), then the card: "{ground} cleared" | card colours | **the same `ShadeBurst` cue as any Shade** | its fall effect; no hold or camera of its own | `init.luau:452-460`, `Config.Effects.Falls.Lamplighter` |
| Lead is hit | number at 1.2 | muted red #E27A6A | none | jolt (trauma 0.45) at 10% of health in one hit; no vignette | `Config.Combat.Shake.Hurt`, `init.luau:1165` |
| Lead down | card: seconds until back, Send or Home; results: "Your lead fell" | portrait dims 0.55; title in Hurt red | none | grey stand-in column; no camera | `Config.Effects.LeadLeaves`, `Config.Hud.Fallen`, `UI/StageScreen.luau:806` |
| Shard drop | plate at the drop about 0.8 s, then toast "+N {Shard}" top right 2.5 s | **Ready gold for every grade** | none | Neon block pops, bounces, flies to the avatar | `FighterController/Effects.luau:2257`, `Config.Effects.Drop`, `Main/HudController.luau:939` |
| Chest, stone, emblem drop | none in the fight; chests on the results card; dropped stones and emblems not found on any card | none | none | none | `Config.Chests.Drop`, `Config.Drops`, `StageScreen.luau:751-760` |
| Credits | pill counts 0.6 s, "+N" rises | teal (gold on the Tower card) | none | icons fly | `Config.Hud.Pop.Rungs.Credits`, `UI/TowerScreen.luau:212` |
| Experience | glint on the thread | xp blue #4E9BFF | none | none | `Pop.Rungs.Xp = 2` |
| Level-up | violet plate "LEVEL UP" under the lead card, 2.5 s | violet plate, gold badge #F2CB62, blue column | none | column 0.7 s, badge burst at rung 5; no hold | `UI/LevelNotice.luau`, `Config.Hud.LevelNotice`, `Config.Effects.LevelUp` |
| Goal progressed, done | **none on the HUD**; pips and a gold claim row on Home's Today card | gold | none | none | `UI/TodayList.luau`, `Config.Goals` |
| Dare kept, broken | the line shows 3 s at a stretch's start; its mark flares 0.4 s or goes dark | mark only | none (by design: "no words, no sound") | none | `UI/DareLine.luau` |
| Shard ready | chamber flashes "Ready" 1.5 s; chip breathes; world prompt. Only at the base | gold #FFD880 | none | none | `UI/BreakerScreen.luau:335-353`, `Rules.Hud.ShardHint` |
| Reveal | rarity word, pip, name; skip opens at 1.0 s | six rarity colours | full ladder by rarity; world ducked 6 dB | whole flash for Legendary, Mythical | `UI/Reveal/`, `Config.Reveal` |
| Machine stage climbs | none | void light | none ("No sound yet") | "Climbing Ring", about 1 s; no camera | `Main/LandingController.luau`, `Config.Landing` |
| Battery, tray full | the pill's word reads "full"; "Tray full · N" | pill colours | none | none | `Main/HudController.luau:1338` |
| Purchase | toast "{name} bought: it's in your Inventory", 2.5 s | ivory | none | the button's charge only | `UI/ShopScreen.luau:245` |
| Upgrade result | "Reinforced to +N" or "Failed: it stays at +N", inline | green #7CF0A4 or red #FF786E | none | ring, sparks, crack | `UI/EquipmentScreen/Reinforce.luau:333-336` |
| Refusal | grey toast, ivory toast or red inline, by system | three tones | none | the dock tile shakes (home jump only) | section 2 |
| Tutorial pointer | next-step chip over the dock; chevron in the world; edge arrow | chip colours | none | bobbing chevron | `UI/Guide.luau`, `Config.Hud.Guide` |
| Travel | full-screen card; failure as an ivory toast | grey block | none | black fade | `UI/TravelCard.luau`, `Main/TravelController.luau:87` |
| Record | "a new best" (stage) or "A new record, past floor N" (Tower) | Ready gold | none | none | `StageScreen.luau:866`, `TowerScreen.luau:206` |
| Signature ready | readout reads "Ready", swells every cooldown, pulses if untapped | white-hot #FFFFFF | not found | none | `UI/Readout.luau` |

## 2. Reading the table

- **Big events are quieter than small ones.** A hit has four channels (number, cue, hold, flash). The keeper's fall, the run's peak, adds nothing a Shade's kill lacks except its effect. Level-up has a plate and a column and no sound. OBSERVED.
- **One meaning, many signals.** "Ready" is gold in the Breaker and white on the readout. "Record" has two wordings. Credits are teal on the pill and the stage card, gold on the Tower card. The player's storage is "the bag" in `VoidkinScreen/Bag.luau:106` and "your Inventory" in `ShopScreen.luau:72`. OBSERVED.
- **One signal, many meanings.** Ready gold paints a shard drop (a reward), a ready chamber (a call to act), a record and the claim row. One red family carries the lead's damage (#E27A6A), failure and refusal (#FF786E, `UIKit.Bad` #FF7A66), danger skulls (#FF4F42), Hard (#FF9A80) and Mythical (#FF8794). One green carries success, heal, type advantage and Uncommon. OBSERVED; the gold count is `ui-colour-review.md`'s.
- **Rarity speaks five dialects.** Reveal: frame, word, pip, light, sound, flash. Lead card: frame and trim. Bag: a coloured word. Breaker rates: coloured headings, with Common lifted to another grey (`Config.Hud.Breaker.Tier`). World drop: nothing. Tower chests: plain text. OBSERVED.
- **Refusals have no house style.** Grey toast (`ShopController.luau:92`, `Bag.luau:139`), ivory toast (`HudController.luau:714`, `Kit/Button.luau:466`), red inline (Reinforce, `ShopScreen.luau:206`). Same shortage, five phrasings: "Not enough Credits", "Not enough Credits: N short", "Need N more", "Not enough charge in the battery", "Needs N kWh". `BaseController.luau:173` can show a raw error code: `Not now: {answer.Error}`. OBSERVED.
- **Silent holes.** A chest, stone or emblem that drops in a fight; a goal completing during play; a shard ready or a full battery while the player is away from the base. `docs/ui.md` rule 4 says the interface never lies; here it says nothing. OBSERVED.
- **The loudest recurring thing on the HUD is the signature's "Ready".** The file's own header calls it "the loudest piece on the HUD". It fires every cooldown. OPINION: that is defensible (it is the one input in a fight), but it must not out-shout a level-up, and today it does.

## 3. Priority and concurrency today

- **Toast** (`UI/Kit/Toast.luau`): two stacked (`Theme.Time.Toasts`), 2.5 s each; a third pushes the oldest out. No priority, no merge, no queue, no icon, no sound. OBSERVED.
- **Level plate and quiet note** share one place under the lead card (`Config.Hud.LevelNotice`, `Config.Hud.Note`). I found no rule between them. OBSERVED.
- **The only merges:** `UI/Kit/Pop.luau` counts wins inside one "+N"'s life as one number, and damage numbers take slots. The only yield: numbers step aside for rung 7 and up (`Config.Hud.Numbers.Yield`). OBSERVED. Both are good and should become the general rule.
- **Layers:** toasts are layer 40, the reveal is 35 (`Config.Reveal.DisplayOrder`, `UI/Layers.luau`). A toast can draw over a reveal. OBSERVED.
- **Reduced Motion** is read in the HUD and the Kit, and not in `FighterController/` or `UI/Reveal/` (searched, none): shake, tremble and the whole flash ignore it. OBSERVED.

**The same-second test** (a level-up, a goal done and a rare drop land together in a fight). Today: the level plate slides in left for 2.5 s with a column and a badge burst; the goal says nothing; the drop pops as a gold block with a gold plate, then a gold toast right for 2.5 s; Credits icons fly; damage numbers keep going. Nothing is ordered, nothing is heard, and the rarest of the three (the drop) looks like every other drop. A second and third toast would push the first out before it is read. OBSERVED from the code paths; not played.

**Attention budget.** OPINION: on a phone in landscape, a fight can carry one sentence at a time. Today a fight can show at once: numbers, the boss bar, the dare line (3 s of words at each stretch's start), the level plate, two toasts, the drop's plate and the readout's pulse. The dare line and the toasts are the two that put sentences in a fight.

## 4. Outside study

- SOURCED. Android's notification importance is a ladder where each step adds a channel: Low shows quietly, Medium appears with no sound, High adds sound, Urgent adds sound and a heads-up. https://developer.android.com/develop/ui/views/notifications/channels **For us:** the same shape for our bands, in section 5a.
- SOURCED. Apple's four interruption levels (Passive, Active, Time Sensitive, Critical): "Build trust by accurately representing the urgency of each notification." https://developer.apple.com/design/human-interface-guidelines/managing-notifications **For us:** the readout's recurring pulse spends trust the keeper's fall needs.
- SOURCED. Material's snackbar: "Only one snackbar will be shown at a time. Showing a new snackbar will dismiss any previous ones first"; they "shouldn't interrupt the user experience". https://github.com/material-components/material-components-android/blob/master/docs/components/Snackbar.md **For us:** our two-stack with oldest-out is close to this for low news, and wrong for news that must not be lost. Low news may replace; high news must wait.
- SOURCED. Haptics, Apple: "Use haptics consistently", build "a clear, causal relationship between each haptic and the action that causes it", "Prefer using haptics to complement other feedback", "Avoid overusing haptics". https://developer.apple.com/design/human-interface-guidelines/playing-haptics Android: "Correlate event importance and frequency with strength"; co-design visual, audio and haptic; "Given the choice of buzzy haptics or no haptics for touch feedback, choose no haptics". https://developer.android.com/develop/ui/views/haptics/haptics-principles **For us:** haptic only on presses and the top bands, never alone (`devforum-ui.md` tip 26: phones may not fire it).
- SOURCED. Xbox Accessibility Guideline 103: "Color alone should never be used to represent information"; critical colour needs "at least one additional signifier such as shape, pattern, iconography, or text labels"; its own example is rarity colours. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 Game Accessibility Guidelines: no essential information by a fixed colour alone (about 8 to 10% of males), nor by sound alone; the test is a first play with sound muted. https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/ **For us:** a pip count per rarity, everywhere. And a frank note: we pass the muted test only because almost nothing has sound; we fail the reverse (eyes off the lane, nothing is heard).
- SOURCED. WCAG 2.3.1: nothing flashes more than three times in one second; saturated red has its own threshold. https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold.html **For us:** backs `vfx-quality.md`'s flash rule; the Conductor is where the count lives.
- SOURCED (names only). Roblox's `GuiService` lists `ReducedMotionEnabled`, `PreferredTransparency` and `PreferredTextSize`. https://create.roblox.com/docs/reference/engine/classes/GuiService The page gave me no descriptions.
- COMMUNITY. Destiny's engrams "use the same color coding" as weapons and armour, and lie on the ground in their rarity's colour. https://www.destinypedia.com/Engram **For us:** the principle only: rarity is readable at the drop, before the pick-up, in the same colours as the bag and the reveal.
- Through siblings, not re-fetched: Riot's "If everything is important, nothing is" (`docs/research/vfx-reference.md`); Diablo IV's importance cap and the sound priority list (`docs/research/sound.md`); Material's sound guidance (`menu-layout-and-motion.md`).
- **Not fetched:** the Overwatch "Play by Sound" talk (abstract only, which does not describe its ranking); Genshin and Zelda item-get hierarchy; Hearthstone and Marvel Snap feedback grammar; Nintendo's sound-as-UI; the juiciness study (the journal page returned 403); Roblox's 2026 accessibility settings beyond the three names above. Nothing in this file rests on them.

## 5. The conductor's rules (proposals)

Band names are internal. Any that reach a player need the IP-list check.

### 5a. The importance ladder for every event

It extends the effects ladder in `docs/research/vfx-reference.md` (rungs 2 to 10); it does not replace it. A band is a span of rungs with fixed channels. **Each band adds a channel the band below never uses.**

| Band | Rungs | Events | Channels | Zone | Time | May interrupt | Sound family |
|---|---|---|---|---|---|---|---|
| 0 Still | under 2 | xp gained, battery filling, goal progressed, next-step chip | the element itself moves (glint, fill, pip) | its own counter | to 0.35 s | nothing | none |
| 1 Tick | 2 to 3 | hit, Credits gained, a press, a refusal | a number or a count, one pulse; no words beyond a reason | at the source | 0.1 to 0.8 s | nothing | hit cue, or a tap at UI level |
| 2 Beat | 4 to 5 | critical, kill, shard caught, Common or Uncommon drop, dare kept, a heavy hit on the lead | adds fly-to-counter, a hold to 0.13 s, an icon chip; never a sentence | source to counter | 0.3 to 1 s | merges band 1 | reward ticks; struck |
| 3 Line | 5 to 6 | level-up, goal done, shard ready, Rare and up drop, purchase, upgrade result, battery full | adds one line with an icon, and a phrase | the lanes (5c) | 1.5 to 2.5 s | nothing; it waits | UI family phrase |
| 4 Strike | 7 to 8 | Voidkin's signature, keeper's signature, elite or keeper enters | adds the screen's top value, hold 0.13 to 0.14 s, music duck; numbers step aside | the world's centre; a name stamp top middle | 0.3 to 1.2 s | pauses bands 2 to 3 | Lead bus, full |
| 5 Payoff | 9 | keeper falls, ground cleared, lead down, new record, machine stage climbs | adds the centre (a stamp or a card), its own cue, a music gap | centre | 2 to 4 s | all below; they defer | its own phrase |
| 6 Event | 10 | Legendary or Mythical reveal; a first-ever reveal or clear | adds the whole screen; music to silence | whole screen | 4 to 10 s, skip at 1.0 s | everything | the reveal's ladder |

Lead down is a band 5 loss: same zone and weight, the quiet tone (`docs/ui.md` rule 5: "a failure is quieter but still felt").

### 5b. The semantic sheet: one meaning, one signal

Colours are `ui-colour-review.md`'s "Night glass" tokens; sounds are `audio-direction.md`'s UI family. The director's ear picks every cue; changing a colour the director picked needs their yes.

| Meaning | Colour | Shape | Sound | Word | Today |
|---|---|---|---|---|---|
| Reward: you got it | the thing's own colour (Credits teal #40DCC6, xp blue, its rarity) | its icon flying to its counter | count ticks | "+N Thing" | drop and toast in Ready gold |
| Ready: it waits for you | accent.action #E9B65C, breathing | a filled dot on the tile that leads there | one open note (E), unanswered | "Ready" | four gold hexes; white on the readout |
| The taking press | the same plate | a verb on the plate | Confirm (A to E) | "Collect" for what's earned; "Open" for a shard or chest | Collect, claim, Open, Take out |
| Done: the server said yes | good #6FE3A0 | a check | Confirm; three notes up for an upgrade | past tense: "Bought", "Collected", "Reinforced to +N" | ivory or green |
| Failed: tried and lost | bad #FF7F70 | a split mark (the broken dare's) | a crack and a falling pair, quiet | "Failed: {what stays}" | red |
| Refused: not yet | grey ink #6B7386; the control shakes; only the shortfall number in bad | a lock or a slash | Refused (one dull note twice, once a second at most) | "{What's missing}: {how much}" | three tones |
| Danger: harm to the lead | the bad family, on numbers and skulls only | skull, down arrow | a low struck thud; never the Refused note | none | no sound |
| Rarity | six colours from one table | one to six pips, and the frame | six notes, one per rarity (A C D E G A) | the rarity's word | typed four times, five dialects |
| Progress | xp blue for xp; ink for the rest | thread, notch, pip | none below band 2 | "N / M" | consistent |
| Record | accent.action | a notch above a line | Goal done's phrase plus its top note | "New record" | two wordings |

- **Gold.** Night glass still leaves three golds (action, Power #FFE266, Legendary #FFC24A). Shape must carry the difference: a plate with a verb is an action; pips and a frame are Legendary; a glyph and a number are Power. Critical keeps its slanted gradient. OPINION.
- **Red and green.** Mythical and Hard sit inside the harm family: Mythical always wears six pips and its frame; Hard gets a mark, not a red word. Uncommon is near good: a rarity never appears as a bare coloured word (`docs/ui.md` rule 3 already says so).
- **The rarity notes** are the neat part: the audio direction's six-step set (PlaybackSpeed 1, 1.189, 1.335, 1.498, 1.782, 2) is exactly six rarities. A drop plays its one note; the reveal's rung climbs to it. Sonus's and the director's call.

### 5c. Queue rules

1. **One door.** Every system calls `Conductor.Say(kind, payload)`; nothing calls `Toast.Show` directly. Kinds live in one config (kind to band, lane, merge key, cue, words). The ordering rule is pure Luau, tested with Studio closed.
2. **Two lanes, one centre.** Left lane under the lead card: the lead's news (level-up, notes). Right lane under the pills: rewards and refusals, next to the counters they feed (`docs/ui.md`'s "event chips"). Centre: bands 4 and up only.
3. **Caps.** In a fight (within `Theme.Time.Fight` of the last hit): one item per lane, one world plate, numbers. Out of a fight: two in the right lane.
4. **Merge.** Same kind and same thing within 1.0 s becomes one line that counts up. A repeated refusal re-shakes its control; no new line.
5. **In a fight,** a band 3 item that is not about the fight (goal done, shard ready, battery full) shows as an icon chip for 0.8 s with no words. Its line plays when the fight ends, or only on the results card if the run ends first.
6. **Same frame:** higher band first; then about-the-fight first; then rarity; then arrival. 0.25 s apart.
7. **Bands 4 and up** pause the lanes' timers. Bands 5 and 6 clear the lanes and defer their items until the card closes. Nothing draws over a reveal, the travel card or the results card.
8. **Loss.** Bands 3 and up are never dropped. Bands 1 and 2 waiting more than 4 s are dropped: their counters already show them.
9. **Sound.** One cue per event. Two cues of one family within 80 ms: the higher band plays, the other is skipped. Bands 5 and 6 duck everything.
10. **The results card is the run's ledger:** Credits, shards by grade, chests, stones, emblems, levels gained, goals done, dares, record, in band order.
11. **Reduced Motion:** slides become fades, shake is off, the whole flash becomes a 0.3 s lift. The flash count (three a second, `vfx-quality.md`) is kept here.

The same-second test under these rules: the Rare drop falls in its own colour with its note; the level plate takes the left lane; the goal shows a pip chip; after the fight, "Goal done" takes the right lane; all three are on the card.

### 5d. The moments map

| # | Moment | Rung | What only it (and those above) gets | Missing today |
|---|---|---|---|---|
| 1 | Legendary or Mythical reveal | 10 | the whole screen, music to silence, the whole flash | a toast can cover it; no Reduced Motion path |
| 2 | Keeper falls, ground cleared | 9 | a long last hit (hold 0.2 to 0.3 s), its own cue, a music gap, a centre stamp before the card | a Shade's cue; no hold of its own; 2.4 s of nothing |
| 3 | A reveal with news (a new Voidkin, any rarity) | 8 to 9 | the full reveal form (`reveal-and-showcase.md`) | length follows rarity, not news |
| 4 | New Tower record | 9 | a centre stamp on the card, the record phrase | a chip, two wordings, silent |
| 5 | Machine stage climbs | 9, at the base | the ring, a camera push, a phrase, one line | silent, no line, no camera |
| 6 | Voidkin's signature | 7 | hold 0.13 s, trauma 0.8, numbers step aside | the best-served moment we have |
| 7 | Upgrade succeeds | 6 | three notes up, the ring in good | silent |
| 8 | Level-up | 5 | the plate, the column, three notes | silent |

### 5e. Fifteen inconsistencies to fix

Costs are the builder's hours unless named, as seeds.

| # | Where | Wrong | Fix | Cost |
|---|---|---|---|---|
| 1 | `Main/FighterController/init.luau:452-460` | the keeper falls to a Shade's cue | its own cue, a rung 9 row in `Config.Combat.Hitstop.Rungs`, a music gap | 1 h, 1 cue |
| 2 | `UI/LevelNotice.luau`, `Config.Effects.LevelUp` | level-up is silent | the "Upgrade or level" phrase through `Cues` | 0.5 h |
| 3 | `Config.Effects.LeadLeaves`, `Config.Combat.Shake.Hurt` | the lead's hurt and fall are silent | a struck thud at the hurt jolt; a falling phrase at the fall | 1 h, 2 cues |
| 4 | `FighterController/Effects.luau:2257`, `HudController.luau:939` | every drop is Ready gold | colour, pips and note from the Rarity table | 2 h, then Scintilla's finish |
| 5 | `Config.Chests.Drop`, `Config.Drops`, `StageScreen.luau:751-760` | chests, stones, emblems drop unseen; stones and emblems reach no card | a band 2 chip in the fight; rows in `gave` | 3 h |
| 6 | `UI/TodayList.luau`, `HudController` `notice()` | a goal completes unseen | band 3 through the Conductor | 1.5 h |
| 7 | `Rules.Hud.ShardHint`, `HudController.luau:1338` | shard ready and battery full are unseen away from the base | a Ready dot on the dock's Base tile; one line per event, never repeated | 2 h |
| 8 | `UI/TowerScreen.luau:212` | Credits in gold | read `UIKit.Systems.Credits.Colour` | 10 min |
| 9 | `StageScreen.luau:866`, `TowerScreen.luau:206` | two words for a record | "New record", one chip | 20 min |
| 10 | `BaseController.luau:173`, `ShopController.luau:92`, `Reinforce.luau:324`, `ShopScreen.luau:206` and the rest | three tones, twenty wordings, a raw code | one `Refuse(reason, amount)` and one reason table | 3 h |
| 11 | `Bag.luau:106`, `ShopScreen.luau:72`, `:245`; Collect, claim, Open | two names for the bag; three verbs for taking | one name; the verbs of 5b | 0.5 h |
| 12 | `UI/Layers.luau`, `Config.Reveal.DisplayOrder`, `Config.Hud.Note` | a toast can cover a reveal; plate and note share a place with no rule | rule 7; the left lane | inside the Conductor |
| 13 | `UI/Readout.luau` | the recurring Ready is the HUD's loudest, in white | one swell, one pulse after 3 s untapped, then steady; the glyph, not the word | 0.5 h |
| 14 | `FighterController/`, `UI/Reveal/` | Reduced Motion ignored | one util read by both; rule 11 | 2 h |
| 15 | `Config.Hud.Card.Trim`, `Config.Hud.Bag.Rarity`, `Config.Hud.Breaker.Tier`, `Config.Reveal` | rarity typed four times, shown five ways | one Rarity table: colour, pips, frame, note, word | 3 h |

## 6. Does it speak the game's language? Ten questions for any new piece

1. Which band is this event, and which channel does that band add?
2. Does it use only the channels its band allows, and no channel of a higher band?
3. Is its meaning on the sheet, and does it wear that colour, shape, sound and word?
4. Is there a second sign besides colour (pips, icon, word)?
5. With sound off, is it still understood? With eyes on the fight, is it still heard?
6. Does it go through the Conductor, or does it draw itself?
7. What happens when it fires three times in a second: does it merge?
8. In a fight, does it put a sentence on screen? If so, why can't it wait?
9. Is it on the results card or a counter afterwards, so nothing is lost if it was missed?
10. Does a bigger event of the same kind feel bigger, on every channel, than this one?

## Top 5 to act on

1. **Build the Conductor:** one door, two lanes, the pure ordering rule, fight gating with `Theme.Time.Fight`, the results ledger; route Toast, the level plate and the note through it. **Faber**, about 1.5 days. Tier 2 (research's verdict on the lanes); no director's yes for the plumbing.
2. **Give the silent big moments a voice:** the keeper's fall, level-up, lead hurt and down, the drop's rarity note, goal done, upgrade result, machine stage, record. **Sonus** makes or shortlists about eight cues from the UI family; **Faber** wires, 3 h. The director's ear picks each cue (the standing rule).
3. **Adopt the semantic sheet and one Rarity table** (colour, pips, frame, note, word), and paint the drop with it. **Quaestor** writes the sheet into `docs/ui.md`; **Faber** 5 h; **Modulo** draws the pip and the Ready dot. Director's yes where a colour they picked changes (the same ask as `ui-colour-review.md`).
4. **One refusal:** a single helper, one reason table, the "{What's missing}: {how much}" pattern, grey with a shake, no raw codes. **Faber** 3 h, **Quaestor** the words. No director's yes.
5. **Fill the holes:** chest, stone and emblem drops; goal done; shard ready and battery full away from the base; Reduced Motion in the fight and the reveal. **Faber**, about 1 day, after item 1. Tier 2; the Base tile's dot is a new HUD sign, so it goes on the Now board for the director.
