--!strict
-- Panel (client kit): a plate with an edge. Grey: a rounded frame; the finished kit gives it its shard-cut corners.

local Theme = require(script.Parent.Parent.Theme)

export type Props = {
	Name: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Colour: Color3?,
	Transparency: number?,
	Edge: boolean?, -- false for a row inside a panel
}

local Panel = {}

function Panel.new(props: Props): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.Name
	frame.Size = props.Size
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundColor3 = props.Colour or Theme.Colour.Plate
	frame.BackgroundTransparency = props.Transparency or Theme.Transparency.Plate
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
	corner.Parent = frame
	if props.Edge ~= false then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Theme.Colour.Line
		stroke.Thickness = Theme.Size.Edge
		stroke.Parent = frame
	end
	frame.Parent = props.Parent
	return frame
end

-- A panel's edge lit in the Ready colour, twice as thick: a place that asks for the player's next step (the Breaker's
-- plate while a shard waits in the bag; research's read of TR2's fixes, 2026-11-12). Off, its edge as made.
function Panel.Lit(frame: GuiObject, on: boolean)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if on then Theme.Colour.Ready else Theme.Colour.Line
		stroke.Thickness = if on then Theme.Size.Edge * 2 else Theme.Size.Edge
	end
end

-- A list inside `frame`: its children stack in order, `gap` apart.
function Panel.List(frame: GuiObject, direction: Enum.FillDirection?, gap: number?): UIListLayout
	local list = Instance.new("UIListLayout")
	list.FillDirection = direction or Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, gap or Theme.Size.Gap)
	list.Parent = frame
	return list
end

-- Padding inside `frame`, all four sides.
function Panel.Pad(frame: GuiObject, pad: number?)
	local padding = Instance.new("UIPadding")
	local p = UDim.new(0, pad or Theme.Size.Pad)
	padding.PaddingLeft, padding.PaddingRight, padding.PaddingTop, padding.PaddingBottom = p, p, p, p
	padding.Parent = frame
end

return Panel
