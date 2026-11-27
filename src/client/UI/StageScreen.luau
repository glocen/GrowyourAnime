--!strict
-- StageScreen (client): the Festival of Battles' Arc panel and a run's card, in Seam's lit glass (AR42; TR43, TR50).
-- Laid on Modulo's cut (tools/blender/stage_seam.py; build/handoff/UI/stages/stages.json), its numbers in
-- Config.Hud.Stages, its pieces the glass kit's (UI/Kit/Glass). Two faces of one full screen:
-- * The Arc panel, from the dock's Play or the Festival Door (StageService's StagePick): one tile for the ground (one
--   mission per Arc, the director's word of 2026-11-19, 23:19), its keeper's picture on its bed and its name, and beside
--   it Normal and Hard, one press each. A choice shows the Combat Power its run recommends (its keeper's,
--   Rules.Stages.Recommended), the run's four marks lit to its checkpoint and ringing it, and where the next run starts
--   ("Stretch 3 of 4"); Hard while shut, its lock and why. A press begins its run there (Net Stage); the player's own
--   power stands at the foot. Hard's one accent is an ember; it keeps Normal's value.
-- * The card, at a run's end (StageDone): a glass card over the street dimmed. The run's marks, all checked and the
--   keeper's just, or lit to where the next run starts after a fall; the ground cleared and the run's time (a new best in
--   Ready's gold, a best only for a run from the first stretch), what the run gave, and Retry, Hard and Home, the one
--   press lit. After the keeper on Normal, the lit press is Hard; on the card whose clear opened Hard, the press comes in
--   shut under Hard's lock, which lifts off as the press lights (research's lines of 2026-11-24, TR54: news shown by the
--   thing that changed, never a banner). A lost run names its lead ("Kirra fell") and where the next run starts, over
--   three presses (docs/design.md, "A fall in the Festival"): Retry, lit while someone leads, else dim with the time the
--   fallen lead heals in and lighting by itself once someone leads (a tap while dim answers nothing, never a refusal);
--   Send another, the picker of who's ready (the card comes back when it closes: StageController); and Home.
--   StageScreen.Pick(ground, view, on)    the Arc panel
--   StageScreen.Results(results, on)     the run's card
--   StageScreen.NewBest(results)         whether the card says "New best": won, timed, and its best its own time
--   StageScreen.Parts()                  its pieces by name, for tests
--   StageScreen.Difficulty()             the difficulty last begun from the panel

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Stages = require(Shared.Rules.Stages)
local Refusal = require(Shared.Rules.Refusal)
local Stats = require(Shared.Rules.Stats)
local Grounds = require(Shared.Definitions.Grounds)
local Enemies = require(Shared.Definitions.Enemies)
local Hud = require(Shared.Rules.Hud)
local Sheet = require(Shared.Rules.Sheet)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local StagesConfig = require(Shared.Config.Stages)
local GoalDefs = require(Shared.Definitions.Goals)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Layers = require(UI.Layers)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)
local Text = require(UI.Kit.Text)

local StageScreen = {}
StageScreen.Name = "Stages"

export type On = {
	Begin: (ground: string, difficulty: string, alone: boolean?) -> { [string]: any }, -- Net Stage: the run, at its checkpoint (`alone`: the Keeper alone)
	Home: () -> { [string]: any }, -- Net Home
	Say: (words: string, refused: boolean?) -> (), -- a toast; grey when it's a refusal (TR71 B)
	-- whether someone leads now, standing; else the server time the fallen lead is whole, when it's healing at home
	Lead: () -> (boolean, number?),
	Another: () -> (), -- the picker of who's ready to lead
}

local LOOK = HudConfig.Stages
local SEAM = UIKit.Palettes.SeamGlass
local TILE, BED, BADGE, ROAD, ARC, MOTION = LOOK.Tile, LOOK.Bed, LOOK.Badge, LOOK.Road, LOOK.Arc, LOOK.Motion
local SMALL, TITLE, BIG = LOOK.Text.Small, LOOK.Text.Title, LOOK.Text.Big
local W, T = LOOK.Block.Wide, LOOK.Block.Top -- the cut's width; its band's foot, where a block's y starts
local MARGIN = 18 -- round the tile's group: its glow stands past it
local WHITE = Color3.new(1, 1, 1)
local INK = SEAM.Ink :: Color3
local CHEVRONS = UIKit.Images.LevelChevrons :: UIKit.Image
local ALONE = { Tall = 44, Caption = 16, Press = 24, Gap = 4 } -- the Keeper alone's strip at the bed's foot (TR74's grey block)
local LOCK = HudConfig.Voidkin.Chrome.Images.LockOn :: UIKit.Image -- the closed shackle: shut (research's must-fix 1 on TR50)
local CHEVRON = UIKit.Images.ChevronSingle :: UIKit.Image
local IMAGES = LOOK.Images :: { [string]: UIKit.Image }
local LIT_NORMAL = (function(): ColorSequence
	local points = {}
	for _, stop in HudConfig.Make.Lit.Fill do
		table.insert(points, ColorSequenceKeypoint.new(stop[1] :: number, Color3.fromHex(stop[2] :: string)))
	end
	return ColorSequence.new(points)
end)()

local parts: { [string]: Instance } = {}
local hudBack = false -- the card has set the HUD aside; it comes back when the screen closes
local difficulty = "Normal"

type Accent = typeof(LOOK.Accent.Normal)
local function accent(hard: boolean): Accent
	return if hard then LOOK.Accent.Hard else LOOK.Accent.Normal
end
-- A lit plate's fill in a mode's light: Normal's is the kit's lit press's.
local function litFill(hard: boolean): Glass.Tint
	return if hard then LOOK.Accent.Hard.Lit else LIT_NORMAL
end

-- The keeper's name as a title: "the Lamplighter" reads "Lamplighter".
local function keeperName(ground: string): string
	local row = Grounds.ById[ground]
	local enemy = if row and row.Keeper then Enemies.ById[row.Keeper] else nil
	local name = if enemy then enemy.Name else "the keeper"
	name = string.gsub(name, "^[Tt]he ", "")
	return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

-- What a shut stretch or difficulty waits for, in the player's words: the one table's (Config.Refusals' Stages; TR71 B).
local function why(ground: string, needs: string?, waits: number?): string?
	if needs == nil then
		return nil
	elseif not Refusal.Has("Stages", needs) then
		return "Not here"
	end
	return Refusal.Words("Stages", needs, { Stage = waits, Keeper = keeperName(ground), Minutes = if waits then math.max(1, math.ceil(waits / 60)) else nil })
end

local function begin(on: On, ground: string, which: string, alone: boolean?): boolean
	local answer = on.Begin(ground, which, alone)
	if answer.Ok == true then
		Screen.Close()
		return true
	end
	-- Every refusal says something: a press that answers nothing reads as a broken one (the Play panel's too).
	local says = why(ground, answer.Needs, answer.Waits) or Refusal.Of("Stages", answer)
	on.Say(says, true)
	return false
end

-- The lead's Combat Power, or nil without one.
local function power(view: Profile.View): number?
	local data = view :: any
	local owned = data.Voidkin[data.Roles.Lead]
	if owned == nil then
		return nil
	end
	return Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
end

-- The cut's room under the band, scaled to the room the screen has, at most Grow, its middle the room's. Its height is
-- what it fits: a card taller than the cut's room grows it.
-- Back's underline in the screen's band in `colour` (the Arc panel's dusk), or its face's light again (nil).
local function underline(band: Frame?, colour: Color3?)
	local back = if band and band.Parent then band.Parent:FindFirstChild("Back") else nil
	if back and back:IsA("TextButton") then
		Button.Set(back, { Underline = colour or false })
	end
end

local function block(body: Frame, name: string, tall: number?): Frame
	local B = LOOK.Block
	local high = tall or B.Tall
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(W, high)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local menus = Layers.Get("Menus")
	local function refit()
		local room = menus.AbsoluteSize / Layers.Scale()
		if room.X > 0 and room.Y > 0 then
			scale.Scale = math.min(room.X / W, room.Y / frame.Size.Y.Offset, B.Grow)
		end
	end
	frame:GetPropertyChangedSignal("Size"):Connect(refit)
	local resized = menus:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	local rescaled = Layers.Changed:Connect(refit)
	frame.Destroying:Connect(function()
		resized:Disconnect()
		rescaled:Disconnect()
	end)
	refit()
	frame.Parent = body
	return frame
end

-- The light along a glass piece's top-left corner: its hairline in the glint, strongest 24 in from the corner.
local function cornerGlint(parent: Instance, name: string, x0: number, y0: number, w: number, h: number, cut: number, strength: number, z: number)
	local edge = Glass.Edge(parent, name, x0, y0, w, h, cut, SEAM.Glint, 1, nil, z)
	local angle = math.rad(35)
	local reach = w * math.cos(angle) + h * math.sin(angle)
	local points = {}
	for i = 0, 12 do
		local v = i / 12
		local d = math.abs(v * reach - 24 * math.cos(angle))
		table.insert(points, NumberSequenceKeypoint.new(v, math.clamp(1 - strength * math.exp(-d / 46), 0, 1)))
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 35
	gradient.Transparency = NumberSequence.new(points)
	gradient.Parent = edge
end

-- Hard's mark at the cut's size s (stage_screen.py's chevrons): two chevrons rising, from the kit's LevelChevrons, whose
-- pair spans 1.2 s in an image of 1.684 s, its middle 0.07 s above the image's; the cut's pair sits 0.115 s below cy. In
-- a holder the pair's own size, so it lays in a list.
local function chevrons(parent: Instance, name: string, cx: number, cy: number, s: number, colour: Color3, z: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromOffset(cx, cy)
	holder.Size = UDim2.fromOffset(1.2 * s, 1.2 * s)
	holder.ZIndex = z
	Glass.Mark(holder, "Image", CHEVRONS, 0.6 * s, 0.6 * s + 0.185 * s, 1.684 * s, colour, z)
	holder.Parent = parent
	return holder
end

-- Words with Hard's chevrons before them, centred in a box: the cut's press into Hard and the band's Hard half.
local function chevronWords(parent: Instance, name: string, words: string, size: number, colour: Color3, s: number, chevronColour: Color3, x0: number, y0: number, w: number, h: number, z: number): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(x0, y0)
	row.Size = UDim2.fromOffset(w, h)
	row.ZIndex = z
	row.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 7) -- read in game: the cut's 11 to the chevrons' middle left them touching the words
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	local mark = chevrons(row, "Chevrons", 0, 0, s, chevronColour, z)
	mark.LayoutOrder = 1
	local label = Glass.Label(row, "Words", words, size, colour, 0, 0, 0, h, nil, true, z)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = 2
	return row
end

-- A glass plate over the world: its shadow under it, lighter at its top, its hairline lit from above (the ember on
-- Hard), the corner glint. Laid at z to z + 4.
local function plate(parent: Instance, x0: number, y0: number, w: number, h: number, hard: boolean, cut: number, z: number)
	Glass.Glow(parent, "Shadow", x0, y0 + 3, w, h, 8, SEAM.Channel, LOOK.Card.Shadow, z)
	Glass.Fill(parent, "Glass", x0, y0, w, h, cut, TILE.Fill, z + 1)
	Glass.Wash(parent, "Sheen", x0, y0, w, h, cut, SEAM.Glint, function(at: number): number
		return TILE.Sheen.Alpha * math.exp(-at / TILE.Sheen.Fall)
	end, z + 2)
	Glass.Edge(parent, "Edge", x0, y0, w, h, cut, if hard then LOOK.Accent.Hard.Edge else SEAM.Facet, 0.95, 0.35, z + 3)
	cornerGlint(parent, "CornerGlint", x0, y0, w, h, cut, 0.85, z + 4)
end

-- A stage's mark: its number on a lit plate (or the well's, shut); on Hard, Hard's chevrons in a box beside it.
-- A node's square: lit in its difficulty's light, or dark.
local function square(parent: Instance, name: string, x0: number, y0: number, hard: boolean, lit: boolean, z: number)
	local s, a = BADGE.Side, accent(hard)
	if lit then
		Glass.Glow(parent, `{name}Glow`, x0, y0, s, s, BADGE.Glow, a.Glow, BADGE.GlowAlpha, z)
		Glass.Fill(parent, `{name}Fill`, x0, y0, s, s, BADGE.Corner, a.Lit, z + 1)
		Glass.Wash(parent, `{name}Top`, x0, y0, s, s, BADGE.Corner, WHITE, function(at: number): number
			return 0.5 * math.exp(-at / 4)
		end, z + 2)
		Glass.Edge(parent, `{name}Edge`, x0, y0, s, s, BADGE.Corner, WHITE, 0.9, nil, z + 3)
	else
		Glass.Fill(parent, `{name}Fill`, x0, y0, s, s, BADGE.Corner, SEAM.Well, z + 1)
		Glass.Edge(parent, `{name}Edge`, x0, y0, s, s, BADGE.Corner, SEAM.Edge, 1, nil, z + 3)
	end
end

local function badge(parent: Instance, name: string, x0: number, y0: number, n: number, hard: boolean, lit: boolean, z: number, ticked: boolean?)
	local s, a = BADGE.Side, accent(hard)
	square(parent, name, x0, y0, hard, lit, z)
	if not ticked then
		Glass.Label(parent, `{name}Number`, tostring(n), TITLE, if lit then INK else SEAM.Soft, x0, y0, s, s, nil, true, z + 4)
	end
	if hard then
		local bx = x0 + s + BADGE.Space
		Glass.Fill(parent, `{name}Hard`, bx, y0, BADGE.Box, s, 4, LOOK.HardBox, z + 1)
		Glass.Edge(parent, `{name}HardEdge`, bx, y0, BADGE.Box, s, 4, a.Edge, 1, nil, z + 3)
		chevrons(parent, `{name}Chevrons`, bx + BADGE.Box / 2, y0 + s / 2, 11, a.Edge, z + 4)
	end
end

-- The run's mark on its line: a lit square holding its difficulty's own, Hard's two chevrons or Normal's one, never a
-- second count beside "Stretch 2 of 4" (research's must-fix 3 on TR50).
local function mark(parent: Instance, name: string, x0: number, y0: number, hard: boolean, z: number)
	local s = BADGE.Side
	square(parent, name, x0, y0, hard, true, z)
	Glass.Mark(parent, `{name}Chevrons`, if hard then CHEVRONS else CHEVRON, x0 + s / 2, y0 + s / 2, BADGE.Mark, INK, z + 4)
end

-- A cleared stage's check: a lit disc, the kit's tick in ink, `tick` wide (r * 1.1 if nil).
local function check(parent: Instance, name: string, cx: number, cy: number, r: number, hard: boolean, z: number, tick: number?): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(cx, cy)
	holder.ZIndex = z
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	Glass.Disc(holder, "Disc", 0, 0, r, accent(hard).Lit, z)
	Glass.Mark(holder, "Tick", UIKit.Images.Tick, 0, 0, tick or r * 1.1, INK, z + 1)
	holder.Parent = parent
	return holder
end

-- A road's light from x0 to x1 (its colours spread to `span`), `half` each side of y: lit at its top edge, glowing; in a
-- holder that clips it, `Run` its share shown.
local function roadLight(parent: Instance, name: string, x0: number, x1: number, y: number, half: number, span: number, hard: boolean, z: number): (Frame, (run: number) -> ())
	local a = accent(hard)
	local reach = ROAD.Glow
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = true
	holder.Position = UDim2.fromOffset(x0 - reach * 2, y - half - reach * 2)
	holder.ZIndex = z
	local tall = 2 * half + reach * 4
	local lx, ly = reach * 2, reach * 2
	local long = math.max(x1 - x0, 1)
	Glass.Glow(holder, "Glow", lx, ly, long, 2 * half, reach, a.Edge, ROAD.GlowAlpha, z)
	local fill = Glass.Fill(holder, "Fill", lx, ly, long, 2 * half, math.min(2, half * 0.6), ColorSequence.new(a.Road[1], a.Road[1]:Lerp(a.Road[2], math.clamp(long / math.max(span, 1), 0, 1))), z + 1)
	local tint = fill:FindFirstChildOfClass("UIGradient")
	if tint then
		tint.Rotation = 0
	end
	Glass.Wash(holder, "Top", lx, ly, long, 2 * half, math.min(2, half * 0.6), WHITE, function(at: number): number
		return 0.35 * math.exp(-at / 1.2)
	end, z + 2)
	local light = Glass.Fill(holder, "Light", lx, ly, long, 2 * half, math.min(2, half * 0.6), WHITE, z + 3)
	local band = Instance.new("UIGradient")
	band.Transparency = Glass.Band(long, 14, ROAD.Light)
	band.Offset = Vector2.new(-2, 0)
	band.Parent = light
	Glass.Idle(light, function(phase: number)
		band.Offset = Vector2.new(phase - 0.5, 0)
	end)
	local function run(share: number)
		holder.Size = UDim2.fromOffset(lx + long * math.clamp(share, 0, 1) + (if share >= 1 then reach * 2 else 0), tall)
	end
	run(1)
	holder.Parent = parent
	return holder, run
end

-- The card's marks: the four stages on their road, lit to the one just cleared and on (`run`) to where the player now
-- stands, the next ringed in light, the one just cleared with its check.
local function marks(parent: Instance, x0: number, x1: number, y: number, rows: { string }, hard: boolean, z: number, kept: { number }?): (number) -> ()
	local a = accent(hard)
	local tab = if hard then BADGE.Box + BADGE.Space else 0
	local step = (x1 - x0 - 12 - BADGE.Side - tab) / 3
	local xs = {}
	for k = 1, 4 do
		xs[k] = x0 + 6 + (k - 1) * step
	end
	-- The track runs from node 1's middle to node 4's, under them: nothing past either end (research's must-fix 5).
	local half = BADGE.Side / 2
	local first, last = xs[1] + half, xs[#xs] + half
	Glass.Fill(parent, "MarksRoad", first, y - 3, last - first, 6, 1.5, SEAM.Channel, z)
	Glass.Edge(parent, "MarksRoadEdge", first, y - 3, last - first, 6, 1.5, SEAM.Edge, 0.9, nil, z)
	local nextK, just = table.find(rows, "next"), table.find(rows, "just")
	local stop = if nextK then xs[nextK] + half else last
	local start = if just then xs[just] + half else stop
	if nextK and just and nextK < just then
		start = stop
	end
	local _, run = roadLight(parent, "MarksLit", first, stop, y, 2, stop - first, hard, z + 1)
	local share0 = (start - first) / math.max(stop - first, 1)
	run(share0)
	local ringed: Frame? = nil
	for k, row in rows do
		local bx, by = xs[k], y - 13
		if row == "next" then
			local r = Instance.new("Frame")
			r.Name = "Ringed"
			r.BackgroundTransparency = 1
			r.Size = UDim2.fromScale(1, 1)
			r.ZIndex = z + 2 -- over the card's glass: its siblings' order is by ZIndex
			r.Parent = parent
			Glass.Glow(r, "Glow", bx - 3, by - 3, 32 + tab, 32, 6, a.Glow, 0.5, z + 2)
			Glass.Edge(r, "Edge", bx - 3, by - 3, 32 + tab, 32, 6, a.Edge, 1, nil, z + 2)
			Glass.Edge(r, "EdgeIn", bx - 2.2, by - 2.2, 30.4 + tab, 30.4, 5.2, a.Edge, 1, nil, z + 2)
			ringed = r
		end
		local ticked = row == "cleared" or row == "just"
		badge(parent, `Mark{k}`, bx, by, k, hard, row ~= "shut", z + 3, ticked)
		-- the tick inside its node, as its fill (research's must-fix 5)
		if row == "cleared" then
			check(parent, `Check{k}`, bx + half, by + half, 9, hard, z + 8, 15)
		elseif row == "just" then
			local made = check(parent, `Check{k}`, bx + half, by + half, 9, hard, z + 8, 15)
			Glass.Bloom(made, "Glow", 0, 0, 34, 34, a.Glow, 0.7, z + 7)
			parts.Just = made
		end
		-- a dare kept on this stretch in this run (TR54): its mark Gap right of the node, on the road's middle
		if kept and table.find(kept, k) then
			local D = LOOK.DareCard.Mark
			local record = UIKit.Images.DareMarkKept
			local dare = Instance.new("ImageLabel")
			dare.Name = `Dare{k}`
			dare.BackgroundTransparency = 1
			dare.Image = record.Id
			dare.AnchorPoint = Vector2.new(0.5, 0.5)
			dare.Position = UDim2.fromOffset(bx + BADGE.Side + tab + D.Gap, y)
			dare.Size = UDim2.fromOffset(record.Points.X * D.Scale, record.Points.Y * D.Scale)
			dare.ZIndex = z + 9
			dare:SetAttribute("Kit", "DareMarkKept")
			dare.Parent = parent
		end
	end
	local function play(u: number)
		-- u: 0 at the card's opening, 1 once the light has run on and the next is ringed
		run(share0 + (1 - share0) * u)
		if ringed then
			for _, image in ringed:GetChildren() do
				if image:IsA("ImageLabel") then
					local rest = if image.Name == "Glow" then 0.5 else 1
					image.ImageTransparency = 1 - rest * math.clamp((u - 0.75) / 0.25, 0, 1)
				end
			end
		end
	end
	play(0)
	return play
end

-- A word at its capitals' top y (the AR53 sheets' measure): its box centred on the capitals' middle.
local function capsLabel(parent: Instance, name: string, said: string, size: number, colour: Color3, x: number, y: number, strong: boolean, z: number): TextLabel
	local label = Glass.Label(parent, name, said, size, colour, x, y + size * 0.36 - 10, 200, 20, Enum.TextXAlignment.Left, strong, z)
	label.Size = UDim2.fromOffset(math.ceil(Text.Wide(label, said)) + 2, 20)
	return label
end

-- The dares a run kept (TR54; AR53's chip, goals.json "dare.card.chip"): the kept mark and "Dare kept", on dark glass
-- with a warm edge. Its width follows its words. The stones they paid stand with the run's other rewards (stoneOf), so
-- each reads as its item (research's must-fix 2).
local function dareChip(parent: Instance, z: number): Frame
	local K = LOOK.DareCard.Chip
	local chip = Instance.new("Frame")
	chip.Name = "DareKept"
	chip.BackgroundTransparency = 1
	chip.ZIndex = z
	chip.Parent = parent
	local words = capsLabel(chip, "Words", GoalDefs.Labels.DareKept, K.Words.Size, K.Words.Colour, K.Words.X, K.Words.Y, true, z + 4)
	local wide = math.ceil(K.Words.X + Text.Wide(words, words.Text) + K.Pad)
	Glass.Glow(chip, "Glow", 0, 0, wide, K.Tall, K.Glow.Reach, K.Glow.Colour, K.Glow.Alpha, z)
	Glass.Fill(chip, "Fill", 0, 0, wide, K.Tall, K.Corner, K.Fill, z + 1)
	Glass.Edge(chip, "Edge", 0, 0, wide, K.Tall, K.Corner, K.Edge.Colour, 1, nil, z + 3)
	local record = UIKit.Images.DareMarkKept
	local mark = Instance.new("ImageLabel")
	mark.Name = "DareMarkKept"
	mark.BackgroundTransparency = 1
	mark.Image = record.Id
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromOffset(K.Mark.At.X, K.Mark.At.Y)
	mark.Size = UDim2.fromOffset(record.Points.X * K.Mark.Scale, record.Points.Y * K.Mark.Scale)
	mark.ZIndex = z + 5
	mark:SetAttribute("Kit", "DareMarkKept")
	mark.Parent = chip
	chip.Size = UDim2.fromOffset(wide, K.Tall)
	return chip
end

-- A face in a bare button's skin, under its press.
local function faceOf(button: TextButton): Frame
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.BackgroundTransparency = 1
	face.Size = UDim2.fromScale(1, 1)
	face.Parent = Skin.Of(button)
	return face
end

-- One difficulty's choice on the Arc's tile, `w` by `h`: its name (Hard's with its chevrons), the Combat Power its run
-- recommends at its top right, and the run's marks lit to its checkpoint and ringing it, with where the next run starts;
-- while shut, its lock and why. Returns the marks' light, to run in, or nil while shut.
local function choice(face: Frame, data: any, ground: string, which: string, w: number, h: number, reason: string?): ((number) -> ())?
	face:ClearAllChildren()
	local C = ARC.Choice
	local hard, shut = which == "Hard", reason ~= nil
	local a = accent(hard)
	local cut = TILE.Corner
	Glass.Fill(face, "Fill", 0, 0, w, h, cut, if shut then TILE.Shut else TILE.Fill, 2)
	if shut then
		Glass.Edge(face, "Edge", 0, 0, w, h, cut, SEAM.Edge, TILE.ShutEdge, nil, 5)
	else
		Glass.Wash(face, "Sheen", 0, 0, w, h, cut, SEAM.Glint, function(at: number): number
			return TILE.Sheen.Alpha * math.exp(-at / TILE.Sheen.Fall)
		end, 3)
		Glass.Wash(face, "Wash", 0, 0, w, h, cut, a.Edge, function(at: number): number
			return TILE.Next.Wash * math.clamp(1 - at / (h * 0.85), 0, 1)
		end, 3)
		Glass.Edge(face, "Edge", 0, 0, w, h, cut, a.Edge, TILE.Edge.Top, TILE.Edge.Foot, 5)
		cornerGlint(face, "CornerGlint", 0, 0, w, h, cut, TILE.CornerGlint, 6)
	end
	local text = if shut then SEAM.Soft else SEAM.Text
	if hard then
		local name = chevronWords(face, "Name", which, TITLE, text, 11, if shut then SEAM.Soft else a.Edge, C.In, C.Top, 120, C.Head, 12)
		local list = name:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	else
		Glass.Label(face, "Name", which, TITLE, text, C.In, C.Top, 120, C.Head, Enum.TextXAlignment.Left, true, 12)
	end
	local count = #((Stages.Of(ground) or {}) :: { any })
	local top = Instance.new("Frame")
	top.Name = "Recommends"
	top.BackgroundTransparency = 1
	top.Position = UDim2.fromOffset(C.In, C.Top)
	top.Size = UDim2.fromOffset(w - 2 * C.In, C.Head)
	top.ZIndex = 12
	top.Parent = face
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = top
	local said = Glass.Label(top, "Said", "Recommended", SMALL, SEAM.Soft, 0, 0, 0, C.Head, nil, false, 12)
	said.AutomaticSize = Enum.AutomaticSize.X
	said.LayoutOrder = 1
	local power = Glass.Label(top, "Power", `{Hud.Digits(Stages.Recommended(ground, which, count))} {Sheet.Said.Power}`, TITLE, text, 0, 0, 0, C.Head, nil, true, 12)
	power.AutomaticSize = Enum.AutomaticSize.X
	power.LayoutOrder = 2
	parts[`{which}Power`] = power
	if shut then
		Glass.Mark(face, "Lock", LOCK, C.In + 9, C.Marks, 18, SEAM.Soft, 12)
		parts[`{which}Says`] = Glass.Label(face, "Words", reason :: string, SMALL, SEAM.Soft, C.In + 26, C.Marks - 10, w - 2 * C.In - 26, 20, Enum.TextXAlignment.Left, false, 12)
		return nil
	end
	local at = Stages.Checkpoint(data, ground, which)
	local rows: { string } = {}
	for k = 1, count do
		rows[k] = if k < at then "cleared" elseif k == at then "next" else "shut"
	end
	local play = marks(face, C.In, C.In + C.Road, C.Marks, rows, hard, 12)
	-- Where the run starts, and under it the way in: a lit press, Fight, or Continue at a checkpoint (research's must-fix
	-- 2). The whole card is the press; the plate says so.
	local wx = C.In + C.Road + C.Words
	local ww = w - wx - C.In
	parts[`{which}Says`] = Glass.Label(face, "Words", `Stretch {at} of {count}`, SMALL, SEAM.Text, wx, C.Marks + C.Says, ww, 16, nil, true, 12)
	local py = C.Marks + C.Says + 18
	Glass.Lit(face, "Plate", wx, py, ww, C.Press, litFill(hard), accent(hard).Glow, 12)
	parts[`{which}Press`] = Glass.Label(face, "Press", if at > 1 then "Continue" else "Fight", TITLE, INK, wx, py, ww, C.Press, nil, true, 17)
	return play
end

-- The Arc panel: the ground's one tile, Normal and Hard on it, a press each (TR50).
function StageScreen.Pick(ground: string, view: Profile.View, on: On)
	table.clear(parts)
	local data = view :: any
	local named = Grounds.ById[ground] and Grounds.ById[ground].Name or "Stages"
	local opening = Screen.Current() ~= StageScreen.Name
	if opening then
		Screen.Rise({ From = MOTION.Rise, Seconds = MOTION.Open, Cover = MOTION.Open, Sink = 0.14, Uncover = 0.12 })
	end
	local body = Screen.Full(StageScreen.Name, ARC.Title, "SeamGlass")
	parts.Body = body
	local cover = Screen.Cover(StageScreen.Name)
	if cover then
		cover.BackgroundColor3 = SEAM.Backing or cover.BackgroundColor3 -- a card before it left its wine (a reopened screen keeps its cover)
	end
	Glass.Ground(body, 1, ARC.Backing) -- the festival's dusk behind the glass (TR50's older line)
	local room = block(body, "Arc")
	room.ZIndex = 2
	parts.Block = room
	local band = Screen.Band(StageScreen.Name)
	underline(band, ARC.Rim)
	if band then
		local title = Glass.Label(band, "Title", ARC.Title, TITLE, SEAM.Text, Screen.BandLeft + 4, 0, 260, 0, Enum.TextXAlignment.Left, true, 3)
		title.Size = UDim2.new(0, 260, 1, 0)
		parts.Title = title
	end
	-- The tile, in a group that fades as it rises in.
	local w, h = W - 2 * TILE.Pad, TILE.Foot - TILE.Top
	local group = Instance.new("CanvasGroup")
	group.Name = "ArcTile"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromOffset(w + 2 * MARGIN, h + 2 * MARGIN)
	group.Position = UDim2.fromOffset(TILE.Pad - MARGIN, TILE.Top - T - MARGIN)
	group.ZIndex = 3
	group.Parent = room
	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.BackgroundTransparency = 1
	tile.Position = UDim2.fromOffset(MARGIN, MARGIN)
	tile.Size = UDim2.fromOffset(w, h)
	tile.Parent = group
	parts.Arc = tile
	-- The street's light pooled behind the bed, on the ground under the tile.
	local bedX, bedY = TILE.Pad + BED.Inset + ARC.Bed.X / 2, TILE.Top - T + BED.Inset + ARC.Bed.Y / 2
	parts.GroundBloom = Glass.Bloom(room, "GroundBloom", bedX, bedY, ARC.Bloom.Size.X, ARC.Bloom.Size.Y, ARC.Bloom.Colour, ARC.Bloom.Alpha, 1)
	Glass.Glow(tile, "Glow", 0, 0, w, h, TILE.Next.Glow, ARC.Glow, TILE.Next.GlowAlpha, 1)
	Glass.Fill(tile, "Fill", 0, 0, w, h, TILE.Corner, TILE.Fill, 2)
	Glass.Wash(tile, "Sheen", 0, 0, w, h, TILE.Corner, SEAM.Glint, function(at: number): number
		return TILE.Sheen.Alpha * math.exp(-at / TILE.Sheen.Fall)
	end, 3)
	Glass.Edge(tile, "Edge", 0, 0, w, h, TILE.Corner, ARC.Rim, TILE.Edge.Top, TILE.Edge.Foot, 5)
	cornerGlint(tile, "CornerGlint", 0, 0, w, h, TILE.Corner, TILE.CornerGlint, 6)
	-- The bed: the keeper's picture on its own light, pooled low under it, the ground's name under it.
	local bx, by, bw, bh = BED.Inset, BED.Inset, ARC.Bed.X, ARC.Bed.Y
	local bed = Instance.new("Frame")
	bed.Name = "Bed"
	bed.BackgroundTransparency = 1
	bed.ClipsDescendants = true
	bed.Position = UDim2.fromOffset(bx, by)
	bed.Size = UDim2.fromOffset(bw, bh)
	bed.ZIndex = 7
	bed.Parent = tile
	Glass.Fill(bed, "Fill", 0, 0, bw, bh, BED.Corner, BED.Fill, 7)
	Glass.Bloom(bed, "Bloom", bw * BED.Bloom.Middle.X, bh * BED.Bloom.Middle.Y, BED.Bloom.Size.X * ARC.Picture, BED.Bloom.Size.Y * ARC.Picture, BED.Bloom.Colour, BED.Bloom.Alpha, 8)
	local record = IMAGES[LOOK.Pictures[#LOOK.Pictures]]
	if record then
		local pw, ph = BED.Picture.X * ARC.Picture, BED.Picture.Y * ARC.Picture
		local picture = Instance.new("ImageLabel")
		picture.Name = "Picture"
		picture.BackgroundTransparency = 1
		picture.Image = record.Id
		picture.Size = UDim2.fromOffset(pw, ph)
		picture.Position = UDim2.fromOffset((bw - pw) / 2, (bh - ph) / 2)
		picture.ZIndex = 9
		picture.Parent = bed
	end
	Glass.Edge(tile, "BedEdge", bx, by, bw, bh, BED.Corner, BED.Edge, BED.EdgeAlpha, nil, 10)
	parts.Ground = Glass.Label(tile, "Ground", named, TITLE, SEAM.Text, bx, by + bh, bw, h - by - bh - BED.Inset, nil, true, 12)
	-- The Keeper alone (TR74; Rules.Stages.Alone): once the keeper has fallen on Normal, the bed's foot offers it again on
	-- its own, a press per difficulty, Hard's shut until it falls there too. A grey block until AR68's system dresses it.
	local count = #((Stages.Of(ground) or {}) :: { any })
	if count > 0 and Stages.Line(data, ground, "Normal").Cleared >= count then
		local A = ALONE
		local sy = by + bh - A.Tall
		Glass.Fill(tile, "AloneStrip", bx, sy, bw, A.Tall, 0, TILE.Shut, 11)
		Glass.Edge(tile, "AloneEdge", bx, sy, bw, A.Tall, 0, SEAM.Edge, TILE.ShutEdge, nil, 12)
		parts.AloneSays = Glass.Label(tile, "AloneSays", "Keeper alone", SMALL, SEAM.Soft, bx, sy + 1, bw, A.Caption, nil, true, 13)
		local pw = (bw - 3 * A.Gap) / 2
		for index, which in Stages.Difficulties do
			local fallen = Stages.Line(data, ground, which).Cleared >= count
			local reason = if fallen then nil else why(ground, Stages.Fallen)
			local button = Button.new({
				Name = `{which}Alone`,
				Text = "",
				Bare = true,
				Size = UDim2.fromOffset(pw, A.Press),
				Position = UDim2.fromOffset(bx + A.Gap + (index - 1) * (pw + A.Gap), sy + A.Caption + 1),
				Parent = tile,
				OnPress = function(): boolean
					local begun = begin(on, ground, which, true)
					if begun then
						difficulty = which
					end
					return begun
				end,
			})
			button.ZIndex = 14
			Button.Set(button, { Disabled = reason or false })
			button:SetAttribute("Look", if reason then "shut" else "open")
			local face = faceOf(button)
			Glass.Fill(face, "Fill", 0, 0, pw, A.Press, 3, if fallen then TILE.Fill else TILE.Shut, 14)
			Glass.Edge(face, "Edge", 0, 0, pw, A.Press, 3, if fallen then accent(which == "Hard").Edge else SEAM.Edge, TILE.ShutEdge, nil, 15)
			Glass.Label(face, "Words", which, SMALL, if fallen then SEAM.Text else SEAM.Soft, 0, 0, pw, A.Press, nil, true, 16)
			parts[`{which}Alone`] = button
		end
	end
	-- Normal and Hard beside it, one press each.
	local cx = bx + bw + ARC.Gap
	local cw, ch = w - cx - BED.Inset, (h - 2 * BED.Inset - ARC.Gap) / 2
	local plays: { (number) -> () } = {}
	for index, which in Stages.Difficulties do
		local needs, waits = Stages.Needs(data, ground, which, 1)
		local reason = why(ground, needs, waits)
		local button = Button.new({
			Name = which,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(cw, ch),
			Position = UDim2.fromOffset(cx, BED.Inset + (index - 1) * (ch + ARC.Gap)),
			Parent = tile,
			OnPress = function(): boolean
				local begun = begin(on, ground, which)
				if begun then
					difficulty = which
				end
				return begun
			end,
		})
		button.ZIndex = 14
		Button.Set(button, { Disabled = reason or false })
		button:SetAttribute("Look", if reason then "shut" else "open")
		button:SetAttribute("Checkpoint", Stages.Checkpoint(data, ground, which))
		parts[which] = button
		local play = choice(faceOf(button), data, ground, which, cw, ch, reason)
		if play then
			table.insert(plays, play)
		end
	end
	-- The foot: the player's own power, and what Hard is once it's open.
	local footY = ROAD.Y + LOOK.Foot.Down - T
	Glass.Label(room, "YourPower", "Your power", SMALL, SEAM.Soft, TILE.Pad + 2, footY, 80, SMALL + 4, Enum.TextXAlignment.Left, false, 2)
	local mine = power(view)
	Glass.Label(room, "Power", if mine then `{Hud.Digits(mine)} {Sheet.Said.Power}` else "No lead", TITLE, SEAM.Text, TILE.Pad + LOOK.Foot.Power, footY - 2, 120, TITLE + 4, Enum.TextXAlignment.Left, true, 2)
	local hardOpen = Stages.Needs(data, ground, "Hard", 1) == nil
	parts.HardWords = Glass.Label(room, "HardWords", if hardOpen then `Hard: enemies are {StagesConfig.Offset.Hard} levels higher` else "", SMALL, SEAM.Text, W - TILE.Pad - 2 - 330, footY, 330, SMALL + 4, Enum.TextXAlignment.Right, false, 2)
	-- The opening: the tile rises in, then each run's light fills to its checkpoint's ring.
	if opening and not GuiService.ReducedMotionEnabled then
		local at = group.Position
		group.GroupTransparency = 1
		group.Position = at + UDim2.fromOffset(0, TILE.Rise)
		TweenService:Create(group, TweenInfo.new(TILE.Seconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, TILE.Start), { GroupTransparency = 0, Position = at }):Play()
		task.delay(MOTION.RoadAt, function()
			for _, play in plays do
				if room.Parent then
					Glass.Ease(room, MOTION.RoadSeconds, play, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end
			end
		end)
	else
		for _, play in plays do
			play(1)
		end
	end
end

-- One press on the card: the lit press (an ember into a Hard stage, with Hard's chevrons) or a quiet one.
local function press(parent: Instance, name: string, words: string, x0: number, y0: number, w: number, one: boolean, intoHard: boolean, act: () -> boolean?): TextButton
	local button = Button.new({
		Name = name,
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(w, Theme.Size.Tap),
		Position = UDim2.fromOffset(x0, y0),
		Parent = parent,
		OnPress = act,
	})
	button.ZIndex = 20
	local face = faceOf(button)
	local h = Theme.Size.Tap
	if one then
		Glass.Lit(face, "Plate", 0, 0, w, h, litFill(intoHard), accent(intoHard).Glow, 1)
	else
		Glass.Quiet(face, "Plate", 0, 0, w, h, SEAM.Facet, 1)
	end
	local colour = if one then INK else SEAM.Text
	if intoHard then
		chevronWords(face, "Words", words, TITLE, colour, 12, colour, 0, 0, w, h, 7)
	else
		Glass.Label(face, "Words", words, TITLE, colour, 0, 0, w, h, nil, true, 7)
	end
	return button
end

-- A fall's Retry (docs/design.md, "A fall in the Festival"): lit while someone leads (on.Lead), else dim, quiet glass with
-- the time the fallen lead heals in after its word, lighting by itself over Fall.Lit once someone leads (healed, or
-- another sent). Its attribute Led says which.
local function standBy(button: TextButton, w: number, on: On)
	local face = button:FindFirstChild("Face", true) :: Frame?
	if face == nil then
		return
	end
	local h = Theme.Size.Tap
	local lit = Instance.new("CanvasGroup")
	lit.Name = "Lit"
	lit.BackgroundTransparency = 1
	lit.Size = UDim2.fromScale(1, 1)
	lit.ZIndex = 1
	for _, child in face:GetChildren() do
		child.Parent = lit
	end
	lit.Parent = face
	local dim = Instance.new("CanvasGroup")
	dim.Name = "Dim"
	dim.BackgroundTransparency = 1
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 2
	dim.Parent = face
	Glass.Quiet(dim, "DimPlate", 0, 0, w, h, SEAM.Facet, 1)
	local words = Glass.Label(dim, "DimWords", "Retry", TITLE, SEAM.Soft, 0, 0, w, h, nil, true, 7)
	local was: boolean? = nil
	local function refresh()
		local led, untilAt = on.Lead()
		if led ~= was then
			local first = was == nil
			was = led
			button:SetAttribute("Led", led)
			local seconds = if first or GuiService.ReducedMotionEnabled then 0 else LOOK.Card.Fall.Lit
			local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TweenService:Create(lit, info, { GroupTransparency = if led then 0 else 1 }):Play()
			TweenService:Create(dim, info, { GroupTransparency = if led then 1 else 0 }):Play()
		end
		if not led then
			local left = if untilAt then math.max(0, untilAt - workspace:GetServerTimeNow()) else nil
			words.Text = if left and left > 0 then `Retry  {Hud.Clock(left)}` else "Retry"
		end
	end
	refresh()
	task.spawn(function()
		while button:IsDescendantOf(game) do
			task.wait(0.2)
			if button:IsDescendantOf(game) then
				refresh()
			end
		end
	end)
end

-- The press into Hard on the card whose clear opened it (research's lines for the card, TR54): it comes in shut, quiet
-- glass under Hard's lock (the Arc panel's own mark) beside its word in Soft, and Unlock.After seconds after the card's
-- beats end the lock lifts Unlock.Rise points and fades over Unlock.Seconds as the press lights. Its attribute Shut says
-- which, and its tap waits until it's lit.
local function shutUntilLit(button: TextButton, w: number)
	local U = LOOK.Card.Unlock
	local h = Theme.Size.Tap
	local face = button:FindFirstChild("Face", true) :: Frame?
	if face == nil or GuiService.ReducedMotionEnabled then
		return
	end
	local lit = Instance.new("CanvasGroup")
	lit.Name = "Lit"
	lit.BackgroundTransparency = 1
	lit.Size = UDim2.fromScale(1, 1)
	lit.GroupTransparency = 1
	lit.ZIndex = 1
	for _, child in face:GetChildren() do
		child.Parent = lit
	end
	lit.Parent = face
	local shut = Instance.new("CanvasGroup")
	shut.Name = "Shut"
	shut.BackgroundTransparency = 1
	shut.Size = UDim2.fromScale(1, 1)
	shut.ZIndex = 2
	shut.Parent = face
	Glass.Quiet(shut, "ShutPlate", 0, 0, w, h, SEAM.Facet, 1)
	local word = Glass.Label(shut, "ShutWords", "Hard", TITLE, SEAM.Soft, 0, 0, w, h, Enum.TextXAlignment.Left, true, 7)
	local wide = math.ceil(Text.Wide(word, "Hard")) + 2
	local unit = U.Lock + U.Gap + wide
	word.Position = UDim2.fromOffset((w - unit) / 2 + U.Lock + U.Gap, 0)
	word.Size = UDim2.fromOffset(wide, h)
	local lock = Glass.Mark(face, "Lock", LOCK, (w - unit) / 2 + U.Lock / 2, h / 2, U.Lock, SEAM.Soft, 12)
	local x0, y0 = lock.Position.X.Offset, lock.Position.Y.Offset
	button:SetAttribute("Shut", true)
	task.delay(MOTION.RunAt + MOTION.RunSeconds + U.After, function()
		if button.Parent == nil then
			return
		end
		button:SetAttribute("Shut", false)
		Glass.Ease(face, U.Seconds, function(u: number)
			lit.GroupTransparency = 1 - u
			shut.GroupTransparency = u
			lock.Position = UDim2.fromOffset(x0, y0 - U.Rise * u)
			lock.ImageTransparency = u
		end, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
end

function StageScreen.NewBest(results: { [string]: any }): boolean
	local seconds, best = results.Seconds, results.Best
	return results.Won == true and type(seconds) == "number" and type(best) == "number" and best >= seconds
end

function StageScreen.Results(results: { [string]: any }, on: On)
	table.clear(parts)
	local ground, which, stage = results.Ground :: string, results.Difficulty :: string, results.Stage :: number
	local count = if type(results.Count) == "number" then results.Count else #((Stages.Of(ground) or {}) :: { any })
	local hard, won = which == "Hard", results.Won == true
	local C = LOOK.Card
	local rows = C.Rows
	Screen.Dim(C.Dim)
	if Screen.Current() ~= StageScreen.Name then
		Screen.Rise({ From = MOTION.Rise, Seconds = MOTION.Open, Cover = MOTION.Open, Sink = 0.14, Uncover = 0.12 })
	end
	local body = Screen.Full(StageScreen.Name, "Results", "SeamGlass")
	parts.Body = body
	-- The street under the card stays the street's dusk: the cover in dark wine (TR50's older line).
	local cover = Screen.Cover(StageScreen.Name)
	if cover then
		cover.BackgroundColor3 = C.Cover
	end
	underline(Screen.Band(StageScreen.Name), nil)
	-- The card stands alone over the street dimmed (the cut): the HUD steps back until the screen closes, as the base's
	-- view does.
	local hud = Layers.Get("Hud")
	hud.Visible = false
	if not hudBack then
		hudBack = true
		Screen.Closed:Once(function()
			hudBack = false
			hud.Visible = true
		end)
	end
	local room = block(body, "Card")
	room.ZIndex = 2
	-- Its rows, top to foot.
	local named = Grounds.ById[ground] and Grounds.ById[ground].Name or "The run"
	local opened = results.Opened :: string?
	local resume = if type(results.Checkpoint) == "number" then results.Checkpoint else stage
	local gave: { { Icon: string, Words: string, Colour: Color3, Stone: boolean? } } = {}
	if won then
		if (results.Credits or 0) > 0 then
			table.insert(gave, { Icon = "CoinMint", Words = `+{Hud.Digits(results.Credits)}`, Colour = UIKit.Systems.Credits.Colour })
		end
		if (results.Shards or 0) > 0 then
			table.insert(gave, { Icon = "ShardStandardSmall", Words = `+{Hud.Digits(results.Shards)}`, Colour = SEAM.Text })
		end
		if (results.Chests or 0) > 0 then
			local keeper = (Stages.Last(ground, stage) or {} :: any).Kind == "Keeper"
			table.insert(gave, { Icon = if keeper then "ChestKeeper" else "ChestShade", Words = `+{Hud.Digits(results.Chests)}`, Colour = SEAM.Text })
		end
	end
	local given: any = results.Dares
	local dares: { [string]: any }? = if type(given) == "table" and type(given.Count) == "number" and given.Count > 0 then given else nil
	local keptStretches: { number }? = if dares and type(dares.Kept) == "table" then dares.Kept :: { number } else nil
	if dares then
		-- the stones the kept dares paid, a reward among the others, on either card
		local grade = if type(dares.Grade) == "string" then dares.Grade else "Low"
		table.insert(gave, { Icon = `Stone{grade}`, Words = `+{Hud.Digits(dares.Count)}`, Colour = SEAM.Text, Stone = true })
	end
	-- The time's row: what it says, worked out first, so the chip can be measured beside it.
	local seconds, best = results.Seconds :: number?, results.Best :: number?
	local from = if type(results.From) == "number" then results.From else 1
	local said: string? = nil
	if not won or seconds == nil then
		said = if won then "Cleared" else `Next run starts at Stretch {resume}`
	elseif StageScreen.NewBest(results) then
		said = nil -- a new best: the clock at the title's size, then "New best"
	elseif best then
		said = `{Read.Clock(seconds)}   ·   best {Read.Clock(best)}`
	else
		said = `{Read.Clock(seconds)}   ·   from Stretch {from}`
	end
	-- The chip rides the time's row on a win when the row's longest still fits inside the card's inner width (research's
	-- must-fix 3), else it takes a row of its own, as it always does on the fall's card.
	local chip: Frame? = if dares then dareChip(room, 6) else nil
	local chipAlone = false
	if chip then
		chip.Visible = false
		local C2 = LOOK.Card
		local probe = Glass.Label(room, "Probe", "", SMALL, SEAM.Soft, 0, 0, 0, 0, nil, false, 0)
		local strong = Glass.Label(room, "ProbeStrong", "", TITLE, SEAM.Text, 0, 0, 0, 0, nil, true, 0)
		local row = if said then Text.Wide(probe, said) elseif seconds then Text.Wide(strong, Read.Clock(seconds)) + 10 + C2.NewBest else 0
		probe:Destroy()
		strong:Destroy()
		chipAlone = not won or row + LOOK.DareCard.Chip.Gap + chip.Size.X.Offset > C2.Wide - 2 * C2.Inset
	end
	local spans: { { Kind: string, Tall: number } } = { { Kind = "Marks", Tall = rows.Marks }, { Kind = "Title", Tall = rows.Title }, { Kind = "Time", Tall = rows.Time } }
	if chipAlone then
		table.insert(spans, { Kind = "Dare", Tall = LOOK.DareCard.Chip.Fall })
	end
	if #gave > 0 then
		table.insert(spans, { Kind = "Gave", Tall = rows.Gave })
	end
	local inner = 0
	for _, span in spans do
		inner += span.Tall
	end
	inner += C.Space * (#spans - 1)
	local total = C.In + inner + C.Before + Theme.Size.Tap + C.Foot
	local x0, w = C.Left, C.Wide
	local high = math.max(LOOK.Block.Tall, total + 2 * C.Margin)
	room.Size = UDim2.fromOffset(W, high)
	local y0 = (high - total) / 2
	local cx = x0 + w / 2
	plate(room, x0, y0, w, total, hard, C.Corner, 1)
	-- The marks: the run's stretches, all checked and the keeper's just on a win; on a fall, checked to where the next
	-- run starts and ringing it.
	local markRows: { string } = {}
	for k = 1, count do
		if won then
			markRows[k] = if k == stage then "just" else "cleared"
		else
			markRows[k] = if k < resume then "cleared" elseif k == resume then "next" else "shut"
		end
	end
	local y = y0 + C.In
	local play: ((number) -> ())? = nil
	for _, span in spans do
		local h = span.Tall
		if span.Kind == "Marks" then
			play = marks(room, x0 + 16, x0 + w - 16, y + h / 2, markRows, hard, 6, keptStretches)
		elseif span.Kind == "Title" then
			local title = Glass.Label(room, "Title", if won then `{named} cleared` elseif type(results.Lead) == "string" then `{results.Lead} fell` else "Your lead fell", BIG, if won then SEAM.Text else Theme.Colour.Hurt, x0, y, w, h, nil, true, 6)
			-- a nickname runs to 20 letters: the title shrinks to keep inside the card's inset, never below TitleFit
			local wide = Text.Wide(title, title.Text)
			if wide > w - 2 * C.Inset then
				title.TextSize = math.floor(BIG * math.max((w - 2 * C.Inset) / wide, C.TitleFit))
			end
			parts.Title = title
		elseif span.Kind == "Time" then
			-- The whole run's time; its best only for a run from the first stretch (Rules.Stages.Clear's RunBest).
			local row = Instance.new("Frame")
			row.Name = "Time"
			row.BackgroundTransparency = 1
			row.Position = UDim2.fromOffset(x0, y)
			row.Size = UDim2.fromOffset(w, h)
			row.ZIndex = 6
			row.Parent = room
			parts.Time = row
			local beside = if chip and not chipAlone then chip else nil
			if beside and said then
				-- the chip last on the row, the row's gap before it (AR53)
				local list = Instance.new("UIListLayout")
				list.FillDirection = Enum.FillDirection.Horizontal
				list.HorizontalAlignment = Enum.HorizontalAlignment.Center
				list.VerticalAlignment = Enum.VerticalAlignment.Center
				list.Padding = UDim.new(0, LOOK.DareCard.Chip.Gap)
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = row
				local label = Glass.Label(row, "Said", said, SMALL, SEAM.Soft, 0, 0, 0, h, nil, false, 6)
				label.AutomaticSize = Enum.AutomaticSize.X
				label.LayoutOrder = 1
				beside.Parent = row
				beside.LayoutOrder = 9
				beside.Visible = true
				parts.Dare = beside
			elseif said then
				Glass.Label(row, "Said", said, SMALL, SEAM.Soft, 0, 0, w, h, nil, false, 6)
			elseif best and seconds and best >= seconds then
				local list = Instance.new("UIListLayout")
				list.FillDirection = Enum.FillDirection.Horizontal
				list.HorizontalAlignment = Enum.HorizontalAlignment.Center
				list.VerticalAlignment = Enum.VerticalAlignment.Center
				list.Padding = UDim.new(0, 10)
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = row
				local clock = Glass.Label(row, "Clock", Read.Clock(seconds), TITLE, SEAM.Text, 0, 0, 0, h, nil, true, 6)
				clock.AutomaticSize = Enum.AutomaticSize.X
				clock.LayoutOrder = 1
				local newBest = C.NewBest
				local tag = Instance.new("Frame")
				tag.Name = "NewBest"
				tag.BackgroundTransparency = 1
				tag.Size = UDim2.fromOffset(newBest, h)
				tag.LayoutOrder = 2
				tag.ZIndex = 6
				tag.Parent = row
				Glass.Fill(tag, "Fill", 0, 0, newBest, h, 4, LOOK.Socket, 6)
				Glass.Edge(tag, "Edge", 0, 0, newBest, h, 4, LOOK.Ready, 1, nil, 7)
				Glass.Label(tag, "Words", "New best", SMALL, LOOK.Ready, 0, 0, newBest, h, nil, true, 8)
				if beside then
					-- the chip last on the row: the row's own gap is 10, so 2 back
					local K = LOOK.DareCard.Chip
					local holder = Instance.new("Frame")
					holder.Name = "DareRoom"
					holder.BackgroundTransparency = 1
					holder.LayoutOrder = 9
					holder.ZIndex = 6
					holder.Parent = row
					beside.Parent = holder
					beside.Visible = true
					local back = K.Gap - list.Padding.Offset
					beside.Position = UDim2.fromOffset(back, (h - K.Tall) / 2)
					holder.Size = UDim2.fromOffset(beside.Size.X.Offset + back, h)
					parts.Dare = beside
				end
			end
		elseif span.Kind == "Dare" and chip then
			local K = LOOK.DareCard.Chip
			chip.Position = UDim2.fromOffset(x0 + (w - chip.Size.X.Offset) / 2, y + K.Down)
			chip.Visible = true
			parts.Dare = chip
		elseif span.Kind == "Gave" then
			-- centred on its own middle, so a row shrunk to fit stays centred on the card
			local row = Instance.new("Frame")
			row.Name = "Gave"
			row.BackgroundTransparency = 1
			row.AnchorPoint = Vector2.new(0.5, 0.5)
			row.Position = UDim2.fromOffset(cx, y + h / 2)
			row.Size = UDim2.fromOffset(w, h)
			row.ZIndex = 6
			row.Parent = room
			parts.Gave = row
			local list = Instance.new("UIListLayout")
			list.FillDirection = Enum.FillDirection.Horizontal
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.Padding = UDim.new(0, C.GaveGap)
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Parent = row
			local across = 0
			for index, item in gave do
				-- a forge stone is a dark rock: drawn larger, its own light behind it, so it reads as a stone beside the
				-- bright shard and chest (research's must-fix 2; Config.Hud.Stages.DareCard.Stone)
				local S = LOOK.DareCard.Stone
				local side = if item.Stone then S.Side else 22
				local cell = Instance.new("Frame")
				cell.Name = item.Icon
				cell.BackgroundTransparency = 1
				cell.LayoutOrder = index
				cell.ZIndex = 6
				cell.Parent = row
				-- each cell as wide as its own words: the picture, the gap, the words, the pad
				local words = Glass.Label(cell, "Words", item.Words, TITLE, item.Colour, 5 + side + 6, 0, 200, h, Enum.TextXAlignment.Left, true, 8)
				local wordsWide = math.ceil(Text.Wide(words, item.Words)) + 2
				words.Size = UDim2.fromOffset(wordsWide, h)
				local cw = 5 + side + 6 + wordsWide + 8
				cell.Size = UDim2.fromOffset(cw, h)
				across += cw + (if index > 1 then C.GaveGap else 0)
				Glass.Fill(cell, "Fill", 0, 0, cw, h, 4, SEAM.Well, 6)
				Glass.Edge(cell, "Edge", 0, 0, cw, h, 4, SEAM.Edge, 1, nil, 7)
				local record = UIKit.Images[item.Icon]
				if record then
					if item.Stone then
						-- wider and taller than the stone, since the stone fills the row: its light shows round it, a little past the cell
						Glass.Bloom(cell, "Light", 5 + side / 2, h / 2, side * S.Light.Spread, side * S.Light.Tall, S.Light.Colour, S.Light.Alpha, 7)
					end
					Glass.Mark(cell, "Icon", record, 5 + side / 2, h / 2, side, WHITE, 8)
				end
				if item.Stone then
					parts.Stone = cell
				end
			end
			-- the row's longest past the card's inset (a run's Credits grow with the level): it shrinks to fit, no
			-- further than Fit (research's must-fix 3)
			local room0 = w - 2 * C.Inset
			if across > room0 then
				local fit = Instance.new("UIScale")
				fit.Scale = math.max(room0 / across, C.Fit)
				fit.Parent = row
			end
		end
		y += h + C.Space
	end
	-- Retry, Hard and Home, the one press lit: Hard after the keeper on Normal (Clear's Then), else Retry on a lost run,
	-- else Home. Retry begins the run again at its checkpoint.
	local P = C.Presses
	local presses: { { Name: string, Words: string, Wide: number, One: boolean, Hard: boolean, Act: () -> boolean? } } = {}
	local retry = function(): boolean
		return begin(on, ground, which)
	end
	local home = function(): boolean
		local answer = on.Home()
		if answer.Ok == true then
			Screen.Close()
			return true
		end
		if type(answer.Says) == "string" and answer.Says ~= "" then
			on.Say(answer.Says, true)
		end
		return false
	end
	if won and results.Then == "Hard" then
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.Quiet, One = false, Hard = false, Act = retry })
		table.insert(presses, { Name = "Next", Words = "Hard", Wide = P.One, One = true, Hard = true, Act = function(): boolean
			if parts.Next and (parts.Next :: Instance):GetAttribute("Shut") == true then
				return false -- shut until its lock lifts
			end
			return begin(on, ground, "Hard")
		end })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = P.Quiet, One = false, Hard = false, Act = home })
	elseif won then
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.Home, One = false, Hard = false, Act = retry })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = P.Home, One = true, Hard = false, Act = home })
	else
		-- A fall: Retry with whoever leads, dim while nobody does (a tap then answers nothing); Send another; Home. "Send
		-- another" kept whole: Tight's widths when it doesn't fit Quiet.
		local F = C.Fall
		local gauge = Glass.Label(room, "Gauge", "", TITLE, SEAM.Text, 0, 0, P.Quiet, Theme.Size.Tap, nil, true, 1) -- the press's own face
		local fits = Text.Wide(gauge, "Send another") + 2 * F.Pad <= P.Quiet
		gauge:Destroy()
		local led = function(): boolean?
			local button = parts.Retry
			if button and button:GetAttribute("Led") ~= true then
				return nil
			end
			return begin(on, ground, which)
		end
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.One, One = true, Hard = hard, Act = led })
		table.insert(presses, { Name = "Another", Words = "Send another", Wide = if fits then P.Quiet else F.Tight.Another, One = false, Hard = false, Act = function(): boolean?
			on.Another()
			return nil
		end })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = if fits then P.Quiet else F.Tight.Home, One = false, Hard = false, Act = home })
	end
	local span = -P.Gap
	for _, p in presses do
		span += p.Wide + P.Gap
	end
	local left = cx - span / 2
	local py = y0 + total - C.Foot - Theme.Size.Tap
	for _, p in presses do
		parts[p.Name] = press(room, p.Name, p.Words, left, py, p.Wide, p.One, p.Hard, p.Act)
		left += p.Wide + P.Gap
	end
	if won and opened == "Hard" and parts.Next then
		shutUntilLit(parts.Next :: TextButton, P.One)
	end
	if not won and parts.Retry then
		standBy(parts.Retry :: TextButton, P.One, on)
	end
	-- The card's beats: the check pops in a little over, then the light runs on and the next rings in.
	local just = parts.Just :: Frame?
	local pop = if just then just:FindFirstChildOfClass("UIScale") else nil
	if GuiService.ReducedMotionEnabled then
		if play then
			play(1)
		end
		return
	end
	if pop then
		pop.Scale = 0
		task.delay(MOTION.CheckAt, function()
			Glass.Ease(room, MOTION.CheckSeconds * 2, function(u: number)
				-- over to CheckOver by halfway, then back to 1
				pop.Scale = if u < 0.5 then MOTION.CheckOver * (u / 0.5) else MOTION.CheckOver + (1 - MOTION.CheckOver) * ((u - 0.5) / 0.5)
			end, Enum.EasingStyle.Linear)
		end)
	end
	if play then
		local playing = play
		task.delay(MOTION.RunAt, function()
			Glass.Ease(room, MOTION.RunSeconds, playing, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end)
	end
end

-- The card's pieces, for the run's line (StageController): its glass, a stage's mark, a check and a road's light.
StageScreen.Plate = plate
StageScreen.Badge = badge
StageScreen.Mark = mark
StageScreen.KeeperName = keeperName
StageScreen.Check = check
StageScreen.Road = roadLight
StageScreen.Accent = accent

-- A run on `which` begun for this player, as a press on the Arc panel begins it (the Play panel's Continue, UI.ModeScreen):
-- the open screen closes once it has, and a refusal says why. True once begun.
function StageScreen.Begin(on: On, ground: string, which: string): boolean
	local begun = begin(on, ground, which)
	if begun then
		difficulty = which
	end
	return begun
end

function StageScreen.Parts(): { [string]: Instance }
	return parts
end

function StageScreen.Difficulty(): string
	return difficulty
end

-- Its images made ready before the first opening: the picker's, the line's and the card's.
do
	local own: { UIKit.Image } = { CHEVRONS, CHEVRON, LOCK }
	for _, name in { "Tick", "RailComet", "CoinMint", "ShardStandardSmall", "ChestShade", "ChestKeeper" } do
		local record = UIKit.Images[name]
		if record then
			table.insert(own, record)
		end
	end
	for _, record in IMAGES do
		table.insert(own, record)
	end
	Glass.Preload(own)
end

return StageScreen
