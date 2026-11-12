--!strict
-- Button (client kit): a press, in the seven states every component has (docs/ui.md): rest, pressed, selected, disabled
-- with its reason, waiting on the server, succeeded, failed. Drawn from the kit in Modulo's order (tools/blender/ui_kit.py,
-- `button`): the shadow, a lit ring's glow, the body, the disabled veil, the edge, the pressed shade, the lit ring, and the
-- accent's base line at rest. A press that waits (an Act) shows the light running round its edge and three dots until it
-- answers, and refuses a second press meanwhile, so nothing is asked twice. It flashes succeeded or failed only on the
-- server's answer (rule 4: the interface never lies). Pressed sinks it a pixel; no state moves the layout.
--   Button.new{ Name, Text, Size, OnPress, ... }      a button; OnPress may return true (succeeded) or false (failed)
--   Button.Set(button, { Text = ..., Disabled = "why" | false, Selected = true | false })
--   Button.Press(button)                             what a tap does, for tests: false when disabled or pending
--   Button.State(button)                             the state it shows

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local Hud = require(Shared.Rules.Hud)
local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)
local Skin = require(script.Parent.Skin)
local Panel = require(script.Parent.Panel)

export type Props = {
	Name: string,
	Text: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Primary: boolean?, -- the screen's one main action
	Palette: string?,
	LayoutOrder: number?,
	TextSize: number?,
	OnPress: () -> ...any,
}

type State = {
	Label: TextLabel,
	Tick: ImageLabel,
	Layers: { [string]: ImageLabel },
	Dots: { ImageLabel },
	Text: string,
	Disabled: string?, -- the reason, while disabled
	Pending: boolean,
	Selected: boolean,
	Primary: boolean,
	Held: boolean,
	Flash: string?, -- "Succeeded" or "Failed", for a moment after the server's answer
	FlashUntil: number,
	OnPress: () -> ...any,
}

local Button = {}

Button.FlashSeconds = 0.6

-- Held until the button is destroyed: a weak table keyed by an instance can lose a live one (Text's note).
local states: { [TextButton]: State } = {}
local waiting: { [TextButton]: boolean } = {}

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

local function paint(button: TextButton, state: State)
	local p = Panel.Palette(button)
	local now = Button.State(button)
	local layers = state.Layers
	local lit = if now == "Selected" then p.Accent elseif now == "Succeeded" then UIKit.Good elseif now == "Failed" then UIKit.Bad else nil
	local pressed = now == "Pressed"
	local inked = now == "Selected" and p.Selected ~= nil
	local skin = Skin.Of(button)
	skin.Position = UDim2.fromOffset(0, if pressed then 1 else 0)
	layers.Shadow.Visible = not pressed
	layers.RingGlow.Visible = lit ~= nil
	if lit then
		Skin.Tint(layers.RingGlow, lit)
	end
	Skin.Tint(layers.Fill, if pressed then p.Pressed elseif inked then p.Selected else p.Button)
	layers.Veil.Visible = now == "Disabled"
	layers.Edge.ImageTransparency = if now == "Disabled" then 0.55 else 0
	layers.Shade.Visible = pressed
	layers.Ring.Visible = lit ~= nil or now == "Waiting"
	Skin.Tint(layers.Ring, lit or p.Accent)
	local gradient = layers.Ring:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Enabled = now == "Waiting"
	end
	local base = now == "Rest" or pressed
	layers.Base.Visible = base
	layers.BaseGlow.Visible = base
	Skin.Tint(layers.Base, if pressed then Color3.new(1, 1, 1) else p.Accent)
	layers.BaseGlow.ImageTransparency = if pressed then 0 else 0.55
	layers.Well.Visible = now == "Waiting"
	for _, dot in state.Dots do
		dot.Visible = now == "Waiting"
	end
	waiting[button] = if now == "Waiting" then true else nil
	state.Tick.Visible = now == "Succeeded"
	state.Label.Text = Hud.Says(state.Text, state.Disabled, false)
	state.Label.Visible = now ~= "Waiting"
	state.Label.Position = UDim2.fromOffset(if now == "Succeeded" then 12 else 0, if pressed then 1 else 0)
	state.Label.TextColor3 = if now == "Disabled" then p.Soft elseif inked then (p.SelectedText or p.Text) else p.Text
	button:SetAttribute("Disabled", state.Disabled or "")
	button:SetAttribute("Pending", state.Pending)
	button:SetAttribute("State", now)
end

function Button.Press(button: TextButton): boolean
	local state = states[button]
	if state == nil or state.Disabled or state.Pending then
		return false
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
	local p = Panel.Palette(button)
	local bold = if (p.Border or 1) > 1 then "Bold" else ""
	local skin = Skin.Of(button)
	local layers: { [string]: ImageLabel } = {
		Shadow = Skin.Lay(skin, "ButtonShadow", { Name = "Shadow", Z = 1 }),
		RingGlow = Skin.Lay(skin, "ButtonRingGlow", { Name = "RingGlow", Z = 2 }),
		Fill = Skin.Lay(skin, "ButtonFill", { Name = "Fill", Tint = p.Button, Z = 3 }),
		Veil = Skin.Lay(skin, "ButtonFill", { Name = "Veil", Tint = p.Ground, Alpha = 0.55, Z = 4 }),
		Edge = Skin.Lay(skin, "ButtonEdge" .. bold, { Name = "Edge", Tint = p.Edge, Z = 5 }),
		Shade = Skin.Lay(skin, "ButtonPressedShade", { Name = "Shade", Z = 6 }),
		Ring = Skin.Lay(skin, "ButtonRing", { Name = "Ring", Z = 7 }),
		Base = Skin.Lay(skin, "ButtonBase", { Name = "Base", Z = 8 }),
		BaseGlow = Skin.Lay(skin, "ButtonBaseGlow", { Name = "BaseGlow", Tint = p.Accent, Z = 9 }),
	}
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
	local well = Skin.Lay(skin, "DotsWell", { Name = "Well", X = -26, Y = -7, Z = 10 })
	centred(well, 0.5)
	layers.Well = well
	local dots = {}
	for i = 0, 2 do
		local dot = Skin.Icon(skin, "Dot", -13 + 13 * i, 0, 12 * (1 - 0.17 * i), p.Accent, 11)
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
	local tick = Skin.Icon(button, "Tick", 29, 0, 20, UIKit.Good, 2)
	centred(tick, 0)
	tick.Name = "Tick"
	local state: State = {
		Label = label,
		Tick = tick,
		Layers = layers,
		Dots = dots,
		Text = props.Text,
		Disabled = nil,
		Pending = false,
		Selected = false,
		Primary = props.Primary == true,
		Held = false,
		Flash = nil,
		FlashUntil = 0,
		OnPress = props.OnPress,
	}
	states[button] = state
	button.Destroying:Connect(function()
		states[button] = nil
		waiting[button] = nil
	end)
	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.Held = true
			paint(button, state)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.Held = false
			paint(button, state)
		end
	end)
	button.Activated:Connect(function()
		Button.Press(button)
	end)
	paint(button, state)
	button.Parent = props.Parent
	return button
end

-- A new label, or disabled with its reason (a string), or enabled again (false); selected while its screen is open.
function Button.Set(button: TextButton, change: { Text: string?, Disabled: (string | boolean)?, Selected: boolean? })
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
	paint(button, state)
end

-- The running light and the dots, while a button waits.
RunService.RenderStepped:Connect(function()
	if next(waiting) == nil then
		return
	end
	local t = os.clock()
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
