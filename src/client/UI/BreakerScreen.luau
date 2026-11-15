--!strict
-- BreakerScreen (client): the Void Breaker's screen, in grey (TR9; docs/ui.md, "The screens of the first loop", 3). The
-- chambers as they stand, each shard with its crack's progress and its time left; what's ready, what waits and what's in
-- the bag; one tap on a shard shows its odds (Rules.Odds, never copied) and infusion as a clear choice, its Electricity
-- price and what it does to the rarest tier (docs/design.md, "Infusion"; Rules.Base.Infuse). Machine, the director's
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local HudConfig = require(Shared.Config.Hud)
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Breaker = require(Shared.Rules.Breaker)
local Odds = require(Shared.Rules.Odds)
local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Row = require(UI.Kit.Row)
local Bar = require(UI.Kit.Bar)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Skin = require(UI.Kit.Skin)

local BreakerScreen = {}

export type Selection = { Kind: string, Index: number, Def: string } -- Kind: "Chamber", "Line", "Ready" or "Bag"
export type On = { Act: (name: string, args: any) -> { [string]: any }, Open: (index: number) -> () }

local NAME = "Breaker"
local SIZE = Vector2.new(660, 320)
local CHIP = Vector2.new(112, 52)
local HEADING = 20
local LINE = 18
local LOCKED = "Upgrade the Breaker" -- under "Locked": what opens a chamber (research, TR9, 2026-11-14, night)

local selected: Selection? = nil
local pending: Selection? = nil -- a shard just put in, chosen where the server says it stands once the save shows it
local pendingUntil = 0
local PENDING = 3 -- seconds a shard put in waits to be chosen
local tickers: { (now: Read.Base) -> () } = {}
local rebuild: () -> () = function() end

-- A shard finishing: the base as last seen, advanced to then, so the next look can tell which chamber handed one over.
type Ended = { Index: number, Left: number } -- a chamber whose shard ended, and how near done it was
type Seen = { Ready: number, Chambers: { [number]: { Def: string, Done: number, Left: number } } }
local seen: Seen? = nil
local flashes: { [number]: number } = {} -- chamber index: os.clock() its flash began
local arrivals: { [number]: number } = {} -- Ready index: os.clock() its shard came from a chamber

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

-- A chance as a player reads it: never "0.00%" for one that can happen.
local function percent(chance: number): string
	local p = chance * 100
	if chance > 0 and p < 0.01 then
		return "<0.01%"
	end
	return if p < 1 then string.format("%.2f%%", p) else string.format("%.1f%%", p)
end

-- The infusion levels by name, Config.Shards.Infusion's order (the director, 2026-11-15: "real electrician words").
local LEVELS = { "Low voltage", "High voltage" }

-- The level a shard was infused at, by name, or nil.
local function levelOf(luck: number): string?
	for index, level in ShardConfig.Infusion do
		if math.abs(level.Lift - luck) < 1e-6 and LEVELS[index] then
			return LEVELS[index]
		end
	end
	return nil
end

-- A shard's infusion by the level put in ("Infused · Low voltage"), never its luck as a number, which reads as a chance.
local function infused(luck: number): string
	local level = levelOf(luck)
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
	local level = if work and work.Luck > 0 then levelOf(work.Luck) else nil
	local luck = if level then ` · infused, {string.lower(level)}` elseif work and work.Luck > 0 then " · infused" else ""
	if item.Kind == "Chamber" then
		return if work then `Chamber {item.Index} · {Read.Seconds(Read.Left(now, work))} left{luck}` else `Chamber {item.Index}`
	elseif item.Kind == "Line" then
		return `Waiting, {ordinal(item.Index)}{luck}`
	elseif item.Kind == "Ready" then
		return `Ready to open{luck}`
	end
	return `In the bag · {view.Bag.Shards[item.Def] or 0}`
end

-- The rarest tier's share of a shard's odds at `luck`, and its name.
local function rarest(def: string, luck: number): (string, number)
	local entries = Odds.Table(def, luck)
	local last = entries[#entries]
	if last == nil then
		return "", 0
	end
	local tier = Voidkin.ById[last.Id].Rarity
	local share = 0
	for _, entry in entries do
		if Voidkin.ById[entry.Id].Rarity == tier then
			share += entry.Chance
		end
	end
	return tier, share
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

-- A tap target over a whole frame: the cell or chip is the button, its look the panel under it.
local taps: { [Instance]: () -> () } = {} -- for tests: what a tap does; emptied at each build
local function tapOver(frame: GuiObject, name: string, onTap: () -> ())
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
	local word = label(over, "Ready", "Ready", Theme.Text.Title, UDim2.new(1, 0, 0, 26), UDim2.fromScale(0, 0.5), { Font = Theme.Font.Number, Colour = Theme.Colour.Backing, Align = Enum.TextXAlignment.Center })
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
local function cell(parent: Instance, index: number, view: Profile.View, width: UDim, height: number)
	local open = index <= #view.Base.Chambers
	local chamber = if open then view.Base.Chambers[index] else nil
	local work = if chamber then chamber.Work else nil
	local item: Selection? = if work then { Kind = "Chamber", Index = index, Def = work.Def } else nil
	local frame = Panel.new({
		Name = `Chamber{index}`,
		Size = UDim2.new(width, UDim.new(0, height)),
		Colour = Theme.Colour.PlateHigh,
		Transparency = if open then 0.3 else 0.7,
		Edge = true,
		LayoutOrder = index,
		Parent = parent,
	})
	local pad = Theme.Size.Pad
	local inner = UDim2.new(1, -pad * 2, 0, 22)
	label(frame, "Number", `Chamber {index}`, Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, pad), { Colour = Theme.Colour.TextDim })
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
	if work == nil then
		later(label(frame, "Name", if open then "Empty" else "Locked", Theme.Text.Body, inner, UDim2.fromOffset(pad, pad + LINE + 4), { Colour = Theme.Colour.Disabled }))
		if not open then
			-- What opens it, by research's rule for the locked infusion: the Breaker's own level (TR9, fix 2). The level
			-- joins the words once the Breaker's upgrades are seeded. "Locked · upgrade the Breaker" over two lines.
			label(frame, "Opens", LOCKED, Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE * 3), UDim2.fromOffset(pad, pad + LINE + 28), { Colour = Theme.Colour.TextDim, Wrap = true })
		end
		return
	end
	local w = work :: Profile.ShardWork
	later(label(frame, "Name", shortName(w.Def), Theme.Text.Body, inner, UDim2.fromOffset(pad, pad + LINE + 2), { Font = Theme.Font.Strong, Truncate = true }))
	local bar = Bar.new({ Name = "Crack", Size = UDim2.new(1, -pad * 2, 0, Theme.Size.Bar), Position = UDim2.fromOffset(pad, pad + LINE + 30), Colour = Theme.Colour.Electricity, Parent = frame })
	later(bar)
	local left = label(frame, "Left", "", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, pad + LINE + 42), { Colour = Theme.Colour.TextDim })
	later(left)
	if w.Luck > 0 then
		-- two lines' room: a narrow chamber wraps the level under the word
		later(label(frame, "Infused", infused(w.Luck), Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE * 2), UDim2.fromOffset(pad, pad + LINE + 60), { Colour = Theme.Colour.Electricity, Wrap = true }))
	end
	table.insert(tickers, function(now: Read.Base)
		local current = now.Data.Base.Chambers[index]
		local at = if current then current.Work else nil
		if at and left.Parent then
			local total = Breaker.Cost(at.Def) or 1
			Bar.Set(bar, math.clamp(at.Done / math.max(total, 1e-3), 0, 1))
			left.Text = `{Read.Seconds(Read.Left(now, at))} left`
		end
	end)
	Panel.Lit(frame, same(item, selected))
	tapOver(frame, "Tap", function()
		select(item)
	end)
end

-- A ready shard's chip, the loudest thing on the screen (TR9, fix (a)): a gold edge, bold, over a gold fill that breathes,
-- and, as it arrives from a chamber, a pop. "Ready" is its first word.
local function glow(frame: GuiObject, item: Selection)
	Panel.Trim(frame, Theme.Colour.Ready)
	local folder = frame:FindFirstChild("NL_Skin")
	local edge = if folder then folder:FindFirstChild("Edge", true) :: ImageLabel? else nil
	if edge then
		Skin.Set(edge, "PanelEdgeBold", {})
		edge.ImageTransparency = 0
	end
	local tune = HudConfig.Breaker.Glow
	local fill = Skin.Lay(Skin.Of(frame), "PanelFill", { Name = "Glow", Tint = Theme.Colour.Ready, Alpha = tune.Low, Z = 3 })
	local function breathe()
		local period = TweenInfo.new(math.max(tune.Period, 0.05), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(fill, period, { ImageTransparency = 1 - tune.High }):Play()
	end
	local came = arrivals[item.Index]
	if came and flashLeft(came) then
		-- Just handed over by a chamber: it lands lit as the chamber's flash, and settles into its breath.
		arrivals[item.Index] = nil -- once: a rebuild shows it as it stands
		fill.ImageTransparency = 0.1
		local settle = TweenService:Create(fill, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 - tune.Low })
		settle.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and fill.Parent then
				breathe()
			end
		end)
		settle:Play()
	else
		breathe()
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
	local ready = item.Kind == "Ready"
	local work = workOf(view, item)
	local infusedMark = if work and work.Luck > 0 then " · infused" else ""
	local top = if ready then "Ready" else shortName(item.Def)
	local under = if ready then `{shortName(item.Def)}{infusedMark}`
		elseif item.Kind == "Line" then `Waiting, {ordinal(item.Index)}{infusedMark}`
		else `In the bag · {view.Bag.Shards[item.Def] or 0}`
	local name = label(frame, "Name", top, if ready then Theme.Text.Body else Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, 6), { Font = if ready then Theme.Font.Number else Theme.Font.Strong, Colour = if ready then Theme.Colour.Ready else nil, Truncate = true })
	name.ZIndex = 2
	local detail = label(frame, "Detail", under, Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, 6 + LINE + 2), { Colour = if ready then Theme.Colour.Text else Theme.Colour.TextDim, Truncate = true })
	detail.ZIndex = 2
	if ready then
		glow(frame, item)
		tapOver(frame, "Tap", function()
			on.Open(item.Index)
		end)
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
	local row = Instance.new("Frame")
	row.Name = "Chambers"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, height)
	row.Position = UDim2.fromOffset(0, HEADING + 2)
	row.Parent = parent
	Panel.List(row, Enum.FillDirection.Horizontal, Theme.Size.Gap)
	local most = math.max(BaseConfig.Breaker.MostChambers, #view.Base.Chambers)
	for index = 1, most do
		cell(row, index, view, UDim.new(1 / most, -Theme.Size.Gap * (most - 1) / most), height)
	end
end

-- What's ready, waiting and in the bag, a strip of chips that scrolls sideways, at `y`.
local function strip(parent: Instance, view: Profile.View, y: number, on: On)
	label(parent, "StripTitle", "Ready, waiting and in the bag", Theme.Text.Caption, UDim2.new(1, 0, 0, HEADING), UDim2.fromOffset(0, y), { Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim })
	local list = Instance.new("ScrollingFrame")
	list.Name = "Strip"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.new(1, 0, 0, CHIP.Y + 8)
	list.Position = UDim2.fromOffset(0, y + HEADING + 2)
	list.ScrollingDirection = Enum.ScrollingDirection.X
	list.ScrollBarThickness = 4
	list.AutomaticCanvasSize = Enum.AutomaticSize.X
	list.CanvasSize = UDim2.new()
	list.Parent = parent
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
	Holds = "It holds one Voidkin: no odds to lift",
	OneTier = "One tier only: no odds to lift",
	Bag = "Put it in first, then infuse it",
	Ready = "Already broken: open it",
	Infused = "%s: once a shard",
	Short = "Needs %s Electricity",
	Battery = "Needs a battery of %s: upgrade the base", -- research's words, TR9, 2026-11-14
}

-- Why the chosen shard takes no infusion at all, or nil.
local function blockShard(item: Selection, now: Read.Base): string?
	local row = Shards.ById[item.Def]
	if row and row.Holds ~= "" then
		return REASONS.Holds
	elseif Odds.Lifted(item.Def) == 0 then
		return REASONS.OneTier
	elseif item.Kind == "Bag" then
		return REASONS.Bag
	elseif item.Kind == "Ready" then
		return REASONS.Ready
	end
	local work = workOf(now.Data, item)
	if work and work.Luck > 0 then
		return string.format(REASONS.Infused, infused(work.Luck))
	end
	return nil
end

-- Why one level can't be paid now, or nil: a battery too small to hold its price, or too little stored in it.
local function blockLevel(now: Read.Base, level: { Lift: number, Energy: number }): string?
	if level.Energy > BaseConfig.Battery.Capacity then
		return string.format(REASONS.Battery, Read.Number(level.Energy))
	elseif now.Data.Base.Battery < level.Energy then
		return string.format(REASONS.Short, Read.Number(level.Energy))
	end
	return nil
end

-- A line that wraps and grows to its words, in a column.
local function lines(parent: Instance, name: string, text: string, box: UDim2, order: number, colour: Color3?): TextLabel
	local made = label(parent, name, text, Theme.Text.Caption, box, UDim2.new(), { Colour = colour or Theme.Colour.TextDim })
	made.TextWrapped = true
	made.AutomaticSize = Enum.AutomaticSize.Y
	made.LayoutOrder = order
	return made
end

-- The chosen shard: its name and place over one column that scrolls: the one thing to do with it, infusion, and its
-- odds, every chance as the server rolls it.
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
	if action then
		local button = Button.new({ Name = "Action", Text = action, Primary = primary, Size = UDim2.new(1, -gap, 0, Theme.Size.Tap), Parent = column, OnPress = press :: () -> ...any })
		button.LayoutOrder = 1
	end
	-- Infusion: why none goes in, if so; then its two levels, each with its price and, beside it, what it does to
	-- the rarest tier, or why that level can't be paid.
	local whole = blockShard(it, now)
	if whole then
		lines(column, "Why", whole, UDim2.new(1, -gap, 0, LINE), 2, Theme.Colour.Text)
	end
	local work = workOf(now.Data, it)
	local luck = if work then work.Luck else 0
	local tier, before = rarest(it.Def, luck)
	local lifts = tier ~= "" and Odds.Lifted(it.Def) > 0
	for index, level in ShardConfig.Infusion do
		local row = Instance.new("Frame")
		row.Name = `Level{index}`
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -gap, 0, Theme.Size.Tap)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = 2 + index
		row.Parent = column
		-- Its name over its price, two lines: "High voltage" and a price don't fit one line of a phone's button.
		local text = `{LEVELS[index] or `Level {index}`}\n{Read.Number(level.Energy)}`
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
		local short = blockLevel(now, level)
		if whole or short then
			Button.Set(button, { Disabled = text }) -- veiled with its price still on it; the reason is the line beside it
		end
		local _, after = rarest(it.Def, math.min(ShardConfig.LuckCap, luck + level.Lift))
		local says = if not lifts then "No odds to lift"
			elseif whole == nil and short then short
			elseif luck > 0 then nil -- infused: no second lift to show
			else `{tier} {percent(before)} → {percent(after)}`
		if says then
			local beside = lines(row, `Effect{index}`, says, UDim2.new(0.5, -gap / 2, 0, Theme.Size.Tap), 0)
			beside.Position = UDim2.new(0.5, gap / 2, 0, 0)
			beside.TextYAlignment = Enum.TextYAlignment.Center
		end
	end
	-- The odds, rarest first: who it can hold and the chance of each, as the server will roll them.
	lines(column, "ChancesTitle", "Who it can hold", UDim2.new(1, -gap, 0, LINE), 10).FontFace = Theme.Font.Strong
	local list = Instance.new("Frame")
	list.Name = "Chances"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, -gap, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.LayoutOrder = 11
	list.Parent = column
	Panel.List(list, nil, 2)
	local entries = Odds.Table(it.Def, luck)
	for index = #entries, 1, -1 do
		local entry = entries[index]
		local row = Voidkin.ById[entry.Id]
		local line = Instance.new("Frame")
		line.Name = entry.Id
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, LINE + 2)
		line.LayoutOrder = #entries - index + 1
		line.Parent = list
		label(line, "Who", `{row.Name} · {row.Rarity}`, Theme.Text.Caption, UDim2.new(1, -64, 1, 0), UDim2.new(), { Truncate = true })
		label(line, "Chance", percent(entry.Chance), Theme.Text.Caption, UDim2.new(0, 60, 1, 0), UDim2.new(1, -60, 0, 0), { Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right })
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
	local body = Screen.Open(NAME, "Void Breaker", SIZE)
	local gap = Theme.Size.Gap
	local cellHeight = HudConfig.Breaker.Cell
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
		seen, flashes, arrivals = nil, {}, {} -- what finished while it was shut waits on the strip, unflashed
	end
	build(view, on)
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

BreakerScreen.Name = NAME
BreakerScreen.Reasons = REASONS
BreakerScreen.Locked = LOCKED

return BreakerScreen
