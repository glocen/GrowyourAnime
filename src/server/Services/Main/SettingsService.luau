--!strict
-- SettingsService (server): the player's own levels, Music, Sound and Effects (AR43's Settings; Rules.Settings), kept
-- in the save so they follow the player. One action, "Settings" { Name, Value }, set on the slider's release: the client
-- hears and sees a level at once while it drags, and saves it once when the drag ends.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Settings = require(Shared.Rules.Settings)

local DataService = require(script.Parent.Parent.Core.DataService)

local SettingsService = {
	Priority = 20, -- after DataService
}

function SettingsService.Init()
	DataService.Action("Settings", function(draft: Profile.Data, args: any): { [string]: any }
		return Settings.Set(draft, args)
	end)
end

return SettingsService
