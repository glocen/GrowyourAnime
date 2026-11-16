--!strict
-- Regalia (shared, pure): what a player may wear where (docs/engineering-plan.md, "Class rules"; docs/design.md,
-- "Regalia: gear"; docs/research/rework-2026-11-16.md, part 10). Gear belongs to the account and one item may sit in
-- several presets, never twice in one. A preset's twelve shared slots take armour of their kind, and each class's pair
-- takes only that class's weapons (Definitions.Items.Fits). The server runs Equip in one transaction with its op id
-- (Services.Main.RegaliaService); the comparison is the resolver's (Rules.Stats.Compare), which puts with Put here.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Definitions.Gear)
local Items = require(Shared.Definitions.Items)
local Profile = require(Shared.Data.Profile)

local Regalia = {}

-- The refusals, which the screen says.
Regalia.Unknown = "Unknown" -- no such preset, or the request isn't one
Regalia.NotOwned = "NotOwned" -- the item isn't the player's
Regalia.WrongSlot = "WrongSlot" -- the item doesn't go in that slot
Regalia.WrongClass = "WrongClass" -- a weapon for another class, or a hand named for no class

-- Puts `id` in `slot` of `preset` (nil: empties it), for `class`'s pair when the slot is a hand. The item leaves any
-- other place it held in this preset, so a ring moves from Ring I to Ring II rather than being worn twice. A pair left
-- empty is taken out, so the save holds no empty tables it doesn't need. It checks nothing: Equip does, first.
function Regalia.Put(preset: Profile.Preset, slot: string, class: string?, id: string?)
	if id ~= nil then
		for other, worn in preset.Slots do
			if worn == id then
				preset.Slots[other] = nil
			end
		end
		for owner, pair in preset.Hands do
			for other, worn in pair do
				if worn == id then
					pair[other] = nil
				end
			end
			if next(pair) == nil then
				preset.Hands[owner] = nil
			end
		end
	end
	if Gear.IsHand(slot) then
		if class == nil then
			return
		end
		local pair = preset.Hands[class] or {}
		pair[slot] = id
		preset.Hands[class] = if next(pair) == nil then nil else pair
	else
		preset.Slots[slot] = id
	end
end

-- Why `id` can't go in `slot` of a preset for `class`, or nil when it can. A hand names its class; a weapon's own row
-- names it when the request doesn't.
function Regalia.Refusal(data: Profile.Data, slot: string, class: string?, id: string): string?
	local item = data.Items[id]
	if item == nil then
		return Regalia.NotOwned
	end
	local row = Items.ById[item.Def]
	if row == nil then
		return Regalia.WrongSlot
	end
	if Items.Fits(row, slot, class) then
		return nil
	end
	if Gear.IsHand(slot) and row.Class ~= nil and row.Slot == slot then
		return Regalia.WrongClass -- the right hand, another class's weapon
	end
	return Regalia.WrongSlot
end

-- Wears `id` in `slot` of preset `index` (an empty or nil id takes off what's there), for `class`'s pair in a hand.
-- Answers what it did, or a refusal that changed nothing.
function Regalia.Equip(data: Profile.Data, index: any, slot: any, class: any, id: any): { [string]: any }
	local preset = if type(index) == "number" then data.Presets[index] else nil
	if preset == nil or type(slot) ~= "string" then
		return { Ok = false, Error = Regalia.Unknown }
	end
	if not (Gear.IsShared(slot) or Gear.IsHand(slot)) then
		return { Ok = false, Error = Regalia.WrongSlot }
	end
	if id ~= nil and type(id) ~= "string" then
		return { Ok = false, Error = Regalia.Unknown }
	end
	local wearing: string? = if id == "" then nil else id
	local owner: string? = nil
	if Gear.IsHand(slot) then
		owner = if type(class) == "string" then class else nil
		if owner == nil and wearing then
			local item = data.Items[wearing]
			local row = if item then Items.ById[item.Def] else nil
			owner = if row then row.Class else nil
		end
		if owner == nil or Gear.Weapons[owner] == nil then
			return { Ok = false, Error = if wearing and data.Items[wearing] == nil then Regalia.NotOwned else Regalia.WrongClass }
		end
	end
	if wearing then
		local refusal = Regalia.Refusal(data, slot, owner, wearing)
		if refusal then
			return { Ok = false, Error = refusal }
		end
	end
	Regalia.Put(preset, slot, owner, wearing)
	return { Ok = true, Preset = index, Slot = slot, Class = owner, Item = wearing or "" }
end

-- What a client may ask, by name, through the Act remote. Args: { Preset, Slot, Class?, Item? }.
Regalia.Actions = {
	Equip = function(data: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		return Regalia.Equip(data, given.Preset, given.Slot, given.Class, given.Item)
	end,
} :: { [string]: (Profile.Data, any) -> { [string]: any } }

return Regalia
