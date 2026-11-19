--!strict
-- MusicController (client): the game's music (the director, 2026-11-19; Config.Music, where its ids are pasted;
-- Rules.Music). Twice a second it reads where the player is: a keeper's try (the Try attribute), a Tower run (Tower),
-- Lantern Row (north of the Festival Gate's line, the world folder's GateZ, as LightingController reads it), the
-- player's own plot (its floor, a few studs past its edge), or the Strip. That place's list plays, a track at a time in a
-- shuffle that never plays one twice running, with Config.Music.Gap of quiet between two. A change of place crosses
-- over Config.Music.Fade: the old track fades out as the new one fades in. A place with no track is silence; a track that
-- hasn't loaded within Config.Music.Load is skipped. Every number is read each frame, so a Tune is heard at once.
--   MusicController.Now() -> { Place, Id, Playing }   what's playing, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.Shared
local MusicConfig = require(Shared.Config.Music)
local Music = require(Shared.Rules.Music)
local Markers = require(Shared.World.Markers)

local MusicController = {}

local player = Players.LocalPlayer
local LOOK = 0.5 -- seconds between two reads of where the player is
local WORLD = "World" -- the world's folder: its GateZ is the festival gate's line, north of it the street
local PLOT_EDGE = 6 -- studs past the plot's floor that still count as on it
local GROUP = "GA_Music"

type Voice = { Sound: Sound, Place: string, Id: number, Share: number, Target: number, Started: number, Ended: boolean }

local random = Random.new()
local group: SoundGroup? = nil
local place = ""
local current: Voice? = nil
local fading: { Voice } = {}
local lastOf: { [string]: number } = {} -- each place's last track's index, so its next is another
local quietUntil = 0
local since = LOOK

local function listOf(name: string): MusicConfig.List?
	return (MusicConfig.Lists :: any)[name]
end

local function onPlot(at: Vector3): boolean
	local number = player:GetAttribute("Plot")
	local floor = if type(number) == "number" then Markers.Find("Plot", { Plot = number }) else nil
	if floor == nil or not floor:IsA("BasePart") then
		return false
	end
	local p = floor.CFrame:PointToObjectSpace(at)
	return math.abs(p.X) <= floor.Size.X / 2 + PLOT_EDGE and math.abs(p.Z) <= floor.Size.Z / 2 + PLOT_EDGE and p.Y > -20
end

local function placeNow(): string
	local camera = workspace.CurrentCamera
	local at = if camera then camera.Focus.Position else Vector3.zero
	local world = workspace:FindFirstChild(WORLD)
	local gateZ = if world then world:GetAttribute("GateZ") else nil
	return Music.Place({
		Try = player:GetAttribute("Try") ~= nil,
		Tower = player:GetAttribute("Tower") ~= nil,
		Row = type(gateZ) == "number" and at.Z < gateZ,
		Plot = onPlot(at),
	})
end

local function fadeOut(voice: Voice?)
	if voice then
		voice.Target = 0
		table.insert(fading, voice)
	end
end

-- The place's next track, begun at `share` (0 to fade in, 1 at once). Nothing when its list has none.
local function start(name: string, share: number)
	local list = listOf(name)
	local index = if list then Music.Next(list.Ids, lastOf[name] or 0, function(count: number): number
		return random:NextInteger(1, count)
	end) else nil
	local id = if list and index then Music.Id(list.Ids[index]) else nil
	if index == nil or id == nil then
		return
	end
	lastOf[name] = index
	local sound = Instance.new("Sound")
	sound.Name = `Music{id}`
	sound.SoundId = `rbxassetid://{id}`
	sound.Looped = false
	sound.Volume = 0
	sound.SoundGroup = group
	sound.Parent = group
	local voice: Voice = { Sound = sound, Place = name, Id = id, Share = share, Target = 1, Started = os.clock(), Ended = false }
	sound.Ended:Connect(function()
		voice.Ended = true
	end)
	sound:Play()
	current = voice
end

local function step(dt: number)
	since += dt
	if since >= LOOK then
		since = 0
		local now = placeNow()
		if now ~= place then
			place = now
			fadeOut(current)
			current = nil
			quietUntil = 0
			start(place, 0)
		end
	end
	local clock = os.clock()
	local voice = current
	if voice then
		local late = not voice.Sound.IsLoaded and clock - voice.Started > MusicConfig.Load
		if voice.Ended or late then
			if late then
				voice.Sound:Destroy()
			else
				fadeOut(voice)
			end
			current = nil
			quietUntil = clock + (if late then 0 else MusicConfig.Gap)
		end
	elseif clock >= quietUntil and place ~= "" then
		quietUntil = clock + MusicConfig.Gap -- an empty place tries again after a gap, so a pasted id is heard
		start(place, 1)
	end
	-- Every voice's share toward its target over Fade, its volume the fader's and its place's.
	local rate = dt / math.max(MusicConfig.Fade, 1e-3)
	local function level(each: Voice)
		local delta = each.Target - each.Share
		each.Share += math.clamp(delta, -rate, rate)
		local list = listOf(each.Place)
		each.Sound.Volume = MusicConfig.Volume * (if list then list.Volume else 1) * each.Share
	end
	if current then
		level(current)
	end
	for index = #fading, 1, -1 do
		local each = fading[index]
		level(each)
		if each.Share <= 0 then
			each.Sound:Destroy()
			table.remove(fading, index)
		end
	end
end

function MusicController.Now(): { Place: string, Id: number?, Playing: boolean }
	local voice = current
	return { Place = place, Id = if voice then voice.Id else nil, Playing = voice ~= nil and voice.Sound.IsPlaying }
end

function MusicController.Start()
	local made = Instance.new("SoundGroup")
	made.Name = GROUP
	made.Volume = 1
	made.Parent = SoundService
	group = made
	RunService.Heartbeat:Connect(step)
end

return MusicController
