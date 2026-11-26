--!strict
-- TodayList (client UI): today's three on Home's panel (TR54; AR53 in B, build/handoff/UI/goals/goals.json, "today";
-- its numbers Config.Hud.Home.Today, its words Definitions.Goals). The Today card under Settings' cog shows the shard a
-- goal pays, three pips for today's three (open, done, claimed) and, while any goal or the welcome week's gift waits to be
-- claimed, its rim in gold.
-- Its press opens the list in the glass alone, the cards hidden: Next pinned at its head with the back press (the
-- account's one next step and what it opens), then today's three, then any banked day under its heading, scrolling
-- under Next. A row leans: open, its shard dim and a count where the goal counts; done, the whole row is the claim's
-- press, lit gold; claimed, it sinks and takes a check until the day turns. A claim is the "GoalClaim" action. From the
-- first session's script's end, the welcome week's seven head the list under their heading (TR59, Rules.Welcome): today's
-- lit and taken with one tap ("WelcomeClaim"), later ones dim, taken ones checked, until the day the seventh is taken.
--   TodayList.Attach(panel, act)   the card's pieces and the list on Home's panel; act runs an action
--   TodayList.View(panel, view)    the save's copy shown: the card, and the list when it shows
--   TodayList.Show(panel), TodayList.Hide(panel)   the list in the glass, or the cards again
--   TodayList.Shown(panel) -> boolean
--   TodayList.Said(panel) -> { [string]: any }   what shows, for tests: Next's lines, each row's words and state

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Profile = require(Shared.Data.Profile)
local Goals = require(Shared.Rules.Goals)
local GoalFacts = require(Shared.Rules.GoalFacts)
local Defs = require(Shared.Definitions.Goals)
local ChestRows = require(Shared.Definitions.Chests)
local WelcomeConfig = require(Shared.Config.Welcome)
local Welcome = require(Shared.Rules.Welcome)

local UI = script.Parent
local Button = require(UI.Kit.Button)
local Fade = require(UI.Kit.Fade)
local Glass = require(UI.Kit.Glass)
local Toast = require(UI.Kit.Toast)
local HomePanel = require(UI.HomePanel)

local TodayList = {}

local HOME = HudConfig.Home
local T = HOME.Today
local R = T.Rows
local WK = T.Week
local FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Italic)
local STRONG = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
local LEFT = 16 -- the scrolling frame starts at the glass image's left, so a row's leaning image isn't cut

type Act = (name: string, args: any) -> { [string]: any }
type Row = { Day: number, Slot: number, Id: string, Text: string, State: string, Right: string, Button: TextButton?, Press: ImageLabel? }
type List = {
	Panel: HomePanel.Panel,
	Act: Act,
	Frame: Frame,
	Scroll: ScrollingFrame,
	Thumb: Frame,
	Next: Frame,
	Back: TextButton,
	Rows: { Row },
	Week: { { Index: number, State: string, Button: TextButton? } }, -- the welcome week's tiles, while shown
	Lines: { string },
	Waits: ImageLabel,
	Pips: { ImageLabel },
	Shown: boolean,
	Switch: number, -- how much of the list shows against the cards, 0 to 1
	Token: number, -- the newest switch; an older one's beat stops
	Key: string, -- what the list was last built from
	View: Profile.View?,
}

local lists: { [HomePanel.Panel]: List } = {}

local function image(parent: Instance, name: string, x: number, y: number, w: number, h: number, z: number): ImageLabel
	local record = UIKit.Images[name]
	assert(record, `UIKit has no image "{name}"`)
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.Image = record.Id
	made.ScaleType = Enum.ScaleType.Stretch
	made.Position = UDim2.fromOffset(x, y)
	made.Size = UDim2.fromOffset(w, h)
	made.ZIndex = z
	made:SetAttribute("Kit", name)
	made.Parent = parent
	return made
end

-- A word in Home's leaning face, its capitals' top at y; its left at x, or its right (Right).
local function word(parent: Instance, name: string, said: string, x: number, y: number, size: number, colour: Color3, strong: boolean, align: string?, z: number): TextLabel
	local made = Instance.new("TextLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.FontFace = if strong then STRONG else FACE
	made.TextSize = size
	made.Text = said
	made.TextColor3 = colour
	made.TextXAlignment = if align == "Right" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	made.TextYAlignment = Enum.TextYAlignment.Top
	made.AnchorPoint = Vector2.new(if align == "Right" then 1 else 0, 0)
	made.Size = UDim2.fromOffset(300, math.ceil(size * 1.4))
	made.Position = UDim2.fromOffset(x, y - HOME.CapTop * size)
	made.ZIndex = z
	made.Parent = parent
	return made
end

-- A stroke from a to b, `width` wide.
local function stroke(parent: Instance, name: string, a: Vector2, b: Vector2, width: number, colour: Color3, z: number)
	local d = b - a
	local line = Instance.new("Frame")
	line.Name = name
	line.BorderSizePixel = 0
	line.BackgroundColor3 = colour
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	line.Size = UDim2.fromOffset(d.Magnitude + width * 0.6, width)
	line.Rotation = math.deg(math.atan2(d.Y, d.X))
	line.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = line
	line.Parent = parent
end

-- "0:15 / 1:00" for a goal counted in seconds, "1 / 3" for one counted in things, nothing for a goal of one.
local function counted(row: any, have: number): string
	if row.Need <= 1 then
		return ""
	elseif row.Need >= 60 then
		local function clock(seconds: number): string
			local minutes = math.floor(seconds / 60)
			return string.format("%d:%02d", minutes // 60, minutes % 60)
		end
		return `{clock(math.min(have, row.Need))} / {clock(row.Need)}`
	end
	return `{math.floor(math.min(have, row.Need))} / {row.Need}`
end

local function stateOf(day: any, slot: number, row: any): string
	if day.Claimed[slot] then
		return "Claimed"
	elseif (day.Have[slot] or 0) >= row.Need then
		return "Done"
	end
	return "Open"
end

-- Next's two lines: the step, then what it opens; the last line alone.
local function nextLines(view: Profile.View): { string }
	local index = Goals.Next(Defs.Next, GoalFacts.Of(view))
	local step = Defs.Next[math.min(index, #Defs.Next)]
	return if step.Opens then { step.Text, step.Opens } else { step.Text }
end

local function layNext(list: List, lines: { string })
	for _, child in list.Next:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local N = T.Next
	local L = N.Lines
	local function x(y: number): number
		return N.Left + L.X + L.Lean * (L.Base - y)
	end
	local y1 = if #lines == 1 then L.Alone else L.Y[1]
	word(list.Next, "Label", Defs.Labels.Next, x(y1), N.Top + y1, L.Size, N.Label.Colour, true, nil, 8)
	word(list.Next, "Step", lines[1], x(y1) + N.Label.Step, N.Top + y1, L.Size, L.Colours[1], false, nil, 8)
	if lines[2] then
		word(list.Next, "Opens", lines[2], x(L.Y[2]), N.Top + L.Y[2], L.Size, L.Colours[2], false, nil, 8)
	end
end

local function claim(list: List, row: Row): boolean
	local answer = list.Act("GoalClaim", { Day = row.Day, Slot = row.Slot })
	return answer.Ok == true
end

-- The server's UTC day (Goals.DayOf), as the claim reads it.
local function today(): number
	return Goals.DayOf(workspace:GetServerTimeNow())
end

-- The welcome week's row shows from the first session's script's end until the day its seventh is taken.
local function weekShown(view: Profile.View, day: number): boolean
	local held = view.Welcome
	return Welcome.Shown(view) and (held == nil or held.Taken < #WelcomeConfig.Week or held.Last == day)
end

local function weekClaim(list: List): boolean
	local answer = list.Act("WelcomeClaim", {})
	if answer.Ok == true and answer.Gift then
		Toast.Show(`{WK.Day} {answer.Day}: {Welcome.Said(answer.Gift :: any)}`, WK.Lit)
	end
	return answer.Ok == true
end

-- The welcome week's heading and seven tiles from y; the y under them.
local function layWeek(list: List, view: Profile.View, y: number): number
	local day = today()
	if not weekShown(view, day) then
		return y
	end
	local D = T.Day
	local heading = Instance.new("Frame")
	heading.Name = "WeekHeading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.fromOffset(0, y)
	heading.Size = UDim2.fromOffset(LEFT + HOME.Size.X, D.Tall)
	heading.ZIndex = 6
	heading.Parent = list.Scroll
	word(heading, "Words", WK.Heading, LEFT + D.X, D.Y, D.Size, D.Colour, false, nil, 7)
	y += D.Tall
	local states = Welcome.Row(view, day)
	local wide = (R.Wide - (#states - 1) * WK.Gap) / #states
	for index, state in states do
		local gift = WelcomeConfig.Week[index]
		local lit = state == "Today"
		local tile = Instance.new("Frame")
		tile.Name = `Week{index}`
		tile.BackgroundColor3 = (WK.Fill :: any)[state]
		tile.BorderSizePixel = 0
		tile.Position = UDim2.fromOffset(LEFT + R.Left + (index - 1) * (wide + WK.Gap), y)
		tile.Size = UDim2.fromOffset(wide, WK.Tall)
		tile.ZIndex = 6
		tile:SetAttribute("State", state)
		tile.Parent = list.Scroll
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, WK.Corner)
		corner.Parent = tile
		if lit then
			local rim = Instance.new("UIStroke")
			rim.Color = WK.Lit
			rim.Thickness = WK.Stroke
			rim.Parent = tile
		end
		local said = word(tile, "Day", `{WK.Day} {index}`, wide / 2, WK.Words.Y, WK.Words.Size, if lit then WK.Lit else WK.Words.Colour, lit, nil, 8)
		said.AnchorPoint = Vector2.new(0.5, 0)
		said.Size = UDim2.fromOffset(wide, said.Size.Y.Offset)
		said.TextXAlignment = Enum.TextXAlignment.Center
		local P = WK.Picture
		local name = if gift.Chest then (ChestRows.ById[gift.Chest] or {} :: any).Image elseif gift.Shard == "named_lyric" then P.Face else P.Shard
		if state == "Taken" then
			-- taken: the check alone on its dimmed tile, the gift's picture and words gone (research's must-fix, 2026-11-26)
			local C = R.Check
			image(tile, C.Image, (wide - WK.Check) / 2, P.Y + (P.Side - WK.Check) / 2, WK.Check, WK.Check, 9)
		elseif name and UIKit.Images[name] then
			local picture = image(tile, name, (wide - P.Side) / 2, P.Y, P.Side, P.Side, 8)
			picture.ScaleType = Enum.ScaleType.Fit
			picture.ImageTransparency = (WK.Dim :: any)[state]
		else -- a picture not made yet (TR56's three): its kind's words in its place, "Emblem Case" for "... of Lantern Row"
			local row = if gift.Chest then ChestRows.ById[gift.Chest] else nil
			local kind = if row then (string.split(row.Name, " of "))[1] else ""
			local stand = Instance.new("TextLabel")
			stand.Name = "Gift"
			stand.BackgroundTransparency = 1
			stand.FontFace = FACE
			stand.TextSize = WK.Words.Size - 1
			stand.TextWrapped = true
			stand.Text = kind
			stand.TextColor3 = HOME.Word
			stand.TextTransparency = (WK.Words.Fade :: any)[state]
			stand.Position = UDim2.fromOffset(2, P.Y)
			stand.Size = UDim2.fromOffset(wide - 4, P.Side)
			stand.ZIndex = 8
			stand.Parent = tile
		end
		local made: { Index: number, State: string, Button: TextButton? } = { Index = index, State = state, Button = nil }
		if lit then
			local button = Button.new({
				Name = "Take",
				Text = "",
				Bare = true,
				Size = UDim2.fromScale(1, 1),
				Parent = tile,
				OnPress = function(): boolean
					return weekClaim(list)
				end,
			})
			button.ZIndex = 10
			made.Button = button
		end
		table.insert(list.Week, made)
	end
	return y + WK.Tall + R.Gap + R.Pad[1]
end

local function layRows(list: List, view: Profile.View)
	for _, child in list.Scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(list.Rows)
	table.clear(list.Week)
	local days: { any } = view.Goals and view.Goals.Days or {}
	local newest = if #days > 0 then days[#days].Day else 0
	local y = layWeek(list, view, R.Pad[1])
	-- today's first, then each banked day newest first under its heading, while any of it is left to claim
	for i = #days, 1, -1 do
		local day = days[i]
		local back = newest - day.Day
		if back > 0 then
			local open = false
			for slot, id in day.Picks do
				local row = Defs.ById[id]
				if row and not day.Claimed[slot] then
					open = true
				end
			end
			if not open then
				continue
			end
			local D = T.Day
			local heading = Instance.new("Frame")
			heading.Name = `Day{back}`
			heading.BackgroundTransparency = 1
			heading.Position = UDim2.fromOffset(0, y)
			heading.Size = UDim2.fromOffset(LEFT + HOME.Size.X, D.Tall)
			heading.ZIndex = 6
			heading.Parent = list.Scroll
			word(heading, "Words", Defs.Labels.Days[back] or "", LEFT + D.X, D.Y, D.Size, D.Colour, false, nil, 7)
			y += D.Tall
		end
		for slot, id in day.Picks do
			local def = Defs.ById[id]
			if def == nil then
				continue
			end
			local state = stateOf(day, slot, def)
			local holder = Instance.new("Frame")
			holder.Name = `Row{day.Day}_{slot}`
			holder.BackgroundTransparency = 1
			holder.Position = UDim2.fromOffset(LEFT + R.Left, y)
			holder.Size = UDim2.fromOffset(R.Wide, R.Tall)
			holder.ZIndex = 6
			holder:SetAttribute("Goal", id)
			holder:SetAttribute("State", state)
			holder.Parent = list.Scroll
			image(holder, (R.Images :: any)[state], -R.Origin.X, -R.Origin.Y, R.Size.X, R.Size.Y, 6)
			word(holder, "Words", def.Text, R.Words.X, R.Words.Y, R.Words.Size, if state == "Claimed" then R.Words.Claimed else R.Words.Colour, false, nil, 9)
			local right = ""
			if state == "Claimed" then
				local C = R.Check
				image(holder, C.Image, C.At.X - C.Side / 2, C.At.Y - C.Side / 2, C.Side, C.Side, 9)
			else
				local S = R.Shard
				local shard = image(holder, "ShardStandardSmall", S[1], S[2], S[3], S[4], 9)
				shard.ImageTransparency = if state == "Open" then 1 - S.Open else 0
				if state == "Done" then
					right = Defs.Labels.Claim
					word(holder, "Right", right, R.Right.X, R.Right.Y, R.Right.Size, R.Right.Claim, true, "Right", 9)
				else
					right = counted(def, day.Have[slot] or 0)
					if right ~= "" then
						word(holder, "Right", right, R.Right.X, R.Right.Y, R.Right.Size, R.Right.Count, false, "Right", 9)
					end
				end
			end
			local made: Row = { Day = day.Day, Slot = slot, Id = id, Text = def.Text, State = state, Right = right, Button = nil, Press = nil }
			if state == "Done" then
				local press = image(holder, R.Images.Press, -R.Origin.X, -R.Origin.Y, R.Size.X, R.Size.Y, 7)
				press.Visible = false
				made.Press = press
				local button = Button.new({
					Name = "Claim",
					Text = "",
					Bare = true,
					Size = UDim2.fromScale(1, 1),
					Parent = holder,
					OnPress = function(): boolean
						return claim(list, made)
					end,
				})
				button.ZIndex = 10
				made.Button = button
			end
			table.insert(list.Rows, made)
			y += R.Tall + R.Gap
		end
	end
	y += R.Pad[2] - R.Gap
	list.Scroll.CanvasSize = UDim2.fromOffset(0, y)
end

local function thumb(list: List)
	local room = list.Scroll.AbsoluteWindowSize.Y
	local whole = list.Scroll.AbsoluteCanvasSize.Y
	local high = HOME.Size.Y - R.From
	if whole <= room + 1 or room <= 0 then
		list.Thumb.Visible = false
		return
	end
	local share = room / whole
	local at = list.Scroll.CanvasPosition.Y / math.max(whole - room, 1)
	list.Thumb.Visible = true
	list.Thumb.Size = UDim2.fromOffset(T.Thumb.Wide, high * share)
	list.Thumb.Position = UDim2.fromOffset(T.Thumb.X, R.From + (high - high * share) * at)
end

local function build(list: List, view: Profile.View)
	local lines = nextLines(view)
	local now = today()
	local held = view.Welcome
	local key = `{table.concat(lines, "|")}#{now}:{weekShown(view, now)}:{if held then `{held.Taken}:{held.Last}` else ""}#`
	for _, day in (view.Goals and view.Goals.Days or {}) do
		key ..= `{day.Day}:{table.concat(day.Picks, ",")}:{table.concat(day.Have :: any, ",")}:{tostring(day.Claimed[1])}{tostring(day.Claimed[2])}{tostring(day.Claimed[3])};`
	end
	if key == list.Key then
		return
	end
	list.Key = key
	list.Lines = lines
	layNext(list, lines)
	layRows(list, view)
	task.defer(thumb, list)
end

local function card(list: List, view: Profile.View)
	local days: { any } = view.Goals and view.Goals.Days or {}
	local day = today()
	local gift = weekShown(view, day) and table.find(Welcome.Row(view, day), "Today") ~= nil
	list.Waits.Visible = gift or Goals.Waits(view.Goals :: any, Defs.ById) > 0
	local today = days[#days]
	for i, pip in list.Pips do
		local id = if today then today.Picks[i] else nil
		local def = if id then Defs.ById[id] else nil
		local state = if def and today then stateOf(today, i, def) else "Open"
		local name = (T.Pips.Images :: any)[state]
		pip.Image = UIKit.Images[name].Id
		pip:SetAttribute("Kit", name)
		pip.Visible = def ~= nil
	end
end

function TodayList.Attach(panel: HomePanel.Panel, act: Act)
	local today = panel.Cards.Today
	assert(today, "Home has no Today card")
	-- the card's own pieces, in its holder so they land and fade with it
	local tap = today.Def.Tap
	local function at(x: number, y: number): (number, number)
		return x - tap[1], y - tap[2]
	end
	-- over the card's art (1) and under its press, which is over them both and under its words, shard and pips
	for _, child in today.Holder:GetChildren() do
		if child:IsA("TextLabel") then
			child.ZIndex += 3
		end
	end
	today.Press.ZIndex = 3
	local W: { any }, S: { any } = T.Waits, T.Shard
	local wx, wy = at(W[2], W[3])
	local waits = image(today.Holder, W[1], wx, wy, W[4], W[5], 2)
	waits.Visible = false
	local sx, sy = at(S[2], S[3])
	image(today.Holder, S[1], sx, sy, S[4], S[5], 4)
	local pips = {}
	for i, px in T.Pips.X do
		local x, y = at(px, T.Pips.Y)
		local side = T.Pips.Side
		table.insert(pips, image(today.Holder, T.Pips.Images.Open, x - side / 2, y - side / 2, side, side, 4))
		pips[i].Name = `Pip{i}`
	end
	-- the list, in the glass alone
	local frame = Instance.new("Frame")
	frame.Name = "TodayList"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 5
	frame.Visible = false
	frame.Parent = panel.Frame
	local N = T.Next
	local nextFrame = Instance.new("Frame")
	nextFrame.Name = "Next"
	nextFrame.BackgroundTransparency = 1
	nextFrame.Size = UDim2.fromScale(1, 1)
	nextFrame.ZIndex = 7
	nextFrame.Parent = frame
	image(nextFrame, N.Image, N.Left - N.Origin.X, N.Top - N.Origin.Y, N.Size.X, N.Size.Y, 7)
	local chevron = N.Back.Chevron
	stroke(nextFrame, "Back1", chevron[1], chevron[2], N.Back.Width, N.Lines.Colours[1], 8)
	stroke(nextFrame, "Back2", chevron[2], chevron[3], N.Back.Width, N.Lines.Colours[1], 8)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Rows"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(-LEFT, R.From)
	scroll.Size = UDim2.fromOffset(HOME.Size.X + 2 * LEFT, HOME.Size.Y - R.From)
	scroll.ScrollBarThickness = 0
	scroll.ScrollBarImageTransparency = 1 -- Roblox draws its own thumb even at nought: a white line past the glass
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior = Enum.ElasticBehavior.Never
	scroll.ZIndex = 6
	scroll.Parent = frame
	local bar = Instance.new("Frame")
	bar.Name = "Thumb"
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = T.Thumb.Colour
	bar.ZIndex = 9
	bar.Visible = false
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = bar
	bar.Parent = frame
	local list: List
	local back = Button.new({
		Name = "Back",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(N.Back.Tap[3], N.Back.Tap[4]),
		Position = UDim2.fromOffset(N.Back.Tap[1], N.Back.Tap[2]),
		Parent = frame,
		OnPress = function()
			TodayList.Hide(panel)
		end,
	})
	back.ZIndex = 10
	list = {
		Panel = panel,
		Act = act,
		Frame = frame,
		Scroll = scroll,
		Thumb = bar,
		Next = nextFrame,
		Back = back,
		Rows = {},
		Week = {},
		Lines = {},
		Waits = waits,
		Pips = pips,
		Shown = false,
		Switch = 0,
		Token = 0,
		Key = "",
		View = nil :: Profile.View?,
	}
	lists[panel] = list
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		thumb(list)
	end)
	panel.Presses.Today = function()
		TodayList.Show(panel)
	end
end

-- Each frame after Home's own Paint: the list fades with the glass, a held row shows its press, and the panel gone
-- leaves the cards for its next opening.
function TodayList.Paint(panel: HomePanel.Panel?)
	local list = if panel then lists[panel] else nil
	if list == nil or not list.Shown then
		return
	end
	if not list.Panel.Frame.Visible then
		TodayList.Hide(list.Panel, true)
		return
	end
	Fade.Set(list.Frame, list.Switch * list.Panel.Shown)
	for _, row in list.Rows do
		if row.Button and row.Press then
			local state = Button.State(row.Button)
			row.Press.Visible = state == "Pressed" or state == "Waiting"
		end
	end
end

function TodayList.View(panel: HomePanel.Panel?, view: Profile.View)
	local list = if panel then lists[panel] else nil
	if list == nil or view.Goals == nil then
		return
	end
	list.View = view
	card(list, view)
	if list.Shown then
		build(list, view)
	end
end

-- The cards step out and the list in, in the glass.
function TodayList.Show(panel: HomePanel.Panel)
	local list = lists[panel]
	if list == nil or list.Shown then
		return
	end
	list.Shown = true
	if list.View then
		build(list, list.View)
	end
	list.Scroll.CanvasPosition = Vector2.zero
	for _, each in panel.Cards do
		each.Button.Visible = false
	end
	list.Frame.Visible = true
	list.Token += 1
	local token = list.Token
	list.Switch = 0
	Fade.Set(list.Frame, 0)
	Glass.Ease(list.Frame, T.Switch, function(u: number)
		if list.Token == token then
			list.Switch = u
		end
	end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.defer(thumb, list)
end

function TodayList.Hide(panel: HomePanel.Panel, now: boolean?)
	local list = lists[panel]
	if list == nil or not list.Shown then
		return
	end
	list.Shown = false
	list.Token += 1
	local token = list.Token
	list.Switch = 0
	list.Frame.Visible = false
	Fade.Set(list.Frame, 1)
	for _, each in panel.Cards do
		each.Button.Visible = true
		if not now then
			Fade.Set(each.Holder, 0)
		end
	end
	if not now then
		Glass.Ease(panel.Frame, T.Switch, function(u: number)
			if list.Token ~= token then
				return
			end
			for _, each in panel.Cards do
				Fade.Set(each.Holder, math.min(u, panel.Shown))
			end
		end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

function TodayList.Shown(panel: HomePanel.Panel?): boolean
	local list = if panel then lists[panel] else nil
	return list ~= nil and list.Shown
end

function TodayList.Said(panel: HomePanel.Panel?): { [string]: any }?
	local list = if panel then lists[panel] else nil
	if list == nil then
		return nil
	end
	local rows = {}
	for _, row in list.Rows do
		table.insert(rows, { Day = row.Day, Slot = row.Slot, Id = row.Id, Text = row.Text, State = row.State, Right = row.Right, Button = row.Button })
	end
	local pips = {}
	for _, pip in list.Pips do
		table.insert(pips, if pip.Visible then pip:GetAttribute("Kit") else "")
	end
	local week = {}
	for _, tile in list.Week do
		table.insert(week, { Index = tile.Index, State = tile.State, Button = tile.Button })
	end
	return { Shown = list.Shown, Next = table.clone(list.Lines), Rows = rows, Week = week, Waits = list.Waits.Visible, Pips = pips, Back = list.Back, Thumb = list.Thumb.Visible }
end

return TodayList
