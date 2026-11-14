--!strict
-- Board cases (pure): the stat board, a Voidkin's skill points (docs/design.md, "Skill points"; TR15). Earning one a
-- level, spending it on one of four stats and never another, its worth sized by G and blind to class and rarity, an even
-- spread matching the Voidkin without the board, a spend or a reset repeated or interrupted never counting twice, the
-- reset's price, a level gained with the board open, and an old save gaining its points.
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
		Name = "Board: a point adds its gain, sized by G at the Voidkin's level, the same whatever its class or rarity",
		Run = function(t: any)
			local data = fresh()
			for _, def in { first("Common", "Warrior"), first("Common", "Tank"), first("Mythical", "Assassin"), "pip", "lyric" } do
				local id = own(data, def, 9).Id
				for _, stat in FOUR do
					local before = Stats.Resolve(data.Voidkin[id], nil, nil)
					t.Check(`{def} {stat}`, act(data, "SpendPoint", { Voidkin = id, Stat = stat }).Ok == true)
					local after, lines = Stats.Resolve(data.Voidkin[id], nil, nil)
					local gain = StatsConfig.Board.Point[stat] * Growth.G(9)
					t.Check(`{def} {stat}: one point adds its gain`, near((after :: any)[stat] - (before :: any)[stat], gain), `{(after :: any)[stat] - (before :: any)[stat]}, wanted {gain}`)
					t.Check(`{def} {stat}: the gain the board shows`, near(Board.Gain(stat, 9), gain))
					t.Check(`{def} {stat}: one line, from the board`, near(lineOf(lines, "Board", stat), gain))
					for _, other in FOUR do
						if other ~= stat then
							t.Check(`{def} {stat}: {other} doesn't move`, near((after :: any)[other], (before :: any)[other]))
						end
					end
				end
			end
			local id = own(data, "rook", 2).Id
			act(data, "SpendPoint", { Voidkin = id, Stat = "Health" })
			local rook = data.Voidkin[id]
			rook.Level = 30
			local _, lines = Stats.Resolve(rook, nil, nil)
			t.Check("an early point keeps its worth: sized by G at today's level", near(lineOf(lines, "Board", "Health"), Board.Gain("Health", 30)))
		end,
	},
	{
		Name = "Board: an even spread is the Voidkin without the board, within 2% in whole points, and stars never move",
		Run = function(t: any)
			local data = fresh()
			local worst = 0
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, 1)
				for level = 1, GrowthConfig.MaxLevel do
					owned.Level, owned.Stars = level, 0
					local want = plain(row.Id, level)
					-- A quarter each, as the board counts it: exactly the Voidkin without the board.
					local quarter = Board.Earned(level) / 4
					for _, stat in FOUR do
						owned.Points[stat] = quarter
					end
					local exact = Stats.Resolve(owned, nil, nil)
					for _, stat in FOUR do
						if not near((exact :: any)[stat], want[stat], 1e-9) then
							t.Check(`{row.Id} at {level}: {stat} a quarter each`, false, `{(exact :: any)[stat]}, wanted {want[stat]}`)
						end
					end
					-- In whole points: the remainder goes in the board's order.
					local whole, rest = Board.Earned(level) // 4, Board.Earned(level) % 4
					for index, stat in FOUR do
						owned.Points[stat] = whole + (if index <= rest then 1 else 0)
					end
					local block = Stats.Resolve(owned, nil, nil)
					for _, stat in FOUR do
						worst = math.max(worst, math.abs((block :: any)[stat] - want[stat]) / want[stat])
					end
					owned.Stars = 3
					local _, lines = Stats.Resolve(owned, nil, nil)
					table.clear(owned.Points)
					local _, bare = Stats.Resolve(owned, nil, nil)
					for _, stat in { "Health", "Attack", "Defence" } do
						if not near(lineOf(lines, "Stars", stat), lineOf(bare, "Stars", stat)) then
							t.Check(`{row.Id} at {level}: stars on {stat} don't move with points`, false)
						end
					end
				end
			end
			t.Check(`whole points within 2% ({string.format("%.2f%%", worst * 100)})`, worst <= 0.02)
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
		Name = "Board: no spread takes a stat below nothing, and each class keeps part of its own base at the last level",
		Run = function(t: any)
			local data = fresh()
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, GrowthConfig.MaxLevel)
				for _, stat in FOUR do
					table.clear(owned.Points)
					owned.Points[stat] = Board.Earned(GrowthConfig.MaxLevel)
					local block, lines = Stats.Resolve(owned, nil, nil)
					for _, other in FOUR do
						if other ~= stat then
							local kept = lineOf(lines, if other == "Regen" then "Level" else "Base", other)
							if not (kept > 0 and (block :: any)[other] > 0) then
								t.Check(`{row.Id}, every point on {stat}: {other} keeps part of its own`, false, `{kept}`)
							end
						end
					end
				end
			end
			t.Check("checked every Voidkin", #Voidkin.List > 0)
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
