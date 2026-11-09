# The cold read of the design

2026-11-09. A reader that hadn't seen the design read the folder's files to break them: degenerate strategies, the first minute, exploits, contradictions, what the builder must ask on day one. No web check, no playtest: every finding is REASONED from the files, and the ones it marked "assumed" are guesses. What each changed is in the file named. Nothing here is the design's home.

| # | Weight | The finding | What changed |
|---|---|---|---|
| 1 | sinks | The first minute switched the base off: one dynamo, and the only fighter left it to fight at second 40 with both Breakers loaded. The Clash's 20 seconds couldn't hold a 15 to 25 second fight, and seconds 14 to 40 held more than a phone player can do | `docs/north-star.md`: the second Breaker comes with its shard and grows unaided, the fight moves to 60 to 120, the table runs to 180. TR2 |
| 2 | sinks | At launch the grow had no roll: a shard names its fighter, and traits and mutations weren't in the launch list | `docs/design.md`, "Shards and Breakers": every break rolls a mutation, from the slice on; the Void weather runs from the clock at launch |
| 3 | sinks (assumed) | Spare power is the income, so an idle base earns most, a big shard on a small Grid stops the credits, and nothing is in the player's hands between shelves | TR2: one switch between the two economies; "The Grid": pause on every machine, the handle's burst on a charge; a finished Breaker waits to be opened. Proposal 1 is locked only after TR2 |
| 4 | weeks | One fighter number can't carry fights and income: a third per rarity is about 13 times across the ladder | "The Grid": a fighter's work stays bounded, the growth sits in stations and upgrades. A balance run |
| 5 | weeks | TR2 ran out of things to do after 90 seconds | TR2: three stations, four shard types, three floors; its question is the first three minutes |
| 6 | weeks | Start stamps can't compute machines that slow | `docs/engineering-plan.md`, "The shape", line 4: progress and its time, one pure function for live play and absence |
| 7 | weeks | Exploits: gifts fed by a second account, a floor's holder changed by rejoining, the lift farmed for credits, the shop's limit refilled by a server hop, the stock read ahead, the tallest Tower won on an empty server | "Where fights happen", "The Void Shop"; `docs/risks.md`, 19 |
| 8 | weeks, polish | The directive's section 3 gives fighters experience from fights, and the design gave none. Luck was said to move the shelf, which is the same for everyone. Modulo's start had two dates | floors pay experience; the shelf is exempt from luck; AR1 starts Wednesday |
| 9 | weeks | Day one: where the director's data system is read from; the handle on a touch screen; starting numbers; how a shard enters a Breaker; what the first fight pays | TR1, TR2 |
| 10 | weeks | Scope: cut the gifts and "one in every rarity" from launch. Unstated: trading, codes, daily rewards, a global board, a faster repeat floor | `docs/design.md`, "What's built when" and "Fighters"; repeat floors at double speed |
| 11 | polish | Three lines two people would build differently: how machines slow, when a break rolls, who holds a floor | each rewritten in `docs/design.md` |

**Not taken:** the reader's reading that section 5 forbids steep income by rarity. Section 5 speaks of fights. The bounded range is kept as research's start for another reason: old fighters stay useful.

**Still unanswered:** whether a pass that raises credits counts as paying for a roll (`docs/roblox-rules.md`, "Not verified yet").
