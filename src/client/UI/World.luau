--!strict
-- World (client): plates and numbers placed over points in the world, drawn on the World layer and moved every frame
-- (handbook/visuals/ui.md, "The layer structure": a BillboardGui isn't drawn by Studio's screen capture, so it can't be
-- reviewed). A plate hides while its point is behind the camera, farther than its reach, or gone.
--   World.Plate(name, size, where, reach?)   a frame over where() (a world position, or nil to hide); size authored
--   World.Remove(plate)

local RunService = game:GetService("RunService")

local Layers = require(script.Parent.Layers)

local World = {}

type Plate = { Frame: Frame, Where: () -> Vector3?, Reach: number }

local plates: { [Frame]: Plate } = {}

function World.Plate(name: string, size: Vector2, where: () -> Vector3?, reach: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.Visible = false
	frame.Parent = Layers.Get("World")
	plates[frame] = { Frame = frame, Where = where, Reach = reach or math.huge }
	return frame
end

function World.Remove(frame: Frame)
	plates[frame] = nil
	frame:Destroy()
end

RunService:BindToRenderStep("NL_WorldPlates", Enum.RenderPriority.Camera.Value + 2, function()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local viewport = camera.ViewportSize
	local eye = camera.CFrame.Position
	for frame, plate in plates do
		if frame.Parent == nil then
			plates[frame] = nil
			continue
		end
		local ok, at = pcall(plate.Where)
		local point = if ok then at else nil
		if point == nil or (point - eye).Magnitude > plate.Reach then
			frame.Visible = false
			continue
		end
		local screen, onScreen = camera:WorldToViewportPoint(point)
		if not onScreen or screen.Z <= 0 then
			frame.Visible = false
			continue
		end
		-- By scale, so the layer's UIScale sizes the plate and never moves it.
		frame.Position = UDim2.fromScale(screen.X / viewport.X, screen.Y / viewport.Y)
		frame.Visible = true
	end
end)

return World
