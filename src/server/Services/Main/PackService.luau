--!strict
-- PackService (server): the Shades of Lantern Row (docs/design.md, "The world, in grey"). Each Pack marker stands Count
-- Shades of its Def at its Level round it (Rules.Fight.PackRing, Config.World.Row.Spread apart), and each Elite marker
-- one, a stage's ("Elite 1" to "Elite 3", TR43). Every Shade carries its marker's Stage.
-- A pack belongs to everyone: FightService shares its notice and keeps every hitter. When a pack's last Shade falls it's
-- back Config.World.Row.Respawn seconds later; an elite, Config.World.Row.Back.Elite later, each one timer for the whole
-- server (TR10, Rules.Cooldown). While a group is down its marker's BackAt attribute holds the server time it's back, so
-- every client shows when (DownController). The world laid again (WorldService.Laid) stands every pack anew on its moved marker.
-- The street in waves (TR69 B; Rules.Waves, Config.World.Row.Waves): a pack whose stop has Waves stands them one at a
-- time, the next Gap seconds after the last Shade of the one before falls, its spots marked in grey for the Tell before;
-- a list run out starts again from its second wave while a player near the stop still owes its stretch's quota. With
-- nobody near owing, it rests: its first wave stands after Respawn, or after a Tell once someone who owes comes near.
-- Studio:
--   NL_Debug:Invoke("Packs")                  each pack: its marker, Shades standing, the gap between them, when it's back,
--                                             and its wave of how many
--   NL_Debug:Invoke("PackDefeat", "Pack 1")   fells that pack's Shades at once, for tests
--   NL_Debug:Invoke("PackBack", "Elite 2")    stands a group that's down at once, its timer cut short

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Fight = require(Shared.Rules.Fight)
local Cooldown = require(Shared.Rules.Cooldown)
local Waves = require(Shared.Rules.Waves)
local Log = require(Shared.Util.Log)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)
local WorldService = require(script.Parent.WorldService)

local PackService = {
	Priority = 40, -- after the world and the fight
}

type Group = {
	Name: string, -- "Pack 1", "Elite 2": FightService's pack id too
	Kind: string, -- "Pack" or "Elite": its comeback's wait (Rules.Cooldown)
	Marker: Instance,
	Alive: { [FightService.Fighter]: boolean },
	BackAt: number?, -- server time it comes back, while it's down
	Waves: { Waves.Wave }?, -- its stop's waves (TR69 B), nil for a pack of one ring and an elite
	Wave: number, -- the wave standing, or next to stand
	Due: number, -- bumped each time a wave is called, so a call overtaken never stands one
}

local groups: { [string]: Group } = {}

-- The Waves of the stop a Pack marker stands for (its Pack number counts the street's Pack stops), nil while they're off.
local function wavesOf(marker: Instance): { Waves.Wave }?
	local number = marker:GetAttribute("Pack")
	if not WorldConfig.Row.Waves.On or type(number) ~= "number" then
		return nil
	end
	local n = 0
	for _, stop in WorldConfig.Row.Stops do
		if stop.Kind == "Pack" then
			n += 1
			if n == number then
				return if stop.Waves then Waves.Of(stop) else nil
			end
		end
	end
	return nil
end

-- Its Shades, standing round the marker and looking where it looks.
local function stand(group: Group)
	local marker = group.Marker
	local def = marker:GetAttribute("Def")
	local level = marker:GetAttribute("Level")
	local count = marker:GetAttribute("Count")
	local type_ = marker:GetAttribute("Type")
	local ground = marker:GetAttribute("Ground")
	local stage = marker:GetAttribute("Stage")
	if type(def) ~= "string" or type(level) ~= "number" then
		Log.Warn("PackService", `{group.Name}'s marker has no Def or Level: the world report says what's wrong`)
		return
	end
	group.BackAt = nil
	marker:SetAttribute("BackAt", nil)
	local at = Markers.At(marker)
	local n = if type(count) == "number" then count else 1
	local with, withCount = marker:GetAttribute("With"), marker:GetAttribute("WithCount")
	local rear, rearCount = marker:GetAttribute("Rear"), marker:GetAttribute("RearCount")
	local waves = group.Waves
	local spots: { any } = if waves then Waves.Spots(waves[group.Wave] or waves[1], WorldConfig.Row.Spread, WorldConfig.Row.Waves.Side, WorldConfig.Row.Waves.Far, WorldConfig.Row.Behind) else Fight.PackSpots(def, n, if type(with) == "string" then with else nil, if type(withCount) == "number" then withCount else nil, if type(rear) == "string" then rear else nil, if type(rearCount) == "number" then rearCount else nil, WorldConfig.Row.Spread, WorldConfig.Row.Behind)
	for _, place in spots do
		local f = FightService.SpawnEnemy(place.Def, level, at * CFrame.new(place.X, 0, place.Z) * CFrame.Angles(0, place.Turn or 0, 0), {
			Type = if place.Type then place.Type elseif type(type_) == "string" then type_ else nil,
			Pack = group.Name,
			Ground = if type(ground) == "string" then ground else nil,
			Stage = if type(stage) == "number" then stage else nil,
		})
		group.Alive[f] = true
		-- Gone without falling (a cleanup): counted as fallen, so the pack still comes back.
		f.Model.Destroying:Connect(function()
			if group.Alive[f] then
				group.Alive[f] = nil
				PackService.Down(group)
			end
		end)
	end
end

-- Whether a player within Near studs of the group's stop still owes its stretch's quota on Normal (a Hard run stands
-- its own Shades: StageService).
local function owed(group: Group): boolean
	local stage = group.Marker:GetAttribute("Stage")
	local at = Markers.At(group.Marker).Position
	for _, player in Players:GetPlayers() do
		local run, kills, quota = player:GetAttribute("StageRun"), player:GetAttribute("StageKills"), player:GetAttribute("StageQuota")
		local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if type(run) == "string" and run == `Normal {stage}` and type(kills) == "number" and type(quota) == "number" and kills < quota
			and root and (root.Position - at).Magnitude <= WorldConfig.Row.Waves.Near then
			return true
		end
	end
	return false
end

-- The Tell: each spot of the wave about to stand marked in grey on the floor for `seconds`.
local function tell(group: Group, seconds: number)
	local waves = group.Waves
	if waves == nil or seconds <= 0 then
		return
	end
	local at = Markers.At(group.Marker)
	local row = WorldConfig.Row
	for _, place in Waves.Spots(waves[group.Wave] or waves[1], row.Spread, row.Waves.Side, row.Waves.Far, row.Behind) do
		local mark = Instance.new("Part")
		mark.Name = "WaveTell"
		mark.Anchored, mark.CanCollide, mark.CanQuery, mark.CanTouch, mark.CastShadow = true, false, false, false, false
		mark.Material = Enum.Material.Neon
		mark.Color = Color3.fromRGB(150, 154, 162)
		mark.Shape = Enum.PartType.Cylinder
		mark.Size = Vector3.new(0.2, 4, 4)
		mark.CFrame = at * CFrame.new(place.X, 0.1, place.Z) * CFrame.Angles(0, 0, math.pi / 2)
		mark:SetAttribute("Pack", group.Name)
		mark.Parent = workspace
		task.delay(seconds, mark.Destroy, mark)
	end
end

-- The group's next wave, called: its Tell, then it stands `gap` seconds from now, unless another call overtakes it.
local function call(group: Group, gap: number)
	group.Due += 1
	local due = group.Due
	group.BackAt = workspace:GetServerTimeNow() + gap
	group.Marker:SetAttribute("BackAt", group.BackAt)
	local wait = WorldConfig.Row.Waves.Tell
	task.delay(math.max(0, gap - wait), function()
		if groups[group.Name] == group and group.Due == due then
			tell(group, math.min(wait, gap))
		end
	end)
	task.delay(gap, function()
		if groups[group.Name] == group and group.Due == due and next(group.Alive) == nil then
			stand(group)
		end
	end)
end

-- A stop that rests (nobody near owes): its first wave stands after Respawn, or after a Tell once someone who owes is near.
local function rest(group: Group)
	group.Wave = 1
	call(group, Cooldown.Wait(group.Kind))
	local due = group.Due
	task.spawn(function()
		while groups[group.Name] == group and group.Due == due and next(group.Alive) == nil do
			if owed(group) then
				call(group, WorldConfig.Row.Waves.Tell)
				return
			end
			task.wait(0.5)
		end
	end)
end

-- A Shade of `group` is down: when it was the last, the pack is back after the wait, or its next wave after the Gap.
function PackService.Down(group: Group)
	if next(group.Alive) ~= nil or group.BackAt ~= nil or groups[group.Name] ~= group then
		return
	end
	local waves = group.Waves
	if waves then
		local after = Waves.After(waves, group.Wave, owed(group))
		if after then
			group.Wave = after
			call(group, WorldConfig.Row.Waves.Gap)
		else
			rest(group)
		end
		return
	end
	local wait = Cooldown.Wait(group.Kind)
	group.BackAt = workspace:GetServerTimeNow() + wait
	group.Marker:SetAttribute("BackAt", group.BackAt)
	task.delay(wait, function()
		if groups[group.Name] == group and group.BackAt ~= nil and next(group.Alive) == nil then
			stand(group)
		end
	end)
end

-- Every pack from the markers, standing; the ones before are cleared first.
local function standAll()
	local old = groups
	groups = {}
	for _, group in old do
		for f in group.Alive do
			group.Alive[f] = nil -- cleared, not fallen: no comeback for a group the world replaced
			FightService.Remove(f)
		end
	end
	local function add(name: string, kind: string, marker: Instance)
		local group: Group = { Name = name, Kind = kind, Marker = marker, Alive = {}, BackAt = nil, Waves = if kind == "Pack" then wavesOf(marker) else nil, Wave = 1, Due = 0 }
		groups[name] = group
		stand(group)
	end
	for _, marker in Markers.All("Pack") do
		local number = marker:GetAttribute("Pack")
		add(`Pack {if type(number) == "number" then number else "?"}`, "Pack", marker)
	end
	for _, marker in Markers.All("Elite") do
		local stage = marker:GetAttribute("Stage")
		add(`Elite {if type(stage) == "number" then stage else "?"}`, "Elite", marker)
	end
end

local function packs(who: any): any
	local player = DebugService.ResolvePlayer(who)
	local list = {}
	local now = workspace:GetServerTimeNow()
	for name, group in groups do
		local spots = {}
		local hitBy = 0
		for f in group.Alive do
			table.insert(spots, f.Model:GetPivot().Position)
			hitBy += if player and f.Hitters[player] then 1 else 0
		end
		local gap = math.huge
		for i = 1, #spots do
			for j = i + 1, #spots do
				local d = spots[i] - spots[j]
				gap = math.min(gap, Vector3.new(d.X, 0, d.Z).Magnitude)
			end
		end
		local ring, rear = group.Marker:GetAttribute("Count"), group.Marker:GetAttribute("RearCount")
		local whole = (if type(ring) == "number" then ring else 1) + (if type(rear) == "number" and type(group.Marker:GetAttribute("Rear")) == "string" then rear else 0)
		table.insert(list, {
			Name = name,
			Def = group.Marker:GetAttribute("Def"),
			Level = group.Marker:GetAttribute("Level"),
			-- every Shade it stands whole: its ring's and its rear row's (AR58), or its wave's (TR69 B)
			Count = if group.Waves then Waves.Size(group.Waves[group.Wave] or group.Waves[1]) else whole,
			Wave = if group.Waves then group.Wave else nil,
			Waves = if group.Waves then #group.Waves else nil,
			Standing = #spots,
			Gap = if gap == math.huge then 0 else gap,
			BackIn = if group.BackAt then math.max(0, group.BackAt - now) else 0,
			Ground = group.Marker:GetAttribute("Ground"),
			Stage = group.Marker:GetAttribute("Stage"),
			At = Markers.At(group.Marker).Position, -- the marker, for a client that has the street streamed out
			HitBy = hitBy, -- its standing Shades the asking player's lead has hit: each one's fall pays them
		})
	end
	table.sort(list, function(a, b)
		return (a.Name :: string) < (b.Name :: string)
	end)
	return list
end

local function packBack(_who: any, name: any): any
	local group = if type(name) == "string" then groups[name] else nil
	if group == nil then
		return { Ok = false, Error = "NoPack" }
	elseif group.BackAt == nil then
		return { Ok = false, Error = "Standing" }
	end
	local left = math.max(0, group.BackAt - workspace:GetServerTimeNow())
	stand(group)
	return { Ok = true, Left = left }
end

local function packDefeat(_who: any, name: any): any
	local group = if type(name) == "string" then groups[name] else nil
	if group == nil then
		return { Ok = false, Error = "NoPack" }
	end
	local felled = 0
	for f in group.Alive do
		group.Alive[f] = nil
		FightService.Defeat(f)
		felled += 1
	end
	PackService.Down(group)
	return { Ok = true, Felled = felled }
end

function PackService.Start()
	FightService.Fell:Connect(function(f: FightService.Fighter)
		local group = if f.Pack then groups[f.Pack] else nil
		if group and group.Alive[f] then
			group.Alive[f] = nil
			PackService.Down(group)
		end
	end)
	WorldService.Laid:Connect(standAll)
	standAll()
	if RunService:IsStudio() then
		DebugService.Register("Packs", packs)
		DebugService.Register("PackDefeat", packDefeat)
		DebugService.Register("PackBack", packBack)
	end
end

return PackService
