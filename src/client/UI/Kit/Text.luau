--!strict
-- Text (client kit): every label the screens show. A label starts empty, and keeps its legible size at any scale: it draws
-- at its authored size, or larger when the layer's scale would take it under Theme.Text.Minimum rendered
-- (handbook/visuals/ui.md, "Scale across devices"). The UI lint reads Text.Legible to check it.
-- A layer can wear a face of its own (docs/ui.md, rule 3: the HUD's; Config.Hud.Face): Text.Face gives every kit label
-- under a root its role's weight in that face, now and as labels join, so the face is one value switched at runtime.
--   Text.new{ Name, Size, Font, ... }     a label
--   Text.Face(root, face)                 every kit label under `root` in `face`, from now on
--   Text.Wide(label, text)                how wide `text` draws in the label's own face and size, authored pixels
--   Text.Epoch()                          goes up when a width asked of Text.Wide arrives: fit again

local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")

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

-- A face: its family, and the weight (an Enum.FontWeight's name) each of the kit's roles draws in (Theme.Font's three).
-- Small: the face a label authored under Under draws in instead.
export type Face = { Family: string, Body: string, Strong: string, Number: string, Small: Face?, Under: number? }

local Text = {}

local AUTHORED = "NL_TextSize" -- the attribute holding a label's authored size
local ROLE = "NL_Font" -- and its role, one of Theme.Font's names, when it was made in one

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

local faced: { [Instance]: Face } = {} -- a root to the face its labels wear

local function weight(name: string): Enum.FontWeight
	local ok, found = pcall(function(): Enum.FontWeight
		return (Enum.FontWeight :: any)[name]
	end)
	return if ok and found then found else Enum.FontWeight.Regular
end

local function reface(label: TextLabel, face: Face)
	local role, authored = label:GetAttribute(ROLE), label:GetAttribute(AUTHORED)
	if type(role) ~= "string" or type(authored) ~= "number" then
		return
	end
	local small = face.Small
	local use: Face = if small and authored < (face.Under or 0) then small else face
	local name = (use :: any)[role]
	local font = Font.new(use.Family, weight(if type(name) == "string" then name else "Regular"))
	if label.FontFace ~= font then
		label.FontFace = font
	end
end

function Text.new(props: Props): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.Name
	label.BackgroundTransparency = 1
	label.Text = ""
	local font = props.Font or Theme.Font.Body
	label.FontFace = font
	label.TextColor3 = props.Colour or Theme.Colour.Text
	label.TextXAlignment = props.Align or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = props.Wrap == true
	label.TextTruncate = if props.Truncate then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None
	label.Size = props.Box or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label:SetAttribute(AUTHORED, props.Size or Theme.Text.Body)
	for role, own in Theme.Font :: { [string]: Font } do
		if own == font then
			label:SetAttribute(ROLE, role)
		end
	end
	apply(label, Layers.Scale())
	CollectionService:AddTag(label, TAG)
	label.Parent = props.Parent
	-- Made straight into a faced layer, it wears the face before it's first drawn (DescendantAdded answers a moment later).
	for root, face in faced do
		if label:IsDescendantOf(root) then
			reface(label, face)
		end
	end
	return label
end

-- A kit label's authored size changed: a piece laid two ways (UI.BossBar's variants).
function Text.Resize(label: TextLabel, authored: number)
	label:SetAttribute(AUTHORED, authored)
	apply(label, Layers.Scale())
	for root, face in faced do
		if label:IsDescendantOf(root) then
			reface(label, face)
		end
	end
end

-- A label's authored size, for the lint: nil for a label the kit didn't make.
function Text.Authored(label: TextLabel): number?
	local authored = label:GetAttribute(AUTHORED)
	return if type(authored) == "number" then authored else nil
end

-- Every kit label under `root` wears `face`: those there now, and each that joins.
function Text.Face(root: Instance, face: Face)
	local first = faced[root] == nil
	faced[root] = face
	for _, label in CollectionService:GetTagged(TAG) do
		if label:IsA("TextLabel") and label:IsDescendantOf(root) then
			reface(label, face)
		end
	end
	if first then
		root.DescendantAdded:Connect(function(made: Instance)
			if made:IsA("TextLabel") and CollectionService:HasTag(made, TAG) then
				reface(made, faced[root])
			end
		end)
	end
end

-- Builder Sans measures at once, by Roblox's own enum; any other face is asked of the engine, which answers a moment
-- later the first time.
local STOCK: { [string]: { [Enum.FontWeight]: Enum.Font } } = {
	["rbxasset://fonts/families/BuilderSans.json"] = {
		[Enum.FontWeight.Regular] = Enum.Font.BuilderSans,
		[Enum.FontWeight.Medium] = Enum.Font.BuilderSansMedium,
		[Enum.FontWeight.Bold] = Enum.Font.BuilderSansBold,
		[Enum.FontWeight.ExtraBold] = Enum.Font.BuilderSansExtraBold,
	},
}
local ROOM = Vector2.new(4000, 400)
local widths: { [string]: number } = {}
local asked: { [string]: boolean } = {}
local epoch = 0

function Text.Epoch(): number
	return epoch
end

-- How wide `text` draws in the label's own face at the size it draws. A face the engine must be asked about answers
-- with Builder Sans Bold's width until its own arrives; Text.Epoch then goes up, so whoever fitted by it fits again.
function Text.Wide(label: TextLabel, text: string): number
	local font = label.FontFace
	local stock = STOCK[font.Family]
	local enum = if stock then stock[font.Weight] else nil
	if enum then
		return TextService:GetTextSize(text, label.TextSize, enum, ROOM).X
	end
	local key = `{font.Family}\0{font.Weight.Value}\0{label.TextSize}\0{text}`
	if widths[key] == nil and not asked[key] then
		asked[key] = true
		local size = label.TextSize
		task.spawn(function()
			local params = Instance.new("GetTextBoundsParams")
			params.Text = text
			params.Font = font
			params.Size = size
			params.Width = ROOM.X
			local ok, bounds = pcall(function(): Vector2
				return TextService:GetTextBoundsAsync(params)
			end)
			if ok then
				widths[key] = bounds.X
				epoch += 1
			end
		end)
	end
	return widths[key] or TextService:GetTextSize(text, label.TextSize, Enum.Font.BuilderSansBold, ROOM).X
end

Layers.Changed:Connect(function(scale: number)
	for _, label in CollectionService:GetTagged(TAG) do
		if label:IsA("TextLabel") then
			apply(label, scale)
		end
	end
end)

return Text
