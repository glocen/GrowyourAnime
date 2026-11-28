--!strict
-- The Void Shop's Exchange (TR76; docs/design.md, "The Strip", "The Exchange"; Config.Exchange), pure Luau. A week's
-- offers stand from Monday 00:00 UTC to the next, the same for everyone, nothing random. A buy names the week it was
-- pressed in, so a buy pressed before Monday and landing after is refused, never paid at the new week's counts. Each
-- offer is paid in a bag token, counted against the week (data.Exchange), and done in one step: every check comes before
-- the first change, so a refusal changes nothing.
--   Exchange.Week(now)                    the week standing at Unix second `now`
--   Exchange.Ends(week)                   the Unix second the next week starts
--   Exchange.Bought(data, week, id) / Exchange.Left(data, week, id)
--   Exchange.Buy(data, args, now)         args { Week, Offer, Count, Voidkin? (Named), Set?, Stat? (Emblem) }

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local ExchangeConfig = require(Shared.Config.Exchange)
local EmblemsConfig = require(Shared.Config.Emblems)
local VoidkinConfig = require(Shared.Config.Voidkin)
local EmblemSets = require(Shared.Definitions.Emblems)
local Tokens = require(Shared.Definitions.Tokens)
local Collection = require(Shared.Rules.Collection)
local Emblems = require(Shared.Rules.Emblems)

local Exchange = {}

Exchange.Unknown = "Unknown" -- no such offer, a count that isn't one, or a pick that isn't one of its own
Exchange.Gone = "Gone" -- the week turned since the press: nothing bought
Exchange.Limit = "Limit" -- that offer's count for this week is bought
Exchange.Short = "Short" -- not enough of its token
Exchange.MaxStars = "MaxStars" -- the picked Voidkin is at its last star: a copy would only be sold

-- The week standing at Unix second `now`: 0 is the week from Monday 1970-01-05.
function Exchange.Week(now: number): number
	return math.floor((now - ExchangeConfig.Monday) / ExchangeConfig.Week)
end

-- The Unix second week `week` gives way to the next.
function Exchange.Ends(week: number): number
	return ExchangeConfig.Monday + (week + 1) * ExchangeConfig.Week
end

-- How many of offer `id` this account has bought in week `week`.
function Exchange.Bought(data: Profile.Data, week: number, id: string): number
	local held = data.Exchange
	if held.Week ~= week then
		return 0
	end
	return held.Bought[id] or 0
end

-- How many of offer `id` this account may still buy in week `week`; 0 for no such offer.
function Exchange.Left(data: Profile.Data, week: number, id: string): number
	local offer = ExchangeConfig.ById[id]
	if offer == nil then
		return 0
	end
	return math.max(0, offer.Limit - Exchange.Bought(data, week, id))
end

-- An emblem's key for a picked set and stat, when the set is of the offer's rarity and the stat is an emblem's.
local function emblemKey(offer: ExchangeConfig.Offer, set: any, stat: any): string?
	if type(set) ~= "string" or type(stat) ~= "string" then
		return nil
	end
	local row = EmblemSets.ById[set]
	if row == nil or row.Rarity ~= offer.Rarity or EmblemsConfig.Points[stat] == nil then
		return nil
	end
	return Emblems.Key(set, stat)
end

-- Buys `args.Count` of offer `args.Offer`, pressed in week `args.Week`, at Unix second `now`. { Ok, Offer, Count,
-- Token, Paid, Outcome? and Id? (Named: Collection.Uncover's last), Emblem? (its key) }, or a refusal that changed
-- nothing, with Need and Tokens (their name, many) on Short.
function Exchange.Buy(data: Profile.Data, args: any, now: number): { [string]: any }
	if type(args) ~= "table" then
		return { Ok = false, Error = Exchange.Unknown }
	end
	local week = Exchange.Week(now)
	if type(args.Week) ~= "number" or args.Week ~= week then
		return { Ok = false, Error = Exchange.Gone }
	end
	local offer = if type(args.Offer) == "string" then ExchangeConfig.ById[args.Offer] else nil
	local count = args.Count
	if offer == nil or type(count) ~= "number" or count ~= math.floor(count) or count < 1 or count > offer.Limit then
		return { Ok = false, Error = Exchange.Unknown }
	end
	-- the pick, checked before anything changes
	local def: string? = nil
	local key: string? = nil
	if offer.Kind == "Named" then
		def = if type(args.Voidkin) == "string" and table.find(offer.Pool or {}, args.Voidkin) then args.Voidkin else nil
		if def == nil then
			return { Ok = false, Error = Exchange.Unknown }
		end
		local owned = Collection.Owned(data, def)
		if owned and owned.Stars >= VoidkinConfig.MaxStars then
			return { Ok = false, Error = Exchange.MaxStars }
		end
	elseif offer.Kind == "Emblem" then
		key = emblemKey(offer, args.Set, args.Stat)
		if key == nil then
			return { Ok = false, Error = Exchange.Unknown }
		end
	elseif offer.Kind ~= "Token" or offer.Gives == nil or Tokens.ById[offer.Gives] == nil then
		return { Ok = false, Error = Exchange.Unknown }
	end
	local bought = Exchange.Bought(data, week, offer.Id)
	if bought + count > offer.Limit then
		return { Ok = false, Error = Exchange.Limit }
	end
	local cost = offer.Price * count
	local held = data.Bag.Tokens[offer.Token] or 0
	if held < cost then
		local row = Tokens.ById[offer.Token]
		return { Ok = false, Error = Exchange.Short, Need = cost - held, Token = offer.Token, Tokens = if row then row.Plural else offer.Token }
	end
	-- every check passed: the change
	local left = held - cost
	data.Bag.Tokens[offer.Token] = if left > 0 then left else nil
	local answer: { [string]: any } = { Ok = true, Offer = offer.Id, Count = count, Token = offer.Token, Paid = cost }
	if def then
		for _ = 1, count do
			local got = Collection.Uncover(data, def, now)
			answer.Outcome, answer.Id = got.Outcome, got.Id
		end
	elseif key then
		data.Bag.Emblems[key] = (data.Bag.Emblems[key] or 0) + count
		answer.Emblem = key
	else
		local gives = offer.Gives :: string
		data.Bag.Tokens[gives] = (data.Bag.Tokens[gives] or 0) + (offer.Each or 1) * count
	end
	if data.Exchange.Week ~= week then
		data.Exchange = { Week = week, Bought = {} }
	end
	data.Exchange.Bought[offer.Id] = bought + count
	return answer
end

return Exchange
