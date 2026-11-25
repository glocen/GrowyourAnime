--!strict
-- Rules.Codes (shared, pure): the codes (TR59; docs/design.md, "The welcome week and codes"; Config.Welcome.Codes). A
-- code is matched without case or spaces, taken once an account, never after its end, and pays only what Pays allows:
-- never Credits, never anything the store sells. Five wrong tries a minute, then a minute's wait, kept on the server
-- (a Gate, never saved). No Roblox API: it runs with Studio closed.
--   Codes.Plain(typed)                         a code as typed, made comparable: upper case, no spaces; "" past Most
--   Codes.Redeem(data, typed, now, list, gate) the code's gifts into the bag: { Ok, Code, Gives } or a refusal
--   Codes.Allowed(code)                        every gift is one a code may give
--   Codes.Said(answer)                         a redeem's words for its line, taken or refused
--   Codes.Gate()                               a player's wrong tries, empty

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local Welcome = require(Shared.Rules.Welcome)

local Codes = {}

Codes.Unknown = "Unknown" -- no code is that, or not yet
Codes.Used = "Used" -- this account took it before
Codes.Ended = "Ended" -- its time is over
Codes.Wait = "Wait" -- five wrong tries inside a minute: a minute's wait

-- The lines a redeem says (the content check passed them, 2026-11-24).
Codes.Words = {
	Unknown = "That isn't a code",
	Ended = "That code has ended",
	Used = "Already used on this account",
	Wait = "Try again in a minute",
} :: { [string]: string }

export type Gate = { Wrong: { number }, Until: number }

function Codes.Gate(): Gate
	return { Wrong = {}, Until = 0 }
end

function Codes.Plain(typed: any): string
	if type(typed) ~= "string" then
		return ""
	end
	local plain = string.upper((string.gsub(typed, "%s", "")))
	return if #plain > Config.Codes.Most then "" else plain
end

function Codes.Allowed(code: Config.Code): boolean
	local pays = Config.Codes.Pays
	for _, gift in code.Gives do
		local fits = (gift.Chest ~= nil and gift.Shard == nil and table.find(pays.Chests, gift.Chest) ~= nil)
			or (gift.Shard ~= nil and gift.Chest == nil and table.find(pays.Shards, gift.Shard) ~= nil)
		if not fits or gift.Count < 1 then
			return false
		end
	end
	return #code.Gives > 0
end

local function wrong(gate: Gate, now: number)
	local kept: { number } = {}
	for _, at in gate.Wrong do
		if now - at < Config.Codes.Wait then
			table.insert(kept, at)
		end
	end
	table.insert(kept, now)
	if #kept >= Config.Codes.Tries then
		gate.Until = now + Config.Codes.Wait
		kept = {}
	end
	gate.Wrong = kept
end

function Codes.Redeem(data: Profile.Data, typed: any, now: number, list: { Config.Code }, gate: Gate): { [string]: any }
	if now < gate.Until then
		return { Ok = false, Error = Codes.Wait }
	end
	local plain = Codes.Plain(typed)
	local code: Config.Code? = nil
	for _, each in list do
		if plain ~= "" and Codes.Plain(each.Code) == plain then
			code = each
			break
		end
	end
	if code == nil then
		wrong(gate, now)
		return { Ok = false, Error = Codes.Unknown }
	end
	local taken = data.Codes or {}
	if taken[code.Id] then
		return { Ok = false, Error = Codes.Used }
	end
	if code.Until > 0 and now >= code.Until then
		return { Ok = false, Error = Codes.Ended }
	end
	if not Codes.Allowed(code) then
		return { Ok = false, Error = Codes.Unknown } -- a code that pays what it mustn't is never taken
	end
	for _, gift in code.Gives do
		Welcome.Give(data, gift)
	end
	taken[code.Id] = true
	data.Codes = taken
	return { Ok = true, Code = code.Id, Gives = table.clone(code.Gives) }
end

function Codes.Said(answer: { [string]: any }): string
	if answer.Ok ~= true then
		return Codes.Words[answer.Error] or Codes.Words.Unknown
	end
	local parts: { string } = {}
	for _, gift in (answer.Gives or {}) :: { Config.Gift } do
		table.insert(parts, Welcome.Said(gift))
	end
	return `Code taken: {table.concat(parts, ", ")}`
end

return Codes
