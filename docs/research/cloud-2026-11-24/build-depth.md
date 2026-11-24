# The build: depth a phone can read (research study, 2026-11-24)

**Verdict, in five lines.**
1. Our build has ten layers and 126 sockets on paper, but only one layer holds many real decisions: the War Emblems' stat choice. Jewels hold none. Reinforce holds one (which item first). Rarity and tier are strictly-better ladders.
2. MEASURED from our resolver: two builds at equal Combat Power do fight differently (kill time 18 s, 29 s, 51 s on the Hard Lamplighter). The difference shows only as fight length and health lost, never as behaviour.
3. Combat Power is a geometric mean, so it pays the balanced build 21 to 48% more for the same spend. With the bag's up arrow it steers every player to one build. Pillar 2 ("two players argue which is better") is at risk from our own number.
4. No item changes how the lead fights. Every passive lives on a Voidkin. The engine already has five passive kinds and four element states: build-defining items cost little code.
5. Stage it by a UI gate on the facts `Goals.luau` already has, hold jewels, make Reinforce sure, and show the build's shape beside the number. Most of this needs the director's yes.

Numbers below are seeds to tune by playing. Labels: SOURCED, COMMUNITY, OBSERVED, MEASURED, OPINION.
Method: MEASURED rows come from our own `Rules.Stats.Resolve`, `Stats.Sum` and `Rules.Hit.Expected`, run offline through `tools/checks/logic_offline.luau` with a scratch cases file. Expected values only: no signature timing, packs, skips or the Opener passive. Lead: Rook. Foes at the lead's level.
Not fetched: the web search budget ran out, so I fetched known pages directly. See "What I couldn't fetch" at the end.

## 1. Our build on one page (OBSERVED, MAIN checkout)

| Layer | What it adds | Decisions it holds | First met | Grind length |
|---|---|---|---|---|
| Voidkin: class, type, element, level, stars | Base 35% and stars 3.5% of level-60 power (`docs/balance.md`); the only passives in the game (`Definitions/Passives.luau`) | Which of 5 leads | Minute 1 | 57 h over six grounds (MODEL, `docs/balance.md`); one ground at launch |
| Five Basic Attributes | Convert once into Battle Attributes (`Config/Stats.luau`) | None directly. No points to spend | Stat sheet | None |
| Regalia items: 14 slots (2 hands + 12 shared) | 27% of power. Main line + 1 to 4 rolled lines; 5 rarities; tier by ground (`Config/Chests.luau`) | Keep or salvage, by comparison. Jewellery's main attribute, by luck of the drop | Third kill (`Chests.Sure = 3`) | One ground: Rare about 2 h, Epic 4.3 h, Legendary 18 h (TR48 MODEL, `docs/design.md`) |
| Reinforce, +30 | 13.5%. Each level adds 1/30 of the main line (`Config/Reinforce.luau`) | Which item first. In the end, all of them | When any item is owned (`Goals` fact Forge) | MEASURED: 106 expected tries and 16,139 Credits per tier-1 item; 1,488 tries for 14 |
| War Emblems, 56 sockets | 11%. One flat stat each: 6 stats, 3 more from Epic (`Config/Emblems.luau`) | Up to 56 free stat choices. The richest layer | Elite 30%, keeper 75% drop (`Config/Drops.luau`) | Four rarities, Uncommon to Legendary |
| Jewels, 70 sockets | 7% on paper. Flat attribute points | None: every item takes one of each colour | Not built. The page says "Jewels are coming" (`EquipmentScreen/Jewels.luau`); the resolver has no jewel source (`Rules/Stats.luau` header) | MEASURED: a level-5 jewel is 81 level-1s; a full set is 5,670 |
| Presets, 1 to 5 | Nothing. A saved loadout per class | Farm set against keeper set. Real, later | One from the start; I didn't find what opens 2 to 5 | None |
| Stone Condenser | Reinforce stones on a timer: 1 Low an hour (`Config/Condenser.luau`) | None | Base level 2 | 471 Low stones for +10 on 14 items (MEASURED) |
| Forge machine | The strike's theatre | None | With Reinforce | None |
| Combat Power | One number: 3.431 x sqrt(EHP x DPS) against a reference body (`Stats.Sum`) | It makes the decisions for the player | By the first equip | Rises with everything |

- Emblem sets (12 of them) are "a name and a symbol only, never a stat" (`Definitions/Emblems.luau`). There are no set bonuses.
- Gear is never shown on the body (the director's call, cited in `systems-that-marry.md`). Combat Power is the build's only face outside a menu.
- At one ground, only Low stones drop (`Config/Drops.luau`, `GroundsAGrade = 2`). Mid comes from the Condenser's 5-to-1 convert. I found no High source at launch, so +21 to +30 looks unreachable. Faber should confirm.

## 2. What the sources say

**F1. A choice with an always-best answer isn't a decision.** SOURCED: Sid Meier, GDC 2012. Good decisions are trade-offs, situational, persistent, or express a play style; he also warns to err "on the side of providing the player with too much information" about a choice's result. https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions
- For us: rarity (worth 0.55 to 1.0, lines 1 to 4, sockets 1 to 4) and jewels fail the test. Emblem stats and presets pass. Automate what fails, spend the taps on what passes.

**F2. Fewer, better, readable drops.** SOURCED: Diablo IV's Season 4 "significantly decreased the number of items that drop", cut affix counts, and replaced conditional affixes with flat ones so it is "easier to understand which items are upgrades when they drop". https://news.blizzard.com/en-us/diablo4/24077223/galvanize-your-legend-in-season-4-loot-reborn SOURCED (secondary): Diablo III's Loot 2.0 did the same ten years earlier, and made legendaries change skills. https://en.wikipedia.org/wiki/Diablo_III:_Reaper_of_Souls
- For us: a chest every third kill, a bag of 300, and a pool of 16 line stats is the pre-fix shape. Our lines are already flat, which is the right half. The missing half is the item that changes a skill.

**F3. Gear can be the character.** SOURCED (secondary): in Monster Hunter the hunter "has no intrinsic statistics"; abilities are "defined by the specific weapons and armor selected", and gear is forged from known parts, not rolled. https://en.wikipedia.org/wiki/Monster_Hunter
- For us: our crafting is all chance (chest roll, then Reinforce roll). One sure path to a named piece (a keeper's first clear, a Tower floor) gives a goal the player can plan. `systems-that-marry.md` notes no goal names gear today.

**F4. Don't make the next tier erase the last.** SOURCED (secondary): Destiny 2 capped old gear's level in 2020; "after two seasons, Bungie recognized this approach was not ideal" and removed it, and cut the seasonal power climb from 50 to 10 after complaints about the grind. https://en.wikipedia.org/wiki/Destiny_2:_Beyond_Light SOURCED: Guild Wars 2's stated aim: "We don't need to make mandatory gear treadmills". https://www.guildwars2.com/en/news/is-it-fun-colin-johanson-on-how-arenanet-measures-success/
- For us, MEASURED: a Common from ground 2 (0.55 x G(19) = 2.45) outweighs a Legendary from ground 1 (1.0 x 2.216). Ground 2 will bin every Legendary. The free transfer of Reinforce and emblems [D 11-17] softens it; keep that rule whatever else changes.

**F5. Enhancement that can fail is the most regulated press in the genre.** SOURCED: Roblox names "Upgrade spell with some chance of working" as a paid random item when bought "directly or indirectly with Robux", and counts pity as a probability modifier to disclose. https://create.roblox.com/docs/production/monetization/paid-random-items SOURCED (secondary): Nexon was fined 11.6 billion won in 2024 over undisclosed rate changes in MapleStory; South Korea has enforced published odds since March 2024. https://en.wikipedia.org/wiki/MapleStory , https://en.wikipedia.org/wiki/Loot_box COMMUNITY: MapleStory's own ladder falls from 95% to 1% with item destruction, and the game added a sure success after two straight drops. https://maplestorywiki.net/w/Star_Force_Enhancement
- For us: `collection-and-economy.md` already makes the case and the price (cost divided by chance). I add the streak numbers in section 4.

**F6. Show a few things first; what's on screen reads as important.** SOURCED: NN/g: "Initially, show users only a few of the most important options", and "the very fact that something appears on the initial display tells users that it's important". https://www.nngroup.com/articles/progressive-disclosure/ SOURCED: Roblox: "Delaying non-essential information to future sessions reduces what they must learn and remember in the first session"; a lock icon marks what isn't earned yet; small screens "easily get overwhelmed". https://create.roblox.com/docs/production/game-design/onboarding-techniques , https://create.roblox.com/docs/production/game-design/ui-ux-design
- For us: 14 empty slots and a "Jewels are coming" page tell a new player that all of it matters now. `Goals.luau` already has `Opens` facts (Hard, Tower, Condenser, Forge): the gate is half built.

**F7. A build the eye can see.** SOURCED (secondary): in Hades each boon set shows in the fight (lightning on hits, waves that push). https://en.wikipedia.org/wiki/Hades_(video_game) Marvel Snap aimed for "a deep game without introducing complicated game mechanic": 12 cards, six turns. https://en.wikipedia.org/wiki/Marvel_Snap
- For us: we own the tells already: Burn, Chill and Freeze, Shock, Sap, the poise bar, the Regen burst, the signature ring (`Config/Combat.luau`, `Rules/Fight.luau`). No gear touches any of them.

**F8. More tracks didn't keep players.** OBSERVED: our own `docs/research/long-grind.md`: the director's reference had about 15 upgrade tracks and fell from 745,280 concurrent players to 1,046 in seven months.
- For us: track count isn't retention. A layer earns its place by holding a decision or a visible change.

## 3. Measured: do additive stats make distinct builds?

Same spend (level 9, 14 Rare items, +10, all 42 sockets filled with Rare emblems), four ways to point it:

| Build | Combat Power | Health / Attack / Defence | Hard Lamplighter | Health lost |
|---|---|---|---|---|
| Striker (Strength, Attack, Critical) | 5,105 | 1,399 / 769 / 136 | 18.2 s | 17.7% |
| Wall (Endurance, Health, Defence, Dodge) | 6,228 | 2,736 / 284 / 795 | 52.1 s | 9.1% |
| Mixed (Attack, Health, Defence) | 7,543 | 2,700 / 671 / 625 | 23.3 s | 7.3% |
| Crit (Agility, Critical) | 4,801 | 1,237 / 669 / 136 | 20.3 s | 20.2% |

Equal Combat Power (about 5,180, level 9, Rare items), reached three ways:

| Build | What it cost | Hard brawler | Hard Lamplighter | Health lost |
|---|---|---|---|---|
| Striker | +12, 42 emblems | 1.8 s | 18.0 s | 17.2% |
| Mixed | +3, 16 emblems | 2.7 s | 29.3 s | 16.6% |
| Wall | +13, 20 emblems | 4.7 s | 51.4 s | 14.0% |

The same pattern holds at level 30 with Epic items (equal Combat Power 18,124: 19.6 s, 30.9 s, 48.8 s).

- **Yes, narrowly.** At equal Combat Power the striker kills 2.8 times faster than the wall. Pillar 2 holds on paper.
- **Mixed dominates.** Same spend: +48% Combat Power over the striker, +21% over the wall, and it loses the least health. The wall is slower and loses more than mixed: it has no use in grounds.
- **The number underrates speed.** The striker pays 4 times the Reinforce and 2.6 times the emblems for the same Combat Power, yet its kills take a third less time than mixed's and under half the wall's. Farming is most of the game.
- **A trap.** Critical chance saturates: 57.4% on the striker, 57.5% on the crit build, cap 60%. The crit build spends a jewellery choice and gets nothing. Nothing on screen says so.
- **One real multiplier.** Attack x Critical Damage is the only place two pools multiply without a ceiling. At Epic, 28 Critical Damage emblems take the striker from 18,546 to 21,399 and the Hard Lamplighter from 19.3 s to 13.9 s. Late builds will converge there.
- **Duels are short.** Expected-value duels at equal Combat Power last 2 to 7 s. A build can't be read in 2 s.

## 4. Frank critique

1. **Bigger numbers, not decisions:** jewels (70 sockets, zero choices, 5,670 grains), Reinforce (everyone maxes everything), rarity, tier, stars. Reinforce and jewels alone are 20.5 of the 58.5 points of level-60 power that gear holds.
2. **Real decisions:** emblem stats, jewellery's attribute, presets, where Reinforce goes first. All four are invisible in a fight.
3. **The first forge rank can't be felt.** MEASURED at level 3: a Common chest piece adds +95.7 Combat Power (8.3%). Reinforce +1 on it adds +1.3 (0.1%) for 71 Credits and a stone, about six kills' Credits. All five sure levels add +6.5. One Uncommon emblem adds +20 to +36, the worth of about 22 Reinforce levels. The north star's "Build" beat names the weakest action we have.
4. **Reinforce's tail is a streak machine.** MEASURED: at 20% a ten-fail streak has a 10.7% chance per level. Across the 224 level-ups at the floor (14 items), about 92% of players who max will see a 20-fail streak and about 24% a 30-fail streak. "No pity" is in `Rules/Reinforce.luau`.
5. **Emblems are flat points sized for level 60**, so early they dwarf the gear they sit in. Only drop scarcity (0.10 at Lantern Row, `docs/balance.md`) hides it.
6. **A new player sees** a 14-slot doll, three sub-pages (one a promise), a 16-stat sheet and a bag that fills every third kill. `first-session-script.md` already hides most of it by script; the screens themselves don't.

## 5. Proposals

**(a) Staging ladder.** One system per session, opened by facts the code has. A UI gate, not a deletion. Chests roll only for open slots. Needs the director's yes (their 14 slots stay, but arrive in steps).

| Step | Opens when | The player gets | Still locked, shown as a lock |
|---|---|---|---|
| 1 | Third kill | Bag, six slots (two hands, Helmet, Chest Armor, Amulet, Ring I), Combat Power. The first equip is by hand, as `first-session-script.md` scripts it | Everything else |
| 2 | First item worn | Reinforce to +5 only, the sure band, on the Forge | Levels past +5 |
| 3 | First Lamplighter win, base level 2 | Condenser (as built), Reinforce past +5, Shoulders, Gloves, Boots | Emblems |
| 4 | First Hard Lamplighter win | War Emblems, one handed over with the win. The first stat choice | Presets |
| 5 | A second class owned | Preset 2, named for its use | |
| 6 | Base level 3 | Bracers, Cloak, Ring II, the Earrings; the first build-defining piece | Jewels |

- Each slot step adds one new stat (Gloves bring Critical, Boots Dodge, Bracers Hit, Cloak Block): the stat sheet is learned a line at a time.
- This matches `design-review.md` (challenge 5) and `state-of-the-game.md` (item 6); the new part is the per-step trigger and the stat-per-slot order.

**(b) Merge, simplify, hold.**

| Cut | Saves | Costs | Director's yes |
|---|---|---|---|
| Hold jewels; remove the "Jewels are coming" page | 70 sockets, a merge screen, a resolver source, a bag tab; weeks of build | 7% of power to re-home in `docs/balance.md`; reverses the 11-19 yes | Yes |
| If jewels stay: one socket per item, any colour | 56 sockets, and it becomes a choice | A smaller grind | Yes |
| Launch Reinforce cap of +15 | All but one level of the 20% band, the worst streaks, a stone grade with no source | Part of Reinforce's share waits for ground 2 | Yes |
| Trim the rolled-line pool to stats a fight shows | A shorter stat sheet, readable compares | Less roll variety | No (tier 2) |
| Emblem set bonuses | Nothing; it adds a layer | Hold until the six ideas below are judged | No change today |

**(c) Build-defining pieces: mechanics only.** Each uses a kind the engine reads today (`Rules/Passive.luau`, `Hit.Effects`), stays inside the bucket caps, has a cost, and has a tell. Fixed stats, a sure source, never from a roll. One worn per preset to start. Names are not proposed; any name needs the IP-list check. These are genre-common mechanics, taken from no single work.
1. **Opener hand.** The first hit on each new target is critical; Critical rating from other sources counts half. A farming build. Tell: a critical flash on every fresh Shade.
2. **Echo off hand** (Extra kind). Every third basic hit repeats 30% as the lead's element; basic hits deal 10% less. Burn stacks faster, Chill fills sooner. Tell: more state on the foe.
3. **Quick amulet** (Cooldown kind). Signature cooldown 25% shorter, signature damage 15% lower. Tell: the ring fills visibly faster.
4. **Last-stand chest** (Reduction kind). Below 30% health take 25% less; above 70% take 10% more. Pairs with Lifesteal. Tell: a guard flash at low health.
5. **Mending belt.** The Regen burst comes every 6 s, not 8, and is smaller. A long-fight build for keepers. Tell: the burst pulse more often.
6. **Breaker bracers.** Hits fill poise 30% faster, damage 10% lower. A stagger build. Tell: the poise bar and more staggers. Waits on poise being in (AR48).
7. **Ward cloak** (Resist kind). 25% less elemental damage, 10% more physical. A keeper-specific preset piece.
- Start with a blockout of 1 and 3 only, judged in motion. New mechanics are tier 2, and joining the slice is the director's.

**(d) Reinforce without paid-random risk or frustration.**
- First choice: every press succeeds, the price carries the odds. Already costed in `collection-and-economy.md` (e), with a +10 fail-stack as the fallback. It removes the paid-random question whole.
- A gentler fallback, MEASURED: +5 points per failure. At the 20% floor, expected tries fall from 5.0 to 3.4 and success is certain by try 17; raise the price 1.46 times to hold the sink. Either fail-stack is still a paid random item once Credits are sold.
- One figure, settled 2026-11-24: one item to +30 costs 7,282 x G Credits in expectation (16,139 at tier 1) and 1,830 x G if every try landed. Checked by hand from `Config/Reinforce.luau`; `collection-and-economy.md` said 33,895 x G and is corrected.
- Front-load the gain so the sure band is felt: levels 1 to 5 give 3/30 each, the rest share what's left (seed). +5 then adds about +20 Combat Power at level 3, not +6.5.
- Either way: the Forge's strike, a +N badge on the item, and a glow at each grade carry the feel. The number can't.

**(e) Compare and equip in two taps.**
1. Tap an item: its card opens on the right, the worn one on the left (as `taichi-panda-study.md` found). One header line: Combat Power change, then the shape change (below). Only changed lines, four at most, the rest behind "more".
2. Tap Equip, right thumb. Reinforce and emblems move by default, said on the button ("Equip, moves +7 and 3 emblems"), with a 5-second Undo. A prompt appears only when something would be lost (fewer sockets). This replaces the standing transfer prompt [D 11-17]: needs the director's yes.
- Zero taps: after the first hand-made equip, an empty slot fills on pickup (no decision in it, F1). Never auto-equip over a worn item: with our number that would build "mixed" for everyone.
- **Build shape.** `Stats.Sum` already computes `ehp` and `dps`. Show them as two bars beside Combat Power, plus "even foe falls in 2.2 s". Show a rating's cap ("Critical 57% of 60%"). Grounds can then recommend a shape, not only a number.
- Bag: the up arrow only for a gain of 1% or more; one dot only when a free action raises Combat Power; auto-salvage on from step 3.

## Top 5 to act on

| # | Do | Who | Cost | Director's yes |
|---|---|---|---|---|
| 1 | Gate the Equipment screen and chest slots by the ladder in (a), on `Goals` facts | Faber builds, Quaestor owns the ladder | 1 to 2 days | Yes |
| 2 | Reinforce: sure success (or the shown fail-stack), front-loaded gain, launch cap +15 | Faber, Quaestor for `docs/balance.md` | Half a day | Yes (reverses 11-19) |
| 3 | Build shape beside Combat Power, caps shown, the two-tap card with default transfer | Faber; Modulo for two bar frames | 1 day | Display: no (tier 2). Default transfer: yes |
| 4 | Hold jewels, remove the "coming" page, re-home their 7% | Quaestor, Faber | 2 hours now; saves weeks | Yes (reverses 11-19) |
| 5 | Blockout two build-defining pieces (Opener hand, Quick amulet), judged in motion | Faber (item source into `Hit.Effects`), Scintilla for a tell each | 1 day | Blockout: no (tier 1). Shipping: yes |

**What I couldn't fetch.** Lost Ark honing and its pity bar; Black Desert fail-stacks; Genshin's and Destiny's roll-on-roll changes; the Brawl Stars gear rework; Path of Exile filters and the GDC talks behind their overview pages; any statement on "small numbers" from Marvel Snap or Slay the Spire; mobile unlock-ladder teardowns; evidence on red dots or on what auto-equip costs. Nothing here rests on them. Fandom wikis returned errors.
