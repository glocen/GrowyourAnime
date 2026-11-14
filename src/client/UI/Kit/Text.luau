--!strict
-- Text (client kit): every label the screens show. A label starts empty, and keeps its legible size at any scale: it draws
-- at its authored size, or larger when the layer's scale would take it under Theme.Text.Minimum rendered
-- (handbook/visuals/ui.md, "Scale across devices"). The UI lint reads Text.Legible to check it.

local CollectionService = game:GetService("CollectionService")

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

-- Every label the kit made, by a tag: a weak table keyed by an instance loses it once no script holds its wrapper, though
-- the label lives on, and a row's second line then missed a rescale (TR3's lint at the smallest phone).
local TAG = "NL_Text"

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
	CollectionService:AddTag(label, TAG)
	label.Parent = props.Parent
	return label
end

-- A kit label's authored size changed: a piece laid two ways (UI.BossBar's variants).
function Text.Resize(label: TextLabel, authored: number)
	label:SetAttribute(AUTHORED, authored)
	apply(label, Layers.Scale())
end

-- A label's authored size, for the lint: nil for a label the kit didn't make.
function Text.Authored(label: TextLabel): number?
	local authored = label:GetAttribute(AUTHORED)
	return if type(authored) == "number" then authored else nil
end

Layers.Changed:Connect(function(scale: number)
	for _, label in CollectionService:GetTagged(TAG) do
		if label:IsA("TextLabel") then
			apply(label, scale)
		end
	end
end)

return Text
