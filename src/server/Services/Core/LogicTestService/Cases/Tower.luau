--!strict
-- Tower cases (pure): TR29's rules (Rules.Tower; docs/design.md, "The Tower"). Each floor's foe and its level from the
-- seed; its block lifted to the build and cut to its health share; fast floors; the heal cap; each floor's reward; and
-- the run's ledger: a floor won once and only the next, the end granting once, the record, the results kept until seen,
-- a crash's run ended at the next join, an end cut short granting nothing and leaving the run for that join; and runs
-- seeded through starts, floors, ends and joins, repeated, stale and cut short, granting each floor once (section 9). Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
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
			-- The opening: the same foes in the same order for every run, each in the pool, then the seed's pick.
			t.Check("an opening", #TowerConfig.Opening >= 1)
			for floor, def in TowerConfig.Opening do
				t.Check(`the opening's {def} is in the pool`, table.find(pool, def) ~= nil)
				for _, seed in { SEED, SEED + 1, 7, 2_000_000_011 } do
					t.Equal(`floor {floor} of seed {seed}: {def}`, Tower.Foe(floor, seed).Def, def)
				end
			end
			local past, varied = #TowerConfig.Opening + 1, false
			for floor = past, past + 20 do
				varied = varied or Tower.Foe(floor, SEED).Def ~= Tower.Foe(floor, SEED + 1).Def
			end
			t.Check("past the opening the seed picks", varied)
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
		Name = "Tower (TR46): past the opening the foes come from the week, the same on every server, a run keeping the week it began in; its chests stay its own",
		Run = function(t: any)
			local monday = 1_794_787_200 -- 2026-11-16 00:00 UTC, a Monday
			local day = 86_400
			t.Equal("a Monday's first second starts a week", Tower.Week(monday), Tower.Week(monday - 1) + 1)
			t.Equal("its Sunday's last second is the same week", Tower.Week(monday + 7 * day - 1), Tower.Week(monday))
			t.Equal("the next Monday the next", Tower.Week(monday + 7 * day), Tower.Week(monday) + 1)
			local week = Tower.WeekSeed(Tower.Week(monday))
			t.Equal("the same week, the same foes' seed", Tower.WeekSeed(Tower.Week(monday + 3 * day + 12_345)), week)
			t.Check("a seed in the draw's range", week >= 0 and week <= 0x7fffffff and week == math.floor(week), tostring(week))
			local past, other, same = #TowerConfig.Opening + 1, false, true
			local following = Tower.WeekSeed(Tower.Week(monday) + 1)
			for floor = past, past + 20 do
				other = other or Tower.Foe(floor, week).Def ~= Tower.Foe(floor, following).Def
				same = same and Tower.Foe(floor, week).Def == Tower.Foe(floor, Tower.WeekSeed(Tower.Week(monday + 6 * day))).Def
			end
			t.Check("one week's runs meet the same foes", same)
			t.Check("the next week, other foes", other)
			for floor, def in TowerConfig.Opening do
				t.Equal(`floor {floor} stays the opening's {def}`, Tower.Foe(floor, following).Def, def)
			end
			-- Two runs of one week meet the same foes, and their chests roll on each run's own seed.
			local apart = false
			for floor = past, 400 do
				apart = apart or (Tower.Reward(floor, 0, SEED).Chest ~= nil) ~= (Tower.Reward(floor, 0, SEED + 1).Chest ~= nil)
			end
			t.Check("two runs' chests roll apart", apart)
		end,
	},
	{
		Name = "Tower: the ring lies on its lot's crossing end, where the sleeping Tower stood on the drawn plot",
		Run = function(t: any)
			local plots = WorldConfig.Plots
			local unit = WorldConfig.Walk
			local across, deep, behind, tower = plots.Drawn * unit, plots.Drawn * unit, plots.Behind * unit, plots.Tower * unit
			local x, z = Tower.RingSpot(across, deep, behind, tower, 1)
			-- The plan's placement at 128 (AR16, delivery 3; base_plan.py's TOWER_AT): across 48, 160 in from the gate at
			-- -deep/2 (Kit.Place), so 96 in from the middle.
			t.Check("on the drawn plot, at the silhouette's place", x == 48 and z == 96, `{x}, {z}`)
			local mx = Tower.RingSpot(across, deep, behind, tower, -1)
			t.Equal("mirrored with its crossing", mx, -48)
			-- Its platforms (out to where a run is left) clear the plot's own yard and the neighbour's half of the gap
			-- between them (AR41: 48 across overhangs the lot's 32, in the air).
			local reach = Tower.Reach(across, deep, behind, tower)
			t.Check("its platforms stay off its own yard", reach.Near >= deep / 2, `{reach.Near} < {deep / 2}`)
			local between = plots.Between * unit
			t.Check("and off its neighbour's half of the gap", reach.Side <= across / 2 + between / 2, `{reach.Side} > {across / 2 + between / 2}`)
			t.Check("and over its own floor, never the one below", TowerConfig.Platform.Height > TowerConfig.Out.Below + TowerConfig.Platform.Thick)
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
				local first = floor == TowerConfig.Chest.First
				if fast.Credits ~= 0 or (fast.Chest ~= nil) ~= first then
					t.Check(`floor {floor}: a fast floor pays nothing, past the record or not, but the first chest`, false, `{fast.Credits}, {fast.Chest}`)
				end
				local known = Tower.Reward(floor, floor, SEED, true)
				if known.Credits ~= 0 or known.Chest ~= nil then
					t.Check(`floor {floor}: a fast floor at or under the record pays nothing at all`, false, `{known.Credits}, {known.Chest}`)
				end
			end
			-- The first chest: sure the first time the account wins its floor, fast or hard, in every run; then the roll again.
			local firstFloor = TowerConfig.Chest.First
			local firstGround = Grounds.List[Growth.GroundOf(Tower.Level(firstFloor))]
			local sure, after = 0, 0
			for seed = 1, 300 do
				local hard, quick = Tower.Reward(firstFloor, firstFloor - 1, seed), Tower.Reward(firstFloor, 0, seed, true)
				local row = if hard.Chest then ChestRows.ById[hard.Chest] else nil
				sure += if row and row.Ground == firstGround.Id and row.Tier == ChestRows.Tower and quick.Chest == hard.Chest then 1 else 0
				after += if Tower.Reward(firstFloor, firstFloor, seed).Chest then 1 else 0
			end
			t.Equal(`floor {firstFloor}'s first win: the Tower's chest in each of 300 runs`, sure, 300)
			t.Check("won before: its roll again", after < 30, `{after} of 300`)
			t.Check("the floor under it isn't sure", Tower.Reward(firstFloor - 1, 0, 1, true).Chest == nil)
			local plain, record = Tower.Reward(30, 30, SEED), Tower.Reward(30, 29, SEED)
			t.Check("past the record: the bonus", record.Credits == math.floor(DropsConfig.CreditsPerKillPerG * Growth.G(Tower.Level(30)) * TowerConfig.Credits.Share * TowerConfig.Credits.Record + 0.5) and record.Credits > plain.Credits)
			t.Check("the chest chance rises with the floor", Tower.ChestChance(10) < Tower.ChestChance(40))
			t.Equal("and tops out", Tower.ChestChance(100_000), TowerConfig.Chest.Most)
			local chests = 0
			for floor = 1, 400 do
				if Tower.Reward(floor, TowerConfig.Chest.First, SEED).Chest then
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
			local results = Tower.End(data, "k900", NOW + 600)
			t.Check("results", results ~= nil and results.Floor == 6 and results.Record and results.Best == 0 and results.Credits == held)
			t.Equal("its Credits granted", data.Currency.Credits, credits + held)
			for chest, count in chests do
				t.Equal(`{chest} granted`, data.Bag.Chests[chest], (before[chest] or 0) + count)
			end
			t.Check("the record raised, the run cleared, the results kept", data.Progress.Tower.Best == 6 and data.Progress.Tower.Run == nil and data.Progress.Tower.Results ~= nil)
			t.Equal("its end again: a no-op", Tower.End(data, "k900", NOW + 600), nil)
			t.Equal("nothing granted twice", data.Currency.Credits, credits + held)
			t.Equal("results not held: not seen", Tower.Seen(data, "k777"), false)
			t.Equal("the results seen", Tower.Seen(data, "k900"), true)
			t.Equal("and gone", data.Progress.Tower.Results, nil)
			-- A shorter run: the record stays, Record false.
			Tower.Start(data, "k902", SEED, NOW)
			for floor = 1, 3 do
				Tower.Won(data, "k902", floor)
			end
			local short = Tower.End(data, "k902", NOW + 600) :: Profile.TowerResults
			t.Check("under the record: kept, not a record", short.Record == false and short.Best == 6 and data.Progress.Tower.Best == 6)
			-- A run ended with no floor won grants nothing and changes the record not at all.
			Tower.Start(data, "k903", SEED, NOW)
			t.Equal("a new start drops results not seen", data.Progress.Tower.Results, nil)
			local none = Tower.End(data, "k903", NOW + 600) :: Profile.TowerResults
			t.Check("no floor won: nothing", none.Floor == 0 and none.Credits == 0 and next(none.Chests) == nil)
			-- Fast floors (only hard floors pay): the run moves on through them, its ledger taking nothing.
			local quick = fresh()
			Tower.Start(quick, "k904", SEED, NOW)
			for floor = 1, 40 do
				Tower.Won(quick, "k904", floor, true)
			end
			local ran = quick.Progress.Tower.Run :: any
			t.Check("forty fast floors: the run at floor 40", ran ~= nil and ran.Floor == 40)
			local firstChest = Tower.Reward(TowerConfig.Chest.First, 0, SEED, true).Chest :: string
			local carried = 0
			for _, each in if ran then ran.Chests else {} do
				carried += each
			end
			t.Check("and its ledger empty but the first chest, once", ran ~= nil and ran.Credits == 0 and carried == 1 and ran.Chests[firstChest] == 1)
			local later = fresh()
			later.Progress.Tower.Best = TowerConfig.Chest.First
			Tower.Start(later, "k905", SEED, NOW)
			for floor = 1, 40 do
				Tower.Won(later, "k905", floor, true)
			end
			local again = later.Progress.Tower.Run :: any
			t.Check("a later climb through fast floors: nothing", again ~= nil and again.Credits == 0 and next(again.Chests) == nil)
			t.Equal("floor 40 again, hard: a no-op", Tower.Won(quick, "k904", 40, false), nil)
			local hard = Tower.Won(quick, "k904", 41, false)
			t.Check("then a hard floor pays", hard ~= nil and hard.Credits > 0 and ran.Credits == hard.Credits)
		end,
	},
	{
		Name = "Tower: a run the save still holds at a join ends there, its ledger granted, and the save stays storable",
		Run = function(t: any)
			local data = fresh()
			t.Equal("no run: nothing to end", Tower.Recover(data, NOW + 600), nil)
			Tower.Start(data, "k910", SEED, NOW)
			Tower.Won(data, "k910", 1)
			Tower.Won(data, "k910", 2)
			t.Check("storable mid-run", #Saveable.Problems(data, "profile") == 0, table.concat(Saveable.Problems(data, "profile"), "; "))
			local credits = data.Currency.Credits
			local ledger = (data.Progress.Tower.Run :: any).Credits
			local results = Tower.Recover(data, NOW + 600)
			t.Check("ended at its last floor won", results ~= nil and results.Floor == 2 and data.Progress.Tower.Run == nil)
			t.Equal("its Credits granted", data.Currency.Credits, credits + ledger)
			t.Check("storable with its results", #Saveable.Problems(data, "profile") == 0)
			t.Equal("once", Tower.Recover(data, NOW + 600), nil)
		end,
	},
	{
		Name = "Tower: the week's board (TR46): a climb scored by floor then the earlier, the week's climb in the save at each run's end, the board as one player reads it, the card's line",
		Run = function(t: any)
			local length = TowerConfig.Week.Length
			local week = Tower.Week(NOW)
			local start = TowerConfig.Week.Start + week * length
			-- The score.
			t.Equal("a score stands for its floor", Tower.ScoreFloor(Tower.Score(23, week, start + 5000)), 23)
			t.Check("a higher floor scores higher, however late", Tower.Score(24, week, start + length - 1) > Tower.Score(23, week, start))
			t.Check("of two equal floors, the earlier scores higher", Tower.Score(23, week, start + 10) > Tower.Score(23, week, start + 20))
			t.Equal("ended past its week: as at its last second", Tower.Score(5, week, start + length + 900), Tower.Score(5, week, start + length - 1))
			t.Equal("and its floor kept", Tower.ScoreFloor(Tower.Score(5, week, start + length + 900)), 5)
			t.Equal("before its week: as at its first second", Tower.Score(5, week, start - 3), Tower.Score(5, week, start))
			local big = Tower.Score(1_000_000_000, week, start)
			t.Check("whole and exact at floor 10^9", big == math.floor(big) and big < 2 ^ 53 and Tower.ScoreFloor(big) == 1_000_000_000)
			-- The week's climb in the save, at each run's end.
			local data = fresh()
			t.Equal("no climb yet", Tower.Climb(data, NOW), nil)
			Tower.Start(data, "k920", SEED, NOW)
			Tower.End(data, "k920", NOW + 60)
			t.Equal("a run with no floor won: still none", Tower.Climb(data, NOW + 60), nil)
			local function climb(id: string, at: number, floors: number, ended: number)
				Tower.Start(data, id, SEED, at)
				for floor = 1, floors do
					Tower.Won(data, id, floor)
				end
				Tower.End(data, id, ended)
			end
			climb("k921", NOW, 7, NOW + 600)
			local held = Tower.Climb(data, NOW + 700)
			t.Check("seven floors: the week's climb", held ~= nil and held.Week == week and held.Floor == 7 and held.Score == Tower.Score(7, week, NOW + 600))
			climb("k922", NOW + 800, 4, NOW + 900)
			t.Equal("a lower climb leaves it", (Tower.Climb(data, NOW + 1000) :: any).Floor, 7)
			climb("k923", NOW + 1000, 7, NOW + 1100)
			t.Equal("an equal floor later keeps the earlier's score", (Tower.Climb(data, NOW + 1200) :: any).Score, Tower.Score(7, week, NOW + 600))
			local late = start + length - 30
			climb("k924", late, 9, late + 300)
			local over = data.Progress.Tower.Week :: Profile.TowerWeek
			t.Check("a run over the week's end counts in the week it started", over.Week == week and over.Floor == 9 and Tower.ScoreFloor(over.Score) == 9)
			t.Equal("read in the next week: no climb yet", Tower.Climb(data, start + length + 60), nil)
			climb("k925", start + length + 100, 1, start + length + 200)
			local fresher = Tower.Climb(data, start + length + 300)
			t.Check("the next week's first climb replaces it, however low", fresher ~= nil and fresher.Week == week + 1 and fresher.Floor == 1)
			t.Check("storable", #Saveable.Problems(data, "profile") == 0, table.concat(Saveable.Problems(data, "profile"), "; "))
			-- The board as one player reads it.
			local function entry(id: number, floor: number, at: number): Tower.Entry
				return { Id = id, Score = Tower.Score(floor, week, start + at) }
			end
			local top = { entry(1, 30, 10), entry(2, 23, 5), entry(3, 23, 50), entry(4, 12, 0) }
			local rows, mine = Tower.Board(top, 3, top[3].Score, 10)
			local order = {}
			for _, row in rows do
				table.insert(order, `{row.Id}`)
			end
			t.Equal("best first, the earlier of an equal floor first", table.concat(order, " "), "1 2 3 4")
			t.Check("their own row: #3, floor 23", mine ~= nil and mine.Rank == 3 and mine.Floor == 23)
			t.Equal("the card's line", Tower.WeekLine(mine), "This week: #3 · floor 23")
			local rows2, mine2 = Tower.Board(top, 4, Tower.Score(25, week, start + 900), 10)
			t.Check("their save fresher than the page: in its place, the stored row gone", mine2 ~= nil and mine2.Rank == 2 and mine2.Floor == 25 and #rows2 == 4 and rows2[2].Id == 4)
			local _, mine3 = Tower.Board(top, 99, Tower.Score(1, week, start), 10)
			t.Check("not stored yet, the page not full: placed in it", mine3 ~= nil and mine3.Rank == 5)
			local page = TowerConfig.Board.Page
			local full = {}
			for i = 1, page do
				table.insert(full, entry(1000 + i, 200 - i, 0))
			end
			local rows4, mine4 = Tower.Board(full, 7, Tower.Score(1, week, start), TowerConfig.Board.Shown)
			t.Check("the first Shown rows", #rows4 == TowerConfig.Board.Shown and rows4[1].Floor == 199)
			t.Check("under a full page: unranked", mine4 ~= nil and mine4.Rank == nil and mine4.Floor == 1)
			t.Equal("its line", Tower.WeekLine(mine4), `This week: #{page}+ · floor 1`)
			local _, mine5 = Tower.Board(full, 7, Tower.Score(150, week, start + 100), TowerConfig.Board.Shown)
			t.Check("over a full page's last: ranked inside it", mine5 ~= nil and mine5.Rank == 51, if mine5 then tostring(mine5.Rank) else "none")
			local _, none = Tower.Board(top, 99, nil, 10)
			t.Equal("no climb: no own row", none, nil)
			t.Equal("its line", Tower.WeekLine(nil), "This week: no climb yet")
		end,
	},
	{
		Name = "Tower (section 9): an end cut short grants nothing and leaves the run, the next join's recovery grants it once, and an ended run recovers nothing",
		Run = function(t: any)
			local data = fresh()
			Tower.Start(data, "k920", SEED, NOW)
			for floor = 1, 12 do
				Tower.Won(data, "k920", floor)
			end
			local run = data.Progress.Tower.Run :: Profile.TowerRun
			local ledger, credits = run.Credits, data.Currency.Credits
			t.Check("a ledger with Credits to grant", ledger > 0, `{ledger}`)
			local before = Profile.DeepCopy(data)
			-- the server falls over once the end has granted, before its change finishes: one transaction, so none of it lands
			local cut, changed, why = Transaction.Run(data, nil, function(draft: Profile.Data): Transaction.Answer
				Tower.End(draft, "k920", NOW + 600)
				error("interrupted")
			end, 8)
			t.Check("the cut end changed nothing", cut.Ok == false and not changed and why ~= nil)
			t.Check("the run still in the save, its ledger whole", data.Progress.Tower.Run ~= nil and (data.Progress.Tower.Run :: any).Credits == ledger and data.Currency.Credits == credits)
			local kept = true
			for chest, count in run.Chests do
				kept = kept and (data.Bag.Chests[chest] or 0) == (before.Bag.Chests[chest] or 0) and count > 0
			end
			t.Check("the chests not granted", kept)
			local recovered = Transaction.Run(data, nil, function(draft: Profile.Data): Transaction.Answer
				local results = Tower.Recover(draft, NOW + 900)
				return if results then { Ok = true, Floor = results.Floor } else { Ok = false, Error = "None" }
			end, 8)
			t.Check("the next join ends it at its last floor", recovered.Ok == true and recovered.Floor == 12 and data.Progress.Tower.Run == nil)
			t.Equal("its Credits granted once", data.Currency.Credits, credits + ledger)
			t.Equal("a second join finds nothing", Tower.Recover(data, NOW + 1200), nil)
			t.Equal("still once", data.Currency.Credits, credits + ledger)
			-- a run ended on leaving, then a join on another server: the save has no run, so nothing is granted again
			Tower.Start(data, "k921", SEED, NOW + 2000)
			Tower.Won(data, "k921", 1)
			local second = (data.Progress.Tower.Run :: any).Credits
			Tower.End(data, "k921", NOW + 2100)
			local after = data.Currency.Credits
			t.Equal("ended on leaving: granted", after, credits + ledger + second)
			t.Equal("its join recovers nothing", Tower.Recover(data, NOW + 2200), nil)
			t.Equal("nothing twice", data.Currency.Credits, after)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Tower (section 9): runs seeded through starts, floors, ends and joins, repeated, stale and cut short in any order, grant each floor's reward once",
		Run = function(t: any)
			local seed = 20261121
			local function roll(n: number): number
				seed = (seed * 16807) % 2147483647
				return seed % n + 1
			end
			local function same(a: any, b: any): boolean
				if type(a) ~= type(b) then
					return false
				elseif type(a) ~= "table" then
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
			local function sum(map: { [string]: number }?): number
				local n = 0
				for _, count in map or {} do
					n += count
				end
				return n
			end
			local data = fresh()
			local credits0, chests0, stones0 = data.Currency.Credits, sum(data.Bag.Chests), sum(data.Bag.Stones)
			-- The model: the run the save should hold, built only from the rewards the rule handed back, and what was granted.
			local open: { Id: string, Floor: number, Credits: number, Chests: number, Stones: number }? = nil
			local ids: { string } = { "never-a-run" }
			local granted, chests, stones, best = 0, 0, 0, 0
			local now = NOW
			local count: { [string]: number } = {}
			local cuts, replays, broken = 0, 0, 0
			local function close(results: any): string?
				local was = open
				if was == nil then
					return if results then "an end granted with no run under way" else nil
				elseif results == nil then
					return `the run {was.Id} didn't end`
				elseif results.Id ~= was.Id or results.Floor ~= was.Floor or results.Credits ~= was.Credits or sum(results.Chests) ~= was.Chests or sum(results.Stones) ~= was.Stones then
					return `the results of {was.Id} aren't its ledger`
				end
				granted += was.Credits
				chests += was.Chests
				stones += was.Stones
				best = math.max(best, was.Floor)
				open = nil
				return nil
			end
			local function check(): string?
				local tower = data.Progress.Tower -- read fresh: a commit replaces the save's tables
				local run = tower.Run
				if data.Currency.Credits ~= credits0 + granted then
					return `Credits: {data.Currency.Credits} against {credits0 + granted}`
				elseif sum(data.Bag.Chests) ~= chests0 + chests then
					return `chests: {sum(data.Bag.Chests)} against {chests0 + chests}`
				elseif sum(data.Bag.Stones) ~= stones0 + stones then
					return `stones: {sum(data.Bag.Stones)} against {stones0 + stones}`
				elseif tower.Best ~= best then
					return `the record {tower.Best} against {best}`
				elseif (run == nil) ~= (open == nil) then
					return if run then `the save holds run {run.Id}, which should have ended` else "the save lost the run under way"
				elseif run and open and (run.Id ~= open.Id or run.Floor ~= open.Floor or run.Credits ~= open.Credits or sum(run.Chests) ~= open.Chests or sum(run.Stones) ~= open.Stones) then
					return `run {run.Id}'s ledger: floor {run.Floor}, {run.Credits} Credits, against floor {open.Floor}, {open.Credits}`
				end
				return nil
			end
			local last: { Name: string, Id: string, Floor: number, Fast: boolean, Seed: number }? = nil
			for step = 1, 500 do
				now += roll(120)
				local ask: { Name: string, Id: string, Floor: number, Fast: boolean, Seed: number }
				local replay = last ~= nil and roll(5) == 1 -- the same call again: a doubled event, a retried step
				if replay and last then
					ask = last
					replays += 1
				else
					local pick = roll(20)
					local id = if open and roll(6) > 1 then open.Id else ids[roll(#ids)]
					local floor = if open then open.Floor + ({ 1, 1, 1, 1, 0, 2 })[roll(6)] else roll(3)
					-- runs long enough to reach the chest floors, with a start soon after each end
					local name = if pick == 1 or (open == nil and pick <= 8) then "Start" elseif pick == 2 then "StartRaw" elseif pick <= 18 then "Won" elseif pick == 19 then "End" else "Recover"
					ask = { Name = name, Id = id, Floor = floor, Fast = roll(4) == 1, Seed = roll(1_000_000) }
				end
				local cut = roll(6) == 1
				local before = Profile.DeepCopy(data)
				local answer, changed = Transaction.Run(data, nil, function(draft: Profile.Data): Transaction.Answer
					local done: Transaction.Answer
					if ask.Name == "Start" then -- as the service starts one: a run a crash left is ended first
						local ended = Tower.Recover(draft, now)
						local run = Tower.Start(draft, Profile.NewId(draft), ask.Seed, now)
						done = { Ok = run ~= nil, Ended = ended, Run = run and run.Id }
					elseif ask.Name == "StartRaw" then
						local run = Tower.Start(draft, Profile.NewId(draft), ask.Seed, now)
						done = { Ok = run ~= nil, Run = run and run.Id }
					elseif ask.Name == "Won" then
						local reward = Tower.Won(draft, ask.Id, ask.Floor, ask.Fast)
						done = { Ok = reward ~= nil, Reward = reward }
					elseif ask.Name == "End" then
						local results = Tower.End(draft, ask.Id, now)
						done = { Ok = results ~= nil, Results = results }
					else
						local results = Tower.Recover(draft, now)
						done = { Ok = results ~= nil, Results = results }
					end
					if cut then
						error("interrupted")
					end
					return done
				end, 8)
				local wrong: string? = nil
				if cut then
					cuts += 1
					if changed or not same(data, before) then
						wrong = "a cut changed the save"
					end
				else
					local was = open
					local key = `{ask.Name} {if answer.Ok then "Ok" else "refused"}`
					count[key] = (count[key] or 0) + 1
					if ask.Name == "Start" or ask.Name == "StartRaw" then
						if ask.Name == "StartRaw" and was then
							wrong = if answer.Ok then `a run started over {was.Id}, its ledger lost` else nil
						elseif not answer.Ok then
							wrong = "a start refused with no run under way"
						else
							wrong = close(answer.Ended)
							open = { Id = answer.Run, Floor = 0, Credits = 0, Chests = 0, Stones = 0 }
							table.insert(ids, answer.Run)
						end
					elseif ask.Name == "Won" then
						local next = was ~= nil and ask.Id == was.Id and ask.Floor == was.Floor + 1
						if answer.Ok ~= next then
							wrong = `floor {ask.Floor} of {ask.Id} {if answer.Ok then "paid" else "refused"}, the run at {if was then `{was.Id} floor {was.Floor}` else "none"}`
						elseif next and was then
							local reward = answer.Reward
							was.Floor = ask.Floor
							was.Credits += reward.Credits
							was.Chests += if reward.Chest then 1 else 0
							was.Stones += reward.Stones
						end
					elseif ask.Name == "End" then
						if was and ask.Id == was.Id then
							wrong = close(answer.Results)
						elseif answer.Ok then
							wrong = `an end of {ask.Id} granted while {if was then was.Id else "no run"} stood`
						end
					else
						wrong = close(answer.Results)
					end
					if not answer.Ok and not same(data, before) then
						wrong = wrong or `a refused {ask.Name} changed the save`
					end
				end
				last = ask
				local failed: string? = (wrong :: any) or check() -- any: the refinements above confuse the checker
				if failed then
					broken += 1
					t.Check(`step {step} ({ask.Name}{if replay then ", again" else ""}): each floor paid once, each run granted once`, false, failed)
					break
				end
			end
			t.Equal("no step paid twice or lost a run", broken, 0)
			local each = {}
			for _, key in { "Start Ok", "StartRaw refused", "Won Ok", "Won refused", "End Ok", "End refused", "Recover Ok", "Recover refused" } do
				table.insert(each, `{key} {count[key] or 0}`)
			end
			t.Check(
				`every call made, cut ({cuts}) and repeated ({replays}) often: {table.concat(each, ", ")}; granted {granted} Credits, {chests} chests, {stones} stones, the record at {best}`,
				granted > 0 and chests >= 3 and stones >= 3 and (count["Start Ok"] or 0) >= 10 and (count["StartRaw refused"] or 0) >= 3 and (count["Won Ok"] or 0) >= 50 and (count["Won refused"] or 0) >= 20 and (count["End Ok"] or 0) >= 5 and (count["End refused"] or 0) >= 5 and (count["Recover Ok"] or 0) >= 3 and (count["Recover refused"] or 0) >= 3 and cuts >= 20 and replays >= 20
			)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
