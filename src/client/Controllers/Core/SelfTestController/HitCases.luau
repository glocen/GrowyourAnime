--!strict
-- HitCases: the hit, TR69's block A (docs/test-requests.md, TR69). The attack clips' snap behind its live switch
-- (Config.Animations.Snap); R4, the mark over the lead's target in its type's colour (Config.Effects.Mark, TargetMark)
-- and gone with it; G1, a Shade's star at its mask's eye line as its ordinary swing starts, in its type's colour and gone
-- before the swing's Hit beat (Config.Combat.Glint, EffectRows' ShadeGlint, MaskGlint). The pack's last fall's hold is
-- Rules.Fight's (its logic case). Apart from Cases, whose size the type check can't take more of.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local EffectsConfig = require(Shared.Config.Effects)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Main = script.Parent.Parent.Parent.Main
local Clips = require(Main.FighterController.Clips)
local TargetMark = require(Main.FighterController.TargetMark)
local MaskGlint = require(Main.FighterController.MaskGlint)
local Helpers = require(script.Parent.Helpers)

local HitCases = {}

local AHEAD = 12 -- studs ahead of the avatar the test Shade spawns, inside its notice and the lead's leash
local TOUGHER = 10 -- levels over the lead's, so it stands and swings several times
local WATCH = 15 -- seconds for the lead to take it on and for it to swing

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

local function fighterModel(id: string): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function clipOf(role: string): string?
	for _, action in Actions.List do
		if action.Clip and Actions.RoleOf(action.Clip) == role then
			return action.Clip
		end
	end
	for clip in Animations.Roles do
		if Actions.RoleOf(clip) == role then
			return clip
		end
	end
	return nil
end

function HitCases.Cases(): { any }
	return {
		{
			Name = "The hit (TR69 A): the attack clips snap in at Animations.Snap.In while its switch is on, and at their own fade while it's off; a reaction keeps its own",
			Run = function(t: any)
				local combo, hit = clipOf("Combo"), clipOf("Hit")
				t.Check("a combo clip to read", combo ~= nil)
				if combo == nil then
					return
				end
				local was = Animations.Snap.On
				t.Check("off by default", was == false)
				t.Equal("off: the combo's own fade", (Clips.Fades(combo)), Animations.Fades.Combo.In)
				local ok, problem = pcall(function()
					t.Server("Tune", "Animations.Snap.On", true)
					t.Check("on, live: the combo snaps in", Helpers.waitFor(t, 2, function(): boolean
						return (Clips.Fades(combo)) == Animations.Snap.In
					end), tostring((Clips.Fades(combo))))
					local _, out = Clips.Fades(combo)
					t.Equal("its fade out its own", out, Animations.Fades.Combo.Out)
					if type(hit) == "string" then
						t.Equal("a reaction keeps its own", (Clips.Fades(hit)), Animations.Fades.Hit.In)
					end
				end)
				t.Server("Tune", "Animations.Snap.On", was)
				Helpers.waitFor(t, 2, function(): boolean
					return Animations.Snap.On == was
				end)
				t.Check("the switch put back", Animations.Snap.On == was, tostring(problem))
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
		{
			Name = "The hit (TR69 A): the mark over the lead's target in its type's colour, gone with it; a Shade's star at its mask's eye line as its swing starts, in its colour, gone before the swing's Hit",
			Run = function(t: any)
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				t.Check("the lead is in the world", lead ~= nil and type(level) == "number")
				if lead == nil or type(level) ~= "number" then
					return
				end
				local swing = Actions.ById[Enemies.ById.brawler.Action :: string]
				t.Check("the glint ends before the swing's Hit", swing ~= nil and Combat.Glint.Seconds < (swing.Beats :: any).Hit, if swing then `{(swing.Beats :: any).Hit} s` else "no swing")
				local glint = (EffectsConfig.Rows :: any).ShadeGlint
				t.Check("its star's rows are loaded, their light tinted and their core never", glint ~= nil and glint.Rows.Star.Tint == true and not glint.Rows.Core.Tint)
				local spawned = t.Server("FightSpawn", "brawler", level + TOUGHER, AHEAD)
				t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
				if type(spawned) ~= "table" or spawned.Ok ~= true then
					return
				end
				local foe: Model? = nil
				local ok, problem = pcall(function()
					local met = Helpers.waitFor(t, WATCH, function(): boolean
						foe = fighterModel(spawned.Id)
						local read = TargetMark.Read()
						return foe ~= nil and lead:GetAttribute("Target") == spawned.Id and read.Shown and read.Target == foe
					end)
					t.Check("the mark shows over the lead's target", met)
					local body = foe :: Model?
					if not met or body == nil then
						return
					end
					local read = TargetMark.Read()
					local want = HudConfig.Card.Types[Enemies.ById.brawler.Type]
					local mark = EffectsConfig.Mark
					t.Check("in its type's colour", read.Colour == want, tostring(read.Colour))
					t.Check("at the body's scale", math.abs(read.Side - mark.Side * body:GetScale()) < 1e-3, string.format("%.2f", read.Side))
					local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
					local apex = read.Apex :: Vector3?
					local masked: BasePart? = nil
					for _, part in body:GetChildren() do
						if part:IsA("BasePart") and string.sub(part.Name, 1, 5) == "Mask_" then
							masked = part
						end
					end
					t.Check("over its head: its apex Lift over its mask, above it", root ~= nil and apex ~= nil and masked ~= nil
						and ((apex - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 0.05 and apex.Y > (masked :: BasePart).Position.Y,
						if root and apex then string.format("%.2f studs over its root", apex.Y - root.Position.Y) else "")
					-- a damage number on it is born over the mark's top, never on it (research's condition)
					local top = TargetMark.Top(body)
					t.Check("its numbers are born over the mark", top ~= nil and apex ~= nil and top > (apex :: Vector3).Y + mark.Centre * body:GetScale(),
						if top and root then string.format("the mark's top %.2f over the root", top - root.Position.Y) else "")
					-- the star, as its swing starts
					local glinted = Helpers.waitFor(t, WATCH, function(): boolean
						local last = MaskGlint.Last()
						return last ~= nil and last.Model == body
					end)
					t.Check("its star plays as it swings", glinted)
					local last = MaskGlint.Last()
					if not glinted or last == nil then
						return
					end
					local camera = workspace.CurrentCamera
					local from = last.Anchor.Position - last.Eye
					local seen = if camera then ((camera.CFrame.Position - last.Eye) * Vector3.new(1, 0, 1)).Unit else Vector3.zero
					t.Check("at its mask's eye line, toward the camera past the mask, facing it",
						math.abs(from.Y) < 1e-3 and math.abs(from.Magnitude - last.Out) < 1e-3 and last.Out > math.max(last.Mask.Size.X, last.Mask.Size.Z) / 2
							and from.Unit:Dot(seen) > 0.98 and last.Anchor.LookVector:Dot(seen) > 0.98,
						string.format("%.2f studs out, %.2f up, toward %.2f, facing %.2f", from.Magnitude, from.Y, from.Unit:Dot(seen), last.Anchor.LookVector:Dot(seen)))
					t.Check("its light in its type's colour", last.Tint == want, tostring(last.Tint))
					t.Check("done within the glint's length", last.Rows.End / 60 <= Combat.Glint.Seconds + 1e-6, `{last.Rows.End} frames`)
					local made = last.Rows.Parts("Star")
					t.Check("it draws", #made > 0, `{#made}`)
					t.Wait(math.max(0, Combat.Glint.Seconds - (os.clock() - last.At)) + 0.2)
					local left = 0
					for _, piece in made do
						if piece.Parent ~= nil then
							left += 1
						end
					end
					t.Check("and is gone after it", left == 0, `{left} left`)
				end)
				t.Server("FightSpawn") -- clears it
				t.Check("the mark goes with it", Helpers.waitFor(t, 3, function(): boolean
					local read = TargetMark.Read()
					return foe == nil or not read.Shown or read.Target ~= foe
				end))
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
	}
end

return HitCases
