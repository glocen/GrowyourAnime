--!strict
-- Breaker cases (pure): a base over time, a power plant (TR18). Full power, shortage (slowed in proportion, never
-- stopped), overflow past the cap, away and back, a shard taken out mid-work, the line fed shortest first, a clock stepping
-- back, many small advances landing where one large one does, an advance repeated at one moment paying nothing twice
-- (section 9); the split (Auto and shares), the floor, the Training
-- machine on the base's clock, voltage's price and the migration to kWh. Expected values come from Config wherever they
-- can.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Growth = require(Shared.Rules.Growth)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Training = require(Shared.Rules.Training)
local Collection = require(Shared.Rules.Collection)
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local GrowthConfig = require(Shared.Config.Growth)

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
			-- The worker's growth held, so its kW stays its own: this case is the battery's.
			withConfig(GrowthConfig.Work :: any, "XpPerKwh", 0, function()
				local data = fresh(0)
				local capacity = Breaker.Capacity(data.Base)
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
			end)
		end,
	},
	{
		Name = "Breaker: away, workers stop after the away hours",
		Run = function(t: any)
			withConfig(GrowthConfig.Work :: any, "XpPerKwh", 0, function() -- the worker's kW held: this case is the away hours'
				local data = fresh(0)
				withWatt(data)
				local rate = perSecond(Power.Generation(data))
				local hours = BaseConfig.Battery.AwayHours
				local summary = Breaker.Advance(data, T0 + (hours + 8) * 3600, true)
				local made = math.min(rate * hours * 3600, Breaker.Capacity(data.Base))
				t.Check("made only the away hours", near(summary.Made, rate * hours * 3600, 1e-3), `{summary.Made}`)
				t.Check("stored", near(data.Base.Charge, made, 1e-3))
			end)
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
			local again = Breaker.Advance(data, T0 + 2 * span)
			t.Check("a worker never trains: it grows by working instead", again.Trained == nil and again.Levels == 0, `{again.Trained}, {again.Levels}`)
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
			t.Check("a full old battery is a full new one", near(old.Base.Charge, Breaker.Capacity(old.Base)) and old.Base.Battery == nil, `{old.Base.Charge}`)
			t.Check("the machine's stamp is gone", old.Training.Stamp == nil)
			local new = Profile.Template()
			Migrations.Run(new)
			t.Check("a new profile keeps its starting charge", near(new.Base.Charge, BaseConfig.Start.Charge), `{new.Base.Charge}`)
			t.Check("Auto, shut, nothing on the machine", new.Base.Power.Auto and not new.Base.Power.Open and new.Training.Trainee == "")
			local problems = Saveable.Problems(old, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Breaker: AR19, the mill's gauge: generation and demand on one scale, its top the larger over Fill and never under Floor, steps lit from the first",
		Run = function(t: any)
			local gauge = { Steps = 8, Floor = 60, Fill = 0.85 }
			local read = Power.Gauge(0, 0, gauge)
			t.Check("nothing made, nothing asked: no step lit, the mark at the foot", read.Lit == 0 and read.Generation == 0 and read.Demand == 0)
			read = Power.Gauge(30, 15, gauge)
			t.Check("a starter's 30 kW under the floor's 60: half the scale", near(read.Generation, 0.5), tostring(read.Generation))
			t.Equal("so four steps of eight", read.Lit, 4)
			t.Check("the demand on the same scale", near(read.Demand, 0.25), tostring(read.Demand))
			read = Power.Gauge(120, 60, gauge)
			t.Check("past the floor the larger stands at Fill, never at the top", near(read.Generation, 0.85), tostring(read.Generation))
			t.Equal("seven steps", read.Lit, 7)
			t.Check("and the demand at half of it", near(read.Demand, 0.425), tostring(read.Demand))
			read = Power.Gauge(60, 120, gauge)
			t.Check("short of power: the demand the larger, at Fill", near(read.Demand, 0.85), tostring(read.Demand))
			t.Check("the generation under it", near(read.Generation, 0.425), tostring(read.Generation))
			local meet = Power.Gauge(90, 90, gauge)
			t.Check("generation meeting demand: the lit steps reach the mark", meet.Generation == meet.Demand and meet.Lit == math.floor(meet.Demand * 8 + 0.5))
			t.Equal("any power made lights the first step", Power.Gauge(1, 0, gauge).Lit, 1)
			t.Equal("all eight at the top", Power.Gauge(100, 0, { Steps = 8, Floor = 10, Fill = 1 }).Lit, 8)
			read = Power.Gauge(0 / 0, -5, gauge)
			t.Check("no number or a negative: nothing", read.Lit == 0 and read.Generation == 0 and read.Demand == 0)
		end,
	},
	{
		Name = "Breaker: TR24's fix 5, the first session's shards break in a few seconds and open themselves on the plot, the others by hand",
		Run = function(t: any)
			local grades = ShardConfig.Grades
			t.Check("Watt's Named shard breaks in a starter's time", grades.Named.BreakSeconds <= grades.Starter.BreakSeconds, tostring(grades.Named.BreakSeconds))
			t.Check("a few seconds", grades.Starter.BreakSeconds <= 10, tostring(grades.Starter.BreakSeconds))
			t.Check("the Named and the starters open themselves", grades.Named.Opens == true and grades.Starter.Opens == true)
			t.Check("the rolled grades by hand", grades.Standard.Opens ~= true and grades.Enriched.Opens ~= true and grades.Prismatic.Opens ~= true)
			local function work(def: string): Profile.ShardWork
				return { Def = def, Luck = 0, Done = 0 }
			end
			t.Equal("nothing ready: nothing", Breaker.SelfOpening({}, true), nil)
			t.Equal("Watt's alone, on the plot: it", Breaker.SelfOpening({ work("named_watt") }, true), 1)
			t.Equal("off the plot: it waits", Breaker.SelfOpening({ work("named_watt") }, false), nil)
			t.Equal("a starter's too", Breaker.SelfOpening({ work("starter_pip") }, true), 1)
			t.Equal("a Standard's waits for a tap", Breaker.SelfOpening({ work(STANDARD) }, true), nil)
			t.Equal("behind a Standard: Watt's", Breaker.SelfOpening({ work(STANDARD), work("named_watt") }, true), 2)
			t.Equal("the oldest of two first", Breaker.SelfOpening({ work("starter_rook"), work("named_watt") }, true), 1)
			t.Equal("an unknown shard waits", Breaker.SelfOpening({ work("no_such_shard") }, true), nil)
		end,
	},
	{
		Name = "Breaker (section 9): an advance repeated at the same moment pays its overflow once, and small advances, each twice, pay what one large one does",
		Run = function(t: any)
			local function build(): Profile.Data
				local data = fresh(0)
				withWatt(data)
				return data
			end
			local sample = build()
			local rate = perSecond(Power.Generation(sample))
			local at = T0 + math.ceil(Breaker.Capacity(sample.Base) / rate) + 3600 -- an hour past full
			local once = build()
			Breaker.Advance(once, at)
			local credits, spill, charge = once.Currency.Credits, once.Base.Spill, once.Base.Charge
			t.Check("the overflow paid Credits", credits > 0, `{credits}`)
			-- two wakes in one moment, as when a rejoin and a machine's change both advance the base in a frame
			local again = Breaker.Advance(once, at)
			t.Check("the same moment again pays nothing", again.Credits == 0 and again.Overflow == 0 and again.Made == 0, `{again.Credits} Credits, {again.Overflow} kWh`)
			t.Check("and changes nothing", once.Currency.Credits == credits and once.Base.Spill == spill and once.Base.Charge == charge and once.Base.Stamp == at)
			local steps = build()
			for second = 7, at - T0, 7 do
				Breaker.Advance(steps, T0 + second)
				Breaker.Advance(steps, T0 + second)
			end
			Breaker.Advance(steps, at)
			local whole, part = steps.Currency.Credits + steps.Base.Spill, credits + spill
			t.Check("Credits and their carried rest add up as in one advance", near(whole, part, 1e-3), `{whole} against {part}`)
			t.Check("whole Credits at most one apart, from rounding", math.abs(steps.Currency.Credits - credits) <= 1, `{steps.Currency.Credits} against {credits}`)
			t.Check("the rest carried stays under a Credit", steps.Base.Spill >= 0 and steps.Base.Spill < 1, `{steps.Base.Spill}`)
		end,
	},
	{
		Name = "Breaker: the workers grow by working (the director, 2026-11-24): Work.XpPerKwh a kWh at the bay's level, the rest banked on the bay, never the lead",
		Run = function(t: any)
			local data = fresh(0)
			local id = withWatt(data)
			local watt, bay = data.Voidkin[id], data.Base.Bays[1]
			watt.Level, watt.Xp = 40, 0 -- far from its next level, so these spans grow its experience only
			local span = 600
			local want = Power.Output(watt) * span / 3600 * GrowthConfig.Work.XpPerKwh
			t.Check("the span stays under its next level", want * (1 + BaseLevels.BayOutput(26)) < (Growth.XpToNext(40) :: number))
			local summary = Breaker.Advance(data, T0 + span)
			t.Check("its kWh's experience", watt.Level == 40 and watt.Xp == math.floor(want), `{watt.Level}/{watt.Xp} against {want}`)
			t.Check("what isn't whole banked on its bay", near(bay.Banked or 0, want - math.floor(want)), `{bay.Banked}`)
			t.Equal("no level yet", summary.Worked, 0)
			local had = watt.Xp + (bay.Banked or 0)
			bay.Level = 26
			Breaker.Advance(data, T0 + 2 * span)
			local grew = watt.Xp + (bay.Banked or 0) - had
			t.Check("a bay's level grows its worker as it raises its output", near(grew, want * BaseLevels.BayOutput(26), 1e-6), `{grew} against {want * BaseLevels.BayOutput(26)}`)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the bank saves", #problems == 0, table.concat(problems, "; "))
			data.Roles.Lead = id -- a lead somehow still in a bay
			local before, banked = watt.Xp, bay.Banked
			local lead = Breaker.Advance(data, T0 + 3 * span)
			t.Check("the lead never grows by working", watt.Xp == before and bay.Banked == banked and lead.Worked == 0)
		end,
	},
	{
		Name = "Breaker: a worker's level is an event of the clock: from level 1, many short advances grow it and fill the battery as one long one does",
		Run = function(t: any)
			local function build(): Profile.Data
				local data = fresh(0)
				withWatt(data)
				return data
			end
			local once, steps = build(), build()
			local first = Power.Generation(once)
			local span = 2 * 3600
			local summary = Breaker.Advance(once, T0 + span)
			for second = 10, span, 10 do
				Breaker.Advance(steps, T0 + second)
			end
			local a, b = steps.Voidkin[steps.Base.Bays[1].Worker], once.Voidkin[once.Base.Bays[1].Worker]
			t.Check("it gained levels by working", summary.Worked > 0 and b.Level == 1 + summary.Worked, `{summary.Worked}, level {b.Level}`)
			t.Check("and its kW rose with them", Power.Generation(once) > first, `{Power.Generation(once)} against {first}`)
			t.Check("the same level and experience", a.Level == b.Level and math.abs(a.Xp - b.Xp) <= 1, `{a.Level}/{a.Xp} against {b.Level}/{b.Xp}`)
			t.Check("the same battery", near(steps.Base.Charge, once.Base.Charge, 1e-3), `{steps.Base.Charge} against {once.Base.Charge}`)
		end,
	},
	{
		Name = "Breaker: away, a worker grows only while it generates, the away hours; at the top level it keeps nothing",
		Run = function(t: any)
			local away, online = fresh(0), fresh(0)
			local a, b = away.Voidkin[withWatt(away)], online.Voidkin[withWatt(online)]
			local hours = BaseConfig.Battery.AwayHours
			Breaker.Advance(away, T0 + (hours + 8) * 3600, true)
			Breaker.Advance(online, T0 + hours * 3600)
			t.Check("hours past the away hours grow nothing", a.Level > 1 and a.Level == b.Level and a.Xp == b.Xp, `{a.Level}/{a.Xp} against {b.Level}/{b.Xp}`)
			local data = fresh(0)
			local top = data.Voidkin[withWatt(data)]
			top.Level = GrowthConfig.MaxLevel
			local summary = Breaker.Advance(data, T0 + 3600)
			t.Check("at the top level: no experience kept, none banked", top.Level == GrowthConfig.MaxLevel and top.Xp == 0 and (data.Base.Bays[1].Banked or 0) == 0 and summary.Worked == 0)
		end,
	},
}
