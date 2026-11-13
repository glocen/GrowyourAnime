--!strict
-- Mixdown: the level check (docs/asset-requests.md, AR8 A). A take can't measure the game's loudness, because this PC's
-- sound processing compresses the loopback (TR4, research's pass, corrected). So each cue's own samples are mixed offline
-- at the time, gain, speed, cut and fades the game plays them with, and measured (Loudness): the reveal at each rarity,
-- and the fight. Studio, MCP execute_luau, in Edit or a playtest's server:
--   local Mixdown = require(game.ServerStorage.NL_Tools.Audio.Mixdown:Clone())
--   print(Mixdown.Report())
-- What it takes as given: a Sound's and a SoundGroup's Volume are linear amplitude, as Rules.Sound does; a tween's fade
-- is the TweenInfo default, quadratic out; a world cue within its Near plays at full volume (the fight's camera stands
-- well inside Haymaker's 30 studs). Read as one channel (Loudness). The engine's own mixing after the groups isn't in it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Shared = ReplicatedStorage.Shared
local SoundConfig = require(Shared.Config.Sounds)
local RevealConfig = require(Shared.Config.Reveal)
local Art = require(Shared.Config.RevealArt)
local RarityDefs = require(Shared.Definitions.Rarity)
local Reveal = require(Shared.Rules.Reveal)
local SoundRule = require(Shared.Rules.Sound)
local Loudness = require(game:GetService("ServerStorage").NL_Tools.Audio.Loudness) -- by its place: a clone has no parent

local RATE = 48000 -- points a second read from each file
local CHUNK = 8192 -- the most GetWaveformAsync returns in one call
local LOAD_TIMEOUT = 6
local TAIL = 0.4 -- seconds of the mix kept after its last sound ends

local Mixdown = {}

-- One sound in a mix: a cue's slice from `At` seconds, at `Gain` (linear) and `Speed`; cut at `Until`, or faded out over
-- `Out` from it; faded in over `In`; looped over its slice when `Loop`.
export type Event = { Cue: string, At: number, Gain: number, Speed: number, Until: number?, In: number?, Out: number?, Loop: boolean? }

local cache: { [string]: { number } } = {}

-- A cue's slice of its file at RATE, or an error naming it.
local function slice(name: string): { number }
	local kept = cache[name]
	if kept then
		return kept
	end
	local cue = (SoundConfig.Cues :: { [string]: SoundConfig.Cue })[name]
	assert(cue, `no cue "{name}" in Config.Sounds`)
	local player = Instance.new("AudioPlayer")
	player.Name = "NL_MixdownProbe"
	player.Asset = `rbxassetid://{cue.Id}`
	player.Parent = SoundService -- GetWaveformAsync needs it in the DataModel
	local started = os.clock()
	while not player.IsReady and os.clock() - started < LOAD_TIMEOUT do
		task.wait(0.03)
	end
	if not player.IsReady then
		player:Destroy()
		error(`{name} ({cue.Id}) didn't load`)
	end
	local to = math.min(cue.To, player.TimeLength)
	local samples: { number } = {}
	local from = cue.From
	while from < to - 1e-9 do
		local upTo = math.min(from + CHUNK / RATE, to)
		local count = math.max(1, math.floor((upTo - from) * RATE + 0.5))
		local ok, chunk = pcall(player.GetWaveformAsync, player, NumberRange.new(from, upTo), count)
		if not ok then
			player:Destroy()
			error(`{name}: {chunk}`)
		end
		table.move(chunk, 1, #chunk, #samples + 1, samples)
		from = upTo
	end
	player:Destroy()
	cache[name] = samples
	return samples
end

-- Where an event's sound has ended, in the mix's seconds.
local function ends(event: Event, length: number): number
	local natural = if event.Loop then math.huge else event.At + length / event.Speed
	local cut = if event.Until then event.Until + (event.Out or 0) else math.huge
	local finish = math.min(natural, cut)
	return if finish == math.huge then event.At + length else finish
end

-- The events mixed into one signal at RATE.
function Mixdown.Mix(events: { Event }): { number }
	local finish = 0
	for _, event in events do
		finish = math.max(finish, ends(event, #slice(event.Cue) / RATE))
	end
	local out = table.create(math.ceil((finish + TAIL) * RATE), 0)
	for _, event in events do
		local s = slice(event.Cue)
		local n = #s
		if n < 2 then
			continue
		end
		local start = math.floor(event.At * RATE + 0.5)
		local last = math.floor(ends(event, n / RATE) * RATE) - start
		for i = 0, last do
			local u = i * event.Speed
			if event.Loop then
				u %= n - 1
			elseif u >= n - 1 then
				break
			end
			local t = i / RATE
			local at = event.At + t
			local envelope = 1
			if event.In and event.In > 0 and t < event.In then
				local x = t / event.In
				envelope = 1 - (1 - x) * (1 - x) -- tweened up, quadratic out
			end
			if event.Until and at >= event.Until then
				local out = event.Out
				if out == nil or out <= 0 then
					break
				end
				local x = (at - event.Until) / out
				if x >= 1 then
					break
				end
				envelope *= (1 - x) * (1 - x) -- tweened down, quadratic out
			end
			local k = math.floor(u)
			local f = u - k
			local v = s[k + 1] * (1 - f) + s[k + 2] * f
			local index = start + i + 1
			if index >= 1 and index <= #out then
				out[index] += v * event.Gain * envelope
			end
		end
	end
	return out
end

-- The reveal's sounds at a rarity, as UI/Reveal plays them: Rules.Reveal.Cues, through the Reveal group's fader, with the
-- figure's own strike (Rook's, the default).
function Mixdown.RevealEvents(rarity: string, clip: string?): { Event }
	local r = (Art.Rarities :: any)[rarity]
	assert(r, `no rarity "{rarity}"`)
	local index = table.find(RarityDefs.Order, rarity) or 1
	local strike = RevealConfig.Sounds.Strike.Cues[clip or "RookReveal"]
	local cues = Reveal.Cues(r, rarity, index, strike, function(name: string): number
		local cue = (SoundConfig.Cues :: { [string]: SoundConfig.Cue })[name]
		return if cue then cue.To - cue.From else 0.5
	end)
	local events: { Event } = {}
	for _, cue in cues do
		local config = (SoundConfig.Cues :: { [string]: SoundConfig.Cue })[cue.Cue]
		table.insert(events, {
			Cue = cue.Cue,
			At = cue.At,
			Gain = SoundRule.Volume(config, cue.Db, true) * SoundConfig.Reveal,
			Speed = cue.Speed,
			Until = cue.Until,
			In = cue.In,
			Out = cue.Out,
			Loop = cue.Loop,
		})
	end
	return events
end

-- The fight's sounds: every world cue as the combat group plays it within its Near, at the middle of its pitch spread.
-- Each is a moment of its own (a cue's slice is under a second), so the fight's loudest is its loudest cue's.
function Mixdown.FightEvents(): { [string]: { Event } }
	local out: { [string]: { Event } } = {}
	for name, cue in SoundConfig.Cues :: { [string]: SoundConfig.Cue } do
		if not SoundRule.Screen(cue) then
			out[name] = { { Cue = name, At = 0, Gain = SoundRule.Volume(cue, 0, false) * SoundConfig.Combat, Speed = (cue.Pitch[1] + cue.Pitch[2]) / 2 } }
		end
	end
	return out
end

function Mixdown.Measure(events: { Event }): Loudness.Measure
	return Loudness.Measure(Mixdown.Mix(events), RATE)
end

local function fmt(x: number): string
	return if x == -math.huge then "-inf" else string.format("%.1f", x)
end

-- The level check's table: each fight cue, each rarity's reveal, and the reveal over the fight's loudest, by its
-- loudest 400 ms (momentary). Research's line (AR8 A): the reveal about 3 to 6 LU over the fight, true peak under -1 dBTP.
function Mixdown.Report(clip: string?): string
	local lines = { "the level check (Mixdown; one channel, the game's gains, offline):" }
	local fight = -math.huge
	local fightCue = ""
	for name, events in Mixdown.FightEvents() do
		local m = Mixdown.Measure(events)
		table.insert(lines, `fight {name}: momentary {fmt(m.Momentary)} LUFS, true peak {fmt(m.TruePeak)} dBTP`)
		if m.Momentary > fight then
			fight, fightCue = m.Momentary, name
		end
		task.wait()
	end
	for _, rarity in RarityDefs.Order do
		local m = Mixdown.Measure(Mixdown.RevealEvents(rarity, clip))
		local over = m.Momentary - fight
		table.insert(lines, string.format(
			"reveal %s: integrated %s, momentary %s, short-term %s LUFS; true peak %s dBTP (sample %s); %s LU over the fight's %s; %.1f s%s%s",
			rarity, fmt(m.Integrated), fmt(m.Momentary), fmt(m.ShortTerm), fmt(m.TruePeak), fmt(m.SamplePeak), fmt(over), fightCue, m.Seconds,
			if m.TruePeak >= -1 then "  TRUE PEAK OVER -1" else "",
			if over < 3 or over > 6 then "  OUTSIDE 3 TO 6" else ""
		))
		task.wait()
	end
	return table.concat(lines, "\n")
end

return Mixdown
