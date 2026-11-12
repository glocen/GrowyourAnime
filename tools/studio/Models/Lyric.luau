--!strict
-- Lyric (AR4, section 5): the stage singer on R6, from build/handoff/Lyric/Lyric.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Lyric:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Lyric.rbxm (ServerStorage.Templates.Lyric), which FightService clones
-- for a lead whose Voidkin row names it. The meshes need build/import/Lyric_<Piece>.txt (copied from the handoff) for
-- their centres.
-- The rig is Roblox's plain R6 with its six parts hidden: a rigid mesh rides each and carries the body's own surface.
-- Three pieces turn on joints of their own, which the clips key under the pieces' names (tools/studio/Animations/Author's
-- HELD): Lyric_Staff, the mic stand, on the Right Arm, its pivot where her fist meets the pole; the two speakers float at
-- her shoulders on joints on the Torso. A joint's frame is the recipe's pivot with the model's axes at rest.
-- Three edges (research's fix 3): dark shells just outside the bob and the boots, turned inside out, welded with their
-- parts; they cast no shadow, or they'd shade what they wrap.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-12 (docs/asset-log.md): the meshes by ModelAssembly.PublishMesh, the maps by
-- tools/upload/upload_asset.py.
local MESHES = {
	Lyric_Torso = 83405819418439,
	Lyric_Head = 135033691595468,
	Lyric_RightArm = 131401144430748,
	Lyric_LeftArm = 121544870162581,
	Lyric_RightLeg = 139229358507076,
	Lyric_LeftLeg = 113962717969748,
	Lyric_Staff = 123959196363788,
	Lyric_SpeakerR = 105223464605018,
	Lyric_SpeakerL = 83001463402296,
	Lyric_HeadEdge = 93435411458784,
	Lyric_RightLegEdge = 71049506909669,
	Lyric_LeftLegEdge = 126825078346082,
}
local MAPS = {
	Color = "rbxassetid://126747193692154",
	Roughness = "rbxassetid://96342815225839",
	Metalness = "rbxassetid://88274199900467",
	Emissive = "rbxassetid://138261768870090",
}
-- The glow: the mask covers the speakers' rings, the mic's ring, the headset's tip and the meter on her back, and nothing
-- else, so the face, the eyes and her hair's rose are never lit. White, since Roblox multiplies the glow by the colour
-- map, which already holds the pink. Cold as she stands; the note takes the speakers and the stand hot.
local GLOW_TINT = Color3.new(1, 1, 1)
local GLOW_COLD = 1.0
local GLOWS = { Lyric_Torso = true, Lyric_Head = true, Lyric_Staff = true, Lyric_SpeakerR = true, Lyric_SpeakerL = true }

local BODY = {
	{ Piece = "Lyric_Torso", On = "Torso" },
	{ Piece = "Lyric_Head", On = "Head" },
	{ Piece = "Lyric_RightArm", On = "Right Arm" },
	{ Piece = "Lyric_LeftArm", On = "Left Arm" },
	{ Piece = "Lyric_RightLeg", On = "Right Leg" },
	{ Piece = "Lyric_LeftLeg", On = "Left Leg" },
	{ Piece = "Lyric_HeadEdge", On = "Head", Edge = true },
	{ Piece = "Lyric_RightLegEdge", On = "Right Leg", Edge = true },
	{ Piece = "Lyric_LeftLegEdge", On = "Left Leg", Edge = true },
}
-- The three joints of her own: the Motor6D's name is the recipe's motor, its Part1 the piece the clips key.
local JOINTS = {
	{ Piece = "Lyric_Staff", On = "Right Arm", Motor = "Staff", Pivot = Vector3.new(1.5, 2.15, -0.68) },
	{ Piece = "Lyric_SpeakerR", On = "Torso", Motor = "SpeakerR", Pivot = Vector3.new(2.62, 5.0, 0.55) },
	{ Piece = "Lyric_SpeakerL", On = "Torso", Motor = "SpeakerL", Pivot = Vector3.new(-2.62, 5.0, 0.55) },
}
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3). On names
-- a rig part or one of the pieces above.
local POINTS = {
	{ Name = "Mic", On = "Lyric_Staff", At = Vector3.new(1.5, 5.9, -0.13) }, -- the mic's head: where the note starts
	{ Name = "RingR", On = "Lyric_SpeakerR", At = Vector3.new(2.5321, 4.892, 0.1362) }, -- the right speaker's cone
	{ Name = "RingL", On = "Lyric_SpeakerL", At = Vector3.new(-2.5321, 4.892, 0.1362) }, -- the left speaker's cone
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
	model.Name = "Lyric"
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
		local props = if piece.Edge then { CastShadow = false } else nil
		local part = Assembly.MeshPart(model, piece.Piece, MESHES[piece.Piece], Assembly.Centre(piece.Piece), props)
		dress(part, piece.Piece)
		Assembly.Weld(rig(piece.On), part)
		parts[piece.Piece] = part
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
		parts[joint.Piece] = part
	end
	for _, point in POINTS do
		Assembly.Attach(rig(point.On), point.Name, point.At)
	end
	model.PrimaryPart = rig("HumanoidRootPart")
	model.WorldPivot = rig("HumanoidRootPart").CFrame
	return model
end
