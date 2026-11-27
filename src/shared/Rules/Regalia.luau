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
Regalia.WornElsewhere = "WornElsewhere" -- a transfer from an item another preset still wears (it would lose what it holds)

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

-- Whether an item holds anything the equip transfer would move: a Reinforce level, an emblem or a jewel (TR47).
function Regalia.Holds(item: Profile.OwnedItem): boolean
	if item.Reinforce > 0 or next(item.Jewels) ~= nil then
		return true
	end
	for _, key in item.Sockets do
		if key ~= "" then
			return true
		end
	end
	return false
end

-- The equip transfer (TR47; docs/design.md, "Reinforce levels, emblems and jewels belong to the item"): what `from` holds
-- moves to `to`, for free, and nothing is ever lost. The two Reinforce levels change places, since an item holds one.
-- `from`'s emblems fill `to`'s empty sockets in order, and `to` keeps its own; those with no room stay on `from`, packed
-- to its first sockets. A jewel moves into its colour's slot when `to`'s is empty, and stays on `from` when it isn't.
-- Each item keeps its own count of sockets. Answers how many emblems moved and how many stayed.
function Regalia.Transfer(from: Profile.OwnedItem, to: Profile.OwnedItem): (number, number)
	from.Reinforce, to.Reinforce = to.Reinforce, from.Reinforce
	from.Heat, to.Heat = to.Heat, from.Heat -- the heat moves with its level (TR55)
	for colour, level in from.Jewels do
		if (to.Jewels[colour] or 0) == 0 then
			to.Jewels[colour] = level
			from.Jewels[colour] = nil
		end
	end
	local kept: { string } = {}
	local moved = 0
	for _, key in from.Sockets do
		if key ~= "" then
			local free = table.find(to.Sockets, "")
			if free then
				to.Sockets[free] = key
				moved += 1
			else
				table.insert(kept, key)
			end
		end
	end
	for index = 1, #from.Sockets do
		from.Sockets[index] = kept[index] or ""
	end
	return moved, #kept
end

-- The first preset other than `index` that wears `id` in any slot or hand, or nil.
function Regalia.WornIn(data: Profile.Data, id: string, index: number): number?
	for other, preset in data.Presets do
		if other ~= index then
			for _, worn in preset.Slots do
				if worn == id then
					return other
				end
			end
			for _, pair in preset.Hands do
				for _, worn in pair do
					if worn == id then
						return other
					end
				end
			end
		end
	end
	return nil
end

-- What `slot` of `preset` wears for `class`'s pair in a hand, or nil.
function Regalia.Worn(preset: Profile.Preset, slot: string, class: string?): string?
	if Gear.IsHand(slot) then
		local pair = if class then preset.Hands[class] else nil
		return if pair then pair[slot] else nil
	end
	return preset.Slots[slot]
end

-- Wears `id` in `slot` of preset `index` (an empty or nil id takes off what's there), for `class`'s pair in a hand. With
-- `move`, the item it replaces gives it its Reinforce level, emblems and jewels first (Regalia.Transfer): the player's Yes
-- to the prompt the screen shows when that item holds any (Regalia.Holds). Refused when another preset wears that item.
-- Answers what it did, or a refusal that changed nothing.
function Regalia.Equip(data: Profile.Data, index: any, slot: any, class: any, id: any, move: any): { [string]: any }
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
	local was = Regalia.Worn(preset, slot, owner)
	local moved, stayed = 0, 0
	if move == true and wearing and was and was ~= wearing and data.Items[was] then
		-- Another preset still wears the old item: the transfer would strip it there, silently (research's launch bug 2,
		-- 2026-11-27). Refused with that preset's number; an equip without the transfer still goes.
		local other = Regalia.WornIn(data, was, index)
		if other then
			return { Ok = false, Error = Regalia.WornElsewhere, Preset = other }
		end
		moved, stayed = Regalia.Transfer(data.Items[was], data.Items[wearing])
	end
	Regalia.Put(preset, slot, owner, wearing)
	return {
		Ok = true,
		Preset = index,
		Slot = slot,
		Class = owner,
		Item = wearing or "",
		Was = was or "",
		Moved = move == true and wearing ~= nil and was ~= nil and was ~= wearing,
		Emblems = moved,
		Stayed = stayed,
	}
end

-- Links Voidkin `id` to preset `index`, one the base's level holds (TR56): it fights in that preset's slots and its own
-- class's pair from it. Answers { Ok, Voidkin, Preset }, or a refusal that changed nothing.
function Regalia.UsePreset(data: Profile.Data, id: any, index: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if owned == nil or type(index) ~= "number" or data.Presets[index] == nil then
		return { Ok = false, Error = Regalia.Unknown }
	end
	owned.Preset = index
	return { Ok = true, Voidkin = owned.Id, Preset = index }
end

-- What a client may ask, by name, through the Act remote. Equip's args: { Preset, Slot, Class?, Item?, Move? };
-- UsePreset's: { Voidkin, Preset }.
Regalia.Actions = {
	UsePreset = function(data: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		return Regalia.UsePreset(data, given.Voidkin, given.Preset)
	end,
	Equip = function(data: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		return Regalia.Equip(data, given.Preset, given.Slot, given.Class, given.Item, given.Move)
	end,
} :: { [string]: (Profile.Data, any) -> { [string]: any } }

return Regalia
