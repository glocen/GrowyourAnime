# AR40: three colour directions for the world by day, as values

From `tools/colour/ar40_directions.py`; the values are in `directions.json`, beside this. `chips.png` is flat colour, top to bottom Today, A, B, C: a machine on the yard with the HUD's card as it is, then the swatches (body, frame, fitting, steel, trim, the wall, the stones, the sun, the fill). It's no render. The renders are `tools/colour/ar40_see.py`'s.

- **Today:** void stone in dark violet on navy frames, violet shards on the horizon, lilac stones, a lilac fill
- **A, porcelain and indigo:** the machines in warm white stone on indigo frames with gold fittings, under a warm white sun. The most blue-violet kept: every frame is the void's colour, at a mid value, never black; the wall is steel blue.
- **B, sky steel:** the machines in light blue steel with white frames, blue-violet only in their trim, their cores and the far shards, under a clear blue fill and a warm white sun.
- **C, sandstone and teal:** the machines in warm pale stone on teal bronze, with violet trim and a violet core against the sand, under a gold day. The warmest, and the violet the most set off.

| | body L* | frame L* | bodies' range | blue-violet | black |
|---|---|---|---|---|---|
| Today | 29 to 7 | 38 to 18 | 83 | 6 of 10: the body's head, the far shards, the Tower, the wall, the wall's foot, the stones | 4 of 10: the body's head, the body's foot, the trim, the wall's foot |
| A, porcelain and indigo | 95 to 75 | 47 to 23 | 72 | 4 of 10: the frame, the trim, the far shards, the Tower | 0 of 10: none |
| B, sky steel | 85 to 61 | 96 to 75 | 46 | 3 of 10: the trim, the far shards, the Tower | 0 of 10: none |
| C, sandstone and teal | 89 to 63 | 62 to 36 | 60 | 3 of 10: the trim, the far shards, the Tower | 0 of 10: none |

Counted over ten of the world's surfaces. Blue-violet: a hue from 225 to 310 degrees with colour in it. Black: under L* 30. The void's own light is violet in every row and isn't counted. Today's stones are read by eye off one capture, an estimate.

## The system panel

One palette for the slab the Breaker's and the Power panels wear, with the base screen's chips and side panels, the Forge's, the Void Shop's screen and the shared confirm, toast and reward where they wear it. The character screen, the Voidkin grid, the reveal and the HUD keep today's. The keys are Config.UIKit's (Graphite's), plus the theme's colours the two screens draw over the slab. `panels.png` is flat colour, left to right Today, A, B, C: the slab over that direction's day, with a title, a row with a bar, a ready chamber, an empty one, a button at rest and one chosen. It's no capture.

- **A:** porcelain in an indigo frame, indigo ink, gold where it's ready, blue-violet where it asks or is chosen.
- **B:** blue steel a clear step under white, in a navy frame with a white rim and white rows, navy ink, the same gold, blue-violet where it asks.
- **C:** teal bronze, a mid slab neither black nor pale, in a sand edge with cream words and pale violet where it asks.

| key | Today | A | B | C |
|---|---|---|---|---|
| Panel | #20242C to #13151A | #F7F2E8 to #E7E0D2 | #C9D8EC to #AFC2DC | #34606C to #2A4E5A |
| Alpha | 0.92 | 0.96 | 0.96 | 0.95 |
| Edge | #434A57 | #2B3472 | #22346A | #E2CFA4 |
| Border |  | 1.6 | 1.6 | 1.3 |
| Rim |  | 2 | 2 |  |
| Seat |  | 1.6 | 1.6 |  |
| Facet | #8A93A6 | #FFFFFF | #FFFFFF | #A9DCD4 |
| Glint | #C9D2E4 | #FFFFFF | #FFFFFF | #F2FFF9 |
| Text | #F3EFE6 | #1B1E3A | #14223F | #FFF6E2 |
| Soft | #A6ADBA | #4A4F70 | #3A4868 | #D9E8E2 |
| Faint | #6E7482 | #74788F | #566480 | #A9C0BC |
| Channel | #06070A | #232A52 | #172648 | #0E1D23 |
| Well | #0B0C10 | #D9D1C0 | #9FB4D0 | #21414A |
| Button | #323845 to #22262F | #FFFFFF to #EEE8DA | #FFFFFF to #E6EEF8 | #447480 to #366270 |
| Pressed | #1A1D24 to #20242C | #D8D0BE to #E4DDCE | #A9BCD6 to #BACBE2 | #2A4E5A to #34606C |
| Ground | #2B2E36 | #CFC8B8 | #A4B6D0 | #3E6872 |
| Accent | #FFF4D6 | #6A4DF0 | #5B43E8 | #CDBBFF |
| Core | 0.5 | 0.9 | 0.9 | 0.5 |
| Selected |  | #2B3472 to #1D2452 | #22346A to #162550 | #F0E2C4 to #DCCBA6 |
| SelectedText |  | #F7F2E8 | #F2F6FB | #1E3238 |
| Row | #2E323B | #FFFDF8 | #EEF3FA | #3C6A76 |
| Backing | #121419 | #D9D3C6 | #A9BAD2 | #2E525C |
| Ready | #F6DE80 | #E3A52A | #F0B429 | #FFD880 |
| ReadyWords | #191B21 | #1B1E3A | #14223F | #1E3238 |
| Electricity | #FFE266 | #FFE266 | #FFE266 | #FFE266 |
| ElectricityWords | #FFE266 | #7A5800 | #5E4300 | #FFE98A |
| Over | #FF965C | #FF8A4A | #FF8A4A | #FF965C |
| OverWords | #FF965C | #A63A12 | #822A0A | #FFE2D0 |

| contrast, the least | Today | A | B | C |
|---|---|---|---|---|
| the panel's L*, top to foot | 14 to 7 | 96 to 89 | 86 to 78 | 38 to 31 |
| Text on the panel, a row, a button | 10.2 | 12.4 | 8.7 | 4.8 |
| Soft on the panel and a row | 5.7 | 6 | 5 | 4.7 |
| Faint on the panel | 3.3 | 3.3 | 3.3 | 3.6 |
| ElectricityWords on the panel and a row | 10 | 5 | 5.1 | 4.9 |
| OverWords, the same | 6 | 4.9 | 5.1 | 4.8 |
| ReadyWords on Ready | 12.9 | 7.5 | 8.5 | 9.8 |
| Ready against the panel | 11.6 | 1.7 | 1 | 5.1 |
| Electricity in its channel | 15.7 | 10.7 | 11.6 | 13.4 |
| the channel against the panel | 1.1 | 10.5 | 8.2 | 1.9 |
| the edge against the panel | 1.7 | 8.7 | 6.5 | 4.5 |
| the accent against the panel | 14.2 | 4.1 | 3.4 | 4 |
| a chosen button's words | 10.2 | 10.2 | 10.9 | 10.4 |
| the accent is blue-violet | no | yes | yes | yes |
| under L* 30 | Panel, Row, Button, Ground, Backing | none | none | none |

Words need 4.5 to 1, a mark or an edge 3. Today's panel is Graphite with the theme's colours, as the code has them.
