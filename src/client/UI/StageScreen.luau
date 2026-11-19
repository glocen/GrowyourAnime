--!strict
-- StageScreen (client): a ground's stages in Seam's lit glass (AR42; TR43's screens; research's B, 2026-11-19, 15:04).
-- Laid as Modulo's cut draws them (tools/blender/stage_seam.py; build/handoff/UI/stages/stages.json), its numbers in
-- Config.Hud.Stages, its pieces the glass kit's (UI/Kit/Glass). Two faces of one full screen:
-- * The picker, from the Festival Door (StageService's StagePick) or the dock's Play: the ground's name and a Normal and
--   Hard switch in the band, the chosen half the lit press; four tiles side by side over one road. A tile is its stage's
--   picture on its bed, its mark, the Combat Power it recommends (Rules.Stages.Recommended) and its best clear, or why
--   it's shut ("Clear Stage 2 first"; Hard's tiles while Hard is shut). The next is raised, washed with light and tagged,
--   the road lit from the first tile to a ring under it; the player's own power stands at the road's start. A tile
--   begins its run (Net Stage). Hard's one accent is an ember; it keeps Normal's value.
-- * The results, at a run's end (StageDone): a glass card over the street dimmed. The four marks on their road, lit to
--   the stage just cleared and then on to the next; the stage cleared and its time (a new best in Ready's gold), what it
--   gave, what it opened ("Hard is open" its own band), and Retry, Next and Home, the one press lit. After the keeper's
--   stage on Normal, Next is Hard's Stage 1 (Rules.Stages.Clear). A lost run says the lead fell; Retry is the press.
--   StageScreen.Pick(ground, view, on)          the picker, on the switch's side (Normal, unless Hard was last picked)
--   StageScreen.Results(results, on, view?)    the results card; `view` marks the stages cleared
--   StageScreen.Parts()                        its pieces by name, for tests
--   StageScreen.Difficulty()                   the switch's side

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Stages = require(Shared.Rules.Stages)
local Stats = require(Shared.Rules.Stats)
local Grounds = require(Shared.Definitions.Grounds)
local Enemies = require(Shared.Definitions.Enemies)
local Hud = require(Shared.Rules.Hud)
local Sheet = require(Shared.Rules.Sheet)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local StagesConfig = require(Shared.Config.Stages)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Layers = require(UI.Layers)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Glass = require(UI.Kit.Glass)
local Skin = require(UI.Kit.Skin)

local StageScreen = {}
StageScreen.Name = "Stages"

export type On = {
	Begin: (ground: string, difficulty: string, stage: number) -> { [string]: any }, -- Net Stage
	Home: () -> { [string]: any }, -- Net Home
	Say: (words: string) -> (), -- a toast
}

local LOOK = HudConfig.Stages
local SEAM = UIKit.Palettes.SeamGlass
local TILE, BED, BADGE, ROAD, RING, MOTION = LOOK.Tile, LOOK.Bed, LOOK.Badge, LOOK.Road, LOOK.Ring, LOOK.Motion
local SMALL, TITLE, BIG = LOOK.Text.Small, LOOK.Text.Title, LOOK.Text.Big
local W, T = LOOK.Block.Wide, LOOK.Block.Top -- the cut's width; its band's foot, where a block's y starts
local WIDE = (W - 2 * TILE.Pad - 3 * TILE.Gap) / 4
local MARGIN = 18 -- round each tile's group: its glow and its tag stand past it
local WHITE = Color3.new(1, 1, 1)
local INK = SEAM.Ink :: Color3
local CHEVRONS = UIKit.Images.LevelChevrons :: UIKit.Image
local LOCK = HudConfig.Voidkin.Chrome.Images.Lock :: UIKit.Image
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

local function x(k: number): number
	return TILE.Pad + (k - 1) * (WIDE + TILE.Gap)
end

-- The keeper's name as a title: "the Lamplighter" reads "Lamplighter".
local function keeperName(ground: string): string
	local row = Grounds.ById[ground]
	local enemy = if row and row.Keeper then Enemies.ById[row.Keeper] else nil
	local name = if enemy then enemy.Name else "the keeper"
	name = string.gsub(name, "^[Tt]he ", "")
	return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

-- What a shut stage waits for, in the player's words.
local function why(ground: string, needs: string?, waits: number?): string?
	if needs == nil then
		return nil
	elseif needs == Stages.Before then
		return `Clear Stage {waits} first`
	elseif needs == Stages.Keeper then
		return `Beat the {keeperName(ground)} on Normal`
	elseif needs == Stages.Ground then
		return "Not open yet"
	end
	return "Not here"
end

local function begin(on: On, ground: string, which: string, stage: number): boolean
	local answer = on.Begin(ground, which, stage)
	if answer.Ok == true then
		Screen.Close()
		return true
	end
	local says = why(ground, answer.Needs, answer.Waits)
		or (if answer.Error == "NoLead" then "Your lead is down" elseif answer.Error == "InTry" then "Not during a challenge" else nil)
	if says then
		on.Say(says)
	end
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
local function badge(parent: Instance, name: string, x0: number, y0: number, n: number, hard: boolean, lit: boolean, z: number)
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
	Glass.Label(parent, `{name}Number`, tostring(n), TITLE, if lit then INK else SEAM.Soft, x0, y0, s, s, nil, true, z + 4)
	if hard then
		local bx = x0 + s + BADGE.Space
		Glass.Fill(parent, `{name}Hard`, bx, y0, BADGE.Box, s, 4, LOOK.HardBox, z + 1)
		Glass.Edge(parent, `{name}HardEdge`, bx, y0, BADGE.Box, s, 4, a.Edge, 1, nil, z + 3)
		chevrons(parent, `{name}Chevrons`, bx + BADGE.Box / 2, y0 + s / 2, 11, a.Edge, z + 4)
	end
end

-- A cleared stage's check: a lit disc, the kit's tick in ink.
local function check(parent: Instance, name: string, cx: number, cy: number, r: number, hard: boolean, z: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(cx, cy)
	holder.ZIndex = z
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	Glass.Disc(holder, "Disc", 0, 0, r, accent(hard).Lit, z)
	Glass.Mark(holder, "Tick", UIKit.Images.Tick, 0, 0, r * 1.1, INK, z + 1)
	holder.Parent = parent
	return holder
end

-- The ring where the player stands: a lit disc with its outer ring lit from above, the kit's comet round it.
local function ring(parent: Instance, cx: number, cy: number, hard: boolean, z: number): Frame
	local a = accent(hard)
	local r, outer = RING.Radius, RING.Radius + RING.Outer
	local holder = Instance.new("Frame")
	holder.Name = "Ring"
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(cx, cy)
	holder.ZIndex = z
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	local glow = 2 * (r + RING.Glow) * 1.5
	Glass.Bloom(holder, "Glow", 0, 0, glow, glow, a.Glow, RING.GlowAlpha, z)
	Glass.Disc(holder, "Disc", 0, 0, r, a.Lit, z + 1)
	local top = Glass.Disc(holder, "Top", 0, 0, r, WHITE, z + 2)
	local fall = Instance.new("UIGradient")
	fall.Rotation = 90
	fall.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.2, 1 - 0.6 * math.exp(-0.4 * r / (r * 0.35))),
		NumberSequenceKeypoint.new(0.45, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	fall.Parent = top
	Glass.Circle(holder, "Edge", 0, 0, r, WHITE, 1, 0.9, nil, z + 3)
	Glass.Circle(holder, "Outer", 0, 0, outer, a.Edge, 1.2, 0.85, 0.3, z + 3)
	local side = 63 * outer / 30.3 -- RailComet: its comet 30.3 points round in 63 (seam_cut.py)
	local comet = Glass.Mark(holder, "Comet", UIKit.Images.RailComet, 0, 0, side, SEAM.Glint, z + 4, 0.9)
	Glass.Idle(comet, function(phase: number)
		comet.Rotation = 360 * phase
	end)
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

-- A tile's face, laid again on every paint: `state` is "next", "cleared", "open" or "shut".
local function lay(face: Frame, ground: string, k: number, state: string, hard: boolean, cp: number, best: number?, waits: string?)
	face:ClearAllChildren()
	local a = accent(hard)
	local lift = if state == "next" then TILE.Lift else 0
	local w, h = WIDE, TILE.Foot - TILE.Top + lift
	local shut = state == "shut"
	local cut = TILE.Corner
	if state == "next" then
		Glass.Glow(face, "Glow", 0, 0, w, h, TILE.Next.Glow, a.Glow, TILE.Next.GlowAlpha, 1)
	end
	Glass.Fill(face, "Fill", 0, 0, w, h, cut, if shut then TILE.Shut else TILE.Fill, 2)
	if not shut then
		Glass.Wash(face, "Sheen", 0, 0, w, h, cut, SEAM.Glint, function(at: number): number
			return TILE.Sheen.Alpha * math.exp(-at / TILE.Sheen.Fall)
		end, 3)
	end
	if state == "next" then
		Glass.Wash(face, "Wash", 0, 0, w, h, cut, a.Edge, function(at: number): number
			return TILE.Next.Wash * math.clamp(1 - at / (h * 0.85), 0, 1)
		end, 3)
		local glint = Glass.Fill(face, "Glint", 0, 0, w, h, cut, SEAM.Glint, 4)
		local band = Instance.new("UIGradient")
		band.Rotation = 90
		band.Transparency = Glass.Band(h, 10, TILE.Next.Glint)
		band.Offset = Vector2.new(0, -2)
		band.Parent = glint
		Glass.Idle(glint, function(phase: number)
			band.Offset = Vector2.new(0, (-40 + (h + 80) * phase) / h - 0.5)
		end)
		Glass.Edge(face, "Edge", 0, 0, w, h, cut, a.Edge, 1, 0.55, 5)
		Glass.Edge(face, "EdgeIn", 0.8, 0.8, w - 1.6, h - 1.6, cut - 0.8, a.Edge, 1, 0.55, 5)
	elseif shut then
		Glass.Edge(face, "Edge", 0, 0, w, h, cut, SEAM.Edge, TILE.ShutEdge, nil, 5)
	else
		Glass.Edge(face, "Edge", 0, 0, w, h, cut, if hard then a.Edge else SEAM.Facet, TILE.Edge.Top, TILE.Edge.Foot, 5)
		cornerGlint(face, "CornerGlint", 0, 0, w, h, cut, TILE.CornerGlint, 6)
	end
	-- The bed: its picture on its own light.
	local bx, by, bw, bh = BED.Inset, BED.Inset, w - 2 * BED.Inset, BED.Tall
	local bed = Instance.new("Frame")
	bed.Name = "Bed"
	bed.BackgroundTransparency = 1
	bed.ClipsDescendants = true
	bed.Position = UDim2.fromOffset(bx, by)
	bed.Size = UDim2.fromOffset(bw, bh)
	bed.ZIndex = 7
	bed.Parent = face
	Glass.Fill(bed, "Fill", 0, 0, bw, bh, BED.Corner, BED.Fill, 7)
	if not shut then
		local strength = if state == "next" then a.Pictures.Next else a.Pictures.Open
		Glass.Bloom(bed, "Bloom", bw * BED.Bloom.Middle.X, bh * BED.Bloom.Middle.Y, BED.Bloom.Size.X, BED.Bloom.Size.Y, a.Bloom, strength, 8)
	end
	local named = LOOK.Pictures[k]
	local record = if named then IMAGES[if shut then `{named}Shut` else named] else nil
	if record then
		local picture = Instance.new("ImageLabel")
		picture.Name = "Picture"
		picture.BackgroundTransparency = 1
		picture.Image = record.Id
		picture.Size = UDim2.fromOffset(BED.Picture.X, BED.Picture.Y)
		picture.Position = UDim2.fromOffset((bw - BED.Picture.X) / 2, 0)
		picture.ZIndex = 9
		picture.Parent = bed
	end
	Glass.Edge(face, "BedEdge", bx, by, bw, bh, BED.Corner, SEAM.Edge, BED.EdgeAlpha, nil, 10)
	if shut then
		Glass.Mark(face, "Lock", LOCK, bx + bw / 2, by + BED.Lock.Down, BED.Lock.Side, SEAM.Soft, 11)
	end
	badge(face, "Mark", bx + BADGE.In, by + BADGE.In, k, hard, not shut, 12)
	if state == "cleared" then
		check(face, "Check", bx + bw - LOOK.Check.In, by + LOOK.Check.In, LOOK.Check.Radius, hard, 12)
	end
	if state == "next" then
		local G = LOOK.Tag
		local tx, ty = w - G.Right - G.Wide, -G.Up
		Glass.Lit(face, "Tag", tx, ty, G.Wide, G.Tall, litFill(hard), a.Glow, 16, 4, 0.3)
		Glass.Label(face, "TagWords", "Next", SMALL, INK, tx, ty, G.Wide, G.Tall, nil, true, 21)
	end
	-- Its words, under the bed.
	local y = BED.Inset + BED.Tall + 8
	local title = if k == #((Stages.Of(ground) or {}) :: { any }) and (Stages.Last(ground, k) or {} :: any).Kind == "Keeper" then keeperName(ground) else `Stage {k}`
	Glass.Label(face, "Title", title, TITLE, if shut then SEAM.Soft else SEAM.Text, 0, y - 2, w, TITLE + 4, nil, true, 12)
	Glass.Label(face, "Recommended", "Recommended", SMALL, SEAM.Soft, 0, y + 21, w, SMALL + 4, nil, false, 12)
	Glass.Label(face, "Power", `{Hud.Digits(cp)} {Sheet.Said.Power}`, TITLE, if shut then SEAM.Soft else SEAM.Text, 0, y + 36, w, TITLE + 4, nil, true, 12)
	local words: { string } = {}
	if state == "cleared" and best and best > 0 then
		words = { `Best {Read.Clock(best)}` }
	elseif state == "next" then
		words = { "Not cleared" }
	elseif shut and waits and string.sub(waits, 1, 11) == "Clear Stage" then
		words = { string.sub(waits, 1, -7), "first" }
	elseif shut and waits and not hard then
		words = { waits }
	end
	for index, line in words do
		Glass.Label(face, `Words{index}`, line, SMALL, if state == "next" then SEAM.Text else SEAM.Soft, 0, y + 58 + (index - 1) * 17, w, SMALL + 4, nil, false, 12)
	end
end

-- A switch half's face: the lit press when chosen, else quiet; Hard's with its chevrons, and its lock while shut.
local function half(face: Frame, which: string, chosen: boolean, hardShut: boolean, w: number, h: number)
	face:ClearAllChildren()
	local hard = which == "Hard"
	if chosen then
		Glass.Lit(face, "Plate", 0, 0, w, h, litFill(hard), accent(hard).Glow, 1)
	else
		Glass.Quiet(face, "Plate", 0, 0, w, h, if hard then LOOK.Accent.Hard.Edge else SEAM.Facet, 1)
	end
	local colour = if chosen then INK else SEAM.Text
	if hard then
		chevrons(face, "Chevrons", 16, h / 2, 11, if chosen then INK else LOOK.Accent.Hard.Edge, 7)
		Glass.Label(face, "Words", which, SMALL, colour, 27, 0, w - 27, h, Enum.TextXAlignment.Left, true, 7)
		if hardShut then
			Glass.Mark(face, "Lock", LOCK, w - 9, 9, LOOK.Switch.Lock, if chosen then INK else SEAM.Soft, 7)
		end
	else
		Glass.Label(face, "Words", which, SMALL, colour, 0, 0, w, h, nil, true, 7)
	end
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

function StageScreen.Pick(ground: string, view: Profile.View, on: On)
	table.clear(parts)
	local data = view :: any
	local hardShut = Stages.Needs(data, ground, "Hard", 1) == Stages.Keeper
	if hardShut then
		difficulty = "Normal" -- its side opens on Normal while Hard is shut; Hard's tiles then say why
	end
	local named = Grounds.ById[ground] and Grounds.ById[ground].Name or "Stages"
	local opening = Screen.Current() ~= StageScreen.Name
	if opening then
		Screen.Rise({ From = MOTION.Rise, Seconds = MOTION.Open, Cover = MOTION.Open, Sink = 0.14, Uncover = 0.12 })
	end
	local body = Screen.Full(StageScreen.Name, named, "SeamGlass")
	parts.Body = body
	Glass.Ground(body, 1)
	local room = block(body, "Picker")
	room.ZIndex = 2
	parts.Block = room
	local count = #((Stages.Of(ground) or {}) :: { any })
	-- The band: the ground's name, then the switch at its right.
	local band = Screen.Band(StageScreen.Name)
	local switch: { [string]: { Button: TextButton, Face: Frame } } = {}
	local tall = Screen.Row()
	local each = (LOOK.Switch.Wide - LOOK.Switch.Gap) / 2
	if band then
		local title = Glass.Label(band, "Title", named, TITLE, SEAM.Text, Screen.BandLeft + 4, 0, 220, 0, Enum.TextXAlignment.Left, true, 3)
		title.Size = UDim2.new(0, 220, 1, 0)
		parts.Title = title
	end
	-- The tiles, each in a group that fades as it rises in.
	local tiles: { { Group: CanvasGroup, Button: TextButton, Face: Frame } } = {}
	for k = 1, count do
		local group = Instance.new("CanvasGroup")
		group.Name = `Tile{k}`
		group.BackgroundTransparency = 1
		group.Size = UDim2.fromOffset(WIDE + 2 * MARGIN, TILE.Foot - TILE.Top + TILE.Lift + 2 * MARGIN)
		group.Position = UDim2.fromOffset(x(k) - MARGIN, TILE.Top - TILE.Lift - T - MARGIN)
		group.ZIndex = 3
		group.Parent = room
		local stage = k
		local button = Button.new({
			Name = `Stage{k}`,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(WIDE, TILE.Foot - TILE.Top),
			Position = UDim2.fromOffset(MARGIN, MARGIN + TILE.Lift),
			Parent = group,
			OnPress = function(): boolean
				return begin(on, ground, difficulty, stage)
			end,
		})
		tiles[k] = { Group = group, Button = button, Face = faceOf(button) }
		parts[`Stage{k}`] = button
	end
	-- The road along their feet, the ring under the next, the player's power at its start.
	local roadY = ROAD.Y - T
	Glass.Fill(room, "Road", TILE.Pad, roadY - ROAD.Half, W - 2 * TILE.Pad, 2 * ROAD.Half, 3, SEAM.Channel, 2)
	Glass.Edge(room, "RoadEdge", TILE.Pad, roadY - ROAD.Half, W - 2 * TILE.Pad, 2 * ROAD.Half, 3, SEAM.Edge, 0.9, nil, 2)
	local footY = ROAD.Y + LOOK.Foot.Down - T
	Glass.Label(room, "YourPower", "Your power", SMALL, SEAM.Soft, TILE.Pad + 2, footY, 80, SMALL + 4, Enum.TextXAlignment.Left, false, 2)
	local mine = power(view)
	Glass.Label(room, "Power", if mine then `{Hud.Digits(mine)} {Sheet.Said.Power}` else "No lead", TITLE, SEAM.Text, TILE.Pad + LOOK.Foot.Power, footY - 2, 120, TITLE + 4, Enum.TextXAlignment.Left, true, 2)
	local hardWords = Glass.Label(room, "HardWords", "", SMALL, SEAM.Text, W - TILE.Pad - 2 - 330, footY, 330, SMALL + 4, Enum.TextXAlignment.Right, false, 2)
	parts.HardWords = hardWords
	local bloom: ImageLabel? = nil
	local lit: Frame? = nil
	local ringAt: Frame? = nil
	-- Lays every face for the switch's side; `beat` runs the road and the ring in.
	local function paint(beat: boolean)
		local hard = difficulty == "Hard"
		local a = accent(hard)
		local line = Stages.Line(data, ground, difficulty)
		local nextK: number? = nil
		for k, tile in tiles do
			local needs, waits = Stages.Needs(data, ground, difficulty, k)
			local reason = why(ground, needs, waits)
			local state = if reason then "shut" elseif k <= line.Cleared then "cleared" else "next"
			if state == "next" and nextK ~= nil then
				state = "open"
			end
			if state == "next" then
				nextK = k
			end
			local lift = if state == "next" then TILE.Lift else 0
			tile.Button.Position = UDim2.fromOffset(MARGIN, MARGIN + TILE.Lift - lift)
			tile.Button.Size = UDim2.fromOffset(WIDE, TILE.Foot - TILE.Top + lift)
			Button.Set(tile.Button, { Disabled = reason or false })
			tile.Button:SetAttribute("Look", state)
			lay(tile.Face, ground, k, state, hard, Stages.Recommended(ground, difficulty, k), line.Best[k], reason)
			parts[`Stage{k}Power`] = tile.Face:FindFirstChild("Power") :: any
		end
		for which, s in switch do
			half(s.Face, which, which == difficulty, hardShut, each, tall)
		end
		hardWords.Text = if not hard then "" elseif hardShut then `Hard opens when you beat the {keeperName(ground)} on Normal` else `Hard: every foe is {StagesConfig.Offset.Hard} levels higher`
		-- The ground's bloom behind where the player stands, the road lit to it: the next tile, or the last cleared once
		-- every stage is (the whole road walked).
		if bloom then
			bloom:Destroy()
		end
		local stand = nextK or (if line.Cleared > 0 then math.min(line.Cleared, #tiles) else nil)
		local bx = if stand then x(stand) + WIDE / 2 else W / 2
		local by = if stand then TILE.Top + BED.Inset + BED.Tall / 2 - T else 170 - T
		bloom = Glass.Bloom(room, "Bloom", bx, by, 750, 600, a.Bloom, a.BloomAlpha, 1)
		if lit then
			lit:Destroy()
			lit = nil
		end
		if ringAt then
			ringAt:Destroy()
			ringAt = nil
		end
		if stand then
			local fromX, toX = TILE.Pad + 2, x(stand) + WIDE / 2
			local holder, run = roadLight(room, "RoadLit", fromX, toX, roadY, 3, toX - fromX, hard, 3)
			lit = holder
			local made = ring(room, toX, roadY, hard, 6)
			ringAt = made
			parts.Ring = made
			if beat and not GuiService.ReducedMotionEnabled then
				run(0)
				local pop = made:FindFirstChildOfClass("UIScale") :: UIScale
				pop.Scale = 0
				task.delay(if opening then MOTION.RoadAt else MOTION.Drain, function()
					Glass.Ease(holder, MOTION.RoadSeconds, run, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end)
				task.delay((if opening then MOTION.RingAt else MOTION.Drain + MOTION.RoadSeconds * 0.8), function()
					pop.Scale = MOTION.RingFrom
					TweenService:Create(pop, TweenInfo.new(MOTION.RingSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				end)
			end
		end
	end
	if band then
		for index, which in Stages.Difficulties do
			local button = Button.new({
				Name = which,
				Text = "",
				Bare = true,
				Size = UDim2.fromOffset(each, tall),
				Position = UDim2.new(1, -(TILE.Pad + LOOK.Switch.Wide) + (index - 1) * (each + LOOK.Switch.Gap), 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Parent = band,
				OnPress = function(): boolean
					if difficulty == which then
						return true
					end
					difficulty = which
					-- The switch: the tiles cross-fade, the road drains and fills again.
					local fade = MOTION.Switch / 2
					for _, tile in tiles do
						TweenService:Create(tile.Group, TweenInfo.new(fade), { GroupTransparency = 1 }):Play()
					end
					task.delay(if GuiService.ReducedMotionEnabled then 0 else fade, function()
						if room.Parent == nil then
							return
						end
						paint(true)
						for _, tile in tiles do
							TweenService:Create(tile.Group, TweenInfo.new(fade), { GroupTransparency = 0 }):Play()
						end
					end)
					return true
				end,
			})
			switch[which] = { Button = button, Face = faceOf(button) }
			parts[which] = button
		end
	end
	paint(opening)
	-- The opening: each tile rises in, Step apart, as the road fills to the ring.
	if opening and not GuiService.ReducedMotionEnabled then
		for k, tile in tiles do
			local at = tile.Group.Position
			tile.Group.GroupTransparency = 1
			tile.Group.Position = at + UDim2.fromOffset(0, TILE.Rise)
			local info = TweenInfo.new(TILE.Seconds, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, TILE.Start + (k - 1) * TILE.Step)
			TweenService:Create(tile.Group, info, { GroupTransparency = 0, Position = at }):Play()
		end
	end
end

-- The card's marks: the four stages on their road, lit to the one just cleared and on (`run`) to where the player now
-- stands, the next ringed in light, the one just cleared with its check.
local function marks(parent: Instance, x0: number, x1: number, y: number, rows: { string }, hard: boolean, z: number): (number) -> ()
	local a = accent(hard)
	local tab = if hard then BADGE.Box + BADGE.Space else 0
	local step = (x1 - x0 - 12 - BADGE.Side - tab) / 3
	local xs = {}
	for k = 1, 4 do
		xs[k] = x0 + 6 + (k - 1) * step
	end
	Glass.Fill(parent, "MarksRoad", x0, y - 3, x1 - x0, 6, 1.5, SEAM.Channel, z)
	Glass.Edge(parent, "MarksRoadEdge", x0, y - 3, x1 - x0, 6, 1.5, SEAM.Edge, 0.9, nil, z)
	local nextK, just = table.find(rows, "next"), table.find(rows, "just")
	local stop = if nextK then xs[nextK] + 13 else x1 - 1
	local start = if just then xs[just] + 13 else stop
	if nextK and just and nextK < just then
		start = stop
	end
	local _, run = roadLight(parent, "MarksLit", x0 + 1, stop, y, 2, stop - x0, hard, z + 1)
	local share0 = (start - x0 - 1) / math.max(stop - x0 - 1, 1)
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
		badge(parent, `Mark{k}`, bx, by, k, hard, row ~= "shut", z + 3)
		if row == "cleared" then
			check(parent, `Check{k}`, bx, by, 6, hard, z + 8)
		elseif row == "just" then
			local made = check(parent, `Check{k}`, bx, by, 7.5, hard, z + 8)
			Glass.Bloom(made, "Glow", 0, 0, 34, 34, a.Glow, 0.7, z + 7)
			parts.Just = made
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

-- One press on the card: the lit press (an ember into a Hard stage, with Hard's chevrons) or a quiet one.
local function press(parent: Instance, name: string, words: string, x0: number, y0: number, w: number, one: boolean, intoHard: boolean, act: () -> boolean): TextButton
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

function StageScreen.Results(results: { [string]: any }, on: On, view: Profile.View?)
	table.clear(parts)
	local ground, which, stage = results.Ground :: string, results.Difficulty :: string, results.Stage :: number
	local hard, won = which == "Hard", results.Won == true
	local C = LOOK.Card
	local rows = C.Rows
	Screen.Dim(C.Dim)
	if Screen.Current() ~= StageScreen.Name then
		Screen.Rise({ From = MOTION.Rise, Seconds = MOTION.Open, Cover = MOTION.Open, Sink = 0.14, Uncover = 0.12 })
	end
	local body = Screen.Full(StageScreen.Name, "Results", "SeamGlass")
	parts.Body = body
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
	local named = if hard then `Hard Stage {stage}` else `Stage {stage}`
	local opened = results.Opened :: string?
	local nextStage = results.Next :: number?
	local nextWhich = (results.NextDifficulty :: string?) or which
	local gave: { { Icon: string, Words: string, Colour: Color3 } } = {}
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
	local spans: { { Kind: string, Tall: number } } = { { Kind = "Marks", Tall = rows.Marks }, { Kind = "Title", Tall = rows.Title }, { Kind = "Time", Tall = rows.Time } }
	if #gave > 0 then
		table.insert(spans, { Kind = "Gave", Tall = rows.Gave })
	end
	local openedWords: string? = nil
	if won and opened == "Hard" then
		openedWords = "Hard is open"
		table.insert(spans, { Kind = "Opened", Tall = rows.Hard })
	elseif won and opened == "Stage" and nextStage then
		openedWords = `{if hard then "Hard " else ""}Stage {nextStage} is open`
		table.insert(spans, { Kind = "Opened", Tall = rows.Opened })
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
	-- The marks: which stages are cleared, by the player's record; the one just played.
	local cleared = if view then Stages.Line(view :: any, ground, which).Cleared else (if won then stage else stage - 1)
	local markRows: { string } = {}
	local count = #((Stages.Of(ground) or {}) :: { any })
	for k = 1, count do
		markRows[k] = if won and k == stage then "just" elseif k <= cleared then "cleared" elseif k == cleared + 1 then "next" else "shut"
	end
	local y = y0 + C.In
	local play: ((number) -> ())? = nil
	for _, span in spans do
		local h = span.Tall
		if span.Kind == "Marks" then
			play = marks(room, x0 + 16, x0 + w - 16, y + h / 2, markRows, hard, 6)
		elseif span.Kind == "Title" then
			parts.Title = Glass.Label(room, "Title", if won then `{named} cleared` else "Your lead fell", BIG, if won then SEAM.Text else Theme.Colour.Hurt, x0, y, w, h, nil, true, 6)
		elseif span.Kind == "Time" then
			local seconds, best = results.Seconds :: number?, results.Best :: number?
			local row = Instance.new("Frame")
			row.Name = "Time"
			row.BackgroundTransparency = 1
			row.Position = UDim2.fromOffset(x0, y)
			row.Size = UDim2.fromOffset(w, h)
			row.ZIndex = 6
			row.Parent = room
			parts.Time = row
			if not won or seconds == nil then
				Glass.Label(row, "Said", if won then "Cleared" else `{named}: try it again, or grow first`, SMALL, SEAM.Soft, 0, 0, w, h, nil, false, 6)
			elseif best and best >= seconds then
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
				local chip = Instance.new("Frame")
				chip.Name = "NewBest"
				chip.BackgroundTransparency = 1
				chip.Size = UDim2.fromOffset(98, h)
				chip.LayoutOrder = 2
				chip.ZIndex = 6
				chip.Parent = row
				Glass.Fill(chip, "Fill", 0, 0, 98, h, 4, LOOK.Socket, 6)
				Glass.Edge(chip, "Edge", 0, 0, 98, h, 4, LOOK.Ready, 1, nil, 7)
				Glass.Label(chip, "Words", "a new best", SMALL, LOOK.Ready, 0, 0, 98, h, nil, true, 8)
			else
				Glass.Label(row, "Said", `{Read.Clock(seconds)}   ·   best {Read.Clock(best or seconds)}`, SMALL, SEAM.Soft, 0, 0, w, h, nil, false, 6)
			end
		elseif span.Kind == "Gave" then
			local row = Instance.new("Frame")
			row.Name = "Gave"
			row.BackgroundTransparency = 1
			row.Position = UDim2.fromOffset(x0, y)
			row.Size = UDim2.fromOffset(w, h)
			row.ZIndex = 6
			row.Parent = room
			parts.Gave = row
			local list = Instance.new("UIListLayout")
			list.FillDirection = Enum.FillDirection.Horizontal
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.Padding = UDim.new(0, 6)
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Parent = row
			for index, item in gave do
				local cw = 38 + 9 * #item.Words + 8
				local chip = Instance.new("Frame")
				chip.Name = item.Icon
				chip.BackgroundTransparency = 1
				chip.Size = UDim2.fromOffset(cw, h)
				chip.LayoutOrder = index
				chip.ZIndex = 6
				chip.Parent = row
				Glass.Fill(chip, "Fill", 0, 0, cw, h, 4, SEAM.Well, 6)
				Glass.Edge(chip, "Edge", 0, 0, cw, h, 4, SEAM.Edge, 1, nil, 7)
				local record = UIKit.Images[item.Icon]
				if record then
					Glass.Mark(chip, "Icon", record, 5 + 11, h / 2, 22, WHITE, 8)
				end
				Glass.Label(chip, "Words", item.Words, TITLE, item.Colour, 33, 0, cw - 37, h, Enum.TextXAlignment.Left, true, 8)
			end
		elseif span.Kind == "Opened" and openedWords then
			if opened == "Hard" then
				local E = LOOK.Accent.Hard
				Glass.Glow(room, "HardGlow", x0 + 16, y, w - 32, h, 6, E.Glow, 0.3, 6)
				Glass.Fill(room, "HardBand", x0 + 16, y, w - 32, h, 5, LOOK.Socket, 7)
				Glass.Bloom(room, "HardBloom", cx, y + h / 2, 300, h * 2.2, E.Bloom, 0.35, 8)
				Glass.Edge(room, "HardEdge", x0 + 16, y, w - 32, h, 5, E.Edge, 1, nil, 9)
				local row = Instance.new("Frame")
				row.Name = "OpenedRow"
				row.BackgroundTransparency = 1
				row.Position = UDim2.fromOffset(x0 + 16, y)
				row.Size = UDim2.fromOffset(w - 32, h)
				row.ZIndex = 10
				row.Parent = room
				local list = Instance.new("UIListLayout")
				list.FillDirection = Enum.FillDirection.Horizontal
				list.HorizontalAlignment = Enum.HorizontalAlignment.Center
				list.VerticalAlignment = Enum.VerticalAlignment.Center
				list.Padding = UDim.new(0, 18 - 0.6 * 13) -- the cut: each pair's middle 18 out from the words
				list.SortOrder = Enum.SortOrder.LayoutOrder
				list.Parent = row
				local said = Glass.Label(row, "Opened", openedWords, BIG, LOOK.Ready, 0, 0, 0, h, nil, true, 10)
				said.AutomaticSize = Enum.AutomaticSize.X
				said.LayoutOrder = 2
				parts.Opened = said
				for order = 1, 3, 2 do
					chevrons(row, `Chevrons{order}`, 0, 0, 13, E.Edge, 10).LayoutOrder = order
				end
			else
				parts.Opened = Glass.Label(room, "Opened", openedWords, TITLE, LOOK.Ready, x0, y, w, h, nil, true, 6)
			end
		end
		y += h + C.Space
	end
	-- Retry, Next and Home, the one press lit: Next, else Retry on a lost run, else Home.
	local P = C.Presses
	local presses: { { Name: string, Words: string, Wide: number, One: boolean, Hard: boolean, Act: () -> boolean } } = {}
	local retry = function(): boolean
		return begin(on, ground, which, stage)
	end
	local home = function(): boolean
		local answer = on.Home()
		if answer.Ok == true then
			Screen.Close()
			return true
		end
		if type(answer.Says) == "string" and answer.Says ~= "" then
			on.Say(answer.Says)
		end
		return false
	end
	if won and nextStage then
		local into = nextWhich
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.Quiet, One = false, Hard = false, Act = retry })
		table.insert(presses, { Name = "Next", Words = `Stage {nextStage}`, Wide = P.One, One = true, Hard = into == "Hard", Act = function(): boolean
			return begin(on, ground, into, nextStage)
		end })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = P.Quiet, One = false, Hard = false, Act = home })
	elseif won then
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.Home, One = false, Hard = false, Act = retry })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = P.Home, One = true, Hard = false, Act = home })
	else
		table.insert(presses, { Name = "Retry", Words = "Retry", Wide = P.Retry, One = true, Hard = hard, Act = retry })
		table.insert(presses, { Name = "Home", Words = "Home", Wide = P.Home, One = false, Hard = false, Act = home })
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
StageScreen.Check = check
StageScreen.Road = roadLight
StageScreen.Accent = accent

function StageScreen.Parts(): { [string]: Instance }
	return parts
end

function StageScreen.Difficulty(): string
	return difficulty
end

-- Its images made ready before the first opening: the picker's, the line's and the card's.
do
	local own: { UIKit.Image } = { CHEVRONS, LOCK }
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
