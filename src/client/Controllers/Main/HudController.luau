--!strict
-- HudController (client): the HUD in the world, on Modulo's kit (docs/ui.md, "The HUD, in the world"; TR3). Top left,
-- the lead's card (UI.LeadCard): the portrait in its rarity's frame, the head over it and the level on a badge, the name
-- on its tab with the class mark, the type's stud, a long health light with current and maximum inside, a thin
-- experience light; fallen, the portrait dims and the health says the seconds until it's back. Top centre, the target's
-- card (UI.TargetCard), built like the lead's, only in a fight: its stud and gem, the type edge's arrow before the first
-- hit, its name and level on its tab, its health light. Top right, two pills: Credits, and Electricity stored
-- over its cap with the rate and a thread of charge. Right edge, low, the signature's ring: it fills over the cooldown
-- and flashes when it fires. Bottom centre, the dock: Voidkin and Base, selected while their screen is open, and the
-- chip over it while a shard waits. Everything reads the fighters' attributes (FightService) or the save's copy
-- (ProfileController); nothing here decides anything. The Voidkin screen lists the collection and makes a lead.
-- A keeper's try and an elite take their own HUD (TR5's grey variants, Config.Hud.Boss): the keeper's title card
-- (UI.BossBar) at the foot or the top in the target card's stead, and an elite's heavier frame on the target card.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local EffectsConfig = require(Shared.Config.Effects)
local HudConfig = require(Shared.Config.Hud)
local Combat = require(Shared.Config.Combat)
local UIKit = require(Shared.Config.UIKit)
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local Voidkin = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local Growth = require(Shared.Rules.Growth)
local Hud = require(Shared.Rules.Hud)
local Markers = require(Shared.World.Markers)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local World = require(UI.World)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Skin = require(UI.Kit.Skin)
local RingLooks = require(UI.RingLooks)
local LeadCard = require(UI.LeadCard)
local VoidkinScreen = require(UI.VoidkinScreen)
local TargetCard = require(UI.TargetCard)
local BossBar = require(UI.BossBar)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Pop = require(UI.Kit.Pop)
local Fly = require(UI.Kit.Fly)
local Count = require(UI.Kit.Count)
local Burst = require(UI.Kit.Burst)
local Fade = require(UI.Kit.Fade)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local SpectateController = require(script.Parent.SpectateController)
local Effects = require(script.Parent.FighterController.Effects)
local FadeController = require(script.Parent.FadeController)

local HudController = {}

local player = Players.LocalPlayer
local GRAPHITE = UIKit.Palettes.Graphite
local PAD = Theme.Size.Pad
-- The cards and the pills fit the smallest phone (Theme.Smallest at the scale's floor, 668 authored across) side by side:
-- the lead's 8 to 220, the target's centred from 226 to 442, the Electricity pill from 460 (the UI lint's overlap check).
-- The lead's card is UI.LeadCard (the director's pick of 2026-11-13: Midnight, the Ember lights, the head over the frame).
-- The top row's one line, the lead card's, the target's and the pills': the lead card's highest art (a head, a Mythical
-- frame's crest) stands 6 points under its top, so it clears Roblox's top bar by more than the 5.5 authored px research's
-- pass on TR3's fix round asked of the crest (call 1).
local TOP = 17
local ELECTRICITY = 200 -- the Electricity pill's width: "600 / 600" and the rate, or "full"
local PILL = 30 -- a pill's height (tools/blender/ui_kit.py, `pill`)
local BASE_EVERY = 0.25 -- seconds between reads of the base as it stands now: each copies the save
local SMOOTH = 12 -- frames in a row under 1/30 s before the join's black lifts: a join's stall leaves text undrawn a moment
local DOCK = Vector2.new(96, Theme.Size.Tap)
local WELL = 0.25 -- the signature ring's well, its transparency shown

type Ring = {
	Frame: Frame,
	Halves: { UIGradient },
	Glyph: ImageLabel,
	Flash: UIStroke,
	Scale: UIScale,
	Well: Frame,
	Strokes: { UIStroke }, -- the channel and the two halves' light, faded with the ring
	Ready: number, -- the server's Ready we last saw
	FiredAt: number, -- os.clock() of the last flash
	ReadyAt: number, -- os.clock() it last became ready
	Full: boolean,
	FoughtAt: number, -- os.clock() the lead last had a target
	Seen: number, -- 0 hidden to 1 shown: it fades in as a fight starts, out a moment after it ends
	InPlace: { [string]: RingLooks.Look }, -- TR13's looks in the ring's place, made when first picked
	Beside: { [string]: RingLooks.Look }, -- and beside it, for the comparison
}

local lead: LeadCard.Card
local target: TargetCard.Card
local targetArrow: Frame
local credits: TextLabel
local coin: ImageLabel -- the Credits pill's icon, where a kill's Credits fly to (TR6)
local electricity: TextLabel
local bolt: ImageLabel -- the Electricity pill's, where the battery's jump flies to
local rate: TextLabel
local charge: Frame
local chip: Frame
local chipText: TextLabel
local ring: Ring
local eye: TextButton -- the spectate toggle (TR11)
local nextButton: TextButton -- under a fallen lead's card: sends out the next (TR12)
local dock: { [string]: TextButton } = {}
local dockHolder: Frame
local keeperBar: BossBar.Bar
local lastView: Profile.View? = nil
local glint: Frame -- experience's pop: a light over the thread's
local lastStored: number? = nil -- the battery at the last read, for its jump
local baseReadAt = 0
local seen: { [string]: { Share: number, Over: number } } = {} -- the top band's pieces over a keeper: each one's fade
local opacities: { [string]: number } = {} -- each piece's opacity now, by name: for tests

local function fighters(): { Instance }
	local folder = workspace:FindFirstChild("Fighters")
	return if folder then folder:GetChildren() else {}
end

local function myLead(): Model?
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function fighterById(id: string): Model?
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

-- A fighter's type and class from its definition: a Voidkin's, or an enemy's (which has a type and no class).
local function kindOf(model: Model): (string, string)
	local def = tostring(model:GetAttribute("Def") or "")
	local row = Voidkin.ById[def]
	if row then
		return row.Type, row.Class
	end
	local enemy = Enemies.ById[def]
	local typed = model:GetAttribute("Type")
	return (if type(typed) == "string" then typed elseif enemy then enemy.Type else ""), ""
end

local function icon(holder: GuiObject, name: string, cx: number, cy: number, size: number): ImageLabel
	local image = Skin.Icon(holder, name, cx, cy, size, nil, 2)
	return image
end

-- Swaps an icon's picture to another of the kit's, keeping its place and size.
local function swap(image: ImageLabel, name: string)
	local im = UIKit.Images[name]
	if im and image:GetAttribute("Kit") ~= name then
		image.Image = im.Id
		image:SetAttribute("Kit", name)
	end
end

-- The type edge's arrow: a chevron of two strokes, up or down (Rules.Hud.Arrow).
local function arrow(parent: Instance, cx: number, cy: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Arrow"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(12, 12)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromOffset(cx, cy)
	holder.ZIndex = 2
	for side = -1, 1, 2 do
		local stroke = Instance.new("Frame")
		stroke.Name = if side < 0 then "Left" else "Right"
		stroke.BorderSizePixel = 0
		stroke.AnchorPoint = Vector2.new(0.5, 0.5)
		stroke.Size = UDim2.fromOffset(8, 2.5)
		stroke.Position = UDim2.new(0.5, side * 2.6, 0.5, 0)
		stroke.ZIndex = 2
		stroke.Parent = holder
	end
	holder:SetAttribute("Way", "")
	holder.Visible = false
	holder.Parent = parent
	return holder
end

local function point(holder: Frame, way: string)
	if holder:GetAttribute("Way") == way then
		return
	end
	holder:SetAttribute("Way", way)
	holder.Visible = way ~= ""
	local colour = if way == "Up" then HudConfig.Arrow.Up else HudConfig.Arrow.Down
	for _, stroke in holder:GetChildren() do
		if stroke:IsA("Frame") then
			local left = stroke.Name == "Left"
			-- Up: /\ ; down: \/
			stroke.Rotation = if (way == "Up") == left then -45 else 45
			stroke.Position = UDim2.new(0.5, (if left then -1 else 1) * 2.6, 0.5, 0)
			stroke.BackgroundColor3 = colour
		end
	end
end

-- A pill (tools/blender/ui_kit.py, `pill`): its icon, its value, what's after it in soft ink, and for electricity a thread.
local function pill(name: string, order: number, width: number, image: string): (TextLabel, TextLabel, Frame?, ImageLabel)
	local frame = Panel.new({
		Name = name,
		Size = UDim2.fromOffset(width, PILL),
		Position = UDim2.new(1, -PAD, 0, TOP + (order - 1) * (PILL + Theme.Size.Gap)),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Layers.Get("Hud"),
	})
	local mark = icon(frame, image, 17, PILL / 2, 21)
	local threaded = name == "Electricity"
	local up = if threaded then -2 else 0
	local value = Text.new({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Box = UDim2.fromOffset(width - 33 - 8, PILL), Position = UDim2.fromOffset(31, up), Parent = frame })
	local extra = Text.new({ Name = "Extra", Size = Theme.Text.Caption, Colour = GRAPHITE.Soft, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(80, PILL), Position = UDim2.new(1, -10, 0, up), AnchorPoint = Vector2.new(1, 0), Parent = frame })
	local thread = if threaded then Bar.new({ Name = "Charge", Size = UDim2.fromOffset(width - 40, 3), Position = UDim2.fromOffset(31, PILL - 8), Colour = UIKit.Charge, Parent = frame }) else nil
	-- Shown once it has something to say: at a join the save's copy comes a moment after the HUD (TR2's rejoin take).
	frame.Visible = false
	value:GetPropertyChangedSignal("Text"):Connect(function()
		frame.Visible = value.Text ~= ""
	end)
	Pop.Centre(frame) -- it swells in place
	return value, extra, thread, mark
end

-- A reward won into a pill (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN 3): from `from` (on the HUD layer,
-- or nil when it came from nowhere on screen) its icons fly to the pill's, and as the first lands its number starts
-- counting, the pill pops at Fly's rung and its "+N" rises. With nowhere to fly from, the number counts and the pill
-- pops at once, at its own rung.
local function reward(value: TextLabel, mark: ImageLabel, from: Vector2?, image: string, old: number, new: number, format: (number) -> string, rung: number, tint: Color3, gainFormat: (number) -> string)
	local pillFrame = value.Parent :: GuiObject
	local won = new - old
	Count.Run(value, old, new, format, from ~= nil)
	local function land(fly: boolean)
		Count.Start(value)
		Pop.Play(pillFrame, if fly then HudConfig.Pop.Rungs.Fly else rung)
		Pop.Gain(pillFrame, won, tint, gainFormat)
	end
	local flown = if from then Fly.Send(from, mark, image, won, function(i: number)
		if i == 1 then
			land(true)
		end
	end) else 0
	if flown == 0 then
		land(false)
	end
end

-- The signature's ring: a channel round the class's glyph, and two halves of light that fill it clockwise from the top.
local function signatureRing(): Ring
	local config = HudConfig.Ring
	local frame = Instance.new("Frame")
	frame.Name = "Signature"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(config.Size, config.Size)
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.new(1, -PAD - 6, 0.6, 0)
	frame.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local function circle(name: string, colour: Color3, z: number): (Frame, UIStroke)
		local disc = Instance.new("Frame")
		disc.Name = name
		disc.BackgroundTransparency = 1
		disc.Size = UDim2.fromScale(1, 1)
		disc.ZIndex = z
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = disc
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = colour
		stroke.Thickness = config.Weight
		stroke.Parent = disc
		return disc, stroke
	end
	local well, channel = circle("Well", GRAPHITE.Channel, 1)
	well.BackgroundColor3 = GRAPHITE.Well
	well.BackgroundTransparency = WELL
	well.Parent = frame
	local strokes = { channel }
	local halves = {}
	for side = 0, 1 do
		local clip = Instance.new("Frame")
		clip.Name = if side == 0 then "LeftHalf" else "RightHalf"
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(0.5, 1)
		clip.Position = UDim2.fromScale(side * 0.5, 0)
		clip.ZIndex = 2
		local disc, stroke = circle("Light", GRAPHITE.Accent, 2)
		disc.Size = UDim2.fromScale(2, 1)
		disc.Position = UDim2.fromScale(-side, 0)
		local gradient = Instance.new("UIGradient")
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.501, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = stroke
		table.insert(strokes, stroke)
		disc.Parent = clip
		clip.Parent = frame
		table.insert(halves, gradient)
	end
	local _, flash = circle("Flash", Color3.new(1, 1, 1), 4)
	flash.Thickness = config.Weight * 2
	flash.Transparency = 1
	;(flash.Parent :: Frame).Parent = frame
	local glyph = Skin.Icon(frame, "ClassWarriorGlyph", config.Size / 2, config.Size / 2, config.Size * 0.5, GRAPHITE.Text, 3)
	glyph.Name = "Glyph"
	frame.Parent = Layers.Get("Hud")
	return {
		Frame = frame,
		Halves = halves,
		Glyph = glyph,
		Flash = flash,
		Scale = scale,
		Well = well,
		Strokes = strokes,
		Ready = 0,
		FiredAt = -math.huge,
		ReadyAt = -math.huge,
		Full = true,
		FoughtAt = -math.huge,
		Seen = 0,
		InPlace = {},
		Beside = {},
	}
end

-- TR13's looks in grey (UI.RingLooks): the one picked in the ring's place, today's ring hidden under it; and, with Beside,
-- the three in a row left of the ring, on the same state, each with its name.
local function ringLooks(state: RingLooks.State): boolean
	local config = HudConfig.Ring
	local pick = tostring(config.Look)
	local current = not RingLooks.Has(pick)
	for _, child in ring.Frame:GetChildren() do
		if child:IsA("GuiObject") and child:GetAttribute("Look") == nil then
			child.Visible = current
		end
	end
	for _, name in RingLooks.Names do
		local look = ring.InPlace[name]
		if name == pick and look == nil then
			look = RingLooks.new(name, config.Size, config.Weight, ring.Frame, false)
			ring.InPlace[name] = look
		end
		if look then
			look.Frame.Visible = name == pick
			if name == pick then
				RingLooks.Step(look, state)
			end
		end
	end
	for index, name in RingLooks.Names do
		local look = ring.Beside[name]
		if config.Beside == true and look == nil then
			look = RingLooks.new(name, config.Size, config.Weight, Layers.Get("Hud"), true)
			ring.Beside[name] = look
		end
		if look then
			look.Frame.AnchorPoint = ring.Frame.AnchorPoint
			look.Frame.Position = ring.Frame.Position - UDim2.fromOffset(index * (config.Size + config.Gap), 0)
			look.Frame.Visible = config.Beside == true and ring.Frame.Visible
			if look.Frame.Visible then
				RingLooks.Step(look, state)
			end
		end
	end
	return current
end

-- The spectate toggle (TR11; Config.Hud.Spectate): a small eye beside the signature's ring, a whole tap target, lit while
-- it's on. In grey: the kit's button with an eye of a stroked almond and its pupil; the finished look waits for TR13's
-- frames. A tap turns it on or off (SpectateController).
local EYE_PLACES: { [string]: (number, number, number, number) -> UDim2 } = {
	Above = function(ring: number, size: number, gap: number, edge: number): UDim2
		return UDim2.new(1, -edge - ring / 2, 0.6, -(ring / 2 + gap + size / 2))
	end,
	Left = function(ring: number, size: number, gap: number, edge: number): UDim2
		return UDim2.new(1, -edge - ring - gap - size / 2, 0.6, 0)
	end,
	Below = function(ring: number, size: number, gap: number, edge: number): UDim2
		return UDim2.new(1, -edge - ring / 2, 0.6, ring / 2 + gap + size / 2)
	end,
}

local function placeEye()
	local look = HudConfig.Spectate
	local place = EYE_PLACES[tostring(look.Place)] or EYE_PLACES.Above
	eye.Position = place(HudConfig.Ring.Size, look.Size, look.Gap, PAD + 6) -- the ring's own edge (signatureRing)
	eye.Size = UDim2.fromOffset(look.Size, look.Size)
	eye:SetAttribute("Place", tostring(look.Place))
end

local function eyeButton(): TextButton
	local look = HudConfig.Spectate
	local button = Button.new({
		Name = "Spectate",
		Text = "",
		Size = UDim2.fromOffset(look.Size, look.Size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = Layers.Get("Hud"),
		OnPress = function()
			SpectateController.Set(not SpectateController.On())
		end,
	})
	local skin = Skin.Of(button) -- in the face, so it squeezes with it
	local almond = Instance.new("Frame")
	almond.Name = "Eye"
	almond.BackgroundTransparency = 1
	almond.AnchorPoint = Vector2.new(0.5, 0.5)
	almond.Position = UDim2.fromScale(0.5, 0.5)
	almond.Size = UDim2.fromOffset(24, 14)
	almond.ZIndex = 12
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = almond
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Lid"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	stroke.Color = GRAPHITE.Text
	stroke.Parent = almond
	local pupil = Instance.new("Frame")
	pupil.Name = "Pupil"
	pupil.BackgroundColor3 = GRAPHITE.Text
	pupil.AnchorPoint = Vector2.new(0.5, 0.5)
	pupil.Position = UDim2.fromScale(0.5, 0.5)
	pupil.Size = UDim2.fromOffset(8, 8)
	pupil.ZIndex = 13
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = pupil
	pupil.Parent = almond
	almond.Parent = skin
	SpectateController.Changed:Connect(function(on: boolean)
		Button.Set(button, { Selected = on })
		local ink = if on then GRAPHITE.Accent else GRAPHITE.Text
		stroke.Color = ink
		pupil.BackgroundColor3 = ink
		button:SetAttribute("On", on)
	end)
	button:SetAttribute("On", false)
	return button
end

-- How full the ring is, 0 to 1: the right half, then the left (each half's gradient turns its light in).
local function fillRing(share: number)
	local a = math.clamp(share * 360, 0, 180)
	local b = math.clamp(share * 360 - 180, 0, 180)
	ring.Halves[1].Rotation = 180 + b -- the left half
	ring.Halves[2].Rotation = a -- the right half
	ring.Frame:SetAttribute("Share", share)
end

-- The ring shows only in a fight (TR3's verdict, fix 5): it fades in as the lead takes a target, and out a moment after it
-- has none. Hidden, it still follows the cooldown, so it shows the truth the moment it fades in.
local function stepRing(model: Model?, fighting: boolean, dt: number)
	local cooldown = if model then model:GetAttribute("Cooldown") else nil
	local config = HudConfig.Ring
	local now = os.clock()
	local can = model ~= nil and type(cooldown) == "number" and cooldown > 0 and lead.Frame.Visible
	if can and fighting then
		ring.FoughtAt = now
	end
	local want = can and now - ring.FoughtAt <= config.Linger
	local by = dt / math.max(if want then config.FadeIn else config.FadeOut, 1e-3)
	ring.Seen = if can then math.clamp(ring.Seen + (if want then by else -by), 0, 1) else 0
	ring.Frame.Visible = ring.Seen > 0
	ring.Frame:SetAttribute("Seen", ring.Seen)
	for _, look in ring.Beside do -- TR13's comparison goes with the ring
		look.Frame.Visible = look.Frame.Visible and ring.Frame.Visible
	end
	if not can or model == nil then
		return
	end
	local seen = ring.Seen
	local function faded(transparency: number): number
		return 1 - (1 - transparency) * seen
	end
	local readyAt = model:GetAttribute("Ready")
	local ready = if type(readyAt) == "number" then readyAt else 0
	if ready > ring.Ready + 1e-3 then
		ring.FiredAt = now -- it fired: the server set when it's ready again
	end
	ring.Ready = ready
	local share = Hud.Ready(ready, cooldown :: number, workspace:GetServerTimeNow())
	local full = share >= 1
	if full and not ring.Full then
		ring.ReadyAt = now
	end
	ring.Full = full
	fillRing(share)
	local _, class = kindOf(model)
	if class ~= "" then
		swap(ring.Glyph, `Class{class}Glyph`)
	end
	ring.Glyph.ImageTransparency = faded(if full then 0 else 0.55)
	ring.Well.BackgroundTransparency = faded(WELL)
	for _, stroke in ring.Strokes do
		stroke.Transparency = faded(0)
	end
	local since = now - ring.FiredAt
	local flash = if since < config.Flash then 1 - since / config.Flash else 0
	ring.Flash.Transparency = faded(1 - flash)
	local swell = now - ring.ReadyAt
	local back = if swell < config.Ready then math.sin(math.pi * swell / config.Ready) else 0
	local current = ringLooks({ Share = share, Full = full, Flash = flash, Swell = back, Since = if full then swell else math.huge, Seen = seen, Class = class })
	ring.Scale.Scale = if current then 1 + 0.25 * flash + 0.12 * back else 1 -- a look swells on its own
	ring.Frame:SetAttribute("Flash", flash)
end

-- A fallen Voidkin's Id to the server time it's whole (LeadService's "Healing"), or empty.
local function healing(): { [string]: number }
	local text = player:GetAttribute("Healing")
	if type(text) ~= "string" or text == "" then
		return {}
	end
	local ok, map = pcall(function(): any
		return HttpService:JSONDecode(text)
	end)
	return if ok and type(map) == "table" then map else {}
end

-- Whether the player owns a Voidkin besides the lead, to send out when it falls.
local function ownsAnother(): boolean
	local view = ProfileController.Get()
	local count = 0
	for _ in (if view then view.Voidkin else {}) do
		count += 1
		if count > 1 then
			return true
		end
	end
	return false
end

-- The Voidkin screen (UI/VoidkinScreen): the collection, the lead set out of combat (TR12), and each one's stat board
-- (TR15).
local function voidkinScreen()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	VoidkinScreen.Open(view, { Act = ProfileController.Act, Healing = healing })
end

local function avatarAt(): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	return if root and root.Parent then root.Position else nil
end

-- Where a shard just won leaps from: the nearest fallen Shade to the avatar, within ShardLeap.From.
local function fallenNear(): Vector3?
	local at = avatarAt()
	local best: Vector3? = nil
	local bestGap = EffectsConfig.ShardLeap.From
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("State") == "Down" and at then
			local where = model:GetPivot().Position
			local gap = (where - at).Magnitude
			if gap < bestGap then
				best, bestGap = where, gap
			end
		end
	end
	return best
end

-- Whether the avatar stands on its own plot.
local function atHome(): boolean
	local plot = player:GetAttribute("Plot")
	return Markers.OnPlot(if type(plot) == "number" then plot else nil, avatarAt())
end

-- The chip over the dock while the bag holds a shard: the hook home stays in view until it's in the Breaker, and names
-- the step that's next: in the field "break it at home", at home "into the Breaker" (research's verdict on TR2 and its
-- read of the fixes, 2026-11-12).
-- This try's keeper: the one nearest the avatar, in its own copy of the ring (KeeperService), while the avatar is in a try.
local function keeperNear(): Model?
	if player:GetAttribute("Try") == nil then
		return nil
	end
	local at = avatarAt()
	local best: Model?, nearest = nil, math.huge
	for _, model in fighters() do
		if model:IsA("Model") and model:GetAttribute("Kind") == "Keeper" then
			local distance = if at then (model:GetPivot().Position - at).Magnitude else 0
			if distance < nearest then
				best, nearest = model, distance
			end
		end
	end
	return if nearest <= Combat.Keeper.Notice then best else nil
end

local function showChip(view: Profile.View)
	local kinds, total, first = 0, 0, nil :: string?
	for shard, count in view.Bag.Shards do
		if count > 0 then
			kinds += 1
			total += count
			first = first or shard
		end
	end
	chip.Visible = total > 0
	if first then
		local home = atHome()
		local step = if home then "into the Breaker" elseif total == 1 then "break it at home" else "break them at home"
		chipText.Text = if kinds == 1 and total == 1 then `{Read.ShardName(first)}: {step}` else `{total} shards: {step}`
	end
end

-- What changed since the last copy, said once: a shard gained (it leaps to the avatar), a level gained.
local function notice(old: Profile.View?, new: Profile.View)
	if old == nil then
		return
	end
	for shard, count in new.Bag.Shards do
		local gained = count - (old.Bag.Shards[shard] or 0)
		if gained > 0 then
			Toast.Show(`+{gained} {Read.ShardName(shard)}`, Theme.Colour.Ready)
			Effects.ShardLeap(fallenNear(), avatarAt)
		end
	end
	local pops = HudConfig.Pop.Rungs
	if new.Currency.Credits > old.Currency.Credits then
		-- A kill's Credits fly from where it fell (TR6); any other win pops at once.
		local fell = fallenNear()
		reward(credits, coin, if fell then Fly.From(fell) else nil, "Coin", old.Currency.Credits, new.Currency.Credits, Read.Number, pops.Credits, HudConfig.Card.Level, Read.Number)
	end
	local id = new.Roles.Lead
	local was, now = old.Voidkin[id], new.Voidkin[id]
	if was and now and (now.Level > was.Level or now.Xp > was.Xp) then
		Pop.Play(glint, pops.Xp, { Swell = false, Paint = function(p: number)
			local share = lead.Xp:GetAttribute("Share")
			glint.Visible = p > 0
			glint.Size = UDim2.fromScale(if type(share) == "number" then share else 0, 1)
			glint.BackgroundTransparency = 1 - HudConfig.Pop.Glow * p
		end })
	end
	if was and now and now.Level > was.Level then
		Toast.Show(`{Read.VoidkinName(now)} reached level {now.Level}`, HudConfig.Card.Xp)
		Pop.Play(lead.Level, pops.Level, { Paint = function(p: number)
			lead.Level.TextColor3 = HudConfig.Card.Level:Lerp(Color3.new(1, 1, 1), HudConfig.Pop.Glow * p)
		end })
		Burst.Play(Fly.Middle(lead.Level), HudConfig.Card.Level) -- rung 5: sparks off the badge (TR6)
	end
end

local function showView(view: Profile.View)
	Count.Show(credits, view.Currency.Credits, Read.Number) -- a count under way heads there
	showChip(view)
	local owned = 0
	for _ in view.Voidkin do
		owned += 1
	end
	Button.Set(dock.Voidkin, { Disabled = Hud.VoidkinReason(owned) or false })
	if Screen.Current() == "Voidkin" then
		voidkinScreen()
	end
end

local function healthOf(model: Model): (number, number)
	local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
	return (if type(health) == "number" then health else 0), (if type(most) == "number" then most else 0)
end

-- A card's health: its share on its light, current and most inside, set tight (UI.LeadCard; the target's card is built
-- like the lead's, UI.TargetCard).
local function showHealth(bar: Frame, label: TextLabel, model: Model)
	local health, most = healthOf(model)
	LeadCard.Fill(bar, if most > 0 then health / most else 0)
	-- Too wide for its bar, it takes its compact form (TR3's verdict, fix 6: the dummy's 1,254,735 crowded its bar): the
	-- characters its share of the bar holds, a digit's width each (Config.Hud.Card.Room).
	local inset = bar:GetAttribute("Inset")
	local shown = bar.Size.X.Offset - (if type(inset) == "number" then inset else 0)
	local room = math.floor(shown * HudConfig.Card.Room / (label.TextSize * HudConfig.Numbers.Digit))
	label.Text = Hud.Health(health, most, room, true)
end

-- The top band's lower edge for the world's numbers (UI.World.Band): the lowest of the cards and the pills that show,
-- plus the margin, in the World layer's authored pixels (TR3's verdict, fix 4: numbers stay below the top band). And each
-- piece's own span, its margin all round, a toast stack's while it shows, and the top bar's foot: an open plate, the
-- level-up's word, stands clear of only what it crosses (research's pass on AR8 C, fix 1).
local banded: { GuiObject } = {}
local function band()
	local world = Layers.Get("World")
	local origin, scale, margin = world.AbsolutePosition, Layers.Scale(), HudConfig.Numbers.Band
	local function span(frame: GuiObject): World.Span
		local at, size = frame.AbsolutePosition - origin, frame.AbsoluteSize
		return { Left = at.X / scale - margin, Right = (at.X + size.X) / scale + margin, Edge = (at.Y + size.Y) / scale + margin }
	end
	local lowest: number? = nil
	local spans: { World.Span } = {}
	for _, frame in banded do
		if frame.Visible then
			local piece = span(frame)
			lowest = math.max(lowest or piece.Edge, piece.Edge)
			table.insert(spans, piece)
		end
	end
	local toasts = Toast.Stack()
	if toasts then
		table.insert(spans, span(toasts))
	end
	World.Band(lowest, spans, (Layers.Get("Hud").AbsolutePosition.Y - origin.Y) / scale)
end

-- The top band goes see-through over a keeper and over your own lead's hanging square (Config.Hud.SeeThrough; research's
-- calls on AR7's fix 4, option B, and on TR7's hang, (a)): the
-- screen boxes of the listed parts that show, in the HUD's pixels, then each piece eased toward its floor while one is under
-- it, and back to whole once none has been for Hold. The lead's card stays whole: nothing tall stands on the left.
local CORNERS = {
	Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
	Vector3.new(1, -1, -1), Vector3.new(1, -1, 1), Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}

local function tallBoxes(): { Hud.Rect }
	local boxes: { Hud.Rect } = {}
	local camera = workspace.CurrentCamera
	if not camera then
		return boxes
	end
	local inset = GuiService:GetGuiInset()
	local function add(part: Instance?)
		if part and part:IsA("BasePart") and part.Transparency < 1 and part.LocalTransparencyModifier < 1 then
			local box: Hud.Rect? = nil
			for _, corner in CORNERS do
				local at = camera:WorldToViewportPoint(part.CFrame * (part.Size / 2 * corner))
				if at.Z > 0 then
					local x, y = at.X - inset.X, at.Y - inset.Y
					box = if box
						then { Left = math.min(box.Left, x), Top = math.min(box.Top, y), Right = math.max(box.Right, x), Bottom = math.max(box.Bottom, y) }
						else { Left = x, Top = y, Right = x, Bottom = y }
				end
			end
			if box then
				table.insert(boxes, box)
			end
		end
	end
	for _, model in fighters() do
		local names = if model:IsA("Model") then HudConfig.SeeThrough.Parts[tostring(model:GetAttribute("Rig"))] else nil
		for _, name in names or {} do
			add(model:FindFirstChild(name))
		end
	end
	-- and the effects' pieces that stand where the band is: your own lead's hanging square (Config.Hud.SeeThrough.Tag)
	for _, part in CollectionService:GetTagged(HudConfig.SeeThrough.Tag) do
		add(part)
	end
	return boxes
end

local function rectOf(frame: GuiObject): Hud.Rect
	local at, size = frame.AbsolutePosition, frame.AbsoluteSize
	return { Left = at.X, Top = at.Y, Right = at.X + size.X, Bottom = at.Y + size.Y }
end

local function seeThrough(dt: number)
	local config = HudConfig.SeeThrough
	local boxes = tallBoxes()
	local now = os.clock()
	local toasts = Toast.Stack()
	local pieces: { { Name: string, Root: GuiObject?, Rects: { Hud.Rect }, Floor: number, Keep: { [Instance]: boolean }? } } = {
		{ Name = "Target", Root = target.Frame, Rects = { rectOf(target.Frame) }, Floor = config.Target, Keep = { [target.Health] = true, [target.HealthText] = true } },
		{ Name = "Credits", Root = credits.Parent :: GuiObject, Rects = { rectOf(credits.Parent :: GuiObject) }, Floor = config.Economy },
		{ Name = "Electricity", Root = electricity.Parent :: GuiObject, Rects = { rectOf(electricity.Parent :: GuiObject) }, Floor = config.Economy },
		{ Name = "Toasts", Root = toasts, Rects = {}, Floor = config.Economy },
	}
	if toasts then
		for _, slot in toasts:GetChildren() do
			local plate = slot:FindFirstChild("Toast")
			if plate and plate:IsA("GuiObject") then
				table.insert(pieces[4].Rects, rectOf(plate))
			end
		end
	end
	for _, piece in pieces do
		local state = seen[piece.Name]
		if not state then
			state = { Share = 0, Over = -math.huge }
			seen[piece.Name] = state
		end
		local root = piece.Root
		if root and root.Visible then
			for _, rect in piece.Rects do
				for _, box in boxes do
					if Hud.Over(rect, box) then
						state.Over = now
					end
				end
			end
		end
		local want = if now - state.Over < config.Hold then 1 else 0
		state.Share += (want - state.Share) * math.min(1, dt * config.Rate)
		if math.abs(want - state.Share) < 1e-3 then
			state.Share = want
		end
		local opacity = Hud.Through(state.Share, piece.Floor)
		opacities[piece.Name] = opacity
		if piece.Keep then
			opacities[piece.Name .. "Bar"] = Hud.Through(state.Share, config.Bar)
		end
		if root then
			local keep: { [Instance]: number }? = nil
			if piece.Keep then
				local own = Hud.Through(state.Share, config.Bar)
				keep = {}
				for part in piece.Keep do
					(keep :: { [Instance]: number })[part] = own
				end
			end
			Fade.Set(root, opacity, keep)
		end
	end
end

-- Every frame: the cards from the fighters' attributes, the ring, the dock's selection, the electricity as it stands now.
-- The band's middle, in authored pixels: twice the nearer of the lead's card and the pills from the screen's middle, a
-- gap clear of each (the keeper's title card in B stands there, TR5).
local function bandRoom(): number
	local root = lead.Frame.Parent :: GuiObject
	local middle = root.AbsolutePosition.X + root.AbsoluteSize.X / 2
	local left = lead.Frame.AbsolutePosition.X + lead.Frame.AbsoluteSize.X
	local right = math.min((credits.Parent :: GuiObject).AbsolutePosition.X, (electricity.Parent :: GuiObject).AbsolutePosition.X)
	return 2 * (math.min(middle - left, right - middle) / math.max(Layers.Scale(), 0.01) - Theme.Size.Gap)
end

local function step(dt: number)
	VoidkinScreen.Tick() -- a tuned layout, or a reset left unconfirmed
	local model = myLead()
	lead.Frame.Visible = model ~= nil and model:GetAttribute("Title") ~= nil -- a fighter's attributes come a moment after it
	local foe: Model? = nil
	local mine = ""
	if model then
		LeadCard.Name(lead, tostring(model:GetAttribute("Title") or ""))
		lead.Level.Text = tostring(model:GetAttribute("Level") or "")
		local def = tostring(model:GetAttribute("Def") or "")
		local kind, class = kindOf(model)
		mine = kind
		local state = tostring(model:GetAttribute("State") or "")
		local down = state == "Down" or state == "Home"
		LeadCard.Who(lead, if Voidkin.ById[def] then def else nil, down)
		LeadCard.Kind(lead, kind, class)
		local status: string? = nil
		if down then
			-- Fallen (TR12): the portrait dims (never a red wash); the bar fills as it heals at home, and the line says how
			-- long, then whether it's training on the machine.
			local untilTime = model:GetAttribute("StateUntil")
			local training = player:GetAttribute("Training") == model:GetAttribute("Voidkin")
			status = Hud.LeadStatus(state, if type(untilTime) == "number" then untilTime else 0, workspace:GetServerTimeNow(), training)
			local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
			LeadCard.Fill(lead.Health, if state == "Home" and type(health) == "number" and type(most) == "number" and most > 0 then health / most else 0)
			lead.HealthText.Text = status or ""
		else
			showHealth(lead.Health, lead.HealthText, model)
		end
		lead.Frame:SetAttribute("Down", down)
		lead.Frame:SetAttribute("Status", status or "")
		nextButton.Visible = down and ownsAnother()
		nextButton.Position = UDim2.new(lead.Frame.Position.X.Scale, lead.Frame.Position.X.Offset, lead.Frame.Position.Y.Scale, lead.Frame.Position.Y.Offset + lead.Frame.Size.Y.Offset + Theme.Size.Gap)
		local why = if down then "Your lead is down" else nil
		if eye:GetAttribute("Why") ~= why then
			eye:SetAttribute("Why", why)
			Button.Set(eye, { Disabled = why or false })
		end
		local view = ProfileController.Get()
		local owned = if view then view.Voidkin[view.Roles.Lead] else nil
		if owned then
			local need = Growth.XpToNext(owned.Level)
			LeadCard.Fill(lead.Xp, if need and need > 0 then owned.Xp / need else 1)
		end
		local id = model:GetAttribute("Target")
		foe = if type(id) == "string" and id ~= "" then fighterById(id) else nil
	end
	-- A keeper's own bar stands in the target card's stead (TR5, A and B); an elite's card wears its heavier frame (C).
	local boss = HudConfig.Boss
	local variant = tostring(boss.Keeper)
	local trying = player:GetAttribute("Try") ~= nil
	BossBar.Step(keeperBar, if trying then keeperNear() else nil, variant, if variant == "B" then bandRoom() else nil)
	local foeKind = if foe then foe:GetAttribute("Kind") else nil
	target.Frame.Visible = foe ~= nil and not (foeKind == "Keeper" and (variant == "A" or variant == "B"))
	banded[5] = if variant == "B" then keeperBar.Frame else nil
	if foe then
		TargetCard.Elite(target, foeKind == "Elite" and boss.Elite == true) -- before its health: it swaps the light
		showHealth(target.Health, target.HealthText, foe)
		TargetCard.Name(target, tostring(foe:GetAttribute("Title") or ""), `Lv {tostring(foe:GetAttribute("Level") or "")}`)
		local theirs = kindOf(foe)
		if theirs ~= "" then
			swap(target.Gem, `Gem{theirs}`)
		end
		target.Gem.Visible = theirs ~= ""
		point(targetArrow, Hud.Arrow(mine, theirs))
	end
	stepRing(model, foe ~= nil, dt)
	placeEye() -- Config.Hud.Spectate.Place, tuned live
	band()
	seeThrough(dt)
	for name, button in dock do
		local open = Screen.Current() == name
		if button:GetAttribute("Selected") ~= open then
			button:SetAttribute("Selected", open)
			Button.Set(button, { Selected = open })
		end
	end
	local view = ProfileController.Get()
	if view and os.clock() - baseReadAt >= BASE_EVERY then
		baseReadAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		local stored = base.Data.Base.Battery
		local cap = BaseConfig.Battery.Capacity
		-- A jump (a return from away) pops; the bays' steady flow never does.
		local function shown(amount: number): string
			return `{Read.Stored(amount)} / {Read.Number(cap)}`
		end
		-- A jump (a return from away) flies in from the screen's middle and counts up (TR6); the steady flow just shows.
		if lastStored and cap > 0 and stored - lastStored >= HudConfig.Pop.Jump * cap then
			reward(electricity, bolt, Fly.Centre(), "Bolt", lastStored, stored, shown, HudConfig.Pop.Rungs.Electricity, UIKit.Charge, Read.Stored)
		else
			Count.Show(electricity, stored, shown)
		end
		lastStored = stored
		rate.Text = if stored >= cap - 1e-6 then "full" else Read.Rate(base.Rates.Net)
		if charge then
			Bar.Set(charge, if cap > 0 then stored / cap else 0)
		end
		showChip(view) -- home or the field, as the avatar moves
	end
	-- A, the keeper at the foot: the dock and its chip step out for the try, since their buttons don't serve a fight.
	local away = variant == "A" and trying
	dockHolder.Visible = not away
	if away then
		chip.Visible = false
	end
end

-- Opens the Base screen: BaseController's, set by it at Start.
HudController.OpenBase = function() end

function HudController.Start()
	lead = LeadCard.new(Layers.Get("Hud"), UDim2.fromOffset(PAD, TOP))
	-- The target's card centred, its blade and tab level with the lead's.
	target = TargetCard.new(Layers.Get("Hud"), UDim2.new(0.5, 0, 0, TOP - UIKit.TargetCard.Offset.Y))
	targetArrow = arrow(target.Frame, TargetCard.ArrowAt.X, TargetCard.ArrowAt.Y)
	targetArrow.ZIndex = 6 -- over the tab
	TargetCard.Elite(target, false) -- C's parts, built hidden
	local creditsValue, _, _, coinMark = pill("Credits", 1, 120, "Coin")
	credits, coin = creditsValue, coinMark
	local value, extra, thread, boltMark = pill("Electricity", 2, ELECTRICITY, "Bolt")
	electricity, rate, charge, bolt = value, extra, thread :: Frame, boltMark
	ring = signatureRing()
	eye = eyeButton()
	-- A fallen lead's card offers the next (TR12; docs/design.md, "The next lead"): it opens the Voidkin screen, where any
	-- whole one goes out at once, out of combat. In grey: the kit's button under the card.
	nextButton = Button.new({
		Name = "Next",
		Text = "Send another",
		Size = UDim2.fromOffset(180, Theme.Size.Tap),
		Parent = Layers.Get("Hud"),
		OnPress = function()
			voidkinScreen()
		end,
	})
	nextButton.Visible = false
	-- Experience's pop: white over the thread's lit share, brightest at its new end (Config.Hud.Pop).
	glint = Instance.new("Frame")
	glint.Name = "Glint"
	glint.BackgroundColor3 = Color3.new(1, 1, 1)
	glint.BackgroundTransparency = 1
	glint.BorderSizePixel = 0
	glint.Visible = false
	glint.ZIndex = 2
	local glow = Instance.new("UIGradient")
	glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(1, 0) })
	glow.Parent = glint
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = glint
	glint.Parent = lead.Xp
	Pop.Centre(lead.Level) -- it swells about its middle
	banded = { lead.Frame, target.Frame, credits.Parent :: GuiObject, electricity.Parent :: GuiObject }
	chip = Panel.new({
		Name = "Chip",
		Size = UDim2.fromOffset(DOCK.X * 3, PILL),
		Position = UDim2.new(0.5, 0, 1, -PAD - DOCK.Y - Theme.Size.Gap),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = Layers.Get("Hud"),
	})
	chip.Visible = false
	chipText = Text.new({ Name = "Value", Font = Theme.Font.Strong, Colour = GRAPHITE.Accent, Align = Enum.TextXAlignment.Center, Truncate = true, Box = UDim2.new(1, -PAD * 2, 1, 0), Position = UDim2.fromOffset(PAD, 0), Parent = chip })
	local holder = Instance.new("Frame")
	holder.Name = "Dock"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -PAD)
	holder.Size = UDim2.fromOffset(DOCK.X * 2 + Theme.Size.Gap, DOCK.Y)
	Panel.List(holder, Enum.FillDirection.Horizontal)
	holder.Parent = Layers.Get("Hud")
	dockHolder = holder
	keeperBar = BossBar.new(Layers.Get("Hud"))
	for order, name in { "Voidkin", "Base" } do
		dock[name] = Button.new({
			Name = name,
			Text = name,
			Size = UDim2.fromOffset(DOCK.X, DOCK.Y),
			LayoutOrder = order,
			Parent = holder,
			OnPress = function()
				if Screen.Current() == name then
					Screen.Close()
				elseif name == "Voidkin" then
					voidkinScreen()
				else
					HudController.OpenBase()
				end
			end,
		})
	end
	ProfileController.Changed:Connect(function(view: Profile.View)
		notice(lastView, view)
		lastView = view
		showView(view)
	end)
	local view = ProfileController.Get()
	if view then
		lastView = view
		showView(view)
	end
	RunService.RenderStepped:Connect(step)
	-- Whole or not at all (FadeController): the join's black lifts once both pills have their numbers, the lead's card its
	-- name when the save names a lead, and the frames have run smooth a moment, so all of it has drawn beneath the black.
	task.spawn(function()
		local smooth = 0
		while true do
			local dt = RunService.RenderStepped:Wait()
			smooth = if dt < 1 / 30 then smooth + 1 else 0
			local now = ProfileController.Get()
			local leadDrawn = lead.Frame.Visible or (now ~= nil and now.Roles.Lead == "")
			if credits.Text ~= "" and electricity.Text ~= "" and leadDrawn and smooth >= SMOOTH then
				FadeController.Whole()
				return
			end
		end
	end)
end

-- For tests: each top band piece's opacity now over a keeper (Config.Hud.SeeThrough), 1 whole: Target, TargetBar, Credits,
-- Electricity, Toasts.
function HudController.SeeThrough(): { [string]: number }
	return table.clone(opacities)
end

-- For tests: the keeper's bar (UI.BossBar.Shown): 0 hidden to 1 whole, and what's showing.
function HudController.Keeper(): (number, string)
	return BossBar.Shown(keeperBar)
end

-- For tests: the keeper's bar's trail and fill, shares of the bar (UI.BossBar.Trail).
function HudController.KeeperTrail(): (number, number)
	return BossBar.Trail(keeperBar)
end

-- For tests: the HUD's parts by name.
function HudController.Parts(): { [string]: GuiObject }
	return {
		Lead = lead.Frame,
		LeadName = lead.Name,
		LeadLevel = lead.Level,
		LeadHealth = lead.Health,
		LeadHealthText = lead.HealthText,
		LeadPortrait = lead.Portrait,
		LeadGem = lead.Gem,
		Target = target.Frame,
		TargetName = target.Name,
		TargetHealth = target.Health,
		TargetArrow = targetArrow,
		TargetGem = target.Gem,
		TargetElite = target.Frame:FindFirstChild("Elite") :: GuiObject,
		Keeper = keeperBar.Frame,
		KeeperHead = keeperBar.Head,
		KeeperName = keeperBar.Name,
		KeeperTitle = keeperBar.Title,
		KeeperFill = keeperBar.Fill,
		Dock = dockHolder,
		Credits = credits,
		Electricity = electricity,
		XpGlint = glint,
		ElectricityRate = rate,
		Signature = ring.Frame,
		Spectate = eye,
		Next = nextButton,
		Chip = chip,
		ChipText = chipText,
		Voidkin = dock.Voidkin,
		Base = dock.Base,
	}
end

return HudController
