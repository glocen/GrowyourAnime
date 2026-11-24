# The words: a voice for the text, and a method for names

Research subagent, 2026-11-24 (cloud session). Read-only on MAIN. Every item is a proposal; a rename of a confirmed word needs the director's yes and is marked **[D-yes]**. Every invented name here is original as far as I know and **still needs the IP-list check and a web search**. Numbers are seeds, tuned by reading the game on a phone.

## Verdict, in five lines
1. **Our best text is already the voice:** "Stand outside every slam.", "Low voltage", "Dare kept", "Bring down the Lamplighter." Plain, dry, concrete. The guide below writes down what those four do.
2. **Our worst text fails in three ways:** riddles ("Nothing waits.", "Who works?"), two words for one thing (bag and Inventory, keeper and boss, home and base), and loot-table fantasy on 120 of 300 item names ("Gloamforge Vambraces", "Pauldrons of Hoarfrost").
3. **The director rejects invented abstractions, cute words and old-book words, and keeps real words used exactly** (voltage, Strength, Drop rates). That is a rule we can apply before they see a line.
4. **"Void" has five meanings in the first ten minutes** (fighters, shards, the machine, the shop, an element), and a new player meets about 40 game words plus four classification axes. Too many; the merges are listed in section 4.
5. **The text will be machine-translated** (D8, 2026-11-18) and only Voidkin names are protected. Idiom names ("Haymaker", "Second Wind") and fragments ("It holds one Voidkin: no voltage") are the ones that break. One naming risk needs a content check now: **Noct**.

## 1. What the director rejected and kept (OBSERVED, `docs/decisions.md`)
| Date | Rejected | Kept or given instead |
|---|---|---|
| 11-11 | the first title | "Grow your Anime"; "dont be shy with the name ... we can use some japanese etc name" |
| 11-15 | "a little / a lot" on the infusion: "childish words" | "let use real electrician words": Low voltage, High voltage |
| 11-15 | descriptions on stats | "Plain list, no taps"; "drop rate is that simple" (Drop rates) |
| 11-15 | "Voidkin" on the dock | "Inventory" (11-15), then "Menu" (11-19, 03:19), then "Home" (11-19, 12:21) |
| 11-17 | "what does might and finesse mean???" (Might, Finesse, Vigor, Spirit, Insight); research's type names Fury, Swift, Bastion, Arcane, Craft | Strength and Endurance; types named by their colours; "Gear", American spelling |
| 11-19 | "ground" in what players read; "Combat Power" spelled out | "Arc"; "CR" |
| 11-23 | goals that are "corny or weird or look like ai slop"; "\"then it last foe\" what a corny ai slop line"; festival words outside Lantern Row | the dares and Today's three as written ("Yes, write it"); "Bring down the Lamplighter"; "then the elite" |

- **The pattern (OPINION):** they reject (a) a made-up abstraction where a plain word exists, (b) a cute word, (c) a word nobody says aloud ("foe"). They keep real technical words, the genre's plain words, and names with a picture in them. `directors-taste.md` has the same reading from the other side. **For us:** before any line ships, ask "would a 13-year-old say this word to a friend?" If not, the word goes.

## 2. The craft (labelled)
**Interface text**
- SOURCED, [Apple's writing guidelines](https://developer.apple.com/design/human-interface-guidelines/writing): "Check each word to be sure it needs to be there." Buttons take a verb. "Avoid the temptation to be too cute or clever." "Interjections like 'oops!' ... can sound insincere." An error says the fix. Keep "a list of common terms". "Favorites" beats "Your Favorites".
- SOURCED, [Microsoft's global writing tips](https://learn.microsoft.com/en-us/style-guide/global-communications/writing-tips): short simple sentences; keep "the" and "that"; no idioms; no modifier stacks; "Use one word for a concept, and use it consistently"; "Limit your use of sentence fragments" because they translate badly.
- SOURCED, [Mailchimp's voice and tone](https://styleguide.mailchimp.com/voice-and-tone/): the voice never changes, the tone does. "We prefer winking to shouting." "If you're unsure, keep a straight face." Forced humour is worse than none.
- SOURCED, [NN/g on children](https://www.nngroup.com/articles/childrens-websites-usability-issues/) (2018 study, 35 children): children skip long instructions, and the study saw it on Roblox itself; older children scan like adults; children are "acutely aware of age differences" and reject anything that reads a grade too young.
- **For us:** the last point backs the voice already in `docs/design.md`, "Goals": "a dry voice a little older than the player". Childish is the larger risk, not hard words. The term list is `docs/design.md`, "Words"; it lacks bag, enemy, base and the run's parts.

**How sticky names are made**
- COMMUNITY, [a report of Riot's "Naming New Champions" post](https://comicbook.com/gaming/news/league-of-legends-champion-names-didnt-make-the-cut) (the original URL now redirects): up to 100 candidates per champion, cut against naming goals. Names died for sounding like an existing champion (even by nickname), for slang in Portuguese, Thai, Czech, Malay or Turkish, for being hard to say, for a brand clash, for meme potential, for being too ordinary.
- COMMUNITY, [Ishihara on Pokémon's names](https://www.nintendolife.com/news/2016/03/tsunekazu_ishihara_on_the_difficulty_of_naming_pokemon_for_different_regions): "Nonsense cannot be valued." A name is two real words fused, so the meaning is felt even when unnoticed, and it is rebuilt per language. COMMUNITY (search snippets only, no article fetched): Valorant's agents go by short callsigns tied to the kit; their real names came later, through lore.
- OPINION, from the genre at large (TV Tropes refused the fetch): anime names things in six patterns. (1) **Image + action**, two words. (2) **A flavour-language word** as the name, a plain gloss as the title. (3) **A number** that implies a system (a form, a step, a count). (4) **Title, then name**: the role card lands a beat before the name. (5) **Role as name** for bosses ("the" + a job). (6) **A spoken line** as a move's name. Never copy a work's instance; the patterns are free.
- **For us:** we already use 2 (60 Legendary items), 3 (Nine Slips, Hundred Steps), 4 ("Keeper of Lantern Row" over the name, `src/client/UI/BossBar.luau:100`) and 5 (the Lamplighter). Pattern 6 is unused. `characters-and-worlds.md` already asks for an epithet per Voidkin; section 5 gives the rule for writing one.

**Why text reads corny or generated**
- COMMUNITY, [Wikipedia's field guide to AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing): the rule of three, "not X, but Y", "serves as" for "is", claims of significance, elegant variation (a new word for the same thing each time), and a stock vocabulary (delve, tapestry, testament, vibrant, pivotal, intricate).
- SOURCED, [Rosewater, 2002](https://magic.wizards.com/en/news/making-magic/add-text-flavor-2002-03-25): flavour text shows the world and leaves the story elsewhere; in Wizards' player survey "basic puns were disliked"; one off-tone card breaks the "mosaic".
- SOURCED at second hand, [Miyazaki](https://en.wikipedia.org/wiki/Hidetaka_Miyazaki) (citing the Guardian 2015, Wired 2016): he read books above his level and let "his imagination fill in the blanks"; players "get more value" from hints found on items. SOURCED, [Kasavin on Hades](https://www.gamedeveloper.com/design/how-supergiant-weaves-narrative-rewards-into-i-hades-i-cycle-of-perpetual-death): the lines players love are "moments where you feel the game is paying attention", picked from the run's state.
- **For us:** no flavour line exists in the game yet, which is right for now. The first two places are a Legendary item's card and the keeper's bar: one line each, one fact said and one left out, written only when the item pass comes up. A character's lines follow the Hades rule: keyed to a state.
- **Before and after, written for this note (OPINION):**

| The fault | Corny | Ours |
|---|---|---|
| over-explaining | "Unleash the true power of your Voidkin by upgrading gear!" | "Reinforce +1: Attack 86 → 98" |
| stacked adjectives | "An ancient, mysterious shard pulsing with dark energy" | "It hums when you hold it." |
| fake depth | "Even the smallest light can change everything." | "The lamps are out. Someone put them out." |
| a pun | "Watt a shocking win!" | "Lantern Row cleared" |
| "the X of Y" | "Blade of the Eternal Flame" | "Burnt Edge" |
| even rhythm, a triple | "Fight. Collect. Conquer." | "Break a shard. See who's inside." |
| a narrator's filler | "then its last foe" | "then the elite" |
| a riddle for a fact | "Nothing waits." | "No shards yet." |

**Roblox's text facts**
- SOURCED, [text filtering](https://create.roblox.com/docs/ui/text-filtering): we must filter "any displayed text that you don't have explicit control over": typed text, stored names, and "words generated from random characters". A game that doesn't is removed until it does. Our own fixed strings don't pass through the filter, but they are moderated content.
- SOURCED, [the maturity questionnaire](https://create.roblox.com/docs/production/promotion/content-maturity): Minimal or Mild reaches Roblox Kids (5 to 8) and Select (9 to 15); Moderate loses Kids. "Mild language" means words like "Damn" or "Heck"; anything stronger is for the strictest age gate. Crude humour is its own question. Casino settings or chips, even unplayable, are 13+.
- SOURCED, [automatic translation](https://create.roblox.com/docs/production/localization/automatic-translations) and [the overview](https://create.roblox.com/docs/production/localization): 17 languages; text is captured from any label with `AutoLocalize` on; a player with the setting on sees a translation even where we enabled none; a translation can be locked; names are kept out by turning `AutoLocalize` off.
- **For us:** zero profanity, zero crude jokes, no "jackpot", "bet", "casino" or "spin" anywhere near the Breaker. `src/shared/Rules/Names.luau` guards Voidkin names only (OBSERVED), so **move, ground, keeper and item names go to translation today**. "Haymaker" and "Second Wind" are idioms, so they are likely to come back literal (OPINION, untested). Nobody has tested whether the chat filter tags any of our names; a name that turns into #### can't spread (section 6, check 5).

## 3. The audit (OBSERVED: about 130 player strings from `src/client/UI`, `src/client/Controllers/Main`, `src/shared/Rules`, `src/shared/Definitions`)
**The ten strongest, and why**
- "Stand outside every slam." and "Finish with your lead above half.": a verb, one thing to do, checkable on screen.
- "Bring down the Lamplighter.": a verb with weight and the boss by name. "Drum Court's gate stays shut, for now.": honest, dry, and it promises.
- "Low voltage" and "High voltage": real words used exactly (the director's). "Dare kept": our own verb, a reward with no cheer. "Take it off first": a refusal that is the fix.
- "Lantern Row" and "the Lamplighter": two plain words with a picture; a role as a name. "Held Note": a real music term that describes hold, then release.
- Rook, Pip, Watt: one syllable, five different first sounds among the launch five, and Watt hints the kit.

**The fifteen weakest, rewritten**

| # | Now (file) | Fault | Proposed |
|---|---|---|---|
| 1 | "Nothing waits. Shards drop on Lantern Row." (`BreakerScreen.luau:863`) | a riddle | "No shards yet. Lantern Row drops them." |
| 2 | "The shares come to more than the whole" (`BaseController.luau:121`) | a maths teacher | "Over 100%. Lower one share." |
| 3 | "It's at the most already" (`EquipmentScreen/Look.luau:209`) | not spoken English | "Already at max" |
| 4 | "That shard has moved on" (`BaseController.luau:122`) | vague, a shard with feelings | "That shard changed. Try again." |
| 5 | "Who works?" (`BaseController.luau:513`) | a riddle as a heading | "Pick a worker" |
| 6 | "It doesn't go there" (`VoidkinScreen/Bag.luau:115`) | no fix | "Wrong slot" |
| 7 | "Nobody on it", "no one works here", "nobody works here" (`BaseView.luau:176`, HUD chips) | three forms of one state | "Empty" |
| 8 | "Your Inventory is full" (`ShopScreen.luau:72`) against "The bag is full: salvage an item from its card to free a slot" | two names; 13 words | "Bag full. Salvage an item to free a slot." in both |
| 9 | "Not in a boss's arena" (`Rules/Home.luau:48`) | "boss" is "keeper" everywhere else | "Not during a keeper fight" |
| 10 | "Hard: every foe is N levels higher" (`StageScreen.luau:664`); "chances against an even foe" (`Rules/Sheet.luau:37`) | "foe", the word in the rejected line | "Hard: enemies are N levels higher"; "against an enemy of your level" |
| 11 | "Its moves come when it's built" (`VoidkinScreen/init.luau:837`) | the team's word in the player's face | "Moves coming soon" |
| 12 | "{n} hits in a string, again and again" (same line) | poetic for a stat | "{n}-hit combo, repeating" |
| 13 | "It holds one Voidkin: no voltage", "Saves under a minute: not offered", "%s: once a shard" (`BreakerScreen.luau:870`) | colon shorthand; breaks in translation | "This shard holds one Voidkin. It takes no voltage." / "Under a minute left. No voltage needed." / "One voltage per shard" |
| 14 | "A convert is already under way" (`BaseController.luau:126`) | "a convert" isn't a thing | "The Condenser is busy" |
| 15 | "Through the Door: {ground}" (`Rules/Hud.luau`, the next step) | a capital-D noun never introduced | "Go to Lantern Row" |

Also small (OBSERVED): "The lead fights, it can't be stationed" → "Your lead can't work a bay"; "Each slot will hold a jewel of its colour" is British in an American game (the director, 11-17, 13:15); "No answer: try again" and "The trip didn't go through. Try again." are one failure in two shapes; goals spell "three" while Next writes "level 2"; "Tap to continue" is wrong for a mouse (say "Continue").

**The dock's Home is not home (OBSERVED, `docs/ui.md`, the dock).** The Home button opens the menu panel. The Base button takes you home. Meanwhile strings say "Still healing at home", "You're home". Cheapest fix, no decision touched: sentences say "base" ("Healing at base 0:24"). Renaming the dock's Home is **[D-yes]** (theirs, 11-19).

**Item names (MEASURED, `Definitions/ItemDesigns.luau`: 300 names, 20 kinds by 15).**
- 60 are "X of Embers / Hoarfrost / Gales"; 60 are Stormcall / Gloamforge / Nightloom; 60 are Lanternsteel / Rowsmith / Stallguard; 60 are a Japanese word with a gloss; 60 are Iron / Bronze / Scrap. **The slot's word changes with rarity:** Ring, Band, Loop; Boots, Greaves; Bracers, Vambraces; Chestplate, Cuirass; Shield, Bulwark. That is elegant variation: a player hunting a ring must learn three words, and a translator makes three more. "Bulwark of Embers" is a shield and Bulwark is a Voidkin.
- Hoarfrost, Gloam, Cuirass, Vambraces, Pauldrons and Sceptre are words a young non-native reader doesn't have. OPINION: this tier is where "generic fantasy" lives in our game.
- **Proposed:** the slot word never changes. Rarity changes the first word only: a material (Iron), then a maker (Rowsmith), then a plain image (Ember Ring, Frost Ring, Gale Ring), then the named Legendary. Tier 2; the names are research's, not the director's. With the gloss check below, about 3 h for research and the builder, whenever the item pass comes up.
- **The Legendary pattern is right** (a flavour word and a plain gloss: "Akari, the First Light"). But some glosses look wrong to me: "Ryuukou" usually reads as "a trend", "Kousai" as "lustre", "Gyouten" as "dawn sky" or "astonishment". PLAUSIBLE, not confirmed: a Japanese speaker checks all 60 before launch. Japanese is one of Roblox's 17 languages.

**Roster names (OBSERVED, `docs/roster.md`; the IP flags are PLAUSIBLE, from my memory of those works with no search run, for the content check).**
- **Noct, strong flag.** A famous RPG lead is nicknamed exactly this, and his known move is throwing a weapon and appearing where it lands. Ours: "Rift Lunge: throws the spear and arrives where it lands", in a long dark coat. Name plus signature is the "Fighters" test's exact case. He isn't built: rename and re-kit now costs minutes.
- **Mirage** (a trickster who fights with afterimages shares name and gimmick with a hero shooter's character), **Cinder** (a woman who fights with fire, as in a known web series), **Dawnbreaker** (a hero's name in one game, a famous sword in another). Medium. Kirra is already flagged in `README.md`, item 8.
- **Spelled harder than said:** Aegir, Ironhymn, Halcyon. Aegir is a sea giant's name on a wind mech, while the sea mech is Shiomaru: the meaning points the wrong way. **Crowded roots:** Cinder, Cinder Ring, Cinderwalk, Kindle, Smoulder, Last Ember, "of Embers". Zenith is a passive and an emblem. Five names start with S.
- **Puns on a trade** (Hard Hat, Hot Meal, Quick Fix, Door Slam) belong to looks the director already rejected as jobs (11-15); they go when their rows are redesigned. MEASURED: signature and passive lines have a median of 9 words; 6 run past 12; the longest (Glint Drive) is 20.

## 4. How many words a first session asks for (MEASURED from the strings and `docs/north-star.md`'s beats; my count, a seed)
- **Names, 11:** Voidkin, Void Shard, Void Breaker, Void Shop, Festival of Battles, the Door, Lantern Row, the Lamplighter, the Tower, Stone Condenser, War Emblems. **Roles, 12:** lead, worker, bay, chamber, Shade, Brawler, Guard, Dasher, elite, keeper, Arc, stretch.
- **Systems, 17:** dare, signature, passive, CR, Credits, Power, kW, kWh, battery, voltage, star, copy, stock, stones, Reinforce, Jewels, Today and Next. **Four axes with about 20 values:** rarity, type (five colours), class, element.
- **About 40 words and 4 axes in ten minutes.** OPINION: a phone player holds about ten. The rest must be learned by doing, or hidden until needed (`state-of-the-game.md`, item 6).

**Merges and renames, in plain words**

| Now | Proposed | Needs |
|---|---|---|
| the element "Void" | "Dark" (Fire, Frost, Storm, Dark). "A Void Voidkin from a Void Shard" is our worst sentence | tier 2; research's word, not marked [D] |
| Void Shop | "the Shop". Refusals already say it ("The Shop is closed for a moment") | **[D-yes]**: the package's word |
| Void Shard, Void Breaker | keep the full name on the title plate; "shard" and "the Breaker" in sentences, as the code already does | none; the director likes Void on machines ("void need be void", 11-15, quoted in `directors-taste.md`) |
| Void Clash, Void Rift, Void Mill, Void Essence | arrive without the prefix: the Clash, the Rift | **[D-yes]** when each is built |
| Festival of Battles | one mode card; never in a sentence. "Go to Lantern Row" carries it | none |
| stretch, stage, phase, mission | players see only "Arc" and a count ("2 / 4") | tier 1; `design-review.md`, item 9, agrees |
| chamber, bay | keep bay; a chamber is "slot 1" | tier 1 |
| Stone Condenser, tray, stones, Reinforce, Jewels, War Emblems | no word shown before its system opens | tier 3, already asked in `state-of-the-game.md` |

**The Void count (MEASURED).** `docs/design.md`, `docs/roster.md`, `docs/ui.md` and `docs/north-star.md` hold nine Void terms: Voidkin, Void Shard, Void Breaker, Void Shop, Void Rift, Void Mill, Void Essence, Void Clash and the element. Player strings already hold three (Voidkin, Void Breaker, Void Shop), and Kirra, a starter, has Void as her element (`Definitions/Voidkin.luau`). After the merges, "Void" means one thing: where shards and Voidkin come from. The first session drops to about 30 words.

## 5. The voice guide (one page; proposed home: a "Words" section in `docs/ui.md`)
**Three traits**

| Trait | Do | Don't |
|---|---|---|
| **Plain.** Real words, used exactly | "High voltage" | "Supercharge!", "Might" |
| **Dry.** A straight face, a little older than the player | "Drum Court's gate stays shut, for now." | "Awesome! You crushed it!" |
| **Concrete.** One thing you can see or do | "Stand outside every slam." | "Master the art of positioning." |

**The tone ladder.** One voice, three volumes. Never mix them.
- **Interface: plain.** Buttons, labels, refusals, stats. No personality. A refusal is the fix. **Characters: personality.** One line each, on the reveal card and after a win or a fall. Nowhere else.
- **Lore: implication.** An item's or a keeper's line says one fact and leaves one out. No stats, no jokes. Goals and dares sit between the first two: plain words, a dry turn allowed once in five.

**Length (seeds)**
- **Button:** 1 or 2 words, 10 characters, a verb ("Equip", "Claim", "Put in"); translation adds about 30%. **Label or chip:** 3 words, parts joined by " · ".
- **Refusal or toast:** 6 words, and it says what to do. **Tip or next step:** 8 words. **Goal or dare:** 8 words, one sentence, one full stop.
- **A move's or passive's effect:** 12 words, a verb first, one effect and one condition (the director's 11-13 rule, extended).
- **Character line:** 8 words, two beats. **Flavour line:** 14 words, two sentences at most.

**Punctuation and capitals**
- Sentence case everywhere. Capitals only for our names: Voidkin, Void Shard, Void Breaker, Lantern Row, the Lamplighter, Arc, Tower, Credits, CR, Hard. Lower case: shard, bay, lead, worker, keeper, dare, star, bag, base.
- No exclamation marks, no "...", no semicolons, no brackets. A colon only before a value ("Needs: 40 kWh"), never to mean "so". A full stop on a goal, a tip or a line that has a verb. None on buttons, labels, chips and toasts.
- Whole sentences keep "the" and "a". At most one possessive on a thing per line ("the Condenser's tray" is our docs' habit). One word for one thing, from the list in `docs/design.md`, "Words".

**Numbers.** Digits always: "Break 3 shards." Thousands separators, and the short form from 100K as decided (11-19). A sign on a change ("+12"). A space before a unit ("40 kWh", "1 min 59 s"), none before "%". "Lv 12" on a chip, "level 12" in a sentence.

**Words we don't use**
- **Old-book and hype:** foe, slay, vanquish, behold, awaits, realm, destiny, fate, ancient, eternal, darkness, whispers; unleash, ultimate, true power, epic and legendary as praise, awesome, amazing, congratulations, get ready, let's go, oops, uh-oh. **Generated:** delve, tapestry, testament, vibrant, journey, "not just X, but Y", any list of three.
- **Quest board and ours, leaking:** Defeat, Complete, Earn and Collect as headers (already ours, `docs/design.md`, "Goals"); built, convert as a noun, stretch, ground, "Tap" and "Click".
- **Rating risks:** any profanity, crude jokes, jackpot, bet, spin, casino, drunk, kiss, kill, die, blood.

**A character's one line**
- **Template:** a concrete thing in front of them, then what they want or refuse. Two beats, 8 words, present tense. Never their own trait ("I'm the strongest"), the theme, a pun on their element, or their own name.
- **The swap test:** give the line to another fighter. If it still works, rewrite it. Each fighter gets three lines keyed to a state (revealed, won, fell), never a random bark.

| Archetype | Line (original, written for this note) |
|---|---|
| the cocky rookie | "Zero wins so far. Ask me again tonight." |
| the stoic guardian | "Stand behind me. Further." |
| the sleepy genius | "Wake me if it gets hard." |
| the strict class rep | "You're late. The fight started at nine." |
| the gentle giant | "Sorry. This part is loud." |
| the cold rival | "Don't thank me. You were in my way." |
| Watt, from his row ("the quiet wall") | "Behind me." |

**The epithet.** Two or three words after the name, never "the X of Y", never the class. It states a habit or a fact, so it can be said in the playground: "Hiru, Half Asleep". At Legendary and above, the reveal shows the epithet first and the name a beat later (pattern 4).

## 6. The naming method
**Steps**
1. **Write the row first:** the archetype in three words, the twist, the kit in six words. No name before this.
2. **Write 20 candidates from four wells** (Riot writes up to 100): a plain English word that hints the kit (Watt); a real given name from any language (Juno); a flavour-language common word, its gloss kept as the epithet; for Epic and above only, a compound of two real words (Sliptail).
3. **Cut by sound and length.** Common to Rare: 1 or 2 syllables, 6 letters. Epic and above: 3 syllables, 8 letters. Spelled as said: no "ae", no silent letters, no "ph" or "hy". Stress on the first syllable. Hard starts (k, t, r, z) for hitters, soft (l, m, n, w) for healers (OPINION, the usual sound-symbolism reading). A person isn't an object noun, unless the epithet makes it a nickname (`characters-and-worlds.md`, rule 6).
4. **Cut by collision with our own set:** no shared first sound inside one Arc's shard pool; no two names one letter or one rhyme apart; no root used twice (the cinder family).
5. **Run the six checks,** all on the sheet:
   1. `docs/ip-list.md`.
   2. A web search for the name with "character", "anime" and "game", **then the name with its signature's mechanic**. The second search is the one that catches a Noct.
   3. Say it aloud three times, then shout it as a callout.
   4. Read it at 14 px in the HUD's face on the lead card: I and l, rn and m, O and 0.
   5. **The filter and the translation.** In the private save, a debug command passes every name through `TextService:FilterStringAsync` and prints any that come back with #. From memory the filter doesn't run in Studio, so this needs a live server; the docs page I fetched didn't say. Then read what automatic translation makes of each move and place name in Spanish and Portuguese.
   6. A slang check in Spanish, Portuguese and Indonesian, Riot's lesson.
6. **Pair it with its epithet,** and judge both beside the look at the design sheet, as `docs/roster.md` already rules.

**For moves:** 1 or 2 words, 16 characters; 3 words from Legendary. A real word used exactly beats a coined one. At most 1 in 10 is "X of Y". A number in a name is a count the player can see on screen. **For Arcs:** two plain words, a thing and a place, 4 syllables; its keeper is "the" and a role. **For items:** section 3.

**Five worked examples** (all original, all still to be checked; the clashes named are from memory, no search was run)
1. **A fighter, the sleepy genius** (Common Mage; ends a fight in one move so he can nap). Candidates: Doze (an object-noun), Nemu (shares N with Noct, and a known character carries it), Yoru (a current game's agent), **Hiru** (from a word for a midday nap; 2 syllables, 4 letters; only Halcyon shares H, three Arcs away). Epithet: "Half Asleep". → **Hiru, Half Asleep.**
2. **A fighter, the strict class rep** (Uncommon Tank; holds one enemy in place). Prim (shares P with Pip in the same pool: cut), Tess (T is Tumble's), **Fumi** (a real given name; "fumi" also means a written note; F is unused in the roster). → **Fumi, By the Book.**
3. **A move for Fumi.** "Rule Enforcement Strike" (three abstract words), "Chains of Order" (X of Y), **"Detention"** (one real word a child knows, and it is the effect: one enemy is held). → **Detention.**
4. **A move for a cold rival** (an Epic Assassin's one draw cut that freezes a beat late). "Absolute Zero Slash" (hype, generic), "Frost Blade of Eternity" (X of Y, banned word), "Last Frost" (too near our Last Ember), **"Seventh Winter"** (a number that implies six before it; says nothing else). → **Seventh Winter.**
5. **An Arc, the train yard at midnight.** "Void Station" (one more Void), "Last Stop" (from memory, a 2021 game has this title: a general phrase, but why start there), "Thousand Tracks" (too near Hundred Steps), **"The Roundhouse"** (a real rail building, and a kick; 2 syllables). Its keeper: **the Stationmaster.**

## 7. Ten questions for any text players read
1. Would a 13-year-old say every word of it to a friend?
2. Is each thing called by its one word from the list?
3. Is it inside its length limit?
4. Can a word be cut with nothing lost?
5. Does a refusal say what to do next?
6. Is there exactly one concrete thing in it, and no adjective pair?
7. Is it free of "!", of a pun, of a triple, of "X of Y" and of the banned words?
8. Does it survive a literal translation: no idiom, no fragment, "the" and "a" in place?
9. For a name: did it pass the six checks, the mechanic search included?
10. Read aloud at the game's camera on a phone: does it sound like one person wrote the whole game?

## Top 5 to act on
| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **Fix the 15 weak strings and the small ones, and add bag, enemy, base and Arc to the term list.** Several self-tests assert the literal text, so their expected strings change with it | research words, the builder edits | about 2 h | no: tier 1. Renaming the dock's Home is **[D-yes]**; saying "base" in sentences is not |
| 2 | **Content-check Noct now, then Mirage, Cinder and Dawnbreaker**, with Kirra's check already asked. Add the mechanic search to every sheet | research, the content check | 1 h | no for the check; a new name is research's with the sheet |
| 3 | **One meaning for "Void":** rename the element, shorten in sentences, no prefix on new modes | research restates, the builder renames one enum's shown word | 1 h of text and tests | **[D-yes]** for Void Shop and the modes; tier 2 for the element |
| 4 | **Adopt the voice page and the ten questions** as a "Words" section of `docs/ui.md`, linked from "Goals" and from `/ga-review` | research | 1 h | no, if it only records practice; yes if a rule in `AGENTS.md` changes |
| 5 | **Decide what translation may touch,** then test. Proposed: fighter, move, Arc and keeper names stay English (extend `Rules/Names.luau`); item names translate, with a fixed slot word. Run the filter and translation checks in the private save | the director decides, the builder extends the guard, research reads the output | 2 h after the private save exists | **[D-yes]**: D8 is theirs, and the save waits on them |

## What I couldn't fetch
The search budget ran out after five searches, so nothing was searched for Nintendo's, Blizzard's or Overwatch's writers. Not fetched: Material Design's writing page (empty render), the Guardian's Miyazaki interview (blocked; quoted through Wikipedia), TV Tropes and Bulbapedia (403), Roblox's Community Standards (403), Iwata Asks (503), the Hades wiki (402), Riot's original post (redirects; a press report used). The anime naming patterns and the sound-symbolism rule are my own reading, labelled OPINION.
