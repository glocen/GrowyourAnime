--!strict
-- HudController (client): the HUD in the world, on Modulo's kit (docs/ui.md, "The HUD, in the world"; TR3). Top left,
-- the lead's card (UI.LeadPlate): the portrait in its rarity's frame, the head over it and the level on a badge, the name
-- on its tab with the class mark, the type's stud, a long health light with current and maximum inside, a thin
-- experience light; fallen, the portrait dims and the health says the seconds until it's back. Top centre, the target's
-- card (UI.TargetCard), built like the lead's, only in a fight: its stud and gem, the type edge's arrow before the first
-- hit, its name and level on its tab, its health light. Top right, two pills, each in its
-- system's colour (AR12, V2 Block; UI.Kit.Pill): Credits, and
-- Electricity stored over its cap with the rate and a thread of charge. Under the lead's card, the signature's readout
-- (UI.Press, on its plate UI.LeadPlate): its well fills over the cooldown, it's white-hot when ready and empties in a flash as the move fires;
-- beside it the spectate eye. Bottom centre, the dock of three icons (UI.Dock): Base takes the player home in one tap
-- (TR19), Home opens Home's panel (AR49; UI.HomePanel), three cards each opening its whole screen, and the Map tile, its word Play, the Festival of Battles'
-- menu (TR45), reached through the Play panel (HudController.OpenPlay, set by ModeController); over the dock the
-- shards' hint while a shard waits and the player is home. The HUD's text wears one face
-- (Config.Hud.Face), switched at runtime. Everything reads the fighters' attributes (FightService) or the save's copy
-- (ProfileController); nothing here decides anything. The Voidkin screen lists the collection and makes a lead.
-- A keeper's try and an elite take their own HUD (TR5's grey variants, Config.Hud.Boss): the keeper's title card
-- (UI.BossBar) at the foot or the top in the target card's stead, and an elite's heavier frame on the target card.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage.Shared
local EffectsConfig = require(Shared.Config.Effects)
local HudConfig = require(Shared.Config.Hud)
local Combat = require(Shared.Config.Combat)
local UIKit = require(Shared.Config.UIKit)
local Profile = require(Shared.Data.Profile)
local Voidkin = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local Grounds = require(Shared.Definitions.Grounds)
local Shards = require(Shared.Definitions.Shards)
local GoalDefs = require(Shared.Definitions.Goals)
local Goals = require(Shared.Rules.Goals)
local SoundRule = require(Shared.Rules.Sound)
local Actions = require(Shared.Definitions.Actions)
local HomeConfig = require(Shared.Config.Home)
local Growth = require(Shared.Rules.Growth)
local Hud = require(Shared.Rules.Hud)
local Progress = require(Shared.Rules.Progress)
local Stats = require(Shared.Rules.Stats)
local Home = require(Shared.Rules.Home)
local Return = require(Shared.Rules.Return)
local Markers = require(Shared.World.Markers)
local PlaceRole = require(Shared.Util.PlaceRole)
local Net = require(Shared.Net)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local World = require(UI.World)
local Guide = require(UI.Guide)
local Read = require(UI.Read)
local Pill = require(UI.Kit.Pill)
local BatteryMark = require(UI.BatteryMark)
local Text = require(UI.Kit.Text)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Slate = require(UI.Kit.Slate)
local Press = require(UI.Press)
local LeadPlate = require(UI.LeadPlate)
local Edge = require(UI.Kit.Edge)
local LevelNotice = require(UI.LevelNotice)
local VoidkinScreen = require(UI.VoidkinScreen)
local EquipmentScreen = require(UI.EquipmentScreen)
local SettingsScreen = require(UI.SettingsScreen)
local TargetCard = require(UI.TargetCard)
local Dock = require(UI.Dock)
local HomePanel = require(UI.HomePanel)
local TodayList = require(UI.TodayList)
local BossBar = require(UI.BossBar)
local ReturnCard = require(UI.ReturnCard)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Refuse = require(UI.Kit.Refuse)
local Pop = require(UI.Kit.Pop)
local Fly = require(UI.Kit.Fly)
local Count = require(UI.Kit.Count)
local Burst = require(UI.Kit.Burst)
local Fade = require(UI.Kit.Fade)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local SpectateController = require(script.Parent.SpectateController)
local Effects = require(script.Parent.FighterController.Effects)
local Cues = require(script.Parent.FighterController.Cues)
local FadeController = require(script.Parent.FadeController)

local HudController = {}

local player = Players.LocalPlayer
local PAD = Theme.Size.Pad
-- The cards and the pills fit the smallest phone (Theme.Smallest at the scale's floor, 668 authored across) side by side:
-- the lead's 8 to 220, the target's centred from 226 to 442, the Electricity pill from 460 (the UI lint's overlap check).
-- The lead's plate is UI.LeadPlate (AR68 M on (a) slate, research's pick of 2026-11-27, 13:38).
-- The top row's one line, the lead card's, the target's and the pills': the lead card's highest art (a head, a Mythical
-- frame's crest) stands 6 points under its top, so it clears Roblox's top bar by more than the 5.5 authored px research's
-- pass on TR3's fix round asked of the crest (call 1).
local TOP = 17
local PILL = Pill.Height
local BASE_EVERY = 0.25 -- seconds between reads of the base as it stands now: each copies the save
local SMOOTH = 12 -- frames in a row under 1/30 s before the join's black lifts: a join's stall leaves text undrawn a moment
local HINT = 288 -- the shards' hint's width over the dock

type Signature = {
	Piece: Press.Piece,
	Ready: number, -- the server's Ready we last saw
	FiredAt: number, -- os.clock() of the last flash
	ReadyAt: number, -- os.clock() it last became ready
	Full: boolean,
	FoughtAt: number, -- os.clock() the lead last had a target
	Seen: number, -- 0 hidden to 1 shown: it fades in as a fight starts, out a moment after it ends
	ShownAt: number, -- os.clock() it last began to fade in
	TappedAt: number, -- os.clock() of the last tap on it (TR52)
	Armed: boolean, -- a full ring tapped: the tap's own word until the server's answer or the fire (TR52)
}

local lead: LeadPlate.Card
local target: TargetCard.Card
local credits: TextLabel
local coin: ImageLabel -- the Credits pill's icon, where a kill's Credits fly to (TR6)
local electricity: TextLabel -- the Power pill's value: generation against demand in kW (TR18)
local bolt: ImageLabel -- the Power pill's mark, where the battery's jump flies to
local stored: TextLabel -- the Power pill's second value: the battery's kWh
local battery: ImageLabel -- the battery's mark before it, its cells lit by the charge (UI.BatteryMark; TR41 (e))
local charge: Frame -- the Power pill's thread: the battery's fill
local chip: Frame
local chipText: TextLabel
local readout: Signature
local eye: TextButton -- the spectate toggle (TR11)
local auto: TextButton -- the signature's Auto, after the eye (TR52's block)
local autoOn = true -- as its words last said
local nextButton: TextButton -- under a fallen lead's card: sends out the next (TR12)
local dock: { [string]: TextButton } = {}
local dockHolder: Frame
local dockUi: Dock.Dock -- the dock of three icons (AR12; UI.Dock): dock[screen] is its tile's button
local homePanel: HomePanel.Panel -- Home's panel (AR49), and the dock's Home cell that opens it
local homeButton: TextButton
local panelWas = false -- whether the panel was open at the last frame: the chip follows it
local keeperBar: BossBar.Bar
local lastView: Profile.View? = nil
local healBand: Frame -- a heal of the lead's own: a band in the heal's green along its health light (Config.Hud.Card.Heal)
local healGain: TextLabel -- and its "+N" after the health's digits
local healAt = -math.huge -- the os.clock() the last one started
local healHeld: number? = nil -- for tests: the look held this many seconds in (a still), or running
local takenLabel: TextLabel -- the lead's damage taken, on its card (HudController.LeadTaken)
local takenScale: UIScale
local takenTotal, takenAt = 0, -math.huge
local takenHeld: number? = nil -- for tests: held this many seconds in
local glint: Frame -- experience's pop: a light over the thread's
local lastCharge: number? = nil -- the battery at the last read, for its jump
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
-- The skull's two blocks (TR49; Rules.Hud.FoeTier). The lead's, resolved from the profile as the server resolves it,
-- again only when a new copy of the profile arrives; the foe's, from its model's attributes, again only when one of
-- them moves (a crowd's health, a level).
local skullLead: { View: Profile.View?, Lead: string?, Block: Stats.Block? } = {}
local skullFoe: { Key: string?, Block: Stats.Block? } = {}

local function leadBlock(): Stats.Block?
	local view = ProfileController.Get()
	local id = if view then view.Roles.Lead else nil
	if view ~= skullLead.View or id ~= skullLead.Lead then
		local owned = if view and id then view.Voidkin[id] else nil
		skullLead.View, skullLead.Lead = view, id
		skullLead.Block = if view and owned then (Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)) else nil
	end
	return skullLead.Block
end

local function foeBlock(foe: Model): Stats.Block?
	local def, level = foe:GetAttribute("Def"), foe:GetAttribute("Level")
	if type(def) ~= "string" or type(level) ~= "number" then
		return nil
	end
	local kind, kin, difficulty, stage, most = foe:GetAttribute("Kind"), foe:GetAttribute("Type"), foe:GetAttribute("Difficulty"), foe:GetAttribute("Stage"), foe:GetAttribute("MaxHealth")
	local key = `{tostring(kind)}|{def}|{level}|{tostring(kin)}|{tostring(difficulty)}|{tostring(stage)}|{tostring(most)}`
	if key ~= skullFoe.Key then
		skullFoe.Key = key
		skullFoe.Block = Hud.FoeBlock(
			if type(kind) == "string" then kind else "",
			def,
			level,
			if type(kin) == "string" then kin else nil,
			if type(difficulty) == "string" then difficulty else nil,
			if type(stage) == "number" then stage else nil,
			if type(most) == "number" then most else nil
		)
	end
	return skullFoe.Block
end

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

-- Swaps an icon's picture to another of the kit's, keeping its place and size.
local function swap(image: ImageLabel, name: string)
	local im = UIKit.Images[name]
	if im and image:GetAttribute("Kit") ~= name then
		image.Image = im.Id
		image:SetAttribute("Kit", name)
	end
end

-- A pill of the top right, in its system's colour (UI.Kit.Pill): its mark on its block, its value, what's after it in
-- soft ink, and for electricity a thread.
local function pill(name: string, order: number, width: number, system: string): Pill.Parts
	local made = Pill.new({
		Name = name,
		System = system,
		Width = width,
		Position = UDim2.new(1, -PAD, 0, TOP + (order - 1) * (PILL + Theme.Size.Gap)),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Layers.Get("Hud"),
		Thread = name == "Electricity",
	})
	-- Shown once it has something to say: at a join the save's copy comes a moment after the HUD (TR2's rejoin take).
	local frame, value = made.Frame, made.Value
	frame.Visible = false
	value:GetPropertyChangedSignal("Text"):Connect(function()
		frame.Visible = value.Text ~= ""
	end)
	Pop.Centre(frame) -- it swells in place
	return made
end

-- A reward won into a pill (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN 3): from `from` (on the HUD layer,
-- or nil when it came from nowhere on screen) its icons fly to the pill's, and as the first lands its number starts
-- counting, the pill pops at Fly's rung and its "+N" rises. With nowhere to fly from, the number counts and the pill
-- pops at once, at its own rung.
-- In a fight the pills, the dock and the next step's chip step out (AR62's piece 1, B: research's yes, 2026-11-26): a fight
-- is the server's Engaged and Theme.Time.Fight after it. A pill that gains in a fight peeks alone: it shows while a reward
-- flies to it, counts up, holds Config.Hud.FightHides.Hold, and goes again.
local fightUntil = 0
local peeks: { [GuiObject]: number } = {}

function HudController.InFight(): boolean
	return os.clock() < fightUntil
end

-- A fight for `seconds` from now, as Engaged gives one (tests).
function HudController.FightFor(seconds: number)
	fightUntil = os.clock() + seconds
end

local function reward(value: TextLabel, mark: ImageLabel, from: Vector2?, image: string, old: number, new: number, format: (number) -> string, rung: number, tint: Color3, gainFormat: (number) -> string)
	local pillFrame = value.Parent :: GuiObject
	local won = new - old
	Count.Run(value, old, new, format, from ~= nil)
	peeks[pillFrame] = os.clock() + HudConfig.FightHides.Flight -- shown for the flight to land on
	local function land(fly: boolean)
		Count.Start(value)
		peeks[pillFrame] = os.clock() + HudConfig.Motion.Count.Seconds + HudConfig.FightHides.Hold
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

-- The lead's signature: its kit's action with a cooldown (Definitions.Actions), by the lead's definition; "" for none.
local signatures: { [string]: string } = {}
-- The signature's name as the roster says it (Voidkin.Words.Signature, its words before the colon), for the press's label.
local function signatureName(def: string): string?
	local voidkin = Voidkin.ById[def]
	local words = if voidkin and voidkin.Words then voidkin.Words.Signature else nil
	return if type(words) == "string" then string.match(words, "^([^:]+)") else nil
end

local function signatureOf(def: string): string
	local known = signatures[def]
	if known == nil then
		known = ""
		for _, action in Actions.KitOf(def) do
			if action.Cooldown > 0 then
				known = action.Id
			end
		end
		signatures[def] = known
	end
	return known
end

-- The spectate toggle (TR11; Config.Hud.Spectate): the eye beside the signature's readout, one family with it (AR12):
-- its own plate, open and lit while it's on, shut and dim while off, in a whole tap target. A tap turns it on or off
-- (SpectateController); while it can't be used it draws fainter and says why on a tap.
-- A control's tap area in B (AR62): the target's, never under the kit's least (Theme.Size.Tap: 44 px at the floor).
local function tapArea(): number
	return math.max(Slate.Pt(HudConfig.Slate.Tap), Theme.Size.Tap)
end

local function eyeButton(): TextButton
	local button = Button.new({
		Name = "Spectate",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(tapArea(), tapArea()),
		AnchorPoint = Vector2.new(0, 0), -- its tap area from the card's right edge, so it never lies over the card
		Parent = Layers.Get("Hud"),
		OnPress = function()
			SpectateController.Set(not SpectateController.On())
		end,
	})
	-- AR68 M: the eye on its slate chip beside Auto's, lit in the hue while you watch your lead (UI.Press).
	Press.EyeChip(button)
	local function show()
		local lit = SpectateController.On()
		local whole = if button:GetAttribute("Why") ~= nil then HudConfig.Spectate.Off else 1
		Press.EyeShows(button, lit, whole)
	end
	SpectateController.Changed:Connect(function(lit: boolean)
		Button.Set(button, { Selected = lit })
		show()
	end)
	button:GetAttributeChangedSignal("Why"):Connect(show)
	show()
	return button
end

-- The signature's Auto (AR68 M, UI.Press): its slate chip, the mark a filled square while on, its outline while off.
local function autoChip(button: TextButton)
	Press.AutoChip(button)
end

local function autoShows(button: TextButton, on: boolean)
	Press.AutoShows(button, on)
end

-- The quiet note under the lead's corner (docs/ui.md, rule 2; Config.Hud.Note; TR46): one line on a soft backing, in, read,
-- out. A new note takes the place of one still shown.
type Note = { Holder: Frame, Body: Frame, Words: TextLabel, Run: number }
local function makeNote(parent: Instance): Note
	local holder = Instance.new("Frame")
	holder.Name = "Note"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.XY
	holder.Visible = false
	holder.ZIndex = 6
	holder.Parent = parent
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Theme.Colour.Backing
	body.BorderSizePixel = 0
	body.Size = UDim2.fromOffset(0, 0)
	body.AutomaticSize = Enum.AutomaticSize.XY
	body.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = body
	local pad = Instance.new("UIPadding")
	local p = UDim.new(0, HudConfig.Note.Pad)
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = p, p, UDim.new(0, HudConfig.Note.Pad / 2), UDim.new(0, HudConfig.Note.Pad / 2)
	pad.Parent = body
	local words = Text.new({ Name = "Words", Size = Theme.Text.Caption, Colour = Theme.Colour.Text, Box = UDim2.fromOffset(0, 0), Parent = body })
	words.AutomaticSize = Enum.AutomaticSize.XY
	return { Holder = holder, Body = body, Words = words, Run = 0 }
end
local note: Note? = nil

-- Roblox's jump button, in GUI space (AbsolutePosition's): the touch controls' own while they show, else where Roblox's
-- jump would stand in the HUD's box (70 px a side when the box's short side is 500 or less, else 120), so the ring's
-- "Jump" place reads the same in a desktop playtest.
function HudController.JumpBox(): (Vector2, Vector2)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local touch = if gui then gui:FindFirstChild("TouchGui") else nil
	local button = if touch and touch:IsA("ScreenGui") and touch.Enabled then touch:FindFirstChild("JumpButton", true) else nil
	if button and button:IsA("GuiObject") and button.Visible and button.AbsoluteSize.X > 0 then
		return button.AbsolutePosition, button.AbsoluteSize
	end
	local hud = Layers.Get("Hud")
	local high = hud.AbsolutePosition + hud.AbsoluteSize
	local side = if math.min(hud.AbsoluteSize.X, hud.AbsoluteSize.Y) <= 500 then 70 else 120
	return Vector2.new(high.X - (side * 1.5 - 10), high.Y - (if side == 70 then side + 20 else side * 1.75)), Vector2.new(side, side)
end

-- The lead's corner in B (AR62; Config.Hud.Slate, tuned live): the eye docked to the card's right, the signature's
-- press under the card's foot-left (Press.At, or over the jump button: Readout.At), Auto beside the press, and a fallen
-- lead's offer of the next in Auto's place (the two never show together: the press hides with a fallen lead).
local corner: { Press: Vector2 }? = nil

local function placeEye()
	if corner == nil then
		return
	end
	local home = HudConfig.M.Art.Centre * HudConfig.M.Per
	local ax, ay, aw = Press.Box("Auto")
	local ex, ey, ew = Press.Box("Eye")
	-- Each chip at its box's top, its touch box hanging below it: clear of the skill's label just above.
	auto.AnchorPoint = Vector2.new(0, 0)
	auto.Size = UDim2.fromOffset(math.max(aw, tapArea()), tapArea())
	auto.Position = UDim2.fromOffset(home.X + ax, home.Y + ay)
	nextButton.AnchorPoint = Vector2.new(0, 0)
	nextButton.Position = auto.Position
	eye.AnchorPoint = Vector2.new(0, 0)
	eye.Size = UDim2.fromOffset(math.max(ew, tapArea()), tapArea())
	if readout.Seen > 0 then
		eye.Position = UDim2.fromOffset(home.X + ex, home.Y + ey) -- in a fight, M's row beside Auto
	else
		-- Out of a fight the row is empty: the eye waits at the plate's right end, clear of the next-lead button and the
		-- step's chip, which share that row on a phone (tier 1, 2026-11-27; the overhaul of the top left places it anew).
		local card = lead.Frame
		eye.Position = UDim2.fromOffset(card.Position.X.Offset + card.Size.X.Offset, card.Position.Y.Offset)
	end
end

local function placeCorner()
	local plate = HudConfig.Readout
	local hud, scale = Layers.Get("Hud"), math.max(Layers.Scale(), 0.01)
	local piece = readout.Piece
	local size = piece.Frame.Size.Y.Offset
	local home = HudConfig.M.Art.Centre * HudConfig.M.Per
	local press = home
	if plate.At == "Jump" then
		local at, box = HudController.JumpBox()
		local origin = hud.AbsolutePosition
		press = Vector2.new((at.X + box.X / 2 - origin.X) / scale, (at.Y - origin.Y) / scale - plate.Jump.Above - size / 2)
	end
	Press.Place(piece, press)
	corner = { Press = press }
	placeEye()
	-- The level-up's notice under the corner's row, at the plate's left edge (AR12, take B; TR41 (c)), stopping a gap short
	-- of the step's chip over the dock, which shares its row on a phone.
	local x = lead.Frame.Position.X.Offset
	local _, ay, _, ah = Press.Box("Auto")
	local foot = math.max(home.Y + size / 2, home.Y + ay + math.max(ah, tapArea())) -- under Auto's touch box
	local chipLeft = if chip then (chip.AbsolutePosition.X - hud.AbsolutePosition.X) / scale else math.huge
	LevelNotice.Place(x, foot + HudConfig.LevelNotice.Below, chipLeft - Theme.Size.Gap - x)
	-- The quiet note in the same place: the two never meet, a Tower run's lead being frozen (TR46).
	if note then
		note.Holder.Position = UDim2.fromOffset(x, foot + HudConfig.LevelNotice.Below)
	end
end

-- The readout shows only in a fight (TR3's verdict, fix 5): it fades in as the lead takes a target, and out a moment
-- after it has none. Hidden, it still follows the cooldown, so it shows the truth the moment it fades in.
local function stepReadout(model: Model?, fighting: boolean, dt: number)
	local cooldown = if model then model:GetAttribute("Cooldown") else nil
	local config = HudConfig.Readout
	local now = os.clock()
	local piece = readout.Piece
	local can = model ~= nil and type(cooldown) == "number" and cooldown > 0 and lead.Frame.Visible
	if can and (fighting or config.Always == true) then
		readout.FoughtAt = now
	end
	local want = can and now - readout.FoughtAt <= config.Linger
	local by = dt / math.max(if want then config.FadeIn else config.FadeOut, 1e-3)
	local was = readout.Seen
	readout.Seen = if can then math.clamp(readout.Seen + (if want then by else -by), 0, 1) else 0
	if was <= 0 and readout.Seen > 0 then
		readout.ShownAt = now
	end
	piece.Frame.Visible = readout.Seen > 0
	if readout.Seen <= 0 then
		piece.Label.Visible = false -- its label goes with it (Press.Step draws it while it shows)
	end
	auto.Visible = readout.Seen > 0 and not nextButton.Visible
	if readout.Seen ~= was then
		placeEye()
	end
	-- Its state in its words: the kit's set light alone read the same on and off at the phone's size (TR52's capture).
	local on = player:GetAttribute("SignatureAuto") ~= false
	if on ~= autoOn or auto:GetAttribute("On") == nil then
		autoOn = on
		Button.Set(auto, { Selected = on })
		autoShows(auto, on)
	end
	piece.Frame:SetAttribute("Seen", readout.Seen)
	if not can or model == nil then
		return
	end
	local readyAt = model:GetAttribute("Ready")
	local ready = if type(readyAt) == "number" then readyAt else 0
	if ready > readout.Ready + 1e-3 then
		readout.FiredAt = now -- it fired: the server set when it's ready again
		readout.Armed = false
	end
	readout.Ready = ready
	local share = Hud.Ready(ready, cooldown :: number, workspace:GetServerTimeNow())
	local full = share >= 1
	if full and not readout.Full then
		readout.ReadyAt = now
	end
	readout.Full = full
	local since = now - readout.FiredAt
	local flash = if since < config.Flash then 1 - since / config.Flash else 0
	local swell = now - readout.ReadyAt
	local back = if swell < config.Ready then math.sin(math.pi * swell / config.Ready) else 0
	-- TR52: a full ring left untapped pulses once, Pulse.Hold after its swell or its fade in; a tap answers on its frame,
	-- squeezed in and back; armed, waiting for its target's range, it stays in a little.
	local pulseConfig = config.Pulse
	local held = now - math.max(readout.ReadyAt + config.Ready, readout.ShownAt + config.FadeIn) - pulseConfig.Hold
	local pulse = if full and held >= 0 and held < pulseConfig.Length then math.sin(math.pi * held / pulseConfig.Length) else 0
	local pressed = now - readout.TappedAt
	local press = if pressed < config.PressTime then 1 - pressed / config.PressTime else 0
	local armed = readout.Armed or model:GetAttribute("Armed") == true
	press = math.max(press, if armed then config.Armed / config.Press else 0)
	local _, class = kindOf(model)
	local def = tostring(model:GetAttribute("Def") or "")
	Press.Step(piece, {
		Share = share,
		Full = full,
		Left = ready - workspace:GetServerTimeNow(),
		Flash = flash,
		Swell = back,
		Pulse = pulse,
		Press = press,
		Seen = readout.Seen,
		Action = signatureOf(def),
		Class = class,
		Name = signatureName(def),
	})
	piece.Frame:SetAttribute("Flash", flash)
	piece.Frame:SetAttribute("Pulse", pulse)
	piece.Frame:SetAttribute("Armed", armed)
end

-- A tap on the signature's readout (TR52's block): it answers on the frame (the squeeze), and a full ring takes the look
-- of armed at once; the server arms and fires it (FightService.Tap), or says why not, and only a refusal takes that back.
local function tapSignature()
	readout.TappedAt = os.clock()
	if readout.Full and readout.Seen > 0 then
		readout.Armed = true
	end
	task.spawn(function()
		local ok, answer = pcall(Net.Client.Invoke, "Signature", "Tap")
		if not ok or type(answer) ~= "table" or (answer.Ok ~= true and answer.Error ~= "Armed") then
			readout.Armed = false
		end
	end)
end

-- The HUD's face (Config.Hud.Face, FaceSmall; docs/ui.md, rule 3): every kit label on the HUD's layers wears it, and
-- wears another the moment the value changes (Tune).
local facedAs = ""
local function face()
	local name, small = tostring(HudConfig.Face), tostring(HudConfig.FaceSmall)
	local row = HudConfig.Faces[name] or HudConfig.Faces.BuilderSans
	local smallRow = HudConfig.Faces[small]
	local key = `{row.Family}\0{row.Body}\0{row.Strong}\0{row.Number}\0{if smallRow then `{smallRow.Family}\0{smallRow.Body}\0{smallRow.Strong}\0{smallRow.Number}` else ""}\0{HudConfig.FaceSmallUnder}`
	if key == facedAs then
		return
	end
	facedAs = key
	local made: Text.Face = {
		Family = row.Family,
		Body = row.Body,
		Strong = row.Strong,
		Number = row.Number,
		Small = if smallRow then { Family = smallRow.Family, Body = smallRow.Body, Strong = smallRow.Strong, Number = smallRow.Number } else nil,
		Under = HudConfig.FaceSmallUnder,
	}
	for _, layer in HudConfig.FaceLayers do
		Text.Face(Layers.Get(layer :: any), made)
	end
end

-- A fallen Voidkin's Id to the server time it's whole (LeadService's folder "Healing", an attribute each), or empty.
local function healing(): { [string]: number }
	local folder = player:FindFirstChild("Healing")
	local map: { [string]: number } = {}
	for id, whole in (if folder then folder:GetAttributes() else {}) :: { [string]: any } do
		if type(whole) == "number" then
			map[id] = whole
		end
	end
	return map
end

-- The other Voidkin the player owns besides the fallen `fallen`, as its card weighs them (Rules.Hud.AfterFall).
local function others(fallen: string): { Hud.Other }
	local view = ProfileController.Get()
	local list: { Hud.Other } = {}
	if view == nil then
		return list
	end
	local heals = healing()
	for id in view.Voidkin do
		if id ~= fallen and id ~= view.Roles.Lead then
			table.insert(list, { Role = Read.Role(view, id), Healing = heals[id] })
		end
	end
	return list
end

local function avatarAt(): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	return if root and root.Parent then root.Position else nil
end

-- Whether the avatar stands on its own plot.
local function atHome(): boolean
	local plot = player:GetAttribute("Plot")
	return Markers.OnPlot(if type(plot) == "number" then plot else nil, avatarAt())
end

-- What a fallen lead's card offers (TR12; Rules.Hud.AfterFall): the next lead under it while another is ready, else, out
-- in a ground, the Base tile's pip, since home is where the lead waits (TR19). Never in the Festival: there the lead
-- heals by the Arrival pad and comes back on its own (docs/design.md, "A fall in the Festival").
local function offer(down: boolean, fallen: string)
	local now = workspace:GetServerTimeNow()
	local which = Hud.AfterFall(down, if down then others(fallen) else {}, now, down and not atHome() and not PlaceRole.Is("Festival"))
	nextButton.Visible = which == "Send"
	Dock.Pip(dockUi, "Base", which == "Home")
end

-- Home in one tap (TR19; Rules.Home, HomeService): the client reads the same situation the server decides by, from the
-- player's attributes, and only shows it. The Base tile is quiet at home, dim while refused, fills from its foot in the
-- charge and wears the cooldown's veil; the avatar's outline lifts in void light over the charge.
local homeOutline: Highlight? = nil
local flashAt: number? = nil -- the jump's light at the screen's edges, from this os.clock()
-- A tap's charge, from its server time, while the server's answer is on its way: the press goes straight into the fill
-- (research's verdict on TR19). Seen: the server's own charge came, so its end ends this one. Its fill runs on this
-- client's own clock from the tap (tappedAt): the synced server clock can stand still for a few frames after a load,
-- and the ink then waited up to 0.08 s after the tap (the self-test, TR19 after TR20's case, 2026-11-15).
local charging: number? = nil
local tappedAt = 0
local chargeSeen = false
local landedAt: number? = nil -- the last jump's landing, from this os.clock(): the full tile holds a moment after it
local settleAt: number? = nil -- the arrival's field of view, eased back from this os.clock()
local settledFov = 70 -- the camera's own field of view under the arrival's
local edges: { Frame } = {}

local function attribute(name: string): number?
	local value = player:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

-- The lead out and standing: neither down nor gone home (FightService's standing, as its model's State shows it).
local function leadStands(): boolean
	local lead = myLead()
	local state = if lead then lead:GetAttribute("State") else nil
	return lead ~= nil and state ~= "Down" and state ~= "Home" and state ~= "Reset"
end

local function homeSituation(): Home.Situation
	return {
		Now = workspace:GetServerTimeNow(),
		HitAt = attribute("HitAt"),
		Engaged = player:GetAttribute("Engaged") == true, -- FightService.InCombat, as the server publishes it
		Standing = leadStands(),
		Try = player:GetAttribute("Try") ~= nil,
		Event = false, -- no event exists yet (HomeService)
		ReadyAt = attribute("HomeReady") or 0,
		OnPlot = atHome(),
	}
end

local function outline(share: number?)
	local character = player.Character
	local glow = homeOutline
	if share == nil or character == nil then
		if glow then
			glow.Enabled = false
		end
		return
	end
	if glow == nil or glow.Parent ~= character then
		if glow then
			glow:Destroy()
		end
		local made = Instance.new("Highlight")
		made.Name = "NL_HomeCharge"
		made.FillTransparency = 1
		made.DepthMode = Enum.HighlightDepthMode.Occluded
		made.Parent = character
		homeOutline = made
		glow = made
	end
	local lit = glow :: Highlight
	lit.OutlineColor = HomeConfig.Outline
	lit.Enabled = true
	lit.OutlineTransparency = 1 - share
end

-- The four edges' light: up in the first third of Flash, gone by its end.
local function stepFlash()
	local at = flashAt
	local u = if at then (os.clock() - at) / math.max(HomeConfig.Flash, 0.01) else 1
	local alpha = if u >= 1 then 0 elseif u < 1 / 3 then u * 3 else (1 - u) * 1.5
	if u >= 1 then
		flashAt = nil
	end
	for index, frame in edges do
		frame.Visible = alpha > 0
		frame.BackgroundTransparency = 1 - alpha * 0.85
		frame.BackgroundColor3 = HomeConfig.Edge
		local deep = HomeConfig.Reach
		frame.Size = if index <= 2 then UDim2.fromScale(1, deep) else UDim2.fromScale(deep * 0.6, 1)
	end
	local camera = workspace.CurrentCamera
	local settle = settleAt
	if camera and settle then
		local v = (os.clock() - settle) / math.max(HomeConfig.Settle, 0.01)
		if v >= 1 then
			settleAt = nil
			camera.FieldOfView = settledFov
		else
			local eased = 1 - (1 - v) * (1 - v)
			camera.FieldOfView = settledFov + HomeConfig.Fov * (1 - eased)
		end
	end
end

local function stepHome()
	local s = homeSituation()
	local refusal = Home.Refusal(s, HomeConfig)
	local served = attribute("HomeCharge")
	if charging and served then
		chargeSeen = true
	end
	if charging and ((chargeSeen and served == nil) or s.Now - charging > HomeConfig.Charge + 1) then
		charging, chargeSeen = nil, false -- the server's charge ended, or never came
	end
	local began = if charging and served then math.min(charging, served) else served or charging
	-- Landed, the tile stays full until this client sees home (its avatar's set-down replicates a moment after the jump).
	if refusal == "Here" or (landedAt and os.clock() - landedAt >= HomeConfig.Hold) then
		landedAt = nil -- home seen once ends the hold
	end
	local holding = began == nil and landedAt ~= nil
	local mood: Dock.Mood? = if refusal == "Here" then "Quiet" elseif refusal == "Boss" or refusal == "Event" or refusal == "Fight" then "Dim" else nil
	if began or holding then
		mood = nil -- a charge under way is broken only by a hit (HomeService): it never dims while it runs
	end
	Dock.Mood(dockUi, "Base", mood)
	Dock.Reason(dockUi, "Base", Home.Word(refusal, s)) -- a refused tile's word says why, at the base "Back at your base" (TR20)
	local share = if began then Home.Share(began, HomeConfig.Charge, s.Now) elseif holding then 1 else nil
	if share and charging then
		share = math.max(share, Home.Share(tappedAt, HomeConfig.Charge, os.clock()))
	end
	Dock.Fill(dockUi, "Base", share)
	Dock.Sweep(dockUi, "Base", if refusal == "Cooldown" and not holding then Home.Share(s.ReadyAt - HomeConfig.Cooldown, HomeConfig.Cooldown, s.Now) else nil)
	outline(if began then share else nil)
	stepFlash()
end

-- A tap on the Base tile: at home the base's command view (TR21); else the server's answer, which on a refusal says why
-- and shakes the tile.
local function goHome(): ...any
	local s = homeSituation()
	local refusal = Home.Refusal(s, HomeConfig)
	if refusal == "Here" then
		HudController.OpenView()
		return nil
	end
	if refusal == nil and attribute("HomeCharge") == nil then
		charging, tappedAt, chargeSeen = s.Now, os.clock(), false
	end
	local ok, answer = pcall(Net.Client.Invoke, "Home")
	if not ok or type(answer) ~= "table" or answer.Ok == false then
		charging, chargeSeen = nil, false
	end
	if ok and type(answer) == "table" and answer.Ok == false then
		if type(answer.Says) == "string" then
			Toast.Show(answer.Says, Theme.Colour.TextDim) -- a refusal in grey (TR71 B)
		end
		Dock.Shake(dockUi, "Base")
	end
	return nil
end

-- The jump's answer: landed, the light at the edges, the arrival's field of view and the puff at the feet; else why not.
local function jumped(landed: boolean, says: string?)
	charging, chargeSeen = nil, false
	if not landed then
		if type(says) == "string" then
			Toast.Show(says, Theme.Colour.TextDim) -- a refusal in grey (TR71 B)
		end
		Dock.Shake(dockUi, "Base")
		return
	end
	flashAt = os.clock()
	landedAt = flashAt
	local camera = workspace.CurrentCamera
	if camera then
		settledFov = if settleAt then settledFov else camera.FieldOfView
		settleAt = os.clock()
		camera.FieldOfView = settledFov + HomeConfig.Fov
	end
	local at = avatarAt()
	if at then
		Effects.Arrive(at, HomeConfig.Puff, HomeConfig.Settle + 0.05, HomeConfig.Edge)
	end
	player:SetAttribute("HomeLanded", os.clock()) -- for the self-test
end

-- The Voidkin screen (UI/VoidkinScreen): one Voidkin at a time, on the lead first (TR17). A fresh open shows `page`,
-- the Items page when none is named.
-- The Voidkin screen on `page`, its own screen, `said` its name in the band (Home's tiles, AR43).
local function voidkinScreen(page: string?, said: string?)
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	VoidkinScreen.Open(view, { Act = ProfileController.Act, Healing = healing, Page = page, Said = said })
end

-- Home's Voidkin card shows the lead live (AR49): the save's lead, so it shows at home as in a fight.
local function showLead(view: Profile.View)
	if homePanel == nil then
		return
	end
	local owned = view.Voidkin[view.Roles.Lead]
	HomePanel.Lead(homePanel, if owned then owned.Def else nil)
end

-- Equipment's screen (UI/EquipmentScreen; AR43, TR47's part A) on `page`: Reinforce, Jewels or War Emblems.
local function equipmentScreen(page: string)
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	EquipmentScreen.Open(page, view, { Act = ProfileController.Act, Say = function(words: string, refused: boolean?)
		Toast.Show(words, if refused then Theme.Colour.TextDim else nil) -- a refusal in grey (TR71 B)
	end })
end

-- Where a shard just won comes from: the nearest fallen Shade to the avatar, within Config.Effects.Drop.From.
local function fallenNear(): Vector3?
	local at = avatarAt()
	local best: Vector3? = nil
	local bestGap = EffectsConfig.Drop.From
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

-- The first session's state for the next step (TR24's fix 1; Rules.Hud.NextStep), from the save and where the avatar is.
local function stepState(view: Profile.View): Hud.StepState
	local kinds, total, first = 0, 0, nil :: string?
	for shard, count in view.Bag.Shards do
		if count > 0 then
			kinds += 1
			total += count
			first = first or shard
		end
	end
	local breaking = 0
	for _, chamber in view.Base.Chambers do
		breaking += if chamber.Work then 1 else 0
	end
	-- An empty bay, and a Voidkin that neither leads, works nor trains to fill it: the lowest Id, so it's always the same.
	local busy: { [string]: boolean } = { [view.Roles.Lead] = true, [view.Training.Trainee] = true }
	local worked, bay = false, nil :: number?
	for index, each in view.Base.Bays do
		if each.Worker ~= "" then
			busy[each.Worker] = true
			worked = true
		elseif bay == nil then
			bay = index
		end
	end
	local idle: string? = nil
	if bay then
		local ids: { string } = {}
		for id in view.Voidkin do
			if not busy[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		idle = if ids[1] then Read.VoidkinName(view.Voidkin[ids[1]]) else nil
	end
	local won = Progress.Beaten(view.Progress.Grounds)
	-- Out in a ground with a keeper: the keeper's name, near its gate (one ground has one yet).
	local home = atHome()
	local keeper: string? = nil
	if not home then
		local gate, ring, at = Markers.Find("KeeperGate"), Markers.Find("Ring"), avatarAt()
		local def = if ring then ring:GetAttribute("Def") else nil
		local row = if type(def) == "string" then Enemies.ById[def] else nil
		if gate and row and at and (Markers.At(gate).Position - at).Magnitude <= HudConfig.Guide.Reach then
			keeper = row.Name
		end
	end
	local firstGround = Grounds.ById[Grounds.First]
	return {
		Home = home,
		Chosen = view.Progress.Starter ~= "",
		Ready = #view.Base.Ready,
		Breaking = breaking,
		Shards = total,
		Kinds = kinds,
		First = if first then Read.ShardName(first) else nil,
		Idle = idle,
		Bay = bay,
		Worked = worked,
		Won = won,
		Keeper = keeper,
		Ground = if firstGround then firstGround.Name else "the Arcs", -- players read a ground as an Arc (the director, 2026-11-19)
	}
end

-- Where the next step's marker stands (UI.Guide): the targets in the world the step names, or none.
local function stepTargets(step: Hud.Step?): { Instance }
	if step == nil then
		return {}
	end
	local plot = player:GetAttribute("Plot")
	local found: Instance? = nil
	if step.Target == "Starters" then
		local folder = workspace:FindFirstChild("NL_Base")
		local list: { Instance } = {}
		for _, id in Shards.Starters do
			local part = if folder then folder:FindFirstChild(id) else nil
			if part then
				table.insert(list, part)
			end
		end
		return list
	elseif step.Target == "Breaker" then
		found = Markers.Find("Breaker", { Plot = plot })
	elseif step.Target == "Bay" then
		found = Markers.Find("Bay", { Plot = plot, Bay = step.Bay })
	elseif step.Target == "Door" then
		found = Markers.Find("FestivalDoor", { Plot = plot })
	elseif step.Target == "Gate" then
		found = Markers.Find("KeeperGate")
	end
	return if found then { found } else {}
end

-- The next step over the dock, in the Voidkin's colour, and its marker in the world (TR24's fix 1; Rules.Hud.NextStep):
-- what to do next at every step of the first session, the shards' hint among them ("into the Breaker", only at the base:
-- the director, 2026-11-15), which stays after it.
local shownStep: Hud.Step? = nil
local function showChip(view: Profile.View)
	-- nothing in a keeper's try: the fight has the screen
	local step = if player:GetAttribute("Try") ~= nil then nil else Hud.NextStep(stepState(view))
	shownStep = step
	-- Home's panel stands where the chip does: it steps out while the panel is open (AR43, AR49), and waits while the
	-- return card is up (TR53).
	chip.Visible = step ~= nil and not (homePanel ~= nil and HomePanel.Shown(homePanel)) and not ReturnCard.Up() and not HudController.InFight()
	if step then
		chipText.Text = step.Line
	end
	-- The world's marker only in the tutorial, until a keeper is beaten (TR65, the director: "those purple arrows are so
	-- stupid should only be there for a tutorial"); the line over the dock stays.
	Guide.Point(if Progress.Beaten(view.Progress.Grounds) then nil else stepTargets(step))
end

-- A level gained, said once, in one place: the notice under the lead's corner (AR12, take B; research's ruling,
-- 2026-11-15: the old toast and the word over the lead go, the column of light stays), the badge lit, and its sound
-- (TR64). Its name is the filtered one.
local function levelled(now: Profile.OwnedVoidkin)
	LevelNotice.Show(Read.VoidkinName(now), now.Level)
	Cues.Moment("LevelUp")
	Pop.Play(lead.Level, HudConfig.Pop.Rungs.Level, { Paint = function(p: number)
		LeadPlate.Glow(lead, HudConfig.Pop.Glow * p) -- the level lit toward pale gold
	end })
	Burst.Play(Fly.Middle(lead.Level), HudConfig.Card.Level) -- rung 5: sparks off the level's mark (TR6)
end

-- A shard's note as it touches the floor and its plate shows (TR64), by its grade.
local function chime(grade: string?): () -> ()
	return function()
		Cues.Moment("ShardDrop", { Speed = SoundRule.Note(grade) })
	end
end

-- What changed since the last copy, said once: a shard gained (it drops in the world and flies to the avatar, and the toast
-- says it as it lands: TR24's fix 8), a level gained, a goal done (its sound once the fight is quiet, TR64).
-- os.clock() the beat of a pack's last fall near the avatar ends (Config.Combat.Hitstop.Last; Net "Hit"'s Last): the
-- drops it paid wait it out, then leave together (TR69 A; combat-agency.md, item 11).
local dropsWait = 0

-- A pack's last fall near the avatar: its drops wait out its hold.
local function heldDrops(hit: any)
	local target = if type(hit) == "table" then hit.T else nil
	local at = avatarAt()
	if type(hit) == "table" and hit.Last == true and typeof(target) == "Instance" and target:IsA("Model") and at
		and (target:GetPivot().Position - at).Magnitude < EffectsConfig.Drop.From then
		dropsWait = math.max(dropsWait, os.clock() + (tonumber(hit.Hold) or 0))
	end
end

-- What a change paid, out in the world: each shard drops from the fallen Shade and flies to the avatar, the toast saying
-- it as it lands (TR24's fix 8), and a kill's Credits fly from where it fell (TR6); any other win pops at once.
local function drops(old: Profile.View, new: Profile.View)
	for shard, count in new.Bag.Shards do
		local gained = count - (old.Bag.Shards[shard] or 0)
		if gained > 0 then
			local words = `+{gained} {Read.ShardName(shard)}`
			local row = Shards.ById[shard]
			Effects.Drop(fallenNear(), avatarAt, Read.ShardName(shard), function()
				Toast.Show(words, Theme.Colour.Ready)
			end, chime(if row then row.Grade else nil))
		end
	end
	if new.Currency.Credits > old.Currency.Credits then
		local fell = fallenNear()
		reward(credits, coin, if fell then Fly.From(fell) else nil, UIKit.Systems.Credits.Icon, old.Currency.Credits, new.Currency.Credits, Read.Number, HudConfig.Pop.Rungs.Credits, UIKit.Systems.Credits.Colour, Read.Number)
	end
end

local function notice(old: Profile.View?, new: Profile.View)
	if old == nil then
		return
	end
	if old.Goals and new.Goals and Goals.Waits(new.Goals :: any, GoalDefs.ById) > Goals.Waits(old.Goals :: any, GoalDefs.ById) then
		Cues.Moment("GoalDone", { Hold = true })
	end
	-- What a pack's last fall paid waits out its beat and leaves together (TR69 A)
	local before: Profile.View = old
	local wait = dropsWait - os.clock()
	if wait > 0 then
		task.delay(wait, drops, before, new)
	else
		drops(before, new)
	end
	local pops = HudConfig.Pop.Rungs
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
		levelled(now)
	end
end

-- The HUD's moments as the listening panel shows them without their cause (TR64, Play the moment): the lead's level-up
-- with its column, a shard dropped before the avatar (each press the next grade's note), a goal done (its sound alone:
-- the Today card's rim is Home's).
local GRADES = { "Standard", "Enriched", "Prismatic", "Named" }
local staged = 0
local function stage()
	Cues.Stage("LevelUp", function()
		local view = ProfileController.Get()
		local now = if view then view.Voidkin[view.Roles.Lead] else nil
		if now == nil then
			return
		end
		levelled(now)
		local model = myLead()
		local root = if model then model:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			Effects.LevelUp(root)
		end
	end)
	Cues.Stage("ShardDrop", function()
		local at, camera = avatarAt(), workspace.CurrentCamera
		if at == nil or camera == nil then
			return
		end
		staged = staged % #GRADES + 1
		local grade = GRADES[staged]
		local ahead = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local from = at + (if ahead.Magnitude > 0 then ahead.Unit else Vector3.zAxis) * 8
		Effects.Drop(from, avatarAt, grade, nil, chime(grade))
	end)
	Cues.Stage("GoalDone", function()
		Cues.Moment("GoalDone", { Hold = true })
	end)
end

-- The return card (TR53; UI.ReturnCard): what the base did while the player was away, at the base only, out of a
-- keeper's try, risen once the join's black has lifted (Config.Hud.Return.Wait after it), so it's seen arriving.
local returnOn: ReturnCard.On = {
	Act = function(name: string, args: any?): { [string]: any }
		local answer = ProfileController.Act(name, args)
		if answer.Ok ~= true and answer.Error ~= Return.NoCard then
			Refuse.Show("Return", answer, nil, `ReturnCard {name}`)
		end
		return answer
	end,
	Reveal = function()
		HudController.OpenShard()
	end,
}
local returnWaits = false
-- The return card's room: from the Power pill's foot to the HUD's, in points, less the card's foot, so it never climbs
-- the pills (its workers fold to fit: ReturnCard).
local function returnRoom(): number?
	local pill = electricity.Parent
	if pill == nil or not pill:IsA("GuiObject") then
		return nil
	end
	local root = Layers.Get("Hud")
	local foot = pill.AbsolutePosition.Y + pill.AbsoluteSize.Y
	return (root.AbsolutePosition.Y + root.AbsoluteSize.Y - foot) / Layers.Scale() - HudConfig.Return.Foot
end
local function showReturn(view: Profile.View)
	local card = if PlaceRole.Is("Main") and player:GetAttribute("Try") == nil then view.Base.Card else nil
	if card == nil then
		ReturnCard.Hide()
		return
	end
	if FadeController.Opened() == nil then
		if not returnWaits then
			returnWaits = true
			task.spawn(function()
				while FadeController.Opened() == nil do
					RunService.RenderStepped:Wait()
				end
				task.wait(HudConfig.Return.Wait)
				returnWaits = false
				local now = ProfileController.Get()
				if now then
					showReturn(now)
					showChip(now)
				end
			end)
		end
		return
	end
	ReturnCard.Show(card, view, returnOn, returnRoom)
end

local function showView(view: Profile.View)
	Count.Show(credits, view.Currency.Credits, Read.Number) -- a count under way heads there
	showReturn(view)
	showChip(view)
	showLead(view)
	TodayList.View(homePanel, view)
	local owned = 0
	for _ in view.Voidkin do
		owned += 1
	end
	Button.Set(homeButton, { Disabled = Hud.VoidkinReason(owned) or false }) -- every built tile shows a Voidkin
	if Screen.Current() == "Voidkin" then
		voidkinScreen()
	elseif Screen.Current() == EquipmentScreen.Name then
		EquipmentScreen.Refresh(view)
	elseif Screen.Current() == SettingsScreen.Name then
		SettingsScreen.Refresh(view)
	end
end

local function healthOf(model: Model): (number, number)
	local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
	return (if type(health) == "number" then health else 0), (if type(most) == "number" then most else 0)
end

-- A card's health: its share on its light, current and most inside, set tight (UI.LeadPlate; the target's card is built
-- like the lead's, UI.TargetCard).
local function showHealth(bar: Frame, label: TextLabel, model: Model)
	local health, most = healthOf(model)
	if bar:IsDescendantOf(lead.Frame) then
		LeadPlate.Fill(bar, if most > 0 then health / most else 0)
	else
		Slate.Fill(bar, if most > 0 then health / most else 0)
		Slate.Notch(bar, most)
	end
	-- Too wide for its bar, it takes its compact form (TR3's verdict, fix 6: the dummy's 1,254,735 crowded its bar): the
	-- characters its share of the bar holds, a digit's width each (Config.Hud.Card.Room).
	local inset = bar:GetAttribute("Inset")
	local shown = bar.Size.X.Offset - (if type(inset) == "number" then inset else 0)
	local worn = HudConfig.Faces[tostring(HudConfig.Face)] or HudConfig.Faces.BuilderSans
	local room = math.floor(shown * HudConfig.Card.Room / (label.TextSize * worn.Digit))
	label.Text = Hud.Health(health, most, room, true)
end

-- The top band's lower edge for the world's numbers (UI.World.Band): the lowest of the cards and the pills that show,
-- plus the margin, in the World layer's authored pixels (TR3's verdict, fix 4: numbers stay below the top band). And each
-- piece's own span, its margin all round, a toast stack's while it shows, and the top bar's foot: an open plate, the
-- level-up's word, stands clear of only what it crosses (research's pass on AR8 C, fix 1). And the lead's corner under its
-- card, one span over the readout, the eye and the next's offer when it shows: a plate under the band starts right of it
-- (research's pass on AR12 at phone size: the eye stood over "Bay 1 · no one works here").
local banded: { GuiObject } = {}
local beneath: { GuiObject } = {} -- pieces under the band's, a span each but no say in its edge (HudController.Beneath)
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
	for index = #beneath, 1, -1 do
		local frame = beneath[index]
		if frame.Parent == nil then
			table.remove(beneath, index)
		elseif frame.Visible then
			table.insert(spans, span(frame))
		end
	end
	local corner: World.Span? = nil
	for _, frame in { readout.Piece.Frame, readout.Piece.Label, eye, auto, nextButton } :: { GuiObject } do
		if frame.Visible then
			local piece = span(frame)
			corner = if corner
				then { Left = math.min(corner.Left, piece.Left), Right = math.max(corner.Right, piece.Right), Edge = math.max(corner.Edge, piece.Edge) }
				else piece
		end
	end
	World.Band(lowest, spans, (Layers.Get("Hud").AbsolutePosition.Y - origin.Y) / scale, corner)
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
		if root and homePanel then -- a corner piece the glass would cut mid-word fades under Home's panel (AR49)
			opacity = math.min(opacity, 1 - HomePanel.Covers(homePanel, root))
		end
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

-- Every frame: the cards from the fighters' attributes, the readout, the dock's selection, the electricity as it stands now.
-- The band's middle, in authored pixels: twice the nearer of the lead's card and the pills from the screen's middle, a
-- gap clear of each (the keeper's title card in B stands there, TR5).
local function bandRoom(): number
	local root = lead.Frame.Parent :: GuiObject
	local middle = root.AbsolutePosition.X + root.AbsoluteSize.X / 2
	local left = lead.Frame.AbsolutePosition.X + lead.Frame.AbsoluteSize.X
	local right = math.min((credits.Parent :: GuiObject).AbsolutePosition.X, (electricity.Parent :: GuiObject).AbsolutePosition.X)
	return 2 * (math.min(middle - left, right - middle) / math.max(Layers.Scale(), 0.01) - Theme.Size.Gap)
end

-- A heal of the lead's own on its bar (TR40, research's must-fix): the band runs from the light's root to its front
-- eased out, holds and fades; the "+N" rises after the digits and fades in its last third. The front is read each frame,
-- so a heal that comes before its health does still ends on the new front.
local function paintHeal()
	local h = HudConfig.Card.Heal
	local age = healHeld or (os.clock() - healAt)
	local shown = lead.Frame.Visible
	healBand.Visible = shown and age < h.Sweep + h.Hold + h.Fade
	if healBand.Visible then
		local share = lead.Health:GetAttribute("Share")
		local front = (if type(share) == "number" then share else 0) * lead.Health.Size.X.Offset
		local run = math.clamp(age / h.Sweep, 0, 1)
		local fade = math.clamp((age - h.Sweep - h.Hold) / h.Fade, 0, 1)
		healBand.Position = UDim2.fromOffset(front * (1 - (1 - run) ^ 2) - h.Band / 2, 0)
		healBand.Size = UDim2.new(0, h.Band, 1, 0)
		healBand.BackgroundTransparency = 1 - h.Peak * (1 - fade)
	end
	healGain.Visible = shown and age < h.Life
	if healGain.Visible then
		local life = math.clamp(age / h.Life, 0, 1)
		local bar, digits = lead.Health, lead.HealthText
		-- The digits as drawn, centred on their bar (AR62, B), in the card's points (Text.Wide's stock measure ran 3 points
		-- long on the phone's face): the "+N" starts after their end.
		local drawn = digits.TextBounds.X * bar.Size.X.Offset / math.max(bar.AbsoluteSize.X, 1)
		local after = bar.Position.X.Offset + (bar.Size.X.Offset + drawn) / 2 + h.Gap
		healGain.Position = UDim2.fromOffset(after, bar.Position.Y.Offset - h.Rise * (1 - (1 - life) ^ 2))
		healGain.Size = UDim2.fromOffset(Text.Wide(healGain, healGain.Text) + 2, bar.Size.Y.Offset)
		healGain.TextTransparency = math.clamp((life - 2 / 3) * 3, 0, 1)
	end
end

-- The lead's damage taken at the end of the plate's name row (AR68 M; UI.LeadPlate lays it): it swells at each hit,
-- rises and fades in its last third (Config.Hud.Slate.Taken's motion).
local function paintTaken()
	local k = HudConfig.Slate.Taken
	local age = takenHeld or (os.clock() - takenAt)
	takenLabel.Visible = lead.Frame.Visible and age < k.Life
	if not takenLabel.Visible then
		return
	end
	local life = math.clamp(age / k.Life, 0, 1)
	local top = takenLabel:GetAttribute("Top")
	takenLabel.Position = UDim2.fromOffset(takenLabel.Position.X.Offset, (if type(top) == "number" then top else 0) - Slate.Pt(k.Rise) * Hud.Ease(life))
	takenScale.Scale = 1 + (k.Pop - 1) * math.clamp(1 - age / 0.12, 0, 1)
	Edge.Fade(takenLabel, math.clamp((life - 2 / 3) * 3, 0, 1))
end

local repaintAt = 0
local function step(dt: number)
	VoidkinScreen.Tick() -- its clocks, Combat Power's count, a layout tuned live
	face()
	if player:GetAttribute("Engaged") == true then
		fightUntil = math.max(fightUntil, os.clock() + Theme.Time.Fight)
	end
	local fighting = HudController.InFight()
	for _, pillFrame in { credits.Parent :: GuiObject, electricity.Parent :: GuiObject } do
		pillFrame.Visible = not fighting or (peeks[pillFrame] or 0) > os.clock()
	end
	-- The Slate's surface tokens laid again a few times a second (AR62: a Tune, or the finish's surface, without a rebuild).
	local clock = os.clock()
	if clock >= repaintAt then
		repaintAt = clock + 0.25
		Slate.Repaint(Layers.Get("Hud"))
	end
	local model = myLead()
	lead.Frame.Visible = model ~= nil and model:GetAttribute("Title") ~= nil -- a fighter's attributes come a moment after it
	local foe: Model? = nil
	local mine = ""
	if model then
		LeadPlate.Name(lead, tostring(model:GetAttribute("Title") or ""))
		lead.Level.Text = tostring(model:GetAttribute("Level") or "")
		local def = tostring(model:GetAttribute("Def") or "")
		local kind, class = kindOf(model)
		mine = kind
		local state = tostring(model:GetAttribute("State") or "")
		local down = state == "Down" or state == "Home"
		LeadPlate.Who(lead, if Voidkin.ById[def] then def else nil, down)
		LeadPlate.Kind(lead, kind, class)
		local status: string? = nil
		if down then
			-- Fallen (TR12): the portrait dims (never a red wash); the bar fills as it heals at home, and the line says how
			-- long, then whether it's training on the machine.
			local untilTime = model:GetAttribute("StateUntil")
			local training = player:GetAttribute("Training") == model:GetAttribute("Voidkin")
			status = Hud.LeadStatus(state, if type(untilTime) == "number" then untilTime else 0, workspace:GetServerTimeNow(), training)
			local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
			LeadPlate.Fill(lead.Health, if state == "Home" and type(health) == "number" and type(most) == "number" and most > 0 then health / most else 0)
			lead.HealthText.Text = status or ""
		else
			showHealth(lead.Health, lead.HealthText, model)
		end
		lead.Frame:SetAttribute("Down", down)
		lead.Frame:SetAttribute("Status", status or "")
		offer(down, tostring(model:GetAttribute("Voidkin") or ""))
		local why = if down then "Your lead is down" else nil
		if eye:GetAttribute("Why") ~= why then
			eye:SetAttribute("Why", why)
			Button.Set(eye, { Disabled = why or false })
		end
		local view = ProfileController.Get()
		local owned = if view then view.Voidkin[view.Roles.Lead] else nil
		if owned then
			local need = Growth.XpToNext(owned.Level)
			LeadPlate.Fill(lead.Xp, if need and need > 0 then owned.Xp / need else 1)
		end
		local id = model:GetAttribute("Target")
		foe = if type(id) == "string" and id ~= "" then fighterById(id) else nil
	end
	paintHeal()
	paintTaken()
	-- A keeper's own bar stands in the target card's stead (TR5, A and B); an elite's card wears its brass (AR45).
	local boss = HudConfig.Boss
	local variant = tostring(boss.Keeper)
	local trying = player:GetAttribute("Try") ~= nil
	BossBar.Step(keeperBar, if trying then keeperNear() else nil, variant, if variant == "B" then bandRoom() else nil)
	local foeKind = if foe then foe:GetAttribute("Kind") else nil
	target.Frame.Visible = foe ~= nil and not (foeKind == "Keeper" and (variant == "A" or variant == "B"))
	banded[5] = if variant == "B" then keeperBar.Frame else nil
	if foe then
		TargetCard.Elite(target, foeKind == "Elite" and boss.Elite == true)
		showHealth(target.Health, target.HealthText, foe)
		-- The skull by what one fight with the foe costs the lead (AR45, TR49; Rules.Hud.FoeTier), read again each frame
		-- from the two blocks: it turns as either grows. No lead yet, white.
		local leadSide, foeSide = leadBlock(), foeBlock(foe)
		TargetCard.Tier(target, if leadSide and foeSide then Hud.FoeTier(leadSide, foeSide, HudConfig.Skulls.Cuts) else 2)
		TargetCard.Name(target, tostring(foe:GetAttribute("Title") or ""), `Lv {tostring(foe:GetAttribute("Level") or "")}`)
		local theirs = kindOf(foe)
		if theirs ~= "" then
			swap(target.Gem, `Gem{theirs}`)
		end
		target.Gem.Visible = theirs ~= ""
		TargetCard.Point(target, Hud.Arrow(mine, theirs))
	end
	placeCorner()
	stepReadout(model, foe ~= nil, dt)
	band()
	seeThrough(dt)
	for name, button in dock do
		local open = Screen.Current() == name
		if button:GetAttribute("Selected") ~= open then
			button:SetAttribute("Selected", open)
			Button.Set(button, { Selected = open })
		end
	end
	stepHome()
	local home = HomePanel.Shown(homePanel) or HomePanel.Holds(homePanel)
	if homeButton:GetAttribute("Selected") ~= home then
		homeButton:SetAttribute("Selected", home)
		Button.Set(homeButton, { Selected = home })
	end
	if HomePanel.Shown(homePanel) ~= panelWas then -- the chip steps out for the panel, and back
		panelWas = HomePanel.Shown(homePanel)
		local view = ProfileController.Get()
		if view then
			showChip(view)
		end
	end
	HomePanel.Paint(homePanel)
	TodayList.Paint(homePanel)
	ReturnCard.Held(TodayList.Shown(homePanel)) -- the list covers the card's corner (research's must-fix on TR59)
	Dock.Paint(dockUi)
	local view = ProfileController.Get()
	if view and os.clock() - baseReadAt >= BASE_EVERY then
		baseReadAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		local kwh = base.Data.Base.Charge
		local cap = base.Rates.Capacity
		-- TR18: the pill says power, never a stock: generation against demand, the battery after it and in the thread.
		-- The value turns Power's warning colour only while the battery covers a shortfall (research's verdict), never
		-- for a split generation covers; the frame's Over attribute is set for the tests.
		local generation, demand = base.Rates.Generation, base.Rates.Demand
		local against = Read.Against(generation, demand)
		local over = base.Rates.Flow.Net < -1e-9
		local function shown(_: number): string
			return against
		end
		-- A jump of the battery (a return from away) flies in from the screen's middle and pops, its "+N kWh" rising
		-- (TR6); the steady flow just shows.
		if lastCharge and cap > 0 and kwh - lastCharge >= HudConfig.Pop.Jump * cap then
			reward(electricity, bolt, Fly.Centre(), "Bolt", lastCharge, kwh, shown, HudConfig.Pop.Rungs.Electricity, UIKit.Charge, function(n: number): string
				return `{Read.Kwh(n)} kWh`
			end)
		else
			Count.Show(electricity, kwh, shown)
		end
		lastCharge = kwh
		local pillFrame = electricity.Parent :: GuiObject
		if pillFrame:GetAttribute("Over") ~= over then
			pillFrame:SetAttribute("Over", over)
			electricity.TextColor3 = if over then Theme.Colour.Over else UIKit.Systems.Power.Text
		end
		stored.Text = if kwh >= cap - 1e-6 then "full" else `{Read.Kwh(kwh)} kWh`
		BatteryMark.Set(battery, kwh, cap)
		if charge then
			Bar.Set(charge, if cap > 0 then kwh / cap else 0)
		end
		showChip(view) -- home or the field, as the avatar moves
	end
	-- A, the keeper at the foot: the dock and its chip step out for the try, since their buttons don't serve a fight.
	local away = variant == "A" and trying
	dockHolder.Visible = not away and not HudController.InFight()
	if away then
		chip.Visible = false
	end
end

-- Opens the Base screen: BaseController's, set by it at Start.
HudController.OpenBase = function() end
-- Opens the base's command view (TR21's blockout): BaseController's, set by it at Start.
HudController.OpenView = function() end
-- Opens the oldest ready shard, its reveal on the server's yes: BaseController's, set by it at Start (the return
-- card's Reveal, TR53).
HudController.OpenShard = function() end
-- The dock's Play tile: the Play panel, a card a mode (ModeController sets it; the director, 2026-11-24).
HudController.OpenPlay = function() end

-- Shows `words` as the quiet note under the lead's corner (TR46: the heal cap told once).
-- Equipment's screen on `page` (Reinforce, Jewels or War Emblems), for a prompt in the world: the Forge's (TR37).
function HudController.OpenEquipment(page: string)
	equipmentScreen(page)
end

function HudController.Note(words: string)
	local shown = note
	if shown == nil then
		return
	end
	local config = HudConfig.Note
	shown.Run += 1
	local run = shown.Run
	shown.Words.Text = words
	shown.Holder.Visible = true
	local still = GuiService.ReducedMotionEnabled
	shown.Body.Position = UDim2.fromOffset(if still then 0 else -config.Slide, 0)
	shown.Body.BackgroundTransparency, shown.Words.TextTransparency = 1, 1
	local easeIn = TweenInfo.new(config.In, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(shown.Body, easeIn, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = config.Back }):Play()
	TweenService:Create(shown.Words, easeIn, { TextTransparency = 0 }):Play()
	task.delay(config.In + config.Hold, function()
		if shown.Run ~= run then
			return
		end
		local easeOut = TweenInfo.new(config.Out, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(shown.Body, easeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shown.Words, easeOut, { TextTransparency = 1 }):Play()
		task.delay(config.Out, function()
			if shown.Run == run then
				shown.Holder.Visible = false
			end
		end)
	end)
end

-- The player's lead's model, standing or fallen, or nil (the run's fall card reads it: UI.StageScreen, Retry).
function HudController.Lead(): Model?
	return myLead()
end

-- The picker of who's ready to lead, as a fallen lead's "Send another" opens it (the run's fall card's too).
function HudController.SendAnother()
	voidkinScreen("Overview", "Overview") -- where Lead stands: the Items page has none (TR28)
end

-- The note's words while it shows, else nil: for tests.
function HudController.Noted(): string?
	return if note and note.Holder.Visible then note.Words.Text else nil
end

function HudController.Start()
	stage()
	-- Roblox's player list stood over the pills of the top right on a computer (research, 21:44, a second reader's cold
	-- read of the base); its height grows with the server, so the pills can't sit clear of it. Hidden: the people on the
	-- server stay a tap away in Roblox's own menu. Its call can fail while the core UI loads, so it's tried a few times.
	task.spawn(function()
		for _ = 1, 10 do
			if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, false) then
				return
			end
			task.wait(0.5)
		end
	end)
	lead = LeadPlate.new(Layers.Get("Hud"))
	LevelNotice.Mount(Layers.Get("Hud"))
	note = makeNote(Layers.Get("Hud"))
	-- The foe's card centred, its top level with the lead's plate's (AR45: the two face each other).
	target = TargetCard.new(Layers.Get("Hud"), UDim2.new(0.5, 0, 0, TOP)) -- level with the lead's card (AR62, B)
	local creditsPill = pill("Credits", 1, HudConfig.Pills.Credits, "Credits")
	credits, coin = creditsPill.Value, creditsPill.Mark
	local power = pill("Electricity", 2, HudConfig.Pills.Power, "Power")
	electricity, stored, charge, bolt = power.Value, power.Extra :: TextLabel, power.Thread :: Frame, power.Mark
	-- The battery's mark before its reading, always (research, TR41 (e); docs/ui.md, the top right).
	battery = BatteryMark.new(power.Frame, HudConfig.Power.PillMark.Side, power.Value.ZIndex)
	battery.Name = "Battery" -- the pill's own Mark stays the bolt, where the battery's jump flies to
	Pill.Before(power, battery, HudConfig.Power.PillMark.Gap)
	readout = {
		Piece = Press.new(Layers.Get("Hud")),
		Ready = 0,
		FiredAt = -math.huge,
		ReadyAt = -math.huge,
		Full = true,
		FoughtAt = -math.huge,
		Seen = 0,
		ShownAt = -math.huge,
		TappedAt = -math.huge,
		Armed = false,
	}
	-- The readout is the button (TR52's block): the touch going down fires, as a fight's buttons do, not the let go.
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.Text = ""
	tap.AutoButtonColor = false
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 20
	tap.Parent = readout.Piece.Frame
	tap.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			tapSignature()
		end
	end)
	eye = eyeButton()
	-- A fallen lead's card offers the next (TR12; docs/design.md, "The next lead"): it opens the Voidkin screen, where any
	-- whole one goes out at once, out of combat. In grey: the kit's button in the lead's corner, after the eye (placeCorner).
	nextButton = Button.new({
		Name = "Next",
		Text = "Send another",
		Size = UDim2.fromOffset(180, Theme.Size.Tap),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = Layers.Get("Hud"),
		OnPress = function()
			voidkinScreen("Overview", "Overview") -- where Lead stands: the Items page has none (TR28)
		end,
	})
	nextButton.Visible = false
	-- The signature's Auto (TR52's block): selected while on, its lead's signature going as soon as it's ready, as ever;
	-- off, only on a tap. For this server only, on the player (FightService.SetAuto).
	auto = Button.new({
		Name = "SignatureAuto",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(tapArea(), tapArea()),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = Layers.Get("Hud"),
		OnPress = function()
			local ok, answer = pcall(Net.Client.Invoke, "Signature", "Auto", player:GetAttribute("SignatureAuto") == false)
			return ok and type(answer) == "table" and answer.Ok == true
		end,
	})
	auto.Visible = false
	autoChip(auto)
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
	-- A heal of the lead's own (paintHeal): the band over its health light, soft at both ends so the light's slant never
	-- shows a square edge; its "+N" on the card, after the digits.
	local heal = HudConfig.Card.Heal
	healBand = Instance.new("Frame")
	healBand.Name = "HealBand"
	healBand.BackgroundColor3 = heal.Colour
	healBand.BackgroundTransparency = 1
	healBand.BorderSizePixel = 0
	healBand.Visible = false
	healBand.ZIndex = 2
	local soft = Instance.new("UIGradient")
	soft.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
	soft.Parent = healBand
	healBand.Parent = lead.Health
	healGain = Text.new({ Name = "HealGain", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = heal.Colour, Parent = lead.Frame })
	healGain.ZIndex = 6
	healGain.Visible = false
	takenLabel = lead.Taken
	takenLabel.Visible = false
	takenScale = Instance.new("UIScale")
	takenScale.Parent = takenLabel
	Effects.Taken = HudController.LeadTaken
	-- A Regen burst on the player's own lead (TR40). Later heals of the lead's own (Lifesteal's, a healer's) come here too.
	Net.Client.On("Hit", heldDrops) -- a pack's last fall holds its drops (TR69 A)
	Net.Client.On("Heal", function(burst: any)
		if type(burst) == "table" and burst.Regen == true and type(burst.Amount) == "number" and burst.T ~= nil and burst.T == myLead() then
			HudController.LeadHealed(burst.Amount)
		end
	end)
	Pop.Centre(lead.Level) -- it swells about its middle
	banded = { lead.Frame, target.Frame, credits.Parent :: GuiObject, electricity.Parent :: GuiObject }
	local hint = Pill.new({
		Name = "Chip",
		System = "Voidkin",
		Width = HINT,
		Centred = true,
		Position = UDim2.new(0.5, 0, 1, -PAD - HudConfig.Make.Dock.Box.Y + math.min(HudConfig.Make.Dock.At.Y, 0) - Theme.Size.Gap), -- over the dock's frame
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = Layers.Get("Hud"),
	})
	chip, chipText = hint.Frame, hint.Value
	World.Foot(chip) -- the edge's arrow stands over it
	chip.Visible = false
	-- The dock of three icons (AR12): Home opens Home's panel and closes it (AR49); Base takes the player home (TR19:
	-- goHome), and the Base screen opens from a bay's prompt; the Map tile opens the Festival's menu (TR45).
	dockUi = Dock.new(Layers.Get("Hud"), {
		Home = function()
			if HomePanel.Shown(homePanel) then
				HomePanel.Close(homePanel)
			else
				HomePanel.Open(homePanel)
			end
		end,
		Base = function()
			HomePanel.Close(homePanel) -- the way home leaves the panel
			goHome()
		end,
		Map = function() -- its word is Play: the Play panel, in either place (ModeController; TR45)
			HudController.OpenPlay()
		end,
	})
	Dock.Charges(dockUi, "Base", true) -- its tap is the charge's first frame: ink while it fills, no flash (TR19)
	dockHolder = dockUi.Frame
	dockHolder.AnchorPoint = Vector2.new(0.5, 1)
	dockHolder.Position = UDim2.new(0.5, 0, 1, -PAD)
	homeButton = dockUi.Tiles.Home.Button
	-- Home's panel (AR49) stands over the dock, clear of the lead's card; each card opens its whole screen on the page last
	-- shown there.
	local make = HudConfig.Make.Dock
	homePanel = HomePanel.new(Layers.Get("Cover"), Layers.Get("Hud"), PAD + make.Box.Y - math.min(make.At.Y, 0), {
		Voidkin = function()
			voidkinScreen(VoidkinScreen.Last())
		end,
		Equipment = function()
			equipmentScreen(EquipmentScreen.Last())
		end,
		Settings = function()
			SettingsScreen.Open({ Act = ProfileController.Act, Say = function(words: string, refused: boolean?)
				Toast.Show(words, if refused then Theme.Colour.TextDim else nil) -- a refusal in grey (TR71 B)
			end })
		end,
	}, lead.Frame)
	TodayList.Attach(homePanel, ProfileController.Act) -- Settings' column's Today card and its list (TR54)
	local known = ProfileController.Get()
	if known then
		showLead(known)
		TodayList.View(homePanel, known)
	end
	-- The bodies come after a join's first copy (RevealService's Ready): the lead's card is shown again once they're in.
	task.spawn(function()
		local reveal = ReplicatedStorage:WaitForChild("NL_Reveal")
		while reveal:GetAttribute("Ready") ~= true do
			reveal:GetAttributeChangedSignal("Ready"):Wait()
		end
		local now = ProfileController.Get()
		if now then
			showLead(now)
		end
	end)
	-- The jump's light (TR19), a stand-in until Modulo's look: one frame on each of the screen's edges, lit at the edge and
	-- gone Reach in, over everything but the toasts.
	local overlay = Layers.Get("Overlay")
	for index, side in { { 0, 0, 90 }, { 0, 1, 270 }, { 0, 0, 0 }, { 1, 0, 180 } } do
		local frame = Instance.new("Frame")
		frame.Name = `HomeEdge{index}`
		frame.BorderSizePixel = 0
		frame.BackgroundTransparency = 1
		frame.AnchorPoint = Vector2.new(side[1], side[2])
		frame.Position = UDim2.fromScale(side[1], side[2])
		frame.Visible = false
		local fade = Instance.new("UIGradient")
		fade.Rotation = side[3]
		fade.Transparency = NumberSequence.new(0, 1)
		fade.Parent = frame
		frame.Parent = overlay
		table.insert(edges, frame)
	end
	Net.Client.On("HomeJump", jumped)
	keeperBar = BossBar.new(Layers.Get("Hud"))
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

-- The next step over the dock now, or nil: a machine's plate leaves out the fact it says (BaseController).
function HudController.Step(): Hud.Step?
	return shownStep
end

-- For tests: where a step's marker stands (stepTargets): a "Bay" step's, the bay it names on the player's plot.
function HudController.StepTargets(step: Hud.Step?): { Instance }
	return stepTargets(step)
end

-- A heal of the lead's own, `amount` health, shown on its bar (paintHeal); nothing under half a point.
function HudController.LeadHealed(amount: number)
	if amount < 0.5 then
		return
	end
	healGain.Text = `+{Hud.Digits(math.floor(amount + 0.5))}`
	healAt = os.clock()
end

-- Damage the lead took, `amount` health, on its card (paintTaken): hits while one shows add to it; nothing under half a
-- point.
function HudController.LeadTaken(amount: number)
	if amount < 0.5 then
		return
	end
	local now = os.clock()
	takenTotal = if now - takenAt < HudConfig.Slate.Taken.Life then takenTotal + amount else amount
	takenAt = now
	takenLabel.Text = `−{Hud.Digits(math.floor(takenTotal + 0.5))}`
end

-- For tests: the lead's damage taken held `age` seconds in, or running again (nil).
function HudController.HoldTaken(age: number?)
	takenHeld = age
end

-- For tests: the lead's heal look held `age` seconds in, for a still, or running again (nil).
function HudController.HoldHeal(age: number?)
	healHeld = age
end

-- For tests: the HUD's parts by name.
-- The foe card's foot, in the HUD layer's authored pixels: a title at the top's middle stands under it (the Tower's
-- floor, TR46; AR44's verdict: it drew over the card's health).
function HudController.FoeFoot(): number
	return target.Frame.Position.Y.Offset + target.Frame.Size.Y.Offset
end

-- The target card's place at the top centre, and whether a fight shows it: where the Broadcast's plate stands when it
-- doesn't (TR57, BroadcastController).
function HudController.TargetSpot(): (UDim2, boolean)
	return target.Frame.Position, target.Frame.Visible
end

-- Home's panel, for tests (UI.HomePanel's own calls).
function HudController.Home(): HomePanel.Panel
	return homePanel
end

-- Where an event chip stands under the pills, anchored at its top right (docs/ui.md, "Under the pills"): the Void Shop's
-- countdown (AR38).
-- A piece on the HUD under the band's (the shop's countdown under the pills): a plate keeps clear of it as of the band's,
-- and it never lowers the band's edge (research's must-fix 3 on AR51). Dropped once it leaves the HUD.
function HudController.Beneath(frame: GuiObject)
	if table.find(beneath, frame) == nil then
		table.insert(beneath, frame)
	end
end

function HudController.UnderPills(): UDim2
	return UDim2.new(1, -PAD, 0, TOP + 2 * (PILL + Theme.Size.Gap))
end

-- A tap on the signature's readout, as a finger's (TR52; tests).
function HudController.TapSignature()
	tapSignature()
end

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
		TargetArrow = target.Arrow,
		TargetGem = target.Gem,
		TargetElite = target.Elite,
		TargetSkull = target.Skull,
		TargetLevel = target.Level,
		Keeper = keeperBar.Frame,
		KeeperHead = keeperBar.Head,
		KeeperName = keeperBar.Name,
		KeeperTitle = keeperBar.Title,
		KeeperFill = keeperBar.Fill,
		Dock = dockHolder,
		Credits = credits,
		Electricity = electricity,
		XpGlint = glint,
		LeadHealBand = healBand,
		LeadHealGain = healGain,
		PowerStored = stored,
		PowerBattery = battery,
		Signature = readout.Piece.Frame,
		Spectate = eye,
		Next = nextButton,
		SignatureAuto = auto,
		Chip = chip,
		ChipText = chipText,
		Voidkin = homePanel.Cards.Voidkin.Button, -- the way to the Voidkin screen: Home's Voidkin card, on the page last shown
		Equipment = homePanel.Cards.Equipment.Button,
		Settings = homePanel.Cards.Settings.Button,
		Home = homeButton,
		HomePanel = homePanel.Frame,
		HomeDim = homePanel.Dim,
		Base = dockUi.Tiles.Base.Button,
		Map = dockUi.Tiles.Map.Button,
		HomeEdge = edges[1],
	}
end

return HudController
