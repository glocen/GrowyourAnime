--!strict
-- MaskGlint (client): a Shade's star at its mask's eye line as its ordinary swing starts, the swing's read, so the strike
-- can be read and Called (TR69 A, G1, research's pick; Config.Combat.Glint its switch and length). The rows ShadeGlint
-- (Config.EffectRows, Scintilla's) played once on the effects' clock with the Shade's scale, its foot at the mask's eye
-- line a little in front of its face, facing as the mask does; its light tinted the Shade's type's colour (Rows' Tint),
-- its core white. It stays where it began. In place of the mask's emissive flare (G2, not picked).
--   MaskGlint.Play(model)   at the swing's start
--   MaskGlint.Last()        for the self-test: { Model, At, Anchor, Mask, MaskAt, Tint, Rows } of the last
--                           played (MaskAt: the mask's frame as it began)

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Effects = require(script.Parent.Effects)
local Rows = require(script.Parent.Rows)

local MaskGlint = {}

local EFFECT = "ShadeGlint"
local EYE = 0.08 -- of the mask's height, over its middle: its eye line
local FRONT = 0.15 -- studs in front of the mask's face

type Played = { Model: Model, At: number, Anchor: CFrame, Mask: BasePart, MaskAt: CFrame, Tint: Color3?, Rows: Rows.Player }

local last: Played? = nil

-- Its mask: an ordinary Shade's, or an elite's first.
local function maskOf(model: Model): BasePart?
	local elite: BasePart? = nil
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			if string.sub(part.Name, 1, 5) == "Mask_" then
				return part
			elseif elite == nil and string.sub(part.Name, 1, 10) == "EliteMask_" then
				elite = part
			end
		end
	end
	return elite
end

function MaskGlint.Play(model: Model)
	local mask = maskOf(model)
	if mask == nil then
		return
	end
	local anchor = mask.CFrame * CFrame.new(0, EYE * mask.Size.Y, -(0.5 * mask.Size.Z + FRONT))
	local kind = model:GetAttribute("Type")
	local tint = if type(kind) == "string" then HudConfig.Card.Types[kind] else nil
	local rows = Effects.At(EFFECT, anchor, model:GetScale(), tint)
	if rows then
		last = { Model = model, At = os.clock(), Anchor = anchor, Mask = mask, MaskAt = mask.CFrame, Tint = tint, Rows = rows }
	end
end

function MaskGlint.Last(): Played?
	return last
end

return MaskGlint
