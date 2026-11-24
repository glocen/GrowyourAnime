--!strict
-- Collection (shared, pure): what uncovering a Voidkin does to a profile, and spending copies on a star
-- (docs/design.md, "Voidkin", "Stars"). A Voidkin is owned once: the first is a new record with its own id; a duplicate
-- waits on it as a copy, spent by hand on the next star at any level, each star costing Config.Voidkin.StarCopies; past the
-- last star a copy sells for Credits. Each function changes a draft inside one Transaction and returns its answer.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local VoidkinConfig = require(Shared.Config.Voidkin)
local Voidkin = require(Shared.Definitions.Voidkin)
local Profile = require(Shared.Data.Profile)
local Stats = require(Shared.Rules.Stats)
local Breaker = require(Shared.Rules.Breaker)

local Collection = {}

-- Refusal codes.
Collection.Unknown = "Unknown" -- no such Voidkin definition, or no such owned Voidkin
Collection.MaxStars = "MaxStars"
Collection.NotEnough = "NotEnough"
Collection.Working = "Working" -- a worker can't also work elsewhere (a Lead recalls it: Collection.SetLead)
Collection.BadName = "BadName" -- a nickname that isn't text, or holds a control character
Collection.TooLong = "TooLong" -- a nickname past Config.Voidkin.Nickname.Max characters

-- The owned Voidkin of a definition, or nil. Owned once each, so the first match is the only one.
function Collection.Owned(data: Profile.Data, def: string): Profile.OwnedVoidkin?
	for _, owned in data.Voidkin do
		if owned.Def == def then
			return owned
		end
	end
	return nil
end

local function sell(data: Profile.Data, def: string, copies: number): number
	local row = Voidkin.ById[def]
	local credits = copies * (VoidkinConfig.SellCredits[row.Rarity] or 0)
	data.Currency.Credits += credits
	return credits
end

-- Uncovers one `def` at `now`: { Ok, Outcome = "New" | "Copy" | "Sold", Id, Def, Credits }.
function Collection.Uncover(data: Profile.Data, def: string, now: number): { [string]: any }
	if not Voidkin.ById[def] then
		return { Ok = false, Error = Collection.Unknown }
	end
	local entry = data.Index[def]
	if entry then
		entry.Count += 1
	else
		data.Index[def] = { First = now, Count = 1 }
	end
	local owned = Collection.Owned(data, def)
	if owned == nil then
		local id = Profile.NewId(data)
		data.Voidkin[id] = {
			Id = id,
			Def = def,
			Level = 1,
			Xp = 0,
			Stars = 0,
			Copies = 0,
			Nickname = "",
			Preset = 1,
			Favourite = false,
			Locked = false,
			Born = now,
		}
		return { Ok = true, Outcome = "New", Id = id, Def = def, Credits = 0 }
	end
	if owned.Stars >= VoidkinConfig.MaxStars then
		return { Ok = true, Outcome = "Sold", Id = owned.Id, Def = def, Credits = sell(data, def, 1) }
	end
	owned.Copies += 1
	return { Ok = true, Outcome = "Copy", Id = owned.Id, Def = def, Credits = 0 }
end

-- The copies the next star costs, or nil at the last star.
function Collection.NextStarCost(owned: Profile.OwnedVoidkin): number?
	if owned.Stars >= VoidkinConfig.MaxStars then
		return nil
	end
	return VoidkinConfig.StarCopies[owned.Stars + 1]
end

-- Spends copies on the next star: { Ok, Id, Stars, Copies, Credits }. Reaching the last star sells the copies left over.
function Collection.SpendCopies(data: Profile.Data, id: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned then
		return { Ok = false, Error = Collection.Unknown }
	end
	local cost = Collection.NextStarCost(owned)
	if cost == nil then
		return { Ok = false, Error = Collection.MaxStars }
	end
	if owned.Copies < cost then
		return { Ok = false, Error = Collection.NotEnough }
	end
	owned.Copies -= cost
	owned.Stars += 1
	local credits = 0
	if owned.Stars >= VoidkinConfig.MaxStars and owned.Copies > 0 then
		credits = sell(data, owned.Def, owned.Copies)
		owned.Copies = 0
	end
	return { Ok = true, Id = owned.Id, Stars = owned.Stars, Copies = owned.Copies, Credits = credits }
end

-- Makes an owned Voidkin the lead: { Ok, Id, Left }. One role at a time (docs/design.md, "Roles"): a stationed one is
-- recalled from its bay in the same step, after the bays have made what they made up to `now`, and Left is the bay it
-- left (research's ruling on the stationed page, 2026-11-17, tier 2). The old lead goes home idle. One transaction, so a
-- repeat or a cut never leaves it stationed and leading at once.
function Collection.SetLead(data: Profile.Data, id: any, now: number?): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned then
		return { Ok = false, Error = Collection.Unknown }
	end
	local left: number? = nil
	if Profile.RoleOf(data, owned.Id) == "Worker" then
		if now == nil then
			return { Ok = false, Error = Collection.Working } -- no clock to settle the bays by
		end
		Breaker.Advance(data, now) -- its bay made what it made up to now
		for index, bay in data.Base.Bays do
			if bay.Worker == owned.Id then
				bay.Worker = ""
				left = left or index
			end
		end
	end
	data.Roles.Lead = owned.Id
	return { Ok = true, Id = owned.Id, Left = left }
end

-- Marks an owned Voidkin a favourite, or locks it, or takes either off: { Ok, Id, Favourite, Locked }. Neither changes
-- its strength: a favourite sorts first, and a lock keeps it from being spent (docs/design.md, "Voidkin"; TR17).
function Collection.SetMark(data: Profile.Data, id: any, mark: any, on: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned or (mark ~= "Favourite" and mark ~= "Locked") or type(on) ~= "boolean" then
		return { Ok = false, Error = Collection.Unknown }
	end
	if mark == "Favourite" then
		owned.Favourite = on
	else
		owned.Locked = on
	end
	return { Ok = true, Id = owned.Id, Favourite = owned.Favourite, Locked = owned.Locked }
end

-- A Voidkin's name as a list shows it: its nickname, else its definition's name.
function Collection.Name(owned: Profile.OwnedVoidkin): string
	if owned.Nickname ~= "" then
		return owned.Nickname
	end
	local row = Voidkin.ById[owned.Def]
	return if row then row.Name else owned.Def
end

-- The owned Voidkin in the order every list shows them: the lead, then the favourites, then by level, then by name. The
-- id settles a tie, so two reads of one save never swap two cards.
function Collection.Roster(voidkin: { [string]: Profile.OwnedVoidkin }, lead: string): { Profile.OwnedVoidkin }
	local list: { Profile.OwnedVoidkin } = {}
	for _, owned in voidkin do
		table.insert(list, owned)
	end
	table.sort(list, function(a: Profile.OwnedVoidkin, b: Profile.OwnedVoidkin): boolean
		if (a.Id == lead) ~= (b.Id == lead) then
			return a.Id == lead
		end
		if a.Favourite ~= b.Favourite then
			return a.Favourite
		end
		if a.Level ~= b.Level then
			return a.Level > b.Level
		end
		local named, other = Collection.Name(a), Collection.Name(b)
		if named ~= other then
			return named < other
		end
		return a.Id < b.Id
	end)
	return list
end

-- The Voidkin the base's showcase stands (TR22; docs/design.md, "The base"): the one picked with "Show at the gate" while
-- it's owned, else the strongest, by Combat Power, then level, then Id, so the plinth never flickers between two. Nil
-- with none owned.
function Collection.Showcase(data: Profile.Data): Profile.OwnedVoidkin?
	local picked = data.Voidkin[data.Base.Showcase or ""]
	if picked then
		return picked
	end
	local best: Profile.OwnedVoidkin?, most = nil, -math.huge
	for _, owned in data.Voidkin do
		local power = Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
		local ahead = best == nil
			or power > most
			or (power == most and (owned.Level > best.Level or (owned.Level == best.Level and owned.Id < best.Id)))
		if ahead then
			best, most = owned, power
		end
	end
	return best
end

-- Picks the Voidkin the showcase stands, any owned one whatever its role: { Ok, Id }. "" gives it back to the strongest.
function Collection.SetShowcase(data: Profile.Data, id: any): { [string]: any }
	if id == "" then
		data.Base.Showcase = ""
		return { Ok = true, Id = "" }
	end
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned then
		return { Ok = false, Error = Collection.Unknown }
	end
	data.Base.Showcase = owned.Id
	return { Ok = true, Id = owned.Id }
end

-- A nickname as typed, made tidy: its ends trimmed and each run of spaces made one; "" takes it off. Nil and the reason
-- when it can't be one. The text filter is the server's, before the rule runs (VoidkinService; docs/roblox-rules.md).
function Collection.CleanName(raw: any): (string?, string?)
	if type(raw) ~= "string" or string.find(raw, "%c") then
		return nil, Collection.BadName
	end
	local tidy = string.gsub(raw, "^%s+", "")
	tidy = string.gsub(tidy, "%s+$", "")
	tidy = string.gsub(tidy, "%s+", " ")
	local length = utf8.len(tidy)
	if length == nil then
		return nil, Collection.BadName
	end
	if length > VoidkinConfig.Nickname.Max then
		return nil, Collection.TooLong
	end
	return tidy, nil
end

-- Gives an owned Voidkin its nickname, stored as the player wrote it, tidied: { Ok, Id, Nickname }. Each viewer sees it
-- filtered (engineering plan, "An owned Voidkin").
function Collection.SetNickname(data: Profile.Data, id: any, raw: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned then
		return { Ok = false, Error = Collection.Unknown }
	end
	local name, why = Collection.CleanName(raw)
	if name == nil then
		return { Ok = false, Error = why }
	end
	owned.Nickname = name
	return { Ok = true, Id = owned.Id, Nickname = name }
end

local function voidkinArg(args: any): any
	return if type(args) == "table" then args.Voidkin else nil
end

-- What a client may ask, by name, with the same shape as Rules.Base's actions (VoidkinService registers them).
--   SetLead { Voidkin }       the lead
--   SpendCopies { Voidkin }   the next star
--   SetMark { Voidkin, Mark, On }   Mark "Favourite" or "Locked", On true or false
--   SetNickname { Voidkin, Name }   "" takes it off; the server's filter passes it first
--   SetShowcase { Voidkin }   the one the showcase at the gate stands (TR22); "" for the strongest
Collection.Actions = {
	SetLead = function(data: Profile.Data, args: any, now: number): { [string]: any }
		return Collection.SetLead(data, voidkinArg(args), now)
	end,
	SpendCopies = function(data: Profile.Data, args: any): { [string]: any }
		return Collection.SpendCopies(data, voidkinArg(args))
	end,
	SetMark = function(data: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		return Collection.SetMark(data, given.Voidkin, given.Mark, given.On)
	end,
	SetNickname = function(data: Profile.Data, args: any): { [string]: any }
		local given = if type(args) == "table" then args else {}
		return Collection.SetNickname(data, given.Voidkin, given.Name)
	end,
	SetShowcase = function(data: Profile.Data, args: any): { [string]: any }
		return Collection.SetShowcase(data, voidkinArg(args))
	end,
} :: { [string]: (data: Profile.Data, args: any, now: number, u: number) -> { [string]: any } }

return Collection
