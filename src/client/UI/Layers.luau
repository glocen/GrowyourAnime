--!strict
-- Layers (client): one ScreenGui per layer, each with one UIScale (handbook/visuals/ui.md, "The layer structure").
-- Authored at Theme.Author and scaled by height, clamped (handbook/visuals/ui.md, "Phones"). The HUD and the screens keep
-- clear of Roblox's top bar and the notch (TR2, research's read of the phone take, fix 1: a screen's title sat under
-- Roblox's own buttons); the world's plates, the overlay's cover and the toasts run full-bleed. Every container is named
-- NL_..., which the UI lint reads as ours.
--   Layers.Get("Hud")      the layer's root frame, made on first use
--   Layers.Scale()         the scale every layer draws at now
--   Layers.Changed         (scale) after a refit

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local Signal = require(game:GetService("ReplicatedStorage").Shared.Util.Signal)

export type Name = "World" | "Hud" | "Menus" | "Overlay" | "Toasts"

local ORDER: { [string]: number } = {
	World = 5, -- plates and numbers projected from the world: drawn in captures, unlike a BillboardGui
	Hud = 10,
	Menus = 20,
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
	local inset = name == "Hud" or name == "Menus"
	gui.IgnoreGuiInset = not inset
	gui.ScreenInsets = if inset then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	uiScale.Parent = gui
	table.insert(scales, uiScale)
	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	roots[name] = frame
	return frame
end

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
