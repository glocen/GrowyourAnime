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
-- Studio: NL_Debug:Invoke("Keeper", who) the try's state; ("KeeperTry", who) a try as if the gate were asked;
-- ("KeeperEnd", who, "Win" | "Loss") the keeper or the lead falls at once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local Enemies = require(Shared.Definitions.Enemies)
local Combat = require(Shared.Config.Combat)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Progress = require(Shared.Rules.Progress)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)
local WorldService = require(script.Parent.WorldService)

local KeeperService = {
	Priority = 45, -- after the world, the fight and the packs
}

local FOLDER = "Keeper"
local STAND = 3 -- an R6 root stands 3 studs over its floor
local FENCE_HIGH = 24 -- the copy's unseen fence
local MARGIN = 6 -- studs of floor round a copy's ring, inside its fence
local REACH_SLACK = 4 -- studs past the prompt's reach the server still accepts: a moving avatar's lag

type Try = {
	Plot: number,
	Keeper: FightService.Fighter?,
	Ending: boolean,
}

type Copy = { Centre: CFrame, Entry: CFrame } -- Entry: where the avatar arrives, facing the middle

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

-- Moves the avatar and its lead to `at`, the lead at its side, both looking where `at` looks.
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
	if lead and lead.State ~= "Down" then
		lead.Root.AssemblyLinearVelocity = Vector3.zero
		lead.Root.CFrame = stand * CFrame.new(Combat.Lead.Side, 0, 1)
	end
end

local function fade(player: Player): number
	local f = Combat.Keeper.Fade
	Net.Server.Fire("Fade", player, f.Out, f.Hold, f.Back)
	return f.Out + f.Hold / 2 -- the move, in the middle of the black
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
		local entry = centre.Position + toGate * (radius - Combat.Keeper.Entry)
		copies[plot] = { Centre = centre, Entry = CFrame.lookAt(entry, centre.Position) }
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
	elseif lead == nil or lead.State == "Down" then
		return { Ok = false, Error = "NoLead" }
	end
	local try: Try = { Plot = plot :: number, Keeper = nil, Ending = false }
	tries[player] = try
	player:SetAttribute("Try", (ring :: any).Def)
	task.delay(fade(player), function()
		if tries[player] ~= try or ring == nil then
			return
		end
		setDown(player, copy.Entry)
		local looks = copy.Centre.Position + (ring :: any).ToGate
		try.Keeper = FightService.SpawnEnemy((ring :: any).Def, (ring :: any).Level, CFrame.lookAt(copy.Centre.Position, looks), {
			Ground = (ring :: any).Ground,
		})
	end)
	return { Ok = true }
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
		Keeper = if keeper then keeper.Id else "",
		KeeperHealth = if keeper then keeper.Health else 0,
		-- Who each is fighting, for "the fight is joined": the keeper's target and the lead's, by id.
		Lead = if lead then lead.Id else "",
		LeadHealth = if lead then lead.Health else 0,
		KeeperTarget = if keeper and keeper.Target then keeper.Target.Id else "",
		LeadTarget = if lead and lead.Target then lead.Target.Id else "",
		FromCopy = if copy and root then (root.Position - copy.Centre.Position).Magnitude else -1,
		FromEntry = from(if copy then copy.Entry else nil),
		FromExit = from(if exit then Markers.At(exit) else nil),
		FromBefore = from(before),
		FromHome = from(WorldService.SpawnOf(player)),
		Wins = if record then record.KeeperWins else 0,
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
				task.delay(fade(player), function()
					setDown(player, home)
				end)
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
	end
end

return KeeperService
