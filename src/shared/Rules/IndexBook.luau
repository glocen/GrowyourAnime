--!strict
-- The Index's records (TR76; docs/design.md, "The Index"; Config.Index), pure Luau and a leaf: it requires no other
-- rule, so the rules that find things (Chests, Shop) and Stats can require it. It holds what the save can't give back
-- later: a Shade's kills, and a gear design seen once (an auto-salvaged piece never reaches the bag). Emblems and jewels
-- are read from what's held when the book is read, and recorded then (Rules.Index), as a Voidkin's find is data.Index.
-- The claims and the pay are Rules.Index's.
--   IndexBook.Of(data)                       the save's book, made on first use
--   IndexBook.GearKey(def, rarity, design)   a gear design's entry, "def:rarity:design"
--   IndexBook.Fell(data, foe)                a Shade's kill counted (DropService, beside Drops.Give)
--   IndexBook.Saw(data, def, rarity, design) a gear design seen (Chests.Open, Shop.Buy)
--   IndexBook.Attributes(data)               the flat points the claimed milestones give each Basic Attribute

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local IndexConfig = require(Shared.Config.Index)

local IndexBook = {}

function IndexBook.Of(data: Profile.Data): Profile.Book
	local book = data.Book
	if book == nil then
		book = { Kills = {}, Gear = {}, Emblems = {}, Jewels = {}, Claimed = {}, Milestones = {} }
		data.Book = book
	end
	return book :: Profile.Book
end

function IndexBook.GearKey(def: string, rarity: string, design: number): string
	return `{def}:{rarity}:{design}`
end

function IndexBook.Fell(data: Profile.Data, foe: any)
	if type(foe) ~= "string" or foe == "" then
		return
	end
	local kills = IndexBook.Of(data).Kills
	kills[foe] = (kills[foe] or 0) + 1
end

function IndexBook.Saw(data: Profile.Data, def: string, rarity: string, design: number)
	IndexBook.Of(data).Gear[IndexBook.GearKey(def, rarity, design)] = true
end

function IndexBook.Attributes(data: Profile.Data?): number
	local book = if data then data.Book else nil
	if book == nil then
		return 0
	end
	local total = 0
	for _, milestone in IndexConfig.Milestones do
		if book.Milestones[tostring(milestone.At)] then
			total += milestone.Pay.Attributes or 0
		end
	end
	return total
end

return IndexBook
