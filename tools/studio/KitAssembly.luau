--!strict
-- KitAssembly: a world kit's pieces as one template (TR8; docs/asset-requests.md, AR5, section 2, "For the builder"), the
-- Studio half of tools/world. Runs in Edit mode from MCP execute_luau (plugin context), never in a game:
--   py tools/upload/stage_kit.py LanternRow    -- each piece's mesh to build/import/LanternRow_<Piece>.txt (NL_Import)
--   local Kit = require(game.ServerStorage.NL_Tools.KitAssembly:Clone())
--   Assembly.Start("kit", function() return Kit.Publish("LanternRow") end)  -- each piece with no id yet; the ids go into
--                                                                            -- its install, tools/studio/Kits/LanternRow.json
--   local template = Kit.Build("LanternRow")
-- then Assembly.Serialize(template) into src/storage/LanternRowKit.rbxm (ServerStorage.Templates.LanternRowKit), which
-- WorldService lays where the kit's plan says (Config.Kits.LanternRow, Shared.World.Kit).
-- The kit's two files are taken into the game as they are (tools/world/kit_take.py): the manifest says each piece's mesh,
-- maps and glow; the install is the builder's half: the published ids (Meshes, Maps), which pieces collide and how
-- (Collide: a CollisionFidelity's name; any other piece is look only), which cast no shadow (NoShadow: the manifest's
-- "shadows"), and the paving tile the street's own floor wears (Paving). A template piece stands at the origin: its
-- place is the plan's, its offset the manifest's centre.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assembly = require(ServerStorage:WaitForChild("NL_Tools"):WaitForChild("ModelAssembly"):Clone()) :: any

local KitAssembly = {}

local function files(kit: string): (any, any, any)
	local home = (ReplicatedStorage.Shared.Config :: any).Kits[kit]
	local manifest = require(home.Manifest:Clone()) :: any
	local installs = ServerStorage:WaitForChild("NL_Tools"):WaitForChild("Kits")
	local install = installs:FindFirstChild(kit)
	assert(install and install:IsA("ModuleScript"), `No install {kit} (tools/studio/Kits/{kit}.json)`)
	return manifest, require(install:Clone()) :: any, require(home.Plan:Clone()) :: any
end

-- A map's published id by its file's name ("maps/LanternRow_Kit_Color.png" -> the install's Maps entry).
local function map(install: any, path: string): string
	local name = string.match(path, "[^/]+$") :: string
	local id = install.Maps[name]
	assert(type(id) == "string" and string.match(id, "^rbxassetid://%d+$"), `{name}: no published id in the install's Maps`)
	return id
end

-- Publishes each piece the install has no id for, as a Mesh under the place's creator; returns the new ids by piece,
-- for the install's Meshes. Yields for seconds a piece: run it as a job (Assembly.Start).
function KitAssembly.Publish(kit: string): { [string]: number }
	local manifest, install = files(kit)
	local out: { [string]: number } = {}
	for name in manifest.pieces do
		if install.Meshes[name] == nil then
			local asset = `{kit}_{name}`
			out[name] = Assembly.PublishMesh(asset, asset, `Grow your Anime: a piece of the {kit} kit, {name}.`)
		end
	end
	return out
end

-- A ParticleEmitter from a plan's emitter (the plan's paper): each property by its own type, a NumberSequence as
-- [time, value] or [time, value, envelope], a NumberRange as [min, max], a colour as hex, an enum by its item's name.
local function emitter(spec: { [string]: any }, texture: string): ParticleEmitter
	local made = Instance.new("ParticleEmitter")
	local props = made :: any
	for key, value in spec do
		local current = props[key]
		local kind = typeof(current)
		local set: any
		if key == "Texture" then
			set = texture
		elseif kind == "EnumItem" then
			set = ((current :: EnumItem).EnumType :: any)[value]
		elseif kind == "NumberRange" then
			set = NumberRange.new(value[1], value[2])
		elseif kind == "NumberSequence" then
			local points = {}
			for _, row in value do
				table.insert(points, NumberSequenceKeypoint.new(row[1], row[2], row[3] or 0))
			end
			set = NumberSequence.new(points)
		elseif kind == "ColorSequence" then
			set = ColorSequence.new(Color3.fromHex(value))
		elseif kind == "Vector2" then
			set = Vector2.new(value[1], value[2])
		elseif kind == "Vector3" then
			set = Vector3.new(value[1], value[2], value[3])
		else
			set = value
		end
		assert(set ~= nil, `the emitter's {key}: no {tostring(value)}`)
		props[key] = set
	end
	made.Enabled = true
	return made
end

-- The kit as a Model named <Kit>Kit: one MeshPart a piece, anchored, with its look (one SurfaceAppearance: the colour,
-- the glow's mask, tint and strength), its shadow and its collision; the paving as a Texture, Paving; and the plan's
-- drifting paper, when it has one, as a ParticleEmitter, Paper, which the game clones into each of its boxes.
function KitAssembly.Build(kit: string): Model
	local manifest, install, plan = files(kit)
	local model = Instance.new("Model")
	model.Name = `{kit}Kit`
	local noShadow: { [string]: boolean } = {}
	for _, name in install.NoShadow or {} do
		noShadow[name] = true
	end
	for name, piece in manifest.pieces do
		local id = install.Meshes[name]
		assert(type(id) == "number", `{name}: no published mesh in the install's Meshes (KitAssembly.Publish)`)
		local collide = (install.Collide or {})[name]
		local fidelity = if collide then (Enum.CollisionFidelity :: any)[collide] else nil
		assert(collide == nil or fidelity ~= nil, `{name}: no CollisionFidelity "{collide}"`)
		local part = Assembly.Mesh(id, fidelity)
		part.Name = name
		part.Anchored = true
		part.CanCollide = fidelity ~= nil
		part.CanQuery = fidelity ~= nil
		part.CanTouch = false
		part.CastShadow = not noShadow[name]
		part.CFrame = CFrame.identity
		local look = Instance.new("SurfaceAppearance")
		look.ColorMapContent = Content.fromUri(map(install, piece.colour))
		if piece.glow then
			look.EmissiveMaskContent = Content.fromUri(map(install, piece.glow))
			look.EmissiveTint = Color3.fromHex(piece.glowTint or "#FFFFFF")
			look.EmissiveStrength = piece.glowStrength or 1
		end
		look.Parent = part
		part.Parent = model
	end
	if install.Paving then
		local paving = Instance.new("Texture")
		paving.Name = "Paving"
		paving.Face = Enum.NormalId.Top
		paving.Texture = map(install, install.Paving.Map)
		paving.StudsPerTileU = install.Paving.Tile
		paving.StudsPerTileV = install.Paving.Tile
		paving.Parent = model
	end
	if plan.paper then
		local paper = emitter(plan.paper.emitter, map(install, plan.paper.picture))
		paper.Name = "Paper"
		paper.Parent = model
	end
	return model
end

return KitAssembly
