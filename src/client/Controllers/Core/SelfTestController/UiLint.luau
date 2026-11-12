--!strict
-- UiLint (client, Studio only): checks every label the player can see now, on whatever is open (from the handbook's,
-- handbook/tech/studio/UiLint.luau, without its shadow check: this kit draws no shadow copies). For each visible, non-empty
-- label in one of our containers (named NL_...):
--   its text fits its box, unless it truncates on purpose (a line box may overrun by FIT_TOLERANCE pixels);
--   it renders at least Theme.Text.Minimum;
--   it lies inside its screen (not for the World layer's plates, which follow the world off the edges);
--     a label a scrolling list (or any clipping frame) hides entirely isn't drawn, so isn't checked, and one it cuts
--     is checked by the part it shows;
--   it doesn't show Roblox's default "Label".
-- And for what the player touches and reads around the world (docs/ui.md, rule 1; TR3):
--   every button that takes a tap is Theme.Size.Touch or more on its least side, rendered;
--   each piece of the HUD and of an open screen lies inside its layer's safe area (Layers: clear of Roblox's top bar and
--     the notch; a test's phone box when one is set);
--   no two pieces of the HUD overlap;
--   none sits under the thumbs' controls (Roblox's jump button and fixed thumbstick, on a touch screen).

local Players = game:GetService("Players")

local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)

local OURS = "NL_"
local WORLD = "NL_World"
local HUD = "NL_Hud"
local INSET: { [string]: boolean } = { NL_Hud = true, NL_Menus = true } -- laid out inside the safe area (Layers)
local THUMBS: { [string]: boolean } = { JumpButton = true, ThumbstickFrame = true } -- Roblox's touch controls, by name
local TOLERANCE = 1 -- pixels
local FIT_TOLERANCE = 2 -- pixels a line box may overrun its frame
local PLACEHOLDER = "Label"

local UiLint = {}

export type Report = {
	Checked: number,
	Fit: { string },
	Size: { string },
	Screen: { string },
	Placeholder: { string },
	Touch: { string },
	Safe: { string },
	Overlap: { string },
	Thumbs: { string },
}

-- Whether a piece draws: visible all the way up to its container, and that container enabled.
local function up(object: GuiObject): boolean
	local node: Instance? = object
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and (node :: LayerCollector).Enabled
end

local function overlaps(a: GuiObject, b: GuiObject): boolean
	local aLow, aHigh = a.AbsolutePosition, a.AbsolutePosition + a.AbsoluteSize
	local bLow, bHigh = b.AbsolutePosition, b.AbsolutePosition + b.AbsoluteSize
	return math.min(aHigh.X, bHigh.X) - math.max(aLow.X, bLow.X) > TOLERANCE
		and math.min(aHigh.Y, bHigh.Y) - math.max(aLow.Y, bLow.Y) > TOLERANCE
end

local function inside(piece: GuiObject, area: GuiObject): boolean
	local low, high = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
	local top, bottom = area.AbsolutePosition, area.AbsolutePosition + area.AbsoluteSize
	return low.X >= top.X - TOLERANCE and low.Y >= top.Y - TOLERANCE and high.X <= bottom.X + TOLERANCE and high.Y <= bottom.Y + TOLERANCE
end

-- Whether a label actually draws: visible all the way up, in an enabled container of ours, not faded out.
local function shown(object: TextLabel): boolean
	if object.TextTransparency >= 0.95 or object.Text == "" then
		return false
	end
	local node: Instance? = object
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and (node :: LayerCollector).Enabled and string.sub(node.Name, 1, #OURS) == OURS
end

-- The part of `label` its clipping frames let through, as (top left, bottom right) on screen, or nil when they hide all
-- of it (a row scrolled out of its list).
local function drawn(label: TextLabel): (Vector2?, Vector2?)
	local low, high = label.AbsolutePosition, label.AbsolutePosition + label.AbsoluteSize
	local node: Instance? = label.Parent
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and (node :: GuiObject).ClipsDescendants then
			local frame = node :: GuiObject
			local top, bottom = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
			low = Vector2.new(math.max(low.X, top.X), math.max(low.Y, top.Y))
			high = Vector2.new(math.min(high.X, bottom.X), math.min(high.Y, bottom.Y))
			if high.X <= low.X or high.Y <= low.Y then
				return nil, nil
			end
		end
		node = node.Parent
	end
	return low, high
end

-- The product of the UIScales over `object` (Layers fits each layer with one).
local function scaleOf(object: Instance): number
	local scale = 1
	local node: Instance? = object
	while node do
		local uiScale = node:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		node = node.Parent
	end
	return scale
end

local function short(object: Instance): string
	local parts = {}
	local node: Instance? = object
	for _ = 1, 3 do
		if not node or node:IsA("PlayerGui") then
			break
		end
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

function UiLint.Run(): Report
	local report: Report = { Checked = 0, Fit = {}, Size = {}, Screen = {}, Placeholder = {}, Touch = {}, Safe = {}, Overlap = {}, Thumbs = {} }
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	-- The taps: every button the player can press now.
	for _, object in gui:GetDescendants() do
		if object:IsA("GuiButton") and object.Active and up(object) then
			local screen = object:FindFirstAncestorOfClass("ScreenGui")
			if screen and screen.Name ~= WORLD and string.sub(screen.Name, 1, #OURS) == OURS then
				local side = math.min(object.AbsoluteSize.X, object.AbsoluteSize.Y)
				if side < Theme.Size.Touch - 0.5 then
					table.insert(report.Touch, `{short(object)} ({math.floor(object.AbsoluteSize.X)}x{math.floor(object.AbsoluteSize.Y)} < {Theme.Size.Touch})`)
				end
			end
		end
	end
	-- The pieces: each top-level piece of an inset layer, inside its safe area; the HUD's apart and clear of the thumbs.
	local thumbs: { GuiObject } = {}
	local touch = gui:FindFirstChild("TouchGui")
	if touch and touch:IsA("ScreenGui") and touch.Enabled then
		for _, control in touch:GetDescendants() do
			if control:IsA("GuiObject") and THUMBS[control.Name] and up(control) then
				table.insert(thumbs, control)
			end
		end
	end
	for _, screen in gui:GetChildren() do
		local root = if INSET[screen.Name] and screen:IsA("ScreenGui") and screen.Enabled then screen:FindFirstChild("Root") else nil
		if root == nil or not root:IsA("GuiObject") then
			continue
		end
		local pieces: { GuiObject } = {}
		for _, piece in root:GetChildren() do
			if piece:IsA("GuiObject") and piece.Visible then
				table.insert(pieces, piece)
				if not inside(piece, root) then
					table.insert(report.Safe, short(piece))
				end
			end
		end
		if screen.Name == HUD then
			for i = 1, #pieces do
				for j = i + 1, #pieces do
					if overlaps(pieces[i], pieces[j]) then
						table.insert(report.Overlap, `{pieces[i].Name} and {pieces[j].Name}`)
					end
				end
				for _, control in thumbs do
					if overlaps(pieces[i], control) then
						table.insert(report.Thumbs, `{pieces[i].Name} under {control.Name}`)
					end
				end
			end
		end
	end
	for _, object in gui:GetDescendants() do
		if not object:IsA("TextLabel") or not shown(object) then
			continue
		end
		local label = object :: TextLabel
		local low, high = drawn(label)
		if low == nil or high == nil then
			continue
		end
		report.Checked += 1
		local name = short(label)
		if label.Text == PLACEHOLDER then
			table.insert(report.Placeholder, name)
		end
		local bounds, box = label.TextBounds, label.AbsoluteSize
		local overruns = bounds.X > box.X + FIT_TOLERANCE or bounds.Y > box.Y + FIT_TOLERANCE
		if not label.TextFits and overruns and not label.TextScaled and label.TextTruncate == Enum.TextTruncate.None then
			table.insert(report.Fit, `{name} ({math.ceil(bounds.X)}x{math.ceil(bounds.Y)} in {math.floor(box.X)}x{math.floor(box.Y)})`)
		end
		local screen = label:FindFirstAncestorOfClass("ScreenGui")
		if screen then
			local rendered = label.TextSize * scaleOf(label)
			if rendered < Theme.Text.Minimum - 0.5 then
				table.insert(report.Size, `{name} ({string.format("%.1f", rendered)} px < {Theme.Text.Minimum})`)
			end
			if screen.Name ~= WORLD then
				-- from the layer's root (its safe area, or a test's phone box): layers that ignore the GUI inset start above y = 0
				local root = screen:FindFirstChild("Root")
				local area: GuiObject = if root and root:IsA("GuiObject") then root else screen :: any
				local position, far = low - area.AbsolutePosition, high - area.AbsolutePosition
				local limit = area.AbsoluteSize
				if position.X < -TOLERANCE or position.Y < -TOLERANCE or far.X > limit.X + TOLERANCE or far.Y > limit.Y + TOLERANCE then
					table.insert(report.Screen, name)
				end
			end
		end
	end
	return report
end

-- "a; b; c +2 more", or how many labels were checked when the list is empty.
function UiLint.Detail(list: { string }, checked: number): string
	if #list == 0 then
		return `{checked} labels checked`
	end
	local shown = {}
	for index = 1, math.min(#list, 6) do
		table.insert(shown, list[index])
	end
	return table.concat(shown, "; ") .. (if #list > 6 then ` +{#list - 6} more` else "")
end

return UiLint
