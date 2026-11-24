# The long game: why a player comes back on day 2, 7 and 30, and eight weeks we could keep (research helper, 2026-11-24)

## Verdict

1. **Our return reasons are front-loaded.** Minutes to one day is well covered and mostly built (the Breaker, the battery, the shop's clock, today's three). One week is thin (Hard, the Tower's weekly foes and board). One month is empty: stars and a decision to update "every 2 to 4 weeks" with nothing on the shelf.
2. **The guided game ends at about hour 5.** The Next list's last line is "Drum Court's gate stays shut, for now." That's day 3 for a keen player and day 7 for a 40-minute one.
3. **Our cheap content is rules, not art.** A new Shade kind reached the game as a block in one day (MEASURED). A fighter at the director's bar has never been finished, so its cost is unknown. A calendar has to lean on rules: modifiers, seasons, a draft mode.
4. **Weekly beats cost nothing once built; a named update every two weeks is affordable only from a bank.** Roblox's own docs say cadence content "exclusively build[s] on existing systems". That's the shape below.
5. **Nothing here is for now.** The first ten minutes and the scope freeze come first (`README.md`, items 1 and 2). This is the plan to hold when the director says go. No public step is proposed.

**How this was read.** Our repo in MAIN, and web fetches on 2026-11-24. The shared search budget ran out after six searches, so some topics rest on pages fetched by address. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED (computed from our records), OPINION. "Couldn't fetch" is listed at the end. Numbers proposed for us are seeds, tuned by playing.

## 1. Every reason to return today, by timescale

| Timescale | As designed (`docs/design.md`) | As built (OBSERVED in `src/`) | Read |
|---|---|---|---|
| **Next session** (minutes to hours) | A shard still breaking in a chamber. The battery filling to its cap, the Condenser's tray, the Training machine, all working away. The Void Shop's stock every 5 minutes, featured 1 stock in 6 (`Config/Shop.luau`). A fallen lead healed in about 90 s. | Rules and services exist for all of it (`Rules/Breaker`, `Condenser`, `Training`, `ShopService`). The return card isn't built (TR53, next in Faber's order). The Forge and Condenser weren't yet verified in Studio (`design-holes.md`, section 1). | Strong. The payoff moment (the card) is the missing piece. |
| **Tomorrow** | Today's three, reset 00:00 UTC, banked three days, each paying a Standard shard. The base's overnight output. An opt-in "battery full" notification, proposed. | Goals are in the game (`GoalService`, `TodayList`, `DareLine`; TR54 held at competent on three must-fixes). No notification. Nothing shows tomorrow's three tonight (no "tomorrow" anywhere in `src/`). | Fair. The reward weakens fast (section 5). |
| **This week** | Lantern Row on Hard. The Tower: foes drawn from the week, a week's board (`Config/Tower.luau`, `Week`, `Board`). The Next list: five steps. Gear: Rare about 2 h, Epic about 4.3 h (`docs/balance.md`, MODEL). The Clash Grounds' daily track. | Hard, the Tower's week and `TowerBoardService` are in code; the Tower is still grey. Clash: not built. | Thin. One weekly system, in grey, off the Home panel. |
| **This month** | Stars: 127 copies a Voidkin (`Config/Voidkin.luau`, `StarCopies`). Legendary gear at about 18 h. Named updates every 2 to 4 weeks (the director, 11-23). The Calamity, the Rift, the Research Lab, Drum Court: after launch. Weekly goals, a pass, titles: "Not at launch". | Stars and gear are built. No update is stocked, owned or dated. | Empty. Seven stars add about 10% of base stats (7 × `StarShareOfBase` 0.0143, MEASURED): a month of copies for a number few will feel. |

## 2. Findings

### A. Loops

1. **A strong core loop is what lets a small team ship little.** The loop is action, reward, progress; "the core loop is so engaging on its own that Supercell only needs to add new content every once in awhile". SOURCED: [Mobile Free to Play](https://mobilefreetoplay.com/bible/crafting-strong-core-loop/).
   For us: the cheapest retention work is still the fight (TR52's tap, the four stretches' questions). No long-game system below rescues a loop nobody wants to repeat.
2. **AFK Arena's modes are two families.** Three one-time progression modes, and "three endless modes which drive the player to have the widest collection". The campaign walls the player, who is then "pushed to play in other modes". The Labyrinth resets every 48 hours, a fallen hero stays out for the run, and the player picks one of three relics every few stages. The Arena fights offline copies of other players' teams in 14-day seasons. The analyst calls the lack of events that favour one hero type "a clear omission". SOURCED: [Deconstructor of Fun, 2019](https://www.deconstructoroffun.com/blog/2019/6/6/afk-arena-puts-lilith-into-the-billionaire-club).
   For us: when our player hits Hard's wall or the Tower's, there's no other mode to go to. And nothing ever asks for a fighter other than the best one.
3. **Its dailies offer more than they ask.** A reward every 20 points up to 100, with more than 100 on offer, so the routine is the player's choice; the idle chest stops filling at 12 hours, which invites two sessions a day. "Flexibility over control." COMMUNITY: [Game Developer](https://www.gamedeveloper.com/design/flexible-time-session-design-in-afk-arena).
   For us: the battery's cap is that chest. Today's three is exactly three, with no slack and no weekly sum.
4. **A premium look doesn't hold day 30; repeatable modes do.** Honkai: Star Rail launched with two endgame modes, both on weekly resets, and kept 4% at D30 on iOS US against 10 to 14% for older squad RPGs; its D30 was about 10% of its D1, against 30 to 40%. The authors name the thin endgame as a key cause. SOURCED: [Naavik](https://naavik.co/deep-dives/how-honkai-star-rail-reveals-cracks-in-the-hoyoverse/).
   For us: a 500-person team hit the wall we're walking toward with one ground.
5. **Who stays for what.** Bartle's achievers: "The point of playing is to master the game." SOURCED: [Bartle](https://mud.co.uk/richard/hcds.htm). Quantic Foundry's model pairs Completion with Power, and Competition with Community (recalled; the page refused the fetch, so OPINION here).
   For us: Completion needs an index with gaps in it, and five fighters fill it in an hour. Power has Combat Power, built. Competition can be served by boards we already have. Community has nothing until parties.

### B. Appointments that respect the player

6. **Lowering the bar keeps the habit.** Duolingo let one lesson keep the streak: D14 retention rose 3.3% (relative) and learners on a 7-day streak rose over 40%. "Lowering the barriers to building a consistent daily habit is more important" than how much is done each day. Allowing two streak freezes added 0.38% daily actives. SOURCED: [Duolingo, 1](https://blog.duolingo.com/improving-the-streak), [2](https://blog.duolingo.com/how-duolingo-streak-builds-habit).
   For us: "bank three days, no streak" is the forgiving half, done right. We dropped the other half: nothing adds up across days. A weekly count (not a chain) gives that with nothing to lose.
7. **Intervals are a design choice.** Daily gifts are everywhere; 48-hour and weekly appointments are a mid-core tool and nearly absent from casual games. SOURCED: [GameRefinery](https://www.gamerefinery.com/keep-your-players-in-game-with-appointment-mechanics/).
   For us: we have 5 minutes and one day. No 48-hour or weekly appointment pays anything.
8. **What Roblox itself calls manipulation.** Notifications may not use "dark patterns or other tactics that manipulate or deceive users": disguised ads, false time pressure, bait-and-switch free rewards, tricked purchases. One a day, opted-in players 13 and over, never needed to progress. SOURCED: [docs](https://create.roblox.com/docs/production/promotion/experience-notifications). In August 2026 Roblox reportedly barred from Kids and Select any game that rewards watching a continuous feed "without natural stopping points"; ordinary loops and daily rewards weren't covered. COMMUNITY: [a secondary write-up](https://shattered.io/roblox-doomscroll-games-ban-kids-select-2026/); the staff post wasn't found. Regulators already fine purchase dark patterns: $245 million in refunds in one 2022 case. SOURCED: [FTC](https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations).
   For us: a true deadline, stated plainly, is fine. A false one isn't. Keep "no timer on the HUD". Every run, climb and goal list must have an end the player can see.
9. **Fear of missing out costs the maker too.** Grow a Garden gave weekly exclusives to players online at the hour; players called its events "rushed and not very inspired" and the studio added two event teams to keep up. Its 21.3 million peak fell to 7.6 million within an hour. COMMUNITY: [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden), citing PC Gamer and PocketGamer.biz. Our own reference fell from 745,280 to 1,046 players once its near-weekly updates stopped (`docs/research/long-grind.md`).
   For us: we can't staff an event team. So an event's reward is "first here, back later in the shop's featured stock", never "gone for good". That removes the pressure on the player and on us.

### C. Content that multiplies itself

10. **Rotating rules on old content.** World of Warcraft's Mythic+ replays the same dungeons under affixes set game-wide each week, 8% more health and damage a level, a weekly top-100 board, and a dungeon pool that rotates by season. SOURCED: [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Mythic%2B).
    For us: `Tower.Week` already draws the Tower's foes this way. The same clock can draw rules.
11. **Difficulty the player chooses.** Hades' Pact of Punishment opens after the first clear, lets the player "manually customize and increase the difficulty", and so "continue to receive rare rewards" from the same rooms and bosses. SOURCED: [Wikipedia](https://en.wikipedia.org/wiki/Hades_(video_game)).
12. **A draft run that re-uses the roster.** Star Rail's Simulated Universe is "a roguelike endgame dungeon with weekly reward resets" built from the game's own characters and enemies (Naavik, above); AFK's Labyrinth is a pick-one-of-three run on the player's own heroes (finding 2). Anime Vanguards' July 2026 raid is 30 waves "with a random card draw system" (finding 16). SOURCED and COMMUNITY.
13. **Saved teams as opponents** need a wide roster. AFK's Arena and our own reference's 3-v-3 Arena (`docs/research/tower.md`) both run on dozens to hundreds of units. OPINION: with five Voidkin, every defence is one of five mirrors.

### D. Roblox in 2026: updates, events, passes, and what hits ship

14. **Roblox's own sizing.** Cadence content runs "weekly to monthly" and "exclusively build[s] on existing systems"; "many games release cadence updates every two weeks to one month"; keep each under three weeks of effort. If players use up cadence content at once, shipping faster "defeats the purpose". A release that needs a new system is an expansion and "unsustainable for a cadence". Major updates "may necessitate many months". Be "realistic about a team's capabilities". SOURCED: [LiveOps essentials](https://create.roblox.com/docs/production/game-design/liveops-essentials), [content updates](https://create.roblox.com/docs/production/game-design/content-updates).
15. **Events and update notes, the mechanics.** At most 10 live or coming events. Players tap Notify Me. An update note is 60 characters, at most one every three days, sent to players who follow the game, and reports views, visit rate and unfollow rate. Trending Events needs 1,000 RSVPs. The best featured events run 7 to 30 days. The join data carries the event's id. SOURCED: [events docs](https://create.roblox.com/docs/production/promotion/experience-events). Plan around the KPI an event should move, and compare the week before with the week after. SOURCED: [LiveOps planning](https://create.roblox.com/docs/production/game-design/liveops-planning).
    For us: to a player, "an update" is an Events card and a 60-character line. To Home, it's nothing by itself: only the play days it causes count (`retention-and-discovery.md`, findings 1 and 17). Playtime counts up to 60 minutes a day, so ten good minutes on many days beats one long evening.
16. **What hits put in an update.** Anime Vanguards, first month (2024-10): 13 units, one story stage, one legend stage, a weekly tournament mode, about 30 quality-of-life changes. COMMUNITY: [Beebom](https://beebom.com/anime-vanguards-update-1-patch-notes/). Two years on (2026-07-06): 3 units, 4 memoria, one raid, one rift, part 1 of a two-part event, 11 small changes, 13 fixes. COMMUNITY: [Gamezebo](https://www.gamezebo.com/walkthroughs/anime-vanguards-update-14/). Its anniversary paid an event currency for clearing stages (500, 5,000 and 9,000 by stage kind), gave one unit for logging in and one at tier 50 of an event pass. COMMUNITY: [AllThingsHow](https://allthings.how/anime-vanguards-2nd-anniversary-how-to-get-all-new-units-update-15-0/). Grow a Garden: weekly, with two event teams. Pet Simulator 99: "fortnightly", by one reviewer (Wikipedia's list of Roblox games).
    For us, OPINION: the mature shape is small: about three units, one twist on a mode, an event in two parts farmed in old stages. We can match the shape at one unit, never the first-month volume.
17. **A season pass, by Roblox's page.** About one month, ten tiers to start, at least a week's rest between seasons, missions that never need paid currency, double pace in the last week, unclaimed rewards paid at the end, and a late buyer gets the tiers already earned. "If players regularly fail missions, interest ... tends to wane." SOURCED: [season pass design](https://create.roblox.com/docs/production/game-design/season-pass-design).
    For us: fixed rewards on fixed tiers aren't a paid random item, so a pass fits rule 4. It's still "Not at launch" by the director's word, and selling one is the store's piece (tier 3).

## 3. What our content costs

| Thing | What our records say | Label |
|---|---|---|
| A fighter, to a playable block | Rook: 13.7 h over 13 "Hours" lines, two days (AR1). Pip and Lyric: about 43 h for the pair, much of it marked "an estimate" (AR4). Kirra: about 5.5 h by the clock, two days (AR10). Watt: about 5 h by the clock, four days with its fixes, and "the clock reads short against the work" (AR11). | MEASURED (sums of logged lines) |
| A fighter, at the director's bar | Not measurable: none of the five is accepted. Each still owes its own basic attack with effect and sound (AR26), a redesign (AR59 names 3 h for the blockout and 2 to 3 h for the takes "as a guide", before the finish) and an install. | OPINION: 20 to 30 team-hours, 4 to 6 days beside other work |
| A Shade kind | Guard and Dasher: two masks and two block clips in 20 minutes, one 20-minute fix, behaviours capped at 90 minutes each; asked 14:54, in the game as a block 23:58 the same day (AR52). The Support: 49 minutes of maker time (AR58). Finished looks aren't made yet. | MEASURED: one day at block. OPINION: two days finished |
| A keeper | The Lamplighter's sheet, model, clips and fall: 2.75 h by the clock against 13 h named, plus 2.4 h of later rounds, all on 11-13 (AR7). The slam's block: 4 h estimated (`docs/production-plan.md`). | MEASURED and estimate: about 10 h, two days at block |
| A ground | Lantern Row's direction and kit: about 8 h over three lines, each "an estimate", 11-12 to 11-16 (AR5). The code isn't data yet: one street, one ring, "Lantern Row named in code" (`docs/engineering-plan.md`, "Content at scale"). Add two or three Shade kinds, a keeper, a headliner, shards and a refit. Lantern Row itself isn't yet called "at the bar". | OPINION: 60 to 90 team-hours, 2 to 3 weeks; the first new one costs more |
| A rule (a modifier row) | No record. Nearest: a behaviour inside its 90-minute cap; Hard's tint measured, fixed and cased in one sitting (AR52). | OPINION: 30 to 60 minutes each, after about 6 h for the frame |
| The team's pace | About 15 commit-hours a day, "read from the commit clock, not measured" (`docs/production-plan.md`, "The date"). Six pieces closed and playable in the week of 11-23 (`docs/team-notes.md`, "The count"). | OBSERVED |

**The honest reading.** One fighter a week isn't sustainable at the bar. One every three to four weeks may be. A ground is a "major update" in Roblox's words: one in the first three months at most. Rules are the only thing we can ship weekly.

## 4. Proposals

### (a) The ladder: one pull per day

| Day | The pull | Built? | Missing |
|---|---|---|---|
| 1, leaving | A shard left breaking, and Hard just opened (the Next line) | yes | The session's last card names tomorrow's three. `Goals.Pick` is a fixed draw per player and day, so tonight can compute it. Faber, 1 to 2 h. |
| 2 | The return card: what the base made overnight, then today's three | goals yes, card no | TR53, already next in Faber's order. |
| 3 | The Lamplighter on Hard and its sure Rare or better, with a second lead raised for it | yes | Hard must ask for a different lead: mixed types in the packs (`design-holes.md`, F2). |
| 7 | Monday: the Tower's new foes and a fresh board, and the week's crate (d) | week and board in code | The board on Home's Tower card; the weekly count; a reward for the week's first climb. |
| 14 | The first named update: mode A below | no | The bank (c). |
| 30 | A second season's end, an Epic to chase, and the draft mode | stars only | The bank; an index that shows its gaps. |

### (b) Two re-use modes (working names; both need the IP-list check)

**A. "Overload": Hard with the week's faults.** A third tile beside Normal and Hard, open once Hard's keeper has fallen. Each Monday 00:00 UTC, on `Tower.Week`'s clock, the server draws two faults for everyone: one on the Shades, one on the lead. The street, the stretches and the keeper are Lantern Row's own. The week's first clear pays a Keeper's chest; the first clear ever under each fault pays a stone bundle once (finding 11's idea). Clear times go on a week's board in three Combat Power bands, on `TowerBoardService`'s pattern. It lasts the whole week, with no HUD timer, and a missed week loses nothing lasting.
- **The faults, seeds:** Shades: *Phase Shift* (every Shade's type turns one step round the ring, so the best lead changes); *Shield Wall* (each pack trades a Brawler for a Guard); *Twin Lines* (a Dasher lunges twice); *Heavy Load* (+30% health, -15% attack). Lead: *Brownout* (no Regen; a kept dare gives back 10% health); *Live Wire* (signature cooldown -40%, basic hits -25%); *Class Call* (the week's class deals +25%: the hero-type event finding 2 says was missing); *Short Fuse* (poise drains twice as fast). Level offset +12 against Hard's +10. Sixteen pairs before a repeat.
- **Cost, OPINION:** Faber 10 to 12 h (fault rows read by `Rules/Fight` and `Rules/Stages`, the tile, the board, a logic case per fault). Research 3 h for the numbers through `tools/balance/`. Modulo 2 h: eight small marks in the kit. No model, no clip.

**B. "Draft Climb": a run in the Tower's room where the build is drafted, not owned.** A second door at the Tower once the record passes floor 15. The player picks one of three offered Voidkin, set to level 20 on a standard Regalia, so gear doesn't decide. Every two floors they pick one of three charges, run-only boosts on stats that exist (Lifesteal, Critical, Block, Penetration, poise damage, signature cooldown, Burn, Chill or Shock on hit, with AR48's cues). Foes are the Tower's own, our Voidkin in the enemy look, on the week's seed. The seed also fixes the offers, so the whole game drafts from the same hands that week and the board is fair. Every tenth floor is the Lamplighter with its slam. Health carries, the heal cap holds, a fall ends it. A run aims at 8 to 10 minutes. The day's first run pays in full (a Tower chest every five floors, stones); later runs pay Credits only.
- **Seeds:** 15 charges (8 plain, 5 strong, 2 with a drawback); foe level 16 + 0.75 a floor.
- **One offer of the three can be next update's Voidkin on trial** (director's yes). Every player handles the new fighter a week before its shard exists.
- **Cost, OPINION:** Faber 14 to 18 h (the two draft cards, charges as a run-only layer over `Stats.Resolve`, the standard build, the lent lead, `TowerService`'s ledger re-used, a board, cases). Research 5 h with `tools/balance/tower.py`. Modulo 3 h: 15 marks and one card. No new art; it uses AR56's room.
- **Why it earns its cost:** it's the one place every fighter gets played by everyone, and the weekly reset has a different answer each week with no art at all.

Both change scope, and B reverses "Not at launch: ... branches" for the Tower: **the director's yes.**

### (c) Eight weeks after an eventual launch, and the bank

**Every Monday, at no cost once built:** new Tower foes and board (built), a new Overload pair, the weekly count reset, one 60-character update note.

| Week | Ships | From | Made that week |
|---|---|---|---|
| 1 | Nothing new. The biggest funnel drop fixed (`retention-and-discovery.md`, finding 7). | | fixes |
| 2 | **Update 1:** Overload, and the dare pool (three a stretch, drawn by the day) | bank | |
| 3 | Tower Season 1 opens: four weeks, the season's best floor marked on the lot's record marker | bank | fighter 8 starts |
| 4 | **Update 2:** Voidkin 6 (Sable), a Named shard in the featured stock; the daily pool grows | bank | |
| 5 | An event on old content: a game-wide count of Shades felled under the week's faults, three thresholds, 7 days; everyone who took part claims a Named shard of their choice. The Rift's first schedule could ride here. | bank (the shell) | numbers |
| 6 | **Update 3:** Draft Climb | bank at block | its finish, weeks 1 to 5 |
| 7 | Tower Season 2; four new faults; the Support's elite joins the pool | one day of rules | Drum Court's block starts |
| 8 | **Update 4:** Voidkin 7 (Marigold, the first Epic and the first real chase); Enriched shards return to the shop's shelf; Drum Court named for month 3 or 4 | bank | |

New art in eight weeks: one fighter and the start of a ground. That fits section 3. A calendar with a fighter every week wouldn't.

**The minimum bank before any launch:** (1) two fighters past the launch five, finished and director-accepted; (2) Overload complete; (3) the dare pool, the daily pool grown from 11 rows to about 20, and the weekly count; (4) the Tower season rule; (5) one event shell on MemoryStore (approved free, rule 1); (6) Draft Climb at block. OPINION: 90 to 110 team-hours, six to eight days at our observed pace. That's the price of not going dark in week 3, and it moves any date: **the director's yes.**

### (d) The goals, reviewed

- **The size is uneven** (OBSERVED, `Definitions/Goals.luau`). "Keep a dare" is one stretch. "Win three Tower floors" is under a minute (`docs/balance.md`). "Bring down the Lamplighter" is a whole 10 to 15 minute run, three times the design's "about five minutes past" ordinary play. The two one-hour base goals run while away, which is good: set it, come back.
- **The reward stops meaning anything.** "Each pays a reveal" holds while there's someone new to reveal. With five Voidkin, by day 2 a goal pays one copy toward 127 (`design-review.md`, challenge 1, says the same of every shard). And the shop sells two Standard shards every five minutes for Credits, so a goal's shard is small change.
- **The dares are solved by the fourth run.** One fixed dare a stretch, paying one Low stone. The three Kinds (`Above`, `Do`, `Avoid`) already exist, so a pool is words and rows.
- **What would make today's three worth opening the game for:**
  1. **A week's count.** Each goal claimed is one mark. Twelve marks of a possible 21 opens the week's crate: the player picks one of three (a Named shard of a Voidkin they choose, a Medium stone bundle, a Tower chest). A choice, never a roll. Twelve is four full days or six light ones, so a missed day costs nothing (findings 3 and 6). Weekly goals are "Not at launch" by the director's word: **their yes**, or it ships as Update 1.
  2. **Tomorrow's three shown tonight**, on the session's last card (the ladder, day 1).
  3. **The claim says what it did:** "Lyric: 3 of 8 copies to her next star", not just a shard.
  4. **One goal a day names a class or type** ("Lead a run with an Assassin"), so a second and third lead get raised.
  5. **Move the keeper goal to the week's list**, and keep each daily under about three minutes of extra play.
  6. **The dare pool** (three a stretch, the day's seed picks), research's words through the content check as today.

### (e) Cut or hold

| System | Call | Why |
|---|---|---|
| The Clash Grounds | Cut from launch (**director's yes**) | A large build whose act is watching five mirrors (`design-review.md`, challenge 8). Its "daily track" becomes the week's count. |
| Saved-player Tower teams, any async arena | Hold until 12 or more Voidkin | Finding 13. |
| A sold pass | Hold until two free seasons have run and D7 is known | Finding 17; the store's piece. |
| A login calendar, any streak that can break | Don't build | Banked goals already do the job without a loss (finding 6). |
| The Research Lab and Research Points | Hold | A currency with no source and no sink at launch (`design-holes.md`, "Checked and fine"). |
| The Calamity | Hold until parties | The event shell in week 5 gives a shared goal for a tenth of the build. |
| Stars as the month's chase | Keep, don't lean on | 127 copies for about 10% of base. |
| The "battery full" notification | Do, on the **director's word** | The exact case Roblox's page describes (finding 8). |

## 5. A frank critique

- **We wrote a rule for updates and stocked nothing.** "Every 2 to 4 weeks" has no owner, no calendar and no shelf. With today's queue the first update would be the first thing we failed to ship.
- **The game tells the player it's over.** The Next list ends on a shut gate at about hour 5. Its last line should always point at something that changes: the week's faults, the season, the next named update.
- **Our only weekly system is grey and out of sight.** The Tower's week and board exist in code, and Home's panel doesn't lead with them (check before acting).
- **The month rests on the part others want cut.** Fourteen gear slots are the only 18-hour content, and `design-review.md` (challenge 5) asks to shrink them. If gear shrinks, modes have to carry the month. That makes mode A more urgent, not less.
- **Every calendar is a guess until one fighter is accepted.** No Voidkin has passed the director end to end. Rook's redesign (AR59) is in flight: its true hours, from first take to accepted and installed, are the unit this whole plan is priced in.
- **The daily reward was designed for a roster of 31.** At five it's a copy. Fix the reward's meaning before adding goals.

## Top 5 to act on

1. **Time one fighter end to end.** Rook's redesign, from AR59's first take to the director's acceptance and the install, logged as one number. Who: research keeps the clock; Modulo and Faber log their lines. Cost: none extra. No yes needed.
2. **Close the day loop with what's nearly there:** TR53's return card (queued), tomorrow's three on the session's last card (Faber, 1 to 2 h, tier 1), and the claim that says what the copy did (Faber, 1 h). Then the week's count and crate (research 2 h, Faber about 4 h): **director's yes**, since weekly goals are "Not at launch".
3. **Design Overload now, build it as the first banked update.** Research writes the request with the eight faults and their numbers (3 h); Faber builds after the freeze (10 to 12 h); Modulo, eight marks (2 h). **Director's yes** (a new mode).
4. **Adopt the bank rule:** no launch without two more accepted fighters, Updates 1 and 2 finished, and the event shell. About 90 to 110 team-hours, OPINION. **Director's yes**: it moves any date and touches the cut line.
5. **Cut the Clash Grounds from launch and hold the pass, the arena, the Lab and the Calamity** as in (e). Who: the director decides, research records. Cost: none; it frees phase 5's hours for the bank. **Director's yes.**

**Couldn't fetch:** Quantic Foundry's model page (403); every Fandom wiki, Anime Vanguards' own update log included (402); Sportskeeda and Pro Game Guides patch notes (403); Roblox's Terms of Use page (403), so the reported "dark patterns" clause is unverified; the staff post behind the August 2026 feed rule; a Roblox quest-design page (404). Wikipedia's pages on Star Rail and Genshin say nothing on their modes or event structure, so those two rest on Naavik alone. The search budget ended before Grow a Garden's and Pet Simulator 99's own logs, pass data from GameRefinery, and Genshin's event structure could be searched.
