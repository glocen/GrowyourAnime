# Decisions

The decisions in force: what binds the work today, grouped, one line each. A status changes on the director's word, or by the tier the change calls for (`AGENTS.md`, "Design changes"). The design itself is in `docs/design.md`.

**The words, whole:** every word of the director's, with its date and what it covers, proposals and rejections included, is in the month's word log, `docs/archive/decisions-words-2026-11.md`. `L<n>` below is a line of that log. A new word goes in the log's last section, "Words after the split", newest on top, so the line numbers above it never move; it changes its line here in the same commit.

## The game and its scope

- Player title "Grow your Anime". Working name GrowyourAnime. L184 [2026-11-11]
- Aim for a premium first session and track its beats in Roblox's onboarding funnel. L178,292 [2026-11-11] [2026-11-16, 21:39]
- Pick Rook, Kirra or Pip from free starter shards. The first enemy drops Watt's Named shard. L173,375 [2026-11-11]
- Launch with Lantern Row only and five finished Voidkin. Other Arcs wait. L226,283 [2026-11-13] [2026-11-17, 02:40]
- Launch includes Tower, Forge, Jewels and War Emblems. Clash Grounds must reach the bar. Parties, Rift, Research Lab and Calamity wait. L386,283,346,130 [2026-11-11] [2026-11-17, 02:40] [2026-11-15, night] [2026-11-18, about 22:20]
- Point new players to Hard Lamplighter, the Tower door and featured shop stock. Drum Court stays shut until its update. L99 [2026-11-23, 15:06]
- Keep quests "js basic at launch". Fixed play-based dares pay forge stones. Three daily goals pay shards, reset at 00:00 UTC and bank up to three days. Show "Next" first. L98,97 [2026-11-23, 15:23 and 15:24] [2026-11-23, 18:35]
- Cut the Mask Ledger. Masks stay on Lantern Row foes only. L97 [2026-11-23, 18:35]
- The five launch Voidkin get earned cosmetic forms "post early access", with no stats or sales. L137,140 [2026-11-18, 22:00]
- Aim at a fuller launch, with global messages and a chest for each launch item, plus additions the team proposes, each through its tier. L85 [2026-11-24, by 10:45]

## The rules of work

- Shorten AGENTS.md with the supreme rules word for word and Codex's lost-rule check. Split decisions.md into the decisions in force and the words kept whole in a monthly log. One file per open piece, with the request files as indexes, after a pilot. Then the game first. L14 [2026-11-27, by 13:39]
- Codex finishes the lean audit and checks Turing. Research applies the fixes and focuses on shipping. Gemini resumes at reset. L21,25 [2026-11-27, by 12:41] [2026-11-27, by 12:24]
- Keep verdicts under eight lines. Use a fresh reader to check specs for signature pieces only. L74 [2026-11-24, by 14:05]
- Use one playtest take and one lighting state for review. Run affected and offline cases at finish, and the full suite at phase close and after shared-code changes. L332,334,336 [2026-11-15, night]
- Research chooses system reworks and overhauls. Polish before speed and new content. L53,54 [2026-11-26, by 14:06] [2026-11-26, about 13:25 to 13:28]
- While the director is away (until they say they're back), research leads in their stead within the vision. Each call is a dated row marked "research, in the director's stead", with a daily digest, and the director reverses any call on return. Never the vision, the rules, spending, accounts, publishing, the store or doubts about Roblox's rules. Whether this still runs is asked under "Waiting on the director". L89,83 [2026-11-24, about 01:58] [2026-11-24, 11:11]
- Judge the director's ideas on merit, and change or drop a weak one with the reason said. A core change still needs the restatement and a yes. L40 [2026-11-26, between 22:37 and 22:57]
- When a piece is short of the bar, study how shipped, high-quality Roblox games do it before iterating further ("just study if u struggle"). L47,16 [2026-11-26, by 21:04] [2026-11-27, by 13:32]

## Combat and balance

- Measure actual ranged and knockback matchups against melee before tuning, starting with Pip versus Rook. Preserve class identity and give melee a chance to close. L23 [2026-11-27, by 12:31]
- Bonuses add ("x + x + x"). Builds can take endgame fights past three minutes. L176,187 [2026-11-11]
- The lead owns health and the hurtbox. Fallen leads heal at base and can be swapped out of combat. Flat Regen bursts every 8 seconds, even in combat. L376,234,267 [2026-11-11] [2026-11-14, night] [2026-11-17, by 12:54]
- Ranged leads keep their distance. Tap to move is a trial block on the grey pad, "an nice bonus" that decides only close fights, and fights are won by the build. Research's seeds: reach 10 studs, recovery 3 s, and a clean tapper ends a keeper fight at most 15 points of health above standing. The design changes only on the director's yes after playing it. L219,39,40 [2026-11-13] [2026-11-26, between 23:20 and 23:23] [2026-11-26, between 22:37 and 22:57]
- Trial tap-to-use signatures, then a battery-powered Charged start after the verdict. L100,84 [2026-11-23, about 14:20 to 14:50] [2026-11-24, 10:50]
- "the level cap is 125 but the launch is designed for level 60 simple is as that". For stat points, "Remove now, tree later". L235,241 [2026-11-14, night]
- Walk speed varies by class and Voidkin. The five Basic Attributes are Strength, Agility, Intelligence, Endurance and Spirit, one Main per class. L237,125 [2026-11-14, night] [2026-11-19, 03:10]
- Ratings use the owner's level. Lower-level damage takes a factor of 0.85 per level beyond a gap of two, with a 0.05 floor. No higher-level bonus. L125,107 [2026-11-19, 03:10] [2026-11-19, 20:57]
- Give Shades all stats and Hard its own increases. Block halves what remains outside the cap. Cap Lifesteal, give Health from Spirit and give all Voidkin an element. L107 [2026-11-19, 20:57]
- Critical Damage starts at +50% with no ceiling ("20k %" over updates). Critical chance caps at 100%. L330 [2026-11-15, night]
- CR measures the fight and skulls show its cost. Display one tenth of CR and keep gear comparisons unrounded. L139,107 [2026-11-18, 22:00] [2026-11-19, 20:57]
- Keep the camera still apart from hit shake and the turn inside the fade. Allow lead spectate. Cap simultaneous Shade attacks. L233,62 [2026-11-14, night] [2026-11-25, 21:41]

## Fighters (Voidkin) and their look

- Launch Rook, Kirra, Pip, Watt and Lyric. Install redesigns on director acceptance. Sable, Marigold and Crane wait. L283,92 [2026-11-17, 02:40] [2026-11-23, by 22:52]
- Use anime side-cast archetypes on R6. Allow some built attachments and exaggeration. L91,90 [2026-11-23, about 23:45 to 23:52] [2026-11-24, about 01:47]
- "voidkin shouldnt have the same face". Kirra's toy back blades become real gear, with a target first, and the hair is reworked a new way. Pip starts once Kirra's hair passes the director's look, with that fitted hair. L20,71,27 [2026-11-27, by 12:47] [2026-11-24, 16:53] [2026-11-27, 03:47]
- Visible weapons and clips fit the model. Combat rules and hitboxes follow the class. L297,54 [2026-11-16, 20:39 to 20:41] [2026-11-26, about 13:25 to 13:28]
- Keep Noct's name and signature. Judge recognition by the combination of look, weapon, signature and role. L85,415 [2026-11-24, by 10:45]
- Remove the recurring idle head tilt and glance. L278 [2026-11-17, by 10:10]
- Give each Voidkin its own M1, signature and effects. Common through Epic passives "should be really short and simple", with one effect and at most one plain condition. L283,100,361 [2026-11-17, 02:40] [2026-11-23, about 14:20 to 14:50] [2026-11-13]
- Spend copies by hand from level 1 for seven small star bonuses, "1 copy to make star 1 then 2 to make it star 2 then 4 to make star 3", doubling onward. Rook evolves at launch. L191,387 [2026-11-12] [2026-11-11]
- Aegir is a Mythical white wind mech. A new Legendary takes his former place. L185 [2026-11-11]

## Worlds and the base

- Use eight plots in two rows around the Void Shop, Void Clash and Calamity sites. Save bases to accounts. Vacant plots stay bare. L167,392,324 [2026-11-09] [2026-11-11] [2026-11-15, night]
- Give each Arc one place for both difficulties. The Festival Door connects base and Arc. L118,209 [2026-11-19, by 11:16] [2026-11-12]
- One Normal or Hard mission per Arc. Lantern Row has four distinct stretches, 10–15 minutes on Normal, checkpoints and a keeper-only fight after first clear. Review separate modes after early access. L106,102,19 [2026-11-19, 23:19] [2026-11-23, 03:25] [2026-11-27, 12:50]
- Use a server timer for elites and "Per player" for keepers. While down, show timer, loot and drop rates. L232 [2026-11-14]
- Festival parties wait until other work is done. Use reserved servers, carry saved health and progress, and return players home whole on transfer failure. L132,130 [2026-11-18, about 22:10] [2026-11-18, about 22:20]
- Tower uses one Voidkin in a temporary circular room away from the map. Carry health, reset on death and seed weekly after floor five. Keep the entrance and record marker by the plot. L119,299,300,386 [2026-11-19, by 11:12] [2026-11-16, 16:50] [2026-11-16, 13:41] [2026-11-11]
- No Tower landing or raised stand. Polish the cloud sea, add Leave with confirmation and revise two chat lines. L95,54 [2026-11-23, by 21:53] [2026-11-26, about 13:25 to 13:28]
- Overhaul Lantern Row's map, give the keeper a fight zone of his own, and overhaul the main map ("it should be changed and overhauled"). The order and the launch date are the director's answer. Log, "Words after the split" [2026-11-27, by 23:13]
- Cycle day, dusk and night. Festival dressing stays in Lantern Row. Give the Strip a void look and remove mist near the base. L302,301,298 [2026-11-16, night] [2026-11-16, 16:50]
- Plots are 128 studs square. Launch caps base at 3, with 2/3/4 bays and machine caps of 2/6/15. Items are needed past 3. L262,333,133,84 [2026-11-17, by 11:40] [2026-11-15, night] [2026-11-18, about 22:10] [2026-11-24, 10:50]
- Base levels change its look and capacity, with 20 as the longer-term top. Machine levels raise output. L207,335 [2026-11-12] [2026-11-15, night]
- Reduce bloom and clutter and make machines easy to distinguish. Redo models while keeping functions reachable. The Generator can be static. L58,51,52 [2026-11-26, between 12:19 and 12:30] [2026-11-26, about 17:46] [2026-11-26, by 17:33]
- Show owner and level on the gate, a chosen Voidkin and CR inside, and rarity light at working bays. L326 [2026-11-15, night]
- Bays feed Breaker, Condenser and Training, with Auto routing available. Battery covers shortfalls and infusion. Sell overflow. L242,381 [2026-11-14, night] [2026-11-11]
- Home Training works offline at about a third of Lantern Row fighting XP. Workers earn XP by kWh produced. L234,84 [2026-11-14, night] [2026-11-24, 10:50]
- The machine is the Generator. "Void Mill" is rejected, and names needn't contain Void. The director's own Void names (Void Breaker, Void Shop, Void Shards) stay. L52 [2026-11-26, by 17:33]

## UI

- Research picks the UI's directions, Modulo makes them, and the director judges in play. Meet "jujutsu infinite, sailor piece, anime crusader levels". Jujutsu Infinite and Sailor Piece "are just benchmark": they sit beside our build at the verdict and are never a source of ideas, layout or look. Codex finds the in-fight screenshots, which stay internal. An idea that stays bad across iterations is overhauled. L15,11 [2026-11-27, by 13:36] [2026-11-27, by 14:22]
- Overhaul all UI, including the galaxy Breaker and Voidkin rail, for a mature, high-quality and original look. Smallest phone text is at least 14 px. L31,32 [2026-11-27, about 02:31] [2026-11-27, about 02:16]
- Use M's dark neutral slate or warm graphite, light text and active orange. Clear the fight centre and put the skill press at the left thumb. L17,29 [2026-11-27, by 13:29] [2026-11-27, about 03:35]
- Overhaul the top-left lead plate: portrait, name, level and health bar. This is an overhaul, not a fix round: Modulo studies, then paints two or three compositions on Faber's capture beside today's plate, and research picks. It doesn't touch the press, AUTO, the eye, the foe's plate or (a)'s dark palette. The relay is UNVERIFIED until the director confirms it. The health bar's colour is open: red was asked for (11-13) and kept in a different red, smaller (11-15: "let keep red.."); on 11-27 the director said "i dont agree with the color hp and experience bar" and named no colour. L13,30,31,261 [2026-11-27, after 14:08] [2026-11-27, about 03:08] [2026-11-27, about 02:31] [2026-11-15]
- Use new skill art and redraw the shared cooldown. Keep press size and position. Shrink Auto and Spectate. L34,35,37 [2026-11-27, 01:39] [2026-11-27, by 01:00] [2026-11-26, between about 23:00 and 23:39]
- Show the full-screen return panel at load. Tap anywhere to close. "Reveal" is the sole button when shards are ready. L68,36 [2026-11-24, 21:13] [2026-11-27, by 00:04]
- Home opens three cards: Voidkin, Equipment and Settings, and pages are reached inside each screen. The cards' art is our own, drawn to the bar of the menu screenshots the director drops in `inbox/`. Never the equipped Voidkin or an item as key art ("skip that sword and rook just make an art"). If the art falls short, the cards get premium UI motion and finish instead. A paid illustrator is the director's call (rule 1). Home is part of the whole-UI overhaul, and the design is the team's call. L105,49,43,31,15 [2026-11-19, 23:20] [2026-11-26, by 20:28 and at 20:46] [2026-11-26, 20:57] [2026-11-27, about 02:31] [2026-11-27, by 13:36]
- Play opens modes. "Go to the Tower" teleports to the player's ring. Purple arrows "should only be there for a tutorial". L87,55,59 [2026-11-24, by 02:36] [2026-11-26, between 13:16 and 13:24] [2026-11-26, between 12:19 and 12:30]
- Base opens controls at home and teleports home on a cooldown outside combat, boss areas and events. Show the shard hint only at base. L333,359,259 [2026-11-15, night] [2026-11-15]
- Make UI motion smooth. Keep shine "inside or very close to the border". Respond to mouse hover or gamepad selection. L78,122,345 [2026-11-24, 13:37] [2026-11-19, 03:19] [2026-11-15, night]
- Use "American everywhere", "Arc" for ground, "always CR" for Combat Power and "Critical Immunity". L270,118,120,288 [2026-11-17, by 13:00 to 13:03] [2026-11-19, by 11:16] [2026-11-19, 10:36] [2026-11-17, by 00:17]
- Show gear slots only on the bag page and socket on Equipment pages. Stats use "Plain list, no taps", with chances and shares as percents only. L270,121,325,288 [2026-11-17, by 13:00 to 13:03] [2026-11-19, 03:37 and 03:38] [2026-11-15, night] [2026-11-17, by 00:17]
- Use distinct Shade, elite and keeper HUDs. Colour skulls and levels grey, white, yellow or red by fight cost. Shorten Credits and kWh at 100K. L117,362 [2026-11-19, by 11:30] [2026-11-13]
- Use gold critical digits with a slight chromatic sheen and orange splash, in our own shapes. L116,29 [2026-11-19, about 11:46] [2026-11-27, about 03:35]
- The director enables Roblox automatic translation. Keep Voidkin names untranslated. L136 [2026-11-18, about 22:10]
- No corny or "ai slop" lines in what players read. Already cut for this reason: the "Hard is open" band, "then its last foe", the Tower's "this server's best today" chat line, and "ROOK · SIGNATURE". L82,97,54,30 [2026-11-24, by 11:29] [2026-11-23, 18:35] [2026-11-26, about 13:25 to 13:28] [2026-11-27, about 03:08]
- AR62's style frame is stopped and holds nothing back: Pip is released from it, and AR68 covers the UI. This is the exception to AGENTS.md's "One style frame". L27 [2026-11-27, 03:47]

## Effects and sound

- Use one in-engine 3D effects kit and player. A manual "performance mode" reduces VFX. L224,229 [2026-11-13]
- Build shared combat effects before individual ones. Redo the thick, glass-like Guard shield after vault study. L100,57 [2026-11-23, about 14:20 to 14:50] [2026-11-26, 12:57]
- The outlined 2D fire is redone from the director's open-source packs as a new direction, among Pip's own effects after her redesign (Scintilla's). Haymaker's B5 is a planned rework, built in 3D, and not queued: its timing is the director's or the plan's. L273,100,92,213,224 [2026-11-17, 13:59] [2026-11-23, about 14:20 to 14:50] [2026-11-23, by 22:52] [2026-11-12] [2026-11-13]
- Use "one m1 sfx per type of class" and one finished sound per signature. L73 [2026-11-24, by 15:46]
- The director auditions cues. For the 22 named cues, Sonus picks unheard, the director judges in play and rejected cues take the next sound on their tab. L141,48 [2026-11-17, 23:24] [2026-11-26, 20:48]
- Music in a fight belongs to a mode, never to a fight alone. The director's own tracks in `Config.Music` stay, and the director removes one. Sonus offers a track only if it is genuinely good beside them; otherwise the director handles the music and Sonus works on SFX. This word doesn't change rule 3: research flagged the tracks once (TR35) and doesn't raise them again. L80,12 [2026-11-24, by 13:35] [2026-11-27, by 14:15]

## Economy, shop and monetization

- Keep Credits and electricity only. No premium currency or launch Credits sales. L84 [2026-11-24, 10:50]
- Sync the Void Shop every five minutes. Offer two Standard shards per player per stock and one previewable gear piece in featured stocks, for Credits. L172,134 [2026-11-09] [2026-11-18, about 22:10]
- Use two Breaker chambers growing to four, plus a queue. Show shard origin and "Drop rates" to 100%. Low voltage halves time left, High breaks instantly. Odds stay. L380,347,254 [2026-11-11] [2026-11-15]
- Later Breaker luck is capped and affects the top two tiers, excluding Named shards and the Rift. L382 [2026-11-11]
- Keep 14 account-wide gear slots in linked presets. Two weapon slots are class-specific, both swords for Warrior. Keep unusable drops. L402,63,297,300 [2026-11-11] [2026-11-25, before 21:41] [2026-11-16, 20:39 to 20:41] [2026-11-16, 13:41]
- Gear is 2D slot art, with several looks per rarity and no set bonus. Legendary changes the border alone. Dawn ranks above ordinary Legendary. L344,349,250,202 [2026-11-15, 17:20] [2026-11-15] [2026-11-12]
- Lock gear in combat and freeze it for keeper and Tower fights. Transfer item upgrades free on confirmation. Use Equipment anywhere or the base Forge. L384,283,266 [2026-11-11] [2026-11-17, 02:40] [2026-11-17, 12:25 (to Modulo, relayed) and 12:27]
- Reinforce always succeeds through +5. Failure spends stones and Credits, keeps rank and adds heat. Full heat guarantees the next try. Success clears heat. Heat transfers with rank. L125,84 [2026-11-19, 03:10] [2026-11-24, 10:50]
- Each item takes five jewel colours with flat stats. Fuse three for the next of five launch tiers. The Condenser makes jewels and stones offline. Crafting materials wait. L125,263,264 [2026-11-19, 03:10] [2026-11-17, 12:10] [2026-11-17, by 12:16]
- War Emblems span Uncommon to Legendary, with three cosmetic sets per rarity and one stat per emblem. Gear has one to four sockets by rarity. L124,408 [2026-11-19, 03:13] [2026-11-11]
- Auto-collect, stack and bulk-open enemy chests. The first reward fits the starter. Epic and Legendary are possible from the first chest. L300,299,109,135 [2026-11-16, 13:41] [2026-11-16, 16:50] [2026-11-19, about 20:55] [2026-11-18, about 22:10]
- No paid rolls at launch. Later rolls must be "as transparent as glass", with full odds, regional restrictions, a Roblox questionnaire and store approval. L190,126,84,390 [2026-11-12] [2026-11-19, about 03:12] [2026-11-24, 10:50] [2026-11-11]

## Tools, accounts and the PC

- Press 1 in the team launcher. Use Opus 5.5 high for Quaestor, Faber and Sonus, xhigh for Modulo and Scintilla. Faber goes xhigh on bugs unexplained after one pass. L166,26,65 [2026-11-09] [2026-11-27, by 11:50] [2026-11-25, by 21:32]
- Gemini uses the director's subscription at XHigh. Keep notes and transcripts in its workspace. Leave the daemon off. L45,41 [2026-11-26, between 21:17 and 21:36] [2026-11-26, between 22:08 and 22:20]
- Render SVG in the existing browser. Krita is approved for paint-overs, and NumPy, SciPy, pedalboard and pyloudnorm for local sound. L72,352 [2026-11-24, 20:52] [2026-11-15]
- Give Effects and Sound Studio play hooks and Effects guarded upload access. Allow Festival sync, playtest and save. L66,103 [2026-11-25, 21:28] [2026-11-23, 00:05]
- Balance reads Config via Lune. Test published clip IDs. Use global Exist serial blocks and crash-safe reveals. Show worker pull cost and a one-line gear trade. L62 [2026-11-25, 21:41]

## Release

- Launch free with "Early Access" in the title and on the page. No fixed date: launch when it's ready at the bar ("we will launch whenever it ready"; Sunday 2026-11-29 dropped). L264,22 [2026-11-17, by 12:16] [2026-11-27, by 12:34] [2026-11-27, by 23:15]
- The game page's icon: AR70's three Rook renders are rejected ("horrendous plain terribly bad"). The next starts from a study of the top games' icons on Roblox, and Rook isn't its centre ("Why rook stop making stuff then making it the center of the world"). Then (b)'s three Kirra icons are rejected too ("omfg horrible he cant make art he need to study"). Modulo studies the shipped icons before any more art, and the subject is a Roblox player ("why kirra why not a robllx player or sum"). Log, "Words after the split" [2026-11-27, by 17:10] [2026-11-27, by 18:29]
- Public release waits for the director. "Private publish OK (Recommended)" for the director's timed phone run. L86,84 [2026-11-24, by 02:47] [2026-11-24, 10:50]
- Ship delayed content in named updates every two to four weeks with featured stock. Set the order nearer launch. L99 [2026-11-23, 15:06]

## Fighters

The test every Voidkin passes (`AGENTS.md`, rule 3): it's ours if no published character is recognisable in it through a combination of look (silhouette, outfit, hair, colours), weapon, signature (what it does and what it's called) and role. Each may share one familiar trait with the genre; a match on several together is a redesign, and a new name never fixes it. The tone is "slightly mature" (`AGENTS.md`): attitude, styling and stakes, never sexualised poses or framing, never gore. The content check judges each sheet against this.

## Waiting on the director

Nothing blocks the team's start. These are the director's when they want them:

1. **The cut line** for launch, once the first ground is at the bar (`docs/production-plan.md`).
2. **The store's design,** before anything is sold. Research's proposal (2026-11-17, 21:10), for your yes or changes. It's tier 3, so nothing is written into the design before your word.
   - **Sold at launch (early access), none of it random and none of it power over another player:**
     - a **Founder's Mark**, sold only during early access: a title, a gold rim on the name plate, and the gate's plate in a founder's finish;
     - **more bag space**, as a pass;
     - **cosmetics**, made by Modulo as its queue allows: a reveal in another light (the crack's colour, never its odds), and the yard's lights in another theme;
     - **private servers**, Roblox's own, at a price you set or free.
   - **Not at launch, and why:**
     - **Credits for Robux, or a 2x Credits pass** (no Credits sold at launch: the director, 2026-11-24, 10:50, above). Credits buy shards that roll, so Robux would reach a roll. Whether a sure 2x counts is asked on Roblox's forum and not clearly answered.
     - **Faster breaks for Robux.** It isn't checked yet whether more rolls an hour, bought, counts as a paid roll.
     - **Luck, rerolls, a paid restock, chests and keys.** Some are your word on chests; the others are Roblox's rules.
     - **A Voidkin for Robux** (a Named shard). It isn't random, so it's allowed, but it sells strength and splits players. Research advises against it at launch, and all Voidkin work is parked until the end anyway.
   - **Later, in an update, the random sales you asked for** ("as transparent as glass", 2026-11-12). Built in first: the PolicyService check, every outcome's odds on the screen before purchase, the questionnaire, and a non-random alternative where they're restricted.
   - **Prices:** comparable passes sell for 149 to 1,499 Robux (`docs/research/tower.md`). Research sets each at your yes.
   - **The cost:** an early access store this thin earns little. It keeps the game clean while the loop proves itself (the directive, section 15: "First establish an enjoyable free progression loop").

**Asked by research, 2026-11-27, at the lean split:** does research's acting lead in the director's stead (2026-11-24, about 01:58) still run, or has the director said they're back?
