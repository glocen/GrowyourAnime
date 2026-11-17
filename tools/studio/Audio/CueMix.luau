--!strict
-- CueMix (pure): Config.Cues' cues mixed as FighterController/Cues plays them, and the numbers AR39's gates are read on
-- (docs/asset-requests.md, AR39, "The technical gates" and "Research on round 1"). CueCheck reads each take's samples in
-- Studio and hands them in; the cases are in LogicTestService/Cases/Audio.luau.
-- What it takes as given (Engine, below; each one a line in the report):
--   - an AudioPlayer at Volume 1 plays its file's samples as they are, and so do its emitter, listener, fader and
--     limiter under its limit (measured with an AudioAnalyzer at each, 2026-11-17: -0.04 dB at 10 and 29 studs; an
--     emitter on the listener itself reads 8.5 dB down, which no fight's cue is). A player's volume stops at 3;
--   - a fade is a tween: its volume steps once a frame, each step at once (the engine may smooth a step; unverified, so
--     the step is the worst case). A rise Rules.Sound.Run doesn't draw isn't drawn here either;
--   - a library slice stops at its To (its player's PlaybackRegion);
--   - a cue within its Near plays at full volume, one channel, and its bus's fader and listener add nothing;
--   - a play's layers start on their sample (the mixer's clock), the moment at time 0.
-- One play: Play. Several, each at its own time: Mix of their renders. A mix's numbers: Measure.

local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Cues)
local SoundRule = require(Shared.Rules.Sound)
local Loudness = require(ServerStorage.NL_Tools.Audio.Loudness) -- by its place: a clone has no parent
local Measures = require(ServerStorage.NL_Tools.Audio.Measures)

local CueMix = {}

-- Studio keeps a required module until it restarts, so an edit to one of these wouldn't be read: CueCheck hands in
-- clones made from the files as they are now.
function CueMix.With(parts: { Config: any?, Sound: any?, Loudness: any?, Measures: any? })
	Config = parts.Config or Config
	SoundRule = parts.Sound or SoundRule
	Loudness = parts.Loudness or Loudness
	Measures = parts.Measures or Measures
end

CueMix.Engine = {
	PlayerGain = 1, -- an AudioPlayer's samples at Volume 1, of its file's (measured: 1)
	MaxVolume = 3, -- an AudioPlayer's Volume stops here
	Frame = 1 / 60, -- a tween's step
	Stepped = true, -- a volume step lands at once; false draws every fade as its straight line
}
CueMix.ShortTerm = 3 -- seconds a cue's short-term loudness is read over
CueMix.Phone = { High = 200, Low = 8000 } -- the phone's curve: a high-pass and a low-pass, Hz (gate 5)
CueMix.Narrow = { 2000, 6000 } -- the bands a narrow peak is looked for in, Hz (gate 7)
CueMix.Lead, CueMix.Tail = 0.02, 0.05 -- silence kept before a render's first sound and after its last, s

-- A take's samples at the mix's rate: its slice of its file, From to To (one of ours: its whole file). Nil when it
-- didn't load.
export type Source = (take: Config.Take) -> { number }?
-- One play of a cue: its layers' takes by number (each list's `k`th, wrapped), its speed, its volume and its strength.
-- Gain multiplies every layer's level before the player's cap (the A/B's matched level).
export type Play = { Cue: Config.Cue, Takes: { number }?, Speed: number?, Volume: number?, Strength: number?, Gain: number? }
-- A render: samples from `Origin` seconds (the cue's moment is 0), and its edges (gate 6): the step into a layer's
-- first sample (In) and out of its last (Out), of that layer's own top, the most of its layers; and a fade's largest
-- step (Fade), of full scale. Missed counts the takes that didn't load, Clamped the layers past the player's cap.
export type Render = { Samples: { number }, Origin: number, In: number, Out: number, Fade: number, Missed: number, Clamped: number }
export type Measure = {
	Momentary: number, -- the loudest 400 ms, LUFS
	ShortTerm: number, -- over CueMix.ShortTerm seconds, LUFS
	Phone: number, -- the same through the phone's curve, LUFS
	TruePeak: number, -- dBTP
	SamplePeak: number, -- dBFS
	PeakAt: number, -- seconds after the cue's moment
	Under120: number, -- the share of its energy under 120 Hz
	Spectrum: { number }, -- dB per third-octave band (Measures.Centres)
	Narrow: number, -- the most a band in CueMix.Narrow stands over its higher neighbour, dB
	NarrowAt: number, -- that band's centre, Hz
}

local function butterworth(kind: string, hz: number, rate: number): Loudness.Biquad
	local w = 2 * math.pi * hz / rate
	local cos, alpha = math.cos(w), math.sin(w) / (2 * math.sqrt(0.5))
	local a0 = 1 + alpha
	local b1 = if kind == "High" then -(1 + cos) else 1 - cos
	local b0 = math.abs(b1) / 2
	return { B0 = b0 / a0, B1 = b1 / a0, B2 = b0 / a0, A1 = -2 * cos / a0, A2 = (1 - alpha) / a0 }
end

-- The signal through the phone's curve: a second-order Butterworth high-pass, then low-pass.
function CueMix.ThroughPhone(samples: { number }, rate: number): { number }
	return Loudness.Filter(butterworth("Low", CueMix.Phone.Low, rate), Loudness.Filter(butterworth("High", CueMix.Phone.High, rate), samples))
end

-- A layer's share of its volume `t` seconds after its start, as the engine's tweens draw `run`.
local function envelope(run: SoundRule.Run, t: number): number
	local engine = CueMix.Engine
	local frame = engine.Frame
	local function drawn(seconds: number): number
		return if engine.Stepped then math.floor(seconds / frame + 1e-9) * frame else seconds
	end
	local v = 1
	if run.In > 0 then
		v = run.Share + (1 - run.Share) * math.min(drawn(t) / run.In, 1)
	end
	if run.OutAfter and t >= run.OutAfter then
		v *= math.max(1 - drawn(t - run.OutAfter) / math.max(run.Out, 1e-9), 0)
	end
	return v
end

-- One play of a cue, its moment at 0.
function CueMix.Play(play: Play, source: Source, rate: number): Render
	local cue = play.Cue
	local speed = play.Speed or (cue.Pitch[1] + cue.Pitch[2]) / 2
	local volume = play.Volume or math.max(cue.Volume[1], cue.Volume[2])
	local engine = CueMix.Engine
	type Event = { Samples: { number }, Start: number, Gain: number, Run: SoundRule.Run }
	local events: { Event } = {}
	local missed, clamped = 0, 0
	local first, last = 0, 0
	for i, layer in cue.Layers do
		local takes = (Config.Takes :: { [string]: { Config.Take } })[layer.Takes]
		if takes == nil or #takes == 0 then
			continue
		end
		local take = takes[((if play.Takes then play.Takes[i] or 1 else 1) - 1) % #takes + 1]
		local level = SoundRule.Level(layer, take, volume, play.Strength) * (play.Gain or 1)
		if level <= 0 then
			continue
		end
		if level > engine.MaxVolume then
			clamped += 1
			level = engine.MaxVolume
		end
		local samples = source(take)
		if samples == nil or #samples < 2 then
			missed += 1
			continue
		end
		local start = SoundRule.Start(layer, take, speed)
		table.insert(events, { Samples = samples, Start = start, Gain = level * engine.PlayerGain, Run = SoundRule.Run(take, 0, speed, engine.Frame) })
		first = math.min(first, start)
		last = math.max(last, start + #samples / rate / speed)
	end
	local origin = first - CueMix.Lead
	local out = table.create(math.max(math.ceil((last + CueMix.Tail - origin) * rate), 1), 0)
	local stepIn, stepOut, stepFade = 0, 0, 0
	for _, event in events do
		local s = event.Samples
		local n = #s
		local base = math.floor((event.Start - origin) * rate + 0.5)
		local was, share = 0, envelope(event.Run, 0)
		local own: { number } = {}
		local i = 0
		while true do
			local u = i * speed
			if u > n - 1 then
				break
			end
			local k = math.floor(u)
			local f = u - k
			local e = envelope(event.Run, i / rate)
			local v = (s[k + 1] * (1 - f) + (s[k + 2] or 0) * f) * event.Gain * e
			if e ~= share then
				stepFade = math.max(stepFade, math.abs(v - was))
				share = e
			end
			own[i + 1] = v
			out[base + i + 1] += v
			was = v
			i += 1
		end
		-- its edges: from silence into its first sample, and from its last into silence, of its own top
		local count = #own
		while count > 0 and own[count] == 0 do
			count -= 1
		end
		local top = 0
		for j = 1, count do
			top = math.max(top, math.abs(own[j]))
		end
		if top > 0 then
			stepIn = math.max(stepIn, math.abs(own[1]) / top)
			stepOut = math.max(stepOut, math.abs(own[count]) / top)
		end
	end
	return { Samples = out, Origin = origin, In = stepIn, Out = stepOut, Fade = stepFade, Missed = missed, Clamped = clamped }
end

-- Renders laid over each other, each one's moment at its own time: the bus's signal, from `Origin`.
function CueMix.Mix(parts: { { Render: Render, At: number } }, rate: number): Render
	local first, last = math.huge, -math.huge
	for _, part in parts do
		local from = part.At + part.Render.Origin
		first = math.min(first, from)
		last = math.max(last, from + #part.Render.Samples / rate)
	end
	if #parts == 0 then
		first, last = 0, 0
	end
	local out = table.create(math.max(math.ceil((last - first) * rate) + 1, 1), 0)
	local mix: Render = { Samples = out, Origin = first, In = 0, Out = 0, Fade = 0, Missed = 0, Clamped = 0 }
	for _, part in parts do
		local base = math.floor((part.At + part.Render.Origin - first) * rate + 0.5)
		for i, v in part.Render.Samples do
			out[base + i] += v
		end
		mix.In, mix.Out, mix.Fade = math.max(mix.In, part.Render.In), math.max(mix.Out, part.Render.Out), math.max(mix.Fade, part.Render.Fade)
		mix.Missed += part.Render.Missed
		mix.Clamped += part.Render.Clamped
	end
	return mix
end

-- A band's stand over its higher neighbour, the most of the bands inside CueMix.Narrow: a narrow peak is one band over
-- both its neighbours (gate 7).
function CueMix.NarrowPeak(spectrum: { number }): (number, number)
	local most, at = -math.huge, 0
	for b = 2, #spectrum - 1 do
		local centre = Measures.Centres[b]
		if centre >= CueMix.Narrow[1] and centre <= CueMix.Narrow[2] then
			local over = spectrum[b] - math.max(spectrum[b - 1], spectrum[b + 1])
			if over > most then
				most, at = over, centre
			end
		end
	end
	return most, at
end

-- The cosine similarity of two spectra, on magnitudes (10^(dB/20)), as tools/audio/ar39_rank.py reads it (gate 8).
function CueMix.Similar(a: { number }, b: { number }): number
	local dot, aa, bb = 0, 0, 0
	for i = 1, math.min(#a, #b) do
		local x, y = 10 ^ (a[i] / 20), 10 ^ (b[i] / 20)
		dot += x * y
		aa += x * x
		bb += y * y
	end
	return if aa > 0 and bb > 0 then dot / math.sqrt(aa * bb) else 0
end

-- A render's numbers. `pause`, if given, is called between the heavy steps (Studio passes task.wait).
function CueMix.Measure(render: Render, rate: number, pause: (() -> ())?): Measure
	local samples = render.Samples
	local slice = Measures.Slice(samples, rate, 0, #samples, pause, true)
	local narrow, at = CueMix.NarrowPeak(slice.Spectrum)
	return {
		Momentary = slice.Loudness,
		ShortTerm = Loudness.Over(samples, rate, CueMix.ShortTerm),
		Phone = Loudness.Over(CueMix.ThroughPhone(samples, rate), rate, CueMix.ShortTerm),
		TruePeak = slice.TruePeak,
		SamplePeak = slice.SamplePeak,
		PeakAt = render.Origin + slice.SamplePeakAt,
		Under120 = slice.Under120,
		Spectrum = slice.Spectrum,
		Narrow = narrow,
		NarrowAt = at,
	}
end

-- The true peak of a render alone, dBTP, read only around its loudest samples (an overlap's sweep reads many).
function CueMix.TruePeak(render: Render): number
	return Loudness.TruePeak(render.Samples)
end

return CueMix
