--!strict
-- Odds cases (pure): every table sums to one, a Named shard is certain, ground 1's Standard, Enriched and Prismatic shards
-- match the seeds by hand, luck lifts the top two tiers and stops at its cap, featured Voidkin weigh more, and a large
-- sample of rolls lands on the odds shown; the drop rates the player reads hold every Voidkin under its rarity's total and
-- add to 100%; and only a made Voidkin comes out of a shard (TR24's guard), each one made with its portraits. The rule's
-- own math is worked with ground 1's eight all made (asMade); the launch's table, with its five. Runs in Studio
-- (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Odds = require(Shared.Rules.Odds)
local Shards = require(Shared.Definitions.Shards)
local ShardConfig = require(Shared.Config.Shards)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local UIKit = require(Shared.Config.UIKit)

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

-- Runs `run` with the Voidkin `ids` as if made (a body, moves, no clips due), then puts their rows back: the rule's math
-- worked on a roster not built yet. Whether it ran, and its error.
local function asMade(ids: { string }, run: () -> ()): (boolean, any)
	local kept: { [string]: { Model: string?, Kit: any, ClipsDue: string? } } = {}
	for _, id in ids do
		local row: any = Voidkin.ById[id]
		kept[id] = { Model = row.Model, Kit = row.Kit, ClipsDue = row.ClipsDue }
		row.Model, row.ClipsDue = row.Model or "Case", nil
		row.Kit = row.Kit or { Signature = "Case", Combo = "Case" }
	end
	local ok, err = pcall(run)
	for id, was in kept do
		local row: any = Voidkin.ById[id]
		row.Model, row.Kit, row.ClipsDue = was.Model, was.Kit, was.ClipsDue
	end
	return ok, err
end

local WAITING = { "sable", "marigold", "crane" } -- ground 1's three not made at launch (the director, 2026-11-17, 02:40)

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
		Name = "Odds: ground 1's Standard shard, its eight made, worked by hand",
		Run = function(t: any)
			-- Ground 1 holds eight (docs/roster.md, Lantern Row's shards at launch, research's call of 2026-11-13): four
			-- Commons (Rook, Kirra, Pip, Watt; Patch moved to Drum Court), Sable (Uncommon), Lyric (Rare), Marigold (Epic) and
			-- Crane (Legendary). The Standard pool weighs them 60, 30, 9 and 1, and gives no Legendary.
			local ok, err = asMade(WAITING, function()
				local entries = Odds.Table(STANDARD, 0)
				t.Equal("seven Voidkin", #entries, 7)
				t.Check("Rook a quarter of the Commons", near(chanceOf(entries, "rook"), 60 / 100 / 4))
				t.Check("Sable 30 in 100", near(chanceOf(entries, "sable"), 30 / 100))
				t.Check("Lyric 9 in 100", near(chanceOf(entries, "lyric"), 9 / 100))
				t.Check("Marigold 1 in 100", near(chanceOf(entries, "marigold"), 1 / 100))
				t.Equal("no Crane from a Standard", chanceOf(entries, "crane"), 0)
				t.Equal("nothing from ground 2", chanceOf(entries, "patch"), 0)
			end)
			t.Check("ran", ok, tostring(err))
		end,
	},
	{
		Name = "Odds: luck lifts the top tiers, up to its cap",
		Run = function(t: any)
			-- ground 1's eight made: four tiers live (Common to Epic), so the top two, Rare and Epic, are lifted
			local ok, err = asMade(WAITING, function()
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
			end)
			t.Check("ran", ok, tostring(err))
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
			local ok, err = asMade(WAITING, function()
				-- Enriched, ground 1's eight made: no Commons; Uncommon 45, Rare 35, Epic 16, Legendary 4
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
			local ok, err = asMade({ "tumble" }, function()
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
	{
		Name = "Odds: drop rates hold every Voidkin under its rarity's total, the commonest first, and add to 100%",
		Run = function(t: any)
			for _, shard in Shards.List do
				for _, luck in { 0, 0.2, ShardConfig.LuckCap } do
					local entries = Odds.Table(shard.Id, luck)
					local groups = Odds.Rates(shard.Id, luck)
					local where = `{shard.Id} at luck {luck}`
					local sum, rows, off = 0, 0, ""
					local below = 0
					for _, group in groups do
						local rank = Rarity.Rank[group.Rarity]
						if rank <= below then
							off = `{group.Rarity} out of order`
						end
						below = rank
						local own, chance = 0, 0
						for _, rate in group.Rates do
							rows += 1
							own += rate.Parts
							chance += rate.Chance
							if Voidkin.ById[rate.Id].Rarity ~= group.Rarity then
								off = `{rate.Id} under {group.Rarity}`
							elseif not near(rate.Chance, chanceOf(entries, rate.Id)) then
								off = `{rate.Id}: not the table's chance`
							elseif rate.Parts < 1 or math.abs(rate.Parts - rate.Chance * Odds.Parts) > 1 then
								off = `{rate.Id}: {rate.Parts} parts for {rate.Chance}`
							end
						end
						if own ~= group.Parts or not near(chance, group.Chance) then
							off = `{group.Rarity}: {group.Parts} isn't its rows' {own}`
						end
						sum += group.Parts
					end
					t.Check(`{where}: every Voidkin once, under its own rarity, the commonest first`, rows == #entries and off == "", off)
					t.Equal(`{where}: the rows add to 100%`, sum, Odds.Parts)
				end
			end
			-- Ground 1's Standard shard, by hand, as the player reads it.
			local function reads(): (string, string)
				local groups = Odds.Rates(STANDARD, 0)
				local read: { string } = {}
				for _, group in groups do
					table.insert(read, `{group.Rarity} {Odds.Percent(group.Parts)} x{#group.Rates}`)
				end
				local commons = groups[1]
				return table.concat(read, ", "), if commons then `{commons.Rates[1].Id} {Odds.Percent(commons.Rates[1].Parts)}` else ""
			end
			-- At launch, its five made: Common 60 and Rare 9, out of 69 (TR24's guard). Each Common's 2173.9 parts and
			-- Lyric's 1304.35 round by largest remainder to 2174 and 1304.
			local launch, firstAtLaunch = reads()
			t.Equal("ground 1's Standard at launch", launch, "Common 86.96% x4, Rare 13.04% x1")
			t.Equal("Rook, the first Common, at 21.74%", firstAtLaunch, "rook 21.74%")
			-- Its eight made: Common 60 in four of 15, Uncommon 30, Rare 9, Epic 1.
			local ok, err = asMade(WAITING, function()
				local all, first = reads()
				t.Equal("ground 1's Standard, its eight made", all, "Common 60% x4, Uncommon 30% x1, Rare 9% x1, Epic 1% x1")
				t.Equal("Rook, the first Common, at 15%", first, "rook 15%")
			end)
			t.Check("ran", ok, tostring(err))
			t.Equal("a Named shard: one rarity, one Voidkin, 100%", Odds.Percent(Odds.Rates("named_watt", 0)[1].Rates[1].Parts), "100%")
			t.Equal("an unknown shard: none", #Odds.Rates("nothing", 0), 0)
			t.Equal("whole", Odds.Percent(6000), "60%")
			t.Equal("a tenth", Odds.Percent(1050), "10.5%")
			t.Equal("a hundredth", Odds.Percent(675), "6.75%")
			t.Equal("under one", Odds.Percent(33), "0.33%")
			t.Equal("a part", Odds.Percent(1), "0.01%")
		end,
	},
	{
		Name = "Odds: only a made Voidkin comes out of a shard, so a tier with no one made drops (TR24's guard)",
		Run = function(t: any)
			-- TR24: "A player's first shards can give a Voidkin that isn't made. The roll takes only made Voidkin" (a must-fix
			-- before any public build). Launch has five (the director, 2026-11-17, 02:40).
			for _, shard in Shards.List do
				for _, luck in { 0, ShardConfig.LuckCap } do
					for _, entry in Odds.Table(shard.Id, luck) do
						t.Check(`{shard.Id} at luck {luck}: {entry.Id} is made`, Voidkin.Made(Voidkin.ById[entry.Id]))
					end
				end
				if shard.Holds ~= "" then
					t.Equal(`{shard.Id}: holds its made Voidkin`, #Odds.Table(shard.Id, 0), 1)
				end
			end
			-- Lantern Row's Standard at launch: the four Commons and Lyric. Uncommon, Epic and Legendary have no one made, so
			-- they drop: the pool's 60 and 9 stand, out of 69.
			local entries = Odds.Table(STANDARD, 0)
			t.Equal("five Voidkin", #entries, 5)
			t.Check("Rook a quarter of the Commons", near(chanceOf(entries, "rook"), 60 / 69 / 4))
			t.Check("Lyric 9 in 69", near(chanceOf(entries, "lyric"), 9 / 69))
			for _, id in WAITING do
				t.Equal(`never {id}`, chanceOf(entries, id), 0)
			end
			local tiers = {}
			for _, group in Odds.Rates(STANDARD, 0) do
				table.insert(tiers, group.Rarity)
			end
			t.Equal("the rates the player reads: Common and Rare", table.concat(tiers, ", "), "Common, Rare")
			-- two tiers live, so luck lifts only the top one
			t.Equal("luck lifts one tier", Odds.Lifted(STANDARD), 1)
			local lifted = Odds.Table(STANDARD, 0.4)
			t.Check("Lyric lifted", near(chanceOf(lifted, "lyric"), 9 * 1.4 / (60 + 9 * 1.4)))
			t.Check("the Commons not", near(chanceOf(lifted, "rook"), 60 / (60 + 9 * 1.4) / 4))
			-- one made joins on its own
			local ok, err = asMade({ "sable" }, function()
				t.Check("Sable made: 30 in 99", near(chanceOf(Odds.Table(STANDARD, 0), "sable"), 30 / 99))
			end)
			t.Check("ran", ok, tostring(err))
			t.Equal("and leaves with its row", chanceOf(Odds.Table(STANDARD, 0), "sable"), 0)
			-- a Named shard of one not made holds nothing, so the Breaker refuses it and the shard stays (Rules.Base)
			local id = "case_named_sable"
			Shards.ById[id] = { Id = id, Grade = "Named", Ground = "lanternrow", Holds = "sable" } :: any
			t.Equal("a Named Sable holds nothing", #Odds.Table(id, 0), 0)
			t.Equal("and rolls nothing", Odds.Roll(id, 0, 0.5), nil)
			Shards.ById[id] = nil
			-- each made Voidkin has its portraits (UI/Kit/Portrait: its own, else its rarity's silhouette)
			for _, row in Voidkin.List do
				if Voidkin.Made(row) then
					t.Check(`{row.Name}: its portraits`, UIKit.Images[`Portrait{row.Name}`] ~= nil and UIKit.Images[`Portrait{row.Name}Small`] ~= nil)
				end
			end
		end,
	},
}
