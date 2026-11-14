# Gear icons and the forge screen: a reference study

Research, 2026-11-12. For AR6, Regalia's item art, and Combat Power's moments (`docs/design.md`, "Regalia: gear" and "Combat Power").

**The question:** what makes an item icon worth wanting when gear is never shown on the body, how rarity reads at a glance, and how an upgrade is made to feel like an event.

**The evidence:** two screenshots of Taichi Panda 3: Dragon Hunter the director shared on 2026-11-12, in `build/reference/dragon-hunter/` (gitignored, internal): `2026-11-12_fortify-dawn-mage.png` (the forge screen, a Mage in Dawn gear) and `2026-11-12_character-slots.png` (the character screen and the bag). Both are 2000 px wide phone captures from videos; an icon is about 100 px in them, enough for form and light, not for fine ornament. The director's words: Epic, ordinary Legendary, then Dawn, "legendary rarity but above legendary". More rarities to come from the director.

## OBSERVED

1. **Rarity is the frame's colour,** three seen: green, purple (Epic), orange-gold (Legendary). The frame is thick and bevelled, with small ornaments at the corners. Inside, the background is a vignette of the same colour, lighter behind the object.
2. **Dawn shares Legendary's frame.** What lifts it is the object itself: every Dawn piece is the same pale-gold metal, glowing, with one gem colour repeated on each (the book's cover, the hat, the bracers). Five different slots read as one set at a glance (fortify screen, the left list).
3. **The object fills the square,** about 80 to 90% of it. Long weapons lie on the diagonal, head up and to the right (the scepter; the axe on the character screen). Small pieces (rings, earrings, amulets) are widened with flourishes, wings or feathers, so they fill the square like the large ones.
4. **They look rendered, not drawn:** a warm key light from above, sharp highlights on metal, dark recesses, a clear silhouette against the vignette. No outline.
5. **The badges sit on the frame, never on the object:** the forge rank as a bold "+10" bottom right, a lock top right, a stack count bottom right on materials.
6. **The character screen** sets six slots in a column on each side of the full-body figure and two more under it. The figure is large, the icons equal in size.
7. **The forge screen makes the upgrade an event:** the item enlarged at the centre in a radiant gold halo with rays and sparks, its materials around it in their own frames with have/need counts, the stats before and after in two columns (+9 to +10, every line up), the chance shown in green, the cost and one button.
8. **Gear stats are big numbers** (+301, +910). A gain of one rank adds tens to each line.
9. **The Mage's pair is a scepter and a book,** as the director named for ours.

From the third screenshot, `2026-11-12_view-character-might.png` (another player's character, seen by a visitor), and the director's words with it:

10. **The power number sits at the figure's feet,** across the bottom of the character between the slot columns: a short label on a dark pill ending in a pointed tip, then the number in large, widely spaced digits, seven of them at this player's level 200. It reads as part of the character, not as a stat line.
11. **When an upgrade lands** (the director's words): the number pops a little, a green "+" gain shows, and the yellow counter updates. A small pop, not a burst.
12. **The forge rank is on every icon** (the director: the number on each gear is its fortify level), +42 to +50 here. Under each icon's number runs a row of small marks in the frame (crowns on some, stars on others), a second rank shown on the frame.
13. **Frames here are red,** a colour past the orange-gold of the first two screenshots, on every slot of this endgame player. Which rarity red is in that game isn't known from these images.
14. **The same screen is what other players see** of you: the slots, the figure and the number, beside social buttons. The number is a thing to show off.

The director: "we can choose where we show combat power".
15. **The frame's form steps at Legendary** (the director, 2026-11-15: "from common to epic it same but at legendary it has a new border this is great"). Read on crops at full size, 2532 px wide, of `2026-11-12_character-slots.png` and `2026-11-12_view-character-might.png`, enlarged 2 to 3 times (`build/scratch/quaestor/ref/slots-both.png`, `red-a.png`, `red-b.png`):
    - **Below Legendary** (green, purple, and a pale tan one): one frame. It's a square with its four corners cut, a single thin rim a step lighter than the fill, and a flat vignette fill. Only the colour changes.
    - **Legendary** (orange-gold): a new frame. The corners are square, not cut, and a double rim runs round, thin and copper. A small pyramid stud stands on each corner, sitting over the rim's crossing and reaching just past the edge.
    - **The red above it:** the Legendary form again, with each stud a faceted red gem. The rank's row of small crowns sits inside the foot. On a weapon, the fill carries a painted scene behind the object, with a glowing band along the foot.
    - So the form changes once, at the rarity a player chases, then gains jewels above it. Up to Epic, the colour alone carries rarity.
    - The rank's digits are blue at +10 and violet at +11 and +12 (`slots-both.png`). What that colour means isn't known.

## DESIGN (ours)

- **Rarity in three layers,** each readable alone: the kit's frame (AR3), the inner light, and the object's own material, from plain iron to gilt. A Common item is still a well-made object, just plainer.
- **A top series reads as a set:** one material family and one accent shared by every piece, so Dawn is recognised before its name is read. Dawn's own material and accent come from our world, on AR6's sheet.
- **Fill and pose:** the object fills about 85% of the square; long weapons on one diagonal for every class; small pieces widened by their own ornament. One light and one camera for every icon, so the bag reads as one family.
- **The frame steps at Legendary** (the director's liking, 2026-11-15; OBSERVED 15). Common to Epic share one gear frame, our kit's cut in the rarity's colour (the director's green, blue, purple). Legendary gets a frame of its own, in our kit's language: the cuts become lit facets, a second rim of light runs inside, and a small crown rises from the top edge, the same crown that marks a Legendary portrait (AR3). Never square corners with studs. Mythical keeps Legendary's form, with its crown broken and its light reddish, as on its portrait. Dawn's frame is set on AR6's sheet. Each step must show at the slot's size on the Voidkin screen (about 38 pt).
- **Badges on the frame only:** forge rank, lock, upgrade arrow, count. The object is never covered.
- **Modelled, then rendered** (`docs/design.md`, "Regalia: gear"): what gives these icons their depth is light on real form, which a model gives for free and a flat drawing fakes.
- **Combat Power where the figure stands:** on Regalia and on one Voidkin, at the Voidkin's feet between the slot columns, so the number belongs to the character. The same view is what a visiting player sees of your lead, so it's worth showing off. When it changes: a small pop, the gain in green, the counter rolling in gold.
- **The forge as an event:** the item enlarged and lit at the centre, stats before and after with every gain shown, the Combat Power gain rolling up after. Whether our forge can fail is not part of this study and not in our design.

## Images looked at

The three above, whole. No crops made.
