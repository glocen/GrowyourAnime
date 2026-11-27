--!strict
-- BossBar (client UI): the keeper's HUD in a try (TR5; Config.Hud.Boss). A title card, light over the fight: no plate
-- behind it (the director, 2026-11-14: "much better ... this is so empty", the health "purpleish", "well compose", and "very
-- light too else we see nothing"). Its title small between two thin rules, each ending in a diamond; its name large, its
-- type's gem before it and its level after, the name in the keeper's purple lit from above (the director, 2026-11-14: "not
-- white"); one framed bar in the keeper's purple, lit from above, on a faint glow, a pale
-- trail behind the fill that holds a moment after a hit and drains, a faceted cap at each end; its health in the bar's
-- middle, and no mark across it (the director, 2026-11-14: "remove the middle crystal", "the hp text value ... in the
-- center"). Nothing below the bar (research's verdict on the grey block, 2026-11-14, fixes 1 and 2: the bar about twice
-- as thick, its number on it, nothing of it over the keeper).
-- Its line art is Modulo's (TR5, "Modulo's frames, delivered"; Config.UIKit's Boss* images and BossBar, drawn by
-- tools/blender/boss_hud_art.py), white and tinted Config.Hud.Boss.Rim: the bar's rim, sliced to the channel; its two caps,
-- scaled with the bar's height; the title's two tapering rules with their diamond tips, sliced across; the crest over the
-- title's middle, standing above the title row's top.
-- B, the top middle (the director's pick, 2026-11-14): in the band's middle, the target card's place, as wide as the room
-- between the lead's card and the pills (HudController measures it). A, at the foot: wide across the bottom centre (the
-- dock steps out for the try: HudController). The name stamps on as the keeper's Challenge lands (its Stamp beat), the
-- rest comes in after it with a shine across the bar, and the whole leaves from the fall's Gone (Config.Effects.Falls).
--   BossBar.new(parent)                         the bar, hidden
--   BossBar.Step(bar, keeper, variant, room?)   each frame: the keeper of this try (nil out of one), "A" | "B" | "Off",
--                                               and B's room in the band, authored pixels
--   BossBar.Shown(bar)                          for tests: 0 hidden to 1 whole, and what's showing ("", "Stamp", "In",
--                                               "Whole", "Leave")
--   BossBar.Trail(bar)                          for tests: the trail's share of the bar, and the fill's
--   BossBar.Foot(bar) -> number?                 B's foot in the band, authored pixels, while a keeper's bar holds the
--                                               top middle (the run's line steps under it: StageController); else nil


local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local EffectsConfig = require(Shared.Config.Effects)
local UIKit = require(Shared.Config.UIKit)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Grounds = require(Shared.Definitions.Grounds)
local Hud = require(Shared.Rules.Hud)
local Theme = require(script.Parent.Theme)
local Text = require(script.Parent.Kit.Text)
local Skin = require(script.Parent.Kit.Skin)

type Fade = { Object: Instance, Property: string, Base: number, Name: boolean }

export type Bar = {
	Frame: Frame, -- the bar and its number: a piece of the HUD of its own
	Head: Frame, -- the title and the name, another
	Title: TextLabel,
	Rules: { ImageLabel }, -- the title's two rules
	Crest: ImageLabel, -- over the title's middle
	NameRow: Frame, -- the gem, the name and the level, stamped on together
	NameScale: UIScale,
	Gem: ImageLabel,
	Name: TextLabel,
	Level: TextLabel,
	Number: TextLabel,
	Glow: Frame,
	Channel: Frame,
	Rim: ImageLabel, -- the channel's rim, over the fill's edge
	Trail: Frame,
	Fill: Frame,
	Shine: Frame,
	ShineGradient: UIGradient,
	Caps: { ImageLabel },
	Fades: { Fade },
	Keeper: Model?, -- the one it shows
	Done: Model?, -- the one it last showed out: never opened again
	Variant: string, -- the layout it's laid in
	Width: number, -- and its width
	High: number, -- the bar's height
	Fit: number, -- the name row's scale to fit the width
	Fitted: string,
	StampAt: number, -- os.clock() its name stamps on
	GoneAt: number?, -- os.clock() it leaves from: the fall's Gone
	Phase: string,
	Shown: number,
	Share: number, -- the fill's share of the bar
	TrailShare: number, -- the trail's
	HeldUntil: number, -- os.clock() the trail starts to drain
	Clock: number, -- the last step's
}

local BossBar = {}

local TITLE = 16 -- the title's row, authored pixels
local GEM, GAP = 20, 6 -- the type's gem; between the gem, the name and the level
local INSET = 9 -- the bar's ends in from the piece's, room for its caps
local GLOW = 4 -- the glow past the bar, above and below
local ART = UIKit.BossBar -- the frames as drawn: the bar's height they were drawn for, a cap's box, the crest's
local RULES = { "BossTitleRuleLeft", "BossTitleRuleRight" }
local RULE_GAP = 8 -- between a rule's taper and the title
local CREST_INTO = 2 -- the crest's foot this far into the title row's top
local EDGE = 0.25 -- the dark edge's transparency on the words
local DARK = Theme.Colour.Backing

local function capital(s: string): string
	return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

-- "Keeper of Lantern Row": the ground whose keeper it is (Definitions.Grounds).
local function titleOf(def: string): string
	for _, ground in Grounds.List do
		if ground.Keeper == def then
			return `Keeper of {ground.Name}`
		end
	end
	return "Keeper"
end

local function ease(x: number): number
	local t = math.clamp(x, 0, 1)
	return 1 - (1 - t) ^ 4 -- Quart out, Theme.Motion's curve
end

local function measure(label: TextLabel): number
	return Text.Wide(label, label.Text)
end

function BossBar.new(parent: Instance): Bar
	local boss = HudConfig.Boss
	local look = boss.Look
	local fades: { Fade } = {}
	local function fade(object: Instance, property: string, base: number, name: boolean?)
		table.insert(fades, { Object = object, Property = property, Base = base, Name = name == true })
	end
	-- A dark edge on a label over the world, so it reads on Lantern Row's pale floor (TR5's first take).
	local function edged(label: TextLabel, thickness: number, name: boolean?)
		local edge = Instance.new("UIStroke")
		edge.Name = "Edge"
		edge.Color = DARK
		edge.Thickness = thickness
		edge.Parent = label
		fade(label, "TextTransparency", 0, name)
		fade(edge, "Transparency", EDGE, name)
	end
	-- One of Modulo's frames, white tinted the rim's lilac; its dark hairline is baked in, so it reads on a pale floor.
	-- Laid where `lay` and `fit` put it.
	local function art(holder: Instance, name: string, kit: string, z: number, base: number): ImageLabel
		local image = Instance.new("ImageLabel")
		Skin.Set(image, kit, {})
		image.Name = name
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.ImageColor3 = boss.Rim
		image.ZIndex = z
		image.Parent = holder
		fade(image, "ImageTransparency", base)
		return image
	end

	local frame = Instance.new("Frame")
	frame.Name = "Keeper"
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	local head = Instance.new("Frame")
	head.Name = "KeeperHead"
	head.BackgroundTransparency = 1
	head.Visible = false
	head.Parent = parent

	-- The title between its rules, the crest over its middle: one ornament.
	local title = Text.new({ Name = "Title", Size = Theme.Text.Caption, Colour = boss.Title, Align = Enum.TextXAlignment.Center, Parent = head })
	edged(title, 1.5)
	local rules: { ImageLabel } = {}
	for i, kit in RULES do
		table.insert(rules, art(head, `Rule{i}`, kit, 1, look.Rule))
	end
	local crest = art(head, "Crest", "BossTitleCrest", 2, look.Rule)

	-- The gem, the name and the level, one row that stamps on.
	local row = Instance.new("Frame")
	row.Name = "NameRow"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Parent = head
	local scale = Instance.new("UIScale")
	scale.Parent = row
	local gem = Instance.new("ImageLabel")
	gem.Name = "Gem"
	gem.BackgroundTransparency = 1
	gem.AnchorPoint = Vector2.new(0, 0.5)
	gem.Size = UDim2.fromOffset(GEM, GEM)
	gem.Parent = row
	fade(gem, "ImageTransparency", 0, true)
	local name = Text.new({ Name = "Name", Size = Theme.Text.Title, Font = Theme.Font.Strong, Colour = Color3.new(1, 1, 1), Parent = row })
	edged(name, 2, true)
	local purple = Instance.new("UIGradient") -- on the words; the dark edge keeps its own colour
	purple.Rotation = 90
	purple.Color = ColorSequence.new(boss.Name[1], boss.Name[2])
	purple.Parent = name
	local level = Text.new({ Name = "Level", Size = Theme.Text.Caption, Colour = HudConfig.Card.Level, Parent = row })
	edged(level, 1.5, true)

	-- The bar: its glow, its channel, the trail, the fill lit from above, the shine; its rim and its caps over them.
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundColor3 = boss.Health
	glow.BorderSizePixel = 0
	glow.Parent = frame
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = glow
	local spread = Instance.new("UIGradient")
	spread.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	spread.Parent = glow
	fade(glow, "BackgroundTransparency", look.Glow)
	local channel = Instance.new("Frame")
	channel.Name = "Channel"
	channel.BackgroundColor3 = Theme.Colour.Channel
	channel.BorderSizePixel = 0
	channel.ClipsDescendants = true
	channel.ZIndex = 2
	channel.Parent = frame
	fade(channel, "BackgroundTransparency", look.Channel)
	local trail = Instance.new("Frame")
	trail.Name = "Trail"
	trail.BackgroundColor3 = boss.Trail
	trail.BorderSizePixel = 0
	trail.Size = UDim2.fromScale(1, 1)
	trail.ZIndex = 2
	trail.Parent = channel
	fade(trail, "BackgroundTransparency", 0.15)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.ZIndex = 3
	fill.Parent = channel
	local lit = Instance.new("UIGradient")
	lit.Rotation = 90
	lit.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, boss.Light),
		ColorSequenceKeypoint.new(0.45, boss.Health),
		ColorSequenceKeypoint.new(1, boss.Deep),
	})
	lit.Parent = fill
	fade(fill, "BackgroundTransparency", 0)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(1, 1)
	shine.ZIndex = 4
	shine.Visible = false
	shine.Parent = channel
	local sweep = Instance.new("UIGradient")
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sweep.Parent = shine
	-- The rim over the channel and all in it (its dark inner line lies over the fill's edge), the caps over the rim.
	local rim = art(frame, "Rim", "BossBarRim", 4, look.Rim)
	local caps = { art(frame, "CapLeft", "BossBarCap", 5, look.Rim), art(frame, "CapRight", "BossBarCap", 5, look.Rim) }
	local number = Text.new({ Name = "Number", Size = Theme.Text.Caption, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, Parent = frame })
	number.ZIndex = 6
	edged(number, 1.5)

	local bar: Bar = {
		Frame = frame,
		Head = head,
		Title = title,
		Rules = rules,
		Crest = crest,
		NameRow = row,
		NameScale = scale,
		Gem = gem,
		Name = name,
		Level = level,
		Number = number,
		Glow = glow,
		Channel = channel,
		Rim = rim,
		Trail = trail,
		Fill = fill,
		Shine = shine,
		ShineGradient = sweep,
		Caps = caps,
		Fades = fades,
		Keeper = nil,
		Done = nil,
		Variant = "",
		Width = 0,
		High = 0,
		Fit = 1,
		Fitted = "",
		StampAt = 0,
		GoneAt = nil,
		Phase = "",
		Shown = 0,
		Share = 1,
		TrailShare = 1,
		HeldUntil = 0,
		Clock = 0,
	}
	return bar
end

-- The name row cut to its words, and the title's rules to the room beside the title: measured at the sizes the labels
-- draw (they grow on a small phone). Nothing when unchanged.
local function fit(bar: Bar)
	local key = `{bar.Name.Text}\0{bar.Level.Text}\0{bar.Title.Text}\0{bar.Name.TextSize}\0{bar.Title.TextSize}\0{bar.Width}\0{bar.Name.FontFace.Family}\0{bar.Name.FontFace.Weight.Value}\0{Text.Epoch()}`
	if bar.Fitted == key then
		return
	end
	bar.Fitted = key
	local high = bar.NameRow.Size.Y.Offset
	local named = measure(bar.Name) + 2
	local levelled = if bar.Level.Text ~= "" then measure(bar.Level) + 2 else 0
	local gem = if bar.Gem.Visible then GEM + GAP else 0
	local total = gem + named + (if levelled > 0 then GAP + levelled else 0)
	bar.NameRow.Size = UDim2.fromOffset(total, high)
	bar.Gem.Position = UDim2.fromOffset(0, high / 2)
	bar.Name.Size = UDim2.fromOffset(named, high)
	bar.Name.Position = UDim2.fromOffset(gem, 0)
	bar.Level.Size = UDim2.fromOffset(levelled, high)
	bar.Level.Position = UDim2.fromOffset(gem + named + GAP, 1)
	bar.Fit = math.min(1, (bar.Width - 8) / math.max(total, 1))
	-- Each rule's box: from its tip's outer point at the piece's edge to its taper's end, RULE_GAP short of the title; it
	-- shows while the box holds its tip and its taper unstretched.
	local reach = (bar.Width - measure(bar.Title)) / 2 - RULE_GAP
	for i, rule in bar.Rules do
		local kit = RULES[i]
		local im = UIKit.Images[kit]
		local cut = im.Cut :: { number }
		local tall = im.Points.Y - 2 * im.Pad
		rule.Visible = reach >= cut[1] + cut[3] - 2 * im.Pad
		if rule.Visible then
			Skin.Set(rule, kit, { X = if i == 1 then 0 else bar.Width - reach, Y = (TITLE - tall) / 2, W = reach, H = tall })
		end
	end
end

-- Laid for a variant, as two pieces of the HUD that never overlap another (the UI lint): the title and the name over
-- the bar, the number in the bar's middle. A at the foot; B in the band's middle, all inside the band.
local function lay(bar: Bar, variant: string, room: number?)
	local boss = HudConfig.Boss
	local width = if variant == "A" then boss.Foot.Width else math.floor(math.clamp(room or boss.Top.Most, 160, boss.Top.Most))
	if bar.Variant == variant and bar.Width == width then
		return
	end
	bar.Variant, bar.Width = variant, width
	local frame, head = bar.Frame, bar.Head
	local high = if variant == "A" then boss.Foot.Bar else boss.Top.Bar
	bar.High = high
	local nameHigh = if variant == "A" then 34 else 26
	head.Size = UDim2.fromOffset(width, TITLE + nameHigh)
	bar.Title.Size = UDim2.fromOffset(width, TITLE)
	bar.Title.Position = UDim2.fromOffset(0, 0)
	bar.NameRow.Size = UDim2.fromOffset(width, nameHigh)
	bar.NameRow.Position = UDim2.fromOffset(width / 2, TITLE + nameHigh / 2)
	Text.Resize(bar.Name, if variant == "A" then Theme.Text.Big else Theme.Text.Title)
	local tall = GLOW * 2 + high
	frame.Size = UDim2.fromOffset(width, tall)
	bar.Glow.Size = UDim2.fromOffset(width, tall)
	bar.Glow.Position = UDim2.fromOffset(0, 0)
	local long = width - INSET * 2
	bar.Channel.Size = UDim2.fromOffset(long, high)
	bar.Channel.Position = UDim2.fromOffset(INSET, GLOW)
	Skin.Set(bar.Rim, "BossBarRim", { X = INSET, Y = GLOW, W = long, H = high })
	-- The caps scale with the bar from the height they were drawn for, centred on the channel's ends.
	local middle = GLOW + high / 2
	local s = high / ART.Height
	for i, cap in bar.Caps do
		local x = if i == 1 then INSET else width - INSET
		Skin.Set(cap, "BossBarCap", { X = x - ART.Cap.X * s / 2, Y = middle - ART.Cap.Y * s / 2, Scale = s })
	end
	-- The crest's foot's middle CREST_INTO down into the title row's top middle: it stands above the head's box.
	Skin.Set(bar.Crest, "BossTitleCrest", { X = (width - ART.Crest.X) / 2, Y = CREST_INTO - ART.Crest.Y })
	bar.Number.Size = UDim2.fromOffset(long, high)
	bar.Number.Position = UDim2.fromOffset(INSET, GLOW)
	if variant == "A" then
		frame.AnchorPoint = Vector2.new(0.5, 1)
		frame.Position = UDim2.new(0.5, 0, 1, -boss.Foot.Above)
		head.AnchorPoint = Vector2.new(0.5, 1)
		head.Position = UDim2.new(0.5, 0, 1, -boss.Foot.Above - tall)
	else
		head.AnchorPoint = Vector2.new(0.5, 0)
		head.Position = UDim2.new(0.5, 0, 0, boss.Top.Y)
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.new(0.5, 0, 0, boss.Top.Y + TITLE + nameHigh + 1)
	end
	bar.Fitted = ""
end

local function opacity(bar: Bar, name: number, rest: number)
	for _, f in bar.Fades do
		(f.Object :: any)[f.Property] = 1 - (1 - f.Base) * (if f.Name then name else rest)
	end
	bar.Shown = rest
end

local function clear(bar: Bar)
	bar.Keeper = nil
	bar.GoneAt = nil
	bar.Phase = ""
	bar.Frame.Visible = false
	bar.Head.Visible = false
	bar.Shine.Visible = false
	opacity(bar, 0, 0)
end

local function shareOf(model: Model): number
	local health, most = model:GetAttribute("Health"), model:GetAttribute("MaxHealth")
	local h = if type(health) == "number" then health else 0
	local m = if type(most) == "number" then most else 0
	return if m > 0 then math.clamp(h / m, 0, 1) else 0
end

function BossBar.Step(bar: Bar, keeper: Model?, variant: string, room: number?)
	local boss = HudConfig.Boss
	if variant ~= "A" and variant ~= "B" then
		clear(bar)
		return
	end
	local clock = os.clock()
	local dt = math.clamp(clock - bar.Clock, 0, 0.1)
	bar.Clock = clock
	if keeper and keeper ~= bar.Keeper and keeper.Parent and keeper ~= bar.Done and keeper:GetAttribute("State") ~= "Down" then
		-- A new keeper: its name stamps on as its Challenge's Stamp lands, or at once if it's past it.
		clear(bar)
		bar.Keeper = keeper
		local def = tostring(keeper:GetAttribute("Def") or "")
		bar.Name.Text = capital(tostring(keeper:GetAttribute("Title") or ""))
		bar.Title.Text = titleOf(def)
		local level = keeper:GetAttribute("Level")
		bar.Level.Text = if level ~= nil then `Lv {tostring(level)}` else ""
		local kind = keeper:GetAttribute("Type")
		local image = if type(kind) == "string" then UIKit.Images[`Gem{kind}`] else nil
		bar.Gem.Image = if image then image.Id else ""
		bar.Gem.Visible = image ~= nil
		bar.Fitted = ""
		local row = Enemies.ById[def]
		local enter = if row and row.Enter then Actions.ById[row.Enter] else nil
		local stamp = if enter then enter.Beats.Stamp else nil
		local at = keeper:GetAttribute("ActionAt")
		if enter and stamp and keeper:GetAttribute("Action") == enter.Id and type(at) == "number" then
			bar.StampAt = clock + math.max(0, at + stamp - workspace:GetServerTimeNow())
		else
			bar.StampAt = clock
		end
		local share = shareOf(keeper)
		bar.Share, bar.TrailShare, bar.HeldUntil = share, share, 0
	end
	local shown = bar.Keeper
	if shown == nil then
		clear(bar)
		return
	end
	lay(bar, variant, room)
	fit(bar)
	-- It leaves from the fall's Gone, or at once when the try ends with it standing.
	if bar.GoneAt == nil then
		if shown:GetAttribute("State") == "Down" then
			local fall = EffectsConfig.Falls[tostring(shown:GetAttribute("Rig"))]
			bar.GoneAt = clock + (if fall then fall.Gone / 60 else 0)
		elseif keeper == nil or shown.Parent == nil then
			bar.GoneAt = clock
		end
	end
	-- The fill at once; the trail holds after a hit, then drains to it (Config.Hud.Boss.Drain).
	local share = shareOf(shown)
	if share < bar.Share - 1e-4 then
		bar.HeldUntil = clock + boss.Drain.Hold
	end
	bar.Share = share
	if share >= bar.TrailShare then
		bar.TrailShare = share
	elseif clock >= bar.HeldUntil then
		bar.TrailShare = math.max(share, bar.TrailShare - boss.Drain.Rate * dt)
	end
	bar.Fill.Size = UDim2.fromScale(share, 1)
	bar.Trail.Size = UDim2.fromScale(bar.TrailShare, 1)
	local health, most = shown:GetAttribute("Health"), shown:GetAttribute("MaxHealth")
	bar.Number.Text = Hud.Health(if type(health) == "number" then health else 0, if type(most) == "number" then most else 0, 24, true)
	local since = clock - bar.StampAt
	if since < 0 then
		bar.Frame.Visible = false
		bar.Head.Visible = false
		bar.Shine.Visible = false
		bar.Phase = ""
		opacity(bar, 0, 0)
		return
	end
	bar.Frame.Visible = true
	bar.Head.Visible = true
	local stamp = boss.Stamp
	local name = ease(since / stamp.Seconds)
	bar.NameScale.Scale = (stamp.From + (1 - stamp.From) * name) * bar.Fit
	local rest = ease((since - stamp.Seconds) / stamp.Fill)
	bar.Phase = if since < stamp.Seconds then "Stamp" elseif rest < 1 then "In" else "Whole"
	-- The shine crosses the bar once, as the rest comes in.
	local across = (since - stamp.Seconds) / boss.Shine.Seconds
	bar.Shine.Visible = across > 0 and across < 1
	bar.ShineGradient.Offset = Vector2.new(-1 + 2 * ease(across), 0)
	local leaving = 1
	if bar.GoneAt and clock >= bar.GoneAt then
		leaving = 1 - math.clamp((clock - bar.GoneAt) / boss.Leave, 0, 1)
		bar.Phase = "Leave"
		if leaving <= 0 then
			bar.Done = shown
			clear(bar)
			return
		end
	end
	opacity(bar, name * leaving, rest * leaving)
end

function BossBar.Shown(bar: Bar): (number, string)
	return if bar.Frame.Visible then bar.Shown else 0, bar.Phase
end

function BossBar.Trail(bar: Bar): (number, number)
	return bar.TrailShare, bar.Share
end

function BossBar.Foot(bar: Bar): number?
	if bar.Keeper == nil or bar.Variant ~= "B" then
		return nil
	end
	local frame = bar.Frame
	return frame.Position.Y.Offset + frame.Size.Y.Offset
end

return BossBar
