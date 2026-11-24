--!strict
-- Condenser cases (pure): the Stone Condenser (TR37; Rules.Condenser, Config.Condenser). Asleep below its base level; its
-- rate, tray and rating by level; its speed by power (full, a split, the floor); the tray's cap stopping it and a higher
-- level starting it again; away time worked on return; the convert, one at a time, landing even in a full tray; a collect
-- and a convert each in one step, a repeat never collecting or spending twice (section 9); many small advances landing
-- where one large one does; the server's wake times. Expected values come from Config wherever they can.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Base = require(Shared.Rules.Base)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Collection = require(Shared.Rules.Collection)
local Condenser = require(Shared.Rules.Condenser)
local BaseConfig = require(Shared.Config.Base)
local GrowthConfig = require(Shared.Config.Growth)
local CondenserConfig = require(Shared.Config.Condenser)
local DataConfig = require(Shared.Config.Data)

local T0 = 1_800_000_000
local HOUR = 3600
local LOW, MID = CondenserConfig.Makes, CondenserConfig.Convert.To

-- A new account at base level `level` (the Condenser's waking one unless said), its battery at `charge` kWh.
local function fresh(level: number?, charge: number?): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Base.Level = level or CondenserConfig.Wakes
	data.Base.Charge = charge or 0
	Breaker.Advance(data, T0) -- the first advance only sets the stamp
	return data
end

-- A battery full at its base level's cap: full power for every hour it holds.
local function charged(data: Profile.Data): Profile.Data
	data.Base.Charge = Breaker.Capacity(data.Base)
	return data
end

-- Runs an action as the server does: inside one Transaction, with the client's op id.
local function act(data: Profile.Data, name: string, args: any, now: number, opId: string?): (any, boolean)
	local action = Base.Actions[name]
	local answer, changed = Transaction.Run(data, opId, function(draft: Profile.Data): any
		return action(draft, args, now, 0.5)
	end, DataConfig.OpsKept)
	return answer, changed
end

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-6)
end

local function tray(data: Profile.Data, grade: string): number
	return data.Base.Condenser.Tray[grade] or 0
end

local function saves(t: any, data: Profile.Data, label: string)
	local problems = Saveable.Problems(data, "profile")
	t.Check(`{label}: saves whole`, #problems == 0, table.concat(problems, "; "))
end

return {
	{
		Name = "Condenser: TR37, its rate, tray and rating by level, from Config",
		Run = function(t: any)
			local rate = CondenserConfig.Rate
			t.Check("level 1 makes First an hour", near(Condenser.Rate(1), rate.First))
			t.Check("level 30 makes PerLevel more a level", near(Condenser.Rate(30), rate.First + 29 * rate.PerLevel), `{Condenser.Rate(30)}`)
			t.Check("research's seed: 2.45 an hour at 30", near(Condenser.Rate(30), 2.45))
			t.Equal("its tray holds TrayHours of its making, whole stones, at 1", Condenser.Cap(1), math.floor(CondenserConfig.TrayHours * rate.First))
			t.Equal("and at 30", Condenser.Cap(30), math.floor(CondenserConfig.TrayHours * Condenser.Rate(30) + 1e-9))
			t.Check("its rating is Kw at 1", near(Condenser.Rating(1), CondenserConfig.Kw))
			t.Check("rising with its rate: 24.5 kW at 30", near(Condenser.Rating(30), 24.5), `{Condenser.Rating(30)}`)
			t.Check("asleep below its base level", not Condenser.Awake(CondenserConfig.Wakes - 1))
			t.Check("awake from it", Condenser.Awake(CondenserConfig.Wakes))
			local offer = BaseLevels.NextMachine("Condenser", 2, 3, 1e9)
			local gains: { [string]: any } = {}
			for _, gain in offer.Gains do
				gains[gain.What] = gain
			end
			t.Check("its next level's offer shows its rate", gains.Rate ~= nil and near(gains.Rate.To, Condenser.Rate(3)))
			t.Check("and its tray", gains.Tray ~= nil and gains.Tray.To == Condenser.Cap(3))
			local woken = false
			for _, gain in BaseLevels.Next(CondenserConfig.Wakes - 1, 1e9).Gains do
				woken = woken or (gain.What == "Condenser" and gain.To == 1)
			end
			t.Check("the base level that wakes it says so", woken)
		end,
	},
	{
		Name = "Condenser: TR37, asleep it makes nothing, asks nothing, and every ask of it is refused",
		Run = function(t: any)
			local data = charged(fresh(CondenserConfig.Wakes - 1))
			data.Bag.Stones[LOW] = 20
			data.Currency.Credits = 1e9
			t.Equal("it asks no power", Breaker.Rates(data).Flow.Demand.Condenser, 0)
			t.Equal("the server has nothing to wake for", Breaker.NextEvent(data), nil)
			Breaker.Advance(data, T0 + 5 * HOUR)
			t.Equal("five hours make nothing", tray(data, LOW), 0)
			t.Equal("a collect", act(data, "CollectTray", {}, T0 + 5 * HOUR).Error, Base.Asleep)
			t.Equal("a convert", act(data, "Convert", {}, T0 + 5 * HOUR).Error, Base.Asleep)
			t.Equal("its level", act(data, "UpgradeMachine", { Machine = "Condenser", Level = 2 }, T0 + 5 * HOUR).Error, Base.Asleep)
			t.Equal("no stone left the bag", data.Bag.Stones[LOW], 20)
			saves(t, data, "asleep")
		end,
	},
	{
		Name = "Condenser: TR37, at full power it makes its rate into its tray, and a higher level makes faster and asks more",
		Run = function(t: any)
			local data = charged(fresh())
			t.Check("awake, it asks its rating", near(Breaker.Rates(data).Flow.Demand.Condenser, Condenser.Rating(1)))
			t.Check("the battery tops it up to full speed", near(Breaker.Rates(data).Condenser, 1))
			Breaker.Advance(data, T0 + 3.5 * HOUR)
			t.Equal("three and a half hours: three stones", tray(data, LOW), 3)
			t.Check("and half of the next", near(data.Base.Condenser.Made, 0.5), `{data.Base.Condenser.Made}`)
			t.Check("drawing its rating the while", near(Breaker.Capacity(data.Base) - data.Base.Charge, Condenser.Rating(1) * 3.5, 1e-4), `{data.Base.Charge}`)
			local fast = charged(fresh(3))
			fast.Base.Machines.Condenser = 21
			local rate = Condenser.Rate(21)
			Breaker.Advance(fast, T0 + 2 * HOUR)
			t.Equal("at level 21 two hours make its rate twice", tray(fast, LOW), math.floor(2 * rate + 1e-9))
			t.Check("asking its level's rating", near(Breaker.Rates(fast).Flow.Demand.Condenser, Condenser.Rating(21)))
			saves(t, data, "after making")
		end,
	},
	{
		Name = "Condenser: TR37, with less power it makes slower: a split's share over its rating, the floor with none",
		Run = function(t: any)
			local floor = BaseConfig.Power.MinSpeed
			local none = fresh()
			t.Check("no generation, no charge: at the floor", near(Breaker.Rates(none).Condenser, floor))
			Breaker.Advance(none, T0 + HOUR / floor + 60)
			t.Equal("one stone in the floor's hours", tray(none, LOW), 1)
			t.Check("and the floor's share of the minute past it", near(none.Base.Condenser.Made, 60 * floor / HOUR), `{none.Base.Condenser.Made}`)
			-- A worker in bay 1 and a split giving the Condenser half its rating.
			local data = fresh()
			local watt = Collection.Uncover(data, "watt", T0)
			data.Voidkin[watt.Id].Level = GrowthConfig.MaxLevel -- its kW stay: work's experience (TR55) raises them otherwise
			data.Base.Bays[1].Worker = watt.Id
			local generation = Power.Generation(data)
			t.Check("the worker makes enough to split", generation >= Condenser.Rating(1) / 2, `{generation}`)
			data.Base.Power.Auto = false
			data.Base.Power.Shares = { Condenser = Condenser.Rating(1) / 2 / generation }
			t.Check("half its rating offered: half speed", near(Breaker.Rates(data).Condenser, 0.5), `{Breaker.Rates(data).Condenser}`)
			Breaker.Advance(data, T0 + 7 * HOUR)
			t.Equal("seven hours at half speed: three stones", tray(data, LOW), 3)
			t.Check("and half of the next", near(data.Base.Condenser.Made, 0.5), `{data.Base.Condenser.Made}`)
			-- Under Auto, short of generation with the battery empty: the generation's share of what's asked.
			data.Base.Power.Auto = true
			data.Base.Charge = 0
			local rates = Breaker.Rates(data)
			local share = math.max(floor, math.min(1, generation / rates.Demand))
			t.Check("Auto shares what's made by demand", near(rates.Condenser, share), `{rates.Condenser}, {share}`)
		end,
	},
	{
		Name = "Condenser: TR37, a full tray stops it and asks no power; a level that holds more starts it again",
		Run = function(t: any)
			local data = charged(fresh())
			local cap = Condenser.Cap(1)
			Breaker.Advance(data, T0 + (cap + 1) * HOUR)
			t.Equal("past its tray's hours it holds its cap", tray(data, LOW), cap)
			t.Equal("its next share is dropped", data.Base.Condenser.Made, 0)
			t.Equal("full, it asks nothing", Breaker.Rates(data).Flow.Demand.Condenser, 0)
			t.Check("it stopped drawing when it filled", near(Breaker.Capacity(data.Base) - data.Base.Charge, Condenser.Rating(1) * cap, 1e-4), `{data.Base.Charge}`)
			t.Equal("nothing to wake the server for", Breaker.NextEvent(data), nil)
			local before = data.Base.Charge
			Breaker.Advance(data, T0 + (cap + 6) * HOUR)
			t.Equal("five more hours make nothing", tray(data, LOW), cap)
			t.Check("and draw nothing", near(data.Base.Charge, before))
			-- Level 2 holds what level 1 does; level 3 one more.
			data.Currency.Credits = 1e9
			local now = T0 + (cap + 6) * HOUR
			t.Check("level 2 bought", act(data, "UpgradeMachine", { Machine = "Condenser", Level = 2 }, now).Ok == true)
			t.Equal("its level", data.Base.Machines.Condenser, 2)
			t.Check("level 3 bought", act(data, "UpgradeMachine", { Machine = "Condenser", Level = 3 }, now).Ok == true)
			t.Check("a tray that holds more makes again", Condenser.Making(data.Base) and Condenser.Cap(3) > cap)
			t.Check("asking its rating", near(Breaker.Rates(data).Flow.Demand.Condenser, Condenser.Rating(3)))
			saves(t, data, "full")
		end,
	},
	{
		Name = "Condenser: TR37, away it works on the battery and stops at its cap; on return it holds what it made",
		Run = function(t: any)
			local data = charged(fresh())
			local charge = data.Base.Charge
			Breaker.Advance(data, T0 + 8 * HOUR, true)
			t.Equal("eight hours away: eight stones", tray(data, LOW), 8)
			local long = charged(fresh())
			Breaker.Advance(long, T0 + 30 * HOUR, true)
			local cap = Condenser.Cap(1)
			t.Equal("thirty hours away: its cap", tray(long, LOW), cap)
			t.Check("the battery paid only its working hours", near(charge - long.Base.Charge, Condenser.Rating(1) * cap, 1e-4), `{long.Base.Charge}`)
			local answer = act(long, "CollectTray", {}, T0 + 30 * HOUR, "back")
			t.Check("the return's collect takes them all", answer.Ok == true and answer.Count == cap)
			t.Equal("into the bag", long.Bag.Stones[LOW], cap)
			saves(t, long, "after away")
		end,
	},
	{
		Name = "Condenser: TR37, the convert takes its stones at once and lands its higher grade after its work, one at a time",
		Run = function(t: any)
			local convert = CondenserConfig.Convert
			local data = charged(fresh())
			data.Bag.Stones[convert.From] = convert.Take + 2
			local answer = act(data, "Convert", {}, T0, "c1")
			t.Check("begun", answer.Ok == true and answer.Spent == convert.Take)
			t.Equal("its stones left the bag", data.Bag.Stones[convert.From], 2)
			t.Equal("a second is refused while it runs", act(data, "Convert", {}, T0 + 60, "c2").Error, Base.Busy)
			local repeat_ = act(data, "Convert", {}, T0 + 60, "c1")
			t.Check("the first one's repeat answers as it did", repeat_.Ok == true)
			t.Equal("and takes nothing more", data.Bag.Stones[convert.From], 2)
			Breaker.Advance(data, T0 + convert.Seconds - 1)
			t.Equal("a second short: not yet", tray(data, convert.To), 0)
			Breaker.Advance(data, T0 + convert.Seconds)
			t.Equal("its work done: its grade in the tray", tray(data, convert.To), convert.Give)
			t.Equal("none under way", data.Base.Condenser.Convert, nil)
			t.Equal("short of stones it's refused", act(data, "Convert", {}, T0 + convert.Seconds, "c3").Error, Base.Stones)
			-- At the floor it takes the floor's share longer.
			local slow = fresh()
			slow.Base.Condenser.Tray[LOW] = Condenser.Cap(1) -- full: only the convert asks
			slow.Bag.Stones[convert.From] = convert.Take
			act(slow, "Convert", {}, T0, "s1")
			t.Check("full but converting, it asks its rating", near(Breaker.Rates(slow).Flow.Demand.Condenser, Condenser.Rating(1)))
			local floor = BaseConfig.Power.MinSpeed
			t.Check("the server wakes for its end", near(Breaker.NextEvent(slow) :: number, convert.Seconds / floor))
			Breaker.Advance(slow, T0 + convert.Seconds / floor)
			t.Equal("at the floor, in its seconds over the floor", tray(slow, convert.To), convert.Give)
			saves(t, data, "after a convert")
		end,
	},
	{
		Name = "Condenser: TR37, with the tray full and a convert running, the convert still finishes and its grade lands",
		Run = function(t: any)
			local convert = CondenserConfig.Convert
			local data = charged(fresh())
			local cap = Condenser.Cap(1)
			data.Base.Condenser.Tray[LOW] = cap
			data.Bag.Stones[convert.From] = convert.Take
			t.Check("begun on a full tray", act(data, "Convert", {}, T0, "f1").Ok == true)
			Breaker.Advance(data, T0 + convert.Seconds)
			t.Equal("its grade landed beside the cap", tray(data, convert.To), convert.Give)
			t.Equal("the tray still holds its cap", tray(data, LOW), cap)
			t.Equal("and it rests: nothing asked", Breaker.Rates(data).Flow.Demand.Condenser, 0)
		end,
	},
	{
		Name = "Condenser: TR37, its comb lights by the tray's fill: empty dark, one stone one cup, full the whole comb",
		Run = function(t: any)
			local cups = 37 -- Stage I's comb (the base plan's machines.condenser)
			local data = fresh()
			local cap = Condenser.Cap(1)
			t.Equal("empty: none", Condenser.Lit(data.Base, cups), 0)
			data.Base.Condenser.Tray[LOW] = 1
			t.Equal("one stone: one cup", Condenser.Lit(data.Base, cups), math.ceil(cups / cap))
			data.Base.Condenser.Tray[LOW] = math.floor(cap / 2)
			t.Check("half: about half the comb", math.abs(Condenser.Lit(data.Base, cups) - cups / 2) <= cups / cap + 1, `{Condenser.Lit(data.Base, cups)}`)
			data.Base.Condenser.Tray[LOW] = cap
			t.Equal("full: the whole comb", Condenser.Lit(data.Base, cups), cups)
			data.Base.Condenser.Tray[LOW] = cap - 1
			t.Check("one short of full: not the whole comb", Condenser.Lit(data.Base, cups) < cups)
			data.Base.Condenser.Tray[LOW] = 0
			data.Base.Condenser.Tray[MID] = 3
			t.Equal("only a convert's grade waiting: the comb is dark", Condenser.Lit(data.Base, cups), 0)
			local asleep = fresh(CondenserConfig.Wakes - 1)
			asleep.Base.Condenser.Tray[LOW] = 5
			t.Equal("asleep: dark", Condenser.Lit(asleep.Base, cups), 0)
		end,
	},
	{
		Name = "Condenser (section 9): a collect is one step, and a repeat or a second ask never collects twice",
		Run = function(t: any)
			local convert = CondenserConfig.Convert
			local data = charged(fresh())
			data.Base.Condenser.Tray[MID] = 1
			local now = T0 + 3 * HOUR
			local answer = act(data, "CollectTray", {}, now, "k1") -- what it made up to now lands first
			t.Check("three stones and a Mid", answer.Ok == true and answer.Count == 4 and answer.Stones[LOW] == 3 and answer.Stones[MID] == 1)
			t.Equal("in the bag", data.Bag.Stones[LOW], 3)
			t.Equal("its Mid too", data.Bag.Stones[convert.To], 1)
			t.Equal("the tray is empty", tray(data, LOW) + tray(data, MID), 0)
			local again = act(data, "CollectTray", {}, now, "k1")
			t.Check("the repeat answers as the first did", again.Ok == true and again.Count == 4)
			t.Equal("and adds nothing", data.Bag.Stones[LOW], 3)
			t.Equal("a new ask finds it empty", act(data, "CollectTray", {}, now, "k2").Error, Base.Empty)
			t.Equal("a bay given to the Condenser's level is refused", act(data, "UpgradeMachine", { Machine = "Condenser", Bay = 1, Level = 2 }, now).Error, Base.BadArgs)
			t.Equal("a level past the next is stale", act(data, "UpgradeMachine", { Machine = "Condenser", Level = 3 }, now).Error, Base.Stale)
			saves(t, data, "after collecting")
		end,
	},
	{
		Name = "Condenser: TR37, many small advances land where one large one does, making and converting",
		Run = function(t: any)
			local convert = CondenserConfig.Convert
			local function begun(): Profile.Data
				local data = charged(fresh())
				data.Bag.Stones[convert.From] = convert.Take
				act(data, "Convert", {}, T0)
				return data
			end
			local one, many = begun(), begun()
			local seconds = 6600
			Breaker.Advance(one, T0 + seconds)
			for at = 66, seconds, 66 do
				Breaker.Advance(many, T0 + at)
			end
			t.Equal("the same stones", tray(many, LOW), tray(one, LOW))
			t.Check("the same share of the next", near(many.Base.Condenser.Made, one.Base.Condenser.Made, 1e-6), `{many.Base.Condenser.Made}, {one.Base.Condenser.Made}`)
			t.Equal("the convert landed in both", tray(many, MID) + tray(one, MID), 2 * convert.Give)
			t.Check("the same charge", near(many.Base.Charge, one.Base.Charge, 1e-4))
			t.Check("the server wakes for its next stone", near(Breaker.NextEvent(one) :: number, (1 - one.Base.Condenser.Made) * HOUR / Condenser.Rate(1), 1e-3))
		end,
	},
}
