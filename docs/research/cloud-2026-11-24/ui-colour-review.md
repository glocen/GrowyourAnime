# UI colour review, 2026-11-24

An independent reviewer's pass on the colours in code at the cloud checkout of 2026-11-24, held against `docs/north-star.md`, the directive's section 13 and the frosted-glass reference the director liked. This is a proposal only: no code or doc was changed. Labels: **MEASURED** is a WCAG 2.x contrast ratio or a CIE76 ΔE after a Machado-2009 colour-vision simulation (severity 1.0), computed from the hex values in code. **OBSERVED** is what the code or docs say. **OPINION** is taste.

## Verdict

1. No single hue is the problem. The problem is how many there are. The game has 6 live panel grounds, 6 coloured pill bodies and about 9 golds, so there's no one identity, and gold stops meaning anything.
2. The ink fails in two places. Every palette's third ink step ("Faint") is under 4.5:1. The Breaker's teal ground can't carry the rarity words the director asked for: Epic is 3.3:1, Rare 3.2:1 and Mythical 3.0:1.
3. Rare and Epic collapse for red-green colour-blind players (ΔE 6 to 7). The reference's restraint (one navy glass, one gold for the main action) fixes all three. It costs a re-cut of the baked UI images, and it needs the director's word.

## The palette in use

Live means it's read by `src/client` (OBSERVED, by grep). `UIKit.luau` also defines Pearl, Dynamo and Void, but nothing reads Pearl or Dynamo, and Void is read in one place.

| Role | Name / token | Hex | Where |
|---|---|---|---|
| Ground: HUD cards, pills | Graphite Panel | #20242C → #13151A | `Config/UIKit.luau` Palettes.Graphite; dup. by hand in `client/UI/Theme.luau` (#20232A, #121419) |
| Ground: Voidkin screen, bag | Seam / SeamDeep Panel | #1A1430 → #0C0A16 | UIKit Palettes.Seam, SeamDeep |
| Ground: Equipment, Settings, Stages, dock glass | SeamGlass Panel, Card | #2F2758 → #16122C; card #4C3E92 | UIKit Palettes.SeamGlass; Equipment Backing #1F1942 (`Config/Hud.luau`) |
| Ground: Breaker, Power windows | System (teal + sand edge) | #34606C → #2A4E5A, edge #E2CFA4 | UIKit Palettes.System |
| Ground: reveal | Eclipse | #1C1F2A → #090A10 | UIKit Palettes.Eclipse |
| Ground: Arc / run card | festival dusk | #1E0F16 → #4A2324, #5E2A3A | Hud.luau stages |
| Pill bodies (Conduit B) | Systems.*.Panel | Power #4D3711, Credits #0E4541, Voidkin #35286B, Regalia #1D2A6E, Map #5A1D3F | UIKit Systems |
| Ink | Text / Soft / Faint | #F3EFE6 / #A6ADBA / #6E7482 (Graphite); #F1ECFF / #B9B0D6 / #6F6790 (Seam) | each palette |
| Main action | SeamLit plate; System Primary sand; Theme.Colour.Primary blue | #FFFFFF→#EDE4FF; #F0E2C4; #60AAEC (no user, dead) | UIKit, Theme |
| Power | Charge / Systems.Power | #FFE266 | UIKit |
| Credits | Systems.Credits; **Theme.Colour.Credits** | #40DCC6; **#EEC65C (gold)** | UIKit; `TowerScreen.luau:212` uses the gold |
| Golds besides Power | Legendary, Critical, Ready, Claim, Level, Home "+7", skull yellow, CR tab | #FFD777, #FFCF4D, #FFD880, #F6DE80, #F2CB62, #FFD36B … | Hud.luau, UIKit |
| Rarity (words) | Common … Mythical | #9AA0AC, #7CF0A0, #6FB6FF, #D29CFF, #FFD777, #FF8794 | Hud.luau Voidkin.Rarity; again in Card.Trim, Voidkin.Rim, `Config/Reveal.luau` |
| Types (gems) | Red, Orange, Blue, Purple, Green | #EA4B4F, #F4902A, #3F9DF2, #A470F2, #42CC7E | Hud.luau Card.Types |
| Good / bad | UIKit.Good / Bad | #7CF0A4 / #FF7A66 | UIKit |
| Damage numbers | Plain, Critical, Heal, Received, Miss; outline | #F8F1DF, #FFCF4D (gradient), #6FE695, #E27A6A, #B9BEC9; outline #15120E | UIKit.Numbers, Hud.luau |

## Contrast findings (MEASURED)

The thresholds are 4.5:1 for body text (the screens' text is 14 to 20 px, so almost all of it is "body") and 3:1 for icons, large text and bars.

**What passes, with room:** the Text and Soft inks on every ground (Graphite 13.6 and 6.9, Seam 15.3 and 8.6, System 6.4 and 5.5, Pearl 16.1 and 5.5). Every rarity word passes on Seam (Common 6.7 up to Legendary 12.8), and so do the pill text, the level gold (10.0), Equip's ink on its plate and the sand-plate words (10.4). Damage numbers pass against their own outline: Plain 16.6, Received 6.4, Heal 11.9, Miss 10.0.

**What fails:**

| Pair | Ratio | Why it matters |
|---|---|---|
| Faint on Graphite #20242C / Seam #1A1430 / SeamGlass #2F2758 | 3.3 / 3.4 / 3.4 | Faint is the ink for off chips, empty states, claimed goals and disabled words. Rule 4 says a disabled button says *why*, and that reason has to be readable. |
| Faint on SeamGlass card #4C3E92 | **2.2** | the Home-opened screens' cards |
| Faint on System #34606C / its row #3C6A76 | 3.6 / 3.1 | the Breaker and Power windows |
| Pearl Faint on its foot | 2.5 | the page-style screens (none live yet) |
| Rare / Epic / Mythical / Common head on System teal | **3.2 / 3.3 / 3.0 / 4.4** | the Breaker's drop rates, where the director asked "the epic chance text should be purple" (2026-11-15). The teal ground makes that word fail. |
| Common trim #666C78 on Graphite | 2.95 | the lead card's rim on a Common lead |
| Goal "claimed" #7E879A, thumb #55607A on glass | 3.75 / 2.15 | Today's list |
| Any damage number **without** its outline over a pale sky or lit grass | 1.0 to 1.2 | the outline does all the work, so it must never be turned off for a style (a Reduced Motion path, a new element number) |

The hairline edges (Graphite 1.7, Seam 1.5) sit under 3:1. That's fine: they're decoration. A panel is told from the world by its whole body, not its edge (OPINION). Don't "fix" them brighter.

**Colour vision (MEASURED, ΔE76 after simulation; under about 10 reads as the same colour at text size):**

- Rarity: **Rare and Epic are 40 apart in normal vision but 6 under protanopia and 7 under deuteranopia.** Uncommon and Mythical are 13 under deuteranopia. Uncommon and Legendary are 17 under protanopia. Shapes carry the frame (`docs/design.md`, "A rarity is a shape and a light"). They don't carry a coloured word, a list heading or a bag cell's 3-point foot bar.
- Types: Blue and Purple are 5 under deuteranopia. The gems differ only by colour (`GemBlue`, `GemPurple`), so the type is unreadable there (OBSERVED in the image names; check the art).
- Rarity against type: Uncommon against Green is 14, Rare against Blue 12, Epic against the Void element 12, even in normal vision. A hue rarity collides with the type gems, as `docs/design.md` warned before the 2026-11-13 word.
- Gold against gold: Legendary vs Ready is **4**, Legendary vs Level 6, Critical vs Power 11, Legendary vs Power 13. A "ready to claim" glow and a Legendary item are the same colour.

## What's wrong, and why it matters

1. **No single identity (OBSERVED and OPINION).** The directive, section 13, says to "establish a coherent visual identity before producing many independent panels". In the first session a player crosses 6 grounds:
   - grey-blue Graphite in the HUD;
   - violet-black Seam in the Voidkin screen;
   - lifted violet SeamGlass in Equipment, Settings and Stages;
   - teal and sandstone System in the Breaker and Power windows;
   - Eclipse in the reveal;
   - wine and rosewood dusk in the Arc.

   That's on top of 5 coloured pill bodies. Each was a reasonable pick for its own screen, judged alone. Together they read as several games, and "premium" (north star, pillar 4) is mostly restraint. The decision log shows the director feeling this without naming it: "more palette, vivid" on 11-15, "way too much purple/black and somber" on 11-17, no to the green makeover on 11-19, "a bit too shiny" on 11-23, and now the frosted reference. Each round added a colour to fix the last, and none took one away.
2. **Gold has no meaning (MEASURED and OBSERVED).** About 9 golds and yellows (Power, Legendary, Critical, Ready, Claim, Level, CR's tab, Equipment's level, the yellow skull) sit within ΔE 4 to 21 of each other. The reference keeps one gold, on the one button to press, so the eye goes there. Here it can't.
3. **Mid-value saturated grounds (MEASURED).** SeamGlass's card (#4C3E92) and System's teal (#34606C, about 9% luminance) are light enough that coloured words and a third grey step can't clear 4.5:1. The darker Seam and Graphite carry every rarity word. The reference's navy is dark for a reason.
4. **Rare and Epic are the same colour for about 1 in 12 boys (MEASURED, with the usual red-green prevalence).** Epic is the rarity the Breaker's odds headline.
5. **Duplication invites drift (OBSERVED).**
   - The rarity colours are typed four times (`Hud.luau` Card.Trim, Voidkin.Rarity, Voidkin.Rim; `Reveal.luau`).
   - Graphite is retyped by hand in `Theme.luau`.
   - `Theme.Colour.Primary` (blue) has no reader.
   - `Theme.Colour.Credits` is gold, against ui.md's "Credits in their teal", and the Tower results use it.
6. **No blur (OBSERVED).** Nothing in `src` makes a BlurEffect or DepthOfField. Home dims the world with #05090B at 0.6 opacity. The reference's "world blurred behind" is a Lighting `BlurEffect` turned on while a full screen is open, and it's what makes a dark glass feel expensive rather than heavy (OPINION).
7. **What's right (OPINION):** the ivory ink, the damage numbers' outline discipline, the lead card's red health against blue experience, Eclipse's neutral reveal room ("a rarity's light is the only colour in it" is exactly the reference's idea), and Seam's blue-violet dark, which the director named good on 11-17.

## The proposal: "Night glass", one ground and one gold

The base is the inventory's blue-violet dark, the screen the director kept (2026-11-17), pushed toward the reference's navy. Every full screen takes it over a blurred world. MEASURED ratios are on glass / raised.

| Token | Hex | Contrast | Replaces |
|---|---|---|---|
| ground.glass (screen body, ≥ 90% opaque) | #151A30 | — | Graphite, Seam, SeamGlass, System panels |
| ground.raised (row, card, button at rest) | #1E2440 | — | Button, Row, SeamGlass Card |
| ground.well (bar channel, slot) | #0B0E1C | — | Channel, Well |
| line.hairline | white at 16% (#3A3F51) | 1.6, decorative | each Edge |
| ink.title (titles; a serif face is worth a sheet, AR12's call) | #F4F1EA | 15.2 / 13.5 | Text |
| ink.body | #C9CFDC | 11.0 / 9.7 | Soft |
| ink.label (small grey caps, reasons, claimed) | #959EB1 | 6.3 / 5.7 | Faint as text |
| ink.off (icons only, never words) | #6B7386 | 3.6 / 3.2 | Faint as icon |
| accent.action (the one primary plate; Ready and Claim fold in) | #E9B65C, ink #1A1408 | 9.9 on plate; plate 9.3 on glass | SeamLit plate, System sand, Ready, Claim |
| Power (icon, number, thread; never a body) | #FFE266 | 13.4 | unchanged hue; pill body goes neutral |
| Credits (the same) | #40DCC6 | 10.0 | Theme's gold Credits goes |
| good / bad | #6FE3A0 / #FF7F70 | 10.8 / 7.0 | close to today |
| Rarity: Common, Uncommon, Rare, Epic, Legendary, Mythical | #AEB4C0, #7AF0A6, **#4A97F7**, **#E2A6FF**, **#FFC24A**, #FF8794 | 8.3, 12.1, 5.8, 9.1, 10.7, 7.5 (raised: Rare 5.1) | keeps the director's hues and moves the lightness |

- **Rare and Epic** become 31 apart under deuteranopia and 17 under protanopia (from 7 and 6), by putting a darker blue against a lighter lilac.
- **Legendary** moves off the action gold (ΔE 15) and off Power's lemon (17).
- **Mythical** stays at #FF8794, under the content check's limit (`Reveal.luau`).
- **Uncommon and Mythical** stay 12 to 13 under deuteranopia. Their crowns and frames part them, as today.
- **Over a bright world:** at 10% see-through over a pale sky the label holds 5.0. At 20% it drops to 3.4. So the frost comes from the BlurEffect plus the dim, never from a more transparent panel.

**What stays:** Eclipse for the reveal; the dusk for the Arc's own picture, as an image, not a ground; the HUD's damage numbers, health red, experience blue and Critical's measured gradient; CR's gold tab (the director's word of 2026-11-19), which becomes the only other gold on the HUD.

**What changes, and where:**

- `tools/ui/kit_config.py` and Modulo's `kit.json`: one Night palette. UIKit is generated, so never edit it by hand.
- `src/client/UI/Theme.luau`: tokens read from UIKit. Drop the dead Primary. Credits becomes teal.
- One `Rarity` table in `Config/UIKit`, read by Hud's Card.Trim, Voidkin.Rarity and Rim, and by Reveal.
- `Kit/Screen` or `Kit/Glass`: a Lighting BlurEffect while a full screen is open (size about 12 to 20, tuned live).
- `Kit/Pill`: the system colour on the icon, thread and number, over the glass.

**Cost:**

- Code: about half a day for the builder, plus the self-tests whose colours are asserted (`SelfTestController/*Cases`).
- Art: the real cost. The Home cards, the SeamGlass and dock glass, the stage tiles and the Equipment cut carry their colours baked in pixels. Each is a Blender re-cut and a group upload, Modulo's days, one screen at a time.
- Approvals:
  - The neutral pill bodies reverse the director's "B, Conduit" of 2026-11-15, so that's tier 3.
  - Retiring System's teal reverses research's AR40 C pick of 2026-11-18, which is tier 2, but it's on the director's own screens.
  - The rarity lightness is tier 2: research and Modulo, who has the kit's creative freedom (2026-11-16).
- A cheaper first step, with no reversal: raise each Faint to pass, and change only the rarity lightness:
  - Faint: Graphite #8A91A0 (4.9), Seam #8C84AE (5.1), SeamGlass #9A92C0 (4.7), Pearl #5F6471 (4.7).
  - SeamGlass's card and System's row have no room for a third ink step at all (best 4.7 and 4.2). That shows the grounds themselves are the cause.

## Verify in Studio, on a phone in landscape

1. Capture the Breaker's drop rates on the teal ground, then the same list on #151A30. Read the Epic and Rare rows at arm's length.
2. Run the same captures through a deuteranopia filter (the AR12 sheet method). Rare and Epic cells and words should part without their frames.
3. Open Home, Voidkin, Equipment, Breaker and the reveal in one sitting, then count the grounds you saw. Judge in motion, not from stills.
4. With the BlurEffect on, check the frame rate on the smallest phone (UI rule 5: 60 fps). If Blur costs too much there, fall back to the dim alone.
5. Check the label grey (#959EB1) at 14 px over the brightest dusk and noon spots, with the panel at its real transparency.
6. Confirm that every damage number, element numbers included, keeps its outline in every mode.
7. Put the action gold, Legendary and Power side by side on one screen (the item card with Equip, a Legendary item, the kW pill). Each should read as a different thing.
