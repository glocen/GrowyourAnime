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
-- tile's word over it, and lifting it then doesn't press (Config.Hud.Dock).
--   Dock.new(parent, presses)          the dock; presses[name] is each tile's OnPress (Base, Inventory, Map)
--   Dock.Pip(dock, name, on)           something new on a tile
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
}
export type Dock = { Frame: Frame, Tiles: { [string]: Tile } }

local Dock = {}

-- One stack for the whole dock (hud_dock.json, "stack"): the body; every halo, glow and light; then every tile with its
-- sheen or rim, its mark and its pip; the words; the taps over all.
local Z = { Body = 1, Halo = 2, Glow = 3, Light = 4, Tile = 5, Over = 6, Mark = 7, Pip = 8, Word = 9, Tap = 10 }
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
	elseif state == "Pressed" or state == "Waiting" then
		return "Pressed"
	elseif state == "Selected" then
		return "Open"
	end
	return "Rest"
end

local function paint(tile: Tile, now: string)
	local def, layers = tile.Def, tile.Layers
	local dim = HudConfig.Dock.Dim
	local pressed = now == "Pressed"
	local placed = if pressed then def.TilePressed else def.Tile
	Skin.Set(layers.Tile, placed.Image, { X = placed.At.X, Y = placed.At.Y })
	Skin.Tint(layers.Tile, tile.Looks[if now == "Dim" then "Rest" else now])
	layers.Tile.ImageTransparency = if now == "Dim" then 1 - dim else 0
	layers.Sheen.Visible = now == "Rest"
	layers.Edge.Visible = now == "Open"
	layers.Halo.Visible = now == "Open"
	layers.Glow.Visible = now == "Rest"
	Skin.Tint(layers.Light, if now == "Rest" then def.Rest.Light elseif now == "Open" then def.Open.Light else def.Deep)
	layers.Light.ImageTransparency = if now == "Dim" then 1 - dim else 0
	local sink = if pressed then HudConfig.Dock.Sink else 0
	layers.Mark.Position = tile.Mark + UDim2.fromOffset(-sink * UIKit.Dock.Lean, sink)
	layers.Mark.ImageTransparency = if now == "Dim" then 1 - dim else 0
	tile.Button:SetAttribute("Look", now)
	tile.Shown = now
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
		}
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

function Dock.Paint(dock: Dock)
	local now = os.clock()
	for _, tile in dock.Tiles do
		local wanted = look(tile)
		if wanted ~= tile.Shown then
			paint(tile, wanted)
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
