--!strict
-- World (client): plates and numbers placed over points in the world, drawn on the World layer and moved every frame
-- (handbook/visuals/ui.md, "The layer structure": a BillboardGui isn't drawn by Studio's screen capture, so it can't be
-- reviewed). A plate hides while its point is behind the camera, farther than its reach, or gone. The whole layer steps
-- back while a screen is open: the screen has the player's attention, and the world's labels would crowd its edges.
--   World.Plate(name, size, where, reach?)   a frame over where() (a world position, or nil to hide); size authored
--   World.Shift(plate, offset)                moved off its point by `offset`, authored pixels (a number clear of another)
--   World.Remove(plate)

local RunService = game:GetService("RunService")

local Layers = require(script.Parent.Layers)
local Screen = require(script.Parent.Kit.Screen)

local World = {}

type Plate = { Frame: Frame, Where: () -> Vector3?, Reach: number, Shift: Vector2 }

local plates: { [Frame]: Plate } = {}

function World.Plate(name: string, size: Vector2, where: () -> Vector3?, reach: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.Visible = false
	frame.Parent = Layers.Get("World")
	plates[frame] = { Frame = frame, Where = where, Reach = reach or math.huge, Shift = Vector2.zero }
	return frame
end

function World.Shift(frame: Frame, offset: Vector2)
	local plate = plates[frame]
	if plate then
		plate.Shift = offset
	end
end

function World.Remove(frame: Frame)
	plates[frame] = nil
	frame:Destroy()
end

RunService:BindToRenderStep("NL_WorldPlates", Enum.RenderPriority.Camera.Value + 2, function()
	local layer = Layers.Get("World")
	layer.Visible = Screen.Current() == nil
	local camera = workspace.CurrentCamera
	if camera == nil or not layer.Visible then
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
		frame.Position = UDim2.new(screen.X / viewport.X, plate.Shift.X, screen.Y / viewport.Y, plate.Shift.Y)
		frame.Visible = true
	end
end)

return World
