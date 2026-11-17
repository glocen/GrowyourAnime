--!strict
-- Button (client kit): a press, in the seven states every component has (docs/ui.md): rest, pressed, selected, disabled
-- with its reason, waiting on the server, succeeded, failed. Every button is of the seam's make (AR30; Config.Hud.Make):
-- a main action, or anything set, on or chosen, is dark glass lit from its foot at L in its light colour (the ring's glow,
-- the Panel gradient, a wash of the light, the edge, the foot's glow and the foot); a second action is the plain channel
-- with a short underline, washed with the light while a finger holds it. A chip on a tabs' row has no plate of its own
-- (the row is the channel) and is the glass when chosen; a picker (Sort) is the channel with its name, its value and a
-- chevron, its value in the light while it isn't the default. A press sinks, and the light rises with it and
-- falls back on the let-go. Unavailable, it's the channel and its words go soft. A press that waits (an Act) shows the
-- light running round its edge and three dots until it answers, and refuses a second press meanwhile, so nothing is asked
-- twice. It flashes succeeded or failed only on the
-- server's answer (rule 4: the interface never lies). Disabled, its face says why in place of its name; one made with
-- Under keeps its name and says why in a smaller line under it (TR17, research's fix 3). A touch squeezes its face and label about their middle within
-- 0.05 s, and a let-go brings them back over full size for a moment (Config.Hud.Motion.Press, Rules.Hud.Squeeze; AR8 C);
-- a press with no touch (a pad, a key) squeezes as a tap. A touch also ticks under the thumb (Roblox's UIClick haptic;
-- TR6). No state moves the layout.
--   Button.new{ Name, Text, Size, OnPress, ... }      a button; OnPress may return true (succeeded) or false (failed)
--   Button.Set(button, { Text = ..., Disabled = "why" | false, Selected = true | false, Note = "Bay 3" | false })
--   Button.Grow(button, scale)   its face and label at `scale` at rest, a card's hover (TR20)
--   Button.Fit(button)           a chip's or a picker's width from its words, set on it (AR30's make)
--   Button.Press(button)                             what a tap does, for tests: false when disabled or pending; an icon's
--                                                    button (Text "") says its reason in a toast, never in its face
--   Button.Touch(button, down)                       a finger going down on it or coming off, for tests
--   Button.State(button)                             the state it shows
--   Button.Haptic(button)                            a touch's tick under the thumb; true when it ticked, for tests

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Hud = require(Shared.Rules.Hud)
local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)
local Skin = require(script.Parent.Skin)
local Toast = require(script.Parent.Toast)

export type Props = {
	Name: string,
	Text: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Primary: boolean?, -- the screen's one main action: the glass; set (Selected), its mark and its word in the light
	Light: Color3?, -- the kind's light: a claim's or a ready shard's (Config.Hud.Make.Light), the seam's Light by default
	Icon: UIKit.Image?, -- an icon's button (the X, Config.Hud.Make.Images.SeamClose): no plate, this image IconSide across
	IconSide: number?,
	Plate: boolean?, -- an icon on the channel (Power's ±): its plate kept, no halo
	Palette: string?,
	LayoutOrder: number?,
	TextSize: number?,
	Under: boolean?, -- disabled, it keeps its name and says why under it
	Quiet: boolean?, -- a secondary press: no accent's base line at rest, so it never reads as the thing to press
	Inset: number?, -- its label's middle this many pixels right of the button's, room for a mark its owner lays at its left
	Bare: boolean?, -- no plate of the kit: its owner lays its own face in its skin (the spectate eye's plate), which squeezes as a face does
	Still: boolean?, -- no squeeze: its owner draws its own press from its State (the dock's tiles sink, UI.Dock)
	Chip: boolean?, -- a chip on a tabs' row: no plate of its own, the row its owner lays is the channel (Config.Hud.Make.Chip)
	Pick: string?, -- a picker's name ("Sort:"): Text is its value; Selected while it holds anything but the default (Make.Pick)
	OnPress: () -> ...any,
}

type State = {
	Label: TextLabel,
	Reason: TextLabel?, -- why it's off, under its name (Under)
	Tick: ImageLabel,
	Layers: { [string]: ImageLabel },
	Dots: { ImageLabel },
	Text: string,
	Disabled: string?, -- the reason, while disabled
	Note: string?, -- a line under its name while it can be pressed (Station's bay)
	Pending: boolean,
	Selected: boolean,
	Primary: boolean,
	Quiet: boolean,
	Inset: number,
	Bare: boolean,
	Still: boolean,
	Light: Color3,
	Skin: Frame,
	Mark: ImageLabel,
	Icon: ImageLabel?, -- an icon's button's image, and its halo
	Halo: ImageLabel?,
	Plate: boolean,
	Chip: boolean,
	Pick: TextLabel?, -- a picker's name, and its chevron
	Chevron: ImageLabel?,
	Wide: number, -- its authored width, for the underline
	Tall: number, -- and its height, for a chip's inset glass
	Fades: { [ImageLabel]: Tween },
	Glass: boolean, -- the kind it was painted in, so the light tweens only within the glass
	L: number,
	Held: boolean,
	DownAt: number?, -- the touch's moment, while its squeeze runs
	UpAt: number?, -- the let-go's
	Scales: { UIScale }, -- the face's and the label's
	Grow: number, -- its owner's scale at rest (Button.Grow: a card under the pointer, TR20); a press's squeeze beats it
	Flash: string?, -- "Succeeded" or "Failed", for a moment after the server's answer
	FlashUntil: number,
	OnPress: () -> ...any,
}

local Button = {}

Button.FlashSeconds = 0.6

local MAKE = HudConfig.Make
local SEAM = UIKit.Palettes.Seam
local SEAM_LIGHT = SEAM.Light :: Color3
local Whole = math.round

local function fall(points: { { number } }): NumberSequence
	local keys = {}
	for _, point in points do
		table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keys)
end
local GLASS_FALL = fall(MAKE.Glass.WashFall)
local PRESSED_FALL = fall(MAKE.Channel.PressedFall)
-- A main action set (Leading, Claimed) wears the rail's chosen tab's light (AR29's B; research's ruling on the director's
-- remark, 2026-11-17, 20:31): its glow, its fill, its edge, and its wash rising to the foot as the tab's does to the line.
local TAB = HudConfig.Voidkin.Chrome.Rail.Tab
local TAB_FALL = (function(): NumberSequence
	local keys = {}
	for i = 0, 10 do
		local t = i / 10
		table.insert(keys, NumberSequenceKeypoint.new(t, 1 - (TAB.Wash.Base + TAB.Wash.Rise * t ^ TAB.Wash.Power)))
	end
	return NumberSequence.new(keys)
end)()

-- The product of the UIScales over a piece: its authored size is its drawn size over it.
local function scaleOver(piece: Instance): number
	local scale = 1
	local at: Instance? = piece
	while at do
		local s = at:FindFirstChildOfClass("UIScale")
		if s then
			scale *= s.Scale
		end
		at = at.Parent
	end
	return scale
end

-- Held until the button is destroyed: a weak table keyed by an instance can lose a live one (Text's note).
local states: { [TextButton]: State } = {}
local waiting: { [TextButton]: boolean } = {}
local squeezing: { [TextButton]: boolean } = {}

function Button.State(button: TextButton): string
	local state = states[button]
	if state == nil then
		return ""
	end
	if state.Pending then
		return "Waiting"
	elseif state.Disabled then
		return "Disabled"
	elseif state.Flash then
		return state.Flash
	elseif state.Held then
		return "Pressed"
	elseif state.Selected then
		return "Selected"
	end
	return "Rest"
end

-- A layer's transparency, tweened over `seconds` (the light rising on a press, falling on the let-go), or set at once.
local function fade(state: State, image: ImageLabel, to: number, seconds: number)
	local running = state.Fades[image]
	if running then
		running:Cancel()
		state.Fades[image] = nil
	end
	if seconds <= 0 or math.abs(image.ImageTransparency - to) < 1e-3 then
		image.ImageTransparency = to
		return
	end
	local tween = TweenService:Create(image, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = to })
	state.Fades[image] = tween
	tween:Play()
end

local function paint(button: TextButton, state: State)
	local now = Button.State(button)
	local layers = state.Layers
	local G, C = MAKE.Glass, MAKE.Channel
	local disabled = now == "Disabled"
	local pressed = now == "Pressed"
	local flash = if now == "Succeeded" then UIKit.Good elseif now == "Failed" then UIKit.Bad else nil
	local main = state.Primary
	local word = state.Text ~= ""
	local set = state.Selected and not disabled
	local light = state.Light
	local chip, pick = state.Chip, state.Pick
	-- The kind: glass for a main action, or anything set, on or chosen; the channel otherwise. A picker on stays the
	-- channel, its value in the light; a chip off the glass has no plate, its row is its channel.
	local glass = not disabled and (set or main) and pick == nil
	local L = if not glass then 0
		elseif set then (if main then MAKE.L.Set elseif chip or not word then MAKE.L.Chosen else MAKE.L.On)
		elseif pressed then MAKE.L.Pressed
		else MAKE.L.Main
	local seconds = if glass and state.Glass then (if L > state.L then MAKE.Down else MAKE.Up) else 0
	state.Glass, state.L = glass, L
	local tabbed = set and main
	local bare = chip and not glass
	if chip then
		local inset = 2 * MAKE.Chip.Inset
		state.Skin.Size = UDim2.fromScale(1 - inset / math.max(state.Wide, 1), 1 - inset / math.max(state.Tall, 1))
	end

	layers.Shadow.Visible = not pressed and not chip
	layers.RingGlow.Visible = glass or flash ~= nil
	layers.RingGlow.ImageColor3 = flash or light
	fade(state, layers.RingGlow, if tabbed then 1 - TAB.Glow else 1 - G.RingGlow * (if glass then L else MAKE.L.Main), seconds)
	if glass then
		Skin.Tint(layers.Fill, SEAM.Panel)
		layers.Fill.ImageTransparency = if tabbed then 1 - TAB.Fill else G.Fill
	else
		Skin.Tint(layers.Fill, SEAM.Channel)
		layers.Fill.ImageTransparency = if disabled then (if main then C.Main else C.Off) else C.Rest
	end
	layers.Fill.Visible = not bare
	layers.Edge.Visible = not bare
	local wash = layers.Wash
	local washFall = wash:FindFirstChildOfClass("UIGradient") :: UIGradient
	wash.Visible = glass or (pressed and not chip and pick == nil)
	wash.ImageColor3 = if glass then light else SEAM_LIGHT
	washFall.Transparency = if tabbed then TAB_FALL elseif glass then GLASS_FALL else PRESSED_FALL
	fade(state, wash, if tabbed then 0 elseif glass then 1 - L / G.Wash else 0, seconds)
	layers.Edge.ImageColor3 = if glass then light elseif pressed and pick == nil then C.PressedEdge else SEAM.Edge
	fade(state, layers.Edge, if tabbed then 1 - TAB.Edge elseif glass then 1 - G.Edge * L else 0, seconds)
	layers.FootGlow.Visible = glass
	layers.FootGlow.ImageColor3 = light
	fade(state, layers.FootGlow, if tabbed then 1 - TAB.Meet.GlowAlpha else 1 - G.FootGlow * L, seconds)
	layers.Foot.Visible = glass
	layers.Foot.ImageColor3 = light
	-- Waiting: a window of light running round the ring; the server's answer: the ring in its colour.
	layers.Ring.Visible = flash ~= nil or now == "Waiting"
	layers.Ring.ImageColor3 = flash or light
	local run = layers.Ring:FindFirstChildOfClass("UIGradient")
	if run then
		run.Enabled = now == "Waiting"
	end
	-- A second action's underline: short at rest, whole under a finger. A chip's only under a finger; a picker's while it's
	-- on or pressed.
	local U = MAKE.Underline
	local at = if pressed then 2 else 1
	local underlined: boolean, half: number, lineT: number, glowT: number
	if chip then
		local K = MAKE.Chip
		underlined, half, lineT, glowT = pressed and not glass and not disabled, K.Under * state.Wide, K.Line, K.Glow
	elseif pick then
		local K = MAKE.Pick
		underlined, half, lineT, glowT = (pressed or set) and not disabled, K.Under * state.Wide, K.Line[at], K.Glow[at]
	else
		underlined = word and not glass and not disabled
		half = (if pressed then 1 else U.Rest) * math.min(U.Share * state.Wide, U.Most)
		lineT, glowT = U.Line[at], U.Glow[at]
	end
	local span = Whole(2 * half * U.Span)
	for index, layer in { layers.Under, layers.UnderGlow } do
		layer.Visible = underlined
		layer.ImageColor3 = SEAM_LIGHT
		layer.Size = UDim2.fromOffset(span, U.Tall)
		layer.ImageTransparency = if index == 1 then lineT else glowT
	end
	layers.Well.Visible = now == "Waiting"
	for _, dot in state.Dots do
		dot.Visible = now == "Waiting"
		dot.ImageColor3 = light
	end
	waiting[button] = if now == "Waiting" then true else nil
	state.Tick.Visible = now == "Succeeded"
	-- An icon's button (no text) keeps its face: a reason never fits in it, so a tap says it instead (Button.Press).
	local reason = state.Reason
	local note = if disabled then state.Disabled else state.Note
	local under = reason ~= nil and word and note ~= nil and note ~= ""
	local label = state.Label
	label.Text = if not word then "" elseif under or chip or pick then state.Text else Hud.Says(state.Text, state.Disabled, false)
	label.Visible = now ~= "Waiting"
	local marked = set and main and word
	local sink = if pressed and not state.Bare and not state.Icon and not chip and pick == nil then Whole(MAKE.Sink) else 0
	local over = if under then -MAKE.Word.Rise
		elseif main and not set then 0
		elseif glass then -Whole(MAKE.Word.OnOver)
		else -Whole(MAKE.Word.Over)
	-- A picker: its name from In, its value Gap after it (the label, centred there), the chevron at its right.
	local faint = SEAM.Faint :: Color3
	if pick then
		local K = MAKE.Pick
		local valueWide = Text.Wide(label, label.Text)
		state.Inset = Whole(K.In + Text.Wide(pick, pick.Text) + K.Gap + valueWide / 2 - state.Wide / 2)
		pick.Position = UDim2.new(0, K.In, 0.5, over)
		pick.TextColor3 = if disabled then faint else SEAM.Soft
		local chevron = state.Chevron :: ImageLabel
		chevron.ImageColor3 = if disabled then faint elseif set then light else SEAM.Text
	end
	label.Position = UDim2.new(0.5, if now == "Succeeded" then 12 elseif marked then state.Inset + MAKE.Mark.Shift else state.Inset, 0.5, over + sink)
	state.Skin.Position = UDim2.new(0.5, 0, 0.5, sink)
	state.Mark.Visible = marked
	if marked then
		state.Mark.ImageColor3 = light
		state.Mark.Position = UDim2.new(0.5, -Whole(Text.Wide(label, label.Text) / 2 + MAKE.Mark.Left), 0.5, 0)
	end
	if reason then
		reason.Visible = under
		reason.Text = if under then note or "" else ""
		reason.TextColor3 = SEAM.Soft
		reason.Position = UDim2.new(0.5, 0, 0.5, MAKE.Word.Fall)
	end
	label.TextColor3 = if chip then (if disabled then faint elseif glass or pressed then SEAM.Text else SEAM.Soft)
		elseif pick then (if disabled then faint elseif set then light else SEAM.Text)
		elseif disabled then SEAM.Soft
		elseif marked then light
		else SEAM.Text
	if state.Bare or (state.Icon and not state.Plate) then
		for _, layer in layers do
			layer.Visible = false
		end
	end
	-- An icon's button: the icon in Text; pressed, in the light over its halo with a short line under it.
	local icon, halo = state.Icon, state.Halo
	if icon and state.Plate then
		icon.ImageColor3 = if disabled then SEAM.Faint :: Color3 else SEAM.Text :: Color3
	elseif icon and halo then
		local I = MAKE.Icon
		icon.ImageColor3 = if disabled then SEAM.Faint :: Color3 elseif pressed then light else SEAM.Text :: Color3
		halo.Visible = pressed
		halo.ImageColor3 = light
		for index, layer in { layers.Under, layers.UnderGlow } do
			layer.Visible = pressed
			layer.Size = UDim2.fromOffset(Whole(2 * I.Half * U.Span), U.Tall)
			layer.Position = UDim2.new(0.5, 0, 0.5, I.Below)
			layer.ImageTransparency = if index == 1 then I.Line else I.Glow
		end
	end
	button:SetAttribute("Disabled", state.Disabled or "")
	button:SetAttribute("Pending", state.Pending)
	button:SetAttribute("State", now)
	button:SetAttribute("Kind", if tabbed then "Plate" elseif glass then "Glass" elseif bare then "Chip" else "Channel")
	button:SetAttribute("L", L)
end

-- A press's tick under the thumb (TR6; the study's DESIGN 2, ClickHaptic): Roblox's UIClick haptic, on a touch going down
-- on a button that takes it (Config.Hud.Motion.Haptic). One effect, made on first use; a device with no haptics ignores it.
local haptic: HapticEffect? = nil
local function click(): boolean
	if not HudConfig.Motion.Haptic then
		return false
	end
	if haptic == nil then
		local made = Instance.new("HapticEffect")
		made.Name = "NL_Click"
		made.Type = Enum.HapticEffectType.UIClick
		made.Parent = workspace
		haptic = made
	end
	return (pcall(function()
		(haptic :: HapticEffect):Play()
	end))
end

-- A touch going down on the button: its tick, when the button takes the press (not disabled, not waiting on the server).
function Button.Haptic(button: TextButton): boolean
	local state = states[button]
	if state == nil or state.Disabled ~= nil or state.Pending then
		return false
	end
	return click()
end

-- What a finger or the mouse does going down on the button (`down`) and coming off it: the held look. The tap itself is
-- Activated's, so a test's touch then calls Press.
function Button.Touch(button: TextButton, down: boolean)
	local state = states[button]
	if state == nil then
		return
	end
	state.Held = down
	local at = os.clock()
	if down then
		state.DownAt, state.UpAt = at, nil
	elseif state.DownAt then
		state.UpAt = at
	end
	squeezing[button] = if state.DownAt then true else nil
	paint(button, state)
end

-- Its face and label at `scale` while no press squeezes them: a card's hover (TR20). 1 puts them back.
function Button.Grow(button: TextButton, scale: number)
	local state = states[button]
	if state == nil or state.Grow == scale then
		return
	end
	state.Grow = scale
	if not squeezing[button] then
		for _, s in state.Scales do
			s.Scale = scale
		end
	end
end

-- How squeezed its face is, a share of its size (1 at rest), for tests.
function Button.Squeeze(button: TextButton): number
	local state = states[button]
	return if state and state.Scales[1] then state.Scales[1].Scale else 1
end

function Button.Press(button: TextButton): boolean
	local state = states[button]
	if state and state.Disabled and not state.Pending and state.Text == "" then
		Toast.Show(state.Disabled) -- an icon's button says why on a tap (docs/ui.md, rule 4)
	end
	if state == nil or state.Disabled or state.Pending then
		return false
	end
	if state.DownAt == nil then -- a press with no touch: a tap's squeeze
		local at = os.clock()
		state.DownAt, state.UpAt = at, at
		squeezing[button] = true
	end
	state.Pending = true
	state.Flash = nil
	paint(button, state)
	task.spawn(function()
		local ok, answer = pcall(state.OnPress)
		if not ok then
			warn(`Button {button.Name}: {answer}`)
		end
		state.Pending = false
		-- Only the server's answer flashes: a press that answers nothing goes back to rest.
		if ok and type(answer) == "boolean" then
			state.Flash = if answer then "Succeeded" else "Failed"
			state.FlashUntil = os.clock() + Button.FlashSeconds
			task.delay(Button.FlashSeconds, function()
				if os.clock() >= state.FlashUntil - 1e-3 and state.Flash then
					state.Flash = nil
					if button.Parent then
						paint(button, state)
					end
				end
			end)
		end
		if button.Parent then
			paint(button, state)
		end
	end)
	return true
end

function Button.new(props: Props): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.Name
	button.Text = ""
	button.Size = props.Size
	button.Position = props.Position or UDim2.new()
	button.AnchorPoint = props.AnchorPoint or Vector2.zero
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.LayoutOrder = props.LayoutOrder or 0
	button:SetAttribute("Palette", props.Palette or "Graphite")
	local light = props.Light or SEAM_LIGHT
	local skin = Skin.Of(button)
	local images = MAKE.Images
	local layers: { [string]: ImageLabel } = {
		Shadow = Skin.Lay(skin, "ButtonShadow", { Name = "Shadow", Z = 1 }),
		RingGlow = Skin.Lay(skin, "ButtonRingGlow", { Name = "RingGlow", Z = 2 }),
		Fill = Skin.Lay(skin, "ButtonFill", { Name = "Fill", Z = 3 }),
		Wash = Skin.Lay(skin, "ButtonFill", { Name = "Wash", Z = 4 }),
		Edge = Skin.Lay(skin, "ButtonEdge", { Name = "Edge", Z = 5 }),
		FootGlow = Skin.LayOwn(skin, images.SeamFootGlow, "FootGlow", { Z = 6 }),
		Foot = Skin.LayOwn(skin, images.SeamFoot, "Foot", { Z = 7 }),
		Ring = Skin.Lay(skin, "ButtonRing", { Name = "Ring", Z = 8 }),
		UnderGlow = Skin.LayOwn(skin, images.SeamUnderlineGlow, "UnderGlow", { Z = 9 }),
		Under = Skin.LayOwn(skin, images.SeamUnderline, "Under", { Z = 10 }),
	}
	-- The wash falls from the foot up; the foot's glow reaches past each side and below; the underline sits over the foot.
	local washFall = Instance.new("UIGradient")
	washFall.Rotation = 90
	washFall.Parent = layers.Wash
	local reach = MAKE.Glass.Reach
	layers.FootGlow.Position = UDim2.new(0, -reach, 1, -reach)
	layers.FootGlow.Size = UDim2.new(1, 2 * reach, 0, 2 * reach)
	layers.Foot.Position = UDim2.new(0, 0, 1, -MAKE.Glass.Foot)
	layers.Foot.Size = UDim2.new(1, 0, 0, MAKE.Glass.Foot)
	for _, layer in { layers.Under, layers.UnderGlow } do
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Position = UDim2.new(0.5, 0, 1, -MAKE.Underline.Over)
	end
	-- Waiting: a window of light running round the ring.
	local run = Instance.new("UIGradient")
	run.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.62, 0),
		NumberSequenceKeypoint.new(0.86, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	run.Enabled = false
	run.Parent = layers.Ring
	-- The dots and the tick sit by the button's middle and left edge, so a button sized by scale keeps them in place.
	local function centred(image: ImageLabel, ax: number)
		local at = image.Position
		image.Position = UDim2.new(ax, at.X.Offset, 0.5, at.Y.Offset)
	end
	local well = Skin.Lay(skin, "DotsWell", { Name = "Well", X = -26, Y = -7, Z = 11 })
	centred(well, 0.5)
	layers.Well = well
	local dots = {}
	for i = 0, 2 do
		local dot = Skin.Icon(skin, "Dot", -13 + 13 * i, 0, 12 * (1 - 0.17 * i), light, 12)
		centred(dot, 0.5)
		dot.ImageTransparency = 0.3 * i
		table.insert(dots, dot)
	end
	local label = Text.new({
		Name = "Label",
		Size = props.TextSize or Theme.Text.Body,
		Font = Theme.Font.Strong,
		Align = Enum.TextXAlignment.Center,
		Parent = button,
	})
	-- The face and the label squeeze about the button's middle.
	skin.AnchorPoint = Vector2.new(0.5, 0.5)
	skin.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	-- A picker: its name at its left and its chevron at its right, over the face, squeezing with it (painted in place).
	local pickName: TextLabel?, chevron: ImageLabel? = nil, nil
	local squeezed: { GuiObject } = if props.Still then {} else { skin, label }
	if props.Pick then
		local holder = Instance.new("Frame")
		holder.Name = "Pick"
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Active = false
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(1, 1)
		holder.Parent = button
		local name = Text.new({ Name = "PickName", Size = props.TextSize or Theme.Text.Body, Font = Theme.Font.Body, Colour = SEAM.Soft, AnchorPoint = Vector2.new(0, 0.5), Parent = holder })
		name.Text = props.Pick
		local side = Whole(MAKE.Pick.Chevron)
		local made = Skin.LayOwn(holder, MAKE.Images.SeamChevron, "Chevron", { Z = 1 })
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Position = UDim2.new(1, -MAKE.Pick.In, 0.5, MAKE.Pick.Drop)
		made.Size = UDim2.fromOffset(side, side)
		pickName, chevron = name, made
		if not props.Still then
			table.insert(squeezed, holder)
		end
	end
	local scales = {}
	for _, piece in squeezed do
		local scale = Instance.new("UIScale")
		scale.Name = "Squeeze"
		scale.Parent = piece
		table.insert(scales, scale)
	end
	-- An icon's button: its icon, and its halo under it, on its middle (they squeeze as its face).
	local icon: ImageLabel?, halo: ImageLabel? = nil, nil
	if props.Icon then
		local I = MAKE.Icon
		local iconSide = Whole(props.IconSide or props.Icon.Points.X)
		local haloSide = Whole(I.Halo)
		halo = if props.Plate then nil else Skin.LayOwn(skin, images.SeamHalo, "Halo", { Z = 8, Alpha = 1 - I.HaloT })
		icon = Skin.LayOwn(skin, props.Icon, "Icon", { Z = 11 })
		for _, each in { halo, icon } :: { ImageLabel } do
			local side = if each == icon then iconSide else haloSide
			each.AnchorPoint = Vector2.new(0.5, 0.5)
			each.Position = UDim2.fromScale(0.5, 0.5)
			each.Size = UDim2.fromOffset(side, side)
		end
	end
	-- A main action set: its mark at the word's left, in the light (Leading, Claimed).
	local side = Whole(MAKE.Mark.Side)
	local mark = Skin.LayOwn(label, images.SeamMark, "Mark", { Z = 2 })
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(side, side)
	mark.Visible = false
	local reason: TextLabel? = nil
	if props.Under then
		reason = Text.new({
			Name = "Reason",
			Size = Theme.Text.Caption,
			Colour = SEAM.Soft,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.new(1, -4, 0, 18),
			Position = UDim2.new(0.5, 0, 0.5, MAKE.Word.Fall),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = button,
		})
	end
	local tick = Skin.Icon(button, "Tick", 29, 0, 20, UIKit.Good, 2)
	centred(tick, 0)
	tick.Name = "Tick"
	local state: State = {
		Label = label,
		Reason = reason,
		Tick = tick,
		Layers = layers,
		Dots = dots,
		Text = props.Text,
		Disabled = nil,
		Note = nil,
		Pending = false,
		Selected = false,
		Primary = props.Primary == true,
		Quiet = props.Quiet == true,
		Inset = props.Inset or 0,
		Bare = props.Bare == true,
		Still = props.Still == true,
		Light = light,
		Skin = skin,
		Mark = mark,
		Icon = icon,
		Halo = halo,
		Plate = props.Plate == true,
		Chip = props.Chip == true,
		Pick = pickName,
		Chevron = chevron,
		Wide = 0,
		Tall = 0,
		Fades = {},
		Glass = false,
		L = 0,
		Held = false,
		Scales = scales,
		Grow = 1,
		Flash = nil,
		FlashUntil = 0,
		OnPress = props.OnPress,
	}
	states[button] = state
	button.Destroying:Connect(function()
		states[button] = nil
		waiting[button] = nil
		squeezing[button] = nil
	end)
	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Button.Touch(button, true)
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			Button.Haptic(button)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Button.Touch(button, false)
		end
	end)
	button.Activated:Connect(function()
		Button.Press(button)
	end)
	-- Its authored width, for the underline, whenever it's laid out again.
	local function refit()
		if not button:IsDescendantOf(game) then
			return -- taken out or destroyed: its layers may be going already
		end
		local scale = math.max(scaleOver(button), 1e-3)
		local wide, tall = button.AbsoluteSize.X / scale, button.AbsoluteSize.Y / scale
		if math.abs(wide - state.Wide) > 0.5 or math.abs(tall - state.Tall) > 0.5 then
			state.Wide, state.Tall = wide, tall
			paint(button, state)
		end
	end
	button:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	button.AncestryChanged:Connect(refit)
	state.Wide = if props.Size.X.Scale == 0 then props.Size.X.Offset else 0
	state.Tall = if props.Size.Y.Scale == 0 then props.Size.Y.Offset else 0
	paint(button, state)
	button.Parent = props.Parent
	return button
end

-- A new label, or disabled with its reason (a string), or enabled again (false); selected while its screen is open.
function Button.Set(button: TextButton, change: { Text: string?, Disabled: (string | boolean)?, Selected: boolean?, Note: (string | boolean)? })
	local state = states[button]
	if state == nil then
		return
	end
	if change.Text ~= nil then
		state.Text = change.Text
	end
	if change.Disabled ~= nil then
		state.Disabled = if type(change.Disabled) == "string" then change.Disabled else nil
	end
	if change.Selected ~= nil then
		state.Selected = change.Selected
	end
	if change.Note ~= nil then
		state.Note = if type(change.Note) == "string" then change.Note else nil
	end
	paint(button, state)
end

-- A chip's or a picker's width from its words (Config.Hud.Make.Chip, .Pick), set on it and returned, in authored points;
-- any other button keeps its own.
function Button.Fit(button: TextButton): number
	local state = states[button]
	local wide = button.Size.X.Offset
	if state and state.Chip then
		wide = math.max(MAKE.Chip.Least, math.ceil(Text.Wide(state.Label, state.Text)) + MAKE.Chip.Pad)
	elseif state and state.Pick then
		local name = state.Pick :: TextLabel
		wide = math.ceil(Text.Wide(name, name.Text) + MAKE.Pick.Gap + Text.Wide(state.Label, state.Text)) + MAKE.Pick.Pad
	end
	button.Size = UDim2.new(0, wide, button.Size.Y.Scale, button.Size.Y.Offset)
	return wide
end

-- The running light and the dots, while a button waits; the squeeze, while a touch's runs.
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if next(squeezing) ~= nil then
		local press = HudConfig.Motion.Press
		for button in squeezing do
			local state = states[button]
			if state == nil or button.Parent == nil then
				squeezing[button] = nil
				continue
			end
			local scale = Hud.Squeeze(t, state.DownAt, state.UpAt, press)
			local up = state.UpAt
			local down = state.DownAt :: number
			if up and t >= math.max(up, down + press.Least) + press.Out then
				scale = state.Grow
				state.DownAt, state.UpAt = nil, nil
				squeezing[button] = nil
			end
			for _, s in state.Scales do
				s.Scale = scale
			end
		end
	end
	if next(waiting) == nil then
		return
	end
	for button in waiting do
		local state = states[button]
		if state == nil or button.Parent == nil then
			waiting[button] = nil
			continue
		end
		local gradient = state.Layers.Ring:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Rotation = (t * 360 / 1.2) % 360
		end
		for i, dot in state.Dots do
			dot.ImageTransparency = 0.15 + 0.6 * (0.5 + 0.5 * math.cos((t * 2.4 - (i - 1) / 3) * math.pi * 2))
		end
	end
end)

return Button
