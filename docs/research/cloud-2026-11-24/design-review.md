# Design review, 2026-11-24 (a frank one, from outside the team)

A senior designer's read of the design as it stands on `main`, for the director. Read: `docs/north-star.md`, the directive's sections 1, 3 to 7 and 15, `docs/decisions.md`, `docs/design.md`, `docs/balance.md`, `docs/roster.md`, `docs/production-plan.md`, the Now board, `docs/research/design-holes.md` and `similar-games.md`. **These are proposals, not permission:** nothing here changes the design until the director says so, and the tier of each is named.

Where research's design study of 2026-11-23 (H1 to H9) already found a hole, this review says so and goes one step further rather than repeating it.

## The verdict

1. The vision holds up and is distinctive: a base that works for you, a lead that fights beside you, one honest account-wide build. The engineering is well ahead of the design.
2. But launch ships a **collection game with five fighters** and a **57-hour build system fitted to six grounds**. The reveal, the game's signature moment, runs dry in the first hour, and in a fight the player still has nothing to press.
3. Spend the next weeks on *what to collect* and *what to press*, not on more systems. Put today's build in front of strangers before anything else grows.

## The challenges, ranked by impact

### 1. A collection game with nothing to collect after hour one

- **Now:** launch has five Voidkin, four of them Common and one Rare (`docs/production-plan.md`, "The cut line"). Lantern Row's shards roll about 87% Common and 13% Lyric. A duplicate becomes a star copy, and the seven stars take 1+2+4+…+64 = 127 copies for "a fixed small gain, not game changing" (`docs/design.md`, "Voidkin", Stars). Stars are 3.5% of a full build (`docs/balance.md`, "Where power comes from"). Fusion, traits, mutations and the second form are all out of launch (`docs/design.md`, "Out of launch"; D4 "post early access").
- **What's wrong:** pillar 4 says "reveals are events", but within the first hour almost every reveal is a fifth copy of Rook worth almost nothing. The roster says so itself: "without an Epic and a Legendary … there's nothing to chase" (`docs/roster.md`, Lantern Row's shards). Research's H9 saw the symptom and answered it with an update cadence. Updates fix week 3. They don't fix hour 2 of day 1, which is where a player decides to come back.
- **Evidence:**
  - SOURCED: every live peer puts a roll on top of the unit. Anime Vanguards rolls a cosmetic shiny at about 1.5% a summon, apart from the unit ([droidgamers](https://www.droidgamers.com/guides/anime-vanguards-shiny-guide/)). Grow a Garden's Gold (about 1%) and Rainbow (about 0.1%) mutations are the hunt ([videogamer](https://www.videogamer.com/guides/grow-a-garden-mutations-guide)). Anime Card Farm sells itself on "mutated cards", and the live template, Grow a Chicken Fighter, fuses into mutations (`docs/research/similar-games.md`).
  - OBSERVED: the two zero-player reskins of that loop show the theme alone draws nobody (same file).
- **Better:**
  - **Bring D4's rare second form forward to launch.** It's a look found by roll, with no stats, earned only and never sold, so it's already designed and already allowed. Each break rolls it at about 1 to 2%, with a reveal beat of its own and an Index slot for each form. Every duplicate becomes a ticket again.
  - **Add Marigold (Epic) to launch** as the one real chase, Enriched and Prismatic only.
- **Cost:** a palette, emissive and outline variant for each of the five (Modulo, about an hour each, once the redesigns land), plus Faber's roll, save field, Index column and reveal flourish (about 4 h). Marigold is a full Voidkin, the expensive half. Tier 3: it reverses D4's timing and the five.

### 2. The production order is upside down: systems first, the product last

- **Now:** "Every Voidkin piece waits for the end … The game's systems come first" (the director, 2026-11-17, in `docs/production-plan.md`, "The cut line"). It was reversed only for the redesigns, on 2026-11-23 at 22:52. The bar has since risen to Anime Vanguards' make (`docs/decisions.md`, 23:45 to 23:52), and Rook's redo isn't accepted yet.
- **What's wrong:** in a collection game the characters *are* the product. Research's own estimate calls the redesigns "the long pole", and every hour on a fourth gear layer or a machine stage is an hour the long pole doesn't move. Nobody yet knows what one finished Voidkin costs at the new bar, so the roster count of every later plan is a guess.
- **Evidence:** OBSERVED. The design study counts 1,366 commits in two weeks, with Regalia, Reinforce, emblems, jewels, the Forge, the Condenser and the machines' three stages built, while four of the five fighters are still "horrible" by the director's word of 2026-11-20.
- **Better:** make the Voidkin pipeline the critical path now.
  - Time Rook's and Kirra's make end to end, and set launch's roster from that measured cost.
  - Freeze every system not yet started (the Clash Grounds, the Forge's later uses, stages past the generator and the Breaker) until the launch roster is in.
- **Cost:** system polish waits. Tier 3, since it's the director's order.

### 3. In a fight, the player still steers a fighter through a 30-stud leash

- **Now:** the avatar is never a target, and the lead fights what's near it (`docs/design.md`, "Combat"). The signature on a tap is a block waiting on the director's run (TR52). Yet the launch dares ask "let no Dasher's line touch you" and "stand outside every slam" (`docs/design.md`, "Goals").
- **What's wrong:** H1 found the missing verb, and TR52 answers half of it. The other half is control. To get the lead out of a line, the player has to move an avatar that can't be hit, so that the leash eventually drags the fighter that can. On a phone that reads as mush: the dare tests the leash's lag, not the player. The directive is blunt: "Do not mistake a mathematically valid auto-battle simulation for a fun combat system" (section 10).
- **Evidence:**
  - OBSERVED: TR44's mode B, a Recall button, exists for the keeper only.
  - SOURCED, by research: AFK Journey and HSR leave the ultimate's timing to the player (`docs/research/design-holes.md`, H1).
- **Better:**
  - The tap is **on by default** for a new player, with Auto offered as a setting after the first keeper.
  - Generalise TR44's B into **one direct command in every fight**: "to me", a short dash of the lead to the avatar's side, on a cooldown of about 4 s. Then dares, Dashers and slams are tests of skill, not of the leash.
- **Cost:** TR52 is built; the command is a block of about 3 h through `/ga-action`. Tier 3 (how combat plays).

### 4. The power plant asks nothing, and the bays hold no choice

- **Now:** the director's power plant has kW, a battery and a drag-to-split bar (`docs/design.md`, "The base", Power). Research's own run says the bays make 1.8 to 7.7 times what the machines draw, voltage is never offered, the battery has no sink, and "the Power screen's split has one answer (Auto)" (`docs/balance.md`, "Electricity at launch"). With five Voidkin, one leading and one training, every other Voidkin works, so "who works" isn't a choice either (H3).
- **What's wrong:** pillar 3 promises that "electricity is what ties collecting to fighting". At launch it ties nothing: it's a number that goes up. A slider with one answer is UI debt on a premium game. Tightening the margin (F3's 1.2 to 1.4 times) alone turns it into the "excessive management" the directive warns against (section 6).
- **Better:**
  - Tighten as F3 proposes, and **replace the free drag with three one-tap focuses: Break, Train, Forge.** Each sends most of the power to one machine. That's a real choice (shards, levels or stones while you're away), made in one tap a session. Keep the drag bar as an advanced view.
  - Give each class a **job leaning** (a Tank makes more power, a Mage condenses better), so who works where matters once the roster grows.
- **Cost:** a simulation rerun (research, about 2 h), the focus buttons (Faber, about 3 h), aptitude data per job (small). Tier 3 for the screen, since it's the director's design; tier 2 for the numbers.

### 5. Gear: 14 slots and up to 126 sockets for one street

- **Now:** fourteen slots, five presets, rolled lines, Reinforce to a 20% chance, up to four emblems a piece, and five jewels in each piece with 3-to-1 merges (`docs/design.md`, "Regalia"). A first Legendary takes about 18 h of Lantern Row repeats (TR48's MODEL). Gear "is never shown on the body".
- **What's wrong:** H5 named the misfit. The worse effect is on the first hour. A new player meets more equipment screens than fighters, and the layers compete with the reveal for attention. Pillar 2's "two players compare builds" also has nothing to see: a build lives only in menus.
- **Evidence:** OBSERVED, `docs/balance.md`, "Pace": the build was fitted to 57 hours and six grounds, and launch has one ground.
- **Better: progressive disclosure, not a cut** (it's built, so keep the code).
  - Launch opens the two hands, Chest, Helmet, Amulet and Ring I, plus Reinforce.
  - Emblems open with Hard's Lamplighter, jewels at a Tower milestone, and the other slots with base levels 2 and 3. Each opening is a moment with a goal pointing at it ("Next").
  - Add one visible flex: a **build aura** on the lead whose tier comes from its total Reinforce or a complete Dawn set. It's an effect, not gear on the model, so the authored look stands.
- **Cost:** gates are about 4 h for Faber; the aura is one effect within the 2 h cap; the rest is research's refit of the pace. Tier 2, and tier 3 for the aura (it touches "gear never shown").

### 6. Selling Credits turns the game into the gacha the north star says it isn't

- **Now:** "Credits will be sold" (the director, 2026-11-19, about 03:12). The north star says "Not a gacha that sells luck. Nothing random is sold at launch." Credits buy rolled shards, Reinforce past +5 at 80% down to 20% (a failure "spends its cost"), and featured gear.
- **What's wrong:**
  - Once Credits are sold, every shard bought and every Reinforce press is a paid random item. Showing the odds is necessary, not sufficient: where `ArePaidRandomItemsRestricted` is true, those players must be blocked from them.
  - Reinforce failure is the worst kind, a paid loss machine. It's the pattern players resent most, and it sits on 13.5% of the build.
- **Evidence:** SOURCED. Roblox's [paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items) page covers items bought with in-game currency that was bought with Robux. OBSERVED: research's store proposal already keeps Credits unsold at launch (`docs/decisions.md`, "Waiting on the director", 2).
- **Better:**
  - Never sell the currency that buys rolls. Sell passes, cosmetics, bag space and a Founder's Mark, as research proposed.
  - Make Reinforce **deterministic** (100%, with a rising cost), or at least add a fail-stack that guarantees success by a shown count.
  - If Credits must be sold one day, make the shop's shards Named (not random) first.
- **Cost:** less store revenue at first, and a Reinforce refit (research, about 2 h). Tier 3.

### 7. The first ten minutes still have a teleport and slow heals in them

- **Now:** join, break a starter shard, walk into the door, the Arc panel, a teleport to the Festival place, the first hit (`docs/research/design-holes.md`, F7). The first drop then needs a trip home before a bay can work.
  - Regen at level 1 is about 1% of health a burst, every 8 s.
  - A fallen lead heals for about 90 s at home.
  - Those are the director's words.
- **What's wrong:** the north star says "nothing in the first session waits more than about half a minute". The path today breaks that at least twice, and it breaks pillar 3's "a shard cracking while you fight". The first breach (Shades stepping out of a crack in your own yard) is filed as the *fallback* if the timing test fails.
- **Evidence:** OBSERVED, F7's path. UNVERIFIED: how a same-experience teleport counts in Roblox's analytics (F7).
- **Better:**
  - Make **the first breach the default first fight**: Fight, Find and Work all happen at home in the first three minutes, and the first teleport is the player's own choice.
  - Keep "health carries" inside a run, but **start every run at full health**, with a lantern heal at each stretch's mark. The attrition is still a choice within a run, never a walk home between runs.
- **Cost:** Faber's estimate for the breach (research guessed it needs no new system); about 1 h for the heals. Tier 3 (the director's health words and the first-session beats).

### 8. The Clash Grounds: an expensive arena where nobody plays

- **Now:** champions fight each other automatically all day, players watch, and Echoes keep it busy (`docs/design.md`, "The Strip"). It's phase 5, "if they reach the bar".
- **What's wrong:** with five Voidkin at launch, every champion is one of the same five, auto against auto, with nothing to press and nothing to read. It's a big build (matchmaking, anti-farm pairs, a daily track, Echoes) for a social feature whose social act is watching.
- **Evidence:** OPINION, weighed against SOURCED: Grow a Chicken Fighter does run an auto 3-v-3 arena (`docs/research/similar-games.md`), but on a pool of hundreds of chickens.
- **Better:** cut it from launch for good. Spend those hours on challenge 1 (Marigold) or on Drum Court's first update. The showcase plinth and visits already carry "see other players' progress" (the directive, section 3).
- **Cost:** none built is lost. Tier 3 (scope).

### 9. Too many colours and too many "Void"s for a player to read

- **Now:**
  - Five types named by colour (Blue beats Red, Red beats Orange…).
  - Five jewel colours with a yellow (Endurance) but no orange.
  - Four elements with their own colours.
  - Eleven rarities, each with its own colour.
  - So Pip is a Purple-type Fire Mage, and Rook a Red-type Fire Warrior holding red Strength jewels.
  - "Void" names the fighters, the shards, the Breaker, the Mill, the Shop, the Rift, the Clash and an element.
  - A run is a ground, an Arc, a mission, a stretch and a phase. Combat Power reads "CR".
- **What's wrong:** colour carries four meanings, so it carries none. Purple beating Green has no hook a ten-year-old can remember. A counter ring nobody can read is a counter ring nobody uses, and the simulation says the right type is "worth a third of a build".
- **Evidence:** OBSERVED, `docs/design.md`, "Voidkin" and "Regalia"; `docs/roster.md`. OPINION on how it reads.
- **Better:**
  - Give each type **a symbol and a word** (keep the colours as its tint).
  - Let colour mean type on fighters, and only rarity on frames.
  - Show jewels by attribute icon first.
  - Players see one word for the run (Arc) and one for its parts.
  - Keep "Void" for the shards and the Breaker only.
- **Cost:** about an hour of text, plus five type icons. Tier 3 for the type names (the director's of 2026-11-17).

### 10. Nobody outside the team has played it

- **Now:** "TR32's marks … before any stranger plays" (`docs/production-plan.md`). The north star's "How we'll know" (comes back the next day, argues builds, screenshots a reveal) has never been measured. Every pace number is MODEL or a seed.
- **What's wrong:** two weeks of systems have been tuned by the team's taste and the director's minute-by-minute remarks. The decision register logs words to the minute. The directive itself warns "do not create another bureaucracy" (section 16), and asks that the loop "be satisfying at a small scale before we add dozens of supporting systems" (section 6).
- **Better:** this week, publish the private build (item 4 on the board) and seat five people who have never seen it, friends of the director, on a phone. Use TR32's funnel plus one question the next day: "did you want to come back?". Let that answer reorder challenges 1 to 9.
- **Cost:** TR32, about 3 h, and the director's publish. Tier 3 (accounts and access).

**A watch item, not a challenge:** the word of 2026-11-23 ("heavy inspiration from famous anime IP") is held correctly by the register: archetypes and wardrobes yes, a recognisable side character no. With the make now copying Anime Vanguards' *way of building* a unit, the Fighters test (`docs/decisions.md`, "Fighters") must be run on every redesign before the director sees it, not after.

## What's strong: keep it

- **Account-wide gear in presets**, class separate from type, and cheap lead swaps. It's the right answer to a counter system.
- **"Things add."** One additive rule, an honest Combat Power, and "an optimized Legendary can beat a bare Mythical" proved in the simulation.
- **Stars that make a Common reach where a Mythical can't.** A good idea that only needs challenge 1's roll beside it.
- **The Void Shop's global five-minute clock,** with a limit per player and odds always shown. It's Grow a Garden's best pull, done fairly.
- **Health carries and keepers as decisions:** losing costs only the try.
- **The Tower as solo endgame:** fast floors, a run of about a minute, nothing lost on a disconnect.
- **The reveal's structure:** silhouette, then colour, then name; rarer is longer and never slower to skip.
- **No stealing, no paid chests, no Robux restocks:** the clean line that protects the game and the account.
