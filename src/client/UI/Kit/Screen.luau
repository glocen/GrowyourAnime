--!strict
-- Screen (client kit): a full screen on the Menus layer, one at a time, with its title and a visible exit
-- (handbook/visuals/ui.md, "Screen standard"). Opening one closes the one before. Its content is rebuilt by its owner
-- whenever the server's copy changes, so it never shows a stale state. It stands in the room the layer leaves below
-- Roblox's top bar, and shrinks to that room on a short screen: its body's lists scroll.
--   Screen.Open(name, title, size) -> the body frame to fill
--   Screen.Close()
--   Screen.Current() -> the open screen's name, or nil

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Layers)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)
local Signal = require(game:GetService("ReplicatedStorage").Shared.Util.Signal)

local Screen = {}
Screen.Closed = Signal.new() -- (name)

local TITLE = 32 -- authored height of the title's line
local HEAD = Theme.Size.Tap + Theme.Size.Pad -- the head row: the close button, a tap high, and half a pad over and under
local MARGIN = 8 -- authored pixels kept between a screen and the edge of its room

-- As large as authored, or as the room allows.
local function fit(frame: Frame, size: Vector2)
	local room = Layers.Get("Menus").AbsoluteSize / Layers.Scale()
	local wide = if room.X > 0 then math.min(size.X, room.X - MARGIN * 2) else size.X
	local tall = if room.Y > 0 then math.min(size.Y, room.Y - MARGIN * 2) else size.Y
	frame.Size = UDim2.fromOffset(wide, tall)
end

local open: { Name: string, Frame: Frame }? = nil

function Screen.Close()
	local current = open
	if current == nil then
		return
	end
	open = nil
	current.Frame:Destroy()
	Screen.Closed:Fire(current.Name)
end

function Screen.Current(): string?
	return if open then open.Name else nil
end

-- The open screen's frame when it is `name`: for tests.
function Screen.Frame(name: string): Frame?
	return if open and open.Name == name then open.Frame else nil
end

function Screen.Open(name: string, title: string, size: Vector2): Frame
	Screen.Close()
	local frame = Panel.new({
		Name = name,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = Layers.Get("Menus"),
	})
	frame.Active = true -- a tap on the screen stays on it
	fit(frame, size)
	local refit = function()
		fit(frame, size)
	end
	local resized = Layers.Get("Menus"):GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	local rescaled = Layers.Changed:Connect(refit)
	frame.Destroying:Connect(function()
		resized:Disconnect()
		rescaled:Disconnect()
	end)
	local heading = Text.new({
		Name = "Title",
		Size = Theme.Text.Title,
		Font = Theme.Font.Strong,
		Box = UDim2.new(1, -(Theme.Size.Pad * 3 + 72), 0, TITLE),
		Position = UDim2.fromOffset(Theme.Size.Pad * 2, (HEAD - TITLE) / 2),
		Parent = frame,
	})
	heading.Text = title
	Button.new({
		Name = "Close",
		Text = "Close",
		Size = UDim2.fromOffset(72, Theme.Size.Tap),
		Position = UDim2.new(1, -Theme.Size.Pad, 0, Theme.Size.Pad / 2),
		AnchorPoint = Vector2.new(1, 0),
		Parent = frame,
		OnPress = Screen.Close,
	})
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(Theme.Size.Pad * 2, HEAD)
	body.Size = UDim2.new(1, -Theme.Size.Pad * 4, 1, -(HEAD + Theme.Size.Pad))
	body.Parent = frame
	open = { Name = name, Frame = frame }
	return body
end

return Screen
