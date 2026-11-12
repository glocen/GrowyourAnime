--!strict
-- Pip (AR4, section 2): the lantern mage on R6, from build/handoff/Pip/Pip.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Pip:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Pip.rbxm (ServerStorage.Templates.Pip), which FightService clones for
-- a lead whose Voidkin row names it. The meshes need build/import/Pip_<Piece>.txt (copied from the handoff) for their
-- centres.
-- The rig is Roblox's plain R6 with its six parts hidden: a rigid mesh rides each and carries the body's own surface.
-- Two pieces turn on joints of their own, which the clips key under the pieces' names (tools/studio/Animations/Author's
-- HELD): Pip_Hat on the Head lags every move and lifts on the send; Pip_Lamp floats by his right shoulder on a joint on
-- the Torso, and Lantern Burst sends it. A joint's frame is the recipe's pivot with the model's axes at rest.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-12 (docs/asset-log.md): the meshes by ModelAssembly.PublishMesh, the maps by
-- tools/upload/upload_asset.py.
local MESHES = {
	Pip_Torso = 132821437900914,
	Pip_Head = 77540985870712,
	Pip_RightArm = 112482368647212,
	Pip_LeftArm = 125703091531387,
	Pip_RightLeg = 126706877495280,
	Pip_LeftLeg = 85810112763498,
	Pip_Hat = 95717361174280,
	Pip_Lamp = 130403422448641,
}
local MAPS = {
	Color = "rbxassetid://104901338746427",
	Roughness = "rbxassetid://124493734704925",
	Metalness = "rbxassetid://140165200687600",
	Emissive = "rbxassetid://118382160224793",
}
-- The glow: the mask covers the lantern's flame and nothing else, so the face and the eyes are never lit. White, since
-- Roblox multiplies the glow by the colour map, which already holds the flame's orange (an orange tint turns it red).
-- It burns cold as it floats; Lantern Burst's send takes it hot (Config.Effects.LanternBurst.Glow).
local GLOW_TINT = Color3.new(1, 1, 1)
local GLOW_COLD = 1.2
local GLOWS = { Pip_Lamp = true }

local BODY = {
	{ Piece = "Pip_Torso", On = "Torso" },
	{ Piece = "Pip_Head", On = "Head" },
	{ Piece = "Pip_RightArm", On = "Right Arm" },
	{ Piece = "Pip_LeftArm", On = "Left Arm" },
	{ Piece = "Pip_RightLeg", On = "Right Leg" },
	{ Piece = "Pip_LeftLeg", On = "Left Leg" },
}
-- The two joints of his own: the Motor6D's name is the recipe's motor, its Part1 the piece the clips key. Neither casts
-- a shadow: the hat's brim would put his face in the dark, and the lamp is a light.
local JOINTS = {
	{ Piece = "Pip_Hat", On = "Head", Motor = "Hat", Pivot = Vector3.new(0, 4.95, 0) },
	{ Piece = "Pip_Lamp", On = "Torso", Motor = "Lamp", Pivot = Vector3.new(2.75, 4.3, -0.3) },
}
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3). On names
-- a rig part or one of the pieces above.
local POINTS = {
	{ Name = "Lantern", On = "Pip_Lamp", At = Vector3.new(2.75, 4.3, -0.3) }, -- the flame's middle: where the burst starts
	{ Name = "Sleeve", On = "Right Arm", At = Vector3.new(1.6, 1.5, 0) }, -- the right cuff's opening: the send's line
	{ Name = "Chest", On = "Torso", At = Vector3.new(0, 3.2, -0.6) }, -- where a hit lands
}

local function dress(part: MeshPart, piece: string)
	local look = Instance.new("SurfaceAppearance")
	look.ColorMapContent = Content.fromUri(MAPS.Color)
	look.RoughnessMapContent = Content.fromUri(MAPS.Roughness)
	look.MetalnessMapContent = Content.fromUri(MAPS.Metalness)
	if GLOWS[piece] then
		look.EmissiveMaskContent = Content.fromUri(MAPS.Emissive)
		look.EmissiveStrength = GLOW_COLD
		look.EmissiveTint = GLOW_TINT
	end
	look.Parent = part
end

return function(Assembly: any): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = "Pip"
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Decal") or item:IsA("SpecialMesh") or item:IsA("BodyColors") or item:IsA("Clothing") or item:IsA("Accessory") or item:IsA("HumanoidDescription") then
			item:Destroy()
		end
	end
	local parts: { [string]: BasePart } = {}
	local function rig(name: string): BasePart
		return parts[name] or model:FindFirstChild(name) :: BasePart
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
		parts[piece.Piece] = part
	end
	for _, joint in JOINTS do
		local part = Assembly.MeshPart(model, joint.Piece, MESHES[joint.Piece], Assembly.Centre(joint.Piece), { CastShadow = false })
		dress(part, joint.Piece)
		local on = rig(joint.On)
		local pivot = CFrame.new(joint.Pivot)
		local motor = Instance.new("Motor6D")
		motor.Name = joint.Motor
		motor.Part0, motor.Part1 = on, part
		motor.C0 = on.CFrame:ToObjectSpace(pivot)
		motor.C1 = part.CFrame:ToObjectSpace(pivot)
		motor.Parent = on
		parts[joint.Piece] = part
	end
	for _, point in POINTS do
		Assembly.Attach(rig(point.On), point.Name, point.At)
	end
	model.PrimaryPart = rig("HumanoidRootPart")
	model.WorldPivot = rig("HumanoidRootPart").CFrame
	return model
end
