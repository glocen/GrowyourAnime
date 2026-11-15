--!strict
-- Hover (client kit): everything that presses answers the pointer (docs/test-requests.md, TR20). On a computer, a thing
-- the mouse is over eases its share up over Config.Hud.Motion.Hover.In and back over Out; with a pad, the selected thing
-- does the same and wears a rim of its owner's in place of Roblox's selection image; on touch nothing answers. Which it
-- is goes by the last input, never TouchEnabled, so a laptop's touchscreen still hovers from its mouse. Each thing draws
-- its own answer from its share (its paint), so nothing moves its neighbours. Pressed beats hover, and open beats both:
-- that's the owner's paint to keep.
--   Hover.On(target, paint)      paint(share 0 to 1, pad) each frame the share or the pad's selection changes
--   Hover.Share(target)          the share now, for tests
--   Hover.Since(target)          seconds the pointer has been over it, 0 while it isn't
--   Hover.Kind()                 "Mouse", "Pad" or "Touch": the last input's kind
--   Hover.Force(target, over?)   a test's mouse over a target, or off it; nil gives it back to the real one
--   Hover.Pretend(kind?)         a test's last input kind; nil gives it back
--   Hover.Lift(frame, share, keep?)   a frame's own children lifted Lift points at `share` (all but `keep`, its tap)
--   Hover.White(colour, share)        a colour White of the way toward white at full share
--   Hover.Whites(sequence, share)     each stop of a gradient the same

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HudConfig = require(game:GetService("ReplicatedStorage").Shared.Config.Hud)

export type Kind = "Mouse" | "Pad" | "Touch"
type Paint = (share: number, pad: boolean) -> ()
type Entry = {
	Paint: Paint,
	Mouse: boolean, -- the mouse is over it
	Forced: boolean?,
	Progress: number, -- 0 to 1, linear; the share is its ease
	Since: number?, -- os.clock() the pointer came over it
	Shown: number, -- the share painted last
	Pad: boolean, -- painted last as a pad's selection
}

local Hover = {}

local entries: { [GuiObject]: Entry } = {}
local kind: Kind = "Mouse"
local pretended: Kind? = nil
local NO_IMAGE = Instance.new("Frame") -- Roblox's selection image gives way to each thing's own rim
NO_IMAGE.BackgroundTransparency = 1
NO_IMAGE.Size = UDim2.fromScale(1, 1)

local function kindOf(input: Enum.UserInputType): Kind?
	if input == Enum.UserInputType.Touch then
		return "Touch"
	elseif input.Name:sub(1, 7) == "Gamepad" then
		return "Pad"
	elseif input == Enum.UserInputType.MouseMovement or input == Enum.UserInputType.MouseButton1 or input == Enum.UserInputType.MouseButton2 or input == Enum.UserInputType.MouseWheel then
		return "Mouse"
	end
	return nil -- a key: the kind it was
end

kind = kindOf(UserInputService:GetLastInputType()) or (if UserInputService.MouseEnabled then "Mouse" else "Touch")
UserInputService.LastInputTypeChanged:Connect(function(input: Enum.UserInputType)
	kind = kindOf(input) or kind
end)

function Hover.Kind(): Kind
	return pretended or kind
end

function Hover.Pretend(as: Kind?)
	pretended = as
end

local function over(target: GuiObject, entry: Entry): boolean
	local now = Hover.Kind()
	if now == "Touch" then
		return false
	elseif now == "Pad" then
		return GuiService.SelectedObject == target
	end
	local mouse = if entry.Forced ~= nil then entry.Forced else entry.Mouse
	return mouse and target.Visible
end

function Hover.On(target: GuiObject, paint: Paint)
	local entry: Entry = { Paint = paint, Mouse = false, Forced = nil, Progress = 0, Since = nil, Shown = 0, Pad = false }
	entries[target] = entry
	target.SelectionImageObject = NO_IMAGE
	target.MouseEnter:Connect(function()
		entry.Mouse = true
	end)
	target.MouseLeave:Connect(function()
		entry.Mouse = false
	end)
	target.Destroying:Connect(function()
		entries[target] = nil
	end)
end

function Hover.Share(target: GuiObject): number
	local entry = entries[target]
	return if entry then entry.Shown else 0
end

function Hover.Since(target: GuiObject): number
	local entry = entries[target]
	local since = if entry then entry.Since else nil
	return if since then os.clock() - since else 0
end

function Hover.Force(target: GuiObject, on: boolean?)
	local entry = entries[target]
	if entry then
		entry.Forced = on
	end
end

function Hover.White(colour: Color3, share: number): Color3
	return colour:Lerp(Color3.new(1, 1, 1), HudConfig.Motion.Hover.White * share)
end

function Hover.Whites(sequence: ColorSequence, share: number): ColorSequence
	if share <= 0 then
		return sequence
	end
	local points = {}
	for _, point in sequence.Keypoints do
		table.insert(points, ColorSequenceKeypoint.new(point.Time, Hover.White(point.Value, share)))
	end
	return ColorSequence.new(points)
end

-- Each child's place before its lift, so the lift never adds up.
local rests: { [GuiObject]: UDim2 } = setmetatable({}, { __mode = "k" }) :: any

function Hover.Lift(frame: GuiObject, share: number, keep: Instance?)
	local up = UDim2.fromOffset(0, -HudConfig.Motion.Hover.Lift * share)
	local function lift(piece: GuiObject)
		local rest = rests[piece]
		if rest == nil then
			rest = piece.Position
			rests[piece] = rest
		end
		piece.Position = (rest :: UDim2) + up
	end
	for _, child in frame:GetChildren() do
		if child ~= keep and child:IsA("GuiObject") then
			lift(child)
		elseif child.Name == "NL_Skin" then -- the kit's skin, in its folder (Skin.Of)
			local skin = child:FindFirstChild("Skin")
			if skin and skin:IsA("GuiObject") then
				lift(skin)
			end
		end
	end
end

RunService.RenderStepped:Connect(function(dt: number)
	local motion = HudConfig.Motion.Hover
	for target, entry in entries do
		local on = over(target, entry)
		if on and entry.Since == nil then
			entry.Since = os.clock()
		elseif not on then
			entry.Since = nil
		end
		local goal = if on then 1 else 0
		if entry.Progress ~= goal then
			local seconds = if on then motion.In else motion.Out
			local step = if seconds > 0 then dt / seconds else 1
			entry.Progress = if on then math.min(entry.Progress + step, 1) else math.max(entry.Progress - step, 0)
		end
		local p = entry.Progress
		local share = 1 - (1 - p) * (1 - p) -- eased out
		local pad = on and Hover.Kind() == "Pad"
		if share ~= entry.Shown or pad ~= entry.Pad then
			entry.Shown, entry.Pad = share, pad
			local ok, problem = pcall(entry.Paint, share, pad)
			if not ok then
				warn(`Hover {target.Name}: {problem}`)
			end
		end
	end
end)

return Hover
