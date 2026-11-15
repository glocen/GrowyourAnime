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

## The stat sheet: Dragon Hunter's attributes

Research, 2026-11-15, night, on the director's words to Faber: "no no no no crit can go as far as 20k % ... we need to show all stats like tcp 3 looks how the overview is in tcp 3".

**OBSERVED, with how sure each line is:**
- **The stats.** Sourced for Dragon Hunter itself, through the director's package of 2026-11-11 (`docs/archive/package-v13/99_REFERENCE_ARCHIVE_V12_4/REFERENCE_FULL_DESIGN_v12/00_CURRENT_DIRECTOR_GEAR_STATS_v11_8/01_SOURCE_VERIFIED_DRAGON_HUNTER.md`, with its links):
  - Health, Attack and Defence;
  - Hit (命中) against Dodge (闪避);
  - Critical (暴击) against Anti-Crit (抗暴);
  - Critical Damage (暴击伤害) against Critical Damage Reduction (暴免), which is a separate stat from Anti-Crit;
  - Block (格挡), Damage Reduction and Damage Bonus;
  - Fire, Wood and Thunder damage and resistance, in class skills;
  - one power number, Might.
- **Where stats come from.** Sourced the same way:
  - gear, and its forge;
  - jewels in gear sockets;
  - emblems (纹章, and the later 战纹);
  - soul stones set on a slot (附魂);
  - mounts;
  - pets, though only the first game's guide says so: there, a pet's Might adds to the player's ([AppGamer](https://www.appgamer.com/taichi-panda/strategy-guide/increasing-your-might)).
- **Points and percents.** Sourced:
  - a mount's table writes some of its bonuses as percents;
  - a 2019 patch fixed a "+50% Hit" bug ([App Store, China](https://apps.apple.com/cn/app/id1179678479)).
- **A pattern only, from the first Taichi Panda and from Taichi Panda: Heroes, not Dragon Hunter:**
  - Critical Damage is a percent that adds up across gear. One helm, fully refined, gives 37% ([GamerSky](https://shouyou.gamersky.com/gl/201511/687391.shtml)).
  - In Heroes, a critical multiplies the base damage by it, less the target's Crit Reduction ([its fan wiki](https://taichipandaheroes.fandom.com/wiki/Attributes)).
  - The formula that circulates, "Hit − Dodge, min 20%", is from that first game too.
- **Not found: the Attribute page itself.** Nothing shows its layout, which stats it shows as points and which as percents, or its caps and formulas.
  - None of these had it: the director's package (which says so itself), today's searches in English and Chinese, and our two captures (the Character page and View Character).
  - Two screenshots of the Attribute page, top and scrolled, would settle it. They go in `build/reference/dragon-hunter/`, kept internal.

**What our sheet does today** (TR17, `2d91c71`; `build/captures/overview/stat_sheet_smallest_phone.png`). Every family above is on it. Three things differ from the director's words:
1. **Critical reads "0 · up to 5%".** The 5% is the chance every hit has at zero points, a floor and not a cap, but it reads as a cap.
2. **Critical Damage can't pass +200%.** It's added into the attacker's bonus bucket, whose ceiling is +200% (`Config.Stats.Buckets.BonusCap`). That ceiling covers Damage Bonus and the type edge too. So 20,000% can't happen today.
3. **"Own" holds the level.** It's the Voidkin's base at its level, so the level isn't a line of its own.

**DESIGN, research's proposal, the director's yes** (2026-11-15, about 21:15, to Faber: "keep working, and yes"; the register):
- **Critical Damage has no ceiling.**
  - It leaves the capped bucket and multiplies a critical by itself: × (1 + Critical Damage − the target's Critical Guard).
  - It starts at +50%, and every source adds percents to it.
  - Over the updates it can reach 20,000%. At launch the sim keeps it in the low hundreds.
  - Each update that raises it raises the foes' health and Critical Guard on the same curve (`docs/balance.md`, "The one rule").
- **Critical's chance stays a chance,** so never past 100%. Its points grow without end, and each point adds less as the chance nears its ceiling. The ratings stay as they are, the shape the director's package asked for ("a raw rating is not +75 percentage points"; "Prefer a rating-based model", `02_COMPLETE_STAT_TAXONOMY_AND_HIT_DODGE.md`).
- **The sheet shows totals, never "up to".**
  - Each stat is one number, the sum of its sources: a rating as its points, a percent as its percent.
  - A tap opens the stat's sources, and they add up to it. The sources:
    - the Voidkin's own base;
    - its level;
    - its stars;
    - gear;
    - forge;
    - jewels;
    - War Emblems;
    - research;
    - the skill tree, when it comes.
  - A source shows once it's in the game.
  - For a rating, the tap's last line gives the chance against a foe of its level with the same points. That's the honest line `docs/ui.md` asks for, moved off the sheet.
- **The risk, said out loud.** With no ceiling, Critical Damage is the one stat whose worth keeps growing while the others flatten. At a 60% chance and 20,000%, a critical is 201 times a plain hit and the average hit is about 121 times one, so the other lines on gear look small beside it.
  - Research accepts this cost for a long-grind power fantasy, as the genre does.
  - What keeps it fair: Combat Power's weights count it, and each update's sim prices the foes against it.

## Images looked at

The two Dragon Hunter screenshots above, whole, at 1280 px wide (`build/scratch/quaestor/ref/`). No crops made.
