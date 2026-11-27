--!strict
-- UiLint (client, Studio only): checks every label the player can see now, on whatever is open (from the handbook's,
-- handbook/tech/studio/UiLint.luau, without its shadow check: this kit draws no shadow copies). For each visible, non-empty
-- label in one of our containers (named NL_...):
--   its text fits its box, unless it truncates on purpose (a line box may overrun by FIT_TOLERANCE pixels);
--   it renders at least Theme.Text.Minimum;
--   it lies inside its screen (not for the World layer's plates, which follow the world off the edges);
--     a label a scrolling list (or any clipping frame) hides entirely isn't drawn, so isn't checked, and one it cuts
--     is checked by the part it shows;
--   it doesn't show Roblox's default "Label";
--   a Voidkin's name in it never goes to Roblox's automatic translation: its AutoLocalize is off (the director,
--     2026-11-18, D8; NameGuardController keeps it so). A button's text counts too.
-- And for what the player touches and reads around the world (docs/ui.md, rule 1; TR3):
--   every button that takes a tap is Theme.Size.Touch or more on its least side, rendered;
--   each piece of the HUD and of an open screen lies inside its layer's safe area (Layers: clear of Roblox's top bar and
--     the notch; a test's phone box when one is set);
--   no two pieces of the HUD overlap;
--   none sits under the thumbs' controls (Roblox's jump button and fixed thumbstick, on a touch screen);
--   no scrolling list draws Roblox's own thumb: one that hides it by a thickness of nought hides its image too, since
--     Roblox draws a thin line there all the same (TR54's list, the Bag's chips).
-- And contrast (TR63, item 2; WCAG 2's ratio): each shown label's text against the colour behind it, 4.5:1 at least, 3:1
--   for large text (24 px, or 18.66 px bold: 18 pt and 14 pt). Behind it: its own background and its ancestors', and a
--   lower sibling frame under its middle, laid down to the first opaque one, a gradient read at that point. Read down the
--   engine's own stack at that point, across ScreenGuis; a label under the same words is their shadow, skipped. Over a glass
--   that covers at least half the world, the worse of a black and a white world beneath. Where an image or the bare world
--   shows through, the colour behind isn't known from here: the label is counted unread (Unread, with why and what is in
--   the way), never passed or failed. A text stroke counts when it's the better side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Names = require(ReplicatedStorage.Shared.Rules.Names)

local OURS = "NL_"
local WORLD = "NL_World"
local HUD = "NL_Hud"
local INSET: { [string]: boolean } = { NL_Hud = true, NL_Menus = true, NL_Band = true } -- laid out inside the safe area, or the top bar's free room (Layers)
local THUMBS: { [string]: boolean } = { JumpButton = true, ThumbstickFrame = true } -- Roblox's touch controls, by name
local TOLERANCE = 1 -- pixels
local FIT_TOLERANCE = 2 -- pixels a line box may overrun its frame
local PLACEHOLDER = "Label"
local CONTRAST, CONTRAST_LARGE = 4.5, 3 -- WCAG 2's AA ratios
local LARGE, LARGE_BOLD = 24, 18.66 -- px: 18 pt, and 14 pt bold
local OPAQUE = 0.98 -- a background's alpha from which nothing behind it shows
local GLASS = 0.5 -- the least cover over the world read as glass, its words judged over a black and a white world

local UiLint = {}

export type Report = {
	Checked: number,
	Fit: { string },
	Size: { string },
	Screen: { string },
	Placeholder: { string },
	Names: { string },
	Touch: { string },
	Safe: { string },
	Overlap: { string },
	Thumbs: { string },
	Bars: { string },
	Contrast: { string },
	Unread: number, -- labels whose colour behind isn't known from here (an image, a gradient, the world)
	UnreadBy: { [string]: number }, -- and why: "art", "viewport", "world", "lettering" (a gradient on the text), "unlisted" (not in the engine's stack at its middle)
	UnreadAt: { [string]: { string } }, -- and the first few pieces in the way, for each why
}

-- Whether a piece draws: visible all the way up to its container, and that container enabled.
local function up(object: GuiObject): boolean
	local node: Instance? = object
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and (node :: LayerCollector).Enabled
end

local function overlaps(a: GuiObject, b: GuiObject): boolean
	local aLow, aHigh = a.AbsolutePosition, a.AbsolutePosition + a.AbsoluteSize
	local bLow, bHigh = b.AbsolutePosition, b.AbsolutePosition + b.AbsoluteSize
	return math.min(aHigh.X, bHigh.X) - math.max(aLow.X, bLow.X) > TOLERANCE
		and math.min(aHigh.Y, bHigh.Y) - math.max(aLow.Y, bLow.Y) > TOLERANCE
end

local function inside(piece: GuiObject, area: GuiObject): boolean
	local low, high = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
	local top, bottom = area.AbsolutePosition, area.AbsolutePosition + area.AbsoluteSize
	return low.X >= top.X - TOLERANCE and low.Y >= top.Y - TOLERANCE and high.X <= bottom.X + TOLERANCE and high.Y <= bottom.Y + TOLERANCE
end

-- Whether a label actually draws: visible all the way up, in an enabled screen of ours, not faded out. A plate in the
-- world (a SurfaceGui, a BillboardGui: the Strip's boards) is the world's, judged from the player's camera, and the
-- engine's stack at a point on the screen never lists it.
local function shown(object: TextLabel): boolean
	if object.TextTransparency >= 0.95 or object.Text == "" then
		return false
	end
	local node: Instance? = object
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and node:IsA("ScreenGui") and (node :: LayerCollector).Enabled and string.sub(node.Name, 1, #OURS) == OURS
end

-- The part of `label` its clipping frames let through, as (top left, bottom right) on screen, or nil when they hide all
-- of it (a row scrolled out of its list).
local function drawn(label: TextLabel): (Vector2?, Vector2?)
	local low, high = label.AbsolutePosition, label.AbsolutePosition + label.AbsoluteSize
	local node: Instance? = label.Parent
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and (node :: GuiObject).ClipsDescendants then
			local frame = node :: GuiObject
			local top, bottom = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
			low = Vector2.new(math.max(low.X, top.X), math.max(low.Y, top.Y))
			high = Vector2.new(math.min(high.X, bottom.X), math.min(high.Y, bottom.Y))
			if high.X <= low.X or high.Y <= low.Y then
				return nil, nil
			end
		end
		node = node.Parent
	end
	return low, high
end

-- The product of the UIScales over `object` (Layers fits each layer with one).
local function scaleOf(object: Instance): number
	local scale = 1
	local node: Instance? = object
	while node do
		local uiScale = node:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		node = node.Parent
	end
	return scale
end

-- WCAG 2's relative luminance and contrast ratio.
local function luminance(colour: Color3): number
	local function linear(c: number): number
		return if c <= 0.03928 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * linear(colour.R) + 0.7152 * linear(colour.G) + 0.0722 * linear(colour.B)
end

local function ratio(a: Color3, b: Color3): number
	local x, y = luminance(a), luminance(b)
	return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end
UiLint.Ratio = ratio

-- A sequence's value at t (0 to 1), straight between its keypoints, as Roblox lays a gradient.
local function colourAt(sequence: ColorSequence, t: number): Color3
	local points = sequence.Keypoints
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		if t <= b.Time then
			local span = b.Time - a.Time
			return if span <= 0 then b.Value else a.Value:Lerp(b.Value, math.clamp((t - a.Time) / span, 0, 1))
		end
	end
	return points[#points].Value
end

local function numberAt(sequence: NumberSequence, t: number): number
	local points = sequence.Keypoints
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		if t <= b.Time then
			local span = b.Time - a.Time
			return if span <= 0 then b.Value else a.Value + (b.Value - a.Value) * math.clamp((t - a.Time) / span, 0, 1)
		end
	end
	return points[#points].Value
end

-- Where `at` falls along `gradient` on `object`: 0 at its sequence's start, 1 at its end. Its Offset moves it in the
-- object's own scale, its Rotation turns it clockwise about the middle (exact at 0, 90, 180 and 270; near on a long
-- piece at other angles).
local function along(gradient: UIGradient, object: GuiObject, at: Vector2): number
	local size = object.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return 0.5
	end
	local d = (at - object.AbsolutePosition) / size - Vector2.new(0.5, 0.5) - gradient.Offset
	local angle = math.rad(gradient.Rotation)
	return math.clamp(d.X * math.cos(angle) + d.Y * math.sin(angle) + 0.5, 0, 1)
end

-- What a piece paints at `at` over what's behind it: nil for nothing (a clear background), or false when it isn't known
-- from here (an image, a viewport), with why and what in `unknown` and `blocker`. A gradient on a background is read at
-- the point: its colour times the background's, its transparency over the background's.
local unknown, blocker = "world", nil :: Instance?
local function paints(object: GuiObject, at: Vector2): { Colour: Color3, Alpha: number }? | false
	if (object:IsA("ImageLabel") or object:IsA("ImageButton")) and (object :: any).Image ~= "" and (object :: any).ImageTransparency < 0.95 then
		unknown, blocker = "art", object
		return false
	end
	if object:IsA("ViewportFrame") then
		unknown, blocker = "viewport", object
		return false
	end
	local alpha = 1 - object.BackgroundTransparency
	if alpha <= 0.02 then
		return nil
	end
	local colour = object.BackgroundColor3
	local gradient = object:FindFirstChildOfClass("UIGradient")
	if gradient and gradient.Enabled then
		local t = along(gradient, object, at)
		local tint = colourAt(gradient.Color, t)
		colour = Color3.new(colour.R * tint.R, colour.G * tint.G, colour.B * tint.B)
		alpha *= 1 - numberAt(gradient.Transparency, t)
		if alpha <= 0.02 then
			return nil
		end
	end
	return { Colour = colour, Alpha = alpha }
end

-- The colour behind `label`'s text at `at`, as two: over a black world and over a white one (the same when something
-- opaque is behind it), or nil when it isn't known from here. Read down the engine's own stack at that point
-- (GetGuiObjectsAtPosition: every ScreenGui, top first), from the label's own background to the first opaque piece. With
-- nothing opaque, a glass covering GLASS of the world or more is judged over both worlds. A label with the same words
-- drawn over it there is their shadow, not words to read: "shadow".
local function behind(label: TextLabel, at: Vector2): (Color3?, Color3?)
	local gui = label:FindFirstAncestorWhichIsA("BasePlayerGui")
	local stack: { GuiObject } = if gui then (gui :: BasePlayerGui):GetGuiObjectsAtPosition(at.X, at.Y) else {}
	local from = table.find(stack, label :: GuiObject)
	if from == nil then
		unknown, blocker = "unlisted", nil
		return nil, nil
	end
	for index = 1, from - 1 do
		local over: GuiObject = stack[index]
		if over:IsA("TextLabel") and (over :: TextLabel).Text == label.Text and (over :: TextLabel).TextTransparency < 0.5 then
			unknown, blocker = "shadow", over
			return nil, nil
		end
	end
	local layers: { { Colour: Color3, Alpha: number } } = {}
	local function laid(base: Color3?): Color3 -- the stack, up from its opaque base, or from `base` beneath it all
		local colour, first = base, #layers
		if colour == nil then
			colour, first = layers[#layers].Colour, #layers - 1
		end
		for index = first, 1, -1 do
			colour = (colour :: Color3):Lerp(layers[index].Colour, layers[index].Alpha)
		end
		return colour :: Color3
	end
	for index = from, #stack do
		local paint = paints(stack[index], at)
		if paint == false then
			return nil, nil
		elseif paint then
			table.insert(layers, paint)
			if paint.Alpha >= OPAQUE then
				local colour = laid()
				return colour, colour
			end
		end
	end
	-- nothing opaque: the world shows through
	local clear = 1
	for _, layer in layers do
		clear *= 1 - layer.Alpha
	end
	if #layers > 0 and 1 - clear >= GLASS then
		return laid(Color3.new(0, 0, 0)), laid(Color3.new(1, 1, 1))
	end
	unknown, blocker = "world", nil
	return nil, nil
end

-- The label's contrast and the ratio it needs, read at `at` (its middle by default), or nil and why when the colour
-- behind it isn't known. Over a glass, the worse of a black and a white world.
local function contrastOf(label: TextLabel, at: Vector2?): (number?, number, string?)
	local rendered = if label.TextScaled then label.TextBounds.Y else label.TextSize * scaleOf(label)
	local bold = label.FontFace.Weight.Value >= Enum.FontWeight.Bold.Value
	local need = if rendered >= LARGE - 0.01 or (bold and rendered >= LARGE_BOLD - 0.01) then CONTRAST_LARGE else CONTRAST
	if label:FindFirstChildOfClass("UIGradient") then
		unknown, blocker = "lettering", label
		return nil, need, "lettering"
	end
	local dark, light = behind(label, at or label.AbsolutePosition + label.AbsoluteSize / 2)
	if dark == nil or light == nil then
		return nil, need, unknown
	end
	local function against(back: Color3): number
		local text = back:Lerp(label.TextColor3, 1 - label.TextTransparency)
		local best = ratio(text, back)
		-- a stroke round the letters reads against them too
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke and stroke.Enabled and stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual and stroke.Transparency < 0.5 and stroke.Thickness >= 1 then
			best = math.max(best, ratio(text, back:Lerp(stroke.Color, 1 - stroke.Transparency)))
		elseif label.TextStrokeTransparency < 0.5 then
			best = math.max(best, ratio(text, back:Lerp(label.TextStrokeColor3, 1 - label.TextStrokeTransparency)))
		end
		return best
	end
	return math.min(against(dark), against(light)), need, nil
end
UiLint.ContrastOf = contrastOf

local function short(object: Instance): string
	local parts = {}
	local node: Instance? = object
	for _ = 1, 3 do
		if not node or node:IsA("PlayerGui") then
			break
		end
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

function UiLint.Run(): Report
	local report: Report = { Checked = 0, Fit = {}, Size = {}, Screen = {}, Placeholder = {}, Names = {}, Touch = {}, Safe = {}, Overlap = {}, Thumbs = {}, Bars = {}, Contrast = {}, Unread = 0, UnreadBy = {}, UnreadAt = {} }
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	-- The taps: every button the player can press now. The lists: every one shown, its own thumb hidden whole.
	for _, object in gui:GetDescendants() do
		if object:IsA("ScrollingFrame") and object.ScrollBarThickness == 0 and object.ScrollBarImageTransparency < 1 and up(object) then
			local screen = object:FindFirstAncestorOfClass("ScreenGui")
			if screen and string.sub(screen.Name, 1, #OURS) == OURS then
				table.insert(report.Bars, short(object))
			end
		end
		if object:IsA("GuiButton") and object.Active and up(object) then
			local screen = object:FindFirstAncestorOfClass("ScreenGui")
			if screen and screen.Name ~= WORLD and string.sub(screen.Name, 1, #OURS) == OURS then
				local side = math.min(object.AbsoluteSize.X, object.AbsoluteSize.Y)
				if side < Theme.Size.Touch - 0.5 then
					table.insert(report.Touch, `{short(object)} ({math.floor(object.AbsoluteSize.X)}x{math.floor(object.AbsoluteSize.Y)} < {Theme.Size.Touch})`)
				end
			end
		end
	end
	-- The pieces: each top-level piece of an inset layer, inside its safe area; the HUD's apart and clear of the thumbs.
	local thumbs: { GuiObject } = {}
	local touch = gui:FindFirstChild("TouchGui")
	if touch and touch:IsA("ScreenGui") and touch.Enabled then
		for _, control in touch:GetDescendants() do
			if control:IsA("GuiObject") and THUMBS[control.Name] and up(control) then
				table.insert(thumbs, control)
			end
		end
	end
	for _, screen in gui:GetChildren() do
		local root = if INSET[screen.Name] and screen:IsA("ScreenGui") and screen.Enabled then screen:FindFirstChild("Root") else nil
		if root == nil or not root:IsA("GuiObject") then
			continue
		end
		local pieces: { GuiObject } = {}
		local tops: { Instance } = {}
		for _, piece in root:GetChildren() do
			-- The slate's page (UI.Kit.Slate.Root) is a frame the layer's size that grows on a big screen: its pieces are the
			-- layer's own.
			if piece.Name == "NL_Page" then
				for _, inner in piece:GetChildren() do
					table.insert(tops, inner)
				end
			else
				table.insert(tops, piece)
			end
		end
		for _, piece in tops do
			if piece:IsA("GuiObject") and piece.Visible then
				table.insert(pieces, piece)
				if not inside(piece, root) then
					table.insert(report.Safe, short(piece))
				end
			end
		end
		if screen.Name == HUD then
			for i = 1, #pieces do
				for j = i + 1, #pieces do
					if overlaps(pieces[i], pieces[j]) then
						table.insert(report.Overlap, `{pieces[i].Name} and {pieces[j].Name}`)
					end
				end
				for _, control in thumbs do
					if overlaps(pieces[i], control) then
						table.insert(report.Thumbs, `{pieces[i].Name} under {control.Name}`)
					end
				end
			end
		end
	end
	-- The names: a shown label or button with a Voidkin's name as a whole word, left to translation.
	for _, object in gui:GetDescendants() do
		if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.AutoLocalize and shown(object :: any) then
			local name = Names.Found((object :: TextLabel).Text)
			if name then
				table.insert(report.Names, `{short(object)} ({name})`)
			end
		end
	end
	for _, object in gui:GetDescendants() do
		if not object:IsA("TextLabel") or not shown(object) then
			continue
		end
		local label = object :: TextLabel
		local low, high = drawn(label)
		if low == nil or high == nil then
			continue
		end
		report.Checked += 1
		local name = short(label)
		if label.Text == PLACEHOLDER then
			table.insert(report.Placeholder, name)
		end
		local has, need, why = contrastOf(label, (low + high) / 2) -- the middle of what's drawn, inside its clips
		if why == "shadow" then
			-- the same words drawn over it: their shadow, not read
		elseif has == nil then
			report.Unread += 1
			local reason = why :: string
			report.UnreadBy[reason] = (report.UnreadBy[reason] or 0) + 1
			local seenAt = report.UnreadAt[reason] or {}
			report.UnreadAt[reason] = seenAt
			local what = if blocker then (blocker :: Instance).Name else label.Name
			if #seenAt < 3 and table.find(seenAt, what) == nil then
				table.insert(seenAt, what)
			end
		elseif has < need - 0.005 then
			table.insert(report.Contrast, `{name} ({string.format("%.2f", has)}:1 < {need})`)
		end
		local bounds, box = label.TextBounds, label.AbsoluteSize
		local overruns = bounds.X > box.X + FIT_TOLERANCE or bounds.Y > box.Y + FIT_TOLERANCE
		if not label.TextFits and overruns and not label.TextScaled and label.TextTruncate == Enum.TextTruncate.None then
			table.insert(report.Fit, `{name} ({math.ceil(bounds.X)}x{math.ceil(bounds.Y)} in {math.floor(box.X)}x{math.floor(box.Y)})`)
		end
		local screen = label:FindFirstAncestorOfClass("ScreenGui")
		if screen then
			local rendered = label.TextSize * scaleOf(label)
			if rendered < Theme.Text.Minimum - 0.5 then
				table.insert(report.Size, `{name} ({string.format("%.1f", rendered)} px < {Theme.Text.Minimum})`)
			end
			if screen.Name ~= WORLD then
				-- from the layer's root (its safe area, or a test's phone box): layers that ignore the GUI inset start above y = 0
				local root = screen:FindFirstChild("Root")
				local area: GuiObject = if root and root:IsA("GuiObject") then root else screen :: any
				local position, far = low - area.AbsolutePosition, high - area.AbsolutePosition
				local limit = area.AbsoluteSize
				if position.X < -TOLERANCE or position.Y < -TOLERANCE or far.X > limit.X + TOLERANCE or far.Y > limit.Y + TOLERANCE then
					table.insert(report.Screen, name)
				end
			end
		end
	end
	return report
end

-- The style frame's tokens (TR63, item 2, after AR62's pick; Theme.Frame): every colour in it, its strokes and its radii.
local function tokenColours(node: any, into: { Color3 })
	for _, value in node do
		if typeof(value) == "Color3" then
			table.insert(into, value)
		elseif type(value) == "table" then
			tokenColours(value, into)
		end
	end
end

local function near(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) <= 1.5 / 255 and math.abs(a.G - b.G) <= 1.5 / 255 and math.abs(a.B - b.B) <= 1.5 / 255
end

local function onList(value: number, list: { number }): boolean
	for _, each in list do
		if math.abs(value - each) <= 0.05 then
			return true
		end
	end
	return false
end

-- What the shown pieces under `root` (or every one of our screens) draw off the style frame's tokens (Theme.Frame): a
-- fill, a text's colour, a stroke's colour or width, a corner's radius, each named once by its piece and value ("Card
-- BackgroundColor3 #4C3E92"). A report, never a failure: the screens move onto the tokens a screen at a time (AR62,
-- "After the pick"). Pictures (an image's tint) and gradients are art, not read. A pill (a corner of half its side or
-- more) and a square corner are the frame's own.
function UiLint.Strays(root: Instance?): ({ string }, number)
	local colours: { Color3 } = {}
	tokenColours(Theme.Frame, colours)
	local strokes, radii = { Theme.Frame.Stroke.Rim, Theme.Frame.Stroke.Hairline }, { 0, Theme.Frame.Radius.Panel, Theme.Frame.Radius.Card, Theme.Frame.Radius.Pill }
	local strays: { string } = {}
	local seen: { [string]: boolean } = {}
	local read = 0
	local function stray(object: Instance, what: string, value: string)
		local line = `{short(object)} {what} {value}`
		if not seen[line] then
			seen[line] = true
			table.insert(strays, line)
		end
	end
	local function colour(object: Instance, what: string, value: Color3)
		read += 1
		for _, token in colours do
			if near(value, token) then
				return
			end
		end
		stray(object, what, `#{value:ToHex():upper()}`)
	end
	local where: Instance = root or Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, object in where:GetDescendants() do
		local screen = object:FindFirstAncestorOfClass("ScreenGui")
		if root == nil and (screen == nil or string.sub(screen.Name, 1, #OURS) ~= OURS) then
			continue
		end
		if object:IsA("GuiObject") and up(object) then
			if object.BackgroundTransparency < 0.95 then
				colour(object, "BackgroundColor3", object.BackgroundColor3)
			end
			if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and (object :: TextLabel).Text ~= "" and (object :: TextLabel).TextTransparency < 0.95 then
				colour(object, "TextColor3", (object :: TextLabel).TextColor3)
			end
		elseif object:IsA("UIStroke") and object.Enabled and object.Transparency < 0.95 and object.Parent and object.Parent:IsA("GuiObject") and up(object.Parent :: GuiObject) then
			colour(object.Parent, "UIStroke.Color", object.Color)
			if not onList(object.Thickness, strokes) then
				stray(object.Parent, "UIStroke.Thickness", string.format("%.2f", object.Thickness))
			end
		elseif object:IsA("UICorner") and object.Parent and object.Parent:IsA("GuiObject") and up(object.Parent :: GuiObject) then
			local piece = object.Parent :: GuiObject
			local side = math.min(piece.AbsoluteSize.X, piece.AbsoluteSize.Y)
			local radius = object.CornerRadius.Scale * side + object.CornerRadius.Offset
			local pill = object.CornerRadius.Scale >= 0.5 or (side > 0 and radius >= side / 2 - 0.5)
			if not pill and (object.CornerRadius.Scale ~= 0 or not onList(object.CornerRadius.Offset, radii)) then
				stray(piece, "UICorner", string.format("%.1f", radius))
			end
		end
	end
	return strays, read
end

-- "a; b; c +2 more", or how many labels were checked when the list is empty.
function UiLint.Detail(list: { string }, checked: number): string
	if #list == 0 then
		return `{checked} labels checked`
	end
	local shown = {}
	for index = 1, math.min(#list, 6) do
		table.insert(shown, list[index])
	end
	return table.concat(shown, "; ") .. (if #list > 6 then ` +{#list - 6} more` else "")
end

-- The labels not read for contrast, why, and the first pieces in the way: "51 unread: art 40 (Plate, Icon), world 11".
function UiLint.Unread(report: Report): string
	local why = {}
	for reason, count in report.UnreadBy do
		local seenAt = report.UnreadAt[reason]
		table.insert(why, `{reason} {count}` .. (if seenAt and #seenAt > 0 then ` ({table.concat(seenAt, ", ")})` else ""))
	end
	table.sort(why)
	return `{report.Unread} unread` .. (if #why > 0 then `: {table.concat(why, ", ")}` else "")
end

return UiLint
