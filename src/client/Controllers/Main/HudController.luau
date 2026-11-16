--!strict
-- HudController (client): the HUD in the world, on Modulo's kit (docs/ui.md, "The HUD, in the world"; TR3). Top left,
-- the lead's card (UI.LeadCard): the portrait in its rarity's frame, the head over it and the level on a badge, the name
-- on its tab with the class mark, the type's stud, a long health light with current and maximum inside, a thin
-- experience light; fallen, the portrait dims and the health says the seconds until it's back. Top centre, the target's
-- card (UI.TargetCard), built like the lead's, only in a fight: its stud and gem, the type edge's arrow before the first
-- hit, its name and level on its tab, its health light. Top right, two pills, each in its
-- system's colour (AR12, V2 Block; UI.Kit.Pill): Credits, and
-- Electricity stored over its cap with the rate and a thread of charge. Under the lead's card, the signature's readout
-- (UI.Readout): its well fills over the cooldown, it's white-hot when ready and empties in a flash as the move fires;
-- beside it the spectate eye. Bottom centre, the dock of three icons (UI.Dock): Base takes the player home in one tap
-- (TR19), Inventory opens the Voidkin screen, open while it is, and the Map waits for its screen; over the dock the
-- shards' hint while a shard waits and the player is home. The HUD's text wears one face
-- (Config.Hud.Face), switched at runtime. Everything reads the fighters' attributes (FightService) or the save's copy
-- (ProfileController); nothing here decides anything. The Voidkin screen lists the collection and makes a lead.
-- A keeper's try and an elite take their own HUD (TR5's grey variants, Config.Hud.Boss): the keeper's title card
-- (UI.BossBar) at the foot or the top in the target card's stead, and an elite's heavier frame on the target card.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local Actions = require(Shared.Definitions.Actions)
local HomeConfig = require(Shared.Config.Home)
local Growth = require(Shared.Rules.Growth)
local Hud = require(Shared.Rules.Hud)
local Home = require(Shared.Rules.Home)
local Markers = require(Shared.World.Markers)
local Net = require(Shared.Net)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local World = require(UI.World)
local Guide = require(UI.Guide)
local Read = require(UI.Read)
local Pill = require(UI.Kit.Pill)
local Text = require(UI.Kit.Text)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Skin = require(UI.Kit.Skin)
local Readout = require(UI.Readout)
local LeadCard = require(UI.LeadCard)
local VoidkinScreen = require(UI.VoidkinScreen)
local TargetCard = require(UI.TargetCard)
local Dock = require(UI.Dock)
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
local PAD = Theme.Size.Pad
-- The cards and the pills fit the smallest phone (Theme.Smallest at the scale's floor, 668 authored across) side by side:
-- the lead's 8 to 220, the target's centred from 226 to 442, the Electricity pill from 460 (the UI lint's overlap check).
-- The lead's card is UI.LeadCard (the director's pick of 2026-11-13: Midnight, the Ember lights, the head over the frame).
-- The top row's one line, the lead card's, the target's and the pills': the lead card's highest art (a head, a Mythical
-- frame's crest) stands 6 points under its top, so it clears Roblox's top bar by more than the 5.5 authored px research's
-- pass on TR3's fix round asked of the crest (call 1).
local TOP = 17
local PILL = Pill.Height
local BASE_EVERY = 0.25 -- seconds between reads of the base as it stands now: each copies the save
local SMOOTH = 12 -- frames in a row under 1/30 s before the join's black lifts: a join's stall leaves text undrawn a moment
local HINT = 288 -- the shards' hint's width over the dock

type Signature = {
	Piece: Readout.Piece,
	Ready: number, -- the server's Ready we last saw
	FiredAt: number, -- os.clock() of the last flash
	ReadyAt: number, -- os.clock() it last became ready
	Full: boolean,
	FoughtAt: number, -- os.clock() the lead last had a target
	Seen: number, -- 0 hidden to 1 shown: it fades in as a fight starts, out a moment after it ends
}

local lead: LeadCard.Card
local target: TargetCard.Card
local targetArrow: Frame
local credits: TextLabel
local coin: ImageLabel -- the Credits pill's icon, where a kill's Credits fly to (TR6)
local electricity: TextLabel -- the Power pill's value: generation against demand in kW (TR18)
local bolt: ImageLabel -- the Power pill's mark, where the battery's jump flies to
local stored: TextLabel -- the Power pill's second value: the battery's kWh
local charge: Frame -- the Power pill's thread: the battery's fill
local chip: Frame
local chipText: TextLabel
local readout: Signature
local eye: TextButton -- the spectate toggle (TR11)
local nextButton: TextButton -- under a fallen lead's card: sends out the next (TR12)
local dock: { [string]: TextButton } = {}
local dockHolder: Frame
local dockUi: Dock.Dock -- the dock of three icons (AR12; UI.Dock): dock[screen] is its tile's button
local keeperBar: BossBar.Bar
local lastView: Profile.View? = nil
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

-- The lead's signature: its kit's action with a cooldown (Definitions.Actions), by the lead's definition; "" for none.
local signatures: { [string]: string } = {}
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
local function eyeButton(): TextButton
	local look = HudConfig.Spectate
	local button = Button.new({
		Name = "Spectate",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(look.Size, look.Size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = Layers.Get("Hud"),
		OnPress = function()
			SpectateController.Set(not SpectateController.On())
		end,
	})
	local skin = Skin.Of(button) -- in the face, so it squeezes with it
	local inset = (look.Size - look.Plate) / 2
	local off = Skin.Lay(skin, "EyeOff", { Name = "Off", X = inset, Y = inset, Z = 12 })
	local on = Skin.Lay(skin, "EyeOn", { Name = "On", X = inset, Y = inset, Z = 12 })
	local function show()
		local lit = SpectateController.On()
		local whole = if button:GetAttribute("Why") ~= nil then HudConfig.Spectate.Off else 1
		on.Visible, off.Visible = lit, not lit
		on.ImageTransparency, off.ImageTransparency = 1 - whole, 1 - whole
		button:SetAttribute("On", lit)
	end
	SpectateController.Changed:Connect(function(lit: boolean)
		Button.Set(button, { Selected = lit })
		show()
	end)
	button:GetAttributeChangedSignal("Why"):Connect(show)
	show()
	return button
end

-- The lead's corner (AR12; Config.Hud.Readout, Config.Hud.Spectate, tuned live): the readout under the lead's card, the
-- eye beside it, and after the eye a fallen lead's offer of the next.
local function placeCorner()
	local plate, look = HudConfig.Readout, HudConfig.Spectate
	local card = lead.Frame
	local left = card.Position.X.Offset + plate.Right
	local top = card.Position.Y.Offset + card.Size.Y.Offset + plate.Under
	local piece = readout.Piece.Frame
	piece.Size = UDim2.fromOffset(plate.Size, plate.Size)
	piece.Position = UDim2.fromOffset(left + plate.Size / 2, top + plate.Size / 2)
	local x, y = left + plate.Size + look.Right + look.Plate / 2, top + look.Lower + look.Plate / 2
	eye.Size = UDim2.fromOffset(look.Size, look.Size)
	eye.Position = UDim2.fromOffset(x, y)
	nextButton.Position = UDim2.fromOffset(x + look.Size / 2 + Theme.Size.Gap, y)
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
	readout.Seen = if can then math.clamp(readout.Seen + (if want then by else -by), 0, 1) else 0
	piece.Frame.Visible = readout.Seen > 0
	piece.Frame:SetAttribute("Seen", readout.Seen)
	if not can or model == nil then
		return
	end
	local readyAt = model:GetAttribute("Ready")
	local ready = if type(readyAt) == "number" then readyAt else 0
	if ready > readout.Ready + 1e-3 then
		readout.FiredAt = now -- it fired: the server set when it's ready again
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
	local _, class = kindOf(model)
	Readout.Step(piece, {
		Share = share,
		Full = full,
		Flash = flash,
		Swell = back,
		Seen = readout.Seen,
		Action = signatureOf(tostring(model:GetAttribute("Def") or "")),
		Class = class,
	})
	piece.Frame:SetAttribute("Flash", flash)
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
-- in a ground, the Base tile's pip, since home is where the lead waits (TR19).
local function offer(down: boolean, fallen: string)
	local now = workspace:GetServerTimeNow()
	local which = Hud.AfterFall(down, if down then others(fallen) else {}, now, down and not atHome())
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
	Dock.Reason(dockUi, "Base", Home.Word(refusal, s)) -- a refused tile's word says why, at home "You're home" (TR20)
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
			Toast.Show(answer.Says)
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
			Toast.Show(says)
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
local function voidkinScreen(page: string?)
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	VoidkinScreen.Open(view, { Act = ProfileController.Act, Healing = healing, Page = page })
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
	local won = false
	for _, ground in view.Progress.Grounds do
		won = won or ground.KeeperWins > 0
	end
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
		Ground = if firstGround then firstGround.Name else "the grounds",
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
local function showChip(view: Profile.View)
	-- nothing in a keeper's try: the fight has the screen
	local step = if player:GetAttribute("Try") ~= nil then nil else Hud.NextStep(stepState(view))
	chip.Visible = step ~= nil
	if step then
		chipText.Text = step.Line
	end
	Guide.Point(stepTargets(step))
end

-- What changed since the last copy, said once: a shard gained (it drops in the world and flies to the avatar, and the toast
-- says it as it lands: TR24's fix 8), a level gained.
local function notice(old: Profile.View?, new: Profile.View)
	if old == nil then
		return
	end
	for shard, count in new.Bag.Shards do
		local gained = count - (old.Bag.Shards[shard] or 0)
		if gained > 0 then
			local words = `+{gained} {Read.ShardName(shard)}`
			Effects.Drop(fallenNear(), avatarAt, Read.ShardName(shard), function()
				Toast.Show(words, Theme.Colour.Ready)
			end)
		end
	end
	local pops = HudConfig.Pop.Rungs
	if new.Currency.Credits > old.Currency.Credits then
		-- A kill's Credits fly from where it fell (TR6); any other win pops at once.
		local fell = fallenNear()
		reward(credits, coin, if fell then Fly.From(fell) else nil, UIKit.Systems.Credits.Icon, old.Currency.Credits, new.Currency.Credits, Read.Number, pops.Credits, UIKit.Systems.Credits.Colour, Read.Number)
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
			lead.Level.TextColor3 = HudConfig.Card.LeadLevel:Lerp(Color3.new(1, 1, 1), HudConfig.Pop.Glow * p)
		end })
		Burst.Play(Fly.Middle(lead.Level), HudConfig.Card.Level) -- rung 5: sparks off the level's mark (TR6)
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
	local corner: World.Span? = nil
	for _, frame in { readout.Piece.Frame, eye, nextButton } :: { GuiObject } do
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

local function step(dt: number)
	VoidkinScreen.Tick() -- its clocks, Combat Power's count, a layout tuned live
	face()
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
		if charge then
			Bar.Set(charge, if cap > 0 then kwh / cap else 0)
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
-- Opens the base's command view (TR21's blockout): BaseController's, set by it at Start.
HudController.OpenView = function() end

function HudController.Start()
	lead = LeadCard.new(Layers.Get("Hud"), UDim2.fromOffset(PAD, TOP))
	-- The target's card centred, its blade and tab level with the lead's.
	target = TargetCard.new(Layers.Get("Hud"), UDim2.new(0.5, 0, 0, TOP - UIKit.TargetCard.Offset.Y))
	targetArrow = arrow(target.Frame, TargetCard.ArrowAt.X, TargetCard.ArrowAt.Y)
	targetArrow.ZIndex = 6 -- over the tab
	TargetCard.Elite(target, false) -- C's parts, built hidden
	local creditsPill = pill("Credits", 1, HudConfig.Pills.Credits, "Credits")
	credits, coin = creditsPill.Value, creditsPill.Mark
	local power = pill("Electricity", 2, HudConfig.Pills.Power, "Power")
	electricity, stored, charge, bolt = power.Value, power.Extra :: TextLabel, power.Thread :: Frame, power.Mark
	readout = {
		Piece = Readout.new(Layers.Get("Hud")),
		Ready = 0,
		FiredAt = -math.huge,
		ReadyAt = -math.huge,
		Full = true,
		FoughtAt = -math.huge,
		Seen = 0,
	}
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
			voidkinScreen("Overview") -- where Lead stands: the Items page has none (TR28)
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
	local hint = Pill.new({
		Name = "Chip",
		System = "Voidkin",
		Width = HINT,
		Centred = true,
		Position = UDim2.new(0.5, 0, 1, -PAD - UIKit.Dock.Size.Y - Theme.Size.Gap),
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = Layers.Get("Hud"),
	})
	chip, chipText = hint.Frame, hint.Value
	World.Foot(chip) -- the edge's arrow stands over it
	chip.Visible = false
	-- The dock of three icons (AR12): Inventory opens the Voidkin screen, open while it is; Base takes the player home
	-- (TR19: goHome), and the Base screen opens from a bay's prompt; the Map's screen isn't built, so its tile dims and says
	-- so on a tap.
	local function toggle(name: string, open: () -> ())
		return function()
			if Screen.Current() == name then
				Screen.Close()
			else
				open()
			end
		end
	end
	dockUi = Dock.new(Layers.Get("Hud"), {
		Inventory = toggle("Voidkin", function()
			voidkinScreen()
		end),
		Base = goHome,
	})
	Dock.Charges(dockUi, "Base", true) -- its tap is the charge's first frame: ink while it fills, no flash (TR19)
	dockHolder = dockUi.Frame
	dockHolder.AnchorPoint = Vector2.new(0.5, 1)
	dockHolder.Position = UDim2.new(0.5, 0, 1, -PAD)
	dock.Voidkin = dockUi.Tiles.Inventory.Button
	Button.Set(dockUi.Tiles.Map.Button, { Disabled = "The map isn't open yet" })
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

-- For tests: where a step's marker stands (stepTargets): a "Bay" step's, the bay it names on the player's plot.
function HudController.StepTargets(step: Hud.Step?): { Instance }
	return stepTargets(step)
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
		PowerStored = stored,
		Signature = readout.Piece.Frame,
		Spectate = eye,
		Next = nextButton,
		Chip = chip,
		ChipText = chipText,
		Voidkin = dock.Voidkin,
		Base = dockUi.Tiles.Base.Button,
		Map = dockUi.Tiles.Map.Button,
		HomeEdge = edges[1],
	}
end

return HudController
