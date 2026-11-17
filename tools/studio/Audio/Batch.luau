--!strict
-- Batch: a shortlist batch, for a teammate who ranks library sounds without hearing them (AR39, "The briefs, and the
-- first batch"). For each brief, Shortlist.Run; then each pick's window is read from its file and measured (Measures):
-- the pick's fields and its numbers, never audio. Studio, Edit mode, MCP execute_luau. A batch outlasts one call, so it
-- runs detached, keeping each pick as its JSON in a StringValue under ServerStorage.NL_Batch:
--   local Batch = require(game.ServerStorage.NL_Tools.Audio.Batch:Clone())
--   Batch.Start({ "LightHitBody", "HeavyHitBody" }, { Count = 14, Measure = 80, Pages = 3 }) -- returns at once
--   return Batch.Status()  -- where it is
--   return Batch.Part(1)   -- once done: part 1 of Collect's text, and how many parts there are
--   Batch.Clear()          -- once the files are written
-- Collect's text is one JSON object, each brief's file under its name ({ Brief, ..., Window, Picks }), in ASCII. An MCP
-- answer keeps 100,000 characters, so it comes back in parts between markers, each padded past that: the MCP host then
-- keeps the answer in a file (tool-results/), never in the conversation. tools/audio/batch_split.py joins the parts and
-- writes one <brief>.json a brief.

local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

local AUDIO = ServerStorage:WaitForChild("NL_Tools"):WaitForChild("Audio")
local function load(name: string): any
	return require(AUDIO:WaitForChild(name):Clone()) -- a clone, so Rojo edits always load
end
local Shortlist = load("Shortlist")
local Measures = load("Measures")

local RATE = 48000 -- points a second read from each file (Mixdown reads at the same)
local CHUNK = 8192 -- the most GetWaveformAsync returns in one call
local LOAD_TIMEOUT = 6
local HOLDER = "NL_Batch"
local PART = 99000 -- characters of Collect's text in one part (an MCP answer keeps 100,000)

local Batch = {}

type Options = { Count: number?, Measure: number?, Pages: number?, AnyAuthor: boolean? }

-- A pick's window, from Before ahead of its slice to After past it, silence where that's outside the file.
local function window(id: number, from: number, to: number): ({ number }?, number, number, string?)
	local player = Instance.new("AudioPlayer")
	player.Name = "NL_BatchProbe"
	player.Asset = `rbxassetid://{id}`
	player.Parent = SoundService -- GetWaveformAsync needs it in the DataModel
	local started = os.clock()
	while not player.IsReady and os.clock() - started < LOAD_TIMEOUT do
		task.wait(0.03)
	end
	if not player.IsReady then
		player:Destroy()
		return nil, 0, 0, "didn't load"
	end
	local before = math.floor(Measures.Before * RATE + 0.5)
	local length = math.floor((to - from) * RATE + 0.5)
	local total = before + length + math.floor(Measures.After * RATE + 0.5)
	local out = table.create(total, 0)
	local first = math.floor(from * RATE + 0.5) - before -- the window's first sample in the file, from 0
	local readFrom, readTo = math.max(first, 0), math.min(first + total, math.floor(player.TimeLength * RATE))
	local at = readFrom
	while at < readTo do
		local upTo = math.min(at + CHUNK, readTo)
		local ok, chunk = pcall(player.GetWaveformAsync, player, NumberRange.new(at / RATE, upTo / RATE), upTo - at)
		if not ok then
			player:Destroy()
			return nil, 0, 0, tostring(chunk)
		end
		table.move(chunk, 1, math.min(#chunk, upTo - at), at - first + 1, out)
		at = upTo
	end
	player:Destroy()
	return out, before, length, nil
end

-- A JSON string in ASCII alone (every other character escaped), so a part's cut never splits a character.
local function text(value: string): string
	local parts = {}
	local ok = pcall(function()
		for _, code in utf8.codes(value) do
			if code == 34 then
				table.insert(parts, '\\"')
			elseif code == 92 then
				table.insert(parts, "\\\\")
			elseif code >= 32 and code < 127 then
				table.insert(parts, string.char(code))
			elseif code < 0x10000 then
				table.insert(parts, string.format("\\u%04x", code))
			else
				local c = code - 0x10000
				table.insert(parts, string.format("\\u%04x\\u%04x", 0xD800 + c // 0x400, 0xDC00 + c % 0x400))
			end
		end
	end)
	if not ok then
		local plain = string.gsub(value, "[\128-\255]", "?")
		return text(plain)
	end
	return '"' .. table.concat(parts) .. '"'
end

local function number(value: number?, places: number): string
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return "null"
	end
	return string.format(`%.{places}f`, value)
end

local function list(values: { number }, places: number): string
	local parts = table.create(#values, "")
	for i, v in values do
		parts[i] = number(v, places)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

-- One pick's JSON: its fields, then its measures (or why it has none).
local function encode(pick: any, m: any, problem: string?): string
	local parts = {
		`"Cue":{text(pick.Cue)}`,
		`"Id":{pick.Id}`,
		`"Title":{text(pick.Title)}`,
		`"Creator":{text(pick.Creator)}`,
		`"Licensed":{if pick.Licensed then "true" else "false"}`,
		`"Keyword":{text(pick.Keyword)}`,
		`"From":{number(pick.From, 3)}`,
		`"To":{number(pick.To, 3)}`,
		`"Peak":{number(pick.Peak, 3)}`,
		`"Level":{number(pick.Level, 1)}`,
		`"Score":{number(pick.Score, 2)}`,
		`"Shape":{text(pick.Shape)}`,
	}
	if m then
		local rows = table.create(#m.Spectrogram, "")
		for i, row in m.Spectrogram do
			rows[i] = list(row, 1)
		end
		table.insert(parts, `"Envelope":{list(m.Envelope, 1)}`)
		table.insert(parts, `"Spectrogram":[{table.concat(rows, ",")}]`)
		table.insert(parts, `"Spectrum":{list(m.Spectrum, 1)}`)
		table.insert(parts, `"Under120":{number(m.Under120, 4)}`)
		table.insert(parts, `"Loudness":{number(m.Loudness, 1)}`)
		table.insert(parts, `"TruePeak":{number(m.TruePeak, 1)}`)
		table.insert(parts, `"SamplePeak":{number(m.SamplePeak, 1)}`)
		table.insert(parts, `"SamplePeakAt":{number(m.SamplePeakAt, 4)}`)
		table.insert(parts, `"StepIn":{number(m.StepIn, 4)}`)
		table.insert(parts, `"StepOut":{number(m.StepOut, 4)}`)
	else
		table.insert(parts, `"Error":{text(problem or "not measured")}`)
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

local function holder(): Folder
	local found = ServerStorage:FindFirstChild(HOLDER)
	if found and found:IsA("Folder") then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = HOLDER
	made.Parent = ServerStorage
	return made
end

local function runBrief(root: Folder, name: string, options: Options)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("State", "searching and ranking")
	folder.Parent = root
	local ok, picks = pcall(Shortlist.Run, name, options)
	if not ok then
		folder:SetAttribute("State", `failed: {picks}`)
		return
	end
	folder:SetAttribute("Picks", #picks)
	for index, pick in picks do
		folder:SetAttribute("State", `measuring {index}/{#picks}`)
		local samples, before, length, problem = window(pick.Id, pick.From, pick.To)
		local measured: any = nil
		if samples and length > 0 then
			local done, result = pcall(Measures.Slice, samples, RATE, before, length, task.wait)
			if done then
				measured = result
			else
				problem = tostring(result)
			end
		elseif samples then
			problem = "an empty slice"
		end
		local value = Instance.new("StringValue")
		value.Name = string.format("%03d", index)
		value.Value = encode(pick, measured, problem)
		value.Parent = folder
	end
	folder:SetAttribute("State", "done")
end

-- Runs the batch detached; one batch at a time.
function Batch.Start(briefs: { string }, options: Options?): string
	local root = holder()
	if root:GetAttribute("State") == "running" then
		return "a batch is running: Batch.Status()"
	end
	root:ClearAllChildren()
	local opts = options or {}
	root:SetAttribute("State", "running")
	root:SetAttribute("Started", DateTime.now():ToIsoDate())
	root:SetAttribute("Options", `Count {opts.Count or 8}, Measure {opts.Measure or 45}, Pages {opts.Pages or 2}, AnyAuthor {if opts.AnyAuthor == false then "false" else "true"}`)
	root:SetAttribute("Briefs", table.concat(briefs, ","))
	task.spawn(function()
		for _, name in briefs do
			runBrief(root, name, opts)
		end
		root:SetAttribute("Finished", DateTime.now():ToIsoDate())
		root:SetAttribute("State", "done")
	end)
	return `started: {table.concat(briefs, ", ")}`
end

function Batch.Status(): string
	local root = ServerStorage:FindFirstChild(HOLDER)
	if root == nil then
		return "no batch"
	end
	local lines = { `{root:GetAttribute("State")} (started {root:GetAttribute("Started")}, {root:GetAttribute("Options")})` }
	for _, folder in root:GetChildren() do
		table.insert(lines, `{folder.Name}: {folder:GetAttribute("State")}, {#folder:GetChildren()}/{folder:GetAttribute("Picks") or "?"} written`)
	end
	return table.concat(lines, "\n")
end

-- Every brief's file, as one JSON object.
function Batch.Collect(): string
	local root = ServerStorage:FindFirstChild(HOLDER)
	assert(root, "no batch")
	local files = {}
	local centres = {}
	for i, c in Measures.Centres do
		centres[i] = number(c, 1)
	end
	local windowText = `\{"Rate":{RATE},"Before":{Measures.Before},"After":{Measures.After},"Step":{Measures.Step},"Frame":{Measures.Frame},"Size":{Measures.Size},"Edge":{Measures.Edge},"Centres":[{table.concat(centres, ",")}]\}`
	for _, folder in root:GetChildren() do
		local picks = {}
		local values = folder:GetChildren()
		table.sort(values, function(a, b)
			return a.Name < b.Name
		end)
		for _, value in values do
			if value:IsA("StringValue") then
				table.insert(picks, value.Value)
			end
		end
		table.insert(files, `{text(folder.Name)}:\{"Brief":{text(folder.Name)},"State":{text(tostring(folder:GetAttribute("State")))},"Started":{text(tostring(root:GetAttribute("Started")))},"Finished":{text(tostring(root:GetAttribute("Finished")))},"Options":{text(tostring(root:GetAttribute("Options")))},"Window":{windowText},"Picks":[{table.concat(picks, ",")}]\}`)
	end
	return "{" .. table.concat(files, ",") .. "}"
end

-- Part `index` of Collect's text, between its markers, padded past what one MCP answer keeps.
function Batch.Part(index: number): string
	local all = Batch.Collect()
	local count = math.max(1, math.ceil(#all / PART))
	local body = string.sub(all, (index - 1) * PART + 1, index * PART)
	local marked = `<<NL_BATCH {index}/{count}>>{body}<<NL_END>>`
	return marked .. string.rep(" ", 101000 - #marked) -- past the cut, a short last part included
end

function Batch.Clear()
	local root = ServerStorage:FindFirstChild(HOLDER)
	if root then
		root:Destroy()
	end
end

return Batch
