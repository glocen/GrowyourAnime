--!strict
-- The Lamplighter (AR7): Lantern Row's keeper, from build/handoff/Lamplighter/Lamplighter.recipe.json. Studio, Edit mode, MCP:
--   local Assembly = require(game.ServerStorage.NL_Tools.ModelAssembly:Clone())
--   local model = require(game.ServerStorage.NL_Tools.Models.Lamplighter:Clone())(Assembly)
-- then Assembly.Serialize(model) into src/storage/Lamplighter.rbxm (ServerStorage.Templates.Lamplighter), which FightService
-- clones for the keeper's row and scales by its Scale (1.5). The meshes need build/import/Lamplighter_<Piece>.txt (copied
-- from the handoff) for their centres.
-- The Shade's R6 rig with its six parts hidden: six pieces welded on their parts (the Head's carries the mask, the hat and
-- its cords), and two on Motor6Ds of their own that the keeper's clips key: the pole on the Right Arm, the lantern on the
-- pole. Built in the stance, so a clip must play before it's seen (the recipe's rest pose has the arm hanging).
-- Each SurfaceAppearance says what its glow is (the attribute Glow): a spawn sets Body's and Mask's tint and strength as a
-- Shade's (Config.Shades); the lantern's is the keeper's fall's to put out (Config.Effects.LamplighterFall). A script may
-- set EmissiveTint and EmissiveStrength, never the maps.

local Players = game:GetService("Players")

-- Published under the group, 2026-11-13 (docs/asset-log.md): meshes by ModelAssembly.PublishMesh, maps by
-- tools/upload/upload_asset.py.
local MESHES = {
	Lamplighter_Torso = 123568546012950,
	Lamplighter_Head = 127642879641804,
	Lamplighter_RightArm = 96231224846300,
	Lamplighter_LeftArm = 101300623559846,
	Lamplighter_RightLeg = 97600147317949,
	Lamplighter_LeftLeg = 87843109491262,
	Lamplighter_Pole = 121025717290785,
	Lamplighter_Lantern = 138604065235609,
}
-- One atlas and one glow mask, uploaded together: the mask is written for the recipe's strengths over this colour map.
local MAPS = {
	Color = "rbxassetid://139338625939450",
	Roughness = "rbxassetid://120919633010805",
	Metalness = "rbxassetid://127686612155796",
	Emissive = "rbxassetid://114291313636166",
}
-- The recipe's glows, by piece: the body's lit seams in Intelligence's violet, the mask's paper and cuts in its warm white,
-- the lantern's paper whole under white (cold as it stands), the pole none.
local GLOWS = {
	Body = { Tint = Color3.fromHex("A470F2"), Strength = 32 },
	Mask = { Tint = Color3.fromHex("FFE2B8"), Strength = 12 },
	Lantern = { Tint = Color3.fromHex("FFFFFF"), Strength = 1.2 },
}
local BODY = {
	{ Piece = "Lamplighter_Torso", On = "Torso", Glow = "Body" },
	{ Piece = "Lamplighter_Head", On = "Head", Glow = "Mask" },
	{ Piece = "Lamplighter_RightArm", On = "Right Arm", Glow = "Body" },
	{ Piece = "Lamplighter_LeftArm", On = "Left Arm", Glow = "Body" },
	{ Piece = "Lamplighter_RightLeg", On = "Right Leg", Glow = "Body" },
	{ Piece = "Lamplighter_LeftLeg", On = "Left Leg", Glow = "Body" },
}
-- Its two joints: the Motor6D's name is the recipe's motor, its Part1 the piece the clips key, its pivot the grip and the
-- hook's tip. The lantern's Part0 is the pole, a held part on a held part (Author.SaveBaked nests its Pose).
local JOINTS = {
	{ Piece = "Lamplighter_Pole", On = "Right Arm", Motor = "Pole", Pivot = Vector3.new(1.8, 1.72, 0), Glow = nil },
	{ Piece = "Lamplighter_Lantern", On = "Lamplighter_Pole", Motor = "Lantern", Pivot = Vector3.new(4.9752, 4.6157, -2.7467), Glow = "Lantern" },
}
-- Points the game reads, in model space (the recipe's frame: the feet on y = 0, facing -Z, the root at y = 3). Collar is
-- the builder's, the Shade's own: where the burst starts.
local POINTS = {
	{ Name = "Lantern", On = "Lamplighter_Lantern", At = Vector3.new(4.317, 3.5858, -1.6988) }, -- the light's middle
	{ Name = "HookTip", On = "Lamplighter_Pole", At = Vector3.new(4.9752, 4.6157, -2.7467) },
	{ Name = "PoleFoot", On = "Lamplighter_Pole", At = Vector3.new(0.7119, 0.0173, 1.7326) },
	{ Name = "Grip", On = "Right Arm", At = Vector3.new(1.8, 1.72, 0) },
	{ Name = "Chest", On = "Torso", At = Vector3.new(0, 3.1, -0.75) }, -- where a hit lands
	{ Name = "Crest", On = "Torso", At = Vector3.new(0, 3.36, 0.72) }, -- the lantern crest on its back
	{ Name = "Collar", On = "Torso", At = Vector3.new(0, 4.5, -0.1) },
}
-- The lantern's light (the recipe: "a cyan PointLight in it is the builder's call"): Lantern Row's cyan, at the template's
-- size (the spawn's ScaleTo scales its Range). The fall dims it with the lantern's glow.
local LIGHT = { Colour = Color3.fromHex("7FE6FF"), Brightness = 1.2, Range = 9 }

local function dress(part: MeshPart, glow: string?)
	local look = Instance.new("SurfaceAppearance")
	look.ColorMapContent = Content.fromUri(MAPS.Color)
	look.RoughnessMapContent = Content.fromUri(MAPS.Roughness)
	look.MetalnessMapContent = Content.fromUri(MAPS.Metalness)
	if glow then
		local spec = GLOWS[glow]
		look.EmissiveMaskContent = Content.fromUri(MAPS.Emissive)
		look.EmissiveStrength = spec.Strength
		look.EmissiveTint = spec.Tint
		look:SetAttribute("Glow", glow)
	end
	look.Parent = part
end

return function(Assembly: any): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = "Lamplighter"
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Decal") or item:IsA("SpecialMesh") or item:IsA("BodyColors") or item:IsA("Clothing") or item:IsA("Accessory") or item:IsA("HumanoidDescription") then
			item:Destroy()
		end
	end
	local function part(name: string): BasePart
		return model:FindFirstChild(name) :: BasePart
	end
	model.PrimaryPart = part("HumanoidRootPart")
	model:PivotTo(CFrame.new(0, 3, 0))
	for _, rigPart in model:GetChildren() do
		if rigPart:IsA("BasePart") then
			rigPart.Transparency = 1
		end
	end
	for _, piece in BODY do
		local mesh = Assembly.MeshPart(model, piece.Piece, MESHES[piece.Piece], Assembly.Centre(piece.Piece))
		dress(mesh, piece.Glow)
		Assembly.Weld(part(piece.On), mesh)
	end
	for _, joint in JOINTS do
		local mesh = Assembly.MeshPart(model, joint.Piece, MESHES[joint.Piece], Assembly.Centre(joint.Piece))
		dress(mesh, joint.Glow)
		local on = part(joint.On)
		local pivot = CFrame.new(joint.Pivot)
		local motor = Instance.new("Motor6D")
		motor.Name = joint.Motor
		motor.Part0, motor.Part1 = on, mesh
		motor.C0 = on.CFrame:ToObjectSpace(pivot)
		motor.C1 = mesh.CFrame:ToObjectSpace(pivot)
		motor.Parent = on
	end
	local lantern = part("Lamplighter_Lantern")
	lantern.CastShadow = false -- it's a light
	for _, point in POINTS do
		Assembly.Attach(part(point.On), point.Name, point.At)
	end
	local light = Instance.new("PointLight")
	light.Name = "Light"
	light.Color = LIGHT.Colour
	light.Brightness = LIGHT.Brightness
	light.Range = LIGHT.Range
	light.Shadows = false
	light.Parent = lantern:FindFirstChild("Lantern")
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	model.PrimaryPart = part("HumanoidRootPart")
	model.WorldPivot = part("HumanoidRootPart").CFrame
	return model
end
