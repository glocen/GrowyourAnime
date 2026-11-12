--!strict
-- Layers (client): one ScreenGui per layer, each with one UIScale (handbook/visuals/ui.md, "The layer structure").
-- Authored at Theme.Author and scaled by height, clamped (handbook/visuals/ui.md, "Phones"). Only the HUD keeps clear of
-- Roblox's top bar and the notch; the others run full-bleed. Every container is named NL_..., which the UI lint reads as ours.
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

local function fit(): number
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
	local hud = name == "Hud"
	gui.IgnoreGuiInset = not hud
	gui.ScreenInsets = if hud then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None
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
