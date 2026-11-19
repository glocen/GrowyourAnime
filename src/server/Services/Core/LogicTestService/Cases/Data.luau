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
		Name = "Data: step 3 takes the stat board's points out of a save, and a save from before the board passes clean",
		Run = function(t: any)
			-- The director's word, 2026-11-14, night: "Remove now, tree later" (TR15's board out of the game).
			local spent = fresh()
			spent.Version = 2
			spent.Voidkin.a = { Id = "a", Def = "rook", Level = 9, Points = { Health = 3, Regen = 5 } } :: any
			spent.Voidkin.b = { Id = "b", Def = "pip", Level = 1, Points = {} } :: any
			local ran = Migrations.Run(spent)
			t.Equal("one step ran", ran, Migrations.Latest - 2)
			t.Check("the points spent are gone", (spent.Voidkin.a :: any).Points == nil and (spent.Voidkin.b :: any).Points == nil)
			t.Equal("the rest kept", (spent.Voidkin.a :: any).Level, 9)
			local older = fresh()
			older.Version = 1
			older.Voidkin.c = { Id = "c", Def = "rook", Level = 4 } :: any
			Migrations.Run(older)
			t.Check("a save from before the board has none", (older.Voidkin.c :: any).Points == nil)
			t.Equal("at the latest", older.Version, Migrations.Latest)
		end,
	},
	{
		Name = "Data: step 6 gives each preset its class pairs and moves a hand in Slots under its item's class",
		Run = function(t: any)
			-- TR26's class rules: Hands holds each class's pair; Slots keeps the twelve shared slots only.
			local old = fresh()
			old.Version = 5
			old.Items.s = { Id = "s", Def = "sword", Tier = 1, Rarity = "Common", Design = 1, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
			old.Items.h = { Id = "h", Def = "helmet", Tier = 1, Rarity = "Common", Design = 1, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
			old.Presets = {
				{ Slots = { ["Main Hand"] = "s", ["Off Hand"] = "gone", Helmet = "h" } },
				{ Slots = { ["Off Hand"] = "s" } },
				{ Slots = {} },
			} :: any
			local ran = Migrations.Run(old)
			t.Equal("one step ran", ran, Migrations.Latest - 5)
			local one, two, three = old.Presets[1], old.Presets[2], old.Presets[3]
			t.Equal("the sword under the Warrior's main hand", one.Hands.Warrior and one.Hands.Warrior["Main Hand"], "s")
			t.Check("no hand left in Slots", one.Slots["Main Hand"] == nil and one.Slots["Off Hand"] == nil)
			t.Equal("the helmet kept", one.Slots.Helmet, "h")
			t.Check("a hand of a lost item goes", one.Hands.Warrior["Off Hand"] == nil)
			t.Check("a main-hand weapon found in the off hand goes", two.Slots["Off Hand"] == nil and next(two.Hands) == nil)
			t.Check("an empty preset gains its pairs", type(three.Hands) == "table" and next(three.Hands) == nil)
			local problems = Saveable.Problems(old, "profile")
			t.Check("still saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Data: step 8 turns the five retired attributes' lines into Strength and Endurance, merged, nothing else moved (TR36)",
		Run = function(t: any)
			local old = fresh()
			old.Version = 7
			local function item(id: string, lines: { any }): any
				return { Id = id, Def = "sword", Tier = 1, Rarity = "Rare", Design = 1, Lines = lines, Sockets = {}, Reinforce = 0, Jewels = {} }
			end
			old.Items.a = item("a", { { Stat = "Attack", Value = 30 }, { Stat = "Might", Value = 4 }, { Stat = "Finesse", Value = 6 }, { Stat = "Spirit", Value = 2 } })
			old.Items.b = item("b", { { Stat = "Vigor", Value = 9 }, { Stat = "Critical", Value = 12 }, { Stat = "Insight", Value = 5 } })
			old.Items.c = item("c", { { Stat = "Health", Value = 100 } })
			old.Items.d = item("d", { { Stat = "Strength", Value = 3 }, { Stat = "Might", Value = 2 } })
			local ran = Migrations.Run(old)
			t.Equal("one step ran", ran, Migrations.Latest - 7)
			local function lines(id: string): string
				local out = {}
				for _, line in old.Items[id].Lines do
					table.insert(out, `{line.Stat} {line.Value}`)
				end
				return table.concat(out, ", ")
			end
			t.Equal("Might and Finesse merge into Strength in the first one's place, Spirit becomes Endurance", lines("a"), "Attack 30, Strength 10, Endurance 2")
			t.Equal("Vigor becomes Endurance, Insight Strength, the order kept", lines("b"), "Endurance 9, Critical 12, Strength 5")
			t.Equal("an item with none is untouched", lines("c"), "Health 100")
			t.Equal("an old line joins a new one already there", lines("d"), "Strength 5")
			for old_, new in Migrations.OldAttributes do
				t.Check(`{old_} becomes one of the two`, new == "Strength" or new == "Endurance", new)
			end
			local problems = Saveable.Problems(old, "profile")
			t.Check("still saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Data: step 9 keeps the bays a base's level opens, 2, 3 and 4, its first ones, its Voidkin still owned (D5)",
		Run = function(t: any)
			local function base(level: number, bays: number): any
				local old = fresh()
				old.Version = 8
				old.Base.Level = level
				old.Base.Bays = {}
				for index = 1, bays do
					table.insert(old.Base.Bays, { Worker = `w{index}`, Level = index })
				end
				return old
			end
			local three = base(3, 6)
			local owned = 0
			for _ in three.Voidkin do
				owned += 1
			end
			t.Equal("one step ran", Migrations.Run(three), Migrations.Latest - 8)
			t.Equal("level 3 keeps four", #three.Base.Bays, 4)
			t.Equal("its first ones, as they were", `{three.Base.Bays[1].Worker} {three.Base.Bays[4].Worker} {three.Base.Bays[4].Level}`, "w1 w4 4")
			local count = 0
			for _ in three.Voidkin do
				count += 1
			end
			t.Equal("no Voidkin goes", count, owned)
			local two = base(2, 4)
			Migrations.Run(two)
			t.Equal("level 2 keeps three", #two.Base.Bays, 3)
			local one = base(1, 2)
			Migrations.Run(one)
			t.Equal("level 1's two untouched", #one.Base.Bays, 2)
			local fewer = base(3, 3)
			Migrations.Run(fewer)
			t.Equal("fewer than its level opens: none added here (the level's rule adds them)", #fewer.Base.Bays, 3)
			local problems = Saveable.Problems(three, "profile")
			t.Check("still saves whole", #problems == 0, table.concat(problems, "; "))
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
