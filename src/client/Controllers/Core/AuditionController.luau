--!strict
-- AuditionController (client, Studio only): the sound audition panel (docs/test-requests.md, TR42). The director plays a
-- fight, taps a candidate, and from that tap every hit of its cue plays it, in the fight, at the fight's level; Keep
-- marks the right one, and None says a ten held nothing. The candidates are the finder's (tools/studio/Audio/Audition,
-- run in Edit), handed over by AuditionService: each a finished library sound, its first event whole, cut only at its
-- head, at one loudness for its cue (Config.Audition.Levels, set against today's LightHit), with no pitch or volume
-- spread. "Old" brings today's cue back exactly.
--   - A tap plays the sound once through the hit's own path (FighterController/Cues), Config.Audition.Preview studs in
--     front of the camera, inside every cue's Near and never on the listener (an emitter there reads 8.5 dB down, AR39).
--   - The live sound changes only once every voice of the tapped one has loaded, so no hit goes silent between two, and
--     a hit plays one cue's voices, never two. A sound already playing finishes. One that doesn't load is marked and
--     skipped: the live sound stays.
--   - Keep and None go to the server as they change; NL_Debug:Invoke("Audition") reads them out.
--   - "Others" silences the fight's cues that aren't open pilots (the Shade's hurt on the same touch, the heavy wind-up,
--     the critical, the burst, the picked hits), the strike's own slices (Config.Sounds) and the music, so a candidate
--     can be heard alone on its hit; on by default, the fight as it is.
--   - A pilot marked Done (Config.Audition) is picked: it has no tab, and the panel opens on the first that's left.
--   - A level changed live (Tune "Audition.Levels.<cue>") reaches every candidate within a quarter second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Config = require(Shared.Config.Audition)
local CuesConfig = require(Shared.Config.Cues)
local Cues = require(script.Parent.Parent.Main.FighterController.Cues)
local Sounds = require(script.Parent.Parent.Main.FighterController.Sounds)
local SettingsController = require(script.Parent.SettingsController)

local AuditionController = {}

local USE = CuesConfig.Use :: { [string]: string } -- AR39's A/B switch: "Old" or a variant, read at each play

local DATA = "NL_Audition" -- the finder's answer, as AuditionService hands it over
local GUI = "Studio_Audition" -- not NL_: the UI lint reads the game's own screens by that, and this is a tool, never a player's
local LOAD = 4 -- s a tapped sound has to load in
local LEVELS = 0.25 -- s between reads of Config.Audition.Levels
local COLUMNS = 3 -- tabs a line
local TAB_LINE = 34 -- px a line of tabs takes
local MUSIC = "GA_Music" -- MusicController's group, silenced with the others

export type Candidate = {
	Number: number,
	Id: number,
	Title: string,
	Author: string,
	Licensed: boolean?,
	Keyword: string?,
	From: number,
	To: number,
	Seconds: number,
	Peak: number,
	Out: number,
	Loud: number,
	Top: number?,
}
type Tab = {
	Spec: any,
	List: { Candidate },
	Page: number,
	Live: string, -- "Old" or the live candidate's variant
	Loading: number?, -- the id of the one being loaded
	Failed: { [number]: boolean },
	Kept: { [number]: Candidate },
	None: { [number]: boolean },
}

local data: any = nil
local tabs: { [string]: Tab } = {}
local shown = "LightHit" -- the panel opens on the first pilot not Done
local built: { [string]: Candidate } = {} -- the cues made, by their voices' key
local refresh: () -> () = function() end

-- Seam: whether this is Studio (a case swaps it to check the panel isn't built outside).
AuditionController.Studio = function(): boolean
	return RunService:IsStudio()
end

local function specOf(pilot: string): any
	for _, spec in Config.Cues do
		if spec.Name == pilot then
			return spec
		end
	end
	return nil
end

local function variantOf(c: Candidate): string
	return `A{c.Id}`
end

-- A candidate's layer volume: at its cue's loudness, today's LightHit plus the cue's level. 1 with no reference.
function AuditionController.VolumeOf(pilot: string, c: Candidate): number
	local reference = if data then data.Reference else nil
	if type(reference) ~= "number" then
		return 1
	end
	return 10 ^ ((reference + ((Config.Levels :: any)[pilot] or 0) - c.Loud) / 20)
end

-- The candidate as its pilot's cue: one layer, the pilot's bus, voices and reach, no spread. A beat's is started ahead by
-- its top; a contact's plays on the touch, its top already within Config.Audition.Top of its start.
local function cueOf(pilot: string, c: Candidate): CuesConfig.Cue
	local base = CuesConfig.Cues[pilot]
	local spec = specOf(pilot)
	local takes = `Aud{c.Id}`
	;(CuesConfig.Takes :: any)[takes] = {
		{ Id = c.Id, Seconds = c.Seconds, Peak = c.Peak, From = c.From, To = c.To, In = 0, Out = c.Out, Gain = 1 },
	}
	return {
		Layers = { { Takes = takes, At = 0, Lead = if spec and spec.Beat then "Peak" else nil, Volume = AuditionController.VolumeOf(pilot, c) } },
		Bus = base.Bus,
		Pitch = { 1, 1 },
		Volume = { 1, 1 },
		Voices = base.Voices,
		Near = base.Near,
		Range = base.Range,
	}
end

-- The candidate's voices' key, its cue made and loading.
local function ensure(pilot: string, c: Candidate): string
	local variant = variantOf(c)
	local key = `{pilot}@{variant}`
	if built[key] == nil then
		local set = CuesConfig.Arrangements[pilot] or {}
		CuesConfig.Arrangements[pilot] = set
		local cue = cueOf(pilot, c)
		set[variant] = cue
		Cues.Try(key, cue)
		built[key] = c
	end
	return key
end

-- Whether every voice of a cue's key has loaded, within `seconds`.
local function loaded(key: string, voices: number, seconds: number): boolean
	local deadline = os.clock() + seconds
	while true do
		local ready = true
		for nth = 1, math.max(voices, 1) do
			local player = Cues.Voice(key, 1, 1, nth)
			if player == nil or not player.IsReady then
				ready = false
				break
			end
		end
		if ready then
			return true
		end
		if os.clock() >= deadline then
			return false
		end
		task.wait(0.05)
	end
end

-- Takes a candidate's cue away (one that didn't load, or a case's own).
function AuditionController.Forget(pilot: string, c: Candidate)
	local variant = variantOf(c)
	local key = `{pilot}@{variant}`
	if USE[pilot] == variant then
		USE[pilot] = "Old"
	end
	Cues.Try(key, nil)
	built[key] = nil
	local set = CuesConfig.Arrangements[pilot]
	if set then
		set[variant] = nil
	end
	;(CuesConfig.Takes :: any)[`Aud{c.Id}`] = nil
end

-- Plays the pilot's live cue once, through the hit's own path.
function AuditionController.Hear(pilot: string)
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local at = camera.CFrame.Position + camera.CFrame.LookVector * Config.Preview
	local ahead = Cues.Ahead(pilot) or 0
	Cues.Play(pilot, at, if ahead > 0 then { In = ahead } else nil)
end

local function tabOf(pilot: string): Tab
	local tab = tabs[pilot]
	if tab == nil then
		local made: Tab = { Spec = specOf(pilot), List = {}, Page = 1, Live = "Old", Loading = nil, Failed = {}, Kept = {}, None = {} }
		tabs[pilot] = made
		return made
	end
	return tab
end

-- Makes `c` (or "Old") the pilot's live sound and plays it once. False when it didn't load: it's marked, and the live
-- sound stays. Yields while it loads. `quiet` makes it live without the play (a case's).
function AuditionController.Choose(pilot: string, c: Candidate | string, quiet: boolean?): boolean
	local tab = tabOf(pilot)
	if type(c) == "string" then
		tab.Loading = nil
		USE[pilot] = "Old"
		tab.Live = "Old"
		if not quiet then
			AuditionController.Hear(pilot)
		end
		refresh()
		return true
	end
	local candidate = c :: Candidate
	if tab.Failed[candidate.Id] then
		return false
	end
	tab.Loading = candidate.Id
	refresh()
	local key = ensure(pilot, candidate)
	local ok = loaded(key, CuesConfig.Cues[pilot].Voices, LOAD)
	if not ok then
		tab.Failed[candidate.Id] = true
		AuditionController.Forget(pilot, candidate)
		if tab.Loading == candidate.Id then
			tab.Loading = nil
		end
		refresh()
		return false
	end
	if tab.Loading ~= candidate.Id then
		return true -- another tap came since: that one goes live
	end
	tab.Loading = nil
	USE[pilot] = variantOf(candidate)
	tab.Live = variantOf(candidate)
	if not quiet then
		AuditionController.Hear(pilot)
	end
	refresh()
	return true
end

function AuditionController.Live(pilot: string): string
	return tabOf(pilot).Live
end

function AuditionController.Failed(pilot: string, id: number): boolean
	return tabOf(pilot).Failed[id] == true
end

-- The fight's other cues (Config.Cues' cues that aren't pilots: the Shade's hurt, the heavy wind-up, the critical, the
-- burst) silenced, so a pilot's candidate is heard alone on its hit, or played again as they are. Each is switched to a
-- silent arrangement of its own, "Mute", as AR39's A/B switches a pilot, and back: on again, the switch and the silent
-- arrangement are taken away, so nothing of theirs is changed and no other case meets one.
local muted = false
local before: { [string]: { Use: string?, Made: boolean } } = {}
function AuditionController.Others(on: boolean)
	if muted == not on then
		return
	end
	muted = not on
	Sounds.Quiet(muted)
	local music = game:GetService("SoundService"):FindFirstChild(MUSIC)
	if music and music:IsA("SoundGroup") then
		music.Volume = if muted then 0 else SettingsController.Level("Music")
	end
	for name, base in CuesConfig.Cues do
		local spec = specOf(name)
		if spec ~= nil and not spec.Done then
			continue
		end
		if on then
			local was = before[name]
			if was then
				USE[name] = was.Use :: any
				local set = CuesConfig.Arrangements[name]
				if set then
					set.Mute = nil
					if was.Made then
						CuesConfig.Arrangements[name] = nil
					end
				end
				Cues.Try(`{name}@Mute`, nil)
				before[name] = nil
			end
		else
			local set = CuesConfig.Arrangements[name]
			before[name] = { Use = USE[name], Made = set == nil }
			if set == nil then
				set = {}
				CuesConfig.Arrangements[name] = set
			end
			local silent: CuesConfig.Cue = { Layers = {}, Bus = base.Bus, Pitch = base.Pitch, Volume = base.Volume, Voices = base.Voices, Near = base.Near, Range = base.Range };
			(set :: any).Mute = silent
			Cues.Try(`{name}@Mute`, silent)
			USE[name] = "Mute"
		end
	end
	refresh()
end
function AuditionController.OthersOn(): boolean
	return not muted
end

-- What's kept and which tens held none, to the server, whole.
local function report()
	local kept, none = {}, {}
	for _, spec in Config.Cues do
		local tab = tabOf(spec.Name)
		for _, c in tab.Kept do
			table.insert(kept, { Cue = spec.Name, Id = c.Id, Title = c.Title, Author = c.Author })
		end
		for page in tab.None do
			table.insert(none, { Cue = spec.Name, Page = page })
		end
	end
	task.spawn(function()
		pcall(Net.Client.Invoke, "DebugCommand", "AuditionReport", kept, none)
	end)
end

-- Every made candidate's layer volume, from the levels as they are now (Tune).
local function relevel()
	for key, c in built do
		local pilot = string.split(key, "@")[1]
		local set = CuesConfig.Arrangements[pilot]
		local cue = set and set[variantOf(c)]
		if cue then
			cue.Layers[1].Volume = AuditionController.VolumeOf(pilot, c)
		end
	end
end

-- The panel ---------------------------------------------------------------------------------------------------------

local COLOURS = {
	Panel = Color3.fromRGB(16, 17, 22),
	Row = Color3.fromRGB(30, 32, 40),
	Live = Color3.fromRGB(30, 70, 72),
	Accent = Color3.fromRGB(90, 225, 205),
	Gold = Color3.fromRGB(255, 205, 90),
	Text = Color3.fromRGB(236, 236, 242),
	Dim = Color3.fromRGB(160, 166, 178),
	Off = Color3.fromRGB(105, 108, 118),
	Button = Color3.fromRGB(48, 52, 64),
}
local ROW = 34

local function label(parent: Instance, text: string, size: number, font: Enum.Font, colour: Color3, frame: UDim2, at: UDim2, align: Enum.TextXAlignment?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font
	l.TextColor3 = colour
	l.Size = frame
	l.Position = at
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, frame: UDim2, at: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = COLOURS.Button
	b.Text = text
	b.TextSize = 14
	b.Font = Enum.Font.BuilderSansBold
	b.TextColor3 = COLOURS.Text
	b.Size = frame
	b.Position = at
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = b
	b.Parent = parent
	return b
end

local function pages(tab: Tab): number
	return math.max(1, math.ceil(#tab.List / Config.Page))
end

-- The panel, or nil outside Studio or with no candidates.
function AuditionController.Mount(): ScreenGui?
	if not AuditionController.Studio() then
		return nil
	end
	local value = ReplicatedStorage:FindFirstChild(DATA)
	if value == nil or not value:IsA("StringValue") then
		return nil
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, value.Value)
	if not ok or type(decoded) ~= "table" then
		warn(`[NL] Audition: the finder's candidates didn't read: {decoded}`)
		return nil
	end
	data = decoded
	for _, spec in Config.Cues do
		local tab = tabOf(spec.Name)
		tab.List = (data.Cues and data.Cues[spec.Name]) or {}
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = GUI
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 60
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 16, 0.5, 0)
	panel.Size = UDim2.fromOffset(390, 560)
	panel.BackgroundColor3 = COLOURS.Panel
	panel.BackgroundTransparency = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.86
	stroke.Parent = panel

	label(panel, "Sound audition", 18, Enum.Font.BuilderSansBold, COLOURS.Text, UDim2.new(1, -100, 0, 28), UDim2.fromOffset(12, 8))
	local hide = button(panel, "Hide", UDim2.fromOffset(64, 24), UDim2.new(1, -76, 0, 10))
	hide.Name = "Hide"
	local others = button(panel, "Others on", UDim2.fromOffset(92, 24), UDim2.new(1, -174, 0, 10))
	others.Name = "Others"
	others.TextSize = 13
	others.MouseButton1Click:Connect(function()
		AuditionController.Others(muted)
	end)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(12, 42)
	body.Size = UDim2.new(1, -24, 1, -50)
	body.Parent = panel

	-- the pilots left to pick, COLUMNS a line; everything under the tabs moves down by their extra lines
	local open: { any } = {}
	for _, spec in Config.Cues do
		if not spec.Done then
			table.insert(open, spec)
		end
	end
	if #open > 0 and (specOf(shown) == nil or specOf(shown).Done) then
		shown = open[1].Name
	end
	local shift = (math.max(math.ceil(#open / COLUMNS), 1) - 1) * TAB_LINE
	local tall = 560 + shift
	panel.Size = UDim2.fromOffset(390, tall)
	local tabButtons: { [string]: TextButton } = {}
	for i, spec in open do
		local column, line = (i - 1) % COLUMNS, (i - 1) // COLUMNS
		local b = button(body, spec.Label, UDim2.new(1 / COLUMNS, -4, 0, 30), UDim2.new(column / COLUMNS, 2, 0, line * TAB_LINE))
		b.Name = `Tab{spec.Name}`
		b.TextSize = 13
		tabButtons[spec.Name] = b
		b.MouseButton1Click:Connect(function()
			shown = spec.Name
			refresh()
		end)
	end
	local info = label(body, "", 13, Enum.Font.BuilderSans, COLOURS.Dim, UDim2.new(1, 0, 0, 18), UDim2.fromOffset(2, 36 + shift))
	info.Name = "Info"

	type Row = { Frame: TextButton, Number: TextLabel, Title: TextLabel, By: TextLabel, Length: TextLabel, Keep: TextButton, Item: (Candidate | string)? }
	local rows: { Row } = {}
	for r = 1, Config.Page + 1 do
		local f = Instance.new("TextButton")
		f.Name = `Row{r}`
		f.AutoButtonColor = true
		f.Text = ""
		f.BackgroundColor3 = COLOURS.Row
		f.Size = UDim2.new(1, 0, 0, ROW)
		f.Position = UDim2.fromOffset(0, 58 + shift + (r - 1) * (ROW + 3))
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = f
		f.Parent = body
		local row: Row = {
			Frame = f,
			Number = label(f, "", 14, Enum.Font.BuilderSansBold, COLOURS.Dim, UDim2.fromOffset(34, ROW), UDim2.fromOffset(8, 0)),
			Title = label(f, "", 14, Enum.Font.BuilderSansMedium, COLOURS.Text, UDim2.new(1, -156, 0, 18), UDim2.fromOffset(42, 1)),
			By = label(f, "", 11, Enum.Font.BuilderSans, COLOURS.Dim, UDim2.new(1, -156, 0, 14), UDim2.fromOffset(42, 18)),
			Length = label(f, "", 13, Enum.Font.BuilderSansMedium, COLOURS.Dim, UDim2.fromOffset(44, ROW), UDim2.new(1, -108, 0, 0), Enum.TextXAlignment.Right),
			Keep = button(f, "Keep", UDim2.fromOffset(54, 24), UDim2.new(1, -60, 0, 5)),
			Item = nil,
		}
		row.Keep.Name = "Keep"
		row.Keep.TextSize = 13
		table.insert(rows, row)
		f.MouseButton1Click:Connect(function()
			local item = row.Item
			if item ~= nil then
				task.spawn(AuditionController.Choose, shown, item, false)
			end
		end)
		row.Keep.MouseButton1Click:Connect(function()
			local item = row.Item
			local tab = tabOf(shown)
			if item == nil then
				return
			end
			local c: Candidate = if type(item) == "string"
				then { Number = 0, Id = 0, Title = "Old (today's cue)", Author = "AR13's takes", From = 0, To = 0, Seconds = 0, Peak = 0, Out = 0, Loud = 0 }
				else item :: Candidate
			tab.Kept[c.Id] = if tab.Kept[c.Id] then nil else c
			report()
			refresh()
		end)
	end

	local footY = 58 + shift + (Config.Page + 1) * (ROW + 3) + 4
	local more = button(body, "More", UDim2.fromOffset(80, 30), UDim2.fromOffset(0, footY))
	more.Name = "More"
	local none = button(body, "None of these", UDim2.fromOffset(126, 30), UDim2.fromOffset(86, footY))
	none.Name = "None"
	local status = label(body, "", 13, Enum.Font.BuilderSansMedium, COLOURS.Dim, UDim2.new(1, -220, 0, 30), UDim2.fromOffset(220, footY), Enum.TextXAlignment.Right)
	status.Name = "Status"

	more.MouseButton1Click:Connect(function()
		local tab = tabOf(shown)
		tab.Page = if tab.Page < pages(tab) then tab.Page + 1 else 1
		refresh()
	end)
	none.MouseButton1Click:Connect(function()
		local tab = tabOf(shown)
		tab.None[tab.Page] = if tab.None[tab.Page] then nil else true
		report()
		refresh()
	end)
	local hidden = false
	hide.MouseButton1Click:Connect(function()
		hidden = not hidden
		body.Visible = not hidden
		panel.Size = if hidden then UDim2.fromOffset(390, 44) else UDim2.fromOffset(390, tall)
		hide.Text = if hidden then "Show" else "Hide"
	end)

	refresh = function()
		local tab = tabOf(shown)
		for name, b in tabButtons do
			local t = tabOf(name)
			b.BackgroundColor3 = if name == shown then COLOURS.Live else COLOURS.Button
			b.TextColor3 = if name == shown then COLOURS.Accent else COLOURS.Text
			local live = if t.Live == "Old" then "Old" else (function()
				for _, c in t.List do
					if variantOf(c) == t.Live then
						return `#{c.Number}`
					end
				end
				return "?"
			end)()
			b.Text = `{t.Spec.Label} · {live}`
		end
		local level = (Config.Levels :: any)[shown] or 0
		info.Text = `Tap a row: it plays, and every {string.lower(tab.Spec.Label)} plays it. Level {if level >= 0 then "+" else ""}{level} dB.`
		local first = (tab.Page - 1) * Config.Page
		for r, row in rows do
			local item: (Candidate | string)? = nil
			if r == 1 then
				item = "Old"
			else
				item = tab.List[first + r - 1]
			end
			row.Item = item
			row.Frame.Visible = item ~= nil
			if item == nil then
				continue
			end
			local id = if type(item) == "string" then 0 else (item :: Candidate).Id
			local live = if type(item) == "string" then tab.Live == "Old" else tab.Live == variantOf(item :: Candidate)
			local failed = id ~= 0 and tab.Failed[id] == true
			local loading = id ~= 0 and tab.Loading == id
			row.Frame.BackgroundColor3 = if live then COLOURS.Live else COLOURS.Row
			if type(item) == "string" then
				local silent = #CuesConfig.Cues[shown].Layers == 0
				row.Number.Text = "Old"
				row.Title.Text = if silent then "Silence" else "Today's cue"
				row.By.Text = if silent then "nothing plays here today" else "what plays here today, at its level"
				row.Length.Text = ""
			else
				local c = item :: Candidate
				row.Number.Text = `#{c.Number}`
				row.Title.Text = c.Title
				row.By.Text = if failed then "didn't load: skipped" elseif loading then "loading…" else `by {c.Author}`
				row.Length.Text = string.format("%.2f s", c.Seconds)
			end
			row.Number.TextColor3 = if live then COLOURS.Accent else COLOURS.Dim
			row.Title.TextColor3 = if failed then COLOURS.Off else COLOURS.Text
			local isKept = tab.Kept[id] ~= nil
			row.Keep.Text = if isKept then "Kept" else "Keep"
			row.Keep.BackgroundColor3 = if isKept then COLOURS.Gold else COLOURS.Button
			row.Keep.TextColor3 = if isKept then COLOURS.Panel else COLOURS.Text
			row.Keep.Visible = not failed
		end
		local keptCount = 0
		for _ in tab.Kept do
			keptCount += 1
		end
		none.Text = if tab.None[tab.Page] then "None: recorded" else "None of these"
		none.BackgroundColor3 = if tab.None[tab.Page] then COLOURS.Gold else COLOURS.Button
		none.TextColor3 = if tab.None[tab.Page] then COLOURS.Panel else COLOURS.Text
		more.Text = if tab.Page < pages(tab) then "More" else "From 1"
		others.Text = if muted then "Others off" else "Others on"
		others.BackgroundColor3 = if muted then COLOURS.Gold else COLOURS.Button
		others.TextColor3 = if muted then COLOURS.Panel else COLOURS.Text
		status.Text = `page {tab.Page} of {pages(tab)} · kept {keptCount}`
	end
	refresh()
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function AuditionController.Start()
	if not AuditionController.Studio() then
		return
	end
	-- the candidates arrive with the server's start; none in a playtest the finder didn't run before
	local value = ReplicatedStorage:WaitForChild(DATA, 10)
	if value == nil then
		return
	end
	AuditionController.Mount()
	local was: { [string]: number } = {}
	while true do
		task.wait(LEVELS)
		local changed = false
		for name, db in Config.Levels :: any do
			if was[name] ~= db then
				was[name] = db
				changed = true
			end
		end
		if changed then
			relevel()
			refresh()
		end
	end
end

return AuditionController
