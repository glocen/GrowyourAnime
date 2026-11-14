--!strict
-- Toast (client kit): a brief notice under the pills, where what it's about lives (Credits, a shard, a level). One line,
-- Theme.Time.Toast seconds, at most Theme.Time.Toasts stacked: a newer one pushes the oldest out (handbook/visuals/ui.md,
-- "HUD behaviour"). It shows only what the server has already said. It slides in from the screen's right edge, eased
-- out, and leaves that way, eased in, a little quicker (Config.Hud.Motion.Toast; rule 4; AR8 C).
--   Toast.Show(message, colour?)   Toast.Stack()   Toast.Shown()   Toast.Riding(), for tests

local TweenService = game:GetService("TweenService")

local HudConfig = require(game:GetService("ReplicatedStorage").Shared.Config.Hud)

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Layers)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)

local Toast = {}

Toast.Width = 220
Toast.Height = 28
Toast.Top = 92 -- authored pixels from the safe area's top: under the Electricity pill's foot (83), never over a pill

local shown: { Frame } = {}
local stack: Frame? = nil

local function holder(): Frame
	if stack and stack.Parent then
		return stack
	end
	local frame = Instance.new("Frame")
	frame.Name = "Stack"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Size = UDim2.fromOffset(Toast.Width, (Toast.Height + Theme.Size.Gap) * Theme.Time.Toasts)
	Panel.List(frame)
	frame.Parent = Layers.Get("Toasts")
	stack = frame
	return frame
end

local function place(frame: Frame)
	frame.Position = UDim2.new(1, -Theme.Size.Pad, 0, Toast.Top) -- its layer is inset: clear of the top bar and the notch
end

local order = 0

-- Off the screen's right edge: past the stack's own margin and the plate's shadow.
local function away(): UDim2
	return UDim2.fromOffset(Toast.Width + Theme.Size.Pad + 24, 0)
end

-- It slides out and its place in the stack goes after.
local function leave(slot: Frame)
	local index = table.find(shown, slot)
	if index then
		table.remove(shown, index)
	end
	local plate = slot:FindFirstChild("Toast") :: Frame?
	local seconds = HudConfig.Motion.Toast.Exit
	if plate then
		TweenService:Create(plate, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = away() }):Play()
	end
	task.delay(seconds, function()
		slot:Destroy()
	end)
end

function Toast.Show(message: string, colour: Color3?)
	local parent = holder()
	place(parent)
	while #shown >= Theme.Time.Toasts do
		leave(shown[1])
	end
	order += 1
	local slot = Instance.new("Frame")
	slot.Name = "Slot"
	slot.BackgroundTransparency = 1
	slot.Size = UDim2.fromOffset(Toast.Width, Toast.Height)
	slot.LayoutOrder = order
	local plate = Panel.new({ Name = "Toast", Size = UDim2.fromOffset(Toast.Width, Toast.Height), Parent = slot })
	plate.Position = away()
	Panel.Pad(plate, Theme.Size.Pad)
	local label = Text.new({ Name = "Message", Size = Theme.Text.Body, Colour = colour, Truncate = true, Parent = plate })
	label.Text = message
	slot.Parent = parent
	table.insert(shown, slot)
	local enter = HudConfig.Motion.Toast.Enter
	TweenService:Create(plate, TweenInfo.new(enter, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new() }):Play()
	task.delay(Theme.Time.Toast, function()
		if table.find(shown, slot) then
			leave(slot)
		end
	end)
end

-- The stack while any notice shows, for what keeps clear of it (UI.World's open plates), or nil.
function Toast.Stack(): Frame?
	return if #shown > 0 and stack and stack.Parent then stack else nil
end

-- The notices on screen now, newest last: for tests.
function Toast.Shown(): { string }
	local messages = {}
	for _, slot in shown do
		local label = slot:FindFirstChild("Message", true) :: TextLabel?
		if label then
			table.insert(messages, label.Text)
		end
	end
	return messages
end

-- Whether a notice is on its way in or out: for the tests' lint, which reads the screen at rest.
function Toast.Riding(): boolean
	local held = stack
	for _, slot in (if held then held:GetChildren() else {}) do
		local plate = slot:FindFirstChild("Toast")
		if plate and plate:IsA("GuiObject") and plate.Position ~= UDim2.new() then
			return true
		end
	end
	return false
end

return Toast
