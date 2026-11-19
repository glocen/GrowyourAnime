--!strict
-- ReplayService (server, Studio only): the replay (the ga-action skill): one action pressed again and again on a clean pad,
-- against a dummy, seen from the player's camera, with every number live through Tune.
--   NL_Debug:Invoke("Replay", who, "RookHaymaker")      every Config.Combat.Replay.Every seconds
--   NL_Debug:Invoke("Replay", who, "RookCombo", 2)      every 2 seconds
--   NL_Debug:Invoke("Replay", who, "WattGroundWire", 6, "brawler")   against a brawler in place of the dummy, swinging
--                                                       on the lead's clock (Config.Combat.Replay.Short)
--   NL_Debug:Invoke("Replay", who)                      stops, and puts the player and the lead back
-- More Studio tools for fights, for tests and play checks:
--   NL_Debug:Invoke("FightSpawn", who, "brawler", 3, 12)   a level 3 brawler 12 studs ahead of the avatar, on its ground
--   NL_Debug:Invoke("FightSpawn", who, "brawler", 3, 12, nil, "Hard")   the same on Hard: its Hard look (AR46)
--   NL_Debug:Invoke("FightSpawn", who)                      removes every Shade it spawned
--   NL_Debug:Invoke("FightDefeat", who, id)                 one of those falls at once, its fall seen whole
--   NL_Debug:Invoke("Fighters")                             every fighter: kind, state, health, target, action, place
--   NL_Debug:Invoke("FightHealth", who, 0.5)                the player's lead at half its health, to see a heal; 0 downs it
--   NL_Debug:Invoke("FoeHealth", who, id, 0.5)             a spawned Shade at half its health, to see its card (AR45)
--   NL_Debug:Invoke("FightHealth", who, 0.05, true)         at most that share: lowered to it, never raised (a take's held fall)
-- Staged as the game frames a fight (FightService's slot, Rules/Fight.Beyond): the dummy at the pad's middle, the avatar
-- Replay.Behind behind it and Lead.Side to the left, so its own body hides neither, all facing down the pad; the lead
-- beyond the dummy at the action's own spacing (Replay.Distance), turned Lead.Frame degrees toward the avatar's right,
-- the side it walks in from, facing the dummy. The client puts the camera behind the avatar. Each press starts with the
-- dummy back on its spot and whole (FightService.Force). The dummy has the lead's level, so the numbers read true.
-- A foe in its place (AR11's retake: "a brawler stopped mid-swing replaces the dummy, so the lock is the payoff") stands
-- on the same spot at the same level and presses its own action at the lead on the lead's clock (FightService.Follow):
-- timed so its blow would land Replay.Short seconds after the lead's first hit, so a stop meets it mid-swing.

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

-- The first beat an action hits on, in seconds from its press.
local function firstHit(action: Actions.Action): number?
	local first: number? = nil
	for beat in action.Hits do
		local at = action.Beats[beat]
		if at and (first == nil or at < first) then
			first = at
		end
	end
	return first
end

local function replay(who: any, actionId: any, every: any, foe: any): any
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
	local foeId = if foe == nil then "dummy" else foe
	local foeRow = if type(foeId) == "string" then Enemies.ById[foeId] else nil
	if action == nil or type(seconds) ~= "number" or not (seconds > 0) or foeRow == nil then
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
	local ahead = Vector3.new(0, 0, -1)
	local right = Vector3.new(1, 0, 0) -- ahead is -Z, so right is +X: in play the lead walks in from the avatar's right
	if session.Dummy then
		FightService.Remove(session.Dummy)
	end
	local gap = if Combat.Replay.Distance > 0 then Combat.Replay.Distance else action.Range - Combat.Approach
	local dummyAt = Vector3.new(CENTER.X, top, CENTER.Z)
	local stand = dummyAt - ahead * Combat.Replay.Behind - right * Combat.Lead.Side + Vector3.new(0, STAND, 0)
	session.Dummy = FightService.SpawnEnemy(foeRow.Id, lead.Block.Level, CFrame.lookAt(dummyAt, dummyAt - ahead))
	local turn = math.rad(Combat.Lead.Frame)
	local spot = dummyAt + (ahead * math.cos(turn) + right * math.sin(turn)) * gap + Vector3.new(0, STAND, 0)
	player:RequestStreamAroundAsync(spot)
	lead.Root.AssemblyLinearVelocity = Vector3.zero
	lead.Root.CFrame = CFrame.lookAt(spot, Vector3.new(dummyAt.X, spot.Y, dummyAt.Z))
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(stand, stand + ahead)
	FightService.Force(lead, action.Id, seconds, session.Dummy)
	local swing = if foeRow.Action then Actions.ById[foeRow.Action] else nil
	local leadHit, foeHit = firstHit(action), if swing then firstHit(swing) else nil
	local lag: number? = nil
	if swing and leadHit and foeHit then
		-- its blow at the lead's first hit plus Short: it presses that long after the lead, or the lead after it
		lag = leadHit + Combat.Replay.Short - foeHit
		local dummy = session.Dummy :: FightService.Fighter
		FightService.Force(dummy, swing.Id, seconds, lead)
		if (lag :: number) >= 0 then
			FightService.Follow(dummy, lead, lag :: number)
		else
			FightService.Follow(lead, dummy, -(lag :: number))
		end
	end
	player:SetAttribute("Replay", `{action.Id}@{workspace:GetServerTimeNow()}`)
	-- Spot and Target: where the lead and the dummy stand for each press, which a client can't see when its first beat
	-- moves the lead (Actions.Moves) in the same step as the press puts them back
	return { Ok = true, Action = action.Id, Every = seconds, Level = lead.Block.Level, Spot = spot, Target = dummyAt, Foe = foeRow.Id, Lag = lag }
end

local spawned: { [FightService.Fighter]: boolean } = {}

-- `comes`: it comes for the player's lead at once, as one fought alone does (TR29's `For`), lead fighting or not: since
-- TR24's fix 6 a Shade passes over an idle lead, and a case that needs one on the lead says so.
local function fightSpawn(who: any, def: any, level: any, ahead: any, comes: any, difficulty: any): any
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
	local badDifficulty = difficulty ~= nil and difficulty ~= "Normal" and difficulty ~= "Hard"
	if root == nil or type(def) ~= "string" or Enemies.ById[def] == nil or type(lvl) ~= "number" or type(studs) ~= "number" or badDifficulty then
		return { Ok = false, Error = "BadArgs" }
	end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local spot = root.Position + look * studs
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Fighters") or workspace.Terrain, (player :: Player).Character :: Model }
	local hit = workspace:Raycast(spot, Vector3.new(0, -GROUND_RAY, 0), params)
	local ground = if hit then hit.Position else spot - Vector3.new(0, STAND, 0)
	local f = FightService.SpawnEnemy(def, lvl, CFrame.lookAt(ground, ground - look), if difficulty then { Difficulty = difficulty } else nil)
	if comes == true then
		f.For = player
		f.Model:SetAttribute("For", (player :: Player).UserId)
	end
	spawned[f] = true
	f.Model.Destroying:Connect(function()
		spawned[f] = nil
	end)
	return { Ok = true, Id = f.Id, Health = f.Health }
end

-- One of FightSpawn's enemies falls at once, as if hit to nothing: its fall seen whole (the keeper's lantern going out).
local function fightDefeat(_who: any, id: any): any
	for f in spawned do
		if f.Id == id then
			FightService.Defeat(f)
			return { Ok = true }
		end
	end
	return { Ok = false, Error = "NotSpawned" }
end

local function fightHealth(who: any, share: any, cap: any): any
	local player = DebugService.ResolvePlayer(who)
	local lead = if player then FightService.LeadOf(player) else nil
	if lead == nil or type(share) ~= "number" or not (share >= 0 and share <= 1) then
		return { Ok = false, Error = "BadArgs" }
	end
	if cap == true and lead.Health <= lead.Block.Health * share then
		-- already as low: left as it is
	elseif share == 0 then
		FightService.Defeat(lead)
	else
		FightService.SetHealthShare(lead, share)
	end
	return { Ok = true, Health = lead.Health }
end

local function foeHealth(_who: any, id: any, share: any): any
	local f = if type(id) == "number" or type(id) == "string" then FightService.All()[tostring(id)] else nil
	if f == nil or spawned[f] == nil or type(share) ~= "number" or not (share > 0 and share <= 1) then
		return { Ok = false, Error = "BadArgs" }
	end
	FightService.SetHealthShare(f, share)
	return { Ok = true, Health = f.Health }
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
	DebugService.Register("FightDefeat", fightDefeat)
	DebugService.Register("Fighters", fighters)
	DebugService.Register("FightHealth", fightHealth)
	DebugService.Register("FoeHealth", foeHealth)
	Players.PlayerRemoving:Connect(stopFor)
end

return ReplayService
