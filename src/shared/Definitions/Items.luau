--!strict
-- Items (shared, content): the row an owned item's Def names (docs/engineering-plan.md, "Class rules"; docs/design.md,
-- "Regalia: gear"). A row says where the item goes and how it's read, never what it rolled: an owned item's tier,
-- rarity and lines are on the item (Data.Profile, OwnedItem).
--   Slot   the kind of slot it fits: a shared slot's name, "Ring" or "Earring" for either of the two, or a hand
--   Kind   what it is, which picks its icon: the slot's name for armour, the weapon's for a weapon (Gear.Weapons)
--   Name   what players read
--   Class  on a weapon only: the one class that wields it
-- One row per kind. A kind's looks and names are its designs (Definitions.ItemDesigns, AR6): an owned item keeps the index
-- of its own (docs/design.md, Regalia, "An item's design"). No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Gear = require(Shared.Definitions.Gear)
local ItemDesigns = require(Shared.Definitions.ItemDesigns)

export type Row = { Id: string, Slot: string, Kind: string, Name: string, Class: string? }

local List: { Row } = {
	{ Id = "helmet", Slot = "Helmet", Kind = "Helmet", Name = "Helmet" },
	{ Id = "shoulders", Slot = "Shoulders", Kind = "Shoulders", Name = "Shoulders" },
	{ Id = "chest_armor", Slot = "Chest Armor", Kind = "Chest Armor", Name = "Chest Armor" },
	{ Id = "gloves", Slot = "Gloves", Kind = "Gloves", Name = "Gloves" },
	{ Id = "bracers", Slot = "Bracers", Kind = "Bracers", Name = "Bracers" },
	{ Id = "boots", Slot = "Boots", Kind = "Boots", Name = "Boots" },
	{ Id = "cloak", Slot = "Cloak", Kind = "Cloak", Name = "Cloak" },
	{ Id = "amulet", Slot = "Amulet", Kind = "Amulet", Name = "Amulet" },
	{ Id = "ring", Slot = "Ring", Kind = "Ring", Name = "Ring" },
	{ Id = "earring", Slot = "Earring", Kind = "Earring", Name = "Earring" },
	{ Id = "great_axe", Slot = "Main Hand", Kind = "Great Axe", Name = "Great Axe", Class = "Tank" },
	{ Id = "shield", Slot = "Off Hand", Kind = "Shield", Name = "Shield", Class = "Tank" },
	{ Id = "staff", Slot = "Main Hand", Kind = "Staff", Name = "Staff", Class = "Mage" },
	{ Id = "tome", Slot = "Off Hand", Kind = "Tome", Name = "Tome", Class = "Mage" },
	{ Id = "dagger", Slot = "Main Hand", Kind = "Dagger", Name = "Dagger", Class = "Assassin" },
	{ Id = "throwing_blades", Slot = "Off Hand", Kind = "Throwing Blades", Name = "Throwing Blades", Class = "Assassin" },
	{ Id = "sword", Slot = "Main Hand", Kind = "Sword", Name = "Sword", Class = "Warrior" },
	{ Id = "short_sword", Slot = "Off Hand", Kind = "Short Sword", Name = "Short Sword", Class = "Warrior" },
	{ Id = "crystal_baton", Slot = "Main Hand", Kind = "Crystal Baton", Name = "Crystal Baton", Class = "Healer" },
	{ Id = "codex", Slot = "Off Hand", Kind = "Codex", Name = "Codex", Class = "Healer" },
}

local ById: { [string]: Row } = {}
for _, row in List do
	ById[row.Id] = row
end

-- Whether a row goes in `slot` for a Voidkin of `class`: a weapon in its own hand for its own class only, anything else
-- in a shared slot of its kind. The resolver and the equip both ask it, so a save edited by hand applies nothing the
-- equip would refuse.
local function Fits(row: Row, slot: string, class: string?): boolean
	if Gear.IsHand(slot) then
		return row.Class ~= nil and row.Class == class and row.Slot == slot
	end
	return row.Class == nil and Gear.IsShared(slot) and row.Slot == Gear.Family(slot)
end

-- How many designs a kind has at a rarity: what a drop picks from (Rules.Chests.Roll).
local function Designs(def: string, rarity: string): number
	local row = ById[def]
	local by = if row then ItemDesigns.ByKind[row.Kind] else nil
	local list = if by then by[rarity] else nil
	return if list then #list else 0
end

-- An owned item's design: its look and its name, by the index it took at its drop. A design is never a stat. Nil when
-- the save names no design its kind has at its rarity (a save edited by hand), and the reader falls back on the row.
local function Design(item: { Def: string, Rarity: string, Design: number }): ItemDesigns.Design?
	local row = ById[item.Def]
	local by = if row then ItemDesigns.ByKind[row.Kind] else nil
	local list = if by then by[item.Rarity] else nil
	return if list then list[item.Design] else nil
end

-- The design an item saved before designs takes (Data.Migrations, step 7): from its id, over the launch's three designs
-- forever, so a design added later never moves one. Pure: the same id gives the same design on every server.
local LAUNCH_DESIGNS = 3
local function LaunchDesign(id: string): number
	local hash = 0
	for i = 1, #id do
		hash = (hash * 31 + string.byte(id, i)) % 2147483647
	end
	return hash % LAUNCH_DESIGNS + 1
end

return {
	List = List,
	ById = ById,
	Fits = Fits,
	Designs = Designs,
	Design = Design,
	LaunchDesign = LaunchDesign,
}
