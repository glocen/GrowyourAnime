--!strict
-- CueCheck: AR39's gates read on the three pilots' cues and their arrangements (docs/asset-requests.md, AR39, "The
-- technical gates", "Research on round 1"). Each take's samples are read from its file, each cue is mixed as the engine
-- plays it (CueMix, with what it takes as given), and the mix is measured: numbers only, never audio. Studio, Edit
-- mode, MCP execute_luau. It outlasts one call, so it runs detached and keeps its answer under ServerStorage.NL_CueCheck:
--   local Check = require(game.ServerStorage.NL_Tools.Audio.CueCheck:Clone())
--   Check.Start()            -- returns at once
--   return Check.Status()    -- where it is
--   return Check.Report()    -- once done: the gates, a line each
--   return Check.Result()    -- the numbers, as JSON: every take alone, every cue with each take once, the overlaps
-- A cue is played at its loudest pick, the middle of its speed spread and full strength; play `k` of a cue takes each
-- of its lists' `k`th take, so every take is in a mix once. An overlap repeats a cue's hottest plays, which the engine
-- never does twice running: the worst case.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.Shared
local AUDIO = ServerStorage:WaitForChild("NL_Tools"):WaitForChild("Audio")
-- clones, so Rojo edits always load: Studio keeps a required module until it restarts
local Config = require(Shared.Config.Cues:Clone())
local Actions = require(Shared.Definitions.Actions)
local Measures = require(AUDIO.Measures:Clone())
local CueMix = require(AUDIO.CueMix:Clone())
CueMix.With({ Config = Config, Sound = require(Shared.Rules.Sound:Clone()), Loudness = require(AUDIO.Loudness:Clone()), Measures = Measures })

local RATE = 48000
local CHUNK = 8192 -- the most GetWaveformAsync returns in one call
local LOAD_TIMEOUT = 8
local HOLDER = "NL_CueCheck"
local PILOTS = { "LightHit", "HeavyHit", "ShadeSwipe" }
local APART = 0.01 -- a HeavyHit lands this far or more from a LightHit in the gate's overlap, s
local SWEEP, REACH = 0.005, 0.3 -- that overlap's offsets: their step, and how far before and after the LightHits, s

local CueCheck = {}

local function holder(): Folder
	local found = ServerStorage:FindFirstChild(HOLDER)
	if found and found:IsA("Folder") then
		return found
	end
	local folder = Instance.new("Folder")
	folder.Name = HOLDER
	folder.Parent = ServerStorage
	return folder
end

local function keep(name: string, value: string)
	local at = holder():FindFirstChild(name)
	if not (at and at:IsA("StringValue")) then
		at = Instance.new("StringValue")
		at.Name = name
		at.Parent = holder()
	end
	(at :: StringValue).Value = value
end

local function kept(name: string): string?
	local at = holder():FindFirstChild(name)
	return if at and at:IsA("StringValue") then at.Value else nil
end

local cache: { [string]: { number } | false } = {}

-- A take's samples at RATE: its slice of its file, or its whole file. Nil when it doesn't load.
local function read(take: Config.Take): { number }?
	local key = `{take.Id}:{take.From or 0}:{take.To or -1}`
	local was = cache[key]
	if was ~= nil then
		return was or nil
	end
	local player = Instance.new("AudioPlayer")
	player.Name = "NL_CueCheckProbe"
	player.Asset = `rbxassetid://{take.Id}`
	player.Parent = SoundService -- GetWaveformAsync needs it in the DataModel
	local started = os.clock()
	while not player.IsReady and os.clock() - started < LOAD_TIMEOUT do
		task.wait(0.03)
	end
	if not player.IsReady then
		player:Destroy()
		cache[key] = false
		return nil
	end
	local from = take.From or 0
	local to = math.min(take.To or player.TimeLength, player.TimeLength)
	local samples: { number } = {}
	local at = from
	while at < to - 1e-9 do
		local upTo = math.min(at + CHUNK / RATE, to)
		local count = math.max(1, math.floor((upTo - at) * RATE + 0.5))
		local ok, chunk = pcall(player.GetWaveformAsync, player, NumberRange.new(at, upTo), count)
		if not ok then
			player:Destroy()
			cache[key] = false
			return nil
		end
		table.move(chunk, 1, #chunk, #samples + 1, samples)
		at = upTo
	end
	player:Destroy()
	cache[key] = samples
	return samples
end

-- The shortest time between two light hits of one fighter, from the kits' own beats: inside an action, and from a
-- combo's last hit to its next first (Definitions.Actions).
function CueCheck.Spacing(): (number, string)
	local least, where = math.huge, ""
	for _, kit in Actions.Kits :: { [string]: { string } } do
		for _, id in kit do
			local action = Actions.ById[id]
			if action == nil then
				continue
			end
			local beats: { number } = {}
			for beat, hit in action.Hits do
				if not hit.Heavy and action.Beats[beat] then
					table.insert(beats, action.Beats[beat])
				end
			end
			table.sort(beats)
			for i = 2, #beats do
				if beats[i] - beats[i - 1] < least then
					least, where = beats[i] - beats[i - 1], id
				end
			end
			if #beats > 0 and action.Cooldown == 0 and action.CancelFrom + beats[1] - beats[#beats] < least then
				least, where = action.CancelFrom + beats[1] - beats[#beats], `{id}, chained`
			end
		end
	end
	return least, where
end

local function round(x: number, places: number?): number
	if x ~= x or x == math.huge then
		return 999
	elseif x == -math.huge then
		return -999
	end
	local p = 10 ^ (places or 2)
	return math.floor(x * p + 0.5) / p
end

-- The mean of levels in dB, by their energy.
local function mean(levels: { number }): number
	local sum = 0
	for _, x in levels do
		sum += 10 ^ (x / 10)
	end
	return if #levels > 0 and sum > 0 then 10 * math.log10(sum / #levels) else -math.huge
end

local function row(m: CueMix.Measure, r: CueMix.Render): { [string]: any }
	local spectrum = {}
	for i, x in m.Spectrum do
		spectrum[i] = round(x, 1)
	end
	return {
		Momentary = round(m.Momentary),
		ShortTerm = round(m.ShortTerm),
		Phone = round(m.Phone),
		TruePeak = round(m.TruePeak),
		PeakAt = round(m.PeakAt, 4),
		Under120 = round(m.Under120, 3),
		Narrow = round(m.Narrow, 1),
		NarrowAt = round(m.NarrowAt, 0),
		StepIn = round(r.In, 3),
		StepOut = round(r.Out, 3),
		StepFade = round(r.Fade, 3),
		Spectrum = spectrum,
	}
end

type Variant = {
	Name: string, -- "LightHit@Old", "LightHit@A1"
	Cue: Config.Cue,
	Renders: { CueMix.Render },
	Rows: { { [string]: any } },
	Peaks: { number }, -- each play's true peak, dBTP
	ShortTerm: number,
	Phone: number,
}

local function run(status: (string) -> ())
	local started = os.clock()
	local limit = Config.Limiter.MaxLevel
	local spacing, spacingOf = CueCheck.Spacing()
	local lines: { string } = {}
	local function say(line: string)
		table.insert(lines, line)
	end
	local function fmt(x: number): string
		return if x == -math.huge then "-inf" else string.format("%.1f", x)
	end

	-- the cues: each pilot as it was, and its arrangements
	local variants: { [string]: { Variant } } = {}
	local lists: { [string]: boolean } = {}
	for _, pilot in PILOTS do
		local set: { Variant } = {}
		local old = (Config.Cues :: { [string]: Config.Cue })[pilot]
		if old then
			table.insert(set, { Name = `{pilot}@Old`, Cue = old, Renders = {}, Rows = {}, Peaks = {}, ShortTerm = 0, Phone = 0 })
		end
		local names = {}
		for name in Config.Arrangements[pilot] or {} do
			table.insert(names, name)
		end
		table.sort(names)
		for _, name in names do
			table.insert(set, { Name = `{pilot}@{name}`, Cue = Config.Arrangements[pilot][name], Renders = {}, Rows = {}, Peaks = {}, ShortTerm = 0, Phone = 0 })
		end
		variants[pilot] = set
		for _, variant in set do
			for _, layer in variant.Cue.Layers do
				lists[layer.Takes] = true
			end
		end
	end

	-- 1. every take alone, at its own gain inside its list: its file as it is, times its Gain
	local takesOut: { [string]: any } = {}
	local missed: { string } = {}
	local alike: { string } = {}
	local full = 1 / (Config.Volume * Config.Trim * CueMix.Engine.PlayerGain)
	local names = {}
	for name in lists do
		table.insert(names, name)
	end
	table.sort(names)
	local source: CueMix.Source = read
	for _, name in names do
		status(`take by take: {name}`)
		local takes = (Config.Takes :: { [string]: { Config.Take } })[name]
		local rows, spectra = {}, {}
		for k, take in takes do
			local solo: Config.Cue = { Layers = { { Takes = name, At = 0, Volume = full } }, Bus = "Lead", Pitch = { 1, 1 }, Volume = { 1, 1 }, Voices = 1, Near = 30, Range = 160 }
			local render = CueMix.Play({ Cue = solo, Takes = { k } }, source, RATE)
			if render.Missed > 0 then
				table.insert(missed, `{name} {k} ({take.Id})`)
				rows[k] = { Id = take.Id, Loaded = false }
				continue
			end
			local m = CueMix.Measure(render, RATE, task.wait)
			local r = row(m, render)
			r.Id, r.Gain, r.Loaded, r.Seconds = take.Id, take.Gain or 1, true, take.Seconds
			rows[k] = r
			spectra[k] = m.Spectrum
		end
		local pairs_ = {}
		for a = 1, #takes do
			for b = a + 1, #takes do
				if spectra[a] and spectra[b] then
					local s = CueMix.Similar(spectra[a], spectra[b])
					table.insert(pairs_, { a, b, round(s, 3) })
					if s >= 0.97 or takes[a].Id == takes[b].Id then
						table.insert(alike, `{name} {a} and {b}: {string.format("%.3f", s)}{if takes[a].Id == takes[b].Id then ", one recording" else ""}`)
					end
				end
			end
		end
		takesOut[name] = { Takes = rows, Similar = pairs_ }
	end

	-- 2. every cue, each take once
	local cuesOut: { [string]: any } = {}
	local players = 0
	for _, pilot in PILOTS do
		for _, variant in variants[pilot] do
			status(`cue by cue: {variant.Name}`)
			local most, count = 1, 0
			for _, layer in variant.Cue.Layers do
				local n = #((Config.Takes :: { [string]: { Config.Take } })[layer.Takes] or {})
				most = math.max(most, n)
				count += n * math.max(variant.Cue.Voices, 1)
			end
			players += count
			local short, phone = {}, {}
			local worst = { TruePeak = -math.huge, PeakFrom = math.huge, PeakTo = -math.huge, Under120 = 0, Narrow = -math.huge, NarrowAt = 0, StepIn = 0, StepOut = 0, StepFade = 0, Missed = 0, Clamped = 0 }
			for k = 1, most do
				local order = table.create(#variant.Cue.Layers, k)
				local render = CueMix.Play({ Cue = variant.Cue, Takes = order }, source, RATE)
				local m = CueMix.Measure(render, RATE, task.wait)
				table.insert(variant.Renders, render)
				table.insert(variant.Rows, row(m, render))
				table.insert(variant.Peaks, m.TruePeak)
				table.insert(short, m.ShortTerm)
				table.insert(phone, m.Phone)
				worst.TruePeak = math.max(worst.TruePeak, m.TruePeak)
				worst.PeakFrom, worst.PeakTo = math.min(worst.PeakFrom, m.PeakAt), math.max(worst.PeakTo, m.PeakAt)
				worst.Under120 = math.max(worst.Under120, m.Under120)
				if m.Narrow > worst.Narrow then
					worst.Narrow, worst.NarrowAt = m.Narrow, m.NarrowAt
				end
				worst.StepIn, worst.StepOut, worst.StepFade = math.max(worst.StepIn, render.In), math.max(worst.StepOut, render.Out), math.max(worst.StepFade, render.Fade)
				worst.Missed += render.Missed
				worst.Clamped += render.Clamped
			end
			variant.ShortTerm, variant.Phone = mean(short), mean(phone)
			cuesOut[variant.Name] = {
				Plays = variant.Rows,
				ShortTerm = round(variant.ShortTerm),
				ShortTermFrom = round(math.min(table.unpack(short))),
				ShortTermTo = round(math.max(table.unpack(short))),
				Phone = round(variant.Phone),
				TruePeak = round(worst.TruePeak),
				PeakFrom = round(worst.PeakFrom, 4),
				PeakTo = round(worst.PeakTo, 4),
				Under120 = round(worst.Under120, 3),
				Narrow = round(worst.Narrow, 1),
				NarrowAt = round(worst.NarrowAt, 0),
				StepIn = round(worst.StepIn, 3),
				StepOut = round(worst.StepOut, 3),
				StepFade = round(worst.StepFade, 3),
				Players = count,
			}
			say(string.format(
				"%s: short-term %s LUFS (%s to %s), through the phone %s; true peak %s dBTP%s; top %.1f to %.1f ms from the moment%s; under 120 Hz %.0f%%; narrow %s dB at %.0f Hz%s; steps in %.3f, out %.3f, fade %.3f%s; %d players%s%s",
				variant.Name, fmt(variant.ShortTerm), fmt(math.min(table.unpack(short))), fmt(math.max(table.unpack(short))), fmt(variant.Phone),
				fmt(worst.TruePeak), if worst.TruePeak > -1 then "  GATE 3" else "",
				worst.PeakFrom * 1000, worst.PeakTo * 1000, if math.max(math.abs(worst.PeakFrom), math.abs(worst.PeakTo)) > 0.01 then "  GATE 2" else "",
				worst.Under120 * 100, fmt(worst.Narrow), worst.NarrowAt, if worst.Narrow >= 10 then "  GATE 7" else "",
				worst.StepIn, worst.StepOut, worst.StepFade, if math.max(worst.StepIn, worst.StepOut, worst.StepFade) > 0.25 then "  GATE 6" else "",
				count, if worst.Missed > 0 then `  {worst.Missed} MISSED` else "", if worst.Clamped > 0 then `  {worst.Clamped} PAST VOLUME 3` else ""
			))
		end
	end

	-- 3. the relations (gates 4 and 5), and the A/B's matched level
	local relations = {}
	local function of(pilot: string, old: boolean): { Variant }
		local out = {}
		for _, variant in variants[pilot] do
			if (string.sub(variant.Name, -4) == "@Old") == old then
				table.insert(out, variant)
			end
		end
		return out
	end
	for _, old in { true, false } do
		for _, light in of("LightHit", old) do
			for _, heavy in of("HeavyHit", old) do
				local over, phone = heavy.ShortTerm - light.ShortTerm, heavy.Phone - light.Phone
				local under = cuesOut[heavy.Name].Under120
				table.insert(relations, { Light = light.Name, Heavy = heavy.Name, Over = round(over), PhoneOver = round(phone) })
				say(string.format("%s over %s: %s LU%s; through the phone %s LU%s%s", heavy.Name, light.Name, fmt(over), if over < 3 or over > 5 then "  GATE 4" else "", fmt(phone), if phone < 2 then "  GATE 5" else "", if under > 0.5 then "  GATE 5 (under 120 Hz)" else ""))
			end
			for _, swipe in of("ShadeSwipe", old) do
				local under = light.ShortTerm - swipe.ShortTerm
				table.insert(relations, { Light = light.Name, Swipe = swipe.Name, Under = round(under) })
				say(string.format("%s under %s: %s LU%s", swipe.Name, light.Name, fmt(under), if under < 3 or under > 6 then "  GATE 4" else ""))
			end
		end
	end
	local match = {}
	for _, pilot in PILOTS do
		local was = of(pilot, true)[1]
		for _, variant in of(pilot, false) do
			if was then
				match[variant.Name] = round(was.ShortTerm - variant.ShortTerm)
			end
		end
	end

	-- 4. the bus in a fight's overlaps (gate 3), and what its limiter takes
	local function hottest(variant: Variant, nth: number): CueMix.Render
		local order = {}
		for i in variant.Peaks do
			order[i] = i
		end
		table.sort(order, function(a, b)
			return variant.Peaks[a] > variant.Peaks[b]
		end)
		return variant.Renders[order[(nth - 1) % #order + 1]]
	end
	local function peakOf(parts: { { Render: CueMix.Render, At: number } }): number
		return CueMix.TruePeak(CueMix.Mix(parts, RATE))
	end
	local function quick(parts: { { Render: CueMix.Render, At: number } }): number
		local most = 0
		for _, v in CueMix.Mix(parts, RATE).Samples do
			most = math.max(most, math.abs(v))
		end
		return most
	end
	local overlaps = {}
	local function taken(peak: number): number
		return math.max(peak - limit, 0)
	end
	for _, old in { true, false } do
		for _, light in of("LightHit", old) do
			status(`overlaps: {light.Name}`)
			-- six in a row at the fastest spacing, takes turning from the hottest
			local six = {}
			for i = 1, 6 do
				table.insert(six, { Render = hottest(light, i), At = (i - 1) * spacing })
			end
			local row6 = peakOf(six)
			-- two and three on one moment (several targets struck by one beat), at 0, 5 and 10 ms
			local together = {}
			for _, n in { 2, 3 } do
				local most = -math.huge
				for _, gap in { 0, 0.005, 0.01 } do
					local parts = {}
					for i = 1, n do
						table.insert(parts, { Render = hottest(light, i), At = (i - 1) * gap })
					end
					most = math.max(most, peakOf(parts))
				end
				together[n] = most
				task.wait()
			end
			overlaps[light.Name] = { Six = round(row6), SixTaken = round(taken(row6)), Two = round(together[2]), TwoTaken = round(taken(together[2])), Three = round(together[3]), ThreeTaken = round(taken(together[3])) }
			say(string.format("%s, six at %.3f s: bus %s dBTP, the limiter takes %.1f dB%s; two on one moment %s (%.1f), three %s (%.1f)", light.Name, spacing, fmt(row6), taken(row6), if row6 > -1 then "  GATE 3" else "", fmt(together[2]), taken(together[2]), fmt(together[3]), taken(together[3])))
			for _, heavy in of("HeavyHit", old) do
				local two = { { Render = hottest(light, 1), At = 0 }, { Render = hottest(light, 2), At = spacing } }
				local worst, worstAt = -1, 0
				local offset = -REACH
				local n = 0
				while offset <= spacing + REACH do
					if math.abs(offset) >= APART - 1e-9 and math.abs(offset - spacing) >= APART - 1e-9 then
						local q = quick({ two[1], two[2], { Render = hottest(heavy, 1), At = offset } })
						if q > worst then
							worst, worstAt = q, offset
						end
					end
					offset += SWEEP
					n += 1
					if n % 12 == 0 then
						task.wait()
					end
				end
				local apart = peakOf({ two[1], two[2], { Render = hottest(heavy, 1), At = worstAt } })
				local on = peakOf({ two[1], two[2], { Render = hottest(heavy, 1), At = 0 } })
				overlaps[`{heavy.Name} over {light.Name}`] = { Peak = round(apart), At = round(worstAt, 3), Taken = round(taken(apart)), OnTheMoment = round(on), OnTheMomentTaken = round(taken(on)) }
				say(string.format("%s over two %s: bus %s dBTP at %+.0f ms, the limiter takes %.1f dB%s; on one moment %s (%.1f)", heavy.Name, light.Name, fmt(apart), worstAt * 1000, taken(apart), if apart > -1 or taken(apart) > 3 then "  GATE 3" else "", fmt(on), taken(on)))
			end
		end
	end

	-- the whole
	table.insert(lines, 1, string.format("AR39's gates on Config.Cues (CueCheck; offline, one channel, as the engine plays them): %d takes missed%s; %d players for these cues; the fastest light hits %.4f s apart (%s); the limiter at %.1f dB", #missed, if #missed > 0 then " (" .. table.concat(missed, ", ") .. ")" else "", players, spacing, spacingOf, limit))
	table.insert(lines, 2, string.format("taken as given: an AudioPlayer at Volume 1 plays its file x%.0f (measured), a fade steps once a frame%s, a slice stops at its To, a cue inside its Near is at full volume", CueMix.Engine.PlayerGain, if CueMix.Engine.Stepped then ", each step at once" else ", drawn as its line"))
	say(if #alike > 0 then "gate 8, takes alike (0.97 or more) or of one recording: " .. table.concat(alike, "; ") else "gate 8: no two takes of a list alike (all under 0.97), none of one recording")
	say(string.format("measured in %.0f s", os.clock() - started))
	local centres = {}
	for i, c in Measures.Centres do
		centres[i] = round(c, 0)
	end
	keep("Report", table.concat(lines, "\n"))
	keep("Result", HttpService:JSONEncode({
		Made = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		Rate = RATE,
		Engine = CueMix.Engine,
		Spacing = round(spacing, 4),
		SpacingOf = spacingOf,
		Limiter = Config.Limiter,
		Centres = centres,
		Missed = missed,
		Players = players,
		Takes = takesOut,
		Cues = cuesOut,
		Relations = relations,
		Match = match,
		Overlaps = overlaps,
	}))
end

-- Starts the check, detached. Its answer stays under ServerStorage.NL_CueCheck until the next Start.
function CueCheck.Start()
	holder():ClearAllChildren()
	keep("Status", "starting")
	task.spawn(function()
		local ok, problem = xpcall(function()
			run(function(where: string)
				keep("Status", `running: {where}`)
			end)
		end, debug.traceback)
		keep("Status", if ok then "done" else "failed: " .. tostring(problem))
	end)
end

function CueCheck.Status(): string
	return kept("Status") or "not started"
end

function CueCheck.Report(): string
	return kept("Report") or CueCheck.Status()
end

-- The numbers as JSON, or characters `from` to `to` of them, and their whole length.
function CueCheck.Result(from: number?, to: number?): (string, number)
	local all = kept("Result") or ""
	return if from then string.sub(all, from, to or #all) else all, #all
end

return CueCheck
