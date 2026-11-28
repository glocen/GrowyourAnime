--!strict
-- Growing cases (pure): growing a Voidkin (docs/design.md, "Growing a Voidkin"; TR76). Mastery's experience to a rank,
-- a rank's points on its class's Main and nowhere else, earned by the lead alone from each fall; a signature's level paid
-- with Skill Manuals and Credits in one step, which a repeated or cut request never spends twice (section 9), and its
-- rows, level 1 the action's own; the star perks at 3, 5 and 7, star 5's passive step a copy, never the definition.
-- The numbers are placeholders (Config.Mastery, Config.Signature): these cases read them, never pin them.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local MasteryConfig = require(Shared.Config.Mastery)
local SignatureConfig = require(Shared.Config.Signature)
local VoidkinConfig = require(Shared.Config.Voidkin)
local StatsConfig = require(Shared.Config.Stats)
local Actions = require(Shared.Definitions.Actions)
local Passives = require(Shared.Definitions.Passives)
local Tokens = require(Shared.Definitions.Tokens)
local Voidkin = require(Shared.Definitions.Voidkin)
local Collection = require(Shared.Rules.Collection)
local Mastery = require(Shared.Rules.Mastery)
local Signature = require(Shared.Rules.Signature)
local Passive = require(Shared.Rules.Passive)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Drops = require(Shared.Rules.Drops)
local Refusal = require(Shared.Rules.Refusal)

local NOW = 1_800_000_000
local OP = "0f1e2d3c-4b5a-4968-8776-655443322110"
local OTHER_OP = "1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(a), math.abs(b))
end

local function leading(def: string): (Profile.Data, Profile.OwnedVoidkin)
	local data = fresh()
	local id = Collection.Uncover(data, def, NOW).Id
	data.Roles.Lead = id
	return data, data.Voidkin[id]
end

local function sumOf(lines: { Stats.Line }, source: string, stat: string?): number
	local total = 0
	for _, line in lines do
		if line.Source == source and (stat == nil or line.Stat == stat) then
			total += line.Value
		end
	end
	return total
end

local LAST = MasteryConfig.Ranks[#MasteryConfig.Ranks]

return {
	{
		Name = "Growing: Mastery's experience holds its rank at each edge, and the next rank's need",
		Run = function(t: any)
			t.Equal("none, rank 0", Mastery.Rank(0), 0)
			for rank, need in MasteryConfig.Ranks do
				t.Equal(`one short of rank {rank}`, Mastery.Rank(need - 1), rank - 1)
				t.Equal(`rank {rank} at {need}`, Mastery.Rank(need), rank)
			end
			t.Equal("past the last, still the last", Mastery.Rank(LAST * 10), #MasteryConfig.Ranks)
			local need, left = Mastery.Next(MasteryConfig.Ranks[1] + 1)
			t.Check("the next rank's need and what's left", need == MasteryConfig.Ranks[2] and left == MasteryConfig.Ranks[2] - MasteryConfig.Ranks[1] - 1)
			t.Check("none at the last", Mastery.Next(LAST) == nil)
			local rising = true
			for rank = 2, #MasteryConfig.Ranks do
				rising = rising and MasteryConfig.Ranks[rank] > MasteryConfig.Ranks[rank - 1]
					and MasteryConfig.Points[rank] > MasteryConfig.Points[rank - 1]
			end
			t.Check("each rank takes more and gives more", rising and #MasteryConfig.Points == #MasteryConfig.Ranks)
		end,
	},
	{
		Name = "Growing: Mastery adds what it's given, gains ranks, stops at the last, and takes no nonsense",
		Run = function(t: any)
			local _, owned = leading("rook")
			t.Equal("a new Voidkin has none", Mastery.Xp(owned), 0)
			t.Check("nil in the save", owned.Mastery == nil)
			t.Equal("short of rank 1, no rank", Mastery.Add(owned, MasteryConfig.Ranks[1] - 1), 0)
			t.Equal("one more, rank 1", Mastery.Add(owned, 1), 1)
			t.Equal("past two ranks at once", Mastery.Add(owned, MasteryConfig.Ranks[3] - MasteryConfig.Ranks[1]), 2)
			t.Equal("rank 3", Mastery.Rank(Mastery.Xp(owned)), 3)
			for _, bad in { -5, 0, 0 / 0, math.huge, -math.huge } do
				local before = Mastery.Xp(owned)
				t.Check(`{bad} adds nothing`, Mastery.Add(owned, bad) == 0 and Mastery.Xp(owned) == before)
			end
			Mastery.Add(owned, LAST * 3)
			t.Equal("held at the last rank's need", Mastery.Xp(owned), LAST)
			t.Equal("nothing more at the last", Mastery.Add(owned, 100), 0)
			t.Equal("still there", Mastery.Xp(owned), LAST)
		end,
	},
	{
		Name = "Growing: a Mastery rank adds its points to its class's Main on G(level), and nothing else moves",
		Run = function(t: any)
			for _, row in Voidkin.List do
				local main = StatsConfig.Attributes.Main[row.Class]
				if main == nil then
					continue
				end
				local _, owned = leading(row.Id)
				owned.Level = 30
				local before, beforeLines = Stats.Resolve(owned, nil, nil)
				t.Equal(`{row.Id}: rank 0 gives no line`, sumOf(beforeLines, "Mastery"), 0)
				owned.Mastery = MasteryConfig.Ranks[#MasteryConfig.Ranks]
				local after, lines = Stats.Resolve(owned, nil, nil)
				local want = MasteryConfig.Points[#MasteryConfig.Points] * Growth.G(30)
				t.Check(`{row.Id}: rank 5 on {main.Attribute}`, near(sumOf(lines, "Mastery", main.Attribute), want) and near(sumOf(lines, "Mastery"), want))
				t.Check(`{row.Id}: its Main's total rises by as much`, near(after.Attributes[main.Attribute] - before.Attributes[main.Attribute], want))
				local others = true
				for id, value in after.Attributes do
					if id ~= main.Attribute then
						others = others and near(value, before.Attributes[id])
					end
				end
				t.Check(`{row.Id}: no other attribute moves`, others)
				t.Check(`{row.Id}: stronger`, Stats.Sum(after) > Stats.Sum(before))
			end
			t.Equal("no rank, no points", Mastery.Points(0, 60), 0)
			t.Check("rank 1 at level 1 is its row", near(Mastery.Points(1, 1), MasteryConfig.Points[1]))
		end,
	},
	{
		Name = "Growing: the placeholder's mark holds, rank 5 about 11% of a Common's own points (about 4% of a level-60 build)",
		Run = function(t: any)
			for class, shape in StatsConfig.Attributes.Shape do
				local own = 0
				for _, points in shape do
					own += points
				end
				local share = MasteryConfig.Points[#MasteryConfig.Points] / own
				t.Check(`{class}: {string.format("%.1f", share * 100)}% of its own`, share >= 0.09 and share <= 0.14)
			end
		end,
	},
	{
		Name = "Growing: each fall gives the lead its kind's Mastery, never multiplied, and nobody else",
		Run = function(t: any)
			local data, lead = leading("rook")
			local other = data.Voidkin[Collection.Uncover(data, "kirra", NOW).Id]
			local kinds = { "Ordinary", "Elite", "Keeper" }
			local total = 0
			for _, kind in kinds do
				local answer = Drops.Give(data, kind, 1, "lanternrow", 0.99, nil, nil, nil)
				total += MasteryConfig.Gain[kind]
				t.Check(`a {kind}'s fall: {MasteryConfig.Gain[kind]}`, answer.Ok == true and answer.Mastery == MasteryConfig.Gain[kind] and Mastery.Xp(lead) == total)
			end
			t.Equal("the other Voidkin earns none", Mastery.Xp(other), 0)
			-- the catch-up multiplies experience, never Mastery
			other.Level = 40
			local before = Mastery.Xp(lead)
			local answer = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, nil, nil, nil)
			t.Check("a lead far behind gets its experience x2", answer.Xp > 0 and Growth.CatchUp(data, lead) > 1)
			t.Equal("and its Mastery as it is", Mastery.Xp(lead) - before, MasteryConfig.Gain.Ordinary)
			-- the rank lands in the answer
			lead.Mastery = MasteryConfig.Ranks[1] - 1
			local ranked = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, nil, nil, nil)
			t.Equal("the fall that reaches rank 1 says so", ranked.Ranks, 1)
			local none = fresh()
			local free = Drops.Give(none, "Ordinary", 1, "lanternrow", 0.99, nil, nil, nil)
			t.Check("no lead: no Mastery, the rest still paid", free.Ok == true and free.Mastery == 0 and free.Credits > 0)
			t.Equal("an unknown kind gives none", Mastery.Earned("Nobody"), 0)
			t.Equal("a Warden's win", Mastery.Earned("Warden"), MasteryConfig.Gain.Warden)
			t.Equal("a bout's win", Mastery.Earned("Bout"), MasteryConfig.Gain.Bout)
		end,
	},
	{
		Name = "Growing: a signature's level is paid in Skill Manuals and Credits, exactly, and refused short",
		Run = function(t: any)
			local data, owned = leading("rook")
			t.Equal("a new Voidkin's signature is level 1", Signature.Level(owned), 1)
			t.Check("Skill Manuals are a bag token", Tokens.ById[Signature.Token] ~= nil and Tokens.ById[Signature.Token].Name == "Skill Manual")
			local cost = Signature.Cost(owned)
			t.Check("level 2's cost", cost ~= nil and cost.Manuals == SignatureConfig.Cost[2].Manuals and cost.Credits == SignatureConfig.Cost[2].Credits)
			assert(cost)
			data.Currency.Credits = cost.Credits
			data.Bag.Tokens.Manual = cost.Manuals - 1
			local short = Signature.Raise(data, owned.Id)
			t.Equal("it says how many", Refusal.Of("Voidkin", short), "Need 1 more Skill Manuals")
			t.Check("a manual short: refused, nothing spent", short.Error == Signature.NoManuals and data.Bag.Tokens.Manual == cost.Manuals - 1 and data.Currency.Credits == cost.Credits and Signature.Level(owned) == 1)
			data.Bag.Tokens.Manual = cost.Manuals
			data.Currency.Credits = cost.Credits - 1
			local poor = Signature.Raise(data, owned.Id)
			t.Equal("it says how many Credits", Refusal.Of("Voidkin", poor), "Need 1 more Credits")
			t.Check("a Credit short: refused, nothing spent", poor.Error == Signature.NoCredits and data.Bag.Tokens.Manual == cost.Manuals and data.Currency.Credits == cost.Credits - 1)
			data.Currency.Credits = cost.Credits + 7
			local raised = Signature.Raise(data, owned.Id)
			t.Check("paid: level 2", raised.Ok == true and raised.Level == 2 and owned.Signature == 2)
			t.Check("both spent, exactly", data.Bag.Tokens.Manual == nil and data.Currency.Credits == 7 and raised.Manuals == cost.Manuals and raised.Credits == cost.Credits)
			-- up to the last, then refused
			data.Bag.Tokens.Manual = 1000
			data.Currency.Credits = 1e9
			for level = 3, SignatureConfig.MaxLevel do
				local up = Signature.Raise(data, owned.Id)
				t.Check(`level {level}`, up.Ok == true and up.Level == level and up.Manuals == SignatureConfig.Cost[level].Manuals)
			end
			local left = data.Bag.Tokens.Manual
			t.Check("none past the last", Signature.Cost(owned) == nil and Signature.Raise(data, owned.Id).Error == Signature.MaxLevel and data.Bag.Tokens.Manual == left)
			t.Equal("an unknown Voidkin is refused", Signature.Raise(data, "nobody").Error, Signature.Unknown)
			for _, code in { Signature.NoManuals, Signature.NoCredits, Signature.MaxLevel, "InCombat" } do
				t.Check(`the Voidkin screen words {code}`, Refusal.Has("Voidkin", code))
			end
			t.Equal("a non-string id is refused", Signature.Raise(data, 5).Error, Signature.Unknown)
			-- a save edited past the ends reads in range
			owned.Signature = 99
			t.Equal("past the last reads the last", Signature.Level(owned), SignatureConfig.MaxLevel)
			owned.Signature = 0 / 0
			t.Equal("nonsense reads 1", Signature.Level(owned), 1)
			local problems = Saveable.Problems((function()
				owned.Signature = 3
				owned.Mastery = 40
				return data
			end)(), "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Growing (section 9): a signature level bought under one op id is bought once, and an interrupted one spends nothing",
		Run = function(t: any)
			local data, owned = leading("pip")
			local cost = SignatureConfig.Cost[2]
			data.Bag.Tokens.Manual = cost.Manuals + SignatureConfig.Cost[3].Manuals
			data.Currency.Credits = cost.Credits + SignatureConfig.Cost[3].Credits
			local function raise(cut: boolean?): Transaction.Change
				return function(draft: Profile.Data): Transaction.Answer
					local answer = Collection.Actions.RaiseSignature(draft, { Voidkin = owned.Id }, NOW, 0)
					if cut then
						error("interrupted")
					end
					return answer
				end
			end
			local first, changed = Transaction.Run(data, OP, raise(), 8)
			t.Check("the first raise", first.Ok == true and changed and data.Voidkin[owned.Id].Signature == 2)
			local manuals, credits = data.Bag.Tokens.Manual, data.Currency.Credits
			local again, againChanged = Transaction.Run(data, OP, raise(), 8)
			t.Check("its repeat raises nothing and spends nothing", not againChanged and data.Voidkin[owned.Id].Signature == 2 and data.Bag.Tokens.Manual == manuals and data.Currency.Credits == credits)
			t.Equal("and answers as the first did", again.Level, 2)
			local cut, cutChanged = Transaction.Run(data, OTHER_OP, raise(true), 8)
			t.Check("an interrupted raise keeps the manuals, the Credits and the level", cut.Ok == false and not cutChanged and data.Voidkin[owned.Id].Signature == 2 and data.Bag.Tokens.Manual == manuals and data.Currency.Credits == credits)
			local retry = Transaction.Run(data, OTHER_OP, raise(), 8)
			t.Check("its retry raises once", retry.Ok == true and data.Voidkin[owned.Id].Signature == 3 and data.Bag.Tokens.Manual == nil and data.Currency.Credits == 0)
		end,
	},
	{
		Name = "Growing: each signature's rows start at its action's own, rise each level, and name only its beats",
		Run = function(t: any)
			local covered = 0
			for action, beats in SignatureConfig.Rows do
				local def = Actions.ById[action]
				t.Check(`{action} is an action`, def ~= nil)
				if def == nil then
					continue
				end
				for beat, row in beats do
					local hit = def.Hits[beat]
					t.Check(`{action}.{beat} is one of its hits`, hit ~= nil)
					if hit == nil then
						continue
					end
					t.Check(`{action}.{beat}: five rows`, #row == SignatureConfig.MaxLevel)
					t.Check(`{action}.{beat}: level 1 is its own {hit.Coefficient}`, near(row[1], hit.Coefficient))
					local rising = true
					for level = 2, #row do
						rising = rising and row[level] > row[level - 1]
					end
					t.Check(`{action}.{beat}: each level better`, rising)
					t.Check(`{action}.{beat}: read by level`, near(Signature.Coefficient(action, beat, 3, hit.Coefficient), row[3]))
				end
				covered += 1
			end
			-- every kit's signature has its rows
			for _, row in Voidkin.List do
				if row.Kit then
					t.Check(`{row.Id}'s signature has rows`, SignatureConfig.Rows[row.Kit.Signature] ~= nil)
				end
			end
			t.Check("a hit without rows keeps its own", Signature.Coefficient("RookCombo", "Hit1", 5, 0.9) == 0.9)
			t.Check("a level past the rows reads the last", near(Signature.Coefficient("RookHaymaker", "Strike", 9, 4), SignatureConfig.Rows.RookHaymaker.Strike[SignatureConfig.MaxLevel]))
			t.Check("signatures covered", covered >= 5)
		end,
	},
	{
		Name = "Growing: a signature's level raises its kit's rate and its Combat Power; level 1 changes nothing",
		Run = function(t: any)
			for _, def in { "rook", "kirra", "pip", "watt", "lyric" } do
				local one = Stats.Rate(def, 1, 0)
				t.Check(`{def}: level 1 is the kit as before`, near(Stats.Rate(def), one))
				t.Check(`{def}: level 5's rate is higher`, Stats.Rate(def, 5, 0) > one)
				local _, owned = leading(def)
				owned.Level = 20
				local before = Stats.Sum((Stats.Resolve(owned, nil, nil)))
				owned.Signature = 5
				local block = Stats.Resolve(owned, nil, nil)
				t.Equal(`{def}: the block carries its level`, block.Signature, 5)
				t.Check(`{def}: stronger at level 5`, Stats.Sum(block) > before)
			end
			local enemy = Stats.Empty(10)
			t.Check("an enemy's block: no stars, level 1", enemy.Stars == 0 and enemy.Signature == 1)
		end,
	},
	{
		Name = "Growing: star perks at 3, 5 and 7; star 5's passive step is a copy on its row",
		Run = function(t: any)
			local at = VoidkinConfig.Perks
			local none = Collection.Perks(at.Colour - 1)
			t.Check("below star 3: none", not none.Colour and not none.Passive and not none.Gold)
			local three = Collection.Perks(at.Colour)
			t.Check("star 3: its signature's colour", three.Colour and not three.Passive and not three.Gold)
			local five = Collection.Perks(at.Passive)
			t.Check("star 5: and its passive's step", five.Colour and five.Passive and not five.Gold)
			local seven = Collection.Perks(at.Gold)
			t.Check("star 7: and its gold", seven.Colour and seven.Passive and seven.Gold)
			t.Check("the last star holds them all", at.Gold <= VoidkinConfig.MaxStars)
			for _, row in Passives.List do
				local share = row.Share
				t.Check(`{row.Id}: below star 5, its own row`, Passive.At(row, at.Passive - 1) == row)
				local stepped = Passive.At(row, at.Passive)
				if row.Step then
					t.Check(`{row.Id}: from star 5, {share} + {row.Step}`, stepped ~= row and stepped ~= nil and near(stepped.Share, share + row.Step) and stepped.Kind == row.Kind)
				else
					t.Check(`{row.Id}: no step yet, its own row`, stepped == row)
				end
				t.Equal(`{row.Id}: the definition untouched`, row.Share, share)
			end
			t.Check("no row, none", Passive.At(nil, 7) == nil)
			-- the step reaches a hit: Second Wind takes Share + Step less from star 5
			local rook = Passives.ById.rook
			t.Check("Second Wind from star 5", near(Passive.Reduction(Passive.At(rook, at.Passive), 1, 10), rook.Share + (rook.Step or 0)))
			-- and the block carries its stars to the fight
			local _, owned = leading("watt")
			owned.Stars = at.Passive
			local block = Stats.Resolve(owned, nil, nil)
			t.Equal("the block carries its stars", block.Stars, at.Passive)
		end,
	},
	{
		Name = "Growing: a new save holds an empty token bag; tokens are named",
		Run = function(t: any)
			local data = fresh()
			t.Check("Bag.Tokens is there and empty", type(data.Bag.Tokens) == "table" and next(data.Bag.Tokens) == nil)
			for _, id in { "Manual", "Seal", "Crest" } do
				local row = Tokens.ById[id]
				t.Check(`{id} is named`, row ~= nil and row.Name ~= "" and row.Plural ~= "")
			end
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
