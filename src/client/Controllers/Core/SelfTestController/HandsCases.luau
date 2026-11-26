--!strict
-- HandsCases (client): TR69 C, the press (Config.Combat.Hands; Rules.Hands), in a fight. The switch on by a Tune for the
-- case and put back after, as it stays Off until the director picks by playing. A Dasher's lunge called in its tell and
-- missed is a slip: the Dasher stands Open and staggered, wearing its cracked ring; the lead's ring fills Open.Fill of
-- its cooldown, its hold ends, it flashes; then its signature tapped onto the Open Dasher lands as a Finisher, its own
-- row, and the screen's edges flash. Every word stays off the screen but Call's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local SlamController = require(script.Parent.Parent.Parent.Main.SlamController)

local HandsCases = {}

local REPLICATE = 2 -- seconds for an attribute or a remote to reach the client
local LUNGE_SOON = 6 -- seconds a ready Dasher may take to come into range and put its line down
local WALK = 7 -- studs the avatar walks off the line, so the Call's dash and the walk both take the lead off it
local OPEN_TEST = 6 -- seconds the case stands a foe Open: time for the lead to reach a Dasher run on through its line
local FINISH_SOON = 8 -- seconds the tapped signature may take to land on the Open Dasher

local player = Players.LocalPlayer

local function now(): number
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function fighterModel(id: any): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

export type Given = {
	LEAD_SETTLE: number,
	SHADE_AHEAD: number,
	SHADE_TOUGHER: number,
	SHADE_TIMEOUT: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	myLead: () -> Model?,
}

function HandsCases.Cases(given: Given): { any }
	local LEAD_SETTLE, SHADE_AHEAD, SHADE_TOUGHER, SHADE_TIMEOUT = given.LEAD_SETTLE, given.SHADE_AHEAD, given.SHADE_TOUGHER, given.SHADE_TIMEOUT
	local waitFor, myLead = given.waitFor, given.myLead

	return {
		{
			Name = "Hands (TR69 C): Call in the Dasher's tell, the lunge missed, is a slip: the Dasher Open, the lead's ring 30% fuller and back in; its signature on the Open Dasher is a Finisher",
			Run = function(t: any)
				local was = t.Server("Hands").On == true
				local seconds = Combat.Hands.Open.Seconds
				local mode = t.Server("Slam").Mode
				-- the walk off the line is A's only while tap to move is off (Config.Combat.TapMove): off for this case
				local tapWas = Combat.TapMove.On
				t.Server("Tune", "Combat.TapMove.On", false)
				t.Server("Hands", true)
				t.Server("Tune", "Combat.Hands.Open.Seconds", OPEN_TEST)
				t.Server("Slam", "A")
				t.Server("Slam", "Reset")
				local hits: { any } = {}
				local onHit = Net.Client.On("Hit", function(hit: any)
					if type(hit) == "table" then
						table.insert(hits, hit)
					end
				end)
				local ok, err = pcall(function()
					t.Server("LeadHeal")
					t.Server("LeadCalm")
					t.Server("FightSpawn")
					t.Wait(LEAD_SETTLE)
					local lead = myLead()
					if lead == nil then
						t.Check("a lead to fight with", false)
						return
					end
					local level = lead:GetAttribute("Level")
					local spawned = t.Server("FightSpawn", "dasher", (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD, true)
					local dasher: Model? = nil
					waitFor(t, REPLICATE, function(): boolean
						dasher = fighterModel(if type(spawned) == "table" then spawned.Id else nil)
						return dasher ~= nil
					end)
					if dasher == nil then
						t.Check("a Dasher spawns and reaches the client", false)
						return
					end
					local foe = dasher :: Model
					t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, function(): boolean
						local id = lead:GetAttribute("Target")
						return type(id) == "string" and id ~= ""
					end))
					-- Call: in this fight, whatever the mode, by the jump, and its word
					t.Check("Call shows in the fight", waitFor(t, REPLICATE, function(): boolean
						return SlamController.Recall() ~= nil
					end))
					local button = SlamController.Recall()
					local word = if button then button:FindFirstChild("Word", true) else nil
					t.Equal("its word", if word and word:IsA("TextLabel") then word.Text else "none", "Call")
					-- a lunge of its own already going down lands first, so Ready never cuts one short
					waitFor(t, LUNGE_SOON, function(): boolean
						return foe:GetAttribute("MarkSlam") == nil
					end)
					t.Wait(0.6)
					local empty = t.Server("Hands", "Empty") -- the ring empty, so Auto never fires it in the lunge
					t.Check("the lead's ring emptied", type(empty) == "table" and empty.Ok == true)
					local cooldown = if type(empty) == "table" then empty.Cooldown else nil
					t.Server("Slam", "Ready")
					local down = waitFor(t, LUNGE_SOON, function(): boolean
						return foe:GetAttribute("MarkSlam") ~= nil
					end)
					t.Check("the Dasher's line goes down", down)
					if not down then
						return
					end
					-- in its tell: the avatar walks off the line, and Call is pressed
					local at, to = foe:GetAttribute("MarkAt"), foe:GetAttribute("MarkTo")
					local root = Parts.Root(player.Character)
					local humanoid = Parts.Humanoid(player.Character)
					if typeof(at) == "Vector3" and typeof(to) == "Vector3" and root and humanoid then
						local way = flat(to - at).Unit
						local side = Vector3.new(-way.Z, 0, way.X)
						local out = if flat(root.Position - at):Dot(side) < 0 then -side else side
						humanoid:MoveTo(root.Position + out * WALK)
					end
					RunService.Heartbeat:Wait()
					local readyBefore = lead:GetAttribute("Ready")
					local called = SlamController.Press()
					t.Check("Call is taken in the tell", called.Ok == true, tostring(called.Error))
					local before = #hits
					local slipped = waitFor(t, LUNGE_SOON, function(): boolean
						local openUntil = foe:GetAttribute("OpenUntil")
						return type(openUntil) == "number" and openUntil > now()
					end)
					local struck = 0
					for k = before + 1, #hits do
						if hits[k].A == foe and hits[k].T == lead then
							struck += 1
						end
					end
					t.Check("the lunge misses the lead", struck == 0, `{struck} hits`)
					t.Check("a slip: the Dasher stands Open", slipped)
					if not slipped then
						return
					end
					local openUntil = foe:GetAttribute("OpenUntil") :: number
					t.Near("for Open's seconds (s)", openUntil - now(), OPEN_TEST, 0.6)
					t.Check("staggered", waitFor(t, REPLICATE, function(): boolean
						return foe:GetAttribute("State") == "Stun"
					end))
					local bits = SlamController.Cracks(foe)
					t.Check("its cracked ring, Look.Cracks of them, grey", bits ~= nil and #bits == Combat.Hands.Look.Cracks, if bits then `{#bits}` else "none")
					t.Check("the lead's Slipped mark, for its flash", type(lead:GetAttribute("Slipped")) == "number")
					t.Check("its hold ends: back in", waitFor(t, REPLICATE, function(): boolean
						return lead:GetAttribute("Away") == nil
					end))
					local readyAfter = lead:GetAttribute("Ready")
					if type(readyBefore) == "number" and type(readyAfter) == "number" and type(cooldown) == "number" then
						t.Near("its ring Open.Fill of its cooldown fuller (s)", readyBefore - readyAfter, Combat.Hands.Open.Fill * cooldown, 0.15)
					else
						t.Check("its ring's ready times read", false, `{readyBefore} to {readyAfter}`)
					end
					-- the Finisher: the ring full, a tap, the signature onto the Open Dasher
					t.Server("LeadReady")
					local tapped = Net.Client.Invoke("Signature", "Tap")
					t.Check("the signature tapped", type(tapped) == "table" and tapped.Ok == true, if type(tapped) == "table" then tostring(tapped.Error) else "no answer")
					local from = #hits
					local finisher: any = nil
					local edged = false
					waitFor(t, FINISH_SOON, function(): boolean
						for k = from + 1, #hits do
							local hit = hits[k]
							if hit.A == lead and hit.T == foe and hit.Finisher == true then
								finisher = hit
							end
						end
						edged = edged or SlamController.Edge() ~= nil
						return finisher ~= nil and edged
					end)
					t.Check("its signature on the Open Dasher lands as a Finisher", finisher ~= nil)
					if finisher then
						t.Equal("on its own row", finisher.Rung, Combat.Hands.Finisher.Rung)
						t.Check("the screen's edges flash", edged)
						t.Check("the Open used up", waitFor(t, REPLICATE, function(): boolean
							return foe:GetAttribute("OpenUntil") == nil or foe.Parent == nil
						end))
					end
				end)
				onHit:Disconnect()
				t.Server("FightSpawn")
				t.Server("Tune", "Combat.Hands.Open.Seconds", seconds)
				t.Server("Hands", was)
				t.Server("Slam", mode)
				t.Server("Tune", "Combat.TapMove.On", tapWas)
				if not ok then
					error(err, 0)
				end
			end,
		},
	}
end

return HandsCases
