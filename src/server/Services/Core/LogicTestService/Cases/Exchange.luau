--!strict
-- Exchange cases (pure): the Void Shop's weekly Exchange (TR76; docs/design.md, "The Strip"; Rules.Exchange). The week
-- turns at Monday 00:00 UTC; each offer lands what it says for its token, picked by the player, nothing random; the
-- limit holds through the week and a new week starts the counts again; a refusal changes nothing and says what's missing;
-- a press from last week is refused; a repeated request spends once. The numbers are placeholders: these cases read them.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local ExchangeConfig = require(Shared.Config.Exchange)
local EmblemsConfig = require(Shared.Config.Emblems)
local VoidkinConfig = require(Shared.Config.Voidkin)
local EmblemSets = require(Shared.Definitions.Emblems)
local Exchange = require(Shared.Rules.Exchange)
local Collection = require(Shared.Rules.Collection)
local Refusal = require(Shared.Rules.Refusal)

local MONDAY = 1_795_996_800 -- 2026-11-30 00:00 UTC, a Monday
local NOW = MONDAY + 3 * 86400 + 4321 -- that Thursday
local OP = "1a2b3c4d-5e6f-4789-9abc-def012345678"
local OTHER_OP = "2b3c4d5e-6f70-4891-abcd-ef0123456789"

local function fresh(seals: number, crests: number): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	if seals > 0 then
		data.Bag.Tokens.Seal = seals
	end
	if crests > 0 then
		data.Bag.Tokens.Crest = crests
	end
	return data
end

local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function offerOf(kind: string): ExchangeConfig.Offer
	for _, offer in ExchangeConfig.Offers do
		if offer.Kind == kind then
			return offer
		end
	end
	error(`no {kind} offer`)
end

-- A set of the emblem offer's rarity and one of another, and a stat.
local function sets(): (string, string?, string)
	local offer = offerOf("Emblem")
	local mine, other: string? = nil, nil
	for _, row in EmblemSets.List do
		if row.Rarity == offer.Rarity then
			mine = mine or row.Id
		else
			other = other or row.Id
		end
	end
	local stat = next(EmblemsConfig.Points) :: string
	return mine :: string, other, stat
end

local function ask(offer: string, count: number, extra: { [string]: any }?): { [string]: any }
	local args: { [string]: any } = { Week = Exchange.Week(NOW), Offer = offer, Count = count }
	for key, value in extra or {} do
		args[key] = value
	end
	return args
end

return {
	{
		Name = "Exchange: the week turns at Monday 00:00 UTC, the same for everyone",
		Run = function(t: any)
			local week = Exchange.Week(MONDAY)
			t.Equal("Monday 00:00 starts a week", Exchange.Week(MONDAY - 1), week - 1)
			t.Equal("all week the same one", Exchange.Week(MONDAY + ExchangeConfig.Week - 1), week)
			t.Equal("the next Monday the next", Exchange.Week(MONDAY + ExchangeConfig.Week), week + 1)
			t.Equal("it ends next Monday 00:00", Exchange.Ends(week), MONDAY + ExchangeConfig.Week)
			t.Equal("the first Monday after Unix 0 is week 0", Exchange.Week(ExchangeConfig.Monday), 0)
			t.Equal("its Thursday before is week -1", Exchange.Week(0), -1)
			local ids: { [string]: boolean } = {}
			local sound = true
			for _, offer in ExchangeConfig.Offers do
				sound = sound and not ids[offer.Id] and offer.Price > 0 and offer.Limit >= 1 and (offer.Token == "Seal" or offer.Token == "Crest")
				ids[offer.Id] = true
			end
			t.Check("every offer a price in Seals or Crests, a limit, its own id", sound)
		end,
	},
	{
		Name = "Exchange: each offer lands what it says, picked by the player, for its tokens",
		Run = function(t: any)
			-- a Named copy: new when not owned, a copy when owned
			local named = offerOf("Named")
			local pool = named.Pool :: { string }
			local data = fresh(named.Price * 2, 0)
			local first = Exchange.Buy(data, ask(named.Id, 1, { Voidkin = pool[1] }), NOW)
			local owned = Collection.Owned(data, pool[1])
			t.Check("a Named pick not owned: it joins", first.Ok == true and first.Outcome == "New" and owned ~= nil)
			local second = Exchange.Buy(data, ask(named.Id, 1, { Voidkin = pool[1] }), NOW)
			t.Check("owned: a copy waits for its next star", second.Ok == true and second.Outcome == "Copy" and owned ~= nil and owned.Copies == 1)
			t.Check("the Seals spent, the key gone at 0", data.Bag.Tokens.Seal == nil)
			t.Equal("two a week", Exchange.Left(data, Exchange.Week(NOW), named.Id), 0)
			-- an emblem of a picked set and stat
			local emblem = offerOf("Emblem")
			local set, _, stat = sets()
			local bag = fresh(0, emblem.Price + 3)
			local got = Exchange.Buy(bag, ask(emblem.Id, 1, { Set = set, Stat = stat }), NOW)
			t.Check("an emblem of the picked set and stat", got.Ok == true and bag.Bag.Emblems[`{set}:{stat}`] == 1 and got.Emblem == `{set}:{stat}`)
			t.Equal("its Crests spent", bag.Bag.Tokens.Crest, 3)
			-- Skill Manuals, for either token
			for _, offer in ExchangeConfig.Offers do
				if offer.Kind == "Token" then
					local seals = if offer.Token == "Seal" then offer.Price * 2 else 0
					local crests = if offer.Token == "Crest" then offer.Price * 2 else 0
					local d = fresh(seals, crests)
					local bought = Exchange.Buy(d, ask(offer.Id, 2), NOW)
					t.Check(`{offer.Id}: two buys land their tokens`, bought.Ok == true and d.Bag.Tokens[offer.Gives :: string] == (offer.Each or 1) * 2 and d.Bag.Tokens[offer.Token] == nil)
					local problems = Saveable.Problems(d, "profile")
					t.Check(`{offer.Id}: the save stays whole`, #problems == 0, table.concat(problems, "; "))
				end
			end
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Exchange: a refusal changes nothing and says why: short, at the limit, a bad pick, last week's press",
		Run = function(t: any)
			local named = offerOf("Named")
			local emblem = offerOf("Emblem")
			local pool = named.Pool :: { string }
			local set, other, stat = sets()
			local rich = fresh(10000, 10000)
			local cases: { { any } } = {
				{ "too few Seals", fresh(named.Price - 7, 0), ask(named.Id, 1, { Voidkin = pool[1] }), Exchange.Short },
				{ "Crests for a Seal offer", fresh(0, 10000), ask(named.Id, 1, { Voidkin = pool[1] }), Exchange.Short },
				{ "past the limit at once", rich, ask(named.Id, named.Limit + 1, { Voidkin = pool[1] }), Exchange.Unknown },
				{ "a Voidkin not in the pool", rich, ask(named.Id, 1, { Voidkin = "lyric" }), Exchange.Unknown },
				{ "no Voidkin named", rich, ask(named.Id, 1), Exchange.Unknown },
				{ "an emblem set of another rarity", rich, ask(emblem.Id, 1, { Set = other, Stat = stat }), Exchange.Unknown },
				{ "an emblem stat that isn't one", rich, ask(emblem.Id, 1, { Set = set, Stat = "Luck" }), Exchange.Unknown },
				{ "no such offer", rich, ask("nothing", 1), Exchange.Unknown },
				{ "a count that isn't one", rich, ask(named.Id, 1.5, { Voidkin = pool[1] }), Exchange.Unknown },
				{ "last week's press", rich, { Week = Exchange.Week(NOW) - 1, Offer = named.Id, Count = 1, Voidkin = pool[1] }, Exchange.Gone },
				{ "no args", rich, "x", Exchange.Unknown },
			}
			for _, case in cases do
				local data = case[2] :: Profile.Data
				local before = Profile.DeepCopy(data)
				local answer = Exchange.Buy(data, case[3], NOW)
				t.Check(`{case[1]}: refused {case[4]}`, answer.Ok == false and answer.Error == case[4], tostring(answer.Error))
				t.Check(`{case[1]}: nothing changed`, same(data, before))
			end
			local short = Exchange.Buy(fresh(named.Price - 7, 0), ask(named.Id, 1, { Voidkin = pool[1] }), NOW)
			t.Equal("it says what's missing", Refusal.Of("Exchange", short), "Need 7 more Arena Seals")
			-- the limit over two presses
			local data = fresh(10000, 0)
			for _ = 1, named.Limit do
				Exchange.Buy(data, ask(named.Id, 1, { Voidkin = pool[2] }), NOW)
			end
			local before = Profile.DeepCopy(data)
			t.Equal("the limit refuses the next", Exchange.Buy(data, ask(named.Id, 1, { Voidkin = pool[2] }), NOW).Error, Exchange.Limit)
			t.Check("and changes nothing", same(data, before))
			-- a Voidkin at its last star
			local top = fresh(10000, 0)
			Collection.Uncover(top, pool[3], NOW)
			local owned = Collection.Owned(top, pool[3]) :: Profile.OwnedVoidkin
			owned.Stars = VoidkinConfig.MaxStars
			local held = Profile.DeepCopy(top)
			t.Equal("its last star: refused, never sold for Seals", Exchange.Buy(top, ask(named.Id, 1, { Voidkin = pool[3] }), NOW).Error, Exchange.MaxStars)
			t.Check("and nothing changed", same(top, held))
			for _, code in { Exchange.Short, Exchange.Limit, Exchange.Gone, Exchange.Unknown, Exchange.MaxStars } do
				t.Check(`the Exchange words {code}`, Refusal.Has("Exchange", code))
			end
		end,
	},
	{
		Name = "Exchange: a new week starts the counts again; a server hop never does",
		Run = function(t: any)
			local offer = offerOf("Token")
			local data = fresh(10000, 10000)
			t.Check("bought out", Exchange.Buy(data, ask(offer.Id, offer.Limit), NOW).Ok == true)
			t.Equal("the same week, later: still out", Exchange.Buy(data, ask(offer.Id, 1), NOW + 3600).Error, Exchange.Limit)
			local nextWeek = NOW + ExchangeConfig.Week
			local again = Exchange.Buy(data, { Week = Exchange.Week(nextWeek), Offer = offer.Id, Count = 1 }, nextWeek)
			t.Check("next week: buys again", again.Ok == true)
			t.Equal("its count starts at one", Exchange.Bought(data, Exchange.Week(nextWeek), offer.Id), 1)
			t.Equal("last week's counts don't hold it back", Exchange.Left(data, Exchange.Week(nextWeek), offer.Id), offer.Limit - 1)
		end,
	},
	{
		Name = "Exchange (section 9): a repeated buy answers its first answer and spends once",
		Run = function(t: any)
			local named = offerOf("Named")
			local pool = named.Pool :: { string }
			local data = fresh(named.Price * 5, 0)
			local change = function(draft: Profile.Data): Transaction.Answer
				return Exchange.Buy(draft, ask(named.Id, 1, { Voidkin = pool[1] }), NOW)
			end
			local first, changed = Transaction.Run(data, OP, change, 8)
			t.Check("bought", first.Ok == true and changed)
			local before = Profile.DeepCopy(data)
			local again, againChanged = Transaction.Run(data, OP, change, 8)
			t.Check("the repeat changes nothing and answers the first", not againChanged and same(data, before) and again.Ok == true and again.Outcome == first.Outcome)
			t.Equal("spent once", data.Bag.Tokens.Seal, named.Price * 4)
			local cut = Profile.DeepCopy(data)
			local _, cutChanged = Transaction.Run(data, OTHER_OP, function(draft: Profile.Data): Transaction.Answer
				Exchange.Buy(draft, ask(named.Id, 1, { Voidkin = pool[1] }), NOW)
				error("cut")
			end, 8)
			t.Check("a cut request changes nothing", not cutChanged and same(data, cut))
		end,
	},
}
