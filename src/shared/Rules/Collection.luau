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

local Collection = {}

-- Refusal codes.
Collection.Unknown = "Unknown" -- no such Voidkin definition, or no such owned Voidkin
Collection.MaxStars = "MaxStars"
Collection.NotEnough = "NotEnough"
Collection.Working = "Working" -- a worker can't also lead
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

-- Makes an owned Voidkin the lead: { Ok, Id }. A worker is refused: one role at a time (docs/design.md, "Roles").
function Collection.SetLead(data: Profile.Data, id: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if not owned then
		return { Ok = false, Error = Collection.Unknown }
	end
	if Profile.RoleOf(data, owned.Id) == "Worker" then
		return { Ok = false, Error = Collection.Working }
	end
	data.Roles.Lead = owned.Id
	return { Ok = true, Id = owned.Id }
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
Collection.Actions = {
	SetLead = function(data: Profile.Data, args: any): { [string]: any }
		return Collection.SetLead(data, voidkinArg(args))
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
} :: { [string]: (data: Profile.Data, args: any, now: number, u: number) -> { [string]: any } }

return Collection
