--!strict
-- Dock (client UI): the dock of three icons (docs/ui.md, the HUD; docs/asset-requests.md, AR12, "The dock as three
-- icons"): one graphite body at the foot's middle, Base and the Map leaning either side of Inventory, which stands over
-- them. Each tile is a block of its system's colour with its mark in ink, its light under it (UIKit.Dock: Modulo's
-- hud_dock.json, every place in points from the body's top left). Each tile's tap is a kit button (Button, Bare and
-- Still: the dock draws its own press), so it has the kit's states, an icon's refusal said in a toast, and Button.Press
-- for tests. The dock paints each tile from its button's state:
--   rest      its gradient, its sheen in its pale, its light and the light's glow in its colour
--   pressed   its pressed twin under pressed's gradient, its mark Sink points down its lean, its light in its deep
--   open      while its screen is (the button Selected): white-hot, its rim over it, its halo under it, its light white
--   dim       while it can't be used (the button Disabled): its tile and mark at Dim of themselves, its light deep
-- and the pip over its far corner while it has something new, in any state. A touch held LongPress seconds shows the
-- tile's word over it, and lifting it then doesn't press (Config.Hud.Dock). A tile its owner gives a mood keeps it over
-- its button's states, still tappable, so a tap can say why (TR19, the Base tile):
--   quiet     nothing to do here: its gradient at Quiet of itself, no sheen, no glow, its light deep; nothing sinks
--   dim       refused for now: as a disabled tile
-- Over a tile, two of its owner's measures in its own shape, under its mark: a fill rising from its foot (a charge), and
-- a veil over the share still to come, swept away left to right (a cooldown).
--   Dock.new(parent, presses)          the dock; presses[name] is each tile's OnPress (Base, Inventory, Map)
--   Dock.Pip(dock, name, on)           something new on a tile
--   Dock.Mood(dock, name, mood?)       "Quiet", "Dim", or nil for its button's own look
--   Dock.Fill(dock, name, share?)      a charge's share, 0 to 1; nil or 0 shows none
--   Dock.Sweep(dock, name, share?)     a cooldown's run, 0 to 1; nil or 1 shows none
--   Dock.Shake(dock, name)             a refused tap: the tile shakes Shake points side to side over Shook seconds
--   Dock.Hold(button, down)            a touch going down on a tile's button or coming off, as a finger's (for tests)
--   Dock.Paint(dock)                   each frame: a tile repaints only when its look changes

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)
local Button = require(script.Parent.Kit.Button)

type Def = typeof(UIKit.Dock.Buttons[1])
type Gradient = { Stops: { number }, Colours: { Color3 } }

export type Tile = {
	Def: Def,
	Button: TextButton,
	Layers: { [string]: ImageLabel },
	Word: TextLabel,
	Mark: UDim2, -- the mark's place at rest
	Looks: { [string]: ColorSequence }, -- the tile's gradient in each state
	New: boolean,
	Shown: string, -- the look painted last
	HeldAt: number?, -- a touch's moment, while it's down
	Long: boolean, -- the touch passed LongPress: its lift doesn't press
	WordUntil: number,
	Mood: Mood?,
	Rest: { [string]: UDim2 }, -- each layer's place at rest, its mark's apart (Mark)
	Shift: number, -- the shake's offset now, in points
	ShakeAt: number?,
	Shares: { [string]: number }, -- the fill's and the veil's shown last
}
export type Mood = "Quiet" | "Dim"
export type Dock = { Frame: Frame, Tiles: { [string]: Tile } }

local Dock = {}

-- One stack for the whole dock (hud_dock.json, "stack"): the body; every halo, glow and light; then every tile with its
-- sheen or rim, its mark and its pip; the words; the taps over all.
local Z = { Body = 1, Halo = 2, Glow = 3, Light = 4, Tile = 5, Over = 6, Fill = 7, Veil = 8, Mark = 9, Pip = 10, Word = 11, Tap = 12 }
local WORD_INK = Color3.fromHex("#0B0B12")

-- Each tile by its button, for Dock.Hold. Held until the dock is destroyed, as the kit's buttons are (Button's note).
local byButton: { [TextButton]: Tile } = {}

local function sequence(g: Gradient): ColorSequence
	local points = {}
	for i, stop in g.Stops do
		table.insert(points, ColorSequenceKeypoint.new(stop, g.Colours[i]))
	end
	return ColorSequence.new(points)
end

local function look(tile: Tile): string
	local state = Button.State(tile.Button)
	if state == "Disabled" then
		return "Dim"
	elseif tile.Mood then
		return tile.Mood
	elseif state == "Pressed" or state == "Waiting" then
		return "Pressed"
	elseif state == "Selected" then
		return "Open"
	end
	return "Rest"
end

-- Every layer at its place with the shake's offset; the mark Sink points down its lean while pressed.
local function place(tile: Tile)
	local shift = UDim2.fromOffset(tile.Shift, 0)
	for name, layer in tile.Layers do
		local rest = tile.Rest[name]
		if rest then
			layer.Position = rest + shift
		end
	end
	local sink = if tile.Shown == "Pressed" then HudConfig.Dock.Sink else 0
	tile.Layers.Mark.Position = tile.Mark + UDim2.fromOffset(tile.Shift - sink * UIKit.Dock.Lean, sink)
end

local function paint(tile: Tile, now: string)
	local def, layers = tile.Def, tile.Layers
	local shade = if now == "Dim" then HudConfig.Dock.Dim elseif now == "Quiet" then HudConfig.Dock.Quiet else 1
	local placed = if now == "Pressed" then def.TilePressed else def.Tile
	Skin.Set(layers.Tile, placed.Image, { X = placed.At.X, Y = placed.At.Y })
	tile.Rest.Tile = layers.Tile.Position
	Skin.Tint(layers.Tile, tile.Looks[now] or tile.Looks.Rest)
	layers.Tile.ImageTransparency = 1 - shade
	layers.Sheen.Visible = now == "Rest"
	layers.Edge.Visible = now == "Open"
	layers.Halo.Visible = now == "Open"
	layers.Glow.Visible = now == "Rest"
	Skin.Tint(layers.Light, if now == "Rest" then def.Rest.Light elseif now == "Open" then def.Open.Light else def.Deep)
	layers.Light.ImageTransparency = 1 - shade
	layers.Mark.ImageTransparency = 1 - shade
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

-- The tile's own shape over it in `colour`, under its mark, its gradient turned `rotation`: made the first time it's
-- asked for.
local function overlay(tile: Tile, name: string, z: number, colour: Color3, rotation: number): ImageLabel
	local made = tile.Layers[name]
	if made then
		return made
	end
	local at = tile.Def.Tile.At
	local layer = Skin.Lay(tile.Layers.Tile.Parent :: GuiObject, tile.Def.Tile.Image, { X = at.X, Y = at.Y, Z = z, Tint = colour })
	layer.Name = `{tile.Def.Name}{name}`
	layer.Visible = false
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Parent = layer
	tile.Layers[name] = layer
	tile.Rest[name] = layer.Position
	layer.Position = layer.Position + UDim2.fromOffset(tile.Shift, 0)
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

local function lay(frame: Frame, layer: { Image: string, At: Vector2 }, z: number, tint: Color3?): ImageLabel
	return Skin.Lay(frame, layer.Image, { X = layer.At.X, Y = layer.At.Y, Z = z, Tint = tint })
end

local function stretched(frame: Frame, layer: { Image: string, At: Vector2, Size: Vector2 }, z: number, tint: Color3): ImageLabel
	return Skin.Lay(frame, layer.Image, { X = layer.At.X, Y = layer.At.Y, W = layer.Size.X, H = layer.Size.Y, Z = z, Tint = tint })
end

function Dock.new(parent: Instance, presses: { [string]: () -> ...any }): Dock
	local shape = UIKit.Dock
	local frame = Instance.new("Frame")
	frame.Name = "Dock"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(shape.Size.X, shape.Size.Y)
	local body = UIKit.Images.DockBody.At :: Vector2
	Skin.Lay(frame, "DockBody", { X = body.X, Y = body.Y, Z = Z.Body })
	local dock: Dock = { Frame = frame, Tiles = {} }
	for _, def in shape.Buttons do
		local layers = {
			Halo = lay(frame, def.Halo, Z.Halo, def.Open.Halo),
			Glow = stretched(frame, def.Glow, Z.Glow, def.Rest.Glow),
			Light = stretched(frame, def.Light, Z.Light, def.Rest.Light),
			Tile = lay(frame, def.Tile, Z.Tile),
			Sheen = lay(frame, def.Sheen, Z.Over, def.Rest.Sheen),
			Edge = lay(frame, def.Edge, Z.Over),
			Mark = Skin.Icon(frame, def.Mark.Image, def.Mark.Middle.X, def.Mark.Middle.Y, def.Mark.Size, nil, Z.Mark),
			Pip = lay(frame, def.Pip, Z.Pip),
		}
		for name, layer in layers do
			layer.Name = `{def.Name}{name}`
		end
		layers.Pip.Visible = false
		local box = def.Box
		local word = Text.new({
			Name = `{def.Name}Word`,
			Size = Theme.Text.Caption,
			Font = Theme.Font.Strong,
			Colour = UIKit.Palettes.Graphite.Text,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(box[3] + 40, 18),
			Position = UDim2.fromOffset(box[1] + box[3] / 2, box[2] - HudConfig.Dock.Rise),
			AnchorPoint = Vector2.new(0.5, 1),
			Parent = frame,
		})
		word.Text = def.Name
		word.ZIndex = Z.Word
		word.Visible = false
		local outline = Instance.new("UIStroke")
		outline.Color = WORD_INK
		outline.Thickness = 1.5
		outline.Parent = word
		local tile: Tile
		local button = Button.new({
			Name = def.Name,
			Text = "",
			Bare = true,
			Still = true,
			Size = UDim2.fromOffset(box[3], box[4]),
			Position = UDim2.fromOffset(box[1], box[2]),
			Parent = frame,
			OnPress = function(): ...any
				if tile.Long then -- a long press showed the word: its lift isn't a tap, and the word stays a moment
					tile.Long = false
					tile.WordUntil = os.clock() + 0.6
					return nil
				end
				return (presses[def.Name] or function() end)()
			end,
		})
		button.ZIndex = Z.Tap
		tile = {
			Def = def,
			Button = button,
			Layers = layers,
			Word = word,
			Mark = layers.Mark.Position,
			Looks = { Rest = sequence(def.Rest.Tile), Pressed = sequence(def.Pressed.Tile), Open = sequence(def.Open.Tile) },
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
		}
		for name, layer in layers do
			if name ~= "Mark" then
				tile.Rest[name] = layer.Position
			end
		end
		byButton[button] = tile
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
		dock.Tiles[def.Name] = tile
	end
	frame.Parent = parent
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
		tile.Layers.Pip.Visible = on
		tile.Button:SetAttribute("New", on)
	end
end

function Dock.Mood(dock: Dock, name: string, mood: Mood?)
	local tile = dock.Tiles[name]
	if tile and tile.Mood ~= mood then
		tile.Mood = mood
		tile.Button:SetAttribute("Mood", mood)
	end
end

-- The fill rises from the tile's foot: its gradient runs top to bottom, so the share past 1 - share is lit.
function Dock.Fill(dock: Dock, name: string, share: number?)
	local tile = dock.Tiles[name]
	if tile then
		local s = math.clamp(share or 0, 0, 1)
		measure(tile, "Fill", Z.Fill, Color3.new(1, 1, 1), 90, s, s > 0, 1 - s, HudConfig.Dock.Fill)
	end
end

-- The veil covers what's still to come, from the run's edge to the tile's right.
function Dock.Sweep(dock: Dock, name: string, share: number?)
	local tile = dock.Tiles[name]
	if tile then
		local s = math.clamp(share or 1, 0, 1)
		measure(tile, "Veil", Z.Veil, WORD_INK, 0, s, s < 1, s, HudConfig.Dock.Veil)
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
		local shows = (held ~= nil and tile.Long) or now < tile.WordUntil
		if tile.Word.Visible ~= shows then
			tile.Word.Visible = shows
		end
	end
end

return Dock
