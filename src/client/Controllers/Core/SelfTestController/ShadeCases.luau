--!strict
-- ShadeCases (client, Studio only): AR52's Guard and Dasher in a fight, a list of their own beside Cases, which joins it
-- as it joins SignatureCases (Cases is at what the type solver checks in one piece). Each spawns its Shade on the lead
-- through FightSpawn and plays it on the server's own paths (FightService, SlamService):
-- * the Guard raises its shield in the fight, its grey pane standing to Drop; the lead's hits glance off it (its
--   signature held, Auto off, so it can't break the raise first); the lead's signature into a raise breaks it open, the
--   pane gone and the Guard staggered;
-- * the Dasher's line goes down from its feet through the lead, its fill reaching the end on the hit; under A, a lead
--   that stays is hit and the Dasher runs on through it and lies there, its back to it, and an avatar that walks off takes its lead off the line and
--   the lunge hits empty stone, each counted under "Lunge A". The switch and Auto are put back at their ends.
-- Their rules' own cases are the logic cases' (Cases/Shades).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local Actions = require(Shared.Definitions.Actions)
local FightRule = require(Shared.Rules.Fight)
local MarkRule = require(Shared.Rules.Mark)
local Parts = require(Shared.Util.Parts)
local SlamController = require(script.Parent.Parent.Parent.Main.SlamController)

local ShadeCases = {}

local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local RAISES = 3 -- raises the Guard case waits through for a glance and for a break
local LUNGE_SOON = 6 -- seconds a ready Dasher may take to come into range and put its line down
local WALK = 7 -- studs the avatar walks off the line

local player = Players.LocalPlayer

local function fighterModel(id: any): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function now(): number
	return workspace:GetServerTimeNow()
end

-- Cases' own helpers and measures, one home each.
export type Given = {
	LEAD_SETTLE: number,
	SHADE_AHEAD: number,
	SHADE_TOUGHER: number,
	SHADE_TIMEOUT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	myLead: () -> Model?,
}

function ShadeCases.Cases(given: Given): { any }
	local LEAD_SETTLE, SHADE_AHEAD, SHADE_TOUGHER, SHADE_TIMEOUT = given.LEAD_SETTLE, given.SHADE_AHEAD, given.SHADE_TOUGHER, given.SHADE_TIMEOUT
	local waitFor, myLead = given.waitFor, given.myLead

	-- The player's lead whole and out of any fight, and a Shade of `def` coming for it, tough enough to last.
	local function begin(t: any, def: string): (Model?, Model?)
		t.Server("LeadHeal")
		t.Server("LeadCalm")
		t.Server("FightSpawn")
		t.Wait(LEAD_SETTLE)
		local lead = myLead()
		if lead == nil then
			t.Check("a lead to fight with", false)
			return nil, nil
		end
		local level = lead:GetAttribute("Level")
		local spawned = t.Server("FightSpawn", def, (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD, true)
		t.Check(`a {def} spawns`, type(spawned) == "table" and spawned.Ok == true)
		local foe: Model? = nil
		waitFor(t, REPLICATE, function(): boolean
			foe = fighterModel(if type(spawned) == "table" then spawned.Id else nil)
			return foe ~= nil
		end)
		t.Check(`its model reaches the client`, foe ~= nil)
		t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, function(): boolean
			local id = lead:GetAttribute("Target")
			return type(id) == "string" and id ~= ""
		end))
		return lead, foe
	end

	return {
		{
			Name = "Shades (AR52): the Guard raises its shield in the fight, its pane standing to Drop; hits glance off; a signature breaks it open, staggered",
			Run = function(t: any)
				local lead, foe = begin(t, "guard")
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					return
				end
				local guard = foe :: Model
				local raise = Actions.ById.GuardRaise
				local glanced, broke, whole = 0, 0, 0
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) ~= "table" or hit.T ~= guard or hit.Dodged then
						return
					end
					if hit.Guarded == "Glanced" then
						glanced += 1
					elseif hit.Guarded == "Broke" then
						broke += 1
					else
						whole += 1
					end
				end)
				local function raised(): boolean
					local up = guard:GetAttribute("GuardUntil")
					return type(up) == "number" and now() < up
				end
				local auto = player:GetAttribute("SignatureAuto") ~= false
				Net.Client.Invoke("Signature", "Auto", false) -- its signature held: a heavy hit would break the raise
				local ok, err = pcall(function()
					-- Its raises, read until a glance is seen (a ranged lead may close in on the second).
					local first = true
					for _ = 1, RAISES do
						local up = waitFor(t, if first then SHADE_TIMEOUT else raise.Cooldown + 2, raised)
						if first then
							t.Check("it raises its shield in the fight", up)
						end
						if not up then
							break
						end
						local untilAt = guard:GetAttribute("GuardUntil") :: number
						local startedAt = guard:GetAttribute("ActionAt")
						if first then
							t.Check("its grey pane stands before it", waitFor(t, 0.5, function(): boolean
								return SlamController.Pane(guard) ~= nil
							end))
							if type(startedAt) == "number" then
								t.Near("held to its Drop (s from the raise's start)", untilAt - startedAt, raise.Beats.Drop, 0.05)
							end
						end
						waitFor(t, raise.Beats.Drop + 1, function(): boolean
							return now() >= untilAt + 0.15
						end)
						if first then
							t.Check("its pane goes at Drop", SlamController.Pane(guard) == nil)
						end
						first = false
						if glanced > 0 then
							break
						end
					end
					t.Check("the lead's hits glance off it while it's raised", glanced > 0, `{glanced} glanced, {whole} whole`)
					-- The break: the lead's signature into a raise, Auto on and its ring made full as the raise goes up.
					local broken = false
					local signature = FightRule.Signature(Actions.KitOf(tostring(lead:GetAttribute("Def"))))
					Net.Client.Invoke("Signature", "Auto", true)
					for _ = 1, RAISES do
						if not waitFor(t, raise.Cooldown + 2, raised) then
							break
						end
						local before = guard:GetAttribute("GuardBroke")
						t.Server("LeadReady")
						broken = waitFor(t, raise.Beats.Drop, function(): boolean
							local now = guard:GetAttribute("GuardBroke")
							return now ~= nil and now ~= before
						end)
						if broken then
							break
						end
					end
					t.Check("the lead's signature breaks it open", broken, if signature then signature.Id else "no signature")
					if broken then
						t.Check("its pane goes at once", waitFor(t, 0.3, function(): boolean
							return SlamController.Pane(guard) == nil
						end))
						t.Check("the breaking hit lands whole", waitFor(t, 0.5, function(): boolean
							return broke >= 1
						end))
						local stunned = waitFor(t, 0.5, function(): boolean
							return guard:GetAttribute("State") == "Stun"
						end)
						t.Check("staggered: it stands stunned", stunned)
						if stunned then
							local from = os.clock()
							waitFor(t, 4, function(): boolean
								return guard:GetAttribute("State") ~= "Stun"
							end)
							-- its Stagger, or the signature's own stun when that's longer
							local most = Combat.Guard.Stagger
							for _, hit in (if signature then signature.Hits else {}) :: { [string]: Actions.Hit } do
								most = math.max(most, hit.Stun or 0)
							end
							local took = os.clock() - from
							t.Check("for its Stagger", took >= Combat.Guard.Stagger - 0.3 and took <= most + 0.3, string.format("%.2f s (%.2f to %.2f)", took, Combat.Guard.Stagger, most))
						end
					end
				end)
				onHit:Disconnect()
				Net.Client.Invoke("Signature", "Auto", auto)
				t.Server("FightSpawn")
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Shades (AR52): the Dasher's line goes down through the lead and fills to its end on the hit; under A, staying it hits and runs on through, walking off it hits empty stone; each counted",
			Run = function(t: any)
				local was = t.Server("Slam").Mode
				t.Server("Slam", "A")
				t.Server("Slam", "Reset")
				local lead, foe = begin(t, "dasher")
				if lead == nil or foe == nil then
					t.Server("FightSpawn")
					t.Server("Slam", was)
					return
				end
				local dasher = foe :: Model
				local lunge = Actions.ById.DasherLunge
				local move = (lunge.Moves :: any).Lunge :: Actions.Move
				local line = Combat.Dasher.Line
				local struck = 0
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) == "table" and hit.A == dasher and hit.T == lead and hit.Action == lunge.Id then
						struck += 1
					end
				end)
				-- One lunge: made ready, its line read as it goes down; `during` runs each frame of its tell.
				local function one(during: (() -> ())?): { [string]: any }?
					-- the lead standing in its fight first, as the Dasher's own First waits for (a lead still walking in
					-- circles to its place and steps off a line by itself)
					t.Check("the lead is in its fight", waitFor(t, SHADE_TIMEOUT, function(): boolean
						local acting = lead:GetAttribute("Action")
						return type(acting) == "string" and acting ~= ""
					end))
					t.Server("Slam", "Ready")
					local down = waitFor(t, LUNGE_SOON, function(): boolean
						return dasher:GetAttribute("MarkSlam") ~= nil
					end)
					if not down then
						return nil
					end
					local at, to = dasher:GetAttribute("MarkAt"), dasher:GetAttribute("MarkTo")
					local read: any = {
						At = at,
						To = to,
						Radius = dasher:GetAttribute("MarkRadius"),
						Down = dasher:GetAttribute("MarkDown"),
						Slam = dasher:GetAttribute("MarkSlam"),
						From = dasher:GetPivot().Position,
						Half = -1,
						Before = struck,
					}
					if typeof(at) ~= "Vector3" or typeof(to) ~= "Vector3" then
						return read
					end
					local way = flat(to - at)
					read.Length = way.Magnitude
					read.Shape = { X = at.X, Z = at.Z, Radius = read.Radius, Length = read.Length, DirX = way.Unit.X, DirZ = way.Unit.Z }
					local leadAt = lead:GetPivot().Position
					read.LeadOn = MarkRule.Covers(read.Shape, leadAt.X, leadAt.Z)
					read.Edges, read.Fill = SlamController.Line(dasher)
					local avatarFrom = Parts.Root(player.Character)
					local avatarAt = if avatarFrom then avatarFrom.Position else Vector3.zero
					while now() < read.Slam - 0.05 and dasher:GetAttribute("MarkSlam") ~= nil do
						-- where the lead and the avatar stand as it lands, for the checks and their detail
						local here = lead:GetPivot().Position
						read.OnAtHit = MarkRule.Covers(read.Shape, here.X, here.Z)
						local l = flat(here - at)
						read.Last = string.format(
							"the lead %.1f down, %.1f off; away %s; the avatar moved %.1f",
							l:Dot(way.Unit),
							math.abs(l:Dot(Vector3.new(-way.Unit.Z, 0, way.Unit.X))),
							tostring(lead:GetAttribute("Away")),
							if avatarFrom then flat(avatarFrom.Position - avatarAt).Magnitude else -1
						)
						if read.Half < 0 and now() >= (read.Down + read.Slam) / 2 then
							local _, fill = SlamController.Line(dasher)
							read.Half = if fill then fill.Size.Z else 0
						end
						if during then
							during()
						end
						RunService.Heartbeat:Wait()
					end
					read.Gone = waitFor(t, 1, function(): boolean
						local edges = SlamController.Line(dasher)
						return dasher:GetAttribute("MarkSlam") == nil and edges == nil
					end)
					t.Wait(0.4) -- its glide's end and the server's count
					read.Went = flat(dasher:GetPivot().Position - read.From):Dot(way.Unit)
					read.LeadAlong = flat(lead:GetPivot().Position - at):Dot(way.Unit)
					local look = flat(dasher:GetPivot().LookVector)
					read.LookAfter = if look.Magnitude > 0.01 then look.Unit:Dot(way.Unit) else 0 -- inside its 0.8 s back open
					read.Hits = struck - read.Before
					read.Counts = t.Server("Slam").Counts
					return read
				end
				local ok, err = pcall(function()
					-- Staying: the lead fights on, on the line.
					local stay = one(nil)
					t.Check("its line goes down in the fight", stay ~= nil and typeof(stay.To) == "Vector3")
					if stay and stay.Length then
						t.Near("its tell, Line to Land (s)", stay.Slam - stay.Down, lunge.Beats.Land - lunge.Beats.Line, 0.02)
						t.Near("as long as its lunge and Past (studs)", stay.Length, (move.Most or 0) + line.Past, 0.05)
						t.Near("Half either side (studs)", stay.Radius, line.Half, 0.01)
						local gap = flat(stay.From - stay.At).Magnitude
						t.Check("from the Dasher's feet", gap < 0.75, string.format("%.2f studs off", gap))
						t.Check("through the lead", stay.LeadOn == true)
						t.Check("an outline of three edges, an edge wide", stay.Edges ~= nil and #stay.Edges == 3 and math.abs(stay.Edges[1].Size.X - math.min(line.Edge, line.Half)) < 0.01)
						t.Check("a fill, see-through", stay.Fill ~= nil and math.abs(stay.Fill.Transparency - line.Fill) < 0.01)
						t.Near("halfway through the tell, the fill half the line (studs)", stay.Half, (stay.Length :: number) / 2, 1.2)
						t.Check("all gone with the hit", stay.Gone == true)
						t.Check("staying, the lunge hits the lead", stay.Hits >= 1, `{stay.Hits} hits; at its hit, {stay.Last}`)
						-- on through it, never short of it; a blow of the lead's landing mid-lunge pushes it as any glide is pushed
						t.Check("and runs on through it, its back to the lead", stay.Went > stay.LeadAlong, string.format("went %.1f studs, the lead %.1f down the line", stay.Went, stay.LeadAlong))
						t.Check("its back open: still facing down its line, its back to the lead", stay.LookAfter > 0.9, string.format("its look along the line %.2f", stay.LookAfter))
						t.Row("the lunge's travel through the lead (studs; its Most unless a blow pushed it)", nil, move.Most, stay.Went, "")
						local tally = stay.Counts["Lunge A"]
						t.Check("counted under Lunge A: hit", tally ~= nil and tally.Slams == 1 and tally.Hit == 1, if tally then `{tally.Slams} lunges, {tally.Hit} hit` else "none")
					end
					-- Walking off: the avatar leaves the line, its lead with it.
					local followed, walked = false, false
					local off = one(function()
						local root = Parts.Root(player.Character)
						local humanoid = Parts.Humanoid(player.Character)
						local at, to = dasher:GetAttribute("MarkAt"), dasher:GetAttribute("MarkTo")
						if not walked and root and humanoid and typeof(at) == "Vector3" and typeof(to) == "Vector3" then
							walked = true
							local way = flat(to - at).Unit
							local side = Vector3.new(-way.Z, 0, way.X) -- across the line
							local from = flat(root.Position - at)
							local out = if from:Dot(side) < 0 then -side else side
							humanoid:MoveTo(root.Position + out * WALK)
						end
						if lead:GetAttribute("Away") == true then
							followed = true
						end
					end)
					t.Check("a second line", off ~= nil and typeof(off.To) == "Vector3")
					if off and off.Length then
						t.Check("the lead followed the avatar off the line", followed)
						t.Check("and stood off it at the hit", off.OnAtHit == false, off.Last)
						t.Check("walking off, the lunge misses", off.Hits == 0, `{off.Hits} hits`)
						t.Check("and hits empty stone, its lunge's length down the line", off.Went >= (move.Most or 0) * 0.5, string.format("went %.1f studs", off.Went))
						t.Row("the missed lunge's travel (studs)", nil, nil, off.Went, "")
						local tally = off.Counts["Lunge A"]
						t.Check("counted under Lunge A: missed, on purpose", tally ~= nil and tally.Slams == 2 and tally.Missed == 1 and tally.OnPurpose == 1, if tally then `{tally.Slams} lunges, {tally.Hit} hit, {tally.OnPurpose} on purpose` else "none")
					end
				end)
				onHit:Disconnect()
				t.Server("FightSpawn")
				t.Server("Slam", was)
				if not ok then
					error(err, 0)
				end
			end,
		},
	}
end

return ShadeCases
