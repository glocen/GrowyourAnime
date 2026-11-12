--!strict
-- Rook (AR1, delivery 2): the first Voidkin on R6, from build/handoff/Rook/Rook.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Rook:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Rook.rbxm (ServerStorage.Templates.Rook), which FightService clones
-- for a lead whose Voidkin row names it. The meshes need build/import/Rook_<Piece>.txt (copied from the handoff) for
-- their centres.
-- The rig is Roblox's plain R6 with its six parts hidden: a rigid mesh rides each and carries the body's own surface.
-- Two pieces turn on joints of their own, which the clips key under the pieces' names (tools/studio/Animations/Author's
-- HELD): Rook_Piston on the Right Arm slides 0.65 studs toward the shoulder through Haymaker's wind-up, Rook_Tape on the
-- Left Arm swings. A joint's frame is the recipe's pivot with the model's axes at rest, as tools/blender/rook_clips.py
-- builds it. Keep a clip playing: at R6's rest pose the ram meets the hip, and every clip holds it out.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-12 (docs/asset-log.md): the meshes by ModelAssembly.PublishMesh, the maps by
-- tools/upload/upload_asset.py. The glow mask is the rebake's, encoded for Roblox's formula (AR1, section 5's last entry).
local MESHES = {
	Rook_Torso = 75072828358670,
	Rook_Head = 83536541785353,
	Rook_RightArm = 110459521531466,
	Rook_LeftArm = 139750633315555,
	Rook_RightLeg = 83301661579419,
	Rook_LeftLeg = 119264728641413,
	Rook_Piston = 137575387200022,
	Rook_Tape = 126440446567363,
}
local MAPS = {
	Color = "rbxassetid://88102000312353",
	Roughness = "rbxassetid://91126705261926",
	Metalness = "rbxassetid://119731333943757",
	Emissive = "rbxassetid://101673823251221",
}
-- The glow: the mask covers the knuckles, the heat band and the piston's rod, on these two pieces. Cold at rest;
-- Haymaker's wind-up raises it from 0 toward the recipe's 10, a start: the ram's strength is tuned on Haymaker's replay.
local GLOW_TINT = Color3.fromHex("FFA630")
local GLOWS = { Rook_RightArm = true, Rook_Piston = true }

local BODY = {
	{ Piece = "Rook_Torso", On = "Torso" },
	{ Piece = "Rook_Head", On = "Head" },
	{ Piece = "Rook_RightArm", On = "Right Arm" },
	{ Piece = "Rook_LeftArm", On = "Left Arm" },
	{ Piece = "Rook_RightLeg", On = "Right Leg" },
	{ Piece = "Rook_LeftLeg", On = "Left Leg" },
}
-- The two joints of his own: the Motor6D's name is the recipe's motor, its Part1 the piece the clips key.
local JOINTS = {
	{ Piece = "Rook_Piston", On = "Right Arm", Motor = "Piston", Pivot = Vector3.new(1.9525, 3.5, 0.64) },
	{ Piece = "Rook_Tape", On = "Left Arm", Motor = "Tape", Pivot = Vector3.new(-2.1091, 2.4646, 0.3956) },
}
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3).
local POINTS = {
	{ Name = "Knuckles", On = "Right Arm", At = Vector3.new(1.72, 1.2175, -0.06) }, -- the ram's striking face
	{ Name = "RamCentre", On = "Right Arm", At = Vector3.new(1.72, 1.9375, -0.06) },
}

local function dress(part: MeshPart, piece: string)
	local look = Instance.new("SurfaceAppearance")
	look.ColorMapContent = Content.fromUri(MAPS.Color)
	look.RoughnessMapContent = Content.fromUri(MAPS.Roughness)
	look.MetalnessMapContent = Content.fromUri(MAPS.Metalness)
	if GLOWS[piece] then
		look.EmissiveMaskContent = Content.fromUri(MAPS.Emissive)
		look.EmissiveStrength = 0
		look.EmissiveTint = GLOW_TINT
	end
	look.Parent = part
end

return function(Assembly: any): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = "Rook"
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Decal") or item:IsA("SpecialMesh") or item:IsA("BodyColors") or item:IsA("Clothing") or item:IsA("Accessory") or item:IsA("HumanoidDescription") then
			item:Destroy()
		end
	end
	local function rig(name: string): BasePart
		return model:FindFirstChild(name) :: BasePart
	end
	model.PrimaryPart = rig("HumanoidRootPart")
	model:PivotTo(CFrame.new(0, 3, 0))
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
	for _, piece in BODY do
		local part = Assembly.MeshPart(model, piece.Piece, MESHES[piece.Piece], Assembly.Centre(piece.Piece))
		dress(part, piece.Piece)
		Assembly.Weld(rig(piece.On), part)
	end
	for _, joint in JOINTS do
		local part = Assembly.MeshPart(model, joint.Piece, MESHES[joint.Piece], Assembly.Centre(joint.Piece))
		dress(part, joint.Piece)
		local on = rig(joint.On)
		local pivot = CFrame.new(joint.Pivot)
		local motor = Instance.new("Motor6D")
		motor.Name = joint.Motor
		motor.Part0, motor.Part1 = on, part
		motor.C0 = on.CFrame:ToObjectSpace(pivot)
		motor.C1 = part.CFrame:ToObjectSpace(pivot)
		motor.Parent = on
	end
	for _, point in POINTS do
		Assembly.Attach(rig(point.On), point.Name, point.At)
	end
	model.PrimaryPart = rig("HumanoidRootPart")
	model.WorldPivot = rig("HumanoidRootPart").CFrame
	return model
end
