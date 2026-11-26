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
- **Odds** (official [24][25]): every outcome, in numbers that add up to 100 percent, shown before the purchase. A "Details" pop-up is accepted. A lone (i) icon isn't. **No outcome may be a pure loss** (official [30], read on 2026-11-24): "All possible outcomes for a paid random item must provide some benefit to the user; there cannot be a possible outcome which results in the user simply losing their payment." The docs page itself doesn't say it. An "Upgrade spell with some chance of working" is named as a paid random item, and so is currency bought with Robux ("This policy also applies to indirect purchases").
- **The check in code** (official [26]): `PolicyService:GetPolicyInfoForPlayerAsync`. `ArePaidRandomItemsRestricted` true means hide, replace or block. `IsPaidItemTradingAllowed` false means no trading of any paid item.
- **Where it's restricted** (official [25][28][29]): Australia, Belgium, the Netherlands, the United Kingdom and Brazil, with the list kept by Roblox.
- **The questionnaire** (official [27][28]): paid random items are declared in the Maturity and Compliance Questionnaire. Declared without the check in code, the game is closed to under-18s in the UK and Brazil.
- **Luck sold for Robux** (official [24][25]): a "probability modifier". Its effect is shown in numbers before purchase, and the shown odds update while it runs. Luck passes count.
- **Rerolls** (official [24]): a reroll token bought with Robux needs the odds shown before it's spent. A paid reroll of a shop's stock: asked on the forum, never answered.
- **Fusing and mutating** (official [2][24]): covered as items "consumed or exchanged in combination with other items to access random outcomes". A paid fuse or upgrade that can fail is allowed with its odds shown (read again 2026-11-19).
- **Read again 2026-11-24** from Roblox's creator-docs source, [Paid random items policy guidelines](https://create.roblox.com/docs/production/monetization/paid-random-items) (SOURCED):
  - **Pity systems are named** among the "probability modifier items", beside luck boosts and rate-up scrolls. Forge heat is one. While Credits are unsold it's outside the rule. Once they're sold, Reinforce is a paid random item, and its heat counts as a modifier: its effect is explained in numbers before the press, and the shown odds follow the heat (TR55 shows them from the heat already). CORRECTED: launch-design, section 3, called heat the shape that lets Credits be sold, and that holds only with this disclosure.
  - **Rounding:** shown odds must sum to exactly 100%. Long decimals may be rounded "to four or more decimal places lower than the decimal place with the first non-zero number", with a disclaimer such as "Probabilities are rounded; total of displayed individual probabilities may not equal 100%." `Rules.Odds` keeps hundredths of a percent, so Lyric's 13.0434% reads 13.04%, where the page asks for 13.043%. That's fine while nothing is paid, and must be fixed before Credits are sold: five significant figures for an inexact chance, with the disclaimer.
  - **Free randomness needs no odds:** "randomized virtual rewards in exchange for completing an action that does not involve the payment of Robux" are outside the rule. We show odds anyway (point 1 below).

**What we do,** as proposed in `docs/design.md`:

1. Every roll in the game shows its odds, paid or not. It's the honest design, and it means the rule is nearly met on the day the director wants to sell something.
2. Credits will be sold for Robux after launch (the director, 2026-11-19), and **none at launch** (2026-11-24, 10:50, `docs/decisions.md`). From the day they're sold, everything random that Credits buy, Reinforce and the Void Shop's shards included, is a paid random item: every outcome's odds shown before the press, and where `ArePaidRandomItemsRestricted` is true, Credits can't be bought (the page's treatment "Blocking the purchase … with an error message"), so players there use earned Credits only.
3. The Void Shop sells known things and one roll (D6, `docs/decisions.md`). A featured gear piece shows its lines before the press. The Standard shard rolls among its ground's Voidkin, and each outcome's odds show before the press. Under point 2 it counts as a paid random item once Credits are on sale. (Rewritten 2026-11-19 to match D6, which replaced the earlier "a shard's type names its fighter".)
4. Nothing random, no reroll and no luck is sold until this section is built in and the director has approved the design (the directive, section 15).

## Feeds that pay for watching

On 2026-08-25 Roblox restricted feeds that reward players for watching, for its Kids and Select programs (official: `docs/research/first-seconds.md`, [O4]). One of the director's four reference games was pulled over it and came back without the feed. We have no such feed, and none is planned.

## Text players write

Nicknames (`docs/ui.md`). Roblox requires any text a player writes to pass its text filter before another player can see it, filtered after it's submitted and never as it's typed. Stored text is filtered again when it's shown, and a game that shows unfiltered text can be moderated ([Text filtering](https://create.roblox.com/docs/ui/text-filtering), read again 2026-11-24 from Roblox's creator-docs source). VERIFIED: `TextFilterService` filters stored nicknames for each viewer as they're shown (`ForUser`, `GetNonChatStringForUserAsync`). A nickname that fails the filter is refused with a plain reason, and the Voidkin keeps its own name. Where another player sees a nickname (TR33's lead card), it goes through `ForUser` for that viewer. The Broadcast never carries one (`docs/design.md`, "Being seen"). **Display names** are shown as Roblox gives them: the text-filtering page's cases are text players type, generated words, outside content and stored text, and the `Player.DisplayName` page asks no filter (VERIFIED, both read 2026-11-24). That they need none is research's reading, since Roblox moderates them where they're set; no page says so in words.

## The content rating

From Roblox's [Content ratings](https://create.roblox.com/docs/production/promotion/content-ratings) page, read 2026-11-24 from its creator-docs source (SOURCED):
- **No rating, no audience.** A game without content ratings has its playability restricted for all players, so the questionnaire comes before any public release. An update that changes an answer means answering again.
- **Who sees what:** Minimal or Mild opens Roblox Kids (5 to 8) and Select (9 to 15); Moderate opens Select and standard Roblox (16+); Content May Vary is for age-checked 16+ only; Restricted is for age-verified 18+ only. Kids and Select also have their own publishing requirements.
- **Our answers today,** for the director, who fills it in (the most intense content a player can meet):
  - violence: yes, against **humans**, because the page counts anything that looks human, armoured or not, and the Shades, keepers and Voidkin are humanoid;
  - a **fantastical world**, **animated** style, **unrealistic** reactions (a Shade bursts into light);
  - shown **often and close up**;
  - **no blood, no gore**: blood is "visible bleeding liquid", gore "a graphic or disturbing depiction of injury", and rule 4 bans both.
- **The rating itself** comes from the questionnaire, not from the page: UNVERIFIED until the director runs it. "Slightly mature" (the directive) fits Moderate. Mild would also open Kids and Select, with their extra requirements.

## Rewards for engagement, invites and notifications

Read 2026-11-24 from the cloud: Roblox's creator-docs source and the Community Standards page.
- **Likes, favourites, follows, group joins:**
  - The Community Standards don't name them (VERIFIED, the page read whole). Their nearest line bans "deceptive, sensational, duplicative, or otherwise misleading content or metadata … used to drive discoverability, monetization, or engagement".
  - The forum reads the old Community Rules' ban on prize promotions, with promo codes exempt unless given "in exchange for" something like a thumbs-up, as barring a reward for a like (COMMUNITY, [2926286](https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286); no staff answer found). The Terms of Use refused the fetch.
  - Discovery's own advice is not to "rely on promotional monetary rewards to drive engagement" (SOURCED, [Discovery](https://create.roblox.com/docs/discovery)).
  - **Ours:** none of the four is ever rewarded, and no code is behind one. That's our design call, not a rule we've verified.
- **Invites:** allowed, and Roblox built the means (SOURCED, [Friend referral system](https://create.roblox.com/docs/production/promotion/referral-system)).
  - `Player:GetJoinData().ReferredByPlayerId` is filled for every kind of invite.
  - The page tells a game to reward both the inviter and the friend, and to show the reward on a banner in the invite menu.
  - A share of a capture (TR60) is not a join, and stays unrewarded.
- **Experience notifications** (SOURCED, [Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications), [User notifications](https://create.roblox.com/docs/cloud/guides/experience-notifications), [In-game HTTP](https://create.roblox.com/docs/cloud-services/http-service), [Secrets](https://create.roblox.com/docs/cloud-services/secrets)):
  - **Who and when:** only after 100 visits, to opted-in players aged 13 and over, one a day per player per game, and delivery isn't guaranteed (a spam filter reads engagement).
  - **The prompt:** `ExperienceNotificationService:PromptOptIn()`, after `CanPromptOptInAsync()`. Its text is Roblox's, it's shown at most once in 30 days, and the game may never require it.
  - **The words:** each string is made by hand in the Creator Dashboard (the director's account), up to 99 characters with parameters. It must be personal and actionable: no disguised ads, no false time pressure, no bait-and-switch gifts, no tricked purchases.
  - **The send:** a server calls Open Cloud's CreateUserNotification through `HttpService`, which supports it, with an API key read from the game's secrets store. Making the key and the secret is the director's (free). The builder writes the call rather than dropping in the Creator Store's "Open Cloud" package (rule 2).
  - **The catch for "battery full":** it happens while the player is offline, and only a running server can send. The send must come from any server through a due list (MemoryStore), or from an event another player causes. That's a design matter for launch: nothing is sent before the game is public.

## Not verified yet

- Whether the Terms of Use say anything about rewards for likes, favourites, follows or group joins (the page refused the fetch from the cloud; read it on the PC).

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
30. Community Standards, paid random items: <https://about.roblox.com/community-standards#roblox-economy-paid-random-items>
