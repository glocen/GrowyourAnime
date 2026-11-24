--!strict
-- TowerService (server): the Tower's runs (TR29; docs/design.md, "The Tower"; docs/engineering-plan.md, "The Tower").
-- A player steps into their plot's ring with a standing lead: a run starts, and floor 1's platform carries them up.
-- Each floor, one foe: a Voidkin of Rules.Tower.Foe in an enemy look, fought by this lead alone (FightService's For). A
-- floor won is one transaction (Rules.Tower.Won); the next platform stands Config.Tower's Height above, the avatar and
-- the lead are set on it at the rise's Leap, and the next foe comes at its end. Health carries: no heal between floors,
-- and in a floor at most its cap (FightService's HealRoom). The lead and its Regalia stay frozen through the run (D10,
-- the player's "Tower" attribute, FightService.Frozen). The lead falling, the avatar leaving its platform, a respawn, a
-- leave or a shutdown end the run at its last floor won (Rules.Tower.End): its ledger granted once, the results kept in
-- the save until the client's screen has shown them (Act "TowerSeen"). A run the save still holds at a join (a crash)
-- is ended there. The server holds one floor's collision; the client draws the platforms (TowerController).
-- Player attributes: Tower, the floor being fought or risen to (nil out of a run); TowerFoe, its foe's name.
--   TowerService.Begin(player) -> { Ok, Error? }     a run from the ring (the ring's own step, and the debug bridge)
--   TowerService.Stop(player, why)                   the run ended where it stands
-- The results' two presses (TR46): Net "TowerRetry" sets the avatar in its ring, where the ring's own step begins the
-- next run once Rest is up; Net "TowerHome" sets it down at its plot's spawn, free (HomeService.SetDown).
-- The heal cap told once (TR46): the first time it binds on a run's lead, the save keeps Progress.Tower.HealTold and the
-- client is told (Net "TowerHealCap", the share), once per account.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local TowerConfig = require(Shared.Config.Tower)
local Voidkin = require(Shared.Definitions.Voidkin)
local Markers = require(Shared.World.Markers)
local Profile = require(Shared.Data.Profile)
local Tower = require(Shared.Rules.Tower)
local Net = require(Shared.Net)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)
local HomeService = require(script.Parent.HomeService)
local KeeperService = require(script.Parent.KeeperService)
local WorldService = require(script.Parent.WorldService)
local GoalService = require(script.Parent.GoalService)

local TowerService = {
	Priority = 50, -- after the world, the fight and the keeper's moves
}

local STAND = 3 -- an R6 root stands 3 studs over its floor
local STEP = 0.1 -- seconds between the ring's and the platforms' checks
local FALL_PAUSE = 1.2 -- seconds the fallen lead's fall plays before the fade takes the player down

type Run = {
	Id: string,
	Seed: number,
	Foes: number, -- the foes' seed: the week the run started in (Rules.Tower.WeekSeed); its chests are its Seed's
	Ring: CFrame, -- the ring's middle on the ground, looking out from the plot: the fight's axis
	Floor: number, -- the floor being fought, or risen to
	On: number, -- the floor whose platform holds the avatar: 0 on the ground before floor 1's, Floor - 1 until a rise's Leap
	Phase: "Rising" | "Fighting" | "Won" | "Ending",
	Foe: FightService.Fighter?,
	Fast: boolean, -- the floor just fought fell fast, so this rise is the quick one
	Collision: BasePart?,
	Grace: number, -- os.clock until which the leave check waits (a set-down settling)
}

local runs: { [Player]: Run } = {}
local endedAt: { [Player]: number } = {} -- os.clock a run ended: the ring waits Config's Rest
local stepped: { [Player]: boolean } = {} -- the avatar has been outside the ring since its last run
local folder: Folder? = nil
local seeds = Random.new()

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function ringOf(player: Player): CFrame?
	local plot = WorldService.PlotOf(player)
	local ring = if plot then Markers.Find("TowerRing", { Plot = plot }) else nil
	if ring == nil then
		return nil
	end
	local at = Markers.At(ring)
	-- Out from the plot: the ring's lot lies past its plot's back, its frame the plot's, so out is its -LookVector.
	local out = -flat(at.LookVector)
	out = if out.Magnitude > 1e-3 then out.Unit else Vector3.zAxis
	return CFrame.lookAt(at.Position, at.Position + out)
end

-- Floor `floor`'s platform top, over the ring.
local function topOf(run: Run, floor: number): Vector3
	return run.Ring.Position + Vector3.new(0, floor * TowerConfig.Platform.Height, 0)
end

local function holder(): Folder
	if folder == nil or folder.Parent == nil then
		local made = Instance.new("Folder")
		made.Name = "Tower"
		made.Parent = workspace
		folder = made
	end
	return folder :: Folder
end

-- The one floor's collision the server holds: unseen, the client draws the platform (TowerController).
local function collision(player: Player, top: Vector3): BasePart
	local p = TowerConfig.Platform
	local part = Instance.new("Part")
	part.Name = `Floor_{player.UserId}`
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.Size = Vector3.new(p.Thick, p.Radius * 2, p.Radius * 2)
	part.CFrame = CFrame.new(top - Vector3.new(0, p.Thick / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Transparency = 1
	part.CanTouch = false
	part:SetAttribute("For", player.UserId)
	part.Parent = holder()
	return part
end

local function dropCollision(run: Run, after: number?)
	local part = run.Collision
	run.Collision = nil
	if part then
		if after and after > 0 then
			task.delay(after, function()
				part:Destroy()
			end)
		else
			part:Destroy()
		end
	end
end

-- Where the avatar is set down on floor `floor` (behind the middle, looking out) and where its foe stands (in front,
-- looking back at it).
local function spots(run: Run, floor: number): (CFrame, CFrame)
	local top = topOf(run, floor)
	local out = run.Ring.LookVector
	local away = TowerConfig.Platform.Radius * TowerConfig.Stand
	local me = top - out * away
	local foe = top + out * away
	return CFrame.lookAt(me, me + out), CFrame.lookAt(foe + Vector3.new(0, STAND, 0), me + Vector3.new(0, STAND, 0))
end

local function leadOf(player: Player): FightService.Fighter?
	local lead = FightService.LeadOf(player)
	return if lead and FightService.Standing(lead) then lead else nil
end

-- Floor `floor`: its platform stands over the last, the avatar and the lead are set on it at the rise's Leap, and its foe
-- comes at the rise's end. Floor 1 rises from the ring.
local function rise(player: Player, run: Run, floor: number)
	run.Phase = "Rising"
	run.Floor = floor
	run.Foe = nil
	player:SetAttribute("Tower", floor)
	player:SetAttribute("TowerFoe", nil)
	local lead = leadOf(player)
	if lead then
		FightService.SetHealRoom(lead, 0) -- nothing heals between floors
	end
	local seconds = Tower.Rise(run.Fast)
	task.delay(seconds * TowerConfig.Leap, function()
		if runs[player] ~= run or run.Floor ~= floor then
			return
		end
		local old = run.Collision
		run.Collision = collision(player, topOf(run, floor))
		local me = spots(run, floor)
		run.Grace = os.clock() + 1
		run.On = floor
		KeeperService.Place(player, me)
		if old then
			old:Destroy()
		end
	end)
	task.delay(seconds, function()
		if runs[player] ~= run or run.Floor ~= floor then
			return
		end
		local data = DataService.Get(player)
		local held = if data then data.Progress.Tower.Run else nil
		if held == nil or held.Id ~= run.Id then
			TowerService.Stop(player, "Lost")
			return
		end
		local foe = Tower.Foe(floor, run.Foes)
		local block = Tower.Block(foe)
		local _, at = spots(run, floor)
		local row = Voidkin.ById[foe.Def]
		local f = FightService.SpawnRival(player, block, at, if row then row.Name else foe.Def)
		local fighter = leadOf(player)
		run.Fast = fighter ~= nil and Tower.Fast(fighter.Block.Level, foe.Level)
		FightService.SetFrail(f, run.Fast)
		if fighter then
			FightService.SetHealRoom(fighter, Tower.HealCap(fighter.Block.Health))
		end
		run.Foe = f
		run.Phase = "Fighting"
		player:SetAttribute("TowerFoe", f.Model.Name)
	end)
end

function TowerService.Begin(player: Player): { [string]: any }
	if runs[player] then
		return { Ok = false, Error = "InRun" }
	end
	local ring = ringOf(player)
	if ring == nil then
		return { Ok = false, Error = "NoRing" }
	elseif player:GetAttribute("Try") ~= nil or FightService.InCombat(player) then
		return { Ok = false, Error = "InCombat" }
	elseif leadOf(player) == nil then
		return { Ok = false, Error = "NoLead" }
	end
	local seed = seeds:NextInteger(1, 2 ^ 31 - 1)
	local started = os.time()
	local answer = DataService.Change(player, "TowerStart", function(draft: Profile.Data)
		Tower.Recover(draft, started) -- a run left by a crash this join didn't end: ended first, so the new one starts clean
		local id = Profile.NewId(draft)
		local run = Tower.Start(draft, id, seed, started)
		if run == nil then
			return { Ok = false, Error = "InRun" }
		end
		return { Ok = true, Id = id }
	end)
	if answer.Ok ~= true then
		return answer
	end
	GoalService.Led(player) -- a climb is a run: "lead a run with someone new" (TR54)
	local run: Run = {
		Id = answer.Id,
		Seed = seed,
		Foes = Tower.WeekSeed(Tower.Week(started)),
		Ring = ring,
		Floor = 0,
		On = 0,
		Phase = "Rising",
		Foe = nil,
		Fast = false,
		Collision = nil,
		Grace = os.clock() + 1,
	}
	runs[player] = run
	stepped[player] = false
	rise(player, run, 1)
	return { Ok = true, Id = run.Id }
end

local function won(player: Player, run: Run)
	run.Phase = "Won"
	local floor = run.Floor
	local lead = leadOf(player)
	if lead then
		FightService.SetHealRoom(lead, 0)
	end
	local answer = DataService.Change(player, "TowerWon", function(draft: Profile.Data)
		local reward = Tower.Won(draft, run.Id, floor, run.Fast) -- only a hard floor pays
		if reward == nil then
			return { Ok = false, Error = "Stale" }
		end
		return { Ok = true, Credits = reward.Credits, Chest = reward.Chest or "" }
	end)
	if answer.Ok ~= true then
		Log.Error("TowerService", `{player.Name}'s floor {floor} wasn't written: {tostring(answer.Error)}`)
		TowerService.Stop(player, "Lost")
		return
	end
	rise(player, run, floor + 1)
end

function TowerService.Stop(player: Player, why: string)
	local run = runs[player]
	if run == nil then
		return
	end
	runs[player] = nil
	run.Phase = "Ending"
	if run.Foe then
		FightService.Remove(run.Foe)
		run.Foe = nil
	end
	local lead = FightService.LeadOf(player)
	if lead then
		FightService.SetHealRoom(lead, nil)
	end
	local ended = os.time()
	local answer = DataService.Change(player, "TowerEnd", function(draft: Profile.Data)
		local results = Tower.End(draft, run.Id, ended)
		if results == nil then
			return { Ok = false, Error = "NoRun" }
		end
		return { Ok = true, Floor = results.Floor }
	end)
	if answer.Ok ~= true and player.Parent == Players then
		-- A player gone takes their save with them: the run stays in it, and the next join ends it (Tower.Recover).
		Log.Warn("TowerService", `{player.Name}'s run {run.Id} ended ({why}) but wasn't written: {tostring(answer.Error)}`)
	end
	endedAt[player] = os.clock()
	stepped[player] = false
	player:SetAttribute("Tower", nil)
	player:SetAttribute("TowerFoe", nil)
	if why == "Fell" then
		-- Still on the platform: set down beside the ring in the fade's black, the platform held till then.
		local beside = run.Ring.Position - run.Ring.LookVector * (TowerConfig.Ring + 6)
		KeeperService.SetDown(player, CFrame.lookAt(beside, run.Ring.Position))
		dropCollision(run, 2)
	else
		dropCollision(run)
	end
end

-- The ring and every run, each STEP: a run starts from its ring; a run's avatar off its platform has left; its lead and
-- its foe are kept on it.
local function check()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local root = Parts.Root(player.Character)
		if root == nil then
			continue
		end
		local run = runs[player]
		if run == nil then
			local ring = ringOf(player)
			if ring == nil then
				continue
			end
			local off = flat(root.Position - ring.Position).Magnitude
			local inside = off <= TowerConfig.Ring and math.abs(root.Position.Y - STAND - ring.Position.Y) < 4
			if not inside and off > TowerConfig.Ring + 1 then
				stepped[player] = true
			end
			local rested = endedAt[player] == nil or now - endedAt[player] >= TowerConfig.Rest
			if inside and rested and stepped[player] ~= false then
				TowerService.Begin(player)
			end
			continue
		end
		if run.On == 0 or run.Collision == nil then
			continue -- floor 1's platform not under them yet
		end
		local top = topOf(run, run.On)
		local radius = TowerConfig.Platform.Radius
		local off = flat(root.Position - top).Magnitude
		if now > run.Grace and (off > radius + TowerConfig.Out.Side or root.Position.Y - STAND < top.Y - TowerConfig.Out.Below) then
			TowerService.Stop(player, "Left")
			continue
		end
		-- A skip back or a shove never takes a fighter off its platform: set back on it, toward the middle.
		for _, f in { leadOf(player), run.Foe } do
			if f and FightService.Standing(f) then
				local at = f.Root.Position
				local away = flat(at - top)
				if away.Magnitude > radius - 1 or at.Y < top.Y - 2 then
					local back = if away.Magnitude > 1e-3 then away.Unit * (radius - 3) else Vector3.zero
					f.Root.AssemblyLinearVelocity = Vector3.zero
					f.Model:PivotTo(CFrame.lookAt(top + back + Vector3.new(0, STAND, 0), top + Vector3.new(0, STAND, 0)))
				end
			end
		end
	end
end

-- A run the save still holds at a join (a crash, a shutdown): ended at its last floor won, its results kept to be shown.
local function recover(player: Player): { [string]: any }
	local now = os.time()
	return DataService.Change(player, "TowerRecover", function(draft: Profile.Data)
		local results = Tower.Recover(draft, now)
		return if results then { Ok = true, Floor = results.Floor } else { Ok = false, Error = "NoRun" }
	end)
end

local function state(who: any): any
	local player = DebugService.ResolvePlayer(who)
	if player == nil then
		return { Ok = false, Error = "NoPlayer" }
	end
	local run = runs[player]
	local data = DataService.Get(player)
	local lead = FightService.LeadOf(player)
	return {
		Ok = true,
		Floor = if run then run.Floor else nil,
		Phase = if run then run.Phase else nil,
		Foe = if run and run.Foe then run.Foe.Def else nil,
		FoeLevel = if run and run.Foe then run.Foe.Block.Level else nil,
		FoeHealth = if run and run.Foe then run.Foe.Health else nil,
		Fast = if run then run.Fast else nil,
		Top = if run then topOf(run, run.Floor).Y else nil,
		HealRoom = if lead then lead.HealRoom else nil,
		LeadHealth = if lead then lead.Health else nil,
		LeadMax = if lead then lead.Block.Health else nil,
		Saved = if data then data.Progress.Tower else nil,
	}
end

function TowerService.Init()
	-- The results shown: cleared from the save, so they open once.
	DataService.Action("TowerSeen", function(draft: Profile.Data, args: any): { [string]: any }
		local id = if type(args) == "table" then args.Id else nil
		if type(id) ~= "string" or not Tower.Seen(draft, id) then
			return { Ok = false, Error = "NotHeld" }
		end
		return { Ok = true }
	end)
	DebugService.Register("TowerStart", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		return if player then TowerService.Begin(player) else { Ok = false, Error = "NoPlayer" }
	end)
	DebugService.Register("TowerWin", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		local run = if player then runs[player] else nil
		if run == nil or run.Foe == nil or run.Phase ~= "Fighting" then
			return { Ok = false, Error = "NoFoe" }
		end
		FightService.Defeat(run.Foe)
		return { Ok = true, Floor = run.Floor }
	end)
	DebugService.Register("TowerFell", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		local lead = if player and runs[player] then FightService.LeadOf(player) else nil
		if lead == nil then
			return { Ok = false, Error = "NoRun" }
		end
		FightService.Defeat(lead)
		return { Ok = true }
	end)
	DebugService.Register("TowerEnd", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		if player == nil or runs[player] == nil then
			return { Ok = false, Error = "NoRun" }
		end
		TowerService.Stop(player, "Debug")
		return { Ok = true }
	end)
	DebugService.Register("TowerState", state)
	-- The avatar stepped off its platform, as a player walking off its edge.
	DebugService.Register("TowerOff", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		local run = if player then runs[player] else nil
		local character = if player then player.Character else nil
		if run == nil or character == nil then
			return { Ok = false, Error = "NoRun" }
		end
		local top = topOf(run, run.On)
		local off = top + run.Ring.LookVector * (TowerConfig.Platform.Radius + TowerConfig.Out.Side + 4)
		character:PivotTo(CFrame.new(off + Vector3.new(0, STAND, 0)))
		return { Ok = true }
	end)
	-- A server lost mid-run: the run dropped here unended, as a crash leaves it, its ledger still in the save; then the
	-- next join's recovery.
	DebugService.Register("TowerCrash", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		local run = if player then runs[player] else nil
		if player == nil or run == nil then
			return { Ok = false, Error = "NoRun" }
		end
		runs[player] = nil
		run.Phase = "Ending"
		if run.Foe then
			FightService.Remove(run.Foe)
		end
		local lead = FightService.LeadOf(player)
		if lead then
			FightService.SetHealRoom(lead, nil)
		end
		player:SetAttribute("Tower", nil)
		player:SetAttribute("TowerFoe", nil)
		dropCollision(run)
		endedAt[player] = os.clock()
		stepped[player] = false
		return { Ok = true }
	end)
	DebugService.Register("TowerRecover", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		return if player then recover(player) else { Ok = false, Error = "NoPlayer" }
	end)
	-- A case's record put back, and any results it left cleared.
	DebugService.Register("TowerBest", function(who: any, best: any)
		local player = DebugService.ResolvePlayer(who)
		if player == nil or type(best) ~= "number" then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "TowerBest", function(draft: Profile.Data)
			draft.Progress.Tower.Best = math.max(0, math.floor(best))
			draft.Progress.Tower.Results = nil
			return { Ok = true }
		end)
	end)
	-- The heal cap at work: a lead's health set to a share mid-floor, so a case can watch what it heals.
	-- A heal through the lead's cap, as its own would go; and the account's heal cap told or not, to see it again.
	DebugService.Register("TowerMend", function(who: any, amount: any)
		local player = DebugService.ResolvePlayer(who)
		local lead = if player then FightService.LeadOf(player) else nil
		if lead == nil or type(amount) ~= "number" then
			return { Ok = false, Error = "NoLead" }
		end
		FightService.Heal(lead, amount)
		return { Ok = true, Health = lead.Health }
	end)
	DebugService.Register("TowerHealTold", function(who: any, told: any)
		local player = DebugService.ResolvePlayer(who)
		if player == nil or (told ~= nil and type(told) ~= "boolean") then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "TowerHealTold", function(draft: Profile.Data)
			draft.Progress.Tower.HealTold = if told then true else nil
			return { Ok = true }
		end)
	end)
	DebugService.Register("TowerHurt", function(who: any, share: any)
		local player = DebugService.ResolvePlayer(who)
		local lead = if player then FightService.LeadOf(player) else nil
		if lead == nil or type(share) ~= "number" then
			return { Ok = false, Error = "NoLead" }
		end
		FightService.SetHealthShare(lead, share)
		return { Ok = true, Health = lead.Health }
	end)
end

-- After a run's results (TR46): "Retry", set in its ring to climb again once rested, or "Home", to the plot's spawn.
-- Refused in a run, a try or a fight.
local function after(player: Player, what: string): { [string]: any }
	if runs[player] then
		return { Ok = false, Error = "InRun" }
	elseif player:GetAttribute("Try") ~= nil or FightService.InCombat(player) then
		return { Ok = false, Error = "InCombat" }
	elseif what == "Home" then
		return if HomeService.SetDown(player) then { Ok = true } else { Ok = false, Error = "Nowhere" }
	end
	local ring = ringOf(player)
	if ring == nil then
		return { Ok = false, Error = "NoRing" }
	elseif leadOf(player) == nil then
		return { Ok = false, Error = "NoLead" }
	elseif not KeeperService.Place(player, ring) then
		return { Ok = false, Error = "Nowhere" }
	end
	stepped[player] = true -- a press counts as stepping in afresh
	local ended = endedAt[player]
	return { Ok = true, Waits = if ended then math.max(0, TowerConfig.Rest - (os.clock() - ended)) else 0 }
end

-- The heal cap bound on a fighter: if it's a run's lead and its account was never told, tell it once.
local telling: { [Player]: boolean } = {}
local function capped(f: FightService.Fighter)
	for player, run in runs do
		if f.Side ~= "Lead" or f.Owner ~= player or run.Phase ~= "Fighting" or telling[player] then
			continue
		end
		local view = DataService.Get(player)
		if view == nil or view.Progress.Tower.HealTold == true then
			continue
		end
		telling[player] = true
		task.spawn(function()
			local answer = DataService.Change(player, "TowerHealTold", function(draft: Profile.Data)
				if draft.Progress.Tower.HealTold == true then
					return { Ok = false, Error = "Told" }
				end
				draft.Progress.Tower.HealTold = true
				return { Ok = true }
			end)
			if answer.Ok == true and player.Parent ~= nil then
				Net.Server.Fire("TowerHealCap", player, TowerConfig.HealCap)
			end
			telling[player] = nil
		end)
	end
end

function TowerService.Start()
	FightService.Capped:Connect(capped)
	Net.Server.Handle("TowerRetry", function(player: Player): { [string]: any }
		return after(player, "Retry")
	end)
	Net.Server.Handle("TowerHome", function(player: Player): { [string]: any }
		return after(player, "Home")
	end)
	FightService.Fell:Connect(function(f: FightService.Fighter)
		for player, run in runs do
			if run.Foe == f and run.Phase == "Fighting" then
				won(player, run)
			elseif f.Side == "Lead" and f.Owner == player and run.Phase ~= "Ending" then
				run.Phase = "Ending"
				task.delay(FALL_PAUSE, function()
					if runs[player] == run then
						TowerService.Stop(player, "Fell")
					end
				end)
			end
		end
	end)
	-- A run the save still holds at a join: a crash or a shutdown took the server before its end. Ended at once.
	DataService.Ready:Connect(function(player: Player, data: Profile.Data)
		if data.Progress.Tower.Run then
			recover(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		TowerService.Stop(player, "Gone")
		endedAt[player] = nil
		stepped[player] = nil
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			TowerService.Stop(player, "Respawn")
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	WorldService.Laid:Connect(function()
		for player in runs do
			TowerService.Stop(player, "World")
		end
	end)
	game:BindToClose(function()
		for player in runs do
			TowerService.Stop(player, "Shutdown")
		end
	end)
	local since = 0
	RunService.Heartbeat:Connect(function(dt: number)
		since += dt
		if since >= STEP then
			since = 0
			check()
		end
	end)
end

return TowerService
