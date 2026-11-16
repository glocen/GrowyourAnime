--[[
kit_reid: a kit's new published ids into its template, with Studio closed (AR20; tools/studio/KitAssembly.luau).

When a kit's pictures are uploaded again or a piece's mesh is published again, and nothing else about the kit changes,
the template src/storage/<Kit>Kit.rbxm needs only its ids swapped. This reads the kit's install,
tools/studio/Kits/<Kit>.json, as HEAD has it and as it is on disk, pairs each Maps and Meshes entry whose id changed,
old to new, and puts each new id wherever the template holds the old one: a MeshPart's mesh, a SurfaceAppearance's
pictures, a Texture's or a Decal's. It prints each swap and its count, and refuses an old id the template doesn't hold,
so a rebuild that's really needed is never skipped. A kit whose pieces, sizes or manifest changed is built again in
Studio instead (KitAssembly.Build).

    lune run tools/world/kit_reid.luau Base

Run it before committing the install's new ids, from the project's folder, with the Bash sandbox off.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local kit = process.args[1]
assert(kit and kit:match("^%w+$"), "usage: lune run tools/world/kit_reid.luau <Kit>")
local installPath = `tools/studio/Kits/{kit}.json`
local templatePath = `src/storage/{kit}Kit.rbxm`

local before = process.exec("git", { "show", `HEAD:{installPath}` })
assert(before.ok, `git show HEAD:{installPath} failed: {before.stderr}`)
local old = serde.decode("json", before.stdout)
local new = serde.decode("json", fs.readFile(installPath))

local function uri(id: any): string
	return if type(id) == "number" then `rbxassetid://{string.format("%d", id)}` else tostring(id)
end

-- old uri -> new uri, from the entries whose id changed
local swaps: { [string]: string } = {}
local count = 0
for _, section in { "Maps", "Meshes" } do
	for name, id in new[section] or {} do
		local was = (old[section] or {})[name]
		if was ~= nil and uri(was) ~= uri(id) then
			local from, to = uri(was), uri(id)
			assert(swaps[from] == nil or swaps[from] == to, `{from} would become both {swaps[from]} and {to}`)
			if swaps[from] == nil then
				count += 1
			end
			swaps[from] = to
		end
	end
end
if count == 0 then
	print(`{kit}: no id changed since HEAD, nothing to swap`)
	return
end

local CONTENT = {
	"MeshContent",
	"TextureContent",
	"ColorMapContent",
	"EmissiveMaskContent",
	"NormalMapContent",
	"MetalnessMapContent",
	"RoughnessMapContent",
}

local model = roblox.deserializeModel(fs.readFile(templatePath))
local done: { [string]: number } = {}
for _, root in model do
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, item in all do
		for _, key in CONTENT do
			local ok, value = pcall(function()
				return (item :: any)[key]
			end)
			if ok and typeof(value) == "Content" and value.SourceType == roblox.Enum.ContentSourceType.Uri then
				local to = swaps[value.Uri]
				if to then
					(item :: any)[key] = roblox.Content.fromUri(to)
					done[value.Uri] = (done[value.Uri] or 0) + 1
				end
			end
		end
	end
end

local missing = {}
for from, to in swaps do
	if done[from] then
		print(`{from} -> {to}: {done[from]}`)
	else
		table.insert(missing, from)
	end
end
if #missing > 0 then
	print(`{kit}: the template holds none of {table.concat(missing, ", ")}; nothing written. Build it again in Studio.`)
	process.exit(1)
end
fs.writeFile(templatePath, roblox.serializeModel(model))
print(`{kit}: {count} ids swapped in {templatePath}`)
