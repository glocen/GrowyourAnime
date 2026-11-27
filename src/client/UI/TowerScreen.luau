--!strict
-- TowerScreen (client): a Tower run's results, in grey (TR29; docs/design.md, "The Tower", "Death ends the run"). The
-- highest floor this run and the record if it's beaten, the floors won, the Credits and the chests won, from
-- the save's Progress.Tower.Results (the server's, written once by the run's end). In the base, Retry sets the avatar in
-- its ring to climb again once rested, and Home sets it down at its plot's spawn (TR46); elsewhere a crash's results
-- close. Closing it, by a press or its exit, tells the server they've been seen (Act "TowerSeen"), so they open once.
-- The week's board (TR46): a line under the rewards, "This week: #12 · floor 23" once the server answers (Net
-- "TowerBoard"); a tap on it shows the board on the card, "This week's climb", the top rows and the player's own, and a
-- tap on the board goes back. The rarity light on a rare reward, the card's art and the board's look wait for the shared finish.
--   TowerScreen.Open(results, on)   builds it (on: Act, Retry, Home, Board)
--   TowerScreen.Ask(won, leave)     the HUD's Leave asks first (TR67): "Leave the Tower?", Leave or Stay; `won` the
--                                   floors the run has won, `leave` the press that ends it (true when it did)
--   TowerScreen.Parts()             its pieces by name, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local TowerConfig = require(Shared.Config.Tower)
local ChestRows = require(Shared.Definitions.Chests)
local Hud = require(Shared.Rules.Hud)
local Tower = require(Shared.Rules.Tower)
local PlaceRole = require(Shared.Util.PlaceRole)

local UI = script.Parent
local Theme = require(UI.Theme)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Refuse = require(UI.Kit.Refuse)

local TowerScreen = {}
TowerScreen.Name = "Tower"
TowerScreen.AskName = "TowerLeave"

export type On = {
	Act: (name: string, args: any?) -> { [string]: any },
	Retry: () -> { [string]: any }, -- Net "TowerRetry"
	Home: () -> { [string]: any }, -- Net "TowerHome"
	Board: () -> { [string]: any }, -- Net "TowerBoard"
}

local SIZE = Vector2.new(340, 344)
local ASK_SIZE = Vector2.new(320, 196) -- the Leave's question: its line and two presses
local ROW = 26
local ROW_LEAST = 20 -- the results' rows close up to this on a short phone, a Body line still clear
local BOARD_ROW = 19 -- a row of the board, in Caption
local BOARD_LEAST = 16 -- and the board's, on the smallest phone (Theme.Smallest)

local parts: { [string]: Instance } = {}
local said: string? = nil -- the last refusal a press said (for tests)
local shown: string? = nil
local closing: { [string]: boolean } = {} -- results already told seen, so a closed screen asks once
local taps: { [string]: () -> () } = {} -- the week's line and the board, by name: what a tap on each does

-- The board in the card's body, `wide` by `tall`, from the server's answer: its title with "Back" at its left, a row a
-- climber (rank, name, floor; the player's own in the record's colour), and the player's own under them when it's
-- further down. Its rows close up to fit a short phone. It stands on the card's own backing: the results step aside
-- while it shows, and a tap anywhere on it brings them back. Returns its switch.
local function boardView(body: Frame, wide: number, tall: number, answer: { [string]: any }): (boolean) -> ()
	local view = Instance.new("TextButton")
	view.Name = "Board"
	view.Text = ""
	view.AutoButtonColor = false
	view.BorderSizePixel = 0
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromOffset(wide, tall)
	view.ZIndex = 5
	view.Visible = false
	view.Parent = body
	parts.Board = view
	local rows = if type(answer.Rows) == "table" then answer.Rows else {}
	local listed = false
	for _, each in rows do
		listed = listed or each.Mine == true
	end
	-- The title's row, then a row a climber, and the player's own under a small break when it isn't listed.
	local count = #rows + (if listed then 0 else 1)
	local step = math.clamp(math.floor((tall - ROW - 2 - (if listed then 0 else 4)) / math.max(1, count)), BOARD_LEAST, BOARD_ROW)
	local y = 0
	local function put(name: string, text: string, x: number, w: number, colour: Color3, font: Font?, align: Enum.TextXAlignment?, size: number?, tall_: number?): TextLabel
		local label = Text.new({
			Name = name,
			Size = size or Theme.Text.Caption,
			Font = font or Theme.Font.Body,
			Colour = colour,
			Align = align or Enum.TextXAlignment.Left,
			Box = UDim2.fromOffset(w, tall_ or step),
			Position = UDim2.fromOffset(x, y),
			Parent = view,
			Truncate = true,
		})
		label.Text = text
		label.ZIndex = 6
		parts[name] = label
		return label
	end
	put("BoardTitle", "This week's climb", 0, wide, Theme.Colour.Text, Theme.Font.Strong, Enum.TextXAlignment.Center, Theme.Text.Body, ROW)
	put("BoardBack", "Back", 0, 60, Theme.Colour.TextDim, nil, Enum.TextXAlignment.Left, Theme.Text.Caption, ROW)
	y += ROW + 2
	local rankWide, floorWide = 40, 70
	local function row(name: string, rank: number?, who: string, floor: number, mine: boolean)
		local colour = if mine then Theme.Colour.Ready else Theme.Colour.Text
		local font = if mine then Theme.Font.Strong else Theme.Font.Body
		put(`{name}Rank`, if rank then `#{rank}` else `#{TowerConfig.Board.Page}+`, 0, rankWide, colour, font)
		put(`{name}Name`, if who ~= "" then who else "—", rankWide, wide - rankWide - floorWide, colour, font)
		put(`{name}Floor`, `floor {floor}`, wide - floorWide, floorWide, colour, font, Enum.TextXAlignment.Right)
		y += step
	end
	for index, each in rows do
		row(`Row{index}`, each.Rank, each.Name or "", each.Floor, each.Mine == true)
	end
	local mine = answer.Mine
	if not listed then
		y += 4
		if type(mine) == "table" then
			row("Mine", mine.Rank, Players.LocalPlayer.DisplayName, mine.Floor, true)
		else
			put("Mine", Tower.WeekLine(nil), 0, wide, Theme.Colour.TextDim, nil, Enum.TextXAlignment.Center)
			y += step
		end
	end
	local aside: { GuiObject } = {}
	local function show(on: boolean)
		if on and not view.Visible then
			for _, child in body:GetChildren() do
				if child ~= view and child:IsA("GuiObject") and child.Visible then
					child.Visible = false
					table.insert(aside, child)
				end
			end
		elseif not on then
			for _, child in aside do
				child.Visible = true
			end
			table.clear(aside)
		end
		view.Visible = on
	end
	local function back()
		show(false)
	end
	view.Activated:Connect(back)
	taps.Board = back
	return show
end

function TowerScreen.Open(results: Profile.TowerResults, on: On)
	table.clear(parts)
	table.clear(taps)
	shown = results.Id
	local body = Screen.Open(TowerScreen.Name, "Tower", SIZE)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	local pad = Theme.Size.Pad
	-- The body as the panel was fitted: a phone's room is shorter than the card's authored height. The body starts two
	-- pads in on each side and under the head (Screen.Head's note), as the stage card's.
	local panel = body.Parent :: Frame
	local wide = panel.Size.X.Offset - pad * 4
	local room = panel.Size.Y.Offset - Screen.Head - pad
	local names = {}
	for id in results.Chests do
		table.insert(names, id)
	end
	table.sort(names)
	-- The rows close up when the lines would push the buttons out of the body, down to ROW_LEAST; past that (many chests
	-- on a small phone) the lines scroll above the buttons, as the bag's card's do.
	local above = pad + 36 + 2 + 4 + 4 + 6 -- the floor's line, the two breaks, the gap over the buttons
	local foot = room - Theme.Size.Tap
	local lines = 4 + math.max(1, #names) -- the record, the defeated, the Credits, the chests, the week
	local row = ROW
	if above + lines * (ROW + 2) > foot then
		row = math.clamp(math.floor((foot - above) / lines) - 2, ROW_LEAST, ROW)
	end
	local holder: GuiObject = body
	local list: ScrollingFrame? = nil
	if above + lines * (row + 2) > foot then
		local made = Instance.new("ScrollingFrame")
		made.Name = "Lines"
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.Size = UDim2.fromOffset(wide, foot - 6)
		made.ScrollBarThickness = 4
		made.ScrollBarImageColor3 = Theme.Colour.TextDim
		made.ScrollingDirection = Enum.ScrollingDirection.Y
		made.Parent = body
		parts.Lines = made
		holder = made
		list = made
	end
	local y = pad
	local function line(name: string, text: string, size: number, colour: Color3?, font: Font?, tall: number?)
		local label = Text.new({
			Name = name,
			Size = size,
			Font = font or Theme.Font.Body,
			Colour = colour or Theme.Colour.Text,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(wide, tall or row),
			Position = UDim2.fromOffset(0, y),
			Parent = holder,
		})
		label.Text = text
		parts[name] = label
		y += (tall or row) + 2
		return label
	end
	line("Floor", `Floor {results.Floor}`, Theme.Text.Big, Theme.Colour.Text, Theme.Font.Number, 36)
	if results.Record then
		line("Record", if results.Best > 0 then `A new record, past floor {results.Best}` else "A new record", Theme.Text.Body, Theme.Colour.Ready, Theme.Font.Strong)
	else
		line("Record", `Your record: floor {results.Best}`, Theme.Text.Body, Theme.Colour.TextDim)
	end
	y += 4
	line("Defeated", `{results.Floor} {if results.Floor == 1 then "floor" else "floors"} won`, Theme.Text.Body)
	line("Credits", `+{Hud.Digits(results.Credits)} Credits`, Theme.Text.Body, Theme.Colour.Credits, Theme.Font.Number)
	local function chest(id: string): string
		local each = ChestRows.ById[id]
		return `{if each then each.Name else id} ×{Hud.Digits(results.Chests[id])}`
	end
	if #names == 0 then
		line("Chests", "No chests this run", Theme.Text.Caption, Theme.Colour.TextDim)
	else
		for index, id in names do
			line(`Chest{index}`, chest(id), Theme.Text.Body)
		end
	end
	-- The week's line: dim until the server answers, then the player's place this week, a tap away from the board. An
	-- answer that doesn't come takes the line away rather than leave it waiting.
	y += 4
	local week = Instance.new("TextButton")
	week.Name = "Week"
	week.Text = ""
	week.AutoButtonColor = false
	week.BackgroundTransparency = 1
	week.Size = UDim2.fromOffset(wide, row)
	week.Position = UDim2.fromOffset(0, y)
	week.Active = false
	week.Parent = holder
	parts.Week = week
	local words = Text.new({
		Name = "Words",
		Size = Theme.Text.Body,
		Font = Theme.Font.Body,
		Colour = Theme.Colour.TextDim,
		Align = Enum.TextXAlignment.Center,
		Box = UDim2.fromScale(1, 1),
		Parent = week,
	})
	words.Text = "This week: …"
	parts.WeekWords = words
	local under = Instance.new("Frame")
	under.Name = "Under"
	under.BorderSizePixel = 0
	under.BackgroundColor3 = Theme.Colour.TextDim
	under.AnchorPoint = Vector2.new(0.5, 1)
	under.Position = UDim2.fromScale(0.5, 1)
	under.Visible = false
	under.Parent = week
	y += row + 2
	if list then
		list.CanvasSize = UDim2.fromOffset(0, y)
	end
	task.spawn(function()
		local ok, answer = pcall(on.Board)
		if shown ~= results.Id or week.Parent == nil then
			return
		end
		if not ok or type(answer) ~= "table" or answer.Ok ~= true then
			week.Visible = false
			return
		end
		words.Text = Tower.WeekLine(answer.Mine :: any)
		words.TextColor3 = Theme.Colour.Text
		under.Size = UDim2.fromOffset(math.min(wide, Text.Wide(words, words.Text)), 1)
		under.Visible = true
		week.Active = true
		local show = boardView(body, wide, room, answer)
		local function open()
			show(true)
		end
		week.Activated:Connect(open)
		taps.Week = open
	end)
	-- Retry and Home in the base, where the Tower stands; Close wherever a crash's results open instead.
	local function asked(ask: () -> { [string]: any }, what: string): () -> boolean
		return function(): boolean
			local ok, answer = pcall(ask)
			if ok and type(answer) == "table" and answer.Ok == true then
				Screen.Close()
				return true
			end
			-- refused: said, never silent (research's launch bug 1: Retry after a fall, the lead still healing)
			said = Refuse.Show("Tower", if ok and type(answer) == "table" then answer else nil, nil, `TowerScreen {what}`)
			return false
		end
	end
	local presses = if PlaceRole.Is("Main")
		then { { "Retry", asked(on.Retry, "Retry"), true }, { "Home", asked(on.Home, "Home"), false } }
		else { { "Close", function(): boolean
			Screen.Close()
			return true
		end, true } }
	local gap = Theme.Size.Gap
	local each = (wide - gap * (#presses - 1)) / #presses
	local at = if list then foot else math.max(y + 6, room - Theme.Size.Tap - pad)
	for index, press in presses do
		local name = press[1] :: string
		parts[name] = Button.new({
			Name = name,
			Text = name,
			Size = UDim2.fromOffset(each, Theme.Size.Tap),
			Position = UDim2.fromOffset((index - 1) * (each + gap), at),
			Parent = body,
			Primary = press[3] :: boolean,
			OnPress = press[2] :: () -> boolean,
		})
	end
	parts.Body = body
	local id = results.Id
	Screen.Closed:Once(function(name: string)
		if name == TowerScreen.Name and not closing[id] then
			closing[id] = true
			task.spawn(on.Act, "TowerSeen", { Id = id })
		end
	end)
end

-- What the question says the run keeps: the floors it has won, in the results' own words.
function TowerScreen.AskLine(won: number): string
	if won < 1 then
		return "Your run ends before its first floor is won"
	end
	return `Your run ends at floor {won}, and you keep what it won`
end

function TowerScreen.Ask(won: number, leave: () -> boolean)
	table.clear(parts)
	local body = Screen.Open(TowerScreen.AskName, "Leave the Tower?", ASK_SIZE)
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	local pad = Theme.Size.Pad
	local panel = body.Parent :: Frame
	local wide = panel.Size.X.Offset - pad * 4
	local room = panel.Size.Y.Offset - Screen.Head - pad
	local words = Text.new({
		Name = "AskLine",
		Size = Theme.Text.Body,
		Font = Theme.Font.Body,
		Colour = Theme.Colour.Text,
		Align = Enum.TextXAlignment.Center,
		Box = UDim2.fromOffset(wide, room - Theme.Size.Tap - pad * 2),
		Position = UDim2.fromOffset(0, pad),
		Parent = body,
		Wrap = true,
	})
	words.Text = TowerScreen.AskLine(won)
	parts.AskLine = words
	local gap = Theme.Size.Gap
	local each = (wide - gap) / 2
	local at = room - Theme.Size.Tap - pad
	parts.Leave = Button.new({
		Name = "Leave",
		Text = "Leave",
		Size = UDim2.fromOffset(each, Theme.Size.Tap),
		Position = UDim2.fromOffset(0, at),
		Parent = body,
		Quiet = true,
		OnPress = function(): boolean
			if leave() then
				if Screen.Current() == TowerScreen.AskName then
					Screen.Close()
				end
				return true
			end
			return false
		end,
	})
	parts.Stay = Button.new({
		Name = "Stay",
		Text = "Stay",
		Size = UDim2.fromOffset(each, Theme.Size.Tap),
		Position = UDim2.fromOffset(each + gap, at),
		Parent = body,
		Primary = true, -- the run goes on: the safe press is the main one
		OnPress = function(): boolean
			Screen.Close()
			return true
		end,
	})
	parts.Body = body
end

-- The id of the results last opened: whether those on screen are the ones the save holds.
function TowerScreen.Shown(): string?
	return shown
end

-- Whether results `id` were told seen from this client.
-- For tests: the words the last refused press said, or nil.
function TowerScreen.Said(): string?
	return said
end

function TowerScreen.Told(id: string): boolean
	return closing[id] == true
end

-- For tests: a tap on the week's line ("Week") or the board ("Board"), as a finger's. False before it can be tapped.
function TowerScreen.Tap(name: string): boolean
	local tap = taps[name]
	if tap == nil then
		return false
	end
	tap()
	return true
end

function TowerScreen.Parts(): { [string]: Instance }
	return parts
end

return TowerScreen
