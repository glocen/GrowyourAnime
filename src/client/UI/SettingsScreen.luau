--!strict
-- SettingsScreen (client): Settings in B (AR43, "The cut in B, for Faber"; build/handoff/UI/seam/seam.json,
-- "settings"; docs/ui.md: Settings, music, sound, effects). Home's tall tile opens it as its own screen: Back and its
-- title in the band, no rail, one card of three sliders on Equipment's block (Config.Hud.Settings, in the cut's points),
-- then the Broadcast's two switches (TR57), each On or Off, the whole row a press. The band's Codes press turns the card
-- to the codes and back (TR59, Rules.Codes): a field, its Take press ("CodeTake"), the answer's line and the note that
-- points to the game's page, the only words Roblox allows inside a game.
-- A slider is the kit's conduit filling with light, its knob the lit press's white, and the whole row drags it: the knob
-- moves with the finger from where it was. Held, the knob grows from 10 to 12.5 and its ring lights, the fill's light
-- and glow rise, and the name and the value turn to the light, over 0.08 s; each change is heard and seen at once
-- (SettingsController.Preview), and the release saves it once ("Settings"; Rules.Settings). At nought it reads Off.
--   SettingsScreen.Open(on)            on: { Act, Say }
--   SettingsScreen.Refresh(view)       the rows not held follow the save's copy
--   SettingsScreen.Set(name, value)    a slider dragged to `value` and let go, as a finger would: for the tests
--   SettingsScreen.Parts()             for the tests
--   SettingsScreen.Codes(shown?)       the codes shown or the card again, as the band's press would: for the tests
--   SettingsScreen.Take(typed)         a code typed and taken, as a finger would; the answer's line: for the tests

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local Settings = require(Shared.Rules.Settings)
local Codes = require(Shared.Rules.Codes)
local WelcomeConfig = require(Shared.Config.Welcome)

local UI = script.Parent
local Screen = require(UI.Kit.Screen)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Fade = require(UI.Kit.Fade)
local Look = require(UI.EquipmentScreen.Look)
local SettingsController = require(script.Parent.Parent.Controllers.Core.SettingsController)
local ProfileController = require(script.Parent.Parent.Controllers.Core.ProfileController)

local SettingsScreen = {}
SettingsScreen.Name = "Settings"

export type On = {
	Act: (name: string, args: any) -> { [string]: any },
	Say: (words: string) -> (),
}

local S = HudConfig.Settings
local E = HudConfig.Equipment
local MOTION = E.Motion
local SEAM = Look.Seam
local LIGHT = Look.Light
local X, Y = Look.X, Look.Y
local START, FINISH = X(S.Slider.Start), X(S.Slider.End)

type Row = {
	Name: string,
	Middle: number, -- the row's middle, in the block
	Value: number,
	Grow: number, -- 0 at rest, 1 held
	Frame: Frame,
	Track: ImageLabel,
	Fill: ImageLabel,
	FillLight: ImageLabel,
	FillGlow: ImageLabel,
	KnobGlow: ImageLabel,
	Knob: ImageLabel,
	KnobSheen: ImageLabel,
	KnobEdge: ImageLabel,
	KnobRing: ImageLabel,
	Label: TextLabel,
	Said: TextLabel,
	Touch: TextButton,
}

type Hold = { Row: Row, Input: InputObject?, From: number, StartX: number }

local rows: { Row } = {}
local switches: { { Name: string, Frame: Frame, Press: TextButton } } = {}
local parts: { [string]: Instance } = {}
local hold: Hold? = nil
local on: On? = nil
local room: Frame? = nil
local codes: { Frame: Frame?, Box: TextBox?, Line: TextLabel?, Press: TextButton?, Shown: boolean } = { Shown = false }

local function lerp(a: number, b: number, u: number): number
	return a + (b - a) * u
end

local function mix(a: Color3, b: Color3, u: number): Color3
	return a:Lerp(b, u)
end

-- The row as its value and its grip stand: the fill to the knob's middle, the knob at its radius, the lights.
local function lay(row: Row)
	local u, g = row.Value, row.Grow
	local cx, cy = lerp(START, FINISH, u), row.Middle
	local from = START + 1
	local long = cx - from
	local F = S.Fill
	local shown = long >= F.Tall
	for _, piece in { row.Fill, row.FillLight, row.FillGlow } do
		piece.Visible = shown
	end
	row.Fill.Position = UDim2.fromOffset(from, cy - F.Tall / 2)
	row.Fill.Size = UDim2.fromOffset(math.max(long, 0), F.Tall)
	row.FillLight.Position = row.Fill.Position
	row.FillLight.Size = row.Fill.Size
	row.FillLight.ImageTransparency = lerp(F.Light[1], F.Light[2], g)
	row.FillGlow.Position = UDim2.fromOffset(from - F.Pad, cy - F.Tall / 2 - F.Pad)
	row.FillGlow.Size = UDim2.fromOffset(math.max(long, 0) + 2 * F.Pad, F.Tall + 2 * F.Pad)
	row.FillGlow.ImageTransparency = lerp(F.Glow[1], F.Glow[2], g)
	local K = S.Knob
	local r = lerp(K.Rest, K.Held, g)
	local at = UDim2.fromOffset(cx, cy)
	for _, piece in { row.Knob, row.KnobSheen, row.KnobEdge } do
		piece.Position = at
		piece.Size = UDim2.fromOffset(2 * (r + 1), 2 * (r + 1))
	end
	local glow = 2 * (r + K.GlowPad) * r / K.Rest
	row.KnobGlow.Position = at
	row.KnobGlow.Size = UDim2.fromOffset(glow, glow)
	row.KnobGlow.ImageTransparency = lerp(K.Glow[1], K.Glow[2], g)
	row.KnobRing.Position = at
	row.KnobRing.Visible = g > 0
	row.KnobRing.ImageTransparency = 1 - (1 - K.RingAlpha) * g
	row.Label.TextColor3 = mix(SEAM.Text, LIGHT, g)
	row.Said.Text = Settings.Said(u)
	row.Said.TextColor3 = mix(SEAM.Soft, LIGHT, g)
	row.Said.FontFace = Font.new(row.Said.FontFace.Family, if g > 0.5 then Enum.FontWeight.Bold else Enum.FontWeight.Regular)
	row.Frame:SetAttribute("Value", u)
	row.Frame:SetAttribute("Held", g > 0)
end

-- The grip's look, eased in or out over Grow (out3).
local function grip(row: Row, held: boolean)
	local from, to = row.Grow, if held then 1 else 0
	if GuiService.ReducedMotionEnabled then
		row.Grow = to
		lay(row)
		return
	end
	Glass.Ease(row.Frame, S.Knob.Grow, function(u: number)
		row.Grow = lerp(from, to, Look.Out3(u))
		lay(row)
	end, Enum.EasingStyle.Linear)
end

-- A released slider's level, saved once; the save's copy follows, and a refusal puts the save's level back.
local function save(row: Row)
	local value = row.Value
	SettingsController.Keep(row.Name, value)
	local given = on
	if given == nil then
		return
	end
	task.spawn(function()
		local answer = given.Act("Settings", { Name = row.Name, Value = value })
		if answer.Ok ~= true then
			given.Say("Not saved: try again")
			SettingsController.Keep(row.Name, SettingsController.Level(row.Name))
		end
	end)
end

local function release(gone: boolean?)
	local h = hold
	if h == nil then
		return
	end
	hold = nil
	if not gone then
		grip(h.Row, false)
	end
	if h.Row.Value ~= h.From then
		save(h.Row)
	else
		SettingsController.Preview(h.Row.Name, nil)
	end
end

local function move(x: number)
	local h = hold
	if h == nil then
		return
	end
	local wide = h.Row.Track.AbsoluteSize.X
	local value = math.clamp(h.From + (x - h.StartX) / math.max(wide, 1), 0, 1)
	value = math.floor(value * 100 + 0.5) / 100
	if value ~= h.Row.Value then
		h.Row.Value = value
		lay(h.Row)
		SettingsController.Preview(h.Row.Name, value)
	end
end

local function image(parent: GuiObject, key: string, z: number, centred: boolean): ImageLabel
	local piece = Skin.Lay(parent, key, { Name = key, Z = z })
	if centred then
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
	end
	return piece
end

local function rowMade(parent: Frame, k: number, name: string): Row
	local middle = Y(S.Rows[k])
	local frame = Instance.new("Frame")
	frame.Name = `Row{name}`
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 3
	frame.Parent = parent
	local track = Skin.Lay(frame, "SliderTrack", { Name = "SliderTrack", X = START, Y = middle - S.Track / 2, W = FINISH - START, H = S.Track, Z = 4 }) :: ImageLabel
	local fill = image(frame, "SliderFill", 5, false)
	local lit = Instance.new("UIGradient")
	lit.Color = ColorSequence.new(SEAM.Facet, LIGHT)
	lit.Parent = fill
	local fillLight = image(frame, "SliderFillLight", 6, false)
	local fillGlow = image(frame, "SliderFillGlow", 7, false)
	fillGlow.ImageColor3 = LIGHT
	local knobGlow = image(frame, "SliderKnobGlow", 8, true)
	knobGlow.ImageColor3 = S.Glow
	local knob = image(frame, "SliderKnob", 9, true)
	local foot = Instance.new("UIGradient")
	foot.Rotation = 90
	foot.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1 / 27, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(26 / 27, S.Knob.Foot),
		ColorSequenceKeypoint.new(1, S.Knob.Foot),
	})
	foot.Parent = knob
	local sheen = image(frame, "SliderKnobSheen", 10, true)
	sheen.ImageTransparency = S.Knob.Sheen
	local edge = image(frame, "SliderKnobEdge", 11, true)
	edge.ImageColor3 = SEAM.Facet
	edge.ImageTransparency = S.Knob.Edge
	local ring = image(frame, "SliderKnobRing", 12, true)
	ring.ImageColor3 = LIGHT
	ring.Size = UDim2.fromOffset(S.Knob.Ring, S.Knob.Ring)
	local N, V = S.Name, S.Value
	local label = Look.Text(frame, "Name", name, N.Size, SEAM.Text, X(N.X), middle - N.Size / 2, "Left", true, 4, X(S.Slider.Start) - X(N.X) - 8)
	local said = Look.Text(frame, "Said", "", V.Size, SEAM.Soft, X(V.Right), middle - V.Size / 2, "Right", false, 4, 48)
	-- The whole row takes the grip, the card wide and a row's pitch tall.
	local touch = Instance.new("TextButton")
	touch.Name = "Touch"
	touch.Text = ""
	touch.AutoButtonColor = false
	touch.BackgroundTransparency = 1
	touch.Position = UDim2.fromOffset(X(S.Card[1]), middle - S.Pitch / 2)
	touch.Size = UDim2.fromOffset(S.Card[3] - S.Card[1], S.Pitch)
	touch.ZIndex = 13
	touch.Parent = frame
	local row: Row = {
		Name = name,
		Middle = middle,
		Value = SettingsController.Level(name),
		Grow = 0,
		Frame = frame,
		Track = track,
		Fill = fill,
		FillLight = fillLight,
		FillGlow = fillGlow,
		KnobGlow = knobGlow,
		Knob = knob,
		KnobSheen = sheen,
		KnobEdge = edge,
		KnobRing = ring,
		Label = label,
		Said = said,
		Touch = touch,
	}
	touch.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if hold ~= nil or not (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch) then
			return
		end
		hold = { Row = row, Input = if kind == Enum.UserInputType.Touch then input else nil, From = row.Value, StartX = input.Position.X }
		grip(row, true)
		SettingsController.Preview(name, row.Value)
	end)
	lay(row)
	return row
end

-- The rows come in as Equipment's list does: each from RowFrom points left, RowGap after the last, over RowTime.
local function rowsIn()
	local frames: { Frame } = {}
	for _, row in rows do
		table.insert(frames, row.Frame)
	end
	for _, switch in switches do
		table.insert(frames, switch.Frame)
	end
	for k, frame in frames do
		local function at(e: number)
			frame.Position = UDim2.fromOffset(-MOTION.RowFrom * (1 - e), 0)
			Fade.Set(frame, e)
		end
		if GuiService.ReducedMotionEnabled then
			at(1)
			continue
		end
		at(0)
		task.delay(MOTION.RowStart + (k - 1) * MOTION.RowGap, function()
			Glass.Ease(frame, MOTION.RowTime, function(u: number)
				at(Look.Out3(u))
			end, Enum.EasingStyle.Linear)
		end)
	end
end

-- The Broadcast's two switches, as the card says them (docs/design.md, "Being seen", "Settings").
local SAID: { [string]: string } = {
	ShareFinds = "Show my finds in other servers",
	ShowFinds = "Show others' finds",
}

local function latest(): Profile.View?
	return ProfileController.Get()
end

local function dressSwitch(press: TextButton, on: boolean)
	Look.Dress(press, if on then "Lit" else "Quiet", if on then "On" else "Off")
end

-- A switch's row: its words on the left, On or Off at the right; the whole row flips it, saved at once ("Settings").
local function switchMade(parent: Frame, k: number, name: string): Frame
	local middle = Y(S.Rows[k])
	local frame = Instance.new("Frame")
	frame.Name = `Row{name}`
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 3
	frame.Parent = parent
	local N, V, W = S.Name, S.Value, S.Switch
	Look.Text(frame, "Name", SAID[name] or name, N.Size, SEAM.Text, X(N.X), middle - N.Size / 2, "Left", true, 4, X(V.Right) - W.Wide - X(N.X) - 8)
	local function flip(): boolean
		local view = latest()
		local now = view == nil or Settings.On(view, name)
		local handle = on
		if handle == nil then
			return false
		end
		local answer = handle.Act("Settings", { Name = name, Value = not now })
		local after = latest()
		local press = frame:FindFirstChild("Switch")
		if press and press:IsA("TextButton") then
			dressSwitch(press, if answer.Ok == true then not now elseif after then Settings.On(after, name) else now)
		end
		if answer.Ok ~= true then
			handle.Say("Can't change it now")
		end
		return answer.Ok == true
	end
	local press = Look.Press(frame, "Switch", X(V.Right) - W.Wide, middle - W.Tall / 2, W.Wide, W.Tall, flip, 14)
	local view = latest()
	dressSwitch(press, view == nil or Settings.On(view, name))
	local touch = Instance.new("TextButton")
	touch.Name = "Touch"
	touch.Text = ""
	touch.AutoButtonColor = false
	touch.BackgroundTransparency = 1
	touch.Position = UDim2.fromOffset(X(S.Card[1]), middle - S.Pitch / 2)
	touch.Size = UDim2.fromOffset(S.Card[3] - S.Card[1], S.Pitch)
	touch.ZIndex = 13
	touch.Parent = frame
	touch.Activated:Connect(function()
		flip()
	end)
	table.insert(switches, { Name = name, Frame = frame, Press = press })
	return frame
end

-- The codes' words (docs/design.md, "The welcome week and codes"; the answers' are Rules.Codes.Words).
local CODE_SAID = {
	Press = "Codes",
	Field = "Type a code",
	Take = "Take",
	Note = "New codes come with each update. See the game's page.",
}

-- A typed code taken: the answer's line, lit when it's taken.
local function take(): boolean
	local handle, box, line = on, codes.Box, codes.Line
	if handle == nil or box == nil or line == nil then
		return false
	end
	local answer = handle.Act("CodeTake", { Code = box.Text })
	line.Text = Codes.Said(answer)
	line.TextColor3 = if answer.Ok == true then LIGHT else SEAM.Soft
	if answer.Ok == true then
		box.Text = ""
	end
	return answer.Ok == true
end

-- The codes, in the card's place: the field and its Take press, the answer's line, the note. Hidden until the band's
-- press shows them.
local function codesMade(parent: Frame): Frame
	local C, N, V = S.Codes, S.Name, S.Value
	local frame = Instance.new("Frame")
	frame.Name = "Codes"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 3
	frame.Visible = false
	frame.Parent = parent
	local middle = Y(S.Rows[1])
	local box = Instance.new("TextBox")
	box.Name = "Field"
	box.Text = ""
	box.PlaceholderText = CODE_SAID.Field
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	box.TextSize = C.Field.Size
	box.TextColor3 = SEAM.Text
	box.PlaceholderColor3 = SEAM.Soft
	box.BackgroundColor3 = SEAM.Facet
	box.BorderSizePixel = 0
	box.Position = UDim2.fromOffset(X(N.X), middle - C.Field.Tall / 2)
	box.Size = UDim2.fromOffset(C.Field.Right - N.X, C.Field.Tall)
	box.ZIndex = 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = box
	local inset = Instance.new("UIPadding")
	inset.PaddingLeft = UDim.new(0, 10)
	inset.Parent = box
	box.Parent = frame
	box:GetPropertyChangedSignal("Text"):Connect(function() -- never past the most, as it's typed
		if #box.Text > WelcomeConfig.Codes.Most then
			box.Text = string.sub(box.Text, 1, WelcomeConfig.Codes.Most)
		end
	end)
	box.FocusLost:Connect(function(entered: boolean)
		if entered then
			take()
		end
	end)
	local W = S.Switch
	local press = Look.Press(frame, "Take", X(V.Right) - W.Wide, middle - W.Tall / 2, W.Wide, W.Tall, take, 14)
	Look.Dress(press, "Lit", CODE_SAID.Take)
	local line = Look.Text(frame, "Line", "", C.Line.Size, SEAM.Soft, X(N.X), Y(C.Line.Y) - C.Line.Size / 2, "Left", true, 4, V.Right - N.X)
	local note = Look.Text(frame, "Note", CODE_SAID.Note, C.Note.Size, SEAM.Soft, X(N.X), Y(C.Note.Y) - C.Note.Size / 2, "Left", false, 4, V.Right - N.X)
	note.TextWrapped = true
	codes.Frame, codes.Box, codes.Line, codes.Press = frame, box, line, press
	return frame
end

-- The codes in the card's place, or the card again.
local function showCodes(shown: boolean)
	local block = room
	if block == nil then
		return
	end
	codes.Shown = shown
	for _, child in block:GetChildren() do
		if child.Name == "Divider" or string.sub(child.Name, 1, 3) == "Row" then
			(child :: GuiObject).Visible = not shown
		end
	end
	if codes.Frame then
		codes.Frame.Visible = shown
	end
	local press = parts.CodesPress
	if press and press:IsA("TextButton") then
		Look.Dress(press, if shown then "Lit" else "Quiet", CODE_SAID.Press)
	end
end

local function divider(parent: Instance, y: number)
	local D = S.Divider
	local line = Instance.new("Frame")
	line.Name = "Divider"
	line.BorderSizePixel = 0
	line.BackgroundColor3 = SEAM.Edge
	line.BackgroundTransparency = D.Alpha
	line.Position = UDim2.fromOffset(X(D.Left), Y(y))
	line.Size = UDim2.fromOffset(D.Right - D.Left, 1)
	line.ZIndex = 3
	line.Parent = parent
end

function SettingsScreen.Open(given: On)
	on = given
	hold = nil
	table.clear(rows)
	table.clear(switches)
	table.clear(parts)
	codes = { Shown = false }
	local body = Screen.Full(SettingsScreen.Name, "Settings", "SeamGlass")
	parts.Body = body
	Glass.Ground(body, 1)
	local made = Look.Room(body)
	made.ZIndex = 2
	room = made
	parts.Block = made
	local bloom = E.Bloom
	Glass.Bloom(made, "Bloom", X(bloom.At.X), Y(bloom.At.Y), bloom.Size.X, bloom.Size.Y, bloom.Tint, 1 - bloom.Alpha, 1)
	local band = Screen.Band(SettingsScreen.Name)
	if band then
		local title = Glass.Label(band, "Title", "Settings", Look.Big, SEAM.Text, Screen.BandLeft + 4, 0, 200, 0, Enum.TextXAlignment.Left, true, 3)
		title.Size = UDim2.new(0, 200, 1, 0)
		parts.Title = title
	end
	local card = Look.Panel(made, "Card", S.Card, 2)
	parts.Card = card
	for k = 1, #S.Rows - 1 do
		divider(made, (S.Rows[k] + S.Rows[k + 1]) / 2)
	end
	for k, name in Settings.Levels do
		local row = rowMade(made, k, name)
		rows[k] = row
		parts[`Row{name}`] = row.Frame
	end
	for j, name in Settings.Switches do
		parts[`Row{name}`] = switchMade(made, #Settings.Levels + j, name)
	end
	parts.Codes = codesMade(made)
	if band then
		local P = S.Codes.Press
		local press = Look.Press(band, "CodesPress", 0, 0, P.Wide, P.Tall, function(): boolean
			showCodes(not codes.Shown)
			return true
		end, 4)
		press.AnchorPoint = Vector2.new(1, 0.5)
		press.Position = UDim2.new(1, -P.Right, 0.5, 0)
		Look.Dress(press, "Quiet", CODE_SAID.Press)
		parts.CodesPress = press
	end
	rowsIn()
	local moved = UserInputService.InputChanged:Connect(function(input: InputObject)
		local h = hold
		if h == nil then
			return
		end
		if (h.Input == nil and input.UserInputType == Enum.UserInputType.MouseMovement) or (h.Input ~= nil and input == h.Input) then
			move(input.Position.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input: InputObject)
		local h = hold
		if h == nil then
			return
		end
		if (h.Input == nil and input.UserInputType == Enum.UserInputType.MouseButton1) or (h.Input ~= nil and input == h.Input) then
			release()
		end
	end)
	made.Destroying:Connect(function()
		moved:Disconnect()
		ended:Disconnect()
		release(true) -- closed while held: the level is kept, nothing left to ease
		if room == made then
			room = nil
		end
	end)
end

function SettingsScreen.Refresh(view: Profile.View)
	if room == nil or Screen.Current() ~= SettingsScreen.Name then
		return
	end
	for _, switch in switches do
		dressSwitch(switch.Press, Settings.On(view, switch.Name))
	end
	local held = if hold then hold.Row else nil
	for _, row in rows do
		if row ~= held then
			local level = SettingsController.Level(row.Name)
			if level ~= row.Value then
				row.Value = level
				lay(row)
			end
		end
	end
end

function SettingsScreen.Set(name: string, value: number): boolean
	for _, row in rows do
		if row.Name == name and hold == nil then
			hold = { Row = row, Input = nil, From = row.Value, StartX = 0 }
			grip(row, true)
			move((value - row.Value) * math.max(row.Track.AbsoluteSize.X, 1))
			release()
			return true
		end
	end
	return false
end

function SettingsScreen.Parts(): { [string]: Instance }
	return parts
end

function SettingsScreen.Codes(shown: boolean?)
	showCodes(if shown == nil then not codes.Shown else shown)
end

function SettingsScreen.Take(typed: string): string
	if codes.Box == nil or codes.Line == nil then
		return ""
	end
	(codes.Box :: TextBox).Text = typed
	take()
	return (codes.Line :: TextLabel).Text
end

return SettingsScreen
