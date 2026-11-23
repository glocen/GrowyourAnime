--!strict
-- NumberCases (client, Studio only): AR44's damage numbers in a fight, a list of their own beside Cases, which joins it
-- as it joins ViewCases (Cases' one table had passed what the type solver checks in one piece). The numbers and words
-- of two bodies kept clear of each other along their whole rise (Rules.Hud.PlaceAlong), and the clip of them in a Tower
-- fight for research's second look.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local Shine = require(script.Parent.Parent.Parent.Main.FighterController.Shine)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local World = require(UI.World)
local Layers = require(UI.Layers)
local Digits = require(UI.Kit.Digits)
local Theme = require(UI.Theme)

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
			Name = "Fight: a critical lands with its shine: the split draws in to a hairline each side, a white flash, one glint across (AR44, take C)",
			Run = function(t: any)
				-- AR44, "The critical's shine": take C (research's pick, 2026-11-19, 23:36; Modulo's cut). First the shine alone,
				-- on a plate of the case's own, laid at the moments that matter: the split's two copies, cyan left and up, red right
				-- and down, symmetric always (the content check's condition), from Land to Rest; the flash clear by its Seconds;
				-- the glint's band crossing left to right, leaning Lean degrees on every character, once; all fading with the
				-- number, following its text and size. Then on a real number: a critical has it from its birth, a plain one from
				-- the critical that joins it, and it goes with the number.
				local numbers = Combat.Numbers
				local critical = HudConfig.Numbers.Critical
				local config = critical.Shine
				local split, flash, glint = config.Split, config.Flash, config.Glint
				local size = numbers.Size * critical.Size
				local look: Digits.Look = { Top = critical.Top, Foot = critical.Foot, Ramp = critical.Ramp, Outline = critical.Outline, Weight = critical.Weight, Gap = critical.Gap, Italic = critical.Italic }
				local plate = Instance.new("Frame")
				plate.Name = "NL_ShineTest"
				plate.BackgroundTransparency = 1
				plate.AnchorPoint = Vector2.new(0.5, 0.5)
				plate.Position = UDim2.fromScale(0.5, 0.5)
				plate.Size = UDim2.fromOffset(Digits.Width("12,345", size, look) + size, size * 1.2)
				plate.Parent = Layers.Get("World")
				local row = Digits.new(plate, size, look)
				Digits.Set(row, "12,345")
				local shine = Shine.new(plate, row, size)
				t.Wait(0.1) -- laid out
				local function c1(made: Frame?): TextLabel?
					return if made then made:FindFirstChild("C1") :: TextLabel? else nil
				end
				local function clearOf(made: Frame?): number
					local label = c1(made)
					return if label then label.TextTransparency else -1
				end
				local function offset(made: Frame): Vector2
					return Vector2.new((made.Position.X.Scale - 0.5) * plate.Size.X.Offset, (made.Position.Y.Scale - 0.5) * plate.Size.Y.Offset)
				end
				local cyan, red = shine.Cyan, shine.Red
				local bare = true
				for _, made in { cyan, red, shine.Flash, shine.GlintRow } do
					local label = c1(made)
					local stroke = if label then label:FindFirstChildOfClass("UIStroke") else nil
					local home = if made ~= nil and made == shine.GlintRow then shine.Glint else made
					bare = bare and made ~= nil and home ~= nil and home.Parent == plate and stroke ~= nil and not stroke.Enabled
				end
				t.Check("four copies of the digits in the plate (the glint's in its group), none outlined", bare)
				local cyan1, red1, flash1 = c1(cyan), c1(red), c1(shine.Flash)
				t.Check("the split in cyan and red, the flash white", cyan1 ~= nil and cyan1.TextColor3 == split.Cyan and red1 ~= nil and red1.TextColor3 == split.Red
					and flash1 ~= nil and flash1.TextColor3 == flash.Colour)
				local over = shine.Flash ~= nil and shine.Glint ~= nil and (shine.Flash :: Frame).ZIndex > row.ZIndex and (shine.Glint :: CanvasGroup).ZIndex > row.ZIndex
				t.Check("the split behind the digits, the flash and the glint over them", cyan.ZIndex == red.ZIndex and cyan.ZIndex < row.ZIndex and over, `{cyan.ZIndex} {row.ZIndex}`)
				local function splitAt(name: string, d: number, clear: number)
					local a, b = offset(cyan), offset(red)
					t.Check(`{name}: the two symmetric`, (a + b).Magnitude < 0.01, `{a} {b}`)
					t.Near(`{name}: cyan to the left by {d}`, a.X, -d, 0.01)
					t.Near(`{name}: and up by a quarter of it`, a.Y, -d * split.Across, 0.01)
					t.Near(`{name}: as clear as Config says`, clearOf(cyan), clear, 0.001)
				end
				Shine.Lay(shine, 0, 0)
				splitAt("at the land", split.Land, split.LandClear)
				t.Near("the flash opaque at the land", clearOf(shine.Flash), 0, 0.001)
				Shine.Lay(shine, flash.Seconds / 2, 0)
				t.Near("half clear halfway", clearOf(shine.Flash), 0.5, 0.01)
				Shine.Lay(shine, split.Seconds, 0)
				splitAt("at rest", split.Rest, split.RestClear)
				t.Check("the flash gone by then", shine.Flash == nil and plate:FindFirstChild("Flash") == nil)
				Shine.Lay(shine, glint.Start - 0.01, 0)
				local group = shine.Glint
				t.Check("the glint unlit before its Start", group ~= nil and group.GroupTransparency == 1)
				-- One gradient over the whole number (a UIGradient turns in screen pixels, so Rotation is the lean on the
				-- screen); its characters plain white.
				local gradient = if group then group:FindFirstChildOfClass("UIGradient") else nil
				local plainGlint = c1(shine.GlintRow)
				t.Check("one band over the whole number, leaning its Lean, top to the right", gradient ~= nil and gradient.Rotation == glint.Lean
					and plainGlint ~= nil and plainGlint:FindFirstChildOfClass("UIGradient") == nil and plainGlint.TextColor3 == Color3.new(1, 1, 1))
				-- Where its light is strongest, across the group, and how strong.
				local function lit(): (number, number)
					local best, at = 1, -1
					local band = gradient
					if band == nil then
						return at, best
					end
					for _, point in band.Transparency.Keypoints do
						if point.Value < best then
							best, at = point.Value, point.Time
						end
					end
					return at, best
				end
				Shine.Lay(shine, glint.Start + glint.Seconds * 0.25, 0)
				local early, light = lit()
				t.Check("lit while it crosses", group ~= nil and group.GroupTransparency == 0)
				t.Near("its middle as opaque as its Strength", light, 1 - glint.Strength, 0.05)
				Shine.Lay(shine, glint.Start + glint.Seconds * 0.75, 0)
				local late = lit()
				t.Check("crossing left to right", early > 0 and late > early + 0.3, string.format("%.2f then %.2f of the width", early, late))
				Shine.Lay(shine, glint.Start + glint.Seconds + 0.01, 0)
				t.Check("once: gone after its Seconds", shine.Glint == nil and plate:FindFirstChild("Glint") == nil)
				Shine.Lay(shine, 1, 0.5)
				t.Near("fading with the number", clearOf(cyan), 1 - 0.5 * (1 - split.RestClear), 0.001)
				Digits.Set(row, "99")
				Digits.Restyle(row, size * 1.2, look)
				Shine.Lay(shine, 1, 0)
				t.Check("following its text and size", cyan:GetAttribute("Text") == "99" and red:GetAttribute("Text") == "99" and cyan:GetAttribute("Size") == size * 1.2)
				t.Near("a heavier hit's number splits as much wider", offset(red).X, split.Rest * 1.2, 0.01)
				plate:Destroy()
				-- On real numbers.
				local root = Instance.new("Part")
				root.Name = "HumanoidRootPart"
				root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
				root.CFrame = CFrame.new(0, 600, 0)
				root.Parent = workspace
				local function of(key: string): any
					return if Effects.Counting[root] then Effects.Counting[root][key] else nil
				end
				Effects.Number(root, "SelfTest:shine", 1204, { Style = "Critical" }, numbers)
				local born = of("SelfTest:shine")
				local s = if born then born.Shine else nil
				t.Check("a critical shines from its birth, in what swells", s ~= nil and born.ShineAt == 0 and s.Cyan.Parent == born.Scale.Parent)
				Effects.Number(root, "SelfTest:plain", 37, { Style = "Dealt" }, numbers)
				local plain = of("SelfTest:plain")
				t.Check("a plain number has none", plain ~= nil and plain.Shine == nil)
				t.Wait(0.3)
				Effects.Number(root, "SelfTest:plain", 50, { Style = "Critical" }, numbers)
				t.Check("a critical joining it lands it then", plain ~= nil and plain.Shine ~= nil and plain.ShineAt > 0.2, if plain then string.format("%.2f", plain.ShineAt) else "none")
				t.Wait(numbers.Seconds + 0.5)
				t.Check("and it goes with the number", Effects.Counting[root] == nil and (s == nil or s.Cyan.Parent == nil))
				root:Destroy()
			end,
		},
		{
			Name = "Take: AR44's critical shine on a phone's frame, held at its beats, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- The smallest phone's frame inside Studio's window: the HUD boxed to the window's left 16:9 and drawn at the
				-- scale the smallest phone's would be at that height, so a capture of that 16:9 is the phone's picture, larger.
				-- A critical lands on a stand-in body in the frame's middle, 16 studs out, and is held at the beat the driver
				-- names in ReplicatedStorage.NL_TakeStep (Effects.TimeScale at 0.05, then 0): "Land" (the flash, the split
				-- wide), "Flash" (0.04 s), "Glint" (the band mid-number), "Rest" (0.4 s: the glint gone, the fade not begun), "Live" (one every 1.6 s at full speed),
				-- "Weights" (a dealt, a received, a heal and a critical side by side at Rest, for the outlines' weights at their
				-- authored thickness, research's re-read of 2026-11-23), "End". The attribute Shown says which beat stands.
				local numbers = Combat.Numbers
				local me = Players.LocalPlayer
				local camera = workspace.CurrentCamera
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Land"
				step.Parent = ReplicatedStorage
				local audition = me.PlayerGui:FindFirstChild("Studio_Audition") :: ScreenGui?
				local heard = if audition then audition.Enabled else false
				if audition then
					audition.Enabled = false
				end
				local tall = camera.ViewportSize.Y
				local wide = tall * Theme.Smallest.X / Theme.Smallest.Y
				Layers.Force(Theme.Scale.Floor * tall / Theme.Smallest.Y)
				Layers.Box(Vector2.new(wide, tall) - Vector2.new(0, GuiService.TopbarInset.Height))
				step:SetAttribute("Frame", `{math.round(wide)}x{math.round(tall)}`)
				local glint = HudConfig.Numbers.Critical.Shine.Glint
				local beats: { [string]: number } = { Land = 0, Flash = 0.04, Glint = glint.Start + glint.Seconds * 0.45, Rest = 0.4 }
				local roots: { BasePart } = {}
				local count = 0
				local function clear()
					for _, body in roots do
						body:Destroy()
					end
					table.clear(roots)
				end
				-- A number on a stand-in body 16 studs out under the frame's point (across, 0.55 down).
				local function put(across: number, amount: number, style: string): any
					local ray = camera:ViewportPointToRay(wide * across, tall * 0.55)
					local body = Instance.new("Part")
					body.Name = "HumanoidRootPart"
					body.Anchored, body.CanCollide, body.CanQuery, body.Transparency = true, false, false, 1
					body.CFrame = CFrame.new(ray.Origin + ray.Direction * 16 - Vector3.new(0, 3, 0))
					body.Parent = workspace
					table.insert(roots, body)
					count += 1
					local key = `SelfTest:take{count}`
					Effects.Number(body, key, amount, { Style = style }, numbers)
					return Effects.Counting[body][key]
				end
				local function land(): any
					clear()
					return put(0.5, 1204, "Critical")
				end
				local weights: { { Across: number, Amount: number, Style: string } } = {
					{ Across = 0.2, Amount = 486, Style = "Dealt" },
					{ Across = 0.4, Amount = 312, Style = "Received" },
					{ Across = 0.6, Amount = 148, Style = "Heal" },
					{ Across = 0.8, Amount = 1204, Style = "Critical" },
				}
				local ok, problem = pcall(function()
					local shown = ""
					local began = os.clock()
					local live = 0
					while step.Value ~= "End" and os.clock() - began < 600 do
						if step.Value ~= shown then
							shown = step.Value
							local beat = beats[shown]
							if shown == "Weights" then
								Effects.TimeScale = 0
								clear()
								local last
								for _, w in weights do
									last = put(w.Across, w.Amount, w.Style)
								end
								Effects.TimeScale = 0.05
								while last.Age < beats.Rest and os.clock() - began < 600 do
									t.Wait()
								end
								Effects.TimeScale = 0
								t.Wait(0.2)
								step:SetAttribute("Age", math.round(last.Age * 1000) / 1000)
							elseif beat then
								Effects.TimeScale = 0
								local c = land()
								if beat > 0 then
									Effects.TimeScale = 0.05
									while c.Age < beat and os.clock() - began < 600 do
										t.Wait()
									end
									Effects.TimeScale = 0
								end
								t.Wait(0.2)
								step:SetAttribute("Age", math.round(c.Age * 1000) / 1000)
							else
								Effects.TimeScale = 1
							end
							step:SetAttribute("Shown", shown)
						end
						if shown == "Live" and os.clock() - live > 1.6 then
							live = os.clock()
							land()
						end
						t.Wait(0.05)
					end
				end)
				Effects.TimeScale = 1
				clear()
				Layers.Box(nil)
				Layers.Force(nil)
				if audition then
					audition.Enabled = heard
				end
				local ended = step.Value == "End"
				step:Destroy()
				if not ok then
					error(problem, 0)
				end
				t.Check("the driver ended it", ended)
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
