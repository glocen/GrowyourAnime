--!strict
-- Shard (client): the reveal's shard in a ViewportFrame the screen's size, its pieces posed each frame from Rules.Reveal
-- (reveal.json, "shard"). The pieces are the server's MeshParts (RevealService), painted from reveal_palette and lit flat,
-- so the palette's swatches read as drawn; the core takes the light's colour, no texture. The root's sway and even scale
-- move and size the ViewportFrame on the screen, the camera never moves; the squash across rides on the pieces.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Art = require(Shared.Config.RevealArt)
local Reveal = require(Shared.Rules.Reveal)

local Shard = {}

export type Shard = {
	View: ViewportFrame,
	Parts: { [string]: MeshPart },
	Sizes: { [string]: Vector3 },
}

-- A shard of `grade` (Standard, Enriched, Prismatic): its buds shown by the grade, the rest left out.
function Shard.new(grade: string, parent: Instance, z: number): Shard
	local screen = Art.Screen
	local root = Art.Shard.Root
	local view = Instance.new("ViewportFrame")
	view.Name = "Shard"
	view.BackgroundTransparency = 1
	view.Ambient = Color3.new(1, 1, 1)
	view.LightColor = Color3.new(0, 0, 0)
	view.AnchorPoint = Vector2.new(root.Origin.X / screen.X, root.Origin.Y / screen.Y)
	view.ZIndex = z
	local camera = Instance.new("Camera")
	local cam = Art.Shard.Camera
	camera.FieldOfView = cam.Fov
	camera.CFrame = CFrame.lookAt(cam.Target + cam.Direction * cam.Distance, cam.Target)
	camera.Parent = view
	view.CurrentCamera = camera
	local buds: { [string]: boolean } = {}
	for _, bud in Art.Shard.Grades[grade] or {} do
		buds[bud] = true
	end
	local parts: { [string]: MeshPart } = {}
	local sizes: { [string]: Vector3 } = {}
	local source = ReplicatedStorage:WaitForChild("NL_Reveal"):WaitForChild("Shard")
	for name, piece in Art.Shard.Pieces do
		local made = source:FindFirstChild(name)
		if made and made:IsA("MeshPart") and (piece.Host == nil or buds[name]) then
			local part = made:Clone()
			part.Material = Enum.Material.SmoothPlastic
			if piece.Order or piece.Host then
				part.TextureID = Art.Images.reveal_palette.Id
				part.Color = Color3.new(1, 1, 1)
			else
				part.TextureID = ""
			end
			part.Parent = view
			parts[name], sizes[name] = part, part.Size
		end
	end
	view.Parent = parent
	return { View = view, Parts = parts, Sizes = sizes }
end

-- The shard as Reveal.At lays it at one frame.
function Shard.Lay(shard: Shard, frame: Reveal.Frame)
	local at = frame.Shard
	shard.View.Visible = at ~= nil
	if at == nil then
		return
	end
	local pose = at.Pose
	local screen = Art.Screen
	shard.View.Position = UDim2.fromOffset(at.Point.X, at.Point.Y)
	shard.View.Size = UDim2.fromOffset(screen.X * pose.Scale.Y, screen.Y * pose.Scale.Y)
	shard.View.ImageTransparency = 1 - math.clamp(pose.Cover, 0, 1)
	local squash = Reveal.Squash(pose)
	local placed = Reveal.Pieces(pose)
	for name, part in shard.Parts do
		local piece = Art.Shard.Pieces[name]
		local grow = if piece.Order or piece.Host then squash else squash * pose.Core
		part.Size = shard.Sizes[name] * grow
		part.CFrame = placed[name]
		if piece.Order == nil and piece.Host == nil then -- the core
			part.Color = Reveal.CoreColour(frame.Colour, frame.Level)
			part.Transparency = if pose.Core > 0 then 0 else 1
		end
	end
end

return Shard
