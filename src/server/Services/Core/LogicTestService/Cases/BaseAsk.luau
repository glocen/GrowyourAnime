--!strict
-- Logic cases (pure): what each spot of the base's view can buy (Rules.BaseLevels.Ask; docs/ui.md, 7; TR21's Upgrade
-- press). The press sends what the offer names, so each case runs the ask through Rules.Base as the server does, inside a
-- Transaction: an open offer is bought once for its price, a shut one is refused for the reason the press shows, and
-- nothing is spent on a refusal. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local Base = require(Shared.Rules.Base)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Condenser = require(Shared.Rules.Condenser)
local BaseConfig = require(Shared.Config.Base)
local DataConfig = require(Shared.Config.Data)

local T0 = 1_800_000_000

local function fresh(credits: number): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	Breaker.Advance(data, T0)
	data.Currency.Credits = credits
	return data
end

-- Sends an ask as the press does, and runs it as the server does.
local function press(data: Profile.Data, ask: BaseLevels.Ask, now: number): any
	local answer = Transaction.Run(data, nil, function(draft: Profile.Data): any
		return Base.Actions[ask.Act](draft, ask.Args, now, 0.5)
	end, DataConfig.OpsKept)
	return answer
end

local function levelOf(data: Profile.Data, ask: BaseLevels.Ask): number
	if ask.Machine == nil then
		return data.Base.Level
	elseif ask.Bay then
		return data.Base.Bays[ask.Bay].Level or 1
	end
	return data.Base.Machines[ask.Machine] or 1
end

return {
	{
		Name = "Base view: every press asks for what the server takes, level after level, and a shut one is refused for the reason shown",
		Run = function(t: any)
			local data = fresh(10_000_000)
			local now = T0
			local bought = 0
			-- Round after round, every spot pressed, until no offer is open: the base to its cap, each machine to its ceiling.
			for _ = 1, 40 do
				local any = false
				for _, spot in { "Base", "Breaker", "Condenser", "Bay1", "Bay2", "Bay3", "Bay4" } do
					local ask = BaseLevels.Ask(data.Base :: any, spot, data.Currency.Credits)
					if ask == nil then
						continue
					end
					now += 1
					local had, was = data.Currency.Credits, levelOf(data, ask)
					t.Equal(`{spot}: the ask names the level it stands at`, ask.Now, was)
					local answer = press(data, ask, now)
					if ask.Offer.Why == nil then
						any = true
						bought += 1
						t.Check(`{spot} to {ask.Offer.Level}: bought`, answer.Ok == true and levelOf(data, ask) == ask.Offer.Level, tostring(answer.Error))
						t.Equal(`{spot} to {ask.Offer.Level}: for the price shown`, had - data.Currency.Credits, ask.Offer.Price)
						t.Check(`{spot} to {ask.Offer.Level}: it says what the level gives`, #ask.Offer.Gains > 0 or ask.Machine ~= nil)
					else
						t.Equal(`{spot} at {was}: refused for the reason shown`, answer.Error, ask.Offer.Why)
						t.Check(`{spot} at {was}: nothing spent, nothing raised`, data.Currency.Credits == had and levelOf(data, ask) == was)
					end
				end
				if not any then
					break
				end
			end
			t.Equal("the base at the launch's cap", data.Base.Level, BaseConfig.Levels.Cap)
			t.Equal("every bay the cap opens", #data.Base.Bays, BaseLevels.Bays(BaseConfig.Levels.Cap))
			local ceiling = BaseLevels.Ceiling(data.Base.Level)
			t.Check("the Breaker and every bay at the ceiling", (data.Base.Machines.Breaker or 1) == ceiling and (data.Base.Bays[1].Level or 1) == ceiling and (data.Base.Bays[4].Level or 1) == ceiling)
			-- Every level there is, each checked: the base's, and the Breaker's, the Condenser's and each bay's to the ceiling.
			local machines = 2 + BaseLevels.Bays(BaseConfig.Levels.Cap)
			t.Equal("every press, each checked", bought, (BaseConfig.Levels.Cap - 1) + machines * (ceiling - 1))
			local top = BaseLevels.Ask(data.Base :: any, "Base", data.Currency.Credits) :: BaseLevels.Ask
			t.Check("at the cap the base's offer has no price", top.Offer.Price == nil and top.Offer.Why == BaseLevels.AtCap)
		end,
	},
	{
		Name = "Base view: a press with too few Credits, a machine at its ceiling and a sleeping Condenser each say why",
		Run = function(t: any)
			local poor = fresh(0)
			for _, spot in { "Base", "Breaker", "Bay1" } do
				local ask = BaseLevels.Ask(poor.Base :: any, spot, 0) :: BaseLevels.Ask
				t.Equal(`{spot}: short`, ask.Offer.Why, BaseLevels.Short)
				t.Equal(`{spot}: the server agrees`, press(poor, ask, T0 + 1).Error, Base.Short)
			end
			local data = fresh(1_000_000)
			local ceiling = BaseLevels.Ceiling(1)
			for step = 2, ceiling do
				press(data, BaseLevels.Ask(data.Base :: any, "Breaker", data.Currency.Credits) :: BaseLevels.Ask, T0 + step)
			end
			local held = BaseLevels.Ask(data.Base :: any, "Breaker", data.Currency.Credits) :: BaseLevels.Ask
			t.Check("the Breaker at the base's ceiling: the base's level comes first", held.Now == ceiling and held.Offer.Why == BaseLevels.AtCeiling)
			t.Equal("the server agrees", press(data, held, T0 + 50).Error, Base.Ceiling)
			if not Condenser.Awake(1) then
				local asleep = BaseLevels.Ask(data.Base :: any, "Condenser", data.Currency.Credits) :: BaseLevels.Ask
				t.Equal("the Condenser asleep at base level 1", asleep.Offer.Why, BaseLevels.Asleep)
				t.Equal("the server agrees", press(data, asleep, T0 + 51).Error, Base.Asleep)
			end
		end,
	},
	{
		Name = "Base view: a spot with no level of its own, a bay not open and a name that isn't a spot have nothing to buy",
		Run = function(t: any)
			local data = fresh(1_000_000)
			for _, spot in { "Battery", "Generator", "Training", `Bay{#data.Base.Bays + 1}`, "Bay0", "Bay", "Forge", "" } do
				t.Equal(`"{spot}"`, BaseLevels.Ask(data.Base :: any, spot, data.Currency.Credits), nil)
			end
		end,
	},
}
