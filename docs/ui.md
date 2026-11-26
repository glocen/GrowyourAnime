# The HUD and the screens

How the game's interface is laid out and how it behaves. Research's direction, 2026-11-11. The look of the kit (frames, icons, textures, effects) is the asset maker's, designed from this page (`docs/asset-requests.md`, AR3). The builder builds every screen from one component library.

The director, 2026-11-11: "we need to be even thoughtfull with the HUD".

**Status:** direction on paper. No screen is drawn or built. The package's mockups (`docs/archive/package-v13/`) are web pages in portrait with invented numbers: useful for what each screen must hold, not for how it looks. Roblox on a phone is landscape.

## The five rules

1. **Phone first, landscape.** Every screen is designed at phone size and grows to a desktop, never the other way. Touch targets are 44 px or more, text 14 px or more, and nothing sits under the thumbs' resting corners or the device's notch.
2. **Quiet until it matters.** In the world, the screen shows the fight. A number, a chip or a glow appears when something changed and leaves when it's read.
3. **One look, ours.** The HUD's text gets a face of its own [the director, 2026-11-15: "the whole main hud of the player need a refont"], from Roblox's font library, chosen at phone size (`docs/asset-requests.md`, AR12). Panels have chamfered, shard-cut corners. Bars read as conduits that fill with light. A rarity is the frame's shape and glow. **Words wear their meaning's colour** [the director, 2026-11-15: "the epic chance text should be purple, the battery text need a rework also like it energy colors"]: a rarity's name and its odds in the rarity's colour, power and the battery (kW, kWh) in Power's yellow, Credits in their teal, the rest ivory. A coloured word is never the only sign of a rarity. Four palettes from one kit [the director, 2026-11-12: some screens get a palette of their own; which is the asset maker's choice, and the whole must hold together]: Graphite Dark, the main one, for the field and the collection; Dynamo for the machine rooms (the bays, the Forge); the Breaker a room of its own with stars, never a literal galaxy's form, composed and slowly moving [D, 2026-11-15], its colours the asset maker's to choose, to be appealing [D, 2026-11-15, night: "something appealing, ART so creative freedom to cook something good"]; the void's room for the reveal, a neutral dark with a pale corona, so a rarity's light is the only colour in it (A, Eclipse, Modulo's pick, 2026-11-15: AR12); Pearl Light, drawn with a black border, for what's read like a page (the map, a shard's odds, a stat's sources). A palette changes a panel's body, edge and ink and the accent; never the cut, the frames, the gems and marks, or the colours that mean something. The screens of each: `docs/asset-requests.md`, AR3. **The asset maker has full creative freedom over the kit's look** [D, 2026-11-16: the package's point 7], AR3's palettes and AR12's Eclipse included: they stand until a direction the asset maker draws replaces them, a screen at a time, the inventory first (AR18). Mythical's light is reddish, never a rainbow [the director, 2026-11-12].
4. **The interface never lies.** No success animation plays before the server has said yes. A count-up shows the real change. A disabled button says why.
5. **Motion is premium** [D, 2026-11-19, 03:19: "the animation and ui vfx need to be premium and smooth and very appealing"]. Every screen and every press moves, and it is judged in motion on a phone capture, never from a still:
   - **Every press answers in the same frame:** it sinks (to about 0.94) and springs back with a little overshoot, with a sound and a haptic. Hover gets a glow.
   - **Screens arrive, they don't appear:** the Menu scales and fades in over the dimmed world, and its parts land in a short stagger. A tab switch slides its content a few pixels as it crossfades, and the tab's marker glides to it. Closing is quicker than opening.
   - **A payoff has three beats:** anticipation (the thing charges while the server answers), the hit (a flash, a burst, the number popping up as it counts), and settle. A failure is quieter but still felt (a crack, a dim, a small shake). Rule 4 holds: the hit waits for the server's yes.
   - **Rarity moves:** Epic and Legendary items carry a slow shine or a living edge. Lower rarities stay still.
   - **Light stays in its piece** [D, 2026-11-24, 13:37: "let not add those shiny bright effect that goes outside the ui buttons it can stay inside or very close to the border"]. A glow, a bloom or a shine lives inside its button, tile or band, or hugs its border, never spreading out over what's around it. Hover's glow too.
   - **Smooth means 60 fps on the smallest phone:** no layout pops, nothing new built per frame, and Reduced Motion turns moves into fades. The speeds live in `Config.Hud`'s Motion, tuned live. The engine facts: `handbook/visuals/ui.md`, "UI effects".

## Phone, tablet and desktop

[D, 2026-11-16: the package; research's design, `docs/research/rework-2026-11-16.md`, part 6.]
- **Detected, never asked.** The layout class comes from the viewport's size and the safe area; the input from the player's preferred input, changing live when they pick up another device.
- **Three layout classes from one kit:** compact, a phone in landscape, two panes with the item sheet over the figure; regular, a tablet, the same two panes wider, nothing overlaid; wide, a desktop, three columns (the figure with its slots, the stats, the bag), so nothing scrolls that needn't.
- **Input:** hover only with a mouse; with a gamepad a focus ring, the shoulder buttons step the tabs, A selects and B goes back; with touch, 44 px or more on every target and nothing under the thumbs' corners.
- **One library:** the same components take size tokens per class. Never a second set of screens.

## The HUD, in the world

| Where | What | When it shows |
|---|---|---|
| Top left | the lead's card [D, 2026-11-12, from a reference; its place may move]: the portrait in its rarity frame, the level on a badge on the frame; beside it a long health bar with current and maximum written inside, and a thinner experience bar beneath (its width and colour ours); name or nickname, type gem, class icon | always, small |
| Top centre | the target's card, built like the lead's: name above, type gem, health, a keeper's phases; beside the level its difficulty skull [D, 2026-11-19, by 11:30]: by the foe's CR against the lead, a faint grey skull much weaker, white about even, yellow stronger, red much stronger, and the level's text in its skull's colour. An elite's frame carries its own mark. Its look: AR45, for the Shade's and the elite's card; the keeper keeps TR5's purple bar [D, 2026-11-19, 12:24] | only in a fight |
| Top right | two pills: Credits, and Power: generation against demand in kW [D, 2026-11-14, night] (`docs/design.md`, "Power"), then the battery's reading after the battery's mark (research, TR41 (e), 2026-11-17). A tap opens the rest | always |
| Beside the signature's readout | the spectate toggle [D, 2026-11-14]: a small eye; on, the camera follows the lead. Its place is set at TR11's blockout | always, small |
| Under the pills | event chips: the Void Shop's countdown, the Rift, the Calamity | only inside the last minutes before and during |
| Top left, under the lead's card | the signature's readout: a ring that fills, flashes when it fires. It has stood here since AR12; TR52 measures its tap against both thumbs' controls, and research's verdict in motion says whether it moves (corrected 21:33, from Faber's fact) | always, small |
| Over the dock | the shards' hint, "65 shards: into the Breaker" | only at the base [D, 2026-11-15: "should only show when we are at the base"] |
| Bottom centre | the dock: Home, Base, Map, and one more at most [D, 2026-11-19, about 12:21: Menu is renamed Home; 03:19: Inventory was renamed Menu]. Home opens a composed panel of large cards, each with its own art and each opening one whole screen [D, 2026-11-19, 23:20, replacing about 12:21's grouped buttons]: **Voidkin** (the Voidkin screen: Overview, Kit, Inventory with the gear slots and the bag, Stars), **Equipment** (Reinforce, Jewels, War Emblems) and **Settings** (music, sound, effects). The pages are switched inside each screen (`docs/asset-requests.md`, AR49). **Today** (today's three goals, with Next pinned at the list's head) is the card quests were to take: it shares Settings' column, Settings a cog tile over it (research's pick, 2026-11-23, 17:49, tier 2; `docs/asset-requests.md`, AR53). Before 2026-11-19: Inventory [D, 2026-11-15: "Inventory"]. Each is an icon with no word, in one composed dock [D, 2026-11-15: "we could make a icon of it no need to name it inventory and make a ui around it, it need to be a very cool ui well composed"; Base and Map too, asked]; a long press shows its word. Inventory opens the Voidkin screen, which holds every Voidkin and the whole bag; Regalia's screen is merged into it [D, 2026-11-15]. Base takes the player home, and at home opens the base screen [D, 2026-11-15, night] | always |
| Over the world | damage numbers, the Breaker's progress above the machine, a worker's output above its bay | where they happen |

- **Damage numbers** [D, 2026-11-12, from a reference: `docs/research/hud-reference.md`] are outlined and widely spaced, with thousands separators, so they read over any background: a hit dealt pale ivory and upright; an element's second number the same, in its element's colour, a beat behind; damage your lead receives the same face in muted red, a size larger; healing as damage received, in green; a critical gold, heavy, slanted forward, larger, on a swept stroke of our own behind it; a dodge, a block or an absorb a short grey word on a pointer [D]: Absorb when a shield takes the hit whole, and the shield's bar loses what it took. They rise from the body that was hit and never stack into a wall: a flurry merges into one counting number.
- **Numbers, short or whole** [D, 2026-11-19, by 11:30]: Credits and kWh take the short form from 100K ("65K" is never shown for CR), and so do a health bar too narrow for its digits and a leaderboard (`Rules.Hud.Short`: three figures, cut, never rounded up). CR, damage numbers under 1M and every price stay whole, with thousands separators, so every upgrade moves the number a player chases.
- **CR's look** [D, 2026-11-19, by 11:30, replacing AR23's Shard light]: "CR" on a small slanted gold tab, the number beside it in pale ivory, in the damage numbers' digits (AR44). Its look: AR45.
- **The type edge** shows on the target's card as a small arrow, up or down, before the first hit lands. The player learns the ring by seeing it, not by reading a chart.
- **A fallen lead** dims its card and shows it's healing at home, with the time left, then that it's training (`docs/design.md`, "A fall sends it home").

## The screens of the first loop

Built first, in this order, each to the bar before the next.

1. **The HUD** above.
2. **The reveal.** Full screen, no chrome: the shard, the crack, the silhouette, the name, the rarity as the frame's shape. Then one card: type, class, element, signature, what it's good at in a line, and how far the copies have taken it. One tap ends it, from 0.4 s once three have been seen (TR70).
3. **The Breaker.** The chambers as they are in the world, each with its shard and time left; the waiting line beneath; the shard's **Drop rates** one tap away [D, 2026-11-15: "drop rate is that simple"]: every Voidkin it can give with its chance, grouped under each rarity's total, adding to 100%; voltage as a clear choice with its price in kWh and the time it saves.
4. **Voidkin.** A grid of portraits, the frame showing rarity, a gem for type and an icon for class. Sort and filter by type, class, role. A long press compares two.
5. **One Voidkin, the character screen** [D, 2026-11-15: Regalia merged into it; its layout is `docs/test-requests.md`, TR17]. Full screen. The selected Voidkin large and turning. **On Items only,** it stands between its linked preset's slots, each with its item's icon and its Reinforce level, the two hands at its feet beside Combat Power. Every other page shows no slots, with Combat Power alone under the figure [D, 2026-11-17, by 13:03: "overview ui shouldn't show any gears slot"]. A rail on the left holds every page: Overview (name, nickname, rarity, type, class, element, level, and the whole stat sheet: every stat, shown below), Items (the bag), Kit, Stars, Forge, Jewels, War Emblems. The bag is the right panel, the player's whole inventory. Presets as tabs. Combat Power reads "CR" on every screen (`docs/design.md`, "Combat Power"). Combat Power's moments: `docs/design.md`, "Combat Power".
   - **Overview's stat sheet** [D, 2026-11-15, 19:13: "the overview need to show all the stats"; its order, D, 2026-11-16: the package's point 3]: every stat in `docs/balance.md`, "The stats", and Poise. A stat at zero shows 0, never hidden.
     - **The header:** name, class, level and its bar. Combat Power stays at the feet.
     - **Basic Attributes:** the five in one row or two, each with its total, the class's Main marked with a small tag.
     - **Battle Attributes,** in three blocks. **Core:** Health, Attack, Defence, Speed, Poise. **Offence | Defence, paired on each row,** so what counters what reads without a word: Hit | Dodge, Critical | Critical Resist, Critical Damage | Critical Immunity, Elemental Attack | Elemental Resist, Damage Bonus | Damage Reduction, Penetration | Block. **Sustain:** Regen | Lifesteal, one question now that the Tower carries health.
     - **A plain list** [D, 2026-11-15, night: "dont put any description for stats", then "Plain list, no taps"]: each stat its name and its total, never "up to", and nothing opens. One caption under the heading, "chances against an even foe", and no other words.
     - **How each number is written:** points as the number. A rating shows only its percent against an even foe, with no points and no words after it [D, 2026-11-17]: Hit, Dodge, Critical and Block their chance ("Critical 9.8%"), Penetration, Critical Resist and Elemental Resist their effect ("Critical Resist 5.1%"). A percent stat shows as its percent. No chance reads over 100%.
     - **The even foe** is a Voidkin of the viewer's level on the on-budget build, its ratings in `Config.Stats`, and every chance comes from the function the hit uses (`Stats.Chance`), so the sheet can't drift from the fight. Damage Bonus and Damage Reduction show only what holds at all times.
     - **Numbers:** thousands separators, no decimals on points, one decimal on a percent under 10%, none above. A change too fine for a tenth reads to a hundredth, then "<0.01%", so a real gain never reads as none (Faber, tier 1, 2026-11-17). After an equip, each changed row shows its gain in green for a moment. On a phone the sheet scrolls in one column, its blocks' headings pinned.
   - **An item's card** [D, 2026-11-15, 19:11]: a tap on an item, in a slot or in the bag, opens its card.
     - Its name is the title. Right under it stands the Combat Power it gives the selected Voidkin: Combat Power with it, minus without it (`Rules.Stats.Power`).
     - Then its details: its main stat, its other stats, its forge rank, its sockets.
     - Opened from a slot, the card also lists what's in the bag for that slot, with the difference as plain up and down numbers and in Combat Power.
     - **The comparison** sets it against what's worn, in two columns: the Basic Attribute changes, then the Battle Attribute changes, then Combat Power's, gains green and losses red, all from the one resolver run twice. Equip sits at the right thumb. A weapon of another class reads "Warrior only", for instance, and its Equip is off with that reason.
     - **Its trade in one line** [the outside review's item 7, D, 2026-11-25, 21:41; research's words, tier 1], over the two columns: the Battle Attribute that gains the most and the one that loses the most, each weighed by what it moves Combat Power (the resolver's run, as the columns): "More Health · Less Attack". With only gains, the two biggest ("More Health · More Critical"); with only losses, the two biggest ("Less Attack · Less Hit"); with nothing changing, no line. "More" in the gains' green and "Less" in the losses' red, each name as the sheet writes it.
   - **Lead and Station say what they cost** [the outside review's item 6, D, 2026-11-25, 21:41; research's words, tier 1], on the line under the press, wherever a Voidkin is offered as the lead or for a bay:
     - Lead, on a worker: "Leaves Bay 2 · −18 kW", the kW its bay makes now, the number in the losses' red.
     - Station, on a resting Voidkin: "Bay 3 · +12 kW", what it would make there, the number in the gains' green.
     - Recall: "Bay 2 · −18 kW".
     - The HUD's power pill shows the base after the press, so the line names only the change.
   - **The bag** [the package's inventory, 2026-11-16; its look is the asset maker's, AR18]: one frame level, never a frame in a frame, panels parted by tone and space. The Voidkin and its slots stand on the left and the grid on the right [D, 2026-11-16, by 23:24]. An item's card opens at the room's right edge and closes back, with Equip under the right thumb; on a phone it covers the grid's end while it's open. Cells about 64 px, 5 or 6 across, the icon filling most of the cell, rarity on the cell's edge and a corner mark, never a full fill. An item that would raise Combat Power carries the up arrow; one the selected Voidkin's class can't wear is dimmed with its class's mark. Icon tabs over the grid (All, Gear, Jewelry, Chests, Materials [D, 2026-11-17, 13:00 to 13:03: weapons and armor merged as Gear, American spelling]), each 44 px or more, and one sort (Rarity, Power, New). An empty bag says where items come from.
6. *(Merged into 5, 2026-11-15.)*
7. **The base screen** [D, 2026-11-15, night: "when they are inside they can click on it and it opena control tab like a really intuitive/exciting ui showing everything like their whole base and can upgrade with credits"]. At home, the dock's Base tile opens it. Away from home, the tile takes the player home (TR19). Its block is `docs/test-requests.md`, TR21.
   - **The command view:** the camera lifts over the player's own base and looks down on all of it, so the world itself is the screen. Every machine and bay wears a chip: its name, its level, and what it's doing now (a worker's output, the Breaker's time left, the battery's charge).
   - **A tap on a chip** opens its panel at the side: what it does, its level, the next level's gain in plain numbers, the price, and Upgrade. A bay's panel also assigns its worker, by tap.
   - **The base's own level** stands at the top: what the next level opens, its price, and Upgrade. When an upgrade lands, the camera holds on the change as it builds in below.
   - **Power** is a tab of the same screen: generation and demand, one bar split among the machines by its handles, +/- on each share, Auto, and the battery in kWh (`docs/design.md`, "Power"). The generator opens the screen on this tab.
   - **Closing** brings the camera back behind the lead.
8. **The map.** The six grounds as a festival route, the keeper's gate on each, what each ground's shards hold.
9. **Shared pieces:** confirm, error, toast, reward, empty state.

Everything else (the Forge, the Condenser, the Lab, the Void Shop, the Tower, the Clash, the Calamity, settings) is built on the same kit when its system is built.

## Every component has these states

Rest, pressed, selected, disabled with its reason, waiting on the server, succeeded, failed. A screen is reviewed with empty, full and long-name content, in both themes, at phone size.

## Stats, shown honestly

- The stat sheet lists every stat as one total, the sum of its sources, never "up to" [D, 2026-11-15, night]: a chance or a share as its percent, any other stat as its number [D, 2026-11-17].
- On the Voidkin screen, the sheet is a plain list and nothing opens [D, 2026-11-15, night: "Plain list, no taps"]: no notes and no sources. Every Battle Attribute that's a chance or a share shows its percent only, with no points beside it [D, 2026-11-17, by 00:17, correcting 2026-11-16, 21:32]. Hit, Dodge, Critical and Block show their chance against an even foe; Penetration, Critical Resist and Elemental Resist show what they do to an even foe, as a percent with no words after it. The percent stats show as they are, and Attack, Defence, Health, Elemental Attack, Speed and Regen stay numbers. What each source gives shows in Combat Power's tap, whose parts sum to its total (`docs/design.md`, "Combat Power").
- An item's comparison never shows a percent of a percent.

## Nicknames

About twenty characters, passed through Roblox's text filter before anyone else can see it, shown with the real name beneath on the detail screen (`docs/roblox-rules.md`).

## Words players read

The director has rejected generated-sounding lines five times ("corny", "ai slop"; `docs/decisions.md`, 11-17 to 11-26). Every line players read follows this. The craft and its sources: `docs/research/cloud-2026-11-24/voice-and-naming.md`, sections 2 and 5.
- **Plain, dry, concrete.** Real words used exactly ("High voltage"), a straight face a little older than the player, one thing you can see or do ("Stand outside every slam.").
- **Ask before it ships:** would a 13-year-old say every word of it to a friend? If not, rewrite it.
- **Never:** a riddle for a fact ("Nothing waits."); a qualifier tacked on after a comma ("…, this server's best today"); a colon meaning "so" ("Stationed: recall it first"); a machine with feelings ("wakes", "has moved on"); "foe", hype words, puns, lists of three, exclamation marks.
- **A refusal says the fix:** "Take it off first", never "That can't be done".
- **One word for one thing:** base, never home (the dock's Home is a button, not a place); enemy, never foe; bag, never Inventory; keeper, never boss; "Empty" for every empty slot.
- **Lengths:** a button 1 or 2 words; a toast or refusal about 6; a tip or goal about 8, one sentence.

## Reviews

Each screen starts from a target the director picked, and is judged beside it on a real phone-sized capture (`/ga-review`, in pairs). The director's word accepts it (`AGENTS.md`, "target first, verdicts in pairs"). The UI lint (clipping, overlap, touch sizes, safe areas) runs before either.
