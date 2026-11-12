--!strict
-- VoidkinService (server): what a player may ask of the Voidkin they own: the lead and the stars (Shared.Rules.Collection),
-- registered with the save's one door.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Collection = require(Shared.Rules.Collection)
local DataService = require(script.Parent.Parent.Core.DataService)

local VoidkinService = {
	Priority = 20, -- after DataService
}

function VoidkinService.Init()
	for name, action in Collection.Actions do
		DataService.Action(name, function(draft: Profile.Data, args: any): { [string]: any }
			return action(draft, args, workspace:GetServerTimeNow(), 0)
		end)
	end
end

return VoidkinService
