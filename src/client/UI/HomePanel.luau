--!strict
-- HomePanel (client UI): Home's panel (AR49 in C: research's pick of 2026-11-19, 23:54, and its second look of
-- 2026-11-20, 00:07; build/handoff/UI/home_cards/; docs/ui.md, the dock). The dock's middle cell, Home, opens it over the
-- world and the HUD dimmed, the dock lit: three cards with their own art, each opening its whole screen on the page last
-- shown. Equipment shows its whole job (the forge, the ring at +7, the blade, our jewel and our emblem); Voidkin the lead
-- itself, live (Figure.Bust), on its rarity's light, its head rising out of its frame; Settings is steel. The glass grows
-- from the pointer with a small overshoot as the cards land in a short stagger, and it leaves quicker, all at once
-- (docs/ui.md, "Screens arrive"). A card's press lights it (its press image; on Voidkin under the live view, so a press
-- never washes the lead), the panel makes way as the card's screen rises over it (Kit.Screen's Rise), and that screen's
-- Back brings it back. A tap on the dim closes it, and a screen opened another way does. Every place, tint and time is
-- Config.Hud.Home's, in points from the glass's top left. Each card is a kit button (Bare: its art is laid here and
-- squeezes as a face does), so it has the kit's states and Button.Press for tests.
--   HomePanel.new(cover, hud, foot, presses, lead)   the panel and its dim in `cover` (the Cover layer, over the HUD): its
--                                                    foot Above over the dock's top, `foot` up from `hud`'s foot; its left
--                                                    clear of `lead` (the lead's card); presses[card] opens that screen
--   HomePanel.Open(panel), HomePanel.Close(panel)    shown or not, in motion
--   HomePanel.Shown(panel)                           whether it's open, or opening
--   HomePanel.Holds(panel)                           whether a screen its card opened is open, whose Back comes back here
--   HomePanel.Lead(panel, def)                       the lead shown live, and its light (rebuilt only when it changes)
--   HomePanel.Covers(panel, piece)                   how much of a HUD piece the panel hides now, 0 to 1: the HUD fades it
--   HomePanel.Paint(panel)                           each frame: its motion, and each card's look

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Button = require(script.Parent.Kit.Button)
local Screen = require(script.Parent.Kit.Screen)
local Skin = require(script.Parent.Kit.Skin)
local Fade = require(script.Parent.Kit.Fade)
local Layers = require(script.Parent.Layers)
local Figure = require(script.Parent.VoidkinScreen.Figure)

local HOME = HudConfig.Home
local FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
local WHITE = Color3.new(1, 1, 1)

-- A place in whole points, to the nearest (Seam.Whole's rule: a UDim's offset is cut toward nought).
local function whole(x: number, y: number): UDim2
	return UDim2.fromOffset(math.round(x), math.round(y))
end

type Laid = { any } -- kit name, left, top, wide, tall, then its tint: a colour, or "Lit" for the lead's light
type Def = { Name: string, Screen: string, Tap: { number }, Z: number, Images: { Laid }, Over: { Laid }?, Press: Laid, Words: { { any } }, Mark: { any }? }
export type Card = { Def: Def, Button: TextButton, Holder: Frame, Press: ImageLabel, Lit: { ImageLabel }, Shown: string }
type Motion = { At: number, Opening: boolean, From: number, To: number, Seconds: number, Seen: number, DimFrom: number, DimTo: number, Done: (() -> ())? }
export type Panel = {
	Frame: Frame,
	Scale: UIScale,
	Glass: { ImageLabel },
	Pointer: ImageLabel,
	Dim: Frame, -- four panels round the dock's rect: Top, Foot, Left, Right
	Panels: { TextButton },
	Dimmed: number,
	Hud: GuiObject,
	Foot: number,
	Lead: GuiObject?, -- the lead's card, kept clear
	Laid: string,
	Cards: { [string]: Card },
	Presses: { [string]: () -> () },
	Open: boolean,
	Shown: number, -- how much of it shows now, 0 to 1: the glass's opacity
	Motion: Motion?,
	Lit: string?, -- the card whose press is stepping into its screen, lit until LitUntil
	LitUntil: number,
	From: string?, -- the screen a card opened, while it's open
	Live: Figure.Bust?,
	LeadDef: string?,
}

local HomePanel = {}

local function backOut(t: number, back: number): number
	local u = t - 1
	return 1 + (back + 1) * u * u * u + back * u * u
end

local function lay(parent: Instance, laid: Laid, origin: Vector2, z: number): ImageLabel
	local record = UIKit.Images[laid[1]]
	assert(record, `UIKit has no image "{laid[1]}"`)
	local image = Instance.new("ImageLabel")
	image.Name = laid[1]
	image.BackgroundTransparency = 1
	image.Image = record.Id
	image.ScaleType = Enum.ScaleType.Stretch
	image.Position = whole(laid[2] - origin.X, laid[3] - origin.Y)
	image.Size = whole(laid[4], laid[5])
	image.ZIndex = z
	local tint = laid[6]
	if typeof(tint) == "Color3" then
		image.ImageColor3 = tint
	end
	image:SetAttribute("Kit", laid[1])
	image.Parent = parent
	return image
end

-- A word in the face's bold italic, its capitals' top at y and its left (or its middle, Centre) at x, a dark copy under.
local function word(parent: Instance, spec: { any }, origin: Vector2, z: number): TextLabel
	local name, said, x, y, size, align, colour = spec[1], spec[2], spec[3], spec[4], spec[5], spec[6], spec[7]
	local function label(nameOf: string, dx: number, dy: number, tint: Color3, t: number, zOf: number): TextLabel
		local made = Instance.new("TextLabel")
		made.Name = nameOf
		made.BackgroundTransparency = 1
		made.FontFace = FACE
		made.TextSize = size
		made.Text = said
		made.TextColor3 = tint
		made.TextTransparency = t
		made.TextXAlignment = if align == "Centre" then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
		made.TextYAlignment = Enum.TextYAlignment.Top
		made.AnchorPoint = Vector2.new(if align == "Centre" then 0.5 else 0, 0)
		made.Size = UDim2.fromOffset(if align == "Centre" then 160 else 200, math.ceil(size * 1.4))
		made.Position = UDim2.fromOffset(x - origin.X + dx, y - origin.Y - HOME.CapTop * size + dy)
		made.ZIndex = zOf
		made.Parent = parent
		return made
	end
	local shadow = HOME.Shadow
	label(`{name}Shadow`, shadow.Offset.X, shadow.Offset.Y, shadow.Colour, shadow.T, z)
	return label(name, 0, 0, colour or HOME.Word, 0, z + 1)
end

-- The panel and its dim laid in the cover from the HUD's foot, in the cover's points: the pointer's middle on the Home
-- cell's (the dock's middle), the glass's left clear of the lead's card or centred on the phone, never past its right.
local function place(panel: Panel)
	local cover = panel.Dim.Parent :: GuiObject
	local hud = panel.Hud
	local scale = Layers.Scale()
	local origin = cover.AbsolutePosition
	local lead = panel.Lead
	local leadRight = if lead and lead.Visible then (lead.AbsolutePosition.X + lead.AbsoluteSize.X - origin.X) / scale else 0
	local key = `{cover.AbsoluteSize} {hud.AbsolutePosition} {hud.AbsoluteSize} {scale} {leadRight}`
	if key == panel.Laid then
		return
	end
	panel.Laid = key
	local size = HOME.Size
	local wide, tall = cover.AbsoluteSize.X / scale, cover.AbsoluteSize.Y / scale
	local foot = (hud.AbsolutePosition.Y + hud.AbsoluteSize.Y - origin.Y) / scale
	local middle = (hud.AbsolutePosition.X + hud.AbsoluteSize.X / 2 - origin.X) / scale
	local top = foot - panel.Foot -- the dock's top
	local left = math.min(math.max(leadRight + HOME.Gap, wide / 2 - size.X / 2), wide - HOME.Edge - size.X)
	local glassFoot = top - HOME.Above
	local at = middle - left -- the pointer's middle, from the glass's left
	panel.Frame.AnchorPoint = Vector2.new(at / size.X, 1)
	panel.Frame.Position = whole(middle, glassFoot)
	local pointer = HOME.Pointer
	panel.Pointer.Position = whole(at + (pointer[2] :: number), pointer[3] :: number)
	-- The dim's hole: the dock's rect, Side each side of its middle up to its top.
	local holeLeft, holeRight = middle - HOME.Dim.Side, middle + HOME.Dim.Side
	local high = foot - top
	local boxes = { { 0, 0, wide, top }, { 0, foot, wide, tall - foot }, { 0, top, holeLeft, high }, { holeRight, top, wide - holeRight, high } }
	for index, each in panel.Panels do
		local box = boxes[index]
		each.Position = whole(box[1], box[2])
		each.Size = whole(math.max(box[3], 0), math.max(box[4], 0))
	end
end

local function dimmed(panel: Panel, transparency: number)
	panel.Dimmed = transparency
	for _, each in panel.Panels do
		each.BackgroundTransparency = transparency
	end
end

local function look(panel: Panel, card: Card): string
	local state = Button.State(card.Button)
	if panel.Lit == card.Def.Name and os.clock() < panel.LitUntil then
		return "Pressed"
	elseif state == "Pressed" or state == "Waiting" then
		return "Pressed"
	end
	return "Rest"
end

local function paint(card: Card, now: string)
	card.Press.Visible = now == "Pressed"
	card.Button:SetAttribute("Look", now)
	card.Shown = now
end

-- A card's press: lit for Lit, then the panel makes way as its screen rises over it, RiseAt in.
local function step(panel: Panel, name: string)
	local press = panel.Presses[name]
	if press == nil then
		return
	end
	if not panel.Open then -- pressed with the panel away (Button.Press, for tests): its screen, with no step and no way back
		press()
		return
	end
	local s = HOME.Step
	panel.Lit, panel.LitUntil = name, os.clock() + s.Lit
	task.delay(s.Lit, function()
		HomePanel.Close(panel, s.LeaveTo, s.Leave)
		task.delay(s.RiseAt, function()
			Screen.Rise({ From = s.RiseFrom, Seconds = s.Rise, Cover = s.Cover, Sink = s.Sink, Uncover = s.Uncover })
			press()
			Screen.Rise(nil) -- spent, or left unspent when nothing opened
			panel.From = Screen.Current()
		end)
	end)
end

function HomePanel.new(cover: Instance, hud: GuiObject, foot: number, presses: { [string]: () -> () }, lead: GuiObject?): Panel
	local size = HOME.Size
	local frame = Instance.new("Frame")
	frame.Name = "HomePanel"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = whole(size.X, size.Y)
	frame.ZIndex = 61 -- over its dim
	frame.Active = true -- a tap on the glass stays on it
	frame.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local zero = Vector2.zero
	local glass = lay(frame, HOME.Glass, zero, 1)
	local pointer = lay(frame, HOME.Pointer, zero, 1)
	pointer.Name = "Pointer"
	local dim = Instance.new("Frame")
	dim.Name = "HomeDim"
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 60 -- over a screen's cover, should one still be fading
	dim.Visible = false
	dim.Parent = cover
	local panels: { TextButton } = {}
	for _, name in { "Top", "Foot", "Left", "Right" } do
		local each = Instance.new("TextButton")
		each.Name = name
		each.Text = ""
		each.AutoButtonColor = false
		each.BorderSizePixel = 0
		each.BackgroundColor3 = HOME.Dim.Colour
		each.BackgroundTransparency = 1
		each.Parent = dim
		table.insert(panels, each)
	end
	local panel: Panel = {
		Frame = frame,
		Scale = scale,
		Glass = { glass, pointer },
		Pointer = pointer,
		Dim = dim,
		Panels = panels,
		Dimmed = 1,
		Hud = hud,
		Foot = foot,
		Lead = lead,
		Laid = "",
		Cards = {},
		Presses = presses,
		Open = false,
		Shown = 0,
		Motion = nil,
		Lit = nil,
		LitUntil = 0,
		From = nil,
		Live = nil,
		LeadDef = nil,
	}
	for _, each in HOME.Cards do
		local def = each :: Def
		local tap = def.Tap
		local origin = Vector2.new(tap[1], tap[2])
		local button = Button.new({
			Name = def.Name,
			Text = "",
			Bare = true,
			Size = whole(tap[3], tap[4]),
			Position = whole(tap[1], tap[2]),
			Parent = frame,
			OnPress = function()
				step(panel, def.Name)
			end,
		})
		button.ZIndex = def.Z
		-- Its art in one holder in the button's face, so the face's squeeze takes it all and the landing moves it as one.
		local holder = Instance.new("Frame")
		holder.Name = "Card"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(1, 1)
		holder.Parent = Skin.Of(button)
		local lit: { ImageLabel } = {}
		local z = 1
		local press: ImageLabel? = nil
		for index, laid in def.Images do
			local image = lay(holder, laid, origin, z)
			if laid[6] == "Lit" then
				table.insert(lit, image)
			end
			z += 1
			if index == 1 and def.Over then -- Voidkin's press lies over its ground, under the glow and the live view
				press = lay(holder, def.Press, origin, z)
				z += 1
			end
		end
		holder:SetAttribute("Live", z) -- where the live view goes
		z += 1
		for _, laid in def.Over or {} do
			local image = lay(holder, laid, origin, z)
			if laid[6] == "Lit" then
				table.insert(lit, image)
			end
			z += 1
		end
		if press == nil then -- the others' presses lie over their art
			press = lay(holder, def.Press, origin, z)
			z += 1
		end
		local pressed = press :: ImageLabel
		pressed.Name = "Press"
		pressed.Visible = false
		if def.Press[6] == "Lit" then
			table.insert(lit, pressed)
		end
		if def.Mark then
			local mark = def.Mark
			local record = UIKit.Images[mark[1]]
			local image = Instance.new("ImageLabel")
			image.Name = "Mark"
			image.BackgroundTransparency = 1
			image.Image = record.Id
			image.ImageColor3 = mark[5]
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Position = whole(mark[2] - origin.X, mark[3] - origin.Y)
			image.Size = whole(mark[4], mark[4])
			image.ZIndex = z
			image:SetAttribute("Kit", mark[1])
			image.Parent = holder
			z += 1
		end
		for _, spec in def.Words do
			word(holder, spec, origin, z)
		end
		local card: Card = { Def = def, Button = button, Holder = holder, Press = pressed, Lit = lit, Shown = "" }
		panel.Cards[def.Name] = card
		paint(card, look(panel, card))
	end
	frame.Parent = cover
	for _, each in panels do
		each.Activated:Connect(function()
			HomePanel.Close(panel)
		end)
	end
	-- A card's screen closed by its Back brings the panel back, BackAt after the screen begins to sink.
	Screen.Closed:Connect(function(name: string, how: string?)
		if panel.From ~= name then
			return
		end
		panel.From = nil
		if how == "Back" then
			task.delay(HOME.Step.BackAt, function()
				if Screen.Current() == nil then
					HomePanel.Open(panel)
				end
			end)
		end
	end)
	return panel
end

-- The lead shown live in the Voidkin card, on its rarity's light (Card.Trim lifted Lift toward white).
function HomePanel.Lead(panel: Panel, def: string?)
	if def == panel.LeadDef then
		return
	end
	panel.LeadDef = def
	if panel.Live then
		panel.Live.View:Destroy()
		panel.Live = nil
	end
	local card = panel.Cards.Voidkin
	if def == nil or card == nil then
		return
	end
	local row = Voidkin.ById[def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or WHITE
	local light = trim:Lerp(WHITE, HOME.Lift)
	for _, image in card.Lit do
		image.ImageColor3 = light
	end
	local live = HOME.Live
	local bust = Figure.Bust(def, light, live :: any)
	if bust == nil then
		return
	end
	local tap = card.Def.Tap
	bust.View.Position = whole(live.Box[1] - tap[1], live.Box[2] - tap[2])
	bust.View.Size = whole(live.Box[3], live.Box[4])
	bust.View.ZIndex = card.Holder:GetAttribute("Live") :: number
	bust.View.Parent = card.Holder
	panel.Live = bust
end

function HomePanel.Open(panel: Panel)
	if panel.Open then
		return
	end
	panel.Open = true
	panel.Lit = nil
	place(panel)
	panel.Frame.Visible = true
	panel.Frame.Interactable = true
	panel.Dim.Visible = true
	panel.Dim.Interactable = true
	panel.Motion = { At = os.clock(), Opening = true, From = HOME.Open.From, To = 1, Seconds = HOME.Open.Grow, Seen = panel.Shown, DimFrom = panel.Dimmed, DimTo = 1 - HOME.Dim.Amount }
	HomePanel.Paint(panel)
end

-- It leaves to `to` of its size (Home.Open.LeaveTo) in `seconds` (Home.Open.Leave), eased in, all at once.
function HomePanel.Close(panel: Panel, to: number?, seconds: number?)
	if not panel.Open then
		return
	end
	panel.Open = false
	panel.Frame.Interactable = false
	panel.Dim.Interactable = false -- taps pass through it at once
	panel.Motion = {
		At = os.clock(),
		Opening = false,
		From = panel.Scale.Scale,
		To = to or HOME.Open.LeaveTo,
		Seconds = seconds or HOME.Open.Leave,
		Seen = panel.Shown,
		DimFrom = panel.Dimmed,
		DimTo = 1,
		Done = function()
			panel.Frame.Visible = false
			panel.Dim.Visible = false
		end,
	}
	HomePanel.Paint(panel)
end

function HomePanel.Shown(panel: Panel): boolean
	return panel.Open
end

function HomePanel.Holds(panel: Panel): boolean
	return panel.From ~= nil and Screen.Current() == panel.From
end

-- How much of a HUD piece the panel hides now: what shows of the glass, when the piece's rect meets the glass's.
function HomePanel.Covers(panel: Panel, piece: GuiObject): number
	if panel.Shown <= 0 or not panel.Frame.Visible then
		return 0
	end
	local a0, a1 = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
	local b0, b1 = panel.Frame.AbsolutePosition, panel.Frame.AbsolutePosition + panel.Frame.AbsoluteSize
	if a0.X < b1.X and a1.X > b0.X and a0.Y < b1.Y and a1.Y > b0.Y then
		return panel.Shown
	end
	return 0
end

function HomePanel.Paint(panel: Panel)
	local motion = panel.Motion
	if motion then
		local open = HOME.Open
		local t = os.clock() - motion.At
		local d = math.clamp(t / HOME.Dim.Seconds, 0, 1)
		local finished: boolean
		if motion.Opening then
			local grow = math.clamp(t / open.Grow, 0, 1)
			local fade = math.clamp(t / open.Fade, 0, 1)
			panel.Scale.Scale = motion.From + (motion.To - motion.From) * backOut(grow, open.Back)
			panel.Shown = motion.Seen + (1 - motion.Seen) * (1 - (1 - fade) ^ 2)
			dimmed(panel, motion.DimFrom + (motion.DimTo - motion.DimFrom) * (1 - (1 - d) ^ 2))
			local last = 0
			for index, name in open.Order do
				local card = panel.Cards[name]
				local u = math.clamp((t - (index - 1) * open.Stagger) / open.Land, 0, 1)
				local eased = 1 - (1 - u) ^ 3
				if card then
					card.Holder.Position = UDim2.fromOffset(0, math.round(open.Rise * (1 - eased)))
					Fade.Set(card.Holder, eased)
				end
				last = math.max(last, u)
			end
			finished = grow >= 1 and fade >= 1 and d >= 1 and last >= 1
		else
			local share = math.clamp(t / math.max(motion.Seconds, 1e-3), 0, 1)
			panel.Scale.Scale = motion.From + (motion.To - motion.From) * share * share
			panel.Shown = motion.Seen * (1 - share * share)
			dimmed(panel, motion.DimFrom + (motion.DimTo - motion.DimFrom) * d * d)
			for _, card in panel.Cards do
				Fade.Set(card.Holder, math.min(Fade.Of(card.Holder), panel.Shown))
			end
			finished = share >= 1 and d >= 1
		end
		for _, image in panel.Glass do
			Fade.Set(image, panel.Shown)
		end
		if finished then
			panel.Motion = nil
			if motion.Done then
				motion.Done()
			end
		end
	end
	if not panel.Frame.Visible then
		return
	end
	if panel.Open and Screen.Current() ~= nil then -- a screen opened another way (the Map's menu): it makes way
		HomePanel.Close(panel)
	end
	place(panel)
	for _, card in panel.Cards do
		local now = look(panel, card)
		if now ~= card.Shown then
			paint(card, now)
		end
	end
end

return HomePanel
