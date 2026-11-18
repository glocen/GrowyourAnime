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
local Hud = require(Shared.Rules.Hud)

local Read = {}

-- "2,357" (Shared.Rules.Hud: one home for how the HUD writes a number)
Read.Number = Hud.Digits

-- The battery's charge in kWh (TR18): a hundredth shown below 100, so a charging battery visibly counts up (research's
-- verdict on TR2, 2026-11-12: "it must visibly count up"; one bay's 18 kW turns the hundredth every 2 s): "0.35",
-- "47.80", "2,357". The unit is the caller's to write.
function Read.Kwh(n: number): string
	if math.abs(n) < 100 then
		return string.format("%.2f", math.floor(n * 100 + 0.5) / 100)
	end
	return Read.Number(n)
end

-- Power in kW: a tenth below 10, whole above: "7.5 kW", "18 kW". `signed` writes a "+" before what charges.
function Read.Kw(kw: number, signed: boolean?): string
	local shown = if math.abs(kw) < 10 then string.format("%.1f", math.floor(kw * 10 + 0.5) / 10) else Read.Number(kw)
	shown = shown:gsub("%.0$", "")
	return `{if signed and kw > 1e-9 then "+" else ""}{shown} kW`
end

-- Generation against demand, as the HUD's pill writes it: "30 / 34 kW". With nothing drawing, only what's made, "18 kW",
-- never eighteen out of nothing (TR24's fix 4).
function Read.Against(generation: number, demand: number): string
	local made = Read.Kw(generation)
	if demand <= 1e-9 then
		return made
	end
	return `{made:sub(1, #made - 3)} / {Read.Kw(demand)}`
end

-- Hours of work as the Power screen writes them: "45 min", "2 h", "2 h 30 min"; under a minute in seconds.
function Read.Hours(hours: number): string
	local seconds = math.max(0, hours * 3600)
	if seconds < 3600 then
		return if seconds < 60 then Read.Seconds(seconds) else `{math.floor(seconds / 60)} min`
	end
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds - h * 3600) / 60)
	return if m == 0 then `{Read.Number(h)} h` else `{Read.Number(h)} h {m} min`
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

-- Seconds as a clock, for a count in a narrow cell (a chamber's, at the smallest phone): "0:45", "1:20", "1:02:05".
function Read.Clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	local h, m = s // 3600, (s % 3600) // 60
	return if h > 0 then string.format("%d:%02d:%02d", h, m, s % 60) else string.format("%d:%02d", m, s % 60)
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

-- "Common · Red · Warrior · Fire"; "Red · Warrior · Fire" when `rarity` is false.
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
	Rates: Breaker.Rates, -- the plant now: generation, each machine's demand and speed, the battery's kW
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
