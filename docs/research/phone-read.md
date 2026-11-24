# Why theirs read on a phone and ours don't: the Voidkin and the screens

Modulo, 2026-11-24, from 21:26, on the director's word of 21:25 ("redesign the voidkin + ui it unreadable for players and ugly we need to study"; AR62). It feeds AR62's targets. The labels:
- **OBSERVED:** seen in an image.
- **MEASURED:** counted or measured on a capture.
- **DESIGN:** ours, for the targets.

The images stay internal (`build/reference/`, `build/captures/`, `build/scratch/modulo/study/`).

**The question:** at a phone's size, what makes a shipped anime game's fighter and screen read at a glance, and what is different in ours?

## The fighters

- **Size isn't the gap** (MEASURED). In our Tower fight at the default zoom (`build/scratch/faber/ar56/fight_zoomin_16.jpg`), Rook stands at 10% of the screen's height and Pip at 14%. An Anime Vanguards unit in its own fight (`animations/Genitsu_Attack_0.gif`, frame 0) stands at 15%. On the street our lead beside the avatar is about 27% (`ar62/before/hud_street_day.png`).
- **Theirs read by one colour and its value** (OBSERVED: AV's fight frames, its unit renders, Sailor Piece's clip). Each unit reads as a single saturated hue over most of its body, with a lit ring under it, on a dark, cool ground. Their hair is a large bright mass in a second strong hue (white, red, yellow), the second read after the body.
- **Ours read as mixed values on a mid ground** (OBSERVED):
  - Rook's back is a white shirt, black trousers and hair, and a small red scarf. On the Tower's pale floor the shirt vanishes and only the black parts read. On Lantern Row's grey-violet stone the whites read, but no one hue says "Rook".
  - Pip is the exception. His blue-violet robe and hat are one saturated mass, and he reads first in the same frame.
- **What players see is still the old make** (OBSERVED). The game shows the blocky, built-garment Rook (the street, the Voidkin screen), a cube-head Rook in the lead card and Lyric in the reveal. Nothing of AR59's or AR60's new make is in the game yet. So the director judged readability on the make that was already rejected on 11-23.
- **The make itself isn't the cause** (OBSERVED). AV's units are the same plain R6 with painted clothes and a drawn face, and they read. The study gives no reason to change the make, so there is no make option to bring.

## The screens

| What | Ours (`build/captures/ar62/before/`, 852×480) | A shipped game (Dragon Hunter's Character; Sailor Piece's Inventory) |
|---|---|---|
| What carries the read (OBSERVED) | words: names, "Reinforce +0" five times, "Empty", "Locked", "None this stock. When one is in, the Shop's crown is lit." | art: each slot is its item's picture, filling about 80% of the slot, with only a number badge on it |
| Text items on one screen (MEASURED, counted) | Voidkin 20, Equipment 22, Void Breaker 17, Void Shop 14 | Dragon Hunter's Character, about 9 words and the slots' numbers |
| Rarity at a glance (OBSERVED) | a word ("Common", "Rare") or nothing; every equipment row looks the same | the slot's fill colour: orange, purple, blue, green |
| The fighter on its own screen (MEASURED) | Rook about 23% of the height in a small well, his CR number nearly as tall as his head | the character 74% of the height (`voidkin-screen.md`) |
| Item art (OBSERVED) | small dark-grey metal on dark plates, so the picture and its ground share a value | saturated pictures on a rarity fill, each a different hue |
| Material families (OBSERVED; digest of `ui-colour-review.md`) | indigo cards, teal and yellow pills, dark slate tiles, gold-rimmed angled cards, lavender buttons, a teal-grey return card: 6 panel grounds, 6 pill bodies, about 9 golds | one dark panel with one thin gold rim, everywhere |
| Portraits (OBSERVED) | the old blocky make in the lead card, the Home menu's Voidkin tile and the roster strip | painted portraits in the game's own render |
| Empty space (OBSERVED) | the Void Shop's Featured panel is a sentence in a big empty box; Settings is three sliders in a full screen; the run's card is small in a big frame | panels sized to what they hold |

The director's accepted examples hold with this: the dark glass, one strong accent, vivid colour only where it means something, rich art in plain chrome (`examples.md`). Our screens kept the plain chrome but lost the rich art, and words took its place.

## The principles for AR62's targets (DESIGN)

**The fighters:**
1. One signature hue over at least 40% of the back view, in a value apart from both grounds: the street's mid stone and the Tower's pale floor.
2. The hair is the second read: one big mass in a strong, light hue (AR64), never thin leaves.
3. Hard two-tone shading with dark ink at the clothes' seams, as the make already intends.
4. The new make in every place a Voidkin shows (world, lead card, menu tile, roster, reveal) at once. A screen with the old portrait undoes the redesign. That's Faber's install, when the director accepts.

**The screens:**
1. Art first: a slot shows its picture at about 75% of the slot, on a fill in its rarity's colour. A name shows only on the piece selected.
2. One material family: one dark panel, one rim, one accent kept for what can be pressed or bought. The currencies are an icon and a number on that same panel.
3. Three type sizes, and a sentence only where a choice needs one.
4. The Voidkin screen gives the fighter at least 60% of the height.
5. Pictures bright and saturated on a dark ground, never dark metal on dark.

**A gap:** none of us has a capture of AV's own menus and HUD on a phone. The screens' comparison stands on Dragon Hunter and Sailor Piece. A few phone screenshots of AV's units screen and HUD would close it.

## Images looked at

- **Ours:** `build/captures/ar62/before/*.png` (12 of 13; `run_card_fall` not opened); `build/scratch/faber/ar56/fight_zoomin_16.jpg`; `build/scratch/faber/ar62_probe.png`.
- **Anime Vanguards:** `build/reference/anime-vanguards/compare_bodies.png`; `animations/Cu_Chulainn_(Child_of_Light)_Attack_0_sheet.png`; `animations/Genitsu_Attack_0.gif`, frame 0.
- **Sailor Piece:** `build/reference/chest-opening/sailor-piece_chest-opening.mp4`, a contact sheet one frame every 3 s, and the frame at 0:30.
- **Dragon Hunter:** `build/reference/dragon-hunter/2026-11-12_character-slots.png` and `2026-11-12_arena-normal-damage.png`, downscaled to 1108 px.
- **What was already written:** `docs/research/cloud-2026-11-24/character-art-pipeline.md`, `ui-colour-review.md`, `directors-taste.md`, `devforum-ui.md`, `examples.md`, `voidkin-screen.md` (through a read-only digest).
