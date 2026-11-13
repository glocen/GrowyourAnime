--!strict
-- Definitions cases (pure): every row complete and every reference resolving, ids unique, and nothing above the top
-- obtainable rarity in any shard. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Voidkin = require(Shared.Definitions.Voidkin)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Rarity = require(Shared.Definitions.Rarity)
local ShardConfig = require(Shared.Config.Shards)
local SoundConfig = require(Shared.Config.Sounds)
local EffectsConfig = require(Shared.Config.Effects)
local FxKit = require(Shared.Config.FxKit)
local Odds = require(Shared.Rules.Odds)
local SoundRule = require(Shared.Rules.Sound)

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
		Name = "Definitions: AR8's effect kit, every mesh and image uploaded, every burn band and front on its coil",
		Run = function(t: any)
			local meshes, images = 0, 0
			for name, mesh in FxKit.Meshes do
				meshes += 1
				t.Check(`{name} has an asset id`, string.find(mesh.Id, "^rbxassetid://%d+$") ~= nil, mesh.Id)
				t.Check(`{name} has a size`, mesh.Size.X > 0 and mesh.Size.Y > 0 and mesh.Size.Z > 0)
				if mesh.Of then
					t.Check(`{name} is a band of a coil in the kit`, FxKit.Meshes[mesh.Of] ~= nil and mesh.Of ~= name, tostring(mesh.Of))
					t.Check(`{name} is a band 1 to 6 or a front 1 to 5, with its offset`, mesh.Offset ~= nil
						and ((mesh.Band ~= nil and mesh.Front == nil and mesh.Band >= 1 and mesh.Band <= 6)
							or (mesh.Front ~= nil and mesh.Band == nil and mesh.Front >= 1 and mesh.Front <= 5)))
				end
			end
			for name, image in FxKit.Images do
				images += 1
				t.Check(`{name} has an asset id`, string.find(image.Id, "^rbxassetid://%d+$") ~= nil, image.Id)
			end
			t.Equal("the kit's 28 meshes", meshes, 28)
			t.Equal("its 20 images", images, 20)
			for coil, fronts in ({ FxCoil2 = 5, FxCoil3 = 0 } :: { [string]: number }) do
				local bands, edges = 0, 0
				for _, mesh in FxKit.Meshes do
					bands += if mesh.Of == coil and mesh.Band then 1 else 0
					edges += if mesh.Of == coil and mesh.Front then 1 else 0
				end
				t.Equal(`{coil} burns in six bands`, bands, 6)
				t.Equal(`{coil}'s burning fronts`, edges, fronts)
			end
			t.Check("the fire bands' Flame uploaded (B1's finish)", FxKit.Images.fx_fire_Flame ~= nil)
			for name in FxKit.Palettes do
				for _, family in { "fx_across_", "fx_rise_", "fx_ribs_" } do
					t.Check(`{family}{name} uploaded`, FxKit.Images[family .. name] ~= nil)
				end
			end
		end,
	},
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
	{
		Name = "Definitions: sound cues are whole, levelled within bounds, and resolve",
		Run = function(t: any)
			local all = SoundConfig.Cues :: { [string]: SoundConfig.Cue }
			for name, cue in all do
				t.Check(`{name} has a library id`, type(cue.Id) == "number" and cue.Id > 0)
				t.Check(`{name}'s slice runs forward`, cue.From >= 0 and cue.To > cue.From)
				local gain = SoundRule.Gain(cue)
				t.Check(`{name}'s pitch spread`, cue.Pitch[1] > 0 and cue.Pitch[2] >= cue.Pitch[1])
				if SoundRule.Screen(cue) then
					-- the screen's cues are bounded where they're mixed (Reveal's case: no file played past twice its own)
					t.Check(`{name} is not turned down past the bound`, gain >= SoundConfig.Gain[1], string.format("%.2f", gain))
				else
					t.Check(`{name} levels within the bounds`, gain >= SoundConfig.Gain[1] and gain <= SoundConfig.Gain[2], string.format("%.2f", gain))
					t.Check(`{name} fades out past its full volume`, cue.Near > 0 and cue.Range > cue.Near)
				end
			end
			local strike = EffectsConfig.Haymaker.Sound
			t.Check("Haymaker's strike cue resolves", all[strike] ~= nil, strike)
		end,
	},
}
