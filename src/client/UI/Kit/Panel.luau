--!strict
-- Panel (client kit): a plate of the kit, with its shard-cut corners (docs/ui.md, rule 3; AR3, section 2). Its layers, in
-- Modulo's order (tools/blender/ui_kit.py, `panel`): the shadow, the body in the palette's two colours top to bottom, the
-- facet's faint light on a big panel, the edge (bold on a bordered palette), the glint. A row inside a panel is the body
-- alone, a step up from its panel. The palette is Graphite unless a piece names another (docs/ui.md: which screen takes
-- which, AR3).

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local Skin = require(script.Parent.Skin)
local HudConfig = require(Shared.Config.Hud)
local Hover = require(script.Parent.Hover)

export type Props = {
	Name: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Palette: string?, -- a UIKit palette: Graphite, Pearl, Dynamo, Void
	Colour: Color3?, -- a row's body, when not the palette's
	Transparency: number?,
	Edge: boolean?, -- false for a row inside a panel
	LayoutOrder: number?,
}

local Panel = {}

local FACET = 48 -- a panel this many points or more each way shows its facet

function Panel.Palette(piece: Instance): UIKit.Palette
	local name = piece:GetAttribute("Palette")
	return UIKit.Palettes[if type(name) == "string" then name else "Graphite"] or UIKit.Palettes.Graphite
end

local function big(size: UDim2): boolean
	local function axis(d: UDim): boolean
		return d.Scale > 0 or d.Offset >= FACET
	end
	return axis(size.X) and axis(size.Y)
end

-- Lays (or lays again) a panel's skin for its palette: used when the palette changes.
function Panel.Paint(frame: GuiObject)
	local p = Panel.Palette(frame)
	local skin = Skin.Of(frame)
	skin:ClearAllChildren()
	if frame:GetAttribute("Row") == true then
		local colour = frame:GetAttribute("Colour")
		Skin.Lay(skin, "PanelFill", { Name = "Fill", Tint = if typeof(colour) == "Color3" then colour else p.Button, Alpha = 0.55, Z = 1 })
		return
	end
	local bold = if (p.Border or 1) > 1 then "Bold" else ""
	Skin.Lay(skin, "PanelShadow", { Name = "Shadow", Z = 1 })
	local alpha = frame:GetAttribute("Alpha")
	Skin.Lay(skin, "PanelFill", { Name = "Fill", Tint = p.Panel, Alpha = if type(alpha) == "number" then alpha else p.Alpha, Z = 2 })
	if big(frame.Size) then
		Skin.Lay(skin, "PanelFacet", { Name = "Facet", Tint = p.Facet, Alpha = 0.07, Z = 3 })
	end
	Skin.Lay(skin, "PanelEdge" .. bold, { Name = "Edge", Tint = p.Edge, Alpha = 0.95, Z = 4 })
	Skin.Lay(skin, "PanelGlint", { Name = "Glint", Tint = p.Glint, Z = 5 })
	if frame:GetAttribute("Lit") == true then
		Panel.Lit(frame, true)
	end
end

function Panel.new(props: Props): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.Name
	frame.Size = props.Size
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = props.LayoutOrder or 0
	frame:SetAttribute("Palette", props.Palette or "Graphite")
	if props.Edge == false then
		frame:SetAttribute("Row", true)
		if props.Colour then
			frame:SetAttribute("Colour", props.Colour)
		end
	end
	if props.Transparency then
		frame:SetAttribute("Alpha", 1 - props.Transparency)
	end
	Panel.Paint(frame)
	frame.Parent = props.Parent
	return frame
end

-- A panel's edge lit, bold, in its palette's accent: a place that asks for the player's next step (the Breaker's plate
-- while a shard waits in the bag; research's read of TR2's fixes, 2026-11-12). Off, its edge as made.
function Panel.Lit(frame: GuiObject, on: boolean)
	frame:SetAttribute("Lit", on)
	local folder = frame:FindFirstChild("NL_Skin")
	local edge = if folder then folder:FindFirstChild("Edge", true) :: ImageLabel? else nil
	if edge == nil then
		return
	end
	local p = Panel.Palette(frame)
	local bold = if on or (p.Border or 1) > 1 then "Bold" else ""
	Skin.Set(edge, "PanelEdge" .. bold, {})
	local trim = frame:GetAttribute("Trim")
	Skin.Tint(edge, if on then p.Accent elseif typeof(trim) == "Color3" then trim else p.Edge)
	edge.ImageTransparency = if on then 0 else 0.05
end

-- A panel's edge in a colour of its own while it isn't lit: a card's trim (Config.Hud.Card.Trim). Nothing when unchanged.
function Panel.Trim(frame: GuiObject, colour: Color3)
	if frame:GetAttribute("Trim") == colour then
		return
	end
	frame:SetAttribute("Trim", colour)
	Panel.Lit(frame, frame:GetAttribute("Lit") == true)
end

-- A pointer over a panel that presses (TR20; Kit.Hover): its body White of the way toward white, its edge Halo of the way
-- toward its accent, all the way for a pad's selection, our rim. A lit panel's edge is already its accent: open beats
-- hover. Share 0 puts both back as made.
function Panel.Hover(frame: GuiObject, share: number, pad: boolean)
	local folder = frame:FindFirstChild("NL_Skin")
	if folder == nil then
		return
	end
	local p = Panel.Palette(frame)
	local fill = folder:FindFirstChild("Fill", true)
	if fill and fill:IsA("ImageLabel") then
		local colour = frame:GetAttribute("Colour")
		local gradient = fill:FindFirstChildOfClass("UIGradient")
		if frame:GetAttribute("Row") == true and typeof(colour) == "Color3" then
			fill.ImageColor3 = Hover.White(colour, share)
		elseif frame:GetAttribute("Row") ~= true and gradient then -- the body's two colours, top to bottom (Skin.Tint)
			gradient.Color = Hover.Whites(ColorSequence.new(p.Panel[1], p.Panel[#p.Panel]), share)
		end
	end
	local edge = folder:FindFirstChild("Edge", true)
	if edge and edge:IsA("ImageLabel") and frame:GetAttribute("Lit") ~= true then
		local trim = frame:GetAttribute("Trim")
		local base = if typeof(trim) == "Color3" then trim else p.Edge
		edge.ImageColor3 = base:Lerp(p.Accent, (if pad then 1 else HudConfig.Motion.Hover.Halo) * share)
	end
end

-- A list inside `frame`: its children stack in order, `gap` apart (the skin is never in it).
function Panel.List(frame: GuiObject, direction: Enum.FillDirection?, gap: number?): UIListLayout
	local list = Instance.new("UIListLayout")
	list.FillDirection = direction or Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, gap or Theme.Size.Gap)
	list.Parent = frame
	return list
end

-- Padding inside `frame`, all four sides (the skin still covers the whole box).
function Panel.Pad(frame: GuiObject, pad: number?, across: number?)
	local padding = Instance.new("UIPadding")
	local p = UDim.new(0, pad or Theme.Size.Pad)
	local x = UDim.new(0, across or pad or Theme.Size.Pad) -- left and right, when they differ from top and bottom
	padding.PaddingLeft, padding.PaddingRight, padding.PaddingTop, padding.PaddingBottom = x, x, p, p
	padding.Parent = frame
	Skin.Refit(frame)
end

return Panel
