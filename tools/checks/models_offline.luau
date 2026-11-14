--[[
models_offline.luau - builds every model that has an install (tools/studio/Models/<Name>.json) from its recipe
(build/handoff/<Name>/<Name>.recipe.json) through tools/studio/ModelRecipe.luau, with Studio closed, under Lune:

	lune run tools/checks/models_offline.luau [Name ...]
	lune run tools/checks/models_offline.luau --recipe <Name> [recipe.json]

Each model is checked against the template that ships (src/storage/<Name>.rbxm), instance by instance: every part,
joint, weld, point, look, light and the humanoid's settings, where they stand from the model's root and what they hold.
A mesh's own id and size are Studio's (AssetService), never read here. The held parts the clips nest (ModelRecipe.Held, Author's HELD) are read
from the built models and from the templates, and must agree.
--recipe builds one recipe before its meshes are published, on stand-in ids, and checks only that it builds: every piece
on its part or joint, every point on its part (a new delivery, before the install; from another file, one not yet handed
off).
The rig offline is the plain R6 a template stands on, with nothing of its own left on it: Roblox's own parts, joints
and attachments, as ModelAssembly's R6() makes it in Studio.
Exit code: 0 when everything agrees, 1 when something differs, 2 when the run itself broke.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance = roblox.Instance

local R6_JOINTS = { Neck = true, ["Left Hip"] = true, ["Right Hip"] = true, ["Left Shoulder"] = true, ["Right Shoulder"] = true, RootJoint = true }
local R6_POINTS = {
	FaceCenterAttachment = true, FaceFrontAttachment = true, HatAttachment = true, HairAttachment = true,
	WaistBackAttachment = true, WaistCenterAttachment = true, WaistFrontAttachment = true, RightCollarAttachment = true,
	LeftCollarAttachment = true, BodyBackAttachment = true, BodyFrontAttachment = true, NeckAttachment = true,
	LeftGripAttachment = true, LeftShoulderAttachment = true, RightGripAttachment = true, RightShoulderAttachment = true,
	LeftFootAttachment = true, RightFootAttachment = true, RootAttachment = true,
}
local CLOSE = 1e-4 -- a stud or a CFrame's component: the .rbxm keeps single precision

local function fail(message: string)
	print(`MODELS OFFLINE BROKE: {message}`)
	process.exit(2)
end

-- ModelRecipe as Studio loads it: the engine's types as globals.
local env: { [string]: any } = { Instance = Instance, Enum = roblox.Enum }
for _, name in { "Vector3", "CFrame", "Color3", "Content" } do
	env[name] = (roblox :: any)[name]
end
setmetatable(env, { __index = _G })
local ModelRecipe = luau.load(fs.readFile("tools/studio/ModelRecipe.luau"), { debugName = "ModelRecipe", environment = env })()

local function template(name: string): any?
	local path = `src/storage/{name}.rbxm`
	return if fs.isFile(path) then roblox.deserializeModel(fs.readFile(path))[1] else nil
end

-- The plain R6, from a template that stands on it: Roblox's own parts, joints and attachments, and its humanoid.
local rigSource = template("Rook") or fail("src/storage/Rook.rbxm, the rig's source, is missing")
local function plainR6(): any
	local model = rigSource:Clone() -- whole, so its joints keep their parts
	for _, child in model:GetChildren() do
		if not ((child:IsA("BasePart") and ModelRecipe.Rig[child.Name]) or child:IsA("Humanoid")) then
			child:Destroy()
		end
	end
	for _, item in model:GetDescendants() do
		local own = (item:IsA("Motor6D") and R6_JOINTS[item.Name]) or (item:IsA("Attachment") and R6_POINTS[item.Name])
			or item:IsA("Animator") or item:IsA("BasePart") or item:IsA("Humanoid")
		if not own and item.Parent ~= nil then
			item:Destroy()
		end
	end
	model.Name = "R6"
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	return model
end

local host = {
	Rig = plainR6,
	Mesh = function(_meshId: number): any
		return Instance.new("MeshPart")
	end,
}

-- ---------------------------------------------------------------- reading an instance as text

-- A property as text; a part's place and the model's pivot from the model's root, so a template saved where it was
-- moved to reads the same as one at the origin. A pivot is stored as WorldPivotData.
local function read(item: any, property: string, root: any): string
	local ok, value = pcall(function()
		return item[property]
	end)
	if not ok and property == "WorldPivot" then
		ok, value = pcall(function()
			return item.WorldPivotData
		end)
	end
	if not ok then
		return "?"
	end
	local kind = typeof(value)
	if kind == "CFrame" and root and (property == "WorldPivot" or (property == "CFrame" and item:IsA("BasePart"))) then
		value = root.CFrame:ToObjectSpace(value)
	end
	if kind == "CFrame" then
		local parts = { value:GetComponents() }
		for index, number in parts do
			parts[index] = string.format("%.4f", number)
		end
		return table.concat(parts, " ")
	elseif kind == "Vector3" then
		return string.format("%.4f %.4f %.4f", value.X, value.Y, value.Z)
	elseif kind == "Color3" then
		return string.format("%d %d %d", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
	elseif kind == "number" then
		return string.format("%.4f", value)
	elseif kind == "Instance" then
		return value.Name
	end
	return tostring(value)
end

local PROPERTIES: { [string]: { string } } = {
	Part = { "CFrame", "Transparency", "CastShadow", "Anchored", "CanCollide", "CanQuery", "CanTouch", "Massless" },
	MeshPart = { "CFrame", "Transparency", "CastShadow", "Anchored", "CanCollide", "CanQuery", "CanTouch", "Massless" },
	Weld = { "Part0", "Part1", "C0", "C1" },
	Motor6D = { "Part0", "Part1", "C0", "C1" },
	Attachment = { "CFrame" },
	SurfaceAppearance = { "ColorMapContent", "RoughnessMapContent", "MetalnessMapContent", "EmissiveMaskContent", "EmissiveStrength", "EmissiveTint" },
	PointLight = { "Color", "Brightness", "Range", "Shadows" },
	Humanoid = { "DisplayDistanceType", "HealthDisplayType" },
	Model = { "PrimaryPart", "WorldPivot" },
}

-- Every instance by its path, as lines of its class and properties.
local function describe(model: any): { [string]: { [string]: string } }
	local out: { [string]: { [string]: string } } = {}
	local root = model:FindFirstChild("HumanoidRootPart")
	local function add(item: any, path: string)
		local key, n = path, 1
		while out[key] do
			n += 1
			key = `{path}#{n}`
		end
		local fields: { [string]: string } = { Class = item.ClassName }
		for _, property in PROPERTIES[item.ClassName] or {} do
			fields[property] = read(item, property, root)
		end
		local glow = item:GetAttribute("Glow")
		if glow ~= nil then
			fields.Glow = tostring(glow)
		end
		out[key] = fields
		for _, child in item:GetChildren() do
			add(child, `{key}.{child.Name}`)
		end
	end
	add(model, model.Name)
	return out
end

local function near(a: string, b: string): boolean
	if a == b then
		return true
	end
	local x, y = string.split(a, " "), string.split(b, " ")
	if #x ~= #y then
		return false
	end
	for index = 1, #x do
		local p, q = tonumber(x[index]), tonumber(y[index])
		if p == nil or q == nil or math.abs(p - q) > CLOSE * math.max(1, math.abs(q)) then
			return false
		end
	end
	return true
end

local function compare(built: any, shipped: any): { string }
	local a, b = describe(built), describe(shipped)
	local lines: { string } = {}
	for path, fields in a do
		local other = b[path]
		if other == nil then
			table.insert(lines, `only built: {path} ({fields.Class})`)
			continue
		end
		for key, value in fields do
			if not near(value, other[key] or "nil") then
				table.insert(lines, `{path}.{key}: built {value}, ships {other[key] or "nil"}`)
			end
		end
		for key, value in other do
			if fields[key] == nil then
				table.insert(lines, `{path}.{key}: ships {value}, built none`)
			end
		end
	end
	for path, fields in b do
		if a[path] == nil then
			table.insert(lines, `only shipped: {path} ({fields.Class})`)
		end
	end
	table.sort(lines)
	return lines
end

-- What every built model must be, template or none: each piece held to the body, each point on its part.
local function structure(model: any, recipe: any): { string }
	local lines: { string } = {}
	for _, piece in recipe.pieces do
		local part = model:FindFirstChild(piece.name)
		local held = false
		for _, joint in model:GetDescendants() do
			if (joint:IsA("Weld") or joint:IsA("Motor6D")) and joint.Part1 == part and joint.Part0 ~= nil then
				held = true
			end
		end
		if part == nil or not held then
			table.insert(lines, `{piece.name}: not held to the body`)
		end
	end
	for _, point in recipe.points or {} do
		local on = model:FindFirstChild(point.on)
		if on == nil or on:FindFirstChild(point.name) == nil then
			table.insert(lines, `{point.name}: not on {point.on}`)
		end
	end
	return lines
end

local function readJson(path: string): any
	if not fs.isFile(path) then
		fail(`{path} is missing`)
	end
	return serde.decode("json", fs.readFile(path))
end

-- ---------------------------------------------------------------- the run

local args = process.args
local recipeOnly = args[1] == "--recipe"
local names: { string } = {}
if recipeOnly then
	names = { args[2] or fail("--recipe needs a name") }
elseif #args > 0 then
	names = table.clone(args)
else
	for _, file in fs.readDir("tools/studio/Models") do
		local name = string.match(file, "^(.+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
end

local bad = 0
local built: { any } = {}
local shipped: { any } = {}
for _, name in names do
	local recipe = readJson(if recipeOnly and args[3] then args[3] else `build/handoff/{name}/{name}.recipe.json`)
	local install
	if recipeOnly then
		install = { Meshes = {}, Maps = { Color = "rbxassetid://0", Roughness = "rbxassetid://0", Metalness = "rbxassetid://0", Emissive = "rbxassetid://0" } }
		for _, piece in recipe.pieces do
			install.Meshes[piece.name] = 0
		end
	else
		install = readJson(`tools/studio/Models/{name}.json`)
	end
	local ok, model = pcall(ModelRecipe.Build, recipe, install, host)
	if not ok then
		bad += 1
		print(`FAIL  {name}: it doesn't build: {tostring(model)}`)
		continue
	end
	table.insert(built, model)
	local lines = structure(model, recipe)
	local against = if recipeOnly then nil else template(name)
	if against then
		table.insert(shipped, against)
		for _, line in compare(model, against) do
			table.insert(lines, line)
		end
	end
	if #lines > 0 then
		bad += 1
		print(`FAIL  {name}: {#lines} differences`)
		for _, line in lines do
			print(`      {line}`)
		end
	else
		print(`ok    {name}: {#recipe.pieces} pieces{if against then ", the same as the template that ships" else ", built from its recipe alone"}`)
	end
end

local function heldLines(models: { any }): { [string]: string }
	local okHeld, held = pcall(ModelRecipe.Held, models)
	if not okHeld then
		bad += 1
		print(`FAIL  the held parts: {tostring(held)}`)
		return {}
	end
	return held
end
local fromBuilt = heldLines(built)
local keys: { string } = {}
for part in fromBuilt do
	table.insert(keys, part)
end
table.sort(keys)
local listed: { string } = {}
for _, part in keys do
	table.insert(listed, `{part} on {fromBuilt[part]}`)
end
print(`held: {table.concat(listed, ", ")}`)
if #shipped > 0 then
	local fromShipped = heldLines(shipped)
	for part, parent in fromBuilt do
		if fromShipped[part] ~= parent then
			bad += 1
			print(`FAIL  held: {part} on {parent} built, on {tostring(fromShipped[part])} in the template`)
		end
	end
end

print(`MODELS OFFLINE {if bad == 0 then "PASS" else "FAIL"}: {#names} models, {bad} with differences`)
process.exit(if bad == 0 then 0 else 1)
