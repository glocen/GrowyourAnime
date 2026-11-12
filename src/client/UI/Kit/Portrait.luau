--!strict
-- Portrait (client kit): a Voidkin's face in its rarity's frame (docs/ui.md, rule 3: a rarity is the frame's shape and
-- glow; AR3, sections 2 and 3). Its layers, in Modulo's order (tools/blender/ui_kit.py, `frame`): the frame's back, its
-- seat on a pale palette, the portrait cut to the frame, the frame. The full frame (80 by 96) wears the type's gem at
-- its top left and the class mark at its bottom right; the small one (40 by 48) wears neither, and its card shows them.
-- A Voidkin with no portrait yet shows its rarity's silhouette. Fallen, the face dims and the frame stays as it is:
-- never a red wash across a portrait, and the palette's accent never rings it (AR3's in-use rules).
--   Portrait.new{ Name, Small, Position, Parent, Voidkin }   a frame, sized to its body
--   Portrait.Set(frame, voidkinId?, dim?)

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Skin = require(script.Parent.Skin)
local Panel = require(script.Parent.Panel)

export type Props = {
	Name: string,
	Small: boolean?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Palette: string?,
	Voidkin: string?, -- a definition's id
}

local Portrait = {}

-- The portrait image for a Voidkin, cut to its rarity's frame: its own, or its rarity's silhouette.
function Portrait.Image(id: string?, small: boolean): (string, string)
	local def = if id then Voidkin.ById[id] else nil
	local rarity = if def then def.Rarity else "Common"
	local suffix = if small then "Small" else ""
	local own = if def then `Portrait{def.Name}{suffix}` else ""
	if UIKit.Images[own] then
		return own, rarity
	end
	return `PortraitUnknown{rarity}{suffix}`, rarity
end

local function lay(frame: Frame)
	local small = frame:GetAttribute("Small") == true
	local id = frame:GetAttribute("Voidkin")
	local voidkin = if type(id) == "string" and id ~= "" then id else nil
	local face, rarity = Portrait.Image(voidkin, small)
	local name = "Frame" .. rarity .. (if small then "Small" else "")
	local p = Panel.Palette(frame)
	local skin = Skin.Of(frame)
	skin:ClearAllChildren()
	Skin.Lay(skin, name .. "Back", { Name = "Back", Z = 1 })
	if p.Seat then
		Skin.Lay(skin, name .. "Seat", { Name = "Seat", Z = 2 })
	end
	local image = Skin.Lay(skin, face, { Name = "Face", Z = 3 })
	Skin.Lay(skin, name, { Name = "Frame", Z = 4 })
	if not small then
		local def = if voidkin then Voidkin.ById[voidkin] else nil
		if def then
			local w = 80
			local scale = w / 80
			Skin.Icon(skin, `Gem{def.Type}Seated`, 5.5 * scale, 5.5 * scale, 32 * 6.5 / 10.5, nil, 5)
			Skin.Icon(skin, `Class{def.Class}`, w - 6.5 * scale, w * 1.2 - 6.5 * scale, 32 * 6 / 13, nil, 5)
		end
	end
	local dim = frame:GetAttribute("Dim") == true
	local d = 1 - HudConfig.Fallen.Dim
	image.ImageColor3 = if dim then Color3.new(d, d, d) else Color3.new(1, 1, 1)
	frame:SetAttribute("Face", face)
	frame:SetAttribute("Rarity", rarity)
end

function Portrait.new(props: Props): Frame
	local small = props.Small == true
	local frame = Instance.new("Frame")
	frame.Name = props.Name
	frame.Size = if small then UDim2.fromOffset(40, 48) else UDim2.fromOffset(80, 96)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame:SetAttribute("Palette", props.Palette or "Graphite")
	frame:SetAttribute("Small", small)
	frame:SetAttribute("Voidkin", props.Voidkin or "")
	frame:SetAttribute("Dim", false)
	lay(frame)
	frame.Parent = props.Parent
	return frame
end

-- Shows `id` (a definition's id, or nil for none), dimmed while it's fallen. Lays it again only when something changed.
function Portrait.Set(frame: Frame, id: string?, dim: boolean?)
	local want, dimmed = id or "", dim == true
	if frame:GetAttribute("Voidkin") == want and frame:GetAttribute("Dim") == dimmed then
		return
	end
	frame:SetAttribute("Voidkin", want)
	frame:SetAttribute("Dim", dimmed)
	lay(frame)
end

return Portrait
