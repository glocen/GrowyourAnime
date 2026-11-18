--!strict
-- Audition: finds the sound audition panel's candidates (docs/test-requests.md, TR42; Config.Audition). For each pilot,
-- Library.Search over every author on research's words, the words' finds taken in turn, so each keeps the library's own
-- order (the library gives no rating to order by: a find carries a title, an author, a description and a whole-second
-- length, read 2026-11-18). Left out before the director sees it, by number and title: a title or description that
-- names another work, a title of gore (AGENTS.md rules 3 and 4), of music or of a voice, a title the filter hid, one that
-- doesn't load, one whose first event is too long for its cue, and one the match can't bring to its level (a player's
-- volume stops at 10) or keep under the ceiling. A candidate is its first event, whole, cut only at its head:
--   a contact's (LightHit, HeavyHit) top lands within Config.Audition.Top of its start, the cut on the quietest sample in
--   reach; a beat's (ShadeSwipe) keeps its rise, and the engine starts it ahead by its top (Lead "Peak").
-- Its loudness is read as CueMix reads a cue: short-term over CueMix.ShortTerm, at the engine's Trim. Studio, Edit mode,
-- MCP execute_luau. It outlasts one call, so it runs detached:
--   local Audition = require(game.ServerStorage.NL_Tools.Audio.Audition:Clone())
--   Audition.Start()           -- returns at once
--   return Audition.Status()
--   return Audition.Report()   -- once done: each cue's count and level, and what was left out, by number and title
-- Its answer stays under ServerStorage.NL_Audition (Candidates, a JSON StringValue): a playtest copies it, and the
-- server's AuditionService hands it to the panel. Audition.Clear() takes it away.

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local Shared = game:GetService("ReplicatedStorage").Shared

local AUDIO = ServerStorage:WaitForChild("NL_Tools"):WaitForChild("Audio")
local function fresh(name: string): any
	return require(AUDIO:WaitForChild(name):Clone()) -- a clone, so Rojo edits always load
end
local Library = fresh("Library")
local Shortlist = fresh("Shortlist")
local CueMix = fresh("CueMix")
local Loudness = require(AUDIO:WaitForChild("Loudness")) :: any
local Config = require(Shared.Config.Audition:Clone()) :: any
local Cues = require(Shared.Config.Cues:Clone()) :: any
CueMix.With({ Config = Cues })

local FOLDER = "NL_Audition"
local RATE = 32000 -- samples a second read, as CueCheck reads
local CHUNK = 8192 -- the most GetWaveformAsync returns a call
local LOAD = 6 -- s a file has to load
local READ = 5 -- s read at most from a candidate's file: longer than every cap
local WINDOW = 0.005 -- s an envelope step

-- Title words of music or a voice (Shortlist's junk list, its jokes left in: the director's ear judges those).
local VOICE_MUSIC = {
	"remix", "song", "music", "theme", "ost", "soundtrack", "anthem", "bass boosted", "voice", "voices", "vocal",
	"talking", "speech", "laugh", "laughing", "cry", "crying", "male", "female", "man", "woman", "girl", "boy", "grunt",
	"yell", "shout", "kiai", "efforts", "scream", "moan", "groan", "heh",
}

local Audition = {}

export type Candidate = {
	Number: number, -- its place in its cue's list, from 1
	Id: number,
	Title: string,
	Author: string,
	Licensed: boolean,
	Keyword: string,
	From: number, -- its slice of its file, s
	To: number,
	Seconds: number,
	Peak: number, -- s from its start to its top
	Out: number, -- its fade at its end, s: 0 when its file ends there
	Loud: number, -- its short-term loudness at layer Volume 1, LUFS
	Top: number, -- its true peak at layer Volume 1, dBTP
}
export type Left = { Id: number, Title: string, Why: string }

local function holder(): Folder
	local folder = ServerStorage:FindFirstChild(FOLDER)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = ServerStorage
	end
	return folder :: Folder
end

local function keep(name: string, value: string)
	local at = holder():FindFirstChild(name)
	if at == nil then
		at = Instance.new("StringValue")
		at.Name = name
		at.Parent = holder()
	end
	(at :: StringValue).Value = value
end

local function kept(name: string): string?
	local folder = ServerStorage:FindFirstChild(FOLDER)
	local at = folder and folder:FindFirstChild(name)
	return if at and at:IsA("StringValue") then at.Value else nil
end

local function load(id: number): AudioPlayer?
	local player = Instance.new("AudioPlayer")
	player.Name = "NL_AuditionProbe"
	player.Asset = `rbxassetid://{id}`
	player.Parent = SoundService -- GetWaveformAsync needs it in the DataModel
	local started = os.clock()
	while not player.IsReady and os.clock() - started < LOAD do
		task.wait(0.03)
	end
	if not player.IsReady or player.TimeLength <= 0 then
		player:Destroy()
		return nil
	end
	return player
end

local function samplesOf(player: AudioPlayer, from: number, to: number): { number }?
	local out: { number } = {}
	local at = from
	while at < to - 1e-9 do
		local upTo = math.min(at + CHUNK / RATE, to)
		local count = math.max(1, math.floor((upTo - at) * RATE + 0.5))
		local ok, chunk = pcall(player.GetWaveformAsync, player, NumberRange.new(at, upTo), count)
		if not ok then
			return nil
		end
		table.move(chunk, 1, #chunk, #out + 1, out)
		at = upTo
	end
	return out
end

local cache: { [string]: { number } | false } = {}

-- A take of Config.Cues as CueMix needs it: its slice of its file, or its whole file.
local function source(take: any): { number }?
	local key = `{take.Id}:{take.From or 0}:{take.To or -1}`
	local was = cache[key]
	if was ~= nil then
		return was or nil
	end
	local player = load(take.Id)
	local samples = nil
	if player then
		samples = samplesOf(player, take.From or 0, math.min(take.To or player.TimeLength, player.TimeLength))
		player:Destroy()
	end
	cache[key] = samples or false
	return samples
end

-- Today's cue's short-term loudness, as CueCheck reads it: each take once, the mean.
local function oldLevel(name: string): number?
	local cue = Cues.Cues[name]
	local most = 1
	for _, layer in cue.Layers do
		most = math.max(most, #(Cues.Takes[layer.Takes] or {}))
	end
	local sum, n = 0, 0
	for k = 1, most do
		local render = CueMix.Play({ Cue = cue, Takes = table.create(#cue.Layers, k) }, source, RATE)
		if render.Missed == 0 then
			sum += Loudness.Over(render.Samples, RATE, CueMix.ShortTerm)
			n += 1
		end
		task.wait()
	end
	return if n > 0 then sum / n else nil
end

-- Why a find is left out by its words, or nil.
local function wordsOut(title: string, description: string): string?
	local t = Shortlist.Normalized(title)
	if not string.find(t, "%a") then
		return "its title is hidden by the filter"
	end
	if Shortlist.NamesWork(t) or Shortlist.NamesWork(Shortlist.Normalized(description)) then
		return "names another work"
	end
	if Shortlist.Mentions(t, Shortlist.Lists.Gore) > 0 then
		return "a gore word"
	end
	if Shortlist.Mentions(t, VOICE_MUSIC) > 0 then
		return "music or a voice"
	end
	return nil
end

-- A find measured as a candidate of `spec` at `target` LUFS, or why it's left out.
local function measure(found: any, spec: any, target: number): (Candidate?, string?)
	local player = load(found.Id)
	if player == nil then
		return nil, "doesn't load"
	end
	local length = player.TimeLength
	local readTo = math.min(length, READ)
	local s = samplesOf(player, 0, readTo)
	player:Destroy()
	if s == nil or #s < 2 then
		return nil, "doesn't load"
	end
	local per = math.max(1, math.floor(WINDOW * RATE))
	local env: { number } = {}
	local loudest = 0
	for w = 1, math.ceil(#s / per) do
		local top = 0
		for i = (w - 1) * per + 1, math.min(w * per, #s) do
			top = math.max(top, math.abs(s[i]))
		end
		env[w] = top
		loudest = math.max(loudest, top)
	end
	if loudest <= 1e-6 then
		return nil, "silent"
	end
	-- the first event whose top comes within Config.Event of the loudest; quieter ones before it are cut with the head
	local floor = loudest * 10 ^ (Config.Floor / 20)
	local meaningful = loudest * 10 ^ (Config.Event / 20)
	local gap = math.ceil(Config.Gap / WINDOW)
	local first, last = nil, nil
	local i = 1
	while i <= #env do
		if env[i] >= floor then
			local a, b, quiet, top = i, i, 0, env[i]
			local j = i + 1
			while j <= #env and quiet < gap do
				if env[j] >= floor then
					b, quiet = j, 0
					top = math.max(top, env[j])
				else
					quiet += 1
				end
				j += 1
			end
			if top >= meaningful then
				first, last = a, b
				break
			end
			i = b + 1
		else
			i += 1
		end
	end
	if first == nil or last == nil then
		return nil, "silent"
	end
	if readTo < length - 1e-3 and #env - last < gap then
		return nil, `too long: its first event runs past {READ} s`
	end
	local lo, hi = (first - 1) * per + 1, math.min(last * per, #s)
	local peakAt, top = lo, 0
	for k = lo, hi do
		local v = math.abs(s[k])
		if v > top then
			top, peakAt = v, k
		end
	end
	-- the head's cut: the earliest of the quietest samples in reach
	local reachFrom, reachTo
	if spec.Beat then
		reachFrom, reachTo = math.max(1, lo - math.floor(0.01 * RATE)), lo
	else
		reachFrom, reachTo = math.max(1, peakAt - math.floor(Config.Top * RATE)), math.max(1, peakAt - 1)
	end
	local least = math.huge
	for k = reachFrom, reachTo do
		least = math.min(least, math.abs(s[k]))
	end
	local near = math.max(least * 1.5, top * 0.01)
	local fromAt = reachFrom
	for k = reachFrom, reachTo do
		if math.abs(s[k]) <= near then
			fromAt = k
			break
		end
	end
	local toAt = math.min(hi + math.floor(Config.Tail * RATE), #s)
	local ends = toAt >= #s and readTo >= length - 1e-3
	local seconds = (toAt - fromAt + 1) / RATE
	if seconds > spec.Max then
		return nil, `too long: {string.format("%.2f", seconds)} s`
	end
	local slice = table.create(toAt - fromAt + 1, 0)
	for k = fromAt, toAt do
		slice[k - fromAt + 1] = s[k] * Cues.Volume * Cues.Trim
	end
	local loud = Loudness.Over(slice, RATE, CueMix.ShortTerm)
	local peak = Loudness.TruePeak(slice)
	local volume = 10 ^ ((target - loud) / 20) -- the layer's at the match
	if Cues.Volume * Cues.Trim * volume > CueMix.Engine.MaxVolume then
		return nil, `too quiet to match: it needs {string.format("%.1f", 20 * math.log10(volume))} dB`
	end
	if peak + 20 * math.log10(volume) > Config.Ceiling then
		return nil, `its top passes {Config.Ceiling} dBTP at the match`
	end
	return {
		Number = 0,
		Id = found.Id,
		Title = found.Title,
		Author = found.Creator,
		Licensed = found.Licensed,
		Keyword = found.Keyword,
		From = (fromAt - 1) / RATE,
		To = math.min(toAt / RATE, length),
		Seconds = seconds,
		Peak = (peakAt - fromAt) / RATE,
		Out = if ends then 0 else Config.Tail,
		Loud = loud,
		Top = peak,
	} :: Candidate, nil
end

-- The finds of `words`, each word's in the library's order, taken in turn.
local function inTurn(found: { any }): { any }
	local by: { [string]: { any } } = {}
	local order: { string } = {}
	for _, item in found do
		if by[item.Keyword] == nil then
			by[item.Keyword] = {}
			table.insert(order, item.Keyword)
		end
		table.insert(by[item.Keyword], item)
	end
	local out = {}
	local round = 1
	while true do
		local added = false
		for _, word in order do
			local item = by[word][round]
			if item then
				table.insert(out, item)
				added = true
			end
		end
		if not added then
			return out
		end
		round += 1
	end
end

local function run(status: (string) -> ())
	local stale = require(Shared.Config.Cues) :: any
	local result: { [string]: any } = { Made = os.date("!%Y-%m-%dT%H:%M:%SZ"), Trim = Cues.Trim, Levels = Config.Levels, Old = {}, Cues = {}, LeftOut = {}, Searched = {} }
	result.Stale = stale.Trim ~= Cues.Trim or stale.Volume ~= Cues.Volume -- Rules.Sound would read an older Config.Cues: restart Studio
	for _, spec in Config.Cues do
		status(`today's {spec.Name}`)
		result.Old[spec.Name] = oldLevel(spec.Name)
	end
	local reference = result.Old.LightHit
	assert(reference, "today's LightHit didn't load: no reference to match to")
	result.Reference = reference
	for _, spec in Config.Cues do
		status(`searching {spec.Name}`)
		local finds = inTurn(Library.Search(spec.Words, { AnyAuthor = true, Pages = Config.Pages }))
		result.Searched[spec.Name] = #finds
		local target = reference + (Config.Levels[spec.Name] or 0)
		local list: { Candidate } = {}
		local left: { Left } = {}
		for n, found in finds do
			if #list >= Config.Keep then
				break
			end
			status(`{spec.Name}: {n} of {#finds}, {#list} kept`)
			local why = wordsOut(found.Title, found.Description or "")
			local candidate = nil
			if why == nil then
				candidate, why = measure(found, spec, target)
			end
			if candidate then
				candidate.Number = #list + 1
				table.insert(list, candidate)
			else
				table.insert(left, { Id = found.Id, Title = found.Title, Why = why or "?" })
			end
			task.wait()
		end
		result.Cues[spec.Name] = list
		result.LeftOut[spec.Name] = left
	end
	keep("Candidates", HttpService:JSONEncode(result))
end

-- Finds every pilot's candidates, detached. Its answer stays under ServerStorage.NL_Audition until the next Start.
function Audition.Start()
	keep("Status", "starting")
	task.spawn(function()
		local ok, err = pcall(run, function(line: string)
			keep("Status", line)
		end)
		keep("Status", if ok then "done" else `failed: {err}`)
	end)
	return "started"
end

function Audition.Status(): string
	return kept("Status") or "not started"
end

-- Each cue's count and level, and what was left out, by number and title.
function Audition.Report(): string
	local text = kept("Candidates")
	if text == nil then
		return Audition.Status()
	end
	local result = HttpService:JSONDecode(text)
	local lines = { `made {result.Made}; reference (today's LightHit) {string.format("%.1f", result.Reference)} LUFS short-term{if result.Stale then "; STALE Config.Cues: restart Studio" else ""}` }
	for _, spec in Config.Cues do
		local list, left = result.Cues[spec.Name] or {}, result.LeftOut[spec.Name] or {}
		local hottest, longest = -math.huge, 0
		for _, c in list do
			hottest = math.max(hottest, c.Top + (result.Reference + (Config.Levels[spec.Name] or 0) - c.Loud))
			longest = math.max(longest, c.Seconds)
		end
		table.insert(lines, `{spec.Name}: today's {string.format("%.1f", result.Old[spec.Name] or 0)} LUFS; {#list} candidates of {result.Searched[spec.Name]} found, {#left} left out; the hottest top at the match {string.format("%.1f", hottest)} dBTP, the longest {string.format("%.2f", longest)} s`)
		for _, l in left do
			table.insert(lines, `  out: {l.Id} "{l.Title}": {l.Why}`)
		end
	end
	return table.concat(lines, "\n")
end

function Audition.Clear()
	local folder = ServerStorage:FindFirstChild(FOLDER)
	if folder then
		folder:Destroy()
	end
end

return Audition
