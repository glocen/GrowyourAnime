--!strict
-- RegaliaService (server): what a player may ask of the gear they own, the equip and the unequip (Shared.Rules.Regalia),
-- registered with the save's one door, so each is one transaction with its op id and a repeat answers its first answer.
-- The lead's block follows on its own: LeadService resolves it again on every change. Items come from chests (part 11);
-- until then, Studio's "ItemGive" makes one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Rarity = require(Shared.Definitions.Rarity)
local Attributes = require(Shared.Definitions.Attributes)
local Stats = require(Shared.Rules.Stats)
local Regalia = require(Shared.Rules.Regalia)
local DataService = require(script.Parent.Parent.Core.DataService)
local DebugService = require(script.Parent.Parent.Core.DebugService)

local RegaliaService = {
	Priority = 20, -- after DataService
}

local function registerDebug()
	-- Studio only. An item of a row in the bag: its rarity (Common by default), its tier (1) and its lines as given, each
	-- { Stat, Value } naming a Battle Attribute or a Basic Attribute. Answers its id.
	DebugService.Register("ItemGive", function(who: any, def: any, rarity: any, lines: any, tier: any): any
		local player = DebugService.ResolvePlayer(who)
		local grade = if rarity == nil then "Common" else rarity
		if not player or type(def) ~= "string" or Items.ById[def] == nil or Rarity.Rank[grade] == nil then
			return { Ok = false, Error = "BadArgs" }
		end
		local rolled: { Profile.ItemLine } = {}
		for _, line in (if type(lines) == "table" then lines else {}) :: { any } do
			local known = type(line) == "table" and type(line.Value) == "number" and line.Value == line.Value
				and (table.find(Stats.Names, line.Stat) ~= nil or Attributes.ById[line.Stat] ~= nil)
			if not known then
				return { Ok = false, Error = "BadArgs" }
			end
			table.insert(rolled, { Stat = line.Stat, Value = line.Value })
		end
		return DataService.Change(player, "ItemGive", function(draft: Profile.Data): { [string]: any }
			local id = Profile.NewId(draft)
			draft.Items[id] = {
				Id = id,
				Def = def,
				Tier = if type(tier) == "number" then tier else 1,
				Rarity = grade,
				Lines = rolled,
				Sockets = {},
				Jewel = "",
			}
			return { Ok = true, Id = id }
		end)
	end)
end

function RegaliaService.Init()
	for name, action in Regalia.Actions do
		DataService.Action(name, action)
	end
	if RunService:IsStudio() then
		registerDebug()
	end
end

return RegaliaService
