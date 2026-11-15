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
--   World.Band(edge?, spans?, floor?, corner?) the top band's lower edge, authored pixels from the screen's top; each piece's
--   World.Edge()                              own span; the top bar's foot (the HUD's); the lead's corner under its card
--                                             (the readout, the eye, the next's offer): a plate under the band starts right
--                                             of it (research's pass on AR12: the eye stood over a bay's plate)
--   World.Ceiling()                           that foot in the viewport's pixels: a shape in the world kept under it
--   World.Remove(plate)
--   World.Where(plate)                        the world point it stands over now, or nil: for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local HudConfig = require(game:GetService("ReplicatedStorage").Shared.Config.Hud)

local Layers = require(script.Parent.Layers)
local Screen = require(script.Parent.Kit.Screen)

local World = {}

type Plate = { Frame: Frame, Where: () -> Vector3?, Reach: number, Shift: Vector2, Below: boolean, Open: boolean, Slide: number?, Drop: number?, Swell: UIScale? }
export type Span = { Left: number, Right: number, Edge: number } -- a piece of the band, its margin included, authored pixels

local plates: { [Frame]: Plate } = {}
local band: number? = nil -- the top band's lower edge, margin included: the cards and the pills that show (HudController)
local spans: { Span } = {} -- the same pieces one by one, and a toast stack while it shows
local floor: number? = nil -- the top bar's foot: an open plate never stands over it
local leadCorner: Span? = nil -- the lead's corner under its card, its margin included: a plate kept under the band keeps right of it

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

function World.Band(edge: number?, pieces: { Span }?, top: number?, lead: Span?)
	band = edge
	spans = pieces or {}
	floor = top
	leadCorner = lead
	Layers.Get("World"):SetAttribute("Band", edge) -- for the self-test
end

function World.Edge(): number?
	return band
end

-- The top bar's foot in the viewport's pixels (Camera:ViewportPointToRay's), or nil before the HUD has set it: for a shape in
-- the world that stays under it, B5's hanging square (TR7, research's call on the hang, (c), at the top bar's foot).
function World.Ceiling(): number?
	if floor == nil then
		return nil
	end
	local world = Layers.Get("World")
	return world.AbsolutePosition.Y + floor * Layers.Scale() + GuiService:GetGuiInset().Y
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

-- How far an open plate slides aside to clear the pieces it would cross: 0 if none, or no room within Room of its width
-- and the screen.
local function aside(middle: number, half: number, top: number, wide: number): number
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
	end
	return best
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
				-- Aside from what it would cross, eased there from where it stood, or set there on its first frame. Then under
				-- what it crosses where it stands now, mid-slide too, and never over the top bar: it drops at once and rises
				-- back eased, so it never stands over a piece's corner while it slides out (the level-up case, 2026-11-13).
				local middle, half = on.X / scale + shift.X, frame.Size.X.Offset * swell / 2
				local rate = math.min(1, dt * HudConfig.Numbers.Slide.Rate)
				local by = aside(middle, half, top, room.X / scale)
				local was = plate.Slide
				local slide = if was then was + (by - was) * rate else by
				plate.Slide = slide
				local crossed = crossing(middle + slide, half - 0.5, top) -- clear within half a pixel: the ease only nears its end
				local bar = floor
				local under = if crossed and bar then math.max(crossed, bar) else crossed or bar
				local want = if under then math.max(0, under - top) else 0
				local had = plate.Drop
				local drop = if had and want < had then had + (want - had) * rate else want
				plate.Drop = drop
				shift += Vector2.new(slide, drop)
			else
				-- Under the band, and right of the lead's corner where it would stand over it: pinned at the corner's side, so
				-- it follows its point out with no jump. It steps aside at once, and eases back once its top is under the
				-- corner's foot, so it never stands over the eye on the way.
				local drop = math.max(0, edge - top)
				local by = 0
				local side = leadCorner
				if side then
					local middle, half = on.X / scale + shift.X, frame.Size.X.Offset * swell / 2
					if side.Edge > top + drop and side.Left < middle + half and side.Right > middle - half then
						by = side.Right + half - middle
					end
				end
				local was = plate.Slide
				local slide = if was and by < was then was + (by - was) * math.min(1, dt * HudConfig.Numbers.Slide.Rate) else by
				plate.Slide = slide
				shift += Vector2.new(slide, drop)
			end
		end
		-- The shift too, in the layer's pixels: a UDim's offset is a whole number, and a push of 21.9999 cut to 21 stood an
		-- open plate a pixel over the piece it cleared (the World case, 2026-11-13).
		frame.Position = UDim2.fromScale((on.X + shift.X * scale) / room.X, (on.Y + shift.Y * scale) / room.Y)
		frame.Visible = true
	end
end)

return World
