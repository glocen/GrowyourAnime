--!strict
-- Logic cases (pure): the Play panel's cards (Rules.Modes; the director, 2026-11-24). Two modes, the Festival first; its
-- press goes where the player would go next, through the stages' own rules; the Tower's press points the way at home and
-- says why anywhere else, or while a climb is under way. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Grounds = require(Shared.Definitions.Grounds)
local Stages = require(Shared.Rules.Stages)
local Modes = require(Shared.Rules.Modes)

local NOW = 1_800_000_000
local GROUND = Grounds.First
local COUNT = #(Stages.Of(GROUND) :: { any })

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- Clears `count` more stretches of `which` on `data`, from its checkpoint, through the stages' own rules.
local function clear(data: Profile.Data, which: string, count: number)
	for _ = 1, count do
		local stage = Stages.Checkpoint(data, GROUND, which)
		local run = Stages.Start(data, GROUND, which, stage, NOW) :: Stages.Run
		local row = (Stages.Of(GROUND) :: any)[stage]
		local pack: string? = nil
		for _, stop in row.Stops do
			pack = if stop.Kind == "Pack" then stop.Def else pack
		end
		for _ = 1, row.Quota do
			Stages.Kill(run, pack :: string)
		end
		Stages.Kill(run, Stages.DefOn(Stages.Last(GROUND, stage) :: any, which))
		Stages.Clear(data, run, NOW + 60)
	end
end

local function card(data: Profile.Data, id: string, home: boolean): Modes.Card
	for _, each in Modes.Cards(data, GROUND, home) do
		if each.Id == id then
			return each
		end
	end
	error(`no card {id}`)
end

return {
	{
		Name = "Modes: Play shows two modes, the Festival first, and never one that isn't built",
		Run = function(t: any)
			local cards = Modes.Cards(fresh(), GROUND, true)
			t.Equal("two cards", #cards, 2)
			t.Equal("the Festival first", cards[1].Id, "Festival")
			t.Equal("then the Tower", cards[2].Id, "Tower")
			local seen: { [string]: boolean } = {}
			for _, each in cards do
				t.Check(`{each.Id}: its id once`, not seen[each.Id])
				seen[each.Id] = true
				t.Check(`{each.Id}: a title, a line, where the player stands and a press`, each.Title ~= "" and each.Line ~= "" and each.Says ~= "" and each.Press ~= "")
				t.Check(`{each.Id}: its press does something the panel knows`, each.Does == Modes.Begin or each.Does == Modes.Ring)
				t.Check(`{each.Id}: no line too long for a card`, #each.Line <= 48 and #each.Press <= 18)
			end
			t.Check("the same cards away from home", #Modes.Cards(fresh(), GROUND, false) == 2)
		end,
	},
	{
		Name = "Modes: the Festival's press goes where the player would go next, and only where the stages' rules open",
		Run = function(t: any)
			local data = fresh()
			local first = card(data, "Festival", true)
			t.Check("a fresh save: Normal, Stretch 1, and the word is Fight", first.Difficulty == "Normal" and first.Stage == 1 and first.Press == "Fight" and first.Off == nil)
			t.Equal("its ground", first.Ground, GROUND)
			t.Equal("its count", first.Count, COUNT)
			t.Check("it names the ground and the stretch", string.find(first.Says, (Grounds.ById[GROUND] :: any).Name, 1, true) ~= nil and string.find(first.Says, `Stretch 1 of {COUNT}`, 1, true) ~= nil)
			t.Equal("the Arc panel a press further", first.Second, "Choose Arc")
			clear(data, "Normal", 1)
			local second = card(data, "Festival", true)
			t.Check("one stretch cleared: Continue, at the checkpoint", second.Difficulty == "Normal" and second.Stage == 2 and second.Press == "Continue")
			t.Check("the server's own way agrees", Stages.Way(data, GROUND, second.Difficulty :: string).Stage == second.Stage)
			clear(data, "Normal", COUNT - 1)
			t.Equal("Normal cleared whole", Stages.Line(data, GROUND, "Normal").Cleared, COUNT)
			local hard = card(data, "Festival", true)
			t.Check("then Hard, from its first stretch", hard.Difficulty == "Hard" and hard.Stage == 1 and hard.Press == "Fight" and hard.Off == nil)
			clear(data, "Hard", 1)
			local on = card(data, "Festival", true)
			t.Check("a Hard run under way: its checkpoint", on.Difficulty == "Hard" and on.Stage == 2 and on.Press == "Continue")
			clear(data, "Hard", COUNT - 1)
			local done = card(data, "Festival", true)
			t.Check("everything cleared: the hardest again", done.Difficulty == "Hard" and done.Off == nil)
			-- every answer along the way is one the stages' rules open
			for _, save in { fresh(), data } do
				local which, stage = Modes.Frontier(save, GROUND)
				t.Equal(`{which} {stage}: open`, Stages.Needs(save, GROUND, which, stage), nil)
			end
		end,
	},
	{
		Name = "Modes: a run under way on Normal comes before a fresh Hard",
		Run = function(t: any)
			local data = fresh()
			clear(data, "Normal", COUNT) -- Hard is open, Normal back at its first stretch
			clear(data, "Normal", 1) -- and a second Normal run reaches Stretch 2
			local which, stage = Modes.Frontier(data, GROUND)
			t.Check("Normal, Stretch 2", which == "Normal" and stage == 2)
			clear(data, "Hard", 1)
			local harder = Modes.Frontier(data, GROUND)
			t.Equal("both under way: the harder", harder, "Hard")
		end,
	},
	{
		Name = "Modes: the Tower's card shows the record, points the way at home, and says why it can't anywhere else",
		Run = function(t: any)
			local data = fresh()
			local none = card(data, "Tower", true)
			t.Check("no climb yet, and the way is open at home", none.Says == "No climb yet" and none.Off == nil and none.Does == Modes.Ring)
			data.Progress.Tower.Best = 12
			t.Equal("the record", card(data, "Tower", true).Says, "Your record: floor 12")
			local away = card(data, "Tower", false)
			t.Check("away: it says where it's climbed", away.Off ~= nil and away.Says == "Your record: floor 12")
			data.Progress.Tower.Run = { Id = "run", Floor = 3 } :: any
			t.Check("a climb under way: no second way in", card(data, "Tower", true).Off ~= nil)
			t.Check("the Tower's card never begins a Festival run", card(data, "Tower", true).Ground == nil)
		end,
	},
}
