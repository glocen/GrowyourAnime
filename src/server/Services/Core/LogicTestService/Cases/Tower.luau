--!strict
-- Tower cases (pure): TR29's rules (Rules.Tower; docs/design.md, "The Tower"). Each floor's foe and its level from the
-- seed; its block lifted to the build and cut to its health share; fast floors; the heal cap; each floor's reward; and
-- the run's ledger: a floor won once and only the next, the end granting once, the record, the results kept until seen,
-- a crash's run ended at the next join. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local TowerConfig = require(Shared.Config.Tower)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local ChestRows = require(Shared.Definitions.Chests)
local Grounds = require(Shared.Definitions.Grounds)
local Voidkin = require(Shared.Definitions.Voidkin)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Tower = require(Shared.Rules.Tower)

local WorldConfig = require(Shared.Config.World)

local NOW = 1_800_000_000
local SEED = 424_242

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function own(def: string, level: number): Stats.Block
	local owned: Profile.OwnedVoidkin = { Id = "x", Def = def, Level = level, Xp = 0, Stars = 0, Copies = 0, Nickname = "", Preset = 0, Favourite = false, Locked = false, Born = 0 }
	return (Stats.Resolve(owned, nil, nil))
end

return {
	{
		Name = "Tower: a floor's foe stands at 1 + (floor - 1) x 0.5, from the run's seed, one of the Voidkin with a body",
		Run = function(t: any)
			t.Equal("floor 1", Tower.Level(1), 1)
			t.Equal("floor 2 rounds up", Tower.Level(2), 2)
			t.Equal("floor 3", Tower.Level(3), 2)
			t.Equal("floor 59", Tower.Level(59), 30)
			t.Equal("never past Growth's last level", Tower.Level(10_000), GrowthConfig.MaxLevel)
			local pool = Tower.Pool()
			t.Check("a pool", #pool >= 1)
			for _, id in pool do
				t.Check(`{id} has a body and its moves`, Voidkin.ById[id] ~= nil and Voidkin.ById[id].Model ~= nil and Voidkin.ById[id].Kit ~= nil)
			end
			for _, row in Voidkin.List do
				if row.Model and row.ClipsDue then
					t.Check(`{row.Id}: its body ahead of its clips, not yet a foe`, table.find(pool, row.Id) == nil)
				end
			end
			local seen = {}
			for floor = 1, 200 do
				local foe = Tower.Foe(floor, SEED)
				local again = Tower.Foe(floor, SEED)
				if foe.Def ~= again.Def or foe.Level ~= Tower.Level(floor) or table.find(pool, foe.Def) == nil then
					t.Check(`floor {floor}: the same foe, in the pool, at its level`, false)
				end
				seen[foe.Def] = true
			end
			for _, id in pool do
				t.Check(`{id} comes up in 200 floors`, seen[id] == true)
			end
			local differs = false
			for floor = 1, 20 do
				differs = differs or Tower.Foe(floor, SEED).Def ~= Tower.Foe(floor, SEED + 1).Def
			end
			t.Check("another seed, other foes", differs)
			local draws = 0
			for index = 1, 1000 do
				local u = Tower.Draw(SEED, index, 2)
				if u < 0 or u >= 1 then
					t.Check(`draw {index} in [0, 1)`, false)
				end
				draws += u
			end
			t.Check("draws spread round a half", math.abs(draws / 1000 - 0.5) < 0.05, `{draws / 1000}`)
		end,
	},
	{
		Name = "Tower: the ring lies on its lot's crossing end, where the sleeping Tower stood on the drawn plot",
		Run = function(t: any)
			local plots = WorldConfig.Plots
			local unit = WorldConfig.Walk
			local across, deep, behind, tower = plots.Drawn * unit, plots.Drawn * unit, plots.Behind * unit, plots.Tower * unit
			local x, z = Tower.RingSpot(across, deep, behind, tower, 1)
			-- The plan's placement: across 84, along -232 from the gate at -deep/2 (Kit.Place), so 132 in from the middle.
			t.Check("on the drawn plot, at the silhouette's place", x == 84 and z == 132, `{x}, {z}`)
			local mx = Tower.RingSpot(across, deep, behind, tower, -1)
			t.Equal("mirrored with its crossing", mx, -84)
			t.Check("its platforms stay on its lot's square", TowerConfig.Platform.Radius <= tower / 2)
		end,
	},
	{
		Name = "Tower: a foe's block is its own figure lifted to the seeds' build, its health then cut to its share",
		Run = function(t: any)
			for _, def in Tower.Pool() do
				local foe = { Def = def, Level = 30 }
				local block, base = Tower.Block(foe), own(def, 30)
				t.Check(`{def}: its health`, math.abs(block.Health - base.Health * TowerConfig.Lift.Health * TowerConfig.Health) < 1e-6)
				t.Check(`{def}: its attack`, math.abs(block.Attack - base.Attack * TowerConfig.Lift.Attack) < 1e-6)
				t.Check(`{def}: its dodge`, math.abs(block.Dodge - base.Dodge * TowerConfig.Lift.Dodge) < 1e-6)
				t.Equal(`{def}: a stat not lifted stays`, block.Lifesteal, base.Lifesteal)
				t.Check(`{def}: its class and level`, block.Class == base.Class and block.Class ~= "" and block.Level == 30 and block.Def == def)
			end
		end,
	},
	{
		Name = "Tower: a foe far under the lead is a fast floor, and its rise is the quick one",
		Run = function(t: any)
			local gap = TowerConfig.Fast.Gap
			t.Check("the gap's edge is fast", Tower.Fast(20 + gap, 20))
			t.Check("one short isn't", not Tower.Fast(20 + gap - 1, 20))
			t.Equal("a fast rise", Tower.Rise(true), TowerConfig.Fast.Rise)
			t.Equal("a rise", Tower.Rise(false), TowerConfig.Rise)
			t.Check("the quick one is quicker", TowerConfig.Fast.Rise < TowerConfig.Rise)
		end,
	},
	{
		Name = "Tower: healing in one floor tops out at the cap, and a hit is never cut",
		Run = function(t: any)
			local most = 1000
			local room = Tower.HealCap(most)
			t.Equal("the cap", room, TowerConfig.HealCap * most)
			local health = 400
			local healed = 0
			for _ = 1, 100 do
				local before = health
				health, room = Tower.Capped(health, math.min(most, health + 7), room)
				healed += health - before
			end
			t.Check("healed at most the cap", math.abs(healed - TowerConfig.HealCap * most) < 1e-6, `{healed}`)
			t.Equal("no room left", room, 0)
			local after, left = Tower.Capped(health, health + 50, 0)
			t.Check("no room, no heal", after == health and left == 0)
			local hurt, kept = Tower.Capped(500, 300, 20)
			t.Check("a hit passes whole and keeps the room", hurt == 300 and kept == 20)
		end,
	},
	{
		Name = "Tower: a hard floor's Credits rise with it, a floor past the record pays the bonus, its chest is the Tower's own of its ground, and a fast floor pays nothing",
		Run = function(t: any)
			local last = 0
			for floor = 1, 120 do
				local reward = Tower.Reward(floor, 10_000, SEED)
				local want = math.floor(DropsConfig.CreditsPerKillPerG * Growth.G(Tower.Level(floor)) * TowerConfig.Credits.Share + 0.5)
				if reward.Credits ~= want or reward.Credits < last then
					t.Check(`floor {floor}: its Credits, never fewer than the floor below's`, false, `{reward.Credits}, {want}`)
				end
				last = reward.Credits
				if reward.Chest then
					local ground = Grounds.List[Growth.GroundOf(Tower.Level(floor))]
					local row = ChestRows.ById[reward.Chest]
					t.Check(`floor {floor}: the Tower's chest of its foe's ground`, row ~= nil and row.Ground == ground.Id and row.Tier == ChestRows.Tower)
				end
				local same = Tower.Reward(floor, 10_000, SEED, false)
				if same.Credits ~= reward.Credits or same.Chest ~= reward.Chest then
					t.Check(`floor {floor}: the same seed, the same reward`, false)
				end
				local fast = Tower.Reward(floor, 0, SEED, true)
				if fast.Credits ~= 0 or fast.Chest ~= nil then
					t.Check(`floor {floor}: a fast floor pays nothing, past the record or not`, false, `{fast.Credits}, {fast.Chest}`)
				end
			end
			local plain, record = Tower.Reward(30, 30, SEED), Tower.Reward(30, 29, SEED)
			t.Check("past the record: the bonus", record.Credits == math.floor(DropsConfig.CreditsPerKillPerG * Growth.G(Tower.Level(30)) * TowerConfig.Credits.Share * TowerConfig.Credits.Record + 0.5) and record.Credits > plain.Credits)
			t.Check("the chest chance rises with the floor", Tower.ChestChance(10) < Tower.ChestChance(40))
			t.Equal("and tops out", Tower.ChestChance(100_000), TowerConfig.Chest.Most)
			local chests = 0
			for floor = 1, 400 do
				if Tower.Reward(floor, 0, SEED).Chest then
					chests += 1
				end
			end
			local expected = 0
			for floor = 1, 400 do
				expected += Tower.ChestChance(floor)
			end
			t.Check("chests come about as often as their chances", math.abs(chests - expected) < 4 * math.sqrt(expected), `{chests} against {expected}`)
		end,
	},
	{
		Name = "Tower: a run's ledger takes each floor once and only the next, and its end grants it once",
		Run = function(t: any)
			local data = fresh()
			t.Check("a new save's record is none", data.Progress.Tower.Best == 0 and data.Progress.Tower.Run == nil)
			local credits = data.Currency.Credits
			local run = Tower.Start(data, "k900", SEED, NOW)
			t.Check("a run", run ~= nil and data.Progress.Tower.Run ~= nil and (data.Progress.Tower.Run :: any).Floor == 0)
			t.Equal("a second start while it's under way: none", Tower.Start(data, "k901", SEED, NOW), nil)
			t.Equal("the first run kept", (data.Progress.Tower.Run :: any).Id, "k900")
			local ledger = 0
			for floor = 1, 6 do
				local reward = Tower.Won(data, "k900", floor)
				t.Check(`floor {floor} won`, reward ~= nil)
				ledger += if reward then reward.Credits else 0
			end
			local held = (data.Progress.Tower.Run :: any).Credits
			t.Equal("the ledger holds each floor's Credits", held, ledger)
			t.Equal("floor 6 again: a no-op", Tower.Won(data, "k900", 6), nil)
			t.Equal("floor 8, skipping 7: refused", Tower.Won(data, "k900", 8), nil)
			t.Equal("another run's id: refused", Tower.Won(data, "k777", 7), nil)
			t.Check("the ledger unchanged by them", (data.Progress.Tower.Run :: any).Credits == held and (data.Progress.Tower.Run :: any).Floor == 6)
			t.Equal("nothing granted before the end", data.Currency.Credits, credits)
			local chests = table.clone((data.Progress.Tower.Run :: any).Chests)
			local before = table.clone(data.Bag.Chests)
			local results = Tower.End(data, "k900")
			t.Check("results", results ~= nil and results.Floor == 6 and results.Record and results.Best == 0 and results.Credits == held)
			t.Equal("its Credits granted", data.Currency.Credits, credits + held)
			for chest, count in chests do
				t.Equal(`{chest} granted`, data.Bag.Chests[chest], (before[chest] or 0) + count)
			end
			t.Check("the record raised, the run cleared, the results kept", data.Progress.Tower.Best == 6 and data.Progress.Tower.Run == nil and data.Progress.Tower.Results ~= nil)
			t.Equal("its end again: a no-op", Tower.End(data, "k900"), nil)
			t.Equal("nothing granted twice", data.Currency.Credits, credits + held)
			t.Equal("results not held: not seen", Tower.Seen(data, "k777"), false)
			t.Equal("the results seen", Tower.Seen(data, "k900"), true)
			t.Equal("and gone", data.Progress.Tower.Results, nil)
			-- A shorter run: the record stays, Record false.
			Tower.Start(data, "k902", SEED, NOW)
			for floor = 1, 3 do
				Tower.Won(data, "k902", floor)
			end
			local short = Tower.End(data, "k902") :: Profile.TowerResults
			t.Check("under the record: kept, not a record", short.Record == false and short.Best == 6 and data.Progress.Tower.Best == 6)
			-- A run ended with no floor won grants nothing and changes the record not at all.
			Tower.Start(data, "k903", SEED, NOW)
			t.Equal("a new start drops results not seen", data.Progress.Tower.Results, nil)
			local none = Tower.End(data, "k903") :: Profile.TowerResults
			t.Check("no floor won: nothing", none.Floor == 0 and none.Credits == 0 and next(none.Chests) == nil)
			-- Fast floors (only hard floors pay): the run moves on through them, its ledger taking nothing.
			local quick = fresh()
			Tower.Start(quick, "k904", SEED, NOW)
			for floor = 1, 40 do
				Tower.Won(quick, "k904", floor, true)
			end
			local ran = quick.Progress.Tower.Run :: any
			t.Check("forty fast floors: the run at floor 40", ran ~= nil and ran.Floor == 40)
			t.Check("and its ledger empty", ran ~= nil and ran.Credits == 0 and next(ran.Chests) == nil)
			t.Equal("floor 40 again, hard: a no-op", Tower.Won(quick, "k904", 40, false), nil)
			local hard = Tower.Won(quick, "k904", 41, false)
			t.Check("then a hard floor pays", hard ~= nil and hard.Credits > 0 and ran.Credits == hard.Credits)
		end,
	},
	{
		Name = "Tower: a run the save still holds at a join ends there, its ledger granted, and the save stays storable",
		Run = function(t: any)
			local data = fresh()
			t.Equal("no run: nothing to end", Tower.Recover(data), nil)
			Tower.Start(data, "k910", SEED, NOW)
			Tower.Won(data, "k910", 1)
			Tower.Won(data, "k910", 2)
			t.Check("storable mid-run", #Saveable.Problems(data, "profile") == 0, table.concat(Saveable.Problems(data, "profile"), "; "))
			local credits = data.Currency.Credits
			local ledger = (data.Progress.Tower.Run :: any).Credits
			local results = Tower.Recover(data)
			t.Check("ended at its last floor won", results ~= nil and results.Floor == 2 and data.Progress.Tower.Run == nil)
			t.Equal("its Credits granted", data.Currency.Credits, credits + ledger)
			t.Check("storable with its results", #Saveable.Problems(data, "profile") == 0)
			t.Equal("once", Tower.Recover(data), nil)
		end,
	},
}
