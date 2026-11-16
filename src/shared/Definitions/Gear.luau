--!strict
-- Gear (shared, content): Regalia's slots and each class's weapon pair (docs/design.md, "Regalia: gear"; the director's
-- words, 2026-11-12). Gear belongs to the account. A preset holds the twelve shared slots and one weapon pair for each
-- class, and a Voidkin fights with its own class's pair from the preset it's linked to (Profile.Preset: Slots by the
-- shared slots' names, Hands by class, then by hand). What goes in a slot is an item row's (Definitions.Items, Fits).
-- No Roblox API: it runs with Studio closed.

local Gear = {}

-- The two weapon slots: what fills them belongs to a class.
Gear.Hands = { "Main Hand", "Off Hand" }

-- The twelve every class shares.
Gear.Shared = {
	"Helmet",
	"Shoulders",
	"Chest Armor",
	"Gloves",
	"Bracers",
	"Boots",
	"Cloak",
	"Amulet",
	"Ring I",
	"Ring II",
	"Earring I",
	"Earring II",
}

-- Each class's pair, by slot. Every main hand is a silhouette no other class shares.
Gear.Weapons = {
	Tank = { ["Main Hand"] = "Great Axe", ["Off Hand"] = "Shield" },
	Mage = { ["Main Hand"] = "Staff", ["Off Hand"] = "Tome" },
	Assassin = { ["Main Hand"] = "Dagger", ["Off Hand"] = "Throwing Blades" },
	Warrior = { ["Main Hand"] = "Sword", ["Off Hand"] = "Short Sword" },
	Healer = { ["Main Hand"] = "Crystal Baton", ["Off Hand"] = "Codex" },
} :: { [string]: { [string]: string } }

-- What a slot holds for a class: its weapon's kind in a hand, the slot's own name anywhere else.
function Gear.Kind(slot: string, class: string): string
	local pair = Gear.Weapons[class]
	return if pair and pair[slot] then pair[slot] else slot
end

-- The two slots of one kind: an item row's Slot names the kind, and fits either.
Gear.Pairs = { ["Ring I"] = "Ring", ["Ring II"] = "Ring", ["Earring I"] = "Earring", ["Earring II"] = "Earring" } :: {
	[string]: string,
}

-- The kind of slot `slot` is: "Ring" for either ring, "Earring" for either earring, the slot's own name otherwise.
function Gear.Family(slot: string): string
	return Gear.Pairs[slot] or slot
end

-- The slots a kind fits, in the sheet's order.
function Gear.SlotsOf(family: string): { string }
	local out = {}
	for _, slot in Gear.Shared do
		if Gear.Family(slot) == family then
			table.insert(out, slot)
		end
	end
	if #out == 0 and Gear.IsHand(family) then
		table.insert(out, family)
	end
	return out
end

function Gear.IsHand(slot: string): boolean
	return slot == "Main Hand" or slot == "Off Hand"
end

function Gear.IsShared(slot: string): boolean
	return table.find(Gear.Shared, slot) ~= nil
end

return Gear
