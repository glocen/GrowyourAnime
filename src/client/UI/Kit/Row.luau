--!strict
-- Row (client kit): one item of a screen's list: what it is on the left, the one thing to do with it on the right.
-- The name has its own line; its state, count or time goes on a quieter second line under it, so neither cuts the other.
--   Row.new{ Parent, Order, Text, Detail?, Action?, OnPress?, Disabled? } -> the row; its button is row.Action,
--   its lines row.Label and row.Detail

local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)

export type Props = {
	Name: string?,
	Parent: Instance,
	Order: number,
	Text: string, -- the name: cut with "…" only past the longest name the game has
	Detail: string?, -- the second line: a state, a count, a time; never cut (handbook/visuals/ui.md, "Text that fits")
	Colour: Color3?, -- the name's
	Action: string?, -- the button's label; no button without it
	Primary: boolean?,
	Disabled: string?, -- the reason the button can't be pressed now
	OnPress: (() -> ())?,
	ActionWidth: number?,
}

local Row = {}

local INSET = 3 -- authored pixels between the row's edge and its button, top and bottom
local LINE = 22 -- the name's line box, authored
local DETAIL = 18 -- the second line's box

-- Every row is this tall, one line or two, so its button holds a whole touch target and a list keeps one rhythm.
Row.Height = Theme.Size.Tap + INSET * 2

function Row.new(props: Props): Frame
	local row = Panel.new({
		Name = props.Name or "Row",
		Size = UDim2.new(1, 0, 0, Row.Height),
		Colour = Theme.Colour.PlateHigh,
		Transparency = 0.4,
		Edge = false,
		Parent = props.Parent,
	})
	row.LayoutOrder = props.Order
	local width = if props.Action then (props.ActionWidth or 96) else 0
	local across = UDim.new(1, -(width + Theme.Size.Pad * 3))
	local top = (Row.Height - LINE - DETAIL) / 2
	local two = props.Detail ~= nil
	local label = Text.new({
		Name = "Label",
		Size = Theme.Text.Body,
		Colour = props.Colour,
		Truncate = true,
		Box = if two then UDim2.new(across, UDim.new(0, LINE)) else UDim2.new(across, UDim.new(1, 0)),
		Position = UDim2.fromOffset(Theme.Size.Pad, if two then top else 0),
		Parent = row,
	})
	label.Text = props.Text
	if two then
		local detail = Text.new({
			Name = "Detail",
			Size = Theme.Text.Caption,
			Colour = Theme.Colour.TextDim,
			Box = UDim2.new(across, UDim.new(0, DETAIL)),
			Position = UDim2.fromOffset(Theme.Size.Pad, top + LINE),
			Parent = row,
		})
		detail.Text = props.Detail :: string
	end
	if props.Action then
		local button = Button.new({
			Name = "Action",
			Text = props.Action,
			Primary = props.Primary,
			Size = UDim2.new(0, width, 1, -INSET * 2),
			Position = UDim2.new(1, -INSET, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Parent = row,
			OnPress = props.OnPress or function() end,
		})
		if props.Disabled then
			Button.Set(button, { Disabled = props.Disabled })
		end
	end
	return row
end

-- A scrolling list filling `parent`, for rows.
function Row.List(parent: Instance, name: string, box: UDim2?, position: UDim2?): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.Name = name
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = box or UDim2.fromScale(1, 1)
	list.Position = position or UDim2.new()
	list.ScrollBarThickness = 4
	list.VerticalScrollBarInset = Enum.ScrollBarInset.Always -- the bar has its own lane, never over a row's button
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	Panel.List(list, nil, 4)
	list.Parent = parent
	return list
end

return Row
