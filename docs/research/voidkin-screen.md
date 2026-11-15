# The Voidkin screen: a reference study

Research, 2026-11-14, night. This study is for TR17, the Voidkin screen remade (`docs/decisions.md`, 2026-11-14, night: "we really need a overhaul for voidkins menu ... it need to looks insanely good like ammorpg character but for each voidkin ... to make it easy").

**The question:** what makes a character screen feel like a premium MMORPG's, so a player wants to open one Voidkin and show it off? And how does it stay easy at phone size, landscape?

**The evidence so far:**
- **Taichi Panda 3: Dragon Hunter.** Two screenshots the director shared on 2026-11-12, in `build/reference/dragon-hunter/` (gitignored, internal), read at 1280 px wide:
  - `2026-11-12_character-slots.png`: the owner's character screen with the bag;
  - `2026-11-12_view-character-might.png`: another player's character, as a visitor sees it.
- **Anime Vanguards:** pictures of its units exist since 2026-11-15 (`build/reference/anime-vanguards/`, gitignored: Modulo's study for Watt, AR11, "The comparison"), but none of its unit screen. Screenshots of that screen are asked of the director. Until they come, nothing here is said about the screen.
- Stills only, so motion is unknown: how the figure moves, turns, or enters.

## OBSERVED (Dragon Hunter)

1. **The figure is the screen.** It is the full body in 3D, about 70% of the screen's height, in the left half. Everything else is arranged around it.
2. **The figure stands in a place, not on a panel.** Behind it is a meadow at dusk, with soft depth, flowers in the foreground and a glow behind the body (violet on the visitor's view). It reads as a character in its world.
3. **Two halves.** On the left, the figure with its slots. On the right, a framed panel whose content changes with the tab: the bag on one screen, name, level, class and social buttons on the other.
4. **Two levels of tabs.** A vertical rail of round icon tabs runs down the far left (Attribute, Backpack, Skill, Title), and the selected one is larger and lit. The panel's own tabs sit on its right edge (Equipment, Items, Jewels, Shards, Souls).
5. **A thin top bar:** a back arrow and the screen's name on the left, the currencies on the right.
6. **The power number at the feet:** "Might" on a pointed pill, then seven wide-set digits (also `docs/research/gear-icons.md`, 10).
7. **Facts as pills:** the visitor's panel lists Name, Level, Class and Guild as dark rounded pills, a label on the left and the value on the right. The action buttons are a column beside them.
8. **Dense ornament:** gold filigree on the panel's corners and bevelled gold buttons. It's theirs, and our look is never built from it.
9. **The same view is shown to others.** The visitor's screen is the owner's figure, slots and number, with social buttons in place of the bag.
10. **Measured, 2026-11-15,** on `2026-11-12_character-slots.png` at 1280 px, the game's frame about 570 px tall:
    - A gear slot is about 67 px square, about 12% of the height, on a pitch of about 75 px.
    - Each side has a column of five, then a bottom row of four across the figure's feet. The inner two of that row stand right beside the feet, and one holds a weapon (a mace).
    - The figure stands about 420 px, about 74% of the height. There's no strip below it.
11. **The rail,** same image: a thin vertical line runs down the far left, with round buttons strung on it, each with a small label under it.
    - An unselected circle is about 38 px across (about 7% of the height). The selected one is about 70 px (about 12%) and haloed, with its label larger.
    - Four buttons fill the rail's height, so it reads as one ornament, not a list.

## DESIGN (ours, for TR17's blockout)

- **The Voidkin is the screen.** Its own model, live, at about 70% of the height, plays its Idle on a small stage of its own, and turns when dragged.
  - A tap on the figure plays a short flourish of its own, the end of its Reveal. It costs nothing new and makes the character feel alive.
  - The stage's light is the rarity's light (`docs/ui.md`, rule 3; Mythical reddish), and the floor glow takes its element. So a Mythical's screen looks different before a word is read.
- **Combat Power at its feet,** as already designed (`docs/design.md`, "Combat Power"; `docs/research/gear-icons.md`).
- **Gear's slots stand round the figure** (corrected, 2026-11-15: `docs/design.md` already put Combat Power between the slot columns, and the director asked for them). They show the preset this Voidkin is linked to, so gear stays the account's. The kit and the stars live in the menu's pages. The director's layout is in TR17.
- **One panel beside the figure,** with a few tabs:
  - **Overview:** name and nickname, rarity, type, class, element, level and experience, its role now;
  - **Stats:** the honest stat sheet (`docs/ui.md`, "Stats, shown honestly");
  - **Kit:** what each move does, in plain words;
  - **Stars:** the next star's gain before it's taken.
- **Switching Voidkin without leaving.** A strip of portraits from the collection runs along one edge, and a swipe on the figure goes to the next or previous one. "For each Voidkin" stays one tap from any other.
- **The two things done most stay in view:** Lead (or Leading) and Send to work. Favourite, lock and rename are small, beside the name.
- **Our look:** Graphite Dark, shard-cut chamfers, bars as conduits (`docs/ui.md`, rule 3). Never filigree, bevelled gold or their pill shapes. The look is drawn with Modulo once a layout is chosen.
- **The rail, ours** (the director, 2026-11-15): a thin conduit line, our bars' language, with round buttons strung on it. At rest a button is a small cut ring with its icon. Selected, it's larger, its ring lit in the room's colour, with light running along the line to it. Never their gilt, horns or filigree.
- **The slots** stand about 12% of the height where they fit. Main Hand and Off Hand sit at the feet, one each side of Combat Power. The icons' art follows `docs/research/gear-icons.md`.
- **Phone landscape:** the figure takes about 45% of the width and the panel about 45%. Taps are 44 px or more, text 14 px or more, and nothing sits under the thumbs' corners.

## Images looked at

The two Dragon Hunter screenshots above, whole, at 1280 px wide (`build/scratch/quaestor/ref/`). No crops made.
