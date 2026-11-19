--!strict
-- Settings cases (pure): the player's own levels (Rules.Settings; AR43's Settings). A new save at full; a level set in
-- whole hundredths; a name or a value out of bounds refused, changing nothing; the card's words. Runs in Studio
-- (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Settings = require(Shared.Rules.Settings)

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

return {
	{
		Name = "Settings: a new save at full; a level kept in hundredths; an unknown name or a value past 0 to 1 refused, changing nothing; Off at nought",
		Run = function(t: any)
			local data = fresh()
			for _, name in Settings.Levels do
				t.Equal(`{name} starts full`, Settings.Level(data, name), 1)
			end
			local set = Settings.Set(data, { Name = "Music", Value = 0.426 })
			t.Check("Music set, in hundredths", set.Ok == true and set.Value == 0.43 and data.Settings.Music == 0.43, tostring(data.Settings.Music))
			t.Check("Sound to nought", Settings.Set(data, { Name = "Sound", Value = 0 }).Ok == true and data.Settings.Sound == 0)
			t.Equal("an unknown name", Settings.Set(data, { Name = "Salvage", Value = 0.5 }).Error, Settings.Unknown)
			t.Equal("past 1", Settings.Set(data, { Name = "Effects", Value = 1.2 }).Error, Settings.Bad)
			t.Equal("under 0", Settings.Set(data, { Name = "Effects", Value = -0.1 }).Error, Settings.Bad)
			t.Equal("not a number", Settings.Set(data, { Name = "Effects", Value = 0 / 0 }).Error, Settings.Bad)
			t.Equal("no args", Settings.Set(data, nil).Error, Settings.Unknown)
			t.Check("the refusals changed nothing", data.Settings.Effects == 1 and data.Settings.Salvage == "")
			t.Equal("Off at nought", Settings.Said(0), "Off")
			t.Equal("a percent", Settings.Said(0.8), "80%")
			t.Equal("under half a percent reads Off", Settings.Said(0.004), "Off")
		end,
	},
}
