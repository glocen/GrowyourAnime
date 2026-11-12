--!strict
-- Row (client kit): one line of a screen's list: what it is on the left, the one thing to do with it on the right.
--   Row.new{ Parent, Order, Text, Action?, OnPress?, Disabled? } -> the row; its button is row.Action

local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)

export type Props = {
	Name: string?,
	Parent: Instance,
	Order: number,
	Text: string,
	Colour: Color3?, -- the label's
	Action: string?, -- the button's label; no button without it
	Primary: boolean?,
	Disabled: string?, -- the reason the button can't be pressed now
	OnPress: (() -> ())?,
	ActionWidth: number?,
}

local Row = {}

Row.Height = Theme.Size.Tap

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
	local label = Text.new({
		Name = "Label",
		Size = Theme.Text.Body,
		Colour = props.Colour,
		Truncate = true,
		Box = UDim2.new(1, -(width + Theme.Size.Pad * 3), 1, 0),
		Position = UDim2.fromOffset(Theme.Size.Pad, 0),
		Parent = row,
	})
	label.Text = props.Text
	if props.Action then
		local button = Button.new({
			Name = "Action",
			Text = props.Action,
			Primary = props.Primary,
			Size = UDim2.new(0, width, 1, -6),
			Position = UDim2.new(1, -3, 0.5, 0),
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
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	Panel.List(list, nil, 4)
	list.Parent = parent
	return list
end

return Row
