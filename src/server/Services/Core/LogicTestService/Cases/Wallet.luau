--!strict
-- Wallet cases (pure): bought and earned Credits (Rules.Wallet; docs/roblox-rules.md, "What we do"). A sure spend takes
-- bought Credits first, a random one earned first, and where paid random items are restricted a random one takes earned
-- only; a purchase lands as bought; a hostile price spends nothing; and over many seeded spends and grants, bought never
-- passes Credits and a restricted player's random spends never touch a bought Credit. Runs in Studio (LogicTests) and with
-- Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Wallet = require(Shared.Rules.Wallet)

local function fresh(credits: number, bought: number?): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Currency.Credits = credits
	data.Currency.Bought = bought
	return data
end

return {
	{
		Name = "Wallet: a sure spend takes bought Credits first, a random one earned first, a restricted random one earned only",
		Run = function(t: any)
			local sure = fresh(100, 30)
			t.Check("70 earned, 30 bought", Wallet.Earned(sure) == 70 and Wallet.Bought(sure) == 30)
			t.Check("a sure 40: the 30 bought, then 10 earned", Wallet.Spend(sure, 40, false, false) and sure.Currency.Credits == 60 and sure.Currency.Bought == nil)
			local random = fresh(100, 30)
			t.Check("a random 80: the 70 earned, then 10 bought", Wallet.Spend(random, 80, true, false) and random.Currency.Credits == 20 and random.Currency.Bought == 20)
			local held = fresh(100, 30)
			t.Check("restricted, a random 70: all earned", Wallet.Spend(held, 70, true, true) and held.Currency.Credits == 30 and held.Currency.Bought == 30)
			local before = Profile.DeepCopy(held)
			t.Check("restricted, a random 1 more: refused, nothing changed", not Wallet.Can(held, 1, true, true) and not Wallet.Spend(held, 1, true, true) and held.Currency.Credits == before.Currency.Credits and held.Currency.Bought == before.Currency.Bought)
			t.Check("restricted, a sure 30: bought Credits pay", Wallet.Spend(held, 30, false, true) and held.Currency.Credits == 0 and held.Currency.Bought == nil)
			local none = fresh(50)
			t.Check("no bought Credits: every spend the same", Wallet.Spend(none, 50, true, true) and none.Currency.Credits == 0 and none.Currency.Bought == nil)
		end,
	},
	{
		Name = "Wallet: a purchase lands as bought; a hostile price or grant changes nothing; a broken ledger reads inside its Credits",
		Run = function(t: any)
			local data = fresh(10)
			Wallet.Grant(data, 500)
			t.Check("500 bought on top of 10 earned", data.Currency.Credits == 510 and Wallet.Bought(data) == 500 and Wallet.Earned(data) == 10)
			for _, odd in { -1, 0.5, 0 / 0, math.huge, -math.huge } do
				local copy = Profile.DeepCopy(data)
				Wallet.Grant(copy, odd)
				local spent = Wallet.Spend(copy, odd, false, false)
				t.Check(`{odd}: no grant and no spend`, not spent and copy.Currency.Credits == 510 and copy.Currency.Bought == 500)
			end
			t.Check("a zero price is a spend of nothing", Wallet.Spend(data, 0, true, true) and data.Currency.Credits == 510)
			t.Check("more than the Credits: refused", not Wallet.Spend(data, 511, false, false) and data.Currency.Credits == 510)
			local broken = fresh(40, 90)
			t.Check("Bought past Credits reads as Credits", Wallet.Bought(broken) == 40 and Wallet.Earned(broken) == 0)
			local negative = fresh(40, -5)
			t.Check("a negative Bought reads as none", Wallet.Bought(negative) == 0 and Wallet.Earned(negative) == 40)
			t.Check("the ledger is saveable", #Saveable.Problems(data, "profile") == 0)
		end,
	},
	{
		Name = "Wallet (section 9): seeded spends and grants in any order keep Credits whole, bought within Credits, and a restricted random spend off every bought Credit",
		Run = function(t: any)
			local seed = 20261124 -- the engine's Random isn't offline: the cases' own Lehmer generator
			local function draw(): number
				seed = (seed * 16807) % 2147483647
				return seed / 2147483647
			end
			local function int(low: number, high: number): number
				return low + math.floor(draw() * (high - low + 1))
			end
			for run = 1, 200 do
				local data = fresh(int(0, 1000), nil)
				local restricted = draw() < 0.5
				local broke = nil
				for step = 1, 60 do
					local credits, bought = data.Currency.Credits, Wallet.Bought(data)
					local roll = draw()
					if roll < 0.2 then
						Wallet.Grant(data, int(1, 400))
					else
						local price = int(0, 300)
						local random = roll < 0.6
						local ok = Wallet.Spend(data, price, random, restricted)
						if ok and random and restricted and Wallet.Bought(data) ~= bought then
							broke = `step {step}: a restricted random spend took a bought Credit`
						end
						if ok and credits - data.Currency.Credits ~= price then
							broke = `step {step}: spent {credits - data.Currency.Credits}, priced {price}`
						end
						if not ok and (data.Currency.Credits ~= credits or Wallet.Bought(data) ~= bought) then
							broke = `step {step}: a refusal changed the wallet`
						end
					end
					local raw = data.Currency.Bought
					if data.Currency.Credits < 0 or data.Currency.Credits ~= math.floor(data.Currency.Credits) or (raw ~= nil and (raw <= 0 or raw > data.Currency.Credits)) then
						broke = `step {step}: Credits {data.Currency.Credits}, Bought {raw}`
					end
					if broke then
						break
					end
				end
				if broke then
					t.Check(`run {run}`, false, broke)
					return
				end
			end
			t.Check("200 runs of 60 steps hold", true)
		end,
	},
}
