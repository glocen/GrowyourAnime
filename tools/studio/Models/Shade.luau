--!strict
-- The Shade (AR2): one R6 rig for every Shade, from build/handoff/Shade/Shade.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Shade:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Shade.rbxm (ServerStorage.Templates.Shade), which FightService clones.
-- The meshes need build/import/Shade_<Piece>.txt (copied from the handoff) for their centres.
-- The rig is Roblox's plain R6 with its six parts hidden: the body's five pieces are welded on their parts and the four
-- masks on the Head, each named Mask_<Role>; an elite's second mask, EliteMask_<Role>, on the Left Arm (AR2, section 5).
-- A spawn keeps its row's masks and drops the others, and tints the body's lit edges with its type (Config.Shades): a
-- script may set EmissiveTint and EmissiveStrength, never the maps.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-12 (docs/asset-log.md): meshes by ModelAssembly.PublishMesh, maps by
-- tools/upload/upload_asset.py. The Brawler's two masks and the colour and glow maps again on 2026-11-19, with the
-- stage tile's face (AR47).
local MESHES = {
	Shade_Torso = 128634049240309,
	Shade_RightArm = 76942653408881,
	Shade_LeftArm = 103928260550532,
	Shade_RightLeg = 94957425237019,
	Shade_LeftLeg = 89850488694412,
	Shade_MaskBrawler = 92815305659174,
	Shade_MaskGuard = 127621233124561,
	Shade_MaskDasher = 92039325647952,
	Shade_MaskSupport = 82027470218034,
	Shade_MaskBrawlerBare = 91378643616488, -- the elite's copy without its ties (AR2, section 7)
}
-- AR2, section 4 (2026-11-12): the colour map grey under the lit edges and near white under the masks' cuts, and the
-- glow mask written for the recipe's two strengths over it. The two go up together and are never paired with the first
-- two (97770465927421, 104234918338692), nor AR2's (101466364915316, 102819316179447), which AR47 replaced.
local MAPS = {
	Color = "rbxassetid://136707341913294",
	Roughness = "rbxassetid://139349513496154",
	Emissive = "rbxassetid://99710484965891",
}
local BODY = {
	{ Piece = "Shade_Torso", On = "Torso" },
	{ Piece = "Shade_RightArm", On = "Right Arm" },
	{ Piece = "Shade_LeftArm", On = "Left Arm" },
	{ Piece = "Shade_RightLeg", On = "Right Leg" },
	{ Piece = "Shade_LeftLeg", On = "Left Leg" },
}
local MASKS = { "Brawler", "Guard", "Dasher", "Support" }
-- The recipe's strengths: the body's five pieces and a mask. The game's are Config.Shades.Emissive and MaskEmissive, set
-- per spawn.
local STRENGTH = 32
local MASK_STRENGTH = 12
local BODY_TINT = Color3.fromHex("EA4B4F") -- Strength's, until a spawn gives its type
local MASK_TINT = Color3.fromHex("FFE2B8")
-- The elite's second mask (AR2, sections 5 and 7; the recipe's `elite`): its Mesh at ELITE_SIZE, on the Left Arm's front
-- corner, where its middle goes and where its own +X, +Y and -Z point, at an ordinary Shade's size (the rig's ScaleTo
-- carries it). The Brawler's is a copy of its mask without the ties, which a sleeve can't hide: the same triangles and
-- UVs, so the same surface. Only the Brawler's is past the content check; the others wait on their own.
local ELITE_SIZE = 0.6
local ELITE = {
	Brawler = {
		Mesh = "Shade_MaskBrawlerBare",
		Centre = Vector3.new(-2.0694, 3.5561, -0.6156),
		Right = Vector3.new(0.7002, -0.1392, -0.7002),
		Up = Vector3.new(0.0984, 0.9903, -0.0984),
		Facing = Vector3.new(-0.7071, 0, -0.7071),
	},
}
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3).
local POINTS = {
	{ Name = "Chest", On = "Torso", At = Vector3.new(0, 3.0, -0.6) }, -- where a hit lands
	{ Name = "Crest", On = "Torso", At = Vector3.new(0, 3.0, 0.62) }, -- the lit mark on its back
	{ Name = "Collar", On = "Torso", At = Vector3.new(0, 4.5, -0.1) }, -- where the burst starts, where the face was
}

local function surface(part: MeshPart, tint: Color3, strength: number)
	local look = Instance.new("SurfaceAppearance")
	look.ColorMapContent = Content.fromUri(MAPS.Color)
	look.RoughnessMapContent = Content.fromUri(MAPS.Roughness)
	look.EmissiveMaskContent = Content.fromUri(MAPS.Emissive)
	look.EmissiveStrength = strength
	look.EmissiveTint = tint
	look.Parent = part
end

return function(Assembly: any): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = "Shade"
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Decal") or item:IsA("SpecialMesh") or item:IsA("BodyColors") or item:IsA("Clothing") or item:IsA("Accessory") or item:IsA("HumanoidDescription") then
			item:Destroy()
		end
	end
	local function rig(name: string): BasePart
		return model:FindFirstChild(name) :: BasePart
	end
	model.PrimaryPart = rig("HumanoidRootPart") -- the pivot it's placed by: the model's own sat off the root, and turned
	model:PivotTo(CFrame.new(0, 3, 0))
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	for _, piece in BODY do
		local part = Assembly.MeshPart(model, piece.Piece, MESHES[piece.Piece], Assembly.Centre(piece.Piece))
		surface(part, BODY_TINT, STRENGTH)
		Assembly.Weld(rig(piece.On), part)
	end
	for _, role in MASKS do
		local piece = `Shade_Mask{role}`
		local part = Assembly.MeshPart(model, `Mask_{role}`, MESHES[piece], Assembly.Centre(piece))
		surface(part, MASK_TINT, MASK_STRENGTH)
		Assembly.Weld(rig("Head"), part)
	end
	for role, at in ELITE do
		local part = Assembly.MeshPart(model, `EliteMask_{role}`, MESHES[at.Mesh], at.Centre)
		part.Size *= ELITE_SIZE
		part.CFrame = CFrame.fromMatrix(at.Centre, at.Right, at.Up, -at.Facing)
		surface(part, MASK_TINT, MASK_STRENGTH)
		Assembly.Weld(rig("Left Arm"), part)
	end
	for _, point in POINTS do
		Assembly.Attach(rig(point.On), point.Name, point.At)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	model.PrimaryPart = rig("HumanoidRootPart")
	model.WorldPivot = rig("HumanoidRootPart").CFrame
	return model
end
