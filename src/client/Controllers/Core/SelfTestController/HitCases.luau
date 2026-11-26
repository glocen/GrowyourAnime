--!strict
-- HitCases: the hit, TR69's block A (docs/test-requests.md, TR69). The attack clips' snap behind its live switch
-- (Config.Animations.Snap); the ring at the feet of the lead's target in its type's colour (Config.Combat.Ring,
-- TargetRing) and gone with it; a Shade's mask glint as its ordinary swing starts, back to its own before the swing's
-- Hit beat (Config.Combat.Glint, MaskGlint). The pack's last fall's hold is Rules.Fight's (its logic case). Apart from
-- Cases, whose size the type check can't take more of.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local Shades = require(Shared.Config.Shades)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Main = script.Parent.Parent.Parent.Main
local Clips = require(Main.FighterController.Clips)
local TargetRing = require(Main.FighterController.TargetRing)
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
			Name = "The hit (TR69 A): a thin ring at the feet of the lead's target in its type's colour, gone with it; a Shade's mask glints as its swing starts and is back to its own before the swing's Hit",
			Run = function(t: any)
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				t.Check("the lead is in the world", lead ~= nil and type(level) == "number")
				if lead == nil or type(level) ~= "number" then
					return
				end
				local swing = Actions.ById[Enemies.ById.brawler.Action :: string]
				t.Check("the glint ends before the swing's Hit", swing ~= nil and Combat.Glint.Seconds < (swing.Beats :: any).Hit, if swing then `{(swing.Beats :: any).Hit} s` else "no swing")
				local spawned = t.Server("FightSpawn", "brawler", level + TOUGHER, AHEAD)
				t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
				if type(spawned) ~= "table" or spawned.Ok ~= true then
					return
				end
				local foe: Model? = nil
				local ok, problem = pcall(function()
					local met = Helpers.waitFor(t, WATCH, function(): boolean
						foe = fighterModel(spawned.Id)
						local read = TargetRing.Read()
						return foe ~= nil and lead:GetAttribute("Target") == spawned.Id and read.Shown and read.Target == foe
					end)
					t.Check("the ring shows under the lead's target", met)
					local body = foe :: Model?
					if not met or body == nil then
						return
					end
					local read = TargetRing.Read()
					local want = HudConfig.Card.Types[Enemies.ById.brawler.Type]
					t.Check("in its type's colour", read.Colour == want, tostring(read.Colour))
					t.Check("at the body's scale", math.abs(read.Radius - Combat.Ring.Radius * body:GetScale()) < 1e-3, string.format("%.2f", read.Radius))
					local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
					local at = read.At :: Vector3?
					t.Check("at its feet, on the floor", root ~= nil and at ~= nil and ((at - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 1 and at.Y < root.Position.Y - 1,
						if root and at then string.format("%.1f studs under its root", root.Position.Y - at.Y) else "")
					-- the glint, as its swing starts
					local glinted = Helpers.waitFor(t, WATCH, function(): boolean
						local last = MaskGlint.Last()
						return last ~= nil and last.Model == body
					end)
					t.Check("its mask glints as it swings", glinted)
					local last = MaskGlint.Last()
					if not glinted or last == nil then
						return
					end
					local base = Shades.MaskEmissive
					t.Check("on its mask", last.Masks >= 1, `{last.Masks}`)
					local since = os.clock() - last.At
					t.Check("lit over its own while it runs", since >= Combat.Glint.Seconds or last.Lit > base + 0.5, string.format("%.2f at %.2f s", last.Lit, since))
					t.Wait(math.max(0, Combat.Glint.Seconds - since) + 0.1)
					local after = MaskGlint.Last()
					t.Check("and back to its own once done", after ~= nil and (after.Model ~= body or math.abs(after.Lit - base) < 1e-3 or os.clock() - after.At < Combat.Glint.Seconds),
						if after then string.format("%.2f", after.Lit) else "")
				end)
				t.Server("FightSpawn") -- clears it
				t.Check("the ring goes with it", Helpers.waitFor(t, 3, function(): boolean
					local read = TargetRing.Read()
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
