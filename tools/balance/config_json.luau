--[[
config_json.luau - prints one of src/shared/Config's modules as JSON, so tools/balance reads the game's numbers as
the game does, never by pattern matching its source (a regex broke on Chests' FirstFloor line, 2026-11-25).

	lune run tools/balance/config_json.luau <Name>      (from the project folder; Name as in src/shared/Config/<Name>.luau)

Roblox's data types come from Lune's roblox library and print as plain tables: a Vector3 as { X, Y, Z }, a Color3 as
{ R, G, B }, anything else as its text. A module that requires another isn't read here (Effects, Hud, Stages): say so
plainly rather than guess. sim.config(name) in tools/balance/sim.py calls this.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox") :: any
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local name = process.args[1]
if not name or name == "" then
	stdio.ewrite("usage: lune run tools/balance/config_json.luau <Name>\n")
	process.exit(2)
end
local file = `src/shared/Config/{name}.luau`
if not fs.isFile(file) then
	stdio.ewrite(`no {file}\n`)
	process.exit(2)
end

-- Lune copies the environment's own fields (a metatable is ignored), so the data types go in one by one, as
-- tools/checks/logic_offline.luau does it.
local environment: { [string]: any } = {
	require = function()
		error(`{file} requires another module: config_json reads only self-contained configs`, 2)
	end,
}
for key, value in roblox do
	if type(value) ~= "function" and key ~= "Instance" then
		environment[key] = value -- Vector3, Color3, CFrame, UDim2, Enum and the rest
	end
end

local function plain(value: any): any
	local kind = typeof(value)
	if kind == "table" then
		local out = {}
		for k, v in value do
			out[k] = plain(v)
		end
		return out
	elseif kind == "Vector3" then
		return { X = value.X, Y = value.Y, Z = value.Z }
	elseif kind == "Vector2" then
		return { X = value.X, Y = value.Y }
	elseif kind == "Color3" then
		return { R = value.R, G = value.G, B = value.B }
	elseif kind == "number" or kind == "string" or kind == "boolean" then
		return value
	end
	return tostring(value)
end

local ok, value = pcall(function()
	return luau.load(fs.readFile(file), { debugName = file, environment = environment })()
end)
if not ok then
	stdio.ewrite(`{file} failed: {tostring(value)}\n`)
	process.exit(2)
end
print(serde.encode("json", plain(value), true))
