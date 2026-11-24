# Collection and economy: making five fighters last, and a store with no luck in it

2026-11-24, a research study for the director, Quaestor, Faber and Modulo. Every proposal here is a proposal. Every number is a seed to tune by playing. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED (computed here), OPINION.

## Verdict

1. MEASURED: at launch the whole collection is expected to be complete after about 11 shards, near 35 minutes of play. Every reveal after that is a duplicate worth 1.43% of one fighter's base stats.
2. The games that last on a small cast don't add bodies fastest. They hang several honest goals on each body: an index, a rare form, a mastery track, an evolution. We have one (stars), and it is weak.
3. SOURCED: Roblox staff wrote on 2026-05-26 that a paid random item can have no outcome "where the user simply loses their payment". Reinforce as written is exactly that outcome the day Credits are sold. `docs/roblox-rules.md` misses this line.
4. Keep Credits unsold, and make everything Credits buy deterministic anyway. Then the store question becomes easy: sell status, space, looks and private servers, read every price from Roblox.
5. Cheapest strong move: an Index, the second form brought to launch with a shown counter, one Epic to chase, a sure-success Reinforce. About 20 builder hours plus one fighter. Nearly all of it needs the director's yes.

## 1. Ours, as designed

| Thing | What it is today | Source |
|---|---|---|
| What a player collects | 5 Voidkin at launch (Rook, Kirra, Pip, Watt Common; Lyric Rare) of 31 on paper. Regalia gear, account-wide. No Index screen is designed. | OBSERVED `docs/roster.md`, `docs/production-plan.md` "The cut line", `state-of-the-game.md` |
| Shard odds at launch | Standard pool 60/30/9/1 with unmade tiers dropped: Common 86.96%, Rare 13.04%. Each Common 21.74%, Lyric 13.04%. Enriched and Prismatic "always give Lyric", so their shelf lines wait. | OBSERVED `src/shared/Config/Shards.luau`, `docs/design.md` line 246; MEASURED |
| Shard income | Drops 0.04 x 450 kills = 18 an hour. Shop up to 2 x 12 stocks = 24 an hour for Credits. Today's three: 3 a day. | OBSERVED `Config/Drops.luau`, `Config/Shop.luau`, `Config/Goals.luau` |
| Duplicates | Copies become stars by hand: 1, 2, 4 ... 64 copies, 127 for seven stars. Each star +1.43% of base. Past seven, a copy sells for 10 (Common) to 100 (Rare) Credits. | OBSERVED `Config/Voidkin.luau`, `docs/design.md` "Voidkin" |
| Credits | From fights, overflow electricity, spare copies. Buy shop shards (rolled), featured gear (seen first), Reinforce tries (rolled), the Condenser, base and machine upgrades. The director, 2026-11-19: "we will sell credit". | OBSERVED `docs/design.md` "What the player holds", `docs/decisions.md` |
| Electricity | From bays. Buys shard breaking and the Condenser. Bays make 1.8 to 7.7 times demand at launch; the battery has no sink. | OBSERVED `docs/balance.md` "Electricity at launch" |
| Forge stones | From enemies, keepers, the Tower, the Condenser, the shop. Buy Reinforce tries. | OBSERVED `docs/design.md` |
| Reinforce | +1 a success to +30. 100% to +5, then 80% down to a 20% floor. "A failure spends its cost and keeps the level, with no pity" (the director's word, 2026-11-19, 03:10). | OBSERVED `Config/Reinforce.luau` |

How long each goal lasts (MEASURED from the configs above, drops only unless said):

| Goal | Arithmetic | Lasts |
|---|---|---|
| Own all five | Start with a starter and Watt. Missing two Commons (p = 0.2174 each) and Lyric (p = 0.1304). Coupon collector: 4.6 + 4.6 + 7.67 - 2.3 - 2.875 - 2.875 + 1.77 = 10.6 shards. | 35 minutes; under 20 with the shop |
| One Common to seven stars | 127 copies / (0.2174 x 18 = 3.9 an hour) | 32 h (14 h buying every shop shard) |
| Lyric to seven stars | 127 / (0.1304 x 18 = 2.35 an hour) | 54 h (23 h with the shop) |
| What all seven stars give | 7 x 1.43% | +10% of one fighter's base. `design-review.md`: stars are 3.5% of a full build |
| One gear piece to +30 | 5 + 21.3 + 80 = 106 expected tries for 30 levels; Credits 33,895 x G expected against 7,875 x G if every try landed | 4.3 times the sure cost, with wide spread |
| The ground itself | `docs/balance.md` pace seed for ground 1 | 1 h. The 57 h figure is six grounds; launch has one |

## 2. How collection games keep the chase alive

**F1. Launch rosters are far bigger than ours, and we can't match them.**
- COMMUNITY: Genshin Impact 1.0 had 22 playable characters, then about 2 per six-week version (12 over versions 1.1 to 1.6). https://www.oneesports.gg/genshin-impact/genshin-impact-characters-rarity/
- SOURCED (press release): AFK Arena launched with "over 40 heroes from 6 factions". https://www.tweaktown.com/pressrelease/13001/afk-arena-awaits-adventurers/index.html
- COMMUNITY: Marvel Snap launched with over 170 cards. Pokémon TCG Pocket's first set held 286 (226 plus 60 secret). https://bulbapedia.bulbagarden.net/wiki/Genetic_Apex_(TCG_Pocket) (read through search; the page itself returned 403)
- COMMUNITY: Arise Crossover held 18 collectible units across four worlds per one undated guide (the page returned 403; read through search).
- Not found: the launch counts of Anime Vanguards, Anime Last Stand, Anime Defenders, Pet Simulator 99, Sol's RNG and Steal a Brainrot. I won't guess them.
- For us: five is below every count I could confirm. A 3D fighter costs us what a card costs them many times over, so the answer isn't 22. It's F2 to F5.

**F2. Mature rosters grow at the top and through forms, not at the bottom.**
- COMMUNITY: Anime Vanguards today lists 339 obtainable units: Rare 10, Epic 12, Legendary 10, Mythic 117, Secret 84, Exclusive 96, Vanguard 10. 146 have an evolved form. https://robloxdatabase.com/guides/anime-vanguards-units/
- COMMUNITY: its major updates added about 6 to 13 units each, every few weeks (Update 1 on 2024-10-22, Update 4.0 on 2025-02-24, each about 12).
- For us (`docs/roster.md`): the paper roster has 14 Commons and Uncommons of 31. The low tiers are where the reference spends least. If a sixth fighter is affordable, it should be the Epic, not a fifth Common.

**F3. One body, several collectibles: the honest multipliers.**
- COMMUNITY: Anime Vanguards rolls a shiny look at 1.5% per summon; a pass doubles it. https://seemeta.com/en/anime-vanguards/summon-rates
- COMMUNITY: Pet Simulator 99 lists over 2,000 pets "not counting gold, rainbow, or shiny versions"; a rainbow is made from 10 goldens, so variants are also the duplicate sink.
- COMMUNITY: Steal a Brainrot stacks mutations and traits on one model, and pays rewards for Index completion. `design-review.md` has the Grow a Garden mutation rates.
- SOURCED: Pokémon TCG Pocket turns extra copies into "flair", a cosmetic on the card. https://www.pokemon.com/us/strategy/a-guide-to-collecting-cards-and-using-wonder-picks-in-pokemon-trading-card-game-pocket
- For us: D4's second form is this lever. Our pillar ("Nobody is a recolour") puts a limit on it: the form is the same somebody in another light. It gets its own Index slot under its Voidkin, and never counts as a new Voidkin.

**F4. Duplicate systems: cosmetic and bounded are liked; power behind doubling copies is resented.**
- COMMUNITY: Genshin's constellations (copies unlock kit power) are its most criticised system: "thousands of dollars" to max one character. https://tvtropes.org/pmwiki/pmwiki.php/ScrappyMechanic/GenshinImpact, https://www.pushsquare.com/news/2025/08/controversial-genshin-impact-update-allows-whales-to-break-the-level-cap-here-are-the-redemption-codes
- COMMUNITY: Marvel Snap has no packs. Upgrading the look of cards you own raises a Collection Level that pays out new cards. Praised early, criticised once rewards past the early levels turned random and slow. https://www.pcgamer.com/the-state-of-marvel-snap-in-2023-super-quick-card-battles-super-slow-progression
- COMMUNITY: AFK Arena's ascension eats same-name and same-faction copies; most heroes end as "fodder".
- For us (`Config/Voidkin.luau`): our stars are the mild version, by the director's design ("not game changing"). The cost is that a duplicate reveal feels like nothing. The fix is to show progress and to add a guarantee (proposal b), with the star numbers left alone.

**F5. Pity is expected, and its distance matters more than its existence.**
- COMMUNITY: Anime Vanguards banner odds Rare 75.5%, Epic 20%, Legendary 4%, Mythic 0.5%; a Legendary guaranteed by 50 summons, a Mythic by 400, none for Secrets. Sources disagree on the Secret rate (0.004% or 0.04%). https://bloxodes.com/wiki/anime-vanguards/banners
- COMMUNITY: its top trait is 0.1% a reroll with a 1,500-reroll guarantee, and rerolls are sold. `docs/research/long-grind.md` shows where that road ends: 745,280 concurrent players in April, 1,046 in November.
- COMMUNITY: Lost Ark's upgrade failures fill a gauge that guarantees the next try at 100%, and gear never breaks. It is still the game's most resented system where the gauge is far away. https://maxroll.gg/lost-ark/resources/gear-honing-system, https://upcomer.com/smilegate-is-killing-lost-ark-through-its-unfair-honing-system
- For us: a counter that sits 400 away is decoration. Ours should land inside one or two sessions.

**F6. Trading multiplies risk, and Roblox gates it.**
- SOURCED: "When `IsPaidItemTradingAllowed` is true, the user can trade virtual items that they purchased with game currency or Robux." Staff add that false "restricts trading of all paid items for ineligible users, not just items obtained through random chance". https://devforum.roblox.com/t/4654622
- COMMUNITY: Pokémon TCG Pocket launched trading behind a token cost, met a backlash, and gave tokens away within days. https://www.gamesradar.com/games/pokemon/pokemon-tcg-pocket-players-are-furious-at-the-new-trading-system-they-should-probably-remove-trading-card-game-from-the-title-screen
- COMMUNITY: scams, duplication and account theft follow tradable valuables on Roblox. https://blog.talosintelligence.com/roblox-scam-overview/
- For us (AGENTS.md, "Fighters are valuables"): no trading at launch. OPINION, and it agrees with what is designed.

## 3. What Roblox lets us sell, as written today

The rule text (SOURCED, https://create.roblox.com/docs/production/monetization/paid-random-items, page dated 2026-11-23):
- "certain requirements may apply to random items purchased directly or indirectly with Robux. This includes random items purchased with paid in-game currency." Its own example: "Paying Robux to buy gems or spin tickets that are spent at a prize wheel".
- Named types include **enhancement items** ("Upgrade spell with some chance of working") and **probability modifier items** ("Luck boosts", "Pity systems", "Enhanced resource drops").
- "you must indicate all possible outcomes and the actual numerical odds". An icon alone is "not sufficient"; odds "must sum to exactly 100%".
- "When `ArePaidRandomItemsRestricted` is true, the user cannot interact with paid random item generators, either through Robux directly or game currency bought with Robux."
- Free of the rule: "randomized virtual rewards in exchange for completing an action that does not involve the payment of Robux or other in-game currency".

The staff post, "Clarifying Requirements for Paid Random Items", 2026-05-26 (SOURCED, https://devforum.roblox.com/t/4654622):
- "All possible outcomes of a Paid Random Item must provide some benefit. There cannot be an outcome where the user simply loses their payment."
- "If you bundle a random item into a paid pack or single transaction, this makes the entire bundle a Paid Random Item."
- Odds modifiers "must have their effects numerically disclosed, and displayed odds must update dynamically".
- "Yes, luck gamepasses count as Paid Random Items". A paid shelf that reloads its content counts too.
- Not a paid random item: a chest "earned through gameplay that can only be opened through gameplay or earned currency"; a paid boost to rewards in skill play; a paid item whose randomness only changes its look.
- "your game will be removed and your account will be suspended."
- Not answered by staff before the thread closed (2026-10-16): whether a 2x-currency pass makes that currency "paid"; whether earned and bought currency can be told apart; whether a timed shop whose stock is seen before buying counts.

For us (`docs/roblox-rules.md`, Quaestor):
- Its line that the page "says nothing on an outcome that gives nothing" is true of the docs page and wrong as a conclusion. The staff post says it twice. Correct it.
- Its open question on a Credits-income pass is still open at Roblox. Treat it as a no until staff answer.
- A paid pass track can never hand out shards, or the whole track becomes a paid random item.

What sells without luck (all create.roblox.com pages dated 2026-11-23 unless said):

| Tool | Current fact | For us |
|---|---|---|
| Passes and products | COMMUNITY prices: Anime Vanguards VIP 299, show-all-units 599, +50 unit slots 149, premium season track 799 (25 levels). Blox Fruits 2x Money 450, 2x Mastery 450. Reseller and guide pages; confirm in game. https://www.sportskeeda.com/roblox-news/anime-vanguards-update-1-ice-fire-battlepass-all-rewards-premium-price, https://playgama.com/blog/game-faqs/how-much-does-2x-money-cost-in-blox-fruits/ | Space and display passes sit at 149 to 599. Their luck and drop passes are probability modifiers under today's rule; not for us |
| Private servers | SOURCED: monthly fee or free; the game must be public; changing the price cancels every subscription. Roblox Plus members get paid servers free and "You still earn up to 100 Robux per subscriber each month". https://create.roblox.com/docs/production/monetization/private-servers | A clean product once the game is public. Pick the price once |
| Roblox Plus | SOURCED: launched 2026-04-30. Members get 10% off (20% from month 3); "Roblox covers this discount". Hard-coded prices show wrong. https://devforum.roblox.com/t/4567894 | Faber: every price label reads `GetProductInfoAsync`. Same fix as `retention-and-discovery.md` finding 19 (Managed Pricing) |
| Creator Rewards | SOURCED: replaced Premium Payouts on 2025-07-24. "Creators earn 5 Robux each day if their experience is one of the first three an Active Spender plays for 10+ minutes." https://devforum.roblox.com/t/3777628 | Pays for a daily 10-minute visit. Today's three and the Condenser tray already aim there |
| Subscriptions | SOURCED: Robux (from 49, 70% payout) or local currency; battle passes may be sold as one. https://create.roblox.com/docs/production/monetization/subscriptions | Later, as the season track's premium lane |
| Season pass | SOURCED: about a month, about 10 tiers to start, a week's rest between, a new exclusive as the last reward. https://create.roblox.com/docs/production/game-design/season-pass-design | After launch, with the 2 to 4 week updates. `docs/design.md` already lists "a pass" as not at launch |
| Rewarded video | SOURCED: the reward must "Not be a randomized item" and "Not inflate currency"; needs a public game with 2,000 monthly visitors. https://create.roblox.com/docs/production/promotion/rewarded-video-ads | Not available to us now. If ever: a time skip on one break, capped daily |
| Top earners | COMMUNITY: the platform's top earner in January 2026 was a brainrot collection game; the top PC shooter sells skins. https://www.pcgamesn.com/roblox/highest-revenue-jan-2026 | Looks and status carry a store. `retention-and-discovery.md` finding 20: 3.8% of players ever spend |

## 4. Frank critique of our current state

- We designed the reveal as "the signature moment" and then gave it eleven meaningful uses. From minute 35 it plays 18 to 42 times an hour to say "another Rook".
- `docs/roster.md` already says it: without an Epic and a Legendary "there's nothing to chase". The cut line kept the sentence and cut the fighters.
- A Common's seventh star takes 32 hours of duplicates and gives 10%. That is a long wait for a small number, with nothing to see on the way.
- The directive calls the Fighter Index established identity. No doc designs one (`state-of-the-game.md`).
- Credits touch randomness in two places (shop shards, Reinforce) and one place I couldn't settle (what the Condenser's Credits buy; Faber should check). Selling Credits today would make all of it paid random, in five restricted markets, on the director's own account.
- Reinforce is on 13.5% of the build (`design-review.md`) and costs 4.3 times its sticker price in expectation. A player at the 20% floor loses four tries in five. The chance is shown, which is honest, but it is still the worst-feeling press in the game.
- Nobody knows what a fighter costs at the new bar (`design-review.md`). The asset entries give first-bar clock readings only: sheet 0.5 to 1.8 h, model 0.25 to 1.1 h, clips 0.7 to 6 h, a signature look about 12 h over its rounds for Rook (OBSERVED `docs/asset-requests.md` AR1, AR4, AR10, AR11, AR26). That bar was rejected. OPINION: plan 15 to 25 hours a fighter until AR59 and AR60 close and give a measured figure.

## 5. Proposals

**(a) The launch collection target.** OPINION. Needs the director's yes: it touches "5 voidkins for the launch not 8" (2026-11-17), D4's "post early access" (2026-11-18) and "evolution isnt for now" (2026-11-14).

| Layer | Count at launch | Cost (rough) | Why it is honest |
|---|---|---|---|
| Voidkin | 6: the five plus Marigold (Epic). 8 with Sable and Crane only if AR59/AR60 measure under about 15 h each | One fighter at the new bar, unmeasured | A real somebody. Brings the Enriched shelf line back (`docs/design.md` line 246) |
| Index | 1 screen: every Voidkin, its forms, stars, where it comes from, the odds | Faber about 6 h, a UI pass from research | Makes the collection visible. `taichi-panda-study.md` asks that a shard say where it came from |
| Second form | 1 per Voidkin, a slot under its Voidkin. No stats, earned only, never sold | Modulo about 1 h each, Faber about 4 h (`design-review.md` challenge 1) | Same fighter in another light, shown as that |
| Mastery track | 5 ranks per Voidkin from kills led and hours worked. Pays a title, a plate rim, and at rank 5 one small shown upgrade to its signature | Faber about 8 h once, Quaestor 2 h of numbers, no new model | Rewards playing a fighter, not owning copies. The upgrade is tier 2: it changes balance |
| Evolution | Rook's, as designed, after launch, once judged | Half a fighter, OPINION | New parts, new kit. Keep the roster's own line: one before a second is promised |

Things worth getting: 5 fighters and 35 stars today; 6 fighters, 6 forms, 42 stars and 30 mastery ranks under this table. A working name for the track ("Bond") still needs the IP-list check. Never sold, never rerolled for Credits: traits.

**(b) Duplicates and pity.** OPINION. Tier 3.
- Keep the star numbers; they are the director's. At every duplicate reveal, show "copy 3 of 4 to the next star" so the moment reads as progress.
- **A shown guarantee per shard grade:** each break that gives no new Voidkin adds 1 to a counter beside the odds. At 60, the next break of that grade gives a Voidkin the player lacks, if its pool holds one. Seed 60.
- **The same for the second form:** seed 1.5% a break, guaranteed by break 150 for the Voidkin revealed on it.
- Shards stay earned only, so this is outside the paid rule. We disclose the counter anyway ("transparent as glass", the director, 2026-11-12). If Credits were ever sold, a pity counter is a named probability modifier and the shown odds must move with it.
- Copies past seven stars keep selling for Credits. No new currency: `state-of-the-game.md` already counts about 50 proper nouns.

**(c) Hours to complete, by roster size.** MEASURED from `Config/Shards.luau` and `Config/Drops.luau` at 18 shards an hour, drops only. With every shop shard bought it is about 42 an hour; divide by 2.3.

| Roster | The hard part | Expected | Unlucky 1 in 20 | With the guarantee at 60 |
|---|---|---|---|---|
| 5 (today) | Lyric at 13.04% | 10.6 shards, 35 min | under 2 h | no change |
| 6 (+ Marigold) | Marigold: 1 / (60 + 9 + 1) = 1.43% of a Standard | 70 shards, 3.9 h | 208 shards, 11.6 h | 40 shards expected, 60 at worst: 3.3 h |
| 8 (+ Sable, Crane) | Marigold at 1% of a Standard: 100 shards. All seven Standard-pool fighters: 101.6 shards | 5.6 h | 298 shards, 16.6 h | 45 expected, 3.3 h at worst |
| 8, Crane | Enriched only, 4%: 25 Enriched shards | not computable: no Enriched income is set for launch | 73 Enriched | set the Enriched counter near 20 |
| 31, six grounds | `docs/balance.md` sim, not mine | 23 Voidkin by day 30 at 0.5 h a day | | |

Second forms at 1.5%: one given Common's form needs 1 / (0.2174 x 0.015) = 307 shards, 17 h. All five forms by coupon collector: 817 shards, 45 h on drops, 19 h with the shop. With the counter at 150, a form lands at worst every 8.3 h of drops. This is the launch game's long chase, and it costs about 9 maker hours.

**(d) A store with nothing random behind Robux.** OPINION, building on research's proposal of 2026-11-17 in `docs/decisions.md`. The store's design is its own piece, approved by the director (tier 3). Prices are seeds, set in Roblox and read at runtime.

| Item | What it is | Why a player buys | Seed price |
|---|---|---|---|
| Founder's Mark | A pass sold only during early access: a title, a gold rim on the name plate, a plate on the base gate | Status with a true reason for scarcity | 399 |
| Bag space | More gear and copy slots, for good | The 18 to 42 reveals an hour fill a bag | 149 |
| Loadout presets | Extra saved gear sets | Convenience for Tower and grounds builds | 99 |
| Reveal lights | The Breaker's reveal in another colour and sound set, each previewed before buying | The moment every visitor on the Strip sees | 149 to 249 each |
| Yard themes | Bay lights, plinths, gate trim for the base | Eight bases face each other across the Strip | 149 to 299 each |
| Private server | A monthly server, once the game is public | Friends, quiet farming; Plus members bring payouts | 50 to 100 a month, chosen once |
| Season track (later) | A month, 10 tiers, cosmetics and fixed items only, never a shard or a stone | A dated reason to return, tied to each update | 399 |

Never sold: Credits, shards, stones, luck, drop or Credits-income multipliers, restocks, chambers, a Voidkin, the second form. A 2x Credits pass waits for a staff answer and for (e).

**(e) Reinforce.** OPINION. Needs the director's yes: the failure roll is their word of 2026-11-19.
- **Recommended: every press succeeds, and the price carries the old odds.** Cost of a level = today's cost / today's chance. +6 costs 1.25 times, +10 costs 2.2 times, +15 and up cost 5 times. The expected sink is unchanged (33,895 x G Credits and the same stones for +30). The variance is gone, and so is the rule problem. Faber: about 2 h in `Config/Reinforce.luau` and `Rules.Reinforce`, with logic cases.
- **If the director wants the gamble kept:** a shown fail-stack. Each failure adds +10 points to the next try's shown chance. At the 20% floor that is 2.96 expected tries where today takes 5, and 9 at worst. Costs must rise about 1.7 times to hold the sink. Keep Credits and stones unsold, since staff haven't said a pity point counts as "some benefit".
- **If nothing changes:** it stays legal only while neither Credits nor stones can be bought, directly or in any bundle. Write that sentence into `docs/roblox-rules.md` beside the staff quote.

## Top 5 to act on

| # | Action | Who | Cost | Director's yes? |
|---|---|---|---|---|
| 1 | Make Reinforce sure-success at cost / chance, and add the staff "no outcome where the user simply loses" quote to `docs/roblox-rules.md` | Faber, Quaestor | 2 h code, 15 min doc | Yes (reverses 2026-11-19, 03:10) |
| 2 | Hold Credits unsold; approve the store piece from table (d); read every price from Roblox | The director, Quaestor writes, Faber builds later | 2 h to write; passes about 1 h each to build | Yes (reverses "we will sell credit") |
| 3 | Build the Index, bring the second form to launch as a slot under each Voidkin, with shown counters (60 and 150) | Faber, Modulo, research's pass | Faber about 10 h, Modulo about 1 h a Voidkin | Yes (D4 said post early access) |
| 4 | Make Marigold the sixth launch fighter and reopen the Enriched line, once AR59/AR60 give a measured cost | Modulo, Faber | One fighter at the new bar: unmeasured, plan 15 to 25 h | Yes (changes "5 not 8") |
| 5 | A five-rank mastery track per Voidkin, numbers first in `docs/balance.md`, name through the IP list | Quaestor, then Faber | 2 h numbers, about 8 h build | Tier 2 for the track; yes for the signature upgrade |

## Not fetched, not verified

- Returned errors: the Anime Vanguards fandom wiki (402), wiki.vanguards.gg (403), two Sportskeeda pages (403), Bulbapedia (403), game8 (402), one Pro Game Guides patch page (403). Their facts above came through search snippets or other pages, and are labelled COMMUNITY.
- Not found anywhere: launch roster sizes for the six Roblox games named in F1; Pokémon TCG Pocket's pack-point exchange costs.
- One wiki-style page on Anime Vanguards contradicted the others on rates and pity. I left it out.
- The reference prices in section 3 come from guides and reseller pages. Check them in game before quoting them to anyone.
- Not checked in our repo: whether the Condenser's output is rolled; how Enriched shards would be earned at launch; the `G` multiplier's value on Lantern Row.
