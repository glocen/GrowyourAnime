--!strict
-- Funnel cases (pure): the first session, measured (TR32; Rules.Funnel). A first session played through logs its steps
-- once each, in order; a repeat, a retried request and a later save never log one again; a refused act, a recall and
-- taking an item off log nothing; the marks save; a save from before the funnel logs nothing. Runs in Studio (LogicTests) and with Studio closed
-- (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Funnel = require(Shared.Rules.Funnel)

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- What a server change logs: the steps an answer makes true, marked in one transaction, as FunnelService runs it.
local function after(data: Profile.Data, label: string, answer: { [string]: any }): { Funnel.Logged }
	local steps = Funnel.Of(label, answer)
	if #steps == 0 then
		return {}
	end
	local marked, changed = Transaction.Run(data, nil, function(draft: Profile.Data): any
		return Funnel.Mark(draft, steps)
	end, 8)
	return if changed then marked.Logged :: { Funnel.Logged } else {}
end

local function numbers(logged: { Funnel.Logged }): string
	local said = {}
	for _, step in logged do
		table.insert(said, `{step.Step} {step.Name}`)
	end
	return table.concat(said, ", ")
end

-- A first session's acts and their answers, as the server's rules answer them, in the north star's order.
local SESSION: { { Label: string, Answer: { [string]: any } } } = {
	{ Label = "ChooseStarter", Answer = { Ok = true, Shard = "starter_rook" } },
	{ Label = "Open", Answer = { Ok = true, Id = "k1", Def = "rook", Lead = true, Shard = "starter_rook" } },
	{ Label = "Drop", Answer = { Ok = true, Credits = 12, Xp = 5, Shard = "", First = "named_watt", Chest = "", Kills = 1 } },
	{ Label = "SetWorker", Answer = { Ok = true, Bay = 1, Voidkin = "k2" } },
	{ Label = "Equip", Answer = { Ok = true, Preset = 1, Slot = "Ring", Class = "", Item = "k3" } },
}

return {
	{
		Name = "Funnel: eight steps in the north star's order, each its number",
		Run = function(t: any)
			t.Equal("eight", #Funnel.Steps, 8)
			local order = { "Arrive", "Choose", "Reveal", "Fight", "Find", "Work", "Build", "Want" }
			for index, name in order do
				t.Equal(`{name} is step {index}`, Funnel.Number[name], index)
			end
			t.Check("a new save has none marked", next(fresh().Funnel) == nil)
		end,
	},
	{
		Name = "Funnel: a first session played through logs each step once, in order; played again, nothing",
		Run = function(t: any)
			local data = fresh()
			local logged: { Funnel.Logged } = {}
			local function take(more: { Funnel.Logged })
				for _, step in more do
					table.insert(logged, step)
				end
			end
			local arrive = Funnel.Mark(data, { "Arrive" })
			take(arrive.Logged)
			for _, act in SESSION do
				take(after(data, act.Label, act.Answer))
			end
			take((Funnel.Mark(data, { "Want" }) :: any).Logged or {})
			t.Equal("steps 1 to 8, once each, in order", numbers(logged), "1 Arrive, 2 Choose, 3 Reveal, 4 Fight, 5 Find, 6 Work, 7 Build, 8 Want")
			local again: { Funnel.Logged } = {}
			for _, act in SESSION do
				for _, step in after(data, act.Label, act.Answer) do
					table.insert(again, step)
				end
			end
			t.Equal("the same acts again: nothing", numbers(again), "")
			t.Equal("a rejoin: no Arrive", Funnel.Mark(data, { "Arrive" }).Error, Funnel.Marked)
			t.Equal("the gate again: no Want", Funnel.Mark(data, { "Want" }).Error, Funnel.Marked)
		end,
	},
	{
		Name = "Funnel: a refused act, a recall, an item taken off and a later kill log nothing; a mark refused changes nothing",
		Run = function(t: any)
			local data = fresh()
			t.Equal("a refused pick", numbers(after(data, "ChooseStarter", { Ok = false, Error = "Chosen" })), "")
			t.Equal("a recall from a bay", numbers(after(data, "SetWorker", { Ok = true, Bay = 1, Voidkin = "" })), "")
			t.Equal("an item taken off", numbers(after(data, "Equip", { Ok = true, Preset = 1, Slot = "Ring", Item = "" })), "")
			t.Equal("an act the funnel doesn't read", numbers(after(data, "ShopBuy", { Ok = true })), "")
			t.Equal("a kill with no Named shard: Fight alone", numbers(after(data, "Drop", { Ok = true, First = "", Kills = 1 })), "4 Fight")
			t.Equal("the Named shard later still logs Find", numbers(after(data, "Drop", { Ok = true, First = "named_watt", Kills = 2 })), "5 Find")
			local before = Profile.DeepCopy(data)
			local answer, changed = Transaction.Run(data, nil, function(draft: Profile.Data): any
				return Funnel.Mark(draft, { "Fight" })
			end, 8)
			t.Check("a mark of a marked step is refused and changes nothing", answer.Error == Funnel.Marked and not changed and data.Funnel.Fight == true and next(before.Funnel) ~= nil)
			t.Equal("an unknown step marks nothing", Funnel.Mark(data, { "Nowhere" }).Error, Funnel.Marked)
		end,
	},
	{
		Name = "Funnel: the marks save, and an old save without them takes an empty set",
		Run = function(t: any)
			local data = fresh()
			Funnel.Mark(data, { "Arrive", "Choose" })
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save with its marks is saveable", #problems == 0, problems[1])
			t.Check("the template carries the set", type(Profile.Template().Funnel) == "table")
		end,
	},
	{
		Name = "Funnel: step 10, a save that played before the funnel has every step marked; a new account none",
		Run = function(t: any)
			local old = Profile.Template()
			Migrations.Run(old)
			old.Version = 9
			old.Progress.Starter = "starter_rook"
			old.Funnel = nil :: any -- a save from before the field, before Reconcile adds it
			Migrations.Run(old)
			local marked = 0
			for _, name in Funnel.Steps do
				marked += if old.Funnel[name] == true then 1 else 0
			end
			t.Equal("an old save that chose its starter: all eight marked", marked, 8)
			t.Equal("so its next act logs nothing", numbers(after(old, "Equip", { Ok = true, Item = "k3" })), "")
			local joined = Profile.Template()
			Migrations.Run(joined)
			joined.Version = 9
			joined.Funnel = {}
			Migrations.Run(joined)
			t.Check("an old save that never chose: none marked, it logs as it plays", next(joined.Funnel) == nil)
			t.Equal("a new account reaches the latest version", fresh().Version, Migrations.Latest)
		end,
	},
}
