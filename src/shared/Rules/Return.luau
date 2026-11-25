--!strict
-- Return (shared, pure): the base between runs (TR53, TR31 folded in; docs/test-requests.md, TR53). While the player
-- is away from the base, on a run in another place or offline, a record of what it does stays open on the save
-- (Base.Away), and every advance adds to it (Rules.Breaker). Back at the base, the record closes onto the return card
-- (Base.Card), which waits for its one press. The server credits everything as it happens or on arrival: the overflow's
-- Credits and the levels as the base advances, the Condenser's tray into the bag on arrival. The press only shows it.
--   Return.Open(data)               opens the record from the base as it stands; one already open stays
--   Return.Arrive(data)             back at the base: the tray into the bag, the record closed onto the card (merged with
--                                   one not yet seen); the card, or nil when nothing changed
--   Return.Lines(card)              the card's lines in AR55's order: the battery, each grade of stone, the Training
--                                   machine, the shards; empty for no card
--   Return.Seen(data, args, now)    the card's press: the card gone; with no card, a refusal that changes nothing

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local ReinforceConfig = require(Shared.Config.Reinforce)
local Breaker = require(Shared.Rules.Breaker)
local Condenser = require(Shared.Rules.Condenser)
local Goals = require(Shared.Rules.Goals)

local Return = {}

Return.NoCard = "NoCard"

local EPSILON = 1e-6

export type Line = {
	Kind: string, -- "Battery" (a net gain), "Full" (it ended full and sold), "Stones", "Training" or "Shards"
	Count: number, -- the kWh, the Credits sold, the stones, the levels or the shards
	Grade: string?, -- a stone's grade
	Id: string?, -- the Voidkin the Training machine trained most
	Def: string?, -- the first shard that broke, for its picture
}

function Return.Open(data: Profile.Data)
	local base = data.Base
	if base.Away == nil then
		base.Away = { Charge = base.Charge, Sold = 0, Credits = 0, Stones = {}, Trained = {}, Shards = {} }
	end
end

local function blank(): Profile.ReturnCard
	return { Kwh = 0, Full = false, Credits = 0, Stones = {}, Trained = {}, Shards = {} }
end

function Return.Lines(card: Profile.ReturnCard?): { Line }
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
	local most, levels = nil :: string?, 0
	for id, gained in card.Trained do
		if gained > levels or (gained == levels and most ~= nil and id < most) then
			most, levels = id, gained
		end
	end
	if most then
		table.insert(lines, { Kind = "Training", Count = levels, Id = most })
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
	if Condenser.Awake(base.Level) then -- TR31: credited on arrival, the press only shows it
		local banked = 0
		for grade, held in base.Condenser.Tray do
			if held > 0 then
				data.Bag.Stones[grade] = (data.Bag.Stones[grade] or 0) + held
				banked += held
			end
		end
		base.Condenser.Tray = {}
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
	card.Kwh += base.Charge - away.Charge
	card.Credits += away.Credits
	card.Full = base.Charge >= Breaker.Capacity(base) - EPSILON and (away.Sold > 0 or card.Full)
	for grade, count in away.Stones do
		card.Stones[grade] = (card.Stones[grade] or 0) + count
	end
	for id, levels in away.Trained do
		card.Trained[id] = (card.Trained[id] or 0) + levels
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
