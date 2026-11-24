# Directing the game: how the best teams stay on course, and what we change

**Why.** The director says the project is "losing control of the wheel" while they're busy. This page collects what works for keeping a game on course, with sources, and gives frank fixes for a team of AI agents with one busy human.
It builds on `docs/research/making-greatness.md` (the order of work, the details, Roblox's levers) and doesn't repeat it.

Labels: **SOURCED** means a primary source or reputable reporting of one. **COMMUNITY** means a developer's post or a blog. **OPINION** means research's own call. Fetch notes: DevForum pages render empty to the fetcher, so they were read through their public `.json` view. GDC Vault talks were not fetched; their content comes from published write-ups, and those entries say so.

## 1. Vision tools that decide things

- **Pillars are filters, not slogans.** The test of a pillar is whether it settles an argument. Pillars name the experience, not a feature (God of War: "Combat, Father/Son, Exploration"). A feature that serves no pillar is scope creep. COMMUNITY: [Game Developer, design pillars](https://gamedeveloper.com/business/agile-game-development-part-2-design-pillars), [Design Pillars, What's your game really about](https://gamedevsjourney.substack.com/p/design-pillars-whats-your-game-really); the talks themselves weren't fetched.
- **Gameplay first, and concentrate the coolness.** Blizzard's mantras were "gameplay first" (every discipline serves play), "easy to learn, almost impossible to master", "make everything overpowered" ("take everything to 11") and "concentrated coolness". SOURCED: [Pardo at GDC 2010, Game Developer](https://www.gamedeveloper.com/game-platforms/gdc-blizzard-s-core-game-design-concepts); [Raph Koster's notes, 2006](https://www.raphkoster.com/?p=678).
- **Essential experience first.** Schell's lenses start from "what experience do I want the player to have?" before any mechanic. MDA says players meet the aesthetics first and designers touch only the mechanics, so a team designs backwards from the feeling. SOURCED: [Schell, *The Art of Game Design*, table of lenses](https://www.oreilly.com/library/view/the-art-of/9781466598645/xhtml/table.xhtml); [Hunicke, LeBlanc and Zubek, MDA (2004)](https://users.cs.northwestern.edu/%7Ehunicke/MDA.pdf).
- **Loved by a few beats liked by all.** Rosewater: "If everyone likes your game but no one loves it, it will fail". Also: "Restrictions breed creativity". SOURCED, from secondary write-ups of the talk: [GDC 2016 listing](https://gdcvault.com/play/1022941/Twenty-Years-Twenty), [notes](https://notes.hamatti.org/sources/talks/'magic-the-gathering'-20-years,-20-lessons-learned-by-mark-rosewater).
- **Non-goals.** A design states what the game deliberately leaves out, so a cut needs no new argument. COMMUNITY: [GDD structure, non-goals](https://gamedesignskills.com/game-design/gdd-structure-formatting-guidelines/).

## 2. Decision hygiene

- **One-way doors versus two-way doors.** Irreversible decisions get slow care. Reversible ones are made fast by one person. Organisations drift into applying the slow process to everything. SOURCED: [Bezos, 2015 letter, via Business Insider](https://businessinsider.in/jeff-bezos-there-are-two-types-of-decisions-to-make-and-dont-confuse-them/amp_articleshow/51706758.cms).
- **About 70% of the information, then disagree and commit.** Most decisions should be made with about 70% of the information you'd want. Waiting for 90% means being slow. A person who disagrees says so, then commits. SOURCED: [Bezos, 2016 letter, full text](https://www.geekwire.com/2017/full-text-annual-letter-amazon-ceo-jeff-bezos-explains-avoid-becoming-day-2-company/).
- **Critique without authority.** Pixar's Braintrust gives the director candid notes, but "the Braintrust has no authority". The director owns the fix, which keeps the notes honest and the vision single. SOURCED: [Catmull, Stanford transcript](https://stvp.stanford.edu/wp-content/uploads/sites/3/2024/09/inside-the-braintrust-transcript.pdf).
- **Kill criteria written in advance, as a state plus a date.** For example: "by Friday, five testers do X without help, or we stop." Tackle the hardest unknown first ("monkeys before pedestals"). People quit too late because of sunk cost. SOURCED: [Annie Duke, *Quit*, Deloitte interview](https://www.deloitte.com/us/en/insights/topics/business-strategy-growth/annie-duke-interview-art-of-quitting.html).
- **Kills are celebrated.** Supercell's cells of about five people kill their own games at the prototype stage, after company-wide testing and in beta. Smash Land was killed after nine months, even though it "could have been a top 25 grossing game". Failure is debriefed, never blamed. SOURCED: [GamesBeat](https://gamesbeat.com/how-supercell-kills-its-darlings-to-focus-on-potential-hits/), [PocketGamer.biz](http://www.pocketgamer.biz/why-supercell-built-a-company-of-startups-and-how-it-works/).
- **Appetite, not estimate, with a circuit breaker.** Fix the time a piece is worth and vary its scope. Work that misses its cycle is "cancelled by default instead of extended by default". SOURCED: [Basecamp, *Shape Up*](https://basecamp.com/shapeup/2.2-chapter-08).
- **Upend the tea table early, never late.** Miyamoto now says "what if we didn't do this?" at the start, and "no longer [comes] in mid-development to completely rework things". SOURCED: [Nintendo Life, 2020](https://nintendolife.com/news/2020/03/miyamoto_has_broken_his_habit_of_completely_reworking_games_mid-development).
- **Plan churn is a cost.** Team Lava Escape changed its plan six times before launch. One early decision raised the whole cost by about 1.5 times, and it launched with three levels. COMMUNITY: [DevForum, 2 years on](https://devforum.roblox.com/t/team-lava-escape-2-years-on-revealing-everything/4135561).

## 3. Finding the fun

- **Something playable before anything else.** "If you have not created something that can be played, it's not a damn game." Make the most basic interactions fun first. SOURCED: [Derek Yu, *Finishing a game*](https://makegames.tumblr.com/post/1136623767/finishing-a-game).
- **Ugly but fun.** Riot's prototypes target "ugly but fun" and don't accept "maybe" as an answer. The stage ends on a representative slice plus "proof that the audience likes the experience via playtesting". Teams assume "most of our ideas won't work out". SOURCED: [Riot R&D, Prototype](https://www.riotgames.com/en/r-and-d-office/prototype-building-a-games-substance). TFT threw out its prototype and built the game in 10 weeks: [Riot](https://riotgames.com/en/news/tf-t-minus-ten-weeks-the-story-of-tft-part-2).
- **Choose by the playable, not the pitch.** Splatoon was picked from about 70 ideas because its tofu-block prototype was fun to play. Squids came later. SOURCED: [Iwata Asks, Splatoon](https://www.nintendo.co.uk/Iwata-Asks/Iwata-Asks-Splatoon/Splatoon/2-Then-Rabbits/2-Then-Rabbits-1021367.html).
- **A publishable first playable.** Cerny's Method ends pre-production on a first playable good enough to ship, with tests of 2 to 5 players watched. If a team can't make that, production won't fix the game. SOURCED, from secondary summaries of the slides: [Cerny, Method](https://www.slideshare.net/holtt/cerny-method).
- **Playtest early and often.** Half-Life wasn't working two months before its planned ship date, so Valve restarted it with frequent playtests from three months into the restart. SOURCED: [GMTK on the Cabal](https://gmtk.substack.com/p/valves-secret-weapon).
- **How many testers.** Five testers per round find most problems, and three rounds of five beat one round of fifteen, because each round tests the fixes. This holds for similar users. For a mixed audience, run a round per segment. SOURCED: [Nielsen Norman Group](https://nngroup.com/articles/why-you-only-need-to-test-with-5-users/).
- **Players find problems, designers find fixes.** Watch what players do. Treat their proposed solutions with suspicion. SOURCED (Rosewater's lesson 19, via write-ups): see section 1's links.
- **What to watch.** Watch where they hesitate, what they try that the game doesn't allow, when they stop looking at the screen, and whether they can explain the goal back. OPINION, from the sources above.
- **Roblox's own metrics.** Watch D1, D7 and average session time first. Build funnel events for the first minutes, where "you lose the majority of your users". Funnel events send only from the server, in a published place, never from Studio. SOURCED: [Roblox analytics](https://create.roblox.com/docs/production/analytics), [funnel events](https://create.roblox.com/docs/production/analytics/funnel-events), [onboarding](https://create.roblox.com/docs/production/game-design/onboarding.md).
- **What Roblox's recommendations reward.** Play-through after an impression, session quality and a 28-day view of retention. SOURCED: [Roblox newsroom, 2026-06](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), [Discovery docs](https://create.roblox.com/docs/production/promotion/discovery).
- **A rule of thumb for early numbers.** "At least 15% D1, and at least 8-9 min initial average session time". Fantasy Forest went from a 2-week prototype to 2,000 concurrent players in four weeks by raising session time from 9 to 13 minutes with content. It credits an RDC talk on rapid iteration. COMMUNITY, from one solo developer: [DevForum post-mortem](https://devforum.roblox.com/t/from-0-to-2000-players-in-4-weeks-fantasy-forest-launch-post-mortem/2044257).

## 4. Scope control

- **Cut it out, and respect the last 10%.** When you're behind, keep the core and cut the fluff. Save big new ideas for the next game. Final polish and bugs take most of the effort, so plan for that grind. SOURCED: [Derek Yu](https://makegames.tumblr.com/post/1136623767/finishing-a-game).
- **Start ridiculously small.** "Start ridiculously small and ridiculously simple." Scale is size, scope is density. COMMUNITY: [Lynn, Lessons of rapid prototyping](https://gamedeveloper.com/business/lessons-of-rapid-prototyping). Vlambeer gave a big project about two weeks of prototyping and dropped it if the team wasn't still having fun. COMMUNITY: [Ismail, via Game Developer](https://www.gamedeveloper.com/game-platforms/how-to-prototype-a-game-in-under-7-days).
- **Ship small, then iterate on live data.** Grow a Garden was made in a few days. It grew from about 500 concurrent players with weekly updates to about 21 million. Later, rushed and repetitive events drew complaints, and the team reset toward depth. SOURCED: [GamesBeat, Jandel interview](https://gamesbeat.com/janzen-madsen-interview/), [PC Gamer](https://www.pcgamer.com/games/survival-crafting/robloxs-top-experience-grow-a-garden-is-shifting-into-a-new-era-and-promises-deeper-farming-after-a-series-of-disappointing-updates-i-hope-the-community-can-see-this-change-as-a-positive-attempt-to-keep-the-game-fresh-and-enjoyable-for-everyone).
- **Signs of feature creep.** Several "order" lists that disagree, pieces made faster than they're installed, new content before the core loop has been played by an outsider, a stale status line, and a polish-later list that keeps growing. OPINION.

## 5. Process versus output

- **Use the simplest thing that works.** Add structure only when it measurably helps. SOURCED: [Anthropic, Building effective agents](https://anthropic.com/engineering/building-effective-agents).
- **Signs that paper is eating production.** Records grow faster than playable pieces close. A verdict is longer than the change it judges. A busy director can't read the status in two minutes. Rules multiply faster than outcomes. OPINION.
- **Lightweight rituals that work.** A playable build every week that someone new plays. One ranked list. A short check-in with the decision-maker that runs on a prepared digest. Each comes from the sources above (Cerny, Valve, Riot, Shape Up). OPINION as a package.

## 6. AI teammates: value over volume

- **Delegation needs an objective, an output format, the tools and a boundary.** Without them, agents "duplicate work, leave gaps". Scale effort to the task: simple jobs need about 3 to 10 tool calls. Multi-agent work uses about 15 times the tokens of a chat, and coding parallelises poorly. "Manual testing remains essential." SOURCED: [Anthropic, multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system).
- **AI judges flatter.** Trained assistants tell users what they want to hear (sycophancy). AI judges favour longer answers (verbosity bias) and their own output (self-enhancement), though a 2026 replication finds some of these effects weaker in newer models. SOURCED: [Sharma et al., 2023](https://arxiv.org/abs/2310.13548); [Zheng et al., 2023](https://arxiv.org/abs/2306.05685).
- **So an AI verdict needs ground truth.** Strangers playing, a timer and the funnel, not another AI's prose. OPINION.

## For our team (frank)

What the repo shows (latest main, read-only, 2026-11-24):

**Paper outweighs play.**
- `docs/*.md` is 24,316 lines.
- `asset-requests.md` alone is 17,054 lines (438 entries), and `test-requests.md` is 4,931.
- The median of the last 202 commit messages is about 400 characters of prose, and the longest is 831.
- `making-greatness.md` measured docs growing 69% in a week.

**Nobody outside the team has played it.**
- The publish (board item 4) is still waiting.
- No funnel or D1 data can exist until there is a published place.
- Every quality call is an AI verdict ("competent"), which section 6 says flatters.

**Too many "orders".**
- The production plan carries a phase 3 order of 11-17 (12 items for Modulo).
- It also carries a design-review order of 11-18 (11 items for Faber).
- The board adds its own orders, and making-greatness adds a 7-point plan.
- The status line is from 11-17.

**Content before the loop.**
- Made and still waiting on install: the Tower room (AR56), Shade elites (AR57), a Support Shade (AR58), stage art.
- Meanwhile no first session has been played on a phone, and the live build animates nothing, because only two clips are published.

**Late table-flips.**
- The Voidkin redesigns were parked "for the end" (11-17), then started on 11-23.
- Rook's make was then rejected whole, and his hair was redone three times in a night.
- These are the director's calls to make, but each late flip costs more than an early one (Miyamoto).

**The pillars are good but unused as filters.**
- No piece entry says which pillar or which first-session beat it serves, so nothing gets cut on a pillar.
- Pillar 4 ("looks expensive") is a quality bar, not a direction. The bar is already in "The bar: premium".

**The judge designs too.**
- While the director is away, research designs, orders the work and passes it.
- A Braintrust works because it has no authority. Here the critic and the decider are the same agent.

Concrete practices (OPINION). The ones marked * change the core and need the director's yes to a restatement first.

1. **One sentence, three ranked pillars, a short not-list.** For example: "Break shards, meet a Voidkin worth keeping, and watch it hit hard for you". The ranking settles conflicts. *
2. **Every piece names its beat.** A request names the first-session beat it improves (Arrive, Choose, Fight, Find, Work, Build, Want), plus its appetite and its kill criterion as a state and a date. A piece with no beat goes to Later.
3. **One ranked list, in one home.** It has three columns: Now (at most 3 per teammate), Next and Later. It replaces the plan's order lists and the board's order lines. Everything else links to it. *
4. **A weekly publish and five strangers.** The same day every week:
   - the private place is published;
   - five people who haven't played it play it on phones, silent, while their screens are recorded;
   - each explains the goal back;
   - the funnel events for the seven beats go in now, since they need a published place.

   The director recruits the testers (group members, friends), at no cost. Three rounds of five beat one of fifteen.
5. **Real numbers as the target.**
   - From the first public test: D1 of at least 15% and a session of at least 8 to 9 minutes (Fantasy Forest's floor, COMMUNITY), compared against Roblox's benchmark panel.
   - Before then, the "pass" for a beat is: 4 of 5 testers do it unaided.
   - The premium rule for public builds collides with this evidence, so a limited public test is the director's call (tier 3).
6. **A circuit breaker.** A piece that blows its appetite is cut down or killed, never extended by default. The existing caps (block 1 h, effect 2 h) become logged facts: the overrun is written in the count.
7. **A paper diet, with numbers.**
   - A verdict is at most 10 lines.
   - A request entry is at most 30 lines.
   - A commit has a subject of at most 72 characters and a body of at most 3 lines.
   - Closed AR and TR entries move to the archive each week.
   - The board shows each week: lines of docs added against pieces closed and playable.
8. **Verdicts with a fresh judge and a human check.** A design isn't passed by the agent that wrote it. A fresh-context reviewer or QA passes it, and on a piece players see, the weekly testers do. An AI verdict reads "provisional" until a human has played it.
9. **Disagreement on a template.** Each proposal carries "the strongest case against" and a one-line pre-mortem ("this fails if..."). A critic's note never decides by itself (the Braintrust rule). Anything reversible is decided within the day by its owner; only a one-way door waits for the director.
10. **Install before you make.** No new art piece starts while three or more made pieces wait on install. The bottleneck sets the pace.
11. **Flip the table early.** The director sees three rough takes at the blockout, and their pick is final there. After the pick, a new idea goes to polish-later, as the rules already say.

## A director's week (15 minutes, plus one playtest)

1. **Monday, 5 minutes:** read the one-screen digest: the build link, a 2-minute capture of the first session, the count, and three decisions at most.
2. **Each decision** comes with a recommendation, the case against it, whether it's a one-way or a two-way door, and a "by" date.
3. **Answer the decisions** in one line each. A two-way door left unanswered by its date goes ahead on the recommendation. *
4. **Reorder the top five** of the one list if you want. Nothing else needs your reading.
5. **Midweek, 5 minutes:** play the newest build on your phone and note the one thing that annoyed you most.
6. **That note** becomes the top of Next, not a mid-piece rewrite.
7. **Friday:** the five testers play, and research brings one line per beat: pass or fail, with a video timestamp.
8. **Friday, 5 minutes:** see the result, kill one thing that isn't working, and celebrate the kill.
9. **The team meanwhile:** builds only from Now, installs before it makes, and writes nothing longer than its caps.
10. **Each month:** reread the sentence and the pillars, and cut whatever serves neither.

## Top 5 to act on

1. **Publish every week, and have five strangers play the first session on phones.** Add the funnel events for the seven beats. Until then, every verdict is provisional.
2. **One ranked list,** with at most 3 items in Now per teammate. Each piece names its first-session beat, its appetite and its kill criterion (a state and a date). The plan's old order lists retire.
3. **A circuit breaker:** an overrun is cut or killed, never extended by default. No new art starts while three or more pieces wait on install.
4. **A paper diet:** verdicts at most 10 lines, requests at most 30, commit subjects at most 72 characters, closed entries archived weekly, and a docs-against-playable count on the board.
5. **A 15-minute director's week:** a one-screen digest with at most three decisions. Each decision has a recommendation, a door type and a date, and a two-way door goes ahead on the recommendation if unanswered. This needs the director's yes, since "silence is not acceptance" is a rule today.
