--!strict
-- Definitions cases (pure): every row complete and every reference resolving, ids unique, and nothing above the top
-- obtainable rarity in any shard. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Voidkin = require(Shared.Definitions.Voidkin)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Rarity = require(Shared.Definitions.Rarity)
local ShardConfig = require(Shared.Config.Shards)
local Odds = require(Shared.Rules.Odds)

local TYPES = { Agility = true, Strength = true, Endurance = true, Intelligence = true, Technique = true }
local CLASSES = { Warrior = true, Tank = true, Assassin = true, Mage = true, Healer = true }
local ELEMENTS = { [""] = true, Fire = true, Frost = true, Storm = true, Void = true }

local function unique(t: any, list: { any }, label: string)
	local seen = {}
	for _, row in list do
		t.Check(`{label} {row.Id} once`, not seen[row.Id])
		t.Check(`{label} {row.Id} is a plain id`, string.find(row.Id, "^[a-z][a-z0-9_]*$") ~= nil)
		seen[row.Id] = true
	end
end

return {
	{
		Name = "Definitions: Voidkin rows are complete",
		Run = function(t: any)
			unique(t, Voidkin.List, "Voidkin")
			t.Equal("thirty-one", #Voidkin.List, 31)
			for _, row in Voidkin.List do
				t.Check(`{row.Id} rarity`, Rarity.Rank[row.Rarity] ~= nil, row.Rarity)
				t.Check(`{row.Id} type`, TYPES[row.Type] == true, row.Type)
				t.Check(`{row.Id} class`, CLASSES[row.Class] == true, row.Class)
				t.Check(`{row.Id} element`, ELEMENTS[row.Element] == true, row.Element)
				t.Check(`{row.Id} zone is a ground`, row.Zone >= 1 and row.Zone <= #Grounds.List)
				t.Check(`{row.Id} aptitude 1 to 3`, row.Aptitude >= 1 and row.Aptitude <= 3)
				t.Check(`{row.Id} has a name`, #row.Name > 0)
			end
		end,
	},
	{
		Name = "Definitions: grounds run in order",
		Run = function(t: any)
			unique(t, Grounds.List, "Ground")
			for index, row in Grounds.List do
				t.Equal(`{row.Id} order`, row.Order, index)
				t.Check(`{row.Id} has a region factor`, ShardConfig.RegionFactor[row.Id] ~= nil)
			end
			t.Check("the first ground exists", Grounds.ById[Grounds.First] ~= nil)
		end,
	},
	{
		Name = "Definitions: shards resolve",
		Run = function(t: any)
			unique(t, Shards.List, "Shard")
			for _, row in Shards.List do
				t.Check(`{row.Id} grade has numbers`, ShardConfig.Grades[row.Grade] ~= nil, row.Grade)
				t.Check(`{row.Id} ground`, Grounds.ById[row.Ground] ~= nil, row.Ground)
				local fixed = row.Grade == "Named" or row.Grade == "Starter"
				if fixed then
					t.Check(`{row.Id} holds a Voidkin`, Voidkin.ById[row.Holds] ~= nil, row.Holds)
				else
					t.Equal(`{row.Id} rolls`, row.Holds, "")
					t.Check(`{row.Id} grade has a pool`, ShardConfig.Pools[row.Grade] ~= nil)
				end
			end
			t.Equal("three starters", #Shards.Starters, 3)
			for _, id in Shards.Starters do
				t.Check(`{id} is a starter`, Shards.ById[id] ~= nil and Shards.ById[id].Grade == "Starter")
			end
		end,
	},
	{
		Name = "Definitions: nothing above the top rarity can drop",
		Run = function(t: any)
			local top = Rarity.Rank[Rarity.ObtainableTop]
			for _, shard in Shards.List do
				for _, entry in Odds.Table(shard.Id, ShardConfig.LuckCap) do
					t.Check(`{shard.Id} gives {entry.Id}`, Rarity.Rank[Voidkin.ById[entry.Id].Rarity] <= top)
				end
			end
			for grade, weights in ShardConfig.Pools do
				for _, name in Rarity.Order do
					t.Check(`{grade} weighs {name}`, weights[name] ~= nil)
				end
			end
		end,
	},
}
