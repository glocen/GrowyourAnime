# Anime Crusaders X: how the UI surface reaches its polish (study)

For Quaestor, 2026-11-27, 00:16 by the PC's clock. It follows `docs/research/anime-crusaders-ui.md` and covers surface and finish only: principle, never their art.

**Labels:**
- **OBSERVED:** seen in the image.
- **SAMPLED:** pixel values read at native 2560 width.
- **ESTIMATED:** by eye.

Every px is at 2560 wide. `u06_crop` sits at (470, 258) in `u06_full`.

**The shared recipe, a ring stack:** concentric rings of one hue at different values, split by black hairlines, around a gradient fill on a near-black ground.

## By element type

**HUD buttons** (`hud_left`, `s004_full`)
- Layers, back to front (SAMPLED, Units tile, about 130 px):
  - a soft outer glow in the hue, about 10 px;
  - a 3-4 px outer stroke in a near-black tint of the hue (#251e0a);
  - a 6 px bright band, in a diagonal gradient: yellow at the top left to orange at the bottom right (#ffcd3a to #fda815);
  - a 2 px dark inner stroke;
  - an interior in a dark version of the hue (#31280b to #5f4b13), with an inner vignette over the 15-20 px next to the border, and a faint tone-on-tone pattern at 10% contrast or less (ESTIMATED).
- **Corners:** a radius of about 15 px, about 12% of the tile (ESTIMATED).
- **Icon:** illustrated, cel-shaded, with a specular highlight and a 3-4 px black ink outline. It takes the border's hue and fills about 70% of the tile (OBSERVED).
- **Label:** a rounded heavy display face, flat white, with a 3 px black stroke (SAMPLED). It sits astride the bottom border.
- **Badges:**
  - the keybind is a black disc of about 40 px, half over the top-left corner;
  - "new" is a red disc of about 28 px, glossy at the top left, with a 2-3 px dark outline and a stroked white "!", half over the top-right corner (`s004_full`, OBSERVED).
- **Gaps:** about 8 px between tiles (ESTIMATED).

**Currency and stat pills**
- **Lobby currencies have no plate** (`s004_full`): a glossy rendered icon, and a number in the currency's hue.
  - The number runs pale at the top to saturated at the bottom (#fff099 to #ffc54f, SAMPLED).
  - Its stroke is 4 px of a warm near-black (#120907), about 19% of the 21 px cap height (SAMPLED).
- **System pills:** a flat dark capsule with no stroke, and plain medium sans in white with no text stroke (OBSERVED). They're kept quiet on purpose.
- **Match chips** (`g05_full`, SAMPLED, about 60 px tall), back to front:
  - a 4 px dark outer line (#073352);
  - a 4 px lighter top rim (#144569 on a #0c2c42 fill);
  - a fill that darkens downward to #0b1218;
  - a 3 px neutral dark bottom edge.
  - The label word sits in a darker inset capsule, the icon is flat and single-hue, and the number is white bold.
- **Detail pills** (`i02_full`): a near-black fill and a 2 px grey rim, with the text in the rarity hue and no stroke.

**Panels and windows** (`u06_crop`, `i02`, `m02`)
- Layers, outside in (SAMPLED):
  - a **3 px bright frame line** whose hue drifts around the panel (#ff3400 on top, #fcac00 on the right, #fdde00 at the bottom);
  - 4 px of black;
  - a 5 px ring of that hue at about 18% value;
  - 5-8 px of black;
  - a near-black interior (#09090b).
- **Sub-panels:** #212125, with a 2 px grey rim.
- A soft outer glow in the panel's hue, and the world blurred behind (OBSERVED).
- **The weight is black matte.** The coloured line is only 3 px.
- **Title ribbon:**
  - an orange-to-yellow gradient;
  - a halftone texture at a 1-2% channel swing (SAMPLED);
  - a darker copy stacked about 6-8 px below (ESTIMATED).
- **Outer corners:** about 24-30 px (ESTIMATED).

**Tabs** (`u06_crop`, `i02_full`)
- The button's ring stack, smaller.
- **Selected:** the panel's hue. **Unselected:** neutral grey with a lighter grey rim.
- **Text:** heavy italic white, with a 2-3 px black stroke. Counts are stroked superscripts.
- **Gap:** about 8 px on a 55 px tab (ESTIMATED).

**Close button**
- A disc in the panel's hue, about 110 px, half outside the corner.
- A 15-20 px glow and a chunky white X (`u06_crop`, ESTIMATED).
- Its flame edge is their ornament.

**Cards and slots** (`u06_crop`, `hud_bottom`, `i02_full`)
- **Frame (SAMPLED):**
  - a 6 px outer ring in a mid-dark shade of the rarity hue (#70560e, about 45% of the band);
  - a 5 px bright band;
  - a 1-2 px dark line;
  - a dark interior with a faint pattern.
  - The same on all four sides: no bottom lip.
- **Two hues on high rarity (SAMPLED):** the purple slot's band runs #3d32fd on the left to #fc32c2 on the right.
- A soft radial glow in the rarity hue behind each icon (`i02`).
- **Breaking the frame:** portraits overlap the frame, and in `g07` one rises out of the panel's top.
- **Type on the card:** the name is stroked, over the bottom border. The count ("x19") is about 45% of the slot's height, a stroked yellow gradient, on the bottom-right corner (OBSERVED).
- **States:**
  - **Selected:** a 4-5 px white outline with a 2 px dark gap (SAMPLED).
  - **Equipped:** a green check on the top edge.
  - **Highlighted:** a pale halo of about 12 px (`hud_bottom`, SAMPLED; probably hover).
  - **Locked:** a desaturated grey-lavender rim (#7b7fa6), a near-black fill and a grey padlock.

**Progress and health bars**
- **XP bar** (`hud_bottom`, SAMPLED): a 3-4 px black stroke and a 23 px track in a **dark tint of the bar's hue** (teal #002d2d to #00171c), not grey. The label is centred on it.
- **Enemy health bar** (`g05_full`, SAMPLED, about 10 px):
  - a 1 px black outline;
  - pure red lit from the top (#e90000 to #a30000);
  - a hairline, then a 2 px darker bottom lip;
  - chunk notches, and the stroked value centred.

**Primary action buttons** (`u06_crop`, `m02_full`, `g07_full`)
- **Ring stack, Equip at 82 px overall (SAMPLED), outside in:**
  - 3 px of black;
  - a 3 px ring of the hue at about 27% (#25441e);
  - a 2 px black hairline;
  - a **4 px rim brighter and more saturated than the fill** (#8cff6f);
  - the fill.
- **Lit from below:**
  - the fill runs #488d3e at the top to #6eed58 at the bottom, about +70%;
  - Sell does the same (#bd393d to #eb484b), with a brighter bottom rim;
  - horizontally the fill is flat.
- **Corners:** the rim's radius is about 12 px, traced (SAMPLED).
- **Label:** heavy italic, flat white, with a symmetric 2-3 px black stroke and **no offset drop shadow** (SAMPLED). The cap height is about 26 px on a 57 px fill.
- **Cost:** in a dark inset capsule of the fill's hue (`m02`).
- **Two lines:** a small hued caption over a large white value (`g07`).
- The widest button is the main verb. A keybind chip of about 28 px sits on the top-left corner.

**Titles and headers**
- **Display title** (`v05_full`, SAMPLED): a rounded heavy face, flat white, with a 6 px blue-black stroke on a cap height of about 90 px (about 6-7%).
- **Stroke scales against the size:** 15-19% on 21-26 px caps (SAMPLED).
- **Coloured titles:** a light-to-deeper gradient in one hue, inside a 4-5 px black stroke (SAMPLED).
  - "Story Act 1" (`g05`): #97c6f7 to #71adec.
  - "Rare" (`v05`): #149eff to #0b74ff.
- **Section labels:** bold small caps in the accent hue, no stroke (`p04`).
- **Divider:** a 3-4 px line from white to grey, with a diamond bullet (`v05`).
- **Stat row** (`g07`, SAMPLED):
  - a 3 px outline in the stat's hue, brighter at the bottom (#b15d5d at the top, #f45656 at the bottom);
  - a fill tinted with the hue;
  - an icon well;
  - a grade chip in the grade's hue.

**Colour, states, spacing**
- **Colour (SAMPLED):**
  - Max chroma only on edges, actions and rarity. Interiors are near-black.
  - Each element is one hue in 3-4 values: a dark ring at about 15-27%, a mid ring at about 45%, the band, and a bright rim.
  - Gold darkens toward orange, never toward grey.
- **Rows** (`p04_full`):
  - **Selected:** a 3 px light-blue outline.
  - **Locked:** a grey title and a red small-caps "LOCKED", against a yellow "OPEN".
  - **Pressed:** not captured.
- **Spacing (ESTIMATED):** the cap height is about 45% of the fill's. Gaps are 6-10% of the plate's height inside a group, and about 15% between groups.

## Why it reads as premium (ranked)

1. **The ring stack.**
   - 3-5 rings of one hue at different values, split by black hairlines, with a rim brighter than the fill.
   - Edges stay crisp over any world.
   - Best: `u06_crop`'s bottom bar (Equip, SAMPLED).
2. **Colour on the edges, black matte inside.**
   - The few max-chroma lines glow instead of flattening.
   - Best: `u06_crop`, `i02_full`.
3. **Directional light on every fill and word.**
   - Pressables are lit from below (+70%). Content plates are lit from the top, with a 3-4 px highlight.
   - Coloured text runs pale to saturated.
   - Only the system chrome is flat.
   - Best: `m02_full`, `s004_full`.
4. **Heavy, consistent strokes** in one display face plus a heavy italic for verbs, the stroke scaled inversely to size. Best: `v05_full`, `u06_crop`.
5. **Things break their frames:** icons, portraits, counts and badges astride borders, so it reads as depth, not boxes in boxes. Best: `hud_left`, `u06_crop`, `g07_full`.
6. **Scarce light as a material:** glows on key items, radial glows behind icons. Best: `i02_full`, `hud_left`.
7. **Texture at a whisper:** patterns, halftone and vignettes, so no big fill is empty vector. Best: `hud_left`, `u06_crop`'s ribbon.
8. **A fixed state grammar:** selected, equipped, locked, new, keybind. Best: `u06_crop`, `p04_full`, `hud_bottom`.

## What our finish should do (principles, our own style)

1. **Every pressable plate is a ring stack.** From the outside in:
   - a 2-3 px near-black hairline;
   - a 3 px ring of its hue at about 25% value;
   - a 2 px black hairline;
   - a 3-4 px rim brighter and more saturated than the fill;
   - the fill.
   - Each ring is about 4% of the plate's height.
2. **No flat fill on anything pressed.**
   - Buttons and tabs: a vertical gradient from about 60% value at the top to 100% at the bottom.
   - Cards and panels: light at the top to dark at the bottom, with a 3 px top highlight at about 50% white.
3. **Colour on the edge, black in the middle.**
   - Each element uses one hue in 3-4 values, and a warm hue shifts warmer as it darkens, never greyer.
   - Max chroma only for actions, rarity and the live numbers.
4. **Three type roles.**
   - A rounded heavy display face for names, numbers and titles.
   - A heavy italic for verbs.
   - A plain sans for meta.
   - Every display word gets a symmetric hue-tinted near-black stroke: 15-20% of the cap height under 30 px, 6-8% over 60 px. No offset shadow.
   - Coloured words run pale at the top to saturated at the bottom.
5. **Break the frame on purpose.** Icons, portraits, counts, labels and badges overlap the plate's edge by 30-50% of their own height.
6. **Light is a layer, and a scarce one.**
   - A 10-20 px outer glow in the hue only on what matters now: the open screen, the selected item, the close button.
   - A soft radial glow in the rarity hue behind every item icon.
7. **Texture at a whisper.** Any fill over about 100 px gets our own pattern or grain at 3-8% contrast, and a 15-20 px inner vignette.
8. **Bars.**
   - The track is a dark tint of the bar's own hue, inside a 1-3 px black outline.
   - The fill is lit from the top, with a 2 px darker bottom lip.
   - Notches mark chunks, and the value sits centred in stroked type.
9. **A fixed state grammar.**
   - **Selected:** a 4 px white outline with a 2 px dark gap.
   - **Locked:** a desaturated rim and title, plus a coloured small-caps tag.
   - **New:** a glossy disc, half outside the top-right corner.
   - **Keybind:** a chip on the top-left corner.
10. **Consistent radii:** about 12-15% of the height on buttons and chips, and 7-12% on cards and tiles. A capsule only on passive pills.

**Never take:** the flame-edged close disc, the slanted ribbon and its swash, the leaf-feather tile pattern, their icons, or the exact colour pairs read above. Only the construction carries over.

## Images looked at

`hud_left.png`, `hud_bottom.png`, `u06_crop.png` (located in `u06_full.png`), `s004.png`, `s004_full.png`, `i02.png`, `i02_full.png`, `m02.png`, `m02_full.png`, `m05.png`, `g05.png`, `g05_full.png`, `g07.png`, `g07_full.png`, `p04.png`, `p04_full.png`, `v05.png`, `v05_full.png`. That's 12 screens, with zoomed crops and pixel profiles from the `_full` files.

## Our adaptation (research, 2026-11-27, 00:19; DESIGN, for AR62's finish)

- **The construction carries over. ACX's near-black ground doesn't by default.**
  - The director said "too purple, black, somber" six times, and called the graphite HUD "a prototype".
  - So the finish keeps B's mid-value slate (AR62, piece 1) and earns its polish from the rings, the gradients, the stroked type and the overlaps.
  - One take tests a deeper slate, never near-black, to see whether the dark ground is what does the work.
- **Hue per system:**
  - gold for the signature and Credits;
  - cyan for Power;
  - azure rims for yours, coral rims for theirs.
  - Full saturation only on actions, rarity and live numbers.
- **Type:** a rounded heavy display face from Roblox's own fonts, with a near-black stroke on every display word, sized as rule 4 says.
- **Pattern:** our own fine grain at 3 to 8%. No motif from any other game.
- **Overlaps on purpose:** the portrait and the level badge cross the lead card's edge, and the damage taken crosses its top.
- **Sailor Piece** is the director's second named bar. Its study follows when its images are in, and it may adjust these rules.
