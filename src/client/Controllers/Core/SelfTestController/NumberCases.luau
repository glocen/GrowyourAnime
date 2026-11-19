--!strict
-- NumberCases (client, Studio only): AR44's damage numbers in a fight, a list of their own beside Cases, which joins it
-- as it joins ViewCases (Cases' one table had passed what the type solver checks in one piece). The numbers and words
-- of two bodies kept clear of each other along their whole rise (Rules.Hud.PlaceAlong), and the clip of them in a Tower
-- fight for research's second look.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local World = require(UI.World)
local Layers = require(UI.Layers)

local NumberCases = {}

export type Given = {
	myLead: () -> Model?,
}

function NumberCases.Cases(given: Given): { any }
	local myLead = given.myLead
	return {
		{
			Name = "Fight: every number and word stays clear of every other along its whole rise, on one body and on the next (AR44)",
			Run = function(t: any)
				-- AR44's verdict, fix 3 (research, 12:11): "Block" sat over the critical and the lead's 57 against it, as each
				-- number rises on its own eased curve and one born a beat later caught up. Two stand-in bodies 4 studs apart
				-- before the camera: on one a flurry, then a critical and a word, a beat apart as a fight's do; on the other a hit
				-- taken and a heal. On every frame of their life no two boxes overlap, the critical's splash counted with its
				-- digits. The bodies stand in the sky, the camera held on them 22 studs off as a fight's is, then given back as it
				-- was: a camera that follows the avatar off them lets numbers behind the lens drop out of each other's way.
				local numbers = Combat.Numbers
				local camera = workspace.CurrentCamera
				local wasType, was = camera.CameraType, camera.CFrame
				local HERE = Vector3.new(0, 600, 0)
				local function body(right: number): BasePart
					local part = Instance.new("Part")
					part.Name = "HumanoidRootPart"
					part.Anchored, part.CanCollide, part.CanQuery, part.Transparency = true, false, false, 1
					part.CFrame = CFrame.new(HERE + Vector3.new(right, 0, 0))
					part.Parent = workspace
					return part
				end
				local foe, lead = body(-2), body(2)
				-- Two views: aimed at where the numbers are born, which on a phone sits level with the top band, so each is held
				-- down under it; and aimed higher, the fight low on the screen, in open room.
				local views = {
					{ Name = "under the band", Look = Vector3.new(0, 3, 0) },
					{ Name = "in open room", Look = Vector3.new(0, 9, 0) },
				}
				local view = CFrame.lookAt(HERE + Vector3.new(0, 6, 22), HERE + views[1].Look)
				camera.CameraType = Enum.CameraType.Scriptable
				RunService:BindToRenderStep("NL_ClearCamera", Enum.RenderPriority.Camera.Value + 1, function()
					camera.CFrame = view
				end)
				camera.CFrame = view
				Screen.Close() -- an open screen hides the world's plates (a run's results open on join, as the save holds them)
				t.Wait(0.1)
				local seen: { [string]: boolean } = {}
				local function boxes(): { { Name: string, Min: Vector2, Max: Vector2, Note: string } }
					local out: { { Name: string, Min: Vector2, Max: Vector2, Note: string } } = {}
					for root, onBody in Effects.Counting do
						if root == foe or root == lead then
							for key, c in onBody do
								local lo: Vector2, hi: Vector2 = c.Row.AbsolutePosition, c.Row.AbsolutePosition + c.Row.AbsoluteSize
								local splash = c.Sweep
								if splash then
									local a, b = splash.AbsolutePosition, splash.AbsolutePosition + splash.AbsoluteSize
									lo, hi = Vector2.new(math.min(lo.X, a.X), math.min(lo.Y, a.Y)), Vector2.new(math.max(hi.X, b.X), math.max(hi.Y, b.Y))
								end
								-- Shown only: World hides a plate off the screen, and a hidden one keeps a stale corner.
								if c.Fade < 0.9 and c.Plate.Visible then
									seen[key] = true
									table.insert(out, { Name = key, Min = lo, Max = hi :: Vector2, Note = string.format("shift %.0f,%.0f age %.2f", c.Shift.X, c.Shift.Y, c.Age) })
								end
							end
						end
					end
					return out
				end
				local worst, pair, began = 0, "", os.clock()
				local function shown(box: { Name: string, Min: Vector2, Max: Vector2, Note: string }): string
					return string.format("%s x%.0f..%.0f y%.0f..%.0f (%s)", box.Name, box.Min.X, box.Max.X, box.Min.Y, box.Max.Y, box.Note)
				end
				local watch = RunService.RenderStepped:Connect(function()
					local b = boxes()
					for i = 1, #b do
						for j = i + 1, #b do
							local w = math.min(b[i].Max.X, b[j].Max.X) - math.max(b[i].Min.X, b[j].Min.X)
							local h = math.min(b[i].Max.Y, b[j].Max.Y) - math.max(b[i].Min.Y, b[j].Min.Y)
							if w > 1 and h > 1 and w * h > worst then
								worst, pair = w * h, string.format("%s and %s at %.2f s", shown(b[i]), shown(b[j]), os.clock() - began)
							end
						end
					end
				end)
				local results: { { Name: string, Shown: number, Worst: number, Pair: string, Edge: number? } } = {}
				local ok, problem = pcall(function()
					for _, each in views do
						view = CFrame.lookAt(HERE + Vector3.new(0, 6, 22), HERE + each.Look)
						t.Wait(0.1)
						table.clear(seen)
						worst, pair, began = 0, "", os.clock()
						for _, amount in { 312, 296, 341 } do
							Effects.Number(foe, "Clear@1", amount, { Style = "Dealt" }, numbers)
							t.Wait(0.1)
						end
						Effects.Number(foe, "Clear@2", 1204, { Style = "Critical" }, numbers)
						Effects.Number(lead, "Clear:mine", 57, { Style = "Received" }, numbers)
						t.Wait(0.1)
						Effects.Number(foe, "Clear:word", nil, { Style = "Word", Word = "Block" }, numbers)
						Effects.Number(lead, "Clear:heal", 86, { Style = "Heal" }, numbers)
						t.Wait(numbers.Seconds + 0.2)
						local shownCount = 0
						for _ in seen do
							shownCount += 1
						end
						table.insert(results, { Name = each.Name, Shown = shownCount, Worst = worst, Pair = pair, Edge = World.Edge() })
					end
				end)
				watch:Disconnect()
				RunService:UnbindFromRenderStep("NL_ClearCamera")
				camera.CameraType, camera.CFrame = wasType, was
				foe:Destroy()
				lead:Destroy()
				if not ok then
					error(problem, 0)
				end
				for _, r in results do
					t.Check(`{r.Name}: all five shown on the screen (the flurry's three hits are one)`, r.Shown == 5, `{r.Shown}`)
					t.Check(`{r.Name}: no two overlap on any frame of their life`, r.Worst == 0,
						if r.Worst > 0 then string.format("%s, by %.0f px square; the band's edge %s, the layer's scale %.2f", r.Pair, r.Worst, tostring(r.Edge), Layers.Scale()) else "clear")
				end
				t.Check("both views run", #results == #views, `{#results}`)
			end,
		},
		{
			-- AR44's second look (research, 12:11): the numbers in motion in a real fight, for a short phone clip of the
			-- critical's pop and the splash's timing (tools/capture/grab.ps1). The lead climbs the Tower. Every few seconds, on
			-- its foe a flurry counts up, then a critical and a word land, a beat apart as a fight's do, and the lead takes a hit
			-- and a heal. Only these are drawn (Effects.Only), so the clip shows them alone. The avatar stands beside the fight
			-- so its body hides neither fighter. ReplicatedStorage.NL_ClipStep's attribute Rounds counts the moments shown; its
			-- value "End" ends the run. Meanwhile the foes strike for next to nothing and stand a hundred times longer, by Tunes
			-- put back after, and a run that ends begins again.
			Name = "Clip: AR44, the numbers in motion in a Tower fight, a flurry, a critical and a word on the foe, a hit and a heal on the lead, again until the driver writes End, for research",
			Manual = true,
			Stay = true,
			Place = "Main",
			Run = function(t: any)
				local me = Players.LocalPlayer
				local numbers = Combat.Numbers
				local lift = (require(Shared.Config.Tower) :: any).Lift -- the client's copy, as the Tower case reads it
				local attack, health = lift.Attack, lift.Health
				t.Server("Tune", "Tower.Lift.Attack", 0.01)
				t.Server("Tune", "Tower.Lift.Health", health * 100)
				local step = Instance.new("StringValue")
				step.Name = "NL_ClipStep"
				step.Parent = ReplicatedStorage
				local camera = workspace.CurrentCamera
				local wasType = camera.CameraType
				local audition = me.PlayerGui:FindFirstChild("Studio_Audition") :: ScreenGui?
				local heard = if audition then audition.Enabled else false
				local across: Vector3? = nil -- the fight's side the avatar stands on, set when it stands
				local ok, problem = pcall(function()
					t.Server("TowerEnd")
					t.Server("LeadHeal")
					t.Wait(0.5)
					t.Check("a run begins", (t.Server("TowerStart") :: any) ~= nil and me:GetAttribute("Tower") ~= nil)
					local function rival(): BasePart?
						for _, item in workspace:GetDescendants() do
							if item:IsA("Model") and item:GetAttribute("Kind") == "Rival" and item:GetAttribute("For") == me.UserId then
								return (item:FindFirstChild("HumanoidRootPart") or item.PrimaryPart) :: BasePart?
							end
						end
						return nil
					end
					Effects.Only = "AR44"
					-- The view a player standing beside the fight has: from behind the avatar, both fighters side by side, the avatar
					-- off to the side; held each frame, as the player's camera follows the avatar's facing, not the fight. Studio's
					-- own audition panel stays out of the take.
					if audition then
						audition.Enabled = false
					end
					RunService:BindToRenderStep("NL_ClipCamera", Enum.RenderPriority.Camera.Value + 1, function()
						local foe, lead = rival(), myLead()
						local them = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						local side = across
						if side == nil or foe == nil then
							return
						end
						local middle = if them then (foe.Position + them.Position) / 2 else foe.Position
						camera.CameraType = Enum.CameraType.Scriptable
						camera.CFrame = CFrame.lookAt(middle + side * 16 + Vector3.new(0, 6, 0), middle + Vector3.new(0, 2.5, 0))
					end)
					local began, stood, rounds = os.clock(), false, 0
					while step.Value ~= "End" and os.clock() - began < 600 do
						if me:GetAttribute("Tower") == nil then
							t.Server("TowerStart")
							stood = false
							t.Wait(2)
						end
						local root, lead = rival(), myLead()
						local leadRoot = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						if root then
							if not stood then
								-- Square to the line between the fighters, behind the camera, so it hides neither.
								local them = if leadRoot then leadRoot.Position else root.Position + Vector3.new(4, 0, 0)
								local line = (them - root.Position) * Vector3.new(1, 0, 1)
								if line.Magnitude > 0.1 then
									local side = line.Unit:Cross(Vector3.yAxis)
									local middle = (root.Position + them) / 2
									t.Server("TestStandAt", middle + side * 22)
									across = side
									t.Wait(0.8)
								end
								stood = true
							end
							for _, amount in { 312, 296, 341 } do
								Effects.Number(root, "AR44@1", amount, { Style = "Dealt" }, numbers)
								t.Wait(0.1)
							end
							Effects.Number(root, "AR44@2", 1204, { Style = "Critical" }, numbers)
							if leadRoot then
								Effects.Number(leadRoot, "AR44:mine", 57, { Style = "Received" }, numbers)
							end
							t.Wait(0.1)
							Effects.Number(root, "AR44:word", nil, { Style = "Word", Word = "Block" }, numbers)
							if leadRoot then
								Effects.Number(leadRoot, "AR44:heal", 86, { Style = "Heal" }, numbers)
							end
							rounds += 1
							step:SetAttribute("Rounds", rounds)
							t.Wait(numbers.Seconds + 1) -- gone, and a beat of the fight alone
						else
							t.Wait(0.2)
						end
					end
				end)
				Effects.Only = nil
				RunService:UnbindFromRenderStep("NL_ClipCamera")
				camera.CameraType = wasType
				if audition then
					audition.Enabled = heard
				end
				t.Server("TowerEnd")
				-- The run's results, closed as a player's Back closes them (told seen, so the save drops them): held, they'd
				-- open over every later case and hide the world's plates.
				local ended = os.clock()
				while Screen.Current() ~= "Tower" and os.clock() - ended < 4 do
					t.Wait(0.1)
				end
				if Screen.Current() == "Tower" then
					Screen.Close()
				end
				t.Server("Tune", "Tower.Lift.Attack", attack)
				t.Server("Tune", "Tower.Lift.Health", health)
				step:Destroy()
				if not ok then
					error(problem, 0)
				end
			end,
		},
	}
end

return NumberCases
