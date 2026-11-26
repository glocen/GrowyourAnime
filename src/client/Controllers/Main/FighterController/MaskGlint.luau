--!strict
-- MaskGlint (client): a Shade's star at its mask's eye line as its ordinary swing starts, the swing's read, so the strike
-- can be read and Called (TR69 A, G1, research's pick; Config.Combat.Glint its switch and length). The rows ShadeGlint
-- (Config.EffectRows, Scintilla's) played once on the effects' clock with the Shade's scale, at the mask's eye line's
-- height, pushed from its middle toward this client's camera, in the flat, past the mask (half its larger side and
-- FRONT more), facing the camera: a Shade faces the lead, so its mask's own front is mostly away from the player, and
-- the star there showed as a thin line over the head (Scintilla's check in play, 2026-11-26, 19:51). Its light tinted
-- the Shade's type's colour (Rows' Tint), its core white. Placed once, at the swing's start, and it stays where it
-- began. In place of the mask's emissive flare (G2, not picked).
--   MaskGlint.Play(model)   at the swing's start
--   MaskGlint.Last()        for the self-test: { Model, At, Anchor, Mask, Eye, Toward, Out, Tint, Rows } of the last
--                           played (Eye: the eye line's point; Toward: the flat way to the camera; Out: how far along)

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Effects = require(script.Parent.Effects)
local Rows = require(script.Parent.Rows)

local MaskGlint = {}

local EFFECT = "ShadeGlint"
local EYE = 0.08 -- of the mask's height, over its middle: its eye line
local FRONT = 0.3 -- studs past the mask's larger half side, toward the camera, at the Shade's scale

type Played = {
	Model: Model,
	At: number,
	Anchor: CFrame,
	Mask: BasePart,
	Eye: Vector3,
	Toward: Vector3,
	Out: number,
	Tint: Color3?,
	Rows: Rows.Player,
}

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
	local scale = model:GetScale()
	local eye = (mask.CFrame * CFrame.new(0, EYE * mask.Size.Y, 0)).Position
	local camera = workspace.CurrentCamera
	local toward = if camera then (camera.CFrame.Position - eye) * Vector3.new(1, 0, 1) else Vector3.zero
	if toward.Magnitude < 1e-3 then
		toward = -mask.CFrame.LookVector * Vector3.new(1, 0, 1) -- the camera straight over it: as if behind
	end
	toward = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.new(0, 0, 1)
	local out = 0.5 * math.max(mask.Size.X, mask.Size.Z) + FRONT * scale
	local at = eye + toward * out
	local anchor = CFrame.lookAt(at, at + toward)
	local kind = model:GetAttribute("Type")
	local tint = if type(kind) == "string" then HudConfig.Card.Types[kind] else nil
	local rows = Effects.At(EFFECT, anchor, scale, tint)
	if rows then
		last = { Model = model, At = os.clock(), Anchor = anchor, Mask = mask, Eye = eye, Toward = toward, Out = out, Tint = tint, Rows = rows }
	end
end

function MaskGlint.Last(): Played?
	return last
end

return MaskGlint
