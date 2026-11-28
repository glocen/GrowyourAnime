--!strict
-- The Index, the collection book (TR76; docs/design.md, "The Index"; Config.Index; its records, Rules.IndexBook), pure
-- Luau. Four tabs of entries, each with its stamps; a stamp is earned from the save as it stands (and, for what the save
-- can't give back, from the book's records), and stays earned once claimed. "Claim all" pays every earned stamp not yet
-- claimed (a find's pay once, every stamp an Index point) and every milestone its points reach, in one step.
--   Voidkin  each one: found, three stars, seven stars, Mastery rank 5
--   Shades   each foe: found on its first kill, then 10, 100 and 500 kills
--   Regalia  each gear design by kind and rarity: found when one is first rolled, auto-salvaged or not
--   Emblems  each emblem set, and each jewel colour and tier
--   Index.Tabs                          the tab names, in order
--   Index.Entries(tab)                  a tab's entry ids, in order
--   Index.Stamps(tab, id)               an entry's stamp keys, its find first
--   Index.Earned(data)                  every stamp earned, by key
--   Index.Points(data)                  the Index points its earned stamps give
--   Index.Done(data, tab)               every stamp of the tab earned
--   Index.Waiting(data)                 the stamps and milestones a claim would pay now
--   Index.Claim(data)                   "Claim all": { Ok, Stamps, Milestones, Credits, Chests, Stones, Tokens, Attributes }

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local IndexConfig = require(Shared.Config.Index)
local ChestsConfig = require(Shared.Config.Chests)
local JewelsConfig = require(Shared.Config.Jewels)
local VoidkinRows = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local Items = require(Shared.Definitions.Items)
local EmblemSets = require(Shared.Definitions.Emblems)
local Mastery = require(Shared.Rules.Mastery)
local Collection = require(Shared.Rules.Collection)
local Chests = require(Shared.Rules.Chests)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)
local IndexBook = require(Shared.Rules.IndexBook)

local Index = {}

Index.Nothing = "Nothing" -- nothing earned waits to be claimed

Index.Tabs = { "Voidkin", "Shades", "Regalia", "Emblems" }

-- Each tab's entries, in a fixed order: the definitions' own.
local ENTRIES: { [string]: { string } } = { Voidkin = {}, Shades = {}, Regalia = {}, Emblems = {} }
for _, row in VoidkinRows.List do
	table.insert(ENTRIES.Voidkin, row.Id)
end
for _, row in Enemies.List do
	if row.Kind ~= "Dummy" then
		table.insert(ENTRIES.Shades, row.Id)
	end
end
for _, row in Items.List do
	for _, rarity in ChestsConfig.Rarities do
		for design = 1, Items.Designs(row.Id, rarity) do
			table.insert(ENTRIES.Regalia, IndexBook.GearKey(row.Id, rarity, design))
		end
	end
end
for _, set in EmblemSets.List do
	table.insert(ENTRIES.Emblems, `set:{set.Id}`)
end
for _, colour in JewelsConfig.Colours do
	for tier = 1, #JewelsConfig.Worth do
		table.insert(ENTRIES.Emblems, `jewel:{Jewels.Key(colour, tier)}`)
	end
end

function Index.Entries(tab: string): { string }
	return ENTRIES[tab] or {}
end

-- An entry's stamp keys, its find first: "<tab>|<entry>|<stamp>".
function Index.Stamps(tab: string, id: string): { string }
	local out = { `{tab}|{id}|Found` }
	if tab == "Voidkin" then
		for _, stars in IndexConfig.Stars do
			table.insert(out, `{tab}|{id}|Stars{stars}`)
		end
		table.insert(out, `{tab}|{id}|Mastery{IndexConfig.MasteryRank}`)
	elseif tab == "Shades" then
		for _, kills in IndexConfig.Kills do
			table.insert(out, `{tab}|{id}|Kills{kills}`)
		end
	end
	return out
end

-- Records the emblem sets and jewels held now, in the bag and in gear, so a later combine or salvage never unfinds one.
local function notice(data: Profile.Data)
	local book = IndexBook.Of(data)
	local function emblem(key: string)
		local parsed = Emblems.Parse(key)
		if parsed then
			book.Emblems[parsed.Set.Id] = true
		end
	end
	local function jewel(key: string)
		local colour = Jewels.Parse(key)
		if colour then
			book.Jewels[key] = true
		end
	end
	for key, count in data.Bag.Emblems do
		if count > 0 then
			emblem(key)
		end
	end
	for key, count in data.Bag.Jewels do
		if count > 0 then
			jewel(key)
		end
	end
	for _, item in data.Items do
		for _, key in item.Sockets do
			if key ~= "" then
				emblem(key)
			end
		end
		for colour, tier in item.Jewels do
			jewel(Jewels.Key(colour, tier))
		end
	end
end

-- Every stamp earned now, by key, from a book as it stands (nothing written).
local function earned(data: Profile.Data, book: Profile.Book): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for key in book.Claimed do
		out[key] = true
	end
	for _, def in ENTRIES.Voidkin do
		if data.Index[def] then
			out[`Voidkin|{def}|Found`] = true
			local owned = Collection.Owned(data, def)
			if owned then
				for _, stars in IndexConfig.Stars do
					if owned.Stars >= stars then
						out[`Voidkin|{def}|Stars{stars}`] = true
					end
				end
				if Mastery.Rank(Mastery.Xp(owned)) >= IndexConfig.MasteryRank then
					out[`Voidkin|{def}|Mastery{IndexConfig.MasteryRank}`] = true
				end
			end
		end
	end
	for _, foe in ENTRIES.Shades do
		local kills = book.Kills[foe] or 0
		if kills >= 1 then
			out[`Shades|{foe}|Found`] = true
		end
		for _, at in IndexConfig.Kills do
			if kills >= at then
				out[`Shades|{foe}|Kills{at}`] = true
			end
		end
	end
	for key in book.Gear do
		out[`Regalia|{key}|Found`] = true
	end
	for set in book.Emblems do
		out[`Emblems|set:{set}|Found`] = true
	end
	for key in book.Jewels do
		out[`Emblems|jewel:{key}|Found`] = true
	end
	return out
end

-- A copy of the book with what's held now noticed, so a read never writes the save.
local function viewed(data: Profile.Data): Profile.Book
	local copy = Profile.DeepCopy(data)
	notice(copy)
	return IndexBook.Of(copy)
end

function Index.Earned(data: Profile.Data): { [string]: boolean }
	return earned(data, viewed(data))
end

local function count(set: { [string]: boolean }): number
	local n = 0
	for _ in set do
		n += 1
	end
	return n
end

function Index.Points(data: Profile.Data): number
	return count(Index.Earned(data)) * IndexConfig.Point
end

function Index.Done(data: Profile.Data, tab: string): boolean
	local have = Index.Earned(data)
	for _, id in Index.Entries(tab) do
		for _, key in Index.Stamps(tab, id) do
			if not have[key] then
				return false
			end
		end
	end
	return #Index.Entries(tab) > 0
end

-- The stamps earned and not claimed, sorted, and the milestones reached and not claimed, in order.
local function waiting(data: Profile.Data, book: Profile.Book): ({ string }, { number })
	local have = earned(data, book)
	local stamps = {}
	for key in have do
		if not book.Claimed[key] then
			table.insert(stamps, key)
		end
	end
	table.sort(stamps)
	local points = count(have) * IndexConfig.Point
	local milestones = {}
	for _, milestone in IndexConfig.Milestones do
		if points >= milestone.At and not book.Milestones[tostring(milestone.At)] then
			table.insert(milestones, milestone.At)
		end
	end
	return stamps, milestones
end

function Index.Waiting(data: Profile.Data): { Stamps: { string }, Milestones: { number } }
	local stamps, milestones = waiting(data, viewed(data))
	return { Stamps = stamps, Milestones = milestones }
end

-- A find's pay row: its tab's, a Keeper's own.
local function findPay(key: string): IndexConfig.Pay?
	local tab, id, stamp = string.match(key, "^([^|]+)|([^|]+)|([^|]+)$")
	if stamp ~= "Found" then
		return nil
	end
	local find = IndexConfig.Find
	if tab == "Voidkin" then
		return find.Voidkin
	elseif tab == "Shades" then
		local row = Enemies.ById[id :: string]
		return if row and row.Kind == "Keeper" then find.Keeper else find.Shade
	elseif tab == "Regalia" then
		return find.Regalia
	elseif tab == "Emblems" then
		return if string.sub(id :: string, 1, 4) == "set:" then find.Emblem else find.Jewel
	end
	return nil
end

-- "Claim all": pays every earned stamp not yet claimed and every milestone reached, in one step. A refusal changes nothing.
function Index.Claim(data: Profile.Data): { [string]: any }
	local before, reached = waiting(data, viewed(data))
	if #before == 0 and #reached == 0 then
		return { Ok = false, Error = Index.Nothing }
	end
	local book = IndexBook.Of(data)
	notice(data)
	local stamps, milestones = waiting(data, book)
	local got = { Credits = 0, Chests = {} :: { [string]: number }, Stones = {} :: { [string]: number }, Tokens = {} :: { [string]: number }, Attributes = 0 }
	local function pay(row: IndexConfig.Pay?)
		if row == nil then
			return
		end
		got.Credits += row.Credits or 0
		got.Attributes += row.Attributes or 0
		for id, n in row.Chests or {} do
			got.Chests[id] = (got.Chests[id] or 0) + n
		end
		for grade, n in row.Stones or {} do
			got.Stones[grade] = (got.Stones[grade] or 0) + n
		end
		for id, n in row.Tokens or {} do
			got.Tokens[id] = (got.Tokens[id] or 0) + n
		end
	end
	for _, key in stamps do
		book.Claimed[key] = true
		pay(findPay(key))
	end
	for _, at in milestones do
		book.Milestones[tostring(at)] = true
		for _, milestone in IndexConfig.Milestones do
			if milestone.At == at then
				pay(milestone.Pay)
			end
		end
	end
	data.Currency.Credits += got.Credits
	for id, n in got.Chests do
		Chests.Grant(data, id, n)
	end
	for grade, n in got.Stones do
		data.Bag.Stones[grade] = (data.Bag.Stones[grade] or 0) + n
	end
	for id, n in got.Tokens do
		data.Bag.Tokens[id] = (data.Bag.Tokens[id] or 0) + n
	end
	return {
		Ok = true,
		Stamps = #stamps,
		Milestones = milestones,
		Credits = got.Credits,
		Chests = got.Chests,
		Stones = got.Stones,
		Tokens = got.Tokens,
		Attributes = got.Attributes, -- each Basic Attribute's new flat points (IndexBook.Attributes holds the whole)
	}
end

return Index
