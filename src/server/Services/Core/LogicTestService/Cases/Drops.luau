--!strict
-- Drops cases (pure): what a fall gives one hitter. Credits and experience follow G and the kind's share; the ground's
-- Standard shard drops on the roll, under the kind's chance; the account's first kill also drops Watt's Named shard, once;
-- the lead levels as far as the experience goes; anything malformed changes nothing. Its save stays saveable.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local Shards = require(Shared.Definitions.Shards)
local Collection = require(Shared.Rules.Collection)
local Growth = require(Shared.Rules.Growth)
local Drops = require(Shared.Rules.Drops)

local NOW = 1_800_000_000
local GROUND = "lanternrow"
local STANDARD = "lanternrow_standard"
local MISS = 0.999 -- a roll that wins no shard at any chance below 1
local SHARE_TOLERANCE = 0.05 -- whole Credits and experience round a share's ratio by this much at level 4

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- A fresh save with Rook as its lead.
local function withLead(): (Profile.Data, Profile.OwnedVoidkin)
	local data = fresh()
	local uncovered = Collection.Uncover(data, "rook", NOW)
	Collection.SetLead(data, uncovered.Id)
	return data, data.Voidkin[uncovered.Id]
end

local function bagCount(data: Profile.Data): number
	local count = 0
	for _, n in data.Bag.Shards do
		count += n
	end
	return count
end

return {
	{
		Name = "Drops: Credits and experience follow G and the kind's share; the shard drops on the roll",
		Run = function(t: any)
			t.Equal("the ground's Standard shard is the one that drops", Shards.ById[STANDARD].Grade, "Standard")
			for _, level in { 1, 4, 9, 30, GrowthConfig.MaxLevel } do
				local drop = Drops.Roll("Ordinary", level, GROUND, MISS)
				t.Check(`an ordinary Shade at level {level} drops`, drop ~= nil)
				if drop then
					t.Equal(`its Credits are CreditsPerKillPerG x G({level})`, drop.Credits, math.floor(DropsConfig.CreditsPerKillPerG * Growth.G(level) + 0.5))
					t.Equal(`its experience is the pace table's kill at level {level}`, drop.Xp, Growth.XpPerKill(level))
				end
			end
			for kind, share in DropsConfig.Share do
				local drop = Drops.Roll(kind, 4, GROUND, MISS) :: Drops.Drop
				local ordinary = Drops.Roll("Ordinary", 4, GROUND, MISS) :: Drops.Drop
				local credits, xp = drop.Credits / ordinary.Credits, drop.Xp / ordinary.Xp
				t.Check(`{kind} pays its share in Credits`, math.abs(credits - share) <= SHARE_TOLERANCE, `{credits} for {share}`)
				t.Check(`{kind} pays its share in experience`, math.abs(xp - share) <= SHARE_TOLERANCE, `{xp} for {share}`)
				local chance = math.min(1, DropsConfig.ShardChance * share)
				t.Equal(`{kind}: a roll of 0 wins the shard`, (Drops.Roll(kind, 4, GROUND, 0) :: Drops.Drop).Shard, STANDARD)
				t.Equal(`{kind}: a roll just under the chance wins it`, (Drops.Roll(kind, 4, GROUND, chance - 1e-9) :: Drops.Drop).Shard, STANDARD)
				if chance < 1 then
					t.Equal(`{kind}: a roll at the chance doesn't`, (Drops.Roll(kind, 4, GROUND, chance) :: Drops.Drop).Shard, "")
				end
			end
		end,
	},
	{
		Name = "Drops: the first kill also drops Watt's shard, once; the lead levels; the save stays saveable",
		Run = function(t: any)
			local data, lead = withLead()
			t.Equal("no kills yet", data.Progress.Kills, 0)
			local first = Drops.Give(data, "Ordinary", 1, GROUND, MISS)
			t.Check("the first kill is written", first.Ok == true and first.Kills == 1)
			t.Equal("and drops Watt's Named shard", first.First, DropsConfig.First)
			t.Equal("which is in the bag", data.Bag.Shards[DropsConfig.First], 1)
			t.Equal("with the kill's Credits", data.Currency.Credits, first.Credits)
			t.Equal("and the lead's experience", lead.Xp, first.Xp)
			local second = Drops.Give(data, "Ordinary", 1, GROUND, 0)
			t.Equal("the second kill drops no Named shard", second.First, "")
			t.Equal("Watt's shard stays one", data.Bag.Shards[DropsConfig.First], 1)
			t.Equal("its roll won the Standard shard", data.Bag.Shards[STANDARD], 1)
			t.Equal("Credits add", data.Currency.Credits, first.Credits + second.Credits)
			-- Enough kills for a level: it rises, and the leftover experience stays.
			local need = Growth.XpToNext(1) :: number
			local kills = 0
			while lead.Level == 1 and kills < need do
				Drops.Give(data, "Ordinary", 1, GROUND, MISS)
				kills += 1
			end
			t.Equal("the lead reaches level 2 at the pace table's kill count", lead.Level, 2)
			local pace = Growth.KillsPerLevel(1)
			t.Check("in Growth.KillsPerLevel kills", math.abs(kills + 2 - pace) <= 1, `{kills + 2} for {pace}`)
			local problems = Saveable.Problems(data)
			t.Check("the save stays saveable", #problems == 0, problems[1])
		end,
	},
	{
		Name = "Drops: without a lead, the rest still drops; anything malformed changes nothing",
		Run = function(t: any)
			local data = fresh()
			local alone = Drops.Give(data, "Elite", 4, GROUND, MISS)
			t.Check("a player without a lead still gets Credits", alone.Ok == true and alone.Credits > 0 and data.Currency.Credits == alone.Credits)
			t.Equal("and no experience", alone.Xp, 0)
			local credits, kills, bag = data.Currency.Credits, data.Progress.Kills, bagCount(data)
			local bad: { { any } } = {
				{ "Dummy", 1, GROUND, 0.5 },
				{ "Lead", 1, GROUND, 0.5 },
				{ nil, 1, GROUND, 0.5 },
				{ "Ordinary", 0, GROUND, 0.5 },
				{ "Ordinary", GrowthConfig.MaxLevel + 1, GROUND, 0.5 },
				{ "Ordinary", 1.5, GROUND, 0.5 },
				{ "Ordinary", 0 / 0, GROUND, 0.5 },
				{ "Ordinary", 1, "nowhere", 0.5 },
				{ "Ordinary", 1, 5, 0.5 },
				{ "Ordinary", 1, GROUND, 1 },
				{ "Ordinary", 1, GROUND, -0.1 },
				{ "Ordinary", 1, GROUND, 0 / 0 },
				{ "Ordinary", 1, GROUND, "0.5" },
			}
			for index, args in bad do
				local answer = Drops.Give(data, args[1], args[2], args[3], args[4])
				t.Check(`malformed fall {index} is refused`, answer.Ok == false and answer.Error == Drops.Unknown)
			end
			t.Check("nothing changed", data.Currency.Credits == credits and data.Progress.Kills == kills and bagCount(data) == bag)
		end,
	},
	{
		-- TR10: the card shown while the elite or the keeper is down reads Roll's own numbers, never copies.
		Name = "Drops: TR10, the loot card is Roll's own numbers, each drop with its chance",
		Run = function(t: any)
			for _, case in { { "Elite", 4 }, { "Keeper", 9 } } do
				local kind, level = case[1] :: string, case[2] :: number
				local card = Drops.Card(kind, level, GROUND)
				local drop = Drops.Roll(kind, level, GROUND, MISS) :: Drops.Drop
				t.Equal(`{kind}: three lines`, #card, 3)
				t.Check(`{kind}: Credits, certain`, card[1].Kind == "Credits" and card[1].Amount == drop.Credits and card[1].Chance == 1)
				t.Check(`{kind}: experience, certain`, card[2].Kind == "Xp" and card[2].Amount == drop.Xp and card[2].Chance == 1)
				local chance = math.min(1, DropsConfig.ShardChance * DropsConfig.Share[kind])
				t.Check(`{kind}: the Standard shard at its chance`, card[3].Kind == "Shard" and card[3].Shard == STANDARD and math.abs(card[3].Chance - chance) < 1e-12, `{card[3].Chance}`)
				t.Equal(`{kind}: a roll just under it wins the shard`, (Drops.Roll(kind, level, GROUND, chance - 1e-9) :: Drops.Drop).Shard, STANDARD)
				t.Equal(`{kind}: one at it doesn't`, (Drops.Roll(kind, level, GROUND, chance) :: Drops.Drop).Shard, "")
			end
			t.Check("the elite's shard, about one in seven", math.abs(Drops.Chance("Elite") - 0.144) < 1e-9)
			t.Equal("a kind that drops nothing: no card", #Drops.Card("Nobody", 4, GROUND), 0)
			t.Equal("a level out of range: no card", #Drops.Card("Elite", 0, GROUND), 0)
		end,
	},
}
