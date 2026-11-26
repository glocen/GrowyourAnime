--!strict
-- PaceCases (client, Studio only): the street's pace, measured (TR69 B, "Measure before and after"). One clean Normal run
-- from StageBegin at the first stretch: the avatar walks to the nearest standing Shade of its stretch (its elite once
-- the quota is met) and the lead is left to fight, never healed. Every tenth of a second counts as fighting (the lead
-- has a target), walking (the avatar moving, no target) or standing (neither), until the run reaches the keeper's
-- stage. Manual: a measure, never in every check. Its gate, under Gate seconds standing in the whole run, is the
-- waves' (block B): before they land it reads a miss. The record is put back after.

local Players = game:GetService("Players")

local Helpers = require(script.Parent.Helpers)

local PaceCases = {}

local TICK = 0.1
local NEAR = 18 -- studs from a Shade the avatar stops at: inside the lead's leash (Config.Combat.Lead.Leash)
local MOVING = 2 -- studs a second over which the avatar counts as walking
local STRETCH = 420 -- seconds a stretch may take before the measure gives up on it
local GATE = 20 -- seconds standing in the whole run (TR69 B's gate)
local KEEPER = 4 -- the keeper's stage: the measure ends as the run reaches it

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

local function standing(model: Model): boolean
	local state = model:GetAttribute("State")
	return state ~= "Down" and state ~= "Reset" and state ~= "Home"
end

-- The nearest standing Shade of `stage` to `from`: its pack's while the quota is owed, its elite's after.
local function nearest(stage: number, elite: boolean, from: Vector3): Model?
	local best: Model?, gap = nil, math.huge
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		local def = model:GetAttribute("Def")
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Stage") == stage and standing(model)
			and type(def) == "string" and (string.find(def, "_elite", 1, true) ~= nil) == elite then
			local d = (model:GetPivot().Position - from).Magnitude
			if d < gap then
				best, gap = model, d
			end
		end
	end
	return best
end

local function stageOf(run: any): number?
	return if type(run) == "string" then tonumber(string.match(run, "(%d+)$")) else nil
end

function PaceCases.Cases(): { any }
	return {
		{
			Name = "Pace (TR69 B): one clean Normal run, each stretch's seconds fighting, walking and standing",
			Manual = true,
			Run = function(t: any)
				local player = Players.LocalPlayer
				local before = t.Server("Stage")
				local normal = if type(before) == "table" then before.Normal else nil
				local cleared = if type(normal) == "table" and type(normal.Cleared) == "number" then normal.Cleared else nil
				local checkpoint = if type(before) == "table" and type(before.Checkpoint) == "table" then before.Checkpoint.Normal else nil
				Helpers.endRun(t)
				t.Server("LeadHeal")
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				t.Row(`the lead's level`, nil, nil, if type(level) == "number" then level else nil, "")
				local began = t.Server("StageBegin", "Normal", 1)
				t.Check("the run begins at the first stretch", type(began) == "table" and began.Ok == true, if type(began) == "table" then tostring(began.Error) else "")
				local ok, problem = pcall(function()
					t.Check("the run is up", Helpers.waitFor(t, 3, function(): boolean
						return stageOf(player:GetAttribute("StageRun")) == 1
					end))
					local seconds: { [number]: { Fight: number, Walk: number, Stand: number } } = {}
					local total = { Fight = 0, Walk = 0, Stand = 0 }
					local stage = 1
					local since = os.clock()
					local moved = 0
					while true do
						local now = stageOf(player:GetAttribute("StageRun"))
						if now == nil then
							t.Check("the run lasts to the keeper's stage", false, `it ended in stretch {stage}`)
							break
						elseif now ~= stage then
							stage, since = now, os.clock()
						end
						if stage >= KEEPER then
							break
						elseif os.clock() - since > STRETCH then
							t.Check(`stretch {stage} within {STRETCH} s`, false, `{player:GetAttribute("StageKills")} of {player:GetAttribute("StageQuota")}`)
							break
						end
						local row = seconds[stage] or { Fight = 0, Walk = 0, Stand = 0 }
						seconds[stage] = row
						local root = t.Root() :: BasePart?
						local character = t.Character() :: Model?
						local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
						local mine = myLead()
						local target = if mine then mine:GetAttribute("Target") else nil
						local kills, quota = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota")
						local owed = type(kills) == "number" and type(quota) == "number" and kills < quota
						if root and humanoid then
							local foe = nearest(stage, not owed, root.Position)
							if foe and (foe:GetPivot().Position - root.Position).Magnitude > NEAR and os.clock() - moved > 0.5 then
								humanoid:MoveTo(foe:GetPivot().Position)
								moved = os.clock()
							elseif foe == nil or (foe:GetPivot().Position - root.Position).Magnitude <= NEAR then
								humanoid:MoveTo(root.Position)
							end
						end
						local speed = if root then (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude else 0
						local kind = if type(target) == "string" and target ~= "" then "Fight" elseif speed > MOVING then "Walk" else "Stand"
						if kind == "Fight" then
							row.Fight += TICK
							total.Fight += TICK
						elseif kind == "Walk" then
							row.Walk += TICK
							total.Walk += TICK
						else
							row.Stand += TICK
							total.Stand += TICK
						end
						t.Wait(TICK)
					end
					for n = 1, KEEPER - 1 do
						local row = seconds[n]
						if row then
							t.Row(`stretch {n}: fighting`, nil, nil, row.Fight, "s")
							t.Row(`stretch {n}: walking`, nil, nil, row.Walk, "s")
							t.Row(`stretch {n}: standing`, nil, nil, row.Stand, "s")
						end
					end
					t.Row("the run: fighting", nil, nil, total.Fight, "s")
					t.Row("the run: walking", nil, nil, total.Walk, "s")
					t.Row(`the run: standing (the waves' gate, under {GATE} s)`, 0, GATE, total.Stand, "s")
				end)
				local character = t.Character() :: Model?
				local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
				local root = t.Root() :: BasePart?
				if humanoid and root then
					humanoid:MoveTo(root.Position)
				end
				Helpers.endRun(t)
				if cleared ~= nil then
					t.Server("StageLine", "Normal", cleared, checkpoint)
				end
				t.Server("LeadHeal")
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
	}
end

return PaceCases
