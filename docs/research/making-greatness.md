# Making it great: the order of work, the details, Roblox's levers

Asked by the director, 2026-11-23, near midnight: research takes the lead for a few days, and "deploy some subagent to do research on how to fully design a game whitout messing a bit and the small details that had big impact on a game quality ... we really should not fear from making greatness". Read on 2026-11-24 by four research subagents. Each finding is SOURCED (its link) or UNVERIFIED. None was tested by us. The plan this study leads to is the last section.

## 1. The order of work

- **Make one slice publishable before production** (SOURCED: [Cerny's Method](https://www.slideshare.net/holtt/cerny-method)). Preproduction ends with a first playable at publishable quality, with the scope set, the art direction in place and behaviour defined. "Your project will not miraculously get better during Production!" Throwing work out is productive, not a failure.
- **Find the fun in one place, then build out from it** (SOURCED: [Valve, Half-Life](https://www.jmeiners.com/shamans/papers/art/half_life_design.pdf)). After a year Half-Life "wasn't any fun": "wonderful individual pieces, but as a whole the game just wasn't working". Valve rebuilt one level from what was fun and worked out why ("experiential density": the next stimulus never waits long). The rest was designed from that.
- **Rough 15 minutes, playtested, every week or two** (SOURCED: [Valve, Half-Life 2](https://cdn.fastly.steamstatic.com/apps/valve/2006/GDC2006_HL2DesignProcess.pdf)). "Finish successful elements before moving on". "Art production is less risky than gameplay production". A final pass over the whole once it plays end to end.
- **Core first, look last** (SOURCED). Splatoon was picked from about 70 ideas because a 4v4 prototype in plain blocks existed, and the squid came last ([Iwata Asks](https://iwataasks.nintendo.com/interviews/wiiu/splatoon/0/0)). Breath of the Wild's rules were tested in a 2D mock-up first ([TechRadar](https://www.techradar.com/news/zelda-breath-of-the-wilds-creators-prototyped-with-the-original-nes-classic)).
- **Roblox's own order** (SOURCED: [Roblox docs](https://create.roblox.com/docs/get-started/strategies)). Set the KPIs before building. Get a minimal version to players early, iterate until the KPIs are met, then run live ops: minor updates every 1 to 2 weeks, major ones every 2 to 3 months.
- **Supercell's kill gate** (SOURCED: [Game Developer](https://gamedeveloper.com/business/quality-is-worth-killing-for-supercell-s-ruthless-approach-to-production), [Supercell](https://supercell.com/en/news/learning-from-failures/)). Of 10 games, 7 were killed in prototype, 2 at soft launch, and 1 shipped. The test moved from "Will this work?" to "Will we be proud of it?".
- **What sinks games** (SOURCED). Scope and feature creep are the top postmortem problems ([Petrillo](https://www.bohrium.com/paper-details/what-went-wrong-a-survey-of-problems-in-game-development/811871260073000961-16624)), and in 200 postmortems most causes are people and production, not technology ([arXiv](https://arxiv.org/abs/2009.02440v2)). Anthem's core was defined too late ([Kotaku](https://kotaku.com/how-biowares-anthem-went-wrong-1833487162)). On Roblox, Dungeon Life had strong production values and about 10% retention, with slow movement a top complaint ([Game Developer](https://gamedeveloper.com/business/my-roblox-years-dungeon-life-and-new-product-science)).
- **Keep peaks** (SOURCED: [Sakurai](https://www.gonintendo.com/contents/35714-sakurai-says-making-everything-in-a-game-fair-leads-to-bland-gameplay)). Making everything fair makes everything average, and enemies that scale with the player kill the feel of growth. Framing matters too: WoW's rest system, hated as a 50% cut, was loved as a 200% bonus, though it was the same mechanic ([Pardo](https://www.gamedeveloper.com/game-platforms/gdc-blizzard-s-core-game-design-concepts)).
- **Playtesting** (SOURCED: the Valve decks above; [Hodent](https://celiahodent.com/gamers-brain-ux-onboarding/); [RITE](https://en.wikipedia.org/wiki/RITE_Method); [Roblox DevRel](https://devforum.roblox.com/t/improving-onboarding-through-funnel-events/3064458)):
  - Watch a new player in silence: no hints and no answers.
  - Ask them to explain the goal back, never "is it clear?".
  - Fix a problem the moment it's seen, and test the fix with the next player.
  - Log each first-session step as a funnel event, to find where players drop. Roblox's own example lost 70% between two steps.
- **What Roblox ranks** (SOURCED: [Roblox discovery](https://create.roblox.com/docs/discovery), [Roblox newsroom, June 2026](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)). Since June 2026 the homepage weighs play-through rate, first-play bounce (as a negative), and play days and playtime per user over D1, D2 to 7 and D8 to 28. Then co-play days, qualified sessions and spend. Playtime is capped at 60 minutes a user a day.

## 2. The small details with big impact

- **A tap answers within 0.1 s, drawn on the client before the server agrees** (SOURCED: [NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/), [Gambetta](https://gabrielgambetta.com/client-side-prediction-server-reconciliation.html)).
- **Hitstop scales with the hit and is capped** (SOURCED: [Smash's formula](https://www.ssbwiki.com/Hitlag)): floor(damage × 0.65 + 6) frames, capped at 30, and ×1.5 for electric hits. Both fighters freeze, and the victim shakes with a fading shake. The attacker drifts slightly ([Sakurai, via Source Gaming](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)).
- **Impact rests on three things:** hitstop, sound that matches, and the camera. A weak one sinks it (SOURCED: [Steam reviews against 19 features](https://arxiv.org/abs/2208.06155)).
- **Sound and visuals:** good sound raises how good the visuals seem, and poor sound lowers it (SOURCED: [Storms and Zyda](https://mikezyda.com/resources/pubs/Presence9.6.pdf)). It lands on the contact frame; errors show past about 45 ms early or 125 ms late (SOURCED: [ITU-R BT.1359](https://en.wikipedia.org/wiki/Audio-to-video_synchronization)).
- **Many phone players are muted,** so every cue is also seen and felt (SOURCED: [TouchArcade, 73% with sound on in 2013](https://toucharcade.com/2013/11/05/73-of-mobile-gamers-play-with-the-sound-on/)). A later, lower figure couldn't be opened.
- **Juice in measure:** both none and extreme lowered players' experience, across 3,018 players (SOURCED: [Kao](https://dblp.uni-trier.de/rec/journals/entcom/Kao20.html)).
- **Shake from trauma, squared, on noise, with a direction and a decay** (SOURCED: [Eiserloh's GDC talk](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing); [anime's camera bump along the strike](https://jbsiraudin.github.io/blog/demon-slayer-visual-grammar)).
- **Anime's rhythm:** a long preparation, a strike often one frame long with one high-contrast impact frame, then a long recovery (SOURCED, a fan analysis: same link).
- **Flash safety:** three flashes a second at most (SOURCED: [WCAG](https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold.html)).
- **A hit unit flashes bright for a moment,** which is how Clash Royale reads hits at a phone's size. Each colour keeps one meaning everywhere (SOURCED: [The Rookies, Clash Royale](https://www.therookies.co/blog/game-design-ux-best-practices-detailed-breakdown-of-clash-royale/)).
- **UI motion** (SOURCED: [Material](https://m1.material.io/motion/duration-easing.html)): about 225 ms in with ease-out and 195 ms out with ease-in. Past 400 ms feels slow.
- **Sizes** (SOURCED: [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)): touch targets 44 pt, text at least 11 pt at 4.5:1 contrast, and never colour alone.
- **Fonts and colours, even on a plain settings menu, change how good the whole game feels** (SOURCED: [Sakurai](https://gonintendo.com/contents/20898-masahiro-sakurai-stresses-the-importance-of-fonts-and-menu-design-in-latest-dev)).
- **Onboarding** (SOURCED: [Hodent](https://celiahodent.com/gamers-brain-ux-onboarding/), [Roblox](https://create.roblox.com/docs/production/game-design/onboarding)):
  - three new things at most at once;
  - teach a thing when the player can use it;
  - nothing punishes while the player learns;
  - show the lock before the key;
  - end on a moment of joy;
  - one popup at most at the session's start.
- **A reveal tells the rarity before the fighter** (SOURCED: [Hearthstone](https://hearthstone.wiki.gg/wiki/Card_pack), [Honkai Star Rail via PC Gamer](https://www.pcgamer.com/uk/honkai-star-rails-gacha-animations-have-no-right-to-go-this-hard/)): a glow or a door colour, with music swelling on the top tier. Repeat openings get a fast mode.
- **Steady frame time at the hit and the reveal** (SOURCED: [NVIDIA, 38 players](https://research.nvidia.com/publication/2025-09_timing-matters-impact-event-specific-frametime-spikes-first-person-shooter)): spikes at the key moment hurt both accuracy and how smooth it feels.
- **UNVERIFIED but common:** every state is drawn (empty, loading, error, maxed, locked); rewards count up and fly to their counter; repeated sounds vary slightly in pitch.

## 3. Roblox's levers, and how the anime games present a unit

- **Ranking** (SOURCED: [Roblox discovery](https://create.roblox.com/docs/en-us/discovery.md), [FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md), [newsroom, 2026-06-15](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), [DevForum, 2026-03-09](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)):
  - **The order:** play-through rate from a Home impression; first-play bounce, a negative measured under 60 s and at 61 to 180 s; play days per user; playtime per user, capped at 60 minutes a day. Then co-play days, qualified sessions, spend days and Robux.
  - **The windows:** D1, D2 to 7 and D8 to 28.
  - **Who counts:** only players who came from Home count. The signals are averages per user, so a small game with engaged players isn't penalised. New player groups are tested daily, and a weak start carries no penalty.
  - **New signals:** "deep play-through rate", and a "Standout Games" sort.
  - **Lookalikes:** a game "virtually indistinguishable" from others in its visuals and title is shown less. "If retention is low, focus on core gameplay first."
- **Thumbnails and icon** (SOURCED: [thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md), [staff tips](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689), [icons](https://create.roblox.com/docs/production/publishing/experience-icons)):
  - A custom 1920 x 1080 thumbnail is needed for any Home impression, with nothing essential at the bottom.
  - Personalisation runs 2 to 5 thumbnails and lifted play-through 12% on average (up to 56%). Vary the characters, places and motives shown; refresh at each update; never restart a test within 7 days.
  - The icon reads at about 150 px.
- **The first minutes** (SOURCED: [onboarding](https://create.roblox.com/docs/production/game-design/onboarding.md), [retention](https://create.roblox.com/docs/en-us/production/analytics/retention)): fun "ideally in 5 minutes or less", short-, mid- and long-term goals shown, and a "designed moment of joy". Tune it live with Experiments and Configs.
- **The bar for games with sessions over 25 minutes** (SOURCED: [GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report)): D1 median 10.8% and top 5% 24.8%; D7 median 1.8% and top 5% 6.4%. The median session is 6.6 minutes.
- **Mobile:** 80% of daily users in 2024 (SOURCED: [PocketGamer.biz](https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue)).
- **The 18+ payout rate** (SOURCED: [Roblox docs](https://create.roblox.com/docs/en-us/production/monetization/18-plus-devex-rate.md)): from 2026-06-08, a 42% higher payout on spend by age-checked US adults. A game isn't eligible "if a player can spawn into or swap to a R6 avatar at any point". NPCs aren't judged, so the Voidkin can stay R6. This is the director's call (monetization).
- **Standout Games** (SOURCED: [Roblox docs](https://create.roblox.com/docs/en-us/creator-programs/standout-games.md)): curated daily; it names RPGs as underrepresented, wants a look new to Roblox, deep meta systems, mobile optimisation and regular updates, and calls "a copy or reskin of a popular Roblox game" a hard sell.
- **Breakout hits** (SOURCED):
  - **Grow a Garden** ([GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)): plants grow offline, players gift newcomers, and an update every Saturday comes with a gift.
  - **99 Nights in the Forest** ([DevForum](https://devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940)):
    - built for co-play;
    - the client acts at once, the server checks after;
    - low part counts for phones;
    - "playtest, playtest";
    - a 45-minute party before each weekly update.
- **Anime Vanguards** (SOURCED, from guide sites; some seen as snippets only):
  - **The start:** three free starters, a short tutorial, the summon portal in the hub, then stage 1.
  - **Pay for collecting:** free gems for each unit collected (a Collection) and each enemy found (an Enemy Index).
  - **The summon board:** a big board over the summon area shows the featured units, resets hourly, and shows pity at 50 and 400.
  - **The reveal:** players turn on "Skip Summon Animation".
  - **Updates:** a part about every 3 weeks, and the update's name sits in the game's title.
- **Anime Last Stand** ([itemlevel](https://itemlevel.net/anime-last-stand-complete-beginners-guide/)): daily rewards on the first login, the summon area in sight from spawn, pity, a countdown and the odds on its screen, and a numbered update about every 10 to 14 days.
- **Anime Defenders** ([rowatcher](https://rowatcher.com/games/5836869368/anime-defenders)): 3.4 billion visits, now about 95 concurrent players. A collapse.
- **Anime Adventures** ([allthings.how](https://allthings.how/anime-adventures-roblox-return-tensura-reveal-and-the-re-adventures-dmca/)): pulled offline over licensing, then about 18 months of silence; its studio's licensed spin-off came later. No unit pictures could be read: its wiki refuses automated reads (`animeadventures.fandom.com/wiki/Unit_List`, by hand).
- **The units' make on R6:** painted Shirt and Pants textures with cel tones and drawn folds, one large smooth hair piece, a decal face with big eyes. The "anime" read rides on effects and animation as much as the mesh. UNVERIFIED as text, and OBSERVED in our own pictures (AR59, "The redo").

## 4. Where we stand (an audit of the repo at 8afb600, 2026-11-24, 00:01)

A read-only subagent built this from the records, the code and git, with each state's evidence. A state it couldn't confirm is marked so.
- **In the game and passed:** the circuit (TR2), the HUD (TR3), the reveal (TR4), Lantern Row (TR8), the Breaker's screen (TR41), the Lamplighter (AR7), the base's sizes (AR16), the bag (TR28), the two attributes (TR36), the machines' stages (TR51, AR54), TR10, TR50.
- **In the game, not passed:**
  - the Tower (TR29 "works"; TR46 open since 11-19);
  - the Forge and the Condenser (TR37, "works, as grey");
  - the stages (TR43) and the slam's pick (TR44, open since 11-19);
  - TR52 and AR52;
  - the music: built, but every track list is empty (TR35).
  - Items, chests, emblems and jewels, gear's budgets and the Void Shop's shelf are in, but their passes are unconfirmed.
- **Made, not installed:**
  - AR23, AR24's A, AR36, AR53, AR55, AR56 and AR57, plus AR58's behaviour;
  - AR26's five basic attacks and AR27's four idles, which the director parked until the end.
- **Written only:** the return card (TR53), goals (TR54), inspecting a player (TR33), the chests' opening show (TR34). **Not started:** parties, the Robux store, the finish pass, the game page.
- **The five Voidkin:** every look is from before the bar, and the redo started with Rook (AR59). None has its own basic attack in the game. Kirra's Scarf Step and Watt's Ground Wire aren't passed.
- **Launch blockers nobody had counted:**
  - Only two clips are published (`Config/Animations.luau`, `Ids`), and an unpublished clip "plays in Studio ... and not at all live". So in a live server no Voidkin, Shade or keeper animates, apart from AR52's two.
  - The real-phone run waits on the publish (the board's item 4).
- **Pace:**
  - **Commits:** 659 since 2026-11-17, 20% of them touching `src/`.
  - **Docs:** `docs/` grew 69% (asset-requests from 12,761 to 16,860 lines), against `src/` growing 63%, 0.85 MB of which is tests.
  - **The install queue:** art outpaces install, and Faber's queue went from about seven to about ten pieces in a day.
- **Stale records:** the production plan's status line is from 11-17. The board's count says 0 pieces closed this week, though TR10 and TR50 closed on 11-23. Six of the seven pieces in Modulo's "still Faber's" list are installed.

## 5. The plan (research's, 2026-11-24; what changes the core waits on the director's yes to research's lead)

1. **One publishable first session before anything else** (section 1: Cerny, Valve).
   - The first ten minutes on a phone, at Anime Vanguards' bar: arrive, break the first shard, the reveal, the first fight on Lantern Row, the return, a Voidkin set to work, the next goal.
   - No new system until it passes. The systems already in stay as they are.
2. **The look, in the order players see it:**
   - the Voidkin's make (AR59's redo: Rook, then Kirra and Pip);
   - the HUD composed as one design;
   - the base as an anime void place, with no real pylons, wires or hazard tape;
   - Lantern Row's night.
3. **The feel:** one audit of combat by capture against section 2, then the fixes:
   - hitstop scaled and capped, with both fighters frozen;
   - shake from trauma, with a direction;
   - the hit flash;
   - the sound on the contact frame;
   - an impact frame.
4. **The blockers:** every clip published under the group before any live test. Music in the empty lists.
5. **Measure:**
   - the first session's beats as funnel events;
   - a silent playtest each week by someone new, who explains the goal back.
6. **Less paper:**
   - one verdict per piece, under ten lines;
   - the board's count and the status line kept true;
   - the closed pieces of `docs/asset-requests.md` moved to the archive.
7. **The director's calls:**
   - the 18+ payout's condition on the player's avatar, R6 or not (UNCONFIRMED: it's a place setting outside Rojo);
   - a limited public test for real D1 data, which today's rule on public builds rules out;
   - the store.
