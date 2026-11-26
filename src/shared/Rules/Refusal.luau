--!strict
-- Refusal (pure rules; TR71 B): what a refused press says, and how its control shakes. Every refusal's words come from
-- one table (Config.Refusals); nothing else in the game words a refusal.
--   Refusal.Words(system, code, fields?) -> string   the line for `code` in `system`, each {Field} filled from `fields`
--                                                     (numbers grouped: 1,200); a line missing a field says its Plain
--                                                     words; an unknown code, the table's Fallback. Never a raw code
--   Refusal.Of(system, answer, fields?) -> string    the same for a server's answer ({ Ok = false, Error = code } or
--                                                     { Refusal = code }); the answer's own fields fill too, `fields`
--                                                     over them
--   Refusal.Code(answer) -> string?                 a server answer's refusal code: its Error, or its Refusal
--   Refusal.Has(system, code) -> boolean             `system` has a line for `code` (the output names one that hasn't)
--   Refusal.Number(n) -> string                      a whole number grouped by thousands: 1200 -> "1,200"
--   Refusal.Shift(u, points) -> number               the shake's offset at `u` of its time (0 to 1): three swings
--                                                     that die away, 0 at both ends (the dock's, TR20)

local Refusals = require(game:GetService("ReplicatedStorage").Shared.Config.Refusals)

local Refusal = {}

function Refusal.Number(n: number): string
	local whole = math.floor(math.abs(n) + 0.5)
	local text = tostring(whole)
	local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	return if n < 0 and whole > 0 then "-" .. grouped else grouped
end

local function shown(value: any): string?
	if type(value) == "number" then
		return Refusal.Number(value)
	elseif type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

-- `words` with every {Field} filled, or nil when one isn't given.
local function fill(words: string, fields: { [string]: any }?): string?
	local missing = false
	local filled = words:gsub("{(%w+)}", function(name: string): string
		local value = if fields then shown(fields[name]) else nil
		if value == nil then
			missing = true
			return ""
		end
		return value :: string
	end)
	return if missing then nil else filled
end

function Refusal.Words(system: string, code: string?, fields: { [string]: any }?): string
	local lines = Refusals.Lines[system]
	local line = if lines and type(code) == "string" then lines[code] else nil
	if line == nil then
		return Refusals.Fallback
	elseif type(line) == "string" then
		return fill(line, fields) or Refusals.Fallback
	end
	return fill(line.Words, fields) or fill(line.Plain, fields) or Refusals.Fallback
end

function Refusal.Code(answer: { [string]: any }?): string?
	if answer == nil then
		return nil
	end
	local code = if answer.Error ~= nil then answer.Error else answer.Refusal
	return if type(code) == "string" then code else nil
end

function Refusal.Has(system: string, code: string?): boolean
	local lines = Refusals.Lines[system]
	return lines ~= nil and type(code) == "string" and lines[code] ~= nil
end

function Refusal.Of(system: string, answer: { [string]: any }?, fields: { [string]: any }?): string
	local code = Refusal.Code(answer)
	local merged: { [string]: any } = {}
	if answer then
		for key, value in answer do
			merged[key] = value
		end
	end
	if fields then
		for key, value in fields do
			merged[key] = value
		end
	end
	return Refusal.Words(system, code, merged)
end

function Refusal.Shift(u: number, points: number): number
	if not (u > 0 and u < 1) then
		return 0
	end
	return points * math.sin(2 * math.pi * 3 * u) * (1 - u)
end

return Refusal
