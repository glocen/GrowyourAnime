# The HUD and the screens

How the game's interface is laid out and how it behaves. Research's direction, 2026-11-11. The look of the kit (frames, icons, textures, effects) is the asset maker's, designed from this page (`docs/asset-requests.md`, AR3). The builder builds every screen from one component library.

The director, 2026-11-11: "we need to be even thoughtfull with the HUD".

**Status:** direction on paper. No screen is drawn or built. The package's mockups (`docs/archive/package-v13/`) are web pages in portrait with invented numbers: useful for what each screen must hold, not for how it looks. Roblox on a phone is landscape.

## The four rules

1. **Phone first, landscape.** Every screen is designed at phone size and grows to a desktop, never the other way. Touch targets are 44 px or more, text 14 px or more, and nothing sits under the thumbs' resting corners or the device's notch.
2. **Quiet until it matters.** In the world, the screen shows the fight. A number, a chip or a glow appears when something changed and leaves when it's read.
3. **One look, ours.** Panels have chamfered, shard-cut corners. Bars read as conduits that fill with light. A rarity is the frame's shape and glow. **Words wear their meaning's colour** [the director, 2026-11-15: "the epic chance text should be purple, the battery text need a rework also like it energy colors"]: a rarity's name and its odds in the rarity's colour, power and the battery (kW, kWh) in Power's yellow, Credits in their teal, the rest ivory. A coloured word is never the only sign of a rarity. Four palettes from one kit [the director, 2026-11-12: some screens get a palette of their own; which is the asset maker's choice, and the whole must hold together]: Graphite Dark, the main one, for the field and the collection; Dynamo for the machine rooms (the bays, the Forge); the Breaker a room of its own in a galaxy's palette and stars, never a literal galaxy's form, composed and slowly moving [D, 2026-11-15]; Void Violet for the reveal; Pearl Light, drawn with a black border, for what's read like a page (the map, a shard's odds, a stat's sources). A palette changes a panel's body, edge and ink and the accent; never the cut, the frames, the gems and marks, or the colours that mean something. The screens of each: `docs/asset-requests.md`, AR3. Mythical's light is reddish, never a rainbow [the director, 2026-11-12].
4. **The interface never lies.** No success animation plays before the server has said yes. A count-up shows the real change. A disabled button says why.

## The HUD, in the world

| Where | What | When it shows |
|---|---|---|
| Top left | the lead's card [D, 2026-11-12, from a reference; its place may move]: the portrait in its rarity frame, the level on a badge on the frame; beside it a long health bar with current and maximum written inside, and a thinner experience bar beneath (its width and colour ours); name or nickname, type gem, class icon | always, small |
| Top centre | the target's card, built like the lead's: name above, type gem, health, a keeper's phases | only in a fight |
| Top right | two pills: Credits, and Power: generation against demand in kW [D, 2026-11-14, night] (`docs/design.md`, "Power"). A tap opens the rest | always |
| Beside the signature's readout | the spectate toggle [D, 2026-11-14]: a small eye; on, the camera follows the lead. Its place is set at TR11's blockout | always, small |
| Under the pills | event chips: the Void Shop's countdown, the Rift, the Calamity | only inside the last minutes before and during |
| Right edge, low | the signature's readout: a ring that fills, flashes when it fires | always, small |
| Bottom centre | the dock: Voidkin, Base, Map, and one more at most. Regalia's screen is merged into the Voidkin screen [D, 2026-11-15] | always |
| Over the world | damage numbers, the Breaker's progress above the machine, a worker's output above its bay | where they happen |

- **Damage numbers** [D, 2026-11-12, from a reference: `docs/research/hud-reference.md`] are outlined and widely spaced, with thousands separators, so they read over any background: a hit dealt pale ivory and upright; an element's second number the same, in its element's colour, a beat behind; damage your lead receives the same face in muted red, a size larger; healing as damage received, in green; a critical gold, heavy, slanted forward, larger, on a swept stroke of our own behind it; a dodge, a block or an absorb a short grey word on a pointer [D]: Absorb when a shield takes the hit whole, and the shield's bar loses what it took. They rise from the body that was hit and never stack into a wall: a flurry merges into one counting number.
- **The type edge** shows on the target's card as a small arrow, up or down, before the first hit lands. The player learns the ring by seeing it, not by reading a chart.
- **A fallen lead** dims its card and shows it's healing at home, with the time left, then that it's training (`docs/design.md`, "A fall sends it home").

## The screens of the first loop

Built first, in this order, each to the bar before the next.

1. **The HUD** above.
2. **The reveal.** Full screen, no chrome: the shard, the crack, the silhouette, the name, the rarity as the frame's shape. Then one card: type, class, element, signature, and what it's good at in a line. Skippable after the first second.
3. **The Breaker.** The chambers as they are in the world, each with its shard and time left; the waiting line beneath; the shard's odds one tap away; infusion as a clear choice with its price and its effect on the odds.
4. **Voidkin.** A grid of portraits, the frame showing rarity, a gem for type and an icon for class. Sort and filter by type, class, role. A long press compares two.
5. **One Voidkin, the character screen** [D, 2026-11-15: Regalia merged into it; its layout is `docs/test-requests.md`, TR17]. Full screen. The selected Voidkin large and turning, between its linked preset's slots, each with its item's icon and its forge rank, the two hands at its feet beside Combat Power. A rail on the left holds every page: Overview (name, nickname, rarity, type, class, element, level, and the whole stat sheet), the bag, Kit, Stars, Forge, Jewels, War Emblems. The bag is the right panel, the player's whole inventory. A tap on a slot opens it: the item, its sockets, what's in the bag for it, with the difference as plain up and down numbers and in Combat Power. Presets as tabs. Combat Power's moments: `docs/design.md`, "Combat Power".
6. *(Merged into 5, 2026-11-15.)*
7. **The base's bays and the Power screen.** Each bay with its worker, output and level. The Power screen, from the generator: generation and demand, one bar split among the machines by its handles, +/- on each share, Auto, and the battery in kWh (`docs/design.md`, "Power"). Assign workers by dragging or by tap.
8. **The map.** The six grounds as a festival route, the keeper's gate on each, what each ground's shards hold.
9. **Shared pieces:** confirm, error, toast, reward, empty state.

Everything else (the Forge, the Condenser, the Lab, the Void Shop, the Tower, the Clash, the Calamity, settings) is built on the same kit when its system is built.

## Every component has these states

Rest, pressed, selected, disabled with its reason, waiting on the server, succeeded, failed. A screen is reviewed with empty, full and long-name content, in both themes, at phone size.

## Stats, shown honestly

- The stat sheet lists every stat with its number and, for a rating, the chance it gives against an equal opponent.
- A tap on a stat says where each point comes from: the Voidkin, each slot, emblems, jewels, research. Since everything adds, the list sums to the total, and the player can see it does.
- An item's comparison never shows a percent of a percent.

## Nicknames

About twenty characters, passed through Roblox's text filter before anyone else can see it, shown with the real name beneath on the detail screen (`docs/roblox-rules.md`).

## Reviews

Each screen gets research's verdict from a real phone-sized capture (`/ga-review`), then the director's eye. The UI lint (clipping, overlap, touch sizes, safe areas) runs before either.
