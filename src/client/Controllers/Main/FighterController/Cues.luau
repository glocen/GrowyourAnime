--!strict
-- Cues (client): plays the fight's layered cues (Config.Cues; docs/asset-requests.md, AR13) on the audio graph, as points
-- in the world. Rules.Sound says which cue a hit's beat or touch plays and when each layer starts. The engine's traps
-- (docs/research/sound.md, "The engine, for Faber"):
--   - one AudioPlayer is one voice, and Play() resumes instead of starting over, so each take keeps a pool of loaded
--     players, one per voice the cue allows; a play past the cap stops the cue's oldest;
--   - the spread is PlaybackSpeed, never a pitch shifter, whose window would put the layer late off its frame;
--   - two listeners of our own on the camera, one per bus (Config.Cues' Bus), each through its fader to the device, so
--     nothing rests on the default listener, and the Shades' bus ducks alone;
--   - the level: Config.Cues.Trim takes back the 2025 doubling of an AudioPlayer's volume (a player at Volume 1 plays
--     its file as it is, so a cue is 6 dB under its file: measured 2026-11-17); a library take has its own
--     gain inside its list (Rules.Sound.Level), and a player's volume stops at 3. While Config.Cues.Match is on, an
--     arrangement plays at its old cue's loudness (the A/B at matched level, for the listen);
--   - each bus ends in an AudioLimiter (Config.Cues.Limiter), after its fader: the rare coincidence of tops is caught
--     there, so the cues' levels are set by their relation (AR39, research on round 1);
--   - a library take plays its slice of its file (AR39): its PlaybackRegion is From to To, set once, and its fades are
--     tweens of its volume, as Rules.Sound.Run times them. A tween steps once a frame, so a rise under two frames isn't
--     drawn: such a slice is cut where its file is near silent;
--   - a play whose take isn't loaded is counted (Cues.Missed) and logged once a take, never dropped in silence;
--   - a play's layers are scheduled together on the mixer's clock, `Play(atTime)` from one GetMixerTime() reading, so
--     they keep their spacing to the sample; a frame's task.delay only where there's no mixer clock;
--   - a start the mixer holds can't be taken back (read on a client, 2026-11-17): Cancel() leaves it, Stop() only keeps
--     it silent while the player stays stopped, and a Play() before its time is taken as that same start. So a start is
--     handed over only Config.Cues.Lookahead before it (a thread waits until then, and a thread can be cancelled), and
--     a voice stopped with a start still held isn't played again until that time has passed. A play that finds every
--     voice of its take held is counted as missed.
--   Cues.Play("HeavyHit", where, { Strength = 0.8 })   now, or { In = 0.3 } with its moment that far ahead
--   Cues.Duck()                                        the player's own lead's hit: the Shades' bus goes down a moment
-- AR39's A/B: a pilot's cue plays as it was or as one of its arrangements, as Config.Cues.Use says, read at each play.

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
	Fade: thread?, -- its fade-out's scheduled start
	Tween: Tween?, -- its fade, while it runs
	Due: number, -- os.clock() when the start the mixer holds for it fires; 0 with none
	Held: number, -- os.clock() until which it isn't played again: a start taken back, still in the mixer
}
type Play = { Voices: { Voice }, Ends: number }

local BUSES = { "Lead", "Shade" }
local GROUP = "NL_Cues" -- the interaction group's prefix: a bus's listener hears only its own emitters
local FRAME = 1 / 60 -- a tween's step
local HOLD = 0.03 -- seconds past a held start's time before its voice plays again

local random = Random.new()
local built = false
local faders: { [string]: AudioFader } = {}
local limiters: { [string]: Instance } = {}
local listeners: { [string]: AudioListener } = {}
-- pools[cue][layer][take]: that take's voices
local pools: { [string]: { { { Voice } } } } = {}
local plays: { [string]: { Play } } = {}
local last: { [string]: number } = {} -- the take each cue's layer played last, by `cue#layer`
local under = 1 -- every bus's share while a screen's sounds play above the fight (Sounds.Duck)
local ducked = 0 -- the Shades' duck's own count: a later duck's release replaces an earlier one's
local missed = 0 -- plays whose take wasn't loaded
local told: { [number]: boolean } = {} -- the takes a miss was logged for

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
	if voice.Fade then
		pcall(task.cancel, voice.Fade)
		voice.Fade = nil
	end
	if voice.Tween then
		voice.Tween:Cancel()
		voice.Tween = nil
	end
	voice.Player:Stop()
	if voice.Due > os.clock() then
		voice.Held = voice.Due + HOLD
	end
	voice.Due = 0
	voice.Free = 0
end

local function miss(id: number, why: string)
	missed += 1
	if not told[id] then
		told[id] = true
		warn(`[NL] Cues: take {id} {why} ({missed} missed so far)`)
	end
end

local function fade(voice: Voice, to: number, seconds: number)
	if voice.Tween then
		voice.Tween:Cancel()
	end
	local tween = TweenService:Create(voice.Player, TweenInfo.new(math.max(seconds, 0), Enum.EasingStyle.Linear), { Volume = to })
	voice.Tween = tween
	tween:Play()
end

-- The mixer's clock, or nil where there's none (AR39: a play's layers are scheduled on it, sample-accurate). Its zero
-- is the engine's own: it read about -4.29e9 on this PC's client and ran a second a second (2026-11-17), so only a
-- reading that isn't a number counts as none.
local function mixerTime(): number?
	local ok, now = pcall(function(): any
		return (SoundService :: any):GetMixerTime()
	end)
	return if ok and type(now) == "number" and now == now then now else nil
end

-- Starts `voice` on its take `offset` into it (the file's seconds past its start, for a play already late): at
-- `target` on the mixer's clock when it's still ahead, or now.
local function begin(voice: Voice, cue: Config.Cue, take: Config.Take, at: Vector3, speed: number, gain: number, offset: number, target: number?)
	voice.Thread = nil
	local player = voice.Player
	if not player.IsReady then
		miss(take.Id, "wasn't loaded when it was due")
		return
	end
	local mixer = if target then mixerTime() else nil
	local delay = if target and mixer then math.max(target - mixer, 0) else 0
	local run = SoundRule.Run(take, offset, speed, FRAME)
	player:Stop()
	player.TimePosition = run.Position
	player.PlaybackSpeed = speed
	player.Volume = gain * run.Share
	voice.Point.WorldPosition = at
	local near = math.max(cue.Near, 0)
	voice.Emitter:SetDistanceAttenuation({ [0] = 1, [near] = 1, [math.max(cue.Range, near + 1)] = 0 })
	if target and delay > 0 then
		(player :: any):Play(target)
		voice.Due = os.clock() + delay
	else
		player:Play()
	end
	if run.In > 0 then
		if delay > 0 then
			voice.Thread = task.delay(delay, function()
				voice.Thread = nil
				fade(voice, gain, run.In)
			end)
		else
			fade(voice, gain, run.In)
		end
	end
	if run.OutAfter then
		voice.Fade = task.delay(delay + run.OutAfter, function()
			voice.Fade = nil
			fade(voice, 0, run.Out)
		end)
	end
end

-- One cue's voices under `key`, loading: a player a take a voice, a library take's on its slice of its file.
local function build(key: string, cue: Config.Cue)
	local layers = {}
	for i, layer in cue.Layers do
		local takes = {}
		for k, take in (Config.Takes :: { [string]: { Config.Take } })[layer.Takes] or {} do
			local voices = {}
			for v = 1, math.max(cue.Voices, 1) do
				local point = Instance.new("Attachment")
				point.Name = `{key}_{i}_{k}_{v}`
				local emitter = Instance.new("AudioEmitter")
				emitter.AudioInteractionGroup = `{GROUP}{cue.Bus}`
				emitter.Parent = point
				local player = Instance.new("AudioPlayer")
				player.Asset = `rbxassetid://{take.Id}`
				if take.From then
					player.PlaybackRegion = NumberRange.new(take.From, take.To or take.From + take.Seconds)
				end
				player.Parent = point
				wire(player, emitter)
				point.Parent = workspace.Terrain
				table.insert(voices, { Player = player, Point = point, Emitter = emitter, Free = 0, Due = 0, Held = 0 } :: Voice)
			end
			takes[k] = voices
		end
		layers[i] = takes
	end
	pools[key] = layers
	plays[key] = {}
end

-- The cue `name` plays now, and its voices' key: one of its arrangements while Config.Cues.Use names one (AR39's A/B),
-- or the cue as it was.
local function chosen(name: string): (string, Config.Cue?)
	local use = (Config.Use :: { [string]: string })[name]
	local set = Config.Arrangements[name]
	local cue = if use and set then set[use] else nil
	if cue and pools[`{name}@{use}`] then
		return `{name}@{use}`, cue
	end
	return name, (Config.Cues :: { [string]: Config.Cue })[name]
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
		local limiter = Instance.new("AudioLimiter")
		limiter.Name = `{GROUP}{bus}`
		limiter.MaxLevel = Config.Limiter.MaxLevel
		limiter.Release = Config.Limiter.Release
		limiter.Parent = SoundService
		wire(listener, f)
		wire(f, limiter)
		wire(limiter, out)
		listeners[bus] = listener
		faders[bus] = f
		limiters[bus] = limiter
	end
	hear()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hear)
	for name, cue in Config.Cues do
		build(name, cue)
	end
	for name, set in Config.Arrangements do
		for variant, cue in set do
			build(`{name}@{variant}`, cue)
		end
	end
end

-- Plays cue `name` at `at`: each layer one of its takes, all at one speed and one volume picked for this play, each
-- started where Rules.Sound.Start puts it from the moment (`options.In` from now). False for an unknown cue.
function Cues.Play(name: string, at: Vector3, options: Options?): boolean
	local key, cue = chosen(name)
	local layers = pools[key]
	if cue == nil or layers == nil then
		return false
	end
	local o: Options = options or {}
	local now = os.clock()
	local running = plays[key]
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
	local match = if key ~= name then SoundRule.Match(name, (Config.Use :: { [string]: string })[name]) else 1
	local mixer = mixerTime()
	local play: Play = { Voices = {}, Ends = now }
	for i, layer in cue.Layers do
		local takes = (Config.Takes :: { [string]: { Config.Take } })[layer.Takes]
		local pool = layers[i]
		if takes == nil or pool == nil or #takes == 0 then
			continue
		end
		local k = takeOf(`{key}#{i}`, math.min(#takes, #pool))
		local take, voices = takes[k], pool[k]
		local gain = SoundRule.Level(layer, take, volume, o.Strength) * match
		if gain <= 0 or voices == nil then
			continue
		end
		local voice: Voice? = nil
		for _, v in voices do
			if v.Held <= now and (voice == nil or v.Free < voice.Free) then
				voice = v
			end
		end
		if voice == nil then
			miss(take.Id, "had every voice held by a start taken back")
			continue
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
		-- on the mixer's clock: every layer's start counted from this play's one reading, handed over Lookahead before it
		local target = if mixer and start > 0 then mixer + start else nil
		local wait = if mixer then start - Config.Lookahead else start
		if wait > 0 then
			voice.Thread = task.delay(wait, begin, voice, cue, take, at, speed, gain, 0, target)
		else
			begin(voice, cue, take, at, speed, gain, offset, target)
		end
	end
	table.insert(running, play)
	return true
end

-- How far ahead of its moment cue `name` begins (Rules.Sound.Ahead), or nil for an unknown cue.
function Cues.Ahead(name: string): number?
	local _, cue = chosen(name)
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

-- For the self-test: a bus's fader, the plays of a cue still sounding, how many of every voice are loaded, and the
-- plays missed because their take wasn't.
Cues.Fader = fader
function Cues.Limiter(bus: string): Instance?
	return limiters[bus]
end
function Cues.Missed(): number
	return missed
end
-- A cue of the self-test's own, built under `name` and taken away again (a cue is nil to take it away).
function Cues.Try(name: string, cue: Config.Cue?)
	for _, layers in { pools[name] or {} } do
		for _, takes in layers do
			for _, voices in takes do
				for _, voice in voices do
					stop(voice)
					voice.Point:Destroy()
				end
			end
		end
	end
	pools[name], plays[name] = nil, nil
	if cue and built then
		build(name, cue)
	end
end
-- One voice of a cue's layer's take (its first, or its `nth`), for the self-test to read.
function Cues.Voice(name: string, layer: number, take: number, nth: number?): AudioPlayer?
	local voices = pools[name] and pools[name][layer] and pools[name][layer][take]
	local voice = voices and voices[nth or 1]
	return if voice then voice.Player else nil
end
function Cues.Playing(name: string): number
	local now, count = os.clock(), 0
	for _, play in plays[(chosen(name))] or {} do
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
