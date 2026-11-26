# The director's examples: looks judged, with the image they judged

Research (Quaestor), 2026-11-24, evening, from the cloud. This is the calibration set for verdicts in pairs (`quality-and-speed.md`, change 3).

**How to use it:**
- A review sets the build beside the nearest accepted and nearest rejected example of its area, and asks which it's closer to, and why.
- `ga-fresh-eyes` takes two of these paths.
- The director's words are OBSERVED, from `docs/decisions.md` (L = its line). "Fit" is how sure we are that the image is what the director saw. It was checked against commit times, which are local, UTC+1.

**To open one at its version:** run `git show <hash>:build/handoff/<path> > build/scratch/<you>/<name>.png`. On the PC the clone is whole. The cloud's clone is shallow, so deepen it first.

**What the set is made of:**
- Of 26 verdicts found, 21 have their image in git as a Blender sheet, render or mock. One has an in-game capture (L210). Four were judged in the game, with no capture in git.
- The base's best praise ("perfect", in the game) has no capture in git.
- So the set is weakest exactly where the director judges best: in the game.

## Characters

| Verdict | The director's words | What | Image @ commit | Fit |
|---|---|---|---|---|
| **Accepted** | "def A, but looks at vanguard units then compare"; "yess see the difference" (11-15, 19:31, L277) | AR11, Watt's take A, the quiet wall | `Watt/watt_takes.png` @40d8841 | high |
| **Accepted, with limits** | "it fine if the model has some attachment or ovexageration you seems to get it now" (11-24, about 01:47, L29) | AR59, Rook's pick (take A, five fixes): a direction, not yet the install | `Rook/takes/rook_pick.png` @7be72f2 | high |
| Rejected | "DONT MAKE THOSE MODEL WITH THOSE STYLE", "LOOK AT ANIME VANGUARD ANIME ADVENTURE THEN REDO" (11-23, 23:45 to 23:52, L30) | AR59, Rook's three takes in the first make | `Rook/takes/rook_takes.png` @4487a49 | high |
| Rejected | "the hair are messy to many artifact and lack" (11-24, about 11:20, L20) | AR60, Kirra's finish in the new make | `Kirra/make/kirra_make_sheet.png` @3b328a9 | high |
| Rejected | "that watt model is sooooo corny it doesnt look like anime" (11-15, about 18:45, L281) | AR11, Watt's first model, the mechanic | `Watt/watt_model_sheet.png` @1c9dda6 | medium-high |

## UI

| Verdict | The director's words | What | Image @ commit | Fit |
|---|---|---|---|---|
| **Accepted** | "ok we keep it good job" (11-15, 02:07 to 02:26, L191) | AR12, the galaxy Breaker screen, its third mock | `UI/hud/colour/vivid3_breaker.png` @0540456 | high |
| **Accepted, crown cut** | "the crown for legendary gears is uselless ... the rest is very good good job" (11-15, 00:54 to 01:38, L189) | TR17 and AR12, the redrawn Voidkin screen | `UI/hud/colour/vivid_voidkin.png` @a094111 | high |
| **Accepted** | "let try F i dont want segments tho just a bar" (11-15, after 03:32, L294) | AR12, the lead's card, round two | `UI/hud/lead_card_takes/lead_card_round2.png` @0159956 | high |
| **Accepted** | "the B) UI on the left are very good" (11-17, 14:03, L214) | AR29, the Voidkin screen's rail, the seam | `UI/voidkin/chrome/voidkin_chrome_close.png` @32b5980 | high |
| **Picked** | "B, Conduit" (11-14 to 11-15, L183) | AR12, the HUD's colour, B of three | `UI/hud/colour/hud_colour_B.png` @77c591e | high |
| **Accepted** | "i love the graphite UI wayyy more" (11-12, L134) | AR3, the UI direction sheet | `UI/ui_sheet.png` @82d5d69 | medium-high |
| Rejected, all three | "it js need a different type of color different width (smaller imo) and much better composition" (11-15, 03:21 to 03:32, L200) | AR12, the lead's card, takes A to C | `UI/hud/lead_card_takes/lead_card_takes.png` @63a25ab | high |
| Rejected | "im not happy with the shoulder and helmet and boots and chest need to looks more detailed "epic"" (11-16, 21:57, L230) | AR22, the empty slots' marks | `UI/slots/slot_marks_grey.png` @94e92dc | high |
| Rejected | "dont make the whole game about lantern drum festival like those mask item" (11-23, 18:35, L36) | AR53, the Mask Ledger page | `UI/goals/goals_ledger.png` @f46f34d | high |
| Rejected | "those ui need a massive polished it looks childish and not good" (11-17, 13:16, L210) | the Voidkin screen's rail before AR29, **in the game** | `UI/voidkin/chrome/base_items.png` @32b5980 (Faber's phone capture, 22 minutes before the words) | medium |
| Rejected | "i do not look like this green ui makeover i liked the old one before" (11-19, 14:56, L50) | AR40's teal on Equipment | `UI/equipment/equipment_cut.png` @8130e92 | medium |
| Rejected | "that lantern drawing is so bad and the rest is just a pain in the eye" (11-24, 13:35, L18) | the Arc panel's Lantern Row tile, in the game | the drawing only: `UI/stages/images/StageLantern.png` @fa02fe7 | medium |
| Rejected | "why it show the eauipped voidkin why not js a beautifull art typesoul like or rellseas like" (11-26, by 20:28, to Modulo) | AR62's Home, the Voidkin card: the lead as a plain standing shot | `UI/style_frames/A_home_cut.png` @92b323c8, the likely image (Modulo to confirm) | medium |
| Rejected | "équipement is so ugly", then "Home's Equipment card" (11-26, by 20:28, to Modulo) | AR62's Home, the Equipment card: a gold sword with +7 on a brown ground | the same | medium |

The UI pair to start from: the accepted rail (AR29, B) beside the rejected rail in the game (L210). It's the same screen, before and after the director's word.

## The base and the world

| Verdict | The director's words | What | Image @ commit | Fit |
|---|---|---|---|---|
| **Accepted** | "you did a good job we still need to keep the anime yet mature theme this is great" (11-15, about 21:46, L266) | AR14, the base on its whole plot | `Base/base_1_across.png` @918d62a | medium |
| **Accepted** | "the night looks absolutely gorgeous" (L153), "The merge" (L154), 11-12 | AR5, Lantern Row's look | `LanternRow/lantern_row_look_round2.png` @d270d74 | medium-high |
| Rejected | "it need look like an base not lantern row ground" (11-15, 20:46, L270) | AR14, the base from Lantern Row's kit | `Base/base_1_home.png` @5e5c46e | high |
| Rejected | "the base feel empty now" (11-16, 00:16, L246) | AR16, the star layout | `Base/base_1_star.png` @a42e3e0 | high |
| Rejected | "a bit to much atmosphere imo like that mist is a bit to much" (11-16, L242) | AR5, the Day sky's first sheet | `LanternRow/sky/lantern_row_sky_day_sheet.png` @45455bc | high |

## Effects and animation: no example to calibrate on

| Verdict | The director's words | What | Image @ commit | Fit |
|---|---|---|---|---|
| Rejected | "those 2d flame effect is horrendous" (11-19, about 11:46, L55) | AR44, the critical's comet stroke | `UI/hud/crit_stroke_sheet.png` @c1cb711 | medium: "those" may mean the fighter's flames |
| Rejected | "i despise those 2d cartoonish fire vfx" (11-17, 13:59, L212) | Pip's Lantern Burst, on a fight still | the design only: `Pip/fx/pip_burst_finish.png` @256e3a6 | low-medium |
| Rejected | "this weird tic in their idle animation where they head tilt on the side" (11-17, L217) | the idles' head glance, in the game | pose sheets only, no clip | low |

- No effect or move has an accepted example in git. The only near-yes on an effect is "the vfx of the mage skill is kinda odd but we will keep it" (11-12, L303).
- So the first target the director picks under change 1, for an effect and for a move, becomes its accepted example.

## Keeping the set honest

- **Add every new verdict** on a look, with the image the director saw, committed at the time of the verdict. An in-game capture beats a sheet. Rows leave only on the director's word.
- **Read the words with their scope.** "Accepted, with limits" covers what the row names, nothing wider (`AGENTS.md`, "The director's words keep their scope").
- **The patterns the examples share** (OPINION, research's reading, to be tested in pairs and not used as a rule):
  - The accepted UI is dark, quiet and composed, with one strong accent: graphite, the seam, the galaxy palette rather than a drawn galaxy.
  - The rejected UI is busy or hand-drawn: the lantern drawing, the masks, the slot marks.
  - Characters: Watt's take A was confirmed beside Anime Vanguards' units ("yess see the difference"), and Rook's takes were rejected with "LOOK AT ANIME VANGUARD ANIME ADVENTURE THEN REDO". The genre's hits are the yardstick the director names.
