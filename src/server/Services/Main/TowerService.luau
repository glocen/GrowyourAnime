--!strict
-- TowerService (server): the Tower's runs (TR29; docs/design.md, "The Tower"; docs/engineering-plan.md, "The Tower").
-- A player steps through the gate's door on their plot's lot with a standing lead: a run starts in their own copy of
-- the Tower's room (AR56, the Crown; the kit's TowerRoomKit laid by Config.Kits.TowerRoom.Plan at Rules.Tower.RoomAt),
-- made then, far from the map, and they and their lead are set down on its floor in a fade. Each floor, one foe: a
-- Voidkin of Rules.Tower.Foe in an enemy look, fought by this lead alone (FightService's For). A floor won is one
-- transaction (Rules.Tower.Won); the next foe comes at the rise's end, while the client plays the room's beat (its
-- steps, its number: TowerRoomController). Health carries: no heal between floors, and in a floor at most its cap
-- (FightService's HealRoom). The lead and its Regalia stay frozen through the run (D10,
-- the player's "Tower" attribute, FightService.Frozen). The lead falling, the avatar leaving the room, a respawn, a
-- leave or a shutdown end the run at its last floor won (Rules.Tower.End): its ledger granted once, the results kept in
-- the save until the client's screen has shown them (Act "TowerSeen"). A run the save still holds at a join (a crash)
-- is ended there. At the end the avatar is set down before its gate in a fade, and the room is removed in the black.
-- Player attributes: Tower, the floor being fought or risen to (nil out of a run); TowerFoe, its foe's name; TowerRise,
-- the seconds of the rise under way, and TowerBeat, when it started (the server's clock). The gate's slab shows its owner's record (the attribute Record, kept here).
--   TowerService.Begin(player) -> { Ok, Error? }     a run from the gate (the gate's own step, and the debug bridge)
--   TowerService.Stop(player, why)                   the run ended where it stands
-- The results' two presses (TR46): Net "TowerRetry" sets the avatar in its gate's door, where the gate's own step
-- begins the next run once Rest is up; Net "TowerHome" sets it down at its plot's spawn, free (HomeService.SetDown).
-- The heal cap told once (TR46): the first time it binds on a run's lead, the save keeps Progress.Tower.HealTold and the
-- client is told (Net "TowerHealCap", the share), once per account.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local TowerConfig = require(Shared.Config.Tower)
local Voidkin = require(Shared.Definitions.Voidkin)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local RoomPlan = require(Shared.Config.Kits.TowerRoom.Plan) :: any
local RoomManifest = require(Shared.Config.Kits.TowerRoom.Manifest) :: any
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
local STEP = 0.1 -- seconds between the gate's and the rooms' checks
local RECORDS = 1 -- seconds between the gates' records kept
local ROOM_TAG = "GA_TowerRoom" -- a room's model, its owner's UserId in For (the client's look and beat)
local SLAB_TAG = "GA_TowerSlab" -- a slab whose numbers the client writes: a room's, or a gate's with its Record
local LINGER = 0.5 -- seconds a room stands past its owner's set-down, so the black hides it going
local RESPAWN_HOLD = 3 -- seconds a room stands past a respawn in it
local DAIS_TOP = (function(): number -- the gate's dais's top over its lot's ground
	local dais = (require(ReplicatedStorage.Shared.Config.Kits.TowerRoom.Manifest) :: any).pieces.GateDais
	return dais.centre[2] + dais.size[2] / 2
end)()
local FALL_PAUSE = 1.2 -- seconds the fallen lead's fall plays before the fade takes the player down

type Run = {
	Id: string,
	Seed: number,
	Foes: number, -- the foes' seed: the week the run started in (Rules.Tower.WeekSeed); its chests are its Seed's
	Ring: CFrame, -- the gate's lot frame (Rules.Tower.Lot): where the run ends
	Room: CFrame, -- its room's floor middle, looking toward the foe's way in: the fight's axis
	Slot: number,
	Model: Model?,
	Floor: number, -- the floor being fought, or risen to
	On: number, -- 1 once the avatar stands in its room, 0 before
	Phase: "Rising" | "Fighting" | "Won" | "Ending",
	Foe: FightService.Fighter?,
	Fast: boolean, -- the floor just fought fell fast, so this rise is the quick one
	Grace: number, -- os.clock until which the leave check waits (a set-down settling)
}

local runs: { [Player]: Run } = {}
local endedAt: { [Player]: number } = {} -- os.clock a run ended: the ring waits Config's Rest
local stepped: { [Player]: boolean } = {} -- the avatar has been outside the gate's door since its last run
local slots: { [number]: Model } = {} -- each room standing, by its slot
local folder: Folder? = nil
local seeds = Random.new()

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- The player's gate's lot frame: its +Z toward the base (Rules.Tower.Lot).
local function ringOf(player: Player): CFrame?
	local plot = WorldService.PlotOf(player)
	local ring = if plot then Markers.Find("TowerRing", { Plot = plot }) else nil
	return if ring then Tower.Lot(Markers.At(ring)) else nil
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

-- A room's name for a placed piece: its tag alone when it says what it is (Foe0, In1, Drift3), else the piece and tag.
local function pieceName(placement: any): string
	return if #placement.tag > 1 then placement.tag else `{placement.piece}{placement.tag}`
end

-- The player's copy of the room, its floor's middle at `at`: every piece of the plan, from the kit's template
-- (src/storage/TowerRoomKit.rbxm), anchored, each as the kit built it (its look, collision and shadow). Nil until the
-- template is built.
local function roomKit(): Instance?
	local templates = ServerStorage:FindFirstChild("Templates")
	return if templates then templates:FindFirstChild("TowerRoomKit") else nil
end

local function makeRoom(player: Player, at: Vector3): Model?
	local kit = roomKit()
	if kit == nil then
		return nil
	end
	local frame = CFrame.new(at)
	local room = Instance.new("Model")
	room.Name = `Room_{player.UserId}`
	room.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	room.WorldPivot = frame
	for _, placement in RoomPlan.placements do
		local source = kit:FindFirstChild(placement.piece)
		if source == nil or not source:IsA("BasePart") then
			Log.Warn("TowerService", `the room's template has no {placement.piece}`)
			continue
		end
		local part = source:Clone()
		part.Anchored = true
		part.Size *= placement.scale
		part.CFrame = Kit.Room(frame, placement, RoomManifest.pieces[placement.piece])
		part.Name = pieceName(placement)
		part:SetAttribute("Piece", placement.piece)
		if placement.piece == "CrownSlab" then
			CollectionService:AddTag(part, SLAB_TAG)
		end
		part.Parent = room
	end
	room:SetAttribute("For", player.UserId)
	CollectionService:AddTag(room, ROOM_TAG)
	room.Parent = holder()
	return room
end

-- The run's room removed, now or `after` seconds from now, and its slot freed with it.
-- Asks the player's client to have the world round `at` before a faded move lands there (the far room, or the base again).
local function streamAround(player: Player, at: Vector3)
	task.spawn(function()
		pcall(player.RequestStreamAroundAsync, player, at, KeeperService.Landing())
	end)
end

local function dropRoom(run: Run, after: number?)
	local room, slot = run.Model, run.Slot
	run.Model = nil
	local function drop()
		if slots[slot] == room then
			slots[slot] = nil
		end
		if room then
			room:Destroy()
		end
	end
	if after and after > 0 then
		task.delay(after, drop)
	else
		drop()
	end
end

-- Where the avatar stands in its room (on the entrance's side of the middle, looking toward the foe's way in) and where
-- its foe stands (the plan's stand on the other side, looking back at it).
local function spots(run: Run): (CFrame, CFrame)
	local middle = run.Room.Position
	local out = run.Room.LookVector
	local away = RoomPlan.floor.stand
	local me = middle - out * away
	local foe = middle + out * away
	return CFrame.lookAt(me, me + out), CFrame.lookAt(foe + Vector3.new(0, STAND, 0), me + Vector3.new(0, STAND, 0))
end

-- Where a run sets the avatar down on its lot: before the gate, facing it (Rules.Tower.Before).
local function before(lot: CFrame): CFrame
	local x, z = Tower.Before()
	local at = lot * CFrame.new(x, 0, z)
	return CFrame.lookAt(at.Position, at.Position + lot.LookVector)
end

local function leadOf(player: Player): FightService.Fighter?
	local lead = FightService.LeadOf(player)
	return if lead and FightService.Standing(lead) then lead else nil
end

-- Floor `floor`: the room's beat plays on the client (its steps, its number: TowerRise says how long), and the foe comes
-- at its end.
local function rise(player: Player, run: Run, floor: number)
	run.Phase = "Rising"
	run.Floor = floor
	run.Foe = nil
	local seconds = Tower.Rise(run.Fast)
	player:SetAttribute("TowerRise", seconds)
	player:SetAttribute("TowerBeat", workspace:GetServerTimeNow()) -- the beat's start, on the server's clock
	player:SetAttribute("Tower", floor)
	player:SetAttribute("TowerFoe", nil)
	local lead = leadOf(player)
	if lead then
		FightService.SetHealRoom(lead, 0) -- nothing heals between floors
	end
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
		local _, at = spots(run)
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
	elseif roomKit() == nil then
		return { Ok = false, Error = "NoRoom" }
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
	local slot = Tower.FreeSlot(slots)
	local middle = Tower.RoomAt(slot)
	local room = makeRoom(player, middle)
	local run: Run = {
		Id = answer.Id,
		Seed = seed,
		Foes = Tower.WeekSeed(Tower.Week(started)),
		Ring = ring,
		Room = CFrame.new(middle),
		Slot = slot,
		Model = room,
		Floor = 0,
		On = 0,
		Phase = "Rising",
		Foe = nil,
		Fast = false,
		Grace = os.clock() + 1,
	}
	if room then
		slots[slot] = room
	end
	runs[player] = run
	stepped[player] = false
	player:SetAttribute("Tower", 1) -- the lead is frozen from here (D10), through the way in
	-- Into the room in a fade, streamed in round its floor while the screen goes black; floor 1's beat once there.
	streamAround(player, middle)
	local me = spots(run)
	if room == nil or not KeeperService.SetDown(player, me) then
		TowerService.Stop(player, "Lost")
		return { Ok = false, Error = if room == nil then "NoRoom" else "Nowhere" }
	end
	task.delay(KeeperService.Landing(), function()
		if runs[player] ~= run then
			return
		end
		run.On = 1
		run.Grace = os.clock() + 1
		rise(player, run, 1)
	end)
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
	player:SetAttribute("TowerRise", nil)
	player:SetAttribute("TowerBeat", nil)
	if why == "Gone" or why == "Shutdown" then
		dropRoom(run)
	elseif why == "Respawn" then
		dropRoom(run, RESPAWN_HOLD) -- the new avatar is home; its lead's leash brings it back off the floor first
	else
		-- Out of the room in a fade, set down before its gate (the world may have been laid again since it started), the
		-- base streamed in round it while the screen is black, and the room removed in the black.
		local out = before(ringOf(player) or run.Ring)
		if KeeperService.SetDown(player, out) then
			streamAround(player, out.Position)
			dropRoom(run, KeeperService.Landing() + LINGER)
		else
			dropRoom(run)
		end
	end
end

-- The gate and every run, each STEP: a run starts from its gate's door; a run's avatar out of its room has left; its
-- lead and its foe are kept on its floor.
local function check()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local root = Parts.Root(player.Character)
		if root == nil then
			continue
		end
		local run = runs[player]
		if run == nil then
			local lot = ringOf(player)
			if lot == nil then
				continue
			end
			local at = lot:PointToObjectSpace(root.Position)
			local feet = at.Y - STAND
			if not Tower.InGate(at.X, feet, at.Z, 1) then
				stepped[player] = true
			end
			local rested = endedAt[player] == nil or now - endedAt[player] >= TowerConfig.Rest
			if rested and stepped[player] ~= false and Tower.InGate(at.X, feet, at.Z) then
				TowerService.Begin(player)
			end
			continue
		end
		if run.On == 0 then
			continue -- the fade's still taking them in
		end
		local top = run.Room.Position
		local radius = RoomPlan.floor.radius
		local off = root.Position - top
		if now > run.Grace and Tower.Left(off.X, off.Y - STAND, off.Z) then
			TowerService.Stop(player, "Left")
			continue
		end
		-- A skip back or a shove never takes a fighter off the floor: set back on it, toward the middle.
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

-- Each gate's slab shows its owner's record (Progress.Tower.Best; the client writes it: TowerRoomController).
local function records()
	for _, player in Players:GetPlayers() do
		local plot = WorldService.PlotOf(player)
		local ring = if plot then Markers.Find("TowerRing", { Plot = plot }) else nil
		local slab = if ring then ring:FindFirstChild("Record") else nil
		local data = DataService.Get(player)
		if slab and data and slab:GetAttribute("Record") ~= data.Progress.Tower.Best then
			slab:SetAttribute("Record", data.Progress.Tower.Best)
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
		Room = if run then run.Room.Position else nil,
		Slot = if run then run.Slot else nil,
		In = if run then run.On == 1 else nil,
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
		local off = run.Room.Position + run.Room.LookVector * (RoomPlan.floor.stepRing[2] + TowerConfig.Out.Side + 4)
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
		player:SetAttribute("TowerRise", nil)
		player:SetAttribute("TowerBeat", nil)
		dropRoom(run)
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

-- After a run's results (TR46): "Retry", set in its gate's door to climb again once rested, or "Home", to the plot's
-- spawn.
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
	end
	local x, z = Tower.Door()
	local door = (ring * CFrame.new(x, DAIS_TOP, z)).Position
	if not KeeperService.Place(player, CFrame.lookAt(door, door + ring.LookVector)) then
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
	local since, kept = 0, 0
	RunService.Heartbeat:Connect(function(dt: number)
		since += dt
		kept += dt
		if since >= STEP then
			since = 0
			check()
		end
		if kept >= RECORDS then
			kept = 0
			records()
		end
	end)
end

return TowerService
