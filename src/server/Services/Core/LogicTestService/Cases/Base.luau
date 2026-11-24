--!strict
-- Base action cases (pure): every action a client may send for its base and its Voidkin, run through Transaction as the
-- server runs it. The first circuit on a fresh account, each action repeated with one op id and interrupted half way,
-- hostile arguments, one role at a time, a change of workers never reaching back in time, and a return after hours away
-- with work left partly done (the package's gates B and D, docs/test-requests.md, TR2); voltage and the plant's split
-- (TR18); the base's levels and its machines', bought once each, and what each level does to the plant (TR21). A seeded
-- run of the shard's whole way, with repeats and cuts, never makes or loses a shard or a fighter (section 9).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Base = require(Shared.Rules.Base)
local Collection = require(Shared.Rules.Collection)
local Condenser = require(Shared.Rules.Condenser)
local Shards = require(Shared.Definitions.Shards)
local BaseConfig = require(Shared.Config.Base)
local GrowthConfig = require(Shared.Config.Growth)
local ShardConfig = require(Shared.Config.Shards)
local DataConfig = require(Shared.Config.Data)

local T0 = 1_800_000_000
local STANDARD = "lanternrow_standard"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	Breaker.Advance(data, T0)
	return data
end

-- Runs an action as the server does: inside one Transaction, with the client's op id.
local function act(data: Profile.Data, name: string, args: any, now: number, opId: string?, u: number?): (any, boolean)
	local action = Base.Actions[name] or Collection.Actions[name]
	local answer, changed = Transaction.Run(data, opId, function(draft: Profile.Data): any
		return action(draft, args, now, u or 0.5)
	end, DataConfig.OpsKept)
	return answer, changed
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

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function saves(t: any, data: Profile.Data, label: string)
	local problems = Saveable.Problems(data, "profile")
	t.Check(`{label}: saves whole`, #problems == 0, table.concat(problems, "; "))
end

-- A fresh account that chose Rook's shard and opened it: Rook leads.
local function withRook(): (Profile.Data, string)
	local data = fresh()
	act(data, "ChooseStarter", { Shard = "starter_rook" }, T0)
	local seconds = Breaker.Cost("starter_rook") :: number
	local opened = act(data, "Open", {}, T0 + seconds)
	return data, opened.Id
end

-- Arguments a hostile client might send. Nil can't sit in a list, so each loop sends it on its own first.
local HOSTILE: { any } = { 7, true, "x", { Shard = 7 }, { Shard = "__index" }, { Chamber = 0 / 0 }, { Bay = math.huge } }

return {
	{
		Name = "Base: the first circuit on a fresh account",
		Run = function(t: any)
			local data = fresh()
			local chose = act(data, "ChooseStarter", { Shard = "starter_rook" }, T0)
			t.Check("starter chosen", chose.Ok == true and data.Progress.Starter == "starter_rook")
			t.Equal("it's breaking", (data.Base.Chambers[1].Work :: Profile.ShardWork).Def, "starter_rook")
			local seconds = Breaker.Cost("starter_rook") :: number
			t.Check("broken fast", seconds <= 10, `{seconds} s`)
			t.Equal("not ready early", act(data, "Open", {}, T0 + seconds - 1).Error, Base.Empty)
			local opened = act(data, "Open", {}, T0 + seconds)
			t.Check("Rook steps out", opened.Ok == true and opened.Outcome == "New" and opened.Def == "rook")
			t.Check("and leads", opened.Lead == true and data.Roles.Lead == opened.Id)
			-- Watt's Named shard, as the first enemy drops it (a server change in the game).
			data.Bag.Shards.named_watt = 1
			t.Check("into the line", act(data, "AddShard", { Shard = "named_watt" }, T0 + 20).Ok == true)
			t.Equal("the bag keeps no zero", data.Bag.Shards.named_watt, nil)
			local wattSeconds = Breaker.Cost("named_watt") :: number
			local watt = act(data, "Open", {}, T0 + 20 + wattSeconds)
			t.Check("Watt steps out, the lead stays", watt.Ok == true and watt.Def == "watt" and watt.Lead == false)
			t.Check("Watt to work", act(data, "SetWorker", { Bay = 1, Voidkin = watt.Id }, T0 + 60).Ok == true)
			t.Check("generating power", Power.Generation(data) > 0)
			t.Equal("roles", Profile.RoleOf(data, watt.Id), "Worker")
			saves(t, data, "after the circuit")
		end,
	},
	{
		Name = "Base: the starter is chosen once, from the three",
		Run = function(t: any)
			local data = fresh()
			t.Equal("hostile nil", act(data, "ChooseStarter", nil, T0).Error, Base.Unknown)
			for _, args in HOSTILE do
				t.Equal(`hostile {tostring(args)}`, act(data, "ChooseStarter", args, T0).Error, Base.Unknown)
			end
			t.Equal("not a starter", act(data, "ChooseStarter", { Shard = "named_watt" }, T0).Error, Base.Unknown)
			t.Equal("nothing chosen", data.Progress.Starter, "")
			t.Check("one of the three", act(data, "ChooseStarter", { Shard = Shards.Starters[2] }, T0).Ok == true)
			t.Equal("not twice", act(data, "ChooseStarter", { Shard = Shards.Starters[1] }, T0).Error, Base.Chosen)
			local breaking = 0
			for _, chamber in data.Base.Chambers do
				breaking += if chamber.Work then 1 else 0
			end
			t.Equal("one shard breaking", breaking + #data.Base.Line, 1)
		end,
	},
	{
		Name = "Base: a shard put in answers where it stands, its chamber or its place in the line",
		Run = function(t: any)
			-- The Breaker's screen keeps a shard chosen as it goes in (TR9), from this answer.
			local data = fresh()
			local chambers = #data.Base.Chambers
			data.Bag.Shards[STANDARD] = chambers + 1
			for index = 1, chambers do
				local answer = act(data, "AddShard", { Shard = STANDARD }, T0)
				t.Check(`shard {index} into chamber {index}`, answer.Ok == true and answer.Chamber == index and answer.Line == nil, `{tostring(answer.Chamber)}, {tostring(answer.Line)}`)
			end
			local waiting = act(data, "AddShard", { Shard = STANDARD }, T0)
			t.Check("the next waits first in the line", waiting.Ok == true and waiting.Line == 1 and waiting.Chamber == nil, `{tostring(waiting.Chamber)}, {tostring(waiting.Line)}`)
			data.Bag.Shards.named_watt = 1
			local quick = act(data, "AddShard", { Shard = "named_watt" }, T0)
			local line = data.Base.Line
			local at = table.find(line, line[quick.Line or 0])
			t.Check("a shard that breaks sooner is answered at its own place", quick.Ok == true and at ~= nil and line[at].Def == "named_watt", `{tostring(quick.Line)}`)
			local shorter = (Breaker.Cost("named_watt") :: number) < (Breaker.Cost(STANDARD) :: number)
			t.Equal("ahead of the longer one when shorter", quick.Line, if shorter then 1 else 2)
		end,
	},
	{
		Name = "Base: an action repeated with its op id happens once",
		Run = function(t: any)
			local data = fresh()
			data.Bag.Shards[STANDARD] = 3
			local first = act(data, "AddShard", { Shard = STANDARD }, T0, "op-add")
			local again, changed = act(data, "AddShard", { Shard = STANDARD }, T0 + 1, "op-add")
			t.Check("the first answer", first.Ok == true and again.Ok == true and again.Shard == first.Shard)
			t.Check("nothing changed the second time", not changed)
			t.Equal("one shard taken", data.Bag.Shards[STANDARD], 2)
			-- Opening is the valuable one: a repeat must never uncover a second Voidkin.
			act(data, "ChooseStarter", { Shard = "starter_kirra" }, T0)
			local seconds = Breaker.Cost("starter_kirra") :: number
			local opened = act(data, "Open", {}, T0 + seconds, "op-open")
			local repeated = act(data, "Open", {}, T0 + seconds + 1, "op-open")
			t.Equal("the same Voidkin answered", repeated.Id, opened.Id)
			t.Equal("owned once", count(data.Voidkin), 1)
			t.Equal("found once", data.Index.kirra.Count, 1)
		end,
	},
	{
		Name = "Base: an action interrupted half way changes nothing",
		Run = function(t: any)
			local data = fresh()
			act(data, "ChooseStarter", { Shard = "starter_pip" }, T0)
			local seconds = Breaker.Cost("starter_pip") :: number
			local before = Profile.DeepCopy(data)
			local answer, changed = Transaction.Run(data, "op-cut", function(draft: Profile.Data): any
				Base.Open(draft, {}, T0 + seconds, 0.5)
				error("the server stopped here")
			end, DataConfig.OpsKept)
			t.Check("failed, unchanged", answer.Ok == false and not changed)
			t.Equal("still ready to open", #data.Base.Ready, #before.Base.Ready)
			t.Equal("nothing owned", count(data.Voidkin), 0)
			t.Equal("the stamp kept", data.Base.Stamp, before.Base.Stamp)
			local retry = act(data, "Open", {}, T0 + seconds, "op-cut")
			t.Check("the retry opens it", retry.Ok == true and retry.Def == "pip")
		end,
	},
	{
		Name = "Base: hostile arguments are refused and change nothing",
		Run = function(t: any)
			local data = withRook()
			data.Bag.Shards[STANDARD] = 1
			local before = Profile.DeepCopy(data)
			for name in Base.Actions do
				if name ~= "Open" then -- Open's arguments are optional: below, with a shard ready
					local answer, changed = act(data, name, nil, T0 + 100)
					t.Check(`{name} refuses nil`, answer.Ok == false and not changed, tostring(answer.Error))
				end
				for _, args in HOSTILE do
					local answer, changed = act(data, name, args, T0 + 100)
					t.Check(`{name} refuses {tostring(args)}`, answer.Ok == false and not changed, tostring(answer.Error))
				end
			end
			for _, chamber in { 0, -1, 1.5, 3, 0 / 0, math.huge, "1" } do
				t.Equal(`chamber {tostring(chamber)}`, act(data, "TakeOut", { Chamber = chamber }, T0 + 100).Error, Base.BadArgs)
			end
			t.Equal("an empty chamber", act(data, "TakeOut", { Chamber = 2 }, T0 + 100).Error, Base.Empty)
			t.Equal("the locked bay", act(data, "SetWorker", { Bay = #data.Base.Bays + 1, Voidkin = "" }, T0 + 100).Error, Base.BadArgs)
			t.Equal("not owned", act(data, "SetWorker", { Bay = 1, Voidkin = "k99" }, T0 + 100).Error, Base.Unknown)
			t.Equal("a shard not held", act(data, "AddShard", { Shard = "named_watt" }, T0 + 100).Error, Base.NoShard)
			t.Equal("nothing ready", act(data, "Open", {}, T0 + 100).Error, Base.Empty)
			t.Equal("a bad index", act(data, "Open", { Index = 2 }, T0 + 100).Error, Base.Empty)
			t.Equal("the bag untouched", data.Bag.Shards[STANDARD], before.Bag.Shards[STANDARD])
			t.Equal("the stamp untouched", data.Base.Stamp, before.Base.Stamp)
			for name in Collection.Actions do
				local refused, moved = act(data, name, nil, T0 + 100)
				t.Check(`{name} refuses nil`, refused.Ok == false and not moved)
				for _, args in HOSTILE do
					local answer, changed = act(data, name, args, T0 + 100)
					t.Check(`{name} refuses {tostring(args)}`, answer.Ok == false and not changed)
				end
			end
			table.insert(data.Base.Ready, { Def = STANDARD, Luck = 0, Done = 30 })
			for _, index in { 0, 2, 1.5, 0 / 0, math.huge, "1", true } do
				t.Equal(`open index {tostring(index)}`, act(data, "Open", { Index = index }, T0 + 100).Error, Base.BadArgs)
			end
			t.Equal("still ready", #data.Base.Ready, 1)
			t.Check("Index 1 opens it", act(data, "Open", { Index = 1 }, T0 + 100).Ok == true and #data.Base.Ready == 0)
			saves(t, data, "after the refusals")
		end,
	},
	{
		Name = "Base: one role at a time",
		Run = function(t: any)
			local data, rook = withRook()
			t.Equal("the lead can't work", act(data, "SetWorker", { Bay = 1, Voidkin = rook }, T0 + 50).Error, Base.Leading)
			local watt = Collection.Uncover(data, "watt", T0 + 50).Id
			t.Check("Watt works", act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 50).Ok == true)
			data.Base.Bays[2] = { Worker = "", Level = 1 } -- a second bay opened
			t.Check("moved, not doubled", act(data, "SetWorker", { Bay = 2, Voidkin = watt }, T0 + 50).Ok == true)
			t.Check("bay 1 emptied", data.Base.Bays[1].Worker == "" and data.Base.Bays[2].Worker == watt)
			t.Check("emptied by hand", act(data, "SetWorker", { Bay = 2, Voidkin = "" }, T0 + 50).Ok == true)
			t.Check("then Watt can lead", act(data, "SetLead", { Voidkin = watt }, T0 + 50).Ok == true and data.Roles.Lead == watt)
			t.Equal("Rook rests", Profile.RoleOf(data, rook), "Resting")
		end,
	},
	{
		Name = "Base: Lead on a stationed Voidkin recalls it and makes it lead in one step, settled first, never stationed and leading at once",
		Run = function(t: any)
			-- Research's ruling on the stationed page (2026-11-17, tier 2): the old lead goes home idle; a repeat of the same
			-- request changes nothing more; the bays made what they made up to the moment it left, as a Recall would have.
			local function stationed(): (Profile.Data, string, string)
				local data, rook = withRook()
				data.Base.Charge = 0
				local watt = Collection.Uncover(data, "watt", T0).Id
				data.Base.Bays[2] = { Worker = "", Level = 1 }
				act(data, "SetWorker", { Bay = 2, Voidkin = watt }, T0)
				return data, rook, watt
			end
			local data, rook, watt = stationed()
			local answer = act(data, "SetLead", { Voidkin = watt }, T0 + 600, "lead-1")
			t.Check("taken, saying the bay it left", answer.Ok == true and answer.Left == 2, `{answer.Ok} {answer.Left}`)
			t.Check("Watt leads, its bay empty", data.Roles.Lead == watt and data.Base.Bays[2].Worker == "")
			t.Equal("Rook home, idle", Profile.RoleOf(data, rook), "Resting")
			local function once(): boolean
				local leading, working = 0, 0
				for _, bay in data.Base.Bays do
					working += if bay.Worker == data.Roles.Lead then 1 else 0
				end
				leading = if data.Roles.Lead ~= "" then 1 else 0
				return leading == 1 and working == 0
			end
			t.Check("never stationed and leading at once", once())
			local _, changed = act(data, "SetLead", { Voidkin = watt }, T0 + 700, "lead-1")
			t.Check("the same request again changes nothing", not changed and data.Roles.Lead == watt and data.Base.Bays[2].Worker == "" and once())
			-- Settled as a Recall: the same moment, the same charge.
			local recalled = stationed()
			act(recalled, "SetWorker", { Bay = 2, Voidkin = "" }, T0 + 600)
			t.Check("the bays made what a Recall would have", recalled.Base.Charge > 0 and math.abs(recalled.Base.Charge - data.Base.Charge) < 1e-9,
				string.format("%.4f against %.4f", data.Base.Charge, recalled.Base.Charge))
			-- With no clock to settle by (a direct call), a worker stays a worker.
			local still, _, held = stationed()
			t.Equal("no clock: refused", Collection.SetLead(still, held).Error, Collection.Working)
			t.Check("and nothing moved", still.Base.Bays[2].Worker == held)
		end,
	},
	{
		Name = "Base: a change of workers never reaches back in time",
		Run = function(t: any)
			local data = withRook()
			data.Base.Charge = 0
			local watt = Collection.Uncover(data, "watt", T0).Id
			data.Voidkin[watt].Level = GrowthConfig.MaxLevel -- its kW stay: work's experience (TR55) raises them otherwise
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 100)
			local rate = Power.Generation(data) / 3600
			act(data, "SetWorker", { Bay = 1, Voidkin = "" }, T0 + 400)
			t.Check("Watt's 300 seconds kept", math.abs(data.Base.Charge - rate * 300) < 1e-9, `{data.Base.Charge}`)
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 1000)
			t.Check("the empty bay made nothing", math.abs(data.Base.Charge - rate * 300) < 1e-9, `{data.Base.Charge}`)
		end,
	},
	{
		Name = "Base: back after ten hours, work left partly done",
		Run = function(t: any)
			local data = withRook()
			local watt = Collection.Uncover(data, "watt", T0).Id
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 10)
			data.Bag.Shards[STANDARD] = 6
			for _ = 1, 6 do
				act(data, "AddShard", { Shard = STANDARD }, T0 + 20)
			end
			act(data, "TakeOut", { Chamber = 1 }, T0 + 30) -- ten seconds of work kept, sent to the back
			local away = T0 + 30 + 10 * 3600
			Breaker.Advance(data, away, true) -- as the server does on the return
			local _, energy = Breaker.Cost(STANDARD)
			local made = Power.Generation(data) * BaseConfig.Battery.AwayHours
			local paid = 0
			for _, work in data.Base.Ready do
				paid += if work.Def == STANDARD then energy :: number else 0
			end
			t.Equal("all six broke while away", #data.Base.Ready, 6)
			t.Check("never more than was made and held", paid <= made + BaseConfig.Start.Charge + 1e-6, `paid {paid}, made {made}`)
			t.Equal("six in all", #data.Base.Ready + #data.Base.Line + (if data.Base.Chambers[1].Work then 1 else 0) + (if data.Base.Chambers[2].Work then 1 else 0), 6)
			t.Equal("the stamp is the return", data.Base.Stamp, away)
			local opened = act(data, "Open", {}, away + 1)
			t.Check("one opens", opened.Ok == true)
			saves(t, data, "after the return")
		end,
	},
	{
		Name = "Base: TR18, voltage puts the battery's charge into one shard before it breaks, once: Low halves its time left, High breaks it at once",
		Run = function(t: any)
			-- Voltage saves under a minute on Lantern Row's 30-second Standard, so the case gives it an Enriched's 900.
			withConfig(ShardConfig.Grades.Standard :: any, "BreakSeconds", 900, function()
				local data = withRook()
				local now = T0 + 100
				data.Bag.Shards[STANDARD] = 3
				act(data, "AddShard", { Shard = STANDARD }, now)
				act(data, "AddShard", { Shard = STANDARD }, now)
				act(data, "AddShard", { Shard = STANDARD }, now)
				t.Check("two breaking and one waiting", data.Base.Chambers[1].Work ~= nil and data.Base.Chambers[2].Work ~= nil and #data.Base.Line == 1)
				data.Base.Charge = 20
				Breaker.Advance(data, now)
				local first = data.Base.Chambers[1].Work :: Profile.ShardWork
				local low, saved = Power.Voltage(first, 1)
				local done = first.Done
				local stored = data.Base.Charge
				local answer = act(data, "Infuse", { Chamber = 1, Def = STANDARD, Level = 1 }, now, "op-volt-1")
				t.Check("Low, into the chamber's shard", answer.Ok == true and answer.Spent == low and answer.Level == 1 and answer.Ready == false, answer.Error)
				t.Equal("its price from the battery", data.Base.Charge, stored - (low :: number))
				first = data.Base.Chambers[1].Work :: Profile.ShardWork -- a transaction commits its draft: read it again
				t.Check("its time left halved", math.abs(Breaker.Left(first) - (900 - done) / 2) < 1e-6 and math.abs(first.Done - done - saved) < 1e-9, `{Breaker.Left(first)}`)
				t.Check("the shard knows its voltage, its odds untouched", first.Volt == 1 and first.Luck == 0)
				local again = act(data, "Infuse", { Chamber = 1, Def = STANDARD, Level = 1 }, now, "op-volt-1")
				t.Check("the same op again: its answer, nothing spent twice", again.Ok == true and data.Base.Charge == stored - (low :: number))
				t.Equal("once a shard", act(data, "Infuse", { Chamber = 1, Def = STANDARD, Level = 2 }, now, "op-volt-2").Error, Base.Infused)
				local waiting = data.Base.Line[1]
				local high = Power.Voltage(waiting, 2) :: number
				local spent = data.Base.Charge
				local broke = act(data, "Infuse", { Line = 1, Def = STANDARD, Level = 2 }, now, "op-volt-3")
				local last = data.Base.Ready[#data.Base.Ready]
				t.Check("High, into the line's first: broken at once", broke.Ok == true and broke.Ready == true and last ~= nil and last.Volt == 2 and #data.Base.Line == 0, broke.Error)
				t.Equal("its price spent", data.Base.Charge, spent - high)
				data.Base.Charge = 0
				local short = act(data, "Infuse", { Chamber = 2, Def = STANDARD, Level = 1 }, now, "op-volt-4")
				t.Equal("short of charge: refused", short.Error, Base.Short)
				t.Check("and nothing spent or changed", data.Base.Charge == 0 and (data.Base.Chambers[2].Work :: any).Volt == nil)
				saves(t, data, "after voltage")
			end)
		end,
	},
	{
		Name = "Base: TR18, voltage is never offered on a shard that holds a stated Voidkin, one it would save under a minute, nor one that broke or moved",
		Run = function(t: any)
			local data = fresh()
			act(data, "ChooseStarter", { Shard = "starter_pip" }, T0)
			data.Base.Charge = 50
			local where = if data.Base.Chambers[1].Work then { Chamber = 1 } else { Line = 1 }
			local args = table.clone(where) :: any
			args.Def, args.Level = "starter_pip", 1
			t.Equal("a starter holds one Voidkin", act(data, "Infuse", args, T0).Error, Base.Named)
			-- Lantern Row's Standard: 30 seconds, so voltage would save under a minute.
			local data2 = withRook()
			data2.Bag.Shards[STANDARD] = 1
			act(data2, "AddShard", { Shard = STANDARD }, T0 + 50)
			data2.Base.Charge = 50
			t.Equal("a Standard's 30 s: not offered", act(data2, "Infuse", { Chamber = 1, Def = STANDARD, Level = 2 }, T0 + 50).Error, Base.Brief)
			t.Equal("and nothing spent", data2.Base.Charge, 50)
			-- The shard broke a moment before the ask reached the server.
			local cost = Breaker.Cost(STANDARD) :: number
			local stored = data2.Base.Charge
			local late = act(data2, "Infuse", { Chamber = 1, Def = STANDARD, Level = 1 }, T0 + 50 + cost * 20)
			t.Equal("broken since: refused", late.Error, Base.Moved)
			local kept = data2.Base.Chambers[1].Work
			t.Check("a refusal changes nothing", kept == nil or kept.Volt == nil, `{data2.Base.Charge} of {stored}`)
			t.Equal("a shard that isn't the one seen", act(data2, "Infuse", { Chamber = 1, Def = "lanternrow_enriched", Level = 1 }, T0 + 50 + cost * 20).Error, Base.Moved)
			t.Equal("no such level", act(data2, "Infuse", { Chamber = 1, Def = STANDARD, Level = 3 }, T0).Error, Base.BadArgs)
			t.Equal("both places", act(data2, "Infuse", { Chamber = 1, Line = 1, Def = STANDARD, Level = 1 }, T0).Error, Base.BadArgs)
			t.Equal("neither", act(data2, "Infuse", { Def = STANDARD, Level = 1 }, T0).Error, Base.BadArgs)
			t.Equal("a fraction", act(data2, "Infuse", { Chamber = 1.5, Def = STANDARD, Level = 1 }, T0).Error, Base.BadArgs)
		end,
	},
	{
		Name = "Base: TR18, the split is the server's: refused until the Power screen opens, checked, once per op, never reaching back in time",
		Run = function(t: any)
			local data = withRook()
			local watt = Collection.Uncover(data, "watt", T0).Id
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 10)
			local split = { Auto = false, Shares = { Breaker = 0.5, Training = 0.25 } }
			t.Equal("shut: refused", act(data, "SetPower", split, T0 + 20).Error, Base.Closed)
			t.Check("still Auto", data.Base.Power.Auto)
			data.Base.Power.Open = true
			local before = data.Base.Charge
			local set = act(data, "SetPower", split, T0 + 100, "op-split-1")
			t.Check("set", set.Ok == true and set.Auto == false and set.Shares.Breaker == 0.5, set.Error)
			t.Check("the old split ran up to now", data.Base.Stamp == T0 + 100 and data.Base.Charge > before)
			t.Check("kept", not data.Base.Power.Auto and data.Base.Power.Shares.Training == 0.25)
			local again = act(data, "SetPower", { Auto = false, Shares = { Breaker = 1 } }, T0 + 100, "op-split-1")
			t.Check("the same op again: its first answer, nothing changed", again.Shares.Breaker == 0.5 and data.Base.Power.Shares.Breaker == 0.5)
			t.Equal("over the whole", act(data, "SetPower", { Auto = false, Shares = { Breaker = 0.8, Training = 0.3 } }, T0 + 110).Error, Base.Over)
			for _, asked in { {}, { Auto = "no" }, { Auto = false }, { Auto = false, Shares = { Forge = 0.2 } }, { Auto = false, Shares = { Breaker = -1 } } } :: { any } do
				t.Equal("a malformed split", act(data, "SetPower", asked, T0 + 110).Error, Base.BadArgs)
			end
			t.Check("refusals changed nothing", data.Base.Power.Shares.Breaker == 0.5 and not data.Base.Power.Auto)
			local auto = act(data, "SetPower", { Auto = true }, T0 + 120)
			t.Check("Auto again, the shares kept for later", auto.Ok == true and data.Base.Power.Auto and data.Base.Power.Shares.Breaker == 0.5)
			saves(t, data, "after the split")
		end,
	},
	{
		Name = "Base: TR21, the base's next level for its Credits, once: the bays it opens join empty, and a repeat charges nothing",
		Run = function(t: any)
			local data = fresh()
			data.Currency.Credits = 839
			t.Equal("839 Credits are short", act(data, "UpgradeBase", { Level = 2 }, T0 + 10).Error, Base.Short)
			t.Check("nothing spent, nothing raised", data.Currency.Credits == 839 and data.Base.Level == 1 and #data.Base.Bays == 2)
			data.Currency.Credits = 1000
			local up = act(data, "UpgradeBase", { Level = 2 }, T0 + 20, "op-up")
			t.Check("level 2 for 840", up.Ok == true and up.Level == 2 and up.Spent == 840 and data.Base.Level == 2, `{up.Error}`)
			t.Equal("its Credits spent", data.Currency.Credits, 160)
			t.Equal("three bays (D5)", #data.Base.Bays, 3)
			t.Check("the new bay empty, at level 1", data.Base.Bays[3].Worker == "" and data.Base.Bays[3].Level == 1)
			local again, changed = act(data, "UpgradeBase", { Level = 2 }, T0 + 21, "op-up")
			t.Check("the same op answered again, nothing changed", again.Ok == true and not changed and data.Currency.Credits == 160)
			t.Equal("a second tap, a fresh op: refused, not charged", act(data, "UpgradeBase", { Level = 2 }, T0 + 22, "op-up-2").Error, Base.Stale)
			t.Equal("still 160 Credits", data.Currency.Credits, 160)
			t.Equal("a level skipped: refused", act(data, "UpgradeBase", { Level = 4 }, T0 + 23).Error, Base.Stale)
			t.Equal("level 3 short", act(data, "UpgradeBase", { Level = 3 }, T0 + 24).Error, Base.Short)
			data.Currency.Credits = 20000
			t.Check("level 3 for 18,000: four bays", act(data, "UpgradeBase", { Level = 3 }, T0 + 25).Ok == true and #data.Base.Bays == 4)
			t.Equal("the launch's cap ends it", act(data, "UpgradeBase", { Level = 4 }, T0 + 26).Error, Base.Cap)
			t.Equal("2,000 Credits left", data.Currency.Credits, 2000)
			for _, bad in { {}, { Level = "4" }, { Level = 3.5 }, { Level = 0 / 0 }, { Level = math.huge } } :: { any } do
				t.Equal(`hostile level {tostring(bad.Level)}`, act(data, "UpgradeBase", bad, T0 + 27).Error, Base.BadArgs)
			end
			t.Equal("no arguments at all", act(data, "UpgradeBase", nil, T0 + 27).Error, Base.BadArgs)
			saves(t, data, "after the base's levels")
		end,
	},
	{
		Name = "Base: TR21, a machine's next level for its Credits, never past the base's ceiling; the Breaker's third chamber joins at 8 and takes the line's next",
		Run = function(t: any)
			local data = fresh()
			data.Currency.Credits = 100000
			local bay = act(data, "UpgradeMachine", { Machine = "Bay", Bay = 1, Level = 2 }, T0 + 10, "op-bay")
			t.Check("bay 1 to level 2 for 170", bay.Ok == true and bay.Bay == 1 and bay.Spent == 170 and data.Base.Bays[1].Level == 2, `{bay.Error}`)
			t.Equal("bay 2 untouched", data.Base.Bays[2].Level, 1)
			local _, changed = act(data, "UpgradeMachine", { Machine = "Bay", Bay = 1, Level = 2 }, T0 + 11, "op-bay")
			t.Equal("the same op again: once", changed, false)
			t.Equal("a second tap: refused", act(data, "UpgradeMachine", { Machine = "Bay", Bay = 1, Level = 2 }, T0 + 12).Error, Base.Stale)
			t.Equal("level 3 waits for the base's level 2", act(data, "UpgradeMachine", { Machine = "Bay", Bay = 1, Level = 3 }, T0 + 13).Error, Base.Ceiling)
			t.Equal("only 170 spent", data.Currency.Credits, 100000 - 170)
			for label, bad in {
				["a bay not open"] = { Machine = "Bay", Bay = 3, Level = 2 },
				["a bay with no number"] = { Machine = "Bay", Level = 2 },
				["the Training machine has no level"] = { Machine = "Training", Level = 2 },
				["the Breaker with a bay"] = { Machine = "Breaker", Bay = 1, Level = 2 },
				["a level that is no number"] = { Machine = "Breaker", Level = "2" },
			} :: { [string]: any } do
				t.Equal(label, act(data, "UpgradeMachine", bad, T0 + 14).Error, Base.BadArgs)
			end
			data.Base.Level = 3
			data.Base.Machines.Breaker = 7
			data.Bag.Shards[STANDARD] = 3
			for _ = 1, 3 do
				act(data, "AddShard", { Shard = STANDARD }, T0 + 15)
			end
			t.Check("two chambers busy, one waiting", #data.Base.Chambers == 2 and #data.Base.Line == 1)
			local credits = data.Currency.Credits
			local breaker = act(data, "UpgradeMachine", { Machine = "Breaker", Level = 8 }, T0 + 16)
			t.Check("the Breaker to 8 for 2,400", breaker.Ok == true and breaker.Spent == 2400 and data.Base.Machines.Breaker == 8, `{breaker.Error}`)
			t.Equal("its Credits spent", data.Currency.Credits, credits - 2400)
			t.Equal("a third chamber", #data.Base.Chambers, 3)
			local third = data.Base.Chambers[3].Work
			t.Check("which took the line's shard", third ~= nil and third.Def == STANDARD and #data.Base.Line == 0)
			data.Base.Machines.Breaker = 14
			t.Check("at 15, the top base level's ceiling, still three chambers: the fourth (20) waits for a base level past launch", act(data, "UpgradeMachine", { Machine = "Breaker", Level = 15 }, T0 + 17).Ok == true and #data.Base.Chambers == 3)
			t.Equal("15 is the last at launch", act(data, "UpgradeMachine", { Machine = "Breaker", Level = 16 }, T0 + 18).Error, Base.Cap)
			saves(t, data, "after the machines' levels")
		end,
	},
	{
		Name = "Base: TR21, a bay's level raises its worker's kW, the Breaker's its speed and draw alike so a shard costs the same kWh, and the battery holds its base level's cap",
		Run = function(t: any)
			local data = withRook()
			local watt = Collection.Uncover(data, "watt", T0 + 50).Id
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 50)
			local kw = Power.Generation(data)
			data.Base.Bays[1].Level = 26
			t.Check("a bay at 26 generates twice", kw > 0 and math.abs(Power.Generation(data) - 2 * kw) < 1e-9, `{Power.Generation(data)} against {kw}`)
			t.Equal("the battery at level 1", Breaker.Capacity(data.Base), 60)
			data.Base.Level = 2
			t.Equal("at level 2", Breaker.Capacity(data.Base), 150)
			-- One shard, no worker and a battery deep enough, at the Breaker's level 1 and 11.
			local seconds, kwh = Power.Cost(STANDARD)
			local function run(level: number, after: number): (Profile.Data, number)
				local base = fresh()
				base.Base.Level = 3
				base.Base.Machines.Breaker = level
				base.Base.Condenser.Tray.Low = Condenser.Cap(1) -- the Stone Condenser rests on a full tray: the Breaker's kWh alone
				base.Base.Charge = 300
				base.Bag.Shards[STANDARD] = 1
				act(base, "AddShard", { Shard = STANDARD }, T0)
				Breaker.Advance(base, T0 + after)
				return base, 300 - base.Base.Charge
			end
			local slow, slowKwh = run(1, (seconds :: number) + 1)
			local fast, fastKwh = run(11, (seconds :: number) / 1.2 + 1)
			t.Check("level 1 breaks it in its time", #slow.Base.Ready == 1)
			t.Check("level 11 in a sixth less", #fast.Base.Ready == 1)
			local early = run(11, (seconds :: number) / 1.2 - 5)
			t.Check("and not before", #early.Base.Ready == 0)
			t.Check("the same kWh either way", math.abs(fastKwh - slowKwh) < 1e-6 and math.abs(slowKwh - (kwh :: number)) < 1e-6, `{fastKwh}, {slowKwh}, {kwh}`)
			t.Check("the Breaker's speed shown", math.abs(Breaker.Rates(early).Speed - 1.2) < 1e-9, `{Breaker.Rates(early).Speed}`)
		end,
	},
	{
		Name = "Base (section 9): the shard's whole way, seeded, repeated and cut short in any order, never makes or loses a shard or a fighter",
		Run = function(t: any)
			local seed = 20261121
			local function roll(n: number): number -- Park-Miller, exact in doubles: the same steps every run
				seed = (seed * 16807) % 2147483647
				return seed % n + 1
			end
			local KEEP = 8 -- short, so ids leave the ledger and come back as new requests
			local data = fresh()
			data.Base.Charge = Breaker.Capacity(data.Base) -- full power, so shards finish inside the run
			data.Bag.Shards[STANDARD] = 14
			data.Bag.Shards.named_watt = 3
			data.Bag.Shards.starter_pip = 1
			local DEFS = { STANDARD, STANDARD, STANDARD, "named_watt", "starter_pip" }
			local function shards(of: Profile.Data?): number
				local d = of or data
				local held = #d.Base.Line + #d.Base.Ready
				for _, n in d.Bag.Shards do
					held += n
				end
				for _, chamber in d.Base.Chambers do
					held += if chamber.Work then 1 else 0
				end
				return held
			end
			local function found(): number
				local n = 0
				for _, entry in data.Index do
					n += entry.Count
				end
				return n
			end
			-- The fighters: each kind owned once, every find a new one or a copy, the lead owned and in no bay, no one in two.
			local function fighters(): string?
				local kinds, copies, owned = {}, 0, 0
				for id, v in data.Voidkin do
					if kinds[v.Def] then
						return `{v.Def} owned twice`
					end
					kinds[v.Def] = id
					copies += v.Copies
					owned += 1
				end
				if owned + copies ~= found() then
					return `{owned} owned and {copies} copies for {found()} found`
				end
				local lead = data.Roles.Lead
				if lead ~= "" and data.Voidkin[lead] == nil then
					return "a lead not owned"
				end
				local placed: { [string]: boolean } = {}
				for _, bay in data.Base.Bays do
					if bay.Worker ~= "" then
						if placed[bay.Worker] or bay.Worker == lead or data.Voidkin[bay.Worker] == nil then
							return `{bay.Worker} placed wrong`
						end
						placed[bay.Worker] = true
					end
				end
				return nil
			end
			local function owned(): string
				local ids = {}
				for id in data.Voidkin do
					table.insert(ids, id)
				end
				table.sort(ids)
				return if #ids == 0 then "" else ids[roll(#ids)]
			end
			local whole = shards() + found()
			local held: { string } = {}
			local sent: { [string]: { Name: string, Args: any, U: number } } = {}
			local now = T0
			local opened, repeats, cuts, broken = 0, 0, 0, 0
			for step = 1, 300 do
				now += roll(90) - 1
				local op = string.format("%08x-0000-4000-8000-%012x", roll(24), 1)
				local ask = sent[op]
				if ask == nil then
					local pick = roll(10)
					if pick <= 3 then
						ask = { Name = "AddShard", Args = { Shard = DEFS[roll(#DEFS)] }, U = 0.5 }
					elseif pick <= 6 then
						ask = { Name = "Open", Args = if roll(2) == 1 then {} else { Index = roll(3) }, U = (roll(999) - 0.5) / 999 }
					elseif pick == 7 then
						ask = { Name = "TakeOut", Args = { Chamber = roll(#data.Base.Chambers) }, U = 0.5 }
					elseif pick <= 9 then
						local worker = data.Base.Bays[roll(#data.Base.Bays)].Worker -- a worker a third of the time: a move between bays
						local who = if roll(4) == 1 then "" elseif worker ~= "" and roll(3) == 1 then worker else owned()
						ask = { Name = "SetWorker", Args = { Bay = roll(#data.Base.Bays), Voidkin = who }, U = 0.5 }
					else
						local worker = data.Base.Bays[roll(#data.Base.Bays)].Worker -- a worker half the time: the lead's recall
						ask = { Name = "SetLead", Args = { Voidkin = if worker ~= "" and roll(2) == 1 then worker else owned() }, U = 0.5 }
					end
					sent[op] = ask
				end
				local action = Base.Actions[ask.Name] or Collection.Actions[ask.Name]
				local cut = roll(6) == 1 -- the server falls over after the action, before its change finishes
				local before = Profile.DeepCopy(data)
				local answer, changed = Transaction.Run(data, op, function(draft: Profile.Data): any
					local done = action(draft, ask.Args, now, ask.U)
					if cut then
						error("interrupted")
					end
					return done
				end, KEEP)
				local again = table.find(held, op) ~= nil
				if again or cut then
					if again then
						repeats += 1
					else
						cuts += 1
					end
					if changed or data.Base.Stamp ~= before.Base.Stamp or shards() ~= shards(before) or count(data.Voidkin) ~= count(before.Voidkin) or #data.Ops.Order ~= #before.Ops.Order then
						broken += 1
						t.Check(`step {step}: a {if again then "repeat" else "cut"} of {ask.Name} changes nothing`, false)
					end
				elseif answer.Ok == true then
					if ask.Name == "Open" then
						opened += 1
					end
					table.insert(held, op)
					if #held > KEEP then
						sent[table.remove(held, 1) :: string] = nil -- its next use is a new request
					end
				end
				local wrong = fighters()
				if shards() + found() ~= whole or wrong then
					broken += 1
					t.Check(`step {step} ({ask.Name}): every shard is still a shard or one find`, false, wrong or `{shards()} + {found()} against {whole}`)
					break
				end
			end
			t.Equal("no step made or lost anything", broken, 0)
			t.Check(`the run opened ({opened}), repeated ({repeats}) and was cut ({cuts}) often`, opened >= 8 and repeats >= 20 and cuts >= 20)
			saves(t, data, "after the run")
		end,
	},
}
