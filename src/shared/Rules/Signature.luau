--!strict
-- Signature (shared, pure): a Voidkin's signature levels, 1 to 5 (docs/design.md, "Voidkin", "Growing a Voidkin"; TR76).
-- Each level is paid with Skill Manuals (the bag's Tokens.Manual) and Credits, by hand, in one step: the check and both
-- spends together, so a repeated or cut request never spends twice or raises without paying (the save's one door runs it
-- in a transaction, and its op id makes a repeat answer the first one's result). Each level is a better row for the
-- signature's hits (Config.Signature.Rows), never a multiplier.
--   Signature.Level(owned) -> number                          its level, 1 to the last
--   Signature.Cost(owned) -> { Manuals, Credits }?            what the next level costs; nil at the last
--   Signature.Raise(data, id) -> { Ok, Id, Level, Manuals, Credits } | { Ok = false, Error, Need? }   Need: what's short
--   Signature.Coefficient(action, beat, level, own) -> number  a hit's Coefficient at that level; `own` without a row
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local SignatureConfig = require(Shared.Config.Signature)
local Profile = require(Shared.Data.Profile)

local Signature = {}

Signature.Unknown = "Unknown" -- no such Voidkin in the save
Signature.MaxLevel = "MaxLevel" -- already at the last level
Signature.NoManuals = "NoManuals" -- not enough Skill Manuals
Signature.NoCredits = "NoCredits" -- not enough Credits

Signature.Token = "Manual" -- its bag item (Definitions.Tokens)

function Signature.Level(owned: Profile.OwnedVoidkin): number
	local level = owned.Signature
	if type(level) ~= "number" or level ~= level then
		return 1
	end
	return math.clamp(math.floor(level), 1, SignatureConfig.MaxLevel)
end

function Signature.Cost(owned: Profile.OwnedVoidkin): { Manuals: number, Credits: number }?
	local level = Signature.Level(owned)
	if level >= SignatureConfig.MaxLevel then
		return nil
	end
	return SignatureConfig.Cost[level + 1]
end

function Signature.Raise(data: Profile.Data, id: any): { [string]: any }
	local owned = if type(id) == "string" then data.Voidkin[id] else nil
	if owned == nil then
		return { Ok = false, Error = Signature.Unknown }
	end
	local cost = Signature.Cost(owned)
	if cost == nil then
		return { Ok = false, Error = Signature.MaxLevel }
	end
	local tokens = data.Bag.Tokens
	local manuals = tokens[Signature.Token] or 0
	if manuals < cost.Manuals then
		return { Ok = false, Error = Signature.NoManuals, Need = cost.Manuals - manuals }
	end
	if data.Currency.Credits < cost.Credits then
		return { Ok = false, Error = Signature.NoCredits, Need = cost.Credits - data.Currency.Credits }
	end
	tokens[Signature.Token] = if manuals - cost.Manuals > 0 then manuals - cost.Manuals else nil
	data.Currency.Credits -= cost.Credits
	owned.Signature = Signature.Level(owned) + 1
	return { Ok = true, Id = owned.Id, Level = owned.Signature, Manuals = cost.Manuals, Credits = cost.Credits }
end

function Signature.Coefficient(action: string, beat: string, level: number, own: number): number
	local rows = SignatureConfig.Rows[action]
	local row = if rows then rows[beat] else nil
	if row == nil then
		return own
	end
	return row[math.clamp(math.floor(level), 1, #row)] or own
end

return Signature
