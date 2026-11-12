--!strict
-- HudController (client): the HUD in the world, on Modulo's kit (docs/ui.md, "The HUD, in the world"; TR3). Top left,
-- the lead's card: the portrait in its rarity's frame with the level on a badge, the name, type gem and class mark, a
-- long health conduit with current and maximum inside, a thin experience thread; fallen, the portrait dims and the
-- conduit says the seconds until it's back. Top centre, the target's card, only in a fight: its gem, the type edge's
-- arrow before the first hit, its name and level, its health. Top right, two pills: Credits, and Electricity stored
-- over its cap with the rate and a thread of charge. Right edge, low, the signature's ring: it fills over the cooldown
-- and flashes when it fires. Bottom centre, the dock: Voidkin and Base, selected while their screen is open, and the
-- chip over it while a shard waits. Everything reads the fighters' attributes (FightService) or the save's copy
-- (ProfileController); nothing here decides anything. The Voidkin screen lists the collection and makes a lead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local EffectsConfig = require(Shared.Config.Effects)
local HudConfig = require(Shared.Config.Hud)
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
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Skin = require(UI.Kit.Skin)
local Portrait = require(UI.Kit.Portrait)
local Row = require(UI.Kit.Row)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local Effects = require(script.Parent.FighterController.Effects)
local FadeController = require(script.Parent.FadeController)

local HudController = {}

local player = Players.LocalPlayer
local GRAPHITE = UIKit.Palettes.Graphite
local PAD = Theme.Size.Pad
-- The cards and the pills fit the smallest phone (Theme.Smallest at the scale's floor, 668 authored across) side by side:
-- the lead's 8 to 220, the target's centred from 226 to 442, the Electricity pill from 460 (the UI lint's overlap check).
local CARD = Vector2.new(212, 62) -- the lead's card: the small frame at (7, 7), its lines from 56
local TARGET = Vector2.new(216, 50)
local ELECTRICITY = 200 -- the Electricity pill's width: "600 / 600" and the rate, or "full"
local PILL = 30 -- a pill's height (tools/blender/ui_kit.py, `pill`)
local BASE_EVERY = 0.25 -- seconds between reads of the base as it stands now: each copies the save
local SMOOTH = 12 -- frames in a row under 1/30 s before the join's black lifts: a join's stall leaves text undrawn a moment
local DOCK = Vector2.new(96, Theme.Size.Tap)
local INK = Color3.fromHex("#0B0C10") -- the outline of text written on a conduit's light

type Card = {
	Frame: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Xp: Frame?,
	Portrait: Frame?,
	Gem: ImageLabel,
	Class: ImageLabel?,
	Arrow: Frame?,
}

type Ring = {
	Frame: Frame,
	Halves: { UIGradient },
	Glyph: ImageLabel,
	Flash: UIStroke,
	Scale: UIScale,
	Ready: number, -- the server's Ready we last saw
	FiredAt: number, -- os.clock() of the last flash
	ReadyAt: number, -- os.clock() it last became ready
	Full: boolean,
}

local lead: Card
local target: Card
local credits: TextLabel
local electricity: TextLabel
local rate: TextLabel
local charge: Frame
local chip: Frame
local chipText: TextLabel
local ring: Ring
local dock: { [string]: TextButton } = {}
local lastView: Profile.View? = nil
local baseReadAt = 0

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

-- Text written on a conduit's light: the number reads over the light and over the empty channel alike.
local function onLight(name: string, parent: Instance): TextLabel
	local label = Text.new({ Name = name, Size = Theme.Text.Caption, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, Parent = parent })
	label.ZIndex = 3
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Thickness = 1.5
	stroke.Parent = label
	return label
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

local function leadCard(): Card
	local frame = Panel.new({ Name = "Lead", Size = UDim2.fromOffset(CARD.X, CARD.Y), Position = UDim2.fromOffset(PAD, PAD), Parent = Layers.Get("Hud") })
	frame.Visible = false
	local portrait = Portrait.new({ Name = "Portrait", Small = true, Position = UDim2.fromOffset(7, 7), Parent = frame })
	portrait.ZIndex = 2
	-- The level on a badge on the frame's foot (the director's word, 2026-11-12, from a reference).
	local badge = Panel.new({ Name = "Badge", Size = UDim2.fromOffset(30, 18), Position = UDim2.fromOffset(27, 56), AnchorPoint = Vector2.new(0.5, 0.5), Parent = frame })
	badge.ZIndex = 3
	local level = Text.new({ Name = "Level", Size = Theme.Text.Caption, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, Parent = badge })
	level.ZIndex = 3
	local x = 56
	local right = CARD.X - 8
	local name = Text.new({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Truncate = true, Box = UDim2.fromOffset(right - x - 40, 20), Position = UDim2.fromOffset(x, 4), Parent = frame })
	local gem = icon(frame, "GemStrength", right - 27, 14, 15)
	gem.Name = "Gem"
	local class = icon(frame, "ClassWarrior", right - 8, 14, 15)
	class.Name = "Class"
	local health = Bar.new({ Name = "Health", Size = UDim2.fromOffset(right - x, 18), Position = UDim2.fromOffset(x, 26), Colour = HudConfig.Card.Health, Parent = frame })
	local healthText = onLight("Value", health)
	local xp = Bar.new({ Name = "Xp", Size = UDim2.fromOffset(right - x, 4), Position = UDim2.fromOffset(x, 49), Colour = HudConfig.Card.Xp, Parent = frame })
	return { Frame = frame, Name = name, Level = level, Health = health, HealthText = healthText, Xp = xp, Portrait = portrait, Gem = gem, Class = class }
end

local function targetCard(): Card
	local frame = Panel.new({ Name = "Target", Size = UDim2.fromOffset(TARGET.X, TARGET.Y), Position = UDim2.new(0.5, 0, 0, PAD), AnchorPoint = Vector2.new(0.5, 0), Parent = Layers.Get("Hud") })
	frame.Visible = false
	local gem = icon(frame, "GemStrength", 16, 14, 15)
	gem.Name = "Gem"
	local way = arrow(frame, 31, 14)
	local name = Text.new({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Truncate = true, Box = UDim2.fromOffset(TARGET.X - 40 - 60, 20), Position = UDim2.fromOffset(40, 4), Parent = frame })
	local level = Text.new({ Name = "Level", Size = Theme.Text.Caption, Colour = GRAPHITE.Soft, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(56, 20), Position = UDim2.new(1, -8, 0, 4), AnchorPoint = Vector2.new(1, 0), Parent = frame })
	local health = Bar.new({ Name = "Health", Size = UDim2.fromOffset(TARGET.X - 16, 16), Position = UDim2.fromOffset(8, 27), Colour = HudConfig.Card.TargetHealth, Parent = frame })
	local healthText = onLight("Value", health)
	return { Frame = frame, Name = name, Level = level, Health = health, HealthText = healthText, Gem = gem, Arrow = way }
end

-- A pill (tools/blender/ui_kit.py, `pill`): its icon, its value, what's after it in soft ink, and for electricity a thread.
local function pill(name: string, order: number, width: number, image: string): (TextLabel, TextLabel, Frame?)
	local frame = Panel.new({
		Name = name,
		Size = UDim2.fromOffset(width, PILL),
		Position = UDim2.new(1, -PAD, 0, PAD + (order - 1) * (PILL + Theme.Size.Gap)),
		AnchorPoint = Vector2.new(1, 0),
		Parent = Layers.Get("Hud"),
	})
	icon(frame, image, 17, PILL / 2, 21)
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
	return value, extra, thread
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
	local well = circle("Well", GRAPHITE.Channel, 1)
	well.BackgroundColor3 = GRAPHITE.Well
	well.BackgroundTransparency = 0.25
	well.Parent = frame
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
	return { Frame = frame, Halves = halves, Glyph = glyph, Flash = flash, Scale = scale, Ready = 0, FiredAt = -math.huge, ReadyAt = -math.huge, Full = true }
end

-- How full the ring is, 0 to 1: the right half, then the left (each half's gradient turns its light in).
local function fillRing(share: number)
	local a = math.clamp(share * 360, 0, 180)
	local b = math.clamp(share * 360 - 180, 0, 180)
	ring.Halves[1].Rotation = 180 + b -- the left half
	ring.Halves[2].Rotation = a -- the right half
	ring.Frame:SetAttribute("Share", share)
end

local function stepRing(model: Model?)
	local cooldown = if model then model:GetAttribute("Cooldown") else nil
	ring.Frame.Visible = model ~= nil and type(cooldown) == "number" and cooldown > 0 and lead.Frame.Visible
	if not ring.Frame.Visible or model == nil then
		return
	end
	local config = HudConfig.Ring
	local now = os.clock()
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
	ring.Glyph.ImageTransparency = if full then 0 else 0.55
	local since = now - ring.FiredAt
	local flash = if since < config.Flash then 1 - since / config.Flash else 0
	ring.Flash.Transparency = 1 - flash
	local swell = now - ring.ReadyAt
	local back = if swell < config.Ready then math.sin(math.pi * swell / config.Ready) else 0
	ring.Scale.Scale = 1 + 0.25 * flash + 0.12 * back
	ring.Frame:SetAttribute("Flash", flash)
end

-- The Voidkin screen: the collection, the lead first; any other can be made the lead.
local function voidkinScreen()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	local body = Screen.Open("Voidkin", "Voidkin", Vector2.new(440, 300))
	local list = Row.List(body, "List")
	local roster = Read.Roster(view)
	if #roster == 0 then
		Row.new({ Parent = list, Order = 1, Text = "No Voidkin yet", Detail = "Break a shard at the Breaker", Colour = Theme.Colour.TextDim })
	end
	for index, owned in roster do
		local role = Read.Role(view, owned.Id)
		Row.new({
			Name = owned.Id,
			Parent = list,
			Order = index,
			Text = Read.VoidkinName(owned),
			Detail = `Lv {owned.Level}{if role ~= "" then " · " .. role else ""}`,
			Action = "Lead",
			Disabled = Hud.LeadReason(role),
			OnPress = function()
				local answer = ProfileController.Act("SetLead", { Voidkin = owned.Id })
				if answer.Ok ~= true then
					Toast.Show(`Can't lead: {tostring(answer.Error)}`, Theme.Colour.TextDim)
				end
			end,
		})
	end
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
	local floor = if type(plot) == "number" then Markers.Find("Plot", { Plot = plot }) else nil
	local at = avatarAt()
	if floor == nil or not floor:IsA("BasePart") or at == nil then
		return false
	end
	local offset = floor.CFrame:PointToObjectSpace(at)
	return math.abs(offset.X) <= floor.Size.X / 2 and math.abs(offset.Z) <= floor.Size.Z / 2
end

-- The chip over the dock while the bag holds a shard: the hook home stays in view until it's in the Breaker, and names
-- the step that's next: in the field "break it at home", at home "into the Breaker" (research's verdict on TR2 and its
-- read of the fixes, 2026-11-12).
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
	local id = new.Roles.Lead
	local was, now = old.Voidkin[id], new.Voidkin[id]
	if was and now and now.Level > was.Level then
		Toast.Show(`{Read.VoidkinName(now)} reached level {now.Level}`, Theme.Colour.Xp)
	end
end

local function showView(view: Profile.View)
	credits.Text = Read.Number(view.Currency.Credits)
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

local function showHealth(card: Card, model: Model)
	local health, most = healthOf(model)
	Bar.Set(card.Health, if most > 0 then health / most else 0)
	card.HealthText.Text = Hud.Health(health, most)
end

-- Every frame: the cards from the fighters' attributes, the ring, the dock's selection, the electricity as it stands now.
local function step()
	-- The cards' colours from Config.Hud.Card, so a tune shows at once (each call does nothing when it's unchanged).
	local colours = HudConfig.Card
	Bar.Colour(lead.Health, colours.Health)
	Bar.Colour(target.Health, colours.TargetHealth)
	if lead.Xp then
		Bar.Colour(lead.Xp, colours.Xp)
	end
	Panel.Trim(lead.Frame, colours.Trim)
	local model = myLead()
	lead.Frame.Visible = model ~= nil and model:GetAttribute("Title") ~= nil -- a fighter's attributes come a moment after it
	local foe: Model? = nil
	local mine = ""
	if model then
		lead.Name.Text = tostring(model:GetAttribute("Title") or "")
		lead.Level.Text = tostring(model:GetAttribute("Level") or "")
		local def = tostring(model:GetAttribute("Def") or "")
		local kind, class = kindOf(model)
		mine = kind
		local down = model:GetAttribute("State") == "Down"
		Portrait.Set(lead.Portrait :: Frame, if Voidkin.ById[def] then def else nil, down)
		if kind ~= "" then
			swap(lead.Gem, `Gem{kind}`)
		end
		if class ~= "" and lead.Class then
			swap(lead.Class, `Class{class}`)
		end
		if down then
			-- Fallen: the portrait dims (never a red wash) and the conduit says when it's back.
			local untilTime = model:GetAttribute("StateUntil")
			local back = if type(untilTime) == "number" and untilTime > 0 then Hud.Back(untilTime, workspace:GetServerTimeNow()) else 1
			Bar.Set(lead.Health, 0)
			lead.HealthText.Text = `Back in {Read.Seconds(back)}`
		else
			showHealth(lead, model)
		end
		lead.Frame:SetAttribute("Down", down)
		local view = ProfileController.Get()
		local owned = if view then view.Voidkin[view.Roles.Lead] else nil
		if owned and lead.Xp then
			local need = Growth.XpToNext(owned.Level)
			Bar.Set(lead.Xp, if need and need > 0 then owned.Xp / need else 1)
		end
		local id = model:GetAttribute("Target")
		foe = if type(id) == "string" and id ~= "" then fighterById(id) else nil
	end
	target.Frame.Visible = foe ~= nil
	if foe then
		showHealth(target, foe)
		target.Name.Text = tostring(foe:GetAttribute("Title") or "")
		target.Level.Text = `Lv {tostring(foe:GetAttribute("Level") or "")}`
		local theirs = kindOf(foe)
		if theirs ~= "" then
			swap(target.Gem, `Gem{theirs}`)
		end
		target.Gem.Visible = theirs ~= ""
		point(target.Arrow :: Frame, Hud.Arrow(mine, theirs))
	end
	stepRing(model)
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
		electricity.Text = `{Read.Stored(stored)} / {Read.Number(cap)}`
		rate.Text = if stored >= cap - 1e-6 then "full" else Read.Rate(base.Rates.Net)
		if charge then
			Bar.Set(charge, if cap > 0 then stored / cap else 0)
		end
		showChip(view) -- home or the field, as the avatar moves
	end
end

-- Opens the Base screen: BaseController's, set by it at Start.
HudController.OpenBase = function() end

function HudController.Start()
	lead = leadCard()
	target = targetCard()
	local creditsValue = pill("Credits", 1, 120, "Coin")
	credits = creditsValue
	local value, extra, thread = pill("Electricity", 2, ELECTRICITY, "Bolt")
	electricity, rate, charge = value, extra, thread :: Frame
	ring = signatureRing()
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

-- For tests: the HUD's parts by name.
function HudController.Parts(): { [string]: GuiObject }
	return {
		Lead = lead.Frame,
		LeadName = lead.Name,
		LeadLevel = lead.Level,
		LeadHealth = lead.Health,
		LeadHealthText = lead.HealthText,
		LeadPortrait = lead.Portrait :: Frame,
		LeadGem = lead.Gem,
		Target = target.Frame,
		TargetName = target.Name,
		TargetHealth = target.Health,
		TargetArrow = target.Arrow :: Frame,
		TargetGem = target.Gem,
		Credits = credits,
		Electricity = electricity,
		ElectricityRate = rate,
		Signature = ring.Frame,
		Chip = chip,
		ChipText = chipText,
		Voidkin = dock.Voidkin,
		Base = dock.Base,
	}
end

return HudController
