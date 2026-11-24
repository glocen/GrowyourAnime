--!strict
-- Condenser (shared config): the Stone Condenser (TR37; docs/design.md, "The base"; Rules.Condenser). It makes Low forge
-- stones into its tray, online and away, drawing power like the Breaker and slower with less (Rules.Power); a full tray
-- stops it. Its second job turns 5 Low stones into 1 Mid, one at a time, and from its level 10 5 Mid into 1 High (TR56).
-- While it works it also makes jewels (Config.Jewels.Condenser). Research's seeds (TR37, 2026-11-17, 11:49, and
-- "Research's scope today", 2026-11-23, 02:53); Wakes and Kw the builder's, research's yes of 2026-11-23 (TR37, "Faber's
-- build").
-- Tuned by playing: NL_Debug:Invoke("Tune", "Condenser.<path>", value).

return {
	Wakes = 2, -- the base's level it wakes at: asleep before, so the first session's starter shard has the power
	Makes = "Low", -- the grade it makes (Config.Reinforce.Grades)
	Rate = { First = 1, PerLevel = 0.05 }, -- stones an hour at full power: First at level 1, plus PerLevel a level (2.45 at 30)
	Kw = 10, -- kW, its rating at level 1 while it works, rising with its rate (the Training machine's): 24.5 at 30
	TrayHours = 12, -- the tray holds this many hours of its making at its level, whole stones; a full tray stops it
	-- Its converts, one at a time, by the grade each takes (Order's): Take stones of From out of the bag, and after Seconds
	-- of work at full power, Give of To in the tray, beside the cap (a full tray never holds back a finished convert). Each
	-- from its level FromLevel (TR56, research's seeds "condenserHigh": +21 to +30 through the base).
	Converts = {
		Low = { From = "Low", Take = 5, To = "Mid", Give = 1, Seconds = 1800, FromLevel = 1 },
		Mid = { From = "Mid", Take = 5, To = "High", Give = 1, Seconds = 3600, FromLevel = 10 },
	} :: { [string]: { From: string, Take: number, To: string, Give: number, Seconds: number, FromLevel: number } },
	Order = { "Low", "Mid" },
}
