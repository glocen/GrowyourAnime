--!strict
-- VoidkinService (server): what a player may ask of the Voidkin they own: the lead, the stars, the marks and a nickname
-- (Shared.Rules.Collection), registered with the save's one door. A nickname passes Roblox's text filter before it's kept
-- and is shown to its owner filtered (TextFilterService; docs/roblox-rules.md, "Nicknames").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Collection = require(Shared.Rules.Collection)
local DataService = require(script.Parent.Parent.Core.DataService)
local TextFilterService = require(script.Parent.Parent.Core.TextFilterService)
local LeadService = require(script.Parent.LeadService)
local FightService = require(script.Parent.FightService)

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

-- What a keeper's try or a Tower run holds as it started, for the lead alone: its stars wait for the end (D10).
local FROZEN: { [string]: boolean } = { SpendCopies = true }

VoidkinService.Filtered = "Filtered" -- a nickname the filter changes: refused, and the Voidkin keeps its name
VoidkinService.FilterFailed = "FilterFailed" -- the filter couldn't answer: refused, to try again

-- What runs before a rule, outside its transaction, and may yield.
local BEFORE: { [string]: DataService.Before } = {
	-- A nickname as its owner would see it filtered: kept only when the filter leaves it whole.
	SetNickname = function(player: Player, args: any): string?
		local name = Collection.CleanName(if type(args) == "table" then args.Name else nil)
		if name == nil or name == "" then
			return nil -- the rule refuses it, or takes the nickname off
		end
		local seen = TextFilterService.ForUser(player, name, player)
		if seen == nil then
			return VoidkinService.FilterFailed
		end
		return if seen ~= name then VoidkinService.Filtered else nil
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
			local asked = if type(args) == "table" then args.Voidkin else nil
			if FROZEN[name] and asked ~= nil and asked == draft.Roles.Lead and FightService.Frozen(player) then
				return { Ok = false, Error = "InCombat" }
			end
			local facts: Collection.Facts = {
				Healing = function(id: string): boolean
					return LeadService.Healing(player, id)
				end,
			}
			return action(draft, args, workspace:GetServerTimeNow(), 0, facts)
		end, BEFORE[name])
	end
	-- The owner's copy carries each nickname filtered for them; one not filtered yet shows as none until it is.
	DataService.Shape(function(player: Player, view: Profile.View)
		for _, owned in view.Voidkin do
			if owned.Nickname ~= "" then
				owned.Nickname = TextFilterService.Cached(player, owned.Nickname, player) or ""
			end
		end
	end)
	TextFilterService.Filtered:Connect(function(author: Player, viewer: Player)
		if author == viewer then
			DataService.Push(viewer)
		end
	end)
end

return VoidkinService
