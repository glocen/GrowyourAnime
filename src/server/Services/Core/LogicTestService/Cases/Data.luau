--!strict
-- Data cases (pure): the profile's shape saves whole, migrations run once and refuse a newer save, and a transaction is
-- all or nothing: a refusal, an error half way, or a repeated operation id changes nothing.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)

local KEEP = 8
local OP = "0f8fad5b-d9cb-469f-a165-70867728950e"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- The same profile, compared through its saved form.
local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function credit(amount: number): Transaction.Change
	return function(draft: Profile.Data): Transaction.Answer
		draft.Currency.Credits += amount
		return { Ok = true, Credits = draft.Currency.Credits }
	end
end

return {
	{
		Name = "Data: the template saves whole",
		Run = function(t: any)
			local problems = Saveable.Problems(fresh(), "profile")
			t.Check("no problems", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Data: Saveable finds what a save loses",
		Run = function(t: any)
			t.Check("a gap", #Saveable.Problems({ 1, nil, 3 }) > 0)
			t.Check("mixed keys", #Saveable.Problems({ 1, Name = "x" }) > 0)
			t.Check("a function", #Saveable.Problems({ F = function() end }) > 0)
			t.Check("not a number", #Saveable.Problems({ N = 0 / 0 }) > 0)
			t.Check("infinity", #Saveable.Problems({ N = math.huge }) > 0)
			t.Check("a number key", #Saveable.Problems({ [2.5] = true }) > 0)
			local shared = {}
			t.Check("one table twice", #Saveable.Problems({ A = shared, B = shared }) > 0)
			t.Check("deep down", #Saveable.Problems({ A = { B = { C = { 1, nil, 3 } } } }) > 0)
			t.Equal("a clean nest", #Saveable.Problems({ A = { 1, 2 }, B = { C = "x", D = true } }), 0)
			t.Equal("empty tables", #Saveable.Problems({ A = {}, B = { {} } }), 0)
		end,
	},
	{
		Name = "Data: migrations run once, to the latest",
		Run = function(t: any)
			local data = Profile.Template()
			t.Equal("a template starts at 0", data.Version, 0)
			local ran, known = Migrations.Run(data)
			t.Equal("every step ran", ran, Migrations.Latest)
			t.Check("known", known)
			t.Equal("at the latest", data.Version, Migrations.Latest)
			local again = Migrations.Run(data)
			t.Equal("nothing runs twice", again, 0)
		end,
	},
	{
		Name = "Data: a newer save is left alone",
		Run = function(t: any)
			local data = fresh()
			data.Version = Migrations.Latest + 1
			local before = Profile.DeepCopy(data)
			local ran, known = Migrations.Run(data)
			t.Equal("nothing ran", ran, 0)
			t.Check("reported unknown", not known)
			t.Check("unchanged", same(data, before))
		end,
	},
	{
		Name = "Data: a change commits",
		Run = function(t: any)
			local data = fresh()
			local answer, changed = Transaction.Run(data, OP, credit(5), KEEP)
			t.Check("ok", answer.Ok == true)
			t.Check("changed", changed)
			t.Equal("credits", data.Currency.Credits, 5)
			t.Check("the op is held", (data.Ops.Answers :: any)[OP] ~= nil)
			local problems = Saveable.Problems(data, "profile")
			t.Check("still saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Data: a repeated op gets its first answer and changes nothing",
		Run = function(t: any)
			local data = fresh()
			local first = Transaction.Run(data, OP, credit(5), KEEP)
			local before = Profile.DeepCopy(data)
			local second, changed = Transaction.Run(data, OP, credit(5), KEEP)
			t.Check("not changed", not changed)
			t.Equal("the first answer", second.Credits, first.Credits)
			t.Equal("paid once", data.Currency.Credits, 5)
			t.Check("the profile is as it was", same(data, before))
		end,
	},
	{
		Name = "Data: a refusal changes nothing",
		Run = function(t: any)
			local data = fresh()
			local before = Profile.DeepCopy(data)
			local answer, changed = Transaction.Run(data, OP, function(draft: Profile.Data): Transaction.Answer
				draft.Currency.Credits += 100 -- touched, then refused: the draft is thrown away
				return { Ok = false, Error = "NotEnough" }
			end, KEEP)
			t.Check("refused", answer.Ok == false and answer.Error == "NotEnough")
			t.Check("not changed", not changed)
			t.Check("the profile is as it was", same(data, before))
			t.Check("a refusal isn't held", (data.Ops.Answers :: any)[OP] == nil)
		end,
	},
	{
		Name = "Data: a change that errors half way changes nothing",
		Run = function(t: any)
			local data = fresh()
			local before = Profile.DeepCopy(data)
			local answer, changed, failure = Transaction.Run(data, OP, function(draft: Profile.Data): Transaction.Answer
				draft.Currency.Credits += 100
				draft.Bag.Shards.anything = 3
				error("a bug in the middle of a change")
			end, KEEP)
			t.Equal("failed", answer.Error, Transaction.Failed)
			t.Check("not changed", not changed)
			t.Check("the error is reported", failure ~= nil and string.find(failure, "a bug", 1, true) ~= nil)
			t.Check("the profile is as it was", same(data, before))
			local retry = Transaction.Run(data, OP, credit(5), KEEP)
			t.Check("its op id is still free", retry.Ok == true and data.Currency.Credits == 5)
		end,
	},
	{
		Name = "Data: a change that waits is refused and changes nothing",
		Run = function(t: any)
			-- Committed after a wait, it would undo whatever another change committed meanwhile.
			local data = fresh()
			local before = Profile.DeepCopy(data)
			local answer, changed, failure = Transaction.Run(data, OP, function(draft: Profile.Data): Transaction.Answer
				draft.Currency.Credits += 100
				coroutine.yield()
				return { Ok = true }
			end, KEEP)
			t.Equal("failed", answer.Error, Transaction.Failed)
			t.Check("not changed", not changed)
			t.Check("the yield is reported", failure ~= nil and string.find(failure, "yielded", 1, true) ~= nil)
			t.Check("the profile is as it was", same(data, before))
		end,
	},
	{
		Name = "Data: a malformed op id is refused",
		Run = function(t: any)
			local data = fresh()
			local before = Profile.DeepCopy(data)
			local answer, changed = Transaction.Run(data, "../x", credit(5), KEEP)
			t.Equal("bad op", answer.Error, Transaction.BadOp)
			t.Check("not changed", not changed and same(data, before))
		end,
	},
	{
		Name = "Data: a server change keeps no op",
		Run = function(t: any)
			local data = fresh()
			local answer, changed = Transaction.Run(data, nil, credit(5), KEEP)
			t.Check("ok and changed", answer.Ok == true and changed)
			t.Equal("no op held", #data.Ops.Order, 0)
		end,
	},
	{
		Name = "Data: an answer that points into the profile still saves whole",
		Run = function(t: any)
			local data = fresh()
			Transaction.Run(data, OP, function(draft: Profile.Data): Transaction.Answer
				local id = Profile.NewId(draft)
				draft.Voidkin[id] = {
					Id = id,
					Def = "rook",
					Level = 1,
					Xp = 0,
					Stars = 0,
					Copies = 0,
					Nickname = "",
					Preset = 1,
					Favourite = false,
					Locked = false,
					Born = 0,
				}
				return { Ok = true, Voidkin = draft.Voidkin[id] }
			end, KEEP)
			local problems = Saveable.Problems(data, "profile")
			t.Check("no table saved twice", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Data: ids are new each time",
		Run = function(t: any)
			local data = fresh()
			local a, b = Profile.NewId(data), Profile.NewId(data)
			t.Check("different", a ~= b)
			t.Equal("the counter moved twice", data.NextId, 3)
		end,
	},
	{
		Name = "Data: a role is read from the slot that points at it",
		Run = function(t: any)
			local data = fresh()
			data.Roles.Lead = "k1"
			data.Base.Bays[1].Worker = "k2"
			t.Equal("lead", Profile.RoleOf(data, "k1"), "Lead")
			t.Equal("worker", Profile.RoleOf(data, "k2"), "Worker")
			t.Equal("resting", Profile.RoleOf(data, "k3"), "Resting")
			t.Equal("nobody", Profile.RoleOf(data, ""), "Resting")
		end,
	},
	{
		Name = "Data: a client's copy holds no ledger and is a copy",
		Run = function(t: any)
			local data = fresh()
			Transaction.Run(data, OP, credit(5), KEEP)
			local view = Profile.View(data)
			t.Equal("no ops in the copy", #view.Ops.Order, 0)
			t.Equal("the profile keeps its op", #data.Ops.Order, 1)
			view.Currency.Credits = 999
			t.Equal("the profile is untouched", data.Currency.Credits, 5)
		end,
	},
}
