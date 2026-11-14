--!strict
-- Screen (client kit): a full screen on the Menus layer, one at a time, with its title and a visible exit
-- (handbook/visuals/ui.md, "Screen standard"). Opening one closes the one before. Its content is rebuilt by its owner
-- whenever the server's copy changes, so it never shows a stale state. It stands in the room the layer leaves below
-- Roblox's top bar, and shrinks to that room on a short screen: its body's lists scroll.
-- It comes in from a little smaller, see-through, eased out, and leaves to a little smaller, eased in, in about 0.8 of
-- its entrance (Config.Hud.Motion.Screen; rule 4; AR8 C): the panel in a group the size of the room, which fades and
-- scales as one. A closed screen is closed at once (Current is nil, Closed fires, nothing in it takes a tap) while it
-- leaves. The same screen opened again, as its owner rebuilds it on a change, keeps its panel and refills its body in
-- place: no second entrance, and Closed doesn't fire. Its lists keep where they were scrolled, found again by name, so a
-- tap low on a list that rebuilds the screen never throws the row tapped out of view (TR15's take, 2026-11-14). A list
-- whose rows are one thing's (a shard's pane) carries that thing as its "Keep" attribute, and starts at its
-- top when the thing changes. A bare screen (one Voidkin's, TR17) has no head row: its body is the whole panel, the
-- close button over its top right corner, so a figure can stand the screen's full height.
--   Screen.Open(name, title, size, bare?) -> the body frame to fill
--   Screen.Close()
--   Screen.Current() -> the open screen's name, or nil

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Layers)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)
local Shared = game:GetService("ReplicatedStorage").Shared
local Signal = require(Shared.Util.Signal)
local HudConfig = require(Shared.Config.Hud)

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

local open: { Name: string, Frame: Frame, Stage: CanvasGroup, Size: Vector2 }? = nil

type Kept = { [string]: { At: Vector2, Keep: any } }

-- Where each list in a body is scrolled, by its path under the body, with what it shows.
local function scrolled(body: Instance): Kept
	local kept: Kept = {}
	local from = #body:GetFullName() + 2
	for _, item in body:GetDescendants() do
		if item:IsA("ScrollingFrame") and item.CanvasPosition ~= Vector2.zero then
			kept[string.sub(item:GetFullName(), from)] = { At = item.CanvasPosition, Keep = item:GetAttribute("Keep") }
		end
	end
	return kept
end

-- Once the owner has refilled the body, its lists back where they were: when it's filled, and again once the lists have
-- grown to their rows, so a position past a list not yet sized holds.
local function rescroll(body: Instance, kept: Kept)
	if next(kept) == nil then
		return
	end
	local function apply()
		if body.Parent == nil then
			return
		end
		local from = #body:GetFullName() + 2
		for _, item in body:GetDescendants() do
			local was = if item:IsA("ScrollingFrame") then kept[string.sub(item:GetFullName(), from)] else nil
			if was and item:IsA("ScrollingFrame") and item:GetAttribute("Keep") == was.Keep then
				item.CanvasPosition = was.At
			end
		end
	end
	task.defer(apply)
	task.delay(0, apply)
end

local function tween(stage: CanvasGroup, seconds: number, style: Enum.EasingStyle, direction: Enum.EasingDirection, see: number, size: number): Tween
	local info = TweenInfo.new(seconds, style, direction)
	local scale = stage:FindFirstChildOfClass("UIScale") :: UIScale
	TweenService:Create(scale, info, { Scale = size }):Play()
	local fade = TweenService:Create(stage, info, { GroupTransparency = see })
	fade:Play()
	return fade
end

function Screen.Close()
	local current = open
	if current == nil then
		return
	end
	open = nil
	local stage = current.Stage
	stage.Interactable = false
	stage.Name = `{current.Name}Leaving`
	local motion = HudConfig.Motion.Screen
	tween(stage, motion.Exit, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 1, motion.To)
	task.delay(motion.Exit, function()
		stage:Destroy()
	end)
	Screen.Closed:Fire(current.Name)
end

function Screen.Current(): string?
	return if open then open.Name else nil
end

-- The open screen's frame when it is `name`: for tests.
function Screen.Frame(name: string): Frame?
	return if open and open.Name == name then open.Frame else nil
end

-- The group it fades and scales in, open or leaving: for tests.
function Screen.Stage(name: string): CanvasGroup?
	local root = Layers.Get("Menus")
	return (root:FindFirstChild(`{name}Stage`) or root:FindFirstChild(`{name}Leaving`)) :: CanvasGroup?
end

function Screen.Open(name: string, title: string, size: Vector2, bare: boolean?): Frame
	local current = open
	local again = current and current.Name == name and current.Frame:FindFirstChild("Body")
	local named = current and current.Frame:FindFirstChild("Title")
	if current and again and named and named:IsA("TextLabel") then
		rescroll(again, scrolled(again))
		again:ClearAllChildren()
		named.Text = title
		current.Size = size
		fit(current.Frame, size)
		return again :: Frame
	end
	Screen.Close()
	local motion = HudConfig.Motion.Screen
	local stage = Instance.new("CanvasGroup")
	stage.Name = `{name}Stage`
	stage.BackgroundTransparency = 1
	stage.BorderSizePixel = 0
	stage.Size = UDim2.fromScale(1, 1)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.GroupTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Scale = motion.From
	scale.Parent = stage
	local frame = Panel.new({
		Name = name,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = stage,
	})
	frame.Active = true -- a tap on the screen stays on it
	fit(frame, size)
	local record = { Name = name, Frame = frame, Stage = stage, Size = size }
	local refit = function()
		fit(frame, record.Size)
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
	heading.Visible = bare ~= true
	local close = Button.new({
		Name = "Close",
		Text = "Close",
		Size = UDim2.fromOffset(72, Theme.Size.Tap),
		Position = UDim2.new(1, -Theme.Size.Pad, 0, Theme.Size.Pad / 2),
		AnchorPoint = Vector2.new(1, 0),
		Parent = frame,
		OnPress = Screen.Close,
	})
	close.ZIndex = 3 -- over a bare body's corner
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	if bare then
		body.Size = UDim2.fromScale(1, 1)
	else
		body.Position = UDim2.fromOffset(Theme.Size.Pad * 2, HEAD)
		body.Size = UDim2.new(1, -Theme.Size.Pad * 4, 1, -(HEAD + Theme.Size.Pad))
	end
	body.Parent = frame
	stage.Parent = Layers.Get("Menus")
	tween(stage, motion.Enter, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, 1)
	open = record
	return body
end

return Screen
