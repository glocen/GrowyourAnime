--!strict
-- The Shade (AR2): one R6 rig for every Shade, from build/handoff/Shade/Shade.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Shade:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Shade.rbxm (ServerStorage.Templates.Shade), which FightService clones.
-- The meshes need build/import/Shade_<Piece>.txt (copied from the handoff) for their centres.
-- The rig is Roblox's plain R6 with its six parts hidden: the body's five pieces are welded on their parts and the four
-- masks on the Head, each named Mask_<Role>. A spawn keeps its row's mask and drops the others, and tints the body's
-- lit edges with its type (Config.Shades): a script may set EmissiveTint, never the maps.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-12 (docs/asset-log.md): meshes by ModelAssembly.PublishMesh, maps by
-- tools/upload/upload_asset.py.
local MESHES = {
	Shade_Torso = 128634049240309,
	Shade_RightArm = 76942653408881,
	Shade_LeftArm = 103928260550532,
	Shade_RightLeg = 94957425237019,
	Shade_LeftLeg = 89850488694412,
	Shade_MaskBrawler = 79129017294899,
	Shade_MaskGuard = 127621233124561,
	Shade_MaskDasher = 92039325647952,
	Shade_MaskSupport = 82027470218034,
}
local MAPS = {
	Color = "rbxassetid://97770465927421",
	Roughness = "rbxassetid://139349513496154",
	Emissive = "rbxassetid://104234918338692",
}
local BODY = {
	{ Piece = "Shade_Torso", On = "Torso" },
	{ Piece = "Shade_RightArm", On = "Right Arm" },
	{ Piece = "Shade_LeftArm", On = "Left Arm" },
	{ Piece = "Shade_RightLeg", On = "Right Leg" },
	{ Piece = "Shade_LeftLeg", On = "Left Leg" },
}
local MASKS = { "Brawler", "Guard", "Dasher", "Support" }
local EMISSIVE = 2 -- the recipe's strength; the game's is Config.Shades.Emissive, set per spawn
local BODY_TINT = Color3.fromHex("EA4B4F") -- Strength's, until a spawn gives its type
local MASK_TINT = Color3.fromHex("FFE2B8")
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3).
local POINTS = {
	{ Name = "Chest", On = "Torso", At = Vector3.new(0, 3.0, -0.6) }, -- where a hit lands
	{ Name = "Crest", On = "Torso", At = Vector3.new(0, 3.0, 0.62) }, -- the lit mark on its back
	{ Name = "Collar", On = "Torso", At = Vector3.new(0, 4.5, -0.1) }, -- where the burst starts, where the face was
}

local function surface(part: MeshPart, tint: Color3)
	local look = Instance.new("SurfaceAppearance")
	look.ColorMapContent = Content.fromUri(MAPS.Color)
	look.RoughnessMapContent = Content.fromUri(MAPS.Roughness)
	look.EmissiveMaskContent = Content.fromUri(MAPS.Emissive)
	look.EmissiveStrength = EMISSIVE
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
		surface(part, BODY_TINT)
		Assembly.Weld(rig(piece.On), part)
	end
	for _, role in MASKS do
		local piece = `Shade_Mask{role}`
		local part = Assembly.MeshPart(model, `Mask_{role}`, MESHES[piece], Assembly.Centre(piece))
		surface(part, MASK_TINT)
		Assembly.Weld(rig("Head"), part)
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
