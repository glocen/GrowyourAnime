--!strict
-- Digits (client kit): a number written the way the HUD's damage numbers are (docs/ui.md, "The HUD, in the world"):
-- Roblox's own face with an outline, widely spaced, one label to a character so the space between them is ours. A look
-- is flat in one colour, or a gradient from its head to its foot (the critical's cream to gold), upright or in the face's
-- italic. Sizes are authored pixels (UI.Theme.Author); the layer's scale grows them, and the outline with them.
--   Digits.new(parent, size, look)   a row of characters, centred in `parent`
--   Digits.Set(row, text)
--   Digits.Restyle(row, size, look)
--   Digits.Width(text, size, look)   its authored width, for placing it

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Layers = require(script.Parent.Parent.Layers)

export type Look = {
	Colour: Color3?,
	Top: Color3?, -- with Foot: a gradient, head to foot
	Foot: Color3?,
	Outline: Color3,
	Weight: number,
	Gap: number,
	Italic: boolean,
}

local Digits = {}

Digits.Looks = {} :: { [Frame]: Look } -- held until the row is destroyed (Text's note on weak tables)

local function face(italic: boolean): Font
	return Font.new(HudConfig.Numbers.Face, Enum.FontWeight.ExtraBold, if italic then Enum.FontStyle.Italic else Enum.FontStyle.Normal)
end

-- A comma or a stop is about a third of a digit.
local function share(char: string): number
	return if char == "," or char == "." then 0.34 elseif char == "+" or char == "-" then 0.8 else 1
end

function Digits.Width(text: string, size: number, look: Look): number
	local digit = HudConfig.Numbers.Digit * size
	local w = 0
	for i = 1, #text do
		w += digit * share(text:sub(i, i))
	end
	return w + math.max(#text - 1, 0) * look.Gap * digit
end

local function style(label: TextLabel, size: number, look: Look)
	label.FontFace = face(look.Italic)
	label.TextSize = size
	local gradient = label:FindFirstChildOfClass("UIGradient")
	if look.Top and look.Foot then
		label.TextColor3 = Color3.new(1, 1, 1)
		if gradient == nil then
			gradient = Instance.new("UIGradient")
			gradient.Rotation = 90 -- head to foot
			gradient.Parent = label
		end
		(gradient :: UIGradient).Color = ColorSequence.new(look.Top, look.Foot)
	else
		label.TextColor3 = look.Colour or Color3.new(1, 1, 1)
		if gradient then
			gradient:Destroy()
		end
	end
	local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = look.Outline
	stroke.Thickness = look.Weight * Layers.Scale() -- a stroke's width isn't grown by the layer's UIScale
end

local function char(row: Frame, index: number, size: number, look: Look): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = `C{index}`
	label.LayoutOrder = index
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.new()
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 2
	local stroke = Instance.new("UIStroke")
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	style(label, size, look)
	label.Parent = row
	return label
end

function Digits.new(parent: Instance, size: number, look: Look): Frame
	local row = Instance.new("Frame")
	row.Name = "Digits"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new()
	row.ZIndex = 2
	row:SetAttribute("Text", "")
	row:SetAttribute("Size", size)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, look.Gap * HudConfig.Numbers.Digit * size)
	list.Parent = row
	row.Parent = parent
	Digits.Looks[row] = look
	row.Destroying:Connect(function()
		Digits.Looks[row] = nil
	end)
	return row
end

function Digits.Set(row: Frame, text: string)
	if row:GetAttribute("Text") == text then
		return
	end
	row:SetAttribute("Text", text)
	local look = Digits.Looks[row]
	local size = row:GetAttribute("Size") :: number
	for i = 1, #text do
		local label = row:FindFirstChild(`C{i}`) :: TextLabel?
		if label == nil then
			label = char(row, i, size, look)
		end
		(label :: TextLabel).Text = text:sub(i, i)
	end
	for _, child in row:GetChildren() do
		local index = tonumber(child.Name:match("^C(%d+)$"))
		if index and index > #text then
			child:Destroy()
		end
	end
end

function Digits.Restyle(row: Frame, size: number, look: Look)
	Digits.Looks[row] = look
	row:SetAttribute("Size", size)
	local list = row:FindFirstChildOfClass("UIListLayout")
	if list then
		list.Padding = UDim.new(0, look.Gap * HudConfig.Numbers.Digit * size)
	end
	for _, child in row:GetChildren() do
		if child:IsA("TextLabel") then
			style(child, size, look)
		end
	end
end

-- Fades every character and its outline together: 0 shown, 1 gone.
function Digits.Fade(row: Frame, transparency: number)
	for _, child in row:GetChildren() do
		if child:IsA("TextLabel") then
			child.TextTransparency = transparency
			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = transparency
			end
		end
	end
end

return Digits
