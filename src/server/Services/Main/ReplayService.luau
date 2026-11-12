--!strict
-- ReplayService (server, Studio only): the replay (the ga-action skill): one action pressed again and again on a clean pad,
-- against a dummy, seen from the player's camera, with every number live through Tune.
--   NL_Debug:Invoke("Replay", who, "RookHaymaker")      every Config.Combat.Replay.Every seconds
--   NL_Debug:Invoke("Replay", who, "RookCombo", 2)      every 2 seconds
--   NL_Debug:Invoke("Replay", who)                      stops, and puts the player and the lead back
-- Two more Studio tools for fights, for tests and play checks:
--   NL_Debug:Invoke("FightSpawn", who, "brawler", 3, 12)   a level 3 brawler 12 studs ahead of the avatar, on its ground
--   NL_Debug:Invoke("FightSpawn", who)                      removes every Shade it spawned
--   NL_Debug:Invoke("Fighters")                             every fighter: kind, state, health, target, action, place
-- The lead stands at the pad's middle, the dummy ahead of it at the action's own spacing (Config.Combat.Replay.Distance),
-- the avatar Replay.Behind behind, all facing down the pad, and the client puts the camera behind the avatar. Each press
-- starts with the dummy back on its spot (FightService.Force). The dummy has the lead's level, so the numbers read true.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Combat = require(Shared.Config.Combat)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)

local PAD_NAME = "NL_ReplayPad"
local CENTER = Vector3.new(0, 2500, 0) -- far above any map, and apart from the self-test's pad
local SIZE = Vector3.new(160, 4, 160)
local FLOOR = Color3.fromRGB(88, 90, 96) -- a mid grey, so both greys of a stand-in read on it
local STAND = 3 -- an R6 root stands 3 studs over the floor
local GROUND_RAY = 50 -- studs under the spot searched for its ground

local ReplayService = {}

type Session = { Dummy: FightService.Fighter?, Back: CFrame?, LeadBack: CFrame? }
local sessions: { [Player]: Session } = {}

local function pad(): Instance
	local found = workspace:FindFirstChild(PAD_NAME)
	if found then
		return found
	end
	local floor = Instance.new("Part")
	floor.Name = PAD_NAME
	floor.Anchored = true
	floor.Size = SIZE
	floor.Position = CENTER
	floor.Color = FLOOR
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	return floor
end

local function stopFor(player: Player)
	local session = sessions[player]
	if session == nil then
		return
	end
	sessions[player] = nil
	local lead = FightService.LeadOf(player)
	if lead then
		FightService.Force(lead, nil)
		if session.LeadBack then
			lead.Root.CFrame = session.LeadBack
		end
	end
	if session.Dummy then
		FightService.Remove(session.Dummy)
	end
	local root = Parts.Root(player.Character)
	if root and session.Back then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = session.Back
	end
	player:SetAttribute("Replay", "")
	if next(sessions) == nil then
		local found = workspace:FindFirstChild(PAD_NAME)
		if found then
			found:Destroy()
		end
	end
end

local function replay(who: any, actionId: any, every: any): any
	local player = DebugService.ResolvePlayer(who)
	if player == nil then
		return { Ok = false, Error = "NoPlayer" }
	end
	if actionId == nil then
		stopFor(player)
		return { Ok = true, Stopped = true }
	end
	local action = if type(actionId) == "string" then Actions.ById[actionId] else nil
	local seconds = if every == nil then Combat.Replay.Every else every
	if action == nil or type(seconds) ~= "number" or not (seconds > 0) then
		return { Ok = false, Error = "BadArgs" }
	end
	local lead = FightService.LeadOf(player)
	local root = Parts.Root(player.Character)
	if lead == nil or root == nil then
		return { Ok = false, Error = "NoLead" }
	end
	local session: Session = sessions[player] or { Dummy = nil, Back = root.CFrame, LeadBack = lead.Root.CFrame }
	sessions[player] = session
	pad()
	local top = CENTER.Y + SIZE.Y / 2
	local spot = Vector3.new(CENTER.X, top + STAND, CENTER.Z)
	local ahead = Vector3.new(0, 0, -1)
	if session.Dummy then
		FightService.Remove(session.Dummy)
	end
	local gap = if Combat.Replay.Distance > 0 then Combat.Replay.Distance else action.Range - Combat.Approach
	local dummyAt = Vector3.new(spot.X, top, spot.Z) + ahead * gap
	session.Dummy = FightService.SpawnEnemy("dummy", lead.Block.Level, CFrame.lookAt(dummyAt, dummyAt - ahead))
	player:RequestStreamAroundAsync(spot)
	lead.Root.AssemblyLinearVelocity = Vector3.zero
	lead.Root.CFrame = CFrame.lookAt(spot, spot + ahead)
	root.AssemblyLinearVelocity = Vector3.zero
	local left = Vector3.new(-1, 0, 0) -- ahead is -Z, so left is -X: in play the lead stands to the avatar's right
	local stand = spot - ahead * Combat.Replay.Behind + left * Combat.Lead.Side
	root.CFrame = CFrame.lookAt(stand, stand + ahead)
	FightService.Force(lead, action.Id, seconds, session.Dummy)
	player:SetAttribute("Replay", `{action.Id}@{workspace:GetServerTimeNow()}`)
	return { Ok = true, Action = action.Id, Every = seconds, Level = lead.Block.Level }
end

local spawned: { [FightService.Fighter]: boolean } = {}

local function fightSpawn(who: any, def: any, level: any, ahead: any): any
	if def == nil then
		local count = 0
		for f in spawned do
			FightService.Remove(f)
			count += 1
		end
		table.clear(spawned)
		return { Ok = true, Removed = count }
	end
	local player = DebugService.ResolvePlayer(who)
	local root = if player then Parts.Root(player.Character) else nil
	local lvl = if level == nil then 1 else level
	local studs = if ahead == nil then 12 else ahead
	if root == nil or type(def) ~= "string" or Enemies.ById[def] == nil or type(lvl) ~= "number" or type(studs) ~= "number" then
		return { Ok = false, Error = "BadArgs" }
	end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local spot = root.Position + look * studs
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Fighters") or workspace.Terrain, (player :: Player).Character :: Model }
	local hit = workspace:Raycast(spot, Vector3.new(0, -GROUND_RAY, 0), params)
	local ground = if hit then hit.Position else spot - Vector3.new(0, STAND, 0)
	local f = FightService.SpawnEnemy(def, lvl, CFrame.lookAt(ground, ground - look))
	spawned[f] = true
	f.Model.Destroying:Connect(function()
		spawned[f] = nil
	end)
	return { Ok = true, Id = f.Id, Health = f.Health }
end

local function fighters(): any
	local list: { { [string]: any } } = {}
	for id, f in FightService.All() do
		local p = f.Root.Position
		local row: { [string]: any } = {
			Id = id,
			Kind = f.Kind,
			Def = f.Model:GetAttribute("Def"),
			State = f.State,
			Health = f.Health,
			MaxHealth = f.Block.Health,
			Target = if f.Target then f.Target.Id else "",
			Action = if f.Action then f.Action.Id else "",
			At = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z),
		}
		table.insert(list, row)
	end
	table.sort(list, function(a, b)
		return (a.Id :: string) < (b.Id :: string)
	end)
	return list
end

function ReplayService.Start()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("Replay", replay)
	DebugService.Register("FightSpawn", fightSpawn)
	DebugService.Register("Fighters", fighters)
	Players.PlayerRemoving:Connect(stopFor)
end

return ReplayService
