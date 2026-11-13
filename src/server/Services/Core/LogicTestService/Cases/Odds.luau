--!strict
-- Odds cases (pure): every table sums to one, a Named shard is certain, ground 1's Standard, Enriched and Prismatic shards
-- match the seeds by hand, luck lifts the top two tiers and stops at its cap, featured Voidkin weigh more, and a large
-- sample of rolls lands on the odds shown. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Odds = require(Shared.Rules.Odds)
local Shards = require(Shared.Definitions.Shards)
local ShardConfig = require(Shared.Config.Shards)

local STANDARD = "lanternrow_standard"

local function chanceOf(entries: { Odds.Entry }, id: string): number
	for _, entry in entries do
		if entry.Id == id then
			return entry.Chance
		end
	end
	return 0
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- A seeded stream of numbers in (0, 1), the same in Studio and in Lune (Random isn't in both). Park–Miller: the product
-- stays under 2^47, so doubles hold it exactly (a 2^30 multiplier would pass 2^53 and lose its low bits).
local MODULUS = 2147483647
local function stream(seed: number): () -> number
	local state = seed % MODULUS
	return function(): number
		state = (state * 48271) % MODULUS
		return state / MODULUS
	end
end

return {
	{
		Name = "Odds: every shard's table sums to one",
		Run = function(t: any)
			for _, shard in Shards.List do
				for _, luck in { 0, 0.2, ShardConfig.LuckCap } do
					local sum = 0
					for _, entry in Odds.Table(shard.Id, luck) do
						sum += entry.Chance
					end
					t.Check(`{shard.Id} at luck {luck}`, near(sum, 1), `sum {sum}`)
				end
			end
		end,
	},
	{
		Name = "Odds: a Named shard holds one Voidkin, for certain",
		Run = function(t: any)
			local entries = Odds.Table("named_watt", ShardConfig.LuckCap)
			t.Equal("one entry", #entries, 1)
			t.Equal("Watt", entries[1].Id, "watt")
			t.Equal("certain", entries[1].Chance, 1)
			t.Equal("rolled", Odds.Roll("named_watt", 0, 0.99), "watt")
		end,
	},
	{
		Name = "Odds: ground 1's Standard shard, worked by hand",
		Run = function(t: any)
			-- Ground 1 holds eight (docs/roster.md, Lantern Row's shards at launch, research's call of 2026-11-13): four
			-- Commons (Rook, Kirra, Pip, Watt; Patch moved to Drum Court), Sable (Uncommon), Lyric (Rare), Marigold (Epic) and
			-- Crane (Legendary). The Standard pool weighs them 60, 30, 9 and 1, and gives no Legendary.
			local entries = Odds.Table(STANDARD, 0)
			t.Equal("seven Voidkin", #entries, 7)
			t.Check("Rook a quarter of the Commons", near(chanceOf(entries, "rook"), 60 / 100 / 4))
			t.Check("Sable 30 in 100", near(chanceOf(entries, "sable"), 30 / 100))
			t.Check("Lyric 9 in 100", near(chanceOf(entries, "lyric"), 9 / 100))
			t.Check("Marigold 1 in 100", near(chanceOf(entries, "marigold"), 1 / 100))
			t.Equal("no Crane from a Standard", chanceOf(entries, "crane"), 0)
			t.Equal("nothing from ground 2", chanceOf(entries, "patch"), 0)
		end,
	},
	{
		Name = "Odds: luck lifts the top tiers, up to its cap",
		Run = function(t: any)
			-- four tiers live (Common to Epic), so the top two, Rare and Epic, are lifted
			local lifted = Odds.Table(STANDARD, 0.4)
			local total = 60 + 30 + (9 + 1) * 1.4
			t.Check("Lyric lifted", near(chanceOf(lifted, "lyric"), 9 * 1.4 / total))
			t.Check("Marigold lifted", near(chanceOf(lifted, "marigold"), 1 * 1.4 / total))
			t.Check("Sable not", near(chanceOf(lifted, "sable"), 30 / total))
			t.Check("the Commons not", near(chanceOf(lifted, "rook"), 60 / total / 4))
			local capped = Odds.Table(STANDARD, 5)
			local atCap = Odds.Table(STANDARD, ShardConfig.LuckCap)
			t.Check("past the cap is the cap", near(chanceOf(capped, "marigold"), chanceOf(atCap, "marigold")))
			local negative = Odds.Table(STANDARD, -1)
			t.Check("no negative luck", near(chanceOf(negative, "marigold"), 1 / 100))
		end,
	},
	{
		Name = "Odds: Lantern Row's Enriched and Prismatic shards reach Epic and Legendary, worked by hand",
		Run = function(t: any)
			-- Rows for this case only: the grades exist in Config.Shards.Pools, their Lantern Row shards not yet.
			local rows: { [string]: any } = {
				case_lanternrow_enriched = { Id = "case_lanternrow_enriched", Grade = "Enriched", Ground = "lanternrow", Holds = "" },
				case_lanternrow_prismatic = { Id = "case_lanternrow_prismatic", Grade = "Prismatic", Ground = "lanternrow", Holds = "" },
			}
			for id, row in rows do
				Shards.ById[id] = row
			end
			local ok, err = pcall(function()
				-- Enriched: no Commons; Uncommon 45, Rare 35, Epic 16, Legendary 4
				local enriched = Odds.Table("case_lanternrow_enriched", 0)
				t.Equal("Enriched: four Voidkin", #enriched, 4)
				t.Check("Enriched: Sable 45 in 100", near(chanceOf(enriched, "sable"), 45 / 100))
				t.Check("Enriched: Lyric 35 in 100", near(chanceOf(enriched, "lyric"), 35 / 100))
				t.Check("Enriched: Marigold 16 in 100", near(chanceOf(enriched, "marigold"), 16 / 100))
				t.Check("Enriched: Crane 4 in 100", near(chanceOf(enriched, "crane"), 4 / 100))
				-- Prismatic: Rare 40, Epic 38, Legendary 18; its Mythical 4 has no one on ground 1, so it drops out
				local prismatic = Odds.Table("case_lanternrow_prismatic", 0)
				t.Equal("Prismatic: three Voidkin", #prismatic, 3)
				t.Check("Prismatic: Lyric 40 in 96", near(chanceOf(prismatic, "lyric"), 40 / 96))
				t.Check("Prismatic: Marigold 38 in 96", near(chanceOf(prismatic, "marigold"), 38 / 96))
				t.Check("Prismatic: Crane 18 in 96", near(chanceOf(prismatic, "crane"), 18 / 96))
			end)
			for id in rows do
				Shards.ById[id] = nil
			end
			t.Check("ran", ok, tostring(err))
		end,
	},
	{
		Name = "Odds: the ground's own Voidkin are featured",
		Run = function(t: any)
			-- A ground-3 shard for this case only: ground 1's Commons are older than ground 2's, so they weigh 1 against 3.
			local id = "case_maskparade_standard"
			local row = { Id = id, Grade = "Standard", Ground = "maskparade", Holds = "" }
			Shards.ById[id] = row :: any
			local ok, err = pcall(function()
				local entries = Odds.Table(id, 0)
				local rook, tumble = chanceOf(entries, "rook"), chanceOf(entries, "tumble")
				t.Check("Tumble (zone 2) weighs three Rooks (zone 1)", near(tumble, rook * ShardConfig.FeaturedWeight), `{tumble} against {rook}`)
			end)
			Shards.ById[id] = nil
			t.Check("ran", ok, tostring(err))
		end,
	},
	{
		Name = "Odds: a large sample lands on the odds shown",
		Run = function(t: any)
			local n = 60000
			local entries = Odds.Table(STANDARD, 0)
			local counts: { [string]: number } = {}
			local u = stream(20261112)
			for _ = 1, n do
				local id = Odds.Roll(STANDARD, 0, u()) :: string
				counts[id] = (counts[id] or 0) + 1
			end
			for _, entry in entries do
				local p = entry.Chance
				local spread = 4 * math.sqrt(p * (1 - p) / n) -- four standard errors
				local seen = (counts[entry.Id] or 0) / n
				t.Check(`{entry.Id} at {string.format("%.4f", p)}`, math.abs(seen - p) <= spread, `seen {string.format("%.4f", seen)}`)
			end
			t.Equal("u near 0 gives the first", Odds.Roll(STANDARD, 0, 0), entries[1].Id)
			t.Equal("u near 1 gives the last", Odds.Roll(STANDARD, 0, 0.9999999), entries[#entries].Id)
			t.Equal("an unknown shard gives nothing", Odds.Roll("nothing", 0, 0.5), nil)
		end,
	},
}
