--!strict
-- Toast (client kit): a brief notice under the pills, where what it's about lives (Credits, a shard, a level). One line,
-- Theme.Time.Toast seconds, at most Theme.Time.Toasts stacked: a newer one pushes the oldest out (handbook/visuals/ui.md,
-- "HUD behaviour"). It shows only what the server has already said.

local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Layers)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)

local Toast = {}

Toast.Width = 220
Toast.Height = 28
Toast.Top = 42 -- authored pixels under the top bar: below the pills

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
	local inset = GuiService.TopbarInset.Max.Y / Layers.Scale()
	frame.Position = UDim2.new(1, -Theme.Size.Pad, 0, inset + Toast.Top)
end

local order = 0

function Toast.Show(message: string, colour: Color3?)
	local parent = holder()
	place(parent)
	while #shown >= Theme.Time.Toasts do
		local oldest = table.remove(shown, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	order += 1
	local plate = Panel.new({ Name = "Toast", Size = UDim2.fromOffset(Toast.Width, Toast.Height), Parent = parent })
	plate.LayoutOrder = order
	Panel.Pad(plate, Theme.Size.Pad)
	local label = Text.new({ Name = "Message", Size = Theme.Text.Body, Colour = colour, Truncate = true, Parent = plate })
	label.Text = message
	table.insert(shown, plate)
	task.delay(Theme.Time.Toast, function()
		local index = table.find(shown, plate)
		if index then
			table.remove(shown, index)
		end
		plate:Destroy()
	end)
end

-- The notices on screen now, newest last: for tests.
function Toast.Shown(): { string }
	local messages = {}
	for _, plate in shown do
		local label = plate:FindFirstChild("Message") :: TextLabel?
		if label then
			table.insert(messages, label.Text)
		end
	end
	return messages
end

return Toast
