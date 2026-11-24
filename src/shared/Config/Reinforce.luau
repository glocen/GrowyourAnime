--!strict
-- Reinforce (shared, numbers): a gear's level, +1 a success, paid in forge stones and Credits (TR47, research's seeds,
-- from docs/balance.md's shares: the forge's 45% of income at the grounds' pace; tuned by play and by the loot refit).
-- Read by Rules.Reinforce. The director's word of 2026-11-19, 03:10: 100% to +5, then 80%, 70%, 60%, 50% and on down to
-- 20%; a failure spends its cost and keeps the level, with no pity. Then 2026-11-24: "we will sell credit so make sure it
-- in accord to roblox rule", and Roblox bans a paid random outcome that only loses the payment, so a failure now warms
-- the item (Heat, below; docs/research/cloud-2026-11-24/launch-design.md, section 3). Heat waits on the director's yes to
-- that design before any Credits are sold, and its prices on research's refit (about x1.46 holds the sink).

return {
	Cap = 30, -- about five levels a ground
	-- The chance a try for each level succeeds, by the level tried for; past the list, Floor.
	Chance = { 1, 1, 1, 1, 1, 0.8, 0.7, 0.6, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25 } :: { number },
	Floor = 0.2,
	-- Forge heat: each failure since the item's last success adds this to its next try's chance, until a try is sure;
	-- a success cools it to none. The builder's seed from launch-design.md, section 3 (+5 points a failure).
	Heat = 0.05,
	-- A level adds this share of the item's main line's own value to that line's stat: +30 doubles it. The main line is
	-- half an item's worth (Config.Chests.MainShare), so a full Reinforce is half the gear's worth.
	Gain = 1 / 30,
	-- Credits a try: round(Base x G(the last level of the item's ground) x (1 + L / Per)), L the level tried for.
	Credits = { Base = 30, Per = 15 },
	-- Forge stones a try: the grade by the ten the level tried for falls in, the count by its place within that ten.
	Grades = { "Low", "Mid", "High" } :: { string },
	Stones = { 1, 1, 1, 2, 2, 2, 3, 3, 3, 4 } :: { number },
}
