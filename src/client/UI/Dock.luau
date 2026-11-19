--!strict
-- Dock (client UI): the dock of three icons (docs/ui.md, the HUD; docs/asset-requests.md, AR30, "The dock"): one dark
-- channel at the foot's middle, the bag's cell rising over the Base and Map wings. Each cell is the seam's dark glass lit
-- from its foot in its room's colour (Base in Power's yellow, the bag in the seam's Light, the Map in its red), its icon
-- in Text; every place, size and light is Config.Hud.Make.Dock's, in points from the dock's frame. Each cell's tap is a
-- kit button (Button, Bare and Still: the dock draws its own press), so it has the kit's states, an icon's refusal said
-- in a toast, and Button.Press for tests. The dock paints each cell from its button's state, its light at 1 - L/Top:
--   rest      L Rest
--   pressed   L Pressed; nothing sinks (under a thumb a sink is hidden, so the light carries the press)
--   open      while its screen is (the button Selected): L Open
--   dim       while it can't be used (the button Disabled): no light, its foot dim, its icon in Faint
--   charge    while a charging cell's fill runs (Dock.Charges): its glass in ink, no light, the fill rising over it
-- Calling (Dock.Pip, something new), at rest its light is L Calling, and in any state its whole edge is lit in its colour
-- and the pip stands over its far corner on an ink ring. A touch held LongPress seconds shows the cell's word over it, and
-- lifting it then doesn't press (Config.Hud.Dock). A pointer over a cell at rest lifts it and raises its light toward a
-- press's, and after a moment shows its word; a pad's selection wears its rim, the edge in Light (TR20, Kit.Hover). A cell
-- its owner gives a mood keeps it over its button's states, still tappable, so a tap can say why (TR19, the Base cell):
--   quiet     nothing to do here: L Quiet, its icon in Soft
--   dim       refused for now: as a disabled cell
-- Over a cell's glass, under its icon, two of its owner's measures in the glass's own shape: a fill rising from its foot
-- (a charge), and a veil over the share still to come, swept away left to right (a cooldown).
--   Dock.new(parent, presses)          the dock; presses[name] is each cell's OnPress (Base, Home, Map: its word Play)
--   Dock.Pip(dock, name, on)           something new on a cell: it calls
--   Dock.Mood(dock, name, mood?)       "Quiet", "Dim", or nil for its button's own look
--   Dock.Reason(dock, name, why?)      why it's refused, its word on a long press or a hover; nil for its name
--   Dock.Fill(dock, name, share?)      a charge's share, 0 to 1, in white under a brighter rising edge; nil or 0 shows
--                                      none
--   Dock.Charges(dock, name, on)       its fill is a charge: the cell wears its ink while the fill runs, and a press alone
--                                      shows nothing (TR19's Base cell: the tap is the charge's first frame)
--   Dock.Sweep(dock, name, share?)     a cooldown's run, 0 to 1; nil or 1 shows none
--   Dock.Shake(dock, name)             a refused tap: the cell shakes Shake points side to side over Shook seconds
--   Dock.Hold(button, down)            a touch going down on a cell's button or coming off, as a finger's (for tests)
--   Dock.Paint(dock)                   each frame: a cell repaints only when its look changes

local ContentProvider = game:GetService("ContentProvider")
local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)
local Button = require(script.Parent.Kit.Button)
local Hover = require(script.Parent.Kit.Hover)
local Panel = require(script.Parent.Kit.Panel)

type Cell = typeof(HudConfig.Make.Dock.Cells[1])

export type Tile = {
	Def: Cell,
	Button: TextButton,
	Layers: { [string]: ImageLabel },
	Word: TextLabel,
	New: boolean,
	Shown: string, -- the look painted last
	HeldAt: number?, -- a touch's moment, while it's down
	Long: boolean, -- the touch passed LongPress: its lift doesn't press
	WordUntil: number,
	Mood: Mood?,
	Rest: { [string]: UDim2 }, -- each layer's place at rest
	Shift: number, -- the shake's offset now, in points
	ShakeAt: number?,
	Shares: { [string]: number }, -- the fill's and the veil's shown last
	Hover: number, -- the pointer's share over it (Kit.Hover)
	Pad: boolean, -- a pad's selection
	Reason: string?, -- why it's refused, its owner's words, shown as its word
	WordEpoch: number, -- the faces' epoch its plate was fitted at (Text.Epoch)
	Charges: boolean, -- its fill is a charge: ink from the tap while it runs, and no press of its own (Dock.Charges)
}
export type Mood = "Quiet" | "Dim"
export type Dock = { Frame: Frame, Tiles: { [string]: Tile } }

local Dock = {}

local SEAM = UIKit.Palettes.Seam
local LIGHT, INK = SEAM.Light :: Color3, SEAM.Ink :: Color3
local MAKE = HudConfig.Make
-- One stack for the whole dock, as the make lays it (tools/blender/button_make.py, check_cut): the shadow, the channel
-- and its edge; each cell's glass, light and foot, the owner's measures over the glass, its icon, its call and rim, its
-- pip; the taps over all, and the words over the taps.
local Z = {
	Shadow = 1,
	Body = 2,
	Edge = 3,
	Glass = 4,
	Light = 5,
	Foot = 6,
	Fill = 7,
	Veil = 8,
	Mark = 9,
	Call = 10,
	Rim = 11,
	PipGlow = 12,
	Pip = 13,
	Tap = 16,
	Word = 17,
}
local WORD = { Tall = 20, Across = 7 } -- the word's plate, authored points: its height, and its words' room either side
local OVER_HUD = 10 -- the dock over the HUD's other pieces in its layer (the chip above it), so its word stands over them

-- Each cell by its button, for Dock.Hold. Held until the dock is destroyed, as the kit's buttons are (Button's note).
local byButton: { [TextButton]: Tile } = {}

-- The rooms' rule (AR30): a cell lit in the colour of the room it opens.
local function hue(name: string): Color3
	return if name == "Base" then MAKE.Light.Power elseif name == "Map" then MAKE.Light.Map else LIGHT
end

-- Each cell's icon, the seam dock's own.
local function icon(name: string): (UIKit.Image, string)
	return MAKE.Images[`DockSeam{name}`], `DockSeam{name}`
end

local function look(tile: Tile): string
	local state = Button.State(tile.Button)
	if state == "Disabled" then
		return "Dim"
	elseif tile.Mood then
		return tile.Mood
	elseif tile.Charges and (tile.Shares.Fill or -1) > 0 then
		return "Charge"
	elseif (state == "Pressed" or state == "Waiting") and not tile.Charges then
		return "Pressed"
	elseif state == "Selected" then
		return "Open"
	end
	return "Rest"
end

-- A place or a size of x, y points, as Scale against the dock's frame: a UDim's Offset is a whole number, so 30.4 points
-- there would draw as 30 (the dock's self-test, 2026-11-15).
local function points(x: number, y: number): UDim2
	local frame = MAKE.Dock.Frame
	return UDim2.fromScale(x / frame.X, y / frame.Y)
end

-- One of the make's images at x, y, w by h points.
local function put(holder: GuiObject, record: UIKit.Image, name: string, x: number, y: number, w: number, h: number, z: number, tint: Color3, alpha: number?): ImageLabel
	local image = Skin.LayOwn(holder, record, name, { Z = z, Tint = tint, Alpha = alpha })
	image.Position = points(x, y)
	image.Size = points(w, h)
	return image
end

-- The glass in the seam's Panel gradient, top to foot; in ink while a charge runs.
local function glaze(glass: ImageLabel, inked: boolean)
	if inked then
		Skin.Tint(glass, HudConfig.Dock.Charge.Ink)
	else
		Skin.Tint(glass, SEAM.Panel)
	end
end

-- Every layer at its place with the shake's offset, lifted by a pointer at rest.
local function place(tile: Tile)
	local lift = if tile.Shown == "Rest" then HudConfig.Motion.Hover.Lift * tile.Hover else 0
	local shift = points(tile.Shift, -lift)
	for name, layer in tile.Layers do
		local rest = tile.Rest[name]
		if rest then
			layer.Position = rest + shift
		end
	end
end

local function paint(tile: Tile, now: string)
	local make = MAKE.Dock
	local layers = tile.Layers
	local l = (make.L :: { [string]: number })[now] or make.L.Rest
	if now == "Rest" then
		-- Calling, brighter; a pointer over it (TR20) raises its light toward a press's by Hover.Halo of its share.
		l = if tile.New then make.L.Calling else make.L.Rest
		l += math.max(make.L.Pressed - l, 0) * HudConfig.Motion.Hover.Halo * tile.Hover
	end
	layers.Light.ImageTransparency = math.clamp(1 - l / make.Top, 0, 1)
	glaze(layers.Glass, now == "Charge")
	layers.Foot.ImageTransparency = if now == "Dim" then make.DimFoot else 0
	layers.Mark.ImageColor3 = if now == "Dim" then SEAM.Faint elseif now == "Quiet" then SEAM.Soft else SEAM.Text
	layers.Call.Visible = tile.New
	local rim = tile.Pad and tile.Hover > 0 and now ~= "Open"
	layers.Rim.Visible = rim
	layers.Rim.ImageTransparency = if rim then 1 - tile.Hover else 1
	tile.Button:SetAttribute("Look", now)
	tile.Shown = now
	place(tile)
end

-- A hard edge at `at` along a gradient, as transparencies: `before` short of it, `after` from it on.
local function edge(at: number, before: number, after: number): NumberSequence
	if at <= 1e-3 then
		return NumberSequence.new(after)
	elseif at >= 1 - 1e-3 then
		return NumberSequence.new(before)
	end
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, before),
		NumberSequenceKeypoint.new(at, before),
		NumberSequenceKeypoint.new(at + 1e-3, after),
		NumberSequenceKeypoint.new(1, after),
	})
end

-- The glass's own shape over it in `colour`, under its icon, its gradient turned `rotation`: made the first time it's
-- asked for.
local function overlay(tile: Tile, name: string, z: number, colour: Color3, rotation: number): ImageLabel
	local made = tile.Layers[name]
	if made then
		return made
	end
	local glass = tile.Layers.Glass
	local layer = Skin.LayOwn(glass.Parent :: GuiObject, MAKE.Images[`DockSeamGlass{tile.Def.Kind}`], `{tile.Def.Name}{name}`, { Z = z, Tint = colour })
	layer.Size = glass.Size
	layer.Visible = false
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Parent = layer
	tile.Layers[name] = layer
	tile.Rest[name] = tile.Rest.Glass
	place(tile)
	return layer
end

-- Shows a share of an overlay: `covered` is the gradient's edge, the share past it drawn at `alpha`.
local function measure(tile: Tile, name: string, z: number, colour: Color3, rotation: number, share: number, shows: boolean, covered: number, alpha: number)
	if tile.Shares[name] == (if shows then share else -1) then
		return
	end
	tile.Shares[name] = if shows then share else -1
	tile.Button:SetAttribute(name, if shows then share else nil)
	if not shows and tile.Layers[name] == nil then
		return
	end
	local layer = overlay(tile, name, z, colour, rotation)
	layer.Visible = shows
	if shows then
		(layer:FindFirstChildOfClass("UIGradient") :: UIGradient).Transparency = edge(covered, 1, 1 - alpha)
	end
end

function Dock.new(parent: Instance, presses: { [string]: () -> ...any }): Dock
	local make = MAKE.Dock
	local images = MAKE.Images
	local box, at, size, out = make.Box, make.At, make.Frame, make.Out
	-- Today's box, which the HUD places and the chip stands over; the dock's own frame inside it.
	local frame = Instance.new("Frame")
	frame.Name = "Dock"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(box.X, box.Y)
	local seam = Instance.new("Frame")
	seam.Name = "Seam"
	seam.BackgroundTransparency = 1
	seam.Position = UDim2.fromScale(at.X / box.X, at.Y / box.Y)
	seam.Size = UDim2.fromScale(size.X / box.X, size.Y / box.Y)
	seam.Parent = frame
	local s = make.Shadow
	put(seam, images.DockSeamShadow, "DockShadow", -s, -s, size.X + 2 * s, size.Y + 2 * s, Z.Shadow, SEAM.Channel, 1 - make.ShadowT)
	put(seam, images.DockSeamBody, "DockBody", 0, 0, size.X, size.Y, Z.Body, SEAM.Channel, 1 - make.BodyT)
	put(seam, images.DockSeamEdge, "DockEdge", 0, 0, size.X, size.Y, Z.Edge, SEAM.Edge)
	local dock: Dock = { Frame = frame, Tiles = {} }
	for _, def in make.Cells do
		local name, kind = def.Name, def.Kind
		local glass, g, colour = (make.Glass :: { [string]: Vector2 })[kind], def.Glass, hue(name)
		local lx, ly, lw, lh = g.X - out, g.Y - out, glass.X + 2 * out, glass.Y + 2 * out
		local mark, kit = icon(name)
		local pip = make.Pip
		local function ring(record: UIKit.Image, label: string, across: number, z: number, tint: Color3, alpha: number?): ImageLabel
			return put(seam, record, label, def.Pip.X - across / 2, def.Pip.Y - across / 2, across, across, z, tint, alpha)
		end
		local layers = {
			Glass = put(seam, images[`DockSeamGlass{kind}`], "Glass", g.X, g.Y, glass.X, glass.Y, Z.Glass, SEAM.Channel, 1 - make.GlassT),
			Light = put(seam, images[`DockSeamLight{kind}`], "Light", lx, ly, lw, lh, Z.Light, colour),
			Foot = put(seam, images[`DockSeamFoot{kind}`], "Foot", g.X, g.Y, glass.X, glass.Y, Z.Foot, colour),
			Mark = put(seam, mark, "Mark", def.Icon.X - def.Side / 2, def.Icon.Y - def.Side / 2, def.Side, def.Side, Z.Mark, SEAM.Text),
			Call = put(seam, images[`DockSeamCall{kind}`], "Call", lx, ly, lw, lh, Z.Call, colour),
			Rim = put(seam, images[`DockSeamCall{kind}`], "Rim", lx, ly, lw, lh, Z.Rim, LIGHT),
			PipGlow = ring(images.SeamPipGlow, "PipGlow", pip.Glow, Z.PipGlow, colour, 1 - pip.GlowT),
			Pip = ring(images.SeamMark, "Pip", pip.Rings[1], Z.Pip, INK),
			PipHue = ring(images.SeamMark, "PipHue", pip.Rings[2], Z.Pip + 1, colour),
			PipLight = ring(images.SeamMark, "PipLight", pip.Rings[3], Z.Pip + 2, LIGHT),
		}
		glaze(layers.Glass, false)
		layers.Mark:SetAttribute("Kit", kit)
		for layer, image in layers do
			image.Name = `{name}{layer}`
		end
		for _, hidden in { layers.Call, layers.Rim, layers.PipGlow, layers.Pip, layers.PipHue, layers.PipLight } do
			hidden.Visible = false
		end
		-- The word on a plate of its own, the toasts' plate made small, centred over its glass (research's verdict on TR20,
		-- fix 1: bare text with a stroke ran into the chip above). The dock draws over the HUD's other pieces, so while it
		-- shows it may cover the chip: the pointer says where the player's eye is. It moves nothing.
		local plate = Panel.new({
			Name = `{name}WordPlate`,
			Size = UDim2.fromOffset(WORD.Across * 2 + 40, WORD.Tall),
			Position = points(g.X + glass.X / 2, g.Y - HudConfig.Dock.Rise),
			AnchorPoint = Vector2.new(0.5, 1),
			Parent = seam,
		})
		plate.ZIndex = Z.Word
		plate.Visible = false
		Panel.Pad(plate, 0, WORD.Across)
		local word = Text.new({
			Name = `{name}Word`,
			Size = Theme.Text.Caption,
			Font = Theme.Font.Strong,
			Colour = UIKit.Palettes.Graphite.Text,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromScale(1, 1),
			Parent = plate,
		})
		word.Text = (def :: any).Word or name
		word.ZIndex = 2
		word.Visible = false
		local tile: Tile
		-- The tap: the cell's column (AR30's touch), a wing's 52 tall and the bag's 62, so each holds Theme.Size.Touch at
		-- the scale's floor.
		local tap = def.Tap
		local button = Button.new({
			Name = name,
			Text = "",
			Bare = true,
			Still = true,
			Size = points(tap[3], tap[4]),
			Position = points(tap[1], tap[2]),
			Parent = seam,
			OnPress = function(): ...any
				if tile.Long then -- a long press showed the word: its lift isn't a tap, and the word stays a moment
					tile.Long = false
					tile.WordUntil = os.clock() + 0.6
					return nil
				end
				return (presses[name] or function() end)()
			end,
		})
		button.ZIndex = Z.Tap
		tile = {
			Def = def,
			Button = button,
			Layers = layers,
			Word = word,
			New = false,
			Shown = "",
			HeldAt = nil :: number?,
			Long = false,
			WordUntil = 0,
			Mood = nil :: Mood?,
			Rest = {},
			Shift = 0,
			ShakeAt = nil :: number?,
			Shares = {},
			Hover = 0,
			Pad = false,
			Reason = nil :: string?,
			WordEpoch = -1,
			Charges = false,
		}
		for layer, image in layers do
			tile.Rest[layer] = image.Position
		end
		byButton[button] = tile
		Hover.On(button, function(share: number, pad: boolean)
			tile.Hover, tile.Pad = share, pad
			if tile.Shown ~= "" then
				paint(tile, tile.Shown)
			end
		end)
		local function pointer(input: InputObject): boolean
			return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		end
		button.InputBegan:Connect(function(input: InputObject)
			if pointer(input) then
				Dock.Hold(button, true)
			end
		end)
		button.InputEnded:Connect(function(input: InputObject)
			if pointer(input) then
				Dock.Hold(button, false)
			end
		end)
		button.Destroying:Connect(function()
			byButton[button] = nil
		end)
		paint(tile, "Rest")
		dock.Tiles[name] = tile
	end
	frame.ZIndex = OVER_HUD
	frame.Parent = parent
	-- Every image the dock lays, loaded before it first shows: a call's edge and pip come in only when something's new,
	-- and unloaded they'd draw nothing for a moment (research's verdict on TR19, the black frame of an unloaded twin).
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ frame })
		end)
	end)
	return dock
end

function Dock.Hold(button: TextButton, down: boolean)
	local tile = byButton[button]
	if tile == nil then
		return
	end
	if down then
		tile.HeldAt, tile.Long = os.clock(), false
	else
		tile.HeldAt = nil
		if tile.Long then
			tile.WordUntil = os.clock() + 0.6 -- the word stays a moment after the lift
		end
	end
end

function Dock.Pip(dock: Dock, name: string, on: boolean)
	local tile = dock.Tiles[name]
	if tile and tile.New ~= on then
		tile.New = on
		for _, layer in { "PipGlow", "Pip", "PipHue", "PipLight" } do
			tile.Layers[layer].Visible = on
		end
		tile.Button:SetAttribute("New", on)
		if tile.Shown ~= "" then
			paint(tile, tile.Shown)
		end
	end
end

-- Why a cell is refused, in its owner's words: its word says it on a long press or a hover (TR20). Nil for its name.
function Dock.Reason(dock: Dock, name: string, why: string?)
	local tile = dock.Tiles[name]
	if tile then
		tile.Reason = why
	end
end

function Dock.Mood(dock: Dock, name: string, mood: Mood?)
	local tile = dock.Tiles[name]
	if tile and tile.Mood ~= mood then
		tile.Mood = mood
		tile.Button:SetAttribute("Mood", mood)
	end
end

-- The fill rises from the glass's foot: its gradient runs top to bottom, so the share past 1 - share is lit, in Colour
-- at Alpha under a band Edge of the glass's height in Bright at full (research's verdict on TR19, corrected 2026-11-15:
-- white over the cell's ink, high contrast, apart from the cooldown's sideways veil; a stand-in until the palette is
-- picked).
function Dock.Fill(dock: Dock, name: string, share: number?)
	local tile = dock.Tiles[name]
	if tile then
		local s = math.clamp(share or 0, 0, 1)
		local charge = HudConfig.Dock.Charge
		local unchanged = tile.Shares.Fill == (if s > 0 then s else -1)
		measure(tile, "Fill", Z.Fill, Color3.new(1, 1, 1), 90, s, s > 0, 1 - s, charge.Alpha)
		local layer = tile.Layers.Fill
		if unchanged or layer == nil or s <= 0 then
			return
		end
		local top = math.min(1 - s, 0.995) -- keypoints stay in order at the thinnest fill
		local band = math.min(math.max(top + charge.Edge, top + 2e-3), 1)
		local colours = { ColorSequenceKeypoint.new(0, charge.Bright) }
		local alphas = { NumberSequenceKeypoint.new(0, if top > 1e-3 then 1 else 0) }
		if top > 1e-3 then
			table.insert(alphas, NumberSequenceKeypoint.new(top, 1))
			table.insert(alphas, NumberSequenceKeypoint.new(math.min(top + 1e-3, 1 - 2e-3), 0))
		end
		if band < 1 - 2e-3 then
			table.insert(colours, ColorSequenceKeypoint.new(band, charge.Bright))
			table.insert(colours, ColorSequenceKeypoint.new(band + 1e-3, charge.Colour))
			table.insert(colours, ColorSequenceKeypoint.new(1, charge.Colour))
			table.insert(alphas, NumberSequenceKeypoint.new(band, 0))
			table.insert(alphas, NumberSequenceKeypoint.new(band + 1e-3, 1 - charge.Alpha))
			table.insert(alphas, NumberSequenceKeypoint.new(1, 1 - charge.Alpha))
		else
			table.insert(colours, ColorSequenceKeypoint.new(1, charge.Bright))
			table.insert(alphas, NumberSequenceKeypoint.new(1, 0))
		end
		local gradient = layer:FindFirstChildOfClass("UIGradient") :: UIGradient
		gradient.Color = ColorSequence.new(colours)
		gradient.Transparency = NumberSequence.new(alphas)
	end
end

function Dock.Charges(dock: Dock, name: string, on: boolean)
	local tile = dock.Tiles[name]
	if tile then
		tile.Charges = on
	end
end

-- The veil covers what's still to come, from the run's edge to the glass's right, in the seam's ink.
function Dock.Sweep(dock: Dock, name: string, share: number?)
	local tile = dock.Tiles[name]
	if tile then
		local s = math.clamp(share or 1, 0, 1)
		measure(tile, "Veil", Z.Veil, INK, 0, s, s < 1, s, HudConfig.Dock.Veil)
	end
end

function Dock.Shake(dock: Dock, name: string)
	local tile = dock.Tiles[name]
	if tile then
		tile.ShakeAt = os.clock()
		tile.Button:SetAttribute("Shakes", (tonumber(tile.Button:GetAttribute("Shakes")) or 0) + 1)
	end
end

function Dock.Paint(dock: Dock)
	local now = os.clock()
	local shook = HudConfig.Dock.Shook
	for _, tile in dock.Tiles do
		local wanted = look(tile)
		if wanted ~= tile.Shown then
			paint(tile, wanted)
		end
		local shakeAt = tile.ShakeAt
		if shakeAt then
			local u = if shook > 0 then (now - shakeAt) / shook else 1
			if u >= 1 then
				tile.ShakeAt = nil
				tile.Shift = 0
			else
				tile.Shift = HudConfig.Dock.Shake * math.sin(2 * math.pi * 3 * u) * (1 - u)
			end
			place(tile)
		end
		local held = tile.HeldAt
		if held and now - held >= HudConfig.Dock.LongPress then
			tile.Long = true
		end
		local shows = (held ~= nil and tile.Long) or now < tile.WordUntil or Hover.Since(tile.Button) >= HudConfig.Motion.Hover.Word
		local disabled = tile.Button:GetAttribute("Disabled")
		local said = tile.Reason or (if type(disabled) == "string" and disabled ~= "" then disabled else (tile.Def :: any).Word or tile.Def.Name)
		local word = tile.Word
		local plate = word.Parent :: Frame
		if shows and (word.Text ~= said or tile.WordEpoch ~= Text.Epoch()) then
			word.Text = said
			tile.WordEpoch = Text.Epoch()
			plate.Size = UDim2.fromOffset(math.ceil(Text.Wide(word, said)) + WORD.Across * 2 + 2, WORD.Tall)
		end
		if word.Visible ~= shows then
			word.Visible = shows
			plate.Visible = shows
		end
	end
end

return Dock
