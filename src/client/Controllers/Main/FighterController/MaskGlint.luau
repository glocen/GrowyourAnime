--!strict
-- MaskGlint (client): a Shade's mask flares as its ordinary swing starts, the swing's read (TR69 A; Config.Combat.Glint).
-- Its masks' light jumps to Peak at once and eases back (quadratic) to its own over Seconds, so the glint ends before the
-- swing's Hit beat. A grey block on the mask's own light; Scintilla gives it its look later.
--   MaskGlint.Play(model)   at the swing's start
--   MaskGlint.Last()        for the self-test: { Model, At, Peak, Masks } of the last played, and Lit, the light a mask
--                           shows now

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)

local MaskGlint = {}

type Playing = { At: number, Seconds: number, Peak: number, Base: number }

local playing: { [SurfaceAppearance]: Playing } = {}
local last: { Model: Model, At: number, Peak: number, Masks: { SurfaceAppearance } }? = nil
local stepping: RBXScriptConnection? = nil

local function masksOf(model: Model): { SurfaceAppearance }
	local found: { SurfaceAppearance } = {}
	for _, part in model:GetChildren() do
		if string.sub(part.Name, 1, 5) == "Mask_" or string.sub(part.Name, 1, 10) == "EliteMask_" then
			local look = part:FindFirstChildOfClass("SurfaceAppearance")
			if look then
				table.insert(found, look)
			end
		end
	end
	return found
end

local function step()
	local now = os.clock()
	for look, glint in playing do
		local u = (now - glint.At) / glint.Seconds
		if u >= 1 or look.Parent == nil then
			look.EmissiveStrength = glint.Base
			playing[look] = nil
		else
			look.EmissiveStrength = glint.Base + (glint.Peak - glint.Base) * (1 - u) * (1 - u)
		end
	end
	if next(playing) == nil and stepping then
		stepping:Disconnect()
		stepping = nil
	end
end

function MaskGlint.Play(model: Model)
	local look = Combat.Glint
	local masks = masksOf(model)
	local now = os.clock()
	for _, mask in masks do
		local running = playing[mask]
		local base = if running then running.Base else mask.EmissiveStrength -- a glint over a glint keeps the mask's own
		playing[mask] = { At = now, Seconds = math.max(0.01, look.Seconds), Peak = math.max(base, look.Peak), Base = base }
		mask.EmissiveStrength = playing[mask].Peak
	end
	last = { Model = model, At = now, Peak = look.Peak, Masks = masks }
	if stepping == nil and next(playing) ~= nil then
		stepping = RunService.RenderStepped:Connect(step)
	end
end

function MaskGlint.Last(): { [string]: any }?
	if last == nil then
		return nil
	end
	local first = last.Masks[1]
	return { Model = last.Model, At = last.At, Peak = last.Peak, Masks = #last.Masks, Lit = if first then first.EmissiveStrength else 0 }
end

return MaskGlint
