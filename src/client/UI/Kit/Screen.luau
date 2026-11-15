--!strict
-- Screen (client kit): a screen on the Menus layer, one at a time, with its title and a visible exit
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
-- top when the thing changes.
-- A full screen (one Voidkin's, TR17; the director, 2026-11-15) takes the whole room with no panel of its own, over a
-- cover that hides the world and the HUD edge to edge and takes their taps (the Cover layer). Its exit is Back, at its
-- top left; its body is the whole room, laid out by its owner round Back (Screen.Back), the screen's name included.
--   Screen.Open(name, title, size) -> the body frame to fill
--   Screen.Full(name, title) -> the body frame to fill, the whole room
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
Screen.Back = Vector2.new(68, Theme.Size.Tap) -- a full screen's Back, authored, Theme.Size.Pad from its top left

local TITLE = 32 -- authored height of the title's line
local HEAD = Theme.Size.Tap + Theme.Size.Pad -- the head row: the close button, a tap high, and half a pad over and under
local MARGIN = 8 -- authored pixels kept between a screen and the edge of its room

-- As large as authored, or as the room allows; a full screen (no size) takes the room.
local function fit(frame: Frame, size: Vector2?)
	local room = Layers.Get("Menus").AbsoluteSize / Layers.Scale()
	if size == nil then
		frame.Size = UDim2.fromOffset(room.X, room.Y)
		return
	end
	local wide = if room.X > 0 then math.min(size.X, room.X - MARGIN * 2) else size.X
	local tall = if room.Y > 0 then math.min(size.Y, room.Y - MARGIN * 2) else size.Y
	frame.Size = UDim2.fromOffset(wide, tall)
end

local open: { Name: string, Frame: Frame, Stage: CanvasGroup, Size: Vector2?, Cover: Frame? }? = nil

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

local function tween(stage: CanvasGroup, seconds: number, style: Enum.EasingStyle, direction: Enum.EasingDirection, see: number, size: number, cover: Frame?): Tween
	local info = TweenInfo.new(seconds, style, direction)
	local scale = stage:FindFirstChildOfClass("UIScale") :: UIScale
	TweenService:Create(scale, info, { Scale = size }):Play()
	if cover then
		TweenService:Create(cover, info, { BackgroundTransparency = see }):Play()
	end
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
	local stage, cover = current.Stage, current.Cover
	stage.Interactable = false
	stage.Name = `{current.Name}Leaving`
	if cover then
		cover.Active = false -- the HUD takes taps again at once
		cover.Name = `{current.Name}CoverLeaving`
	end
	local motion = HudConfig.Motion.Screen
	tween(stage, motion.Exit, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 1, motion.To, cover)
	task.delay(motion.Exit, function()
		stage:Destroy()
		if cover then
			cover:Destroy()
		end
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

-- A full screen's cover, open or leaving: for tests.
function Screen.Cover(name: string): Frame?
	local root = Layers.Get("Cover")
	return (root:FindFirstChild(`{name}Cover`) or root:FindFirstChild(`{name}CoverLeaving`)) :: Frame?
end

-- `size` nil: a full screen.
local function show(name: string, title: string, size: Vector2?): Frame
	local full = size == nil
	local current = open
	local again = current and current.Name == name and current.Frame:FindFirstChild("Body")
	local named = current and current.Frame:FindFirstChild("Title")
	if current and again and named and named:IsA("TextLabel") and (current.Cover ~= nil) == full then
		rescroll(again, scrolled(again))
		again:ClearAllChildren()
		named.Text = title
		current.Size = size
		fit(current.Frame, size)
		return again :: Frame
	end
	Screen.Close()
	local motion = HudConfig.Motion.Screen
	local cover: Frame? = nil
	if full then
		local made = Instance.new("Frame")
		made.Name = `{name}Cover`
		made.BorderSizePixel = 0
		made.BackgroundColor3 = Theme.Colour.Backing
		made.BackgroundTransparency = 1
		made.Size = UDim2.fromScale(1, 1)
		made.Active = true -- a tap on it never reaches the HUD under it
		made.Parent = Layers.Get("Cover")
		cover = made
	end
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
	local frame: Frame
	if full then
		frame = Instance.new("Frame")
		frame.Name = name
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Parent = stage
	else
		frame = Panel.new({
			Name = name,
			Size = if size then UDim2.fromOffset(size.X, size.Y) else UDim2.new(),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = stage,
		})
	end
	frame.Active = true -- a tap on the screen stays on it
	fit(frame, size)
	local record = { Name = name, Frame = frame, Stage = stage, Size = size, Cover = cover }
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
	heading.Visible = not full -- a full screen's owner places its name
	local exit = Button.new({
		Name = if full then "Back" else "Close",
		Text = if full then "Back" else "Close",
		Size = if full then UDim2.fromOffset(Screen.Back.X, Screen.Back.Y) else UDim2.fromOffset(72, Theme.Size.Tap),
		Position = if full then UDim2.fromOffset(Theme.Size.Pad, Theme.Size.Pad) else UDim2.new(1, -Theme.Size.Pad, 0, Theme.Size.Pad / 2),
		AnchorPoint = if full then Vector2.zero else Vector2.new(1, 0),
		Parent = frame,
		OnPress = Screen.Close,
	})
	exit.ZIndex = 3 -- over a full screen's body
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	if full then
		body.Size = UDim2.fromScale(1, 1)
	else
		body.Position = UDim2.fromOffset(Theme.Size.Pad * 2, HEAD)
		body.Size = UDim2.new(1, -Theme.Size.Pad * 4, 1, -(HEAD + Theme.Size.Pad))
	end
	body.Parent = frame
	stage.Parent = Layers.Get("Menus")
	tween(stage, motion.Enter, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, 1, cover)
	open = record
	return body
end

function Screen.Open(name: string, title: string, size: Vector2): Frame
	return show(name, title, size)
end

function Screen.Full(name: string, title: string): Frame
	return show(name, title, nil)
end

return Screen
