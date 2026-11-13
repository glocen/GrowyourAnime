--!strict
-- Tune: changes a value in Config, or in a root you add, while a Studio playtest runs, so a feel is tried by playing, not by
-- edit-and-restart. A path names a module under Shared.Config and the keys inside it, as "Movement.Dodge.Duration", or a root
-- the game adds to Tune.Roots, which Definitions needs. Code that reads them when
-- it runs sees the new value at once; a value a module copied when it loaded (a file-level `local X = Config.Y`) needs a restart.
-- TuneService applies a change on the server and every client; it lasts until the playtest ends.

local ConfigFolder = script.Parent.Parent.Config

local Tune = {}

-- Seam: other tables a path may start with. Roots.Action = function(keys) return node, firstKeyIndex end
Tune.Roots = {} :: { [string]: (keys: { string }) -> (any, number) }

-- A key in a list (Config.Combat.Hitstop.Rungs) is its number: "Combat.Hitstop.Rungs.1.Hold".
local function key(node: any, name: string): any
	local index = tonumber(name)
	return if node[name] == nil and index ~= nil and node[index] ~= nil then index else name
end

local function locate(path: string): ({ [any]: any }, any)
	local keys = string.split(path, ".")
	if keys[1] == "Config" then
		table.remove(keys, 1)
	end
	assert(#keys >= 2, `"{path}" needs a Config module and a key`)
	local node: any
	local first = 2
	local root = Tune.Roots[keys[1]]
	if root then
		node, first = root(keys)
	else
		local module = ConfigFolder:FindFirstChild(keys[1])
		assert(module and module:IsA("ModuleScript"), `no Config module "{keys[1]}"`)
		node = (require :: any)(module) -- found by name at run time, so the checker can't follow it
	end
	assert(node, `"{path}" names no {keys[1]}`)
	for index = first, #keys - 1 do
		node = node[key(node, keys[index])]
		assert(type(node) == "table", `"{path}": {keys[index]} isn't a table`)
	end
	return node, key(node, keys[#keys])
end

function Tune.Read(path: string): any
	local node, key = locate(path)
	return node[key]
end

-- Sets the value and returns the old one. It keeps its type, so a typo can't turn a number into a string.
function Tune.Apply(path: string, value: any): any
	local node, key = locate(path)
	local old = node[key]
	assert(old ~= nil, `"{path}" doesn't exist`)
	assert(typeof(old) == typeof(value), `"{path}" is a {typeof(old)}, not a {typeof(value)}`)
	node[key] = value
	return old
end

return Tune
