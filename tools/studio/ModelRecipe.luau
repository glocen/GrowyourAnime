--!strict
-- ModelRecipe: one assembler for every model the asset maker hands off as a recipe (docs/engineering-plan.md, "Content at
-- scale", item 2), in place of a script per model. Pure: it calls no service, so tools/checks/models_offline.luau runs it
-- with Studio closed against the templates that ship, and Studio runs it through ModelAssembly.Build(name).
--   ModelRecipe.Build(recipe, install, host) -> Model
--     recipe   build/handoff/<Name>/<Name>.recipe.json, as the asset maker's model script writes it: its pieces, each on
--              a rig part or a piece before it (with "motor" and "pivot" on a joint of its own, the clips' to key, else
--              welded; "edge" a shell that casts no shadow), its points, and its glow ("emissive")
--     install  tools/studio/Models/<Name>.json, the builder's half: the published ids (Meshes, Maps), and what the recipe
--              leaves to the builder (NoShadow, GlowNames, Points, Lights, Humanoid; the header of Build)
--     host     Roblox's plain R6, cleaned and standing with its root at (0, 3, 0), and a MeshPart of a published mesh:
--              Studio's (ModelAssembly), or bare ones offline
--   ModelRecipe.Held(models) -> { [part]: string }: each part on a joint of its own and the part its Pose nests under,
--     read from the models' Motor6Ds (tools/studio/Animations/Author's HELD)
--   ModelRecipe.Place, .Weld, .Attach: the steps ModelAssembly shares with the models still built by hand
-- The recipe's frame: Roblox studs, Y up, the model on y = 0 facing -Z, its HumanoidRootPart at (0, 3, 0). A joint's frame
-- is its pivot with the model's axes at rest.

export type Host = {
	Rig: () -> Model,
	Mesh: (meshId: number) -> MeshPart,
}

type Glow = { Tint: Color3, Strength: number, Name: string? }

local ModelRecipe = {}

-- R6's own parts: a Motor6D whose Part1 is one of them is the rig's joint, never a held part's.
ModelRecipe.Rig = {
	HumanoidRootPart = true,
	Torso = true,
	Head = true,
	["Right Arm"] = true,
	["Left Arm"] = true,
	["Right Leg"] = true,
	["Left Leg"] = true,
} :: { [string]: boolean }

local function vector(list: any, where: string): Vector3
	assert(type(list) == "table" and #list == 3, `{where}: three numbers`)
	return Vector3.new(list[1], list[2], list[3])
end

local function hex(text: string): Color3
	return Color3.fromHex((string.gsub(text, "^#", "")))
end

-- A mesh made a held or worn prop at a model-space position: no physics, no queries.
function ModelRecipe.Place(part: MeshPart, model: Model, name: string, position: Vector3, props: { [string]: any }?): MeshPart
	part.Name = name
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, false, true
	part.CFrame = CFrame.new(position)
	for key, value in props or {} do
		(part :: any)[key] = value
	end
	part.Parent = model
	return part
end

-- Holds `part` to `to` where it stands now: a Weld with an explicit C0 (WeldConstraints in a cloned model don't hold
-- under Server Authority).
function ModelRecipe.Weld(to: BasePart, part: BasePart): Weld
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = to, part
	weld.C0 = to.CFrame:ToObjectSpace(part.CFrame)
	weld.Parent = part
	return weld
end

-- An Attachment on `part` at a model-space position.
function ModelRecipe.Attach(part: BasePart, name: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = CFrame.new(part.CFrame:PointToObjectSpace(position))
	attachment.Parent = part
	return attachment
end

-- The recipe's glow, by piece: one glow ("emissive" with its pieces, its tint, and cold, its strength at rest), or one per
-- group (each with its pieces, its tint, and its strength or cold), named by the install's GlowNames for the code that
-- sets it (the attribute Glow). A group without a tint takes none (the Lamplighter's pole).
local function glows(recipe: any, install: any): { [string]: Glow }
	local out: { [string]: Glow } = {}
	local emissive = recipe.emissive
	if type(emissive) ~= "table" then
		return out
	end
	local function take(spec: any, name: string?)
		if type(spec) ~= "table" or type(spec.pieces) ~= "table" or type(spec.tint) ~= "string" then
			return
		end
		local strength = spec.strength or spec.cold
		assert(type(strength) == "number", `{recipe.name}: a glow with a tint has a strength or a cold`)
		for _, piece in spec.pieces do
			out[piece] = { Tint = hex(spec.tint), Strength = strength, Name = name }
		end
	end
	if emissive.pieces then
		take(emissive, nil)
	else
		local names = install.GlowNames or {}
		for key, spec in emissive do
			take(spec, names[key])
		end
	end
	return out
end

-- The model, from its recipe and its install. The install's fields:
--   Meshes     each piece's published mesh id, by piece
--   Maps       the surface's published maps: Color, Roughness, Metalness, and Emissive when anything glows
--   NoShadow   pieces that cast no shadow (a hat's brim over a face, a lamp)
--   GlowNames  the attribute Glow each of the recipe's glow groups carries, by group
--   Points     the builder's own points, as the recipe writes its points
--   Lights     PointLights, each on a point of a piece: { Part, Point, Name, Color (hex), Brightness, Range }
--   Humanoid   the humanoid's settings, an enum's item by name: { DisplayDistanceType = "None" }
function ModelRecipe.Build(recipe: any, install: any, host: Host): Model
	local name = recipe.name
	assert(type(name) == "string" and type(recipe.pieces) == "table", "not a model recipe: no name, or no pieces")
	local maps = install.Maps
	assert(type(maps) == "table" and type(maps.Color) == "string", `{name}: its install names no maps`)
	local model = host.Rig()
	model.Name = name
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = 1 -- the pieces carry the body's surface
		end
	end
	local parts: { [string]: BasePart } = {}
	local function on(partName: any, where: string): BasePart
		local found = if type(partName) == "string" then parts[partName] or model:FindFirstChild(partName) else nil
		assert(found and found:IsA("BasePart"), `{where}: on "{tostring(partName)}", which is neither R6's part nor a piece made before it`)
		return found
	end
	local glow = glows(recipe, install)
	local shadowless: { [string]: boolean } = {}
	for _, piece in install.NoShadow or {} do
		shadowless[piece] = true
	end
	for _, piece in recipe.pieces do
		local pieceName = piece.name
		assert(type(pieceName) == "string", `{name}: a piece without a name`)
		assert(type(piece.on) == "string", `{pieceName}: on no part (a recipe of an older form: ask the asset maker for it again)`)
		local meshId = install.Meshes and install.Meshes[pieceName]
		assert(type(meshId) == "number", `{pieceName}: no published mesh in {name}'s install`)
		local props = if piece.edge or shadowless[pieceName] then { CastShadow = false } else nil
		local part = ModelRecipe.Place(host.Mesh(meshId), model, pieceName, vector(piece.centre, pieceName), props)
		local look = Instance.new("SurfaceAppearance")
		look.ColorMapContent = Content.fromUri(maps.Color)
		if maps.Roughness then
			look.RoughnessMapContent = Content.fromUri(maps.Roughness)
		end
		if maps.Metalness then
			look.MetalnessMapContent = Content.fromUri(maps.Metalness)
		end
		local lit = glow[pieceName]
		if lit then
			assert(type(maps.Emissive) == "string", `{pieceName} glows, and {name}'s install has no Emissive map`)
			look.EmissiveMaskContent = Content.fromUri(maps.Emissive)
			look.EmissiveStrength = lit.Strength
			look.EmissiveTint = lit.Tint
			if lit.Name then
				look:SetAttribute("Glow", lit.Name)
			end
		end
		look.Parent = part
		local to = on(piece.on, pieceName)
		if piece.motor then
			local pivot = CFrame.new(vector(piece.pivot, pieceName))
			local motor = Instance.new("Motor6D")
			motor.Name = piece.motor
			motor.Part0, motor.Part1 = to, part
			motor.C0 = to.CFrame:ToObjectSpace(pivot)
			motor.C1 = part.CFrame:ToObjectSpace(pivot)
			motor.Parent = to
		else
			ModelRecipe.Weld(to, part)
		end
		parts[pieceName] = part
	end
	for _, list in { recipe.points or {}, install.Points or {} } do
		for _, point in list do
			ModelRecipe.Attach(on(point.on, point.name), point.name, vector(point.at, point.name))
		end
	end
	for _, light in install.Lights or {} do
		local holder = on(light.Part, `{name}'s light`)
		local at = holder:FindFirstChild(light.Point)
		assert(at and at:IsA("Attachment"), `{name}'s light: no point "{tostring(light.Point)}" on {light.Part}`)
		local made = Instance.new("PointLight")
		made.Name = light.Name or "Light"
		made.Color = hex(light.Color)
		made.Brightness = light.Brightness
		made.Range = light.Range
		made.Shadows = false
		made.Parent = at
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	for property, item in install.Humanoid or {} do
		assert(humanoid, `{name}: no Humanoid to set`);
		(humanoid :: any)[property] = (Enum :: any)[`Humanoid{property}`][item]
	end
	local root = on("HumanoidRootPart", name)
	model.PrimaryPart = root
	model.WorldPivot = root.CFrame
	return model
end

-- Each part the models carry on a joint of their own, and the part it turns on: a clip's Pose for it nests under that
-- part's (Author's HELD). A Motor6D with no Part0 is an error, never skipped: a synced .rbxm can drop a new part's.
function ModelRecipe.Held(models: { Instance }): { [string]: string }
	local held: { [string]: string } = {}
	for _, model in models do
		for _, joint in model:GetDescendants() do
			if not joint:IsA("Motor6D") then
				continue
			end
			local part0, part1 = joint.Part0, joint.Part1
			if part1 == nil or ModelRecipe.Rig[part1.Name] then
				continue
			end
			assert(part0, `{model.Name}.{joint.Name}: its Part0 is gone`)
			local was = held[part1.Name]
			assert(was == nil or was == part0.Name, `{part1.Name} turns on {was} in one model and {part0.Name} in another`)
			held[part1.Name] = part0.Name
		end
	end
	return held
end

return ModelRecipe
