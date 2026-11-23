--!strict
-- Base (shared, pure): what a player may ask of their base, one function per action, each changing a draft inside one
-- Transaction (docs/design.md, "Shards and the Void Breaker", "The base"). An action that touches the Breaker or the bays
-- first moves the base to `now`, so a change of workers or of the line never reaches back in time. Arguments come from a
-- client: each is checked here, and a refusal changes nothing. The server passes the time and, for a roll, a number from
-- its own Random in [0, 1). No Roblox API: it runs with Studio closed.
--
-- The actions, by name (BaseService registers them with DataService):
--   ChooseStarter { Shard }      once per account: one of Definitions.Shards.Starters joins the line
--   AddShard { Shard }           one shard from the bag joins the line; the answer says where it stands (Chamber or Line)
--   TakeOut { Chamber }          a shard leaves its chamber with its work kept, to the back of the line
--   Open { Index? }              a broken shard is opened (the oldest unless Index): its Voidkin is uncovered; the first
--                                Voidkin an account ever owns becomes its lead
--   SetWorker { Bay, Voidkin }   puts a Voidkin to work in an open bay, moving it from another bay; "" empties the bay
--   Infuse { Chamber | Line, Def, Level }
--                                voltage from the battery into one shard still breaking (Chamber) or waiting (Line): its
--                                time left cut to Config.Shards.Voltage.Levels[Level]'s share, at once (TR18; the director,
--                                2026-11-15, "Faster break"), its odds untouched. Once a shard, never one that holds a
--                                stated Voidkin, never one it saves under a minute; the price is Rules.Power.Voltage's. Def
--                                is the shard the client saw there; a shard that broke or moved since is refused, and
--                                nothing is spent
--   SetPower { Auto, Shares? }   how the generation is split (Rules.Power): Auto, or each machine's share of it, checked
--                                by Rules.Power.Shares; refused until the Power screen has opened (Base.Power.Open)
--   UpgradeBase { Level }        the base's next level for its Credits (TR21; Rules.BaseLevels): the bays it opens join,
--                                empty. Level names the level bought, so a second tap is refused, never charged twice
--   UpgradeMachine { Machine, Bay?, Level }
--                                a machine's next level ("Breaker", "Condenser", or "Bay" with its Bay) for its Credits,
--                                never past the base's ceiling; the Breaker's chambers join at their levels and take the
--                                line's next; the Condenser only once it's awake
--   CollectTray {}               the Stone Condenser's tray, every stone in it, into the bag (TR37; Rules.Condenser). A
--                                second ask finds it empty, so nothing is collected twice
--   Convert {}                   the Condenser's convert begins: Config.Condenser.Convert's stones leave the bag now, and
--                                its higher grade lands in the tray once its work is done. One at a time

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Shards = require(Shared.Definitions.Shards)
local Breaker = require(Shared.Rules.Breaker)
local Collection = require(Shared.Rules.Collection)
local Odds = require(Shared.Rules.Odds)
local Power = require(Shared.Rules.Power)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Condenser = require(Shared.Rules.Condenser)
local ShardConfig = require(Shared.Config.Shards)
local BaseConfig = require(Shared.Config.Base)
local CondenserConfig = require(Shared.Config.Condenser)

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
Base.Named = "Named" -- the shard holds a stated Voidkin: voltage isn't offered on it
Base.Infused = "Infused" -- the shard has had its voltage
Base.Brief = "Brief" -- voltage would save it under Config.Shards.Voltage.MinSavedSeconds: not offered
Base.Short = "Short" -- less charge in the battery than voltage's price, or fewer Credits than an upgrade's
Base.Moved = "Moved" -- the shard isn't there any more: it broke, or the line moved on
Base.Closed = "Closed" -- the Power screen hasn't opened yet: Auto runs the base unseen
Base.Over = "Over" -- the shares come to more than the whole generation
Base.Stale = "Stale" -- the level asked isn't the next one: the upgrade was bought already, or the screen was behind
Base.Cap = BaseLevels.AtCap -- past the last level there is at launch
Base.Ceiling = BaseLevels.AtCeiling -- a machine at its base's ceiling: the base's level comes first
Base.Asleep = "Asleep" -- the Stone Condenser hasn't woken yet: the base's level comes first (Config.Condenser.Wakes)
Base.Busy = "Busy" -- a convert is under way: one at a time
Base.Stones = "Stones" -- fewer stones in the bag than the convert takes

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
	local work = newWork(shard)
	Breaker.AddToLine(data, work)
	for index, chamber in data.Base.Chambers do
		if chamber.Work == work then
			return { Ok = true, Shard = shard, Chamber = index }
		end
	end
	return { Ok = true, Shard = shard, Line = table.find(data.Base.Line, work) }
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

function Base.Infuse(data: Profile.Data, args: any, now: number): Answer
	local levelAt = slot(field(args, "Level"), #ShardConfig.Voltage.Levels)
	local chamber, line, def = field(args, "Chamber"), field(args, "Line"), field(args, "Def")
	if levelAt == nil or type(def) ~= "string" or (chamber == nil) == (line == nil) then
		return refuse(Base.BadArgs)
	end
	-- The shard the client saw, found before the Breaker moves on: a row keeps its table as it moves to a chamber or Ready.
	local work: Profile.ShardWork?
	if chamber ~= nil then
		local at = slot(chamber, #data.Base.Chambers)
		if at == nil then
			return refuse(Base.BadArgs)
		end
		work = data.Base.Chambers[at].Work
	else
		local at = slot(line, math.max(#data.Base.Line, 1))
		if at == nil then
			return refuse(Base.BadArgs)
		end
		work = data.Base.Line[at]
	end
	if work == nil or work.Def ~= def then
		return refuse(Base.Moved)
	end
	local row = Shards.ById[def]
	if row == nil then
		return refuse(Base.Unknown)
	end
	if row.Holds ~= "" then
		return refuse(Base.Named)
	end
	if work.Volt ~= nil then
		return refuse(Base.Infused)
	end
	Breaker.Advance(data, now) -- the battery and the work as they stand now
	if table.find(data.Base.Ready, work) then
		return refuse(Base.Moved) -- it broke a moment ago: voltage goes into a shard before it breaks, so nothing is spent
	end
	local price, saved = Power.Voltage(work, levelAt)
	if price == nil then
		return refuse(Base.Brief)
	end
	if data.Base.Charge < price then
		return refuse(Base.Short)
	end
	data.Base.Charge -= price
	work.Volt = levelAt
	work.Done += saved
	Breaker.Settle(data) -- High breaks it at once: to Ready, and the chamber it frees takes the line's next
	return { Ok = true, Def = def, Level = levelAt, Spent = price, Saved = saved, Ready = table.find(data.Base.Ready, work) ~= nil }
end

function Base.SetPower(data: Profile.Data, args: any, now: number): Answer
	if not data.Base.Power.Open then
		return refuse(Base.Closed)
	end
	local auto = field(args, "Auto")
	if type(auto) ~= "boolean" then
		return refuse(Base.BadArgs)
	end
	local shares: { [string]: number }? = nil
	if not auto then
		local checked, code = Power.Shares(field(args, "Shares"))
		if checked == nil then
			return refuse(code or Base.BadArgs)
		end
		shares = checked
	end
	Breaker.Advance(data, now) -- the old split ran up to now
	data.Base.Power.Auto = auto
	if shares then
		data.Base.Power.Shares = shares
	end
	return { Ok = true, Auto = auto, Shares = table.clone(data.Base.Power.Shares) }
end

-- The level asked, a whole number, or nil.
local function wanted(args: any): number?
	local level = field(args, "Level")
	return if type(level) == "number" and level == math.floor(level) and level >= 1 and level < math.huge then level else nil
end

function Base.UpgradeBase(data: Profile.Data, args: any, now: number): Answer
	local level = wanted(args)
	if level == nil then
		return refuse(Base.BadArgs)
	end
	local base = data.Base
	if level ~= base.Level + 1 then
		return refuse(Base.Stale)
	end
	local offer = BaseLevels.Next(base.Level, math.huge)
	local price = offer.Price
	if offer.Why ~= nil or price == nil then
		return refuse(offer.Why or Base.Cap)
	end
	Breaker.Advance(data, now) -- the old level's battery and bays ran up to now
	if data.Currency.Credits < price then
		return refuse(Base.Short)
	end
	data.Currency.Credits -= price
	base.Level = level
	for _ = #base.Bays + 1, BaseLevels.Bays(level) do
		table.insert(base.Bays, { Worker = "", Level = 1 })
	end
	return { Ok = true, Level = level, Spent = price, Bays = #base.Bays }
end

function Base.UpgradeMachine(data: Profile.Data, args: any, now: number): Answer
	local machine, level = field(args, "Machine"), wanted(args)
	local base = data.Base
	local bay: number? = nil
	if machine == "Bay" then
		bay = slot(field(args, "Bay"), #base.Bays)
		if bay == nil then
			return refuse(Base.BadArgs)
		end
	elseif (machine ~= "Breaker" and machine ~= "Condenser") or field(args, "Bay") ~= nil then
		return refuse(Base.BadArgs)
	end
	if level == nil then
		return refuse(Base.BadArgs)
	end
	if machine == "Condenser" and not Condenser.Awake(base.Level) then
		return refuse(Base.Asleep)
	end
	local current = if bay then base.Bays[bay].Level or 1 else base.Machines[machine] or 1
	if level ~= current + 1 then
		return refuse(Base.Stale)
	end
	local offer = BaseLevels.NextMachine(machine, current, base.Level, math.huge)
	local price = offer.Price
	if offer.Why ~= nil or price == nil then
		return refuse(offer.Why or Base.Cap)
	end
	Breaker.Advance(data, now) -- the machine's old level worked up to now
	if data.Currency.Credits < price then
		return refuse(Base.Short)
	end
	data.Currency.Credits -= price
	if bay then
		base.Bays[bay].Level = level
		return { Ok = true, Machine = machine, Bay = bay, Level = level, Spent = price }
	end
	if machine == "Condenser" then
		base.Machines.Condenser = level -- its tray's cap rises with it, so a full tray makes again
		return { Ok = true, Machine = machine, Level = level, Spent = price }
	end
	base.Machines.Breaker = level
	for _ = #base.Chambers + 1, math.min(BaseLevels.Chambers(level), BaseConfig.Breaker.MostChambers) do
		table.insert(base.Chambers, {})
	end
	Breaker.Settle(data) -- a new chamber takes the line's next shard
	return { Ok = true, Machine = machine, Level = level, Spent = price, Chambers = #base.Chambers }
end

function Base.CollectTray(data: Profile.Data, _args: any, now: number): Answer
	local base = data.Base
	if not Condenser.Awake(base.Level) then
		return refuse(Base.Asleep)
	end
	Breaker.Advance(data, now) -- what it made up to now lands first
	local taken: { [string]: number } = {}
	local count = 0
	for grade, held in base.Condenser.Tray do
		if held > 0 then
			taken[grade] = held
			count += held
			data.Bag.Stones[grade] = (data.Bag.Stones[grade] or 0) + held
		end
	end
	if count == 0 then
		return refuse(Base.Empty)
	end
	base.Condenser.Tray = {}
	return { Ok = true, Stones = taken, Count = count }
end

function Base.Convert(data: Profile.Data, _args: any, now: number): Answer
	local base = data.Base
	local convert = CondenserConfig.Convert
	if not Condenser.Awake(base.Level) then
		return refuse(Base.Asleep)
	end
	Breaker.Advance(data, now) -- the one before finishes first, if its time has come
	if base.Condenser.Convert ~= nil then
		return refuse(Base.Busy)
	end
	local held = data.Bag.Stones[convert.From] or 0
	if held < convert.Take then
		return refuse(Base.Stones)
	end
	data.Bag.Stones[convert.From] = held - convert.Take
	base.Condenser.Convert = 0
	return { Ok = true, Spent = convert.Take, Seconds = convert.Seconds }
end

Base.Actions = {
	ChooseStarter = Base.ChooseStarter,
	AddShard = Base.AddShard,
	TakeOut = Base.TakeOut,
	Open = Base.Open,
	SetWorker = Base.SetWorker,
	Infuse = Base.Infuse,
	SetPower = Base.SetPower,
	UpgradeBase = Base.UpgradeBase,
	UpgradeMachine = Base.UpgradeMachine,
	CollectTray = Base.CollectTray,
	Convert = Base.Convert,
} :: { [string]: Action }

return Base
