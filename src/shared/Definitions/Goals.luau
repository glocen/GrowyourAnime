--!strict
-- Goals (shared, content): today's three, the account's Next and each stretch's dare, with every word players read
-- (docs/design.md, "Goals"; docs/test-requests.md, TR54: the words research wrote and the content check passed). The rules
-- are Rules.Goals; the numbers Config.Goals. A goal's Event is what GoalService counts toward its Need; its Opens is an
-- account fact it waits for before it's ever drawn. No Roblox API: it runs with Studio closed.

local Goals = {}

-- The lists in a day's order: the card's three pips and the list's rows follow it.
Goals.Lists = { "Fight", "Base", "Roster" }

Goals.Rows = {
	{ Id = "KeepDare", List = "Fight", Text = "Keep a dare.", Event = "DareKept", Need = 1 },
	{ Id = "HardStretch", List = "Fight", Text = "Clear a stretch on Hard.", Event = "HardStretch", Need = 1, Opens = "Hard" },
	{ Id = "TowerThree", List = "Fight", Text = "Win three Tower floors.", Event = "TowerFloor", Need = 3, Opens = "Tower" },
	{ Id = "Lamplighter", List = "Fight", Text = "Bring down the Lamplighter.", Event = "Keeper", Need = 1 },
	-- seconds: every bay the base holds working at once, counted as the base runs, online and away
	{ Id = "BaysHour", List = "Base", Text = "Let every bay run a full hour.", Event = "BaysSeconds", Need = 3600 },
	{ Id = "ThreeShards", List = "Base", Text = "Break three shards.", Event = "ShardBroken", Need = 3 },
	{ Id = "CondenserTray", List = "Base", Text = "Collect the Condenser's tray.", Event = "TrayCollected", Need = 1, Opens = "Condenser" },
	-- seconds a Voidkin trains, any of them
	{ Id = "TrainHour", List = "Base", Text = "Train a Voidkin for an hour.", Event = "TrainSeconds", Need = 3600 },
	-- a run led by a Voidkin that hasn't led one today (Rules.Goals.Led)
	{ Id = "NewLead", List = "Roster", Text = "Lead a run with someone new.", Event = "NewLead", Need = 1 },
	{ Id = "LevelUp", List = "Roster", Text = "Raise a Voidkin a level.", Event = "LevelUp", Need = 1 },
	{ Id = "ForgeOnce", List = "Roster", Text = "Forge once.", Event = "Forge", Need = 1, Opens = "Forge" },
} :: { any }

Goals.ById = {} :: { [string]: any }
for _, row in Goals.Rows do
	Goals.ById[row.Id] = row
end

-- Next: the first step not done (Rules.Goals.Next), its Text then what it Opens, each one row at the list's head. A step
-- says only what launch opens: Config.Base's bays and caps, Config.Condenser.Wakes, Config.Chests' keeper chests (the
-- logic case "Goals: each Next line says what the config opens" holds them to it). The last line has no Fact.
Goals.Next = {
	{ Text = "Bring down the Lamplighter.", Opens = "Hard opens on Lantern Row.", Fact = "Keeper" },
	{ Text = "Raise the base to level 2.", Opens = "A third bay opens, and the Condenser wakes.", Fact = "BaseLevel", AtLeast = 2 },
	{ Text = "Bring down the Lamplighter on Hard.", Opens = "Its first chest holds a Rare or better.", Fact = "KeeperHard" },
	{ Text = "Raise the base to level 3.", Opens = "A fourth bay opens. Machines reach level 30.", Fact = "BaseLevel", AtLeast = 3 },
	{ Text = "Climb the Tower to floor 25.", Opens = "Each new floor pays a first-time bonus.", Fact = "TowerBest", AtLeast = 25 },
	{ Text = "Drum Court's gate stays shut, for now." },
} :: { any }

-- A stretch's dare, by its stage on Lantern Row (Config.World's Row): each stretch asks its own question (F2). Needs: the
-- piece it waits for (Config.Goals.Ready); until it's in, the stretch takes the fallback.
Goals.Dares = {
	{ Id = "AboveHalf", Text = "Finish with your lead above half.", Kind = "Above", Event = "Health", Share = 0.5 },
	{ Id = "BreakShield", Text = "Break a raised shield with your signature.", Kind = "Do", Event = "SignatureBreak", Needs = "Guard" },
	{ Id = "NoLine", Text = "Let no Dasher's line touch you.", Kind = "Avoid", Event = "LineHit", Needs = "Dasher" },
	{ Id = "OutsideSlams", Text = "Stand outside every slam.", Kind = "Avoid", Event = "SlamHit", Needs = "Slam" },
} :: { any }
Goals.Fallback = { Id = "NoFall", Text = "Finish without your lead falling.", Kind = "Avoid", Event = "LeadFell" } :: any

Goals.Labels = {
	Today = "Today",
	Next = "Next",
	Days = { "Yesterday", "Two days ago" }, -- the banked days' headings, newest first
	Claim = "Claim",
	DareKept = "Dare kept",
}

return Goals
