--!strict
-- EffectRows (shared Config): the effects whose rows are a JSON file, one child each, <Effect>.json, as the asset maker's
-- rows script writes it and tools/fx/rows_take.py takes it from the handoff, never copied into Luau by hand
-- (docs/engineering-plan.md, "The rows contract"). Rojo makes each file a module of plain tables; this decodes them once, at
-- load, and Config.Effects.Rows takes them beside its own Luau rows, so the player, a Tune and the checks see one kind of
-- effect. A file is Config.Effects' Rows type as JSON, with "Schema" and "Effect" (its name) on top: a Vector3 is
-- {"Vector3": [x, y, z]}, a Color3 {"Color3": [r, g, b]} from 0 to 255, a missing value null or left out, and "Why" (an
-- effect's or a row's) a note for the reader, dropped here.
--   EffectRows.Effects             the decoded effects, by name
--   EffectRows.Decode(raw, name)   one file's table as the game reads it
--   EffectRows.Encode(rows, name)  the reverse, for an effect written in Luau (tools/fx/rows_export.py; the round trip's case)
-- No Roblox API beyond its data types: it runs with Studio closed.

local EffectRows = {}

EffectRows.Schema = "rows/1"

-- A file's fields, and a row's, as Config.Effects names them.
EffectRows.Top = { Schema = true, Effect = true, Why = true, Area = true, Grey = true, Action = true, Free = true, World = true, Rows = true } :: { [string]: boolean }
EffectRows.Fields = {
	Kind = true, On = true, Part = true, Look = true, Grey = true, Image = true, Color = true, Range = true, Emitter = true,
	Emit = true, Tell = true, Tracks = true, Bands = true, From = true, Body = true, Ground = true, Hold = true, Turn = true, Beam = true,
	Trail = true, Low = true, High = true, Like = true, FootFade = true, Taper = true, Cue = true, Relight = true, Tint = true,
	Why = true,
} :: { [string]: boolean }

local COLOUR_PLACES = 1e4 -- a colour's 0 to 255 kept to four places: a round trip within a millionth

local function decodeValue(value: any, where: string): any
	if type(value) ~= "table" then
		return value
	end
	local vector, colour = value.Vector3, value.Color3
	if vector ~= nil or colour ~= nil then
		local list = vector or colour
		local first = next(value)
		assert(next(value, first) == nil and type(list) == "table" and #list == 3, `{where}: a Vector3 or a Color3 is one key and three numbers`)
		if vector then
			return Vector3.new(list[1], list[2], list[3])
		end
		return Color3.fromRGB(list[1], list[2], list[3])
	end
	local out = {}
	for key, inner in value do
		out[key] = decodeValue(inner, `{where}.{tostring(key)}`)
	end
	return out
end

local function encodeValue(value: any, where: string): any
	local kind = typeof(value)
	if kind == "Vector3" then
		return { Vector3 = { value.X, value.Y, value.Z } }
	elseif kind == "Color3" then
		local function byte(x: number): number
			return math.round(x * 255 * COLOUR_PLACES) / COLOUR_PLACES
		end
		return { Color3 = { byte(value.R), byte(value.G), byte(value.B) } }
	elseif kind == "table" then
		local out = {}
		for key, inner in value do
			out[key] = encodeValue(inner, `{where}.{tostring(key)}`)
		end
		return out
	elseif kind == "number" or kind == "string" or kind == "boolean" then
		return value
	end
	error(`{where}: a {kind} has no place in a rows file`)
end

function EffectRows.Decode(raw: any, name: string): any
	assert(type(raw) == "table" and raw.Schema == EffectRows.Schema, `{name}: not a rows file ({EffectRows.Schema})`)
	assert(raw.Effect == name, `{name}: its Effect is "{tostring(raw.Effect)}", not its file's name`)
	for key in raw do
		assert(EffectRows.Top[key], `{name}: no field "{tostring(key)}" in a rows file`)
	end
	assert(type(raw.Area) == "number" and raw.Area > 0, `{name}: its Area`)
	local rows = {}
	for rowName, row in raw.Rows or {} do
		local out = {}
		for key, value in row do
			assert(EffectRows.Fields[key], `{name}.{rowName}: no field "{tostring(key)}" in a row`)
			if key ~= "Why" then
				out[key] = decodeValue(value, `{name}.{rowName}.{key}`)
			end
		end
		out.Tracks = out.Tracks or {}
		rows[rowName] = out
	end
	return { Area = raw.Area, Grey = raw.Grey == true, Action = raw.Action, Free = raw.Free, World = if raw.World == true then true else nil, Rows = rows }
end

function EffectRows.Encode(effect: any, name: string): any
	local rows = {}
	for rowName, row in effect.Rows do
		rows[rowName] = encodeValue(row, `{name}.{rowName}`)
	end
	return {
		Schema = EffectRows.Schema,
		Effect = name,
		Area = effect.Area,
		Grey = effect.Grey,
		Action = effect.Action,
		Free = effect.Free,
		World = effect.World,
		Rows = rows,
	}
end

EffectRows.Effects = {} :: { [string]: any }
for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		EffectRows.Effects[child.Name] = EffectRows.Decode(require(child :: ModuleScript) :: any, child.Name)
	end
end

return EffectRows
