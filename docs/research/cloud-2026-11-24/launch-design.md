# The launch game, from the ground up (2026-11-24)

Faber, from a cloud session. It answers the director's words of 11-24. On the economy: "do you think we should do some deep overhaul on the game currency credit and electricity maybe even remove electricitty as a whole and change it with something else or keep same for credit or keep and add a new one". On the scope: "imagine the game from the ground up, global messages, chests for everything we have at launch etc reallly a full fleshed out games you can even add stuff". It also answers their four replies of the same day (section 12).

**Everything here is a proposal.** Each line says whose yes it needs. The tiers are `AGENTS.md`'s, "Design changes". Nothing touches the north star's pitch or pillars. Evidence labels: OBSERVED (read in code or docs), COMPUTED (worked from the real Config, in Lune or by hand), SOURCED (a page, linked), MODEL (a seed or the simulation, not play), OPINION. Every rate rests on the 450-kills-an-hour seed, which no one has timed (`README.md`, item 1).

## 1. The answer, in eight lines

1. **Keep both currencies.** Don't remove electricity, and don't add a third currency or a premium one.
2. **Change what electricity is for.** Today it's a machine speed that nobody is ever short of. Make it what your collection makes and your fighter spends: workers grow by the power they make, and the battery charges the next run.
3. **Sell no Credits at launch.** Sell only sure things, for Robux directly.
4. **Keep Reinforce's chance, and add forge heat:** every failure fills a bar, and a full bar makes the next try succeed. That's the genre's answer, and the only shape that would let Credits be sold later.
5. **The machines' ceiling at base level 3: 15, not 6.** Each base level then brings a new stage of the base, and the Breaker keeps its third chamber.
6. **A chest for everything at launch.** An Emblem Case, a Jewel Pouch and a Forge Crate join the four gear chests, so every launch item has a source and an opening. A shard stays its own chest, and the Breaker is its show.
7. **The Broadcast.** What's worth telling is told: to this server, and the rarest to every server. Never anything bought, failed or typed.
8. **Seven small additions** that make the game feel complete (section 10). The biggest are boards on the Strip, a welcome week and codes.

## 2. The currencies

### What's true today

| | Comes from | Goes to | The fact that matters |
|---|---|---|---|
| **Credits** | fighting: 7,069 in the first hour (MODEL, sim `earned(0,1)`); at most 7,816 an hour on Normal and 18,007 on Hard at the seed, 63 to 68% of that after cooldowns. Also overflow, copies past seven stars, salvage, the Tower | the base, the machines, Reinforce, the shop | the hub, and it works. Every sink is a number the player wants (COMPUTED, the economy ledger) |
| **Electricity** | bays: Watt 18 kW, Rook, Pip and Lyric 12, Kirra 6 at level 1 | the Breaker, the Training machine, the Condenser; overflow sells at 0.5 Credits a kWh | **nothing outside the base reads it** (OBSERVED: no fight, stage, Tower or drop requires Power). Online it's always surplus: 79 kW made against 15 to 28 asked on day 3 (COMPUTED). It only matters while away, and no screen says so |
| **Research Points** | nothing | nothing | orphaned until the Lab (OBSERVED, `Profile.luau`) |
| **Forge stones** | drops, dares, the Condenser, the Tower | Reinforce | High stones come only from Tower floor 78 up, and an expected lead climbs 31 at level 20 (`balance.md`, "The Tower"), so +21 to +30 has no source at launch (COMPUTED) |

Two of this morning's studies had these wrong, and they're fixed with this file (section 11): the Condenser takes no Credits but its own levels, the battery does have a sink (while away), and the machines' 791,940 Credits are 44 to 101 hours of fighting at the seed.

### The four ways the director named

| Way | What it means | What it gains | What it costs | Verdict |
|---|---|---|---|---|
| **Remove electricity**, the bays make Credits | the standard tycoon: workers print money | one number fewer, no Power screen | the pitch's own line ("make the electricity the Breaker runs on") and pillar 3. The bays become a second Credits tap beside fighting, which the practitioners quoted call losing control of the soft currency (SOURCED, research hand-back). The machines' art loses its meaning. It's Bee Swarm's and Grow a Garden's loop, the least distinctive on Roblox | no |
| **Replace it** with another resource | the same role under a new name | nothing the rename itself does | words, art, code and the pitch, for the same hole | no |
| **Keep it and add a currency** | a third number, or Robux gems | a lever to sell | three numbers on a phone HUD. Top Roblox games show two numbers and a meter (RECALLED). Roblox's own guide keeps extra currencies for events (SOURCED, Creator Hub, "Balance virtual economies"). A premium currency that ever buys a roll is the paid-random leak | no |
| **Keep it and make it matter** | electricity is the base's half of the game, as Credits are the fight's | pillar 3 becomes true in the rules | two small rules, below | **yes** |

The director's own founding words point the same way. The directive, section 6: "Do not invent a complicated electrical engineering simulator unless it demonstrably improves the game", and "The electricity mechanic should provide understandable choices and satisfying progression, not excessive management". None of the nine games studied keeps a resource that only changes speed (SOURCED, research hand-back, Q1). Those whose base output feeds the fighter, as ours should, are Monster Hunter's Meowcenaries and Pokémon Sleep.

### The design: two currencies, two halves, each feeding the other

- **Credits are what fighting earns.** They're on the HUD and spent on the base, the machines, Reinforce and the shop. Nothing changes.
- **Electricity is what your collection makes.** It's a meter, never a wallet number: the Mill's buckets and the battery's cells. It's spent on five things, two of them new:
  1. breaking shards (as built);
  2. the Training machine and the Condenser (as built);
  3. **new: the workers grow by working.** A worker earns experience for every kWh it makes, so a higher bay level grows its worker faster too. The design already says it ("Each role earns its own experience", `design.md`, "Voidkin"), and no rule pays it (OBSERVED). A seed to start from: about 100 experience a kWh, so a 12 kW worker earns half what the Training machine gives (43 a minute in code). Research fits it with the simulation.
     - Why it matters: at base level 3 every Voidkin but the lead works (OBSERVED: the Training machine is never a worker). So the whole bench grows, and the second and third leads a counter system asks for are always nearly ready.
  4. **new: the charge.** At the Festival Door and the Tower's entrance, a run takes 20 kWh from the battery (seed), if it holds that much, and starts **Charged**: the signature's ring full and lit in the battery's light at the first fight. A switch on the Door's plate, on by default.
     - It's timing, never a stat, so pillar 2 holds. An empty battery starts the run as today, so fighting is never gated (Genshin's resin wall was resented: SOURCED, research hand-back, Q3).
     - It makes the battery a budget. On day 3, about 55 kW of surplus pays for about half the runs; by the end of launch's content, every run (COMPUTED from the ledger's rates, at 12-minute runs). More workers and higher bays mean more charged runs: that's "the base runs because of who I found", felt in the fight.
     - It needs TR52's tap accepted first (`docs/test-requests.md`, TR52).
     - **Held, 11-24, after the director's yes** (Faber, OBSERVED in code): the lead is made with its signature ready (`FightService.luau:651`, `ReadyAt = {}`), and a rise or a trip home makes it ready again (:1322, :1362). So every run already starts as "Charged" would, and the charge as written changes nothing. It comes back to the director with options before anything is built.
  5. overflow into Credits at 0.5 a kWh (as built), named on the return card ("The grid paid 140").
- **The loop, end to end:** a fight drops shards and Credits → the Breaker spends kWh on the shards → Voidkin → the bays → kWh → the workers grow, the lead trains, stones condense, the next run starts charged → the fight.
- **Not at launch:** Research Points anywhere on screen; voltage (never offered, since no launch shard breaks 60 s); the Power screen's split, which Auto always beats (OBSERVED, `Power.luau`): show the screen as a readout until a split can win.
- **Whose yes:** the director's, since they asked. Rule 3 is a balance number (tier 2: research and Faber); rule 4 is a new mechanic (tier 2), after TR52's verdict. **Cost:** Faber 4 h for both, with logic cases; research 2 h for the seeds.

## 3. Credits, Robux and Reinforce

The director's question: "sure reinforce but is this good? cant we js fixe paid random rule".

**What Roblox asks**, read on 2026-11-24:
- Currency bought with Robux makes everything random it buys a paid random item. "Upgrade spell with some chance of working" is named. Every outcome's odds must be shown before the press, summing to 100% (SOURCED, [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)).
- Where `ArePaidRandomItemsRestricted` is true (Australia, Belgium, the Netherlands, the UK and Brazil), players can't use them with Robux or with bought currency (the same page; [DevForum, 2026-05-26](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)).
- "All possible outcomes for a paid random item must provide some benefit to the user; there cannot be a possible outcome which results in the user simply losing their payment" (SOURCED, [Community Standards](https://about.roblox.com/community-standards#roblox-economy-paid-random-items)). This settles the line `docs/roblox-rules.md` couldn't confirm.

**So yes, the rule can be met.** It takes four things:
1. the odds on every press (built for shards, and Reinforce shows its chance);
2. the PolicyService check on the Credits purchase;
3. the declaration in the questionnaire;
4. a failure that isn't a pure loss.

Only the fourth changes the design, and today's failure ("spends its cost and keeps the level, with no pity") is exactly the outcome Roblox bans.

**A sure Reinforce is the worst answer.** The tension goes, and so does the sink: one item to +30 costs about 16,139 Credits expected today (COMPUTED), and a sure ladder would cost a fraction of that unless every price rose.

**My recommendation, in order:**
1. **At launch, sell no Credits** (research's store proposal, `docs/decisions.md`, "Waiting on the director", 2). Then nothing random touches Robux and the rule doesn't apply.
2. **Forge heat, for its own sake.**
   - Each failure fills the item's heat bar by a set amount; a full bar makes the next try succeed; a success empties it. The heat moves with the item's level when the transfer prompt moves it.
   - It's Lost Ark's honing; Black Desert's failstacks and MapleStory's 2025 Star Force went the same way (SOURCED, research hand-back, Q4).
   - Why players need it: at the 20% floor, 15 failures in a row happen to one player in 28 (0.8^15 = 3.5%, COMPUTED). Across a server of children, that's someone every evening.
   - To hold the sink: +5 points of chance a failure needs prices 1.46 times higher (`build-depth.md`, MEASURED there). Research refits it.
   - It reverses "no pity" (the director, 2026-11-19, 03:10), so it's theirs.
3. **Credits for Robux later,** only with 1 to 4 built, and research rereads the page that week.
   - Whether a heat bar counts as "some benefit" isn't written anywhere (SOURCED: the policy is silent), so research asks Roblox's forum before the sale.
   - If the answer is no, Reinforce's chance levels (+6 and up) cost stones only, and Credits never buy stones. The Condenser's levels buy a rate, not stones.
   - The shop's shards always give a Voidkin, so they pass the no-loss rule as they are.

## 4. The machines' ceiling, restated

The director said "ok" to holding it at 6. Before it's built, here is exactly what 6 does, and why I now advise 15.

- **What 6 does:** at base level 3 every machine stops at level 6 (today 30). Stage III (machine level 15) never shows at launch. The generator takes the stage at the base's ceiling, so it's Stage II at both base levels 2 and 3, and base level 3 brings no new look. The Breaker's third chamber (level 8) is out of reach. Six machines to 6 cost 26,940 Credits, 1.5 to 3.4 hours of fighting at the seed: the base stops growing on the first day (COMPUTED from `Config.Base`).
- **What 15 does:** ceilings 2, 6 and 15. Each base level brings a stage, I, II and III, the art Modulo drew (AR32, AR35, AR36). The third chamber stays, and the fourth (level 20) waits for the base's next level. Six machines to 15 cost 210,540 Credits, 27% of today's 791,940 and 12 to 27 hours of fighting at the seed (COMPUTED). That fits the launch's span: the first Legendary lands at 18 to 40 hours (`design.md`, "Chests").
- **What it touches:** `Config.Base.Levels.Ceiling` (30 to 15 or 6), seeds.json's "baseLevels" (research's), `design.md` and `balance.md`'s "2, 6 and 30", and one logic case. Faber, 30 minutes, on the director's word for 6 or 15.

## 5. A chest for everything at launch

**Today** (OBSERVED, the content catalogue):
- Chests give gear only. Emblems drop loose from elites (30%) and keepers (75%, sure on the first Normal win). Stones drop loose.
- **Jewels have no source and no effect,** though the Condenser makes them "from launch" [D, 2026-11-17, 12:10].
- Epic and Legendary emblems: no source. Presets 2 to 5: nothing adds them. High stones: Tower floor 78 up.
- **A rarity gap:** Lantern Row's Normal Shade and Elite chests can give an Epic (0.3%) or a Legendary (0.05%), but never a Rare (0%). So a player can find an Epic before any Rare. Research's rows (TR48); flagged, not changed.

**The family at launch:**

| Chest | Holds | Comes from | New? |
|---|---|---|---|
| Shade, Elite, Keeper's, Tower | one gear piece | as built | no |
| **Emblem Case** | one War Emblem, its rarity from the ladder as today | the elite's and keeper's emblem drops, now cased; the Tower's every tenth hard floor, once | yes: the drop becomes a case |
| **Jewel Pouch** | one jewel, level 1 mostly, now and then level 2 | a keeper's win on Hard; the welcome week | yes; the Condenser stays the main source [D] |
| **Forge Crate** | a handful of Low stones, sometimes Mid, rarely High | a keeper's win on Hard; the welcome week; codes | yes |
| a shard | a Voidkin | as built | no: **the shard is its own chest, and the Breaker is its show** |

- **Kept from the design:** a chest is named for its ground and its kind ("an Emblem Case of Lantern Row"), never with a rarity's word or frame. Its card gives its odds. Open all goes across kinds, one server step per chunk, and nothing is ever sold.
- **Closing the orphans:**
  - **Emblem combine.** Three emblems of one stat and rarity make one of the next rarity, with that stat; its set (look only) is drawn. It's free and sure, which gives Epic and Legendary emblems a source and the duplicates a sink.
  - **High stones from the Condenser:** a second conversion, 5 Mid into 1 High, from machine level 10. So +21 to +30 is reached through the base, with electricity behind it.
  - **Presets earned:** a second at base level 2, a third at 3.
- **Jewels at launch,** as the director decided. The work: the Condenser's jewel making, jewels' flat points in the resolver (`Rules/Stats`), the three-into-one combine already designed. This replaces the steering brief's "Hold jewels" (`README.md`, item 8): that advice was mine, and the director's word of 11-17 comes first.
- **Whose yes:** tier 2 (research's rates; Modulo's three pictures; Faber's open path, which is gear-shaped today). **Cost:** Faber 1.5 days with cases (the cases, combine, High, presets, jewels' effect and making); research the rates, 3 h; Modulo three chest pictures.

## 6. The Broadcast: global messages

The director's idea of 2026-11-13: "global chat like when someone get a mythical units? Let keep this idea in mind for later since we arent making mythical units yet" (`docs/decisions.md`). At launch the top is Rare, so the ladder is set by what's rare at launch, not by rarity names.

| Reach | What's told |
|---|---|
| **Every server** | a Legendary item; a Dawn piece; a Reinforce success at +20 or higher; a Voidkin to seven stars; a new first place on the Tower's weekly board |
| **This server** | an Epic item; an account's first Rare Voidkin; a first win over the Lamplighter on Hard; a new server record in the Tower; a Reinforce success at +15 |
| **Nobody** | anything bought; any failure; any text a player typed. Nicknames stay with their owner (OBSERVED, `VoidkinService`), so a line names the Voidkin's own name |

- **The line:** "{display name} found Meigetsu, the Full Moon", in the rarity's light. It runs once at the top centre for 4 s and stays in the chat. It's never shown during a keeper's fight, a reveal or a menu; it waits until after (the conductor's hold, `README.md`, item 4).
- **This server:** a RemoteEvent to every client; each client draws the banner and calls `TextChannel:DisplaySystemMessage`, which runs only on the client (SOURCED, Creator Hub).
- **Every server:** one MessagingService topic. The message is under 1 kB and carries ids only, never words, so each client builds the line from its own strings, and a translation, once there is one, reaches it.
  - The limits (SOURCED, Creator Hub): a server sends 600 + 240 × players a minute, and a topic receives 40 + 80 × servers a minute. Delivery is best effort, which is fine for news.
  - Throttles: one every-server line per player per 10 minutes, and each server shows at most 12 a minute, dropping the oldest.
- **Settings:** "Show my finds in other servers" and "Show others' finds", both on.
- **The Strip's board:** a board beside the Shop shows the last eight every-server lines, so the world tells the news before any banner does.
- **The words:** display names are moderated by Roblox, and nothing else a player wrote is carried. Research writes the lines; the content check reads them.
- **Whose yes:** tier 2 (new screens and words). **Cost:** Faber 4 h (a pure rule for reach and throttle with cases, the service, the client line); research the words, 1 h; Modulo the board's look, later.

## 7. The neighbourhood and the social layer

- **Built:**
  - eight bases on a street;
  - the plinth turning your best Voidkin with its CR, and the gate plate with your name and base level;
  - visiting, free and safe;
  - packs and elites anyone may join;
  - the Tower's weekly board (OBSERVED, `TowerBoardService`).
- **Add, in the world:** three boards on the Strip, so the street is where you see who's strong.
  - **The best lead's CR,** all time;
  - **the Tower's week,** today's board moved into the world;
  - **total stars.**
  - Each reads a server-computed number from an OrderedDataStore, which is free.
  - A tap on a name opens that player's lead card (TR33).
- **Add, small:** Roblox's invite prompt (`SocialService`) on Home, never rewarded.
- **Not at launch, and why:**
  - **trading:** a duplicated or scammed Voidkin is the valuables risk section 9 of the directive warns about;
  - **parties:** the director, after everything else;
  - **clans:** [D];
  - **friend multipliers:** pillar 2.

## 8. A day and a week

- **Built:**
  - Today's three, banked three days, with no streak;
  - the Shop's clock;
  - the battery and the tray;
  - the Tower's weekly foes and board;
  - the return card (TR53).
- **Add:**
  - **The welcome week:** seven gifts, one for each day played (not each calendar day), never lost.
    - Day 1 a Forge Crate, then an Emblem Case and a Jewel Pouch in turn.
    - Day 7 a Named shard of a launch Voidkin the account doesn't own yet, chosen for it, not rolled. A player who owns all five gets a Forge Crate.
    - Research sets the seeds.
  - **Codes:** one per update, typed in Home's settings, once per account. It pays a crate, a case or a pouch, never anything sold. Where they're posted is the director's call.
  - **Firsts:** a once-per-account moment for each new rarity found, the first +10 and the first Hard win, with a line to the server.
  - **Notifications,** opt-in, on the director's word (`long-game.md`): the battery full, the tray full.
- **Not:**
  - playtime gifts, which pay for sitting, not playing;
  - streaks [D];
  - a pass (the director: "Not at launch").

## 9. The store at launch

Research's proposal stands (`docs/decisions.md`, "Waiting on the director", 2):
- a Founder's Mark during early access;
- more bag space;
- cosmetics (a reveal's light, the yard's theme);
- private servers.

Never at launch: Credits, luck, chests, keys, restocks, rerolls or faster breaks. The director approves the store before anything is sold.

## 10. Additions, ranked

| # | What | Why | Cost | Yes? |
|---|---|---|---|---|
| 1 | The workers grow by working (2) | pillar 3 true; the bench ready for counters | Faber 2 h, research 1 h | the director |
| 2 | The charge (2) | electricity felt in the fight; the battery a budget | Faber 2 h after TR52 | the director |
| 3 | Forge heat (3) | no 15-fail streaks; the rule's door kept open | Faber 2 h, research the refit | the director |
| 4 | The ceiling at 15 (4) | the base grows a stage each level | Faber 30 min | the director: 6 or 15 |
| 5 | The chest family and the orphans closed (5) | every launch item has a source | Faber 1.5 days | tier 2 |
| 6 | The Broadcast (6) | the server hears your finds | Faber 4 h | tier 2 |
| 7 | Boards on the Strip (7) | "two players compare builds" (north star) | Faber 3 h, Modulo the boards | tier 2 |
| 8 | The welcome week and codes (8) | a reason for day 2 to day 7, and for each update | Faber 3 h | tier 2 (rewards) |
| 9 | **Capture after a reveal:** a button that takes a picture with Roblox's own CaptureService, for the player to save or share | "a screenshot of a reveal looks like an advert" (north star) | Faber 2 h; the API checked first | tier 1 |
| 10 | Firsts (8) | the first Epic is an event, not a line in the bag | Faber 2 h | tier 2 |

All ten come to about five days of the builder's work. None waits on Voidkin art, so they fit the order the director gave ("the game comes before the Voidkin"). They go after the open pieces, in this order, each through its feel line.

## 11. Fixed with this file

- `collection-and-economy.md`, the currency table: the Condenser takes no Credits but its levels, and the battery has a sink away.
- `systems-map.md`, finding 4: 44 to 101 hours of fighting at the seed, not 100 to 250.
- `docs/design.md`, "The Festival of Battles": six grounds in all, Lantern Row alone at launch (the cut line). "What the player holds": Credits don't go to the Condenser; electricity also runs the Training machine.

## 12. The director's replies of 11-24, for the register

For research to file in `docs/decisions.md` with their scope:

| The director's words | Covers |
|---|---|
| "who care about one famous rpg lead name and move it not copying stop being so extreme with this be more leniant" | **Noct stays** as written (`docs/roster.md`), name and signature. The general steer: flag a fighter only when it would be recognised as one character, not for one shared name or move. The test in `docs/decisions.md`, "Fighters", stands until they say otherwise. |
| "sure reinforce but is this good? cant we js fixe paid random rule" | a question, answered in section 3. Nothing changes until they pick. |
| "ok" (the machines' ceiling at 6) | restated in section 4 with a correction to 15; answered below with "6". |
| "ok" (the private phone sitting) | the director does it with a stopwatch: the first ten minutes, one clean Normal run, and the trip there and back (`README.md`, item 1). |

Their answers to section 13, later on 11-24:

| The director's words | Covers |
|---|---|
| "if it good sure put it in the grow your anime github and i will tell quaestor about it" (1) | **Both currencies stay**, and electricity gains the two uses of section 2: workers grow by working, and the charge. The other spends in section 2's table aren't named, so they stay proposals. The director tells Quaestor. |
| "we will sell credit so make sure it in accord to roblox rule" (2) | **Credits will be sold**, so section 3's first recommendation (no sale at launch) is set aside and its third is the path: the odds on every press, the PolicyService gate, the questionnaire (theirs), and a failure that isn't a pure loss. Forge heat is the design built for the fourth. It reverses "no pity" (2026-11-19), and AGENTS.md rule 4 wants the director's yes to the compliant design before the sale opens, so heat comes back to them built, with stones-only chance levels as the alternative. Its prices wait for research's refit. **Built 11-24, held for their yes:** heat at +5 points a failure, the bought-Credits ledger and the policy gate (`docs/roblox-rules.md`, points 2 and 5). The Credits product waits for the PC. |
| "6" (3) | **The ceiling holds at 6 at launch:** `Config.Base.Levels.Ceiling` is 2, 6 and 6. Section 4's consequences stand: no Stage III and no third chamber at launch, and base level 3 brings a bay and the battery, not a look. |
| "ok" (4) | **The Emblem Case, the Jewel Pouch and the Forge Crate**, with jewels finished for launch (the Condenser makes them, 2026-11-17). Section 5's other proposals (the emblem combine, High from the Condenser, earned presets) aren't named, so they stay proposals. **Built 11-24:** jewels' points in the resolver and their set, unset and merge (TR47 part B), the Condenser's jewels, and the three chests (`docs/design.md`, "Chests"), on the builder's seeds for research's refit. Waiting: the Jewels page and the cards seen in Studio (the PC), Modulo's three pictures. |
| "ok" (5) | **The Broadcast** on section 6's ladder. **Built 11-24:** the rule and its cases, the service with its topic, the chat line and the banner, and the two switches in the save (`docs/design.md`, "The Broadcast"). Waiting: research's words, the Settings card and a playtest (the PC), and the Strip's board (later). The finder's display name passes Roblox's text filter (the content check, 2026-11-24). **For the director, before Credits go on sale:** may a line tell a rare outcome that bought Credits paid for? The options:<br>(a) keep it, once research sources that no rule forbids it;<br>(b) tell only outcomes paid with earned Credits, or free;<br>(c) never tell such an outcome to a viewer, or about a finder, where paid random items are restricted.<br>The content check recommends (c) as the floor. |
| "ok" (6) | **The welcome week and codes**, as section 8 has them. |

## 13. For the director, in one list

Answered on 11-24: section 12 has the words and what each covers.

1. **The currencies:** keep both; electricity gains two uses, the workers growing and the charge. Yes?
2. **Credits:** unsold at launch. Yes? **Forge heat** in place of "no pity". Yes?
3. **The ceiling:** 6 as you said, or 15?
4. **Chests:** the Emblem Case, the Jewel Pouch and the Forge Crate, with jewels finished for launch as you decided. Yes?
5. **The Broadcast,** on the ladder in section 6. Yes?
6. **The welcome week and codes.** Yes?
