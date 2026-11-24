--!strict
-- Welcome (shared, pure): what's given, never sold (docs/research/cloud-2026-11-24/launch-design.md, section 8, on the
-- director's "ok" of 2026-11-24; Config.Welcome). The welcome week gives one gift for each day played, never each
-- calendar day, and never loses one: day by day the account gets the next. A code is typed once per account and gives
-- chests with no gear only. Each is one transaction, and a repeat changes nothing (the day, the code's id).
--   Welcome.Gift(data, today)              today's gift, if it's due: { Ok, Gift (1 to 7), Chest, Shard } or a refusal
--   Welcome.Case(data)                     the Emblem Case a "Case" gift gives
--   Welcome.Named(data)                    the Named shard a "Named" gift gives, or "" when the account owns all five
--   Welcome.Redeem(data, typed, now, codes)   a code: { Ok, Code, Chests } or a refusal
--   Welcome.Plain(typed)                   a code as typed, made comparable: upper case, no spaces
--   Welcome.Said(answer)                   a gift's or a code's words, for its toast
--   Welcome.Refused                        a code's refusal's words, by error

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local ChestRows = require(Shared.Definitions.Chests)
local Grounds = require(Shared.Definitions.Grounds)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Chests = require(Shared.Rules.Chests)
local Collection = require(Shared.Rules.Collection)

local Welcome = {}

Welcome.Early = "Early" -- no starter chosen yet: the first gift waits for the choice, out of the first moments' way
Welcome.Done = "Done" -- the week's seven are given
Welcome.Today = "Today" -- today's is given; the next comes on the next day played
Welcome.Unknown = "Unknown" -- no code is that, or not yet
Welcome.Used = "Used" -- this account typed it before
Welcome.Ended = "Ended" -- its time is over

Welcome.Refused = {
	Unknown = "That isn't a code",
	Used = "You've used that code",
	Ended = "That code has ended",
} :: { [string]: string }

-- The account's furthest ground open, in the grounds' order.
local function furthest(data: Profile.Data): string
	local best = Grounds.First
	for _, row in Grounds.List do
		if data.Progress.Grounds[row.Id] ~= nil then
			best = row.Id
		end
	end
	return best
end

function Welcome.Case(data: Profile.Data): string
	local row = ChestRows.CaseOf(furthest(data), "Elite")
	return if row then row.Id else Config.Fallback
end

function Welcome.Named(data: Profile.Data): string
	for _, row in Voidkin.List do
		if Voidkin.Made(row) and Collection.Owned(data, row.Id) == nil then
			for _, shard in Shards.List do
				if shard.Grade == "Named" and shard.Holds == row.Id then
					return shard.Id
				end
			end
		end
	end
	return ""
end

function Welcome.Gift(data: Profile.Data, today: number): { [string]: any }
	local gifts = data.Gifts
	if data.Progress.Starter == "" then
		return { Ok = false, Error = Welcome.Early }
	end
	if gifts.Week >= #Config.Week then
		return { Ok = false, Error = Welcome.Done }
	end
	if gifts.Week > 0 and gifts.Day >= today then
		return { Ok = false, Error = Welcome.Today }
	end
	local number = gifts.Week + 1
	local gift = Config.Week[number]
	local chest, shard = "", ""
	if gift == "Named" then
		shard = Welcome.Named(data)
		if shard == "" then
			chest = Config.Fallback
		end
	elseif gift == "Case" then
		chest = Welcome.Case(data)
	else
		chest = gift
	end
	if shard ~= "" then
		data.Bag.Shards[shard] = (data.Bag.Shards[shard] or 0) + 1
	elseif ChestRows.ById[chest] then
		Chests.Grant(data, chest, 1)
	else
		return { Ok = false, Error = Welcome.Unknown } -- a seed naming no chest: nothing given, the day kept for a fix
	end
	gifts.Week = number
	gifts.Day = today
	return { Ok = true, Gift = number, Of = #Config.Week, Chest = chest, Shard = shard }
end

function Welcome.Plain(typed: string): string
	return (string.upper(typed):gsub("%s", ""))
end

function Welcome.Redeem(data: Profile.Data, typed: any, now: number, codes: { Config.Code }): { [string]: any }
	if type(typed) ~= "string" or #typed > Config.CodeMost then
		return { Ok = false, Error = Welcome.Unknown }
	end
	local plain = Welcome.Plain(typed)
	local found: Config.Code? = nil
	for _, code in codes do
		if plain ~= "" and Welcome.Plain(code.Code) == plain then
			found = code
		end
	end
	if found == nil or (found.From > 0 and now < found.From) then
		return { Ok = false, Error = Welcome.Unknown }
	end
	if data.Gifts.Codes[found.Id] ~= nil then
		return { Ok = false, Error = Welcome.Used }
	end
	if found.Until > 0 and now > found.Until then
		return { Ok = false, Error = Welcome.Ended }
	end
	for id, count in found.Chests do
		local row = ChestRows.ById[id]
		if row == nil or row.Kind == "Gear" or count < 1 or count ~= math.floor(count) then
			return { Ok = false, Error = Welcome.Unknown } -- a code that would give gear, or nothing: never given
		end
	end
	for id, count in found.Chests do
		Chests.Grant(data, id, count)
	end
	data.Gifts.Codes[found.Id] = now
	return { Ok = true, Code = found.Id, Chests = table.clone(found.Chests) }
end

local function article(word: string): string
	return if string.find(word, "^[AEIOUaeiou]") then `an {word}` else `a {word}`
end

local function chestWords(id: string, count: number): string
	local row = ChestRows.ById[id]
	local word = if row then row.Word else id
	local plural = if string.find(word, "[sx]$") or string.find(word, "[cs]h$") then `{word}es` else `{word}s`
	return if count == 1 then article(word) else `{count} {plural}`
end

-- Its words for a toast (research writes the final words; these stand in).
function Welcome.Said(answer: { [string]: any }): string
	if type(answer.Gift) == "number" then
		local what
		if type(answer.Shard) == "string" and answer.Shard ~= "" then
			local shard = Shards.ById[answer.Shard]
			local held = if shard then Voidkin.ById[shard.Holds] else nil
			what = `a Named shard of {if held then held.Name else "a Voidkin"}`
		else
			what = chestWords(answer.Chest, 1)
		end
		return `Welcome gift {answer.Gift} of {answer.Of}: {what}`
	end
	local parts = {}
	local ids = {}
	for id in answer.Chests or {} do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		table.insert(parts, chestWords(id, answer.Chests[id]))
	end
	return `Code accepted: {table.concat(parts, ", ")}`
end

return Welcome
