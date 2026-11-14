--!strict
-- BreakerScreen (client): the Void Breaker's screen, in grey (TR9; docs/ui.md, "The screens of the first loop", 3). The
-- chambers as they stand, each shard with its crack's progress and its time left; what's ready, what waits and what's in
-- the bag; one tap on a shard shows its odds (Rules.Odds, never copied) and infusion as a clear choice, its Electricity
-- price and what it does to the rarest tier (docs/design.md, "Infusion"; Rules.Base.Infuse). Three layouts for the
-- blockout's verdict (Config.Hud.Breaker.Layout, live): Machine, List and Sheet. Every change is asked of the server
-- through the owner's Act, and the screen is rebuilt from the server's copy.
--   BreakerScreen.Open(view, on)    builds it (on: Act, Open a ready shard); again on each change of the save
--   BreakerScreen.Tick(now)         the countdowns and the bars, from the base as it stands now; a tuned layout rebuilds
--   BreakerScreen.Selected()        the chosen shard, for tests
--   BreakerScreen.Select(selection) a tap on a shard, for tests

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local BreakerScreen = {}

export type Selection = { Kind: string, Index: number, Def: string } -- Kind: "Chamber", "Line", "Ready" or "Bag"
export type On = { Act: (name: string, args: any) -> { [string]: any }, Open: (index: number) -> () }

local NAME = "Breaker"
local SIZE = Vector2.new(660, 320)
local CHIP = Vector2.new(112, 52)
local HEADING = 20
local LINE = 18

local selected: Selection? = nil
local pending: Selection? = nil -- a shard just put in, chosen where the server says it stands once the save shows it
local pendingUntil = 0
local PENDING = 3 -- seconds a shard put in waits to be chosen
local sheetOpen = false
local built: string? = nil -- the layout last built
local tickers: { (now: Read.Base) -> () } = {}
local rebuild: () -> () = function() end

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

-- The infusion levels by name, Config.Shards.Infusion's order.
local LEVELS = { "A little", "A lot" }

-- A shard's infusion by the level put in ("Infused, a little"), never its luck as a number, which reads as a chance.
local function infused(luck: number): string
	for index, level in ShardConfig.Infusion do
		if math.abs(level.Lift - luck) < 1e-6 and LEVELS[index] then
			return `Infused, {string.lower(LEVELS[index])}`
		end
	end
	return "Infused"
end

local function ordinal(n: number): string
	local last = n % 10
	local suffix = if n % 100 >= 11 and n % 100 <= 13 then "th" elseif last == 1 then "st" elseif last == 2 then "nd" elseif last == 3 then "rd" else "th"
	return `{n}{suffix}`
end

-- Where a shard stands, in a line: "Chamber 1 · 12 s left", "Waiting, 2nd", "In the bag · 3", "Ready to open".
local function placeOf(item: Selection, now: Read.Base, view: Profile.View): string
	local work = workOf(now.Data, item)
	local luck = if work and work.Luck > 0 then ` · {string.lower(infused(work.Luck))}` else ""
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
	sheetOpen = item ~= nil
	rebuild()
end

-- A tap target over a whole frame: the cell or chip is the button, its look the panel under it.
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
		Parent = parent,
	})
	made.Text = text
	return made
end

-- A chamber as it stands: its shard's name, the crack's progress as a conduit filling, the time left; empty or locked.
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
	if work == nil then
		label(frame, "Name", if open then "Empty" else "Locked", Theme.Text.Body, inner, UDim2.fromOffset(pad, pad + LINE + 4), { Colour = Theme.Colour.Disabled })
		return
	end
	local w = work :: Profile.ShardWork
	label(frame, "Name", shortName(w.Def), Theme.Text.Body, inner, UDim2.fromOffset(pad, pad + LINE + 2), { Font = Theme.Font.Strong, Truncate = true })
	local bar = Bar.new({ Name = "Crack", Size = UDim2.new(1, -pad * 2, 0, Theme.Size.Bar), Position = UDim2.fromOffset(pad, pad + LINE + 30), Colour = Theme.Colour.Electricity, Parent = frame })
	local left = label(frame, "Left", "", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, pad + LINE + 42), { Colour = Theme.Colour.TextDim })
	if w.Luck > 0 then
		label(frame, "Infused", infused(w.Luck), Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, pad + LINE + 60), { Colour = Theme.Colour.Electricity })
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

-- A shard that's ready, waiting or in the bag, as a chip on the strip.
local function chip(parent: Instance, item: Selection, view: Profile.View, order: number)
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
	local colour = if item.Kind == "Ready" then Theme.Colour.Ready else nil
	label(frame, "Name", shortName(item.Def), Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, 6), { Font = Theme.Font.Strong, Colour = colour, Truncate = true })
	local work = workOf(view, item)
	local under = if item.Kind == "Ready" then "Ready"
		elseif item.Kind == "Line" then `Waiting, {ordinal(item.Index)}`
		else `In the bag · {view.Bag.Shards[item.Def] or 0}`
	if work and work.Luck > 0 then
		under ..= " · infused"
	end
	label(frame, "Detail", under, Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE), UDim2.fromOffset(pad, 6 + LINE + 2), { Colour = colour or Theme.Colour.TextDim, Truncate = true })
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
local function strip(parent: Instance, view: Profile.View, y: number)
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
			chip(list, item, view, order)
		end
	end
	if order == 0 then
		label(list, "Nothing", "Nothing waits. Shards drop on Lantern Row.", Theme.Text.Caption, UDim2.fromOffset(300, CHIP.Y), UDim2.new(), { Colour = Theme.Colour.TextDim })
	end
end

-- Why infusion at `level` can't go into the chosen shard now, or nil.
local function infuseBlock(item: Selection, now: Read.Base, level: { Lift: number, Energy: number }): string?
	if Shards.ById[item.Def] and Shards.ById[item.Def].Holds ~= "" then
		return "Holds one Voidkin"
	elseif Odds.Lifted(item.Def) == 0 then
		return "One tier only"
	elseif item.Kind == "Bag" then
		return "Put it in first"
	elseif item.Kind == "Ready" then
		return "Already broken"
	end
	local work = workOf(now.Data, item)
	if work and work.Luck > 0 then
		return "Infused"
	elseif level.Energy > BaseConfig.Battery.Capacity then
		return "More than the battery holds"
	elseif now.Data.Base.Battery < level.Energy then
		return `Needs {Read.Number(level.Energy)}`
	end
	return nil
end

-- The chosen shard: its name and place, the one thing to do with it, its odds, and infusion.
local function pane(parent: Instance, item: Selection?, view: Profile.View, now: Read.Base, on: On, box: UDim2, position: UDim2, back: boolean)
	local frame = Panel.new({ Name = "Odds", Size = box, Position = position, Parent = parent })
	frame.ZIndex = 10
	frame.Active = true -- a tap on the pane stays on it, never reaching a chamber under the sheet
	local pad = Theme.Size.Pad
	if item == nil then
		label(frame, "Empty", "No shard yet. They drop on Lantern Row.", Theme.Text.Caption, UDim2.new(1, -pad * 2, 0, LINE * 2), UDim2.fromOffset(pad, pad), { Colour = Theme.Colour.TextDim })
		return
	end
	local it = item :: Selection
	local right = if back then 96 + pad else 0
	label(frame, "Title", fullName(it.Def), Theme.Text.Body, UDim2.new(1, -pad * 2 - right, 0, 22), UDim2.fromOffset(pad, pad), { Font = Theme.Font.Strong, Truncate = true })
	local place = label(frame, "Place", placeOf(it, now, view), Theme.Text.Caption, UDim2.new(1, -pad * 2 - right, 0, LINE), UDim2.fromOffset(pad, pad + 22), { Colour = Theme.Colour.TextDim, Truncate = true })
	table.insert(tickers, function(current: Read.Base)
		if place.Parent then
			place.Text = placeOf(it, current, view)
		end
	end)
	if back then
		Button.new({ Name = "Back", Text = "Back", Size = UDim2.fromOffset(96, Theme.Size.Tap), Position = UDim2.new(1, -pad, 0, pad), AnchorPoint = Vector2.new(1, 0), Parent = frame, OnPress = function()
			sheetOpen = false
			rebuild()
		end })
	end
	-- The one thing to do with it.
	local y = pad + 22 + LINE + Theme.Size.Gap
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
				sheetOpen = true
				rebuild() -- when the save's copy came before the answer
			end
			return answer.Ok == true
		end
	end
	if action then
		Button.new({ Name = "Action", Text = action, Primary = primary, Size = UDim2.new(1, -pad * 2, 0, Theme.Size.Tap), Position = UDim2.fromOffset(pad, y), Parent = frame, OnPress = press :: () -> ...any })
		y += Theme.Size.Tap + Theme.Size.Gap
	end
	-- Infusion, at the foot: a little or a lot, each with its price and what it does to the rarest tier.
	local levels = ShardConfig.Infusion
	local foot = Theme.Size.Tap + LINE + pad
	local tier, before = rarest(it.Def, 0)
	local work = workOf(now.Data, it)
	local luck = if work then work.Luck else 0
	for index, level in levels do
		local share = UDim2.new(1 / #levels, -(pad * (#levels + 1)) / #levels, 0, Theme.Size.Tap)
		local x = UDim2.new((index - 1) / #levels, pad + (index - 1) * (pad - (pad * (#levels + 1)) / #levels), 1, -foot)
		local button = Button.new({
			Name = `Infuse{index}`,
			Text = `{LEVELS[index] or `Level {index}`} · {Read.Number(level.Energy)}`,
			Size = share,
			Position = x,
			Parent = frame,
			OnPress = function()
				local args: { [string]: any } = { Def = it.Def, Level = index }
				args[it.Kind] = it.Index
				return on.Act("Infuse", args).Ok == true
			end,
		})
		local why = infuseBlock(it, now, level)
		if why then
			Button.Set(button, { Disabled = why })
		end
		local _, after = rarest(it.Def, math.min(ShardConfig.LuckCap, luck + level.Lift))
		local effect = if tier ~= "" and Odds.Lifted(it.Def) > 0 then `{tier} {percent(before)} → {percent(after)}` else "No odds to lift"
		label(frame, `Effect{index}`, effect, Theme.Text.Caption, UDim2.new(share.X, UDim.new(0, LINE)), UDim2.new(x.X, UDim.new(1, -LINE - pad / 2)), { Colour = Theme.Colour.TextDim, Truncate = true })
	end
	-- The odds between, rarest first: who it can hold and the chance of each, as the server will roll them.
	local list = Row.List(frame, "Chances", UDim2.new(1, -pad * 2, 1, -(y + foot + Theme.Size.Gap)), UDim2.fromOffset(pad, y))
	local entries = Odds.Table(it.Def, luck)
	for index = #entries, 1, -1 do
		local entry = entries[index]
		local row = Voidkin.ById[entry.Id]
		local line = Instance.new("Frame")
		line.Name = entry.Id
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, -6, 0, LINE + 2)
		line.LayoutOrder = #entries - index + 1
		line.Parent = list
		label(line, "Who", `{row.Name} · {row.Rarity}`, Theme.Text.Caption, UDim2.new(1, -64, 1, 0), UDim2.new(), { Truncate = true })
		label(line, "Chance", percent(entry.Chance), Theme.Text.Caption, UDim2.new(0, 60, 1, 0), UDim2.new(1, -60, 0, 0), { Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right })
	end
end

-- One list of every shard beside its odds: each row's button chooses it.
local function listOf(parent: Instance, view: Profile.View, now: Read.Base, box: UDim2)
	local list = Row.List(parent, "Shards", box)
	for order, item in shardsOf(view) do
		local work = workOf(now.Data, item)
		local made = Row.new({
			Name = `{item.Kind}{item.Index}`,
			Order = order,
			Text = fullName(item.Def),
			Detail = placeOf(item, now, view),
			Colour = if item.Kind == "Ready" then Theme.Colour.Ready else nil,
			Action = "Odds",
			ActionWidth = 80,
			Parent = list,
			OnPress = function()
				select(item)
			end,
		})
		local detail = made:FindFirstChild("Detail") :: TextLabel?
		if detail and work and item.Kind == "Chamber" then
			table.insert(tickers, function(current: Read.Base)
				if detail.Parent then
					detail.Text = placeOf(item, current, view)
				end
			end)
		end
		local button = made:FindFirstChild("Action")
		if button and button:IsA("TextButton") then
			Button.Set(button, { Selected = same(item, selected) })
		end
	end
end

local lastView: Profile.View? = nil
local lastOn: On? = nil

local function build(view: Profile.View, on: On)
	lastView, lastOn = view, on
	tickers = {}
	local now = Read.Base(view, workspace:GetServerTimeNow())
	selected = settle(view)
	local layout = HudConfig.Breaker.Layout
	built = layout
	local body = Screen.Open(NAME, "Void Breaker", SIZE)
	local gap = Theme.Size.Gap
	local cellHeight = HudConfig.Breaker.Cell
	if layout == "List" then
		listOf(body, view, now, UDim2.new(0.55, -gap / 2, 1, 0))
		pane(body, selected, view, now, on, UDim2.new(0.45, -gap / 2, 1, 0), UDim2.new(0.55, gap / 2, 0, 0), false)
	elseif layout == "Sheet" then
		machine(body, view, cellHeight)
		strip(body, view, HEADING + 2 + cellHeight + gap)
		if sheetOpen and selected then
			pane(body, selected, view, now, on, UDim2.new(0.55, 0, 1, 0), UDim2.new(0.45, 0, 0, 0), true)
		end
	else
		local left = Instance.new("Frame")
		left.Name = "Machine"
		left.BackgroundTransparency = 1
		left.Size = UDim2.new(0.6, -gap / 2, 1, 0)
		left.Parent = body
		machine(left, view, cellHeight)
		strip(left, view, HEADING + 2 + cellHeight + gap)
		pane(body, selected, view, now, on, UDim2.new(0.4, -gap / 2, 1, 0), UDim2.new(0.6, gap / 2, 0, 0), false)
	end
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function BreakerScreen.Open(view: Profile.View, on: On)
	if Screen.Current() ~= NAME then -- a fresh open starts on the chambers, never on a choice left from before
		selected, pending, sheetOpen = nil, nil, false
	end
	build(view, on)
end

function BreakerScreen.Tick(now: Read.Base)
	if Screen.Current() ~= NAME then
		return
	end
	if built ~= HudConfig.Breaker.Layout then
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

BreakerScreen.Name = NAME

return BreakerScreen
