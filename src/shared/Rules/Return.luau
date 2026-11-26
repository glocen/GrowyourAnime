--!strict
-- Return (shared, pure): the base between runs (TR53, TR31 folded in; docs/test-requests.md, TR53). While the player
-- is away from the base, on a run in another place or offline, a record of what it does stays open on the save
-- (Base.Away), and every advance adds to it (Rules.Breaker). Back at the base, the record closes onto the return card
-- (Base.Card), which waits for its one press. The server credits everything as it happens or on arrival: the overflow's
-- Credits and the levels as the base advances, the Condenser's tray, its stones and its jewels, into the bag on arrival
-- (TR66 #11: the jewels too, and the card names them). The press only shows it.
--   Return.Open(data)               opens the record from the base as it stands; one already open stays
--   Return.Arrive(data)             back at the base: the tray's stones and jewels into the bag, the record closed onto the card (merged with
--                                   one not yet seen); the card, or nil when nothing changed
--   Return.Lines(card, room?)       the card's lines in AR55's order: the battery, each grade of stone, the jewels, the Training
--                                   machine, the workers who gained a level, the shards; empty for no card. `room`: the
--                                   lines the card has room for, the workers folding sooner to fit
--   Return.Seen(data, args, now)    the card's press: the card gone; with no card, a refusal that changes nothing

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local ReinforceConfig = require(Shared.Config.Reinforce)
local JewelsConfig = require(Shared.Config.Jewels)
local Breaker = require(Shared.Rules.Breaker)
local Condenser = require(Shared.Rules.Condenser)
local Goals = require(Shared.Rules.Goals)

local Return = {}

Return.NoCard = "NoCard"

local EPSILON = 1e-6

export type Line = {
	Kind: string, -- "Battery" (a net gain), "Full" (it ended full and sold), "Stones", "Jewels", "Training", "Worker",
	-- "Workers" (the workers past the most lines, folded) or "Shards"
	Count: number, -- the kWh, the Credits sold, the stones, the jewels, the levels or the shards
	Grade: string?, -- a stone's grade
	Id: string?, -- the Voidkin the Training machine trained most, the worker, or the first worker folded
	Def: string?, -- the first shard that broke, or the first jewel's key ("Blue:1"), for its picture
	More: number?, -- the workers a "Workers" line folds
	First: boolean?, -- a "Workers" line with no worker's line before it: it folds them all
}

function Return.Open(data: Profile.Data)
	local base = data.Base
	if base.Away == nil then
		base.Away = { Charge = base.Charge, Sold = 0, Credits = 0, Stones = {}, Trained = {}, Worked = {}, Shards = {} }
	end
end

local function blank(): Profile.ReturnCard
	return { Kwh = 0, Full = false, Credits = 0, Stones = {}, Trained = {}, Worked = {}, Shards = {} }
end

function Return.Lines(card: Profile.ReturnCard?, room: number?): { Line }
	local lines: { Line } = {}
	if card == nil then
		return lines
	end
	if card.Full and card.Credits >= 1 then
		table.insert(lines, { Kind = "Full", Count = card.Credits })
	elseif card.Kwh >= BaseConfig.Return.LeastKwh then
		table.insert(lines, { Kind = "Battery", Count = card.Kwh })
	end
	for _, grade in ReinforceConfig.Grades do
		local count = card.Stones[grade] or 0
		if count > 0 then
			table.insert(lines, { Kind = "Stones", Count = count, Grade = grade })
		end
	end
	-- The jewels banked, one line: their count, the first in the lists' order (Config.Jewels.Colours, then the tier) its
	-- picture (TR66 #11).
	local keys, jewels = {}, 0
	for key, count in card.Jewels or {} do
		if count > 0 then
			table.insert(keys, key)
			jewels += count
		end
	end
	if jewels > 0 then
		local function rank(key: string): number
			local colour, tier = string.match(key, "^(%a+):(%d+)$")
			return (table.find(JewelsConfig.Colours, colour or "") or #JewelsConfig.Colours + 1) * 100 + (tonumber(tier) or 0)
		end
		table.sort(keys, function(a: string, b: string): boolean
			return rank(a) < rank(b)
		end)
		table.insert(lines, { Kind = "Jewels", Count = jewels, Def = keys[1] })
	end
	local most, levels = nil :: string?, 0
	for id, gained in card.Trained do
		if gained > levels or (gained == levels and most ~= nil and id < most) then
			most, levels = id, gained
		end
	end
	if most then
		table.insert(lines, { Kind = "Training", Count = levels, Id = most })
	end
	-- The workers who gained a level, the most first (research, 2026-11-25): up to Workers lines, the rest folded into
	-- one, their levels summed, the first of them its face. On a card held to `room` lines (a short phone: the HUD's
	-- room), they fold sooner, so the card fits; at the least, all of them in one line (its First set).
	type Gain = { Id: string, Count: number }
	local workers: { Gain } = {}
	for id, gained in card.Worked or {} do
		if gained >= 1 then
			table.insert(workers, { Id = id, Count = gained })
		end
	end
	table.sort(workers, function(a: Gain, b: Gain): boolean
		if a.Count ~= b.Count then
			return a.Count > b.Count
		end
		return a.Id < b.Id
	end)
	local after = if #card.Shards > 0 then 1 else 0
	local free = math.max(1, (room or math.huge) - #lines - after) -- lines the workers may take, one at the least
	local cap = BaseConfig.Return.Workers
	local single = if #workers <= cap and #workers <= free then #workers else math.max(0, math.min(cap, free - 1))
	for index, worker in workers do
		if index <= single then
			table.insert(lines, { Kind = "Worker", Count = worker.Count, Id = worker.Id })
		elseif index == single + 1 then
			table.insert(lines, { Kind = "Workers", Count = worker.Count, Id = worker.Id, More = 1, First = single == 0 })
		else
			local folded = lines[#lines]
			folded.Count += worker.Count
			folded.More = (folded.More or 0) + 1
		end
	end
	if #card.Shards > 0 then
		table.insert(lines, { Kind = "Shards", Count = #card.Shards, Def = card.Shards[1] })
	end
	return lines
end

function Return.Arrive(data: Profile.Data): Profile.ReturnCard?
	local base = data.Base
	local away = base.Away
	base.Away = nil
	local jewels: { [string]: number } = {}
	if Condenser.Awake(base.Level) then -- TR31: credited on arrival, the press only shows it
		local banked = 0
		for grade, held in base.Condenser.Tray do
			if held > 0 then
				data.Bag.Stones[grade] = (data.Bag.Stones[grade] or 0) + held
				banked += held
			end
		end
		base.Condenser.Tray = {}
		-- Its jewels too, as the tray's press takes them (Base.CollectTray; TR66 #11).
		for key, held in base.Condenser.Jewels or {} do
			if held > 0 then
				data.Bag.Jewels[key] = (data.Bag.Jewels[key] or 0) + held
				jewels[key] = held
				banked += held
			end
		end
		base.Condenser.Jewels = nil
		-- The arrival is the tray's collect, so today's "Collect the Condenser's tray" counts it as the press does
		-- (Base.CollectTray); an empty tray collects nothing, so a second arrival counts nothing.
		if banked > 0 then
			Goals.Note(data, "TrayCollected")
		end
	end
	if away == nil then
		return base.Card
	end
	local card = base.Card or blank()
	if next(jewels) then
		local onCard = card.Jewels or {}
		for key, count in jewels do
			onCard[key] = (onCard[key] or 0) + count
		end
		card.Jewels = onCard
	end
	card.Kwh += base.Charge - away.Charge
	card.Credits += away.Credits
	card.Full = base.Charge >= Breaker.Capacity(base) - EPSILON and (away.Sold > 0 or card.Full)
	for grade, count in away.Stones do
		card.Stones[grade] = (card.Stones[grade] or 0) + count
	end
	for id, levels in away.Trained do
		card.Trained[id] = (card.Trained[id] or 0) + levels
	end
	if away.Worked and next(away.Worked) then
		local worked = card.Worked or {}
		for id, levels in away.Worked do
			worked[id] = (worked[id] or 0) + levels
		end
		card.Worked = worked
	end
	for _, def in away.Shards do
		table.insert(card.Shards, def)
	end
	base.Card = if #Return.Lines(card) > 0 then card else nil
	return base.Card
end

function Return.Seen(data: Profile.Data, _args: any, _now: number): { [string]: any }
	if data.Base.Card == nil then
		return { Ok = false, Error = Return.NoCard }
	end
	data.Base.Card = nil
	return { Ok = true }
end

return Return
