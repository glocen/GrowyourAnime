--!strict
-- SlamService (server): the lead's ways out of a keeper's marked slam, and the slams counted (docs/test-requests.md, TR44;
-- Rules.Mark; Config.Combat.Keeper.Out). FightService puts the footprint down and resolves the hit; this hears it.
-- * The switch, Config.Combat.Keeper.Out.Mode, read live: "Off" is today's rule (the lead fights on); "A", while a
--   footprint is down, an avatar that moves Moved studs or more from where it stood at the Plant and stands outside the
--   ring takes its lead with it (FightService.Away, at Combat.Lead.CatchUpSpeed, held until the Slam); "B", a Recall
--   (Net "Recall": the touch button, R, ButtonY, only in a keeper's try) dashes the lead to its place by the avatar.
-- * Each slam aimed at a lead is counted under the mode it was played in: hit or missed, and a miss on purpose (the
--   avatar moved Moved studs, or Recall was pressed, in the tell) or by accident (neither).
-- * A Dasher's line (AR52) is a footprint too: the same switch and the same way out, its outside the line's, and its
--   lunges counted apart, under "Lunge A" (or B, or Off). B's Recall shows only in a keeper's try, so on the Row a line
--   under B is left by walking alone until the director's pick says otherwise.
-- * The keeper's hazards (TR69 D; KeeperPhaseService: its pools, its double slam's second, its sweep) are footprints too,
--   each watched on its own, so several may be down on one lead: only for a lead under it at its Plant, and A breaks the
--   lead off only while it's still under it, held until its Slam (a sweep's, until its line has turned). Counted under
--   their kind ("Pool A", "Second A", "Sweep A").
-- The player's attribute RecallReady (server time) says when their next Recall is ready, for the button's cooldown.
-- * TR69 C, the press (Config.Combat.Hands, Off by default; Rules.Hands): on, the Recall is Call, in every fight but the
--   Tower's (the lead has a target, or a blow landed within Hands.Linger), whatever the mode. A Call in a marked strike's
--   tell that the strike then misses is a slip: FightService.Open stands the attacker Open. Each Call and each miss, on
--   purpose or by accident, goes into the fight's read-out (FightService.Note).
-- Studio:
--   NL_Debug:Invoke("Slam")                 the mode, and the counts per mode
--   NL_Debug:Invoke("Slam", nil, "A")       the switch on "Off", "A" or "B" for every side (a Tune)
--   NL_Debug:Invoke("Slam", nil, "Reset")   the counts cleared
--   NL_Debug:Invoke("Slam", nil, "Now")     the player's keeper's slam ready now (a test's)
--   NL_Debug:Invoke("Slam", nil, "Ready")   every foe on the player's lead with a signature, its signature ready now
--                                            (AR52's cases: a Guard's raise, a Dasher's lunge)
--   NL_Debug:Invoke("Hands")                the switch, and the player's fights' read-out (TR69 C)
--   NL_Debug:Invoke("Hands", nil, true)     the switch on (or false: off) for every side (a Tune)
--   NL_Debug:Invoke("Hands", nil, "Open")   every foe on the player's lead Open now, as a slip leaves it (a test's)
--   NL_Debug:Invoke("Hands", nil, "Empty")  the lead's signature ring empty now: { Ready, Cooldown } (a test's)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local Enemies = require(Shared.Definitions.Enemies)
local MarkRule = require(Shared.Rules.Mark)
local Hands = require(Shared.Rules.Hands)
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
	Lead: FightService.Fighter,
	Player: Player,
	Mode: MarkRule.Mode, -- the switch as the footprint went down: the slam is counted under it
	Key: string, -- what it's counted under: its mode, a lunge's after "Lunge " (AR52), a hazard's after its kind (TR69 D)
	FromX: number, -- where the avatar stood at the Plant
	FromZ: number,
	Moved: number, -- the farthest it has stood from there since
	Recalled: boolean,
	Broke: boolean, -- A: its lead broken off already
}

local watches: { [FightService.Mark]: Watch } = {} -- by footprint: a lead may be under several (TR69 D)
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
	local p = lead.Root.Position
	if mark.Every then
		return -- a burn lies where a slam already landed: nothing to walk out of in a tell
	end
	if mark.Kind and not MarkRule.Covers(mark, p.X, p.Z) then
		return -- a hazard put down where the lead isn't asks nothing of it
	end
	watches[mark] = {
		Mark = mark,
		Keeper = keeper,
		Lead = lead,
		Player = player,
		Mode = mode(),
		Key = if mark.Kind then `{mark.Kind} {mode()}` elseif mark.Length then `Lunge {mode()}` else mode(),
		FromX = avatar.Position.X,
		FromZ = avatar.Position.Z,
		Moved = 0,
		Recalled = false,
		Broke = false,
	}
end

-- Taken up: on its hit, each watched lead's slam counted; ended first, nothing.
local function unmarked(_keeper: FightService.Fighter, mark: FightService.Mark, struck: { FightService.Fighter }?)
	local watch = watches[mark]
	if watch then
		watches[mark] = nil
		local lead = watch.Lead
		if struck == nil then
			return
		end
		local hit = table.find(struck, lead) ~= nil
		local kind = if hit then nil else MarkRule.Purpose(watch.Moved, watch.Recalled, Combat.Keeper.Out.Moved)
		MarkRule.Count(counts, watch.Key, hit, kind)
		if kind then
			FightService.Note(watch.Player, kind, 1)
		end
		local slip = Combat.Hands.On and Hands.Slip(hit, watch.Recalled)
		if slip then
			FightService.Open(watch.Keeper, lead)
		end
		Log.Info("Slam", `{watch.Player.Name}'s lead, {watch.Key}: {if hit then "hit" else `missed, {kind}`}{if slip then ", a slip" else ""}`)
	end
end

-- Every frame a footprint is down: how far each avatar has gone from its Plant, and A's break-off.
local function step()
	local out = Combat.Keeper.Out
	for mark, watch in watches do
		local avatar = Parts.Root(watch.Player.Character)
		if avatar == nil or mark.Up or (mark.Kind == nil and watch.Keeper.Mark ~= mark) then
			continue
		end
		local lead = watch.Lead
		local p = avatar.Position
		local dx, dz = p.X - watch.FromX, p.Z - watch.FromZ
		local moved = math.sqrt(dx * dx + dz * dz)
		watch.Moved = math.max(watch.Moved, moved)
		if watch.Mode == "A" and not watch.Broke and mode() == "A" then
			local outside = not MarkRule.Covers(mark, p.X, p.Z)
			local l = lead.Root.Position
			local under = mark.Kind == nil or MarkRule.Covers(mark, l.X, l.Z)
			if under and MarkRule.Follows(moved, outside, out.Moved) then
				watch.Broke = FightService.Away(lead, Combat.Lead.CatchUpSpeed, mark.Slam + (mark.Turn or 0) * (if mark.Back then 2 else 1))
			end
		end
	end
end

-- Whether `player` is in a fight, for Call (TR69 C): their lead has a target, or a blow landed within Hands.Linger.
local function fighting(player: Player, lead: FightService.Fighter?, at: number): boolean
	local blow = player:GetAttribute("HitAt")
	return (lead ~= nil and lead.Target ~= nil) or (type(blow) == "number" and at - blow < Combat.Hands.Linger)
end

-- B: a Recall pressed, or with hands on, Call (TR69 C). Its answer says why not, and when the next is ready.
function SlamService.Recall(player: Player): { [string]: any }
	local recall = Combat.Keeper.Out.Recall
	local at = now()
	local ready, from = MarkRule.Ready(recalled[player], at, recall.Cooldown)
	local lead = FightService.LeadOf(player)
	local hands = Combat.Hands.On
	local tower = player:GetAttribute("Tower") ~= nil
	if not Hands.Calls(hands, mode(), player:GetAttribute("Try") ~= nil, fighting(player, lead, at), tower) then
		if hands then
			return { Ok = false, Error = if tower then "Tower" else "NoFight" }
		end
		return { Ok = false, Error = if mode() ~= "B" then "Off" else "NoFight" }
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
	FightService.Note(player, "Calls", 1)
	for _, watch in watches do
		if watch.Lead == lead then
			watch.Recalled = true
		end
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
	elseif what == "Ready" then
		local player = DebugService.ResolvePlayer(who)
		local lead = if player then FightService.LeadOf(player) else nil
		local readied = {}
		for _, f in FightService.All() do
			local row = Enemies.ById[f.Def]
			if lead and f.Target == lead and FightService.Standing(f) and row and row.Signature then
				f.ReadyAt[row.Signature] = 0
				table.insert(readied, f.Id)
			end
		end
		return { Ok = #readied > 0, Error = if #readied > 0 then nil else "NoFoe", Ready = readied }
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
		for mark, watch in watches do
			if watch.Player == player then
				watches[mark] = nil
			end
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("Slam", command)
		DebugService.Register("Hands", function(who: any, what: any): any
			local player = DebugService.ResolvePlayer(who)
			if what == "Open" then
				local lead = if player then FightService.LeadOf(player) else nil
				local opened = {}
				for _, f in FightService.All() do
					if lead and f.Target == lead and FightService.Standing(f) then
						FightService.Open(f, lead)
						table.insert(opened, f.Id)
					end
				end
				return { Ok = #opened > 0, Error = if #opened > 0 then nil else "NoFoe", Open = opened }
			elseif what == "Empty" then
				local lead = if player then FightService.LeadOf(player) else nil
				local readyAt, cooldown = nil, nil
				if lead then
					readyAt, cooldown = FightService.Ring(lead, 0)
				end
				return { Ok = readyAt ~= nil, Error = if readyAt then nil else "NoLead", Ready = readyAt, Cooldown = cooldown }
			elseif type(what) == "boolean" then
				TuneService.Set("Combat.Hands.On", what)
			elseif what ~= nil then
				return { Ok = false, Error = "BadArgs" }
			end
			return { Ok = true, On = Combat.Hands.On, Readout = if player then FightService.Readout(player) else nil }
		end)
	end
end

return SlamService
