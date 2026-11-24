--!strict
-- Layers (client): one ScreenGui per layer, each with one UIScale (handbook/visuals/ui.md, "The layer structure").
-- Authored at Theme.Author and scaled by height, clamped (handbook/visuals/ui.md, "Phones"). The HUD and the screens keep
-- clear of Roblox's top bar and the notch (TR2, research's read of the phone take, fix 1: a screen's title sat under
-- Roblox's own buttons), and so do the toasts, which stood past the notch's side at phone size (AR8 C, research's pass,
-- fix 2); the world's plates, a full screen's cover and the overlay's run full-bleed. The Band is the room Roblox's
-- top bar leaves free, right of its own buttons (GuiService.TopbarInset, read live): a full screen's bar stands in it
-- (Kit.Screen; TR17, research's call, 2026-11-15). Every container is named NL_..., which the UI lint reads as ours.
--   Layers.Get("Hud")      the layer's root frame, made on first use
--   Layers.Scale()         the scale every layer draws at now
--   Layers.Band()          the band's size now, authored
--   Layers.Changed         (scale) after a refit
--   Layers.Force(scale?), Layers.Box(size?)   for tests: a phone's scale and its box

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local Signal = require(game:GetService("ReplicatedStorage").Shared.Util.Signal)

export type Name = "World" | "Hud" | "Cover" | "Menus" | "Band" | "Overlay" | "Toasts"

local ORDER: { [string]: number } = {
	World = 5, -- plates and numbers projected from the world: drawn in captures, unlike a BillboardGui
	Hud = 10,
	Cover = 15, -- behind a full screen (Kit.Screen): over the world and the HUD, edge to edge
	Menus = 20,
	Band = 21, -- Roblox's top bar, right of its buttons: a full screen's Back and what its owner sets beside it
	Overlay = 30,
	Toasts = 40,
	-- The fade (FadeController) is 100, over all of them.
}

local Layers = {}
Layers.Changed = Signal.new()

local roots: { [string]: Frame } = {}
local scales: { UIScale } = {}
local scale = 1
local forced: number? = nil -- a test's scale, in place of the screen's
local boxed: Vector2? = nil -- a test's phone, in rendered pixels: the inset layers laid out in it
local boxAt = Vector2.zero -- its top left, rendered pixels from the safe area's
local framed = false -- the box placed by a take (centred): the World layer is then the phone's whole screen too

-- Where the top bar's free room starts, rendered: right of Roblox's buttons, and inside a test's phone box. A take's
-- centred box is the phone's whole screen, so its band starts where the phone's would: right of the phone's own buttons.
local function bandLeft(): number
	local free = GuiService.TopbarInset
	return if framed then boxAt.X + free.Min.X elseif boxed then math.max(free.Min.X, boxAt.X) else free.Min.X
end

-- The top bar's free room, authored: read from the inset itself, so it's right before its layer is laid out.
function Layers.Band(): Vector2
	local free = GuiService.TopbarInset
	local wide = if boxed then math.min(free.Max.X, boxAt.X + boxed.X) - bandLeft() else free.Width
	return Vector2.new(math.max(wide, 0), free.Height) / scale
end
local INSET: { [string]: boolean } = { Hud = true, Menus = true, Toasts = true } -- kept clear of Roblox's top bar and the notch

-- An inset layer's root fills its safe area, or a test's phone box. The Band's fills the top bar's free room, cut to a
-- test's phone box: its layer starts at the screen's top, at the safe area's left, where TopbarInset is measured from.
local function size(name: string, root: Frame)
	if name == "Band" then
		local free, band = GuiService.TopbarInset, Layers.Band()
		local top = if framed then boxAt.Y else 0 -- a take's centred box: the band at the phone's top, not the window's
		root.Position = UDim2.fromOffset(bandLeft() / scale, (top + free.Min.Y) / scale)
		root.Size = UDim2.fromOffset(band.X, band.Y)
		return
	end
	-- A centred take's World layer: the phone's whole screen, the top bar's height over its box, so a plate kept to the
	-- screen's edges keeps to the phone's (UI.World.Beside, AR51), as it does on the phone.
	local box: Vector2? = if INSET[name] then boxed else nil
	if name == "World" and framed and boxed then
		box = boxed + Vector2.new(0, GuiService.TopbarInset.Height)
	end
	root.Size = if box then UDim2.fromOffset(box.X / scale, box.Y / scale) else UDim2.fromScale(1, 1)
	root.Position = if box then UDim2.fromOffset(boxAt.X / scale, boxAt.Y / scale) else UDim2.new()
end

local function fit(): number
	if forced then
		return forced
	end
	local camera = workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else Theme.Author.Y
	local small = tostring((GuiService :: any).ViewportDisplaySize) == "Enum.DisplaySize.Small"
	return math.clamp(height / Theme.Author.Y, Theme.Scale.Floor, if small then Theme.Scale.CapSmall else Theme.Scale.Cap)
end

local function refit()
	local now = fit()
	if math.abs(now - scale) < 1e-4 then
		return
	end
	scale = now
	for _, s in scales do
		s.Scale = scale
	end
	for name, root in roots do
		size(name, root)
	end
	Layers.Changed:Fire(scale)
end

function Layers.Scale(): number
	return scale
end

-- For tests: every layer drawn at `value` (Theme.Scale.Floor is the smallest phone), or fitted to the screen again (nil).
function Layers.Force(value: number?)
	forced = value
	refit()
end

-- For tests: the HUD and the screens laid out in a phone's safe area of `box` rendered pixels, from the window's safe top
-- left or `at` from it, or in the whole window again (nil). With Force(Theme.Scale.Floor) and Theme.Smallest, the
-- smallest phone. A take that shows the world under the HUD centres the box on the window: the world is drawn across the
-- whole window, so only there does it stand under the HUD as on the phone. Roblox's own buttons stay at the window's top
-- left, outside such a box. Placed with `at`, the World layer is framed as the phone's whole screen too, its plates kept
-- to the phone's edges.
function Layers.Box(box: Vector2?, at: Vector2?)
	boxed = box
	boxAt = if box then at or Vector2.zero else Vector2.zero
	framed = box ~= nil and at ~= nil
	for name, root in roots do
		size(name, root)
	end
end

function Layers.Get(name: Name): Frame
	local root = roots[name]
	if root then
		return root
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = `NL_{name}`
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = ORDER[name]
	local inset = INSET[name] == true
	gui.IgnoreGuiInset = not inset
	gui.ScreenInsets = if inset then Enum.ScreenInsets.CoreUISafeInsets elseif name == "Band" then Enum.ScreenInsets.DeviceSafeInsets else Enum.ScreenInsets.None
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	uiScale.Parent = gui
	table.insert(scales, uiScale)
	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.BackgroundTransparency = 1
	size(name, frame)
	frame.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	roots[name] = frame
	return frame
end

GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	local band = roots.Band
	if band then
		size("Band", band)
	end
end)

scale = fit()
local function watch(camera: Camera?)
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	refit()
end
watch(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	watch(workspace.CurrentCamera)
end)

return Layers
