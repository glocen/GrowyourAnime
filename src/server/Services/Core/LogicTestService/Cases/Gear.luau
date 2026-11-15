--!strict
-- Gear cases (pure): Regalia's fourteen slots, twelve shared and two hands, each named once; every class a Voidkin has
-- holds a weapon pair, its two weapons never the same, and no two classes share a main hand (docs/design.md, "Regalia:
-- gear"). Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Definitions.Gear)
local Voidkin = require(Shared.Definitions.Voidkin)

return {
	{
		Name = "Gear: fourteen slots, twelve shared and the two hands, each named once",
		Run = function(t: any)
			t.Equal("twelve shared", #Gear.Shared, 12)
			t.Equal("two hands", #Gear.Hands, 2)
			local seen: { [string]: boolean } = {}
			local count = 0
			for _, list in { Gear.Hands, Gear.Shared } do
				for _, slot in list do
					t.Check(`{slot} named once`, not seen[slot])
					seen[slot] = true
					count += 1
				end
			end
			t.Equal("fourteen in all", count, 14)
		end,
	},
	{
		Name = "Gear: every class a Voidkin has holds its own pair, and no two classes share a main hand",
		Run = function(t: any)
			local mains: { [string]: string } = {}
			for class, pair in Gear.Weapons do
				local main, off = pair["Main Hand"], pair["Off Hand"]
				t.Check(`{class}: a main hand and an off hand`, main ~= nil and off ~= nil)
				t.Check(`{class}: its two weapons differ`, main ~= off, `{main}, {off}`)
				t.Check(`{class}: its main hand is no other class's`, mains[main] == nil, `{main}, also {mains[main]}`)
				mains[main] = class
				t.Equal(`{class}: a hand shows its weapon`, Gear.Kind("Main Hand", class), main)
				t.Equal(`{class}: a shared slot shows itself`, Gear.Kind("Helmet", class), "Helmet")
			end
			for _, row in Voidkin.List do
				t.Check(`{row.Id}: its class, {row.Class}, has a pair`, Gear.Weapons[row.Class] ~= nil)
			end
		end,
	},
}
