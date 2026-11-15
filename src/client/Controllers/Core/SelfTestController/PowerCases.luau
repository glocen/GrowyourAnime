--!strict
-- PowerCases (client, Studio only): the Power screen's cases, a list of their own beside Cases, which joins it as it joins
-- HudCases and VoidkinCases (Cases' one table had passed what the type solver checks in one piece). The generator's face
-- and prompt, the screen's bar and its handles, +/- and Auto (TR18), and the battery on its plate in the head (AR12's
-- tier 2, research's ruling, 2026-11-15).

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BaseConfig = require(Shared.Config.Base)
local HudConfig = require(Shared.Config.Hud)
local Profile = require(Shared.Data.Profile)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local PowerScreen = require(UI.PowerScreen)
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
	local widest: { [TextLabel]: string } = { [reading] = `88.88 / {Read.Number(BaseConfig.Battery.Capacity)} kWh`, [holds] = "holds 88 h 58 min of work" }
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
	local capacity = BaseConfig.Battery.Capacity
	local reading = part("BatteryReading")
	t.Check("the battery's plate: its kWh against its cap", string.find(said("BatteryReading"), `^[%d%.,]+ / {Read.Number(capacity)} kWh$`) ~= nil, said("BatteryReading"))
	t.Check("in Power's yellow", reading ~= nil and reading:IsA("TextLabel") and reading.TextColor3 == Theme.Colour.Electricity)
	local holds = said("BatteryHolds")
	t.Check("the work it holds as its soft line", string.find(holds, "^holds .+ of work$") ~= nil or holds == "nothing draws now", holds)
	local charge = part("BatteryCharge")
	local share = if charge then charge:GetAttribute("Share") else nil
	t.Check("its charge as a bar, lit to its share", type(share) == "number" and math.abs(share - now.Data.Base.Charge / capacity) < 0.02, `{share} against {now.Data.Base.Charge / capacity}`)
	t.Check("no row of its own in the list", (part("Machines") :: Instance):FindFirstChild("Battery") == nil and part("Share3") == nil)
end

function PowerCases.Cases(given: Given): { any }
	local ANSWER, PLATE_TICK = given.ANSWER, given.PLATE_TICK
	local waitFor, lintClean = given.waitFor, given.lintClean

	return {
		{
			Name = "Power: the generator shows generation and demand, opens the Power screen once it's open, its battery on a plate in the head, and its split is asked of the server",
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
					t.Check("one bar, three segments, two handles", part("Track") ~= nil and part("Segment3") ~= nil and part("Handle1") ~= nil and part("Handle2") ~= nil)
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
					t.Check("the screen shows it: 30%, 60%, and the battery's 10% as the bar's rest", waitFor(t, 1, function(): boolean
						local rest = part("Segment3") :: Frame?
						return said("Share1") == "30%" and said("Share2") == "60%" and rest ~= nil and math.abs(rest.Size.X.Scale - 0.1) < 1e-6
					end), `{said("Share1")}, {said("Share2")}`)
					local flow = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow()).Rates.Flow
					for index, machine in PowerScreen.Machines do
						local segment = part(`Segment{index}`)
						local busy = (flow.Demand[machine.Id] or 0) > 0
						local colour = if busy then machine.Colour else Theme.Colour.Electricity
						t.Check(`{machine.Name}'s share in its colour, or the battery's while it's idle ({if busy then "working" else "idle"})`, segment ~= nil and segment:IsA("Frame") and segment.BackgroundColor3 == colour)
					end
					local line = part("Over")
					t.Check("under a split, the head's line is plain: never the warning colour", line ~= nil and line:IsA("TextLabel") and line.TextColor3 ~= Theme.Colour.Over and (part("Body") :: Instance):GetAttribute("Over") ~= true, if line and line:IsA("TextLabel") then line.Text else "none")
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
					t.Check("the second handle at the end: the whole given", full.Ok == true and waitFor(t, ANSWER, function(): boolean
						local p = plant()
						return p ~= nil and math.abs((p.Shares.Breaker or 0) + (p.Shares.Training or 0) - 1) < 1e-6
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
	}
end

return PowerCases
