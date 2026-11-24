# The details pass: what a premium game ships inside each system, and what ours has

A cloud research agent for Faber, 2026-11-24, read-only on main. It answers the director's words of 11-24: "the small details that comes with big systems specific to our visions ... the synchronization and holes details filed ... just to make it 1 whole premium game ... it just good to learn from the best". Depth inside each system only. How systems marry is `systems-that-marry.md`; the resource map is `systems-map.md`; transitions, interruptions and empty or full states are `seams-and-states.md`; the shared feedback language is `orchestration.md`.

Labels: SOURCED (link), COMMUNITY (wiki or Wikipedia, link), OBSERVED (our repo, path under main), MEASURED (counted here), OPINION. **RECALLED** marks a feature I know from the named game but could not fetch today: treat it as OPINION until checked. The session's search budget was spent and most game wikis refused the fetch (list at the end), so the outside lists lean on RECALLED more than I'd like. Every proposal is a proposal. Costs are seeds.

## Verdict

1. **MEASURED: 74 of 139 details are in the build (53%), 21 partly, 39 missing, 2 wrong, 3 don't apply.** The fight HUD, the shop and the Breaker's honesty (odds, prices, reasons on every disabled press) are at the level of the best. The base, the gear screens and the fight's "am I in danger" reads are the thinnest.
2. **The largest hole is not small: no screen has a press that upgrades the base or a machine.** The rule and its logic cases exist (`Rules.Base.UpgradeBase`, `UpgradeMachine`); the client never calls them. The Breaker's own words tell the player to "Upgrade the Breaker". OBSERVED.
3. **The paper promises nine details the code doesn't have:** the equip transfer's question, the chest summary, an item lock, the "better item waiting" dot, CR's breakdown, comparing two Voidkin, reordering the Breaker's line, the Tower floor's recommended CR, and a favourite that sorts first. A detail written and not built is worse than one never written: reviews pass against the doc.
4. **Most of the top 30 are under an hour each and provable by a self-test or a logic case.** They are finish work on systems that exist, so they fit a scope freeze (`README.md`, item 2). Do the ones on the first ten minutes' path first.
5. **Twelve details only our game can have** are at the end. Three of them (the Breaker's hum, the workers' glance, the lights following the battery) cost about half a day together and carry pillar 3 further than any new system would.

## What counts as a detail, and why players notice

- **SOURCED.** Liz England's "door problem": one door raises dozens of questions ("How does the player know the difference?", "What tells a player a door is locked and will open?"), and "SOMEONE has to solve" each. [Essay](https://lizengland.com/blog/2014/04/the-door-problem/). **For us:** every row below is one of those questions asked of a system we already built. The audit is the method; rerun it per system at its finish.
- **COMMUNITY.** Rockstar's team on Red Dead Redemption 2: camp members were given chores, activities and waking hours, and the aim was a world "feeling natural or organic in every respect". [Wikipedia](https://en.wikipedia.org/wiki/Development_of_Red_Dead_Redemption_2). **For us:** a detail is noticed when the world answers the player without being asked. That's the test for the twelve at the end.
- **SOURCED.** Roblox's paid-random-items rule is a detail checklist in itself: every outcome with its numerical odds, visible before the buy, behind a control with a word on it (a bare "(i)" isn't enough); a one-per-player outcome must show that player's remaining odds; a pity system must be "numerically explained". [Roblox](https://create.roblox.com/docs/production/monetization/paid-random-items). Apple asks the same disclosure "prior to purchase". [Apple 3.1.1](https://developer.apple.com/app-store/review/guidelines/). **For us:** "Drop rates" already passes. The rule's personal-odds line is the model for showing what the player owns in that list (top 30, item 5).
- **SOURCED.** The Last of Us Part II shipped "more than 60 accessibility settings" with three presets, HUD scale, colour-blind palettes for HUD accents and a shake slider. [Naughty Dog](https://www.naughtydog.com/blog/the_last_of_us_part_ii_accessibility_features_detailed). The basic tier of the Game Accessibility Guidelines asks for separate volume controls, a haptics toggle, remapping, settings remembered and no information by colour alone. [Guidelines](https://gameaccessibilityguidelines.com/full-list/). Xbox's guideline asks that text scale to 200% without loss. [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101). **For us:** we have three sliders. On Roblox the platform owns Text Size and Reduced Motion; we read the second and ignore the first.
- **SOURCED.** Duolingo measured small touches: a second streak freeze raised daily actives by 0.38%, and a new streak animation raised day-7 retention of new learners by 1.7%. [Duolingo](https://blog.duolingo.com/how-duolingo-streak-builds-habit/). **For us:** forgiveness and a payoff beat are worth measuring like features. Our three-day bank is the right call.
- **SOURCED.** The FTC's Fortnite order: charges from "the press of a single button", including while "attempting simply to preview an item"; $245 million. [FTC](https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations). **For us:** Preview and Buy never share a press, and a confirm stands before anything bought with a sold currency.
- **SOURCED.** Roblox's notifications are opt-in, 13 and over, one a day per experience, need 100 visits, and a game may not require them. [Roblox](https://create.roblox.com/docs/production/promotion/experience-notifications). **For us:** not now (the game isn't public). `retention-and-discovery.md` owns it.
- **COMMUNITY.** Palworld's Monitoring Stand grew over four patches: work intensity, then a relax option, then allowed work types, then fixed assignment. [wiki.gg](https://palworld.wiki.gg/wiki/Monitoring_Stand). Fallout Shelter raises a mark when a room has produced, and its rush shows a risk. [Wikipedia](https://en.wikipedia.org/wiki/Fallout_Shelter). **For us:** workers default to automatic and players then ask for control. We have the control and no automatic.
- **COMMUNITY.** Hard pity works as "an effective price ceiling". [Wikipedia](https://en.wikipedia.org/wiki/Gacha_game). Pokémon TCG Pocket turns every pack into points toward a chosen card, and reviewers praised the opening itself. [Wikipedia](https://en.wikipedia.org/wiki/Pok%C3%A9mon_Trading_Card_Game_Pocket). Marvel Snap makes the cosmetic upgrade of a card the progress track. [Wikipedia](https://en.wikipedia.org/wiki/Marvel_Snap). **For us:** all three are "a duplicate is never nothing"; `collection-and-economy.md` and `reveal-and-showcase.md` own that.

## The audit, system by system

Paths are under main's `src/`. Each block: what the best ship (RECALLED unless a link stands above), what we have, then the gaps. "Not found" means I searched and can't prove absence.

### A. The Breaker screen and the reveal: 9 of 16

**Outside (RECALLED: Genshin, Pokémon TCG Pocket, Pet Simulator 99, Anime Vanguards):** a rates page, a history log, "new" tags, duplicates explained before the roll, open-many, skip, a shown pity count, an index with completion rewards, a model you can turn.
**HAVE (OBSERVED):** Drop rates one tap away, per Voidkin under each rarity's total (`client/UI/BreakerScreen.luau`, `chances`; `Rules/Odds.luau`). Skip from 1.0 s (`UI/Reveal/init.luau`). New, copy and sold said on the plate (`UI/Reveal/Plate.luau`). Time left per chamber as a clock. A ready shard calls from outside the screen (`Rules.Hud.NextStep`; the Base cell's pip, `HudController.luau:563`). Voltage shows its price and the time saved, and says why when it's off. Rarity shows before the name. The reveal's end replays from the Voidkin screen. A locked chamber says what opens it.

| Gap | State | Note |
|---|---|---|
| The rates list marks who you own, with stars and copies | MISSING | `chances` prints a name and a percent |
| Break all, a fast form for copies | MISSING | `on.Open(index)`, one at a time. Owned by `reveal-and-showcase.md` |
| A log of recent reveals | MISSING | no field in `shared/Data/Profile.luau` |
| Luck or pity shown | PARTLY | a shard's luck reads on its line; no pity exists. `collection-and-economy.md` |
| Reorder the waiting line | MISSING | `docs/design.md` says "unless the player reorders it"; only AddShard and TakeOut exist |
| Put every shard in at once | MISSING | "Put it in", one press a shard |
| An index of every Voidkin | MISSING | owned by `collection-and-economy.md` |

### B. The Voidkin screen and roster: 7 of 13

**Outside (RECALLED: Genshin, Honkai, AFK Journey):** a turntable, favourite and lock, sort and filter remembered, compare, a preview before every upgrade, a marker on anything new, where each character comes from.
**HAVE (OBSERVED):** drag to turn and flick to the next (`UI/VoidkinScreen/Figure.luau`). Lock and rename with the text filter. The next star's gain shown before it's taken (`VoidkinScreen/init.luau:900`). Signature and passive in words on Kit. Lead and Send to work say why when off. The stat sheet from the fight's own functions.

| Gap | State | Note |
|---|---|---|
| A favourite sorts first | WRONG | `Rules/Collection.luau:136` says it does; `UI/Read.luau`, `Read.Roster`, sorts lead, level, name |
| CR's tap shows each source | PARTLY | the tap opens Overview; no parts that sum (`docs/design.md`, "Honest") |
| Compare two Voidkin | MISSING | `docs/ui.md`, screen 4: "A long press compares two" |
| A mark on a new Voidkin, or one with a star ready | MISSING | not found on the portrait strip |
| Where it comes from (its ground, its shard) | MISSING | not found |
| Sort and filter | MISSING | low value at five Voidkin; build at about twelve |

### C. The fight HUD: 10 of 17

**Outside (RECALLED: Xenoblade 3, Honkai: Star Rail, AFK-style games; COMMUNITY for Xenoblade's positional arts and auto-attack radius, [Wikipedia](https://en.wikipedia.org/wiki/Xenoblade_Chronicles_3)):** a target marker, off-screen arrows, damage number rules, cooldown reads, a low-health warning, a target override, enemy tells, state icons, a recap.
**HAVE (OBSERVED):** the lead's card with health in digits, experience and level (`UI/LeadCard.luau`). The target's card with level, difficulty skull and the type edge's arrow (`UI/TargetCard.luau`). Damage numbers that merge a flurry, with their own critical, received, heal and word styles (`FighterController/Effects.luau:1785`; 28 checks in `NumberCases`). The signature's ring, white-hot when ready (`UI/Readout.luau`). Tells in the world: the slam's ring filling, the Dasher's lane, the Guard's pane (`SlamController.luau`). The keeper's bar with its trail and stamp (`UI/BossBar.luau`). The next lead offered after a fall. Spectate. One level-up notice. An effects and shake slider.

| Gap | State | Note |
|---|---|---|
| A mark under the Shade the lead is on | MISSING | the card says who; the world doesn't |
| A low-health warning | MISSING | no low state in `LeadCard.luau` or `HudController.luau` |
| An arrow to the lead when it's off the frame | PARTLY | `UI/Guide.luau` has the edge arrow, for the next step only |
| Choosing the target | PARTLY | by standing only. Owned by `combat-agency.md` |
| The poise bar on an elite and a keeper | MISSING | designed (`docs/design.md`, "States in a fight"); poise is only in `Rules/Stats.luau` |
| State marks on the cards (burn, chill) | MISSING | waits for the states |
| A recap of the fight | MISSING | see D |

### D. The stage picker and the run's card: 7 of 12

**HAVE (OBSERVED, `UI/StageScreen.luau`, `StageController.luau`):** recommended CR beside yours. Hard's lock and why. The checkpoint ("Your next run starts at Stretch 3 of 4"). The run's line with a notch a Shade. Time and a new best. Credits, chests, shards and dares kept. Retry, Hard and Home with one lit.

| Gap | State | Note |
|---|---|---|
| What the run can give, before entering | MISSING | `Rules.Drops.Card` exists and feeds the elite's world card only |
| The lead's experience gained on the card | MISSING | no experience field in the results |
| After a fall: why, and one press toward the fix | MISSING | "Your lead fell" and where the next run starts |
| Three numbers of recap: biggest hit, signatures landed, damage taken | MISSING | RECALLED: AFK-style battle statistics |
| First clear marked apart from a repeat | PARTLY | "Hard is open" has its band; the first-win chest has no mark |

### E. The base: view, bays, battery, machines: 7 of 15

**Outside (COMMUNITY above; RECALLED: idle games' offline card and collect-all):** collect-all, timers as time, opt-in notices, auto-assign and best-fit hints, capacity warnings, before-and-after upgrade previews, an offline report, free speed-ups, visual stages.
**HAVE (OBSERVED):** the command view with a live chip on every machine (`UI/BaseView.luau`, a grey blockout). The Condenser's tray in one press (`CollectTray`). Time left on the plates. Voltage as the free speed-up. Power on Auto by default with a split by hand, and the battery as hours of work (`UI/PowerScreen.luau`). The showcase (`SetShowcase`).

| Gap | State | Note |
|---|---|---|
| Upgrade, with before and after | PARTLY | the level's line shows gains and price (`BaseView.luau:210`); **no client press calls UpgradeBase or UpgradeMachine** |
| The bay picker leads with the best fit | PARTLY | each row shows "Lv N · kW" (`BaseController.luau:443`), in roster order, no gain against the worker there |
| Fill the bays in one press | MISSING | |
| Capacity warnings | PARTLY | "Tray full" lights its plate; the bag says so only at a refusal; a full battery is silent |
| What happened while away | MISSING | the server works it out at join; no card shows it. See `seams-and-states.md` |
| Workers visibly working | PARTLY | the rig's Idle, looped (`BaseController.luau:1279`); no work clip |
| Machine stages in the world | PARTLY | designed; not checked in a place |
| Opt-in notifications | N/A | not public |

### F. Equipment, the bag, Reinforce, Emblems, jewels, chests: 8 of 19

**Outside (RECALLED: Diablo IV, Destiny 2, mobile ARPGs):** a compare card with deltas, equip-best, lock and junk marks, salvage-all by rarity with a confirm, a preview and cost before commit, loadouts, new-item marks, sort memory.
**HAVE (OBSERVED):** the item's card against what's worn, every change in green or red with CR (`UI/VoidkinScreen/Bag.luau`; `Rules/Bag.luau`, `Card`). The up arrow on a better item. Salvage in two taps, the second showing what it gives. The count under the grid, and how to free a slot when full. Reinforce: level now and after, odds adding to 100, cost, one press, and a reason on every off state (`EquipmentScreen/Reinforce.luau`). Emblems in and out for free. A chest's odds on its card.

| Gap | State | Note |
|---|---|---|
| The equip transfer's question | MISSING | the director's words of 11-17; `Rules/Regalia.luau:88` has `Transfer`; no asking UI found in `Bag.luau` |
| The chest summary | WRONG | a toast, "Opened 50: 41 kept, 9 salvaged" (`Bag.luau:855`); the design asks a summary by rarity and an Epic's own reveal |
| An item lock | MISSING | `docs/design.md`, "The bag": "a lock on anything precious" |
| A dot where a better item waits | MISSING | `docs/design.md`, "The pull" |
| A mark on new items | MISSING | "New" is a sort only |
| Sort remembered | PARTLY | `Bag.Reset()` goes back to All and Rarity |
| Salvage many at once | PARTLY | auto-salvage on opening (`SetSalvage`); nothing for items already held |
| Presets as tabs | PARTLY | the save has them; Overview reads "Gear · preset N" |
| Jewels | PARTLY | five empty slots marked as coming |
| Equip-best | MISSING | OPINION: leave it out. Pillar 2 says the build is the game; the up arrow is enough |
| Fail protection on Reinforce | N/A | the director's "no pity". `collection-and-economy.md` argues it |

### G. The Void Shop: 8 of 11

**HAVE (OBSERVED, `UI/ShopScreen.luau`, `ShopController.luau`):** the stock's clock. A limit per player, "None left for you this stock". "Need N more". Drop rates before the buy. The featured piece's stats. "No Tank yet. Buy anyway?" on a second press. How often a featured stock comes. A countdown chip under the pills.

| Gap | State | Note |
|---|---|---|
| Can't afford: where to earn it | MISSING | RECALLED: Genshin's source links |
| Rates mark who you own | MISSING | as A |
| A confirm on every buy | N/A | earned Credits only; due the day anything is sold |

### H. Goals: the dare, today's three: 5 of 10

**HAVE (OBSERVED, `UI/TodayList.luau`, `UI/DareLine.luau`):** rows that are open, done or claimed, the claim the server's. A count on a counting goal. A bank of three days (`Config/Goals.luau`). The Today card's gold rim when a claim waits. "Dare kept" on the run's card.

| Gap | State | Note |
|---|---|---|
| Claim all | MISSING | up to nine rows can wait |
| When the next three come | MISSING | in the list only; the design keeps timers off the HUD |
| Progress where it happens | PARTLY | the dare shows in the run; a today's goal ticks unseen |
| A press that takes you there | PARTLY | Next has the world's chevron (`UI/Guide.luau`); a today's row has no press |
| Swap one goal | MISSING | low; not at launch |

### I. The Tower: 6 of 10

**Outside (RECALLED: Spiral Abyss, AFK-style towers, Anime Vanguards' infinite mode):** a best mark, the next floor's line-up, checkpoints, quick retry, a board with your neighbours, the reward ahead.
**HAVE (OBSERVED, `TowerController.luau`, `UI/TowerScreen.luau`, `Config/Tower.luau`):** "Floor N · best M". Fast floors in place of checkpoints. Retry. Results with the record. The heal cap's note. Results shown once after a disconnect.

| Gap | State | Note |
|---|---|---|
| The next foe, before it lands | MISSING | 2.5 s of rise with nothing to read |
| The floor's recommended CR | MISSING | `docs/design.md`, "The pull" |
| The reward ahead | MISSING | the first-time bonus and floor 5's sure chest are never announced |
| Your neighbours on the board | PARTLY | the top rows and your own |

### J. Home, the dock, onboarding, settings and accessibility: 7 of 16

**HAVE (OBSERVED):** the dock's long-press names, refusals said and a pip (`UI/Dock.luau`). The next step's chip, the world's chevron and the edge arrow (`UI/Guide.luau`). No forced tutorial. Music, Sound and Effects, saved on the profile so they follow the player (`Rules/Settings.luau`). Reduced Motion read from Roblox in six or more files. The top bar's inset (`UI/Layers.luau`; `UiLint`).

| Gap | State | Note |
|---|---|---|
| Marks on Home's cards | PARTLY | Today only; none for a better item or a ready star |
| The player's Text Size | MISSING | `PreferredTextSize` is read nowhere. `devforum-ui.md`, tip 16 |
| Colour-blind safety | PARTLY | the rule is written; `ui-colour-review.md` measured the failures |
| Gamepad and keys | PARTLY | a pad's ring (`Kit/Hover.luau`), R and Y for Recall; `docs/ui.md`'s shoulder buttons and B aren't found |
| A haptics toggle | PARTLY | presses buzz (`Kit/Button.luau`); no off |
| A help page (the type ring, classes, states) | MISSING | must not undo "Plain list, no taps" on the stat sheet |
| A left-handed HUD | MISSING | low |
| A reconnect message | MISSING | not found. `seams-and-states.md` |
| A feedback button | MISSING | N/A until outside players |

## The score

| | A Breaker | B Voidkin | C HUD | D Stage | E Base | F Gear | G Shop | H Goals | I Tower | J Home | **All** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Have | 9 of 16 | 7 of 13 | 10 of 17 | 7 of 12 | 7 of 15 | 8 of 19 | 8 of 11 | 5 of 10 | 6 of 10 | 7 of 16 | **74 of 139** |
| Partly | 1 | 1 | 2 | 1 | 5 | 4 | 0 | 2 | 1 | 4 | **21** |
| Missing | 6 | 4 | 5 | 4 | 2 | 5 | 2 | 3 | 3 | 5 | **39** |
| Wrong | 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | **2** |
| N/A | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | **3** |

MEASURED from the rows above. The lists are mine, so the percentages compare our systems with each other, not with another game.

## The top 30, by value per hour

S: under an hour. M: a few hours. L: a day or more. T: provable by a self-test or a logic case. All the builder's unless said. OPINION on the order.

| # | Detail | Sys | Why a player notices | Cheapest build | Cost | T |
|---|---|---|---|---|---|---|
| 1 | The Upgrade press, with before and after | E | The Build beat and Next ("Raise the base to level 2") have no button | A chip's tap opens a side panel in `UI/BaseView.luau`: gains, price, Upgrade calling the existing acts | M | T |
| 2 | A favourite sorts first | B | They starred it and nothing moved | One comparison in `UI/Read.luau`, `Read.Roster` | S | T |
| 3 | A low-health pulse | C | In an automatic fight, "leave now" is the one decision | Under 30%, the health light breathes and one soft cue plays once; steady under Reduced Motion. `UI/LeadCard.luau`. Research's feel line | S | T |
| 4 | The fall card says why | D | "Your lead fell" teaches nothing | One line, "Recommended 1,240 CR · yours 980", and a press that opens Equipment. `UI/StageScreen.luau` | S | T |
| 5 | Drop rates mark who you own | A, G | It answers "what's left for me" before the break | After a name in `chances`, the stars and copies ("★2 · 1 of 4"), or "New" | S | T |
| 6 | The equip transfer's question | F | A +7 left behind on the old sword reads as a bug | A two-press confirm in `VoidkinScreen/Bag.luau` passing the rule's move flag | M | T |
| 7 | The bay picker leads with the best | E | Nobody should do sums to staff a bay | Sort by `Power.Output`, tag the top row, show the gain against the worker there. `BaseController.luau`, `bayRows` | S | T |
| 8 | The chest summary | F | Fifty chests end in one line of toast | A card of cells by rarity, the rare ones lit, in `Bag.luau` | M | T |
| 9 | Experience on the run's card | D | The lead grew and the card doesn't say | One field in the results; a bar that fills on the card | S-M | T |
| 10 | Marks on Home's cards | J | The player shouldn't open three screens to find one upgrade | A dot on Equipment when any up arrow exists, on Voidkin when a star is ready. `UI/HomePanel.luau`, `Rules/Bag.luau` | S-M | T |
| 11 | A ring under the lead's target | C | In a pack of five, which one is mine | A thin ring in the lead's type colour, beside `SlamController.luau`'s adornments | S-M | T |
| 12 | Claim all, and when the next three come | H | Nine claims is nine presses; "is it tomorrow yet" has no answer | A press over the list when two or more wait; one quiet line under it. `UI/TodayList.luau` | S | T |
| 13 | While you were away | E | It proves pillar 3 at every join | One card from the server's own catch-up: shards broken, kWh stored, stones made, levels trained | M | T |
| 14 | The next foe, in the Tower's rise | I | 2.5 s of nothing becomes a decision | A small card: portrait, level, the type arrow, the floor's CR. `TowerController.luau` | M | T |
| 15 | An item lock | F | One slip salvages the best ring | A flag on the item; salvage and auto-salvage refuse it. `Rules/Bag.luau`, the card | S-M | T |
| 16 | Recent reveals | A | "Did I get Lyric yesterday?" It's trust | The last 20 in the profile; a page in the Breaker's pane | S-M | T |
| 17 | Can't afford: where to earn | G, F | A dead button is the end of a session | Under "Need N more": "Lantern Row pays about N a run". `UI/ShopScreen.luau`, Reinforce | S | T |
| 18 | The bag remembers its tab and sort | F | Re-picking Power every open | Keep `kind` and `sort` across opens in `Bag.luau` | S | T |
| 19 | A dot on new items | F | What dropped in that run? | Items gained since the bag last closed carry a dot until tapped | S-M | T |
| 20 | The reward ahead in the Tower | I | A climb needs a next rung | "First-time bonus from floor 24" by the floor's line | S | T |
| 21 | Fill the bays | E | Four bays, four trips through a list | A pure rule picks the best free Voidkin per bay; one press in the base's rows | S-M | T |
| 22 | What a run can give | D | The reason to press Hard | A row on the Arc panel from `Rules.Drops.Card` | S-M | T |
| 23 | An arrow to the lead off the frame | C | The camera is the player's, so the lead gets lost | `UI/Guide.luau`'s edge arrow, in the lead's colour, only in a fight | S | T |
| 24 | Three numbers of recap | D | Two players compare builds (north star) | Biggest hit, signatures landed, damage taken, counted by the server | M | T |
| 25 | Reorder the line, put all in | A | The design already promised the first | Two acts in `Rules/Breaker.luau`; arrows on a chip | S-M | T |
| 26 | CR's parts on a tap | B | "It never lies" needs showing | A small sheet: level, stars, gear, Reinforce, emblems, summing to the total | M | T |
| 27 | Honour the player's Text Size | J | A setting they made that we ignore | Read `PreferredTextSize` in the kit's text. `devforum-ui.md`, tip 16 | M | T |
| 28 | Neighbours on the Tower's board | I | Rank 212 only matters next to 211 | Two rows above and below in the server's answer | S-M | T |
| 29 | Gamepad tabs and back | J | `docs/ui.md` says it's there | Shoulder buttons step the rail, B backs. `devforum-ui.md`, tip 34 | S-M | T |
| 30 | A haptics toggle | J | A basic-tier accessibility line | A fourth row in `UI/SettingsScreen.luau` | S | T |

Left out on purpose: equip-best (it plays the build for the player), a reroll for goals (not at launch by the director's word), presets as tabs and the poise bar (each is a piece, not a detail).

## Twelve details only our game can have

Original, inside the rules, no gore, our own assets. Costs are seeds. Every line of words goes through research and the content check. OPINION throughout.

| # | The detail | Pillar | Cost |
|---|---|---|---|
| 1 | **The workers glance up.** When the lead walks in at the gate, each worker turns its head and chest toward it for a second, then goes back to work. One shared clip per rig. | 3, 1 | Modulo S, builder S |
| 2 | **The Breaker's hum climbs.** One looped library hum per working chamber, its pitch rising from 0.9 to 1.25 with the crack's progress, then 0.3 s of silence before "Ready". No machine has a looped sound today (OBSERVED). `audio-direction.md` picks the sound. | 3, 4 | S |
| 3 | **The lights follow the battery.** The battery's cells already light by charge (`LightingController.luau:216`). Extend it: gate and bay lamps dim in three steps under 25%, and at empty the Breaker's window falls to an ember. The world tells the truth before the HUD does. | 3 | S-M |
| 4 | **The keeper names who it faces.** The Lamplighter's challenge carries one dry line chosen by the lead's class or name: "A Rook. Hold your light steady." No exclamation marks. | 1, 4 | research S, builder S |
| 5 | **An idle earned by stars.** At three stars a Voidkin's idle gains one small flourish every eight seconds or so; at seven it holds a pose of its own on the Voidkin screen. No stat. A Common at seven stars shows something a Mythical can't. | 1 | Modulo M |
| 6 | **Cracks you can read from the gate.** The shard in a chamber gains a crack at each quarter of its break, so progress reads from across the base with no number. | 3, 4 | Modulo S, builder S |
| 7 | **A Named shard shows its outline.** In the last tenth of its break, the chamber's window shows the faint outline of who is inside, from the reveal's own silhouette layer. Never on a rolled shard. | 1 | S-M |
| 8 | **The showcase greets.** When a visitor stands within ten studs of a plinth, the Voidkin on it plays the end of its reveal once. | 1, 3 | S |
| 9 | **The card says who did it.** "Kirra cleared Lantern Row · 11:42", and under a new best, "Kirra's best". The Tower's card the same. | 1 | S |
| 10 | **The type edge is in the sparks.** A hit with the edge throws a second, brighter ring; one against it lands dull. The player learns the ring by watching. | 2, 4 | builder S-M, Scintilla's look |
| 11 | **The Tower's marker grows.** The marker behind the base gains a lit band for every ten floors of the record, so a passer-by reads the climb from the Strip. | 3 | S-M |
| 12 | **The base reaches you in a fight.** Out on Lantern Row, each quarter of a break at home sends one small glint along the Power pill, and "Ready" lights the Base cell's pip (the pip exists). "A shard cracking while you fight" becomes something seen. | 3 | S |

Each is tier 2 (a new thing players see), so research and the area touched say yes, with a notice to the director. None changes balance. Number 4 needs the lines read against `docs/ip-list.md`.

## A frank critique

- **The docs describe a more finished game than the build.** Nine written details aren't in the code (verdict 3). OPINION: a review should open the screen with the doc's sentence beside it, and a sentence the build doesn't keep should be struck or filed, the same day.
- **The honesty details are strong and nobody will praise them.** Odds, prices, reasons on disabled presses, server-confirmed payoffs: all there, all tested (1,110 checks in `Cases.luau` alone). What's thin is the warmth: marks, greetings, summaries, a welcome back. Premium is both.
- **The base is the pillar with the fewest finished details** (7 of 15, and no Upgrade press). The fight has had the hours. Pillar 3 can't hold on a grey command view.
- **A details pass can turn into scope creep.** The guard: a detail lives inside a system that exists, costs under a day, and adds no rule, currency or screen. Anything else is a piece and goes through a feel line.
- **I disagree with one item on my own outside list:** equip-best. Every ARPG has it and it fits them. It would hollow out pillar 2 here.

## Top 5 to act on

| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **The Upgrade press** (top 30, item 1), with its self-test. It unblocks the Build beat and the Next list. | builder | 3 to 5 h | no: `docs/ui.md`, screen 7, is already the director's |
| 2 | **One day of the small provable ones:** items 2, 5, 7, 12, 17, 18, 20. Each lands with its case. | builder | about a day | no: tier 1, except item 5's wording (research) |
| 3 | **Keep what the paper promised:** the transfer's question (6), the chest summary (8), the item lock (15), CR's parts (26). Or strike the sentence. | builder; research strikes | about 1.5 days | no for building; yes to strike a director's line |
| 4 | **The fight's three reads:** the low-health pulse (3), the target's ring (11), the fall card's why (4). One feel line, one block. | research's line, builder | 4 to 5 h | no: tier 2, a notice on the board |
| 5 | **Three living-base details as one block:** the hum (2), the glance (1), the lights (3) from the twelve. | builder; Modulo one clip; research picks the hum | about half a day | no: tier 2. The hum joins `audio-direction.md`'s one sitting of the director's ear |

## What I couldn't fetch

- The session's web search budget was used up before this study began, so no search ran.
- Refused or not found: Fandom wikis (Genshin), Bulbapedia, Game8, Game UI Database, Fextralife, Marvel Snap Zone, the Independent Fallout Wiki, a Deconstructor of Fun URL I guessed, the Xeno Series Wiki. No YouTube, no Interface In Game, no GameRefinery.
- So every per-game feature marked RECALLED (history logs, lock and junk marks, salvage filters, battle statistics, tower previews, source links) is from memory and needs one check before anyone quotes it. The audit of our own build doesn't depend on them.
