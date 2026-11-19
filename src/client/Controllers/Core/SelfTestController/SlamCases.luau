--!strict
-- The keeper's marked slam and the lead's ways out of it (TR44), apart: Cases is at the type checker's limit. One case
-- plays a keeper's try through the server's own paths (KeeperService, FightService, SlamService), the slam made ready at
-- once by SlamService's "Now", under each mode of the switch: Off, the footprint drawn, filling to its ring on the Slam
-- and gone with it, counted; A, the avatar walks out and its lead follows, held away until the Slam, the keeper's aim
-- fixed from Plant, the miss counted on purpose; B, the Recall's button by the thumb, a press dashing the lead out, a
-- second refused on its cooldown, the lead striking nothing on its way, the miss counted on purpose, the button's own
-- press. Outside a try, and in A, there's no Recall. The switch is put back at its end.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local StagesConfig = require(Shared.Config.Stages)
local Actions = require(Shared.Definitions.Actions)
local MarkRule = require(Shared.Rules.Mark)
local Parts = require(Shared.Util.Parts)
local SlamController = require(script.Parent.Parent.Parent.Main.SlamController)
local Helpers = require(script.Parent.Helpers)
local UI = script.Parent.Parent.Parent.Parent.UI
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)

local SlamCases = {}

local MOVE = 2.5 -- seconds for the try's fade to move the avatar (KeeperService's)
local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local CHOOSE = 4 -- seconds a ready keeper may take to come into range and begin its slam
local WALK = 7 -- studs the avatar walks out in A
local AIM_HELD = 2 -- degrees the keeper may turn between its Plant and its Slam (its body settling, not its aim)
local TOUCH = 44 -- a touch target's least side, rendered

local player = Players.LocalPlayer
local waitFor = Helpers.waitFor

local function fighterModel(id: string): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function flatLook(model: Model): Vector3
	local look = model:GetPivot().LookVector
	return Vector3.new(look.X, 0, look.Z).Unit
end

local function degrees(a: Vector3, b: Vector3): number
	return math.deg(math.acos(math.clamp(a:Dot(b), -1, 1)))
end

function SlamCases.Cases(): { any }
	return {
		{
			Name = "Slam (TR44): the keeper's footprint, its fill and its aim; Off counted, A's walk out, B's Recall and its cooldown",
			Place = "Festival", -- TR45: its world stands in that place only
			Run = function(t: any)
				local was = t.Server("Slam").Mode
				local look = Combat.Keeper.Mark
				local action = Actions.ById.KeeperSignature
				local tell = action.Beats.Slam - action.Beats.Plant
				local function restore()
					t.Server("Slam", was)
				end
				-- A try, its keeper in its ring and the lead on it.
				t.Server("Slam", "Off")
				t.Server("Slam", "Reset")
				t.Server("KeeperRest", 0)
				local start = t.Server("KeeperTry")
				t.Check("a try starts", start.Ok == true, tostring(start.Error))
				if start.Ok ~= true then
					restore()
					return
				end
				t.Wait(MOVE)
				local state = t.Server("Keeper")
				local keeper = fighterModel(state.Keeper)
				t.Check("its keeper stands in the ring", keeper ~= nil, tostring(state.Keeper))
				waitFor(t, 6, function(): boolean
					local now = t.Server("Keeper")
					return now.LeadTarget == now.Keeper and now.KeeperTarget == now.Lead
				end)
				if keeper == nil then
					t.Server("KeeperEnd", "Loss")
					restore()
					return
				end
				local k = keeper :: Model

				-- One slam: made ready, begun, its footprint read as it goes down; `during` runs each frame of its tell.
				local function slam(during: ((at: number) -> ())?): { [string]: any }?
					t.Server("Slam", "Now")
					local down = waitFor(t, CHOOSE, function(): boolean
						return k:GetAttribute("MarkSlam") ~= nil
					end)
					if not down then
						return nil
					end
					local at, slamAt = k:GetAttribute("MarkAt") :: Vector3, k:GetAttribute("MarkSlam") :: number
					local read: any = { At = at, Down = k:GetAttribute("MarkDown") :: number, Slam = slamAt, Look = flatLook(k), Turned = 0, Half = -1, Gone = false }
					read.Ring, read.Disc = SlamController.Ring(k)
					while workspace:GetServerTimeNow() < slamAt - 0.05 and k:GetAttribute("MarkSlam") ~= nil do
						read.Turned = math.max(read.Turned, degrees(read.Look, flatLook(k)))
						if read.Half < 0 and workspace:GetServerTimeNow() >= (read.Down + slamAt) / 2 then
							local _, disc = SlamController.Ring(k)
							read.Half = if disc then disc.Radius else 0
						end
						if during then
							during(workspace:GetServerTimeNow())
						end
						RunService.Heartbeat:Wait()
					end
					read.Gone = waitFor(t, 1, function(): boolean
						local ring = SlamController.Ring(k)
						return k:GetAttribute("MarkSlam") == nil and ring == nil
					end)
					t.Wait(0.3) -- the server's count, after its hit
					read.Counts = t.Server("Slam").Counts
					return read
				end

				-- Off: today's rule, the footprint drawn and counted.
				local off = slam()
				t.Check("Off: the keeper's slam comes in its fight, its footprint down", off ~= nil)
				if off then
					t.Near("its tell, Plant to Slam (s)", off.Slam - off.Down, tell, 0.02)
					local keeperAt = k:GetPivot().Position
					local gap = Vector3.new(off.At.X - keeperAt.X, 0, off.At.Z - keeperAt.Z).Magnitude
					t.Near("it lies Ahead and Left of the keeper (studs)", gap, math.sqrt(look.Ahead ^ 2 + look.Left ^ 2), 1)
					t.Check("a ring of its radius, an edge wide", off.Ring ~= nil and math.abs(off.Ring.Radius - look.Radius) < 0.01 and math.abs(off.Ring.InnerRadius - (look.Radius - look.Edge)) < 0.01)
					t.Check("a disc inside it, see-through", off.Disc ~= nil and math.abs(off.Disc.Transparency - look.Fill) < 0.01)
					t.Near("halfway through the tell, the disc half the ring (studs)", off.Half, look.Radius / 2, 0.6)
					t.Check("both gone with the Slam", off.Gone == true)
					local tally = off.Counts.Off
					t.Check("counted under Off", tally ~= nil and tally.Slams == 1, if tally then `{tally.Slams} slams` else "none")
					t.Row("Off: the lead stood still and was hit (1) or missed (0)", nil, nil, if tally then tally.Hit else nil, "")
				end
				local lead = myLead()

				-- A: the avatar walks out of reach; its lead follows, held away until the Slam.
				t.Server("Slam", "A")
				local followed, away = false, false
				local walked = false
				local a = slam(function()
					local root = Parts.Root(player.Character)
					local humanoid = Parts.Humanoid(player.Character)
					if not walked and root and humanoid then
						walked = true
						local at = k:GetAttribute("MarkAt")
						local from = if typeof(at) == "Vector3" then Vector3.new(root.Position.X - at.X, 0, root.Position.Z - at.Z) else root.CFrame.LookVector * -1
						local out = if from.Magnitude > 0.1 then from.Unit else Vector3.new(1, 0, 0)
						humanoid:MoveTo(root.Position + out * WALK)
					end
					if lead and lead:GetAttribute("Away") == true then
						followed = true
					end
				end)
				away = lead ~= nil and lead:GetAttribute("Away") == true
				t.Check("A: a slam", a ~= nil)
				if a then
					t.Check("the lead followed the avatar out", followed)
					t.Check("the keeper's aim held from Plant to Slam", a.Turned <= AIM_HELD, string.format("turned %.1f degrees", a.Turned))
					local tally = a.Counts.A
					t.Check("counted under A: missed, on purpose", tally ~= nil and tally.Slams == 1 and tally.Missed == 1 and tally.OnPurpose == 1, if tally then `{tally.Slams} slams, {tally.Hit} hit, {tally.OnPurpose} on purpose, {tally.Accident} by accident` else "none")
					t.Check("and back to its fight after the Slam", waitFor(t, 1.5, function(): boolean
						return lead ~= nil and lead:GetAttribute("Away") == nil
					end), `held away at the Slam: {away}`)
				end
				t.Check("A: no Recall", waitFor(t, 0.5, function(): boolean
					return SlamController.Recall() == nil
				end))
				t.Equal("and the server refuses one", SlamController.Press().Error, "Off")

				-- B: the Recall, by the right thumb.
				t.Server("Slam", "B")
				t.Check("B: the Recall shows in a keeper's try", waitFor(t, 1, function(): boolean
					return SlamController.Recall() ~= nil
				end))
				local button = SlamController.Recall()
				if button then
					local size = button.AbsoluteSize
					t.Check("a touch's size or more", size.X >= TOUCH and size.Y >= TOUCH, `{size.X} x {size.Y}`)
					local view = workspace.CurrentCamera.ViewportSize
					local middle = button.AbsolutePosition + size / 2
					t.Check("in the right thumb's corner", middle.X > view.X * 0.6 and middle.Y > view.Y * 0.5, `at {middle.X}, {middle.Y} of {view.X} x {view.Y}`)
				end
				local first: any, second: any, lunged = nil, nil, false
				local b = slam(function()
					if first == nil then
						first = SlamController.Press()
						second = SlamController.Press()
					end
					if lead and lead:GetAttribute("Away") == true and (lead:GetAttribute("Action") or "") ~= "" then
						lunged = true
					end
				end)
				t.Check("B: a slam", b ~= nil)
				if b then
					t.Check("a press in the tell: taken", first ~= nil and first.Ok == true, if first then tostring(first.Error) else "")
					t.Equal("a second at once: refused on its cooldown", if second then second.Error else nil, "Cooldown")
					t.Check("the lead strikes nothing on its way", not lunged)
					local tally = b.Counts.B
					t.Check("counted under B: missed, on purpose", tally ~= nil and tally.Slams == 1 and tally.Missed == 1 and tally.OnPurpose == 1, if tally then `{tally.Slams} slams, {tally.Hit} hit, {tally.OnPurpose} on purpose, {tally.Accident} by accident` else "none")
					local ready = player:GetAttribute("RecallReady")
					t.Check("its cooldown on the player", type(ready) == "number")
					local face = button and button:FindFirstChild("Word", true)
					local counting = face ~= nil and face:IsA("TextLabel") and tonumber(face.Text) ~= nil
					t.Check("its face counts the seconds down", counting or (type(ready) == "number" and workspace:GetServerTimeNow() >= ready), if face and face:IsA("TextLabel") then face.Text else "no face")
					-- the button's own press, once it's ready again
					if type(ready) == "number" then
						t.Wait(math.max(0, ready - workspace:GetServerTimeNow()) + 0.2)
					end
					local still = SlamController.Recall()
					if still then
						Button.Press(still)
					end
					t.Check("the button's own press asks it", waitFor(t, REPLICATE, function(): boolean
						local now = player:GetAttribute("RecallReady")
						return type(now) == "number" and type(ready) == "number" and now > ready
					end))
				end
				local counts = t.Server("Slam").Counts
				t.Check("each mode counted apart", counts.Off and counts.A and counts.B and counts.Off.Slams == 1 and counts.A.Slams == 1 and counts.B.Slams == 1)

				-- The try ends; outside one, no Recall.
				t.Server("KeeperEnd", "Loss")
				waitFor(t, Combat.Keeper.LossPause + MOVE + 2, function(): boolean
					return player:GetAttribute("Try") == nil
				end)
				-- the try lost is Stage 4's run: its card, closed so the next case starts clear
				local carded = waitFor(t, StagesConfig.Results.After + REPLICATE, function(): boolean
					local open = Screen.Current()
					return open ~= nil
				end)
				if carded then
					Screen.Close()
				end
				t.Check("outside a try, no Recall", waitFor(t, 0.5, function(): boolean
					return SlamController.Recall() == nil
				end))
				t.Equal("and the server refuses one", SlamController.Press().Error, "NoFight")
				t.Server("LeadHeal")
				restore()
				t.Equal("the switch put back", t.Server("Slam").Mode, MarkRule.Mode(was))
			end,
		},
	}
end

return SlamCases
