# The HUD and the screens

How the game's interface is laid out and how it behaves. Research's direction, 2026-11-11. The look of the kit (frames, icons, textures, effects) is the asset maker's, designed from this page (`docs/asset-requests.md`, AR3). The builder builds every screen from one component library.

The director, 2026-11-11: "we need to be even thoughtfull with the HUD".

**Status:** direction on paper. No screen is drawn or built. The package's mockups (`docs/archive/package-v13/`) are web pages in portrait with invented numbers: useful for what each screen must hold, not for how it looks. Roblox on a phone is landscape.

## The four rules

1. **Phone first, landscape.** Every screen is designed at phone size and grows to a desktop, never the other way. Touch targets are 44 px or more, text 14 px or more, and nothing sits under the thumbs' resting corners or the device's notch.
2. **Quiet until it matters.** In the world, the screen shows the fight. A number, a chip or a glow appears when something changed and leaves when it's read.
3. **One look, ours.** Panels have chamfered, shard-cut corners. Bars read as conduits that fill with light. A rarity is the frame's shape and glow, never a coloured word in a corner. Two themes from one kit: Graphite Dark is the main one, and Pearl Light, drawn with a black border, serves some screens, and some screens get a palette of their own on the same kit [the director, 2026-11-12]. Mythical's light is reddish, never a rainbow [the director, 2026-11-12].
4. **The interface never lies.** No success animation plays before the server has said yes. A count-up shows the real change. A disabled button says why.

## The HUD, in the world

| Where | What | When it shows |
|---|---|---|
| Top left | the lead's card: portrait, name or nickname, type gem, class icon, health, experience, level | always, small |
| Top centre | the target's card: name, type gem, health, a keeper's phases | only in a fight |
| Top right | two pills: Credits and Electricity (stored over cap, and the rate). A tap opens the rest | always |
| Under the pills | event chips: the Void Shop's countdown, the Rift, the Calamity | only inside the last minutes before and during |
| Right edge, low | the signature's readout: a ring that fills, flashes when it fires | always, small |
| Bottom centre | the dock: Voidkin, Regalia, Base, Map, and one more at most | always |
| Over the world | damage numbers, the Breaker's progress above the machine, a worker's output above its bay | where they happen |

- **Damage numbers** are stroked and slanted so they read over any background: ivory for a plain hit, gold and larger with a mark for a critical, the element's colour and smaller for the second number, green for healing, grey for a dodge or a block. They rise from the body that was hit and never stack into a wall: a flurry merges into one counting number.
- **The type edge** shows on the target's card as a small arrow, up or down, before the first hit lands. The player learns the ring by seeing it, not by reading a chart.
- **A fallen lead** dims its card and shows the seconds until it's back.

## The screens of the first loop

Built first, in this order, each to the bar before the next.

1. **The HUD** above.
2. **The reveal.** Full screen, no chrome: the shard, the crack, the silhouette, the name, the rarity as the frame's shape. Then one card: type, class, element, signature, and what it's good at in a line. Skippable after the first second.
3. **The Breaker.** The chambers as they are in the world, each with its shard and time left; the waiting line beneath; the shard's odds one tap away; infusion as a clear choice with its price and its effect on the odds.
4. **Voidkin.** A grid of portraits, the frame showing rarity, a gem for type and an icon for class. Sort and filter by type, class, role. A long press compares two.
5. **One Voidkin.** The character large, turning. Name and nickname (rename beside favourite, lock and set as lead). Its stats, its signature and passive in plain words, its stars, its linked preset.
6. **Regalia.** The fourteen slots around a figure, each showing its item's icon and its forge rank, the two hands for the lead's class; Combat Power large above them. A tap opens the slot: the item, its sockets, what's in the bag for it, with the difference shown as plain up and down numbers and in Combat Power. Presets as tabs. Combat Power's moments: `docs/design.md`, "Combat Power".
7. **The base's bays.** Each bay with its worker, output and level; the battery; what the Breaker is drawing. Assign by dragging or by tap.
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
