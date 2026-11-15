--!strict
-- Breaker cases (pure): a base over time, a power plant (TR18). Full power, shortage (slowed in proportion, never
-- stopped), overflow past the cap, away and back, a shard taken out mid-work, the line fed shortest first, a clock stepping
-- back, many small advances landing where one large one does; the split (Auto and shares), the floor, the Training
-- machine on the base's clock, voltage's price and the migration to kWh. Expected values come from Config wherever they
-- can.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Training = require(Shared.Rules.Training)
local Collection = require(Shared.Rules.Collection)
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)

local T0 = 1_800_000_000
local STANDARD = "lanternrow_standard"

local function fresh(charge: number?): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Base.Charge = charge or 0
	Breaker.Advance(data, T0) -- the first advance only sets the stamp
	return data
end

local function work(def: string, done: number?): Profile.ShardWork
	return { Def = def, Luck = 0, Done = done or 0 }
end

-- kWh a second from kW.
local function perSecond(kw: number): number
	return kw / 3600
end

-- Watt in bay 1: aptitude 3 at level 1.
local function withWatt(data: Profile.Data): string
	local id = Collection.Uncover(data, "watt", T0).Id
	data.Base.Bays[1].Worker = id
	return id
end

-- Sets a Config value for one case and puts it back, even when the case errors.
local function withConfig(node: { [string]: any }, key: string, value: any, run: () -> ())
	local old = node[key]
	node[key] = value
	local ok, err = pcall(run)
	node[key] = old
	if not ok then
		error(err, 0)
	end
end

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-6)
end

return {
	{
		Name = "Breaker: the first advance sets the stamp and nothing else",
		Run = function(t: any)
			local data = Profile.Template()
			Migrations.Run(data)
			local summary = Breaker.Advance(data, T0)
			t.Equal("stamp", data.Base.Stamp, T0)
			t.Equal("nothing stepped", summary.Steps, 0)
		end,
	},
	{
		Name = "Breaker: at full power a shard takes its seconds and its kWh",
		Run = function(t: any)
			local seconds, energy = Breaker.Cost(STANDARD)
			local data = fresh(energy)
			Breaker.AddToLine(data, work(STANDARD))
			t.Check("it went straight into a chamber", data.Base.Chambers[1].Work ~= nil and #data.Base.Line == 0)
			Breaker.Advance(data, T0 + (seconds :: number) - 1)
			t.Equal("not yet", #data.Base.Ready, 0)
			Breaker.Advance(data, T0 + (seconds :: number))
			t.Equal("ready", #data.Base.Ready, 1)
			t.Check("the chamber is free", data.Base.Chambers[1].Work == nil)
			t.Check("the battery paid it", near(data.Base.Charge, 0))
		end,
	},
	{
		Name = "Breaker: with no power it slows to its floor, never stops",
		Run = function(t: any)
			local seconds = Breaker.Cost(STANDARD) :: number
			local data = fresh(0)
			Breaker.AddToLine(data, work(STANDARD))
			local slowest = seconds / BaseConfig.Power.MinSpeed
			Breaker.Advance(data, T0 + slowest - 1)
			t.Equal("not yet", #data.Base.Ready, 0)
			Breaker.Advance(data, T0 + slowest + 1)
			t.Equal("ready at the floor's pace", #data.Base.Ready, 1)
		end,
	},
	{
		Name = "Breaker: short of power it slows in proportion",
		Run = function(t: any)
			withConfig(BaseConfig.Power :: any, "MinSpeed", 0, function()
				local data = fresh(0)
				withWatt(data)
				Breaker.AddToLine(data, work(STANDARD))
				Breaker.AddToLine(data, work(STANDARD)) -- two chambers ask more than Watt generates
				local share = Power.Generation(data) / (2 * (Power.Rating(STANDARD) :: number))
				t.Check("short", share < 1, `{share}`)
				Breaker.Advance(data, T0 + 10)
				local done = (data.Base.Chambers[1].Work :: Profile.ShardWork).Done
				t.Check("work at the workers' share", near(done, 10 * share), `done {done}, share {share}`)
				t.Check("nothing stored", near(data.Base.Charge, 0))
			end)
		end,
	},
	{
		Name = "Breaker: the battery fills to its cap, then overflow pays Credits",
		Run = function(t: any)
			local capacity = BaseConfig.Battery.Capacity
			local data = fresh(0)
			withWatt(data)
			local rate = perSecond(Power.Generation(data))
			local toFull = capacity / rate
			local extra = 1000
			local summary = Breaker.Advance(data, T0 + toFull + extra)
			t.Check("full", near(data.Base.Charge, capacity))
			t.Check("the overflow", near(summary.Overflow, rate * extra, 1e-3), `{summary.Overflow}`)
			local paid = rate * extra * BaseConfig.Battery.CreditsPerKwh
			t.Equal("whole Credits paid", data.Currency.Credits, math.floor(paid))
			t.Check("the rest carried", near(data.Base.Spill, paid - math.floor(paid), 1e-3), `{data.Base.Spill}`)
		end,
	},
	{
		Name = "Breaker: away, workers stop after the away hours",
		Run = function(t: any)
			local data = fresh(0)
			withWatt(data)
			local rate = perSecond(Power.Generation(data))
			local hours = BaseConfig.Battery.AwayHours
			local summary = Breaker.Advance(data, T0 + (hours + 8) * 3600, true)
			local made = math.min(rate * hours * 3600, BaseConfig.Battery.Capacity)
			t.Check("made only the away hours", near(summary.Made, rate * hours * 3600, 1e-3), `{summary.Made}`)
			t.Check("stored", near(data.Base.Charge, made, 1e-3))
		end,
	},
	{
		Name = "Breaker: away and back, the line breaks down and the battery runs out",
		Run = function(t: any)
			local seconds, energy = Breaker.Cost(STANDARD)
			local data = fresh(2 * (energy :: number))
			for _ = 1, 4 do
				Breaker.AddToLine(data, work(STANDARD))
			end
			t.Equal("two breaking, two waiting", #data.Base.Line, 2)
			Breaker.Advance(data, T0 + 12 * 3600, true)
			t.Equal("all four ready", #data.Base.Ready, 4)
			t.Equal("the battery spent", data.Base.Charge, 0)
			t.Equal("the stamp moved", data.Base.Stamp, T0 + 12 * 3600)
			local problems = Saveable.Problems(data, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
			t.Check("seconds known", seconds ~= nil)
		end,
	},
	{
		Name = "Breaker: a shard taken out keeps its work",
		Run = function(t: any)
			local data = fresh(1000)
			data.Base.Chambers = { {} } -- one chamber, so the line has to wait
			Breaker.AddToLine(data, work(STANDARD))
			Breaker.Advance(data, T0 + 10)
			Breaker.AddToLine(data, work("named_watt"))
			t.Check("taken out", Breaker.TakeOut(data, 1))
			local inChamber = data.Base.Chambers[1].Work :: Profile.ShardWork
			t.Equal("the waiting one went in", inChamber.Def, "named_watt")
			t.Equal("the taken one waits at the back", data.Base.Line[#data.Base.Line].Def, STANDARD)
			t.Check("with its work", near(data.Base.Line[#data.Base.Line].Done, 10))
			t.Check("a missing chamber can't", not Breaker.TakeOut(data, 9))
			Breaker.TakeOut(data, 1)
			local back = data.Base.Chambers[1].Work :: Profile.ShardWork
			t.Check("taking Watt out brings it back, work kept", back.Def == STANDARD and near(back.Done, 10))
			t.Equal("Watt waits", data.Base.Line[1].Def, "named_watt")
		end,
	},
	{
		Name = "Breaker: a lone shard taken out goes straight back in",
		Run = function(t: any)
			local data = fresh(1000)
			data.Base.Chambers = { {} }
			Breaker.AddToLine(data, work(STANDARD, 12))
			t.Check("taken out", Breaker.TakeOut(data, 1))
			local again = data.Base.Chambers[1].Work :: Profile.ShardWork
			t.Check("back in, work kept", again ~= nil and near(again.Done, 12))
			t.Equal("nothing waiting", #data.Base.Line, 0)
			data.Base.Chambers[1].Work = nil
			t.Check("an empty chamber can't", not Breaker.TakeOut(data, 1))
		end,
	},
	{
		Name = "Breaker: the line is fed shortest first",
		Run = function(t: any)
			local data = fresh(1000)
			data.Base.Chambers = { {} }
			Breaker.AddToLine(data, work(STANDARD)) -- takes the chamber
			Breaker.AddToLine(data, work(STANDARD))
			Breaker.AddToLine(data, work("starter_rook")) -- shorter: jumps ahead
			Breaker.AddToLine(data, work(STANDARD, 25)) -- nearly done: shortest of all
			t.Equal("first", data.Base.Line[1].Def, STANDARD)
			t.Check("first is the nearly done one", near(data.Base.Line[1].Done, 25))
			t.Equal("then the starter", data.Base.Line[2].Def, "starter_rook")
			t.Equal("then the fresh one", data.Base.Line[3].Def, STANDARD)
		end,
	},
	{
		Name = "Breaker: a clock stepping back changes nothing",
		Run = function(t: any)
			local data = fresh(100)
			Breaker.AddToLine(data, work(STANDARD))
			local before = Profile.DeepCopy(data)
			Breaker.Advance(data, T0 - 60)
			t.Equal("stamp kept", data.Base.Stamp, T0)
			t.Check("work kept", near((data.Base.Chambers[1].Work :: Profile.ShardWork).Done, before.Base.Chambers[1].Work.Done))
		end,
	},
	{
		Name = "Breaker: many small advances land where one large one does",
		Run = function(t: any)
			local function build(): Profile.Data
				local data = fresh(30)
				withWatt(data)
				for _ = 1, 5 do
					Breaker.AddToLine(data, work(STANDARD))
				end
				return data
			end
			local once, steps = build(), build()
			local span = 900
			Breaker.Advance(once, T0 + span)
			for second = 1, span do
				Breaker.Advance(steps, T0 + second)
			end
			t.Equal("as many ready", #steps.Base.Ready, #once.Base.Ready)
			t.Check("the same battery", near(steps.Base.Charge, once.Base.Charge, 1e-6), `{steps.Base.Charge} against {once.Base.Charge}`)
			local a, b = steps.Base.Chambers[1].Work, once.Base.Chambers[1].Work
			t.Check("the same work in chamber 1", (a == nil) == (b == nil) and (a == nil or near(a.Done, (b :: any).Done, 1e-3)))
		end,
	},
	{
		Name = "Breaker: TR18, a starter draws its chamber's rating like any shard, and the first battery covers it",
		Run = function(t: any)
			local seconds, kwh = Breaker.Cost("starter_rook")
			t.Check("its kWh is its chamber's rating over its seconds", near(kwh :: number, (Power.Rating("starter_rook") :: number) * (seconds :: number) / 3600))
			local data = Profile.Template()
			Migrations.Run(data)
			t.Check("a new battery holds more than it", data.Base.Charge >= (kwh :: number), `{data.Base.Charge}`)
			Breaker.Advance(data, T0)
			Breaker.AddToLine(data, work("starter_rook"))
			Breaker.Advance(data, T0 + (seconds :: number))
			t.Equal("ready at full speed", #data.Base.Ready, 1)
			t.Check("the battery paid it", near(data.Base.Charge, BaseConfig.Start.Charge - (kwh :: number)))
		end,
	},
	{
		Name = "Breaker: the rates a screen shows are the ones an advance runs at, and reading them writes nothing",
		Run = function(t: any)
			local seconds = Breaker.Cost(STANDARD) :: number
			local data = fresh(0)
			local id = withWatt(data)
			local made = Power.Output(data.Voidkin[id])
			t.Check("Watt's output is the bay formula", near(made, 3 * BaseConfig.Bays.KwPerAptitude))
			t.Check("generation is the workers' sum", near(Power.Generation(data), made))
			local idle = Breaker.Rates(data)
			t.Check("idle: all of it to the battery", idle.Speed == 1 and near(idle.NetKw, made) and not idle.Busy and idle.Demand == 0)
			Breaker.AddToLine(data, work(STANDARD))
			Breaker.AddToLine(data, work(STANDARD))
			local before = (data.Base.Chambers[1].Work :: any).Done
			local short = Breaker.Rates(data)
			local demand = 2 * (Power.Rating(STANDARD) :: number)
			t.Check("short on an empty battery: in proportion, nothing stored", short.Busy and near(short.Speed, math.max(BaseConfig.Power.MinSpeed, made / demand)) and short.NetKw == 0 and near(short.Demand, demand))
			t.Equal("reading changed no work", (data.Base.Chambers[1].Work :: any).Done, before)
			t.Equal("left is the whole shard", Breaker.Left(data.Base.Chambers[1].Work :: any), seconds)
			Breaker.Advance(data, T0 + 10)
			local done = (data.Base.Chambers[1].Work :: any).Done
			t.Check("an advance runs at that speed", near(done, 10 * short.Speed, 1e-3), `{done} against {10 * short.Speed}`)
			t.Check("left falls by the work done", near(Breaker.Left(data.Base.Chambers[1].Work :: any), seconds - done))
			data.Base.Charge = 5
			local charged = Breaker.Rates(data)
			t.Check("with charge: full speed, the battery pays the rest", charged.Speed == 1 and near(charged.NetKw, made - demand))
		end,
	},
	{
		Name = "Breaker: TR18, a shard's kWh is derived from its chamber's rating, and a ground's factor scales the rating",
		Run = function(t: any)
			local seconds, kwh = Breaker.Cost(STANDARD)
			t.Check("a Standard is 30 s and 0.125 kWh at 15 kW", seconds == 30 and near(kwh :: number, BaseConfig.Breaker.Kw * 30 / 3600), `{seconds} s, {kwh} kWh`)
			withConfig(ShardConfig.RegionFactor :: any, "lanternrow", 1.5, function()
				t.Check("the factor scales the rating", near(Power.Rating(STANDARD) :: number, BaseConfig.Breaker.Kw * 1.5))
			end)
			t.Check("an unknown shard has no cost", Breaker.Cost("nope") == nil and Power.Rating("nope") == nil)
		end,
	},
	{
		Name = "Breaker: TR18, Auto tops every machine up from the battery, and shares the generation by demand once it's empty",
		Run = function(t: any)
			local data = fresh(1)
			withWatt(data)
			data.Training.Trainee = Collection.Uncover(data, "rook", T0).Id
			Breaker.AddToLine(data, work(STANDARD))
			Breaker.AddToLine(data, work(STANDARD))
			local generation = Power.Generation(data)
			local ask = 2 * (Power.Rating(STANDARD) :: number) + BaseConfig.Training.Kw
			local full = Breaker.Rates(data)
			t.Check("charged: all at full, the battery covers the rest", full.Flow.Speed.Breaker == 1 and full.Flow.Speed.Training == 1 and near(full.NetKw, generation - ask), `{full.NetKw}`)
			data.Base.Charge = 0
			local empty = Breaker.Rates(data)
			local share = generation / ask
			t.Check("empty: each at the generation's share of its demand", near(empty.Flow.Speed.Breaker, share) and near(empty.Flow.Speed.Training, share) and empty.NetKw == 0, `{empty.Flow.Speed.Breaker}, {share}`)
			t.Check("drawing all of the generation", near(empty.Flow.Draw.Breaker + empty.Flow.Draw.Training, generation))
		end,
	},
	{
		Name = "Breaker: TR18, a split runs each machine at its share over its rating, never draws the battery, and what isn't used charges it",
		Run = function(t: any)
			local data = fresh(10)
			withWatt(data)
			data.Training.Trainee = Collection.Uncover(data, "rook", T0).Id
			Breaker.AddToLine(data, work(STANDARD))
			Breaker.AddToLine(data, work(STANDARD))
			data.Base.Power.Auto = false
			data.Base.Power.Shares = { Breaker = 0.5, Training = 0.2 }
			local generation = Power.Generation(data)
			local breakerAsks = 2 * (Power.Rating(STANDARD) :: number)
			local rates = Breaker.Rates(data)
			local floor = BaseConfig.Power.MinSpeed
			t.Check("the Breaker at its share over its rating", near(rates.Flow.Speed.Breaker, math.max(floor, 0.5 * generation / breakerAsks)), `{rates.Flow.Speed.Breaker}`)
			t.Check("the Training machine at its share over its rating", near(rates.Flow.Speed.Training, math.max(floor, math.min(1, 0.2 * generation / BaseConfig.Training.Kw))), `{rates.Flow.Speed.Training}`)
			local used = rates.Flow.Draw.Breaker + rates.Flow.Draw.Training
			t.Check("the rest charges the battery, though it holds charge", near(rates.NetKw, generation - used) and rates.NetKw >= 0, `{rates.NetKw}`)
			data.Base.Power.Shares = { Breaker = 1 }
			data.Base.Chambers[2].Work = nil
			local one = Breaker.Rates(data)
			t.Check("a share the machine can't use charges the battery", one.Flow.Speed.Breaker == 1 and near(one.NetKw, generation - (Power.Rating(STANDARD) :: number)), `{one.NetKw}`)
			t.Check("a machine with no share runs at the floor", near(one.Flow.Speed.Training, floor))
			data.Base.Power.Shares = { Breaker = 0.9, Training = 0.9 }
			local over = Breaker.Rates(data)
			t.Check("shares over the whole are scaled back to it", over.NetKw >= 0 and over.Flow.Draw.Breaker + over.Flow.Draw.Training <= generation + 1e-9)
		end,
	},
	{
		Name = "Breaker: TR18, a split a client asks for is checked: a machine's, 0 or more, never over the whole",
		Run = function(t: any)
			local shares, code = Power.Shares({ Breaker = 0.6, Training = 0.4 })
			t.Check("the whole is fine", shares ~= nil and code == nil and (shares :: any).Breaker == 0.6)
			t.Equal("over the whole", select(2, Power.Shares({ Breaker = 0.6, Training = 0.5 })), "Over")
			for label, asked in { negative = { Breaker = -0.1 }, nan = { Breaker = 0 / 0 }, huge = { Breaker = math.huge }, unknown = { Forge = 0.1 }, word = { Breaker = "half" }, list = { 0.5 } } :: { [string]: any } do
				t.Equal(label, select(2, Power.Shares(asked)), "BadArgs")
			end
			t.Equal("not a table", select(2, Power.Shares("all")), "BadArgs")
			t.Check("nothing routed is a split too", (Power.Shares({})) ~= nil)
		end,
	},
	{
		Name = "Breaker: TR18, the Training machine trains on the base's clock at its speed, opens the Power screen, and never a worker",
		Run = function(t: any)
			local data = fresh(0)
			local id = Collection.Uncover(data, "rook", T0).Id
			t.Check("the Power screen starts shut", not data.Base.Power.Open)
			data.Training.Trainee = id
			local copy = Profile.DeepCopy(data.Voidkin[id])
			local span = 4000
			local summary = Breaker.Advance(data, T0 + span)
			local levels = Training.Gain(copy, span * BaseConfig.Power.MinSpeed) -- no generation and no charge: the floor
			local now = data.Voidkin[id]
			t.Check("it trained at the floor's pace", summary.Trained == id and summary.Levels == levels and now.Level == copy.Level and now.Xp == copy.Xp, `{now.Level}/{now.Xp} against {copy.Level}/{copy.Xp}`)
			t.Check("it banked what wasn't a whole point", data.Training.Banked >= 0 and data.Training.Banked * Training.Rate() < 1 + 1e-6)
			t.Check("the Power screen opened", data.Base.Power.Open)
			data.Base.Bays[1].Worker = id
			local before = now.Xp
			local again = Breaker.Advance(data, T0 + 2 * span)
			t.Check("a worker never trains", again.Trained == nil and now.Xp == before)
		end,
	},
	{
		Name = "Breaker: TR18, away the lead trains, whoever was on the machine",
		Run = function(t: any)
			local data = fresh(0)
			local lead = Collection.Uncover(data, "rook", T0).Id
			data.Roles.Lead = lead
			data.Training.Trainee = ""
			local summary = Breaker.Advance(data, T0 + 3600, true)
			t.Equal("the lead trained", summary.Trained, lead)
			local online = Breaker.Advance(data, T0 + 7200)
			t.Check("online, nobody on it trains nobody", online.Trained == nil)
		end,
	},
	{
		Name = "Breaker: TR18, voltage's price follows the time it saves, rounded up to a whole kWh, and is never offered under a minute",
		Run = function(t: any)
			local fresh30 = work(STANDARD)
			t.Check("a Standard's 30 s: never offered", Power.Voltage(fresh30, 1) == nil and Power.Voltage(fresh30, 2) == nil)
			t.Check("so a Standard's kind is never offered: the Breaker shows no voltage", not Power.Offered(STANDARD))
			t.Check("nor an unknown shard's", not Power.Offered("nope"))
			-- Drum Court's Enriched, as TR18 states it: 900 s at a factor of 1.5, Low 4 kWh, High 8.
			withConfig(ShardConfig.Grades.Standard :: any, "BreakSeconds", 900, function()
				withConfig(ShardConfig.RegionFactor :: any, "lanternrow", 1.5, function()
					local low, lowSaved = Power.Voltage(work(STANDARD), 1)
					local high, highSaved = Power.Voltage(work(STANDARD), 2)
					t.Check("Low halves its time left: 4 kWh", low == 4 and near(lowSaved, 450), `{low}, {lowSaved}`)
					t.Check("High breaks it at once: 8 kWh", high == 8 and near(highSaved, 900), `{high}, {highSaved}`)
					local late, lateSaved = Power.Voltage(work(STANDARD, 820), 2)
					t.Check("from what it has left: 80 s, 1 kWh", late == 1 and near(lateSaved, 80), `{late}, {lateSaved}`)
					t.Check("Low on 80 s left saves 40: not offered", Power.Voltage(work(STANDARD, 820), 1) == nil)
					t.Check("at 900 s its kind is offered, nearly done or not", Power.Offered(STANDARD))
				end)
			end)
			t.Check("an unknown level or shard", Power.Voltage(fresh30, 3) == nil and Power.Voltage(work("nope"), 1) == nil)
		end,
	},
	{
		Name = "Breaker: TR18, the migration makes the battery's electricity its charge in kWh, a tenth, and leaves a new profile's alone",
		Run = function(t: any)
			local old = Profile.Template() :: any
			old.Version = 3
			old.Base.Battery = 600 -- the old save's, beside the Charge that Reconcile filled from the template
			old.Training.Stamp = T0
			Migrations.Run(old)
			t.Check("a full old battery is a full new one", near(old.Base.Charge, BaseConfig.Battery.Capacity) and old.Base.Battery == nil, `{old.Base.Charge}`)
			t.Check("the machine's stamp is gone", old.Training.Stamp == nil)
			local new = Profile.Template()
			Migrations.Run(new)
			t.Check("a new profile keeps its starting charge", near(new.Base.Charge, BaseConfig.Start.Charge), `{new.Base.Charge}`)
			t.Check("Auto, shut, nothing on the machine", new.Base.Power.Auto and not new.Base.Power.Open and new.Training.Trainee == "")
			local problems = Saveable.Problems(old, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
