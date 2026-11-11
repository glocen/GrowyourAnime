--[[
logic_offline.luau - runs rule-math cases with Studio closed, under Lune.

	lune run tools/checks/logic_offline.luau <cases.luau or a folder of them> [default.project.json]

It reads the Rojo project file, so `game:GetService("ReplicatedStorage").Shared.Simulation.PetRule` and
`require(script.Parent.Parent.Config.X)` find the same files they find in Studio, and the game's modules load unchanged.
A cases file returns a list of { Name = "...", Run = function(t) ... end }, with the tester LogicTestService gives:
t.Equal(name, got, want) and t.Check(name, ok, detail). So a pure case can be moved between this and Studio as it is.

What runs here: modules that only do math on tables, strings and numbers, with Roblox's data types (Vector3, Color3,
UDim2, Enum and the rest of what Lune's roblox library has). What doesn't: anything that needs the engine: a service's
methods, Instance.new, a player, physics, time on the server. Such a module fails at its first engine call with the
engine's name in the error, and its case is reported as "needs Studio", never as a pass.
This never proves the engine does what a rule assumes. Cases about players, attributes, remotes and saves stay in Studio.

Exit code: 0 when every case passes, 1 when a case fails or needs Studio, 2 when the run itself broke.
Needs Lune (free, MPL-2.0): `rokit trust lune-org/lune`, then `rokit add lune-org/lune`.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local NEEDS_ENGINE = "needs the engine"

local function fail(message: string)
	print(`logic offline: {message}`)
	process.exit(2)
end

local casesPath = process.args[1]
local projectPath = process.args[2] or "default.project.json"
if not casesPath then
	fail("usage: lune run logic_offline.luau <cases.luau> [default.project.json]")
end
if not fs.isFile(projectPath) then
	fail(`no project file at {projectPath}. Run it from the project's folder, or give the path.`)
end
local projectDir = string.match(projectPath, "^(.*)[/\\][^/\\]*$") or "."

-- ---------------------------------------------------------------- the tree, from the project file and the disk

type Node = { Name: string, ClassName: string, Parent: any, Path: string?, File: string?, Source: string?, Kids: { [string]: any }?, Proxy: any }

local nodeOf = setmetatable({}, { __mode = "k" }) :: any -- proxy -> node
local loaded: { [any]: any } = {}
local requireNode
local get

local SCRIPT_SUFFIX = {
	{ ".server.luau", "Script" }, { ".client.luau", "LocalScript" }, { ".luau", "ModuleScript" },
	{ ".server.lua", "Script" }, { ".client.lua", "LocalScript" }, { ".lua", "ModuleScript" },
	{ ".json", "ModuleScript" }, { ".txt", "StringValue" },
}

local function newNode(name: string, class: string, parent: Node?): Node
	local node: Node = { Name = name, ClassName = class, Parent = parent, Proxy = nil }
	local proxy = newproxy(true)
	local meta = getmetatable(proxy)
	node.Proxy = proxy
	nodeOf[proxy] = node
	meta.__tostring = function()
		return node.Name
	end
	meta.__index = function(_, key)
		return get(node, key)
	end
	meta.__newindex = function(_, key)
		error(`{NEEDS_ENGINE}: setting {node.Name}.{tostring(key)}`, 2)
	end
	return node
end

local scan

local function kids(node: Node): { [string]: any }
	if not node.Kids then
		node.Kids = {}
	end
	return node.Kids :: any
end

-- Reads a folder's whole tree and every source once, up front: a file call can't run later inside a metamethod, where
-- Lune can't yield.
function scan(node: Node)
	local out = kids(node)
	if node.File then
		node.Source = fs.readFile(node.File)
	end
	if node.Path and fs.isDir(node.Path) then
		for _, entry in fs.readDir(node.Path) do
			local full = `{node.Path}/{entry}`
			if fs.isDir(full) then
				local class = "Folder"
				local file = nil
				for _, init in { "init.luau", "init.lua", "init.server.luau", "init.client.luau" } do
					if fs.isFile(`{full}/{init}`) then
						class = if string.find(init, "server") then "Script" elseif string.find(init, "client") then "LocalScript" else "ModuleScript"
						file = `{full}/{init}`
						break
					end
				end
				local child = newNode(entry, class, node)
				child.Path = full
				child.File = file
				out[entry] = child
				scan(child)
			elseif not string.match(entry, "^init%.") and not string.match(entry, "%.meta%.json$") then
				for _, rule in SCRIPT_SUFFIX do
					if string.sub(entry, -#rule[1]) == rule[1] then
						local name = string.sub(entry, 1, -#rule[1] - 1)
						if not out[name] then
							local child = newNode(name, rule[2], node)
							child.File = full
							child.Source = fs.readFile(full)
							out[name] = child
						end
						break
					end
				end
			end
		end
	end
end

local function path(node: Node): string
	local parts = {}
	local at: Node? = node
	while at do
		table.insert(parts, 1, at.Name)
		at = at.Parent
	end
	return table.concat(parts, ".")
end

local METHODS = {}

function METHODS.FindFirstChild(node: Node, name: string)
	local child = kids(node)[name]
	return child and child.Proxy
end

function METHODS.WaitForChild(node: Node, name: string)
	local child = kids(node)[name]
	if not child then
		error(`{path(node)} has no child "{name}" on disk, and nothing here creates one ({NEEDS_ENGINE}?)`, 3)
	end
	return child.Proxy
end

function METHODS.GetChildren(node: Node)
	local out = {}
	for _, child in kids(node) do
		table.insert(out, child.Proxy)
	end
	table.sort(out, function(a, b)
		return nodeOf[a].Name < nodeOf[b].Name
	end)
	return out
end

function METHODS.IsA(node: Node, class: string)
	return node.ClassName == class or class == "Instance" or (class == "LuaSourceContainer" and node.File ~= nil)
end

function METHODS.GetFullName(node: Node)
	return path(node)
end

function METHODS.GetService(node: Node, name: string)
	local child = kids(node)[name]
	if not child then
		child = newNode(name, name, node) -- a service the project doesn't map: it exists, and it's empty
		kids(node)[name] = child
	end
	return child.Proxy
end

function get(node: Node, key: any)
	if key == "Name" or key == "ClassName" then
		return (node :: any)[key]
	elseif key == "Parent" then
		return node.Parent and node.Parent.Proxy
	end
	local child = kids(node)[key]
	if child then
		return child.Proxy
	end
	local method = METHODS[key]
	if method and (key ~= "GetService" or node.Parent == nil) then
		return function(self, ...)
			return method(nodeOf[self] or node, ...)
		end
	end
	error(`{NEEDS_ENGINE}: {path(node)}.{tostring(key)} is not a file under the project, so it's the engine's`, 3)
end

local function build(name: string, spec: any, parent: Node?): Node
	local node = newNode(name, spec["$className"] or "Folder", parent)
	if spec["$path"] then
		local full = `{projectDir}/{spec["$path"]}`
		if fs.isFile(full) then
			node.File, node.ClassName = full, "ModuleScript"
		else
			node.Path = full
			for _, init in { "init.luau", "init.lua" } do
				if fs.isFile(`{full}/{init}`) then
					node.File, node.ClassName = `{full}/{init}`, "ModuleScript"
				end
			end
		end
	end
	scan(node)
	local out = kids(node)
	for key, value in spec do
		if type(value) == "table" and string.sub(key, 1, 1) ~= "$" then
			out[key] = build(key, value, node)
		end
	end
	return node
end

local project = serde.decode("json", fs.readFile(projectPath))
local game = build("game", project.tree, nil)
game.ClassName = "DataModel"

-- ---------------------------------------------------------------- the environment a module sees

local function engine(name: string)
	return setmetatable({}, {
		__index = function(_, key)
			error(`{NEEDS_ENGINE}: {name}.{tostring(key)}`, 2)
		end,
		__call = function()
			error(`{NEEDS_ENGINE}: {name}()`, 2)
		end,
	})
end

local base: { [string]: any } = {
	game = game.Proxy,
	workspace = engine("workspace"),
	task = task,
	warn = function(...)
		print("warn:", ...)
	end,
	tick = os.clock,
	time = os.clock,
	Instance = engine("Instance"),
}
for name, value in roblox :: any do
	if type(value) ~= "function" and name ~= "Instance" and base[name] == nil then
		base[name] = value -- Vector3, Color3, CFrame, UDim2, Enum, NumberSequence and the rest
	end
end

-- The engine's own globals that Lune doesn't have. Random is one of them on purpose: its numbers are the engine's, and a
-- case that rolls with a seed proves nothing with another generator.
for _, name in { "Random", "DateTime", "RaycastParams", "OverlapParams", "TweenInfo", "PathWaypoint", "UserSettings",
	"settings", "elapsedTime", "wait", "delay", "spawn" } do
	if base[name] == nil then
		base[name] = engine(name)
	end
end

local function environment(node: Node?): { [string]: any }
	local env = table.clone(base)
	env.script = if node then node.Proxy else engine("script") -- a cases file isn't in the tree
	env.require = function(target: any)
		local wanted = nodeOf[target]
		if not wanted then
			error(`require of {typeof(target)}: only modules under the project load here ({NEEDS_ENGINE}?)`, 2)
		end
		return requireNode(wanted)
	end
	return env
end

function requireNode(node: Node): any
	if loaded[node] ~= nil then
		return loaded[node]
	end
	if not node.File then
		error(`{path(node)} is a {node.ClassName}, not a module`, 3)
	end
	local source = node.Source :: string
	local value
	if string.sub(node.File, -5) == ".json" then
		value = serde.decode("json", source)
	else
		local chunk = luau.load(source, { debugName = node.File, environment = environment(node) })
		value = chunk()
	end
	if value == nil then
		error(`{path(node)} returned nothing`, 3)
	end
	loaded[node] = value
	return value
end

-- ---------------------------------------------------------------- the run

-- One cases file, or a folder of them: every .luau in it but its init, in name order (Grow your Anime, 2026-11-12).
local casesFiles: { string } = {}
if fs.isDir(casesPath) then
	for _, entry in fs.readDir(casesPath) do
		if string.sub(entry, -5) == ".luau" and not string.match(entry, "^init%.") then
			table.insert(casesFiles, `{casesPath}/{entry}`)
		end
	end
	table.sort(casesFiles)
	if #casesFiles == 0 then
		fail(`no cases files in {casesPath}`)
	end
elseif fs.isFile(casesPath) then
	casesFiles = { casesPath }
else
	fail(`no cases file at {casesPath}`)
end
local cases = {}
for _, file in casesFiles do
	local okLoad, list = pcall(function()
		return luau.load(fs.readFile(file), { debugName = file, environment = environment(nil) })()
	end)
	if not okLoad then
		local needs = string.find(tostring(list), NEEDS_ENGINE, 1, true) ~= nil
		fail(`{file} didn't load{if needs then ", because something it requires needs Studio" else ""}: {tostring(list)}`)
	end
	if type(list) ~= "table" then
		fail(`{file} must return a list of \{ Name, Run }`)
	end
	table.move(list, 1, #list, #cases + 1, cases)
end

local passed, failed, needStudio = 0, 0, 0
local lines = {}
local started = os.clock()
for _, case in cases do
	local function record(ok: boolean, name: string, detail: string?)
		if ok then
			passed += 1
		else
			failed += 1
			table.insert(lines, `FAIL  {case.Name} · {name}{if detail then ` ({detail})` else ""}`)
		end
	end
	local tester = {
		Check = function(name, ok, detail)
			record(ok == true, name, detail)
		end,
		Equal = function(name, got, want)
			record(got == want, name, `got {tostring(got)}, want {tostring(want)}`)
		end,
	}
	local ok, err = pcall(case.Run, tester)
	if not ok then
		if string.find(tostring(err), NEEDS_ENGINE, 1, true) then
			needStudio += 1
			table.insert(lines, `STUDIO  {case.Name} · it can't run here ({tostring(err)})`)
		else
			record(false, "errored", tostring(err))
		end
	end
end

local clean = failed == 0 and needStudio == 0
local verdict = if clean then "PASSED" else "FAILED"
print(`LOGIC OFFLINE {verdict}: {passed} passed, {failed} failed, {needStudio} need Studio ({string.format("%.2f", os.clock() - started)} s, Lune)`)
for _, line in lines do
	print(line)
end
process.exit(if clean then 0 else 1)
