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

local Players = game:GetService("Players")

local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)

local OURS = "NL_"
local WORLD = "NL_World"
local TOLERANCE = 1 -- pixels
local FIT_TOLERANCE = 2 -- pixels a line box may overrun its frame
local PLACEHOLDER = "Label"

local UiLint = {}

export type Report = { Checked: number, Fit: { string }, Size: { string }, Screen: { string }, Placeholder: { string } }

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
	local report: Report = { Checked = 0, Fit = {}, Size = {}, Screen = {}, Placeholder = {} }
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
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
				-- from the screen's own origin: layers that ignore the GUI inset start above y = 0
				local position, far = low - screen.AbsolutePosition, high - screen.AbsolutePosition
				local limit = screen.AbsoluteSize
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
