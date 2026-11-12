--!strict
-- Text (client kit): every label the screens show. A label starts empty, and keeps its legible size at any scale: it draws
-- at its authored size, or larger when the layer's scale would take it under Theme.Text.Minimum rendered
-- (handbook/visuals/ui.md, "Scale across devices"). The UI lint reads Text.Legible to check it.

local Theme = require(script.Parent.Parent.Theme)
local Layers = require(script.Parent.Parent.Layers)

export type Props = {
	Name: string,
	Size: number?, -- authored, a Theme.Text size; Body when left out
	Font: Font?,
	Colour: Color3?,
	Align: Enum.TextXAlignment?,
	Box: UDim2?, -- the label's frame; fills its parent when left out
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Wrap: boolean?,
	Truncate: boolean?, -- cut with "…" rather than overrun: never for a price or a count (handbook, "Text that fits")
}

local Text = {}

local AUTHORED = "NL_TextSize" -- the attribute holding a label's authored size

local labels: { [TextLabel]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- The size a label authored at `authored` draws at, at `scale`.
function Text.Legible(authored: number, scale: number): number
	return math.max(authored, math.ceil(Theme.Text.Minimum / math.max(scale, 0.01)))
end

local function apply(label: TextLabel, scale: number)
	local authored = label:GetAttribute(AUTHORED)
	if type(authored) == "number" then
		label.TextSize = Text.Legible(authored, scale)
	end
end

function Text.new(props: Props): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.Name
	label.BackgroundTransparency = 1
	label.Text = ""
	label.FontFace = props.Font or Theme.Font.Body
	label.TextColor3 = props.Colour or Theme.Colour.Text
	label.TextXAlignment = props.Align or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = props.Wrap == true
	label.TextTruncate = if props.Truncate then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None
	label.Size = props.Box or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label:SetAttribute(AUTHORED, props.Size or Theme.Text.Body)
	apply(label, Layers.Scale())
	labels[label] = true
	label.Parent = props.Parent
	return label
end

-- A label's authored size, for the lint: nil for a label the kit didn't make.
function Text.Authored(label: TextLabel): number?
	local authored = label:GetAttribute(AUTHORED)
	return if type(authored) == "number" then authored else nil
end

Layers.Changed:Connect(function(scale: number)
	for label in labels do
		apply(label, scale)
	end
end)

return Text
