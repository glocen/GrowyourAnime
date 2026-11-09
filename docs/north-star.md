# North star

The game in one page: what it is, what the player wants, and what the first 20 seconds must be. Research's foundation, 2026-11-09, from the director's directive (`docs/directive.md`), their sketch and their words of that day. How each system works: `docs/design.md`. Who decided what: `docs/decisions.md`. Read this page before any piece players see.

## The game

You run a small electric base where Void Shards are broken open and grow into anime fighters. Your fighters power the base, climb your Tower and clash with the neighbours' teams.

**The loop:** catch a shard at the Void Shop → grow it in a Void Breaker → the fighter steps out and powers your base → send your team to a Void Clash → the winnings and the power buy better shards and a bigger Grid.

**The spine:** fighters make the power that grows the next fighters, and the power you don't use sells itself.

## What the player wants

- **In a minute:** to see what the Breaker gives.
- **In a session:** a rarer shard caught at the shop, a higher floor of the Tower, a Grid that makes more.
- **Over weeks:** a full Index, a fighter built beyond its rarity, the tallest Tower on the server.

**Why they come back tomorrow:** the base worked all night, the shop has turned for everyone, a row of finished Breakers waits to be opened, their team held floors on other players' Towers, and something is new each week.

## What's ours

- **You grow fighters, not crops.** The thing that grows has a face, a pose and a skill, and then it goes to work.
- **Your fighters are the power plant.** Training makes electricity. Cables light from each station to each machine, and a richer base hums louder.
- **One shop, one moment, for the whole game.** Every five minutes the same shelf turns on every server. When a rare shard is in, a beam rises over the shop and everyone runs.
- **A fight is a show.** A Void Clash is watched: who acts, with what, and why it was won.
- **A skyline of Towers.** Eight bases, eight Towers lighting floor by floor. The ranking is the horizon.
- **Build beats luck, within reason.** A well-built fighter can beat a plain one a rarity above it (the directive, section 5).

## The first 20 seconds

The director, 2026-11-09: "the game 20 first seconds isn't a rule for every game just those type of games and for fact this is something that our next game named "Grow a Anime" Need!" It covers this game and games of its kind, and it isn't a studio rule.

**Why it matters here** (read 2026-11-09, SOURCED: `docs/research/first-seconds.md`):

- Roblox's recommendations count a first play that ends under 60 seconds, and one that ends before 180, against the game.
- The four games the director named share a start: you spawn on your own plot holding the starter item, with no text tutorial; the first input is the title's verb; the first payout comes in seconds, as a multiple; income turns passive at once; a rarity ladder shows before the first purchase.
- NEXT Button gave its first pet at about 2:39. Players left before it.

**The target,** a design to block out and time, not a measurement:

| Second | The player | What they see |
|---|---|---|
| 0 | spawns in their own base, facing a Void Breaker with a shard already in it and a handle that glows | neighbours' fighters at work, a beam over the shop, Towers behind |
| 0 to 4 | one input: holds the handle | their own power runs down the cable, and a body grows in the Breaker for as long as they hold |
| 4 to 8 | lets go | the Breaker opens, the fighter steps out and strikes its pose, its name and rarity land, and the Index pays the first credits |
| 8 to 14 | watches | the fighter walks to the dynamo and starts. The cables light without the player, credits begin to tick, and the second Breaker, which came with its own shard, wakes and grows with no hand on it |
| about 25 | opens the second Breaker, which glows when it's done | a second, different fighter, its pose, a second payout from the Index. One fighter now powers the base and one is free |
| 25 to 60 | runs to the shop and buys | the shelf, the rarity ladder on it, the countdown. Back home, the shards go into the Breakers |
| 60 to 120 | sends the free fighter up the Tower's first floor | the first Void Clash, won, and a mystery shard for it. The base keeps running behind |
| 120 to 180 | opens the mystery shard's Breaker, looks at what's next | the next shelf's hint, the second floor's holder, a third fighter growing |

The first verb is the title's: you grow it, by hand. The first payout is at about second 8. Income is passive by second 14. No text to read before the first input. The table runs to 180 because Roblox counts a first play that ends before then, and the fight comes after the second fighter so the base never goes dark for it.

The measures at the blockout: seconds to the first input, to the pose, to the first credits, to the second reveal, to the first purchase, and to the first Clash.

## The bar

- A small roster of excellent fighters beats a large one of repeats (the directive, section 11). Each reads at a glance as a person: a silhouette, a stance, one signature move.
- A fight that's correct and dull fails (section 6). So does a screen that passes its lint and looks poor (section 13).
- The look is set by the first fighter and the first screen, each judged from the player's camera and at phone size, before a second is made.

## What it isn't

- Not a planting simulator: shards go into machines, never into soil (the directive, section 3).
- Not a roster of other people's characters under new names (section 3).
- Not an electrical simulator: three numbers on the screen, and everything else seen in the world (section 6; `docs/design.md`, "The Grid").
- Not a wall of percentage bonuses: few traits, each one changes how a fight or a base plays (section 7).
- Not a big map: nothing is more than a short walk away (section 12).
