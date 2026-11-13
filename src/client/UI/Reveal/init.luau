--!strict
-- Reveal (client): the reveal's ceremony on the screen (docs/test-requests.md, TR4; AR3, sections 4 and 5). Modulo's 16
-- layers in reveal.json's order, laid every frame from the time since the tap by Rules.Reveal.At; this module decides
-- nothing, it only lays what that says. The stage is the art's 844 by 390 screen, fitted whole inside the window (a phone
-- held sideways fills it; a wider or taller window shows the room beyond it), on the Overlay layer.
--   local stage = Reveal.Play({ Rarity = "Rare", Name = "Lyric", Model = "Lyric" }, onCard)
--   stage.Skip()      from 1.0 s, to the held frame
--   stage.Seek(t)     for tests and captures: the clock pinned at t (nil lets it run on from there)
--   stage.Destroy()

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.Shared
local Art = require(Shared.Config.RevealArt)
local RevealConfig = require(Shared.Config.Reveal)
local Reveal = require(Shared.Rules.Reveal)
local Layers = require(script.Parent.Layers)
local Shard = require(script.Shard)
local Figure = require(script.Figure)

local WHITE = Color3.new(1, 1, 1)
local FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic)
local MARGIN = 24 -- points of room past the window's top and foot, so the kick never shows its edge
local HEAD = Vector2.new(-Art.Figure.Tile.X / 2, 185 - Art.Figure.Tile.Y / 2) + Art.Figure.Flood.Origin -- the ram's head, from cx
local COLUMN = { 400, 72 } -- the column reaches this far above the ram's head, and this far below
local LEAK_LABELS = 24
local Z = { Glow = 1, Rings = 2, Rays = 3, Halo = 4, Window = 5, Sill = 6, Frame = 7, Shard = 8, Leak = 9, Figure = 10, Strike = 11, Foot = 12, Flash = 13, Name = 14, Split = 15 }

local Stage = {}

export type Options = { Rarity: string, Name: string, Model: string? }
export type Handle = {
	Root: Frame,
	Rarity: Art.Rarity,
	Time: () -> number,
	Skip: () -> boolean,
	Seek: (t: number?) -> (),
	Destroy: () -> (),
}

task.spawn(function() -- every image ready before the first break, so nothing pops in
	local ids = {}
	for _, image in Art.Images do
		table.insert(ids, image.Id)
	end
	pcall(function()
		ContentProvider:PreloadAsync(ids)
	end)
end)

local function image(name: string, id: string, parent: Instance, z: number): ImageLabel
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Image = id
	label.ZIndex = z
	label.Visible = false
	label.Parent = parent
	return label
end

-- An image laid over the stage in a box of points, tinted, its cover times alpha.
local function lay(label: ImageLabel, x: number, y: number, w: number, h: number, tint: Color3, alpha: number)
	if alpha <= 0.002 or w <= 0 or h <= 0 then
		label.Visible = false
		return
	end
	label.Visible = true
	label.Position = UDim2.fromOffset(x, y)
	label.Size = UDim2.fromOffset(w, h)
	label.ImageColor3 = tint
	label.ImageTransparency = 1 - math.min(1, alpha)
end

-- reveal_glow, s points across and down.
local function dot(label: ImageLabel, x: number, y: number, sx: number, sy: number, tint: Color3, alpha: number)
	lay(label, x - 3 * sx, y - 3 * sy, 6 * sx, 6 * sy, tint, alpha)
end

local function anchored(label: ImageLabel, points: Vector2, anchor: Vector2, x: number, y: number, sx: number, sy: number, tint: Color3, alpha: number)
	lay(label, x - anchor.X * points.X * sx, y - anchor.Y * points.Y * sy, points.X * sx, points.Y * sy, tint, alpha)
end

local function ring(label: ImageLabel, x: number, y: number, r: Reveal.Ring, tint: Color3)
	local i, size = Reveal.Ring(r.Radius, r.Width)
	local rect = Art.Rings[i].Rect
	label.ImageRectOffset = Vector2.new(rect[1], rect[2])
	label.ImageRectSize = Vector2.new(rect[3], rect[4])
	lay(label, x - size / 2, y - size / 2, size, size, tint, r.Alpha)
end

local function bounds(text: string, size: number): Vector2
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = FONT
	params.Size = size
	params.Width = 100000
	local ok, got = pcall(function(): Vector2
		return TextService:GetTextBoundsAsync(params)
	end)
	return if ok then got else Vector2.new(#text * size * 0.55, size)
end

function Stage.Play(options: Options, onCard: (() -> ())?): Handle
	local r = Art.Rarities[options.Rarity] or Art.Rarities.Common
	local rarity = if Art.Rarities[options.Rarity] then options.Rarity else "Common"
	local images = Art.Images
	local screen = Art.Screen
	local places = Art.Places
	local named = Art.Name
	local text = string.upper(options.Name) -- the art's names are set in capitals (reveal_art.py)

	local holder = Instance.new("Frame")
	holder.Name = "Reveal"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	local room = image("Room", images.reveal_room.Id, holder, 1)
	room.ScaleType = Enum.ScaleType.Crop
	room.BackgroundColor3 = Art.Figure.Dark
	room.BackgroundTransparency = 0
	room.Visible = true
	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.BackgroundTransparency = 1
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Size = UDim2.fromOffset(screen.X, screen.Y)
	stage.ZIndex = 2
	stage.Parent = holder
	local fit = Instance.new("UIScale")
	fit.Parent = stage
	local white = Instance.new("Frame")
	white.Name = "White"
	white.BackgroundColor3 = WHITE
	white.BorderSizePixel = 0
	white.Size = UDim2.fromScale(1, 1)
	white.ZIndex = 3
	white.Visible = false
	white.Parent = holder

	-- 2 to 7: the room's light, the rungs' rings, the rays, the window's halo and fill, the sill, the frame
	local glow = image("Glow", images.reveal_glow.Id, stage, Z.Glow)
	local rings = {}
	for i = 1, 3 do
		rings[i] = image(`Ring{i}`, images.reveal_rings.Id, stage, Z.Rings)
	end
	local rays = if r.Light.Rays > 0 then image("Rays", images[`reveal_rays{r.Light.Rays}`].Id, stage, Z.Rays) else nil
	local haloArt, windowArt, frameArt = images[`reveal_halo_{rarity}`], images[`reveal_window_{rarity}`], images[`reveal_frame_{rarity}`]
	local halo = image("Halo", haloArt.Id, stage, Z.Halo)
	local window = image("Window", windowArt.Id, stage, Z.Window)
	local sill = image("Sill", images.reveal_glow.Id, stage, Z.Sill)
	local frameLabel = image("Frame", frameArt.Id, stage, Z.Frame)
	-- 8 and 9: the shard and its leak
	local shard = Shard.new(r.Grade, stage, Z.Shard)
	local leak = {}
	for i = 1, LEAK_LABELS do
		leak[i] = image(`Leak{i}`, images.reveal_leak.Id, stage, Z.Leak)
	end
	-- 10 and 11: the figure and the strike
	local figure = Figure.new(options.Model, stage, Z.Figure)
	local strikeRing = image("StrikeRing", images.reveal_rings.Id, stage, Z.Strike)
	local strikeDot = image("StrikeDot", images.reveal_glow.Id, stage, Z.Strike)
	local column = image("Column", images.reveal_column.Id, stage, Z.Strike)
	-- 12: the frame's foot over his soles, a copy clipped to the rows below the band
	local foot = Instance.new("Frame")
	foot.Name = "Foot"
	foot.BackgroundTransparency = 1
	foot.ClipsDescendants = true
	foot.Position = UDim2.fromOffset(0, places.FootBand)
	foot.Size = UDim2.fromOffset(screen.X, screen.Y - places.FootBand + MARGIN)
	foot.ZIndex = Z.Foot
	foot.Parent = stage
	local footFrame = image("Frame", frameArt.Id, foot, 1)
	-- 13 to 15: the rung's flash, the name, the split's flash
	local flash = image("Flash", images.reveal_glow.Id, stage, Z.Flash)
	local width58 = bounds(text, named.Size).X
	local size = Reveal.NameSize(r, width58)
	local box = bounds(text, size)
	if box.X > named.Widest then -- the font's own rounding: a point smaller until it fits
		size = math.floor(size * named.Widest / box.X)
		box = bounds(text, size)
	end
	local nameBox = Instance.new("Frame")
	nameBox.Name = "Name"
	nameBox.BackgroundTransparency = 1
	nameBox.AnchorPoint = Vector2.new(0.25, 1)
	nameBox.Size = UDim2.fromOffset(box.X, box.Y)
	nameBox.Position = UDim2.fromOffset(named.Left + 0.25 * box.X, named.Baseline + RevealConfig.NameDescent * size)
	nameBox.ZIndex = Z.Name
	nameBox.Visible = false
	nameBox.Parent = stage
	local slam = Instance.new("UIScale")
	slam.Parent = nameBox
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Text"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.FontFace = FONT
	nameLabel.TextSize = size
	nameLabel.Text = text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	nameLabel.ZIndex = Z.Name
	nameLabel.Parent = nameBox
	local rule = image("Rule", images.reveal_rule.Id, stage, Z.Name)
	local slice = images.reveal_rule.Slice :: { number }
	rule.ScaleType = Enum.ScaleType.Slice
	rule.SliceCenter = Rect.new(slice[1], slice[2], slice[3], slice[4])
	rule.SliceScale = (images.reveal_rule.Points :: Vector2).X / images.reveal_rule.Pixels.X
	local glintClip = Instance.new("Frame")
	glintClip.Name = "Glint"
	glintClip.BackgroundTransparency = 1
	glintClip.ClipsDescendants = true
	glintClip.ZIndex = Z.Name
	glintClip.Parent = stage
	local glint = image("Line", images.reveal_glow.Id, glintClip, 1)
	local glintColour = image("GlintColour", images.reveal_glow.Id, stage, Z.Name)
	local wash = image("Wash", images.reveal_glow.Id, stage, Z.Name)
	local split = image("Split", images.reveal_glow.Id, stage, Z.Split)

	holder.Parent = Layers.Get("Overlay")

	local start = os.clock()
	local pinned: number? = nil
	local carded = false
	local function now(): number
		return math.min(pinned or (os.clock() - start), r.Times.Card)
	end

	local function frameAt(t: number)
		local f = Reveal.At(r, t, box.X)
		local viewport = if workspace.CurrentCamera then workspace.CurrentCamera.ViewportSize else screen
		local whole = math.min(viewport.X / screen.X, viewport.Y / screen.Y)
		local layer = Layers.Scale()
		fit.Scale = whole / layer
		local kick = f.Kick * whole / layer
		stage.Position = UDim2.new(0.5, 0, 0.5, kick)
		room.Position = UDim2.new(0, 0, 0, kick - MARGIN * whole / layer)
		room.Size = UDim2.new(1, 0, 1, 2 * MARGIN * whole / layer)
		local cx, cy, colour = f.Cx, places.Cy, f.Colour
		dot(glow, cx, cy, 300, 300, colour, f.Glow)
		for i, label in rings do
			local at = f.Rings[i]
			if at then
				ring(label, cx, cy, at, colour)
			else
				label.Visible = false
			end
		end
		local w = f.Window
		local middle = places.WindowMiddle
		if w then
			if rays then
				local span = images[`reveal_rays{r.Light.Rays}`].Points :: Vector2
				lay(rays, cx - span.X / 2, places.RaysPoint - span.Y / 2, span.X, span.Y, r.Light.RaysColour, w.Rays)
				rays.Rotation = math.deg(w.Turn)
			end
			anchored(halo, haloArt.Points :: Vector2, haloArt.Anchor :: Vector2, cx, middle, w.Sx, w.Sy, WHITE, 1)
			anchored(window, windowArt.Points :: Vector2, windowArt.Anchor :: Vector2, cx, middle, w.Sx, w.Sy, WHITE, 1)
			dot(sill, cx, places.Sill, 170, 5, colour, w.Sill)
			anchored(frameLabel, frameArt.Points :: Vector2, frameArt.Anchor :: Vector2, cx, middle, 1, 1, WHITE, w.Framed)
			anchored(footFrame, frameArt.Points :: Vector2, frameArt.Anchor :: Vector2, cx, middle - places.FootBand, 1, 1, WHITE, w.Framed)
		else
			for _, label in { rays, halo, window, sill, frameLabel, footFrame } do
				(label :: ImageLabel).Visible = false
			end
		end
		Shard.Lay(shard, f)
		local used = 0
		local at = f.Shard
		if at then
			local scale = at.Pose.Scale
			for _, cell in at.Leak do
				used += 1
				local label = leak[used]
				if label == nil then
					break
				end
				local art = Art.Leak.Cells[cell.Name]
				label.ImageRectOffset = Vector2.new(art.Rect[1], art.Rect[2])
				label.ImageRectSize = Vector2.new(art.Rect[3], art.Rect[4])
				anchored(label, art.Points, art.Anchor, at.Point.X, at.Point.Y, scale.X, scale.Y, if cell.White then WHITE else colour, cell.Alpha)
			end
		end
		for i = used + 1, LEAK_LABELS do
			leak[i].Visible = false
		end
		Figure.Lay(figure, f)
		local strike = f.Strike
		if strike then
			local head = Vector2.new(cx, 0) + HEAD
			ring(strikeRing, head.X, head.Y, strike.Ring, f.Hot)
			dot(strikeDot, head.X, head.Y, 22, 22, WHITE, strike.Dot)
			local c = strike.Column
			if c then
				lay(column, head.X - 3 * c.Width, head.Y - COLUMN[1], 6 * c.Width, COLUMN[1] + COLUMN[2], r.Light.RaysColour, c.Alpha)
			else
				column.Visible = false
			end
		else
			strikeRing.Visible, strikeDot.Visible, column.Visible = false, false, false
		end
		dot(flash, cx, cy, 110, 110, colour:Lerp(WHITE, 0.5), f.Flash)
		local n = f.Name
		nameBox.Visible = n ~= nil
		if n then
			slam.Scale = n.Slam
			nameLabel.TextColor3 = named.Colour:Lerp(WHITE, n.Burn)
			lay(rule, named.Left - 12, named.Baseline + 10, n.Span + 4, 9, r.Rule, n.Landed)
			local g = n.Glint
			glintClip.Visible = g ~= nil
			if g then
				local x0 = named.Left - 10
				glintClip.Position = UDim2.fromOffset(x0, named.Baseline + 12)
				glintClip.Size = UDim2.fromOffset(n.Span, 5)
				dot(glint, g.X - x0, 2.5, 14, 40, WHITE, g.Alpha)
				dot(glintColour, g.X, named.Baseline + 14.5, 22, 9, r.Light.Colour, 0.6 * g.Alpha)
			else
				glintColour.Visible = false
			end
			dot(wash, named.Left + box.X / 2, named.Baseline - size * 0.36, box.X * 0.6, 40, WHITE, n.Wash)
		else
			rule.Visible, glintClip.Visible, glintColour.Visible, wash.Visible = false, false, false, false
		end
		local s = f.Split
		white.Visible = s ~= nil and s.Radius == nil
		if s and s.Radius then
			dot(split, cx, cy, s.Radius, s.Radius, WHITE, s.Alpha)
		else
			split.Visible = false
			if s then
				white.BackgroundTransparency = 1 - math.clamp(s.Alpha, 0, 1)
			end
		end
		if f.Done and not carded then
			carded = true
			if onCard then
				task.spawn(onCard)
			end
		end
	end

	frameAt(0)
	local connection = RunService.RenderStepped:Connect(function()
		frameAt(now())
	end)

	local handle: Handle
	handle = {
		Root = holder,
		Rarity = r,
		Time = now,
		Skip = function(): boolean
			local t = now()
			if not Reveal.SkipOpen(t) or t >= r.Times.Card then
				return false
			end
			start = os.clock() - r.Times.Card
			if pinned then
				pinned = r.Times.Card
			end
			return true
		end,
		Seek = function(t: number?)
			if t == nil and pinned then
				start = os.clock() - pinned
			end
			pinned = t
			if t then
				frameAt(math.min(t, r.Times.Card))
			end
		end,
		Destroy = function()
			connection:Disconnect()
			holder:Destroy()
		end,
	}
	return handle
end

return Stage
