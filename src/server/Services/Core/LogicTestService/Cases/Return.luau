--!strict
-- Return cases (pure): the base between runs (TR53, TR31 in; Rules.Return). Away from the base the record adds up every
-- advance; back at the base it closes onto one card, the tray credited; a card shows each change once, and a repeat
-- shows nothing; a net loss shows no battery line; full and sold reads Full with its Credits.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local Base = require(Shared.Rules.Base)
local Return = require(Shared.Rules.Return)
local Collection = require(Shared.Rules.Collection)
local GrowthConfig = require(Shared.Config.Growth)
local CondenserConfig = require(Shared.Config.Condenser)
local DataConfig = require(Shared.Config.Data)
local JewelsConfig = require(Shared.Config.Jewels)

local T0 = 1_800_000_000
local HOUR = 3600
local STANDARD = "lanternrow_standard"
local LOW = CondenserConfig.Makes

-- A base with its Condenser awake and Watt at work, its kW held (the last level), the battery at `charge`.
local function fresh(charge: number?): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Base.Level = CondenserConfig.Wakes
	data.Base.Charge = charge or 0
	local watt = Collection.Uncover(data, "watt", T0).Id
	data.Voidkin[watt].Level = GrowthConfig.MaxLevel
	data.Base.Bays[1].Worker = watt
	Breaker.Advance(data, T0)
	return data
end

local function kinds(lines: { Return.Line }): string
	local words = {}
	for _, line in lines do
		table.insert(words, line.Kind .. (if line.Grade then `:{line.Grade}` else ""))
	end
	return table.concat(words, ",")
end

local function find(lines: { Return.Line }, kind: string): Return.Line?
	for _, line in lines do
		if line.Kind == kind then
			return line
		end
	end
	return nil
end

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-6)
end

return {
	{
		Name = "Return (TR53): away, every advance adds up; back at the base, one card with each change, the tray credited; seen once, a repeat shows nothing",
		Run = function(t: any)
			local data = fresh(0)
			t.Check("at the base, no record", data.Base.Away == nil)
			Breaker.Advance(data, T0 + 60)
			t.Check("an advance at the base opens none", data.Base.Away == nil)
			Return.Open(data)
			local charge = data.Base.Charge
			t.Check("opened from the base as it stands", data.Base.Away ~= nil and (data.Base.Away :: Profile.Away).Charge == charge)
			Return.Open(data)
			t.Check("opening again keeps the first", (data.Base.Away :: Profile.Away).Charge == charge)
			-- a run's advances in the other place, then the join's
			for i = 1, 4 do
				Breaker.Advance(data, T0 + 60 + i * HOUR / 2) -- two hours: about 71 kWh, short of the battery's cap
			end
			local away = data.Base.Away :: Profile.Away
			local made = away.Stones[LOW] or 0
			t.Check("the Condenser's stones counted", made > 0, tostring(made))
			local tray = data.Base.Condenser.Tray[LOW] or 0
			local bag = data.Bag.Stones[LOW] or 0
			data.Goals.Days = { { Day = 20780, Picks = { "CondenserTray" }, Have = { 0 }, Claimed = { false } } }
			local card = Return.Arrive(data)
			t.Check("back at the base: the record closed onto the card", data.Base.Away == nil and card ~= nil and data.Base.Card == card)
			t.Check("the tray credited into the bag", (data.Bag.Stones[LOW] or 0) == bag + tray and next(data.Base.Condenser.Tray) == nil)
			t.Check("today's \"Collect the Condenser's tray\" counts the arrival's collect", tray > 0 and data.Goals.Days[1].Have[1] == 1,
				`{tray} in the tray, the goal at {data.Goals.Days[1].Have[1]}`)
			local lines = Return.Lines(card)
			t.Equal("the battery's gain, then the stones", kinds(lines), "Battery,Stones:Low")
			t.Check("the battery's line is its net gain", near(lines[1].Count, data.Base.Charge - charge), `{lines[1].Count}`)
			t.Equal("the stones made away", lines[2].Count, made)
			t.Check("a second arrival adds nothing: the same card waits", Return.Arrive(data) == card and #Return.Lines(data.Base.Card) == 2)
			local seen, changed = Transaction.Run(data, "op-seen", function(draft: Profile.Data): any
				return Base.Actions.ReturnSeen(draft, nil, T0, 0.5)
			end, DataConfig.OpsKept)
			t.Check("the press: the card gone", seen.Ok == true and changed and data.Base.Card == nil)
			local again, twice = Transaction.Run(data, "op-seen", function(draft: Profile.Data): any
				return Base.Actions.ReturnSeen(draft, nil, T0, 0.5)
			end, DataConfig.OpsKept)
			t.Check("the same op id: its first answer, nothing changed", again.Ok == true and not twice)
			t.Equal("a new press with no card: refused", Return.Seen(data, nil, T0).Error, Return.NoCard)
			t.Check("and the next arrival shows nothing", Return.Arrive(data) == nil and data.Base.Card == nil)
			t.Check("nothing changed away: no card", (function(): boolean
				Return.Open(data)
				return Return.Arrive(data) == nil
			end)())
			t.Equal("the save holds nothing it would lose", #Saveable.Problems(data, "profile"), 0)
		end,
	},
	{
		Name = "Return (TR66 #11): arrival banks the Condenser's jewels with its stones, the tray emptied, and the card names them after the stones; jewels alone make a card",
		Run = function(t: any)
			local first, second = `{JewelsConfig.Colours[1]}:1`, `{JewelsConfig.Colours[2]}:1`
			local data = fresh(0)
			Return.Open(data)
			for i = 1, 2 do
				Breaker.Advance(data, T0 + i * HOUR / 2)
			end
			data.Base.Condenser.Jewels = { [first] = 2, [second] = 1 }
			local had = data.Bag.Jewels[first] or 0
			local card = Return.Arrive(data)
			t.Check("the jewels into the bag", (data.Bag.Jewels[first] or 0) == had + 2 and (data.Bag.Jewels[second] or 0) >= 1)
			t.Check("the Condenser's jewels taken from its tray", data.Base.Condenser.Jewels == nil)
			local lines = Return.Lines(card)
			local line = find(lines, "Jewels")
			t.Check("the card names them: their count, the first key its picture", line ~= nil and line.Count == 3 and line.Def == first,
				if line then `{line.Count} {line.Def}` else kinds(lines))
			local stonesAt, jewelsAt = 0, 0
			for index, each in lines do
				stonesAt = if each.Kind == "Stones" and stonesAt == 0 then index else stonesAt
				jewelsAt = if each.Kind == "Jewels" then index else jewelsAt
			end
			t.Check("after the stones", stonesAt > 0 and jewelsAt > stonesAt, kinds(lines))
			t.Check("the tray's press after it has nothing to take", Base.CollectTray(data, nil, T0 + HOUR).Ok == false)
			local only = fresh(0)
			Return.Open(only)
			only.Base.Condenser.Jewels = { [first] = 1 }
			local alone = Return.Arrive(only)
			t.Equal("a jewel alone makes a card", kinds(Return.Lines(alone)), "Jewels")
			t.Equal("the save holds nothing it would lose", #Saveable.Problems(data, "profile"), 0)
		end,
	},
	{
		Name = "Return (TR53, TR31): a net loss shows no battery line; a shard broken shows; full and sold reads Full with the Credits it sold",
		Run = function(t: any)
			-- the bay empty, the battery charged, a shard breaking: the battery spends, the shard breaks
			local data = fresh(Breaker.Capacity(Profile.Template().Base))
			data.Base.Bays[1].Worker = ""
			data.Base.Charge = Breaker.Capacity(data.Base)
			Breaker.AddToLine(data, { Def = STANDARD, Luck = 0, Done = 0 })
			Return.Open(data)
			Breaker.Advance(data, T0 + HOUR)
			local card = Return.Arrive(data)
			local lines = Return.Lines(card)
			t.Check("the battery spent", card ~= nil and card.Kwh < 0, if card then `{card.Kwh}` else "no card")
			t.Check("no battery line", find(lines, "Battery") == nil and find(lines, "Full") == nil, kinds(lines))
			local shards = find(lines, "Shards")
			t.Check("one shard, its picture its own", shards ~= nil and shards.Count == 1 and shards.Def == STANDARD, kinds(lines))
			Return.Seen(data, nil, T0)
			-- full and sold
			local full = fresh(0)
			full.Base.Charge = Breaker.Capacity(full.Base) - 0.5
			Return.Open(full)
			Breaker.Advance(full, T0 + 10 * HOUR)
			local sold = Return.Arrive(full)
			local first = Return.Lines(sold)[1]
			t.Check("full and sold: Full, its Credits the count", sold ~= nil and sold.Full and first.Kind == "Full" and first.Count == sold.Credits and sold.Credits >= 1, if sold then `{first.Kind} {first.Count} {sold.Credits}` else "no card")
		end,
	},
	{
		Name = "Return (TR53): the Training machine's levels name the Voidkin trained most; two returns not yet seen merge onto one card",
		Run = function(t: any)
			local data = fresh(0)
			local rook = Collection.Uncover(data, "rook", T0).Id
			data.Roles.Lead = rook
			Return.Open(data)
			Breaker.Advance(data, T0 + HOUR / 2, true) -- offline: the lead trains
			local card = Return.Arrive(data) :: Profile.ReturnCard
			local lines = Return.Lines(card)
			local training = lines[#lines]
			t.Check("its levels and its Voidkin", training and training.Kind == "Training" and training.Id == rook and training.Count == card.Trained[rook] and training.Count >= 1, kinds(lines))
			local kwh = card.Kwh
			Return.Open(data)
			Breaker.Advance(data, T0 + HOUR)
			Breaker.AddToLine(data, { Def = STANDARD, Luck = 0, Done = 0 })
			Breaker.Advance(data, T0 + 2 * HOUR)
			local merged = Return.Arrive(data) :: Profile.ReturnCard
			t.Check("merged: the same card, the battery's gain summed", merged == card and merged.Kwh > kwh, `{merged.Kwh} against {kwh}`)
			t.Equal("the shard joins it", #merged.Shards, 1)
			t.Equal("the lines in AR55's order", kinds(Return.Lines(merged)), "Battery,Stones:Low,Training,Shards")
		end,
	},
	{
		Name = "Return (research, 2026-11-25): a worker's levels away on the card, after the Training machine's; the most first, three lines, the rest folded into one",
		Run = function(t: any)
			local data = fresh(0)
			local watt = data.Base.Bays[1].Worker
			data.Voidkin[watt].Level = 1
			data.Voidkin[watt].Xp = 0
			local rook = Collection.Uncover(data, "rook", T0).Id
			data.Roles.Lead = rook
			Return.Open(data)
			Breaker.Advance(data, T0 + 2 * HOUR, true) -- offline: Watt works, Rook trains
			Breaker.AddToLine(data, { Def = STANDARD, Luck = 0, Done = 0 })
			Breaker.Advance(data, T0 + 4 * HOUR, true)
			local gained = data.Voidkin[watt].Level - 1
			local card = Return.Arrive(data) :: Profile.ReturnCard
			t.Check("Watt gained levels at work", gained >= 1, tostring(gained))
			t.Equal("the card holds them", card and card.Worked and card.Worked[watt], gained)
			local lines = Return.Lines(card)
			local worker = find(lines, "Worker")
			t.Check("his line: his levels, his face", worker ~= nil and worker.Id == watt and worker.Count == gained, kinds(lines))
			t.Equal("after the Training machine's, before the shards", kinds(lines), "Battery,Stones:Low,Training,Worker,Shards")
			-- five workers: three lines, the most first (a tie by id), then the other two folded, their levels summed
			local five: Profile.ReturnCard = { Kwh = 0, Full = false, Credits = 0, Stones = {}, Trained = {}, Shards = {},
				Worked = { a = 1, b = 5, c = 3, d = 3, e = 2, f = 0 } }
			local shown = Return.Lines(five)
			local words = {}
			for _, line in shown do
				table.insert(words, `{line.Kind}:{line.Id}:{line.Count}:{line.More or ""}`)
			end
			t.Equal("three lines, then the rest in one; none for a worker without a level", table.concat(words, ","),
				"Worker:b:5:,Worker:c:3:,Worker:d:3:,Workers:e:3:2")
			five.Worked = { a = 2, b = 1, c = 4, d = 1 }
			local four = Return.Lines(five)
			t.Check("four: the fourth folds alone", #four == 4 and four[4].Kind == "Workers" and four[4].More == 1 and four[4].Count == 1, kinds(four))
			-- held to the room the HUD gives (a short phone): the workers fold sooner, their levels' total kept
			local full: Profile.ReturnCard = { Kwh = 12, Full = false, Credits = 0, Stones = { Low = 6, Mid = 1 }, Trained = { r = 2 },
				Shards = { STANDARD }, Worked = { a = 5, b = 3, c = 3, d = 1 } }
			local function block(room: number?): string
				local out = {}
				for _, line in Return.Lines(full, room) do
					if line.Kind == "Worker" or line.Kind == "Workers" then
						table.insert(out, `{line.Kind}:{line.Count}{if line.More then `x{line.More}` else ""}{if line.First then "!" else ""}`)
					end
				end
				return table.concat(out, ",")
			end
			t.Equal("room to spare: three lines and the fourth folded", block(nil), "Worker:5,Worker:3,Worker:3,Workers:1x1")
			t.Equal("room for ten: the same", block(10), "Worker:5,Worker:3,Worker:3,Workers:1x1")
			t.Equal("room for seven: one line, the other three folded", block(7), "Worker:5,Workers:7x3")
			t.Equal("room for six: all four in one line", block(6), "Workers:12x4!")
			t.Equal("room for six: six lines in all", #Return.Lines(full, 6), 6)
			t.Equal("no room at all: still one line, never none", block(2), "Workers:12x4!")
			full.Worked = { a = 5 }
			t.Equal("one worker in a room for six: his own line", block(6), "Worker:5")
			five.Worked = nil
			t.Equal("a card from before the workers' lines: none, and no error", #Return.Lines(five), 0)
			t.Equal("the save holds nothing it would lose", #Saveable.Problems(data, "profile"), 0)
		end,
	},
}
