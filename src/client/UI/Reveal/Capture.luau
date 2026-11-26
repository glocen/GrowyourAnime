--!strict
-- Reveal's capture (client; TR60, docs/design.md, "Being seen", the capture). While a reveal's card holds, a camera tile
-- stands beside its top right corner. A tap takes the frame with the reveal's card and without the HUD: every layer but
-- the world's and the overlay's is off for it, and so are the tile and "Continue" (Layers.Only). Then Roblox's
-- share sheet opens on it, its launch data the sharer's UserId alone (Rules.Capture), which the server counts when a
-- friend joins through it (FunnelService). A share is never rewarded. Config.Reveal.Plate.Capture's numbers; a drawn
-- camera in the kit's neutral glass stands in for the tile's icon (Modulo's).
--   Capture.Tile(plate)           the tile on a reveal's card (UI/Reveal/Plate), returned
--   Capture.Take(plate, share?)   what a tap does; `share` false stops at the frame, for tests. False while one is taken
--   Capture.Last()                the last take: its result's name, and the layers it turned off, for tests

local CaptureService = game:GetService("CaptureService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local RevealConfig = require(Shared.Config.Reveal)
local UIKit = require(Shared.Config.UIKit)
local CaptureRules = require(Shared.Rules.Capture)
local Log = require(Shared.Util.Log)
local Layers = require(script.Parent.Parent.Layers)

export type Taken = { Result: string, Off: number }

local Capture = {}

local TILE = "Capture"
local KEEP: { Layers.Name } = { "World", "Overlay" }

local busy = false
local last: Taken? = nil

local function corner(parent: GuiObject, radius: number)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = parent
end

local function piece(name: string, parent: GuiObject, size: Vector2, y: number, colour: Color3, radius: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, y)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.BackgroundColor3 = colour
	frame.BorderSizePixel = 0
	frame.ZIndex = parent.ZIndex + 1
	frame.Parent = parent
	corner(frame, radius)
	return frame
end

function Capture.Tile(plate: Frame): TextButton
	local c = RevealConfig.Plate.Capture
	local glass = UIKit.Palettes.Graphite
	local tile = Instance.new("TextButton")
	tile.Name = TILE
	tile.Text = ""
	tile.AutoButtonColor = false
	tile.AnchorPoint = Vector2.new(0, 0)
	tile.Position = UDim2.new(1, c.Gap, 0, 0)
	tile.Size = UDim2.fromOffset(c.Size, c.Size)
	tile.BackgroundColor3 = glass.Panel[1]
	tile.BackgroundTransparency = 1 - glass.Alpha
	tile.BorderSizePixel = 0
	tile.ZIndex = plate.ZIndex + 1
	corner(tile, 8)
	local edge = Instance.new("UIStroke")
	edge.Color = glass.Edge
	edge.Thickness = 1
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = tile
	-- The stand-in camera: a body, its lens, the bump on its top.
	local body = piece("Body", tile, c.Body, 1, glass.Text, 3)
	piece("Bump", tile, c.Bump, 1 - c.Body.Y / 2 - c.Bump.Y / 2 + 1, glass.Text, 1)
	local lens = piece("Lens", body, Vector2.new(c.Lens, c.Lens), 0, glass.Panel[1], c.Lens)
	lens.Position = UDim2.fromScale(0.5, 0.5)
	tile.Parent = plate
	tile.Activated:Connect(function()
		Capture.Take(plate)
	end)
	return tile
end

function Capture.Take(plate: Frame, share: boolean?): boolean
	if busy then
		return false
	end
	busy = true
	local c = RevealConfig.Plate.Capture
	local hidden: { GuiObject } = {}
	for _, name in { TILE, "Skip" } do
		local found = plate:FindFirstChild(name)
		if found and found:IsA("GuiObject") and found.Visible then
			found.Visible = false
			table.insert(hidden, found)
		end
	end
	local restore, off = Layers.Only(KEEP)
	local done = false
	local function finish(result: string)
		if done then
			return
		end
		done = true
		restore()
		for _, object in hidden do
			if object.Parent then
				object.Visible = true
			end
		end
		busy = false
		last = { Result = result, Off = off }
	end
	task.delay(c.Timeout, finish, "Timeout")
	RunService.RenderStepped:Wait() -- a frame drawn without them first
	local ok, problem = pcall(function()
		CaptureService:TakeScreenshotCaptureAsync(function(result: any, capture: any)
			finish(if typeof(result) == "EnumItem" then result.Name else tostring(result))
			if result ~= Enum.ScreenshotCaptureResult.Success or capture == nil or share == false then
				return
			end
			local shared, why = pcall(function()
				CaptureService:PromptShareCapture(Content.fromObject(capture), CaptureRules.Launch(Players.LocalPlayer.UserId), function() end, function() end)
			end)
			if not shared then
				Log.Warn("RevealCapture", "the share sheet didn't open:", why)
			end
		end, { UICaptureMode = Enum.UICaptureMode.All })
	end)
	if not ok then
		Log.Warn("RevealCapture", "the frame wasn't taken:", problem)
		finish("Error")
	end
	return true
end

function Capture.Last(): Taken?
	return last
end

return Capture
