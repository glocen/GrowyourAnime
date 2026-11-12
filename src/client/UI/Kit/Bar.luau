--!strict
-- Bar (client kit): a channel that fills, left to right. Grey: a flat fill; the finished kit makes it a conduit of light
-- (docs/ui.md, rule 3). Bars are told apart by place and label as well as colour (handbook/visuals/ui.md, "Don't").

local Theme = require(script.Parent.Parent.Theme)

export type Props = {
	Name: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Colour: Color3,
	LayoutOrder: number?,
}

local Bar = {}

function Bar.new(props: Props): Frame
	local channel = Instance.new("Frame")
	channel.Name = props.Name
	channel.Size = props.Size
	channel.Position = props.Position or UDim2.new()
	channel.AnchorPoint = props.AnchorPoint or Vector2.zero
	channel.BackgroundColor3 = Theme.Colour.Channel
	channel.BorderSizePixel = 0
	channel.LayoutOrder = props.LayoutOrder or 0
	channel.ClipsDescendants = true
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = props.Colour
	fill.BorderSizePixel = 0
	fill.Parent = channel
	for _, frame in { channel, fill } do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, math.floor(Theme.Size.Bar / 2))
		corner.Parent = frame
	end
	channel.Parent = props.Parent
	return channel
end

-- Fills `bar` to `share` of its length (0 to 1).
function Bar.Set(bar: Frame, share: number)
	local fill = bar:FindFirstChild("Fill") :: Frame?
	if fill then
		local clamped = math.clamp(if share == share then share else 0, 0, 1)
		fill.Size = UDim2.fromScale(clamped, 1)
		bar:SetAttribute("Share", clamped)
	end
end

-- Recolours the fill.
function Bar.Colour(bar: Frame, colour: Color3)
	local fill = bar:FindFirstChild("Fill") :: Frame?
	if fill then
		fill.BackgroundColor3 = colour
	end
end

return Bar
