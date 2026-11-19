--!strict
-- StageScreen (client): a ground's stages, in grey (docs/test-requests.md, TR43). Two faces of one panel:
-- * The picker, opened at the Festival Door for a player who isn't fresh (StageService's StagePick): a Normal and Hard
--   switch, and a tile a stage with its recommended Combat Power (Rules.Stages.Recommended), its best clear, and why it's
--   shut ("Clear Stage 2 first", "Beat the Lamplighter on Normal", each Hard tile's while Hard is shut). A tile begins
--   its run (Net Stage) where it starts.
-- * The results, at a run's end (StageDone): its time and best, what it gave, what it opened ("Hard is open" when the
--   keeper's stage falls on Normal), and Retry, Next and Home. A lost run says the lead fell, with Retry and Home.
-- Their look waits for the shared finish; tile art waits (TR43, "Waits").
--   StageScreen.Pick(ground, view, on)      the picker, on the switch's difficulty (Normal, unless Hard was last picked)
--   StageScreen.Results(results, on)       the results card
--   StageScreen.Parts()                    its pieces by name, for tests
--   StageScreen.Difficulty()               the switch's side

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Stages = require(Shared.Rules.Stages)
local Grounds = require(Shared.Definitions.Grounds)
local Enemies = require(Shared.Definitions.Enemies)
local Hud = require(Shared.Rules.Hud)
local Sheet = require(Shared.Rules.Sheet)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)

local StageScreen = {}
StageScreen.Name = "Stages"

export type On = {
	Begin: (ground: string, difficulty: string, stage: number) -> { [string]: any }, -- Net Stage
	Home: () -> { [string]: any }, -- Net Home
	Say: (words: string) -> (), -- a toast
}

local PICK = Vector2.new(360, 418)
local RESULTS = Vector2.new(340, 330)
local ROW = 26
local TILE = 48 -- a stage's tile: its button, then its line under it
local LINE = 18

local parts: { [string]: Instance } = {}
local difficulty = "Normal"

-- The keeper's name as a title: "the Lamplighter" reads "The Lamplighter".
local function keeperName(ground: string): string
	local row = Grounds.ById[ground]
	local enemy = if row and row.Keeper then Enemies.ById[row.Keeper] else nil
	local name = if enemy then enemy.Name else "the keeper"
	return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

-- What a shut stage waits for, in the player's words.
local function why(ground: string, needs: string?, waits: number?): string?
	if needs == nil then
		return nil
	elseif needs == Stages.Before then
		return `Clear Stage {waits} first`
	elseif needs == Stages.Keeper then
		return `Beat {string.lower(string.sub(keeperName(ground), 1, 1)) .. string.sub(keeperName(ground), 2)} on Normal`
	elseif needs == Stages.Ground then
		return "Not open yet"
	end
	return "Not here"
end

local function label(body: Instance, name: string, text: string, size: number, at: UDim2, box: UDim2, colour: Color3?, font: Font?): TextLabel
	local made = Text.new({
		Name = name,
		Size = size,
		Font = font or Theme.Font.Body,
		Colour = colour or Theme.Colour.Text,
		Align = Enum.TextXAlignment.Center,
		Box = box,
		Position = at,
		Parent = body,
	})
	made.Text = text
	parts[name] = made
	return made
end

local function begin(on: On, ground: string, which: string, stage: number): boolean
	local answer = on.Begin(ground, which, stage)
	if answer.Ok == true then
		Screen.Close()
		return true
	end
	local says = why(ground, answer.Needs, answer.Waits)
		or (if answer.Error == "NoLead" then "Your lead is down" elseif answer.Error == "InTry" then "Not during a challenge" else nil)
	if says then
		on.Say(says)
	end
	return false
end

function StageScreen.Pick(ground: string, view: Profile.View, on: On)
	table.clear(parts)
	local body = Screen.Open(StageScreen.Name, Grounds.ById[ground] and Grounds.ById[ground].Name or "Stages", PICK)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	parts.Body = body
	local data = view
	if Stages.Needs(data, ground, "Hard", 1) ~= nil then
		difficulty = "Normal" -- its side opens on Normal while Hard is shut; Hard's tiles then say why
	end
	local pad = Theme.Size.Pad
	local wide = PICK.X - pad * 4
	local half = (wide - Theme.Size.Gap) / 2
	local y = 0
	-- The switch.
	local switch: { [string]: TextButton } = {}
	local tiles: { TextButton } = {}
	local lines: { TextLabel } = {}
	local function paint()
		for which, button in switch do
			Button.Set(button, { Selected = which == difficulty })
		end
		local line = Stages.Line(data, ground, difficulty)
		for stage, tile in tiles do
			local needs, waits = Stages.Needs(data, ground, difficulty, stage)
			Button.Set(tile, { Disabled = why(ground, needs, waits) or false, Selected = needs == nil and stage == line.Cleared + 1 })
			local best = line.Best[stage] or 0
			local cp = Stages.Recommended(ground, difficulty, stage)
			lines[stage].Text = `Recommended {Hud.Digits(cp)} {Sheet.Said.Power}   ·   {if best > 0 then `best {Read.Clock(best)}` else "not cleared"}`
		end
	end
	for index, which in Stages.Difficulties do
		local button = Button.new({
			Name = which,
			Text = which,
			Size = UDim2.fromOffset(half, Theme.Size.Tap),
			Position = UDim2.fromOffset((index - 1) * (half + Theme.Size.Gap), y),
			Parent = body,
			OnPress = function(): boolean
				difficulty = which
				paint()
				return true
			end,
		})
		switch[which] = button
		parts[which] = button
	end
	y += Theme.Size.Tap + pad
	local count = #((Stages.Of(ground) or {}) :: { any })
	for stage = 1, count do
		local last = Stages.Last(ground, stage)
		local title = if last and last.Kind == "Keeper" then `Stage {stage}   ·   {keeperName(ground)}` else `Stage {stage}`
		local tile = Button.new({
			Name = `Stage{stage}`,
			Text = title,
			Size = UDim2.fromOffset(wide, Theme.Size.Tap),
			Position = UDim2.fromOffset(0, y),
			Parent = body,
			Under = true,
			OnPress = function(): boolean
				return begin(on, ground, difficulty, stage)
			end,
		})
		tiles[stage] = tile
		parts[`Stage{stage}`] = tile
		lines[stage] = label(body, `Stage{stage}Line`, "", Theme.Text.Caption, UDim2.fromOffset(0, y + Theme.Size.Tap + 2), UDim2.fromOffset(wide, LINE), Theme.Colour.TextDim)
		y += Theme.Size.Tap + 2 + LINE + (TILE - LINE - 2) / 2
	end
	paint()
end

function StageScreen.Results(results: { [string]: any }, on: On)
	table.clear(parts)
	local body = Screen.Open(StageScreen.Name, "Results", RESULTS)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	parts.Body = body
	local pad = Theme.Size.Pad
	local wide = RESULTS.X - pad * 4
	local ground, which, stage = results.Ground :: string, results.Difficulty :: string, results.Stage :: number
	local y = 0
	local function line(name: string, text: string, size: number, colour: Color3?, font: Font?, tall: number?)
		label(body, name, text, size, UDim2.fromOffset(0, y), UDim2.fromOffset(wide, tall or ROW), colour, font)
		y += (tall or ROW) + 2
	end
	local named = if which == "Hard" then `Hard Stage {stage}` else `Stage {stage}`
	if results.Won then
		line("Title", `{named} cleared`, Theme.Text.Big, Theme.Colour.Text, Theme.Font.Number, 36)
		local seconds, best = results.Seconds :: number?, results.Best :: number?
		if seconds then
			line("Time", if best and best >= seconds then `{Read.Clock(seconds)}   ·   a new best` else `{Read.Clock(seconds)}   ·   best {Read.Clock(best or seconds)}`, Theme.Text.Body, Theme.Colour.TextDim)
		end
		local gave = {}
		if (results.Credits or 0) > 0 then
			table.insert(gave, `+{Hud.Digits(results.Credits)} Credits`)
		end
		if (results.Shards or 0) > 0 then
			table.insert(gave, `{Hud.Digits(results.Shards)} {if results.Shards == 1 then "shard" else "shards"}`)
		end
		if (results.Chests or 0) > 0 then
			table.insert(gave, `{Hud.Digits(results.Chests)} {if results.Chests == 1 then "chest" else "chests"}`)
		end
		line("Gave", if #gave > 0 then table.concat(gave, "   ·   ") else "Nothing dropped this time", Theme.Text.Body, if #gave > 0 then Theme.Colour.Credits else Theme.Colour.TextDim, Theme.Font.Number)
		local opened = results.Opened :: string?
		if opened == "Hard" then
			line("Opened", "Hard is open", Theme.Text.Big, Theme.Colour.Ready, Theme.Font.Strong, 34)
		elseif opened == "Stage" and results.Next then
			line("Opened", `{if which == "Hard" then "Hard " else ""}Stage {results.Next} is open`, Theme.Text.Body, Theme.Colour.Ready, Theme.Font.Strong)
		end
	else
		line("Title", "Your lead fell", Theme.Text.Big, Theme.Colour.Hurt, Theme.Font.Number, 36)
		line("Time", `{named}: try it again, or grow first`, Theme.Text.Body, Theme.Colour.TextDim)
	end
	-- Retry, Next, Home.
	local presses: { { Name: string, Text: string, Primary: boolean, Press: () -> boolean } } = {
		{ Name = "Retry", Text = "Retry", Primary = not results.Won, Press = function(): boolean
			return begin(on, ground, which, stage)
		end },
	}
	local nextStage = results.Next :: number?
	if results.Won and nextStage then
		table.insert(presses, { Name = "Next", Text = `Stage {nextStage}`, Primary = true, Press = function(): boolean
			return begin(on, ground, which, nextStage)
		end })
	end
	table.insert(presses, { Name = "Home", Text = "Home", Primary = false, Press = function(): boolean
		local answer = on.Home()
		if answer.Ok == true then
			Screen.Close()
			return true
		end
		if type(answer.Says) == "string" and answer.Says ~= "" then
			on.Say(answer.Says)
		end
		return false
	end })
	local gap = Theme.Size.Gap
	local each = (wide - gap * (#presses - 1)) / #presses
	local at = math.max(y + 8, RESULTS.Y - Screen.Head - Theme.Size.Tap - pad * 2)
	for index, press in presses do
		parts[press.Name] = Button.new({
			Name = press.Name,
			Text = press.Text,
			Size = UDim2.fromOffset(each, Theme.Size.Tap),
			Position = UDim2.fromOffset((index - 1) * (each + gap), at),
			Parent = body,
			Primary = press.Primary,
			OnPress = press.Press,
		})
	end
end

function StageScreen.Parts(): { [string]: Instance }
	return parts
end

function StageScreen.Difficulty(): string
	return difficulty
end

return StageScreen
