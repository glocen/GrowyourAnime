--!strict
-- Base action cases (pure): every action a client may send for its base and its Voidkin, run through Transaction as the
-- server runs it. The first circuit on a fresh account, each action repeated with one op id and interrupted half way,
-- hostile arguments, one role at a time, a change of workers never reaching back in time, and a return after hours away
-- with work left partly done (the package's gates B and D, docs/test-requests.md, TR2).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local Base = require(Shared.Rules.Base)
local Collection = require(Shared.Rules.Collection)
local Shards = require(Shared.Definitions.Shards)
local BaseConfig = require(Shared.Config.Base)
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
			t.Check("making electricity", Breaker.Production(data) > 0)
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
			t.Equal("the locked bay", act(data, "SetWorker", { Bay = 2, Voidkin = "" }, T0 + 100).Error, Base.BadArgs)
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
			t.Equal("a worker can't lead", act(data, "SetLead", { Voidkin = watt }, T0 + 50).Error, Collection.Working)
			data.Base.Bays[2] = { Worker = "" } -- a second bay opened
			t.Check("moved, not doubled", act(data, "SetWorker", { Bay = 2, Voidkin = watt }, T0 + 50).Ok == true)
			t.Check("bay 1 emptied", data.Base.Bays[1].Worker == "" and data.Base.Bays[2].Worker == watt)
			t.Check("emptied by hand", act(data, "SetWorker", { Bay = 2, Voidkin = "" }, T0 + 50).Ok == true)
			t.Check("then Watt can lead", act(data, "SetLead", { Voidkin = watt }, T0 + 50).Ok == true and data.Roles.Lead == watt)
			t.Equal("Rook rests", Profile.RoleOf(data, rook), "Resting")
		end,
	},
	{
		Name = "Base: a change of workers never reaches back in time",
		Run = function(t: any)
			local data = withRook()
			data.Base.Battery = 0
			local watt = Collection.Uncover(data, "watt", T0).Id
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 100)
			local rate = Breaker.Production(data)
			act(data, "SetWorker", { Bay = 1, Voidkin = "" }, T0 + 400)
			t.Check("Watt's 300 seconds kept", math.abs(data.Base.Battery - rate * 300) < 1e-6, `{data.Base.Battery}`)
			act(data, "SetWorker", { Bay = 1, Voidkin = watt }, T0 + 1000)
			t.Check("the empty bay made nothing", math.abs(data.Base.Battery - rate * 300) < 1e-6, `{data.Base.Battery}`)
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
			local made = Breaker.Production(data) * BaseConfig.Battery.AwayHours * 3600
			local paid = 0
			for _, work in data.Base.Ready do
				paid += if work.Def == STANDARD then energy :: number else 0
			end
			t.Equal("all six broke while away", #data.Base.Ready, 6)
			t.Check("never more than was made and held", paid <= made + 20 + 1e-6, `paid {paid}, made {made}`)
			t.Equal("six in all", #data.Base.Ready + #data.Base.Line + (if data.Base.Chambers[1].Work then 1 else 0) + (if data.Base.Chambers[2].Work then 1 else 0), 6)
			t.Equal("the stamp is the return", data.Base.Stamp, away)
			local opened = act(data, "Open", {}, away + 1)
			t.Check("one opens", opened.Ok == true)
			saves(t, data, "after the return")
		end,
	},
}
