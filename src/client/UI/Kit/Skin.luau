--!strict
-- Skin (client kit): lays Modulo's kit images (Config.UIKit; AR3, section 2) under a piece, as his compositor does
-- (tools/blender/ui_kit.py, `Stage.lay`): a white slice takes its palette's colour, its corners keep their size, its middle
-- stretches, and it reaches its Pad past the piece's box on every side. Sizes are authored pixels, one point each.
-- The layers live in a Folder, so a list or grid in the piece never lays them out, inside one Frame drawn under every
-- other child (ZIndex 0 against their 1). The Frame undoes the piece's padding, so the skin always covers the whole box.
--   Skin.Of(piece)                          the piece's skin frame, made on first use
--   Skin.Lay(holder, image, options?)       one image: filling `holder`'s box, or at X, Y, W, H inside it
--   Skin.Tint(image, tint)                  a colour, two top to bottom, or a ColorSequence top to bottom
--   Skin.Refit(piece)                       after the piece's padding changes

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)

export type Options = {
	Name: string?,
	X: number?, -- placed at X, Y inside the holder; W, H for a slice's size (left out, it fills the holder)
	Y: number?,
	W: number?,
	H: number?,
	Tint: (Color3 | { Color3 } | ColorSequence)?, -- a colour, two top to foot, or a gradient's stops top to foot
	Alpha: number?,
	Scale: number?, -- the image's points to authored pixels: a slice's corners and pad, an icon's size
	Size: number?, -- an image with no cut drawn this many pixels across (its height kept in proportion)
	Z: number?,
}

local Skin = {}

local FOLDER = "NL_Skin"

function Skin.Of(piece: GuiObject): Frame
	local folder = piece:FindFirstChild(FOLDER)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = piece
	end
	local frame = (folder :: Instance):FindFirstChild("Skin") :: Frame?
	if frame then
		return frame
	end
	local made = Instance.new("Frame")
	made.Name = "Skin"
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.ZIndex = 0
	made.Active = false
	made.Parent = folder
	Skin.Refit(piece)
	return made
end

-- The skin frame covers the piece's whole box whatever padding the piece has (UIPadding moves a folder's children too).
function Skin.Refit(piece: GuiObject)
	local folder = piece:FindFirstChild(FOLDER)
	local frame = if folder then folder:FindFirstChild("Skin") :: Frame? else nil
	if frame == nil then
		return
	end
	local padding = piece:FindFirstChildOfClass("UIPadding")
	local l, t, r, b = 0, 0, 0, 0
	if padding then
		l, t, r, b = padding.PaddingLeft.Offset, padding.PaddingTop.Offset, padding.PaddingRight.Offset, padding.PaddingBottom.Offset
	end
	frame.Position = UDim2.fromOffset(-l, -t)
	frame.Size = UDim2.new(1, l + r, 1, t + b)
end

function Skin.Tint(image: ImageLabel, tint: (Color3 | { Color3 } | ColorSequence)?)
	local gradient = image:FindFirstChildOfClass("UIGradient")
	if typeof(tint) == "Color3" then
		image.ImageColor3 = tint
		if gradient then
			gradient:Destroy()
		end
	elseif type(tint) == "table" or typeof(tint) == "ColorSequence" then
		image.ImageColor3 = Color3.new(1, 1, 1)
		if gradient == nil then
			gradient = Instance.new("UIGradient")
			gradient.Rotation = 90 -- top to bottom
			gradient.Parent = image
		end
		local sequence: ColorSequence
		if typeof(tint) == "ColorSequence" then
			sequence = tint
		else
			local list = tint :: { Color3 }
			sequence = ColorSequence.new(list[1], list[#list])
		end
		(gradient :: UIGradient).Color = sequence
	else
		image.ImageColor3 = Color3.new(1, 1, 1)
		if gradient then
			gradient:Destroy()
		end
	end
end

-- Lays `name` in `holder` (a skin frame, or any frame for an icon). Returns the image.
function Skin.Lay(holder: GuiObject, name: string, options: Options?): ImageLabel
	local o: Options = options or {}
	local im = UIKit.Images[name]
	assert(im, `UIKit has no image "{name}"`)
	local image = Instance.new("ImageLabel")
	Skin.Set(image, name, o)
	image.Name = o.Name or name
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.ZIndex = o.Z or 1
	image.ImageTransparency = 1 - (o.Alpha or 1)
	Skin.Tint(image, o.Tint)
	image.Parent = holder
	return image
end

-- Lays `name` into an image already made (a bar's light as it moves, a frame's rarity as it changes).
function Skin.Set(image: ImageLabel, name: string, o: Options)
	local im = UIKit.Images[name]
	assert(im, `UIKit has no image "{name}"`)
	local s = o.Scale or (if o.Size then o.Size / (im.Points.X - 2 * im.Pad) else 1)
	local pad = im.Pad * s
	local x, y = o.X or 0, o.Y or 0
	image.Image = im.Id
	if im.Cut then
		local ppp = UIKit.PixelsPerPoint
		local cut = im.Cut
		image.ScaleType = Enum.ScaleType.Slice
		image.SliceCenter = Rect.new(cut[1] * ppp, cut[2] * ppp, im.Pixels.X - cut[3] * ppp, im.Pixels.Y - cut[4] * ppp)
		image.SliceScale = UIKit.SliceScale * s
		if o.W and o.H then
			image.Size = UDim2.fromOffset(o.W + 2 * pad, o.H + 2 * pad)
			image.Position = UDim2.fromOffset(x - pad, y - pad)
		else
			image.Size = UDim2.new(1, 2 * pad, 1, 2 * pad)
			image.Position = UDim2.fromOffset(x - pad, y - pad)
		end
	else
		image.ScaleType = Enum.ScaleType.Stretch
		image.Size = UDim2.fromOffset(im.Points.X * s, im.Points.Y * s)
		image.Position = UDim2.fromOffset(x - pad, y - pad)
	end
	image:SetAttribute("Kit", name)
end

-- An icon of the kit (a gem, a class mark, an element, a coin, a bolt) `size` pixels across, centred on cx, cy.
function Skin.Icon(holder: GuiObject, name: string, cx: number, cy: number, size: number, tint: Color3?, z: number?): ImageLabel
	local im = UIKit.Images[name]
	assert(im, `UIKit has no image "{name}"`)
	local s = size / im.Points.X
	return Skin.Lay(holder, name, { X = cx - size / 2, Y = cy - size / 2, Scale = s, Tint = tint, Z = z })
end

return Skin
