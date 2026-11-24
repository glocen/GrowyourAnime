--!strict
-- Wallet (shared, pure): a player's Credits, and which of them were bought with Robux. The director, 2026-11-24: "we
-- will sell credit so make sure it in accord to roblox rule" (docs/research/cloud-2026-11-24/launch-design.md, sections
-- 3 and 12; docs/roblox-rules.md). Roblox: a random outcome paid for with currency bought for Robux is a paid random
-- item, and where PolicyService says ArePaidRandomItemsRestricted, a player may not use bought currency on one.
-- So the profile keeps, inside its Credits, the ones bought and not yet spent (Currency.Bought, never more than Credits):
--   a sure spend (the base, a machine, a Reinforce level that can't fail, a shop piece shown before it's bought) takes
--   bought Credits first;
--   a random spend (a Reinforce try that can fail, the shop's shards) takes earned Credits first, and a restricted
--   player's takes earned Credits only.
-- No Roblox API: it runs with Studio closed. The server reads the policy (Services.Core.RandomPolicyService).
--   Wallet.Bought(data)                              Credits bought and not yet spent
--   Wallet.Earned(data)                              Credits earned: the rest
--   Wallet.Can(data, price, random, restricted)      whether a spend of `price` may be made
--   Wallet.Spend(data, price, random, restricted)    makes it, or changes nothing and answers false
--   Wallet.Grant(data, credits)                      a purchase's Credits: they land as bought

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)

local Wallet = {}

-- A Credit is a whole number, so a hostile or broken price never spends a fraction.
local function whole(n: number): boolean
	return n == n and n ~= math.huge and n >= 0 and n == math.floor(n)
end

function Wallet.Bought(data: Profile.Data): number
	return math.clamp(data.Currency.Bought or 0, 0, math.max(data.Currency.Credits, 0))
end

function Wallet.Earned(data: Profile.Data): number
	return math.max(data.Currency.Credits - Wallet.Bought(data), 0)
end

function Wallet.Can(data: Profile.Data, price: number, random: boolean, restricted: boolean): boolean
	if not whole(price) then
		return false
	end
	return price <= (if random and restricted then Wallet.Earned(data) else data.Currency.Credits)
end

function Wallet.Spend(data: Profile.Data, price: number, random: boolean, restricted: boolean): boolean
	if not Wallet.Can(data, price, random, restricted) then
		return false
	end
	local bought = Wallet.Bought(data)
	local fromBought = if random then math.max(price - Wallet.Earned(data), 0) else math.min(price, bought)
	data.Currency.Credits -= price
	local left = bought - fromBought
	data.Currency.Bought = if left > 0 then left else nil
	return true
end

-- A purchase's Credits (the store's receipt, once it's built): they count as bought until they're spent.
function Wallet.Grant(data: Profile.Data, credits: number)
	if not whole(credits) or credits == 0 then
		return
	end
	local bought = Wallet.Bought(data)
	data.Currency.Credits += credits
	data.Currency.Bought = bought + credits
end

return Wallet
