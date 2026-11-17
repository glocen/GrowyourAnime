--!strict
-- PowerScreen (client): the Power screen, in grey (TR18; docs/ui.md, "The screens of the first loop", 7; docs/design.md,
-- "Power"). The plant as it stands now, from the server's own rules run on the client's copy (UI.Read): generation
-- against demand; one bar that is the whole generation, split among the machines by its handles, what's left charging
-- the battery; +/- on each share, and Auto; each machine's kW against its rating and its speed; and the battery on a
-- plate in the head, the screen's one store above the fold: its kWh against its cap, the work it holds, its charge as a
-- bar (AR12's tier 2, research's ruling, 2026-11-15). Every change is asked of the server (Rules.Base.SetPower) through the owner's Act,
-- and the screen is rebuilt from the server's copy. A handle drags here and asks once, when it's let go; a change of the
-- save while it's held waits for the let-go. The generator's prompt opens it (BaseController), once a second machine
-- has drawn (Profile's Base.Power.Open). Its bar is Modulo's, cut in Eclipse (Hud.Power; TR41 (b)): the ember and the
-- well behind it, the bed, each light's glow, the lights seen through their segments' windows, the outline, the ticks, and
-- the brass handles over all.
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
local HudConfig = require(Shared.Config.Hud)
local Power = require(Shared.Rules.Power)

local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Row = require(UI.Kit.Row)
local Panel = require(UI.Kit.Panel)
local Bar = require(UI.Kit.Bar)
local Skin = require(UI.Kit.Skin)

local PowerScreen = {}

export type On = { Act: (name: string, args: any?) -> { [string]: any } }

local NAME = "Power"
local SIZE = Vector2.new(600, 380)
local POWER = HudConfig.Power
local LOOK = POWER.Bar
local TRACK = LOOK.Height -- the bar's height, authored
local RIM = LOOK.Rim -- the lights stand this far inside the bar's ends
local HANDLE = Theme.Size.Tap -- a handle: a whole touch target over the bar
local CHIP = LOOK.Chip -- a row's chip, the bar's light it reads
local NAME_LINE = 24
local STEP = Theme.Size.Tap -- a +/- button, square
local SHARE = 56 -- the share's words between a row's - and +
local AUTO = 96
local PLATE = Vector2.new(400, Theme.Size.Tap - Theme.Size.Pad) -- the battery's plate in the head, authored
local LINE = 20 -- the plate's reading line, authored high
local CHARGE = 8 -- the plate's charge bar, authored high
local MARK = Vector2.new(20, 12) -- the battery's mark, drawn from frames: a stand-in until AR12's mark is cut

-- The machines in the bar's order (Rules.Power.Machines), by name, each with its light's colour and its chip; the
-- battery takes what's left, in its own light.
local MACHINES: { { Id: string, Name: string, Colour: Color3, Chip: string } } = {
	{ Id = "Breaker", Name = "Void Breaker", Colour = POWER.Colours.Breaker, Chip = "ChipBreaker" },
	{ Id = "Training", Name = "Training machine", Colour = POWER.Colours.Training, Chip = "ChipTraining" },
}
local BATTERY = Theme.Colour.Electricity -- the plate's words and charge
local REST = "Battery" -- the light of the bar's rest, and of an idle machine's share

local lastView: Profile.View? = nil
local lastOn: On? = nil
local parts: { [string]: Instance } = {}
local tickers: { (now: Read.Base) -> () } = {}
local cuts: { number } = { 0, 0 } -- the bar's cuts, 0 to 1: after the Breaker's share, after the Training machine's
-- A held handle: Keep, the Training machine's share as the hold began; Pick, the two handles on one spot, so the first
-- move says which is held.
local held: { Handle: number, Input: InputObject?, StartX: number, From: number, Keep: number, Pick: boolean }? = nil
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

-- The bar's width in points, whatever the layer's scale: its height is TRACK points. 0 before it's first laid out.
local function barWidth(): number
	local track = parts.Track :: Frame?
	local size = if track then track.AbsoluteSize else Vector2.zero
	return if size.Y > 0 then size.X * TRACK / size.Y else 0
end

-- A cut at share `at` of the bar, `offset` points past it, as a share of the bar's `wide` points: Rim inside its left at
-- 0, Rim inside its right at 1. In shares, since a UDim's offset is a whole number (1.8 points lands at 1). Before the bar
-- is laid out (`wide` 0) it's the plain share, until its size comes.
local function across(at: number, offset: number, wide: number): number
	return if wide > 0 then (RIM + (wide - 2 * RIM) * at + offset) / wide else at
end

-- The arriving end's Transparency across the bar's whole width: clear, then From to To over Arrive.Points ending at
-- share `right`, and To past it (clipped by the window).
local function arriving(right: number, wide: number): NumberSequence
	local arrive = LOOK.Arrive
	local keys = { NumberSequenceKeypoint.new(0, arrive.From) }
	local function add(time: number, value: number)
		time = math.clamp(time, 0, 1)
		if time > keys[#keys].Time + 1e-4 and time < 1 - 1e-4 then
			table.insert(keys, NumberSequenceKeypoint.new(time, value))
		end
	end
	add(right - arrive.Points / wide, arrive.From)
	add(right, arrive.To)
	table.insert(keys, NumberSequenceKeypoint.new(1, if right >= 1 - 1e-4 then arrive.To else keys[#keys].Value))
	return NumberSequence.new(keys)
end

-- The bar's lights, their glows, its ticks and the handles at `cuts`. A light's window runs cut to cut, the Gap left each
-- side of a cut between two lights; the light inside it is the bar's whole image at the bar's own place, so its ends
-- stay true. Every place across the bar is a share of it.
local function lay()
	local edges = { 0, cuts[1], cuts[2], 1 }
	local wide = barWidth()
	for index = 1, 3 do
		local left = across(edges[index], if index > 1 then LOOK.Gap else 0, wide)
		local right = across(edges[index + 1], if index < 3 then -LOOK.Gap else 0, wide)
		local share = math.max(0, edges[index + 1] - edges[index])
		local width = right - left
		local shown = width > 1e-6 and share > 0
		local segment = parts[`Segment{index}`] :: Frame?
		local glow = parts[`Glow{index}`] :: Frame?
		if segment then
			segment:SetAttribute("Share", share)
			segment.Position = UDim2.fromScale(left, 0)
			segment.Size = UDim2.fromScale(math.max(width, 0), 1)
			segment.Visible = shown
			-- The bar's image at the bar's own place, in shares of the window: its left `left` of the bar back, its width
			-- the bar's.
			for _, name in { "Light", "Arrive" } do
				local image = segment:FindFirstChild(name) :: ImageLabel?
				if image and shown then
					image.Position = UDim2.fromScale(-left / width, 0)
					image.Size = UDim2.fromScale(1 / width, 1)
				end
			end
			local arrive = segment:FindFirstChild("Arrive")
			local fade = if arrive then arrive:FindFirstChildOfClass("UIGradient") else nil
			if fade and wide > 0 then
				fade.Transparency = arriving(right, wide)
			end
		end
		if glow then
			glow.Position = UDim2.new(left, 0, 0, RIM)
			glow.Size = UDim2.new(math.max(width, 0), 0, 0, TRACK - 2 * RIM)
			glow.Visible = shown
		end
	end
	for index, at in LOOK.Ticks.At do
		local tick = parts[`Tick{index}`] :: Frame?
		if tick then
			tick.Position = UDim2.new(across(at, -LOOK.Ticks.Size.X / 2, wide), 0, 1, LOOK.Ticks.Under)
		end
	end
	for index = 1, 2 do
		local handle = parts[`Handle{index}`] :: GuiObject?
		if handle then
			handle.Position = UDim2.fromScale(across(cuts[index], 0, wide), 0.5)
		end
	end
	for index = 1, 3 do
		local share = parts[`Share{index}`] :: TextLabel?
		if share then
			share.Text = `{math.floor((edges[index + 1] - edges[index]) * 100 + 0.5)}%`
		end
	end
end

-- A handle moved to `to` of the bar. The Void Breaker's keeps the Training machine's share behind it, squeezing it only
-- at the bar's end, so what it gives up goes to the battery (research, TR18); the Training machine's stays past it.
local function move(handle: number, to: number)
	if handle == 1 then
		local keep = if held then held.Keep else cuts[2] - cuts[1]
		cuts[1] = math.clamp(to, 0, 1)
		cuts[2] = math.min(cuts[1] + keep, 1)
	else
		cuts[2] = math.clamp(to, cuts[1], 1)
	end
	lay()
end

-- A hold on `handle` from `x`, a finger's or the mouse's (`input` a touch's, nil for the mouse).
local function grab(handle: number, input: InputObject?, x: number)
	held = { Handle = handle, Input = input, StartX = x, From = cuts[handle], Keep = cuts[2] - cuts[1], Pick = math.abs(cuts[2] - cuts[1]) < 1e-6 }
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
			-- By how far the finger went, never where it is: the same in every layer's inset. Two handles on one spot: a
			-- move left holds the Void Breaker's, a move right the Training machine's.
			local span = track.AbsoluteSize.X - 2 * RIM * track.AbsoluteSize.Y / TRACK
			local by = (input.Position.X - hold.StartX) / math.max(span, 1)
			if hold.Pick and math.abs(by) > 1e-6 then
				hold.Pick = false
				hold.Handle = if by < 0 then 1 else 2
			end
			move(hold.Handle, hold.From + by)
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

-- A row's chip: its machine's cut stone, in its light's colour (its own), reaching past its box.
local function chip(parent: Instance, image: string)
	local mark = Instance.new("Frame")
	mark.Name = "Chip"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Position = UDim2.new(0, 0, 0, NAME_LINE / 2)
	mark.Size = UDim2.fromOffset(CHIP, CHIP)
	mark.Parent = parent
	Skin.LayOwn(mark, POWER.Images[image], "Stone")
end

-- The head: generation against demand; Auto at its right. Under Auto, demand over generation in the warning colour: the
-- battery covering it, or the machines slowing. Under a split the player made, the fact plainly, with no warning
-- (research, TR18): each machine its share slows, at its speed.
local function head(body: Frame, now: Read.Base)
	local gap = Theme.Size.Gap
	local says = label(body, "Plant", "", Theme.Text.Body, UDim2.new(1, -(AUTO + gap), 0, NAME_LINE), UDim2.fromOffset(0, (STEP - NAME_LINE) / 2), { Font = Theme.Font.Strong })
	local over = label(body, "Over", "", Theme.Text.Caption, UDim2.new(1, -(AUTO + gap), 0, 18), UDim2.fromOffset(0, (STEP + NAME_LINE) / 2), { Colour = Theme.Colour.Over })
	parts.Plant, parts.Over = says, over
	table.insert(tickers, function(at: Read.Base)
		local rates = at.Rates
		says.Text = `Generation {Read.Kw(rates.Generation)} · Demand {Read.Kw(rates.Demand)}`
		local flow = rates.Flow
		local warn, text = false, ""
		if at.Data.Base.Power.Auto then
			warn = rates.Demand > rates.Generation + 1e-9
			text = if not warn then ""
				elseif at.Data.Base.Charge > 1e-9 then "The battery covers the rest"
				else "Demand over generation: the machines slow"
		else
			local slow: { string } = {}
			for _, machine in MACHINES do
				local speed = flow.Speed[machine.Id] or 1
				if (flow.Demand[machine.Id] or 0) > 0 and speed < 1 - 1e-6 then
					table.insert(slow, `The {machine.Name} at {math.floor(speed * 100 + 0.5)}%`)
				end
			end
			text = table.concat(slow, " · ")
		end
		over.Text = text
		over.TextColor3 = if warn then Theme.Colour.Over else Theme.Colour.TextDim
		body:SetAttribute("Over", warn)
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

-- The bar: the whole generation, a light for each machine and the battery's for the rest, a handle at each cut. Stacked
-- as power_images.json's `bar.stack` says: the ember, the well, the bed, the glows (outside every window), the lights,
-- the outline, the ticks; the handles over all.
local function bar(body: Frame, top: number)
	local images, colours = POWER.Images, POWER.Colours
	local rail = Instance.new("Frame")
	rail.Name = "Rail"
	rail.BackgroundTransparency = 1
	rail.Size = UDim2.new(1, -HANDLE, 0, HANDLE)
	rail.Position = UDim2.fromOffset(HANDLE / 2, top)
	rail.Parent = body
	local box = Instance.new("Frame")
	box.Name = "Bar"
	box.BackgroundTransparency = 1
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Position = UDim2.fromScale(0, 0.5)
	box.Size = UDim2.new(1, 0, 0, TRACK)
	box.Parent = rail
	-- The conduit's warmth behind the well, its middle on the bar's.
	local ember = Skin.LayOwn(box, images.Ember, "Ember", { Tint = colours.Ember, Alpha = LOOK.Ember, Z = 1 })
	ember.AnchorPoint = Vector2.new(0.5, 0.5)
	ember.Position = UDim2.fromScale(0.5, 0.5)
	local well = Instance.new("Frame")
	well.Name = "Well"
	well.BackgroundTransparency = 1
	well.Position = UDim2.fromOffset(-LOOK.Well.Ends, -LOOK.Well.Above)
	well.Size = UDim2.new(1, 2 * LOOK.Well.Ends, 1, LOOK.Well.Above + LOOK.Well.Under)
	well.ZIndex = 2
	well.Parent = box
	Skin.Lay(well, "ButtonFill", { Tint = colours.Well, Alpha = LOOK.Well.Fill, Z = 1 })
	Skin.Lay(well, "ButtonEdge", { Tint = colours.Edge, Alpha = LOOK.Well.Line, Z = 2 })
	Skin.LayOwn(box, images.Channel, "Channel", { Tint = colours.Channel, Z = 3 })
	for index = 1, 3 do
		local glow = Instance.new("Frame")
		glow.Name = `Glow{index}`
		glow.BackgroundTransparency = 1
		glow.ZIndex = 4
		glow.Parent = box
		Skin.LayOwn(glow, images.Glow, "Image", { Alpha = LOOK.Glow })
		parts[`Glow{index}`] = glow
	end
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundTransparency = 1
	track.Size = UDim2.fromScale(1, 1)
	track.ZIndex = 5
	track.Parent = box
	parts.Track = track
	for index = 1, 3 do
		local segment = Instance.new("Frame")
		segment.Name = `Segment{index}`
		segment.BackgroundTransparency = 1
		segment.ClipsDescendants = true
		segment.Parent = track
		Skin.LayOwn(segment, images.Light, "Light", { Z = 1 })
		local arrive = Skin.LayOwn(segment, images.Light, "Arrive", { Z = 2 })
		local fade = Instance.new("UIGradient")
		fade.Parent = arrive
		parts[`Segment{index}`] = segment
	end
	Skin.LayOwn(box, images.Edge, "Edge", { Tint = colours.Edge, Alpha = LOOK.Edge, Z = 6 })
	for index in LOOK.Ticks.At do
		local tick = Instance.new("Frame")
		tick.Name = `Tick{index}`
		tick.BorderSizePixel = 0
		tick.BackgroundColor3 = colours.Faint
		tick.BackgroundTransparency = 1 - LOOK.Ticks.Alpha
		tick.Size = UDim2.fromOffset(LOOK.Ticks.Size.X, LOOK.Ticks.Size.Y)
		tick.ZIndex = 7
		tick.Parent = box
		parts[`Tick{index}`] = tick
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
		-- The brass centred on the handle's middle (its pad even each side), never by a half point's offset.
		local grip = Skin.LayOwn(handle, images.Handle, "Grip", { Z = 4 })
		grip.AnchorPoint = Vector2.new(0.5, 0.5)
		grip.Position = UDim2.fromScale(0.5, 0.5)
		handle.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
				grab(index, if kind == Enum.UserInputType.Touch then input else nil, input.Position.X)
			end
		end)
		parts[`Handle{index}`] = handle
	end
	-- The lights stand on the bar's width in points, known once it's laid out, and again whenever the layer's box changes.
	track:GetPropertyChangedSignal("AbsoluteSize"):Connect(lay)
	-- Each light in its machine's colour while it works; an idle machine's share charges the battery whole, so it's lit
	-- as the battery's (research, TR18). `Wears` names the light a segment wears.
	local function wear(index: number, name: string)
		local segment = parts[`Segment{index}`] :: Frame?
		local glow = parts[`Glow{index}`] :: Frame?
		if segment == nil or glow == nil or segment:GetAttribute("Wears") == name then
			return
		end
		segment:SetAttribute("Wears", name)
		Skin.Tint(segment:FindFirstChild("Light") :: ImageLabel, POWER.Lights[name])
		Skin.Tint(glow:FindFirstChild("Image") :: ImageLabel, colours[name])
	end
	wear(3, REST)
	table.insert(tickers, function(at: Read.Base)
		for index, machine in MACHINES do
			wear(index, if (at.Rates.Flow.Demand[machine.Id] or 0) > 0 then machine.Id else REST)
		end
	end)
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
	chip(row, machine.Chip)
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

-- The battery's plate, in the head between the title and Close: its mark; its kWh against its cap in Power's yellow
-- (docs/ui.md, rule 3), the work it holds at today's demand as its soft line beside it; its charge as a bar under them.
-- Its share of the generation is the bar's yellow rest, so it has no row of its own. It lives in the body, above its
-- top, so a rebuild makes it again with the rest.
local function plate(body: Frame)
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local frame = Panel.new({
		Name = "BatteryPlate",
		Size = UDim2.fromOffset(PLATE.X, PLATE.Y),
		-- Centred in the head's row, its right a gap short of Close (the body stands two pads in, Close one).
		Position = UDim2.new(1, -(Screen.Exit - pad + gap), 0, -(Screen.Head + PLATE.Y) / 2),
		AnchorPoint = Vector2.new(1, 0),
		Edge = false,
		Parent = body,
	})
	parts.BatteryPlate = frame
	local mark = Instance.new("Frame")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Position = UDim2.new(0, pad, 0.5, 0)
	mark.Size = UDim2.fromOffset(MARK.X, MARK.Y)
	mark.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = BATTERY
	stroke.Parent = mark
	local nub = Instance.new("Frame")
	nub.Name = "Nub"
	nub.BorderSizePixel = 0
	nub.BackgroundColor3 = BATTERY
	nub.AnchorPoint = Vector2.new(0, 0.5)
	nub.Position = UDim2.new(1, 2, 0.5, 0)
	nub.Size = UDim2.fromOffset(3, MARK.Y / 2)
	nub.Parent = mark
	local left = pad + MARK.X + 5 + gap -- past the mark and its nub
	local inner = PLATE.X - left - pad
	local top = (PLATE.Y - LINE - gap - CHARGE) / 2
	local reading = label(frame, "BatteryReading", "", Theme.Text.Body, UDim2.fromOffset(inner, LINE), UDim2.fromOffset(left, top), { Font = Theme.Font.Number, Colour = BATTERY })
	local holds = label(frame, "BatteryHolds", "", Theme.Text.Caption, UDim2.fromOffset(inner, LINE), UDim2.fromOffset(left, top), { Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Right })
	local charge = Bar.new({ Name = "Charge", Size = UDim2.fromOffset(inner, CHARGE), Position = UDim2.fromOffset(left, top + LINE + gap), Colour = BATTERY, Parent = frame })
	parts.BatteryReading, parts.BatteryHolds, parts.BatteryCharge = reading, holds, charge
	table.insert(tickers, function(at: Read.Base)
		local kwh, capacity = at.Data.Base.Charge, at.Rates.Capacity
		local demand = at.Rates.Demand
		reading.Text = `{Read.Kwh(kwh)} / {Read.Number(capacity)} kWh`
		holds.Text = if demand > 1e-9 then `holds {Read.Hours(kwh / demand)} of work` else "nothing draws now"
		Bar.Set(charge, if capacity > 0 then math.clamp(kwh / capacity, 0, 1) else 0)
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
	plate(body)
	local top = STEP + gap
	bar(body, top)
	top += HANDLE + gap
	local list = Row.List(body, "Machines", UDim2.new(1, 0, 1, -top), UDim2.fromOffset(0, top))
	parts.Machines = list
	for index in MACHINES do
		machineRow(list, index, now)
	end
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
	grab(handle, nil, 0)
	move(handle, to)
	return release()
end

function PowerScreen.Slide(handle: number, to: number, seconds: number): { [string]: any }
	local from = cuts[handle]
	grab(handle, nil, 0)
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
