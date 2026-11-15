--!strict
-- PowerScreen (client): the Power screen, in grey (TR18; docs/ui.md, "The screens of the first loop", 7; docs/design.md,
-- "Power"). The plant as it stands now, from the server's own rules run on the client's copy (UI.Read): generation
-- against demand; one bar that is the whole generation, split among the machines by its handles, what's left charging
-- the battery; +/- on each share, and Auto; each machine's kW against its rating and its speed; the battery's kWh, its
-- cap and the hours of work it holds. Every change is asked of the server (Rules.Base.SetPower) through the owner's Act,
-- and the screen is rebuilt from the server's copy. A handle drags here and asks once, when it's let go; a change of the
-- save while it's held waits for the let-go. The generator's prompt opens it (BaseController), once a second machine
-- has drawn (Profile's Base.Power.Open). Its look waits on AR12's pick and the machine room's Dynamo.
--   PowerScreen.Open(view, on)    builds it (on: Act); again on each change of the save
--   PowerScreen.Tick(now)         the readings and the bar, from the base as it stands now
--   PowerScreen.Parts()           its pieces by name, for tests
--   PowerScreen.Drag(handle, to)  a handle dragged to `to` of the bar and let go, as a finger would, for tests: the answer
--   PowerScreen.Slide(handle, to, seconds)  the same drag over `seconds`, a frame at a time, for a take: the answer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local HudConfig = require(Shared.Config.Hud)
local Power = require(Shared.Rules.Power)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Row = require(UI.Kit.Row)

local PowerScreen = {}

export type On = { Act: (name: string, args: any?) -> { [string]: any } }

local NAME = "Power"
local SIZE = Vector2.new(600, 380)
local TRACK = 24 -- the bar's height, authored
local HANDLE = Theme.Size.Tap -- a handle: a whole touch target over the bar
local GRIP = Vector2.new(8, 40) -- what a handle shows: an upright, over the bar
local CHIP = 12 -- a row's colour chip, the bar's segment it reads
local NAME_LINE = 24
local STEP = Theme.Size.Tap -- a +/- button, square
local SHARE = 56 -- the share's words between a row's - and +
local AUTO = 96

-- The machines in the bar's order (Rules.Power.Machines), by name, each in a grey colour until AR12's pick; the battery
-- takes what's left, in Power's.
local MACHINES: { { Id: string, Name: string, Colour: Color3 } } = {
	{ Id = "Breaker", Name = "Void Breaker", Colour = Theme.Colour.Primary },
	{ Id = "Training", Name = "Training machine", Colour = Theme.Colour.Heal },
}
local BATTERY = Theme.Colour.Electricity

local lastView: Profile.View? = nil
local lastOn: On? = nil
local parts: { [string]: Instance } = {}
local tickers: { (now: Read.Base) -> () } = {}
local cuts: { number } = { 0, 0 } -- the bar's cuts, 0 to 1: after the Breaker's share, after the Training machine's
local held: { Handle: number, Input: InputObject?, StartX: number, From: number }? = nil
local waiting = false -- a rebuild asked while a handle was held
local sent = false -- a let-go's split asked, the save's copy not back yet: the bar keeps it rather than jump back
local wired = false

local function snap(share: number): number
	local step = HudConfig.Power.Snap
	return math.clamp(math.floor(share / step + 0.5) * step, 0, 1)
end

-- Each machine's share of the whole generation as the plant runs it now: under Auto, what each draws (all of it when
-- they ask more than is made: the battery covers the rest); under a split, the player's shares, scaled back to the whole
-- as the rule does (Rules.Power.Flow).
local function sharesNow(now: Read.Base): { number }
	local setting = now.Data.Base.Power
	local out: { number } = {}
	if setting.Auto then
		local flow = now.Rates.Flow
		local drawn = 0
		for _, machine in MACHINES do
			drawn += flow.Draw[machine.Id] or 0
		end
		local whole = math.max(flow.Generation, drawn)
		for index, machine in MACHINES do
			out[index] = if whole > 0 then (flow.Draw[machine.Id] or 0) / whole else 0
		end
	else
		local routed = 0
		for _, machine in MACHINES do
			routed += math.max(0, setting.Shares[machine.Id] or 0)
		end
		local scale = if routed > 1 then 1 / routed else 1
		for index, machine in MACHINES do
			out[index] = math.max(0, setting.Shares[machine.Id] or 0) * scale
		end
	end
	return out
end

local function cutsOf(shares: { number }): { number }
	local first = math.clamp(shares[1] or 0, 0, 1)
	return { first, math.clamp(first + (shares[2] or 0), first, 1) }
end

-- The split a +/- press asks: one share moved by `by`, never under 0, never past what's left of the whole.
local function stepped(shares: { number }, index: number, by: number): { [string]: number }
	local whole = 0
	for _, share in shares do
		whole += share
	end
	local asked: { [string]: number } = {}
	for at, machine in MACHINES do
		local share = shares[at] or 0
		if at == index then
			share = math.clamp(share + by, 0, share + math.max(0, 1 - whole))
		end
		asked[machine.Id] = snap(share)
	end
	return asked
end

-- The bar's segments and handles at `cuts`.
local function lay()
	local edges = { 0, cuts[1], cuts[2], 1 }
	for index = 1, 3 do
		local segment = parts[`Segment{index}`] :: Frame?
		if segment then
			segment.Position = UDim2.fromScale(edges[index], 0)
			segment.Size = UDim2.fromScale(math.max(0, edges[index + 1] - edges[index]), 1)
		end
	end
	for index = 1, 2 do
		local handle = parts[`Handle{index}`] :: GuiObject?
		if handle then
			handle.Position = UDim2.new(cuts[index], 0, 0.5, 0)
		end
	end
	for index = 1, 3 do
		local share = parts[`Share{index}`] :: TextLabel?
		if share then
			share.Text = `{math.floor((edges[index + 1] - edges[index]) * 100 + 0.5)}%`
		end
	end
end

-- A handle moved to `to` of the bar, kept between its neighbours.
local function move(handle: number, to: number)
	if handle == 1 then
		cuts[1] = math.clamp(to, 0, cuts[2])
	else
		cuts[2] = math.clamp(to, cuts[1], 1)
	end
	lay()
end

local function ask(args: { [string]: any }): { [string]: any }
	local on = lastOn
	if on == nil then
		return { Ok = false, Error = "Closed" }
	end
	return on.Act("SetPower", args)
end

-- The split the bar's cuts say, asked of the server.
local function askCuts(): { [string]: any }
	local first = snap(cuts[1])
	local both = math.max(first, snap(cuts[2]))
	return ask({ Auto = false, Shares = { Breaker = first, Training = both - first } })
end

local build: (view: Profile.View) -> ()

-- The let-go: the split asked once, and a rebuild that waited on the hold.
local function release()
	held = nil
	sent = true -- a rebuild from the save's copy takes it back
	local answer = askCuts()
	if answer.Ok ~= true then
		sent = false
	end
	local view = lastView
	if waiting and view and Screen.Current() == NAME then
		waiting = false
		build(view)
	end
	return answer
end

local function wire()
	if wired then
		return
	end
	wired = true
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local hold = held
		local track = parts.Track :: Frame?
		if hold == nil or track == nil or track.AbsoluteSize.X <= 0 then
			return
		end
		local moving = input.UserInputType == Enum.UserInputType.MouseMovement or (hold.Input ~= nil and input == hold.Input)
		if moving then
			-- By how far the finger went, never where it is: the same in every layer's inset.
			move(hold.Handle, hold.From + (input.Position.X - hold.StartX) / track.AbsoluteSize.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		local hold = held
		if hold and (input == hold.Input or input.UserInputType == Enum.UserInputType.MouseButton1) then
			task.spawn(release)
		end
	end)
end

local function label(parent: Instance, name: string, text: string, size: number, box: UDim2, at: UDim2, extra: { [string]: any }?): TextLabel
	local props: { [string]: any } = { Name = name, Size = size, Box = box, Position = at, Parent = parent }
	for key, value in extra or {} do
		props[key] = value
	end
	local made = Text.new(props :: any)
	made.Text = text
	return made
end

local function chip(parent: Instance, colour: Color3)
	local mark = Instance.new("Frame")
	mark.Name = "Chip"
	mark.BorderSizePixel = 0
	mark.BackgroundColor3 = colour
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Position = UDim2.new(0, 0, 0, NAME_LINE / 2)
	mark.Size = UDim2.fromOffset(CHIP, CHIP)
	mark.Parent = parent
end

-- The head: generation against demand, demand in the warning colour while it's over generation; Auto at its right.
local function head(body: Frame, now: Read.Base)
	local gap = Theme.Size.Gap
	local says = label(body, "Plant", "", Theme.Text.Body, UDim2.new(1, -(AUTO + gap), 0, NAME_LINE), UDim2.fromOffset(0, (STEP - NAME_LINE) / 2), { Font = Theme.Font.Strong })
	local over = label(body, "Over", "", Theme.Text.Caption, UDim2.new(1, -(AUTO + gap), 0, 18), UDim2.fromOffset(0, (STEP + NAME_LINE) / 2), { Colour = Theme.Colour.Over })
	parts.Plant, parts.Over = says, over
	table.insert(tickers, function(at: Read.Base)
		local rates = at.Rates
		says.Text = `Generation {Read.Kw(rates.Generation)} · Demand {Read.Kw(rates.Demand)}`
		local short = rates.Demand > rates.Generation + 1e-9
		over.Text = if not short then ""
			elseif at.Data.Base.Power.Auto and at.Data.Base.Charge > 1e-9 then "The battery covers the rest"
			else "Demand over generation: the machines slow"
		body:SetAttribute("Over", short)
	end)
	local auto = now.Data.Base.Power.Auto
	parts.Auto = Button.new({
		Name = "Auto",
		Text = "Auto",
		Size = UDim2.fromOffset(AUTO, STEP),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Parent = body,
		OnPress = function()
			if auto then
				-- Off: the split starts where Auto had it.
				local shares = sharesNow(now)
				return ask({ Auto = false, Shares = { Breaker = snap(shares[1]), Training = snap(shares[2]) } }).Ok == true
			end
			return ask({ Auto = true }).Ok == true
		end,
	})
	Button.Set(parts.Auto :: TextButton, { Selected = auto })
end

-- The bar: the whole generation, a segment for each machine and the battery's for the rest, a handle at each cut.
local function bar(body: Frame, top: number)
	local rail = Instance.new("Frame")
	rail.Name = "Rail"
	rail.BackgroundTransparency = 1
	rail.Size = UDim2.new(1, -HANDLE, 0, HANDLE)
	rail.Position = UDim2.fromOffset(HANDLE / 2, top)
	rail.Parent = body
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BorderSizePixel = 0
	track.BackgroundColor3 = Theme.Colour.Channel
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.fromScale(0, 0.5)
	track.Size = UDim2.new(1, 0, 0, TRACK)
	track.ClipsDescendants = true
	track.Parent = rail
	parts.Track = track
	local colours = { MACHINES[1].Colour, MACHINES[2].Colour, BATTERY }
	for index, colour in colours do
		local segment = Instance.new("Frame")
		segment.Name = `Segment{index}`
		segment.BorderSizePixel = 0
		segment.BackgroundColor3 = colour
		segment.Parent = track
		parts[`Segment{index}`] = segment
	end
	for index = 1, 2 do
		local handle = Instance.new("TextButton")
		handle.Name = `Handle{index}`
		handle.Text = ""
		handle.AutoButtonColor = false
		handle.BackgroundTransparency = 1
		handle.AnchorPoint = Vector2.new(0.5, 0.5)
		handle.Size = UDim2.fromOffset(HANDLE, HANDLE)
		handle.ZIndex = 3
		handle.Parent = rail
		local grip = Instance.new("Frame")
		grip.Name = "Grip"
		grip.BorderSizePixel = 0
		grip.BackgroundColor3 = Theme.Colour.Text
		grip.AnchorPoint = Vector2.new(0.5, 0.5)
		grip.Position = UDim2.fromScale(0.5, 0.5)
		grip.Size = UDim2.fromOffset(GRIP.X, GRIP.Y)
		grip.ZIndex = 4
		grip.Parent = handle
		handle.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				held = { Handle = index, Input = if kind == Enum.UserInputType.Touch then input else nil, StartX = input.Position.X, From = cuts[index] }
			end
		end)
		parts[`Handle{index}`] = handle
	end
end

-- A machine's row: its chip and name, its kW against its rating and its speed under them, and its share between - and +.
local function machineRow(list: ScrollingFrame, index: number, now: Read.Base)
	local machine = MACHINES[index]
	local gap = Theme.Size.Gap
	local row = Instance.new("Frame")
	row.Name = machine.Id
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -gap, 0, STEP)
	row.LayoutOrder = index
	row.Parent = list
	chip(row, machine.Colour)
	local right = STEP * 2 + SHARE + gap * 2
	label(row, "Name", machine.Name, Theme.Text.Body, UDim2.new(1, -(right + CHIP + gap), 0, NAME_LINE), UDim2.fromOffset(CHIP + gap, 0), { Font = Theme.Font.Strong })
	local reading = label(row, "Reading", "", Theme.Text.Caption, UDim2.new(1, -(right + CHIP + gap), 0, STEP - NAME_LINE), UDim2.fromOffset(CHIP + gap, NAME_LINE), { Colour = Theme.Colour.TextDim })
	parts[`Reading{index}`] = reading
	table.insert(tickers, function(at: Read.Base)
		local flow = at.Rates.Flow
		local rating = flow.Demand[machine.Id] or 0
		reading.Text = if rating > 0
			then `{Read.Against(flow.Draw[machine.Id] or 0, rating)} · {math.floor((flow.Speed[machine.Id] or 1) * 100 + 0.5)}%`
			else "Idle"
	end)
	local shares = sharesNow(now)
	local function step(name: string, by: number, x: number)
		local made = Button.new({
			Name = `{name}{index}`,
			Text = if by > 0 then "+" else "-",
			Size = UDim2.fromOffset(STEP, STEP),
			Position = UDim2.new(1, -x, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
			Parent = row,
			Quiet = true,
			OnPress = function()
				return ask({ Auto = false, Shares = stepped(shares, index, by) }).Ok == true
			end,
		})
		parts[`{name}{index}`] = made
		local whole = 0
		for _, share in shares do
			whole += share
		end
		local stuck = if by > 0 then whole >= 1 - 1e-6 else (shares[index] or 0) <= 1e-6
		if stuck then
			Button.Set(made, { Disabled = made.Text }) -- its own mark stays; the bar says why
		end
	end
	step("Plus", HudConfig.Power.Step, 0)
	parts[`Share{index}`] = label(row, `Share{index}`, "", Theme.Text.Body, UDim2.fromOffset(SHARE, STEP), UDim2.new(1, -(STEP + gap), 0, 0), { Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, 0) })
	step("Minus", -HudConfig.Power.Step, STEP + SHARE + gap * 2)
end

-- The battery's row: its kWh against its cap, the hours of work it holds at today's demand, and its share: the rest.
local function batteryRow(list: ScrollingFrame)
	local gap = Theme.Size.Gap
	local row = Instance.new("Frame")
	row.Name = "Battery"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -gap, 0, STEP)
	row.LayoutOrder = #MACHINES + 1
	row.Parent = list
	chip(row, BATTERY)
	local right = STEP + SHARE + gap
	label(row, "Name", "Battery", Theme.Text.Body, UDim2.new(1, -(right + CHIP + gap), 0, NAME_LINE), UDim2.fromOffset(CHIP + gap, 0), { Font = Theme.Font.Strong })
	local reading = label(row, "Reading", "", Theme.Text.Caption, UDim2.new(1, -(right + CHIP + gap), 0, STEP - NAME_LINE), UDim2.fromOffset(CHIP + gap, NAME_LINE), { Colour = Theme.Colour.TextDim })
	parts.BatteryReading = reading
	parts.Share3 = label(row, "Share3", "", Theme.Text.Body, UDim2.fromOffset(SHARE, STEP), UDim2.new(1, -(STEP + gap), 0, 0), { Font = Theme.Font.Number, Align = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(1, 0) })
	table.insert(tickers, function(at: Read.Base)
		local kwh = at.Data.Base.Charge
		local demand = at.Rates.Demand
		local holds = if demand > 1e-9 then `holds {Read.Hours(kwh / demand)} of work` else "nothing draws now"
		reading.Text = `{Read.Kwh(kwh)} / {Read.Number(BaseConfig.Battery.Capacity)} kWh · {holds}`
	end)
end

build = function(view: Profile.View)
	lastView = view
	if held then
		waiting = true -- the screen under a held handle stays until it's let go
		return
	end
	parts, tickers = {}, {}
	sent = false
	wire()
	local now = Read.Base(view, workspace:GetServerTimeNow())
	local body = Screen.Open(NAME, "Power", SIZE)
	local gap = Theme.Size.Gap
	head(body, now)
	local top = STEP + gap
	bar(body, top)
	top += HANDLE + gap
	local list = Row.List(body, "Machines", UDim2.new(1, 0, 1, -top), UDim2.fromOffset(0, top))
	parts.Machines = list
	for index in MACHINES do
		machineRow(list, index, now)
	end
	batteryRow(list)
	parts.Body = body
	cuts = cutsOf(sharesNow(now))
	lay()
	for _, tick in tickers do
		tick(now)
	end
end

function PowerScreen.Open(view: Profile.View, on: On)
	lastOn = on
	build(view)
end

function PowerScreen.Tick(now: Read.Base)
	if Screen.Current() ~= NAME then
		return
	end
	if held == nil and not sent then
		cuts = cutsOf(sharesNow(now))
		lay()
	end
	for _, tick in tickers do
		tick(now)
	end
end

function PowerScreen.Parts(): { [string]: Instance }
	return parts
end

function PowerScreen.Cuts(): { number }
	return table.clone(cuts)
end

function PowerScreen.Drag(handle: number, to: number): { [string]: any }
	held = { Handle = handle, Input = nil, StartX = 0, From = cuts[handle] }
	move(handle, to)
	return release()
end

function PowerScreen.Slide(handle: number, to: number, seconds: number): { [string]: any }
	local from = cuts[handle]
	held = { Handle = handle, Input = nil, StartX = 0, From = from }
	local start = os.clock()
	while true do
		local share = math.clamp((os.clock() - start) / math.max(seconds, 1e-3), 0, 1)
		move(handle, from + (to - from) * share)
		if share >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	return release()
end

PowerScreen.Name = NAME
PowerScreen.Machines = MACHINES
assert(#MACHINES == #Power.Machines, "PowerScreen: one row for each of Rules.Power's machines")

return PowerScreen
