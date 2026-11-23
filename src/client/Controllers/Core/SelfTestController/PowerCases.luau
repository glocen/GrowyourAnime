--!strict
-- PowerCases (client, Studio only): the Power screen's cases, a list of their own beside Cases, which joins it as it joins
-- HudCases and VoidkinCases (Cases' one table had passed what the type solver checks in one piece). The generator's face
-- and prompt, the screen's bar and its handles, +/- and Auto (TR18), and the battery on its plate in the head (AR12's
-- tier 2, research's ruling, 2026-11-15), its mark AR12's battery (TR41 (e)).

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BaseLevels = require(Shared.Rules.BaseLevels)
local HudConfig = require(Shared.Config.Hud)
local Profile = require(Shared.Data.Profile)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local PowerScreen = require(UI.PowerScreen)
local Helpers = require(script.Parent.Helpers)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Layers = require(UI.Layers)
local Theme = require(UI.Theme)

local PowerCases = {}

-- Cases' own helpers and measures, one home each.
export type Given = {
	ANSWER: number,
	PLATE_TICK: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	lintClean: (t: any, where: string) -> (),
}

-- The battery's plate: in the head's row between the title's words and Close, and its two lines apart at their
-- longest, measured on probes of each with the widest words it says (research: the soft line only if it fits).
local function plateClear(t: any, where: string)
	local function part(name: string): Instance?
		return PowerScreen.Parts()[name]
	end
	local plate = part("BatteryPlate") :: GuiObject?
	local body = part("Body") :: GuiObject?
	local panel = if body then body.Parent :: GuiObject? else nil
	local title = if panel then panel:FindFirstChild("Title") :: TextLabel? else nil
	local close = if panel then panel:FindFirstChild("Close") :: GuiObject? else nil
	local reading = part("BatteryReading") :: TextLabel?
	local holds = part("BatteryHolds") :: TextLabel?
	if not (plate and body and panel and title and close and reading and holds) then
		t.Check(`{where}: the plate, its lines, the title and Close are here`, false)
		return
	end
	local low, high = plate.AbsolutePosition, plate.AbsolutePosition + plate.AbsoluteSize
	local head = panel.AbsolutePosition.Y
	t.Check(`{where}: the plate stands in the head's row, over the body`, low.Y >= head - 1 and high.Y <= body.AbsolutePosition.Y + 1, `{math.floor(low.Y)} to {math.floor(high.Y)}, the head {math.floor(head)} to {math.floor(body.AbsolutePosition.Y)}`)
	local words = title.AbsolutePosition.X + title.TextBounds.X
	t.Check(`{where}: clear of the title's words and of Close`, low.X >= words and high.X <= close.AbsolutePosition.X, `{math.floor(words)} | {math.floor(low.X)} to {math.floor(high.X)} | {math.floor(close.AbsolutePosition.X)}`)
	-- The widest reading is at the launch's top level, whose cap is the largest (TR21).
	local widest: { [TextLabel]: string } = { [reading] = `88.88 / {Read.Number(BaseLevels.Battery(BaseLevels.Top()))} kWh`, [holds] = "holds 88 h 58 min of work" }
	local probes: { [TextLabel]: TextLabel } = {}
	for label, text in widest do
		local probe = label:Clone()
		probe.Name = `Probe{label.Name}`
		probe.Text = text
		probe.Parent = label.Parent
		probes[label] = probe
	end
	t.Wait(0.05)
	local ends = probes[reading].AbsolutePosition.X + probes[reading].TextBounds.X
	local starts = probes[holds].AbsolutePosition.X + probes[holds].AbsoluteSize.X - probes[holds].TextBounds.X
	local fits = probes[holds].TextFits and probes[reading].TextFits
	for _, probe in probes do
		probe:Destroy()
	end
	local gap = Theme.Size.Gap * Layers.Scale()
	t.Check(`{where}: the reading and the work it holds stay apart at their longest`, fits and ends + gap <= starts, `{math.floor(ends)} + {math.floor(gap)} against {math.floor(starts)}`)
end

-- TR41 (b): the bar stacked from Modulo's cut images (Hud.Power; power_images.json's `bar.stack`), checked on the screen
-- as it stands: each layer its image and its order, the lights the bar's own image seen through their windows, the
-- rim and the gap kept, and each handle's brass on its cut.
local function barLook(t: any)
	local look = HudConfig.Power
	local parts = PowerScreen.Parts()
	local track = parts.Track :: Frame?
	local box = if track then track.Parent :: Frame? else nil
	t.Check("the bar is laid out", box ~= nil and track ~= nil and track.AbsoluteSize.Y > 0)
	if box == nil or track == nil or track.AbsoluteSize.Y <= 0 then
		return
	end
	local k = track.AbsoluteSize.Y / look.Bar.Height -- pixels a point, here
	local function image(holder: Instance?, name: string): ImageLabel?
		local found = if holder then holder:FindFirstChild(name) else nil
		return if found and found:IsA("ImageLabel") then found else nil
	end
	local ember, well, channel, edge = image(box, "Ember"), box:FindFirstChild("Well") :: Frame?, image(box, "Channel"), image(box, "Edge")
	local glow = box:FindFirstChild("Glow1") :: Frame?
	t.Check("each layer wears its own image: the ember, the bed, a glow, a light, the outline", ember ~= nil and ember.Image == look.Images.Ember.Id
		and channel ~= nil and channel.Image == look.Images.Channel.Id and edge ~= nil and edge.Image == look.Images.Edge.Id
		and image(glow, "Image") ~= nil and (image(glow, "Image") :: ImageLabel).Image == look.Images.Glow.Id
		and image(parts.Segment1, "Light") ~= nil and (image(parts.Segment1, "Light") :: ImageLabel).Image == look.Images.Light.Id)
	t.Check("stacked as the json says: ember, well, bed, glows, lights, outline, ticks", ember ~= nil and well ~= nil and channel ~= nil and glow ~= nil
		and edge ~= nil and ember.ZIndex < well.ZIndex and well.ZIndex < channel.ZIndex and channel.ZIndex < glow.ZIndex
		and glow.ZIndex < track.ZIndex and track.ZIndex < edge.ZIndex and edge.ZIndex < (box:FindFirstChild("Tick1") :: GuiObject).ZIndex)
	t.Check("the glows stand outside every window", glow ~= nil and glow.Parent == box and not box.ClipsDescendants and not track.ClipsDescendants)
	t.Check("the well reaches 26 past each end, 13 above and 15 under", well ~= nil
		and math.abs(well.AbsoluteSize.X - box.AbsoluteSize.X - 2 * look.Bar.Well.Ends * k) < 1
		and math.abs(well.AbsolutePosition.Y - (box.AbsolutePosition.Y - look.Bar.Well.Above * k)) < 1
		and math.abs(well.AbsoluteSize.Y - (look.Bar.Height + look.Bar.Well.Above + look.Bar.Well.Under) * k) < 1)
	local rim, gap = look.Bar.Rim * k, look.Bar.Gap * k
	local span = box.AbsoluteSize.X - 2 * rim
	local cuts = PowerScreen.Cuts()
	local edges = { 0 }
	for index, cut in cuts do
		edges[index + 1] = cut
	end
	table.insert(edges, 1)
	for index = 1, #cuts + 1 do
		local segment = parts[`Segment{index}`] :: Frame?
		local light = image(segment, "Light")
		local arrive = image(segment, "Arrive")
		local share = edges[index + 1] - edges[index]
		if segment and light and arrive and share * span > 2 * gap + 1 then
			local left = box.AbsolutePosition.X + rim + span * edges[index] + (if index > 1 then gap else 0)
			local right = box.AbsolutePosition.X + rim + span * edges[index + 1] - (if index <= #cuts then gap else 0)
			t.Check(`light {index}: its window from cut to cut, the gap kept at a cut between two`, segment.ClipsDescendants
				and math.abs(segment.AbsolutePosition.X - left) < 1 and math.abs(segment.AbsolutePosition.X + segment.AbsoluteSize.X - right) < 1,
				string.format("%.1f to %.1f, want %.1f to %.1f", segment.AbsolutePosition.X, segment.AbsolutePosition.X + segment.AbsoluteSize.X, left, right))
			t.Check(`light {index}: the bar's whole image at the bar's own place`, math.abs(light.AbsolutePosition.X - box.AbsolutePosition.X) < 1
				and math.abs(light.AbsoluteSize.X - box.AbsoluteSize.X) < 1 and math.abs(arrive.AbsolutePosition.X - box.AbsolutePosition.X) < 1)
			local fade = arrive:FindFirstChildOfClass("UIGradient")
			local keys = if fade then fade.Transparency.Keypoints else {}
			local function at(x: number): number
				local time = (x - box.AbsolutePosition.X) / box.AbsoluteSize.X
				for i = 2, #keys do
					if keys[i].Time >= time - 1e-6 then
						local a, b = keys[i - 1], keys[i]
						return a.Value + (b.Value - a.Value) * (time - a.Time) / math.max(b.Time - a.Time, 1e-9)
					end
				end
				return if #keys > 0 then keys[#keys].Value else 1
			end
			t.Check(`light {index}: its white end clear, then {look.Bar.Arrive.To} at its right side`, arrive.ImageColor3 == Color3.new(1, 1, 1)
				and math.abs(at(right) - look.Bar.Arrive.To) < 0.02 and at(right - look.Bar.Arrive.Points * k - 2) > 0.99,
				string.format("%.3f at its right, %.3f before its ramp", at(right), at(right - look.Bar.Arrive.Points * k - 2)))
		end
	end
	for index = 1, #cuts do
		local handle = parts[`Handle{index}`] :: GuiObject?
		local grip = image(handle, "Grip")
		local want = box.AbsolutePosition.X + rim + span * cuts[index]
		t.Check(`handle {index}: the brass, its middle on its cut`, grip ~= nil and grip.Image == look.Images.Handle.Id
			and math.abs(grip.AbsolutePosition.X + grip.AbsoluteSize.X / 2 - want) < 1,
			if grip then string.format("%.1f, want %.1f", grip.AbsolutePosition.X + grip.AbsoluteSize.X / 2, want) else "no grip")
	end
end

-- The battery on its plate in the Power screen's head (AR12's tier 2): its kWh against its cap in Power's yellow, the
-- work it holds as its soft line, its charge as a bar; no row of its own, its share being the bar's yellow rest.
local function batteryPlate(t: any, now: Read.Base)
	local function part(name: string): Instance?
		return PowerScreen.Parts()[name]
	end
	local function said(name: string): string
		local found = part(name)
		return if found and found:IsA("TextLabel") then found.Text else ""
	end
	local capacity = now.Rates.Capacity
	local reading = part("BatteryReading")
	t.Check("the battery's plate: its kWh against its cap", string.find(said("BatteryReading"), `^[%d%.,]+ / {Read.Number(capacity)} kWh$`) ~= nil, said("BatteryReading"))
	t.Check("in Power's yellow, the words' own on its slab (AR40's C)", reading ~= nil and reading:IsA("TextLabel") and reading.TextColor3 == Theme.Ink(PowerScreen.Palette).ElectricityWords)
	-- Its mark is AR12's battery (TR41 (e)), in its own gold, centred on the plate's height, clear of the words.
	local plate = part("BatteryPlate")
	local mark = if plate then plate:FindFirstChild("Mark") else nil
	if mark and mark:IsA("ImageLabel") and plate and plate:IsA("GuiObject") and reading and reading:IsA("GuiObject") then
		local middle = mark.AbsolutePosition.Y + mark.AbsoluteSize.Y / 2
		local plateMiddle = plate.AbsolutePosition.Y + plate.AbsoluteSize.Y / 2
		t.Check("its mark: AR12's battery, untinted", mark.Image == HudConfig.Power.Images.Battery.Id and mark.ImageColor3 == Color3.new(1, 1, 1), mark.Image)
		t.Check("the mark centred on the plate's height, inside its left", math.abs(middle - plateMiddle) <= 1 and mark.AbsolutePosition.X >= plate.AbsolutePosition.X, `{middle} against {plateMiddle}`)
		t.Check("the mark ends before the words", mark.AbsolutePosition.X + mark.AbsoluteSize.X <= reading.AbsolutePosition.X + 0.5, `{mark.AbsolutePosition.X + mark.AbsoluteSize.X} against {reading.AbsolutePosition.X}`)
		Helpers.batteryCells(t, mark, now.Data.Base.Charge, capacity, "the battery's plate")
	else
		t.Check("its mark: AR12's battery, an image on the plate", false, tostring(mark))
	end
	local holds = said("BatteryHolds")
	t.Check("the work it holds as its soft line", string.find(holds, "^holds .+ of work$") ~= nil or holds == "nothing draws now", holds)
	local charge = part("BatteryCharge")
	local share = if charge then charge:GetAttribute("Share") else nil
	t.Check("its charge as a bar, lit to its share", type(share) == "number" and math.abs(share - now.Data.Base.Charge / capacity) < 0.02, `{share} against {now.Data.Base.Charge / capacity}`)
	t.Check("no row of its own in the list", (part("Machines") :: Instance):FindFirstChild("Battery") == nil and part(`Share{#PowerScreen.Machines + 1}`) == nil)
end

function PowerCases.Cases(given: Given): { any }
	local ANSWER, PLATE_TICK = given.ANSWER, given.PLATE_TICK
	local waitFor, lintClean = given.waitFor, given.lintClean

	return {
		{
			Name = "Power: the generator shows generation and demand, opens the Power screen once it's open, its battery on a plate in the head, and its split is asked of the server",
			Place = "Main", -- TR45: its world stands in that place only
			Run = function(t: any)
				-- TR18 (docs/design.md, "Power"; UI/PowerScreen; Rules.Base.SetPower): the generator's face, its prompt only once
				-- a second machine has drawn (PowerOpen stands for that here), the screen's bar dragged by its handles, +/- on a
				-- share, Auto again. The battery on its plate in the head (AR12's tier 2, research's ruling, 2026-11-15). Leaves
				-- the plant as it found it.
				local view = ProfileController.Get()
				t.Check("the save's copy is here", view ~= nil)
				if view == nil then
					return
				end
				local was = { Open = view.Base.Power.Open, Auto = view.Base.Power.Auto, Shares = table.clone(view.Base.Power.Shares) }
				local function plant(): Profile.Power?
					local now = ProfileController.Get()
					return if now then now.Base.Power else nil
				end
				local function line(plate: Instance?, index: number): string
					local found = plate and plate:FindFirstChild(`Line{index}`, true)
					return if found and found:IsA("TextLabel") then found.Text else ""
				end
				local function part(name: string): Instance?
					return PowerScreen.Parts()[name]
				end
				local function said(name: string): string
					local found = part(name)
					return if found and found:IsA("TextLabel") then found.Text else ""
				end
				local ok, err = pcall(function()
					Screen.Close()
					-- Shut: the face says the plant, no prompt, and the screen won't open.
					t.Server("PowerOpen", false)
					t.Check("the Power screen shut", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and not p.Open and BaseController.Parts().GeneratorPrompt == nil
					end))
					local parts = BaseController.Parts()
					local face = parts.GeneratorPlate
					t.Check("the generator has its plate", face ~= nil)
					t.Wait(PLATE_TICK)
					local now = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow())
					t.Equal("its face: generation", line(face, 1), `Generation {Read.Kw(now.Rates.Generation)}`)
					t.Equal("and demand", line(face, 2), `Demand {Read.Kw(now.Rates.Demand)}`)
					BaseController.OpenPower()
					t.Check("shut, the screen doesn't open", Screen.Current() ~= PowerScreen.Name, tostring(Screen.Current()))
					-- Open: its prompt, and the screen under Auto.
					t.Server("PowerOpen", true)
					t.Check("open: the generator's prompt", waitFor(t, ANSWER, function(): boolean
						local prompt = BaseController.Parts().GeneratorPrompt
						return prompt ~= nil and prompt:IsA("ProximityPrompt") and prompt.ActionText == "Power"
					end))
					BaseController.OpenPower()
					t.Check("the Power screen opens", Screen.Current() == PowerScreen.Name, tostring(Screen.Current()))
					now = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow())
					t.Equal("generation against demand at its head", said("Plant"), `Generation {Read.Kw(now.Rates.Generation)} · Demand {Read.Kw(now.Rates.Demand)}`)
					local count = #PowerScreen.Machines
					local laid = part("Track") ~= nil and part(`Segment{count + 1}`) ~= nil and part(`Segment{count + 2}`) == nil and part(`Handle{count + 1}`) == nil
					for index = 1, count do
						laid = laid and part(`Handle{index}`) ~= nil
					end
					t.Check(`one bar: a light for each of the {count} machines and the battery's, a handle each`, laid)
					for index, machine in PowerScreen.Machines do
						local row = (part("Machines") :: Instance):FindFirstChild(machine.Id)
						local chip = if row then row:FindFirstChild("Chip") else nil
						local stone = if chip then chip:FindFirstChild("Stone", true) else nil
						t.Check(`{machine.Name}: its row, its own chip`, stone ~= nil and stone:IsA("ImageLabel") and stone.Image == HudConfig.Power.Images[machine.Chip].Id)
					end
					t.Check("Auto, as it starts", Button.State(part("Auto") :: TextButton) == "Selected", Button.State(part("Auto") :: TextButton))
					for index, machine in PowerScreen.Machines do
						local rating = now.Rates.Flow.Demand[machine.Id] or 0
						local reading = said(`Reading{index}`)
						t.Check(`{machine.Name}: its kW against its rating and its speed, or idle`, if rating > 0 then string.find(reading, " kW · %d+%%$") ~= nil else reading == "Idle", reading)
					end
					batteryPlate(t, now)
					plateClear(t, "under Auto, in this window")
					lintClean(t, "the Power screen under Auto")
					-- Two handles dragged: the split asked once at each let-go, the bar's shares in the save. The first goes to the
					-- bar's start first, wherever Auto had it, so the second has the room.
					local start = PowerScreen.Drag(1, 0)
					t.Check("the first handle to the start: asked and taken", start.Ok == true and waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and not p.Auto and (p.Shares.Breaker or 0) == 0
					end), start.Error)
					-- The handles after it, each to the start too: no share left but the battery's.
					for handle = 2, count do
						PowerScreen.Drag(handle, 0)
					end
					t.Check("every handle at the start: nothing shared", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and (p.Shares.Breaker or 0) == 0 and (p.Shares.Training or 0) == 0 and (p.Shares.Condenser or 0) == 0
					end))
					local second = PowerScreen.Drag(2, 0.6)
					t.Check("the second handle let go at 60%: asked and taken", second.Ok == true and second.Auto == false, second.Error)
					t.Check("the bar keeps it while the save's copy comes", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and not p.Auto and math.abs((p.Shares.Training or 0) - 0.6) < 1e-6
					end) and math.abs(PowerScreen.Cuts()[2] - 0.6) < 1e-6, `{PowerScreen.Cuts()[1]}, {PowerScreen.Cuts()[2]}`)
					-- The Void Breaker's handle keeps the Training machine's share: what it takes or gives up is the battery's
					-- (research, TR18).
					local first = PowerScreen.Drag(1, 0.3)
					t.Check("the first at 30%: asked and taken", first.Ok == true, first.Error)
					t.Check("the save holds the bar's split, the Training machine's 60% kept", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and not p.Auto and math.abs((p.Shares.Breaker or 0) - 0.3) < 1e-6 and math.abs((p.Shares.Training or 0) - 0.6) < 1e-6
					end))
					t.Check("the screen shows it: 30%, 60%, the Condenser's 0%, and the battery's 10% as the bar's rest", waitFor(t, 1, function(): boolean
						local rest = part(`Segment{count + 1}`) :: Frame?
						return said("Share1") == "30%" and said("Share2") == "60%" and said("Share3") == "0%" and rest ~= nil and math.abs((tonumber(rest:GetAttribute("Share")) or 0) - 0.1) < 1e-6
					end), `{said("Share1")}, {said("Share2")}, {said("Share3")}`)
					-- The Stone Condenser's handle (AR51): its own share out of the battery's rest.
					local third = PowerScreen.Drag(3, 0.95)
					t.Check("the third handle at 95%: the Condenser's 5% asked and taken", third.Ok == true and waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and math.abs((p.Shares.Condenser or 0) - 0.05) < 1e-6 and math.abs((p.Shares.Training or 0) - 0.6) < 1e-6
					end))
					t.Check("the screen shows it: 5%, and the battery's 5%", waitFor(t, 1, function(): boolean
						local rest = part(`Segment{count + 1}`) :: Frame?
						return said("Share3") == "5%" and rest ~= nil and math.abs((tonumber(rest:GetAttribute("Share")) or 0) - 0.05) < 1e-6
					end), said("Share3"))
					local flow = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow()).Rates.Flow
					for index, machine in PowerScreen.Machines do
						local segment = part(`Segment{index}`)
						local busy = (flow.Demand[machine.Id] or 0) > 0
						local wears = if busy then machine.Id else "Battery"
						local light = if segment then segment:FindFirstChild("Light") else nil
						local gradient = if light then light:FindFirstChildOfClass("UIGradient") else nil
						t.Check(`{machine.Name}'s light in its colour, or the battery's while it's idle ({if busy then "working" else "idle"})`,
							segment ~= nil and segment:GetAttribute("Wears") == wears and gradient ~= nil and gradient.Rotation == 90
								and gradient.Color == HudConfig.Power.Lights[wears], if segment then tostring(segment:GetAttribute("Wears")) else "no segment")
					end
					barLook(t)
					local line = part("Over")
					t.Check("under a split, the head's line is plain: never the warning colour", line ~= nil and line:IsA("TextLabel") and line.TextColor3 ~= Theme.Ink(PowerScreen.Palette).Over and (part("Body") :: Instance):GetAttribute("Over") ~= true, if line and line:IsA("TextLabel") then line.Text else "none")
					-- +/-: a step of the whole on one share.
					local step = HudConfig.Power.Step
					t.Check("+ on the Breaker", Button.Press(part("Plus1") :: TextButton))
					t.Check(`a step up: {math.floor((0.3 + step) * 100 + 0.5)}%`, waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and math.abs((p.Shares.Breaker or 0) - (0.3 + step)) < 1e-6
					end))
					t.Check("- on the Training machine", Button.Press(part("Minus2") :: TextButton))
					t.Check("a step down", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and math.abs((p.Shares.Training or 0) - (0.6 - step)) < 1e-6
					end))
					-- The whole given: + can't give more.
					local full = PowerScreen.Drag(2, 1)
					t.Check("the second handle at the end: the whole given, the Condenser's squeezed out at the bar's end", full.Ok == true and waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and math.abs((p.Shares.Breaker or 0) + (p.Shares.Training or 0) - 1) < 1e-6 and (p.Shares.Condenser or 0) == 0
					end))
					t.Check("and + gives no more", waitFor(t, 1, function(): boolean
						local plus = part("Plus1")
						return plus ~= nil and plus:IsA("TextButton") and not Button.Press(plus)
					end))
					-- The UI lint in this window and on the smallest phone (TR18's done-when: both scales).
					local top = GuiService.TopbarInset.Height
					for _, at in { { Name = "this window", Scale = nil :: number?, Box = nil :: Vector2? }, { Name = "the smallest phone", Scale = Theme.Scale.Floor, Box = Theme.Smallest - Vector2.new(0, top) } } do
						Layers.Force(at.Scale)
						Layers.Box(at.Box)
						t.Wait(0.1) -- laid out again
						lintClean(t, `the Power screen with a split, in {at.Name}`)
						plateClear(t, `with a split, in {at.Name}`)
						-- No row cut at the list's foot (AR51, research's must-fix 2): each whole above it, or wholly past it.
						local list = part("Machines") :: GuiObject?
						local cut: { string } = {}
						for _, machine in PowerScreen.Machines do
							local row = if list then list:FindFirstChild(machine.Id) :: GuiObject? else nil
							if list and row then
								local foot = list.AbsolutePosition.Y + list.AbsoluteSize.Y
								local head, bottom = row.AbsolutePosition.Y, row.AbsolutePosition.Y + row.AbsoluteSize.Y
								if bottom > foot + 0.5 and head < foot - 0.5 then
									table.insert(cut, string.format("%s, %.1f of %.1f under the foot", machine.Name, bottom - foot, row.AbsoluteSize.Y))
								end
							end
						end
						t.Check(`in {at.Name}: no machine's row cut at the list's foot`, list ~= nil and #cut == 0, table.concat(cut, "; "))
					end
					Layers.Force(nil)
					Layers.Box(nil)
					-- Auto again, the shares kept for later.
					t.Check("Auto pressed", Button.Press(part("Auto") :: TextButton))
					t.Check("Auto again, the split kept", waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and p.Auto and (p.Shares.Breaker or 0) > 0
					end))
				end)
				-- The plant as it was found.
				Screen.Close()
				if was.Open then
					t.Server("PowerOpen", true)
					waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and p.Open
					end)
					local back = ProfileController.Act("SetPower", if was.Auto then { Auto = true } else { Auto = false, Shares = was.Shares })
					t.Check("the split put back", back.Ok == true, back.Error)
				else
					t.Server("PowerOpen", false)
				end
				if not ok then
					error(err, 0)
				end
			end,
		},
		{
			Name = "Take: TR41 (b), Power's bar at the smallest phone: the Breaker working at 40%, the idle Training machine's 20% lit as the battery's, the battery's rest, held for a still, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Research's read of TR41 (b) (docs/test-requests.md, TR41): a shard in each open chamber so the Breaker draws,
				-- the split set by hand, the battery a third full, held until the driver sets ReplicatedStorage.NL_TakeStep to
				-- "End". The plant's door and split are put back; the shards break on as any shard does.
				local view = ProfileController.Get()
				t.Check("the save's copy is here", view ~= nil)
				if view == nil then
					return
				end
				local was = { Open = view.Base.Power.Open, Auto = view.Base.Power.Auto, Shares = table.clone(view.Base.Power.Shares) }
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Ready"
				step.Parent = ReplicatedStorage
				local shard = "lanternrow_standard"
				local idle = 0
				for _, chamber in view.Base.Chambers do
					idle += if chamber.Work then 0 else 1
				end
				if idle > 0 then
					local held = view.Bag.Shards[shard] or 0
					t.Server("BaseGive", shard, idle)
					waitFor(t, ANSWER, function(): boolean
						local seen = ProfileController.Get()
						return seen ~= nil and (seen.Bag.Shards[shard] or 0) == held + idle
					end)
					for _ = 1, idle do
						ProfileController.Act("AddShard", { Shard = shard })
					end
				end
				local base = Read.Base(view, workspace:GetServerTimeNow())
				t.Server("BaseBattery", base.Rates.Capacity / 3)
				t.Server("PowerOpen", true)
				local split = ProfileController.Act("SetPower", { Auto = false, Shares = { Breaker = 0.4, Training = 0.2 } })
				t.Check("the split is taken", split.Ok == true, tostring(split.Error))
				waitFor(t, ANSWER, function(): boolean
					local seen = ProfileController.Get()
					return seen ~= nil and seen.Base.Power.Open and not seen.Base.Power.Auto
				end)
				Screen.Close()
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				BaseController.OpenPower()
				t.Check("the Power screen opens", Screen.Current() == PowerScreen.Name, tostring(Screen.Current()))
				waitFor(t, 180, function(): boolean
					return step.Value == "End"
				end)
				Layers.Box(nil)
				Layers.Force(nil)
				Screen.Close()
				local back = ProfileController.Act("SetPower", if was.Auto then { Auto = true } else { Auto = false, Shares = was.Shares })
				t.Check("the split put back", back.Ok == true, tostring(back.Error))
				if not was.Open then
					t.Server("PowerOpen", false)
				end
				step:Destroy()
			end,
		},
		{
			Name = "Take: TR41 (e), the battery's mark on Power's plate and the Training machine lit while its Voidkin trains, at the smallest phone then this screen, as the driver writes, for research",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- Research's read of TR41 (e) (docs/test-requests.md, TR41): the Power screen at the smallest phone, held until
				-- ReplicatedStorage.NL_TakeStep says "Large" (this screen's own room), "Phone" or "End". The driver sets the
				-- machine training first, as the game does (Rules.Training.Who): the player off the plot, the lead home and whole.
				local step = Instance.new("StringValue")
				step.Name = "NL_TakeStep"
				step.Value = "Phone"
				step.Parent = ReplicatedStorage
				local function show(phone: boolean)
					Screen.Close()
					Layers.Force(if phone then Theme.Scale.Floor else nil)
					Layers.Box(if phone then Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height) else nil)
					BaseController.OpenPower()
				end
				show(true)
				t.Check("the Power screen opens", Screen.Current() == PowerScreen.Name, tostring(Screen.Current()))
				local plate = PowerScreen.Parts().BatteryPlate
				local mark = if plate then plate:FindFirstChild("Mark") else nil
				t.Check("its plate wears the battery's mark", mark ~= nil and mark:IsA("ImageLabel") and mark.Image == HudConfig.Power.Images.Battery.Id)
				local on = game:GetService("Players").LocalPlayer:GetAttribute("Training")
				t.Check("a Voidkin trains (the driver's setup)", type(on) == "string" and on ~= "", tostring(on))
				for index, machine in PowerScreen.Machines do
					if machine.Id == "Training" then
						t.Check("the Training machine wears its own light", waitFor(t, 3, function(): boolean
							local segment = PowerScreen.Parts()[`Segment{index}`]
							return segment ~= nil and segment:GetAttribute("Wears") == "Training"
						end))
					end
				end
				local shown = step.Value
				waitFor(t, 300, function(): boolean
					if step.Value ~= shown then
						shown = step.Value
						if shown == "Large" or shown == "Phone" then
							show(shown == "Phone")
						end
					end
					return step.Value == "End"
				end)
				Layers.Box(nil)
				Layers.Force(nil)
				Screen.Close()
				step:Destroy()
			end,
		},
	}
end

return PowerCases
