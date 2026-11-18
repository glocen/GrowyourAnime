--!strict
-- RegaliaService (server): what a player may ask of the gear they own: the equip and the unequip (Shared.Rules.Regalia),
-- a chest opened and the salvage's rarity (Shared.Rules.Chests). Each is registered with the save's one door, so it's one
-- transaction with its op id and a repeat answers its first answer. An open's rolls come from a generator seeded inside
-- its transaction, never from the client. The lead's block follows on its own: LeadService resolves it again on every
-- change. Chests drop at a fall (DropService, KeeperService); Studio's "ChestGive" and "ItemGive" make them by hand.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Rarity = require(Shared.Definitions.Rarity)
local Attributes = require(Shared.Definitions.Attributes)
local Stats = require(Shared.Rules.Stats)
local Regalia = require(Shared.Rules.Regalia)
local Chests = require(Shared.Rules.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local DataService = require(script.Parent.Parent.Core.DataService)
local DebugService = require(script.Parent.Parent.Core.DebugService)
local FightService = require(script.Parent.FightService)

local RegaliaService = {
	Priority = 20, -- after DataService
}

local seeds = Random.new()

local function registerDebug()
	-- Studio only. `count` of chest `chest` in the bag (a negative count takes them out, never below none).
	DebugService.Register("ChestGive", function(who: any, chest: any, count: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(chest) ~= "string" or ChestRows.ById[chest] == nil or type(count) ~= "number" or count ~= math.floor(count) then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "ChestGive", function(draft: Profile.Data): { [string]: any }
			local held = math.max(0, (draft.Bag.Chests[chest] or 0) + count)
			draft.Bag.Chests[chest] = if held > 0 then held else nil
			return { Ok = true, Held = held }
		end)
	end)
	-- Studio only. An item of a row in the bag: its rarity (Common by default), its tier (1) and its lines as given, each
	-- { Stat, Value } naming a Battle Attribute or a Basic Attribute. Answers its id.
	-- Studio only. Item `id` out of the save and out of every preset that wears it: a case's own items, taken back.
	DebugService.Register("ItemTake", function(who: any, id: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(id) ~= "string" then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "ItemTake", function(draft: Profile.Data): { [string]: any }
			if draft.Items[id] == nil then
				return { Ok = false, Error = "NotOwned" }
			end
			draft.Items[id] = nil
			for _, preset in draft.Presets do
				for slot, worn in preset.Slots do
					if worn == id then
						preset.Slots[slot] = nil
					end
				end
				for class, pair in preset.Hands do
					for slot, worn in pair do
						if worn == id then
							pair[slot] = nil
						end
					end
					if next(pair) == nil then
						preset.Hands[class] = nil
					end
				end
			end
			return { Ok = true }
		end)
	end)
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
				Design = 1,
				Lines = rolled,
				Sockets = {},
				Jewel = "",
			}
			return { Ok = true, Id = id }
		end)
	end)
end

function RegaliaService.Init()
	-- Gear never changes in a fight, and stays frozen through a keeper's try and a Tower run (D10): the client's
	-- "Not during a fight" answers this refusal.
	for name, action in Regalia.Actions do
		DataService.Action(name, function(draft: Profile.Data, args: any, player: Player): { [string]: any }
			if FightService.InCombat(player) or FightService.Frozen(player) then
				return { Ok = false, Error = "InCombat" }
			end
			return action(draft, args)
		end)
	end
	DataService.Action("OpenChests", function(draft: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		local rng = Random.new(seeds:NextInteger(0, 2 ^ 31 - 1))
		return Chests.Open(draft, given.Chest, given.Count, function(): number
			return rng:NextNumber()
		end)
	end)
	DataService.Action("SetSalvage", function(draft: Profile.Data, args: any): { [string]: any }
		return Chests.SetSalvage(draft, if type(args) == "table" then args.Below else nil)
	end)
	-- One owned item into Credits by the player's hand (Rules.Chests.SalvageItem): never one a preset wears, so it changes
	-- no fighter's stats and needs no fight check.
	DataService.Action("SalvageItem", function(draft: Profile.Data, args: any): { [string]: any }
		return Chests.SalvageItem(draft, if type(args) == "table" then args.Item else nil)
	end)
	if RunService:IsStudio() then
		registerDebug()
	end
end

return RegaliaService
