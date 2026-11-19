--!strict
-- HomeTray (client UI): Home's tray (AR43 in B, research's pick of 2026-11-19, 12:56; the dock's graphite, 13:36;
-- docs/ui.md, the dock). The dock's middle cell, Home, opens it: the dock unfolding into a tray over the world and the
-- HUD dimmed edge to edge, all but the dock (home.json's dim: Home.Dim.Side each side of the middle, up to the dock's
-- top), a group a row (Inventory's four, Equipment's three) and Settings its own tall tile at the end, each tile its own screen.
-- It grows out of the Home cell's top with a small overshoot and fades in, and leaves the same way, eased in. A tile's
-- press lights it, the tray folds back toward the cell as the tile's screen rises over it (Kit.Screen's Rise), and that
-- screen's Back sinks it and brings the tray back: the player always sees where a screen came from and goes back to.
-- A tap on the dim closes it, and a screen opened another way does. Every place, tint and time is Config.Hud.Home's, in points from the tray's top
-- left; the images are Modulo's (Config.UIKit's Home*), white masks tinted here, but HomePoint, in its own colours. Each
-- tile is a kit button (Bare: its face is laid here, and squeezes as a face does), so it has the kit's states, a
-- refusal said in a toast, and Button.Press for tests. A tile with no press isn't built yet: it says so when tapped.
--   HomeTray.new(cover, hud, foot, presses)    the tray and its dim in `cover` (the Cover layer, over the HUD), growing
--                                              about the point `foot` up from the middle of `hud`'s foot (the Home
--                                              cell's top); presses[tile name] opens that tile's screen
--   HomeTray.Open(tray), HomeTray.Close(tray)  shown or not, in motion
--   HomeTray.Shown(tray)                       whether it's open, or opening
--   HomeTray.Holds(tray)                       whether a screen its tile opened is open, whose Back comes back here
--   HomeTray.Paint(tray)                       each frame: its motion, and each tile's look from its button's state

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)
local Button = require(script.Parent.Kit.Button)
local Screen = require(script.Parent.Kit.Screen)
local Layers = require(script.Parent.Layers)

-- A place in whole points, to the nearest: Roblox keeps a UDim's offset whole by cutting toward nought, so War Emblems'
-- 314.67 would lay at 314, two thirds of a point off; rounded, no place is half a point off (Seam.Whole's rule).
local function whole(x: number, y: number): UDim2
	return UDim2.fromOffset(math.round(x), math.round(y))
end

local HOME = HudConfig.Home
local PAGES = HudConfig.Voidkin.Chrome.Images -- the Voidkin screen's page icons
local MARGIN = 16 -- room round the tray inside its group for the plate's shadow and the point: a CanvasGroup clips
local SOON = "Soon" -- a tile not built yet: its reason
local GAP = Theme.Size.Gap -- points kept between the tray and what it never covers

type Def = { Name: string, Page: string?, Icon: string, Tall: boolean?, Box: { number }, At: Vector2, Side: number?, Word: Vector2 }
export type Tile = { Def: Def, Button: TextButton, Layers: { [string]: ImageLabel }, Icon: ImageLabel, Word: TextLabel, Shown: string }
type Motion = { At: number, From: number, To: number, Seconds: number, Back: number?, Seen: number, Unseen: number, Fade: number, DimFrom: number, DimTo: number, Done: (() -> ())? }
export type Tray = {
	Frame: Frame,
	Group: CanvasGroup,
	Scale: UIScale,
	Dim: Frame, -- four panels round the dock's rect: Top, Foot, Left, Right
	Panels: { TextButton },
	Dimmed: number, -- the panels' transparency now
	Hud: GuiObject,
	Foot: number,
	Avoid: { string }, -- the HUD's pieces it never covers, by name: the lead card and the currencies (research, AR43)
	Over: boolean, -- laid over the dock, its foot on the dock's: a room too short for it over the dock's top
	Point: ImageLabel,
	Laid: string, -- where the tray and the dim were laid last: the room and the HUD's foot
	Tiles: { [string]: Tile },
	Presses: { [string]: () -> () },
	Open: boolean,
	Motion: Motion?,
	Lit: string?, -- the tile whose press is stepping into its screen, lit until LitUntil
	LitUntil: number,
	From: string?, -- the screen a tile opened, while it's open
}

local HomeTray = {}

local function eased(t: number, back: number?): number
	if back then -- out, past 1 and back: Back's ease of strength `back`
		local u = t - 1
		return 1 + (back + 1) * u * u * u + back * u * u
	end
	return t * t -- in
end

-- The tray and the dim laid in the cover from the HUD's foot, all in the cover's points: the tray's foot on the Home
-- cell's top, its point on the cell, the dim round the dock's rect. Where that would cover the lead card or the
-- currencies (the smallest phones: 107 rendered pixels between the lead card's foot and the dock's top, for a tray of
-- 117), it stands over the dock instead, its foot on the dock's, the same size (its taps and words stay whole): no
-- point, and the dim round the tray itself (research's must-fix on AR43, 2026-11-19).
local function place(tray: Tray)
	local cover = tray.Dim.Parent :: GuiObject
	local hud = tray.Hud
	local scale = Layers.Scale()
	local origin = cover.AbsolutePosition
	local kept: { { number } } = {} -- x0, y0, x1, y1, a gap round each
	local seen: { string } = {}
	for _, name in tray.Avoid do
		local piece = hud:FindFirstChild(name)
		if piece and piece:IsA("GuiObject") and piece.Visible then
			local at, size = (piece.AbsolutePosition - origin) / scale, piece.AbsoluteSize / scale
			table.insert(kept, { at.X - GAP, at.Y - GAP, at.X + size.X + GAP, at.Y + size.Y + GAP })
			table.insert(seen, `{piece.AbsolutePosition}{piece.AbsoluteSize}`)
		end
	end
	local key = `{cover.AbsoluteSize} {hud.AbsolutePosition} {hud.AbsoluteSize} {scale} {table.concat(seen, " ")}`
	if key == tray.Laid then
		return
	end
	tray.Laid = key
	local size = HOME.Size
	local wide, tall = cover.AbsoluteSize.X / scale, cover.AbsoluteSize.Y / scale
	local foot = (hud.AbsolutePosition.Y + hud.AbsoluteSize.Y - origin.Y) / scale
	local middle = (hud.AbsolutePosition.X + hud.AbsoluteSize.X / 2 - origin.X) / scale
	local top = foot - tray.Foot -- the dock's top
	local function clear(bottom: number): boolean -- the tray's body, its foot at `bottom`, covers none of them
		local x0, x1, y0 = middle - size.X / 2, middle + size.X / 2, bottom - size.Y
		for _, box in kept do
			if x0 < box[3] and x1 > box[1] and y0 < box[4] and bottom > box[2] then
				return false
			end
		end
		return true
	end
	local under = foot - Theme.Size.Pad -- the dock's foot, about
	local over = not clear(top - HOME.Above) and clear(under)
	tray.Over = over
	tray.Point.Visible = not over
	local frameFoot = if over then under + HOME.Above else top
	tray.Frame.Position = whole(middle, frameFoot)
	-- The dim's hole: the dock's rect, Side each side of its middle up to its top; over the dock, the tray's own rect.
	local left, right, holeTop, holeFoot = middle - HOME.Dim.Side, middle + HOME.Dim.Side, top, foot
	if over then
		left, right, holeTop, holeFoot = middle - size.X / 2, middle + size.X / 2, under - size.Y, under
	end
	local high = holeFoot - holeTop
	local boxes = { { 0, 0, wide, holeTop }, { 0, holeFoot, wide, tall - holeFoot }, { 0, holeTop, left, high }, { right, holeTop, wide - right, high } }
	for index, panel in tray.Panels do
		local box = boxes[index]
		panel.Position = whole(box[1], box[2])
		panel.Size = whole(math.max(box[3], 0), math.max(box[4], 0))
	end
end

local function dimmed(tray: Tray, transparency: number)
	tray.Dimmed = transparency
	for _, panel in tray.Panels do
		panel.BackgroundTransparency = transparency
	end
end

local function move(tray: Tray, motion: Motion)
	tray.Motion = motion
	HomeTray.Paint(tray)
end

-- One layer of a tile, as home.json lays it: a sliced row image in the tile's box at its own height, the tall one at its
-- own size, each grown by its Pad on every side.
local function lay(face: Frame, image: string, name: string, box: { number }, z: number): ImageLabel
	local record = UIKit.Images[image]
	local made = Skin.Lay(face, image, { Name = name, Z = z })
	if record.Cut then
		Skin.Set(made, image, { X = 0, Y = 0, W = box[3], H = box[4] })
	else
		made.Size = whole(box[3] + 2 * record.Pad, box[4] + 2 * record.Pad)
		made.Position = whole(-record.Pad, -record.Pad)
	end
	return made
end

local function word(parent: Instance, name: string, said: string, at: Vector2, wide: number, colour: Color3): TextLabel
	local label = Text.new({
		Name = name,
		Size = HOME.Words,
		Font = Theme.Font.Strong,
		Colour = colour,
		Align = Enum.TextXAlignment.Center,
		Box = whole(wide, HOME.Words + 6),
		Position = whole(at.X, at.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = parent,
	})
	label.Text = said
	return label
end

-- A tile's look: at rest, pressed (held, or lit while its screen opens), and whether it's built yet.
local function paint(tile: Tile, now: string)
	local layers = tile.Layers
	local pressed = now == "Pressed"
	local look = if pressed then HOME.Pressed else HOME.Rest
	Skin.Tint(layers.Fill, look.Fill)
	layers.Edge.ImageColor3 = look.Edge
	layers.Edge.ImageTransparency = if pressed then 0 else HOME.Rest.EdgeT
	layers.Glint.Visible = not pressed
	layers.Glow.Visible = pressed
	local faint = if now == "Soon" then HOME.Soon else 0
	tile.Icon.ImageTransparency = faint
	tile.Word.TextTransparency = faint
	tile.Button:SetAttribute("Look", now)
	tile.Shown = now
end

local function look(tray: Tray, tile: Tile): string
	local state = Button.State(tile.Button)
	if tray.Lit == tile.Def.Name and os.clock() < tray.LitUntil then
		return "Pressed"
	elseif state == "Disabled" then
		return "Soon"
	elseif state == "Pressed" or state == "Waiting" then
		return "Pressed"
	end
	return "Rest"
end

-- A tile's press: lit for Lit, then the tray folds back toward the cell as the screen rises over it, RiseAt in.
local function step(tray: Tray, def: Def)
	local press = tray.Presses[def.Name]
	if press == nil then
		return
	end
	if not tray.Open then -- pressed with the tray away (Button.Press, for tests): its screen, with no step and no way back
		press()
		return
	end
	local s = HOME.Step
	tray.Lit, tray.LitUntil = def.Name, os.clock() + s.Lit
	task.delay(s.Lit, function()
		HomeTray.Close(tray, s.LeaveTo, s.Leave)
		task.delay(s.RiseAt, function()
			Screen.Rise({ From = s.RiseFrom, Seconds = s.Rise, Cover = s.Cover, Sink = s.Sink, Uncover = s.Uncover })
			press()
			Screen.Rise(nil) -- spent, or left unspent when nothing opened
			tray.From = Screen.Current()
		end)
	end)
end

function HomeTray.new(cover: Instance, hud: GuiObject, foot: number, presses: { [string]: () -> () }, avoid: { string }?): Tray
	local size = HOME.Size
	local frame = Instance.new("Frame")
	frame.Name = "HomeTray"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 1) -- it grows about the Home cell's top middle (place)
	frame.Size = whole(size.X, size.Y + HOME.Above)
	frame.ZIndex = 61 -- over its dim
	frame.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local group = Instance.new("CanvasGroup")
	group.Name = "Group"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.Position = whole(-MARGIN, -MARGIN)
	group.Size = whole(size.X + MARGIN * 2, size.Y + HOME.Above + MARGIN * 2)
	group.GroupTransparency = 1
	group.Parent = frame
	local body = Instance.new("Frame")
	body.Name = "Tray"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Position = whole(MARGIN, MARGIN)
	body.Size = whole(size.X, size.Y)
	body.Active = true -- a tap on the tray stays on it
	body.Parent = group
	-- The plate: the kit's panel in the dock body's graphite, opaque (the world never shows through it).
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundTransparency = 1
	plate.BorderSizePixel = 0
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = body
	local skin = Skin.Of(plate)
	Skin.Lay(skin, "PanelShadow", { Name = "Shadow", Z = 1 })
	Skin.Lay(skin, "PanelFill", { Name = "Fill", Tint = HOME.Plate.Fill, Alpha = 1, Z = 2 })
	Skin.Lay(skin, "PanelEdge", { Name = "Edge", Tint = HOME.Plate.Edge, Alpha = 0.95, Z = 3 })
	local point = Skin.Lay(body, "HomePoint", { Name = "Point", Z = 2 })
	point.AnchorPoint = Vector2.new(HOME.Point.X / point.Size.X.Offset, HOME.Point.Y / point.Size.Y.Offset)
	point.Position = whole(size.X / 2, size.Y)
	local rule = Instance.new("Frame")
	rule.Name = "Rule"
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = HOME.Rule.Colour
	rule.BackgroundTransparency = HOME.Rule.T
	rule.AnchorPoint = Vector2.new(0.5, 0.5)
	rule.Position = whole(HOME.Rule.Middle.X, HOME.Rule.Middle.Y)
	rule.Size = whole(1, HOME.Rule.Long)
	rule.Rotation = HOME.Rule.Rotation
	rule.ZIndex = 2
	rule.Parent = body
	for _, heading in HOME.Headings do
		local record = UIKit.Images[heading.Mark] or PAGES[heading.Mark]
		local mark = Skin.LayOwn(body, record, `{heading.Group}Mark`, { X = heading.At.X - heading.Side / 2, Y = heading.At.Y - heading.Side / 2, Size = heading.Side, Tint = HOME.Colours.Mark, Z = 2 })
		mark:SetAttribute("Kit", heading.Mark)
		word(body, `{heading.Group}Heading`, heading.Group, heading.Word, 96, HOME.Colours.Heading).ZIndex = 2
	end
	local dim = Instance.new("Frame")
	dim.Name = "HomeDim"
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 60 -- over a screen's cover, should one still be fading
	dim.Visible = false
	dim.Parent = cover
	local panels: { TextButton } = {}
	for _, name in { "Top", "Foot", "Left", "Right" } do
		local panel = Instance.new("TextButton")
		panel.Name = name
		panel.Text = ""
		panel.AutoButtonColor = false
		panel.BorderSizePixel = 0
		panel.BackgroundColor3 = HOME.Dim.Colour
		panel.BackgroundTransparency = 1
		panel.Parent = dim
		table.insert(panels, panel)
	end
	local tray: Tray = {
		Frame = frame,
		Group = group,
		Scale = scale,
		Dim = dim,
		Panels = panels,
		Dimmed = 1,
		Hud = hud,
		Foot = foot,
		Avoid = avoid or {},
		Over = false,
		Point = point,
		Laid = "",
		Tiles = {},
		Presses = presses,
		Open = false,
		Motion = nil,
		Lit = nil,
		LitUntil = 0,
		From = nil,
	}
	for _, each in HOME.Tiles do
		local def = each :: Def
		local box = def.Box
		local button = Button.new({
			Name = def.Name,
			Text = "",
			Bare = true,
			Size = whole(box[3], box[4]),
			Position = whole(box[1], box[2]),
			Parent = body,
			OnPress = function()
				step(tray, def)
			end,
		})
		button.ZIndex = 3
		local face = Skin.Of(button)
		local kind = if def.Tall then "HomeTall" else "HomeTile"
		local layers = {
			Glow = lay(face, `{kind}Glow`, "Glow", box, 1),
			Fill = lay(face, `{kind}Fill`, "Fill", box, 2),
			Edge = lay(face, `{kind}Edge`, "Edge", box, 3),
			Glint = lay(face, `{kind}Glint`, "Glint", box, 4),
		}
		layers.Glint.ImageColor3 = HOME.Rest.Glint
		layers.Glint.ImageTransparency = HOME.Rest.GlintT
		layers.Glow.ImageColor3 = HOME.Pressed.Glow
		layers.Glow.ImageTransparency = HOME.Pressed.GlowT
		local side = def.Side or HOME.Side
		local record = UIKit.Images[def.Icon] or PAGES[def.Icon]
		local icon = Skin.LayOwn(face, record, "Icon", { X = def.At.X - box[1] - side / 2, Y = def.At.Y - box[2] - side / 2, Size = side, Tint = HOME.Colours.Ink, Z = 5 })
		icon:SetAttribute("Kit", def.Icon)
		local said = word(face, "Word", def.Name, Vector2.new(def.Word.X - box[1], def.Word.Y - box[2]), box[3], HOME.Colours.Ink)
		said.ZIndex = 6
		local tile: Tile = { Def = def, Button = button, Layers = layers, Icon = icon, Word = said, Shown = "" }
		tray.Tiles[def.Name] = tile
		if presses[def.Name] == nil then
			Button.Set(button, { Disabled = SOON })
		end
		paint(tile, look(tray, tile))
	end
	frame.Parent = cover
	for _, panel in panels do
		panel.Activated:Connect(function()
			HomeTray.Close(tray)
		end)
	end
	-- A tile's screen closed by its Back brings the tray back, BackAt after the screen begins to sink.
	Screen.Closed:Connect(function(name: string, how: string?)
		if tray.From ~= name then
			return
		end
		tray.From = nil
		if how == "Back" then
			task.delay(HOME.Step.BackAt, function()
				if Screen.Current() == nil then
					HomeTray.Open(tray)
				end
			end)
		end
	end)
	return tray
end

function HomeTray.Open(tray: Tray)
	if tray.Open then
		return
	end
	tray.Open = true
	tray.Lit = nil
	place(tray)
	tray.Frame.Visible = true
	tray.Group.Interactable = true
	tray.Dim.Visible = true
	tray.Dim.Interactable = true
	local open = HOME.Open
	local from = if tray.Motion then tray.Scale.Scale else open.From
	move(tray, { At = os.clock(), From = from, To = 1, Seconds = open.Grow, Back = open.Back, Seen = tray.Group.GroupTransparency, Unseen = 0, Fade = open.Fade, DimFrom = tray.Dimmed, DimTo = 1 - HOME.Dim.Amount })
end

-- It leaves to `to` of its size (Home.Open.From) in `seconds` (Home.Open.Leave), eased in, fading as it goes.
function HomeTray.Close(tray: Tray, to: number?, seconds: number?)
	if not tray.Open then
		return
	end
	tray.Open = false
	tray.Group.Interactable = false
	tray.Dim.Interactable = false -- taps pass through it at once
	local open = HOME.Open
	local leave = seconds or open.Leave
	move(tray, {
		At = os.clock(),
		From = tray.Scale.Scale,
		To = to or open.From,
		Seconds = leave,
		Back = nil,
		Seen = tray.Group.GroupTransparency,
		Unseen = 1,
		Fade = leave,
		DimFrom = tray.Dimmed,
		DimTo = 1,
		Done = function()
			tray.Frame.Visible = false
			tray.Dim.Visible = false
		end,
	})
end

function HomeTray.Shown(tray: Tray): boolean
	return tray.Open
end

function HomeTray.Holds(tray: Tray): boolean
	return tray.From ~= nil and Screen.Current() == tray.From
end

function HomeTray.Paint(tray: Tray)
	local motion = tray.Motion
	if motion then
		local t = os.clock() - motion.At
		local share = math.clamp(t / math.max(motion.Seconds, 1e-3), 0, 1)
		local shown = math.clamp(t / math.max(motion.Fade, 1e-3), 0, 1)
		tray.Scale.Scale = motion.From + (motion.To - motion.From) * eased(share, motion.Back)
		tray.Group.GroupTransparency = motion.Seen + (motion.Unseen - motion.Seen) * (if motion.Back then 1 - (1 - shown) ^ 2 else shown * shown)
		-- The dim eases with it: out while it opens, in while it leaves.
		local d = math.clamp(t / HOME.Dim.Seconds, 0, 1)
		dimmed(tray, motion.DimFrom + (motion.DimTo - motion.DimFrom) * (if motion.Back then 1 - (1 - d) ^ 2 else d * d))
		if share >= 1 and shown >= 1 and d >= 1 then
			tray.Motion = nil
			if motion.Done then
				motion.Done()
			end
		end
	end
	if not tray.Frame.Visible then
		return
	end
	if tray.Open and Screen.Current() ~= nil then -- a screen opened another way (the Map's menu): it makes way
		HomeTray.Close(tray)
	end
	place(tray)
	for _, tile in tray.Tiles do
		local now = look(tray, tile)
		if now ~= tile.Shown then
			paint(tile, now)
		end
	end
end

return HomeTray
