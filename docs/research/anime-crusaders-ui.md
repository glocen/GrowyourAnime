# How a high-quality anime Roblox UI is laid out: Anime Crusaders X (study)

Faber, 2026-11-25, 00:49 to 01:01 by the PC's clock. Played live on the director's account at the director's ask ("we arent aiming to copy their nor do something similar but learn how high quality UI is made, this will be an example of many"). It's an anime tower-defense game: the genre and the systems differ from ours, and the study is about how its UI is put together. We study function and principle only. Their art, icons, frames, layout and names are never ours (AGENTS.md rule 3, `ga-reference-study`).

**The question:** what makes this UI read as high quality: its structure, its hierarchy, its colour and type, and how each screen guides the player?

**Evidence:** screenshots at 2560x1600 and one 10-second recording, in `build/reference/anime-crusaders-x/` (gitignored, never uploaded). Every finding below is OBSERVED in those images unless it's labelled DESIGN.

## What was seen, by screen

**Lobby HUD** (`s004`, `hud_left`, `hud_bottom`)
- The menu buttons sit in two columns of square tiles at the screen's left and right edges, about 8 + 5 of them.
  - Each tile has its own hue. The border is a thick gradient in that hue, and the interior is dark with a faint pattern.
  - The icon is an illustrated object with a heavy dark outline, cel shading and a gradient fill, a little bigger than the frame's opening, in the same hue as the border.
  - The label sits on the tile's bottom edge: white, chunky, with a black stroke.
  - Keybinds show as small black circle badges on a tile's corner (F, H). News is a red "!" badge.
- The bottom centre stacks, from the top: the currencies (icon + number, the number tinted in its icon's hue), the six unit slots (cards in rarity frames; a locked slot is flat grey with a padlock and "Lvl 5"), then a thin XP bar reading "Level 1 [0/100]".
- The top right holds small dark translucent pills: "Login Rewards: 23h 52m", friends, "UPD 10.5".

**One panel template, tinted per menu** (`u04`, `i02`, `p01`, `p04`)
- Units, Items, the Wiki and Story all use the same panel. A slanted ribbon carries the title and breaks out over the top-left border. The frame glows in a gradient. A large round X with a flame sits half outside the top-right corner.
- **The whole panel takes the colour of the button that opened it:** Units yellow, Items blue, the Wiki purple, Story blue. The player always knows where they are.
- Opening a panel blurs the world behind it, and the HUD columns stay visible.
- A panel has three parts:
  - tabs, a search field and Filters on top;
  - the grid on the left, with a detail pane on the right and a rail of square icon buttons (favourite, lock, inspect, delete);
  - a bottom bar of wide buttons, each its own hue: Quick Lock orange, Quick Sell yellow, Teams purple, Unequip All red, Equip green. Equip turns into a red Unequip when the unit is already equipped.

**Cards** (`u06_crop`, `hud_bottom`)
- The card's background is a gradient in its rarity's hue: gold, purple, blue, green.
- The portrait fills the card. The name runs across the bottom in the stroke font, over the portrait. "Lvl 1" sits top-left with the number in yellow, the price in yellow above the name, and the element badges stacked top-right.
- An equipped card has a green check above it. The selected card has a thick white outline. Duplicates stack with an "x2" badge.
- The hover tooltip is a dark rounded card: the name, then a rarity line in the rarity's hue ("Epic Unit"), chips (Ground, Farm, Physical), the level and XP bar, stat cells, and **"Exist: 1,037,997"** with the unit's kills.

**Item detail** (`i02`)
- Small pills name the rarity (top-left) and the type (top-right). The icon sits on a radial burst in the rarity's hue, with the rarity's name in small text above the item's name.
- Below come folding cards: DETAILS (the count owned, a one-line flavour quote in italic yellow, then the plain description) and WHERE TO GET IT (the source, with its path in grey).

**Summon** (`m02`, `m03`, `m05`, `r01`, `v02` to `v11`, `m06`)
- Summon is a place in the lobby: the button walks the player to a room, and the screen closes when they walk out. There is no X.
- The layout:
  - **Left:** the Robux packs and boosts as cards in their own hues, each with a corner tab showing its bonus ("+20%").
  - **Top:** the banner tabs as small art cards.
  - **Centre:** three featured units standing in 3D, each named with its rarity underneath, and a "FEATURED" pill on one.
  - **Top right:** "Banner Change 7m 04s" with a thin bar.
  - **Bottom:** the pity bars ("Legendary 0/50", "Mythic 0/400", "Secret 0/10,000"), Rates, Auto Roll, Auto Sell toggles per rarity, then Summon 1x and Summon 10x in green with the cost in a dark inset.
- **The pull (one 10x on free gems, the director's OK):**
  - A "-500 Gems" toast slides in from the right.
  - A full-screen void hole ringed in light opens, with streaks pulling into it.
  - Then each unit stands in 3D on a huge radial burst in its rarity's hue (gold, purple or blue), with a light ring on the floor.
  - On the left, large: the name, a thin divider, the rarity word in its hue, the level, and three stats. Each stat shows its grade letter (C+, B-, A-) and its rolled deviation (+5.0% in green, -0.9% in red), then the tags, each in its own colour.
  - Along the top, a strip of "Summon 3/10" fills one slot per unit.
  - Bottom right: **"Original Owner: @glocen / Obtained Nov 24, 2026 23:53 UTC"**.
  - After the tenth comes "Rewards Obtained", sorted by rarity with duplicates stacked, and Continue (or Space, shown as a key chip).

**Play** (`p03`, `p04`, `p05`)
- There's no panel: the left half is a list and the right half is the 3D lobby. Empty party slots are pads in the world, each with a floating green "+" and "INVITE".
- The modes come in sections. Each section opens with a slanted label strip (FEATURED, PROGRESSIVE, REWARDS) and a count. Each mode is a wide card on its own tinted art, with:
  - small-caps tags ("PARTY · HARD · LIMITED");
  - the title;
  - one line of description;
  - a "0%" progress chip.
- The Story picker runs in three columns, read left to right in the order the player chooses: world, act, preview.
  - Locked things say LOCKED in red; the open one says OPEN in yellow.
  - The preview gives the difficulty with its unlock hint ("Clear it on Normal to open Hard."), a strip of rewards with counts and "First Clear", and Best Time and Clears.
  - A hint line sits next to Back: "Pick a world, then an act."
- The party lobby shows the stage card, then the rewards, then one row per player with their equipped units, then "Empty · Invite a player". Start is green, Change Map purple, Change Mode yellow.

**In the match** (`g01`, `g03`, `g05`, `g07`)
- Top centre: three chips, "3 health", "1/15 wave" and "3 enemies", with "9 to spawn" under the wave chip. Each is a dark pill with a coloured icon, the number big and the label small and grey.
- Right: the stage title in the stroke font, "Normal Mode", then Unit Manager (F), Stage Info (C) and Macro.
- The lobby's tiles shrink to a row of small squares at the bottom left. The money sits above the hotbar.
- Dialogue is a wide box, low and in the centre, translucent dark wine-red. The speaker's name sits on the box's top edge, with ">" to advance.
- **Placing a unit:**
  - A ghost of the unit follows the cursor.
  - Next to the cursor, a column of key hints: Place, Cancel (Q), Rotate (R), Quick Place.
  - The path turns red where a unit can't go, and the card lifts with "0/4" above it.
  - After placing: a "Unit placed" toast, "+¥180", and the unit's panel.
- **The unit's panel** has the unit's rarity colour.
  - The portrait breaks out of the panel's top.
  - Each stat row shows its upgrade's preview in green: DMG 186 → 383, B+; SPA 7.1s; RNG 12.5 → 13.5.
  - Then Crit Chance and Crit DMG.
  - Buttons with their keys: Priority First (R), Sell ¥500 (X, red), Upgrade 0/6 ¥1,350 (T, green, the widest), Auto Off (Z). Six upgrade pips sit under them.
- **A unit's attack** (`vid/hit1`, 20 fps, about 1 s):
  - It's one shape: a white-hot core in the unit's hue (pink), radial spike streaks shooting outward, and a translucent dome that swells and fades. Then a few pink wisps on the ground.
  - Blue damage numbers with a white stroke stack once per enemy hit ("186" many times).
  - About three layers and one hue, but very bright, and readable at the game's zoom.
- The game has a built-in auto-play "Macro" panel. It was running when the match started: "Saving ¥1,300 for Twenty One", runs and wins counted, Pause / Stop / Open.

## Why it reads as high quality (analysis)

1. **Colour has a job.** A hue means a place (each menu's button colour becomes its panel's colour), a rarity (cards, bursts, rarity words), or an action (green go, red sell or cancel, yellow or purple secondary). Nothing is coloured for decoration alone.
2. **One template, many screens.** The same ribbon, frame, X, tabs, grid, detail pane and bottom bar repeat. Players learn the template once, and the team builds each new screen cheaply.
3. **A strict type hierarchy.** One chunky stroke font for every name, title and button, and a plain sans for descriptions and small labels. Numbers are always the biggest thing in their cell.
4. **Everything says what comes next.** Unlock hints, upgrade previews (186 → 383), pity counts, timers, "Pick a world, then an act.", keybind badges on every button.
5. **Every number has a frame.** A stat is never a bare number: icon + grade letter + value + its change.
6. **Collectibles have a history.** "Exist: N", "Original Owner", "Obtained <date>", kills, the rolled deviation: each copy is a thing with a story, not a stack.
7. **The big moments go full-screen and 3D.** The summon and the placement use the world itself (the room, the ghost, the red path), not a flat panel.
8. **Effects are simple and bright.** One hero shape, one hue, a white core, and big readable numbers.

## Lessons for us (DESIGN: proposals, not decisions)

These feed AR62's style frame and the screens waiting on it. Our art, shapes and names stay our own.
- Give each HUD button a hue, and tint its screen with it. That fits the "too purple" note: violet stays for what is alive or for sale.
- Build one screen template (title, frame, close, tabs, grid, detail, action bar) and derive every inventory-like screen from it.
- Put an upgrade's before → after on every upgrade button, and an unlock hint on every locked thing.
- Give the Voidkin card provenance: how many exist, who broke it first, when, and its kills (the director's ask, below).
- Give the shard break a reveal the way a banner pull has one: a full-screen void moment, then the Voidkin standing in 3D on a burst in its rarity's hue, its rolled stats with their deviations, a counter strip for a multi-break, and a sorted summary.
- Effects: one hero shape in the Voidkin's hue with a white core, and big damage numbers (this agrees with Scintilla's brief).

## The director's words during the study (verbatim)

Times are bounded by the capture files' clocks.
- Between 00:52:57 and 00:53:45, on the tooltip's "Exist: 1,037,997": "this exist thing is dope we need this also maybe awe should have a summon systems instead of void breaking like scrap that idea or have both system".
  - **The count of how many exist:** covers a fighter's existing-copies count, shown to players. It's a new feature players see, so tier 2, and it's for research to record and spec.
  - **Summon versus breaking:** a question about the core, not a decision. Faber answered: keep the shards, and give the break a banner's presentation (Rates, a featured Voidkin per rotation, pity, a reveal, the count). Replacing shard breaking would be a core change: the director's yes to a plain restatement first.
- Between 00:53:45 and 00:54:01: "do a multi summon i allow you to do it", then "summon 10x". This covered one 10x summon on the free in-game gems (500 of 5,800). No Robux was spent.
- Between 00:58:36 and 01:00:16, on a unit's attack in the match: "see those sfx for their skill it that simple this is what we need".
  - Read as the visual effect: a recording can't carry sound to Faber, and the effect on screen was the pink burst.
  - It covers the look of skill effects: simple, one bright shape. It goes to Scintilla and research. If it meant the sound, it goes to Sonus.
- Between 01:00:44 and 01:01:07: "ok this is enough for today take note then we are done".

## Images looked at

`build/reference/anime-crusaders-x/`: s001 to s004, u01 to u06 (with `u06_crop`), i02 (`hud_left`, `hud_bottom`), m02 to m08, r01 and r06, v02, v05, v10, v11, p01 to p05, g01 to g07, `vid/skill1.mkv` (`sheet1`, `hit1`, `hit2`). Not opened: the Store, Events, Areas, Quests, Battlepass, Guilds, Profile, the end-of-match screen and the upgrade's own effect. A later session starts there.
