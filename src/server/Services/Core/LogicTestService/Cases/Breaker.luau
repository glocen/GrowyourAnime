--!strict
-- Breaker cases (pure): a base over time. Full power, shortage (slowed in proportion, never stopped), overflow past the cap,
-- away and back, a shard taken out mid-work, the line fed shortest first, a clock stepping back, and many small advances
-- landing where one large one does. Expected values come from Config wherever they can.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Breaker = require(Shared.Rules.Breaker)
local Collection = require(Shared.Rules.Collection)
local BaseConfig = require(Shared.Config.Base)

local T0 = 1_800_000_000
local STANDARD = "lanternrow_standard"

local function fresh(battery: number?): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Base.Battery = battery or 0
	Breaker.Advance(data, T0) -- the first advance only sets the stamp
	return data
end

local function work(def: string, done: number?): Profile.ShardWork
	return { Def = def, Luck = 0, Done = done or 0 }
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
		Name = "Breaker: at full power a shard takes its seconds and its electricity",
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
			t.Check("the battery paid it", near(data.Base.Battery, 0))
		end,
	},
	{
		Name = "Breaker: with no power it slows to its floor, never stops",
		Run = function(t: any)
			local seconds = Breaker.Cost(STANDARD) :: number
			local data = fresh(0)
			Breaker.AddToLine(data, work(STANDARD))
			local slowest = seconds / BaseConfig.Breaker.MinSpeed
			Breaker.Advance(data, T0 + slowest - 1)
			t.Equal("not yet", #data.Base.Ready, 0)
			Breaker.Advance(data, T0 + slowest + 1)
			t.Equal("ready at the floor's pace", #data.Base.Ready, 1)
		end,
	},
	{
		Name = "Breaker: short of power it slows in proportion",
		Run = function(t: any)
			withConfig(BaseConfig.Breaker :: any, "MinSpeed", 0, function()
				local seconds, energy = Breaker.Cost(STANDARD)
				local data = fresh(0)
				withWatt(data)
				local share = Breaker.Production(data) / ((energy :: number) / (seconds :: number))
				Breaker.AddToLine(data, work(STANDARD))
				Breaker.Advance(data, T0 + 10)
				local done = (data.Base.Chambers[1].Work :: Profile.ShardWork).Done
				t.Check("work at the workers' share", near(done, 10 * share), `done {done}, share {share}`)
				t.Check("nothing stored", near(data.Base.Battery, 0))
			end)
		end,
	},
	{
		Name = "Breaker: the battery fills to its cap, then overflow pays Credits",
		Run = function(t: any)
			local capacity = BaseConfig.Battery.Capacity
			local data = fresh(0)
			withWatt(data)
			local rate = Breaker.Production(data)
			local toFull = capacity / rate
			local extra = 1000
			local summary = Breaker.Advance(data, T0 + toFull + extra)
			t.Check("full", near(data.Base.Battery, capacity))
			t.Check("the overflow", near(summary.Overflow, rate * extra, 1e-3), `{summary.Overflow}`)
			local paid = rate * extra * BaseConfig.Battery.CreditsPerElectricity
			t.Equal("whole Credits paid", data.Currency.Credits, math.floor(paid))
			t.Check("the rest carried", near(data.Base.Spill, paid - math.floor(paid), 1e-3), `{data.Base.Spill}`)
		end,
	},
	{
		Name = "Breaker: away, workers stop after the away hours",
		Run = function(t: any)
			local data = fresh(0)
			withWatt(data)
			local rate = Breaker.Production(data)
			local hours = BaseConfig.Battery.AwayHours
			local summary = Breaker.Advance(data, T0 + (hours + 8) * 3600, true)
			local made = math.min(rate * hours * 3600, BaseConfig.Battery.Capacity)
			t.Check("made only the away hours", near(summary.Made, rate * hours * 3600, 1e-3), `{summary.Made}`)
			t.Check("stored", near(data.Base.Battery, made, 1e-3))
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
			t.Equal("the battery spent", data.Base.Battery, 0)
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
			t.Check("the same battery", near(steps.Base.Battery, once.Base.Battery, 1e-3), `{steps.Base.Battery} against {once.Base.Battery}`)
			local a, b = steps.Base.Chambers[1].Work, once.Base.Chambers[1].Work
			t.Check("the same work in chamber 1", (a == nil) == (b == nil) and (a == nil or near(a.Done, (b :: any).Done, 1e-3)))
		end,
	},
	{
		Name = "Breaker: a free starter costs nothing and needs no power",
		Run = function(t: any)
			local seconds = Breaker.Cost("starter_rook") :: number
			local data = fresh(0)
			Breaker.AddToLine(data, work("starter_rook"))
			Breaker.Advance(data, T0 + seconds)
			t.Equal("ready at full speed", #data.Base.Ready, 1)
			t.Equal("nothing drawn", data.Base.Battery, 0)
		end,
	},
}
