--!strict
-- Base (shared, pure): what a player may ask of their base, one function per action, each changing a draft inside one
-- Transaction (docs/design.md, "Shards and the Void Breaker", "The base"). An action that touches the Breaker or the bays
-- first moves the base to `now`, so a change of workers or of the line never reaches back in time. Arguments come from a
-- client: each is checked here, and a refusal changes nothing. The server passes the time and, for a roll, a number from
-- its own Random in [0, 1). No Roblox API: it runs with Studio closed.
--
-- The actions, by name (BaseService registers them with DataService):
--   ChooseStarter { Shard }      once per account: one of Definitions.Shards.Starters joins the line
--   AddShard { Shard }           one shard from the bag joins the line
--   TakeOut { Chamber }          a shard leaves its chamber with its work kept, to the back of the line
--   Open { Index? }              a broken shard is opened (the oldest unless Index): its Voidkin is uncovered; the first
--                                Voidkin an account ever owns becomes its lead
--   SetWorker { Bay, Voidkin }   puts a Voidkin to work in an open bay, moving it from another bay; "" empties the bay

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Shards = require(Shared.Definitions.Shards)
local Breaker = require(Shared.Rules.Breaker)
local Collection = require(Shared.Rules.Collection)
local Odds = require(Shared.Rules.Odds)

local Base = {}

export type Answer = { [string]: any }
export type Action = (data: Profile.Data, args: any, now: number, u: number) -> Answer

-- Refusal codes.
Base.BadArgs = "BadArgs" -- arguments of the wrong shape, or a chamber, bay or index that isn't there
Base.Unknown = "Unknown" -- no such shard (or not a starter), or no such owned Voidkin
Base.Chosen = "Chosen" -- the starter was already chosen
Base.NoShard = "NoShard" -- none of that shard in the bag
Base.Empty = "Empty" -- nothing in that chamber, or nothing ready to open
Base.Leading = "Leading" -- the lead can't also work: one role at a time (docs/design.md, "Roles")

local function refuse(code: string): Answer
	return { Ok = false, Error = code }
end

local function field(args: any, key: string): any
	return if type(args) == "table" then args[key] else nil
end

-- A whole number from 1 to `count`, or nil. NaN, infinities, fractions and strings fail.
local function slot(value: any, count: number): number?
	if type(value) == "number" and value == math.floor(value) and value >= 1 and value <= count then
		return value
	end
	return nil
end

local function newWork(shard: string): Profile.ShardWork
	return { Def = shard, Luck = 0, Done = 0 }
end

function Base.ChooseStarter(data: Profile.Data, args: any, now: number): Answer
	if data.Progress.Starter ~= "" then
		return refuse(Base.Chosen)
	end
	local shard = field(args, "Shard")
	if type(shard) ~= "string" or table.find(Shards.Starters, shard) == nil then
		return refuse(Base.Unknown)
	end
	Breaker.Advance(data, now)
	data.Progress.Starter = shard
	Breaker.AddToLine(data, newWork(shard))
	return { Ok = true, Shard = shard }
end

function Base.AddShard(data: Profile.Data, args: any, now: number): Answer
	local shard = field(args, "Shard")
	if type(shard) ~= "string" or Shards.ById[shard] == nil then
		return refuse(Base.Unknown)
	end
	local held = data.Bag.Shards[shard] or 0
	if held < 1 then
		return refuse(Base.NoShard)
	end
	Breaker.Advance(data, now)
	data.Bag.Shards[shard] = if held > 1 then held - 1 else nil -- no zero counts kept
	Breaker.AddToLine(data, newWork(shard))
	return { Ok = true, Shard = shard }
end

function Base.TakeOut(data: Profile.Data, args: any, now: number): Answer
	local chamber = slot(field(args, "Chamber"), #data.Base.Chambers)
	if chamber == nil then
		return refuse(Base.BadArgs)
	end
	Breaker.Advance(data, now) -- a shard that finished a moment ago is Ready, not taken out
	if not Breaker.TakeOut(data, chamber) then
		return refuse(Base.Empty)
	end
	return { Ok = true, Chamber = chamber }
end

function Base.Open(data: Profile.Data, args: any, now: number, u: number): Answer
	Breaker.Advance(data, now)
	local ready = data.Base.Ready
	if #ready == 0 then
		return refuse(Base.Empty)
	end
	local asked = field(args, "Index")
	local at = if asked == nil then 1 else slot(asked, #ready)
	if at == nil then
		return refuse(Base.BadArgs)
	end
	local work = table.remove(ready, at) :: Profile.ShardWork
	local def = Odds.Roll(work.Def, work.Luck, u)
	if def == nil then
		return refuse(Base.Unknown) -- a definition that's gone: refused, so the shard stays Ready
	end
	local found = Collection.Uncover(data, def, now)
	if not found.Ok then
		return found
	end
	if data.Roles.Lead == "" then
		data.Roles.Lead = found.Id
	end
	found.Shard = work.Def
	found.Lead = data.Roles.Lead == found.Id
	return found
end

function Base.SetWorker(data: Profile.Data, args: any, now: number): Answer
	local bay = slot(field(args, "Bay"), #data.Base.Bays)
	local id = field(args, "Voidkin")
	if bay == nil or type(id) ~= "string" then
		return refuse(Base.BadArgs)
	end
	if id ~= "" then
		if data.Voidkin[id] == nil then
			return refuse(Base.Unknown)
		end
		if data.Roles.Lead == id then
			return refuse(Base.Leading)
		end
	end
	Breaker.Advance(data, now) -- the old workers made what they made up to now
	if id ~= "" then
		for _, other in data.Base.Bays do
			if other.Worker == id then
				other.Worker = ""
			end
		end
	end
	data.Base.Bays[bay].Worker = id
	return { Ok = true, Bay = bay, Voidkin = id }
end

Base.Actions = {
	ChooseStarter = Base.ChooseStarter,
	AddShard = Base.AddShard,
	TakeOut = Base.TakeOut,
	Open = Base.Open,
	SetWorker = Base.SetWorker,
} :: { [string]: Action }

return Base
