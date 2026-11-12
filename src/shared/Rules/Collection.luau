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

return Collection
