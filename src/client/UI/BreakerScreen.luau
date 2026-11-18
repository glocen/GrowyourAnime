--!strict
-- BreakerScreen (client): the Void Breaker's screen, in grey (TR9; docs/ui.md, "The screens of the first loop", 3). The
-- chambers as they stand, each shard with its crack's progress and its time left; what's ready, what waits and what's in
-- the bag; one tap on a shard shows its odds (Rules.Odds, never copied) and voltage as a clear choice, its price in kWh
-- and the time it saves (TR18; docs/design.md, "Power"; Rules.Power.Voltage, Rules.Base.Infuse). Machine, the director's
-- pick of the blockout's three (2026-11-14, night), with research's fixes: a ready shard's chip glows gold and opens on
-- one tap; a chamber whose shard finishes flashes gold "Ready" as it hands the shard to the strip; a locked chamber
-- says what opens it. Every change is asked of the server through the owner's Act, and the screen is rebuilt from the
-- server's copy.
--   BreakerScreen.Open(view, on)    builds it (on: Act, Open a ready shard); again on each change of the save
--   BreakerScreen.Tick(now)         the countdowns and the bars, from the base as it stands now; a shard finishing flashes
--   BreakerScreen.Selected()        the chosen shard, for tests
--   BreakerScreen.Select(selection) a tap on a shard, for tests
--   BreakerScreen.Flashing()        the chambers flashing now, by index, for tests
--   BreakerScreen.Tap(target)       a tap on a chamber's or a chip's tap target, for tests
--   BreakerScreen.Still(on)         for tests: the sky held as reduced motion holds it (nil: as the player's setting says)
--   BreakerScreen.Fall(at?)         for tests: the next star falls now; `at` holds it at that share of its path
-- The galaxy (TR41; AR12's images, the director's "ok we keep it", 2026-11-15): the panel's body is a still night with
-- one river of mist sliding along the chambers' row, six stars breathing and now and then a star falling in the last
-- chamber's window. A chamber is glass on it: a solid strip for its number, a window, a solid plate for its words.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Odds = require(Shared.Rules.Odds)
local Hud = require(Shared.Rules.Hud)
local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Hover = require(UI.Kit.Hover)
local Text = require(UI.Kit.Text)
local Row = require(UI.Kit.Row)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Skin = require(UI.Kit.Skin)
local ShardTag = require(UI.ShardTag)

local BreakerScreen = {}

export type Selection = { Kind: string, Index: number, Def: string } -- Kind: "Chamber", "Line", "Ready" or "Bag"
export type On = { Act: (name: string, args: any) -> { [string]: any }, Open: (index: number) -> () }

local NAME = "Breaker"
local SIZE = Vector2.new(660, 320)
local CHIP = Vector2.new(144, 52) -- its shard's picture (Config.Hud.ShardArt.Chip) and a gap left of 112 for its words
local HEADING = 20
local LINE = 18
local SKY = HudConfig.Breaker.Sky
local NUMBER_PAD = 6 -- "Chamber N" from its strip's left: whole at the smallest phone's text

-- The room a chamber's plate takes: a working one's name, its crack, its time and, infused, its line; an empty or locked
-- one's single word.
local function plateFor(working: boolean, infused: boolean): number
	if not working then
		return 2 + LINE + 2
	end
	return 2 + LINE + 2 + Theme.Size.Bar + 2 + LINE + (if infused then LINE else 0) + 2
end
-- What opens a locked chamber (research, TR9, 2026-11-14, night), said once over the row: at the kit's smallest text it
-- won't fit a plate beside "Locked" (research's fix 1 on the galaxy, AR12, 2026-11-15: "say it once").
local LOCKED = "Upgrade the Breaker"

local selected: Selection? = nil
local pending: Selection? = nil -- a shard just put in, chosen where the server says it stands once the save shows it
local pendingUntil = 0
local rates = false -- the chosen shard's drop rates open in the pane, in place of its voltage
local PENDING = 3 -- seconds a shard put in waits to be chosen
local tickers: { (now: Read.Base) -> () } = {}
local rebuild: () -> () = function() end

-- A shard finishing: the base as last seen, advanced to then, so the next look can tell which chamber handed one over.
type Ended = { Index: number, Left: number } -- a chamber whose shard ended, and how near done it was
type Seen = { Ready: number, Chambers: { [number]: { Def: string, Done: number, Left: number } } }
local seen: Seen? = nil
local flashes: { [number]: number } = {} -- chamber index: os.clock() its flash began
local arrivals: { [number]: number } = {} -- Ready index: os.clock() its shard came from a chamber

-- The galaxy's moving layers, laid again at each build (the stars once a screen), and the clock they move by.
type Star = { Image: ImageLabel, Seconds: number, Start: number }
type Sky = { Mist: { ImageLabel }, Lights: { ImageLabel }, Fall: ImageLabel?, Stars: { Star } }
local sky: Sky = { Mist = {}, Lights = {}, Fall = nil, Stars = {} }
local opened = 0 -- os.clock() at the screen's fresh opening
local nextFall = math.huge -- os.clock() the next star falls
local fallFrom = 0 -- os.clock() the falling star set off, or 0
local still: boolean? = nil -- for tests: held still, or nil for the player's setting
local heldFall: number? = nil -- for tests: the falling star held at this share of its path
local moving: RBXScriptConnection? = nil

-- Every shard on the screen, in its order: ready, the chambers, the line, the bag.
local function shardsOf(view: Profile.View): { Selection }
	local out: { Selection } = {}
	for index, work in view.Base.Ready do
		table.insert(out, { Kind = "Ready", Index = index, Def = work.Def })
	end
	for index, chamber in view.Base.Chambers do
		if chamber.Work then
			table.insert(out, { Kind = "Chamber", Index = index, Def = chamber.Work.Def })
		end
	end
	for index, work in view.Base.Line do
		table.insert(out, { Kind = "Line", Index = index, Def = work.Def })
	end
	local bag: { string } = {}
	for id, count in view.Bag.Shards do
		if count > 0 then
			table.insert(bag, id)
		end
	end
	table.sort(bag)
	for index, id in bag do
		table.insert(out, { Kind = "Bag", Index = index, Def = id })
	end
	return out
end

local function same(a: Selection?, b: Selection?): boolean
	return a ~= nil and b ~= nil and a.Kind == b.Kind and a.Index == b.Index and a.Def == b.Def
end

-- The chosen shard if it's still where it was, else the first shard breaking, else the first of any.
local function settle(view: Profile.View): Selection?
	local all = shardsOf(view)
	if pending and os.clock() > pendingUntil then
		pending = nil
	end
	for _, item in all do
		if same(item, pending) then
			pending = nil
			return item
		end
	end
	for _, item in all do
		if same(item, selected) then
			return item
		end
	end
	for _, item in all do
		if item.Kind == "Chamber" then
			return item
		end
	end
	return all[1]
end

local function workOf(data: Profile.View, item: Selection): Profile.ShardWork?
	if item.Kind == "Chamber" then
		local chamber = data.Base.Chambers[item.Index]
		return if chamber then chamber.Work else nil
	elseif item.Kind == "Line" then
		return data.Base.Line[item.Index]
	elseif item.Kind == "Ready" then
		return data.Base.Ready[item.Index]
	end
	return nil
end

-- A shard by what tells it apart on the machine: its grade ("Standard"), or whose it is ("Watt's shard").
local function shortName(def: string): string
	local row = Shards.ById[def]
	if row == nil or row.Holds ~= "" then
		return Read.ShardName(def)
	end
	return row.Grade
end

-- The pane's title: "Lantern Row shard · Standard", or "Watt's shard".
local function fullName(def: string): string
	local row = Shards.ById[def]
	return if row and row.Holds == "" then `{Read.ShardName(def)} · {row.Grade}` else Read.ShardName(def)
end


local RATE_INDENT = 10 -- a Voidkin's row under its rarity's line, in the drop rates
-- The list's mark on the Drop rates button, three bars left of its word: their size, the label's shift right to make
-- their room, and the mark's middle from the button's, authored ("Drop rates" is about 62 across at the caption's size).
local RATE_MARK = { Wide = 10, Thick = 2, Pitch = 4, Inset = 7, At = -33 }

-- The voltage levels by name, Config.Shards.Voltage.Levels' order (the director, 2026-11-15: "real electrician words").
local LEVELS = { "Low voltage", "High voltage" }

-- Whether a shard is infused: given its voltage (TR18), or an old save's luck before voltage replaced it.
local function charged(work: Profile.ShardWork?): boolean
	return work ~= nil and (work.Volt ~= nil or work.Luck > 0)
end

-- The voltage a shard was given, by name, or nil (none, or an old save's luck, which had no level).
local function levelOf(work: Profile.ShardWork): string?
	return if work.Volt then LEVELS[work.Volt] else nil
end

-- A shard's infusion by the level put in: "Infused · Low voltage".
local function infused(work: Profile.ShardWork): string
	local level = levelOf(work)
	return if level then `Infused · {level}` else "Infused"
end

local function ordinal(n: number): string
	local last = n % 10
	local suffix = if n % 100 >= 11 and n % 100 <= 13 then "th" elseif last == 1 then "st" elseif last == 2 then "nd" elseif last == 3 then "rd" else "th"
	return `{n}{suffix}`
end

-- Where a shard stands, in a line: "Chamber 1 · 12 s left", "Waiting, 2nd", "In the bag · 3", "Ready to open".
local function placeOf(item: Selection, now: Read.Base, view: Profile.View): string
	local work = workOf(now.Data, item)
	-- One item of a line whose items a dot parts: its level after a comma.
	local level = if work then levelOf(work) else nil
	local luck = if level then ` · infused, {string.lower(level)}` elseif charged(work) then " · infused" else ""
	if item.Kind == "Chamber" then
		return if work then `Chamber {item.Index} · {Read.Seconds(Read.Left(now, work))} left{luck}` else `Chamber {item.Index}`
	elseif item.Kind == "Line" then
		return `Waiting, {ordinal(item.Index)}{luck}`
	elseif item.Kind == "Ready" then
		return `Ready to open{luck}`
	end
	return `In the bag · {view.Bag.Shards[item.Def] or 0}`
end

local function select(item: Selection?)
	selected = item
	pending = nil
	rebuild()
end

-- Looks at the base as it stands now: a chamber whose shard ended as the ready shards grew handed it over, and flashes.
-- The nearest to done goes first when fewer were handed over than ended (a shard taken out ends one too). True if one
-- began flashing.
local function watch(now: Read.Base): boolean
	local base = now.Data.Base
	local began = false
	local was = seen
	if was and #base.Ready > was.Ready then
		local ended: { Ended } = {}
		for index, before in was.Chambers do
			local chamber = base.Chambers[index]
			local work = if chamber then chamber.Work else nil
			if work == nil or work.Def ~= before.Def or work.Done < before.Done then
				table.insert(ended, { Index = index, Left = before.Left })
			end
		end
		table.sort(ended, function(a: Ended, b: Ended): boolean
			return a.Left < b.Left
		end)
		local gained = #base.Ready - was.Ready
		local at = os.clock()
		for n = 1, math.min(gained, #ended) do
			flashes[ended[n].Index] = at
			began = true
		end
		for index = was.Ready + 1, #base.Ready do
			arrivals[index] = at
		end
	end
	local chambers = {}
	for index, chamber in base.Chambers do
		local work = chamber.Work
		if work then
			chambers[index] = { Def = work.Def, Done = work.Done, Left = Read.Left(now, work) }
		end
	end
	seen = { Ready = #base.Ready, Chambers = chambers }
	return began
end

-- The share of a flash still to run, 1 as it begins and 0 once done, or nil when none runs.
local function flashLeft(started: number?): number?
	local seconds = HudConfig.Breaker.Flash.Seconds
	if started == nil or seconds <= 0 then
		return nil
	end
	local left = 1 - (os.clock() - started) / seconds
	return if left > 0 then left else nil
end

-- A tap target over a whole frame: the cell or chip is the button, its look the panel under it, which answers a pointer.
local taps: { [Instance]: () -> () } = {} -- for tests: what a tap does; emptied at each build
local function tapOver(frame: GuiObject, name: string, onTap: () -> (), also: ((share: number) -> ())?)
	local tap = Instance.new("TextButton")
	tap.Name = name
	tap.Text = ""
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 5
	tap.Activated:Connect(function()
		onTap()
	end)
	taps[tap] = onTap
	tap.Parent = frame
	-- Hover (TR20): the chamber or chip lifts and brightens under the pointer, inside its own place in the list.
	Hover.On(tap, function(share: number, pad: boolean)
		Hover.Lift(frame, share, tap)
		Panel.Hover(frame, share, pad)
		if also then
			also(share)
		end
	end)
end

local function label(parent: Instance, name: string, text: string, size: number, box: UDim2, position: UDim2, props: { [string]: any }?): TextLabel
	local p: { [string]: any } = props or {}
	local made = Text.new({
		Name = name,
		Size = size,
		Font = p.Font,
		Colour = p.Colour,
		Align = p.Align,
		Box = box,
		Position = position,
		Truncate = p.Truncate,
		Wrap = p.Wrap,
		Parent = parent,
	})
	made.Text = text
	return made
end

-- Gold over a chamber that has just handed its shard to the strip: the box lit, "Ready" across it, held, then fading;
-- laid again on each rebuild for what's left of it.
local function flashOver(frame: GuiObject, started: number)
	local left = flashLeft(started)
	if left == nil then
		return
	end
	local tune = HudConfig.Breaker.Flash
	local over = Instance.new("Frame")
	over.Name = "Flash"
	over.BackgroundTransparency = 1
	over.AnchorPoint = Vector2.new(0.5, 0.5)
	over.Position = UDim2.fromScale(0.5, 0.5)
	over.Size = UDim2.fromScale(1, 1)
	over.ZIndex = 4
	over.Parent = frame
	local fill = Skin.Lay(over, "PanelFill", { Name = "Fill", Tint = Theme.Colour.Ready, Alpha = 0.9, Z = 1 })
	local edge = Skin.Lay(over, "PanelEdgeBold", { Name = "Edge", Tint = Theme.Colour.Ready, Alpha = 1, Z = 2 })
	local word = label(over, "Ready", "Ready", Theme.Text.Title, UDim2.new(1, 0, 0, 26), UDim2.fromScale(0, 0.5), { Font = Theme.Font.Number, Colour = Theme.Colour.ReadyWords, Align = Enum.TextXAlignment.Center })
	word.AnchorPoint = Vector2.new(0, 0.5)
	word.ZIndex = 3
	local elapsed = (1 - left) * tune.Seconds
	local hold = math.max(tune.Hold - elapsed, 0)
	local fade = TweenInfo.new(math.max(left * tune.Seconds - hold, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, hold)
	TweenService:Create(fill, fade, { ImageTransparency = 1 }):Play()
	TweenService:Create(edge, fade, { ImageTransparency = 1 }):Play()
	TweenService:Create(word, fade, { TextTransparency = 1 }):Play()
	if elapsed < 0.05 then -- landing: the box pops, once
		local scale = Instance.new("UIScale")
		scale.Scale = tune.Pop
		scale.Parent = over
		TweenService:Create(scale, Theme.Motion.Slow, { Scale = 1 }):Play()
	end
end

-- A chamber as it stands: its shard's name, the crack's progress as a conduit filling, the time left; empty or locked.
-- While gold fades over it, what it holds next waits under it: its words show once the gold is gone, never through
-- "Ready" (TR9's retake, research's fix, 2026-11-15).
-- Seconds drawn at random between a range's two ends.
local function between(range: { number }): number
	return range[1] + math.random() * (range[2] - range[1])
end

local function image(name: string, id: string, parent: Instance): ImageLabel
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Image = id
	made.Parent = parent
	return made
end

-- The still night in the panel's shape and its six stars, on the panel's own fill and under its facet, edge and glint:
-- laid once a screen and kept through its rebuilds (the body is cleared, the panel's skin isn't). The places are shares
-- of the mock's panel, so the night carries ours.
local function night(panel: GuiObject)
	local skin = Skin.Of(panel)
	if skin:FindFirstChild("Sky") then
		return
	end
	for _, name in { "Facet", "Edge", "Glint" } do -- the fill at 2, the night at 3, these over it
		local layer = skin:FindFirstChild(name)
		if layer and layer:IsA("GuiObject") then
			layer.ZIndex += 1
		end
	end
	local holder = Instance.new("Frame")
	holder.Name = "Sky"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 3
	holder.Parent = skin
	local across = SKY.Panel
	for _, half in { { Name = "Left", Id = SKY.Images.Left, Part = SKY.Left }, { Name = "Right", Id = SKY.Images.Right, Part = SKY.Right } } do
		local made = image(half.Name, half.Id, holder)
		made.Position = UDim2.fromScale(half.Part.At / across.X, 0)
		made.Size = UDim2.fromScale(half.Part.Wide / across.X, 1)
	end
	sky.Stars = {}
	for index, star in SKY.Stars.Each do
		local side = math.floor(SKY.Stars.Side * star.Size + 0.5) -- an offset is whole points
		local made = image(`Star{index}`, SKY.Images.Star, holder)
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Position = UDim2.fromScale(star.At.X / across.X, star.At.Y / across.Y)
		made.Size = UDim2.fromOffset(side, side)
		made.ImageColor3 = Color3.fromHex(star.Tint)
		made.ZIndex = 2
		table.insert(sky.Stars, { Image = made, Seconds = star.Seconds, Start = star.Start })
	end
end

-- One band of mist along the chambers' row, gaps included, behind them: two copies of its lumps slide inside a group that
-- holds still and carries the river's colour as one gradient, so the colour stays put while the lumps move (research's
-- read of AR12's images, 2026-11-15). The image lies so the json's band meets the windows' band down a chamber `height`
-- tall, from `y`; its cover fades down its height, which sliding never changes.
local function mist(parent: Instance, y: number, height: number)
	local m = SKY.Mist
	local band = (SKY.Band.Foot - SKY.Band.Top) * height
	local tall = math.floor(band / (m.Foot - m.Top) + 0.5) -- an offset is whole points
	local turn = math.floor(m.Image.X * tall / m.Image.Y + 0.5)
	local group = Instance.new("CanvasGroup")
	group.Name = "Mist"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.Size = UDim2.new(1, 0, 0, tall)
	group.Position = UDim2.fromOffset(0, y + SKY.Band.Top * height - m.Top * tall)
	group.ZIndex = 1
	group.Parent = parent
	local colours = {}
	for _, stop in m.Tint do
		table.insert(colours, ColorSequenceKeypoint.new(stop[1] :: number, Color3.fromHex(stop[2] :: string)))
	end
	local river = Instance.new("UIGradient")
	river.Name = "River"
	river.Color = ColorSequence.new(colours)
	river.Parent = group
	local covers = {}
	for _, stop in m.Down do
		table.insert(covers, NumberSequenceKeypoint.new(stop[1], 1 - stop[2]))
	end
	sky.Mist = {}
	for copy = 1, 2 do
		local made = image(`Lumps{copy}`, SKY.Images.Mist, group)
		made.Size = UDim2.fromOffset(turn, tall)
		made:SetAttribute("Turn", turn)
		local down = Instance.new("UIGradient")
		down.Name = "Down"
		down.Rotation = 90
		down.Transparency = NumberSequence.new(covers)
		down.Parent = made
		table.insert(sky.Mist, made)
	end
end

-- The falling star's window: chamber `index`'s band, under its glass, of `most` across the row.
local function fallingBox(parent: Instance, index: number, most: number, y: number, height: number)
	local gap = Theme.Size.Gap
	local box = Instance.new("Frame")
	box.Name = "Falling"
	box.BackgroundTransparency = 1
	box.ClipsDescendants = true
	box.Position = UDim2.new((index - 1) / most, (index - 1) * gap / most, 0, y + SKY.Band.Top * height)
	box.Size = UDim2.new(1 / most, -gap * (most - 1) / most, 0, (SKY.Band.Foot - SKY.Band.Top) * height)
	box.ZIndex = 2
	box.Parent = parent
	local made = image("Star", SKY.Images.Falling, box)
	made.Size = UDim2.fromOffset(SKY.Falling.Points.X, SKY.Falling.Points.Y)
	made.ImageTransparency = 1
	sky.Fall = made
end

-- A chamber's glass: its body in the glass's colour, solid over its strip (to `top`) and its plate (from `foot`), covering
-- Window of the sky between them, Locked's when it's locked. The fill reaches its pad past the box, so the stops are laid
-- in its own height. Its shadow would darken the window, so it goes.
local function glass(frame: GuiObject, height: number, top: number, foot: number, open: boolean)
	local g = SKY.Glass
	local colour = Color3.fromHex(g.Colour)
	frame:SetAttribute("Body", colour) -- Panel.Hover whitens this, not the palette's
	local folder = frame:FindFirstChild("NL_Skin")
	local shadow = if folder then folder:FindFirstChild("Shadow", true) else nil
	if shadow then
		shadow:Destroy()
	end
	local fill = if folder then folder:FindFirstChild("Fill", true) :: ImageLabel? else nil
	if fill == nil then
		return
	end
	Skin.Tint(fill, ColorSequence.new(colour))
	fill.ImageTransparency = 0
	local gradient = fill:FindFirstChildOfClass("UIGradient")
	if gradient == nil then
		return
	end
	local pad = fill.Size.Y.Offset / 2
	local whole = height + 2 * pad
	local function at(y: number): number
		return math.clamp((y + pad) / whole, 0, 1)
	end
	local clear = 1 - (if open then g.Window else g.Locked)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(at(top), 0),
		NumberSequenceKeypoint.new(at(top + g.Under * height), clear),
		NumberSequenceKeypoint.new(at(foot - g.Over * height), clear),
		NumberSequenceKeypoint.new(at(foot), 0),
		NumberSequenceKeypoint.new(1, 0),
	})
end

local function held(): boolean
	if still ~= nil then
		return still
	end
	return GuiService.ReducedMotionEnabled
end

-- The sky's motion, each frame, from the screen's clock: the mist slides, the stars and a shard's light breathe, and a
-- star falls when it's due. Held still, the screen is the still: the mist and the stars at their start, no star falls.
local function move()
	local now = os.clock()
	local hold = held()
	local t = if hold then 0 else now - opened
	for copy, lumps in sky.Mist do
		-- Slid by scale, which takes a share of a point: an offset is whole points, and the drift is 2.5 a second.
		local turn = lumps:GetAttribute("Turn")
		local group = lumps.Parent
		if type(turn) == "number" and turn > 0 and group and group:IsA("GuiObject") and group.AbsoluteSize.X > 0 then
			local shift = -((t * SKY.Mist.Drift) % turn) + (copy - 1) * turn
			lumps.Position = UDim2.fromScale(shift * (lumps.AbsoluteSize.X / turn) / group.AbsoluteSize.X, 0)
		end
	end
	for _, star in sky.Stars do
		star.Image.ImageTransparency = 1 - (0.775 + 0.225 * math.sin(2 * math.pi * (t / star.Seconds + star.Start)))
	end
	local l = SKY.Light
	local cover = l.Cover + l.Swell * math.sin(2 * math.pi * t / l.Breath)
	for _, light in sky.Lights do
		light.ImageTransparency = 1 - cover
	end
	local fall = sky.Fall
	local f = SKY.Falling
	if heldFall and fall and not hold then
		local head = f.From:Lerp(f.To, heldFall)
		fall.Position = UDim2.new(head.X, -f.Head.X, head.Y, -f.Head.Y)
		fall.ImageTransparency = 1 - math.sin(math.pi * heldFall) ^ 0.6
		return
	end
	if hold then
		fallFrom = 0
		if fall then
			fall.ImageTransparency = 1
		end
		return
	end
	if fallFrom == 0 and now >= nextFall then
		fallFrom = now
		nextFall = now + between(f.Every)
	end
	if fallFrom > 0 then
		local s = (now - fallFrom) / f.Seconds
		if s >= 1 then
			fallFrom = 0
		end
		if fall then
			local head = f.From:Lerp(f.To, math.clamp(s, 0, 1))
			fall.Position = UDim2.new(head.X, -f.Head.X, head.Y, -f.Head.Y)
			fall.ImageTransparency = if s >= 1 then 1 else 1 - math.sin(math.pi * s) ^ 0.6
		end
	end
end

local function cell(parent: Instance, index: number, view: Profile.View, width: UDim, height: number, plate: number, side: number)
	local open = index <= #view.Base.Chambers
	local chamber = if open then view.Base.Chambers[index] else nil
	local work = if chamber then chamber.Work else nil
	local item: Selection? = if work then { Kind = "Chamber", Index = index, Def = work.Def } else nil
	local frame = Panel.new({
		Name = `Chamber{index}`,
		Size = UDim2.new(width, UDim.new(0, height)),
		Edge = true,
		LayoutOrder = index,
		Parent = parent,
	})
	-- Glass on the sky (TR41): its number on the strip, its shard in the window, its words on the plate.
	local top = HudConfig.Breaker.Strip
	local foot = height - plate
	glass(frame, height, top, foot, open)
	local pad = Theme.Size.Pad
	local inner = UDim2.new(1, -pad * 2, 0, LINE)
	local centre = { Font = Theme.Font.Strong, Truncate = true, Align = Enum.TextXAlignment.Center }
	label(frame, "Number", `Chamber {index}`, Theme.Text.Caption, UDim2.new(1, -NUMBER_PAD * 2, 0, LINE), UDim2.fromOffset(NUMBER_PAD, (top - LINE) / 2), { Colour = Theme.Colour.TextDim, Truncate = true })
	local flash = flashes[index]
	local gold = if flash then flashLeft(flash) else nil
	if flash then
		if gold then
			flashOver(frame, flash)
		else
			flashes[index] = nil
		end
	end
	local function later(piece: GuiObject)
		if gold then
			piece.Visible = false
			task.delay(gold * HudConfig.Breaker.Flash.Seconds, function()
				piece.Visible = true
			end)
		end
	end
	if work == nil then -- what opens a locked one is said once over the row
		later(label(frame, "Name", if open then "Empty" else "Locked", Theme.Text.Caption, inner, UDim2.fromOffset(pad, foot + 2), { Colour = Theme.Colour.Disabled, Align = Enum.TextXAlignment.Center }))
		return
	end
	local w = work :: Profile.ShardWork
	-- The soft light behind its shard, in its window only (the json's light, working).
	local tall = foot - top
	local window = Instance.new("Frame")
	window.Name = "Window"
	window.BackgroundTransparency = 1
	window.ClipsDescendants = true
	window.Position = UDim2.fromOffset(0, top)
	window.Size = UDim2.new(1, 0, 0, tall)
	window.Parent = frame
	local l = SKY.Light
	local light = image("Light", SKY.Images.Light, window)
	light.AnchorPoint = Vector2.new(0.5, 0.5)
	light.Position = UDim2.new(0.5, 0, 0, tall / 2)
	light.Size = UDim2.fromOffset(l.Side * l.Radius, l.Side * l.Radius)
	light.ImageColor3 = Color3.fromHex(l.Tint)
	light.ImageTransparency = 1 - l.Cover
	table.insert(sky.Lights, light)
	later(window)
	-- Its shard in the window's middle, `side` points (AR12, research's call); on the plate under it, its name, its
	-- crack, its time, and, infused, one line saying so: the level is the pane's and the odds', as on a chip.
	local art = HudConfig.ShardArt
	local row = Shards.ById[w.Def]
	local picture = Skin.Icon(frame, Hud.ShardPicture(if row then row.Grade else "Standard", side, art.Large), 0, 0, side)
	picture.Name = "Picture"
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.new(0.5, 0, 0, top + tall / 2)
	picture.ZIndex = 2
	ShardTag.Lay(picture, w.Def, side) -- where it came from (TR41 (d))
	later(picture)
	local y = foot + 2
	later(label(frame, "Name", shortName(w.Def), Theme.Text.Caption, inner, UDim2.fromOffset(pad, y), centre))
	y += LINE + 2
	local bar = Bar.new({ Name = "Crack", Size = UDim2.new(1, -pad * 2, 0, Theme.Size.Bar), Position = UDim2.fromOffset(pad, y), Colour = Theme.Colour.Electricity, Parent = frame })
	later(bar)
	y += Theme.Size.Bar + 2
	local left = label(frame, "Left", "", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, y), { Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Center })
	later(left)
	if charged(w) then
		later(label(frame, "Infused", "Infused", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, y + LINE), { Colour = Theme.Colour.ElectricityWords, Align = Enum.TextXAlignment.Center }))
	end
	table.insert(tickers, function(now: Read.Base)
		local current = now.Data.Base.Chambers[index]
		local at = if current then current.Work else nil
		if at and left.Parent then
			local total = Breaker.Cost(at.Def) or 1
			Bar.Set(bar, math.clamp(at.Done / math.max(total, 1e-3), 0, 1))
			left.Text = `{Read.Clock(Read.Left(now, at))} left` -- a clock: "1 min 20 s left" outgrew the cell at the smallest phone
		end
	end)
	Panel.Lit(frame, same(item, selected))
	tapOver(frame, "Tap", function()
		select(item)
	end)
end

-- A ready shard's chip, the loudest thing on the screen (TR9, fix (a)): a gold edge, bold, over a gold fill that breathes,
-- and, as it arrives from a chamber, a pop. "Ready" is its first word. Returns its hover's paint: under the pointer or
-- a pad's selection the breath holds at its High, since the body's whitening is lost under its gold (TR20's verdict), and
-- it breathes on from where it paused when the pointer leaves.
local function glow(frame: GuiObject, item: Selection): (share: number) -> ()
	Panel.Trim(frame, Theme.Colour.Ready)
	local folder = frame:FindFirstChild("NL_Skin")
	local edge = if folder then folder:FindFirstChild("Edge", true) :: ImageLabel? else nil
	if edge then
		Skin.Set(edge, "PanelEdgeBold", {})
		edge.ImageTransparency = 0
	end
	local tune = HudConfig.Breaker.Glow
	local fill = Skin.Lay(Skin.Of(frame), "PanelFill", { Name = "Glow", Tint = Theme.Colour.Ready, Alpha = tune.Low, Z = 3 })
	local active: Tween? = nil -- the breath, or the settle after an arrival
	local function breathe()
		local period = TweenInfo.new(math.max(tune.Period, 0.05), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local breath = TweenService:Create(fill, period, { ImageTransparency = 1 - tune.High })
		active = breath
		breath:Play()
	end
	local came = arrivals[item.Index]
	if came and flashLeft(came) then
		-- Just handed over by a chamber: it lands lit as the chamber's flash, and settles into its breath.
		arrivals[item.Index] = nil -- once: a rebuild shows it as it stands
		fill.ImageTransparency = 0.1
		local settle = TweenService:Create(fill, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 - tune.Low })
		active = settle
		settle.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and fill.Parent then
				breathe()
			end
		end)
		settle:Play()
	else
		breathe()
	end
	local paused: number? = nil -- the breath's transparency when the pointer came
	return function(share: number)
		if share > 0 then
			if paused == nil then
				paused = fill.ImageTransparency
				if active then
					active:Pause()
				end
			end
			local from = paused :: number
			fill.ImageTransparency = from + (1 - tune.High - from) * share
		elseif paused ~= nil then
			fill.ImageTransparency = paused
			paused = nil
			if active and fill.Parent then
				active:Play()
			end
		end
	end
end

-- A shard that's ready, waiting or in the bag, as a chip on the strip. A ready one opens on one tap; the rest are chosen.
local function chip(parent: Instance, item: Selection, view: Profile.View, order: number, on: On)
	local frame = Panel.new({
		Name = `{item.Kind}{item.Index}`,
		Size = UDim2.fromOffset(CHIP.X, CHIP.Y),
		Colour = Theme.Colour.PlateHigh,
		Transparency = if item.Kind == "Bag" then 0.6 else 0.3,
		Edge = true,
		LayoutOrder = order,
		Parent = parent,
	})
	local pad = Theme.Size.Pad
	-- Its grade's picture on the left, the small one at a chip's size (AR12); the words beside it.
	local art = HudConfig.ShardArt
	local row = Shards.ById[item.Def]
	local picture = Skin.Icon(frame, Hud.ShardPicture(if row then row.Grade else "Standard", art.Chip, art.Large), pad + art.Chip / 2, CHIP.Y / 2, art.Chip)
	picture.Name = "Picture"
	picture.ZIndex = 2
	ShardTag.Band(frame, item.Def, CHIP.Y) -- where it came from, along its foot (TR41 (d))
	local words = pad + art.Chip + Theme.Size.Gap
	local ready = item.Kind == "Ready"
	local work = workOf(view, item)
	local infusedMark = if charged(work) then " · infused" else ""
	local top = if ready then "Ready" else shortName(item.Def)
	local under = if ready then `{shortName(item.Def)}{infusedMark}`
		elseif item.Kind == "Line" then `Waiting, {ordinal(item.Index)}{infusedMark}`
		else `In the bag · {view.Bag.Shards[item.Def] or 0}`
	local name = label(frame, "Name", top, if ready then Theme.Text.Body else Theme.Text.Caption, UDim2.new(1, -(words + pad), 0, LINE), UDim2.fromOffset(words, 6), { Font = if ready then Theme.Font.Number else Theme.Font.Strong, Colour = if ready then Theme.Colour.Ready else nil, Truncate = true })
	name.ZIndex = 2
	local detail = label(frame, "Detail", under, Theme.Text.Caption, UDim2.new(1, -(words + pad), 0, LINE), UDim2.fromOffset(words, 6 + LINE + 2), { Colour = if ready then Theme.Colour.Text else Theme.Colour.TextDim, Truncate = true })
	detail.ZIndex = 2
	if ready then
		local held = glow(frame, item)
		tapOver(frame, "Tap", function()
			on.Open(item.Index)
		end, held)
		return
	end
	Panel.Lit(frame, same(item, selected))
	tapOver(frame, "Tap", function()
		select(item)
	end)
end

-- The chambers side by side, `height` tall: those open, and the rest locked up to the most a Breaker has.
local function machine(parent: Instance, view: Profile.View, height: number)
	label(parent, "ChambersTitle", "Chambers", Theme.Text.Caption, UDim2.new(1, 0, 0, HEADING), UDim2.new(), { Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim })
	local most = math.max(BaseConfig.Breaker.MostChambers, #view.Base.Chambers)
	if most > #view.Base.Chambers then
		label(parent, "Opens", LOCKED, Theme.Text.Caption, UDim2.new(1, 0, 0, HEADING), UDim2.new(), { Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Right })
	end
	local top = HEADING + 2
	mist(parent, top, height)
	fallingBox(parent, math.min(SKY.Falling.Chamber, most), most, top, height)
	local row = Instance.new("Frame")
	row.Name = "Chambers"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, height)
	row.Position = UDim2.fromOffset(0, top)
	row.ZIndex = 3
	row.Parent = parent
	Panel.List(row, Enum.FillDirection.Horizontal, Theme.Size.Gap)
	-- One plate for the row, as tall as its fullest chamber's words, so the windows line up as one band; one picture size,
	-- as large as the window holds up to Chamber, giving way to Least where an infusion takes a line (Config.Hud.ShardArt).
	local plate = plateFor(false, false)
	for _, chamber in view.Base.Chambers do
		if chamber.Work then
			plate = math.max(plate, plateFor(true, charged(chamber.Work)))
		end
	end
	local art = HudConfig.ShardArt
	-- Least where an infusion takes a line; under it only where a short room leaves less (the smallest phone: the small
	-- picture and its mark, as drawn for 40 points), never under a chip's.
	local free = height - HudConfig.Breaker.Strip - plate - 2
	local side = if free >= art.Least then math.min(free, art.Chamber) else math.max(free, art.Chip)
	for index = 1, most do
		cell(row, index, view, UDim.new(1 / most, -Theme.Size.Gap * (most - 1) / most), height, plate, side)
	end
end

-- What's ready, waiting and in the bag, a strip of chips that scrolls sideways, at `y`.
local function strip(parent: Instance, view: Profile.View, y: number, on: On)
	label(parent, "StripTitle", "Ready, waiting and in the bag", Theme.Text.Caption, UDim2.new(1, 0, 0, HEADING), UDim2.fromOffset(0, y), { Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim })
	-- It ends at the machine's column, by the detail panel, softly: a chip cut there fades out, never stands cut mid-word
	-- (research's must-fix on TR41 (a), 2026-11-17).
	local fade = Instance.new("CanvasGroup")
	fade.Name = "StripFade"
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.Size = UDim2.new(1, 0, 0, CHIP.Y + 8)
	fade.Position = UDim2.fromOffset(0, y + HEADING + 2)
	fade.Parent = parent
	local soft = Instance.new("UIGradient")
	soft.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1 - HudConfig.Breaker.Fade, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	soft.Parent = fade
	local list = Instance.new("ScrollingFrame")
	list.Name = "Strip"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.fromScale(1, 1)
	list.ScrollingDirection = Enum.ScrollingDirection.X
	list.ScrollBarThickness = 4
	list.AutomaticCanvasSize = Enum.AutomaticSize.X
	list.CanvasSize = UDim2.new()
	list.Parent = fade
	Panel.List(list, Enum.FillDirection.Horizontal, Theme.Size.Gap)
	local order = 0
	for _, item in shardsOf(view) do
		if item.Kind ~= "Chamber" then
			order += 1
			chip(list, item, view, order, on)
		end
	end
	if order == 0 then
		label(list, "Nothing", "Nothing waits. Shards drop on Lantern Row.", Theme.Text.Caption, UDim2.fromOffset(300, CHIP.Y), UDim2.new(), { Colour = Theme.Colour.TextDim })
	end
end

-- Why infusion can't go in, as the lines a player reads (BreakerScreen.Reasons, for tests). A whole shard's reason
-- stands over the levels; a level's own beside its button, which keeps its price on it, veiled.
local REASONS = {
	Holds = "It holds one Voidkin: no voltage",
	Bag = "Put it in first, then give it voltage",
	Ready = "Already broken: open it",
	Infused = "%s: once a shard",
	Brief = "Saves under a minute: not offered",
	Short = "Needs %s kWh",
	Battery = "Needs a battery of %s kWh: upgrade the base", -- research's words, TR9, 2026-11-14
}

-- Why the chosen shard takes no voltage at all, or nil.
local function blockShard(item: Selection, now: Read.Base): string?
	local row = Shards.ById[item.Def]
	if row and row.Holds ~= "" then
		return REASONS.Holds
	elseif item.Kind == "Bag" then
		return REASONS.Bag
	elseif item.Kind == "Ready" then
		return REASONS.Ready
	end
	local work = workOf(now.Data, item)
	if work and charged(work) then
		return string.format(REASONS.Infused, infused(work))
	end
	return nil
end

-- Why one level can't be paid now, or nil: it saves under a minute, the battery is too small to hold its price, or
-- too little is stored in it. `price` is Rules.Power.Voltage's.
local function blockLevel(now: Read.Base, price: number?): string?
	if price == nil then
		return REASONS.Brief
	elseif price > now.Rates.Capacity then
		return string.format(REASONS.Battery, Read.Number(price))
	elseif now.Data.Base.Charge < price then
		return string.format(REASONS.Short, Read.Number(price))
	end
	return nil
end

local chances: (column: Instance, def: string, luck: number) -> ()

-- A line that wraps and grows to its words, in a column.
local function lines(parent: Instance, name: string, text: string, box: UDim2, order: number, colour: Color3?): TextLabel
	local made = label(parent, name, text, Theme.Text.Caption, box, UDim2.new(), { Colour = colour or Theme.Colour.TextDim })
	made.TextWrapped = true
	made.AutomaticSize = Enum.AutomaticSize.Y
	made.LayoutOrder = order
	return made
end

-- The chosen shard: its name and place over one column that scrolls. First a row: the one thing to do with it, and
-- "Drop rates" beside it, one tap away (docs/ui.md, screen 3). Under the row, its voltage; or, Drop rates lit, every
-- Voidkin it can give under its rarity's total, as the server rolls them.
local function pane(parent: Instance, item: Selection?, view: Profile.View, now: Read.Base, on: On, box: UDim2, position: UDim2)
	local frame = Panel.new({ Name = "Odds", Size = box, Position = position, Parent = parent })
	frame.ZIndex = 10
	frame.Active = true -- a tap on the pane stays on it, never reaching a chamber under the sheet
	local pad = Theme.Size.Pad
	local gap = Theme.Size.Gap
	if item == nil then
		label(frame, "Empty", "No shard yet. They drop on Lantern Row.", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE * 2), UDim2.fromOffset(pad, pad), { Colour = Theme.Colour.TextDim })
		return
	end
	local it = item :: Selection
	label(frame, "Title", fullName(it.Def), Theme.Text.Body, UDim2.new(1, -pad * 2, 0, 22), UDim2.fromOffset(pad, pad), { Font = Theme.Font.Strong, Truncate = true })
	local place = label(frame, "Place", placeOf(it, now, view), Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, pad + 22), { Colour = Theme.Colour.TextDim, Truncate = true })
	table.insert(tickers, function(current: Read.Base)
		if place.Parent then
			place.Text = placeOf(it, current, view)
		end
	end)
	local top = pad + 22 + LINE + gap
	local column = Row.List(frame, "Pane", UDim2.new(1, -pad, 1, -(top + pad)), UDim2.fromOffset(pad, top))
	column:SetAttribute("Keep", `{it.Kind}{it.Index}{it.Def}`) -- another shard's pane starts at its top (Screen)
	-- The one thing to do with it.
	local action: string?, press: (() -> ...any)?, primary: boolean? = nil, nil, nil
	if it.Kind == "Ready" then
		action, primary = "Open", true
		press = function()
			on.Open(it.Index)
		end
	elseif it.Kind == "Chamber" then
		action = "Take out"
		press = function()
			return on.Act("TakeOut", { Chamber = it.Index }).Ok == true
		end
	elseif it.Kind == "Bag" then
		action, primary = "Put it in", true
		press = function()
			local answer = on.Act("AddShard", { Shard = it.Def })
			local index = answer.Chamber or answer.Line
			if answer.Ok == true and type(index) == "number" then
				pending = { Kind = if answer.Chamber then "Chamber" else "Line", Index = index, Def = it.Def }
				pendingUntil = os.clock() + PENDING
				rebuild() -- when the save's copy came before the answer
			end
			return answer.Ok == true
		end
	end
	local first = Instance.new("Frame")
	first.Name = "Do"
	first.BackgroundTransparency = 1
	first.Size = UDim2.new(1, -gap, 0, Theme.Size.Tap)
	first.LayoutOrder = 1
	first.Parent = column
	if action then
		Button.new({ Name = "Action", Text = action, Primary = primary, Size = UDim2.new(0.5, -gap / 2, 1, 0), Parent = first, OnPress = press :: () -> ...any })
	end
	-- A secondary press, half the row whether or not an action stands beside it, with a list's mark and never the
	-- action's light (research's fix, 2026-11-15).
	local fold = Button.new({
		Name = "Rates",
		Text = "Drop rates",
		TextSize = Theme.Text.Caption,
		Quiet = true,
		Inset = RATE_MARK.Inset,
		Size = UDim2.new(0.5, -gap / 2, 1, 0),
		Position = if action then UDim2.new(0.5, gap / 2, 0, 0) else UDim2.new(),
		Parent = first,
		OnPress = function()
			rates = not rates
			rebuild()
			return true
		end,
	})
	Button.Set(fold, { Selected = rates })
	local mark = Instance.new("Frame")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.new(0.5, RATE_MARK.At, 0.5, 0)
	mark.Size = UDim2.fromOffset(RATE_MARK.Wide, RATE_MARK.Pitch * 2 + RATE_MARK.Thick)
	mark.ZIndex = 12
	mark.Parent = fold
	for index = 0, 2 do
		local bar = Instance.new("Frame")
		bar.Name = `Bar{index + 1}`
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Theme.Colour.TextDim
		bar.Position = UDim2.fromOffset(0, index * RATE_MARK.Pitch)
		bar.Size = UDim2.fromOffset(RATE_MARK.Wide, RATE_MARK.Thick)
		bar.ZIndex = 12
		bar.Parent = mark
	end
	if rates then
		local held = workOf(now.Data, it)
		chances(column, it.Def, if held then held.Luck else 0)
		return
	end
	-- Voltage: none at all on a kind it's never offered on (Rules.Power.Offered; research, TR18). Else why none goes in,
	-- if so; then its two levels, each with its price in kWh and, beside it, the time it saves at the Breaker's speed
	-- now, or why that level can't be paid. A shard in the bag is priced from its start.
	if not Power.Offered(it.Def) then
		return
	end
	local whole = blockShard(it, now)
	if whole then
		lines(column, "Why", whole, UDim2.new(1, -gap, 0, LINE), 2, Theme.Colour.Text)
	end
	local fresh: Profile.ShardWork = { Def = it.Def, Luck = 0, Done = 0 }
	local work = workOf(now.Data, it) or fresh
	local speed = math.max(now.Rates.Speed, 1e-3)
	for index, level in ShardConfig.Voltage.Levels do
		local row = Instance.new("Frame")
		row.Name = `Level{index}`
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -gap, 0, Theme.Size.Tap)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = 2 + index
		row.Parent = column
		-- Its name over its price, two lines: "High voltage" and a price don't fit one line of a phone's button.
		local price, saved = Power.Voltage(work, index)
		local name = LEVELS[index] or `Level {index}`
		local text = if price then `{name}\n{Read.Number(price)} kWh` else name
		local button = Button.new({
			Name = `Infuse{index}`,
			Text = text,
			Size = UDim2.new(0.5, -gap / 2, 0, Theme.Size.Tap),
			Parent = row,
			OnPress = function()
				local args: { [string]: any } = { Def = it.Def, Level = index }
				args[it.Kind] = it.Index
				return on.Act("Infuse", args).Ok == true
			end,
		})
		local short = blockLevel(now, price)
		if whole or short then
			Button.Set(button, { Disabled = text }) -- veiled with its price still on it; the reason is the line beside it
		end
		local says = if whole == nil and short then short
			elseif price == nil then REASONS.Brief
			elseif charged(workOf(now.Data, it)) then nil -- infused: no second voltage to show
			elseif level.TimeLeft <= 0 then "Breaks it now"
			else `Saves {Read.Seconds(saved / speed)}`
		if says then
			local beside = lines(row, `Effect{index}`, says, UDim2.new(0.5, -gap / 2, 0, Theme.Size.Tap), 0)
			beside.Position = UDim2.new(0.5, gap / 2, 0, 0)
			beside.TextYAlignment = Enum.TextYAlignment.Center
		end
	end
end

-- Drop rates: every Voidkin the shard can give under its rarity's total, the commonest first, as the server will roll
-- them. The rows shown add to 100% (Rules.Odds.Rates).
chances = function(column: Instance, def: string, luck: number)
	local list = Instance.new("Frame")
	list.Name = "Chances"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, -Theme.Size.Gap, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.LayoutOrder = 11
	list.Parent = column
	Panel.List(list, nil, 2)
	local order = 0
	local function rate(name: string, who: string, parts: number, indent: number, colour: Color3?, font: Font?)
		order += 1
		local line = Instance.new("Frame")
		line.Name = name
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, LINE + 2)
		line.LayoutOrder = order
		line.Parent = list
		label(line, "Who", who, Theme.Text.Caption, UDim2.new(1, -(64 + indent), 1, 0), UDim2.fromOffset(indent, 0), { Truncate = true, Colour = colour, Font = font })
		label(line, "Chance", Odds.Percent(parts), Theme.Text.Caption, UDim2.new(0, 60, 1, 0), UDim2.new(1, -60, 0, 0), { Font = font, Colour = colour, Align = Enum.TextXAlignment.Right })
	end
	for _, group in Odds.Rates(def, luck) do
		-- A rarity heads its rows in its own colour, heavier than them; their names are the text's ivory.
		rate(`Tier{group.Rarity}`, group.Rarity, group.Parts, 0, HudConfig.Breaker.Tier[group.Rarity] or HudConfig.Card.Trim[group.Rarity], Theme.Font.Number)
		for _, each in group.Rates do
			rate(each.Id, Voidkin.ById[each.Id].Name, each.Parts, RATE_INDENT, Theme.Colour.Text, Theme.Font.Body)
		end
	end
end

local lastView: Profile.View? = nil
local lastOn: On? = nil

local function build(view: Profile.View, on: On)
	lastView, lastOn = view, on
	tickers = {}
	taps = {}
	local now = Read.Base(view, workspace:GetServerTimeNow())
	watch(now)
	selected = settle(view)
	sky.Mist, sky.Lights, sky.Fall = {}, {}, nil
	local body = Screen.Open(NAME, "Void Breaker", SIZE)
	local panel = body.Parent
	if panel and panel:IsA("GuiObject") then
		night(panel)
	end
	local gap = Theme.Size.Gap
	-- The chambers' row as tall as the body leaves over the strip, up to Cell: on a short room (the smallest phone) the
	-- row gives way, never the strip, which ran past the panel's foot there with its chips cut (found at TR41 (d)).
	-- Its height in points from the sizes, never from the screen, which the entrance's scale shrinks for a moment.
	local under = HEADING + 2 + gap + HEADING + 2 + CHIP.Y + 8
	local tall = if panel and panel:IsA("GuiObject") then panel.Size.Y.Offset * body.Size.Y.Scale + body.Size.Y.Offset else 0
	local cellHeight = if tall > 0 then math.min(HudConfig.Breaker.Cell, math.floor(tall - under)) else HudConfig.Breaker.Cell
	local left = Instance.new("Frame")
	left.Name = "Machine"
	left.BackgroundTransparency = 1
	left.Size = UDim2.new(0.6, -gap / 2, 1, 0)
	left.Parent = body
	machine(left, view, cellHeight)
	strip(left, view, HEADING + 2 + cellHeight + gap, on)
	pane(body, selected, view, now, on, UDim2.new(0.4, -gap / 2, 1, 0), UDim2.new(0.6, gap / 2, 0, 0))
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function BreakerScreen.Open(view: Profile.View, on: On)
	if Screen.Current() ~= NAME then -- a fresh open starts on the chambers, never on a choice left from before
		selected, pending = nil, nil
		rates = false
		seen, flashes, arrivals = nil, {}, {} -- what finished while it was shut waits on the strip, unflashed
		opened = os.clock()
		nextFall = opened + between(SKY.Falling.First)
		fallFrom = 0
	end
	build(view, on)
	move() -- laid where it stands before its first frame
	if moving == nil then
		moving = RunService.RenderStepped:Connect(function()
			if Screen.Current() ~= NAME then
				local was = moving
				moving = nil
				sky = { Mist = {}, Lights = {}, Fall = nil, Stars = {} }
				if was then
					was:Disconnect()
				end
				return
			end
			move()
		end)
	end
end

function BreakerScreen.Tick(now: Read.Base)
	if Screen.Current() ~= NAME then
		return
	end
	if watch(now) then -- a shard just finished here, ahead of the save's copy: its chamber flashes now
		rebuild()
		return
	end
	for _, tick in tickers do
		tick(now)
	end
end

function BreakerScreen.Selected(): Selection?
	return selected
end

function BreakerScreen.Select(item: Selection?)
	select(item)
end

-- For tests: a tap on a chamber or a chip, by its tap target, as a player's finger would; false if it has none.
function BreakerScreen.Tap(tap: Instance?): boolean
	local onTap = if tap then taps[tap] else nil
	if onTap == nil then
		return false
	end
	onTap()
	return true
end

function BreakerScreen.Flashing(): { [number]: boolean }
	local out = {}
	for index, started in flashes do
		if flashLeft(started) then
			out[index] = true
		end
	end
	return out
end

function BreakerScreen.Still(on: boolean?)
	still = on
end

function BreakerScreen.Fall(at: number?)
	heldFall = at
	nextFall = os.clock()
end

BreakerScreen.Name = NAME
BreakerScreen.Reasons = REASONS
BreakerScreen.Locked = LOCKED

return BreakerScreen
