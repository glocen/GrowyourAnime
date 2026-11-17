--!strict
-- Pill (client kit): a pill of the HUD in its system's colour (AR12, V2 Block; build/handoff/UI/hud/colour/hud_colour.json,
-- pieces.pill and pieces.hint). Its layers, in Modulo's order: the kit's shadow, the body in the system's two colours, the
-- block of colour at its left (its leaning side and dark seam drawn in), the bold edge and the glint in the system's;
-- on the block, the system's mark in ink. Its words start past the block in the system's pale ink, a second value
-- right-aligned in its soft ink, and Power's wears a thread of light under them. A hint is a pill with its words centred.
--   Pill.new{ Name, System, Width, ... }     its parts: Frame, Mark, Value, Extra, Thread
--   Pill.Before(parts, piece, gap)          `piece` held just left of the second value's words, as they change

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local Skin = require(script.Parent.Skin)
local Text = require(script.Parent.Text)
local Bar = require(script.Parent.Bar)

export type Props = {
	Name: string,
	System: string, -- a row of Config.UIKit.Systems
	Width: number,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Thread: boolean?, -- a thread of light under its words (Power's)
	Centred: boolean?, -- a hint: one line, centred
}

export type Parts = {
	Frame: Frame,
	Mark: ImageLabel, -- the system's mark, where a reward flies to
	Value: TextLabel,
	Extra: TextLabel?, -- nil on a hint
	Thread: Frame?,
}

local Pill = {}

Pill.Height = 30
local MARK = 20 -- the mark's size, its middle MARK_X from the left
local MARK_X = 16.5
local WORDS = 41 -- the words' left
local RIGHT = 10 -- the second value's gap to the right edge
local THREAD = { High = 3, Foot = 8, Short = 9, Lift = 2 } -- the thread: its height, how far above the foot, short of the right; the words' lift over it
local HINT = { Aside = 10, Clear = 38 } -- a hint's words: centred this far right of the middle, clear of the block

function Pill.new(props: Props): Parts
	local system = UIKit.Systems[props.System]
	assert(system, `UIKit has no system "{props.System}"`)
	local high = Pill.Height
	local frame = Instance.new("Frame")
	frame.Name = props.Name
	frame.Size = UDim2.fromOffset(props.Width, high)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame:SetAttribute("System", props.System)
	local skin = Skin.Of(frame)
	Skin.Lay(skin, "PanelShadow", { Name = "Shadow", Z = 1 })
	Skin.Lay(skin, "PanelFill", { Name = "Fill", Tint = system.Panel, Alpha = system.Alpha, Z = 2 })
	Skin.Lay(skin, "BlockPill", { Name = "Block", X = 0, Y = 0, Tint = system.Block, Z = 3 })
	Skin.Lay(skin, "PanelEdgeBold", { Name = "Edge", Tint = system.Edge, Z = 4 })
	Skin.Lay(skin, "PanelGlint", { Name = "Glint", Tint = system.Glint, Z = 5 })
	local mark = Skin.Icon(frame, system.Mark, MARK_X, high / 2, MARK, nil, 2)
	mark.Name = "Mark"
	local lift = if props.Thread then -THREAD.Lift else 0
	local value: TextLabel
	local extra: TextLabel? = nil
	if props.Centred then
		value = Text.new({
			Name = "Value",
			Size = Theme.Text.Caption,
			Font = Theme.Font.Strong,
			Colour = system.Text,
			Align = Enum.TextXAlignment.Center,
			Truncate = true,
			Box = UDim2.new(1, -2 * (HINT.Clear - HINT.Aside), 1, 0),
			Position = UDim2.new(0.5, HINT.Aside, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = frame,
		})
	else
		value = Text.new({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = system.Text, Box = UDim2.fromOffset(props.Width - WORDS - RIGHT, high), Position = UDim2.fromOffset(WORDS, lift), Parent = frame })
		extra = Text.new({ Name = "Extra", Size = Theme.Text.Caption, Colour = system.Soft, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(80, high), Position = UDim2.new(1, -RIGHT, 0, lift), AnchorPoint = Vector2.new(1, 0), Parent = frame })
	end
	local thread = if props.Thread
		then Bar.new({ Name = "Charge", Size = UDim2.fromOffset(props.Width - WORDS - THREAD.Short, THREAD.High), Position = UDim2.fromOffset(WORDS, high - THREAD.Foot), Colour = system.Colour, Parent = frame })
		else nil
	frame.Parent = props.Parent
	return { Frame = frame, Mark = mark, Value = value, Extra = extra, Thread = thread }
end

-- Holds `piece` just left of the second value's words, `gap` points clear, its middle on their line (the battery's mark
-- before its reading in Power's: research, TR41 (e)). The words are right-aligned, so it follows the width they draw at,
-- now and whenever it changes: their own bounds, in the pill's points.
function Pill.Before(parts: Parts, piece: GuiObject, gap: number)
	local extra = parts.Extra
	if extra == nil then
		return
	end
	local function place()
		local scale = extra.AbsoluteSize.X / extra.Size.X.Offset
		if scale <= 0 then
			return
		end
		piece.Position = UDim2.new(1, -(RIGHT + extra.TextBounds.X / scale + gap), 0, extra.Position.Y.Offset + extra.Size.Y.Offset / 2)
	end
	piece.AnchorPoint = Vector2.new(1, 0.5)
	place()
	extra:GetPropertyChangedSignal("TextBounds"):Connect(place)
	extra:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
end

return Pill
