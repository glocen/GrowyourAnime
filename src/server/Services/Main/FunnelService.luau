--!strict
-- FunnelService (server): the first session, measured (TR32; Rules.Funnel). Each step of docs/north-star.md's first
-- session the build has is logged once an account to Roblox's onboarding funnel (AnalyticsService), from the server's
-- own record of the act that makes it true, never the client's word:
--   * a committed act or server change (DataService.Changed, with its label): a starter picked, the first Voidkin
--     opened, the first Shade's fall and the Named shard with it, the first worker in a bay, the first item equipped;
--   * the first join (DataService.Ready);
--   * the keeper's gate reached: within the reach its Challenge shows at (Config.Combat.Keeper.Reach), in the place
--     whose world has the gate, looked at every LOOK seconds.
-- The step is marked on the save in its own transaction first, and logged only when that commits, so a repeat, a retried
-- request or a rejoin never logs it again. A step carries its number and name only: no personal data.
-- A join through a reveal's share (TR60, Rules.Capture: the launch data names the sharer) is counted as the custom
-- event "ShareJoin", once a join, without the sharer's id, and never rewarded: Studio doesn't log it.
--   Studio's debug bridge: "Funnel" (who) -> the player's marks and what this server has logged for them;
--   "FunnelSet" (who, marks) -> the marks become exactly the names given and this server's log is cleared, so a test
--   can play a step again and put the account's own marks back.
--   "ShareJoin" (who, launchData) -> whether a join carrying that launch data counts as one through a share (TR60).

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Parts = require(Shared.Util.Parts)
local Markers = require(Shared.World.Markers)
local Profile = require(Shared.Data.Profile)
local Combat = require(Shared.Config.Combat)
local Funnel = require(Shared.Rules.Funnel)
local Capture = require(Shared.Rules.Capture)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local FunnelService = {
	Priority = 20, -- after DataService
}

local LOOK = 1 -- seconds between looks at who stands at the keeper's gate

local logged: { [Player]: { string } } = {} -- Studio only: what this server logged, for tests

local function log(player: Player, steps: { Funnel.Logged })
	for _, step in steps do
		local ok, problem = pcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, step.Step, step.Name)
		end)
		if not ok then
			Log.Warn("FunnelService", `step {step.Step} ({step.Name}) not logged:`, problem)
		end
		if RunService:IsStudio() then
			local list = logged[player] or {}
			table.insert(list, `{step.Step} {step.Name}`)
			logged[player] = list
		end
	end
end

-- Marks the steps not yet marked, then logs them once the mark has committed.
local function mark(player: Player, steps: { string })
	local data = DataService.Get(player)
	if data == nil or player.Parent == nil then
		return
	end
	local fresh = false
	for _, name in steps do
		if data.Funnel[name] ~= true then
			fresh = true
			break
		end
	end
	if not fresh then
		return
	end
	local answer = DataService.Change(player, "Funnel", function(draft: Profile.Data): any
		return Funnel.Mark(draft, steps)
	end)
	if answer.Ok == true then
		log(player, answer.Logged :: { Funnel.Logged })
	end
end

-- A join through a reveal's share (TR60): counted once a join, never rewarded. Whether it counted.
local function shareJoin(player: Player, launch: any): boolean
	if Capture.Sharer(launch, player.UserId) == nil then
		return false
	end
	if RunService:IsStudio() then
		local list = logged[player] or {}
		table.insert(list, "ShareJoin")
		logged[player] = list
	else
		local ok, problem = pcall(function()
			AnalyticsService:LogCustomEvent(player, "ShareJoin", 1)
		end)
		if not ok then
			Log.Warn("FunnelService", "a join through a share wasn't logged:", problem)
		end
	end
	return true
end

local function joined(player: Player)
	local ok, data = pcall(function(): any
		return player:GetJoinData()
	end)
	if ok and type(data) == "table" then
		shareJoin(player, data.LaunchData)
	end
end

-- Who stands within the Challenge's reach of the keeper's gate, in the place that has one.
local function look()
	local gate = Markers.Find("KeeperGate")
	if gate == nil then
		return
	end
	local at = Markers.At(gate).Position
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		local root = Parts.Root(player.Character)
		if data and data.Funnel.Want ~= true and root and (root.Position - at).Magnitude <= Combat.Keeper.Reach then
			task.spawn(mark, player, { "Want" })
		end
	end
end

function FunnelService.Start()
	DataService.Ready:Connect(function(player: Player)
		task.defer(mark, player, { "Arrive" })
	end)
	DataService.Changed:Connect(function(player: Player, _data: Profile.Data, answer: any, label: string?)
		local steps = Funnel.Of(label or "", answer)
		if #steps > 0 then
			task.defer(mark, player, steps) -- after the act's own change has finished telling its listeners
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		logged[player] = nil
	end)
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do
		task.spawn(joined, player)
	end
	task.spawn(function()
		while true do
			look()
			task.wait(LOOK)
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("Funnel", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			local data = if player then DataService.Get(player) else nil
			if player == nil or data == nil then
				return { Ok = false, Error = "BadArgs" }
			end
			local marks = {}
			for _, name in Funnel.Steps do
				if data.Funnel[name] == true then
					table.insert(marks, name)
				end
			end
			return { Ok = true, Marks = marks, Logged = table.clone(logged[player] or {}) }
		end)
		DebugService.Register("ShareJoin", function(who: any, launch: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil then
				return { Ok = false, Error = "BadArgs" }
			end
			return { Ok = true, Counted = shareJoin(player, launch), Logged = table.clone(logged[player] or {}) }
		end)
		DebugService.Register("FunnelSet", function(who: any, marks: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil or type(marks) ~= "table" then
				return { Ok = false, Error = "BadArgs" }
			end
			for _, name in marks do
				if Funnel.Number[name] == nil then
					return { Ok = false, Error = "BadArgs" }
				end
			end
			logged[player] = nil
			return DataService.Change(player, "FunnelSet", function(draft: Profile.Data): any
				draft.Funnel = {}
				for _, name in marks do
					draft.Funnel[name] = true
				end
				return { Ok = true }
			end)
		end)
	end
end

return FunnelService
