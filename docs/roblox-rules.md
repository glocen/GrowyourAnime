# Roblox's rules for this game

What Roblox requires of this game, and what we do about it. Read on 2026-11-09 by a research subagent from the pages linked at the end. Labels: (official) Roblox's own pages, (sourced) press and established guides, (inferred) our reading. The pages were read through a summarising tool, so open a page again before quoting it word for word. Read this file before fighters' sheets, anything sold, the game page and publishing.

## Other people's characters

- **The terms** (official [1][2][3]): what we upload "must not include third party intellectual property ... unless you have permission". A valid claim takes the game down and puts a warning on the account. It reopens only with the owner's permission or a counter-notice, 10 to 14 business days. Repeat infringers lose their accounts, and Robux in a closed account "become invalid". Roblox may also delete what it suspects, without a claim.
- **Who judges** (inferred from [9][10]): Roblox acts on the owner's claim. It doesn't judge likeness itself.
- **Owners can scan** (official [7][9][10]): since July 2025 the License Manager lets a rights holder find games by keywords and by images, then send a licence offer or ask for removal. A new name weakens the keyword match. The image match and a hand-made request remain (inferred).
- **The record** (sourced [19][20][22]): no case found of a game removed for renamed lookalikes as such. Every documented removal followed a claim tied to one property: three large anime games went down around 2023-12-22 on a claim reported to come from the holder of one licensed game, with one estimate of 4 to 5 million dollars of yearly spend removed. A pirate-themed game was removed 19 hours after launch in July 2025 and restored in August. One football game with about 4 billion visits was licensed instead of removed [14][15]. No takedown found from Shueisha, Toei, Kadokawa, Aniplex or Bandai.
- **How many strikes** (official [3][4]): not stated today. A 2019 post gave three, and is now marked outdated. What happens to a group: not found.

**What we do:** `docs/decisions.md`, "Fighters".

## Licences: the route into NEXT

- **How** (official [9][12]): Creator Hub, Licenses. Pick the game, pitch it, and the holder approves, refuses or sets conditions. The game must be public. A holder may ask for a seven-day average of 1,000 or of 25,000 daily players, and may cap the maturity label. Some ask for none [8].
- **The price** (official [10]; sourced [13]): a share of revenue the holder sets, from 0 to 95 percent, typically 10 to 25, taken from the payout automatically. No upfront fee is stated anywhere (so none: inferred).
- **Kinds** (official [9][12]): the whole game; only in-game sales of the licensed items (new on 2026-09-12); Marketplace items. The holder can end it with 30 days' notice, and the IP must then come out.
- **What's on offer** (official [7][8][12]; sourced [16][17]): every anime or manga listing found is Kodansha's (Blue Lock, That Time I Got Reincarnated as a Slime, Fairy Tail, Attack on Titan, Knights of Sidonia, Ghost Encyclopedia), plus Pop Team Epic from Takeshobo. Nothing found from Shueisha, Toei, Kadokawa or Aniplex, who hold the biggest fighting series. The live catalog needs a sign-in and wasn't opened.

**What we do:** nothing until the game is public and has players. NEXT stays reserved in the data, and the in-game-sales licence is the kind to ask for (`docs/decisions.md`).

## Paid random items

Tightened on 2026-05-26: for a game that doesn't comply, "your game will be removed and your account will be suspended" (official [25]).

- **What counts** (official [2][25]): a random item bought with Robux, or with anything Robux buys. A bundle with one random item in it counts whole. Random rewards that can't be bought, directly or indirectly, are outside the rule.
- **Odds** (official [24][25]): every outcome, in numbers that add up to 100 percent, shown before the purchase. A "Details" pop-up is accepted. A lone (i) icon isn't. The page, read again on 2026-11-19, says nothing on an outcome that gives nothing; research's earlier "no pure loss" isn't on it. An "Upgrade spell with some chance of working" is named as a paid random item, and so is currency bought with Robux ("This policy also applies to indirect purchases").
- **The check in code** (official [26]): `PolicyService:GetPolicyInfoForPlayerAsync`. `ArePaidRandomItemsRestricted` true means hide, replace or block. `IsPaidItemTradingAllowed` false means no trading of any paid item.
- **Where it's restricted** (official [25][28][29]): Australia, Belgium, the Netherlands, the United Kingdom and Brazil, with the list kept by Roblox.
- **The questionnaire** (official [27][28]): paid random items are declared in the Maturity and Compliance Questionnaire. Declared without the check in code, the game is closed to under-18s in the UK and Brazil.
- **Luck sold for Robux** (official [24][25]): a "probability modifier". Its effect is shown in numbers before purchase, and the shown odds update while it runs. Luck passes count.
- **Rerolls** (official [24]): a reroll token bought with Robux needs the odds shown before it's spent. A paid reroll of a shop's stock: asked on the forum, never answered.
- **Fusing and mutating** (official [2][24]): covered as items "consumed or exchanged in combination with other items to access random outcomes". A paid fuse or upgrade that can fail is allowed with its odds shown (read again 2026-11-19).

**What we do,** as proposed in `docs/design.md`:

1. Every roll in the game shows its odds, paid or not. It's the honest design, and it means the rule is nearly met on the day the director wants to sell something.
2. Credits will be sold for Robux (the director, 2026-11-19, `docs/decisions.md`). So everything random that Credits buy, Reinforce and the Void Shop's shards included, is a paid random item: every outcome's odds shown before the press, and where `ArePaidRandomItemsRestricted` is true, Credits can't be bought (the page's treatment "Blocking the purchase … with an error message"), so players there use earned Credits only.
3. The Void Shop sells known things and one roll (D6, `docs/decisions.md`). A featured gear piece shows its lines before the press. The Standard shard rolls among its ground's Voidkin, and each outcome's odds show before the press. Under point 2 it counts as a paid random item once Credits are on sale. (Rewritten 2026-11-19 to match D6, which replaced the earlier "a shard's type names its fighter".)
4. Nothing random, no reroll and no luck is sold until this section is built in and the director has approved the design (the directive, section 15).

## Feeds that pay for watching

On 2026-08-25 Roblox restricted feeds that reward players for watching, for its Kids and Select programs (official: `docs/research/first-seconds.md`, [O4]). One of the director's four reference games was pulled over it and came back without the feed. We have no such feed, and none is planned.

## Text players write

Nicknames (`docs/ui.md`). Roblox requires any text a player writes to pass its text filter before another player can see it, filtered for the viewer, and a game that shows unfiltered text can be moderated. The builder reads the current page before building it: <https://create.roblox.com/docs/ui/text-filtering>. A nickname that fails the filter is refused with a plain reason, and the Voidkin keeps its own name. (official page, from memory: reread at build)

## Not verified yet

- The maturity label a game of fights without blood gets. Before the game page.
- Whether a shard that names its fighter, but whose mutation and trait are rolled, counts as a random item when sold for Robux. Before anything is sold.
- Whether a pass that raises credit income counts as paying for a roll, once every break rolls a mutation and credits buy shards. Before anything is sold.
- The strike count, and what a strike does to a group.

## Links

1. Terms of Use, effective 2026-11-01: <https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use>
2. Community Standards: <https://about.roblox.com/community-standards>
3. DMCA guidelines: <https://create.roblox.com/docs/production/publishing/dmca-guidelines>
4. Staff, 2019, marked outdated: <https://devforum.roblox.com/t/more-information-about-our-dmca-policy/255884>
7. Roblox, 2025-07: <https://about.roblox.com/newsroom/2025/07/roblox-launches-new-licensing-platform-for-experiences>
8. Staff, the Licenses catalog: <https://devforum.roblox.com/t/introducing-the-licenses-catalog-for-game-changing-ip-partnerships/3816457>
9. Licensing, for creators: <https://create.roblox.com/docs/ip-licensing/creators>
10. License Manager: <https://create.roblox.com/docs/ip-licensing/license-manager>
12. Staff, 2026-09-12: <https://devforum.roblox.com/t/licensing-platform-update-in-game-sales-license-and-3-new-kodansha-ips/4868288>
13. TheWrap: <https://www.thewrap.com/roblox-opens-ip-license-manager-creators-partners>
14. Tubefilter, 2025-11-12: <https://www.tubefilter.com/2025/11/12/roblox-ip-licensing-program-expansion/>
15. Tubefilter, 2025-07-15: <https://www.tubefilter.com/2025/07/15/roblox-ip-platform-netflix-blue-lock-creator-revenue-share-transformative-works/amp/>
16. Mogura VR: <https://www.moguravr.com/rdc2026-lc/>
17. Phile Web: <https://www.phileweb.com/news/hobby/202609/10/8492.html>
19. Pocket Tactics: <https://www.pockettactics.com/anime-adventures/private>
20. Naavik: <https://naavik.co/digest/unlicensed-ip-reckoning/>
22. Distractify: <https://www.distractify.com/p/what-happened-to-vox-seas>
24. Paid random items: <https://create.roblox.com/docs/production/monetization/paid-random-items>
25. Staff, 2026-05-26: <https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622>
26. PolicyService: <https://create.roblox.com/docs/reference/engine/classes/PolicyService>
27. Content maturity: <https://create.roblox.com/docs/production/promotion/content-maturity>
28. Staff, UK: <https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183>
29. Brazil: <https://en.help.roblox.com/hc/en-us/articles/48706630819476-Brazil-Digital-ECA-Updates>
