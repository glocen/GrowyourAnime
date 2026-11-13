--!strict
-- World (client): plates and numbers placed over points in the world, drawn on the World layer and moved every frame
-- (handbook/visuals/ui.md, "The layer structure": a BillboardGui isn't drawn by Studio's screen capture, so it can't be
-- reviewed). A plate hides while its point is behind the camera, farther than its reach, or gone. The whole layer steps
-- back while a screen is open: the screen has the player's attention, and the world's labels would crowd its edges.
--   World.Plate(name, size, where, reach?)   a frame over where() (a world position, or nil to hide); size authored
--   World.Shift(plate, offset)                moved off its point by `offset`, authored pixels (a number clear of another)
--   World.Below(plate, open?)                 kept under the top band its whole life: a number (TR3's verdict, fix 4), a
--                                             machine's plate (the phone pack, 2026-11-13). Open: it may stand in the sky
--                                             between the band's pieces; one it would cross, it slides aside from, eased, or
--                                             with no room is pushed under; never over the top bar (the level-up's word over
--                                             the lead's head: research's pass on AR8 C, fix 1)
--   World.Band(edge?, spans?, floor?)         the top band's lower edge, authored pixels from the screen's top; each piece's
--   World.Edge()                              own span; the top bar's foot (the HUD's)
--   World.Remove(plate)
--   World.Where(plate)                        the world point it stands over now, or nil: for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local HudConfig = require(game:GetService("ReplicatedStorage").Shared.Config.Hud)

local Layers = require(script.Parent.Layers)
local Screen = require(script.Parent.Kit.Screen)

local World = {}

type Plate = { Frame: Frame, Where: () -> Vector3?, Reach: number, Shift: Vector2, Below: boolean, Open: boolean, Slide: number?, Swell: UIScale? }
export type Span = { Left: number, Right: number, Edge: number } -- a piece of the band, its margin included, authored pixels

local plates: { [Frame]: Plate } = {}
local band: number? = nil -- the top band's lower edge, margin included: the cards and the pills that show (HudController)
local spans: { Span } = {} -- the same pieces one by one, and a toast stack while it shows
local floor: number? = nil -- the top bar's foot: an open plate never stands over it

function World.Plate(name: string, size: Vector2, where: () -> Vector3?, reach: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.Visible = false
	frame.Parent = Layers.Get("World")
	plates[frame] = { Frame = frame, Where = where, Reach = reach or math.huge, Shift = Vector2.zero, Below = false, Open = false }
	return frame
end

function World.Below(frame: Frame, open: boolean?)
	local plate = plates[frame]
	if plate then
		plate.Below = true
		plate.Open = open == true
		plate.Swell = frame:FindFirstChildOfClass("UIScale") -- a number's swell grows it up from its foot
	end
end

function World.Band(edge: number?, pieces: { Span }?, top: number?)
	band = edge
	spans = pieces or {}
	floor = top
	Layers.Get("World"):SetAttribute("Band", edge) -- for the self-test
end

function World.Edge(): number?
	return band
end

function World.Shift(frame: Frame, offset: Vector2)
	local plate = plates[frame]
	if plate then
		plate.Shift = offset
	end
end

function World.Where(frame: Frame): Vector3?
	local plate = plates[frame]
	return if plate then plate.Where() else nil
end

-- The pieces under a plate's width at `middle` that reach below its `top`: the lowest one's edge, and their outer sides.
local function crossing(middle: number, half: number, top: number): (number?, number, number)
	local edge: number?, left, right = nil, math.huge, -math.huge
	for _, span in spans do
		if span.Edge > top and span.Left < middle + half and span.Right > middle - half then
			edge = math.max(edge or span.Edge, span.Edge)
			left, right = math.min(left, span.Left), math.max(right, span.Right)
		end
	end
	return edge, left, right
end

-- How far an open plate slides aside to clear the pieces it would cross (0 if none, or no room within Room of its width
-- and the screen), and the edge it's pushed under then: the pieces' if it couldn't slide, the top bar's always.
local function aside(middle: number, half: number, top: number, wide: number): (number, number?)
	local edge, left, right = crossing(middle, half, top)
	local best = 0
	if edge then
		local room = HudConfig.Numbers.Slide.Room * half * 2
		local found = false
		for _, to in { left - half, right + half } do
			local by = to - middle
			if math.abs(by) <= room and to - half >= 0 and to + half <= wide and crossing(to, half, top) == nil then
				if not found or math.abs(by) < math.abs(best) then
					best, found = by, true
				end
			end
		end
		if found then
			edge = nil
		end
	end
	local under = if edge and floor then math.max(edge, floor) else edge or floor
	return best, under
end

function World.Remove(frame: Frame)
	plates[frame] = nil
	frame:Destroy()
end

RunService:BindToRenderStep("NL_WorldPlates", Enum.RenderPriority.Camera.Value + 2, function(dt: number)
	local layer = Layers.Get("World")
	layer.Visible = Screen.Current() == nil
	local camera = workspace.CurrentCamera
	if camera == nil or not layer.Visible then
		return
	end
	local eye = camera.CFrame.Position
	-- A viewport pixel less the top bar's inset is a GUI pixel (as WorldToScreenPoint gives), and the layer's corner is
	-- where it starts. On a phone with a notch the viewport is the safe width while the layer runs full-bleed, so a share
	-- of the viewport set on the layer drifts outward from its point (the device simulator, 2026-11-13).
	local inset = GuiService:GetGuiInset()
	local corner, room, scale = layer.AbsolutePosition, layer.AbsoluteSize, Layers.Scale()
	if room.X <= 0 or room.Y <= 0 then
		return
	end
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
		local on = Vector2.new(screen.X, screen.Y) - inset - corner -- on the layer, in its pixels
		-- By scale, so the layer's UIScale sizes the plate and never moves it.
		local shift = plate.Shift
		local edge = band
		if plate.Below and edge then
			-- Anchored at its foot, so its top is its point less its height, in authored pixels from the layer's top, the
			-- band's own measure; pushed down by what crosses it. An open plate, by only the pieces under its width.
			local swell = if plate.Swell then plate.Swell.Scale else 1
			local top = on.Y / scale + shift.Y - frame.Size.Y.Offset * swell
			if plate.Open then
				-- Aside from what it would cross, eased there from where it stood, or set there on its first frame.
				local middle = on.X / scale + shift.X
				local by, under = aside(middle, frame.Size.X.Offset * swell / 2, top, room.X / scale)
				local was = plate.Slide
				local slide = if was then was + (by - was) * math.min(1, dt * HudConfig.Numbers.Slide.Rate) else by
				plate.Slide = slide
				shift += Vector2.new(slide, 0)
				edge = under or -math.huge
			end
			shift += Vector2.new(0, math.max(0, edge - top))
		end
		frame.Position = UDim2.new(on.X / room.X, shift.X, on.Y / room.Y, shift.Y)
		frame.Visible = true
	end
end)

return World
