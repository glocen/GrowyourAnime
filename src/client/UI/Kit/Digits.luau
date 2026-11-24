--!strict
-- Digits (client kit): a number written the way the HUD's damage numbers are (docs/ui.md, "The HUD, in the world"):
-- Roblox's own face with an outline, widely spaced, one label to a character so the space between them is ours: a
-- gap of the look's Gap in digits, narrowed beside a comma or a "1" (spaceOf). A look
-- is flat in one colour, or a gradient from its head to its foot (the critical's cream to gold), upright or in the face's
-- italic, in Config.Hud.Numbers.Face at ExtraBold or its own face (AR44's takes), with a soft shadow if it has one: a
-- dark copy of the row beside it, offset, under it. Sizes are authored pixels (UI.Theme.Author); the layer's scale grows
-- them, and the outline with them.
--   Digits.new(parent, size, look)   a row of characters, centred in `parent`
--   Digits.Set(row, text)
--   Digits.Restyle(row, size, look)
--   Digits.Fade(row, transparency)
--   Digits.Width(text, size, look)   its authored width, for placing it

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)

export type Shadow = { Colour: Color3, Offset: Vector2, Transparency: number, Spread: number, Soft: number }

export type Look = {
	Colour: Color3?,
	Top: Color3?, -- with Foot: a gradient, head to foot
	Foot: Color3?,
	Ramp: ColorSequence?, -- with Top and Foot: the gradient's every stop, in their place
	Outline: Color3,
	Weight: number,
	Gap: number,
	Italic: boolean,
	Face: string?, -- a font family; nil: Config.Hud.Numbers.Face
	Font: Enum.FontWeight?, -- its weight; nil: ExtraBold
	Digit: number?, -- a digit's width in its text size, the unit of Gap; nil: Config.Hud.Numbers.Digit
	Shadow: Shadow?,
	Bare: boolean?, -- no outline: a copy of the digits laid on them (the critical's shine)
}

local Digits = {}

Digits.Looks = {} :: { [Frame]: Look } -- held until the row is destroyed (Text's note on weak tables)
Digits.Shadows = {} :: { [Frame]: Frame } -- a row's shadow, for the self-test

local function face(look: Look): Font
	return Font.new(look.Face or HudConfig.Numbers.Face, look.Font or Enum.FontWeight.ExtraBold, if look.Italic then Enum.FontStyle.Italic else Enum.FontStyle.Normal)
end

local function digitOf(look: Look): number
	return look.Digit or HudConfig.Numbers.Digit
end

-- A character's width in digits: a comma or a stop about a third, a "1" about 0.7 (measured in Studio: Builder Sans
-- ExtraBold's is 0.66 of its 0, Oswald's 0.75).
local function share(char: string): number
	return if char == "," or char == "." then 0.34 elseif char == "1" then 0.7 elseif char == "+" or char == "-" then 0.8 else 1
end

-- The space after a character, before the next: the gap, narrowed by the narrower of the two, so a comma or a "1"
-- advances by its own width and keeps no whole digit's gap about it (AR44's verdict, fix 2).
local function spaceOf(text: string, i: number, size: number, look: Look): number
	if i >= #text then
		return 0
	end
	return look.Gap * digitOf(look) * size * math.min(share(text:sub(i, i)), share(text:sub(i + 1, i + 1)))
end

function Digits.Width(text: string, size: number, look: Look): number
	local digit = digitOf(look) * size
	local w = 0
	for i = 1, #text do
		w += digit * share(text:sub(i, i)) + spaceOf(text, i, size, look)
	end
	return w
end

-- Each character's space after it, as its own right padding (the list lays them with none of its own).
local function space(row: Frame, text: string, size: number, look: Look)
	for i = 1, #text do
		local label = row:FindFirstChild(`C{i}`)
		local pad = if label then label:FindFirstChildOfClass("UIPadding") else nil
		if pad then
			pad.PaddingRight = UDim.new(0, math.round(spaceOf(text, i, size, look))) -- an offset is whole pixels
		end
	end
end

local function style(label: TextLabel, size: number, look: Look)
	label.FontFace = face(look)
	label.TextSize = size
	local gradient = label:FindFirstChildOfClass("UIGradient")
	if look.Top and look.Foot then
		label.TextColor3 = Color3.new(1, 1, 1)
		if gradient == nil then
			gradient = Instance.new("UIGradient")
			gradient.Rotation = 90 -- head to foot
			gradient.Parent = label
		end
		(gradient :: UIGradient).Color = look.Ramp or ColorSequence.new(look.Top, look.Foot)
	else
		label.TextColor3 = look.Colour or Color3.new(1, 1, 1)
		if gradient then
			gradient:Destroy()
		end
	end
	local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = look.Outline
	-- Authored, as every stroke in the kit: the layer's UIScale grows a stroke's width with the rest (measured, 2026-11-23:
	-- a 6 under a UIScale of 2 draws 12). Multiplied by the scale as well, it drew the scale twice: 1.5 times too thick in
	-- Studio, 0.85 times too thin on the smallest phone.
	stroke.Thickness = look.Weight
	stroke.Enabled = not look.Bare
end

-- A shadow's character: the face and size of its row's, in the shadow's colour, its outline the soft edge.
local function shaded(label: TextLabel, size: number, look: Look, shadow: Shadow, fade: number)
	label.FontFace = face(look)
	label.TextSize = size
	label.TextColor3 = shadow.Colour
	label.TextTransparency = 1 - (1 - fade) * (1 - shadow.Transparency)
	local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = shadow.Colour
	stroke.Thickness = shadow.Spread
	stroke.Transparency = 1 - (1 - fade) * (1 - shadow.Soft)
end

local function char(row: Frame, index: number, z: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = `C{index}`
	label.LayoutOrder = index
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.new()
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = z
	local stroke = Instance.new("UIStroke")
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	Instance.new("UIPadding").Parent = label -- the space after it (space)
	label.Parent = row
	return label
end

local function frame(name: string, size: number, look: Look, z: number): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new()
	row.ZIndex = z
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	return row
end

-- The shadow follows its row: there while the look has one, the same characters, size and gap, beside it by its
-- offset and under it.
local function shade(row: Frame)
	local look = Digits.Looks[row]
	local shadow = look.Shadow
	local copy = Digits.Shadows[row]
	if shadow == nil then
		if copy then
			copy:Destroy()
			Digits.Shadows[row] = nil
		end
		return
	end
	local size = row:GetAttribute("Size") :: number
	local fade = (row:GetAttribute("Fade") :: number?) or 0
	if copy == nil then
		local made = frame("Shadow", size, look, row.ZIndex - 1)
		made.Parent = row.Parent
		Digits.Shadows[row] = made
		copy = made
	end
	local s = copy :: Frame
	s.Position = UDim2.new(0.5, shadow.Offset.X, 0.5, shadow.Offset.Y)
	local text = row:GetAttribute("Text") :: string
	for i = 1, #text do
		local label = s:FindFirstChild(`C{i}`) :: TextLabel?
		if label == nil then
			label = char(s, i, s.ZIndex)
		end
		(label :: TextLabel).Text = text:sub(i, i)
		shaded(label :: TextLabel, size, look, shadow, fade)
	end
	for _, child in s:GetChildren() do
		local index = tonumber(child.Name:match("^C(%d+)$"))
		if index and index > #text then
			child:Destroy()
		end
	end
	space(s, text, size, look)
end

function Digits.new(parent: Instance, size: number, look: Look): Frame
	local row = frame("Digits", size, look, 2)
	row:SetAttribute("Text", "")
	row:SetAttribute("Size", size)
	row.Parent = parent
	Digits.Looks[row] = look
	row.Destroying:Connect(function()
		Digits.Looks[row] = nil
		local copy = Digits.Shadows[row]
		if copy then
			copy:Destroy()
			Digits.Shadows[row] = nil
		end
	end)
	shade(row)
	return row
end

function Digits.Set(row: Frame, text: string)
	if row:GetAttribute("Text") == text then
		return
	end
	row:SetAttribute("Text", text)
	local look = Digits.Looks[row]
	local size = row:GetAttribute("Size") :: number
	local fade = (row:GetAttribute("Fade") :: number?) or 0
	for i = 1, #text do
		local label = row:FindFirstChild(`C{i}`) :: TextLabel?
		if label == nil then
			label = char(row, i, 2)
			style(label :: TextLabel, size, look)
			if fade > 0 then
				(label :: TextLabel).TextTransparency = fade;
				((label :: TextLabel):FindFirstChildOfClass("UIStroke") :: UIStroke).Transparency = fade
			end
		end
		(label :: TextLabel).Text = text:sub(i, i)
	end
	for _, child in row:GetChildren() do
		local index = tonumber(child.Name:match("^C(%d+)$"))
		if index and index > #text then
			child:Destroy()
		end
	end
	space(row, text, size, look)
	shade(row)
end

function Digits.Restyle(row: Frame, size: number, look: Look)
	Digits.Looks[row] = look
	row:SetAttribute("Size", size)
	for _, child in row:GetChildren() do
		if child:IsA("TextLabel") then
			style(child, size, look)
		end
	end
	space(row, row:GetAttribute("Text") :: string, size, look)
	shade(row)
end

-- Fades every character and its outline together, and the shadow with them: 0 shown, 1 gone.
function Digits.Fade(row: Frame, transparency: number)
	row:SetAttribute("Fade", transparency)
	for _, child in row:GetChildren() do
		if child:IsA("TextLabel") then
			child.TextTransparency = transparency
			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = transparency
			end
		end
	end
	local copy = Digits.Shadows[row]
	local shadow = Digits.Looks[row] and Digits.Looks[row].Shadow
	if copy and shadow then
		for _, child in copy:GetChildren() do
			if child:IsA("TextLabel") then
				child.TextTransparency = 1 - (1 - transparency) * (1 - shadow.Transparency)
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Transparency = 1 - (1 - transparency) * (1 - shadow.Soft)
				end
			end
		end
	end
end

return Digits
