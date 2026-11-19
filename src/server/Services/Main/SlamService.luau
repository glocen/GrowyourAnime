--!strict
-- SlamService (server): the lead's ways out of a keeper's marked slam, and the slams counted (docs/test-requests.md, TR44;
-- Rules.Mark; Config.Combat.Keeper.Out). FightService puts the footprint down and resolves the hit; this hears it.
-- * The switch, Config.Combat.Keeper.Out.Mode, read live: "Off" is today's rule (the lead fights on); "A", while a
--   footprint is down, an avatar that moves Moved studs or more from where it stood at the Plant and stands outside the
--   ring takes its lead with it (FightService.Away, at Combat.Lead.CatchUpSpeed, held until the Slam); "B", a Recall
--   (Net "Recall": the touch button, R, ButtonY, only in a keeper's try) dashes the lead to its place by the avatar.
-- * Each slam aimed at a lead is counted under the mode it was played in: hit or missed, and a miss on purpose (the
--   avatar moved Moved studs, or Recall was pressed, in the tell) or by accident (neither).
-- The player's attribute RecallReady (server time) says when their next Recall is ready, for the button's cooldown.
-- Studio:
--   NL_Debug:Invoke("Slam")                 the mode, and the counts per mode
--   NL_Debug:Invoke("Slam", nil, "A")       the switch on "Off", "A" or "B" for every side (a Tune)
--   NL_Debug:Invoke("Slam", nil, "Reset")   the counts cleared
--   NL_Debug:Invoke("Slam", nil, "Now")     the player's keeper's slam ready now (a test's)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local Enemies = require(Shared.Definitions.Enemies)
local MarkRule = require(Shared.Rules.Mark)
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local TuneService = require(Core.TuneService)
local FightService = require(script.Parent.FightService)

local SlamService = {
	Priority = 46, -- after the fight and the keeper, whose fighters and tries it reads
}

-- A lead under a footprint, watched from its Plant to its Slam.
type Watch = {
	Mark: FightService.Mark,
	Keeper: FightService.Fighter,
	Player: Player,
	Mode: MarkRule.Mode, -- the switch as the footprint went down: the slam is counted under it
	FromX: number, -- where the avatar stood at the Plant
	FromZ: number,
	Moved: number, -- the farthest it has stood from there since
	Recalled: boolean,
	Broke: boolean, -- A: its lead broken off already
}

local watches: { [FightService.Fighter]: Watch } = {} -- by lead
local counts: MarkRule.Counts = {}
local recalled: { [Player]: number } = {} -- each player's last Recall, server time

local function now(): number
	return workspace:GetServerTimeNow()
end

local function mode(): MarkRule.Mode
	return MarkRule.Mode(Combat.Keeper.Out.Mode)
end

-- A footprint down: every lead it was aimed at is watched until it's taken up.
local function marked(keeper: FightService.Fighter, mark: FightService.Mark)
	local lead = mark.Target
	local player = if lead then lead.Owner else nil
	local avatar = if player then Parts.Root(player.Character) else nil
	if lead == nil or player == nil or avatar == nil then
		return
	end
	watches[lead] = {
		Mark = mark,
		Keeper = keeper,
		Player = player,
		Mode = mode(),
		FromX = avatar.Position.X,
		FromZ = avatar.Position.Z,
		Moved = 0,
		Recalled = false,
		Broke = false,
	}
end

-- Taken up: on its hit, each watched lead's slam counted; ended first, nothing.
local function unmarked(_keeper: FightService.Fighter, mark: FightService.Mark, struck: { FightService.Fighter }?)
	for lead, watch in watches do
		if watch.Mark ~= mark then
			continue
		end
		watches[lead] = nil
		if struck == nil then
			continue
		end
		local hit = table.find(struck, lead) ~= nil
		local kind = if hit then nil else MarkRule.Purpose(watch.Moved, watch.Recalled, Combat.Keeper.Out.Moved)
		MarkRule.Count(counts, watch.Mode, hit, kind)
		Log.Info("Slam", `{watch.Player.Name}'s lead, mode {watch.Mode}: {if hit then "hit" else `missed, {kind}`}`)
	end
end

-- Every frame a footprint is down: how far each avatar has gone from its Plant, and A's break-off.
local function step()
	local out = Combat.Keeper.Out
	for lead, watch in watches do
		local avatar = Parts.Root(watch.Player.Character)
		if avatar == nil or watch.Keeper.Mark ~= watch.Mark then
			continue
		end
		local p = avatar.Position
		local dx, dz = p.X - watch.FromX, p.Z - watch.FromZ
		local moved = math.sqrt(dx * dx + dz * dz)
		watch.Moved = math.max(watch.Moved, moved)
		if watch.Mode == "A" and not watch.Broke and mode() == "A" then
			local mark = watch.Mark
			local outside = not MarkRule.Inside(mark.X, mark.Z, mark.Radius, p.X, p.Z)
			if MarkRule.Follows(moved, outside, out.Moved) then
				watch.Broke = FightService.Away(lead, Combat.Lead.CatchUpSpeed, mark.Slam)
			end
		end
	end
end

-- B: a Recall pressed. Its answer says why not, and when the next is ready.
function SlamService.Recall(player: Player): { [string]: any }
	local recall = Combat.Keeper.Out.Recall
	local at = now()
	local ready, from = MarkRule.Ready(recalled[player], at, recall.Cooldown)
	local lead = FightService.LeadOf(player)
	if mode() ~= "B" then
		return { Ok = false, Error = "Off" }
	elseif player:GetAttribute("Try") == nil then
		return { Ok = false, Error = "NoFight" }
	elseif not ready then
		return { Ok = false, Error = "Cooldown", Ready = from }
	elseif lead == nil or not FightService.Standing(lead) then
		return { Ok = false, Error = "NoLead" }
	end
	if not FightService.Away(lead, recall.Speed, nil, recall.Hold, recall.Most) then
		return { Ok = false, Error = "NoLead" }
	end
	recalled[player] = at
	player:SetAttribute("RecallReady", at + recall.Cooldown)
	local watch = watches[lead]
	if watch then
		watch.Recalled = true
	end
	return { Ok = true, Ready = at + recall.Cooldown }
end

-- The player's keeper, in their try, if one stands.
local function keeperOf(player: Player): FightService.Fighter?
	local lead = FightService.LeadOf(player)
	for _, f in FightService.All() do
		if f.Kind == "Keeper" and FightService.Standing(f) and (f.Target == lead or f.For == player) then
			return f
		end
	end
	-- no target yet: the nearest keeper to the avatar
	local avatar = Parts.Root(player.Character)
	local best, nearest = nil, math.huge
	for _, f in FightService.All() do
		if f.Kind == "Keeper" and FightService.Standing(f) and avatar then
			local gap = (f.Root.Position - avatar.Position).Magnitude
			if gap < nearest then
				best, nearest = f, gap
			end
		end
	end
	return best
end

local function command(who: any, what: any): any
	if what == nil then
		return { Mode = mode(), Counts = counts }
	elseif what == "Reset" then
		table.clear(counts)
		return { Mode = mode(), Counts = counts }
	elseif what == "Now" then
		local player = DebugService.ResolvePlayer(who)
		local keeper = if player then keeperOf(player) else nil
		local row = if keeper then Enemies.ById[keeper.Def] else nil
		if keeper == nil or row == nil or row.Signature == nil then
			return { Ok = false, Error = "NoKeeper" }
		end
		keeper.ReadyAt[row.Signature] = 0
		return { Ok = true }
	elseif what == "Off" or what == "A" or what == "B" then
		TuneService.Set("Combat.Keeper.Out.Mode", what)
		return { Mode = mode(), Counts = counts }
	end
	return { Ok = false, Error = "BadArgs" }
end

function SlamService.Start()
	FightService.Marked:Connect(marked)
	FightService.Unmarked:Connect(unmarked)
	RunService.Heartbeat:Connect(step)
	Net.Server.Handle("Recall", function(player: Player): { [string]: any }
		return SlamService.Recall(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		recalled[player] = nil
		for lead, watch in watches do
			if watch.Player == player then
				watches[lead] = nil
			end
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("Slam", command)
	end
end

return SlamService
