--!strict
-- Theme (client): every colour, font, size and motion value the screens use, as named tokens (handbook/visuals/ui.md,
-- "Engineering"). The kit's look (AR3, docs/ui.md, "One look, ours") restyles this file and the kit, never a screen: the
-- ink and the lights come from Config.UIKit's Graphite Dark, the face is Builder Sans (TR3). Sizes are authored at
-- Theme.Author, a phone held sideways.

local UIKit = require(game:GetService("ReplicatedStorage").Shared.Config.UIKit)
local GRAPHITE = UIKit.Palettes.Graphite

local Theme = {}

-- The screen every layout is authored at: Roblox's report of a phone held sideways (handbook/visuals/ui.md, "Phones").
Theme.Author = Vector2.new(812, 375)
-- The smallest phone held sideways, in Roblox's report (iPhone SE, first generation): 320 high draws at the scale's floor.
Theme.Smallest = Vector2.new(568, 320)
Theme.Scale = {
	Floor = 0.85, -- the smallest a layer draws: a tap authored at Size.Tap still holds Size.Touch there
	CapSmall = 1.3, -- the largest on a small screen
	Cap = 1.5,
}

Theme.Colour = {
	Backing = Color3.fromRGB(18, 20, 25), -- behind a full screen
	Plate = Color3.fromRGB(32, 35, 42), -- a panel
	PlateHigh = Color3.fromRGB(46, 50, 59), -- a row inside a panel, a button at rest
	Pressed = Color3.fromRGB(62, 67, 79),
	Line = Color3.fromRGB(92, 98, 112), -- a panel's edge
	Text = GRAPHITE.Text, -- ivory
	TextDim = GRAPHITE.Soft,
	Disabled = GRAPHITE.Faint,
	Primary = Color3.fromRGB(96, 170, 236), -- the one action a screen asks for
	Electricity = UIKit.Charge,
	Credits = Color3.fromRGB(238, 198, 92),
	Ready = Color3.fromRGB(246, 222, 128),
	Channel = Color3.fromRGB(14, 15, 19), -- a bar's empty
	-- Damage numbers (docs/ui.md, "The HUD, in the world").
	Hit = Color3.fromRGB(240, 236, 226),
	Critical = Color3.fromRGB(246, 202, 84),
	Heal = Color3.fromRGB(120, 222, 130),
	Dodge = Color3.fromRGB(150, 154, 162),
	Hurt = Color3.fromRGB(255, 120, 110), -- a hit on the player's own lead
	Over = Color3.fromRGB(255, 150, 92), -- power: demand over generation (TR18, grey until AR12's pick)
	-- A colour that's both a light and a word is two values (AR40, "The system panel in A, B and C"): the light in a bar or
	-- a fill above, the word on the panel here. Today each word is its light's colour (the word on a ready fill, the ink).
	ReadyWords = Color3.fromRGB(18, 20, 25), -- the word on a ready fill
	ElectricityWords = UIKit.Charge,
	OverWords = Color3.fromRGB(255, 150, 92),
}

-- A screen's colours on a palette of its own (UIKit's System, AR40's C): Theme.Colour with its ink (Text, Soft and
-- Faint as Text, TextDim and Disabled), its rows (Row as PlateHigh) and its lights and their words from the palette's
-- keys of those names. Theme.Colour itself without one. Read when a screen is built, so a live tune reaches the next.
local INKED = { "Backing", "Channel", "Ready", "ReadyWords", "Electricity", "ElectricityWords", "Over", "OverWords" }
function Theme.Ink(palette: string?): typeof(Theme.Colour)
	local p = if palette then (UIKit.Palettes :: any)[palette] else nil
	if p == nil then
		return Theme.Colour
	end
	local ink = table.clone(Theme.Colour)
	ink.Text, ink.TextDim, ink.Disabled = p.Text or ink.Text, p.Soft or ink.TextDim, p.Faint or ink.Disabled
	ink.PlateHigh = p.Row or ink.PlateHigh
	for _, key in INKED do
		if p[key] ~= nil then
			(ink :: any)[key] = p[key]
		end
	end
	return ink
end

Theme.Transparency = {
	Plate = 0.08, -- 92% opaque: ".12 looks too solid" reads the other way round
	Dim = 0.45, -- the world behind a reveal
}

Theme.Font = {
	Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	Strong = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
	Number = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold),
}

-- Authored text sizes, in pixels at Theme.Author.
Theme.Text = {
	Caption = 14,
	Body = 16,
	Title = 20,
	Big = 28,
	Minimum = 14, -- rendered, for every label (docs/ui.md: text 14 px or more)
}

Theme.Size = {
	Gap = 6,
	Pad = 8,
	Corner = 4, -- grey: a plain round; the shard-cut chamfer is the finished kit's
	Edge = 1, -- a panel's line
	Tap = 52, -- a touch target's least side, authored: 44 rendered at the scale's floor (Touch / Scale.Floor, up)
	Touch = 44, -- a touch target's least side, rendered (docs/ui.md: 44 px or more); the UI lint holds every button to it
	Bar = 8, -- a bar's height
}

-- Motion: the only tween speeds (handbook/visuals/ui.md, "Motion helper").
Theme.Motion = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Base = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

-- The style frame (AR62; research's pick, 2026-11-26, 14:24: A, Graphite, with the shard cut): the tokens every screen's
-- redo derives from, a screen at a time (build/handoff/UI/style_frames/A_home_cut.png and A_tokens.png, drawn by
-- tools/ui/style_frames.py, its TAKES.A). Until a screen moves onto them it keeps Theme.Colour, and the UI lint
-- (UiLint.Strays, TR63) names what it draws off them. Sizes are authored, at Theme.Author: the frame is drawn at 852 x
-- 480, which the layer draws at 480 / 375 of authored, so each is the frame's over 1.28, its frame number beside it.
local function hex(code: string): Color3
	return Color3.fromHex(code)
end
Theme.Frame = {
	-- Dark and quiet, never black: warm graphite, ivory words, one ivory press. The art is the light.
	Neutral = {
		Dim = hex("#17181C"), -- the dim behind a screen
		Panel = hex("#23252B"),
		Raised = hex("#30333B"), -- a button at rest
		Rim = hex("#4A4F5A"),
		Second = hex("#A9AEB8"), -- second words
		Words = hex("#F3EEE4"), -- words, and the press
	},
	-- Matte graphite: a soft top-down gradient, a thin rim, a hairline of light along the top edge.
	Panel = { Top = hex("#2C2F36"), Bottom = hex("#202227"), Hairline = Color3.new(1, 1, 1), HairlineAlpha = 0.07, Shadow = 0.45 },
	-- The one press a screen asks for, ivory with dark ink (its words in Font.Display).
	Press = { Top = hex("#F3EEE4"), Bottom = hex("#DCD5C6"), Ink = hex("#1B1C20") },
	-- Hues, one job each: Alive for what's alive or for sale, only there (the director, six times: too purple).
	Hue = { Power = hex("#FFC83D"), Alive = hex("#B784FF"), Health = hex("#E8505B") },
	Health = { Top = hex("#F06A6E"), Bottom = hex("#C93C48") }, -- the health bar's fill
	-- Pictures sit on their own lit grounds inside the panel, top to bottom (Modulo's must-fixes 1 and 2: Today on the
	-- panel's graphite, Equipment on a dim bronze so the gold lives in the sword).
	Ground = {
		Stage = { hex("#ECE5D6"), hex("#B8B0A0") },
		Equipment = { hex("#80684A"), hex("#38322B") },
		Today = { hex("#30333B"), hex("#202227") },
	},
	DimShade = 0.55, -- how dark the world goes behind a screen, as an opacity of Neutral.Dim
	Blur = 7, -- and how soft, in the frame's pixels
	-- Content's own colours, as the tokens page shows them.
	Rarity = {
		Common = hex("#A7AEBB"),
		Uncommon = hex("#5FD98A"),
		Rare = hex("#58A9FF"),
		Epic = hex("#B784FF"),
		Legendary = hex("#FFC94A"),
		Mythical = hex("#FF6A82"),
	} :: { [string]: Color3 },
	Types = {
		Red = hex("#EA4B4F"),
		Orange = hex("#F4902A"),
		Blue = hex("#3F9DF2"),
		Purple = hex("#A470F2"),
		Green = hex("#42CC7E"),
	} :: { [string]: Color3 },
	-- Two faces: Oswald for names, titles and presses, in capitals; Builder Sans for numbers and the rest.
	Font = {
		Display = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold),
		Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
	},
	Upper = true, -- the display face's words in capitals
	Text = { Small = 14, Middle = 20, Large = 30 }, -- 18, 26, 38 in the frame
	Radius = { Panel = 11, Card = 8, Pill = 16 }, -- 14, 10, 20 in the frame
	Stroke = { Rim = 1.2, Hairline = 0.9 }, -- 1.5 and 1.2 in the frame
	-- The shard cut (docs/ui.md, rule 3): a panel's, card's or clip's top-left and bottom-right corners cut on the
	-- diagonal, Share of its radius along each side, the other two square. A piece under Least a side, or with a radius
	-- under LeastRadius, or a pill, a bar or a small mark, keeps its round.
	Cut = { Share = 0.9, Least = 23, LeastRadius = 5 }, -- 30 and 6 in the frame
}

-- How long things stay (docs/ui.md, rule 2: quiet until it matters).
Theme.Time = {
	Toast = 2.5, -- one line, then it leaves
	Toasts = 2, -- stacked at most
	Fight = 6, -- seconds since the last hit that still count as in a fight
}

return Theme
