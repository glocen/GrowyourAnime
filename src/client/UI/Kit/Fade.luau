--!strict
-- Fade (client kit): a whole HUD piece drawn see-through, its parts each at a share of what shows of them (Rules.Hud.Faded),
-- so a piece built of images, text and strokes fades as one without a CanvasGroup, which would clip a pop's swell
-- (Kit.Pop). Each part's own transparency is its base: taken when the fade starts, or when a part joins mid-fade, and
-- taken again whenever something else writes it mid-fade (a pop's "+N" fading, a toast's plate), so the fade never fights
-- what animates the piece. Back at 1, every part has its base again, exactly, and the piece is forgotten.
--   Fade.Set(root, opacity, keep?)   root and its descendants at `opacity` (1 whole); `keep` gives a part, and all under it,
--                                    its own opacity instead (the Target card's bar, kept readable)
--   Fade.Of(root)                    the opacity it was last set to (1 when never): for tests

local Hud = require(game:GetService("ReplicatedStorage").Shared.Rules.Hud)

local Fade = {}

-- The transparencies a part draws with, by class.
local PROPERTIES: { [string]: { string } } = {
	Frame = { "BackgroundTransparency" },
	ScrollingFrame = { "BackgroundTransparency", "ScrollBarImageTransparency" },
	TextLabel = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	TextButton = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	TextBox = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
	ImageButton = { "BackgroundTransparency", "ImageTransparency" },
	UIStroke = { "Transparency" },
}

type Part = { Base: { [string]: number }, Wrote: { [string]: number } }
type Piece = { Opacity: number, Parts: { [Instance]: Part } }

local pieces: { [Instance]: Piece } = {}

local function opacityOf(object: Instance, root: Instance, opacity: number, keep: { [Instance]: number }?): number
	if keep then
		local at: Instance? = object
		while at do
			local own = keep[at]
			if own then
				return own
			end
			if at == root then
				break
			end
			at = at.Parent
		end
	end
	return opacity
end

local function apply(piece: Piece, object: Instance, opacity: number)
	local names = PROPERTIES[object.ClassName]
	if not names then
		return
	end
	local part = piece.Parts[object]
	if not part then
		part = { Base = {}, Wrote = {} }
		piece.Parts[object] = part
	end
	local anyObject = object :: any
	for _, name in names do
		local now = anyObject[name] :: number
		local wrote = part.Wrote[name]
		if wrote == nil or now ~= wrote then
			part.Base[name] = now -- new, or written by something else since: its own value now
		end
		local want = Hud.Faded(part.Base[name], opacity)
		if now ~= want then
			anyObject[name] = want
		end
		part.Wrote[name] = anyObject[name] -- read back: the property stores less precision than a number
	end
end

local function restore(piece: Piece)
	for object, part in piece.Parts do
		local wrote = part.Wrote
		local anyObject = object :: any
		for name, base in part.Base do
			if object.Parent ~= nil and anyObject[name] == wrote[name] then
				anyObject[name] = base
			end
		end
	end
end

local function whole(opacity: number, keep: { [Instance]: number }?): boolean
	if opacity < 1 then
		return false
	end
	for _, own in keep or {} do
		if own < 1 then
			return false
		end
	end
	return true
end

function Fade.Set(root: Instance, opacity: number, keep: { [Instance]: number }?)
	local piece = pieces[root]
	if whole(opacity, keep) then
		if piece then
			restore(piece)
			pieces[root] = nil
		end
		if root:GetAttribute("Opacity") ~= nil then
			root:SetAttribute("Opacity", nil)
		end
		return
	end
	if not piece then
		piece = { Opacity = 1, Parts = {} }
		pieces[root] = piece
	end
	local current = piece :: Piece
	current.Opacity = opacity
	apply(current, root, opacityOf(root, root, opacity, keep))
	for _, object in root:GetDescendants() do
		apply(current, object, opacityOf(object, root, opacity, keep))
	end
	for object in current.Parts do
		if object.Parent == nil then
			current.Parts[object] = nil -- gone mid-fade (a toast that left)
		end
	end
	root:SetAttribute("Opacity", opacity)
end

function Fade.Of(root: Instance): number
	local piece = pieces[root]
	return if piece then piece.Opacity else 1
end

return Fade
