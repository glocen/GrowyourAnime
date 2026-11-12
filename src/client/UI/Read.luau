--!strict
-- Read (client): what the screens say about the player's save, in the game's words. It only reads the copy the server sent
-- (Controllers.Core.ProfileController); nothing here decides anything. The base is shown as it stands now by running the
-- server's own rules (Shared.Rules.Breaker) on a copy, so a chamber's seconds count down between the server's updates;
-- what can be opened still comes only from the server's copy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Voidkin = require(Shared.Definitions.Voidkin)
local Breaker = require(Shared.Rules.Breaker)

local Read = {}

-- "2,357"
function Read.Number(n: number): string
	local whole = tostring(math.floor(math.abs(n) + 0.5))
	local grouped = whole:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return if n < 0 then "-" .. grouped else grouped
end

-- Electricity a second as a minute's: "+3.0/min".
function Read.Rate(perSecond: number): string
	local perMinute = perSecond * 60
	return string.format("%s%.1f/min", if perMinute >= 0 then "+" else "", perMinute)
end

-- Seconds as the screens show them: "4 s", "1 min 20 s".
function Read.Seconds(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s < 60 then
		return `{s} s`
	end
	local m = s // 60
	return if s % 60 == 0 then `{m} min` else `{m} min {s % 60} s`
end

-- A shard's name: "Rook's shard", "Watt's shard", "Lantern Row shard".
function Read.ShardName(id: string): string
	local row = Shards.ById[id]
	if row == nil then
		return "a shard"
	end
	if row.Holds ~= "" then
		local holds = Voidkin.ById[row.Holds]
		return `{if holds then holds.Name else row.Holds}'s shard`
	end
	local ground = Grounds.ById[row.Ground]
	return `{if ground then ground.Name else row.Ground} shard`
end

-- An owned Voidkin's name: its nickname, else its own.
function Read.VoidkinName(owned: Profile.OwnedVoidkin): string
	if owned.Nickname ~= "" then
		return owned.Nickname
	end
	local row = Voidkin.ById[owned.Def]
	return if row then row.Name else owned.Def
end

-- "Common · Strength · Warrior · Fire"; "Strength · Warrior · Fire" when `rarity` is false.
function Read.VoidkinLine(def: string, rarity: boolean?): string
	local row = Voidkin.ById[def]
	if row == nil then
		return ""
	end
	local parts = if rarity == false then { row.Type, row.Class } else { row.Rarity, row.Type, row.Class }
	if row.Element ~= "" then
		table.insert(parts, row.Element)
	end
	return table.concat(parts, " · ")
end

export type Base = {
	Data: Profile.View, -- a copy, advanced to now: never sent anywhere
	Rates: { Speed: number, Production: number, Net: number, Busy: boolean },
}

-- The base as it stands at server time `now`, from the server's copy `view`.
function Read.Base(view: Profile.View, now: number): Base
	local data = Profile.View(view :: any) -- a copy that shares no table with the server's
	if data.Base.Stamp > 0 and now > data.Base.Stamp then
		Breaker.Advance(data :: any, now)
	end
	return { Data = data, Rates = Breaker.Rates(data :: any) }
end

-- Seconds until a chamber's shard is ready at the base's speed now.
function Read.Left(base: Base, work: Profile.ShardWork): number
	return Breaker.Left(work) / math.max(base.Rates.Speed, 1e-3)
end

-- Owned Voidkin, the lead first, then by level, then by name.
function Read.Roster(view: Profile.View): { Profile.OwnedVoidkin }
	local list: { Profile.OwnedVoidkin } = {}
	for _, owned in view.Voidkin do
		table.insert(list, owned)
	end
	local lead = view.Roles.Lead
	table.sort(list, function(a: Profile.OwnedVoidkin, b: Profile.OwnedVoidkin): boolean
		if (a.Id == lead) ~= (b.Id == lead) then
			return a.Id == lead
		end
		if a.Level ~= b.Level then
			return a.Level > b.Level
		end
		return Read.VoidkinName(a) < Read.VoidkinName(b)
	end)
	return list
end

-- What a Voidkin is doing, with its bay's number: "Lead", "Bay 1", or "" (Profile.RoleOf without the number).
function Read.Role(view: Profile.View, id: string): string
	if view.Roles.Lead == id then
		return "Lead"
	end
	for index, bay in view.Base.Bays do
		if bay.Worker == id then
			return `Bay {index}`
		end
	end
	return ""
end

return Read
