--!strict
-- KeeperService (server): the keeper, fought alone (docs/design.md, "Combat": bosses are a decision; docs/test-requests.md,
-- TR2, "The builder's read"). Each plot has its own copy of the street's ring, out of sight (Config.World.Grey: CopiesAt,
-- Copies), cloned from the Ring marker with its tags taken off, so the player fights in the place they saw.
-- * The keeper's gate asks "Challenge" (held Config.Combat.Keeper.Hold). A try is a fade, then the avatar and the lead at the
--   copy's entrance, a fresh keeper at its middle. The player attribute Try holds the keeper's Def while it runs.
-- * The keeper's fall wins it: the win is saved first (Rules.Progress), then after WinPause a fade sets the avatar and the
--   lead down at RingExit, by the shortcut. The lead's fall loses it: after LossPause a fade sets them back before the
--   keeper's gate. A leave or a respawn ends it with nothing saved.
-- * The shortcut pad sets whoever steps on it down on their own plot. It's reached only beyond the ring, so only by a win.
-- * A win rests this player's keeper Config.World.Row.Back.Keeper, kept in their save (TR10, Rules.Progress): a try asked
--   meanwhile is refused "Resting". The client hides the gate's Challenge (workspace.Keeper.Challenge) for them meanwhile
--   and shows the time left at the gate (DownController). A loss rests nothing.
-- Studio: NL_Debug:Invoke("Keeper", who) the try's state; ("KeeperTry", who) a try as if the gate were asked;
-- ("KeeperEnd", who, "Win" | "Loss") the keeper or the lead falls at once; ("KeeperRest", who, seconds) this player's
-- keeper resting that long from now, 0 to have it back at once; ("KeeperForce", who, action, every?) the try's
-- keeper pressing it every `every` seconds (6) where it stands, its lead set back to the action's Range and held still
-- facing it, kept over half its health, for a take (AR8, the keeper's signature); ("KeeperForce", who) lets both go.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local Enemies = require(Shared.Definitions.Enemies)
local Actions = require(Shared.Definitions.Actions)
local Combat = require(Shared.Config.Combat)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Progress = require(Shared.Rules.Progress)
local Profile = require(Shared.Data.Profile)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)
local WorldService = require(script.Parent.WorldService)

local KeeperService = {
	Priority = 45, -- after the world, the fight and the packs
}

-- A try begins (player, ground), before its fade: StageService makes it the keeper's stage's run (TR43).
KeeperService.Trying = Signal.new()
-- A try won (player, ground), its win saved: the keeper's stage cleared (StageService, TR43).
KeeperService.Won = Signal.new()
-- The keeper's level in `player`'s try: the ring's, unless StageService lifts it for a run on Hard (TR43).
KeeperService.LevelOf = function(_player: Player, level: number): number
	return level
end

local FOLDER = "Keeper"
local STAND = 3 -- an R6 root stands 3 studs over its floor
local FENCE_HIGH = 24 -- the copy's unseen fence
local MARGIN = 6 -- studs of floor round a copy's ring, inside its fence
local REACH_SLACK = 4 -- studs past the prompt's reach the server still accepts: a moving avatar's lag

type Try = {
	Plot: number,
	Keeper: FightService.Fighter?,
	Ending: boolean,
	LeadSide: number?, -- studs right of the avatar its lead was set down (the self-test's read of Combat.Keeper.Side)
}

type Copy = { Centre: CFrame } -- its middle, where the keeper starts

local tries: { [Player]: Try } = {}
local copies: { [number]: Copy } = {}
local ring: { Def: string, Level: number, Ground: string, Radius: number, ToGate: Vector3 }? = nil

local function folder(): Folder
	local found = workspace:FindFirstChild(FOLDER)
	if found and found:IsA("Folder") then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = FOLDER
	made.Parent = workspace
	return made
end

local function wall(parent: Instance, size: Vector3, at: CFrame)
	local p = Instance.new("Part")
	p.Name = "Fence"
	p.Anchored = true
	p.Size = size
	p.CFrame = at
	p.Transparency = 1
	p.CanQuery = false
	p.Parent = parent
end

-- Where the avatar arrives in `copy`, facing its middle, Arrive from it toward the gate and turned Turn left: read at each
-- try, so both are tuned live.
local function entryOf(copy: Copy): CFrame
	local r = ring :: any
	local entry = copy.Centre.Position + r.ToGate * math.min(Combat.Keeper.Arrive, r.Radius - 1)
	return CFrame.lookAt(entry, copy.Centre.Position) * CFrame.Angles(0, math.rad(Combat.Keeper.Turn), 0)
end

-- Moves the avatar and its lead to `at`, the lead at its side (its left in a try: Combat.Keeper.Side), both looking where
-- `at` looks.
local function setDown(player: Player, at: CFrame)
	local character = player.Character
	local root = Parts.Root(character)
	if character == nil or root == nil then
		return
	end
	local stand = at + Vector3.new(0, STAND, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(stand)
	local lead = FightService.LeadOf(player)
	if lead and FightService.Standing(lead) then -- a fallen lead is home on its plot (TR12)
		lead.Root.AssemblyLinearVelocity = Vector3.zero
		local side = if player:GetAttribute("Try") ~= nil then Combat.Keeper.Side else Combat.Lead.Side
		lead.Root.CFrame = stand * CFrame.new(side, 0, 1)
	end
end

local function fade(player: Player): number
	local f = Combat.Keeper.Fade
	Net.Server.Fire("Fade", player, f.Out, f.Hold, f.Back)
	return f.Out + f.Hold / 2 -- the move, in the middle of the black
end

-- Sets the player and their lead down at `at` in the middle of a fade: the shortcut's way home, and the Festival Door's
-- (DoorService). Not during a try, which moves the player itself. False when nothing moves.
function KeeperService.SetDown(player: Player, at: CFrame): boolean
	if tries[player] then
		return false
	end
	task.delay(fade(player), function()
		setDown(player, at)
	end)
	return true
end

-- Sets the player and their lead down at `at` at once, with no fade: home in one tap (HomeService, TR19), whose jump
-- is its own light. Not during a try. False when nothing moves.
function KeeperService.Place(player: Player, at: CFrame): boolean
	if tries[player] or player.Character == nil then
		return false
	end
	setDown(player, at)
	return true
end

-- The copies, one per plot, and the gate's prompt, from the markers as they stand now. A try under way ends.
local function lay()
	for player in tries do
		KeeperService.End(player)
	end
	local old = workspace:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
	table.clear(copies)
	ring = nil
	local marker = Markers.Find("Ring")
	local gate = Markers.Find("KeeperGate")
	if marker == nil or gate == nil then
		Log.Warn("KeeperService", "no Ring or KeeperGate marker: no keeper's try")
		return
	end
	local def, level, ground = marker:GetAttribute("Def"), marker:GetAttribute("Level"), marker:GetAttribute("Ground")
	if type(def) ~= "string" or type(level) ~= "number" or type(ground) ~= "string" or Enemies.ById[def] == nil then
		Log.Warn("KeeperService", "the Ring marker's Def, Level or Ground is wrong: the world report says what")
		return
	end
	local at = Markers.At(marker)
	local extents = if marker:IsA("Model") then marker:GetExtentsSize() elseif marker:IsA("BasePart") then marker.Size else Vector3.zero
	local radius = math.max(extents.X, extents.Z) / 2
	local toward = Markers.At(gate).Position - at.Position
	local flat = Vector3.new(toward.X, 0, toward.Z)
	local toGate = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, 1)
	ring = { Def = def, Level = level, Ground = ground, Radius = radius, ToGate = toGate }

	local into = folder()
	local grey = WorldConfig.Grey
	for plot = 1, WorldConfig.Plots.Count do
		local copy = marker:Clone()
		Markers.Unstamp(copy)
		copy.Name = `Ring copy {plot}`
		local centre = CFrame.new(grey.CopiesAt + (plot - 1) * grey.Copies, at.Y, 0) * at.Rotation
		if copy:IsA("Model") then
			copy:PivotTo(centre)
		elseif copy:IsA("BasePart") then
			copy.CFrame = centre
		end
		copy:SetAttribute("Plot", plot)
		copy.Parent = into
		-- Its own floor, and an unseen fence round it, so the opening onto the street leads nowhere.
		local side = 2 * (radius + MARGIN)
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Anchored = true
		floor.Size = Vector3.new(side, 1, side)
		floor.CFrame = CFrame.new(centre.Position - Vector3.new(0, 0.5, 0))
		floor.Color = Color3.fromRGB(118, 120, 126)
		floor.Material = Enum.Material.SmoothPlastic
		floor.Parent = copy
		local sides: { Vector3 } = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
		for _, offset in sides do
			local across = if offset.X ~= 0 then Vector3.new(1, FENCE_HIGH, side) else Vector3.new(side, FENCE_HIGH, 1)
			wall(copy, across, CFrame.new(centre.Position + offset * (side / 2) + Vector3.new(0, FENCE_HIGH / 2, 0)))
		end
		copies[plot] = { Centre = centre }
	end

	-- The gate's Challenge, on a part of our own at its foot, so an authored gate needs no named part.
	local holder = Instance.new("Part")
	holder.Name = "Challenge"
	holder.Anchored = true
	holder.Size = Vector3.new(2, 2, 2)
	holder.CFrame = Markers.At(gate) + Vector3.new(0, 3, 0) + toGate * 2
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Parent = into
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Challenge"
	prompt.ObjectText = Enemies.ById[def].Name
	prompt.HoldDuration = Combat.Keeper.Hold
	prompt.MaxActivationDistance = Combat.Keeper.Reach
	prompt.RequiresLineOfSight = false
	prompt.Parent = holder
	prompt.Triggered:Connect(function(player: Player)
		local root = Parts.Root(player.Character)
		if root and (root.Position - holder.Position).Magnitude <= Combat.Keeper.Reach + REACH_SLACK then
			KeeperService.Try(player) -- the server's own check of where the asker stands
		end
	end)
end

-- Ends `player`'s try where it stands: the keeper goes, nothing is saved, nobody moves.
function KeeperService.End(player: Player)
	local try = tries[player]
	if try == nil then
		return
	end
	tries[player] = nil
	if try.Keeper then
		FightService.Remove(try.Keeper)
	end
	if player.Parent then
		player:SetAttribute("Try", nil)
	end
end

-- Starts a try for `player`: { Ok } or { Ok = false, Error }.
function KeeperService.Try(player: Player): { [string]: any }
	local plot = WorldService.PlotOf(player)
	local copy = if plot then copies[plot] else nil
	local lead = FightService.LeadOf(player)
	if tries[player] then
		return { Ok = false, Error = "InTry" }
	elseif ring == nil or plot == nil or copy == nil then
		return { Ok = false, Error = "NoRing" }
	end
	local data = DataService.Get(player)
	local resting = if data then Progress.Resting(data, (ring :: any).Ground, os.time()) else 0
	if resting > 0 then
		return { Ok = false, Error = "Resting", Left = resting }
	elseif lead == nil or not FightService.Standing(lead) then
		return { Ok = false, Error = "NoLead" }
	end
	local try: Try = { Plot = plot :: number, Keeper = nil, Ending = false }
	tries[player] = try
	KeeperService.Trying:Fire(player, (ring :: any).Ground) -- before its attribute: a stage's run won't begin in a try
	player:SetAttribute("Try", (ring :: any).Def)
	task.delay(fade(player), function()
		if tries[player] ~= try or ring == nil then
			return
		end
		setDown(player, entryOf(copy))
		local root, lead = Parts.Root(player.Character), FightService.LeadOf(player)
		if root and lead then
			try.LeadSide = (lead.Root.Position - root.Position):Dot(root.CFrame.RightVector)
		end
		local looks = copy.Centre.Position + (ring :: any).ToGate
		try.Keeper = FightService.SpawnEnemy((ring :: any).Def, KeeperService.LevelOf(player, (ring :: any).Level), CFrame.lookAt(copy.Centre.Position, looks), {
			Ground = (ring :: any).Ground,
		})
	end)
	return { Ok = true }
end

-- `v` on the ground, of length 1; the zero vector stays zero.
local function flatLook(v: Vector3): Vector3
	local flat = Vector3.new(v.X, 0, v.Z)
	return if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zero
end

local function won(player: Player, try: Try)
	try.Ending = true
	local ground = (ring :: any).Ground
	local answer = DataService.Change(player, "KeeperWon", function(draft)
		return Progress.KeeperWon(draft, ground, os.time())
	end)
	if answer.Ok ~= true then
		Log.Error("KeeperService", `{player.Name}'s win wasn't saved: {tostring(answer.Error)}`)
	end
	KeeperService.Won:Fire(player, ground)
	task.delay(Combat.Keeper.WinPause, function()
		if tries[player] ~= try then
			return
		end
		task.delay(fade(player), function()
			if tries[player] ~= try then
				return
			end
			local exit = Markers.Find("RingExit")
			if exit then
				setDown(player, Markers.At(exit))
			end
			KeeperService.End(player)
		end)
	end)
end

local function lost(player: Player, try: Try)
	try.Ending = true
	task.delay(Combat.Keeper.LossPause, function()
		if tries[player] ~= try then
			return
		end
		task.delay(fade(player), function()
			if tries[player] ~= try then
				return
			end
			local gate = Markers.Find("KeeperGate")
			if gate and ring then
				local at = Markers.At(gate).Position + (ring :: any).ToGate * Combat.Keeper.Before
				setDown(player, CFrame.lookAt(at, at - (ring :: any).ToGate))
			end
			KeeperService.End(player)
		end)
	end)
end

local function state(who: any): any
	local player = DebugService.ResolvePlayer(who)
	if player == nil then
		return { Ok = false, Error = "NoPlayer" }
	end
	local try = tries[player]
	local plot = WorldService.PlotOf(player)
	local copy = if plot then copies[plot] else nil
	local root = Parts.Root(player.Character)
	local data = DataService.Get(player)
	local record = if data and ring then data.Progress.Grounds[(ring :: any).Ground] else nil
	local function from(at: CFrame?): number
		return if at and root then (root.Position - (at.Position + Vector3.new(0, STAND, 0))).Magnitude else -1
	end
	local exit = Markers.Find("RingExit")
	local gate = Markers.Find("KeeperGate")
	local before = if gate and ring then Markers.At(gate) + (ring :: any).ToGate * Combat.Keeper.Before else nil
	local keeper = if try then try.Keeper else nil
	local lead = FightService.LeadOf(player)
	return {
		Ok = true,
		InTry = try ~= nil,
		Ending = if try then try.Ending else false,
		LeadSide = if try then try.LeadSide or 0 else 0,
		Keeper = if keeper then keeper.Id else "",
		KeeperHealth = if keeper then keeper.Health else 0,
		KeeperLevel = if keeper then keeper.Block.Level else 0, -- lifted on a Hard run (TR43)
		-- Who each is fighting, for "the fight is joined": the keeper's target and the lead's, by id.
		Lead = if lead then lead.Id else "",
		LeadHealth = if lead then lead.Health else 0,
		KeeperTarget = if keeper and keeper.Target then keeper.Target.Id else "",
		LeadTarget = if lead and lead.Target then lead.Target.Id else "",
		FromCopy = if copy and root then (root.Position - copy.Centre.Position).Magnitude else -1,
		-- Degrees the avatar faces off its copy's middle, where the keeper starts.
		OffCentre = if copy and root then math.deg(math.acos(math.clamp(flatLook(root.CFrame.LookVector):Dot(flatLook(copy.Centre.Position - root.Position)), -1, 1))) else -1,
		FromEntry = from(if copy and ring then entryOf(copy) else nil),
		FromExit = from(if exit then Markers.At(exit) else nil),
		FromBefore = from(before),
		FromHome = from(WorldService.SpawnOf(player)),
		Wins = if record then record.KeeperWins else 0,
		Resting = if data and ring then Progress.Resting(data, (ring :: any).Ground, os.time()) else 0,
		Radius = if ring then (ring :: any).Radius else 0,
	}
end

function KeeperService.Start()
	FightService.Fell:Connect(function(f: FightService.Fighter)
		for player, try in tries do
			if try.Ending then
				continue
			end
			if try.Keeper == f then
				won(player, try)
			elseif f.Side == "Lead" and f.Owner == player then
				lost(player, try)
			end
		end
	end)
	Players.PlayerRemoving:Connect(KeeperService.End)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			KeeperService.End(player) -- a respawn mid-try: WorldService sets them down on their plot
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	-- The shortcut home: whoever steps on it, once a second at most.
	local last: { [Player]: number } = {}
	local function shortcut()
		local pad = Markers.Find("Shortcut")
		if pad == nil or not pad:IsA("BasePart") then
			return
		end
		pad.Touched:Connect(function(part: BasePart)
			local player = if part.Parent and part.Parent:IsA("Model") then Players:GetPlayerFromCharacter(part.Parent) else nil
			local now = os.clock()
			if player == nil or tries[player] or (last[player] and now - last[player] < 1) then
				return
			end
			last[player] = now
			local home = WorldService.SpawnOf(player)
			if home then
				KeeperService.SetDown(player, home)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		last[player] = nil
	end)
	WorldService.Laid:Connect(function()
		lay()
		shortcut()
	end)
	lay()
	shortcut()
	if RunService:IsStudio() then
		DebugService.Register("Keeper", state)
		DebugService.Register("KeeperTry", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			return if player then KeeperService.Try(player) else { Ok = false, Error = "NoPlayer" }
		end)
		DebugService.Register("KeeperRest", function(who: any, seconds: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil then
				return { Ok = false, Error = "NoPlayer" }
			elseif ring == nil then
				return { Ok = false, Error = "NoRing" }
			elseif type(seconds) ~= "number" or seconds < 0 then
				return { Ok = false, Error = "BadArgs" }
			end
			local ground = (ring :: any).Ground
			return DataService.Change(player, "KeeperRest", function(draft)
				local record = draft.Progress.Grounds[ground]
				if record == nil and seconds > 0 then
					record = { Opened = os.time(), KeeperWins = 0, Back = nil } :: Profile.GroundProgress
					draft.Progress.Grounds[ground] = record
				end
				if record then
					record.Back = if seconds > 0 then os.time() + seconds else nil
				end
				return { Ok = true, Resting = Progress.Resting(draft, ground, os.time()) }
			end)
		end)
		DebugService.Register("KeeperEnd", function(who: any, how: any): any
			local player = DebugService.ResolvePlayer(who)
			local try = if player then tries[player] else nil
			if player == nil or try == nil or try.Keeper == nil then
				return { Ok = false, Error = "NoTry" }
			end
			if how == "Win" then
				FightService.Defeat(try.Keeper)
			elseif how == "Loss" then
				local lead = FightService.LeadOf(player)
				if lead == nil then
					return { Ok = false, Error = "NoLead" }
				end
				FightService.Defeat(lead)
			else
				return { Ok = false, Error = "BadArgs" }
			end
			return { Ok = true }
		end)
		DebugService.Register("KeeperForce", function(who: any, action: any, every: any): any
			local player = DebugService.ResolvePlayer(who)
			local try = if player then tries[player] else nil
			local keeper = if try then try.Keeper else nil
			local lead = if player then FightService.LeadOf(player) else nil
			if keeper == nil or lead == nil then
				return { Ok = false, Error = "NoTry" }
			end
			if action == nil then
				FightService.Force(keeper, nil)
				FightService.Force(lead, nil)
				lead.Home = nil
				return { Ok = true }
			end
			local row = if type(action) == "string" then Actions.ById[action] else nil
			if row == nil or (every ~= nil and type(every) ~= "number") then
				return { Ok = false, Error = "BadArgs" }
			end
			-- Where the fight has put them (let it settle first: the lead at the keeper's side, Combat.Lead.Beside): the keeper
			-- stays, facing the lead, and the lead steps back along their line to the action's range, facing it.
			local spot = keeper.Root.Position
			local away = lead.Root.Position - spot
			away = Vector3.new(away.X, 0, away.Z)
			away = if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, -1)
			local from = spot + away * row.Range
			from = Vector3.new(from.X, lead.Root.Position.Y, from.Z)
			keeper.Root.AssemblyLinearVelocity = Vector3.zero
			keeper.Root.CFrame = CFrame.lookAt(spot, Vector3.new(from.X, spot.Y, from.Z))
			lead.Root.AssemblyLinearVelocity = Vector3.zero
			lead.Root.CFrame = CFrame.lookAt(from, Vector3.new(spot.X, from.Y, spot.Z))
			lead.Home = lead.Root.CFrame -- every press from the same spacing: the last one's push undone
			FightService.Force(lead, "", 0, keeper)
			FightService.Force(keeper, action, every or 6, lead)
			task.spawn(function()
				while keeper.Forced == action and lead.Forced == "" and lead.Model.Parent do
					if lead.Health < lead.Block.Health * 0.5 then
						FightService.SetHealthShare(lead, 1)
					end
					task.wait(0.1)
				end
			end)
			return { Ok = true, Range = row.Range }
		end)
	end
end

return KeeperService
