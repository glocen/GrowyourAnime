--!strict
-- PackService (server): the Shades of Lantern Row (docs/design.md, "The world, in grey"). Each Pack marker stands Count
-- Shades of its Def at its Level round it (Rules.Fight.PackRing, Config.World.Row.Spread apart), and each Elite marker
-- one, a stage's ("Elite 1" to "Elite 3", TR43). Every Shade carries its marker's Stage.
-- A pack belongs to everyone: FightService shares its notice and keeps every hitter. When a pack's last Shade falls it's
-- back Config.World.Row.Respawn seconds later; an elite, Config.World.Row.Back.Elite later, each one timer for the whole
-- server (TR10, Rules.Cooldown). While a group is down its marker's BackAt attribute holds the server time it's back, so
-- every client shows when (DownController). The world laid again (WorldService.Laid) stands every pack anew on its moved marker.
-- Studio:
--   NL_Debug:Invoke("Packs")                  each pack: its marker, Shades standing, the gap between them, when it's back
--   NL_Debug:Invoke("PackDefeat", "Pack 1")   fells that pack's Shades at once, for tests
--   NL_Debug:Invoke("PackBack", "Elite 2")    stands a group that's down at once, its timer cut short

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Fight = require(Shared.Rules.Fight)
local Cooldown = require(Shared.Rules.Cooldown)
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
}

local groups: { [string]: Group } = {}

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
	local defs = Fight.PackDefs(def, n, if type(with) == "string" then with else nil, if type(withCount) == "number" then withCount else nil)
	for index, offset in Fight.PackRing(n, WorldConfig.Row.Spread) do
		local f = FightService.SpawnEnemy(defs[index], level, at * CFrame.new(offset[1], 0, offset[2]), {
			Type = if type(type_) == "string" then type_ else nil,
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

-- A Shade of `group` is down: when it was the last, the pack is back after the wait.
function PackService.Down(group: Group)
	if next(group.Alive) ~= nil or group.BackAt ~= nil or groups[group.Name] ~= group then
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
		local group: Group = { Name = name, Kind = kind, Marker = marker, Alive = {}, BackAt = nil }
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
		table.insert(list, {
			Name = name,
			Def = group.Marker:GetAttribute("Def"),
			Level = group.Marker:GetAttribute("Level"),
			Count = group.Marker:GetAttribute("Count") or 1,
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
