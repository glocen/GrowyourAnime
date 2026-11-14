--!strict
-- VoidkinService (server): what a player may ask of the Voidkin they own: the lead, the stars and the stat board's points
-- (Shared.Rules.Collection, Rules.Board), registered with the save's one door.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Collection = require(Shared.Rules.Collection)
local DataService = require(script.Parent.Parent.Core.DataService)
local LeadService = require(script.Parent.LeadService)

local VoidkinService = {
	Priority = 20, -- after DataService
}

-- What the world says before a rule runs: the lead never changes in a fight, and a fallen one stays home until it's
-- whole (TR12, LeadService.Refusal).
local GUARDS: { [string]: (Player, any) -> string? } = {
	SetLead = function(player: Player, args: any): string?
		return LeadService.Refusal(player, if type(args) == "table" then args.Voidkin else nil)
	end,
}

function VoidkinService.Init()
	for name, action in Collection.Actions do
		local guard = GUARDS[name]
		DataService.Action(name, function(draft: Profile.Data, args: any, player: Player): { [string]: any }
			local refusal = if guard then guard(player, args) else nil
			if refusal then
				return { Ok = false, Error = refusal }
			end
			return action(draft, args, workspace:GetServerTimeNow(), 0)
		end)
	end
end

return VoidkinService
