--!strict
-- Edge (client kit): AR68 M's dark edge on a word (Config.Hud.M.Edge): a near-black stroke round it, and a copy of the
-- word in the same edge Drop lower, under it, so the off-white reads on the world by day and on the slate alike. The copy
-- follows its word: its text, size, face, box, visibility, fade and swell (a Pop's UIScale).
--   Edge.Wear(label, own?)        the edge and its drop on a word, once; own { Line, Drop, Colour, Clear } in the
--                                 frame's points overrides Config.Hud.M.Edge for this word (the top left's A)
--   Edge.Fade(label, clear)       the word, its edge and its drop faded together
--   Edge.Size(authored, em?) -> size  a word's size at the layer's scale, never under the kit's floor; em the face's
--                                 (Oswald's Config.Hud.M.Em unless named)
--   Edge.Refit(root)              every drop under `root` laid again (after a layout)

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Layers = require(script.Parent.Parent.Layers)
local Text = require(script.Parent.Text)

local Edge = {}

local DROP = "Drop"

local owns: { [TextLabel]: any } = setmetatable({}, { __mode = "k" }) :: any

-- A word's edge: the kit's, with what the word was given in its own place.
local function edge(label: TextLabel?): any
	local e = HudConfig.M.Edge
	local own = if label then owns[label] else nil
	if own == nil then
		return e
	end
	return {
		Colour = own.Colour or e.Colour,
		Clear = own.Clear or e.Clear,
		Line = own.Line or e.Line,
		Drop = own.Drop or e.Drop,
	}
end

function Edge.Size(authored: number, em: number?): number
	-- Roblox sets a face smaller than a page does at the same size: Em says how much (Config.Hud.M.Em, Oswald's)
	return Text.Legible(authored / (em or HudConfig.M.Em), Layers.Scale())
end

local function stroke(label: TextLabel, e: any)
	local line = label:FindFirstChild("Edge") :: UIStroke? or Instance.new("UIStroke")
	line.Name = "Edge"
	line.Color = e.Colour
	line.Thickness = e.Line * HudConfig.M.Per
	line.Transparency = e.Clear
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	line.LineJoinMode = Enum.LineJoinMode.Round
	line.Parent = label
end

local function dropOf(label: TextLabel): TextLabel?
	local parent = label.Parent
	return if parent then parent:FindFirstChild(label.Name .. DROP) :: TextLabel? else nil
end

local function follow(label: TextLabel, drop: TextLabel)
	local e = edge(label)
	drop.Text = label.Text
	drop.TextSize = label.TextSize
	drop.FontFace = label.FontFace
	drop.RichText = label.RichText
	drop.TextXAlignment = label.TextXAlignment
	drop.TextYAlignment = label.TextYAlignment
	drop.TextTruncate = label.TextTruncate
	drop.AnchorPoint = label.AnchorPoint
	drop.Size = label.Size
	drop.Position = label.Position + UDim2.fromOffset(0, e.Drop * HudConfig.M.Per)
	drop.Visible = label.Visible
	drop.ZIndex = label.ZIndex - 1
	local clear = label.TextTransparency
	drop.TextTransparency = 1 - (1 - clear) * (1 - e.Clear)
	local line = drop:FindFirstChild("Edge") :: UIStroke?
	if line then
		line.Transparency = 1 - (1 - clear) * (1 - e.Clear)
	end
	local swell = label:FindFirstChildOfClass("UIScale")
	local copy = drop:FindFirstChildOfClass("UIScale")
	if swell then
		if copy == nil then
			copy = Instance.new("UIScale")
			copy.Parent = drop
		end
		(copy :: UIScale).Scale = swell.Scale
	end
end

function Edge.Wear(label: TextLabel, own: any?)
	if dropOf(label) then
		return
	end
	owns[label] = own
	local e = edge(label)
	stroke(label, e)
	local drop = Instance.new("TextLabel")
	drop.Name = label.Name .. DROP
	drop.BackgroundTransparency = 1
	drop.BorderSizePixel = 0
	drop.TextColor3 = e.Colour
	drop.Active = false
	drop.Parent = label.Parent
	stroke(drop, e)
	follow(label, drop)
	for _, property in { "Text", "TextSize", "FontFace", "Size", "Position", "AnchorPoint", "Visible", "TextTransparency", "ZIndex" } do
		label:GetPropertyChangedSignal(property :: any):Connect(function()
			follow(label, drop)
		end)
	end
	local function watch(child: Instance)
		if child:IsA("UIScale") then
			child:GetPropertyChangedSignal("Scale"):Connect(function()
				follow(label, drop)
			end)
			follow(label, drop)
		end
	end
	label.ChildAdded:Connect(watch)
	for _, child in label:GetChildren() do
		watch(child)
	end
end

function Edge.Fade(label: TextLabel, clear: number)
	label.TextTransparency = clear
	local line = label:FindFirstChild("Edge") :: UIStroke?
	if line then
		line.Transparency = 1 - (1 - clear) * (1 - edge(label).Clear)
	end
	local drop = dropOf(label)
	if drop then
		follow(label, drop)
	end
end

function Edge.Refit(root: Instance)
	for _, child in root:GetChildren() do
		if child:IsA("TextLabel") then
			local drop = dropOf(child)
			if drop then
				local e = edge(child)
				stroke(child, e)
				stroke(drop, e)
				follow(child, drop)
			end
		end
	end
end

return Edge
