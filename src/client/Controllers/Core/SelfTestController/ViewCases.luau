--!strict
-- ViewCases (client, Studio only): TR24's fixes 1 to 3, a list of their own beside Cases, which joins it as it joins
-- HudCases (Cases' one table had passed what the type solver checks in one piece). The next step's marker in the world
-- and at the frame's edge (UI.Guide), the lead beside the avatar on the camera's right, and a lead in the camera's line
-- fading on this screen (ViewController), and fix 2 in play: a Shade in the camera's view taken on at once, one out of it
-- waited for in view (Rules.Fight.LeadTarget's order is the logic cases').

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local Fight = require(Shared.Rules.Fight)
local Net = require(Shared.Net)
local ViewController = require(script.Parent.Parent.Parent.Main.ViewController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Guide = require(UI.Guide)
local Layers = require(UI.Layers)
local World = require(UI.World)

local ViewCases = {}

export type Given = {
	LEAD_SETTLE: number,
	SHADE_AHEAD: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	myLead: () -> Model?,
}

local FADE_WAIT = Combat.Lead.Fade.Seconds + 0.25 -- a fade's length and a few frames
local TAKE = 2 -- seconds a lead may take to take on a Shade in view, or to meet one once its wait is over
local CROSS = 1.5 -- seconds more for the lead to walk across when the camera turns round (Side and Ahead, both sides)
local STAYS = 2 -- studs toward the Shade its place may give, the Shade's knock included, while it waits in view

local function flatUnit(v: Vector3): Vector3?
	local flat = Vector3.new(v.X, 0, v.Z)
	return if flat.Magnitude > 1e-3 then flat.Unit else nil
end

-- A stand-in lead on this screen only: a body in workspace.Fighters with a lead's attributes, as the server makes one.
local function standIn(): (Model, Part, Decal)
	local model = Instance.new("Model")
	model.Name = "NL_SelfTestViewLead"
	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.Size = Vector3.new(2, 5, 1)
	body.Parent = model
	local face = Instance.new("Decal")
	face.Parent = body
	model.PrimaryPart = body
	model:SetAttribute("Side", "Lead")
	model:SetAttribute("State", "Idle")
	model:SetAttribute("Owner", 0)
	local folder = workspace:FindFirstChild("Fighters") or workspace
	model.Parent = folder
	return model, body, face
end

function ViewCases.Cases(given: Given): { any }
	local waitFor = given.waitFor
	return {
		{
			Name = "Fight: TR24's fix 3, the lead stands beside the avatar on the camera's right, out of its line, unfaded",
			Run = function(t: any)
				t.Wait(given.LEAD_SETTLE)
				local lead = given.myLead()
				t.Check("the lead is in the world", lead ~= nil)
				if lead == nil then
					return
				end
				local root = lead:FindFirstChild("HumanoidRootPart") :: BasePart?
				local camera = workspace.CurrentCamera
				local look = flatUnit(camera.CFrame.LookVector)
				if root == nil or look == nil then
					t.Check("a root and a camera looking along the ground", false)
					return
				end
				local right = (look :: Vector3):Cross(Vector3.yAxis)
				-- once it has walked to its place: Side right, Ahead in front, along where the camera looks
				local offset = Vector3.zero
				local settled = waitFor(t, 4, function(): boolean
					offset = root.Position - t.Root().Position
					return offset:Dot(right) >= Combat.Lead.Side - 0.75 and math.abs(offset:Dot(look :: Vector3) - Combat.Lead.Ahead) <= Combat.Lead.Settle
				end)
				t.Check("on the camera's right, Side studs or more", settled, string.format("%.1f right, %.1f ahead", offset:Dot(right), offset:Dot(look :: Vector3)))
				local head = t.Root().Position + Vector3.new(0, 1.5, 0)
				local line = head - camera.CFrame.Position
				local along = (root.Position - camera.CFrame.Position):Dot(line.Unit)
				local across = ((root.Position - camera.CFrame.Position) - line.Unit * along).Magnitude
				local fade = Combat.Lead.Fade
				t.Check("out of the camera's line to the avatar", not Fight.InLine(along, across, line.Magnitude, 1, fade.Margin, fade.Near), string.format("%.1f along, %.1f off", along, across))
				t.Wait(FADE_WAIT)
				t.Near("so it isn't faded", ViewController.Faded(lead), 0, 1e-3)
			end,
		},
		{
			Name = "Fight: TR24's fix 2, the lead takes on a Shade in the camera's view at once, and waits in view for one coming from out of it",
			Run = function(t: any)
				local lead = given.myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				t.Check("the lead is in the world", type(level) == "number")
				local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if lead == nil or root == nil or type(level) ~= "number" then
					return
				end
				local mineId = lead:GetAttribute("Fighter")
				local camera = workspace.CurrentCamera
				local was, wasType = camera.CFrame, camera.CameraType
				local facing = flatUnit(t.Root().CFrame.LookVector) or Vector3.new(0, 0, -1)
				local looking = facing
				-- the camera behind the avatar looking along `looking`, and the server told so (ViewController says it too,
				-- while this screen draws); called every poll, so the server's view never goes stale
				local function aim()
					local at = t.Root().Position + Vector3.new(0, 1.5, 0)
					camera.CameraType = Enum.CameraType.Scriptable
					camera.CFrame = CFrame.lookAt(at - looking * 14 + Vector3.new(0, 5, 0), at)
					Net.Client.Fire("View", math.deg(math.atan2(looking.Z, looking.X)))
				end
				local function mine(): any
					for _, row in t.Server("Fighters") do
						if row.Id == mineId then
							return row
						end
					end
					return nil
				end
				local ok, err = pcall(function()
					aim()
					t.Wait(given.LEAD_SETTLE)
					local spawned = t.Server("FightSpawn", "brawler", level, given.SHADE_AHEAD)
					t.Check("in view: the Shade spawns ahead", type(spawned) == "table" and spawned.Ok == true)
					if type(spawned) ~= "table" or spawned.Ok ~= true then
						return
					end
					local began = os.clock()
					local took: number? = nil
					while took == nil and os.clock() - began < TAKE do
						aim()
						local row = mine()
						if row and row.Target == spawned.Id then
							took = os.clock() - began
						end
						t.Wait(0.2)
					end
					t.Check("in view: the lead takes it on at once", took ~= nil, string.format("%.1f s", took or -1))
					t.Server("FightSpawn")
					-- the camera turned round: the same Shade comes from behind it, out of view
					looking = -facing
					aim()
					t.Wait(given.LEAD_SETTLE + CROSS)
					local avatar = t.Root().Position
					-- one that comes for the lead (since fix 6 a Shade passes over an idle lead: one out of view and not on it
					-- is left for the player to look at, Rules.Fight.LeadTarget)
					spawned = t.Server("FightSpawn", "brawler", level, given.SHADE_AHEAD, true)
					t.Check("out of view: the Shade spawns behind the camera", type(spawned) == "table" and spawned.Ok == true)
					if type(spawned) ~= "table" or spawned.Ok ~= true then
						return
					end
					local wait = Combat.Lead.View.Wait
					local toward = -math.huge
					local met: number? = nil
					local targeted: number? = nil -- when the lead first took it as its target, for the report
					local last = "no row"
					began = os.clock()
					while met == nil and os.clock() - began < wait + TAKE do
						aim()
						local age = os.clock() - began
						if age < wait - 0.5 then
							toward = math.max(toward, (root.Position - avatar):Dot(facing))
						end
						local row = mine()
						if row then
							last = `target {if row.Target == spawned.Id then "it" else tostring(row.Target)}, action "{row.Action}"`
							if row.Target == spawned.Id and targeted == nil then
								targeted = age
							end
						end
						if age >= wait - 0.5 and row and row.Target == spawned.Id and row.Action ~= "" then
							met = age
						end
						t.Wait(0.2)
					end
					local place = -Combat.Lead.Ahead
					t.Check("out of view: it waits at its place in view, not walking off to it", toward <= place + STAYS, string.format("%.1f studs toward it, its place %.1f", toward, place))
					t.Check("and meets it once its wait is over, if it hasn't come", met ~= nil, string.format("%.1f s, the wait %.1f; targeted at %.1f s, last %s", met or -1, wait, targeted or -1, last))
				end)
				t.Server("FightSpawn")
				camera.CameraType = wasType
				camera.CFrame = was
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Fight: TR24's fix 3, a lead in the camera's line fades on this screen, and comes back once clear",
			Run = function(t: any)
				local camera = workspace.CurrentCamera
				local model, body, face = standIn()
				local ok, err = pcall(function()
					local eye = camera.CFrame.Position
					local head = t.Root().Position + Vector3.new(0, 1.5, 0)
					local line = head - eye
					body.CFrame = CFrame.new(eye + line * 0.55)
					t.Wait(FADE_WAIT)
					local want = Combat.Lead.Fade.Transparency
					t.Near("between the camera and the avatar: faded all the way", ViewController.Faded(model), 1, 1e-3)
					t.Near("its body by Fade.Transparency", body.LocalTransparencyModifier, want, 0.01)
					t.Near("its face too", face.LocalTransparencyModifier, want, 0.01)
					local right = camera.CFrame.RightVector
					body.CFrame = CFrame.new(head + right * 15)
					t.Wait(FADE_WAIT)
					t.Near("well aside: whole again", body.LocalTransparencyModifier, 0, 0.01)
					body.CFrame = CFrame.new(eye + line * 0.55)
					t.Wait(FADE_WAIT)
					model:SetAttribute("State", "Down")
					t.Wait(0.1)
					t.Near("down, its fall is the effects': let go whole at once", body.LocalTransparencyModifier, 0, 0.01)
				end)
				model:Destroy()
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "HUD: TR24's fix 1, the next step's marker over its target in view, at the frame's edge out of it, and none beside it",
			Run = function(t: any)
				local camera = workspace.CurrentCamera
				local target = Instance.new("Part")
				target.Name = "NL_SelfTestGuideTarget"
				target.Anchored = true
				target.CanCollide = false
				target.CanQuery = false
				target.Transparency = 1
				target.Size = Vector3.new(4, 4, 4)
				target.Parent = workspace
				local ok, err = pcall(function()
					local look = flatUnit(camera.CFrame.LookVector) or Vector3.new(0, 0, -1)
					local avatar = t.Root().Position
					target.Position = avatar + look * 30
					Guide.Test({ target })
					t.Wait(0.2)
					local read = Guide.Read()
					t.Check("in view: its chevron shows", read.Count == 1 and read.Shown == 1, `{read.Count} targets, {read.Shown} shown`)
					t.Check("and no arrow at the edge", not read.Edge)
					-- high in view, over the HUD's band (the Door's crown): still its chevron, and no arrow with it
					local over = camera.CFrame.Position + camera.CFrame.LookVector * 40
					local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, HudConfig.Guide.Top * Layers.Scale() + 24)
					target.Position = ray.Origin + ray.Direction * (over - camera.CFrame.Position).Magnitude - Vector3.new(0, target.Size.Y / 2 + HudConfig.Guide.Lift, 0)
					t.Wait(0.2)
					read = Guide.Read()
					t.Check("high in view, over the band: its chevron, and no arrow", read.Shown == 1 and not read.Edge, `edge {read.Edge}, {read.Shown} shown`)
					target.Position = avatar - look * 40
					t.Wait(0.2)
					read = Guide.Read()
					t.Check("behind the camera: the arrow at the frame's edge", read.Edge and read.Shown == 0, `edge {read.Edge}, {read.Shown} shown`)
					-- and under the HUD's top band, never drawn under a card or a pill (it hid under the wallet)
					local band = World.Edge()
					local arrow = read.Arrow
					if band and arrow then
						local layer = arrow.Parent :: GuiObject
						local arrowTop = (arrow.AbsolutePosition.Y - layer.AbsolutePosition.Y) / Layers.Scale()
						t.Check("its top under the top band", arrowTop >= band - 0.5, string.format("%.0f, the band %.0f", arrowTop, band))
					end
					target.Position = avatar + look * (HudConfig.Guide.Near - 2)
					t.Wait(0.2)
					read = Guide.Read()
					t.Check("beside the avatar: both step back for its prompt", not read.Edge and read.Shown == 0, `edge {read.Edge}, {read.Shown} shown`)
				end)
				Guide.Test(nil)
				target:Destroy()
				if not ok then
					error(err, 0)
				end
			end,
		},
	}
end

return ViewCases
