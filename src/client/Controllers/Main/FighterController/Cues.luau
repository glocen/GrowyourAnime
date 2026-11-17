--!strict
-- Cues (client): plays the fight's layered cues (Config.Cues; docs/asset-requests.md, AR13) on the audio graph, as points
-- in the world. Rules.Sound says which cue a hit's beat or touch plays and when each layer starts. The engine's traps
-- (docs/research/sound.md, "The engine, for Faber"):
--   - one AudioPlayer is one voice, and Play() resumes instead of starting over, so each take keeps a pool of loaded
--     players, one per voice the cue allows; a play past the cap stops the cue's oldest;
--   - the spread is PlaybackSpeed, never a pitch shifter, whose window would put the layer late off its frame;
--   - two listeners of our own on the camera, one per bus (Config.Cues' Bus), each through its fader to the device, so
--     nothing rests on the default listener, and the Shades' bus ducks alone;
--   - the level: Config.Cues.Trim takes back the 2025 doubling of an AudioPlayer's volume.
--   Cues.Play("HeavyHit", where, { Strength = 0.8 })   now, or { In = 0.3 } with its moment that far ahead
--   Cues.Duck()                                        the player's own lead's hit: the Shades' bus goes down a moment

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config.Cues)
local SoundRule = require(ReplicatedStorage.Shared.Rules.Sound)

local Cues = {}

export type Options = {
	In: number?, -- seconds until the cue's moment (a beat's cue starts before it); 0 when left out
	Strength: number?, -- 0 to 1, for a layer that follows the hit's strength; 1 when left out
}

type Voice = {
	Player: AudioPlayer,
	Point: Attachment,
	Emitter: AudioEmitter,
	Free: number, -- os.clock() when it's done with its last play
	Thread: thread?, -- its scheduled start, while it waits
}
type Play = { Voices: { Voice }, Ends: number }

local BUSES = { "Lead", "Shade" }
local GROUP = "NL_Cues" -- the interaction group's prefix: a bus's listener hears only its own emitters

local random = Random.new()
local built = false
local faders: { [string]: AudioFader } = {}
local listeners: { [string]: AudioListener } = {}
-- pools[cue][layer][take]: that take's voices
local pools: { [string]: { { { Voice } } } } = {}
local plays: { [string]: { Play } } = {}
local last: { [string]: number } = {} -- the take each cue's layer played last, by `cue#layer`
local under = 1 -- every bus's share while a screen's sounds play above the fight (Sounds.Duck)
local ducked = 0 -- the Shades' duck's own count: a later duck's release replaces an earlier one's

local function wire(from: Instance, to: Instance)
	local w = Instance.new("Wire")
	w.SourceInstance = from
	w.TargetInstance = to
	w.Parent = to
end

local function pick(range: { number }): number
	local low, high = math.min(range[1], range[2]), math.max(range[1], range[2])
	return low + random:NextNumber() * (high - low)
end

-- A take other than the one this layer played last, when it has more than one.
local function takeOf(key: string, count: number): number
	local was = last[key]
	local k = random:NextInteger(1, count)
	if count > 1 and k == was then
		k = k % count + 1
	end
	last[key] = k
	return k
end

local function hear()
	local camera = workspace.CurrentCamera
	for _, listener in listeners do
		listener.Parent = camera
	end
end

local function fader(bus: string): AudioFader
	return faders[bus]
end

local function level(bus: string, share: number)
	local f = faders[bus]
	if f then
		f.Volume = share * under
	end
end

local function stop(voice: Voice)
	if voice.Thread then
		pcall(task.cancel, voice.Thread)
		voice.Thread = nil
	end
	voice.Player:Stop()
	voice.Free = 0
end

local function begin(voice: Voice, cue: Config.Cue, at: Vector3, speed: number, gain: number, offset: number)
	voice.Thread = nil
	local player = voice.Player
	if not player.IsReady then
		return
	end
	player:Stop()
	player.TimePosition = offset
	player.PlaybackSpeed = speed
	player.Volume = gain
	voice.Point.WorldPosition = at
	local near = math.max(cue.Near, 0)
	voice.Emitter:SetDistanceAttenuation({ [0] = 1, [near] = 1, [math.max(cue.Range, near + 1)] = 0 })
	player:Play()
end

-- The graph, every take's voices loaded: once, when the fight's controller starts.
function Cues.Preload()
	if built then
		return
	end
	built = true
	local out = Instance.new("AudioDeviceOutput")
	out.Name = "NL_CuesOut"
	out.Parent = SoundService
	for _, bus in BUSES do
		local listener = Instance.new("AudioListener")
		listener.Name = `{GROUP}{bus}`
		listener.AudioInteractionGroup = `{GROUP}{bus}`
		local f = Instance.new("AudioFader")
		f.Name = `{GROUP}{bus}`
		f.Parent = SoundService
		wire(listener, f)
		wire(f, out)
		listeners[bus] = listener
		faders[bus] = f
	end
	hear()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hear)
	for name, cue in Config.Cues do
		local layers = {}
		for i, layer in cue.Layers do
			local takes = {}
			for k, take in Config.Takes[layer.Takes] or {} do
				local voices = {}
				for v = 1, math.max(cue.Voices, 1) do
					local point = Instance.new("Attachment")
					point.Name = `{name}_{i}_{k}_{v}`
					local emitter = Instance.new("AudioEmitter")
					emitter.AudioInteractionGroup = `{GROUP}{cue.Bus}`
					emitter.Parent = point
					local player = Instance.new("AudioPlayer")
					player.Asset = `rbxassetid://{take.Id}`
					player.Parent = point
					wire(player, emitter)
					point.Parent = workspace.Terrain
					table.insert(voices, { Player = player, Point = point, Emitter = emitter, Free = 0, Thread = nil } :: Voice)
				end
				takes[k] = voices
			end
			layers[i] = takes
		end
		pools[name] = layers
		plays[name] = {}
	end
end

-- Plays cue `name` at `at`: each layer one of its takes, all at one speed and one volume picked for this play, each
-- started where Rules.Sound.Start puts it from the moment (`options.In` from now). False for an unknown cue.
function Cues.Play(name: string, at: Vector3, options: Options?): boolean
	local cue = Config.Cues[name]
	local layers = pools[name]
	if cue == nil or layers == nil then
		return false
	end
	local o: Options = options or {}
	local now = os.clock()
	local running = plays[name]
	for i = #running, 1, -1 do
		if running[i].Ends <= now then
			table.remove(running, i)
		end
	end
	while #running >= math.max(cue.Voices, 1) do
		local oldest = table.remove(running, 1) :: Play
		for _, voice in oldest.Voices do
			stop(voice)
		end
	end
	local speed, volume = pick(cue.Pitch), pick(cue.Volume)
	local play: Play = { Voices = {}, Ends = now }
	for i, layer in cue.Layers do
		local takes = Config.Takes[layer.Takes]
		local pool = layers[i]
		if takes == nil or pool == nil or #takes == 0 then
			continue
		end
		local k = takeOf(`{name}#{i}`, math.min(#takes, #pool))
		local take, voices = takes[k], pool[k]
		local gain = Config.Volume * Config.Trim * layer.Volume * volume * (if layer.Strength then math.clamp(o.Strength or 1, 0, 1) else 1)
		if gain <= 0 or voices == nil then
			continue
		end
		local voice = voices[1]
		for _, v in voices do
			if v.Free < voice.Free then
				voice = v
			end
		end
		stop(voice)
		local start = (o.In or 0) + SoundRule.Start(layer, take, speed)
		local offset = math.max(0, -start) * speed -- a start already past: in from where it would be by now
		if offset >= take.Seconds then
			continue
		end
		voice.Free = now + math.max(start, 0) + (take.Seconds - offset) / speed
		play.Ends = math.max(play.Ends, voice.Free)
		table.insert(play.Voices, voice)
		if start > 0 then
			voice.Thread = task.delay(start, begin, voice, cue, at, speed, gain, 0)
		else
			begin(voice, cue, at, speed, gain, offset)
		end
	end
	table.insert(running, play)
	return true
end

-- How far ahead of its moment cue `name` begins (Rules.Sound.Ahead), or nil for an unknown cue.
function Cues.Ahead(name: string): number?
	local cue = Config.Cues[name]
	return if cue then SoundRule.Ahead(cue) else nil
end

-- The player's own lead's hit: the Shades' bus down by Config.Cues.Duck's Db at once, held, then back over its Release.
function Cues.Duck()
	local duck = Config.Duck
	local f = faders.Shade
	if f == nil then
		return
	end
	ducked += 1
	local mine = ducked
	level("Shade", 10 ^ (math.min(duck.Db, 0) / 20))
	task.delay(duck.Hold, function()
		if ducked == mine and f.Parent then
			TweenService:Create(f, TweenInfo.new(math.max(duck.Release, 0)), { Volume = under }):Play()
		end
	end)
end

-- Every bus taken down by `db` under a screen's sounds (Sounds.Duck), 0 to put them back.
function Cues.Under(db: number)
	under = 10 ^ (math.min(db, 0) / 20)
	for _, bus in BUSES do
		level(bus, 1)
	end
end

-- For the self-test: a bus's fader, the plays of a cue still sounding, and how many of every voice are loaded.
Cues.Fader = fader
function Cues.Playing(name: string): number
	local now, count = os.clock(), 0
	for _, play in plays[name] or {} do
		if play.Ends > now then
			count += 1
		end
	end
	return count
end
function Cues.Ready(): (number, number)
	local ready, all = 0, 0
	for _, layers in pools do
		for _, takes in layers do
			for _, voices in takes do
				for _, voice in voices do
					all += 1
					if voice.Player.IsReady then
						ready += 1
					end
				end
			end
		end
	end
	return ready, all
end

return Cues
