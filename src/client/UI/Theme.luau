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
}

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

-- How long things stay (docs/ui.md, rule 2: quiet until it matters).
Theme.Time = {
	Toast = 2.5, -- one line, then it leaves
	Toasts = 2, -- stacked at most
	Fight = 6, -- seconds since the last hit that still count as in a fight
}

return Theme
