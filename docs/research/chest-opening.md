# Opening chests: Dragon Hunter's flow, Sailor Piece's feel

Asked by the director, 2026-11-16, 21:39 (`docs/decisions.md`): "sure let do it like tcp3 but i want the feeling if openning chance to be as good as sailor piece". Read by research's subagent at 21:47, from written sources only. Reference stays internal: for feel and readability, never a blueprint. The design goes to TR34.

## SOURCED, from what's written

- **The gap:** no written source describes either game's opening as it plays: its animation, sound, flash, camera, timing or skip. That needs footage, read frame by frame (`/ga-reference-study`). Sailor Piece's clip is read below. Dragon Hunter's isn't in yet.
- **Taichi Panda 3: Dragon Hunter:**
  - Gear's quality runs green, blue, purple, orange ([18183](https://www.18183.com/tjxm3ll/gonglue/), from a search snippet).
  - Chests lie in the field ([9game](https://www.9game.cn/tjxm3ll/1606356.html)).
  - Its App Store pages answer 404. The game may be delisted (INFERRED), so footage may be the only record of its flow.
- **Sailor Piece opens three kinds of thing:**
  - **Chests** in six tiers named by rarity, Common to Secret, dropped by enemies and bosses ([game.guide](https://www.game.guide/mythical-chest-value-sailor-piece), [Gamezebo](https://www.gamezebo.com/walkthroughs/sailor-piece-secret-chest/)). Players stack them and "open them all at once at the end of your session" ([ItemLevel](https://itemlevel.net/sailor-piece-best-gems-guide/)). Videos title openings of 60,000 and 100,000 chests (titles only).
  - **The race spin:** a typed number spins many at once, and the batch keeps only the highest rarity it lands ([GameRant](https://gamerant.com/roblox-sailor-piece-all-races-how-to-get-reroll/), [AllThingsHow](https://allthings.how/sailor-piece-races-explained-full-list-stats-and-reroll-steps/)).
  - **Trait, power and stat rerolls:** an auto-reroll with filters runs until the tier the player set ([AllThingsHow](https://allthings.how/sailor-piece-power-system-every-power-drop-rate-and-how-to-reroll/), [Beebom](https://beebom.com/sailor-piece-stat-reroll-guide/)). A pity guarantees a Mythical at 500 rolls and a Secret at 2,500 ([RBLXGuide](https://rblxguide.com/games/sailor-piece/updates/trait-reroll-guide)). Whether a counter shows is unknown.

## INFERRED, the general levers

1. The container shows its worth before it opens.
2. A batch opened all at once is a ritual: saved up, then paid out as a pile.
3. A bulk open resolves to its best: many rolls in, the keeper shown last and largest.
4. The same tier words and colours everywhere, so a high result reads at once.

## OBSERVED, Sailor Piece's opening, from the director's clip

Read by research, 2026-11-17, 02:21. The clip is the director's phone recording, `build/reference/chest-opening/sailor-piece_chest-opening.mp4` (97.7 s, 1108 by 512, 30 fps). The director's word at 02:16: "here is the chest openning video of sailor piece we need to make it our own tho". It was read on contact sheets at one frame a second, then at two to five a second, cropped and enlarged round each open.
- **0 to 24 s:** a boss fight, with no chest in it. The sparks round the avatar at 24 to 25 s and 47 to 49 s are the avatar's own aura, which shows whenever the bag closes. They aren't an opening.
- **The chests are bag items:** stacks in the Items tab, each in its tier's frame ("Common Chest" ×1409, "Rare Chest" ×1098, Epic, Legendary).
- **The ask (35, 52, 72, 78 and 84 s):** tapping a stack raises a small panel over the bag: "Open Common Chest?", with a green Yes, a number field and a red No. The amount is typed on the phone's keyboard, which covers the lower half of the screen (43, 54, 74 and 85 s).
- **The open (56.2 s):** the stack drops from ×1409 to ×409 within one sampled frame (200 ms), so a thousand chests open at once. There's no animation, camera move, flash or screen of its own, and the bag stays open.
- **The payout, from about 0.2 to 0.4 s after:**
  - thin strips fade in at the top centre, each a line of text on a band that fades out at both ends;
  - each is coloured by what it pays: a gold band reads "Earned 4.5M$", a blue band above it reads "Earned 11.0K Gems";
  - then come lines reading "Obtained x10" and the item, its name in its tier's colour (83 to 85 s);
  - they stack and hold for at least 2.5 s.
- **After:** the player scrolls the bag's pages to see what came (61 to 71 s). The stacks' counts are the record.
- **Sound:** not measured. The clip's audio is a repeating bed, and no cue stands out at the opens.
- **Not in the clip:** a reveal for each item, a moment for the best one, or anything for one chest alone.

## INFERRED, what makes it feel good

In this clip the feeling comes from mass and speed, not ceremony. A thousand chests open in one tap, the payout comes as big rounded numbers in colour, and the bag swells. The thrill is the haul's size. Our design (TR34) keeps that and adds what the clip lacks: the climb to the best item, and the best one landing last.
