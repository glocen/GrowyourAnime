--!strict
-- Logic cases (pure): a Voidkin's name is found in a text as a whole word, so its label stays out of Roblox's automatic
-- translation (Rules.Names; the director, 2026-11-18, D8). Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Names = require(Shared.Rules.Names)
local Voidkin = require(Shared.Definitions.Voidkin)

return {
	{
		Name = "Names: a Voidkin's name is found as a whole word, alone, in a line or in a tag, and never inside another word",
		Run = function(t: any)
			for _, row in Voidkin.List do
				t.Equal(`{row.Id}: alone`, Names.Found(row.Name), row.Name)
				t.Equal(`{row.Id}: in a line`, Names.Found(`{row.Name} · Lv 5`), row.Name)
				t.Equal(`{row.Id}: after a word`, Names.Found(`Rates for {row.Name}`), row.Name)
				t.Equal(`{row.Id}: in a tag`, Names.Found(`<b>{row.Name}</b> joined`), row.Name)
				t.Equal(`{row.Id}: inside a longer word, none`, Names.Found(`{row.Name}ie {row.Name}s`), nil)
			end
			t.Equal("a line with no name", Names.Found("Nobody works here · 12 kW"), nil)
			t.Equal("empty", Names.Found(""), nil)
		end,
	},
}
