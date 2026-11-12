--!strict
-- Button (client kit): a press, with every state a screen needs (docs/ui.md, "Every component has these states"): rest,
-- pressed, disabled with its reason, waiting on the server. A press that waits (an Act) shows pending until it answers and
-- refuses a second press meanwhile, so nothing is asked twice. Pressed changes colour only, never the layout.
--   Button.new{ Name, Text, Size, OnPress, ... }      a button
--   Button.Set(button, { Text = ..., Disabled = "why" | false })
--   Button.Press(button)                             what a tap does, for tests: false when disabled or pending

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Text)

export type Props = {
	Name: string,
	Text: string,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Primary: boolean?, -- the screen's one main action
	LayoutOrder: number?,
	TextSize: number?,
	OnPress: () -> (),
}

type State = {
	Label: TextLabel,
	Text: string,
	Disabled: string?, -- the reason, while disabled
	Pending: boolean,
	Primary: boolean,
	Held: boolean,
	OnPress: () -> (),
}

local Button = {}

local PENDING = "…"

local states: { [TextButton]: State } = setmetatable({}, { __mode = "k" }) :: any

local function paint(button: TextButton, state: State)
	local colour = if state.Primary then Theme.Colour.Primary else Theme.Colour.PlateHigh
	if state.Disabled then
		colour = Theme.Colour.Plate
	elseif state.Held or state.Pending then
		colour = Theme.Colour.Pressed
	end
	button.BackgroundColor3 = colour
	button.AutoButtonColor = false
	-- A button at rest is the colour of the row it sits on: its edge is what says it can be pressed.
	local edge = button:FindFirstChild("Edge") :: UIStroke?
	if edge then
		edge.Enabled = not state.Primary and not state.Disabled
	end
	state.Label.Text = if state.Pending then PENDING elseif state.Disabled then state.Disabled else state.Text
	state.Label.TextColor3 = if state.Disabled then Theme.Colour.Disabled else Theme.Colour.Text
	button:SetAttribute("Disabled", state.Disabled or "")
	button:SetAttribute("Pending", state.Pending)
end

function Button.Press(button: TextButton): boolean
	local state = states[button]
	if state == nil or state.Disabled or state.Pending then
		return false
	end
	state.Pending = true
	paint(button, state)
	task.spawn(function()
		local ok, problem = pcall(state.OnPress)
		if not ok then
			warn(`Button {button.Name}: {problem}`)
		end
		state.Pending = false
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
	button.BorderSizePixel = 0
	button.LayoutOrder = props.LayoutOrder or 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
	corner.Parent = button
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Theme.Colour.Line
	edge.Thickness = Theme.Size.Edge
	edge.Parent = button
	local label = Text.new({
		Name = "Label",
		Size = props.TextSize or Theme.Text.Body,
		Font = Theme.Font.Strong,
		Align = Enum.TextXAlignment.Center,
		Parent = button,
	})
	local state: State = {
		Label = label,
		Text = props.Text,
		Disabled = nil,
		Pending = false,
		Primary = props.Primary == true,
		Held = false,
		OnPress = props.OnPress,
	}
	states[button] = state
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

-- A new label, or disabled with its reason (a string), or enabled again (false).
function Button.Set(button: TextButton, change: { Text: string?, Disabled: (string | boolean)? })
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
	paint(button, state)
end

return Button
