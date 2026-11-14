--!strict
-- Board cases (pure): the stat board, a Voidkin's skill points (docs/design.md, "Skill points"; TR15). Earning one a
-- level, spending it on one of four stats and never another, the board on top of the own base (research's call (c)): a
-- point's gain a part of the stat's own figure, class and rarity in it, and what the board shows the same as what a tap
-- adds; nothing spent is today's Voidkin, an even full spend adds each stat's Share, every point on one four times it;
-- no spread lowers a stat, and no level-up does either with its point waiting; a spend or a reset repeated or interrupted
-- never counting twice, the reset's price, a level gained with the board open, and an old save gaining its points.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Board = require(Shared.Rules.Board)
local Stats = require(Shared.Rules.Stats)
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local Voidkin = require(Shared.Definitions.Voidkin)
local StatsConfig = require(Shared.Config.Stats)
local GrowthConfig = require(Shared.Config.Growth)
local DataConfig = require(Shared.Config.Data)

local T0 = 1_800_000_000
local FOUR = { "Health", "Attack", "Defence", "Regen" }

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9) * math.max(1, math.abs(b))
end

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function own(data: Profile.Data, def: string, level: number): Profile.OwnedVoidkin
	local owned = data.Voidkin[Collection.Uncover(data, def, T0).Id]
	owned.Level = level
	return owned
end

local function act(data: Profile.Data, name: string, args: any, opId: string?): (any, boolean)
	return Transaction.Run(data, opId, function(draft: Profile.Data): any
		return Collection.Actions[name](draft, args, T0, 0.5)
	end, DataConfig.OpsKept)
end

local function first(rarity: string, class: string): string
	for _, row in Voidkin.List do
		if row.Rarity == rarity and row.Class == class then
			return row.Id
		end
	end
	error(`no {rarity} {class} in the roster`)
end

-- The Voidkin without the board: its own base whole, and its Regen from the level.
local function plain(def: string, level: number): { [string]: number }
	local row = Voidkin.ById[def]
	local g = Growth.G(level)
	local out = {}
	for _, stat in { "Health", "Attack", "Defence" } do
		out[stat] = StatsConfig.Base[stat] * StatsConfig.Rarity[row.Rarity] * StatsConfig.Class[row.Class][stat] * g
	end
	out.Regen = StatsConfig.Regen.Base * (StatsConfig.Regen.Class[row.Class] or 1) * g
	return out
end

local function lineOf(lines: { Stats.Line }, source: string, stat: string): number
	local sum = 0
	for _, line in lines do
		if line.Source == source and line.Stat == stat then
			sum += line.Value
		end
	end
	return sum
end

return {
	{
		Name = "Board: one point a level from level 2, each Voidkin's own, and a level gained adds one to spend",
		Run = function(t: any)
			t.Equal("the board's four", table.concat(StatsConfig.Board.Stats, ","), table.concat(FOUR, ","))
			t.Equal("none at level 1", Board.Earned(1), 0)
			t.Equal("one at level 2", Board.Earned(2), 1)
			t.Equal("eight at level 9", Board.Earned(9), 8)
			t.Equal("one a level to the last", Board.Earned(GrowthConfig.MaxLevel), GrowthConfig.MaxLevel - 1)
			local data = fresh()
			local id = own(data, "rook", 1).Id
			local function rook(): Profile.OwnedVoidkin
				return data.Voidkin[id] -- a committed change puts in new tables: read it again each time
			end
			t.Check("a new Voidkin has spent nothing", next(rook().Points) == nil and Board.Spent(rook()) == 0)
			t.Equal("and has nothing to spend at level 1", Board.Left(rook()), 0)
			t.Equal("nothing to spend, refused", act(data, "SpendPoint", { Voidkin = id, Stat = "Health" }).Error, Board.NoPoints)
			Growth.AddXp(rook(), Growth.XpToNext(1) :: number)
			t.Equal("level 2: one to spend", Board.Left(rook()), 1)
			t.Check("spent", act(data, "SpendPoint", { Voidkin = id, Stat = "Attack" }).Ok == true)
			t.Equal("none left", Board.Left(rook()), 0)
			-- A level gained with the board open: the spent point stays, the new one waits.
			Growth.AddXp(rook(), Growth.XpToNext(2) :: number)
			t.Check("level 3: the point kept, one more to spend", Board.On(rook(), "Attack") == 1 and Board.Left(rook()) == 1)
			local pip = own(data, "pip", 9)
			t.Equal("another Voidkin's points are its own", Board.Left(pip), 8)
			t.Equal("and the first keeps its own", Board.Left(rook()), 1)
		end,
	},
	{
		Name = "Board: a point adds its gain on top, a part of the stat's own figure with class and rarity in it, and the board shows what a tap adds",
		Run = function(t: any)
			local data = fresh()
			for _, def in { first("Common", "Warrior"), first("Common", "Tank"), first("Mythical", "Assassin"), "pip", "lyric" } do
				local id = own(data, def, 9).Id
				local mine = plain(def, 9)
				for index, stat in FOUR do
					local before = Stats.Resolve(data.Voidkin[id], nil, nil)
					local shown = Stats.PointGain(data.Voidkin[id], stat)
					local gain = StatsConfig.Board.Share[stat] * 4 * mine[stat] / Board.Earned(9)
					t.Check(`{def} {stat}`, act(data, "SpendPoint", { Voidkin = id, Stat = stat }).Ok == true)
					local after, lines = Stats.Resolve(data.Voidkin[id], nil, nil)
					local added = (after :: any)[stat] - (before :: any)[stat]
					t.Check(`{def} {stat}: four times its Share of the own figure, over the points earned`, near(added, gain), `{added}, wanted {gain}`)
					t.Check(`{def} {stat}: the gain the board showed is what the tap added`, near(shown, added))
					t.Check(`{def} {stat}: one line, from the board`, near(lineOf(lines, "Board", stat), gain))
					for other, value in FOUR do
						if other ~= index then
							t.Check(`{def} {stat}: {value} doesn't move`, near((after :: any)[value], (before :: any)[value]))
						end
					end
				end
			end
			-- Rarity and class in the own figure: a Mythical's point is worth its rarity's times a Common's of its class.
			local common, mythical = own(data, first("Common", "Assassin"), 9), own(data, first("Mythical", "Assassin"), 9)
			local ratio = StatsConfig.Rarity.Mythical / StatsConfig.Rarity.Common
			t.Check("a Mythical's point, its rarity's times a Common's", near(Stats.PointGain(mythical, "Attack") / Stats.PointGain(common, "Attack"), ratio))
			-- A point's part of the share falls as points pile up: the first, spent at 2, places half as much of the own
			-- figure at 3 with the new point waiting. A save of its own: the first Common Warrior above may be Rook.
			local alone = fresh()
			local id = own(alone, "rook", 2).Id
			act(alone, "SpendPoint", { Voidkin = id, Stat = "Health" })
			local rook = alone.Voidkin[id]
			local _, two = Stats.Resolve(rook, nil, nil)
			t.Check("at 2, one point: four times Health's Share", near(lineOf(two, "Board", "Health"), 4 * StatsConfig.Board.Share.Health * plain("rook", 2).Health))
			rook.Level = 3
			local _, three = Stats.Resolve(rook, nil, nil)
			t.Check("at 3, the new point waiting: half that part, of a larger own", near(lineOf(three, "Board", "Health"), 2 * StatsConfig.Board.Share.Health * plain("rook", 3).Health))
			t.Check("the greyed board at level 1 shows a first point's worth", Stats.PointGain(own(data, "pip", 1), "Health") > 0)
		end,
	},
	{
		Name = "Board: nothing spent is today's Voidkin, an even full spend adds each Share, every point on one four times it, and stars never move",
		Run = function(t: any)
			local data = fresh()
			local share = StatsConfig.Board.Share
			local failed = 0
			local function expect(what: string, got: number, want: number)
				if not near(got, want, 1e-9) then
					failed += 1
					if failed <= 20 then
						t.Check(what, false, `{got}, wanted {want}`)
					end
				end
			end
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, 1)
				for level = 1, GrowthConfig.MaxLevel do
					owned.Level, owned.Stars = level, 0
					local want = plain(row.Id, level)
					local earned = Board.Earned(level)
					table.clear(owned.Points)
					local today = Stats.Resolve(owned, nil, nil)
					for _, stat in FOUR do
						expect(`{row.Id} at {level}: {stat} with nothing spent`, (today :: any)[stat], want[stat])
					end
					if earned > 0 then
						for _, stat in FOUR do
							owned.Points[stat] = earned / 4
						end
						local even = Stats.Resolve(owned, nil, nil)
						for _, stat in FOUR do
							expect(`{row.Id} at {level}: {stat} spent evenly at full`, (even :: any)[stat], want[stat] * (1 + share[stat]))
						end
						for _, stat in FOUR do
							table.clear(owned.Points)
							owned.Points[stat] = earned
							local lean = Stats.Resolve(owned, nil, nil)
							expect(`{row.Id} at {level}: every point on {stat}`, (lean :: any)[stat], want[stat] * (1 + 4 * share[stat]))
						end
					end
					owned.Stars = 3
					table.clear(owned.Points)
					owned.Points.Health = earned
					local _, lines = Stats.Resolve(owned, nil, nil)
					table.clear(owned.Points)
					local _, bare = Stats.Resolve(owned, nil, nil)
					for _, stat in { "Health", "Attack", "Defence" } do
						expect(`{row.Id} at {level}: stars on {stat} don't move with points`, lineOf(lines, "Stars", stat), lineOf(bare, "Stars", stat))
					end
				end
			end
			t.Check(`every Voidkin at every level ({failed} off)`, failed == 0)
			-- More spent than earned (a test's or a tune's): the whole board still adds no more than its share.
			local rook = own(data, "rook", 5)
			rook.Points.Health, rook.Points.Attack = 4, 4
			local _, lines = Stats.Resolve(rook, nil, nil)
			local want = plain("rook", 5)
			t.Check("eight spent of four earned: each half the board, twice its Share", near(lineOf(lines, "Board", "Health"), 2 * share.Health * want.Health) and near(lineOf(lines, "Board", "Attack"), 2 * share.Attack * want.Attack))
		end,
	},
	{
		Name = "Board: only Health, Attack, Defence and Regen take points, never Dodge, Block, a damage bucket, Critical Damage or Speed",
		Run = function(t: any)
			local data = fresh()
			local rook = own(data, "rook", 9)
			local before = Profile.DeepCopy(data)
			for _, stat in { "Dodge", "Block", "DamageReduction", "DamageBonus", "CriticalDamage", "Speed", "Critical", "Hit", "Lifesteal", "", "health", 7, true, "__index" } :: { any } do
				local answer, changed = act(data, "SpendPoint", { Voidkin = rook.Id, Stat = stat })
				t.Check(`{tostring(stat)} refused`, answer.Ok == false and answer.Error == Board.Stat and not changed)
			end
			t.Equal("not owned", act(data, "SpendPoint", { Voidkin = "k404", Stat = "Health" }).Error, Board.Unknown)
			t.Equal("points untouched", Board.Spent(rook), 0)
			t.Equal("the save untouched", data.NextId, before.NextId)
			for _, stat in FOUR do
				t.Check(`{stat} takes one`, act(data, "SpendPoint", { Voidkin = rook.Id, Stat = stat }).Ok == true)
			end
			t.Equal("four spent", Board.Spent(data.Voidkin[rook.Id]), 4)
		end,
	},
	{
		Name = "Board: a spend asked twice with one op id spends once, one interrupted changes nothing, and none past those earned",
		Run = function(t: any)
			local data = fresh()
			local rook = own(data, "rook", 4)
			local spent = act(data, "SpendPoint", { Voidkin = rook.Id, Stat = "Defence" }, "op-1")
			local again = act(data, "SpendPoint", { Voidkin = rook.Id, Stat = "Defence" }, "op-1")
			t.Check("the first spends", spent.Ok == true and spent.On == 1 and spent.Left == 2)
			t.Check("the repeat answers the same", again.Ok == true and again.On == 1 and again.Left == 2)
			t.Equal("one point spent", Board.On(data.Voidkin[rook.Id], "Defence"), 1)
			local before = Profile.DeepCopy(data)
			local cut, changed = Transaction.Run(data, "op-cut", function(draft: Profile.Data): any
				Board.Spend(draft, rook.Id, "Health")
				error("the server stopped here")
			end, DataConfig.OpsKept)
			t.Check("interrupted: failed, unchanged", cut.Ok == false and not changed)
			t.Equal("no point on Health", Board.On(data.Voidkin[rook.Id], "Health"), 0)
			t.Equal("still two left", Board.Left(data.Voidkin[rook.Id]), Board.Left(before.Voidkin[rook.Id]))
			t.Check("the retry spends it", act(data, "SpendPoint", { Voidkin = rook.Id, Stat = "Health" }, "op-cut").Ok == true)
			rook = data.Voidkin[rook.Id]
			t.Check("and one more", act(data, "SpendPoint", { Voidkin = rook.Id, Stat = "Health" }).Ok == true)
			local over, moved = act(data, "SpendPoint", { Voidkin = rook.Id, Stat = "Health" })
			t.Check("none past those earned", over.Ok == false and over.Error == Board.NoPoints and not moved)
			t.Equal("three spent, of three", Board.Spent(data.Voidkin[rook.Id]), 3)
		end,
	},
	{
		Name = "Board: a reset gives every point back for its price in Credits, once, and a reset with nothing spent costs nothing",
		Run = function(t: any)
			local data = fresh()
			local rook = own(data, "rook", 9)
			t.Equal("nothing to reset", act(data, "ResetPoints", { Voidkin = rook.Id }).Error, Board.Nothing)
			for _, stat in { "Health", "Health", "Attack" } do
				act(data, "SpendPoint", { Voidkin = rook.Id, Stat = stat })
			end
			rook = data.Voidkin[rook.Id]
			local price = Board.ResetCost(rook)
			t.Equal("its price: ResetPerG times G, whole", price, math.ceil(StatsConfig.Board.ResetPerG * Growth.G(9) - 1e-9))
			t.Check("a little: under twenty kills at its level", price < 20 * 10 * Growth.G(9))
			data.Currency.Credits = price - 1
			local short, moved = act(data, "ResetPoints", { Voidkin = rook.Id })
			t.Check("short: refused, unchanged, with the price", short.Ok == false and short.Error == Board.Short and short.Credits == price and not moved)
			data.Currency.Credits = price + 5
			local reset = act(data, "ResetPoints", { Voidkin = rook.Id }, "op-reset")
			local again = act(data, "ResetPoints", { Voidkin = rook.Id }, "op-reset")
			rook = data.Voidkin[rook.Id]
			t.Check("reset", reset.Ok == true and reset.Credits == price and reset.Left == 8)
			t.Check("the repeat answers the same", again.Ok == true and again.Credits == price)
			t.Equal("paid once", data.Currency.Credits, 5)
			t.Check("every point back", next(rook.Points) == nil and Board.Left(rook) == 8)
			local saved = Saveable.Problems(data, "profile")
			t.Check("saves whole", #saved == 0, table.concat(saved, "; "))
		end,
	},
	{
		Name = "Board: no spread lowers a stat, and a level-up with its point waiting never leaves one lower than before",
		Run = function(t: any)
			local data = fresh()
			local failed = 0
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, 1)
				for _, stat in FOUR do
					for level = 1, GrowthConfig.MaxLevel - 1 do
						owned.Level = level
						table.clear(owned.Points)
						owned.Points[stat] = Board.Earned(level)
						local now = Stats.Resolve(owned, nil, nil)
						local want = plain(row.Id, level)
						owned.Level = level + 1 -- the new point waits
						local later = Stats.Resolve(owned, nil, nil)
						for _, other in FOUR do
							local low = (now :: any)[other] < want[other] - 1e-9
							local fell = (later :: any)[other] < (now :: any)[other]
							if low or fell then
								failed += 1
								if failed <= 20 then
									t.Check(`{row.Id} at {level}, every point on {stat}: {other}`, false, if low then "below today's" else `lower at {level + 1}`)
								end
							end
						end
					end
				end
			end
			t.Check(`every Voidkin, every stat, every level ({failed} off)`, failed == 0 and #Voidkin.List > 0)
		end,
	},
	{
		Name = "Board: a save from before the board gains its points, nothing spent",
		Run = function(t: any)
			local data = fresh()
			local rook: any = own(data, "rook", 7)
			rook.Points = nil
			data.Version = 1
			local ran = Migrations.Run(data)
			t.Check("the board's step ran", ran >= 1 and data.Version == Migrations.Latest)
			t.Check("points, none spent", type(rook.Points) == "table" and next(rook.Points) == nil)
			t.Equal("its six earned wait", Board.Left(rook), 6)
			local problems = Saveable.Problems(data, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
